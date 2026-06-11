; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $03d", ROMX[$4000], BANK[$3d]

    db $3D ; Bank number

    ; Cross-bank dispatch table (196 entries)
    ; Called via: ld hl, $3DXX / rst $10
    dw $4189                          ; Entry 0
    dw $41D1                          ; Entry 1
    dw $4229                          ; Entry 2
    dw $4267                          ; Entry 3
    dw $42A7                          ; Entry 4
    dw $42F8                          ; Entry 5
    dw $4339                          ; Entry 6
    dw $438F                          ; Entry 7
    dw $43F6                          ; Entry 8
    dw $445C                          ; Entry 9
    dw $44AF                          ; Entry 10
    dw $4504                          ; Entry 11
    dw $455F                          ; Entry 12
    dw $45A1                          ; Entry 13
    dw $45DB                          ; Entry 14
    dw $4636                          ; Entry 15
    dw $467A                          ; Entry 16
    dw $46C1                          ; Entry 17
    dw $4715                          ; Entry 18
    dw $475A                          ; Entry 19
    dw $47A6                          ; Entry 20
    dw $47FB                          ; Entry 21
    dw $4857                          ; Entry 22
    dw $48AE                          ; Entry 23
    dw $48FE                          ; Entry 24
    dw $492D                          ; Entry 25
    dw $4970                          ; Entry 26
    dw $49C7                          ; Entry 27
    dw $4A0C                          ; Entry 28
    dw $4A63                          ; Entry 29
    dw $4AAD                          ; Entry 30
    dw $4B00                          ; Entry 31
    dw $4B4E                          ; Entry 32
    dw $4BA9                          ; Entry 33
    dw $4BF4                          ; Entry 34
    dw $4C5C                          ; Entry 35
    dw $4CB8                          ; Entry 36
    dw $4CFB                          ; Entry 37
    dw $4D38                          ; Entry 38
    dw $4D85                          ; Entry 39
    dw $4DD4                          ; Entry 40
    dw $4DF3                          ; Entry 41
    dw $4E3C                          ; Entry 42
    dw $4E89                          ; Entry 43
    dw $4EDC                          ; Entry 44
    dw $4F1A                          ; Entry 45
    dw $4F5A                          ; Entry 46
    dw $4FAA                          ; Entry 47
    dw $4FFC                          ; Entry 48
    dw $5030                          ; Entry 49
    dw $5072                          ; Entry 50
    dw $509C                          ; Entry 51
    dw $50E2                          ; Entry 52
    dw $512C                          ; Entry 53
    dw $517A                          ; Entry 54
    dw $51CA                          ; Entry 55
    dw $521A                          ; Entry 56
    dw $526E                          ; Entry 57
    dw $52C6                          ; Entry 58
    dw $5316                          ; Entry 59
    dw $5354                          ; Entry 60
    dw $536F                          ; Entry 61
    dw $53AC                          ; Entry 62
    dw $53F7                          ; Entry 63
    dw $5440                          ; Entry 64
    dw $548E                          ; Entry 65
    dw $54CE                          ; Entry 66
    dw $5517                          ; Entry 67
    dw $5563                          ; Entry 68
    dw $55A7                          ; Entry 69
    dw $5600                          ; Entry 70
    dw $564B                          ; Entry 71
    dw $5690                          ; Entry 72
    dw $56B1                          ; Entry 73
    dw $56F1                          ; Entry 74
    dw $5720                          ; Entry 75
    dw $5762                          ; Entry 76
    dw $57AD                          ; Entry 77
    dw $57FB                          ; Entry 78
    dw $582A                          ; Entry 79
    dw $5870                          ; Entry 80
    dw $58BB                          ; Entry 81
    dw $5905                          ; Entry 82
    dw $593B                          ; Entry 83
    dw $597E                          ; Entry 84
    dw $59AB                          ; Entry 85
    dw $59F9                          ; Entry 86
    dw $5A40                          ; Entry 87
    dw $5A87                          ; Entry 88
    dw $5AC8                          ; Entry 89
    dw $5B09                          ; Entry 90
    dw $5B3D                          ; Entry 91
    dw $5B7B                          ; Entry 92
    dw $5BB8                          ; Entry 93
    dw $5C10                          ; Entry 94
    dw $5C52                          ; Entry 95
    dw $5CA2                          ; Entry 96
    dw $5CC7                          ; Entry 97
    dw $5D0E                          ; Entry 98
    dw $5D63                          ; Entry 99
    dw $5DAF                          ; Entry 100
    dw $5E06                          ; Entry 101
    dw $5E68                          ; Entry 102
    dw $5EA7                          ; Entry 103
    dw $5EDB                          ; Entry 104
    dw $5F31                          ; Entry 105
    dw $5F9B                          ; Entry 106
    dw $5FEC                          ; Entry 107
    dw $6039                          ; Entry 108
    dw $605F                          ; Entry 109
    dw $60AB                          ; Entry 110
    dw $60F9                          ; Entry 111
    dw $6151                          ; Entry 112
    dw $61A0                          ; Entry 113
    dw $61E9                          ; Entry 114
    dw $622C                          ; Entry 115
    dw $6274                          ; Entry 116
    dw $62BD                          ; Entry 117
    dw $630B                          ; Entry 118
    dw $6356                          ; Entry 119
    dw $639D                          ; Entry 120
    dw $63D7                          ; Entry 121
    dw $63EF                          ; Entry 122
    dw $6427                          ; Entry 123
    dw $6468                          ; Entry 124
    dw $648A                          ; Entry 125
    dw $64BC                          ; Entry 126
    dw $64F4                          ; Entry 127
    dw $652B                          ; Entry 128
    dw $6561                          ; Entry 129
    dw $65B5                          ; Entry 130
    dw $65F1                          ; Entry 131
    dw $663E                          ; Entry 132
    dw $6671                          ; Entry 133
    dw $6694                          ; Entry 134
    dw $66D1                          ; Entry 135
    dw $6700                          ; Entry 136
    dw $6743                          ; Entry 137
    dw $678F                          ; Entry 138
    dw $67C7                          ; Entry 139
    dw $681D                          ; Entry 140
    dw $6865                          ; Entry 141
    dw $68A5                          ; Entry 142
    dw $68C8                          ; Entry 143
    dw $6925                          ; Entry 144
    dw $694C                          ; Entry 145
    dw $696F                          ; Entry 146
    dw $6996                          ; Entry 147
    dw $69D9                          ; Entry 148
    dw $6A28                          ; Entry 149
    dw $6A56                          ; Entry 150
    dw $6A96                          ; Entry 151
    dw $6AAF                          ; Entry 152
    dw $6AE9                          ; Entry 153
    dw $6B2A                          ; Entry 154
    dw $6B60                          ; Entry 155
    dw $6BB0                          ; Entry 156
    dw $6BE4                          ; Entry 157
    dw $6BFF                          ; Entry 158
    dw $6C48                          ; Entry 159
    dw $6C90                          ; Entry 160
    dw $6CD1                          ; Entry 161
    dw $6D1E                          ; Entry 162
    dw $6D67                          ; Entry 163
    dw $6D82                          ; Entry 164
    dw $6DC4                          ; Entry 165
    dw $6E11                          ; Entry 166
    dw $6E5B                          ; Entry 167
    dw $6EA5                          ; Entry 168
    dw $6EE5                          ; Entry 169
    dw $6F08                          ; Entry 170
    dw $6F33                          ; Entry 171
    dw $6F79                          ; Entry 172
    dw $6FBD                          ; Entry 173
    dw $6FF2                          ; Entry 174
    dw $703B                          ; Entry 175
    dw $7056                          ; Entry 176
    dw $708D                          ; Entry 177
    dw $70BE                          ; Entry 178
    dw $7107                          ; Entry 179
    dw $7157                          ; Entry 180
    dw $716A                          ; Entry 181
    dw $718F                          ; Entry 182
    dw $71B7                          ; Entry 183
    dw $71DD                          ; Entry 184
    dw $71FC                          ; Entry 185
    dw $721C                          ; Entry 186
    dw $7237                          ; Entry 187
    dw $7258                          ; Entry 188
    dw $7279                          ; Entry 189
    dw $729E                          ; Entry 190
    dw $72C4                          ; Entry 191
    dw $72DC                          ; Entry 192
    dw $72FF                          ; Entry 193
    dw $7314                          ; Entry 194
    dw $732F                          ; Entry 195

; --- Dispatch entry 0 ($4189) ---
DispatchEntry_3D_0:
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    nop
    nop
    inc sp
    inc sp
    inc sp
    inc sp
    ld bc, $013e
    ld bc, $0f3c
    ld bc, $4301
    nop
    inc sp
    ld bc, $015c
    ld bc, $0f5a
    inc c
    ld bc, $f3f9
    ld bc, Copy4Bytes
    ld [hl+], a
    ld bc, $0460
    ld [hl+], a
    ld bc, $f3fa
    ld bc, $0460
    ld bc, $0409
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f09
    inc h
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld [$0122], sp
    ld b, $0b
    ld bc, $0000
    ld bc, RequestScreenUpdate
    ld bc, $0204
    ld bc, $0f39
    inc b
    inc sp
    ld bc, $0060
    ld bc, Boot
    ld bc, $0f5a
    inc b
    ld [hl+], a
    ld [hl+], a
    ld bc, $0161
    inc sp
    ld bc, $0469
    ld bc, $0002
    ld bc, $0785
    ld [hl+], a
    ld de, $2211
    inc sp
    ld bc, $005e
    ld [hl+], a
    ld bc, $f7fa
    ld bc, $005e
    ld bc, $0909
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f09
    add hl, bc
    ld bc, $0f05
    ld [$0100], sp
    ld bc, $1111
    ld de, $3311
    inc sp
    ld bc, $0000
    ld bc, $fffa
    dec h
    inc sp
    ld bc, $0042
    nop
    ld bc, $0f38
    dec b
    ld bc, $0142
    inc sp
    inc sp
    nop
    nop
    inc sp
    ld bc, $0f5a
    ld [$5e01], sp
    ld bc, $7a01
    rrca
    inc bc
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    ld bc, $019f
    ld bc, $f7fa
    ld bc, $f1ff
    ld bc, $fffa
    inc sp
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    dec h
    inc sp
    inc sp
    ld bc, $0f34
    add hl, bc
    inc sp
    inc sp
    inc sp
    ld [hl+], a
    inc sp
    inc sp
    ld bc, $0041
    ld bc, CallBank59Entry3_055A
    ld bc, $0003
    ld bc, $0f67
    ld d, $22
    ld [hl+], a
    ld [hl+], a
    ld bc, $0141
    ld [hl+], a
    ld [hl+], a
    ld bc, $f8fa
    ld bc, $0004
    ld bc, $f8fa
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f08
    dec h
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    inc b
    inc sp
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    inc sp
    ld bc, CallBank59Entry3_055A
    ld bc, $0200
    ld bc, Goto_Unnamed2
    ld bc, $f5fd
    ld bc, $0f79
    inc b
    ld [hl+], a
    ld bc, $035c
    inc sp
    ld bc, $01a0
    nop
    nop
    ld bc, $0109
    ld bc, $0845
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    nop
    ld bc, $0062
    ld bc, SetCancelFlag
    nop
    ld bc, $0f05
    jr jr_03d_42f9

jr_03d_42f9:
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    nop
    nop
    ld bc, $0003
    ld bc, $013e
    ld bc, $0f3c
    ld bc, $0033
    nop
    inc sp
    inc sp
    inc sp
    ld bc, $0060
    ld bc, $0f5a
    inc hl
    ld [hl+], a
    nop
    nop
    ld [hl+], a
    inc sp
    inc sp
    ld bc, $00a0
    ld bc, $0f3a
    inc b
    ld [hl+], a
    ld [hl+], a
    ld bc, $0003
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f09
    inc h
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    rlca
    ld [hl+], a
    ld bc, $0b05
    ld de, $2501
    dec c
    inc sp
    nop
    nop
    ld bc, $0f39
    inc b
    ld bc, $0505
    inc sp
    ld bc, $0f5a
    inc b
    ld bc, $0005
    ld bc, $f7f5
    ld bc, Copy4Bytes
    ld bc, $0124
    ld bc, $0069
    ld [hl+], a
    ld bc, $f3fa
    ld bc, $04a1
    ld bc, $0409
    inc sp
    ld bc, $01c1
    ld [hl+], a
    ld [hl+], a
    ld bc, $0ab9
    ld bc, $0607
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0f07
    ld b, $00
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    dec h
    nop
    nop
    nop
    inc sp
    ld bc, $0004
    ld bc, $0f3a
    inc bc
    inc sp
    ld de, $3333
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld de, $0133
    ld e, d
    ld b, $01
    ld [bc], a
    ld bc, $6901
    inc b
    inc sp
    inc sp
    ld [hl+], a
    ld de, $2211
    inc sp
    inc sp
    ld bc, $0679
    ld bc, $0200
    ld bc, Goto_Unnamed2
    ld bc, $0065
    ld bc, $0101
    ld [hl+], a
    ld bc, $f3fa
    ld bc, $0491
    ld bc, $0409
    ld bc, $0086
    ld bc, $0180
    ld bc, $f4fa
    ld bc, $02c2
    ld bc, RetUnused
    ld bc, $0064
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f08
    dec b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld [$0122], sp
    ld b, $0b
    ld bc, $0000
    ld bc, $0409
    inc sp
    inc sp
    ld bc, HeaderLogo
    inc sp
    ld bc, $0f39
    inc b
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0041
    nop
    nop
    inc sp
    ld bc, $045a
    ld bc, $0140
    ld bc, $0667
    ld [hl+], a
    ld de, $0122
    add e
    nop
    ld bc, $0568
    ld bc, $0135
    ld de, $0111
    ld l, b
    inc b
    ld bc, $0125
    ld bc, $0121
    ld bc, $f6fa
    ld bc, $0230
    ld bc, $07aa
    ld bc, $0141
    ld bc, $0fba
    rlca
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    rlca
    ld [hl+], a
    ld bc, $0b05
    ld de, $2501
    rrca
    jr jr_03d_44a9

    ld bc, $0002
    ld bc, $0160
    ld bc, $0f5a
    inc b
    ld bc, $0080
    ld [hl+], a
    ld bc, $0b76
    ld bc, $0101
    ld bc, $f2fa
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $f0ff
    inc sp
    ld [hl+], a
    ld bc, $f6fa
    ld bc, $01a4
    ld bc, SetCancelFlag
    ld bc, $017f
    ld bc, $0fb9
    ld [$3333], sp
    ld [hl+], a

jr_03d_44a9:
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld [$0122], sp
    ld b, $0b
    ld bc, $0000
    ld bc, $0409
    ld bc, $f4fc
    ld bc, $0f39
    inc b
    inc sp
    ld bc, $005f
    ld bc, Boot
    ld bc, $0f5a
    dec b
    ld bc, $005f
    ld bc, $0085
    ld bc, $0f7a
    inc bc
    ld [hl+], a
    ld bc, $00a0
    ld bc, $0085
    ld [hl+], a
    ld bc, $f6fa
    ld de, $8501
    nop
    ld bc, SetCancelFlag
    ld bc, $0fb4
    dec c
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    nop
    inc sp
    inc sp
    inc sp
    inc sp
    nop
    ld bc, $0f38
    dec b
    ld bc, $0043
    inc sp
    ld [hl+], a
    ld [hl+], a
    nop
    nop
    inc sp
    ld bc, $075a
    ld bc, $0008
    ld bc, $0469
    ld bc, $0042
    ld de, $2211
    ld [hl+], a
    ld bc, $0a79
    ld de, $0111
    ld l, c
    inc bc
    ld [hl+], a
    ld bc, $0041
    ld bc, $0000
    ld [hl+], a
    ld bc, $073a
    ld bc, $0000
    ld bc, $0539
    ld bc, $0392
    ld bc, $0fb9
    dec b
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f04
    add hl, bc
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    dec h
    ld bc, $0f3a
    dec bc
    inc sp
    inc sp
    inc sp
    ld bc, $035b
    ld bc, $0f5a
    ld a, [bc]
    ld bc, $0460
    ld bc, $0d7f
    ld [hl+], a
    ld [hl+], a
    inc sp
    ld bc, $01a2
    ld [hl+], a
    ld [hl+], a
    ld bc, $f4fa
    ld bc, $02a2
    ld bc, RetUnused
    ld bc, $0fb2
    dec c
    ld bc, $00a0
    ld [hl+], a
    ld [hl+], a
    ld bc, $0808
    ld bc, $00b6
    ld bc, $0408
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    inc b
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld bc, $0260
    ld bc, $045a
    ld de, $0111
    ld [hl], b
    ld [bc], a
    ld bc, $0f6a
    inc de
    ld [hl+], a
    ld [hl+], a
    ld bc, $0272
    ld [hl+], a
    ld [hl+], a
    ld bc, $f6fa
    ld bc, $0070
    ld bc, $0808
    ld bc, $0fb4
    add hl, hl
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    ld bc, $f1fb
    inc sp
    inc sp
    inc sp
    ld bc, $0f39
    inc b
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    inc sp
    inc sp
    ld bc, $045a
    ld bc, $0000
    ld bc, $0c66
    ld bc, $0064
    ld bc, $086a
    ld bc, $0074
    ld bc, $f2fa
    ld bc, $0165
    ld bc, $0073
    ld [hl+], a
    ld bc, $f3fa
    ld bc, $04a1
    ld bc, $0409
    ld bc, $0163
    nop
    nop
    ld bc, $0548
    ld bc, $0395
    ld bc, $0ac8
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $09c9
    ld bc, $0606
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    ld bc, $0041
    ld bc, $0f36
    rlca
    ld bc, $0141
    ld bc, $0045
    inc sp
    ld bc, $0f5a
    dec bc
    nop
    ld bc, $0f79
    inc b
    ld [hl+], a
    ld bc, $0481
    ld [hl+], a
    ld bc, $0a3a
    nop
    ld bc, $0939
    ld bc, $f0fd
    ld bc, $0fba
    inc b
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, SetCancelFlag
    ld bc, $0844
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    jr z, jr_03d_46b9

    inc sp
    nop
    nop
    ld bc, $0f39
    inc b
    inc sp
    ld bc, $0360
    ld bc, $f4f8
    ld bc, $0d60
    ld [hl+], a
    ld bc, $0181
    ld bc, $0565
    inc sp
    ld bc, $0200
    ld bc, $0565
    ld [hl+], a
    ld bc, $0391
    ld [hl+], a
    ld [hl+], a
    ld bc, $f9fa
    inc sp
    ld bc, $0808
    ld bc, $0060
    ld bc, $0fb8
    dec bc

jr_03d_46b9:
    ld [hl+], a
    ld [hl+], a
    ld bc, $0ab8
    ld bc, $0606
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    ld bc, $f5fd
    ld bc, $0f3a
    inc bc
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $f2ff
    inc sp
    ld bc, $045a
    ld de, $6301
    inc c
    inc sp
    ld bc, $0165
    ld bc, $0f79
    inc b
    ld [hl+], a
    ld [hl+], a
    ld de, $0133
    and e
    ld bc, $0122
    ld a, [$01f5]
    and e
    ld [bc], a
    ld bc, RequestScreenUpdate
    nop
    ld bc, $00a3
    ld bc, HeaderManufacturerCode
    ld bc, $0fbd
    inc bc
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, SetCancelFlag
    inc sp
    ld bc, $0183
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    jr z, jr_03d_4721

jr_03d_4721:
    nop
    nop
    inc sp
    ld bc, $0f39
    inc b
    inc sp
    inc sp
    ld bc, $0007
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld bc, $085a
    ld de, $0111
    ld l, b
    rrca
    dec d
    ld [hl+], a
    inc sp
    ld bc, $00a1
    ld de, $2211
    ld [hl+], a
    ld bc, $f3fa
    ld bc, $03a1
    ld bc, $0508
    ld bc, $0fb1
    dec c
    ld [hl+], a
    ld bc, $0066
    ld bc, $0a06
    ld bc, $08b4
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    inc b
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0062
    inc sp
    inc sp
    inc sp
    ld bc, $045a
    ld bc, Boot
    ld bc, $0667
    ld [hl+], a
    ld bc, $0b72
    ld bc, $0200
    ld bc, $0567
    ld bc, $0281
    ld de, $3333
    ld [hl+], a
    ld bc, $f9fa
    ld bc, $0647
    ld bc, $0373
    ld bc, $0fb8
    add hl, bc
    ld bc, $0160
    ld bc, $09d9
    ld bc, $0606
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    nop
    nop
    inc sp
    nop
    nop
    inc sp
    inc sp
    inc sp
    ld bc, $0f39
    inc b
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    inc sp
    ld bc, $0045
    inc sp
    ld bc, $045a
    ld de, $0111
    ld h, h
    add hl, bc
    ld [hl+], a
    ld de, $0111
    ld h, [hl]
    nop
    ld bc, $0568
    ld de, $8201
    ld a, [bc]
    ld [hl+], a
    ld de, $1111
    ld [hl+], a
    ld bc, $0066
    ld [hl+], a
    ld bc, $f7fa
    ld bc, $0066
    ld bc, $0809
    ld bc, $0fb5
    inc c
    ld bc, $0060
    ld [hl+], a
    ld bc, $09d9
    ld bc, $0606
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    inc sp
    inc sp
    nop
    inc sp
    inc sp
    ld bc, $0f37
    ld b, $33
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    ld de, $3311
    ld bc, $045a
    ld bc, $0000
    ld bc, $0766
    ld [hl+], a
    ld bc, $0272
    inc sp
    ld bc, $0469
    ld bc, Boot
    ld bc, GameStateBit_0686
    ld [hl+], a
    ld de, $4001
    nop
    inc sp
    ld de, RetFromSRAMCopy
    ld bc, $f5fa
    ld bc, $02a3
    ld bc, RequestScreenUpdate
    ld bc, $0141
    ld bc, $0fb8
    ld [$0122], sp
    ld h, b
    ld bc, WaitSTATForOverlayB
    rlca
    ld bc, $0270
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    nop
    inc sp
    ld de, $4001
    ld bc, $3a01
    rrca
    inc bc
    inc sp
    nop
    ld [hl+], a
    ld bc, $0043
    ld [hl+], a
    nop
    inc sp
    ld bc, $045a
    ld de, $4301
    nop
    ld de, $6801
    dec b
    inc sp
    ld bc, $0272
    inc sp
    ld bc, $0f79
    inc b
    ld [hl+], a
    ld [hl+], a
    ld de, $3333
    inc sp
    inc sp
    ld de, $2222
    ld bc, $f5fa
    ld bc, $01a3
    ld bc, $0708
    ld bc, $0fb3
    dec c
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0907
    ld bc, $01b5
    ld bc, $0309
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    nop
    inc sp
    nop
    inc sp
    ld bc, $0044
    ld bc, $0f39
    inc b
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0243
    inc sp
    ld bc, $045a
    ld de, $6301
    inc c
    ld bc, $0264
    ld bc, $0f79
    inc b
    ld [hl+], a
    ld [hl+], a
    ld bc, ScreenRefreshVBlank
    ld [hl+], a
    ld bc, $f5fa
    ld bc, $0264
    ld bc, RequestScreenUpdate
    ld bc, HeaderCGBFlag
    nop
    ld bc, $0fb9
    rlca
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, SetCancelFlag
    inc sp
    inc sp
    ld bc, $0606
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    inc b
    ld bc, $0441
    inc sp
    inc sp
    ld bc, $0f5a
    inc hl
    ld [hl+], a
    ld bc, $05a0
    ld bc, $f6fa
    ld bc, $02b0
    ld bc, $0faa
    inc sp
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    inc b
    inc sp
    inc sp
    inc sp
    ld bc, $075c
    ld bc, $0e5e
    nop
    ld bc, $0f71
    inc c
    ld [hl+], a
    ld bc, $0461
    ld [hl+], a
    ld bc, $053a
    ld bc, $025c
    ld bc, $0f39
    inc d
    ld de, $0122
    pop hl
    inc bc
    ld bc, SetCancelFlag
    ld bc, $02f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld h, $00
    nop
    nop
    inc sp
    inc sp
    inc sp
    ld bc, $0f39
    inc b
    inc sp
    ld de, $3311
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld bc, SetupTilemapRow
    ld bc, $0200
    ld bc, Goto_No_More
    inc sp
    ld bc, $0f72
    dec bc
    ld [hl+], a
    inc sp
    ld bc, $005f
    ld de, $2211
    ld [hl+], a
    ld bc, $f3fa
    ld bc, $03a1
    ld bc, $0508
    ld bc, $f3fd
    ld bc, $0fb8
    ld b, $22
    ld [hl+], a
    ld [hl+], a
    ld bc, $09b4
    ld bc, $05f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld b, e
    ld bc, $0005
    ld bc, HeaderLogo
    inc sp
    ld bc, $0f5a
    inc b
    ld bc, $0580
    ld bc, $0f7a
    inc bc
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0080
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $f5fa
    ld bc, $0080
    ld bc, $0807
    ld bc, $0fb3
    dec c
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0907
    ld bc, $02f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    inc sp
    ld de, $0133
    ld b, h
    nop
    ld bc, $0f39
    inc b
    ld bc, $0046
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld bc, SetupTilemapRow
    ld bc, $0200
    ld bc, $0f6a
    inc de
    ld [hl+], a
    ld bc, $0241
    ld de, $2233
    ld bc, $093a
    ld de, $4801
    rlca
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0946
    ld bc, $03a1
    ld bc, $f3fa
    ld bc, $0064
    ld bc, $0063
    ld bc, SetCancelFlag
    ld bc, $02f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    inc b
    inc sp
    inc sp
    ld bc, $0f5a
    ld c, $22
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $085f
    ld bc, $0106
    ld bc, $0460
    ld [hl+], a
    ld bc, $0491
    ld [hl+], a
    ld bc, $043a
    ld bc, $0392
    ld bc, $0f39
    inc d
    ld de, $8301
    nop
    ld bc, $0083
    ld bc, SetCancelFlag
    ld bc, $02f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    ld bc, $0041
    ld bc, $0f36
    rlca
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0001
    ld bc, $045a
    ld bc, $0000
    ld bc, $0e66
    nop
    ld bc, $0f79
    inc b
    ld [hl+], a
    ld bc, $0481
    ld [hl+], a
    ld bc, $043a
    ld bc, ScreenRefreshVBlank
    ld bc, $0939
    ld bc, $0043
    ld bc, $0fba
    inc b
    ld bc, $0062
    ld bc, $0162
    ld bc, $f6fa
    ld bc, ScreenRefreshVBlank
    ld bc, $01fa
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    inc b
    inc sp
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    inc sp
    ld bc, CallBank59Entry3_055A
    ld bc, $0200
    ld bc, $0469
    ld [hl+], a
    ld [hl+], a
    ld bc, $0000
    ld [hl+], a
    ld [hl+], a
    ld bc, $0469
    ld bc, $0000
    ld bc, Boot
    ld bc, $f2fa
    ld bc, $0182
    ld bc, $0183
    ld bc, $f6fa
    ld bc, $0291
    ld bc, $0faa
    inc sp
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    inc sp
    ld bc, $f3fd
    ld bc, $0f3a
    inc bc
    inc sp
    inc sp
    ld [hl+], a
    inc sp
    inc sp
    ld bc, $0004
    ld bc, $0042
    ld bc, $015d
    ld de, $6301
    ld a, [bc]
    ld [hl+], a
    ld de, $2222
    ld [hl+], a
    ld bc, $0071
    ld bc, Goto_No_More
    ld bc, $0000
    ld de, $8601
    ld b, $22
    ld bc, $0491
    ld [hl+], a
    ld bc, $f6fa
    ld bc, $0194
    ld bc, SetCancelFlag
    ld bc, $0002
    ld bc, $0fb8
    dec bc
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $09b9
    ld bc, $0606
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld b, e
    inc sp
    ld bc, $0060
    ld [hl+], a
    ld bc, $0001
    ld bc, $075a
    ld bc, Boot
    ld bc, $0a6a
    inc sp
    ld bc, $0f79
    inc b
    ld [hl+], a
    ld bc, $0481
    ld [hl+], a
    ld bc, $f3fa
    ld bc, $0481
    ld bc, $0409
    ld bc, $0160
    ld bc, $0072
    ld bc, $0fba
    inc b
    ld [hl+], a
    ld bc, $03e1
    ld bc, SetCancelFlag
    ld bc, $02f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld [$ff01], sp
    pop af
    ld bc, $0f1a
    rlca
    ld [hl+], a
    inc sp
    inc sp
    inc sp
    nop
    ld bc, SetCancelFlag
    ld de, $4501
    rlca
    ld bc, $0105
    inc sp
    ld bc, $0065
    ld bc, $0f5a
    inc b
    ld bc, $0046
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0979
    ld bc, $0121
    ld bc, $f1fb
    ld [hl+], a
    inc sp
    inc sp
    nop
    ld bc, HeaderLogo
    ld [hl+], a
    ld bc, $f3fa
    ld bc, $04a1
    ld bc, $0409
    ld bc, $0065
    ld [hl+], a
    ld bc, $0bb6
    ld bc, BootMain
    ld bc, $f3fa
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $01c5
    ld bc, $0849
    ld bc, $07d5
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    dec h
    inc sp
    ld bc, $0142
    ld bc, $0f38
    dec b
    inc sp
    ld de, $0000
    ld [hl+], a
    ld [hl+], a
    nop
    nop
    inc sp
    inc sp
    ld bc, SetupTilemapRow
    ld bc, $0008
    ld bc, $0568
    inc sp
    nop
    inc sp
    ld de, $3311
    nop
    ld [hl+], a
    ld bc, $0b79
    ld de, $6901
    inc bc
    ld [hl+], a
    ld [hl+], a
    nop
    ld bc, $0042
    nop
    ld de, $0122
    ld a, [$01f4]
    and d
    inc bc
    ld bc, $0f39
    inc d
    ld de, $2211
    ld bc, $01e2
    ld bc, $0808
    ld bc, $02f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    dec c
    inc sp
    ld bc, $0f5a
    inc b
    nop
    nop
    ld bc, $0f73
    dec bc
    ld bc, $0069
    ld bc, $0041
    ld [hl+], a
    ld bc, $0b9a
    ld bc, $0739
    ld bc, $01a2
    ld bc, $0fb9
    dec b
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    daa
    nop
    inc sp
    inc sp
    inc sp
    inc sp
    ld bc, $0f39
    add hl, bc
    ld bc, HeaderNewLicenseeCode
    ld bc, $0f5a
    rlca
    inc sp
    ld bc, $0164
    ld bc, $0f7a
    ld a, [bc]
    nop
    nop
    ld [hl+], a
    ld bc, $0b9a
    ld bc, $0909
    inc sp
    ld bc, SpriteGBCFlipSkipX
    inc c
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    ld bc, $0041
    ld bc, $0f36
    add hl, bc
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0001
    ld bc, $043a
    ld bc, $0000
    ld bc, $0d66
    inc sp
    inc sp
    ld bc, $0f79
    dec b
    ld bc, $f0fc
    inc sp
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld bc, $0a9a
    ld bc, $0508
    ld [hl+], a
    ld bc, $00a8
    ld bc, $0064
    ld bc, $f6fa
    ld bc, GetStoredPointerHL
    ld bc, $fffc
    ld de, Boot
    ld bc, $1111
    ld de, $3311
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    inc sp
    nop
    nop
    nop
    inc sp
    inc sp
    inc sp
    ld bc, $0f39
    ld b, $22
    ld bc, $0162
    ld bc, $0141
    ld bc, $013d
    ld bc, $0000
    ld bc, $0002
    ld bc, $0f6a
    dec d
    ld bc, $0271
    inc sp
    ld [hl+], a
    ld bc, $0b9a
    ld bc, $0639
    ld de, $0133
    call nz, Boot
    cp c
    rrca
    dec b
    ld [hl+], a
    ld [hl+], a
    ld de, $0133
    ld h, c
    nop
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld c, c
    ld bc, $0064
    ld bc, $0f5a
    add hl, hl
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $fffa
    ld b, e
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    nop
    inc sp
    ld bc, $0242
    ld bc, $0f39
    ld b, $01
    ld b, c
    inc b
    ld bc, $0f5a
    inc b
    inc sp
    nop
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0877
    ld bc, $0200
    ld bc, $0c89
    ld [hl+], a
    ld bc, $0b8a
    ld bc, $0409
    ld bc, $0069
    ld bc, $0845
    ld bc, $0cc1
    ld bc, $0184
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld h, $33
    ld bc, HeaderCGBFlag
    ld bc, $0f39
    dec b
    inc sp
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld bc, SetupTilemapRow
    ld bc, $0200
    ld bc, $f3fa
    nop
    nop
    ld bc, $0105
    ld [hl+], a
    ld bc, $0b79
    ld de, $6901
    dec bc
    ld de, $0122
    sbc d
    dec bc
    ld bc, $0759
    ld bc, $f1ff
    ld bc, $0fb9
    dec b
    ld bc, $0165
    ld bc, $0f06
    rlca
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    inc sp
    ld de, $3322
    inc sp
    inc sp
    inc sp
    ld bc, $0739
    ld de, $4501
    add hl, bc
    nop
    ld de, $0011
    ld bc, $0045
    ld bc, $0f5a
    inc b
    ld bc, $0265
    ld [hl+], a
    ld [hl+], a
    ld bc, $0a79
    ld de, $0111
    ld l, c
    dec b
    inc sp
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld de, $2211
    ld bc, $079a
    ld bc, $0000
    ld bc, $0639
    ld bc, $0fb3
    dec bc
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f04
    add hl, bc
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    jr z, jr_03d_4f0f

    ld bc, $0b06
    ld bc, $0000
    ld bc, RequestScreenUpdate
    ld bc, $0204
    inc sp
    ld bc, $0f5a
    ld [$8301], sp
    ld bc, $7a01
    rrca
    ld [$0122], sp
    and l
    nop
    ld bc, $0b5a
    ld bc, RequestScreenUpdate

jr_03d_4f0f:
    ld [hl+], a
    ld bc, $0b54
    ld bc, $0c53
    ld bc, $0f03
    ld a, [bc]
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    daa
    ld [hl+], a
    inc sp
    inc sp
    inc sp
    inc sp
    ld bc, SetCancelFlag
    ld de, $4501
    inc c
    ld [hl+], a
    ld [hl+], a
    nop
    inc sp
    inc sp
    ld bc, CheckJoypadAB
    ld de, $0111
    ld h, a
    rrca
    dec e
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0b9a
    ld bc, $0f49
    add hl, bc
    ld bc, $0b45
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    inc sp
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0b36
    ld bc, $0000
    ld bc, $0539
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0002
    inc sp
    ld bc, $043a
    ld bc, $0155
    ld bc, $0f67
    jr @+$35

    nop
    ld bc, $0041
    inc sp
    ld [hl+], a
    ld bc, $0b9a
    ld bc, $0539
    nop
    nop
    ld bc, $01a3
    ld bc, $0fb9
    dec b
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    ld bc, $0161
    ld bc, $fffa
    inc bc
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    dec h
    inc sp
    ld bc, $0242
    ld bc, $0f39
    dec b
    nop
    nop
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld bc, $075a
    ld bc, $0101
    ld bc, $f3fa
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld bc, $0a74
    ld de, $9001
    nop
    ld bc, $0a87
    ld bc, $0042
    ld [hl+], a
    ld bc, $0b9a
    ld bc, $0409
    ld bc, $0069
    ld bc, $0fb5
    add hl, bc
    ld bc, $0165
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    inc b
    ld bc, $0441
    ld bc, $0f58
    dec h
    ld [hl+], a
    ld bc, $0f41
    inc c
    ld bc, $0fb0
    ld c, $22
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld [$ff01], sp
    pop af
    ld bc, $0f1a
    inc b
    inc sp
    inc sp
    inc sp
    ld bc, $f2fe
    ld bc, $0f3a
    inc bc
    ld bc, $0141
    ld bc, $0f55
    inc c
    ld bc, $0824
    ld bc, Copy4Bytes
    ld [hl+], a
    ld bc, $0b61
    ld de, $a101
    ld c, $01
    ld b, e
    rrca
    ld a, [bc]
    ld de, $2222
    ld [hl+], a
    ld bc, $0f04
    add hl, bc
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld b, e
    inc sp
    ld bc, $0160
    ld bc, $0f56
    daa
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $f2fe
    ld bc, $f6fa
    ld bc, $0fa4
    dec e
    ld bc, $0f04
    add hl, bc
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    inc b
    ld bc, $0441
    ld bc, $0f58
    ld [$2222], sp
    ld [hl+], a
    ld [hl+], a
    ld bc, $0857
    ld bc, $0300
    ld bc, $f2fa
    ld bc, $0086
    ld bc, $0894
    ld bc, $0303
    ld bc, $0f47
    ld b, $01
    ld b, b
    dec c
    ld bc, $0184
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    ld bc, $0041
    ld bc, $f0fd
    ld bc, $0f3a
    inc bc
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0062
    ld bc, $0757
    ld bc, $0000
    ld de, $6701
    inc c
    inc sp
    inc sp
    ld bc, $0f79
    inc b
    ld [hl+], a
    ld [hl+], a
    ld bc, $0a82
    ld bc, $0172
    ld bc, $0ba5
    ld bc, $0141
    ld bc, $0fb9
    ld a, [bc]
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld h, $33
    ld bc, HeaderCGBFlag
    ld bc, $0f39
    inc b
    inc sp
    nop
    ld bc, $0f52
    ld c, $22
    ld bc, $0083
    nop
    ld bc, $0659
    ld bc, $0192
    ld bc, $0488
    ld [hl+], a
    ld bc, $0105
    ld bc, $0696
    ld de, $a101
    dec c
    nop
    ld bc, $0043
    nop
    ld bc, $0548
    ld bc, $0cc1
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    ld bc, $0241
    ld bc, $0f38
    dec b
    ld bc, $0041
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld bc, $0759
    ld bc, $0201
    ld bc, Goto_No_More
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0974
    ld bc, $0000
    ld bc, $0775
    ld bc, $0083
    ld de, $5e01
    nop
    ld bc, SetCancelFlag
    ld bc, $0da4
    ld bc, HeaderNewLicenseeCode
    ld bc, $0fba
    rlca
    ld bc, $0162
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld [$ff01], sp
    pop af
    ld bc, $0f1a
    dec b
    inc sp
    inc sp
    nop
    ld [hl+], a
    ld bc, $0b36
    ld bc, $0000
    ld bc, $0309
    inc sp
    inc sp
    inc sp
    inc sp
    ld bc, $0145
    ld bc, $0759
    ld bc, $0155
    ld bc, $0f69
    inc d
    ld [hl+], a
    ld [hl+], a
    inc sp
    ld bc, $f2fe
    ld bc, $0639
    ld bc, $0ba3
    ld [hl+], a
    ld [hl+], a
    ld bc, $f2fe
    ld bc, $f6fa
    ld bc, $0cc4
    ld bc, $0f04
    add hl, bc
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    daa
    ld [hl+], a
    inc sp
    inc sp
    inc sp
    inc sp
    ld bc, SetCancelFlag
    ld de, $4501
    rlca
    ld bc, $0046
    ld de, $2222
    ld [hl+], a
    ld bc, $0958
    ld bc, $0001
    ld bc, $0659
    ld bc, $0105
    ld bc, $0f78
    dec b
    ld bc, $0044
    nop
    nop
    inc sp
    ld bc, $0577
    ld bc, $0054
    ld bc, $0fa4
    nop
    ld bc, $0647
    ld bc, $0cc1
    ld bc, $0065
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    inc sp
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0b36
    ld bc, $0000
    ld bc, $0309
    ld bc, $0042
    ld [hl+], a
    ld bc, $0102
    ld bc, CallBank59Entry3_055A
    ld bc, $0300
    ld bc, $0f6a
    inc de
    ld [hl+], a
    inc sp
    inc sp
    inc sp
    ld bc, $003f
    ld [hl+], a
    ld bc, $0739
    ld bc, $003f
    ld bc, $0508
    ld [hl+], a
    ld bc, $00a0
    ld bc, $0044
    ld bc, $f5fa
    ld bc, $0351
    ld bc, $f5fa
    ld [hl+], a
    ld bc, $0243
    ld bc, $fffa
    inc bc
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    ld bc, $0041
    ld bc, $f0fd
    ld bc, $0f3a
    inc bc
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld bc, $0060
    ld bc, $0658
    ld bc, $0202
    ld bc, $0f68
    dec d
    ld [hl+], a
    ld bc, $0f41
    inc c
    ld de, $0133
    and b
    nop
    nop
    ld [hl+], a
    inc sp
    ld bc, $0539
    ld bc, $0040
    ld bc, $00cf
    ld bc, $f3fa
    ld [hl+], a
    ld de, $6301
    nop
    ld de, $0122
    add hl, bc
    rrca
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    daa
    nop
    ld bc, $0f35
    ld [$0501], sp
    nop
    ld bc, $0804
    ld bc, $0d60
    nop
    inc sp
    ld bc, $0f73
    ld a, [bc]
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld bc, $0a04
    ld bc, $0ca2
    ld [hl+], a
    ld [hl+], a
    inc sp
    ld bc, $023f
    ld bc, $f6fb
    ld bc, $0cc5
    ld bc, $0f05
    ld [$0100], sp
    ld bc, $0111
    nop
    dec b
    ld bc, $fffa
    ld b, e
    inc sp
    ld bc, $0560
    ld bc, $0f5a
    inc hl
    ld [hl+], a
    ld bc, $05a0
    ld bc, $fffa
    ld b, e
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    inc b
    inc sp
    inc sp
    ld bc, $0f5a
    ld c, $33
    nop
    nop
    inc sp
    ld bc, $0f77
    ld b, $22
    ld bc, $0285
    inc sp
    nop
    ld [hl+], a
    ld bc, $f3fa
    ld bc, $04a1
    ld bc, $0409
    ld bc, $0fb1
    dec c
    ld [hl+], a
    ld bc, $03e1
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    ld bc, $043c
    ld bc, $0f39
    inc b
    inc sp
    inc sp
    inc sp
    ld bc, $013e
    ld bc, $0061
    ld bc, $0f5c
    inc b
    inc sp
    inc sp
    ld de, $5f01
    ld [bc], a
    ld bc, $0f7c
    ld bc, $2222
    nop
    inc sp
    inc sp
    ld de, $3333
    inc sp
    ld [hl+], a
    ld bc, $f4fa
    ld bc, $03a2
    ld bc, $0509
    ld bc, $0180
    ld bc, SpriteGBCFlipSkipX
    ld [$0122], sp
    ld [c], a
    ld [bc], a
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    add hl, hl
    inc sp
    inc sp
    inc sp
    ld bc, $0f39
    inc b
    inc sp
    ld bc, $f1fe
    nop
    ld [hl+], a
    inc sp
    inc sp
    ld bc, $095a
    ld de, $6801
    dec b
    inc sp
    ld bc, $0f72
    dec bc
    ld [hl+], a
    inc sp
    ld bc, $01a1
    ld de, $2222
    ld bc, $f3fa
    ld bc, $03a1
    ld bc, $0508
    ld bc, $00a1
    ld bc, $0261
    ld bc, $0fbb
    inc bc
    ld [hl+], a
    ld bc, $01e1
    ld bc, $0f07
    ld b, $00
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    ld bc, $0041
    ld bc, $f0ff
    ld bc, $0f3a
    inc bc
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $003f
    ld bc, $045a
    ld bc, $0106
    ld bc, $0b67
    inc sp
    ld bc, $0f77
    ld b, $22
    ld [hl+], a
    ld bc, $0140
    ld de, $2233
    ld bc, $f5fa
    ld bc, $02a3
    ld bc, RequestScreenUpdate
    ld bc, $0142
    ld bc, $0fb8
    ld [$6201], sp
    nop
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld b, e
    inc sp
    ld bc, $0560
    ld bc, $0f5a
    dec b
    ld [hl+], a
    ld [hl+], a
    ld bc, $0280
    ld bc, $045a
    ld de, $0111
    sub b
    ld [bc], a
    ld bc, $f2fa
    ld [hl+], a
    ld bc, $0491
    ld [hl+], a
    ld bc, $f3fa
    ld bc, $0491
    ld bc, $0409
    ld bc, $0460
    ld bc, $0fb9
    dec b
    ld [hl+], a
    ld bc, $03e1
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld a, [hl+]
    inc sp
    inc sp
    ld bc, $0f39
    inc b
    inc sp
    ld bc, $0441
    inc sp
    ld bc, $0f5a
    inc b
    inc sp
    inc sp
    ld bc, $0165
    ld bc, $0f78
    dec b
    ld [hl+], a
    ld bc, $0185
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $f3fa
    ld bc, $02a1
    ld bc, $0607
    ld [hl+], a
    ld [hl+], a
    ld bc, $00a5
    ld bc, $0807
    ld bc, $01b5
    ld bc, $0708
    ld bc, $01c5
    ld bc, $0f08
    dec b
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld b, e
    inc sp
    ld de, $3311
    ld bc, $005f
    ld de, $0133
    ld e, d
    rrca
    inc b
    inc sp
    ld de, $2233
    nop
    inc sp
    nop
    inc sp
    ld bc, $0779
    ld de, $8501
    rlca
    ld [hl+], a
    ld bc, $0291
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $f3fa
    ld bc, $04a1
    ld bc, $0409
    nop
    inc sp
    nop
    ld de, $2222
    ld [hl+], a
    ld [hl+], a
    ld bc, $08b9
    ld bc, $0805
    ld bc, $00c6
    ld bc, $0f05
    ld [$0100], sp
    ld bc, $0111
    nop
    dec b
    ld bc, $fffa
    ld b, e
    inc sp
    inc sp
    inc sp
    inc sp
    nop
    inc sp
    ld de, $1111
    inc sp
    ld bc, $0f5a
    inc b
    ld [hl+], a
    ld [hl+], a
    ld bc, $0161
    inc sp
    ld bc, $0469
    ld de, $0111
    add e
    add hl, bc
    ld [hl+], a
    ld bc, $0191
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld bc, $f5fa
    ld bc, $01a3
    ld bc, $0708
    ld bc, $0fb3
    dec c
    ld [hl+], a
    ld bc, $00e3
    ld bc, $0f08
    dec b
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    inc b
    inc sp
    nop
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld bc, $045a
    ld de, $1111
    inc sp
    ld de, $0111
    ld l, b
    dec b
    ld [hl+], a
    ld bc, $0272
    ld [hl+], a
    ld bc, $0469
    ld bc, $0000
    ld bc, $0090
    ld bc, Goto_Unnamed2
    ld [hl+], a
    ld bc, $0076
    inc sp
    ld bc, $0085
    ld bc, $f5fa
    ld bc, $02a3
    ld bc, RequestScreenUpdate
    ld bc, $0fb3
    dec c
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0081
    ld bc, $fffa
    inc bc
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    ld bc, $0141
    ld bc, $0f37
    ld b, $33
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld de, $3333
    ld bc, $045a
    ld de, $1111
    ld bc, $0c65
    ld [hl+], a
    ld bc, $0b66
    ld de, $6601
    ld b, $01
    ld h, h
    nop
    ld bc, $0194
    ld [hl+], a
    ld bc, $053a
    ld bc, $0293
    ld bc, $0a39
    inc sp
    ld bc, $0fb8
    ld b, $22
    ld bc, $03e1
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld a, [hl+]
    inc sp
    inc sp
    ld bc, $0f39
    inc b
    inc sp
    ld bc, $0441
    inc sp
    ld bc, $0f5a
    inc b
    ld bc, $0380
    ld [hl+], a
    ld bc, $0b79
    ld de, $6901
    inc bc
    ld [hl+], a
    ld bc, $0184
    ld [hl+], a
    ld [hl+], a
    ld de, $0122
    ld a, [$01f3]
    sub h
    ld bc, CopyDEtoHLByte
    rlca
    ld bc, $0067
    ld bc, $0fb5
    add hl, bc
    ld [hl+], a
    ld bc, $00a5
    ld bc, $0f06
    rlca
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld b, a
    inc sp
    ld bc, $0164
    ld bc, $0f5a
    add hl, hl
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $085a
    ld bc, $0c56
    ld bc, $0fb6
    daa
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    ld b, $01
    ld a, [$33f2]
    ld bc, $0361
    ld bc, $0f60
    nop
    ld bc, $0041
    ld bc, $0f77
    add hl, bc
    ld bc, $0263
    ld [hl+], a
    ld bc, $0b5a
    ld bc, $0f39
    dec d
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, SetCancelFlag
    inc sp
    inc sp
    ld bc, $0606
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    ld bc, $0041
    ld bc, $0f36
    dec c
    ld bc, $0041
    ld bc, $0f5a
    add hl, hl
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f3a
    inc b
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0944
    ld de, $1111
    ld bc, $0fc4
    add hl, de
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    nop
    nop
    inc sp
    ld bc, HeaderCGBFlag
    ld bc, $0f39
    ld b, $33
    ld [hl+], a
    ld bc, $0063
    inc sp
    inc sp
    ld bc, CallBank59Entry3_055A
    ld bc, Boot
    ld bc, $0f68
    rla
    ld bc, $f2ff
    ld [hl+], a
    ld [hl+], a
    ld bc, $0a9a
    ld bc, $0508
    inc sp
    ld bc, $0042
    ld bc, $0fb6
    ld [$6501], sp
    ld bc, CopyDEtoHLByte
    ld a, [bc]
    ld bc, $08c4
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    ld bc, $0141
    ld bc, $0f37
    ld [$0122], sp
    ld h, d
    nop
    ld de, $3333
    ld bc, $043a
    ld bc, $0200
    ld bc, $0f68
    ld d, $00
    ld bc, $0076
    inc sp
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0b9a
    ld bc, $0409
    nop
    nop
    ld bc, $00a6
    ld [hl+], a
    ld [hl+], a
    ld bc, $09b9
    ld bc, $0706
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $09d4
    ld bc, $0175
    ld bc, $0606
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    ld b, $22
    ld bc, $0062
    inc sp
    inc sp
    inc sp
    ld bc, $043a
    ld bc, Boot
    ld bc, $0667
    ld bc, $f2ff
    ld bc, $0f77
    ld [$0133], sp
    ld [hl], c
    nop
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0b9a
    ld bc, $0409
    nop
    nop
    ld bc, $0a43
    ld bc, $0cc1
    ld bc, $0164
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, SetCancelFlag
    ld bc, $01a2
    ld bc, $0309
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld c, h
    inc sp
    ld bc, $0f5a
    dec bc
    inc sp
    ld bc, $0f79
    dec bc
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0b9a
    ld bc, $0809
    inc sp
    inc sp
    ld bc, SpriteGBCFlipSkipX
    ld a, [bc]
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $09d9
    ld bc, $0606
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    jr z, @+$35

    inc sp
    inc sp
    inc sp
    ld bc, $0f39
    add hl, bc
    nop
    nop
    inc sp
    inc sp
    inc sp
    ld bc, $0f5a
    ld b, $00
    inc sp
    ld bc, $0066
    ld bc, $0f79
    ld [$8501], sp
    ld bc, $0122
    sbc d
    dec bc
    ld bc, RequestScreenUpdate
    ld bc, $01a5
    ld [hl+], a
    ld bc, $0ab9
    ld bc, $0807
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0907
    ld bc, $01d5
    ld bc, $0309
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    inc sp
    inc sp
    ld bc, $0f34
    ld a, [bc]
    nop
    nop
    ld bc, $0243
    inc sp
    ld bc, $0f5a
    inc b
    inc sp
    ld bc, $f2fe
    inc sp
    ld bc, $0f79
    dec b
    nop
    ld bc, $0142
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0b9a
    ld bc, $0559
    inc sp
    ld bc, $02c2
    ld bc, $0fb9
    dec b
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, SetCancelFlag
    ld bc, $0242
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    nop
    nop
    inc sp
    ld bc, HeaderCGBFlag
    ld bc, $0f39
    ld b, $01
    ld b, e
    nop
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld bc, $085a
    ld de, $0111
    ld l, b
    ld b, $01
    ld b, d
    nop
    ld de, $2211
    ld bc, $0b79
    ld de, $7901
    ld [$1122], sp
    ld de, $2211
    ld bc, $073a
    ld bc, $0c35
    ld bc, $0fb5
    add hl, bc
    ld [hl+], a
    ld bc, $0066
    ld bc, $0a06
    ld bc, $08e4
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    jr z, @+$35

    inc sp
    inc sp
    inc sp
    ld bc, $0f39
    dec c
    inc sp
    ld bc, $0f5a
    add hl, bc
    ld [hl+], a
    ld [hl+], a
    ld bc, $0a68
    ld bc, $0043
    ld bc, $0b8a
    ld [hl+], a
    ld bc, $0b8a
    ld bc, $0f39
    jr @+$35

    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $09d9
    ld bc, $0606
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    jr z, @+$35

    inc sp
    inc sp
    inc sp
    ld bc, $0f39
    dec c
    inc sp
    ld bc, $0f5a
    inc b
    nop
    ld bc, $0165
    ld [hl+], a
    ld [hl+], a
    ld bc, $0a79
    ld de, $0111
    ld a, c
    ld [$2222], sp
    ld de, $2211
    ld bc, $077a
    ld bc, $0805
    nop
    nop
    ld bc, $0fb3
    dec bc
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $02b3
    ld bc, $f6fa
    ld bc, $08e4
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld b, e
    inc sp
    ld bc, $0160
    ld bc, $0f56
    ld a, [bc]
    nop
    nop
    ld bc, $0f75
    ld [$2222], sp
    ld [hl+], a
    ld [hl+], a
    ld bc, $f2fe
    ld bc, $f6fa
    ld bc, $0fa4
    dec e
    ld bc, HandleScreenRefresh
    ld bc, $0ce0
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    nop
    inc sp
    inc sp
    inc sp
    inc sp
    ld bc, $013d
    ld bc, $0f3b
    ld [bc], a
    ld bc, HeaderCGBFlag
    ld bc, $0043
    ld bc, $0f59
    ld b, $00
    ld bc, $0045
    inc sp
    inc sp
    ld bc, $0f79
    inc b
    ld [hl+], a
    inc sp
    ld bc, $0241
    ld bc, $0488
    ld de, $a101
    dec c
    ld bc, $03c1
    ld bc, $0fb9
    dec b
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, SetCancelFlag
    inc sp
    inc sp
    ld bc, $0606
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    nop
    nop
    nop
    inc sp
    ld bc, $0044
    ld bc, $0f39
    inc b
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0162
    ld bc, $0658
    ld bc, $0200
    ld bc, $0f68
    dec d
    ld [hl+], a
    ld [hl+], a
    ld de, $4401
    nop
    ld bc, $023e
    ld bc, $f2fd
    ld bc, $0fa3
    nop
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $09a9
    ld bc, $0906
    ld [hl+], a
    ld bc, $0bd4
    ld de, $d401
    ld [$0100], sp
    ld bc, $0111
    nop
    dec b
    ld bc, $fffa
    inc h
    inc sp
    nop
    nop
    nop
    inc sp
    inc sp
    inc sp
    inc sp
    ld bc, $0f39
    inc b
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0062
    ld bc, $0757
    ld bc, Boot
    ld bc, $0f67
    ld d, $22
    ld bc, $f2ff
    ld bc, $0647
    ld bc, $0da1
    inc sp
    inc sp
    nop
    inc sp
    ld bc, $0fb6
    ld [$6401], sp
    ld [bc], a
    ld [hl+], a
    ld [hl+], a
    ld bc, SetCancelFlag
    ld bc, $0270
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    daa
    inc sp
    ld bc, $0044
    ld bc, $0f39
    inc b
    inc sp
    inc sp
    inc sp
    ld bc, $025b
    ld bc, $0f59
    rlca
    ld bc, $0161
    ld bc, $0f78
    dec b
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0884
    ld bc, $0140
    ld bc, $0ca5
    ld bc, $0f45
    ld [$4001], sp
    ld [bc], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0939
    ld bc, $0606
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    inc b
    inc sp
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0b54
    ld bc, $0240
    ld bc, $0f69
    inc d
    ld [hl+], a
    ld bc, $043e
    ld bc, $0409
    ld bc, $0ca1
    ld bc, $0b71
    ld bc, $0dc0
    ld [hl+], a
    ld [hl+], a
    ld de, $3333
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, SetCancelFlag
    inc sp
    inc sp
    ld bc, $0606
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld b, e
    inc sp
    ld bc, $0f51
    dec c
    ld bc, $0560
    ld bc, $0f7a
    inc bc
    ld [hl+], a
    ld bc, $0580
    ld bc, $f3fa
    ld bc, $0ea1
    inc sp
    ld bc, $f2ff
    ld bc, $0fba
    inc b
    ld [hl+], a
    ld [hl+], a
    ld bc, $03a0
    ld bc, $f6fa
    ld bc, $08e4
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld b, e
    inc sp
    inc sp
    inc sp
    ld bc, $025e
    ld bc, $0f59
    dec b
    ld [hl+], a
    ld bc, $0181
    inc sp
    inc sp
    ld bc, $0459
    ld bc, $0200
    ld bc, $0587
    ld [hl+], a
    ld bc, $0b91
    ld bc, $0300
    ld bc, $0aa7
    inc sp
    inc sp
    ld bc, SpriteGBCFlipSkipX
    ld a, [bc]
    inc sp
    ld bc, $0080
    ld bc, $09d9
    ld bc, $0606
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    nop
    nop
    nop
    inc sp
    inc sp
    ld bc, $0f36
    rlca
    inc sp
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld bc, $0a55
    ld de, $0111
    ld d, l
    ld [$2222], sp
    ld bc, $0a73
    ld bc, $0000
    ld bc, $0745
    ld [hl+], a
    ld bc, $0b91
    ld bc, Boot
    ld bc, $0fa5
    inc e
    ld bc, $0944
    ld bc, $0be1
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld h, $00
    nop
    inc sp
    inc sp
    inc sp
    ld bc, $0f38
    dec b
    inc sp
    inc sp
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld bc, $0759
    ld de, $1111
    ld bc, $0767
    ld [hl+], a
    ld [hl+], a
    ld bc, $0a74
    ld bc, Boot
    ld bc, $0567
    ld [hl+], a
    ld bc, $f1ff
    ld bc, $0045
    ld bc, $f3fa
    ld bc, $0da1
    inc sp
    inc sp
    ld bc, $027f
    ld bc, $09ba
    ld bc, $0607
    ld bc, $0164
    ld bc, $0083
    ld bc, $f6fa
    ld bc, $0290
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld h, $33
    ld bc, HeaderCGBFlag
    ld bc, $0f39
    inc b
    inc sp
    ld bc, $0308
    ld bc, $0f58
    ld b, $33
    ld de, $3333
    ld bc, $0f75
    ld [$0122], sp
    add c
    dec bc
    ld de, $a101
    dec c
    ld bc, $03c1
    ld bc, $0fb9
    dec b
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, SetCancelFlag
    inc sp
    inc sp
    ld bc, $0606
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    inc sp
    inc sp
    ld bc, $0140
    ld bc, $0f39
    inc b
    inc sp
    inc sp
    ld [hl+], a
    inc sp
    ld de, $6101
    nop
    ld bc, $0559
    ld de, $7101
    ld [bc], a
    ld bc, $0769
    ld bc, $0170
    ld bc, $0f79
    inc b
    ld [hl+], a
    ld bc, $033f
    ld bc, $0508
    ld bc, $0ca1
    inc sp
    ld bc, $02c1
    ld bc, $0fb8
    ld b, $22
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld bc, $0808
    ld bc, $0046
    ld bc, $0408
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld c, c
    ld bc, $0064
    ld bc, $0f5a
    daa
    ld [hl+], a
    ld bc, $01a4
    ld bc, $f6fa
    ld bc, $02b0
    ld bc, $0faa
    inc sp
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    nop
    nop
    inc sp
    ld bc, HeaderCGBFlag
    ld bc, $0f39
    dec b
    inc sp
    ld bc, $0441
    ld bc, $0f5a
    dec b
    ld bc, $0461
    ld bc, $0f7a
    ld b, $01
    ld h, c
    ld [bc], a
    ld [hl+], a
    ld bc, $0b9a
    ld bc, $0559
    ld bc, $03a1
    ld bc, $0fb9
    dec b
    ld [hl+], a
    ld bc, $03e1
    ld bc, SetCancelFlag
    ld bc, $02f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    inc sp
    ld bc, $f3fd
    ld bc, $0f3a
    ld b, $22
    ld [hl+], a
    ld [hl+], a
    ld bc, $0001
    ld bc, $053a
    ld bc, $0000
    ld bc, $0667
    nop
    ld bc, $0105
    inc sp
    ld bc, $0141
    ld bc, $0f7d
    ld [bc], a
    ld bc, $f3ff
    ld [hl+], a
    ld bc, $0b9a
    ld bc, $0409
    nop
    nop
    nop
    ld bc, $0187
    ld bc, $0fb9
    dec b
    ld [hl+], a
    ld bc, $03e1
    ld bc, SetCancelFlag
    ld bc, $0273
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld [$ff01], sp
    pop af
    ld bc, $0f1a
    rlca
    ld bc, $043e
    ld bc, $0f3c
    ld a, [bc]
    inc sp
    ld bc, $0f5a
    inc b
    inc sp
    inc sp
    inc sp
    inc sp
    nop
    nop
    ld bc, $0182
    ld bc, $0f7c
    ld b, $33
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $089a
    ld bc, $0706
    ld bc, $0fb1
    dec c
    ld bc, $00a6
    ld [hl+], a
    ld bc, $0a06
    ld bc, $02f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    add hl, bc
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld bc, $073a
    ld bc, $0101
    ld bc, $f3fa
    nop
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld bc, $0a75
    ld bc, $0000
    ld bc, $0777
    ld bc, $f0ff
    inc sp
    inc sp
    nop
    ld [hl+], a
    ld bc, $0b9a
    ld bc, $0539
    nop
    nop
    inc sp
    ld bc, $0068
    ld bc, $0fb9
    dec b
    ld [hl+], a
    ld bc, $03e1
    ld bc, SetCancelFlag
    ld bc, $02f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    inc sp
    ld de, $3333
    inc sp
    nop
    nop
    ld bc, $0f39
    ld [$2222], sp
    ld [hl+], a
    ld [hl+], a
    nop
    inc sp
    ld bc, $063a
    ld bc, $0106
    ld bc, CallBank56Entry8_0569
    ld [hl+], a
    ld bc, $0173
    ld bc, $0045
    ld bc, $023c
    ld bc, $0173
    ld bc, $0687
    ld bc, $f1ff
    ld de, $3311
    ld [hl+], a
    ld bc, $0b9a
    ld bc, $0409
    nop
    nop
    nop
    inc sp
    ld bc, $00c4
    ld bc, $0fb9
    dec b
    ld bc, $0064
    ld bc, $0064
    ld bc, SetCancelFlag
    ld bc, $0292
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    daa
    ld [hl+], a
    ld bc, HeaderLogo
    ld bc, $f6fa
    ld bc, $0203
    ld bc, $094a
    inc sp
    ld de, $0133
    ld e, d
    rrca
    ld [$3322], sp
    inc sp
    inc sp
    ld bc, $0869
    ld bc, $0064
    ld bc, $0989
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $088a
    ld bc, $0a06
    ld bc, $0fb4
    add hl, hl
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    add hl, hl
    inc sp
    inc sp
    inc sp
    ld bc, $0f39
    ld [$2222], sp
    ld bc, $0044
    ld bc, $f6fa
    ld bc, $0242
    ld bc, $0f6a
    add hl, de
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $086a
    ld bc, $0a06
    ld bc, $0fb4
    add hl, hl
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    inc sp
    nop
    nop
    ld [hl+], a
    ld bc, $0b36
    ld bc, $0000
    ld bc, $0639
    ld bc, $0204
    inc sp
    ld bc, $0f5a
    inc b
    nop
    ld bc, $0061
    ld bc, $0061
    ld bc, $0f7a
    dec b
    ld bc, $0081
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $089a
    ld bc, $0706
    nop
    nop
    nop
    ld [hl+], a
    ld bc, $0bb5
    ld de, $0501
    ld [$2222], sp
    ld [hl+], a
    ld de, $4501
    ld [$f001], sp
    dec b
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld [$ff01], sp
    pop af
    ld bc, $0f1a
    dec b
    inc sp
    inc sp
    nop
    nop
    ld bc, $0005
    ld bc, $0f3a
    inc b
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld de, $0133
    ld e, d
    dec b
    ld bc, $0201
    ld bc, $0969
    ld [hl+], a
    inc sp
    ld bc, $0042
    ld bc, $066c
    ld de, $8701
    ld b, $01
    ld h, l
    nop
    ld bc, $0002
    ld [hl+], a
    ld bc, $063a
    ld bc, $0201
    ld bc, $f4fa
    ld bc, $0086
    inc sp
    ld bc, $07b7
    ld bc, $0096
    ld bc, $09c6
    ld [hl+], a
    ld bc, $01e3
    ld bc, SetCancelFlag
    ld bc, $02f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    ld bc, $0241
    ld bc, $0f38
    dec c
    inc sp
    inc sp
    ld bc, $0f5a
    inc b
    nop
    ld [hl+], a
    inc sp
    ld [hl+], a
    inc sp
    ld [hl+], a
    nop
    ld [hl+], a
    ld bc, $0579
    ld de, $1133
    inc sp
    ld bc, $0090
    ld bc, $058a
    ld bc, $028f
    ld [hl+], a
    ld bc, $0b9a
    ld bc, $0539
    ld bc, $03c0
    ld bc, $0fb9
    dec b
    ld [hl+], a
    ld bc, $03e0
    ld bc, SetCancelFlag
    ld bc, $02f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    daa
    ld [hl+], a
    inc sp
    inc sp
    nop
    nop
    ld bc, SetCancelFlag
    ld de, $4501
    ld c, $33
    nop
    inc sp
    ld bc, $0f5a
    dec bc
    ld bc, $0045
    ld bc, $0f7c
    ld [bc], a
    nop
    inc sp
    inc sp
    ld de, $2233
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $089a
    ld bc, $0706
    ld bc, $0185
    ld bc, $0fb6
    ld [$a601], sp
    nop
    ld [hl+], a
    ld bc, $0a06
    ld bc, $02f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld b, e
    inc sp
    ld bc, $0160
    ld bc, $0f56
    daa
    ld [hl+], a
    ld bc, $01a0
    ld bc, $0a06
    ld bc, $02b0
    ld bc, $0faa
    inc sp
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    nop
    nop
    inc sp
    ld bc, HeaderCGBFlag
    ld bc, $0f39
    inc b
    inc sp
    inc sp
    ld bc, $015d
    ld bc, $0f57
    ld [$6001], sp
    inc bc
    ld bc, $0f79
    inc b
    ld [hl+], a
    ld bc, HeaderCGBFlag
    nop
    nop
    ld bc, $0548
    ld bc, $0fa1
    ld [bc], a
    inc sp
    ld bc, $013e
    ld bc, $0fbc
    ld [bc], a
    ld [hl+], a
    ld bc, $03e1
    ld bc, SetCancelFlag
    ld bc, $02f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    add hl, hl
    inc sp
    inc sp
    nop
    ld bc, $0f39
    inc b
    ld bc, $0004
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld bc, $0759
    ld bc, $0201
    ld bc, $096a
    nop
    ld bc, $0858
    ld bc, $0884
    ld [hl+], a
    ld bc, $0b71
    ld de, $a101
    dec c
    inc sp
    nop
    nop
    ld bc, $00c2
    ld bc, $0fb9
    dec b
    ld [hl+], a
    ld bc, $03e1
    ld bc, SetCancelFlag
    ld bc, $02f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    inc sp
    nop
    inc sp
    inc sp
    inc sp
    inc sp
    nop
    ld bc, $0f39
    inc b
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    nop
    ld bc, $0658
    ld bc, $0101
    ld bc, $0a67
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0968
    ld bc, $0007
    ld bc, $0309
    ld [hl+], a
    ld bc, $0391
    inc sp
    ld bc, $0539
    ld bc, $0ca2
    ld bc, $03c1
    ld bc, $0fb9
    dec b
    ld [hl+], a
    ld bc, $03e1
    ld bc, SetCancelFlag
    ld bc, $0392
    ld bc, $01fa
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    add hl, hl
    ld bc, $f0fd
    ld bc, $0f3a
    inc bc
    inc sp
    ld bc, $0002
    ld bc, $0044
    ld bc, $0f59
    dec b
    ld bc, $0380
    ld bc, $0f78
    dec b
    ld [hl+], a
    ld [hl+], a
    ld bc, $027d
    ld bc, CheckTilemapBit5
    ld bc, $0ca2
    ld bc, $00a0
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld bc, SetCancelFlag
    ld bc, $015e
    ld bc, SetCancelFlag
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0907
    ld bc, $02f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    rlca
    nop
    ld bc, $0f15
    add hl, bc
    inc sp
    inc sp
    inc sp
    nop
    nop
    ld bc, $0004
    ld bc, $0f3a
    inc bc
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    nop
    ld bc, $0658
    ld bc, Boot
    ld bc, $0f67
    ld d, $22
    ld [hl+], a
    ld bc, $0200
    inc sp
    ld bc, SetCancelFlag
    ld bc, $0fa4
    rra
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $09a9
    ld bc, $0606
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    inc sp
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0b36
    ld bc, $0000
    ld bc, $0309
    ld bc, $0042
    ld bc, $0145
    ld bc, $0659
    ld bc, $0155
    ld bc, $0558
    ld bc, $0363
    ld bc, $0558
    ld bc, $0373
    ld bc, $0408
    ld bc, $0482
    ld bc, $0808
    ld bc, $0fa4
    add hl, sp
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    daa
    ld [hl+], a
    ld bc, $0b05
    ld de, $0501
    rlca
    ld bc, $0105
    ld bc, $0f55
    add hl, bc
    inc sp
    inc sp
    inc sp
    ld de, $ff01
    pop af
    ld bc, $0f7a
    inc bc
    ld [hl+], a
    ld bc, $0081
    ld bc, $0805
    ld bc, $0fa1
    nop
    ld bc, $0904
    ld bc, $0cc1
    ld [hl+], a
    ld bc, $00e1
    ld bc, $0b46
    ld bc, BootMain
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    daa
    ld [hl+], a
    inc sp
    inc sp
    inc sp
    inc sp
    ld bc, SetCancelFlag
    ld de, $4501
    rlca
    ld bc, $0105
    ld [hl+], a
    ld [hl+], a
    ld bc, $0a57
    ld bc, $0102
    ld bc, Goto_No_More
    ld bc, $0046
    ld bc, $0f75
    ld [$0122], sp
    ld h, l
    nop
    ld bc, $0a45
    ld bc, $0ca3
    ld [hl+], a
    ld bc, $01c3
    ld bc, $0849
    ld bc, BootMain
    ld bc, $0fca
    inc de
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    daa
    ld [hl+], a
    inc sp
    inc sp
    inc sp
    nop
    ld bc, SetCancelFlag
    ld de, $4501
    rlca
    ld bc, $0105
    inc sp
    inc sp
    nop
    ld bc, $0f58
    ld b, $01
    add b
    inc bc
    ld bc, $0f78
    dec b
    ld bc, $0044
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0409
    ld bc, $0080
    ld bc, BootMain
    ld bc, $0faa
    inc d
    ld bc, $01a5
    ld bc, $0a06
    ld bc, $02f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    jr z, @+$24

    ld bc, $0b06
    ld bc, $0000
    ld bc, $0309
    inc sp
    ld bc, $0402
    ld bc, $0f59
    dec b
    ld bc, $0080
    ld bc, $0f75
    ld [$2222], sp
    ld [hl+], a
    ld [hl+], a
    ld bc, $007f
    nop
    ld bc, SetCancelFlag
    ld bc, $0da4
    ld bc, $007f
    ld bc, $0fb9
    ld [$a001], sp
    nop
    ld [hl+], a
    ld bc, SetCancelFlag
    ld bc, $02f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    rlca
    nop
    ld bc, $0f15
    add hl, bc
    inc sp
    inc sp
    inc sp
    ld bc, $031e
    ld bc, $0f3b
    ld [bc], a
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0705
    ld bc, HeaderLogo
    ld bc, $0f65
    jr @+$24

    inc sp
    ld bc, $00a1
    ld bc, $0a36
    ld bc, $0fa4
    ld a, [de]
    ld [hl+], a
    ld bc, $00e1
    ld bc, $0a06
    ld bc, $02f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    ld b, $01
    ld a, [$01f2]
    ld e, b
    rrca
    ld [$4101], sp
    nop
    ld bc, $0f77
    add hl, bc
    ld bc, SpriteGBCFlippedRead
    inc c
    ld bc, $0f42
    inc c
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld c, l
    ld bc, $0f5a
    ld c, l
    ld bc, $0f9a
    inc hl
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    dec h
    nop
    nop
    ld bc, $0f34
    dec c
    ld [hl+], a
    ld [hl+], a
    ld bc, $0a36
    ld bc, $0000
    ld bc, RetUnused
    ld bc, $0204
    ld bc, $0f78
    rlca
    ld bc, $0c72
    ld bc, $0ea2
    ld bc, $0f34
    dec bc
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f04
    add hl, bc
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    ld bc, $0041
    ld bc, $0f36
    add hl, bc
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0836
    ld bc, $0000
    ld bc, $0f66
    jr jr_03d_644f

    rst $38

jr_03d_644f:
    pop af
    ld bc, $0f96
    add hl, bc
    nop
    ld bc, Goto_Staff
    ld bc, $0fba
    inc b
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld bc, $0064
    ld bc, $fffa
    inc bc
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld c, l
    ld bc, $0f1a
    add hl, bc
    nop
    inc sp
    inc sp
    ld bc, $0f79
    ld c, d
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f19
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    inc sp
    nop
    ld bc, $0f34
    cpl
    ld bc, $0043
    ld bc, $0f7a
    inc b
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0984
    ld bc, $0101
    ld bc, $0fa6
    dec e
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    ld b, $00
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    nop
    ld bc, $0758
    ld bc, $0106
    ld bc, $0f68
    scf
    ld bc, $0f42
    inc c
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    daa
    ld [hl+], a
    ld bc, HeaderLogo
    ld bc, $f6fa
    ld bc, $0203
    ld bc, $0f4a
    ld d, $33
    inc sp
    ld bc, $0f75
    dec c
    ld [hl+], a
    ld [hl+], a
    ld bc, $0a77
    ld bc, BootMain
    ld bc, $0faa
    ld d, $01
    ld b, h
    ld [bc], a
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    daa
    ld [hl+], a
    inc sp
    inc sp
    inc sp
    inc sp
    ld bc, SetCancelFlag
    ld de, $4501
    inc c
    ld bc, $0044
    ld bc, $0849
    ld bc, $0054
    ld bc, $0f69
    add hl, sp
    ld bc, $0f45
    inc c
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    daa
    ld [hl+], a
    ld bc, HeaderLogo
    ld bc, $f6fa
    ld bc, $0203
    ld bc, $094a
    inc sp
    ld bc, $0f58
    ld b, $01
    inc b
    nop
    ld [hl+], a
    ld bc, $0065
    ld bc, $077a
    ld bc, $0164
    ld bc, $f3fa
    nop
    ld bc, $0004
    ld bc, $0f96
    ld [$0022], sp
    inc sp
    ld bc, $00c3
    ld [hl+], a
    ld bc, $0509
    ld bc, $02c2
    ld bc, RetUnused
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f08
    dec b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    ld b, $22
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    nop
    ld bc, $0539
    ld bc, $0202
    ld bc, $0f68
    rla
    inc sp
    ld bc, $03a0
    ld bc, $0f9a
    inc h
    ld [hl+], a
    ld [hl+], a
    ld bc, $0003
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    nop
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0b36
    ld bc, $0000
    ld bc, $0639
    nop
    ld bc, $0f54
    ld a, [bc]
    ld [hl+], a
    ld [hl+], a
    nop
    inc sp
    inc sp
    ld bc, $f0fe
    ld bc, $f5fa
    ld bc, $0c83
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld bc, $0887
    ld bc, $0002
    ld bc, $0ba7
    nop
    ld [hl+], a
    ld bc, $0bb8
    ld bc, RunScriptEngine
    ld bc, $0045
    ld bc, $fffa
    inc bc
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    inc sp
    ld bc, $f0fc
    inc sp
    inc sp
    ld bc, $0f39
    ld [$6101], sp
    ld bc, $5901
    rrca
    ld c, b
    ld bc, SpriteGBCWriteAndCheck
    ld a, [bc]
    ld [hl+], a
    ld bc, $03e1
    ld bc, SetCancelFlag
    ld bc, $02f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld c, l
    ld bc, $0f5a
    ld c, l
    ld bc, $0f7a
    rlca
    ld [hl+], a
    ld [hl+], a
    ld bc, $0a76
    ld bc, $02f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    ld bc, $0041
    ld bc, $0f36
    ld [$2200], sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, IncrementHLAndPop
    ld bc, $0000
    ld bc, $0f66
    jr jr_03d_66bd

    ld b, c

jr_03d_66bd:
    ld bc, $4301
    nop
    ld bc, $0f9a
    inc h
    ld bc, $0062
    ld bc, $0162
    ld bc, $f6fa
    ld bc, $0874
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    add hl, hl
    inc sp
    inc sp
    inc sp
    ld bc, $0f39
    ld [$2222], sp
    ld [hl+], a
    ld [hl+], a
    ld bc, $0848
    ld bc, Boot
    ld bc, $0f69
    ld c, l
    ld bc, $0b79
    ld [hl+], a
    ld bc, $0b79
    ld bc, $0408
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    add hl, hl
    inc sp
    inc sp
    inc sp
    ld bc, $0f39
    dec b
    nop
    inc sp
    nop
    ld bc, $0f54
    dec bc
    ld bc, $0361
    ld bc, $0f79
    dec b
    inc sp
    nop
    nop
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0899
    ld bc, $0000
    ld bc, $0409
    ld bc, $01a5
    ld bc, $0a06
    ld bc, $02d0
    ld bc, $0fca
    inc de
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    add hl, bc
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0948
    ld bc, $0001
    ld bc, $0539
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0975
    ld bc, $0000
    ld bc, $0e86
    nop
    ld bc, SpriteGBCFlipSkip
    ld b, $33
    inc sp
    inc sp
    ld bc, $f1fc
    ld bc, $0fba
    inc b
    ld [hl+], a
    ld bc, $03e1
    ld bc, SetCancelFlag
    ld bc, $03a2
    ld bc, $01fa
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    dec h
    inc sp
    nop
    nop
    ld [hl+], a
    ld bc, $0b36
    ld bc, $0000
    ld bc, $0639
    ld bc, $0204
    ld bc, $0f59
    rlca
    nop
    ld bc, $0f74
    dec bc
    ld [hl+], a
    ld [hl+], a
    ld bc, $0145
    ld bc, SetCancelFlag
    ld bc, $02b0
    ld bc, $0faa
    inc sp
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    daa
    ld [hl+], a
    ld bc, HeaderLogo
    ld bc, $f6fa
    ld bc, $0203
    ld bc, $094a
    inc sp
    inc sp
    ld bc, $0f59
    dec b
    ld bc, $0004
    ld [hl+], a
    nop
    ld bc, $0a77
    ld de, $8601
    ld [$3300], sp
    ld bc, $0002
    nop
    ld bc, SpriteGBCFlipSkip
    dec b
    ld bc, $0085
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld bc, $0509
    ld bc, $01c2
    ld bc, $0707
    ld [hl+], a
    ld bc, $00e2
    ld bc, $0a47
    ld bc, BootMain
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    jr z, @+$24

    ld bc, $0b06
    ld bc, $0000
    ld bc, RequestScreenUpdate
    ld bc, $0204
    ld bc, $0f59
    dec bc
    inc sp
    inc sp
    ld bc, $0f79
    dec b
    inc sp
    ld bc, $03a1
    ld bc, SpriteGBCFlipSkip
    ld [$0122], sp
    call nz, Boot
    sbc c
    rlca
    ld bc, $0155
    ld bc, $0409
    ld bc, $00c6
    ld bc, $0a55
    ld bc, $03f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    daa
    ld [hl+], a
    inc sp
    ld bc, $0004
    ld bc, $f6fa
    ld de, $4501
    rrca
    dec de
    nop
    nop
    ld bc, $0f75
    dec bc
    inc sp
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld bc, $0a98
    ld bc, $0906
    nop
    ld bc, $0fb4
    inc c
    ld [hl+], a
    ld bc, $00a6
    ld bc, $0948
    ld bc, BootMain
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld c, l
    ld bc, $0f1a
    rlca
    ld [hl+], a
    ld [hl+], a
    ld bc, $0a16
    ld bc, $0290
    ld bc, $0f8a
    ld c, l
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    inc h
    inc sp
    inc sp
    inc sp
    inc sp
    ld [hl+], a
    ld de, $0011
    ld bc, $0839
    ld bc, $0007
    ld bc, $0a49
    nop
    inc sp
    ld bc, $0f59
    rlca
    ld [hl+], a
    inc sp
    nop
    nop
    inc sp
    ld bc, $0748
    ld de, $8401
    ld a, [bc]
    ld [hl+], a
    ld de, $0022
    inc sp
    nop
    ld bc, CheckTilemapBit5
    ld bc, $0007
    ld bc, $07a6
    ld [hl+], a
    ld de, $1111
    ld [hl+], a
    ld bc, $0043
    ld bc, $f6fa
    ld bc, $0202
    ld bc, $08ca
    ld [hl+], a
    ld bc, $0045
    ld bc, $07cb
    ld bc, $0606
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    ld c, l
    ld bc, $0f79
    dec h
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, SetCancelFlag
    inc sp
    inc sp
    ld bc, $0606
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    daa
    nop
    inc sp
    ld bc, $0f36
    inc l
    ld bc, $037f
    ld bc, $0f7c
    dec h
    inc sp
    ld bc, $0fb5
    dec c
    ld bc, $0b45
    ld bc, $08e4
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    dec h
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, SetCancelFlag
    inc sp
    inc sp
    ld bc, $0a06
    ld bc, $0f94
    ld c, c
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    ld bc, $0041
    ld bc, $f0fd
    ld bc, $0f3a
    dec b
    ld [hl+], a
    ld bc, $0162
    ld bc, CheckTilemapBit5
    ld bc, $0304
    ld bc, $0f69
    dec de
    inc sp
    inc sp
    ld bc, SpriteGBCFlipSkip
    ld b, $01
    ld b, c
    nop
    ld bc, $0fb6
    ld [$2222], sp
    ld [hl+], a
    inc sp
    inc sp
    ld de, $2222
    ld bc, SetCancelFlag
    inc sp
    ld bc, $0171
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    inc sp
    inc sp
    inc sp
    ld bc, $f1fc
    ld bc, $0f3a
    ld [$2222], sp
    ld [hl+], a
    inc sp
    ld bc, $0839
    ld de, $1111
    ld bc, $0668
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0975
    ld bc, $0200
    ld bc, $0a88
    ld bc, $0072
    ld bc, $0f9a
    inc b
    ld bc, $f0fc
    ld bc, $0171
    ld bc, $0fba
    inc b
    ld bc, $0065
    ld bc, $0181
    ld bc, $f6fa
    ld bc, $0173
    ld bc, $0309
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    ld bc, $0041
    ld bc, $0f36
    jr z, @+$24

    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $f1ff
    ld bc, $f7fa
    ld bc, $0f85
    dec e
    ld bc, $0845
    ld bc, $0fc1
    nop
    ld bc, $0944
    ld bc, $0be1
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    dec h
    inc sp
    inc sp
    inc sp
    ld bc, $f1fc
    ld bc, $0f3a
    rlca
    ld [hl+], a
    ld bc, $0064
    ld bc, $0739
    ld bc, $0904
    inc sp
    ld bc, $0f72
    rrca
    ld bc, $0273
    ld bc, $0f9a
    inc b
    ld [hl+], a
    ld [hl+], a
    ld bc, $f3fe
    ld bc, $f5fa
    ld bc, $0cc3
    ld [hl+], a
    ld bc, $0272
    ld bc, $f6fa
    ld bc, $08e4
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld c, l
    ld bc, $0f1a
    rlca
    inc sp
    inc sp
    ld bc, $0f76
    ld c, l
    ld bc, $0f96
    rlca
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    daa
    inc sp
    inc sp
    inc sp
    ld bc, $0f37
    dec bc
    nop
    ld bc, $0f56
    inc c
    ld bc, $0084
    ld bc, $0f79
    ld [$3322], sp
    ld bc, $0064
    ld bc, $f7fa
    ld bc, $0ea5
    ld bc, $0987
    ld bc, $0cc4
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0939
    ld bc, $0606
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    daa
    inc sp
    ld bc, $0044
    ld bc, $0f39
    ld a, [bc]
    ld [hl+], a
    ld [hl+], a
    ld bc, $0a48
    ld de, $0111
    ld c, b
    ld [$2222], sp
    ld bc, $0a76
    ld bc, $0140
    ld bc, FormatHundredThousands
    ld bc, $0947
    ld bc, $0da4
    nop
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0bb9
    ld bc, $0a38
    ld bc, $0084
    ld bc, $0a6a
    ld bc, $0408
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld h, $33
    ld bc, $0043
    ld bc, $0f38
    inc c
    nop
    ld bc, $0f58
    dec bc
    nop
    ld bc, $0b47
    ld bc, $0986
    ld [hl+], a
    ld [hl+], a
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld bc, $0908
    inc sp
    ld bc, $0b06
    ld bc, $0fb5
    inc c
    ld bc, $0046
    ld bc, $0fd8
    dec b
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    nop
    nop
    nop
    inc sp
    inc sp
    ld bc, $033d
    ld bc, SpriteGBCSkipXEntry
    ld [bc], a
    inc sp
    ld bc, $0162
    ld bc, $0f58
    ld [$2222], sp
    ld [hl+], a
    ld [hl+], a
    ld bc, $0867
    ld bc, $0000
    ld bc, $0667
    ld [hl+], a
    ld bc, $0292
    ld [hl+], a
    ld bc, $0509
    ld bc, $0292
    ld bc, RetUnused
    ld bc, $0262
    ld bc, $0fb8
    rlca
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld bc, $0808
    ld bc, $00c6
    ld bc, $0408
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    ld bc, $f2fa
    inc sp
    ld bc, $0f39
    inc b
    inc sp
    inc sp
    ld bc, $035e
    ld bc, $0f59
    inc h
    ld [hl+], a
    ld bc, $0b61
    ld bc, $0040
    ld bc, $0ca4
    ld bc, SpriteGBCWriteAndCheck
    add hl, bc
    ld de, $0122
    pop hl
    inc bc
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld b, e
    inc sp
    ld bc, $0460
    ld bc, $0f59
    inc h
    ld [hl+], a
    ld bc, $04a0
    ld bc, $0f09
    ld b, h
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    dec h
    inc sp
    ld bc, $0242
    ld bc, $0f39
    inc b
    ld bc, $0042
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0858
    ld bc, $0000
    ld bc, $0558
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0974
    ld bc, $0300
    ld bc, $0448
    ld bc, $0183
    ld bc, $0775
    ld bc, $0400
    ld bc, $0f48
    dec b
    ld bc, $0e40
    ld bc, $0064
    ld bc, $0081
    ld bc, $fffa
    inc bc
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    jr z, @+$35

    inc sp
    inc sp
    inc sp
    ld bc, $0f39
    inc b
    inc sp
    ld bc, $0141
    ld [hl+], a
    ld [hl+], a
    ld bc, Div24SubtractLoop
    ld bc, $0073
    ld bc, Goto_No_More
    inc sp
    inc sp
    inc sp
    ld bc, $f0fe
    ld bc, $0f78
    dec b
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $f1fd
    ld bc, $0748
    ld bc, $0fa3
    nop
    nop
    ld bc, $0847
    ld bc, $0cc3
    ld [hl+], a
    ld bc, $01e3
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    jr z, @+$35

    inc sp
    inc sp
    inc sp
    ld bc, $0f39
    inc b
    ld bc, $0045
    ld bc, $015e
    ld bc, $0f59
    ld [$6301], sp
    ld bc, $7901
    rrca
    inc b
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0162
    ld bc, SetCancelFlag
    ld bc, $0ea4
    inc sp
    ld [hl+], a
    ld [hl+], a
    ld bc, $0ab9
    ld bc, $0907
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f07
    ld b, $00
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld h, $33
    ld bc, HeaderCGBFlag
    ld bc, $0f39
    inc b
    inc sp
    ld bc, $0041
    nop
    ld [hl+], a
    ld [hl+], a
    ld bc, Div24SubtractLoop
    ld de, $0111
    ld e, b
    dec b
    ld bc, $0043
    ld [hl+], a
    ld bc, $0b76
    ld bc, $0040
    ld bc, $0309
    ld [hl+], a
    ld [hl+], a
    ld bc, $0192
    nop
    ld bc, CheckTilemapBit5
    ld bc, $0ca2
    ld bc, $00a1
    ld bc, $0f46
    rlca
    ld de, $1111
    ld [hl+], a
    ld bc, $01e3
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    add hl, hl
    inc sp
    inc sp
    inc sp
    ld bc, $0f39
    inc b
    inc sp
    ld bc, $0342
    ld bc, $0f58
    ld b, $33
    nop
    ld bc, $0164
    ld bc, $0f78
    dec b
    ld [hl+], a
    inc sp
    ld bc, $007e
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0409
    ld bc, $01a1
    ld bc, $0706
    ld [hl+], a
    nop
    nop
    ld [hl+], a
    ld [hl+], a
    ld bc, $0806
    ld bc, $f4fe
    ld bc, $f4fa
    ld bc, $02c4
    ld bc, $0f08
    dec b
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld b, e
    inc sp
    inc sp
    inc sp
    inc sp
    ld bc, $0f54
    add hl, hl
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f04
    ld c, c
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    daa
    inc sp
    ld bc, $0044
    ld bc, $0f39
    inc b
    inc sp
    ld bc, $0f51
    dec c
    ld bc, $0044
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0879
    ld bc, $0705
    ld [hl+], a
    nop
    nop
    inc sp
    ld bc, $f2ff
    ld bc, $f3fa
    ld bc, $0ca1
    inc sp
    inc sp
    ld bc, $015f
    ld bc, $0fb8
    ld b, $01
    add l
    ld bc, CopyDEtoHLByte
    rrca
    rlca
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    ld bc, Goto_Staff
    ld bc, $0f39
    inc b
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0062
    ld bc, $0757
    ld bc, Boot
    ld bc, $0c67
    ld [hl+], a
    ld [hl+], a
    ld bc, $0a69
    ld bc, $0507
    ld [hl+], a
    inc sp
    inc sp
    nop
    ld bc, $0271
    ld bc, $053a
    ld bc, $0aa3
    ld [hl+], a
    nop
    inc sp
    inc sp
    ld bc, $016e
    ld bc, $f4fa
    ld bc, $0cc2
    ld bc, $0162
    ld bc, $0587
    ld bc, $0c00
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    dec h
    inc sp
    inc sp
    inc sp
    ld bc, $0f35
    ld [$3333], sp
    inc sp
    inc sp
    ld bc, $f2fe
    ld bc, $0f5a
    inc b
    ld [hl+], a
    ld bc, $0061
    ld bc, $0756
    ld bc, $0041
    ld bc, $0765
    ld [hl+], a
    ld de, $0033
    ld bc, $0243
    ld bc, $053a
    ld bc, $0ba3
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0906
    ld bc, $0b43
    ld de, $0122
    push bc
    ld bc, WaitSTATForOverlayB
    rrca
    inc b
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld h, $33
    ld bc, $0043
    ld bc, $0f38
    dec b
    inc sp
    ld bc, $0041
    nop
    ld bc, $0f56
    ld [$1133], sp
    inc sp
    ld [hl+], a
    ld bc, $0855
    inc sp
    ld de, $0133
    ld b, d
    nop
    ld bc, $0408
    ld [hl+], a
    ld bc, $0091
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0508
    ld bc, $0091
    ld bc, $0805
    ld bc, $0145
    ld bc, $0fb6
    ld [$a501], sp
    ld bc, CopyDEtoHLByte
    rrca
    rlca
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    ld bc, $f0fc
    inc sp
    inc sp
    inc sp
    inc sp
    ld bc, $0f39
    ld b, $01
    ld b, l
    nop
    ld bc, $0045
    ld bc, $0f5a
    inc b
    ld bc, $0462
    ld bc, $0f79
    rlca
    ld bc, $0243
    ld [hl+], a
    ld bc, $0b9a
    ld bc, $0839
    ld bc, $0044
    ld bc, $0fb9
    dec b
    ld [hl+], a
    ld bc, $03e1
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld b, h
    nop
    inc sp
    ld bc, $0362
    ld bc, $0f5a
    inc b
    ld bc, $0462
    ld bc, $0f79
    dec b
    ld [hl+], a
    ld bc, $04a1
    ld bc, $fffa
    ld b, e
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    inc sp
    inc sp
    ld bc, $0f34
    dec c
    ld bc, $0261
    ld bc, $0f5a
    daa
    ld [hl+], a
    ld bc, $01a4
    ld bc, $0f3a
    rla
    ld bc, $0904
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f04
    add hl, bc
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    ld bc, $f0fc
    inc sp
    inc sp
    ld bc, $0f37
    ld [$2222], sp
    ld [hl+], a
    ld bc, $0045
    inc sp
    ld bc, $043a
    ld de, $1111
    ld bc, $0c65
    ld [hl+], a
    ld [hl+], a
    ld de, Boot
    ld l, c
    ld [$0701], sp
    nop
    ld bc, $0c89
    ld [hl+], a
    ld bc, $0b8a
    ld bc, $0839
    ld bc, $07bc
    ld bc, $0dc0
    ld [hl+], a
    ld bc, $03e1
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld h, $33
    ld bc, $0043
    ld bc, $0f38
    ld [$0100], sp
    ld b, e
    ld bc, $0133
    ld e, d
    rrca
    rlca
    ld [hl+], a
    ld bc, $0b65
    ld bc, $0242
    ld bc, $f3fa
    inc sp
    inc sp
    nop
    ld de, $0000
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $099a
    ld bc, $0607
    ld bc, $0267
    ld bc, SpriteGBCFlipSkipX
    rlca
    ld [hl+], a
    ld bc, $01e1
    ld bc, $0f07
    ld b, $00
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    nop
    nop
    ld de, $0000
    inc sp
    inc sp
    ld bc, $0f39
    ld b, $33
    nop
    ld de, $3300
    inc sp
    inc sp
    inc sp
    ld bc, $0f5a
    ld b, $01
    ld l, c
    nop
    ld bc, $0f77
    rlca
    ld [hl+], a
    ld bc, $04a1
    ld bc, $fffa
    inc [hl]
    ld bc, DispatchBank42Rst
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    dec h
    inc sp
    ld bc, $f3fe
    ld bc, $0f3a
    ld b, $33
    inc sp
    ld bc, $0000
    inc sp
    ld bc, $0f5a
    ld [$0133], sp
    ld h, c
    nop
    ld bc, $0f7a
    dec b
    ld [hl+], a
    ld [hl+], a
    nop
    ld bc, $0082
    ld [hl+], a
    ld bc, $f6fa
    ld bc, $01a4
    ld bc, SetCancelFlag
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0909
    ld bc, $0063
    ld bc, $f8fa
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f08
    dec b
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld c, c
    inc sp
    inc sp
    inc sp
    inc sp
    ld bc, $0f5a
    add hl, hl
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $fffa
    ld b, e
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    jr z, @+$35

    inc sp
    inc sp
    inc sp
    ld bc, $0f39
    rlca
    ld bc, $0045
    inc sp
    inc sp
    inc sp
    ld bc, $0f5a
    add hl, bc
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0969
    ld bc, $0042
    ld bc, $0b8a
    ld [hl+], a
    ld bc, $0b8a
    ld bc, RequestScreenUpdate
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f06
    daa
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    ld bc, $f5f8
    ld bc, $0f3a
    inc b
    inc sp
    inc sp
    ld bc, $f2fa
    ld bc, $0362
    ld bc, $0f60
    ld e, $01
    ld hl, sp-$0c
    ld [hl+], a
    ld bc, $0f3a
    inc d
    ld bc, $0c41
    ld [hl+], a
    ld bc, $03e1
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    inc h
    inc sp
    ld bc, $0041
    ld bc, $0f36
    add hl, bc
    nop
    ld [hl+], a
    inc sp
    inc sp
    ld bc, $0040
    ld bc, CallBank59Entry3_055A
    ld de, $6401
    ld a, [bc]
    ld bc, $0065
    ld bc, $0f76
    inc c
    nop
    ld de, $2233
    ld [hl+], a
    ld bc, $0a9a
    ld bc, $0508
    ld [hl+], a
    ld [hl+], a
    ld bc, $0009
    ld bc, $06b7
    ld bc, $0207
    ld bc, FormatLargeNumber
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f08
    dec b
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld h, $00
    inc sp
    nop
    inc sp
    ld bc, $0f37
    ld [$0133], sp
    ld b, e
    nop
    inc sp
    inc sp
    inc sp
    ld bc, $0f5a
    ld b, $33
    nop
    nop
    inc sp
    inc sp
    ld [hl+], a
    ld bc, $0b79
    ld de, $6901
    dec b
    ld [hl+], a
    ld bc, $0066
    ld [hl+], a
    ld de, $0122
    ld a, [$01f5]
    ld h, [hl]
    nop
    ld bc, $0807
    ld [hl+], a
    ld bc, $00a5
    ld bc, $0808
    ld bc, $01b5
    ld bc, SetCancelFlag
    ld [hl+], a
    ld bc, $00c6
    ld bc, $0f09
    inc b
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld c, l
    ld bc, $0f5a
    ld c, l
    ld bc, $0f9a
    inc hl
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld b, e
    inc sp
    ld bc, $0560
    ld bc, $0f5a
    inc hl
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld bc, $00a0
    ld bc, $fffa
    ld b, e
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld b, e
    inc sp
    ld bc, $0560
    ld bc, $0f5a
    inc hl
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    inc sp
    inc sp
    ld bc, $00a0
    ld bc, $f6fa
    inc sp
    inc sp
    ld bc, $0a06
    ld bc, $0fb4
    add hl, hl
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld b, e
    inc sp
    ld bc, $0560
    ld bc, $0f5a
    inc hl
    ld [hl+], a
    ld bc, $05a0
    ld bc, $f6fa
    ld bc, $02b0
    ld bc, $0faa
    inc sp
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld c, c
    ld bc, $0064
    ld bc, $0f5a
    add hl, hl
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $fffa
    ld b, e
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld b, e
    inc sp
    ld bc, $0160
    ld bc, $0f56
    daa
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $0f04
    ld c, c
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld b, e
    inc sp
    ld bc, $0560
    ld bc, $0f5a
    inc hl
    ld [hl+], a
    ld bc, $05a0
    ld bc, $fffa
    ld b, e
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld b, a
    inc sp
    ld bc, $0164
    ld bc, $0f5a
    add hl, hl
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, $085a
    ld bc, $0c56
    ld bc, $0fb6
    daa
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld b, e
    inc sp
    ld bc, $0160
    ld bc, $0f56
    daa
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld bc, HandleScreenRefresh
    ld bc, $0000
    ld bc, $0fa4
    add hl, sp
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld c, c
    ld bc, $0064
    ld bc, $0f5a
    daa
    ld [hl+], a
    ld bc, $01a4
    ld bc, $f6fa
    ld bc, $02b0
    ld bc, $0faa
    inc sp
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld b, e
    inc sp
    ld bc, $0160
    ld bc, $0f56
    daa
    ld [hl+], a
    ld bc, $01a0
    ld bc, $0a06
    ld bc, $02b0
    ld bc, $0faa
    inc sp
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld c, l
    ld bc, $0f5a
    ld c, l
    ld bc, $0f9a
    inc hl
    nop
    ld bc, $1101
    ld de, $1111
    inc sp
    inc sp
    ld bc, $0000
    ld bc, $fffa
    ld c, l
    ld bc, $0f5a
    ld c, l
    ld bc, $0f7a
    rlca
    ld [hl+], a
    ld [hl+], a
    ld bc, $0a76
    ld bc, $02f0
    ld bc, $f2a0
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    daa
    inc sp
    inc sp
    ld bc, $0f36
    ld c, l
    ld bc, $0f96
    ld b, a
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld b, e
    inc sp
    ld bc, $0460
    ld bc, $0f59
    inc h
    ld [hl+], a
    ld bc, $04a0
    ld bc, $0f09
    ld b, h
    nop
    ld bc, $1101
    ld bc, $0500
    ld bc, $fffa
    ld b, h
    inc sp
    ld bc, $0461
    ld bc, $0f5a
    inc h
    ld [hl+], a
    ld bc, $04a1
    ld bc, $fffa
    ld b, e
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
