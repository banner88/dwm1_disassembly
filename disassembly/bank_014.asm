; =============================================================================
; BANK $14 — ENEMY STATS, BOSS TABLE, PARTY MONSTER MANAGEMENT
; =============================================================================
; Contains:
;   - Enemy stats loader (entries 0,1 → EnemyStatsLoad at $4849)
;   - Party monster init/clear (entry 3 → $401D)
;   - Boss EID redirect table (entry 6 → BossRedirectLookup at $4869)
;
; KEY DATA TABLES:
;   $4893: Boss redirect table (first entry is non-boss redirect EID 4→486)
;   $4897: Boss table proper — 32 gates × 4 bytes each
;          Format: [fight_eid_lo, fight_eid_hi, join_eid_lo, join_eid_hi]
;          fight_eid = enemy stats entry used for boss fight
;          join_eid  = enemy stats entry for the monster that joins after defeat
;   $4C1D: Enemy stats table — 487 entries × 25 bytes each
;          Format per entry:
;            +0:  species_id (1 byte)
;            +1:  EXP reward low byte
;            +2:  EXP reward high byte (16-bit LE)
;            +3:  Joinability (0=always joins, 5=standard, 7=never → $DB85)
;            +4:  level (1 byte)
;            +5:  HP (2 bytes LE)
;            +7:  MP (2 bytes LE)
;            +9:  ATK (2 bytes LE)
;            +11: DEF (2 bytes LE)
;            +13: AGL (2 bytes LE)
;            +15: INT (2 bytes LE)
;            +17: AI weights (4 bytes)
;            +21: skills (4 bytes, $FF = none)
;
; RAM VARIABLES:
;   $DA12-$DA13: Enemy stats ID (16-bit LE) — input for loader
;   $DA18+:      25-byte copy of loaded enemy stats entry
;   $DA14:       Party monster index for init
;
; Sources: editor.py constants, dump_boss_table.py, dump_enemy_stats.py
; =============================================================================

; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $014", ROMX[$4000], BANK[$14]

    db $14 ;ROM Bank

    ; Bank $14 jump table (7 entries, called via rst $10 with H=$14)
    dw label14_400f          ; Entry 0: Load enemy stats → $DA18
    dw label14_4016          ; Entry 1: Load enemy stats → $DA18 (same as entry 0)
    dw label14_40b4          ; Entry 2: Unknown
    dw label14_401d          ; Entry 3: Party monster slot init/clear
    dw label14_7bac          ; Entry 4: Unknown
    dw label14_7d12          ; Entry 5: Unknown
    dw label14_4869          ; Entry 6: Boss EID redirect lookup

label14_400f:
    ld de, $da18
    call Call_014_4849
    ret

label14_4016:
    ld de, $da18
    call Call_014_4849
    ret

label14_401d:
    ld hl, $cac1
    ld a, [$da14]
    call Call_000_223b
    ld bc, $0095
    xor a
    call FillNBytesWithRegA
    ld hl, $cad6
    ld a, [$da14]
    call Call_000_223b
    ld a, $ff
    ld [hl+], a
    ld [hl+], a
    ld hl, $caea
    ld a, [$da14]
    call Call_000_223b
    ld bc, $0008
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $caf2
    ld a, [$da14]
    call Call_000_223b
    ld bc, $0019
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $cb44
    ld de, $477a
    ld b, $08
    call $4782
    ld hl, $cad8
    ld de, $477a
    ld b, $08
    call $4782
    ld hl, $cb4d
    ld de, $477a
    ld b, $08
    call $4782
    ld hl, $cae1
    ld de, $477a
    ld b, $08
    call $4782
    ld hl, $cac1
    ld a, [$da14]
    call Call_000_223b
    ld [hl], $01
    ld hl, $cacd
    ld de, $ca42
    ld b, $08
    call $4782
    ld hl, $cad5
    ld a, [$da14]
    call Call_000_223b
    ld a, [$ca4a]
    ld [hl], a
    ld de, $da18
    call Call_014_4849
    jp Jump_014_4158

label14_40b4:
    ld hl, $cac1
    ld a, [$da14]
    call Call_000_223b
    ld bc, $0095
    xor a
    call FillNBytesWithRegA
    ld hl, $cad6
    ld a, [$da14]
    call Call_000_223b
    ld a, $ff
    ld [hl+], a
    ld [hl+], a
    ld hl, $caea
    ld a, [$da14]
    call Call_000_223b
    ld bc, $0008
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $caf2
    ld a, [$da14]
    call Call_000_223b
    ld bc, $0019
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $cb44
    ld de, $477a
    ld b, $08
    call $4782
    ld hl, $cad8
    ld de, $477a
    ld b, $08
    call $4782
    ld hl, $cb4d
    ld de, $477a
    ld b, $08
    call $4782
    ld hl, $cae1
    ld de, $477a
    ld b, $08
    call $4782
    ld hl, $cac1
    ld a, [$da14]
    call Call_000_223b
    ld [hl], $01
    ld hl, $cacd
    ld de, $ca42
    ld b, $08
    call $4782
    ld hl, $cad5
    ld a, [$da14]
    call Call_000_223b
    ld a, [$ca4a]
    ld [hl], a
    ld de, $da18
    call Call_014_4849
    ld a, [$da14]
    cp $15
    jr z, jr_014_4158

    ld a, [$da18]
    ld hl, $ca94
    call Call_000_2670

Jump_014_4158:
jr_014_4158:
    ld hl, $caca
    ld de, $da18
    call Call_014_4793
    ld hl, $caea
    ld de, $da2d
    call Call_014_47a8
    ld hl, $cb0c
    ld de, $da1c
    call Call_014_4793
    ld hl, $cb13
    ld de, $da1d
    call Call_014_479e
    ld hl, $cb13
    call Call_014_4821
    ld hl, $cb13
    ld a, [$da14]
    call Call_000_223b
    ld c, [hl]
    inc hl
    ld b, [hl]
    push bc
    ld hl, $cb11
    ld a, [$da14]
    call Call_000_223b
    pop bc
    ld [hl], c
    inc hl
    ld [hl], b
    ld hl, $cb17
    ld de, $da1f
    call Call_014_479e
    ld hl, $cb17
    call Call_014_4821
    ld hl, $cb17
    ld a, [$da14]
    call Call_000_223b
    ld c, [hl]
    inc hl
    ld b, [hl]
    push bc
    ld hl, $cb15
    ld a, [$da14]
    call Call_000_223b
    pop bc
    ld [hl], c
    inc hl
    ld [hl], b
    ld hl, $cb19
    ld de, $da21
    call Call_014_479e
    ld hl, $cb19
    call Call_014_4821
    ld hl, $cb1b
    ld de, $da23
    call Call_014_479e
    ld hl, $cb1b
    call Call_014_4821
    ld hl, $cb1d
    ld de, $da25
    call Call_014_479e
    ld hl, $cb1f
    ld de, $da27
    call Call_014_479e
    ld hl, $cb1f
    call Call_014_4821
    ld hl, $cb25
    ld de, $da29
    call Call_014_4793
    ld hl, $cb25
    call Call_014_47fd
    ld hl, $cb26
    ld de, $da2a
    call Call_014_4793
    ld hl, $cb26
    call Call_014_47fd
    ld hl, $cb27
    ld de, $da2c
    call Call_014_4793
    ld hl, $cb27
    call Call_014_47fd
    ld hl, $cb28
    ld de, $da2b
    call Call_014_4793
    ld hl, $cb28
    call Call_014_47fd
    ld hl, $cb0c
    ld a, [$da14]
    call Call_000_223b
    ld a, [hl]
    ld bc, $0005
    call Call_000_1de6
    push hl
    ld a, [$cab4]
    ld bc, $000a
    call Call_000_1de6
    pop bc
    ld a, c
    sub l
    ld c, a
    ld a, b
    sbc h
    ld b, a
    jr nc, jr_014_425d

    ld bc, $0000

jr_014_425d:
    ld a, b
    or a
    jr z, jr_014_4264

    ld bc, $00ff

jr_014_4264:
    push bc
    ld hl, $cb21
    ld a, [$da14]
    call Call_000_223b
    pop bc
    ld [hl], c
    ld a, [$da18]
    ld [$da31], a
    ld hl, $0301
    rst $10
    ld hl, $cacb
    ld de, $da33
    call Call_014_4793
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $05
    call Call_000_1dfb
    sub $02
    ld b, a
    ld a, [$da34]
    add b
    push af
    ld hl, $cb0d
    ld a, [$da14]
    call Call_000_223b
    pop af
    ld [hl], a
    ld hl, $cb29
    ld de, $da42
    ld b, $1b
    call $4782
    ld hl, $caf2
    ld de, $da39
    ld b, $03
    call $4782
    call Call_014_47ad
    ld hl, $cacc
    ld a, [$da14]
    call Call_000_223b
    ld a, [$da12]
    ld e, a
    ld a, [$da13]
    ld d, a
    ld a, e
    add $1d
    ld e, a
    ld a, d
    adc $4a
    ld d, a
    ld a, [de]
    ld [hl], a
    cp $ff
    jr nz, jr_014_42fe

    ld [hl], $00
    call GenerateRNG
    ld hl, $459e
    ld a, [$da36]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wRNG1]
    cp [hl]
    jr z, jr_014_42fe

    jr nc, jr_014_42fe

    ld hl, $cacc
    ld a, [$da14]
    call Call_000_223b
    ld [hl], $01

jr_014_42fe:
    ld a, [$da14]
    ld [$cac0], a
    ld hl, $1301
    rst $10
    ld a, [$da13]
    or a
    jp nz, Jump_014_4413

    ld a, [$da12]
    cp $01
    ld de, $45a2
    jp z, Jump_014_4469

    cp $0c
    ld de, $45aa
    jp z, Jump_014_4469

    cp $34
    ld de, $45c2
    jp z, Jump_014_4469

    cp $36
    ld de, $45ca
    jp z, Jump_014_4469

    cp $38
    ld de, $45d2
    jp z, Jump_014_4469

    cp $4c
    ld de, $45da
    jp z, Jump_014_4469

    cp $4e
    ld de, $45e2
    jp z, Jump_014_4469

    cp $50
    ld de, $45ea
    jp z, Jump_014_4469

    cp $64
    ld de, $45f2
    jp z, Jump_014_4469

    cp $66
    ld de, $45fa
    jp z, Jump_014_4469

    cp $68
    ld de, $4602
    jp z, Jump_014_4469

    cp $7c
    ld de, $460a
    jp z, Jump_014_4469

    cp $7e
    ld de, $4612
    jp z, Jump_014_4469

    cp $80
    ld de, $461a
    jp z, Jump_014_4469

    cp $94
    ld de, $4622
    jp z, Jump_014_4469

    cp $96
    ld de, $462a
    jp z, Jump_014_4469

    cp $9a
    ld de, $4632
    jp z, Jump_014_4469

    cp $b0
    ld de, $463a
    jp z, Jump_014_4469

    cp $b2
    ld de, $4642
    jp z, Jump_014_4469

    cp $b4
    ld de, $464a
    jp z, Jump_014_4469

    cp $c8
    ld de, $4652
    jp z, Jump_014_4469

    cp $ca
    ld de, $465a
    jp z, Jump_014_4469

    cp $cc
    ld de, $4662
    jp z, Jump_014_4469

    cp $ce
    ld de, $466a
    jp z, Jump_014_4469

    cp $d0
    ld de, $4672
    jp z, Jump_014_4469

    cp $d2
    ld de, $467a
    jp z, Jump_014_4469

    cp $d4
    ld de, $4682
    jp z, Jump_014_4469

    cp $d6
    ld de, $468a
    jp z, Jump_014_4469

    cp $d8
    ld de, $4692
    jp z, Jump_014_4469

    cp $da
    ld de, $469a
    jp z, Jump_014_4469

    cp $dc
    ld de, $46a2
    jp z, Jump_014_4469

    cp $df
    ld de, $46aa
    jp z, Jump_014_4469

    ret


Jump_014_4413:
    ld a, [$da12]
    cp $31
    jr z, jr_014_4472

    cp $32
    jr z, jr_014_4489

    cp $33
    jp z, Jump_014_44a0

    cp $34
    jp z, Jump_014_44b7

    cp $35
    jp z, Jump_014_44ce

    cp $36
    jp z, Jump_014_44e5

    cp $37
    jp z, Jump_014_44fc

    cp $38
    jp z, Jump_014_4513

    cp $39
    jp z, Jump_014_452a

    cp $3a
    jp z, Jump_014_4541

    cp $3b
    jp z, Jump_014_4558

    cp $3c
    jp z, Jump_014_456f

    cp $5e
    jp z, Jump_014_4586

    cp $5f
    jp z, Jump_014_4592

    cp $e4
    ld de, $45b2
    jr z, jr_014_4469

    cp $e5
    ld de, $45ba
    jr z, jr_014_4469

    ret


Jump_014_4469:
jr_014_4469:
    ld hl, $cac2
    ld b, $08
    call $4782
    ret


jr_014_4472:
    ld hl, $cacd
    ld de, $46ba
    ld b, $08
    call $4782
    ld hl, $cac2
    ld de, $46c2
    ld b, $08
    call $4782
    ret


jr_014_4489:
    ld hl, $cacd
    ld de, $46ca
    ld b, $08
    call $4782
    ld hl, $cac2
    ld de, $46d2
    ld b, $08
    call $4782
    ret


Jump_014_44a0:
    ld hl, $cacd
    ld de, $46da
    ld b, $08
    call $4782
    ld hl, $cac2
    ld de, $46e2
    ld b, $08
    call $4782
    ret


Jump_014_44b7:
    ld hl, $cacd
    ld de, $46ea
    ld b, $08
    call $4782
    ld hl, $cac2
    ld de, $46f2
    ld b, $08
    call $4782
    ret


Jump_014_44ce:
    ld hl, $cacd
    ld de, $46fa
    ld b, $08
    call $4782
    ld hl, $cac2
    ld de, $4702
    ld b, $08
    call $4782
    ret


Jump_014_44e5:
    ld hl, $cacd
    ld de, $470a
    ld b, $08
    call $4782
    ld hl, $cac2
    ld de, $4712
    ld b, $08
    call $4782
    ret


Jump_014_44fc:
    ld hl, $cacd
    ld de, $471a
    ld b, $08
    call $4782
    ld hl, $cac2
    ld de, $4722
    ld b, $08
    call $4782
    ret


Jump_014_4513:
    ld hl, $cacd
    ld de, $472a
    ld b, $08
    call $4782
    ld hl, $cac2
    ld de, $4732
    ld b, $08
    call $4782
    ret


Jump_014_452a:
    ld hl, $cacd
    ld de, $473a
    ld b, $08
    call $4782
    ld hl, $cac2
    ld de, $4742
    ld b, $08
    call $4782
    ret


Jump_014_4541:
    ld hl, $cacd
    ld de, $474a
    ld b, $08
    call $4782
    ld hl, $cac2
    ld de, $4752
    ld b, $08
    call $4782
    ret


Jump_014_4558:
    ld hl, $cacd
    ld de, $475a
    ld b, $08
    call $4782
    ld hl, $cac2
    ld de, $4762
    ld b, $08
    call $4782
    ret


Jump_014_456f:
    ld hl, $cacd
    ld de, $476a
    ld b, $08
    call $4782
    ld hl, $cac2
    ld de, $4772
    ld b, $08
    call $4782
    ret


Jump_014_4586:
    ld hl, $cb24
    ld a, [$da14]
    call Call_000_223b
    ld [hl], $01
    ret


Jump_014_4592:
    ld hl, $cac2
    ld de, $46b2
    ld b, $08
    call $4782
    ret


    nop
    ld a, [de]
    add b
    sub $36
    ld c, c
    ld b, [hl]
    ccf
    ldh a, [$f0]
    ldh a, [$f0]
    dec hl
    ld a, $49
    ld b, d
    ldh a, [$f0]
    ldh a, [$f0]
    daa
    ld c, a
    ld a, $4b
    ldh a, [$f0]
    ldh a, [$f0]
    ld a, [hl+]
    ld c, h
    ld c, c
    ld c, d
    ldh a, [$f0]
    ldh a, [$f0]
    ld a, [hl+]
    ld b, [hl]
    ld b, h
    ldh a, [$f0]
    ldh a, [$f0]
    ldh a, [$29]
    ld a, $40
    ld b, d
    ldh a, [$f0]
    ldh a, [$f0]
    inc sp
    ld a, $50
    ld b, l
    ldh a, [$f0]
    ldh a, [$f0]
    add hl, hl
    ld a, $4b
    ld b, h
    ldh a, [$f0]
    ldh a, [$f0]
    db $76
    adc l
    ld h, d
    ld d, [hl]
    ld e, b
    ldh a, [$f0]
    ldh a, [$2a]
    ld a, $4b
    ld d, c
    ldh a, [$f0]
    ldh a, [$f0]
    ld h, $2d
    adc l
    dec hl
    ld [hl-], a
    adc l
    ldh a, [$f0]
    ld a, [hl-]
    ld c, a
    ld b, d
    ld d, l
    ldh a, [$f0]
    ldh a, [$f0]
    jr nc, @+$48

    ld c, d
    ld b, d
    ldh a, [$f0]
    ldh a, [$f0]
    add hl, hl
    ld d, d
    ld c, e
    ld b, b
    ldh a, [$f0]
    ldh a, [$f0]
    ld h, a
    ld h, b
    ld l, a
    adc l
    add l
    ldh a, [$f0]
    ldh a, [$28]
    ccf
    ld b, [hl]
    ldh a, [$f0]
    ldh a, [$f0]
    ldh a, [$66]
    adc l
    add b
    ld a, e
    add l
    ldh a, [$f0]
    ldh a, [$30]
    ld a, $51
    ld d, b
    ldh a, [$f0]
    ldh a, [$f0]
    ld l, $46
    ld d, l
    ldh a, [$f0]
    ldh a, [$f0]
    ldh a, [$27]
    ld a, $4f
    ld c, b
    ldh a, [$f0]
    ldh a, [$f0]
    ld d, [hl]
    ld h, d
    ld [hl], l
    adc l
    sbc h
    ldh a, [$f0]
    ldh a, [$28]
    ld d, d
    inc [hl]
    ldh a, [$f0]
    ldh a, [$f0]
    ldh a, [$6e]
    adc l
    add d
    add l
    adc h
    ldh a, [$f0]
    ldh a, [rVBK]
    ld c, e
    ld h, $28
    ldh a, [$f0]
    ldh a, [$f0]
    ld [hl], l
    sbc h
    ld h, h
    adc l
    adc h
    ldh a, [$f0]
    ldh a, [$66]
    ld l, a
    adc l
    sbc h
    ldh a, [$f0]
    ldh a, [$f0]
    ld [hl], l
    adc l
    add l
    ld a, [hl]
    ld h, a
    ldh a, [$f0]
    ldh a, [rBCPD]
    adc l
    sbc h
    ld a, d
    ldh a, [$f0]
    ldh a, [$f0]
    db $76
    adc [hl]
    ld h, l
    adc c
    ldh a, [$f0]
    ldh a, [$f0]
    ld e, h
    ld h, a
    ld l, d
    ld h, d
    ldh a, [$f0]
    ldh a, [$f0]
    ld a, e
    add a
    ld l, a
    adc l
    add l
    ldh a, [$f0]
    ldh a, [$7c]
    ld l, a
    adc l
    sbc h
    ldh a, [$f0]
    ldh a, [$f0]
    ld a, h
    sbc h
    ld d, [hl]
    ldh a, [$f0]
    ldh a, [$f0]
    ldh a, [$3a]
    ld a, $51
    ld a, $f0
    ldh a, [$f0]
    ldh a, [$36]
    ld c, c
    ld b, [hl]
    ld c, h
    ldh a, [$f0]
    ldh a, [$f0]
    jr nc, @+$48

    ld b, b
    ld c, b
    ldh a, [$f0]
    ldh a, [$f0]
    cpl
    ld b, [hl]
    ld d, a
    ld b, c
    ldh a, [$f0]
    ldh a, [$f0]
    daa
    ld c, h
    ccf
    ldh a, [$f0]
    ldh a, [$f0]
    ldh a, [$29]
    ld d, d
    ld b, h
    ld a, $f0
    ldh a, [$f0]
    ldh a, [$30]
    ld b, [hl]
    ld b, b
    ld c, b
    ldh a, [$f0]
    ldh a, [$f0]
    dec h
    ld c, h
    ld c, e
    ld b, d
    ldh a, [$f0]
    ldh a, [$f0]
    scf
    ld b, d
    ld d, c
    ld c, h
    ldh a, [$f0]
    ldh a, [$f0]
    ld l, $52
    ld c, a
    ld b, d
    ldh a, [$f0]
    ldh a, [$f0]
    jr nc, jr_014_473a

    ld d, [hl]
    ldh a, [$f0]
    ldh a, [$f0]
    ldh a, [$3d]
    ld b, d
    ld b, d
    ldh a, [$f0]
    ldh a, [$f0]
    ldh a, [$37]
    ld b, d
    ld d, c
    ld c, h
    ldh a, [$f0]
    ldh a, [$f0]
    inc sp
    ld a, $40
    ld b, l
    ldh a, [$f0]
    ldh a, [$f0]
    jr nc, @+$44

    ld d, c
    ld a, $f0
    ldh a, [$f0]
    ldh a, [$30]
    ld c, h
    ld b, l
    ld a, $f0
    ldh a, [$f0]
    ldh a, [$30]
    ld a, $44
    ld b, [hl]
    ldh a, [$f0]
    ldh a, [$f0]
    ld h, d
    add a
    ld l, a
    sbc h
    ldh a, [$f0]
    ldh a, [$f0]

jr_014_473a:
    scf
    ld b, d
    ld d, c
    ld c, h
    ldh a, [$f0]
    ldh a, [$f0]
    daa
    ld b, [hl]
    ld d, a
    ldh a, [$f0]
    ldh a, [$f0]
    ldh a, [$30]
    ld a, $56
    ldh a, [$f0]
    ldh a, [$f0]
    ldh a, [$33]
    ld b, d
    ld d, c
    ld b, d
    ldh a, [$f0]
    ldh a, [$f0]
    jr nc, jr_014_479e

    ld d, c
    ld a, $f0
    ldh a, [$f0]
    ldh a, [$30]
    ld b, d
    ld d, c
    ld a, $f0
    ldh a, [$f0]
    ldh a, [$30]
    ld b, [hl]
    ld c, c
    ld a, $f0
    ldh a, [$f0]
    ldh a, [$2e]
    ld a, $46
    ldh a, [$f0]
    ldh a, [$f0]
    ldh a, [$64]
    ld h, h
    ld h, h
    ldh a, [$f0]
    ldh a, [$f0]
    ldh a, [$c5]
    push de
    ld a, [$da14]
    call Call_000_223b
    pop de
    pop bc

jr_014_478c:
    ld a, [de]
    ld [hl+], a
    inc de
    dec b
    jr nz, jr_014_478c

    ret


Call_014_4793:
    push de
    ld a, [$da14]
    call Call_000_223b
    pop de
    ld a, [de]
    ld [hl], a
    ret


Call_014_479e:
jr_014_479e:
    ld b, $02
    jp $4782


    ld b, $03
    jp $4782


Call_014_47a8:
    ld b, $04
    jp $4782


Call_014_47ad:
    ld hl, $caea
    ld a, [$da14]
    call Call_000_223b
    ld e, l
    ld d, h
    ld b, $08

jr_014_47ba:
    ld a, [de]
    push bc
    push de
    call Call_014_47c7
    pop de
    pop bc
    inc de
    dec b
    jr nz, jr_014_47ba

    ret


Call_014_47c7:
    cp $ff
    ret z

    cp $db
    jr nz, jr_014_47d2

    ld a, $ff
    ld [de], a
    ret


jr_014_47d2:
    ld hl, $491d
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $ff
    ret z

    push af
    ld hl, $caf2
    ld a, [$da14]
    call Call_000_223b
    pop af
    ld b, $19
    ld c, a

jr_014_47ed:
    ld a, [hl]
    cp $ff
    jr z, jr_014_47f8

    cp c
    jr nz, jr_014_47f8

    ld [hl], $ff
    ret


jr_014_47f8:
    inc hl
    dec b
    jr nz, jr_014_47ed

    ret


Call_014_47fd:
    push hl
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $34
    call Call_000_1dfb
    add $cd
    pop hl
    ret z

    push af
    ld a, [$da14]
    call Call_000_223b
    ld c, [hl]
    ld b, $00
    pop af
    push hl
    call Call_000_1de6
    ld c, h
    pop hl
    ld [hl], c
    ret


Call_014_4821:
    push hl
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $34
    call Call_000_1dfb
    add $cd
    pop hl
    ret z

    push af
    ld a, [$da14]
    call Call_000_223b
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    pop af
    dec hl
    push hl
    call Call_000_1de6
    ld c, h
    ld b, e
    pop hl
    ld [hl], c
    inc hl
    ld [hl], b
    ret


; EnemyStatsLoad — Copy 25 bytes from enemy stats table to WRAM
; Input: $DA12/$DA13 = enemy stats ID (16-bit LE)
;        DE = destination WRAM address
; Calculates: table_base($4C1D) + eid × 25
; Output: 25 bytes copied to [DE]
Call_014_4849:
    push de
    ld a, [$da12]            ; EID low byte
    ld c, a
    ld a, [$da13]            ; EID high byte
    ld b, a                  ; BC = enemy stats ID
    ld a, $19                ; 25 = entry size
    call Call_000_1de6       ; HL = EID × 25
    ld a, l
    add $1d                  ; HL += $4C1D (enemy stats table base)
    ld l, a
    ld a, h
    adc $4c
    ld h, a
    pop de
    ld b, $19                ; copy 25 bytes

jr_014_4862:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, jr_014_4862

    ret

; BossRedirectLookup — Remap a fight EID to its join EID
; Input: $DA12/$DA13 = source EID (boss fight encounter)
; Scans redirect table at $4893 for matching fight EID
; If found: overwrites $DA12/$DA13 with join EID
; Table format: [match_eid_lo, match_eid_hi, replace_eid_lo, replace_eid_hi]
;   terminated by $FFFF
; First entry at $4893 is a non-boss redirect (EID 4 → EID 486)
; Boss entries start at $4897: 32 gates × 4 bytes
;   Gate 0:  fight EID 11 → join EID 12 (Healer)
;   Gate 1:  fight EID 31 → join EID 484 (Dragon)
;   ...see dump_boss_table.py output for full list
label14_4869:
    ld a, [$da12]            ; source EID low
    ld c, a
    ld a, [$da13]            ; source EID high
    ld b, a                  ; BC = source EID
    ld hl, $4893             ; redirect table base

jr_014_4874:
    ld a, [hl+]              ; read match EID low
    ld e, a
    ld a, [hl+]              ; read match EID high
    ld d, a
    and e
    cp $ff                   ; check for $FFFF terminator
    jr nz, jr_014_487e

    ret                      ; no match found


jr_014_487e:
    ld a, e
    cp c                     ; compare match EID low with source
    jr nz, jr_014_488f

    ld a, d
    cp b                     ; compare match EID high with source
    jr nz, jr_014_488f

    ld a, [hl+]              ; MATCH: read replacement EID low
    ld [$da12], a
    ld a, [hl+]              ; read replacement EID high
    ld [$da13], a
    ret


jr_014_488f:
    inc hl                   ; skip replacement EID (no match)
    inc hl
    jr jr_014_4874           ; check next entry

; ---------------------------------------------------------------

; ---------------------------------------------------------------
; Boss Redirect Table ($4893)
; Scanned by label14_4869 (entry 6) to redirect fight EIDs to join EIDs
; Format: dw fight_eid, join_eid  (16-bit LE pairs)
; Terminated by $FFFF
; ---------------------------------------------------------------

BossRedirectTable:
    dw 4, 486  ; [0] Non-boss redirect (EID 4 -> 486)
    dw 11, 12  ; [1] Gate of Beginning: Healer (fight=11, join=12)
    dw 31, 484  ; [2] Gate of Villager: Dragon (fight=31, join=484)
    dw 32, 485  ; [3] Gate of Talisman: Golem (fight=32, join=485)
    dw 51, 52  ; [4] Gate of Memories: MadCat (fight=51, join=52)
    dw 53, 54  ; [5] Gate of Bewilder: FaceTree (fight=53, join=54)
    dw 55, 56  ; [6] Bazaar Gate: MadKnight (fight=55, join=56)
    dw 75, 76  ; [7] Gate of Peace: FangSlime (fight=75, join=76)
    dw 77, 78  ; [8] Gate of Bravery: BigEye (fight=77, join=78)
    dw 79, 80  ; [9] Well Gate: Gigantes (fight=79, join=80)
    dw 99, 100  ; [10] Gate of Strength: StoneMan (fight=99, join=100)
    dw 101, 102  ; [11] Gate of Anger: BattleRex (fight=101, join=102)
    dw 103, 104  ; [12] Farm Gate: Copycat (fight=103, join=104)
    dw 123, 124  ; [13] Gate of Joy: FunkyBird (fight=123, join=124)
    dw 125, 126  ; [14] Gate of Wisdom: SkyDragon (fight=125, join=126)
    dw 127, 128  ; [15] Arena - Left Gate: Digster (fight=127, join=128)
    dw 147, 148  ; [16] Gate of Happiness: Jamirus (fight=147, join=148)
    dw 149, 150  ; [17] Gate of Temptation: Servant (fight=149, join=150)
    dw 153, 154  ; [18] Medal Gate: KingSlime (fight=153, join=154)
    dw 175, 176  ; [19] Gate of Labyrinth: DarkHorn (fight=175, join=176)
    dw 177, 178  ; [20] Gate of Judgement: Akubar (fight=177, join=178)
    dw 179, 180  ; [21] Library Gate: Orochi (fight=179, join=180)
    dw 199, 200  ; [22] Gate of Reflection: Durran (fight=199, join=200)
    dw 201, 202  ; [23] Gate of Ambition: DracoLord (fight=201, join=202)
    dw 203, 204  ; [24] Gate of Demolition (Hargon): Hargon (fight=203, join=204)
    dw 205, 206  ; [25] Gate of Demolition (Sidoh): Sidoh (fight=205, join=206)
    dw 207, 208  ; [26] Gate of Mastermind: Baramos (fight=207, join=208)
    dw 209, 210  ; [27] Gate of Control: Zoma (fight=209, join=210)
    dw 211, 212  ; [28] Gate of Extinction: Pizzaro (fight=211, join=212)
    dw 213, 214  ; [29] Gate of Sleep: Esterk (fight=213, join=214)
    dw 215, 216  ; [30] Bazaar Edge Gate: Mirudraas (fight=215, join=216)
    dw 217, 218  ; [31] Arena - Right Gate: Mudou (fight=217, join=218)
    dw 219, 220  ; [32] Old Man's Gate: DeathMore (fight=219, join=220)
    dw 221, 222  ; [33] Cut Content: Darkdrium (fight=221, join=222)
    dw $FFFF, $0000  ; Terminator

; ---------------------------------------------------------------
; Unknown data block ($491F-$4C1C, 766 bytes)
; Purpose not yet identified — possibly EID lookup table or
; encounter-related mapping. Sequential single-byte values.
; ---------------------------------------------------------------

UnknownData_491F:
    db $00, $03, $03, $03, $06, $06, $06, $09, $09, $09, $0C, $0C, $0C, $0F, $0F, $0F  ; $491F
    db $12, $12, $14, $15, $15, $17, $18, $19, $1A, $1A, $1C, $1C, $1E, $1E, $20, $20  ; $492F
    db $22, $22, $24, $25, $26, $27, $27, $29, $2A, $2B, $2B, $2B, $2E, $2E, $30, $30  ; $493F
    db $32, $33, $34, $35, $36, $37, $38, $39, $FF, $3B, $3C, $3D, $3E, $3F, $40, $41  ; $494F
    db $42, $43, $44, $45, $46, $47, $48, $49, $4A, $4B, $4C, $4D, $4E, $4F, $50, $50  ; $495F
    db $52, $52, $54, $55, $56, $57, $58, $58, $5A, $5B, $5C, $5C, $5C, $5C, $60, $60  ; $496F
    db $60, $60, $64, $65, $66, $67, $68, $69, $6A, $6B, $6C, $6C, $6E, $6F, $70, $71  ; $497F
    db $72, $73, $74, $75, $75, $77, $78, $79, $79, $7B, $7B, $7D, $7E, $7F, $80, $81  ; $498F
    db $82, $83, $84, $84, $84, $84, $88, $88, $8A, $8A, $8C, $FF, $8E, $8F, $90, $91  ; $499F
    db $92, $93, $94, $95, $96, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $49AF
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $49BF
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $49CF
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $49DF
    db $FF, $FF, $FF, $D5, $D6, $D7, $D8, $D9, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $49EF
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $49FF
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00  ; $4A0F
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $FF, $FF, $FF, $FF, $FF  ; $4A1F
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $FF  ; $4A2F
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4A3F
    db $FF, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4A4F
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $FF  ; $4A5F
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4A6F
    db $FF, $00, $00, $01, $01, $01, $01, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4A7F
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $FF, $FF, $FF  ; $4A8F
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4A9F
    db $FF, $00, $00, $00, $00, $00, $00, $01, $01, $01, $FF, $FF, $FF, $FF, $FF, $FF  ; $4AAF
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00  ; $4ABF
    db $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4ACF
    db $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $4ADF
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF  ; $4AEF
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4AFF
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4B0F
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4B1F
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4B2F
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4B3F
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4B4F
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4B5F
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $FF, $FF  ; $4B6F
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4B7F
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4B8F
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4B9F
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4BAF
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4BBF
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4BCF
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4BDF
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4BEF
    db $FF, $FF, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4BFF
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; $4C0F

; ---------------------------------------------------------------
; Enemy Stats Table ($4C1D)
; 487 entries x 25 bytes = 12175 bytes
;
; Format (25 bytes per entry):
;   +$00    Species ID
;   +$01-02 EXP reward (16-bit LE)
;   +$03    Joinability (0=always..5=standard..7=never)
;   +$04    Level
;   +$05-06 HP (16-bit LE)
;   +$07-08 MP (16-bit LE)
;   +$09-0A ATK (16-bit LE)
;   +$0B-0C DEF (16-bit LE)
;   +$0D-0E AGL (16-bit LE)
;   +$0F-10 INT (16-bit LE)
;   +$11-14 AI weights (4 bytes)
;   +$15-18 Skills (4 bytes, $FF = none)
; ---------------------------------------------------------------

EnemyStatsTable:
; --- EID 0 (0x0): DrakSlime Lv0 ---
EnemyStats_000:
    db 0  ; Species: DrakSlime
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 0  ; Level
    dw 0, 0, 0, 0, 0, 0  ; HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 1 (0x1): Slime Lv1 ---
EnemyStats_001:
    db 8  ; Species: Slime
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 1  ; Level
    dw 30, 0, 10, 6, 5, 1  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 200, 100, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 2 (0x2): Slime Lv1 ---
EnemyStats_002:
    db 8  ; Species: Slime
    dw 3  ; EXP reward
    db 2  ; Joinability (2)
    db 1  ; Level
    dw 8, 0, 8, 5, 7, 1  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 100, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 3 (0x3): Anteater Lv1 ---
EnemyStats_003:
    db 53  ; Species: Anteater
    dw 9  ; EXP reward
    db 1  ; Joinability (1)
    db 1  ; Level
    dw 12, 0, 19, 4, 4, 3  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 0, 50, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 4 (0x4): Dracky Lv1 ---
EnemyStats_004:
    db 78  ; Species: Dracky
    dw 4  ; EXP reward
    db 1  ; Joinability (1)
    db 1  ; Level
    dw 8, 20, 12, 4, 12, 14  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 0, 200  ; AI weights
    db $33, $FF, $FF, $FF  ; Skills: Antidote, none, none, none

; --- EID 5 (0x5): Stubsuck Lv2 ---
EnemyStats_005:
    db 98  ; Species: Stubsuck
    dw 9  ; EXP reward
    db 2  ; Joinability (2)
    db 2  ; Level
    dw 20, 6, 23, 8, 12, 10  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 50, 200, 200  ; AI weights
    db $15, $FF, $FF, $FF  ; Skills: Sleep, none, none, none

; --- EID 6 (0x6): GoHopper Lv2 ---
EnemyStats_006:
    db 119  ; Species: GoHopper
    dw 10  ; EXP reward
    db 2  ; Joinability (2)
    db 2  ; Level
    dw 24, 2, 18, 6, 10, 8  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 50, 0, 200  ; AI weights
    db $41, $FF, $FF, $FF  ; Skills: ChargeUP, none, none, none

; --- EID 7 (0x7): Gremlin Lv2 ---
EnemyStats_007:
    db 139  ; Species: Gremlin
    dw 10  ; EXP reward
    db 2  ; Joinability (2)
    db 2  ; Level
    dw 26, 9, 14, 9, 9, 28  ; HP, MP, ATK, DEF, AGL, INT
    db 50, 150, 200, 200  ; AI weights
    db $03, $2B, $FF, $FF  ; Skills: Firebal, Heal, none, none

; --- EID 8 (0x8): Spooky Lv3 ---
EnemyStats_008:
    db 155  ; Species: Spooky
    dw 18  ; EXP reward
    db 3  ; Joinability (3)
    db 3  ; Level
    dw 37, 3, 25, 9, 31, 13  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 200, 200  ; AI weights
    db $79, $FF, $FF, $FF  ; Skills: LushLicks, none, none, none

; --- EID 9 (0x9): Goopi Lv5 ---
EnemyStats_009:
    db 183  ; Species: Goopi
    dw 16  ; EXP reward
    db 3  ; Joinability (3)
    db 5  ; Level
    dw 41, 3, 28, 8, 8, 6  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 150, 200  ; AI weights
    db $7B, $FF, $FF, $FF  ; Skills: LegSweep, none, none, none

; --- EID 10 (0xa): ArmyAnt Lv3 ---
EnemyStats_010:
    db 118  ; Species: ArmyAnt
    dw 12  ; EXP reward
    db 2  ; Joinability (2)
    db 3  ; Level
    dw 24, 3, 29, 9, 11, 13  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 0, 200  ; AI weights
    db $68, $FF, $FF, $FF  ; Skills: NapAttack, none, none, none

; --- EID 11 (0xb): Healer Lv6 ---
EnemyStats_011:
    db 9  ; Species: Healer
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 6  ; Level
    dw 40, 7, 20, 12, 12, 28  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 250, 100, 200  ; AI weights
    db $2B, $FF, $FF, $FF  ; Skills: Heal, none, none, none

; --- EID 12 (0xc): Healer Lv6 ---
EnemyStats_012:
    db 9  ; Species: Healer
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 6  ; Level
    dw 30, 18, 16, 10, 32, 28  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 250, 200, 200  ; AI weights
    db $2B, $FF, $FF, $FF  ; Skills: Heal, none, none, none

; --- EID 13 (0xd): MiniDrak Lv4 ---
EnemyStats_013:
    db 29  ; Species: MiniDrak
    dw 32  ; EXP reward
    db 3  ; Joinability (3)
    db 4  ; Level
    dw 45, 5, 32, 10, 18, 6  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 100, 150, 150  ; AI weights
    db $72, $FF, $FF, $FF  ; Skills: SandStorm, none, none, none

; --- EID 14 (0xe): Picky Lv4 ---
EnemyStats_014:
    db 70  ; Species: Picky
    dw 25  ; EXP reward
    db 2  ; Joinability (2)
    db 4  ; Level
    dw 32, 6, 30, 12, 26, 12  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 150, 150  ; AI weights
    db $1C, $FF, $FF, $FF  ; Skills: Sap, none, none, none

; --- EID 15 (0xf): PillowRat Lv4 ---
EnemyStats_015:
    db 48  ; Species: PillowRat
    dw 27  ; EXP reward
    db 3  ; Joinability (3)
    db 4  ; Level
    dw 29, 12, 26, 12, 30, 13  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 50, 100, 150  ; AI weights
    db $77, $FF, $FF, $FF  ; Skills: SideStep, none, none, none

; --- EID 16 (0x10): Hork Lv5 ---
EnemyStats_016:
    db 163  ; Species: Hork
    dw 45  ; EXP reward
    db 3  ; Joinability (3)
    db 5  ; Level
    dw 51, 6, 35, 10, 10, 10  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 50, 150  ; AI weights
    db $6C, $79, $FF, $FF  ; Skills: PoisonGas, LushLicks, none, none

; --- EID 17 (0x11): DragonKid Lv6 ---
EnemyStats_017:
    db 20  ; Species: DragonKid
    dw 55  ; EXP reward
    db 3  ; Joinability (3)
    db 6  ; Level
    dw 32, 7, 32, 20, 35, 11  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 100, 100, 150  ; AI weights
    db $6A, $8C, $FF, $FF  ; Skills: SleepAir, Dodge, none, none

; --- EID 18 (0x12): EvilSeed Lv7 ---
EnemyStats_018:
    db 105  ; Species: EvilSeed
    dw 50  ; EXP reward
    db 2  ; Joinability (2)
    db 7  ; Level
    dw 43, 5, 29, 25, 15, 28  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 250, 150  ; AI weights
    db $4E, $69, $FF, $FF  ; Skills: CleanCut, Paralyze, none, none

; --- EID 19 (0x13): Catapila Lv8 ---
EnemyStats_019:
    db 111  ; Species: Catapila
    dw 64  ; EXP reward
    db 3  ; Joinability (3)
    db 8  ; Level
    dw 38, 16, 44, 29, 12, 10  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 100, 150  ; AI weights
    db $1E, $FF, $FF, $FF  ; Skills: Upper, none, none, none

; --- EID 20 (0x14): FairyRat Lv6 ---
EnemyStats_020:
    db 61  ; Species: FairyRat
    dw 55  ; EXP reward
    db 2  ; Joinability (2)
    db 6  ; Level
    dw 48, 18, 32, 14, 40, 30  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 50, 200, 150  ; AI weights
    db $20, $D6, $FF, $FF  ; Skills: Slow, Smashlime, none, none

; --- EID 21 (0x15): BigRoost Lv8 ---
EnemyStats_021:
    db 79  ; Species: BigRoost
    dw 67  ; EXP reward
    db 2  ; Joinability (2)
    db 8  ; Level
    dw 48, 18, 28, 16, 42, 9  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 150, 150, 150  ; AI weights
    db $72, $8C, $FF, $FF  ; Skills: SandStorm, Dodge, none, none

; --- EID 22 (0x16): Demonite Lv7 ---
EnemyStats_022:
    db 133  ; Species: Demonite
    dw 65  ; EXP reward
    db 2  ; Joinability (2)
    db 7  ; Level
    dw 41, 3, 34, 14, 40, 19  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 100, 250, 150  ; AI weights
    db $01, $FF, $FF, $FF  ; Skills: Blazemore, none, none, none

; --- EID 23 (0x17): BoneSlave Lv7 ---
EnemyStats_023:
    db 171  ; Species: BoneSlave
    dw 67  ; EXP reward
    db 3  ; Joinability (3)
    db 7  ; Level
    dw 53, 20, 53, 15, 24, 45  ; HP, MP, ATK, DEF, AGL, INT
    db 50, 0, 0, 150  ; AI weights
    db $45, $4B, $FF, $FF  ; Skills: BoltSlash, BirdBlow, none, none

; --- EID 24 (0x18): SabreMan Lv7 ---
EnemyStats_024:
    db 187  ; Species: SabreMan
    dw 64  ; EXP reward
    db 2  ; Joinability (2)
    db 7  ; Level
    dw 45, 20, 60, 24, 26, 42  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 100, 150  ; AI weights
    db $1A, $4C, $FF, $FF  ; Skills: RobMagic, DevilCut, none, none

; --- EID 25 (0x19): SpotSlime Lv8 ---
EnemyStats_025:
    db 1  ; Species: SpotSlime
    dw 72  ; EXP reward
    db 2  ; Joinability (2)
    db 8  ; Level
    dw 48, 11, 39, 14, 50, 11  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 100, 100, 150  ; AI weights
    db $52, $79, $FF, $FF  ; Skills: CallHelp, LushLicks, none, none

; --- EID 26 (0x1a): Crestpent Lv8 ---
EnemyStats_026:
    db 38  ; Species: Crestpent
    dw 73  ; EXP reward
    db 2  ; Joinability (2)
    db 8  ; Level
    dw 62, 8, 32, 33, 15, 9  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 50, 150  ; AI weights
    db $17, $67, $FF, $FF  ; Skills: StopSpell, PoisonHit, none, none

; --- EID 27 (0x1b): BeanMan Lv8 ---
EnemyStats_027:
    db 104  ; Species: BeanMan
    dw 90  ; EXP reward
    db 2  ; Joinability (2)
    db 8  ; Level
    dw 61, 11, 40, 34, 30, 10  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 200, 150  ; AI weights
    db $1A, $25, $FF, $FF  ; Skills: RobMagic, TwinHits, none, none

; --- EID 28 (0x1c): 1EyeClown Lv9 ---
EnemyStats_028:
    db 138  ; Species: 1EyeClown
    dw 81  ; EXP reward
    db 2  ; Joinability (2)
    db 9  ; Level
    dw 54, 14, 42, 20, 38, 30  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 250, 150  ; AI weights
    db $01, $FF, $FF, $FF  ; Skills: Blazemore, none, none, none

; --- EID 29 (0x1d): CoilBird Lv9 ---
EnemyStats_029:
    db 178  ; Species: CoilBird
    dw 78  ; EXP reward
    db 3  ; Joinability (3)
    db 9  ; Level
    dw 66, 30, 34, 22, 52, 17  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 200, 100, 150  ; AI weights
    db $34, $35, $FF, $FF  ; Skills: NumbOff, DeChaos, none, none

; --- EID 30 (0x1e): Metaly Lv10 ---
EnemyStats_030:
    db 16  ; Species: Metaly
    dw 3365  ; EXP reward
    db 6  ; Joinability (6)
    db 10  ; Level
    dw 6, 120, 22, 300, 130, 32  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 100, 100, 150  ; AI weights
    db $00, $DB, $FF, $FF  ; Skills: Blaze, RUN, none, none

; --- EID 31 (0x1f): Dragon Lv6 ---
EnemyStats_031:
    db 28  ; Species: Dragon
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 6  ; Level
    dw 90, 60, 40, 25, 15, 10  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 0, 150  ; AI weights
    db $44, $5C, $FF, $FF  ; Skills: FireSlash, FireAir, none, none

; --- EID 32 (0x20): Golem Lv7 ---
EnemyStats_032:
    db 196  ; Species: Golem
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 7  ; Level
    dw 100, 20, 45, 20, 20, 70  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 150, 150, 150  ; AI weights
    db $41, $56, $8E, $FF  ; Skills: ChargeUP, PsycheUp, StrongD, none

; --- EID 33 (0x21): Almiraj Lv10 ---
EnemyStats_033:
    db 46  ; Species: Almiraj
    dw 130  ; EXP reward
    db 3  ; Joinability (3)
    db 10  ; Level
    dw 57, 46, 48, 25, 50, 15  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 100, 100  ; AI weights
    db $15, $3D, $41, $FF  ; Skills: Sleep, Beserker, ChargeUP, none

; --- EID 34 (0x22): BullBird Lv12 ---
EnemyStats_034:
    db 72  ; Species: BullBird
    dw 144  ; EXP reward
    db 3  ; Joinability (3)
    db 12  ; Level
    dw 72, 17, 64, 21, 57, 10  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 200, 100  ; AI weights
    db $3C, $41, $D8, $FF  ; Skills: Ramming, ChargeUP, Branching, none

; --- EID 35 (0x23): FloraMan Lv12 ---
EnemyStats_035:
    db 92  ; Species: FloraMan
    dw 121  ; EXP reward
    db 3  ; Joinability (3)
    db 12  ; Level
    dw 68, 80, 30, 26, 39, 65  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 150, 250, 100  ; AI weights
    db $04, $33, $36, $FF  ; Skills: Firebane, Antidote, CurseOff, none

; --- EID 36 (0x24): GiantWorm Lv12 ---
EnemyStats_036:
    db 115  ; Species: GiantWorm
    dw 126  ; EXP reward
    db 3  ; Joinability (3)
    db 12  ; Level
    dw 62, 20, 59, 24, 45, 40  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 200, 100  ; AI weights
    db $4A, $75, $FF, $FF  ; Skills: BeastCut, OddDance, none, none

; --- EID 37 (0x25): SkulRider Lv11 ---
EnemyStats_037:
    db 136  ; Species: SkulRider
    dw 175  ; EXP reward
    db 3  ; Joinability (3)
    db 11  ; Level
    dw 80, 20, 63, 45, 42, 19  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 0, 100, 100  ; AI weights
    db $44, $57, $7B, $FF  ; Skills: FireSlash, RainSlash, LegSweep, none

; --- EID 38 (0x26): GiantSlug Lv12 ---
EnemyStats_038:
    db 110  ; Species: GiantSlug
    dw 132  ; EXP reward
    db 2  ; Joinability (2)
    db 12  ; Level
    dw 60, 18, 51, 25, 43, 21  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 200, 200, 100  ; AI weights
    db $79, $8C, $FF, $FF  ; Skills: LushLicks, Dodge, none, none

; --- EID 39 (0x27): MudDoll Lv12 ---
EnemyStats_039:
    db 195  ; Species: MudDoll
    dw 144  ; EXP reward
    db 3  ; Joinability (3)
    db 12  ; Level
    dw 79, 44, 56, 28, 22, 44  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 100, 200, 100  ; AI weights
    db $75, $77, $FF, $FF  ; Skills: OddDance, SideStep, none, none

; --- EID 40 (0x28): TreeSlime Lv12 ---
EnemyStats_040:
    db 3  ; Species: TreeSlime
    dw 151  ; EXP reward
    db 3  ; Joinability (3)
    db 12  ; Level
    dw 86, 22, 44, 28, 69, 46  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 50, 200, 100  ; AI weights
    db $1C, $69, $6A, $FF  ; Skills: Sap, Paralyze, SleepAir, none

; --- EID 41 (0x29): Poisongon Lv12 ---
EnemyStats_041:
    db 26  ; Species: Poisongon
    dw 150  ; EXP reward
    db 3  ; Joinability (3)
    db 12  ; Level
    dw 65, 43, 59, 50, 26, 23  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 100, 100, 100  ; AI weights
    db $67, $6C, $FF, $FF  ; Skills: PoisonHit, PoisonGas, none, none

; --- EID 42 (0x2a): CatFly Lv13 ---
EnemyStats_042:
    db 47  ; Species: CatFly
    dw 146  ; EXP reward
    db 2  ; Joinability (2)
    db 13  ; Level
    dw 67, 46, 56, 26, 67, 49  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 150, 100  ; AI weights
    db $17, $20, $FF, $FF  ; Skills: StopSpell, Slow, none, none

; --- EID 43 (0x2b): WingTree Lv13 ---
EnemyStats_043:
    db 93  ; Species: WingTree
    dw 160  ; EXP reward
    db 3  ; Joinability (3)
    db 13  ; Level
    dw 69, 60, 67, 30, 52, 40  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 200, 100  ; AI weights
    db $32, $4D, $FF, $FF  ; Skills: Farewell, ZombieCut, none, none

; --- EID 44 (0x2c): Eyeder Lv16 ---
EnemyStats_044:
    db 122  ; Species: Eyeder
    dw 156  ; EXP reward
    db 3  ; Joinability (3)
    db 16  ; Level
    dw 54, 15, 70, 90, 85, 50  ; HP, MP, ATK, DEF, AGL, INT
    db 50, 150, 200, 100  ; AI weights
    db $03, $2B, $FF, $FF  ; Skills: Firebal, Heal, none, none

; --- EID 45 (0x2d): Putrepup Lv14 ---
EnemyStats_045:
    db 157  ; Species: Putrepup
    dw 145  ; EXP reward
    db 3  ; Joinability (3)
    db 14  ; Level
    dw 84, 52, 76, 35, 30, 26  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 200, 100  ; AI weights
    db $1C, $20, $FF, $FF  ; Skills: Sap, Slow, none, none

; --- EID 46 (0x2e): DrakSlime Lv14 ---
EnemyStats_046:
    db 0  ; Species: DrakSlime
    dw 153  ; EXP reward
    db 3  ; Joinability (3)
    db 14  ; Level
    dw 75, 26, 58, 32, 96, 52  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 100, 200, 100  ; AI weights
    db $43, $5D, $FF, $FF  ; Skills: SuckAir, BlazeAir, none, none

; --- EID 47 (0x2f): FairyDrak Lv14 ---
EnemyStats_047:
    db 24  ; Species: FairyDrak
    dw 168  ; EXP reward
    db 3  ; Joinability (3)
    db 14  ; Level
    dw 66, 51, 53, 33, 51, 27  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 100, 150, 100  ; AI weights
    db $18, $6A, $FF, $FF  ; Skills: Surround, SleepAir, none, none

; --- EID 48 (0x30): Skullroo Lv15 ---
EnemyStats_048:
    db 51  ; Species: Skullroo
    dw 170  ; EXP reward
    db 3  ; Joinability (3)
    db 15  ; Level
    dw 95, 24, 79, 31, 57, 55  ; HP, MP, ATK, DEF, AGL, INT
    db 50, 50, 50, 100  ; AI weights
    db $41, $6E, $FF, $FF  ; Skills: ChargeUP, PaniDance, none, none

; --- EID 49 (0x31): Butterfly Lv15 ---
EnemyStats_049:
    db 113  ; Species: Butterfly
    dw 176  ; EXP reward
    db 2  ; Joinability (2)
    db 15  ; Level
    dw 68, 57, 59, 36, 78, 28  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 150, 100  ; AI weights
    db $18, $6F, $FF, $FF  ; Skills: Surround, Curse, none, none

; --- EID 50 (0x32): MadRaven Lv17 ---
EnemyStats_050:
    db 76  ; Species: MadRaven
    dw 190  ; EXP reward
    db 3  ; Joinability (3)
    db 17  ; Level
    dw 73, 55, 67, 49, 80, 85  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 150, 100  ; AI weights
    db $42, $8A, $FF, $FF  ; Skills: HighJump, TailWind, none, none

; --- EID 51 (0x33): MadCat Lv12 ---
EnemyStats_051:
    db 68  ; Species: MadCat
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 12  ; Level
    dw 200, 30, 63, 35, 63, 35  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 200, 100  ; AI weights
    db $46, $55, $7B, $FF  ; Skills: VacuSlash, SquallHit, LegSweep, none

; --- EID 52 (0x34): MadCat Lv12 ---
EnemyStats_052:
    db 68  ; Species: MadCat
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 12  ; Level
    dw 80, 30, 63, 50, 63, 35  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 200, 100  ; AI weights
    db $46, $55, $7B, $FF  ; Skills: VacuSlash, SquallHit, LegSweep, none

; --- EID 53 (0x35): FaceTree Lv12 ---
EnemyStats_053:
    db 102  ; Species: FaceTree
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 12  ; Level
    dw 400, 100, 60, 30, 38, 55  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 200, 100  ; AI weights
    db $17, $6F, $75, $FF  ; Skills: StopSpell, Curse, OddDance, none

; --- EID 54 (0x36): FaceTree Lv12 ---
EnemyStats_054:
    db 102  ; Species: FaceTree
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 12  ; Level
    dw 100, 100, 45, 50, 38, 55  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 150, 200, 100  ; AI weights
    db $17, $6F, $75, $FF  ; Skills: StopSpell, Curse, OddDance, none

; --- EID 55 (0x37): MadKnight Lv12 ---
EnemyStats_055:
    db 149  ; Species: MadKnight
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 12  ; Level
    dw 300, 60, 77, 60, 40, 50  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 200, 100  ; AI weights
    db $3F, $4A, $FF, $FF  ; Skills: Massacre, BeastCut, none, none

; --- EID 56 (0x38): MadKnight Lv12 ---
EnemyStats_056:
    db 149  ; Species: MadKnight
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 12  ; Level
    dw 85, 60, 77, 75, 40, 50  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 200, 50  ; AI weights
    db $3F, $4A, $FF, $FF  ; Skills: Massacre, BeastCut, none, none

; --- EID 57 (0x39): Mudron Lv16 ---
EnemyStats_057:
    db 164  ; Species: Mudron
    dw 284  ; EXP reward
    db 3  ; Joinability (3)
    db 16  ; Level
    dw 78, 40, 58, 46, 34, 70  ; HP, MP, ATK, DEF, AGL, INT
    db 50, 200, 250, 50  ; AI weights
    db $12, $2B, $FF, $FF  ; Skills: Beat, Heal, none, none

; --- EID 58 (0x3a): Facer Lv16 ---
EnemyStats_058:
    db 179  ; Species: Facer
    dw 282  ; EXP reward
    db 3  ; Joinability (3)
    db 16  ; Level
    dw 64, 113, 49, 34, 95, 110  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 100, 50  ; AI weights
    db $0A, $95, $FF, $FF  ; Skills: Infermore, LifeSong, none, none

; --- EID 59 (0x3b): Snaily Lv16 ---
EnemyStats_059:
    db 4  ; Species: Snaily
    dw 290  ; EXP reward
    db 2  ; Joinability (2)
    db 16  ; Level
    dw 67, 30, 65, 115, 110, 60  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 50, 50  ; AI weights
    db $0C, $52, $FF, $FF  ; Skills: IceBolt, CallHelp, none, none

; --- EID 60 (0x3c): Saccer Lv17 ---
EnemyStats_060:
    db 49  ; Species: Saccer
    dw 246  ; EXP reward
    db 3  ; Joinability (3)
    db 17  ; Level
    dw 95, 61, 88, 129, 35, 62  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 150, 50  ; AI weights
    db $1E, $56, $FF, $FF  ; Skills: Upper, PsycheUp, none, none

; --- EID 61 (0x3d): MadPecker Lv22 ---
EnemyStats_061:
    db 75  ; Species: MadPecker
    dw 322  ; EXP reward
    db 3  ; Joinability (3)
    db 22  ; Level
    dw 68, 32, 126, 70, 122, 61  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 150, 50  ; AI weights
    db $0A, $1C, $FF, $FF  ; Skills: Infermore, Sap, none, none

; --- EID 62 (0x3e): Gulpple Lv17 ---
EnemyStats_062:
    db 95  ; Species: Gulpple
    dw 288  ; EXP reward
    db 3  ; Joinability (3)
    db 17  ; Level
    dw 96, 82, 75, 100, 66, 74  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 150, 50  ; AI weights
    db $0A, $68, $FF, $FF  ; Skills: Infermore, NapAttack, none, none

; --- EID 63 (0x3f): EyeBall Lv18 ---
EnemyStats_063:
    db 135  ; Species: EyeBall
    dw 320  ; EXP reward
    db 3  ; Joinability (3)
    db 18  ; Level
    dw 98, 67, 76, 72, 69, 68  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 250, 50  ; AI weights
    db $27, $7D, $FF, $FF  ; Skills: MagicBack, WarCry, none, none

; --- EID 64 (0x40): Mummy Lv18 ---
EnemyStats_064:
    db 159  ; Species: Mummy
    dw 342  ; EXP reward
    db 3  ; Joinability (3)
    db 18  ; Level
    dw 130, 68, 77, 55, 42, 38  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 150, 50  ; AI weights
    db $40, $52, $69, $FF  ; Skills: EvilSlash, CallHelp, Paralyze, none

; --- EID 65 (0x41): Babble Lv18 ---
EnemyStats_065:
    db 6  ; Species: Babble
    dw 312  ; EXP reward
    db 3  ; Joinability (3)
    db 18  ; Level
    dw 82, 35, 80, 44, 120, 60  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 100, 150, 50  ; AI weights
    db $18, $67, $FF, $FF  ; Skills: Surround, PoisonHit, none, none

; --- EID 66 (0x42): Pteranod Lv19 ---
EnemyStats_066:
    db 22  ; Species: Pteranod
    dw 406  ; EXP reward
    db 3  ; Joinability (3)
    db 19  ; Level
    dw 140, 40, 103, 70, 123, 80  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 150, 50  ; AI weights
    db $03, $58, $8A, $FF  ; Skills: Firebal, WindBeast, TailWind, none

; --- EID 67 (0x43): Tonguella Lv19 ---
EnemyStats_067:
    db 45  ; Species: Tonguella
    dw 356  ; EXP reward
    db 3  ; Joinability (3)
    db 19  ; Level
    dw 108, 62, 90, 61, 45, 40  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 200, 50  ; AI weights
    db $68, $79, $FF, $FF  ; Skills: NapAttack, LushLicks, none, none

; --- EID 68 (0x44): Florajay Lv19 ---
EnemyStats_068:
    db 73  ; Species: Florajay
    dw 259  ; EXP reward
    db 3  ; Joinability (3)
    db 19  ; Level
    dw 75, 86, 65, 42, 142, 120  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 150, 150, 50  ; AI weights
    db $23, $4A, $95, $FF  ; Skills: SpeedUp, BeastCut, LifeSong, none

; --- EID 69 (0x45): MadPlant Lv20 ---
EnemyStats_069:
    db 90  ; Species: MadPlant
    dw 374  ; EXP reward
    db 3  ; Joinability (3)
    db 20  ; Level
    dw 116, 140, 72, 50, 135, 91  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 100, 250, 50  ; AI weights
    db $1C, $20, $34, $FF  ; Skills: Sap, Slow, NumbOff, none

; --- EID 70 (0x46): ArmorPede Lv24 ---
EnemyStats_070:
    db 121  ; Species: ArmorPede
    dw 450  ; EXP reward
    db 4  ; Joinability (4)
    db 24  ; Level
    dw 125, 37, 119, 127, 50, 68  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 200, 50  ; AI weights
    db $1E, $25, $3B, $FF  ; Skills: Upper, TwinHits, TwinSlash, none

; --- EID 71 (0x47): MedusaEye Lv18 ---
EnemyStats_071:
    db 140  ; Species: MedusaEye
    dw 305  ; EXP reward
    db 4  ; Joinability (4)
    db 18  ; Level
    dw 82, 68, 66, 96, 88, 64  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 50, 100, 50  ; AI weights
    db $18, $1C, $D8, $FF  ; Skills: Surround, Sap, Branching, none

; --- EID 72 (0x48): MadCandle Lv21 ---
EnemyStats_072:
    db 177  ; Species: MadCandle
    dw 522  ; EXP reward
    db 3  ; Joinability (3)
    db 21  ; Level
    dw 95, 38, 100, 135, 91, 67  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 150, 50  ; AI weights
    db $01, $56, $FF, $FF  ; Skills: Blazemore, PsycheUp, none, none

; --- EID 73 (0x49): WingSlime Lv21 ---
EnemyStats_073:
    db 2  ; Species: WingSlime
    dw 358  ; EXP reward
    db 4  ; Joinability (4)
    db 21  ; Level
    dw 76, 68, 66, 44, 150, 68  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 50, 100, 50  ; AI weights
    db $55, $58, $8A, $FF  ; Skills: SquallHit, WindBeast, TailWind, none

; --- EID 74 (0x4a): MadGopher Lv21 ---
EnemyStats_074:
    db 60  ; Species: MadGopher
    dw 410  ; EXP reward
    db 3  ; Joinability (3)
    db 21  ; Level
    dw 106, 68, 97, 45, 54, 48  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 150, 200, 50  ; AI weights
    db $41, $4B, $4D, $FF  ; Skills: ChargeUP, BirdBlow, ZombieCut, none

; --- EID 75 (0x4b): FangSlime Lv20 ---
EnemyStats_075:
    db 10  ; Species: FangSlime
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 20  ; Level
    dw 400, 40, 87, 50, 80, 65  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 150, 0  ; AI weights
    db $41, $52, $7D, $FF  ; Skills: ChargeUP, CallHelp, WarCry, none

; --- EID 76 (0x4c): FangSlime Lv20 ---
EnemyStats_076:
    db 10  ; Species: FangSlime
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 20  ; Level
    dw 70, 40, 85, 52, 90, 65  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 200, 200, 50  ; AI weights
    db $41, $52, $7D, $FF  ; Skills: ChargeUP, CallHelp, WarCry, none

; --- EID 77 (0x4d): BigEye Lv20 ---
EnemyStats_077:
    db 69  ; Species: BigEye
    dw 1500  ; EXP reward
    db 7  ; Joinability (never)
    db 20  ; Level
    dw 500, 40, 80, 40, 62, 80  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 150, 150, 50  ; AI weights
    db $0D, $2B, $61, $FF  ; Skills: SnowStorm, Heal, IceAir, none

; --- EID 78 (0x4e): BigEye Lv20 ---
EnemyStats_078:
    db 69  ; Species: BigEye
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 20  ; Level
    dw 80, 57, 80, 48, 62, 80  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 200, 100, 50  ; AI weights
    db $0D, $2B, $61, $FF  ; Skills: SnowStorm, Heal, IceAir, none

; --- EID 79 (0x4f): Gigantes Lv14 ---
EnemyStats_079:
    db 150  ; Species: Gigantes
    dw 1700  ; EXP reward
    db 6  ; Joinability (6)
    db 14  ; Level
    dw 600, 10, 130, 30, 68, 15  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 50  ; AI weights
    db $40, $41, $4D, $FF  ; Skills: EvilSlash, ChargeUP, ZombieCut, none

; --- EID 80 (0x50): Gigantes Lv14 ---
EnemyStats_080:
    db 150  ; Species: Gigantes
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 14  ; Level
    dw 150, 10, 130, 46, 48, 15  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 50  ; AI weights
    db $40, $41, $4D, $FF  ; Skills: EvilSlash, ChargeUP, ZombieCut, none

; --- EID 81 (0x51): Slabbit Lv22 ---
EnemyStats_081:
    db 13  ; Species: Slabbit
    dw 475  ; EXP reward
    db 3  ; Joinability (3)
    db 22  ; Level
    dw 130, 40, 91, 60, 162, 105  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 100, 150, 0  ; AI weights
    db $77, $7C, $FF, $FF  ; Skills: SideStep, BigTrip, none, none

; --- EID 82 (0x52): Gasgon Lv22 ---
EnemyStats_082:
    db 23  ; Species: Gasgon
    dw 510  ; EXP reward
    db 4  ; Joinability (4)
    db 22  ; Level
    dw 141, 111, 113, 59, 30, 73  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 250, 100, 0  ; AI weights
    db $32, $3D, $FF, $FF  ; Skills: Farewell, Beserker, none, none

; --- EID 83 (0x53): WindBeast Lv22 ---
EnemyStats_083:
    db 52  ; Species: WindBeast
    dw 480  ; EXP reward
    db 3  ; Joinability (3)
    db 22  ; Level
    dw 110, 132, 78, 81, 130, 105  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 150, 200, 0  ; AI weights
    db $0A, $0C, $46, $FF  ; Skills: Infermore, IceBolt, VacuSlash, none

; --- EID 84 (0x54): StubBird Lv23 ---
EnemyStats_084:
    db 80  ; Species: StubBird
    dw 588  ; EXP reward
    db 4  ; Joinability (4)
    db 23  ; Level
    dw 91, 84, 170, 140, 90, 82  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 200, 0  ; AI weights
    db $25, $57, $D7, $FF  ; Skills: TwinHits, RainSlash, Sheldodge, none

; --- EID 85 (0x55): Oniono Lv23 ---
EnemyStats_085:
    db 99  ; Species: Oniono
    dw 500  ; EXP reward
    db 3  ; Joinability (3)
    db 23  ; Level
    dw 100, 110, 95, 50, 126, 143  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 100, 200, 0  ; AI weights
    db $1A, $41, $6A, $FF  ; Skills: RobMagic, ChargeUP, SleepAir, none

; --- EID 86 (0x56): Gophecada Lv23 ---
EnemyStats_086:
    db 112  ; Species: Gophecada
    dw 490  ; EXP reward
    db 3  ; Joinability (3)
    db 23  ; Level
    dw 172, 55, 95, 112, 54, 43  ; HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0  ; AI weights
    db $12, $27, $52, $FF  ; Skills: Beat, MagicBack, CallHelp, none

; --- EID 87 (0x57): Pixy Lv24 ---
EnemyStats_087:
    db 130  ; Species: Pixy
    dw 518  ; EXP reward
    db 3  ; Joinability (3)
    db 24  ; Level
    dw 90, 46, 102, 68, 80, 62  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 100, 150, 0  ; AI weights
    db $23, $25, $33, $FF  ; Skills: SpeedUp, TwinHits, Antidote, none

; --- EID 88 (0x58): DeadNite Lv24 ---
EnemyStats_088:
    db 161  ; Species: DeadNite
    dw 630  ; EXP reward
    db 4  ; Joinability (4)
    db 24  ; Level
    dw 121, 87, 140, 99, 105, 92  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 200, 200, 0  ; AI weights
    db $2B, $35, $36, $FF  ; Skills: Heal, DeChaos, CurseOff, none

; --- EID 89 (0x59): SpikyBoy Lv24 ---
EnemyStats_089:
    db 180  ; Species: SpikyBoy
    dw 560  ; EXP reward
    db 3  ; Joinability (3)
    db 24  ; Level
    dw 93, 46, 100, 93, 50, 63  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 150, 0  ; AI weights
    db $14, $42, $D6, $FF  ; Skills: Sacrifice, HighJump, Smashlime, none

; --- EID 90 (0x5a): SlimeNite Lv25 ---
EnemyStats_090:
    db 5  ; Species: SlimeNite
    dw 585  ; EXP reward
    db 4  ; Joinability (4)
    db 25  ; Level
    dw 144, 47, 136, 102, 152, 96  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 150, 150, 0  ; AI weights
    db $1F, $2B, $4A, $FF  ; Skills: Increase, Heal, BeastCut, none

; --- EID 91 (0x5b): KingCobra Lv25 ---
EnemyStats_091:
    db 35  ; Species: KingCobra
    dw 660  ; EXP reward
    db 3  ; Joinability (3)
    db 25  ; Level
    dw 126, 46, 95, 82, 130, 47  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 100, 0  ; AI weights
    db $67, $6F, $FF, $FF  ; Skills: PoisonHit, Curse, none, none

; --- EID 92 (0x5c): Mommonja Lv25 ---
EnemyStats_092:
    db 56  ; Species: Mommonja
    dw 600  ; EXP reward
    db 4  ; Joinability (4)
    db 25  ; Level
    dw 125, 66, 85, 80, 135, 170  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 150, 200, 0  ; AI weights
    db $0D, $78, $92, $FF  ; Skills: SnowStorm, LureDance, MouthShut, none

; --- EID 93 (0x5d): MistyWing Lv26 ---
EnemyStats_093:
    db 77  ; Species: MistyWing
    dw 573  ; EXP reward
    db 3  ; Joinability (3)
    db 26  ; Level
    dw 131, 94, 105, 105, 132, 100  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 100, 150, 0  ; AI weights
    db $18, $24, $74, $FF  ; Skills: Surround, Barrier, EerieLite, none

; --- EID 94 (0x5e): StagBug Lv26 ---
EnemyStats_094:
    db 117  ; Species: StagBug
    dw 640  ; EXP reward
    db 3  ; Joinability (3)
    db 26  ; Level
    dw 106, 49, 141, 155, 96, 49  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 200, 0  ; AI weights
    db $15, $5D, $7B, $FF  ; Skills: Sleep, BlazeAir, LegSweep, none

; --- EID 95 (0x5f): DarkEye Lv20 ---
EnemyStats_095:
    db 134  ; Species: DarkEye
    dw 720  ; EXP reward
    db 4  ; Joinability (4)
    db 20  ; Level
    dw 97, 133, 77, 95, 105, 102  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 0, 150, 0  ; AI weights
    db $48, $6B, $73, $FF  ; Skills: MetalCut, PalsyAir, Radiant, none

; --- EID 96 (0x60): NiteWhip Lv27 ---
EnemyStats_096:
    db 165  ; Species: NiteWhip
    dw 666  ; EXP reward
    db 3  ; Joinability (3)
    db 27  ; Level
    dw 101, 74, 58, 135, 140, 111  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 150, 0  ; AI weights
    db $58, $5A, $5D, $FF  ; Skills: WindBeast, Lightning, BlazeAir, none

; --- EID 97 (0x61): RogueNite Lv27 ---
EnemyStats_097:
    db 182  ; Species: RogueNite
    dw 780  ; EXP reward
    db 3  ; Joinability (3)
    db 27  ; Level
    dw 160, 38, 166, 200, 75, 79  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 150, 0  ; AI weights
    db $2B, $40, $48, $FF  ; Skills: Heal, EvilSlash, MetalCut, none

; --- EID 98 (0x62): BoxSlime Lv27 ---
EnemyStats_098:
    db 7  ; Species: BoxSlime
    dw 740  ; EXP reward
    db 4  ; Joinability (4)
    db 27  ; Level
    dw 102, 49, 112, 82, 145, 76  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 50, 150, 0  ; AI weights
    db $01, $1E, $3C, $FF  ; Skills: Blazemore, Upper, Ramming, none

; --- EID 99 (0x63): StoneMan Lv20 ---
EnemyStats_099:
    db 197  ; Species: StoneMan
    dw 6400  ; EXP reward
    db 7  ; Joinability (never)
    db 20  ; Level
    dw 800, 36, 130, 90, 45, 90  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 100, 50, 0  ; AI weights
    db $88, $8F, $FF, $FF  ; Skills: Cover, SuckAll, none, none

; --- EID 100 (0x64): StoneMan Lv20 ---
EnemyStats_100:
    db 197  ; Species: StoneMan
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 20  ; Level
    dw 170, 36, 130, 110, 45, 90  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 50, 0  ; AI weights
    db $88, $8F, $FF, $FF  ; Skills: Cover, SuckAll, none, none

; --- EID 101 (0x65): BattleRex Lv20 ---
EnemyStats_101:
    db 42  ; Species: BattleRex
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 20  ; Level
    dw 1000, 50, 170, 80, 80, 70  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 100, 150, 0  ; AI weights
    db $48, $5D, $FF, $FF  ; Skills: MetalCut, BlazeAir, none, none

; --- EID 102 (0x66): BattleRex Lv20 ---
EnemyStats_102:
    db 42  ; Species: BattleRex
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 20  ; Level
    dw 165, 90, 140, 80, 100, 70  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 150, 0  ; AI weights
    db $48, $5D, $FF, $FF  ; Skills: MetalCut, BlazeAir, none, none

; --- EID 103 (0x67): Copycat Lv20 ---
EnemyStats_103:
    db 174  ; Species: Copycat
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 20  ; Level
    dw 800, 48, 95, 70, 60, 60  ; HP, MP, ATK, DEF, AGL, INT
    db 50, 50, 250, 0  ; AI weights
    db $29, $76, $7F, $FF  ; Skills: Transform, RobDance, Imitate, none

; --- EID 104 (0x68): Copycat Lv20 ---
EnemyStats_104:
    db 174  ; Species: Copycat
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 20  ; Level
    dw 80, 48, 100, 85, 60, 60  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 250, 0  ; AI weights
    db $29, $76, $7F, $FF  ; Skills: Transform, RobDance, Imitate, none

; --- EID 105 (0x69): Orc Lv28 ---
EnemyStats_105:
    db 143  ; Species: Orc
    dw 710  ; EXP reward
    db 3  ; Joinability (3)
    db 28  ; Level
    dw 160, 40, 130, 88, 86, 140  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 100, 0  ; AI weights
    db $1C, $4B, $FF, $FF  ; Skills: Sap, BirdBlow, none, none

; --- EID 106 (0x6a): Reaper Lv28 ---
EnemyStats_106:
    db 168  ; Species: Reaper
    dw 750  ; EXP reward
    db 4  ; Joinability (4)
    db 28  ; Level
    dw 110, 135, 156, 40, 130, 170  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 250, 0  ; AI weights
    db $4C, $6F, $74, $FF  ; Skills: DevilCut, Curse, EerieLite, none

; --- EID 107 (0x6b): Gismo Lv28 ---
EnemyStats_107:
    db 191  ; Species: Gismo
    dw 700  ; EXP reward
    db 4  ; Joinability (4)
    db 28  ; Level
    dw 152, 52, 81, 120, 142, 142  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 150, 150, 0  ; AI weights
    db $43, $5D, $61, $FF  ; Skills: SuckAir, BlazeAir, IceAir, none

; --- EID 108 (0x6c): RockSlime Lv29 ---
EnemyStats_108:
    db 11  ; Species: RockSlime
    dw 830  ; EXP reward
    db 4  ; Joinability (4)
    db 29  ; Level
    dw 186, 9, 140, 138, 89, 55  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 200, 150, 0  ; AI weights
    db $42, $5B, $8E, $FF  ; Skills: HighJump, RockThrow, StrongD, none

; --- EID 109 (0x6d): Chamelgon Lv29 ---
EnemyStats_109:
    db 32  ; Species: Chamelgon
    dw 776  ; EXP reward
    db 4  ; Joinability (4)
    db 29  ; Level
    dw 160, 149, 90, 88, 138, 85  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 200, 0  ; AI weights
    db $19, $69, $FF, $FF  ; Skills: PanicAll, Paralyze, none, none

; --- EID 110 (0x6e): Goategon Lv29 ---
EnemyStats_110:
    db 63  ; Species: Goategon
    dw 910  ; EXP reward
    db 4  ; Joinability (4)
    db 29  ; Level
    dw 220, 120, 172, 92, 131, 132  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 200, 0  ; AI weights
    db $04, $21, $6A, $FF  ; Skills: Firebane, SlowAll, SleepAir, none

; --- EID 111 (0x6f): DuckKite Lv28 ---
EnemyStats_111:
    db 74  ; Species: DuckKite
    dw 882  ; EXP reward
    db 3  ; Joinability (3)
    db 28  ; Level
    dw 117, 115, 143, 138, 165, 140  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 100, 0  ; AI weights
    db $15, $19, $6F, $FF  ; Skills: Sleep, PanicAll, Curse, none

; --- EID 112 (0x70): CactiBall Lv28 ---
EnemyStats_112:
    db 94  ; Species: CactiBall
    dw 977  ; EXP reward
    db 3  ; Joinability (3)
    db 28  ; Level
    dw 192, 165, 140, 65, 135, 130  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 150, 250, 0  ; AI weights
    db $42, $69, $75, $FF  ; Skills: HighJump, Paralyze, OddDance, none

; --- EID 113 (0x71): TailEater Lv30 ---
EnemyStats_113:
    db 120  ; Species: TailEater
    dw 960  ; EXP reward
    db 4  ; Joinability (4)
    db 30  ; Level
    dw 160, 58, 116, 90, 121, 88  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 150, 0  ; AI weights
    db $47, $6C, $73, $FF  ; Skills: IceSlash, PoisonGas, Radiant, none

; --- EID 114 (0x72): AgDevil Lv31 ---
EnemyStats_114:
    db 132  ; Species: AgDevil
    dw 1005  ; EXP reward
    db 4  ; Joinability (4)
    db 31  ; Level
    dw 160, 90, 148, 125, 90, 142  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 150, 0  ; AI weights
    db $04, $6A, $FF, $FF  ; Skills: Firebane, SleepAir, none, none

; --- EID 115 (0x73): WindMerge Lv31 ---
EnemyStats_115:
    db 167  ; Species: WindMerge
    dw 1100  ; EXP reward
    db 4  ; Joinability (4)
    db 31  ; Level
    dw 116, 142, 98, 176, 122, 165  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 100, 200, 0  ; AI weights
    db $0B, $24, $36, $FF  ; Skills: Infermost, Barrier, CurseOff, none

; --- EID 116 (0x74): WeedBug Lv31 ---
EnemyStats_116:
    db 114  ; Species: WeedBug
    dw 957  ; EXP reward
    db 4  ; Joinability (4)
    db 31  ; Level
    dw 143, 90, 65, 140, 90, 141  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 150, 200, 0  ; AI weights
    db $1A, $24, $26, $FF  ; Skills: RobMagic, Barrier, MagicWall, none

; --- EID 117 (0x75): SpotKing Lv32 ---
EnemyStats_117:
    db 14  ; Species: SpotKing
    dw 1200  ; EXP reward
    db 5  ; Joinability (standard)
    db 32  ; Level
    dw 300, 62, 206, 99, 115, 170  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 150, 150, 0  ; AI weights
    db $4E, $68, $92, $FF  ; Skills: CleanCut, NapAttack, MouthShut, none

; --- EID 118 (0x76): LizardFly Lv28 ---
EnemyStats_118:
    db 33  ; Species: LizardFly
    dw 990  ; EXP reward
    db 4  ; Joinability (4)
    db 28  ; Level
    dw 120, 93, 188, 99, 93, 90  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 150, 0  ; AI weights
    db $04, $58, $5D, $FF  ; Skills: Firebane, WindBeast, BlazeAir, none

; --- EID 119 (0x77): HammerMan Lv32 ---
EnemyStats_119:
    db 57  ; Species: HammerMan
    dw 1035  ; EXP reward
    db 4  ; Joinability (4)
    db 32  ; Level
    dw 136, 60, 156, 100, 118, 62  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 50, 0  ; AI weights
    db $3E, $40, $41, $FF  ; Skills: Kamikaze, EvilSlash, ChargeUP, none

; --- EID 120 (0x78): MadGoose Lv28 ---
EnemyStats_120:
    db 82  ; Species: MadGoose
    dw 983  ; EXP reward
    db 4  ; Joinability (4)
    db 28  ; Level
    dw 180, 197, 167, 190, 180, 96  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 100, 200, 0  ; AI weights
    db $19, $75, $78, $FF  ; Skills: PanicAll, OddDance, LureDance, none

; --- EID 121 (0x79): TreeBoy Lv33 ---
EnemyStats_121:
    db 101  ; Species: TreeBoy
    dw 1095  ; EXP reward
    db 4  ; Joinability (4)
    db 33  ; Level
    dw 213, 185, 104, 100, 156, 185  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 200, 200, 0  ; AI weights
    db $0D, $2C, $36, $FF  ; Skills: SnowStorm, HealMore, CurseOff, none

; --- EID 122 (0x7a): Droll Lv33 ---
EnemyStats_122:
    db 124  ; Species: Droll
    dw 1152  ; EXP reward
    db 4  ; Joinability (4)
    db 33  ; Level
    dw 132, 40, 142, 100, 68, 126  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 0, 100, 0  ; AI weights
    db $21, $D8, $FF, $FF  ; Skills: SlowAll, Branching, none, none

; --- EID 123 (0x7b): FunkyBird Lv30 ---
EnemyStats_123:
    db 88  ; Species: FunkyBird
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 30  ; Level
    dw 1200, 160, 100, 140, 98, 160  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 150, 0  ; AI weights
    db $6E, $94, $96, $FF  ; Skills: PaniDance, Hustle, LifeDance, none

; --- EID 124 (0x7c): FunkyBird Lv30 ---
EnemyStats_124:
    db 88  ; Species: FunkyBird
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 30  ; Level
    dw 120, 160, 100, 140, 98, 160  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 250, 0  ; AI weights
    db $6E, $94, $96, $FF  ; Skills: PaniDance, Hustle, LifeDance, none

; --- EID 125 (0x7d): SkyDragon Lv30 ---
EnemyStats_125:
    db 43  ; Species: SkyDragon
    dw 7800  ; EXP reward
    db 7  ; Joinability (never)
    db 30  ; Level
    dw 1200, 150, 170, 120, 80, 80  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 200, 0  ; AI weights
    db $43, $5E, $FF, $FF  ; Skills: SuckAir, Scorching, none, none

; --- EID 126 (0x7e): SkyDragon Lv30 ---
EnemyStats_126:
    db 43  ; Species: SkyDragon
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 30  ; Level
    dw 125, 150, 170, 155, 80, 80  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 200, 0  ; AI weights
    db $43, $5E, $FF, $FF  ; Skills: SuckAir, Scorching, none, none

; --- EID 127 (0x7f): Digster Lv45 ---
EnemyStats_127:
    db 129  ; Species: Digster
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 45  ; Level
    dw 1000, 85, 190, 150, 60, 140  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 0, 150, 0  ; AI weights
    db $8E, $8F, $FF, $FF  ; Skills: StrongD, SuckAll, none, none

; --- EID 128 (0x80): Digster Lv45 ---
EnemyStats_128:
    db 129  ; Species: Digster
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 45  ; Level
    dw 230, 85, 190, 160, 60, 140  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 200, 150, 0  ; AI weights
    db $8E, $8F, $FF, $FF  ; Skills: StrongD, SuckAll, none, none

; --- EID 129 (0x81): GiantMoth Lv28 ---
EnemyStats_129:
    db 123  ; Species: GiantMoth
    dw 1187  ; EXP reward
    db 4  ; Joinability (4)
    db 28  ; Level
    dw 155, 165, 155, 168, 186, 162  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 200, 0  ; AI weights
    db $58, $69, $73, $FF  ; Skills: WindBeast, Paralyze, Radiant, none

; --- EID 130 (0x82): ArcDemon Lv34 ---
EnemyStats_130:
    db 131  ; Species: ArcDemon
    dw 1720  ; EXP reward
    db 5  ; Joinability (standard)
    db 34  ; Level
    dw 230, 98, 230, 180, 72, 250  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 150, 0  ; AI weights
    db $07, $45, $4B, $FF  ; Skills: Boom, BoltSlash, BirdBlow, none

; --- EID 131 (0x83): MadSpirit Lv34 ---
EnemyStats_131:
    db 166  ; Species: MadSpirit
    dw 1368  ; EXP reward
    db 5  ; Joinability (standard)
    db 34  ; Level
    dw 160, 162, 203, 168, 100, 66  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 250, 0  ; AI weights
    db $6A, $73, $83, $FF  ; Skills: SleepAir, Radiant, ThickFog, none

; --- EID 132 (0x84): CurseLamp Lv40 ---
EnemyStats_132:
    db 188  ; Species: CurseLamp
    dw 1213  ; EXP reward
    db 4  ; Joinability (4)
    db 40  ; Level
    dw 200, 204, 182, 180, 102, 200  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 200, 0  ; AI weights
    db $1F, $23, $25, $FF  ; Skills: Increase, SpeedUp, TwinHits, none

; --- EID 133 (0x85): Tortragon Lv33 ---
EnemyStats_133:
    db 21  ; Species: Tortragon
    dw 1305  ; EXP reward
    db 4  ; Joinability (4)
    db 33  ; Level
    dw 162, 104, 212, 250, 72, 104  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 100, 100, 0  ; AI weights
    db $28, $5A, $FF, $FF  ; Skills: Bounce, Lightning, none, none

; --- EID 134 (0x86): WildApe Lv33 ---
EnemyStats_134:
    db 64  ; Species: WildApe
    dw 1250  ; EXP reward
    db 4  ; Joinability (4)
    db 33  ; Level
    dw 160, 68, 195, 75, 158, 100  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 150, 0  ; AI weights
    db $3B, $53, $7C, $FF  ; Skills: TwinSlash, YellHelp, BigTrip, none

; --- EID 135 (0x87): LandOwl Lv33 ---
EnemyStats_135:
    db 81  ; Species: LandOwl
    dw 1528  ; EXP reward
    db 5  ; Joinability (standard)
    db 33  ; Level
    dw 240, 71, 260, 110, 110, 70  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 150, 0  ; AI weights
    db $0B, $45, $77, $FF  ; Skills: Infermost, BoltSlash, SideStep, none

; --- EID 136 (0x88): AmberWeed Lv36 ---
EnemyStats_136:
    db 97  ; Species: AmberWeed
    dw 1138  ; EXP reward
    db 4  ; Joinability (4)
    db 36  ; Level
    dw 180, 192, 115, 140, 180, 70  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 250, 0  ; AI weights
    db $24, $25, $26, $FF  ; Skills: Barrier, TwinHits, MagicWall, none

; --- EID 137 (0x89): ArmyCrab Lv36 ---
EnemyStats_137:
    db 125  ; Species: ArmyCrab
    dw 1299  ; EXP reward
    db 5  ; Joinability (standard)
    db 36  ; Level
    dw 130, 108, 160, 230, 55, 72  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 200, 0  ; AI weights
    db $1F, $48, $53, $FF  ; Skills: Increase, MetalCut, YellHelp, none

; --- EID 138 (0x8a): EvilBeast Lv30 ---
EnemyStats_138:
    db 137  ; Species: EvilBeast
    dw 1203  ; EXP reward
    db 5  ; Joinability (standard)
    db 30  ; Level
    dw 150, 71, 202, 162, 56, 186  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 200, 0  ; AI weights
    db $04, $61, $FF, $FF  ; Skills: Firebane, IceAir, none, none

; --- EID 139 (0x8b): Shadow Lv37 ---
EnemyStats_139:
    db 162  ; Species: Shadow
    dw 1256  ; EXP reward
    db 5  ; Joinability (standard)
    db 37  ; Level
    dw 217, 134, 210, 210, 118, 185  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 250, 0  ; AI weights
    db $61, $71, $83, $FF  ; Skills: IceAir, K.O.Dance, ThickFog, none

; --- EID 140 (0x8c): EvilWand Lv37 ---
EnemyStats_140:
    db 176  ; Species: EvilWand
    dw 1343  ; EXP reward
    db 4  ; Joinability (4)
    db 37  ; Level
    dw 172, 130, 167, 230, 190, 100  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 150, 0  ; AI weights
    db $35, $61, $FF, $FF  ; Skills: DeChaos, IceAir, none, none

; --- EID 141 (0x8d): SlimeBorg Lv38 ---
EnemyStats_141:
    db 12  ; Species: SlimeBorg
    dw 1444  ; EXP reward
    db 5  ; Joinability (standard)
    db 38  ; Level
    dw 250, 73, 205, 192, 200, 100  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 200, 200, 0  ; AI weights
    db $57, $5A, $90, $FF  ; Skills: RainSlash, Lightning, BladeD, none

; --- EID 142 (0x8e): LizardMan Lv38 ---
EnemyStats_142:
    db 25  ; Species: LizardMan
    dw 1347  ; EXP reward
    db 4  ; Joinability (4)
    db 38  ; Level
    dw 210, 73, 182, 110, 105, 100  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 100, 50, 0  ; AI weights
    db $40, $4A, $FF, $FF  ; Skills: EvilSlash, BeastCut, none, none

; --- EID 143 (0x8f): Grizzly Lv38 ---
EnemyStats_143:
    db 58  ; Species: Grizzly
    dw 1560  ; EXP reward
    db 5  ; Joinability (standard)
    db 38  ; Level
    dw 230, 18, 285, 82, 200, 80  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 150, 0  ; AI weights
    db $3B, $55, $7C, $FF  ; Skills: TwinSlash, SquallHit, BigTrip, none

; --- EID 144 (0x90): Wyvern Lv39 ---
EnemyStats_144:
    db 71  ; Species: Wyvern
    dw 1580  ; EXP reward
    db 4  ; Joinability (4)
    db 39  ; Level
    dw 193, 105, 165, 130, 160, 205  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 150, 0  ; AI weights
    db $16, $2C, $61, $FF  ; Skills: SleepAll, HealMore, IceAir, none

; --- EID 145 (0x91): FireWeed Lv36 ---
EnemyStats_145:
    db 91  ; Species: FireWeed
    dw 1440  ; EXP reward
    db 4  ; Joinability (4)
    db 36  ; Level
    dw 180, 200, 83, 128, 155, 147  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 150, 200, 0  ; AI weights
    db $01, $35, $6B, $FF  ; Skills: Blazemore, DeChaos, PalsyAir, none

; --- EID 146 (0x92): MadHornet Lv38 ---
EnemyStats_146:
    db 126  ; Species: MadHornet
    dw 1380  ; EXP reward
    db 6  ; Joinability (6)
    db 38  ; Level
    dw 233, 105, 167, 112, 210, 120  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 200, 0  ; AI weights
    db $67, $69, $8B, $FF  ; Skills: PoisonHit, Paralyze, StormWind, none

; --- EID 147 (0x93): Jamirus Lv35 ---
EnemyStats_147:
    db 153  ; Species: Jamirus
    dw 13000  ; EXP reward
    db 7  ; Joinability (never)
    db 35  ; Level
    dw 1600, 175, 260, 160, 150, 145  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 0  ; AI weights
    db $02, $51, $8B, $FF  ; Skills: Blazemost, QuadHits, StormWind, none

; --- EID 148 (0x94): Jamirus Lv35 ---
EnemyStats_148:
    db 153  ; Species: Jamirus
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 35  ; Level
    dw 200, 175, 260, 200, 150, 145  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 0  ; AI weights
    db $02, $51, $8B, $FF  ; Skills: Blazemost, QuadHits, StormWind, none

; --- EID 149 (0x95): Servant Lv35 ---
EnemyStats_149:
    db 173  ; Species: Servant
    dw 15076  ; EXP reward
    db 5  ; Joinability (standard)
    db 35  ; Level
    dw 1000, 250, 160, 160, 200, 170  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 150, 250, 0  ; AI weights
    db $02, $0E, $54, $FF  ; Skills: Blazemost, Blizzard, Focus, none

; --- EID 150 (0x96): Servant Lv35 ---
EnemyStats_150:
    db 173  ; Species: Servant
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 35  ; Level
    dw 160, 250, 160, 180, 200, 170  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 0  ; AI weights
    db $02, $0E, $54, $FF  ; Skills: Blazemost, Blizzard, Focus, none

; --- EID 151 (0x97): Centasaur Lv30 ---
EnemyStats_151:
    db 151  ; Species: Centasaur
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 30  ; Level
    dw 220, 115, 205, 140, 320, 200  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 100, 200, 0  ; AI weights
    db $17, $44, $57, $FF  ; Skills: StopSpell, FireSlash, RainSlash, none

; --- EID 152 (0x98): EvilArmor Lv28 ---
EnemyStats_152:
    db 152  ; Species: EvilArmor
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 28  ; Level
    dw 175, 98, 170, 220, 132, 146  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 150, 0  ; AI weights
    db $44, $45, $49, $FF  ; Skills: FireSlash, BoltSlash, DrakSlash, none

; --- EID 153 (0x99): KingSlime Lv38 ---
EnemyStats_153:
    db 15  ; Species: KingSlime
    dw 17000  ; EXP reward
    db 5  ; Joinability (standard)
    db 38  ; Level
    dw 2000, 75, 200, 130, 190, 190  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 150, 200, 0  ; AI weights
    db $24, $2C, $FF, $FF  ; Skills: Barrier, HealMore, none, none

; --- EID 154 (0x9a): KingSlime Lv38 ---
EnemyStats_154:
    db 15  ; Species: KingSlime
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 38  ; Level
    dw 230, 75, 200, 160, 190, 190  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 250, 200, 0  ; AI weights
    db $24, $2C, $31, $FF  ; Skills: Barrier, HealMore, Revive, none

; --- EID 155 (0x9b): Toadstool Lv10 ---
EnemyStats_155:
    db 96  ; Species: Toadstool
    dw 300  ; EXP reward
    db 5  ; Joinability (standard)
    db 10  ; Level
    dw 45, 17, 25, 23, 40, 36  ; HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0  ; AI weights
    db $68, $6A, $92, $FF  ; Skills: NapAttack, SleepAir, MouthShut, none

; --- EID 156 (0x9c): Lipsy Lv10 ---
EnemyStats_156:
    db 116  ; Species: Lipsy
    dw 250  ; EXP reward
    db 5  ; Joinability (standard)
    db 10  ; Level
    dw 23, 17, 23, 22, 20, 72  ; HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0  ; AI weights
    db $68, $70, $79, $FF  ; Skills: NapAttack, Ahhh, LushLicks, none

; --- EID 157 (0x9d): Lionex Lv40 ---
EnemyStats_157:
    db 141  ; Species: Lionex
    dw 1850  ; EXP reward
    db 5  ; Joinability (standard)
    db 40  ; Level
    dw 268, 130, 202, 246, 210, 160  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 150, 200, 0  ; AI weights
    db $0B, $2E, $46, $FF  ; Skills: Infermost, HealUs, VacuSlash, none

; --- EID 158 (0x9e): RotRaven Lv33 ---
EnemyStats_158:
    db 158  ; Species: RotRaven
    dw 1680  ; EXP reward
    db 4  ; Joinability (4)
    db 33  ; Level
    dw 155, 145, 167, 132, 244, 210  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 150, 0  ; AI weights
    db $3E, $45, $5A, $FF  ; Skills: Kamikaze, BoltSlash, Lightning, none

; --- EID 159 (0x9f): JewelBag Lv38 ---
EnemyStats_159:
    db 175  ; Species: JewelBag
    dw 2000  ; EXP reward
    db 5  ; Joinability (standard)
    db 38  ; Level
    dw 138, 126, 218, 246, 180, 240  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 0, 50, 0  ; AI weights
    db $04, $17, $19, $FF  ; Skills: Firebane, StopSpell, PanicAll, none

; --- EID 160 (0xa0): Swordgon Lv41 ---
EnemyStats_160:
    db 27  ; Species: Swordgon
    dw 1915  ; EXP reward
    db 4  ; Joinability (4)
    db 41  ; Level
    dw 246, 165, 190, 213, 128, 115  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 200, 250, 0  ; AI weights
    db $4E, $57, $90, $FF  ; Skills: CleanCut, RainSlash, BladeD, none

; --- EID 161 (0xa1): SuperTen Lv41 ---
EnemyStats_161:
    db 54  ; Species: SuperTen
    dw 1872  ; EXP reward
    db 5  ; Joinability (standard)
    db 41  ; Level
    dw 276, 80, 148, 90, 218, 154  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 100, 200, 0  ; AI weights
    db $71, $7F, $94, $FF  ; Skills: K.O.Dance, Imitate, Hustle, none

; --- EID 162 (0xa2): MadCondor Lv41 ---
EnemyStats_162:
    db 83  ; Species: MadCondor
    dw 2075  ; EXP reward
    db 5  ; Joinability (standard)
    db 41  ; Level
    dw 190, 130, 256, 224, 160, 160  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 0, 0  ; AI weights
    db $04, $2E, $FF, $FF  ; Skills: Firebane, HealUs, none, none

; --- EID 163 (0xa3): ManEater Lv42 ---
EnemyStats_163:
    db 106  ; Species: ManEater
    dw 1996  ; EXP reward
    db 6  ; Joinability (6)
    db 42  ; Level
    dw 192, 225, 176, 90, 115, 110  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 200, 0  ; AI weights
    db $49, $56, $6A, $FF  ; Skills: DrakSlash, PsycheUp, SleepAir, none

; --- EID 164 (0xa4): Grendal Lv42 ---
EnemyStats_164:
    db 147  ; Species: Grendal
    dw 2130  ; EXP reward
    db 5  ; Joinability (standard)
    db 42  ; Level
    dw 304, 82, 260, 310, 226, 226  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 200, 200, 0  ; AI weights
    db $44, $49, $89, $FF  ; Skills: FireSlash, DrakSlash, Guardian, none

; --- EID 165 (0xa5): DarkCrab Lv28 ---
EnemyStats_165:
    db 160  ; Species: DarkCrab
    dw 1999  ; EXP reward
    db 4  ; Joinability (4)
    db 28  ; Level
    dw 254, 135, 260, 222, 85, 140  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 0, 0  ; AI weights
    db $26, $2A, $FF, $FF  ; Skills: MagicWall, Ironize, none, none

; --- EID 166 (0xa6): MadMirror Lv38 ---
EnemyStats_166:
    db 181  ; Species: MadMirror
    dw 2184  ; EXP reward
    db 5  ; Joinability (standard)
    db 38  ; Level
    dw 284, 92, 145, 204, 232, 170  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 150, 150, 0  ; AI weights
    db $28, $29, $FF, $FF  ; Skills: Bounce, Transform, none, none

; --- EID 167 (0xa7): WingSnake Lv43 ---
EnemyStats_167:
    db 39  ; Species: WingSnake
    dw 2030  ; EXP reward
    db 4  ; Joinability (4)
    db 43  ; Level
    dw 284, 138, 230, 177, 170, 140  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 150, 0  ; AI weights
    db $42, $55, $6D, $FF  ; Skills: HighJump, SquallHit, PoisonAir, none

; --- EID 168 (0xa8): Yeti Lv38 ---
EnemyStats_168:
    db 59  ; Species: Yeti
    dw 1820  ; EXP reward
    db 5  ; Joinability (standard)
    db 38  ; Level
    dw 287, 140, 264, 230, 100, 140  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 150, 200, 0  ; AI weights
    db $0D, $47, $7D, $FF  ; Skills: SnowStorm, IceSlash, WarCry, none

; --- EID 169 (0xa9): DanceVegi Lv44 ---
EnemyStats_169:
    db 100  ; Species: DanceVegi
    dw 1770  ; EXP reward
    db 4  ; Joinability (4)
    db 44  ; Level
    dw 176, 122, 124, 240, 316, 150  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 200, 0  ; AI weights
    db $71, $77, $78, $FF  ; Skills: K.O.Dance, SideStep, LureDance, none

; --- EID 170 (0xaa): Ogre Lv33 ---
EnemyStats_170:
    db 144  ; Species: Ogre
    dw 2320  ; EXP reward
    db 4  ; Joinability (4)
    db 33  ; Level
    dw 288, 140, 235, 235, 104, 230  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 100, 0  ; AI weights
    db $3F, $48, $57, $FF  ; Skills: Massacre, MetalCut, RainSlash, none

; --- EID 171 (0xab): Skullgon Lv43 ---
EnemyStats_171:
    db 156  ; Species: Skullgon
    dw 2516  ; EXP reward
    db 5  ; Joinability (standard)
    db 43  ; Level
    dw 420, 87, 258, 80, 135, 230  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 100, 150, 0  ; AI weights
    db $3B, $47, $61, $FF  ; Skills: TwinSlash, IceSlash, IceAir, none

; --- EID 172 (0xac): Voodoll Lv33 ---
EnemyStats_172:
    db 184  ; Species: Voodoll
    dw 2160  ; EXP reward
    db 4  ; Joinability (4)
    db 33  ; Level
    dw 204, 180, 220, 256, 150, 170  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 250, 0  ; AI weights
    db $18, $19, $1D, $FF  ; Skills: Surround, PanicAll, Defence, none

; --- EID 173 (0xad): Rayburn Lv33 ---
EnemyStats_173:
    db 31  ; Species: Rayburn
    dw 2604  ; EXP reward
    db 6  ; Joinability (6)
    db 33  ; Level
    dw 206, 110, 235, 115, 265, 110  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 100, 150, 0  ; AI weights
    db $46, $4C, $67, $FF  ; Skills: VacuSlash, DevilCut, PoisonHit, none

; --- EID 174 (0xae): IronTurt Lv43 ---
EnemyStats_174:
    db 55  ; Species: IronTurt
    dw 2248  ; EXP reward
    db 5  ; Joinability (standard)
    db 43  ; Level
    dw 300, 120, 258, 200, 120, 180  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 250, 250, 0  ; AI weights
    db $28, $89, $8E, $FF  ; Skills: Bounce, Guardian, StrongD, none

; --- EID 175 (0xaf): DarkHorn Lv40 ---
EnemyStats_175:
    db 67  ; Species: DarkHorn
    dw 21076  ; EXP reward
    db 5  ; Joinability (standard)
    db 40  ; Level
    dw 2000, 130, 225, 120, 80, 210  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 200, 0  ; AI weights
    db $16, $17, $56, $FF  ; Skills: SleepAll, StopSpell, PsycheUp, none

; --- EID 176 (0xb0): DarkHorn Lv40 ---
EnemyStats_176:
    db 67  ; Species: DarkHorn
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 40  ; Level
    dw 170, 130, 245, 150, 80, 250  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 250, 0  ; AI weights
    db $16, $17, $56, $FF  ; Skills: SleepAll, StopSpell, PsycheUp, none

; --- EID 177 (0xb1): Akubar Lv40 ---
EnemyStats_177:
    db 148  ; Species: Akubar
    dw 23000  ; EXP reward
    db 7  ; Joinability (never)
    db 40  ; Level
    dw 2000, 400, 230, 240, 250, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 200, 0  ; AI weights
    db $08, $54, $62, $FF  ; Skills: Explodet, Focus, IceStorm, none

; --- EID 178 (0xb2): Akubar Lv40 ---
EnemyStats_178:
    db 148  ; Species: Akubar
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 40  ; Level
    dw 300, 400, 200, 300, 250, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 100, 200, 0  ; AI weights
    db $08, $54, $62, $FF  ; Skills: Explodet, Focus, IceStorm, none

; --- EID 179 (0xb3): Orochi Lv40 ---
EnemyStats_179:
    db 41  ; Species: Orochi
    dw 28000  ; EXP reward
    db 7  ; Joinability (never)
    db 40  ; Level
    dw 2000, 110, 300, 210, 130, 130  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 250, 0  ; AI weights
    db $44, $51, $5E, $FF  ; Skills: FireSlash, QuadHits, Scorching, none

; --- EID 180 (0xb4): Orochi Lv40 ---
EnemyStats_180:
    db 41  ; Species: Orochi
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 40  ; Level
    dw 310, 110, 300, 260, 130, 130  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 250, 0  ; AI weights
    db $44, $51, $5E, $FF  ; Skills: FireSlash, QuadHits, Scorching, none

; --- EID 181 (0xb5): Metabble Lv38 ---
EnemyStats_181:
    db 17  ; Species: Metabble
    dw 65000  ; EXP reward
    db 6  ; Joinability (6)
    db 38  ; Level
    dw 8, 490, 95, 770, 511, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 0  ; AI weights
    db $05, $08, $DB, $FF  ; Skills: Firebolt, Explodet, RUN, none

; --- EID 182 (0xb6): GulpBeast Lv38 ---
EnemyStats_182:
    db 50  ; Species: GulpBeast
    dw 2480  ; EXP reward
    db 5  ; Joinability (standard)
    db 38  ; Level
    dw 360, 90, 300, 185, 150, 90  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 150, 0  ; AI weights
    db $3D, $3F, $7D, $FF  ; Skills: Beserker, Massacre, WarCry, none

; --- EID 183 (0xb7): Balzak Lv38 ---
EnemyStats_183:
    db 186  ; Species: Balzak
    dw 2560  ; EXP reward
    db 5  ; Joinability (standard)
    db 38  ; Level
    dw 350, 165, 250, 320, 280, 180  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 100, 200, 0  ; AI weights
    db $08, $10, $FF, $FF  ; Skills: Explodet, Zap, none, none

; --- EID 184 (0xb8): Spikerous Lv28 ---
EnemyStats_184:
    db 36  ; Species: Spikerous
    dw 2700  ; EXP reward
    db 5  ; Joinability (standard)
    db 28  ; Level
    dw 250, 23, 270, 340, 90, 113  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 150, 150, 0  ; AI weights
    db $3D, $3E, $5B, $FF  ; Skills: Beserker, Kamikaze, RockThrow, none

; --- EID 185 (0xb9): Trumpeter Lv47 ---
EnemyStats_185:
    db 65  ; Species: Trumpeter
    dw 2800  ; EXP reward
    db 5  ; Joinability (standard)
    db 47  ; Level
    dw 270, 150, 330, 210, 190, 130  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 150, 0  ; AI weights
    db $3D, $72, $7D, $FF  ; Skills: Beserker, SandStorm, WarCry, none

; --- EID 186 (0xba): Skeletor Lv47 ---
EnemyStats_186:
    db 172  ; Species: Skeletor
    dw 2770  ; EXP reward
    db 5  ; Joinability (standard)
    db 47  ; Level
    dw 180, 175, 310, 260, 145, 180  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 250, 0  ; AI weights
    db $1D, $4B, $51, $FF  ; Skills: Defence, BirdBlow, QuadHits, none

; --- EID 187 (0xbb): MetalDrak Lv43 ---
EnemyStats_187:
    db 185  ; Species: MetalDrak
    dw 3360  ; EXP reward
    db 6  ; Joinability (6)
    db 43  ; Level
    dw 330, 105, 280, 260, 250, 130  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 100, 0  ; AI weights
    db $3F, $5B, $72, $FF  ; Skills: Massacre, RockThrow, SandStorm, none

; --- EID 188 (0xbc): MadDragon Lv33 ---
EnemyStats_188:
    db 30  ; Species: MadDragon
    dw 3150  ; EXP reward
    db 5  ; Joinability (standard)
    db 33  ; Level
    dw 220, 24, 335, 130, 90, 30  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 150, 0  ; AI weights
    db $3F, $40, $78, $FF  ; Skills: Massacre, EvilSlash, LureDance, none

; --- EID 189 (0xbd): Snapper Lv48 ---
EnemyStats_189:
    db 107  ; Species: Snapper
    dw 2880  ; EXP reward
    db 5  ; Joinability (standard)
    db 48  ; Level
    dw 235, 185, 250, 140, 140, 230  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 150, 0  ; AI weights
    db $17, $53, $57, $FF  ; Skills: StopSpell, YellHelp, RainSlash, none

; --- EID 190 (0xbe): GoatHorn Lv33 ---
EnemyStats_190:
    db 142  ; Species: GoatHorn
    dw 3520  ; EXP reward
    db 6  ; Joinability (6)
    db 33  ; Level
    dw 270, 190, 260, 150, 190, 240  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 100, 250, 0  ; AI weights
    db $08, $0B, $0E, $FF  ; Skills: Explodet, Infermost, Blizzard, none

; --- EID 191 (0xbf): DeadNoble Lv48 ---
EnemyStats_191:
    db 169  ; Species: DeadNoble
    dw 2990  ; EXP reward
    db 5  ; Joinability (standard)
    db 48  ; Level
    dw 360, 240, 340, 280, 280, 215  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 100, 200, 0  ; AI weights
    db $13, $2F, $FF, $FF  ; Skills: Defeat, HealUsAll, none, none

; --- EID 192 (0xc0): Roboster Lv38 ---
EnemyStats_192:
    db 189  ; Species: Roboster
    dw 3540  ; EXP reward
    db 5  ; Joinability (standard)
    db 38  ; Level
    dw 300, 45, 340, 230, 360, 210  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 200, 0  ; AI weights
    db $51, $55, $57, $FF  ; Skills: QuadHits, SquallHit, RainSlash, none

; --- EID 193 (0xc1): BombCrag Lv48 ---
EnemyStats_193:
    db 198  ; Species: BombCrag
    dw 2500  ; EXP reward
    db 4  ; Joinability (4)
    db 48  ; Level
    dw 310, 190, 175, 250, 25, 140  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 150, 0  ; AI weights
    db $14, $32, $93, $FF  ; Skills: Sacrifice, Farewell, Meditate, none

; --- EID 194 (0xc2): Andreal Lv48 ---
EnemyStats_194:
    db 34  ; Species: Andreal
    dw 3480  ; EXP reward
    db 5  ; Joinability (standard)
    db 48  ; Level
    dw 360, 280, 230, 320, 200, 250  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 200, 0  ; AI weights
    db $0B, $18, $6D, $FF  ; Skills: Infermost, Surround, PoisonAir, none

; --- EID 195 (0xc3): Unicorn Lv48 ---
EnemyStats_195:
    db 62  ; Species: Unicorn
    dw 3120  ; EXP reward
    db 5  ; Joinability (standard)
    db 48  ; Level
    dw 180, 330, 180, 150, 290, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 200, 250, 0  ; AI weights
    db $2D, $31, $33, $FF  ; Skills: HealAll, Revive, Antidote, none

; --- EID 196 (0xc4): GreatDrak Lv51 ---
EnemyStats_196:
    db 37  ; Species: GreatDrak
    dw 3580  ; EXP reward
    db 5  ; Joinability (standard)
    db 51  ; Level
    dw 370, 130, 260, 210, 170, 210  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 200, 250, 0  ; AI weights
    db $47, $62, $8F, $FF  ; Skills: IceSlash, IceStorm, SuckAll, none

; --- EID 197 (0xc5): ZapBird Lv48 ---
EnemyStats_197:
    db 86  ; Species: ZapBird
    dw 3320  ; EXP reward
    db 5  ; Joinability (standard)
    db 48  ; Level
    dw 280, 120, 210, 200, 240, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 150, 150, 0  ; AI weights
    db $45, $5A, $FF, $FF  ; Skills: BoltSlash, Lightning, none, none

; --- EID 198 (0xc6): WhipBird Lv51 ---
EnemyStats_198:
    db 87  ; Species: WhipBird
    dw 3076  ; EXP reward
    db 6  ; Joinability (6)
    db 51  ; Level
    dw 500, 200, 175, 250, 240, 230  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 150, 0  ; AI weights
    db $2A, $83, $FF, $FF  ; Skills: Ironize, ThickFog, none, none

; --- EID 199 (0xc7): Durran Lv45 ---
EnemyStats_199:
    db 154  ; Species: Durran
    dw 31000  ; EXP reward
    db 7  ; Joinability (never)
    db 45  ; Level
    dw 3000, 330, 420, 380, 370, 10  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 100, 0  ; AI weights
    db $49, $4B, $59, $FF  ; Skills: DrakSlash, BirdBlow, Vacuum, none

; --- EID 200 (0xc8): Durran Lv45 ---
EnemyStats_200:
    db 154  ; Species: Durran
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 45  ; Level
    dw 220, 330, 380, 250, 190, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 200, 0  ; AI weights
    db $49, $4B, $59, $FF  ; Skills: DrakSlash, BirdBlow, Vacuum, none

; --- EID 201 (0xc9): DracoLord Lv48 ---
EnemyStats_201:
    db 200  ; Species: DracoLord
    dw 26000  ; EXP reward
    db 7  ; Joinability (never)
    db 48  ; Level
    dw 4000, 550, 340, 320, 230, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 200, 200, 0  ; AI weights
    db $05, $93, $D5, $FF  ; Skills: Firebolt, Meditate, BeDragon, none

; --- EID 202 (0xca): DracoLord Lv48 ---
EnemyStats_202:
    db 200  ; Species: DracoLord
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 48  ; Level
    dw 250, 550, 340, 260, 230, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 200, 250, 0  ; AI weights
    db $05, $93, $D5, $FF  ; Skills: Firebolt, Meditate, BeDragon, none

; --- EID 203 (0xcb): Hargon Lv50 ---
EnemyStats_203:
    db 202  ; Species: Hargon
    dw 38000  ; EXP reward
    db 7  ; Joinability (never)
    db 50  ; Level
    dw 4000, 550, 260, 400, 230, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 250, 0  ; AI weights
    db $05, $08, $87, $FF  ; Skills: Firebolt, Explodet, BazooCall, none

; --- EID 204 (0xcc): Hargon Lv50 ---
EnemyStats_204:
    db 202  ; Species: Hargon
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 50  ; Level
    dw 190, 550, 260, 340, 230, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 250, 0  ; AI weights
    db $05, $08, $87, $FF  ; Skills: Firebolt, Explodet, BazooCall, none

; --- EID 205 (0xcd): Sidoh Lv50 ---
EnemyStats_205:
    db 203  ; Species: Sidoh
    dw 38000  ; EXP reward
    db 7  ; Joinability (never)
    db 50  ; Level
    dw 6000, 999, 530, 340, 230, 10  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 200, 0  ; AI weights
    db $5F, $63, $64, $FF  ; Skills: WhiteFire, WhiteAir, Hellblast, none

; --- EID 206 (0xce): Sidoh Lv50 ---
EnemyStats_206:
    db 203  ; Species: Sidoh
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 50  ; Level
    dw 370, 550, 370, 340, 230, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 200, 0  ; AI weights
    db $5F, $65, $80, $FF  ; Skills: WhiteFire, BigBang, DeMagic, none

; --- EID 207 (0xcf): Baramos Lv50 ---
EnemyStats_207:
    db 204  ; Species: Baramos
    dw 43000  ; EXP reward
    db 7  ; Joinability (never)
    db 50  ; Level
    dw 4000, 999, 410, 550, 230, 10  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 150, 0  ; AI weights
    db $08, $5B, $64, $FF  ; Skills: Explodet, RockThrow, Hellblast, none

; --- EID 208 (0xd0): Baramos Lv50 ---
EnemyStats_208:
    db 204  ; Species: Baramos
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 50  ; Level
    dw 250, 550, 260, 260, 230, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 100, 0  ; AI weights
    db $19, $64, $65, $FF  ; Skills: PanicAll, Hellblast, BigBang, none

; --- EID 209 (0xd1): Zoma Lv55 ---
EnemyStats_209:
    db 205  ; Species: Zoma
    dw 45076  ; EXP reward
    db 7  ; Joinability (never)
    db 55  ; Level
    dw 4500, 999, 440, 400, 260, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 200, 0  ; AI weights
    db $63, $65, $80, $FF  ; Skills: WhiteAir, BigBang, DeMagic, none

; --- EID 210 (0xd2): Zoma Lv55 ---
EnemyStats_210:
    db 205  ; Species: Zoma
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 55  ; Level
    dw 400, 600, 420, 350, 260, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 200, 0  ; AI weights
    db $54, $63, $80, $FF  ; Skills: Focus, WhiteAir, DeMagic, none

; --- EID 211 (0xd3): Pizzaro Lv55 ---
EnemyStats_211:
    db 206  ; Species: Pizzaro
    dw 39076  ; EXP reward
    db 7  ; Joinability (never)
    db 55  ; Level
    dw 6000, 600, 510, 450, 260, 20  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 200, 0  ; AI weights
    db $51, $5F, $64, $FF  ; Skills: QuadHits, WhiteFire, Hellblast, none

; --- EID 212 (0xd4): Pizzaro Lv55 ---
EnemyStats_212:
    db 206  ; Species: Pizzaro
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 55  ; Level
    dw 360, 600, 420, 350, 260, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 250, 200, 0  ; AI weights
    db $51, $63, $82, $FF  ; Skills: QuadHits, WhiteAir, UltraDown, none

; --- EID 213 (0xd5): Esterk Lv60 ---
EnemyStats_213:
    db 207  ; Species: Esterk
    dw 42076  ; EXP reward
    db 7  ; Joinability (never)
    db 60  ; Level
    dw 3800, 700, 560, 520, 450, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 250, 0  ; AI weights
    db $57, $80, $D9, $FF  ; Skills: RainSlash, DeMagic, GigaSlash, none

; --- EID 214 (0xd6): Esterk Lv60 ---
EnemyStats_214:
    db 207  ; Species: Esterk
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 60  ; Level
    dw 600, 700, 460, 450, 300, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 250, 0  ; AI weights
    db $54, $5F, $80, $FF  ; Skills: Focus, WhiteFire, DeMagic, none

; --- EID 215 (0xd7): Mirudraas Lv60 ---
EnemyStats_215:
    db 208  ; Species: Mirudraas
    dw 48076  ; EXP reward
    db 7  ; Joinability (never)
    db 60  ; Level
    dw 5000, 999, 520, 480, 300, 10  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 200, 0  ; AI weights
    db $02, $08, $11, $FF  ; Skills: Blazemost, Explodet, Thordain, none

; --- EID 216 (0xd8): Mirudraas Lv60 ---
EnemyStats_216:
    db 208  ; Species: Mirudraas
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 60  ; Level
    dw 380, 700, 460, 380, 300, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 200, 0  ; AI weights
    db $02, $08, $0E, $FF  ; Skills: Blazemost, Explodet, Blizzard, none

; --- EID 217 (0xd9): Mudou Lv60 ---
EnemyStats_217:
    db 210  ; Species: Mudou
    dw 45076  ; EXP reward
    db 7  ; Joinability (never)
    db 60  ; Level
    dw 5000, 999, 530, 450, 300, 10  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 100, 150, 0  ; AI weights
    db $5F, $63, $6D, $FF  ; Skills: WhiteFire, WhiteAir, PoisonAir, none

; --- EID 218 (0xda): Mudou Lv60 ---
EnemyStats_218:
    db 210  ; Species: Mudou
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 60  ; Level
    dw 380, 700, 460, 450, 300, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 50, 100, 150, 0  ; AI weights
    db $5F, $63, $6A, $FF  ; Skills: WhiteFire, WhiteAir, SleepAir, none

; --- EID 219 (0xdb): DeathMore Lv58 ---
EnemyStats_219:
    db 211  ; Species: DeathMore
    dw 50000  ; EXP reward
    db 7  ; Joinability (never)
    db 58  ; Level
    dw 9000, 700, 460, 520, 450, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 200, 0  ; AI weights
    db $64, $65, $86, $FF  ; Skills: Hellblast, BigBang, SamsiCall, none

; --- EID 220 (0xdc): DeathMore Lv58 ---
EnemyStats_220:
    db 211  ; Species: DeathMore
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 58  ; Level
    dw 380, 700, 460, 380, 300, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 250, 0  ; AI weights
    db $08, $64, $6D, $FF  ; Skills: Explodet, Hellblast, PoisonAir, none

; --- EID 221 (0xdd): Darkdrium Lv70 ---
EnemyStats_221:
    db 214  ; Species: Darkdrium
    dw 65000  ; EXP reward
    db 0  ; Joinability (always)
    db 70  ; Level
    dw 9000, 850, 780, 520, 390, 10  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 150, 250, 0  ; AI weights
    db $50, $5F, $63, $FF  ; Skills: BiAttack, WhiteFire, WhiteAir, none

; --- EID 222 (0xde): Darkdrium Lv70 ---
EnemyStats_222:
    db 214  ; Species: Darkdrium
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 70  ; Level
    dw 999, 850, 999, 520, 390, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 0  ; AI weights
    db $50, $5F, $63, $FF  ; Skills: BiAttack, WhiteFire, WhiteAir, none

; --- EID 223 (0xdf): Watabou Lv20 ---
EnemyStats_223:
    db 109  ; Species: Watabou
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 20  ; Level
    dw 150, 460, 160, 205, 370, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 0, 250, 250, 0  ; AI weights
    db $39, $7E, $7F, $FF  ; Skills: Chance, Whistle, Imitate, none

; --- EID 224 (0xe0): Dracky Lv1 ---
EnemyStats_224:
    db 78  ; Species: Dracky
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 1  ; Level
    dw 8, 20, 12, 4, 12, 14  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 0, 150  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 225 (0xe1): Anteater Lv1 ---
EnemyStats_225:
    db 53  ; Species: Anteater
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 1  ; Level
    dw 12, 0, 17, 4, 4, 3  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 0, 50, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 226 (0xe2): Dracky Lv1 ---
EnemyStats_226:
    db 78  ; Species: Dracky
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 1  ; Level
    dw 8, 20, 11, 3, 10, 14  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 0, 150  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 227 (0xe3): Slime Lv1 ---
EnemyStats_227:
    db 8  ; Species: Slime
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 1  ; Level
    dw 8, 0, 8, 5, 7, 1  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 100, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 228 (0xe4): Stubsuck Lv2 ---
EnemyStats_228:
    db 98  ; Species: Stubsuck
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 2  ; Level
    dw 16, 6, 19, 7, 10, 10  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 50, 200, 100  ; AI weights
    db $15, $FF, $FF, $FF  ; Skills: Sleep, none, none, none

; --- EID 229 (0xe5): Slime Lv1 ---
EnemyStats_229:
    db 8  ; Species: Slime
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 1  ; Level
    dw 7, 0, 8, 5, 6, 1  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 100, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 230 (0xe6): Spooky Lv7 ---
EnemyStats_230:
    db 155  ; Species: Spooky
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 7  ; Level
    dw 16, 8, 13, 12, 17, 16  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 200, 200  ; AI weights
    db $79, $FF, $FF, $FF  ; Skills: LushLicks, none, none, none

; --- EID 231 (0xe7): Hork Lv5 ---
EnemyStats_231:
    db 163  ; Species: Hork
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 5  ; Level
    dw 20, 6, 20, 6, 10, 10  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 0, 0, 50  ; AI weights
    db $6C, $79, $FF, $FF  ; Skills: PoisonGas, LushLicks, none, none

; --- EID 232 (0xe8): Spooky Lv7 ---
EnemyStats_232:
    db 155  ; Species: Spooky
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 7  ; Level
    dw 14, 8, 15, 9, 11, 13  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 200, 200  ; AI weights
    db $79, $FF, $FF, $FF  ; Skills: LushLicks, none, none, none

; --- EID 233 (0xe9): SpotSlime Lv8 ---
EnemyStats_233:
    db 1  ; Species: SpotSlime
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 8  ; Level
    dw 26, 11, 30, 17, 30, 11  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 100, 150  ; AI weights
    db $52, $FF, $FF, $FF  ; Skills: CallHelp, none, none, none

; --- EID 234 (0xea): SpotSlime Lv9 ---
EnemyStats_234:
    db 1  ; Species: SpotSlime
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 9  ; Level
    dw 20, 12, 26, 15, 30, 32  ; HP, MP, ATK, DEF, AGL, INT
    db 50, 0, 150, 0  ; AI weights
    db $79, $FF, $FF, $FF  ; Skills: LushLicks, none, none, none

; --- EID 235 (0xeb): SpotSlime Lv8 ---
EnemyStats_235:
    db 1  ; Species: SpotSlime
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 8  ; Level
    dw 24, 15, 28, 14, 32, 11  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 200, 150  ; AI weights
    db $7F, $FF, $FF, $FF  ; Skills: Imitate, none, none, none

; --- EID 236 (0xec): MudDoll Lv12 ---
EnemyStats_236:
    db 195  ; Species: MudDoll
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 12  ; Level
    dw 38, 20, 22, 18, 24, 44  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 0, 250, 50  ; AI weights
    db $75, $FF, $FF, $FF  ; Skills: OddDance, none, none, none

; --- EID 237 (0xed): Almiraj Lv10 ---
EnemyStats_237:
    db 46  ; Species: Almiraj
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 10  ; Level
    dw 42, 26, 26, 20, 40, 22  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 0, 100, 100  ; AI weights
    db $15, $3C, $41, $FF  ; Skills: Sleep, Ramming, ChargeUP, none

; --- EID 238 (0xee): MudDoll Lv12 ---
EnemyStats_238:
    db 195  ; Species: MudDoll
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 12  ; Level
    dw 40, 44, 20, 22, 22, 44  ; HP, MP, ATK, DEF, AGL, INT
    db 50, 0, 250, 50  ; AI weights
    db $77, $FF, $FF, $FF  ; Skills: SideStep, none, none, none

; --- EID 239 (0xef): Putrepup Lv12 ---
EnemyStats_239:
    db 157  ; Species: Putrepup
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 12  ; Level
    dw 75, 10, 28, 24, 30, 20  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 150, 150  ; AI weights
    db $1C, $20, $FF, $FF  ; Skills: Sap, Slow, none, none

; --- EID 240 (0xf0): MadRaven Lv12 ---
EnemyStats_240:
    db 76  ; Species: MadRaven
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 12  ; Level
    dw 50, 12, 30, 24, 60, 80  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 100, 150  ; AI weights
    db $42, $8A, $FF, $FF  ; Skills: HighJump, TailWind, none, none

; --- EID 241 (0xf1): Skullroo Lv12 ---
EnemyStats_241:
    db 51  ; Species: Skullroo
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 12  ; Level
    dw 58, 8, 38, 18, 50, 50  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 0, 100, 50  ; AI weights
    db $41, $6E, $FF, $FF  ; Skills: ChargeUP, PaniDance, none, none

; --- EID 242 (0xf2): Crestpent Lv8 ---
EnemyStats_242:
    db 38  ; Species: Crestpent
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 8  ; Level
    dw 60, 8, 20, 30, 15, 9  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 100, 100  ; AI weights
    db $17, $67, $D5, $FF  ; Skills: StopSpell, PoisonHit, BeDragon, none

; --- EID 243 (0xf3): TreeSlime Lv12 ---
EnemyStats_243:
    db 3  ; Species: TreeSlime
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 12  ; Level
    dw 70, 8, 30, 26, 49, 46  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 0, 250, 200  ; AI weights
    db $1C, $69, $6A, $FF  ; Skills: Sap, Paralyze, SleepAir, none

; --- EID 244 (0xf4): Poisongon Lv12 ---
EnemyStats_244:
    db 26  ; Species: Poisongon
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 12  ; Level
    dw 50, 14, 35, 30, 26, 23  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 0, 50, 0  ; AI weights
    db $67, $6C, $FF, $FF  ; Skills: PoisonHit, PoisonGas, none, none

; --- EID 245 (0xf5): DrakSlime Lv14 ---
EnemyStats_245:
    db 0  ; Species: DrakSlime
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 14  ; Level
    dw 40, 16, 30, 26, 96, 52  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 0, 200, 150  ; AI weights
    db $43, $5C, $FF, $FF  ; Skills: SuckAir, FireAir, none, none

; --- EID 246 (0xf6): Dragon Lv15 ---
EnemyStats_246:
    db 28  ; Species: Dragon
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 15  ; Level
    dw 65, 20, 45, 40, 30, 26  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 0, 250  ; AI weights
    db $44, $5C, $FF, $FF  ; Skills: FireSlash, FireAir, none, none

; --- EID 247 (0xf7): FairyDrak Lv14 ---
EnemyStats_247:
    db 24  ; Species: FairyDrak
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 14  ; Level
    dw 40, 21, 25, 30, 51, 27  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 0, 100, 50  ; AI weights
    db $18, $6A, $FF, $FF  ; Skills: Surround, SleepAir, none, none

; --- EID 248 (0xf8): Snaily Lv16 ---
EnemyStats_248:
    db 4  ; Species: Snaily
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 16  ; Level
    dw 45, 20, 30, 60, 110, 60  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 100, 0, 150  ; AI weights
    db $0C, $FF, $FF, $FF  ; Skills: IceBolt, none, none, none

; --- EID 249 (0xf9): ArmorPede Lv20 ---
EnemyStats_249:
    db 121  ; Species: ArmorPede
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 20  ; Level
    dw 80, 27, 40, 72, 40, 68  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 100, 50  ; AI weights
    db $1E, $25, $3B, $FF  ; Skills: Upper, TwinHits, TwinSlash, none

; --- EID 250 (0xfa): Snaily Lv16 ---
EnemyStats_250:
    db 4  ; Species: Snaily
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 16  ; Level
    dw 40, 20, 32, 55, 110, 60  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 0, 150  ; AI weights
    db $52, $FF, $FF, $FF  ; Skills: CallHelp, none, none, none

; --- EID 251 (0xfb): Saccer Lv17 ---
EnemyStats_251:
    db 49  ; Species: Saccer
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 17  ; Level
    dw 80, 31, 48, 82, 9, 62  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 0, 200, 100  ; AI weights
    db $1E, $56, $FF, $FF  ; Skills: Upper, PsycheUp, none, none

; --- EID 252 (0xfc): Florajay Lv19 ---
EnemyStats_252:
    db 73  ; Species: Florajay
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 19  ; Level
    dw 50, 56, 55, 42, 142, 120  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 50, 100, 250  ; AI weights
    db $23, $4A, $95, $FF  ; Skills: SpeedUp, BeastCut, LifeSong, none

; --- EID 253 (0xfd): MadPlant Lv20 ---
EnemyStats_253:
    db 90  ; Species: MadPlant
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 20  ; Level
    dw 100, 100, 52, 50, 135, 91  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 250, 100  ; AI weights
    db $1C, $20, $34, $FF  ; Skills: Sap, Slow, NumbOff, none

; --- EID 254 (0xfe): MedusaEye Lv20 ---
EnemyStats_254:
    db 140  ; Species: MedusaEye
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 20  ; Level
    dw 70, 48, 40, 96, 48, 44  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 0, 100, 250  ; AI weights
    db $18, $1C, $D8, $FF  ; Skills: Surround, Sap, Branching, none

; --- EID 255 (0xff): MadGopher Lv21 ---
EnemyStats_255:
    db 60  ; Species: MadGopher
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 21  ; Level
    dw 100, 38, 61, 45, 54, 48  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 0, 200  ; AI weights
    db $41, $4B, $4D, $FF  ; Skills: ChargeUP, BirdBlow, ZombieCut, none

; --- EID 256 (0x100): MedusaEye Lv20 ---
EnemyStats_256:
    db 140  ; Species: MedusaEye
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 20  ; Level
    dw 70, 68, 44, 90, 48, 44  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 0, 100, 250  ; AI weights
    db $18, $1C, $D8, $FF  ; Skills: Surround, Sap, Branching, none

; --- EID 257 (0x101): MadCat Lv20 ---
EnemyStats_257:
    db 68  ; Species: MadCat
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 20  ; Level
    dw 100, 28, 65, 60, 80, 45  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 200, 250  ; AI weights
    db $46, $55, $7B, $FF  ; Skills: VacuSlash, SquallHit, LegSweep, none

; --- EID 258 (0x102): RogueNite Lv27 ---
EnemyStats_258:
    db 182  ; Species: RogueNite
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 27  ; Level
    dw 110, 38, 80, 100, 50, 79  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 150, 200  ; AI weights
    db $2B, $40, $48, $FF  ; Skills: Heal, EvilSlash, MetalCut, none

; --- EID 259 (0x103): MadCat Lv20 ---
EnemyStats_259:
    db 68  ; Species: MadCat
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 20  ; Level
    dw 100, 28, 72, 50, 80, 45  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 200, 250  ; AI weights
    db $46, $55, $7B, $FF  ; Skills: VacuSlash, SquallHit, LegSweep, none

; --- EID 260 (0x104): SpikyBoy Lv24 ---
EnemyStats_260:
    db 180  ; Species: SpikyBoy
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 24  ; Level
    dw 80, 26, 70, 83, 50, 63  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 100, 100, 250  ; AI weights
    db $14, $42, $D6, $FF  ; Skills: Sacrifice, HighJump, Smashlime, none

; --- EID 261 (0x105): StubBird Lv23 ---
EnemyStats_261:
    db 80  ; Species: StubBird
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 23  ; Level
    dw 100, 44, 100, 120, 90, 82  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 50, 100  ; AI weights
    db $25, $57, $D7, $FF  ; Skills: TwinHits, RainSlash, Sheldodge, none

; --- EID 262 (0x106): SpikyBoy Lv24 ---
EnemyStats_262:
    db 180  ; Species: SpikyBoy
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 24  ; Level
    dw 80, 46, 75, 83, 50, 63  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 100, 100, 250  ; AI weights
    db $14, $42, $D6, $FF  ; Skills: Sacrifice, HighJump, Smashlime, none

; --- EID 263 (0x107): Healer Lv22 ---
EnemyStats_263:
    db 9  ; Species: Healer
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 22  ; Level
    dw 80, 50, 16, 80, 37, 250  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 250, 100, 200  ; AI weights
    db $2B, $FF, $FF, $FF  ; Skills: Heal, none, none, none

; --- EID 264 (0x108): RogueNite Lv27 ---
EnemyStats_264:
    db 182  ; Species: RogueNite
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 27  ; Level
    dw 180, 48, 150, 120, 50, 79  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 150, 200  ; AI weights
    db $2B, $40, $48, $FF  ; Skills: Heal, EvilSlash, MetalCut, none

; --- EID 265 (0x109): Healer Lv22 ---
EnemyStats_265:
    db 9  ; Species: Healer
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 22  ; Level
    dw 90, 50, 16, 80, 37, 250  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 250, 100, 200  ; AI weights
    db $2B, $FF, $FF, $FF  ; Skills: Heal, none, none, none

; --- EID 266 (0x10a): BoxSlime Lv27 ---
EnemyStats_266:
    db 7  ; Species: BoxSlime
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 27  ; Level
    dw 240, 39, 122, 100, 145, 76  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 50, 200, 150  ; AI weights
    db $1E, $3C, $FF, $FF  ; Skills: Upper, Ramming, none, none

; --- EID 267 (0x10b): RockSlime Lv29 ---
EnemyStats_267:
    db 11  ; Species: RockSlime
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 29  ; Level
    dw 170, 20, 155, 160, 89, 55  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 150, 250  ; AI weights
    db $42, $8E, $FF, $FF  ; Skills: HighJump, StrongD, none, none

; --- EID 268 (0x10c): BoxSlime Lv27 ---
EnemyStats_268:
    db 7  ; Species: BoxSlime
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 27  ; Level
    dw 240, 29, 122, 100, 145, 76  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 150, 150, 150  ; AI weights
    db $01, $3C, $FF, $FF  ; Skills: Blazemore, Ramming, none, none

; --- EID 269 (0x10d): HammerMan Lv32 ---
EnemyStats_269:
    db 57  ; Species: HammerMan
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 32  ; Level
    dw 150, 30, 110, 90, 118, 62  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 50, 250  ; AI weights
    db $3E, $40, $41, $FF  ; Skills: Kamikaze, EvilSlash, ChargeUP, none

; --- EID 270 (0x10e): HammerMan Lv32 ---
EnemyStats_270:
    db 57  ; Species: HammerMan
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 32  ; Level
    dw 130, 35, 120, 85, 118, 62  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 50, 250  ; AI weights
    db $3E, $41, $FF, $FF  ; Skills: Kamikaze, ChargeUP, none, none

; --- EID 271 (0x10f): HammerMan Lv32 ---
EnemyStats_271:
    db 57  ; Species: HammerMan
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 32  ; Level
    dw 120, 30, 115, 80, 118, 62  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 50, 250  ; AI weights
    db $3E, $40, $41, $FF  ; Skills: Kamikaze, EvilSlash, ChargeUP, none

; --- EID 272 (0x110): AgDevil Lv31 ---
EnemyStats_272:
    db 132  ; Species: AgDevil
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 31  ; Level
    dw 200, 60, 98, 115, 90, 142  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 150, 150  ; AI weights
    db $04, $6A, $FF, $FF  ; Skills: Firebane, SleepAir, none, none

; --- EID 273 (0x111): WindMerge Lv31 ---
EnemyStats_273:
    db 167  ; Species: WindMerge
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 31  ; Level
    dw 150, 80, 68, 126, 122, 165  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 200, 100  ; AI weights
    db $0B, $24, $36, $FF  ; Skills: Infermost, Barrier, CurseOff, none

; --- EID 274 (0x112): TreeBoy Lv33 ---
EnemyStats_274:
    db 101  ; Species: TreeBoy
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 33  ; Level
    dw 200, 85, 64, 80, 156, 185  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 200, 200, 50  ; AI weights
    db $0C, $2B, $36, $FF  ; Skills: IceBolt, Heal, CurseOff, none

; --- EID 275 (0x113): ArmyCrab Lv36 ---
EnemyStats_275:
    db 125  ; Species: ArmyCrab
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 36  ; Level
    dw 170, 78, 100, 150, 105, 72  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 250, 0  ; AI weights
    db $1F, $48, $FF, $FF  ; Skills: Increase, MetalCut, none, none

; --- EID 276 (0x114): MadDragon Lv33 ---
EnemyStats_276:
    db 30  ; Species: MadDragon
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 33  ; Level
    dw 220, 20, 200, 70, 150, 20  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 150, 150  ; AI weights
    db $3F, $40, $78, $FF  ; Skills: Massacre, EvilSlash, LureDance, none

; --- EID 277 (0x115): ArmyCrab Lv36 ---
EnemyStats_277:
    db 125  ; Species: ArmyCrab
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 36  ; Level
    dw 130, 78, 110, 140, 105, 72  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 250, 0  ; AI weights
    db $1F, $48, $52, $FF  ; Skills: Increase, MetalCut, CallHelp, none

; --- EID 278 (0x116): FireWeed Lv39 ---
EnemyStats_278:
    db 91  ; Species: FireWeed
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 39  ; Level
    dw 160, 80, 73, 108, 110, 147  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 150, 100  ; AI weights
    db $01, $35, $6B, $FF  ; Skills: Blazemore, DeChaos, PalsyAir, none

; --- EID 279 (0x117): EvilBeast Lv37 ---
EnemyStats_279:
    db 137  ; Species: EvilBeast
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 37  ; Level
    dw 150, 60, 172, 132, 106, 186  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 250, 150  ; AI weights
    db $04, $61, $FF, $FF  ; Skills: Firebane, IceAir, none, none

; --- EID 280 (0x118): Wyvern Lv39 ---
EnemyStats_280:
    db 71  ; Species: Wyvern
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 39  ; Level
    dw 160, 75, 135, 100, 160, 205  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 150, 150, 250  ; AI weights
    db $16, $2C, $61, $FF  ; Skills: SleepAll, HealMore, IceAir, none

; --- EID 281 (0x119): Grizzly Lv38 ---
EnemyStats_281:
    db 58  ; Species: Grizzly
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 38  ; Level
    dw 250, 20, 260, 72, 200, 80  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 0, 200  ; AI weights
    db $55, $7C, $FF, $FF  ; Skills: SquallHit, BigTrip, none, none

; --- EID 282 (0x11a): Lionex Lv40 ---
EnemyStats_282:
    db 141  ; Species: Lionex
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 40  ; Level
    dw 260, 100, 122, 200, 210, 160  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 150, 150, 50  ; AI weights
    db $0B, $2E, $46, $FF  ; Skills: Infermost, HealUs, VacuSlash, none

; --- EID 283 (0x11b): Grizzly Lv38 ---
EnemyStats_283:
    db 58  ; Species: Grizzly
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 38  ; Level
    dw 240, 20, 250, 72, 200, 80  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 0, 200  ; AI weights
    db $3B, $55, $7C, $FF  ; Skills: TwinSlash, SquallHit, BigTrip, none

; --- EID 284 (0x11c): Toadstool Lv40 ---
EnemyStats_284:
    db 96  ; Species: Toadstool
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 40  ; Level
    dw 250, 120, 150, 160, 150, 120  ; HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0  ; AI weights
    db $68, $6A, $92, $FF  ; Skills: NapAttack, SleepAir, MouthShut, none

; --- EID 285 (0x11d): Lipsy Lv38 ---
EnemyStats_285:
    db 116  ; Species: Lipsy
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 38  ; Level
    dw 350, 110, 170, 100, 180, 150  ; HP, MP, ATK, DEF, AGL, INT
    db 50, 0, 50, 0  ; AI weights
    db $68, $70, $79, $FF  ; Skills: NapAttack, Ahhh, LushLicks, none

; --- EID 286 (0x11e): Toadstool Lv40 ---
EnemyStats_286:
    db 96  ; Species: Toadstool
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 40  ; Level
    dw 250, 100, 140, 150, 120, 120  ; HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0  ; AI weights
    db $68, $6A, $92, $FF  ; Skills: NapAttack, SleepAir, MouthShut, none

; --- EID 287 (0x11f): DanceVegi Lv44 ---
EnemyStats_287:
    db 100  ; Species: DanceVegi
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 44  ; Level
    dw 160, 80, 84, 200, 120, 150  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 200, 100  ; AI weights
    db $71, $77, $78, $FF  ; Skills: K.O.Dance, SideStep, LureDance, none

; --- EID 288 (0x120): Voodoll Lv33 ---
EnemyStats_288:
    db 184  ; Species: Voodoll
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 33  ; Level
    dw 190, 120, 168, 216, 150, 170  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 200, 250  ; AI weights
    db $18, $19, $1D, $FF  ; Skills: Surround, PanicAll, Defence, none

; --- EID 289 (0x121): DanceVegi Lv44 ---
EnemyStats_289:
    db 100  ; Species: DanceVegi
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 44  ; Level
    dw 170, 85, 86, 190, 316, 150  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 150, 100  ; AI weights
    db $71, $77, $78, $FF  ; Skills: K.O.Dance, SideStep, LureDance, none

; --- EID 290 (0x122): Slime Lv38 ---
EnemyStats_290:
    db 8  ; Species: Slime
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 38  ; Level
    dw 250, 120, 200, 130, 260, 140  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 0, 100, 200  ; AI weights
    db $05, $73, $FF, $FF  ; Skills: Firebolt, Radiant, none, none

; --- EID 291 (0x123): Dracky Lv38 ---
EnemyStats_291:
    db 78  ; Species: Dracky
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 38  ; Level
    dw 180, 150, 170, 130, 160, 200  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 200, 150  ; AI weights
    db $16, $1A, $73, $FF  ; Skills: SleepAll, RobMagic, Radiant, none

; --- EID 292 (0x124): ArmyAnt Lv33 ---
EnemyStats_292:
    db 118  ; Species: ArmyAnt
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 33  ; Level
    dw 210, 100, 250, 200, 150, 90  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 0, 200  ; AI weights
    db $3E, $53, $68, $FF  ; Skills: Kamikaze, YellHelp, NapAttack, none

; --- EID 293 (0x125): Metabble Lv38 ---
EnemyStats_293:
    db 17  ; Species: Metabble
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 38  ; Level
    dw 10, 490, 110, 670, 511, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 0  ; AI weights
    db $05, $08, $FF, $FF  ; Skills: Firebolt, Explodet, none, none

; --- EID 294 (0x126): Roboster Lv38 ---
EnemyStats_294:
    db 189  ; Species: Roboster
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 38  ; Level
    dw 310, 145, 230, 180, 360, 210  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 50, 50  ; AI weights
    db $51, $55, $57, $FF  ; Skills: QuadHits, SquallHit, RainSlash, none

; --- EID 295 (0x127): MetalDrak Lv43 ---
EnemyStats_295:
    db 185  ; Species: MetalDrak
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 43  ; Level
    dw 400, 105, 250, 200, 250, 130  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 150, 100  ; AI weights
    db $3F, $72, $FF, $FF  ; Skills: Massacre, SandStorm, none, none

; --- EID 296 (0x128): Centasaur Lv43 ---
EnemyStats_296:
    db 151  ; Species: Centasaur
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 43  ; Level
    dw 320, 85, 205, 240, 320, 200  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 200, 250  ; AI weights
    db $17, $44, $57, $FF  ; Skills: StopSpell, FireSlash, RainSlash, none

; --- EID 297 (0x129): Orochi Lv50 ---
EnemyStats_297:
    db 41  ; Species: Orochi
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 50  ; Level
    dw 300, 200, 160, 320, 250, 180  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 250, 200  ; AI weights
    db $44, $51, $5E, $FF  ; Skills: FireSlash, QuadHits, Scorching, none

; --- EID 298 (0x12a): Swordgon Lv48 ---
EnemyStats_298:
    db 27  ; Species: Swordgon
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 48  ; Level
    dw 250, 100, 180, 210, 100, 130  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 200, 200, 250  ; AI weights
    db $4E, $57, $90, $FF  ; Skills: CleanCut, RainSlash, BladeD, none

; --- EID 299 (0x12b): Andreal Lv48 ---
EnemyStats_299:
    db 34  ; Species: Andreal
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 48  ; Level
    dw 340, 180, 185, 260, 200, 250  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 200, 200  ; AI weights
    db $0B, $18, $6D, $FF  ; Skills: Infermost, Surround, PoisonAir, none

; --- EID 300 (0x12c): Unicorn Lv48 ---
EnemyStats_300:
    db 62  ; Species: Unicorn
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 48  ; Level
    dw 220, 230, 170, 150, 290, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $2D, $31, $33, $FF  ; Skills: HealAll, Revive, Antidote, none

; --- EID 301 (0x12d): MadDragon Lv33 ---
EnemyStats_301:
    db 30  ; Species: MadDragon
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 33  ; Level
    dw 220, 20, 305, 120, 200, 30  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 200, 150  ; AI weights
    db $3F, $40, $78, $FF  ; Skills: Massacre, EvilSlash, LureDance, none

; --- EID 302 (0x12e): MetalKing Lv50 ---
EnemyStats_302:
    db 18  ; Species: MetalKing
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 50  ; Level
    dw 8, 700, 150, 700, 511, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 200  ; AI weights
    db $10, $FF, $FF, $FF  ; Skills: Zap, none, none, none

; --- EID 303 (0x12f): Coatol Lv50 ---
EnemyStats_303:
    db 40  ; Species: Coatol
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 50  ; Level
    dw 300, 180, 220, 240, 320, 200  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 100, 150, 100  ; AI weights
    db $08, $40, $45, $FF  ; Skills: Explodet, EvilSlash, BoltSlash, none

; --- EID 304 (0x130): RainHawk Lv50 ---
EnemyStats_304:
    db 89  ; Species: RainHawk
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 50  ; Level
    dw 380, 50, 200, 220, 320, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 150, 50, 250  ; AI weights
    db $66, $81, $FF, $FF  ; Skills: MegaMagic, Surge, none, none

; --- EID 305 (0x131): LizardMan Lv20 ---
EnemyStats_305:
    db 25  ; Species: LizardMan
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 20  ; Level
    dw 80, 40, 130, 70, 70, 70  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 100, 100, 100  ; AI weights
    db $2B, $30, $8E, $FF  ; Skills: Heal, Vivify, StrongD, none

; --- EID 306 (0x132): CatFly Lv20 ---
EnemyStats_306:
    db 47  ; Species: CatFly
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 20  ; Level
    dw 50, 40, 80, 50, 100, 70  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 50, 200  ; AI weights
    db $1A, $1E, $25, $FF  ; Skills: RobMagic, Upper, TwinHits, none

; --- EID 307 (0x133): DeadNite Lv20 ---
EnemyStats_307:
    db 161  ; Species: DeadNite
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 20  ; Level
    dw 80, 80, 70, 90, 60, 90  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 150, 150  ; AI weights
    db $49, $4C, $D6, $FF  ; Skills: DrakSlash, DevilCut, Smashlime, none

; --- EID 308 (0x134): IceMan Lv20 ---
EnemyStats_308:
    db 193  ; Species: IceMan
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 20  ; Level
    dw 80, 40, 80, 150, 50, 40  ; HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0  ; AI weights
    db $88, $8A, $FF, $FF  ; Skills: Cover, TailWind, none, none

; --- EID 309 (0x135): Rayburn Lv30 ---
EnemyStats_309:
    db 31  ; Species: Rayburn
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 30  ; Level
    dw 150, 80, 160, 100, 220, 90  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 150, 100, 200  ; AI weights
    db $00, $03, $06, $FF  ; Skills: Blaze, Firebal, Bang, none

; --- EID 310 (0x136): Eyeder Lv30 ---
EnemyStats_310:
    db 122  ; Species: Eyeder
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 30  ; Level
    dw 100, 60, 130, 120, 140, 100  ; HP, MP, ATK, DEF, AGL, INT
    db 50, 150, 200, 100  ; AI weights
    db $76, $77, $78, $FF  ; Skills: RobDance, SideStep, LureDance, none

; --- EID 311 (0x137): FangSlime Lv30 ---
EnemyStats_311:
    db 10  ; Species: FangSlime
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 30  ; Level
    dw 90, 60, 170, 130, 170, 90  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 200, 200, 200  ; AI weights
    db $43, $50, $90, $FF  ; Skills: SuckAir, BiAttack, BladeD, none

; --- EID 312 (0x138): Droll Lv30 ---
EnemyStats_312:
    db 124  ; Species: Droll
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 30  ; Level
    dw 80, 120, 100, 100, 80, 120  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 0, 100, 100  ; AI weights
    db $4B, $D6, $D7, $FF  ; Skills: BirdBlow, Smashlime, Sheldodge, none

; --- EID 313 (0x139): Yeti Lv38 ---
EnemyStats_313:
    db 59  ; Species: Yeti
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 38  ; Level
    dw 220, 140, 230, 210, 100, 140  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 250, 200, 0  ; AI weights
    db $17, $91, $92, $FF  ; Skills: StopSpell, DanceShut, MouthShut, none

; --- EID 314 (0x13a): StoneMan Lv40 ---
EnemyStats_314:
    db 197  ; Species: StoneMan
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 40  ; Level
    dw 300, 120, 200, 240, 90, 170  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 50, 200  ; AI weights
    db $2E, $32, $70, $FF  ; Skills: HealUs, Farewell, Ahhh, none

; --- EID 315 (0x13b): Metaly Lv20 ---
EnemyStats_315:
    db 16  ; Species: Metaly
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 20  ; Level
    dw 10, 200, 30, 300, 200, 50  ; HP, MP, ATK, DEF, AGL, INT
    db 0, 100, 100, 0  ; AI weights
    db $88, $96, $FF, $FF  ; Skills: Cover, LifeDance, none, none

; --- EID 316 (0x13c): Skeletor Lv40 ---
EnemyStats_316:
    db 172  ; Species: Skeletor
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 40  ; Level
    dw 160, 170, 310, 260, 140, 180  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 250, 150  ; AI weights
    db $4E, $4F, $D9, $FF  ; Skills: CleanCut, MultiCut, GigaSlash, none

; --- EID 317 (0x13d): Mimic Lv1 ---
EnemyStats_317:
    db 194  ; Species: Mimic
    dw 10  ; EXP reward
    db 4  ; Joinability (4)
    db 1  ; Level
    dw 12, 2, 10, 6, 5, 8  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 100, 50  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 318 (0x13e): Mimic Lv5 ---
EnemyStats_318:
    db 194  ; Species: Mimic
    dw 30  ; EXP reward
    db 4  ; Joinability (4)
    db 5  ; Level
    dw 20, 9, 20, 12, 10, 30  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 100, 50  ; AI weights
    db $00, $FF, $FF, $FF  ; Skills: Blaze, none, none, none

; --- EID 319 (0x13f): Mimic Lv10 ---
EnemyStats_319:
    db 194  ; Species: Mimic
    dw 90  ; EXP reward
    db 4  ; Joinability (4)
    db 10  ; Level
    dw 45, 20, 40, 20, 20, 80  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 100, 50  ; AI weights
    db $00, $12, $FF, $FF  ; Skills: Blaze, Beat, none, none

; --- EID 320 (0x140): Mimic Lv20 ---
EnemyStats_320:
    db 194  ; Species: Mimic
    dw 300  ; EXP reward
    db 4  ; Joinability (4)
    db 20  ; Level
    dw 80, 40, 60, 40, 40, 130  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 100, 50  ; AI weights
    db $01, $12, $FF, $FF  ; Skills: Blazemore, Beat, none, none

; --- EID 321 (0x141): Mimic Lv30 ---
EnemyStats_321:
    db 194  ; Species: Mimic
    dw 600  ; EXP reward
    db 4  ; Joinability (4)
    db 30  ; Level
    dw 125, 60, 80, 60, 60, 170  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 100, 50  ; AI weights
    db $01, $12, $FF, $FF  ; Skills: Blazemore, Beat, none, none

; --- EID 322 (0x142): Mimic Lv38 ---
EnemyStats_322:
    db 194  ; Species: Mimic
    dw 1200  ; EXP reward
    db 4  ; Joinability (4)
    db 38  ; Level
    dw 165, 80, 100, 80, 80, 210  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 100, 50  ; AI weights
    db $02, $13, $FF, $FF  ; Skills: Blazemost, Defeat, none, none

; --- EID 323 (0x143): Mimic Lv38 ---
EnemyStats_323:
    db 194  ; Species: Mimic
    dw 3076  ; EXP reward
    db 4  ; Joinability (4)
    db 38  ; Level
    dw 295, 160, 120, 110, 90, 225  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 100, 50  ; AI weights
    db $02, $13, $FF, $FF  ; Skills: Blazemost, Defeat, none, none

; --- EID 324 (0x144): Mimic Lv38 ---
EnemyStats_324:
    db 194  ; Species: Mimic
    dw 6076  ; EXP reward
    db 4  ; Joinability (4)
    db 38  ; Level
    dw 330, 220, 200, 150, 110, 225  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 100, 50  ; AI weights
    db $02, $13, $FF, $FF  ; Skills: Blazemost, Defeat, none, none

; --- EID 325 (0x145): Slime Lv1 ---
EnemyStats_325:
    db 8  ; Species: Slime
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 1  ; Level
    dw 4, 2, 3, 4, 8, 5  ; HP, MP, ATK, DEF, AGL, INT
    db 0, 250, 100, 150  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 326 (0x146): DragonKid Lv1 ---
EnemyStats_326:
    db 20  ; Species: DragonKid
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 1  ; Level
    dw 8, 4, 10, 7, 6, 8  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 0, 250  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 327 (0x147): Anteater Lv1 ---
EnemyStats_327:
    db 53  ; Species: Anteater
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 1  ; Level
    dw 6, 3, 6, 4, 7, 5  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 150, 250, 50  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 328 (0x148): 1EyeClown Lv1 ---
EnemyStats_328:
    db 138  ; Species: 1EyeClown
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 1  ; Level
    dw 7, 8, 5, 3, 6, 10  ; HP, MP, ATK, DEF, AGL, INT
    db 50, 100, 250, 150  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 329 (0x149): Blizzardy Lv1 ---
EnemyStats_329:
    db 84  ; Species: Blizzardy
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 1  ; Level
    dw 15, 10, 12, 8, 18, 10  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 200, 100, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 330 (0x14a): Phoenix Lv1 ---
EnemyStats_330:
    db 85  ; Species: Phoenix
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 1  ; Level
    dw 15, 10, 12, 8, 18, 10  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 200, 100, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 331 (0x14b): LavaMan Lv1 ---
EnemyStats_331:
    db 192  ; Species: LavaMan
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 1  ; Level
    dw 18, 8, 12, 18, 4, 6  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 100, 50, 150  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 332 (0x14c): IceMan Lv1 ---
EnemyStats_332:
    db 193  ; Species: IceMan
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 1  ; Level
    dw 18, 8, 12, 18, 4, 6  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 100, 50, 150  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 333 (0x14d): NiteWhip Lv1 ---
EnemyStats_333:
    db 165  ; Species: NiteWhip
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 1  ; Level
    dw 20, 20, 20, 15, 25, 15  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 200, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 334 (0x14e): ArmorPede Lv1 ---
EnemyStats_334:
    db 121  ; Species: ArmorPede
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 1  ; Level
    dw 30, 20, 20, 30, 15, 15  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 150, 100, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 335 (0x14f): ManEater Lv1 ---
EnemyStats_335:
    db 106  ; Species: ManEater
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 1  ; Level
    dw 30, 30, 25, 20, 20, 20  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 150, 100  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 336 (0x150): ZapBird Lv1 ---
EnemyStats_336:
    db 86  ; Species: ZapBird
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 1  ; Level
    dw 30, 25, 30, 25, 30, 20  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 200, 200, 150  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 337 (0x151): Trumpeter Lv1 ---
EnemyStats_337:
    db 65  ; Species: Trumpeter
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 1  ; Level
    dw 35, 25, 35, 30, 25, 25  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 150, 100, 100  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 338 (0x152): ChopClown Lv1 ---
EnemyStats_338:
    db 146  ; Species: ChopClown
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 1  ; Level
    dw 35, 20, 35, 20, 35, 20  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 200, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 339 (0x153): Spikerous Lv1 ---
EnemyStats_339:
    db 36  ; Species: Spikerous
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 1  ; Level
    dw 40, 30, 40, 60, 20, 30  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 200, 150, 150  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 340 (0x154): Metabble Lv1 ---
EnemyStats_340:
    db 17  ; Species: Metabble
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 1  ; Level
    dw 10, 50, 20, 200, 200, 30  ; HP, MP, ATK, DEF, AGL, INT
    db 0, 150, 100, 0  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 341 (0x155): Stubsuck Lv20 ---
EnemyStats_341:
    db 98  ; Species: Stubsuck
    dw 300  ; EXP reward
    db 4  ; Joinability (4)
    db 20  ; Level
    dw 80, 120, 40, 30, 30, 100  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 50, 200, 100  ; AI weights
    db $16, $4D, $FF, $FF  ; Skills: SleepAll, ZombieCut, none, none

; --- EID 342 (0x156): Servant Lv55 ---
EnemyStats_342:
    db 173  ; Species: Servant
    dw 0  ; EXP reward
    db 6  ; Joinability (6)
    db 55  ; Level
    dw 300, 350, 380, 220, 306, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 100, 250  ; AI weights
    db $02, $0E, $FF, $FF  ; Skills: Blazemost, Blizzard, none, none

; --- EID 343 (0x157): TERRY? Lv60 ---
EnemyStats_343:
    db 215  ; Species: TERRY?
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 60  ; Level
    dw 2000, 200, 390, 220, 400, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 100, 200  ; AI weights
    db $40, $45, $57, $FF  ; Skills: EvilSlash, BoltSlash, RainSlash, none

; --- EID 344 (0x158): Tatsu Lv30 ---
EnemyStats_344:
    db 216  ; Species: Tatsu
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 30  ; Level
    dw 200, 100, 180, 150, 80, 150  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $2C, $5A, $88, $FF  ; Skills: HealMore, Lightning, Cover, none

; --- EID 345 (0x159): Diago Lv40 ---
EnemyStats_345:
    db 217  ; Species: Diago
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 40  ; Level
    dw 300, 200, 210, 160, 120, 100  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $25, $5E, $7A, $FF  ; Skills: TwinHits, Scorching, SickLick, none

; --- EID 346 (0x15a): Samsi Lv50 ---
EnemyStats_346:
    db 218  ; Species: Samsi
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 50  ; Level
    dw 450, 200, 250, 190, 150, 200  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $40, $55, $57, $FF  ; Skills: EvilSlash, SquallHit, RainSlash, none

; --- EID 347 (0x15b): Bazoo Lv60 ---
EnemyStats_347:
    db 219  ; Species: Bazoo
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 60  ; Level
    dw 700, 400, 350, 300, 100, 250  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $62, $64, $80, $FF  ; Skills: IceStorm, Hellblast, DeMagic, none

; --- EID 348 (0x15c):  Lv50 ---
EnemyStats_348:
    db 220  ; Species: 
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 50  ; Level
    dw 999, 300, 300, 200, 200, 200  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 0, 250  ; AI weights
    db $5F, $63, $80, $FF  ; Skills: WhiteFire, WhiteAir, DeMagic, none

; --- EID 349 (0x15d): DragonKid Lv23 ---
EnemyStats_349:
    db 20  ; Species: DragonKid
    dw 1000  ; EXP reward
    db 4  ; Joinability (4)
    db 23  ; Level
    dw 70, 60, 100, 60, 90, 90  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 150, 250  ; AI weights
    db $5D, $6A, $8C, $FF  ; Skills: BlazeAir, SleepAir, Dodge, none

; --- EID 350 (0x15e): SkyDragon Lv1 ---
EnemyStats_350:
    db 43  ; Species: SkyDragon
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 1  ; Level
    dw 20, 27, 28, 20, 15, 16  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 200, 250  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 351 (0x15f): Slime Lv1 ---
EnemyStats_351:
    db 8  ; Species: Slime
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 1  ; Level
    dw 60, 50, 64, 54, 120, 65  ; HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 100, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 352 (0x160): HammerMan Lv5 ---
EnemyStats_352:
    db 57  ; Species: HammerMan
    dw 70  ; EXP reward
    db 5  ; Joinability (standard)
    db 5  ; Level
    dw 25, 12, 28, 14, 22, 45  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 100, 200  ; AI weights
    db $45, $46, $47, $FF  ; Skills: BoltSlash, VacuSlash, IceSlash, none

; --- EID 353 (0x161): Goategon Lv6 ---
EnemyStats_353:
    db 63  ; Species: Goategon
    dw 80  ; EXP reward
    db 5  ; Joinability (standard)
    db 6  ; Level
    dw 26, 10, 32, 22, 26, 25  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 150, 200  ; AI weights
    db $3B, $3C, $3D, $FF  ; Skills: TwinSlash, Ramming, Beserker, none

; --- EID 354 (0x162): StagBug Lv5 ---
EnemyStats_354:
    db 117  ; Species: StagBug
    dw 83  ; EXP reward
    db 5  ; Joinability (standard)
    db 5  ; Level
    dw 27, 12, 26, 28, 15, 28  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 100, 50, 150  ; AI weights
    db $46, $47, $48, $FF  ; Skills: VacuSlash, IceSlash, MetalCut, none

; --- EID 355 (0x163): SpotKing Lv6 ---
EnemyStats_355:
    db 14  ; Species: SpotKing
    dw 86  ; EXP reward
    db 5  ; Joinability (standard)
    db 6  ; Level
    dw 32, 20, 25, 20, 32, 43  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 100, 250  ; AI weights
    db $50, $52, $57, $FF  ; Skills: BiAttack, CallHelp, RainSlash, none

; --- EID 356 (0x164): LizardFly Lv6 ---
EnemyStats_356:
    db 33  ; Species: LizardFly
    dw 90  ; EXP reward
    db 5  ; Joinability (standard)
    db 6  ; Level
    dw 36, 16, 28, 16, 10, 30  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 200, 50  ; AI weights
    db $5C, $60, $FF, $FF  ; Skills: FireAir, FrigidAir, none, none

; --- EID 357 (0x165): DuckKite Lv5 ---
EnemyStats_357:
    db 74  ; Species: DuckKite
    dw 88  ; EXP reward
    db 5  ; Joinability (standard)
    db 5  ; Level
    dw 22, 24, 25, 21, 31, 34  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 0, 100  ; AI weights
    db $4A, $4B, $D6, $FF  ; Skills: BeastCut, BirdBlow, Smashlime, none

; --- EID 358 (0x166): DarkEye Lv6 ---
EnemyStats_358:
    db 134  ; Species: DarkEye
    dw 81  ; EXP reward
    db 5  ; Joinability (standard)
    db 6  ; Level
    dw 22, 42, 21, 14, 36, 41  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 50, 150, 150  ; AI weights
    db $25, $27, $77, $FF  ; Skills: TwinHits, MagicBack, SideStep, none

; --- EID 359 (0x167): CactiBall Lv6 ---
EnemyStats_359:
    db 94  ; Species: CactiBall
    dw 100  ; EXP reward
    db 5  ; Joinability (standard)
    db 6  ; Level
    dw 32, 37, 25, 24, 17, 38  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 100, 200, 100  ; AI weights
    db $78, $79, $90, $FF  ; Skills: LureDance, LushLicks, BladeD, none

; --- EID 360 (0x168): Snapper Lv5 ---
EnemyStats_360:
    db 107  ; Species: Snapper
    dw 50  ; EXP reward
    db 5  ; Joinability (standard)
    db 5  ; Level
    dw 30, 23, 20, 10, 12, 34  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 250, 200  ; AI weights
    db $12, $20, $72, $FF  ; Skills: Beat, Slow, SandStorm, none

; --- EID 361 (0x169): Reaper Lv6 ---
EnemyStats_361:
    db 168  ; Species: Reaper
    dw 76  ; EXP reward
    db 5  ; Joinability (standard)
    db 6  ; Level
    dw 31, 17, 29, 13, 22, 39  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 0, 150, 100  ; AI weights
    db $17, $91, $92, $FF  ; Skills: StopSpell, DanceShut, MouthShut, none

; --- EID 362 (0x16a): MistyWing Lv6 ---
EnemyStats_362:
    db 77  ; Species: MistyWing
    dw 68  ; EXP reward
    db 5  ; Joinability (standard)
    db 6  ; Level
    dw 35, 34, 16, 24, 32, 30  ; HP, MP, ATK, DEF, AGL, INT
    db 50, 0, 250, 150  ; AI weights
    db $15, $7D, $8A, $FF  ; Skills: Sleep, WarCry, TailWind, none

; --- EID 363 (0x16b): Gasgon Lv5 ---
EnemyStats_363:
    db 23  ; Species: Gasgon
    dw 75  ; EXP reward
    db 5  ; Joinability (standard)
    db 5  ; Level
    dw 26, 6, 34, 25, 14, 32  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 150, 150, 100  ; AI weights
    db $2B, $8C, $FF, $FF  ; Skills: Heal, Dodge, none, none

; --- EID 364 (0x16c): SlimeNite Lv5 ---
EnemyStats_364:
    db 5  ; Species: SlimeNite
    dw 63  ; EXP reward
    db 5  ; Joinability (standard)
    db 5  ; Level
    dw 29, 24, 30, 18, 34, 33  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 100, 50, 250  ; AI weights
    db $1E, $22, $2B, $FF  ; Skills: Upper, Speed, Heal, none

; --- EID 365 (0x16d): TailEater Lv6 ---
EnemyStats_365:
    db 120  ; Species: TailEater
    dw 76  ; EXP reward
    db 5  ; Joinability (standard)
    db 6  ; Level
    dw 23, 20, 21, 20, 24, 28  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 150, 150, 50  ; AI weights
    db $27, $2B, $FF, $FF  ; Skills: MagicBack, Heal, none, none

; --- EID 366 (0x16e): TreeBoy Lv5 ---
EnemyStats_366:
    db 101  ; Species: TreeBoy
    dw 76  ; EXP reward
    db 5  ; Joinability (standard)
    db 5  ; Level
    dw 37, 45, 16, 21, 19, 37  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 150, 200, 200  ; AI weights
    db $0C, $2B, $30, $FF  ; Skills: IceBolt, Heal, Vivify, none

; --- EID 367 (0x16f): AgDevil Lv5 ---
EnemyStats_367:
    db 132  ; Species: AgDevil
    dw 86  ; EXP reward
    db 5  ; Joinability (standard)
    db 5  ; Level
    dw 30, 36, 32, 23, 23, 45  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 150, 200, 200  ; AI weights
    db $3D, $88, $8E, $FF  ; Skills: Beserker, Cover, StrongD, none

; --- EID 368 (0x170): Wyvern Lv12 ---
EnemyStats_368:
    db 71  ; Species: Wyvern
    dw 183  ; EXP reward
    db 5  ; Joinability (standard)
    db 12  ; Level
    dw 46, 32, 52, 28, 48, 84  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 100, 0  ; AI weights
    db $50, $55, $58, $FF  ; Skills: BiAttack, SquallHit, WindBeast, none

; --- EID 369 (0x171): AmberWeed Lv13 ---
EnemyStats_369:
    db 97  ; Species: AmberWeed
    dw 186  ; EXP reward
    db 5  ; Joinability (standard)
    db 13  ; Level
    dw 36, 64, 50, 36, 39, 42  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 0, 150  ; AI weights
    db $03, $4C, $5D, $FF  ; Skills: Firebal, DevilCut, BlazeAir, none

; --- EID 370 (0x172): ArcDemon Lv12 ---
EnemyStats_370:
    db 131  ; Species: ArcDemon
    dw 200  ; EXP reward
    db 5  ; Joinability (standard)
    db 12  ; Level
    dw 48, 46, 53, 42, 18, 88  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 200, 150  ; AI weights
    db $44, $46, $47, $FF  ; Skills: FireSlash, VacuSlash, IceSlash, none

; --- EID 371 (0x173): IceMan Lv12 ---
EnemyStats_371:
    db 193  ; Species: IceMan
    dw 216  ; EXP reward
    db 3  ; Joinability (3)
    db 12  ; Level
    dw 38, 41, 47, 40, 21, 51  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 0, 200  ; AI weights
    db $3F, $55, $D8, $FF  ; Skills: Massacre, SquallHit, Branching, none

; --- EID 372 (0x174): SlimeBorg Lv12 ---
EnemyStats_372:
    db 12  ; Species: SlimeBorg
    dw 203  ; EXP reward
    db 5  ; Joinability (standard)
    db 12  ; Level
    dw 52, 24, 43, 31, 49, 61  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 100, 100, 150  ; AI weights
    db $4E, $56, $7D, $FF  ; Skills: CleanCut, PsycheUp, WarCry, none

; --- EID 373 (0x175): ArmyCrab Lv12 ---
EnemyStats_373:
    db 125  ; Species: ArmyCrab
    dw 190  ; EXP reward
    db 5  ; Joinability (standard)
    db 12  ; Level
    dw 46, 31, 50, 36, 28, 50  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 0, 150, 50  ; AI weights
    db $6F, $75, $D7, $FF  ; Skills: Curse, OddDance, Sheldodge, none

; --- EID 374 (0x176): Shadow Lv13 ---
EnemyStats_374:
    db 162  ; Species: Shadow
    dw 166  ; EXP reward
    db 5  ; Joinability (standard)
    db 13  ; Level
    dw 59, 40, 54, 50, 26, 46  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 200, 150  ; AI weights
    db $15, $1A, $23, $FF  ; Skills: Sleep, RobMagic, SpeedUp, none

; --- EID 375 (0x177): LizardMan Lv13 ---
EnemyStats_375:
    db 25  ; Species: LizardMan
    dw 176  ; EXP reward
    db 5  ; Joinability (standard)
    db 13  ; Level
    dw 55, 34, 52, 34, 32, 48  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 200, 0  ; AI weights
    db $19, $78, $7B, $FF  ; Skills: PanicAll, LureDance, LegSweep, none

; --- EID 376 (0x178): MadHornet Lv13 ---
EnemyStats_376:
    db 126  ; Species: MadHornet
    dw 210  ; EXP reward
    db 6  ; Joinability (6)
    db 13  ; Level
    dw 60, 37, 54, 31, 54, 55  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 200, 250  ; AI weights
    db $6F, $72, $8A, $FF  ; Skills: Curse, SandStorm, TailWind, none

; --- EID 377 (0x179): FireWeed Lv12 ---
EnemyStats_377:
    db 91  ; Species: FireWeed
    dw 153  ; EXP reward
    db 5  ; Joinability (standard)
    db 12  ; Level
    dw 49, 42, 40, 29, 30, 46  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 0, 250, 150  ; AI weights
    db $6E, $79, $7D, $FF  ; Skills: PaniDance, LushLicks, WarCry, none

; --- EID 378 (0x17a): WindMerge Lv12 ---
EnemyStats_378:
    db 167  ; Species: WindMerge
    dw 196  ; EXP reward
    db 5  ; Joinability (standard)
    db 12  ; Level
    dw 44, 45, 38, 40, 40, 51  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 100, 50, 200  ; AI weights
    db $2B, $88, $8A, $FF  ; Skills: Heal, Cover, TailWind, none

; --- EID 379 (0x17b): Orc Lv13 ---
EnemyStats_379:
    db 143  ; Species: Orc
    dw 180  ; EXP reward
    db 5  ; Joinability (standard)
    db 13  ; Level
    dw 51, 29, 36, 25, 44, 57  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 200, 200, 50  ; AI weights
    db $2B, $30, $78, $FF  ; Skills: Heal, Vivify, LureDance, none

; --- EID 380 (0x17c): Droll Lv12 ---
EnemyStats_380:
    db 124  ; Species: Droll
    dw 150  ; EXP reward
    db 5  ; Joinability (standard)
    db 12  ; Level
    dw 39, 50, 40, 28, 31, 55  ; HP, MP, ATK, DEF, AGL, INT
    db 0, 200, 200, 250  ; AI weights
    db $2B, $83, $88, $FF  ; Skills: Heal, ThickFog, Cover, none

; --- EID 381 (0x17d): Phoenix Lv12 ---
EnemyStats_381:
    db 85  ; Species: Phoenix
    dw 193  ; EXP reward
    db 5  ; Joinability (standard)
    db 12  ; Level
    dw 50, 47, 53, 27, 41, 47  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 200, 200, 250  ; AI weights
    db $2B, $5D, $8A, $FF  ; Skills: Heal, BlazeAir, TailWind, none

; --- EID 382 (0x17e): GiantMoth Lv12 ---
EnemyStats_382:
    db 123  ; Species: GiantMoth
    dw 170  ; EXP reward
    db 5  ; Joinability (standard)
    db 12  ; Level
    dw 41, 46, 40, 36, 29, 57  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 150, 200, 100  ; AI weights
    db $2B, $67, $75, $FF  ; Skills: Heal, PoisonHit, OddDance, none

; --- EID 383 (0x17f): Grizzly Lv13 ---
EnemyStats_383:
    db 58  ; Species: Grizzly
    dw 183  ; EXP reward
    db 6  ; Joinability (6)
    db 13  ; Level
    dw 57, 43, 62, 23, 48, 24  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $2B, $3F, $73, $FF  ; Skills: Heal, Massacre, Radiant, none

; --- EID 384 (0x180): WildApe Lv20 ---
EnemyStats_384:
    db 64  ; Species: WildApe
    dw 500  ; EXP reward
    db 5  ; Joinability (standard)
    db 20  ; Level
    dw 65, 46, 78, 38, 51, 47  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 0, 100  ; AI weights
    db $41, $48, $4E, $FF  ; Skills: ChargeUP, MetalCut, CleanCut, none

; --- EID 385 (0x181): Blizzardy Lv20 ---
EnemyStats_385:
    db 84  ; Species: Blizzardy
    dw 513  ; EXP reward
    db 5  ; Joinability (standard)
    db 20  ; Level
    dw 72, 53, 71, 46, 46, 57  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 100, 150  ; AI weights
    db $0A, $3B, $42, $FF  ; Skills: Infermore, TwinSlash, HighJump, none

; --- EID 386 (0x182): EvilWand Lv21 ---
EnemyStats_386:
    db 176  ; Species: EvilWand
    dw 526  ; EXP reward
    db 5  ; Joinability (standard)
    db 21  ; Level
    dw 66, 55, 59, 45, 53, 45  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 200, 100  ; AI weights
    db $01, $07, $41, $FF  ; Skills: Blazemore, Boom, ChargeUP, none

; --- EID 387 (0x183): LavaMan Lv21 ---
EnemyStats_387:
    db 192  ; Species: LavaMan
    dw 546  ; EXP reward
    db 5  ; Joinability (standard)
    db 21  ; Level
    dw 80, 43, 88, 49, 40, 51  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 50, 150  ; AI weights
    db $01, $44, $48, $FF  ; Skills: Blazemore, FireSlash, MetalCut, none

; --- EID 388 (0x184): CurseLamp Lv20 ---
EnemyStats_388:
    db 188  ; Species: CurseLamp
    dw 553  ; EXP reward
    db 5  ; Joinability (standard)
    db 20  ; Level
    dw 60, 70, 62, 50, 42, 59  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 100, 100, 0  ; AI weights
    db $0D, $14, $49, $FF  ; Skills: SnowStorm, Sacrifice, DrakSlash, none

; --- EID 389 (0x185): MadSpirit Lv20 ---
EnemyStats_389:
    db 166  ; Species: MadSpirit
    dw 546  ; EXP reward
    db 5  ; Joinability (standard)
    db 20  ; Level
    dw 63, 68, 85, 55, 64, 60  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 0, 200, 100  ; AI weights
    db $19, $1D, $28, $FF  ; Skills: PanicAll, Defence, Bounce, none

; --- EID 390 (0x186): Gismo Lv21 ---
EnemyStats_390:
    db 191  ; Species: Gismo
    dw 563  ; EXP reward
    db 5  ; Joinability (standard)
    db 21  ; Level
    dw 57, 47, 69, 52, 72, 46  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 150, 100  ; AI weights
    db $16, $21, $6D, $FF  ; Skills: SleepAll, SlowAll, PoisonAir, none

; --- EID 391 (0x187): DeadNite Lv20 ---
EnemyStats_391:
    db 161  ; Species: DeadNite
    dw 516  ; EXP reward
    db 5  ; Joinability (standard)
    db 20  ; Level
    dw 80, 65, 72, 67, 52, 77  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 0, 100, 100  ; AI weights
    db $23, $7D, $91, $FF  ; Skills: SpeedUp, WarCry, DanceShut, none

; --- EID 392 (0x188): RogueNite Lv21 ---
EnemyStats_392:
    db 182  ; Species: RogueNite
    dw 533  ; EXP reward
    db 5  ; Joinability (standard)
    db 21  ; Level
    dw 75, 61, 103, 120, 40, 61  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 200, 200  ; AI weights
    db $1B, $6F, $7A, $FF  ; Skills: TakeMagic, Curse, SickLick, none

; --- EID 393 (0x189): KingCobra Lv21 ---
EnemyStats_393:
    db 35  ; Species: KingCobra
    dw 563  ; EXP reward
    db 5  ; Joinability (standard)
    db 21  ; Level
    dw 100, 39, 80, 72, 110, 41  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 150, 0  ; AI weights
    db $12, $25, $74, $FF  ; Skills: Beat, TwinHits, EerieLite, none

; --- EID 394 (0x18a): Phoenix Lv20 ---
EnemyStats_394:
    db 85  ; Species: Phoenix
    dw 533  ; EXP reward
    db 5  ; Joinability (standard)
    db 20  ; Level
    dw 81, 46, 77, 51, 66, 40  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 150, 0, 150  ; AI weights
    db $2B, $26, $46, $FF  ; Skills: Heal, MagicWall, VacuSlash, none

; --- EID 395 (0x18b): Dragon Lv21 ---
EnemyStats_395:
    db 28  ; Species: Dragon
    dw 563  ; EXP reward
    db 5  ; Joinability (standard)
    db 21  ; Level
    dw 105, 36, 83, 63, 48, 64  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 200, 200, 200  ; AI weights
    db $2B, $52, $88, $FF  ; Skills: Heal, CallHelp, Cover, none

; --- EID 396 (0x18c): Metaly Lv20 ---
EnemyStats_396:
    db 16  ; Species: Metaly
    dw 4000  ; EXP reward
    db 6  ; Joinability (6)
    db 20  ; Level
    dw 10, 200, 45, 300, 250, 66  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 200, 200, 250  ; AI weights
    db $2B, $3F, $89, $FF  ; Skills: Heal, Massacre, Guardian, none

; --- EID 397 (0x18d): LandOwl Lv21 ---
EnemyStats_397:
    db 81  ; Species: LandOwl
    dw 516  ; EXP reward
    db 5  ; Joinability (standard)
    db 21  ; Level
    dw 95, 57, 110, 57, 53, 48  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 200, 200, 250  ; AI weights
    db $0A, $2B, $81, $FF  ; Skills: Infermore, Heal, Surge, none

; --- EID 398 (0x18e): EvilBeast Lv20 ---
EnemyStats_398:
    db 137  ; Species: EvilBeast
    dw 546  ; EXP reward
    db 5  ; Joinability (standard)
    db 20  ; Level
    dw 84, 53, 110, 71, 64, 100  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 0  ; AI weights
    db $0F, $2B, $7C, $FF  ; Skills: Bolt, Heal, BigTrip, none

; --- EID 399 (0x18f): Lipsy Lv20 ---
EnemyStats_399:
    db 116  ; Species: Lipsy
    dw 333  ; EXP reward
    db 5  ; Joinability (standard)
    db 20  ; Level
    dw 52, 43, 46, 46, 36, 57  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $2E, $32, $3E, $FF  ; Skills: HealUs, Farewell, Kamikaze, none

; --- EID 400 (0x190): Lionex Lv26 ---
EnemyStats_400:
    db 141  ; Species: Lionex
    dw 1000  ; EXP reward
    db 5  ; Joinability (standard)
    db 26  ; Level
    dw 110, 70, 100, 106, 122, 117  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 150, 200, 200  ; AI weights
    db $04, $43, $5E, $FF  ; Skills: Firebane, SuckAir, Scorching, none

; --- EID 401 (0x191): Rayburn Lv26 ---
EnemyStats_401:
    db 31  ; Species: Rayburn
    dw 1006  ; EXP reward
    db 5  ; Joinability (standard)
    db 26  ; Level
    dw 93, 55, 104, 62, 136, 65  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 0, 250  ; AI weights
    db $5A, $62, $69, $FF  ; Skills: Lightning, IceStorm, Paralyze, none

; --- EID 402 (0x192): ManEater Lv27 ---
EnemyStats_402:
    db 106  ; Species: ManEater
    dw 1033  ; EXP reward
    db 5  ; Joinability (standard)
    db 27  ; Level
    dw 88, 114, 93, 45, 42, 57  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 150, 200  ; AI weights
    db $10, $5B, $79, $FF  ; Skills: Zap, RockThrow, LushLicks, none

; --- EID 403 (0x193): RotRaven Lv26 ---
EnemyStats_403:
    db 158  ; Species: RotRaven
    dw 1020  ; EXP reward
    db 5  ; Joinability (standard)
    db 26  ; Level
    dw 67, 84, 114, 70, 120, 102  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 100, 0  ; AI weights
    db $12, $46, $50, $FF  ; Skills: Beat, VacuSlash, BiAttack, none

; --- EID 404 (0x194): Ogre Lv27 ---
EnemyStats_404:
    db 144  ; Species: Ogre
    dw 1043  ; EXP reward
    db 5  ; Joinability (standard)
    db 27  ; Level
    dw 134, 72, 120, 107, 52, 115  ; HP, MP, ATK, DEF, AGL, INT
    db 50, 0, 0, 0  ; AI weights
    db $3B, $4A, $59, $FF  ; Skills: TwinSlash, BeastCut, Vacuum, none

; --- EID 405 (0x195): IronTurt Lv26 ---
EnemyStats_405:
    db 55  ; Species: IronTurt
    dw 1020  ; EXP reward
    db 5  ; Joinability (standard)
    db 26  ; Level
    dw 140, 60, 130, 100, 61, 91  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 100, 100, 100  ; AI weights
    db $14, $24, $84, $FF  ; Skills: Sacrifice, Barrier, TatsuCall, none

; --- EID 406 (0x196): Copycat Lv26 ---
EnemyStats_406:
    db 174  ; Species: Copycat
    dw 1066  ; EXP reward
    db 5  ; Joinability (standard)
    db 26  ; Level
    dw 55, 45, 82, 61, 64, 57  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 150, 150, 50  ; AI weights
    db $26, $7F, $83, $FF  ; Skills: MagicWall, Imitate, ThickFog, none

; --- EID 407 (0x197): DarkCrab Lv25 ---
EnemyStats_407:
    db 160  ; Species: DarkCrab
    dw 1006  ; EXP reward
    db 5  ; Joinability (standard)
    db 25  ; Level
    dw 130, 64, 136, 111, 54, 70  ; HP, MP, ATK, DEF, AGL, INT
    db 50, 0, 150, 250  ; AI weights
    db $17, $76, $7A, $FF  ; Skills: StopSpell, RobDance, SickLick, none

; --- EID 408 (0x198): WingSnake Lv26 ---
EnemyStats_408:
    db 39  ; Species: WingSnake
    dw 1060  ; EXP reward
    db 5  ; Joinability (standard)
    db 26  ; Level
    dw 132, 77, 120, 89, 85, 78  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 50, 100, 100  ; AI weights
    db $1D, $6E, $D8, $FF  ; Skills: Defence, PaniDance, Branching, none

; --- EID 409 (0x199): DanceVegi Lv25 ---
EnemyStats_409:
    db 100  ; Species: DanceVegi
    dw 1066  ; EXP reward
    db 5  ; Joinability (standard)
    db 25  ; Level
    dw 83, 61, 59, 120, 156, 85  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $25, $78, $92, $FF  ; Skills: TwinHits, LureDance, MouthShut, none

; --- EID 410 (0x19a): Grendal Lv26 ---
EnemyStats_410:
    db 147  ; Species: Grendal
    dw 996  ; EXP reward
    db 5  ; Joinability (standard)
    db 26  ; Level
    dw 99, 41, 135, 155, 112, 113  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 150, 150, 100  ; AI weights
    db $2C, $56, $95, $FF  ; Skills: HealMore, PsycheUp, LifeSong, none

; --- EID 411 (0x19b): JewelBag Lv25 ---
EnemyStats_411:
    db 175  ; Species: JewelBag
    dw 1050  ; EXP reward
    db 5  ; Joinability (standard)
    db 25  ; Level
    dw 68, 76, 123, 126, 40, 130  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 200, 200, 50  ; AI weights
    db $2E, $77, $85, $FF  ; Skills: HealUs, SideStep, DiagoCall, none

; --- EID 412 (0x19c): Phoenix Lv26 ---
EnemyStats_412:
    db 85  ; Species: Phoenix
    dw 1040  ; EXP reward
    db 5  ; Joinability (standard)
    db 26  ; Level
    dw 110, 65, 125, 70, 100, 75  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 100, 100, 250  ; AI weights
    db $52, $6D, $94, $FF  ; Skills: CallHelp, PoisonAir, Hustle, none

; --- EID 413 (0x19d): Goategon Lv25 ---
EnemyStats_413:
    db 63  ; Species: Goategon
    dw 1023  ; EXP reward
    db 5  ; Joinability (standard)
    db 25  ; Level
    dw 133, 107, 155, 82, 98, 128  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 150, 200, 150  ; AI weights
    db $2D, $30, $55, $FF  ; Skills: HealAll, Vivify, SquallHit, none

; --- EID 414 (0x19e): FaceTree Lv26 ---
EnemyStats_414:
    db 102  ; Species: FaceTree
    dw 1040  ; EXP reward
    db 5  ; Joinability (standard)
    db 26  ; Level
    dw 125, 119, 67, 74, 51, 86  ; HP, MP, ATK, DEF, AGL, INT
    db 50, 0, 50, 0  ; AI weights
    db $26, $89, $D7, $FF  ; Skills: MagicWall, Guardian, Sheldodge, none

; --- EID 415 (0x19f): Swordgon Lv25 ---
EnemyStats_415:
    db 27  ; Species: Swordgon
    dw 1093  ; EXP reward
    db 5  ; Joinability (standard)
    db 25  ; Level
    dw 126, 95, 95, 128, 46, 67  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 200, 200, 250  ; AI weights
    db $10, $1F, $2C, $FF  ; Skills: Zap, Increase, HealMore, none

; --- EID 416 (0x1a0): SuperTen Lv33 ---
EnemyStats_416:
    db 54  ; Species: SuperTen
    dw 1666  ; EXP reward
    db 5  ; Joinability (standard)
    db 33  ; Level
    dw 156, 60, 77, 60, 136, 78  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 0, 100, 200  ; AI weights
    db $05, $44, $51, $FF  ; Skills: Firebolt, FireSlash, QuadHits, none

; --- EID 417 (0x1a1): MadMirror Lv33 ---
EnemyStats_417:
    db 181  ; Species: MadMirror
    dw 1666  ; EXP reward
    db 5  ; Joinability (standard)
    db 33  ; Level
    dw 164, 62, 71, 64, 170, 120  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 50, 250  ; AI weights
    db $07, $4B, $57, $FF  ; Skills: Boom, BirdBlow, RainSlash, none

; --- EID 418 (0x1a2): Yeti Lv34 ---
EnemyStats_418:
    db 59  ; Species: Yeti
    dw 1706  ; EXP reward
    db 5  ; Joinability (standard)
    db 34  ; Level
    dw 198, 110, 170, 170, 80, 94  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 150, 100, 100  ; AI weights
    db $0B, $42, $59, $FF  ; Skills: Infermost, HighJump, Vacuum, none

; --- EID 419 (0x1a3): Skullgon Lv33 ---
EnemyStats_419:
    db 156  ; Species: Skullgon
    dw 1720  ; EXP reward
    db 5  ; Joinability (standard)
    db 33  ; Level
    dw 164, 63, 132, 174, 85, 169  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 50, 250  ; AI weights
    db $02, $3B, $55, $FF  ; Skills: Blazemost, TwinSlash, SquallHit, none

; --- EID 420 (0x1a4): Centasaur Lv33 ---
EnemyStats_420:
    db 151  ; Species: Centasaur
    dw 1756  ; EXP reward
    db 5  ; Joinability (standard)
    db 33  ; Level
    dw 200, 126, 225, 270, 320, 220  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 50, 150  ; AI weights
    db $14, $59, $67, $FF  ; Skills: Sacrifice, Vacuum, PoisonHit, none

; --- EID 421 (0x1a5): EvilArmor Lv34 ---
EnemyStats_421:
    db 152  ; Species: EvilArmor
    dw 1716  ; EXP reward
    db 5  ; Joinability (standard)
    db 34  ; Level
    dw 185, 102, 229, 420, 135, 148  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 250, 100  ; AI weights
    db $16, $24, $57, $FF  ; Skills: SleepAll, Barrier, RainSlash, none

; --- EID 422 (0x1a6): Voodoll Lv33 ---
EnemyStats_422:
    db 184  ; Species: Voodoll
    dw 1760  ; EXP reward
    db 5  ; Joinability (standard)
    db 33  ; Level
    dw 154, 148, 168, 164, 120, 133  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 50, 150, 200  ; AI weights
    db $28, $6D, $7D, $FF  ; Skills: Bounce, PoisonAir, WarCry, none

; --- EID 423 (0x1a7): Golem Lv33 ---
EnemyStats_423:
    db 196  ; Species: Golem
    dw 1723  ; EXP reward
    db 5  ; Joinability (standard)
    db 33  ; Level
    dw 210, 59, 108, 182, 52, 192  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 100, 100, 250  ; AI weights
    db $6E, $76, $94, $FF  ; Skills: PaniDance, RobDance, Hustle, none

; --- EID 424 (0x1a8): LavaMan Lv33 ---
EnemyStats_424:
    db 192  ; Species: LavaMan
    dw 1713  ; EXP reward
    db 5  ; Joinability (standard)
    db 33  ; Level
    dw 180, 63, 158, 179, 87, 101  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 200, 150  ; AI weights
    db $6F, $74, $86, $FF  ; Skills: Curse, EerieLite, SamsiCall, none

; --- EID 425 (0x1a9): Blizzardy Lv33 ---
EnemyStats_425:
    db 84  ; Species: Blizzardy
    dw 1746  ; EXP reward
    db 5  ; Joinability (standard)
    db 33  ; Level
    dw 182, 103, 121, 116, 152, 107  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 100, 200, 150  ; AI weights
    db $72, $7A, $8B, $FF  ; Skills: SandStorm, SickLick, StormWind, none

; --- EID 426 (0x1aa): MadCat Lv34 ---
EnemyStats_426:
    db 68  ; Species: MadCat
    dw 1726  ; EXP reward
    db 5  ; Joinability (standard)
    db 34  ; Level
    dw 166, 64, 159, 124, 163, 107  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 150, 150, 250  ; AI weights
    db $2C, $47, $78, $FF  ; Skills: HealMore, IceSlash, LureDance, none

; --- EID 427 (0x1ab): StoneMan Lv34 ---
EnemyStats_427:
    db 197  ; Species: StoneMan
    dw 1740  ; EXP reward
    db 5  ; Joinability (standard)
    db 34  ; Level
    dw 220, 96, 147, 220, 71, 125  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 150, 200, 200  ; AI weights
    db $05, $2E, $8F, $FF  ; Skills: Firebolt, HealUs, SuckAll, none

; --- EID 428 (0x1ac): BigEye Lv33 ---
EnemyStats_428:
    db 69  ; Species: BigEye
    dw 1703  ; EXP reward
    db 5  ; Joinability (standard)
    db 33  ; Level
    dw 155, 134, 162, 122, 137, 100  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $2E, $32, $42, $FF  ; Skills: HealUs, Farewell, HighJump, none

; --- EID 429 (0x1ad): Metaly Lv30 ---
EnemyStats_429:
    db 16  ; Species: Metaly
    dw 6076  ; EXP reward
    db 6  ; Joinability (6)
    db 30  ; Level
    dw 15, 300, 65, 400, 350, 86  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 200, 250, 100  ; AI weights
    db $2B, $3E, $8F, $FF  ; Skills: Heal, Kamikaze, SuckAll, none

; --- EID 430 (0x1ae): Gasgon Lv34 ---
EnemyStats_430:
    db 23  ; Species: Gasgon
    dw 1746  ; EXP reward
    db 5  ; Joinability (standard)
    db 34  ; Level
    dw 164, 58, 67, 117, 80, 97  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 100, 0  ; AI weights
    db $2C, $53, $8F, $FF  ; Skills: HealMore, YellHelp, SuckAll, none

; --- EID 431 (0x1af): Gigantes Lv33 ---
EnemyStats_431:
    db 150  ; Species: Gigantes
    dw 1730  ; EXP reward
    db 5  ; Joinability (standard)
    db 33  ; Level
    dw 210, 20, 226, 84, 128, 18  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 100, 100, 100  ; AI weights
    db $7F, $89, $D6, $FF  ; Skills: Imitate, Guardian, Smashlime, none

; --- EID 432 (0x1b0): Skeletor Lv39 ---
EnemyStats_432:
    db 172  ; Species: Skeletor
    dw 3433  ; EXP reward
    db 5  ; Joinability (standard)
    db 39  ; Level
    dw 145, 160, 272, 224, 128, 166  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 50, 150  ; AI weights
    db $4B, $54, $D7, $FF  ; Skills: BirdBlow, Focus, Sheldodge, none

; --- EID 433 (0x1b1): Snapper Lv40 ---
EnemyStats_433:
    db 107  ; Species: Snapper
    dw 3520  ; EXP reward
    db 5  ; Joinability (standard)
    db 40  ; Level
    dw 186, 161, 234, 124, 127, 118  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 100, 200  ; AI weights
    db $43, $5F, $D8, $FF  ; Skills: SuckAir, WhiteFire, Branching, none

; --- EID 434 (0x1b2): LavaMan Lv38 ---
EnemyStats_434:
    db 192  ; Species: LavaMan
    dw 3546  ; EXP reward
    db 5  ; Joinability (standard)
    db 38  ; Level
    dw 190, 113, 198, 159, 140, 101  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 50, 150  ; AI weights
    db $11, $3B, $55, $FF  ; Skills: Thordain, TwinSlash, SquallHit, none

; --- EID 435 (0x1b3): Phoenix Lv40 ---
EnemyStats_435:
    db 85  ; Species: Phoenix
    dw 3533  ; EXP reward
    db 5  ; Joinability (standard)
    db 40  ; Level
    dw 181, 116, 177, 121, 155, 81  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 0, 150  ; AI weights
    db $4C, $68, $87, $FF  ; Skills: DevilCut, NapAttack, BazooCall, none

; --- EID 436 (0x1b4): KingSlime Lv38 ---
EnemyStats_436:
    db 15  ; Species: KingSlime
    dw 3483  ; EXP reward
    db 5  ; Joinability (standard)
    db 38  ; Level
    dw 250, 94, 218, 181, 206, 200  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 150, 0, 200  ; AI weights
    db $0E, $40, $49, $FF  ; Skills: Blizzard, EvilSlash, DrakSlash, none

; --- EID 437 (0x1b5): MadPecker Lv38 ---
EnemyStats_437:
    db 75  ; Species: MadPecker
    dw 3516  ; EXP reward
    db 5  ; Joinability (standard)
    db 38  ; Level
    dw 139, 88, 197, 115, 186, 127  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 200, 100  ; AI weights
    db $16, $25, $4A, $FF  ; Skills: SleepAll, TwinHits, BeastCut, none

; --- EID 438 (0x1b6): BombCrag Lv40 ---
EnemyStats_438:
    db 198  ; Species: BombCrag
    dw 3496  ; EXP reward
    db 5  ; Joinability (standard)
    db 40  ; Level
    dw 260, 174, 156, 233, 20, 134  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 150, 0  ; AI weights
    db $29, $6B, $7C, $FF  ; Skills: Transform, PalsyAir, BigTrip, none

; --- EID 439 (0x1b7): FangSlime Lv33 ---
EnemyStats_439:
    db 10  ; Species: FangSlime
    dw 3553  ; EXP reward
    db 5  ; Joinability (standard)
    db 33  ; Level
    dw 184, 78, 166, 151, 311, 141  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 0, 200, 250  ; AI weights
    db $1F, $74, $7D, $FF  ; Skills: Increase, EerieLite, WarCry, none

; --- EID 440 (0x1b8): ZapBird Lv39 ---
EnemyStats_440:
    db 86  ; Species: ZapBird
    dw 3583  ; EXP reward
    db 5  ; Joinability (standard)
    db 39  ; Level
    dw 224, 87, 187, 167, 210, 222  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 100, 100, 50  ; AI weights
    db $82, $91, $92, $FF  ; Skills: UltraDown, DanceShut, MouthShut, none

; --- EID 441 (0x1b9): Spikerous Lv28 ---
EnemyStats_441:
    db 36  ; Species: Spikerous
    dw 3466  ; EXP reward
    db 5  ; Joinability (standard)
    db 28  ; Level
    dw 204, 18, 177, 300, 81, 104  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 200, 200, 100  ; AI weights
    db $28, $67, $83, $FF  ; Skills: Bounce, PoisonHit, ThickFog, none

; --- EID 442 (0x1ba): Centasaur Lv40 ---
EnemyStats_442:
    db 151  ; Species: Centasaur
    dw 3540  ; EXP reward
    db 5  ; Joinability (standard)
    db 40  ; Level
    dw 251, 124, 290, 352, 338, 211  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 200, 200, 200  ; AI weights
    db $30, $44, $70, $FF  ; Skills: Vivify, FireSlash, Ahhh, none

; --- EID 443 (0x1bb): BombCrag Lv39 ---
EnemyStats_443:
    db 198  ; Species: BombCrag
    dw 3483  ; EXP reward
    db 5  ; Joinability (standard)
    db 39  ; Level
    dw 210, 157, 138, 239, 18, 132  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 100, 100, 150  ; AI weights
    db $46, $81, $92, $FF  ; Skills: VacuSlash, Surge, MouthShut, none

; --- EID 444 (0x1bc): SkyDragon Lv33 ---
EnemyStats_444:
    db 43  ; Species: SkyDragon
    dw 3516  ; EXP reward
    db 5  ; Joinability (standard)
    db 33  ; Level
    dw 165, 164, 198, 175, 123, 112  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $14, $23, $31, $FF  ; Skills: Sacrifice, SpeedUp, Revive, none

; --- EID 445 (0x1bd): BattleRex Lv39 ---
EnemyStats_445:
    db 42  ; Species: BattleRex
    dw 3473  ; EXP reward
    db 5  ; Joinability (standard)
    db 39  ; Level
    dw 187, 122, 286, 187, 200, 141  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 150, 150, 0  ; AI weights
    db $63, $6F, $94, $FF  ; Skills: WhiteAir, Curse, Hustle, none

; --- EID 446 (0x1be): FunkyBird Lv39 ---
EnemyStats_446:
    db 88  ; Species: FunkyBird
    dw 3540  ; EXP reward
    db 5  ; Joinability (standard)
    db 39  ; Level
    dw 178, 197, 151, 227, 143, 198  ; HP, MP, ATK, DEF, AGL, INT
    db 50, 50, 50, 0  ; AI weights
    db $1F, $2E, $5A, $FF  ; Skills: Increase, HealUs, Lightning, none

; --- EID 447 (0x1bf): StoneMan Lv40 ---
EnemyStats_447:
    db 197  ; Species: StoneMan
    dw 3496  ; EXP reward
    db 5  ; Joinability (standard)
    db 40  ; Level
    dw 222, 126, 199, 257, 107, 184  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 100, 100, 100  ; AI weights
    db $17, $87, $89, $FF  ; Skills: StopSpell, BazooCall, Guardian, none

; --- EID 448 (0x1c0): GulpBeast Lv38 ---
EnemyStats_448:
    db 50  ; Species: GulpBeast
    dw 7140  ; EXP reward
    db 6  ; Joinability (6)
    db 38  ; Level
    dw 340, 90, 300, 185, 150, 90  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 100, 50  ; AI weights
    db $0E, $42, $4D, $FF  ; Skills: Blizzard, HighJump, ZombieCut, none

; --- EID 449 (0x1c1): GreatDrak Lv45 ---
EnemyStats_449:
    db 37  ; Species: GreatDrak
    dw 7260  ; EXP reward
    db 6  ; Joinability (6)
    db 45  ; Level
    dw 350, 130, 240, 210, 170, 210  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 50, 200  ; AI weights
    db $0B, $41, $D6, $FF  ; Skills: Infermost, ChargeUP, Smashlime, none

; --- EID 450 (0x1c2): Trumpeter Lv45 ---
EnemyStats_450:
    db 65  ; Species: Trumpeter
    dw 7480  ; EXP reward
    db 6  ; Joinability (6)
    db 45  ; Level
    dw 190, 150, 330, 210, 190, 130  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 50, 100, 200  ; AI weights
    db $02, $45, $4C, $FF  ; Skills: Blazemost, BoltSlash, DevilCut, none

; --- EID 451 (0x1c3): MetalDrak Lv43 ---
EnemyStats_451:
    db 185  ; Species: MetalDrak
    dw 7836  ; EXP reward
    db 6  ; Joinability (6)
    db 43  ; Level
    dw 310, 105, 240, 220, 250, 130  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 50, 50, 100  ; AI weights
    db $08, $40, $47, $FF  ; Skills: Explodet, EvilSlash, IceSlash, none

; --- EID 452 (0x1c4): ZapBird Lv45 ---
EnemyStats_452:
    db 86  ; Species: ZapBird
    dw 7933  ; EXP reward
    db 6  ; Joinability (6)
    db 45  ; Level
    dw 260, 120, 210, 200, 240, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 150, 100  ; AI weights
    db $3F, $46, $59, $FF  ; Skills: Massacre, VacuSlash, Vacuum, none

; --- EID 453 (0x1c5): WhipBird Lv45 ---
EnemyStats_453:
    db 87  ; Species: WhipBird
    dw 7273  ; EXP reward
    db 6  ; Joinability (6)
    db 45  ; Level
    dw 480, 200, 150, 250, 240, 230  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 200, 150, 250  ; AI weights
    db $32, $51, $72, $FF  ; Skills: Farewell, QuadHits, SandStorm, none

; --- EID 454 (0x1c6): Metabble Lv38 ---
EnemyStats_454:
    db 17  ; Species: Metabble
    dw 30376  ; EXP reward
    db 6  ; Joinability (6)
    db 38  ; Level
    dw 23, 490, 190, 670, 511, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 50, 150, 0  ; AI weights
    db $28, $3C, $53, $FF  ; Skills: Bounce, Ramming, YellHelp, none

; --- EID 455 (0x1c7): Balzak Lv33 ---
EnemyStats_455:
    db 186  ; Species: Balzak
    dw 7783  ; EXP reward
    db 6  ; Joinability (6)
    db 33  ; Level
    dw 330, 165, 210, 320, 280, 180  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 100, 200, 250  ; AI weights
    db $16, $69, $78, $FF  ; Skills: SleepAll, Paralyze, LureDance, none

; --- EID 456 (0x1c8): MadDragon Lv33 ---
EnemyStats_456:
    db 30  ; Species: MadDragon
    dw 7176  ; EXP reward
    db 6  ; Joinability (6)
    db 33  ; Level
    dw 200, 24, 335, 130, 190, 30  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 200, 150  ; AI weights
    db $43, $63, $92, $FF  ; Skills: SuckAir, WhiteAir, MouthShut, none

; --- EID 457 (0x1c9): GoatHorn Lv33 ---
EnemyStats_457:
    db 142  ; Species: GoatHorn
    dw 7200  ; EXP reward
    db 6  ; Joinability (6)
    db 33  ; Level
    dw 150, 190, 220, 150, 190, 240  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 150, 250, 0  ; AI weights
    db $1D, $6F, $7A, $FF  ; Skills: Defence, Curse, SickLick, none

; --- EID 458 (0x1ca): DeadNoble Lv46 ---
EnemyStats_458:
    db 169  ; Species: DeadNoble
    dw 7540  ; EXP reward
    db 6  ; Joinability (6)
    db 46  ; Level
    dw 340, 240, 340, 280, 280, 215  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 250, 200, 200  ; AI weights
    db $2D, $44, $8C, $FF  ; Skills: HealAll, FireSlash, Dodge, none

; --- EID 459 (0x1cb): Roboster Lv38 ---
EnemyStats_459:
    db 189  ; Species: Roboster
    dw 7033  ; EXP reward
    db 6  ; Joinability (6)
    db 38  ; Level
    dw 280, 245, 340, 230, 360, 210  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 50  ; AI weights
    db $2E, $4F, $8B, $FF  ; Skills: HealUs, MultiCut, StormWind, none

; --- EID 460 (0x1cc): Andreal Lv45 ---
EnemyStats_460:
    db 34  ; Species: Andreal
    dw 7116  ; EXP reward
    db 6  ; Joinability (6)
    db 45  ; Level
    dw 340, 280, 200, 320, 200, 250  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 200, 200  ; AI weights
    db $31, $81, $8F, $FF  ; Skills: Revive, Surge, SuckAll, none

; --- EID 461 (0x1cd): Unicorn Lv45 ---
EnemyStats_461:
    db 62  ; Species: Unicorn
    dw 9506  ; EXP reward
    db 6  ; Joinability (6)
    db 45  ; Level
    dw 200, 330, 200, 150, 290, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 250, 250, 250  ; AI weights
    db $55, $78, $89, $FF  ; Skills: SquallHit, LureDance, Guardian, none

; --- EID 462 (0x1ce): Digster Lv46 ---
EnemyStats_462:
    db 129  ; Species: Digster
    dw 7033  ; EXP reward
    db 6  ; Joinability (6)
    db 46  ; Level
    dw 267, 115, 197, 257, 110, 185  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 150, 150, 50  ; AI weights
    db $94, $96, $D8, $FF  ; Skills: Hustle, LifeDance, Branching, none

; --- EID 463 (0x1cf): Copycat Lv38 ---
EnemyStats_463:
    db 174  ; Species: Copycat
    dw 7513  ; EXP reward
    db 6  ; Joinability (6)
    db 38  ; Level
    dw 210, 210, 120, 167, 138, 200  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $29, $3E, $63, $FF  ; Skills: Transform, Kamikaze, WhiteAir, none

; --- EID 464 (0x1d0): GreatDrak Lv50 ---
EnemyStats_464:
    db 37  ; Species: GreatDrak
    dw 13400  ; EXP reward
    db 6  ; Joinability (6)
    db 50  ; Level
    dw 370, 150, 250, 220, 190, 230  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $25, $4F, $7A, $FF  ; Skills: TwinHits, MultiCut, SickLick, none

; --- EID 465 (0x1d1): Roboster Lv38 ---
EnemyStats_465:
    db 189  ; Species: Roboster
    dw 13500  ; EXP reward
    db 6  ; Joinability (6)
    db 38  ; Level
    dw 300, 260, 350, 240, 380, 250  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $2C, $54, $55, $FF  ; Skills: HealMore, Focus, SquallHit, none

; --- EID 466 (0x1d2): Balzak Lv33 ---
EnemyStats_466:
    db 186  ; Species: Balzak
    dw 13666  ; EXP reward
    db 6  ; Joinability (6)
    db 33  ; Level
    dw 380, 190, 240, 340, 300, 210  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $11, $2E, $83, $FF  ; Skills: Thordain, HealUs, ThickFog, none

; --- EID 467 (0x1d3): WhipBird Lv50 ---
EnemyStats_467:
    db 87  ; Species: WhipBird
    dw 13616  ; EXP reward
    db 6  ; Joinability (6)
    db 50  ; Level
    dw 500, 200, 180, 260, 250, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $40, $87, $94, $FF  ; Skills: EvilSlash, BazooCall, Hustle, none

; --- EID 468 (0x1d4): MetalDrak Lv43 ---
EnemyStats_468:
    db 185  ; Species: MetalDrak
    dw 13373  ; EXP reward
    db 6  ; Joinability (6)
    db 43  ; Level
    dw 330, 120, 260, 240, 250, 160  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $39, $6E, $7C, $FF  ; Skills: Chance, PaniDance, BigTrip, none

; --- EID 469 (0x1d5): GateGuard Lv48 ---
EnemyStats_469:
    db 145  ; Species: GateGuard
    dw 13516  ; EXP reward
    db 6  ; Joinability (6)
    db 48  ; Level
    dw 340, 300, 330, 210, 150, 210  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $63, $7F, $89, $FF  ; Skills: WhiteAir, Imitate, Guardian, none

; --- EID 470 (0x1d6): ChopClown Lv48 ---
EnemyStats_470:
    db 146  ; Species: ChopClown
    dw 13600  ; EXP reward
    db 6  ; Joinability (6)
    db 48  ; Level
    dw 310, 300, 300, 200, 260, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $14, $54, $93, $FF  ; Skills: Sacrifice, Focus, Meditate, none

; --- EID 471 (0x1d7): MetalKing Lv50 ---
EnemyStats_471:
    db 18  ; Species: MetalKing
    dw 30376  ; EXP reward
    db 6  ; Joinability (6)
    db 50  ; Level
    dw 25, 700, 290, 700, 511, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $68, $89, $96, $FF  ; Skills: NapAttack, Guardian, LifeDance, none

; --- EID 472 (0x1d8): Orochi Lv50 ---
EnemyStats_472:
    db 41  ; Species: Orochi
    dw 13440  ; EXP reward
    db 6  ; Joinability (6)
    db 50  ; Level
    dw 360, 150, 360, 350, 200, 180  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $13, $78, $94, $FF  ; Skills: Defeat, LureDance, Hustle, none

; --- EID 473 (0x1d9): Trumpeter Lv48 ---
EnemyStats_473:
    db 65  ; Species: Trumpeter
    dw 13600  ; EXP reward
    db 6  ; Joinability (6)
    db 48  ; Level
    dw 220, 170, 250, 220, 210, 150  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $08, $7D, $91, $FF  ; Skills: Explodet, WarCry, DanceShut, none

; --- EID 474 (0x1da): Snapper Lv50 ---
EnemyStats_474:
    db 107  ; Species: Snapper
    dw 13650  ; EXP reward
    db 6  ; Joinability (6)
    db 50  ; Level
    dw 250, 210, 250, 160, 160, 200  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $42, $4F, $7A, $FF  ; Skills: HighJump, MultiCut, SickLick, none

; --- EID 475 (0x1db): HornBeet Lv48 ---
EnemyStats_475:
    db 127  ; Species: HornBeet
    dw 13556  ; EXP reward
    db 6  ; Joinability (6)
    db 48  ; Level
    dw 380, 190, 240, 250, 300, 200  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $67, $72, $93, $FF  ; Skills: PoisonHit, SandStorm, Meditate, none

; --- EID 476 (0x1dc): DeadNoble Lv48 ---
EnemyStats_476:
    db 169  ; Species: DeadNoble
    dw 13526  ; EXP reward
    db 6  ; Joinability (6)
    db 48  ; Level
    dw 340, 350, 350, 190, 290, 230  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $66, $77, $8E, $FF  ; Skills: MegaMagic, SideStep, StrongD, none

; --- EID 477 (0x1dd): Servant Lv50 ---
EnemyStats_477:
    db 173  ; Species: Servant
    dw 13573  ; EXP reward
    db 6  ; Joinability (6)
    db 50  ; Level
    dw 240, 340, 210, 320, 290, 250  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $5F, $6F, $8B, $FF  ; Skills: WhiteFire, Curse, StormWind, none

; --- EID 478 (0x1de): StoneMan Lv48 ---
EnemyStats_478:
    db 197  ; Species: StoneMan
    dw 13416  ; EXP reward
    db 6  ; Joinability (6)
    db 48  ; Level
    dw 360, 160, 240, 360, 100, 200  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $43, $63, $74, $FF  ; Skills: SuckAir, WhiteAir, EerieLite, none

; --- EID 479 (0x1df): BombCrag Lv48 ---
EnemyStats_479:
    db 198  ; Species: BombCrag
    dw 13630  ; EXP reward
    db 6  ; Joinability (6)
    db 48  ; Level
    dw 290, 200, 180, 260, 20, 150  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 250, 250, 250  ; AI weights
    db $57, $7F, $D5, $FF  ; Skills: RainSlash, Imitate, BeDragon, none

; --- EID 480 (0x1e0): Slime Lv1 ---
EnemyStats_480:
    db 8  ; Species: Slime
    dw 65000  ; EXP reward
    db 1  ; Joinability (1)
    db 1  ; Level
    dw 2, 0, 2, 2, 2, 2  ; HP, MP, ATK, DEF, AGL, INT
    db 100, 100, 100, 100  ; AI weights
    db $FF, $FF, $FF, $FF  ; Skills: none, none, none, none

; --- EID 481 (0x1e1): GoldSlime Lv70 ---
EnemyStats_481:
    db 19  ; Species: GoldSlime
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 70  ; Level
    dw 900, 600, 400, 999, 411, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 0, 250, 0, 250  ; AI weights
    db $2E, $31, $81, $FF  ; Skills: HealUs, Revive, Surge, none

; --- EID 482 (0x1e2): Divinegon Lv70 ---
EnemyStats_482:
    db 44  ; Species: Divinegon
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 70  ; Level
    dw 6500, 999, 700, 400, 280, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 0, 250, 250  ; AI weights
    db $40, $54, $64, $FF  ; Skills: EvilSlash, Focus, Hellblast, none

; --- EID 483 (0x1e3): Rosevine Lv70 ---
EnemyStats_483:
    db 108  ; Species: Rosevine
    dw 0  ; EXP reward
    db 7  ; Joinability (never)
    db 70  ; Level
    dw 1800, 999, 600, 500, 400, 255  ; HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 250, 250  ; AI weights
    db $7F, $80, $8B, $FF  ; Skills: Imitate, DeMagic, StormWind, none

; --- EID 484 (0x1e4): Dragon Lv6 ---
EnemyStats_484:
    db 28  ; Species: Dragon
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 6  ; Level
    dw 60, 20, 40, 25, 20, 30  ; HP, MP, ATK, DEF, AGL, INT
    db 250, 50, 0, 250  ; AI weights
    db $44, $5C, $FF, $FF  ; Skills: FireSlash, FireAir, none, none

; --- EID 485 (0x1e5): Golem Lv7 ---
EnemyStats_485:
    db 196  ; Species: Golem
    dw 0  ; EXP reward
    db 0  ; Joinability (always)
    db 7  ; Level
    dw 80, 20, 45, 35, 15, 70  ; HP, MP, ATK, DEF, AGL, INT
    db 150, 150, 150, 200  ; AI weights
    db $41, $56, $8E, $FF  ; Skills: ChargeUP, PsycheUp, StrongD, none

; --- EID 486 (0x1e6): Dracky Lv1 ---
EnemyStats_486:
    db 78  ; Species: Dracky
    dw 4  ; EXP reward
    db 1  ; Joinability (1)
    db 1  ; Level
    dw 14, 20, 12, 4, 12, 14  ; HP, MP, ATK, DEF, AGL, INT
    db 200, 0, 0, 200  ; AI weights
    db $33, $FF, $FF, $FF  ; Skills: Antidote, none, none, none

label14_7bac:
    ld a, [$da5e]
    cp $ff
    ret z

    cp $2b
    jp z, Jump_014_7bf4

    cp $2c
    jp z, Jump_014_7bf4

    cp $2d
    jp z, Jump_014_7bf4

    cp $2e
    jp z, Jump_014_7c1b

    cp $2f
    jp z, Jump_014_7c1b

    cp $30
    jp z, Jump_014_7c9b

    cp $31
    jp z, Jump_014_7c9b

    cp $33
    jp z, Jump_014_7cad

    cp $36
    jp z, Jump_014_7cc3

    cp $37
    jp z, Jump_014_7cd9

    cp $38
    jp z, Jump_014_7ce5

    cp $7e
    jp z, Jump_014_7cf5

    ld a, $ff
    ld [$da5e], a
    ret


Jump_014_7bf4:
    call Call_014_7d00
    ret nz

    ld a, [$da60]
    ld hl, $cb13
    call Call_000_224f

Call_014_7c01:
    push bc
    ld a, [$da60]
    ld hl, $cb11
    call Call_000_224f
    pop hl
    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    ld a, h
    or l
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


Jump_014_7c1b:
    ld a, [$ca8d]
    or a
    jr z, jr_014_7c95

    ld a, $00
    call Call_014_7d03
    jr nz, jr_014_7c4a

    ld a, $00
    ld hl, $cb13
    call Call_000_224f
    push bc
    ld a, $00
    ld hl, $cb11
    call Call_000_224f
    pop hl
    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    ld a, h
    or l
    ret nz

    ld a, [$ca8d]
    cp $01
    jr z, jr_014_7c95

jr_014_7c4a:
    ld a, $01
    call Call_014_7d03
    jr nz, jr_014_7c73

    ld a, $01
    ld hl, $cb13
    call Call_000_224f
    push bc
    ld a, $01
    ld hl, $cb11
    call Call_000_224f
    pop hl
    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    ld a, h
    or l
    ret nz

    ld a, [$ca8d]
    cp $02
    jr z, jr_014_7c95

jr_014_7c73:
    ld a, $02
    call Call_014_7d03
    jr nz, jr_014_7c95

    ld a, $02
    ld hl, $cb13
    call Call_000_224f
    push bc
    ld a, $02
    ld hl, $cb11
    call Call_000_224f
    pop hl
    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    ld a, h
    or l
    ret nz

jr_014_7c95:
    ld a, $ff
    ld [$da5e], a
    ret


Jump_014_7c9b:
    ld a, [$da60]
    ld hl, $cb0b
    call Call_000_224a
    bit 7, a
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


Jump_014_7cad:
    call Call_014_7d00
    ret nz

    ld a, [$da60]
    ld hl, $cb0b
    call Call_000_224a
    bit 2, a
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


Jump_014_7cc3:
    call Call_014_7d00
    ret nz

    ld a, [$da60]
    ld hl, $cb0b
    call Call_000_224a
    bit 0, a
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


Jump_014_7cd9:
    ld a, [$c93e]
    bit 0, a
    ret z

    ld a, $ff
    ld [$da5e], a
    ret


Jump_014_7ce5:
    ld b, $10
    ld hl, $c950

jr_014_7cea:
    ld a, [hl+]
    ret z

    dec b
    jr nz, jr_014_7cea

    ld a, $ff
    ld [$da5e], a
    ret


Jump_014_7cf5:
    ld a, [wInGateworld]
    or a
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


Call_014_7d00:
    ld a, [$da60]

Call_014_7d03:
    ld hl, $cb0b
    call Call_000_224a
    bit 7, a
    ret z

    ld a, $ff
    ld [$da5e], a
    ret

label14_7d12:
    ld a, [$da5e]
    cp $ff
    ret z

    cp $2b
    jp z, Jump_014_7d55

    cp $2c
    jp z, Jump_014_7d6d

    cp $2d
    jp z, Jump_014_7d85

    cp $2e
    jp z, Jump_014_7d98

    cp $2f
    jp z, Jump_014_7dd8

    cp $30
    jp z, Jump_014_7e1e

    cp $31
    jp z, Jump_014_7e4e

    cp $33
    jp z, Jump_014_7e6c

    cp $36
    jp z, Jump_014_7e78

    cp $37
    jp z, Jump_014_7e84

    cp $38
    jp z, Jump_014_7e8a

    cp $7e
    jp z, Jump_014_7e96

    ret


Jump_014_7d55:
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $0b
    call Call_000_1dfb
    add $1e
    ld l, a
    ld h, $00
    ld a, [$da60]
    call Call_000_22a0
    ret


Jump_014_7d6d:
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $10
    call Call_000_1dfb
    add $4b
    ld l, a
    ld h, $00
    ld a, [$da60]
    call Call_000_22a0
    ret


Jump_014_7d85:
    ld a, [$da60]
    ld hl, $cb13
    call Call_000_224f
    ld a, [$da60]
    ld hl, $cb11
    call Call_000_225d
    ret


Jump_014_7d98:
    ld a, $00
    ld [$da60], a
    ld a, $00
    call Call_014_7db7
    ld a, $01
    ld [$da60], a
    ld a, $01
    call Call_014_7db7
    ld a, $02
    ld [$da60], a
    ld a, $02
    call Call_014_7db7
    ret


Call_014_7db7:
    ld hl, $cb0b
    call Call_000_224a
    bit 7, a
    ret nz

    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $1f
    call Call_000_1dfb
    add $5a
    ld l, a
    ld h, $00
    ld a, [$da60]
    call Call_000_22a0
    ret


Jump_014_7dd8:
    ld a, $00
    call Call_014_7d03
    jr nz, jr_014_7def

    ld a, $00
    ld hl, $cb13
    call Call_000_224f
    ld a, $00
    ld hl, $cb11
    call Call_000_225d

jr_014_7def:
    ld a, $01
    call Call_014_7d03
    jr nz, jr_014_7e06

    ld a, $01
    ld hl, $cb13
    call Call_000_224f
    ld a, $01
    ld hl, $cb11
    call Call_000_225d

jr_014_7e06:
    ld a, $02
    call Call_014_7d03
    jr nz, jr_014_7e1d

    ld a, $02
    ld hl, $cb13
    call Call_000_224f
    ld a, $02
    ld hl, $cb11
    call Call_000_225d

jr_014_7e1d:
    ret


Jump_014_7e1e:
    ld a, [wRNG1]
    bit 0, a
    jr nz, jr_014_7e47

    ld a, [$da60]
    ld hl, $cb0b
    call Call_000_2229
    ld [hl], $00
    ld a, [$da60]
    ld hl, $cb13
    call Call_000_224f
    srl b
    rr c
    ld a, [$da60]
    ld hl, $cb11
    call Call_000_225d
    ret


jr_014_7e47:
    ld hl, $0e05
    call Call_000_096d
    ret


Jump_014_7e4e:
    ld a, [$da60]
    ld hl, $cb0b
    call Call_000_2229
    ld [hl], $00
    ld a, [$da60]
    ld hl, $cb13
    call Call_000_224f
    ld a, [$da60]
    ld hl, $cb11
    call Call_000_225d
    ret


Jump_014_7e6c:
    ld a, [$da60]
    ld hl, $cb0b
    call Call_000_2229
    res 2, [hl]
    ret


Jump_014_7e78:
    ld a, [$da60]
    ld hl, $cb0b
    call Call_000_2229
    res 0, [hl]
    ret


Jump_014_7e84:
    ld hl, $c93e
    set 0, [hl]
    ret


Jump_014_7e8a:
    ld hl, $c950
    ld bc, $0010
    ld a, $01
    call FillNBytesWithRegA
    ret


Jump_014_7e96:
    ld hl, $010b
    rst $10
    ld hl, wGameState
    set 6, [hl]
    xor a
    ld [$c905], a
    ld a, $00
    ld [$da09], a
    ld hl, $c90d
    inc [hl]
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
