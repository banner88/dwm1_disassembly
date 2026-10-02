; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $05c", ROMX[$4000], BANK[$5c]

    db $5C ; Bank number

    ; Cross-bank dispatch table (2 entries)
    ; Called via: ld hl, $5CXX / rst $10
    dw $4005                          ; Entry 0
    dw $408D                          ; Entry 1

; --- Dispatch entry 0 ($4005) ---
AnimTick5C:
    ld a, [$dd60]
    or a
    ret z

    ld de, $4071
    call AnimBuildOAM5C
    ld a, [$dd68]
    or a
    jr z, jr_05c_4021

    ld a, [$daa4]

CmpB5c_4019:
    cp $03
    jr z, jr_05c_4021

    cp $04
    jr nz, jr_05c_4031

jr_05c_4021:
    ld hl, $ffc3
    inc [hl]
    ld hl, $ffc3
    inc [hl]
    ld hl, $ffc3
    inc [hl]
    ld hl, $ffc3
    inc [hl]

jr_05c_4031:
    ld a, [$dd66]
    ldh [$c8], a
    ld a, [$dd62]
    or a
    jr nz, jr_05c_4041

    ld a, $00
    ld [$dd60], a

jr_05c_4041:
    ld a, [$dd68]
    or a
    ret nz

    ld a, [$daa4]
    cp $03
    jr z, jr_05c_4051

    cp $04
    jr nz, jr_05c_4061

jr_05c_4051:
    ldh a, [$c3]
    cp $d0
    ret c

    ld a, $04
    ld [$dd65], a
    ld a, $01
    ld [$dd68], a
    ret


jr_05c_4061:
    ldh a, [$c3]
    cp $c0
    ret c

    ld a, $00
    ld [$dd60], a
    ld a, $01
    ld [$dd68], a
    ret


AnimFrameTable5C:
    ; ANIMATION -> its 32 frame pointers, index [$c7] = animation number
    ; ($00-$0D bank $5C, $0E-$20 $5D, $21-$2C $5E — ROM0 AnimTickSelectAndDraw
    ; picks the bank). Re-sectioned S112.
    dw Anim_00_Blaze         ; [$00] Blaze
    dw Anim_01_Blazemore     ; [$01] Blazemore
    dw Anim_02_Blazemost     ; [$02] Blazemost, COMEDYBK
    dw Anim_03_Firebal       ; [$03] Firebal, FireAir
    dw Anim_04_Firebane      ; [$04] Firebane, BlazeAir, LAVASTAFF
    dw Anim_05_Firebolt      ; [$05] Firebolt, Scorching
    dw Anim_06_Bang          ; [$06] Bang
    dw Anim_07_Boom          ; [$07] Boom
    dw Anim_08_Explodet      ; [$08] Explodet
    dw Anim_09_Infernos      ; [$09] Infernos, WindBeast, STAFF
    dw Anim_0a_Infermore     ; [$0a] Infermore
    dw Anim_0b_Infermost     ; [$0b] Infermost, Vacuum
    dw Anim_0c_IceBolt       ; [$0c] IceBolt, FrigidAir
    dw Anim_0d_SnowStorm     ; [$0d] SnowStorm, IceAir
; bank $5C entry 1: start an animation — X from AnimTargetXTable5C[$db54] when [$dd68] != 0 (else 0 = fly in from the left), Y $60, [$c7] = [$daa4], [$c8] = its first frame (bank $02 entry 5) (S112)
AnimInit5C:
    ld a, $01
    ld [$dd62], a
    ld a, [$dd68]
    or a
    jr z, jr_05c_40aa

    ld a, [$db54]
    cp $07
    jr nc, jr_05c_40e5

    add a
    ld hl, $40ee
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]

jr_05c_40aa:
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

jr_05c_40c2:
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


jr_05c_40e5:
    xor a
    ld [$dd60], a
    xor a
    ld [$dd62], a
    ret


AnimTargetXTable5C:
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
; NOTE: unreferenced fake-decode labels removed with this block: jr_05c_40f4, jr_05c_40f8
AnimBuildOAM5C:
    ldh a, [$cb]
    cp $28
    jr nc, jr_05c_414c

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

jr_05c_411f:
    ld a, [de]
    inc de
    cp $80
    jr z, jr_05c_414c

    ld b, a
    ldh a, [$c5]
    add b
    add $10
    ld [hl+], a
    ld a, [de]
    inc de
    ld b, a

jr_05c_412f:
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
    jr c, jr_05c_411f

jr_05c_414c:
    ret


; ============================================================================
; BATTLE ANIMATION DATA (bank $5C): per animation 32 dw frame pointers
; (unused slots point at an empty frame; slot $1F = the blank) and the
; frames: 4-byte sprites (dy, dx, tile, attr) — X = dx + [$c3] + 8,
; Y = dy + [$c5] + 16, tile + [$c9], attr XOR [$ca] — $80 end; the builder
; draws at most 40. MEASURED S112 (tools/census_battle_anims.py: all 45
; animations, every frame == the shadow OAM). Re-sectioned S112.
; ============================================================================
Anim_00_Blaze:   ; $414d animation $00 — Blaze
    dw Anim_00_F00
    dw Anim_00_F01
    dw Anim_00_F02
    dw Anim_00_F03
    dw Anim_00_F04
    dw Anim_00_F05
    dw Anim_00_F06
    dw Anim_00_F07
    dw Anim_00_F08
    dw Anim_00_F08
    dw Anim_00_F08
    dw Anim_00_F08
    dw Anim_00_F08
    dw Anim_00_F08
    dw Anim_00_F08
    dw Anim_00_F08
    dw Anim_00_F08
    dw Anim_00_F08
    dw Anim_00_F08
    dw Anim_00_F08
    dw Anim_00_F08
    dw Anim_00_F08
    dw Anim_00_F08
    dw Anim_00_F08
    dw Anim_00_F08
    dw Anim_00_F08
    dw Anim_00_F08
    dw Anim_00_F08
    dw Anim_00_F08
    dw Anim_00_F08
    dw Anim_00_F08
    dw Anim_00_F08
Anim_00_F00:   ; $418d 2 sprites
    db $f8, $f8, $00, $00   ; dy -8 dx -8 tile 0 attr $00
    db $f8, $00, $01, $00   ; dy -8 dx +0 tile 1 attr $00
    db $80
Anim_00_F01:   ; $4196 6 sprites
    db $f0, $00, $00, $20   ; dy -16 dx +0 tile 0 attr $20
    db $f0, $f8, $01, $20   ; dy -16 dx -8 tile 1 attr $20
    db $f8, $08, $02, $20   ; dy -8 dx +8 tile 2 attr $20
    db $f8, $00, $03, $20   ; dy -8 dx +0 tile 3 attr $20
    db $f8, $f8, $04, $20   ; dy -8 dx -8 tile 4 attr $20
    db $f8, $f0, $05, $20   ; dy -8 dx -16 tile 5 attr $20
    db $80
Anim_00_F02:   ; $41af 7 sprites
    db $f8, $fc, $06, $00   ; dy -8 dx -4 tile 6 attr $00
    db $e8, $f8, $00, $00   ; dy -24 dx -8 tile 0 attr $00
    db $e8, $00, $01, $00   ; dy -24 dx +0 tile 1 attr $00
    db $f0, $f0, $02, $00   ; dy -16 dx -16 tile 2 attr $00
    db $f0, $f8, $03, $00   ; dy -16 dx -8 tile 3 attr $00
    db $f0, $00, $04, $00   ; dy -16 dx +0 tile 4 attr $00
    db $f0, $08, $05, $00   ; dy -16 dx +8 tile 5 attr $00
    db $80
Anim_00_F03:   ; $41cc 9 sprites
    db $de, $f8, $07, $00   ; dy -34 dx -8 tile 7 attr $00
    db $e6, $f0, $08, $00   ; dy -26 dx -16 tile 8 attr $00
    db $e6, $f8, $09, $00   ; dy -26 dx -8 tile 9 attr $00
    db $e6, $00, $0a, $00   ; dy -26 dx +0 tile 10 attr $00
    db $e6, $08, $0b, $00   ; dy -26 dx +8 tile 11 attr $00
    db $ee, $f8, $0c, $00   ; dy -18 dx -8 tile 12 attr $00
    db $ee, $00, $0d, $00   ; dy -18 dx +0 tile 13 attr $00
    db $ee, $08, $0e, $00   ; dy -18 dx +8 tile 14 attr $00
    db $f6, $00, $0f, $00   ; dy -10 dx +0 tile 15 attr $00
    db $80
Anim_00_F04:   ; $41f1 9 sprites
    db $f3, $01, $07, $60   ; dy -13 dx +1 tile 7 attr $60
    db $eb, $09, $08, $60   ; dy -21 dx +9 tile 8 attr $60
    db $eb, $01, $09, $60   ; dy -21 dx +1 tile 9 attr $60
    db $eb, $f9, $0a, $60   ; dy -21 dx -7 tile 10 attr $60
    db $eb, $f1, $0b, $60   ; dy -21 dx -15 tile 11 attr $60
    db $e3, $01, $0c, $60   ; dy -29 dx +1 tile 12 attr $60
    db $e3, $f9, $0d, $60   ; dy -29 dx -7 tile 13 attr $60
    db $e3, $f1, $0e, $60   ; dy -29 dx -15 tile 14 attr $60
    db $db, $f9, $0f, $60   ; dy -37 dx -7 tile 15 attr $60
    db $80
Anim_00_F05:   ; $4216 6 sprites
    db $ee, $f8, $14, $00   ; dy -18 dx -8 tile 20 attr $00
    db $ee, $00, $15, $00   ; dy -18 dx +0 tile 21 attr $00
    db $e6, $f8, $11, $00   ; dy -26 dx -8 tile 17 attr $00
    db $e6, $00, $12, $00   ; dy -26 dx +0 tile 18 attr $00
    db $e6, $08, $13, $00   ; dy -26 dx +8 tile 19 attr $00
    db $de, $00, $10, $00   ; dy -34 dx +0 tile 16 attr $00
    db $80
Anim_00_F06:   ; $422f 6 sprites
    db $e7, $01, $14, $60   ; dy -25 dx +1 tile 20 attr $60
    db $e7, $f9, $15, $60   ; dy -25 dx -7 tile 21 attr $60
    db $ef, $01, $11, $60   ; dy -17 dx +1 tile 17 attr $60
    db $ef, $f9, $12, $60   ; dy -17 dx -7 tile 18 attr $60
    db $ef, $f1, $13, $60   ; dy -17 dx -15 tile 19 attr $60
    db $f7, $f9, $10, $60   ; dy -9 dx -7 tile 16 attr $60
    db $80
Anim_00_F07:   ; $4248 4 sprites
    db $e8, $f7, $16, $00   ; dy -24 dx -9 tile 22 attr $00
    db $e8, $ff, $17, $00   ; dy -24 dx -1 tile 23 attr $00
    db $f0, $f7, $18, $00   ; dy -16 dx -9 tile 24 attr $00
    db $f0, $ff, $19, $00   ; dy -16 dx -1 tile 25 attr $00
Anim_00_F08:   ; $4258 empty frame = the $80 end above (shared)
    db $80
Anim_01_Blazemore:   ; $4259 animation $01 — Blazemore
    dw Anim_01_F00
    dw Anim_01_F01
    dw Anim_01_F02
    dw Anim_01_F03
    dw Anim_01_F04
    dw Anim_01_F05
    dw Anim_01_F06
    dw Anim_01_F07
    dw Anim_01_F08
    dw Anim_01_F09
    dw Anim_01_F10
    dw Anim_01_F11
    dw Anim_01_F12
    dw Anim_01_F13
    dw Anim_01_F14
    dw Anim_01_F15
    dw Anim_01_F15
    dw Anim_01_F15
    dw Anim_01_F15
    dw Anim_01_F15
    dw Anim_01_F15
    dw Anim_01_F15
    dw Anim_01_F15
    dw Anim_01_F15
    dw Anim_01_F15
    dw Anim_01_F15
    dw Anim_01_F15
    dw Anim_01_F15
    dw Anim_01_F15
    dw Anim_01_F15
    dw Anim_01_F15
    dw Anim_01_F15
Anim_01_F00:   ; $4299 2 sprites
    db $f8, $f8, $00, $00   ; dy -8 dx -8 tile 0 attr $00
    db $f8, $00, $01, $00   ; dy -8 dx +0 tile 1 attr $00
    db $80
Anim_01_F01:   ; $42a2 5 sprites
    db $f8, $fb, $03, $20   ; dy -8 dx -5 tile 3 attr $20
    db $f0, $00, $00, $20   ; dy -16 dx +0 tile 0 attr $20
    db $f8, $f3, $0d, $20   ; dy -8 dx -13 tile 13 attr $20
    db $f8, $03, $05, $20   ; dy -8 dx +3 tile 5 attr $20
    db $f0, $f8, $04, $20   ; dy -16 dx -8 tile 4 attr $20
    db $80
Anim_01_F02:   ; $42b7 9 sprites
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
Anim_01_F03:   ; $42dc 13 sprites
    db $f0, $f5, $06, $00   ; dy -16 dx -11 tile 6 attr $00
    db $f0, $05, $08, $00   ; dy -16 dx +5 tile 8 attr $00
    db $e8, $f3, $02, $00   ; dy -24 dx -13 tile 2 attr $00
    db $e8, $03, $04, $00   ; dy -24 dx +3 tile 4 attr $00
    db $e0, $fc, $04, $00   ; dy -32 dx -4 tile 4 attr $00
    db $e0, $f9, $02, $00   ; dy -32 dx -7 tile 2 attr $00
    db $e8, $fb, $07, $00   ; dy -24 dx -5 tile 7 attr $00
    db $f0, $fd, $0b, $00   ; dy -16 dx -3 tile 11 attr $00
    db $f0, $ef, $09, $00   ; dy -16 dx -17 tile 9 attr $00
    db $f8, $00, $0f, $60   ; dy -8 dx +0 tile 15 attr $60
    db $f8, $f8, $18, $40   ; dy -8 dx -8 tile 24 attr $40
    db $f8, $08, $12, $00   ; dy -8 dx +8 tile 18 attr $00
    db $f8, $f0, $17, $20   ; dy -8 dx -16 tile 23 attr $20
    db $80
Anim_01_F04:   ; $4311 15 sprites
    db $e8, $03, $06, $20   ; dy -24 dx +3 tile 6 attr $20
    db $e8, $f3, $08, $20   ; dy -24 dx -13 tile 8 attr $20
    db $e0, $05, $02, $20   ; dy -32 dx +5 tile 2 attr $20
    db $e0, $f5, $04, $20   ; dy -32 dx -11 tile 4 attr $20
    db $d8, $fc, $04, $20   ; dy -40 dx -4 tile 4 attr $20
    db $d8, $ff, $02, $20   ; dy -40 dx -1 tile 2 attr $20
    db $e0, $fd, $07, $20   ; dy -32 dx -3 tile 7 attr $20
    db $e8, $fb, $0b, $20   ; dy -24 dx -5 tile 11 attr $20
    db $e8, $09, $09, $20   ; dy -24 dx +9 tile 9 attr $20
    db $f0, $f8, $0f, $40   ; dy -16 dx -8 tile 15 attr $40
    db $f0, $f0, $12, $20   ; dy -16 dx -16 tile 18 attr $20
    db $f0, $08, $17, $00   ; dy -16 dx +8 tile 23 attr $00
    db $f0, $00, $18, $20   ; dy -16 dx +0 tile 24 attr $20
    db $f8, $f8, $23, $00   ; dy -8 dx -8 tile 35 attr $00
    db $f8, $00, $23, $20   ; dy -8 dx +0 tile 35 attr $20
    db $80
Anim_01_F05:   ; $434e 8 sprites
    db $d4, $fc, $1b, $20   ; dy -44 dx -4 tile 27 attr $20
    db $dc, $04, $1c, $20   ; dy -36 dx +4 tile 28 attr $20
    db $dc, $fc, $1d, $20   ; dy -36 dx -4 tile 29 attr $20
    db $dc, $f4, $1e, $20   ; dy -36 dx -12 tile 30 attr $20
    db $e4, $04, $1f, $20   ; dy -28 dx +4 tile 31 attr $20
    db $e4, $fc, $20, $20   ; dy -28 dx -4 tile 32 attr $20
    db $e4, $f4, $21, $20   ; dy -28 dx -12 tile 33 attr $20
    db $ec, $fc, $22, $20   ; dy -20 dx -4 tile 34 attr $20
    db $80
Anim_01_F06:   ; $436f 8 sprites
    db $d8, $fc, $1b, $00   ; dy -40 dx -4 tile 27 attr $00
    db $e0, $f4, $1c, $00   ; dy -32 dx -12 tile 28 attr $00
    db $e0, $fc, $1d, $00   ; dy -32 dx -4 tile 29 attr $00
    db $e0, $04, $1e, $00   ; dy -32 dx +4 tile 30 attr $00
    db $e8, $f4, $1f, $00   ; dy -24 dx -12 tile 31 attr $00
    db $e8, $fc, $20, $00   ; dy -24 dx -4 tile 32 attr $00
    db $e8, $04, $21, $00   ; dy -24 dx +4 tile 33 attr $00
    db $f0, $fc, $22, $00   ; dy -16 dx -4 tile 34 attr $00
    db $80
Anim_01_F07:   ; $4390 3 sprites
    db $e8, $fc, $25, $20   ; dy -24 dx -4 tile 37 attr $20
    db $e0, $fc, $24, $20   ; dy -32 dx -4 tile 36 attr $20
    db $f0, $fc, $22, $20   ; dy -16 dx -4 tile 34 attr $20
    db $80
Anim_01_F08:   ; $439d 9 sprites
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
Anim_01_F09:   ; $43c2 15 sprites
    db $f8, $05, $11, $00   ; dy -8 dx +5 tile 17 attr $00
    db $f8, $f5, $0f, $00   ; dy -8 dx -11 tile 15 attr $00
    db $f0, $0b, $09, $20   ; dy -16 dx +11 tile 9 attr $20
    db $f8, $ed, $17, $20   ; dy -8 dx -19 tile 23 attr $20
    db $f8, $0d, $13, $20   ; dy -8 dx +13 tile 19 attr $20
    db $f8, $fd, $20, $00   ; dy -8 dx -3 tile 32 attr $00
    db $f0, $03, $0c, $00   ; dy -16 dx +3 tile 12 attr $00
    db $f0, $fb, $18, $00   ; dy -16 dx -5 tile 24 attr $00
    db $e8, $06, $02, $20   ; dy -24 dx +6 tile 2 attr $20
    db $e8, $fe, $03, $20   ; dy -24 dx -2 tile 3 attr $20
    db $e8, $f6, $04, $20   ; dy -24 dx -10 tile 4 attr $20
    db $d8, $fd, $24, $20   ; dy -40 dx -3 tile 36 attr $20
    db $e0, $fd, $25, $20   ; dy -32 dx -3 tile 37 attr $20
    db $f0, $f3, $09, $00   ; dy -16 dx -13 tile 9 attr $00
    db $f0, $ed, $05, $00   ; dy -16 dx -19 tile 5 attr $00
    db $80
Anim_01_F10:   ; $43ff 19 sprites
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
Anim_01_F11:   ; $444c 25 sprites
    db $f0, $fd, $10, $00   ; dy -16 dx -3 tile 16 attr $00
    db $f0, $05, $11, $00   ; dy -16 dx +5 tile 17 attr $00
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
    db $d8, $05, $1c, $20   ; dy -40 dx +5 tile 28 attr $20
    db $f8, $e8, $1f, $00   ; dy -8 dx -24 tile 31 attr $00
    db $f8, $08, $16, $00   ; dy -8 dx +8 tile 22 attr $00
    db $f8, $f8, $15, $00   ; dy -8 dx -8 tile 21 attr $00
    db $f8, $f0, $14, $00   ; dy -8 dx -16 tile 20 attr $00
    db $f8, $00, $10, $20   ; dy -8 dx +0 tile 16 attr $20
    db $f8, $10, $21, $00   ; dy -8 dx +16 tile 33 attr $00
    db $f0, $0d, $1c, $20   ; dy -16 dx +13 tile 28 attr $20
    db $80
Anim_01_F12:   ; $44b1 21 sprites
    db $f0, $fb, $10, $20   ; dy -16 dx -5 tile 16 attr $20
    db $f0, $f3, $11, $20   ; dy -16 dx -13 tile 17 attr $20
    db $f0, $eb, $12, $20   ; dy -16 dx -21 tile 18 attr $20
    db $f0, $03, $0f, $20   ; dy -16 dx +3 tile 15 attr $20
    db $e8, $f5, $0c, $20   ; dy -24 dx -11 tile 12 attr $20
    db $e8, $ed, $0d, $20   ; dy -24 dx -19 tile 13 attr $20
    db $f8, $e8, $17, $20   ; dy -8 dx -24 tile 23 attr $20
    db $f8, $f0, $18, $00   ; dy -8 dx -16 tile 24 attr $00
    db $f8, $00, $20, $20   ; dy -8 dx +0 tile 32 attr $20
    db $f8, $08, $14, $20   ; dy -8 dx +8 tile 20 attr $20
    db $e8, $fd, $18, $20   ; dy -24 dx -3 tile 24 attr $20
    db $e0, $f1, $02, $00   ; dy -32 dx -15 tile 2 attr $00
    db $e0, $f9, $03, $00   ; dy -32 dx -7 tile 3 attr $00
    db $e0, $01, $04, $00   ; dy -32 dx +1 tile 4 attr $00
    db $d8, $fb, $25, $00   ; dy -40 dx -5 tile 37 attr $00
    db $cf, $03, $00, $20   ; dy -49 dx +3 tile 0 attr $20
    db $d0, $fb, $24, $00   ; dy -48 dx -5 tile 36 attr $00
    db $e8, $05, $09, $20   ; dy -24 dx +5 tile 9 attr $20
    db $f0, $0b, $1e, $00   ; dy -16 dx +11 tile 30 attr $00
    db $f8, $10, $0d, $00   ; dy -8 dx +16 tile 13 attr $00
    db $f8, $f8, $20, $40   ; dy -8 dx -8 tile 32 attr $40
    db $80
Anim_01_F13:   ; $4506 18 sprites
    db $e4, $03, $06, $20   ; dy -28 dx +3 tile 6 attr $20
    db $e4, $f3, $08, $20   ; dy -28 dx -13 tile 8 attr $20
    db $dc, $05, $02, $20   ; dy -36 dx +5 tile 2 attr $20
    db $dc, $f5, $04, $20   ; dy -36 dx -11 tile 4 attr $20
    db $d4, $fc, $04, $20   ; dy -44 dx -4 tile 4 attr $20
    db $d4, $ff, $02, $00   ; dy -44 dx -1 tile 2 attr $00
    db $dc, $fd, $07, $20   ; dy -36 dx -3 tile 7 attr $20
    db $e4, $fb, $0b, $20   ; dy -28 dx -5 tile 11 attr $20
    db $e4, $09, $09, $20   ; dy -28 dx +9 tile 9 attr $20
    db $ec, $f8, $0f, $40   ; dy -20 dx -8 tile 15 attr $40
    db $ec, $f0, $12, $20   ; dy -20 dx -16 tile 18 attr $20
    db $ec, $08, $17, $00   ; dy -20 dx +8 tile 23 attr $00
    db $ec, $00, $18, $20   ; dy -20 dx +0 tile 24 attr $20
    db $f4, $f4, $1f, $40   ; dy -12 dx -12 tile 31 attr $40
    db $f4, $fc, $20, $40   ; dy -12 dx -4 tile 32 attr $40
    db $f4, $04, $1f, $60   ; dy -12 dx +4 tile 31 attr $60
    db $fc, $f8, $23, $00   ; dy -4 dx -8 tile 35 attr $00
    db $fc, $00, $23, $20   ; dy -4 dx +0 tile 35 attr $20
    db $80
Anim_01_F14:   ; $454f 11 sprites
    db $d0, $fc, $1b, $20   ; dy -48 dx -4 tile 27 attr $20
    db $d8, $04, $1c, $20   ; dy -40 dx +4 tile 28 attr $20
    db $d8, $fc, $1d, $20   ; dy -40 dx -4 tile 29 attr $20
    db $d8, $f4, $1e, $20   ; dy -40 dx -12 tile 30 attr $20
    db $e0, $04, $1f, $20   ; dy -32 dx +4 tile 31 attr $20
    db $e0, $fc, $20, $20   ; dy -32 dx -4 tile 32 attr $20
    db $e0, $f4, $21, $20   ; dy -32 dx -12 tile 33 attr $20
    db $e8, $fc, $25, $00   ; dy -24 dx -4 tile 37 attr $00
    db $f0, $fc, $22, $00   ; dy -16 dx -4 tile 34 attr $00
    db $e8, $03, $21, $00   ; dy -24 dx +3 tile 33 attr $00
    db $e8, $f5, $1f, $00   ; dy -24 dx -11 tile 31 attr $00
Anim_01_F15:   ; $457b empty frame = the $80 end above (shared)
    db $80
Anim_02_Blazemost:   ; $457c animation $02 — Blazemost, COMEDYBK
    dw Anim_02_F00
    dw Anim_02_F01
    dw Anim_02_F02
    dw Anim_02_F03
    dw Anim_02_F04
    dw Anim_02_F05
    dw Anim_02_F06
    dw Anim_02_F07
    dw Anim_02_F08
    dw Anim_02_F09
    dw Anim_02_F10
    dw Anim_02_F11
    dw Anim_02_F12
    dw Anim_02_F13
    dw Anim_02_F14
    dw Anim_02_F15
    dw Anim_02_F16
    dw Anim_02_F16
    dw Anim_02_F16
    dw Anim_02_F16
    dw Anim_02_F16
    dw Anim_02_F16
    dw Anim_02_F16
    dw Anim_02_F16
    dw Anim_02_F16
    dw Anim_02_F16
    dw Anim_02_F16
    dw Anim_02_F16
    dw Anim_02_F16
    dw Anim_02_F16
    dw Anim_02_F16
    dw Anim_02_F16
Anim_02_F00:   ; $45bc 10 sprites
    db $f0, $f0, $00, $00   ; dy -16 dx -16 tile 0 attr $00
    db $f0, $f8, $01, $00   ; dy -16 dx -8 tile 1 attr $00
    db $f0, $00, $02, $00   ; dy -16 dx +0 tile 2 attr $00
    db $f0, $08, $03, $00   ; dy -16 dx +8 tile 3 attr $00
    db $f8, $f0, $15, $00   ; dy -8 dx -16 tile 21 attr $00
    db $f8, $f8, $16, $00   ; dy -8 dx -8 tile 22 attr $00
    db $f8, $08, $15, $20   ; dy -8 dx +8 tile 21 attr $20
    db $f8, $00, $16, $20   ; dy -8 dx +0 tile 22 attr $20
    db $f8, $10, $19, $00   ; dy -8 dx +16 tile 25 attr $00
    db $f8, $e8, $19, $20   ; dy -8 dx -24 tile 25 attr $20
    db $80
Anim_02_F01:   ; $45e5 14 sprites
    db $e8, $08, $00, $20   ; dy -24 dx +8 tile 0 attr $20
    db $e8, $00, $01, $20   ; dy -24 dx +0 tile 1 attr $20
    db $e8, $f8, $02, $20   ; dy -24 dx -8 tile 2 attr $20
    db $e8, $f0, $03, $20   ; dy -24 dx -16 tile 3 attr $20
    db $f0, $08, $10, $20   ; dy -16 dx +8 tile 16 attr $20
    db $f0, $00, $11, $20   ; dy -16 dx +0 tile 17 attr $20
    db $f0, $f8, $12, $20   ; dy -16 dx -8 tile 18 attr $20
    db $f0, $f0, $13, $20   ; dy -16 dx -16 tile 19 attr $20
    db $f8, $f8, $17, $20   ; dy -8 dx -8 tile 23 attr $20
    db $f8, $f0, $18, $20   ; dy -8 dx -16 tile 24 attr $20
    db $f8, $00, $17, $00   ; dy -8 dx +0 tile 23 attr $00
    db $f8, $08, $18, $00   ; dy -8 dx +8 tile 24 attr $00
    db $f8, $10, $1a, $00   ; dy -8 dx +16 tile 26 attr $00
    db $f8, $e8, $1a, $20   ; dy -8 dx -24 tile 26 attr $20
    db $80
Anim_02_F02:   ; $461e 18 sprites
    db $e0, $f0, $00, $00   ; dy -32 dx -16 tile 0 attr $00
    db $e0, $f8, $01, $00   ; dy -32 dx -8 tile 1 attr $00
    db $e0, $00, $02, $00   ; dy -32 dx +0 tile 2 attr $00
    db $e0, $08, $03, $00   ; dy -32 dx +8 tile 3 attr $00
    db $e8, $f0, $10, $00   ; dy -24 dx -16 tile 16 attr $00
    db $e8, $f8, $11, $00   ; dy -24 dx -8 tile 17 attr $00
    db $e8, $00, $12, $00   ; dy -24 dx +0 tile 18 attr $00
    db $e8, $08, $13, $00   ; dy -24 dx +8 tile 19 attr $00
    db $f0, $f0, $04, $00   ; dy -16 dx -16 tile 4 attr $00
    db $f0, $f8, $05, $00   ; dy -16 dx -8 tile 5 attr $00
    db $f0, $00, $06, $00   ; dy -16 dx +0 tile 6 attr $00
    db $f0, $08, $07, $00   ; dy -16 dx +8 tile 7 attr $00
    db $f8, $f0, $15, $00   ; dy -8 dx -16 tile 21 attr $00
    db $f8, $f8, $16, $00   ; dy -8 dx -8 tile 22 attr $00
    db $f8, $08, $15, $20   ; dy -8 dx +8 tile 21 attr $20
    db $f8, $00, $16, $20   ; dy -8 dx +0 tile 22 attr $20
    db $f8, $10, $19, $00   ; dy -8 dx +16 tile 25 attr $00
    db $f8, $e8, $19, $20   ; dy -8 dx -24 tile 25 attr $20
    db $80
Anim_02_F03:   ; $4667 26 sprites
    db $d0, $f0, $00, $00   ; dy -48 dx -16 tile 0 attr $00
    db $d0, $f8, $01, $00   ; dy -48 dx -8 tile 1 attr $00
    db $d0, $00, $02, $00   ; dy -48 dx +0 tile 2 attr $00
    db $d0, $08, $03, $00   ; dy -48 dx +8 tile 3 attr $00
    db $d8, $f0, $10, $00   ; dy -40 dx -16 tile 16 attr $00
    db $d8, $f8, $11, $00   ; dy -40 dx -8 tile 17 attr $00
    db $d8, $00, $12, $00   ; dy -40 dx +0 tile 18 attr $00
    db $d8, $08, $13, $00   ; dy -40 dx +8 tile 19 attr $00
    db $e0, $f0, $04, $00   ; dy -32 dx -16 tile 4 attr $00
    db $e0, $f8, $05, $00   ; dy -32 dx -8 tile 5 attr $00
    db $e0, $00, $06, $00   ; dy -32 dx +0 tile 6 attr $00
    db $e0, $08, $07, $00   ; dy -32 dx +8 tile 7 attr $00
    db $e8, $f8, $06, $00   ; dy -24 dx -8 tile 6 attr $00
    db $e8, $00, $09, $00   ; dy -24 dx +0 tile 9 attr $00
    db $e8, $08, $0a, $00   ; dy -24 dx +8 tile 10 attr $00
    db $e8, $f0, $08, $00   ; dy -24 dx -16 tile 8 attr $00
    db $f0, $f8, $09, $00   ; dy -16 dx -8 tile 9 attr $00
    db $f0, $f0, $0b, $00   ; dy -16 dx -16 tile 11 attr $00
    db $f0, $00, $0c, $00   ; dy -16 dx +0 tile 12 attr $00
    db $f0, $08, $0d, $00   ; dy -16 dx +8 tile 13 attr $00
    db $f8, $f8, $17, $20   ; dy -8 dx -8 tile 23 attr $20
    db $f8, $f0, $18, $20   ; dy -8 dx -16 tile 24 attr $20
    db $f8, $00, $17, $00   ; dy -8 dx +0 tile 23 attr $00
    db $f8, $08, $18, $00   ; dy -8 dx +8 tile 24 attr $00
    db $f8, $10, $1a, $00   ; dy -8 dx +16 tile 26 attr $00
    db $f8, $e8, $1a, $20   ; dy -8 dx -24 tile 26 attr $20
    db $80
Anim_02_F04:   ; $46d0 26 sprites
    db $d0, $f0, $04, $00   ; dy -48 dx -16 tile 4 attr $00
    db $d0, $f8, $05, $00   ; dy -48 dx -8 tile 5 attr $00
    db $d0, $00, $06, $00   ; dy -48 dx +0 tile 6 attr $00
    db $d0, $08, $07, $00   ; dy -48 dx +8 tile 7 attr $00
    db $d8, $f8, $06, $00   ; dy -40 dx -8 tile 6 attr $00
    db $d8, $00, $09, $00   ; dy -40 dx +0 tile 9 attr $00
    db $d8, $08, $0a, $00   ; dy -40 dx +8 tile 10 attr $00
    db $d8, $f0, $08, $00   ; dy -40 dx -16 tile 8 attr $00
    db $e0, $f8, $09, $00   ; dy -32 dx -8 tile 9 attr $00
    db $e0, $f0, $0b, $00   ; dy -32 dx -16 tile 11 attr $00
    db $e0, $00, $0c, $00   ; dy -32 dx +0 tile 12 attr $00
    db $e0, $08, $0d, $00   ; dy -32 dx +8 tile 13 attr $00
    db $e8, $f0, $0e, $00   ; dy -24 dx -16 tile 14 attr $00
    db $e8, $f8, $0c, $00   ; dy -24 dx -8 tile 12 attr $00
    db $e8, $00, $0f, $00   ; dy -24 dx +0 tile 15 attr $00
    db $e8, $08, $14, $00   ; dy -24 dx +8 tile 20 attr $00
    db $f0, $f0, $04, $00   ; dy -16 dx -16 tile 4 attr $00
    db $f0, $f8, $05, $00   ; dy -16 dx -8 tile 5 attr $00
    db $f0, $00, $06, $00   ; dy -16 dx +0 tile 6 attr $00
    db $f0, $08, $07, $00   ; dy -16 dx +8 tile 7 attr $00
    db $f8, $f0, $15, $00   ; dy -8 dx -16 tile 21 attr $00
    db $f8, $f8, $16, $00   ; dy -8 dx -8 tile 22 attr $00
    db $f8, $08, $15, $20   ; dy -8 dx +8 tile 21 attr $20
    db $f8, $00, $16, $20   ; dy -8 dx +0 tile 22 attr $20
    db $f8, $10, $19, $00   ; dy -8 dx +16 tile 25 attr $00
    db $f8, $e8, $19, $20   ; dy -8 dx -24 tile 25 attr $20
    db $80
Anim_02_F05:   ; $4739 26 sprites
    db $d0, $f8, $06, $00   ; dy -48 dx -8 tile 6 attr $00
    db $d0, $00, $09, $00   ; dy -48 dx +0 tile 9 attr $00
    db $d0, $08, $0a, $00   ; dy -48 dx +8 tile 10 attr $00
    db $d0, $f0, $08, $00   ; dy -48 dx -16 tile 8 attr $00
    db $d8, $f8, $09, $00   ; dy -40 dx -8 tile 9 attr $00
    db $d8, $f0, $0b, $00   ; dy -40 dx -16 tile 11 attr $00
    db $d8, $00, $0c, $00   ; dy -40 dx +0 tile 12 attr $00
    db $d8, $08, $0d, $00   ; dy -40 dx +8 tile 13 attr $00
    db $e0, $f0, $0e, $00   ; dy -32 dx -16 tile 14 attr $00
    db $e0, $f8, $0c, $00   ; dy -32 dx -8 tile 12 attr $00
    db $e0, $00, $0f, $00   ; dy -32 dx +0 tile 15 attr $00
    db $e0, $08, $14, $00   ; dy -32 dx +8 tile 20 attr $00
    db $e8, $f0, $04, $00   ; dy -24 dx -16 tile 4 attr $00
    db $e8, $f8, $05, $00   ; dy -24 dx -8 tile 5 attr $00
    db $e8, $00, $06, $00   ; dy -24 dx +0 tile 6 attr $00
    db $e8, $08, $07, $00   ; dy -24 dx +8 tile 7 attr $00
    db $f0, $f8, $06, $00   ; dy -16 dx -8 tile 6 attr $00
    db $f0, $00, $09, $00   ; dy -16 dx +0 tile 9 attr $00
    db $f0, $08, $0a, $00   ; dy -16 dx +8 tile 10 attr $00
    db $f0, $f0, $08, $00   ; dy -16 dx -16 tile 8 attr $00
    db $f8, $f8, $17, $20   ; dy -8 dx -8 tile 23 attr $20
    db $f8, $f0, $18, $20   ; dy -8 dx -16 tile 24 attr $20
    db $f8, $00, $17, $00   ; dy -8 dx +0 tile 23 attr $00
    db $f8, $08, $18, $00   ; dy -8 dx +8 tile 24 attr $00
    db $f8, $10, $1a, $00   ; dy -8 dx +16 tile 26 attr $00
    db $f8, $e8, $1a, $20   ; dy -8 dx -24 tile 26 attr $20
    db $80
Anim_02_F06:   ; $47a2 26 sprites
    db $d0, $f8, $09, $00   ; dy -48 dx -8 tile 9 attr $00
    db $d0, $f0, $0b, $00   ; dy -48 dx -16 tile 11 attr $00
    db $d0, $00, $0c, $00   ; dy -48 dx +0 tile 12 attr $00
    db $d0, $08, $0d, $00   ; dy -48 dx +8 tile 13 attr $00
    db $d8, $f0, $0e, $00   ; dy -40 dx -16 tile 14 attr $00
    db $d8, $f8, $0c, $00   ; dy -40 dx -8 tile 12 attr $00
    db $d8, $00, $0f, $00   ; dy -40 dx +0 tile 15 attr $00
    db $d8, $08, $14, $00   ; dy -40 dx +8 tile 20 attr $00
    db $e0, $f0, $04, $00   ; dy -32 dx -16 tile 4 attr $00
    db $e0, $f8, $05, $00   ; dy -32 dx -8 tile 5 attr $00
    db $e0, $00, $06, $00   ; dy -32 dx +0 tile 6 attr $00
    db $e0, $08, $07, $00   ; dy -32 dx +8 tile 7 attr $00
    db $e8, $f8, $06, $00   ; dy -24 dx -8 tile 6 attr $00
    db $e8, $00, $09, $00   ; dy -24 dx +0 tile 9 attr $00
    db $e8, $08, $0a, $00   ; dy -24 dx +8 tile 10 attr $00
    db $e8, $f0, $08, $00   ; dy -24 dx -16 tile 8 attr $00
    db $f0, $f8, $09, $00   ; dy -16 dx -8 tile 9 attr $00
    db $f0, $f0, $0b, $00   ; dy -16 dx -16 tile 11 attr $00
    db $f0, $00, $0c, $00   ; dy -16 dx +0 tile 12 attr $00
    db $f0, $08, $0d, $00   ; dy -16 dx +8 tile 13 attr $00
    db $f8, $f0, $15, $00   ; dy -8 dx -16 tile 21 attr $00
    db $f8, $f8, $16, $00   ; dy -8 dx -8 tile 22 attr $00
    db $f8, $08, $15, $20   ; dy -8 dx +8 tile 21 attr $20
    db $f8, $00, $16, $20   ; dy -8 dx +0 tile 22 attr $20
    db $f8, $10, $19, $00   ; dy -8 dx +16 tile 25 attr $00
    db $f8, $e8, $19, $20   ; dy -8 dx -24 tile 25 attr $20
    db $80
Anim_02_F07:   ; $480b 26 sprites
    db $d0, $f0, $0e, $00   ; dy -48 dx -16 tile 14 attr $00
    db $d0, $f8, $0c, $00   ; dy -48 dx -8 tile 12 attr $00
    db $d0, $00, $0f, $00   ; dy -48 dx +0 tile 15 attr $00
    db $d0, $08, $14, $00   ; dy -48 dx +8 tile 20 attr $00
    db $d8, $f0, $04, $00   ; dy -40 dx -16 tile 4 attr $00
    db $d8, $f8, $05, $00   ; dy -40 dx -8 tile 5 attr $00
    db $d8, $00, $06, $00   ; dy -40 dx +0 tile 6 attr $00
    db $d8, $08, $07, $00   ; dy -40 dx +8 tile 7 attr $00
    db $e0, $f8, $06, $00   ; dy -32 dx -8 tile 6 attr $00
    db $e0, $00, $09, $00   ; dy -32 dx +0 tile 9 attr $00
    db $e0, $08, $0a, $00   ; dy -32 dx +8 tile 10 attr $00
    db $e0, $f0, $08, $00   ; dy -32 dx -16 tile 8 attr $00
    db $e8, $f8, $09, $00   ; dy -24 dx -8 tile 9 attr $00
    db $e8, $f0, $0b, $00   ; dy -24 dx -16 tile 11 attr $00
    db $e8, $00, $0c, $00   ; dy -24 dx +0 tile 12 attr $00
    db $e8, $08, $0d, $00   ; dy -24 dx +8 tile 13 attr $00
    db $f0, $f0, $0e, $00   ; dy -16 dx -16 tile 14 attr $00
    db $f0, $f8, $0c, $00   ; dy -16 dx -8 tile 12 attr $00
    db $f0, $00, $0f, $00   ; dy -16 dx +0 tile 15 attr $00
    db $f0, $08, $14, $00   ; dy -16 dx +8 tile 20 attr $00
    db $f8, $f8, $17, $20   ; dy -8 dx -8 tile 23 attr $20
    db $f8, $f0, $18, $20   ; dy -8 dx -16 tile 24 attr $20
    db $f8, $00, $17, $00   ; dy -8 dx +0 tile 23 attr $00
    db $f8, $08, $18, $00   ; dy -8 dx +8 tile 24 attr $00
    db $f8, $10, $1a, $00   ; dy -8 dx +16 tile 26 attr $00
    db $f8, $e8, $1a, $20   ; dy -8 dx -24 tile 26 attr $20
    db $80
Anim_02_F08:   ; $4874 2 sprites
    db $f8, $f8, $1b, $00   ; dy -8 dx -8 tile 27 attr $00
    db $f8, $00, $1b, $20   ; dy -8 dx +0 tile 27 attr $20
    db $80
Anim_02_F09:   ; $487d 6 sprites
    db $f0, $f8, $1c, $00   ; dy -16 dx -8 tile 28 attr $00
    db $f0, $00, $1d, $00   ; dy -16 dx +0 tile 29 attr $00
    db $f8, $f8, $1e, $00   ; dy -8 dx -8 tile 30 attr $00
    db $f8, $00, $1f, $00   ; dy -8 dx +0 tile 31 attr $00
    db $f8, $07, $27, $00   ; dy -8 dx +7 tile 39 attr $00
    db $f8, $f1, $26, $00   ; dy -8 dx -15 tile 38 attr $00
    db $80
Anim_02_F10:   ; $4896 9 sprites
    db $e8, $00, $1c, $20   ; dy -24 dx +0 tile 28 attr $20
    db $e8, $f8, $1d, $20   ; dy -24 dx -8 tile 29 attr $20
    db $f0, $00, $1e, $20   ; dy -16 dx +0 tile 30 attr $20
    db $f0, $f8, $1f, $20   ; dy -16 dx -8 tile 31 attr $20
    db $f7, $fc, $25, $00   ; dy -9 dx -4 tile 37 attr $00
    db $f0, $07, $26, $20   ; dy -16 dx +7 tile 38 attr $20
    db $f6, $03, $27, $00   ; dy -10 dx +3 tile 39 attr $00
    db $f4, $f4, $26, $00   ; dy -12 dx -12 tile 38 attr $00
    db $f0, $f1, $27, $20   ; dy -16 dx -15 tile 39 attr $20
    db $80
Anim_02_F11:   ; $48bb 9 sprites
    db $e4, $f8, $1c, $00   ; dy -28 dx -8 tile 28 attr $00
    db $e4, $00, $1d, $00   ; dy -28 dx +0 tile 29 attr $00
    db $ec, $f8, $1e, $00   ; dy -20 dx -8 tile 30 attr $00
    db $ec, $00, $1f, $00   ; dy -20 dx +0 tile 31 attr $00
    db $f3, $fc, $25, $20   ; dy -13 dx -4 tile 37 attr $20
    db $ec, $f1, $26, $00   ; dy -20 dx -15 tile 38 attr $00
    db $f2, $f5, $27, $20   ; dy -14 dx -11 tile 39 attr $20
    db $f0, $04, $26, $20   ; dy -16 dx +4 tile 38 attr $20
    db $ec, $07, $27, $00   ; dy -20 dx +7 tile 39 attr $00
    db $80
Anim_02_F12:   ; $48e0 4 sprites
    db $e4, $f8, $20, $00   ; dy -28 dx -8 tile 32 attr $00
    db $e4, $00, $21, $00   ; dy -28 dx +0 tile 33 attr $00
    db $ec, $f8, $22, $00   ; dy -20 dx -8 tile 34 attr $00
    db $ec, $00, $23, $00   ; dy -20 dx +0 tile 35 attr $00
    db $80
Anim_02_F13:   ; $48f1 4 sprites
    db $e6, $00, $20, $20   ; dy -26 dx +0 tile 32 attr $20
    db $e6, $f8, $21, $20   ; dy -26 dx -8 tile 33 attr $20
    db $ee, $00, $22, $20   ; dy -18 dx +0 tile 34 attr $20
    db $ee, $f8, $23, $20   ; dy -18 dx -8 tile 35 attr $20
    db $80
Anim_02_F14:   ; $4902 4 sprites
    db $e8, $f8, $20, $00   ; dy -24 dx -8 tile 32 attr $00
    db $e8, $00, $21, $00   ; dy -24 dx +0 tile 33 attr $00
    db $f0, $f8, $22, $00   ; dy -16 dx -8 tile 34 attr $00
    db $f0, $00, $23, $00   ; dy -16 dx +0 tile 35 attr $00
    db $80
Anim_02_F15:   ; $4913 1 sprites
    db $ec, $fc, $24, $00   ; dy -20 dx -4 tile 36 attr $00
Anim_02_F16:   ; $4917 empty frame = the $80 end above (shared)
    db $80
Anim_03_Firebal:   ; $4918 animation $03 — Firebal, FireAir
    dw Anim_03_F00
    dw Anim_03_F01
    dw Anim_03_F02
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
    dw Anim_03_F03
Anim_03_F00:   ; $4958 16 sprites
    db $f0, $d8, $00, $10   ; dy -16 dx -40 tile 0 attr $10
    db $f0, $e0, $01, $10   ; dy -16 dx -32 tile 1 attr $10
    db $f0, $ef, $02, $10   ; dy -16 dx -17 tile 2 attr $10
    db $f0, $00, $03, $10   ; dy -16 dx +0 tile 3 attr $10
    db $f0, $08, $04, $10   ; dy -16 dx +8 tile 4 attr $10
    db $f0, $18, $05, $10   ; dy -16 dx +24 tile 5 attr $10
    db $f8, $d8, $06, $10   ; dy -8 dx -40 tile 6 attr $10
    db $f8, $e0, $07, $10   ; dy -8 dx -32 tile 7 attr $10
    db $f8, $e8, $08, $10   ; dy -8 dx -24 tile 8 attr $10
    db $f8, $f0, $09, $10   ; dy -8 dx -16 tile 9 attr $10
    db $f8, $f8, $0a, $10   ; dy -8 dx -8 tile 10 attr $10
    db $f8, $00, $0b, $10   ; dy -8 dx +0 tile 11 attr $10
    db $f8, $08, $0c, $10   ; dy -8 dx +8 tile 12 attr $10
    db $f8, $10, $0d, $10   ; dy -8 dx +16 tile 13 attr $10
    db $f8, $18, $0e, $10   ; dy -8 dx +24 tile 14 attr $10
    db $f8, $20, $0f, $10   ; dy -8 dx +32 tile 15 attr $10
    db $80
Anim_03_F01:   ; $4999 16 sprites
    db $f0, $e8, $00, $10   ; dy -16 dx -24 tile 0 attr $10
    db $f0, $d8, $10, $10   ; dy -16 dx -40 tile 16 attr $10
    db $f0, $e0, $11, $10   ; dy -16 dx -32 tile 17 attr $10
    db $f0, $f0, $12, $10   ; dy -16 dx -16 tile 18 attr $10
    db $f0, $f8, $13, $10   ; dy -16 dx -8 tile 19 attr $10
    db $f0, $00, $14, $10   ; dy -16 dx +0 tile 20 attr $10
    db $f8, $d8, $15, $10   ; dy -8 dx -40 tile 21 attr $10
    db $f8, $e0, $16, $10   ; dy -8 dx -32 tile 22 attr $10
    db $f8, $e8, $17, $10   ; dy -8 dx -24 tile 23 attr $10
    db $f8, $f0, $18, $10   ; dy -8 dx -16 tile 24 attr $10
    db $f8, $f8, $19, $10   ; dy -8 dx -8 tile 25 attr $10
    db $f8, $00, $1a, $10   ; dy -8 dx +0 tile 26 attr $10
    db $f8, $08, $1b, $10   ; dy -8 dx +8 tile 27 attr $10
    db $f8, $10, $1c, $10   ; dy -8 dx +16 tile 28 attr $10
    db $f8, $18, $1d, $10   ; dy -8 dx +24 tile 29 attr $10
    db $f8, $20, $1e, $10   ; dy -8 dx +32 tile 30 attr $10
    db $80
Anim_03_F02:   ; $49da 15 sprites
    db $f0, $f8, $03, $10   ; dy -16 dx -8 tile 3 attr $10
    db $f0, $20, $03, $10   ; dy -16 dx +32 tile 3 attr $10
    db $f0, $e0, $1f, $10   ; dy -16 dx -32 tile 31 attr $10
    db $f0, $e8, $20, $10   ; dy -16 dx -24 tile 32 attr $10
    db $f0, $10, $21, $10   ; dy -16 dx +16 tile 33 attr $10
    db $f8, $d8, $22, $10   ; dy -8 dx -40 tile 34 attr $10
    db $f8, $e0, $23, $10   ; dy -8 dx -32 tile 35 attr $10
    db $f8, $e8, $24, $10   ; dy -8 dx -24 tile 36 attr $10
    db $f8, $f0, $25, $10   ; dy -8 dx -16 tile 37 attr $10
    db $f8, $f8, $26, $10   ; dy -8 dx -8 tile 38 attr $10
    db $f8, $00, $27, $10   ; dy -8 dx +0 tile 39 attr $10
    db $f8, $08, $28, $10   ; dy -8 dx +8 tile 40 attr $10
    db $f8, $10, $29, $10   ; dy -8 dx +16 tile 41 attr $10
    db $f8, $18, $2a, $10   ; dy -8 dx +24 tile 42 attr $10
    db $f8, $20, $2b, $10   ; dy -8 dx +32 tile 43 attr $10
Anim_03_F03:   ; $4a16 empty frame = the $80 end above (shared)
    db $80
Anim_04_Firebane:   ; $4a17 animation $04 — Firebane, BlazeAir, LAVASTAFF
    dw Anim_04_F00
    dw Anim_04_F01
    dw Anim_04_F02
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
    dw Anim_04_F03
Anim_04_F00:   ; $4a57 24 sprites
    db $e0, $f0, $00, $10   ; dy -32 dx -16 tile 0 attr $10
    db $e8, $f0, $01, $10   ; dy -24 dx -16 tile 1 attr $10
    db $e8, $f8, $02, $10   ; dy -24 dx -8 tile 2 attr $10
    db $e8, $00, $03, $10   ; dy -24 dx +0 tile 3 attr $10
    db $e8, $08, $04, $10   ; dy -24 dx +8 tile 4 attr $10
    db $f0, $e0, $05, $10   ; dy -16 dx -32 tile 5 attr $10
    db $f0, $e8, $06, $10   ; dy -16 dx -24 tile 6 attr $10
    db $f0, $f0, $07, $10   ; dy -16 dx -16 tile 7 attr $10
    db $f0, $f8, $08, $10   ; dy -16 dx -8 tile 8 attr $10
    db $f0, $00, $09, $10   ; dy -16 dx +0 tile 9 attr $10
    db $f0, $08, $0a, $10   ; dy -16 dx +8 tile 10 attr $10
    db $f0, $10, $0b, $10   ; dy -16 dx +16 tile 11 attr $10
    db $f0, $18, $0c, $10   ; dy -16 dx +24 tile 12 attr $10
    db $f8, $e8, $0d, $10   ; dy -8 dx -24 tile 13 attr $10
    db $f8, $00, $10, $10   ; dy -8 dx +0 tile 16 attr $10
    db $f8, $08, $11, $10   ; dy -8 dx +8 tile 17 attr $10
    db $f8, $10, $12, $10   ; dy -8 dx +16 tile 18 attr $10
    db $f8, $18, $13, $10   ; dy -8 dx +24 tile 19 attr $10
    db $f8, $20, $14, $10   ; dy -8 dx +32 tile 20 attr $10
    db $f8, $d8, $23, $30   ; dy -8 dx -40 tile 35 attr $30
    db $e8, $e8, $27, $30   ; dy -24 dx -24 tile 39 attr $30
    db $f8, $f0, $0e, $10   ; dy -8 dx -16 tile 14 attr $10
    db $f8, $f8, $0f, $10   ; dy -8 dx -8 tile 15 attr $10
    db $f8, $e0, $1f, $10   ; dy -8 dx -32 tile 31 attr $10
    db $80
Anim_04_F01:   ; $4ab8 19 sprites
    db $e0, $18, $04, $10   ; dy -32 dx +24 tile 4 attr $10
    db $f0, $e0, $06, $10   ; dy -16 dx -32 tile 6 attr $10
    db $f8, $10, $10, $10   ; dy -8 dx +16 tile 16 attr $10
    db $f8, $18, $11, $10   ; dy -8 dx +24 tile 17 attr $10
    db $f0, $d8, $15, $10   ; dy -16 dx -40 tile 21 attr $10
    db $f0, $e8, $16, $10   ; dy -16 dx -24 tile 22 attr $10
    db $f0, $f0, $17, $10   ; dy -16 dx -16 tile 23 attr $10
    db $f0, $f8, $18, $10   ; dy -16 dx -8 tile 24 attr $10
    db $f0, $08, $19, $10   ; dy -16 dx +8 tile 25 attr $10
    db $f0, $10, $1a, $10   ; dy -16 dx +16 tile 26 attr $10
    db $f0, $18, $1b, $10   ; dy -16 dx +24 tile 27 attr $10
    db $f8, $d8, $1c, $10   ; dy -8 dx -40 tile 28 attr $10
    db $f8, $e0, $1d, $10   ; dy -8 dx -32 tile 29 attr $10
    db $f8, $f8, $20, $10   ; dy -8 dx -8 tile 32 attr $10
    db $f8, $00, $21, $10   ; dy -8 dx +0 tile 33 attr $10
    db $f8, $08, $22, $10   ; dy -8 dx +8 tile 34 attr $10
    db $f8, $20, $23, $10   ; dy -8 dx +32 tile 35 attr $10
    db $f8, $e8, $1e, $10   ; dy -8 dx -24 tile 30 attr $10
    db $f8, $f0, $1f, $10   ; dy -8 dx -16 tile 31 attr $10
    db $80
Anim_04_F02:   ; $4b05 22 sprites
    db $e8, $20, $00, $10   ; dy -24 dx +32 tile 0 attr $10
    db $f0, $00, $05, $10   ; dy -16 dx +0 tile 5 attr $10
    db $f0, $e0, $0b, $10   ; dy -16 dx -32 tile 11 attr $10
    db $f0, $e8, $0c, $10   ; dy -16 dx -24 tile 12 attr $10
    db $f0, $18, $09, $10   ; dy -16 dx +24 tile 9 attr $10
    db $f8, $e0, $12, $10   ; dy -8 dx -32 tile 18 attr $10
    db $f0, $08, $19, $30   ; dy -16 dx +8 tile 25 attr $30
    db $e0, $18, $24, $10   ; dy -32 dx +24 tile 36 attr $10
    db $e8, $10, $25, $10   ; dy -24 dx +16 tile 37 attr $10
    db $e8, $18, $26, $10   ; dy -24 dx +24 tile 38 attr $10
    db $f8, $08, $20, $10   ; dy -8 dx +8 tile 32 attr $10
    db $f8, $f8, $23, $30   ; dy -8 dx -8 tile 35 attr $30
    db $f0, $f0, $27, $10   ; dy -16 dx -16 tile 39 attr $10
    db $f0, $10, $28, $10   ; dy -16 dx +16 tile 40 attr $10
    db $f0, $20, $29, $10   ; dy -16 dx +32 tile 41 attr $10
    db $f8, $d8, $2a, $10   ; dy -8 dx -40 tile 42 attr $10
    db $f8, $e8, $2b, $10   ; dy -8 dx -24 tile 43 attr $10
    db $f8, $f0, $2c, $10   ; dy -8 dx -16 tile 44 attr $10
    db $f8, $10, $2d, $10   ; dy -8 dx +16 tile 45 attr $10
    db $f8, $00, $1f, $10   ; dy -8 dx +0 tile 31 attr $10
    db $f8, $18, $0f, $10   ; dy -8 dx +24 tile 15 attr $10
    db $f8, $20, $2e, $10   ; dy -8 dx +32 tile 46 attr $10
Anim_04_F03:   ; $4b5d empty frame = the $80 end above (shared)
    db $80
Anim_05_Firebolt:   ; $4b5e animation $05 — Firebolt, Scorching
    dw Anim_05_F00
    dw Anim_05_F01
    dw Anim_05_F02
    dw Anim_05_F03
    dw Anim_05_F04
    dw Anim_05_F05
    dw Anim_05_F06
    dw Anim_05_F07
    dw Anim_05_F08
    dw Anim_05_F09
    dw Anim_05_F10
    dw Anim_05_F11
    dw Anim_05_F11
    dw Anim_05_F11
    dw Anim_05_F11
    dw Anim_05_F11
    dw Anim_05_F11
    dw Anim_05_F11
    dw Anim_05_F11
    dw Anim_05_F11
    dw Anim_05_F11
    dw Anim_05_F11
    dw Anim_05_F11
    dw Anim_05_F11
    dw Anim_05_F11
    dw Anim_05_F11
    dw Anim_05_F11
    dw Anim_05_F11
    dw Anim_05_F11
    dw Anim_05_F11
    dw Anim_05_F11
    dw Anim_05_F11
Anim_05_F00:   ; $4b9e 2 sprites
    db $f8, $b0, $04, $10   ; dy -8 dx -80 tile 4 attr $10
    db $f8, $48, $04, $30   ; dy -8 dx +72 tile 4 attr $30
    db $80
Anim_05_F01:   ; $4ba7 10 sprites
    db $f0, $be, $00, $10   ; dy -16 dx -66 tile 0 attr $10
    db $f8, $b6, $01, $10   ; dy -8 dx -74 tile 1 attr $10
    db $f8, $be, $02, $10   ; dy -8 dx -66 tile 2 attr $10
    db $f8, $c6, $03, $10   ; dy -8 dx -58 tile 3 attr $10
    db $f8, $ce, $09, $10   ; dy -8 dx -50 tile 9 attr $10
    db $f0, $3a, $00, $30   ; dy -16 dx +58 tile 0 attr $30
    db $f8, $42, $01, $30   ; dy -8 dx +66 tile 1 attr $30
    db $f8, $3a, $02, $30   ; dy -8 dx +58 tile 2 attr $30
    db $f8, $32, $03, $30   ; dy -8 dx +50 tile 3 attr $30
    db $f8, $2a, $09, $30   ; dy -8 dx +42 tile 9 attr $30
    db $80
Anim_05_F02:   ; $4bd0 12 sprites
    db $f8, $2c, $01, $30   ; dy -8 dx +44 tile 1 attr $30
    db $f8, $cc, $01, $10   ; dy -8 dx -52 tile 1 attr $10
    db $f0, $e4, $05, $10   ; dy -16 dx -28 tile 5 attr $10
    db $f8, $d4, $06, $10   ; dy -8 dx -44 tile 6 attr $10
    db $f8, $dc, $07, $10   ; dy -8 dx -36 tile 7 attr $10
    db $f8, $e4, $08, $10   ; dy -8 dx -28 tile 8 attr $10
    db $f8, $ec, $09, $10   ; dy -8 dx -20 tile 9 attr $10
    db $f8, $24, $06, $30   ; dy -8 dx +36 tile 6 attr $30
    db $f8, $1c, $07, $30   ; dy -8 dx +28 tile 7 attr $30
    db $f8, $14, $08, $30   ; dy -8 dx +20 tile 8 attr $30
    db $f8, $0c, $09, $30   ; dy -8 dx +12 tile 9 attr $30
    db $f0, $14, $05, $30   ; dy -16 dx +20 tile 5 attr $30
    db $80
Anim_05_F03:   ; $4c01 16 sprites
    db $ef, $0e, $00, $30   ; dy -17 dx +14 tile 0 attr $30
    db $d8, $f9, $10, $10   ; dy -40 dx -7 tile 16 attr $10
    db $e0, $f8, $11, $10   ; dy -32 dx -8 tile 17 attr $10
    db $e0, $00, $12, $10   ; dy -32 dx +0 tile 18 attr $10
    db $e8, $f8, $21, $10   ; dy -24 dx -8 tile 33 attr $10
    db $e8, $00, $22, $10   ; dy -24 dx +0 tile 34 attr $10
    db $f0, $f0, $13, $10   ; dy -16 dx -16 tile 19 attr $10
    db $f8, $f0, $23, $10   ; dy -8 dx -16 tile 35 attr $10
    db $f8, $f8, $24, $10   ; dy -8 dx -8 tile 36 attr $10
    db $f8, $00, $25, $10   ; dy -8 dx +0 tile 37 attr $10
    db $f8, $08, $26, $10   ; dy -8 dx +8 tile 38 attr $10
    db $f8, $e8, $20, $10   ; dy -8 dx -24 tile 32 attr $10
    db $f8, $10, $20, $30   ; dy -8 dx +16 tile 32 attr $30
    db $f0, $00, $15, $10   ; dy -16 dx +0 tile 21 attr $10
    db $f0, $08, $16, $10   ; dy -16 dx +8 tile 22 attr $10
    db $f0, $f8, $1e, $10   ; dy -16 dx -8 tile 30 attr $10
    db $80
Anim_05_F04:   ; $4c42 32 sprites
    db $d0, $00, $0a, $10   ; dy -48 dx +0 tile 10 attr $10
    db $d8, $00, $0b, $10   ; dy -40 dx +0 tile 11 attr $10
    db $d8, $07, $0c, $10   ; dy -40 dx +7 tile 12 attr $10
    db $e0, $04, $0e, $10   ; dy -32 dx +4 tile 14 attr $10
    db $e8, $08, $19, $10   ; dy -24 dx +8 tile 25 attr $10
    db $f0, $00, $19, $10   ; dy -16 dx +0 tile 25 attr $10
    db $f0, $08, $29, $10   ; dy -16 dx +8 tile 41 attr $10
    db $f0, $18, $17, $10   ; dy -16 dx +24 tile 23 attr $10
    db $f8, $17, $27, $10   ; dy -8 dx +23 tile 39 attr $10
    db $f0, $e0, $14, $10   ; dy -16 dx -32 tile 20 attr $10
    db $f0, $e8, $25, $10   ; dy -16 dx -24 tile 37 attr $10
    db $e0, $0c, $22, $10   ; dy -32 dx +12 tile 34 attr $10
    db $d8, $f8, $12, $30   ; dy -40 dx -8 tile 18 attr $30
    db $d8, $ee, $10, $30   ; dy -40 dx -18 tile 16 attr $30
    db $e0, $fc, $21, $10   ; dy -32 dx -4 tile 33 attr $10
    db $e8, $f8, $13, $10   ; dy -24 dx -8 tile 19 attr $10
    db $e8, $00, $15, $30   ; dy -24 dx +0 tile 21 attr $30
    db $f0, $f8, $28, $10   ; dy -16 dx -8 tile 40 attr $10
    db $f0, $f0, $28, $30   ; dy -16 dx -16 tile 40 attr $30
    db $f8, $0f, $23, $30   ; dy -8 dx +15 tile 35 attr $30
    db $e8, $10, $28, $30   ; dy -24 dx +16 tile 40 attr $30
    db $f8, $e0, $1a, $10   ; dy -8 dx -32 tile 26 attr $10
    db $f8, $e8, $1b, $10   ; dy -8 dx -24 tile 27 attr $10
    db $f8, $ff, $1b, $10   ; dy -8 dx -1 tile 27 attr $10
    db $f8, $07, $1c, $10   ; dy -8 dx +7 tile 28 attr $10
    db $f0, $10, $1e, $30   ; dy -16 dx +16 tile 30 attr $30
    db $f8, $f0, $2a, $10   ; dy -8 dx -16 tile 42 attr $10
    db $f8, $f7, $0b, $10   ; dy -8 dx -9 tile 11 attr $10
    db $e0, $ef, $1a, $30   ; dy -32 dx -17 tile 26 attr $30
    db $e0, $e7, $0c, $30   ; dy -32 dx -25 tile 12 attr $30
    db $e8, $e1, $22, $30   ; dy -24 dx -31 tile 34 attr $30
    db $e8, $e9, $18, $30   ; dy -24 dx -23 tile 24 attr $30
    db $80
Anim_05_F05:   ; $4cc3 47 sprites
    db $e8, $e8, $14, $10   ; dy -24 dx -24 tile 20 attr $10
    db $e0, $e7, $21, $10   ; dy -32 dx -25 tile 33 attr $10
    db $e0, $ef, $19, $10   ; dy -32 dx -17 tile 25 attr $10
    db $d8, $20, $17, $10   ; dy -40 dx +32 tile 23 attr $10
    db $e0, $1f, $27, $10   ; dy -32 dx +31 tile 39 attr $10
    db $d0, $dc, $22, $70   ; dy -48 dx -36 tile 34 attr $70
    db $e8, $18, $10, $50   ; dy -24 dx +24 tile 16 attr $50
    db $f8, $fa, $1c, $10   ; dy -8 dx -6 tile 28 attr $10
    db $e0, $df, $1d, $10   ; dy -32 dx -33 tile 29 attr $10
    db $f8, $f2, $2c, $10   ; dy -8 dx -14 tile 44 attr $10
    db $d0, $ec, $1c, $10   ; dy -48 dx -20 tile 28 attr $10
    db $d8, $e0, $18, $10   ; dy -40 dx -32 tile 24 attr $10
    db $d8, $e8, $19, $10   ; dy -40 dx -24 tile 25 attr $10
    db $d0, $e4, $29, $10   ; dy -48 dx -28 tile 41 attr $10
    db $d0, $f4, $29, $30   ; dy -48 dx -12 tile 41 attr $30
    db $d0, $fc, $1c, $50   ; dy -48 dx -4 tile 28 attr $50
    db $d0, $04, $19, $70   ; dy -48 dx +4 tile 25 attr $70
    db $d8, $f0, $19, $70   ; dy -40 dx -16 tile 25 attr $70
    db $e0, $f7, $29, $10   ; dy -32 dx -9 tile 41 attr $10
    db $d8, $f8, $1c, $10   ; dy -40 dx -8 tile 28 attr $10
    db $e8, $f0, $29, $10   ; dy -24 dx -16 tile 41 attr $10
    db $f0, $f4, $29, $50   ; dy -16 dx -12 tile 41 attr $50
    db $f8, $02, $0e, $50   ; dy -8 dx +2 tile 14 attr $50
    db $f0, $04, $0e, $70   ; dy -16 dx +4 tile 14 attr $70
    db $d8, $10, $19, $30   ; dy -40 dx +16 tile 25 attr $30
    db $d8, $00, $19, $70   ; dy -40 dx +0 tile 25 attr $70
    db $e0, $ff, $1c, $50   ; dy -32 dx -1 tile 28 attr $50
    db $e8, $f8, $1c, $50   ; dy -24 dx -8 tile 28 attr $50
    db $d0, $0c, $0e, $10   ; dy -48 dx +12 tile 14 attr $10
    db $d8, $08, $29, $10   ; dy -40 dx +8 tile 41 attr $10
    db $e0, $07, $29, $30   ; dy -32 dx +7 tile 41 attr $30
    db $e8, $00, $1b, $10   ; dy -24 dx +0 tile 27 attr $10
    db $d0, $14, $1c, $10   ; dy -48 dx +20 tile 28 attr $10
    db $e8, $08, $1c, $10   ; dy -24 dx +8 tile 28 attr $10
    db $f0, $fc, $29, $10   ; dy -16 dx -4 tile 41 attr $10
    db $d0, $1c, $0f, $10   ; dy -48 dx +28 tile 15 attr $10
    db $d8, $18, $14, $30   ; dy -40 dx +24 tile 20 attr $30
    db $e8, $10, $0f, $10   ; dy -24 dx +16 tile 15 attr $10
    db $e0, $0f, $2a, $50   ; dy -32 dx +15 tile 42 attr $50
    db $e0, $17, $10, $70   ; dy -32 dx +23 tile 16 attr $70
    db $f0, $0c, $28, $70   ; dy -16 dx +12 tile 40 attr $70
    db $f0, $ec, $0b, $50   ; dy -16 dx -20 tile 11 attr $50
    db $f8, $e2, $05, $10   ; dy -8 dx -30 tile 5 attr $10
    db $f8, $12, $20, $30   ; dy -8 dx +18 tile 32 attr $30
    db $f8, $1a, $16, $10   ; dy -8 dx +26 tile 22 attr $10
    db $f8, $ea, $2b, $10   ; dy -8 dx -22 tile 43 attr $10
    db $f8, $0a, $0d, $10   ; dy -8 dx +10 tile 13 attr $10
    db $80
Anim_05_F06:   ; $4d80 40 sprites
    db $f8, $0a, $26, $10   ; dy -8 dx +10 tile 38 attr $10
    db $e8, $19, $10, $10   ; dy -24 dx +25 tile 16 attr $10
    db $f0, $18, $11, $10   ; dy -16 dx +24 tile 17 attr $10
    db $f0, $20, $12, $10   ; dy -16 dx +32 tile 18 attr $10
    db $f8, $18, $21, $10   ; dy -8 dx +24 tile 33 attr $10
    db $f8, $20, $22, $10   ; dy -8 dx +32 tile 34 attr $10
    db $e0, $e8, $17, $10   ; dy -32 dx -24 tile 23 attr $10
    db $e8, $e8, $27, $10   ; dy -24 dx -24 tile 39 attr $10
    db $d8, $f0, $18, $10   ; dy -40 dx -16 tile 24 attr $10
    db $e8, $f4, $18, $10   ; dy -24 dx -12 tile 24 attr $10
    db $e0, $00, $18, $30   ; dy -32 dx +0 tile 24 attr $30
    db $f0, $00, $18, $30   ; dy -16 dx +0 tile 24 attr $30
    db $d0, $00, $19, $10   ; dy -48 dx +0 tile 25 attr $10
    db $d8, $f8, $19, $10   ; dy -40 dx -8 tile 25 attr $10
    db $d0, $f8, $29, $10   ; dy -48 dx -8 tile 41 attr $10
    db $e8, $fc, $0e, $10   ; dy -24 dx -4 tile 14 attr $10
    db $e8, $04, $22, $10   ; dy -24 dx +4 tile 34 attr $10
    db $d0, $f0, $21, $10   ; dy -48 dx -16 tile 33 attr $10
    db $d8, $10, $17, $30   ; dy -40 dx +16 tile 23 attr $30
    db $e0, $10, $27, $30   ; dy -32 dx +16 tile 39 attr $30
    db $d0, $20, $17, $10   ; dy -48 dx +32 tile 23 attr $10
    db $f0, $f0, $28, $10   ; dy -16 dx -16 tile 40 attr $10
    db $e8, $df, $10, $30   ; dy -24 dx -33 tile 16 attr $30
    db $f0, $e0, $11, $30   ; dy -16 dx -32 tile 17 attr $30
    db $f0, $d8, $12, $30   ; dy -16 dx -40 tile 18 attr $30
    db $f8, $e0, $21, $30   ; dy -8 dx -32 tile 33 attr $30
    db $f8, $d8, $0c, $30   ; dy -8 dx -40 tile 12 attr $30
    db $d8, $d8, $1d, $10   ; dy -40 dx -40 tile 29 attr $10
    db $e0, $28, $1d, $10   ; dy -32 dx +40 tile 29 attr $10
    db $d0, $08, $0f, $10   ; dy -48 dx +8 tile 15 attr $10
    db $f0, $f8, $1f, $10   ; dy -16 dx -8 tile 31 attr $10
    db $e0, $f8, $1f, $10   ; dy -32 dx -8 tile 31 attr $10
    db $f8, $f2, $2c, $10   ; dy -8 dx -14 tile 44 attr $10
    db $f8, $fa, $2d, $10   ; dy -8 dx -6 tile 45 attr $10
    db $e0, $f0, $1e, $10   ; dy -32 dx -16 tile 30 attr $10
    db $d8, $08, $1e, $30   ; dy -40 dx +8 tile 30 attr $30
    db $d8, $00, $29, $70   ; dy -40 dx +0 tile 41 attr $70
    db $f8, $02, $0d, $10   ; dy -8 dx +2 tile 13 attr $10
    db $f8, $28, $17, $30   ; dy -8 dx +40 tile 23 attr $30
    db $f8, $d0, $17, $10   ; dy -8 dx -48 tile 23 attr $10
    db $80
Anim_05_F07:   ; $4e21 35 sprites
    db $f0, $f0, $18, $10   ; dy -16 dx -16 tile 24 attr $10
    db $f0, $f8, $19, $10   ; dy -16 dx -8 tile 25 attr $10
    db $e4, $d4, $10, $10   ; dy -28 dx -44 tile 16 attr $10
    db $ec, $24, $11, $30   ; dy -20 dx +36 tile 17 attr $30
    db $f4, $1c, $27, $10   ; dy -12 dx +28 tile 39 attr $10
    db $ec, $1c, $28, $10   ; dy -20 dx +28 tile 40 attr $10
    db $e4, $24, $10, $30   ; dy -28 dx +36 tile 16 attr $30
    db $f8, $10, $0c, $10   ; dy -8 dx +16 tile 12 attr $10
    db $d8, $10, $17, $10   ; dy -40 dx +16 tile 23 attr $10
    db $e0, $10, $27, $10   ; dy -32 dx +16 tile 39 attr $10
    db $dc, $e8, $17, $30   ; dy -36 dx -24 tile 23 attr $30
    db $e4, $e8, $27, $30   ; dy -28 dx -24 tile 39 attr $30
    db $d0, $f8, $0a, $10   ; dy -48 dx -8 tile 10 attr $10
    db $d8, $f8, $0b, $10   ; dy -40 dx -8 tile 11 attr $10
    db $d8, $00, $0c, $10   ; dy -40 dx +0 tile 12 attr $10
    db $e0, $fc, $0e, $10   ; dy -32 dx -4 tile 14 attr $10
    db $e0, $04, $22, $10   ; dy -32 dx +4 tile 34 attr $10
    db $e8, $f0, $28, $10   ; dy -24 dx -16 tile 40 attr $10
    db $e8, $f8, $29, $10   ; dy -24 dx -8 tile 41 attr $10
    db $e8, $00, $19, $10   ; dy -24 dx +0 tile 25 attr $10
    db $f0, $08, $28, $30   ; dy -16 dx +8 tile 40 attr $30
    db $d8, $f0, $16, $30   ; dy -40 dx -16 tile 22 attr $30
    db $e8, $08, $0f, $10   ; dy -24 dx +8 tile 15 attr $10
    db $f8, $e8, $1a, $10   ; dy -8 dx -24 tile 26 attr $10
    db $f8, $f0, $1b, $10   ; dy -8 dx -16 tile 27 attr $10
    db $f8, $08, $1c, $70   ; dy -8 dx +8 tile 28 attr $70
    db $f8, $f8, $0e, $10   ; dy -8 dx -8 tile 14 attr $10
    db $f8, $00, $2d, $10   ; dy -8 dx +0 tile 45 attr $10
    db $f4, $24, $1e, $30   ; dy -12 dx +36 tile 30 attr $30
    db $f0, $00, $29, $10   ; dy -16 dx +0 tile 41 attr $10
    db $ec, $d4, $11, $10   ; dy -20 dx -44 tile 17 attr $10
    db $f4, $dc, $27, $30   ; dy -12 dx -36 tile 39 attr $30
    db $ec, $dc, $28, $30   ; dy -20 dx -36 tile 40 attr $30
    db $f4, $d4, $1e, $10   ; dy -12 dx -44 tile 30 attr $10
    db $e0, $f4, $18, $10   ; dy -32 dx -12 tile 24 attr $10
    db $80
Anim_05_F08:   ; $4eae 26 sprites
    db $ef, $0e, $00, $30   ; dy -17 dx +14 tile 0 attr $30
    db $d8, $f9, $10, $10   ; dy -40 dx -7 tile 16 attr $10
    db $e0, $f8, $11, $10   ; dy -32 dx -8 tile 17 attr $10
    db $e0, $00, $12, $10   ; dy -32 dx +0 tile 18 attr $10
    db $e8, $f8, $21, $10   ; dy -24 dx -8 tile 33 attr $10
    db $e8, $00, $22, $10   ; dy -24 dx +0 tile 34 attr $10
    db $f0, $f0, $13, $10   ; dy -16 dx -16 tile 19 attr $10
    db $f0, $f8, $14, $10   ; dy -16 dx -8 tile 20 attr $10
    db $f0, $00, $15, $10   ; dy -16 dx +0 tile 21 attr $10
    db $f0, $08, $16, $10   ; dy -16 dx +8 tile 22 attr $10
    db $f8, $f0, $23, $10   ; dy -8 dx -16 tile 35 attr $10
    db $f8, $f8, $24, $10   ; dy -8 dx -8 tile 36 attr $10
    db $f8, $00, $25, $10   ; dy -8 dx +0 tile 37 attr $10
    db $f8, $08, $26, $10   ; dy -8 dx +8 tile 38 attr $10
    db $f8, $e8, $20, $10   ; dy -8 dx -24 tile 32 attr $10
    db $f8, $10, $20, $30   ; dy -8 dx +16 tile 32 attr $30
    db $f0, $d4, $11, $10   ; dy -16 dx -44 tile 17 attr $10
    db $f0, $dc, $12, $10   ; dy -16 dx -36 tile 18 attr $10
    db $e8, $d8, $0a, $30   ; dy -24 dx -40 tile 10 attr $30
    db $f0, $24, $11, $30   ; dy -16 dx +36 tile 17 attr $30
    db $f0, $1c, $12, $30   ; dy -16 dx +28 tile 18 attr $30
    db $e8, $20, $0a, $10   ; dy -24 dx +32 tile 10 attr $10
    db $f8, $24, $0b, $30   ; dy -8 dx +36 tile 11 attr $30
    db $f8, $1c, $0c, $30   ; dy -8 dx +28 tile 12 attr $30
    db $f8, $d4, $0b, $10   ; dy -8 dx -44 tile 11 attr $10
    db $f8, $dc, $0c, $10   ; dy -8 dx -36 tile 12 attr $10
    db $80
Anim_05_F09:   ; $4f17 16 sprites
    db $f7, $ea, $00, $10   ; dy -9 dx -22 tile 0 attr $10
    db $f0, $1c, $17, $10   ; dy -16 dx +28 tile 23 attr $10
    db $f8, $1c, $27, $10   ; dy -8 dx +28 tile 39 attr $10
    db $f0, $dc, $17, $30   ; dy -16 dx -36 tile 23 attr $30
    db $f8, $dc, $27, $30   ; dy -8 dx -36 tile 39 attr $30
    db $e0, $ff, $10, $30   ; dy -32 dx -1 tile 16 attr $30
    db $e8, $00, $11, $30   ; dy -24 dx +0 tile 17 attr $30
    db $e8, $f8, $12, $30   ; dy -24 dx -8 tile 18 attr $30
    db $f0, $00, $21, $30   ; dy -16 dx +0 tile 33 attr $30
    db $f0, $f8, $22, $30   ; dy -16 dx -8 tile 34 attr $30
    db $f8, $08, $13, $30   ; dy -8 dx +8 tile 19 attr $30
    db $f8, $00, $14, $30   ; dy -8 dx +0 tile 20 attr $30
    db $f8, $f8, $15, $30   ; dy -8 dx -8 tile 21 attr $30
    db $f8, $f0, $16, $30   ; dy -8 dx -16 tile 22 attr $30
    db $f8, $d4, $1d, $10   ; dy -8 dx -44 tile 29 attr $10
    db $f8, $24, $1d, $30   ; dy -8 dx +36 tile 29 attr $30
    db $80
Anim_05_F10:   ; $4f58 8 sprites
    db $e8, $f8, $17, $10   ; dy -24 dx -8 tile 23 attr $10
    db $f8, $f8, $24, $10   ; dy -8 dx -8 tile 36 attr $10
    db $f8, $e8, $16, $10   ; dy -8 dx -24 tile 22 attr $10
    db $f8, $f0, $22, $30   ; dy -8 dx -16 tile 34 attr $30
    db $f8, $00, $22, $10   ; dy -8 dx +0 tile 34 attr $10
    db $f8, $08, $1d, $10   ; dy -8 dx +8 tile 29 attr $10
    db $f0, $f8, $11, $10   ; dy -16 dx -8 tile 17 attr $10
    db $f0, $fe, $1e, $70   ; dy -16 dx -2 tile 30 attr $70
Anim_05_F11:   ; $4f78 empty frame = the $80 end above (shared)
    db $80
Anim_06_Bang:   ; $4f79 animation $06 — Bang
    dw Anim_06_F00
    dw Anim_06_F01
    dw Anim_06_F02
    dw Anim_06_F03
    dw Anim_06_F04
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
    dw Anim_06_F05
Anim_06_F00:   ; $4fb9 4 sprites
    db $e2, $f8, $00, $00   ; dy -30 dx -8 tile 0 attr $00
    db $e2, $00, $01, $00   ; dy -30 dx +0 tile 1 attr $00
    db $ea, $f8, $02, $00   ; dy -22 dx -8 tile 2 attr $00
    db $ea, $00, $03, $00   ; dy -22 dx +0 tile 3 attr $00
    db $80
Anim_06_F01:   ; $4fca 4 sprites
    db $e4, $f8, $07, $00   ; dy -28 dx -8 tile 7 attr $00
    db $e4, $00, $08, $00   ; dy -28 dx +0 tile 8 attr $00
    db $ec, $f8, $09, $00   ; dy -20 dx -8 tile 9 attr $00
    db $ec, $00, $0a, $00   ; dy -20 dx +0 tile 10 attr $00
    db $80
Anim_06_F02:   ; $4fdb 8 sprites
    db $e8, $08, $00, $20   ; dy -24 dx +8 tile 0 attr $20
    db $e8, $00, $01, $20   ; dy -24 dx +0 tile 1 attr $20
    db $f0, $08, $02, $20   ; dy -16 dx +8 tile 2 attr $20
    db $f0, $00, $03, $20   ; dy -16 dx +0 tile 3 attr $20
    db $df, $f1, $00, $00   ; dy -33 dx -15 tile 0 attr $00
    db $df, $f9, $01, $00   ; dy -33 dx -7 tile 1 attr $00
    db $e7, $f1, $02, $00   ; dy -25 dx -15 tile 2 attr $00
    db $e7, $f9, $03, $00   ; dy -25 dx -7 tile 3 attr $00
    db $80
Anim_06_F03:   ; $4ffc 12 sprites
    db $e2, $00, $0f, $00   ; dy -30 dx +0 tile 15 attr $00
    db $e2, $08, $10, $00   ; dy -30 dx +8 tile 16 attr $00
    db $da, $00, $0c, $00   ; dy -38 dx +0 tile 12 attr $00
    db $da, $f8, $0b, $00   ; dy -38 dx -8 tile 11 attr $00
    db $ea, $ff, $0e, $60   ; dy -22 dx -1 tile 14 attr $60
    db $ea, $f7, $0f, $60   ; dy -22 dx -9 tile 15 attr $60
    db $ea, $ef, $10, $60   ; dy -22 dx -17 tile 16 attr $60
    db $ea, $07, $0d, $60   ; dy -22 dx +7 tile 13 attr $60
    db $f2, $f7, $0c, $60   ; dy -14 dx -9 tile 12 attr $60
    db $f2, $ff, $0b, $60   ; dy -14 dx -1 tile 11 attr $60
    db $e2, $f8, $0e, $00   ; dy -30 dx -8 tile 14 attr $00
    db $e2, $f0, $0d, $00   ; dy -30 dx -16 tile 13 attr $00
    db $80
Anim_06_F04:   ; $502d 9 sprites
    db $df, $06, $01, $00   ; dy -33 dx +6 tile 1 attr $00
    db $e7, $fe, $02, $00   ; dy -25 dx -2 tile 2 attr $00
    db $e7, $06, $03, $00   ; dy -25 dx +6 tile 3 attr $00
    db $df, $fe, $00, $00   ; dy -33 dx -2 tile 0 attr $00
    db $e6, $ef, $01, $20   ; dy -26 dx -17 tile 1 attr $20
    db $ee, $ef, $03, $20   ; dy -18 dx -17 tile 3 attr $20
    db $ee, $ff, $02, $20   ; dy -18 dx -1 tile 2 attr $20
    db $e6, $f7, $04, $00   ; dy -26 dx -9 tile 4 attr $00
    db $ee, $f7, $05, $00   ; dy -18 dx -9 tile 5 attr $00
Anim_06_F05:   ; $5051 empty frame = the $80 end above (shared)
    db $80
Anim_07_Boom:   ; $5052 animation $07 — Boom
    dw Anim_07_F00
    dw Anim_07_F01
    dw Anim_07_F02
    dw Anim_07_F03
    dw Anim_07_F04
    dw Anim_07_F05
    dw Anim_07_F06
    dw Anim_07_F07
    dw Anim_07_F08
    dw Anim_07_F09
    dw Anim_07_F09
    dw Anim_07_F09
    dw Anim_07_F09
    dw Anim_07_F09
    dw Anim_07_F09
    dw Anim_07_F09
    dw Anim_07_F09
    dw Anim_07_F09
    dw Anim_07_F09
    dw Anim_07_F09
    dw Anim_07_F09
    dw Anim_07_F09
    dw Anim_07_F09
    dw Anim_07_F09
    dw Anim_07_F09
    dw Anim_07_F09
    dw Anim_07_F09
    dw Anim_07_F09
    dw Anim_07_F09
    dw Anim_07_F09
    dw Anim_07_F09
    dw Anim_07_F09
Anim_07_F00:   ; $5092 24 sprites
    db $d0, $e8, $19, $00   ; dy -48 dx -24 tile 25 attr $00
    db $d0, $f0, $1a, $00   ; dy -48 dx -16 tile 26 attr $00
    db $d0, $f8, $1b, $00   ; dy -48 dx -8 tile 27 attr $00
    db $d0, $10, $19, $20   ; dy -48 dx +16 tile 25 attr $20
    db $d0, $08, $1a, $20   ; dy -48 dx +8 tile 26 attr $20
    db $d0, $00, $1b, $20   ; dy -48 dx +0 tile 27 attr $20
    db $f8, $e8, $19, $40   ; dy -8 dx -24 tile 25 attr $40
    db $f8, $f0, $1a, $40   ; dy -8 dx -16 tile 26 attr $40
    db $f8, $f8, $1b, $40   ; dy -8 dx -8 tile 27 attr $40
    db $f8, $10, $19, $60   ; dy -8 dx +16 tile 25 attr $60
    db $f8, $08, $1a, $60   ; dy -8 dx +8 tile 26 attr $60
    db $f8, $00, $1b, $60   ; dy -8 dx +0 tile 27 attr $60
    db $d8, $e8, $1c, $00   ; dy -40 dx -24 tile 28 attr $00
    db $d8, $f0, $1d, $00   ; dy -40 dx -16 tile 29 attr $00
    db $d8, $10, $1c, $20   ; dy -40 dx +16 tile 28 attr $20
    db $d8, $08, $1d, $20   ; dy -40 dx +8 tile 29 attr $20
    db $f0, $10, $1c, $60   ; dy -16 dx +16 tile 28 attr $60
    db $f0, $08, $1d, $60   ; dy -16 dx +8 tile 29 attr $60
    db $f0, $e8, $1c, $40   ; dy -16 dx -24 tile 28 attr $40
    db $f0, $f0, $1d, $40   ; dy -16 dx -16 tile 29 attr $40
    db $e0, $e8, $1e, $00   ; dy -32 dx -24 tile 30 attr $00
    db $e8, $e8, $1e, $40   ; dy -24 dx -24 tile 30 attr $40
    db $e0, $10, $1e, $20   ; dy -32 dx +16 tile 30 attr $20
    db $e8, $10, $1e, $60   ; dy -24 dx +16 tile 30 attr $60
    db $80
Anim_07_F01:   ; $50f3 16 sprites
    db $dc, $f0, $19, $00   ; dy -36 dx -16 tile 25 attr $00
    db $dc, $f8, $1a, $00   ; dy -36 dx -8 tile 26 attr $00
    db $e4, $f0, $1c, $00   ; dy -28 dx -16 tile 28 attr $00
    db $e4, $f8, $1d, $00   ; dy -28 dx -8 tile 29 attr $00
    db $dc, $08, $19, $20   ; dy -36 dx +8 tile 25 attr $20
    db $dc, $00, $1a, $20   ; dy -36 dx +0 tile 26 attr $20
    db $e4, $08, $1c, $20   ; dy -28 dx +8 tile 28 attr $20
    db $e4, $00, $1d, $20   ; dy -28 dx +0 tile 29 attr $20
    db $f4, $08, $19, $60   ; dy -12 dx +8 tile 25 attr $60
    db $f4, $00, $1a, $60   ; dy -12 dx +0 tile 26 attr $60
    db $ec, $08, $1c, $60   ; dy -20 dx +8 tile 28 attr $60
    db $ec, $00, $1d, $60   ; dy -20 dx +0 tile 29 attr $60
    db $f4, $f0, $19, $40   ; dy -12 dx -16 tile 25 attr $40
    db $f4, $f8, $1a, $40   ; dy -12 dx -8 tile 26 attr $40
    db $ec, $f0, $1c, $40   ; dy -20 dx -16 tile 28 attr $40
    db $ec, $f8, $1d, $40   ; dy -20 dx -8 tile 29 attr $40
    db $80
Anim_07_F02:   ; $5134 4 sprites
    db $ec, $f8, $19, $40   ; dy -20 dx -8 tile 25 attr $40
    db $ec, $00, $19, $60   ; dy -20 dx +0 tile 25 attr $60
    db $e4, $00, $19, $20   ; dy -28 dx +0 tile 25 attr $20
    db $e4, $f8, $19, $00   ; dy -28 dx -8 tile 25 attr $00
    db $80
Anim_07_F03:   ; $5145 9 sprites
    db $df, $06, $01, $00   ; dy -33 dx +6 tile 1 attr $00
    db $e7, $fe, $02, $00   ; dy -25 dx -2 tile 2 attr $00
    db $e7, $06, $03, $00   ; dy -25 dx +6 tile 3 attr $00
    db $df, $fe, $00, $00   ; dy -33 dx -2 tile 0 attr $00
    db $e6, $ef, $01, $20   ; dy -26 dx -17 tile 1 attr $20
    db $ee, $ef, $03, $20   ; dy -18 dx -17 tile 3 attr $20
    db $ee, $ff, $02, $20   ; dy -18 dx -1 tile 2 attr $20
    db $e6, $f7, $04, $00   ; dy -26 dx -9 tile 4 attr $00
    db $ee, $f7, $05, $00   ; dy -18 dx -9 tile 5 attr $00
    db $80
Anim_07_F04:   ; $516a 12 sprites
    db $e2, $00, $0f, $00   ; dy -30 dx +0 tile 15 attr $00
    db $e2, $08, $10, $00   ; dy -30 dx +8 tile 16 attr $00
    db $da, $00, $0c, $00   ; dy -38 dx +0 tile 12 attr $00
    db $da, $f8, $0b, $00   ; dy -38 dx -8 tile 11 attr $00
    db $ea, $ff, $0e, $60   ; dy -22 dx -1 tile 14 attr $60
    db $ea, $f7, $0f, $60   ; dy -22 dx -9 tile 15 attr $60
    db $ea, $ef, $10, $60   ; dy -22 dx -17 tile 16 attr $60
    db $ea, $07, $0d, $60   ; dy -22 dx +7 tile 13 attr $60
    db $f2, $f7, $0c, $60   ; dy -14 dx -9 tile 12 attr $60
    db $f2, $ff, $0b, $60   ; dy -14 dx -1 tile 11 attr $60
    db $e2, $f8, $0e, $00   ; dy -30 dx -8 tile 14 attr $00
    db $e2, $f0, $0d, $00   ; dy -30 dx -16 tile 13 attr $00
    db $80
Anim_07_F05:   ; $519b 20 sprites
    db $e8, $08, $00, $20   ; dy -24 dx +8 tile 0 attr $20
    db $e8, $00, $01, $20   ; dy -24 dx +0 tile 1 attr $20
    db $f0, $08, $02, $20   ; dy -16 dx +8 tile 2 attr $20
    db $f0, $00, $03, $20   ; dy -16 dx +0 tile 3 attr $20
    db $d5, $f9, $00, $00   ; dy -43 dx -7 tile 0 attr $00
    db $d5, $01, $01, $00   ; dy -43 dx +1 tile 1 attr $00
    db $dd, $f9, $02, $00   ; dy -35 dx -7 tile 2 attr $00
    db $dd, $01, $03, $00   ; dy -35 dx +1 tile 3 attr $00
    db $e4, $07, $02, $00   ; dy -28 dx +7 tile 2 attr $00
    db $e4, $0f, $03, $00   ; dy -28 dx +15 tile 3 attr $00
    db $dc, $11, $00, $20   ; dy -36 dx +17 tile 0 attr $20
    db $dc, $09, $01, $20   ; dy -36 dx +9 tile 1 attr $20
    db $df, $ee, $00, $00   ; dy -33 dx -18 tile 0 attr $00
    db $df, $f6, $01, $00   ; dy -33 dx -10 tile 1 attr $00
    db $e7, $ee, $02, $00   ; dy -25 dx -18 tile 2 attr $00
    db $e7, $f6, $03, $00   ; dy -25 dx -10 tile 3 attr $00
    db $ef, $fd, $00, $20   ; dy -17 dx -3 tile 0 attr $20
    db $ef, $f5, $01, $20   ; dy -17 dx -11 tile 1 attr $20
    db $f7, $fd, $02, $20   ; dy -9 dx -3 tile 2 attr $20
    db $f7, $f5, $03, $20   ; dy -9 dx -11 tile 3 attr $20
    db $80
Anim_07_F06:   ; $51ec 16 sprites
    db $f0, $fb, $07, $00   ; dy -16 dx -5 tile 7 attr $00
    db $f0, $03, $08, $00   ; dy -16 dx +3 tile 8 attr $00
    db $f8, $fb, $09, $00   ; dy -8 dx -5 tile 9 attr $00
    db $f8, $03, $0a, $00   ; dy -8 dx +3 tile 10 attr $00
    db $e3, $e8, $07, $00   ; dy -29 dx -24 tile 7 attr $00
    db $e3, $f0, $08, $00   ; dy -29 dx -16 tile 8 attr $00
    db $eb, $e8, $09, $00   ; dy -21 dx -24 tile 9 attr $00
    db $eb, $f0, $0a, $00   ; dy -21 dx -16 tile 10 attr $00
    db $ec, $10, $07, $20   ; dy -20 dx +16 tile 7 attr $20
    db $ec, $08, $08, $20   ; dy -20 dx +8 tile 8 attr $20
    db $f4, $10, $09, $20   ; dy -12 dx +16 tile 9 attr $20
    db $f4, $08, $0a, $20   ; dy -12 dx +8 tile 10 attr $20
    db $d8, $06, $07, $20   ; dy -40 dx +6 tile 7 attr $20
    db $d8, $fe, $08, $20   ; dy -40 dx -2 tile 8 attr $20
    db $e0, $06, $09, $20   ; dy -32 dx +6 tile 9 attr $20
    db $e0, $fe, $0a, $20   ; dy -32 dx -2 tile 10 attr $20
    db $80
Anim_07_F07:   ; $522d 13 sprites
    db $da, $ef, $00, $00   ; dy -38 dx -17 tile 0 attr $00
    db $da, $f7, $01, $00   ; dy -38 dx -9 tile 1 attr $00
    db $e2, $ef, $02, $00   ; dy -30 dx -17 tile 2 attr $00
    db $e2, $f7, $03, $00   ; dy -30 dx -9 tile 3 attr $00
    db $e7, $05, $02, $00   ; dy -25 dx +5 tile 2 attr $00
    db $e7, $0d, $03, $00   ; dy -25 dx +13 tile 3 attr $00
    db $df, $0f, $00, $20   ; dy -33 dx +15 tile 0 attr $20
    db $df, $07, $01, $20   ; dy -33 dx +7 tile 1 attr $20
    db $f4, $fa, $03, $00   ; dy -12 dx -6 tile 3 attr $00
    db $f4, $f2, $03, $20   ; dy -12 dx -14 tile 3 attr $20
    db $ec, $fa, $06, $00   ; dy -20 dx -6 tile 6 attr $00
    db $ec, $f2, $01, $20   ; dy -20 dx -14 tile 1 attr $20
    db $ef, $01, $02, $20   ; dy -17 dx +1 tile 2 attr $20
    db $80
Anim_07_F08:   ; $5262 24 sprites
    db $d8, $f9, $0f, $00   ; dy -40 dx -7 tile 15 attr $00
    db $d8, $01, $10, $00   ; dy -40 dx +1 tile 16 attr $00
    db $d0, $f9, $0c, $00   ; dy -48 dx -7 tile 12 attr $00
    db $d0, $f1, $0b, $00   ; dy -48 dx -15 tile 11 attr $00
    db $e0, $f8, $0e, $60   ; dy -32 dx -8 tile 14 attr $60
    db $e0, $f0, $0f, $60   ; dy -32 dx -16 tile 15 attr $60
    db $e0, $e8, $10, $60   ; dy -32 dx -24 tile 16 attr $60
    db $e0, $00, $0d, $60   ; dy -32 dx +0 tile 13 attr $60
    db $e8, $f0, $0c, $60   ; dy -24 dx -16 tile 12 attr $60
    db $e8, $f8, $0b, $60   ; dy -24 dx -8 tile 11 attr $60
    db $d8, $f1, $0e, $00   ; dy -40 dx -15 tile 14 attr $00
    db $d8, $e9, $0d, $00   ; dy -40 dx -23 tile 13 attr $00
    db $e8, $09, $0f, $00   ; dy -24 dx +9 tile 15 attr $00
    db $e8, $11, $10, $00   ; dy -24 dx +17 tile 16 attr $00
    db $e0, $09, $0c, $00   ; dy -32 dx +9 tile 12 attr $00
    db $e0, $01, $0b, $00   ; dy -32 dx +1 tile 11 attr $00
    db $f0, $08, $0e, $60   ; dy -16 dx +8 tile 14 attr $60
    db $f0, $00, $0f, $60   ; dy -16 dx +0 tile 15 attr $60
    db $f0, $f8, $10, $60   ; dy -16 dx -8 tile 16 attr $60
    db $f0, $10, $0d, $60   ; dy -16 dx +16 tile 13 attr $60
    db $f8, $00, $0c, $60   ; dy -8 dx +0 tile 12 attr $60
    db $f8, $08, $0b, $60   ; dy -8 dx +8 tile 11 attr $60
    db $e8, $01, $0e, $00   ; dy -24 dx +1 tile 14 attr $00
    db $e8, $f9, $0d, $00   ; dy -24 dx -7 tile 13 attr $00
Anim_07_F09:   ; $52c2 empty frame = the $80 end above (shared)
    db $80
Anim_08_Explodet:   ; $52c3 animation $08 — Explodet
    dw Anim_08_F00
    dw Anim_08_F01
    dw Anim_08_F02
    dw Anim_08_F03
    dw Anim_08_F04
    dw Anim_08_F05
    dw Anim_08_F06
    dw Anim_08_F07
    dw Anim_08_F08
    dw Anim_08_F09
    dw Anim_08_F10
    dw Anim_08_F11
    dw Anim_08_F12
    dw Anim_08_F13
    dw Anim_08_F14
    dw Anim_08_F15
    dw Anim_08_F16
    dw Anim_08_F17
    dw Anim_08_F18
    dw Anim_08_F19
    dw Anim_08_F20
    dw Anim_08_F20
    dw Anim_08_F20
    dw Anim_08_F20
    dw Anim_08_F20
    dw Anim_08_F20
    dw Anim_08_F20
    dw Anim_08_F20
    dw Anim_08_F20
    dw Anim_08_F20
    dw Anim_08_F20
    dw Anim_08_F20
Anim_08_F00:   ; $5303 40 sprites
    db $f8, $48, $19, $60   ; dy -8 dx +72 tile 25 attr $60
    db $d0, $48, $19, $20   ; dy -48 dx +72 tile 25 attr $20
    db $e8, $44, $1b, $40   ; dy -24 dx +68 tile 27 attr $40
    db $f0, $40, $1b, $40   ; dy -16 dx +64 tile 27 attr $40
    db $e0, $44, $1b, $00   ; dy -32 dx +68 tile 27 attr $00
    db $d8, $40, $1b, $00   ; dy -40 dx +64 tile 27 attr $00
    db $f8, $b0, $19, $40   ; dy -8 dx -80 tile 25 attr $40
    db $d0, $b0, $19, $00   ; dy -48 dx -80 tile 25 attr $00
    db $d8, $b8, $1b, $20   ; dy -40 dx -72 tile 27 attr $20
    db $e0, $b4, $1b, $20   ; dy -32 dx -76 tile 27 attr $20
    db $f0, $b8, $1b, $60   ; dy -16 dx -72 tile 27 attr $60
    db $e8, $b4, $1b, $60   ; dy -24 dx -76 tile 27 attr $60
    db $d0, $e0, $1a, $00   ; dy -48 dx -32 tile 26 attr $00
    db $d0, $d0, $1a, $00   ; dy -48 dx -48 tile 26 attr $00
    db $d0, $c0, $1a, $00   ; dy -48 dx -64 tile 26 attr $00
    db $f8, $e0, $1a, $40   ; dy -8 dx -32 tile 26 attr $40
    db $f8, $d0, $1a, $40   ; dy -8 dx -48 tile 26 attr $40
    db $f8, $c0, $1a, $40   ; dy -8 dx -64 tile 26 attr $40
    db $d0, $28, $1a, $20   ; dy -48 dx +40 tile 26 attr $20
    db $f8, $28, $1a, $60   ; dy -8 dx +40 tile 26 attr $60
    db $d0, $18, $1a, $20   ; dy -48 dx +24 tile 26 attr $20
    db $f8, $18, $1a, $60   ; dy -8 dx +24 tile 26 attr $60
    db $d0, $38, $1a, $20   ; dy -48 dx +56 tile 26 attr $20
    db $f8, $38, $1a, $60   ; dy -8 dx +56 tile 26 attr $60
    db $d8, $30, $19, $20   ; dy -40 dx +48 tile 25 attr $20
    db $f0, $30, $19, $60   ; dy -16 dx +48 tile 25 attr $60
    db $d8, $c8, $19, $00   ; dy -40 dx -56 tile 25 attr $00
    db $f0, $c8, $19, $40   ; dy -16 dx -56 tile 25 attr $40
    db $dc, $c0, $1b, $20   ; dy -36 dx -64 tile 27 attr $20
    db $ec, $c0, $1b, $60   ; dy -20 dx -64 tile 27 attr $60
    db $dc, $38, $1b, $00   ; dy -36 dx +56 tile 27 attr $00
    db $ec, $38, $1b, $40   ; dy -20 dx +56 tile 27 attr $40
    db $e0, $cc, $1b, $20   ; dy -32 dx -52 tile 27 attr $20
    db $e8, $cc, $1b, $60   ; dy -24 dx -52 tile 27 attr $60
    db $e8, $2c, $1b, $40   ; dy -24 dx +44 tile 27 attr $40
    db $e0, $2c, $1b, $00   ; dy -32 dx +44 tile 27 attr $00
    db $d0, $f0, $1c, $00   ; dy -48 dx -16 tile 28 attr $00
    db $d0, $08, $1c, $20   ; dy -48 dx +8 tile 28 attr $20
    db $f8, $f0, $1c, $40   ; dy -8 dx -16 tile 28 attr $40
    db $f8, $08, $1c, $60   ; dy -8 dx +8 tile 28 attr $60
    db $80
Anim_08_F01:   ; $53a4 32 sprites
    db $d0, $10, $1a, $20   ; dy -48 dx +16 tile 26 attr $20
    db $d0, $20, $1a, $20   ; dy -48 dx +32 tile 26 attr $20
    db $f8, $10, $1a, $60   ; dy -8 dx +16 tile 26 attr $60
    db $f8, $20, $1a, $60   ; dy -8 dx +32 tile 26 attr $60
    db $d0, $e8, $1a, $00   ; dy -48 dx -24 tile 26 attr $00
    db $d0, $d8, $1a, $00   ; dy -48 dx -40 tile 26 attr $00
    db $f8, $e8, $1a, $40   ; dy -8 dx -24 tile 26 attr $40
    db $f8, $d8, $1a, $40   ; dy -8 dx -40 tile 26 attr $40
    db $d0, $d0, $19, $00   ; dy -48 dx -48 tile 25 attr $00
    db $d8, $d0, $1b, $20   ; dy -40 dx -48 tile 27 attr $20
    db $e0, $d4, $1b, $20   ; dy -32 dx -44 tile 27 attr $20
    db $f0, $d0, $1b, $60   ; dy -16 dx -48 tile 27 attr $60
    db $e8, $d4, $1b, $60   ; dy -24 dx -44 tile 27 attr $60
    db $f8, $d0, $19, $40   ; dy -8 dx -48 tile 25 attr $40
    db $f8, $28, $19, $60   ; dy -8 dx +40 tile 25 attr $60
    db $d0, $28, $19, $20   ; dy -48 dx +40 tile 25 attr $20
    db $e8, $24, $1b, $40   ; dy -24 dx +36 tile 27 attr $40
    db $f0, $28, $1b, $40   ; dy -16 dx +40 tile 27 attr $40
    db $e0, $24, $1b, $00   ; dy -32 dx +36 tile 27 attr $00
    db $d8, $28, $1b, $00   ; dy -40 dx +40 tile 27 attr $00
    db $d0, $f8, $1c, $00   ; dy -48 dx -8 tile 28 attr $00
    db $f8, $00, $1c, $60   ; dy -8 dx +0 tile 28 attr $60
    db $f8, $f8, $1c, $40   ; dy -8 dx -8 tile 28 attr $40
    db $d0, $00, $1c, $20   ; dy -48 dx +0 tile 28 attr $20
    db $d8, $dc, $19, $00   ; dy -40 dx -36 tile 25 attr $00
    db $f0, $dc, $19, $40   ; dy -16 dx -36 tile 25 attr $40
    db $e0, $e0, $1b, $20   ; dy -32 dx -32 tile 27 attr $20
    db $e8, $e0, $1b, $60   ; dy -24 dx -32 tile 27 attr $60
    db $f0, $1c, $19, $60   ; dy -16 dx +28 tile 25 attr $60
    db $d8, $1c, $19, $20   ; dy -40 dx +28 tile 25 attr $20
    db $e8, $18, $1b, $40   ; dy -24 dx +24 tile 27 attr $40
    db $e0, $18, $1b, $00   ; dy -32 dx +24 tile 27 attr $00
    db $80
Anim_08_F02:   ; $5425 36 sprites
    db $f0, $e8, $19, $40   ; dy -16 dx -24 tile 25 attr $40
    db $d8, $e8, $19, $00   ; dy -40 dx -24 tile 25 attr $00
    db $e0, $e8, $1b, $20   ; dy -32 dx -24 tile 27 attr $20
    db $e8, $e8, $1b, $60   ; dy -24 dx -24 tile 27 attr $60
    db $d8, $00, $1c, $20   ; dy -40 dx +0 tile 28 attr $20
    db $d8, $08, $1a, $20   ; dy -40 dx +8 tile 26 attr $20
    db $d8, $f8, $1c, $00   ; dy -40 dx -8 tile 28 attr $00
    db $d8, $f0, $1a, $00   ; dy -40 dx -16 tile 26 attr $00
    db $f0, $00, $1c, $60   ; dy -16 dx +0 tile 28 attr $60
    db $f0, $f8, $1c, $40   ; dy -16 dx -8 tile 28 attr $40
    db $f0, $f0, $1a, $40   ; dy -16 dx -16 tile 26 attr $40
    db $d8, $10, $19, $20   ; dy -40 dx +16 tile 25 attr $20
    db $e0, $10, $1b, $00   ; dy -32 dx +16 tile 27 attr $00
    db $f0, $10, $19, $60   ; dy -16 dx +16 tile 25 attr $60
    db $e8, $10, $1b, $40   ; dy -24 dx +16 tile 27 attr $40
    db $f8, $18, $19, $60   ; dy -8 dx +24 tile 25 attr $60
    db $f8, $e0, $19, $40   ; dy -8 dx -32 tile 25 attr $40
    db $d0, $e0, $19, $00   ; dy -48 dx -32 tile 25 attr $00
    db $d0, $08, $1a, $20   ; dy -48 dx +8 tile 26 attr $20
    db $d0, $f0, $1a, $00   ; dy -48 dx -16 tile 26 attr $00
    db $f8, $f0, $1a, $40   ; dy -8 dx -16 tile 26 attr $40
    db $f8, $08, $1a, $60   ; dy -8 dx +8 tile 26 attr $60
    db $d0, $18, $19, $20   ; dy -48 dx +24 tile 25 attr $20
    db $e0, $f0, $1a, $00   ; dy -32 dx -16 tile 26 attr $00
    db $e8, $f0, $1a, $40   ; dy -24 dx -16 tile 26 attr $40
    db $e0, $08, $1a, $20   ; dy -32 dx +8 tile 26 attr $20
    db $f0, $08, $1a, $60   ; dy -16 dx +8 tile 26 attr $60
    db $e8, $08, $1a, $60   ; dy -24 dx +8 tile 26 attr $60
    db $dc, $e0, $1b, $20   ; dy -36 dx -32 tile 27 attr $20
    db $ec, $e0, $1b, $60   ; dy -20 dx -32 tile 27 attr $60
    db $dc, $18, $1b, $00   ; dy -36 dx +24 tile 27 attr $00
    db $ec, $18, $1b, $40   ; dy -20 dx +24 tile 27 attr $40
    db $d4, $d4, $19, $00   ; dy -44 dx -44 tile 25 attr $00
    db $f4, $d4, $19, $40   ; dy -12 dx -44 tile 25 attr $40
    db $d4, $24, $19, $20   ; dy -44 dx +36 tile 25 attr $20
    db $f4, $24, $19, $60   ; dy -12 dx +36 tile 25 attr $60
    db $80
Anim_08_F03:   ; $54b6 4 sprites
    db $e8, $f8, $19, $40   ; dy -24 dx -8 tile 25 attr $40
    db $e8, $00, $19, $60   ; dy -24 dx +0 tile 25 attr $60
    db $e0, $00, $19, $20   ; dy -32 dx +0 tile 25 attr $20
    db $e0, $f8, $19, $00   ; dy -32 dx -8 tile 25 attr $00
    db $80
Anim_08_F04:   ; $54c7 8 sprites
    db $e8, $00, $02, $20   ; dy -24 dx +0 tile 2 attr $20
    db $e8, $f8, $03, $20   ; dy -24 dx -8 tile 3 attr $20
    db $e0, $f8, $02, $40   ; dy -32 dx -8 tile 2 attr $40
    db $e0, $00, $03, $40   ; dy -32 dx +0 tile 3 attr $40
    db $de, $08, $28, $00   ; dy -34 dx +8 tile 40 attr $00
    db $de, $10, $29, $00   ; dy -34 dx +16 tile 41 attr $00
    db $d9, $f3, $21, $00   ; dy -39 dx -13 tile 33 attr $00
    db $ef, $fb, $20, $60   ; dy -17 dx -5 tile 32 attr $60
    db $80
Anim_08_F05:   ; $54e8 33 sprites
    db $e8, $f0, $2d, $20   ; dy -24 dx -16 tile 45 attr $20
    db $e8, $e8, $2e, $20   ; dy -24 dx -24 tile 46 attr $20
    db $e8, $00, $2c, $00   ; dy -24 dx +0 tile 44 attr $00
    db $e8, $08, $2d, $00   ; dy -24 dx +8 tile 45 attr $00
    db $e8, $10, $2e, $00   ; dy -24 dx +16 tile 46 attr $00
    db $e8, $f8, $2b, $00   ; dy -24 dx -8 tile 43 attr $00
    db $e0, $e8, $22, $00   ; dy -32 dx -24 tile 34 attr $00
    db $e0, $f0, $23, $00   ; dy -32 dx -16 tile 35 attr $00
    db $e0, $f8, $24, $00   ; dy -32 dx -8 tile 36 attr $00
    db $e0, $00, $25, $00   ; dy -32 dx +0 tile 37 attr $00
    db $e0, $08, $26, $00   ; dy -32 dx +8 tile 38 attr $00
    db $e0, $10, $27, $00   ; dy -32 dx +16 tile 39 attr $00
    db $db, $18, $28, $00   ; dy -37 dx +24 tile 40 attr $00
    db $db, $20, $29, $00   ; dy -37 dx +32 tile 41 attr $00
    db $d8, $e8, $21, $00   ; dy -40 dx -24 tile 33 attr $00
    db $d8, $f0, $2f, $00   ; dy -40 dx -16 tile 47 attr $00
    db $d8, $f8, $1d, $00   ; dy -40 dx -8 tile 29 attr $00
    db $d8, $00, $1e, $00   ; dy -40 dx +0 tile 30 attr $00
    db $d8, $08, $1f, $00   ; dy -40 dx +8 tile 31 attr $00
    db $f0, $10, $22, $60   ; dy -16 dx +16 tile 34 attr $60
    db $f0, $08, $23, $60   ; dy -16 dx +8 tile 35 attr $60
    db $f0, $00, $24, $60   ; dy -16 dx +0 tile 36 attr $60
    db $f0, $f8, $25, $60   ; dy -16 dx -8 tile 37 attr $60
    db $f0, $f0, $26, $60   ; dy -16 dx -16 tile 38 attr $60
    db $f0, $e8, $27, $60   ; dy -16 dx -24 tile 39 attr $60
    db $f8, $10, $21, $60   ; dy -8 dx +16 tile 33 attr $60
    db $f8, $08, $2f, $60   ; dy -8 dx +8 tile 47 attr $60
    db $f8, $00, $1d, $60   ; dy -8 dx +0 tile 29 attr $60
    db $f8, $f0, $1f, $60   ; dy -8 dx -16 tile 31 attr $60
    db $f5, $e0, $28, $60   ; dy -11 dx -32 tile 40 attr $60
    db $f5, $d8, $29, $60   ; dy -11 dx -40 tile 41 attr $60
    db $f8, $f8, $1e, $60   ; dy -8 dx -8 tile 30 attr $60
    db $d0, $00, $20, $00   ; dy -48 dx +0 tile 32 attr $00
    db $80
Anim_08_F06:   ; $556d 40 sprites
    db $e0, $f0, $15, $00   ; dy -32 dx -16 tile 21 attr $00
    db $e0, $f8, $16, $00   ; dy -32 dx -8 tile 22 attr $00
    db $e0, $00, $17, $00   ; dy -32 dx +0 tile 23 attr $00
    db $e0, $08, $18, $00   ; dy -32 dx +8 tile 24 attr $00
    db $d8, $f5, $11, $00   ; dy -40 dx -11 tile 17 attr $00
    db $d8, $fd, $12, $00   ; dy -40 dx -3 tile 18 attr $00
    db $e8, $08, $15, $60   ; dy -24 dx +8 tile 21 attr $60
    db $e8, $00, $16, $60   ; dy -24 dx +0 tile 22 attr $60
    db $e8, $f8, $17, $60   ; dy -24 dx -8 tile 23 attr $60
    db $e8, $f0, $18, $60   ; dy -24 dx -16 tile 24 attr $60
    db $f0, $03, $11, $60   ; dy -16 dx +3 tile 17 attr $60
    db $f0, $fb, $12, $60   ; dy -16 dx -5 tile 18 attr $60
    db $e0, $e8, $0f, $40   ; dy -32 dx -24 tile 15 attr $40
    db $d8, $e7, $0e, $20   ; dy -40 dx -25 tile 14 attr $20
    db $d8, $df, $0f, $20   ; dy -40 dx -33 tile 15 attr $20
    db $e0, $e0, $0e, $40   ; dy -32 dx -32 tile 14 attr $40
    db $d0, $e7, $0b, $20   ; dy -48 dx -25 tile 11 attr $20
    db $d0, $df, $0c, $20   ; dy -48 dx -33 tile 12 attr $20
    db $d8, $d8, $10, $20   ; dy -40 dx -40 tile 16 attr $20
    db $e0, $d8, $0d, $40   ; dy -32 dx -40 tile 13 attr $40
    db $f0, $eb, $07, $00   ; dy -16 dx -21 tile 7 attr $00
    db $f0, $f3, $08, $00   ; dy -16 dx -13 tile 8 attr $00
    db $f8, $eb, $09, $00   ; dy -8 dx -21 tile 9 attr $00
    db $f8, $f3, $0a, $00   ; dy -8 dx -13 tile 10 attr $00
    db $e0, $21, $0f, $40   ; dy -32 dx +33 tile 15 attr $40
    db $e0, $29, $10, $40   ; dy -32 dx +41 tile 16 attr $40
    db $d8, $20, $0e, $20   ; dy -40 dx +32 tile 14 attr $20
    db $d8, $18, $0f, $20   ; dy -40 dx +24 tile 15 attr $20
    db $d8, $10, $10, $20   ; dy -40 dx +16 tile 16 attr $20
    db $d8, $28, $0d, $20   ; dy -40 dx +40 tile 13 attr $20
    db $d0, $18, $0c, $20   ; dy -48 dx +24 tile 12 attr $20
    db $d0, $20, $0b, $20   ; dy -48 dx +32 tile 11 attr $20
    db $e0, $19, $0e, $40   ; dy -32 dx +25 tile 14 attr $40
    db $e0, $11, $0d, $40   ; dy -32 dx +17 tile 13 attr $40
    db $f0, $20, $07, $60   ; dy -16 dx +32 tile 7 attr $60
    db $f0, $18, $08, $60   ; dy -16 dx +24 tile 8 attr $60
    db $e8, $20, $09, $60   ; dy -24 dx +32 tile 9 attr $60
    db $e8, $18, $0a, $60   ; dy -24 dx +24 tile 10 attr $60
    db $e8, $e0, $0b, $40   ; dy -24 dx -32 tile 11 attr $40
    db $e8, $e8, $0c, $40   ; dy -24 dx -24 tile 12 attr $40
    db $80
Anim_08_F07:   ; $560e 33 sprites
    db $e8, $08, $2d, $00   ; dy -24 dx +8 tile 45 attr $00
    db $e8, $10, $2e, $00   ; dy -24 dx +16 tile 46 attr $00
    db $e8, $f8, $2c, $20   ; dy -24 dx -8 tile 44 attr $20
    db $e8, $f0, $2d, $20   ; dy -24 dx -16 tile 45 attr $20
    db $e8, $e8, $2e, $20   ; dy -24 dx -24 tile 46 attr $20
    db $e8, $00, $2b, $20   ; dy -24 dx +0 tile 43 attr $20
    db $e0, $10, $22, $20   ; dy -32 dx +16 tile 34 attr $20
    db $e0, $08, $23, $20   ; dy -32 dx +8 tile 35 attr $20
    db $e0, $00, $24, $20   ; dy -32 dx +0 tile 36 attr $20
    db $e0, $f8, $25, $20   ; dy -32 dx -8 tile 37 attr $20
    db $e0, $f0, $26, $20   ; dy -32 dx -16 tile 38 attr $20
    db $e0, $e8, $27, $20   ; dy -32 dx -24 tile 39 attr $20
    db $db, $e0, $28, $20   ; dy -37 dx -32 tile 40 attr $20
    db $db, $d8, $29, $20   ; dy -37 dx -40 tile 41 attr $20
    db $d8, $10, $21, $20   ; dy -40 dx +16 tile 33 attr $20
    db $d8, $08, $2f, $20   ; dy -40 dx +8 tile 47 attr $20
    db $d8, $00, $1d, $20   ; dy -40 dx +0 tile 29 attr $20
    db $d8, $f8, $1e, $20   ; dy -40 dx -8 tile 30 attr $20
    db $d8, $f0, $1f, $20   ; dy -40 dx -16 tile 31 attr $20
    db $f0, $e8, $22, $40   ; dy -16 dx -24 tile 34 attr $40
    db $f0, $f0, $23, $40   ; dy -16 dx -16 tile 35 attr $40
    db $f0, $f8, $24, $40   ; dy -16 dx -8 tile 36 attr $40
    db $f0, $00, $25, $40   ; dy -16 dx +0 tile 37 attr $40
    db $f0, $08, $26, $40   ; dy -16 dx +8 tile 38 attr $40
    db $f0, $10, $27, $40   ; dy -16 dx +16 tile 39 attr $40
    db $f8, $e8, $21, $40   ; dy -8 dx -24 tile 33 attr $40
    db $f8, $f0, $2f, $40   ; dy -8 dx -16 tile 47 attr $40
    db $f8, $f8, $1d, $40   ; dy -8 dx -8 tile 29 attr $40
    db $f8, $08, $1f, $40   ; dy -8 dx +8 tile 31 attr $40
    db $f5, $18, $28, $40   ; dy -11 dx +24 tile 40 attr $40
    db $f5, $20, $29, $40   ; dy -11 dx +32 tile 41 attr $40
    db $f8, $00, $1e, $40   ; dy -8 dx +0 tile 30 attr $40
    db $d0, $f8, $20, $20   ; dy -48 dx -8 tile 32 attr $20
    db $80
Anim_08_F08:   ; $5693 35 sprites
    db $e0, $29, $0f, $00   ; dy -32 dx +41 tile 15 attr $00
    db $e0, $31, $10, $00   ; dy -32 dx +49 tile 16 attr $00
    db $e8, $28, $0e, $60   ; dy -24 dx +40 tile 14 attr $60
    db $e8, $20, $0f, $60   ; dy -24 dx +32 tile 15 attr $60
    db $e8, $18, $10, $60   ; dy -24 dx +24 tile 16 attr $60
    db $e8, $30, $0d, $60   ; dy -24 dx +48 tile 13 attr $60
    db $f0, $20, $0c, $60   ; dy -16 dx +32 tile 12 attr $60
    db $e0, $21, $0e, $00   ; dy -32 dx +33 tile 14 attr $00
    db $e0, $19, $0d, $00   ; dy -32 dx +25 tile 13 attr $00
    db $e5, $fe, $08, $20   ; dy -27 dx -2 tile 8 attr $20
    db $ed, $06, $09, $20   ; dy -19 dx +6 tile 9 attr $20
    db $ed, $fe, $0a, $20   ; dy -19 dx -2 tile 10 attr $20
    db $d0, $10, $07, $20   ; dy -48 dx +16 tile 7 attr $20
    db $d0, $08, $08, $20   ; dy -48 dx +8 tile 8 attr $20
    db $d8, $10, $09, $20   ; dy -40 dx +16 tile 9 attr $20
    db $d8, $08, $0a, $20   ; dy -40 dx +8 tile 10 attr $20
    db $f0, $28, $09, $20   ; dy -16 dx +40 tile 9 attr $20
    db $e5, $06, $07, $20   ; dy -27 dx +6 tile 7 attr $20
    db $e8, $ea, $0f, $20   ; dy -24 dx -22 tile 15 attr $20
    db $e8, $e2, $10, $20   ; dy -24 dx -30 tile 16 attr $20
    db $f0, $eb, $0e, $40   ; dy -16 dx -21 tile 14 attr $40
    db $f0, $f3, $0f, $40   ; dy -16 dx -13 tile 15 attr $40
    db $f0, $fb, $10, $40   ; dy -16 dx -5 tile 16 attr $40
    db $f0, $e3, $0d, $40   ; dy -16 dx -29 tile 13 attr $40
    db $e8, $f2, $0e, $20   ; dy -24 dx -14 tile 14 attr $20
    db $e8, $fa, $0d, $20   ; dy -24 dx -6 tile 13 attr $20
    db $f8, $eb, $0b, $40   ; dy -8 dx -21 tile 11 attr $40
    db $f8, $f3, $0c, $40   ; dy -8 dx -13 tile 12 attr $40
    db $e0, $f2, $0b, $20   ; dy -32 dx -14 tile 11 attr $20
    db $e0, $ea, $0c, $20   ; dy -32 dx -22 tile 12 attr $20
    db $d0, $30, $07, $20   ; dy -48 dx +48 tile 7 attr $20
    db $d0, $28, $08, $20   ; dy -48 dx +40 tile 8 attr $20
    db $d8, $30, $09, $20   ; dy -40 dx +48 tile 9 attr $20
    db $d8, $28, $0a, $20   ; dy -40 dx +40 tile 10 attr $20
    db $d8, $22, $0c, $20   ; dy -40 dx +34 tile 12 attr $20
    db $80
Anim_08_F09:   ; $5720 30 sprites
    db $d4, $2e, $01, $00   ; dy -44 dx +46 tile 1 attr $00
    db $dc, $26, $02, $00   ; dy -36 dx +38 tile 2 attr $00
    db $dc, $2e, $03, $00   ; dy -36 dx +46 tile 3 attr $00
    db $d4, $26, $00, $00   ; dy -44 dx +38 tile 0 attr $00
    db $e7, $15, $01, $20   ; dy -25 dx +21 tile 1 attr $20
    db $ef, $15, $03, $20   ; dy -17 dx +21 tile 3 attr $20
    db $ef, $25, $02, $20   ; dy -17 dx +37 tile 2 attr $20
    db $e7, $1d, $04, $00   ; dy -25 dx +29 tile 4 attr $00
    db $ef, $1d, $05, $00   ; dy -17 dx +29 tile 5 attr $00
    db $e7, $25, $01, $00   ; dy -25 dx +37 tile 1 attr $00
    db $db, $0d, $00, $20   ; dy -37 dx +13 tile 0 attr $20
    db $db, $05, $01, $20   ; dy -37 dx +5 tile 1 attr $20
    db $e3, $0d, $02, $20   ; dy -29 dx +13 tile 2 attr $20
    db $e3, $05, $03, $20   ; dy -29 dx +5 tile 3 attr $20
    db $f7, $2b, $02, $00   ; dy -9 dx +43 tile 2 attr $00
    db $f7, $33, $03, $00   ; dy -9 dx +51 tile 3 attr $00
    db $ef, $2b, $00, $00   ; dy -17 dx +43 tile 0 attr $00
    db $ef, $33, $01, $00   ; dy -17 dx +51 tile 1 attr $00
    db $f0, $ff, $00, $00   ; dy -16 dx -1 tile 0 attr $00
    db $f0, $07, $01, $00   ; dy -16 dx +7 tile 1 attr $00
    db $f8, $ff, $02, $00   ; dy -8 dx -1 tile 2 attr $00
    db $f8, $07, $03, $00   ; dy -8 dx +7 tile 3 attr $00
    db $e3, $40, $07, $20   ; dy -29 dx +64 tile 7 attr $20
    db $e3, $38, $08, $20   ; dy -29 dx +56 tile 8 attr $20
    db $eb, $40, $09, $20   ; dy -21 dx +64 tile 9 attr $20
    db $eb, $38, $0a, $20   ; dy -21 dx +56 tile 10 attr $20
    db $db, $1d, $07, $20   ; dy -37 dx +29 tile 7 attr $20
    db $db, $15, $08, $20   ; dy -37 dx +21 tile 8 attr $20
    db $e3, $1d, $09, $20   ; dy -29 dx +29 tile 9 attr $20
    db $e3, $15, $0a, $20   ; dy -29 dx +21 tile 10 attr $20
    db $80
Anim_08_F10:   ; $5799 36 sprites
    db $ec, $38, $0e, $40   ; dy -20 dx +56 tile 14 attr $40
    db $ec, $40, $0f, $40   ; dy -20 dx +64 tile 15 attr $40
    db $ec, $48, $10, $40   ; dy -20 dx +72 tile 16 attr $40
    db $ec, $30, $0d, $40   ; dy -20 dx +48 tile 13 attr $40
    db $f4, $40, $0c, $40   ; dy -12 dx +64 tile 12 attr $40
    db $f4, $38, $09, $00   ; dy -12 dx +56 tile 9 attr $00
    db $f4, $1d, $07, $40   ; dy -12 dx +29 tile 7 attr $40
    db $f4, $25, $08, $40   ; dy -12 dx +37 tile 8 attr $40
    db $ec, $1d, $09, $40   ; dy -20 dx +29 tile 9 attr $40
    db $ec, $25, $0a, $40   ; dy -20 dx +37 tile 10 attr $40
    db $f0, $08, $07, $00   ; dy -16 dx +8 tile 7 attr $00
    db $f0, $10, $08, $00   ; dy -16 dx +16 tile 8 attr $00
    db $f8, $08, $09, $00   ; dy -8 dx +8 tile 9 attr $00
    db $f8, $10, $0a, $00   ; dy -8 dx +16 tile 10 attr $00
    db $ec, $17, $11, $60   ; dy -20 dx +23 tile 17 attr $60
    db $ec, $0f, $12, $60   ; dy -20 dx +15 tile 18 attr $60
    db $d4, $08, $11, $00   ; dy -44 dx +8 tile 17 attr $00
    db $d4, $10, $12, $00   ; dy -44 dx +16 tile 18 attr $00
    db $d4, $1c, $14, $00   ; dy -44 dx +28 tile 20 attr $00
    db $dc, $04, $15, $00   ; dy -36 dx +4 tile 21 attr $00
    db $dc, $0c, $16, $00   ; dy -36 dx +12 tile 22 attr $00
    db $dc, $14, $17, $00   ; dy -36 dx +20 tile 23 attr $00
    db $dc, $1c, $18, $00   ; dy -36 dx +28 tile 24 attr $00
    db $e4, $1c, $15, $60   ; dy -28 dx +28 tile 21 attr $60
    db $e4, $14, $16, $60   ; dy -28 dx +20 tile 22 attr $60
    db $e4, $0c, $17, $60   ; dy -28 dx +12 tile 23 attr $60
    db $e4, $04, $18, $60   ; dy -28 dx +4 tile 24 attr $60
    db $dc, $2c, $07, $20   ; dy -36 dx +44 tile 7 attr $20
    db $dc, $24, $08, $20   ; dy -36 dx +36 tile 8 attr $20
    db $e4, $2c, $09, $20   ; dy -28 dx +44 tile 9 attr $20
    db $e4, $24, $0a, $20   ; dy -28 dx +36 tile 10 attr $20
    db $e4, $3f, $0e, $20   ; dy -28 dx +63 tile 14 attr $20
    db $e4, $37, $0f, $20   ; dy -28 dx +55 tile 15 attr $20
    db $e4, $47, $0d, $20   ; dy -28 dx +71 tile 13 attr $20
    db $dc, $3f, $0b, $20   ; dy -36 dx +63 tile 11 attr $20
    db $dc, $37, $0c, $20   ; dy -36 dx +55 tile 12 attr $20
    db $80
Anim_08_F11:   ; $582a 34 sprites
    db $d8, $0c, $02, $00   ; dy -40 dx +12 tile 2 attr $00
    db $d8, $14, $03, $00   ; dy -40 dx +20 tile 3 attr $00
    db $d0, $0c, $00, $00   ; dy -48 dx +12 tile 0 attr $00
    db $e3, $25, $01, $00   ; dy -29 dx +37 tile 1 attr $00
    db $eb, $25, $03, $00   ; dy -21 dx +37 tile 3 attr $00
    db $eb, $15, $02, $00   ; dy -21 dx +21 tile 2 attr $00
    db $e3, $1d, $04, $20   ; dy -29 dx +29 tile 4 attr $20
    db $eb, $1d, $05, $20   ; dy -21 dx +29 tile 5 attr $20
    db $e3, $15, $01, $20   ; dy -29 dx +21 tile 1 attr $20
    db $f3, $0f, $02, $20   ; dy -13 dx +15 tile 2 attr $20
    db $f3, $07, $03, $20   ; dy -13 dx +7 tile 3 attr $20
    db $eb, $07, $01, $20   ; dy -21 dx +7 tile 1 attr $20
    db $f0, $2a, $07, $20   ; dy -16 dx +42 tile 7 attr $20
    db $f0, $22, $08, $20   ; dy -16 dx +34 tile 8 attr $20
    db $f8, $2a, $09, $20   ; dy -8 dx +42 tile 9 attr $20
    db $f8, $22, $0a, $20   ; dy -8 dx +34 tile 10 attr $20
    db $d3, $31, $00, $00   ; dy -45 dx +49 tile 0 attr $00
    db $d3, $39, $01, $00   ; dy -45 dx +57 tile 1 attr $00
    db $db, $31, $02, $00   ; dy -37 dx +49 tile 2 attr $00
    db $db, $39, $03, $00   ; dy -37 dx +57 tile 3 attr $00
    db $d7, $24, $07, $20   ; dy -41 dx +36 tile 7 attr $20
    db $d7, $1c, $08, $20   ; dy -41 dx +28 tile 8 attr $20
    db $df, $24, $09, $20   ; dy -33 dx +36 tile 9 attr $20
    db $df, $1c, $0a, $20   ; dy -33 dx +28 tile 10 attr $20
    db $ea, $2d, $02, $00   ; dy -22 dx +45 tile 2 attr $00
    db $e2, $2d, $2f, $00   ; dy -30 dx +45 tile 47 attr $00
    db $e2, $35, $04, $00   ; dy -30 dx +53 tile 4 attr $00
    db $ea, $35, $2d, $40   ; dy -22 dx +53 tile 45 attr $40
    db $e8, $3d, $05, $00   ; dy -24 dx +61 tile 5 attr $00
    db $e0, $3d, $04, $00   ; dy -32 dx +61 tile 4 attr $00
    db $e8, $45, $2e, $40   ; dy -24 dx +69 tile 46 attr $40
    db $eb, $0f, $0c, $00   ; dy -21 dx +15 tile 12 attr $00
    db $d0, $14, $07, $20   ; dy -48 dx +20 tile 7 attr $20
    db $e0, $45, $28, $00   ; dy -32 dx +69 tile 40 attr $00
    db $80
Anim_08_F12:   ; $58b3 34 sprites
    db $dc, $40, $0e, $00   ; dy -36 dx +64 tile 14 attr $00
    db $dc, $48, $0f, $00   ; dy -36 dx +72 tile 15 attr $00
    db $dc, $38, $0d, $00   ; dy -36 dx +56 tile 13 attr $00
    db $d4, $48, $0c, $00   ; dy -44 dx +72 tile 12 attr $00
    db $e4, $47, $0e, $60   ; dy -28 dx +71 tile 14 attr $60
    db $e4, $3f, $0f, $60   ; dy -28 dx +63 tile 15 attr $60
    db $ec, $47, $0b, $60   ; dy -20 dx +71 tile 11 attr $60
    db $ec, $3f, $0c, $60   ; dy -20 dx +63 tile 12 attr $60
    db $d4, $40, $0b, $00   ; dy -44 dx +64 tile 11 attr $00
    db $e0, $30, $11, $20   ; dy -32 dx +48 tile 17 attr $20
    db $e0, $28, $12, $20   ; dy -32 dx +40 tile 18 attr $20
    db $f8, $21, $11, $40   ; dy -8 dx +33 tile 17 attr $40
    db $f8, $29, $12, $40   ; dy -8 dx +41 tile 18 attr $40
    db $f8, $35, $14, $40   ; dy -8 dx +53 tile 20 attr $40
    db $f0, $1d, $15, $40   ; dy -16 dx +29 tile 21 attr $40
    db $f0, $25, $16, $40   ; dy -16 dx +37 tile 22 attr $40
    db $f0, $2d, $17, $40   ; dy -16 dx +45 tile 23 attr $40
    db $f0, $35, $18, $40   ; dy -16 dx +53 tile 24 attr $40
    db $e8, $35, $15, $20   ; dy -24 dx +53 tile 21 attr $20
    db $e8, $2d, $16, $20   ; dy -24 dx +45 tile 22 attr $20
    db $e8, $25, $17, $20   ; dy -24 dx +37 tile 23 attr $20
    db $e8, $1d, $18, $20   ; dy -24 dx +29 tile 24 attr $20
    db $d8, $24, $07, $40   ; dy -40 dx +36 tile 7 attr $40
    db $d8, $2c, $08, $40   ; dy -40 dx +44 tile 8 attr $40
    db $d0, $24, $09, $40   ; dy -48 dx +36 tile 9 attr $40
    db $d0, $2c, $0a, $40   ; dy -48 dx +44 tile 10 attr $40
    db $f0, $0d, $07, $40   ; dy -16 dx +13 tile 7 attr $40
    db $f0, $15, $08, $40   ; dy -16 dx +21 tile 8 attr $40
    db $e8, $0d, $09, $40   ; dy -24 dx +13 tile 9 attr $40
    db $e8, $15, $0a, $40   ; dy -24 dx +21 tile 10 attr $40
    db $f0, $47, $07, $20   ; dy -16 dx +71 tile 7 attr $20
    db $f0, $3f, $08, $20   ; dy -16 dx +63 tile 8 attr $20
    db $f8, $47, $09, $20   ; dy -8 dx +71 tile 9 attr $20
    db $f8, $3f, $0a, $20   ; dy -8 dx +63 tile 10 attr $20
    db $80
Anim_08_F13:   ; $593c 29 sprites
    db $d0, $43, $11, $20   ; dy -48 dx +67 tile 17 attr $20
    db $d0, $3b, $12, $20   ; dy -48 dx +59 tile 18 attr $20
    db $e8, $34, $11, $40   ; dy -24 dx +52 tile 17 attr $40
    db $e8, $3c, $12, $40   ; dy -24 dx +60 tile 18 attr $40
    db $e8, $48, $14, $40   ; dy -24 dx +72 tile 20 attr $40
    db $e0, $30, $15, $40   ; dy -32 dx +48 tile 21 attr $40
    db $e0, $38, $16, $40   ; dy -32 dx +56 tile 22 attr $40
    db $e0, $40, $17, $40   ; dy -32 dx +64 tile 23 attr $40
    db $e0, $48, $18, $40   ; dy -32 dx +72 tile 24 attr $40
    db $d8, $48, $15, $20   ; dy -40 dx +72 tile 21 attr $20
    db $d8, $40, $16, $20   ; dy -40 dx +64 tile 22 attr $20
    db $d8, $38, $17, $20   ; dy -40 dx +56 tile 23 attr $20
    db $d8, $30, $18, $20   ; dy -40 dx +48 tile 24 attr $20
    db $e1, $24, $0e, $00   ; dy -31 dx +36 tile 14 attr $00
    db $e1, $2c, $0f, $00   ; dy -31 dx +44 tile 15 attr $00
    db $e9, $2b, $0e, $60   ; dy -23 dx +43 tile 14 attr $60
    db $e9, $23, $0f, $60   ; dy -23 dx +35 tile 15 attr $60
    db $f1, $2b, $0b, $60   ; dy -15 dx +43 tile 11 attr $60
    db $f1, $23, $0c, $60   ; dy -15 dx +35 tile 12 attr $60
    db $d9, $24, $0b, $00   ; dy -39 dx +36 tile 11 attr $00
    db $e0, $1c, $0d, $00   ; dy -32 dx +28 tile 13 attr $00
    db $e0, $18, $07, $20   ; dy -32 dx +24 tile 7 attr $20
    db $e0, $10, $08, $20   ; dy -32 dx +16 tile 8 attr $20
    db $e8, $18, $09, $20   ; dy -24 dx +24 tile 9 attr $20
    db $e8, $10, $0a, $20   ; dy -24 dx +16 tile 10 attr $20
    db $d0, $28, $07, $40   ; dy -48 dx +40 tile 7 attr $40
    db $d0, $30, $08, $40   ; dy -48 dx +48 tile 8 attr $40
    db $f8, $2a, $09, $40   ; dy -8 dx +42 tile 9 attr $40
    db $f8, $32, $0a, $40   ; dy -8 dx +50 tile 10 attr $40
    db $80
Anim_08_F14:   ; $59b1 35 sprites
    db $e0, $d0, $0f, $20   ; dy -32 dx -48 tile 15 attr $20
    db $e0, $c8, $10, $20   ; dy -32 dx -56 tile 16 attr $20
    db $e8, $d1, $0e, $40   ; dy -24 dx -47 tile 14 attr $40
    db $e8, $d9, $0f, $40   ; dy -24 dx -39 tile 15 attr $40
    db $e8, $e1, $10, $40   ; dy -24 dx -31 tile 16 attr $40
    db $e8, $c9, $0d, $40   ; dy -24 dx -55 tile 13 attr $40
    db $f0, $d9, $0c, $40   ; dy -16 dx -39 tile 12 attr $40
    db $e0, $d8, $0e, $20   ; dy -32 dx -40 tile 14 attr $20
    db $e0, $e0, $0d, $20   ; dy -32 dx -32 tile 13 attr $20
    db $e5, $fb, $08, $00   ; dy -27 dx -5 tile 8 attr $00
    db $ed, $f3, $09, $00   ; dy -19 dx -13 tile 9 attr $00
    db $ed, $fb, $0a, $00   ; dy -19 dx -5 tile 10 attr $00
    db $d0, $e9, $07, $00   ; dy -48 dx -23 tile 7 attr $00
    db $d0, $f1, $08, $00   ; dy -48 dx -15 tile 8 attr $00
    db $d8, $e9, $09, $00   ; dy -40 dx -23 tile 9 attr $00
    db $d8, $f1, $0a, $00   ; dy -40 dx -15 tile 10 attr $00
    db $f0, $d1, $09, $00   ; dy -16 dx -47 tile 9 attr $00
    db $e5, $f3, $07, $00   ; dy -27 dx -13 tile 7 attr $00
    db $e8, $0f, $0f, $00   ; dy -24 dx +15 tile 15 attr $00
    db $e8, $17, $10, $00   ; dy -24 dx +23 tile 16 attr $00
    db $f0, $0e, $0e, $60   ; dy -16 dx +14 tile 14 attr $60
    db $f0, $06, $0f, $60   ; dy -16 dx +6 tile 15 attr $60
    db $f0, $fe, $10, $60   ; dy -16 dx -2 tile 16 attr $60
    db $f0, $16, $0d, $60   ; dy -16 dx +22 tile 13 attr $60
    db $e8, $07, $0e, $00   ; dy -24 dx +7 tile 14 attr $00
    db $e8, $ff, $0d, $00   ; dy -24 dx -1 tile 13 attr $00
    db $f8, $0e, $0b, $60   ; dy -8 dx +14 tile 11 attr $60
    db $f8, $06, $0c, $60   ; dy -8 dx +6 tile 12 attr $60
    db $e0, $07, $0b, $00   ; dy -32 dx +7 tile 11 attr $00
    db $e0, $0f, $0c, $00   ; dy -32 dx +15 tile 12 attr $00
    db $d0, $c9, $07, $00   ; dy -48 dx -55 tile 7 attr $00
    db $d0, $d1, $08, $00   ; dy -48 dx -47 tile 8 attr $00
    db $d8, $c9, $09, $00   ; dy -40 dx -55 tile 9 attr $00
    db $d8, $d1, $0a, $00   ; dy -40 dx -47 tile 10 attr $00
    db $d8, $d7, $0c, $00   ; dy -40 dx -41 tile 12 attr $00
    db $80
Anim_08_F15:   ; $5a3e 30 sprites
    db $d4, $ca, $01, $20   ; dy -44 dx -54 tile 1 attr $20
    db $dc, $d2, $02, $20   ; dy -36 dx -46 tile 2 attr $20
    db $dc, $ca, $03, $20   ; dy -36 dx -54 tile 3 attr $20
    db $d4, $d2, $00, $20   ; dy -44 dx -46 tile 0 attr $20
    db $e7, $e3, $01, $00   ; dy -25 dx -29 tile 1 attr $00
    db $ef, $e3, $03, $00   ; dy -17 dx -29 tile 3 attr $00
    db $ef, $d3, $02, $00   ; dy -17 dx -45 tile 2 attr $00
    db $e7, $db, $04, $20   ; dy -25 dx -37 tile 4 attr $20
    db $ef, $db, $05, $20   ; dy -17 dx -37 tile 5 attr $20
    db $e7, $d3, $01, $20   ; dy -25 dx -45 tile 1 attr $20
    db $db, $eb, $00, $00   ; dy -37 dx -21 tile 0 attr $00
    db $db, $f3, $01, $00   ; dy -37 dx -13 tile 1 attr $00
    db $e3, $eb, $02, $00   ; dy -29 dx -21 tile 2 attr $00
    db $e3, $f3, $03, $00   ; dy -29 dx -13 tile 3 attr $00
    db $f7, $cd, $02, $20   ; dy -9 dx -51 tile 2 attr $20
    db $f7, $c5, $03, $20   ; dy -9 dx -59 tile 3 attr $20
    db $ef, $cd, $00, $20   ; dy -17 dx -51 tile 0 attr $20
    db $ef, $c5, $01, $20   ; dy -17 dx -59 tile 1 attr $20
    db $f0, $f9, $00, $20   ; dy -16 dx -7 tile 0 attr $20
    db $f0, $f1, $01, $20   ; dy -16 dx -15 tile 1 attr $20
    db $f8, $f9, $02, $20   ; dy -8 dx -7 tile 2 attr $20
    db $f8, $f1, $03, $20   ; dy -8 dx -15 tile 3 attr $20
    db $e3, $b8, $07, $00   ; dy -29 dx -72 tile 7 attr $00
    db $e3, $c0, $08, $00   ; dy -29 dx -64 tile 8 attr $00
    db $eb, $b8, $09, $00   ; dy -21 dx -72 tile 9 attr $00
    db $eb, $c0, $0a, $00   ; dy -21 dx -64 tile 10 attr $00
    db $db, $db, $07, $00   ; dy -37 dx -37 tile 7 attr $00
    db $db, $e3, $08, $00   ; dy -37 dx -29 tile 8 attr $00
    db $e3, $db, $09, $00   ; dy -29 dx -37 tile 9 attr $00
    db $e3, $e3, $0a, $00   ; dy -29 dx -29 tile 10 attr $00
    db $80
Anim_08_F16:   ; $5ab7 36 sprites
    db $ec, $c2, $0e, $60   ; dy -20 dx -62 tile 14 attr $60
    db $ec, $ba, $0f, $60   ; dy -20 dx -70 tile 15 attr $60
    db $ec, $b2, $10, $60   ; dy -20 dx -78 tile 16 attr $60
    db $ec, $ca, $0d, $60   ; dy -20 dx -54 tile 13 attr $60
    db $f4, $ba, $0c, $60   ; dy -12 dx -70 tile 12 attr $60
    db $f4, $c2, $09, $20   ; dy -12 dx -62 tile 9 attr $20
    db $f4, $dd, $07, $60   ; dy -12 dx -35 tile 7 attr $60
    db $f4, $d5, $08, $60   ; dy -12 dx -43 tile 8 attr $60
    db $ec, $dd, $09, $60   ; dy -20 dx -35 tile 9 attr $60
    db $ec, $d5, $0a, $60   ; dy -20 dx -43 tile 10 attr $60
    db $f0, $f2, $07, $20   ; dy -16 dx -14 tile 7 attr $20
    db $f0, $ea, $08, $20   ; dy -16 dx -22 tile 8 attr $20
    db $f8, $f2, $09, $20   ; dy -8 dx -14 tile 9 attr $20
    db $f8, $ea, $0a, $20   ; dy -8 dx -22 tile 10 attr $20
    db $ec, $e3, $11, $40   ; dy -20 dx -29 tile 17 attr $40
    db $ec, $eb, $12, $40   ; dy -20 dx -21 tile 18 attr $40
    db $d4, $f2, $11, $20   ; dy -44 dx -14 tile 17 attr $20
    db $d4, $ea, $12, $20   ; dy -44 dx -22 tile 18 attr $20
    db $d4, $de, $14, $20   ; dy -44 dx -34 tile 20 attr $20
    db $dc, $f6, $15, $20   ; dy -36 dx -10 tile 21 attr $20
    db $dc, $ee, $16, $20   ; dy -36 dx -18 tile 22 attr $20
    db $dc, $e6, $17, $20   ; dy -36 dx -26 tile 23 attr $20
    db $dc, $de, $18, $20   ; dy -36 dx -34 tile 24 attr $20
    db $e4, $de, $15, $40   ; dy -28 dx -34 tile 21 attr $40
    db $e4, $e6, $16, $40   ; dy -28 dx -26 tile 22 attr $40
    db $e4, $ee, $17, $40   ; dy -28 dx -18 tile 23 attr $40
    db $e4, $f6, $18, $40   ; dy -28 dx -10 tile 24 attr $40
    db $dc, $ce, $07, $00   ; dy -36 dx -50 tile 7 attr $00
    db $dc, $d6, $08, $00   ; dy -36 dx -42 tile 8 attr $00
    db $e4, $ce, $09, $00   ; dy -28 dx -50 tile 9 attr $00
    db $e4, $d6, $0a, $00   ; dy -28 dx -42 tile 10 attr $00
    db $e4, $bb, $0e, $00   ; dy -28 dx -69 tile 14 attr $00
    db $e4, $c3, $0f, $00   ; dy -28 dx -61 tile 15 attr $00
    db $e4, $b3, $0d, $00   ; dy -28 dx -77 tile 13 attr $00
    db $dc, $bb, $0b, $00   ; dy -36 dx -69 tile 11 attr $00
    db $dc, $c3, $0c, $00   ; dy -36 dx -61 tile 12 attr $00
    db $80
Anim_08_F17:   ; $5b48 34 sprites
    db $d8, $ec, $02, $20   ; dy -40 dx -20 tile 2 attr $20
    db $d8, $e4, $03, $20   ; dy -40 dx -28 tile 3 attr $20
    db $d0, $ec, $00, $20   ; dy -48 dx -20 tile 0 attr $20
    db $e3, $d3, $01, $20   ; dy -29 dx -45 tile 1 attr $20
    db $eb, $d3, $03, $20   ; dy -21 dx -45 tile 3 attr $20
    db $eb, $e3, $02, $20   ; dy -21 dx -29 tile 2 attr $20
    db $e3, $db, $04, $00   ; dy -29 dx -37 tile 4 attr $00
    db $eb, $db, $05, $00   ; dy -21 dx -37 tile 5 attr $00
    db $e3, $e3, $01, $00   ; dy -29 dx -29 tile 1 attr $00
    db $f3, $e9, $02, $00   ; dy -13 dx -23 tile 2 attr $00
    db $f3, $f1, $03, $00   ; dy -13 dx -15 tile 3 attr $00
    db $eb, $f1, $01, $00   ; dy -21 dx -15 tile 1 attr $00
    db $f0, $ce, $07, $00   ; dy -16 dx -50 tile 7 attr $00
    db $f0, $d6, $08, $00   ; dy -16 dx -42 tile 8 attr $00
    db $f8, $ce, $09, $00   ; dy -8 dx -50 tile 9 attr $00
    db $f8, $d6, $0a, $00   ; dy -8 dx -42 tile 10 attr $00
    db $d3, $c7, $00, $20   ; dy -45 dx -57 tile 0 attr $20
    db $d3, $bf, $01, $20   ; dy -45 dx -65 tile 1 attr $20
    db $db, $c7, $02, $20   ; dy -37 dx -57 tile 2 attr $20
    db $db, $bf, $03, $20   ; dy -37 dx -65 tile 3 attr $20
    db $d7, $d4, $07, $00   ; dy -41 dx -44 tile 7 attr $00
    db $d7, $dc, $08, $00   ; dy -41 dx -36 tile 8 attr $00
    db $df, $d4, $09, $00   ; dy -33 dx -44 tile 9 attr $00
    db $df, $dc, $0a, $00   ; dy -33 dx -36 tile 10 attr $00
    db $ea, $cb, $02, $20   ; dy -22 dx -53 tile 2 attr $20
    db $e2, $cb, $2f, $20   ; dy -30 dx -53 tile 47 attr $20
    db $e2, $c3, $04, $20   ; dy -30 dx -61 tile 4 attr $20
    db $ea, $c3, $2d, $60   ; dy -22 dx -61 tile 45 attr $60
    db $e8, $bb, $05, $20   ; dy -24 dx -69 tile 5 attr $20
    db $e0, $bb, $04, $20   ; dy -32 dx -69 tile 4 attr $20
    db $e8, $b3, $2e, $60   ; dy -24 dx -77 tile 46 attr $60
    db $eb, $e9, $0c, $20   ; dy -21 dx -23 tile 12 attr $20
    db $d0, $e4, $07, $00   ; dy -48 dx -28 tile 7 attr $00
    db $e0, $b3, $28, $20   ; dy -32 dx -77 tile 40 attr $20
    db $80
Anim_08_F18:   ; $5bd1 34 sprites
    db $dc, $b8, $0e, $20   ; dy -36 dx -72 tile 14 attr $20
    db $dc, $b0, $0f, $20   ; dy -36 dx -80 tile 15 attr $20
    db $dc, $c0, $0d, $20   ; dy -36 dx -64 tile 13 attr $20
    db $d4, $b0, $0c, $20   ; dy -44 dx -80 tile 12 attr $20
    db $e4, $b1, $0e, $40   ; dy -28 dx -79 tile 14 attr $40
    db $e4, $b9, $0f, $40   ; dy -28 dx -71 tile 15 attr $40
    db $ec, $b1, $0b, $40   ; dy -20 dx -79 tile 11 attr $40
    db $ec, $b9, $0c, $40   ; dy -20 dx -71 tile 12 attr $40
    db $d4, $b8, $0b, $20   ; dy -44 dx -72 tile 11 attr $20
    db $e0, $c8, $11, $00   ; dy -32 dx -56 tile 17 attr $00
    db $e0, $d0, $12, $00   ; dy -32 dx -48 tile 18 attr $00
    db $f8, $d7, $11, $60   ; dy -8 dx -41 tile 17 attr $60
    db $f8, $cf, $12, $60   ; dy -8 dx -49 tile 18 attr $60
    db $f8, $c3, $14, $60   ; dy -8 dx -61 tile 20 attr $60
    db $f0, $db, $15, $60   ; dy -16 dx -37 tile 21 attr $60
    db $f0, $d3, $16, $60   ; dy -16 dx -45 tile 22 attr $60
    db $f0, $cb, $17, $60   ; dy -16 dx -53 tile 23 attr $60
    db $f0, $c3, $18, $60   ; dy -16 dx -61 tile 24 attr $60
    db $e8, $c3, $15, $00   ; dy -24 dx -61 tile 21 attr $00
    db $e8, $cb, $16, $00   ; dy -24 dx -53 tile 22 attr $00
    db $e8, $d3, $17, $00   ; dy -24 dx -45 tile 23 attr $00
    db $e8, $db, $18, $00   ; dy -24 dx -37 tile 24 attr $00
    db $d8, $d4, $07, $60   ; dy -40 dx -44 tile 7 attr $60
    db $d8, $cc, $08, $60   ; dy -40 dx -52 tile 8 attr $60
    db $d0, $d4, $09, $60   ; dy -48 dx -44 tile 9 attr $60
    db $d0, $cc, $0a, $60   ; dy -48 dx -52 tile 10 attr $60
    db $f0, $eb, $07, $60   ; dy -16 dx -21 tile 7 attr $60
    db $f0, $e3, $08, $60   ; dy -16 dx -29 tile 8 attr $60
    db $e8, $eb, $09, $60   ; dy -24 dx -21 tile 9 attr $60
    db $e8, $e3, $0a, $60   ; dy -24 dx -29 tile 10 attr $60
    db $f0, $b1, $07, $00   ; dy -16 dx -79 tile 7 attr $00
    db $f0, $b9, $08, $00   ; dy -16 dx -71 tile 8 attr $00
    db $f8, $b1, $09, $00   ; dy -8 dx -79 tile 9 attr $00
    db $f8, $b9, $0a, $00   ; dy -8 dx -71 tile 10 attr $00
    db $80
Anim_08_F19:   ; $5c5a 29 sprites
    db $d0, $b5, $11, $00   ; dy -48 dx -75 tile 17 attr $00
    db $d0, $bd, $12, $00   ; dy -48 dx -67 tile 18 attr $00
    db $e8, $c4, $11, $60   ; dy -24 dx -60 tile 17 attr $60
    db $e8, $bc, $12, $60   ; dy -24 dx -68 tile 18 attr $60
    db $e8, $b0, $14, $60   ; dy -24 dx -80 tile 20 attr $60
    db $e0, $c8, $15, $60   ; dy -32 dx -56 tile 21 attr $60
    db $e0, $c0, $16, $60   ; dy -32 dx -64 tile 22 attr $60
    db $e0, $b8, $17, $60   ; dy -32 dx -72 tile 23 attr $60
    db $e0, $b0, $18, $60   ; dy -32 dx -80 tile 24 attr $60
    db $d8, $b0, $15, $00   ; dy -40 dx -80 tile 21 attr $00
    db $d8, $b8, $16, $00   ; dy -40 dx -72 tile 22 attr $00
    db $d8, $c0, $17, $00   ; dy -40 dx -64 tile 23 attr $00
    db $d8, $c8, $18, $00   ; dy -40 dx -56 tile 24 attr $00
    db $e1, $d4, $0e, $20   ; dy -31 dx -44 tile 14 attr $20
    db $e1, $cc, $0f, $20   ; dy -31 dx -52 tile 15 attr $20
    db $e9, $cd, $0e, $40   ; dy -23 dx -51 tile 14 attr $40
    db $e9, $d5, $0f, $40   ; dy -23 dx -43 tile 15 attr $40
    db $f1, $cd, $0b, $40   ; dy -15 dx -51 tile 11 attr $40
    db $f1, $d5, $0c, $40   ; dy -15 dx -43 tile 12 attr $40
    db $d9, $d4, $0b, $20   ; dy -39 dx -44 tile 11 attr $20
    db $e0, $dc, $0d, $20   ; dy -32 dx -36 tile 13 attr $20
    db $e0, $e0, $07, $00   ; dy -32 dx -32 tile 7 attr $00
    db $e0, $e8, $08, $00   ; dy -32 dx -24 tile 8 attr $00
    db $e8, $e0, $09, $00   ; dy -24 dx -32 tile 9 attr $00
    db $e8, $e8, $0a, $00   ; dy -24 dx -24 tile 10 attr $00
    db $d0, $d0, $07, $60   ; dy -48 dx -48 tile 7 attr $60
    db $d0, $c8, $08, $60   ; dy -48 dx -56 tile 8 attr $60
    db $f8, $ce, $09, $60   ; dy -8 dx -50 tile 9 attr $60
    db $f8, $c6, $0a, $60   ; dy -8 dx -58 tile 10 attr $60
Anim_08_F20:   ; $5cce empty frame = the $80 end above (shared)
    db $80
Anim_09_Infernos:   ; $5ccf animation $09 — Infernos, WindBeast, STAFF
    dw Anim_09_F00
    dw Anim_09_F01
    dw Anim_09_F02
    dw Anim_09_F03
    dw Anim_09_F04
    dw Anim_09_F05
    dw Anim_09_F06
    dw Anim_09_F07
    dw Anim_09_F08
    dw Anim_09_F09
    dw Anim_09_F10
    dw Anim_09_F11
    dw Anim_09_F12
    dw Anim_09_F13
    dw Anim_09_F13
    dw Anim_09_F13
    dw Anim_09_F13
    dw Anim_09_F13
    dw Anim_09_F13
    dw Anim_09_F13
    dw Anim_09_F13
    dw Anim_09_F13
    dw Anim_09_F13
    dw Anim_09_F13
    dw Anim_09_F13
    dw Anim_09_F13
    dw Anim_09_F13
    dw Anim_09_F13
    dw Anim_09_F13
    dw Anim_09_F13
    dw Anim_09_F13
    dw Anim_09_F13
Anim_09_F00:   ; $5d0f 2 sprites
    db $e6, $fc, $02, $00   ; dy -26 dx -4 tile 2 attr $00
    db $e6, $04, $03, $00   ; dy -26 dx +4 tile 3 attr $00
    db $80
Anim_09_F01:   ; $5d18 4 sprites
    db $ee, $f4, $02, $00   ; dy -18 dx -12 tile 2 attr $00
    db $ee, $fc, $03, $00   ; dy -18 dx -4 tile 3 attr $00
    db $e8, $fc, $00, $00   ; dy -24 dx -4 tile 0 attr $00
    db $e8, $04, $01, $00   ; dy -24 dx +4 tile 1 attr $00
    db $80
Anim_09_F02:   ; $5d29 7 sprites
    db $f0, $f4, $00, $00   ; dy -16 dx -12 tile 0 attr $00
    db $f0, $fc, $01, $00   ; dy -16 dx -4 tile 1 attr $00
    db $de, $f4, $00, $00   ; dy -34 dx -12 tile 0 attr $00
    db $de, $fc, $01, $00   ; dy -34 dx -4 tile 1 attr $00
    db $e5, $f5, $0c, $00   ; dy -27 dx -11 tile 12 attr $00
    db $e5, $fd, $0d, $00   ; dy -27 dx -3 tile 13 attr $00
    db $e5, $05, $0e, $00   ; dy -27 dx +5 tile 14 attr $00
    db $80
Anim_09_F03:   ; $5d46 9 sprites
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
Anim_09_F04:   ; $5d6b 8 sprites
    db $de, $f4, $00, $00   ; dy -34 dx -12 tile 0 attr $00
    db $de, $fc, $01, $00   ; dy -34 dx -4 tile 1 attr $00
    db $f0, $f0, $0c, $00   ; dy -16 dx -16 tile 12 attr $00
    db $f0, $f8, $0d, $00   ; dy -16 dx -8 tile 13 attr $00
    db $f0, $00, $0e, $00   ; dy -16 dx +0 tile 14 attr $00
    db $e2, $f6, $09, $00   ; dy -30 dx -10 tile 9 attr $00
    db $e2, $fe, $0a, $00   ; dy -30 dx -2 tile 10 attr $00
    db $e2, $06, $0b, $00   ; dy -30 dx +6 tile 11 attr $00
    db $80
Anim_09_F05:   ; $5d8c 10 sprites
    db $e8, $fc, $00, $00   ; dy -24 dx -4 tile 0 attr $00
    db $e8, $04, $01, $00   ; dy -24 dx +4 tile 1 attr $00
    db $dd, $f0, $0c, $00   ; dy -35 dx -16 tile 12 attr $00
    db $dd, $f8, $0d, $00   ; dy -35 dx -8 tile 13 attr $00
    db $dd, $00, $0e, $00   ; dy -35 dx +0 tile 14 attr $00
    db $f0, $f0, $04, $00   ; dy -16 dx -16 tile 4 attr $00
    db $f0, $f8, $05, $00   ; dy -16 dx -8 tile 5 attr $00
    db $f0, $00, $06, $00   ; dy -16 dx +0 tile 6 attr $00
    db $f8, $f0, $08, $00   ; dy -8 dx -16 tile 8 attr $00
    db $f7, $e8, $07, $00   ; dy -9 dx -24 tile 7 attr $00
    db $80
Anim_09_F06:   ; $5db5 11 sprites
    db $da, $f1, $04, $00   ; dy -38 dx -15 tile 4 attr $00
    db $da, $f9, $05, $00   ; dy -38 dx -7 tile 5 attr $00
    db $da, $01, $06, $00   ; dy -38 dx +1 tile 6 attr $00
    db $e2, $f1, $08, $00   ; dy -30 dx -15 tile 8 attr $00
    db $e1, $e9, $07, $00   ; dy -31 dx -23 tile 7 attr $00
    db $f2, $ee, $0c, $00   ; dy -14 dx -18 tile 12 attr $00
    db $f2, $f6, $0d, $00   ; dy -14 dx -10 tile 13 attr $00
    db $f2, $fe, $0e, $00   ; dy -14 dx -2 tile 14 attr $00
    db $e6, $f8, $09, $00   ; dy -26 dx -8 tile 9 attr $00
    db $e6, $00, $0a, $00   ; dy -26 dx +0 tile 10 attr $00
    db $e6, $08, $0b, $00   ; dy -26 dx +8 tile 11 attr $00
    db $80
Anim_09_F07:   ; $5de2 8 sprites
    db $db, $f2, $09, $00   ; dy -37 dx -14 tile 9 attr $00
    db $db, $fa, $0a, $00   ; dy -37 dx -6 tile 10 attr $00
    db $db, $02, $0b, $00   ; dy -37 dx +2 tile 11 attr $00
    db $e6, $f8, $04, $00   ; dy -26 dx -8 tile 4 attr $00
    db $e6, $00, $05, $00   ; dy -26 dx +0 tile 5 attr $00
    db $e6, $08, $06, $00   ; dy -26 dx +8 tile 6 attr $00
    db $ee, $f8, $08, $00   ; dy -18 dx -8 tile 8 attr $00
    db $ed, $f0, $07, $00   ; dy -19 dx -16 tile 7 attr $00
    db $80
Anim_09_F08:   ; $5e03 5 sprites
    db $e9, $f6, $0c, $00   ; dy -23 dx -10 tile 12 attr $00
    db $e9, $fe, $0d, $00   ; dy -23 dx -2 tile 13 attr $00
    db $e9, $06, $0e, $00   ; dy -23 dx +6 tile 14 attr $00
    db $e0, $f8, $00, $00   ; dy -32 dx -8 tile 0 attr $00
    db $e0, $00, $01, $00   ; dy -32 dx +0 tile 1 attr $00
    db $80
Anim_09_F09:   ; $5e18 10 sprites
    db $e8, $fc, $00, $00   ; dy -24 dx -4 tile 0 attr $00
    db $e8, $04, $01, $00   ; dy -24 dx +4 tile 1 attr $00
    db $e4, $f3, $0c, $00   ; dy -28 dx -13 tile 12 attr $00
    db $e4, $fb, $0d, $00   ; dy -28 dx -5 tile 13 attr $00
    db $e4, $03, $0e, $00   ; dy -28 dx +3 tile 14 attr $00
    db $f0, $f4, $04, $00   ; dy -16 dx -12 tile 4 attr $00
    db $f0, $fc, $05, $00   ; dy -16 dx -4 tile 5 attr $00
    db $f0, $04, $06, $00   ; dy -16 dx +4 tile 6 attr $00
    db $f8, $f4, $08, $00   ; dy -8 dx -12 tile 8 attr $00
    db $f7, $ec, $07, $00   ; dy -9 dx -20 tile 7 attr $00
    db $80
Anim_09_F10:   ; $5e41 11 sprites
    db $ee, $f3, $0c, $00   ; dy -18 dx -13 tile 12 attr $00
    db $ee, $fb, $0d, $00   ; dy -18 dx -5 tile 13 attr $00
    db $ee, $03, $0e, $00   ; dy -18 dx +3 tile 14 attr $00
    db $f5, $f2, $09, $00   ; dy -11 dx -14 tile 9 attr $00
    db $f5, $fa, $0a, $00   ; dy -11 dx -6 tile 10 attr $00
    db $f5, $02, $0b, $00   ; dy -11 dx +2 tile 11 attr $00
    db $e5, $f4, $04, $00   ; dy -27 dx -12 tile 4 attr $00
    db $e5, $fc, $05, $00   ; dy -27 dx -4 tile 5 attr $00
    db $e5, $04, $06, $00   ; dy -27 dx +4 tile 6 attr $00
    db $ed, $f4, $08, $00   ; dy -19 dx -12 tile 8 attr $00
    db $ec, $ec, $07, $00   ; dy -20 dx -20 tile 7 attr $00
    db $80
Anim_09_F11:   ; $5e6e 8 sprites
    db $e4, $f5, $09, $00   ; dy -28 dx -11 tile 9 attr $00
    db $e4, $fd, $0a, $00   ; dy -28 dx -3 tile 10 attr $00
    db $e4, $05, $0b, $00   ; dy -28 dx +5 tile 11 attr $00
    db $ec, $f6, $04, $00   ; dy -20 dx -10 tile 4 attr $00
    db $ec, $fe, $05, $00   ; dy -20 dx -2 tile 5 attr $00
    db $ec, $06, $06, $00   ; dy -20 dx +6 tile 6 attr $00
    db $f4, $f6, $08, $00   ; dy -12 dx -10 tile 8 attr $00
    db $f3, $ee, $07, $00   ; dy -13 dx -18 tile 7 attr $00
    db $80
Anim_09_F12:   ; $5e8f 5 sprites
    db $e6, $f3, $0c, $00   ; dy -26 dx -13 tile 12 attr $00
    db $e6, $fb, $0d, $00   ; dy -26 dx -5 tile 13 attr $00
    db $e6, $03, $0e, $00   ; dy -26 dx +3 tile 14 attr $00
    db $f1, $01, $03, $00   ; dy -15 dx +1 tile 3 attr $00
    db $f1, $f9, $02, $00   ; dy -15 dx -7 tile 2 attr $00
Anim_09_F13:   ; $5ea3 empty frame = the $80 end above (shared)
    db $80
Anim_0a_Infermore:   ; $5ea4 animation $0a — Infermore
    dw Anim_0a_F00
    dw Anim_0a_F01
    dw Anim_0a_F02
    dw Anim_0a_F03
    dw Anim_0a_F04
    dw Anim_0a_F05
    dw Anim_0a_F06
    dw Anim_0a_F07
    dw Anim_0a_F08
    dw Anim_0a_F09
    dw Anim_0a_F10
    dw Anim_0a_F11
    dw Anim_0a_F12
    dw Anim_0a_F13
    dw Anim_0a_F14
    dw Anim_0a_F15
    dw Anim_0a_F16
    dw Anim_0a_F16
    dw Anim_0a_F16
    dw Anim_0a_F16
    dw Anim_0a_F16
    dw Anim_0a_F16
    dw Anim_0a_F16
    dw Anim_0a_F16
    dw Anim_0a_F24
    dw Anim_0a_F24
    dw Anim_0a_F24
    dw Anim_0a_F24
    dw Anim_0a_F24
    dw Anim_0a_F24
    dw Anim_0a_F24
    dw Anim_0a_F24
Anim_0a_F00:   ; $5ee4 6 sprites
    db $f8, $e8, $1b, $00   ; dy -8 dx -24 tile 27 attr $00
    db $f8, $f0, $1c, $00   ; dy -8 dx -16 tile 28 attr $00
    db $e0, $e8, $0d, $00   ; dy -32 dx -24 tile 13 attr $00
    db $e8, $e8, $11, $00   ; dy -24 dx -24 tile 17 attr $00
    db $f0, $e8, $16, $00   ; dy -16 dx -24 tile 22 attr $00
    db $f8, $f5, $1d, $00   ; dy -8 dx -11 tile 29 attr $00
    db $80
Anim_0a_F01:   ; $5efd 9 sprites
    db $d0, $e8, $09, $00   ; dy -48 dx -24 tile 9 attr $00
    db $f8, $e8, $03, $00   ; dy -8 dx -24 tile 3 attr $00
    db $f8, $f0, $04, $00   ; dy -8 dx -16 tile 4 attr $00
    db $f0, $e8, $1b, $00   ; dy -16 dx -24 tile 27 attr $00
    db $f0, $f0, $1c, $00   ; dy -16 dx -16 tile 28 attr $00
    db $d8, $e8, $0d, $00   ; dy -40 dx -24 tile 13 attr $00
    db $e0, $e8, $11, $00   ; dy -32 dx -24 tile 17 attr $00
    db $e8, $e8, $16, $00   ; dy -24 dx -24 tile 22 attr $00
    db $f8, $f8, $1e, $00   ; dy -8 dx -8 tile 30 attr $00
    db $80
Anim_0a_F02:   ; $5f22 18 sprites
    db $f8, $e8, $05, $00   ; dy -8 dx -24 tile 5 attr $00
    db $f8, $e8, $07, $00   ; dy -8 dx -24 tile 7 attr $00
    db $f8, $f0, $08, $00   ; dy -8 dx -16 tile 8 attr $00
    db $f8, $f8, $09, $00   ; dy -8 dx -8 tile 9 attr $00
    db $e8, $e8, $19, $00   ; dy -24 dx -24 tile 25 attr $00
    db $e8, $f0, $1a, $00   ; dy -24 dx -16 tile 26 attr $00
    db $f0, $e8, $02, $00   ; dy -16 dx -24 tile 2 attr $00
    db $f0, $f0, $03, $00   ; dy -16 dx -16 tile 3 attr $00
    db $f0, $f8, $04, $00   ; dy -16 dx -8 tile 4 attr $00
    db $d0, $e8, $0c, $00   ; dy -48 dx -24 tile 12 attr $00
    db $d0, $f0, $0d, $00   ; dy -48 dx -16 tile 13 attr $00
    db $d8, $e8, $10, $00   ; dy -40 dx -24 tile 16 attr $00
    db $d8, $f0, $11, $00   ; dy -40 dx -16 tile 17 attr $00
    db $e0, $e8, $15, $00   ; dy -32 dx -24 tile 21 attr $00
    db $e0, $f0, $16, $00   ; dy -32 dx -16 tile 22 attr $00
    db $e8, $00, $05, $20   ; dy -24 dx +0 tile 5 attr $20
    db $e8, $f8, $06, $20   ; dy -24 dx -8 tile 6 attr $20
    db $f8, $00, $1f, $00   ; dy -8 dx +0 tile 31 attr $00
    db $80
Anim_0a_F03:   ; $5f6b 22 sprites
    db $f8, $e8, $0a, $00   ; dy -8 dx -24 tile 10 attr $00
    db $f8, $f0, $0b, $00   ; dy -8 dx -16 tile 11 attr $00
    db $f8, $f8, $0c, $00   ; dy -8 dx -8 tile 12 attr $00
    db $f8, $00, $0d, $00   ; dy -8 dx +0 tile 13 attr $00
    db $e8, $e8, $01, $00   ; dy -24 dx -24 tile 1 attr $00
    db $e8, $f0, $02, $00   ; dy -24 dx -16 tile 2 attr $00
    db $e8, $f8, $03, $00   ; dy -24 dx -8 tile 3 attr $00
    db $e8, $00, $04, $00   ; dy -24 dx +0 tile 4 attr $00
    db $f0, $f8, $06, $20   ; dy -16 dx -8 tile 6 attr $20
    db $f0, $f0, $07, $20   ; dy -16 dx -16 tile 7 attr $20
    db $f0, $e8, $08, $20   ; dy -16 dx -24 tile 8 attr $20
    db $f0, $00, $09, $00   ; dy -16 dx +0 tile 9 attr $00
    db $d8, $e8, $14, $00   ; dy -40 dx -24 tile 20 attr $00
    db $d8, $f0, $15, $00   ; dy -40 dx -16 tile 21 attr $00
    db $d8, $f8, $16, $00   ; dy -40 dx -8 tile 22 attr $00
    db $e0, $f8, $18, $20   ; dy -32 dx -8 tile 24 attr $20
    db $e0, $f0, $19, $20   ; dy -32 dx -16 tile 25 attr $20
    db $e0, $e8, $1a, $20   ; dy -32 dx -24 tile 26 attr $20
    db $e0, $00, $1c, $00   ; dy -32 dx +0 tile 28 attr $00
    db $d0, $f0, $0e, $20   ; dy -48 dx -16 tile 14 attr $20
    db $d0, $e8, $0f, $20   ; dy -48 dx -24 tile 15 attr $20
    db $f8, $08, $1d, $00   ; dy -8 dx +8 tile 29 attr $00
    db $80
Anim_0a_F04:   ; $5fc4 30 sprites
    db $d8, $eb, $00, $00   ; dy -40 dx -21 tile 0 attr $00
    db $d8, $f3, $01, $00   ; dy -40 dx -13 tile 1 attr $00
    db $d8, $fb, $02, $00   ; dy -40 dx -5 tile 2 attr $00
    db $d8, $03, $03, $00   ; dy -40 dx +3 tile 3 attr $00
    db $d8, $0b, $04, $00   ; dy -40 dx +11 tile 4 attr $00
    db $e0, $e8, $05, $00   ; dy -32 dx -24 tile 5 attr $00
    db $e0, $f0, $06, $00   ; dy -32 dx -16 tile 6 attr $00
    db $e0, $f8, $07, $00   ; dy -32 dx -8 tile 7 attr $00
    db $e0, $00, $08, $00   ; dy -32 dx +0 tile 8 attr $00
    db $e0, $08, $09, $00   ; dy -32 dx +8 tile 9 attr $00
    db $e8, $f0, $0a, $00   ; dy -24 dx -16 tile 10 attr $00
    db $e8, $f8, $0b, $00   ; dy -24 dx -8 tile 11 attr $00
    db $e8, $00, $0c, $00   ; dy -24 dx +0 tile 12 attr $00
    db $e8, $08, $0d, $00   ; dy -24 dx +8 tile 13 attr $00
    db $f0, $f0, $0e, $00   ; dy -16 dx -16 tile 14 attr $00
    db $f0, $f8, $0f, $00   ; dy -16 dx -8 tile 15 attr $00
    db $f0, $00, $10, $00   ; dy -16 dx +0 tile 16 attr $00
    db $f0, $08, $11, $00   ; dy -16 dx +8 tile 17 attr $00
    db $d0, $0f, $17, $20   ; dy -48 dx +15 tile 23 attr $20
    db $d0, $07, $18, $20   ; dy -48 dx +7 tile 24 attr $20
    db $d0, $ff, $19, $20   ; dy -48 dx -1 tile 25 attr $20
    db $d0, $f7, $1a, $20   ; dy -48 dx -9 tile 26 attr $20
    db $d0, $ef, $1b, $20   ; dy -48 dx -17 tile 27 attr $20
    db $d0, $e7, $1c, $20   ; dy -48 dx -25 tile 28 attr $20
    db $f8, $e9, $12, $00   ; dy -8 dx -23 tile 18 attr $00
    db $f8, $f1, $13, $00   ; dy -8 dx -15 tile 19 attr $00
    db $f8, $f9, $14, $00   ; dy -8 dx -7 tile 20 attr $00
    db $f8, $01, $15, $00   ; dy -8 dx +1 tile 21 attr $00
    db $f8, $09, $16, $00   ; dy -8 dx +9 tile 22 attr $00
    db $f8, $10, $1e, $00   ; dy -8 dx +16 tile 30 attr $00
    db $80
Anim_0a_F05:   ; $603d 28 sprites
    db $e8, $09, $0e, $20   ; dy -24 dx +9 tile 14 attr $20
    db $e8, $01, $0f, $20   ; dy -24 dx +1 tile 15 attr $20
    db $e8, $f9, $10, $20   ; dy -24 dx -7 tile 16 attr $20
    db $e8, $f1, $11, $20   ; dy -24 dx -15 tile 17 attr $20
    db $f8, $f8, $18, $00   ; dy -8 dx -8 tile 24 attr $00
    db $f8, $00, $19, $00   ; dy -8 dx +0 tile 25 attr $00
    db $f8, $08, $1a, $00   ; dy -8 dx +8 tile 26 attr $00
    db $f8, $10, $1b, $00   ; dy -8 dx +16 tile 27 attr $00
    db $f8, $f0, $17, $00   ; dy -8 dx -16 tile 23 attr $00
    db $f0, $f8, $13, $00   ; dy -16 dx -8 tile 19 attr $00
    db $f0, $00, $14, $00   ; dy -16 dx +0 tile 20 attr $00
    db $f0, $08, $15, $00   ; dy -16 dx +8 tile 21 attr $00
    db $f0, $10, $16, $00   ; dy -16 dx +16 tile 22 attr $00
    db $f0, $f0, $12, $00   ; dy -16 dx -16 tile 18 attr $00
    db $e0, $ee, $0a, $00   ; dy -32 dx -18 tile 10 attr $00
    db $e0, $f6, $0b, $00   ; dy -32 dx -10 tile 11 attr $00
    db $e0, $fe, $0c, $00   ; dy -32 dx -2 tile 12 attr $00
    db $e0, $06, $0d, $00   ; dy -32 dx +6 tile 13 attr $00
    db $d8, $05, $05, $20   ; dy -40 dx +5 tile 5 attr $20
    db $d8, $fd, $06, $20   ; dy -40 dx -3 tile 6 attr $20
    db $d8, $f5, $07, $20   ; dy -40 dx -11 tile 7 attr $20
    db $d8, $ed, $08, $20   ; dy -40 dx -19 tile 8 attr $20
    db $d8, $e5, $05, $40   ; dy -40 dx -27 tile 5 attr $40
    db $d0, $00, $00, $20   ; dy -48 dx +0 tile 0 attr $20
    db $d0, $f8, $01, $20   ; dy -48 dx -8 tile 1 attr $20
    db $d0, $f0, $02, $20   ; dy -48 dx -16 tile 2 attr $20
    db $d0, $e8, $03, $20   ; dy -48 dx -24 tile 3 attr $20
    db $f8, $e8, $1f, $20   ; dy -8 dx -24 tile 31 attr $20
    db $80
Anim_0a_F06:   ; $60ae 31 sprites
    db $f0, $eb, $17, $00   ; dy -16 dx -21 tile 23 attr $00
    db $f0, $f3, $18, $00   ; dy -16 dx -13 tile 24 attr $00
    db $f0, $fb, $19, $00   ; dy -16 dx -5 tile 25 attr $00
    db $f0, $03, $1a, $00   ; dy -16 dx +3 tile 26 attr $00
    db $f0, $0b, $1b, $00   ; dy -16 dx +11 tile 27 attr $00
    db $f0, $13, $1c, $00   ; dy -16 dx +19 tile 28 attr $00
    db $e8, $eb, $12, $00   ; dy -24 dx -21 tile 18 attr $00
    db $e8, $f3, $13, $00   ; dy -24 dx -13 tile 19 attr $00
    db $e8, $fb, $14, $00   ; dy -24 dx -5 tile 20 attr $00
    db $e8, $03, $15, $00   ; dy -24 dx +3 tile 21 attr $00
    db $e8, $0b, $16, $00   ; dy -24 dx +11 tile 22 attr $00
    db $d0, $10, $05, $20   ; dy -48 dx +16 tile 5 attr $20
    db $e0, $06, $0e, $20   ; dy -32 dx +6 tile 14 attr $20
    db $e0, $fe, $0f, $20   ; dy -32 dx -2 tile 15 attr $20
    db $e0, $f6, $10, $20   ; dy -32 dx -10 tile 16 attr $20
    db $e0, $ee, $11, $20   ; dy -32 dx -18 tile 17 attr $20
    db $d8, $06, $0a, $20   ; dy -40 dx +6 tile 10 attr $20
    db $d8, $fe, $0b, $20   ; dy -40 dx -2 tile 11 attr $20
    db $d8, $f6, $0c, $20   ; dy -40 dx -10 tile 12 attr $20
    db $d8, $ee, $0d, $20   ; dy -40 dx -18 tile 13 attr $20
    db $d0, $08, $06, $20   ; dy -48 dx +8 tile 6 attr $20
    db $d0, $00, $07, $20   ; dy -48 dx +0 tile 7 attr $20
    db $d0, $f8, $08, $20   ; dy -48 dx -8 tile 8 attr $20
    db $d0, $f0, $09, $20   ; dy -48 dx -16 tile 9 attr $20
    db $f8, $10, $1f, $00   ; dy -8 dx +16 tile 31 attr $00
    db $f8, $e8, $1d, $00   ; dy -8 dx -24 tile 29 attr $00
    db $f8, $0c, $00, $20   ; dy -8 dx +12 tile 0 attr $20
    db $f8, $04, $01, $20   ; dy -8 dx +4 tile 1 attr $20
    db $f8, $fc, $02, $20   ; dy -8 dx -4 tile 2 attr $20
    db $f8, $f4, $03, $20   ; dy -8 dx -12 tile 3 attr $20
    db $f8, $ec, $04, $20   ; dy -8 dx -20 tile 4 attr $20
    db $80
Anim_0a_F07:   ; $612b 31 sprites
    db $f0, $0c, $00, $20   ; dy -16 dx +12 tile 0 attr $20
    db $f0, $04, $01, $20   ; dy -16 dx +4 tile 1 attr $20
    db $f0, $fc, $02, $20   ; dy -16 dx -4 tile 2 attr $20
    db $f0, $f4, $03, $20   ; dy -16 dx -12 tile 3 attr $20
    db $f0, $ec, $04, $20   ; dy -16 dx -20 tile 4 attr $20
    db $e8, $0f, $17, $20   ; dy -24 dx +15 tile 23 attr $20
    db $e8, $07, $18, $20   ; dy -24 dx +7 tile 24 attr $20
    db $e8, $ff, $19, $20   ; dy -24 dx -1 tile 25 attr $20
    db $e8, $f7, $1a, $20   ; dy -24 dx -9 tile 26 attr $20
    db $e8, $ef, $1b, $20   ; dy -24 dx -17 tile 27 attr $20
    db $e8, $e7, $1c, $20   ; dy -24 dx -25 tile 28 attr $20
    db $e0, $0f, $12, $20   ; dy -32 dx +15 tile 18 attr $20
    db $e0, $07, $13, $20   ; dy -32 dx +7 tile 19 attr $20
    db $e0, $ff, $14, $20   ; dy -32 dx -1 tile 20 attr $20
    db $e0, $f7, $15, $20   ; dy -32 dx -9 tile 21 attr $20
    db $e0, $ef, $16, $20   ; dy -32 dx -17 tile 22 attr $20
    db $f8, $f1, $06, $00   ; dy -8 dx -15 tile 6 attr $00
    db $f8, $f9, $07, $00   ; dy -8 dx -7 tile 7 attr $00
    db $f8, $01, $08, $00   ; dy -8 dx +1 tile 8 attr $00
    db $f8, $09, $09, $00   ; dy -8 dx +9 tile 9 attr $00
    db $d8, $f4, $0e, $00   ; dy -40 dx -12 tile 14 attr $00
    db $d8, $fc, $0f, $00   ; dy -40 dx -4 tile 15 attr $00
    db $d8, $04, $10, $00   ; dy -40 dx +4 tile 16 attr $00
    db $d8, $0c, $11, $00   ; dy -40 dx +12 tile 17 attr $00
    db $d0, $10, $0a, $20   ; dy -48 dx +16 tile 10 attr $20
    db $d0, $08, $0b, $20   ; dy -48 dx +8 tile 11 attr $20
    db $d0, $00, $0c, $20   ; dy -48 dx +0 tile 12 attr $20
    db $d0, $f8, $0d, $20   ; dy -48 dx -8 tile 13 attr $20
    db $f8, $e8, $1e, $20   ; dy -8 dx -24 tile 30 attr $20
    db $f8, $e9, $05, $00   ; dy -8 dx -23 tile 5 attr $00
    db $f8, $10, $1d, $00   ; dy -8 dx +16 tile 29 attr $00
    db $80
Anim_0a_F08:   ; $61a8 30 sprites
    db $d8, $e7, $12, $00   ; dy -40 dx -25 tile 18 attr $00
    db $d8, $ef, $13, $00   ; dy -40 dx -17 tile 19 attr $00
    db $d8, $f7, $14, $00   ; dy -40 dx -9 tile 20 attr $00
    db $d8, $ff, $15, $00   ; dy -40 dx -1 tile 21 attr $00
    db $d8, $07, $16, $00   ; dy -40 dx +7 tile 22 attr $00
    db $f8, $f8, $0a, $00   ; dy -8 dx -8 tile 10 attr $00
    db $f8, $00, $0b, $00   ; dy -8 dx +0 tile 11 attr $00
    db $f8, $08, $0c, $00   ; dy -8 dx +8 tile 12 attr $00
    db $f8, $10, $0d, $00   ; dy -8 dx +16 tile 13 attr $00
    db $f0, $0b, $05, $20   ; dy -16 dx +11 tile 5 attr $20
    db $f0, $03, $06, $20   ; dy -16 dx +3 tile 6 attr $20
    db $f0, $fb, $07, $20   ; dy -16 dx -5 tile 7 attr $20
    db $f0, $f3, $08, $20   ; dy -16 dx -13 tile 8 attr $20
    db $f0, $eb, $09, $20   ; dy -16 dx -21 tile 9 attr $20
    db $e8, $e9, $00, $00   ; dy -24 dx -23 tile 0 attr $00
    db $e8, $f1, $01, $00   ; dy -24 dx -15 tile 1 attr $00
    db $e8, $f9, $02, $00   ; dy -24 dx -7 tile 2 attr $00
    db $e8, $01, $03, $00   ; dy -24 dx +1 tile 3 attr $00
    db $e8, $09, $04, $00   ; dy -24 dx +9 tile 4 attr $00
    db $e0, $e6, $17, $00   ; dy -32 dx -26 tile 23 attr $00
    db $e0, $ee, $18, $00   ; dy -32 dx -18 tile 24 attr $00
    db $e0, $f6, $19, $00   ; dy -32 dx -10 tile 25 attr $00
    db $e0, $fe, $1a, $00   ; dy -32 dx -2 tile 26 attr $00
    db $e0, $06, $1b, $00   ; dy -32 dx +6 tile 27 attr $00
    db $e0, $0e, $1c, $00   ; dy -32 dx +14 tile 28 attr $00
    db $d0, $f2, $0e, $00   ; dy -48 dx -14 tile 14 attr $00
    db $d0, $fa, $0f, $00   ; dy -48 dx -6 tile 15 attr $00
    db $d0, $02, $10, $00   ; dy -48 dx +2 tile 16 attr $00
    db $d0, $0a, $11, $00   ; dy -48 dx +10 tile 17 attr $00
    db $f8, $f0, $1e, $20   ; dy -8 dx -16 tile 30 attr $20
    db $80
Anim_0a_F09:   ; $6221 30 sprites
    db $f0, $f4, $0a, $00   ; dy -16 dx -12 tile 10 attr $00
    db $f0, $fc, $0b, $00   ; dy -16 dx -4 tile 11 attr $00
    db $f0, $04, $0c, $00   ; dy -16 dx +4 tile 12 attr $00
    db $f0, $0c, $0d, $00   ; dy -16 dx +12 tile 13 attr $00
    db $e8, $0c, $05, $20   ; dy -24 dx +12 tile 5 attr $20
    db $e8, $04, $06, $20   ; dy -24 dx +4 tile 6 attr $20
    db $e8, $fc, $07, $20   ; dy -24 dx -4 tile 7 attr $20
    db $e8, $f4, $08, $20   ; dy -24 dx -12 tile 8 attr $20
    db $e8, $ec, $09, $20   ; dy -24 dx -20 tile 9 attr $20
    db $e0, $ea, $00, $00   ; dy -32 dx -22 tile 0 attr $00
    db $e0, $f2, $01, $00   ; dy -32 dx -14 tile 1 attr $00
    db $e0, $fa, $02, $00   ; dy -32 dx -6 tile 2 attr $00
    db $e0, $02, $03, $00   ; dy -32 dx +2 tile 3 attr $00
    db $e0, $0a, $04, $00   ; dy -32 dx +10 tile 4 attr $00
    db $d8, $e7, $17, $00   ; dy -40 dx -25 tile 23 attr $00
    db $d8, $ef, $18, $00   ; dy -40 dx -17 tile 24 attr $00
    db $d8, $f7, $19, $00   ; dy -40 dx -9 tile 25 attr $00
    db $d8, $ff, $1a, $00   ; dy -40 dx -1 tile 26 attr $00
    db $d8, $07, $1b, $00   ; dy -40 dx +7 tile 27 attr $00
    db $d8, $0f, $1c, $00   ; dy -40 dx +15 tile 28 attr $00
    db $d0, $e7, $12, $00   ; dy -48 dx -25 tile 18 attr $00
    db $d0, $ef, $13, $00   ; dy -48 dx -17 tile 19 attr $00
    db $d0, $f7, $14, $00   ; dy -48 dx -9 tile 20 attr $00
    db $d0, $ff, $15, $00   ; dy -48 dx -1 tile 21 attr $00
    db $d0, $07, $16, $00   ; dy -48 dx +7 tile 22 attr $00
    db $f8, $10, $0e, $20   ; dy -8 dx +16 tile 14 attr $20
    db $f8, $08, $0f, $20   ; dy -8 dx +8 tile 15 attr $20
    db $f8, $00, $10, $20   ; dy -8 dx +0 tile 16 attr $20
    db $f8, $f8, $11, $20   ; dy -8 dx -8 tile 17 attr $20
    db $f8, $f0, $1f, $20   ; dy -8 dx -16 tile 31 attr $20
    db $80
Anim_0a_F10:   ; $629a 30 sprites
    db $f8, $10, $12, $20   ; dy -8 dx +16 tile 18 attr $20
    db $f8, $08, $13, $20   ; dy -8 dx +8 tile 19 attr $20
    db $f8, $00, $14, $20   ; dy -8 dx +0 tile 20 attr $20
    db $f8, $f8, $15, $20   ; dy -8 dx -8 tile 21 attr $20
    db $f8, $f0, $16, $20   ; dy -8 dx -16 tile 22 attr $20
    db $e8, $08, $0a, $20   ; dy -24 dx +8 tile 10 attr $20
    db $e8, $00, $0b, $20   ; dy -24 dx +0 tile 11 attr $20
    db $e8, $f8, $0c, $20   ; dy -24 dx -8 tile 12 attr $20
    db $e8, $f0, $0d, $20   ; dy -24 dx -16 tile 13 attr $20
    db $f0, $08, $0e, $20   ; dy -16 dx +8 tile 14 attr $20
    db $f0, $00, $0f, $20   ; dy -16 dx +0 tile 15 attr $20
    db $f0, $f8, $10, $20   ; dy -16 dx -8 tile 16 attr $20
    db $f0, $f0, $11, $20   ; dy -16 dx -16 tile 17 attr $20
    db $e0, $12, $05, $20   ; dy -32 dx +18 tile 5 attr $20
    db $e0, $0a, $06, $20   ; dy -32 dx +10 tile 6 attr $20
    db $e0, $02, $07, $20   ; dy -32 dx +2 tile 7 attr $20
    db $e0, $fa, $08, $20   ; dy -32 dx -6 tile 8 attr $20
    db $e0, $f2, $09, $20   ; dy -32 dx -14 tile 9 attr $20
    db $d8, $f0, $00, $00   ; dy -40 dx -16 tile 0 attr $00
    db $d8, $f8, $01, $00   ; dy -40 dx -8 tile 1 attr $00
    db $d8, $00, $02, $00   ; dy -40 dx +0 tile 2 attr $00
    db $d8, $08, $03, $00   ; dy -40 dx +8 tile 3 attr $00
    db $d8, $10, $04, $00   ; dy -40 dx +16 tile 4 attr $00
    db $d0, $12, $17, $20   ; dy -48 dx +18 tile 23 attr $20
    db $d0, $0a, $18, $20   ; dy -48 dx +10 tile 24 attr $20
    db $d0, $02, $19, $20   ; dy -48 dx +2 tile 25 attr $20
    db $d0, $fa, $1a, $20   ; dy -48 dx -6 tile 26 attr $20
    db $d0, $f2, $1b, $20   ; dy -48 dx -14 tile 27 attr $20
    db $d0, $ea, $1c, $20   ; dy -48 dx -22 tile 28 attr $20
    db $f8, $e8, $1d, $20   ; dy -8 dx -24 tile 29 attr $20
    db $80
Anim_0a_F11:   ; $6313 29 sprites
    db $f0, $e8, $12, $00   ; dy -16 dx -24 tile 18 attr $00
    db $f0, $f0, $13, $00   ; dy -16 dx -16 tile 19 attr $00
    db $f0, $f8, $14, $00   ; dy -16 dx -8 tile 20 attr $00
    db $f0, $00, $15, $00   ; dy -16 dx +0 tile 21 attr $00
    db $f0, $08, $16, $00   ; dy -16 dx +8 tile 22 attr $00
    db $e8, $f0, $0e, $00   ; dy -24 dx -16 tile 14 attr $00
    db $e8, $f8, $0f, $00   ; dy -24 dx -8 tile 15 attr $00
    db $e8, $00, $10, $00   ; dy -24 dx +0 tile 16 attr $00
    db $e8, $08, $11, $00   ; dy -24 dx +8 tile 17 attr $00
    db $e0, $0b, $0a, $20   ; dy -32 dx +11 tile 10 attr $20
    db $e0, $03, $0b, $20   ; dy -32 dx +3 tile 11 attr $20
    db $e0, $fb, $0c, $20   ; dy -32 dx -5 tile 12 attr $20
    db $e0, $f3, $0d, $20   ; dy -32 dx -13 tile 13 attr $20
    db $d8, $f8, $05, $00   ; dy -40 dx -8 tile 5 attr $00
    db $d8, $00, $06, $00   ; dy -40 dx +0 tile 6 attr $00
    db $d8, $08, $07, $00   ; dy -40 dx +8 tile 7 attr $00
    db $d8, $10, $08, $00   ; dy -40 dx +16 tile 8 attr $00
    db $d0, $10, $01, $20   ; dy -48 dx +16 tile 1 attr $20
    db $d0, $08, $02, $20   ; dy -48 dx +8 tile 2 attr $20
    db $d0, $00, $03, $20   ; dy -48 dx +0 tile 3 attr $20
    db $d0, $f8, $04, $20   ; dy -48 dx -8 tile 4 attr $20
    db $f8, $f7, $19, $00   ; dy -8 dx -9 tile 25 attr $00
    db $f8, $ff, $1a, $00   ; dy -8 dx -1 tile 26 attr $00
    db $f8, $10, $1e, $00   ; dy -8 dx +16 tile 30 attr $00
    db $f8, $e8, $1e, $20   ; dy -8 dx -24 tile 30 attr $20
    db $f8, $e7, $17, $00   ; dy -8 dx -25 tile 23 attr $00
    db $f8, $ef, $18, $00   ; dy -8 dx -17 tile 24 attr $00
    db $f8, $07, $1b, $00   ; dy -8 dx +7 tile 27 attr $00
    db $f8, $0f, $1c, $00   ; dy -8 dx +15 tile 28 attr $00
    db $80
Anim_0a_F12:   ; $6388 31 sprites
    db $d8, $0b, $00, $20   ; dy -40 dx +11 tile 0 attr $20
    db $d8, $03, $01, $20   ; dy -40 dx +3 tile 1 attr $20
    db $d8, $fb, $02, $20   ; dy -40 dx -5 tile 2 attr $20
    db $d8, $f3, $03, $20   ; dy -40 dx -13 tile 3 attr $20
    db $d8, $eb, $04, $20   ; dy -40 dx -21 tile 4 attr $20
    db $e0, $0e, $05, $20   ; dy -32 dx +14 tile 5 attr $20
    db $e0, $06, $06, $20   ; dy -32 dx +6 tile 6 attr $20
    db $e0, $fe, $07, $20   ; dy -32 dx -2 tile 7 attr $20
    db $e0, $f6, $08, $20   ; dy -32 dx -10 tile 8 attr $20
    db $e0, $ee, $09, $20   ; dy -32 dx -18 tile 9 attr $20
    db $e8, $06, $0a, $20   ; dy -24 dx +6 tile 10 attr $20
    db $e8, $fe, $0b, $20   ; dy -24 dx -2 tile 11 attr $20
    db $e8, $f6, $0c, $20   ; dy -24 dx -10 tile 12 attr $20
    db $e8, $ee, $0d, $20   ; dy -24 dx -18 tile 13 attr $20
    db $f0, $06, $0e, $20   ; dy -16 dx +6 tile 14 attr $20
    db $f0, $fe, $0f, $20   ; dy -16 dx -2 tile 15 attr $20
    db $f0, $f6, $10, $20   ; dy -16 dx -10 tile 16 attr $20
    db $f0, $ee, $11, $20   ; dy -16 dx -18 tile 17 attr $20
    db $d0, $e7, $17, $00   ; dy -48 dx -25 tile 23 attr $00
    db $d0, $ef, $18, $00   ; dy -48 dx -17 tile 24 attr $00
    db $d0, $f7, $19, $00   ; dy -48 dx -9 tile 25 attr $00
    db $d0, $ff, $1a, $00   ; dy -48 dx -1 tile 26 attr $00
    db $d0, $07, $1b, $00   ; dy -48 dx +7 tile 27 attr $00
    db $d0, $0f, $1c, $00   ; dy -48 dx +15 tile 28 attr $00
    db $f8, $05, $13, $20   ; dy -8 dx +5 tile 19 attr $20
    db $f8, $fd, $14, $20   ; dy -8 dx -3 tile 20 attr $20
    db $f8, $f5, $15, $20   ; dy -8 dx -11 tile 21 attr $20
    db $f8, $0d, $12, $20   ; dy -8 dx +13 tile 18 attr $20
    db $f8, $e8, $1d, $20   ; dy -8 dx -24 tile 29 attr $20
    db $f8, $ed, $16, $20   ; dy -8 dx -19 tile 22 attr $20
    db $f8, $10, $1f, $00   ; dy -8 dx +16 tile 31 attr $00
    db $80
Anim_0a_F13:   ; $6405 29 sprites
    db $e8, $0b, $0e, $20   ; dy -24 dx +11 tile 14 attr $20
    db $e8, $03, $0f, $20   ; dy -24 dx +3 tile 15 attr $20
    db $e8, $fb, $10, $20   ; dy -24 dx -5 tile 16 attr $20
    db $e8, $f3, $11, $20   ; dy -24 dx -13 tile 17 attr $20
    db $f8, $f0, $17, $00   ; dy -8 dx -16 tile 23 attr $00
    db $f8, $f8, $18, $00   ; dy -8 dx -8 tile 24 attr $00
    db $f8, $00, $19, $00   ; dy -8 dx +0 tile 25 attr $00
    db $f8, $08, $1a, $00   ; dy -8 dx +8 tile 26 attr $00
    db $f8, $10, $1b, $00   ; dy -8 dx +16 tile 27 attr $00
    db $d0, $eb, $00, $00   ; dy -48 dx -21 tile 0 attr $00
    db $d0, $f3, $01, $00   ; dy -48 dx -13 tile 1 attr $00
    db $d0, $fb, $02, $00   ; dy -48 dx -5 tile 2 attr $00
    db $d0, $03, $03, $00   ; dy -48 dx +3 tile 3 attr $00
    db $d0, $0b, $04, $00   ; dy -48 dx +11 tile 4 attr $00
    db $d8, $e8, $05, $00   ; dy -40 dx -24 tile 5 attr $00
    db $d8, $f0, $06, $00   ; dy -40 dx -16 tile 6 attr $00
    db $d8, $f8, $07, $00   ; dy -40 dx -8 tile 7 attr $00
    db $d8, $00, $08, $00   ; dy -40 dx +0 tile 8 attr $00
    db $d8, $08, $09, $00   ; dy -40 dx +8 tile 9 attr $00
    db $e0, $f0, $0a, $00   ; dy -32 dx -16 tile 10 attr $00
    db $e0, $f8, $0b, $00   ; dy -32 dx -8 tile 11 attr $00
    db $e0, $00, $0c, $00   ; dy -32 dx +0 tile 12 attr $00
    db $e0, $08, $0d, $00   ; dy -32 dx +8 tile 13 attr $00
    db $f0, $f0, $12, $00   ; dy -16 dx -16 tile 18 attr $00
    db $f0, $f8, $13, $00   ; dy -16 dx -8 tile 19 attr $00
    db $f0, $00, $14, $00   ; dy -16 dx +0 tile 20 attr $00
    db $f0, $08, $15, $00   ; dy -16 dx +8 tile 21 attr $00
    db $f0, $10, $16, $00   ; dy -16 dx +16 tile 22 attr $00
    db $f8, $e8, $1e, $20   ; dy -8 dx -24 tile 30 attr $20
    db $80
Anim_0a_F14:   ; $647a 23 sprites
    db $f0, $00, $17, $00   ; dy -16 dx +0 tile 23 attr $00
    db $f0, $08, $18, $00   ; dy -16 dx +8 tile 24 attr $00
    db $f0, $10, $19, $00   ; dy -16 dx +16 tile 25 attr $00
    db $e8, $00, $12, $00   ; dy -24 dx +0 tile 18 attr $00
    db $e8, $08, $13, $00   ; dy -24 dx +8 tile 19 attr $00
    db $e8, $10, $14, $00   ; dy -24 dx +16 tile 20 attr $00
    db $f8, $10, $02, $20   ; dy -8 dx +16 tile 2 attr $20
    db $f8, $08, $03, $20   ; dy -8 dx +8 tile 3 attr $20
    db $f8, $00, $04, $20   ; dy -8 dx +0 tile 4 attr $20
    db $e0, $10, $0f, $20   ; dy -32 dx +16 tile 15 attr $20
    db $e0, $08, $10, $20   ; dy -32 dx +8 tile 16 attr $20
    db $e0, $00, $11, $20   ; dy -32 dx +0 tile 17 attr $20
    db $d8, $fa, $0a, $00   ; dy -40 dx -6 tile 10 attr $00
    db $d8, $02, $0b, $00   ; dy -40 dx +2 tile 11 attr $00
    db $d8, $0a, $0c, $00   ; dy -40 dx +10 tile 12 attr $00
    db $d8, $12, $0d, $00   ; dy -40 dx +18 tile 13 attr $00
    db $d0, $0d, $05, $20   ; dy -48 dx +13 tile 5 attr $20
    db $d0, $05, $06, $20   ; dy -48 dx +5 tile 6 attr $20
    db $d0, $fd, $07, $20   ; dy -48 dx -3 tile 7 attr $20
    db $d0, $f5, $08, $20   ; dy -48 dx -11 tile 8 attr $20
    db $d0, $ed, $09, $20   ; dy -48 dx -19 tile 9 attr $20
    db $f8, $f0, $1f, $20   ; dy -8 dx -16 tile 31 attr $20
    db $f8, $f8, $1d, $20   ; dy -8 dx -8 tile 29 attr $20
    db $80
Anim_0a_F15:   ; $64d7 10 sprites
    db $e8, $10, $1b, $20   ; dy -24 dx +16 tile 27 attr $20
    db $e0, $10, $16, $20   ; dy -32 dx +16 tile 22 attr $20
    db $f0, $10, $00, $00   ; dy -16 dx +16 tile 0 attr $00
    db $f8, $10, $05, $00   ; dy -8 dx +16 tile 5 attr $00
    db $d0, $08, $0a, $00   ; dy -48 dx +8 tile 10 attr $00
    db $d0, $10, $0b, $00   ; dy -48 dx +16 tile 11 attr $00
    db $e7, $08, $1c, $20   ; dy -25 dx +8 tile 28 attr $20
    db $d8, $10, $11, $20   ; dy -40 dx +16 tile 17 attr $20
    db $f8, $00, $1f, $20   ; dy -8 dx +0 tile 31 attr $20
    db $f8, $08, $1d, $20   ; dy -8 dx +8 tile 29 attr $20
    db $80
Anim_0a_F16:   ; $6500 26 sprites
    db $f8, $0b, $13, $20   ; dy -8 dx +11 tile 19 attr $20
    db $f8, $03, $14, $20   ; dy -8 dx +3 tile 20 attr $20
    db $f8, $fb, $15, $20   ; dy -8 dx -5 tile 21 attr $20
    db $f8, $f3, $16, $20   ; dy -8 dx -13 tile 22 attr $20
    db $f0, $0b, $0e, $20   ; dy -16 dx +11 tile 14 attr $20
    db $f0, $03, $0f, $20   ; dy -16 dx +3 tile 15 attr $20
    db $f0, $fb, $10, $20   ; dy -16 dx -5 tile 16 attr $20
    db $f0, $f3, $11, $20   ; dy -16 dx -13 tile 17 attr $20
    db $e0, $e7, $05, $40   ; dy -32 dx -25 tile 5 attr $40
    db $e8, $f0, $0a, $00   ; dy -24 dx -16 tile 10 attr $00
    db $e8, $f8, $0b, $00   ; dy -24 dx -8 tile 11 attr $00
    db $e8, $00, $0c, $00   ; dy -24 dx +0 tile 12 attr $00
    db $e8, $08, $0d, $00   ; dy -24 dx +8 tile 13 attr $00
    db $e0, $04, $05, $20   ; dy -32 dx +4 tile 5 attr $20
    db $e0, $fc, $06, $20   ; dy -32 dx -4 tile 6 attr $20
    db $e0, $f4, $07, $20   ; dy -32 dx -12 tile 7 attr $20
    db $d8, $00, $00, $20   ; dy -40 dx +0 tile 0 attr $20
    db $d8, $f8, $01, $20   ; dy -40 dx -8 tile 1 attr $20
    db $d8, $f0, $02, $20   ; dy -40 dx -16 tile 2 attr $20
    db $d8, $e8, $03, $20   ; dy -40 dx -24 tile 3 attr $20
    db $d0, $00, $17, $20   ; dy -48 dx +0 tile 23 attr $20
    db $d0, $f8, $18, $20   ; dy -48 dx -8 tile 24 attr $20
    db $d0, $f0, $19, $20   ; dy -48 dx -16 tile 25 attr $20
    db $d0, $e8, $1a, $20   ; dy -48 dx -24 tile 26 attr $20
    db $e0, $ec, $08, $20   ; dy -32 dx -20 tile 8 attr $20
    db $f8, $11, $12, $20   ; dy -8 dx +17 tile 18 attr $20
Anim_0a_F24:   ; $6568 empty frame = the $80 end above (shared)
    db $80
Anim_0b_Infermost:   ; $6569 animation $0b — Infermost, Vacuum
    dw Anim_0b_F00
    dw Anim_0b_F01
    dw Anim_0b_F02
    dw Anim_0b_F03
    dw Anim_0b_F04
    dw Anim_0b_F05
    dw Anim_0b_F06
    dw Anim_0b_F07
    dw Anim_0b_F08
    dw Anim_0b_F09
    dw Anim_0b_F10
    dw Anim_0b_F11
    dw Anim_0b_F12
    dw Anim_0b_F13
    dw Anim_0b_F14
    dw Anim_0b_F15
    dw Anim_0b_F16
    dw Anim_0b_F17
    dw Anim_0b_F18
    dw Anim_0b_F19
    dw Anim_0b_F20
    dw Anim_0b_F21
    dw Anim_0b_F22
    dw Anim_0b_F23
    dw Anim_0b_F24
    dw Anim_0b_F25
    dw Anim_0b_F26
    dw Anim_0b_F27
    dw Anim_0b_F27
    dw Anim_0b_F27
    dw Anim_0b_F27
    dw Anim_0b_F27
Anim_0b_F00:   ; $65a9 13 sprites
    db $f8, $b0, $04, $00   ; dy -8 dx -80 tile 4 attr $00
    db $f8, $b8, $05, $00   ; dy -8 dx -72 tile 5 attr $00
    db $f8, $c0, $06, $00   ; dy -8 dx -64 tile 6 attr $00
    db $f8, $c8, $07, $00   ; dy -8 dx -56 tile 7 attr $00
    db $f8, $d0, $08, $00   ; dy -8 dx -48 tile 8 attr $00
    db $f8, $d8, $09, $00   ; dy -8 dx -40 tile 9 attr $00
    db $f2, $d0, $05, $00   ; dy -14 dx -48 tile 5 attr $00
    db $f2, $d8, $06, $00   ; dy -14 dx -40 tile 6 attr $00
    db $f2, $c9, $04, $00   ; dy -14 dx -55 tile 4 attr $00
    db $f0, $b0, $08, $00   ; dy -16 dx -80 tile 8 attr $00
    db $f0, $b8, $09, $00   ; dy -16 dx -72 tile 9 attr $00
    db $f8, $e0, $20, $00   ; dy -8 dx -32 tile 32 attr $00
    db $f8, $e8, $1c, $40   ; dy -8 dx -24 tile 28 attr $40
    db $80
Anim_0b_F01:   ; $65de 14 sprites
    db $f8, $c0, $0a, $00   ; dy -8 dx -64 tile 10 attr $00
    db $f8, $c8, $0b, $00   ; dy -8 dx -56 tile 11 attr $00
    db $f8, $d0, $0c, $00   ; dy -8 dx -48 tile 12 attr $00
    db $f8, $d8, $0d, $00   ; dy -8 dx -40 tile 13 attr $00
    db $f0, $b8, $04, $00   ; dy -16 dx -72 tile 4 attr $00
    db $f0, $c0, $05, $00   ; dy -16 dx -64 tile 5 attr $00
    db $f0, $c8, $06, $00   ; dy -16 dx -56 tile 6 attr $00
    db $f0, $d0, $07, $00   ; dy -16 dx -48 tile 7 attr $00
    db $f0, $d8, $08, $00   ; dy -16 dx -40 tile 8 attr $00
    db $f0, $e0, $09, $00   ; dy -16 dx -32 tile 9 attr $00
    db $f8, $b0, $20, $20   ; dy -8 dx -80 tile 32 attr $20
    db $f8, $e8, $21, $00   ; dy -8 dx -24 tile 33 attr $00
    db $f0, $f0, $1d, $00   ; dy -16 dx -16 tile 29 attr $00
    db $e8, $b0, $1c, $00   ; dy -24 dx -80 tile 28 attr $00
    db $80
Anim_0b_F02:   ; $6617 34 sprites
    db $d8, $e0, $04, $00   ; dy -40 dx -32 tile 4 attr $00
    db $d8, $c0, $05, $00   ; dy -40 dx -64 tile 5 attr $00
    db $d8, $c8, $06, $00   ; dy -40 dx -56 tile 6 attr $00
    db $d8, $d0, $07, $00   ; dy -40 dx -48 tile 7 attr $00
    db $d8, $d8, $08, $00   ; dy -40 dx -40 tile 8 attr $00
    db $d8, $e0, $09, $00   ; dy -40 dx -32 tile 9 attr $00
    db $e0, $c0, $0a, $00   ; dy -32 dx -64 tile 10 attr $00
    db $e0, $c8, $0b, $00   ; dy -32 dx -56 tile 11 attr $00
    db $e0, $d0, $0c, $00   ; dy -32 dx -48 tile 12 attr $00
    db $e0, $d8, $0d, $00   ; dy -32 dx -40 tile 13 attr $00
    db $f0, $d0, $0a, $00   ; dy -16 dx -48 tile 10 attr $00
    db $f0, $d8, $0b, $00   ; dy -16 dx -40 tile 11 attr $00
    db $f0, $e0, $0c, $00   ; dy -16 dx -32 tile 12 attr $00
    db $e8, $c8, $04, $00   ; dy -24 dx -56 tile 4 attr $00
    db $e8, $d0, $05, $00   ; dy -24 dx -48 tile 5 attr $00
    db $e8, $d8, $06, $00   ; dy -24 dx -40 tile 6 attr $00
    db $e8, $e0, $07, $00   ; dy -24 dx -32 tile 7 attr $00
    db $f8, $d0, $10, $00   ; dy -8 dx -48 tile 16 attr $00
    db $f8, $d8, $11, $00   ; dy -8 dx -40 tile 17 attr $00
    db $f8, $e0, $12, $00   ; dy -8 dx -32 tile 18 attr $00
    db $f8, $c0, $0e, $00   ; dy -8 dx -64 tile 14 attr $00
    db $f8, $c8, $0f, $00   ; dy -8 dx -56 tile 15 attr $00
    db $f0, $e8, $0d, $00   ; dy -16 dx -24 tile 13 attr $00
    db $e8, $e8, $08, $00   ; dy -24 dx -24 tile 8 attr $00
    db $e8, $f0, $09, $00   ; dy -24 dx -16 tile 9 attr $00
    db $f8, $e8, $17, $00   ; dy -8 dx -24 tile 23 attr $00
    db $f8, $b0, $21, $20   ; dy -8 dx -80 tile 33 attr $20
    db $f8, $f8, $21, $00   ; dy -8 dx -8 tile 33 attr $00
    db $f0, $c0, $1d, $20   ; dy -16 dx -64 tile 29 attr $20
    db $e8, $00, $1c, $20   ; dy -24 dx +0 tile 28 attr $20
    db $f0, $10, $1f, $00   ; dy -16 dx +16 tile 31 attr $00
    db $f8, $f0, $13, $00   ; dy -8 dx -16 tile 19 attr $00
    db $f8, $b8, $13, $20   ; dy -8 dx -72 tile 19 attr $20
    db $e0, $b8, $1e, $00   ; dy -32 dx -72 tile 30 attr $00
    db $80
Anim_0b_F03:   ; $66a0 18 sprites
    db $f0, $e4, $0a, $00   ; dy -16 dx -28 tile 10 attr $00
    db $f0, $ec, $0b, $00   ; dy -16 dx -20 tile 11 attr $00
    db $f0, $f4, $0c, $00   ; dy -16 dx -12 tile 12 attr $00
    db $f0, $fc, $0d, $00   ; dy -16 dx -4 tile 13 attr $00
    db $f8, $b8, $04, $00   ; dy -8 dx -72 tile 4 attr $00
    db $f8, $c0, $05, $00   ; dy -8 dx -64 tile 5 attr $00
    db $f8, $c8, $06, $00   ; dy -8 dx -56 tile 6 attr $00
    db $f8, $d0, $07, $00   ; dy -8 dx -48 tile 7 attr $00
    db $f8, $d8, $08, $00   ; dy -8 dx -40 tile 8 attr $00
    db $f8, $e0, $05, $00   ; dy -8 dx -32 tile 5 attr $00
    db $f8, $e8, $06, $00   ; dy -8 dx -24 tile 6 attr $00
    db $f8, $f0, $07, $00   ; dy -8 dx -16 tile 7 attr $00
    db $f8, $f8, $08, $00   ; dy -8 dx -8 tile 8 attr $00
    db $f8, $00, $09, $00   ; dy -8 dx +0 tile 9 attr $00
    db $d0, $20, $1e, $00   ; dy -48 dx +32 tile 30 attr $00
    db $e8, $20, $1f, $00   ; dy -24 dx +32 tile 31 attr $00
    db $e0, $10, $1d, $00   ; dy -32 dx +16 tile 29 attr $00
    db $f0, $d8, $1c, $00   ; dy -16 dx -40 tile 28 attr $00
    db $80
Anim_0b_F04:   ; $66e9 40 sprites
    db $f8, $e0, $0e, $00   ; dy -8 dx -32 tile 14 attr $00
    db $e0, $08, $0b, $00   ; dy -32 dx +8 tile 11 attr $00
    db $e0, $10, $0c, $00   ; dy -32 dx +16 tile 12 attr $00
    db $e0, $18, $0d, $00   ; dy -32 dx +24 tile 13 attr $00
    db $d8, $08, $05, $00   ; dy -40 dx +8 tile 5 attr $00
    db $d8, $10, $06, $00   ; dy -40 dx +16 tile 6 attr $00
    db $d8, $18, $08, $00   ; dy -40 dx +24 tile 8 attr $00
    db $da, $20, $11, $00   ; dy -38 dx +32 tile 17 attr $00
    db $da, $28, $12, $00   ; dy -38 dx +40 tile 18 attr $00
    db $e8, $f8, $0a, $00   ; dy -24 dx -8 tile 10 attr $00
    db $e8, $00, $0b, $00   ; dy -24 dx +0 tile 11 attr $00
    db $e8, $08, $0c, $00   ; dy -24 dx +8 tile 12 attr $00
    db $e8, $10, $0d, $00   ; dy -24 dx +16 tile 13 attr $00
    db $d0, $f0, $10, $00   ; dy -48 dx -16 tile 16 attr $00
    db $d0, $f8, $11, $00   ; dy -48 dx -8 tile 17 attr $00
    db $d0, $00, $12, $00   ; dy -48 dx +0 tile 18 attr $00
    db $d0, $e0, $0e, $00   ; dy -48 dx -32 tile 14 attr $00
    db $d0, $e8, $0f, $00   ; dy -48 dx -24 tile 15 attr $00
    db $d8, $e8, $19, $00   ; dy -40 dx -24 tile 25 attr $00
    db $d8, $f0, $1a, $00   ; dy -40 dx -16 tile 26 attr $00
    db $d8, $f8, $1b, $00   ; dy -40 dx -8 tile 27 attr $00
    db $e0, $f0, $15, $00   ; dy -32 dx -16 tile 21 attr $00
    db $d8, $00, $14, $00   ; dy -40 dx +0 tile 20 attr $00
    db $e0, $f8, $1a, $00   ; dy -32 dx -8 tile 26 attr $00
    db $e0, $00, $1b, $00   ; dy -32 dx +0 tile 27 attr $00
    db $f0, $e0, $19, $00   ; dy -16 dx -32 tile 25 attr $00
    db $f0, $e8, $1a, $00   ; dy -16 dx -24 tile 26 attr $00
    db $f0, $f8, $0f, $00   ; dy -16 dx -8 tile 15 attr $00
    db $f0, $f0, $1b, $00   ; dy -16 dx -16 tile 27 attr $00
    db $d0, $08, $09, $00   ; dy -48 dx +8 tile 9 attr $00
    db $f8, $d0, $19, $00   ; dy -8 dx -48 tile 25 attr $00
    db $f8, $d8, $1a, $00   ; dy -8 dx -40 tile 26 attr $00
    db $f8, $e8, $1a, $60   ; dy -8 dx -24 tile 26 attr $60
    db $f8, $f0, $08, $00   ; dy -8 dx -16 tile 8 attr $00
    db $f8, $f8, $09, $00   ; dy -8 dx -8 tile 9 attr $00
    db $f0, $00, $10, $00   ; dy -16 dx +0 tile 16 attr $00
    db $f0, $08, $11, $00   ; dy -16 dx +8 tile 17 attr $00
    db $f8, $c0, $21, $20   ; dy -8 dx -64 tile 33 attr $20
    db $f8, $08, $20, $00   ; dy -8 dx +8 tile 32 attr $00
    db $d0, $20, $1c, $00   ; dy -48 dx +32 tile 28 attr $00
    db $80
Anim_0b_F05:   ; $678a 39 sprites
    db $e8, $f8, $0b, $00   ; dy -24 dx -8 tile 11 attr $00
    db $e8, $00, $0c, $00   ; dy -24 dx +0 tile 12 attr $00
    db $e8, $08, $0d, $00   ; dy -24 dx +8 tile 13 attr $00
    db $e0, $d8, $04, $00   ; dy -32 dx -40 tile 4 attr $00
    db $d8, $f0, $11, $00   ; dy -40 dx -16 tile 17 attr $00
    db $d8, $f8, $12, $00   ; dy -40 dx -8 tile 18 attr $00
    db $e0, $e0, $0c, $00   ; dy -32 dx -32 tile 12 attr $00
    db $e0, $e8, $14, $00   ; dy -32 dx -24 tile 20 attr $00
    db $e8, $f0, $14, $00   ; dy -24 dx -16 tile 20 attr $00
    db $d8, $d8, $15, $00   ; dy -40 dx -40 tile 21 attr $00
    db $d8, $e0, $16, $00   ; dy -40 dx -32 tile 22 attr $00
    db $d8, $e8, $17, $00   ; dy -40 dx -24 tile 23 attr $00
    db $f8, $e8, $0c, $00   ; dy -8 dx -24 tile 12 attr $00
    db $f8, $f0, $0d, $00   ; dy -8 dx -16 tile 13 attr $00
    db $f0, $d8, $05, $00   ; dy -16 dx -40 tile 5 attr $00
    db $f0, $e0, $06, $00   ; dy -16 dx -32 tile 6 attr $00
    db $f0, $e8, $07, $00   ; dy -16 dx -24 tile 7 attr $00
    db $f0, $f0, $14, $00   ; dy -16 dx -16 tile 20 attr $00
    db $f0, $f8, $0f, $00   ; dy -16 dx -8 tile 15 attr $00
    db $f8, $f8, $17, $00   ; dy -8 dx -8 tile 23 attr $00
    db $f0, $00, $17, $00   ; dy -16 dx +0 tile 23 attr $00
    db $e0, $f0, $06, $00   ; dy -32 dx -16 tile 6 attr $00
    db $e0, $f8, $07, $00   ; dy -32 dx -8 tile 7 attr $00
    db $e0, $00, $08, $00   ; dy -32 dx +0 tile 8 attr $00
    db $e0, $08, $09, $00   ; dy -32 dx +8 tile 9 attr $00
    db $e8, $e0, $15, $00   ; dy -24 dx -32 tile 21 attr $00
    db $e8, $e8, $16, $00   ; dy -24 dx -24 tile 22 attr $00
    db $f0, $c8, $15, $00   ; dy -16 dx -56 tile 21 attr $00
    db $f0, $d0, $16, $00   ; dy -16 dx -48 tile 22 attr $00
    db $d8, $00, $09, $00   ; dy -40 dx +0 tile 9 attr $00
    db $f8, $d8, $1a, $00   ; dy -8 dx -40 tile 26 attr $00
    db $f8, $e0, $1b, $00   ; dy -8 dx -32 tile 27 attr $00
    db $f8, $10, $20, $00   ; dy -8 dx +16 tile 32 attr $00
    db $f8, $08, $21, $00   ; dy -8 dx +8 tile 33 attr $00
    db $f8, $c8, $21, $20   ; dy -8 dx -56 tile 33 attr $20
    db $f0, $18, $1d, $00   ; dy -16 dx +24 tile 29 attr $00
    db $f8, $c0, $13, $00   ; dy -8 dx -64 tile 19 attr $00
    db $f8, $d0, $1c, $00   ; dy -8 dx -48 tile 28 attr $00
    db $e8, $c0, $1c, $00   ; dy -24 dx -64 tile 28 attr $00
    db $80
Anim_0b_F06:   ; $6827 40 sprites
    db $d0, $e8, $05, $00   ; dy -48 dx -24 tile 5 attr $00
    db $e0, $dc, $0b, $00   ; dy -32 dx -36 tile 11 attr $00
    db $e0, $e4, $0c, $00   ; dy -32 dx -28 tile 12 attr $00
    db $e0, $ec, $0d, $00   ; dy -32 dx -20 tile 13 attr $00
    db $d0, $f0, $06, $00   ; dy -48 dx -16 tile 6 attr $00
    db $d0, $f8, $08, $00   ; dy -48 dx -8 tile 8 attr $00
    db $d0, $e0, $14, $00   ; dy -48 dx -32 tile 20 attr $00
    db $d0, $c0, $15, $00   ; dy -48 dx -64 tile 21 attr $00
    db $d0, $c8, $16, $00   ; dy -48 dx -56 tile 22 attr $00
    db $d0, $d0, $17, $00   ; dy -48 dx -48 tile 23 attr $00
    db $d0, $d8, $0e, $00   ; dy -48 dx -40 tile 14 attr $00
    db $d8, $c8, $19, $00   ; dy -40 dx -56 tile 25 attr $00
    db $d8, $d0, $1a, $00   ; dy -40 dx -48 tile 26 attr $00
    db $d8, $d8, $14, $00   ; dy -40 dx -40 tile 20 attr $00
    db $e0, $c4, $19, $00   ; dy -32 dx -60 tile 25 attr $00
    db $e0, $cc, $1a, $00   ; dy -32 dx -52 tile 26 attr $00
    db $e0, $d4, $0d, $00   ; dy -32 dx -44 tile 13 attr $00
    db $d8, $e8, $07, $00   ; dy -40 dx -24 tile 7 attr $00
    db $d8, $f0, $08, $00   ; dy -40 dx -16 tile 8 attr $00
    db $d8, $f8, $09, $00   ; dy -40 dx -8 tile 9 attr $00
    db $d8, $e0, $16, $00   ; dy -40 dx -32 tile 22 attr $00
    db $d0, $00, $09, $00   ; dy -48 dx +0 tile 9 attr $00
    db $e8, $d4, $15, $00   ; dy -24 dx -44 tile 21 attr $00
    db $e8, $dc, $16, $00   ; dy -24 dx -36 tile 22 attr $00
    db $e8, $e4, $17, $00   ; dy -24 dx -28 tile 23 attr $00
    db $e8, $ec, $12, $00   ; dy -24 dx -20 tile 18 attr $00
    db $f0, $e8, $15, $00   ; dy -16 dx -24 tile 21 attr $00
    db $f0, $f0, $16, $00   ; dy -16 dx -16 tile 22 attr $00
    db $f0, $f8, $17, $00   ; dy -16 dx -8 tile 23 attr $00
    db $f8, $f0, $05, $00   ; dy -8 dx -16 tile 5 attr $00
    db $e8, $f4, $09, $00   ; dy -24 dx -12 tile 9 attr $00
    db $f8, $d8, $15, $00   ; dy -8 dx -40 tile 21 attr $00
    db $f8, $e0, $16, $00   ; dy -8 dx -32 tile 22 attr $00
    db $f8, $e8, $17, $00   ; dy -8 dx -24 tile 23 attr $00
    db $f8, $f8, $10, $00   ; dy -8 dx -8 tile 16 attr $00
    db $f8, $00, $11, $00   ; dy -8 dx +0 tile 17 attr $00
    db $f8, $08, $12, $00   ; dy -8 dx +8 tile 18 attr $00
    db $f8, $c8, $20, $20   ; dy -8 dx -56 tile 32 attr $20
    db $e0, $28, $1c, $00   ; dy -32 dx +40 tile 28 attr $00
    db $f8, $18, $20, $00   ; dy -8 dx +24 tile 32 attr $00
    db $80
Anim_0b_F07:   ; $68c8 40 sprites
    db $f8, $f8, $0e, $00   ; dy -8 dx -8 tile 14 attr $00
    db $e0, $20, $0b, $00   ; dy -32 dx +32 tile 11 attr $00
    db $e0, $28, $0c, $00   ; dy -32 dx +40 tile 12 attr $00
    db $e0, $30, $0d, $00   ; dy -32 dx +48 tile 13 attr $00
    db $d8, $20, $05, $00   ; dy -40 dx +32 tile 5 attr $00
    db $d8, $28, $06, $00   ; dy -40 dx +40 tile 6 attr $00
    db $d8, $30, $08, $00   ; dy -40 dx +48 tile 8 attr $00
    db $da, $38, $11, $00   ; dy -38 dx +56 tile 17 attr $00
    db $da, $40, $12, $00   ; dy -38 dx +64 tile 18 attr $00
    db $e8, $10, $0a, $00   ; dy -24 dx +16 tile 10 attr $00
    db $e8, $18, $0b, $00   ; dy -24 dx +24 tile 11 attr $00
    db $e8, $20, $0c, $00   ; dy -24 dx +32 tile 12 attr $00
    db $e8, $28, $0d, $00   ; dy -24 dx +40 tile 13 attr $00
    db $d0, $08, $10, $00   ; dy -48 dx +8 tile 16 attr $00
    db $d0, $10, $11, $00   ; dy -48 dx +16 tile 17 attr $00
    db $d0, $18, $12, $00   ; dy -48 dx +24 tile 18 attr $00
    db $d0, $f8, $0e, $00   ; dy -48 dx -8 tile 14 attr $00
    db $d0, $00, $0f, $00   ; dy -48 dx +0 tile 15 attr $00
    db $d8, $00, $19, $00   ; dy -40 dx +0 tile 25 attr $00
    db $d8, $08, $1a, $00   ; dy -40 dx +8 tile 26 attr $00
    db $d8, $10, $1b, $00   ; dy -40 dx +16 tile 27 attr $00
    db $e0, $08, $15, $00   ; dy -32 dx +8 tile 21 attr $00
    db $d8, $18, $14, $00   ; dy -40 dx +24 tile 20 attr $00
    db $e0, $10, $1a, $00   ; dy -32 dx +16 tile 26 attr $00
    db $e0, $18, $1b, $00   ; dy -32 dx +24 tile 27 attr $00
    db $f0, $f8, $19, $00   ; dy -16 dx -8 tile 25 attr $00
    db $f0, $00, $1a, $00   ; dy -16 dx +0 tile 26 attr $00
    db $f0, $18, $10, $00   ; dy -16 dx +24 tile 16 attr $00
    db $f0, $20, $11, $00   ; dy -16 dx +32 tile 17 attr $00
    db $f0, $10, $0f, $00   ; dy -16 dx +16 tile 15 attr $00
    db $f0, $08, $1b, $00   ; dy -16 dx +8 tile 27 attr $00
    db $d0, $20, $09, $00   ; dy -48 dx +32 tile 9 attr $00
    db $f8, $e8, $19, $00   ; dy -8 dx -24 tile 25 attr $00
    db $f8, $f0, $1a, $00   ; dy -8 dx -16 tile 26 attr $00
    db $f8, $00, $1a, $60   ; dy -8 dx +0 tile 26 attr $60
    db $f8, $08, $08, $00   ; dy -8 dx +8 tile 8 attr $00
    db $f8, $10, $09, $00   ; dy -8 dx +16 tile 9 attr $00
    db $f8, $20, $21, $00   ; dy -8 dx +32 tile 33 attr $00
    db $f8, $d8, $21, $20   ; dy -8 dx -40 tile 33 attr $20
    db $e8, $d0, $1f, $00   ; dy -24 dx -48 tile 31 attr $00
    db $80
Anim_0b_F08:   ; $6969 40 sprites
    db $e8, $10, $0b, $00   ; dy -24 dx +16 tile 11 attr $00
    db $e8, $18, $0c, $00   ; dy -24 dx +24 tile 12 attr $00
    db $e8, $20, $0d, $00   ; dy -24 dx +32 tile 13 attr $00
    db $e0, $f0, $04, $00   ; dy -32 dx -16 tile 4 attr $00
    db $d8, $08, $11, $00   ; dy -40 dx +8 tile 17 attr $00
    db $d8, $10, $12, $00   ; dy -40 dx +16 tile 18 attr $00
    db $e0, $f8, $0c, $00   ; dy -32 dx -8 tile 12 attr $00
    db $e0, $00, $14, $00   ; dy -32 dx +0 tile 20 attr $00
    db $e8, $08, $14, $00   ; dy -24 dx +8 tile 20 attr $00
    db $d8, $f0, $15, $00   ; dy -40 dx -16 tile 21 attr $00
    db $d8, $f8, $16, $00   ; dy -40 dx -8 tile 22 attr $00
    db $d8, $00, $17, $00   ; dy -40 dx +0 tile 23 attr $00
    db $f8, $00, $0c, $00   ; dy -8 dx +0 tile 12 attr $00
    db $f8, $08, $0d, $00   ; dy -8 dx +8 tile 13 attr $00
    db $f0, $f0, $05, $00   ; dy -16 dx -16 tile 5 attr $00
    db $f0, $f8, $06, $00   ; dy -16 dx -8 tile 6 attr $00
    db $f0, $00, $07, $00   ; dy -16 dx +0 tile 7 attr $00
    db $f0, $08, $14, $00   ; dy -16 dx +8 tile 20 attr $00
    db $f0, $10, $0f, $00   ; dy -16 dx +16 tile 15 attr $00
    db $f8, $10, $17, $00   ; dy -8 dx +16 tile 23 attr $00
    db $f0, $18, $17, $00   ; dy -16 dx +24 tile 23 attr $00
    db $e0, $08, $06, $00   ; dy -32 dx +8 tile 6 attr $00
    db $e0, $10, $07, $00   ; dy -32 dx +16 tile 7 attr $00
    db $e0, $18, $08, $00   ; dy -32 dx +24 tile 8 attr $00
    db $e0, $20, $09, $00   ; dy -32 dx +32 tile 9 attr $00
    db $e8, $f8, $15, $00   ; dy -24 dx -8 tile 21 attr $00
    db $e8, $00, $16, $00   ; dy -24 dx +0 tile 22 attr $00
    db $f0, $e0, $15, $00   ; dy -16 dx -32 tile 21 attr $00
    db $f0, $e8, $16, $00   ; dy -16 dx -24 tile 22 attr $00
    db $d8, $18, $09, $00   ; dy -40 dx +24 tile 9 attr $00
    db $f8, $f0, $1a, $00   ; dy -8 dx -16 tile 26 attr $00
    db $f8, $f8, $1b, $00   ; dy -8 dx -8 tile 27 attr $00
    db $f8, $28, $20, $00   ; dy -8 dx +40 tile 32 attr $00
    db $f8, $d8, $20, $20   ; dy -8 dx -40 tile 32 attr $20
    db $f8, $e0, $13, $00   ; dy -8 dx -32 tile 19 attr $00
    db $f8, $20, $13, $20   ; dy -8 dx +32 tile 19 attr $20
    db $d0, $38, $1d, $00   ; dy -48 dx +56 tile 29 attr $00
    db $f8, $d0, $1f, $00   ; dy -8 dx -48 tile 31 attr $00
    db $f0, $30, $1e, $20   ; dy -16 dx +48 tile 30 attr $20
    db $d8, $c8, $1e, $00   ; dy -40 dx -56 tile 30 attr $00
    db $80
Anim_0b_F09:   ; $6a0a 40 sprites
    db $d0, $f8, $05, $00   ; dy -48 dx -8 tile 5 attr $00
    db $e0, $ec, $0b, $00   ; dy -32 dx -20 tile 11 attr $00
    db $e0, $f4, $0c, $00   ; dy -32 dx -12 tile 12 attr $00
    db $e0, $fc, $0d, $00   ; dy -32 dx -4 tile 13 attr $00
    db $d0, $00, $06, $00   ; dy -48 dx +0 tile 6 attr $00
    db $d0, $08, $08, $00   ; dy -48 dx +8 tile 8 attr $00
    db $d0, $f0, $14, $00   ; dy -48 dx -16 tile 20 attr $00
    db $d0, $d0, $15, $00   ; dy -48 dx -48 tile 21 attr $00
    db $d0, $d8, $16, $00   ; dy -48 dx -40 tile 22 attr $00
    db $d0, $e0, $17, $00   ; dy -48 dx -32 tile 23 attr $00
    db $d0, $e8, $0e, $00   ; dy -48 dx -24 tile 14 attr $00
    db $d8, $d8, $19, $00   ; dy -40 dx -40 tile 25 attr $00
    db $d8, $e0, $1a, $00   ; dy -40 dx -32 tile 26 attr $00
    db $d8, $e8, $14, $00   ; dy -40 dx -24 tile 20 attr $00
    db $e0, $d4, $19, $00   ; dy -32 dx -44 tile 25 attr $00
    db $e0, $dc, $1a, $00   ; dy -32 dx -36 tile 26 attr $00
    db $e0, $e4, $0d, $00   ; dy -32 dx -28 tile 13 attr $00
    db $d8, $f8, $07, $00   ; dy -40 dx -8 tile 7 attr $00
    db $d8, $00, $08, $00   ; dy -40 dx +0 tile 8 attr $00
    db $d8, $08, $09, $00   ; dy -40 dx +8 tile 9 attr $00
    db $d8, $f0, $16, $00   ; dy -40 dx -16 tile 22 attr $00
    db $d0, $10, $09, $00   ; dy -48 dx +16 tile 9 attr $00
    db $e8, $e4, $15, $00   ; dy -24 dx -28 tile 21 attr $00
    db $e8, $ec, $16, $00   ; dy -24 dx -20 tile 22 attr $00
    db $e8, $f4, $17, $00   ; dy -24 dx -12 tile 23 attr $00
    db $e8, $fc, $12, $00   ; dy -24 dx -4 tile 18 attr $00
    db $f0, $f8, $15, $00   ; dy -16 dx -8 tile 21 attr $00
    db $f0, $00, $16, $00   ; dy -16 dx +0 tile 22 attr $00
    db $f0, $08, $17, $00   ; dy -16 dx +8 tile 23 attr $00
    db $f8, $00, $05, $00   ; dy -8 dx +0 tile 5 attr $00
    db $e8, $04, $09, $00   ; dy -24 dx +4 tile 9 attr $00
    db $f8, $e8, $15, $00   ; dy -8 dx -24 tile 21 attr $00
    db $f8, $f0, $16, $00   ; dy -8 dx -16 tile 22 attr $00
    db $f8, $f8, $17, $00   ; dy -8 dx -8 tile 23 attr $00
    db $f8, $08, $10, $00   ; dy -8 dx +8 tile 16 attr $00
    db $f8, $10, $11, $00   ; dy -8 dx +16 tile 17 attr $00
    db $f8, $18, $12, $00   ; dy -8 dx +24 tile 18 attr $00
    db $f8, $28, $21, $00   ; dy -8 dx +40 tile 33 attr $00
    db $f8, $d8, $21, $20   ; dy -8 dx -40 tile 33 attr $20
    db $e8, $d0, $1f, $00   ; dy -24 dx -48 tile 31 attr $00
    db $80
Anim_0b_F10:   ; $6aab 40 sprites
    db $f8, $00, $0e, $00   ; dy -8 dx +0 tile 14 attr $00
    db $e0, $28, $0b, $00   ; dy -32 dx +40 tile 11 attr $00
    db $e0, $30, $0c, $00   ; dy -32 dx +48 tile 12 attr $00
    db $e0, $38, $0d, $00   ; dy -32 dx +56 tile 13 attr $00
    db $d8, $28, $05, $00   ; dy -40 dx +40 tile 5 attr $00
    db $d8, $30, $06, $00   ; dy -40 dx +48 tile 6 attr $00
    db $d8, $38, $08, $00   ; dy -40 dx +56 tile 8 attr $00
    db $da, $40, $11, $00   ; dy -38 dx +64 tile 17 attr $00
    db $da, $48, $12, $00   ; dy -38 dx +72 tile 18 attr $00
    db $e8, $18, $0a, $00   ; dy -24 dx +24 tile 10 attr $00
    db $e8, $20, $0b, $00   ; dy -24 dx +32 tile 11 attr $00
    db $e8, $28, $0c, $00   ; dy -24 dx +40 tile 12 attr $00
    db $e8, $30, $0d, $00   ; dy -24 dx +48 tile 13 attr $00
    db $d0, $10, $10, $00   ; dy -48 dx +16 tile 16 attr $00
    db $d0, $18, $11, $00   ; dy -48 dx +24 tile 17 attr $00
    db $d0, $20, $12, $00   ; dy -48 dx +32 tile 18 attr $00
    db $d0, $00, $0e, $00   ; dy -48 dx +0 tile 14 attr $00
    db $d0, $08, $0f, $00   ; dy -48 dx +8 tile 15 attr $00
    db $d8, $08, $19, $00   ; dy -40 dx +8 tile 25 attr $00
    db $d8, $10, $1a, $00   ; dy -40 dx +16 tile 26 attr $00
    db $d8, $18, $1b, $00   ; dy -40 dx +24 tile 27 attr $00
    db $e0, $10, $15, $00   ; dy -32 dx +16 tile 21 attr $00
    db $d8, $20, $14, $00   ; dy -40 dx +32 tile 20 attr $00
    db $e0, $18, $1a, $00   ; dy -32 dx +24 tile 26 attr $00
    db $e0, $20, $1b, $00   ; dy -32 dx +32 tile 27 attr $00
    db $f0, $00, $19, $00   ; dy -16 dx +0 tile 25 attr $00
    db $f0, $08, $1a, $00   ; dy -16 dx +8 tile 26 attr $00
    db $f0, $20, $10, $00   ; dy -16 dx +32 tile 16 attr $00
    db $f0, $28, $11, $00   ; dy -16 dx +40 tile 17 attr $00
    db $f0, $18, $0f, $00   ; dy -16 dx +24 tile 15 attr $00
    db $f0, $10, $1b, $00   ; dy -16 dx +16 tile 27 attr $00
    db $d0, $28, $09, $00   ; dy -48 dx +40 tile 9 attr $00
    db $f8, $f0, $19, $00   ; dy -8 dx -16 tile 25 attr $00
    db $f8, $f8, $1a, $00   ; dy -8 dx -8 tile 26 attr $00
    db $f8, $08, $1a, $60   ; dy -8 dx +8 tile 26 attr $60
    db $f8, $10, $08, $00   ; dy -8 dx +16 tile 8 attr $00
    db $f8, $18, $09, $00   ; dy -8 dx +24 tile 9 attr $00
    db $f8, $28, $20, $00   ; dy -8 dx +40 tile 32 attr $00
    db $f8, $e0, $20, $20   ; dy -8 dx -32 tile 32 attr $20
    db $e2, $40, $1c, $00   ; dy -30 dx +64 tile 28 attr $00
    db $80
Anim_0b_F11:   ; $6b4c 40 sprites
    db $e8, $10, $0b, $00   ; dy -24 dx +16 tile 11 attr $00
    db $e8, $18, $0c, $00   ; dy -24 dx +24 tile 12 attr $00
    db $e8, $20, $0d, $00   ; dy -24 dx +32 tile 13 attr $00
    db $e0, $f0, $04, $00   ; dy -32 dx -16 tile 4 attr $00
    db $d8, $08, $11, $00   ; dy -40 dx +8 tile 17 attr $00
    db $d8, $10, $12, $00   ; dy -40 dx +16 tile 18 attr $00
    db $e0, $f8, $0c, $00   ; dy -32 dx -8 tile 12 attr $00
    db $e0, $00, $14, $00   ; dy -32 dx +0 tile 20 attr $00
    db $e8, $08, $14, $00   ; dy -24 dx +8 tile 20 attr $00
    db $d8, $f0, $15, $00   ; dy -40 dx -16 tile 21 attr $00
    db $d8, $f8, $16, $00   ; dy -40 dx -8 tile 22 attr $00
    db $d8, $00, $17, $00   ; dy -40 dx +0 tile 23 attr $00
    db $f8, $00, $0c, $00   ; dy -8 dx +0 tile 12 attr $00
    db $f8, $08, $0d, $00   ; dy -8 dx +8 tile 13 attr $00
    db $f0, $f0, $05, $00   ; dy -16 dx -16 tile 5 attr $00
    db $f0, $f8, $06, $00   ; dy -16 dx -8 tile 6 attr $00
    db $f0, $00, $07, $00   ; dy -16 dx +0 tile 7 attr $00
    db $f0, $08, $14, $00   ; dy -16 dx +8 tile 20 attr $00
    db $f0, $10, $0f, $00   ; dy -16 dx +16 tile 15 attr $00
    db $f8, $10, $17, $00   ; dy -8 dx +16 tile 23 attr $00
    db $f0, $18, $17, $00   ; dy -16 dx +24 tile 23 attr $00
    db $e0, $08, $06, $00   ; dy -32 dx +8 tile 6 attr $00
    db $e0, $10, $07, $00   ; dy -32 dx +16 tile 7 attr $00
    db $e0, $18, $08, $00   ; dy -32 dx +24 tile 8 attr $00
    db $e0, $20, $09, $00   ; dy -32 dx +32 tile 9 attr $00
    db $e8, $f8, $15, $00   ; dy -24 dx -8 tile 21 attr $00
    db $e8, $00, $16, $00   ; dy -24 dx +0 tile 22 attr $00
    db $f0, $e0, $15, $00   ; dy -16 dx -32 tile 21 attr $00
    db $f0, $e8, $16, $00   ; dy -16 dx -24 tile 22 attr $00
    db $d8, $18, $09, $00   ; dy -40 dx +24 tile 9 attr $00
    db $f8, $f0, $1a, $00   ; dy -8 dx -16 tile 26 attr $00
    db $f8, $f8, $1b, $00   ; dy -8 dx -8 tile 27 attr $00
    db $f8, $20, $21, $00   ; dy -8 dx +32 tile 33 attr $00
    db $f8, $d8, $21, $20   ; dy -8 dx -40 tile 33 attr $20
    db $f8, $28, $13, $00   ; dy -8 dx +40 tile 19 attr $00
    db $f8, $d0, $13, $20   ; dy -8 dx -48 tile 19 attr $20
    db $f0, $30, $1d, $00   ; dy -16 dx +48 tile 29 attr $00
    db $f8, $c8, $1c, $00   ; dy -8 dx -56 tile 28 attr $00
    db $e0, $e8, $1e, $00   ; dy -32 dx -24 tile 30 attr $00
    db $e0, $28, $1f, $00   ; dy -32 dx +40 tile 31 attr $00
    db $80
Anim_0b_F12:   ; $6bed 40 sprites
    db $d0, $f8, $05, $00   ; dy -48 dx -8 tile 5 attr $00
    db $e0, $ec, $0b, $00   ; dy -32 dx -20 tile 11 attr $00
    db $e0, $f4, $0c, $00   ; dy -32 dx -12 tile 12 attr $00
    db $e0, $fc, $0d, $00   ; dy -32 dx -4 tile 13 attr $00
    db $d0, $00, $06, $00   ; dy -48 dx +0 tile 6 attr $00
    db $d0, $08, $08, $00   ; dy -48 dx +8 tile 8 attr $00
    db $d0, $f0, $14, $00   ; dy -48 dx -16 tile 20 attr $00
    db $d0, $d0, $15, $00   ; dy -48 dx -48 tile 21 attr $00
    db $d0, $d8, $16, $00   ; dy -48 dx -40 tile 22 attr $00
    db $d0, $e0, $17, $00   ; dy -48 dx -32 tile 23 attr $00
    db $d0, $e8, $0e, $00   ; dy -48 dx -24 tile 14 attr $00
    db $d8, $d8, $19, $00   ; dy -40 dx -40 tile 25 attr $00
    db $d8, $e0, $1a, $00   ; dy -40 dx -32 tile 26 attr $00
    db $d8, $e8, $14, $00   ; dy -40 dx -24 tile 20 attr $00
    db $e0, $d4, $19, $00   ; dy -32 dx -44 tile 25 attr $00
    db $e0, $dc, $1a, $00   ; dy -32 dx -36 tile 26 attr $00
    db $e0, $e4, $0d, $00   ; dy -32 dx -28 tile 13 attr $00
    db $d8, $f8, $07, $00   ; dy -40 dx -8 tile 7 attr $00
    db $d8, $00, $08, $00   ; dy -40 dx +0 tile 8 attr $00
    db $d8, $08, $09, $00   ; dy -40 dx +8 tile 9 attr $00
    db $d8, $f0, $16, $00   ; dy -40 dx -16 tile 22 attr $00
    db $d0, $10, $09, $00   ; dy -48 dx +16 tile 9 attr $00
    db $e8, $e4, $15, $00   ; dy -24 dx -28 tile 21 attr $00
    db $e8, $ec, $16, $00   ; dy -24 dx -20 tile 22 attr $00
    db $e8, $f4, $17, $00   ; dy -24 dx -12 tile 23 attr $00
    db $e8, $fc, $12, $00   ; dy -24 dx -4 tile 18 attr $00
    db $f0, $f8, $15, $00   ; dy -16 dx -8 tile 21 attr $00
    db $f0, $00, $16, $00   ; dy -16 dx +0 tile 22 attr $00
    db $f0, $08, $17, $00   ; dy -16 dx +8 tile 23 attr $00
    db $f8, $00, $05, $00   ; dy -8 dx +0 tile 5 attr $00
    db $e8, $04, $09, $00   ; dy -24 dx +4 tile 9 attr $00
    db $f8, $e8, $15, $00   ; dy -8 dx -24 tile 21 attr $00
    db $f8, $f0, $16, $00   ; dy -8 dx -16 tile 22 attr $00
    db $f8, $f8, $17, $00   ; dy -8 dx -8 tile 23 attr $00
    db $f8, $08, $10, $00   ; dy -8 dx +8 tile 16 attr $00
    db $f8, $10, $11, $00   ; dy -8 dx +16 tile 17 attr $00
    db $f8, $18, $12, $00   ; dy -8 dx +24 tile 18 attr $00
    db $f8, $28, $20, $00   ; dy -8 dx +40 tile 32 attr $00
    db $f8, $d8, $20, $20   ; dy -8 dx -40 tile 32 attr $20
    db $e8, $40, $1d, $00   ; dy -24 dx +64 tile 29 attr $00
    db $80
Anim_0b_F13:   ; $6c8e 40 sprites
    db $f8, $f8, $0e, $00   ; dy -8 dx -8 tile 14 attr $00
    db $e0, $20, $0b, $00   ; dy -32 dx +32 tile 11 attr $00
    db $e0, $28, $0c, $00   ; dy -32 dx +40 tile 12 attr $00
    db $e0, $30, $0d, $00   ; dy -32 dx +48 tile 13 attr $00
    db $d8, $20, $05, $00   ; dy -40 dx +32 tile 5 attr $00
    db $d8, $28, $06, $00   ; dy -40 dx +40 tile 6 attr $00
    db $d8, $30, $08, $00   ; dy -40 dx +48 tile 8 attr $00
    db $da, $38, $11, $00   ; dy -38 dx +56 tile 17 attr $00
    db $da, $40, $12, $00   ; dy -38 dx +64 tile 18 attr $00
    db $e8, $10, $0a, $00   ; dy -24 dx +16 tile 10 attr $00
    db $e8, $18, $0b, $00   ; dy -24 dx +24 tile 11 attr $00
    db $e8, $20, $0c, $00   ; dy -24 dx +32 tile 12 attr $00
    db $e8, $28, $0d, $00   ; dy -24 dx +40 tile 13 attr $00
    db $d0, $08, $10, $00   ; dy -48 dx +8 tile 16 attr $00
    db $d0, $10, $11, $00   ; dy -48 dx +16 tile 17 attr $00
    db $d0, $18, $12, $00   ; dy -48 dx +24 tile 18 attr $00
    db $d0, $f8, $0e, $00   ; dy -48 dx -8 tile 14 attr $00
    db $d0, $00, $0f, $00   ; dy -48 dx +0 tile 15 attr $00
    db $d8, $00, $19, $00   ; dy -40 dx +0 tile 25 attr $00
    db $d8, $08, $1a, $00   ; dy -40 dx +8 tile 26 attr $00
    db $d8, $10, $1b, $00   ; dy -40 dx +16 tile 27 attr $00
    db $e0, $08, $15, $00   ; dy -32 dx +8 tile 21 attr $00
    db $d8, $18, $14, $00   ; dy -40 dx +24 tile 20 attr $00
    db $e0, $10, $1a, $00   ; dy -32 dx +16 tile 26 attr $00
    db $e0, $18, $1b, $00   ; dy -32 dx +24 tile 27 attr $00
    db $f0, $f8, $19, $00   ; dy -16 dx -8 tile 25 attr $00
    db $f0, $00, $1a, $00   ; dy -16 dx +0 tile 26 attr $00
    db $f0, $18, $10, $00   ; dy -16 dx +24 tile 16 attr $00
    db $f0, $20, $11, $00   ; dy -16 dx +32 tile 17 attr $00
    db $f0, $10, $0f, $00   ; dy -16 dx +16 tile 15 attr $00
    db $f0, $08, $1b, $00   ; dy -16 dx +8 tile 27 attr $00
    db $d0, $20, $09, $00   ; dy -48 dx +32 tile 9 attr $00
    db $f8, $e8, $19, $00   ; dy -8 dx -24 tile 25 attr $00
    db $f8, $f0, $1a, $00   ; dy -8 dx -16 tile 26 attr $00
    db $f8, $00, $1a, $60   ; dy -8 dx +0 tile 26 attr $60
    db $f8, $08, $08, $00   ; dy -8 dx +8 tile 8 attr $00
    db $f8, $10, $09, $00   ; dy -8 dx +16 tile 9 attr $00
    db $f8, $d8, $13, $00   ; dy -8 dx -40 tile 19 attr $00
    db $f8, $20, $13, $20   ; dy -8 dx +32 tile 19 attr $20
    db $d0, $e0, $1f, $00   ; dy -48 dx -32 tile 31 attr $00
    db $80
Anim_0b_F14:   ; $6d2f 40 sprites
    db $e8, $00, $0b, $00   ; dy -24 dx +0 tile 11 attr $00
    db $e8, $08, $0c, $00   ; dy -24 dx +8 tile 12 attr $00
    db $e8, $10, $0d, $00   ; dy -24 dx +16 tile 13 attr $00
    db $e0, $e0, $04, $00   ; dy -32 dx -32 tile 4 attr $00
    db $d8, $f8, $11, $00   ; dy -40 dx -8 tile 17 attr $00
    db $d8, $00, $12, $00   ; dy -40 dx +0 tile 18 attr $00
    db $e0, $e8, $0c, $00   ; dy -32 dx -24 tile 12 attr $00
    db $e0, $f0, $14, $00   ; dy -32 dx -16 tile 20 attr $00
    db $e8, $f8, $14, $00   ; dy -24 dx -8 tile 20 attr $00
    db $d8, $e0, $15, $00   ; dy -40 dx -32 tile 21 attr $00
    db $d8, $e8, $16, $00   ; dy -40 dx -24 tile 22 attr $00
    db $d8, $f0, $17, $00   ; dy -40 dx -16 tile 23 attr $00
    db $f8, $f0, $0c, $00   ; dy -8 dx -16 tile 12 attr $00
    db $f8, $f8, $0d, $00   ; dy -8 dx -8 tile 13 attr $00
    db $f0, $e0, $05, $00   ; dy -16 dx -32 tile 5 attr $00
    db $f0, $e8, $06, $00   ; dy -16 dx -24 tile 6 attr $00
    db $f0, $f0, $07, $00   ; dy -16 dx -16 tile 7 attr $00
    db $f0, $f8, $14, $00   ; dy -16 dx -8 tile 20 attr $00
    db $f0, $00, $0f, $00   ; dy -16 dx +0 tile 15 attr $00
    db $f8, $00, $17, $00   ; dy -8 dx +0 tile 23 attr $00
    db $f0, $08, $17, $00   ; dy -16 dx +8 tile 23 attr $00
    db $e0, $f8, $06, $00   ; dy -32 dx -8 tile 6 attr $00
    db $e0, $00, $07, $00   ; dy -32 dx +0 tile 7 attr $00
    db $e0, $08, $08, $00   ; dy -32 dx +8 tile 8 attr $00
    db $e0, $10, $09, $00   ; dy -32 dx +16 tile 9 attr $00
    db $e8, $e8, $15, $00   ; dy -24 dx -24 tile 21 attr $00
    db $e8, $f0, $16, $00   ; dy -24 dx -16 tile 22 attr $00
    db $f0, $d0, $15, $00   ; dy -16 dx -48 tile 21 attr $00
    db $f0, $d8, $16, $00   ; dy -16 dx -40 tile 22 attr $00
    db $d8, $08, $09, $00   ; dy -40 dx +8 tile 9 attr $00
    db $f8, $e0, $1a, $00   ; dy -8 dx -32 tile 26 attr $00
    db $f8, $e8, $1b, $00   ; dy -8 dx -24 tile 27 attr $00
    db $f8, $10, $20, $00   ; dy -8 dx +16 tile 32 attr $00
    db $f8, $18, $21, $00   ; dy -8 dx +24 tile 33 attr $00
    db $f8, $c8, $20, $20   ; dy -8 dx -56 tile 32 attr $20
    db $f8, $c0, $21, $20   ; dy -8 dx -64 tile 33 attr $20
    db $f8, $38, $1c, $20   ; dy -8 dx +56 tile 28 attr $20
    db $e8, $d8, $1d, $20   ; dy -24 dx -40 tile 29 attr $20
    db $f0, $18, $1e, $20   ; dy -16 dx +24 tile 30 attr $20
    db $d8, $d0, $1f, $20   ; dy -40 dx -48 tile 31 attr $20
    db $80
Anim_0b_F15:   ; $6dd0 40 sprites
    db $d0, $e8, $05, $00   ; dy -48 dx -24 tile 5 attr $00
    db $e0, $dc, $0b, $00   ; dy -32 dx -36 tile 11 attr $00
    db $e0, $e4, $0c, $00   ; dy -32 dx -28 tile 12 attr $00
    db $e0, $ec, $0d, $00   ; dy -32 dx -20 tile 13 attr $00
    db $d0, $f0, $06, $00   ; dy -48 dx -16 tile 6 attr $00
    db $d0, $f8, $08, $00   ; dy -48 dx -8 tile 8 attr $00
    db $d0, $e0, $14, $00   ; dy -48 dx -32 tile 20 attr $00
    db $d0, $c0, $15, $00   ; dy -48 dx -64 tile 21 attr $00
    db $d0, $c8, $16, $00   ; dy -48 dx -56 tile 22 attr $00
    db $d0, $d0, $17, $00   ; dy -48 dx -48 tile 23 attr $00
    db $d0, $d8, $0e, $00   ; dy -48 dx -40 tile 14 attr $00
    db $d8, $c8, $19, $00   ; dy -40 dx -56 tile 25 attr $00
    db $d8, $d0, $1a, $00   ; dy -40 dx -48 tile 26 attr $00
    db $d8, $d8, $14, $00   ; dy -40 dx -40 tile 20 attr $00
    db $e0, $c4, $19, $00   ; dy -32 dx -60 tile 25 attr $00
    db $e0, $cc, $1a, $00   ; dy -32 dx -52 tile 26 attr $00
    db $e0, $d4, $0d, $00   ; dy -32 dx -44 tile 13 attr $00
    db $d8, $e8, $07, $00   ; dy -40 dx -24 tile 7 attr $00
    db $d8, $f0, $08, $00   ; dy -40 dx -16 tile 8 attr $00
    db $d8, $f8, $09, $00   ; dy -40 dx -8 tile 9 attr $00
    db $d8, $e0, $16, $00   ; dy -40 dx -32 tile 22 attr $00
    db $d0, $00, $09, $00   ; dy -48 dx +0 tile 9 attr $00
    db $e8, $d4, $15, $00   ; dy -24 dx -44 tile 21 attr $00
    db $e8, $dc, $16, $00   ; dy -24 dx -36 tile 22 attr $00
    db $e8, $e4, $17, $00   ; dy -24 dx -28 tile 23 attr $00
    db $e8, $ec, $12, $00   ; dy -24 dx -20 tile 18 attr $00
    db $f0, $e8, $15, $00   ; dy -16 dx -24 tile 21 attr $00
    db $f0, $f0, $16, $00   ; dy -16 dx -16 tile 22 attr $00
    db $f0, $f8, $17, $00   ; dy -16 dx -8 tile 23 attr $00
    db $f8, $f0, $05, $00   ; dy -8 dx -16 tile 5 attr $00
    db $e8, $f4, $09, $00   ; dy -24 dx -12 tile 9 attr $00
    db $f8, $d8, $15, $00   ; dy -8 dx -40 tile 21 attr $00
    db $f8, $e0, $16, $00   ; dy -8 dx -32 tile 22 attr $00
    db $f8, $e8, $17, $00   ; dy -8 dx -24 tile 23 attr $00
    db $f8, $f8, $10, $00   ; dy -8 dx -8 tile 16 attr $00
    db $f8, $00, $11, $00   ; dy -8 dx +0 tile 17 attr $00
    db $f8, $08, $12, $00   ; dy -8 dx +8 tile 18 attr $00
    db $f8, $c8, $13, $00   ; dy -8 dx -56 tile 19 attr $00
    db $f8, $18, $13, $20   ; dy -8 dx +24 tile 19 attr $20
    db $e8, $30, $1c, $40   ; dy -24 dx +48 tile 28 attr $40
    db $80
Anim_0b_F16:   ; $6e71 40 sprites
    db $f8, $e8, $0e, $00   ; dy -8 dx -24 tile 14 attr $00
    db $e0, $10, $0b, $00   ; dy -32 dx +16 tile 11 attr $00
    db $e0, $18, $0c, $00   ; dy -32 dx +24 tile 12 attr $00
    db $e0, $20, $0d, $00   ; dy -32 dx +32 tile 13 attr $00
    db $d8, $10, $05, $00   ; dy -40 dx +16 tile 5 attr $00
    db $d8, $18, $06, $00   ; dy -40 dx +24 tile 6 attr $00
    db $d8, $20, $08, $00   ; dy -40 dx +32 tile 8 attr $00
    db $da, $28, $11, $00   ; dy -38 dx +40 tile 17 attr $00
    db $da, $30, $12, $00   ; dy -38 dx +48 tile 18 attr $00
    db $e8, $00, $0a, $00   ; dy -24 dx +0 tile 10 attr $00
    db $e8, $08, $0b, $00   ; dy -24 dx +8 tile 11 attr $00
    db $e8, $10, $0c, $00   ; dy -24 dx +16 tile 12 attr $00
    db $e8, $18, $0d, $00   ; dy -24 dx +24 tile 13 attr $00
    db $d0, $f8, $10, $00   ; dy -48 dx -8 tile 16 attr $00
    db $d0, $00, $11, $00   ; dy -48 dx +0 tile 17 attr $00
    db $d0, $08, $12, $00   ; dy -48 dx +8 tile 18 attr $00
    db $d0, $e8, $0e, $00   ; dy -48 dx -24 tile 14 attr $00
    db $d0, $f0, $0f, $00   ; dy -48 dx -16 tile 15 attr $00
    db $d8, $f0, $19, $00   ; dy -40 dx -16 tile 25 attr $00
    db $d8, $f8, $1a, $00   ; dy -40 dx -8 tile 26 attr $00
    db $d8, $00, $1b, $00   ; dy -40 dx +0 tile 27 attr $00
    db $e0, $f8, $15, $00   ; dy -32 dx -8 tile 21 attr $00
    db $d8, $08, $14, $00   ; dy -40 dx +8 tile 20 attr $00
    db $e0, $00, $1a, $00   ; dy -32 dx +0 tile 26 attr $00
    db $e0, $08, $1b, $00   ; dy -32 dx +8 tile 27 attr $00
    db $f0, $e8, $19, $00   ; dy -16 dx -24 tile 25 attr $00
    db $f0, $f0, $1a, $00   ; dy -16 dx -16 tile 26 attr $00
    db $f0, $08, $10, $00   ; dy -16 dx +8 tile 16 attr $00
    db $f0, $10, $11, $00   ; dy -16 dx +16 tile 17 attr $00
    db $f0, $00, $0f, $00   ; dy -16 dx +0 tile 15 attr $00
    db $f0, $f8, $1b, $00   ; dy -16 dx -8 tile 27 attr $00
    db $d0, $10, $09, $00   ; dy -48 dx +16 tile 9 attr $00
    db $f8, $d8, $19, $00   ; dy -8 dx -40 tile 25 attr $00
    db $f8, $e0, $1a, $00   ; dy -8 dx -32 tile 26 attr $00
    db $f8, $f0, $1a, $60   ; dy -8 dx -16 tile 26 attr $60
    db $f8, $f8, $08, $00   ; dy -8 dx -8 tile 8 attr $00
    db $f8, $00, $09, $00   ; dy -8 dx +0 tile 9 attr $00
    db $f8, $10, $21, $00   ; dy -8 dx +16 tile 33 attr $00
    db $f8, $c8, $21, $20   ; dy -8 dx -56 tile 33 attr $20
    db $e8, $48, $1d, $00   ; dy -24 dx +72 tile 29 attr $00
    db $80
Anim_0b_F17:   ; $6f12 40 sprites
    db $e8, $f8, $0b, $00   ; dy -24 dx -8 tile 11 attr $00
    db $e8, $00, $0c, $00   ; dy -24 dx +0 tile 12 attr $00
    db $e8, $08, $0d, $00   ; dy -24 dx +8 tile 13 attr $00
    db $e0, $d8, $04, $00   ; dy -32 dx -40 tile 4 attr $00
    db $d8, $f0, $11, $00   ; dy -40 dx -16 tile 17 attr $00
    db $d8, $f8, $12, $00   ; dy -40 dx -8 tile 18 attr $00
    db $e0, $e0, $0c, $00   ; dy -32 dx -32 tile 12 attr $00
    db $e0, $e8, $14, $00   ; dy -32 dx -24 tile 20 attr $00
    db $e8, $f0, $14, $00   ; dy -24 dx -16 tile 20 attr $00
    db $d8, $d8, $15, $00   ; dy -40 dx -40 tile 21 attr $00
    db $d8, $e0, $16, $00   ; dy -40 dx -32 tile 22 attr $00
    db $d8, $e8, $17, $00   ; dy -40 dx -24 tile 23 attr $00
    db $f8, $e8, $0c, $00   ; dy -8 dx -24 tile 12 attr $00
    db $f8, $f0, $0d, $00   ; dy -8 dx -16 tile 13 attr $00
    db $f0, $d8, $05, $00   ; dy -16 dx -40 tile 5 attr $00
    db $f0, $e0, $06, $00   ; dy -16 dx -32 tile 6 attr $00
    db $f0, $e8, $07, $00   ; dy -16 dx -24 tile 7 attr $00
    db $f0, $f0, $14, $00   ; dy -16 dx -16 tile 20 attr $00
    db $f0, $f8, $0f, $00   ; dy -16 dx -8 tile 15 attr $00
    db $f8, $f8, $17, $00   ; dy -8 dx -8 tile 23 attr $00
    db $f0, $00, $17, $00   ; dy -16 dx +0 tile 23 attr $00
    db $e0, $f0, $06, $00   ; dy -32 dx -16 tile 6 attr $00
    db $e0, $f8, $07, $00   ; dy -32 dx -8 tile 7 attr $00
    db $e0, $00, $08, $00   ; dy -32 dx +0 tile 8 attr $00
    db $e0, $08, $09, $00   ; dy -32 dx +8 tile 9 attr $00
    db $e8, $e0, $15, $00   ; dy -24 dx -32 tile 21 attr $00
    db $e8, $e8, $16, $00   ; dy -24 dx -24 tile 22 attr $00
    db $f0, $c8, $15, $00   ; dy -16 dx -56 tile 21 attr $00
    db $f0, $d0, $16, $00   ; dy -16 dx -48 tile 22 attr $00
    db $d8, $00, $09, $00   ; dy -40 dx +0 tile 9 attr $00
    db $f8, $d8, $1a, $00   ; dy -8 dx -40 tile 26 attr $00
    db $f8, $e0, $1b, $00   ; dy -8 dx -32 tile 27 attr $00
    db $f8, $10, $20, $00   ; dy -8 dx +16 tile 32 attr $00
    db $f8, $c0, $20, $20   ; dy -8 dx -64 tile 32 attr $20
    db $f8, $c8, $13, $20   ; dy -8 dx -56 tile 19 attr $20
    db $f8, $08, $13, $00   ; dy -8 dx +8 tile 19 attr $00
    db $e8, $10, $1c, $20   ; dy -24 dx +16 tile 28 attr $20
    db $e8, $d8, $1d, $20   ; dy -24 dx -40 tile 29 attr $20
    db $d0, $e0, $1f, $20   ; dy -48 dx -32 tile 31 attr $20
    db $d0, $38, $1e, $20   ; dy -48 dx +56 tile 30 attr $20
    db $80
Anim_0b_F18:   ; $6fb3 40 sprites
    db $d0, $d8, $05, $00   ; dy -48 dx -40 tile 5 attr $00
    db $e0, $cc, $0b, $00   ; dy -32 dx -52 tile 11 attr $00
    db $e0, $d4, $0c, $00   ; dy -32 dx -44 tile 12 attr $00
    db $e0, $dc, $0d, $00   ; dy -32 dx -36 tile 13 attr $00
    db $d0, $e0, $06, $00   ; dy -48 dx -32 tile 6 attr $00
    db $d0, $e8, $08, $00   ; dy -48 dx -24 tile 8 attr $00
    db $d0, $d0, $14, $00   ; dy -48 dx -48 tile 20 attr $00
    db $d0, $b0, $15, $00   ; dy -48 dx -80 tile 21 attr $00
    db $d0, $b8, $16, $00   ; dy -48 dx -72 tile 22 attr $00
    db $d0, $c0, $17, $00   ; dy -48 dx -64 tile 23 attr $00
    db $d0, $c8, $0e, $00   ; dy -48 dx -56 tile 14 attr $00
    db $d8, $b8, $19, $00   ; dy -40 dx -72 tile 25 attr $00
    db $d8, $c0, $1a, $00   ; dy -40 dx -64 tile 26 attr $00
    db $d8, $c8, $14, $00   ; dy -40 dx -56 tile 20 attr $00
    db $e0, $b4, $19, $00   ; dy -32 dx -76 tile 25 attr $00
    db $e0, $bc, $1a, $00   ; dy -32 dx -68 tile 26 attr $00
    db $e0, $c4, $0d, $00   ; dy -32 dx -60 tile 13 attr $00
    db $d8, $d8, $07, $00   ; dy -40 dx -40 tile 7 attr $00
    db $d8, $e0, $08, $00   ; dy -40 dx -32 tile 8 attr $00
    db $d8, $e8, $09, $00   ; dy -40 dx -24 tile 9 attr $00
    db $d8, $d0, $16, $00   ; dy -40 dx -48 tile 22 attr $00
    db $d0, $f0, $09, $00   ; dy -48 dx -16 tile 9 attr $00
    db $e8, $c4, $15, $00   ; dy -24 dx -60 tile 21 attr $00
    db $e8, $cc, $16, $00   ; dy -24 dx -52 tile 22 attr $00
    db $e8, $d4, $17, $00   ; dy -24 dx -44 tile 23 attr $00
    db $e8, $dc, $12, $00   ; dy -24 dx -36 tile 18 attr $00
    db $f0, $d8, $15, $00   ; dy -16 dx -40 tile 21 attr $00
    db $f0, $e0, $16, $00   ; dy -16 dx -32 tile 22 attr $00
    db $f0, $e8, $17, $00   ; dy -16 dx -24 tile 23 attr $00
    db $f8, $e0, $05, $00   ; dy -8 dx -32 tile 5 attr $00
    db $e8, $e4, $09, $00   ; dy -24 dx -28 tile 9 attr $00
    db $f8, $c8, $15, $00   ; dy -8 dx -56 tile 21 attr $00
    db $f8, $d0, $16, $00   ; dy -8 dx -48 tile 22 attr $00
    db $f8, $d8, $17, $00   ; dy -8 dx -40 tile 23 attr $00
    db $f8, $e8, $10, $00   ; dy -8 dx -24 tile 16 attr $00
    db $f8, $f0, $11, $00   ; dy -8 dx -16 tile 17 attr $00
    db $f8, $f8, $12, $00   ; dy -8 dx -8 tile 18 attr $00
    db $f8, $08, $21, $00   ; dy -8 dx +8 tile 33 attr $00
    db $f8, $b8, $21, $20   ; dy -8 dx -72 tile 33 attr $20
    db $d0, $00, $1f, $00   ; dy -48 dx +0 tile 31 attr $00
    db $80
Anim_0b_F19:   ; $7054 40 sprites
    db $f8, $e8, $0e, $00   ; dy -8 dx -24 tile 14 attr $00
    db $e0, $10, $0b, $00   ; dy -32 dx +16 tile 11 attr $00
    db $e0, $18, $0c, $00   ; dy -32 dx +24 tile 12 attr $00
    db $e0, $20, $0d, $00   ; dy -32 dx +32 tile 13 attr $00
    db $d8, $10, $05, $00   ; dy -40 dx +16 tile 5 attr $00
    db $d8, $18, $06, $00   ; dy -40 dx +24 tile 6 attr $00
    db $d8, $20, $08, $00   ; dy -40 dx +32 tile 8 attr $00
    db $da, $28, $11, $00   ; dy -38 dx +40 tile 17 attr $00
    db $da, $30, $12, $00   ; dy -38 dx +48 tile 18 attr $00
    db $e8, $00, $0a, $00   ; dy -24 dx +0 tile 10 attr $00
    db $e8, $08, $0b, $00   ; dy -24 dx +8 tile 11 attr $00
    db $e8, $10, $0c, $00   ; dy -24 dx +16 tile 12 attr $00
    db $e8, $18, $0d, $00   ; dy -24 dx +24 tile 13 attr $00
    db $d0, $f8, $10, $00   ; dy -48 dx -8 tile 16 attr $00
    db $d0, $00, $11, $00   ; dy -48 dx +0 tile 17 attr $00
    db $d0, $08, $12, $00   ; dy -48 dx +8 tile 18 attr $00
    db $d0, $e8, $0e, $00   ; dy -48 dx -24 tile 14 attr $00
    db $d0, $f0, $0f, $00   ; dy -48 dx -16 tile 15 attr $00
    db $d8, $f0, $19, $00   ; dy -40 dx -16 tile 25 attr $00
    db $d8, $f8, $1a, $00   ; dy -40 dx -8 tile 26 attr $00
    db $d8, $00, $1b, $00   ; dy -40 dx +0 tile 27 attr $00
    db $e0, $f8, $15, $00   ; dy -32 dx -8 tile 21 attr $00
    db $d8, $08, $14, $00   ; dy -40 dx +8 tile 20 attr $00
    db $e0, $00, $1a, $00   ; dy -32 dx +0 tile 26 attr $00
    db $e0, $08, $1b, $00   ; dy -32 dx +8 tile 27 attr $00
    db $f0, $e8, $19, $00   ; dy -16 dx -24 tile 25 attr $00
    db $f0, $f0, $1a, $00   ; dy -16 dx -16 tile 26 attr $00
    db $f0, $08, $10, $00   ; dy -16 dx +8 tile 16 attr $00
    db $f0, $10, $11, $00   ; dy -16 dx +16 tile 17 attr $00
    db $f0, $00, $0f, $00   ; dy -16 dx +0 tile 15 attr $00
    db $f0, $f8, $1b, $00   ; dy -16 dx -8 tile 27 attr $00
    db $d0, $10, $09, $00   ; dy -48 dx +16 tile 9 attr $00
    db $f8, $d8, $19, $00   ; dy -8 dx -40 tile 25 attr $00
    db $f8, $e0, $1a, $00   ; dy -8 dx -32 tile 26 attr $00
    db $f8, $f0, $1a, $60   ; dy -8 dx -16 tile 26 attr $60
    db $f8, $f8, $08, $00   ; dy -8 dx -8 tile 8 attr $00
    db $f8, $00, $09, $00   ; dy -8 dx +0 tile 9 attr $00
    db $f8, $c8, $13, $00   ; dy -8 dx -56 tile 19 attr $00
    db $f8, $10, $13, $20   ; dy -8 dx +16 tile 19 attr $20
    db $f0, $e0, $1e, $40   ; dy -16 dx -32 tile 30 attr $40
    db $80
Anim_0b_F20:   ; $70f5 40 sprites
    db $e8, $00, $0b, $00   ; dy -24 dx +0 tile 11 attr $00
    db $e8, $08, $0c, $00   ; dy -24 dx +8 tile 12 attr $00
    db $e8, $10, $0d, $00   ; dy -24 dx +16 tile 13 attr $00
    db $e0, $e0, $04, $00   ; dy -32 dx -32 tile 4 attr $00
    db $d8, $f8, $11, $00   ; dy -40 dx -8 tile 17 attr $00
    db $d8, $00, $12, $00   ; dy -40 dx +0 tile 18 attr $00
    db $e0, $e8, $0c, $00   ; dy -32 dx -24 tile 12 attr $00
    db $e0, $f0, $14, $00   ; dy -32 dx -16 tile 20 attr $00
    db $e8, $f8, $14, $00   ; dy -24 dx -8 tile 20 attr $00
    db $d8, $e0, $15, $00   ; dy -40 dx -32 tile 21 attr $00
    db $d8, $e8, $16, $00   ; dy -40 dx -24 tile 22 attr $00
    db $d8, $f0, $17, $00   ; dy -40 dx -16 tile 23 attr $00
    db $f8, $f0, $0c, $00   ; dy -8 dx -16 tile 12 attr $00
    db $f8, $f8, $0d, $00   ; dy -8 dx -8 tile 13 attr $00
    db $f0, $e0, $05, $00   ; dy -16 dx -32 tile 5 attr $00
    db $f0, $e8, $06, $00   ; dy -16 dx -24 tile 6 attr $00
    db $f0, $f0, $07, $00   ; dy -16 dx -16 tile 7 attr $00
    db $f0, $f8, $14, $00   ; dy -16 dx -8 tile 20 attr $00
    db $f0, $00, $0f, $00   ; dy -16 dx +0 tile 15 attr $00
    db $f8, $00, $17, $00   ; dy -8 dx +0 tile 23 attr $00
    db $f0, $08, $17, $00   ; dy -16 dx +8 tile 23 attr $00
    db $e0, $f8, $06, $00   ; dy -32 dx -8 tile 6 attr $00
    db $e0, $00, $07, $00   ; dy -32 dx +0 tile 7 attr $00
    db $e0, $08, $08, $00   ; dy -32 dx +8 tile 8 attr $00
    db $e0, $10, $09, $00   ; dy -32 dx +16 tile 9 attr $00
    db $e8, $e8, $15, $00   ; dy -24 dx -24 tile 21 attr $00
    db $e8, $f0, $16, $00   ; dy -24 dx -16 tile 22 attr $00
    db $f0, $d0, $15, $00   ; dy -16 dx -48 tile 21 attr $00
    db $f0, $d8, $16, $00   ; dy -16 dx -40 tile 22 attr $00
    db $d8, $08, $09, $00   ; dy -40 dx +8 tile 9 attr $00
    db $f8, $e0, $1a, $00   ; dy -8 dx -32 tile 26 attr $00
    db $f8, $e8, $1b, $00   ; dy -8 dx -24 tile 27 attr $00
    db $f8, $10, $21, $00   ; dy -8 dx +16 tile 33 attr $00
    db $f8, $18, $20, $00   ; dy -8 dx +24 tile 32 attr $00
    db $f8, $c8, $20, $20   ; dy -8 dx -56 tile 32 attr $20
    db $f8, $d0, $21, $20   ; dy -8 dx -48 tile 33 attr $20
    db $f0, $18, $1d, $00   ; dy -16 dx +24 tile 29 attr $00
    db $d0, $f0, $1c, $00   ; dy -48 dx -16 tile 28 attr $00
    db $d8, $10, $1d, $00   ; dy -40 dx +16 tile 29 attr $00
    db $d8, $30, $1c, $00   ; dy -40 dx +48 tile 28 attr $00
    db $80
Anim_0b_F21:   ; $7196 40 sprites
    db $d0, $f0, $05, $00   ; dy -48 dx -16 tile 5 attr $00
    db $e0, $e4, $0b, $00   ; dy -32 dx -28 tile 11 attr $00
    db $e0, $ec, $0c, $00   ; dy -32 dx -20 tile 12 attr $00
    db $e0, $f4, $0d, $00   ; dy -32 dx -12 tile 13 attr $00
    db $d0, $f8, $06, $00   ; dy -48 dx -8 tile 6 attr $00
    db $d0, $00, $08, $00   ; dy -48 dx +0 tile 8 attr $00
    db $d0, $e8, $14, $00   ; dy -48 dx -24 tile 20 attr $00
    db $d0, $c8, $15, $00   ; dy -48 dx -56 tile 21 attr $00
    db $d0, $d0, $16, $00   ; dy -48 dx -48 tile 22 attr $00
    db $d0, $d8, $17, $00   ; dy -48 dx -40 tile 23 attr $00
    db $d0, $e0, $0e, $00   ; dy -48 dx -32 tile 14 attr $00
    db $d8, $d0, $19, $00   ; dy -40 dx -48 tile 25 attr $00
    db $d8, $d8, $1a, $00   ; dy -40 dx -40 tile 26 attr $00
    db $d8, $e0, $14, $00   ; dy -40 dx -32 tile 20 attr $00
    db $e0, $cc, $19, $00   ; dy -32 dx -52 tile 25 attr $00
    db $e0, $d4, $1a, $00   ; dy -32 dx -44 tile 26 attr $00
    db $e0, $dc, $0d, $00   ; dy -32 dx -36 tile 13 attr $00
    db $d8, $f0, $07, $00   ; dy -40 dx -16 tile 7 attr $00
    db $d8, $f8, $08, $00   ; dy -40 dx -8 tile 8 attr $00
    db $d8, $00, $09, $00   ; dy -40 dx +0 tile 9 attr $00
    db $d8, $e8, $16, $00   ; dy -40 dx -24 tile 22 attr $00
    db $d0, $08, $09, $00   ; dy -48 dx +8 tile 9 attr $00
    db $e8, $dc, $15, $00   ; dy -24 dx -36 tile 21 attr $00
    db $e8, $e4, $16, $00   ; dy -24 dx -28 tile 22 attr $00
    db $e8, $ec, $17, $00   ; dy -24 dx -20 tile 23 attr $00
    db $e8, $f4, $12, $00   ; dy -24 dx -12 tile 18 attr $00
    db $f0, $f0, $15, $00   ; dy -16 dx -16 tile 21 attr $00
    db $f0, $f8, $16, $00   ; dy -16 dx -8 tile 22 attr $00
    db $f0, $00, $17, $00   ; dy -16 dx +0 tile 23 attr $00
    db $f8, $f8, $05, $00   ; dy -8 dx -8 tile 5 attr $00
    db $e8, $fc, $09, $00   ; dy -24 dx -4 tile 9 attr $00
    db $f8, $e0, $15, $00   ; dy -8 dx -32 tile 21 attr $00
    db $f8, $e8, $16, $00   ; dy -8 dx -24 tile 22 attr $00
    db $f8, $f0, $17, $00   ; dy -8 dx -16 tile 23 attr $00
    db $f8, $00, $10, $00   ; dy -8 dx +0 tile 16 attr $00
    db $f8, $08, $11, $00   ; dy -8 dx +8 tile 17 attr $00
    db $f8, $10, $12, $00   ; dy -8 dx +16 tile 18 attr $00
    db $f8, $d0, $21, $00   ; dy -8 dx -48 tile 33 attr $00
    db $f8, $20, $21, $20   ; dy -8 dx +32 tile 33 attr $20
    db $f8, $b0, $1e, $20   ; dy -8 dx -80 tile 30 attr $20
    db $80
Anim_0b_F22:   ; $7237 40 sprites
    db $f8, $08, $0e, $00   ; dy -8 dx +8 tile 14 attr $00
    db $e0, $30, $0b, $00   ; dy -32 dx +48 tile 11 attr $00
    db $e0, $38, $0c, $00   ; dy -32 dx +56 tile 12 attr $00
    db $d8, $30, $05, $00   ; dy -40 dx +48 tile 5 attr $00
    db $d8, $38, $06, $00   ; dy -40 dx +56 tile 6 attr $00
    db $e8, $20, $0a, $00   ; dy -24 dx +32 tile 10 attr $00
    db $e8, $28, $0b, $00   ; dy -24 dx +40 tile 11 attr $00
    db $e8, $30, $0c, $00   ; dy -24 dx +48 tile 12 attr $00
    db $e8, $38, $0d, $00   ; dy -24 dx +56 tile 13 attr $00
    db $d0, $18, $10, $00   ; dy -48 dx +24 tile 16 attr $00
    db $d0, $20, $11, $00   ; dy -48 dx +32 tile 17 attr $00
    db $d0, $28, $12, $00   ; dy -48 dx +40 tile 18 attr $00
    db $d0, $08, $0e, $00   ; dy -48 dx +8 tile 14 attr $00
    db $d0, $10, $0f, $00   ; dy -48 dx +16 tile 15 attr $00
    db $d8, $10, $19, $00   ; dy -40 dx +16 tile 25 attr $00
    db $d8, $18, $1a, $00   ; dy -40 dx +24 tile 26 attr $00
    db $d8, $20, $1b, $00   ; dy -40 dx +32 tile 27 attr $00
    db $e0, $18, $15, $00   ; dy -32 dx +24 tile 21 attr $00
    db $d8, $28, $14, $00   ; dy -40 dx +40 tile 20 attr $00
    db $e0, $20, $1a, $00   ; dy -32 dx +32 tile 26 attr $00
    db $e0, $28, $1b, $00   ; dy -32 dx +40 tile 27 attr $00
    db $f0, $08, $19, $00   ; dy -16 dx +8 tile 25 attr $00
    db $f0, $10, $1a, $00   ; dy -16 dx +16 tile 26 attr $00
    db $f0, $28, $10, $00   ; dy -16 dx +40 tile 16 attr $00
    db $f0, $30, $11, $00   ; dy -16 dx +48 tile 17 attr $00
    db $f0, $20, $0f, $00   ; dy -16 dx +32 tile 15 attr $00
    db $f0, $18, $1b, $00   ; dy -16 dx +24 tile 27 attr $00
    db $d0, $30, $09, $00   ; dy -48 dx +48 tile 9 attr $00
    db $f8, $f8, $19, $00   ; dy -8 dx -8 tile 25 attr $00
    db $f8, $00, $1a, $00   ; dy -8 dx +0 tile 26 attr $00
    db $f8, $10, $1a, $60   ; dy -8 dx +16 tile 26 attr $60
    db $f8, $18, $08, $00   ; dy -8 dx +24 tile 8 attr $00
    db $f8, $20, $09, $00   ; dy -8 dx +32 tile 9 attr $00
    db $e0, $40, $0d, $00   ; dy -32 dx +64 tile 13 attr $00
    db $d8, $40, $08, $00   ; dy -40 dx +64 tile 8 attr $00
    db $da, $48, $11, $00   ; dy -38 dx +72 tile 17 attr $00
    db $f8, $30, $13, $00   ; dy -8 dx +48 tile 19 attr $00
    db $f8, $e8, $13, $20   ; dy -8 dx -24 tile 19 attr $20
    db $e8, $d8, $1f, $00   ; dy -24 dx -40 tile 31 attr $00
    db $d0, $f0, $1d, $00   ; dy -48 dx -16 tile 29 attr $00
    db $80
Anim_0b_F23:   ; $72d8 40 sprites
    db $e8, $28, $0b, $00   ; dy -24 dx +40 tile 11 attr $00
    db $e8, $30, $0c, $00   ; dy -24 dx +48 tile 12 attr $00
    db $e8, $38, $0d, $00   ; dy -24 dx +56 tile 13 attr $00
    db $e0, $08, $04, $00   ; dy -32 dx +8 tile 4 attr $00
    db $d8, $20, $11, $00   ; dy -40 dx +32 tile 17 attr $00
    db $d8, $28, $12, $00   ; dy -40 dx +40 tile 18 attr $00
    db $e0, $10, $0c, $00   ; dy -32 dx +16 tile 12 attr $00
    db $e0, $18, $14, $00   ; dy -32 dx +24 tile 20 attr $00
    db $e8, $20, $14, $00   ; dy -24 dx +32 tile 20 attr $00
    db $d8, $08, $15, $00   ; dy -40 dx +8 tile 21 attr $00
    db $d8, $10, $16, $00   ; dy -40 dx +16 tile 22 attr $00
    db $d8, $18, $17, $00   ; dy -40 dx +24 tile 23 attr $00
    db $f8, $18, $0c, $00   ; dy -8 dx +24 tile 12 attr $00
    db $f8, $20, $0d, $00   ; dy -8 dx +32 tile 13 attr $00
    db $f0, $08, $05, $00   ; dy -16 dx +8 tile 5 attr $00
    db $f0, $10, $06, $00   ; dy -16 dx +16 tile 6 attr $00
    db $f0, $18, $07, $00   ; dy -16 dx +24 tile 7 attr $00
    db $f0, $20, $14, $00   ; dy -16 dx +32 tile 20 attr $00
    db $f0, $28, $0f, $00   ; dy -16 dx +40 tile 15 attr $00
    db $f8, $28, $17, $00   ; dy -8 dx +40 tile 23 attr $00
    db $f0, $30, $17, $00   ; dy -16 dx +48 tile 23 attr $00
    db $e0, $20, $06, $00   ; dy -32 dx +32 tile 6 attr $00
    db $e0, $28, $07, $00   ; dy -32 dx +40 tile 7 attr $00
    db $e0, $30, $08, $00   ; dy -32 dx +48 tile 8 attr $00
    db $e0, $38, $09, $00   ; dy -32 dx +56 tile 9 attr $00
    db $e8, $10, $15, $00   ; dy -24 dx +16 tile 21 attr $00
    db $e8, $18, $16, $00   ; dy -24 dx +24 tile 22 attr $00
    db $f0, $f8, $15, $00   ; dy -16 dx -8 tile 21 attr $00
    db $f0, $00, $16, $00   ; dy -16 dx +0 tile 22 attr $00
    db $d8, $30, $09, $00   ; dy -40 dx +48 tile 9 attr $00
    db $f8, $08, $1a, $00   ; dy -8 dx +8 tile 26 attr $00
    db $f8, $10, $1b, $00   ; dy -8 dx +16 tile 27 attr $00
    db $f8, $38, $20, $00   ; dy -8 dx +56 tile 32 attr $00
    db $f8, $40, $21, $00   ; dy -8 dx +64 tile 33 attr $00
    db $f8, $f8, $20, $20   ; dy -8 dx -8 tile 32 attr $20
    db $f8, $f0, $21, $20   ; dy -8 dx -16 tile 33 attr $20
    db $e0, $00, $1f, $00   ; dy -32 dx +0 tile 31 attr $00
    db $f8, $d8, $1d, $00   ; dy -8 dx -40 tile 29 attr $00
    db $d0, $20, $1f, $00   ; dy -48 dx +32 tile 31 attr $00
    db $e0, $48, $1c, $00   ; dy -32 dx +72 tile 28 attr $00
    db $80
Anim_0b_F24:   ; $7379 40 sprites
    db $d0, $20, $05, $00   ; dy -48 dx +32 tile 5 attr $00
    db $e0, $14, $0b, $00   ; dy -32 dx +20 tile 11 attr $00
    db $e0, $1c, $0c, $00   ; dy -32 dx +28 tile 12 attr $00
    db $e0, $24, $0d, $00   ; dy -32 dx +36 tile 13 attr $00
    db $d0, $28, $06, $00   ; dy -48 dx +40 tile 6 attr $00
    db $d0, $30, $08, $00   ; dy -48 dx +48 tile 8 attr $00
    db $d0, $18, $14, $00   ; dy -48 dx +24 tile 20 attr $00
    db $d0, $f8, $15, $00   ; dy -48 dx -8 tile 21 attr $00
    db $d0, $00, $16, $00   ; dy -48 dx +0 tile 22 attr $00
    db $d0, $08, $17, $00   ; dy -48 dx +8 tile 23 attr $00
    db $d0, $10, $0e, $00   ; dy -48 dx +16 tile 14 attr $00
    db $d8, $00, $19, $00   ; dy -40 dx +0 tile 25 attr $00
    db $d8, $08, $1a, $00   ; dy -40 dx +8 tile 26 attr $00
    db $d8, $10, $14, $00   ; dy -40 dx +16 tile 20 attr $00
    db $e0, $fc, $19, $00   ; dy -32 dx -4 tile 25 attr $00
    db $e0, $04, $1a, $00   ; dy -32 dx +4 tile 26 attr $00
    db $e0, $0c, $0d, $00   ; dy -32 dx +12 tile 13 attr $00
    db $d8, $20, $07, $00   ; dy -40 dx +32 tile 7 attr $00
    db $d8, $28, $08, $00   ; dy -40 dx +40 tile 8 attr $00
    db $d8, $30, $09, $00   ; dy -40 dx +48 tile 9 attr $00
    db $d8, $18, $16, $00   ; dy -40 dx +24 tile 22 attr $00
    db $d0, $38, $09, $00   ; dy -48 dx +56 tile 9 attr $00
    db $e8, $0c, $15, $00   ; dy -24 dx +12 tile 21 attr $00
    db $e8, $14, $16, $00   ; dy -24 dx +20 tile 22 attr $00
    db $e8, $1c, $17, $00   ; dy -24 dx +28 tile 23 attr $00
    db $e8, $24, $12, $00   ; dy -24 dx +36 tile 18 attr $00
    db $f0, $20, $15, $00   ; dy -16 dx +32 tile 21 attr $00
    db $f0, $28, $16, $00   ; dy -16 dx +40 tile 22 attr $00
    db $f0, $30, $17, $00   ; dy -16 dx +48 tile 23 attr $00
    db $f8, $28, $05, $00   ; dy -8 dx +40 tile 5 attr $00
    db $e8, $2c, $09, $00   ; dy -24 dx +44 tile 9 attr $00
    db $f8, $10, $15, $00   ; dy -8 dx +16 tile 21 attr $00
    db $f8, $18, $16, $00   ; dy -8 dx +24 tile 22 attr $00
    db $f8, $20, $17, $00   ; dy -8 dx +32 tile 23 attr $00
    db $f8, $30, $10, $00   ; dy -8 dx +48 tile 16 attr $00
    db $f8, $38, $11, $00   ; dy -8 dx +56 tile 17 attr $00
    db $f8, $00, $20, $00   ; dy -8 dx +0 tile 32 attr $00
    db $f8, $48, $20, $20   ; dy -8 dx +72 tile 32 attr $20
    db $f8, $f0, $1c, $00   ; dy -8 dx -16 tile 28 attr $00
    db $e8, $34, $1d, $00   ; dy -24 dx +52 tile 29 attr $00
    db $80
Anim_0b_F25:   ; $741a 14 sprites
    db $f8, $40, $0e, $00   ; dy -8 dx +64 tile 14 attr $00
    db $d0, $40, $0e, $00   ; dy -48 dx +64 tile 14 attr $00
    db $d0, $48, $0f, $00   ; dy -48 dx +72 tile 15 attr $00
    db $d8, $48, $19, $00   ; dy -40 dx +72 tile 25 attr $00
    db $f0, $40, $19, $00   ; dy -16 dx +64 tile 25 attr $00
    db $f0, $48, $1a, $00   ; dy -16 dx +72 tile 26 attr $00
    db $f8, $30, $19, $00   ; dy -8 dx +48 tile 25 attr $00
    db $f8, $38, $1a, $00   ; dy -8 dx +56 tile 26 attr $00
    db $f8, $48, $1a, $60   ; dy -8 dx +72 tile 26 attr $60
    db $f8, $20, $20, $20   ; dy -8 dx +32 tile 32 attr $20
    db $f8, $18, $21, $20   ; dy -8 dx +24 tile 33 attr $20
    db $e8, $00, $1c, $20   ; dy -24 dx +0 tile 28 attr $20
    db $e8, $28, $1f, $00   ; dy -24 dx +40 tile 31 attr $00
    db $f8, $10, $1e, $20   ; dy -8 dx +16 tile 30 attr $20
    db $80
Anim_0b_F26:   ; $7453 4 sprites
    db $d0, $20, $1d, $00   ; dy -48 dx +32 tile 29 attr $00
    db $d8, $38, $1f, $00   ; dy -40 dx +56 tile 31 attr $00
    db $f8, $48, $1c, $00   ; dy -8 dx +72 tile 28 attr $00
    db $d0, $48, $1e, $00   ; dy -48 dx +72 tile 30 attr $00
Anim_0b_F27:   ; $7463 empty frame = the $80 end above (shared)
    db $80
Anim_0c_IceBolt:   ; $7464 animation $0c — IceBolt, FrigidAir
    dw Anim_0c_F00
    dw Anim_0c_F01
    dw Anim_0c_F02
    dw Anim_0c_F03
    dw Anim_0c_F04
    dw Anim_0c_F05
    dw Anim_0c_F06
    dw Anim_0c_F07
    dw Anim_0c_F08
    dw Anim_0c_F09
    dw Anim_0c_F10
    dw Anim_0c_F11
    dw Anim_0c_F12
    dw Anim_0c_F13
    dw Anim_0c_F14
    dw Anim_0c_F15
    dw Anim_0c_F16
    dw Anim_0c_F17
    dw Anim_0c_F18
    dw Anim_0c_F19
    dw Anim_0c_F19
    dw Anim_0c_F19
    dw Anim_0c_F19
    dw Anim_0c_F19
    dw Anim_0c_F19
    dw Anim_0c_F19
    dw Anim_0c_F19
    dw Anim_0c_F19
    dw Anim_0c_F19
    dw Anim_0c_F19
    dw Anim_0c_F19
    dw Anim_0c_F19
Anim_0c_F00:   ; $74a4 4 sprites
    db $f8, $b0, $04, $00   ; dy -8 dx -80 tile 4 attr $00
    db $f8, $b8, $05, $00   ; dy -8 dx -72 tile 5 attr $00
    db $f0, $b0, $01, $00   ; dy -16 dx -80 tile 1 attr $00
    db $f0, $b8, $02, $00   ; dy -16 dx -72 tile 2 attr $00
    db $80
Anim_0c_F01:   ; $74b5 10 sprites
    db $f8, $c4, $13, $20   ; dy -8 dx -60 tile 19 attr $20
    db $f8, $bc, $14, $20   ; dy -8 dx -68 tile 20 attr $20
    db $f8, $b4, $15, $20   ; dy -8 dx -76 tile 21 attr $20
    db $f0, $c4, $10, $20   ; dy -16 dx -60 tile 16 attr $20
    db $f0, $bc, $11, $20   ; dy -16 dx -68 tile 17 attr $20
    db $f0, $b4, $12, $20   ; dy -16 dx -76 tile 18 attr $20
    db $e8, $c4, $0e, $20   ; dy -24 dx -60 tile 14 attr $20
    db $e8, $bc, $0f, $20   ; dy -24 dx -68 tile 15 attr $20
    db $f0, $ac, $1c, $00   ; dy -16 dx -84 tile 28 attr $00
    db $f8, $ac, $1d, $00   ; dy -8 dx -84 tile 29 attr $00
    db $80
Anim_0c_F02:   ; $74de 11 sprites
    db $f8, $c0, $14, $00   ; dy -8 dx -64 tile 20 attr $00
    db $f8, $c8, $15, $00   ; dy -8 dx -56 tile 21 attr $00
    db $f0, $b8, $10, $00   ; dy -16 dx -72 tile 16 attr $00
    db $f0, $c0, $11, $00   ; dy -16 dx -64 tile 17 attr $00
    db $f0, $c8, $12, $00   ; dy -16 dx -56 tile 18 attr $00
    db $e8, $b8, $0e, $00   ; dy -24 dx -72 tile 14 attr $00
    db $e8, $c0, $0f, $00   ; dy -24 dx -64 tile 15 attr $00
    db $f0, $b0, $01, $20   ; dy -16 dx -80 tile 1 attr $20
    db $f8, $b0, $04, $20   ; dy -8 dx -80 tile 4 attr $20
    db $f8, $d0, $18, $00   ; dy -8 dx -48 tile 24 attr $00
    db $f8, $b8, $16, $20   ; dy -8 dx -72 tile 22 attr $20
    db $80
Anim_0c_F03:   ; $750b 16 sprites
    db $f8, $c4, $14, $20   ; dy -8 dx -60 tile 20 attr $20
    db $f8, $bc, $15, $20   ; dy -8 dx -68 tile 21 attr $20
    db $f0, $cc, $10, $20   ; dy -16 dx -52 tile 16 attr $20
    db $f0, $c4, $11, $20   ; dy -16 dx -60 tile 17 attr $20
    db $f0, $bc, $12, $20   ; dy -16 dx -68 tile 18 attr $20
    db $e8, $cc, $0e, $20   ; dy -24 dx -52 tile 14 attr $20
    db $e8, $c4, $0f, $00   ; dy -24 dx -60 tile 15 attr $00
    db $f0, $b4, $01, $20   ; dy -16 dx -76 tile 1 attr $20
    db $f8, $b4, $04, $20   ; dy -8 dx -76 tile 4 attr $20
    db $f8, $d4, $08, $00   ; dy -8 dx -44 tile 8 attr $00
    db $f0, $d4, $06, $00   ; dy -16 dx -44 tile 6 attr $00
    db $f0, $dc, $07, $00   ; dy -16 dx -36 tile 7 attr $00
    db $f8, $cc, $17, $20   ; dy -8 dx -52 tile 23 attr $20
    db $f8, $dc, $19, $00   ; dy -8 dx -36 tile 25 attr $00
    db $f0, $ac, $1e, $00   ; dy -16 dx -84 tile 30 attr $00
    db $f8, $ac, $1f, $00   ; dy -8 dx -84 tile 31 attr $00
    db $80
Anim_0c_F04:   ; $754c 16 sprites
    db $f8, $b8, $08, $20   ; dy -8 dx -72 tile 8 attr $20
    db $f8, $b0, $09, $20   ; dy -8 dx -80 tile 9 attr $20
    db $f0, $b8, $06, $20   ; dy -16 dx -72 tile 6 attr $20
    db $f0, $b0, $07, $20   ; dy -16 dx -80 tile 7 attr $20
    db $f8, $c0, $03, $00   ; dy -8 dx -64 tile 3 attr $00
    db $f8, $c8, $04, $00   ; dy -8 dx -56 tile 4 attr $00
    db $f8, $d0, $05, $00   ; dy -8 dx -48 tile 5 attr $00
    db $f0, $c0, $00, $00   ; dy -16 dx -64 tile 0 attr $00
    db $f0, $c8, $01, $00   ; dy -16 dx -56 tile 1 attr $00
    db $f0, $d0, $02, $00   ; dy -16 dx -48 tile 2 attr $00
    db $f8, $e0, $04, $20   ; dy -8 dx -32 tile 4 attr $20
    db $f8, $d8, $05, $20   ; dy -8 dx -40 tile 5 attr $20
    db $f0, $e8, $00, $20   ; dy -16 dx -24 tile 0 attr $20
    db $f0, $e0, $01, $20   ; dy -16 dx -32 tile 1 attr $20
    db $f0, $d8, $02, $20   ; dy -16 dx -40 tile 2 attr $20
    db $f8, $e8, $1a, $00   ; dy -8 dx -24 tile 26 attr $00
    db $80
Anim_0c_F05:   ; $758d 17 sprites
    db $f8, $dc, $03, $20   ; dy -8 dx -36 tile 3 attr $20
    db $f0, $dc, $00, $20   ; dy -16 dx -36 tile 0 attr $20
    db $f8, $f4, $13, $20   ; dy -8 dx -12 tile 19 attr $20
    db $f8, $ec, $14, $20   ; dy -8 dx -20 tile 20 attr $20
    db $f8, $e4, $15, $20   ; dy -8 dx -28 tile 21 attr $20
    db $f0, $f4, $10, $20   ; dy -16 dx -12 tile 16 attr $20
    db $f0, $ec, $11, $20   ; dy -16 dx -20 tile 17 attr $20
    db $f0, $e4, $12, $20   ; dy -16 dx -28 tile 18 attr $20
    db $e8, $f4, $0e, $20   ; dy -24 dx -12 tile 14 attr $20
    db $e8, $ec, $0f, $20   ; dy -24 dx -20 tile 15 attr $20
    db $f8, $d4, $08, $20   ; dy -8 dx -44 tile 8 attr $20
    db $f8, $cc, $09, $20   ; dy -8 dx -52 tile 9 attr $20
    db $f0, $d4, $06, $20   ; dy -16 dx -44 tile 6 attr $20
    db $f0, $cc, $07, $20   ; dy -16 dx -52 tile 7 attr $20
    db $f8, $c4, $0b, $20   ; dy -8 dx -60 tile 11 attr $20
    db $f8, $bc, $0c, $20   ; dy -8 dx -68 tile 12 attr $20
    db $f8, $b4, $0d, $20   ; dy -8 dx -76 tile 13 attr $20
    db $80
Anim_0c_F06:   ; $75d2 17 sprites
    db $f8, $f0, $14, $00   ; dy -8 dx -16 tile 20 attr $00
    db $f8, $f8, $15, $00   ; dy -8 dx -8 tile 21 attr $00
    db $f0, $e8, $10, $00   ; dy -16 dx -24 tile 16 attr $00
    db $f0, $f0, $11, $00   ; dy -16 dx -16 tile 17 attr $00
    db $f0, $f8, $12, $00   ; dy -16 dx -8 tile 18 attr $00
    db $e8, $e8, $0e, $00   ; dy -24 dx -24 tile 14 attr $00
    db $e8, $f0, $0f, $00   ; dy -24 dx -16 tile 15 attr $00
    db $f0, $e0, $01, $20   ; dy -16 dx -32 tile 1 attr $20
    db $f0, $d8, $02, $20   ; dy -16 dx -40 tile 2 attr $20
    db $f8, $e0, $04, $20   ; dy -8 dx -32 tile 4 attr $20
    db $f8, $d8, $05, $20   ; dy -8 dx -40 tile 5 attr $20
    db $f8, $00, $18, $00   ; dy -8 dx +0 tile 24 attr $00
    db $f8, $e8, $16, $20   ; dy -8 dx -24 tile 22 attr $20
    db $f8, $c8, $0b, $00   ; dy -8 dx -56 tile 11 attr $00
    db $f8, $d0, $0c, $00   ; dy -8 dx -48 tile 12 attr $00
    db $f8, $b8, $0d, $20   ; dy -8 dx -72 tile 13 attr $20
    db $f8, $c0, $0c, $00   ; dy -8 dx -64 tile 12 attr $00
    db $80
Anim_0c_F07:   ; $7617 19 sprites
    db $f8, $f4, $14, $20   ; dy -8 dx -12 tile 20 attr $20
    db $f8, $ec, $15, $20   ; dy -8 dx -20 tile 21 attr $20
    db $f0, $fc, $10, $20   ; dy -16 dx -4 tile 16 attr $20
    db $f0, $f4, $11, $20   ; dy -16 dx -12 tile 17 attr $20
    db $f0, $ec, $12, $20   ; dy -16 dx -20 tile 18 attr $20
    db $e8, $fc, $0e, $20   ; dy -24 dx -4 tile 14 attr $20
    db $e8, $f4, $0f, $00   ; dy -24 dx -12 tile 15 attr $00
    db $f0, $e4, $01, $20   ; dy -16 dx -28 tile 1 attr $20
    db $f0, $dc, $02, $20   ; dy -16 dx -36 tile 2 attr $20
    db $f8, $e4, $04, $20   ; dy -8 dx -28 tile 4 attr $20
    db $f8, $dc, $05, $20   ; dy -8 dx -36 tile 5 attr $20
    db $f8, $04, $08, $00   ; dy -8 dx +4 tile 8 attr $00
    db $f0, $04, $06, $00   ; dy -16 dx +4 tile 6 attr $00
    db $f0, $0c, $07, $00   ; dy -16 dx +12 tile 7 attr $00
    db $f8, $fc, $17, $20   ; dy -8 dx -4 tile 23 attr $20
    db $f8, $d4, $0c, $20   ; dy -8 dx -44 tile 12 attr $20
    db $f8, $0c, $19, $00   ; dy -8 dx +12 tile 25 attr $00
    db $f8, $c4, $1b, $20   ; dy -8 dx -60 tile 27 attr $20
    db $f8, $cc, $0b, $20   ; dy -8 dx -52 tile 11 attr $20
    db $80
Anim_0c_F08:   ; $7664 18 sprites
    db $f8, $d8, $0c, $20   ; dy -8 dx -40 tile 12 attr $20
    db $f8, $d0, $0d, $20   ; dy -8 dx -48 tile 13 attr $20
    db $f8, $e8, $08, $20   ; dy -8 dx -24 tile 8 attr $20
    db $f8, $e0, $09, $20   ; dy -8 dx -32 tile 9 attr $20
    db $f0, $e8, $06, $20   ; dy -16 dx -24 tile 6 attr $20
    db $f0, $e0, $07, $20   ; dy -16 dx -32 tile 7 attr $20
    db $f8, $f0, $03, $00   ; dy -8 dx -16 tile 3 attr $00
    db $f8, $f8, $04, $00   ; dy -8 dx -8 tile 4 attr $00
    db $f8, $00, $05, $00   ; dy -8 dx +0 tile 5 attr $00
    db $f0, $f0, $00, $00   ; dy -16 dx -16 tile 0 attr $00
    db $f0, $f8, $01, $00   ; dy -16 dx -8 tile 1 attr $00
    db $f0, $00, $02, $00   ; dy -16 dx +0 tile 2 attr $00
    db $f8, $10, $04, $20   ; dy -8 dx +16 tile 4 attr $20
    db $f8, $08, $05, $20   ; dy -8 dx +8 tile 5 attr $20
    db $f0, $18, $00, $20   ; dy -16 dx +24 tile 0 attr $20
    db $f0, $10, $01, $20   ; dy -16 dx +16 tile 1 attr $20
    db $f0, $08, $02, $20   ; dy -16 dx +8 tile 2 attr $20
    db $f8, $18, $1a, $00   ; dy -8 dx +24 tile 26 attr $00
    db $80
Anim_0c_F09:   ; $76ad 18 sprites
    db $f8, $0c, $03, $20   ; dy -8 dx +12 tile 3 attr $20
    db $f0, $0c, $00, $20   ; dy -16 dx +12 tile 0 attr $20
    db $f8, $24, $13, $20   ; dy -8 dx +36 tile 19 attr $20
    db $f8, $1c, $14, $20   ; dy -8 dx +28 tile 20 attr $20
    db $f8, $14, $15, $20   ; dy -8 dx +20 tile 21 attr $20
    db $f0, $24, $10, $20   ; dy -16 dx +36 tile 16 attr $20
    db $f0, $1c, $11, $20   ; dy -16 dx +28 tile 17 attr $20
    db $f0, $14, $12, $20   ; dy -16 dx +20 tile 18 attr $20
    db $e8, $24, $0e, $20   ; dy -24 dx +36 tile 14 attr $20
    db $e8, $1c, $0f, $20   ; dy -24 dx +28 tile 15 attr $20
    db $f8, $04, $08, $20   ; dy -8 dx +4 tile 8 attr $20
    db $f8, $fc, $09, $20   ; dy -8 dx -4 tile 9 attr $20
    db $f0, $04, $06, $20   ; dy -16 dx +4 tile 6 attr $20
    db $f0, $fc, $07, $20   ; dy -16 dx -4 tile 7 attr $20
    db $f8, $f4, $0b, $20   ; dy -8 dx -12 tile 11 attr $20
    db $f8, $ec, $0c, $20   ; dy -8 dx -20 tile 12 attr $20
    db $f8, $e4, $0d, $20   ; dy -8 dx -28 tile 13 attr $20
    db $f8, $dc, $0e, $20   ; dy -8 dx -36 tile 14 attr $20
    db $80
Anim_0c_F10:   ; $76f6 17 sprites
    db $f8, $20, $14, $00   ; dy -8 dx +32 tile 20 attr $00
    db $f8, $28, $15, $00   ; dy -8 dx +40 tile 21 attr $00
    db $f0, $18, $10, $00   ; dy -16 dx +24 tile 16 attr $00
    db $f0, $20, $11, $00   ; dy -16 dx +32 tile 17 attr $00
    db $f0, $28, $12, $00   ; dy -16 dx +40 tile 18 attr $00
    db $e8, $18, $0e, $00   ; dy -24 dx +24 tile 14 attr $00
    db $e8, $20, $0f, $00   ; dy -24 dx +32 tile 15 attr $00
    db $f0, $10, $01, $20   ; dy -16 dx +16 tile 1 attr $20
    db $f0, $08, $02, $20   ; dy -16 dx +8 tile 2 attr $20
    db $f8, $10, $04, $20   ; dy -8 dx +16 tile 4 attr $20
    db $f8, $08, $05, $20   ; dy -8 dx +8 tile 5 attr $20
    db $f8, $30, $18, $00   ; dy -8 dx +48 tile 24 attr $00
    db $f8, $18, $16, $20   ; dy -8 dx +24 tile 22 attr $20
    db $f8, $f8, $0b, $00   ; dy -8 dx -8 tile 11 attr $00
    db $f8, $00, $0c, $00   ; dy -8 dx +0 tile 12 attr $00
    db $f8, $e8, $0d, $20   ; dy -8 dx -24 tile 13 attr $20
    db $f8, $f0, $0c, $00   ; dy -8 dx -16 tile 12 attr $00
    db $80
Anim_0c_F11:   ; $773b 19 sprites
    db $f8, $24, $14, $20   ; dy -8 dx +36 tile 20 attr $20
    db $f8, $1c, $15, $20   ; dy -8 dx +28 tile 21 attr $20
    db $f0, $2c, $10, $20   ; dy -16 dx +44 tile 16 attr $20
    db $f0, $24, $11, $20   ; dy -16 dx +36 tile 17 attr $20
    db $f0, $1c, $12, $20   ; dy -16 dx +28 tile 18 attr $20
    db $e8, $2c, $0e, $20   ; dy -24 dx +44 tile 14 attr $20
    db $e8, $24, $0f, $00   ; dy -24 dx +36 tile 15 attr $00
    db $f0, $14, $01, $20   ; dy -16 dx +20 tile 1 attr $20
    db $f0, $0c, $02, $20   ; dy -16 dx +12 tile 2 attr $20
    db $f8, $14, $04, $20   ; dy -8 dx +20 tile 4 attr $20
    db $f8, $0c, $05, $20   ; dy -8 dx +12 tile 5 attr $20
    db $f8, $34, $08, $00   ; dy -8 dx +52 tile 8 attr $00
    db $f0, $34, $06, $00   ; dy -16 dx +52 tile 6 attr $00
    db $f0, $3c, $07, $00   ; dy -16 dx +60 tile 7 attr $00
    db $f8, $2c, $17, $20   ; dy -8 dx +44 tile 23 attr $20
    db $f8, $04, $0c, $20   ; dy -8 dx +4 tile 12 attr $20
    db $f8, $3c, $19, $00   ; dy -8 dx +60 tile 25 attr $00
    db $f8, $f4, $1b, $20   ; dy -8 dx -12 tile 27 attr $20
    db $f8, $fc, $0b, $20   ; dy -8 dx -4 tile 11 attr $20
    db $80
Anim_0c_F12:   ; $7788 18 sprites
    db $f8, $08, $0c, $20   ; dy -8 dx +8 tile 12 attr $20
    db $f8, $00, $0d, $20   ; dy -8 dx +0 tile 13 attr $20
    db $f8, $18, $08, $20   ; dy -8 dx +24 tile 8 attr $20
    db $f8, $10, $09, $20   ; dy -8 dx +16 tile 9 attr $20
    db $f0, $18, $06, $20   ; dy -16 dx +24 tile 6 attr $20
    db $f0, $10, $07, $20   ; dy -16 dx +16 tile 7 attr $20
    db $f8, $20, $03, $00   ; dy -8 dx +32 tile 3 attr $00
    db $f8, $28, $04, $00   ; dy -8 dx +40 tile 4 attr $00
    db $f8, $30, $05, $00   ; dy -8 dx +48 tile 5 attr $00
    db $f0, $20, $00, $00   ; dy -16 dx +32 tile 0 attr $00
    db $f0, $28, $01, $00   ; dy -16 dx +40 tile 1 attr $00
    db $f0, $30, $02, $00   ; dy -16 dx +48 tile 2 attr $00
    db $f8, $40, $04, $20   ; dy -8 dx +64 tile 4 attr $20
    db $f8, $38, $05, $20   ; dy -8 dx +56 tile 5 attr $20
    db $f0, $48, $00, $20   ; dy -16 dx +72 tile 0 attr $20
    db $f0, $40, $01, $20   ; dy -16 dx +64 tile 1 attr $20
    db $f0, $38, $02, $20   ; dy -16 dx +56 tile 2 attr $20
    db $f8, $48, $1a, $00   ; dy -8 dx +72 tile 26 attr $00
    db $80
Anim_0c_F13:   ; $77d1 15 sprites
    db $f8, $3c, $03, $20   ; dy -8 dx +60 tile 3 attr $20
    db $f0, $3c, $00, $20   ; dy -16 dx +60 tile 0 attr $20
    db $f8, $44, $15, $20   ; dy -8 dx +68 tile 21 attr $20
    db $f0, $44, $12, $20   ; dy -16 dx +68 tile 18 attr $20
    db $f8, $34, $08, $20   ; dy -8 dx +52 tile 8 attr $20
    db $f8, $2c, $09, $20   ; dy -8 dx +44 tile 9 attr $20
    db $f0, $34, $06, $20   ; dy -16 dx +52 tile 6 attr $20
    db $f0, $2c, $07, $20   ; dy -16 dx +44 tile 7 attr $20
    db $f8, $24, $0b, $20   ; dy -8 dx +36 tile 11 attr $20
    db $f8, $1c, $0c, $20   ; dy -8 dx +28 tile 12 attr $20
    db $f8, $14, $0d, $20   ; dy -8 dx +20 tile 13 attr $20
    db $f8, $0c, $0e, $20   ; dy -8 dx +12 tile 14 attr $20
    db $e8, $4c, $20, $00   ; dy -24 dx +76 tile 32 attr $00
    db $f0, $4c, $21, $00   ; dy -16 dx +76 tile 33 attr $00
    db $f8, $4c, $22, $00   ; dy -8 dx +76 tile 34 attr $00
    db $80
Anim_0c_F14:   ; $780e 11 sprites
    db $f0, $48, $10, $00   ; dy -16 dx +72 tile 16 attr $00
    db $e8, $48, $0e, $00   ; dy -24 dx +72 tile 14 attr $00
    db $f0, $40, $01, $20   ; dy -16 dx +64 tile 1 attr $20
    db $f0, $38, $02, $20   ; dy -16 dx +56 tile 2 attr $20
    db $f8, $40, $04, $20   ; dy -8 dx +64 tile 4 attr $20
    db $f8, $38, $05, $20   ; dy -8 dx +56 tile 5 attr $20
    db $f8, $48, $16, $20   ; dy -8 dx +72 tile 22 attr $20
    db $f8, $28, $0b, $00   ; dy -8 dx +40 tile 11 attr $00
    db $f8, $30, $0c, $00   ; dy -8 dx +48 tile 12 attr $00
    db $f8, $18, $0d, $20   ; dy -8 dx +24 tile 13 attr $20
    db $f8, $20, $0c, $00   ; dy -8 dx +32 tile 12 attr $00
    db $80
Anim_0c_F15:   ; $783b 9 sprites
    db $f0, $44, $01, $20   ; dy -16 dx +68 tile 1 attr $20
    db $f0, $3c, $02, $20   ; dy -16 dx +60 tile 2 attr $20
    db $f8, $44, $04, $20   ; dy -8 dx +68 tile 4 attr $20
    db $f8, $3c, $05, $20   ; dy -8 dx +60 tile 5 attr $20
    db $f8, $34, $0c, $20   ; dy -8 dx +52 tile 12 attr $20
    db $f8, $24, $1b, $20   ; dy -8 dx +36 tile 27 attr $20
    db $f8, $2c, $0b, $20   ; dy -8 dx +44 tile 11 attr $20
    db $f0, $4c, $23, $00   ; dy -16 dx +76 tile 35 attr $00
    db $f8, $4c, $24, $00   ; dy -8 dx +76 tile 36 attr $00
    db $80
Anim_0c_F16:   ; $7860 5 sprites
    db $f0, $48, $02, $20   ; dy -16 dx +72 tile 2 attr $20
    db $f8, $48, $05, $20   ; dy -8 dx +72 tile 5 attr $20
    db $f8, $40, $0c, $20   ; dy -8 dx +64 tile 12 attr $20
    db $f8, $30, $1b, $20   ; dy -8 dx +48 tile 27 attr $20
    db $f8, $38, $0b, $20   ; dy -8 dx +56 tile 11 attr $20
    db $80
Anim_0c_F17:   ; $7875 3 sprites
    db $f8, $44, $0c, $20   ; dy -8 dx +68 tile 12 attr $20
    db $f8, $3c, $0d, $20   ; dy -8 dx +60 tile 13 attr $20
    db $f8, $4c, $25, $00   ; dy -8 dx +76 tile 37 attr $00
    db $80
Anim_0c_F18:   ; $7882 1 sprites
    db $f8, $48, $0e, $20   ; dy -8 dx +72 tile 14 attr $20
Anim_0c_F19:   ; $7886 empty frame = the $80 end above (shared)
    db $80
Anim_0d_SnowStorm:   ; $7887 animation $0d — SnowStorm, IceAir
    dw Anim_0d_F00
    dw Anim_0d_F01
    dw Anim_0d_F02
    dw Anim_0d_F03
    dw Anim_0d_F04
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
    dw Anim_0d_F05
Anim_0d_F00:   ; $78c7 4 sprites
    db $f8, $f8, $22, $00   ; dy -8 dx -8 tile 34 attr $00
    db $f8, $00, $23, $00   ; dy -8 dx +0 tile 35 attr $00
    db $f0, $f8, $20, $00   ; dy -16 dx -8 tile 32 attr $00
    db $f0, $00, $21, $00   ; dy -16 dx +0 tile 33 attr $00
    db $80
Anim_0d_F01:   ; $78d8 7 sprites
    db $f8, $f4, $1d, $00   ; dy -8 dx -12 tile 29 attr $00
    db $f8, $fc, $1e, $00   ; dy -8 dx -4 tile 30 attr $00
    db $f8, $04, $1f, $00   ; dy -8 dx +4 tile 31 attr $00
    db $f0, $f4, $1a, $00   ; dy -16 dx -12 tile 26 attr $00
    db $f0, $fc, $1b, $00   ; dy -16 dx -4 tile 27 attr $00
    db $f0, $04, $1c, $00   ; dy -16 dx +4 tile 28 attr $00
    db $e8, $fc, $19, $00   ; dy -24 dx -4 tile 25 attr $00
    db $80
Anim_0d_F02:   ; $78f5 14 sprites
    db $f0, $f4, $1d, $00   ; dy -16 dx -12 tile 29 attr $00
    db $f0, $fc, $1e, $00   ; dy -16 dx -4 tile 30 attr $00
    db $f0, $04, $1f, $00   ; dy -16 dx +4 tile 31 attr $00
    db $e8, $f4, $1a, $00   ; dy -24 dx -12 tile 26 attr $00
    db $e8, $fc, $1b, $00   ; dy -24 dx -4 tile 27 attr $00
    db $e8, $04, $1c, $00   ; dy -24 dx +4 tile 28 attr $00
    db $e0, $fc, $19, $00   ; dy -32 dx -4 tile 25 attr $00
    db $f8, $f4, $22, $00   ; dy -8 dx -12 tile 34 attr $00
    db $f8, $04, $23, $00   ; dy -8 dx +4 tile 35 attr $00
    db $f8, $fc, $0e, $00   ; dy -8 dx -4 tile 14 attr $00
    db $f8, $ec, $1f, $20   ; dy -8 dx -20 tile 31 attr $20
    db $f0, $ec, $1c, $20   ; dy -16 dx -20 tile 28 attr $20
    db $f8, $0c, $1d, $20   ; dy -8 dx +12 tile 29 attr $20
    db $f0, $0c, $1a, $20   ; dy -16 dx +12 tile 26 attr $20
    db $80
Anim_0d_F03:   ; $792e 25 sprites
    db $d0, $f8, $00, $20   ; dy -48 dx -8 tile 0 attr $20
    db $d8, $00, $01, $20   ; dy -40 dx +0 tile 1 attr $20
    db $d8, $f8, $02, $20   ; dy -40 dx -8 tile 2 attr $20
    db $e0, $00, $04, $20   ; dy -32 dx +0 tile 4 attr $20
    db $e0, $f8, $05, $20   ; dy -32 dx -8 tile 5 attr $20
    db $e0, $f0, $06, $20   ; dy -32 dx -16 tile 6 attr $20
    db $e8, $10, $07, $20   ; dy -24 dx +16 tile 7 attr $20
    db $e8, $08, $08, $20   ; dy -24 dx +8 tile 8 attr $20
    db $e8, $00, $09, $20   ; dy -24 dx +0 tile 9 attr $20
    db $e8, $f8, $0a, $20   ; dy -24 dx -8 tile 10 attr $20
    db $e8, $f0, $0b, $20   ; dy -24 dx -16 tile 11 attr $20
    db $e8, $e8, $0c, $20   ; dy -24 dx -24 tile 12 attr $20
    db $f0, $10, $0d, $20   ; dy -16 dx +16 tile 13 attr $20
    db $f0, $08, $0e, $20   ; dy -16 dx +8 tile 14 attr $20
    db $f0, $00, $0f, $20   ; dy -16 dx +0 tile 15 attr $20
    db $f0, $f8, $10, $20   ; dy -16 dx -8 tile 16 attr $20
    db $f0, $f0, $11, $20   ; dy -16 dx -16 tile 17 attr $20
    db $f0, $e8, $12, $20   ; dy -16 dx -24 tile 18 attr $20
    db $f8, $10, $13, $20   ; dy -8 dx +16 tile 19 attr $20
    db $f8, $08, $14, $20   ; dy -8 dx +8 tile 20 attr $20
    db $f8, $00, $15, $20   ; dy -8 dx +0 tile 21 attr $20
    db $f8, $f8, $16, $20   ; dy -8 dx -8 tile 22 attr $20
    db $f8, $f0, $17, $20   ; dy -8 dx -16 tile 23 attr $20
    db $f8, $e8, $18, $20   ; dy -8 dx -24 tile 24 attr $20
    db $e0, $0c, $03, $20   ; dy -32 dx +12 tile 3 attr $20
    db $80
Anim_0d_F04:   ; $7993 25 sprites
    db $d0, $00, $00, $00   ; dy -48 dx +0 tile 0 attr $00
    db $d8, $f8, $01, $00   ; dy -40 dx -8 tile 1 attr $00
    db $d8, $00, $02, $00   ; dy -40 dx +0 tile 2 attr $00
    db $e0, $f8, $04, $00   ; dy -32 dx -8 tile 4 attr $00
    db $e0, $00, $05, $00   ; dy -32 dx +0 tile 5 attr $00
    db $e0, $08, $06, $00   ; dy -32 dx +8 tile 6 attr $00
    db $e8, $e8, $07, $00   ; dy -24 dx -24 tile 7 attr $00
    db $e8, $f0, $08, $00   ; dy -24 dx -16 tile 8 attr $00
    db $e8, $f8, $09, $00   ; dy -24 dx -8 tile 9 attr $00
    db $e8, $00, $0a, $00   ; dy -24 dx +0 tile 10 attr $00
    db $e8, $08, $0b, $00   ; dy -24 dx +8 tile 11 attr $00
    db $e8, $10, $0c, $00   ; dy -24 dx +16 tile 12 attr $00
    db $f0, $e8, $0d, $00   ; dy -16 dx -24 tile 13 attr $00
    db $f0, $f0, $0e, $00   ; dy -16 dx -16 tile 14 attr $00
    db $f0, $f8, $0f, $00   ; dy -16 dx -8 tile 15 attr $00
    db $f0, $00, $10, $00   ; dy -16 dx +0 tile 16 attr $00
    db $f0, $08, $11, $00   ; dy -16 dx +8 tile 17 attr $00
    db $f0, $10, $12, $00   ; dy -16 dx +16 tile 18 attr $00
    db $f8, $e8, $13, $00   ; dy -8 dx -24 tile 19 attr $00
    db $f8, $f0, $14, $00   ; dy -8 dx -16 tile 20 attr $00
    db $f8, $f8, $15, $00   ; dy -8 dx -8 tile 21 attr $00
    db $f8, $00, $16, $00   ; dy -8 dx +0 tile 22 attr $00
    db $f8, $08, $17, $00   ; dy -8 dx +8 tile 23 attr $00
    db $f8, $10, $18, $00   ; dy -8 dx +16 tile 24 attr $00
    db $e0, $ec, $03, $00   ; dy -32 dx -20 tile 3 attr $00
Anim_0d_F05:   ; $79f7 empty frame = the $80 end above (shared)
    db $80
; NOTE: unreferenced fake-decode labels removed with this block: jr_05c_418b, jr_05c_419f, jr_05c_4237, jr_05c_4254, jr_05c_4291, jr_05c_4297, jr_05c_42a7, jr_05c_42ce, jr_05c_42d7, jr_05c_42ef, jr_05c_42fa, jr_05c_42fb, jr_05c_42fe, jr_05c_430a, jr_05c_431a, jr_05c_4326, jr_05c_432e, jr_05c_432f, jr_05c_4333, jr_05c_4347, jr_05c_4348, jr_05c_4375, jr_05c_4387, jr_05c_4389, jr_05c_43bd, jr_05c_43c7, jr_05c_43cf, jr_05c_43d3, jr_05c_43da, jr_05c_43e2, jr_05c_43e7, jr_05c_43f8, jr_05c_4431, jr_05c_4490, jr_05c_44a6, jr_05c_44aa, jr_05c_44ae, jr_05c_44c2, jr_05c_44c6, jr_05c_44ea, jr_05c_44eb, jr_05c_44ef, jr_05c_44f5, jr_05c_44fd, jr_05c_4507, jr_05c_450b, jr_05c_4517, jr_05c_4544, jr_05c_4545, jr_05c_455a, jr_05c_4565, jr_05c_4582, jr_05c_4587, jr_05c_459e, jr_05c_45d2, jr_05c_45da, jr_05c_45e7, jr_05c_45f2, jr_05c_45fe, jr_05c_4602, jr_05c_4606, jr_05c_4615, jr_05c_4650, jr_05c_46b9, jr_05c_46c7, jr_05c_4722, jr_05c_478a, jr_05c_4799, jr_05c_47f4, jr_05c_47fd, jr_05c_486b, jr_05c_4883, jr_05c_488f, jr_05c_48bc, jr_05c_48c8, jr_05c_48ec, jr_05c_4906, jr_05c_4915, jr_05c_49d1, jr_05c_49fa, jr_05c_4a1a, jr_05c_4ae8, jr_05c_4b00, jr_05c_4b02, jr_05c_4b27, jr_05c_4b41, jr_05c_4b48, jr_05c_4b4d, jr_05c_4b50, jr_05c_4b81, jr_05c_4bc0, jr_05c_4bc4, jr_05c_4bde, jr_05c_4c41, jr_05c_4c65, jr_05c_4c77, jr_05c_4c7b, jr_05c_4cc6, jr_05c_4cd0, jr_05c_4ce9, jr_05c_4cf2, jr_05c_4d00, jr_05c_4d28, jr_05c_4d40, jr_05c_4d6a, jr_05c_4da1, jr_05c_4da3, jr_05c_4db8, jr_05c_4db9, jr_05c_4dc5, jr_05c_4dcd, jr_05c_4dd1, jr_05c_4ddd, jr_05c_4de1, jr_05c_4dea, jr_05c_4e32, jr_05c_4e35, jr_05c_4e36, jr_05c_4e49, jr_05c_4e8b, jr_05c_4ea5, jr_05c_4ebd, jr_05c_4ed8, jr_05c_4f03, jr_05c_4f0f, jr_05c_4f18, jr_05c_4f1e, jr_05c_4f28, jr_05c_4f38, jr_05c_4f40, jr_05c_4f48, jr_05c_4fc8, jr_05c_4fcb, jr_05c_5030, jr_05c_5034, jr_05c_5073, jr_05c_50a3, jr_05c_50a7, jr_05c_50e4, jr_05c_50f0, jr_05c_5108, jr_05c_5148, jr_05c_514c, jr_05c_516c, jr_05c_5181, jr_05c_51a4, jr_05c_51ad, jr_05c_51cf, jr_05c_51fd, jr_05c_5205, jr_05c_5209, jr_05c_520d, jr_05c_5229, jr_05c_5242, jr_05c_5308, jr_05c_532e, jr_05c_5350, jr_05c_5358, jr_05c_5364, jr_05c_5368, jr_05c_536c, jr_05c_5378, jr_05c_5379, jr_05c_537f, jr_05c_5383, jr_05c_539d, jr_05c_53a5, jr_05c_53ad, jr_05c_53c5, jr_05c_53cd, jr_05c_53fc, jr_05c_5405, jr_05c_540e, jr_05c_541a, jr_05c_5436, jr_05c_543a, jr_05c_547e, jr_05c_54b0, jr_05c_54b4, jr_05c_54d5, jr_05c_54d9, jr_05c_54db, jr_05c_5543, jr_05c_5548, jr_05c_556c, jr_05c_557d, jr_05c_5582, jr_05c_559a, jr_05c_55b2, jr_05c_55b6, jr_05c_55ba, jr_05c_55e6, jr_05c_55f1, jr_05c_55f4, jr_05c_55f5, jr_05c_55f7, jr_05c_5603, jr_05c_5607, jr_05c_5609, jr_05c_560b, jr_05c_561b, jr_05c_561f, jr_05c_562b, jr_05c_564b, jr_05c_56a9, jr_05c_56ad, jr_05c_56c4, jr_05c_571a, jr_05c_5724, jr_05c_5728, jr_05c_5760, jr_05c_5764, jr_05c_576c, jr_05c_5778, jr_05c_5787, jr_05c_5791, jr_05c_57aa, jr_05c_57b5, jr_05c_57f6, jr_05c_57fa, jr_05c_57fe, jr_05c_5802, jr_05c_582e, jr_05c_5832, jr_05c_583e, jr_05c_5842, jr_05c_584f, jr_05c_585f, jr_05c_5865, jr_05c_588f, jr_05c_58b2, jr_05c_592b, jr_05c_592d, jr_05c_5930, jr_05c_593d, jr_05c_5945, jr_05c_5952, jr_05c_5971, jr_05c_5975, jr_05c_5982, jr_05c_5985, jr_05c_5987, jr_05c_5996, jr_05c_59a4, jr_05c_59aa, jr_05c_59af, jr_05c_59bb, jr_05c_5a1f, jr_05c_5a4e, jr_05c_5a7a, jr_05c_5a7b, jr_05c_5a8b, jr_05c_5ad0, jr_05c_5ad4, jr_05c_5ae4, jr_05c_5aec, jr_05c_5b38, jr_05c_5b48, jr_05c_5b70, jr_05c_5b93, jr_05c_5b99, jr_05c_5b9d, jr_05c_5bc6, jr_05c_5bd6, jr_05c_5bf0, jr_05c_5c29, jr_05c_5c79, jr_05c_5c8e, jr_05c_5c8f, jr_05c_5cde, jr_05c_5d41, jr_05c_5f4b, jr_05c_5f94, jr_05c_5fb8, jr_05c_5fe9, HramB5c_6008, SetB5c_600a, Jump_05c_600d, Jump_05c_600e, JmpB5c_601b, jr_05c_601d, jr_05c_602e, jr_05c_6032, jr_05c_6034, jr_05c_60a2, jr_05c_60b6, jr_05c_60db, jr_05c_6107, jr_05c_611b, jr_05c_611f, jr_05c_6120, jr_05c_6128, jr_05c_6134, jr_05c_6138, jr_05c_613c, jr_05c_6140, jr_05c_6144, jr_05c_6160, jr_05c_6168, jr_05c_6194, jr_05c_6198, jr_05c_61a1, jr_05c_61fc, jr_05c_621a, jr_05c_6261, jr_05c_628e, jr_05c_629f, jr_05c_62af, jr_05c_62b7, jr_05c_62bb, jr_05c_62cb, jr_05c_62d3, jr_05c_62db, jr_05c_631e, jr_05c_6360, jr_05c_636d, jr_05c_6371, jr_05c_637d, jr_05c_637f, jr_05c_6381, jr_05c_6385, jr_05c_6389, jr_05c_638d, jr_05c_6399, jr_05c_639d, jr_05c_63a1, jr_05c_63a5, jr_05c_63b1, jr_05c_63b5, jr_05c_63b9, jr_05c_63bd, jr_05c_63d8, jr_05c_63e5, jr_05c_63ed, jr_05c_63f1, jr_05c_63f5, jr_05c_63f6, jr_05c_641d, jr_05c_6457, jr_05c_6482, jr_05c_6497, jr_05c_64bc, jr_05c_64c7, jr_05c_64cb, jr_05c_64f4, jr_05c_6505, jr_05c_6509, jr_05c_650d, jr_05c_6519, jr_05c_651d, jr_05c_6521, jr_05c_6541, jr_05c_65d9, jr_05c_66f9, jr_05c_670c, jr_05c_67a4, jr_05c_680e, jr_05c_6836, jr_05c_68c7, jr_05c_68df, jr_05c_68e0, jr_05c_68eb, jr_05c_6919, jr_05c_6950, jr_05c_69ca, jr_05c_69d5, jr_05c_69e9, jr_05c_69ed, jr_05c_6a11, jr_05c_6a19, jr_05c_6aaf, jr_05c_6ac3, jr_05c_6ace, jr_05c_6af7, jr_05c_6afc, jr_05c_6b19, jr_05c_6b31, jr_05c_6b33, jr_05c_6b43, jr_05c_6b47, jr_05c_6b67, jr_05c_6bb8, jr_05c_6bcc, jr_05c_6bea, jr_05c_6bfc, jr_05c_6c85, jr_05c_6c92, jr_05c_6ca6, jr_05c_6ca9, jr_05c_6cb1, jr_05c_6cdf, jr_05c_6d16, jr_05c_6da4, jr_05c_6db3, jr_05c_6db8, jr_05c_6ddb, jr_05c_6dde, jr_05c_6de8, jr_05c_6e94, jr_05c_6f96, jr_05c_6fba, jr_05c_6fcf, jr_05c_7077, jr_05c_719c, jr_05c_71a1, jr_05c_71a5, jr_05c_724b, jr_05c_7252, jr_05c_726e, jr_05c_7273, jr_05c_7278, jr_05c_7295, jr_05c_72ad, jr_05c_72af, jr_05c_72b8, jr_05c_72fc, jr_05c_7301, jr_05c_731e, jr_05c_7344, jr_05c_7358, jr_05c_735c, jr_05c_7381, jr_05c_7392, jr_05c_7398, jr_05c_73a8, jr_05c_73cc, jr_05c_73d1, jr_05c_73d9, jr_05c_740d, jr_05c_7431, jr_05c_746c, jr_05c_7473, jr_05c_74b2, jr_05c_7504, jr_05c_7506, jr_05c_7508, jr_05c_7545, jr_05c_7552, jr_05c_7555, jr_05c_7571, jr_05c_7581, jr_05c_7592, jr_05c_75ae, jr_05c_75be, jr_05c_75c6, jr_05c_75f3, jr_05c_75f7, jr_05c_7602, jr_05c_7610, jr_05c_7614, jr_05c_7638, jr_05c_7669, jr_05c_7675, jr_05c_7691, jr_05c_76a2, jr_05c_76b2, jr_05c_76b6, jr_05c_76ce, jr_05c_76de, jr_05c_76e6, jr_05c_76ea, jr_05c_7717, jr_05c_7726, jr_05c_7734, jr_05c_775c, jr_05c_7760, jr_05c_777c, jr_05c_7785, jr_05c_778d, jr_05c_7799, jr_05c_779b, jr_05c_77a1, jr_05c_77a6, jr_05c_77b5, jr_05c_77c5, jr_05c_77c6, jr_05c_77cd, jr_05c_77ce, jr_05c_77da, jr_05c_77ea, jr_05c_77f2, jr_05c_77f6, jr_05c_7805, jr_05c_781b, jr_05c_781f, jr_05c_782a, jr_05c_7840, jr_05c_7844, jr_05c_7845, jr_05c_7848, jr_05c_784c, jr_05c_785d, jr_05c_7865, jr_05c_7869, jr_05c_787e, jr_05c_788a, jr_05c_78ae, jr_05c_78d3, jr_05c_790b, jr_05c_7913, jr_05c_791b, jr_05c_791f, jr_05c_7923, jr_05c_792f, jr_05c_7933, jr_05c_793b, jr_05c_793f, jr_05c_7943, jr_05c_7953, jr_05c_795b, jr_05c_795f, jr_05c_7963, jr_05c_796f, jr_05c_7973, jr_05c_797b, jr_05c_7983, jr_05c_79f3
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
