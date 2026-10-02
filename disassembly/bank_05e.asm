; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $05e", ROMX[$4000], BANK[$5e]
;All invalid jumps to external banks removed.
Jump_05e_4000:
    db $5E ; Bank number

    ; Cross-bank dispatch table (2 entries)
    ; Called via: ld hl, $5EXX / rst $10
    dw AnimTick5E             ; Entry 0
    dw $40CB                          ; Entry 1

AnimTick5E:
    ld a, [$dd60]
    or a
    ret z

Jump_05e_400a:
    ld de, $4071
    call AnimBuildOAM5E
    ld a, [$dd68]
    or a

JmpB5e_4014:
    jr z, jr_05e_4021

    ld a, [$daa4]
    cp $03
    jr z, jr_05e_4021

    cp $04
    jr nz, jr_05e_4031

jr_05e_4021:
    ld hl, $ffc3
    inc [hl]
    ld hl, $ffc3
    inc [hl]
    ld hl, $ffc3
    inc [hl]
    ld hl, $ffc3
    inc [hl]

jr_05e_4031:
    ld a, [$dd66]
    ldh [$c8], a
    ld a, [$dd62]
    or a
    jr nz, jr_05e_4041

    ld a, $00
    ld [$dd60], a

jr_05e_4041:
    ld a, [$dd68]
    or a
    ret nz

    ld a, [$daa4]
    cp $03
    jr z, jr_05e_4051

    cp $04
    jr nz, jr_05e_4061

jr_05e_4051:
    ldh a, [$c3]
    cp $d0
    ret c

    ld a, $04
    ld [$dd65], a
    ld a, $01
    ld [$dd68], a
    ret


jr_05e_4061:
    ldh a, [$c3]
    cp $c0
    ret c

    ld a, $00
    ld [$dd60], a
    ld a, $01
    ld [$dd68], a
    ret


AnimFrameTable5E:
    ; ANIMATION -> its 32 frame pointers, index [$c7] = animation number
    ; ($00-$0D bank $5C, $0E-$20 $5D, $21-$2C $5E — ROM0 AnimTickSelectAndDraw
    ; picks the bank). Re-sectioned S112.
    dw $418b   ; [$00] (another bank's number: an unused default)
    dw $418b   ; [$01] (another bank's number: an unused default)
    dw $418b   ; [$02] (another bank's number: an unused default)
    dw $418b   ; [$03] (another bank's number: an unused default)
    dw $418b   ; [$04] (another bank's number: an unused default)
    dw $418b   ; [$05] (another bank's number: an unused default)
    dw $418b   ; [$06] (another bank's number: an unused default)
    dw $418b   ; [$07] (another bank's number: an unused default)
    dw $418b   ; [$08] (another bank's number: an unused default)
    dw $418b   ; [$09] (another bank's number: an unused default)
    dw $418b   ; [$0a] (another bank's number: an unused default)
    dw $418b   ; [$0b] (another bank's number: an unused default)
    dw $418b   ; [$0c] (another bank's number: an unused default)
    dw $418b   ; [$0d] (another bank's number: an unused default)
    dw $418b   ; [$0e] (another bank's number: an unused default)
    dw $418b   ; [$0f] (another bank's number: an unused default)
    dw $418b   ; [$10] (another bank's number: an unused default)
    dw $418b   ; [$11] (another bank's number: an unused default)
    dw $418b   ; [$12] (another bank's number: an unused default)
    dw $418b   ; [$13] (another bank's number: an unused default)
    dw $418b   ; [$14] (another bank's number: an unused default)
    dw $418b   ; [$15] (another bank's number: an unused default)
    dw $418b   ; [$16] (another bank's number: an unused default)
    dw $418b   ; [$17] (another bank's number: an unused default)
    dw $418b   ; [$18] (another bank's number: an unused default)
    dw $418b   ; [$19] (another bank's number: an unused default)
    dw $418b   ; [$1a] (another bank's number: an unused default)
    dw $418b   ; [$1b] (another bank's number: an unused default)
    dw $418b   ; [$1c] (another bank's number: an unused default)
    dw $418b   ; [$1d] (another bank's number: an unused default)
    dw $418b   ; [$1e] (another bank's number: an unused default)
    dw $418b   ; [$1f] (another bank's number: an unused default)
    dw $418b   ; [$20] (another bank's number: an unused default)
    dw Anim_21_IceSlash      ; [$21] IceSlash
    dw Anim_22_Smashlime     ; [$22] Smashlime, Sheldodge
    dw Anim_23_BirdBlow      ; [$23] BirdBlow
    dw Anim_24_DevilCut      ; [$24] DevilCut, ZombieCut
    dw Anim_25_MetalCut      ; [$25] MetalCut, CleanCut
    dw Anim_26_GigaSlash     ; [$26] GigaSlash
    dw Anim_27_MultiCut      ; [$27] MultiCut
    dw Anim_28_Hellblast     ; [$28] Hellblast
    dw Anim_29_BigBang       ; [$29] BigBang
    dw Anim_2a_MegaMagic     ; [$2a] MegaMagic
    dw Anim_2b_DeMagic       ; [$2b] DeMagic
    dw Anim_2c_FEEDMEAT      ; [$2c] FEEDMEAT, BEFFJERKY, PORKCHOP, SIRLOIN
; bank $5E entry 1: start an animation — X from AnimTargetXTable5E[$db54] when [$dd68] != 0 (else 0 = fly in from the left), Y $60, [$c7] = [$daa4], [$c8] = its first frame (bank $02 entry 5) (S112)
AnimInit5E:
    ld a, $01
    ld [$dd62], a
    ld a, [$dd68]
    or a
    jr z, jr_05e_40e8

    ld a, [$db54]
    cp $07
    jr nc, jr_05e_4123

    add a
    ld hl, $412c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]

jr_05e_40e8:
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


jr_05e_4123:
    xor a
    ld [$dd60], a
    xor a
    ld [$dd62], a
    ret


AnimTargetXTable5E:
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
; NOTE: unreferenced fake-decode labels removed with this block: jr_05e_4132, jr_05e_4136
AnimBuildOAM5E:
    ldh a, [$cb]
    cp $28
    jr nc, jr_05e_418a

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

jr_05e_415d:
    ld a, [de]
    inc de
    cp $80
    jr z, jr_05e_418a

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
    jr c, jr_05e_415d

jr_05e_418a:
    ret


; ============================================================================
; BATTLE ANIMATION DATA (bank $5E): per animation 32 dw frame pointers
; (unused slots point at an empty frame; slot $1F = the blank) and the
; frames: 4-byte sprites (dy, dx, tile, attr) — X = dx + [$c3] + 8,
; Y = dy + [$c5] + 16, tile + [$c9], attr XOR [$ca] — $80 end; the builder
; draws at most 40. MEASURED S112 (tools/census_battle_anims.py: all 45
; animations, every frame == the shadow OAM). Re-sectioned S112.
; ============================================================================
Anim_21_IceSlash:   ; $418b animation $21 — IceSlash
    dw Anim_21_F00
    dw Anim_21_F01
    dw Anim_21_F02
    dw Anim_21_F03
    dw Anim_21_F04
    dw Anim_21_F05
    dw Anim_21_F06
    dw Anim_21_F07
    dw Anim_21_F08
    dw Anim_21_F09
    dw Anim_21_F10
    dw Anim_21_F11
    dw Anim_21_F12
    dw Anim_21_F12
    dw Anim_21_F12
    dw Anim_21_F12
    dw Anim_21_F12
    dw Anim_21_F12
    dw Anim_21_F12
    dw Anim_21_F12
    dw Anim_21_F12
    dw Anim_21_F12
    dw Anim_21_F12
    dw Anim_21_F12
    dw Anim_21_F12
    dw Anim_21_F12
    dw Anim_21_F12
    dw Anim_21_F12
    dw Anim_21_F12
    dw Anim_21_F12
    dw Anim_21_F12
    dw Anim_21_F12
Anim_21_F00:   ; $41cb 4 sprites
    db $d8, $03, $20, $00   ; dy -40 dx +3 tile 32 attr $00
    db $d8, $0b, $21, $00   ; dy -40 dx +11 tile 33 attr $00
    db $d0, $03, $22, $00   ; dy -48 dx +3 tile 34 attr $00
    db $d0, $0b, $23, $00   ; dy -48 dx +11 tile 35 attr $00
    db $80
Anim_21_F01:   ; $41dc 8 sprites
    db $dc, $00, $20, $00   ; dy -36 dx +0 tile 32 attr $00
    db $dc, $08, $21, $00   ; dy -36 dx +8 tile 33 attr $00
    db $d4, $00, $22, $00   ; dy -44 dx +0 tile 34 attr $00
    db $d4, $08, $23, $00   ; dy -44 dx +8 tile 35 attr $00
    db $e4, $f8, $20, $60   ; dy -28 dx -8 tile 32 attr $60
    db $e4, $f0, $21, $60   ; dy -28 dx -16 tile 33 attr $60
    db $ec, $f8, $22, $60   ; dy -20 dx -8 tile 34 attr $60
    db $ec, $f0, $23, $60   ; dy -20 dx -16 tile 35 attr $60
    db $80
Anim_21_F02:   ; $41fd 10 sprites
    db $f0, $f4, $2c, $00   ; dy -16 dx -12 tile 44 attr $00
    db $f8, $f0, $2d, $00   ; dy -8 dx -16 tile 45 attr $00
    db $e8, $f8, $2a, $00   ; dy -24 dx -8 tile 42 attr $00
    db $e8, $00, $2b, $00   ; dy -24 dx +0 tile 43 attr $00
    db $d0, $04, $24, $00   ; dy -48 dx +4 tile 36 attr $00
    db $d0, $0c, $25, $00   ; dy -48 dx +12 tile 37 attr $00
    db $d8, $00, $26, $00   ; dy -40 dx +0 tile 38 attr $00
    db $d8, $08, $27, $00   ; dy -40 dx +8 tile 39 attr $00
    db $e0, $fb, $28, $00   ; dy -32 dx -5 tile 40 attr $00
    db $e0, $03, $29, $00   ; dy -32 dx +3 tile 41 attr $00
    db $80
Anim_21_F03:   ; $4226 12 sprites
    db $f8, $f0, $2c, $00   ; dy -8 dx -16 tile 44 attr $00
    db $f0, $ec, $2e, $00   ; dy -16 dx -20 tile 46 attr $00
    db $d8, $08, $25, $00   ; dy -40 dx +8 tile 37 attr $00
    db $d0, $0c, $2e, $00   ; dy -48 dx +12 tile 46 attr $00
    db $d0, $04, $24, $00   ; dy -48 dx +4 tile 36 attr $00
    db $d8, $00, $28, $40   ; dy -40 dx +0 tile 40 attr $40
    db $e0, $fc, $26, $00   ; dy -32 dx -4 tile 38 attr $00
    db $e0, $04, $27, $00   ; dy -32 dx +4 tile 39 attr $00
    db $e8, $f7, $28, $00   ; dy -24 dx -9 tile 40 attr $00
    db $e8, $ff, $29, $00   ; dy -24 dx -1 tile 41 attr $00
    db $f0, $f4, $2a, $00   ; dy -16 dx -12 tile 42 attr $00
    db $f0, $fc, $2b, $00   ; dy -16 dx -4 tile 43 attr $00
    db $80
Anim_21_F04:   ; $4257 7 sprites
    db $f8, $ee, $2e, $00   ; dy -8 dx -18 tile 46 attr $00
    db $f0, $f3, $2e, $00   ; dy -16 dx -13 tile 46 attr $00
    db $e8, $f8, $2e, $00   ; dy -24 dx -8 tile 46 attr $00
    db $e0, $fe, $2e, $00   ; dy -32 dx -2 tile 46 attr $00
    db $d8, $03, $2e, $00   ; dy -40 dx +3 tile 46 attr $00
    db $d0, $08, $2e, $00   ; dy -48 dx +8 tile 46 attr $00
    db $e0, $f6, $24, $00   ; dy -32 dx -10 tile 36 attr $00
    db $80
Anim_21_F05:   ; $4274 6 sprites
    db $f8, $ee, $2e, $00   ; dy -8 dx -18 tile 46 attr $00
    db $f0, $f3, $2e, $00   ; dy -16 dx -13 tile 46 attr $00
    db $e8, $f8, $2e, $00   ; dy -24 dx -8 tile 46 attr $00
    db $e0, $fe, $2f, $00   ; dy -32 dx -2 tile 47 attr $00
    db $d8, $03, $2f, $00   ; dy -40 dx +3 tile 47 attr $00
    db $f8, $e6, $24, $00   ; dy -8 dx -26 tile 36 attr $00
    db $80
Anim_21_F06:   ; $428d 3 sprites
    db $f8, $f0, $2f, $00   ; dy -8 dx -16 tile 47 attr $00
    db $f0, $f5, $2f, $00   ; dy -16 dx -11 tile 47 attr $00
    db $e8, $fa, $2f, $00   ; dy -24 dx -6 tile 47 attr $00
    db $80
Anim_21_F07:   ; $429a 3 sprites
    db $f8, $f8, $1c, $00   ; dy -8 dx -8 tile 28 attr $00
    db $f8, $00, $1e, $00   ; dy -8 dx +0 tile 30 attr $00
    db $f0, $fd, $1f, $00   ; dy -16 dx -3 tile 31 attr $00
    db $80
Anim_21_F08:   ; $42a7 7 sprites
    db $f8, $fc, $1d, $00   ; dy -8 dx -4 tile 29 attr $00
    db $f8, $04, $1e, $00   ; dy -8 dx +4 tile 30 attr $00
    db $f0, $fc, $1a, $00   ; dy -16 dx -4 tile 26 attr $00
    db $f0, $04, $1b, $00   ; dy -16 dx +4 tile 27 attr $00
    db $f8, $f4, $1c, $00   ; dy -8 dx -12 tile 28 attr $00
    db $f0, $f4, $19, $00   ; dy -16 dx -12 tile 25 attr $00
    db $ea, $fa, $00, $20   ; dy -22 dx -6 tile 0 attr $20
    db $80
Anim_21_F09:   ; $42c4 14 sprites
    db $f8, $fc, $0e, $00   ; dy -8 dx -4 tile 14 attr $00
    db $e8, $fc, $1a, $20   ; dy -24 dx -4 tile 26 attr $20
    db $e8, $f4, $1b, $20   ; dy -24 dx -12 tile 27 attr $20
    db $f0, $fc, $1d, $20   ; dy -16 dx -4 tile 29 attr $20
    db $f8, $f4, $14, $00   ; dy -8 dx -12 tile 20 attr $00
    db $f8, $04, $16, $00   ; dy -8 dx +4 tile 22 attr $00
    db $f0, $0c, $19, $20   ; dy -16 dx +12 tile 25 attr $20
    db $f8, $0c, $1c, $20   ; dy -8 dx +12 tile 28 attr $20
    db $f0, $ec, $1b, $20   ; dy -16 dx -20 tile 27 attr $20
    db $f8, $ec, $1e, $20   ; dy -8 dx -20 tile 30 attr $20
    db $e2, $fe, $00, $00   ; dy -30 dx -2 tile 0 attr $00
    db $e8, $04, $0c, $00   ; dy -24 dx +4 tile 12 attr $00
    db $f0, $04, $1e, $00   ; dy -16 dx +4 tile 30 attr $00
    db $f0, $f4, $0e, $00   ; dy -16 dx -12 tile 14 attr $00
    db $80
Anim_21_F10:   ; $42fd 25 sprites
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
Anim_21_F11:   ; $4362 25 sprites
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
Anim_21_F12:   ; $43c6 empty frame = the $80 end above (shared)
    db $80
Anim_22_Smashlime:   ; $43c7 animation $22 — Smashlime, Sheldodge
    dw Anim_22_F00
    dw Anim_22_F01
    dw Anim_22_F02
    dw Anim_22_F03
    dw Anim_22_F04
    dw Anim_22_F05
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
    dw Anim_22_F06
Anim_22_F00:   ; $4407 2 sprites
    db $d0, $f8, $04, $00   ; dy -48 dx -8 tile 4 attr $00
    db $d0, $00, $05, $00   ; dy -48 dx +0 tile 5 attr $00
    db $80
Anim_22_F01:   ; $4410 6 sprites
    db $e0, $f8, $04, $00   ; dy -32 dx -8 tile 4 attr $00
    db $e0, $00, $05, $00   ; dy -32 dx +0 tile 5 attr $00
    db $d8, $f8, $02, $00   ; dy -40 dx -8 tile 2 attr $00
    db $d8, $00, $03, $00   ; dy -40 dx +0 tile 3 attr $00
    db $d0, $f8, $00, $00   ; dy -48 dx -8 tile 0 attr $00
    db $d0, $00, $01, $00   ; dy -48 dx +0 tile 1 attr $00
    db $80
Anim_22_F02:   ; $4429 6 sprites
    db $dc, $f8, $17, $00   ; dy -36 dx -8 tile 23 attr $00
    db $dc, $00, $17, $20   ; dy -36 dx +0 tile 23 attr $20
    db $e4, $f0, $15, $00   ; dy -28 dx -16 tile 21 attr $00
    db $e4, $f8, $16, $00   ; dy -28 dx -8 tile 22 attr $00
    db $e4, $08, $15, $20   ; dy -28 dx +8 tile 21 attr $20
    db $e4, $00, $16, $20   ; dy -28 dx +0 tile 22 attr $20
    db $80
Anim_22_F03:   ; $4442 6 sprites
    db $e4, $00, $07, $00   ; dy -28 dx +0 tile 7 attr $00
    db $e4, $08, $08, $00   ; dy -28 dx +8 tile 8 attr $00
    db $e4, $f8, $07, $20   ; dy -28 dx -8 tile 7 attr $20
    db $e4, $f0, $08, $20   ; dy -28 dx -16 tile 8 attr $20
    db $dc, $f8, $00, $00   ; dy -36 dx -8 tile 0 attr $00
    db $dc, $00, $01, $00   ; dy -36 dx +0 tile 1 attr $00
    db $80
Anim_22_F04:   ; $445b 16 sprites
    db $d4, $f8, $0d, $20   ; dy -44 dx -8 tile 13 attr $20
    db $d4, $f0, $0e, $20   ; dy -44 dx -16 tile 14 attr $20
    db $d4, $00, $0d, $00   ; dy -44 dx +0 tile 13 attr $00
    db $d4, $08, $0e, $00   ; dy -44 dx +8 tile 14 attr $00
    db $dc, $00, $0f, $00   ; dy -36 dx +0 tile 15 attr $00
    db $dc, $08, $10, $00   ; dy -36 dx +8 tile 16 attr $00
    db $dc, $10, $11, $00   ; dy -36 dx +16 tile 17 attr $00
    db $dc, $f0, $10, $20   ; dy -36 dx -16 tile 16 attr $20
    db $dc, $e8, $11, $20   ; dy -36 dx -24 tile 17 attr $20
    db $dc, $f8, $0f, $20   ; dy -36 dx -8 tile 15 attr $20
    db $e4, $f8, $12, $20   ; dy -28 dx -8 tile 18 attr $20
    db $e4, $f0, $13, $20   ; dy -28 dx -16 tile 19 attr $20
    db $e4, $e8, $14, $20   ; dy -28 dx -24 tile 20 attr $20
    db $e4, $00, $12, $00   ; dy -28 dx +0 tile 18 attr $00
    db $e4, $08, $13, $00   ; dy -28 dx +8 tile 19 attr $00
    db $e4, $10, $14, $00   ; dy -28 dx +16 tile 20 attr $00
    db $80
Anim_22_F05:   ; $449c 8 sprites
    db $dc, $f8, $09, $20   ; dy -36 dx -8 tile 9 attr $20
    db $dc, $f0, $0a, $20   ; dy -36 dx -16 tile 10 attr $20
    db $dc, $00, $09, $00   ; dy -36 dx +0 tile 9 attr $00
    db $dc, $08, $0a, $00   ; dy -36 dx +8 tile 10 attr $00
    db $e4, $f8, $0b, $20   ; dy -28 dx -8 tile 11 attr $20
    db $e4, $f0, $0c, $20   ; dy -28 dx -16 tile 12 attr $20
    db $e4, $00, $0b, $00   ; dy -28 dx +0 tile 11 attr $00
    db $e4, $08, $0c, $00   ; dy -28 dx +8 tile 12 attr $00
Anim_22_F06:   ; $44bc empty frame = the $80 end above (shared)
    db $80
Anim_23_BirdBlow:   ; $44bd animation $23 — BirdBlow
    dw Anim_23_F00
    dw Anim_23_F01
    dw Anim_23_F02
    dw Anim_23_F03
    dw Anim_23_F04
    dw Anim_23_F05
    dw Anim_23_F06
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
    dw Anim_23_F07
Anim_23_F00:   ; $44fd 2 sprites
    db $f8, $f0, $00, $60   ; dy -8 dx -16 tile 0 attr $60
    db $f8, $e8, $01, $60   ; dy -8 dx -24 tile 1 attr $60
    db $80
Anim_23_F01:   ; $4506 4 sprites
    db $f7, $f5, $00, $60   ; dy -9 dx -11 tile 0 attr $60
    db $f7, $ed, $01, $60   ; dy -9 dx -19 tile 1 attr $60
    db $f1, $fd, $00, $00   ; dy -15 dx -3 tile 0 attr $00
    db $f1, $05, $01, $00   ; dy -15 dx +5 tile 1 attr $00
    db $80
Anim_23_F02:   ; $4517 11 sprites
    db $f8, $f0, $0b, $00   ; dy -8 dx -16 tile 11 attr $00
    db $f8, $f8, $0c, $00   ; dy -8 dx -8 tile 12 attr $00
    db $f0, $fc, $09, $00   ; dy -16 dx -4 tile 9 attr $00
    db $f0, $04, $0a, $00   ; dy -16 dx +4 tile 10 attr $00
    db $e0, $08, $05, $00   ; dy -32 dx +8 tile 5 attr $00
    db $e0, $10, $06, $00   ; dy -32 dx +16 tile 6 attr $00
    db $e8, $04, $07, $00   ; dy -24 dx +4 tile 7 attr $00
    db $e8, $0c, $08, $00   ; dy -24 dx +12 tile 8 attr $00
    db $d8, $10, $04, $00   ; dy -40 dx +16 tile 4 attr $00
    db $d0, $08, $02, $00   ; dy -48 dx +8 tile 2 attr $00
    db $d0, $10, $03, $00   ; dy -48 dx +16 tile 3 attr $00
    db $80
Anim_23_F03:   ; $4544 16 sprites
    db $f8, $f0, $0b, $00   ; dy -8 dx -16 tile 11 attr $00
    db $f8, $f8, $0c, $00   ; dy -8 dx -8 tile 12 attr $00
    db $f0, $fc, $09, $00   ; dy -16 dx -4 tile 9 attr $00
    db $f0, $04, $0a, $00   ; dy -16 dx +4 tile 10 attr $00
    db $e8, $04, $07, $00   ; dy -24 dx +4 tile 7 attr $00
    db $e8, $0c, $08, $00   ; dy -24 dx +12 tile 8 attr $00
    db $e0, $08, $0d, $00   ; dy -32 dx +8 tile 13 attr $00
    db $e0, $10, $0e, $00   ; dy -32 dx +16 tile 14 attr $00
    db $d8, $08, $0f, $00   ; dy -40 dx +8 tile 15 attr $00
    db $d8, $10, $10, $00   ; dy -40 dx +16 tile 16 attr $00
    db $d0, $fc, $11, $00   ; dy -48 dx -4 tile 17 attr $00
    db $d0, $04, $12, $00   ; dy -48 dx +4 tile 18 attr $00
    db $d0, $0c, $13, $00   ; dy -48 dx +12 tile 19 attr $00
    db $d8, $ee, $14, $00   ; dy -40 dx -18 tile 20 attr $00
    db $d8, $f6, $15, $00   ; dy -40 dx -10 tile 21 attr $00
    db $e0, $e8, $16, $00   ; dy -32 dx -24 tile 22 attr $00
    db $80
Anim_23_F04:   ; $4585 15 sprites
    db $f8, $f0, $0b, $00   ; dy -8 dx -16 tile 11 attr $00
    db $f8, $f8, $0c, $00   ; dy -8 dx -8 tile 12 attr $00
    db $d0, $fc, $17, $00   ; dy -48 dx -4 tile 23 attr $00
    db $d0, $04, $18, $00   ; dy -48 dx +4 tile 24 attr $00
    db $d0, $0c, $19, $00   ; dy -48 dx +12 tile 25 attr $00
    db $d8, $ec, $1a, $00   ; dy -40 dx -20 tile 26 attr $00
    db $d8, $f4, $1b, $00   ; dy -40 dx -12 tile 27 attr $00
    db $d8, $fc, $1c, $00   ; dy -40 dx -4 tile 28 attr $00
    db $d8, $08, $1d, $00   ; dy -40 dx +8 tile 29 attr $00
    db $d8, $10, $1e, $00   ; dy -40 dx +16 tile 30 attr $00
    db $e0, $e8, $1f, $00   ; dy -32 dx -24 tile 31 attr $00
    db $e0, $10, $20, $00   ; dy -32 dx +16 tile 32 attr $00
    db $e8, $0c, $28, $00   ; dy -24 dx +12 tile 40 attr $00
    db $f0, $fc, $29, $00   ; dy -16 dx -4 tile 41 attr $00
    db $f0, $04, $2a, $00   ; dy -16 dx +4 tile 42 attr $00
    db $80
Anim_23_F05:   ; $45c2 8 sprites
    db $e0, $e8, $1f, $00   ; dy -32 dx -24 tile 31 attr $00
    db $e0, $10, $27, $00   ; dy -32 dx +16 tile 39 attr $00
    db $d8, $10, $26, $00   ; dy -40 dx +16 tile 38 attr $00
    db $d0, $fc, $21, $00   ; dy -48 dx -4 tile 33 attr $00
    db $d0, $04, $22, $00   ; dy -48 dx +4 tile 34 attr $00
    db $d0, $0c, $23, $00   ; dy -48 dx +12 tile 35 attr $00
    db $d8, $ee, $24, $00   ; dy -40 dx -18 tile 36 attr $00
    db $d8, $f6, $25, $00   ; dy -40 dx -10 tile 37 attr $00
    db $80
Anim_23_F06:   ; $45e3 2 sprites
    db $e0, $e8, $1f, $00   ; dy -32 dx -24 tile 31 attr $00
    db $d8, $ee, $24, $00   ; dy -40 dx -18 tile 36 attr $00
Anim_23_F07:   ; $45eb empty frame = the $80 end above (shared)
    db $80
Anim_24_DevilCut:   ; $45ec animation $24 — DevilCut, ZombieCut
    dw Anim_24_F00
    dw Anim_24_F01
    dw Anim_24_F02
    dw Anim_24_F03
    dw Anim_24_F04
    dw Anim_24_F05
    dw Anim_24_F06
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
    dw Anim_24_F07
Anim_24_F00:   ; $462c 2 sprites
    db $d8, $fc, $00, $00   ; dy -40 dx -4 tile 0 attr $00
    db $d0, $fc, $01, $00   ; dy -48 dx -4 tile 1 attr $00
    db $80
Anim_24_F01:   ; $4635 6 sprites
    db $d0, $f8, $05, $00   ; dy -48 dx -8 tile 5 attr $00
    db $d8, $f8, $08, $00   ; dy -40 dx -8 tile 8 attr $00
    db $e0, $fc, $01, $00   ; dy -32 dx -4 tile 1 attr $00
    db $d0, $fc, $03, $00   ; dy -48 dx -4 tile 3 attr $00
    db $d8, $fc, $02, $00   ; dy -40 dx -4 tile 2 attr $00
    db $e8, $fc, $0b, $00   ; dy -24 dx -4 tile 11 attr $00
    db $80
Anim_24_F02:   ; $464e 17 sprites
    db $d0, $f8, $05, $00   ; dy -48 dx -8 tile 5 attr $00
    db $d8, $f0, $07, $00   ; dy -40 dx -16 tile 7 attr $00
    db $d8, $f8, $08, $00   ; dy -40 dx -8 tile 8 attr $00
    db $d8, $e8, $06, $00   ; dy -40 dx -24 tile 6 attr $00
    db $f8, $fc, $00, $00   ; dy -8 dx -4 tile 0 attr $00
    db $f0, $fc, $01, $00   ; dy -16 dx -4 tile 1 attr $00
    db $d8, $fc, $04, $00   ; dy -40 dx -4 tile 4 attr $00
    db $d0, $fc, $04, $00   ; dy -48 dx -4 tile 4 attr $00
    db $e8, $fc, $0f, $00   ; dy -24 dx -4 tile 15 attr $00
    db $e0, $fc, $0d, $00   ; dy -32 dx -4 tile 13 attr $00
    db $e0, $f4, $0c, $00   ; dy -32 dx -12 tile 12 attr $00
    db $e8, $f4, $0e, $00   ; dy -24 dx -12 tile 14 attr $00
    db $e0, $03, $0c, $20   ; dy -32 dx +3 tile 12 attr $20
    db $e8, $03, $0e, $20   ; dy -24 dx +3 tile 14 attr $20
    db $e0, $e8, $06, $40   ; dy -32 dx -24 tile 6 attr $40
    db $e0, $f0, $07, $40   ; dy -32 dx -16 tile 7 attr $40
    db $e0, $f8, $08, $40   ; dy -32 dx -8 tile 8 attr $40
    db $80
Anim_24_F03:   ; $4693 17 sprites
    db $d0, $f8, $05, $00   ; dy -48 dx -8 tile 5 attr $00
    db $d8, $f0, $07, $00   ; dy -40 dx -16 tile 7 attr $00
    db $d8, $f8, $08, $00   ; dy -40 dx -8 tile 8 attr $00
    db $d8, $e8, $06, $00   ; dy -40 dx -24 tile 6 attr $00
    db $e0, $e8, $06, $40   ; dy -32 dx -24 tile 6 attr $40
    db $e0, $f0, $07, $40   ; dy -32 dx -16 tile 7 attr $40
    db $e0, $f8, $08, $40   ; dy -32 dx -8 tile 8 attr $40
    db $f0, $fc, $04, $00   ; dy -16 dx -4 tile 4 attr $00
    db $e0, $fc, $04, $00   ; dy -32 dx -4 tile 4 attr $00
    db $d8, $fc, $04, $00   ; dy -40 dx -4 tile 4 attr $00
    db $d0, $fc, $04, $00   ; dy -48 dx -4 tile 4 attr $00
    db $f8, $fc, $03, $00   ; dy -8 dx -4 tile 3 attr $00
    db $f8, $00, $0a, $20   ; dy -8 dx +0 tile 10 attr $20
    db $e8, $fc, $0b, $00   ; dy -24 dx -4 tile 11 attr $00
    db $e8, $f8, $09, $00   ; dy -24 dx -8 tile 9 attr $00
    db $f0, $f8, $09, $00   ; dy -16 dx -8 tile 9 attr $00
    db $f8, $f8, $0a, $00   ; dy -8 dx -8 tile 10 attr $00
    db $80
Anim_24_F04:   ; $46d8 17 sprites
    db $d0, $f8, $05, $00   ; dy -48 dx -8 tile 5 attr $00
    db $d8, $f0, $07, $00   ; dy -40 dx -16 tile 7 attr $00
    db $d8, $f8, $08, $00   ; dy -40 dx -8 tile 8 attr $00
    db $d8, $e8, $06, $00   ; dy -40 dx -24 tile 6 attr $00
    db $e0, $e8, $06, $40   ; dy -32 dx -24 tile 6 attr $40
    db $e0, $f0, $07, $40   ; dy -32 dx -16 tile 7 attr $40
    db $f8, $fc, $04, $00   ; dy -8 dx -4 tile 4 attr $00
    db $f0, $fc, $04, $00   ; dy -16 dx -4 tile 4 attr $00
    db $e8, $fc, $04, $00   ; dy -24 dx -4 tile 4 attr $00
    db $e0, $f8, $08, $40   ; dy -32 dx -8 tile 8 attr $40
    db $e8, $f8, $09, $00   ; dy -24 dx -8 tile 9 attr $00
    db $f0, $f8, $09, $00   ; dy -16 dx -8 tile 9 attr $00
    db $f8, $f8, $0a, $00   ; dy -8 dx -8 tile 10 attr $00
    db $e0, $00, $08, $60   ; dy -32 dx +0 tile 8 attr $60
    db $e8, $00, $09, $20   ; dy -24 dx +0 tile 9 attr $20
    db $f0, $00, $09, $20   ; dy -16 dx +0 tile 9 attr $20
    db $f8, $00, $0a, $20   ; dy -8 dx +0 tile 10 attr $20
    db $80
Anim_24_F05:   ; $471d 18 sprites
    db $d0, $f8, $05, $00   ; dy -48 dx -8 tile 5 attr $00
    db $d8, $f0, $07, $00   ; dy -40 dx -16 tile 7 attr $00
    db $d8, $f8, $08, $00   ; dy -40 dx -8 tile 8 attr $00
    db $d8, $e8, $06, $00   ; dy -40 dx -24 tile 6 attr $00
    db $e0, $e8, $06, $40   ; dy -32 dx -24 tile 6 attr $40
    db $e0, $f0, $07, $40   ; dy -32 dx -16 tile 7 attr $40
    db $e0, $f8, $08, $40   ; dy -32 dx -8 tile 8 attr $40
    db $e8, $f8, $09, $00   ; dy -24 dx -8 tile 9 attr $00
    db $f0, $f8, $09, $00   ; dy -16 dx -8 tile 9 attr $00
    db $f8, $f8, $0a, $00   ; dy -8 dx -8 tile 10 attr $00
    db $e8, $00, $09, $20   ; dy -24 dx +0 tile 9 attr $20
    db $f0, $00, $09, $20   ; dy -16 dx +0 tile 9 attr $20
    db $f8, $00, $0a, $20   ; dy -8 dx +0 tile 10 attr $20
    db $d8, $08, $07, $20   ; dy -40 dx +8 tile 7 attr $20
    db $d8, $10, $06, $20   ; dy -40 dx +16 tile 6 attr $20
    db $e0, $10, $06, $60   ; dy -32 dx +16 tile 6 attr $60
    db $e0, $08, $07, $60   ; dy -32 dx +8 tile 7 attr $60
    db $e0, $00, $08, $60   ; dy -32 dx +0 tile 8 attr $60
    db $80
Anim_24_F06:   ; $4766 20 sprites
    db $d0, $f8, $05, $00   ; dy -48 dx -8 tile 5 attr $00
    db $d8, $f0, $07, $00   ; dy -40 dx -16 tile 7 attr $00
    db $d8, $f8, $08, $00   ; dy -40 dx -8 tile 8 attr $00
    db $d8, $e8, $06, $00   ; dy -40 dx -24 tile 6 attr $00
    db $e0, $e8, $06, $40   ; dy -32 dx -24 tile 6 attr $40
    db $e0, $f0, $07, $40   ; dy -32 dx -16 tile 7 attr $40
    db $e0, $f8, $08, $40   ; dy -32 dx -8 tile 8 attr $40
    db $e8, $f8, $09, $00   ; dy -24 dx -8 tile 9 attr $00
    db $f0, $f8, $09, $00   ; dy -16 dx -8 tile 9 attr $00
    db $f8, $f8, $0a, $00   ; dy -8 dx -8 tile 10 attr $00
    db $e8, $00, $09, $20   ; dy -24 dx +0 tile 9 attr $20
    db $f0, $00, $09, $20   ; dy -16 dx +0 tile 9 attr $20
    db $f8, $00, $0a, $20   ; dy -8 dx +0 tile 10 attr $20
    db $d0, $00, $05, $20   ; dy -48 dx +0 tile 5 attr $20
    db $d8, $08, $07, $20   ; dy -40 dx +8 tile 7 attr $20
    db $d8, $00, $08, $20   ; dy -40 dx +0 tile 8 attr $20
    db $d8, $10, $06, $20   ; dy -40 dx +16 tile 6 attr $20
    db $e0, $10, $06, $60   ; dy -32 dx +16 tile 6 attr $60
    db $e0, $08, $07, $60   ; dy -32 dx +8 tile 7 attr $60
    db $e0, $00, $08, $60   ; dy -32 dx +0 tile 8 attr $60
Anim_24_F07:   ; $47b6 empty frame = the $80 end above (shared)
    db $80
Anim_25_MetalCut:   ; $47b7 animation $25 — MetalCut, CleanCut
    dw Anim_25_F00
    dw Anim_25_F01
    dw Anim_25_F02
    dw Anim_25_F03
    dw Anim_25_F04
    dw Anim_25_F05
    dw Anim_25_F06
    dw Anim_25_F07
    dw Anim_25_F08
    dw Anim_25_F09
    dw Anim_25_F09
    dw Anim_25_F09
    dw Anim_25_F09
    dw Anim_25_F09
    dw Anim_25_F09
    dw Anim_25_F09
    dw Anim_25_F09
    dw Anim_25_F09
    dw Anim_25_F09
    dw Anim_25_F09
    dw Anim_25_F09
    dw Anim_25_F09
    dw Anim_25_F09
    dw Anim_25_F09
    dw Anim_25_F09
    dw Anim_25_F09
    dw Anim_25_F09
    dw Anim_25_F09
    dw Anim_25_F09
    dw Anim_25_F09
    dw Anim_25_F09
    dw Anim_25_F09
Anim_25_F00:   ; $47f7 2 sprites
    db $d8, $fc, $00, $00   ; dy -40 dx -4 tile 0 attr $00
    db $d0, $fc, $01, $00   ; dy -48 dx -4 tile 1 attr $00
    db $80
Anim_25_F01:   ; $4800 6 sprites
    db $e8, $fc, $00, $00   ; dy -24 dx -4 tile 0 attr $00
    db $e0, $fc, $01, $00   ; dy -32 dx -4 tile 1 attr $00
    db $d0, $fc, $03, $00   ; dy -48 dx -4 tile 3 attr $00
    db $d8, $fc, $02, $00   ; dy -40 dx -4 tile 2 attr $00
    db $e4, $f4, $06, $20   ; dy -28 dx -12 tile 6 attr $20
    db $e4, $03, $06, $00   ; dy -28 dx +3 tile 6 attr $00
    db $80
Anim_25_F02:   ; $4819 12 sprites
    db $f8, $fc, $00, $00   ; dy -8 dx -4 tile 0 attr $00
    db $f0, $fc, $01, $00   ; dy -16 dx -4 tile 1 attr $00
    db $e0, $fc, $03, $00   ; dy -32 dx -4 tile 3 attr $00
    db $e8, $fc, $02, $00   ; dy -24 dx -4 tile 2 attr $00
    db $d8, $fc, $04, $00   ; dy -40 dx -4 tile 4 attr $00
    db $d0, $fc, $05, $00   ; dy -48 dx -4 tile 5 attr $00
    db $dc, $03, $07, $00   ; dy -36 dx +3 tile 7 attr $00
    db $dc, $0b, $08, $00   ; dy -36 dx +11 tile 8 attr $00
    db $e4, $03, $09, $00   ; dy -28 dx +3 tile 9 attr $00
    db $e4, $f4, $09, $20   ; dy -28 dx -12 tile 9 attr $20
    db $dc, $f4, $07, $20   ; dy -36 dx -12 tile 7 attr $20
    db $dc, $ec, $08, $20   ; dy -36 dx -20 tile 8 attr $20
    db $80
Anim_25_F03:   ; $484a 18 sprites
    db $d0, $fc, $05, $00   ; dy -48 dx -4 tile 5 attr $00
    db $f8, $fc, $03, $00   ; dy -8 dx -4 tile 3 attr $00
    db $f0, $fc, $04, $00   ; dy -16 dx -4 tile 4 attr $00
    db $e8, $fc, $05, $00   ; dy -24 dx -4 tile 5 attr $00
    db $e0, $fc, $05, $00   ; dy -32 dx -4 tile 5 attr $00
    db $d8, $fc, $05, $00   ; dy -40 dx -4 tile 5 attr $00
    db $d4, $03, $0a, $00   ; dy -44 dx +3 tile 10 attr $00
    db $d4, $0b, $0b, $00   ; dy -44 dx +11 tile 11 attr $00
    db $dc, $03, $0c, $00   ; dy -36 dx +3 tile 12 attr $00
    db $dc, $0b, $0d, $00   ; dy -36 dx +11 tile 13 attr $00
    db $e4, $03, $0e, $00   ; dy -28 dx +3 tile 14 attr $00
    db $e4, $0b, $0f, $00   ; dy -28 dx +11 tile 15 attr $00
    db $d4, $f4, $0a, $20   ; dy -44 dx -12 tile 10 attr $20
    db $d4, $ec, $0b, $20   ; dy -44 dx -20 tile 11 attr $20
    db $dc, $f4, $0c, $20   ; dy -36 dx -12 tile 12 attr $20
    db $dc, $ec, $0d, $20   ; dy -36 dx -20 tile 13 attr $20
    db $e4, $f4, $0e, $20   ; dy -28 dx -12 tile 14 attr $20
    db $e4, $ec, $0f, $20   ; dy -28 dx -20 tile 15 attr $20
    db $80
Anim_25_F04:   ; $4893 12 sprites
    db $d0, $fc, $10, $00   ; dy -48 dx -4 tile 16 attr $00
    db $d8, $fc, $10, $00   ; dy -40 dx -4 tile 16 attr $00
    db $e0, $fc, $10, $00   ; dy -32 dx -4 tile 16 attr $00
    db $e8, $fc, $10, $00   ; dy -24 dx -4 tile 16 attr $00
    db $f0, $fc, $10, $00   ; dy -16 dx -4 tile 16 attr $00
    db $f8, $fc, $10, $00   ; dy -8 dx -4 tile 16 attr $00
    db $e4, $f4, $09, $20   ; dy -28 dx -12 tile 9 attr $20
    db $dc, $f4, $07, $20   ; dy -36 dx -12 tile 7 attr $20
    db $dc, $ec, $08, $20   ; dy -36 dx -20 tile 8 attr $20
    db $dc, $04, $07, $00   ; dy -36 dx +4 tile 7 attr $00
    db $dc, $0c, $08, $00   ; dy -36 dx +12 tile 8 attr $00
    db $e4, $03, $09, $00   ; dy -28 dx +3 tile 9 attr $00
    db $80
Anim_25_F05:   ; $48c4 18 sprites
    db $d0, $fc, $10, $00   ; dy -48 dx -4 tile 16 attr $00
    db $d8, $fc, $10, $00   ; dy -40 dx -4 tile 16 attr $00
    db $e0, $fc, $10, $00   ; dy -32 dx -4 tile 16 attr $00
    db $e8, $fc, $10, $00   ; dy -24 dx -4 tile 16 attr $00
    db $f0, $fc, $10, $00   ; dy -16 dx -4 tile 16 attr $00
    db $f8, $fc, $10, $00   ; dy -8 dx -4 tile 16 attr $00
    db $d4, $f4, $0a, $20   ; dy -44 dx -12 tile 10 attr $20
    db $d4, $ec, $0b, $20   ; dy -44 dx -20 tile 11 attr $20
    db $dc, $f4, $0c, $20   ; dy -36 dx -12 tile 12 attr $20
    db $dc, $ec, $0d, $20   ; dy -36 dx -20 tile 13 attr $20
    db $e4, $f4, $0e, $20   ; dy -28 dx -12 tile 14 attr $20
    db $e4, $ec, $0f, $20   ; dy -28 dx -20 tile 15 attr $20
    db $d4, $03, $0a, $00   ; dy -44 dx +3 tile 10 attr $00
    db $d4, $0b, $0b, $00   ; dy -44 dx +11 tile 11 attr $00
    db $dc, $03, $0c, $00   ; dy -36 dx +3 tile 12 attr $00
    db $dc, $0b, $0d, $00   ; dy -36 dx +11 tile 13 attr $00
    db $e4, $03, $0e, $00   ; dy -28 dx +3 tile 14 attr $00
    db $e4, $0b, $0f, $00   ; dy -28 dx +11 tile 15 attr $00
    db $80
Anim_25_F06:   ; $490d 8 sprites
    db $d0, $fb, $10, $20   ; dy -48 dx -5 tile 16 attr $20
    db $d8, $fb, $10, $20   ; dy -40 dx -5 tile 16 attr $20
    db $e0, $fb, $10, $20   ; dy -32 dx -5 tile 16 attr $20
    db $e8, $fb, $10, $20   ; dy -24 dx -5 tile 16 attr $20
    db $f0, $fb, $10, $20   ; dy -16 dx -5 tile 16 attr $20
    db $f8, $fb, $10, $20   ; dy -8 dx -5 tile 16 attr $20
    db $e4, $f4, $06, $20   ; dy -28 dx -12 tile 6 attr $20
    db $e4, $03, $06, $00   ; dy -28 dx +3 tile 6 attr $00
    db $80
Anim_25_F07:   ; $492e 6 sprites
    db $d0, $fc, $11, $00   ; dy -48 dx -4 tile 17 attr $00
    db $d8, $fc, $11, $00   ; dy -40 dx -4 tile 17 attr $00
    db $e0, $fc, $11, $00   ; dy -32 dx -4 tile 17 attr $00
    db $e8, $fc, $11, $00   ; dy -24 dx -4 tile 17 attr $00
    db $f0, $fc, $11, $00   ; dy -16 dx -4 tile 17 attr $00
    db $f8, $fc, $11, $00   ; dy -8 dx -4 tile 17 attr $00
    db $80
Anim_25_F08:   ; $4947 6 sprites
    db $d0, $fb, $11, $20   ; dy -48 dx -5 tile 17 attr $20
    db $d8, $fb, $11, $20   ; dy -40 dx -5 tile 17 attr $20
    db $e0, $fb, $11, $20   ; dy -32 dx -5 tile 17 attr $20
    db $e8, $fb, $11, $20   ; dy -24 dx -5 tile 17 attr $20
    db $f0, $fb, $11, $20   ; dy -16 dx -5 tile 17 attr $20
    db $f8, $fb, $11, $20   ; dy -8 dx -5 tile 17 attr $20
Anim_25_F09:   ; $495f empty frame = the $80 end above (shared)
    db $80
Anim_26_GigaSlash:   ; $4960 animation $26 — GigaSlash
    dw Anim_26_F00
    dw Anim_26_F01
    dw Anim_26_F02
    dw Anim_26_F03
    dw Anim_26_F04
    dw Anim_26_F05
    dw Anim_26_F06
    dw Anim_26_F07
    dw Anim_26_F08
    dw Anim_26_F09
    dw Anim_26_F10
    dw Anim_26_F11
    dw Anim_26_F12
    dw Anim_26_F12
    dw Anim_26_F12
    dw Anim_26_F12
    dw Anim_26_F12
    dw Anim_26_F12
    dw Anim_26_F12
    dw Anim_26_F12
    dw Anim_26_F12
    dw Anim_26_F12
    dw Anim_26_F12
    dw Anim_26_F12
    dw Anim_26_F12
    dw Anim_26_F12
    dw Anim_26_F12
    dw Anim_26_F12
    dw Anim_26_F12
    dw Anim_26_F12
    dw Anim_26_F12
    dw Anim_26_F12
Anim_26_F00:   ; $49a0 4 sprites
    db $d8, $03, $00, $00   ; dy -40 dx +3 tile 0 attr $00
    db $d8, $0b, $01, $00   ; dy -40 dx +11 tile 1 attr $00
    db $d0, $03, $02, $00   ; dy -48 dx +3 tile 2 attr $00
    db $d0, $0b, $03, $00   ; dy -48 dx +11 tile 3 attr $00
    db $80
Anim_26_F01:   ; $49b1 8 sprites
    db $dc, $ff, $00, $00   ; dy -36 dx -1 tile 0 attr $00
    db $dc, $07, $01, $00   ; dy -36 dx +7 tile 1 attr $00
    db $d4, $ff, $02, $00   ; dy -44 dx -1 tile 2 attr $00
    db $d4, $07, $03, $00   ; dy -44 dx +7 tile 3 attr $00
    db $e4, $f9, $00, $60   ; dy -28 dx -7 tile 0 attr $60
    db $e4, $f1, $01, $60   ; dy -28 dx -15 tile 1 attr $60
    db $ec, $f9, $02, $60   ; dy -20 dx -7 tile 2 attr $60
    db $ec, $f1, $03, $60   ; dy -20 dx -15 tile 3 attr $60
    db $80
Anim_26_F02:   ; $49d2 8 sprites
    db $e0, $fe, $11, $00   ; dy -32 dx -2 tile 17 attr $00
    db $e0, $06, $12, $00   ; dy -32 dx +6 tile 18 attr $00
    db $d8, $0e, $10, $00   ; dy -40 dx +14 tile 16 attr $00
    db $d8, $fe, $0e, $00   ; dy -40 dx -2 tile 14 attr $00
    db $d8, $06, $0f, $00   ; dy -40 dx +6 tile 15 attr $00
    db $d0, $02, $0b, $00   ; dy -48 dx +2 tile 11 attr $00
    db $d0, $0a, $0c, $00   ; dy -48 dx +10 tile 12 attr $00
    db $d0, $12, $0d, $00   ; dy -48 dx +18 tile 13 attr $00
    db $80
Anim_26_F03:   ; $49f3 15 sprites
    db $f0, $f5, $11, $00   ; dy -16 dx -11 tile 17 attr $00
    db $f0, $fd, $12, $00   ; dy -16 dx -3 tile 18 attr $00
    db $d0, $02, $06, $00   ; dy -48 dx +2 tile 6 attr $00
    db $d0, $0a, $07, $00   ; dy -48 dx +10 tile 7 attr $00
    db $d8, $01, $09, $00   ; dy -40 dx +1 tile 9 attr $00
    db $d8, $09, $0a, $00   ; dy -40 dx +9 tile 10 attr $00
    db $e0, $09, $0d, $00   ; dy -32 dx +9 tile 13 attr $00
    db $e8, $05, $10, $00   ; dy -24 dx +5 tile 16 attr $00
    db $d8, $f9, $08, $00   ; dy -40 dx -7 tile 8 attr $00
    db $d8, $f7, $19, $00   ; dy -40 dx -9 tile 25 attr $00
    db $e8, $f0, $1d, $00   ; dy -24 dx -16 tile 29 attr $00
    db $e8, $f8, $1e, $00   ; dy -24 dx -8 tile 30 attr $00
    db $e8, $00, $1f, $00   ; dy -24 dx +0 tile 31 attr $00
    db $e0, $f9, $1b, $00   ; dy -32 dx -7 tile 27 attr $00
    db $e0, $01, $1c, $00   ; dy -32 dx +1 tile 28 attr $00
    db $80
Anim_26_F04:   ; $4a30 16 sprites
    db $e0, $f8, $22, $00   ; dy -32 dx -8 tile 34 attr $00
    db $e0, $00, $23, $00   ; dy -32 dx +0 tile 35 attr $00
    db $e0, $08, $24, $00   ; dy -32 dx +8 tile 36 attr $00
    db $d8, $f3, $20, $00   ; dy -40 dx -13 tile 32 attr $00
    db $e8, $02, $26, $00   ; dy -24 dx +2 tile 38 attr $00
    db $f0, $0a, $29, $00   ; dy -16 dx +10 tile 41 attr $00
    db $f8, $ea, $0b, $00   ; dy -8 dx -22 tile 11 attr $00
    db $f8, $f2, $0c, $00   ; dy -8 dx -14 tile 12 attr $00
    db $f8, $fa, $0d, $00   ; dy -8 dx -6 tile 13 attr $00
    db $f0, $ea, $08, $00   ; dy -16 dx -22 tile 8 attr $00
    db $f0, $f2, $09, $00   ; dy -16 dx -14 tile 9 attr $00
    db $f0, $fa, $0a, $00   ; dy -16 dx -6 tile 10 attr $00
    db $e8, $f4, $06, $00   ; dy -24 dx -12 tile 6 attr $00
    db $e8, $fa, $25, $00   ; dy -24 dx -6 tile 37 attr $00
    db $d0, $09, $13, $00   ; dy -48 dx +9 tile 19 attr $00
    db $d8, $04, $13, $00   ; dy -40 dx +4 tile 19 attr $00
    db $80
Anim_26_F05:   ; $4a71 11 sprites
    db $f0, $f4, $13, $00   ; dy -16 dx -12 tile 19 attr $00
    db $f8, $ef, $13, $00   ; dy -8 dx -17 tile 19 attr $00
    db $d8, $04, $14, $00   ; dy -40 dx +4 tile 20 attr $00
    db $ec, $f0, $1d, $00   ; dy -20 dx -16 tile 29 attr $00
    db $ec, $f8, $1e, $00   ; dy -20 dx -8 tile 30 attr $00
    db $ec, $00, $1f, $00   ; dy -20 dx +0 tile 31 attr $00
    db $dc, $09, $1a, $00   ; dy -36 dx +9 tile 26 attr $00
    db $dc, $f8, $19, $00   ; dy -36 dx -8 tile 25 attr $00
    db $e0, $ff, $14, $00   ; dy -32 dx -1 tile 20 attr $00
    db $e4, $f9, $1b, $00   ; dy -28 dx -7 tile 27 attr $00
    db $e4, $01, $1c, $00   ; dy -28 dx +1 tile 28 attr $00
    db $80
Anim_26_F06:   ; $4a9e 11 sprites
    db $dc, $f4, $2e, $00   ; dy -36 dx -12 tile 46 attr $00
    db $e4, $f4, $2f, $40   ; dy -28 dx -12 tile 47 attr $40
    db $dc, $fc, $2d, $20   ; dy -36 dx -4 tile 45 attr $20
    db $dc, $04, $2e, $20   ; dy -36 dx +4 tile 46 attr $20
    db $e4, $04, $2f, $60   ; dy -28 dx +4 tile 47 attr $60
    db $e4, $fc, $04, $00   ; dy -28 dx -4 tile 4 attr $00
    db $f8, $ef, $14, $00   ; dy -8 dx -17 tile 20 attr $00
    db $f0, $f4, $14, $00   ; dy -16 dx -12 tile 20 attr $00
    db $ec, $fc, $2d, $60   ; dy -20 dx -4 tile 45 attr $60
    db $ec, $04, $2e, $60   ; dy -20 dx +4 tile 46 attr $60
    db $ec, $f4, $2e, $40   ; dy -20 dx -12 tile 46 attr $40
    db $80
Anim_26_F07:   ; $4acb 36 sprites
    db $d0, $e8, $2b, $00   ; dy -48 dx -24 tile 43 attr $00
    db $d0, $f0, $2c, $00   ; dy -48 dx -16 tile 44 attr $00
    db $d0, $f8, $2d, $00   ; dy -48 dx -8 tile 45 attr $00
    db $e0, $e8, $2f, $00   ; dy -32 dx -24 tile 47 attr $00
    db $e0, $f0, $2a, $00   ; dy -32 dx -16 tile 42 attr $00
    db $d8, $f8, $2a, $00   ; dy -40 dx -8 tile 42 attr $00
    db $d8, $e8, $2e, $00   ; dy -40 dx -24 tile 46 attr $00
    db $d0, $10, $2b, $20   ; dy -48 dx +16 tile 43 attr $20
    db $d0, $08, $2c, $20   ; dy -48 dx +8 tile 44 attr $20
    db $d0, $00, $2d, $20   ; dy -48 dx +0 tile 45 attr $20
    db $e0, $10, $2f, $20   ; dy -32 dx +16 tile 47 attr $20
    db $e0, $08, $2a, $20   ; dy -32 dx +8 tile 42 attr $20
    db $d8, $00, $2a, $20   ; dy -40 dx +0 tile 42 attr $20
    db $d8, $10, $2e, $20   ; dy -40 dx +16 tile 46 attr $20
    db $f8, $e8, $2b, $40   ; dy -8 dx -24 tile 43 attr $40
    db $f8, $f0, $2c, $40   ; dy -8 dx -16 tile 44 attr $40
    db $f8, $f8, $2d, $40   ; dy -8 dx -8 tile 45 attr $40
    db $e8, $e8, $2f, $40   ; dy -24 dx -24 tile 47 attr $40
    db $e8, $f0, $2a, $40   ; dy -24 dx -16 tile 42 attr $40
    db $f0, $f8, $2a, $40   ; dy -16 dx -8 tile 42 attr $40
    db $f0, $e8, $2e, $40   ; dy -16 dx -24 tile 46 attr $40
    db $f8, $10, $2b, $60   ; dy -8 dx +16 tile 43 attr $60
    db $f8, $08, $2c, $60   ; dy -8 dx +8 tile 44 attr $60
    db $f8, $00, $2d, $60   ; dy -8 dx +0 tile 45 attr $60
    db $e8, $10, $2f, $60   ; dy -24 dx +16 tile 47 attr $60
    db $e8, $08, $2a, $60   ; dy -24 dx +8 tile 42 attr $60
    db $f0, $00, $2a, $60   ; dy -16 dx +0 tile 42 attr $60
    db $f0, $10, $2e, $60   ; dy -16 dx +16 tile 46 attr $60
    db $e0, $00, $04, $60   ; dy -32 dx +0 tile 4 attr $60
    db $e8, $00, $04, $20   ; dy -24 dx +0 tile 4 attr $20
    db $e8, $f8, $04, $00   ; dy -24 dx -8 tile 4 attr $00
    db $e0, $f8, $04, $40   ; dy -32 dx -8 tile 4 attr $40
    db $d8, $08, $04, $00   ; dy -40 dx +8 tile 4 attr $00
    db $d8, $f0, $04, $20   ; dy -40 dx -16 tile 4 attr $20
    db $f0, $08, $04, $40   ; dy -16 dx +8 tile 4 attr $40
    db $f0, $f0, $04, $60   ; dy -16 dx -16 tile 4 attr $60
    db $80
Anim_26_F08:   ; $4b5c 12 sprites
    db $d0, $05, $15, $00   ; dy -48 dx +5 tile 21 attr $00
    db $d0, $0d, $16, $00   ; dy -48 dx +13 tile 22 attr $00
    db $d8, $00, $15, $00   ; dy -40 dx +0 tile 21 attr $00
    db $d8, $08, $16, $00   ; dy -40 dx +8 tile 22 attr $00
    db $e0, $fb, $15, $00   ; dy -32 dx -5 tile 21 attr $00
    db $e0, $03, $16, $00   ; dy -32 dx +3 tile 22 attr $00
    db $e8, $f5, $15, $00   ; dy -24 dx -11 tile 21 attr $00
    db $e8, $fd, $16, $00   ; dy -24 dx -3 tile 22 attr $00
    db $f0, $f0, $15, $00   ; dy -16 dx -16 tile 21 attr $00
    db $f0, $f8, $16, $00   ; dy -16 dx -8 tile 22 attr $00
    db $f8, $eb, $15, $00   ; dy -8 dx -21 tile 21 attr $00
    db $f8, $f3, $16, $00   ; dy -8 dx -13 tile 22 attr $00
    db $80
Anim_26_F09:   ; $4b8d 12 sprites
    db $d0, $0d, $15, $60   ; dy -48 dx +13 tile 21 attr $60
    db $d0, $05, $16, $60   ; dy -48 dx +5 tile 22 attr $60
    db $d8, $08, $15, $60   ; dy -40 dx +8 tile 21 attr $60
    db $d8, $00, $16, $60   ; dy -40 dx +0 tile 22 attr $60
    db $e0, $03, $15, $60   ; dy -32 dx +3 tile 21 attr $60
    db $e0, $fb, $16, $60   ; dy -32 dx -5 tile 22 attr $60
    db $e8, $fd, $15, $60   ; dy -24 dx -3 tile 21 attr $60
    db $e8, $f5, $16, $60   ; dy -24 dx -11 tile 22 attr $60
    db $f0, $f8, $15, $60   ; dy -16 dx -8 tile 21 attr $60
    db $f0, $f0, $16, $60   ; dy -16 dx -16 tile 22 attr $60
    db $f8, $f3, $15, $60   ; dy -8 dx -13 tile 21 attr $60
    db $f8, $eb, $16, $60   ; dy -8 dx -21 tile 22 attr $60
    db $80
Anim_26_F10:   ; $4bbe 12 sprites
    db $d0, $05, $17, $00   ; dy -48 dx +5 tile 23 attr $00
    db $d0, $0d, $18, $00   ; dy -48 dx +13 tile 24 attr $00
    db $d8, $00, $17, $00   ; dy -40 dx +0 tile 23 attr $00
    db $d8, $08, $18, $00   ; dy -40 dx +8 tile 24 attr $00
    db $e0, $fb, $17, $00   ; dy -32 dx -5 tile 23 attr $00
    db $e0, $03, $18, $00   ; dy -32 dx +3 tile 24 attr $00
    db $e8, $f5, $17, $00   ; dy -24 dx -11 tile 23 attr $00
    db $e8, $fd, $18, $00   ; dy -24 dx -3 tile 24 attr $00
    db $f0, $f0, $17, $00   ; dy -16 dx -16 tile 23 attr $00
    db $f0, $f8, $18, $00   ; dy -16 dx -8 tile 24 attr $00
    db $f8, $eb, $17, $00   ; dy -8 dx -21 tile 23 attr $00
    db $f8, $f3, $18, $00   ; dy -8 dx -13 tile 24 attr $00
    db $80
Anim_26_F11:   ; $4bef 12 sprites
    db $d0, $0d, $17, $60   ; dy -48 dx +13 tile 23 attr $60
    db $d0, $05, $18, $60   ; dy -48 dx +5 tile 24 attr $60
    db $d8, $08, $17, $60   ; dy -40 dx +8 tile 23 attr $60
    db $d8, $00, $18, $60   ; dy -40 dx +0 tile 24 attr $60
    db $e0, $03, $17, $60   ; dy -32 dx +3 tile 23 attr $60
    db $e0, $fb, $18, $60   ; dy -32 dx -5 tile 24 attr $60
    db $e8, $fd, $17, $60   ; dy -24 dx -3 tile 23 attr $60
    db $e8, $f5, $18, $60   ; dy -24 dx -11 tile 24 attr $60
    db $f0, $f8, $17, $60   ; dy -16 dx -8 tile 23 attr $60
    db $f0, $f0, $18, $60   ; dy -16 dx -16 tile 24 attr $60
    db $f8, $f3, $17, $60   ; dy -8 dx -13 tile 23 attr $60
    db $f8, $eb, $18, $60   ; dy -8 dx -21 tile 24 attr $60
Anim_26_F12:   ; $4c1f empty frame = the $80 end above (shared)
    db $80
Anim_27_MultiCut:   ; $4c20 animation $27 — MultiCut
    dw Anim_27_F00
    dw Anim_27_F01
    dw Anim_27_F02
    dw Anim_27_F03
    dw Anim_27_F04
    dw Anim_27_F05
    dw Anim_27_F06
    dw Anim_27_F07
    dw Anim_27_F08
    dw Anim_27_F09
    dw Anim_27_F10
    dw Anim_27_F11
    dw Anim_27_F12
    dw Anim_27_F13
    dw Anim_27_F14
    dw Anim_27_F14
    dw Anim_27_F14
    dw Anim_27_F14
    dw Anim_27_F14
    dw Anim_27_F14
    dw Anim_27_F14
    dw Anim_27_F14
    dw Anim_27_F14
    dw Anim_27_F14
    dw Anim_27_F14
    dw Anim_27_F14
    dw Anim_27_F14
    dw Anim_27_F14
    dw Anim_27_F14
    dw Anim_27_F14
    dw Anim_27_F14
    dw Anim_27_F14
Anim_27_F00:   ; $4c60 5 sprites
    db $e8, $b0, $1c, $00   ; dy -24 dx -80 tile 28 attr $00
    db $e8, $c0, $1e, $00   ; dy -24 dx -64 tile 30 attr $00
    db $e8, $c8, $1f, $00   ; dy -24 dx -56 tile 31 attr $00
    db $e6, $b8, $1d, $00   ; dy -26 dx -72 tile 29 attr $00
    db $e2, $bf, $22, $00   ; dy -30 dx -65 tile 34 attr $00
    db $80
Anim_27_F01:   ; $4c75 8 sprites
    db $e8, $b0, $1c, $00   ; dy -24 dx -80 tile 28 attr $00
    db $e8, $b8, $1c, $00   ; dy -24 dx -72 tile 28 attr $00
    db $e8, $c0, $1c, $00   ; dy -24 dx -64 tile 28 attr $00
    db $e8, $d0, $1e, $00   ; dy -24 dx -48 tile 30 attr $00
    db $e8, $d8, $1f, $00   ; dy -24 dx -40 tile 31 attr $00
    db $e6, $c8, $1d, $00   ; dy -26 dx -56 tile 29 attr $00
    db $dc, $ba, $22, $00   ; dy -36 dx -70 tile 34 attr $00
    db $e2, $c2, $22, $00   ; dy -30 dx -62 tile 34 attr $00
    db $80
Anim_27_F02:   ; $4c96 16 sprites
    db $e8, $b0, $1c, $00   ; dy -24 dx -80 tile 28 attr $00
    db $e8, $b8, $1c, $00   ; dy -24 dx -72 tile 28 attr $00
    db $e8, $c0, $1c, $00   ; dy -24 dx -64 tile 28 attr $00
    db $e8, $c8, $1c, $00   ; dy -24 dx -56 tile 28 attr $00
    db $e8, $d0, $1c, $00   ; dy -24 dx -48 tile 28 attr $00
    db $e8, $e0, $1e, $00   ; dy -24 dx -32 tile 30 attr $00
    db $e8, $e8, $1f, $00   ; dy -24 dx -24 tile 31 attr $00
    db $d9, $f3, $12, $00   ; dy -39 dx -13 tile 18 attr $00
    db $e6, $d8, $1d, $00   ; dy -26 dx -40 tile 29 attr $00
    db $d0, $03, $22, $00   ; dy -48 dx +3 tile 34 attr $00
    db $d1, $f2, $22, $00   ; dy -47 dx -14 tile 34 attr $00
    db $dd, $c6, $22, $00   ; dy -35 dx -58 tile 34 attr $00
    db $da, $bb, $22, $00   ; dy -38 dx -69 tile 34 attr $00
    db $d0, $fa, $23, $00   ; dy -48 dx -6 tile 35 attr $00
    db $d8, $fa, $24, $00   ; dy -40 dx -6 tile 36 attr $00
    db $e0, $fa, $25, $00   ; dy -32 dx -6 tile 37 attr $00
    db $80
Anim_27_F03:   ; $4cd7 22 sprites
    db $e8, $d8, $1c, $00   ; dy -24 dx -40 tile 28 attr $00
    db $e8, $e0, $1c, $00   ; dy -24 dx -32 tile 28 attr $00
    db $dc, $df, $12, $00   ; dy -36 dx -33 tile 18 attr $00
    db $d7, $f2, $12, $00   ; dy -41 dx -14 tile 18 attr $00
    db $db, $03, $12, $20   ; dy -37 dx +3 tile 18 attr $20
    db $d0, $fc, $1b, $00   ; dy -48 dx -4 tile 27 attr $00
    db $e8, $f8, $1f, $00   ; dy -24 dx -8 tile 31 attr $00
    db $d8, $c0, $22, $00   ; dy -40 dx -64 tile 34 attr $00
    db $dd, $d0, $22, $00   ; dy -35 dx -48 tile 34 attr $00
    db $d1, $f2, $22, $00   ; dy -47 dx -14 tile 34 attr $00
    db $d0, $03, $22, $00   ; dy -48 dx +3 tile 34 attr $00
    db $d8, $fa, $23, $00   ; dy -40 dx -6 tile 35 attr $00
    db $e8, $b0, $20, $00   ; dy -24 dx -80 tile 32 attr $00
    db $e8, $bb, $21, $00   ; dy -24 dx -69 tile 33 attr $00
    db $e8, $c6, $1c, $00   ; dy -24 dx -58 tile 28 attr $00
    db $e8, $cf, $1c, $00   ; dy -24 dx -49 tile 28 attr $00
    db $e0, $fa, $24, $00   ; dy -32 dx -6 tile 36 attr $00
    db $e8, $fa, $25, $00   ; dy -24 dx -6 tile 37 attr $00
    db $e0, $e8, $29, $00   ; dy -32 dx -24 tile 41 attr $00
    db $e0, $f0, $2a, $00   ; dy -32 dx -16 tile 42 attr $00
    db $e8, $e8, $2b, $00   ; dy -24 dx -24 tile 43 attr $00
    db $e8, $f0, $2c, $00   ; dy -24 dx -16 tile 44 attr $00
    db $80
Anim_27_F04:   ; $4d30 23 sprites
    db $e8, $dd, $1c, $00   ; dy -24 dx -35 tile 28 attr $00
    db $e8, $e5, $1c, $00   ; dy -24 dx -27 tile 28 attr $00
    db $e8, $ed, $1c, $00   ; dy -24 dx -19 tile 28 attr $00
    db $e8, $f5, $1c, $00   ; dy -24 dx -11 tile 28 attr $00
    db $e8, $d3, $1c, $00   ; dy -24 dx -45 tile 28 attr $00
    db $d0, $fc, $19, $00   ; dy -48 dx -4 tile 25 attr $00
    db $e8, $fc, $1b, $00   ; dy -24 dx -4 tile 27 attr $00
    db $dc, $d2, $12, $00   ; dy -36 dx -46 tile 18 attr $00
    db $e8, $c8, $20, $00   ; dy -24 dx -56 tile 32 attr $00
    db $f0, $fa, $24, $00   ; dy -16 dx -6 tile 36 attr $00
    db $f8, $fa, $25, $00   ; dy -8 dx -6 tile 37 attr $00
    db $d4, $f5, $22, $00   ; dy -44 dx -11 tile 34 attr $00
    db $d8, $e0, $22, $00   ; dy -40 dx -32 tile 34 attr $00
    db $d2, $03, $22, $20   ; dy -46 dx +3 tile 34 attr $20
    db $db, $01, $26, $00   ; dy -37 dx +1 tile 38 attr $00
    db $d9, $06, $27, $00   ; dy -39 dx +6 tile 39 attr $00
    db $d9, $f8, $27, $00   ; dy -39 dx -8 tile 39 attr $00
    db $e0, $02, $29, $00   ; dy -32 dx +2 tile 41 attr $00
    db $e0, $0a, $2a, $00   ; dy -32 dx +10 tile 42 attr $00
    db $e0, $f6, $28, $00   ; dy -32 dx -10 tile 40 attr $00
    db $e8, $02, $2d, $00   ; dy -24 dx +2 tile 45 attr $00
    db $e8, $0a, $2e, $00   ; dy -24 dx +10 tile 46 attr $00
    db $e6, $12, $2f, $00   ; dy -26 dx +18 tile 47 attr $00
    db $80
Anim_27_F05:   ; $4d8d 25 sprites
    db $e8, $ef, $1c, $00   ; dy -24 dx -17 tile 28 attr $00
    db $e8, $f7, $1c, $00   ; dy -24 dx -9 tile 28 attr $00
    db $e8, $ff, $1c, $00   ; dy -24 dx -1 tile 28 attr $00
    db $e8, $07, $1c, $00   ; dy -24 dx +7 tile 28 attr $00
    db $e8, $0f, $1c, $00   ; dy -24 dx +15 tile 28 attr $00
    db $e8, $27, $1f, $00   ; dy -24 dx +39 tile 31 attr $00
    db $da, $05, $12, $00   ; dy -38 dx +5 tile 18 attr $00
    db $cf, $f2, $12, $00   ; dy -49 dx -14 tile 18 attr $00
    db $f7, $03, $12, $20   ; dy -9 dx +3 tile 18 attr $20
    db $f0, $fc, $19, $00   ; dy -16 dx -4 tile 25 attr $00
    db $d0, $fc, $18, $00   ; dy -48 dx -4 tile 24 attr $00
    db $d8, $fc, $22, $20   ; dy -40 dx -4 tile 34 attr $20
    db $dc, $e8, $22, $00   ; dy -36 dx -24 tile 34 attr $00
    db $d8, $11, $22, $00   ; dy -40 dx +17 tile 34 attr $00
    db $f0, $f3, $22, $00   ; dy -16 dx -13 tile 34 attr $00
    db $f8, $fa, $23, $00   ; dy -8 dx -6 tile 35 attr $00
    db $de, $fc, $27, $00   ; dy -34 dx -4 tile 39 attr $00
    db $e0, $08, $26, $00   ; dy -32 dx +8 tile 38 attr $00
    db $e8, $df, $20, $00   ; dy -24 dx -33 tile 32 attr $00
    db $e8, $e7, $21, $00   ; dy -24 dx -25 tile 33 attr $00
    db $e0, $0f, $28, $00   ; dy -32 dx +15 tile 40 attr $00
    db $e1, $16, $29, $00   ; dy -31 dx +22 tile 41 attr $00
    db $e0, $1e, $2a, $00   ; dy -32 dx +30 tile 42 attr $00
    db $e8, $17, $2b, $00   ; dy -24 dx +23 tile 43 attr $00
    db $e8, $1f, $2c, $00   ; dy -24 dx +31 tile 44 attr $00
    db $80
Anim_27_F06:   ; $4df2 22 sprites
    db $d0, $fc, $18, $00   ; dy -48 dx -4 tile 24 attr $00
    db $e0, $fc, $18, $00   ; dy -32 dx -4 tile 24 attr $00
    db $f8, $fc, $18, $00   ; dy -8 dx -4 tile 24 attr $00
    db $f0, $fc, $19, $00   ; dy -16 dx -4 tile 25 attr $00
    db $d8, $fc, $19, $00   ; dy -40 dx -4 tile 25 attr $00
    db $d4, $06, $12, $00   ; dy -44 dx +6 tile 18 attr $00
    db $da, $de, $12, $00   ; dy -38 dx -34 tile 18 attr $00
    db $e8, $07, $1c, $00   ; dy -24 dx +7 tile 28 attr $00
    db $e8, $0f, $1c, $00   ; dy -24 dx +15 tile 28 attr $00
    db $e8, $17, $1c, $00   ; dy -24 dx +23 tile 28 attr $00
    db $e8, $1f, $1c, $00   ; dy -24 dx +31 tile 28 attr $00
    db $e8, $2f, $1e, $00   ; dy -24 dx +47 tile 30 attr $00
    db $e8, $37, $1f, $00   ; dy -24 dx +55 tile 31 attr $00
    db $e6, $27, $1d, $00   ; dy -26 dx +39 tile 29 attr $00
    db $e0, $25, $26, $00   ; dy -32 dx +37 tile 38 attr $00
    db $de, $04, $26, $00   ; dy -34 dx +4 tile 38 attr $00
    db $dd, $0f, $22, $00   ; dy -35 dx +15 tile 34 attr $00
    db $dd, $ee, $22, $00   ; dy -35 dx -18 tile 34 attr $00
    db $e8, $eb, $20, $00   ; dy -24 dx -21 tile 32 attr $00
    db $e8, $f5, $20, $00   ; dy -24 dx -11 tile 32 attr $00
    db $e8, $ff, $21, $00   ; dy -24 dx -1 tile 33 attr $00
    db $de, $19, $28, $00   ; dy -34 dx +25 tile 40 attr $00
    db $80
Anim_27_F07:   ; $4e4b 13 sprites
    db $e8, $1f, $1c, $00   ; dy -24 dx +31 tile 28 attr $00
    db $e8, $27, $1c, $00   ; dy -24 dx +39 tile 28 attr $00
    db $e8, $37, $1e, $00   ; dy -24 dx +55 tile 30 attr $00
    db $e8, $3f, $1f, $00   ; dy -24 dx +63 tile 31 attr $00
    db $db, $fa, $12, $00   ; dy -37 dx -6 tile 18 attr $00
    db $e6, $2f, $1d, $00   ; dy -26 dx +47 tile 29 attr $00
    db $de, $d6, $22, $00   ; dy -34 dx -42 tile 34 attr $00
    db $db, $1d, $22, $00   ; dy -37 dx +29 tile 34 attr $00
    db $e8, $f1, $20, $00   ; dy -24 dx -15 tile 32 attr $00
    db $e8, $04, $20, $00   ; dy -24 dx +4 tile 32 attr $00
    db $e8, $0d, $20, $00   ; dy -24 dx +13 tile 32 attr $00
    db $e8, $15, $21, $00   ; dy -24 dx +21 tile 33 attr $00
    db $e2, $27, $26, $00   ; dy -30 dx +39 tile 38 attr $00
    db $80
Anim_27_F08:   ; $4e80 11 sprites
    db $e0, $3d, $12, $00   ; dy -32 dx +61 tile 18 attr $00
    db $e8, $15, $20, $00   ; dy -24 dx +21 tile 32 attr $00
    db $e8, $20, $20, $00   ; dy -24 dx +32 tile 32 attr $00
    db $e8, $29, $20, $00   ; dy -24 dx +41 tile 32 attr $00
    db $e8, $3a, $20, $00   ; dy -24 dx +58 tile 32 attr $00
    db $e0, $2d, $22, $00   ; dy -32 dx +45 tile 34 attr $00
    db $e8, $32, $21, $00   ; dy -24 dx +50 tile 33 attr $00
    db $e8, $4a, $21, $00   ; dy -24 dx +74 tile 33 attr $00
    db $e8, $b8, $20, $00   ; dy -24 dx -72 tile 32 attr $00
    db $e8, $d4, $20, $00   ; dy -24 dx -44 tile 32 attr $00
    db $e8, $f4, $22, $00   ; dy -24 dx -12 tile 34 attr $00
    db $80
Anim_27_F09:   ; $4ead 9 sprites
    db $e8, $4a, $20, $00   ; dy -24 dx +74 tile 32 attr $00
    db $e8, $20, $20, $00   ; dy -24 dx +32 tile 32 attr $00
    db $e8, $3e, $22, $00   ; dy -24 dx +62 tile 34 attr $00
    db $e8, $2e, $21, $00   ; dy -24 dx +46 tile 33 attr $00
    db $e8, $0d, $21, $00   ; dy -24 dx +13 tile 33 attr $00
    db $e8, $02, $22, $00   ; dy -24 dx +2 tile 34 attr $00
    db $e8, $dc, $22, $00   ; dy -24 dx -36 tile 34 attr $00
    db $e8, $ea, $20, $00   ; dy -24 dx -22 tile 32 attr $00
    db $e8, $bb, $22, $00   ; dy -24 dx -69 tile 34 attr $00
    db $80
Anim_27_F10:   ; $4ed2 10 sprites
    db $e8, $b1, $20, $00   ; dy -24 dx -79 tile 32 attr $00
    db $e8, $d2, $20, $00   ; dy -24 dx -46 tile 32 attr $00
    db $e8, $f8, $20, $00   ; dy -24 dx -8 tile 32 attr $00
    db $e8, $e0, $21, $00   ; dy -24 dx -32 tile 33 attr $00
    db $e8, $bf, $22, $00   ; dy -24 dx -65 tile 34 attr $00
    db $e8, $0b, $22, $00   ; dy -24 dx +11 tile 34 attr $00
    db $e8, $13, $20, $00   ; dy -24 dx +19 tile 32 attr $00
    db $e8, $34, $20, $00   ; dy -24 dx +52 tile 32 attr $00
    db $e8, $1c, $21, $00   ; dy -24 dx +28 tile 33 attr $00
    db $e8, $40, $21, $00   ; dy -24 dx +64 tile 33 attr $00
    db $80
Anim_27_F11:   ; $4efb 48 sprites
    db $e8, $03, $11, $20   ; dy -24 dx +3 tile 17 attr $20
    db $e8, $0d, $11, $20   ; dy -24 dx +13 tile 17 attr $20
    db $e8, $16, $03, $20   ; dy -24 dx +22 tile 3 attr $20
    db $dd, $17, $03, $60   ; dy -35 dx +23 tile 3 attr $60
    db $e8, $27, $07, $40   ; dy -24 dx +39 tile 7 attr $40
    db $d5, $28, $02, $60   ; dy -43 dx +40 tile 2 attr $60
    db $dd, $28, $07, $00   ; dy -35 dx +40 tile 7 attr $00
    db $e8, $1e, $15, $20   ; dy -24 dx +30 tile 21 attr $20
    db $d6, $20, $01, $00   ; dy -42 dx +32 tile 1 attr $00
    db $dd, $1f, $15, $60   ; dy -35 dx +31 tile 21 attr $60
    db $cd, $30, $17, $60   ; dy -51 dx +48 tile 23 attr $60
    db $f8, $31, $17, $20   ; dy -8 dx +49 tile 23 attr $20
    db $f0, $28, $02, $20   ; dy -16 dx +40 tile 2 attr $20
    db $f0, $17, $02, $20   ; dy -16 dx +23 tile 2 attr $20
    db $f0, $20, $01, $40   ; dy -16 dx +32 tile 1 attr $40
    db $f0, $03, $11, $20   ; dy -16 dx +3 tile 17 attr $20
    db $dd, $0d, $1a, $60   ; dy -35 dx +13 tile 26 attr $60
    db $d0, $0c, $02, $00   ; dy -48 dx +12 tile 2 attr $00
    db $d4, $14, $02, $00   ; dy -44 dx +20 tile 2 attr $00
    db $e8, $f5, $11, $00   ; dy -24 dx -11 tile 17 attr $00
    db $e8, $eb, $11, $00   ; dy -24 dx -21 tile 17 attr $00
    db $e8, $e2, $03, $00   ; dy -24 dx -30 tile 3 attr $00
    db $dd, $e1, $03, $40   ; dy -35 dx -31 tile 3 attr $40
    db $e8, $d1, $07, $60   ; dy -24 dx -47 tile 7 attr $60
    db $d5, $d0, $02, $40   ; dy -43 dx -48 tile 2 attr $40
    db $dd, $d0, $07, $20   ; dy -35 dx -48 tile 7 attr $20
    db $e8, $da, $15, $00   ; dy -24 dx -38 tile 21 attr $00
    db $d6, $d8, $01, $20   ; dy -42 dx -40 tile 1 attr $20
    db $dd, $d9, $15, $40   ; dy -35 dx -39 tile 21 attr $40
    db $cd, $c8, $17, $40   ; dy -51 dx -56 tile 23 attr $40
    db $f0, $e1, $02, $00   ; dy -16 dx -31 tile 2 attr $00
    db $f0, $d8, $01, $60   ; dy -16 dx -40 tile 1 attr $60
    db $f0, $f5, $11, $00   ; dy -16 dx -11 tile 17 attr $00
    db $d0, $ec, $02, $20   ; dy -48 dx -20 tile 2 attr $20
    db $d4, $e4, $02, $20   ; dy -44 dx -28 tile 2 attr $20
    db $f1, $d0, $02, $00   ; dy -15 dx -48 tile 2 attr $00
    db $f8, $c8, $17, $00   ; dy -8 dx -56 tile 23 attr $00
    db $dd, $eb, $1a, $40   ; dy -35 dx -21 tile 26 attr $40
    db $f8, $03, $11, $20   ; dy -8 dx +3 tile 17 attr $20
    db $f8, $f5, $11, $00   ; dy -8 dx -11 tile 17 attr $00
    db $d8, $f5, $11, $40   ; dy -40 dx -11 tile 17 attr $40
    db $dd, $f5, $11, $40   ; dy -35 dx -11 tile 17 attr $40
    db $d0, $f5, $11, $40   ; dy -48 dx -11 tile 17 attr $40
    db $d0, $03, $11, $60   ; dy -48 dx +3 tile 17 attr $60
    db $dd, $03, $11, $60   ; dy -35 dx +3 tile 17 attr $60
    db $d8, $03, $11, $60   ; dy -40 dx +3 tile 17 attr $60
    db $f8, $df, $02, $00   ; dy -8 dx -33 tile 2 attr $00
    db $f8, $19, $02, $20   ; dy -8 dx +25 tile 2 attr $20
    db $80
Anim_27_F12:   ; $4fbc 52 sprites
    db $f8, $e8, $1a, $00   ; dy -8 dx -24 tile 26 attr $00
    db $d0, $e8, $1a, $40   ; dy -48 dx -24 tile 26 attr $40
    db $f0, $28, $14, $20   ; dy -16 dx +40 tile 20 attr $20
    db $f8, $10, $1a, $20   ; dy -8 dx +16 tile 26 attr $20
    db $d8, $28, $14, $60   ; dy -40 dx +40 tile 20 attr $60
    db $d0, $10, $1a, $60   ; dy -48 dx +16 tile 26 attr $60
    db $f0, $20, $13, $20   ; dy -16 dx +32 tile 19 attr $20
    db $d8, $20, $13, $60   ; dy -40 dx +32 tile 19 attr $60
    db $e8, $24, $13, $20   ; dy -24 dx +36 tile 19 attr $20
    db $e0, $24, $13, $60   ; dy -32 dx +36 tile 19 attr $60
    db $ea, $2c, $16, $40   ; dy -22 dx +44 tile 22 attr $40
    db $de, $2c, $16, $00   ; dy -34 dx +44 tile 22 attr $00
    db $d0, $19, $11, $00   ; dy -48 dx +25 tile 17 attr $00
    db $f8, $19, $11, $20   ; dy -8 dx +25 tile 17 attr $20
    db $e0, $1b, $06, $60   ; dy -32 dx +27 tile 6 attr $60
    db $e8, $1b, $06, $20   ; dy -24 dx +27 tile 6 attr $20
    db $f0, $40, $06, $20   ; dy -16 dx +64 tile 6 attr $20
    db $f8, $34, $06, $20   ; dy -8 dx +52 tile 6 attr $20
    db $d8, $40, $06, $60   ; dy -40 dx +64 tile 6 attr $60
    db $d0, $34, $06, $60   ; dy -48 dx +52 tile 6 attr $60
    db $ea, $f5, $11, $00   ; dy -22 dx -11 tile 17 attr $00
    db $ea, $03, $11, $20   ; dy -22 dx +3 tile 17 attr $20
    db $de, $f5, $11, $40   ; dy -34 dx -11 tile 17 attr $40
    db $de, $03, $11, $60   ; dy -34 dx +3 tile 17 attr $60
    db $f0, $d0, $14, $00   ; dy -16 dx -48 tile 20 attr $00
    db $d8, $d0, $14, $40   ; dy -40 dx -48 tile 20 attr $40
    db $f0, $d8, $13, $00   ; dy -16 dx -40 tile 19 attr $00
    db $d8, $d8, $13, $40   ; dy -40 dx -40 tile 19 attr $40
    db $e0, $d4, $13, $40   ; dy -32 dx -44 tile 19 attr $40
    db $d0, $df, $11, $20   ; dy -48 dx -33 tile 17 attr $20
    db $f8, $df, $11, $00   ; dy -8 dx -33 tile 17 attr $00
    db $e0, $dd, $06, $40   ; dy -32 dx -35 tile 6 attr $40
    db $e8, $dd, $06, $00   ; dy -24 dx -35 tile 6 attr $00
    db $f8, $c4, $06, $00   ; dy -8 dx -60 tile 6 attr $00
    db $d0, $c4, $06, $40   ; dy -48 dx -60 tile 6 attr $40
    db $f0, $f5, $11, $00   ; dy -16 dx -11 tile 17 attr $00
    db $e8, $d4, $13, $00   ; dy -24 dx -44 tile 19 attr $00
    db $f8, $f5, $1a, $00   ; dy -8 dx -11 tile 26 attr $00
    db $e8, $cc, $16, $60   ; dy -24 dx -52 tile 22 attr $60
    db $e0, $cc, $16, $20   ; dy -32 dx -52 tile 22 attr $20
    db $d8, $f5, $11, $40   ; dy -40 dx -11 tile 17 attr $40
    db $d0, $f5, $1a, $40   ; dy -48 dx -11 tile 26 attr $40
    db $de, $ed, $11, $40   ; dy -34 dx -19 tile 17 attr $40
    db $ea, $ed, $11, $00   ; dy -22 dx -19 tile 17 attr $00
    db $de, $0b, $11, $60   ; dy -34 dx +11 tile 17 attr $60
    db $ea, $0b, $11, $20   ; dy -22 dx +11 tile 17 attr $20
    db $d8, $03, $11, $60   ; dy -40 dx +3 tile 17 attr $60
    db $d0, $03, $1a, $60   ; dy -48 dx +3 tile 26 attr $60
    db $f0, $03, $11, $20   ; dy -16 dx +3 tile 17 attr $20
    db $f8, $03, $1a, $20   ; dy -8 dx +3 tile 26 attr $20
    db $f8, $48, $06, $20   ; dy -8 dx +72 tile 6 attr $20
    db $d0, $48, $06, $60   ; dy -48 dx +72 tile 6 attr $60
    db $80
Anim_27_F13:   ; $508d 56 sprites
    db $e8, $f8, $0d, $00   ; dy -24 dx -8 tile 13 attr $00
    db $e0, $f8, $0d, $40   ; dy -32 dx -8 tile 13 attr $40
    db $d0, $f0, $10, $40   ; dy -48 dx -16 tile 16 attr $40
    db $f0, $f8, $0e, $00   ; dy -16 dx -8 tile 14 attr $00
    db $f8, $f8, $0e, $00   ; dy -8 dx -8 tile 14 attr $00
    db $d8, $f8, $0e, $40   ; dy -40 dx -8 tile 14 attr $40
    db $d0, $f8, $0e, $40   ; dy -48 dx -8 tile 14 attr $40
    db $d0, $b1, $06, $40   ; dy -48 dx -79 tile 6 attr $40
    db $d8, $d2, $0a, $40   ; dy -40 dx -46 tile 10 attr $40
    db $d8, $e7, $0b, $40   ; dy -40 dx -25 tile 11 attr $40
    db $d0, $d9, $0c, $40   ; dy -48 dx -39 tile 12 attr $40
    db $d0, $ca, $07, $40   ; dy -48 dx -54 tile 7 attr $40
    db $f8, $f0, $10, $00   ; dy -8 dx -16 tile 16 attr $00
    db $f8, $b1, $06, $00   ; dy -8 dx -79 tile 6 attr $00
    db $f0, $d2, $0a, $00   ; dy -16 dx -46 tile 10 attr $00
    db $f0, $e7, $0b, $00   ; dy -16 dx -25 tile 11 attr $00
    db $f8, $d9, $0c, $00   ; dy -8 dx -39 tile 12 attr $00
    db $f8, $ca, $07, $00   ; dy -8 dx -54 tile 7 attr $00
    db $f0, $bd, $04, $60   ; dy -16 dx -67 tile 4 attr $60
    db $e9, $b4, $00, $00   ; dy -23 dx -76 tile 0 attr $00
    db $d8, $bc, $04, $20   ; dy -40 dx -68 tile 4 attr $20
    db $df, $b4, $00, $40   ; dy -33 dx -76 tile 0 attr $40
    db $e8, $00, $0d, $20   ; dy -24 dx +0 tile 13 attr $20
    db $e0, $00, $0d, $60   ; dy -32 dx +0 tile 13 attr $60
    db $d0, $08, $10, $60   ; dy -48 dx +8 tile 16 attr $60
    db $f0, $00, $0e, $20   ; dy -16 dx +0 tile 14 attr $20
    db $f8, $00, $0e, $20   ; dy -8 dx +0 tile 14 attr $20
    db $d8, $00, $0e, $60   ; dy -40 dx +0 tile 14 attr $60
    db $d0, $00, $0e, $60   ; dy -48 dx +0 tile 14 attr $60
    db $d0, $47, $06, $60   ; dy -48 dx +71 tile 6 attr $60
    db $d8, $26, $0a, $60   ; dy -40 dx +38 tile 10 attr $60
    db $d8, $11, $0b, $60   ; dy -40 dx +17 tile 11 attr $60
    db $d0, $1f, $0c, $60   ; dy -48 dx +31 tile 12 attr $60
    db $d0, $2e, $07, $60   ; dy -48 dx +46 tile 7 attr $60
    db $f8, $08, $10, $20   ; dy -8 dx +8 tile 16 attr $20
    db $f8, $47, $06, $20   ; dy -8 dx +71 tile 6 attr $20
    db $f0, $26, $0a, $20   ; dy -16 dx +38 tile 10 attr $20
    db $f0, $11, $0b, $20   ; dy -16 dx +17 tile 11 attr $20
    db $f8, $1f, $0c, $20   ; dy -8 dx +31 tile 12 attr $20
    db $f8, $2e, $07, $20   ; dy -8 dx +46 tile 7 attr $20
    db $f0, $3b, $04, $40   ; dy -16 dx +59 tile 4 attr $40
    db $e9, $44, $00, $20   ; dy -23 dx +68 tile 0 attr $20
    db $d8, $3c, $04, $00   ; dy -40 dx +60 tile 4 attr $00
    db $df, $44, $00, $60   ; dy -33 dx +68 tile 0 attr $60
    db $e0, $dc, $00, $40   ; dy -32 dx -36 tile 0 attr $40
    db $e8, $dc, $00, $00   ; dy -24 dx -36 tile 0 attr $00
    db $e0, $1c, $00, $60   ; dy -32 dx +28 tile 0 attr $60
    db $e8, $1c, $00, $20   ; dy -24 dx +28 tile 0 attr $20
    db $e0, $10, $08, $60   ; dy -32 dx +16 tile 8 attr $60
    db $e8, $10, $08, $20   ; dy -24 dx +16 tile 8 attr $20
    db $e0, $e8, $08, $40   ; dy -32 dx -24 tile 8 attr $40
    db $e8, $e8, $08, $00   ; dy -24 dx -24 tile 8 attr $00
    db $e8, $f0, $0f, $00   ; dy -24 dx -16 tile 15 attr $00
    db $e8, $08, $0f, $00   ; dy -24 dx +8 tile 15 attr $00
    db $e0, $08, $0f, $40   ; dy -32 dx +8 tile 15 attr $40
    db $e0, $f0, $0f, $40   ; dy -32 dx -16 tile 15 attr $40
Anim_27_F14:   ; $516d empty frame = the $80 end above (shared)
    db $80
Anim_28_Hellblast:   ; $516e animation $28 — Hellblast
    dw Anim_28_F00
    dw Anim_28_F01
    dw Anim_28_F02
    dw Anim_28_F03
    dw Anim_28_F04
    dw Anim_28_F05
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
    dw Anim_28_F06
Anim_28_F00:   ; $51ae 11 sprites
    db $e4, $02, $0f, $00   ; dy -28 dx +2 tile 15 attr $00
    db $ec, $02, $1f, $00   ; dy -20 dx +2 tile 31 attr $00
    db $f8, $f2, $2f, $00   ; dy -8 dx -14 tile 47 attr $00
    db $f8, $ff, $21, $00   ; dy -8 dx -1 tile 33 attr $00
    db $f8, $f7, $26, $00   ; dy -8 dx -9 tile 38 attr $00
    db $f0, $ff, $29, $40   ; dy -16 dx -1 tile 41 attr $40
    db $e5, $ef, $19, $00   ; dy -27 dx -17 tile 25 attr $00
    db $e9, $f4, $2a, $60   ; dy -23 dx -12 tile 42 attr $60
    db $f0, $f7, $20, $00   ; dy -16 dx -9 tile 32 attr $00
    db $e9, $fc, $29, $40   ; dy -23 dx -4 tile 41 attr $40
    db $e3, $fb, $17, $00   ; dy -29 dx -5 tile 23 attr $00
    db $80
Anim_28_F01:   ; $51db 20 sprites
    db $d5, $0d, $04, $00   ; dy -43 dx +13 tile 4 attr $00
    db $d0, $05, $14, $00   ; dy -48 dx +5 tile 20 attr $00
    db $da, $05, $12, $00   ; dy -38 dx +5 tile 18 attr $00
    db $e8, $ee, $18, $20   ; dy -24 dx -18 tile 24 attr $20
    db $f8, $fe, $1a, $40   ; dy -8 dx -2 tile 26 attr $40
    db $f8, $06, $1a, $20   ; dy -8 dx +6 tile 26 attr $20
    db $d0, $fa, $19, $20   ; dy -48 dx -6 tile 25 attr $20
    db $e8, $fe, $21, $00   ; dy -24 dx -2 tile 33 attr $00
    db $d8, $f2, $21, $20   ; dy -40 dx -14 tile 33 attr $20
    db $f0, $06, $20, $60   ; dy -16 dx +6 tile 32 attr $60
    db $e0, $f0, $20, $00   ; dy -32 dx -16 tile 32 attr $00
    db $e0, $f8, $20, $60   ; dy -32 dx -8 tile 32 attr $60
    db $e0, $fd, $18, $00   ; dy -32 dx -3 tile 24 attr $00
    db $e8, $f6, $20, $00   ; dy -24 dx -10 tile 32 attr $00
    db $f0, $fc, $21, $60   ; dy -16 dx -4 tile 33 attr $60
    db $f0, $fe, $00, $00   ; dy -16 dx -2 tile 0 attr $00
    db $f0, $ee, $1f, $00   ; dy -16 dx -18 tile 31 attr $00
    db $f8, $ec, $0f, $60   ; dy -8 dx -20 tile 15 attr $60
    db $d0, $f2, $29, $60   ; dy -48 dx -14 tile 41 attr $60
    db $f8, $f3, $12, $40   ; dy -8 dx -13 tile 18 attr $40
    db $80
Anim_28_F02:   ; $522c 19 sprites
    db $e2, $f3, $17, $00   ; dy -30 dx -13 tile 23 attr $00
    db $f8, $00, $03, $40   ; dy -8 dx +0 tile 3 attr $40
    db $d0, $04, $0f, $00   ; dy -48 dx +4 tile 15 attr $00
    db $d0, $fc, $1c, $00   ; dy -48 dx -4 tile 28 attr $00
    db $d8, $f8, $19, $00   ; dy -40 dx -8 tile 25 attr $00
    db $f8, $f0, $2f, $00   ; dy -8 dx -16 tile 47 attr $00
    db $f8, $08, $20, $20   ; dy -8 dx +8 tile 32 attr $20
    db $d8, $04, $1f, $00   ; dy -40 dx +4 tile 31 attr $00
    db $e1, $00, $20, $00   ; dy -31 dx +0 tile 32 attr $00
    db $f0, $ef, $0f, $60   ; dy -16 dx -17 tile 15 attr $60
    db $e8, $ef, $0f, $20   ; dy -24 dx -17 tile 15 attr $20
    db $f2, $f7, $12, $40   ; dy -14 dx -9 tile 18 attr $40
    db $f8, $f8, $26, $00   ; dy -8 dx -8 tile 38 attr $00
    db $f0, $00, $25, $00   ; dy -16 dx +0 tile 37 attr $00
    db $f0, $08, $24, $00   ; dy -16 dx +8 tile 36 attr $00
    db $e8, $08, $23, $00   ; dy -24 dx +8 tile 35 attr $00
    db $e0, $08, $22, $00   ; dy -32 dx +8 tile 34 attr $00
    db $d0, $f3, $2a, $00   ; dy -48 dx -13 tile 42 attr $00
    db $d9, $ff, $15, $60   ; dy -39 dx -1 tile 21 attr $60
    db $80
Anim_28_F03:   ; $5279 26 sprites
    db $e8, $f8, $00, $00   ; dy -24 dx -8 tile 0 attr $00
    db $f8, $00, $00, $00   ; dy -8 dx +0 tile 0 attr $00
    db $ec, $e8, $13, $00   ; dy -20 dx -24 tile 19 attr $00
    db $de, $f2, $12, $20   ; dy -34 dx -14 tile 18 attr $20
    db $d3, $f2, $14, $20   ; dy -45 dx -14 tile 20 attr $20
    db $d8, $ea, $04, $20   ; dy -40 dx -22 tile 4 attr $20
    db $e8, $f0, $05, $00   ; dy -24 dx -16 tile 5 attr $00
    db $f0, $f0, $15, $00   ; dy -16 dx -16 tile 21 attr $00
    db $f0, $f8, $16, $00   ; dy -16 dx -8 tile 22 attr $00
    db $e5, $06, $1c, $00   ; dy -27 dx +6 tile 28 attr $00
    db $e5, $0e, $0f, $00   ; dy -27 dx +14 tile 15 attr $00
    db $ed, $0e, $1f, $00   ; dy -19 dx +14 tile 31 attr $00
    db $f8, $f8, $1a, $00   ; dy -8 dx -8 tile 26 attr $00
    db $f8, $f1, $2f, $00   ; dy -8 dx -15 tile 47 attr $00
    db $d0, $f8, $2f, $40   ; dy -48 dx -8 tile 47 attr $40
    db $e8, $fd, $1a, $60   ; dy -24 dx -3 tile 26 attr $60
    db $d8, $01, $1a, $00   ; dy -40 dx +1 tile 26 attr $00
    db $f0, $00, $20, $60   ; dy -16 dx +0 tile 32 attr $60
    db $f0, $07, $2e, $00   ; dy -16 dx +7 tile 46 attr $00
    db $f8, $07, $1a, $60   ; dy -8 dx +7 tile 26 attr $60
    db $d8, $08, $28, $00   ; dy -40 dx +8 tile 40 attr $00
    db $d0, $00, $2a, $00   ; dy -48 dx +0 tile 42 attr $00
    db $e2, $02, $20, $20   ; dy -30 dx +2 tile 32 attr $20
    db $e0, $00, $00, $00   ; dy -32 dx +0 tile 0 attr $00
    db $e0, $f8, $2b, $00   ; dy -32 dx -8 tile 43 attr $00
    db $e0, $08, $29, $00   ; dy -32 dx +8 tile 41 attr $00
    db $80
Anim_28_F04:   ; $52e2 34 sprites
    db $d8, $fc, $00, $00   ; dy -40 dx -4 tile 0 attr $00
    db $e8, $fc, $00, $00   ; dy -24 dx -4 tile 0 attr $00
    db $f0, $fc, $00, $00   ; dy -16 dx -4 tile 0 attr $00
    db $f8, $f4, $00, $00   ; dy -8 dx -12 tile 0 attr $00
    db $d0, $fc, $00, $00   ; dy -48 dx -4 tile 0 attr $00
    db $f8, $fc, $06, $00   ; dy -8 dx -4 tile 6 attr $00
    db $f8, $00, $0b, $00   ; dy -8 dx +0 tile 11 attr $00
    db $f8, $08, $0c, $00   ; dy -8 dx +8 tile 12 attr $00
    db $e0, $f4, $01, $00   ; dy -32 dx -12 tile 1 attr $00
    db $e0, $fc, $02, $00   ; dy -32 dx -4 tile 2 attr $00
    db $e8, $f4, $11, $00   ; dy -24 dx -12 tile 17 attr $00
    db $f0, $ee, $12, $60   ; dy -16 dx -18 tile 18 attr $60
    db $ed, $10, $04, $00   ; dy -19 dx +16 tile 4 attr $00
    db $e8, $ed, $04, $20   ; dy -24 dx -19 tile 4 attr $20
    db $f8, $e8, $14, $20   ; dy -8 dx -24 tile 20 attr $20
    db $f0, $08, $17, $00   ; dy -16 dx +8 tile 23 attr $00
    db $d0, $e8, $0f, $20   ; dy -48 dx -24 tile 15 attr $20
    db $d8, $e8, $1f, $20   ; dy -40 dx -24 tile 31 attr $20
    db $d0, $f0, $1c, $20   ; dy -48 dx -16 tile 28 attr $20
    db $f0, $f4, $1a, $00   ; dy -16 dx -12 tile 26 attr $00
    db $f8, $f0, $1a, $00   ; dy -8 dx -16 tile 26 attr $00
    db $d0, $0a, $20, $20   ; dy -48 dx +10 tile 32 attr $20
    db $f0, $04, $21, $00   ; dy -16 dx +4 tile 33 attr $00
    db $d8, $f4, $21, $20   ; dy -40 dx -12 tile 33 attr $20
    db $e0, $ee, $20, $40   ; dy -32 dx -18 tile 32 attr $40
    db $d0, $03, $00, $00   ; dy -48 dx +3 tile 0 attr $00
    db $d8, $04, $00, $00   ; dy -40 dx +4 tile 0 attr $00
    db $d8, $06, $21, $00   ; dy -40 dx +6 tile 33 attr $00
    db $e0, $04, $20, $20   ; dy -32 dx +4 tile 32 attr $20
    db $d0, $f7, $20, $40   ; dy -48 dx -9 tile 32 attr $40
    db $e8, $03, $2c, $20   ; dy -24 dx +3 tile 44 attr $20
    db $e8, $08, $14, $00   ; dy -24 dx +8 tile 20 attr $00
    db $d0, $13, $2d, $00   ; dy -48 dx +19 tile 45 attr $00
    db $d0, $0b, $17, $00   ; dy -48 dx +11 tile 23 attr $00
    db $80
Anim_28_F05:   ; $536b 31 sprites
    db $e0, $ff, $00, $00   ; dy -32 dx -1 tile 0 attr $00
    db $e0, $07, $00, $00   ; dy -32 dx +7 tile 0 attr $00
    db $e8, $08, $00, $00   ; dy -24 dx +8 tile 0 attr $00
    db $f8, $f8, $00, $00   ; dy -8 dx -8 tile 0 attr $00
    db $e8, $f8, $07, $00   ; dy -24 dx -8 tile 7 attr $00
    db $e8, $00, $08, $00   ; dy -24 dx +0 tile 8 attr $00
    db $d8, $ff, $1d, $00   ; dy -40 dx -1 tile 29 attr $00
    db $d8, $07, $1e, $00   ; dy -40 dx +7 tile 30 attr $00
    db $d0, $00, $0d, $00   ; dy -48 dx +0 tile 13 attr $00
    db $d0, $07, $0e, $00   ; dy -48 dx +7 tile 14 attr $00
    db $e0, $f3, $1b, $00   ; dy -32 dx -13 tile 27 attr $00
    db $f8, $00, $00, $00   ; dy -8 dx +0 tile 0 attr $00
    db $f0, $00, $09, $00   ; dy -16 dx +0 tile 9 attr $00
    db $f0, $08, $0a, $00   ; dy -16 dx +8 tile 10 attr $00
    db $f8, $08, $10, $00   ; dy -8 dx +8 tile 16 attr $00
    db $f7, $10, $18, $60   ; dy -9 dx +16 tile 24 attr $60
    db $d8, $f7, $03, $20   ; dy -40 dx -9 tile 3 attr $20
    db $e9, $eb, $0f, $20   ; dy -23 dx -21 tile 15 attr $20
    db $f1, $eb, $1f, $20   ; dy -15 dx -21 tile 31 attr $20
    db $e9, $f3, $1c, $20   ; dy -23 dx -13 tile 28 attr $20
    db $e0, $fb, $1a, $40   ; dy -32 dx -5 tile 26 attr $40
    db $d0, $f0, $20, $00   ; dy -48 dx -16 tile 32 attr $00
    db $d0, $f8, $1d, $00   ; dy -48 dx -8 tile 29 attr $00
    db $e8, $0f, $1a, $60   ; dy -24 dx +15 tile 26 attr $60
    db $d8, $ef, $19, $00   ; dy -40 dx -17 tile 25 attr $00
    db $f0, $f8, $20, $40   ; dy -16 dx -8 tile 32 attr $40
    db $f0, $f1, $2e, $20   ; dy -16 dx -15 tile 46 attr $20
    db $e0, $0f, $24, $00   ; dy -32 dx +15 tile 36 attr $00
    db $da, $10, $2e, $00   ; dy -38 dx +16 tile 46 attr $00
    db $f0, $10, $29, $00   ; dy -16 dx +16 tile 41 attr $00
    db $f8, $f0, $2b, $40   ; dy -8 dx -16 tile 43 attr $40
Anim_28_F06:   ; $53e7 empty frame = the $80 end above (shared)
    db $80
Anim_29_BigBang:   ; $53e8 animation $29 — BigBang
    dw Anim_29_F00
    dw Anim_29_F01
    dw Anim_29_F02
    dw Anim_29_F03
    dw Anim_29_F04
    dw Anim_29_F05
    dw Anim_29_F06
    dw Anim_29_F07
    dw Anim_29_F08
    dw Anim_29_F09
    dw Anim_29_F10
    dw Anim_29_F11
    dw Anim_29_F12
    dw Anim_29_F13
    dw Anim_29_F14
    dw Anim_29_F15
    dw Anim_29_F16
    dw Anim_29_F17
    dw Anim_29_F18
    dw Anim_29_F19
    dw Anim_29_F20
    dw Anim_29_F20
    dw Anim_29_F20
    dw Anim_29_F20
    dw Anim_29_F20
    dw Anim_29_F20
    dw Anim_29_F20
    dw Anim_29_F20
    dw Anim_29_F20
    dw Anim_29_F20
    dw Anim_29_F20
    dw Anim_29_F20
Anim_29_F00:   ; $5428 2 sprites
    db $f8, $f8, $1b, $00   ; dy -8 dx -8 tile 27 attr $00
    db $f8, $00, $1b, $20   ; dy -8 dx +0 tile 27 attr $20
    db $80
Anim_29_F01:   ; $5431 8 sprites
    db $f0, $f0, $1c, $00   ; dy -16 dx -16 tile 28 attr $00
    db $f0, $f8, $1d, $00   ; dy -16 dx -8 tile 29 attr $00
    db $f0, $08, $1c, $20   ; dy -16 dx +8 tile 28 attr $20
    db $f0, $00, $1d, $20   ; dy -16 dx +0 tile 29 attr $20
    db $f8, $f0, $1e, $00   ; dy -8 dx -16 tile 30 attr $00
    db $f8, $f8, $1f, $00   ; dy -8 dx -8 tile 31 attr $00
    db $f8, $08, $1e, $20   ; dy -8 dx +8 tile 30 attr $20
    db $f8, $00, $1f, $20   ; dy -8 dx +0 tile 31 attr $20
    db $80
Anim_29_F02:   ; $5452 30 sprites
    db $e0, $e8, $20, $00   ; dy -32 dx -24 tile 32 attr $00
    db $e0, $f0, $21, $00   ; dy -32 dx -16 tile 33 attr $00
    db $e0, $f8, $22, $00   ; dy -32 dx -8 tile 34 attr $00
    db $e8, $e0, $23, $00   ; dy -24 dx -32 tile 35 attr $00
    db $e8, $e8, $24, $00   ; dy -24 dx -24 tile 36 attr $00
    db $f0, $e0, $25, $00   ; dy -16 dx -32 tile 37 attr $00
    db $f8, $e0, $26, $00   ; dy -8 dx -32 tile 38 attr $00
    db $e8, $18, $23, $20   ; dy -24 dx +24 tile 35 attr $20
    db $e8, $10, $24, $20   ; dy -24 dx +16 tile 36 attr $20
    db $f0, $18, $25, $20   ; dy -16 dx +24 tile 37 attr $20
    db $f8, $18, $26, $20   ; dy -8 dx +24 tile 38 attr $20
    db $e0, $10, $20, $20   ; dy -32 dx +16 tile 32 attr $20
    db $e0, $08, $21, $20   ; dy -32 dx +8 tile 33 attr $20
    db $e0, $00, $22, $20   ; dy -32 dx +0 tile 34 attr $20
    db $e8, $f0, $1f, $20   ; dy -24 dx -16 tile 31 attr $20
    db $e8, $f8, $1f, $20   ; dy -24 dx -8 tile 31 attr $20
    db $e8, $00, $1f, $20   ; dy -24 dx +0 tile 31 attr $20
    db $e8, $08, $1f, $20   ; dy -24 dx +8 tile 31 attr $20
    db $f0, $10, $1f, $20   ; dy -16 dx +16 tile 31 attr $20
    db $f8, $10, $1f, $20   ; dy -8 dx +16 tile 31 attr $20
    db $f8, $e8, $1f, $20   ; dy -8 dx -24 tile 31 attr $20
    db $f0, $e8, $1f, $20   ; dy -16 dx -24 tile 31 attr $20
    db $f0, $f0, $1f, $20   ; dy -16 dx -16 tile 31 attr $20
    db $f8, $f0, $1f, $20   ; dy -8 dx -16 tile 31 attr $20
    db $f8, $f8, $1f, $20   ; dy -8 dx -8 tile 31 attr $20
    db $f0, $f8, $1f, $20   ; dy -16 dx -8 tile 31 attr $20
    db $f0, $00, $1f, $20   ; dy -16 dx +0 tile 31 attr $20
    db $f8, $00, $1f, $20   ; dy -8 dx +0 tile 31 attr $20
    db $f8, $08, $1f, $20   ; dy -8 dx +8 tile 31 attr $20
    db $f0, $08, $1f, $20   ; dy -16 dx +8 tile 31 attr $20
    db $80
Anim_29_F03:   ; $54cb 39 sprites
    db $d6, $dc, $20, $00   ; dy -42 dx -36 tile 32 attr $00
    db $e0, $d2, $23, $00   ; dy -32 dx -46 tile 35 attr $00
    db $d5, $e8, $29, $00   ; dy -43 dx -24 tile 41 attr $00
    db $d4, $f4, $2a, $00   ; dy -44 dx -12 tile 42 attr $00
    db $ec, $d1, $2d, $00   ; dy -20 dx -47 tile 45 attr $00
    db $f8, $d0, $2e, $00   ; dy -8 dx -48 tile 46 attr $00
    db $f8, $ed, $27, $00   ; dy -8 dx -19 tile 39 attr $00
    db $f8, $f8, $27, $00   ; dy -8 dx -8 tile 39 attr $00
    db $f0, $f8, $27, $00   ; dy -16 dx -8 tile 39 attr $00
    db $ef, $ee, $27, $00   ; dy -17 dx -18 tile 39 attr $00
    db $f5, $da, $28, $00   ; dy -11 dx -38 tile 40 attr $00
    db $f0, $e4, $28, $00   ; dy -16 dx -28 tile 40 attr $00
    db $e7, $e5, $28, $00   ; dy -25 dx -27 tile 40 attr $00
    db $e9, $db, $28, $00   ; dy -23 dx -37 tile 40 attr $00
    db $df, $dc, $28, $00   ; dy -33 dx -36 tile 40 attr $00
    db $de, $e6, $28, $00   ; dy -34 dx -26 tile 40 attr $00
    db $dd, $f2, $28, $00   ; dy -35 dx -14 tile 40 attr $00
    db $e6, $ee, $28, $00   ; dy -26 dx -18 tile 40 attr $00
    db $dd, $fc, $28, $00   ; dy -35 dx -4 tile 40 attr $00
    db $e6, $f7, $27, $00   ; dy -26 dx -9 tile 39 attr $00
    db $d6, $1c, $20, $20   ; dy -42 dx +28 tile 32 attr $20
    db $e0, $26, $23, $20   ; dy -32 dx +38 tile 35 attr $20
    db $d5, $10, $29, $20   ; dy -43 dx +16 tile 41 attr $20
    db $d4, $04, $2a, $20   ; dy -44 dx +4 tile 42 attr $20
    db $ec, $27, $2d, $20   ; dy -20 dx +39 tile 45 attr $20
    db $f8, $28, $2e, $20   ; dy -8 dx +40 tile 46 attr $20
    db $f8, $0b, $27, $20   ; dy -8 dx +11 tile 39 attr $20
    db $f8, $00, $27, $20   ; dy -8 dx +0 tile 39 attr $20
    db $f0, $00, $27, $20   ; dy -16 dx +0 tile 39 attr $20
    db $ef, $0a, $27, $20   ; dy -17 dx +10 tile 39 attr $20
    db $f5, $1e, $28, $20   ; dy -11 dx +30 tile 40 attr $20
    db $f0, $14, $28, $20   ; dy -16 dx +20 tile 40 attr $20
    db $e7, $13, $28, $20   ; dy -25 dx +19 tile 40 attr $20
    db $e9, $1d, $28, $20   ; dy -23 dx +29 tile 40 attr $20
    db $df, $1c, $28, $20   ; dy -33 dx +28 tile 40 attr $20
    db $de, $12, $28, $20   ; dy -34 dx +18 tile 40 attr $20
    db $dd, $06, $28, $20   ; dy -35 dx +6 tile 40 attr $20
    db $e6, $0a, $28, $20   ; dy -26 dx +10 tile 40 attr $20
    db $e6, $01, $27, $20   ; dy -26 dx +1 tile 39 attr $20
    db $80
Anim_29_F04:   ; $5568 38 sprites
    db $d8, $33, $23, $20   ; dy -40 dx +51 tile 35 attr $20
    db $d8, $0c, $27, $20   ; dy -40 dx +12 tile 39 attr $20
    db $d8, $ec, $27, $00   ; dy -40 dx -20 tile 39 attr $00
    db $d8, $c5, $23, $00   ; dy -40 dx -59 tile 35 attr $00
    db $e8, $be, $2b, $00   ; dy -24 dx -66 tile 43 attr $00
    db $e8, $3a, $2b, $20   ; dy -24 dx +58 tile 43 attr $20
    db $f0, $f0, $1c, $00   ; dy -16 dx -16 tile 28 attr $00
    db $f0, $f8, $1d, $00   ; dy -16 dx -8 tile 29 attr $00
    db $f0, $08, $1c, $20   ; dy -16 dx +8 tile 28 attr $20
    db $f0, $00, $1d, $20   ; dy -16 dx +0 tile 29 attr $20
    db $f8, $f0, $1e, $00   ; dy -8 dx -16 tile 30 attr $00
    db $f8, $08, $1e, $20   ; dy -8 dx +8 tile 30 attr $20
    db $f8, $f8, $1f, $00   ; dy -8 dx -8 tile 31 attr $00
    db $f8, $00, $1f, $00   ; dy -8 dx +0 tile 31 attr $00
    db $f8, $b8, $2d, $00   ; dy -8 dx -72 tile 45 attr $00
    db $f8, $40, $2d, $20   ; dy -8 dx +64 tile 45 attr $20
    db $e0, $c6, $28, $00   ; dy -32 dx -58 tile 40 attr $00
    db $d8, $cd, $28, $00   ; dy -40 dx -51 tile 40 attr $00
    db $f0, $bd, $28, $00   ; dy -16 dx -67 tile 40 attr $00
    db $d8, $2b, $28, $20   ; dy -40 dx +43 tile 40 attr $20
    db $e0, $32, $28, $20   ; dy -32 dx +50 tile 40 attr $20
    db $f0, $3b, $28, $20   ; dy -16 dx +59 tile 40 attr $20
    db $e8, $32, $28, $20   ; dy -24 dx +50 tile 40 attr $20
    db $f8, $38, $28, $20   ; dy -8 dx +56 tile 40 attr $20
    db $f8, $c0, $28, $00   ; dy -8 dx -64 tile 40 attr $00
    db $e8, $c6, $28, $00   ; dy -24 dx -58 tile 40 attr $00
    db $f0, $c5, $28, $00   ; dy -16 dx -59 tile 40 attr $00
    db $f0, $33, $28, $20   ; dy -16 dx +51 tile 40 attr $20
    db $e0, $ce, $28, $00   ; dy -32 dx -50 tile 40 attr $00
    db $e0, $2a, $28, $20   ; dy -32 dx +42 tile 40 attr $20
    db $d8, $23, $28, $20   ; dy -40 dx +35 tile 40 attr $20
    db $d8, $d5, $28, $00   ; dy -40 dx -43 tile 40 attr $00
    db $ec, $d6, $27, $00   ; dy -20 dx -42 tile 39 attr $00
    db $ec, $22, $27, $20   ; dy -20 dx +34 tile 39 attr $20
    db $e2, $e1, $27, $00   ; dy -30 dx -31 tile 39 attr $00
    db $f8, $d0, $27, $00   ; dy -8 dx -48 tile 39 attr $00
    db $e2, $17, $27, $20   ; dy -30 dx +23 tile 39 attr $20
    db $f8, $28, $27, $20   ; dy -8 dx +40 tile 39 attr $20
    db $80
Anim_29_F05:   ; $5601 40 sprites
    db $e0, $e8, $20, $00   ; dy -32 dx -24 tile 32 attr $00
    db $e8, $e0, $23, $00   ; dy -24 dx -32 tile 35 attr $00
    db $e0, $10, $20, $20   ; dy -32 dx +16 tile 32 attr $20
    db $e8, $18, $23, $20   ; dy -24 dx +24 tile 35 attr $20
    db $e0, $f0, $29, $00   ; dy -32 dx -16 tile 41 attr $00
    db $f8, $e0, $2e, $00   ; dy -8 dx -32 tile 46 attr $00
    db $f0, $e0, $2d, $00   ; dy -16 dx -32 tile 45 attr $00
    db $e8, $e8, $2c, $00   ; dy -24 dx -24 tile 44 attr $00
    db $e0, $f8, $2a, $00   ; dy -32 dx -8 tile 42 attr $00
    db $e0, $08, $29, $20   ; dy -32 dx +8 tile 41 attr $20
    db $e0, $00, $2a, $20   ; dy -32 dx +0 tile 42 attr $20
    db $e8, $10, $2c, $20   ; dy -24 dx +16 tile 44 attr $20
    db $f0, $18, $2d, $20   ; dy -16 dx +24 tile 45 attr $20
    db $f8, $18, $2e, $20   ; dy -8 dx +24 tile 46 attr $20
    db $e8, $f0, $28, $60   ; dy -24 dx -16 tile 40 attr $60
    db $f0, $08, $28, $40   ; dy -16 dx +8 tile 40 attr $40
    db $e8, $08, $28, $40   ; dy -24 dx +8 tile 40 attr $40
    db $ec, $24, $28, $20   ; dy -20 dx +36 tile 40 attr $20
    db $f4, $34, $28, $20   ; dy -12 dx +52 tile 40 attr $20
    db $e0, $20, $28, $20   ; dy -32 dx +32 tile 40 attr $20
    db $d2, $14, $28, $20   ; dy -46 dx +20 tile 40 attr $20
    db $e0, $d8, $28, $00   ; dy -32 dx -40 tile 40 attr $00
    db $d2, $e4, $28, $00   ; dy -46 dx -28 tile 40 attr $00
    db $d0, $f4, $28, $00   ; dy -48 dx -12 tile 40 attr $00
    db $d0, $04, $28, $20   ; dy -48 dx +4 tile 40 attr $20
    db $f8, $e8, $28, $20   ; dy -8 dx -24 tile 40 attr $20
    db $f8, $10, $28, $00   ; dy -8 dx +16 tile 40 attr $00
    db $f0, $f0, $28, $60   ; dy -16 dx -16 tile 40 attr $60
    db $e8, $00, $28, $40   ; dy -24 dx +0 tile 40 attr $40
    db $f8, $08, $28, $40   ; dy -8 dx +8 tile 40 attr $40
    db $f8, $00, $28, $40   ; dy -8 dx +0 tile 40 attr $40
    db $e8, $f8, $28, $60   ; dy -24 dx -8 tile 40 attr $60
    db $f8, $f0, $28, $60   ; dy -8 dx -16 tile 40 attr $60
    db $f8, $f8, $28, $60   ; dy -8 dx -8 tile 40 attr $60
    db $ec, $d4, $28, $00   ; dy -20 dx -44 tile 40 attr $00
    db $f4, $c4, $28, $00   ; dy -12 dx -60 tile 40 attr $00
    db $f0, $00, $28, $40   ; dy -16 dx +0 tile 40 attr $40
    db $f0, $f8, $28, $60   ; dy -16 dx -8 tile 40 attr $60
    db $f0, $e8, $28, $60   ; dy -16 dx -24 tile 40 attr $60
    db $f0, $10, $28, $00   ; dy -16 dx +16 tile 40 attr $00
    db $80
Anim_29_F06:   ; $56a2 40 sprites
    db $d7, $dc, $20, $00   ; dy -41 dx -36 tile 32 attr $00
    db $e0, $d1, $23, $00   ; dy -32 dx -47 tile 35 attr $00
    db $e0, $27, $23, $20   ; dy -32 dx +39 tile 35 attr $20
    db $d7, $1c, $20, $20   ; dy -41 dx +28 tile 32 attr $20
    db $f8, $dc, $27, $00   ; dy -8 dx -36 tile 39 attr $00
    db $ec, $dc, $27, $00   ; dy -20 dx -36 tile 39 attr $00
    db $e0, $e8, $27, $00   ; dy -32 dx -24 tile 39 attr $00
    db $e0, $f4, $27, $00   ; dy -32 dx -12 tile 39 attr $00
    db $eb, $e7, $27, $00   ; dy -21 dx -25 tile 39 attr $00
    db $ec, $1c, $27, $20   ; dy -20 dx +28 tile 39 attr $20
    db $eb, $11, $27, $20   ; dy -21 dx +17 tile 39 attr $20
    db $f8, $1c, $27, $20   ; dy -8 dx +28 tile 39 attr $20
    db $e0, $10, $27, $20   ; dy -32 dx +16 tile 39 attr $20
    db $e0, $04, $27, $20   ; dy -32 dx +4 tile 39 attr $20
    db $f5, $f1, $28, $00   ; dy -11 dx -15 tile 40 attr $00
    db $e0, $dc, $27, $00   ; dy -32 dx -36 tile 39 attr $00
    db $e0, $1c, $27, $20   ; dy -32 dx +28 tile 39 attr $20
    db $d6, $e8, $29, $00   ; dy -42 dx -24 tile 41 attr $00
    db $d5, $f4, $2a, $00   ; dy -43 dx -12 tile 42 attr $00
    db $d6, $10, $29, $20   ; dy -42 dx +16 tile 41 attr $20
    db $d5, $04, $2a, $20   ; dy -43 dx +4 tile 42 attr $20
    db $ec, $d0, $2d, $00   ; dy -20 dx -48 tile 45 attr $00
    db $f8, $cf, $2e, $00   ; dy -8 dx -49 tile 46 attr $00
    db $f8, $29, $2e, $20   ; dy -8 dx +41 tile 46 attr $20
    db $ec, $28, $2d, $20   ; dy -20 dx +40 tile 45 attr $20
    db $f5, $07, $28, $20   ; dy -11 dx +7 tile 40 attr $20
    db $eb, $07, $28, $20   ; dy -21 dx +7 tile 40 attr $20
    db $f5, $11, $28, $20   ; dy -11 dx +17 tile 40 attr $20
    db $eb, $f1, $28, $00   ; dy -21 dx -15 tile 40 attr $00
    db $f5, $e7, $28, $00   ; dy -11 dx -25 tile 40 attr $00
    db $f0, $b8, $2d, $00   ; dy -16 dx -72 tile 45 attr $00
    db $e0, $c1, $2b, $00   ; dy -32 dx -63 tile 43 attr $00
    db $d0, $d4, $2c, $00   ; dy -48 dx -44 tile 44 attr $00
    db $d0, $28, $2c, $20   ; dy -48 dx +40 tile 44 attr $20
    db $e0, $37, $2b, $20   ; dy -32 dx +55 tile 43 attr $20
    db $f0, $40, $2d, $20   ; dy -16 dx +64 tile 45 attr $20
    db $f0, $c4, $28, $00   ; dy -16 dx -60 tile 40 attr $00
    db $f0, $34, $28, $20   ; dy -16 dx +52 tile 40 attr $20
    db $ea, $fc, $28, $00   ; dy -22 dx -4 tile 40 attr $00
    db $f4, $fc, $28, $20   ; dy -12 dx -4 tile 40 attr $20
    db $80
Anim_29_F07:   ; $5743 40 sprites
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
Anim_29_F08:   ; $57e4 35 sprites
    db $e0, $25, $0f, $00   ; dy -32 dx +37 tile 15 attr $00
    db $e0, $2d, $10, $00   ; dy -32 dx +45 tile 16 attr $00
    db $e8, $24, $0e, $60   ; dy -24 dx +36 tile 14 attr $60
    db $e8, $1c, $0f, $60   ; dy -24 dx +28 tile 15 attr $60
    db $e8, $14, $10, $60   ; dy -24 dx +20 tile 16 attr $60
    db $e8, $2c, $0d, $60   ; dy -24 dx +44 tile 13 attr $60
    db $f0, $1c, $0c, $60   ; dy -16 dx +28 tile 12 attr $60
    db $e0, $1d, $0e, $00   ; dy -32 dx +29 tile 14 attr $00
    db $e0, $15, $0d, $00   ; dy -32 dx +21 tile 13 attr $00
    db $e5, $fa, $08, $20   ; dy -27 dx -6 tile 8 attr $20
    db $ed, $02, $09, $20   ; dy -19 dx +2 tile 9 attr $20
    db $ed, $fa, $0a, $20   ; dy -19 dx -6 tile 10 attr $20
    db $d0, $0c, $07, $20   ; dy -48 dx +12 tile 7 attr $20
    db $d0, $04, $08, $20   ; dy -48 dx +4 tile 8 attr $20
    db $d8, $0c, $09, $20   ; dy -40 dx +12 tile 9 attr $20
    db $d8, $04, $0a, $20   ; dy -40 dx +4 tile 10 attr $20
    db $f0, $24, $09, $20   ; dy -16 dx +36 tile 9 attr $20
    db $e5, $02, $07, $20   ; dy -27 dx +2 tile 7 attr $20
    db $e8, $e6, $0f, $20   ; dy -24 dx -26 tile 15 attr $20
    db $e8, $de, $10, $20   ; dy -24 dx -34 tile 16 attr $20
    db $f0, $e7, $0e, $40   ; dy -16 dx -25 tile 14 attr $40
    db $f0, $ef, $0f, $40   ; dy -16 dx -17 tile 15 attr $40
    db $f0, $f7, $10, $40   ; dy -16 dx -9 tile 16 attr $40
    db $f0, $df, $0d, $40   ; dy -16 dx -33 tile 13 attr $40
    db $e8, $ee, $0e, $20   ; dy -24 dx -18 tile 14 attr $20
    db $e8, $f6, $0d, $20   ; dy -24 dx -10 tile 13 attr $20
    db $f8, $e7, $0b, $40   ; dy -8 dx -25 tile 11 attr $40
    db $f8, $ef, $0c, $40   ; dy -8 dx -17 tile 12 attr $40
    db $e0, $ee, $0b, $20   ; dy -32 dx -18 tile 11 attr $20
    db $e0, $e6, $0c, $20   ; dy -32 dx -26 tile 12 attr $20
    db $d0, $2c, $07, $20   ; dy -48 dx +44 tile 7 attr $20
    db $d0, $24, $08, $20   ; dy -48 dx +36 tile 8 attr $20
    db $d8, $2c, $09, $20   ; dy -40 dx +44 tile 9 attr $20
    db $d8, $24, $0a, $20   ; dy -40 dx +36 tile 10 attr $20
    db $d8, $1e, $0c, $20   ; dy -40 dx +30 tile 12 attr $20
    db $80
Anim_29_F09:   ; $5871 30 sprites
    db $d4, $2a, $01, $00   ; dy -44 dx +42 tile 1 attr $00
    db $dc, $22, $02, $00   ; dy -36 dx +34 tile 2 attr $00
    db $dc, $2a, $03, $00   ; dy -36 dx +42 tile 3 attr $00
    db $d4, $22, $00, $00   ; dy -44 dx +34 tile 0 attr $00
    db $e7, $11, $01, $20   ; dy -25 dx +17 tile 1 attr $20
    db $ef, $11, $03, $20   ; dy -17 dx +17 tile 3 attr $20
    db $ef, $21, $02, $20   ; dy -17 dx +33 tile 2 attr $20
    db $e7, $19, $04, $00   ; dy -25 dx +25 tile 4 attr $00
    db $ef, $19, $05, $00   ; dy -17 dx +25 tile 5 attr $00
    db $e7, $21, $01, $00   ; dy -25 dx +33 tile 1 attr $00
    db $db, $09, $00, $20   ; dy -37 dx +9 tile 0 attr $20
    db $db, $01, $01, $20   ; dy -37 dx +1 tile 1 attr $20
    db $e3, $09, $02, $20   ; dy -29 dx +9 tile 2 attr $20
    db $e3, $01, $03, $20   ; dy -29 dx +1 tile 3 attr $20
    db $f7, $27, $02, $00   ; dy -9 dx +39 tile 2 attr $00
    db $f7, $2f, $03, $00   ; dy -9 dx +47 tile 3 attr $00
    db $ef, $27, $00, $00   ; dy -17 dx +39 tile 0 attr $00
    db $ef, $2f, $01, $00   ; dy -17 dx +47 tile 1 attr $00
    db $f0, $fb, $00, $00   ; dy -16 dx -5 tile 0 attr $00
    db $f0, $03, $01, $00   ; dy -16 dx +3 tile 1 attr $00
    db $f8, $fb, $02, $00   ; dy -8 dx -5 tile 2 attr $00
    db $f8, $03, $03, $00   ; dy -8 dx +3 tile 3 attr $00
    db $e3, $3c, $07, $20   ; dy -29 dx +60 tile 7 attr $20
    db $e3, $34, $08, $20   ; dy -29 dx +52 tile 8 attr $20
    db $eb, $3c, $09, $20   ; dy -21 dx +60 tile 9 attr $20
    db $eb, $34, $0a, $20   ; dy -21 dx +52 tile 10 attr $20
    db $db, $19, $07, $20   ; dy -37 dx +25 tile 7 attr $20
    db $db, $11, $08, $20   ; dy -37 dx +17 tile 8 attr $20
    db $e3, $19, $09, $20   ; dy -29 dx +25 tile 9 attr $20
    db $e3, $11, $0a, $20   ; dy -29 dx +17 tile 10 attr $20
    db $80
Anim_29_F10:   ; $58ea 36 sprites
    db $ec, $34, $0e, $40   ; dy -20 dx +52 tile 14 attr $40
    db $ec, $3c, $0f, $40   ; dy -20 dx +60 tile 15 attr $40
    db $ec, $44, $10, $40   ; dy -20 dx +68 tile 16 attr $40
    db $ec, $2c, $0d, $40   ; dy -20 dx +44 tile 13 attr $40
    db $f4, $3c, $0c, $40   ; dy -12 dx +60 tile 12 attr $40
    db $f4, $34, $09, $00   ; dy -12 dx +52 tile 9 attr $00
    db $f4, $19, $07, $40   ; dy -12 dx +25 tile 7 attr $40
    db $f4, $21, $08, $40   ; dy -12 dx +33 tile 8 attr $40
    db $ec, $19, $09, $40   ; dy -20 dx +25 tile 9 attr $40
    db $ec, $21, $0a, $40   ; dy -20 dx +33 tile 10 attr $40
    db $f0, $04, $07, $00   ; dy -16 dx +4 tile 7 attr $00
    db $f0, $0c, $08, $00   ; dy -16 dx +12 tile 8 attr $00
    db $f8, $04, $09, $00   ; dy -8 dx +4 tile 9 attr $00
    db $f8, $0c, $0a, $00   ; dy -8 dx +12 tile 10 attr $00
    db $ec, $13, $11, $60   ; dy -20 dx +19 tile 17 attr $60
    db $ec, $0b, $12, $60   ; dy -20 dx +11 tile 18 attr $60
    db $d4, $04, $11, $00   ; dy -44 dx +4 tile 17 attr $00
    db $d4, $0c, $12, $00   ; dy -44 dx +12 tile 18 attr $00
    db $d4, $18, $14, $00   ; dy -44 dx +24 tile 20 attr $00
    db $dc, $00, $15, $00   ; dy -36 dx +0 tile 21 attr $00
    db $dc, $08, $16, $00   ; dy -36 dx +8 tile 22 attr $00
    db $dc, $10, $17, $00   ; dy -36 dx +16 tile 23 attr $00
    db $dc, $18, $18, $00   ; dy -36 dx +24 tile 24 attr $00
    db $e4, $18, $15, $60   ; dy -28 dx +24 tile 21 attr $60
    db $e4, $10, $16, $60   ; dy -28 dx +16 tile 22 attr $60
    db $e4, $08, $17, $60   ; dy -28 dx +8 tile 23 attr $60
    db $e4, $00, $18, $60   ; dy -28 dx +0 tile 24 attr $60
    db $dc, $28, $07, $20   ; dy -36 dx +40 tile 7 attr $20
    db $dc, $20, $08, $20   ; dy -36 dx +32 tile 8 attr $20
    db $e4, $28, $09, $20   ; dy -28 dx +40 tile 9 attr $20
    db $e4, $20, $0a, $20   ; dy -28 dx +32 tile 10 attr $20
    db $e4, $3b, $0e, $20   ; dy -28 dx +59 tile 14 attr $20
    db $e4, $33, $0f, $20   ; dy -28 dx +51 tile 15 attr $20
    db $e4, $43, $0d, $20   ; dy -28 dx +67 tile 13 attr $20
    db $dc, $3b, $0b, $20   ; dy -36 dx +59 tile 11 attr $20
    db $dc, $33, $0c, $20   ; dy -36 dx +51 tile 12 attr $20
    db $80
Anim_29_F11:   ; $597b 34 sprites
    db $d8, $08, $02, $00   ; dy -40 dx +8 tile 2 attr $00
    db $d8, $10, $03, $00   ; dy -40 dx +16 tile 3 attr $00
    db $d0, $08, $00, $00   ; dy -48 dx +8 tile 0 attr $00
    db $e3, $21, $01, $00   ; dy -29 dx +33 tile 1 attr $00
    db $eb, $21, $03, $00   ; dy -21 dx +33 tile 3 attr $00
    db $eb, $11, $02, $00   ; dy -21 dx +17 tile 2 attr $00
    db $e3, $19, $04, $20   ; dy -29 dx +25 tile 4 attr $20
    db $eb, $19, $05, $20   ; dy -21 dx +25 tile 5 attr $20
    db $e3, $11, $01, $20   ; dy -29 dx +17 tile 1 attr $20
    db $f3, $0b, $02, $20   ; dy -13 dx +11 tile 2 attr $20
    db $f3, $03, $03, $20   ; dy -13 dx +3 tile 3 attr $20
    db $eb, $03, $01, $20   ; dy -21 dx +3 tile 1 attr $20
    db $f0, $26, $07, $20   ; dy -16 dx +38 tile 7 attr $20
    db $f0, $1e, $08, $20   ; dy -16 dx +30 tile 8 attr $20
    db $f8, $26, $09, $20   ; dy -8 dx +38 tile 9 attr $20
    db $f8, $1e, $0a, $20   ; dy -8 dx +30 tile 10 attr $20
    db $d3, $2d, $00, $00   ; dy -45 dx +45 tile 0 attr $00
    db $d3, $35, $01, $00   ; dy -45 dx +53 tile 1 attr $00
    db $db, $2d, $02, $00   ; dy -37 dx +45 tile 2 attr $00
    db $db, $35, $03, $00   ; dy -37 dx +53 tile 3 attr $00
    db $d7, $20, $07, $20   ; dy -41 dx +32 tile 7 attr $20
    db $d7, $18, $08, $20   ; dy -41 dx +24 tile 8 attr $20
    db $df, $20, $09, $20   ; dy -33 dx +32 tile 9 attr $20
    db $df, $18, $0a, $20   ; dy -33 dx +24 tile 10 attr $20
    db $ea, $29, $02, $00   ; dy -22 dx +41 tile 2 attr $00
    db $e2, $31, $04, $00   ; dy -30 dx +49 tile 4 attr $00
    db $e8, $39, $05, $00   ; dy -24 dx +57 tile 5 attr $00
    db $e0, $39, $04, $00   ; dy -32 dx +57 tile 4 attr $00
    db $eb, $0b, $0c, $00   ; dy -21 dx +11 tile 12 attr $00
    db $d0, $10, $07, $20   ; dy -48 dx +16 tile 7 attr $20
    db $e2, $29, $00, $00   ; dy -30 dx +41 tile 0 attr $00
    db $e0, $41, $01, $00   ; dy -32 dx +65 tile 1 attr $00
    db $ea, $31, $05, $00   ; dy -22 dx +49 tile 5 attr $00
    db $e8, $41, $03, $00   ; dy -24 dx +65 tile 3 attr $00
    db $80
Anim_29_F12:   ; $5a04 34 sprites
    db $dc, $3c, $0e, $00   ; dy -36 dx +60 tile 14 attr $00
    db $dc, $44, $0f, $00   ; dy -36 dx +68 tile 15 attr $00
    db $dc, $34, $0d, $00   ; dy -36 dx +52 tile 13 attr $00
    db $d4, $44, $0c, $00   ; dy -44 dx +68 tile 12 attr $00
    db $e4, $43, $0e, $60   ; dy -28 dx +67 tile 14 attr $60
    db $e4, $3b, $0f, $60   ; dy -28 dx +59 tile 15 attr $60
    db $ec, $43, $0b, $60   ; dy -20 dx +67 tile 11 attr $60
    db $ec, $3b, $0c, $60   ; dy -20 dx +59 tile 12 attr $60
    db $d4, $3c, $0b, $00   ; dy -44 dx +60 tile 11 attr $00
    db $e0, $2c, $11, $20   ; dy -32 dx +44 tile 17 attr $20
    db $e0, $24, $12, $20   ; dy -32 dx +36 tile 18 attr $20
    db $f8, $1d, $11, $40   ; dy -8 dx +29 tile 17 attr $40
    db $f8, $25, $12, $40   ; dy -8 dx +37 tile 18 attr $40
    db $f8, $31, $14, $40   ; dy -8 dx +49 tile 20 attr $40
    db $f0, $19, $15, $40   ; dy -16 dx +25 tile 21 attr $40
    db $f0, $21, $16, $40   ; dy -16 dx +33 tile 22 attr $40
    db $f0, $29, $17, $40   ; dy -16 dx +41 tile 23 attr $40
    db $f0, $31, $18, $40   ; dy -16 dx +49 tile 24 attr $40
    db $e8, $31, $15, $20   ; dy -24 dx +49 tile 21 attr $20
    db $e8, $29, $16, $20   ; dy -24 dx +41 tile 22 attr $20
    db $e8, $21, $17, $20   ; dy -24 dx +33 tile 23 attr $20
    db $e8, $19, $18, $20   ; dy -24 dx +25 tile 24 attr $20
    db $d8, $20, $07, $40   ; dy -40 dx +32 tile 7 attr $40
    db $d8, $28, $08, $40   ; dy -40 dx +40 tile 8 attr $40
    db $d0, $20, $09, $40   ; dy -48 dx +32 tile 9 attr $40
    db $d0, $28, $0a, $40   ; dy -48 dx +40 tile 10 attr $40
    db $f0, $09, $07, $40   ; dy -16 dx +9 tile 7 attr $40
    db $f0, $11, $08, $40   ; dy -16 dx +17 tile 8 attr $40
    db $e8, $09, $09, $40   ; dy -24 dx +9 tile 9 attr $40
    db $e8, $11, $0a, $40   ; dy -24 dx +17 tile 10 attr $40
    db $f0, $43, $07, $20   ; dy -16 dx +67 tile 7 attr $20
    db $f0, $3b, $08, $20   ; dy -16 dx +59 tile 8 attr $20
    db $f8, $43, $09, $20   ; dy -8 dx +67 tile 9 attr $20
    db $f8, $3b, $0a, $20   ; dy -8 dx +59 tile 10 attr $20
    db $80
Anim_29_F13:   ; $5a8d 33 sprites
    db $d0, $3f, $11, $20   ; dy -48 dx +63 tile 17 attr $20
    db $d0, $37, $12, $20   ; dy -48 dx +55 tile 18 attr $20
    db $e8, $30, $11, $40   ; dy -24 dx +48 tile 17 attr $40
    db $e8, $38, $12, $40   ; dy -24 dx +56 tile 18 attr $40
    db $e8, $44, $14, $40   ; dy -24 dx +68 tile 20 attr $40
    db $e0, $2c, $15, $40   ; dy -32 dx +44 tile 21 attr $40
    db $e0, $34, $16, $40   ; dy -32 dx +52 tile 22 attr $40
    db $e0, $3c, $17, $40   ; dy -32 dx +60 tile 23 attr $40
    db $e0, $44, $18, $40   ; dy -32 dx +68 tile 24 attr $40
    db $d8, $44, $15, $20   ; dy -40 dx +68 tile 21 attr $20
    db $d8, $3c, $16, $20   ; dy -40 dx +60 tile 22 attr $20
    db $d8, $34, $17, $20   ; dy -40 dx +52 tile 23 attr $20
    db $d8, $2c, $18, $20   ; dy -40 dx +44 tile 24 attr $20
    db $e1, $20, $0e, $00   ; dy -31 dx +32 tile 14 attr $00
    db $e1, $28, $0f, $00   ; dy -31 dx +40 tile 15 attr $00
    db $e9, $27, $0e, $60   ; dy -23 dx +39 tile 14 attr $60
    db $e9, $1f, $0f, $60   ; dy -23 dx +31 tile 15 attr $60
    db $f1, $27, $0b, $60   ; dy -15 dx +39 tile 11 attr $60
    db $f1, $1f, $0c, $60   ; dy -15 dx +31 tile 12 attr $60
    db $d9, $20, $0b, $00   ; dy -39 dx +32 tile 11 attr $00
    db $e0, $18, $0d, $00   ; dy -32 dx +24 tile 13 attr $00
    db $e0, $14, $07, $20   ; dy -32 dx +20 tile 7 attr $20
    db $e0, $0c, $08, $20   ; dy -32 dx +12 tile 8 attr $20
    db $e8, $14, $09, $20   ; dy -24 dx +20 tile 9 attr $20
    db $e8, $0c, $0a, $20   ; dy -24 dx +12 tile 10 attr $20
    db $d0, $24, $07, $40   ; dy -48 dx +36 tile 7 attr $40
    db $d0, $2c, $08, $40   ; dy -48 dx +44 tile 8 attr $40
    db $f8, $26, $09, $40   ; dy -8 dx +38 tile 9 attr $40
    db $f8, $2e, $0a, $40   ; dy -8 dx +46 tile 10 attr $40
    db $d8, $08, $0e, $40   ; dy -40 dx +8 tile 14 attr $40
    db $d8, $10, $0f, $40   ; dy -40 dx +16 tile 15 attr $40
    db $d0, $0f, $0e, $20   ; dy -48 dx +15 tile 14 attr $20
    db $d0, $07, $0f, $20   ; dy -48 dx +7 tile 15 attr $20
    db $80
Anim_29_F14:   ; $5b12 35 sprites
    db $e0, $d4, $0f, $20   ; dy -32 dx -44 tile 15 attr $20
    db $e0, $cc, $10, $20   ; dy -32 dx -52 tile 16 attr $20
    db $e8, $d5, $0e, $40   ; dy -24 dx -43 tile 14 attr $40
    db $e8, $dd, $0f, $40   ; dy -24 dx -35 tile 15 attr $40
    db $e8, $e5, $10, $40   ; dy -24 dx -27 tile 16 attr $40
    db $e8, $cd, $0d, $40   ; dy -24 dx -51 tile 13 attr $40
    db $f0, $dd, $0c, $40   ; dy -16 dx -35 tile 12 attr $40
    db $e0, $dc, $0e, $20   ; dy -32 dx -36 tile 14 attr $20
    db $e0, $e4, $0d, $20   ; dy -32 dx -28 tile 13 attr $20
    db $e5, $ff, $08, $00   ; dy -27 dx -1 tile 8 attr $00
    db $ed, $f7, $09, $00   ; dy -19 dx -9 tile 9 attr $00
    db $ed, $ff, $0a, $00   ; dy -19 dx -1 tile 10 attr $00
    db $d0, $ed, $07, $00   ; dy -48 dx -19 tile 7 attr $00
    db $d0, $f5, $08, $00   ; dy -48 dx -11 tile 8 attr $00
    db $d8, $ed, $09, $00   ; dy -40 dx -19 tile 9 attr $00
    db $d8, $f5, $0a, $00   ; dy -40 dx -11 tile 10 attr $00
    db $f0, $d5, $09, $00   ; dy -16 dx -43 tile 9 attr $00
    db $e5, $f7, $07, $00   ; dy -27 dx -9 tile 7 attr $00
    db $e8, $13, $0f, $00   ; dy -24 dx +19 tile 15 attr $00
    db $e8, $1b, $10, $00   ; dy -24 dx +27 tile 16 attr $00
    db $f0, $12, $0e, $60   ; dy -16 dx +18 tile 14 attr $60
    db $f0, $0a, $0f, $60   ; dy -16 dx +10 tile 15 attr $60
    db $f0, $02, $10, $60   ; dy -16 dx +2 tile 16 attr $60
    db $f0, $1a, $0d, $60   ; dy -16 dx +26 tile 13 attr $60
    db $e8, $0b, $0e, $00   ; dy -24 dx +11 tile 14 attr $00
    db $e8, $03, $0d, $00   ; dy -24 dx +3 tile 13 attr $00
    db $f8, $12, $0b, $60   ; dy -8 dx +18 tile 11 attr $60
    db $f8, $0a, $0c, $60   ; dy -8 dx +10 tile 12 attr $60
    db $e0, $0b, $0b, $00   ; dy -32 dx +11 tile 11 attr $00
    db $e0, $13, $0c, $00   ; dy -32 dx +19 tile 12 attr $00
    db $d0, $cd, $07, $00   ; dy -48 dx -51 tile 7 attr $00
    db $d0, $d5, $08, $00   ; dy -48 dx -43 tile 8 attr $00
    db $d8, $cd, $09, $00   ; dy -40 dx -51 tile 9 attr $00
    db $d8, $d5, $0a, $00   ; dy -40 dx -43 tile 10 attr $00
    db $d8, $db, $0c, $00   ; dy -40 dx -37 tile 12 attr $00
    db $80
Anim_29_F15:   ; $5b9f 30 sprites
    db $d4, $ce, $01, $20   ; dy -44 dx -50 tile 1 attr $20
    db $dc, $d6, $02, $20   ; dy -36 dx -42 tile 2 attr $20
    db $dc, $ce, $03, $20   ; dy -36 dx -50 tile 3 attr $20
    db $d4, $d6, $00, $20   ; dy -44 dx -42 tile 0 attr $20
    db $e7, $e7, $01, $00   ; dy -25 dx -25 tile 1 attr $00
    db $ef, $e7, $03, $00   ; dy -17 dx -25 tile 3 attr $00
    db $ef, $d7, $02, $00   ; dy -17 dx -41 tile 2 attr $00
    db $e7, $df, $04, $20   ; dy -25 dx -33 tile 4 attr $20
    db $ef, $df, $05, $20   ; dy -17 dx -33 tile 5 attr $20
    db $e7, $d7, $01, $20   ; dy -25 dx -41 tile 1 attr $20
    db $db, $ef, $00, $00   ; dy -37 dx -17 tile 0 attr $00
    db $db, $f7, $01, $00   ; dy -37 dx -9 tile 1 attr $00
    db $e3, $ef, $02, $00   ; dy -29 dx -17 tile 2 attr $00
    db $e3, $f7, $03, $00   ; dy -29 dx -9 tile 3 attr $00
    db $f7, $d1, $02, $20   ; dy -9 dx -47 tile 2 attr $20
    db $f7, $c9, $03, $20   ; dy -9 dx -55 tile 3 attr $20
    db $ef, $d1, $00, $20   ; dy -17 dx -47 tile 0 attr $20
    db $ef, $c9, $01, $20   ; dy -17 dx -55 tile 1 attr $20
    db $f0, $fd, $00, $20   ; dy -16 dx -3 tile 0 attr $20
    db $f0, $f5, $01, $20   ; dy -16 dx -11 tile 1 attr $20
    db $f8, $fd, $02, $20   ; dy -8 dx -3 tile 2 attr $20
    db $f8, $f5, $03, $20   ; dy -8 dx -11 tile 3 attr $20
    db $e3, $bc, $07, $00   ; dy -29 dx -68 tile 7 attr $00
    db $e3, $c4, $08, $00   ; dy -29 dx -60 tile 8 attr $00
    db $eb, $bc, $09, $00   ; dy -21 dx -68 tile 9 attr $00
    db $eb, $c4, $0a, $00   ; dy -21 dx -60 tile 10 attr $00
    db $db, $df, $07, $00   ; dy -37 dx -33 tile 7 attr $00
    db $db, $e7, $08, $00   ; dy -37 dx -25 tile 8 attr $00
    db $e3, $df, $09, $00   ; dy -29 dx -33 tile 9 attr $00
    db $e3, $e7, $0a, $00   ; dy -29 dx -25 tile 10 attr $00
    db $80
Anim_29_F16:   ; $5c18 36 sprites
    db $ec, $c6, $0e, $60   ; dy -20 dx -58 tile 14 attr $60
    db $ec, $be, $0f, $60   ; dy -20 dx -66 tile 15 attr $60
    db $ec, $b6, $10, $60   ; dy -20 dx -74 tile 16 attr $60
    db $ec, $ce, $0d, $60   ; dy -20 dx -50 tile 13 attr $60
    db $f4, $be, $0c, $60   ; dy -12 dx -66 tile 12 attr $60
    db $f4, $c6, $09, $20   ; dy -12 dx -58 tile 9 attr $20
    db $f4, $e1, $07, $60   ; dy -12 dx -31 tile 7 attr $60
    db $f4, $d9, $08, $60   ; dy -12 dx -39 tile 8 attr $60
    db $ec, $e1, $09, $60   ; dy -20 dx -31 tile 9 attr $60
    db $ec, $d9, $0a, $60   ; dy -20 dx -39 tile 10 attr $60
    db $f0, $f6, $07, $20   ; dy -16 dx -10 tile 7 attr $20
    db $f0, $ee, $08, $20   ; dy -16 dx -18 tile 8 attr $20
    db $f8, $f6, $09, $20   ; dy -8 dx -10 tile 9 attr $20
    db $f8, $ee, $0a, $20   ; dy -8 dx -18 tile 10 attr $20
    db $ec, $e7, $11, $40   ; dy -20 dx -25 tile 17 attr $40
    db $ec, $ef, $12, $40   ; dy -20 dx -17 tile 18 attr $40
    db $d4, $f6, $11, $20   ; dy -44 dx -10 tile 17 attr $20
    db $d4, $ee, $12, $20   ; dy -44 dx -18 tile 18 attr $20
    db $d4, $e2, $14, $20   ; dy -44 dx -30 tile 20 attr $20
    db $dc, $fa, $15, $20   ; dy -36 dx -6 tile 21 attr $20
    db $dc, $f2, $16, $20   ; dy -36 dx -14 tile 22 attr $20
    db $dc, $ea, $17, $20   ; dy -36 dx -22 tile 23 attr $20
    db $dc, $e2, $18, $20   ; dy -36 dx -30 tile 24 attr $20
    db $e4, $e2, $15, $40   ; dy -28 dx -30 tile 21 attr $40
    db $e4, $ea, $16, $40   ; dy -28 dx -22 tile 22 attr $40
    db $e4, $f2, $17, $40   ; dy -28 dx -14 tile 23 attr $40
    db $e4, $fa, $18, $40   ; dy -28 dx -6 tile 24 attr $40
    db $dc, $d2, $07, $00   ; dy -36 dx -46 tile 7 attr $00
    db $dc, $da, $08, $00   ; dy -36 dx -38 tile 8 attr $00
    db $e4, $d2, $09, $00   ; dy -28 dx -46 tile 9 attr $00
    db $e4, $da, $0a, $00   ; dy -28 dx -38 tile 10 attr $00
    db $e4, $bf, $0e, $00   ; dy -28 dx -65 tile 14 attr $00
    db $e4, $c7, $0f, $00   ; dy -28 dx -57 tile 15 attr $00
    db $e4, $b7, $0d, $00   ; dy -28 dx -73 tile 13 attr $00
    db $dc, $bf, $0b, $00   ; dy -36 dx -65 tile 11 attr $00
    db $dc, $c7, $0c, $00   ; dy -36 dx -57 tile 12 attr $00
    db $80
Anim_29_F17:   ; $5ca9 34 sprites
    db $d8, $f0, $02, $20   ; dy -40 dx -16 tile 2 attr $20
    db $d8, $e8, $03, $20   ; dy -40 dx -24 tile 3 attr $20
    db $d0, $f0, $00, $20   ; dy -48 dx -16 tile 0 attr $20
    db $e3, $d7, $01, $20   ; dy -29 dx -41 tile 1 attr $20
    db $eb, $d7, $03, $20   ; dy -21 dx -41 tile 3 attr $20
    db $eb, $e7, $02, $20   ; dy -21 dx -25 tile 2 attr $20
    db $e3, $df, $04, $00   ; dy -29 dx -33 tile 4 attr $00
    db $eb, $df, $05, $00   ; dy -21 dx -33 tile 5 attr $00
    db $e3, $e7, $01, $00   ; dy -29 dx -25 tile 1 attr $00
    db $f3, $ed, $02, $00   ; dy -13 dx -19 tile 2 attr $00
    db $f3, $f5, $03, $00   ; dy -13 dx -11 tile 3 attr $00
    db $eb, $f5, $01, $00   ; dy -21 dx -11 tile 1 attr $00
    db $f0, $d2, $07, $00   ; dy -16 dx -46 tile 7 attr $00
    db $f0, $da, $08, $00   ; dy -16 dx -38 tile 8 attr $00
    db $f8, $d2, $09, $00   ; dy -8 dx -46 tile 9 attr $00
    db $f8, $da, $0a, $00   ; dy -8 dx -38 tile 10 attr $00
    db $d3, $cb, $00, $20   ; dy -45 dx -53 tile 0 attr $20
    db $d3, $c3, $01, $20   ; dy -45 dx -61 tile 1 attr $20
    db $db, $cb, $02, $20   ; dy -37 dx -53 tile 2 attr $20
    db $db, $c3, $03, $20   ; dy -37 dx -61 tile 3 attr $20
    db $d7, $d8, $07, $00   ; dy -41 dx -40 tile 7 attr $00
    db $d7, $e0, $08, $00   ; dy -41 dx -32 tile 8 attr $00
    db $df, $d8, $09, $00   ; dy -33 dx -40 tile 9 attr $00
    db $df, $e0, $0a, $00   ; dy -33 dx -32 tile 10 attr $00
    db $ea, $cf, $02, $20   ; dy -22 dx -49 tile 2 attr $20
    db $e2, $c7, $04, $20   ; dy -30 dx -57 tile 4 attr $20
    db $e8, $bf, $05, $20   ; dy -24 dx -65 tile 5 attr $20
    db $e0, $bf, $04, $20   ; dy -32 dx -65 tile 4 attr $20
    db $eb, $ed, $0c, $20   ; dy -21 dx -19 tile 12 attr $20
    db $d0, $e8, $07, $00   ; dy -48 dx -24 tile 7 attr $00
    db $e8, $b7, $03, $20   ; dy -24 dx -73 tile 3 attr $20
    db $e0, $b7, $00, $00   ; dy -32 dx -73 tile 0 attr $00
    db $ea, $c7, $05, $00   ; dy -22 dx -57 tile 5 attr $00
    db $e2, $cf, $01, $00   ; dy -30 dx -49 tile 1 attr $00
    db $80
Anim_29_F18:   ; $5d32 34 sprites
    db $dc, $bc, $0e, $20   ; dy -36 dx -68 tile 14 attr $20
    db $dc, $b4, $0f, $20   ; dy -36 dx -76 tile 15 attr $20
    db $dc, $c4, $0d, $20   ; dy -36 dx -60 tile 13 attr $20
    db $d4, $b4, $0c, $20   ; dy -44 dx -76 tile 12 attr $20
    db $e4, $b5, $0e, $40   ; dy -28 dx -75 tile 14 attr $40
    db $e4, $bd, $0f, $40   ; dy -28 dx -67 tile 15 attr $40
    db $ec, $b5, $0b, $40   ; dy -20 dx -75 tile 11 attr $40
    db $ec, $bd, $0c, $40   ; dy -20 dx -67 tile 12 attr $40
    db $d4, $bc, $0b, $20   ; dy -44 dx -68 tile 11 attr $20
    db $e0, $cc, $11, $00   ; dy -32 dx -52 tile 17 attr $00
    db $e0, $d4, $12, $00   ; dy -32 dx -44 tile 18 attr $00
    db $f8, $db, $11, $60   ; dy -8 dx -37 tile 17 attr $60
    db $f8, $d3, $12, $60   ; dy -8 dx -45 tile 18 attr $60
    db $f8, $c7, $14, $60   ; dy -8 dx -57 tile 20 attr $60
    db $f0, $df, $15, $60   ; dy -16 dx -33 tile 21 attr $60
    db $f0, $d7, $16, $60   ; dy -16 dx -41 tile 22 attr $60
    db $f0, $cf, $17, $60   ; dy -16 dx -49 tile 23 attr $60
    db $f0, $c7, $18, $60   ; dy -16 dx -57 tile 24 attr $60
    db $e8, $c7, $15, $00   ; dy -24 dx -57 tile 21 attr $00
    db $e8, $cf, $16, $00   ; dy -24 dx -49 tile 22 attr $00
    db $e8, $d7, $17, $00   ; dy -24 dx -41 tile 23 attr $00
    db $e8, $df, $18, $00   ; dy -24 dx -33 tile 24 attr $00
    db $d8, $d8, $07, $60   ; dy -40 dx -40 tile 7 attr $60
    db $d8, $d0, $08, $60   ; dy -40 dx -48 tile 8 attr $60
    db $d0, $d8, $09, $60   ; dy -48 dx -40 tile 9 attr $60
    db $d0, $d0, $0a, $60   ; dy -48 dx -48 tile 10 attr $60
    db $f0, $ef, $07, $60   ; dy -16 dx -17 tile 7 attr $60
    db $f0, $e7, $08, $60   ; dy -16 dx -25 tile 8 attr $60
    db $e8, $ef, $09, $60   ; dy -24 dx -17 tile 9 attr $60
    db $e8, $e7, $0a, $60   ; dy -24 dx -25 tile 10 attr $60
    db $f0, $b5, $07, $00   ; dy -16 dx -75 tile 7 attr $00
    db $f0, $bd, $08, $00   ; dy -16 dx -67 tile 8 attr $00
    db $f8, $b5, $09, $00   ; dy -8 dx -75 tile 9 attr $00
    db $f8, $bd, $0a, $00   ; dy -8 dx -67 tile 10 attr $00
    db $80
Anim_29_F19:   ; $5dbb 34 sprites
    db $dc, $bc, $0e, $20   ; dy -36 dx -68 tile 14 attr $20
    db $dc, $b4, $0f, $20   ; dy -36 dx -76 tile 15 attr $20
    db $dc, $c4, $0d, $20   ; dy -36 dx -60 tile 13 attr $20
    db $d4, $b4, $0c, $20   ; dy -44 dx -76 tile 12 attr $20
    db $e4, $b5, $0e, $40   ; dy -28 dx -75 tile 14 attr $40
    db $e4, $bd, $0f, $40   ; dy -28 dx -67 tile 15 attr $40
    db $ec, $b5, $0b, $40   ; dy -20 dx -75 tile 11 attr $40
    db $ec, $bd, $0c, $40   ; dy -20 dx -67 tile 12 attr $40
    db $d4, $bc, $0b, $20   ; dy -44 dx -68 tile 11 attr $20
    db $e0, $cc, $11, $00   ; dy -32 dx -52 tile 17 attr $00
    db $e0, $d4, $12, $00   ; dy -32 dx -44 tile 18 attr $00
    db $f8, $db, $11, $60   ; dy -8 dx -37 tile 17 attr $60
    db $f8, $d3, $12, $60   ; dy -8 dx -45 tile 18 attr $60
    db $f8, $c7, $14, $60   ; dy -8 dx -57 tile 20 attr $60
    db $f0, $df, $15, $60   ; dy -16 dx -33 tile 21 attr $60
    db $f0, $d7, $16, $60   ; dy -16 dx -41 tile 22 attr $60
    db $f0, $cf, $17, $60   ; dy -16 dx -49 tile 23 attr $60
    db $f0, $c7, $18, $60   ; dy -16 dx -57 tile 24 attr $60
    db $e8, $c7, $15, $00   ; dy -24 dx -57 tile 21 attr $00
    db $e8, $cf, $16, $00   ; dy -24 dx -49 tile 22 attr $00
    db $e8, $d7, $17, $00   ; dy -24 dx -41 tile 23 attr $00
    db $e8, $df, $18, $00   ; dy -24 dx -33 tile 24 attr $00
    db $d8, $d8, $07, $60   ; dy -40 dx -40 tile 7 attr $60
    db $d8, $d0, $08, $60   ; dy -40 dx -48 tile 8 attr $60
    db $d0, $d8, $09, $60   ; dy -48 dx -40 tile 9 attr $60
    db $d0, $d0, $0a, $60   ; dy -48 dx -48 tile 10 attr $60
    db $f0, $ef, $07, $60   ; dy -16 dx -17 tile 7 attr $60
    db $f0, $e7, $08, $60   ; dy -16 dx -25 tile 8 attr $60
    db $e8, $ef, $09, $60   ; dy -24 dx -17 tile 9 attr $60
    db $e8, $e7, $0a, $60   ; dy -24 dx -25 tile 10 attr $60
    db $f0, $b5, $07, $00   ; dy -16 dx -75 tile 7 attr $00
    db $f0, $bd, $08, $00   ; dy -16 dx -67 tile 8 attr $00
    db $f8, $b5, $09, $00   ; dy -8 dx -75 tile 9 attr $00
    db $f8, $bd, $0a, $00   ; dy -8 dx -67 tile 10 attr $00
Anim_29_F20:   ; $5e43 empty frame = the $80 end above (shared)
    db $80
Anim_2a_MegaMagic:   ; $5e44 animation $2a — MegaMagic
    dw Anim_2a_F00
    dw Anim_2a_F01
    dw Anim_2a_F02
    dw Anim_2a_F03
    dw Anim_2a_F04
    dw Anim_2a_F05
    dw Anim_2a_F06
    dw Anim_2a_F07
    dw Anim_2a_F08
    dw Anim_2a_F09
    dw Anim_2a_F10
    dw Anim_2a_F11
    dw Anim_2a_F12
    dw Anim_2a_F13
    dw Anim_2a_F14
    dw Anim_2a_F15
    dw Anim_2a_F16
    dw Anim_2a_F17
    dw Anim_2a_F18
    dw Anim_2a_F19
    dw Anim_2a_F20
    dw Anim_2a_F21
    dw Anim_2a_F22
    dw Anim_2a_F23
    dw Anim_2a_F24
    dw Anim_2a_F24
    dw Anim_2a_F24
    dw Anim_2a_F24
    dw Anim_2a_F24
    dw Anim_2a_F24
    dw Anim_2a_F24
    dw Anim_2a_F24
Anim_2a_F00:   ; $5e84 23 sprites
    db $f8, $c0, $00, $00   ; dy -8 dx -64 tile 0 attr $00
    db $f0, $c0, $00, $00   ; dy -16 dx -64 tile 0 attr $00
    db $e8, $c0, $00, $00   ; dy -24 dx -64 tile 0 attr $00
    db $f8, $e0, $00, $00   ; dy -8 dx -32 tile 0 attr $00
    db $f0, $e0, $00, $00   ; dy -16 dx -32 tile 0 attr $00
    db $f8, $f0, $00, $00   ; dy -8 dx -16 tile 0 attr $00
    db $f0, $f0, $00, $00   ; dy -16 dx -16 tile 0 attr $00
    db $e8, $f0, $00, $00   ; dy -24 dx -16 tile 0 attr $00
    db $e0, $f0, $00, $00   ; dy -32 dx -16 tile 0 attr $00
    db $d8, $f0, $00, $00   ; dy -40 dx -16 tile 0 attr $00
    db $f8, $00, $00, $00   ; dy -8 dx +0 tile 0 attr $00
    db $f0, $00, $00, $00   ; dy -16 dx +0 tile 0 attr $00
    db $e8, $00, $00, $00   ; dy -24 dx +0 tile 0 attr $00
    db $f8, $20, $00, $00   ; dy -8 dx +32 tile 0 attr $00
    db $f0, $20, $00, $00   ; dy -16 dx +32 tile 0 attr $00
    db $e8, $20, $00, $00   ; dy -24 dx +32 tile 0 attr $00
    db $e0, $20, $00, $00   ; dy -32 dx +32 tile 0 attr $00
    db $d8, $20, $00, $00   ; dy -40 dx +32 tile 0 attr $00
    db $f8, $30, $00, $00   ; dy -8 dx +48 tile 0 attr $00
    db $f0, $30, $00, $00   ; dy -16 dx +48 tile 0 attr $00
    db $e0, $00, $00, $00   ; dy -32 dx +0 tile 0 attr $00
    db $d8, $00, $00, $00   ; dy -40 dx +0 tile 0 attr $00
    db $d0, $00, $00, $00   ; dy -48 dx +0 tile 0 attr $00
    db $80
Anim_2a_F01:   ; $5ee1 36 sprites
    db $e8, $c0, $01, $00   ; dy -24 dx -64 tile 1 attr $00
    db $e0, $c0, $01, $00   ; dy -32 dx -64 tile 1 attr $00
    db $d0, $c0, $01, $00   ; dy -48 dx -64 tile 1 attr $00
    db $d8, $c0, $01, $00   ; dy -40 dx -64 tile 1 attr $00
    db $f8, $e0, $01, $00   ; dy -8 dx -32 tile 1 attr $00
    db $f0, $e0, $01, $00   ; dy -16 dx -32 tile 1 attr $00
    db $e8, $e0, $01, $00   ; dy -24 dx -32 tile 1 attr $00
    db $e0, $e0, $01, $00   ; dy -32 dx -32 tile 1 attr $00
    db $d0, $e0, $01, $00   ; dy -48 dx -32 tile 1 attr $00
    db $d8, $e0, $01, $00   ; dy -40 dx -32 tile 1 attr $00
    db $f8, $f0, $01, $00   ; dy -8 dx -16 tile 1 attr $00
    db $f0, $f0, $01, $00   ; dy -16 dx -16 tile 1 attr $00
    db $e8, $f0, $01, $00   ; dy -24 dx -16 tile 1 attr $00
    db $e0, $f0, $01, $00   ; dy -32 dx -16 tile 1 attr $00
    db $d0, $f0, $01, $00   ; dy -48 dx -16 tile 1 attr $00
    db $d8, $f0, $01, $00   ; dy -40 dx -16 tile 1 attr $00
    db $f8, $00, $01, $00   ; dy -8 dx +0 tile 1 attr $00
    db $f0, $00, $01, $00   ; dy -16 dx +0 tile 1 attr $00
    db $e8, $00, $01, $00   ; dy -24 dx +0 tile 1 attr $00
    db $e0, $00, $01, $00   ; dy -32 dx +0 tile 1 attr $00
    db $d0, $00, $01, $00   ; dy -48 dx +0 tile 1 attr $00
    db $d8, $00, $01, $00   ; dy -40 dx +0 tile 1 attr $00
    db $f8, $20, $01, $00   ; dy -8 dx +32 tile 1 attr $00
    db $f0, $20, $01, $00   ; dy -16 dx +32 tile 1 attr $00
    db $e8, $20, $01, $00   ; dy -24 dx +32 tile 1 attr $00
    db $e0, $20, $01, $00   ; dy -32 dx +32 tile 1 attr $00
    db $d0, $20, $01, $00   ; dy -48 dx +32 tile 1 attr $00
    db $d8, $20, $01, $00   ; dy -40 dx +32 tile 1 attr $00
    db $f8, $30, $01, $00   ; dy -8 dx +48 tile 1 attr $00
    db $f0, $30, $01, $00   ; dy -16 dx +48 tile 1 attr $00
    db $e8, $30, $01, $00   ; dy -24 dx +48 tile 1 attr $00
    db $e0, $30, $01, $00   ; dy -32 dx +48 tile 1 attr $00
    db $d0, $30, $01, $00   ; dy -48 dx +48 tile 1 attr $00
    db $d8, $30, $01, $00   ; dy -40 dx +48 tile 1 attr $00
    db $f8, $c0, $01, $00   ; dy -8 dx -64 tile 1 attr $00
    db $f0, $c0, $01, $00   ; dy -16 dx -64 tile 1 attr $00
    db $80
Anim_2a_F02:   ; $5f72 36 sprites
    db $f0, $c8, $02, $00   ; dy -16 dx -56 tile 2 attr $00
    db $e8, $c8, $02, $00   ; dy -24 dx -56 tile 2 attr $00
    db $e0, $c8, $02, $00   ; dy -32 dx -56 tile 2 attr $00
    db $d8, $c8, $02, $00   ; dy -40 dx -56 tile 2 attr $00
    db $d0, $c8, $02, $00   ; dy -48 dx -56 tile 2 attr $00
    db $f8, $d8, $02, $00   ; dy -8 dx -40 tile 2 attr $00
    db $f0, $d8, $02, $00   ; dy -16 dx -40 tile 2 attr $00
    db $e8, $d8, $02, $00   ; dy -24 dx -40 tile 2 attr $00
    db $e0, $d8, $02, $00   ; dy -32 dx -40 tile 2 attr $00
    db $d8, $d8, $02, $00   ; dy -40 dx -40 tile 2 attr $00
    db $d0, $d8, $02, $00   ; dy -48 dx -40 tile 2 attr $00
    db $f8, $f8, $02, $00   ; dy -8 dx -8 tile 2 attr $00
    db $f0, $f8, $02, $00   ; dy -16 dx -8 tile 2 attr $00
    db $e8, $f8, $02, $00   ; dy -24 dx -8 tile 2 attr $00
    db $e0, $f8, $02, $00   ; dy -32 dx -8 tile 2 attr $00
    db $d8, $f8, $02, $00   ; dy -40 dx -8 tile 2 attr $00
    db $d0, $f8, $02, $00   ; dy -48 dx -8 tile 2 attr $00
    db $f8, $08, $02, $00   ; dy -8 dx +8 tile 2 attr $00
    db $f0, $08, $02, $00   ; dy -16 dx +8 tile 2 attr $00
    db $e8, $08, $02, $00   ; dy -24 dx +8 tile 2 attr $00
    db $e0, $08, $02, $00   ; dy -32 dx +8 tile 2 attr $00
    db $d8, $08, $02, $00   ; dy -40 dx +8 tile 2 attr $00
    db $d0, $08, $02, $00   ; dy -48 dx +8 tile 2 attr $00
    db $f8, $18, $02, $00   ; dy -8 dx +24 tile 2 attr $00
    db $f0, $18, $02, $00   ; dy -16 dx +24 tile 2 attr $00
    db $e8, $18, $02, $00   ; dy -24 dx +24 tile 2 attr $00
    db $e0, $18, $02, $00   ; dy -32 dx +24 tile 2 attr $00
    db $d8, $18, $02, $00   ; dy -40 dx +24 tile 2 attr $00
    db $d0, $18, $02, $00   ; dy -48 dx +24 tile 2 attr $00
    db $f8, $38, $02, $00   ; dy -8 dx +56 tile 2 attr $00
    db $f0, $38, $02, $00   ; dy -16 dx +56 tile 2 attr $00
    db $e8, $38, $02, $00   ; dy -24 dx +56 tile 2 attr $00
    db $e0, $38, $02, $00   ; dy -32 dx +56 tile 2 attr $00
    db $d8, $38, $02, $00   ; dy -40 dx +56 tile 2 attr $00
    db $d0, $38, $02, $00   ; dy -48 dx +56 tile 2 attr $00
    db $f8, $c8, $02, $00   ; dy -8 dx -56 tile 2 attr $00
    db $80
Anim_2a_F03:   ; $6003 36 sprites
    db $f8, $bc, $02, $00   ; dy -8 dx -68 tile 2 attr $00
    db $f0, $bc, $02, $00   ; dy -16 dx -68 tile 2 attr $00
    db $e8, $bc, $02, $00   ; dy -24 dx -68 tile 2 attr $00
    db $e0, $bc, $02, $00   ; dy -32 dx -68 tile 2 attr $00
    db $d8, $bc, $02, $00   ; dy -40 dx -68 tile 2 attr $00
    db $d0, $bc, $02, $00   ; dy -48 dx -68 tile 2 attr $00
    db $f8, $da, $02, $00   ; dy -8 dx -38 tile 2 attr $00
    db $f0, $da, $02, $00   ; dy -16 dx -38 tile 2 attr $00
    db $e8, $da, $02, $00   ; dy -24 dx -38 tile 2 attr $00
    db $e0, $da, $02, $00   ; dy -32 dx -38 tile 2 attr $00
    db $d8, $da, $02, $00   ; dy -40 dx -38 tile 2 attr $00
    db $d0, $da, $02, $00   ; dy -48 dx -38 tile 2 attr $00
    db $f8, $f0, $02, $00   ; dy -8 dx -16 tile 2 attr $00
    db $f0, $f0, $02, $00   ; dy -16 dx -16 tile 2 attr $00
    db $e8, $f0, $02, $00   ; dy -24 dx -16 tile 2 attr $00
    db $e0, $f0, $02, $00   ; dy -32 dx -16 tile 2 attr $00
    db $d8, $f0, $02, $00   ; dy -40 dx -16 tile 2 attr $00
    db $d0, $f0, $02, $00   ; dy -48 dx -16 tile 2 attr $00
    db $f8, $fc, $02, $00   ; dy -8 dx -4 tile 2 attr $00
    db $f0, $fc, $02, $00   ; dy -16 dx -4 tile 2 attr $00
    db $e8, $fc, $02, $00   ; dy -24 dx -4 tile 2 attr $00
    db $e0, $fc, $02, $00   ; dy -32 dx -4 tile 2 attr $00
    db $d8, $fc, $02, $00   ; dy -40 dx -4 tile 2 attr $00
    db $d0, $fc, $02, $00   ; dy -48 dx -4 tile 2 attr $00
    db $f8, $20, $02, $00   ; dy -8 dx +32 tile 2 attr $00
    db $f0, $20, $02, $00   ; dy -16 dx +32 tile 2 attr $00
    db $e8, $20, $02, $00   ; dy -24 dx +32 tile 2 attr $00
    db $e0, $20, $02, $00   ; dy -32 dx +32 tile 2 attr $00
    db $d8, $20, $02, $00   ; dy -40 dx +32 tile 2 attr $00
    db $d0, $20, $02, $00   ; dy -48 dx +32 tile 2 attr $00
    db $f8, $40, $02, $00   ; dy -8 dx +64 tile 2 attr $00
    db $f0, $40, $02, $00   ; dy -16 dx +64 tile 2 attr $00
    db $e8, $40, $02, $00   ; dy -24 dx +64 tile 2 attr $00
    db $e0, $40, $02, $00   ; dy -32 dx +64 tile 2 attr $00
    db $d8, $40, $02, $00   ; dy -40 dx +64 tile 2 attr $00
    db $d0, $40, $02, $00   ; dy -48 dx +64 tile 2 attr $00
    db $80
Anim_2a_F04:   ; $6094 36 sprites
    db $f8, $26, $03, $00   ; dy -8 dx +38 tile 3 attr $00
    db $f0, $26, $03, $00   ; dy -16 dx +38 tile 3 attr $00
    db $e8, $26, $03, $00   ; dy -24 dx +38 tile 3 attr $00
    db $e0, $26, $03, $00   ; dy -32 dx +38 tile 3 attr $00
    db $d8, $26, $03, $00   ; dy -40 dx +38 tile 3 attr $00
    db $d0, $26, $03, $00   ; dy -48 dx +38 tile 3 attr $00
    db $f8, $f8, $03, $00   ; dy -8 dx -8 tile 3 attr $00
    db $f0, $f8, $03, $00   ; dy -16 dx -8 tile 3 attr $00
    db $e8, $f8, $03, $00   ; dy -24 dx -8 tile 3 attr $00
    db $e0, $f8, $03, $00   ; dy -32 dx -8 tile 3 attr $00
    db $d8, $f8, $03, $00   ; dy -40 dx -8 tile 3 attr $00
    db $d0, $f8, $03, $00   ; dy -48 dx -8 tile 3 attr $00
    db $f8, $b8, $03, $00   ; dy -8 dx -72 tile 3 attr $00
    db $f0, $b8, $03, $00   ; dy -16 dx -72 tile 3 attr $00
    db $e8, $b8, $03, $00   ; dy -24 dx -72 tile 3 attr $00
    db $e0, $b8, $03, $00   ; dy -32 dx -72 tile 3 attr $00
    db $d8, $b8, $03, $00   ; dy -40 dx -72 tile 3 attr $00
    db $d0, $b8, $03, $00   ; dy -48 dx -72 tile 3 attr $00
    db $f8, $c0, $03, $20   ; dy -8 dx -64 tile 3 attr $20
    db $f0, $c0, $03, $20   ; dy -16 dx -64 tile 3 attr $20
    db $e8, $c0, $03, $20   ; dy -24 dx -64 tile 3 attr $20
    db $e0, $c0, $03, $20   ; dy -32 dx -64 tile 3 attr $20
    db $d8, $c0, $03, $20   ; dy -40 dx -64 tile 3 attr $20
    db $d0, $c0, $03, $20   ; dy -48 dx -64 tile 3 attr $20
    db $f8, $00, $03, $20   ; dy -8 dx +0 tile 3 attr $20
    db $f0, $00, $03, $20   ; dy -16 dx +0 tile 3 attr $20
    db $e8, $00, $03, $20   ; dy -24 dx +0 tile 3 attr $20
    db $e0, $00, $03, $20   ; dy -32 dx +0 tile 3 attr $20
    db $d8, $00, $03, $20   ; dy -40 dx +0 tile 3 attr $20
    db $d0, $00, $03, $20   ; dy -48 dx +0 tile 3 attr $20
    db $f8, $2e, $03, $20   ; dy -8 dx +46 tile 3 attr $20
    db $f0, $2e, $03, $20   ; dy -16 dx +46 tile 3 attr $20
    db $e8, $2e, $03, $20   ; dy -24 dx +46 tile 3 attr $20
    db $e0, $2e, $03, $20   ; dy -32 dx +46 tile 3 attr $20
    db $d8, $2e, $03, $20   ; dy -40 dx +46 tile 3 attr $20
    db $d0, $2e, $03, $20   ; dy -48 dx +46 tile 3 attr $20
    db $80
Anim_2a_F05:   ; $6125 36 sprites
    db $f8, $d0, $03, $00   ; dy -8 dx -48 tile 3 attr $00
    db $f0, $d0, $03, $00   ; dy -16 dx -48 tile 3 attr $00
    db $e8, $d0, $03, $00   ; dy -24 dx -48 tile 3 attr $00
    db $e0, $d0, $03, $00   ; dy -32 dx -48 tile 3 attr $00
    db $d8, $d0, $03, $00   ; dy -40 dx -48 tile 3 attr $00
    db $d0, $d0, $03, $00   ; dy -48 dx -48 tile 3 attr $00
    db $f8, $d8, $03, $20   ; dy -8 dx -40 tile 3 attr $20
    db $f0, $d8, $03, $20   ; dy -16 dx -40 tile 3 attr $20
    db $e8, $d8, $03, $20   ; dy -24 dx -40 tile 3 attr $20
    db $e0, $d8, $03, $20   ; dy -32 dx -40 tile 3 attr $20
    db $d8, $d8, $03, $20   ; dy -40 dx -40 tile 3 attr $20
    db $d0, $d8, $03, $20   ; dy -48 dx -40 tile 3 attr $20
    db $f8, $3c, $03, $00   ; dy -8 dx +60 tile 3 attr $00
    db $f0, $3c, $03, $00   ; dy -16 dx +60 tile 3 attr $00
    db $e8, $3c, $03, $00   ; dy -24 dx +60 tile 3 attr $00
    db $e0, $3c, $03, $00   ; dy -32 dx +60 tile 3 attr $00
    db $d8, $3c, $03, $00   ; dy -40 dx +60 tile 3 attr $00
    db $d0, $3c, $03, $00   ; dy -48 dx +60 tile 3 attr $00
    db $f8, $44, $03, $20   ; dy -8 dx +68 tile 3 attr $20
    db $f0, $44, $03, $20   ; dy -16 dx +68 tile 3 attr $20
    db $e8, $44, $03, $20   ; dy -24 dx +68 tile 3 attr $20
    db $e0, $44, $03, $20   ; dy -32 dx +68 tile 3 attr $20
    db $d8, $44, $03, $20   ; dy -40 dx +68 tile 3 attr $20
    db $d0, $44, $03, $20   ; dy -48 dx +68 tile 3 attr $20
    db $f8, $10, $03, $00   ; dy -8 dx +16 tile 3 attr $00
    db $f0, $10, $03, $00   ; dy -16 dx +16 tile 3 attr $00
    db $e8, $10, $03, $00   ; dy -24 dx +16 tile 3 attr $00
    db $e0, $10, $03, $00   ; dy -32 dx +16 tile 3 attr $00
    db $d8, $10, $03, $00   ; dy -40 dx +16 tile 3 attr $00
    db $d0, $10, $03, $00   ; dy -48 dx +16 tile 3 attr $00
    db $f8, $18, $03, $20   ; dy -8 dx +24 tile 3 attr $20
    db $f0, $18, $03, $20   ; dy -16 dx +24 tile 3 attr $20
    db $e8, $18, $03, $20   ; dy -24 dx +24 tile 3 attr $20
    db $e0, $18, $03, $20   ; dy -32 dx +24 tile 3 attr $20
    db $d8, $18, $03, $20   ; dy -40 dx +24 tile 3 attr $20
    db $d0, $18, $03, $20   ; dy -48 dx +24 tile 3 attr $20
    db $80
Anim_2a_F06:   ; $61b6 36 sprites
    db $f8, $3c, $03, $20   ; dy -8 dx +60 tile 3 attr $20
    db $f0, $3c, $03, $20   ; dy -16 dx +60 tile 3 attr $20
    db $e8, $3c, $03, $20   ; dy -24 dx +60 tile 3 attr $20
    db $e0, $3c, $03, $20   ; dy -32 dx +60 tile 3 attr $20
    db $d8, $3c, $03, $20   ; dy -40 dx +60 tile 3 attr $20
    db $d0, $3c, $03, $20   ; dy -48 dx +60 tile 3 attr $20
    db $f8, $2c, $03, $00   ; dy -8 dx +44 tile 3 attr $00
    db $f0, $2c, $03, $00   ; dy -16 dx +44 tile 3 attr $00
    db $e8, $2c, $03, $00   ; dy -24 dx +44 tile 3 attr $00
    db $e0, $2c, $03, $00   ; dy -32 dx +44 tile 3 attr $00
    db $d8, $2c, $03, $00   ; dy -40 dx +44 tile 3 attr $00
    db $d0, $2c, $03, $00   ; dy -48 dx +44 tile 3 attr $00
    db $f8, $34, $04, $00   ; dy -8 dx +52 tile 4 attr $00
    db $f0, $34, $04, $00   ; dy -16 dx +52 tile 4 attr $00
    db $e8, $34, $04, $00   ; dy -24 dx +52 tile 4 attr $00
    db $e0, $34, $04, $00   ; dy -32 dx +52 tile 4 attr $00
    db $d8, $34, $04, $00   ; dy -40 dx +52 tile 4 attr $00
    db $d0, $34, $04, $00   ; dy -48 dx +52 tile 4 attr $00
    db $f8, $d0, $03, $20   ; dy -8 dx -48 tile 3 attr $20
    db $f0, $d0, $03, $20   ; dy -16 dx -48 tile 3 attr $20
    db $e8, $d0, $03, $20   ; dy -24 dx -48 tile 3 attr $20
    db $e0, $d0, $03, $20   ; dy -32 dx -48 tile 3 attr $20
    db $d8, $d0, $03, $20   ; dy -40 dx -48 tile 3 attr $20
    db $d0, $d0, $03, $20   ; dy -48 dx -48 tile 3 attr $20
    db $f8, $c0, $03, $00   ; dy -8 dx -64 tile 3 attr $00
    db $f0, $c0, $03, $00   ; dy -16 dx -64 tile 3 attr $00
    db $e8, $c0, $03, $00   ; dy -24 dx -64 tile 3 attr $00
    db $e0, $c0, $03, $00   ; dy -32 dx -64 tile 3 attr $00
    db $d8, $c0, $03, $00   ; dy -40 dx -64 tile 3 attr $00
    db $d0, $c0, $03, $00   ; dy -48 dx -64 tile 3 attr $00
    db $f8, $c8, $04, $00   ; dy -8 dx -56 tile 4 attr $00
    db $f0, $c8, $04, $00   ; dy -16 dx -56 tile 4 attr $00
    db $e8, $c8, $04, $00   ; dy -24 dx -56 tile 4 attr $00
    db $e0, $c8, $04, $00   ; dy -32 dx -56 tile 4 attr $00
    db $d8, $c8, $04, $00   ; dy -40 dx -56 tile 4 attr $00
    db $d0, $c8, $04, $00   ; dy -48 dx -56 tile 4 attr $00
    db $80
Anim_2a_F07:   ; $6247 36 sprites
    db $f8, $20, $03, $20   ; dy -8 dx +32 tile 3 attr $20
    db $f0, $20, $03, $20   ; dy -16 dx +32 tile 3 attr $20
    db $e8, $20, $03, $20   ; dy -24 dx +32 tile 3 attr $20
    db $e0, $20, $03, $20   ; dy -32 dx +32 tile 3 attr $20
    db $d8, $20, $03, $20   ; dy -40 dx +32 tile 3 attr $20
    db $d0, $20, $03, $20   ; dy -48 dx +32 tile 3 attr $20
    db $f8, $10, $03, $00   ; dy -8 dx +16 tile 3 attr $00
    db $f0, $10, $03, $00   ; dy -16 dx +16 tile 3 attr $00
    db $e8, $10, $03, $00   ; dy -24 dx +16 tile 3 attr $00
    db $e0, $10, $03, $00   ; dy -32 dx +16 tile 3 attr $00
    db $d8, $10, $03, $00   ; dy -40 dx +16 tile 3 attr $00
    db $d0, $10, $03, $00   ; dy -48 dx +16 tile 3 attr $00
    db $f8, $18, $04, $00   ; dy -8 dx +24 tile 4 attr $00
    db $f0, $18, $04, $00   ; dy -16 dx +24 tile 4 attr $00
    db $e8, $18, $04, $00   ; dy -24 dx +24 tile 4 attr $00
    db $e0, $18, $04, $00   ; dy -32 dx +24 tile 4 attr $00
    db $d8, $18, $04, $00   ; dy -40 dx +24 tile 4 attr $00
    db $d0, $18, $04, $00   ; dy -48 dx +24 tile 4 attr $00
    db $f8, $f0, $03, $20   ; dy -8 dx -16 tile 3 attr $20
    db $f0, $f0, $03, $20   ; dy -16 dx -16 tile 3 attr $20
    db $e8, $f0, $03, $20   ; dy -24 dx -16 tile 3 attr $20
    db $e0, $f0, $03, $20   ; dy -32 dx -16 tile 3 attr $20
    db $d8, $f0, $03, $20   ; dy -40 dx -16 tile 3 attr $20
    db $d0, $f0, $03, $20   ; dy -48 dx -16 tile 3 attr $20
    db $f8, $e0, $03, $00   ; dy -8 dx -32 tile 3 attr $00
    db $f0, $e0, $03, $00   ; dy -16 dx -32 tile 3 attr $00
    db $e8, $e0, $03, $00   ; dy -24 dx -32 tile 3 attr $00
    db $e0, $e0, $03, $00   ; dy -32 dx -32 tile 3 attr $00
    db $d8, $e0, $03, $00   ; dy -40 dx -32 tile 3 attr $00
    db $d0, $e0, $03, $00   ; dy -48 dx -32 tile 3 attr $00
    db $f8, $e8, $04, $00   ; dy -8 dx -24 tile 4 attr $00
    db $f0, $e8, $04, $00   ; dy -16 dx -24 tile 4 attr $00
    db $e8, $e8, $04, $00   ; dy -24 dx -24 tile 4 attr $00
    db $e0, $e8, $04, $00   ; dy -32 dx -24 tile 4 attr $00
    db $d8, $e8, $04, $00   ; dy -40 dx -24 tile 4 attr $00
    db $d0, $e8, $04, $00   ; dy -48 dx -24 tile 4 attr $00
    db $80
Anim_2a_F08:   ; $62d8 36 sprites
    db $f8, $e8, $03, $00   ; dy -8 dx -24 tile 3 attr $00
    db $f0, $e8, $03, $00   ; dy -16 dx -24 tile 3 attr $00
    db $e8, $e8, $03, $00   ; dy -24 dx -24 tile 3 attr $00
    db $e0, $e8, $03, $00   ; dy -32 dx -24 tile 3 attr $00
    db $d8, $e8, $03, $00   ; dy -40 dx -24 tile 3 attr $00
    db $d0, $e8, $03, $00   ; dy -48 dx -24 tile 3 attr $00
    db $f8, $f0, $04, $00   ; dy -8 dx -16 tile 4 attr $00
    db $f0, $f0, $04, $00   ; dy -16 dx -16 tile 4 attr $00
    db $e8, $f0, $04, $00   ; dy -24 dx -16 tile 4 attr $00
    db $e0, $f0, $04, $00   ; dy -32 dx -16 tile 4 attr $00
    db $d8, $f0, $04, $00   ; dy -40 dx -16 tile 4 attr $00
    db $d0, $f0, $04, $00   ; dy -48 dx -16 tile 4 attr $00
    db $f8, $10, $03, $20   ; dy -8 dx +16 tile 3 attr $20
    db $f0, $10, $03, $20   ; dy -16 dx +16 tile 3 attr $20
    db $e8, $10, $03, $20   ; dy -24 dx +16 tile 3 attr $20
    db $e0, $10, $03, $20   ; dy -32 dx +16 tile 3 attr $20
    db $d8, $10, $03, $20   ; dy -40 dx +16 tile 3 attr $20
    db $d0, $10, $03, $20   ; dy -48 dx +16 tile 3 attr $20
    db $f8, $08, $04, $00   ; dy -8 dx +8 tile 4 attr $00
    db $f0, $08, $04, $00   ; dy -16 dx +8 tile 4 attr $00
    db $e8, $08, $04, $00   ; dy -24 dx +8 tile 4 attr $00
    db $e0, $08, $04, $00   ; dy -32 dx +8 tile 4 attr $00
    db $d8, $08, $04, $00   ; dy -40 dx +8 tile 4 attr $00
    db $d0, $08, $04, $00   ; dy -48 dx +8 tile 4 attr $00
    db $f8, $00, $04, $00   ; dy -8 dx +0 tile 4 attr $00
    db $f0, $00, $04, $00   ; dy -16 dx +0 tile 4 attr $00
    db $e8, $00, $04, $00   ; dy -24 dx +0 tile 4 attr $00
    db $e0, $00, $04, $00   ; dy -32 dx +0 tile 4 attr $00
    db $d8, $00, $04, $00   ; dy -40 dx +0 tile 4 attr $00
    db $d0, $00, $04, $00   ; dy -48 dx +0 tile 4 attr $00
    db $f8, $f8, $04, $00   ; dy -8 dx -8 tile 4 attr $00
    db $f0, $f8, $04, $00   ; dy -16 dx -8 tile 4 attr $00
    db $e8, $f8, $04, $00   ; dy -24 dx -8 tile 4 attr $00
    db $e0, $f8, $04, $00   ; dy -32 dx -8 tile 4 attr $00
    db $d8, $f8, $04, $00   ; dy -40 dx -8 tile 4 attr $00
    db $d0, $f8, $04, $00   ; dy -48 dx -8 tile 4 attr $00
    db $80
Anim_2a_F09:   ; $6369 8 sprites
    db $d8, $18, $07, $00   ; dy -40 dx +24 tile 7 attr $00
    db $e4, $f8, $12, $00   ; dy -28 dx -8 tile 18 attr $00
    db $e4, $00, $13, $00   ; dy -28 dx +0 tile 19 attr $00
    db $f8, $40, $0c, $00   ; dy -8 dx +64 tile 12 attr $00
    db $f8, $48, $0d, $00   ; dy -8 dx +72 tile 13 attr $00
    db $f0, $30, $05, $00   ; dy -16 dx +48 tile 5 attr $00
    db $f8, $e8, $05, $00   ; dy -8 dx -24 tile 5 attr $00
    db $f0, $10, $07, $00   ; dy -16 dx +16 tile 7 attr $00
    db $80
Anim_2a_F10:   ; $638a 16 sprites
    db $d0, $fc, $10, $40   ; dy -48 dx -4 tile 16 attr $40
    db $f8, $08, $1f, $20   ; dy -8 dx +8 tile 31 attr $20
    db $f8, $00, $20, $20   ; dy -8 dx +0 tile 32 attr $20
    db $f8, $f8, $21, $20   ; dy -8 dx -8 tile 33 attr $20
    db $f0, $f8, $05, $40   ; dy -16 dx -8 tile 5 attr $40
    db $e8, $40, $0c, $00   ; dy -24 dx +64 tile 12 attr $00
    db $e8, $48, $0d, $00   ; dy -24 dx +72 tile 13 attr $00
    db $f0, $40, $0e, $00   ; dy -16 dx +64 tile 14 attr $00
    db $f0, $48, $0f, $00   ; dy -16 dx +72 tile 15 attr $00
    db $e0, $30, $05, $40   ; dy -32 dx +48 tile 5 attr $40
    db $f0, $28, $05, $00   ; dy -16 dx +40 tile 5 attr $00
    db $f4, $1c, $12, $20   ; dy -12 dx +28 tile 18 attr $20
    db $f4, $14, $13, $20   ; dy -12 dx +20 tile 19 attr $20
    db $e8, $e8, $05, $40   ; dy -24 dx -24 tile 5 attr $40
    db $f0, $b0, $06, $00   ; dy -16 dx -80 tile 6 attr $00
    db $d8, $10, $06, $40   ; dy -40 dx +16 tile 6 attr $40
    db $80
Anim_2a_F11:   ; $63cb 40 sprites
    db $e8, $f8, $1f, $00   ; dy -24 dx -8 tile 31 attr $00
    db $e8, $00, $20, $00   ; dy -24 dx +0 tile 32 attr $00
    db $e8, $08, $21, $00   ; dy -24 dx +8 tile 33 attr $00
    db $f0, $f8, $22, $00   ; dy -16 dx -8 tile 34 attr $00
    db $f0, $00, $23, $00   ; dy -16 dx +0 tile 35 attr $00
    db $f0, $08, $24, $00   ; dy -16 dx +8 tile 36 attr $00
    db $f8, $f8, $25, $00   ; dy -8 dx -8 tile 37 attr $00
    db $f8, $00, $26, $00   ; dy -8 dx +0 tile 38 attr $00
    db $f8, $08, $27, $00   ; dy -8 dx +8 tile 39 attr $00
    db $e0, $c0, $1b, $00   ; dy -32 dx -64 tile 27 attr $00
    db $e0, $c8, $1c, $00   ; dy -32 dx -56 tile 28 attr $00
    db $e0, $d0, $1d, $00   ; dy -32 dx -48 tile 29 attr $00
    db $e0, $d8, $1e, $00   ; dy -32 dx -40 tile 30 attr $00
    db $d8, $c0, $17, $00   ; dy -40 dx -64 tile 23 attr $00
    db $d8, $c8, $18, $00   ; dy -40 dx -56 tile 24 attr $00
    db $d8, $d0, $19, $00   ; dy -40 dx -48 tile 25 attr $00
    db $d8, $d8, $1a, $00   ; dy -40 dx -40 tile 26 attr $00
    db $d0, $c1, $14, $00   ; dy -48 dx -63 tile 20 attr $00
    db $d0, $c9, $15, $00   ; dy -48 dx -55 tile 21 attr $00
    db $d0, $d1, $16, $00   ; dy -48 dx -47 tile 22 attr $00
    db $d8, $40, $08, $00   ; dy -40 dx +64 tile 8 attr $00
    db $d8, $48, $09, $00   ; dy -40 dx +72 tile 9 attr $00
    db $e0, $40, $0a, $00   ; dy -32 dx +64 tile 10 attr $00
    db $e0, $48, $0b, $00   ; dy -32 dx +72 tile 11 attr $00
    db $f0, $28, $07, $00   ; dy -16 dx +40 tile 7 attr $00
    db $e0, $b0, $06, $00   ; dy -32 dx -80 tile 6 attr $00
    db $e0, $f8, $05, $20   ; dy -32 dx -8 tile 5 attr $20
    db $f0, $d8, $06, $20   ; dy -16 dx -40 tile 6 attr $20
    db $d0, $30, $05, $00   ; dy -48 dx +48 tile 5 attr $00
    db $f8, $c8, $07, $20   ; dy -8 dx -56 tile 7 attr $20
    db $e8, $18, $11, $00   ; dy -24 dx +24 tile 17 attr $00
    db $e0, $18, $10, $00   ; dy -32 dx +24 tile 16 attr $00
    db $f8, $b8, $11, $00   ; dy -8 dx -72 tile 17 attr $00
    db $f0, $b8, $10, $00   ; dy -16 dx -72 tile 16 attr $00
    db $f0, $30, $0c, $00   ; dy -16 dx +48 tile 12 attr $00
    db $f0, $38, $0d, $00   ; dy -16 dx +56 tile 13 attr $00
    db $f8, $30, $0e, $00   ; dy -8 dx +48 tile 14 attr $00
    db $f8, $38, $0f, $00   ; dy -8 dx +56 tile 15 attr $00
    db $d8, $e8, $05, $00   ; dy -40 dx -24 tile 5 attr $00
    db $e0, $28, $05, $40   ; dy -32 dx +40 tile 5 attr $40
    db $80
Anim_2a_F12:   ; $646c 40 sprites
    db $d8, $f8, $1f, $00   ; dy -40 dx -8 tile 31 attr $00
    db $d8, $00, $20, $00   ; dy -40 dx +0 tile 32 attr $00
    db $d8, $08, $21, $00   ; dy -40 dx +8 tile 33 attr $00
    db $e0, $f8, $22, $00   ; dy -32 dx -8 tile 34 attr $00
    db $e0, $00, $23, $00   ; dy -32 dx +0 tile 35 attr $00
    db $e0, $08, $24, $00   ; dy -32 dx +8 tile 36 attr $00
    db $e8, $f8, $25, $00   ; dy -24 dx -8 tile 37 attr $00
    db $e8, $00, $26, $00   ; dy -24 dx +0 tile 38 attr $00
    db $e8, $08, $27, $00   ; dy -24 dx +8 tile 39 attr $00
    db $d0, $d8, $1b, $20   ; dy -48 dx -40 tile 27 attr $20
    db $d0, $d0, $1c, $20   ; dy -48 dx -48 tile 28 attr $20
    db $d0, $c8, $1d, $20   ; dy -48 dx -56 tile 29 attr $20
    db $d0, $c0, $1e, $20   ; dy -48 dx -64 tile 30 attr $20
    db $d0, $48, $0a, $20   ; dy -48 dx +72 tile 10 attr $20
    db $d0, $40, $0b, $20   ; dy -48 dx +64 tile 11 attr $20
    db $e0, $28, $07, $20   ; dy -32 dx +40 tile 7 attr $20
    db $d0, $b0, $06, $20   ; dy -48 dx -80 tile 6 attr $20
    db $d0, $f8, $05, $20   ; dy -48 dx -8 tile 5 attr $20
    db $e0, $d8, $06, $00   ; dy -32 dx -40 tile 6 attr $00
    db $e8, $c8, $07, $00   ; dy -24 dx -56 tile 7 attr $00
    db $d8, $14, $11, $20   ; dy -40 dx +20 tile 17 attr $20
    db $d0, $14, $10, $20   ; dy -48 dx +20 tile 16 attr $20
    db $e8, $b4, $11, $20   ; dy -24 dx -76 tile 17 attr $20
    db $e0, $b4, $10, $20   ; dy -32 dx -76 tile 16 attr $20
    db $e0, $38, $0c, $20   ; dy -32 dx +56 tile 12 attr $20
    db $e0, $30, $0d, $20   ; dy -32 dx +48 tile 13 attr $20
    db $e8, $38, $0e, $20   ; dy -24 dx +56 tile 14 attr $20
    db $e8, $30, $0f, $20   ; dy -24 dx +48 tile 15 attr $20
    db $d0, $28, $05, $20   ; dy -48 dx +40 tile 5 attr $20
    db $f0, $fa, $28, $00   ; dy -16 dx -6 tile 40 attr $00
    db $f0, $02, $29, $00   ; dy -16 dx +2 tile 41 attr $00
    db $f8, $2f, $14, $00   ; dy -8 dx +47 tile 20 attr $00
    db $f8, $37, $15, $00   ; dy -8 dx +55 tile 21 attr $00
    db $f8, $3f, $16, $00   ; dy -8 dx +63 tile 22 attr $00
    db $f0, $48, $05, $00   ; dy -16 dx +72 tile 5 attr $00
    db $f8, $18, $07, $00   ; dy -8 dx +24 tile 7 attr $00
    db $f0, $e8, $06, $00   ; dy -16 dx -24 tile 6 attr $00
    db $f8, $d8, $05, $00   ; dy -8 dx -40 tile 5 attr $00
    db $f8, $b8, $12, $00   ; dy -8 dx -72 tile 18 attr $00
    db $f8, $c0, $13, $00   ; dy -8 dx -64 tile 19 attr $00
    db $80
Anim_2a_F13:   ; $650d 40 sprites
    db $d0, $08, $22, $20   ; dy -48 dx +8 tile 34 attr $20
    db $d0, $00, $23, $20   ; dy -48 dx +0 tile 35 attr $20
    db $d0, $f8, $24, $20   ; dy -48 dx -8 tile 36 attr $20
    db $d8, $08, $25, $20   ; dy -40 dx +8 tile 37 attr $20
    db $d8, $00, $26, $20   ; dy -40 dx +0 tile 38 attr $20
    db $d8, $f8, $27, $20   ; dy -40 dx -8 tile 39 attr $20
    db $d0, $28, $07, $00   ; dy -48 dx +40 tile 7 attr $00
    db $d0, $d8, $06, $40   ; dy -48 dx -40 tile 6 attr $40
    db $d8, $c8, $07, $40   ; dy -40 dx -56 tile 7 attr $40
    db $d0, $b4, $11, $60   ; dy -48 dx -76 tile 17 attr $60
    db $d8, $b4, $10, $60   ; dy -40 dx -76 tile 16 attr $60
    db $d8, $30, $0c, $40   ; dy -40 dx +48 tile 12 attr $40
    db $d8, $38, $0d, $40   ; dy -40 dx +56 tile 13 attr $40
    db $d0, $30, $0e, $40   ; dy -48 dx +48 tile 14 attr $40
    db $d0, $38, $0f, $40   ; dy -48 dx +56 tile 15 attr $40
    db $e0, $06, $28, $20   ; dy -32 dx +6 tile 40 attr $20
    db $e0, $fe, $29, $20   ; dy -32 dx -2 tile 41 attr $20
    db $e0, $48, $05, $40   ; dy -32 dx +72 tile 5 attr $40
    db $e8, $18, $07, $40   ; dy -24 dx +24 tile 7 attr $40
    db $e0, $e8, $06, $00   ; dy -32 dx -24 tile 6 attr $00
    db $e8, $d8, $05, $40   ; dy -24 dx -40 tile 5 attr $40
    db $f0, $bc, $11, $00   ; dy -16 dx -68 tile 17 attr $00
    db $e8, $bc, $10, $00   ; dy -24 dx -68 tile 16 attr $00
    db $e8, $2f, $14, $00   ; dy -24 dx +47 tile 20 attr $00
    db $e8, $37, $15, $00   ; dy -24 dx +55 tile 21 attr $00
    db $e8, $3f, $16, $00   ; dy -24 dx +63 tile 22 attr $00
    db $f0, $2e, $17, $00   ; dy -16 dx +46 tile 23 attr $00
    db $f0, $36, $18, $00   ; dy -16 dx +54 tile 24 attr $00
    db $f0, $3e, $19, $00   ; dy -16 dx +62 tile 25 attr $00
    db $f0, $46, $1a, $00   ; dy -16 dx +70 tile 26 attr $00
    db $f8, $2e, $1b, $00   ; dy -8 dx +46 tile 27 attr $00
    db $f8, $36, $1c, $00   ; dy -8 dx +54 tile 28 attr $00
    db $f8, $3e, $1d, $00   ; dy -8 dx +62 tile 29 attr $00
    db $f8, $46, $1e, $00   ; dy -8 dx +70 tile 30 attr $00
    db $f0, $f8, $10, $00   ; dy -16 dx -8 tile 16 attr $00
    db $f8, $f8, $11, $00   ; dy -8 dx -8 tile 17 attr $00
    db $f0, $d0, $08, $00   ; dy -16 dx -48 tile 8 attr $00
    db $f0, $d8, $09, $00   ; dy -16 dx -40 tile 9 attr $00
    db $f8, $d0, $0a, $00   ; dy -8 dx -48 tile 10 attr $00
    db $f8, $d8, $0b, $00   ; dy -8 dx -40 tile 11 attr $00
    db $80
Anim_2a_F14:   ; $65ae 37 sprites
    db $d0, $fa, $28, $00   ; dy -48 dx -6 tile 40 attr $00
    db $d0, $02, $29, $00   ; dy -48 dx +2 tile 41 attr $00
    db $d0, $48, $05, $60   ; dy -48 dx +72 tile 5 attr $60
    db $d8, $18, $07, $00   ; dy -40 dx +24 tile 7 attr $00
    db $d0, $e8, $06, $00   ; dy -48 dx -24 tile 6 attr $00
    db $d8, $d8, $05, $00   ; dy -40 dx -40 tile 5 attr $00
    db $e8, $45, $14, $60   ; dy -24 dx +69 tile 20 attr $60
    db $e8, $3d, $15, $60   ; dy -24 dx +61 tile 21 attr $60
    db $e8, $35, $16, $60   ; dy -24 dx +53 tile 22 attr $60
    db $e0, $46, $17, $60   ; dy -32 dx +70 tile 23 attr $60
    db $e0, $3e, $18, $60   ; dy -32 dx +62 tile 24 attr $60
    db $e0, $36, $19, $60   ; dy -32 dx +54 tile 25 attr $60
    db $e0, $2e, $1a, $60   ; dy -32 dx +46 tile 26 attr $60
    db $d8, $46, $1b, $60   ; dy -40 dx +70 tile 27 attr $60
    db $d8, $3e, $1c, $60   ; dy -40 dx +62 tile 28 attr $60
    db $d8, $36, $1d, $60   ; dy -40 dx +54 tile 29 attr $60
    db $d8, $2e, $1e, $60   ; dy -40 dx +46 tile 30 attr $60
    db $e8, $d0, $08, $40   ; dy -24 dx -48 tile 8 attr $40
    db $e8, $d8, $09, $40   ; dy -24 dx -40 tile 9 attr $40
    db $e0, $d0, $0a, $40   ; dy -32 dx -48 tile 10 attr $40
    db $e0, $d8, $0b, $40   ; dy -32 dx -40 tile 11 attr $40
    db $e4, $f8, $12, $00   ; dy -28 dx -8 tile 18 attr $00
    db $e4, $00, $13, $00   ; dy -28 dx +0 tile 19 attr $00
    db $dc, $b8, $12, $40   ; dy -36 dx -72 tile 18 attr $40
    db $dc, $c0, $13, $40   ; dy -36 dx -64 tile 19 attr $40
    db $f0, $d7, $14, $20   ; dy -16 dx -41 tile 20 attr $20
    db $f0, $cf, $15, $20   ; dy -16 dx -49 tile 21 attr $20
    db $f0, $c7, $16, $20   ; dy -16 dx -57 tile 22 attr $20
    db $f8, $d8, $17, $20   ; dy -8 dx -40 tile 23 attr $20
    db $f8, $d0, $18, $20   ; dy -8 dx -48 tile 24 attr $20
    db $f8, $c8, $19, $20   ; dy -8 dx -56 tile 25 attr $20
    db $f8, $c0, $1a, $20   ; dy -8 dx -64 tile 26 attr $20
    db $f8, $40, $0c, $00   ; dy -8 dx +64 tile 12 attr $00
    db $f8, $48, $0d, $00   ; dy -8 dx +72 tile 13 attr $00
    db $f0, $30, $05, $00   ; dy -16 dx +48 tile 5 attr $00
    db $f8, $e8, $05, $00   ; dy -8 dx -24 tile 5 attr $00
    db $f0, $10, $07, $00   ; dy -16 dx +16 tile 7 attr $00
    db $80
Anim_2a_F15:   ; $6643 38 sprites
    db $d8, $2f, $14, $40   ; dy -40 dx +47 tile 20 attr $40
    db $d8, $37, $15, $40   ; dy -40 dx +55 tile 21 attr $40
    db $d8, $3f, $16, $40   ; dy -40 dx +63 tile 22 attr $40
    db $d0, $2e, $17, $40   ; dy -48 dx +46 tile 23 attr $40
    db $d0, $36, $18, $40   ; dy -48 dx +54 tile 24 attr $40
    db $d0, $3e, $19, $40   ; dy -48 dx +62 tile 25 attr $40
    db $d0, $46, $1a, $40   ; dy -48 dx +70 tile 26 attr $40
    db $d8, $d0, $08, $40   ; dy -40 dx -48 tile 8 attr $40
    db $d8, $d8, $09, $40   ; dy -40 dx -40 tile 9 attr $40
    db $d0, $d0, $0a, $40   ; dy -48 dx -48 tile 10 attr $40
    db $d0, $d8, $0b, $40   ; dy -48 dx -40 tile 11 attr $40
    db $f0, $d7, $14, $60   ; dy -16 dx -41 tile 20 attr $60
    db $f0, $cf, $15, $60   ; dy -16 dx -49 tile 21 attr $60
    db $f0, $c7, $16, $60   ; dy -16 dx -57 tile 22 attr $60
    db $e8, $d8, $17, $60   ; dy -24 dx -40 tile 23 attr $60
    db $e8, $d0, $18, $60   ; dy -24 dx -48 tile 24 attr $60
    db $e8, $c8, $19, $60   ; dy -24 dx -56 tile 25 attr $60
    db $e8, $c0, $1a, $60   ; dy -24 dx -64 tile 26 attr $60
    db $e0, $d8, $1b, $60   ; dy -32 dx -40 tile 27 attr $60
    db $e0, $d0, $1c, $60   ; dy -32 dx -48 tile 28 attr $60
    db $e0, $c8, $1d, $60   ; dy -32 dx -56 tile 29 attr $60
    db $e0, $c0, $1e, $60   ; dy -32 dx -64 tile 30 attr $60
    db $d0, $fc, $10, $40   ; dy -48 dx -4 tile 16 attr $40
    db $f8, $08, $1f, $20   ; dy -8 dx +8 tile 31 attr $20
    db $f8, $00, $20, $20   ; dy -8 dx +0 tile 32 attr $20
    db $f8, $f8, $21, $20   ; dy -8 dx -8 tile 33 attr $20
    db $f0, $f8, $05, $40   ; dy -16 dx -8 tile 5 attr $40
    db $e8, $40, $0c, $00   ; dy -24 dx +64 tile 12 attr $00
    db $e8, $48, $0d, $00   ; dy -24 dx +72 tile 13 attr $00
    db $f0, $40, $0e, $00   ; dy -16 dx +64 tile 14 attr $00
    db $f0, $48, $0f, $00   ; dy -16 dx +72 tile 15 attr $00
    db $e0, $30, $05, $40   ; dy -32 dx +48 tile 5 attr $40
    db $f0, $28, $05, $00   ; dy -16 dx +40 tile 5 attr $00
    db $f4, $1c, $12, $20   ; dy -12 dx +28 tile 18 attr $20
    db $f4, $14, $13, $20   ; dy -12 dx +20 tile 19 attr $20
    db $e8, $e8, $05, $40   ; dy -24 dx -24 tile 5 attr $40
    db $f0, $b0, $06, $00   ; dy -16 dx -80 tile 6 attr $00
    db $d8, $10, $06, $40   ; dy -40 dx +16 tile 6 attr $40
    db $80
Anim_2a_F16:   ; $66dc 40 sprites
    db $f0, $38, $07, $00   ; dy -16 dx +56 tile 7 attr $00
    db $e0, $08, $05, $20   ; dy -32 dx +8 tile 5 attr $20
    db $f0, $e8, $06, $20   ; dy -16 dx -24 tile 6 attr $20
    db $d0, $40, $05, $00   ; dy -48 dx +64 tile 5 attr $00
    db $e8, $28, $11, $00   ; dy -24 dx +40 tile 17 attr $00
    db $e0, $28, $10, $00   ; dy -32 dx +40 tile 16 attr $00
    db $e0, $38, $05, $40   ; dy -32 dx +56 tile 5 attr $40
    db $e8, $10, $1b, $60   ; dy -24 dx +16 tile 27 attr $60
    db $e8, $08, $1c, $60   ; dy -24 dx +8 tile 28 attr $60
    db $e8, $00, $1d, $60   ; dy -24 dx +0 tile 29 attr $60
    db $e8, $f8, $1e, $60   ; dy -24 dx -8 tile 30 attr $60
    db $f0, $10, $17, $60   ; dy -16 dx +16 tile 23 attr $60
    db $f0, $08, $18, $60   ; dy -16 dx +8 tile 24 attr $60
    db $f0, $00, $19, $60   ; dy -16 dx +0 tile 25 attr $60
    db $f0, $f8, $1a, $60   ; dy -16 dx -8 tile 26 attr $60
    db $f8, $0f, $14, $60   ; dy -8 dx +15 tile 20 attr $60
    db $f8, $07, $15, $60   ; dy -8 dx +7 tile 21 attr $60
    db $f8, $ff, $16, $60   ; dy -8 dx -1 tile 22 attr $60
    db $e0, $b0, $06, $00   ; dy -32 dx -80 tile 6 attr $00
    db $e0, $40, $0c, $40   ; dy -32 dx +64 tile 12 attr $40
    db $e0, $48, $0d, $40   ; dy -32 dx +72 tile 13 attr $40
    db $d8, $40, $0e, $40   ; dy -40 dx +64 tile 14 attr $40
    db $d8, $48, $0f, $40   ; dy -40 dx +72 tile 15 attr $40
    db $d8, $e8, $05, $00   ; dy -40 dx -24 tile 5 attr $00
    db $e0, $c0, $1b, $00   ; dy -32 dx -64 tile 27 attr $00
    db $e0, $c8, $1c, $00   ; dy -32 dx -56 tile 28 attr $00
    db $e0, $d0, $1d, $00   ; dy -32 dx -48 tile 29 attr $00
    db $e0, $d8, $1e, $00   ; dy -32 dx -40 tile 30 attr $00
    db $d8, $c0, $17, $00   ; dy -40 dx -64 tile 23 attr $00
    db $d8, $c8, $18, $00   ; dy -40 dx -56 tile 24 attr $00
    db $d8, $d0, $19, $00   ; dy -40 dx -48 tile 25 attr $00
    db $d8, $d8, $1a, $00   ; dy -40 dx -40 tile 26 attr $00
    db $d0, $c1, $14, $00   ; dy -48 dx -63 tile 20 attr $00
    db $d0, $c9, $15, $00   ; dy -48 dx -55 tile 21 attr $00
    db $d0, $d1, $16, $00   ; dy -48 dx -47 tile 22 attr $00
    db $f8, $20, $05, $00   ; dy -8 dx +32 tile 5 attr $00
    db $f0, $c0, $08, $00   ; dy -16 dx -64 tile 8 attr $00
    db $f0, $c8, $09, $00   ; dy -16 dx -56 tile 9 attr $00
    db $f8, $c0, $0a, $00   ; dy -8 dx -64 tile 10 attr $00
    db $f8, $c8, $0b, $00   ; dy -8 dx -56 tile 11 attr $00
    db $80
Anim_2a_F17:   ; $677d 36 sprites
    db $e0, $38, $07, $20   ; dy -32 dx +56 tile 7 attr $20
    db $d0, $08, $05, $00   ; dy -48 dx +8 tile 5 attr $00
    db $e0, $e8, $06, $00   ; dy -32 dx -24 tile 6 attr $00
    db $d8, $28, $11, $20   ; dy -40 dx +40 tile 17 attr $20
    db $d0, $28, $10, $20   ; dy -48 dx +40 tile 16 attr $20
    db $d0, $38, $05, $60   ; dy -48 dx +56 tile 5 attr $60
    db $e8, $10, $1b, $20   ; dy -24 dx +16 tile 27 attr $20
    db $e8, $08, $1c, $20   ; dy -24 dx +8 tile 28 attr $20
    db $e8, $00, $1d, $20   ; dy -24 dx +0 tile 29 attr $20
    db $e8, $f8, $1e, $20   ; dy -24 dx -8 tile 30 attr $20
    db $e0, $10, $17, $20   ; dy -32 dx +16 tile 23 attr $20
    db $e0, $08, $18, $20   ; dy -32 dx +8 tile 24 attr $20
    db $e0, $00, $19, $20   ; dy -32 dx +0 tile 25 attr $20
    db $e0, $f8, $1a, $20   ; dy -32 dx -8 tile 26 attr $20
    db $d8, $0f, $14, $20   ; dy -40 dx +15 tile 20 attr $20
    db $d8, $07, $15, $20   ; dy -40 dx +7 tile 21 attr $20
    db $d8, $ff, $16, $20   ; dy -40 dx -1 tile 22 attr $20
    db $d0, $b0, $06, $00   ; dy -48 dx -80 tile 6 attr $00
    db $d0, $48, $0c, $60   ; dy -48 dx +72 tile 12 attr $60
    db $d0, $40, $0d, $60   ; dy -48 dx +64 tile 13 attr $60
    db $d0, $d8, $1b, $20   ; dy -48 dx -40 tile 27 attr $20
    db $d0, $d0, $1c, $20   ; dy -48 dx -48 tile 28 attr $20
    db $d0, $c8, $1d, $20   ; dy -48 dx -56 tile 29 attr $20
    db $d0, $c0, $1e, $20   ; dy -48 dx -64 tile 30 attr $20
    db $e8, $20, $05, $20   ; dy -24 dx +32 tile 5 attr $20
    db $e8, $c0, $08, $40   ; dy -24 dx -64 tile 8 attr $40
    db $e8, $c8, $09, $40   ; dy -24 dx -56 tile 9 attr $40
    db $e0, $c0, $0a, $40   ; dy -32 dx -64 tile 10 attr $40
    db $e0, $c8, $0b, $40   ; dy -32 dx -56 tile 11 attr $40
    db $f8, $20, $1f, $00   ; dy -8 dx +32 tile 31 attr $00
    db $f8, $28, $20, $00   ; dy -8 dx +40 tile 32 attr $00
    db $f8, $30, $21, $00   ; dy -8 dx +48 tile 33 attr $00
    db $f8, $f0, $06, $00   ; dy -8 dx -16 tile 6 attr $00
    db $f8, $b8, $07, $00   ; dy -8 dx -72 tile 7 attr $00
    db $f4, $3c, $12, $00   ; dy -12 dx +60 tile 18 attr $00
    db $f4, $44, $13, $00   ; dy -12 dx +68 tile 19 attr $00
    db $80
Anim_2a_F18:   ; $680e 35 sprites
    db $d0, $38, $07, $20   ; dy -48 dx +56 tile 7 attr $20
    db $d0, $e8, $06, $00   ; dy -48 dx -24 tile 6 attr $00
    db $d8, $10, $1b, $20   ; dy -40 dx +16 tile 27 attr $20
    db $d8, $08, $1c, $20   ; dy -40 dx +8 tile 28 attr $20
    db $d8, $00, $1d, $20   ; dy -40 dx +0 tile 29 attr $20
    db $d8, $f8, $1e, $20   ; dy -40 dx -8 tile 30 attr $20
    db $d0, $10, $17, $20   ; dy -48 dx +16 tile 23 attr $20
    db $d0, $08, $18, $20   ; dy -48 dx +8 tile 24 attr $20
    db $d0, $00, $19, $20   ; dy -48 dx +0 tile 25 attr $20
    db $d0, $f8, $1a, $20   ; dy -48 dx -8 tile 26 attr $20
    db $d8, $20, $05, $20   ; dy -40 dx +32 tile 5 attr $20
    db $d8, $c0, $08, $40   ; dy -40 dx -64 tile 8 attr $40
    db $d8, $c8, $09, $40   ; dy -40 dx -56 tile 9 attr $40
    db $d0, $c0, $0a, $40   ; dy -48 dx -64 tile 10 attr $40
    db $d0, $c8, $0b, $40   ; dy -48 dx -56 tile 11 attr $40
    db $e8, $30, $1f, $20   ; dy -24 dx +48 tile 31 attr $20
    db $e8, $28, $20, $20   ; dy -24 dx +40 tile 32 attr $20
    db $e8, $20, $21, $20   ; dy -24 dx +32 tile 33 attr $20
    db $e8, $f0, $06, $00   ; dy -24 dx -16 tile 6 attr $00
    db $e8, $b8, $07, $00   ; dy -24 dx -72 tile 7 attr $00
    db $e4, $3c, $12, $00   ; dy -28 dx +60 tile 18 attr $00
    db $e4, $44, $13, $00   ; dy -28 dx +68 tile 19 attr $00
    db $f0, $30, $22, $20   ; dy -16 dx +48 tile 34 attr $20
    db $f0, $28, $23, $20   ; dy -16 dx +40 tile 35 attr $20
    db $f0, $20, $24, $20   ; dy -16 dx +32 tile 36 attr $20
    db $f8, $30, $25, $20   ; dy -8 dx +48 tile 37 attr $20
    db $f8, $28, $26, $20   ; dy -8 dx +40 tile 38 attr $20
    db $f8, $20, $27, $20   ; dy -8 dx +32 tile 39 attr $20
    db $f0, $d0, $08, $00   ; dy -16 dx -48 tile 8 attr $00
    db $f0, $d8, $09, $00   ; dy -16 dx -40 tile 9 attr $00
    db $f8, $d0, $0a, $00   ; dy -8 dx -48 tile 10 attr $00
    db $f8, $d8, $0b, $00   ; dy -8 dx -40 tile 11 attr $00
    db $f0, $f8, $10, $00   ; dy -16 dx -8 tile 16 attr $00
    db $f8, $f8, $11, $00   ; dy -8 dx -8 tile 17 attr $00
    db $f8, $bc, $10, $00   ; dy -8 dx -68 tile 16 attr $00
    db $80
Anim_2a_F19:   ; $689b 33 sprites
    db $d8, $20, $1f, $00   ; dy -40 dx +32 tile 31 attr $00
    db $d8, $28, $20, $00   ; dy -40 dx +40 tile 32 attr $00
    db $d8, $30, $21, $00   ; dy -40 dx +48 tile 33 attr $00
    db $d8, $f0, $06, $00   ; dy -40 dx -16 tile 6 attr $00
    db $d8, $b8, $07, $00   ; dy -40 dx -72 tile 7 attr $00
    db $d4, $3c, $12, $00   ; dy -44 dx +60 tile 18 attr $00
    db $d4, $44, $13, $00   ; dy -44 dx +68 tile 19 attr $00
    db $e0, $20, $22, $00   ; dy -32 dx +32 tile 34 attr $00
    db $e0, $28, $23, $00   ; dy -32 dx +40 tile 35 attr $00
    db $e0, $30, $24, $00   ; dy -32 dx +48 tile 36 attr $00
    db $e8, $20, $25, $00   ; dy -24 dx +32 tile 37 attr $00
    db $e8, $28, $26, $00   ; dy -24 dx +40 tile 38 attr $00
    db $e8, $30, $27, $00   ; dy -24 dx +48 tile 39 attr $00
    db $e0, $d0, $08, $00   ; dy -32 dx -48 tile 8 attr $00
    db $e0, $d8, $09, $00   ; dy -32 dx -40 tile 9 attr $00
    db $e8, $d0, $0a, $00   ; dy -24 dx -48 tile 10 attr $00
    db $e8, $d8, $0b, $00   ; dy -24 dx -40 tile 11 attr $00
    db $e8, $bc, $10, $00   ; dy -24 dx -68 tile 16 attr $00
    db $f0, $22, $28, $00   ; dy -16 dx +34 tile 40 attr $00
    db $f0, $2a, $29, $00   ; dy -16 dx +42 tile 41 attr $00
    db $f0, $d7, $14, $20   ; dy -16 dx -41 tile 20 attr $20
    db $f0, $cf, $15, $20   ; dy -16 dx -49 tile 21 attr $20
    db $f0, $c7, $16, $20   ; dy -16 dx -57 tile 22 attr $20
    db $f8, $d8, $17, $20   ; dy -8 dx -40 tile 23 attr $20
    db $f8, $d0, $18, $20   ; dy -8 dx -48 tile 24 attr $20
    db $f8, $c8, $19, $20   ; dy -8 dx -56 tile 25 attr $20
    db $f8, $c0, $1a, $20   ; dy -8 dx -64 tile 26 attr $20
    db $f8, $40, $0c, $00   ; dy -8 dx +64 tile 12 attr $00
    db $f8, $48, $0d, $00   ; dy -8 dx +72 tile 13 attr $00
    db $f0, $10, $07, $00   ; dy -16 dx +16 tile 7 attr $00
    db $e4, $f4, $12, $00   ; dy -28 dx -12 tile 18 attr $00
    db $e4, $fc, $13, $00   ; dy -28 dx -4 tile 19 attr $00
    db $f8, $e8, $05, $00   ; dy -8 dx -24 tile 5 attr $00
    db $80
Anim_2a_F20:   ; $6920 40 sprites
    db $d0, $20, $22, $00   ; dy -48 dx +32 tile 34 attr $00
    db $d0, $28, $23, $00   ; dy -48 dx +40 tile 35 attr $00
    db $d0, $30, $24, $00   ; dy -48 dx +48 tile 36 attr $00
    db $d8, $20, $25, $00   ; dy -40 dx +32 tile 37 attr $00
    db $d8, $28, $26, $00   ; dy -40 dx +40 tile 38 attr $00
    db $d8, $30, $27, $00   ; dy -40 dx +48 tile 39 attr $00
    db $d0, $d0, $08, $00   ; dy -48 dx -48 tile 8 attr $00
    db $d0, $d8, $09, $00   ; dy -48 dx -40 tile 9 attr $00
    db $d8, $d0, $0a, $00   ; dy -40 dx -48 tile 10 attr $00
    db $d8, $d8, $0b, $00   ; dy -40 dx -40 tile 11 attr $00
    db $d8, $bc, $10, $00   ; dy -40 dx -68 tile 16 attr $00
    db $e0, $22, $28, $00   ; dy -32 dx +34 tile 40 attr $00
    db $e0, $2a, $29, $00   ; dy -32 dx +42 tile 41 attr $00
    db $e8, $40, $0c, $00   ; dy -24 dx +64 tile 12 attr $00
    db $e8, $48, $0d, $00   ; dy -24 dx +72 tile 13 attr $00
    db $e0, $10, $07, $00   ; dy -32 dx +16 tile 7 attr $00
    db $d4, $f4, $12, $00   ; dy -44 dx -12 tile 18 attr $00
    db $d4, $fc, $13, $00   ; dy -44 dx -4 tile 19 attr $00
    db $e8, $e8, $05, $00   ; dy -24 dx -24 tile 5 attr $00
    db $f8, $08, $1f, $20   ; dy -8 dx +8 tile 31 attr $20
    db $f8, $00, $20, $20   ; dy -8 dx +0 tile 32 attr $20
    db $f8, $f8, $21, $20   ; dy -8 dx -8 tile 33 attr $20
    db $f0, $f8, $05, $40   ; dy -16 dx -8 tile 5 attr $40
    db $f0, $40, $0e, $00   ; dy -16 dx +64 tile 14 attr $00
    db $f0, $48, $0f, $00   ; dy -16 dx +72 tile 15 attr $00
    db $f0, $28, $05, $00   ; dy -16 dx +40 tile 5 attr $00
    db $f4, $1d, $12, $20   ; dy -12 dx +29 tile 18 attr $20
    db $f4, $15, $13, $20   ; dy -12 dx +21 tile 19 attr $20
    db $f0, $b0, $06, $00   ; dy -16 dx -80 tile 6 attr $00
    db $f0, $d7, $14, $60   ; dy -16 dx -41 tile 20 attr $60
    db $f0, $cf, $15, $60   ; dy -16 dx -49 tile 21 attr $60
    db $f0, $c7, $16, $60   ; dy -16 dx -57 tile 22 attr $60
    db $e8, $d8, $17, $60   ; dy -24 dx -40 tile 23 attr $60
    db $e8, $d0, $18, $60   ; dy -24 dx -48 tile 24 attr $60
    db $e8, $c8, $19, $60   ; dy -24 dx -56 tile 25 attr $60
    db $e8, $c0, $1a, $60   ; dy -24 dx -64 tile 26 attr $60
    db $e0, $d8, $1b, $60   ; dy -32 dx -40 tile 27 attr $60
    db $e0, $d0, $1c, $60   ; dy -32 dx -48 tile 28 attr $60
    db $e0, $c8, $1d, $60   ; dy -32 dx -56 tile 29 attr $60
    db $e0, $c0, $1e, $60   ; dy -32 dx -64 tile 30 attr $60
    db $80
Anim_2a_F21:   ; $69c1 31 sprites
    db $e8, $f8, $1f, $00   ; dy -24 dx -8 tile 31 attr $00
    db $e8, $00, $20, $00   ; dy -24 dx +0 tile 32 attr $00
    db $e8, $08, $21, $00   ; dy -24 dx +8 tile 33 attr $00
    db $f0, $f8, $22, $00   ; dy -16 dx -8 tile 34 attr $00
    db $f0, $00, $23, $00   ; dy -16 dx +0 tile 35 attr $00
    db $f0, $08, $24, $00   ; dy -16 dx +8 tile 36 attr $00
    db $f8, $f8, $25, $00   ; dy -8 dx -8 tile 37 attr $00
    db $f8, $00, $26, $00   ; dy -8 dx +0 tile 38 attr $00
    db $f8, $08, $27, $00   ; dy -8 dx +8 tile 39 attr $00
    db $e0, $c0, $1b, $00   ; dy -32 dx -64 tile 27 attr $00
    db $e0, $c8, $1c, $00   ; dy -32 dx -56 tile 28 attr $00
    db $e0, $d0, $1d, $00   ; dy -32 dx -48 tile 29 attr $00
    db $e0, $d8, $1e, $00   ; dy -32 dx -40 tile 30 attr $00
    db $d8, $c0, $17, $00   ; dy -40 dx -64 tile 23 attr $00
    db $d8, $c8, $18, $00   ; dy -40 dx -56 tile 24 attr $00
    db $d8, $d0, $19, $00   ; dy -40 dx -48 tile 25 attr $00
    db $d8, $d8, $1a, $00   ; dy -40 dx -40 tile 26 attr $00
    db $d0, $c1, $14, $00   ; dy -48 dx -63 tile 20 attr $00
    db $d0, $c9, $15, $00   ; dy -48 dx -55 tile 21 attr $00
    db $d0, $d1, $16, $00   ; dy -48 dx -47 tile 22 attr $00
    db $d8, $40, $08, $00   ; dy -40 dx +64 tile 8 attr $00
    db $d8, $48, $09, $00   ; dy -40 dx +72 tile 9 attr $00
    db $e0, $40, $0a, $00   ; dy -32 dx +64 tile 10 attr $00
    db $e0, $48, $0b, $00   ; dy -32 dx +72 tile 11 attr $00
    db $e0, $b0, $06, $00   ; dy -32 dx -80 tile 6 attr $00
    db $e0, $f8, $05, $20   ; dy -32 dx -8 tile 5 attr $20
    db $d0, $30, $05, $00   ; dy -48 dx +48 tile 5 attr $00
    db $e8, $18, $11, $00   ; dy -24 dx +24 tile 17 attr $00
    db $e0, $18, $10, $00   ; dy -32 dx +24 tile 16 attr $00
    db $d8, $e8, $05, $00   ; dy -40 dx -24 tile 5 attr $00
    db $e0, $28, $05, $40   ; dy -32 dx +40 tile 5 attr $40
    db $80
Anim_2a_F22:   ; $6a3e 22 sprites
    db $d8, $f8, $1f, $00   ; dy -40 dx -8 tile 31 attr $00
    db $d8, $00, $20, $00   ; dy -40 dx +0 tile 32 attr $00
    db $d8, $08, $21, $00   ; dy -40 dx +8 tile 33 attr $00
    db $e0, $f8, $22, $00   ; dy -32 dx -8 tile 34 attr $00
    db $e0, $00, $23, $00   ; dy -32 dx +0 tile 35 attr $00
    db $e0, $08, $24, $00   ; dy -32 dx +8 tile 36 attr $00
    db $e8, $f8, $25, $00   ; dy -24 dx -8 tile 37 attr $00
    db $e8, $00, $26, $00   ; dy -24 dx +0 tile 38 attr $00
    db $e8, $08, $27, $00   ; dy -24 dx +8 tile 39 attr $00
    db $d0, $d8, $1b, $20   ; dy -48 dx -40 tile 27 attr $20
    db $d0, $d0, $1c, $20   ; dy -48 dx -48 tile 28 attr $20
    db $d0, $c8, $1d, $20   ; dy -48 dx -56 tile 29 attr $20
    db $d0, $c0, $1e, $20   ; dy -48 dx -64 tile 30 attr $20
    db $d0, $48, $0a, $20   ; dy -48 dx +72 tile 10 attr $20
    db $d0, $40, $0b, $20   ; dy -48 dx +64 tile 11 attr $20
    db $d0, $b0, $06, $20   ; dy -48 dx -80 tile 6 attr $20
    db $d0, $f8, $05, $20   ; dy -48 dx -8 tile 5 attr $20
    db $d8, $14, $11, $20   ; dy -40 dx +20 tile 17 attr $20
    db $d0, $14, $10, $20   ; dy -48 dx +20 tile 16 attr $20
    db $d0, $28, $05, $20   ; dy -48 dx +40 tile 5 attr $20
    db $f0, $fa, $28, $00   ; dy -16 dx -6 tile 40 attr $00
    db $f0, $02, $29, $00   ; dy -16 dx +2 tile 41 attr $00
    db $80
Anim_2a_F23:   ; $6a97 5 sprites
    db $d0, $08, $25, $20   ; dy -48 dx +8 tile 37 attr $20
    db $d0, $00, $26, $20   ; dy -48 dx +0 tile 38 attr $20
    db $d0, $f8, $27, $20   ; dy -48 dx -8 tile 39 attr $20
    db $d8, $06, $28, $20   ; dy -40 dx +6 tile 40 attr $20
    db $d8, $fe, $29, $20   ; dy -40 dx -2 tile 41 attr $20
Anim_2a_F24:   ; $6aab empty frame = the $80 end above (shared)
    db $80
Anim_2b_DeMagic:   ; $6aac animation $2b — DeMagic
    dw Anim_2b_F00
    dw Anim_2b_F01
    dw Anim_2b_F02
    dw Anim_2b_F03
    dw Anim_2b_F04
    dw Anim_2b_F05
    dw Anim_2b_F06
    dw Anim_2b_F07
    dw Anim_2b_F08
    dw Anim_2b_F09
    dw Anim_2b_F09
    dw Anim_2b_F09
    dw Anim_2b_F09
    dw Anim_2b_F09
    dw Anim_2b_F09
    dw Anim_2b_F09
    dw Anim_2b_F09
    dw Anim_2b_F09
    dw Anim_2b_F09
    dw Anim_2b_F09
    dw Anim_2b_F09
    dw Anim_2b_F09
    dw Anim_2b_F09
    dw Anim_2b_F09
    dw Anim_2b_F09
    dw Anim_2b_F09
    dw Anim_2b_F09
    dw Anim_2b_F09
    dw Anim_2b_F09
    dw Anim_2b_F09
    dw Anim_2b_F09
    dw Anim_2b_F09
Anim_2b_F00:   ; $6aec 28 sprites
    db $f0, $f0, $1f, $00   ; dy -16 dx -16 tile 31 attr $00
    db $f8, $f8, $21, $00   ; dy -8 dx -8 tile 33 attr $00
    db $f5, $eb, $1f, $00   ; dy -11 dx -21 tile 31 attr $00
    db $e8, $ec, $1e, $00   ; dy -24 dx -20 tile 30 attr $00
    db $ec, $f8, $13, $00   ; dy -20 dx -8 tile 19 attr $00
    db $d8, $f0, $1f, $40   ; dy -40 dx -16 tile 31 attr $40
    db $d0, $f8, $21, $40   ; dy -48 dx -8 tile 33 attr $40
    db $d3, $eb, $1f, $40   ; dy -45 dx -21 tile 31 attr $40
    db $e0, $ec, $1e, $40   ; dy -32 dx -20 tile 30 attr $40
    db $e0, $f5, $13, $40   ; dy -32 dx -11 tile 19 attr $40
    db $d8, $f9, $0f, $20   ; dy -40 dx -7 tile 15 attr $20
    db $dc, $f8, $13, $40   ; dy -36 dx -8 tile 19 attr $40
    db $f0, $09, $1f, $20   ; dy -16 dx +9 tile 31 attr $20
    db $f8, $01, $21, $20   ; dy -8 dx +1 tile 33 attr $20
    db $f5, $0e, $1f, $20   ; dy -11 dx +14 tile 31 attr $20
    db $e8, $0d, $1e, $20   ; dy -24 dx +13 tile 30 attr $20
    db $e8, $04, $13, $20   ; dy -24 dx +4 tile 19 attr $20
    db $f0, $00, $0f, $40   ; dy -16 dx +0 tile 15 attr $40
    db $ec, $01, $13, $20   ; dy -20 dx +1 tile 19 attr $20
    db $d8, $09, $1f, $60   ; dy -40 dx +9 tile 31 attr $60
    db $d0, $01, $21, $60   ; dy -48 dx +1 tile 33 attr $60
    db $d3, $0e, $1f, $60   ; dy -45 dx +14 tile 31 attr $60
    db $e0, $0d, $1e, $60   ; dy -32 dx +13 tile 30 attr $60
    db $e0, $04, $13, $60   ; dy -32 dx +4 tile 19 attr $60
    db $dc, $01, $13, $60   ; dy -36 dx +1 tile 19 attr $60
    db $e8, $f5, $13, $00   ; dy -24 dx -11 tile 19 attr $00
    db $f0, $f9, $0f, $60   ; dy -16 dx -7 tile 15 attr $60
    db $d8, $00, $0f, $00   ; dy -40 dx +0 tile 15 attr $00
    db $80
Anim_2b_F01:   ; $6b5d 34 sprites
    db $ee, $e8, $18, $00   ; dy -18 dx -24 tile 24 attr $00
    db $f6, $f8, $1b, $00   ; dy -10 dx -8 tile 27 attr $00
    db $e6, $e4, $14, $00   ; dy -26 dx -28 tile 20 attr $00
    db $f6, $f0, $18, $00   ; dy -10 dx -16 tile 24 attr $00
    db $da, $e8, $18, $40   ; dy -38 dx -24 tile 24 attr $40
    db $d2, $f8, $1b, $40   ; dy -46 dx -8 tile 27 attr $40
    db $e2, $e4, $14, $40   ; dy -30 dx -28 tile 20 attr $40
    db $d2, $f0, $18, $40   ; dy -46 dx -16 tile 24 attr $40
    db $ee, $10, $18, $20   ; dy -18 dx +16 tile 24 attr $20
    db $f6, $00, $1b, $20   ; dy -10 dx +0 tile 27 attr $20
    db $e6, $14, $14, $20   ; dy -26 dx +20 tile 20 attr $20
    db $f6, $08, $18, $20   ; dy -10 dx +8 tile 24 attr $20
    db $da, $10, $18, $60   ; dy -38 dx +16 tile 24 attr $60
    db $d2, $00, $1b, $60   ; dy -46 dx +0 tile 27 attr $60
    db $e2, $14, $14, $60   ; dy -30 dx +20 tile 20 attr $60
    db $d2, $08, $18, $60   ; dy -46 dx +8 tile 24 attr $60
    db $e2, $0c, $13, $00   ; dy -30 dx +12 tile 19 attr $00
    db $da, $08, $13, $00   ; dy -38 dx +8 tile 19 attr $00
    db $da, $f0, $13, $20   ; dy -38 dx -16 tile 19 attr $20
    db $da, $f8, $13, $20   ; dy -38 dx -8 tile 19 attr $20
    db $e6, $ec, $13, $60   ; dy -26 dx -20 tile 19 attr $60
    db $ee, $f0, $13, $60   ; dy -18 dx -16 tile 19 attr $60
    db $ee, $08, $13, $40   ; dy -18 dx +8 tile 19 attr $40
    db $ee, $00, $13, $40   ; dy -18 dx +0 tile 19 attr $40
    db $da, $00, $13, $00   ; dy -38 dx +0 tile 19 attr $00
    db $ee, $f8, $13, $60   ; dy -18 dx -8 tile 19 attr $60
    db $e2, $ec, $13, $20   ; dy -30 dx -20 tile 19 attr $20
    db $ea, $0c, $13, $00   ; dy -22 dx +12 tile 19 attr $00
    db $e4, $f4, $0a, $00   ; dy -28 dx -12 tile 10 attr $00
    db $e4, $04, $0a, $20   ; dy -28 dx +4 tile 10 attr $20
    db $f3, $e3, $09, $00   ; dy -13 dx -29 tile 9 attr $00
    db $f3, $15, $09, $20   ; dy -13 dx +21 tile 9 attr $20
    db $d5, $15, $09, $60   ; dy -43 dx +21 tile 9 attr $60
    db $d5, $e3, $09, $40   ; dy -43 dx -29 tile 9 attr $40
    db $80
Anim_2b_F02:   ; $6be6 46 sprites
    db $f0, $f0, $19, $00   ; dy -16 dx -16 tile 25 attr $00
    db $f8, $f0, $1b, $00   ; dy -8 dx -16 tile 27 attr $00
    db $f0, $e0, $14, $00   ; dy -16 dx -32 tile 20 attr $00
    db $f8, $e0, $17, $00   ; dy -8 dx -32 tile 23 attr $00
    db $d8, $f0, $19, $40   ; dy -40 dx -16 tile 25 attr $40
    db $d0, $f0, $1b, $40   ; dy -48 dx -16 tile 27 attr $40
    db $d8, $e0, $14, $40   ; dy -40 dx -32 tile 20 attr $40
    db $d0, $e0, $17, $40   ; dy -48 dx -32 tile 23 attr $40
    db $f8, $08, $1b, $20   ; dy -8 dx +8 tile 27 attr $20
    db $f0, $18, $14, $20   ; dy -16 dx +24 tile 20 attr $20
    db $f8, $18, $17, $20   ; dy -8 dx +24 tile 23 attr $20
    db $d0, $08, $1b, $60   ; dy -48 dx +8 tile 27 attr $60
    db $d8, $18, $14, $60   ; dy -40 dx +24 tile 20 attr $60
    db $d0, $18, $17, $60   ; dy -48 dx +24 tile 23 attr $60
    db $f0, $08, $86, $20   ; dy -16 dx +8 tile 134 attr $20
    db $d8, $08, $86, $60   ; dy -40 dx +8 tile 134 attr $60
    db $d8, $00, $0d, $60   ; dy -40 dx +0 tile 13 attr $60
    db $d0, $f8, $0e, $40   ; dy -48 dx -8 tile 14 attr $40
    db $d0, $00, $0e, $40   ; dy -48 dx +0 tile 14 attr $40
    db $f0, $f8, $0d, $00   ; dy -16 dx -8 tile 13 attr $00
    db $f0, $00, $0d, $20   ; dy -16 dx +0 tile 13 attr $20
    db $f8, $f8, $0e, $00   ; dy -8 dx -8 tile 14 attr $00
    db $f8, $00, $0e, $00   ; dy -8 dx +0 tile 14 attr $00
    db $d8, $10, $04, $00   ; dy -40 dx +16 tile 4 attr $00
    db $d8, $e8, $04, $20   ; dy -40 dx -24 tile 4 attr $20
    db $f0, $10, $04, $20   ; dy -16 dx +16 tile 4 attr $20
    db $f0, $e8, $04, $00   ; dy -16 dx -24 tile 4 attr $00
    db $f8, $e8, $1f, $00   ; dy -8 dx -24 tile 31 attr $00
    db $f8, $10, $1f, $20   ; dy -8 dx +16 tile 31 attr $20
    db $d0, $10, $1f, $00   ; dy -48 dx +16 tile 31 attr $00
    db $d0, $e8, $1f, $20   ; dy -48 dx -24 tile 31 attr $20
    db $ea, $f6, $08, $00   ; dy -22 dx -10 tile 8 attr $00
    db $de, $f6, $08, $40   ; dy -34 dx -10 tile 8 attr $40
    db $de, $02, $08, $60   ; dy -34 dx +2 tile 8 attr $60
    db $ea, $02, $08, $20   ; dy -22 dx +2 tile 8 attr $20
    db $e0, $e7, $00, $40   ; dy -32 dx -25 tile 0 attr $40
    db $e8, $e2, $01, $00   ; dy -24 dx -30 tile 1 attr $00
    db $e4, $e0, $0b, $00   ; dy -28 dx -32 tile 11 attr $00
    db $e8, $11, $00, $20   ; dy -24 dx +17 tile 0 attr $20
    db $e0, $11, $00, $60   ; dy -32 dx +17 tile 0 attr $60
    db $e8, $16, $01, $20   ; dy -24 dx +22 tile 1 attr $20
    db $e0, $16, $01, $60   ; dy -32 dx +22 tile 1 attr $60
    db $e4, $18, $0b, $20   ; dy -28 dx +24 tile 11 attr $20
    db $d8, $f8, $0d, $40   ; dy -40 dx -8 tile 13 attr $40
    db $e8, $e7, $00, $00   ; dy -24 dx -25 tile 0 attr $00
    db $e0, $e2, $01, $40   ; dy -32 dx -30 tile 1 attr $40
    db $80
Anim_2b_F03:   ; $6c9f 42 sprites
    db $f0, $dc, $14, $00   ; dy -16 dx -36 tile 20 attr $00
    db $f0, $e4, $15, $00   ; dy -16 dx -28 tile 21 attr $00
    db $f8, $dc, $17, $00   ; dy -8 dx -36 tile 23 attr $00
    db $f8, $ec, $1a, $00   ; dy -8 dx -20 tile 26 attr $00
    db $f3, $f1, $19, $00   ; dy -13 dx -15 tile 25 attr $00
    db $f8, $f8, $10, $00   ; dy -8 dx -8 tile 16 attr $00
    db $d8, $dc, $14, $40   ; dy -40 dx -36 tile 20 attr $40
    db $d8, $e4, $15, $40   ; dy -40 dx -28 tile 21 attr $40
    db $d0, $dc, $17, $40   ; dy -48 dx -36 tile 23 attr $40
    db $d0, $ec, $1a, $40   ; dy -48 dx -20 tile 26 attr $40
    db $d5, $f1, $19, $40   ; dy -43 dx -15 tile 25 attr $40
    db $d0, $f8, $10, $40   ; dy -48 dx -8 tile 16 attr $40
    db $f0, $1c, $14, $20   ; dy -16 dx +28 tile 20 attr $20
    db $f0, $14, $15, $20   ; dy -16 dx +20 tile 21 attr $20
    db $f8, $1c, $17, $20   ; dy -8 dx +28 tile 23 attr $20
    db $f8, $0c, $1a, $20   ; dy -8 dx +12 tile 26 attr $20
    db $f3, $07, $19, $20   ; dy -13 dx +7 tile 25 attr $20
    db $f8, $00, $10, $20   ; dy -8 dx +0 tile 16 attr $20
    db $d8, $1c, $14, $60   ; dy -40 dx +28 tile 20 attr $60
    db $d8, $14, $15, $60   ; dy -40 dx +20 tile 21 attr $60
    db $d0, $1c, $17, $60   ; dy -48 dx +28 tile 23 attr $60
    db $d0, $0c, $1a, $60   ; dy -48 dx +12 tile 26 attr $60
    db $d5, $07, $19, $60   ; dy -43 dx +7 tile 25 attr $60
    db $d0, $00, $10, $60   ; dy -48 dx +0 tile 16 attr $60
    db $f8, $e4, $1f, $00   ; dy -8 dx -28 tile 31 attr $00
    db $d0, $e4, $1f, $20   ; dy -48 dx -28 tile 31 attr $20
    db $d0, $14, $1f, $00   ; dy -48 dx +20 tile 31 attr $00
    db $f8, $14, $1f, $20   ; dy -8 dx +20 tile 31 attr $20
    db $ef, $fc, $0d, $00   ; dy -17 dx -4 tile 13 attr $00
    db $d9, $fc, $0d, $40   ; dy -39 dx -4 tile 13 attr $40
    db $e0, $db, $01, $40   ; dy -32 dx -37 tile 1 attr $40
    db $e8, $db, $01, $00   ; dy -24 dx -37 tile 1 attr $00
    db $e8, $e3, $11, $00   ; dy -24 dx -29 tile 17 attr $00
    db $e0, $e3, $11, $40   ; dy -32 dx -29 tile 17 attr $40
    db $e9, $ed, $02, $00   ; dy -23 dx -19 tile 2 attr $00
    db $df, $ed, $02, $40   ; dy -33 dx -19 tile 2 attr $40
    db $e0, $1d, $01, $60   ; dy -32 dx +29 tile 1 attr $60
    db $e8, $1d, $01, $20   ; dy -24 dx +29 tile 1 attr $20
    db $e8, $15, $11, $20   ; dy -24 dx +21 tile 17 attr $20
    db $e0, $15, $11, $60   ; dy -32 dx +21 tile 17 attr $60
    db $e9, $0b, $02, $20   ; dy -23 dx +11 tile 2 attr $20
    db $df, $0b, $02, $60   ; dy -33 dx +11 tile 2 attr $60
    db $80
Anim_2b_F04:   ; $6d48 48 sprites
    db $f8, $f4, $20, $00   ; dy -8 dx -12 tile 32 attr $00
    db $f0, $d8, $15, $00   ; dy -16 dx -40 tile 21 attr $00
    db $f8, $d0, $17, $00   ; dy -8 dx -48 tile 23 attr $00
    db $ee, $eb, $1f, $00   ; dy -18 dx -21 tile 31 attr $00
    db $f8, $e8, $1a, $00   ; dy -8 dx -24 tile 26 attr $00
    db $d0, $f4, $20, $40   ; dy -48 dx -12 tile 32 attr $40
    db $d8, $d8, $15, $40   ; dy -40 dx -40 tile 21 attr $40
    db $d0, $d0, $17, $40   ; dy -48 dx -48 tile 23 attr $40
    db $da, $eb, $1f, $40   ; dy -38 dx -21 tile 31 attr $40
    db $d0, $e8, $1a, $40   ; dy -48 dx -24 tile 26 attr $40
    db $f8, $df, $1f, $00   ; dy -8 dx -33 tile 31 attr $00
    db $d0, $df, $1f, $40   ; dy -48 dx -33 tile 31 attr $40
    db $ea, $f6, $1f, $00   ; dy -22 dx -10 tile 31 attr $00
    db $de, $f6, $1f, $40   ; dy -34 dx -10 tile 31 attr $40
    db $f0, $d0, $02, $00   ; dy -16 dx -48 tile 2 attr $00
    db $d8, $d0, $02, $40   ; dy -40 dx -48 tile 2 attr $40
    db $e8, $d7, $03, $00   ; dy -24 dx -41 tile 3 attr $00
    db $e0, $d7, $03, $40   ; dy -32 dx -41 tile 3 attr $40
    db $e8, $de, $01, $60   ; dy -24 dx -34 tile 1 attr $60
    db $e0, $de, $01, $20   ; dy -32 dx -34 tile 1 attr $20
    db $f0, $e1, $02, $00   ; dy -16 dx -31 tile 2 attr $00
    db $d8, $e1, $02, $20   ; dy -40 dx -31 tile 2 attr $20
    db $f8, $04, $20, $20   ; dy -8 dx +4 tile 32 attr $20
    db $f0, $20, $15, $20   ; dy -16 dx +32 tile 21 attr $20
    db $f8, $28, $17, $20   ; dy -8 dx +40 tile 23 attr $20
    db $ee, $0d, $1f, $20   ; dy -18 dx +13 tile 31 attr $20
    db $f8, $10, $1a, $20   ; dy -8 dx +16 tile 26 attr $20
    db $d0, $04, $20, $60   ; dy -48 dx +4 tile 32 attr $60
    db $d8, $20, $15, $60   ; dy -40 dx +32 tile 21 attr $60
    db $d0, $28, $17, $60   ; dy -48 dx +40 tile 23 attr $60
    db $da, $0d, $1f, $60   ; dy -38 dx +13 tile 31 attr $60
    db $d0, $10, $1a, $60   ; dy -48 dx +16 tile 26 attr $60
    db $f8, $19, $1f, $20   ; dy -8 dx +25 tile 31 attr $20
    db $d0, $19, $1f, $60   ; dy -48 dx +25 tile 31 attr $60
    db $ea, $02, $1f, $20   ; dy -22 dx +2 tile 31 attr $20
    db $de, $02, $1f, $60   ; dy -34 dx +2 tile 31 attr $60
    db $f0, $28, $02, $20   ; dy -16 dx +40 tile 2 attr $20
    db $d8, $28, $02, $60   ; dy -40 dx +40 tile 2 attr $60
    db $e8, $21, $03, $20   ; dy -24 dx +33 tile 3 attr $20
    db $e0, $21, $03, $60   ; dy -32 dx +33 tile 3 attr $60
    db $e8, $1a, $01, $40   ; dy -24 dx +26 tile 1 attr $40
    db $e0, $1a, $01, $00   ; dy -32 dx +26 tile 1 attr $00
    db $f0, $17, $02, $20   ; dy -16 dx +23 tile 2 attr $20
    db $d8, $17, $02, $00   ; dy -40 dx +23 tile 2 attr $00
    db $e0, $28, $07, $00   ; dy -32 dx +40 tile 7 attr $00
    db $e8, $28, $07, $40   ; dy -24 dx +40 tile 7 attr $40
    db $e0, $d0, $07, $20   ; dy -32 dx -48 tile 7 attr $20
    db $e8, $d0, $07, $60   ; dy -24 dx -48 tile 7 attr $60
    db $80
Anim_2b_F05:   ; $6e09 58 sprites
    db $f0, $f8, $1b, $00   ; dy -16 dx -8 tile 27 attr $00
    db $e8, $f0, $14, $00   ; dy -24 dx -16 tile 20 attr $00
    db $f0, $dd, $1c, $00   ; dy -16 dx -35 tile 28 attr $00
    db $f0, $f0, $1d, $00   ; dy -16 dx -16 tile 29 attr $00
    db $f8, $e1, $18, $00   ; dy -8 dx -31 tile 24 attr $00
    db $f8, $c2, $17, $00   ; dy -8 dx -62 tile 23 attr $00
    db $f8, $d3, $17, $00   ; dy -8 dx -45 tile 23 attr $00
    db $d8, $f8, $1b, $40   ; dy -40 dx -8 tile 27 attr $40
    db $e0, $f0, $14, $40   ; dy -32 dx -16 tile 20 attr $40
    db $d8, $dd, $1c, $40   ; dy -40 dx -35 tile 28 attr $40
    db $d8, $f0, $1d, $40   ; dy -40 dx -16 tile 29 attr $40
    db $d0, $e1, $18, $40   ; dy -48 dx -31 tile 24 attr $40
    db $d0, $c2, $17, $40   ; dy -48 dx -62 tile 23 attr $40
    db $d0, $d3, $17, $40   ; dy -48 dx -45 tile 23 attr $40
    db $f8, $ef, $20, $00   ; dy -8 dx -17 tile 32 attr $00
    db $e8, $f8, $12, $00   ; dy -24 dx -8 tile 18 attr $00
    db $e0, $f8, $12, $40   ; dy -32 dx -8 tile 18 attr $40
    db $f8, $fc, $0d, $00   ; dy -8 dx -4 tile 13 attr $00
    db $d0, $ef, $20, $40   ; dy -48 dx -17 tile 32 attr $40
    db $d0, $fc, $0d, $60   ; dy -48 dx -4 tile 13 attr $60
    db $e0, $d7, $00, $20   ; dy -32 dx -41 tile 0 attr $20
    db $e8, $d7, $00, $60   ; dy -24 dx -41 tile 0 attr $60
    db $d8, $c8, $02, $20   ; dy -40 dx -56 tile 2 attr $20
    db $f0, $c8, $02, $60   ; dy -16 dx -56 tile 2 attr $60
    db $e8, $c8, $06, $00   ; dy -24 dx -56 tile 6 attr $00
    db $e0, $c8, $06, $40   ; dy -32 dx -56 tile 6 attr $40
    db $f0, $d0, $00, $60   ; dy -16 dx -48 tile 0 attr $60
    db $d8, $d0, $00, $20   ; dy -40 dx -48 tile 0 attr $20
    db $e8, $cf, $03, $00   ; dy -24 dx -49 tile 3 attr $00
    db $e0, $cf, $03, $40   ; dy -32 dx -49 tile 3 attr $40
    db $f0, $00, $1b, $20   ; dy -16 dx +0 tile 27 attr $20
    db $e8, $08, $14, $20   ; dy -24 dx +8 tile 20 attr $20
    db $f0, $1b, $1c, $20   ; dy -16 dx +27 tile 28 attr $20
    db $f0, $08, $1d, $20   ; dy -16 dx +8 tile 29 attr $20
    db $f8, $17, $18, $20   ; dy -8 dx +23 tile 24 attr $20
    db $f8, $36, $17, $20   ; dy -8 dx +54 tile 23 attr $20
    db $f8, $25, $17, $20   ; dy -8 dx +37 tile 23 attr $20
    db $d8, $00, $1b, $60   ; dy -40 dx +0 tile 27 attr $60
    db $e0, $08, $14, $60   ; dy -32 dx +8 tile 20 attr $60
    db $d8, $1b, $1c, $60   ; dy -40 dx +27 tile 28 attr $60
    db $d8, $08, $1d, $60   ; dy -40 dx +8 tile 29 attr $60
    db $d0, $17, $18, $60   ; dy -48 dx +23 tile 24 attr $60
    db $d0, $36, $17, $60   ; dy -48 dx +54 tile 23 attr $60
    db $d0, $25, $17, $60   ; dy -48 dx +37 tile 23 attr $60
    db $f8, $09, $20, $20   ; dy -8 dx +9 tile 32 attr $20
    db $e8, $00, $12, $20   ; dy -24 dx +0 tile 18 attr $20
    db $e0, $00, $12, $60   ; dy -32 dx +0 tile 18 attr $60
    db $d0, $09, $20, $60   ; dy -48 dx +9 tile 32 attr $60
    db $e0, $21, $00, $00   ; dy -32 dx +33 tile 0 attr $00
    db $e8, $21, $00, $40   ; dy -24 dx +33 tile 0 attr $40
    db $d8, $30, $02, $00   ; dy -40 dx +48 tile 2 attr $00
    db $f0, $30, $02, $40   ; dy -16 dx +48 tile 2 attr $40
    db $e8, $30, $06, $20   ; dy -24 dx +48 tile 6 attr $20
    db $e0, $30, $06, $60   ; dy -32 dx +48 tile 6 attr $60
    db $f0, $28, $00, $40   ; dy -16 dx +40 tile 0 attr $40
    db $d8, $28, $00, $00   ; dy -40 dx +40 tile 0 attr $00
    db $e8, $29, $03, $20   ; dy -24 dx +41 tile 3 attr $20
    db $e0, $29, $03, $60   ; dy -32 dx +41 tile 3 attr $60
    db $80
Anim_2b_F06:   ; $6ef2 56 sprites
    db $f8, $d6, $18, $00   ; dy -8 dx -42 tile 24 attr $00
    db $f0, $f4, $11, $00   ; dy -16 dx -12 tile 17 attr $00
    db $f0, $ec, $18, $00   ; dy -16 dx -20 tile 24 attr $00
    db $e8, $e5, $14, $00   ; dy -24 dx -27 tile 20 attr $00
    db $e8, $ed, $13, $00   ; dy -24 dx -19 tile 19 attr $00
    db $f8, $f7, $1b, $00   ; dy -8 dx -9 tile 27 attr $00
    db $d0, $d6, $18, $40   ; dy -48 dx -42 tile 24 attr $40
    db $d8, $f4, $11, $40   ; dy -40 dx -12 tile 17 attr $40
    db $d8, $ec, $18, $40   ; dy -40 dx -20 tile 24 attr $40
    db $e0, $e5, $14, $40   ; dy -32 dx -27 tile 20 attr $40
    db $e0, $ed, $13, $40   ; dy -32 dx -19 tile 19 attr $40
    db $d0, $f7, $1b, $40   ; dy -48 dx -9 tile 27 attr $40
    db $f8, $c8, $1c, $00   ; dy -8 dx -56 tile 28 attr $00
    db $d0, $c8, $1c, $40   ; dy -48 dx -56 tile 28 attr $40
    db $f8, $b8, $17, $00   ; dy -8 dx -72 tile 23 attr $00
    db $d0, $b8, $17, $40   ; dy -48 dx -72 tile 23 attr $40
    db $f8, $ed, $1f, $00   ; dy -8 dx -19 tile 31 attr $00
    db $d0, $e6, $1f, $20   ; dy -48 dx -26 tile 31 attr $20
    db $f0, $e4, $1c, $00   ; dy -16 dx -28 tile 28 attr $00
    db $d8, $df, $1c, $40   ; dy -40 dx -33 tile 28 attr $40
    db $ea, $bc, $14, $00   ; dy -22 dx -68 tile 20 attr $00
    db $de, $bc, $14, $40   ; dy -34 dx -68 tile 20 attr $40
    db $f0, $cd, $05, $00   ; dy -16 dx -51 tile 5 attr $00
    db $d8, $cb, $05, $40   ; dy -40 dx -53 tile 5 attr $40
    db $f8, $22, $18, $20   ; dy -8 dx +34 tile 24 attr $20
    db $f0, $04, $11, $20   ; dy -16 dx +4 tile 17 attr $20
    db $f0, $0c, $18, $20   ; dy -16 dx +12 tile 24 attr $20
    db $e8, $13, $14, $20   ; dy -24 dx +19 tile 20 attr $20
    db $e8, $0b, $13, $20   ; dy -24 dx +11 tile 19 attr $20
    db $f8, $01, $1b, $20   ; dy -8 dx +1 tile 27 attr $20
    db $d0, $22, $18, $60   ; dy -48 dx +34 tile 24 attr $60
    db $d8, $04, $11, $60   ; dy -40 dx +4 tile 17 attr $60
    db $d8, $0c, $18, $60   ; dy -40 dx +12 tile 24 attr $60
    db $e0, $13, $14, $60   ; dy -32 dx +19 tile 20 attr $60
    db $e0, $0b, $13, $60   ; dy -32 dx +11 tile 19 attr $60
    db $d0, $01, $1b, $60   ; dy -48 dx +1 tile 27 attr $60
    db $f8, $30, $1c, $20   ; dy -8 dx +48 tile 28 attr $20
    db $d0, $30, $1c, $60   ; dy -48 dx +48 tile 28 attr $60
    db $f8, $40, $17, $20   ; dy -8 dx +64 tile 23 attr $20
    db $d0, $40, $17, $60   ; dy -48 dx +64 tile 23 attr $60
    db $f8, $0b, $1f, $20   ; dy -8 dx +11 tile 31 attr $20
    db $d0, $12, $1f, $00   ; dy -48 dx +18 tile 31 attr $00
    db $f0, $14, $1c, $20   ; dy -16 dx +20 tile 28 attr $20
    db $d8, $19, $1c, $60   ; dy -40 dx +25 tile 28 attr $60
    db $ea, $3c, $14, $20   ; dy -22 dx +60 tile 20 attr $20
    db $de, $3c, $14, $60   ; dy -34 dx +60 tile 20 attr $60
    db $f0, $2b, $05, $20   ; dy -16 dx +43 tile 5 attr $20
    db $d8, $2d, $05, $60   ; dy -40 dx +45 tile 5 attr $60
    db $e0, $35, $00, $60   ; dy -32 dx +53 tile 0 attr $60
    db $e8, $35, $00, $20   ; dy -24 dx +53 tile 0 attr $20
    db $e0, $c3, $00, $40   ; dy -32 dx -61 tile 0 attr $40
    db $e8, $c3, $00, $00   ; dy -24 dx -61 tile 0 attr $00
    db $e8, $cb, $04, $00   ; dy -24 dx -53 tile 4 attr $00
    db $e0, $cb, $04, $40   ; dy -32 dx -53 tile 4 attr $40
    db $e0, $2d, $04, $60   ; dy -32 dx +45 tile 4 attr $60
    db $e8, $2d, $04, $20   ; dy -24 dx +45 tile 4 attr $20
    db $80
Anim_2b_F07:   ; $6fd3 42 sprites
    db $f0, $cb, $15, $00   ; dy -16 dx -53 tile 21 attr $00
    db $f8, $ec, $1a, $00   ; dy -8 dx -20 tile 26 attr $00
    db $f3, $f1, $19, $00   ; dy -13 dx -15 tile 25 attr $00
    db $f0, $e6, $04, $00   ; dy -16 dx -26 tile 4 attr $00
    db $e8, $e3, $15, $00   ; dy -24 dx -29 tile 21 attr $00
    db $f0, $b8, $14, $00   ; dy -16 dx -72 tile 20 attr $00
    db $f8, $c5, $09, $00   ; dy -8 dx -59 tile 9 attr $00
    db $f8, $f8, $0d, $00   ; dy -8 dx -8 tile 13 attr $00
    db $ed, $c1, $16, $60   ; dy -19 dx -63 tile 22 attr $60
    db $e4, $da, $0c, $60   ; dy -28 dx -38 tile 12 attr $60
    db $f0, $2e, $15, $20   ; dy -16 dx +46 tile 21 attr $20
    db $f8, $0d, $1a, $20   ; dy -8 dx +13 tile 26 attr $20
    db $f3, $08, $19, $20   ; dy -13 dx +8 tile 25 attr $20
    db $f0, $13, $04, $20   ; dy -16 dx +19 tile 4 attr $20
    db $e8, $16, $15, $20   ; dy -24 dx +22 tile 21 attr $20
    db $f0, $41, $14, $20   ; dy -16 dx +65 tile 20 attr $20
    db $f8, $34, $09, $20   ; dy -8 dx +52 tile 9 attr $20
    db $f8, $01, $0d, $20   ; dy -8 dx +1 tile 13 attr $20
    db $ed, $38, $16, $40   ; dy -19 dx +56 tile 22 attr $40
    db $e4, $1f, $0c, $40   ; dy -28 dx +31 tile 12 attr $40
    db $d8, $cb, $15, $40   ; dy -40 dx -53 tile 21 attr $40
    db $d0, $ec, $1a, $40   ; dy -48 dx -20 tile 26 attr $40
    db $d5, $f1, $19, $40   ; dy -43 dx -15 tile 25 attr $40
    db $d8, $e6, $04, $40   ; dy -40 dx -26 tile 4 attr $40
    db $e0, $e3, $15, $40   ; dy -32 dx -29 tile 21 attr $40
    db $d8, $b8, $14, $40   ; dy -40 dx -72 tile 20 attr $40
    db $d0, $c5, $09, $40   ; dy -48 dx -59 tile 9 attr $40
    db $d0, $f8, $0d, $40   ; dy -48 dx -8 tile 13 attr $40
    db $db, $c1, $16, $20   ; dy -37 dx -63 tile 22 attr $20
    db $d8, $2e, $15, $60   ; dy -40 dx +46 tile 21 attr $60
    db $d0, $0d, $1a, $60   ; dy -48 dx +13 tile 26 attr $60
    db $d5, $08, $19, $60   ; dy -43 dx +8 tile 25 attr $60
    db $d8, $13, $04, $60   ; dy -40 dx +19 tile 4 attr $60
    db $e0, $16, $15, $60   ; dy -32 dx +22 tile 21 attr $60
    db $d8, $41, $14, $60   ; dy -40 dx +65 tile 20 attr $60
    db $d0, $34, $09, $60   ; dy -48 dx +52 tile 9 attr $60
    db $d0, $01, $0d, $60   ; dy -48 dx +1 tile 13 attr $60
    db $db, $38, $16, $00   ; dy -37 dx +56 tile 22 attr $00
    db $f8, $e4, $06, $00   ; dy -8 dx -28 tile 6 attr $00
    db $d0, $e4, $06, $40   ; dy -48 dx -28 tile 6 attr $40
    db $d0, $15, $06, $00   ; dy -48 dx +21 tile 6 attr $00
    db $f8, $15, $06, $40   ; dy -8 dx +21 tile 6 attr $40
    db $80
Anim_2b_F08:   ; $707c 48 sprites
    db $f8, $f4, $20, $00   ; dy -8 dx -12 tile 32 attr $00
    db $f0, $d0, $14, $00   ; dy -16 dx -48 tile 20 attr $00
    db $f8, $e8, $1a, $00   ; dy -8 dx -24 tile 26 attr $00
    db $d0, $f4, $20, $40   ; dy -48 dx -12 tile 32 attr $40
    db $d8, $d0, $14, $40   ; dy -40 dx -48 tile 20 attr $40
    db $d0, $e8, $1a, $40   ; dy -48 dx -24 tile 26 attr $40
    db $f0, $e5, $1f, $00   ; dy -16 dx -27 tile 31 attr $00
    db $d8, $e5, $1f, $40   ; dy -40 dx -27 tile 31 attr $40
    db $f0, $d8, $13, $00   ; dy -16 dx -40 tile 19 attr $00
    db $d8, $d8, $13, $40   ; dy -40 dx -40 tile 19 attr $40
    db $e8, $d4, $13, $00   ; dy -24 dx -44 tile 19 attr $00
    db $e0, $d4, $13, $40   ; dy -32 dx -44 tile 19 attr $40
    db $ea, $cc, $16, $60   ; dy -22 dx -52 tile 22 attr $60
    db $de, $cc, $16, $20   ; dy -34 dx -52 tile 22 attr $20
    db $d0, $df, $11, $20   ; dy -48 dx -33 tile 17 attr $20
    db $f8, $df, $11, $00   ; dy -8 dx -33 tile 17 attr $00
    db $e0, $dd, $06, $40   ; dy -32 dx -35 tile 6 attr $40
    db $e8, $dd, $06, $00   ; dy -24 dx -35 tile 6 attr $00
    db $f8, $b0, $09, $00   ; dy -8 dx -80 tile 9 attr $00
    db $f0, $b8, $06, $00   ; dy -16 dx -72 tile 6 attr $00
    db $f8, $c4, $06, $00   ; dy -8 dx -60 tile 6 attr $00
    db $f8, $04, $20, $20   ; dy -8 dx +4 tile 32 attr $20
    db $f0, $28, $14, $20   ; dy -16 dx +40 tile 20 attr $20
    db $f8, $10, $1a, $20   ; dy -8 dx +16 tile 26 attr $20
    db $d0, $04, $20, $60   ; dy -48 dx +4 tile 32 attr $60
    db $d8, $28, $14, $60   ; dy -40 dx +40 tile 20 attr $60
    db $d0, $10, $1a, $60   ; dy -48 dx +16 tile 26 attr $60
    db $f0, $13, $1f, $20   ; dy -16 dx +19 tile 31 attr $20
    db $d8, $13, $1f, $60   ; dy -40 dx +19 tile 31 attr $60
    db $f0, $20, $13, $20   ; dy -16 dx +32 tile 19 attr $20
    db $d8, $20, $13, $60   ; dy -40 dx +32 tile 19 attr $60
    db $e8, $24, $13, $20   ; dy -24 dx +36 tile 19 attr $20
    db $e0, $24, $13, $60   ; dy -32 dx +36 tile 19 attr $60
    db $ea, $2c, $16, $40   ; dy -22 dx +44 tile 22 attr $40
    db $de, $2c, $16, $00   ; dy -34 dx +44 tile 22 attr $00
    db $d0, $19, $11, $00   ; dy -48 dx +25 tile 17 attr $00
    db $f8, $19, $11, $20   ; dy -8 dx +25 tile 17 attr $20
    db $e0, $1b, $06, $60   ; dy -32 dx +27 tile 6 attr $60
    db $e8, $1b, $06, $20   ; dy -24 dx +27 tile 6 attr $20
    db $f8, $48, $09, $20   ; dy -8 dx +72 tile 9 attr $20
    db $f0, $40, $06, $20   ; dy -16 dx +64 tile 6 attr $20
    db $f8, $34, $06, $20   ; dy -8 dx +52 tile 6 attr $20
    db $d0, $48, $09, $60   ; dy -48 dx +72 tile 9 attr $60
    db $d8, $40, $06, $60   ; dy -40 dx +64 tile 6 attr $60
    db $d0, $34, $06, $60   ; dy -48 dx +52 tile 6 attr $60
    db $d0, $b0, $09, $40   ; dy -48 dx -80 tile 9 attr $40
    db $d8, $b8, $06, $40   ; dy -40 dx -72 tile 6 attr $40
    db $d0, $c4, $06, $40   ; dy -48 dx -60 tile 6 attr $40
Anim_2b_F09:   ; $713c empty frame = the $80 end above (shared)
    db $80
Anim_2c_FEEDMEAT:   ; $713d animation $2c — FEEDMEAT, BEFFJERKY, PORKCHOP, SIRLOIN
    dw Anim_2c_F00
    dw Anim_2c_F01
    dw Anim_2c_F02
    dw Anim_2c_F03
    dw Anim_2c_F04
    dw Anim_2c_F05
    dw Anim_2c_F06
    dw Anim_2c_F07
    dw Anim_2c_F08
    dw Anim_2c_F09
    dw Anim_2c_F10
    dw Anim_2c_F10
    dw Anim_2c_F10
    dw Anim_2c_F10
    dw Anim_2c_F10
    dw Anim_2c_F10
    dw Anim_2c_F10
    dw Anim_2c_F10
    dw Anim_2c_F10
    dw Anim_2c_F10
    dw Anim_2c_F10
    dw Anim_2c_F10
    dw Anim_2c_F10
    dw Anim_2c_F10
    dw Anim_2c_F10
    dw Anim_2c_F10
    dw Anim_2c_F10
    dw Anim_2c_F10
    dw Anim_2c_F10
    dw Anim_2c_F10
    dw Anim_2c_F10
    dw Anim_2c_F10
Anim_2c_F00:   ; $717d 4 sprites
    db $df, $01, $00, $00   ; dy -33 dx +1 tile 0 attr $00
    db $df, $09, $01, $00   ; dy -33 dx +9 tile 1 attr $00
    db $e7, $01, $02, $00   ; dy -25 dx +1 tile 2 attr $00
    db $e7, $09, $03, $00   ; dy -25 dx +9 tile 3 attr $00
    db $80
Anim_2c_F01:   ; $718e 4 sprites
    db $dc, $05, $00, $00   ; dy -36 dx +5 tile 0 attr $00
    db $dc, $0d, $01, $00   ; dy -36 dx +13 tile 1 attr $00
    db $e4, $05, $02, $00   ; dy -28 dx +5 tile 2 attr $00
    db $e4, $0d, $03, $00   ; dy -28 dx +13 tile 3 attr $00
    db $80
Anim_2c_F02:   ; $719f 4 sprites
    db $da, $fe, $00, $00   ; dy -38 dx -2 tile 0 attr $00
    db $da, $06, $01, $00   ; dy -38 dx +6 tile 1 attr $00
    db $e2, $fe, $02, $00   ; dy -30 dx -2 tile 2 attr $00
    db $e2, $06, $03, $00   ; dy -30 dx +6 tile 3 attr $00
    db $80
Anim_2c_F03:   ; $71b0 4 sprites
    db $d6, $02, $00, $00   ; dy -42 dx +2 tile 0 attr $00
    db $d6, $0a, $01, $00   ; dy -42 dx +10 tile 1 attr $00
    db $de, $02, $02, $00   ; dy -34 dx +2 tile 2 attr $00
    db $de, $0a, $03, $00   ; dy -34 dx +10 tile 3 attr $00
    db $80
Anim_2c_F04:   ; $71c1 4 sprites
    db $d5, $07, $00, $00   ; dy -43 dx +7 tile 0 attr $00
    db $d5, $0f, $01, $00   ; dy -43 dx +15 tile 1 attr $00
    db $dd, $07, $02, $00   ; dy -35 dx +7 tile 2 attr $00
    db $dd, $0f, $03, $00   ; dy -35 dx +15 tile 3 attr $00
    db $80
Anim_2c_F05:   ; $71d2 4 sprites
    db $d4, $0b, $00, $00   ; dy -44 dx +11 tile 0 attr $00
    db $d4, $13, $01, $00   ; dy -44 dx +19 tile 1 attr $00
    db $dc, $0b, $02, $00   ; dy -36 dx +11 tile 2 attr $00
    db $dc, $13, $03, $00   ; dy -36 dx +19 tile 3 attr $00
    db $80
Anim_2c_F06:   ; $71e3 4 sprites
    db $d2, $0a, $00, $00   ; dy -46 dx +10 tile 0 attr $00
    db $d2, $12, $01, $00   ; dy -46 dx +18 tile 1 attr $00
    db $da, $0a, $02, $00   ; dy -38 dx +10 tile 2 attr $00
    db $da, $12, $03, $00   ; dy -38 dx +18 tile 3 attr $00
    db $80
Anim_2c_F07:   ; $71f4 4 sprites
    db $d1, $08, $00, $00   ; dy -47 dx +8 tile 0 attr $00
    db $d1, $10, $01, $00   ; dy -47 dx +16 tile 1 attr $00
    db $d9, $08, $02, $00   ; dy -39 dx +8 tile 2 attr $00
    db $d9, $10, $03, $00   ; dy -39 dx +16 tile 3 attr $00
    db $80
Anim_2c_F08:   ; $7205 4 sprites
    db $d0, $0a, $00, $00   ; dy -48 dx +10 tile 0 attr $00
    db $d0, $12, $01, $00   ; dy -48 dx +18 tile 1 attr $00
    db $d8, $0a, $02, $00   ; dy -40 dx +10 tile 2 attr $00
    db $d8, $12, $03, $00   ; dy -40 dx +18 tile 3 attr $00
    db $80
Anim_2c_F09:   ; $7216 4 sprites
    db $d0, $0c, $00, $00   ; dy -48 dx +12 tile 0 attr $00
    db $d0, $14, $01, $00   ; dy -48 dx +20 tile 1 attr $00
    db $d8, $0c, $02, $00   ; dy -40 dx +12 tile 2 attr $00
    db $d8, $14, $03, $00   ; dy -40 dx +20 tile 3 attr $00
Anim_2c_F10:   ; $7226 empty frame = the $80 end above (shared)
    db $80
; NOTE: unreferenced fake-decode labels removed with this block: jr_05e_41cf, jr_05e_4221, jr_05e_4244, jr_05e_424a, jr_05e_427e, jr_05e_42b5, jr_05e_42cd, jr_05e_42d5, jr_05e_42da, jr_05e_42e1, jr_05e_42e2, jr_05e_42ea, jr_05e_42f2, jr_05e_42fe, jr_05e_4302, jr_05e_430a, jr_05e_430e, jr_05e_4312, jr_05e_4322, jr_05e_432a, jr_05e_432e, jr_05e_4332, jr_05e_433e, jr_05e_4342, jr_05e_434a, jr_05e_4352, jr_05e_43c2, jr_05e_4416, jr_05e_4434, jr_05e_4438, jr_05e_4499, jr_05e_4595, jr_05e_45b5, jr_05e_45b9, jr_05e_466b, jr_05e_46b0, jr_05e_4711, jr_05e_472a, jr_05e_473a, jr_05e_476b, jr_05e_4783, jr_05e_4822, jr_05e_485f, jr_05e_488c, jr_05e_4890, jr_05e_48b5, jr_05e_48c1, jr_05e_48c5, jr_05e_48c9, jr_05e_48ea, jr_05e_48f6, jr_05e_490a, jr_05e_490e, jr_05e_491a, jr_05e_49b4, jr_05e_4a40, jr_05e_4a87, jr_05e_4abc, jr_05e_4ad4, jr_05e_4b44, jr_05e_4bc6, jr_05e_4bd6, jr_05e_4bde, jr_05e_4be6, jr_05e_4bee, jr_05e_4c57, jr_05e_4c5f, jr_05e_4c6f, jr_05e_4c77, jr_05e_4c7f, jr_05e_4cbc, jr_05e_4d0b, jr_05e_4d44, jr_05e_4d54, jr_05e_4d80, jr_05e_4db9, jr_05e_4dd9, jr_05e_4de1, jr_05e_4df6, jr_05e_4dfa, jr_05e_4dfe, jr_05e_4e3e, jr_05e_4e42, jr_05e_4e4a, jr_05e_4e6f, jr_05e_4e73, jr_05e_4e77, jr_05e_4e88, jr_05e_4e8c, jr_05e_4e90, jr_05e_4e94, jr_05e_4ea4, jr_05e_4ea8, jr_05e_4eb1, jr_05e_4eb5, jr_05e_4ecd, jr_05e_4ed6, jr_05e_4eda, jr_05e_4ede, jr_05e_4ee5, jr_05e_4eee, jr_05e_4ef2, jr_05e_4f14, jr_05e_4f1c, jr_05e_4f1f, jr_05e_4f20, jr_05e_4f30, jr_05e_4f37, jr_05e_4f3c, jr_05e_4f4c, jr_05e_4f79, jr_05e_4fa5, jr_05e_4fb1, jr_05e_4fc1, jr_05e_4fe3, jr_05e_4fee, jr_05e_50c1, jr_05e_510e, jr_05e_5112, jr_05e_5122, jr_05e_512e, jr_05e_51c4, jr_05e_51d2, jr_05e_5207, jr_05e_520b, jr_05e_520f, jr_05e_5213, jr_05e_524b, jr_05e_5250, jr_05e_5266, jr_05e_5268, jr_05e_526b, jr_05e_52f5, jr_05e_530f, jr_05e_5313, jr_05e_531f, jr_05e_5347, jr_05e_535a, jr_05e_5376, jr_05e_5399, jr_05e_539a, jr_05e_53a1, jr_05e_53a5, jr_05e_53b1, jr_05e_540b, jr_05e_5413, jr_05e_542e, jr_05e_543e, jr_05e_544b, jr_05e_5456, jr_05e_545b, jr_05e_5466, jr_05e_5473, jr_05e_5477, jr_05e_547b, jr_05e_547f, jr_05e_5497, jr_05e_54a3, jr_05e_54a7, jr_05e_54ab, jr_05e_54b7, jr_05e_54bb, jr_05e_54cf, jr_05e_54f9, jr_05e_54fb, jr_05e_54fc, jr_05e_54ff, jr_05e_5503, jr_05e_550b, jr_05e_550f, jr_05e_5513, jr_05e_5517, jr_05e_5528, jr_05e_552c, jr_05e_5530, jr_05e_5538, jr_05e_5539, jr_05e_5546, jr_05e_5549, jr_05e_5560, jr_05e_556b, jr_05e_556f, jr_05e_5571, jr_05e_5573, jr_05e_5577, jr_05e_557b, jr_05e_5581, jr_05e_5583, jr_05e_55b4, jr_05e_55cc, jr_05e_55d0, jr_05e_55d4, jr_05e_55d8, jr_05e_55dc, jr_05e_55e0, jr_05e_55e4, jr_05e_55e8, jr_05e_55f2, jr_05e_55f8, jr_05e_5605, jr_05e_562e, jr_05e_5636, jr_05e_5659, jr_05e_5661, jr_05e_5669, jr_05e_566d, jr_05e_5671, jr_05e_5681, jr_05e_5685, jr_05e_5689, jr_05e_56a1, jr_05e_56b5, jr_05e_56b6, jr_05e_56b7, jr_05e_56bd, jr_05e_56c8, jr_05e_56d0, jr_05e_56d1, jr_05e_56d5, jr_05e_56de, jr_05e_56e1, jr_05e_56e5, jr_05e_56e9, jr_05e_56f9, jr_05e_56fc, jr_05e_570b, jr_05e_5716, jr_05e_571a, jr_05e_5723, jr_05e_5753, jr_05e_5755, jr_05e_5758, jr_05e_575a, jr_05e_5770, jr_05e_5788, jr_05e_578c, jr_05e_5790, jr_05e_57bc, jr_05e_57c7, jr_05e_57ca, jr_05e_57cb, jr_05e_57cd, jr_05e_57df, jr_05e_57fe, jr_05e_580e, jr_05e_5815, jr_05e_5819, jr_05e_5825, jr_05e_582d, jr_05e_5831, jr_05e_5879, jr_05e_5889, jr_05e_58b1, jr_05e_58b5, jr_05e_58c9, jr_05e_58fb, jr_05e_5947, jr_05e_594b, jr_05e_594f, jr_05e_5953, jr_05e_5965, jr_05e_596a, jr_05e_596f, jr_05e_597f, jr_05e_5983, jr_05e_598f, jr_05e_5993, jr_05e_59a0, jr_05e_59ac, jr_05e_59b0, jr_05e_59b6, jr_05e_59c6, jr_05e_59d6, jr_05e_59da, jr_05e_59df, jr_05e_5a6b, jr_05e_5a70, jr_05e_5a75, jr_05e_5a7c, jr_05e_5a7e, jr_05e_5a81, jr_05e_5a8e, jr_05e_5a92, jr_05e_5a96, jr_05e_5aa9, jr_05e_5ac2, jr_05e_5ac6, jr_05e_5ad2, jr_05e_5ad6, jr_05e_5ad7, jr_05e_5ae1, jr_05e_5ae7, jr_05e_5af7, jr_05e_5b1c, jr_05e_5b80, jr_05e_5b84, jr_05e_5b97, jr_05e_5bd3, jr_05e_5bdc, jr_05e_5bec, jr_05e_5c25, jr_05e_5c31, jr_05e_5c35, jr_05e_5c3d, jr_05e_5c45, jr_05e_5c49, jr_05e_5c99, jr_05e_5ca9, jr_05e_5cd1, jr_05e_5cee, jr_05e_5cf6, jr_05e_5cfa, jr_05e_5d05, jr_05e_5d06, jr_05e_5d13, jr_05e_5d17, jr_05e_5d27, jr_05e_5d37, jr_05e_5d8a, jr_05e_5d9c, jr_05e_5da0, jr_05e_5db0, jr_05e_5dc0, jr_05e_5dda, jr_05e_5e13, jr_05e_5e63, jr_05e_5ecb, jr_05e_5ed7, jr_05e_5f3d, jr_05e_5f45, jr_05e_5f4d, jr_05e_5f51, jr_05e_5f59, jr_05e_5f61, jr_05e_5f65, jr_05e_5f69, jr_05e_5fe3, jr_05e_5ffb, jr_05e_6078, jr_05e_60a5, jr_05e_60c1, jr_05e_60d9, jr_05e_60e1, jr_05e_60e5, jr_05e_60e9, jr_05e_60ed, jr_05e_60f1, jr_05e_60f5, jr_05e_60f9, jr_05e_60fd, jr_05e_6101, jr_05e_6105, jr_05e_6136, jr_05e_614e, jr_05e_6152, jr_05e_6156, jr_05e_617e, jr_05e_6182, jr_05e_6186, jr_05e_619b, jr_05e_619f, jr_05e_61c7, jr_05e_61e3, jr_05e_620f, jr_05e_622c, jr_05e_6230, jr_05e_6234, jr_05e_6238, jr_05e_623c, jr_05e_6258, jr_05e_6261, jr_05e_6274, jr_05e_628e, jr_05e_6292, jr_05e_62a0, jr_05e_62ed, jr_05e_6319, jr_05e_6373, jr_05e_638b, jr_05e_63b6, jr_05e_63d3, jr_05e_6407, jr_05e_6457, jr_05e_6469, jr_05e_646d, jr_05e_6474, jr_05e_6475, jr_05e_6495, jr_05e_64ad, jr_05e_64b1, jr_05e_64bd, jr_05e_64c1, jr_05e_64d1, jr_05e_64db, jr_05e_64e4, jr_05e_64e6, jr_05e_64ea, jr_05e_64f2, jr_05e_64f6, jr_05e_652f, jr_05e_6532, jr_05e_6548, jr_05e_654d, jr_05e_6552, jr_05e_6557, jr_05e_656d, jr_05e_657d, jr_05e_65c4, jr_05e_6607, jr_05e_661b, jr_05e_6623, jr_05e_663a, jr_05e_6646, jr_05e_669c, jr_05e_66b9, jr_05e_66c7, jr_05e_66d5, jr_05e_66e3, jr_05e_6703, jr_05e_6752, jr_05e_6754, jr_05e_675e, jr_05e_6762, jr_05e_6782, jr_05e_678a, jr_05e_678e, jr_05e_6792, jr_05e_679d, jr_05e_67a0, jr_05e_67a2, jr_05e_67a6, jr_05e_67aa, jr_05e_67ca, jr_05e_67e3, jr_05e_67f3, jr_05e_67f7, jr_05e_67f9, jr_05e_67fb, jr_05e_6803, jr_05e_680f, jr_05e_6813, jr_05e_6818, jr_05e_6837, jr_05e_683b, jr_05e_683f, jr_05e_685f, jr_05e_686b, jr_05e_686f, jr_05e_6871, jr_05e_6873, jr_05e_6890, jr_05e_689a, jr_05e_689f, jr_05e_68a4, jr_05e_68bd, jr_05e_68c2, jr_05e_68c7, jr_05e_68e7, jr_05e_68f4, jr_05e_68fc, jr_05e_691f, jr_05e_6945, jr_05e_694a, jr_05e_6950, jr_05e_6954, jr_05e_695e, jr_05e_6994, jr_05e_69c9, jr_05e_69fa, jr_05e_69fd, jr_05e_6a08, jr_05e_6a2c, jr_05e_6a3b, jr_05e_6a3f, jr_05e_6a44, jr_05e_6a46, jr_05e_6a47, jr_05e_6a7c, jr_05e_6a7f, jr_05e_6a92, jr_05e_6af5, jr_05e_6b19, jr_05e_6b21, jr_05e_6b61, jr_05e_6b6d, jr_05e_6b84, jr_05e_6b94, jr_05e_6ba1, jr_05e_6bb3, jr_05e_6bb4, jr_05e_6be3, jr_05e_6bfb, jr_05e_6c21, jr_05e_6c28, jr_05e_6c2b, jr_05e_6c2d, jr_05e_6c34, jr_05e_6c3b, jr_05e_6c4d, jr_05e_6c63, jr_05e_6c6b, jr_05e_6c9c, jr_05e_6cc0, jr_05e_6cc4, jr_05e_6cd4, jr_05e_6cd8, jr_05e_6cdc, jr_05e_6cff, jr_05e_6d4c, jr_05e_6d85, jr_05e_6d99, jr_05e_6d9b, jr_05e_6d9d, jr_05e_6da1, jr_05e_6da9, jr_05e_6db3, jr_05e_6db5, jr_05e_6dc4, jr_05e_6dc5, jr_05e_6dcd, jr_05e_6dd0, jr_05e_6dd6, jr_05e_6ded, jr_05e_6e18, jr_05e_6e1d, jr_05e_6e45, jr_05e_6e56, jr_05e_6e62, jr_05e_6e76, jr_05e_6e95, jr_05e_6eb5, jr_05e_6edd, jr_05e_6ee8, jr_05e_6ef6, jr_05e_6efe, jr_05e_6f29, jr_05e_6f56, jr_05e_6f67, jr_05e_6f76, jr_05e_6f7e, jr_05e_6f85, jr_05e_6f87, jr_05e_6fa5, jr_05e_6fce, jr_05e_6fd6, jr_05e_6ff4, jr_05e_6ff7, jr_05e_6ff8, jr_05e_7000, jr_05e_700c, jr_05e_7010, jr_05e_7080, jr_05e_70cc, jr_05e_70dd, jr_05e_70f7, jr_05e_710a, jr_05e_710d, jr_05e_7140
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

DataB5e_7d66:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
