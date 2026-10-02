; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $05d", ROMX[$4000], BANK[$5d]
;All invalid calls to external banks removed. 
DataB5d_4000:
    db $5D ; Bank number

    ; Cross-bank dispatch table (2 entries)
    ; Called via: ld hl, $5DXX / rst $10
    dw $4005                          ; Entry 0
FuncB5d_4003:
Jump_05d_4003:
    dw $40B3                          ; Entry 1

; --- Dispatch entry 0 ($4005) ---
AnimTick5D:
    ld a, [$dd60]
    or a
    ret z

    ld de, $4071
    call AnimBuildOAM5D
    ld a, [$dd68]
    or a
    jr z, jr_05d_4021

    ld a, [$daa4]
    cp $03
    jr z, jr_05d_4021

    cp $04
    jr nz, jr_05d_4031

jr_05d_4021:
    ld hl, $ffc3
    inc [hl]
    ld hl, $ffc3
    inc [hl]
    ld hl, $ffc3
    inc [hl]
    ld hl, $ffc3
    inc [hl]

jr_05d_4031:
    ld a, [$dd66]
    ldh [$c8], a
    ld a, [$dd62]
    or a
    jr nz, jr_05d_4041

    ld a, $00
    ld [$dd60], a

jr_05d_4041:
    ld a, [$dd68]
    or a
    ret nz

    ld a, [$daa4]
    cp $03
    jr z, jr_05d_4051

    cp $04
    jr nz, jr_05d_4061

jr_05d_4051:
    ldh a, [$c3]
    cp $d0
    ret c

    ld a, $04
    ld [$dd65], a
    ld a, $01
    ld [$dd68], a
    ret


jr_05d_4061:
    ldh a, [$c3]
    cp $c0
    ret c

    ld a, $00
    ld [$dd60], a
    ld a, $01
    ld [$dd68], a
    ret


AnimFrameTable5D:
    ; ANIMATION -> its 32 frame pointers, index [$c7] = animation number
    ; ($00-$0D bank $5C, $0E-$20 $5D, $21-$2C $5E — ROM0 AnimTickSelectAndDraw
    ; picks the bank). Re-sectioned S112.
    dw $4173   ; [$00] (another bank's number: an unused default)
    dw $4173   ; [$01] (another bank's number: an unused default)
    dw $4173   ; [$02] (another bank's number: an unused default)
    dw $4173   ; [$03] (another bank's number: an unused default)
    dw $4173   ; [$04] (another bank's number: an unused default)
    dw $4173   ; [$05] (another bank's number: an unused default)
    dw $4173   ; [$06] (another bank's number: an unused default)
    dw $4173   ; [$07] (another bank's number: an unused default)
    dw $4173   ; [$08] (another bank's number: an unused default)
    dw $4173   ; [$09] (another bank's number: an unused default)
    dw $4173   ; [$0a] (another bank's number: an unused default)
    dw $4173   ; [$0b] (another bank's number: an unused default)
    dw $4173   ; [$0c] (another bank's number: an unused default)
    dw $4173   ; [$0d] (another bank's number: an unused default)
    dw Anim_0e_Blizzard      ; [$0e] Blizzard, IceStorm, SNOWSTAFF
    dw Anim_0f_Bolt          ; [$0f] Bolt, Lightning, BOLTSTAFF
    dw Anim_10_Zap           ; [$10] Zap
    dw Anim_11_Thordain      ; [$11] Thordain
    dw Anim_12_StopSpell     ; [$12] StopSpell, RobMagic, Sap, Defence, Slow, SlowAll (+6)
    dw Anim_13_RobMagic      ; [$13] RobMagic, TakeMagic, Upper, Increase, Speed, SpeedUp (+2)
    dw Anim_14_Heal          ; [$14] Heal, HealMore, HealAll, HealUs, HealUsAll, Farewell (+20)
    dw Anim_15_Sleep         ; [$15] Sleep, SleepAll, PoisonHit, NapAttack, Paralyze, SleepAir (+7)
    dw Anim_16_PanicAll      ; [$16] PanicAll, PaniDance, Curse, Ahhh, LureDance
    dw Anim_17_Surround      ; [$17] Surround, SandStorm
    dw Anim_18_Transform     ; [$18] Transform, CHGDRAGON, BeDragon
    dw Anim_19_MagicBack     ; [$19] MagicBack, Bounce
    dw Anim_1a_WhiteAir      ; [$1a] WhiteAir
    dw Anim_1b_RockThrow     ; [$1b] RockThrow
    dw Anim_1c_WhiteFire     ; [$1c] WhiteFire
    dw Anim_1d_TwinSlash     ; [$1d] TwinSlash, Massacre, EvilSlash, DrakSlash, BeastCut, SquallHit (+2)
    dw Anim_1e_FireSlash     ; [$1e] FireSlash
    dw Anim_1f_BoltSlash     ; [$1f] BoltSlash
    dw Anim_20_VacuSlash     ; [$20] VacuSlash
; bank $5D entry 1: start an animation — X from AnimTargetXTable5D[$db54] when [$dd68] != 0 (else 0 = fly in from the left), Y $60, [$c7] = [$daa4], [$c8] = its first frame (bank $02 entry 5) (S112)
AnimInit5D:
    ld a, $01
    ld [$dd62], a
    ld a, [$dd68]
    or a
    jr z, jr_05d_40d0

    ld a, [$db54]
    cp $07
    jr nc, jr_05d_410b

    add a
    ld hl, $4114
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]

jr_05d_40d0:
    ld hl, $ffc3
    ld a, a
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $60
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, [$daa4]
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $01
    ld [$dd60], a
    ld hl, $dd63
    ld a, l
    ld [$d7b4], a
    ld a, h
    ld [$d7b5], a
    ld hl, $0205
    rst $10
    ld hl, $dd62
    ld a, l
    ld [$d7b4], a
    ld a, h
    ld [$d7b5], a
    ret


jr_05d_410b:
    xor a
    ld [$dd60], a
    xor a
    ld [$dd62], a
    ret


AnimTargetXTable5D:
    ; X of the animation by [$db54] (AnimTargetSlot: 0 = off-screen left
    ; = the fly-in start, 1 = the middle, 2/3 = two foes, 4/5/6 = three
    ; foes); low byte read, the high byte unused. Used when [$dd68] != 0.
    dw $0000   ; slot 0
    dw $0050   ; slot 1
    dw $0038   ; slot 2
    dw $0068   ; slot 3
    dw $0020   ; slot 4
    dw $0050   ; slot 5
    dw $0080   ; slot 6
; NOTE: unreferenced fake-decode labels removed with this block: jr_05d_411a, jr_05d_411e
AnimBuildOAM5D:
    ldh a, [$cb]
    cp $28
    jr nc, jr_05d_4172

    ldh a, [$c7]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
    ldh a, [$c8]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
    ldh a, [$cb]
    sla a
    sla a
    ld l, a
    ld h, $c0

jr_05d_4145:
    ld a, [de]
    inc de
    cp $80
    jr z, jr_05d_4172

    ld b, a
    ldh a, [$c5]
    add b
    add $10
    ld [hl+], a
    ld a, [de]
    inc de
    ld b, a
    ldh a, [$c3]
    add b
    add $08
    ld [hl+], a
    ldh a, [$c9]
    ld b, a
    ld a, [de]
    inc de
    add b
    ld [hl+], a
    ld a, [de]
    inc de
    ld b, a
    ldh a, [$ca]
    xor b
    ld [hl+], a
    ldh a, [$cb]
    inc a
    ldh [$cb], a
    cp $28
    jr c, jr_05d_4145

jr_05d_4172:
    ret


; ============================================================================
; BATTLE ANIMATION DATA (bank $5D): per animation 32 dw frame pointers
; (unused slots point at an empty frame; slot $1F = the blank) and the
; frames: 4-byte sprites (dy, dx, tile, attr) — X = dx + [$c3] + 8,
; Y = dy + [$c5] + 16, tile + [$c9], attr XOR [$ca] — $80 end; the builder
; draws at most 40. MEASURED S112 (tools/census_battle_anims.py: all 45
; animations, every frame == the shadow OAM). Re-sectioned S112.
; ============================================================================
Anim_0e_Blizzard:   ; $4173 animation $0e — Blizzard, IceStorm, SNOWSTAFF
    dw Anim_0e_F00
    dw Anim_0e_F01
    dw Anim_0e_F02
    dw Anim_0e_F03
    dw Anim_0e_F04
    dw Anim_0e_F05
    dw Anim_0e_F06
    dw Anim_0e_F07
    dw Anim_0e_F08
    dw Anim_0e_F09
    dw Anim_0e_F10
    dw Anim_0e_F11
    dw Anim_0e_F12
    dw Anim_0e_F13
    dw Anim_0e_F13
    dw Anim_0e_F13
    dw Anim_0e_F13
    dw Anim_0e_F13
    dw Anim_0e_F13
    dw Anim_0e_F13
    dw Anim_0e_F13
    dw Anim_0e_F13
    dw Anim_0e_F13
    dw Anim_0e_F13
    dw Anim_0e_F13
    dw Anim_0e_F13
    dw Anim_0e_F13
    dw Anim_0e_F13
    dw Anim_0e_F13
    dw Anim_0e_F13
    dw Anim_0e_F13
    dw Anim_0e_F13
Anim_0e_F00:   ; $41b3 36 sprites
    db $d0, $d0, $03, $00   ; dy -48 dx -48 tile 3 attr $00
    db $d8, $b8, $0f, $00   ; dy -40 dx -72 tile 15 attr $00
    db $e3, $c1, $0f, $00   ; dy -29 dx -63 tile 15 attr $00
    db $e8, $b9, $03, $00   ; dy -24 dx -71 tile 3 attr $00
    db $d8, $d9, $03, $00   ; dy -40 dx -39 tile 3 attr $00
    db $d4, $c8, $03, $00   ; dy -44 dx -56 tile 3 attr $00
    db $f4, $d4, $03, $40   ; dy -12 dx -44 tile 3 attr $40
    db $f5, $c2, $03, $40   ; dy -11 dx -62 tile 3 attr $40
    db $d0, $b0, $12, $00   ; dy -48 dx -80 tile 18 attr $00
    db $d0, $c0, $12, $00   ; dy -48 dx -64 tile 18 attr $00
    db $e0, $b4, $12, $00   ; dy -32 dx -76 tile 18 attr $00
    db $e8, $f8, $05, $20   ; dy -24 dx -8 tile 5 attr $20
    db $f0, $e8, $05, $20   ; dy -16 dx -24 tile 5 attr $20
    db $d8, $e8, $04, $00   ; dy -40 dx -24 tile 4 attr $00
    db $e0, $d0, $05, $00   ; dy -32 dx -48 tile 5 attr $00
    db $e8, $c9, $05, $00   ; dy -24 dx -55 tile 5 attr $00
    db $e8, $d8, $07, $20   ; dy -24 dx -40 tile 7 attr $20
    db $e0, $f0, $07, $20   ; dy -32 dx -16 tile 7 attr $20
    db $f5, $28, $03, $60   ; dy -11 dx +40 tile 3 attr $60
    db $ed, $40, $0f, $60   ; dy -19 dx +64 tile 15 attr $60
    db $e2, $37, $0f, $60   ; dy -30 dx +55 tile 15 attr $60
    db $dd, $3f, $03, $60   ; dy -35 dx +63 tile 3 attr $60
    db $ed, $1f, $03, $60   ; dy -19 dx +31 tile 3 attr $60
    db $f1, $30, $03, $60   ; dy -15 dx +48 tile 3 attr $60
    db $d1, $24, $03, $20   ; dy -47 dx +36 tile 3 attr $20
    db $d0, $36, $03, $20   ; dy -48 dx +54 tile 3 attr $20
    db $f5, $48, $12, $60   ; dy -11 dx +72 tile 18 attr $60
    db $f5, $38, $12, $60   ; dy -11 dx +56 tile 18 attr $60
    db $e5, $44, $12, $60   ; dy -27 dx +68 tile 18 attr $60
    db $dd, $00, $05, $40   ; dy -35 dx +0 tile 5 attr $40
    db $d5, $10, $05, $40   ; dy -43 dx +16 tile 5 attr $40
    db $ed, $10, $04, $60   ; dy -19 dx +16 tile 4 attr $60
    db $e5, $28, $05, $60   ; dy -27 dx +40 tile 5 attr $60
    db $dd, $2f, $05, $60   ; dy -35 dx +47 tile 5 attr $60
    db $dd, $20, $07, $40   ; dy -35 dx +32 tile 7 attr $40
    db $e5, $08, $07, $40   ; dy -27 dx +8 tile 7 attr $40
    db $80
Anim_0e_F01:   ; $4244 36 sprites
    db $e0, $bc, $0f, $00   ; dy -32 dx -68 tile 15 attr $00
    db $d8, $c4, $12, $00   ; dy -40 dx -60 tile 18 attr $00
    db $e0, $cc, $03, $00   ; dy -32 dx -52 tile 3 attr $00
    db $d3, $d4, $03, $00   ; dy -45 dx -44 tile 3 attr $00
    db $f8, $c6, $03, $40   ; dy -8 dx -58 tile 3 attr $40
    db $f8, $f2, $05, $20   ; dy -8 dx -14 tile 5 attr $20
    db $e8, $fc, $08, $60   ; dy -24 dx -4 tile 8 attr $60
    db $e4, $f4, $09, $20   ; dy -28 dx -12 tile 9 attr $20
    db $f0, $e9, $05, $40   ; dy -16 dx -23 tile 5 attr $40
    db $dc, $b0, $13, $00   ; dy -36 dx -80 tile 19 attr $00
    db $e8, $b8, $13, $00   ; dy -24 dx -72 tile 19 attr $00
    db $f8, $e0, $02, $00   ; dy -8 dx -32 tile 2 attr $00
    db $eb, $c8, $10, $00   ; dy -21 dx -56 tile 16 attr $00
    db $f0, $bd, $01, $00   ; dy -16 dx -67 tile 1 attr $00
    db $e0, $e9, $07, $00   ; dy -32 dx -23 tile 7 attr $00
    db $dd, $dc, $00, $00   ; dy -35 dx -36 tile 0 attr $00
    db $e7, $d5, $03, $00   ; dy -25 dx -43 tile 3 attr $00
    db $f0, $d8, $01, $00   ; dy -16 dx -40 tile 1 attr $00
    db $e8, $3c, $0f, $60   ; dy -24 dx +60 tile 15 attr $60
    db $f0, $34, $12, $60   ; dy -16 dx +52 tile 18 attr $60
    db $e8, $2c, $03, $60   ; dy -24 dx +44 tile 3 attr $60
    db $f5, $24, $03, $60   ; dy -11 dx +36 tile 3 attr $60
    db $d0, $32, $03, $20   ; dy -48 dx +50 tile 3 attr $20
    db $d0, $06, $05, $40   ; dy -48 dx +6 tile 5 attr $40
    db $e0, $fc, $08, $00   ; dy -32 dx -4 tile 8 attr $00
    db $e4, $04, $09, $40   ; dy -28 dx +4 tile 9 attr $40
    db $d8, $0f, $05, $20   ; dy -40 dx +15 tile 5 attr $20
    db $ec, $48, $13, $60   ; dy -20 dx +72 tile 19 attr $60
    db $e0, $40, $13, $60   ; dy -32 dx +64 tile 19 attr $60
    db $d0, $18, $02, $60   ; dy -48 dx +24 tile 2 attr $60
    db $dd, $30, $10, $60   ; dy -35 dx +48 tile 16 attr $60
    db $d8, $3b, $01, $60   ; dy -40 dx +59 tile 1 attr $60
    db $e8, $0f, $07, $60   ; dy -24 dx +15 tile 7 attr $60
    db $eb, $1c, $00, $60   ; dy -21 dx +28 tile 0 attr $60
    db $e1, $23, $03, $60   ; dy -31 dx +35 tile 3 attr $60
    db $d8, $20, $01, $60   ; dy -40 dx +32 tile 1 attr $60
    db $80
Anim_0e_F02:   ; $42d5 36 sprites
    db $f3, $cd, $10, $00   ; dy -13 dx -51 tile 16 attr $00
    db $f8, $c4, $01, $00   ; dy -8 dx -60 tile 1 attr $00
    db $e8, $d1, $03, $00   ; dy -24 dx -47 tile 3 attr $00
    db $f0, $da, $03, $00   ; dy -16 dx -38 tile 3 attr $00
    db $e8, $fc, $06, $60   ; dy -24 dx -4 tile 6 attr $60
    db $f0, $f8, $08, $00   ; dy -16 dx -8 tile 8 attr $00
    db $f8, $f4, $07, $00   ; dy -8 dx -12 tile 7 attr $00
    db $e4, $f4, $07, $00   ; dy -28 dx -12 tile 7 attr $00
    db $f8, $e6, $03, $40   ; dy -8 dx -26 tile 3 attr $40
    db $ec, $f0, $05, $40   ; dy -20 dx -16 tile 5 attr $40
    db $e8, $e0, $02, $00   ; dy -24 dx -32 tile 2 attr $00
    db $e4, $e8, $07, $00   ; dy -28 dx -24 tile 7 attr $00
    db $f0, $b7, $10, $00   ; dy -16 dx -73 tile 16 attr $00
    db $d0, $b0, $12, $00   ; dy -48 dx -80 tile 18 attr $00
    db $d8, $e0, $0f, $00   ; dy -40 dx -32 tile 15 attr $00
    db $e8, $c1, $10, $00   ; dy -24 dx -63 tile 16 attr $00
    db $e0, $ce, $01, $00   ; dy -32 dx -50 tile 1 attr $00
    db $f8, $d5, $11, $00   ; dy -8 dx -43 tile 17 attr $00
    db $d5, $2b, $10, $60   ; dy -43 dx +43 tile 16 attr $60
    db $d0, $34, $01, $60   ; dy -48 dx +52 tile 1 attr $60
    db $e0, $27, $03, $60   ; dy -32 dx +39 tile 3 attr $60
    db $d8, $1e, $03, $60   ; dy -40 dx +30 tile 3 attr $60
    db $e0, $fc, $06, $00   ; dy -32 dx -4 tile 6 attr $00
    db $d8, $00, $08, $60   ; dy -40 dx +0 tile 8 attr $60
    db $d0, $04, $07, $60   ; dy -48 dx +4 tile 7 attr $60
    db $e4, $04, $07, $60   ; dy -28 dx +4 tile 7 attr $60
    db $d0, $12, $03, $20   ; dy -48 dx +18 tile 3 attr $20
    db $dc, $08, $05, $20   ; dy -36 dx +8 tile 5 attr $20
    db $e0, $18, $02, $60   ; dy -32 dx +24 tile 2 attr $60
    db $e4, $10, $07, $60   ; dy -28 dx +16 tile 7 attr $60
    db $d8, $41, $10, $60   ; dy -40 dx +65 tile 16 attr $60
    db $f8, $48, $12, $60   ; dy -8 dx +72 tile 18 attr $60
    db $f0, $18, $0f, $60   ; dy -16 dx +24 tile 15 attr $60
    db $e0, $37, $10, $60   ; dy -32 dx +55 tile 16 attr $60
    db $e8, $2a, $01, $60   ; dy -24 dx +42 tile 1 attr $60
    db $d0, $23, $11, $60   ; dy -48 dx +35 tile 17 attr $60
    db $80
Anim_0e_F03:   ; $4366 40 sprites
    db $e8, $f5, $07, $00   ; dy -24 dx -11 tile 7 attr $00
    db $f8, $da, $01, $00   ; dy -8 dx -38 tile 1 attr $00
    db $f8, $cb, $10, $00   ; dy -8 dx -53 tile 16 attr $00
    db $e8, $fd, $0a, $60   ; dy -24 dx -3 tile 10 attr $60
    db $f0, $05, $08, $40   ; dy -16 dx +5 tile 8 attr $40
    db $f0, $fd, $06, $20   ; dy -16 dx -3 tile 6 attr $20
    db $e8, $ed, $09, $00   ; dy -24 dx -19 tile 9 attr $00
    db $e8, $d9, $02, $00   ; dy -24 dx -39 tile 2 attr $00
    db $f8, $f8, $05, $40   ; dy -8 dx -8 tile 5 attr $40
    db $f8, $02, $05, $40   ; dy -8 dx +2 tile 5 attr $40
    db $f0, $f0, $06, $20   ; dy -16 dx -16 tile 6 attr $20
    db $f8, $eb, $03, $40   ; dy -8 dx -21 tile 3 attr $40
    db $f3, $e3, $0f, $00   ; dy -13 dx -29 tile 15 attr $00
    db $e8, $e1, $07, $00   ; dy -24 dx -31 tile 7 attr $00
    db $e0, $e7, $00, $00   ; dy -32 dx -25 tile 0 attr $00
    db $e0, $d6, $03, $00   ; dy -32 dx -42 tile 3 attr $00
    db $f0, $d5, $03, $00   ; dy -16 dx -43 tile 3 attr $00
    db $e0, $c9, $0f, $00   ; dy -32 dx -55 tile 15 attr $00
    db $e0, $03, $07, $60   ; dy -32 dx +3 tile 7 attr $60
    db $d0, $1e, $01, $60   ; dy -48 dx +30 tile 1 attr $60
    db $d0, $2d, $10, $60   ; dy -48 dx +45 tile 16 attr $60
    db $e0, $fb, $0a, $00   ; dy -32 dx -5 tile 10 attr $00
    db $d8, $f3, $08, $20   ; dy -40 dx -13 tile 8 attr $20
    db $d8, $fb, $06, $40   ; dy -40 dx -5 tile 6 attr $40
    db $e0, $0b, $09, $60   ; dy -32 dx +11 tile 9 attr $60
    db $e0, $1f, $02, $60   ; dy -32 dx +31 tile 2 attr $60
    db $d0, $00, $05, $20   ; dy -48 dx +0 tile 5 attr $20
    db $d0, $f6, $05, $20   ; dy -48 dx -10 tile 5 attr $20
    db $d8, $08, $06, $40   ; dy -40 dx +8 tile 6 attr $40
    db $d0, $0d, $03, $20   ; dy -48 dx +13 tile 3 attr $20
    db $d5, $15, $0f, $60   ; dy -43 dx +21 tile 15 attr $60
    db $e0, $17, $07, $60   ; dy -32 dx +23 tile 7 attr $60
    db $d8, $23, $03, $60   ; dy -40 dx +35 tile 3 attr $60
    db $e8, $11, $00, $60   ; dy -24 dx +17 tile 0 attr $60
    db $e8, $22, $03, $60   ; dy -24 dx +34 tile 3 attr $60
    db $e8, $2f, $0f, $60   ; dy -24 dx +47 tile 15 attr $60
    db $f0, $1a, $06, $00   ; dy -16 dx +26 tile 6 attr $00
    db $f0, $38, $12, $00   ; dy -16 dx +56 tile 18 attr $00
    db $d8, $de, $06, $60   ; dy -40 dx -34 tile 6 attr $60
    db $d8, $c0, $12, $60   ; dy -40 dx -64 tile 18 attr $60
    db $80
Anim_0e_F04:   ; $4407 40 sprites
    db $d8, $b8, $0f, $00   ; dy -40 dx -72 tile 15 attr $00
    db $e3, $c1, $0f, $00   ; dy -29 dx -63 tile 15 attr $00
    db $d4, $c8, $03, $00   ; dy -44 dx -56 tile 3 attr $00
    db $d0, $b0, $12, $00   ; dy -48 dx -80 tile 18 attr $00
    db $d0, $c0, $12, $00   ; dy -48 dx -64 tile 18 attr $00
    db $e0, $b4, $12, $00   ; dy -32 dx -76 tile 18 attr $00
    db $f0, $40, $0f, $60   ; dy -16 dx +64 tile 15 attr $60
    db $e5, $37, $0f, $60   ; dy -27 dx +55 tile 15 attr $60
    db $f4, $30, $03, $60   ; dy -12 dx +48 tile 3 attr $60
    db $f8, $48, $12, $60   ; dy -8 dx +72 tile 18 attr $60
    db $f8, $38, $12, $60   ; dy -8 dx +56 tile 18 attr $60
    db $e8, $44, $12, $60   ; dy -24 dx +68 tile 18 attr $60
    db $f8, $fb, $03, $40   ; dy -8 dx -5 tile 3 attr $40
    db $f8, $f3, $0f, $00   ; dy -8 dx -13 tile 15 attr $00
    db $f0, $f3, $07, $00   ; dy -16 dx -13 tile 7 attr $00
    db $e8, $03, $05, $00   ; dy -24 dx +3 tile 5 attr $00
    db $e8, $fb, $08, $40   ; dy -24 dx -5 tile 8 attr $40
    db $f8, $05, $06, $20   ; dy -8 dx +5 tile 6 attr $20
    db $f0, $fb, $09, $00   ; dy -16 dx -5 tile 9 attr $00
    db $e8, $eb, $02, $00   ; dy -24 dx -21 tile 2 attr $00
    db $e8, $0b, $00, $60   ; dy -24 dx +11 tile 0 attr $60
    db $e8, $f3, $09, $20   ; dy -24 dx -13 tile 9 attr $20
    db $f0, $03, $05, $20   ; dy -16 dx +3 tile 5 attr $20
    db $f0, $0b, $08, $20   ; dy -16 dx +11 tile 8 attr $20
    db $e0, $ed, $00, $00   ; dy -32 dx -19 tile 0 attr $00
    db $d0, $fd, $03, $20   ; dy -48 dx -3 tile 3 attr $20
    db $d0, $05, $0f, $60   ; dy -48 dx +5 tile 15 attr $60
    db $d8, $05, $07, $60   ; dy -40 dx +5 tile 7 attr $60
    db $e0, $f5, $05, $60   ; dy -32 dx -11 tile 5 attr $60
    db $e0, $fd, $08, $20   ; dy -32 dx -3 tile 8 attr $20
    db $d0, $f3, $06, $40   ; dy -48 dx -13 tile 6 attr $40
    db $d8, $fd, $09, $60   ; dy -40 dx -3 tile 9 attr $60
    db $e0, $05, $09, $40   ; dy -32 dx +5 tile 9 attr $40
    db $d8, $f5, $05, $40   ; dy -40 dx -11 tile 5 attr $40
    db $d8, $ed, $08, $40   ; dy -40 dx -19 tile 8 attr $40
    db $e0, $0d, $02, $60   ; dy -32 dx +13 tile 2 attr $60
    db $d0, $e8, $0a, $00   ; dy -48 dx -24 tile 10 attr $00
    db $f8, $10, $0a, $60   ; dy -8 dx +16 tile 10 attr $60
    db $f8, $1a, $06, $60   ; dy -8 dx +26 tile 6 attr $60
    db $d0, $de, $06, $00   ; dy -48 dx -34 tile 6 attr $00
    db $80
Anim_0e_F05:   ; $44a8 16 sprites
    db $df, $fd, $08, $00   ; dy -33 dx -3 tile 8 attr $00
    db $df, $06, $07, $60   ; dy -33 dx +6 tile 7 attr $60
    db $df, $f4, $05, $00   ; dy -33 dx -12 tile 5 attr $00
    db $df, $eb, $03, $00   ; dy -33 dx -21 tile 3 attr $00
    db $df, $0f, $02, $00   ; dy -33 dx +15 tile 2 attr $00
    db $d6, $f4, $05, $20   ; dy -42 dx -12 tile 5 attr $20
    db $d6, $fd, $07, $00   ; dy -42 dx -3 tile 7 attr $00
    db $d6, $06, $09, $40   ; dy -42 dx +6 tile 9 attr $40
    db $f2, $04, $05, $40   ; dy -14 dx +4 tile 5 attr $40
    db $e9, $fb, $08, $60   ; dy -23 dx -5 tile 8 attr $60
    db $e9, $f2, $07, $00   ; dy -23 dx -14 tile 7 attr $00
    db $e9, $04, $05, $60   ; dy -23 dx +4 tile 5 attr $60
    db $e9, $0d, $03, $60   ; dy -23 dx +13 tile 3 attr $60
    db $f2, $fb, $07, $60   ; dy -14 dx -5 tile 7 attr $60
    db $f2, $f2, $09, $20   ; dy -14 dx -14 tile 9 attr $20
    db $e9, $e9, $02, $60   ; dy -23 dx -23 tile 2 attr $60
    db $80
Anim_0e_F06:   ; $44e9 36 sprites
    db $d0, $d0, $0b, $20   ; dy -48 dx -48 tile 11 attr $20
    db $d8, $ce, $0c, $20   ; dy -40 dx -50 tile 12 attr $20
    db $e0, $cc, $0b, $20   ; dy -32 dx -52 tile 11 attr $20
    db $e8, $cc, $0c, $20   ; dy -24 dx -52 tile 12 attr $20
    db $f0, $ce, $0b, $20   ; dy -16 dx -50 tile 11 attr $20
    db $f8, $d0, $0c, $20   ; dy -8 dx -48 tile 12 attr $20
    db $d0, $b0, $0b, $20   ; dy -48 dx -80 tile 11 attr $20
    db $d8, $b0, $0c, $20   ; dy -40 dx -80 tile 12 attr $20
    db $e0, $b0, $0b, $20   ; dy -32 dx -80 tile 11 attr $20
    db $e8, $b0, $0c, $20   ; dy -24 dx -80 tile 12 attr $20
    db $f0, $b0, $0b, $20   ; dy -16 dx -80 tile 11 attr $20
    db $f8, $b0, $0c, $20   ; dy -8 dx -80 tile 12 attr $20
    db $d0, $c0, $0c, $20   ; dy -48 dx -64 tile 12 attr $20
    db $d8, $be, $0b, $20   ; dy -40 dx -66 tile 11 attr $20
    db $e0, $bc, $0c, $20   ; dy -32 dx -68 tile 12 attr $20
    db $e8, $bc, $0b, $20   ; dy -24 dx -68 tile 11 attr $20
    db $f0, $be, $0c, $20   ; dy -16 dx -66 tile 12 attr $20
    db $f8, $c0, $0b, $20   ; dy -8 dx -64 tile 11 attr $20
    db $d0, $28, $0b, $00   ; dy -48 dx +40 tile 11 attr $00
    db $d8, $2a, $0c, $00   ; dy -40 dx +42 tile 12 attr $00
    db $e0, $2c, $0b, $00   ; dy -32 dx +44 tile 11 attr $00
    db $e8, $2c, $0c, $00   ; dy -24 dx +44 tile 12 attr $00
    db $f0, $2a, $0b, $00   ; dy -16 dx +42 tile 11 attr $00
    db $f8, $28, $0c, $00   ; dy -8 dx +40 tile 12 attr $00
    db $d0, $48, $0b, $00   ; dy -48 dx +72 tile 11 attr $00
    db $d8, $48, $0c, $00   ; dy -40 dx +72 tile 12 attr $00
    db $e0, $48, $0b, $00   ; dy -32 dx +72 tile 11 attr $00
    db $e8, $48, $0c, $00   ; dy -24 dx +72 tile 12 attr $00
    db $f0, $48, $0b, $00   ; dy -16 dx +72 tile 11 attr $00
    db $f8, $48, $0c, $00   ; dy -8 dx +72 tile 12 attr $00
    db $d0, $38, $0c, $00   ; dy -48 dx +56 tile 12 attr $00
    db $d8, $3a, $0b, $00   ; dy -40 dx +58 tile 11 attr $00
    db $e0, $3c, $0c, $00   ; dy -32 dx +60 tile 12 attr $00
    db $e8, $3c, $0b, $00   ; dy -24 dx +60 tile 11 attr $00
    db $f0, $3a, $0c, $00   ; dy -16 dx +58 tile 12 attr $00
    db $f8, $38, $0b, $00   ; dy -8 dx +56 tile 11 attr $00
    db $80
Anim_0e_F07:   ; $457a 36 sprites
    db $d0, $d8, $0c, $20   ; dy -48 dx -40 tile 12 attr $20
    db $d8, $d6, $0b, $20   ; dy -40 dx -42 tile 11 attr $20
    db $e0, $d4, $0c, $20   ; dy -32 dx -44 tile 12 attr $20
    db $e8, $d4, $0b, $20   ; dy -24 dx -44 tile 11 attr $20
    db $f0, $d6, $0c, $20   ; dy -16 dx -42 tile 12 attr $20
    db $f8, $d8, $0b, $20   ; dy -8 dx -40 tile 11 attr $20
    db $d0, $c8, $0b, $20   ; dy -48 dx -56 tile 11 attr $20
    db $d8, $c6, $0c, $20   ; dy -40 dx -58 tile 12 attr $20
    db $e0, $c4, $0b, $20   ; dy -32 dx -60 tile 11 attr $20
    db $e8, $c4, $0c, $20   ; dy -24 dx -60 tile 12 attr $20
    db $f0, $c6, $0b, $20   ; dy -16 dx -58 tile 11 attr $20
    db $f8, $c8, $0c, $20   ; dy -8 dx -56 tile 12 attr $20
    db $d0, $b8, $0c, $20   ; dy -48 dx -72 tile 12 attr $20
    db $d8, $b6, $0b, $20   ; dy -40 dx -74 tile 11 attr $20
    db $e0, $b4, $0c, $20   ; dy -32 dx -76 tile 12 attr $20
    db $e8, $b4, $0b, $20   ; dy -24 dx -76 tile 11 attr $20
    db $f0, $b6, $0c, $20   ; dy -16 dx -74 tile 12 attr $20
    db $f8, $b8, $0b, $20   ; dy -8 dx -72 tile 11 attr $20
    db $d0, $20, $0c, $00   ; dy -48 dx +32 tile 12 attr $00
    db $d8, $22, $0b, $00   ; dy -40 dx +34 tile 11 attr $00
    db $e0, $24, $0c, $00   ; dy -32 dx +36 tile 12 attr $00
    db $e8, $24, $0b, $00   ; dy -24 dx +36 tile 11 attr $00
    db $f0, $22, $0c, $00   ; dy -16 dx +34 tile 12 attr $00
    db $f8, $20, $0b, $00   ; dy -8 dx +32 tile 11 attr $00
    db $d0, $30, $0b, $00   ; dy -48 dx +48 tile 11 attr $00
    db $d8, $32, $0c, $00   ; dy -40 dx +50 tile 12 attr $00
    db $e0, $34, $0b, $00   ; dy -32 dx +52 tile 11 attr $00
    db $e8, $34, $0c, $00   ; dy -24 dx +52 tile 12 attr $00
    db $f0, $32, $0b, $00   ; dy -16 dx +50 tile 11 attr $00
    db $f8, $30, $0c, $00   ; dy -8 dx +48 tile 12 attr $00
    db $d0, $40, $0c, $00   ; dy -48 dx +64 tile 12 attr $00
    db $d8, $42, $0b, $00   ; dy -40 dx +66 tile 11 attr $00
    db $e0, $44, $0c, $00   ; dy -32 dx +68 tile 12 attr $00
    db $e8, $44, $0b, $00   ; dy -24 dx +68 tile 11 attr $00
    db $f0, $42, $0c, $00   ; dy -16 dx +66 tile 12 attr $00
    db $f8, $40, $0b, $00   ; dy -8 dx +64 tile 11 attr $00
    db $80
Anim_0e_F08:   ; $460b 36 sprites
    db $d0, $e0, $0b, $20   ; dy -48 dx -32 tile 11 attr $20
    db $d8, $de, $0c, $20   ; dy -40 dx -34 tile 12 attr $20
    db $e0, $dc, $0b, $20   ; dy -32 dx -36 tile 11 attr $20
    db $e8, $dc, $0c, $20   ; dy -24 dx -36 tile 12 attr $20
    db $f0, $de, $0b, $20   ; dy -16 dx -34 tile 11 attr $20
    db $f8, $e0, $0c, $20   ; dy -8 dx -32 tile 12 attr $20
    db $d0, $d0, $0c, $20   ; dy -48 dx -48 tile 12 attr $20
    db $d8, $ce, $0b, $20   ; dy -40 dx -50 tile 11 attr $20
    db $e0, $cc, $0c, $20   ; dy -32 dx -52 tile 12 attr $20
    db $e8, $cc, $0b, $20   ; dy -24 dx -52 tile 11 attr $20
    db $f0, $ce, $0c, $20   ; dy -16 dx -50 tile 12 attr $20
    db $f8, $d0, $0b, $20   ; dy -8 dx -48 tile 11 attr $20
    db $d0, $c0, $0b, $20   ; dy -48 dx -64 tile 11 attr $20
    db $d8, $be, $0c, $20   ; dy -40 dx -66 tile 12 attr $20
    db $e0, $bc, $0b, $20   ; dy -32 dx -68 tile 11 attr $20
    db $e8, $bc, $0c, $20   ; dy -24 dx -68 tile 12 attr $20
    db $f0, $be, $0b, $20   ; dy -16 dx -66 tile 11 attr $20
    db $f8, $c0, $0c, $20   ; dy -8 dx -64 tile 12 attr $20
    db $d0, $38, $0b, $00   ; dy -48 dx +56 tile 11 attr $00
    db $d8, $3a, $0c, $00   ; dy -40 dx +58 tile 12 attr $00
    db $e0, $3c, $0b, $00   ; dy -32 dx +60 tile 11 attr $00
    db $e8, $3c, $0c, $00   ; dy -24 dx +60 tile 12 attr $00
    db $f0, $3a, $0b, $00   ; dy -16 dx +58 tile 11 attr $00
    db $f8, $38, $0c, $00   ; dy -8 dx +56 tile 12 attr $00
    db $d0, $18, $0b, $00   ; dy -48 dx +24 tile 11 attr $00
    db $d8, $1a, $0c, $00   ; dy -40 dx +26 tile 12 attr $00
    db $e0, $1c, $0b, $00   ; dy -32 dx +28 tile 11 attr $00
    db $e8, $1c, $0c, $00   ; dy -24 dx +28 tile 12 attr $00
    db $f0, $1a, $0b, $00   ; dy -16 dx +26 tile 11 attr $00
    db $f8, $18, $0c, $00   ; dy -8 dx +24 tile 12 attr $00
    db $d0, $28, $0c, $00   ; dy -48 dx +40 tile 12 attr $00
    db $d8, $2a, $0b, $00   ; dy -40 dx +42 tile 11 attr $00
    db $e0, $2c, $0c, $00   ; dy -32 dx +44 tile 12 attr $00
    db $e8, $2c, $0b, $00   ; dy -24 dx +44 tile 11 attr $00
    db $f0, $2a, $0c, $00   ; dy -16 dx +42 tile 12 attr $00
    db $f8, $28, $0b, $00   ; dy -8 dx +40 tile 11 attr $00
    db $80
Anim_0e_F09:   ; $469c 36 sprites
    db $d0, $e8, $0c, $20   ; dy -48 dx -24 tile 12 attr $20
    db $d8, $e6, $0b, $20   ; dy -40 dx -26 tile 11 attr $20
    db $e0, $e4, $0c, $20   ; dy -32 dx -28 tile 12 attr $20
    db $e8, $e4, $0b, $20   ; dy -24 dx -28 tile 11 attr $20
    db $f0, $e6, $0c, $20   ; dy -16 dx -26 tile 12 attr $20
    db $f8, $e8, $0b, $20   ; dy -8 dx -24 tile 11 attr $20
    db $d0, $d8, $0b, $20   ; dy -48 dx -40 tile 11 attr $20
    db $d8, $d6, $0c, $20   ; dy -40 dx -42 tile 12 attr $20
    db $e0, $d4, $0b, $20   ; dy -32 dx -44 tile 11 attr $20
    db $e8, $d4, $0c, $20   ; dy -24 dx -44 tile 12 attr $20
    db $f0, $d6, $0b, $20   ; dy -16 dx -42 tile 11 attr $20
    db $f8, $d8, $0c, $20   ; dy -8 dx -40 tile 12 attr $20
    db $d0, $c8, $0c, $20   ; dy -48 dx -56 tile 12 attr $20
    db $d8, $c6, $0b, $20   ; dy -40 dx -58 tile 11 attr $20
    db $e0, $c4, $0c, $20   ; dy -32 dx -60 tile 12 attr $20
    db $e8, $c4, $0b, $20   ; dy -24 dx -60 tile 11 attr $20
    db $f0, $c6, $0c, $20   ; dy -16 dx -58 tile 12 attr $20
    db $f8, $c8, $0b, $20   ; dy -8 dx -56 tile 11 attr $20
    db $d0, $30, $0c, $00   ; dy -48 dx +48 tile 12 attr $00
    db $d8, $32, $0b, $00   ; dy -40 dx +50 tile 11 attr $00
    db $e0, $34, $0c, $00   ; dy -32 dx +52 tile 12 attr $00
    db $e8, $34, $0b, $00   ; dy -24 dx +52 tile 11 attr $00
    db $f0, $32, $0c, $00   ; dy -16 dx +50 tile 12 attr $00
    db $f8, $30, $0b, $00   ; dy -8 dx +48 tile 11 attr $00
    db $d0, $20, $0b, $00   ; dy -48 dx +32 tile 11 attr $00
    db $d8, $22, $0c, $00   ; dy -40 dx +34 tile 12 attr $00
    db $e0, $24, $0b, $00   ; dy -32 dx +36 tile 11 attr $00
    db $e8, $24, $0c, $00   ; dy -24 dx +36 tile 12 attr $00
    db $f0, $22, $0b, $00   ; dy -16 dx +34 tile 11 attr $00
    db $f8, $20, $0c, $00   ; dy -8 dx +32 tile 12 attr $00
    db $d0, $10, $0c, $00   ; dy -48 dx +16 tile 12 attr $00
    db $d8, $12, $0b, $00   ; dy -40 dx +18 tile 11 attr $00
    db $e0, $14, $0c, $00   ; dy -32 dx +20 tile 12 attr $00
    db $e8, $14, $0b, $00   ; dy -24 dx +20 tile 11 attr $00
    db $f0, $12, $0c, $00   ; dy -16 dx +18 tile 12 attr $00
    db $f8, $10, $0b, $00   ; dy -8 dx +16 tile 11 attr $00
    db $80
Anim_0e_F10:   ; $472d 36 sprites
    db $d0, $f0, $0b, $20   ; dy -48 dx -16 tile 11 attr $20
    db $d8, $ec, $0c, $20   ; dy -40 dx -20 tile 12 attr $20
    db $e0, $e8, $0b, $20   ; dy -32 dx -24 tile 11 attr $20
    db $e8, $e8, $0c, $20   ; dy -24 dx -24 tile 12 attr $20
    db $f0, $ec, $0b, $20   ; dy -16 dx -20 tile 11 attr $20
    db $f8, $f0, $0c, $20   ; dy -8 dx -16 tile 12 attr $20
    db $d0, $e0, $0c, $20   ; dy -48 dx -32 tile 12 attr $20
    db $d8, $dc, $0b, $20   ; dy -40 dx -36 tile 11 attr $20
    db $e0, $d8, $0c, $20   ; dy -32 dx -40 tile 12 attr $20
    db $e8, $d8, $0b, $20   ; dy -24 dx -40 tile 11 attr $20
    db $f0, $dc, $0c, $20   ; dy -16 dx -36 tile 12 attr $20
    db $f8, $e0, $0b, $20   ; dy -8 dx -32 tile 11 attr $20
    db $d0, $d0, $0b, $20   ; dy -48 dx -48 tile 11 attr $20
    db $d8, $cc, $0c, $20   ; dy -40 dx -52 tile 12 attr $20
    db $e0, $c8, $0b, $20   ; dy -32 dx -56 tile 11 attr $20
    db $e8, $c8, $0c, $20   ; dy -24 dx -56 tile 12 attr $20
    db $f0, $cc, $0b, $20   ; dy -16 dx -52 tile 11 attr $20
    db $f8, $d0, $0c, $20   ; dy -8 dx -48 tile 12 attr $20
    db $d0, $28, $0b, $00   ; dy -48 dx +40 tile 11 attr $00
    db $d8, $2c, $0c, $00   ; dy -40 dx +44 tile 12 attr $00
    db $e0, $30, $0b, $00   ; dy -32 dx +48 tile 11 attr $00
    db $e8, $30, $0c, $00   ; dy -24 dx +48 tile 12 attr $00
    db $f0, $2c, $0b, $00   ; dy -16 dx +44 tile 11 attr $00
    db $f8, $28, $0c, $00   ; dy -8 dx +40 tile 12 attr $00
    db $d0, $18, $0c, $00   ; dy -48 dx +24 tile 12 attr $00
    db $d8, $1c, $0b, $00   ; dy -40 dx +28 tile 11 attr $00
    db $e0, $20, $0c, $00   ; dy -32 dx +32 tile 12 attr $00
    db $e8, $20, $0b, $00   ; dy -24 dx +32 tile 11 attr $00
    db $f0, $1c, $0c, $00   ; dy -16 dx +28 tile 12 attr $00
    db $f8, $18, $0b, $00   ; dy -8 dx +24 tile 11 attr $00
    db $d0, $08, $0b, $00   ; dy -48 dx +8 tile 11 attr $00
    db $d8, $0c, $0c, $00   ; dy -40 dx +12 tile 12 attr $00
    db $e0, $10, $0b, $00   ; dy -32 dx +16 tile 11 attr $00
    db $e8, $10, $0c, $00   ; dy -24 dx +16 tile 12 attr $00
    db $f0, $0c, $0b, $00   ; dy -16 dx +12 tile 11 attr $00
    db $f8, $08, $0c, $00   ; dy -8 dx +8 tile 12 attr $00
    db $80
Anim_0e_F11:   ; $47be 36 sprites
    db $d0, $f8, $0c, $20   ; dy -48 dx -8 tile 12 attr $20
    db $d8, $f8, $0b, $20   ; dy -40 dx -8 tile 11 attr $20
    db $e0, $f8, $0c, $20   ; dy -32 dx -8 tile 12 attr $20
    db $e8, $f8, $0b, $20   ; dy -24 dx -8 tile 11 attr $20
    db $f0, $f8, $0c, $20   ; dy -16 dx -8 tile 12 attr $20
    db $f8, $f8, $0b, $20   ; dy -8 dx -8 tile 11 attr $20
    db $d0, $e8, $0b, $20   ; dy -48 dx -24 tile 11 attr $20
    db $d8, $e4, $0c, $20   ; dy -40 dx -28 tile 12 attr $20
    db $e0, $e0, $0b, $20   ; dy -32 dx -32 tile 11 attr $20
    db $e8, $e0, $0c, $20   ; dy -24 dx -32 tile 12 attr $20
    db $f0, $e4, $0b, $20   ; dy -16 dx -28 tile 11 attr $20
    db $f8, $e8, $0c, $20   ; dy -8 dx -24 tile 12 attr $20
    db $d0, $d8, $0c, $20   ; dy -48 dx -40 tile 12 attr $20
    db $d8, $d4, $0b, $20   ; dy -40 dx -44 tile 11 attr $20
    db $e0, $d0, $0c, $20   ; dy -32 dx -48 tile 12 attr $20
    db $e8, $d0, $0b, $20   ; dy -24 dx -48 tile 11 attr $20
    db $f0, $d4, $0c, $20   ; dy -16 dx -44 tile 12 attr $20
    db $f8, $d8, $0b, $20   ; dy -8 dx -40 tile 11 attr $20
    db $d0, $20, $0c, $00   ; dy -48 dx +32 tile 12 attr $00
    db $d8, $24, $0b, $00   ; dy -40 dx +36 tile 11 attr $00
    db $e0, $28, $0c, $00   ; dy -32 dx +40 tile 12 attr $00
    db $e8, $28, $0b, $00   ; dy -24 dx +40 tile 11 attr $00
    db $f0, $24, $0c, $00   ; dy -16 dx +36 tile 12 attr $00
    db $f8, $20, $0b, $00   ; dy -8 dx +32 tile 11 attr $00
    db $d0, $10, $0b, $00   ; dy -48 dx +16 tile 11 attr $00
    db $d8, $14, $0c, $00   ; dy -40 dx +20 tile 12 attr $00
    db $e0, $18, $0b, $00   ; dy -32 dx +24 tile 11 attr $00
    db $e8, $18, $0c, $00   ; dy -24 dx +24 tile 12 attr $00
    db $f0, $14, $0b, $00   ; dy -16 dx +20 tile 11 attr $00
    db $f8, $10, $0c, $00   ; dy -8 dx +16 tile 12 attr $00
    db $d0, $00, $0c, $00   ; dy -48 dx +0 tile 12 attr $00
    db $d8, $00, $0b, $00   ; dy -40 dx +0 tile 11 attr $00
    db $e0, $00, $0c, $00   ; dy -32 dx +0 tile 12 attr $00
    db $e8, $00, $0b, $00   ; dy -24 dx +0 tile 11 attr $00
    db $f0, $00, $0c, $00   ; dy -16 dx +0 tile 12 attr $00
    db $f8, $00, $0b, $00   ; dy -8 dx +0 tile 11 attr $00
    db $80
Anim_0e_F12:   ; $484f 18 sprites
    db $d0, $ee, $0b, $20   ; dy -48 dx -18 tile 11 attr $20
    db $d8, $ea, $0c, $20   ; dy -40 dx -22 tile 12 attr $20
    db $e0, $e6, $0b, $20   ; dy -32 dx -26 tile 11 attr $20
    db $e8, $e6, $0c, $20   ; dy -24 dx -26 tile 12 attr $20
    db $f0, $ea, $0b, $20   ; dy -16 dx -22 tile 11 attr $20
    db $f8, $ee, $0c, $20   ; dy -8 dx -18 tile 12 attr $20
    db $d0, $0a, $0b, $00   ; dy -48 dx +10 tile 11 attr $00
    db $d8, $0e, $0c, $00   ; dy -40 dx +14 tile 12 attr $00
    db $e0, $12, $0b, $00   ; dy -32 dx +18 tile 11 attr $00
    db $e8, $12, $0c, $00   ; dy -24 dx +18 tile 12 attr $00
    db $f0, $0e, $0b, $00   ; dy -16 dx +14 tile 11 attr $00
    db $f8, $0a, $0c, $00   ; dy -8 dx +10 tile 12 attr $00
    db $d0, $fc, $0d, $00   ; dy -48 dx -4 tile 13 attr $00
    db $d8, $fc, $0e, $00   ; dy -40 dx -4 tile 14 attr $00
    db $e0, $fc, $0d, $00   ; dy -32 dx -4 tile 13 attr $00
    db $e8, $fc, $0e, $00   ; dy -24 dx -4 tile 14 attr $00
    db $f0, $fc, $0d, $00   ; dy -16 dx -4 tile 13 attr $00
    db $f8, $fc, $0e, $00   ; dy -8 dx -4 tile 14 attr $00
Anim_0e_F13:   ; $4897 empty frame = the $80 end above (shared)
    db $80
Anim_0f_Bolt:   ; $4898 animation $0f — Bolt, Lightning, BOLTSTAFF
    dw Anim_0f_F00
    dw Anim_0f_F01
    dw Anim_0f_F02
    dw Anim_0f_F03
    dw Anim_0f_F04
    dw Anim_0f_F05
    dw Anim_0f_F06
    dw Anim_0f_F07
    dw Anim_0f_F08
    dw Anim_0f_F08
    dw Anim_0f_F08
    dw Anim_0f_F08
    dw Anim_0f_F08
    dw Anim_0f_F08
    dw Anim_0f_F08
    dw Anim_0f_F08
    dw Anim_0f_F08
    dw Anim_0f_F08
    dw Anim_0f_F08
    dw Anim_0f_F08
    dw Anim_0f_F08
    dw Anim_0f_F08
    dw Anim_0f_F08
    dw Anim_0f_F08
    dw Anim_0f_F08
    dw Anim_0f_F08
    dw Anim_0f_F08
    dw Anim_0f_F08
    dw Anim_0f_F08
    dw Anim_0f_F08
    dw Anim_0f_F08
    dw Anim_0f_F08
Anim_0f_F00:   ; $48d8 1 sprites
    db $d0, $fc, $00, $00   ; dy -48 dx -4 tile 0 attr $00
    db $80
Anim_0f_F01:   ; $48dd 2 sprites
    db $d0, $fc, $03, $00   ; dy -48 dx -4 tile 3 attr $00
    db $d8, $fc, $02, $00   ; dy -40 dx -4 tile 2 attr $00
    db $80
Anim_0f_F02:   ; $48e6 3 sprites
    db $d0, $f8, $0c, $00   ; dy -48 dx -8 tile 12 attr $00
    db $d0, $00, $0d, $00   ; dy -48 dx +0 tile 13 attr $00
    db $d7, $01, $05, $00   ; dy -41 dx +1 tile 5 attr $00
    db $80
Anim_0f_F03:   ; $48f3 7 sprites
    db $d0, $00, $16, $20   ; dy -48 dx +0 tile 22 attr $20
    db $d0, $f8, $17, $20   ; dy -48 dx -8 tile 23 attr $20
    db $d8, $00, $1c, $00   ; dy -40 dx +0 tile 28 attr $00
    db $d8, $08, $1d, $00   ; dy -40 dx +8 tile 29 attr $00
    db $e0, $fa, $18, $20   ; dy -32 dx -6 tile 24 attr $20
    db $e0, $f2, $19, $20   ; dy -32 dx -14 tile 25 attr $20
    db $e8, $f6, $05, $00   ; dy -24 dx -10 tile 5 attr $00
    db $80
Anim_0f_F04:   ; $4910 14 sprites
    db $d0, $f8, $06, $00   ; dy -48 dx -8 tile 6 attr $00
    db $d0, $00, $07, $00   ; dy -48 dx +0 tile 7 attr $00
    db $d8, $f6, $08, $00   ; dy -40 dx -10 tile 8 attr $00
    db $d8, $fe, $09, $00   ; dy -40 dx -2 tile 9 attr $00
    db $e0, $f9, $0a, $00   ; dy -32 dx -7 tile 10 attr $00
    db $e0, $01, $0b, $00   ; dy -32 dx +1 tile 11 attr $00
    db $e8, $f4, $0c, $00   ; dy -24 dx -12 tile 12 attr $00
    db $e8, $fc, $0d, $00   ; dy -24 dx -4 tile 13 attr $00
    db $f0, $f4, $0e, $00   ; dy -16 dx -12 tile 14 attr $00
    db $f0, $fc, $0f, $00   ; dy -16 dx -4 tile 15 attr $00
    db $f8, $f9, $10, $00   ; dy -8 dx -7 tile 16 attr $00
    db $f8, $01, $11, $00   ; dy -8 dx +1 tile 17 attr $00
    db $f8, $04, $1e, $00   ; dy -8 dx +4 tile 30 attr $00
    db $f8, $f8, $1e, $20   ; dy -8 dx -8 tile 30 attr $20
    db $80
Anim_0f_F05:   ; $4949 14 sprites
    db $d0, $fa, $12, $00   ; dy -48 dx -6 tile 18 attr $00
    db $d0, $02, $13, $00   ; dy -48 dx +2 tile 19 attr $00
    db $d8, $fd, $14, $00   ; dy -40 dx -3 tile 20 attr $00
    db $d8, $05, $15, $00   ; dy -40 dx +5 tile 21 attr $00
    db $e0, $fd, $16, $00   ; dy -32 dx -3 tile 22 attr $00
    db $e0, $05, $17, $00   ; dy -32 dx +5 tile 23 attr $00
    db $e8, $fd, $18, $00   ; dy -24 dx -3 tile 24 attr $00
    db $e8, $05, $19, $00   ; dy -24 dx +5 tile 25 attr $00
    db $f0, $fd, $1a, $00   ; dy -16 dx -3 tile 26 attr $00
    db $f0, $05, $1b, $00   ; dy -16 dx +5 tile 27 attr $00
    db $f8, $fd, $1c, $00   ; dy -8 dx -3 tile 28 attr $00
    db $f8, $05, $1d, $00   ; dy -8 dx +5 tile 29 attr $00
    db $f8, $06, $1e, $00   ; dy -8 dx +6 tile 30 attr $00
    db $f8, $f5, $1e, $20   ; dy -8 dx -11 tile 30 attr $20
    db $80
Anim_0f_F06:   ; $4982 16 sprites
    db $d8, $0b, $08, $20   ; dy -40 dx +11 tile 8 attr $20
    db $d8, $03, $09, $20   ; dy -40 dx +3 tile 9 attr $20
    db $d0, $01, $18, $00   ; dy -48 dx +1 tile 24 attr $00
    db $d0, $09, $19, $00   ; dy -48 dx +9 tile 25 attr $00
    db $e0, $05, $14, $00   ; dy -32 dx +5 tile 20 attr $00
    db $e0, $0d, $15, $00   ; dy -32 dx +13 tile 21 attr $00
    db $e8, $06, $0c, $00   ; dy -24 dx +6 tile 12 attr $00
    db $e8, $0e, $0d, $00   ; dy -24 dx +14 tile 13 attr $00
    db $f0, $05, $0e, $00   ; dy -16 dx +5 tile 14 attr $00
    db $f0, $0d, $0f, $00   ; dy -16 dx +13 tile 15 attr $00
    db $f8, $04, $16, $00   ; dy -8 dx +4 tile 22 attr $00
    db $f8, $0c, $17, $00   ; dy -8 dx +12 tile 23 attr $00
    db $e8, $03, $0d, $20   ; dy -24 dx +3 tile 13 attr $20
    db $f0, $fe, $0c, $00   ; dy -16 dx -2 tile 12 attr $00
    db $f8, $11, $1e, $00   ; dy -8 dx +17 tile 30 attr $00
    db $f8, $fd, $1e, $20   ; dy -8 dx -3 tile 30 attr $20
    db $80
Anim_0f_F07:   ; $49c3 16 sprites
    db $d0, $02, $0c, $20   ; dy -48 dx +2 tile 12 attr $20
    db $d0, $fa, $0d, $20   ; dy -48 dx -6 tile 13 attr $20
    db $d8, $f1, $16, $00   ; dy -40 dx -15 tile 22 attr $00
    db $d8, $f9, $17, $00   ; dy -40 dx -7 tile 23 attr $00
    db $e0, $f7, $16, $20   ; dy -32 dx -9 tile 22 attr $20
    db $e0, $ef, $17, $20   ; dy -32 dx -17 tile 23 attr $20
    db $e8, $f7, $18, $20   ; dy -24 dx -9 tile 24 attr $20
    db $e8, $ef, $19, $20   ; dy -24 dx -17 tile 25 attr $20
    db $f0, $f7, $1a, $20   ; dy -16 dx -9 tile 26 attr $20
    db $f0, $ef, $1b, $20   ; dy -16 dx -17 tile 27 attr $20
    db $f8, $f4, $14, $00   ; dy -8 dx -12 tile 20 attr $00
    db $f8, $fc, $15, $00   ; dy -8 dx -4 tile 21 attr $00
    db $e5, $fe, $06, $20   ; dy -27 dx -2 tile 6 attr $20
    db $ed, $01, $05, $20   ; dy -19 dx +1 tile 5 attr $20
    db $f8, $01, $1e, $00   ; dy -8 dx +1 tile 30 attr $00
    db $f8, $ed, $1e, $20   ; dy -8 dx -19 tile 30 attr $20
Anim_0f_F08:   ; $4a03 empty frame = the $80 end above (shared)
    db $80
Anim_10_Zap:   ; $4a04 animation $10 — Zap
    dw Anim_10_F00
    dw Anim_10_F01
    dw Anim_10_F02
    dw Anim_10_F03
    dw Anim_10_F04
    dw Anim_10_F05
    dw Anim_10_F06
    dw Anim_10_F07
    dw Anim_10_F08
    dw Anim_10_F09
    dw Anim_10_F10
    dw Anim_10_F10
    dw Anim_10_F10
    dw Anim_10_F10
    dw Anim_10_F10
    dw Anim_10_F10
    dw Anim_10_F10
    dw Anim_10_F10
    dw Anim_10_F10
    dw Anim_10_F10
    dw Anim_10_F10
    dw Anim_10_F10
    dw Anim_10_F10
    dw Anim_10_F10
    dw Anim_10_F10
    dw Anim_10_F10
    dw Anim_10_F10
    dw Anim_10_F10
    dw Anim_10_F10
    dw Anim_10_F10
    dw Anim_10_F10
    dw Anim_10_F10
Anim_10_F00:   ; $4a44 2 sprites
    db $d0, $fc, $00, $00   ; dy -48 dx -4 tile 0 attr $00
    db $d0, $fd, $00, $20   ; dy -48 dx -3 tile 0 attr $20
    db $80
Anim_10_F01:   ; $4a4d 2 sprites
    db $d0, $f8, $01, $00   ; dy -48 dx -8 tile 1 attr $00
    db $d0, $00, $01, $20   ; dy -48 dx +0 tile 1 attr $20
    db $80
Anim_10_F02:   ; $4a56 4 sprites
    db $d0, $fc, $00, $00   ; dy -48 dx -4 tile 0 attr $00
    db $d0, $fd, $00, $20   ; dy -48 dx -3 tile 0 attr $20
    db $d3, $fd, $03, $00   ; dy -45 dx -3 tile 3 attr $00
    db $db, $fd, $02, $00   ; dy -37 dx -3 tile 2 attr $00
    db $80
Anim_10_F03:   ; $4a67 3 sprites
    db $d0, $f8, $0c, $00   ; dy -48 dx -8 tile 12 attr $00
    db $d0, $00, $0d, $00   ; dy -48 dx +0 tile 13 attr $00
    db $d7, $01, $05, $00   ; dy -41 dx +1 tile 5 attr $00
    db $80
Anim_10_F04:   ; $4a74 7 sprites
    db $d0, $00, $16, $20   ; dy -48 dx +0 tile 22 attr $20
    db $d0, $f8, $17, $20   ; dy -48 dx -8 tile 23 attr $20
    db $d8, $00, $18, $20   ; dy -40 dx +0 tile 24 attr $20
    db $d8, $f8, $19, $20   ; dy -40 dx -8 tile 25 attr $20
    db $e0, $fc, $18, $20   ; dy -32 dx -4 tile 24 attr $20
    db $e0, $f4, $19, $20   ; dy -32 dx -12 tile 25 attr $20
    db $e8, $f8, $05, $00   ; dy -24 dx -8 tile 5 attr $00
    db $80
Anim_10_F05:   ; $4a91 38 sprites
    db $d0, $01, $06, $20   ; dy -48 dx +1 tile 6 attr $20
    db $d0, $f9, $07, $20   ; dy -48 dx -7 tile 7 attr $20
    db $d8, $03, $08, $20   ; dy -40 dx +3 tile 8 attr $20
    db $d8, $fb, $09, $20   ; dy -40 dx -5 tile 9 attr $20
    db $e0, $00, $0a, $20   ; dy -32 dx +0 tile 10 attr $20
    db $e0, $f8, $0b, $20   ; dy -32 dx -8 tile 11 attr $20
    db $e8, $05, $0c, $20   ; dy -24 dx +5 tile 12 attr $20
    db $e8, $fd, $0d, $20   ; dy -24 dx -3 tile 13 attr $20
    db $f0, $05, $0e, $20   ; dy -16 dx +5 tile 14 attr $20
    db $f0, $fd, $0f, $20   ; dy -16 dx -3 tile 15 attr $20
    db $f8, $00, $10, $20   ; dy -8 dx +0 tile 16 attr $20
    db $f8, $f8, $11, $20   ; dy -8 dx -8 tile 17 attr $20
    db $f8, $f4, $21, $20   ; dy -8 dx -12 tile 33 attr $20
    db $f8, $02, $21, $00   ; dy -8 dx +2 tile 33 attr $00
    db $d0, $10, $22, $00   ; dy -48 dx +16 tile 34 attr $00
    db $d0, $08, $22, $00   ; dy -48 dx +8 tile 34 attr $00
    db $d8, $0b, $22, $00   ; dy -40 dx +11 tile 34 attr $00
    db $d8, $10, $22, $00   ; dy -40 dx +16 tile 34 attr $00
    db $e0, $10, $22, $00   ; dy -32 dx +16 tile 34 attr $00
    db $e0, $08, $22, $00   ; dy -32 dx +8 tile 34 attr $00
    db $e8, $10, $22, $00   ; dy -24 dx +16 tile 34 attr $00
    db $f0, $10, $22, $00   ; dy -16 dx +16 tile 34 attr $00
    db $f8, $10, $22, $00   ; dy -8 dx +16 tile 34 attr $00
    db $f8, $0a, $22, $00   ; dy -8 dx +10 tile 34 attr $00
    db $d0, $f0, $22, $20   ; dy -48 dx -16 tile 34 attr $20
    db $d8, $f0, $22, $20   ; dy -40 dx -16 tile 34 attr $20
    db $e0, $f0, $22, $20   ; dy -32 dx -16 tile 34 attr $20
    db $e8, $f0, $22, $20   ; dy -24 dx -16 tile 34 attr $20
    db $f0, $f0, $22, $20   ; dy -16 dx -16 tile 34 attr $20
    db $f8, $f0, $22, $20   ; dy -8 dx -16 tile 34 attr $20
    db $d0, $e8, $22, $20   ; dy -48 dx -24 tile 34 attr $20
    db $d8, $e8, $22, $20   ; dy -40 dx -24 tile 34 attr $20
    db $e0, $e8, $22, $20   ; dy -32 dx -24 tile 34 attr $20
    db $e8, $e8, $22, $20   ; dy -24 dx -24 tile 34 attr $20
    db $f0, $e8, $22, $20   ; dy -16 dx -24 tile 34 attr $20
    db $f8, $e8, $22, $20   ; dy -8 dx -24 tile 34 attr $20
    db $e8, $f5, $22, $20   ; dy -24 dx -11 tile 34 attr $20
    db $f0, $f5, $22, $20   ; dy -16 dx -11 tile 34 attr $20
    db $80
Anim_10_F06:   ; $4b2a 16 sprites
    db $d0, $02, $0c, $20   ; dy -48 dx +2 tile 12 attr $20
    db $d0, $fa, $0d, $20   ; dy -48 dx -6 tile 13 attr $20
    db $d8, $f1, $16, $00   ; dy -40 dx -15 tile 22 attr $00
    db $d8, $f9, $17, $00   ; dy -40 dx -7 tile 23 attr $00
    db $e0, $f7, $16, $20   ; dy -32 dx -9 tile 22 attr $20
    db $e0, $ef, $17, $20   ; dy -32 dx -17 tile 23 attr $20
    db $e8, $f7, $18, $20   ; dy -24 dx -9 tile 24 attr $20
    db $e8, $ef, $19, $20   ; dy -24 dx -17 tile 25 attr $20
    db $f0, $f7, $1a, $20   ; dy -16 dx -9 tile 26 attr $20
    db $f0, $ef, $1b, $20   ; dy -16 dx -17 tile 27 attr $20
    db $e5, $fe, $06, $20   ; dy -27 dx -2 tile 6 attr $20
    db $ed, $01, $05, $20   ; dy -19 dx +1 tile 5 attr $20
    db $f8, $fc, $1e, $00   ; dy -8 dx -4 tile 30 attr $00
    db $f8, $04, $1f, $00   ; dy -8 dx +4 tile 31 attr $00
    db $f8, $f4, $1e, $20   ; dy -8 dx -12 tile 30 attr $20
    db $f8, $ec, $1f, $20   ; dy -8 dx -20 tile 31 attr $20
    db $80
Anim_10_F07:   ; $4b6b 33 sprites
    db $d8, $0b, $08, $20   ; dy -40 dx +11 tile 8 attr $20
    db $d8, $03, $09, $20   ; dy -40 dx +3 tile 9 attr $20
    db $d0, $01, $18, $00   ; dy -48 dx +1 tile 24 attr $00
    db $d0, $09, $19, $00   ; dy -48 dx +9 tile 25 attr $00
    db $e0, $05, $14, $00   ; dy -32 dx +5 tile 20 attr $00
    db $e0, $0d, $15, $00   ; dy -32 dx +13 tile 21 attr $00
    db $e8, $06, $0c, $00   ; dy -24 dx +6 tile 12 attr $00
    db $e8, $0e, $0d, $00   ; dy -24 dx +14 tile 13 attr $00
    db $f0, $05, $0e, $00   ; dy -16 dx +5 tile 14 attr $00
    db $f0, $0d, $0f, $00   ; dy -16 dx +13 tile 15 attr $00
    db $e8, $03, $0d, $20   ; dy -24 dx +3 tile 13 attr $20
    db $f0, $fe, $0c, $00   ; dy -16 dx -2 tile 12 attr $00
    db $f8, $0c, $20, $00   ; dy -8 dx +12 tile 32 attr $00
    db $f8, $04, $20, $20   ; dy -8 dx +4 tile 32 attr $20
    db $f8, $fc, $21, $20   ; dy -8 dx -4 tile 33 attr $20
    db $d0, $e8, $22, $00   ; dy -48 dx -24 tile 34 attr $00
    db $d8, $e8, $22, $00   ; dy -40 dx -24 tile 34 attr $00
    db $e0, $e8, $22, $00   ; dy -32 dx -24 tile 34 attr $00
    db $e8, $e8, $22, $00   ; dy -24 dx -24 tile 34 attr $00
    db $f0, $e9, $22, $00   ; dy -16 dx -23 tile 34 attr $00
    db $f8, $e9, $22, $00   ; dy -8 dx -23 tile 34 attr $00
    db $d0, $f0, $22, $00   ; dy -48 dx -16 tile 34 attr $00
    db $d8, $f1, $22, $00   ; dy -40 dx -15 tile 34 attr $00
    db $e0, $f2, $22, $00   ; dy -32 dx -14 tile 34 attr $00
    db $e8, $f1, $22, $00   ; dy -24 dx -15 tile 34 attr $00
    db $f0, $f3, $22, $00   ; dy -16 dx -13 tile 34 attr $00
    db $f8, $f3, $22, $00   ; dy -8 dx -13 tile 34 attr $00
    db $d0, $f8, $22, $00   ; dy -48 dx -8 tile 34 attr $00
    db $d8, $fa, $22, $00   ; dy -40 dx -6 tile 34 attr $00
    db $e8, $fa, $22, $00   ; dy -24 dx -6 tile 34 attr $00
    db $e0, $fc, $22, $00   ; dy -32 dx -4 tile 34 attr $00
    db $d0, $10, $22, $20   ; dy -48 dx +16 tile 34 attr $20
    db $f8, $14, $1f, $00   ; dy -8 dx +20 tile 31 attr $00
    db $80
Anim_10_F08:   ; $4bf0 26 sprites
    db $f8, $00, $1f, $00   ; dy -8 dx +0 tile 31 attr $00
    db $d0, $03, $14, $20   ; dy -48 dx +3 tile 20 attr $20
    db $d0, $fb, $15, $20   ; dy -48 dx -5 tile 21 attr $20
    db $d8, $09, $0a, $20   ; dy -40 dx +9 tile 10 attr $20
    db $d8, $01, $0b, $20   ; dy -40 dx +1 tile 11 attr $20
    db $f8, $0f, $1e, $00   ; dy -8 dx +15 tile 30 attr $00
    db $f8, $17, $1f, $00   ; dy -8 dx +23 tile 31 attr $00
    db $f8, $07, $1e, $20   ; dy -8 dx +7 tile 30 attr $20
    db $e0, $08, $16, $40   ; dy -32 dx +8 tile 22 attr $40
    db $e0, $10, $17, $40   ; dy -32 dx +16 tile 23 attr $40
    db $e8, $11, $0c, $20   ; dy -24 dx +17 tile 12 attr $20
    db $e8, $09, $0d, $20   ; dy -24 dx +9 tile 13 attr $20
    db $f0, $10, $0e, $20   ; dy -16 dx +16 tile 14 attr $20
    db $f0, $08, $0f, $20   ; dy -16 dx +8 tile 15 attr $20
    db $e8, $fa, $14, $60   ; dy -24 dx -6 tile 20 attr $60
    db $e8, $f2, $15, $60   ; dy -24 dx -14 tile 21 attr $60
    db $f0, $fa, $10, $20   ; dy -16 dx -6 tile 16 attr $20
    db $f0, $f2, $11, $20   ; dy -16 dx -14 tile 17 attr $20
    db $f8, $f0, $20, $20   ; dy -8 dx -16 tile 32 attr $20
    db $f8, $f8, $20, $00   ; dy -8 dx -8 tile 32 attr $00
    db $f8, $00, $21, $00   ; dy -8 dx +0 tile 33 attr $00
    db $d8, $fa, $09, $00   ; dy -40 dx -6 tile 9 attr $00
    db $e0, $fb, $0a, $60   ; dy -32 dx -5 tile 10 attr $60
    db $e0, $f3, $0b, $60   ; dy -32 dx -13 tile 11 attr $60
    db $db, $f2, $1d, $60   ; dy -37 dx -14 tile 29 attr $60
    db $f8, $e8, $21, $20   ; dy -8 dx -24 tile 33 attr $20
    db $80
Anim_10_F09:   ; $4c59 37 sprites
    db $d0, $fe, $10, $20   ; dy -48 dx -2 tile 16 attr $20
    db $d0, $f6, $11, $20   ; dy -48 dx -10 tile 17 attr $20
    db $d8, $f4, $12, $40   ; dy -40 dx -12 tile 18 attr $40
    db $d8, $fc, $13, $40   ; dy -40 dx -4 tile 19 attr $40
    db $e0, $ed, $1d, $60   ; dy -32 dx -19 tile 29 attr $60
    db $e8, $f6, $10, $20   ; dy -24 dx -10 tile 16 attr $20
    db $e8, $ee, $11, $20   ; dy -24 dx -18 tile 17 attr $20
    db $f0, $f0, $18, $20   ; dy -16 dx -16 tile 24 attr $20
    db $d8, $06, $14, $00   ; dy -40 dx +6 tile 20 attr $00
    db $d8, $0e, $15, $00   ; dy -40 dx +14 tile 21 attr $00
    db $e0, $0f, $10, $20   ; dy -32 dx +15 tile 16 attr $20
    db $e0, $07, $11, $20   ; dy -32 dx +7 tile 17 attr $20
    db $e8, $04, $06, $00   ; dy -24 dx +4 tile 6 attr $00
    db $e8, $0c, $07, $00   ; dy -24 dx +12 tile 7 attr $00
    db $f0, $01, $14, $00   ; dy -16 dx +1 tile 20 attr $00
    db $f0, $09, $15, $00   ; dy -16 dx +9 tile 21 attr $00
    db $f8, $10, $1f, $00   ; dy -8 dx +16 tile 31 attr $00
    db $f8, $01, $1e, $20   ; dy -8 dx +1 tile 30 attr $20
    db $f8, $09, $1e, $00   ; dy -8 dx +9 tile 30 attr $00
    db $f0, $0c, $04, $00   ; dy -16 dx +12 tile 4 attr $00
    db $f8, $10, $05, $20   ; dy -8 dx +16 tile 5 attr $20
    db $e0, $fa, $05, $20   ; dy -32 dx -6 tile 5 attr $20
    db $e0, $f5, $1c, $60   ; dy -32 dx -11 tile 28 attr $60
    db $d0, $02, $12, $00   ; dy -48 dx +2 tile 18 attr $00
    db $d0, $0a, $13, $00   ; dy -48 dx +10 tile 19 attr $00
    db $f8, $f9, $1f, $20   ; dy -8 dx -7 tile 31 attr $20
    db $f8, $f4, $20, $00   ; dy -8 dx -12 tile 32 attr $00
    db $f8, $fc, $21, $00   ; dy -8 dx -4 tile 33 attr $00
    db $f8, $ec, $20, $20   ; dy -8 dx -20 tile 32 attr $20
    db $f0, $f8, $22, $00   ; dy -16 dx -8 tile 34 attr $00
    db $f8, $e4, $1f, $20   ; dy -8 dx -28 tile 31 attr $20
    db $d0, $e8, $22, $20   ; dy -48 dx -24 tile 34 attr $20
    db $d8, $e8, $22, $20   ; dy -40 dx -24 tile 34 attr $20
    db $e0, $e8, $22, $20   ; dy -32 dx -24 tile 34 attr $20
    db $d0, $10, $22, $00   ; dy -48 dx +16 tile 34 attr $00
    db $e8, $fd, $22, $00   ; dy -24 dx -3 tile 34 attr $00
    db $f0, $e8, $0e, $00   ; dy -16 dx -24 tile 14 attr $00
Anim_10_F10:   ; $4ced empty frame = the $80 end above (shared)
    db $80
Anim_11_Thordain:   ; $4cee animation $11 — Thordain
    dw Anim_11_F00
    dw Anim_11_F01
    dw Anim_11_F02
    dw Anim_11_F03
    dw Anim_11_F04
    dw Anim_11_F05
    dw Anim_11_F06
    dw Anim_11_F07
    dw Anim_11_F08
    dw Anim_11_F09
    dw Anim_11_F10
    dw Anim_11_F11
    dw Anim_11_F12
    dw Anim_11_F13
    dw Anim_11_F14
    dw Anim_11_F15
    dw Anim_11_F16
    dw Anim_11_F16
    dw Anim_11_F16
    dw Anim_11_F16
    dw Anim_11_F16
    dw Anim_11_F16
    dw Anim_11_F16
    dw Anim_11_F16
    dw Anim_11_F16
    dw Anim_11_F16
    dw Anim_11_F16
    dw Anim_11_F16
    dw Anim_11_F16
    dw Anim_11_F16
    dw Anim_11_F16
    dw Anim_11_F16
Anim_11_F00:   ; $4d2e 6 sprites
    db $f8, $f8, $01, $40   ; dy -8 dx -8 tile 1 attr $40
    db $f8, $00, $01, $60   ; dy -8 dx +0 tile 1 attr $60
    db $d0, $f8, $01, $00   ; dy -48 dx -8 tile 1 attr $00
    db $d0, $00, $01, $20   ; dy -48 dx +0 tile 1 attr $20
    db $f0, $fe, $05, $60   ; dy -16 dx -2 tile 5 attr $60
    db $d8, $fa, $05, $00   ; dy -40 dx -6 tile 5 attr $00
    db $80
Anim_11_F01:   ; $4d47 8 sprites
    db $d0, $fc, $00, $00   ; dy -48 dx -4 tile 0 attr $00
    db $d4, $fc, $2b, $00   ; dy -44 dx -4 tile 43 attr $00
    db $f8, $fc, $00, $40   ; dy -8 dx -4 tile 0 attr $40
    db $f4, $fc, $2b, $40   ; dy -12 dx -4 tile 43 attr $40
    db $e7, $fc, $00, $00   ; dy -25 dx -4 tile 0 attr $00
    db $e2, $fc, $00, $40   ; dy -30 dx -4 tile 0 attr $40
    db $dc, $fc, $2f, $00   ; dy -36 dx -4 tile 47 attr $00
    db $ed, $fc, $2f, $00   ; dy -19 dx -4 tile 47 attr $00
    db $80
Anim_11_F02:   ; $4d68 11 sprites
    db $db, $0d, $1d, $00   ; dy -37 dx +13 tile 29 attr $00
    db $ea, $07, $14, $20   ; dy -22 dx +7 tile 20 attr $20
    db $f2, $06, $05, $00   ; dy -14 dx +6 tile 5 attr $00
    db $db, $f4, $23, $40   ; dy -37 dx -12 tile 35 attr $40
    db $e8, $f8, $01, $00   ; dy -24 dx -8 tile 1 attr $00
    db $e0, $f8, $01, $40   ; dy -32 dx -8 tile 1 attr $40
    db $e0, $00, $01, $60   ; dy -32 dx +0 tile 1 attr $60
    db $e8, $00, $01, $20   ; dy -24 dx +0 tile 1 attr $20
    db $ed, $f5, $24, $40   ; dy -19 dx -11 tile 36 attr $40
    db $db, $05, $1c, $00   ; dy -37 dx +5 tile 28 attr $00
    db $ee, $ed, $1d, $60   ; dy -18 dx -19 tile 29 attr $60
    db $80
Anim_11_F03:   ; $4d95 12 sprites
    db $e8, $08, $06, $20   ; dy -24 dx +8 tile 6 attr $20
    db $e8, $00, $02, $60   ; dy -24 dx +0 tile 2 attr $60
    db $e0, $00, $03, $00   ; dy -32 dx +0 tile 3 attr $00
    db $e8, $f8, $2c, $00   ; dy -24 dx -8 tile 44 attr $00
    db $e8, $f0, $27, $00   ; dy -24 dx -16 tile 39 attr $00
    db $dc, $08, $27, $60   ; dy -36 dx +8 tile 39 attr $60
    db $f8, $fc, $2e, $00   ; dy -8 dx -4 tile 46 attr $00
    db $f0, $fd, $2d, $00   ; dy -16 dx -3 tile 45 attr $00
    db $e0, $f8, $2c, $40   ; dy -32 dx -8 tile 44 attr $40
    db $e0, $f0, $0b, $20   ; dy -32 dx -16 tile 11 attr $20
    db $d0, $fc, $2e, $60   ; dy -48 dx -4 tile 46 attr $60
    db $d8, $fb, $2d, $60   ; dy -40 dx -5 tile 45 attr $60
    db $80
Anim_11_F04:   ; $4dc6 6 sprites
    db $e0, $fb, $17, $60   ; dy -32 dx -5 tile 23 attr $60
    db $e0, $03, $14, $60   ; dy -32 dx +3 tile 20 attr $60
    db $d8, $03, $10, $60   ; dy -40 dx +3 tile 16 attr $60
    db $e8, $fd, $17, $00   ; dy -24 dx -3 tile 23 attr $00
    db $e8, $f5, $14, $00   ; dy -24 dx -11 tile 20 attr $00
    db $f0, $f5, $10, $00   ; dy -16 dx -11 tile 16 attr $00
    db $80
Anim_11_F05:   ; $4ddf 14 sprites
    db $e4, $f8, $1e, $00   ; dy -28 dx -8 tile 30 attr $00
    db $ec, $f8, $1f, $00   ; dy -20 dx -8 tile 31 attr $00
    db $e4, $f0, $1c, $00   ; dy -28 dx -16 tile 28 attr $00
    db $ec, $f0, $1d, $00   ; dy -20 dx -16 tile 29 attr $00
    db $e4, $e8, $1f, $40   ; dy -28 dx -24 tile 31 attr $40
    db $ec, $e6, $24, $20   ; dy -20 dx -26 tile 36 attr $20
    db $f1, $e2, $0d, $20   ; dy -15 dx -30 tile 13 attr $20
    db $e4, $00, $1e, $60   ; dy -28 dx +0 tile 30 attr $60
    db $dc, $00, $1f, $60   ; dy -36 dx +0 tile 31 attr $60
    db $e4, $08, $1c, $60   ; dy -28 dx +8 tile 28 attr $60
    db $dc, $08, $1d, $60   ; dy -36 dx +8 tile 29 attr $60
    db $e4, $10, $1f, $20   ; dy -28 dx +16 tile 31 attr $20
    db $dc, $12, $24, $40   ; dy -36 dx +18 tile 36 attr $40
    db $d7, $16, $0d, $40   ; dy -41 dx +22 tile 13 attr $40
    db $80
Anim_11_F06:   ; $4e18 30 sprites
    db $e2, $f8, $18, $60   ; dy -30 dx -8 tile 24 attr $60
    db $da, $f8, $19, $60   ; dy -38 dx -8 tile 25 attr $60
    db $e1, $f0, $1a, $60   ; dy -31 dx -16 tile 26 attr $60
    db $d9, $f0, $1b, $60   ; dy -39 dx -16 tile 27 attr $60
    db $e6, $00, $18, $00   ; dy -26 dx +0 tile 24 attr $00
    db $ee, $00, $19, $00   ; dy -18 dx +0 tile 25 attr $00
    db $e7, $08, $1a, $00   ; dy -25 dx +8 tile 26 attr $00
    db $ef, $08, $1b, $00   ; dy -17 dx +8 tile 27 attr $00
    db $e8, $10, $1c, $00   ; dy -24 dx +16 tile 28 attr $00
    db $f0, $10, $1d, $00   ; dy -16 dx +16 tile 29 attr $00
    db $e9, $18, $1e, $00   ; dy -23 dx +24 tile 30 attr $00
    db $f1, $18, $16, $40   ; dy -15 dx +24 tile 22 attr $40
    db $e9, $20, $20, $00   ; dy -23 dx +32 tile 32 attr $00
    db $e8, $28, $09, $00   ; dy -24 dx +40 tile 9 attr $00
    db $f1, $20, $21, $00   ; dy -15 dx +32 tile 33 attr $00
    db $f8, $28, $1c, $00   ; dy -8 dx +40 tile 28 attr $00
    db $f8, $30, $15, $00   ; dy -8 dx +48 tile 21 attr $00
    db $f0, $2a, $08, $00   ; dy -16 dx +42 tile 8 attr $00
    db $df, $e0, $1e, $60   ; dy -33 dx -32 tile 30 attr $60
    db $d7, $e0, $1e, $00   ; dy -41 dx -32 tile 30 attr $00
    db $df, $d8, $20, $60   ; dy -33 dx -40 tile 32 attr $60
    db $e0, $d0, $09, $60   ; dy -32 dx -48 tile 9 attr $60
    db $e0, $e8, $1c, $60   ; dy -32 dx -24 tile 28 attr $60
    db $d8, $e8, $1d, $60   ; dy -40 dx -24 tile 29 attr $60
    db $d8, $ce, $08, $60   ; dy -40 dx -50 tile 8 attr $60
    db $d7, $d8, $21, $60   ; dy -41 dx -40 tile 33 attr $60
    db $d0, $d0, $1c, $60   ; dy -48 dx -48 tile 28 attr $60
    db $d0, $c8, $15, $60   ; dy -48 dx -56 tile 21 attr $60
    db $f8, $20, $1e, $60   ; dy -8 dx +32 tile 30 attr $60
    db $d0, $d8, $1e, $00   ; dy -48 dx -40 tile 30 attr $00
    db $80
Anim_11_F07:   ; $4e91 22 sprites
    db $d8, $02, $08, $20   ; dy -40 dx +2 tile 8 attr $20
    db $d8, $fa, $09, $20   ; dy -40 dx -6 tile 9 attr $20
    db $e0, $fc, $14, $00   ; dy -32 dx -4 tile 20 attr $00
    db $e0, $04, $15, $00   ; dy -32 dx +4 tile 21 attr $00
    db $e8, $fd, $0c, $00   ; dy -24 dx -3 tile 12 attr $00
    db $e8, $05, $0d, $00   ; dy -24 dx +5 tile 13 attr $00
    db $e8, $fa, $0d, $20   ; dy -24 dx -6 tile 13 attr $20
    db $f0, $12, $0e, $20   ; dy -16 dx +18 tile 14 attr $20
    db $f0, $0a, $0f, $20   ; dy -16 dx +10 tile 15 attr $20
    db $f8, $0a, $09, $00   ; dy -8 dx +10 tile 9 attr $00
    db $f8, $1a, $0b, $40   ; dy -8 dx +26 tile 11 attr $40
    db $f8, $12, $0f, $20   ; dy -8 dx +18 tile 15 attr $20
    db $f8, $02, $20, $00   ; dy -8 dx +2 tile 32 attr $00
    db $f0, $f4, $11, $60   ; dy -16 dx -12 tile 17 attr $60
    db $d0, $02, $0b, $40   ; dy -48 dx +2 tile 11 attr $40
    db $d8, $f3, $16, $40   ; dy -40 dx -13 tile 22 attr $40
    db $d0, $e7, $1c, $60   ; dy -48 dx -25 tile 28 attr $60
    db $d0, $f7, $08, $20   ; dy -48 dx -9 tile 8 attr $20
    db $d0, $ef, $09, $20   ; dy -48 dx -17 tile 9 attr $20
    db $d0, $df, $2a, $20   ; dy -48 dx -33 tile 42 attr $20
    db $d8, $df, $05, $00   ; dy -40 dx -33 tile 5 attr $00
    db $f0, $1a, $0c, $60   ; dy -16 dx +26 tile 12 attr $60
    db $80
Anim_11_F08:   ; $4eea 22 sprites
    db $f0, $03, $08, $60   ; dy -16 dx +3 tile 8 attr $60
    db $f0, $fb, $09, $60   ; dy -16 dx -5 tile 9 attr $60
    db $e8, $fd, $14, $40   ; dy -24 dx -3 tile 20 attr $40
    db $e8, $05, $15, $40   ; dy -24 dx +5 tile 21 attr $40
    db $e0, $fe, $0c, $40   ; dy -32 dx -2 tile 12 attr $40
    db $e0, $06, $0d, $40   ; dy -32 dx +6 tile 13 attr $40
    db $e0, $fb, $0d, $60   ; dy -32 dx -5 tile 13 attr $60
    db $d8, $13, $0e, $60   ; dy -40 dx +19 tile 14 attr $60
    db $d8, $0b, $0f, $60   ; dy -40 dx +11 tile 15 attr $60
    db $d8, $1a, $0c, $60   ; dy -40 dx +26 tile 12 attr $60
    db $d0, $0b, $09, $40   ; dy -48 dx +11 tile 9 attr $40
    db $d0, $1b, $0b, $00   ; dy -48 dx +27 tile 11 attr $00
    db $d0, $13, $0f, $60   ; dy -48 dx +19 tile 15 attr $60
    db $d0, $03, $20, $40   ; dy -48 dx +3 tile 32 attr $40
    db $d8, $f5, $11, $20   ; dy -40 dx -11 tile 17 attr $20
    db $f8, $03, $0b, $00   ; dy -8 dx +3 tile 11 attr $00
    db $f0, $f4, $16, $00   ; dy -16 dx -12 tile 22 attr $00
    db $f8, $e8, $1c, $20   ; dy -8 dx -24 tile 28 attr $20
    db $f8, $f8, $08, $60   ; dy -8 dx -8 tile 8 attr $60
    db $f8, $f0, $09, $60   ; dy -8 dx -16 tile 9 attr $60
    db $f8, $e0, $2a, $60   ; dy -8 dx -32 tile 42 attr $60
    db $f0, $e0, $05, $40   ; dy -16 dx -32 tile 5 attr $40
    db $80
Anim_11_F09:   ; $4f43 40 sprites
    db $d0, $30, $18, $20   ; dy -48 dx +48 tile 24 attr $20
    db $d8, $30, $19, $20   ; dy -40 dx +48 tile 25 attr $20
    db $d0, $28, $1a, $20   ; dy -48 dx +40 tile 26 attr $20
    db $d8, $28, $1b, $20   ; dy -40 dx +40 tile 27 attr $20
    db $d0, $20, $1c, $20   ; dy -48 dx +32 tile 28 attr $20
    db $d8, $20, $1d, $20   ; dy -40 dx +32 tile 29 attr $20
    db $d0, $18, $1e, $20   ; dy -48 dx +24 tile 30 attr $20
    db $d8, $18, $1e, $40   ; dy -40 dx +24 tile 30 attr $40
    db $d8, $10, $20, $60   ; dy -40 dx +16 tile 32 attr $60
    db $d9, $08, $09, $60   ; dy -39 dx +8 tile 9 attr $60
    db $d1, $06, $08, $60   ; dy -47 dx +6 tile 8 attr $60
    db $d0, $10, $21, $60   ; dy -48 dx +16 tile 33 attr $60
    db $e1, $07, $15, $40   ; dy -31 dx +7 tile 21 attr $40
    db $e4, $ff, $11, $60   ; dy -28 dx -1 tile 17 attr $60
    db $e4, $f9, $11, $00   ; dy -28 dx -7 tile 17 attr $00
    db $e7, $f1, $15, $20   ; dy -25 dx -15 tile 21 attr $20
    db $f7, $f2, $08, $00   ; dy -9 dx -14 tile 8 attr $00
    db $ef, $f0, $09, $00   ; dy -17 dx -16 tile 9 attr $00
    db $f8, $c8, $18, $40   ; dy -8 dx -56 tile 24 attr $40
    db $f0, $c8, $19, $40   ; dy -16 dx -56 tile 25 attr $40
    db $f8, $d0, $1a, $40   ; dy -8 dx -48 tile 26 attr $40
    db $f0, $d0, $1b, $40   ; dy -16 dx -48 tile 27 attr $40
    db $f8, $d8, $1c, $40   ; dy -8 dx -40 tile 28 attr $40
    db $f0, $d8, $1d, $40   ; dy -16 dx -40 tile 29 attr $40
    db $f8, $e0, $1e, $40   ; dy -8 dx -32 tile 30 attr $40
    db $f0, $e0, $1e, $20   ; dy -16 dx -32 tile 30 attr $20
    db $f0, $e8, $20, $00   ; dy -16 dx -24 tile 32 attr $00
    db $f8, $e8, $21, $00   ; dy -8 dx -24 tile 33 attr $00
    db $df, $13, $08, $00   ; dy -33 dx +19 tile 8 attr $00
    db $e0, $1b, $24, $60   ; dy -32 dx +27 tile 36 attr $60
    db $e8, $1b, $05, $00   ; dy -24 dx +27 tile 5 attr $00
    db $e9, $e5, $08, $60   ; dy -23 dx -27 tile 8 attr $60
    db $e8, $dd, $24, $00   ; dy -24 dx -35 tile 36 attr $00
    db $e0, $dd, $05, $60   ; dy -32 dx -35 tile 5 attr $60
    db $e9, $07, $08, $60   ; dy -23 dx +7 tile 8 attr $60
    db $f8, $0b, $26, $20   ; dy -8 dx +11 tile 38 attr $20
    db $f1, $09, $0d, $60   ; dy -15 dx +9 tile 13 attr $60
    db $df, $f1, $08, $00   ; dy -33 dx -15 tile 8 attr $00
    db $d0, $ed, $26, $40   ; dy -48 dx -19 tile 38 attr $40
    db $d7, $ef, $0d, $00   ; dy -41 dx -17 tile 13 attr $00
    db $80
Anim_11_F10:   ; $4fe4 31 sprites
    db $e2, $00, $18, $40   ; dy -30 dx +0 tile 24 attr $40
    db $da, $00, $19, $40   ; dy -38 dx +0 tile 25 attr $40
    db $e2, $08, $1a, $40   ; dy -30 dx +8 tile 26 attr $40
    db $da, $08, $1b, $40   ; dy -38 dx +8 tile 27 attr $40
    db $e2, $10, $1c, $40   ; dy -30 dx +16 tile 28 attr $40
    db $da, $10, $1d, $40   ; dy -38 dx +16 tile 29 attr $40
    db $e2, $18, $1e, $40   ; dy -30 dx +24 tile 30 attr $40
    db $da, $18, $1f, $40   ; dy -38 dx +24 tile 31 attr $40
    db $da, $20, $20, $00   ; dy -38 dx +32 tile 32 attr $00
    db $e2, $20, $21, $00   ; dy -30 dx +32 tile 33 attr $00
    db $e8, $40, $09, $40   ; dy -24 dx +64 tile 9 attr $40
    db $df, $30, $1e, $00   ; dy -33 dx +48 tile 30 attr $00
    db $e7, $30, $1e, $60   ; dy -25 dx +48 tile 30 attr $60
    db $e7, $38, $20, $40   ; dy -25 dx +56 tile 32 attr $40
    db $df, $38, $21, $40   ; dy -33 dx +56 tile 33 attr $40
    db $de, $28, $18, $00   ; dy -34 dx +40 tile 24 attr $00
    db $e6, $28, $19, $00   ; dy -26 dx +40 tile 25 attr $00
    db $e0, $40, $08, $60   ; dy -32 dx +64 tile 8 attr $60
    db $f0, $40, $15, $60   ; dy -16 dx +64 tile 21 attr $60
    db $f0, $48, $1c, $20   ; dy -16 dx +72 tile 28 attr $20
    db $f8, $48, $09, $00   ; dy -8 dx +72 tile 9 attr $00
    db $f8, $40, $2a, $40   ; dy -8 dx +64 tile 42 attr $40
    db $d8, $28, $09, $00   ; dy -40 dx +40 tile 9 attr $00
    db $d0, $2c, $0f, $60   ; dy -48 dx +44 tile 15 attr $60
    db $d0, $34, $08, $20   ; dy -48 dx +52 tile 8 attr $20
    db $ea, $1e, $0c, $60   ; dy -22 dx +30 tile 12 attr $60
    db $ea, $16, $0d, $60   ; dy -22 dx +22 tile 13 attr $60
    db $f2, $1e, $0e, $60   ; dy -14 dx +30 tile 14 attr $60
    db $f2, $16, $0f, $60   ; dy -14 dx +22 tile 15 attr $60
    db $f8, $1a, $10, $60   ; dy -8 dx +26 tile 16 attr $60
    db $f8, $12, $11, $60   ; dy -8 dx +18 tile 17 attr $60
    db $80
Anim_11_F11:   ; $5061 31 sprites
    db $e6, $f8, $18, $20   ; dy -26 dx -8 tile 24 attr $20
    db $ee, $f8, $19, $20   ; dy -18 dx -8 tile 25 attr $20
    db $e6, $f0, $1a, $20   ; dy -26 dx -16 tile 26 attr $20
    db $ee, $f0, $1b, $20   ; dy -18 dx -16 tile 27 attr $20
    db $e6, $e8, $1c, $20   ; dy -26 dx -24 tile 28 attr $20
    db $ee, $e8, $1d, $20   ; dy -18 dx -24 tile 29 attr $20
    db $e6, $e0, $1e, $20   ; dy -26 dx -32 tile 30 attr $20
    db $ee, $e0, $1f, $20   ; dy -18 dx -32 tile 31 attr $20
    db $ee, $d8, $20, $60   ; dy -18 dx -40 tile 32 attr $60
    db $e6, $d8, $21, $60   ; dy -26 dx -40 tile 33 attr $60
    db $e0, $b8, $09, $20   ; dy -32 dx -72 tile 9 attr $20
    db $e9, $c8, $1e, $60   ; dy -23 dx -56 tile 30 attr $60
    db $e1, $c8, $1e, $00   ; dy -31 dx -56 tile 30 attr $00
    db $e1, $c0, $20, $20   ; dy -31 dx -64 tile 32 attr $20
    db $e9, $c0, $21, $20   ; dy -23 dx -64 tile 33 attr $20
    db $ea, $d0, $18, $60   ; dy -22 dx -48 tile 24 attr $60
    db $e2, $d0, $19, $60   ; dy -30 dx -48 tile 25 attr $60
    db $e8, $b8, $08, $00   ; dy -24 dx -72 tile 8 attr $00
    db $d8, $b8, $15, $00   ; dy -40 dx -72 tile 21 attr $00
    db $d8, $b0, $1c, $40   ; dy -40 dx -80 tile 28 attr $40
    db $d0, $b0, $09, $60   ; dy -48 dx -80 tile 9 attr $60
    db $d0, $b8, $2a, $20   ; dy -48 dx -72 tile 42 attr $20
    db $f0, $d0, $09, $60   ; dy -16 dx -48 tile 9 attr $60
    db $f8, $cc, $0f, $00   ; dy -8 dx -52 tile 15 attr $00
    db $f8, $c4, $08, $40   ; dy -8 dx -60 tile 8 attr $40
    db $de, $da, $0c, $00   ; dy -34 dx -38 tile 12 attr $00
    db $de, $e2, $0d, $00   ; dy -34 dx -30 tile 13 attr $00
    db $d6, $da, $0e, $00   ; dy -42 dx -38 tile 14 attr $00
    db $d6, $e2, $0f, $00   ; dy -42 dx -30 tile 15 attr $00
    db $d0, $de, $10, $00   ; dy -48 dx -34 tile 16 attr $00
    db $d0, $e6, $11, $00   ; dy -48 dx -26 tile 17 attr $00
    db $80
Anim_11_F12:   ; $50de 32 sprites
    db $e4, $00, $09, $20   ; dy -28 dx +0 tile 9 attr $20
    db $ed, $10, $1e, $60   ; dy -19 dx +16 tile 30 attr $60
    db $e5, $10, $1e, $00   ; dy -27 dx +16 tile 30 attr $00
    db $e5, $08, $20, $20   ; dy -27 dx +8 tile 32 attr $20
    db $ed, $08, $21, $20   ; dy -19 dx +8 tile 33 attr $20
    db $ee, $18, $18, $60   ; dy -18 dx +24 tile 24 attr $60
    db $ec, $00, $08, $00   ; dy -20 dx +0 tile 8 attr $00
    db $dc, $00, $15, $00   ; dy -36 dx +0 tile 21 attr $00
    db $f8, $40, $18, $60   ; dy -8 dx +64 tile 24 attr $60
    db $f0, $40, $19, $60   ; dy -16 dx +64 tile 25 attr $60
    db $f8, $38, $1a, $60   ; dy -8 dx +56 tile 26 attr $60
    db $f0, $38, $1b, $60   ; dy -16 dx +56 tile 27 attr $60
    db $f8, $30, $1c, $60   ; dy -8 dx +48 tile 28 attr $60
    db $f0, $30, $1d, $60   ; dy -16 dx +48 tile 29 attr $60
    db $f8, $28, $1e, $60   ; dy -8 dx +40 tile 30 attr $60
    db $f0, $28, $1f, $60   ; dy -16 dx +40 tile 31 attr $60
    db $f0, $20, $20, $20   ; dy -16 dx +32 tile 32 attr $20
    db $f8, $20, $21, $20   ; dy -8 dx +32 tile 33 attr $20
    db $e8, $f8, $28, $60   ; dy -24 dx -8 tile 40 attr $60
    db $e8, $f0, $29, $60   ; dy -24 dx -16 tile 41 attr $60
    db $e6, $18, $28, $60   ; dy -26 dx +24 tile 40 attr $60
    db $de, $25, $1a, $60   ; dy -34 dx +37 tile 26 attr $60
    db $de, $1d, $24, $40   ; dy -34 dx +29 tile 36 attr $40
    db $dc, $2d, $1c, $60   ; dy -36 dx +45 tile 28 attr $60
    db $d4, $2d, $1d, $60   ; dy -44 dx +45 tile 29 attr $60
    db $dc, $35, $22, $40   ; dy -36 dx +53 tile 34 attr $40
    db $d4, $35, $24, $40   ; dy -44 dx +53 tile 36 attr $40
    db $d0, $3d, $1e, $40   ; dy -48 dx +61 tile 30 attr $40
    db $f8, $48, $10, $60   ; dy -8 dx +72 tile 16 attr $60
    db $f0, $f7, $26, $60   ; dy -16 dx -9 tile 38 attr $60
    db $f8, $f4, $26, $00   ; dy -8 dx -12 tile 38 attr $00
    db $db, $3d, $27, $20   ; dy -37 dx +61 tile 39 attr $20
    db $80
Anim_11_F13:   ; $515f 32 sprites
    db $f4, $cb, $1d, $00   ; dy -12 dx -53 tile 29 attr $00
    db $f4, $c3, $24, $20   ; dy -12 dx -61 tile 36 attr $20
    db $f8, $bb, $1e, $20   ; dy -8 dx -69 tile 30 attr $20
    db $e4, $f8, $09, $40   ; dy -28 dx -8 tile 9 attr $40
    db $db, $e8, $1e, $00   ; dy -37 dx -24 tile 30 attr $00
    db $e3, $e8, $1e, $60   ; dy -29 dx -24 tile 30 attr $60
    db $e3, $f0, $20, $40   ; dy -29 dx -16 tile 32 attr $40
    db $db, $f0, $21, $40   ; dy -37 dx -16 tile 33 attr $40
    db $da, $e0, $18, $00   ; dy -38 dx -32 tile 24 attr $00
    db $dc, $f8, $08, $60   ; dy -36 dx -8 tile 8 attr $60
    db $ec, $f8, $15, $60   ; dy -20 dx -8 tile 21 attr $60
    db $d0, $b8, $18, $00   ; dy -48 dx -72 tile 24 attr $00
    db $d8, $b8, $19, $00   ; dy -40 dx -72 tile 25 attr $00
    db $d0, $c0, $1a, $00   ; dy -48 dx -64 tile 26 attr $00
    db $d8, $c0, $1b, $00   ; dy -40 dx -64 tile 27 attr $00
    db $d0, $c8, $1c, $00   ; dy -48 dx -56 tile 28 attr $00
    db $d8, $c8, $1d, $00   ; dy -40 dx -56 tile 29 attr $00
    db $d0, $d0, $1e, $00   ; dy -48 dx -48 tile 30 attr $00
    db $d8, $d0, $1f, $00   ; dy -40 dx -48 tile 31 attr $00
    db $d8, $d8, $20, $40   ; dy -40 dx -40 tile 32 attr $40
    db $d0, $d8, $21, $40   ; dy -48 dx -40 tile 33 attr $40
    db $e0, $00, $28, $00   ; dy -32 dx +0 tile 40 attr $00
    db $e0, $08, $29, $00   ; dy -32 dx +8 tile 41 attr $00
    db $e2, $e0, $28, $00   ; dy -30 dx -32 tile 40 attr $00
    db $ea, $d3, $1a, $00   ; dy -22 dx -45 tile 26 attr $00
    db $ea, $db, $24, $20   ; dy -22 dx -37 tile 36 attr $20
    db $ec, $cb, $1c, $00   ; dy -20 dx -53 tile 28 attr $00
    db $ec, $c3, $22, $20   ; dy -20 dx -61 tile 34 attr $20
    db $d0, $b0, $10, $00   ; dy -48 dx -80 tile 16 attr $00
    db $d8, $01, $26, $00   ; dy -40 dx +1 tile 38 attr $00
    db $d0, $04, $26, $60   ; dy -48 dx +4 tile 38 attr $60
    db $ed, $bb, $27, $40   ; dy -19 dx -69 tile 39 attr $40
    db $80
Anim_11_F14:   ; $51e0 14 sprites
    db $e8, $00, $1e, $60   ; dy -24 dx +0 tile 30 attr $60
    db $e0, $00, $1f, $60   ; dy -32 dx +0 tile 31 attr $60
    db $ea, $08, $1c, $20   ; dy -22 dx +8 tile 28 attr $20
    db $e0, $f8, $1e, $00   ; dy -32 dx -8 tile 30 attr $00
    db $e8, $f8, $1f, $00   ; dy -24 dx -8 tile 31 attr $00
    db $de, $f0, $1c, $40   ; dy -34 dx -16 tile 28 attr $40
    db $dd, $e8, $1f, $00   ; dy -35 dx -24 tile 31 attr $00
    db $d5, $e6, $24, $60   ; dy -43 dx -26 tile 36 attr $60
    db $d0, $e2, $0d, $60   ; dy -48 dx -30 tile 13 attr $60
    db $eb, $10, $1f, $60   ; dy -21 dx +16 tile 31 attr $60
    db $f3, $12, $24, $00   ; dy -13 dx +18 tile 36 attr $00
    db $f8, $16, $0d, $00   ; dy -8 dx +22 tile 13 attr $00
    db $d6, $f0, $05, $60   ; dy -42 dx -16 tile 5 attr $60
    db $f2, $08, $05, $00   ; dy -14 dx +8 tile 5 attr $00
    db $80
Anim_11_F15:   ; $5219 34 sprites
    db $e0, $fc, $14, $00   ; dy -32 dx -4 tile 20 attr $00
    db $e0, $04, $15, $00   ; dy -32 dx +4 tile 21 attr $00
    db $e8, $fd, $0c, $00   ; dy -24 dx -3 tile 12 attr $00
    db $e8, $05, $0d, $00   ; dy -24 dx +5 tile 13 attr $00
    db $e8, $fa, $0d, $20   ; dy -24 dx -6 tile 13 attr $20
    db $f0, $12, $0e, $20   ; dy -16 dx +18 tile 14 attr $20
    db $f0, $0a, $0f, $20   ; dy -16 dx +10 tile 15 attr $20
    db $f0, $19, $0c, $60   ; dy -16 dx +25 tile 12 attr $60
    db $f8, $0a, $09, $00   ; dy -8 dx +10 tile 9 attr $00
    db $f8, $1a, $0b, $40   ; dy -8 dx +26 tile 11 attr $40
    db $f8, $12, $0f, $20   ; dy -8 dx +18 tile 15 attr $20
    db $f8, $02, $20, $00   ; dy -8 dx +2 tile 32 attr $00
    db $d8, $f8, $08, $00   ; dy -40 dx -8 tile 8 attr $00
    db $d8, $00, $09, $00   ; dy -40 dx +0 tile 9 attr $00
    db $d8, $07, $16, $60   ; dy -40 dx +7 tile 22 attr $60
    db $d0, $13, $1c, $40   ; dy -48 dx +19 tile 28 attr $40
    db $d0, $03, $08, $00   ; dy -48 dx +3 tile 8 attr $00
    db $d0, $0b, $09, $00   ; dy -48 dx +11 tile 9 attr $00
    db $d0, $1b, $2a, $00   ; dy -48 dx +27 tile 42 attr $00
    db $d8, $1b, $05, $20   ; dy -40 dx +27 tile 5 attr $20
    db $d8, $e8, $0e, $40   ; dy -40 dx -24 tile 14 attr $40
    db $d8, $f0, $0f, $40   ; dy -40 dx -16 tile 15 attr $40
    db $d8, $e1, $0c, $00   ; dy -40 dx -31 tile 12 attr $00
    db $d0, $f0, $09, $60   ; dy -48 dx -16 tile 9 attr $60
    db $d0, $e0, $0b, $20   ; dy -48 dx -32 tile 11 attr $20
    db $d0, $e8, $0f, $40   ; dy -48 dx -24 tile 15 attr $40
    db $d0, $f8, $20, $60   ; dy -48 dx -8 tile 32 attr $60
    db $f8, $e6, $1c, $20   ; dy -8 dx -26 tile 28 attr $20
    db $f8, $f5, $08, $60   ; dy -8 dx -11 tile 8 attr $60
    db $f8, $ee, $09, $60   ; dy -8 dx -18 tile 9 attr $60
    db $f8, $de, $2a, $60   ; dy -8 dx -34 tile 42 attr $60
    db $f0, $de, $05, $40   ; dy -16 dx -34 tile 5 attr $40
    db $ef, $f7, $09, $00   ; dy -17 dx -9 tile 9 attr $00
    db $f1, $ef, $21, $60   ; dy -15 dx -17 tile 33 attr $60
Anim_11_F16:   ; $52a1 empty frame = the $80 end above (shared)
    db $80
Anim_12_StopSpell:   ; $52a2 animation $12 — StopSpell, RobMagic, Sap, Defence, Slow, SlowAll (+6)
    dw Anim_12_F00
    dw Anim_12_F01
    dw Anim_12_F02
    dw Anim_12_F03
    dw Anim_12_F04
    dw Anim_12_F05
    dw Anim_12_F06
    dw Anim_12_F07
    dw Anim_12_F08
    dw Anim_12_F09
    dw Anim_12_F10
    dw Anim_12_F11
    dw Anim_12_F11
    dw Anim_12_F11
    dw Anim_12_F11
    dw Anim_12_F11
    dw Anim_12_F11
    dw Anim_12_F11
    dw Anim_12_F11
    dw Anim_12_F11
    dw Anim_12_F11
    dw Anim_12_F11
    dw Anim_12_F11
    dw Anim_12_F11
    dw Anim_12_F11
    dw Anim_12_F11
    dw Anim_12_F11
    dw Anim_12_F11
    dw Anim_12_F11
    dw Anim_12_F11
    dw Anim_12_F11
    dw Anim_12_F11
Anim_12_F00:   ; $52e2 2 sprites
    db $d0, $10, $00, $00   ; dy -48 dx +16 tile 0 attr $00
    db $d8, $10, $01, $00   ; dy -40 dx +16 tile 1 attr $00
    db $80
Anim_12_F01:   ; $52eb 5 sprites
    db $d8, $08, $01, $00   ; dy -40 dx +8 tile 1 attr $00
    db $d0, $08, $00, $00   ; dy -48 dx +8 tile 0 attr $00
    db $d2, $10, $02, $00   ; dy -46 dx +16 tile 2 attr $00
    db $da, $10, $03, $00   ; dy -38 dx +16 tile 3 attr $00
    db $e2, $10, $04, $00   ; dy -30 dx +16 tile 4 attr $00
    db $80
Anim_12_F02:   ; $5300 9 sprites
    db $d0, $00, $00, $00   ; dy -48 dx +0 tile 0 attr $00
    db $d8, $00, $01, $00   ; dy -40 dx +0 tile 1 attr $00
    db $d2, $08, $02, $00   ; dy -46 dx +8 tile 2 attr $00
    db $da, $08, $03, $00   ; dy -38 dx +8 tile 3 attr $00
    db $e2, $08, $04, $00   ; dy -30 dx +8 tile 4 attr $00
    db $d4, $10, $05, $00   ; dy -44 dx +16 tile 5 attr $00
    db $dc, $10, $06, $00   ; dy -36 dx +16 tile 6 attr $00
    db $e4, $10, $07, $00   ; dy -28 dx +16 tile 7 attr $00
    db $ec, $10, $08, $00   ; dy -20 dx +16 tile 8 attr $00
    db $80
Anim_12_F03:   ; $5325 13 sprites
    db $d0, $f8, $00, $00   ; dy -48 dx -8 tile 0 attr $00
    db $d8, $f8, $01, $00   ; dy -40 dx -8 tile 1 attr $00
    db $d2, $00, $02, $00   ; dy -46 dx +0 tile 2 attr $00
    db $da, $00, $03, $00   ; dy -38 dx +0 tile 3 attr $00
    db $e2, $00, $04, $00   ; dy -30 dx +0 tile 4 attr $00
    db $d4, $08, $05, $00   ; dy -44 dx +8 tile 5 attr $00
    db $dc, $08, $06, $00   ; dy -36 dx +8 tile 6 attr $00
    db $e4, $08, $07, $00   ; dy -28 dx +8 tile 7 attr $00
    db $ec, $08, $08, $00   ; dy -20 dx +8 tile 8 attr $00
    db $d6, $10, $09, $00   ; dy -42 dx +16 tile 9 attr $00
    db $de, $10, $0a, $00   ; dy -34 dx +16 tile 10 attr $00
    db $e6, $10, $0b, $00   ; dy -26 dx +16 tile 11 attr $00
    db $ee, $10, $0c, $00   ; dy -18 dx +16 tile 12 attr $00
    db $80
Anim_12_F04:   ; $535a 16 sprites
    db $d0, $f0, $00, $00   ; dy -48 dx -16 tile 0 attr $00
    db $d8, $f0, $01, $00   ; dy -40 dx -16 tile 1 attr $00
    db $d2, $f8, $02, $00   ; dy -46 dx -8 tile 2 attr $00
    db $da, $f8, $03, $00   ; dy -38 dx -8 tile 3 attr $00
    db $e2, $f8, $04, $00   ; dy -30 dx -8 tile 4 attr $00
    db $d4, $00, $05, $00   ; dy -44 dx +0 tile 5 attr $00
    db $dc, $00, $06, $00   ; dy -36 dx +0 tile 6 attr $00
    db $e4, $00, $07, $00   ; dy -28 dx +0 tile 7 attr $00
    db $ec, $00, $08, $00   ; dy -20 dx +0 tile 8 attr $00
    db $d6, $08, $09, $00   ; dy -42 dx +8 tile 9 attr $00
    db $de, $08, $0a, $00   ; dy -34 dx +8 tile 10 attr $00
    db $e6, $08, $0b, $00   ; dy -26 dx +8 tile 11 attr $00
    db $ee, $08, $0c, $00   ; dy -18 dx +8 tile 12 attr $00
    db $e0, $10, $0d, $00   ; dy -32 dx +16 tile 13 attr $00
    db $e8, $10, $0e, $00   ; dy -24 dx +16 tile 14 attr $00
    db $f0, $10, $0f, $00   ; dy -16 dx +16 tile 15 attr $00
    db $80
Anim_12_F05:   ; $539b 18 sprites
    db $d0, $e8, $00, $00   ; dy -48 dx -24 tile 0 attr $00
    db $d8, $e8, $01, $00   ; dy -40 dx -24 tile 1 attr $00
    db $d2, $f0, $02, $00   ; dy -46 dx -16 tile 2 attr $00
    db $da, $f0, $03, $00   ; dy -38 dx -16 tile 3 attr $00
    db $e2, $f0, $04, $00   ; dy -30 dx -16 tile 4 attr $00
    db $d4, $f8, $05, $00   ; dy -44 dx -8 tile 5 attr $00
    db $dc, $f8, $06, $00   ; dy -36 dx -8 tile 6 attr $00
    db $e4, $f8, $07, $00   ; dy -28 dx -8 tile 7 attr $00
    db $ec, $f8, $08, $00   ; dy -20 dx -8 tile 8 attr $00
    db $d6, $00, $09, $00   ; dy -42 dx +0 tile 9 attr $00
    db $de, $00, $0a, $00   ; dy -34 dx +0 tile 10 attr $00
    db $e6, $00, $0b, $00   ; dy -26 dx +0 tile 11 attr $00
    db $ee, $00, $0c, $00   ; dy -18 dx +0 tile 12 attr $00
    db $e0, $08, $0d, $00   ; dy -32 dx +8 tile 13 attr $00
    db $e8, $08, $0e, $00   ; dy -24 dx +8 tile 14 attr $00
    db $f0, $08, $0f, $00   ; dy -16 dx +8 tile 15 attr $00
    db $ea, $10, $10, $00   ; dy -22 dx +16 tile 16 attr $00
    db $f2, $10, $11, $00   ; dy -14 dx +16 tile 17 attr $00
    db $80
Anim_12_F06:   ; $53e4 16 sprites
    db $ea, $08, $10, $00   ; dy -22 dx +8 tile 16 attr $00
    db $f2, $08, $11, $00   ; dy -14 dx +8 tile 17 attr $00
    db $e0, $00, $0d, $00   ; dy -32 dx +0 tile 13 attr $00
    db $e8, $00, $0e, $00   ; dy -24 dx +0 tile 14 attr $00
    db $f0, $00, $0f, $00   ; dy -16 dx +0 tile 15 attr $00
    db $d2, $e8, $02, $00   ; dy -46 dx -24 tile 2 attr $00
    db $da, $e8, $03, $00   ; dy -38 dx -24 tile 3 attr $00
    db $e2, $e8, $04, $00   ; dy -30 dx -24 tile 4 attr $00
    db $d4, $f0, $05, $00   ; dy -44 dx -16 tile 5 attr $00
    db $dc, $f0, $06, $00   ; dy -36 dx -16 tile 6 attr $00
    db $e4, $f0, $07, $00   ; dy -28 dx -16 tile 7 attr $00
    db $ec, $f0, $08, $00   ; dy -20 dx -16 tile 8 attr $00
    db $d6, $f8, $09, $00   ; dy -42 dx -8 tile 9 attr $00
    db $de, $f8, $0a, $00   ; dy -34 dx -8 tile 10 attr $00
    db $e6, $f8, $0b, $00   ; dy -26 dx -8 tile 11 attr $00
    db $ee, $f8, $0c, $00   ; dy -18 dx -8 tile 12 attr $00
    db $80
Anim_12_F07:   ; $5425 13 sprites
    db $d4, $e8, $05, $00   ; dy -44 dx -24 tile 5 attr $00
    db $dc, $e8, $06, $00   ; dy -36 dx -24 tile 6 attr $00
    db $e4, $e8, $07, $00   ; dy -28 dx -24 tile 7 attr $00
    db $ec, $e8, $08, $00   ; dy -20 dx -24 tile 8 attr $00
    db $d6, $f0, $09, $00   ; dy -42 dx -16 tile 9 attr $00
    db $de, $f0, $0a, $00   ; dy -34 dx -16 tile 10 attr $00
    db $e6, $f0, $0b, $00   ; dy -26 dx -16 tile 11 attr $00
    db $ee, $f0, $0c, $00   ; dy -18 dx -16 tile 12 attr $00
    db $e0, $f8, $0d, $00   ; dy -32 dx -8 tile 13 attr $00
    db $e8, $f8, $0e, $00   ; dy -24 dx -8 tile 14 attr $00
    db $f0, $f8, $0f, $00   ; dy -16 dx -8 tile 15 attr $00
    db $ea, $00, $10, $00   ; dy -22 dx +0 tile 16 attr $00
    db $f2, $00, $11, $00   ; dy -14 dx +0 tile 17 attr $00
    db $80
Anim_12_F08:   ; $545a 9 sprites
    db $d6, $e8, $09, $00   ; dy -42 dx -24 tile 9 attr $00
    db $de, $e8, $0a, $00   ; dy -34 dx -24 tile 10 attr $00
    db $e6, $e8, $0b, $00   ; dy -26 dx -24 tile 11 attr $00
    db $ee, $e8, $0c, $00   ; dy -18 dx -24 tile 12 attr $00
    db $e0, $f0, $0d, $00   ; dy -32 dx -16 tile 13 attr $00
    db $e8, $f0, $0e, $00   ; dy -24 dx -16 tile 14 attr $00
    db $f0, $f0, $0f, $00   ; dy -16 dx -16 tile 15 attr $00
    db $ea, $f8, $10, $00   ; dy -22 dx -8 tile 16 attr $00
    db $f2, $f8, $11, $00   ; dy -14 dx -8 tile 17 attr $00
    db $80
Anim_12_F09:   ; $547f 5 sprites
    db $e0, $e8, $0d, $00   ; dy -32 dx -24 tile 13 attr $00
    db $e8, $e8, $0e, $00   ; dy -24 dx -24 tile 14 attr $00
    db $f0, $e8, $0f, $00   ; dy -16 dx -24 tile 15 attr $00
    db $ea, $f0, $10, $00   ; dy -22 dx -16 tile 16 attr $00
    db $f2, $f0, $11, $00   ; dy -14 dx -16 tile 17 attr $00
    db $80
Anim_12_F10:   ; $5494 2 sprites
    db $ea, $e8, $10, $00   ; dy -22 dx -24 tile 16 attr $00
    db $f2, $e8, $11, $00   ; dy -14 dx -24 tile 17 attr $00
Anim_12_F11:   ; $549c empty frame = the $80 end above (shared)
    db $80
Anim_13_RobMagic:   ; $549d animation $13 — RobMagic, TakeMagic, Upper, Increase, Speed, SpeedUp (+2)
    dw Anim_13_F00
    dw Anim_13_F01
    dw Anim_13_F02
    dw Anim_13_F03
    dw Anim_13_F04
    dw Anim_13_F05
    dw Anim_13_F06
    dw Anim_13_F07
    dw Anim_13_F08
    dw Anim_13_F08
    dw Anim_13_F08
    dw Anim_13_F08
    dw Anim_13_F08
    dw Anim_13_F08
    dw Anim_13_F08
    dw Anim_13_F08
    dw Anim_13_F08
    dw Anim_13_F08
    dw Anim_13_F08
    dw Anim_13_F08
    dw Anim_13_F08
    dw Anim_13_F08
    dw Anim_13_F08
    dw Anim_13_F08
    dw Anim_13_F08
    dw Anim_13_F08
    dw Anim_13_F08
    dw Anim_13_F08
    dw Anim_13_F08
    dw Anim_13_F08
    dw Anim_13_F08
    dw Anim_13_F08
Anim_13_F00:   ; $54dd 12 sprites
    db $e8, $f0, $00, $00   ; dy -24 dx -16 tile 0 attr $00
    db $e8, $f8, $01, $00   ; dy -24 dx -8 tile 1 attr $00
    db $e8, $00, $00, $00   ; dy -24 dx +0 tile 0 attr $00
    db $e8, $08, $01, $00   ; dy -24 dx +8 tile 1 attr $00
    db $f0, $f0, $02, $00   ; dy -16 dx -16 tile 2 attr $00
    db $f0, $f8, $03, $00   ; dy -16 dx -8 tile 3 attr $00
    db $f0, $00, $02, $00   ; dy -16 dx +0 tile 2 attr $00
    db $f0, $08, $03, $00   ; dy -16 dx +8 tile 3 attr $00
    db $f8, $f0, $04, $00   ; dy -8 dx -16 tile 4 attr $00
    db $f8, $f8, $05, $00   ; dy -8 dx -8 tile 5 attr $00
    db $f8, $00, $04, $00   ; dy -8 dx +0 tile 4 attr $00
    db $f8, $08, $05, $00   ; dy -8 dx +8 tile 5 attr $00
    db $80
Anim_13_F01:   ; $550e 16 sprites
    db $e0, $f0, $06, $00   ; dy -32 dx -16 tile 6 attr $00
    db $e0, $f8, $07, $00   ; dy -32 dx -8 tile 7 attr $00
    db $e0, $00, $06, $00   ; dy -32 dx +0 tile 6 attr $00
    db $e0, $08, $07, $00   ; dy -32 dx +8 tile 7 attr $00
    db $e8, $f0, $08, $00   ; dy -24 dx -16 tile 8 attr $00
    db $e8, $f8, $09, $00   ; dy -24 dx -8 tile 9 attr $00
    db $e8, $00, $08, $00   ; dy -24 dx +0 tile 8 attr $00
    db $e8, $08, $09, $00   ; dy -24 dx +8 tile 9 attr $00
    db $f0, $f0, $0a, $00   ; dy -16 dx -16 tile 10 attr $00
    db $f0, $f8, $0b, $00   ; dy -16 dx -8 tile 11 attr $00
    db $f0, $00, $0a, $00   ; dy -16 dx +0 tile 10 attr $00
    db $f0, $08, $0b, $00   ; dy -16 dx +8 tile 11 attr $00
    db $f8, $00, $0c, $00   ; dy -8 dx +0 tile 12 attr $00
    db $f8, $08, $0d, $00   ; dy -8 dx +8 tile 13 attr $00
    db $f8, $f0, $0c, $00   ; dy -8 dx -16 tile 12 attr $00
    db $f8, $f8, $0d, $00   ; dy -8 dx -8 tile 13 attr $00
    db $80
Anim_13_F02:   ; $554f 12 sprites
    db $d8, $f0, $00, $00   ; dy -40 dx -16 tile 0 attr $00
    db $d8, $f8, $01, $00   ; dy -40 dx -8 tile 1 attr $00
    db $d8, $00, $00, $00   ; dy -40 dx +0 tile 0 attr $00
    db $d8, $08, $01, $00   ; dy -40 dx +8 tile 1 attr $00
    db $e0, $00, $02, $00   ; dy -32 dx +0 tile 2 attr $00
    db $e0, $08, $03, $00   ; dy -32 dx +8 tile 3 attr $00
    db $e0, $f0, $02, $00   ; dy -32 dx -16 tile 2 attr $00
    db $e0, $f8, $03, $00   ; dy -32 dx -8 tile 3 attr $00
    db $e8, $00, $04, $00   ; dy -24 dx +0 tile 4 attr $00
    db $e8, $08, $05, $00   ; dy -24 dx +8 tile 5 attr $00
    db $e8, $f0, $04, $00   ; dy -24 dx -16 tile 4 attr $00
    db $e8, $f8, $05, $00   ; dy -24 dx -8 tile 5 attr $00
    db $80
Anim_13_F03:   ; $5580 16 sprites
    db $d0, $00, $06, $00   ; dy -48 dx +0 tile 6 attr $00
    db $d0, $08, $07, $00   ; dy -48 dx +8 tile 7 attr $00
    db $d0, $f0, $06, $00   ; dy -48 dx -16 tile 6 attr $00
    db $d0, $f8, $07, $00   ; dy -48 dx -8 tile 7 attr $00
    db $d8, $00, $08, $00   ; dy -40 dx +0 tile 8 attr $00
    db $d8, $08, $09, $00   ; dy -40 dx +8 tile 9 attr $00
    db $d8, $f0, $08, $00   ; dy -40 dx -16 tile 8 attr $00
    db $d8, $f8, $09, $00   ; dy -40 dx -8 tile 9 attr $00
    db $e0, $00, $0a, $00   ; dy -32 dx +0 tile 10 attr $00
    db $e0, $08, $0b, $00   ; dy -32 dx +8 tile 11 attr $00
    db $e0, $f0, $0a, $00   ; dy -32 dx -16 tile 10 attr $00
    db $e0, $f8, $0b, $00   ; dy -32 dx -8 tile 11 attr $00
    db $e8, $00, $0c, $00   ; dy -24 dx +0 tile 12 attr $00
    db $e8, $08, $0d, $00   ; dy -24 dx +8 tile 13 attr $00
    db $e8, $f0, $0c, $00   ; dy -24 dx -16 tile 12 attr $00
    db $e8, $f8, $0d, $00   ; dy -24 dx -8 tile 13 attr $00
    db $80
Anim_13_F04:   ; $55c1 8 sprites
    db $d0, $f0, $02, $00   ; dy -48 dx -16 tile 2 attr $00
    db $d0, $f8, $03, $00   ; dy -48 dx -8 tile 3 attr $00
    db $d0, $00, $02, $00   ; dy -48 dx +0 tile 2 attr $00
    db $d0, $08, $03, $00   ; dy -48 dx +8 tile 3 attr $00
    db $d8, $00, $04, $00   ; dy -40 dx +0 tile 4 attr $00
    db $d8, $08, $05, $00   ; dy -40 dx +8 tile 5 attr $00
    db $d8, $f0, $04, $00   ; dy -40 dx -16 tile 4 attr $00
    db $d8, $f8, $05, $00   ; dy -40 dx -8 tile 5 attr $00
    db $80
Anim_13_F05:   ; $55e2 8 sprites
    db $d0, $f0, $0a, $00   ; dy -48 dx -16 tile 10 attr $00
    db $d0, $f8, $0b, $00   ; dy -48 dx -8 tile 11 attr $00
    db $d0, $00, $0a, $00   ; dy -48 dx +0 tile 10 attr $00
    db $d0, $08, $0b, $00   ; dy -48 dx +8 tile 11 attr $00
    db $d8, $f0, $0c, $00   ; dy -40 dx -16 tile 12 attr $00
    db $d8, $f8, $0d, $00   ; dy -40 dx -8 tile 13 attr $00
    db $d8, $00, $0c, $00   ; dy -40 dx +0 tile 12 attr $00
    db $d8, $08, $0d, $00   ; dy -40 dx +8 tile 13 attr $00
    db $80
Anim_13_F06:   ; $5603 4 sprites
    db $d0, $f0, $04, $00   ; dy -48 dx -16 tile 4 attr $00
    db $d0, $f8, $05, $00   ; dy -48 dx -8 tile 5 attr $00
    db $d0, $00, $04, $00   ; dy -48 dx +0 tile 4 attr $00
    db $d0, $08, $05, $00   ; dy -48 dx +8 tile 5 attr $00
    db $80
Anim_13_F07:   ; $5614 4 sprites
    db $d0, $f0, $0c, $00   ; dy -48 dx -16 tile 12 attr $00
    db $d0, $f8, $0d, $00   ; dy -48 dx -8 tile 13 attr $00
    db $d0, $00, $0c, $00   ; dy -48 dx +0 tile 12 attr $00
    db $d0, $08, $0d, $00   ; dy -48 dx +8 tile 13 attr $00
Anim_13_F08:   ; $5624 empty frame = the $80 end above (shared)
    db $80
Anim_14_Heal:   ; $5625 animation $14 — Heal, HealMore, HealAll, HealUs, HealUsAll, Farewell (+20)
    dw Anim_14_F00
    dw Anim_14_F01
    dw Anim_14_F02
    dw Anim_14_F03
    dw Anim_14_F04
    dw Anim_14_F05
    dw Anim_14_F06
    dw Anim_14_F07
    dw Anim_14_F08
    dw Anim_14_F09
    dw Anim_14_F10
    dw Anim_14_F11
    dw Anim_14_F11
    dw Anim_14_F11
    dw Anim_14_F11
    dw Anim_14_F11
    dw Anim_14_F11
    dw Anim_14_F11
    dw Anim_14_F11
    dw Anim_14_F11
    dw Anim_14_F11
    dw Anim_14_F11
    dw Anim_14_F11
    dw Anim_14_F11
    dw Anim_14_F11
    dw Anim_14_F11
    dw Anim_14_F11
    dw Anim_14_F11
    dw Anim_14_F11
    dw Anim_14_F11
    dw Anim_14_F11
    dw Anim_14_F11
Anim_14_F00:   ; $5665 1 sprites
    db $e5, $f5, $00, $00   ; dy -27 dx -11 tile 0 attr $00
    db $80
Anim_14_F01:   ; $566a 5 sprites
    db $e0, $f0, $00, $00   ; dy -32 dx -16 tile 0 attr $00
    db $e8, $f0, $02, $00   ; dy -24 dx -16 tile 2 attr $00
    db $e8, $f8, $03, $00   ; dy -24 dx -8 tile 3 attr $00
    db $e0, $f8, $05, $00   ; dy -32 dx -8 tile 5 attr $00
    db $dd, $05, $00, $00   ; dy -35 dx +5 tile 0 attr $00
    db $80
Anim_14_F02:   ; $567f 9 sprites
    db $d8, $00, $00, $00   ; dy -40 dx +0 tile 0 attr $00
    db $e0, $00, $02, $00   ; dy -32 dx +0 tile 2 attr $00
    db $e0, $08, $03, $00   ; dy -32 dx +8 tile 3 attr $00
    db $d8, $08, $01, $00   ; dy -40 dx +8 tile 1 attr $00
    db $ed, $05, $00, $00   ; dy -19 dx +5 tile 0 attr $00
    db $e0, $f0, $01, $00   ; dy -32 dx -16 tile 1 attr $00
    db $e4, $f8, $04, $00   ; dy -28 dx -8 tile 4 attr $00
    db $e8, $f8, $01, $00   ; dy -24 dx -8 tile 1 attr $00
    db $e7, $f2, $04, $00   ; dy -25 dx -14 tile 4 attr $00
    db $80
Anim_14_F03:   ; $56a4 11 sprites
    db $d8, $00, $01, $00   ; dy -40 dx +0 tile 1 attr $00
    db $dc, $08, $04, $00   ; dy -36 dx +8 tile 4 attr $00
    db $e0, $08, $01, $00   ; dy -32 dx +8 tile 1 attr $00
    db $df, $02, $04, $00   ; dy -33 dx +2 tile 4 attr $00
    db $e6, $f2, $05, $00   ; dy -26 dx -14 tile 5 attr $00
    db $e0, $f8, $05, $00   ; dy -32 dx -8 tile 5 attr $00
    db $e4, $f4, $04, $00   ; dy -28 dx -12 tile 4 attr $00
    db $e8, $00, $00, $00   ; dy -24 dx +0 tile 0 attr $00
    db $f0, $00, $02, $00   ; dy -16 dx +0 tile 2 attr $00
    db $f0, $08, $03, $00   ; dy -16 dx +8 tile 3 attr $00
    db $e8, $08, $01, $00   ; dy -24 dx +8 tile 1 attr $00
    db $80
Anim_14_F04:   ; $56d1 9 sprites
    db $e0, $f0, $01, $00   ; dy -32 dx -16 tile 1 attr $00
    db $d8, $08, $01, $00   ; dy -40 dx +8 tile 1 attr $00
    db $de, $02, $01, $00   ; dy -34 dx +2 tile 1 attr $00
    db $dc, $04, $04, $00   ; dy -36 dx +4 tile 4 attr $00
    db $e8, $00, $01, $00   ; dy -24 dx +0 tile 1 attr $00
    db $f0, $08, $01, $00   ; dy -16 dx +8 tile 1 attr $00
    db $ef, $02, $04, $00   ; dy -17 dx +2 tile 4 attr $00
    db $ec, $08, $04, $00   ; dy -20 dx +8 tile 4 attr $00
    db $e6, $f7, $01, $40   ; dy -26 dx -9 tile 1 attr $40
    db $80
Anim_14_F05:   ; $56f6 5 sprites
    db $d8, $00, $01, $00   ; dy -40 dx +0 tile 1 attr $00
    db $e8, $08, $01, $00   ; dy -24 dx +8 tile 1 attr $00
    db $ee, $02, $01, $00   ; dy -18 dx +2 tile 1 attr $00
    db $ec, $04, $04, $00   ; dy -20 dx +4 tile 4 attr $00
    db $de, $07, $05, $40   ; dy -34 dx +7 tile 5 attr $40
    db $80
Anim_14_F06:   ; $570b 2 sprites
    db $e8, $00, $01, $00   ; dy -24 dx +0 tile 1 attr $00
    db $ee, $07, $01, $40   ; dy -18 dx +7 tile 1 attr $40
    db $80
Anim_14_F07:   ; $5714 7 sprites
    db $e6, $f2, $01, $00   ; dy -26 dx -14 tile 1 attr $00
    db $e0, $f8, $01, $00   ; dy -32 dx -8 tile 1 attr $00
    db $e4, $f4, $04, $00   ; dy -28 dx -12 tile 4 attr $00
    db $e8, $00, $00, $00   ; dy -24 dx +0 tile 0 attr $00
    db $e8, $08, $01, $00   ; dy -24 dx +8 tile 1 attr $00
    db $f0, $00, $02, $00   ; dy -16 dx +0 tile 2 attr $00
    db $f0, $08, $03, $00   ; dy -16 dx +8 tile 3 attr $00
    db $80
Anim_14_F08:   ; $5731 6 sprites
    db $e0, $f0, $01, $00   ; dy -32 dx -16 tile 1 attr $00
    db $e8, $00, $01, $00   ; dy -24 dx +0 tile 1 attr $00
    db $f0, $08, $01, $00   ; dy -16 dx +8 tile 1 attr $00
    db $e6, $f7, $01, $40   ; dy -26 dx -9 tile 1 attr $40
    db $ec, $08, $04, $00   ; dy -20 dx +8 tile 4 attr $00
    db $ef, $02, $04, $00   ; dy -17 dx +2 tile 4 attr $00
    db $80
Anim_14_F09:   ; $574a 3 sprites
    db $ee, $02, $01, $00   ; dy -18 dx +2 tile 1 attr $00
    db $e8, $08, $01, $00   ; dy -24 dx +8 tile 1 attr $00
    db $ec, $04, $04, $00   ; dy -20 dx +4 tile 4 attr $00
    db $80
Anim_14_F10:   ; $5757 2 sprites
    db $e8, $00, $01, $00   ; dy -24 dx +0 tile 1 attr $00
    db $ee, $07, $01, $40   ; dy -18 dx +7 tile 1 attr $40
Anim_14_F11:   ; $575f empty frame = the $80 end above (shared)
    db $80
Anim_15_Sleep:   ; $5760 animation $15 — Sleep, SleepAll, PoisonHit, NapAttack, Paralyze, SleepAir (+7)
    dw Anim_15_F00
    dw Anim_15_F01
    dw Anim_15_F02
    dw Anim_15_F03
    dw Anim_15_F04
    dw Anim_15_F05
    dw Anim_15_F06
    dw Anim_15_F07
    dw Anim_15_F08
    dw Anim_15_F09
    dw Anim_15_F10
    dw Anim_15_F10
    dw Anim_15_F10
    dw Anim_15_F10
    dw Anim_15_F10
    dw Anim_15_F10
    dw Anim_15_F10
    dw Anim_15_F10
    dw Anim_15_F10
    dw Anim_15_F10
    dw Anim_15_F10
    dw Anim_15_F10
    dw Anim_15_F10
    dw Anim_15_F10
    dw Anim_15_F10
    dw Anim_15_F10
    dw Anim_15_F10
    dw Anim_15_F10
    dw Anim_15_F10
    dw Anim_15_F10
    dw Anim_15_F10
    dw Anim_15_F10
Anim_15_F00:   ; $57a0 2 sprites
    db $ea, $02, $01, $00   ; dy -22 dx +2 tile 1 attr $00
    db $e0, $f8, $02, $00   ; dy -32 dx -8 tile 2 attr $00
    db $80
Anim_15_F01:   ; $57a9 4 sprites
    db $e0, $0b, $01, $00   ; dy -32 dx +11 tile 1 attr $00
    db $eb, $ee, $01, $00   ; dy -21 dx -18 tile 1 attr $00
    db $ea, $02, $02, $00   ; dy -22 dx +2 tile 2 attr $00
    db $e0, $f8, $03, $00   ; dy -32 dx -8 tile 3 attr $00
    db $80
Anim_15_F02:   ; $57ba 6 sprites
    db $f0, $10, $01, $00   ; dy -16 dx +16 tile 1 attr $00
    db $db, $ef, $01, $00   ; dy -37 dx -17 tile 1 attr $00
    db $e0, $0b, $02, $00   ; dy -32 dx +11 tile 2 attr $00
    db $eb, $ec, $02, $00   ; dy -21 dx -20 tile 2 attr $00
    db $ea, $02, $03, $00   ; dy -22 dx +2 tile 3 attr $00
    db $e0, $f8, $04, $00   ; dy -32 dx -8 tile 4 attr $00
    db $80
Anim_15_F03:   ; $57d3 7 sprites
    db $da, $fe, $01, $00   ; dy -38 dx -2 tile 1 attr $00
    db $dd, $f8, $00, $00   ; dy -35 dx -8 tile 0 attr $00
    db $db, $ef, $02, $00   ; dy -37 dx -17 tile 2 attr $00
    db $f0, $10, $02, $00   ; dy -16 dx +16 tile 2 attr $00
    db $e0, $0b, $03, $00   ; dy -32 dx +11 tile 3 attr $00
    db $eb, $ec, $03, $00   ; dy -21 dx -20 tile 3 attr $00
    db $ea, $02, $04, $00   ; dy -22 dx +2 tile 4 attr $00
    db $80
Anim_15_F04:   ; $57f0 8 sprites
    db $d6, $fa, $00, $00   ; dy -42 dx -6 tile 0 attr $00
    db $e7, $01, $00, $00   ; dy -25 dx +1 tile 0 attr $00
    db $e2, $e8, $01, $00   ; dy -30 dx -24 tile 1 attr $00
    db $eb, $ff, $01, $00   ; dy -21 dx -1 tile 1 attr $00
    db $e0, $0b, $04, $00   ; dy -32 dx +11 tile 4 attr $00
    db $eb, $ec, $04, $00   ; dy -21 dx -20 tile 4 attr $00
    db $f0, $10, $03, $00   ; dy -16 dx +16 tile 3 attr $00
    db $db, $ef, $03, $00   ; dy -37 dx -17 tile 3 attr $00
    db $80
Anim_15_F05:   ; $5811 8 sprites
    db $e2, $00, $00, $00   ; dy -30 dx +0 tile 0 attr $00
    db $dd, $0c, $00, $00   ; dy -35 dx +12 tile 0 attr $00
    db $e8, $ea, $00, $00   ; dy -24 dx -22 tile 0 attr $00
    db $e2, $13, $01, $00   ; dy -30 dx +19 tile 1 attr $00
    db $ef, $e7, $01, $00   ; dy -17 dx -25 tile 1 attr $00
    db $e2, $e6, $02, $00   ; dy -30 dx -26 tile 2 attr $00
    db $f0, $10, $04, $00   ; dy -16 dx +16 tile 4 attr $00
    db $db, $ef, $04, $00   ; dy -37 dx -17 tile 4 attr $00
    db $80
Anim_15_F06:   ; $5832 6 sprites
    db $d9, $ee, $00, $00   ; dy -39 dx -18 tile 0 attr $00
    db $e5, $e7, $00, $00   ; dy -27 dx -25 tile 0 attr $00
    db $ec, $0f, $00, $00   ; dy -20 dx +15 tile 0 attr $00
    db $ed, $0c, $01, $00   ; dy -19 dx +12 tile 1 attr $00
    db $d8, $e9, $01, $00   ; dy -40 dx -23 tile 1 attr $00
    db $e2, $e7, $03, $00   ; dy -30 dx -25 tile 3 attr $00
    db $80
Anim_15_F07:   ; $584b 3 sprites
    db $d4, $ec, $00, $00   ; dy -44 dx -20 tile 0 attr $00
    db $e9, $13, $01, $00   ; dy -23 dx +19 tile 1 attr $00
    db $e1, $e8, $04, $00   ; dy -31 dx -24 tile 4 attr $00
    db $80
Anim_15_F08:   ; $5858 3 sprites
    db $d8, $ef, $00, $00   ; dy -40 dx -17 tile 0 attr $00
    db $de, $e8, $01, $00   ; dy -34 dx -24 tile 1 attr $00
    db $e0, $f7, $01, $00   ; dy -32 dx -9 tile 1 attr $00
    db $80
Anim_15_F09:   ; $5865 1 sprites
    db $d8, $ea, $01, $00   ; dy -40 dx -22 tile 1 attr $00
Anim_15_F10:   ; $5869 empty frame = the $80 end above (shared)
    db $80
Anim_16_PanicAll:   ; $586a animation $16 — PanicAll, PaniDance, Curse, Ahhh, LureDance
    dw Anim_16_F00
    dw Anim_16_F01
    dw Anim_16_F02
    dw Anim_16_F03
    dw Anim_16_F04
    dw Anim_16_F05
    dw Anim_16_F06
    dw Anim_16_F07
    dw Anim_16_F08
    dw Anim_16_F09
    dw Anim_16_F09
    dw Anim_16_F09
    dw Anim_16_F09
    dw Anim_16_F09
    dw Anim_16_F09
    dw Anim_16_F09
    dw Anim_16_F09
    dw Anim_16_F09
    dw Anim_16_F09
    dw Anim_16_F09
    dw Anim_16_F09
    dw Anim_16_F09
    dw Anim_16_F09
    dw Anim_16_F09
    dw Anim_16_F09
    dw Anim_16_F09
    dw Anim_16_F09
    dw Anim_16_F09
    dw Anim_16_F09
    dw Anim_16_F09
    dw Anim_16_F09
    dw Anim_16_F09
Anim_16_F00:   ; $58aa 1 sprites
    db $e8, $fc, $00, $00   ; dy -24 dx -4 tile 0 attr $00
    db $80
Anim_16_F01:   ; $58af 1 sprites
    db $e7, $fd, $00, $00   ; dy -25 dx -3 tile 0 attr $00
    db $80
Anim_16_F02:   ; $58b4 1 sprites
    db $e4, $fa, $00, $00   ; dy -28 dx -6 tile 0 attr $00
    db $80
Anim_16_F03:   ; $58b9 1 sprites
    db $e1, $ff, $01, $00   ; dy -31 dx -1 tile 1 attr $00
    db $80
Anim_16_F04:   ; $58be 1 sprites
    db $dd, $f6, $01, $00   ; dy -35 dx -10 tile 1 attr $00
    db $80
Anim_16_F05:   ; $58c3 4 sprites
    db $d8, $f8, $02, $00   ; dy -40 dx -8 tile 2 attr $00
    db $d8, $00, $03, $00   ; dy -40 dx +0 tile 3 attr $00
    db $e0, $f8, $04, $00   ; dy -32 dx -8 tile 4 attr $00
    db $e0, $00, $05, $00   ; dy -32 dx +0 tile 5 attr $00
    db $80
Anim_16_F06:   ; $58d4 10 sprites
    db $d9, $f6, $06, $00   ; dy -39 dx -10 tile 6 attr $00
    db $d9, $02, $06, $20   ; dy -39 dx +2 tile 6 attr $20
    db $e1, $f6, $07, $00   ; dy -31 dx -10 tile 7 attr $00
    db $e1, $fe, $08, $00   ; dy -31 dx -2 tile 8 attr $00
    db $d6, $f8, $02, $00   ; dy -42 dx -8 tile 2 attr $00
    db $d6, $00, $03, $00   ; dy -42 dx +0 tile 3 attr $00
    db $de, $f8, $04, $00   ; dy -34 dx -8 tile 4 attr $00
    db $de, $00, $05, $00   ; dy -34 dx +0 tile 5 attr $00
    db $e1, $02, $07, $20   ; dy -31 dx +2 tile 7 attr $20
    db $e1, $fa, $08, $20   ; dy -31 dx -6 tile 8 attr $20
    db $80
Anim_16_F07:   ; $58fd 6 sprites
    db $d8, $f4, $06, $00   ; dy -40 dx -12 tile 6 attr $00
    db $d8, $04, $06, $20   ; dy -40 dx +4 tile 6 attr $20
    db $e0, $f4, $07, $00   ; dy -32 dx -12 tile 7 attr $00
    db $e0, $fc, $08, $00   ; dy -32 dx -4 tile 8 attr $00
    db $e0, $04, $07, $20   ; dy -32 dx +4 tile 7 attr $20
    db $e0, $fc, $08, $20   ; dy -32 dx -4 tile 8 attr $20
    db $80
Anim_16_F08:   ; $5916 13 sprites
    db $d2, $fc, $00, $00   ; dy -46 dx -4 tile 0 attr $00
    db $d8, $e8, $06, $00   ; dy -40 dx -24 tile 6 attr $00
    db $d8, $f2, $06, $00   ; dy -40 dx -14 tile 6 attr $00
    db $e0, $e8, $07, $00   ; dy -32 dx -24 tile 7 attr $00
    db $e0, $f0, $08, $00   ; dy -32 dx -16 tile 8 attr $00
    db $e0, $f2, $07, $00   ; dy -32 dx -14 tile 7 attr $00
    db $e0, $fa, $08, $00   ; dy -32 dx -6 tile 8 attr $00
    db $e0, $10, $07, $20   ; dy -32 dx +16 tile 7 attr $20
    db $e0, $08, $08, $20   ; dy -32 dx +8 tile 8 attr $20
    db $d8, $10, $06, $20   ; dy -40 dx +16 tile 6 attr $20
    db $e0, $fe, $08, $20   ; dy -32 dx -2 tile 8 attr $20
    db $d8, $06, $06, $20   ; dy -40 dx +6 tile 6 attr $20
    db $e0, $06, $07, $20   ; dy -32 dx +6 tile 7 attr $20
Anim_16_F09:   ; $594a empty frame = the $80 end above (shared)
    db $80
Anim_17_Surround:   ; $594b animation $17 — Surround, SandStorm
    dw Anim_17_F00
    dw Anim_17_F01
    dw Anim_17_F02
    dw Anim_17_F03
    dw Anim_17_F04
    dw Anim_17_F05
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
    dw Anim_17_F06
Anim_17_F00:   ; $598b 34 sprites
    db $f0, $e8, $0a, $60   ; dy -16 dx -24 tile 10 attr $60
    db $d8, $f0, $0a, $00   ; dy -40 dx -16 tile 10 attr $00
    db $d8, $f8, $10, $40   ; dy -40 dx -8 tile 16 attr $40
    db $d8, $e8, $05, $20   ; dy -40 dx -24 tile 5 attr $20
    db $d8, $e0, $0a, $60   ; dy -40 dx -32 tile 10 attr $60
    db $d8, $00, $11, $40   ; dy -40 dx +0 tile 17 attr $40
    db $d8, $d8, $0e, $00   ; dy -40 dx -40 tile 14 attr $00
    db $f0, $f0, $01, $00   ; dy -16 dx -16 tile 1 attr $00
    db $e8, $e8, $17, $60   ; dy -24 dx -24 tile 23 attr $60
    db $e8, $f0, $16, $00   ; dy -24 dx -16 tile 22 attr $00
    db $e0, $00, $16, $00   ; dy -32 dx +0 tile 22 attr $00
    db $e0, $08, $16, $60   ; dy -32 dx +8 tile 22 attr $60
    db $e0, $10, $0c, $40   ; dy -32 dx +16 tile 12 attr $40
    db $e0, $18, $0f, $00   ; dy -32 dx +24 tile 15 attr $00
    db $f8, $00, $17, $00   ; dy -8 dx +0 tile 23 attr $00
    db $f8, $f8, $0c, $20   ; dy -8 dx -8 tile 12 attr $20
    db $f0, $e0, $11, $20   ; dy -16 dx -32 tile 17 attr $20
    db $f8, $f0, $10, $40   ; dy -8 dx -16 tile 16 attr $40
    db $f8, $e8, $0f, $60   ; dy -8 dx -24 tile 15 attr $60
    db $e0, $f0, $00, $00   ; dy -32 dx -16 tile 0 attr $00
    db $e0, $f8, $00, $00   ; dy -32 dx -8 tile 0 attr $00
    db $d0, $f0, $10, $40   ; dy -48 dx -16 tile 16 attr $40
    db $d0, $e8, $0f, $60   ; dy -48 dx -24 tile 15 attr $60
    db $d0, $f8, $11, $40   ; dy -48 dx -8 tile 17 attr $40
    db $f0, $08, $05, $40   ; dy -16 dx +8 tile 5 attr $40
    db $f0, $10, $06, $40   ; dy -16 dx +16 tile 6 attr $40
    db $f0, $18, $07, $40   ; dy -16 dx +24 tile 7 attr $40
    db $e8, $00, $0c, $40   ; dy -24 dx +0 tile 12 attr $40
    db $f0, $00, $16, $60   ; dy -16 dx +0 tile 22 attr $60
    db $e8, $08, $0f, $00   ; dy -24 dx +8 tile 15 attr $00
    db $f0, $f8, $00, $00   ; dy -16 dx -8 tile 0 attr $00
    db $e8, $f8, $00, $00   ; dy -24 dx -8 tile 0 attr $00
    db $e0, $e0, $0a, $60   ; dy -32 dx -32 tile 10 attr $60
    db $e0, $e8, $00, $00   ; dy -32 dx -24 tile 0 attr $00
    db $80
Anim_17_F01:   ; $5a14 33 sprites
    db $f8, $00, $17, $00   ; dy -8 dx +0 tile 23 attr $00
    db $f8, $f0, $19, $20   ; dy -8 dx -16 tile 25 attr $20
    db $f8, $f8, $16, $00   ; dy -8 dx -8 tile 22 attr $00
    db $f0, $f0, $0a, $60   ; dy -16 dx -16 tile 10 attr $60
    db $f0, $f8, $01, $00   ; dy -16 dx -8 tile 1 attr $00
    db $f0, $e8, $0e, $00   ; dy -16 dx -24 tile 14 attr $00
    db $f0, $08, $16, $60   ; dy -16 dx +8 tile 22 attr $60
    db $f0, $00, $00, $00   ; dy -16 dx +0 tile 0 attr $00
    db $f0, $10, $0c, $40   ; dy -16 dx +16 tile 12 attr $40
    db $f0, $18, $0d, $40   ; dy -16 dx +24 tile 13 attr $40
    db $e8, $08, $07, $40   ; dy -24 dx +8 tile 7 attr $40
    db $e8, $e8, $19, $20   ; dy -24 dx -24 tile 25 attr $20
    db $e8, $f0, $15, $20   ; dy -24 dx -16 tile 21 attr $20
    db $e8, $00, $17, $00   ; dy -24 dx +0 tile 23 attr $00
    db $e8, $f8, $00, $00   ; dy -24 dx -8 tile 0 attr $00
    db $d8, $08, $11, $40   ; dy -40 dx +8 tile 17 attr $40
    db $e0, $08, $16, $60   ; dy -32 dx +8 tile 22 attr $60
    db $d8, $00, $0a, $00   ; dy -40 dx +0 tile 10 attr $00
    db $e0, $00, $00, $00   ; dy -32 dx +0 tile 0 attr $00
    db $d8, $f8, $16, $00   ; dy -40 dx -8 tile 22 attr $00
    db $e0, $f8, $09, $20   ; dy -32 dx -8 tile 9 attr $20
    db $d8, $f0, $18, $60   ; dy -40 dx -16 tile 24 attr $60
    db $e0, $10, $17, $00   ; dy -32 dx +16 tile 23 attr $00
    db $d8, $e4, $03, $00   ; dy -40 dx -28 tile 3 attr $00
    db $d8, $dc, $07, $20   ; dy -40 dx -36 tile 7 attr $20
    db $e0, $e8, $0f, $00   ; dy -32 dx -24 tile 15 attr $00
    db $d0, $f0, $0a, $00   ; dy -48 dx -16 tile 10 attr $00
    db $d0, $00, $07, $40   ; dy -48 dx +0 tile 7 attr $40
    db $d0, $f8, $18, $00   ; dy -48 dx -8 tile 24 attr $00
    db $d0, $e8, $17, $60   ; dy -48 dx -24 tile 23 attr $60
    db $e0, $18, $03, $00   ; dy -32 dx +24 tile 3 attr $00
    db $f0, $d8, $11, $20   ; dy -16 dx -40 tile 17 attr $20
    db $f0, $e0, $0e, $00   ; dy -16 dx -32 tile 14 attr $00
    db $80
Anim_17_F02:   ; $5a99 29 sprites
    db $e8, $e8, $0a, $60   ; dy -24 dx -24 tile 10 attr $60
    db $e8, $00, $05, $40   ; dy -24 dx +0 tile 5 attr $40
    db $e8, $08, $06, $40   ; dy -24 dx +8 tile 6 attr $40
    db $e8, $10, $07, $40   ; dy -24 dx +16 tile 7 attr $40
    db $d0, $00, $11, $40   ; dy -48 dx +0 tile 17 attr $40
    db $e8, $f0, $01, $00   ; dy -24 dx -16 tile 1 attr $00
    db $e8, $f8, $16, $60   ; dy -24 dx -8 tile 22 attr $60
    db $e0, $e8, $17, $60   ; dy -32 dx -24 tile 23 attr $60
    db $f0, $00, $17, $00   ; dy -16 dx +0 tile 23 attr $00
    db $f0, $f8, $0c, $20   ; dy -16 dx -8 tile 12 attr $20
    db $f8, $f8, $00, $00   ; dy -8 dx -8 tile 0 attr $00
    db $f8, $00, $01, $00   ; dy -8 dx +0 tile 1 attr $00
    db $f8, $f0, $13, $20   ; dy -8 dx -16 tile 19 attr $20
    db $f0, $f0, $0f, $60   ; dy -16 dx -16 tile 15 attr $60
    db $f8, $08, $14, $00   ; dy -8 dx +8 tile 20 attr $00
    db $d8, $00, $16, $60   ; dy -40 dx +0 tile 22 attr $60
    db $d8, $08, $0c, $40   ; dy -40 dx +8 tile 12 attr $40
    db $d8, $10, $0f, $00   ; dy -40 dx +16 tile 15 attr $00
    db $d0, $f8, $0a, $00   ; dy -48 dx -8 tile 10 attr $00
    db $d0, $e8, $0a, $60   ; dy -48 dx -24 tile 10 attr $60
    db $d0, $e0, $0e, $00   ; dy -48 dx -32 tile 14 attr $00
    db $d8, $f8, $00, $00   ; dy -40 dx -8 tile 0 attr $00
    db $d8, $e8, $07, $20   ; dy -40 dx -24 tile 7 attr $20
    db $e8, $d8, $11, $20   ; dy -24 dx -40 tile 17 attr $20
    db $e8, $e0, $0e, $00   ; dy -24 dx -32 tile 14 attr $00
    db $d8, $f0, $17, $60   ; dy -40 dx -16 tile 23 attr $60
    db $e0, $f0, $00, $00   ; dy -32 dx -16 tile 0 attr $00
    db $e0, $f8, $08, $00   ; dy -32 dx -8 tile 8 attr $00
    db $d0, $f0, $16, $00   ; dy -48 dx -16 tile 22 attr $00
    db $80
Anim_17_F03:   ; $5b0e 28 sprites
    db $e8, $f8, $16, $60   ; dy -24 dx -8 tile 22 attr $60
    db $f8, $f8, $00, $00   ; dy -8 dx -8 tile 0 attr $00
    db $f8, $f0, $17, $60   ; dy -8 dx -16 tile 23 attr $60
    db $f0, $f8, $19, $20   ; dy -16 dx -8 tile 25 attr $20
    db $f0, $f0, $03, $60   ; dy -16 dx -16 tile 3 attr $60
    db $f7, $e9, $0e, $00   ; dy -9 dx -23 tile 14 attr $00
    db $e8, $f0, $18, $60   ; dy -24 dx -16 tile 24 attr $60
    db $e0, $f8, $0a, $00   ; dy -32 dx -8 tile 10 attr $00
    db $e0, $f0, $06, $20   ; dy -32 dx -16 tile 6 attr $20
    db $e0, $e8, $07, $20   ; dy -32 dx -24 tile 7 attr $20
    db $e0, $00, $03, $40   ; dy -32 dx +0 tile 3 attr $40
    db $d8, $00, $01, $00   ; dy -40 dx +0 tile 1 attr $00
    db $d8, $f0, $03, $60   ; dy -40 dx -16 tile 3 attr $60
    db $d8, $f8, $02, $60   ; dy -40 dx -8 tile 2 attr $60
    db $d0, $00, $06, $40   ; dy -48 dx +0 tile 6 attr $40
    db $d0, $08, $07, $40   ; dy -48 dx +8 tile 7 attr $40
    db $d8, $08, $17, $00   ; dy -40 dx +8 tile 23 attr $00
    db $d0, $f8, $19, $20   ; dy -48 dx -8 tile 25 attr $20
    db $d0, $f0, $03, $60   ; dy -48 dx -16 tile 3 attr $60
    db $d0, $ec, $07, $00   ; dy -48 dx -20 tile 7 attr $00
    db $d0, $e4, $03, $20   ; dy -48 dx -28 tile 3 attr $20
    db $e8, $00, $14, $00   ; dy -24 dx +0 tile 20 attr $00
    db $f0, $00, $15, $40   ; dy -16 dx +0 tile 21 attr $40
    db $f8, $00, $06, $40   ; dy -8 dx +0 tile 6 attr $40
    db $e8, $e8, $07, $20   ; dy -24 dx -24 tile 7 attr $20
    db $e8, $e0, $07, $00   ; dy -24 dx -32 tile 7 attr $00
    db $e8, $d8, $03, $20   ; dy -24 dx -40 tile 3 attr $20
    db $e8, $08, $07, $60   ; dy -24 dx +8 tile 7 attr $60
    db $80
Anim_17_F04:   ; $5b7f 26 sprites
    db $f0, $08, $0a, $40   ; dy -16 dx +8 tile 10 attr $40
    db $f0, $00, $01, $20   ; dy -16 dx +0 tile 1 attr $20
    db $f0, $10, $11, $00   ; dy -16 dx +16 tile 17 attr $00
    db $e0, $00, $0a, $40   ; dy -32 dx +0 tile 10 attr $40
    db $e0, $08, $10, $00   ; dy -32 dx +8 tile 16 attr $00
    db $e8, $00, $17, $40   ; dy -24 dx +0 tile 23 attr $40
    db $d0, $00, $10, $60   ; dy -48 dx +0 tile 16 attr $60
    db $d0, $08, $19, $00   ; dy -48 dx +8 tile 25 attr $00
    db $f0, $f8, $06, $60   ; dy -16 dx -8 tile 6 attr $60
    db $f0, $f0, $07, $60   ; dy -16 dx -16 tile 7 attr $60
    db $e0, $f8, $16, $20   ; dy -32 dx -8 tile 22 attr $20
    db $f8, $f8, $17, $20   ; dy -8 dx -8 tile 23 attr $20
    db $f8, $00, $0c, $00   ; dy -8 dx +0 tile 12 attr $00
    db $f8, $08, $11, $40   ; dy -8 dx +8 tile 17 attr $40
    db $f8, $e8, $10, $40   ; dy -8 dx -24 tile 16 attr $40
    db $d8, $f8, $19, $20   ; dy -40 dx -8 tile 25 attr $20
    db $d8, $00, $15, $20   ; dy -40 dx +0 tile 21 attr $20
    db $d8, $08, $00, $00   ; dy -40 dx +8 tile 0 attr $00
    db $d8, $10, $12, $00   ; dy -40 dx +16 tile 18 attr $00
    db $e0, $f0, $0c, $60   ; dy -32 dx -16 tile 12 attr $60
    db $e0, $e8, $0f, $20   ; dy -32 dx -24 tile 15 attr $20
    db $e8, $f8, $19, $60   ; dy -24 dx -8 tile 25 attr $60
    db $f8, $e0, $03, $60   ; dy -8 dx -32 tile 3 attr $60
    db $f8, $f0, $07, $40   ; dy -8 dx -16 tile 7 attr $40
    db $f0, $e0, $07, $60   ; dy -16 dx -32 tile 7 attr $60
    db $f0, $e8, $03, $40   ; dy -16 dx -24 tile 3 attr $40
    db $80
Anim_17_F05:   ; $5be8 29 sprites
    db $e0, $f8, $16, $00   ; dy -32 dx -8 tile 22 attr $00
    db $f8, $00, $08, $00   ; dy -8 dx +0 tile 8 attr $00
    db $f8, $f0, $0e, $60   ; dy -8 dx -16 tile 14 attr $60
    db $f8, $f8, $02, $60   ; dy -8 dx -8 tile 2 attr $60
    db $f8, $e8, $03, $60   ; dy -8 dx -24 tile 3 attr $60
    db $f0, $08, $17, $40   ; dy -16 dx +8 tile 23 attr $40
    db $f0, $00, $16, $40   ; dy -16 dx +0 tile 22 attr $40
    db $e8, $f8, $02, $00   ; dy -24 dx -8 tile 2 attr $00
    db $e8, $00, $03, $00   ; dy -24 dx +0 tile 3 attr $00
    db $f0, $f8, $00, $00   ; dy -16 dx -8 tile 0 attr $00
    db $f0, $f0, $06, $20   ; dy -16 dx -16 tile 6 attr $20
    db $f0, $e8, $07, $20   ; dy -16 dx -24 tile 7 attr $20
    db $e8, $f0, $09, $20   ; dy -24 dx -16 tile 9 attr $20
    db $e0, $00, $05, $40   ; dy -32 dx +0 tile 5 attr $40
    db $e0, $10, $03, $00   ; dy -32 dx +16 tile 3 attr $00
    db $e0, $08, $02, $00   ; dy -32 dx +8 tile 2 attr $00
    db $e0, $e8, $10, $20   ; dy -32 dx -24 tile 16 attr $20
    db $e0, $f0, $06, $20   ; dy -32 dx -16 tile 6 attr $20
    db $e0, $e0, $07, $20   ; dy -32 dx -32 tile 7 attr $20
    db $d8, $f8, $00, $00   ; dy -40 dx -8 tile 0 attr $00
    db $d8, $00, $17, $00   ; dy -40 dx +0 tile 23 attr $00
    db $d8, $08, $03, $00   ; dy -40 dx +8 tile 3 attr $00
    db $d8, $e8, $06, $20   ; dy -40 dx -24 tile 6 attr $20
    db $d8, $e0, $07, $20   ; dy -40 dx -32 tile 7 attr $20
    db $d8, $f0, $16, $00   ; dy -40 dx -16 tile 22 attr $00
    db $d0, $08, $07, $40   ; dy -48 dx +8 tile 7 attr $40
    db $d0, $f8, $10, $60   ; dy -48 dx -8 tile 16 attr $60
    db $d0, $00, $10, $60   ; dy -48 dx +0 tile 16 attr $60
    db $d0, $f0, $03, $60   ; dy -48 dx -16 tile 3 attr $60
Anim_17_F06:   ; $5c5c empty frame = the $80 end above (shared)
    db $80
Anim_18_Transform:   ; $5c5d animation $18 — Transform, CHGDRAGON, BeDragon
    dw Anim_18_F00
    dw Anim_18_F01
    dw Anim_18_F02
    dw Anim_18_F03
    dw Anim_18_F04
    dw Anim_18_F05
    dw Anim_18_F06
    dw Anim_18_F07
    dw Anim_18_F08
    dw Anim_18_F08
    dw Anim_18_F08
    dw Anim_18_F08
    dw Anim_18_F08
    dw Anim_18_F08
    dw Anim_18_F08
    dw Anim_18_F08
    dw Anim_18_F08
    dw Anim_18_F08
    dw Anim_18_F08
    dw Anim_18_F08
    dw Anim_18_F08
    dw Anim_18_F08
    dw Anim_18_F08
    dw Anim_18_F08
    dw Anim_18_F08
    dw Anim_18_F08
    dw Anim_18_F08
    dw Anim_18_F08
    dw Anim_18_F08
    dw Anim_18_F08
    dw Anim_18_F08
    dw Anim_18_F08
Anim_18_F00:   ; $5c9d 4 sprites
    db $e8, $f8, $00, $00   ; dy -24 dx -8 tile 0 attr $00
    db $e8, $00, $01, $00   ; dy -24 dx +0 tile 1 attr $00
    db $f0, $f8, $02, $00   ; dy -16 dx -8 tile 2 attr $00
    db $f0, $00, $03, $00   ; dy -16 dx +0 tile 3 attr $00
    db $80
Anim_18_F01:   ; $5cae 9 sprites
    db $e2, $f3, $00, $00   ; dy -30 dx -13 tile 0 attr $00
    db $e2, $fb, $04, $00   ; dy -30 dx -5 tile 4 attr $00
    db $e2, $03, $01, $00   ; dy -30 dx +3 tile 1 attr $00
    db $ea, $f3, $06, $00   ; dy -22 dx -13 tile 6 attr $00
    db $ea, $fb, $07, $00   ; dy -22 dx -5 tile 7 attr $00
    db $ea, $03, $14, $00   ; dy -22 dx +3 tile 20 attr $00
    db $f2, $f3, $0a, $00   ; dy -14 dx -13 tile 10 attr $00
    db $f2, $fb, $0b, $00   ; dy -14 dx -5 tile 11 attr $00
    db $f2, $03, $0c, $00   ; dy -14 dx +3 tile 12 attr $00
    db $80
Anim_18_F02:   ; $5cd3 12 sprites
    db $e2, $f0, $0d, $00   ; dy -30 dx -16 tile 13 attr $00
    db $e2, $f8, $0e, $00   ; dy -30 dx -8 tile 14 attr $00
    db $e2, $00, $0f, $00   ; dy -30 dx +0 tile 15 attr $00
    db $e2, $08, $10, $00   ; dy -30 dx +8 tile 16 attr $00
    db $ea, $f0, $11, $00   ; dy -22 dx -16 tile 17 attr $00
    db $ea, $f8, $12, $00   ; dy -22 dx -8 tile 18 attr $00
    db $ea, $00, $13, $00   ; dy -22 dx +0 tile 19 attr $00
    db $ea, $08, $14, $00   ; dy -22 dx +8 tile 20 attr $00
    db $f2, $f0, $15, $00   ; dy -14 dx -16 tile 21 attr $00
    db $f2, $f8, $16, $00   ; dy -14 dx -8 tile 22 attr $00
    db $f2, $00, $17, $00   ; dy -14 dx +0 tile 23 attr $00
    db $f2, $08, $18, $00   ; dy -14 dx +8 tile 24 attr $00
    db $80
Anim_18_F03:   ; $5d04 26 sprites
    db $d4, $ec, $0d, $00   ; dy -44 dx -20 tile 13 attr $00
    db $d4, $f4, $0e, $00   ; dy -44 dx -12 tile 14 attr $00
    db $d4, $fc, $0f, $00   ; dy -44 dx -4 tile 15 attr $00
    db $d4, $04, $0e, $00   ; dy -44 dx +4 tile 14 attr $00
    db $d4, $0c, $10, $00   ; dy -44 dx +12 tile 16 attr $00
    db $dc, $ec, $11, $00   ; dy -36 dx -20 tile 17 attr $00
    db $dc, $f4, $12, $00   ; dy -36 dx -12 tile 18 attr $00
    db $dc, $fc, $13, $00   ; dy -36 dx -4 tile 19 attr $00
    db $dc, $04, $12, $00   ; dy -36 dx +4 tile 18 attr $00
    db $dc, $0c, $1a, $00   ; dy -36 dx +12 tile 26 attr $00
    db $e4, $ec, $1b, $00   ; dy -28 dx -20 tile 27 attr $00
    db $e4, $f4, $1c, $00   ; dy -28 dx -12 tile 28 attr $00
    db $e4, $fc, $1d, $00   ; dy -28 dx -4 tile 29 attr $00
    db $e4, $04, $1d, $00   ; dy -28 dx +4 tile 29 attr $00
    db $e4, $0c, $1e, $00   ; dy -28 dx +12 tile 30 attr $00
    db $e2, $14, $09, $00   ; dy -30 dx +20 tile 9 attr $00
    db $ec, $ec, $1f, $00   ; dy -20 dx -20 tile 31 attr $00
    db $ec, $f4, $20, $00   ; dy -20 dx -12 tile 32 attr $00
    db $ec, $fc, $13, $00   ; dy -20 dx -4 tile 19 attr $00
    db $ec, $04, $12, $00   ; dy -20 dx +4 tile 18 attr $00
    db $ec, $0c, $21, $00   ; dy -20 dx +12 tile 33 attr $00
    db $f4, $ec, $15, $00   ; dy -12 dx -20 tile 21 attr $00
    db $f4, $f4, $16, $00   ; dy -12 dx -12 tile 22 attr $00
    db $f4, $fc, $17, $00   ; dy -12 dx -4 tile 23 attr $00
    db $f4, $04, $22, $00   ; dy -12 dx +4 tile 34 attr $00
    db $f4, $0c, $23, $00   ; dy -12 dx +12 tile 35 attr $00
    db $80
Anim_18_F04:   ; $5d6d 33 sprites
    db $d0, $e8, $0d, $00   ; dy -48 dx -24 tile 13 attr $00
    db $d0, $f0, $0e, $00   ; dy -48 dx -16 tile 14 attr $00
    db $d0, $f8, $01, $00   ; dy -48 dx -8 tile 1 attr $00
    db $d0, $10, $01, $00   ; dy -48 dx +16 tile 1 attr $00
    db $e8, $10, $01, $00   ; dy -24 dx +16 tile 1 attr $00
    db $d0, $00, $00, $00   ; dy -48 dx +0 tile 0 attr $00
    db $e8, $08, $00, $00   ; dy -24 dx +8 tile 0 attr $00
    db $f0, $08, $02, $00   ; dy -16 dx +8 tile 2 attr $00
    db $f0, $10, $03, $00   ; dy -16 dx +16 tile 3 attr $00
    db $d8, $f8, $23, $00   ; dy -40 dx -8 tile 35 attr $00
    db $d0, $08, $04, $00   ; dy -48 dx +8 tile 4 attr $00
    db $d8, $00, $06, $00   ; dy -40 dx +0 tile 6 attr $00
    db $d8, $08, $07, $00   ; dy -40 dx +8 tile 7 attr $00
    db $d8, $f0, $07, $00   ; dy -40 dx -16 tile 7 attr $00
    db $d8, $e8, $11, $00   ; dy -40 dx -24 tile 17 attr $00
    db $f0, $e8, $11, $00   ; dy -16 dx -24 tile 17 attr $00
    db $f0, $f0, $12, $00   ; dy -16 dx -16 tile 18 attr $00
    db $f0, $f8, $13, $00   ; dy -16 dx -8 tile 19 attr $00
    db $f0, $00, $14, $00   ; dy -16 dx +0 tile 20 attr $00
    db $f8, $e8, $15, $00   ; dy -8 dx -24 tile 21 attr $00
    db $f8, $f0, $16, $00   ; dy -8 dx -16 tile 22 attr $00
    db $f8, $f8, $17, $00   ; dy -8 dx -8 tile 23 attr $00
    db $f8, $00, $18, $00   ; dy -8 dx +0 tile 24 attr $00
    db $e8, $e8, $0d, $00   ; dy -24 dx -24 tile 13 attr $00
    db $e8, $f0, $0e, $00   ; dy -24 dx -16 tile 14 attr $00
    db $e8, $f8, $0f, $00   ; dy -24 dx -8 tile 15 attr $00
    db $e8, $00, $10, $00   ; dy -24 dx +0 tile 16 attr $00
    db $d8, $10, $14, $00   ; dy -40 dx +16 tile 20 attr $00
    db $e0, $00, $0a, $00   ; dy -32 dx +0 tile 10 attr $00
    db $e0, $08, $0b, $00   ; dy -32 dx +8 tile 11 attr $00
    db $e0, $10, $0c, $00   ; dy -32 dx +16 tile 12 attr $00
    db $e0, $e8, $15, $00   ; dy -32 dx -24 tile 21 attr $00
    db $e0, $f0, $18, $00   ; dy -32 dx -16 tile 24 attr $00
    db $80
Anim_18_F05:   ; $5df2 25 sprites
    db $d0, $e8, $00, $00   ; dy -48 dx -24 tile 0 attr $00
    db $d0, $f0, $01, $00   ; dy -48 dx -16 tile 1 attr $00
    db $f0, $08, $00, $00   ; dy -16 dx +8 tile 0 attr $00
    db $f0, $10, $01, $00   ; dy -16 dx +16 tile 1 attr $00
    db $ea, $e8, $00, $00   ; dy -22 dx -24 tile 0 attr $00
    db $ea, $f8, $01, $00   ; dy -22 dx -8 tile 1 attr $00
    db $f8, $08, $02, $00   ; dy -8 dx +8 tile 2 attr $00
    db $f8, $10, $03, $00   ; dy -8 dx +16 tile 3 attr $00
    db $d8, $f0, $03, $00   ; dy -40 dx -16 tile 3 attr $00
    db $ea, $f0, $04, $00   ; dy -22 dx -16 tile 4 attr $00
    db $d0, $08, $04, $00   ; dy -48 dx +8 tile 4 attr $00
    db $d0, $10, $01, $00   ; dy -48 dx +16 tile 1 attr $00
    db $d8, $00, $0a, $00   ; dy -40 dx +0 tile 10 attr $00
    db $fa, $e8, $0a, $00   ; dy -6 dx -24 tile 10 attr $00
    db $d8, $08, $0b, $00   ; dy -40 dx +8 tile 11 attr $00
    db $d8, $10, $0c, $00   ; dy -40 dx +16 tile 12 attr $00
    db $fa, $f0, $0b, $00   ; dy -6 dx -16 tile 11 attr $00
    db $fa, $f8, $0c, $00   ; dy -6 dx -8 tile 12 attr $00
    db $d8, $e8, $11, $00   ; dy -40 dx -24 tile 17 attr $00
    db $e0, $e8, $0a, $00   ; dy -32 dx -24 tile 10 attr $00
    db $e0, $f0, $0a, $20   ; dy -32 dx -16 tile 10 attr $20
    db $d0, $00, $0a, $40   ; dy -48 dx +0 tile 10 attr $40
    db $f2, $e8, $06, $00   ; dy -14 dx -24 tile 6 attr $00
    db $f2, $f0, $07, $00   ; dy -14 dx -16 tile 7 attr $00
    db $f2, $f8, $14, $00   ; dy -14 dx -8 tile 20 attr $00
    db $80
Anim_18_F06:   ; $5e57 24 sprites
    db $e8, $f8, $00, $00   ; dy -24 dx -8 tile 0 attr $00
    db $e8, $00, $01, $00   ; dy -24 dx +0 tile 1 attr $00
    db $cc, $07, $00, $00   ; dy -52 dx +7 tile 0 attr $00
    db $cc, $0f, $01, $00   ; dy -52 dx +15 tile 1 attr $00
    db $cd, $e7, $00, $00   ; dy -51 dx -25 tile 0 attr $00
    db $cd, $ef, $01, $00   ; dy -51 dx -17 tile 1 attr $00
    db $f0, $e8, $00, $00   ; dy -16 dx -24 tile 0 attr $00
    db $f0, $f0, $00, $20   ; dy -16 dx -16 tile 0 attr $20
    db $fb, $11, $00, $60   ; dy -5 dx +17 tile 0 attr $60
    db $e0, $10, $00, $20   ; dy -32 dx +16 tile 0 attr $20
    db $d4, $07, $02, $00   ; dy -44 dx +7 tile 2 attr $00
    db $d4, $0f, $03, $00   ; dy -44 dx +15 tile 3 attr $00
    db $f0, $f8, $02, $00   ; dy -16 dx -8 tile 2 attr $00
    db $f0, $00, $03, $00   ; dy -16 dx +0 tile 3 attr $00
    db $f8, $e8, $03, $20   ; dy -8 dx -24 tile 3 attr $20
    db $f3, $11, $01, $00   ; dy -13 dx +17 tile 1 attr $00
    db $e7, $0f, $0c, $00   ; dy -25 dx +15 tile 12 attr $00
    db $d5, $e7, $0c, $20   ; dy -43 dx -25 tile 12 attr $20
    db $d5, $ef, $00, $60   ; dy -43 dx -17 tile 0 attr $60
    db $fb, $09, $0a, $00   ; dy -5 dx +9 tile 10 attr $00
    db $e8, $08, $0a, $00   ; dy -24 dx +8 tile 10 attr $00
    db $f4, $09, $0a, $40   ; dy -12 dx +9 tile 10 attr $40
    db $e0, $08, $0a, $40   ; dy -32 dx +8 tile 10 attr $40
    db $f8, $f0, $11, $20   ; dy -8 dx -16 tile 17 attr $20
    db $80
Anim_18_F07:   ; $5eb8 4 sprites
    db $eb, $fb, $00, $00   ; dy -21 dx -5 tile 0 attr $00
    db $eb, $03, $01, $00   ; dy -21 dx +3 tile 1 attr $00
    db $f3, $03, $00, $60   ; dy -13 dx +3 tile 0 attr $60
    db $f3, $fb, $0c, $20   ; dy -13 dx -5 tile 12 attr $20
Anim_18_F08:   ; $5ec8 empty frame = the $80 end above (shared)
    db $80
Anim_19_MagicBack:   ; $5ec9 animation $19 — MagicBack, Bounce
    dw Anim_19_F00
    dw Anim_19_F01
    dw Anim_19_F01
    dw Anim_19_F01
    dw Anim_19_F01
    dw Anim_19_F01
    dw Anim_19_F01
    dw Anim_19_F07
    dw Anim_19_F08
    dw Anim_19_F08
    dw Anim_19_F08
    dw Anim_19_F08
    dw Anim_19_F08
    dw Anim_19_F08
    dw Anim_19_F08
    dw Anim_19_F08
    dw Anim_19_F08
    dw Anim_19_F08
    dw Anim_19_F08
    dw Anim_19_F08
    dw Anim_19_F08
    dw Anim_19_F08
    dw Anim_19_F08
    dw Anim_19_F08
    dw Anim_19_F08
    dw Anim_19_F08
    dw Anim_19_F08
    dw Anim_19_F08
    dw Anim_19_F08
    dw Anim_19_F08
    dw Anim_19_F08
    dw Anim_19_F08
Anim_19_F00:   ; $5f09 36 sprites
    db $d0, $e8, $00, $00   ; dy -48 dx -24 tile 0 attr $00
    db $d0, $f0, $01, $00   ; dy -48 dx -16 tile 1 attr $00
    db $d0, $f8, $02, $00   ; dy -48 dx -8 tile 2 attr $00
    db $d0, $00, $03, $00   ; dy -48 dx +0 tile 3 attr $00
    db $d0, $08, $04, $00   ; dy -48 dx +8 tile 4 attr $00
    db $d0, $10, $05, $00   ; dy -48 dx +16 tile 5 attr $00
    db $d8, $e8, $06, $00   ; dy -40 dx -24 tile 6 attr $00
    db $d8, $f0, $07, $00   ; dy -40 dx -16 tile 7 attr $00
    db $d8, $f8, $08, $00   ; dy -40 dx -8 tile 8 attr $00
    db $d8, $00, $09, $00   ; dy -40 dx +0 tile 9 attr $00
    db $d8, $08, $0a, $00   ; dy -40 dx +8 tile 10 attr $00
    db $d8, $10, $0b, $00   ; dy -40 dx +16 tile 11 attr $00
    db $e0, $e8, $01, $00   ; dy -32 dx -24 tile 1 attr $00
    db $e0, $f0, $02, $00   ; dy -32 dx -16 tile 2 attr $00
    db $e0, $f8, $03, $00   ; dy -32 dx -8 tile 3 attr $00
    db $e0, $00, $0c, $00   ; dy -32 dx +0 tile 12 attr $00
    db $e0, $08, $05, $00   ; dy -32 dx +8 tile 5 attr $00
    db $e0, $10, $00, $00   ; dy -32 dx +16 tile 0 attr $00
    db $e8, $10, $00, $00   ; dy -24 dx +16 tile 0 attr $00
    db $f0, $10, $00, $00   ; dy -16 dx +16 tile 0 attr $00
    db $f8, $10, $00, $00   ; dy -8 dx +16 tile 0 attr $00
    db $f8, $08, $00, $00   ; dy -8 dx +8 tile 0 attr $00
    db $f0, $08, $00, $00   ; dy -16 dx +8 tile 0 attr $00
    db $f8, $f8, $00, $00   ; dy -8 dx -8 tile 0 attr $00
    db $e8, $e8, $07, $00   ; dy -24 dx -24 tile 7 attr $00
    db $e8, $f0, $08, $00   ; dy -24 dx -16 tile 8 attr $00
    db $e8, $f8, $0d, $00   ; dy -24 dx -8 tile 13 attr $00
    db $e8, $00, $00, $00   ; dy -24 dx +0 tile 0 attr $00
    db $e8, $08, $0b, $00   ; dy -24 dx +8 tile 11 attr $00
    db $f0, $e8, $02, $00   ; dy -16 dx -24 tile 2 attr $00
    db $f0, $f0, $0e, $00   ; dy -16 dx -16 tile 14 attr $00
    db $f0, $f8, $0f, $00   ; dy -16 dx -8 tile 15 attr $00
    db $f0, $00, $10, $00   ; dy -16 dx +0 tile 16 attr $00
    db $f8, $f0, $11, $00   ; dy -8 dx -16 tile 17 attr $00
    db $f8, $e8, $0b, $00   ; dy -8 dx -24 tile 11 attr $00
    db $f8, $00, $0b, $00   ; dy -8 dx +0 tile 11 attr $00
    db $80
Anim_19_F01:   ; $5f9a 36 sprites
    db $d0, $e8, $50, $00   ; dy -48 dx -24 tile 80 attr $00
    db $d0, $f0, $51, $00   ; dy -48 dx -16 tile 81 attr $00
    db $d0, $f8, $52, $00   ; dy -48 dx -8 tile 82 attr $00
    db $d0, $00, $53, $00   ; dy -48 dx +0 tile 83 attr $00
    db $d0, $08, $54, $00   ; dy -48 dx +8 tile 84 attr $00
    db $d0, $10, $55, $00   ; dy -48 dx +16 tile 85 attr $00
    db $d8, $e8, $60, $00   ; dy -40 dx -24 tile 96 attr $00
    db $d8, $f0, $61, $00   ; dy -40 dx -16 tile 97 attr $00
    db $d8, $f8, $62, $00   ; dy -40 dx -8 tile 98 attr $00
    db $d8, $00, $63, $00   ; dy -40 dx +0 tile 99 attr $00
    db $d8, $08, $64, $00   ; dy -40 dx +8 tile 100 attr $00
    db $d8, $10, $65, $00   ; dy -40 dx +16 tile 101 attr $00
    db $e0, $e8, $70, $00   ; dy -32 dx -24 tile 112 attr $00
    db $e0, $f0, $71, $00   ; dy -32 dx -16 tile 113 attr $00
    db $e0, $f8, $72, $00   ; dy -32 dx -8 tile 114 attr $00
    db $e0, $00, $73, $00   ; dy -32 dx +0 tile 115 attr $00
    db $e0, $08, $74, $00   ; dy -32 dx +8 tile 116 attr $00
    db $e0, $10, $75, $00   ; dy -32 dx +16 tile 117 attr $00
    db $e8, $e8, $80, $00   ; dy -24 dx -24 tile 128 attr $00
    db $e8, $f0, $81, $00   ; dy -24 dx -16 tile 129 attr $00
    db $e8, $f8, $82, $00   ; dy -24 dx -8 tile 130 attr $00
    db $e8, $00, $83, $00   ; dy -24 dx +0 tile 131 attr $00
    db $e8, $08, $84, $00   ; dy -24 dx +8 tile 132 attr $00
    db $e8, $10, $85, $00   ; dy -24 dx +16 tile 133 attr $00
    db $f0, $e8, $90, $00   ; dy -16 dx -24 tile 144 attr $00
    db $f0, $f0, $91, $00   ; dy -16 dx -16 tile 145 attr $00
    db $f0, $f8, $92, $00   ; dy -16 dx -8 tile 146 attr $00
    db $f0, $00, $93, $00   ; dy -16 dx +0 tile 147 attr $00
    db $f0, $08, $94, $00   ; dy -16 dx +8 tile 148 attr $00
    db $f0, $10, $95, $00   ; dy -16 dx +16 tile 149 attr $00
    db $f8, $e8, $a0, $00   ; dy -8 dx -24 tile 160 attr $00
    db $f8, $f0, $a1, $00   ; dy -8 dx -16 tile 161 attr $00
    db $f8, $f8, $a2, $00   ; dy -8 dx -8 tile 162 attr $00
    db $f8, $00, $a3, $00   ; dy -8 dx +0 tile 163 attr $00
    db $f8, $08, $a4, $00   ; dy -8 dx +8 tile 164 attr $00
    db $f8, $10, $a5, $00   ; dy -8 dx +16 tile 165 attr $00
    db $80
Anim_19_F07:   ; $602b 36 sprites
    db $d8, $e8, $50, $00   ; dy -40 dx -24 tile 80 attr $00
    db $d8, $f0, $51, $00   ; dy -40 dx -16 tile 81 attr $00
    db $d8, $f8, $52, $00   ; dy -40 dx -8 tile 82 attr $00
    db $d8, $00, $53, $00   ; dy -40 dx +0 tile 83 attr $00
    db $d8, $08, $54, $00   ; dy -40 dx +8 tile 84 attr $00
    db $d8, $10, $55, $00   ; dy -40 dx +16 tile 85 attr $00
    db $e0, $e8, $60, $00   ; dy -32 dx -24 tile 96 attr $00
    db $e0, $f0, $61, $00   ; dy -32 dx -16 tile 97 attr $00
    db $e0, $f8, $62, $00   ; dy -32 dx -8 tile 98 attr $00
    db $e0, $00, $63, $00   ; dy -32 dx +0 tile 99 attr $00
    db $e0, $08, $64, $00   ; dy -32 dx +8 tile 100 attr $00
    db $e0, $10, $65, $00   ; dy -32 dx +16 tile 101 attr $00
    db $e8, $e8, $70, $00   ; dy -24 dx -24 tile 112 attr $00
    db $e8, $f0, $71, $00   ; dy -24 dx -16 tile 113 attr $00
    db $e8, $f8, $72, $00   ; dy -24 dx -8 tile 114 attr $00
    db $e8, $00, $73, $00   ; dy -24 dx +0 tile 115 attr $00
    db $e8, $08, $74, $00   ; dy -24 dx +8 tile 116 attr $00
    db $e8, $10, $75, $00   ; dy -24 dx +16 tile 117 attr $00
    db $f0, $e8, $80, $00   ; dy -16 dx -24 tile 128 attr $00
    db $f0, $f0, $81, $00   ; dy -16 dx -16 tile 129 attr $00
    db $f0, $f8, $82, $00   ; dy -16 dx -8 tile 130 attr $00
    db $f0, $00, $83, $00   ; dy -16 dx +0 tile 131 attr $00
    db $f0, $08, $84, $00   ; dy -16 dx +8 tile 132 attr $00
    db $f0, $10, $85, $00   ; dy -16 dx +16 tile 133 attr $00
    db $f8, $e8, $90, $00   ; dy -8 dx -24 tile 144 attr $00
    db $f8, $f0, $91, $00   ; dy -8 dx -16 tile 145 attr $00
    db $f8, $f8, $92, $00   ; dy -8 dx -8 tile 146 attr $00
    db $f8, $00, $93, $00   ; dy -8 dx +0 tile 147 attr $00
    db $f8, $08, $94, $00   ; dy -8 dx +8 tile 148 attr $00
    db $f8, $10, $95, $00   ; dy -8 dx +16 tile 149 attr $00
    db $d0, $e8, $88, $00   ; dy -48 dx -24 tile 136 attr $00
    db $d0, $f0, $88, $00   ; dy -48 dx -16 tile 136 attr $00
    db $d0, $f8, $88, $00   ; dy -48 dx -8 tile 136 attr $00
    db $d0, $00, $88, $00   ; dy -48 dx +0 tile 136 attr $00
    db $d0, $08, $88, $00   ; dy -48 dx +8 tile 136 attr $00
    db $d0, $10, $88, $00   ; dy -48 dx +16 tile 136 attr $00
Anim_19_F08:   ; $60bb empty frame = the $80 end above (shared)
    db $80
Anim_1a_WhiteAir:   ; $60bc animation $1a — WhiteAir
    dw Anim_1a_F00
    dw Anim_1a_F01
    dw Anim_1a_F02
    dw Anim_1a_F03
    dw Anim_1a_F04
    dw Anim_1a_F05
    dw Anim_1a_F06
    dw Anim_1a_F07
    dw Anim_1a_F08
    dw Anim_1a_F09
    dw Anim_1a_F10
    dw Anim_1a_F11
    dw Anim_1a_F12
    dw Anim_1a_F13
    dw Anim_1a_F14
    dw Anim_1a_F15
    dw Anim_1a_F16
    dw Anim_1a_F17
    dw Anim_1a_F18
    dw Anim_1a_F19
    dw Anim_1a_F19
    dw Anim_1a_F19
    dw Anim_1a_F19
    dw Anim_1a_F19
    dw Anim_1a_F19
    dw Anim_1a_F19
    dw Anim_1a_F19
    dw Anim_1a_F19
    dw Anim_1a_F19
    dw Anim_1a_F19
    dw Anim_1a_F19
    dw Anim_1a_F19
Anim_1a_F00:   ; $60fc 2 sprites
    db $d0, $01, $2e, $00   ; dy -48 dx +1 tile 46 attr $00
    db $d8, $01, $2e, $60   ; dy -40 dx +1 tile 46 attr $60
    db $80
Anim_1a_F01:   ; $6105 6 sprites
    db $e0, $fc, $2e, $00   ; dy -32 dx -4 tile 46 attr $00
    db $e8, $fc, $2e, $60   ; dy -24 dx -4 tile 46 attr $60
    db $f0, $f7, $2e, $00   ; dy -16 dx -9 tile 46 attr $00
    db $f8, $f7, $2e, $60   ; dy -8 dx -9 tile 46 attr $60
    db $d0, $01, $2e, $00   ; dy -48 dx +1 tile 46 attr $00
    db $d8, $01, $2e, $60   ; dy -40 dx +1 tile 46 attr $60
    db $80
Anim_1a_F02:   ; $611e 4 sprites
    db $f0, $f7, $2e, $00   ; dy -16 dx -9 tile 46 attr $00
    db $f8, $f7, $2e, $60   ; dy -8 dx -9 tile 46 attr $60
    db $e8, $fc, $2f, $60   ; dy -24 dx -4 tile 47 attr $60
    db $e0, $fc, $2f, $00   ; dy -32 dx -4 tile 47 attr $00
    db $80
Anim_1a_F03:   ; $612f 17 sprites
    db $d0, $d8, $00, $00   ; dy -48 dx -40 tile 0 attr $00
    db $d4, $ec, $02, $00   ; dy -44 dx -20 tile 2 attr $00
    db $d0, $f8, $04, $00   ; dy -48 dx -8 tile 4 attr $00
    db $e0, $d8, $02, $00   ; dy -32 dx -40 tile 2 attr $00
    db $d0, $08, $00, $00   ; dy -48 dx +8 tile 0 attr $00
    db $d4, $1c, $02, $60   ; dy -44 dx +28 tile 2 attr $60
    db $d0, $28, $04, $40   ; dy -48 dx +40 tile 4 attr $40
    db $d0, $b8, $00, $00   ; dy -48 dx -72 tile 0 attr $00
    db $d0, $38, $02, $00   ; dy -48 dx +56 tile 2 attr $00
    db $dc, $f4, $01, $00   ; dy -36 dx -12 tile 1 attr $00
    db $e0, $32, $00, $00   ; dy -32 dx +50 tile 0 attr $00
    db $d4, $c9, $02, $60   ; dy -44 dx -55 tile 2 attr $60
    db $d8, $07, $02, $00   ; dy -40 dx +7 tile 2 attr $00
    db $e0, $06, $00, $00   ; dy -32 dx +6 tile 0 attr $00
    db $dc, $c8, $01, $00   ; dy -36 dx -56 tile 1 attr $00
    db $d8, $27, $00, $00   ; dy -40 dx +39 tile 0 attr $00
    db $d0, $14, $03, $00   ; dy -48 dx +20 tile 3 attr $00
    db $80
Anim_1a_F04:   ; $6174 21 sprites
    db $e0, $d8, $02, $00   ; dy -32 dx -40 tile 2 attr $00
    db $e4, $e9, $02, $00   ; dy -28 dx -23 tile 2 attr $00
    db $ec, $f1, $01, $00   ; dy -20 dx -15 tile 1 attr $00
    db $f0, $04, $02, $00   ; dy -16 dx +4 tile 2 attr $00
    db $e0, $06, $01, $00   ; dy -32 dx +6 tile 1 attr $00
    db $e8, $05, $01, $00   ; dy -24 dx +5 tile 1 attr $00
    db $e4, $c7, $02, $60   ; dy -28 dx -57 tile 2 attr $60
    db $ec, $c6, $01, $00   ; dy -20 dx -58 tile 1 attr $00
    db $e0, $b6, $00, $00   ; dy -32 dx -74 tile 0 attr $00
    db $d8, $d7, $00, $00   ; dy -40 dx -41 tile 0 attr $00
    db $e0, $36, $02, $00   ; dy -32 dx +54 tile 2 attr $00
    db $f0, $30, $00, $20   ; dy -16 dx +48 tile 0 attr $20
    db $e0, $12, $03, $40   ; dy -32 dx +18 tile 3 attr $40
    db $e0, $26, $03, $00   ; dy -32 dx +38 tile 3 attr $00
    db $e8, $25, $02, $00   ; dy -24 dx +37 tile 2 attr $00
    db $e4, $1a, $01, $60   ; dy -28 dx +26 tile 1 attr $60
    db $e0, $f5, $04, $20   ; dy -32 dx -11 tile 4 attr $20
    db $d0, $e8, $0c, $00   ; dy -48 dx -24 tile 12 attr $00
    db $d8, $24, $11, $00   ; dy -40 dx +36 tile 17 attr $00
    db $d0, $28, $10, $00   ; dy -48 dx +40 tile 16 attr $00
    db $d0, $20, $0f, $00   ; dy -48 dx +32 tile 15 attr $00
    db $80
Anim_1a_F05:   ; $61c9 20 sprites
    db $e8, $1c, $02, $60   ; dy -24 dx +28 tile 2 attr $60
    db $e4, $0b, $02, $60   ; dy -28 dx +11 tile 2 attr $60
    db $dc, $03, $01, $60   ; dy -36 dx +3 tile 1 attr $60
    db $d8, $f0, $02, $60   ; dy -40 dx -16 tile 2 attr $60
    db $e8, $ee, $01, $60   ; dy -24 dx -18 tile 1 attr $60
    db $e0, $ef, $01, $60   ; dy -32 dx -17 tile 1 attr $60
    db $e4, $2d, $02, $00   ; dy -28 dx +45 tile 2 attr $00
    db $dc, $2e, $01, $60   ; dy -36 dx +46 tile 1 attr $60
    db $f0, $1d, $00, $60   ; dy -16 dx +29 tile 0 attr $60
    db $e8, $be, $02, $60   ; dy -24 dx -66 tile 2 attr $60
    db $d8, $c4, $00, $40   ; dy -40 dx -60 tile 0 attr $40
    db $e8, $e2, $03, $20   ; dy -24 dx -30 tile 3 attr $20
    db $e8, $ce, $03, $60   ; dy -24 dx -50 tile 3 attr $60
    db $e0, $cf, $02, $60   ; dy -32 dx -49 tile 2 attr $60
    db $e4, $da, $01, $00   ; dy -28 dx -38 tile 1 attr $00
    db $e8, $ff, $04, $40   ; dy -24 dx -1 tile 4 attr $40
    db $d0, $d0, $09, $00   ; dy -48 dx -48 tile 9 attr $00
    db $d0, $d8, $0a, $00   ; dy -48 dx -40 tile 10 attr $00
    db $d0, $00, $1a, $00   ; dy -48 dx +0 tile 26 attr $00
    db $d0, $08, $1b, $00   ; dy -48 dx +8 tile 27 attr $00
    db $80
Anim_1a_F06:   ; $621a 29 sprites
    db $f0, $d6, $02, $00   ; dy -16 dx -42 tile 2 attr $00
    db $f4, $e7, $02, $00   ; dy -12 dx -25 tile 2 attr $00
    db $f8, $03, $01, $00   ; dy -8 dx +3 tile 1 attr $00
    db $e8, $d5, $00, $20   ; dy -24 dx -43 tile 0 attr $20
    db $f0, $34, $02, $00   ; dy -16 dx +52 tile 2 attr $00
    db $f8, $23, $02, $00   ; dy -8 dx +35 tile 2 attr $00
    db $f4, $18, $01, $60   ; dy -12 dx +24 tile 1 attr $60
    db $f0, $f3, $04, $20   ; dy -16 dx -13 tile 4 attr $20
    db $f0, $24, $04, $00   ; dy -16 dx +36 tile 4 attr $00
    db $f0, $10, $03, $00   ; dy -16 dx +16 tile 3 attr $00
    db $f0, $04, $02, $00   ; dy -16 dx +4 tile 2 attr $00
    db $f0, $b4, $02, $00   ; dy -16 dx -76 tile 2 attr $00
    db $f4, $c5, $01, $00   ; dy -12 dx -59 tile 1 attr $00
    db $e8, $1c, $11, $00   ; dy -24 dx +28 tile 17 attr $00
    db $e0, $20, $10, $00   ; dy -32 dx +32 tile 16 attr $00
    db $e0, $18, $0f, $00   ; dy -32 dx +24 tile 15 attr $00
    db $d8, $18, $0d, $00   ; dy -40 dx +24 tile 13 attr $00
    db $d8, $20, $0e, $00   ; dy -40 dx +32 tile 14 attr $00
    db $e0, $e0, $0c, $00   ; dy -32 dx -32 tile 12 attr $00
    db $d8, $e0, $0b, $00   ; dy -40 dx -32 tile 11 attr $00
    db $d8, $c4, $11, $00   ; dy -40 dx -60 tile 17 attr $00
    db $d0, $c8, $10, $00   ; dy -48 dx -56 tile 16 attr $00
    db $d0, $c0, $0f, $00   ; dy -48 dx -64 tile 15 attr $00
    db $d0, $48, $0c, $00   ; dy -48 dx +72 tile 12 attr $00
    db $d0, $d8, $03, $00   ; dy -48 dx -40 tile 3 attr $00
    db $d8, $f0, $01, $60   ; dy -40 dx -16 tile 1 attr $60
    db $d8, $40, $02, $00   ; dy -40 dx +64 tile 2 attr $00
    db $e0, $30, $04, $00   ; dy -32 dx +48 tile 4 attr $00
    db $d0, $10, $02, $00   ; dy -48 dx +16 tile 2 attr $00
    db $80
Anim_1a_F07:   ; $628f 35 sprites
    db $f0, $1b, $02, $60   ; dy -16 dx +27 tile 2 attr $60
    db $ec, $0a, $02, $60   ; dy -20 dx +10 tile 2 attr $60
    db $e8, $ee, $01, $60   ; dy -24 dx -18 tile 1 attr $60
    db $f8, $1c, $00, $40   ; dy -8 dx +28 tile 0 attr $40
    db $f0, $bd, $02, $60   ; dy -16 dx -67 tile 2 attr $60
    db $ec, $d9, $01, $00   ; dy -20 dx -39 tile 1 attr $00
    db $f0, $fe, $04, $40   ; dy -16 dx -2 tile 4 attr $40
    db $f0, $cd, $04, $60   ; dy -16 dx -51 tile 4 attr $60
    db $f0, $e1, $03, $60   ; dy -16 dx -31 tile 3 attr $60
    db $f0, $ed, $02, $60   ; dy -16 dx -19 tile 2 attr $60
    db $ec, $2c, $01, $60   ; dy -20 dx +44 tile 1 attr $60
    db $e0, $f8, $1a, $00   ; dy -32 dx -8 tile 26 attr $00
    db $e0, $00, $1b, $00   ; dy -32 dx +0 tile 27 attr $00
    db $d8, $f8, $17, $00   ; dy -40 dx -8 tile 23 attr $00
    db $d8, $00, $18, $00   ; dy -40 dx +0 tile 24 attr $00
    db $d8, $08, $19, $00   ; dy -40 dx +8 tile 25 attr $00
    db $d0, $f8, $14, $00   ; dy -48 dx -8 tile 20 attr $00
    db $d0, $00, $15, $00   ; dy -48 dx +0 tile 21 attr $00
    db $d0, $08, $16, $00   ; dy -48 dx +8 tile 22 attr $00
    db $e8, $c8, $09, $00   ; dy -24 dx -56 tile 9 attr $00
    db $e8, $d0, $0a, $00   ; dy -24 dx -48 tile 10 attr $00
    db $e0, $c8, $07, $40   ; dy -32 dx -56 tile 7 attr $40
    db $e0, $d0, $08, $40   ; dy -32 dx -48 tile 8 attr $40
    db $d0, $30, $23, $00   ; dy -48 dx +48 tile 35 attr $00
    db $d0, $38, $24, $00   ; dy -48 dx +56 tile 36 attr $00
    db $d8, $30, $25, $00   ; dy -40 dx +48 tile 37 attr $00
    db $d8, $e0, $07, $00   ; dy -40 dx -32 tile 7 attr $00
    db $d8, $e8, $08, $00   ; dy -40 dx -24 tile 8 attr $00
    db $d0, $e0, $05, $00   ; dy -48 dx -32 tile 5 attr $00
    db $d0, $e8, $06, $00   ; dy -48 dx -24 tile 6 attr $00
    db $d8, $18, $00, $40   ; dy -40 dx +24 tile 0 attr $40
    db $d0, $28, $01, $60   ; dy -48 dx +40 tile 1 attr $60
    db $d0, $d8, $02, $60   ; dy -48 dx -40 tile 2 attr $60
    db $d8, $c0, $02, $60   ; dy -40 dx -64 tile 2 attr $60
    db $e0, $b0, $04, $40   ; dy -32 dx -80 tile 4 attr $40
    db $80
Anim_1a_F08:   ; $631c 29 sprites
    db $f8, $14, $11, $00   ; dy -8 dx +20 tile 17 attr $00
    db $f0, $18, $10, $00   ; dy -16 dx +24 tile 16 attr $00
    db $f0, $10, $0f, $00   ; dy -16 dx +16 tile 15 attr $00
    db $e8, $10, $0d, $00   ; dy -24 dx +16 tile 13 attr $00
    db $e8, $18, $0e, $00   ; dy -24 dx +24 tile 14 attr $00
    db $f0, $d8, $0c, $00   ; dy -16 dx -40 tile 12 attr $00
    db $e8, $d8, $0b, $00   ; dy -24 dx -40 tile 11 attr $00
    db $e8, $bc, $11, $00   ; dy -24 dx -68 tile 17 attr $00
    db $e0, $c0, $10, $00   ; dy -32 dx -64 tile 16 attr $00
    db $e0, $b8, $0f, $00   ; dy -32 dx -72 tile 15 attr $00
    db $d8, $b8, $0d, $00   ; dy -40 dx -72 tile 13 attr $00
    db $d8, $c0, $0e, $00   ; dy -40 dx -64 tile 14 attr $00
    db $e8, $3c, $0c, $00   ; dy -24 dx +60 tile 12 attr $00
    db $e0, $3c, $0b, $00   ; dy -32 dx +60 tile 11 attr $00
    db $d0, $10, $2b, $00   ; dy -48 dx +16 tile 43 attr $00
    db $d0, $18, $2c, $00   ; dy -48 dx +24 tile 44 attr $00
    db $d0, $20, $2d, $00   ; dy -48 dx +32 tile 45 attr $00
    db $d8, $d0, $1a, $00   ; dy -40 dx -48 tile 26 attr $00
    db $d8, $d8, $1b, $00   ; dy -40 dx -40 tile 27 attr $00
    db $d0, $d0, $17, $00   ; dy -48 dx -48 tile 23 attr $00
    db $d0, $d8, $18, $00   ; dy -48 dx -40 tile 24 attr $00
    db $d0, $e0, $19, $00   ; dy -48 dx -32 tile 25 attr $00
    db $e0, $e0, $01, $00   ; dy -32 dx -32 tile 1 attr $00
    db $e0, $10, $03, $00   ; dy -32 dx +16 tile 3 attr $00
    db $e8, $f0, $04, $00   ; dy -24 dx -16 tile 4 attr $00
    db $d0, $3c, $02, $00   ; dy -48 dx +60 tile 2 attr $00
    db $f0, $b0, $00, $00   ; dy -16 dx -80 tile 0 attr $00
    db $f0, $28, $01, $00   ; dy -16 dx +40 tile 1 attr $00
    db $d0, $00, $02, $00   ; dy -48 dx +0 tile 2 attr $00
    db $80
Anim_1a_F09:   ; $6391 33 sprites
    db $f0, $f0, $1a, $00   ; dy -16 dx -16 tile 26 attr $00
    db $f0, $f8, $1b, $00   ; dy -16 dx -8 tile 27 attr $00
    db $e8, $f0, $17, $00   ; dy -24 dx -16 tile 23 attr $00
    db $e8, $f8, $18, $00   ; dy -24 dx -8 tile 24 attr $00
    db $e8, $00, $19, $00   ; dy -24 dx +0 tile 25 attr $00
    db $e0, $f0, $14, $00   ; dy -32 dx -16 tile 20 attr $00
    db $e0, $f8, $15, $00   ; dy -32 dx -8 tile 21 attr $00
    db $e0, $00, $16, $00   ; dy -32 dx +0 tile 22 attr $00
    db $d8, $f4, $12, $00   ; dy -40 dx -12 tile 18 attr $00
    db $d8, $fc, $13, $00   ; dy -40 dx -4 tile 19 attr $00
    db $f8, $bc, $07, $40   ; dy -8 dx -68 tile 7 attr $40
    db $f8, $c4, $08, $40   ; dy -8 dx -60 tile 8 attr $40
    db $f0, $24, $25, $00   ; dy -16 dx +36 tile 37 attr $00
    db $e8, $24, $23, $00   ; dy -24 dx +36 tile 35 attr $00
    db $e8, $2c, $24, $00   ; dy -24 dx +44 tile 36 attr $00
    db $e0, $28, $21, $00   ; dy -32 dx +40 tile 33 attr $00
    db $e0, $30, $22, $00   ; dy -32 dx +48 tile 34 attr $00
    db $d8, $30, $20, $00   ; dy -40 dx +48 tile 32 attr $00
    db $d8, $28, $1f, $00   ; dy -40 dx +40 tile 31 attr $00
    db $d0, $2a, $1d, $00   ; dy -48 dx +42 tile 29 attr $00
    db $d0, $32, $1e, $00   ; dy -48 dx +50 tile 30 attr $00
    db $e8, $d8, $07, $00   ; dy -24 dx -40 tile 7 attr $00
    db $e8, $e0, $08, $00   ; dy -24 dx -32 tile 8 attr $00
    db $e0, $d8, $05, $00   ; dy -32 dx -40 tile 5 attr $00
    db $e0, $e0, $06, $00   ; dy -32 dx -32 tile 6 attr $00
    db $d0, $c0, $03, $00   ; dy -48 dx -64 tile 3 attr $00
    db $e8, $c8, $01, $00   ; dy -24 dx -56 tile 1 attr $00
    db $e0, $1c, $03, $00   ; dy -32 dx +28 tile 3 attr $00
    db $d8, $48, $02, $00   ; dy -40 dx +72 tile 2 attr $00
    db $f8, $48, $01, $00   ; dy -8 dx +72 tile 1 attr $00
    db $f8, $08, $00, $00   ; dy -8 dx +8 tile 0 attr $00
    db $f8, $e0, $03, $00   ; dy -8 dx -32 tile 3 attr $00
    db $d0, $08, $02, $00   ; dy -48 dx +8 tile 2 attr $00
    db $80
Anim_1a_F10:   ; $6416 35 sprites
    db $f8, $08, $0d, $00   ; dy -8 dx +8 tile 13 attr $00
    db $f8, $10, $0e, $00   ; dy -8 dx +16 tile 14 attr $00
    db $f8, $d4, $0c, $00   ; dy -8 dx -44 tile 12 attr $00
    db $f0, $d4, $0b, $00   ; dy -16 dx -44 tile 11 attr $00
    db $f8, $b4, $11, $00   ; dy -8 dx -76 tile 17 attr $00
    db $f0, $b8, $10, $00   ; dy -16 dx -72 tile 16 attr $00
    db $f0, $b0, $0f, $00   ; dy -16 dx -80 tile 15 attr $00
    db $e8, $b0, $0d, $00   ; dy -24 dx -80 tile 13 attr $00
    db $e8, $b8, $0e, $00   ; dy -24 dx -72 tile 14 attr $00
    db $f8, $30, $0b, $00   ; dy -8 dx +48 tile 11 attr $00
    db $e0, $08, $2b, $00   ; dy -32 dx +8 tile 43 attr $00
    db $e0, $10, $2c, $00   ; dy -32 dx +16 tile 44 attr $00
    db $e0, $18, $2d, $00   ; dy -32 dx +24 tile 45 attr $00
    db $d8, $08, $28, $00   ; dy -40 dx +8 tile 40 attr $00
    db $d8, $10, $29, $00   ; dy -40 dx +16 tile 41 attr $00
    db $d8, $18, $2a, $00   ; dy -40 dx +24 tile 42 attr $00
    db $d0, $10, $26, $00   ; dy -48 dx +16 tile 38 attr $00
    db $d0, $18, $27, $00   ; dy -48 dx +24 tile 39 attr $00
    db $e8, $c8, $1a, $00   ; dy -24 dx -56 tile 26 attr $00
    db $e8, $d0, $1b, $00   ; dy -24 dx -48 tile 27 attr $00
    db $e0, $c8, $17, $00   ; dy -32 dx -56 tile 23 attr $00
    db $e0, $d0, $18, $00   ; dy -32 dx -48 tile 24 attr $00
    db $e0, $d8, $19, $00   ; dy -32 dx -40 tile 25 attr $00
    db $d8, $c8, $14, $00   ; dy -40 dx -56 tile 20 attr $00
    db $d8, $d0, $15, $00   ; dy -40 dx -48 tile 21 attr $00
    db $d8, $d8, $16, $00   ; dy -40 dx -40 tile 22 attr $00
    db $d0, $cc, $12, $00   ; dy -48 dx -52 tile 18 attr $00
    db $d0, $d4, $13, $00   ; dy -48 dx -44 tile 19 attr $00
    db $f0, $08, $03, $00   ; dy -16 dx +8 tile 3 attr $00
    db $f8, $f0, $04, $00   ; dy -8 dx -16 tile 4 attr $00
    db $e8, $dc, $01, $00   ; dy -24 dx -36 tile 1 attr $00
    db $e8, $30, $02, $00   ; dy -24 dx +48 tile 2 attr $00
    db $e0, $f8, $03, $00   ; dy -32 dx -8 tile 3 attr $00
    db $d8, $b0, $01, $00   ; dy -40 dx -80 tile 1 attr $00
    db $e0, $40, $00, $00   ; dy -32 dx +64 tile 0 attr $00
    db $80
Anim_1a_F11:   ; $64a3 32 sprites
    db $f8, $e4, $12, $00   ; dy -8 dx -28 tile 18 attr $00
    db $f8, $ec, $13, $00   ; dy -8 dx -20 tile 19 attr $00
    db $f8, $18, $21, $00   ; dy -8 dx +24 tile 33 attr $00
    db $f8, $20, $22, $00   ; dy -8 dx +32 tile 34 attr $00
    db $f0, $20, $20, $00   ; dy -16 dx +32 tile 32 attr $00
    db $f0, $18, $1f, $00   ; dy -16 dx +24 tile 31 attr $00
    db $e8, $1a, $1d, $00   ; dy -24 dx +26 tile 29 attr $00
    db $e8, $22, $1e, $00   ; dy -24 dx +34 tile 30 attr $00
    db $e0, $22, $1c, $00   ; dy -32 dx +34 tile 28 attr $00
    db $f8, $d0, $07, $00   ; dy -8 dx -48 tile 7 attr $00
    db $f8, $d8, $08, $00   ; dy -8 dx -40 tile 8 attr $00
    db $f0, $d0, $05, $00   ; dy -16 dx -48 tile 5 attr $00
    db $f0, $d8, $06, $00   ; dy -16 dx -40 tile 6 attr $00
    db $d8, $e0, $2b, $00   ; dy -40 dx -32 tile 43 attr $00
    db $d8, $e8, $2c, $00   ; dy -40 dx -24 tile 44 attr $00
    db $d8, $f0, $2d, $00   ; dy -40 dx -16 tile 45 attr $00
    db $d0, $e0, $28, $00   ; dy -48 dx -32 tile 40 attr $00
    db $d0, $e8, $29, $00   ; dy -48 dx -24 tile 41 attr $00
    db $d0, $f0, $2a, $00   ; dy -48 dx -16 tile 42 attr $00
    db $d0, $40, $09, $00   ; dy -48 dx +64 tile 9 attr $00
    db $d0, $48, $0a, $00   ; dy -48 dx +72 tile 10 attr $00
    db $f8, $c0, $01, $00   ; dy -8 dx -64 tile 1 attr $00
    db $f8, $0c, $03, $00   ; dy -8 dx +12 tile 3 attr $00
    db $f0, $38, $02, $00   ; dy -16 dx +56 tile 2 attr $00
    db $d0, $30, $03, $00   ; dy -48 dx +48 tile 3 attr $00
    db $d8, $b8, $03, $00   ; dy -40 dx -72 tile 3 attr $00
    db $d8, $08, $04, $00   ; dy -40 dx +8 tile 4 attr $00
    db $e0, $d8, $00, $00   ; dy -32 dx -40 tile 0 attr $00
    db $e8, $b0, $01, $00   ; dy -24 dx -80 tile 1 attr $00
    db $f0, $48, $01, $00   ; dy -16 dx +72 tile 1 attr $00
    db $e8, $f0, $00, $00   ; dy -24 dx -16 tile 0 attr $00
    db $e0, $40, $02, $00   ; dy -32 dx +64 tile 2 attr $00
    db $80
Anim_1a_F12:   ; $6524 32 sprites
    db $f8, $b0, $0e, $00   ; dy -8 dx -80 tile 14 attr $00
    db $f8, $c0, $1a, $00   ; dy -8 dx -64 tile 26 attr $00
    db $f8, $c8, $1b, $00   ; dy -8 dx -56 tile 27 attr $00
    db $f0, $c0, $17, $00   ; dy -16 dx -64 tile 23 attr $00
    db $f0, $c8, $18, $00   ; dy -16 dx -56 tile 24 attr $00
    db $f0, $d0, $19, $00   ; dy -16 dx -48 tile 25 attr $00
    db $e8, $c0, $14, $00   ; dy -24 dx -64 tile 20 attr $00
    db $e8, $c8, $15, $00   ; dy -24 dx -56 tile 21 attr $00
    db $e8, $d0, $16, $00   ; dy -24 dx -48 tile 22 attr $00
    db $e0, $c4, $12, $00   ; dy -32 dx -60 tile 18 attr $00
    db $e0, $cc, $13, $00   ; dy -32 dx -52 tile 19 attr $00
    db $f0, $00, $2b, $00   ; dy -16 dx +0 tile 43 attr $00
    db $f0, $08, $2c, $00   ; dy -16 dx +8 tile 44 attr $00
    db $f0, $10, $2d, $00   ; dy -16 dx +16 tile 45 attr $00
    db $e8, $00, $28, $00   ; dy -24 dx +0 tile 40 attr $00
    db $e8, $08, $29, $00   ; dy -24 dx +8 tile 41 attr $00
    db $e8, $10, $2a, $00   ; dy -24 dx +16 tile 42 attr $00
    db $e0, $08, $26, $00   ; dy -32 dx +8 tile 38 attr $00
    db $e0, $10, $27, $00   ; dy -32 dx +16 tile 39 attr $00
    db $d0, $e8, $0c, $00   ; dy -48 dx -24 tile 12 attr $00
    db $d8, $24, $11, $00   ; dy -40 dx +36 tile 17 attr $00
    db $d0, $28, $10, $00   ; dy -48 dx +40 tile 16 attr $00
    db $d0, $20, $0f, $00   ; dy -48 dx +32 tile 15 attr $00
    db $f0, $f0, $03, $00   ; dy -16 dx -16 tile 3 attr $00
    db $f8, $28, $02, $00   ; dy -8 dx +40 tile 2 attr $00
    db $f0, $38, $00, $00   ; dy -16 dx +56 tile 0 attr $00
    db $e0, $b8, $04, $00   ; dy -32 dx -72 tile 4 attr $00
    db $d0, $b8, $00, $00   ; dy -48 dx -72 tile 0 attr $00
    db $d8, $d0, $02, $00   ; dy -40 dx -48 tile 2 attr $00
    db $e8, $e0, $03, $00   ; dy -24 dx -32 tile 3 attr $00
    db $d0, $08, $01, $00   ; dy -48 dx +8 tile 1 attr $00
    db $e0, $30, $00, $00   ; dy -32 dx +48 tile 0 attr $00
    db $80
Anim_1a_F13:   ; $65a5 23 sprites
    db $f8, $06, $1c, $00   ; dy -8 dx +6 tile 28 attr $00
    db $e8, $d8, $2b, $00   ; dy -24 dx -40 tile 43 attr $00
    db $e8, $e0, $2c, $00   ; dy -24 dx -32 tile 44 attr $00
    db $e8, $e8, $2d, $00   ; dy -24 dx -24 tile 45 attr $00
    db $e0, $d8, $28, $00   ; dy -32 dx -40 tile 40 attr $00
    db $e0, $e0, $29, $00   ; dy -32 dx -32 tile 41 attr $00
    db $e0, $e8, $2a, $00   ; dy -32 dx -24 tile 42 attr $00
    db $d8, $e0, $26, $00   ; dy -40 dx -32 tile 38 attr $00
    db $d8, $e8, $27, $00   ; dy -40 dx -24 tile 39 attr $00
    db $e0, $38, $09, $00   ; dy -32 dx +56 tile 9 attr $00
    db $e0, $40, $0a, $00   ; dy -32 dx +64 tile 10 attr $00
    db $d8, $38, $05, $00   ; dy -40 dx +56 tile 5 attr $00
    db $d8, $40, $06, $00   ; dy -40 dx +64 tile 6 attr $00
    db $e8, $b0, $03, $00   ; dy -24 dx -80 tile 3 attr $00
    db $e0, $28, $03, $00   ; dy -32 dx +40 tile 3 attr $00
    db $d0, $10, $02, $00   ; dy -48 dx +16 tile 2 attr $00
    db $f0, $c8, $01, $00   ; dy -16 dx -56 tile 1 attr $00
    db $d0, $f8, $00, $00   ; dy -48 dx -8 tile 0 attr $00
    db $d0, $d0, $00, $00   ; dy -48 dx -48 tile 0 attr $00
    db $f8, $20, $03, $00   ; dy -8 dx +32 tile 3 attr $00
    db $f0, $e8, $04, $00   ; dy -16 dx -24 tile 4 attr $00
    db $e8, $10, $02, $00   ; dy -24 dx +16 tile 2 attr $00
    db $f0, $40, $01, $00   ; dy -16 dx +64 tile 1 attr $00
    db $80
Anim_1a_F14:   ; $6602 29 sprites
    db $e8, $1c, $11, $00   ; dy -24 dx +28 tile 17 attr $00
    db $e0, $20, $10, $00   ; dy -32 dx +32 tile 16 attr $00
    db $e0, $18, $0f, $00   ; dy -32 dx +24 tile 15 attr $00
    db $d8, $18, $0d, $00   ; dy -40 dx +24 tile 13 attr $00
    db $d8, $20, $0e, $00   ; dy -40 dx +32 tile 14 attr $00
    db $e0, $e0, $0c, $00   ; dy -32 dx -32 tile 12 attr $00
    db $d8, $e0, $0b, $00   ; dy -40 dx -32 tile 11 attr $00
    db $d0, $48, $0c, $00   ; dy -48 dx +72 tile 12 attr $00
    db $d8, $c4, $11, $00   ; dy -40 dx -60 tile 17 attr $00
    db $d0, $c8, $10, $00   ; dy -48 dx -56 tile 16 attr $00
    db $d0, $c0, $0f, $00   ; dy -48 dx -64 tile 15 attr $00
    db $f8, $f8, $28, $00   ; dy -8 dx -8 tile 40 attr $00
    db $f8, $00, $29, $00   ; dy -8 dx +0 tile 41 attr $00
    db $f8, $08, $2a, $00   ; dy -8 dx +8 tile 42 attr $00
    db $f0, $00, $26, $00   ; dy -16 dx +0 tile 38 attr $00
    db $f0, $08, $27, $00   ; dy -16 dx +8 tile 39 attr $00
    db $f8, $b8, $14, $00   ; dy -8 dx -72 tile 20 attr $00
    db $f8, $c0, $15, $00   ; dy -8 dx -64 tile 21 attr $00
    db $f8, $c8, $16, $00   ; dy -8 dx -56 tile 22 attr $00
    db $f0, $bc, $12, $00   ; dy -16 dx -68 tile 18 attr $00
    db $f0, $c4, $13, $00   ; dy -16 dx -60 tile 19 attr $00
    db $e0, $08, $02, $00   ; dy -32 dx +8 tile 2 attr $00
    db $e0, $f0, $00, $00   ; dy -32 dx -16 tile 0 attr $00
    db $f0, $24, $03, $00   ; dy -16 dx +36 tile 3 attr $00
    db $f8, $b0, $03, $00   ; dy -8 dx -80 tile 3 attr $00
    db $e8, $48, $02, $00   ; dy -24 dx +72 tile 2 attr $00
    db $f8, $38, $01, $00   ; dy -8 dx +56 tile 1 attr $00
    db $d0, $00, $00, $00   ; dy -48 dx +0 tile 0 attr $00
    db $e8, $d0, $02, $00   ; dy -24 dx -48 tile 2 attr $00
    db $80
Anim_1a_F15:   ; $6677 35 sprites
    db $e0, $f8, $1a, $00   ; dy -32 dx -8 tile 26 attr $00
    db $e0, $00, $1b, $00   ; dy -32 dx +0 tile 27 attr $00
    db $d8, $f8, $17, $00   ; dy -40 dx -8 tile 23 attr $00
    db $d8, $00, $18, $00   ; dy -40 dx +0 tile 24 attr $00
    db $d8, $08, $19, $00   ; dy -40 dx +8 tile 25 attr $00
    db $d0, $f8, $14, $00   ; dy -48 dx -8 tile 20 attr $00
    db $d0, $00, $15, $00   ; dy -48 dx +0 tile 21 attr $00
    db $d0, $08, $16, $00   ; dy -48 dx +8 tile 22 attr $00
    db $d0, $30, $23, $00   ; dy -48 dx +48 tile 35 attr $00
    db $d0, $38, $24, $00   ; dy -48 dx +56 tile 36 attr $00
    db $d8, $30, $25, $00   ; dy -40 dx +48 tile 37 attr $00
    db $d8, $e0, $07, $00   ; dy -40 dx -32 tile 7 attr $00
    db $d8, $e8, $08, $00   ; dy -40 dx -24 tile 8 attr $00
    db $d0, $e0, $05, $00   ; dy -48 dx -32 tile 5 attr $00
    db $d0, $e8, $06, $00   ; dy -48 dx -24 tile 6 attr $00
    db $f8, $d0, $2b, $00   ; dy -8 dx -48 tile 43 attr $00
    db $f8, $d8, $2c, $00   ; dy -8 dx -40 tile 44 attr $00
    db $f8, $e0, $2d, $00   ; dy -8 dx -32 tile 45 attr $00
    db $f0, $d0, $28, $00   ; dy -16 dx -48 tile 40 attr $00
    db $f0, $d8, $29, $00   ; dy -16 dx -40 tile 41 attr $00
    db $f0, $e0, $2a, $00   ; dy -16 dx -32 tile 42 attr $00
    db $e8, $d8, $26, $00   ; dy -24 dx -40 tile 38 attr $00
    db $e8, $e0, $27, $00   ; dy -24 dx -32 tile 39 attr $00
    db $f0, $30, $09, $00   ; dy -16 dx +48 tile 9 attr $00
    db $f0, $38, $0a, $00   ; dy -16 dx +56 tile 10 attr $00
    db $e8, $30, $05, $00   ; dy -24 dx +48 tile 5 attr $00
    db $e8, $38, $06, $00   ; dy -24 dx +56 tile 6 attr $00
    db $f0, $18, $04, $00   ; dy -16 dx +24 tile 4 attr $00
    db $e0, $20, $03, $00   ; dy -32 dx +32 tile 3 attr $00
    db $f0, $b8, $02, $00   ; dy -16 dx -72 tile 2 attr $00
    db $f8, $f8, $01, $00   ; dy -8 dx -8 tile 1 attr $00
    db $d9, $b8, $00, $00   ; dy -39 dx -72 tile 0 attr $00
    db $d1, $d0, $00, $00   ; dy -47 dx -48 tile 0 attr $00
    db $d8, $40, $01, $00   ; dy -40 dx +64 tile 1 attr $00
    db $f8, $40, $00, $00   ; dy -8 dx +64 tile 0 attr $00
    db $80
Anim_1a_F16:   ; $6704 28 sprites
    db $f8, $14, $11, $00   ; dy -8 dx +20 tile 17 attr $00
    db $f0, $18, $10, $00   ; dy -16 dx +24 tile 16 attr $00
    db $f0, $10, $0f, $00   ; dy -16 dx +16 tile 15 attr $00
    db $e8, $10, $0d, $00   ; dy -24 dx +16 tile 13 attr $00
    db $e8, $18, $0e, $00   ; dy -24 dx +24 tile 14 attr $00
    db $f0, $d8, $0c, $00   ; dy -16 dx -40 tile 12 attr $00
    db $e8, $d8, $0b, $00   ; dy -24 dx -40 tile 11 attr $00
    db $e0, $48, $0c, $00   ; dy -32 dx +72 tile 12 attr $00
    db $d8, $48, $0b, $00   ; dy -40 dx +72 tile 11 attr $00
    db $f0, $b8, $11, $00   ; dy -16 dx -72 tile 17 attr $00
    db $e8, $bc, $10, $00   ; dy -24 dx -68 tile 16 attr $00
    db $e8, $b4, $0f, $00   ; dy -24 dx -76 tile 15 attr $00
    db $e0, $b4, $0d, $00   ; dy -32 dx -76 tile 13 attr $00
    db $e0, $bc, $0e, $00   ; dy -32 dx -68 tile 14 attr $00
    db $d0, $10, $2b, $00   ; dy -48 dx +16 tile 43 attr $00
    db $d0, $18, $2c, $00   ; dy -48 dx +24 tile 44 attr $00
    db $d0, $20, $2d, $00   ; dy -48 dx +32 tile 45 attr $00
    db $d8, $d0, $1a, $00   ; dy -40 dx -48 tile 26 attr $00
    db $d8, $d8, $1b, $00   ; dy -40 dx -40 tile 27 attr $00
    db $d0, $d0, $17, $00   ; dy -48 dx -48 tile 23 attr $00
    db $d0, $d8, $18, $00   ; dy -48 dx -40 tile 24 attr $00
    db $d0, $e0, $19, $00   ; dy -48 dx -32 tile 25 attr $00
    db $f8, $00, $04, $00   ; dy -8 dx +0 tile 4 attr $00
    db $e0, $f8, $01, $00   ; dy -32 dx -8 tile 1 attr $00
    db $f8, $c0, $00, $00   ; dy -8 dx -64 tile 0 attr $00
    db $e8, $30, $02, $00   ; dy -24 dx +48 tile 2 attr $00
    db $f8, $e8, $03, $00   ; dy -8 dx -24 tile 3 attr $00
    db $d0, $f0, $01, $00   ; dy -48 dx -16 tile 1 attr $00
    db $80
Anim_1a_F17:   ; $6775 33 sprites
    db $f8, $d0, $26, $00   ; dy -8 dx -48 tile 38 attr $00
    db $f8, $d8, $27, $00   ; dy -8 dx -40 tile 39 attr $00
    db $f8, $28, $05, $00   ; dy -8 dx +40 tile 5 attr $00
    db $f8, $30, $06, $00   ; dy -8 dx +48 tile 6 attr $00
    db $f0, $f0, $1a, $00   ; dy -16 dx -16 tile 26 attr $00
    db $f0, $f8, $1b, $00   ; dy -16 dx -8 tile 27 attr $00
    db $e8, $f0, $17, $00   ; dy -24 dx -16 tile 23 attr $00
    db $e8, $f8, $18, $00   ; dy -24 dx -8 tile 24 attr $00
    db $e8, $00, $19, $00   ; dy -24 dx +0 tile 25 attr $00
    db $e0, $f0, $14, $00   ; dy -32 dx -16 tile 20 attr $00
    db $e0, $f8, $15, $00   ; dy -32 dx -8 tile 21 attr $00
    db $e0, $00, $16, $00   ; dy -32 dx +0 tile 22 attr $00
    db $d8, $f4, $12, $00   ; dy -40 dx -12 tile 18 attr $00
    db $d8, $fc, $13, $00   ; dy -40 dx -4 tile 19 attr $00
    db $f0, $24, $25, $00   ; dy -16 dx +36 tile 37 attr $00
    db $e8, $24, $23, $00   ; dy -24 dx +36 tile 35 attr $00
    db $e8, $2c, $24, $00   ; dy -24 dx +44 tile 36 attr $00
    db $e0, $28, $21, $00   ; dy -32 dx +40 tile 33 attr $00
    db $e0, $30, $22, $00   ; dy -32 dx +48 tile 34 attr $00
    db $e8, $d8, $07, $00   ; dy -24 dx -40 tile 7 attr $00
    db $e8, $e0, $08, $00   ; dy -24 dx -32 tile 8 attr $00
    db $e0, $d8, $05, $00   ; dy -32 dx -40 tile 5 attr $00
    db $e0, $e0, $06, $00   ; dy -32 dx -32 tile 6 attr $00
    db $d8, $32, $20, $00   ; dy -40 dx +50 tile 32 attr $00
    db $d8, $2a, $1f, $00   ; dy -40 dx +42 tile 31 attr $00
    db $d0, $2c, $1d, $00   ; dy -48 dx +44 tile 29 attr $00
    db $d0, $34, $1e, $00   ; dy -48 dx +52 tile 30 attr $00
    db $f0, $b8, $00, $00   ; dy -16 dx -72 tile 0 attr $00
    db $f0, $40, $04, $00   ; dy -16 dx +64 tile 4 attr $00
    db $e0, $c8, $03, $00   ; dy -32 dx -56 tile 3 attr $00
    db $f8, $08, $02, $00   ; dy -8 dx +8 tile 2 attr $00
    db $e0, $18, $01, $00   ; dy -32 dx +24 tile 1 attr $00
    db $d0, $04, $02, $00   ; dy -48 dx +4 tile 2 attr $00
    db $80
Anim_1a_F18:   ; $67fa 16 sprites
    db $f8, $e4, $12, $00   ; dy -8 dx -28 tile 18 attr $00
    db $f8, $ec, $13, $00   ; dy -8 dx -20 tile 19 attr $00
    db $f8, $18, $21, $00   ; dy -8 dx +24 tile 33 attr $00
    db $f8, $20, $22, $00   ; dy -8 dx +32 tile 34 attr $00
    db $f8, $d0, $07, $00   ; dy -8 dx -48 tile 7 attr $00
    db $f8, $d8, $08, $00   ; dy -8 dx -40 tile 8 attr $00
    db $f0, $d0, $05, $00   ; dy -16 dx -48 tile 5 attr $00
    db $f0, $d8, $06, $00   ; dy -16 dx -40 tile 6 attr $00
    db $f0, $22, $20, $00   ; dy -16 dx +34 tile 32 attr $00
    db $f0, $1a, $1f, $00   ; dy -16 dx +26 tile 31 attr $00
    db $e8, $1c, $1d, $00   ; dy -24 dx +28 tile 29 attr $00
    db $e8, $24, $1e, $00   ; dy -24 dx +36 tile 30 attr $00
    db $e0, $24, $1c, $00   ; dy -32 dx +36 tile 28 attr $00
    db $f0, $08, $01, $00   ; dy -16 dx +8 tile 1 attr $00
    db $f0, $b8, $03, $00   ; dy -16 dx -72 tile 3 attr $00
    db $f0, $f4, $02, $00   ; dy -16 dx -12 tile 2 attr $00
Anim_1a_F19:   ; $683a empty frame = the $80 end above (shared)
    db $80
Anim_1b_RockThrow:   ; $683b animation $1b — RockThrow
    dw Anim_1b_F00
    dw Anim_1b_F01
    dw Anim_1b_F02
    dw Anim_1b_F03
    dw Anim_1b_F04
    dw Anim_1b_F05
    dw Anim_1b_F06
    dw Anim_1b_F07
    dw Anim_1b_F08
    dw Anim_1b_F08
    dw Anim_1b_F08
    dw Anim_1b_F08
    dw Anim_1b_F08
    dw Anim_1b_F08
    dw Anim_1b_F08
    dw Anim_1b_F08
    dw Anim_1b_F08
    dw Anim_1b_F08
    dw Anim_1b_F08
    dw Anim_1b_F08
    dw Anim_1b_F08
    dw Anim_1b_F08
    dw Anim_1b_F08
    dw Anim_1b_F08
    dw Anim_1b_F08
    dw Anim_1b_F08
    dw Anim_1b_F08
    dw Anim_1b_F08
    dw Anim_1b_F08
    dw Anim_1b_F08
    dw Anim_1b_F08
    dw Anim_1b_F08
Anim_1b_F00:   ; $687b 4 sprites
    db $d0, $f2, $17, $00   ; dy -48 dx -14 tile 23 attr $00
    db $d0, $fa, $18, $00   ; dy -48 dx -6 tile 24 attr $00
    db $d0, $02, $19, $00   ; dy -48 dx +2 tile 25 attr $00
    db $d0, $0a, $1a, $00   ; dy -48 dx +10 tile 26 attr $00
    db $80
Anim_1b_F01:   ; $688c 8 sprites
    db $d0, $f2, $13, $00   ; dy -48 dx -14 tile 19 attr $00
    db $d0, $fa, $14, $00   ; dy -48 dx -6 tile 20 attr $00
    db $d0, $02, $15, $00   ; dy -48 dx +2 tile 21 attr $00
    db $d8, $f2, $17, $00   ; dy -40 dx -14 tile 23 attr $00
    db $d8, $fa, $18, $00   ; dy -40 dx -6 tile 24 attr $00
    db $d8, $02, $19, $00   ; dy -40 dx +2 tile 25 attr $00
    db $d0, $0a, $16, $00   ; dy -48 dx +10 tile 22 attr $00
    db $d8, $0a, $1a, $00   ; dy -40 dx +10 tile 26 attr $00
    db $80
Anim_1b_F02:   ; $68ad 11 sprites
    db $d8, $f2, $10, $00   ; dy -40 dx -14 tile 16 attr $00
    db $d8, $fa, $11, $00   ; dy -40 dx -6 tile 17 attr $00
    db $d8, $02, $12, $00   ; dy -40 dx +2 tile 18 attr $00
    db $e0, $f2, $13, $00   ; dy -32 dx -14 tile 19 attr $00
    db $e0, $fa, $14, $00   ; dy -32 dx -6 tile 20 attr $00
    db $e0, $02, $15, $00   ; dy -32 dx +2 tile 21 attr $00
    db $e0, $0a, $16, $00   ; dy -32 dx +10 tile 22 attr $00
    db $e8, $f2, $17, $00   ; dy -24 dx -14 tile 23 attr $00
    db $e8, $fa, $18, $00   ; dy -24 dx -6 tile 24 attr $00
    db $e8, $02, $19, $00   ; dy -24 dx +2 tile 25 attr $00
    db $e8, $0a, $1a, $00   ; dy -24 dx +10 tile 26 attr $00
    db $80
Anim_1b_F03:   ; $68da 12 sprites
    db $e9, $f8, $06, $00   ; dy -23 dx -8 tile 6 attr $00
    db $e9, $00, $07, $00   ; dy -23 dx +0 tile 7 attr $00
    db $e8, $f2, $0d, $20   ; dy -24 dx -14 tile 13 attr $20
    db $e0, $ea, $00, $20   ; dy -32 dx -22 tile 0 attr $20
    db $e1, $f8, $04, $00   ; dy -31 dx -8 tile 4 attr $00
    db $e1, $00, $05, $00   ; dy -31 dx +0 tile 5 attr $00
    db $e0, $f2, $0c, $20   ; dy -32 dx -14 tile 12 attr $20
    db $dd, $fa, $03, $00   ; dy -35 dx -6 tile 3 attr $00
    db $dc, $02, $02, $00   ; dy -36 dx +2 tile 2 attr $00
    db $e4, $06, $0c, $00   ; dy -28 dx +6 tile 12 attr $00
    db $ec, $06, $0d, $00   ; dy -20 dx +6 tile 13 attr $00
    db $db, $0a, $01, $00   ; dy -37 dx +10 tile 1 attr $00
    db $80
Anim_1b_F04:   ; $690b 12 sprites
    db $d8, $f2, $03, $00   ; dy -40 dx -14 tile 3 attr $00
    db $eb, $eb, $0e, $40   ; dy -21 dx -21 tile 14 attr $40
    db $eb, $f3, $0f, $40   ; dy -21 dx -13 tile 15 attr $40
    db $de, $e8, $00, $20   ; dy -34 dx -24 tile 0 attr $20
    db $d4, $06, $02, $00   ; dy -44 dx +6 tile 2 attr $00
    db $e4, $10, $0e, $60   ; dy -28 dx +16 tile 14 attr $60
    db $e4, $08, $0f, $60   ; dy -28 dx +8 tile 15 attr $60
    db $da, $10, $01, $00   ; dy -38 dx +16 tile 1 attr $00
    db $de, $f8, $04, $00   ; dy -34 dx -8 tile 4 attr $00
    db $de, $00, $05, $00   ; dy -34 dx +0 tile 5 attr $00
    db $e6, $f8, $06, $00   ; dy -26 dx -8 tile 6 attr $00
    db $e6, $00, $07, $00   ; dy -26 dx +0 tile 7 attr $00
    db $80
Anim_1b_F05:   ; $693c 12 sprites
    db $e2, $10, $01, $20   ; dy -30 dx +16 tile 1 attr $20
    db $f2, $10, $0c, $60   ; dy -14 dx +16 tile 12 attr $60
    db $ea, $10, $0d, $60   ; dy -22 dx +16 tile 13 attr $60
    db $dc, $0a, $02, $40   ; dy -36 dx +10 tile 2 attr $40
    db $e0, $ed, $03, $40   ; dy -32 dx -19 tile 3 attr $40
    db $e6, $e8, $01, $00   ; dy -26 dx -24 tile 1 attr $00
    db $f8, $eb, $0c, $40   ; dy -8 dx -21 tile 12 attr $40
    db $f0, $eb, $0d, $40   ; dy -16 dx -21 tile 13 attr $40
    db $e6, $fa, $08, $00   ; dy -26 dx -6 tile 8 attr $00
    db $e6, $02, $09, $00   ; dy -26 dx +2 tile 9 attr $00
    db $ee, $fa, $0a, $00   ; dy -18 dx -6 tile 10 attr $00
    db $ee, $02, $0b, $00   ; dy -18 dx +2 tile 11 attr $00
    db $80
Anim_1b_F06:   ; $696d 9 sprites
    db $f8, $eb, $0d, $60   ; dy -8 dx -21 tile 13 attr $60
    db $f8, $10, $0c, $40   ; dy -8 dx +16 tile 12 attr $40
    db $f0, $10, $0d, $40   ; dy -16 dx +16 tile 13 attr $40
    db $ec, $e8, $02, $00   ; dy -20 dx -24 tile 2 attr $00
    db $e2, $10, $00, $20   ; dy -30 dx +16 tile 0 attr $20
    db $ee, $fc, $04, $00   ; dy -18 dx -4 tile 4 attr $00
    db $ee, $04, $05, $00   ; dy -18 dx +4 tile 5 attr $00
    db $f6, $fc, $06, $00   ; dy -10 dx -4 tile 6 attr $00
    db $f6, $04, $07, $00   ; dy -10 dx +4 tile 7 attr $00
    db $80
Anim_1b_F07:   ; $6992 3 sprites
    db $f8, $10, $0d, $60   ; dy -8 dx +16 tile 13 attr $60
    db $f8, $fd, $04, $00   ; dy -8 dx -3 tile 4 attr $00
    db $f8, $05, $05, $00   ; dy -8 dx +5 tile 5 attr $00
Anim_1b_F08:   ; $699e empty frame = the $80 end above (shared)
    db $80
Anim_1c_WhiteFire:   ; $699f animation $1c — WhiteFire
    dw Anim_1c_F00
    dw Anim_1c_F01
    dw Anim_1c_F02
    dw Anim_1c_F03
    dw Anim_1c_F04
    dw Anim_1c_F05
    dw Anim_1c_F06
    dw Anim_1c_F07
    dw Anim_1c_F08
    dw Anim_1c_F09
    dw Anim_1c_F10
    dw Anim_1c_F11
    dw Anim_1c_F12
    dw Anim_1c_F13
    dw Anim_1c_F14
    dw Anim_1c_F15
    dw Anim_1c_F16
    dw Anim_1c_F17
    dw Anim_1c_F18
    dw Anim_1c_F19
    dw Anim_1c_F20
    dw Anim_1c_F20
    dw Anim_1c_F20
    dw Anim_1c_F20
    dw Anim_1c_F20
    dw Anim_1c_F20
    dw Anim_1c_F20
    dw Anim_1c_F20
    dw Anim_1c_F20
    dw Anim_1c_F20
    dw Anim_1c_F20
    dw Anim_1c_F20
Anim_1c_F00:   ; $69df 1 sprites
    db $f8, $b0, $22, $10   ; dy -8 dx -80 tile 34 attr $10
    db $80
Anim_1c_F01:   ; $69e4 3 sprites
    db $f8, $b0, $20, $10   ; dy -8 dx -80 tile 32 attr $10
    db $f8, $b8, $21, $10   ; dy -8 dx -72 tile 33 attr $10
    db $f8, $c0, $22, $10   ; dy -8 dx -64 tile 34 attr $10
    db $80
Anim_1c_F02:   ; $69f1 6 sprites
    db $f8, $c3, $20, $10   ; dy -8 dx -61 tile 32 attr $10
    db $f8, $cb, $21, $10   ; dy -8 dx -53 tile 33 attr $10
    db $f8, $d3, $22, $10   ; dy -8 dx -45 tile 34 attr $10
    db $f8, $b3, $10, $10   ; dy -8 dx -77 tile 16 attr $10
    db $f8, $bb, $11, $10   ; dy -8 dx -69 tile 17 attr $10
    db $f8, $ab, $11, $10   ; dy -8 dx -85 tile 17 attr $10
    db $80
Anim_1c_F03:   ; $6a0a 8 sprites
    db $f8, $d8, $20, $10   ; dy -8 dx -40 tile 32 attr $10
    db $f8, $e0, $21, $10   ; dy -8 dx -32 tile 33 attr $10
    db $f8, $e8, $22, $10   ; dy -8 dx -24 tile 34 attr $10
    db $f8, $c8, $11, $10   ; dy -8 dx -56 tile 17 attr $10
    db $f8, $d0, $11, $10   ; dy -8 dx -48 tile 17 attr $10
    db $f8, $c0, $12, $10   ; dy -8 dx -64 tile 18 attr $10
    db $f8, $b0, $02, $10   ; dy -8 dx -80 tile 2 attr $10
    db $f8, $b8, $02, $10   ; dy -8 dx -72 tile 2 attr $10
    db $80
Anim_1c_F04:   ; $6a2b 10 sprites
    db $f8, $b7, $00, $10   ; dy -8 dx -73 tile 0 attr $10
    db $f8, $bf, $01, $10   ; dy -8 dx -65 tile 1 attr $10
    db $f8, $c7, $02, $10   ; dy -8 dx -57 tile 2 attr $10
    db $f8, $cf, $02, $10   ; dy -8 dx -49 tile 2 attr $10
    db $f8, $df, $10, $10   ; dy -8 dx -33 tile 16 attr $10
    db $f8, $e7, $11, $10   ; dy -8 dx -25 tile 17 attr $10
    db $f8, $d7, $11, $10   ; dy -8 dx -41 tile 17 attr $10
    db $f8, $ef, $20, $10   ; dy -8 dx -17 tile 32 attr $10
    db $f8, $f7, $21, $10   ; dy -8 dx -9 tile 33 attr $10
    db $f8, $ff, $22, $10   ; dy -8 dx -1 tile 34 attr $10
    db $80
Anim_1c_F05:   ; $6a54 10 sprites
    db $f8, $d0, $00, $10   ; dy -8 dx -48 tile 0 attr $10
    db $f8, $d8, $01, $10   ; dy -8 dx -40 tile 1 attr $10
    db $f8, $e0, $02, $10   ; dy -8 dx -32 tile 2 attr $10
    db $f8, $e8, $02, $10   ; dy -8 dx -24 tile 2 attr $10
    db $f8, $f0, $11, $10   ; dy -8 dx -16 tile 17 attr $10
    db $f8, $f8, $12, $10   ; dy -8 dx -8 tile 18 attr $10
    db $f8, $00, $11, $10   ; dy -8 dx +0 tile 17 attr $10
    db $f8, $08, $20, $10   ; dy -8 dx +8 tile 32 attr $10
    db $f8, $10, $21, $10   ; dy -8 dx +16 tile 33 attr $10
    db $f8, $18, $22, $10   ; dy -8 dx +24 tile 34 attr $10
    db $80
Anim_1c_F06:   ; $6a7d 10 sprites
    db $f8, $eb, $00, $10   ; dy -8 dx -21 tile 0 attr $10
    db $f8, $f3, $01, $10   ; dy -8 dx -13 tile 1 attr $10
    db $f8, $fb, $02, $10   ; dy -8 dx -5 tile 2 attr $10
    db $f8, $03, $02, $10   ; dy -8 dx +3 tile 2 attr $10
    db $f8, $0b, $10, $10   ; dy -8 dx +11 tile 16 attr $10
    db $f8, $13, $11, $10   ; dy -8 dx +19 tile 17 attr $10
    db $f8, $1b, $11, $10   ; dy -8 dx +27 tile 17 attr $10
    db $f8, $23, $20, $10   ; dy -8 dx +35 tile 32 attr $10
    db $f8, $2b, $21, $10   ; dy -8 dx +43 tile 33 attr $10
    db $f8, $33, $22, $10   ; dy -8 dx +51 tile 34 attr $10
    db $80
Anim_1c_F07:   ; $6aa6 11 sprites
    db $f8, $08, $00, $10   ; dy -8 dx +8 tile 0 attr $10
    db $f8, $10, $01, $10   ; dy -8 dx +16 tile 1 attr $10
    db $f8, $18, $02, $10   ; dy -8 dx +24 tile 2 attr $10
    db $f8, $20, $02, $10   ; dy -8 dx +32 tile 2 attr $10
    db $f8, $30, $11, $10   ; dy -8 dx +48 tile 17 attr $10
    db $f8, $38, $11, $10   ; dy -8 dx +56 tile 17 attr $10
    db $f8, $28, $12, $10   ; dy -8 dx +40 tile 18 attr $10
    db $f8, $40, $20, $10   ; dy -8 dx +64 tile 32 attr $10
    db $f8, $48, $21, $10   ; dy -8 dx +72 tile 33 attr $10
    db $f0, $d0, $17, $10   ; dy -16 dx -48 tile 23 attr $10
    db $f6, $d8, $0d, $10   ; dy -10 dx -40 tile 13 attr $10
    db $80
Anim_1c_F08:   ; $6ad3 10 sprites
    db $f8, $19, $00, $10   ; dy -8 dx +25 tile 0 attr $10
    db $f8, $21, $01, $10   ; dy -8 dx +33 tile 1 attr $10
    db $f8, $29, $02, $10   ; dy -8 dx +41 tile 2 attr $10
    db $f8, $31, $02, $10   ; dy -8 dx +49 tile 2 attr $10
    db $f8, $39, $12, $10   ; dy -8 dx +57 tile 18 attr $10
    db $f8, $41, $11, $10   ; dy -8 dx +65 tile 17 attr $10
    db $f8, $49, $11, $10   ; dy -8 dx +73 tile 17 attr $10
    db $f8, $c8, $13, $10   ; dy -8 dx -56 tile 19 attr $10
    db $f5, $cb, $27, $10   ; dy -11 dx -53 tile 39 attr $10
    db $ed, $c8, $0d, $10   ; dy -19 dx -56 tile 13 attr $10
    db $80
Anim_1c_F09:   ; $6afc 10 sprites
    db $f8, $2c, $00, $10   ; dy -8 dx +44 tile 0 attr $10
    db $f8, $34, $01, $10   ; dy -8 dx +52 tile 1 attr $10
    db $f8, $3c, $02, $10   ; dy -8 dx +60 tile 2 attr $10
    db $f8, $44, $02, $10   ; dy -8 dx +68 tile 2 attr $10
    db $f8, $4c, $12, $10   ; dy -8 dx +76 tile 18 attr $10
    db $ef, $d0, $13, $10   ; dy -17 dx -48 tile 19 attr $10
    db $f7, $d0, $23, $10   ; dy -9 dx -48 tile 35 attr $10
    db $f3, $db, $24, $10   ; dy -13 dx -37 tile 36 attr $10
    db $ed, $d3, $27, $10   ; dy -19 dx -45 tile 39 attr $10
    db $e5, $d0, $0d, $10   ; dy -27 dx -48 tile 13 attr $10
    db $80
Anim_1c_F10:   ; $6b25 16 sprites
    db $f8, $41, $00, $10   ; dy -8 dx +65 tile 0 attr $10
    db $f8, $49, $01, $10   ; dy -8 dx +73 tile 1 attr $10
    db $f8, $c6, $03, $10   ; dy -8 dx -58 tile 3 attr $10
    db $f8, $de, $08, $50   ; dy -8 dx -34 tile 8 attr $50
    db $f0, $d6, $15, $10   ; dy -16 dx -42 tile 21 attr $10
    db $f8, $d6, $26, $10   ; dy -8 dx -42 tile 38 attr $10
    db $f8, $e6, $26, $10   ; dy -8 dx -26 tile 38 attr $10
    db $f8, $ce, $25, $10   ; dy -8 dx -50 tile 37 attr $10
    db $f8, $06, $17, $10   ; dy -8 dx +6 tile 23 attr $10
    db $f0, $ee, $0d, $30   ; dy -16 dx -18 tile 13 attr $30
    db $f8, $ee, $0e, $30   ; dy -8 dx -18 tile 14 attr $30
    db $f0, $e6, $0b, $10   ; dy -16 dx -26 tile 11 attr $10
    db $e8, $e8, $14, $10   ; dy -24 dx -24 tile 20 attr $10
    db $f8, $f6, $14, $10   ; dy -8 dx -10 tile 20 attr $10
    db $e8, $e0, $1d, $10   ; dy -24 dx -32 tile 29 attr $10
    db $f0, $de, $1f, $70   ; dy -16 dx -34 tile 31 attr $70
    db $80
Anim_1c_F11:   ; $6b66 25 sprites
    db $d8, $06, $13, $10   ; dy -40 dx +6 tile 19 attr $10
    db $f8, $ce, $03, $10   ; dy -8 dx -50 tile 3 attr $10
    db $f8, $d6, $04, $10   ; dy -8 dx -42 tile 4 attr $10
    db $f8, $de, $05, $10   ; dy -8 dx -34 tile 5 attr $10
    db $f8, $ee, $06, $10   ; dy -8 dx -18 tile 6 attr $10
    db $f8, $f6, $07, $10   ; dy -8 dx -10 tile 7 attr $10
    db $f8, $fe, $08, $10   ; dy -8 dx -2 tile 8 attr $10
    db $f0, $fe, $08, $70   ; dy -16 dx -2 tile 8 attr $70
    db $f8, $e6, $26, $10   ; dy -8 dx -26 tile 38 attr $10
    db $d8, $fe, $25, $30   ; dy -40 dx -2 tile 37 attr $30
    db $d0, $f6, $0d, $10   ; dy -48 dx -10 tile 13 attr $10
    db $d8, $f6, $0e, $10   ; dy -40 dx -10 tile 14 attr $10
    db $e8, $f6, $0f, $30   ; dy -24 dx -10 tile 15 attr $30
    db $f0, $d2, $0d, $10   ; dy -16 dx -46 tile 13 attr $10
    db $e0, $06, $18, $70   ; dy -32 dx +6 tile 24 attr $70
    db $e8, $06, $19, $30   ; dy -24 dx +6 tile 25 attr $30
    db $f0, $0e, $1f, $10   ; dy -16 dx +14 tile 31 attr $10
    db $f8, $0e, $2f, $10   ; dy -8 dx +14 tile 47 attr $10
    db $e8, $0e, $1c, $10   ; dy -24 dx +14 tile 28 attr $10
    db $e8, $fe, $1b, $10   ; dy -24 dx -2 tile 27 attr $10
    db $e0, $fe, $1b, $30   ; dy -32 dx -2 tile 27 attr $30
    db $f0, $06, $2d, $10   ; dy -16 dx +6 tile 45 attr $10
    db $f8, $06, $2e, $50   ; dy -8 dx +6 tile 46 attr $50
    db $f0, $f6, $1f, $30   ; dy -16 dx -10 tile 31 attr $30
    db $f0, $e4, $1d, $30   ; dy -16 dx -28 tile 29 attr $30
    db $80
Anim_1c_F12:   ; $6bcb 31 sprites
    db $f8, $28, $22, $10   ; dy -8 dx +40 tile 34 attr $10
    db $f8, $b8, $13, $10   ; dy -8 dx -72 tile 19 attr $10
    db $f0, $c2, $17, $10   ; dy -16 dx -62 tile 23 attr $10
    db $f0, $c8, $25, $10   ; dy -16 dx -56 tile 37 attr $10
    db $e8, $ef, $27, $50   ; dy -24 dx -17 tile 39 attr $50
    db $f8, $30, $28, $50   ; dy -8 dx +48 tile 40 attr $50
    db $d8, $f0, $18, $10   ; dy -40 dx -16 tile 24 attr $10
    db $e0, $04, $0c, $10   ; dy -32 dx +4 tile 12 attr $10
    db $d8, $08, $0a, $10   ; dy -40 dx +8 tile 10 attr $10
    db $d8, $10, $0b, $10   ; dy -40 dx +16 tile 11 attr $10
    db $d0, $0a, $09, $10   ; dy -48 dx +10 tile 9 attr $10
    db $d0, $f2, $19, $50   ; dy -48 dx -14 tile 25 attr $50
    db $e8, $d0, $0d, $30   ; dy -24 dx -48 tile 13 attr $30
    db $f0, $d0, $0e, $30   ; dy -16 dx -48 tile 14 attr $30
    db $f8, $c0, $18, $50   ; dy -8 dx -64 tile 24 attr $50
    db $f8, $d0, $15, $10   ; dy -8 dx -48 tile 21 attr $10
    db $d8, $e0, $14, $10   ; dy -40 dx -32 tile 20 attr $10
    db $f8, $d8, $14, $10   ; dy -8 dx -40 tile 20 attr $10
    db $f8, $c8, $1b, $10   ; dy -8 dx -56 tile 27 attr $10
    db $d8, $00, $2d, $70   ; dy -40 dx +0 tile 45 attr $70
    db $d8, $f8, $2e, $70   ; dy -40 dx -8 tile 46 attr $70
    db $d0, $fa, $1b, $30   ; dy -48 dx -6 tile 27 attr $30
    db $e8, $26, $1a, $10   ; dy -24 dx +38 tile 26 attr $10
    db $f0, $20, $14, $10   ; dy -16 dx +32 tile 20 attr $10
    db $f8, $18, $1d, $10   ; dy -8 dx +24 tile 29 attr $10
    db $f8, $38, $1c, $10   ; dy -8 dx +56 tile 28 attr $10
    db $f0, $26, $2a, $10   ; dy -16 dx +38 tile 42 attr $10
    db $f8, $20, $2b, $10   ; dy -8 dx +32 tile 43 attr $10
    db $d0, $02, $1f, $50   ; dy -48 dx +2 tile 31 attr $50
    db $e0, $0b, $1a, $50   ; dy -32 dx +11 tile 26 attr $50
    db $e0, $f4, $28, $10   ; dy -32 dx -12 tile 40 attr $10
    db $80
Anim_1c_F13:   ; $6c48 28 sprites
    db $ef, $18, $13, $10   ; dy -17 dx +24 tile 19 attr $10
    db $f7, $18, $23, $10   ; dy -9 dx +24 tile 35 attr $10
    db $f8, $b8, $13, $10   ; dy -8 dx -72 tile 19 attr $10
    db $f3, $23, $24, $10   ; dy -13 dx +35 tile 36 attr $10
    db $f8, $c8, $08, $10   ; dy -8 dx -56 tile 8 attr $10
    db $d8, $c8, $16, $30   ; dy -40 dx -56 tile 22 attr $30
    db $ed, $1b, $27, $10   ; dy -19 dx +27 tile 39 attr $10
    db $e5, $18, $0d, $10   ; dy -27 dx +24 tile 13 attr $10
    db $d0, $d8, $0d, $30   ; dy -48 dx -40 tile 13 attr $30
    db $d8, $d8, $0e, $30   ; dy -40 dx -40 tile 14 attr $30
    db $d8, $d0, $0f, $30   ; dy -40 dx -48 tile 15 attr $30
    db $e0, $d7, $19, $30   ; dy -32 dx -41 tile 25 attr $30
    db $e8, $d8, $29, $30   ; dy -24 dx -40 tile 41 attr $30
    db $f8, $f0, $28, $50   ; dy -8 dx -16 tile 40 attr $50
    db $f0, $c7, $0a, $10   ; dy -16 dx -57 tile 10 attr $10
    db $e0, $c7, $2c, $10   ; dy -32 dx -57 tile 44 attr $10
    db $e0, $cf, $1b, $10   ; dy -32 dx -49 tile 27 attr $10
    db $f8, $e8, $2b, $30   ; dy -8 dx -24 tile 43 attr $30
    db $f8, $e0, $2c, $30   ; dy -8 dx -32 tile 44 attr $30
    db $f8, $d8, $2d, $30   ; dy -8 dx -40 tile 45 attr $30
    db $f8, $d0, $2e, $30   ; dy -8 dx -48 tile 46 attr $30
    db $f0, $c0, $1f, $30   ; dy -16 dx -64 tile 31 attr $30
    db $f8, $c0, $2f, $30   ; dy -8 dx -64 tile 47 attr $30
    db $e8, $bf, $1c, $30   ; dy -24 dx -65 tile 28 attr $30
    db $f0, $df, $1d, $30   ; dy -16 dx -33 tile 29 attr $30
    db $f0, $cf, $1e, $30   ; dy -16 dx -49 tile 30 attr $30
    db $e8, $c8, $1b, $30   ; dy -24 dx -56 tile 27 attr $30
    db $e8, $d0, $2e, $50   ; dy -24 dx -48 tile 46 attr $50
    db $80
Anim_1c_F14:   ; $6cb9 22 sprites
    db $f0, $30, $13, $10   ; dy -16 dx +48 tile 19 attr $10
    db $f8, $e4, $03, $10   ; dy -8 dx -28 tile 3 attr $10
    db $f8, $c8, $13, $30   ; dy -8 dx -56 tile 19 attr $30
    db $f8, $fc, $08, $50   ; dy -8 dx -4 tile 8 attr $50
    db $f5, $d0, $27, $10   ; dy -11 dx -48 tile 39 attr $10
    db $f8, $ec, $25, $10   ; dy -8 dx -20 tile 37 attr $10
    db $f0, $28, $25, $30   ; dy -16 dx +40 tile 37 attr $30
    db $f8, $f4, $26, $10   ; dy -8 dx -12 tile 38 attr $10
    db $f8, $04, $26, $10   ; dy -8 dx +4 tile 38 attr $10
    db $f0, $f4, $15, $10   ; dy -16 dx -12 tile 21 attr $10
    db $f0, $0c, $16, $10   ; dy -16 dx +12 tile 22 attr $10
    db $ed, $ca, $0d, $10   ; dy -19 dx -54 tile 13 attr $10
    db $e8, $20, $0d, $10   ; dy -24 dx +32 tile 13 attr $10
    db $f0, $04, $0b, $10   ; dy -16 dx +4 tile 11 attr $10
    db $f0, $20, $0e, $10   ; dy -16 dx +32 tile 14 attr $10
    db $f8, $0c, $0e, $30   ; dy -8 dx +12 tile 14 attr $30
    db $f8, $30, $18, $70   ; dy -8 dx +48 tile 24 attr $70
    db $f8, $20, $28, $50   ; dy -8 dx +32 tile 40 attr $50
    db $e8, $06, $14, $10   ; dy -24 dx +6 tile 20 attr $10
    db $e8, $fe, $1d, $10   ; dy -24 dx -2 tile 29 attr $10
    db $f8, $28, $1b, $30   ; dy -8 dx +40 tile 27 attr $30
    db $f0, $fc, $1f, $70   ; dy -16 dx -4 tile 31 attr $70
    db $80
Anim_1c_F15:   ; $6d12 23 sprites
    db $f8, $28, $08, $30   ; dy -8 dx +40 tile 8 attr $30
    db $d8, $28, $16, $10   ; dy -40 dx +40 tile 22 attr $10
    db $d0, $18, $0d, $10   ; dy -48 dx +24 tile 13 attr $10
    db $d8, $18, $0e, $10   ; dy -40 dx +24 tile 14 attr $10
    db $d8, $20, $0f, $10   ; dy -40 dx +32 tile 15 attr $10
    db $e0, $19, $19, $10   ; dy -32 dx +25 tile 25 attr $10
    db $e8, $18, $29, $10   ; dy -24 dx +24 tile 41 attr $10
    db $f0, $29, $0a, $10   ; dy -16 dx +41 tile 10 attr $10
    db $f8, $00, $28, $70   ; dy -8 dx +0 tile 40 attr $70
    db $f8, $30, $2f, $10   ; dy -8 dx +48 tile 47 attr $10
    db $f0, $31, $1f, $10   ; dy -16 dx +49 tile 31 attr $10
    db $e8, $28, $1b, $10   ; dy -24 dx +40 tile 27 attr $10
    db $e8, $30, $1c, $10   ; dy -24 dx +48 tile 28 attr $10
    db $f0, $21, $1e, $10   ; dy -16 dx +33 tile 30 attr $10
    db $f8, $08, $2b, $10   ; dy -8 dx +8 tile 43 attr $10
    db $f8, $10, $2c, $10   ; dy -8 dx +16 tile 44 attr $10
    db $f8, $18, $2d, $10   ; dy -8 dx +24 tile 45 attr $10
    db $f8, $20, $2e, $10   ; dy -8 dx +32 tile 46 attr $10
    db $e0, $29, $2c, $30   ; dy -32 dx +41 tile 44 attr $30
    db $e0, $21, $1b, $30   ; dy -32 dx +33 tile 27 attr $30
    db $f0, $12, $1d, $10   ; dy -16 dx +18 tile 29 attr $10
    db $f8, $f8, $2a, $50   ; dy -8 dx -8 tile 42 attr $50
    db $e8, $20, $2e, $50   ; dy -24 dx +32 tile 46 attr $50
    db $80
Anim_1c_F16:   ; $6d6f 13 sprites
    db $f8, $0c, $22, $10   ; dy -8 dx +12 tile 34 attr $10
    db $f0, $f7, $13, $10   ; dy -16 dx -9 tile 19 attr $10
    db $f8, $04, $04, $30   ; dy -8 dx +4 tile 4 attr $30
    db $f8, $fc, $07, $30   ; dy -8 dx -4 tile 7 attr $30
    db $f8, $d0, $17, $10   ; dy -8 dx -48 tile 23 attr $10
    db $e8, $f5, $14, $10   ; dy -24 dx -11 tile 20 attr $10
    db $f0, $04, $14, $10   ; dy -16 dx +4 tile 20 attr $10
    db $f8, $14, $14, $10   ; dy -8 dx +20 tile 20 attr $10
    db $f8, $ec, $2b, $10   ; dy -8 dx -20 tile 43 attr $10
    db $f8, $f4, $2c, $10   ; dy -8 dx -12 tile 44 attr $10
    db $e8, $0a, $1a, $10   ; dy -24 dx +10 tile 26 attr $10
    db $f0, $0a, $2a, $10   ; dy -16 dx +10 tile 42 attr $10
    db $f0, $fc, $1d, $30   ; dy -16 dx -4 tile 29 attr $30
    db $80
Anim_1c_F17:   ; $6da4 6 sprites
    db $ef, $00, $13, $10   ; dy -17 dx +0 tile 19 attr $10
    db $f7, $00, $23, $10   ; dy -9 dx +0 tile 35 attr $10
    db $f3, $0b, $24, $10   ; dy -13 dx +11 tile 36 attr $10
    db $f0, $e5, $27, $10   ; dy -16 dx -27 tile 39 attr $10
    db $ed, $03, $27, $10   ; dy -19 dx +3 tile 39 attr $10
    db $e5, $00, $0d, $10   ; dy -27 dx +0 tile 13 attr $10
    db $80
Anim_1c_F18:   ; $6dbd 5 sprites
    db $f0, $f8, $17, $10   ; dy -16 dx -8 tile 23 attr $10
    db $f8, $f7, $27, $10   ; dy -8 dx -9 tile 39 attr $10
    db $f8, $f0, $0d, $10   ; dy -8 dx -16 tile 13 attr $10
    db $e8, $08, $0d, $30   ; dy -24 dx +8 tile 13 attr $30
    db $f8, $08, $14, $10   ; dy -8 dx +8 tile 20 attr $10
    db $80
Anim_1c_F19:   ; $6dd2 14 sprites
    db $f8, $c6, $03, $10   ; dy -8 dx -58 tile 3 attr $10
    db $f8, $de, $08, $50   ; dy -8 dx -34 tile 8 attr $50
    db $f0, $d6, $15, $10   ; dy -16 dx -42 tile 21 attr $10
    db $f8, $d6, $26, $10   ; dy -8 dx -42 tile 38 attr $10
    db $f8, $e6, $26, $10   ; dy -8 dx -26 tile 38 attr $10
    db $f8, $ce, $25, $10   ; dy -8 dx -50 tile 37 attr $10
    db $f8, $06, $17, $10   ; dy -8 dx +6 tile 23 attr $10
    db $f0, $ee, $0d, $30   ; dy -16 dx -18 tile 13 attr $30
    db $f8, $ee, $0e, $30   ; dy -8 dx -18 tile 14 attr $30
    db $f0, $e6, $0b, $10   ; dy -16 dx -26 tile 11 attr $10
    db $e8, $e8, $14, $10   ; dy -24 dx -24 tile 20 attr $10
    db $f8, $f6, $14, $10   ; dy -8 dx -10 tile 20 attr $10
    db $e8, $e0, $1d, $10   ; dy -24 dx -32 tile 29 attr $10
    db $f0, $de, $1f, $70   ; dy -16 dx -34 tile 31 attr $70
Anim_1c_F20:   ; $6e0a empty frame = the $80 end above (shared)
    db $80
Anim_1d_TwinSlash:   ; $6e0b animation $1d — TwinSlash, Massacre, EvilSlash, DrakSlash, BeastCut, SquallHit (+2)
    dw Anim_1d_F00
    dw Anim_1d_F01
    dw Anim_1d_F02
    dw Anim_1d_F03
    dw Anim_1d_F04
    dw Anim_1d_F05
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
    dw Anim_1d_F06
Anim_1d_F00:   ; $6e4b 4 sprites
    db $d8, $03, $00, $00   ; dy -40 dx +3 tile 0 attr $00
    db $d8, $0b, $01, $00   ; dy -40 dx +11 tile 1 attr $00
    db $d0, $03, $02, $00   ; dy -48 dx +3 tile 2 attr $00
    db $d0, $0b, $03, $00   ; dy -48 dx +11 tile 3 attr $00
    db $80
Anim_1d_F01:   ; $6e5c 10 sprites
    db $dc, $00, $00, $00   ; dy -36 dx +0 tile 0 attr $00
    db $dc, $08, $01, $00   ; dy -36 dx +8 tile 1 attr $00
    db $d4, $00, $02, $00   ; dy -44 dx +0 tile 2 attr $00
    db $d4, $08, $03, $00   ; dy -44 dx +8 tile 3 attr $00
    db $cc, $04, $04, $00   ; dy -52 dx +4 tile 4 attr $00
    db $e4, $f8, $00, $60   ; dy -28 dx -8 tile 0 attr $60
    db $e4, $f0, $01, $60   ; dy -28 dx -16 tile 1 attr $60
    db $ec, $f8, $02, $60   ; dy -20 dx -8 tile 2 attr $60
    db $ec, $f0, $03, $60   ; dy -20 dx -16 tile 3 attr $60
    db $f4, $f4, $04, $60   ; dy -12 dx -12 tile 4 attr $60
    db $80
Anim_1d_F02:   ; $6e85 11 sprites
    db $f0, $fb, $05, $60   ; dy -16 dx -5 tile 5 attr $60
    db $f0, $f3, $06, $60   ; dy -16 dx -13 tile 6 attr $60
    db $e8, $03, $07, $60   ; dy -24 dx +3 tile 7 attr $60
    db $e8, $fb, $08, $60   ; dy -24 dx -5 tile 8 attr $60
    db $e8, $f3, $09, $60   ; dy -24 dx -13 tile 9 attr $60
    db $e0, $03, $0a, $60   ; dy -32 dx +3 tile 10 attr $60
    db $e0, $fb, $0b, $60   ; dy -32 dx -5 tile 11 attr $60
    db $e0, $f3, $0c, $60   ; dy -32 dx -13 tile 12 attr $60
    db $d8, $07, $0d, $60   ; dy -40 dx +7 tile 13 attr $60
    db $d8, $ff, $0e, $60   ; dy -40 dx -1 tile 14 attr $60
    db $d0, $08, $0f, $60   ; dy -48 dx +8 tile 15 attr $60
    db $80
Anim_1d_F03:   ; $6eb2 6 sprites
    db $f0, $f3, $11, $00   ; dy -16 dx -13 tile 17 attr $00
    db $e8, $f8, $11, $00   ; dy -24 dx -8 tile 17 attr $00
    db $e0, $fe, $11, $00   ; dy -32 dx -2 tile 17 attr $00
    db $d8, $03, $11, $00   ; dy -40 dx +3 tile 17 attr $00
    db $d0, $08, $11, $00   ; dy -48 dx +8 tile 17 attr $00
    db $f8, $ee, $11, $00   ; dy -8 dx -18 tile 17 attr $00
    db $80
Anim_1d_F04:   ; $6ecb 5 sprites
    db $f0, $f3, $11, $00   ; dy -16 dx -13 tile 17 attr $00
    db $e8, $f8, $11, $00   ; dy -24 dx -8 tile 17 attr $00
    db $f8, $ee, $11, $00   ; dy -8 dx -18 tile 17 attr $00
    db $e0, $fe, $12, $00   ; dy -32 dx -2 tile 18 attr $00
    db $d8, $03, $12, $00   ; dy -40 dx +3 tile 18 attr $00
    db $80
Anim_1d_F05:   ; $6ee0 3 sprites
    db $f8, $ee, $12, $00   ; dy -8 dx -18 tile 18 attr $00
    db $f0, $f3, $12, $00   ; dy -16 dx -13 tile 18 attr $00
    db $e8, $f8, $12, $00   ; dy -24 dx -8 tile 18 attr $00
Anim_1d_F06:   ; $6eec empty frame = the $80 end above (shared)
    db $80
Anim_1e_FireSlash:   ; $6eed animation $1e — FireSlash
    dw Anim_1e_F00
    dw Anim_1e_F01
    dw Anim_1e_F02
    dw Anim_1e_F03
    dw Anim_1e_F04
    dw Anim_1e_F05
    dw Anim_1e_F06
    dw Anim_1e_F07
    dw Anim_1e_F08
    dw Anim_1e_F09
    dw Anim_1e_F10
    dw Anim_1e_F11
    dw Anim_1e_F12
    dw Anim_1e_F13
    dw Anim_1e_F14
    dw Anim_1e_F15
    dw Anim_1e_F16
    dw Anim_1e_F17
    dw Anim_1e_F18
    dw Anim_1e_F19
    dw Anim_1e_F20
    dw Anim_1e_F20
    dw Anim_1e_F20
    dw Anim_1e_F20
    dw Anim_1e_F20
    dw Anim_1e_F20
    dw Anim_1e_F20
    dw Anim_1e_F20
    dw Anim_1e_F20
    dw Anim_1e_F20
    dw Anim_1e_F20
    dw Anim_1e_F20
Anim_1e_F00:   ; $6f2d 4 sprites
    db $d8, $03, $1c, $00   ; dy -40 dx +3 tile 28 attr $00
    db $d8, $0b, $1d, $00   ; dy -40 dx +11 tile 29 attr $00
    db $d0, $03, $1e, $00   ; dy -48 dx +3 tile 30 attr $00
    db $d0, $0b, $1f, $00   ; dy -48 dx +11 tile 31 attr $00
    db $80
Anim_1e_F01:   ; $6f3e 10 sprites
    db $dc, $00, $1c, $00   ; dy -36 dx +0 tile 28 attr $00
    db $dc, $08, $1d, $00   ; dy -36 dx +8 tile 29 attr $00
    db $cf, $01, $26, $00   ; dy -49 dx +1 tile 38 attr $00
    db $d4, $00, $1e, $00   ; dy -44 dx +0 tile 30 attr $00
    db $d4, $08, $1f, $00   ; dy -44 dx +8 tile 31 attr $00
    db $e4, $f8, $1c, $60   ; dy -28 dx -8 tile 28 attr $60
    db $e4, $f0, $1d, $60   ; dy -28 dx -16 tile 29 attr $60
    db $f1, $f7, $26, $60   ; dy -15 dx -9 tile 38 attr $60
    db $ec, $f8, $1e, $60   ; dy -20 dx -8 tile 30 attr $60
    db $ec, $f0, $1f, $60   ; dy -20 dx -16 tile 31 attr $60
    db $80
Anim_1e_F02:   ; $6f67 10 sprites
    db $d0, $00, $20, $00   ; dy -48 dx +0 tile 32 attr $00
    db $d0, $08, $21, $00   ; dy -48 dx +8 tile 33 attr $00
    db $d8, $fc, $22, $00   ; dy -40 dx -4 tile 34 attr $00
    db $d8, $04, $23, $00   ; dy -40 dx +4 tile 35 attr $00
    db $e0, $f8, $24, $00   ; dy -32 dx -8 tile 36 attr $00
    db $e0, $00, $25, $00   ; dy -32 dx +0 tile 37 attr $00
    db $e8, $f0, $26, $00   ; dy -24 dx -16 tile 38 attr $00
    db $e8, $f8, $27, $00   ; dy -24 dx -8 tile 39 attr $00
    db $f0, $f4, $28, $00   ; dy -16 dx -12 tile 40 attr $00
    db $f8, $f0, $29, $00   ; dy -8 dx -16 tile 41 attr $00
    db $80
Anim_1e_F03:   ; $6f90 12 sprites
    db $d8, $03, $21, $00   ; dy -40 dx +3 tile 33 attr $00
    db $e0, $f7, $22, $00   ; dy -32 dx -9 tile 34 attr $00
    db $e0, $ff, $23, $00   ; dy -32 dx -1 tile 35 attr $00
    db $e8, $fb, $25, $00   ; dy -24 dx -5 tile 37 attr $00
    db $f0, $eb, $26, $00   ; dy -16 dx -21 tile 38 attr $00
    db $f0, $f3, $27, $00   ; dy -16 dx -13 tile 39 attr $00
    db $f8, $ef, $28, $00   ; dy -8 dx -17 tile 40 attr $00
    db $d0, $08, $2a, $00   ; dy -48 dx +8 tile 42 attr $00
    db $d8, $fb, $2a, $00   ; dy -40 dx -5 tile 42 attr $00
    db $e8, $f3, $2a, $00   ; dy -24 dx -13 tile 42 attr $00
    db $e0, $eb, $2b, $00   ; dy -32 dx -21 tile 43 attr $00
    db $d0, $00, $2b, $00   ; dy -48 dx +0 tile 43 attr $00
    db $80
Anim_1e_F04:   ; $6fc1 8 sprites
    db $d0, $08, $2c, $00   ; dy -48 dx +8 tile 44 attr $00
    db $d8, $03, $2c, $00   ; dy -40 dx +3 tile 44 attr $00
    db $e0, $fe, $2c, $00   ; dy -32 dx -2 tile 44 attr $00
    db $e8, $f8, $2c, $00   ; dy -24 dx -8 tile 44 attr $00
    db $f0, $f3, $2c, $00   ; dy -16 dx -13 tile 44 attr $00
    db $f8, $ee, $2c, $00   ; dy -8 dx -18 tile 44 attr $00
    db $f0, $eb, $2a, $00   ; dy -16 dx -21 tile 42 attr $00
    db $e0, $f6, $2b, $00   ; dy -32 dx -10 tile 43 attr $00
    db $80
Anim_1e_F05:   ; $6fe2 6 sprites
    db $e8, $f8, $2c, $00   ; dy -24 dx -8 tile 44 attr $00
    db $f0, $f3, $2c, $00   ; dy -16 dx -13 tile 44 attr $00
    db $f8, $ee, $2c, $00   ; dy -8 dx -18 tile 44 attr $00
    db $d8, $03, $2d, $00   ; dy -40 dx +3 tile 45 attr $00
    db $e0, $fe, $2d, $00   ; dy -32 dx -2 tile 45 attr $00
    db $e8, $f0, $20, $00   ; dy -24 dx -16 tile 32 attr $00
    db $80
Anim_1e_F06:   ; $6ffb 3 sprites
    db $e8, $fa, $2d, $00   ; dy -24 dx -6 tile 45 attr $00
    db $f0, $f5, $2d, $00   ; dy -16 dx -11 tile 45 attr $00
    db $f8, $f0, $2d, $00   ; dy -8 dx -16 tile 45 attr $00
    db $80
Anim_1e_F07:   ; $7008 3 sprites
    db $f0, $fc, $27, $00   ; dy -16 dx -4 tile 39 attr $00
    db $f8, $fc, $28, $00   ; dy -8 dx -4 tile 40 attr $00
    db $e8, $fc, $24, $20   ; dy -24 dx -4 tile 36 attr $20
    db $80
Anim_1e_F08:   ; $7015 8 sprites
    db $e8, $fc, $02, $00   ; dy -24 dx -4 tile 2 attr $00
    db $f0, $fc, $27, $20   ; dy -16 dx -4 tile 39 attr $20
    db $f8, $fc, $27, $00   ; dy -8 dx -4 tile 39 attr $00
    db $e0, $fc, $21, $20   ; dy -32 dx -4 tile 33 attr $20
    db $f8, $f4, $21, $00   ; dy -8 dx -12 tile 33 attr $00
    db $f0, $f0, $20, $00   ; dy -16 dx -16 tile 32 attr $00
    db $f8, $04, $21, $20   ; dy -8 dx +4 tile 33 attr $20
    db $f0, $08, $20, $20   ; dy -16 dx +8 tile 32 attr $20
    db $80
Anim_1e_F09:   ; $7036 9 sprites
    db $f0, $f6, $02, $00   ; dy -16 dx -10 tile 2 attr $00
    db $e8, $f9, $00, $00   ; dy -24 dx -7 tile 0 attr $00
    db $f8, $f0, $05, $00   ; dy -8 dx -16 tile 5 attr $00
    db $f8, $08, $05, $20   ; dy -8 dx +8 tile 5 attr $20
    db $f0, $03, $02, $20   ; dy -16 dx +3 tile 2 attr $20
    db $f0, $fe, $03, $00   ; dy -16 dx -2 tile 3 attr $00
    db $e8, $ff, $04, $00   ; dy -24 dx -1 tile 4 attr $00
    db $f8, $f8, $18, $00   ; dy -8 dx -8 tile 24 attr $00
    db $f8, $00, $18, $20   ; dy -8 dx +0 tile 24 attr $20
    db $80
Anim_1e_F10:   ; $705b 19 sprites
    db $f8, $05, $11, $00   ; dy -8 dx +5 tile 17 attr $00
    db $f8, $f5, $0f, $00   ; dy -8 dx -11 tile 15 attr $00
    db $f0, $0b, $09, $20   ; dy -16 dx +11 tile 9 attr $20
    db $f0, $03, $0a, $20   ; dy -16 dx +3 tile 10 attr $20
    db $f0, $fb, $0b, $20   ; dy -16 dx -5 tile 11 attr $20
    db $f0, $f3, $0c, $20   ; dy -16 dx -13 tile 12 attr $20
    db $f0, $eb, $0d, $20   ; dy -16 dx -21 tile 13 attr $20
    db $e8, $ff, $06, $20   ; dy -24 dx -1 tile 6 attr $20
    db $e8, $f7, $07, $20   ; dy -24 dx -9 tile 7 attr $20
    db $e8, $ef, $08, $20   ; dy -24 dx -17 tile 8 attr $20
    db $e0, $01, $02, $20   ; dy -32 dx +1 tile 2 attr $20
    db $e0, $f9, $03, $20   ; dy -32 dx -7 tile 3 attr $20
    db $e0, $f1, $04, $20   ; dy -32 dx -15 tile 4 attr $20
    db $d8, $fe, $00, $20   ; dy -40 dx -2 tile 0 attr $20
    db $d8, $f6, $01, $20   ; dy -40 dx -10 tile 1 attr $20
    db $e8, $07, $05, $20   ; dy -24 dx +7 tile 5 attr $20
    db $f8, $ed, $17, $20   ; dy -8 dx -19 tile 23 attr $20
    db $f8, $0d, $13, $20   ; dy -8 dx +13 tile 19 attr $20
    db $f8, $fd, $19, $00   ; dy -8 dx -3 tile 25 attr $00
    db $80
Anim_1e_F11:   ; $70a8 19 sprites
    db $f8, $f3, $11, $20   ; dy -8 dx -13 tile 17 attr $20
    db $f8, $03, $0f, $20   ; dy -8 dx +3 tile 15 attr $20
    db $f0, $ed, $09, $00   ; dy -16 dx -19 tile 9 attr $00
    db $f0, $f5, $0a, $00   ; dy -16 dx -11 tile 10 attr $00
    db $f0, $fd, $0b, $00   ; dy -16 dx -3 tile 11 attr $00
    db $f0, $05, $0c, $00   ; dy -16 dx +5 tile 12 attr $00
    db $f0, $0d, $0d, $00   ; dy -16 dx +13 tile 13 attr $00
    db $e8, $f9, $06, $00   ; dy -24 dx -7 tile 6 attr $00
    db $e8, $01, $07, $00   ; dy -24 dx +1 tile 7 attr $00
    db $e8, $09, $08, $00   ; dy -24 dx +9 tile 8 attr $00
    db $e0, $f7, $02, $00   ; dy -32 dx -9 tile 2 attr $00
    db $e0, $ff, $03, $00   ; dy -32 dx -1 tile 3 attr $00
    db $e0, $07, $04, $00   ; dy -32 dx +7 tile 4 attr $00
    db $d8, $fa, $00, $00   ; dy -40 dx -6 tile 0 attr $00
    db $d8, $02, $01, $00   ; dy -40 dx +2 tile 1 attr $00
    db $e8, $f1, $05, $00   ; dy -24 dx -15 tile 5 attr $00
    db $f8, $0b, $17, $00   ; dy -8 dx +11 tile 23 attr $00
    db $f8, $eb, $13, $00   ; dy -8 dx -21 tile 19 attr $00
    db $f8, $fb, $15, $00   ; dy -8 dx -5 tile 21 attr $00
    db $80
Anim_1e_F12:   ; $70f5 24 sprites
    db $f8, $f4, $14, $00   ; dy -8 dx -12 tile 20 attr $00
    db $f8, $fc, $15, $00   ; dy -8 dx -4 tile 21 attr $00
    db $f8, $04, $16, $00   ; dy -8 dx +4 tile 22 attr $00
    db $f0, $fd, $10, $00   ; dy -16 dx -3 tile 16 attr $00
    db $f0, $05, $11, $00   ; dy -16 dx +5 tile 17 attr $00
    db $f0, $0d, $12, $00   ; dy -16 dx +13 tile 18 attr $00
    db $f0, $ed, $0e, $00   ; dy -16 dx -19 tile 14 attr $00
    db $e8, $eb, $09, $00   ; dy -24 dx -21 tile 9 attr $00
    db $e8, $f3, $0a, $00   ; dy -24 dx -13 tile 10 attr $00
    db $e8, $fb, $0b, $00   ; dy -24 dx -5 tile 11 attr $00
    db $e8, $03, $0c, $00   ; dy -24 dx +3 tile 12 attr $00
    db $e8, $0b, $0d, $00   ; dy -24 dx +11 tile 13 attr $00
    db $e0, $f7, $06, $00   ; dy -32 dx -9 tile 6 attr $00
    db $e0, $ff, $07, $00   ; dy -32 dx -1 tile 7 attr $00
    db $e0, $07, $08, $00   ; dy -32 dx +7 tile 8 attr $00
    db $d8, $f5, $02, $00   ; dy -40 dx -11 tile 2 attr $00
    db $d8, $fd, $03, $00   ; dy -40 dx -3 tile 3 attr $00
    db $d0, $f8, $00, $00   ; dy -48 dx -8 tile 0 attr $00
    db $d0, $00, $01, $00   ; dy -48 dx +0 tile 1 attr $00
    db $e0, $ef, $05, $00   ; dy -32 dx -17 tile 5 attr $00
    db $f0, $f5, $18, $00   ; dy -16 dx -11 tile 24 attr $00
    db $f8, $0c, $1a, $00   ; dy -8 dx +12 tile 26 attr $00
    db $f8, $ec, $13, $00   ; dy -8 dx -20 tile 19 attr $00
    db $d8, $05, $0d, $00   ; dy -40 dx +5 tile 13 attr $00
    db $80
Anim_1e_F13:   ; $7156 24 sprites
    db $f8, $0c, $13, $20   ; dy -8 dx +12 tile 19 attr $20
    db $f8, $04, $14, $20   ; dy -8 dx +4 tile 20 attr $20
    db $f8, $ec, $17, $20   ; dy -8 dx -20 tile 23 attr $20
    db $f0, $fb, $10, $20   ; dy -16 dx -5 tile 16 attr $20
    db $f0, $f3, $11, $20   ; dy -16 dx -13 tile 17 attr $20
    db $f0, $eb, $12, $20   ; dy -16 dx -21 tile 18 attr $20
    db $f0, $0b, $0e, $20   ; dy -16 dx +11 tile 14 attr $20
    db $f0, $03, $0f, $20   ; dy -16 dx +3 tile 15 attr $20
    db $e8, $0d, $09, $20   ; dy -24 dx +13 tile 9 attr $20
    db $e8, $05, $0a, $20   ; dy -24 dx +5 tile 10 attr $20
    db $e8, $fd, $0b, $20   ; dy -24 dx -3 tile 11 attr $20
    db $e8, $f5, $0c, $20   ; dy -24 dx -11 tile 12 attr $20
    db $e8, $ed, $0d, $20   ; dy -24 dx -19 tile 13 attr $20
    db $e0, $01, $06, $20   ; dy -32 dx +1 tile 6 attr $20
    db $e0, $f9, $07, $20   ; dy -32 dx -7 tile 7 attr $20
    db $e0, $f1, $08, $20   ; dy -32 dx -15 tile 8 attr $20
    db $d8, $03, $02, $20   ; dy -40 dx +3 tile 2 attr $20
    db $d8, $fb, $03, $20   ; dy -40 dx -5 tile 3 attr $20
    db $d8, $f3, $04, $20   ; dy -40 dx -13 tile 4 attr $20
    db $d0, $00, $00, $20   ; dy -48 dx +0 tile 0 attr $20
    db $d0, $f8, $01, $20   ; dy -48 dx -8 tile 1 attr $20
    db $e0, $09, $05, $20   ; dy -32 dx +9 tile 5 attr $20
    db $f8, $f4, $18, $00   ; dy -8 dx -12 tile 24 attr $00
    db $f8, $fc, $11, $00   ; dy -8 dx -4 tile 17 attr $00
    db $80
Anim_1e_F14:   ; $71b7 19 sprites
    db $f8, $f0, $11, $20   ; dy -8 dx -16 tile 17 attr $20
    db $f8, $e8, $13, $00   ; dy -8 dx -24 tile 19 attr $00
    db $f8, $f8, $15, $00   ; dy -8 dx -8 tile 21 attr $00
    db $f8, $08, $0f, $20   ; dy -8 dx +8 tile 15 attr $20
    db $f0, $e8, $09, $00   ; dy -16 dx -24 tile 9 attr $00
    db $f0, $f0, $0a, $00   ; dy -16 dx -16 tile 10 attr $00
    db $f0, $f8, $0b, $00   ; dy -16 dx -8 tile 11 attr $00
    db $f0, $08, $0c, $00   ; dy -16 dx +8 tile 12 attr $00
    db $f8, $10, $13, $20   ; dy -8 dx +16 tile 19 attr $20
    db $f0, $10, $09, $20   ; dy -16 dx +16 tile 9 attr $20
    db $f8, $00, $0b, $00   ; dy -8 dx +0 tile 11 attr $00
    db $f0, $00, $07, $00   ; dy -16 dx +0 tile 7 attr $00
    db $e8, $f4, $02, $00   ; dy -24 dx -12 tile 2 attr $00
    db $e8, $fc, $03, $00   ; dy -24 dx -4 tile 3 attr $00
    db $e8, $04, $04, $00   ; dy -24 dx +4 tile 4 attr $00
    db $e0, $f7, $00, $00   ; dy -32 dx -9 tile 0 attr $00
    db $e0, $ff, $01, $00   ; dy -32 dx -1 tile 1 attr $00
    db $e8, $0b, $24, $00   ; dy -24 dx +11 tile 36 attr $00
    db $e8, $ed, $04, $20   ; dy -24 dx -19 tile 4 attr $20
    db $80
Anim_1e_F15:   ; $7204 23 sprites
    db $f8, $05, $11, $00   ; dy -8 dx +5 tile 17 attr $00
    db $f8, $f5, $0f, $00   ; dy -8 dx -11 tile 15 attr $00
    db $f8, $ed, $17, $20   ; dy -8 dx -19 tile 23 attr $20
    db $f8, $0d, $13, $20   ; dy -8 dx +13 tile 19 attr $20
    db $f8, $fd, $19, $00   ; dy -8 dx -3 tile 25 attr $00
    db $f0, $f8, $0b, $20   ; dy -16 dx -8 tile 11 attr $20
    db $f0, $f0, $0c, $20   ; dy -16 dx -16 tile 12 attr $20
    db $f0, $e8, $0d, $20   ; dy -16 dx -24 tile 13 attr $20
    db $f0, $08, $0a, $20   ; dy -16 dx +8 tile 10 attr $20
    db $f0, $00, $19, $00   ; dy -16 dx +0 tile 25 attr $00
    db $e8, $f0, $07, $20   ; dy -24 dx -16 tile 7 attr $20
    db $e8, $e8, $08, $20   ; dy -24 dx -24 tile 8 attr $20
    db $e0, $f2, $03, $20   ; dy -32 dx -14 tile 3 attr $20
    db $e0, $ea, $04, $20   ; dy -32 dx -22 tile 4 attr $20
    db $d8, $ef, $01, $20   ; dy -40 dx -17 tile 1 attr $20
    db $e8, $08, $06, $20   ; dy -24 dx +8 tile 6 attr $20
    db $e8, $00, $09, $00   ; dy -24 dx +0 tile 9 attr $00
    db $e8, $f8, $09, $20   ; dy -24 dx -8 tile 9 attr $20
    db $e8, $10, $0d, $00   ; dy -24 dx +16 tile 13 attr $00
    db $e0, $04, $08, $20   ; dy -32 dx +4 tile 8 attr $20
    db $e0, $0c, $05, $20   ; dy -32 dx +12 tile 5 attr $20
    db $d8, $06, $04, $00   ; dy -40 dx +6 tile 4 attr $00
    db $f0, $10, $1a, $00   ; dy -16 dx +16 tile 26 attr $00
    db $80
Anim_1e_F16:   ; $7261 26 sprites
    db $f8, $e8, $17, $20   ; dy -8 dx -24 tile 23 attr $20
    db $f8, $f0, $18, $00   ; dy -8 dx -16 tile 24 attr $00
    db $f8, $f8, $11, $00   ; dy -8 dx -8 tile 17 attr $00
    db $f8, $10, $13, $20   ; dy -8 dx +16 tile 19 attr $20
    db $f8, $08, $14, $20   ; dy -8 dx +8 tile 20 attr $20
    db $f8, $00, $19, $00   ; dy -8 dx +0 tile 25 attr $00
    db $f0, $f0, $11, $20   ; dy -16 dx -16 tile 17 attr $20
    db $f0, $10, $0e, $20   ; dy -16 dx +16 tile 14 attr $20
    db $f0, $08, $0f, $20   ; dy -16 dx +8 tile 15 attr $20
    db $e8, $10, $09, $20   ; dy -24 dx +16 tile 9 attr $20
    db $f0, $e8, $0e, $00   ; dy -16 dx -24 tile 14 attr $00
    db $e8, $e8, $09, $00   ; dy -24 dx -24 tile 9 attr $00
    db $e8, $f0, $04, $00   ; dy -24 dx -16 tile 4 attr $00
    db $f0, $00, $04, $20   ; dy -16 dx +0 tile 4 attr $20
    db $e8, $08, $02, $00   ; dy -24 dx +8 tile 2 attr $00
    db $f0, $f8, $02, $20   ; dy -16 dx -8 tile 2 attr $20
    db $e0, $0c, $27, $20   ; dy -32 dx +12 tile 39 attr $20
    db $d0, $07, $24, $20   ; dy -48 dx +7 tile 36 attr $20
    db $d8, $0c, $22, $20   ; dy -40 dx +12 tile 34 attr $20
    db $d8, $04, $23, $20   ; dy -40 dx +4 tile 35 attr $20
    db $e0, $ec, $27, $00   ; dy -32 dx -20 tile 39 attr $00
    db $d0, $f1, $24, $00   ; dy -48 dx -15 tile 36 attr $00
    db $d8, $ec, $22, $00   ; dy -40 dx -20 tile 34 attr $00
    db $d8, $f4, $23, $00   ; dy -40 dx -12 tile 35 attr $00
    db $d0, $e8, $2b, $00   ; dy -48 dx -24 tile 43 attr $00
    db $d0, $10, $2b, $20   ; dy -48 dx +16 tile 43 attr $20
    db $80
Anim_1e_F17:   ; $72ca 28 sprites
    db $d8, $0c, $22, $20   ; dy -40 dx +12 tile 34 attr $20
    db $d8, $04, $23, $20   ; dy -40 dx +4 tile 35 attr $20
    db $d8, $ec, $22, $00   ; dy -40 dx -20 tile 34 attr $00
    db $d8, $f4, $23, $00   ; dy -40 dx -12 tile 35 attr $00
    db $e8, $10, $0e, $20   ; dy -24 dx +16 tile 14 attr $20
    db $f0, $10, $13, $20   ; dy -16 dx +16 tile 19 attr $20
    db $f0, $e8, $13, $00   ; dy -16 dx -24 tile 19 attr $00
    db $f0, $f0, $14, $00   ; dy -16 dx -16 tile 20 attr $00
    db $f8, $f0, $1a, $20   ; dy -8 dx -16 tile 26 attr $20
    db $f8, $f8, $0a, $00   ; dy -8 dx -8 tile 10 attr $00
    db $f8, $00, $0c, $00   ; dy -8 dx +0 tile 12 attr $00
    db $f8, $08, $12, $00   ; dy -8 dx +8 tile 18 attr $00
    db $f0, $00, $09, $00   ; dy -16 dx +0 tile 9 attr $00
    db $f0, $08, $0a, $00   ; dy -16 dx +8 tile 10 attr $00
    db $e8, $08, $05, $00   ; dy -24 dx +8 tile 5 attr $00
    db $e0, $08, $0d, $20   ; dy -32 dx +8 tile 13 attr $20
    db $e0, $10, $09, $20   ; dy -32 dx +16 tile 9 attr $20
    db $e8, $e8, $0e, $00   ; dy -24 dx -24 tile 14 attr $00
    db $e8, $f0, $05, $20   ; dy -24 dx -16 tile 5 attr $20
    db $e0, $f0, $0d, $00   ; dy -32 dx -16 tile 13 attr $00
    db $e0, $e8, $09, $00   ; dy -32 dx -24 tile 9 attr $00
    db $f0, $f8, $09, $20   ; dy -16 dx -8 tile 9 attr $20
    db $e8, $00, $26, $00   ; dy -24 dx +0 tile 38 attr $00
    db $e8, $f8, $20, $00   ; dy -24 dx -8 tile 32 attr $00
    db $e0, $00, $21, $00   ; dy -32 dx +0 tile 33 attr $00
    db $e0, $f8, $21, $20   ; dy -32 dx -8 tile 33 attr $20
    db $d3, $00, $20, $00   ; dy -45 dx +0 tile 32 attr $00
    db $d3, $f8, $20, $20   ; dy -45 dx -8 tile 32 attr $20
    db $80
Anim_1e_F18:   ; $733b 16 sprites
    db $e4, $03, $06, $20   ; dy -28 dx +3 tile 6 attr $20
    db $e4, $f3, $08, $20   ; dy -28 dx -13 tile 8 attr $20
    db $dc, $05, $02, $20   ; dy -36 dx +5 tile 2 attr $20
    db $dc, $f5, $04, $20   ; dy -36 dx -11 tile 4 attr $20
    db $d4, $fc, $04, $20   ; dy -44 dx -4 tile 4 attr $20
    db $d4, $ff, $02, $20   ; dy -44 dx -1 tile 2 attr $20
    db $dc, $fd, $07, $20   ; dy -36 dx -3 tile 7 attr $20
    db $e4, $fb, $0b, $20   ; dy -28 dx -5 tile 11 attr $20
    db $e4, $09, $09, $20   ; dy -28 dx +9 tile 9 attr $20
    db $ec, $f8, $0f, $40   ; dy -20 dx -8 tile 15 attr $40
    db $ec, $f0, $12, $20   ; dy -20 dx -16 tile 18 attr $20
    db $ec, $08, $17, $00   ; dy -20 dx +8 tile 23 attr $00
    db $ec, $00, $18, $20   ; dy -20 dx +0 tile 24 attr $20
    db $f4, $fb, $19, $00   ; dy -12 dx -5 tile 25 attr $00
    db $f4, $03, $1a, $00   ; dy -12 dx +3 tile 26 attr $00
    db $f4, $f3, $1a, $20   ; dy -12 dx -13 tile 26 attr $20
    db $80
Anim_1e_F19:   ; $737c 8 sprites
    db $f8, $fc, $1b, $00   ; dy -8 dx -4 tile 27 attr $00
    db $e0, $fc, $24, $00   ; dy -32 dx -4 tile 36 attr $00
    db $e8, $fc, $03, $00   ; dy -24 dx -4 tile 3 attr $00
    db $f0, $04, $12, $00   ; dy -16 dx +4 tile 18 attr $00
    db $f0, $fc, $0c, $20   ; dy -16 dx -4 tile 12 attr $20
    db $f0, $f4, $0d, $20   ; dy -16 dx -12 tile 13 attr $20
    db $e8, $f4, $22, $00   ; dy -24 dx -12 tile 34 attr $00
    db $e8, $04, $23, $00   ; dy -24 dx +4 tile 35 attr $00
Anim_1e_F20:   ; $739c empty frame = the $80 end above (shared)
    db $80
Anim_1f_BoltSlash:   ; $739d animation $1f — BoltSlash
    dw Anim_1f_F00
    dw Anim_1f_F01
    dw Anim_1f_F02
    dw Anim_1f_F03
    dw Anim_1f_F04
    dw Anim_1f_F05
    dw Anim_1f_F06
    dw Anim_1f_F07
    dw Anim_1f_F08
    dw Anim_1f_F09
    dw Anim_1f_F10
    dw Anim_1f_F11
    dw Anim_1f_F12
    dw Anim_1f_F13
    dw Anim_1f_F14
    dw Anim_1f_F15
    dw Anim_1f_F16
    dw Anim_1f_F17
    dw Anim_1f_F17
    dw Anim_1f_F17
    dw Anim_1f_F17
    dw Anim_1f_F17
    dw Anim_1f_F17
    dw Anim_1f_F17
    dw Anim_1f_F17
    dw Anim_1f_F17
    dw Anim_1f_F17
    dw Anim_1f_F17
    dw Anim_1f_F17
    dw Anim_1f_F17
    dw Anim_1f_F17
    dw Anim_1f_F17
Anim_1f_F00:   ; $73dd 4 sprites
    db $d8, $03, $20, $00   ; dy -40 dx +3 tile 32 attr $00
    db $d8, $0b, $21, $00   ; dy -40 dx +11 tile 33 attr $00
    db $d0, $03, $22, $00   ; dy -48 dx +3 tile 34 attr $00
    db $d0, $0b, $23, $00   ; dy -48 dx +11 tile 35 attr $00
    db $80
Anim_1f_F01:   ; $73ee 8 sprites
    db $dc, $00, $20, $00   ; dy -36 dx +0 tile 32 attr $00
    db $dc, $08, $21, $00   ; dy -36 dx +8 tile 33 attr $00
    db $d4, $00, $22, $00   ; dy -44 dx +0 tile 34 attr $00
    db $d4, $08, $23, $00   ; dy -44 dx +8 tile 35 attr $00
    db $e4, $f8, $20, $60   ; dy -28 dx -8 tile 32 attr $60
    db $e4, $f0, $21, $60   ; dy -28 dx -16 tile 33 attr $60
    db $ec, $f8, $22, $60   ; dy -20 dx -8 tile 34 attr $60
    db $ec, $f0, $23, $60   ; dy -20 dx -16 tile 35 attr $60
    db $80
Anim_1f_F02:   ; $740f 10 sprites
    db $d0, $00, $24, $00   ; dy -48 dx +0 tile 36 attr $00
    db $d0, $08, $25, $00   ; dy -48 dx +8 tile 37 attr $00
    db $d8, $fc, $26, $00   ; dy -40 dx -4 tile 38 attr $00
    db $d8, $04, $27, $00   ; dy -40 dx +4 tile 39 attr $00
    db $e0, $f8, $28, $00   ; dy -32 dx -8 tile 40 attr $00
    db $e0, $00, $29, $00   ; dy -32 dx +0 tile 41 attr $00
    db $e8, $f0, $2a, $00   ; dy -24 dx -16 tile 42 attr $00
    db $e8, $f8, $2b, $00   ; dy -24 dx -8 tile 43 attr $00
    db $f0, $f4, $2c, $00   ; dy -16 dx -12 tile 44 attr $00
    db $f8, $f0, $2d, $00   ; dy -8 dx -16 tile 45 attr $00
    db $80
Anim_1f_F03:   ; $7438 12 sprites
    db $d8, $fb, $24, $00   ; dy -40 dx -5 tile 36 attr $00
    db $d8, $03, $25, $00   ; dy -40 dx +3 tile 37 attr $00
    db $e0, $f7, $26, $00   ; dy -32 dx -9 tile 38 attr $00
    db $e0, $ff, $27, $00   ; dy -32 dx -1 tile 39 attr $00
    db $e8, $f3, $28, $00   ; dy -24 dx -13 tile 40 attr $00
    db $e8, $fb, $29, $00   ; dy -24 dx -5 tile 41 attr $00
    db $f0, $eb, $2a, $00   ; dy -16 dx -21 tile 42 attr $00
    db $f0, $f3, $2b, $00   ; dy -16 dx -13 tile 43 attr $00
    db $f8, $ef, $2c, $00   ; dy -8 dx -17 tile 44 attr $00
    db $d0, $08, $05, $00   ; dy -48 dx +8 tile 5 attr $00
    db $d0, $00, $24, $00   ; dy -48 dx +0 tile 36 attr $00
    db $e8, $eb, $12, $00   ; dy -24 dx -21 tile 18 attr $00
    db $80
Anim_1f_F04:   ; $7469 8 sprites
    db $f8, $ee, $2e, $00   ; dy -8 dx -18 tile 46 attr $00
    db $f0, $f3, $2e, $00   ; dy -16 dx -13 tile 46 attr $00
    db $e8, $f8, $2e, $00   ; dy -24 dx -8 tile 46 attr $00
    db $e0, $fe, $2e, $00   ; dy -32 dx -2 tile 46 attr $00
    db $d8, $03, $2e, $00   ; dy -40 dx +3 tile 46 attr $00
    db $d0, $08, $2e, $00   ; dy -48 dx +8 tile 46 attr $00
    db $f0, $eb, $11, $20   ; dy -16 dx -21 tile 17 attr $20
    db $e0, $f6, $0b, $20   ; dy -32 dx -10 tile 11 attr $20
    db $80
Anim_1f_F05:   ; $748a 6 sprites
    db $e8, $f0, $24, $00   ; dy -24 dx -16 tile 36 attr $00
    db $f0, $f3, $2e, $00   ; dy -16 dx -13 tile 46 attr $00
    db $e8, $f8, $2e, $00   ; dy -24 dx -8 tile 46 attr $00
    db $e0, $fe, $2f, $00   ; dy -32 dx -2 tile 47 attr $00
    db $d8, $03, $2f, $00   ; dy -40 dx +3 tile 47 attr $00
    db $f8, $ee, $2e, $00   ; dy -8 dx -18 tile 46 attr $00
    db $80
Anim_1f_F06:   ; $74a3 3 sprites
    db $f8, $f0, $2f, $00   ; dy -8 dx -16 tile 47 attr $00
    db $f0, $f5, $2f, $00   ; dy -16 dx -11 tile 47 attr $00
    db $e8, $fa, $2f, $00   ; dy -24 dx -6 tile 47 attr $00
    db $80
Anim_1f_F07:   ; $74b0 8 sprites
    db $e8, $f8, $05, $00   ; dy -24 dx -8 tile 5 attr $00
    db $e8, $00, $13, $00   ; dy -24 dx +0 tile 19 attr $00
    db $e0, $00, $0c, $60   ; dy -32 dx +0 tile 12 attr $60
    db $e0, $f8, $0b, $20   ; dy -32 dx -8 tile 11 attr $20
    db $d8, $f3, $01, $20   ; dy -40 dx -13 tile 1 attr $20
    db $ee, $f2, $00, $60   ; dy -18 dx -14 tile 0 attr $60
    db $ed, $07, $01, $40   ; dy -19 dx +7 tile 1 attr $40
    db $dd, $04, $00, $00   ; dy -35 dx +4 tile 0 attr $00
    db $80
Anim_1f_F08:   ; $74d1 12 sprites
    db $e8, $f8, $03, $00   ; dy -24 dx -8 tile 3 attr $00
    db $e8, $f0, $02, $00   ; dy -24 dx -16 tile 2 attr $00
    db $e0, $00, $03, $60   ; dy -32 dx +0 tile 3 attr $60
    db $e0, $08, $02, $60   ; dy -32 dx +8 tile 2 attr $60
    db $e0, $f8, $0d, $00   ; dy -32 dx -8 tile 13 attr $00
    db $e8, $00, $0d, $00   ; dy -24 dx +0 tile 13 attr $00
    db $f0, $00, $05, $00   ; dy -16 dx +0 tile 5 attr $00
    db $d8, $f8, $05, $60   ; dy -40 dx -8 tile 5 attr $60
    db $d6, $f0, $00, $20   ; dy -42 dx -16 tile 0 attr $20
    db $d6, $08, $01, $00   ; dy -42 dx +8 tile 1 attr $00
    db $f2, $f0, $01, $60   ; dy -14 dx -16 tile 1 attr $60
    db $f2, $08, $00, $40   ; dy -14 dx +8 tile 0 attr $40
    db $80
Anim_1f_F09:   ; $7502 15 sprites
    db $ec, $f0, $08, $00   ; dy -20 dx -16 tile 8 attr $00
    db $ec, $f8, $09, $00   ; dy -20 dx -8 tile 9 attr $00
    db $ec, $08, $0c, $60   ; dy -20 dx +8 tile 12 attr $60
    db $ec, $00, $0d, $60   ; dy -20 dx +0 tile 13 attr $60
    db $dc, $f0, $0e, $40   ; dy -36 dx -16 tile 14 attr $40
    db $dc, $f8, $0f, $40   ; dy -36 dx -8 tile 15 attr $40
    db $dc, $00, $18, $40   ; dy -36 dx +0 tile 24 attr $40
    db $dc, $08, $19, $40   ; dy -36 dx +8 tile 25 attr $40
    db $e4, $f8, $10, $00   ; dy -28 dx -8 tile 16 attr $00
    db $e4, $00, $11, $00   ; dy -28 dx +0 tile 17 attr $00
    db $d4, $03, $05, $60   ; dy -44 dx +3 tile 5 attr $60
    db $f4, $0b, $02, $20   ; dy -12 dx +11 tile 2 attr $20
    db $f4, $03, $03, $20   ; dy -12 dx +3 tile 3 attr $20
    db $d4, $f5, $19, $00   ; dy -44 dx -11 tile 25 attr $00
    db $f4, $f4, $05, $00   ; dy -12 dx -12 tile 5 attr $00
    db $80
Anim_1f_F10:   ; $753f 14 sprites
    db $d0, $f8, $0c, $00   ; dy -48 dx -8 tile 12 attr $00
    db $d0, $00, $0d, $00   ; dy -48 dx +0 tile 13 attr $00
    db $d7, $01, $05, $00   ; dy -41 dx +1 tile 5 attr $00
    db $f8, $f8, $08, $20   ; dy -8 dx -8 tile 8 attr $20
    db $f8, $f0, $18, $00   ; dy -8 dx -16 tile 24 attr $00
    db $f0, $ea, $05, $40   ; dy -16 dx -22 tile 5 attr $40
    db $d8, $0c, $01, $00   ; dy -40 dx +12 tile 1 attr $00
    db $f8, $e8, $01, $20   ; dy -8 dx -24 tile 1 attr $20
    db $d5, $f0, $08, $60   ; dy -43 dx -16 tile 8 attr $60
    db $d5, $e8, $09, $60   ; dy -43 dx -24 tile 9 attr $60
    db $dd, $ea, $05, $20   ; dy -35 dx -22 tile 5 attr $20
    db $f4, $04, $02, $40   ; dy -12 dx +4 tile 2 attr $40
    db $f8, $0c, $03, $00   ; dy -8 dx +12 tile 3 attr $00
    db $f4, $10, $02, $60   ; dy -12 dx +16 tile 2 attr $60
    db $80
Anim_1f_F11:   ; $7578 12 sprites
    db $d0, $00, $16, $20   ; dy -48 dx +0 tile 22 attr $20
    db $d0, $f8, $17, $20   ; dy -48 dx -8 tile 23 attr $20
    db $d8, $00, $18, $20   ; dy -40 dx +0 tile 24 attr $20
    db $d8, $f8, $19, $20   ; dy -40 dx -8 tile 25 attr $20
    db $e0, $fc, $18, $20   ; dy -32 dx -4 tile 24 attr $20
    db $e0, $f4, $19, $20   ; dy -32 dx -12 tile 25 attr $20
    db $e8, $f8, $05, $00   ; dy -24 dx -8 tile 5 attr $00
    db $de, $e3, $0b, $60   ; dy -34 dx -29 tile 11 attr $60
    db $e8, $ec, $01, $00   ; dy -24 dx -20 tile 1 attr $00
    db $f8, $10, $18, $00   ; dy -8 dx +16 tile 24 attr $00
    db $f8, $00, $01, $00   ; dy -8 dx +0 tile 1 attr $00
    db $f8, $f8, $01, $20   ; dy -8 dx -8 tile 1 attr $20
    db $80
Anim_1f_F12:   ; $75a9 38 sprites
    db $d0, $01, $06, $20   ; dy -48 dx +1 tile 6 attr $20
    db $d0, $f9, $07, $20   ; dy -48 dx -7 tile 7 attr $20
    db $d8, $03, $08, $20   ; dy -40 dx +3 tile 8 attr $20
    db $d8, $fb, $09, $20   ; dy -40 dx -5 tile 9 attr $20
    db $e0, $00, $0a, $20   ; dy -32 dx +0 tile 10 attr $20
    db $e0, $f8, $0b, $20   ; dy -32 dx -8 tile 11 attr $20
    db $e8, $05, $0c, $20   ; dy -24 dx +5 tile 12 attr $20
    db $e8, $fd, $0d, $20   ; dy -24 dx -3 tile 13 attr $20
    db $f0, $05, $0e, $20   ; dy -16 dx +5 tile 14 attr $20
    db $f0, $fd, $0f, $20   ; dy -16 dx -3 tile 15 attr $20
    db $f8, $00, $10, $20   ; dy -8 dx +0 tile 16 attr $20
    db $f8, $f8, $11, $20   ; dy -8 dx -8 tile 17 attr $20
    db $f8, $f4, $1d, $20   ; dy -8 dx -12 tile 29 attr $20
    db $f8, $02, $1d, $00   ; dy -8 dx +2 tile 29 attr $00
    db $d0, $10, $1b, $00   ; dy -48 dx +16 tile 27 attr $00
    db $d0, $08, $1b, $00   ; dy -48 dx +8 tile 27 attr $00
    db $d8, $0b, $1b, $00   ; dy -40 dx +11 tile 27 attr $00
    db $d8, $10, $1b, $00   ; dy -40 dx +16 tile 27 attr $00
    db $e0, $10, $1b, $00   ; dy -32 dx +16 tile 27 attr $00
    db $e0, $08, $1b, $00   ; dy -32 dx +8 tile 27 attr $00
    db $e8, $10, $1b, $00   ; dy -24 dx +16 tile 27 attr $00
    db $f0, $10, $1b, $00   ; dy -16 dx +16 tile 27 attr $00
    db $f8, $10, $1b, $00   ; dy -8 dx +16 tile 27 attr $00
    db $f8, $0a, $1b, $00   ; dy -8 dx +10 tile 27 attr $00
    db $d0, $f0, $1b, $20   ; dy -48 dx -16 tile 27 attr $20
    db $d8, $f0, $1b, $20   ; dy -40 dx -16 tile 27 attr $20
    db $e0, $f0, $1b, $20   ; dy -32 dx -16 tile 27 attr $20
    db $e8, $f0, $1b, $20   ; dy -24 dx -16 tile 27 attr $20
    db $f0, $f0, $1b, $20   ; dy -16 dx -16 tile 27 attr $20
    db $f8, $f0, $1b, $20   ; dy -8 dx -16 tile 27 attr $20
    db $d0, $e8, $1b, $20   ; dy -48 dx -24 tile 27 attr $20
    db $d8, $e8, $1b, $20   ; dy -40 dx -24 tile 27 attr $20
    db $e0, $e8, $1b, $20   ; dy -32 dx -24 tile 27 attr $20
    db $e8, $e8, $1b, $20   ; dy -24 dx -24 tile 27 attr $20
    db $f0, $e8, $1b, $20   ; dy -16 dx -24 tile 27 attr $20
    db $f8, $e8, $1b, $20   ; dy -8 dx -24 tile 27 attr $20
    db $e8, $f5, $1b, $20   ; dy -24 dx -11 tile 27 attr $20
    db $f0, $f5, $1b, $20   ; dy -16 dx -11 tile 27 attr $20
    db $80
Anim_1f_F13:   ; $7642 16 sprites
    db $d0, $02, $0c, $20   ; dy -48 dx +2 tile 12 attr $20
    db $d0, $fa, $0d, $20   ; dy -48 dx -6 tile 13 attr $20
    db $d8, $f1, $16, $00   ; dy -40 dx -15 tile 22 attr $00
    db $d8, $f9, $17, $00   ; dy -40 dx -7 tile 23 attr $00
    db $e0, $f7, $16, $20   ; dy -32 dx -9 tile 22 attr $20
    db $e0, $ef, $17, $20   ; dy -32 dx -17 tile 23 attr $20
    db $e8, $f7, $18, $20   ; dy -24 dx -9 tile 24 attr $20
    db $e8, $ef, $19, $20   ; dy -24 dx -17 tile 25 attr $20
    db $f0, $f7, $1a, $20   ; dy -16 dx -9 tile 26 attr $20
    db $e5, $fe, $06, $20   ; dy -27 dx -2 tile 6 attr $20
    db $ed, $01, $05, $20   ; dy -19 dx +1 tile 5 attr $20
    db $f8, $fc, $1e, $00   ; dy -8 dx -4 tile 30 attr $00
    db $f8, $04, $1f, $00   ; dy -8 dx +4 tile 31 attr $00
    db $f8, $f4, $1e, $20   ; dy -8 dx -12 tile 30 attr $20
    db $f8, $ec, $1f, $20   ; dy -8 dx -20 tile 31 attr $20
    db $f0, $ef, $0c, $00   ; dy -16 dx -17 tile 12 attr $00
    db $80
Anim_1f_F14:   ; $7683 33 sprites
    db $d8, $0b, $08, $20   ; dy -40 dx +11 tile 8 attr $20
    db $d8, $03, $09, $20   ; dy -40 dx +3 tile 9 attr $20
    db $d0, $01, $18, $00   ; dy -48 dx +1 tile 24 attr $00
    db $d0, $09, $19, $00   ; dy -48 dx +9 tile 25 attr $00
    db $e0, $05, $14, $00   ; dy -32 dx +5 tile 20 attr $00
    db $e0, $0d, $15, $00   ; dy -32 dx +13 tile 21 attr $00
    db $e8, $06, $0c, $00   ; dy -24 dx +6 tile 12 attr $00
    db $e8, $0e, $0d, $00   ; dy -24 dx +14 tile 13 attr $00
    db $f0, $05, $0e, $00   ; dy -16 dx +5 tile 14 attr $00
    db $f0, $0d, $0f, $00   ; dy -16 dx +13 tile 15 attr $00
    db $e8, $03, $0d, $20   ; dy -24 dx +3 tile 13 attr $20
    db $f0, $fe, $0c, $00   ; dy -16 dx -2 tile 12 attr $00
    db $f8, $0c, $1c, $00   ; dy -8 dx +12 tile 28 attr $00
    db $f8, $04, $1c, $20   ; dy -8 dx +4 tile 28 attr $20
    db $f8, $fc, $1d, $20   ; dy -8 dx -4 tile 29 attr $20
    db $d0, $e8, $1b, $00   ; dy -48 dx -24 tile 27 attr $00
    db $d8, $e8, $1b, $00   ; dy -40 dx -24 tile 27 attr $00
    db $e0, $e8, $1b, $00   ; dy -32 dx -24 tile 27 attr $00
    db $e8, $e8, $1b, $00   ; dy -24 dx -24 tile 27 attr $00
    db $f0, $e9, $1b, $00   ; dy -16 dx -23 tile 27 attr $00
    db $f8, $e9, $1b, $00   ; dy -8 dx -23 tile 27 attr $00
    db $d0, $f0, $1b, $00   ; dy -48 dx -16 tile 27 attr $00
    db $d8, $f1, $1b, $00   ; dy -40 dx -15 tile 27 attr $00
    db $e0, $f2, $1b, $00   ; dy -32 dx -14 tile 27 attr $00
    db $e8, $f1, $1b, $00   ; dy -24 dx -15 tile 27 attr $00
    db $f0, $f3, $1b, $00   ; dy -16 dx -13 tile 27 attr $00
    db $f8, $f3, $1b, $00   ; dy -8 dx -13 tile 27 attr $00
    db $d0, $f8, $1b, $00   ; dy -48 dx -8 tile 27 attr $00
    db $d8, $fa, $1b, $00   ; dy -40 dx -6 tile 27 attr $00
    db $e8, $fa, $1b, $00   ; dy -24 dx -6 tile 27 attr $00
    db $e0, $fc, $1b, $00   ; dy -32 dx -4 tile 27 attr $00
    db $d0, $10, $1b, $20   ; dy -48 dx +16 tile 27 attr $20
    db $f8, $14, $1f, $00   ; dy -8 dx +20 tile 31 attr $00
    db $80
Anim_1f_F15:   ; $7708 26 sprites
    db $f8, $00, $1f, $00   ; dy -8 dx +0 tile 31 attr $00
    db $d0, $03, $14, $20   ; dy -48 dx +3 tile 20 attr $20
    db $d0, $fb, $15, $20   ; dy -48 dx -5 tile 21 attr $20
    db $d8, $09, $0a, $20   ; dy -40 dx +9 tile 10 attr $20
    db $d8, $01, $0b, $20   ; dy -40 dx +1 tile 11 attr $20
    db $f8, $0f, $1e, $00   ; dy -8 dx +15 tile 30 attr $00
    db $f8, $17, $1f, $00   ; dy -8 dx +23 tile 31 attr $00
    db $f8, $07, $1e, $20   ; dy -8 dx +7 tile 30 attr $20
    db $e0, $08, $16, $40   ; dy -32 dx +8 tile 22 attr $40
    db $e0, $10, $17, $40   ; dy -32 dx +16 tile 23 attr $40
    db $e8, $11, $0c, $20   ; dy -24 dx +17 tile 12 attr $20
    db $e8, $09, $0d, $20   ; dy -24 dx +9 tile 13 attr $20
    db $f0, $10, $0e, $20   ; dy -16 dx +16 tile 14 attr $20
    db $f0, $08, $0f, $20   ; dy -16 dx +8 tile 15 attr $20
    db $e8, $fa, $14, $60   ; dy -24 dx -6 tile 20 attr $60
    db $e8, $f2, $15, $60   ; dy -24 dx -14 tile 21 attr $60
    db $f0, $fa, $10, $20   ; dy -16 dx -6 tile 16 attr $20
    db $f0, $f2, $11, $20   ; dy -16 dx -14 tile 17 attr $20
    db $f8, $f0, $1c, $20   ; dy -8 dx -16 tile 28 attr $20
    db $f8, $f8, $1c, $00   ; dy -8 dx -8 tile 28 attr $00
    db $f8, $00, $1d, $00   ; dy -8 dx +0 tile 29 attr $00
    db $e0, $f3, $0b, $60   ; dy -32 dx -13 tile 11 attr $60
    db $f8, $e8, $1d, $20   ; dy -8 dx -24 tile 29 attr $20
    db $dc, $f3, $0c, $00   ; dy -36 dx -13 tile 12 attr $00
    db $d8, $fa, $09, $00   ; dy -40 dx -6 tile 9 attr $00
    db $e0, $fb, $0a, $60   ; dy -32 dx -5 tile 10 attr $60
    db $80
Anim_1f_F16:   ; $7771 36 sprites
    db $d0, $fe, $10, $20   ; dy -48 dx -2 tile 16 attr $20
    db $d0, $f6, $11, $20   ; dy -48 dx -10 tile 17 attr $20
    db $d8, $f4, $12, $40   ; dy -40 dx -12 tile 18 attr $40
    db $d8, $fc, $13, $40   ; dy -40 dx -4 tile 19 attr $40
    db $e8, $f6, $10, $20   ; dy -24 dx -10 tile 16 attr $20
    db $e8, $ee, $11, $20   ; dy -24 dx -18 tile 17 attr $20
    db $f0, $f0, $18, $20   ; dy -16 dx -16 tile 24 attr $20
    db $d8, $06, $14, $00   ; dy -40 dx +6 tile 20 attr $00
    db $d8, $0e, $15, $00   ; dy -40 dx +14 tile 21 attr $00
    db $e0, $0f, $10, $20   ; dy -32 dx +15 tile 16 attr $20
    db $e0, $07, $11, $20   ; dy -32 dx +7 tile 17 attr $20
    db $e8, $04, $06, $00   ; dy -24 dx +4 tile 6 attr $00
    db $e8, $0c, $07, $00   ; dy -24 dx +12 tile 7 attr $00
    db $f0, $01, $14, $00   ; dy -16 dx +1 tile 20 attr $00
    db $f0, $09, $15, $00   ; dy -16 dx +9 tile 21 attr $00
    db $f8, $10, $1f, $00   ; dy -8 dx +16 tile 31 attr $00
    db $f8, $01, $1e, $20   ; dy -8 dx +1 tile 30 attr $20
    db $f8, $09, $1e, $00   ; dy -8 dx +9 tile 30 attr $00
    db $f0, $0c, $04, $00   ; dy -16 dx +12 tile 4 attr $00
    db $f8, $10, $05, $20   ; dy -8 dx +16 tile 5 attr $20
    db $d0, $02, $12, $00   ; dy -48 dx +2 tile 18 attr $00
    db $d0, $0a, $13, $00   ; dy -48 dx +10 tile 19 attr $00
    db $f8, $f9, $1f, $20   ; dy -8 dx -7 tile 31 attr $20
    db $f8, $f4, $1c, $00   ; dy -8 dx -12 tile 28 attr $00
    db $f8, $fc, $1d, $00   ; dy -8 dx -4 tile 29 attr $00
    db $f8, $ec, $1c, $20   ; dy -8 dx -20 tile 28 attr $20
    db $f0, $f8, $1b, $00   ; dy -16 dx -8 tile 27 attr $00
    db $f8, $e4, $1f, $20   ; dy -8 dx -28 tile 31 attr $20
    db $d0, $e8, $1b, $20   ; dy -48 dx -24 tile 27 attr $20
    db $d8, $e8, $1b, $20   ; dy -40 dx -24 tile 27 attr $20
    db $e0, $e8, $1b, $20   ; dy -32 dx -24 tile 27 attr $20
    db $d0, $10, $1b, $00   ; dy -48 dx +16 tile 27 attr $00
    db $e8, $fd, $1b, $00   ; dy -24 dx -3 tile 27 attr $00
    db $f0, $e8, $0e, $00   ; dy -16 dx -24 tile 14 attr $00
    db $e0, $f6, $14, $00   ; dy -32 dx -10 tile 20 attr $00
    db $e0, $fe, $15, $00   ; dy -32 dx -2 tile 21 attr $00
Anim_1f_F17:   ; $7801 empty frame = the $80 end above (shared)
    db $80
Anim_20_VacuSlash:   ; $7802 animation $20 — VacuSlash
    dw Anim_20_F00
    dw Anim_20_F01
    dw Anim_20_F02
    dw Anim_20_F03
    dw Anim_20_F04
    dw Anim_20_F05
    dw Anim_20_F06
    dw Anim_20_F07
    dw Anim_20_F08
    dw Anim_20_F09
    dw Anim_20_F10
    dw Anim_20_F11
    dw Anim_20_F12
    dw Anim_20_F13
    dw Anim_20_F14
    dw Anim_20_F15
    dw Anim_20_F16
    dw Anim_20_F17
    dw Anim_20_F18
    dw Anim_20_F19
    dw Anim_20_F20
    dw Anim_20_F21
    dw Anim_20_F22
    dw Anim_20_F23
    dw Anim_20_F24
    dw Anim_20_F25
    dw Anim_20_F26
    dw Anim_20_F26
    dw Anim_20_F26
    dw Anim_20_F26
    dw Anim_20_F26
    dw Anim_20_F26
Anim_20_F00:   ; $7842 4 sprites
    db $d8, $03, $20, $00   ; dy -40 dx +3 tile 32 attr $00
    db $d8, $0b, $21, $00   ; dy -40 dx +11 tile 33 attr $00
    db $d0, $03, $22, $00   ; dy -48 dx +3 tile 34 attr $00
    db $d0, $0b, $23, $00   ; dy -48 dx +11 tile 35 attr $00
    db $80
Anim_20_F01:   ; $7853 10 sprites
    db $dc, $00, $20, $00   ; dy -36 dx +0 tile 32 attr $00
    db $dc, $08, $21, $00   ; dy -36 dx +8 tile 33 attr $00
    db $e4, $f8, $20, $60   ; dy -28 dx -8 tile 32 attr $60
    db $e4, $f0, $21, $60   ; dy -28 dx -16 tile 33 attr $60
    db $d0, $03, $2f, $00   ; dy -48 dx +3 tile 47 attr $00
    db $d4, $00, $22, $00   ; dy -44 dx +0 tile 34 attr $00
    db $d4, $08, $23, $00   ; dy -44 dx +8 tile 35 attr $00
    db $f0, $f5, $2f, $60   ; dy -16 dx -11 tile 47 attr $60
    db $ec, $f8, $22, $60   ; dy -20 dx -8 tile 34 attr $60
    db $ec, $f0, $23, $60   ; dy -20 dx -16 tile 35 attr $60
    db $80
Anim_20_F02:   ; $787c 12 sprites
    db $d8, $fc, $26, $00   ; dy -40 dx -4 tile 38 attr $00
    db $d8, $04, $27, $00   ; dy -40 dx +4 tile 39 attr $00
    db $d8, $0c, $28, $00   ; dy -40 dx +12 tile 40 attr $00
    db $f0, $f4, $2e, $00   ; dy -16 dx -12 tile 46 attr $00
    db $f8, $ef, $2f, $00   ; dy -8 dx -17 tile 47 attr $00
    db $d0, $00, $24, $00   ; dy -48 dx +0 tile 36 attr $00
    db $d0, $08, $25, $00   ; dy -48 dx +8 tile 37 attr $00
    db $e0, $f8, $29, $00   ; dy -32 dx -8 tile 41 attr $00
    db $e0, $00, $2a, $00   ; dy -32 dx +0 tile 42 attr $00
    db $e0, $08, $2b, $00   ; dy -32 dx +8 tile 43 attr $00
    db $e8, $f8, $2c, $00   ; dy -24 dx -8 tile 44 attr $00
    db $e8, $00, $2d, $00   ; dy -24 dx +0 tile 45 attr $00
    db $80
Anim_20_F03:   ; $78ad 12 sprites
    db $e0, $f7, $26, $00   ; dy -32 dx -9 tile 38 attr $00
    db $e0, $ff, $27, $00   ; dy -32 dx -1 tile 39 attr $00
    db $e0, $07, $28, $00   ; dy -32 dx +7 tile 40 attr $00
    db $f8, $ef, $2e, $00   ; dy -8 dx -17 tile 46 attr $00
    db $d8, $fb, $24, $00   ; dy -40 dx -5 tile 36 attr $00
    db $d8, $03, $25, $00   ; dy -40 dx +3 tile 37 attr $00
    db $e8, $f3, $29, $00   ; dy -24 dx -13 tile 41 attr $00
    db $e8, $fb, $2a, $00   ; dy -24 dx -5 tile 42 attr $00
    db $e8, $03, $2b, $00   ; dy -24 dx +3 tile 43 attr $00
    db $f0, $f3, $2c, $00   ; dy -16 dx -13 tile 44 attr $00
    db $f0, $fb, $2d, $00   ; dy -16 dx -5 tile 45 attr $00
    db $d0, $09, $2f, $00   ; dy -48 dx +9 tile 47 attr $00
    db $80
Anim_20_F04:   ; $78de 9 sprites
    db $d0, $09, $2e, $00   ; dy -48 dx +9 tile 46 attr $00
    db $d8, $04, $2e, $00   ; dy -40 dx +4 tile 46 attr $00
    db $e0, $ff, $2e, $00   ; dy -32 dx -1 tile 46 attr $00
    db $e8, $f9, $2e, $00   ; dy -24 dx -7 tile 46 attr $00
    db $f8, $f5, $29, $60   ; dy -8 dx -11 tile 41 attr $60
    db $f8, $ed, $2a, $60   ; dy -8 dx -19 tile 42 attr $60
    db $f8, $e5, $2b, $60   ; dy -8 dx -27 tile 43 attr $60
    db $f0, $f5, $2c, $60   ; dy -16 dx -11 tile 44 attr $60
    db $f0, $ed, $2d, $60   ; dy -16 dx -19 tile 45 attr $60
    db $80
Anim_20_F05:   ; $7903 5 sprites
    db $f8, $ef, $2e, $00   ; dy -8 dx -17 tile 46 attr $00
    db $f0, $f4, $2e, $00   ; dy -16 dx -12 tile 46 attr $00
    db $e8, $f9, $2e, $00   ; dy -24 dx -7 tile 46 attr $00
    db $e0, $ff, $2f, $00   ; dy -32 dx -1 tile 47 attr $00
    db $d8, $04, $2f, $00   ; dy -40 dx +4 tile 47 attr $00
    db $80
Anim_20_F06:   ; $7918 3 sprites
    db $f8, $ef, $2f, $00   ; dy -8 dx -17 tile 47 attr $00
    db $f0, $f4, $2f, $00   ; dy -16 dx -12 tile 47 attr $00
    db $e8, $f9, $2f, $00   ; dy -24 dx -7 tile 47 attr $00
    db $80
Anim_20_F07:   ; $7925 9 sprites
    db $dc, $f4, $02, $00   ; dy -36 dx -12 tile 2 attr $00
    db $dc, $fc, $03, $00   ; dy -36 dx -4 tile 3 attr $00
    db $ee, $f4, $00, $00   ; dy -18 dx -12 tile 0 attr $00
    db $ee, $fc, $01, $00   ; dy -18 dx -4 tile 1 attr $00
    db $e3, $f5, $04, $00   ; dy -29 dx -11 tile 4 attr $00
    db $e3, $fd, $05, $00   ; dy -29 dx -3 tile 5 attr $00
    db $e3, $05, $06, $00   ; dy -29 dx +5 tile 6 attr $00
    db $ea, $ed, $07, $00   ; dy -22 dx -19 tile 7 attr $00
    db $eb, $f5, $08, $00   ; dy -21 dx -11 tile 8 attr $00
    db $80
Anim_20_F08:   ; $794a 8 sprites
    db $de, $f4, $00, $00   ; dy -34 dx -12 tile 0 attr $00
    db $de, $fc, $01, $00   ; dy -34 dx -4 tile 1 attr $00
    db $f0, $f0, $0c, $00   ; dy -16 dx -16 tile 12 attr $00
    db $f0, $f8, $0d, $00   ; dy -16 dx -8 tile 13 attr $00
    db $f0, $00, $0e, $00   ; dy -16 dx +0 tile 14 attr $00
    db $e2, $f6, $09, $00   ; dy -30 dx -10 tile 9 attr $00
    db $e2, $fe, $0a, $00   ; dy -30 dx -2 tile 10 attr $00
    db $e2, $06, $0b, $00   ; dy -30 dx +6 tile 11 attr $00
    db $80
Anim_20_F09:   ; $796b 13 sprites
    db $dd, $f0, $0c, $00   ; dy -35 dx -16 tile 12 attr $00
    db $dd, $f8, $0d, $00   ; dy -35 dx -8 tile 13 attr $00
    db $dd, $00, $0e, $00   ; dy -35 dx +0 tile 14 attr $00
    db $f0, $f0, $04, $00   ; dy -16 dx -16 tile 4 attr $00
    db $f0, $f8, $05, $00   ; dy -16 dx -8 tile 5 attr $00
    db $f0, $00, $06, $00   ; dy -16 dx +0 tile 6 attr $00
    db $f8, $f0, $08, $00   ; dy -8 dx -16 tile 8 attr $00
    db $f7, $e8, $07, $00   ; dy -9 dx -24 tile 7 attr $00
    db $ea, $f8, $1c, $00   ; dy -22 dx -8 tile 28 attr $00
    db $ea, $00, $1d, $00   ; dy -22 dx +0 tile 29 attr $00
    db $e2, $f8, $1b, $00   ; dy -30 dx -8 tile 27 attr $00
    db $e6, $08, $1e, $00   ; dy -26 dx +8 tile 30 attr $00
    db $e6, $10, $1f, $00   ; dy -26 dx +16 tile 31 attr $00
    db $80
Anim_20_F10:   ; $79a0 15 sprites
    db $da, $f1, $04, $00   ; dy -38 dx -15 tile 4 attr $00
    db $da, $f9, $05, $00   ; dy -38 dx -7 tile 5 attr $00
    db $da, $01, $06, $00   ; dy -38 dx +1 tile 6 attr $00
    db $e2, $f1, $08, $00   ; dy -30 dx -15 tile 8 attr $00
    db $e1, $e9, $07, $00   ; dy -31 dx -23 tile 7 attr $00
    db $f2, $ee, $0c, $00   ; dy -14 dx -18 tile 12 attr $00
    db $f2, $f6, $0d, $00   ; dy -14 dx -10 tile 13 attr $00
    db $f2, $fe, $0e, $00   ; dy -14 dx -2 tile 14 attr $00
    db $e2, $f8, $0f, $00   ; dy -30 dx -8 tile 15 attr $00
    db $e2, $00, $10, $00   ; dy -30 dx +0 tile 16 attr $00
    db $e2, $08, $11, $00   ; dy -30 dx +8 tile 17 attr $00
    db $e2, $10, $12, $00   ; dy -30 dx +16 tile 18 attr $00
    db $ea, $f8, $13, $00   ; dy -22 dx -8 tile 19 attr $00
    db $ea, $00, $14, $00   ; dy -22 dx +0 tile 20 attr $00
    db $ea, $0c, $15, $00   ; dy -22 dx +12 tile 21 attr $00
    db $80
Anim_20_F11:   ; $79dd 14 sprites
    db $e2, $00, $16, $00   ; dy -30 dx +0 tile 22 attr $00
    db $ea, $00, $19, $00   ; dy -22 dx +0 tile 25 attr $00
    db $e9, $0e, $15, $00   ; dy -23 dx +14 tile 21 attr $00
    db $e2, $10, $18, $00   ; dy -30 dx +16 tile 24 attr $00
    db $e2, $08, $17, $00   ; dy -30 dx +8 tile 23 attr $00
    db $ea, $08, $1a, $00   ; dy -22 dx +8 tile 26 attr $00
    db $e0, $e8, $1c, $00   ; dy -32 dx -24 tile 28 attr $00
    db $e0, $f0, $1d, $00   ; dy -32 dx -16 tile 29 attr $00
    db $d8, $e8, $1b, $00   ; dy -40 dx -24 tile 27 attr $00
    db $da, $f3, $09, $00   ; dy -38 dx -13 tile 9 attr $00
    db $da, $fb, $0a, $00   ; dy -38 dx -5 tile 10 attr $00
    db $da, $03, $0b, $00   ; dy -38 dx +3 tile 11 attr $00
    db $dc, $f8, $1e, $00   ; dy -36 dx -8 tile 30 attr $00
    db $dc, $00, $1f, $00   ; dy -36 dx +0 tile 31 attr $00
    db $80
Anim_20_F12:   ; $7a16 12 sprites
    db $d8, $f0, $10, $00   ; dy -40 dx -16 tile 16 attr $00
    db $d8, $f8, $11, $00   ; dy -40 dx -8 tile 17 attr $00
    db $d8, $00, $12, $00   ; dy -40 dx +0 tile 18 attr $00
    db $d8, $e8, $0f, $00   ; dy -40 dx -24 tile 15 attr $00
    db $e0, $e8, $13, $00   ; dy -32 dx -24 tile 19 attr $00
    db $e0, $f0, $14, $00   ; dy -32 dx -16 tile 20 attr $00
    db $e0, $fc, $15, $00   ; dy -32 dx -4 tile 21 attr $00
    db $e9, $f6, $0c, $00   ; dy -23 dx -10 tile 12 attr $00
    db $e9, $fe, $0d, $00   ; dy -23 dx -2 tile 13 attr $00
    db $e9, $06, $0e, $00   ; dy -23 dx +6 tile 14 attr $00
    db $d0, $00, $00, $00   ; dy -48 dx +0 tile 0 attr $00
    db $d0, $08, $01, $00   ; dy -48 dx +8 tile 1 attr $00
    db $80
Anim_20_F13:   ; $7a47 16 sprites
    db $e8, $fc, $00, $00   ; dy -24 dx -4 tile 0 attr $00
    db $e8, $04, $01, $00   ; dy -24 dx +4 tile 1 attr $00
    db $f0, $f4, $04, $00   ; dy -16 dx -12 tile 4 attr $00
    db $f0, $fc, $05, $00   ; dy -16 dx -4 tile 5 attr $00
    db $f0, $04, $06, $00   ; dy -16 dx +4 tile 6 attr $00
    db $f8, $f4, $08, $00   ; dy -8 dx -12 tile 8 attr $00
    db $f7, $ec, $07, $00   ; dy -9 dx -20 tile 7 attr $00
    db $d8, $f0, $16, $00   ; dy -40 dx -16 tile 22 attr $00
    db $e0, $f0, $19, $00   ; dy -32 dx -16 tile 25 attr $00
    db $df, $fe, $15, $00   ; dy -33 dx -2 tile 21 attr $00
    db $e0, $f8, $1a, $00   ; dy -32 dx -8 tile 26 attr $00
    db $d8, $f8, $17, $00   ; dy -40 dx -8 tile 23 attr $00
    db $d8, $00, $18, $00   ; dy -40 dx +0 tile 24 attr $00
    db $d0, $fe, $09, $00   ; dy -48 dx -2 tile 9 attr $00
    db $d0, $06, $0a, $00   ; dy -48 dx +6 tile 10 attr $00
    db $d0, $0e, $0b, $00   ; dy -48 dx +14 tile 11 attr $00
    db $80
Anim_20_F14:   ; $7a88 16 sprites
    db $ee, $f3, $0c, $00   ; dy -18 dx -13 tile 12 attr $00
    db $e5, $fc, $05, $00   ; dy -27 dx -4 tile 5 attr $00
    db $e5, $04, $06, $00   ; dy -27 dx +4 tile 6 attr $00
    db $d8, $f8, $1c, $00   ; dy -40 dx -8 tile 28 attr $00
    db $d8, $00, $1d, $00   ; dy -40 dx +0 tile 29 attr $00
    db $d4, $08, $1e, $00   ; dy -44 dx +8 tile 30 attr $00
    db $d4, $10, $1f, $00   ; dy -44 dx +16 tile 31 attr $00
    db $d0, $f8, $1b, $00   ; dy -48 dx -8 tile 27 attr $00
    db $e5, $f4, $04, $00   ; dy -27 dx -12 tile 4 attr $00
    db $ed, $f4, $08, $00   ; dy -19 dx -12 tile 8 attr $00
    db $ec, $ec, $07, $00   ; dy -20 dx -20 tile 7 attr $00
    db $f0, $10, $0b, $00   ; dy -16 dx +16 tile 11 attr $00
    db $ee, $fb, $0d, $00   ; dy -18 dx -5 tile 13 attr $00
    db $ee, $03, $0e, $00   ; dy -18 dx +3 tile 14 attr $00
    db $f0, $00, $09, $00   ; dy -16 dx +0 tile 9 attr $00
    db $f0, $08, $0a, $00   ; dy -16 dx +8 tile 10 attr $00
    db $80
Anim_20_F15:   ; $7ac9 15 sprites
    db $e4, $f5, $09, $00   ; dy -28 dx -11 tile 9 attr $00
    db $e4, $fd, $0a, $00   ; dy -28 dx -3 tile 10 attr $00
    db $e4, $05, $0b, $00   ; dy -28 dx +5 tile 11 attr $00
    db $d0, $00, $10, $00   ; dy -48 dx +0 tile 16 attr $00
    db $d0, $08, $11, $00   ; dy -48 dx +8 tile 17 attr $00
    db $d0, $10, $12, $00   ; dy -48 dx +16 tile 18 attr $00
    db $d0, $f8, $0f, $00   ; dy -48 dx -8 tile 15 attr $00
    db $d8, $f8, $13, $00   ; dy -40 dx -8 tile 19 attr $00
    db $d8, $00, $14, $00   ; dy -40 dx +0 tile 20 attr $00
    db $d8, $0c, $15, $00   ; dy -40 dx +12 tile 21 attr $00
    db $f8, $ee, $1c, $00   ; dy -8 dx -18 tile 28 attr $00
    db $f8, $f6, $1d, $00   ; dy -8 dx -10 tile 29 attr $00
    db $f4, $fe, $1e, $00   ; dy -12 dx -2 tile 30 attr $00
    db $f4, $06, $1f, $00   ; dy -12 dx +6 tile 31 attr $00
    db $f0, $ee, $1b, $00   ; dy -16 dx -18 tile 27 attr $00
    db $80
Anim_20_F16:   ; $7b06 16 sprites
    db $e6, $f3, $0c, $00   ; dy -26 dx -13 tile 12 attr $00
    db $e6, $fb, $0d, $00   ; dy -26 dx -5 tile 13 attr $00
    db $e6, $03, $0e, $00   ; dy -26 dx +3 tile 14 attr $00
    db $d0, $00, $16, $00   ; dy -48 dx +0 tile 22 attr $00
    db $d8, $00, $19, $00   ; dy -40 dx +0 tile 25 attr $00
    db $d7, $0e, $15, $00   ; dy -41 dx +14 tile 21 attr $00
    db $d0, $08, $17, $00   ; dy -48 dx +8 tile 23 attr $00
    db $d8, $08, $1a, $00   ; dy -40 dx +8 tile 26 attr $00
    db $d0, $10, $18, $00   ; dy -48 dx +16 tile 24 attr $00
    db $f0, $f6, $10, $00   ; dy -16 dx -10 tile 16 attr $00
    db $f0, $fe, $11, $00   ; dy -16 dx -2 tile 17 attr $00
    db $f0, $06, $12, $00   ; dy -16 dx +6 tile 18 attr $00
    db $f0, $ee, $0f, $00   ; dy -16 dx -18 tile 15 attr $00
    db $f8, $ee, $13, $00   ; dy -8 dx -18 tile 19 attr $00
    db $f8, $f6, $14, $00   ; dy -8 dx -10 tile 20 attr $00
    db $f8, $02, $15, $00   ; dy -8 dx +2 tile 21 attr $00
    db $80
Anim_20_F17:   ; $7b47 14 sprites
    db $f0, $f6, $16, $00   ; dy -16 dx -10 tile 22 attr $00
    db $f8, $f6, $19, $00   ; dy -8 dx -10 tile 25 attr $00
    db $f7, $04, $15, $00   ; dy -9 dx +4 tile 21 attr $00
    db $f0, $fe, $17, $00   ; dy -16 dx -2 tile 23 attr $00
    db $f8, $fe, $1a, $00   ; dy -8 dx -2 tile 26 attr $00
    db $f0, $06, $18, $00   ; dy -16 dx +6 tile 24 attr $00
    db $e8, $f0, $09, $00   ; dy -24 dx -16 tile 9 attr $00
    db $e8, $f8, $0a, $00   ; dy -24 dx -8 tile 10 attr $00
    db $e8, $00, $0b, $00   ; dy -24 dx +0 tile 11 attr $00
    db $d8, $f0, $0c, $00   ; dy -40 dx -16 tile 12 attr $00
    db $d8, $f8, $0d, $00   ; dy -40 dx -8 tile 13 attr $00
    db $d8, $00, $0e, $00   ; dy -40 dx +0 tile 14 attr $00
    db $dc, $04, $02, $00   ; dy -36 dx +4 tile 2 attr $00
    db $dc, $0c, $03, $00   ; dy -36 dx +12 tile 3 attr $00
    db $80
Anim_20_F18:   ; $7b80 11 sprites
    db $f0, $e8, $1c, $00   ; dy -16 dx -24 tile 28 attr $00
    db $f0, $f0, $1d, $00   ; dy -16 dx -16 tile 29 attr $00
    db $e8, $e8, $1b, $00   ; dy -24 dx -24 tile 27 attr $00
    db $ec, $f8, $1e, $00   ; dy -20 dx -8 tile 30 attr $00
    db $ec, $00, $1f, $00   ; dy -20 dx +0 tile 31 attr $00
    db $f8, $f0, $0c, $00   ; dy -8 dx -16 tile 12 attr $00
    db $f8, $f8, $0d, $00   ; dy -8 dx -8 tile 13 attr $00
    db $f8, $00, $0e, $00   ; dy -8 dx +0 tile 14 attr $00
    db $dc, $00, $09, $00   ; dy -36 dx +0 tile 9 attr $00
    db $dc, $08, $0a, $00   ; dy -36 dx +8 tile 10 attr $00
    db $dc, $10, $0b, $00   ; dy -36 dx +16 tile 11 attr $00
    db $80
Anim_20_F19:   ; $7bad 17 sprites
    db $e8, $f0, $10, $00   ; dy -24 dx -16 tile 16 attr $00
    db $e8, $f8, $11, $00   ; dy -24 dx -8 tile 17 attr $00
    db $e8, $00, $12, $00   ; dy -24 dx +0 tile 18 attr $00
    db $e8, $e8, $0f, $00   ; dy -24 dx -24 tile 15 attr $00
    db $f0, $e8, $13, $00   ; dy -16 dx -24 tile 19 attr $00
    db $f0, $f0, $14, $00   ; dy -16 dx -16 tile 20 attr $00
    db $f0, $fc, $15, $00   ; dy -16 dx -4 tile 21 attr $00
    db $f2, $ff, $0c, $00   ; dy -14 dx -1 tile 12 attr $00
    db $f2, $07, $0d, $00   ; dy -14 dx +7 tile 13 attr $00
    db $f2, $0f, $0e, $00   ; dy -14 dx +15 tile 14 attr $00
    db $e0, $f8, $1c, $00   ; dy -32 dx -8 tile 28 attr $00
    db $e0, $00, $1d, $00   ; dy -32 dx +0 tile 29 attr $00
    db $dc, $08, $1e, $00   ; dy -36 dx +8 tile 30 attr $00
    db $dc, $10, $1f, $00   ; dy -36 dx +16 tile 31 attr $00
    db $d8, $f8, $1b, $00   ; dy -40 dx -8 tile 27 attr $00
    db $d6, $eb, $02, $00   ; dy -42 dx -21 tile 2 attr $00
    db $d6, $f3, $03, $00   ; dy -42 dx -13 tile 3 attr $00
    db $80
Anim_20_F20:   ; $7bf2 21 sprites
    db $e8, $f0, $16, $00   ; dy -24 dx -16 tile 22 attr $00
    db $f0, $f0, $19, $00   ; dy -16 dx -16 tile 25 attr $00
    db $ef, $fe, $15, $00   ; dy -17 dx -2 tile 21 attr $00
    db $f0, $f8, $1a, $00   ; dy -16 dx -8 tile 26 attr $00
    db $e8, $f8, $17, $00   ; dy -24 dx -8 tile 23 attr $00
    db $e8, $00, $18, $00   ; dy -24 dx +0 tile 24 attr $00
    db $f0, $00, $04, $00   ; dy -16 dx +0 tile 4 attr $00
    db $f0, $08, $05, $00   ; dy -16 dx +8 tile 5 attr $00
    db $f0, $10, $06, $00   ; dy -16 dx +16 tile 6 attr $00
    db $f8, $00, $08, $00   ; dy -8 dx +0 tile 8 attr $00
    db $f7, $f8, $07, $00   ; dy -9 dx -8 tile 7 attr $00
    db $d0, $f4, $09, $00   ; dy -48 dx -12 tile 9 attr $00
    db $d0, $fc, $0a, $00   ; dy -48 dx -4 tile 10 attr $00
    db $d0, $04, $0b, $00   ; dy -48 dx +4 tile 11 attr $00
    db $d8, $00, $10, $00   ; dy -40 dx +0 tile 16 attr $00
    db $d8, $08, $11, $00   ; dy -40 dx +8 tile 17 attr $00
    db $d8, $10, $12, $00   ; dy -40 dx +16 tile 18 attr $00
    db $d8, $f8, $0f, $00   ; dy -40 dx -8 tile 15 attr $00
    db $e0, $f8, $13, $00   ; dy -32 dx -8 tile 19 attr $00
    db $e0, $00, $14, $00   ; dy -32 dx +0 tile 20 attr $00
    db $e0, $0c, $15, $00   ; dy -32 dx +12 tile 21 attr $00
    db $80
Anim_20_F21:   ; $7c47 19 sprites
    db $f0, $10, $0b, $00   ; dy -16 dx +16 tile 11 attr $00
    db $f0, $00, $09, $00   ; dy -16 dx +0 tile 9 attr $00
    db $f0, $08, $0a, $00   ; dy -16 dx +8 tile 10 attr $00
    db $d8, $e8, $1c, $00   ; dy -40 dx -24 tile 28 attr $00
    db $d8, $f0, $1d, $00   ; dy -40 dx -16 tile 29 attr $00
    db $d4, $f8, $1e, $00   ; dy -44 dx -8 tile 30 attr $00
    db $d4, $00, $1f, $00   ; dy -44 dx +0 tile 31 attr $00
    db $d0, $e8, $1b, $00   ; dy -48 dx -24 tile 27 attr $00
    db $d8, $00, $16, $00   ; dy -40 dx +0 tile 22 attr $00
    db $e0, $00, $19, $00   ; dy -32 dx +0 tile 25 attr $00
    db $df, $0e, $15, $00   ; dy -33 dx +14 tile 21 attr $00
    db $d8, $08, $17, $00   ; dy -40 dx +8 tile 23 attr $00
    db $e0, $08, $1a, $00   ; dy -32 dx +8 tile 26 attr $00
    db $d8, $10, $18, $00   ; dy -40 dx +16 tile 24 attr $00
    db $f0, $e8, $0c, $00   ; dy -16 dx -24 tile 12 attr $00
    db $f0, $f0, $0d, $00   ; dy -16 dx -16 tile 13 attr $00
    db $f0, $f8, $0e, $00   ; dy -16 dx -8 tile 14 attr $00
    db $e8, $f8, $02, $00   ; dy -24 dx -8 tile 2 attr $00
    db $e8, $00, $03, $00   ; dy -24 dx +0 tile 3 attr $00
    db $80
Anim_20_F22:   ; $7c94 15 sprites
    db $e0, $f5, $09, $00   ; dy -32 dx -11 tile 9 attr $00
    db $e0, $fd, $0a, $00   ; dy -32 dx -3 tile 10 attr $00
    db $e0, $05, $0b, $00   ; dy -32 dx +5 tile 11 attr $00
    db $d0, $00, $10, $00   ; dy -48 dx +0 tile 16 attr $00
    db $d0, $08, $11, $00   ; dy -48 dx +8 tile 17 attr $00
    db $d0, $10, $12, $00   ; dy -48 dx +16 tile 18 attr $00
    db $d0, $f8, $0f, $00   ; dy -48 dx -8 tile 15 attr $00
    db $d8, $f8, $13, $00   ; dy -40 dx -8 tile 19 attr $00
    db $d8, $00, $14, $00   ; dy -40 dx +0 tile 20 attr $00
    db $d8, $0c, $15, $00   ; dy -40 dx +12 tile 21 attr $00
    db $f4, $ee, $1c, $00   ; dy -12 dx -18 tile 28 attr $00
    db $f4, $f6, $1d, $00   ; dy -12 dx -10 tile 29 attr $00
    db $f0, $fe, $1e, $00   ; dy -16 dx -2 tile 30 attr $00
    db $f0, $06, $1f, $00   ; dy -16 dx +6 tile 31 attr $00
    db $ec, $ee, $1b, $00   ; dy -20 dx -18 tile 27 attr $00
    db $80
Anim_20_F23:   ; $7cd1 16 sprites
    db $e2, $f3, $0c, $00   ; dy -30 dx -13 tile 12 attr $00
    db $e2, $fb, $0d, $00   ; dy -30 dx -5 tile 13 attr $00
    db $e2, $03, $0e, $00   ; dy -30 dx +3 tile 14 attr $00
    db $d0, $00, $16, $00   ; dy -48 dx +0 tile 22 attr $00
    db $d8, $00, $19, $00   ; dy -40 dx +0 tile 25 attr $00
    db $d7, $0e, $15, $00   ; dy -41 dx +14 tile 21 attr $00
    db $d0, $08, $17, $00   ; dy -48 dx +8 tile 23 attr $00
    db $d8, $08, $1a, $00   ; dy -40 dx +8 tile 26 attr $00
    db $d0, $10, $18, $00   ; dy -48 dx +16 tile 24 attr $00
    db $ec, $f6, $10, $00   ; dy -20 dx -10 tile 16 attr $00
    db $ec, $fe, $11, $00   ; dy -20 dx -2 tile 17 attr $00
    db $ec, $06, $12, $00   ; dy -20 dx +6 tile 18 attr $00
    db $ec, $ee, $0f, $00   ; dy -20 dx -18 tile 15 attr $00
    db $f4, $ee, $13, $00   ; dy -12 dx -18 tile 19 attr $00
    db $f4, $f6, $14, $00   ; dy -12 dx -10 tile 20 attr $00
    db $f4, $02, $15, $00   ; dy -12 dx +2 tile 21 attr $00
    db $80
Anim_20_F24:   ; $7d12 11 sprites
    db $ec, $ee, $16, $00   ; dy -20 dx -18 tile 22 attr $00
    db $f4, $ee, $19, $00   ; dy -12 dx -18 tile 25 attr $00
    db $f3, $fc, $15, $00   ; dy -13 dx -4 tile 21 attr $00
    db $ec, $f6, $17, $00   ; dy -20 dx -10 tile 23 attr $00
    db $f4, $f6, $1a, $00   ; dy -12 dx -10 tile 26 attr $00
    db $ec, $fe, $18, $00   ; dy -20 dx -2 tile 24 attr $00
    db $e0, $fd, $00, $00   ; dy -32 dx -3 tile 0 attr $00
    db $e0, $05, $01, $00   ; dy -32 dx +5 tile 1 attr $00
    db $d8, $f0, $0c, $00   ; dy -40 dx -16 tile 12 attr $00
    db $d8, $f8, $0d, $00   ; dy -40 dx -8 tile 13 attr $00
    db $d8, $00, $0e, $00   ; dy -40 dx +0 tile 14 attr $00
    db $80
Anim_20_F25:   ; $7d3f 7 sprites
    db $e0, $fd, $02, $00   ; dy -32 dx -3 tile 2 attr $00
    db $e0, $05, $03, $00   ; dy -32 dx +5 tile 3 attr $00
    db $d4, $fb, $00, $00   ; dy -44 dx -5 tile 0 attr $00
    db $d4, $03, $01, $00   ; dy -44 dx +3 tile 1 attr $00
    db $f4, $e8, $0c, $00   ; dy -12 dx -24 tile 12 attr $00
    db $f4, $f0, $0d, $00   ; dy -12 dx -16 tile 13 attr $00
    db $f4, $f8, $0e, $00   ; dy -12 dx -8 tile 14 attr $00
Anim_20_F26:   ; $7d5b empty frame = the $80 end above (shared)
    db $80
; NOTE: unreferenced fake-decode labels removed with this block: jr_05d_41d4, jr_05d_41d8, jr_05d_41e8, jr_05d_41f1, jr_05d_4201, jr_05d_4215, jr_05d_4234, jr_05d_423b, jr_05d_429d, jr_05d_42bd, jr_05d_42cf, jr_05d_42d4, jr_05d_431e, jr_05d_442d, jr_05d_4497, jr_05d_44c6, jr_05d_44ce, jr_05d_44d2, jr_05d_44de, jr_05d_44ea, jr_05d_4502, jr_05d_450e, jr_05d_451a, jr_05d_4526, jr_05d_453f, jr_05d_4557, jr_05d_456f, jr_05d_4570, jr_05d_457b, jr_05d_4593, jr_05d_45ab, jr_05d_45b7, jr_05d_45d1, jr_05d_45e8, jr_05d_45f4, jr_05d_4600, jr_05d_460c, jr_05d_4624, jr_05d_463c, jr_05d_4648, jr_05d_4661, jr_05d_4679, jr_05d_4691, jr_05d_4692, jr_05d_469d, jr_05d_46a9, jr_05d_46b5, jr_05d_46cd, jr_05d_46f3, jr_05d_470a, jr_05d_4716, jr_05d_4722, jr_05d_472e, jr_05d_473a, jr_05d_4746, jr_05d_4752, jr_05d_475e, jr_05d_4783, jr_05d_479b, jr_05d_479c, jr_05d_47b3, jr_05d_47bf, jr_05d_47cb, jr_05d_47d7, jr_05d_47e3, jr_05d_47ef, jr_05d_4815, jr_05d_482c, jr_05d_4838, jr_05d_4844, jr_05d_4850, jr_05d_48d4, jr_05d_48f4, jr_05d_4927, jr_05d_495b, jr_05d_4965, jr_05d_4998, jr_05d_49c4, jr_05d_49cd, jr_05d_49e4, jr_05d_49e5, jr_05d_49ff, jr_05d_4a32, jr_05d_4a65, jr_05d_4a75, jr_05d_4a86, jr_05d_4a92, jr_05d_4a96, jr_05d_4aa0, jr_05d_4aa2, jr_05d_4aa8, jr_05d_4aaa, jr_05d_4ab2, jr_05d_4aba, jr_05d_4ace, jr_05d_4aeb, jr_05d_4af2, jr_05d_4afe, jr_05d_4b0a, jr_05d_4b16, jr_05d_4b2b, jr_05d_4b38, jr_05d_4b44, jr_05d_4b66, jr_05d_4b9f, jr_05d_4bc3, jr_05d_4bc9, jr_05d_4bd5, jr_05d_4c2e, jr_05d_4c35, jr_05d_4c52, jr_05d_4c5a, jr_05d_4c66, jr_05d_4cba, jr_05d_4cc5, jr_05d_4ced, jr_05d_4d4a, jr_05d_4d63, jr_05d_4d8e, jr_05d_4de0, jr_05d_4dec, jr_05d_4e2c, jr_05d_4e61, jr_05d_4e74, jr_05d_4eae, jr_05d_4ec5, jr_05d_4ecc, jr_05d_4f1c, jr_05d_4f20, jr_05d_4f24, jr_05d_4f28, jr_05d_4f2c, jr_05d_4f30, jr_05d_4f38, jr_05d_4f5e, jr_05d_4f62, jr_05d_4f63, jr_05d_4f68, jr_05d_4f77, jr_05d_4f7c, jr_05d_4f80, jr_05d_4faf, jr_05d_4fc7, jr_05d_501d, jr_05d_5024, jr_05d_5028, jr_05d_502d, jr_05d_5035, jr_05d_503b, jr_05d_5040, jr_05d_5050, jr_05d_5058, jr_05d_505c, jr_05d_506c, jr_05d_5070, jr_05d_5085, jr_05d_50aa, jr_05d_50df, jr_05d_5142, jr_05d_5156, jr_05d_5162, jr_05d_518f, jr_05d_5192, jr_05d_51b4, jr_05d_51b7, jr_05d_51ef, jr_05d_5249, jr_05d_524e, jr_05d_5282, jr_05d_58cb, jr_05d_58da, jr_05d_58f2, jr_05d_5974, jr_05d_5ade, jr_05d_5b4b, jr_05d_5b5b, jr_05d_5b63, jr_05d_5b98, jr_05d_5b9c, jr_05d_5bbc, jr_05d_5c1d, jr_05d_5d4c, jr_05d_5dc9, jr_05d_5df1, jr_05d_5e49, jr_05d_5e73, jr_05d_5e75, jr_05d_5e87, jr_05d_614e, jr_05d_6189, jr_05d_61d6, jr_05d_61e2, jr_05d_622b, jr_05d_6236, jr_05d_6265, jr_05d_626a, jr_05d_626f, jr_05d_62cb, jr_05d_630a, jr_05d_630f, jr_05d_6311, jr_05d_6316, jr_05d_631b, jr_05d_6333, jr_05d_6370, jr_05d_6387, jr_05d_63a1, jr_05d_63f6, jr_05d_63f8, jr_05d_63fb, jr_05d_646e, jr_05d_647f, jr_05d_64b7, jr_05d_6509, jr_05d_6538, jr_05d_6560, jr_05d_658b, jr_05d_658e, jr_05d_65b9, jr_05d_65d9, jr_05d_6619, jr_05d_661e, jr_05d_6623, jr_05d_6632, jr_05d_6687, jr_05d_66bd, jr_05d_66c3, jr_05d_66c7, jr_05d_671b, jr_05d_6758, jr_05d_676f, jr_05d_6774, jr_05d_6795, jr_05d_67d5, jr_05d_681e, jr_05d_68c7, jr_05d_68d1, jr_05d_68d4, jr_05d_68f0, jr_05d_6970, jr_05d_6a9d, jr_05d_6ace, jr_05d_6ad6, jr_05d_6b4b, jr_05d_6b5f, jr_05d_6b8b, jr_05d_6bf0, jr_05d_6c12, jr_05d_6c33, jr_05d_6c45, jr_05d_6c55, jr_05d_6c57, jr_05d_6c5e, jr_05d_6c61, jr_05d_6c72, jr_05d_6c75, jr_05d_6c91, jr_05d_6c99, jr_05d_6d2a, jr_05d_6d34, jr_05d_6d51, jr_05d_6da6, jr_05d_6f6b, jr_05d_6f8b, jr_05d_6f95, jr_05d_6fac, jr_05d_6ffa, jr_05d_7010, jr_05d_7056, jr_05d_7058, jr_05d_7060, jr_05d_7068, jr_05d_706c, jr_05d_7080, jr_05d_7094, jr_05d_7098, jr_05d_709c, jr_05d_70a1, jr_05d_7149, jr_05d_7153, jr_05d_715f, jr_05d_7163, jr_05d_7167, jr_05d_716b, jr_05d_716f, jr_05d_7177, jr_05d_7184, jr_05d_718b, jr_05d_71a7, jr_05d_71b2, jr_05d_7209, jr_05d_7211, jr_05d_7215, jr_05d_7231, jr_05d_7235, jr_05d_724a, jr_05d_725e, jr_05d_726e, jr_05d_7286, jr_05d_72a7, jr_05d_72ab, jr_05d_72bb, jr_05d_72d3, jr_05d_72fc, jr_05d_7306, jr_05d_730b, jr_05d_7320, jr_05d_7324, jr_05d_732a, jr_05d_7336, jr_05d_733c, jr_05d_7340, jr_05d_734c, jr_05d_7354, jr_05d_738f, jr_05d_73e1, jr_05d_740a, jr_05d_7419, jr_05d_7423, jr_05d_744c, jr_05d_7499, jr_05d_750b, jr_05d_7527, jr_05d_7535, jr_05d_7559, jr_05d_7579, jr_05d_758a, jr_05d_759a, jr_05d_759e, jr_05d_75a0, jr_05d_75aa, jr_05d_75ae, jr_05d_75ba, jr_05d_75c2, jr_05d_75ca, jr_05d_75d2, jr_05d_75d6, jr_05d_75e6, jr_05d_760a, jr_05d_7616, jr_05d_7622, jr_05d_762e, jr_05d_7643, jr_05d_764c, jr_05d_7658, jr_05d_765c, jr_05d_7690, jr_05d_76e1, jr_05d_76ed, jr_05d_7741, jr_05d_7746, jr_05d_774d, jr_05d_7766, jr_05d_776e, jr_05d_777a, jr_05d_7792, jr_05d_77c6, jr_05d_7846, jr_05d_7888, jr_05d_78b9, jr_05d_79ed, jr_05d_7a7b, jr_05d_7b2a, jr_05d_7b5f, jr_05d_7c0a, jr_05d_7c7f, jr_05d_7cf5
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
