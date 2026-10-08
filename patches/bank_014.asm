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
    dw label14_40b4          ; Entry 2: CREATE monster record from enemy-stats row (S87)
    dw label14_401d          ; Entry 3: Party monster slot init/clear
    dw label14_7bac          ; Entry 4: Unknown
    dw label14_7d12          ; Entry 5: Unknown
    dw LookupBossRedirect          ; Entry 6: Boss EID redirect lookup

label14_400f:
    ld de, $da18
    call LoadEnemyStats
    ret

label14_4016:
    ld de, $da18
    call LoadEnemyStats
    ret

label14_401d:
    ld hl, $cac1
    ld a, [$da14]
    call GetMonsterDataPtr
    ld bc, $0095
    xor a
    call FillNBytesWithRegA
    ld hl, $cad6
    ld a, [$da14]
    call GetMonsterDataPtr
    ld a, $ff
    ld [hl+], a
    ld [hl+], a
    ld hl, $caea
    ld a, [$da14]
    call GetMonsterDataPtr
    ld bc, $0008
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $caf2
    ld a, [$da14]
    call GetMonsterDataPtr
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
    call GetMonsterDataPtr
    ld [hl], $01
    ld hl, $cacd
    ld de, $ca42
    ld b, $08
    call $4782
    ld hl, $cad5
    ld a, [$da14]
    call GetMonsterDataPtr
    ld a, [$ca4a]
    ld [hl], a
    ld de, $da18
    call LoadEnemyStats
    jp Jump_014_4158

; [S87] MONSTER RECORD CONSTRUCTOR (entry 2; script opcode $29 path):
; builds the 149-byte instance record for slot [$da14] from the loaded
; enemy-stats row staged at $DA18+. MaxHP/MaxMP/ATK/DEF/INT (NOT AGL —
; S130 correction) AND the four AI-weight /
; personality bytes get a ONE-TIME per-value CREATION ROLL (SaveEnem_47fd
; byte / SaveEnem_4821 word): factor = ($CD + RNG mod $34)/256, i.e.
; uniform ~0.801..0.996x, with the $100 overflow case = exactly 1.0x.
; AI weights land at slot-record +$64..$67 ($CB25/26/28/27 views) in
; source order w0(cat1)/w1(cat3)/w3/w2(cat2). The individual LEVEL CAP
; (slot+$4C, $CB0D) = species base +-2 (RNG mod 5 - 2). WLD (slot+$60,
; $CB21) = 5*level - 10*arenaTier[$CAB4], clamped 0..$FF. See
; MONSTER_DATA "instance record" (S87).
; [S130] full decode (simulator/raising.py create; tools/census_raising.py:
; 962 creations, 0 mismatches). Record zero-filled; +$15/+$16 (pedigree
; species) := $FF; +$29 (8 known skills) := $FF; +$31 (25-byte learn queue)
; := $FF; the parents' name fields +$17/+$20/+$83/+$8C := the placeholder at
; $477A; +$0C master name (8 B, 9th byte +$14 = $CAD5) := the player's name
; $CA42 (CreateForeignMasterNames overrides it for the rival rows). Stats:
; MaxHP/HP, MaxMP/MP, ATK, DEF, INT rolled (SaveEnem_4821); AGL copied
; UNROLLED (see $CB1D). AI bytes +$64..+$67 <- row +17, +18, +20, +19, each
; rolled. Known skills +$29 <- the row's 4 skills, then DropKnownSkillBases.
; Learn queue +$31 <- info +$06..+$08 (the natural 3). Max level +$4C :=
; info +$01 + (RNG1 mod 5) - 2. Gender +$0B := EnemyGroupTable[EID] unless
; $FF, then RNG1 < CreateGenderThreshold[info +$03] -> 1 (female). Exp
; snapped to the level ($1301 = bank $13 SnapExpToLevel).
; RNG order: HP, MP, ATK, DEF, INT, the four AI rolls (+$64, +$65, +$66,
; +$67), the cap roll, the gender roll (only when the table gives $FF).
label14_40b4:
    ld hl, $cac1
    ld a, [$da14]
    call GetMonsterDataPtr
    ld bc, $0095
    xor a
    call FillNBytesWithRegA
    ld hl, $cad6
    ld a, [$da14]
    call GetMonsterDataPtr
    ld a, $ff
    ld [hl+], a
    ld [hl+], a
    ld hl, $caea
    ld a, [$da14]
    call GetMonsterDataPtr
    ld bc, $0008
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $caf2
    ld a, [$da14]
    call GetMonsterDataPtr
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
    call GetMonsterDataPtr
    ld [hl], $01
    ld hl, $cacd
    ld de, $ca42
    ld b, $08
    call $4782
    ld hl, $cad5
    ld a, [$da14]
    call GetMonsterDataPtr
    ld a, [$ca4a]
    ld [hl], a
    ld de, $da18
    call LoadEnemyStats
    ld a, [$da14]
    cp $29                      ; FX1: staging 21 -> 41 (no library bit for preview)
    jr z, jr_014_4158

    ld a, [$da18]
    ld hl, $ca94
    call SetBitInArray

Jump_014_4158:
jr_014_4158:
    ld hl, $caca
    ld de, $da18
    call SaveEnem_4793
    ld hl, $caea
    ld de, $da2d
    call FuncEnem_47a8
    ld hl, $cb0c
    ld de, $da1c
    call SaveEnem_4793
    ld hl, $cb13
    ld de, $da1d
    call FuncEnem_479e
    ld hl, $cb13
    call SaveEnem_4821
    ld hl, $cb13
    ld a, [$da14]
    call GetMonsterDataPtr
    ld c, [hl]
    inc hl
    ld b, [hl]
    push bc
    ld hl, $cb11
    ld a, [$da14]
    call GetMonsterDataPtr
    pop bc
    ld [hl], c
    inc hl
    ld [hl], b
    ld hl, $cb17
    ld de, $da1f
    call FuncEnem_479e
    ld hl, $cb17
    call SaveEnem_4821
    ld hl, $cb17
    ld a, [$da14]
    call GetMonsterDataPtr
    ld c, [hl]
    inc hl
    ld b, [hl]
    push bc
    ld hl, $cb15
    ld a, [$da14]
    call GetMonsterDataPtr
    pop bc
    ld [hl], c
    inc hl
    ld [hl], b
    ld hl, $cb19
    ld de, $da21
    call FuncEnem_479e
    ld hl, $cb19
    call SaveEnem_4821
    ld hl, $cb1b
    ld de, $da23
    call FuncEnem_479e
    ld hl, $cb1b
    call SaveEnem_4821
    ld hl, $cb1d                ; [S130] AGL +$5C: copied from row +13 with NO
    ld de, $da25                ;   SaveEnem_4821 roll — the one unrolled stat
    call FuncEnem_479e          ;   (MONSTER_DATA "every stat word" was wrong)
    ld hl, $cb1f
    ld de, $da27
    call FuncEnem_479e
    ld hl, $cb1f
    call SaveEnem_4821
    ld hl, $cb25
    ld de, $da29
    call SaveEnem_4793
    ld hl, $cb25
    call SaveEnem_47fd
    ld hl, $cb26
    ld de, $da2a
    call SaveEnem_4793
    ld hl, $cb26
    call SaveEnem_47fd
    ld hl, $cb27
    ld de, $da2c
    call SaveEnem_4793
    ld hl, $cb27
    call SaveEnem_47fd
    ld hl, $cb28
    ld de, $da2b
    call SaveEnem_4793
    ld hl, $cb28
    call SaveEnem_47fd
    ld hl, $cb0c
    ld a, [$da14]
    call GetMonsterDataPtr
    ld a, [hl]
    ld bc, $0005
    call Mul16x8To24
    push hl
    ld a, [$cab4]
    ld bc, $000a
    call Mul16x8To24
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
    call GetMonsterDataPtr
    pop bc
    ld [hl], c
    ld a, [$da18]
    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10
    ld hl, $cacb
    ld de, $da33
    call SaveEnem_4793
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $05
    call Div8x8
    sub $02
    ld b, a
    ld a, [$da34]
    add b
    push af
    ld hl, $cb0d
    ld a, [$da14]
    call GetMonsterDataPtr
    pop af
    ld [hl], a
    ld hl, $cb29
    ld de, $da42
    ld b, $1b
    call $4782
    ld hl, $caf2                ; [S130] learn queue +$31 <- info +$06..+$08
    ld de, $da39
    ld b, $03
    call $4782
    call DropKnownSkillBases           ; [S130] known skills' bases leave the queue
    ld hl, $cacc
    ld a, [$da14]
    call GetMonsterDataPtr
    ld a, [wTempEnemyStatsId]
    ld e, a
    ld a, [$da13]
    ld d, a
    ld a, e
    add LOW(EnemyGroupTable)
    ld e, a
    ld a, d
    adc HIGH(EnemyGroupTable)
    ld d, a
    ld a, [de]
    ld [hl], a
    cp $ff
    jr nz, jr_014_42fe

    ld [hl], $00
    call GenerateRNG
    ld hl, $459e                ; [S130] = CreateGenderThreshold (by info +$03 female ratio)
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
    call GetMonsterDataPtr
    ld [hl], $01

jr_014_42fe:
    ld a, [$da14]
    ld [$cac0], a
    ld hl, $1301
    rst $10
    ld a, [$da13]
    or a
    jp nz, CreateForeignMasterNames

    ld a, [wTempEnemyStatsId]
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


; [S130] CreateForeignMasterNames — EIDs $131-$13C (high byte $01, low
; $31-$3C, the rival tamers' teams): ANOTHER master's name -> +$0C ($CACD,
; 8 B) and a nickname -> +$01 ($CAC2). $15E sets the EGG flag +$63
; (Jump_014_4586); $15F / $1E4 / $1E5 a nickname only. EIDs < $100 listed
; above ($01, $0C, $34, ...: the `$da13 == 0` cases) get a nickname only
; (jr_014_4469). Every other row keeps the player's name as master.
CreateForeignMasterNames:
    ld a, [wTempEnemyStatsId]
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
    call GetMonsterDataPtr
    ld [hl], $01
    ret


Jump_014_4592:
    ld hl, $cac2
    ld de, $46b2
    ld b, $08
    call $4782
    ret


; [S130] CreateGenderThreshold ($14:$459E, 4 B by info +$03 female ratio
; 0-3): db $00, $1a, $80, $d6 — P(female) = byte/256 (0 / 10 / 50 / 84 %),
; the same bytes as bank $16 BreedGenderThreshold. The rival nicknames and
; master names (8 B each, from $45A2) follow; all misassembled as code here.
CreateGenderThreshold:
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
    call GetMonsterDataPtr
    pop de
    pop bc

jr_014_478c:
    ld a, [de]
    ld [hl+], a
    inc de
    dec b
    jr nz, jr_014_478c

    ret


SaveEnem_4793:
    push de
    ld a, [$da14]
    call GetMonsterDataPtr
    pop de
    ld a, [de]
    ld [hl], a
    ret


FuncEnem_479e:
jr_014_479e:
    ld b, $02
    jp $4782


    ld b, $03
    jp $4782


FuncEnem_47a8:
    ld b, $04
    jp $4782


; [S130] DropKnownSkillBases — for each of the 8 known skills +$29:
; DropSkillBase (a known $DB is erased; else its base, through the 256-byte
; UnevolvedSkillMap copy at $491D, leaves the learn queue +$31, first match).
DropKnownSkillBases:
    ld hl, $caea
    ld a, [$da14]
    call GetMonsterDataPtr
    ld e, l
    ld d, h
    ld b, $08

jr_014_47ba:
    ld a, [de]
    push bc
    push de
    call DropSkillBase
    pop de
    pop bc
    inc de
    dec b
    jr nz, jr_014_47ba

    ret


; [S130] DropSkillBase — A = known skill at [DE]: $FF -> nothing; $DB -> the
; known slot := $FF; else base = [$491D + A] ($FF -> nothing) and the first
; queue byte (+$31, 25) equal to it := $FF.
DropSkillBase:
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
    call GetMonsterDataPtr
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


; [S87] CREATION ROLL (byte): [hl] *= ($CD + RNG1 mod $34)/256; the
; mod-$33 case overflows add to $00 (Z) -> ret -> keep original (x1.0).
; Div8x8 convention: B=B//A, A=B%A (remainder in A).
SaveEnem_47fd:
    push hl
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $34
    call Div8x8
    add $cd
    pop hl
    ret z

    push af
    ld a, [$da14]
    call GetMonsterDataPtr
    ld c, [hl]
    ld b, $00
    pop af
    push hl
    call Mul16x8To24
    ld c, h
    pop hl
    ld [hl], c
    ret


; [S87] CREATION ROLL (word variant) — same factor, 16-bit stat.
SaveEnem_4821:
    push hl
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $34
    call Div8x8
    add $cd
    pop hl
    ret z

    push af
    ld a, [$da14]
    call GetMonsterDataPtr
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    pop af
    dec hl
    push hl
    call Mul16x8To24
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
LoadEnemyStats:
    jp LoadEnemyStatsExt     ; [S101] was `push de / ld a,[wTempEnemyStatsId]`
    nop                      ;   (4 B -> 3+1, same size). EIDs >= 519 = PROJECT
                             ;   enemy rows in bank $6B (far copy); below 519
                             ;   the tail re-executes the two instructions and
                             ;   jumps back here. MONSTER_DATA "Project enemy rows".
LoadEnemyStatsResume:        ; A = EID low byte, [sp] = DE (the vanilla path)
    ld c, a
    ld a, [$da13]            ; EID high byte
    ld b, a                  ; BC = enemy stats ID
    ld a, $19                ; 25 = entry size
    call Mul16x8To24       ; HL = EID × 25
    ld a, l
    add LOW(EnemyStatsTable)   ; HL += EnemyStatsTable base address
    ld l, a
    ld a, h
    adc HIGH(EnemyStatsTable)
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
LookupBossRedirect:
    ld a, [wTempEnemyStatsId]            ; source EID low
    ld c, a
    ld a, [$da13]            ; source EID high
    ld b, a                  ; BC = source EID
    ld hl, BossRedirectTableExt          ; [S101] was BossRedirectTable: the
                                         ;   compiler-owned copy in the bank tail =
                                         ;   project fight->join rows FIRST, then
                                         ;   the 34 vanilla rows, then $FFFF

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
    ld [wTempEnemyStatsId], a
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
; Scanned by LookupBossRedirect (entry 6) to redirect fight EIDs to join EIDs
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

; [S130] NOT unknown: the 256-byte UnevolvedSkillMap copy read by
; DropSkillBase (`ld hl, $491d`) starts at $491D, 2 bytes before this label
; (overlapping the BossRedirect terminator's $0000); its bytes equal bank $16
; UnevolvedSkillMap ($16:$4874, checked S130). Entries $F2-$FF ($4A0F-$4A1C)
; are the first 14 bytes of EnemyGroupTable. Label kept (tools/
; gen_enemy_stats_db.py emits it).
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
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
; [S130] EnemyGroupTable = the CREATION GENDER table ($14:$4A0F, 526 B,
; index = EID 0-525; name kept — simulator/raising.py finds it by name):
; $00 male / $01 female fixed for that enemy row, $FF = rolled (RNG1 <
; CreateGenderThreshold[info +$03] -> female). Read by label14_40b4 -> +$0B.
EnemyGroupTable:
    db $FF, $00  ;  $4A0F
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

; @BUILD_PROJECT BEGIN gd_enemy_stats
; (generated by editor2 `gd_enemies` from gamedata.enemies — 25 B: species,
;  exp, joinability, level, HP MP ATK DEF AGL INT, 4 AI weights, 4 skills)
EnemyStatsTable:
EnemyStats_000:  ; DrakSlime Lv0 join 0
    db 0
    dw 0
    db 0, 0
    dw 0, 0, 0, 0, 0, 0  ; HP MP ATK DEF AGL INT
    db 0, 0, 0, 0  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_001:  ; Slime Lv1 join 0  ; EDITED (project gamedata)
    db 8
    dw 0
    db 0, 1
    dw 30, 100, 10, 6, 5, 1  ; HP MP ATK DEF AGL INT
    db 100, 200, 100, 200  ; AI weights
    db $E9, $E5, $E4, $09  ; $E9, $E5, $E4, Infernos
EnemyStats_002:  ; Slime Lv1 join 2
    db 8
    dw 3
    db 2, 1
    dw 8, 0, 8, 5, 7, 1  ; HP MP ATK DEF AGL INT
    db 200, 50, 100, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_003:  ; Anteater Lv1 join 1
    db 53
    dw 9
    db 1, 1
    dw 12, 0, 19, 4, 4, 3  ; HP MP ATK DEF AGL INT
    db 150, 0, 50, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_004:  ; Dracky Lv1 join 1
    db 78
    dw 4
    db 1, 1
    dw 8, 20, 12, 4, 12, 14  ; HP MP ATK DEF AGL INT
    db 200, 0, 0, 200  ; AI weights
    db $33, $FF, $FF, $FF  ; Antidote, -, -, -
EnemyStats_005:  ; Stubsuck Lv2 join 2
    db 98
    dw 9
    db 2, 2
    dw 20, 6, 23, 8, 12, 10  ; HP MP ATK DEF AGL INT
    db 100, 50, 200, 200  ; AI weights
    db $15, $FF, $FF, $FF  ; Sleep, -, -, -
EnemyStats_006:  ; GoHopper Lv2 join 2
    db 119
    dw 10
    db 2, 2
    dw 24, 2, 18, 6, 10, 8  ; HP MP ATK DEF AGL INT
    db 100, 50, 0, 200  ; AI weights
    db $41, $FF, $FF, $FF  ; ChargeUP, -, -, -
EnemyStats_007:  ; Gremlin Lv2 join 2
    db 139
    dw 10
    db 2, 2
    dw 26, 9, 14, 9, 9, 28  ; HP MP ATK DEF AGL INT
    db 50, 150, 200, 200  ; AI weights
    db $03, $2B, $FF, $FF  ; Firebal, Heal, -, -
EnemyStats_008:  ; Spooky Lv3 join 3
    db 155
    dw 18
    db 3, 3
    dw 37, 3, 25, 9, 31, 13  ; HP MP ATK DEF AGL INT
    db 200, 100, 200, 200  ; AI weights
    db $79, $FF, $FF, $FF  ; LushLicks, -, -, -
EnemyStats_009:  ; Goopi Lv5 join 3
    db 183
    dw 16
    db 3, 5
    dw 41, 3, 28, 8, 8, 6  ; HP MP ATK DEF AGL INT
    db 150, 50, 150, 200  ; AI weights
    db $7B, $FF, $FF, $FF  ; LegSweep, -, -, -
EnemyStats_010:  ; ArmyAnt Lv3 join 2
    db 118
    dw 12
    db 2, 3
    dw 24, 3, 29, 9, 11, 13  ; HP MP ATK DEF AGL INT
    db 250, 50, 0, 200  ; AI weights
    db $68, $FF, $FF, $FF  ; NapAttack, -, -, -
EnemyStats_011:  ; Healer Lv6 join 0
    db 9
    dw 0
    db 0, 6
    dw 40, 7, 20, 12, 12, 28  ; HP MP ATK DEF AGL INT
    db 100, 250, 100, 200  ; AI weights
    db $2B, $FF, $FF, $FF  ; Heal, -, -, -
EnemyStats_012:  ; Healer Lv6 join 0
    db 9
    dw 0
    db 0, 6
    dw 30, 18, 16, 10, 32, 28  ; HP MP ATK DEF AGL INT
    db 100, 250, 200, 200  ; AI weights
    db $2B, $FF, $FF, $FF  ; Heal, -, -, -
EnemyStats_013:  ; MiniDrak Lv4 join 3
    db 29
    dw 32
    db 3, 4
    dw 45, 5, 32, 10, 18, 6  ; HP MP ATK DEF AGL INT
    db 150, 100, 150, 150  ; AI weights
    db $72, $FF, $FF, $FF  ; SandStorm, -, -, -
EnemyStats_014:  ; Picky Lv4 join 2
    db 70
    dw 25
    db 2, 4
    dw 32, 6, 30, 12, 26, 12  ; HP MP ATK DEF AGL INT
    db 200, 100, 150, 150  ; AI weights
    db $1C, $FF, $FF, $FF  ; Sap, -, -, -
EnemyStats_015:  ; PillowRat Lv4 join 3
    db 48
    dw 27
    db 3, 4
    dw 29, 12, 26, 12, 30, 13  ; HP MP ATK DEF AGL INT
    db 100, 50, 100, 150  ; AI weights
    db $77, $FF, $FF, $FF  ; SideStep, -, -, -
EnemyStats_016:  ; Hork Lv5 join 3
    db 163
    dw 45
    db 3, 5
    dw 51, 6, 35, 10, 10, 10  ; HP MP ATK DEF AGL INT
    db 150, 50, 50, 150  ; AI weights
    db $6C, $79, $FF, $FF  ; PoisonGas, LushLicks, -, -
EnemyStats_017:  ; DragonKid Lv6 join 3
    db 20
    dw 55
    db 3, 6
    dw 32, 7, 32, 20, 35, 11  ; HP MP ATK DEF AGL INT
    db 150, 100, 100, 150  ; AI weights
    db $6A, $8C, $FF, $FF  ; SleepAir, Dodge, -, -
EnemyStats_018:  ; EvilSeed Lv7 join 2
    db 105
    dw 50
    db 2, 7
    dw 43, 5, 29, 25, 15, 28  ; HP MP ATK DEF AGL INT
    db 200, 0, 250, 150  ; AI weights
    db $4E, $69, $FF, $FF  ; CleanCut, Paralyze, -, -
EnemyStats_019:  ; Catapila Lv8 join 3
    db 111
    dw 64
    db 3, 8
    dw 38, 16, 44, 29, 12, 10  ; HP MP ATK DEF AGL INT
    db 200, 50, 100, 150  ; AI weights
    db $1E, $FF, $FF, $FF  ; Upper, -, -, -
EnemyStats_020:  ; FairyRat Lv6 join 2
    db 61
    dw 55
    db 2, 6
    dw 48, 18, 32, 14, 40, 30  ; HP MP ATK DEF AGL INT
    db 100, 50, 200, 150  ; AI weights
    db $20, $D6, $FF, $FF  ; Slow, Smashlime, -, -
EnemyStats_021:  ; BigRoost Lv8 join 2
    db 79
    dw 67
    db 2, 8
    dw 48, 18, 28, 16, 42, 9  ; HP MP ATK DEF AGL INT
    db 200, 150, 150, 150  ; AI weights
    db $72, $8C, $FF, $FF  ; SandStorm, Dodge, -, -
EnemyStats_022:  ; Demonite Lv7 join 2
    db 133
    dw 65
    db 2, 7
    dw 41, 3, 34, 14, 40, 19  ; HP MP ATK DEF AGL INT
    db 100, 100, 250, 150  ; AI weights
    db $01, $FF, $FF, $FF  ; Blazemore, -, -, -
EnemyStats_023:  ; BoneSlave Lv7 join 3
    db 171
    dw 67
    db 3, 7
    dw 53, 20, 53, 15, 24, 45  ; HP MP ATK DEF AGL INT
    db 50, 0, 0, 150  ; AI weights
    db $45, $4B, $FF, $FF  ; BoltSlash, BirdBlow, -, -
EnemyStats_024:  ; SabreMan Lv7 join 2
    db 187
    dw 64
    db 2, 7
    dw 45, 20, 60, 24, 26, 42  ; HP MP ATK DEF AGL INT
    db 250, 0, 100, 150  ; AI weights
    db $1A, $4C, $FF, $FF  ; RobMagic, DevilCut, -, -
EnemyStats_025:  ; SpotSlime Lv8 join 2
    db 1
    dw 72
    db 2, 8
    dw 48, 11, 39, 14, 50, 11  ; HP MP ATK DEF AGL INT
    db 100, 100, 100, 150  ; AI weights
    db $52, $79, $FF, $FF  ; CallHelp, LushLicks, -, -
EnemyStats_026:  ; Crestpent Lv8 join 2
    db 38
    dw 73
    db 2, 8
    dw 62, 8, 32, 33, 15, 9  ; HP MP ATK DEF AGL INT
    db 200, 100, 50, 150  ; AI weights
    db $17, $67, $FF, $FF  ; StopSpell, PoisonHit, -, -
EnemyStats_027:  ; BeanMan Lv8 join 2
    db 104
    dw 90
    db 2, 8
    dw 61, 11, 40, 34, 30, 10  ; HP MP ATK DEF AGL INT
    db 250, 0, 200, 150  ; AI weights
    db $1A, $25, $FF, $FF  ; RobMagic, TwinHits, -, -
EnemyStats_028:  ; 1EyeClown Lv9 join 2
    db 138
    dw 81
    db 2, 9
    dw 54, 14, 42, 20, 38, 30  ; HP MP ATK DEF AGL INT
    db 200, 0, 250, 150  ; AI weights
    db $01, $FF, $FF, $FF  ; Blazemore, -, -, -
EnemyStats_029:  ; CoilBird Lv9 join 3
    db 178
    dw 78
    db 3, 9
    dw 66, 30, 34, 22, 52, 17  ; HP MP ATK DEF AGL INT
    db 100, 200, 100, 150  ; AI weights
    db $34, $35, $FF, $FF  ; NumbOff, DeChaos, -, -
EnemyStats_030:  ; Metaly Lv10 join 6
    db 16
    dw 3365
    db 6, 10
    dw 6, 120, 22, 300, 130, 32  ; HP MP ATK DEF AGL INT
    db 100, 100, 100, 150  ; AI weights
    db $00, $DB, $FF, $FF  ; Blaze, RUN, -, -
EnemyStats_031:  ; Dragon Lv6 join 0
    db 28
    dw 0
    db 0, 6
    dw 90, 60, 40, 25, 15, 10  ; HP MP ATK DEF AGL INT
    db 250, 50, 0, 150  ; AI weights
    db $44, $5C, $FF, $FF  ; FireSlash, FireAir, -, -
EnemyStats_032:  ; Golem Lv7 join 0
    db 196
    dw 0
    db 0, 7
    dw 100, 20, 45, 20, 20, 70  ; HP MP ATK DEF AGL INT
    db 150, 150, 150, 150  ; AI weights
    db $41, $56, $8E, $FF  ; ChargeUP, PsycheUp, StrongD, -
EnemyStats_033:  ; Almiraj Lv10 join 3
    db 46
    dw 130
    db 3, 10
    dw 57, 46, 48, 25, 50, 15  ; HP MP ATK DEF AGL INT
    db 150, 50, 100, 100  ; AI weights
    db $15, $3D, $41, $FF  ; Sleep, Beserker, ChargeUP, -
EnemyStats_034:  ; BullBird Lv12 join 3
    db 72
    dw 144
    db 3, 12
    dw 72, 17, 64, 21, 57, 10  ; HP MP ATK DEF AGL INT
    db 200, 50, 200, 100  ; AI weights
    db $3C, $41, $D8, $FF  ; Ramming, ChargeUP, Branching, -
EnemyStats_035:  ; FloraMan Lv12 join 3
    db 92
    dw 121
    db 3, 12
    dw 68, 80, 30, 26, 39, 65  ; HP MP ATK DEF AGL INT
    db 100, 150, 250, 100  ; AI weights
    db $04, $33, $36, $FF  ; Firebane, Antidote, CurseOff, -
EnemyStats_036:  ; GiantWorm Lv12 join 3
    db 115
    dw 126
    db 3, 12
    dw 62, 20, 59, 24, 45, 40  ; HP MP ATK DEF AGL INT
    db 250, 0, 200, 100  ; AI weights
    db $4A, $75, $FF, $FF  ; BeastCut, OddDance, -, -
EnemyStats_037:  ; SkulRider Lv11 join 3
    db 136
    dw 175
    db 3, 11
    dw 80, 20, 63, 45, 42, 19  ; HP MP ATK DEF AGL INT
    db 150, 0, 100, 100  ; AI weights
    db $44, $57, $7B, $FF  ; FireSlash, RainSlash, LegSweep, -
EnemyStats_038:  ; GiantSlug Lv12 join 2
    db 110
    dw 132
    db 2, 12
    dw 60, 18, 51, 25, 43, 21  ; HP MP ATK DEF AGL INT
    db 100, 200, 200, 100  ; AI weights
    db $79, $8C, $FF, $FF  ; LushLicks, Dodge, -, -
EnemyStats_039:  ; MudDoll Lv12 join 3
    db 195
    dw 144
    db 3, 12
    dw 79, 44, 56, 28, 22, 44  ; HP MP ATK DEF AGL INT
    db 150, 100, 200, 100  ; AI weights
    db $75, $77, $FF, $FF  ; OddDance, SideStep, -, -
EnemyStats_040:  ; TreeSlime Lv12 join 3
    db 3
    dw 151
    db 3, 12
    dw 86, 22, 44, 28, 69, 46  ; HP MP ATK DEF AGL INT
    db 100, 50, 200, 100  ; AI weights
    db $1C, $69, $6A, $FF  ; Sap, Paralyze, SleepAir, -
EnemyStats_041:  ; Poisongon Lv12 join 3
    db 26
    dw 150
    db 3, 12
    dw 65, 43, 59, 50, 26, 23  ; HP MP ATK DEF AGL INT
    db 150, 100, 100, 100  ; AI weights
    db $67, $6C, $FF, $FF  ; PoisonHit, PoisonGas, -, -
EnemyStats_042:  ; CatFly Lv13 join 2
    db 47
    dw 146
    db 2, 13
    dw 67, 46, 56, 26, 67, 49  ; HP MP ATK DEF AGL INT
    db 150, 50, 150, 100  ; AI weights
    db $17, $20, $FF, $FF  ; StopSpell, Slow, -, -
EnemyStats_043:  ; WingTree Lv13 join 3
    db 93
    dw 160
    db 3, 13
    dw 69, 60, 67, 30, 52, 40  ; HP MP ATK DEF AGL INT
    db 200, 100, 200, 100  ; AI weights
    db $32, $4D, $FF, $FF  ; Farewell, ZombieCut, -, -
EnemyStats_044:  ; Eyeder Lv16 join 3
    db 122
    dw 156
    db 3, 16
    dw 54, 15, 70, 90, 85, 50  ; HP MP ATK DEF AGL INT
    db 50, 150, 200, 100  ; AI weights
    db $03, $2B, $FF, $FF  ; Firebal, Heal, -, -
EnemyStats_045:  ; Putrepup Lv14 join 3
    db 157
    dw 145
    db 3, 14
    dw 84, 52, 76, 35, 30, 26  ; HP MP ATK DEF AGL INT
    db 200, 0, 200, 100  ; AI weights
    db $1C, $20, $FF, $FF  ; Sap, Slow, -, -
EnemyStats_046:  ; DrakSlime Lv14 join 3
    db 0
    dw 153
    db 3, 14
    dw 75, 26, 58, 32, 96, 52  ; HP MP ATK DEF AGL INT
    db 150, 100, 200, 100  ; AI weights
    db $43, $5D, $FF, $FF  ; SuckAir, BlazeAir, -, -
EnemyStats_047:  ; FairyDrak Lv14 join 3
    db 24
    dw 168
    db 3, 14
    dw 66, 51, 53, 33, 51, 27  ; HP MP ATK DEF AGL INT
    db 150, 100, 150, 100  ; AI weights
    db $18, $6A, $FF, $FF  ; Surround, SleepAir, -, -
EnemyStats_048:  ; Skullroo Lv15 join 3
    db 51
    dw 170
    db 3, 15
    dw 95, 24, 79, 31, 57, 55  ; HP MP ATK DEF AGL INT
    db 50, 50, 50, 100  ; AI weights
    db $41, $6E, $FF, $FF  ; ChargeUP, PaniDance, -, -
EnemyStats_049:  ; Butterfly Lv15 join 2
    db 113
    dw 176
    db 2, 15
    dw 68, 57, 59, 36, 78, 28  ; HP MP ATK DEF AGL INT
    db 200, 0, 150, 100  ; AI weights
    db $18, $6F, $FF, $FF  ; Surround, Curse, -, -
EnemyStats_050:  ; MadRaven Lv17 join 3
    db 76
    dw 190
    db 3, 17
    dw 73, 55, 67, 49, 80, 85  ; HP MP ATK DEF AGL INT
    db 200, 50, 150, 100  ; AI weights
    db $42, $8A, $FF, $FF  ; HighJump, TailWind, -, -
EnemyStats_051:  ; MadCat Lv12 join 0
    db 68
    dw 0
    db 0, 12
    dw 200, 30, 63, 35, 63, 35  ; HP MP ATK DEF AGL INT
    db 250, 0, 200, 100  ; AI weights
    db $46, $55, $7B, $FF  ; VacuSlash, SquallHit, LegSweep, -
EnemyStats_052:  ; MadCat Lv12 join 0
    db 68
    dw 0
    db 0, 12
    dw 80, 30, 63, 50, 63, 35  ; HP MP ATK DEF AGL INT
    db 250, 250, 200, 100  ; AI weights
    db $46, $55, $7B, $FF  ; VacuSlash, SquallHit, LegSweep, -
EnemyStats_053:  ; FaceTree Lv12 join 0
    db 102
    dw 0
    db 0, 12
    dw 400, 100, 60, 30, 38, 55  ; HP MP ATK DEF AGL INT
    db 200, 50, 200, 100  ; AI weights
    db $17, $6F, $75, $FF  ; StopSpell, Curse, OddDance, -
EnemyStats_054:  ; FaceTree Lv12 join 0
    db 102
    dw 0
    db 0, 12
    dw 100, 100, 45, 50, 38, 55  ; HP MP ATK DEF AGL INT
    db 100, 150, 200, 100  ; AI weights
    db $17, $6F, $75, $FF  ; StopSpell, Curse, OddDance, -
EnemyStats_055:  ; MadKnight Lv12 join 0
    db 149
    dw 0
    db 0, 12
    dw 300, 60, 77, 60, 40, 50  ; HP MP ATK DEF AGL INT
    db 250, 0, 200, 100  ; AI weights
    db $3F, $4A, $FF, $FF  ; Massacre, BeastCut, -, -
EnemyStats_056:  ; MadKnight Lv12 join 0
    db 149
    dw 0
    db 0, 12
    dw 85, 60, 77, 75, 40, 50  ; HP MP ATK DEF AGL INT
    db 250, 0, 200, 50  ; AI weights
    db $3F, $4A, $FF, $FF  ; Massacre, BeastCut, -, -
EnemyStats_057:  ; Mudron Lv16 join 3
    db 164
    dw 284
    db 3, 16
    dw 78, 40, 58, 46, 34, 70  ; HP MP ATK DEF AGL INT
    db 50, 200, 250, 50  ; AI weights
    db $12, $2B, $FF, $FF  ; Beat, Heal, -, -
EnemyStats_058:  ; Facer Lv16 join 3
    db 179
    dw 282
    db 3, 16
    dw 64, 113, 49, 34, 95, 110  ; HP MP ATK DEF AGL INT
    db 150, 50, 100, 50  ; AI weights
    db $0A, $95, $FF, $FF  ; Infermore, LifeSong, -, -
EnemyStats_059:  ; Snaily Lv16 join 2
    db 4
    dw 290
    db 2, 16
    dw 67, 30, 65, 115, 110, 60  ; HP MP ATK DEF AGL INT
    db 250, 250, 50, 50  ; AI weights
    db $0C, $52, $FF, $FF  ; IceBolt, CallHelp, -, -
EnemyStats_060:  ; Saccer Lv17 join 3
    db 49
    dw 246
    db 3, 17
    dw 95, 61, 88, 129, 35, 62  ; HP MP ATK DEF AGL INT
    db 150, 50, 150, 50  ; AI weights
    db $1E, $56, $FF, $FF  ; Upper, PsycheUp, -, -
EnemyStats_061:  ; MadPecker Lv22 join 3
    db 75
    dw 322
    db 3, 22
    dw 68, 32, 126, 70, 122, 61  ; HP MP ATK DEF AGL INT
    db 250, 0, 150, 50  ; AI weights
    db $0A, $1C, $FF, $FF  ; Infermore, Sap, -, -
EnemyStats_062:  ; Gulpple Lv17 join 3
    db 95
    dw 288
    db 3, 17
    dw 96, 82, 75, 100, 66, 74  ; HP MP ATK DEF AGL INT
    db 200, 100, 150, 50  ; AI weights
    db $0A, $68, $FF, $FF  ; Infermore, NapAttack, -, -
EnemyStats_063:  ; EyeBall Lv18 join 3
    db 135
    dw 320
    db 3, 18
    dw 98, 67, 76, 72, 69, 68  ; HP MP ATK DEF AGL INT
    db 200, 50, 250, 50  ; AI weights
    db $27, $7D, $FF, $FF  ; MagicBack, WarCry, -, -
EnemyStats_064:  ; Mummy Lv18 join 3
    db 159
    dw 342
    db 3, 18
    dw 130, 68, 77, 55, 42, 38  ; HP MP ATK DEF AGL INT
    db 200, 50, 150, 50  ; AI weights
    db $40, $52, $69, $FF  ; EvilSlash, CallHelp, Paralyze, -
EnemyStats_065:  ; Babble Lv18 join 3
    db 6
    dw 312
    db 3, 18
    dw 82, 35, 80, 44, 120, 60  ; HP MP ATK DEF AGL INT
    db 150, 100, 150, 50  ; AI weights
    db $18, $67, $FF, $FF  ; Surround, PoisonHit, -, -
EnemyStats_066:  ; Pteranod Lv19 join 3
    db 22
    dw 406
    db 3, 19
    dw 140, 40, 103, 70, 123, 80  ; HP MP ATK DEF AGL INT
    db 200, 100, 150, 50  ; AI weights
    db $03, $58, $8A, $FF  ; Firebal, WindBeast, TailWind, -
EnemyStats_067:  ; Tonguella Lv19 join 3
    db 45
    dw 356
    db 3, 19
    dw 108, 62, 90, 61, 45, 40  ; HP MP ATK DEF AGL INT
    db 250, 50, 200, 50  ; AI weights
    db $68, $79, $FF, $FF  ; NapAttack, LushLicks, -, -
EnemyStats_068:  ; Florajay Lv19 join 3
    db 73
    dw 259
    db 3, 19
    dw 75, 86, 65, 42, 142, 120  ; HP MP ATK DEF AGL INT
    db 200, 150, 150, 50  ; AI weights
    db $23, $4A, $95, $FF  ; SpeedUp, BeastCut, LifeSong, -
EnemyStats_069:  ; MadPlant Lv20 join 3
    db 90
    dw 374
    db 3, 20
    dw 116, 140, 72, 50, 135, 91  ; HP MP ATK DEF AGL INT
    db 250, 100, 250, 50  ; AI weights
    db $1C, $20, $34, $FF  ; Sap, Slow, NumbOff, -
EnemyStats_070:  ; ArmorPede Lv24 join 4
    db 121
    dw 450
    db 4, 24
    dw 125, 37, 119, 127, 50, 68  ; HP MP ATK DEF AGL INT
    db 250, 50, 200, 50  ; AI weights
    db $1E, $25, $3B, $FF  ; Upper, TwinHits, TwinSlash, -
EnemyStats_071:  ; MedusaEye Lv18 join 4
    db 140
    dw 305
    db 4, 18
    dw 82, 68, 66, 96, 88, 64  ; HP MP ATK DEF AGL INT
    db 100, 50, 100, 50  ; AI weights
    db $18, $1C, $D8, $FF  ; Surround, Sap, Branching, -
EnemyStats_072:  ; MadCandle Lv21 join 3
    db 177
    dw 522
    db 3, 21
    dw 95, 38, 100, 135, 91, 67  ; HP MP ATK DEF AGL INT
    db 200, 100, 150, 50  ; AI weights
    db $01, $56, $FF, $FF  ; Blazemore, PsycheUp, -, -
EnemyStats_073:  ; WingSlime Lv21 join 4
    db 2
    dw 358
    db 4, 21
    dw 76, 68, 66, 44, 150, 68  ; HP MP ATK DEF AGL INT
    db 100, 50, 100, 50  ; AI weights
    db $55, $58, $8A, $FF  ; SquallHit, WindBeast, TailWind, -
EnemyStats_074:  ; MadGopher Lv21 join 3
    db 60
    dw 410
    db 3, 21
    dw 106, 68, 97, 45, 54, 48  ; HP MP ATK DEF AGL INT
    db 250, 150, 200, 50  ; AI weights
    db $41, $4B, $4D, $FF  ; ChargeUP, BirdBlow, ZombieCut, -
EnemyStats_075:  ; FangSlime Lv20 join 0
    db 10
    dw 0
    db 0, 20
    dw 400, 40, 87, 50, 80, 65  ; HP MP ATK DEF AGL INT
    db 200, 100, 150, 0  ; AI weights
    db $41, $52, $7D, $FF  ; ChargeUP, CallHelp, WarCry, -
EnemyStats_076:  ; FangSlime Lv20 join 0
    db 10
    dw 0
    db 0, 20
    dw 70, 40, 85, 52, 90, 65  ; HP MP ATK DEF AGL INT
    db 200, 200, 200, 50  ; AI weights
    db $41, $52, $7D, $FF  ; ChargeUP, CallHelp, WarCry, -
EnemyStats_077:  ; BigEye Lv20 join 7
    db 69
    dw 1500
    db 7, 20
    dw 500, 40, 80, 40, 62, 80  ; HP MP ATK DEF AGL INT
    db 150, 150, 150, 50  ; AI weights
    db $0D, $2B, $61, $FF  ; SnowStorm, Heal, IceAir, -
EnemyStats_078:  ; BigEye Lv20 join 0
    db 69
    dw 0
    db 0, 20
    dw 80, 57, 80, 48, 62, 80  ; HP MP ATK DEF AGL INT
    db 150, 200, 100, 50  ; AI weights
    db $0D, $2B, $61, $FF  ; SnowStorm, Heal, IceAir, -
EnemyStats_079:  ; Gigantes Lv14 join 6
    db 150
    dw 1700
    db 6, 14
    dw 600, 10, 130, 30, 68, 15  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 50  ; AI weights
    db $40, $41, $4D, $FF  ; EvilSlash, ChargeUP, ZombieCut, -
EnemyStats_080:  ; Gigantes Lv14 join 0
    db 150
    dw 0
    db 0, 14
    dw 150, 10, 130, 46, 48, 15  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 50  ; AI weights
    db $40, $41, $4D, $FF  ; EvilSlash, ChargeUP, ZombieCut, -
EnemyStats_081:  ; Slabbit Lv22 join 3
    db 13
    dw 475
    db 3, 22
    dw 130, 40, 91, 60, 162, 105  ; HP MP ATK DEF AGL INT
    db 150, 100, 150, 0  ; AI weights
    db $77, $7C, $FF, $FF  ; SideStep, BigTrip, -, -
EnemyStats_082:  ; Gasgon Lv22 join 4
    db 23
    dw 510
    db 4, 22
    dw 141, 111, 113, 59, 30, 73  ; HP MP ATK DEF AGL INT
    db 200, 250, 100, 0  ; AI weights
    db $32, $3D, $FF, $FF  ; Farewell, Beserker, -, -
EnemyStats_083:  ; WindBeast Lv22 join 3
    db 52
    dw 480
    db 3, 22
    dw 110, 132, 78, 81, 130, 105  ; HP MP ATK DEF AGL INT
    db 200, 150, 200, 0  ; AI weights
    db $0A, $0C, $46, $FF  ; Infermore, IceBolt, VacuSlash, -
EnemyStats_084:  ; StubBird Lv23 join 4
    db 80
    dw 588
    db 4, 23
    dw 91, 84, 170, 140, 90, 82  ; HP MP ATK DEF AGL INT
    db 250, 50, 200, 0  ; AI weights
    db $25, $57, $D7, $FF  ; TwinHits, RainSlash, Sheldodge, -
EnemyStats_085:  ; Oniono Lv23 join 3
    db 99
    dw 500
    db 3, 23
    dw 100, 110, 95, 50, 126, 143  ; HP MP ATK DEF AGL INT
    db 150, 100, 200, 0  ; AI weights
    db $1A, $41, $6A, $FF  ; RobMagic, ChargeUP, SleepAir, -
EnemyStats_086:  ; Gophecada Lv23 join 3
    db 112
    dw 490
    db 3, 23
    dw 172, 55, 95, 112, 54, 43  ; HP MP ATK DEF AGL INT
    db 0, 0, 0, 0  ; AI weights
    db $12, $27, $52, $FF  ; Beat, MagicBack, CallHelp, -
EnemyStats_087:  ; Pixy Lv24 join 3
    db 130
    dw 518
    db 3, 24
    dw 90, 46, 102, 68, 80, 62  ; HP MP ATK DEF AGL INT
    db 100, 100, 150, 0  ; AI weights
    db $23, $25, $33, $FF  ; SpeedUp, TwinHits, Antidote, -
EnemyStats_088:  ; DeadNite Lv24 join 4
    db 161
    dw 630
    db 4, 24
    dw 121, 87, 140, 99, 105, 92  ; HP MP ATK DEF AGL INT
    db 250, 200, 200, 0  ; AI weights
    db $2B, $35, $36, $FF  ; Heal, DeChaos, CurseOff, -
EnemyStats_089:  ; SpikyBoy Lv24 join 3
    db 180
    dw 560
    db 3, 24
    dw 93, 46, 100, 93, 50, 63  ; HP MP ATK DEF AGL INT
    db 150, 50, 150, 0  ; AI weights
    db $14, $42, $D6, $FF  ; Sacrifice, HighJump, Smashlime, -
EnemyStats_090:  ; SlimeNite Lv25 join 4
    db 5
    dw 585
    db 4, 25
    dw 144, 47, 136, 102, 152, 96  ; HP MP ATK DEF AGL INT
    db 200, 150, 150, 0  ; AI weights
    db $1F, $2B, $4A, $FF  ; Increase, Heal, BeastCut, -
EnemyStats_091:  ; KingCobra Lv25 join 3
    db 35
    dw 660
    db 3, 25
    dw 126, 46, 95, 82, 130, 47  ; HP MP ATK DEF AGL INT
    db 250, 0, 100, 0  ; AI weights
    db $67, $6F, $FF, $FF  ; PoisonHit, Curse, -, -
EnemyStats_092:  ; Mommonja Lv25 join 4
    db 56
    dw 600
    db 4, 25
    dw 125, 66, 85, 80, 135, 170  ; HP MP ATK DEF AGL INT
    db 150, 150, 200, 0  ; AI weights
    db $0D, $78, $92, $FF  ; SnowStorm, LureDance, MouthShut, -
EnemyStats_093:  ; MistyWing Lv26 join 3
    db 77
    dw 573
    db 3, 26
    dw 131, 94, 105, 105, 132, 100  ; HP MP ATK DEF AGL INT
    db 150, 100, 150, 0  ; AI weights
    db $18, $24, $74, $FF  ; Surround, Barrier, EerieLite, -
EnemyStats_094:  ; StagBug Lv26 join 3
    db 117
    dw 640
    db 3, 26
    dw 106, 49, 141, 155, 96, 49  ; HP MP ATK DEF AGL INT
    db 200, 50, 200, 0  ; AI weights
    db $15, $5D, $7B, $FF  ; Sleep, BlazeAir, LegSweep, -
EnemyStats_095:  ; DarkEye Lv20 join 4
    db 134
    dw 720
    db 4, 20
    dw 97, 133, 77, 95, 105, 102  ; HP MP ATK DEF AGL INT
    db 150, 0, 150, 0  ; AI weights
    db $48, $6B, $73, $FF  ; MetalCut, PalsyAir, Radiant, -
EnemyStats_096:  ; NiteWhip Lv27 join 3
    db 165
    dw 666
    db 3, 27
    dw 101, 74, 58, 135, 140, 111  ; HP MP ATK DEF AGL INT
    db 200, 100, 150, 0  ; AI weights
    db $58, $5A, $5D, $FF  ; WindBeast, Lightning, BlazeAir, -
EnemyStats_097:  ; RogueNite Lv27 join 3
    db 182
    dw 780
    db 3, 27
    dw 160, 38, 166, 200, 75, 79  ; HP MP ATK DEF AGL INT
    db 250, 250, 150, 0  ; AI weights
    db $2B, $40, $48, $FF  ; Heal, EvilSlash, MetalCut, -
EnemyStats_098:  ; BoxSlime Lv27 join 4
    db 7
    dw 740
    db 4, 27
    dw 102, 49, 112, 82, 145, 76  ; HP MP ATK DEF AGL INT
    db 100, 50, 150, 0  ; AI weights
    db $01, $1E, $3C, $FF  ; Blazemore, Upper, Ramming, -
EnemyStats_099:  ; StoneMan Lv20 join 7
    db 197
    dw 6400
    db 7, 20
    dw 800, 36, 130, 90, 45, 90  ; HP MP ATK DEF AGL INT
    db 250, 100, 50, 0  ; AI weights
    db $88, $8F, $FF, $FF  ; Cover, SuckAll, -, -
EnemyStats_100:  ; StoneMan Lv20 join 0
    db 197
    dw 0
    db 0, 20
    dw 170, 36, 130, 110, 45, 90  ; HP MP ATK DEF AGL INT
    db 250, 50, 50, 0  ; AI weights
    db $88, $8F, $FF, $FF  ; Cover, SuckAll, -, -
EnemyStats_101:  ; BattleRex Lv20 join 0
    db 42
    dw 0
    db 0, 20
    dw 1000, 50, 170, 80, 80, 70  ; HP MP ATK DEF AGL INT
    db 250, 100, 150, 0  ; AI weights
    db $48, $5D, $FF, $FF  ; MetalCut, BlazeAir, -, -
EnemyStats_102:  ; BattleRex Lv20 join 0
    db 42
    dw 0
    db 0, 20
    dw 165, 90, 140, 80, 100, 70  ; HP MP ATK DEF AGL INT
    db 250, 250, 150, 0  ; AI weights
    db $48, $5D, $FF, $FF  ; MetalCut, BlazeAir, -, -
EnemyStats_103:  ; Copycat Lv20 join 0
    db 174
    dw 0
    db 0, 20
    dw 800, 48, 95, 70, 60, 60  ; HP MP ATK DEF AGL INT
    db 50, 50, 250, 0  ; AI weights
    db $29, $76, $7F, $FF  ; Transform, RobDance, Imitate, -
EnemyStats_104:  ; Copycat Lv20 join 0
    db 174
    dw 0
    db 0, 20
    dw 80, 48, 100, 85, 60, 60  ; HP MP ATK DEF AGL INT
    db 200, 50, 250, 0  ; AI weights
    db $29, $76, $7F, $FF  ; Transform, RobDance, Imitate, -
EnemyStats_105:  ; Orc Lv28 join 3
    db 143
    dw 710
    db 3, 28
    dw 160, 40, 130, 88, 86, 140  ; HP MP ATK DEF AGL INT
    db 200, 0, 100, 0  ; AI weights
    db $1C, $4B, $FF, $FF  ; Sap, BirdBlow, -, -
EnemyStats_106:  ; Reaper Lv28 join 4
    db 168
    dw 750
    db 4, 28
    dw 110, 135, 156, 40, 130, 170  ; HP MP ATK DEF AGL INT
    db 200, 50, 250, 0  ; AI weights
    db $4C, $6F, $74, $FF  ; DevilCut, Curse, EerieLite, -
EnemyStats_107:  ; Gismo Lv28 join 4
    db 191
    dw 700
    db 4, 28
    dw 152, 52, 81, 120, 142, 142  ; HP MP ATK DEF AGL INT
    db 150, 150, 150, 0  ; AI weights
    db $43, $5D, $61, $FF  ; SuckAir, BlazeAir, IceAir, -
EnemyStats_108:  ; RockSlime Lv29 join 4
    db 11
    dw 830
    db 4, 29
    dw 186, 9, 140, 138, 89, 55  ; HP MP ATK DEF AGL INT
    db 250, 200, 150, 0  ; AI weights
    db $42, $5B, $8E, $FF  ; HighJump, RockThrow, StrongD, -
EnemyStats_109:  ; Chamelgon Lv29 join 4
    db 32
    dw 776
    db 4, 29
    dw 160, 149, 90, 88, 138, 85  ; HP MP ATK DEF AGL INT
    db 200, 50, 200, 0  ; AI weights
    db $19, $69, $FF, $FF  ; PanicAll, Paralyze, -, -
EnemyStats_110:  ; Goategon Lv29 join 4
    db 63
    dw 910
    db 4, 29
    dw 220, 120, 172, 92, 131, 132  ; HP MP ATK DEF AGL INT
    db 200, 50, 200, 0  ; AI weights
    db $04, $21, $6A, $FF  ; Firebane, SlowAll, SleepAir, -
EnemyStats_111:  ; DuckKite Lv28 join 3
    db 74
    dw 882
    db 3, 28
    dw 117, 115, 143, 138, 165, 140  ; HP MP ATK DEF AGL INT
    db 150, 50, 100, 0  ; AI weights
    db $15, $19, $6F, $FF  ; Sleep, PanicAll, Curse, -
EnemyStats_112:  ; CactiBall Lv28 join 3
    db 94
    dw 977
    db 3, 28
    dw 192, 165, 140, 65, 135, 130  ; HP MP ATK DEF AGL INT
    db 250, 150, 250, 0  ; AI weights
    db $42, $69, $75, $FF  ; HighJump, Paralyze, OddDance, -
EnemyStats_113:  ; TailEater Lv30 join 4
    db 120
    dw 960
    db 4, 30
    dw 160, 58, 116, 90, 121, 88  ; HP MP ATK DEF AGL INT
    db 150, 50, 150, 0  ; AI weights
    db $47, $6C, $73, $FF  ; IceSlash, PoisonGas, Radiant, -
EnemyStats_114:  ; AgDevil Lv31 join 4
    db 132
    dw 1005
    db 4, 31
    dw 160, 90, 148, 125, 90, 142  ; HP MP ATK DEF AGL INT
    db 200, 50, 150, 0  ; AI weights
    db $04, $6A, $FF, $FF  ; Firebane, SleepAir, -, -
EnemyStats_115:  ; WindMerge Lv31 join 4
    db 167
    dw 1100
    db 4, 31
    dw 116, 142, 98, 176, 122, 165  ; HP MP ATK DEF AGL INT
    db 150, 100, 200, 0  ; AI weights
    db $0B, $24, $36, $FF  ; Infermost, Barrier, CurseOff, -
EnemyStats_116:  ; WeedBug Lv31 join 4
    db 114
    dw 957
    db 4, 31
    dw 143, 90, 65, 140, 90, 141  ; HP MP ATK DEF AGL INT
    db 100, 150, 200, 0  ; AI weights
    db $1A, $24, $26, $FF  ; RobMagic, Barrier, MagicWall, -
EnemyStats_117:  ; SpotKing Lv32 join 5
    db 14
    dw 1200
    db 5, 32
    dw 300, 62, 206, 99, 115, 170  ; HP MP ATK DEF AGL INT
    db 200, 150, 150, 0  ; AI weights
    db $4E, $68, $92, $FF  ; CleanCut, NapAttack, MouthShut, -
EnemyStats_118:  ; LizardFly Lv28 join 4
    db 33
    dw 990
    db 4, 28
    dw 120, 93, 188, 99, 93, 90  ; HP MP ATK DEF AGL INT
    db 200, 100, 150, 0  ; AI weights
    db $04, $58, $5D, $FF  ; Firebane, WindBeast, BlazeAir, -
EnemyStats_119:  ; HammerMan Lv32 join 4
    db 57
    dw 1035
    db 4, 32
    dw 136, 60, 156, 100, 118, 62  ; HP MP ATK DEF AGL INT
    db 250, 0, 50, 0  ; AI weights
    db $3E, $40, $41, $FF  ; Kamikaze, EvilSlash, ChargeUP, -
EnemyStats_120:  ; MadGoose Lv28 join 4
    db 82
    dw 983
    db 4, 28
    dw 180, 197, 167, 190, 180, 96  ; HP MP ATK DEF AGL INT
    db 150, 100, 200, 0  ; AI weights
    db $19, $75, $78, $FF  ; PanicAll, OddDance, LureDance, -
EnemyStats_121:  ; TreeBoy Lv33 join 4
    db 101
    dw 1095
    db 4, 33
    dw 213, 185, 104, 100, 156, 185  ; HP MP ATK DEF AGL INT
    db 200, 200, 200, 0  ; AI weights
    db $0D, $2C, $36, $FF  ; SnowStorm, HealMore, CurseOff, -
EnemyStats_122:  ; Droll Lv33 join 4
    db 124
    dw 1152
    db 4, 33
    dw 132, 40, 142, 100, 68, 126  ; HP MP ATK DEF AGL INT
    db 150, 0, 100, 0  ; AI weights
    db $21, $D8, $FF, $FF  ; SlowAll, Branching, -, -
EnemyStats_123:  ; FunkyBird Lv30 join 0
    db 88
    dw 0
    db 0, 30
    dw 1200, 160, 100, 140, 98, 160  ; HP MP ATK DEF AGL INT
    db 150, 50, 150, 0  ; AI weights
    db $6E, $94, $96, $FF  ; PaniDance, Hustle, LifeDance, -
EnemyStats_124:  ; FunkyBird Lv30 join 0
    db 88
    dw 0
    db 0, 30
    dw 120, 160, 100, 140, 98, 160  ; HP MP ATK DEF AGL INT
    db 150, 50, 250, 0  ; AI weights
    db $6E, $94, $96, $FF  ; PaniDance, Hustle, LifeDance, -
EnemyStats_125:  ; SkyDragon Lv30 join 7
    db 43
    dw 7800
    db 7, 30
    dw 1200, 150, 170, 120, 80, 80  ; HP MP ATK DEF AGL INT
    db 200, 50, 200, 0  ; AI weights
    db $43, $5E, $FF, $FF  ; SuckAir, Scorching, -, -
EnemyStats_126:  ; SkyDragon Lv30 join 0
    db 43
    dw 0
    db 0, 30
    dw 125, 150, 170, 155, 80, 80  ; HP MP ATK DEF AGL INT
    db 150, 50, 200, 0  ; AI weights
    db $43, $5E, $FF, $FF  ; SuckAir, Scorching, -, -
EnemyStats_127:  ; Digster Lv45 join 0
    db 129
    dw 0
    db 0, 45
    dw 1000, 85, 190, 150, 60, 140  ; HP MP ATK DEF AGL INT
    db 150, 0, 150, 0  ; AI weights
    db $8E, $8F, $FF, $FF  ; StrongD, SuckAll, -, -
EnemyStats_128:  ; Digster Lv45 join 0
    db 129
    dw 0
    db 0, 45
    dw 230, 85, 190, 160, 60, 140  ; HP MP ATK DEF AGL INT
    db 150, 200, 150, 0  ; AI weights
    db $8E, $8F, $FF, $FF  ; StrongD, SuckAll, -, -
EnemyStats_129:  ; GiantMoth Lv28 join 4
    db 123
    dw 1187
    db 4, 28
    dw 155, 165, 155, 168, 186, 162  ; HP MP ATK DEF AGL INT
    db 200, 100, 200, 0  ; AI weights
    db $58, $69, $73, $FF  ; WindBeast, Paralyze, Radiant, -
EnemyStats_130:  ; ArcDemon Lv34 join 5
    db 131
    dw 1720
    db 5, 34
    dw 230, 98, 230, 180, 72, 250  ; HP MP ATK DEF AGL INT
    db 200, 50, 150, 0  ; AI weights
    db $07, $45, $4B, $FF  ; Boom, BoltSlash, BirdBlow, -
EnemyStats_131:  ; MadSpirit Lv34 join 5
    db 166
    dw 1368
    db 5, 34
    dw 160, 162, 203, 168, 100, 66  ; HP MP ATK DEF AGL INT
    db 200, 100, 250, 0  ; AI weights
    db $6A, $73, $83, $FF  ; SleepAir, Radiant, ThickFog, -
EnemyStats_132:  ; CurseLamp Lv40 join 4
    db 188
    dw 1213
    db 4, 40
    dw 200, 204, 182, 180, 102, 200  ; HP MP ATK DEF AGL INT
    db 200, 50, 200, 0  ; AI weights
    db $1F, $23, $25, $FF  ; Increase, SpeedUp, TwinHits, -
EnemyStats_133:  ; Tortragon Lv33 join 4
    db 21
    dw 1305
    db 4, 33
    dw 162, 104, 212, 250, 72, 104  ; HP MP ATK DEF AGL INT
    db 150, 100, 100, 0  ; AI weights
    db $28, $5A, $FF, $FF  ; Bounce, Lightning, -, -
EnemyStats_134:  ; WildApe Lv33 join 4
    db 64
    dw 1250
    db 4, 33
    dw 160, 68, 195, 75, 158, 100  ; HP MP ATK DEF AGL INT
    db 250, 0, 150, 0  ; AI weights
    db $3B, $53, $7C, $FF  ; TwinSlash, YellHelp, BigTrip, -
EnemyStats_135:  ; LandOwl Lv33 join 5
    db 81
    dw 1528
    db 5, 33
    dw 240, 71, 260, 110, 110, 70  ; HP MP ATK DEF AGL INT
    db 200, 0, 150, 0  ; AI weights
    db $0B, $45, $77, $FF  ; Infermost, BoltSlash, SideStep, -
EnemyStats_136:  ; AmberWeed Lv36 join 4
    db 97
    dw 1138
    db 4, 36
    dw 180, 192, 115, 140, 180, 70  ; HP MP ATK DEF AGL INT
    db 200, 100, 250, 0  ; AI weights
    db $24, $25, $26, $FF  ; Barrier, TwinHits, MagicWall, -
EnemyStats_137:  ; ArmyCrab Lv36 join 5
    db 125
    dw 1299
    db 5, 36
    dw 130, 108, 160, 230, 55, 72  ; HP MP ATK DEF AGL INT
    db 200, 100, 200, 0  ; AI weights
    db $1F, $48, $53, $FF  ; Increase, MetalCut, YellHelp, -
EnemyStats_138:  ; EvilBeast Lv30 join 5
    db 137
    dw 1203
    db 5, 30
    dw 150, 71, 202, 162, 56, 186  ; HP MP ATK DEF AGL INT
    db 200, 50, 200, 0  ; AI weights
    db $04, $61, $FF, $FF  ; Firebane, IceAir, -, -
EnemyStats_139:  ; Shadow Lv37 join 5
    db 162
    dw 1256
    db 5, 37
    dw 217, 134, 210, 210, 118, 185  ; HP MP ATK DEF AGL INT
    db 250, 50, 250, 0  ; AI weights
    db $61, $71, $83, $FF  ; IceAir, K.O.Dance, ThickFog, -
EnemyStats_140:  ; EvilWand Lv37 join 4
    db 176
    dw 1343
    db 4, 37
    dw 172, 130, 167, 230, 190, 100  ; HP MP ATK DEF AGL INT
    db 150, 50, 150, 0  ; AI weights
    db $35, $61, $FF, $FF  ; DeChaos, IceAir, -, -
EnemyStats_141:  ; SlimeBorg Lv38 join 5
    db 12
    dw 1444
    db 5, 38
    dw 250, 73, 205, 192, 200, 100  ; HP MP ATK DEF AGL INT
    db 250, 200, 200, 0  ; AI weights
    db $57, $5A, $90, $FF  ; RainSlash, Lightning, BladeD, -
EnemyStats_142:  ; LizardMan Lv38 join 4
    db 25
    dw 1347
    db 4, 38
    dw 210, 73, 182, 110, 105, 100  ; HP MP ATK DEF AGL INT
    db 250, 100, 50, 0  ; AI weights
    db $40, $4A, $FF, $FF  ; EvilSlash, BeastCut, -, -
EnemyStats_143:  ; Grizzly Lv38 join 5
    db 58
    dw 1560
    db 5, 38
    dw 230, 18, 285, 82, 200, 80  ; HP MP ATK DEF AGL INT
    db 250, 0, 150, 0  ; AI weights
    db $3B, $55, $7C, $FF  ; TwinSlash, SquallHit, BigTrip, -
EnemyStats_144:  ; Wyvern Lv39 join 4
    db 71
    dw 1580
    db 4, 39
    dw 193, 105, 165, 130, 160, 205  ; HP MP ATK DEF AGL INT
    db 200, 100, 150, 0  ; AI weights
    db $16, $2C, $61, $FF  ; SleepAll, HealMore, IceAir, -
EnemyStats_145:  ; FireWeed Lv36 join 4
    db 91
    dw 1440
    db 4, 36
    dw 180, 200, 83, 128, 155, 147  ; HP MP ATK DEF AGL INT
    db 250, 150, 200, 0  ; AI weights
    db $01, $35, $6B, $FF  ; Blazemore, DeChaos, PalsyAir, -
EnemyStats_146:  ; MadHornet Lv38 join 6
    db 126
    dw 1380
    db 6, 38
    dw 233, 105, 167, 112, 210, 120  ; HP MP ATK DEF AGL INT
    db 200, 0, 200, 0  ; AI weights
    db $67, $69, $8B, $FF  ; PoisonHit, Paralyze, StormWind, -
EnemyStats_147:  ; Jamirus Lv35 join 7
    db 153
    dw 13000
    db 7, 35
    dw 1600, 175, 260, 160, 150, 145  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 0  ; AI weights
    db $02, $51, $8B, $FF  ; Blazemost, QuadHits, StormWind, -
EnemyStats_148:  ; Jamirus Lv35 join 0
    db 153
    dw 0
    db 0, 35
    dw 200, 175, 260, 200, 150, 145  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 0  ; AI weights
    db $02, $51, $8B, $FF  ; Blazemost, QuadHits, StormWind, -
EnemyStats_149:  ; Servant Lv35 join 5
    db 173
    dw 15076
    db 5, 35
    dw 1000, 250, 160, 160, 200, 170  ; HP MP ATK DEF AGL INT
    db 250, 150, 250, 0  ; AI weights
    db $02, $0E, $54, $FF  ; Blazemost, Blizzard, Focus, -
EnemyStats_150:  ; Servant Lv35 join 0
    db 173
    dw 0
    db 0, 35
    dw 160, 250, 160, 180, 200, 170  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 0  ; AI weights
    db $02, $0E, $54, $FF  ; Blazemost, Blizzard, Focus, -
EnemyStats_151:  ; Centasaur Lv30 join 7
    db 151
    dw 0
    db 7, 30
    dw 220, 115, 205, 140, 320, 200  ; HP MP ATK DEF AGL INT
    db 250, 100, 200, 0  ; AI weights
    db $17, $44, $57, $FF  ; StopSpell, FireSlash, RainSlash, -
EnemyStats_152:  ; EvilArmor Lv28 join 7
    db 152
    dw 0
    db 7, 28
    dw 175, 98, 170, 220, 132, 146  ; HP MP ATK DEF AGL INT
    db 250, 50, 150, 0  ; AI weights
    db $44, $45, $49, $FF  ; FireSlash, BoltSlash, DrakSlash, -
EnemyStats_153:  ; KingSlime Lv38 join 5
    db 15
    dw 17000
    db 5, 38
    dw 2000, 75, 200, 130, 190, 190  ; HP MP ATK DEF AGL INT
    db 250, 150, 200, 0  ; AI weights
    db $24, $2C, $FF, $FF  ; Barrier, HealMore, -, -
EnemyStats_154:  ; KingSlime Lv38 join 0
    db 15
    dw 0
    db 0, 38
    dw 230, 75, 200, 160, 190, 190  ; HP MP ATK DEF AGL INT
    db 150, 250, 200, 0  ; AI weights
    db $24, $2C, $31, $FF  ; Barrier, HealMore, Revive, -
EnemyStats_155:  ; Toadstool Lv10 join 5
    db 96
    dw 300
    db 5, 10
    dw 45, 17, 25, 23, 40, 36  ; HP MP ATK DEF AGL INT
    db 0, 0, 0, 0  ; AI weights
    db $68, $6A, $92, $FF  ; NapAttack, SleepAir, MouthShut, -
EnemyStats_156:  ; Lipsy Lv10 join 5
    db 116
    dw 250
    db 5, 10
    dw 23, 17, 23, 22, 20, 72  ; HP MP ATK DEF AGL INT
    db 0, 0, 0, 0  ; AI weights
    db $68, $70, $79, $FF  ; NapAttack, Ahhh, LushLicks, -
EnemyStats_157:  ; Lionex Lv40 join 5
    db 141
    dw 1850
    db 5, 40
    dw 268, 130, 202, 246, 210, 160  ; HP MP ATK DEF AGL INT
    db 150, 150, 200, 0  ; AI weights
    db $0B, $2E, $46, $FF  ; Infermost, HealUs, VacuSlash, -
EnemyStats_158:  ; RotRaven Lv33 join 4
    db 158
    dw 1680
    db 4, 33
    dw 155, 145, 167, 132, 244, 210  ; HP MP ATK DEF AGL INT
    db 150, 50, 150, 0  ; AI weights
    db $3E, $45, $5A, $FF  ; Kamikaze, BoltSlash, Lightning, -
EnemyStats_159:  ; JewelBag Lv38 join 5
    db 175
    dw 2000
    db 5, 38
    dw 138, 126, 218, 246, 180, 240  ; HP MP ATK DEF AGL INT
    db 100, 0, 50, 0  ; AI weights
    db $04, $17, $19, $FF  ; Firebane, StopSpell, PanicAll, -
EnemyStats_160:  ; Swordgon Lv41 join 4
    db 27
    dw 1915
    db 4, 41
    dw 246, 165, 190, 213, 128, 115  ; HP MP ATK DEF AGL INT
    db 250, 200, 250, 0  ; AI weights
    db $4E, $57, $90, $FF  ; CleanCut, RainSlash, BladeD, -
EnemyStats_161:  ; SuperTen Lv41 join 5
    db 54
    dw 1872
    db 5, 41
    dw 276, 80, 148, 90, 218, 154  ; HP MP ATK DEF AGL INT
    db 250, 100, 200, 0  ; AI weights
    db $71, $7F, $94, $FF  ; K.O.Dance, Imitate, Hustle, -
EnemyStats_162:  ; MadCondor Lv41 join 5
    db 83
    dw 2075
    db 5, 41
    dw 190, 130, 256, 224, 160, 160  ; HP MP ATK DEF AGL INT
    db 200, 100, 0, 0  ; AI weights
    db $04, $2E, $FF, $FF  ; Firebane, HealUs, -, -
EnemyStats_163:  ; ManEater Lv42 join 6
    db 106
    dw 1996
    db 6, 42
    dw 192, 225, 176, 90, 115, 110  ; HP MP ATK DEF AGL INT
    db 250, 0, 200, 0  ; AI weights
    db $49, $56, $6A, $FF  ; DrakSlash, PsycheUp, SleepAir, -
EnemyStats_164:  ; Grendal Lv42 join 5
    db 147
    dw 2130
    db 5, 42
    dw 304, 82, 260, 310, 226, 226  ; HP MP ATK DEF AGL INT
    db 250, 200, 200, 0  ; AI weights
    db $44, $49, $89, $FF  ; FireSlash, DrakSlash, Guardian, -
EnemyStats_165:  ; DarkCrab Lv28 join 4
    db 160
    dw 1999
    db 4, 28
    dw 254, 135, 260, 222, 85, 140  ; HP MP ATK DEF AGL INT
    db 200, 100, 0, 0  ; AI weights
    db $26, $2A, $FF, $FF  ; MagicWall, Ironize, -, -
EnemyStats_166:  ; MadMirror Lv38 join 5
    db 181
    dw 2184
    db 5, 38
    dw 284, 92, 145, 204, 232, 170  ; HP MP ATK DEF AGL INT
    db 150, 150, 150, 0  ; AI weights
    db $28, $29, $FF, $FF  ; Bounce, Transform, -, -
EnemyStats_167:  ; WingSnake Lv43 join 4
    db 39
    dw 2030
    db 4, 43
    dw 284, 138, 230, 177, 170, 140  ; HP MP ATK DEF AGL INT
    db 250, 0, 150, 0  ; AI weights
    db $42, $55, $6D, $FF  ; HighJump, SquallHit, PoisonAir, -
EnemyStats_168:  ; Yeti Lv38 join 5
    db 59
    dw 1820
    db 5, 38
    dw 287, 140, 264, 230, 100, 140  ; HP MP ATK DEF AGL INT
    db 250, 150, 200, 0  ; AI weights
    db $0D, $47, $7D, $FF  ; SnowStorm, IceSlash, WarCry, -
EnemyStats_169:  ; DanceVegi Lv44 join 4
    db 100
    dw 1770
    db 4, 44
    dw 176, 122, 124, 240, 316, 150  ; HP MP ATK DEF AGL INT
    db 200, 100, 200, 0  ; AI weights
    db $71, $77, $78, $FF  ; K.O.Dance, SideStep, LureDance, -
EnemyStats_170:  ; Ogre Lv33 join 4
    db 144
    dw 2320
    db 4, 33
    dw 288, 140, 235, 235, 104, 230  ; HP MP ATK DEF AGL INT
    db 250, 0, 100, 0  ; AI weights
    db $3F, $48, $57, $FF  ; Massacre, MetalCut, RainSlash, -
EnemyStats_171:  ; Skullgon Lv43 join 5
    db 156
    dw 2516
    db 5, 43
    dw 420, 87, 258, 80, 135, 230  ; HP MP ATK DEF AGL INT
    db 250, 100, 150, 0  ; AI weights
    db $3B, $47, $61, $FF  ; TwinSlash, IceSlash, IceAir, -
EnemyStats_172:  ; Voodoll Lv33 join 4
    db 184
    dw 2160
    db 4, 33
    dw 204, 180, 220, 256, 150, 170  ; HP MP ATK DEF AGL INT
    db 200, 50, 250, 0  ; AI weights
    db $18, $19, $1D, $FF  ; Surround, PanicAll, Defence, -
EnemyStats_173:  ; Rayburn Lv33 join 6
    db 31
    dw 2604
    db 6, 33
    dw 206, 110, 235, 115, 265, 110  ; HP MP ATK DEF AGL INT
    db 250, 100, 150, 0  ; AI weights
    db $46, $4C, $67, $FF  ; VacuSlash, DevilCut, PoisonHit, -
EnemyStats_174:  ; IronTurt Lv43 join 5
    db 55
    dw 2248
    db 5, 43
    dw 300, 120, 258, 200, 120, 180  ; HP MP ATK DEF AGL INT
    db 100, 250, 250, 0  ; AI weights
    db $28, $89, $8E, $FF  ; Bounce, Guardian, StrongD, -
EnemyStats_175:  ; DarkHorn Lv40 join 5
    db 67
    dw 21076
    db 5, 40
    dw 2000, 130, 225, 120, 80, 210  ; HP MP ATK DEF AGL INT
    db 250, 0, 200, 0  ; AI weights
    db $16, $17, $56, $FF  ; SleepAll, StopSpell, PsycheUp, -
EnemyStats_176:  ; DarkHorn Lv40 join 0
    db 67
    dw 0
    db 0, 40
    dw 170, 130, 245, 150, 80, 250  ; HP MP ATK DEF AGL INT
    db 250, 0, 250, 0  ; AI weights
    db $16, $17, $56, $FF  ; SleepAll, StopSpell, PsycheUp, -
EnemyStats_177:  ; Akubar Lv40 join 7
    db 148
    dw 23000
    db 7, 40
    dw 2000, 400, 230, 240, 250, 255  ; HP MP ATK DEF AGL INT
    db 200, 100, 200, 0  ; AI weights
    db $08, $54, $62, $FF  ; Explodet, Focus, IceStorm, -
EnemyStats_178:  ; Akubar Lv40 join 0
    db 148
    dw 0
    db 0, 40
    dw 300, 400, 200, 300, 250, 255  ; HP MP ATK DEF AGL INT
    db 250, 100, 200, 0  ; AI weights
    db $08, $54, $62, $FF  ; Explodet, Focus, IceStorm, -
EnemyStats_179:  ; Orochi Lv40 join 7
    db 41
    dw 28000
    db 7, 40
    dw 2000, 110, 300, 210, 130, 130  ; HP MP ATK DEF AGL INT
    db 250, 0, 250, 0  ; AI weights
    db $44, $51, $5E, $FF  ; FireSlash, QuadHits, Scorching, -
EnemyStats_180:  ; Orochi Lv40 join 0
    db 41
    dw 0
    db 0, 40
    dw 310, 110, 300, 260, 130, 130  ; HP MP ATK DEF AGL INT
    db 250, 0, 250, 0  ; AI weights
    db $44, $51, $5E, $FF  ; FireSlash, QuadHits, Scorching, -
EnemyStats_181:  ; Metabble Lv38 join 6
    db 17
    dw 65000
    db 6, 38
    dw 8, 490, 95, 770, 511, 255  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 0  ; AI weights
    db $05, $08, $DB, $FF  ; Firebolt, Explodet, RUN, -
EnemyStats_182:  ; GulpBeast Lv38 join 5
    db 50
    dw 2480
    db 5, 38
    dw 360, 90, 300, 185, 150, 90  ; HP MP ATK DEF AGL INT
    db 250, 0, 150, 0  ; AI weights
    db $3D, $3F, $7D, $FF  ; Beserker, Massacre, WarCry, -
EnemyStats_183:  ; Balzak Lv38 join 5
    db 186
    dw 2560
    db 5, 38
    dw 350, 165, 250, 320, 280, 180  ; HP MP ATK DEF AGL INT
    db 250, 100, 200, 0  ; AI weights
    db $08, $10, $FF, $FF  ; Explodet, Zap, -, -
EnemyStats_184:  ; Spikerous Lv28 join 5
    db 36
    dw 2700
    db 5, 28
    dw 250, 23, 270, 340, 90, 113  ; HP MP ATK DEF AGL INT
    db 250, 150, 150, 0  ; AI weights
    db $3D, $3E, $5B, $FF  ; Beserker, Kamikaze, RockThrow, -
EnemyStats_185:  ; Trumpeter Lv47 join 5
    db 65
    dw 2800
    db 5, 47
    dw 270, 150, 330, 210, 190, 130  ; HP MP ATK DEF AGL INT
    db 200, 100, 150, 0  ; AI weights
    db $3D, $72, $7D, $FF  ; Beserker, SandStorm, WarCry, -
EnemyStats_186:  ; Skeletor Lv47 join 5
    db 172
    dw 2770
    db 5, 47
    dw 180, 175, 310, 260, 145, 180  ; HP MP ATK DEF AGL INT
    db 250, 50, 250, 0  ; AI weights
    db $1D, $4B, $51, $FF  ; Defence, BirdBlow, QuadHits, -
EnemyStats_187:  ; MetalDrak Lv43 join 6
    db 185
    dw 3360
    db 6, 43
    dw 330, 105, 280, 260, 250, 130  ; HP MP ATK DEF AGL INT
    db 150, 50, 100, 0  ; AI weights
    db $3F, $5B, $72, $FF  ; Massacre, RockThrow, SandStorm, -
EnemyStats_188:  ; MadDragon Lv33 join 5
    db 30
    dw 3150
    db 5, 33
    dw 220, 24, 335, 130, 90, 30  ; HP MP ATK DEF AGL INT
    db 250, 0, 150, 0  ; AI weights
    db $3F, $40, $78, $FF  ; Massacre, EvilSlash, LureDance, -
EnemyStats_189:  ; Snapper Lv48 join 5
    db 107
    dw 2880
    db 5, 48
    dw 235, 185, 250, 140, 140, 230  ; HP MP ATK DEF AGL INT
    db 200, 100, 150, 0  ; AI weights
    db $17, $53, $57, $FF  ; StopSpell, YellHelp, RainSlash, -
EnemyStats_190:  ; GoatHorn Lv33 join 6
    db 142
    dw 3520
    db 6, 33
    dw 270, 190, 260, 150, 190, 240  ; HP MP ATK DEF AGL INT
    db 250, 100, 250, 0  ; AI weights
    db $08, $0B, $0E, $FF  ; Explodet, Infermost, Blizzard, -
EnemyStats_191:  ; DeadNoble Lv48 join 5
    db 169
    dw 2990
    db 5, 48
    dw 360, 240, 340, 280, 280, 215  ; HP MP ATK DEF AGL INT
    db 250, 100, 200, 0  ; AI weights
    db $13, $2F, $FF, $FF  ; Defeat, HealUsAll, -, -
EnemyStats_192:  ; Roboster Lv38 join 5
    db 189
    dw 3540
    db 5, 38
    dw 300, 45, 340, 230, 360, 210  ; HP MP ATK DEF AGL INT
    db 250, 50, 200, 0  ; AI weights
    db $51, $55, $57, $FF  ; QuadHits, SquallHit, RainSlash, -
EnemyStats_193:  ; BombCrag Lv48 join 4
    db 198
    dw 2500
    db 4, 48
    dw 310, 190, 175, 250, 25, 140  ; HP MP ATK DEF AGL INT
    db 200, 100, 150, 0  ; AI weights
    db $14, $32, $93, $FF  ; Sacrifice, Farewell, Meditate, -
EnemyStats_194:  ; Andreal Lv48 join 5
    db 34
    dw 3480
    db 5, 48
    dw 360, 280, 230, 320, 200, 250  ; HP MP ATK DEF AGL INT
    db 250, 0, 200, 0  ; AI weights
    db $0B, $18, $6D, $FF  ; Infermost, Surround, PoisonAir, -
EnemyStats_195:  ; Unicorn Lv48 join 5
    db 62
    dw 3120
    db 5, 48
    dw 180, 330, 180, 150, 290, 255  ; HP MP ATK DEF AGL INT
    db 250, 200, 250, 0  ; AI weights
    db $2D, $31, $33, $FF  ; HealAll, Revive, Antidote, -
EnemyStats_196:  ; GreatDrak Lv51 join 5
    db 37
    dw 3580
    db 5, 51
    dw 370, 130, 260, 210, 170, 210  ; HP MP ATK DEF AGL INT
    db 250, 200, 250, 0  ; AI weights
    db $47, $62, $8F, $FF  ; IceSlash, IceStorm, SuckAll, -
EnemyStats_197:  ; ZapBird Lv48 join 5
    db 86
    dw 3320
    db 5, 48
    dw 280, 120, 210, 200, 240, 255  ; HP MP ATK DEF AGL INT
    db 250, 150, 150, 0  ; AI weights
    db $45, $5A, $FF, $FF  ; BoltSlash, Lightning, -, -
EnemyStats_198:  ; WhipBird Lv51 join 6
    db 87
    dw 3076
    db 6, 51
    dw 500, 200, 175, 250, 240, 230  ; HP MP ATK DEF AGL INT
    db 200, 100, 150, 0  ; AI weights
    db $2A, $83, $FF, $FF  ; Ironize, ThickFog, -, -
EnemyStats_199:  ; Durran Lv45 join 7
    db 154
    dw 31000
    db 7, 45
    dw 3000, 330, 420, 380, 370, 10  ; HP MP ATK DEF AGL INT
    db 200, 0, 100, 0  ; AI weights
    db $49, $4B, $59, $FF  ; DrakSlash, BirdBlow, Vacuum, -
EnemyStats_200:  ; Durran Lv45 join 0
    db 154
    dw 0
    db 0, 45
    dw 220, 330, 380, 250, 190, 255  ; HP MP ATK DEF AGL INT
    db 200, 0, 200, 0  ; AI weights
    db $49, $4B, $59, $FF  ; DrakSlash, BirdBlow, Vacuum, -
EnemyStats_201:  ; DracoLord Lv48 join 7
    db 200
    dw 26000
    db 7, 48
    dw 4000, 550, 340, 320, 230, 255  ; HP MP ATK DEF AGL INT
    db 250, 200, 200, 0  ; AI weights
    db $05, $93, $D5, $FF  ; Firebolt, Meditate, BeDragon, -
EnemyStats_202:  ; DracoLord Lv48 join 0
    db 200
    dw 0
    db 0, 48
    dw 250, 550, 340, 260, 230, 255  ; HP MP ATK DEF AGL INT
    db 100, 200, 250, 0  ; AI weights
    db $05, $93, $D5, $FF  ; Firebolt, Meditate, BeDragon, -
EnemyStats_203:  ; Hargon Lv50 join 7
    db 202
    dw 38000
    db 7, 50
    dw 4000, 550, 260, 400, 230, 255  ; HP MP ATK DEF AGL INT
    db 250, 50, 250, 0  ; AI weights
    db $05, $08, $87, $FF  ; Firebolt, Explodet, BazooCall, -
EnemyStats_204:  ; Hargon Lv50 join 0
    db 202
    dw 0
    db 0, 50
    dw 190, 550, 260, 340, 230, 255  ; HP MP ATK DEF AGL INT
    db 150, 50, 250, 0  ; AI weights
    db $05, $08, $87, $FF  ; Firebolt, Explodet, BazooCall, -
EnemyStats_205:  ; Sidoh Lv50 join 7
    db 203
    dw 38000
    db 7, 50
    dw 6000, 999, 530, 340, 230, 10  ; HP MP ATK DEF AGL INT
    db 200, 0, 200, 0  ; AI weights
    db $5F, $63, $64, $FF  ; WhiteFire, WhiteAir, Hellblast, -
EnemyStats_206:  ; Sidoh Lv50 join 0
    db 203
    dw 0
    db 0, 50
    dw 370, 550, 370, 340, 230, 255  ; HP MP ATK DEF AGL INT
    db 200, 0, 200, 0  ; AI weights
    db $5F, $65, $80, $FF  ; WhiteFire, BigBang, DeMagic, -
EnemyStats_207:  ; Baramos Lv50 join 7
    db 204
    dw 43000
    db 7, 50
    dw 4000, 999, 410, 550, 230, 10  ; HP MP ATK DEF AGL INT
    db 250, 0, 150, 0  ; AI weights
    db $08, $5B, $64, $FF  ; Explodet, RockThrow, Hellblast, -
EnemyStats_208:  ; Baramos Lv50 join 0
    db 204
    dw 0
    db 0, 50
    dw 250, 550, 260, 260, 230, 255  ; HP MP ATK DEF AGL INT
    db 250, 0, 100, 0  ; AI weights
    db $19, $64, $65, $FF  ; PanicAll, Hellblast, BigBang, -
EnemyStats_209:  ; Zoma Lv55 join 7
    db 205
    dw 45076
    db 7, 55
    dw 4500, 999, 440, 400, 260, 255  ; HP MP ATK DEF AGL INT
    db 250, 0, 200, 0  ; AI weights
    db $63, $65, $80, $FF  ; WhiteAir, BigBang, DeMagic, -
EnemyStats_210:  ; Zoma Lv55 join 0
    db 205
    dw 0
    db 0, 55
    dw 400, 600, 420, 350, 260, 255  ; HP MP ATK DEF AGL INT
    db 250, 0, 200, 0  ; AI weights
    db $54, $63, $80, $FF  ; Focus, WhiteAir, DeMagic, -
EnemyStats_211:  ; Pizzaro Lv55 join 7
    db 206
    dw 39076
    db 7, 55
    dw 6000, 600, 510, 450, 260, 20  ; HP MP ATK DEF AGL INT
    db 250, 50, 200, 0  ; AI weights
    db $51, $5F, $64, $FF  ; QuadHits, WhiteFire, Hellblast, -
EnemyStats_212:  ; Pizzaro Lv55 join 0
    db 206
    dw 0
    db 0, 55
    dw 360, 600, 420, 350, 260, 255  ; HP MP ATK DEF AGL INT
    db 100, 250, 200, 0  ; AI weights
    db $51, $63, $82, $FF  ; QuadHits, WhiteAir, UltraDown, -
EnemyStats_213:  ; Esterk Lv60 join 7
    db 207
    dw 42076
    db 7, 60
    dw 3800, 700, 560, 520, 450, 255  ; HP MP ATK DEF AGL INT
    db 250, 0, 250, 0  ; AI weights
    db $57, $80, $D9, $FF  ; RainSlash, DeMagic, GigaSlash, -
EnemyStats_214:  ; Esterk Lv60 join 0
    db 207
    dw 0
    db 0, 60
    dw 600, 700, 460, 450, 300, 255  ; HP MP ATK DEF AGL INT
    db 250, 0, 250, 0  ; AI weights
    db $54, $5F, $80, $FF  ; Focus, WhiteFire, DeMagic, -
EnemyStats_215:  ; Mirudraas Lv60 join 7
    db 208
    dw 48076
    db 7, 60
    dw 5000, 999, 520, 480, 300, 10  ; HP MP ATK DEF AGL INT
    db 250, 0, 200, 0  ; AI weights
    db $02, $08, $11, $FF  ; Blazemost, Explodet, Thordain, -
EnemyStats_216:  ; Mirudraas Lv60 join 0
    db 208
    dw 0
    db 0, 60
    dw 380, 700, 460, 380, 300, 255  ; HP MP ATK DEF AGL INT
    db 250, 0, 200, 0  ; AI weights
    db $02, $08, $0E, $FF  ; Blazemost, Explodet, Blizzard, -
EnemyStats_217:  ; Mudou Lv60 join 7
    db 210
    dw 45076
    db 7, 60
    dw 5000, 999, 530, 450, 300, 10  ; HP MP ATK DEF AGL INT
    db 250, 100, 150, 0  ; AI weights
    db $5F, $63, $6D, $FF  ; WhiteFire, WhiteAir, PoisonAir, -
EnemyStats_218:  ; Mudou Lv60 join 0
    db 210
    dw 0
    db 0, 60
    dw 380, 700, 460, 450, 300, 255  ; HP MP ATK DEF AGL INT
    db 50, 100, 150, 0  ; AI weights
    db $5F, $63, $6A, $FF  ; WhiteFire, WhiteAir, SleepAir, -
EnemyStats_219:  ; DeathMore Lv58 join 7
    db 211
    dw 50000
    db 7, 58
    dw 9000, 700, 460, 520, 450, 255  ; HP MP ATK DEF AGL INT
    db 250, 0, 200, 0  ; AI weights
    db $64, $65, $86, $FF  ; Hellblast, BigBang, SamsiCall, -
EnemyStats_220:  ; DeathMore Lv58 join 0
    db 211
    dw 0
    db 0, 58
    dw 380, 700, 460, 380, 300, 255  ; HP MP ATK DEF AGL INT
    db 250, 0, 250, 0  ; AI weights
    db $08, $64, $6D, $FF  ; Explodet, Hellblast, PoisonAir, -
EnemyStats_221:  ; Darkdrium Lv70 join 0
    db 214
    dw 65000
    db 0, 70
    dw 9000, 850, 780, 520, 390, 10  ; HP MP ATK DEF AGL INT
    db 250, 150, 250, 0  ; AI weights
    db $50, $5F, $63, $FF  ; BiAttack, WhiteFire, WhiteAir, -
EnemyStats_222:  ; Darkdrium Lv70 join 0
    db 214
    dw 0
    db 0, 70
    dw 999, 850, 999, 520, 390, 255  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 0  ; AI weights
    db $50, $5F, $63, $FF  ; BiAttack, WhiteFire, WhiteAir, -
EnemyStats_223:  ; Watabou Lv20 join 0
    db 109
    dw 0
    db 0, 20
    dw 150, 460, 160, 205, 370, 255  ; HP MP ATK DEF AGL INT
    db 0, 250, 250, 0  ; AI weights
    db $39, $7E, $7F, $FF  ; Chance, Whistle, Imitate, -
EnemyStats_224:  ; Dracky Lv1 join 7
    db 78
    dw 0
    db 7, 1
    dw 8, 20, 12, 4, 12, 14  ; HP MP ATK DEF AGL INT
    db 200, 0, 0, 150  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_225:  ; Anteater Lv1 join 7
    db 53
    dw 0
    db 7, 1
    dw 12, 0, 17, 4, 4, 3  ; HP MP ATK DEF AGL INT
    db 150, 0, 50, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_226:  ; Dracky Lv1 join 7
    db 78
    dw 0
    db 7, 1
    dw 8, 20, 11, 3, 10, 14  ; HP MP ATK DEF AGL INT
    db 200, 0, 0, 150  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_227:  ; Slime Lv1 join 7
    db 8
    dw 0
    db 7, 1
    dw 8, 0, 8, 5, 7, 1  ; HP MP ATK DEF AGL INT
    db 200, 50, 100, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_228:  ; Stubsuck Lv2 join 7
    db 98
    dw 0
    db 7, 2
    dw 16, 6, 19, 7, 10, 10  ; HP MP ATK DEF AGL INT
    db 100, 50, 200, 100  ; AI weights
    db $15, $FF, $FF, $FF  ; Sleep, -, -, -
EnemyStats_229:  ; Slime Lv1 join 7
    db 8
    dw 0
    db 7, 1
    dw 7, 0, 8, 5, 6, 1  ; HP MP ATK DEF AGL INT
    db 200, 50, 100, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_230:  ; Spooky Lv7 join 7
    db 155
    dw 0
    db 7, 7
    dw 16, 8, 13, 12, 17, 16  ; HP MP ATK DEF AGL INT
    db 200, 0, 200, 200  ; AI weights
    db $79, $FF, $FF, $FF  ; LushLicks, -, -, -
EnemyStats_231:  ; Hork Lv5 join 7
    db 163
    dw 0
    db 7, 5
    dw 20, 6, 20, 6, 10, 10  ; HP MP ATK DEF AGL INT
    db 100, 0, 0, 50  ; AI weights
    db $6C, $79, $FF, $FF  ; PoisonGas, LushLicks, -, -
EnemyStats_232:  ; Spooky Lv7 join 7
    db 155
    dw 0
    db 7, 7
    dw 14, 8, 15, 9, 11, 13  ; HP MP ATK DEF AGL INT
    db 200, 0, 200, 200  ; AI weights
    db $79, $FF, $FF, $FF  ; LushLicks, -, -, -
EnemyStats_233:  ; SpotSlime Lv8 join 7
    db 1
    dw 0
    db 7, 8
    dw 26, 11, 30, 17, 30, 11  ; HP MP ATK DEF AGL INT
    db 200, 0, 100, 150  ; AI weights
    db $52, $FF, $FF, $FF  ; CallHelp, -, -, -
EnemyStats_234:  ; SpotSlime Lv9 join 7
    db 1
    dw 0
    db 7, 9
    dw 20, 12, 26, 15, 30, 32  ; HP MP ATK DEF AGL INT
    db 50, 0, 150, 0  ; AI weights
    db $79, $FF, $FF, $FF  ; LushLicks, -, -, -
EnemyStats_235:  ; SpotSlime Lv8 join 7
    db 1
    dw 0
    db 7, 8
    dw 24, 15, 28, 14, 32, 11  ; HP MP ATK DEF AGL INT
    db 200, 0, 200, 150  ; AI weights
    db $7F, $FF, $FF, $FF  ; Imitate, -, -, -
EnemyStats_236:  ; MudDoll Lv12 join 7
    db 195
    dw 0
    db 7, 12
    dw 38, 20, 22, 18, 24, 44  ; HP MP ATK DEF AGL INT
    db 100, 0, 250, 50  ; AI weights
    db $75, $FF, $FF, $FF  ; OddDance, -, -, -
EnemyStats_237:  ; Almiraj Lv10 join 7
    db 46
    dw 0
    db 7, 10
    dw 42, 26, 26, 20, 40, 22  ; HP MP ATK DEF AGL INT
    db 150, 0, 100, 100  ; AI weights
    db $15, $3C, $41, $FF  ; Sleep, Ramming, ChargeUP, -
EnemyStats_238:  ; MudDoll Lv12 join 7
    db 195
    dw 0
    db 7, 12
    dw 40, 44, 20, 22, 22, 44  ; HP MP ATK DEF AGL INT
    db 50, 0, 250, 50  ; AI weights
    db $77, $FF, $FF, $FF  ; SideStep, -, -, -
EnemyStats_239:  ; Putrepup Lv12 join 7
    db 157
    dw 0
    db 7, 12
    dw 75, 10, 28, 24, 30, 20  ; HP MP ATK DEF AGL INT
    db 200, 0, 150, 150  ; AI weights
    db $1C, $20, $FF, $FF  ; Sap, Slow, -, -
EnemyStats_240:  ; MadRaven Lv12 join 7
    db 76
    dw 0
    db 7, 12
    dw 50, 12, 30, 24, 60, 80  ; HP MP ATK DEF AGL INT
    db 200, 0, 100, 150  ; AI weights
    db $42, $8A, $FF, $FF  ; HighJump, TailWind, -, -
EnemyStats_241:  ; Skullroo Lv12 join 7
    db 51
    dw 0
    db 7, 12
    dw 58, 8, 38, 18, 50, 50  ; HP MP ATK DEF AGL INT
    db 150, 0, 100, 50  ; AI weights
    db $41, $6E, $FF, $FF  ; ChargeUP, PaniDance, -, -
EnemyStats_242:  ; Crestpent Lv8 join 7
    db 38
    dw 0
    db 7, 8
    dw 60, 8, 20, 30, 15, 9  ; HP MP ATK DEF AGL INT
    db 200, 0, 100, 100  ; AI weights
    db $17, $67, $D5, $FF  ; StopSpell, PoisonHit, BeDragon, -
EnemyStats_243:  ; TreeSlime Lv12 join 7
    db 3
    dw 0
    db 7, 12
    dw 70, 8, 30, 26, 49, 46  ; HP MP ATK DEF AGL INT
    db 100, 0, 250, 200  ; AI weights
    db $1C, $69, $6A, $FF  ; Sap, Paralyze, SleepAir, -
EnemyStats_244:  ; Poisongon Lv12 join 7
    db 26
    dw 0
    db 7, 12
    dw 50, 14, 35, 30, 26, 23  ; HP MP ATK DEF AGL INT
    db 150, 0, 50, 0  ; AI weights
    db $67, $6C, $FF, $FF  ; PoisonHit, PoisonGas, -, -
EnemyStats_245:  ; DrakSlime Lv14 join 7
    db 0
    dw 0
    db 7, 14
    dw 40, 16, 30, 26, 96, 52  ; HP MP ATK DEF AGL INT
    db 100, 0, 200, 150  ; AI weights
    db $43, $5C, $FF, $FF  ; SuckAir, FireAir, -, -
EnemyStats_246:  ; Dragon Lv15 join 7
    db 28
    dw 0
    db 7, 15
    dw 65, 20, 45, 40, 30, 26  ; HP MP ATK DEF AGL INT
    db 250, 0, 0, 250  ; AI weights
    db $44, $5C, $FF, $FF  ; FireSlash, FireAir, -, -
EnemyStats_247:  ; FairyDrak Lv14 join 7
    db 24
    dw 0
    db 7, 14
    dw 40, 21, 25, 30, 51, 27  ; HP MP ATK DEF AGL INT
    db 150, 0, 100, 50  ; AI weights
    db $18, $6A, $FF, $FF  ; Surround, SleepAir, -, -
EnemyStats_248:  ; Snaily Lv16 join 7
    db 4
    dw 0
    db 7, 16
    dw 45, 20, 30, 60, 110, 60  ; HP MP ATK DEF AGL INT
    db 150, 100, 0, 150  ; AI weights
    db $0C, $FF, $FF, $FF  ; IceBolt, -, -, -
EnemyStats_249:  ; ArmorPede Lv20 join 7
    db 121
    dw 0
    db 7, 20
    dw 80, 27, 40, 72, 40, 68  ; HP MP ATK DEF AGL INT
    db 250, 0, 100, 50  ; AI weights
    db $1E, $25, $3B, $FF  ; Upper, TwinHits, TwinSlash, -
EnemyStats_250:  ; Snaily Lv16 join 7
    db 4
    dw 0
    db 7, 16
    dw 40, 20, 32, 55, 110, 60  ; HP MP ATK DEF AGL INT
    db 150, 50, 0, 150  ; AI weights
    db $52, $FF, $FF, $FF  ; CallHelp, -, -, -
EnemyStats_251:  ; Saccer Lv17 join 7
    db 49
    dw 0
    db 7, 17
    dw 80, 31, 48, 82, 9, 62  ; HP MP ATK DEF AGL INT
    db 150, 0, 200, 100  ; AI weights
    db $1E, $56, $FF, $FF  ; Upper, PsycheUp, -, -
EnemyStats_252:  ; Florajay Lv19 join 7
    db 73
    dw 0
    db 7, 19
    dw 50, 56, 55, 42, 142, 120  ; HP MP ATK DEF AGL INT
    db 100, 50, 100, 250  ; AI weights
    db $23, $4A, $95, $FF  ; SpeedUp, BeastCut, LifeSong, -
EnemyStats_253:  ; MadPlant Lv20 join 7
    db 90
    dw 0
    db 7, 20
    dw 100, 100, 52, 50, 135, 91  ; HP MP ATK DEF AGL INT
    db 200, 0, 250, 100  ; AI weights
    db $1C, $20, $34, $FF  ; Sap, Slow, NumbOff, -
EnemyStats_254:  ; MedusaEye Lv20 join 7
    db 140
    dw 0
    db 7, 20
    dw 70, 48, 40, 96, 48, 44  ; HP MP ATK DEF AGL INT
    db 100, 0, 100, 250  ; AI weights
    db $18, $1C, $D8, $FF  ; Surround, Sap, Branching, -
EnemyStats_255:  ; MadGopher Lv21 join 7
    db 60
    dw 0
    db 7, 21
    dw 100, 38, 61, 45, 54, 48  ; HP MP ATK DEF AGL INT
    db 250, 0, 0, 200  ; AI weights
    db $41, $4B, $4D, $FF  ; ChargeUP, BirdBlow, ZombieCut, -
EnemyStats_256:  ; MedusaEye Lv20 join 7
    db 140
    dw 0
    db 7, 20
    dw 70, 68, 44, 90, 48, 44  ; HP MP ATK DEF AGL INT
    db 100, 0, 100, 250  ; AI weights
    db $18, $1C, $D8, $FF  ; Surround, Sap, Branching, -
EnemyStats_257:  ; MadCat Lv20 join 7
    db 68
    dw 0
    db 7, 20
    dw 100, 28, 65, 60, 80, 45  ; HP MP ATK DEF AGL INT
    db 200, 50, 200, 250  ; AI weights
    db $46, $55, $7B, $FF  ; VacuSlash, SquallHit, LegSweep, -
EnemyStats_258:  ; RogueNite Lv27 join 7
    db 182
    dw 0
    db 7, 27
    dw 110, 38, 80, 100, 50, 79  ; HP MP ATK DEF AGL INT
    db 250, 250, 150, 200  ; AI weights
    db $2B, $40, $48, $FF  ; Heal, EvilSlash, MetalCut, -
EnemyStats_259:  ; MadCat Lv20 join 7
    db 68
    dw 0
    db 7, 20
    dw 100, 28, 72, 50, 80, 45  ; HP MP ATK DEF AGL INT
    db 250, 50, 200, 250  ; AI weights
    db $46, $55, $7B, $FF  ; VacuSlash, SquallHit, LegSweep, -
EnemyStats_260:  ; SpikyBoy Lv24 join 7
    db 180
    dw 0
    db 7, 24
    dw 80, 26, 70, 83, 50, 63  ; HP MP ATK DEF AGL INT
    db 150, 100, 100, 250  ; AI weights
    db $14, $42, $D6, $FF  ; Sacrifice, HighJump, Smashlime, -
EnemyStats_261:  ; StubBird Lv23 join 7
    db 80
    dw 0
    db 7, 23
    dw 100, 44, 100, 120, 90, 82  ; HP MP ATK DEF AGL INT
    db 250, 50, 50, 100  ; AI weights
    db $25, $57, $D7, $FF  ; TwinHits, RainSlash, Sheldodge, -
EnemyStats_262:  ; SpikyBoy Lv24 join 7
    db 180
    dw 0
    db 7, 24
    dw 80, 46, 75, 83, 50, 63  ; HP MP ATK DEF AGL INT
    db 150, 100, 100, 250  ; AI weights
    db $14, $42, $D6, $FF  ; Sacrifice, HighJump, Smashlime, -
EnemyStats_263:  ; Healer Lv22 join 7
    db 9
    dw 0
    db 7, 22
    dw 80, 50, 16, 80, 37, 250  ; HP MP ATK DEF AGL INT
    db 200, 250, 100, 200  ; AI weights
    db $2B, $FF, $FF, $FF  ; Heal, -, -, -
EnemyStats_264:  ; RogueNite Lv27 join 7
    db 182
    dw 0
    db 7, 27
    dw 180, 48, 150, 120, 50, 79  ; HP MP ATK DEF AGL INT
    db 250, 50, 150, 200  ; AI weights
    db $2B, $40, $48, $FF  ; Heal, EvilSlash, MetalCut, -
EnemyStats_265:  ; Healer Lv22 join 7
    db 9
    dw 0
    db 7, 22
    dw 90, 50, 16, 80, 37, 250  ; HP MP ATK DEF AGL INT
    db 200, 250, 100, 200  ; AI weights
    db $2B, $FF, $FF, $FF  ; Heal, -, -, -
EnemyStats_266:  ; BoxSlime Lv27 join 7
    db 7
    dw 0
    db 7, 27
    dw 240, 39, 122, 100, 145, 76  ; HP MP ATK DEF AGL INT
    db 100, 50, 200, 150  ; AI weights
    db $1E, $3C, $FF, $FF  ; Upper, Ramming, -, -
EnemyStats_267:  ; RockSlime Lv29 join 7
    db 11
    dw 0
    db 7, 29
    dw 170, 20, 155, 160, 89, 55  ; HP MP ATK DEF AGL INT
    db 200, 100, 150, 250  ; AI weights
    db $42, $8E, $FF, $FF  ; HighJump, StrongD, -, -
EnemyStats_268:  ; BoxSlime Lv27 join 7
    db 7
    dw 0
    db 7, 27
    dw 240, 29, 122, 100, 145, 76  ; HP MP ATK DEF AGL INT
    db 200, 150, 150, 150  ; AI weights
    db $01, $3C, $FF, $FF  ; Blazemore, Ramming, -, -
EnemyStats_269:  ; HammerMan Lv32 join 7
    db 57
    dw 0
    db 7, 32
    dw 150, 30, 110, 90, 118, 62  ; HP MP ATK DEF AGL INT
    db 250, 0, 50, 250  ; AI weights
    db $3E, $40, $41, $FF  ; Kamikaze, EvilSlash, ChargeUP, -
EnemyStats_270:  ; HammerMan Lv32 join 7
    db 57
    dw 0
    db 7, 32
    dw 130, 35, 120, 85, 118, 62  ; HP MP ATK DEF AGL INT
    db 250, 0, 50, 250  ; AI weights
    db $3E, $41, $FF, $FF  ; Kamikaze, ChargeUP, -, -
EnemyStats_271:  ; HammerMan Lv32 join 7
    db 57
    dw 0
    db 7, 32
    dw 120, 30, 115, 80, 118, 62  ; HP MP ATK DEF AGL INT
    db 250, 0, 50, 250  ; AI weights
    db $3E, $40, $41, $FF  ; Kamikaze, EvilSlash, ChargeUP, -
EnemyStats_272:  ; AgDevil Lv31 join 7
    db 132
    dw 0
    db 7, 31
    dw 200, 60, 98, 115, 90, 142  ; HP MP ATK DEF AGL INT
    db 200, 50, 150, 150  ; AI weights
    db $04, $6A, $FF, $FF  ; Firebane, SleepAir, -, -
EnemyStats_273:  ; WindMerge Lv31 join 7
    db 167
    dw 0
    db 7, 31
    dw 150, 80, 68, 126, 122, 165  ; HP MP ATK DEF AGL INT
    db 200, 100, 200, 100  ; AI weights
    db $0B, $24, $36, $FF  ; Infermost, Barrier, CurseOff, -
EnemyStats_274:  ; TreeBoy Lv33 join 7
    db 101
    dw 0
    db 7, 33
    dw 200, 85, 64, 80, 156, 185  ; HP MP ATK DEF AGL INT
    db 200, 200, 200, 50  ; AI weights
    db $0C, $2B, $36, $FF  ; IceBolt, Heal, CurseOff, -
EnemyStats_275:  ; ArmyCrab Lv36 join 7
    db 125
    dw 0
    db 7, 36
    dw 170, 78, 100, 150, 105, 72  ; HP MP ATK DEF AGL INT
    db 250, 50, 250, 0  ; AI weights
    db $1F, $48, $FF, $FF  ; Increase, MetalCut, -, -
EnemyStats_276:  ; MadDragon Lv33 join 7
    db 30
    dw 0
    db 7, 33
    dw 220, 20, 200, 70, 150, 20  ; HP MP ATK DEF AGL INT
    db 250, 0, 150, 150  ; AI weights
    db $3F, $40, $78, $FF  ; Massacre, EvilSlash, LureDance, -
EnemyStats_277:  ; ArmyCrab Lv36 join 7
    db 125
    dw 0
    db 7, 36
    dw 130, 78, 110, 140, 105, 72  ; HP MP ATK DEF AGL INT
    db 200, 50, 250, 0  ; AI weights
    db $1F, $48, $52, $FF  ; Increase, MetalCut, CallHelp, -
EnemyStats_278:  ; FireWeed Lv39 join 7
    db 91
    dw 0
    db 7, 39
    dw 160, 80, 73, 108, 110, 147  ; HP MP ATK DEF AGL INT
    db 250, 0, 150, 100  ; AI weights
    db $01, $35, $6B, $FF  ; Blazemore, DeChaos, PalsyAir, -
EnemyStats_279:  ; EvilBeast Lv37 join 7
    db 137
    dw 0
    db 7, 37
    dw 150, 60, 172, 132, 106, 186  ; HP MP ATK DEF AGL INT
    db 250, 50, 250, 150  ; AI weights
    db $04, $61, $FF, $FF  ; Firebane, IceAir, -, -
EnemyStats_280:  ; Wyvern Lv39 join 7
    db 71
    dw 0
    db 7, 39
    dw 160, 75, 135, 100, 160, 205  ; HP MP ATK DEF AGL INT
    db 150, 150, 150, 250  ; AI weights
    db $16, $2C, $61, $FF  ; SleepAll, HealMore, IceAir, -
EnemyStats_281:  ; Grizzly Lv38 join 7
    db 58
    dw 0
    db 7, 38
    dw 250, 20, 260, 72, 200, 80  ; HP MP ATK DEF AGL INT
    db 250, 0, 0, 200  ; AI weights
    db $55, $7C, $FF, $FF  ; SquallHit, BigTrip, -, -
EnemyStats_282:  ; Lionex Lv40 join 7
    db 141
    dw 0
    db 7, 40
    dw 260, 100, 122, 200, 210, 160  ; HP MP ATK DEF AGL INT
    db 150, 150, 150, 50  ; AI weights
    db $0B, $2E, $46, $FF  ; Infermost, HealUs, VacuSlash, -
EnemyStats_283:  ; Grizzly Lv38 join 7
    db 58
    dw 0
    db 7, 38
    dw 240, 20, 250, 72, 200, 80  ; HP MP ATK DEF AGL INT
    db 250, 0, 0, 200  ; AI weights
    db $3B, $55, $7C, $FF  ; TwinSlash, SquallHit, BigTrip, -
EnemyStats_284:  ; Toadstool Lv40 join 7
    db 96
    dw 0
    db 7, 40
    dw 250, 120, 150, 160, 150, 120  ; HP MP ATK DEF AGL INT
    db 0, 0, 0, 0  ; AI weights
    db $68, $6A, $92, $FF  ; NapAttack, SleepAir, MouthShut, -
EnemyStats_285:  ; Lipsy Lv38 join 7
    db 116
    dw 0
    db 7, 38
    dw 350, 110, 170, 100, 180, 150  ; HP MP ATK DEF AGL INT
    db 50, 0, 50, 0  ; AI weights
    db $68, $70, $79, $FF  ; NapAttack, Ahhh, LushLicks, -
EnemyStats_286:  ; Toadstool Lv40 join 7
    db 96
    dw 0
    db 7, 40
    dw 250, 100, 140, 150, 120, 120  ; HP MP ATK DEF AGL INT
    db 0, 0, 0, 0  ; AI weights
    db $68, $6A, $92, $FF  ; NapAttack, SleepAir, MouthShut, -
EnemyStats_287:  ; DanceVegi Lv44 join 7
    db 100
    dw 0
    db 7, 44
    dw 160, 80, 84, 200, 120, 150  ; HP MP ATK DEF AGL INT
    db 200, 0, 200, 100  ; AI weights
    db $71, $77, $78, $FF  ; K.O.Dance, SideStep, LureDance, -
EnemyStats_288:  ; Voodoll Lv33 join 7
    db 184
    dw 0
    db 7, 33
    dw 190, 120, 168, 216, 150, 170  ; HP MP ATK DEF AGL INT
    db 250, 0, 200, 250  ; AI weights
    db $18, $19, $1D, $FF  ; Surround, PanicAll, Defence, -
EnemyStats_289:  ; DanceVegi Lv44 join 7
    db 100
    dw 0
    db 7, 44
    dw 170, 85, 86, 190, 316, 150  ; HP MP ATK DEF AGL INT
    db 200, 0, 150, 100  ; AI weights
    db $71, $77, $78, $FF  ; K.O.Dance, SideStep, LureDance, -
EnemyStats_290:  ; Slime Lv38 join 7
    db 8
    dw 0
    db 7, 38
    dw 250, 120, 200, 130, 260, 140  ; HP MP ATK DEF AGL INT
    db 100, 0, 100, 200  ; AI weights
    db $05, $73, $FF, $FF  ; Firebolt, Radiant, -, -
EnemyStats_291:  ; Dracky Lv38 join 7
    db 78
    dw 0
    db 7, 38
    dw 180, 150, 170, 130, 160, 200  ; HP MP ATK DEF AGL INT
    db 200, 0, 200, 150  ; AI weights
    db $16, $1A, $73, $FF  ; SleepAll, RobMagic, Radiant, -
EnemyStats_292:  ; ArmyAnt Lv33 join 7
    db 118
    dw 0
    db 7, 33
    dw 210, 100, 250, 200, 150, 90  ; HP MP ATK DEF AGL INT
    db 250, 0, 0, 200  ; AI weights
    db $3E, $53, $68, $FF  ; Kamikaze, YellHelp, NapAttack, -
EnemyStats_293:  ; Metabble Lv38 join 7
    db 17
    dw 0
    db 7, 38
    dw 10, 490, 110, 670, 511, 255  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 0  ; AI weights
    db $05, $08, $FF, $FF  ; Firebolt, Explodet, -, -
EnemyStats_294:  ; Roboster Lv38 join 7
    db 189
    dw 0
    db 7, 38
    dw 310, 145, 230, 180, 360, 210  ; HP MP ATK DEF AGL INT
    db 250, 50, 50, 50  ; AI weights
    db $51, $55, $57, $FF  ; QuadHits, SquallHit, RainSlash, -
EnemyStats_295:  ; MetalDrak Lv43 join 7
    db 185
    dw 0
    db 7, 43
    dw 400, 105, 250, 200, 250, 130  ; HP MP ATK DEF AGL INT
    db 200, 50, 150, 100  ; AI weights
    db $3F, $72, $FF, $FF  ; Massacre, SandStorm, -, -
EnemyStats_296:  ; Centasaur Lv43 join 7
    db 151
    dw 0
    db 7, 43
    dw 320, 85, 205, 240, 320, 200  ; HP MP ATK DEF AGL INT
    db 250, 50, 200, 250  ; AI weights
    db $17, $44, $57, $FF  ; StopSpell, FireSlash, RainSlash, -
EnemyStats_297:  ; Orochi Lv50 join 7
    db 41
    dw 0
    db 7, 50
    dw 300, 200, 160, 320, 250, 180  ; HP MP ATK DEF AGL INT
    db 250, 0, 250, 200  ; AI weights
    db $44, $51, $5E, $FF  ; FireSlash, QuadHits, Scorching, -
EnemyStats_298:  ; Swordgon Lv48 join 7
    db 27
    dw 0
    db 7, 48
    dw 250, 100, 180, 210, 100, 130  ; HP MP ATK DEF AGL INT
    db 200, 200, 200, 250  ; AI weights
    db $4E, $57, $90, $FF  ; CleanCut, RainSlash, BladeD, -
EnemyStats_299:  ; Andreal Lv48 join 7
    db 34
    dw 0
    db 7, 48
    dw 340, 180, 185, 260, 200, 250  ; HP MP ATK DEF AGL INT
    db 200, 0, 200, 200  ; AI weights
    db $0B, $18, $6D, $FF  ; Infermost, Surround, PoisonAir, -
EnemyStats_300:  ; Unicorn Lv48 join 7
    db 62
    dw 0
    db 7, 48
    dw 220, 230, 170, 150, 290, 255  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $2D, $31, $33, $FF  ; HealAll, Revive, Antidote, -
EnemyStats_301:  ; MadDragon Lv33 join 7
    db 30
    dw 0
    db 7, 33
    dw 220, 20, 305, 120, 200, 30  ; HP MP ATK DEF AGL INT
    db 250, 0, 200, 150  ; AI weights
    db $3F, $40, $78, $FF  ; Massacre, EvilSlash, LureDance, -
EnemyStats_302:  ; MetalKing Lv50 join 7
    db 18
    dw 0
    db 7, 50
    dw 8, 700, 150, 700, 511, 255  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 200  ; AI weights
    db $10, $FF, $FF, $FF  ; Zap, -, -, -
EnemyStats_303:  ; Coatol Lv50 join 7
    db 40
    dw 0
    db 7, 50
    dw 300, 180, 220, 240, 320, 200  ; HP MP ATK DEF AGL INT
    db 250, 100, 150, 100  ; AI weights
    db $08, $40, $45, $FF  ; Explodet, EvilSlash, BoltSlash, -
EnemyStats_304:  ; RainHawk Lv50 join 7
    db 89
    dw 0
    db 7, 50
    dw 380, 50, 200, 220, 320, 255  ; HP MP ATK DEF AGL INT
    db 200, 150, 50, 250  ; AI weights
    db $66, $81, $FF, $FF  ; MegaMagic, Surge, -, -
EnemyStats_305:  ; LizardMan Lv20 join 0
    db 25
    dw 0
    db 0, 20
    dw 80, 40, 130, 70, 70, 70  ; HP MP ATK DEF AGL INT
    db 100, 100, 100, 100  ; AI weights
    db $2B, $30, $8E, $FF  ; Heal, Vivify, StrongD, -
EnemyStats_306:  ; CatFly Lv20 join 0
    db 47
    dw 0
    db 0, 20
    dw 50, 40, 80, 50, 100, 70  ; HP MP ATK DEF AGL INT
    db 200, 0, 50, 200  ; AI weights
    db $1A, $1E, $25, $FF  ; RobMagic, Upper, TwinHits, -
EnemyStats_307:  ; DeadNite Lv20 join 0
    db 161
    dw 0
    db 0, 20
    dw 80, 80, 70, 90, 60, 90  ; HP MP ATK DEF AGL INT
    db 250, 50, 150, 150  ; AI weights
    db $49, $4C, $D6, $FF  ; DrakSlash, DevilCut, Smashlime, -
EnemyStats_308:  ; IceMan Lv20 join 0
    db 193
    dw 0
    db 0, 20
    dw 80, 40, 80, 150, 50, 40  ; HP MP ATK DEF AGL INT
    db 0, 0, 0, 0  ; AI weights
    db $88, $8A, $FF, $FF  ; Cover, TailWind, -, -
EnemyStats_309:  ; Rayburn Lv30 join 0
    db 31
    dw 0
    db 0, 30
    dw 150, 80, 160, 100, 220, 90  ; HP MP ATK DEF AGL INT
    db 250, 150, 100, 200  ; AI weights
    db $00, $03, $06, $FF  ; Blaze, Firebal, Bang, -
EnemyStats_310:  ; Eyeder Lv30 join 0
    db 122
    dw 0
    db 0, 30
    dw 100, 60, 130, 120, 140, 100  ; HP MP ATK DEF AGL INT
    db 50, 150, 200, 100  ; AI weights
    db $76, $77, $78, $FF  ; RobDance, SideStep, LureDance, -
EnemyStats_311:  ; FangSlime Lv30 join 0
    db 10
    dw 0
    db 0, 30
    dw 90, 60, 170, 130, 170, 90  ; HP MP ATK DEF AGL INT
    db 200, 200, 200, 200  ; AI weights
    db $43, $50, $90, $FF  ; SuckAir, BiAttack, BladeD, -
EnemyStats_312:  ; Droll Lv30 join 0
    db 124
    dw 0
    db 0, 30
    dw 80, 120, 100, 100, 80, 120  ; HP MP ATK DEF AGL INT
    db 150, 0, 100, 100  ; AI weights
    db $4B, $D6, $D7, $FF  ; BirdBlow, Smashlime, Sheldodge, -
EnemyStats_313:  ; Yeti Lv38 join 0
    db 59
    dw 0
    db 0, 38
    dw 220, 140, 230, 210, 100, 140  ; HP MP ATK DEF AGL INT
    db 150, 250, 200, 0  ; AI weights
    db $17, $91, $92, $FF  ; StopSpell, DanceShut, MouthShut, -
EnemyStats_314:  ; StoneMan Lv40 join 0
    db 197
    dw 0
    db 0, 40
    dw 300, 120, 200, 240, 90, 170  ; HP MP ATK DEF AGL INT
    db 250, 50, 50, 200  ; AI weights
    db $2E, $32, $70, $FF  ; HealUs, Farewell, Ahhh, -
EnemyStats_315:  ; Metaly Lv20 join 0
    db 16
    dw 0
    db 0, 20
    dw 10, 200, 30, 300, 200, 50  ; HP MP ATK DEF AGL INT
    db 0, 100, 100, 0  ; AI weights
    db $88, $96, $FF, $FF  ; Cover, LifeDance, -, -
EnemyStats_316:  ; Skeletor Lv40 join 0
    db 172
    dw 0
    db 0, 40
    dw 160, 170, 310, 260, 140, 180  ; HP MP ATK DEF AGL INT
    db 250, 50, 250, 150  ; AI weights
    db $4E, $4F, $D9, $FF  ; CleanCut, MultiCut, GigaSlash, -
EnemyStats_317:  ; Mimic Lv1 join 4
    db 194
    dw 10
    db 4, 1
    dw 12, 2, 10, 6, 5, 8  ; HP MP ATK DEF AGL INT
    db 200, 100, 100, 50  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_318:  ; Mimic Lv5 join 4
    db 194
    dw 30
    db 4, 5
    dw 20, 9, 20, 12, 10, 30  ; HP MP ATK DEF AGL INT
    db 200, 100, 100, 50  ; AI weights
    db $00, $FF, $FF, $FF  ; Blaze, -, -, -
EnemyStats_319:  ; Mimic Lv10 join 4
    db 194
    dw 90
    db 4, 10
    dw 45, 20, 40, 20, 20, 80  ; HP MP ATK DEF AGL INT
    db 200, 100, 100, 50  ; AI weights
    db $00, $12, $FF, $FF  ; Blaze, Beat, -, -
EnemyStats_320:  ; Mimic Lv20 join 4
    db 194
    dw 300
    db 4, 20
    dw 80, 40, 60, 40, 40, 130  ; HP MP ATK DEF AGL INT
    db 200, 100, 100, 50  ; AI weights
    db $01, $12, $FF, $FF  ; Blazemore, Beat, -, -
EnemyStats_321:  ; Mimic Lv30 join 4
    db 194
    dw 600
    db 4, 30
    dw 125, 60, 80, 60, 60, 170  ; HP MP ATK DEF AGL INT
    db 200, 100, 100, 50  ; AI weights
    db $01, $12, $FF, $FF  ; Blazemore, Beat, -, -
EnemyStats_322:  ; Mimic Lv38 join 4
    db 194
    dw 1200
    db 4, 38
    dw 165, 80, 100, 80, 80, 210  ; HP MP ATK DEF AGL INT
    db 200, 100, 100, 50  ; AI weights
    db $02, $13, $FF, $FF  ; Blazemost, Defeat, -, -
EnemyStats_323:  ; Mimic Lv38 join 4
    db 194
    dw 3076
    db 4, 38
    dw 295, 160, 120, 110, 90, 225  ; HP MP ATK DEF AGL INT
    db 200, 100, 100, 50  ; AI weights
    db $02, $13, $FF, $FF  ; Blazemost, Defeat, -, -
EnemyStats_324:  ; Mimic Lv38 join 4
    db 194
    dw 6076
    db 4, 38
    dw 330, 220, 200, 150, 110, 225  ; HP MP ATK DEF AGL INT
    db 200, 100, 100, 50  ; AI weights
    db $02, $13, $FF, $FF  ; Blazemost, Defeat, -, -
EnemyStats_325:  ; Slime Lv1 join 0
    db 8
    dw 0
    db 0, 1
    dw 4, 2, 3, 4, 8, 5  ; HP MP ATK DEF AGL INT
    db 0, 250, 100, 150  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_326:  ; DragonKid Lv1 join 0
    db 20
    dw 0
    db 0, 1
    dw 8, 4, 10, 7, 6, 8  ; HP MP ATK DEF AGL INT
    db 250, 50, 0, 250  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_327:  ; Anteater Lv1 join 0
    db 53
    dw 0
    db 0, 1
    dw 6, 3, 6, 4, 7, 5  ; HP MP ATK DEF AGL INT
    db 100, 150, 250, 50  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_328:  ; 1EyeClown Lv1 join 0
    db 138
    dw 0
    db 0, 1
    dw 7, 8, 5, 3, 6, 10  ; HP MP ATK DEF AGL INT
    db 50, 100, 250, 150  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_329:  ; Blizzardy Lv1 join 0
    db 84
    dw 0
    db 0, 1
    dw 15, 10, 12, 8, 18, 10  ; HP MP ATK DEF AGL INT
    db 150, 200, 100, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_330:  ; Phoenix Lv1 join 0
    db 85
    dw 0
    db 0, 1
    dw 15, 10, 12, 8, 18, 10  ; HP MP ATK DEF AGL INT
    db 150, 200, 100, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_331:  ; LavaMan Lv1 join 0
    db 192
    dw 0
    db 0, 1
    dw 18, 8, 12, 18, 4, 6  ; HP MP ATK DEF AGL INT
    db 250, 100, 50, 150  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_332:  ; IceMan Lv1 join 0
    db 193
    dw 0
    db 0, 1
    dw 18, 8, 12, 18, 4, 6  ; HP MP ATK DEF AGL INT
    db 250, 100, 50, 150  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_333:  ; NiteWhip Lv1 join 0
    db 165
    dw 0
    db 0, 1
    dw 20, 20, 20, 15, 25, 15  ; HP MP ATK DEF AGL INT
    db 200, 100, 200, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_334:  ; ArmorPede Lv1 join 0
    db 121
    dw 0
    db 0, 1
    dw 30, 20, 20, 30, 15, 15  ; HP MP ATK DEF AGL INT
    db 200, 150, 100, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_335:  ; ManEater Lv1 join 0
    db 106
    dw 0
    db 0, 1
    dw 30, 30, 25, 20, 20, 20  ; HP MP ATK DEF AGL INT
    db 200, 50, 150, 100  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_336:  ; ZapBird Lv1 join 0
    db 86
    dw 0
    db 0, 1
    dw 30, 25, 30, 25, 30, 20  ; HP MP ATK DEF AGL INT
    db 150, 200, 200, 150  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_337:  ; Trumpeter Lv1 join 0
    db 65
    dw 0
    db 0, 1
    dw 35, 25, 35, 30, 25, 25  ; HP MP ATK DEF AGL INT
    db 250, 150, 100, 100  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_338:  ; ChopClown Lv1 join 0
    db 146
    dw 0
    db 0, 1
    dw 35, 20, 35, 20, 35, 20  ; HP MP ATK DEF AGL INT
    db 200, 100, 200, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_339:  ; Spikerous Lv1 join 0
    db 36
    dw 0
    db 0, 1
    dw 40, 30, 40, 60, 20, 30  ; HP MP ATK DEF AGL INT
    db 250, 200, 150, 150  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_340:  ; Metabble Lv1 join 0
    db 17
    dw 0
    db 0, 1
    dw 10, 50, 20, 200, 200, 30  ; HP MP ATK DEF AGL INT
    db 0, 150, 100, 0  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_341:  ; Stubsuck Lv20 join 4
    db 98
    dw 300
    db 4, 20
    dw 80, 120, 40, 30, 30, 100  ; HP MP ATK DEF AGL INT
    db 100, 50, 200, 100  ; AI weights
    db $16, $4D, $FF, $FF  ; SleepAll, ZombieCut, -, -
EnemyStats_342:  ; Servant Lv55 join 6
    db 173
    dw 0
    db 6, 55
    dw 300, 350, 380, 220, 306, 255  ; HP MP ATK DEF AGL INT
    db 250, 50, 100, 250  ; AI weights
    db $02, $0E, $FF, $FF  ; Blazemost, Blizzard, -, -
EnemyStats_343:  ; TERRY? Lv60 join 7
    db 215
    dw 0
    db 7, 60
    dw 2000, 200, 390, 220, 400, 255  ; HP MP ATK DEF AGL INT
    db 250, 50, 100, 200  ; AI weights
    db $40, $45, $57, $FF  ; EvilSlash, BoltSlash, RainSlash, -
EnemyStats_344:  ; Tatsu Lv30 join 7
    db 216
    dw 0
    db 7, 30
    dw 200, 100, 180, 150, 80, 150  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $2C, $5A, $88, $FF  ; HealMore, Lightning, Cover, -
EnemyStats_345:  ; Diago Lv40 join 7
    db 217
    dw 0
    db 7, 40
    dw 300, 200, 210, 160, 120, 100  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $25, $5E, $7A, $FF  ; TwinHits, Scorching, SickLick, -
EnemyStats_346:  ; Samsi Lv50 join 7
    db 218
    dw 0
    db 7, 50
    dw 450, 200, 250, 190, 150, 200  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $40, $55, $57, $FF  ; EvilSlash, SquallHit, RainSlash, -
EnemyStats_347:  ; Bazoo Lv60 join 7
    db 219
    dw 0
    db 7, 60
    dw 700, 400, 350, 300, 100, 250  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $62, $64, $80, $FF  ; IceStorm, Hellblast, DeMagic, -
EnemyStats_348:  ;  Lv50 join 7
    db 220
    dw 0
    db 7, 50
    dw 999, 300, 300, 200, 200, 200  ; HP MP ATK DEF AGL INT
    db 250, 0, 0, 250  ; AI weights
    db $5F, $63, $80, $FF  ; WhiteFire, WhiteAir, DeMagic, -
EnemyStats_349:  ; DragonKid Lv23 join 4
    db 20
    dw 1000
    db 4, 23
    dw 70, 60, 100, 60, 90, 90  ; HP MP ATK DEF AGL INT
    db 150, 50, 150, 250  ; AI weights
    db $5D, $6A, $8C, $FF  ; BlazeAir, SleepAir, Dodge, -
EnemyStats_350:  ; SkyDragon Lv1 join 0
    db 43
    dw 0
    db 0, 1
    dw 20, 27, 28, 20, 15, 16  ; HP MP ATK DEF AGL INT
    db 150, 50, 200, 250  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_351:  ; Slime Lv1 join 0
    db 8
    dw 0
    db 0, 1
    dw 60, 50, 64, 54, 120, 65  ; HP MP ATK DEF AGL INT
    db 0, 0, 100, 200  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_352:  ; HammerMan Lv5 join 5
    db 57
    dw 70
    db 5, 5
    dw 25, 12, 28, 14, 22, 45  ; HP MP ATK DEF AGL INT
    db 200, 50, 100, 200  ; AI weights
    db $45, $46, $47, $FF  ; BoltSlash, VacuSlash, IceSlash, -
EnemyStats_353:  ; Goategon Lv6 join 5
    db 63
    dw 80
    db 5, 6
    dw 26, 10, 32, 22, 26, 25  ; HP MP ATK DEF AGL INT
    db 250, 0, 150, 200  ; AI weights
    db $3B, $3C, $3D, $FF  ; TwinSlash, Ramming, Beserker, -
EnemyStats_354:  ; StagBug Lv5 join 5
    db 117
    dw 83
    db 5, 5
    dw 27, 12, 26, 28, 15, 28  ; HP MP ATK DEF AGL INT
    db 250, 100, 50, 150  ; AI weights
    db $46, $47, $48, $FF  ; VacuSlash, IceSlash, MetalCut, -
EnemyStats_355:  ; SpotKing Lv6 join 5
    db 14
    dw 86
    db 5, 6
    dw 32, 20, 25, 20, 32, 43  ; HP MP ATK DEF AGL INT
    db 200, 100, 100, 250  ; AI weights
    db $50, $52, $57, $FF  ; BiAttack, CallHelp, RainSlash, -
EnemyStats_356:  ; LizardFly Lv6 join 5
    db 33
    dw 90
    db 5, 6
    dw 36, 16, 28, 16, 10, 30  ; HP MP ATK DEF AGL INT
    db 200, 0, 200, 50  ; AI weights
    db $5C, $60, $FF, $FF  ; FireAir, FrigidAir, -, -
EnemyStats_357:  ; DuckKite Lv5 join 5
    db 74
    dw 88
    db 5, 5
    dw 22, 24, 25, 21, 31, 34  ; HP MP ATK DEF AGL INT
    db 200, 50, 0, 100  ; AI weights
    db $4A, $4B, $D6, $FF  ; BeastCut, BirdBlow, Smashlime, -
EnemyStats_358:  ; DarkEye Lv6 join 5
    db 134
    dw 81
    db 5, 6
    dw 22, 42, 21, 14, 36, 41  ; HP MP ATK DEF AGL INT
    db 100, 50, 150, 150  ; AI weights
    db $25, $27, $77, $FF  ; TwinHits, MagicBack, SideStep, -
EnemyStats_359:  ; CactiBall Lv6 join 5
    db 94
    dw 100
    db 5, 6
    dw 32, 37, 25, 24, 17, 38  ; HP MP ATK DEF AGL INT
    db 100, 100, 200, 100  ; AI weights
    db $78, $79, $90, $FF  ; LureDance, LushLicks, BladeD, -
EnemyStats_360:  ; Snapper Lv5 join 5
    db 107
    dw 50
    db 5, 5
    dw 30, 23, 20, 10, 12, 34  ; HP MP ATK DEF AGL INT
    db 150, 50, 250, 200  ; AI weights
    db $12, $20, $72, $FF  ; Beat, Slow, SandStorm, -
EnemyStats_361:  ; Reaper Lv6 join 5
    db 168
    dw 76
    db 5, 6
    dw 31, 17, 29, 13, 22, 39  ; HP MP ATK DEF AGL INT
    db 100, 0, 150, 100  ; AI weights
    db $17, $91, $92, $FF  ; StopSpell, DanceShut, MouthShut, -
EnemyStats_362:  ; MistyWing Lv6 join 5
    db 77
    dw 68
    db 5, 6
    dw 35, 34, 16, 24, 32, 30  ; HP MP ATK DEF AGL INT
    db 50, 0, 250, 150  ; AI weights
    db $15, $7D, $8A, $FF  ; Sleep, WarCry, TailWind, -
EnemyStats_363:  ; Gasgon Lv5 join 5
    db 23
    dw 75
    db 5, 5
    dw 26, 6, 34, 25, 14, 32  ; HP MP ATK DEF AGL INT
    db 150, 150, 150, 100  ; AI weights
    db $2B, $8C, $FF, $FF  ; Heal, Dodge, -, -
EnemyStats_364:  ; SlimeNite Lv5 join 5
    db 5
    dw 63
    db 5, 5
    dw 29, 24, 30, 18, 34, 33  ; HP MP ATK DEF AGL INT
    db 150, 100, 50, 250  ; AI weights
    db $1E, $22, $2B, $FF  ; Upper, Speed, Heal, -
EnemyStats_365:  ; TailEater Lv6 join 5
    db 120
    dw 76
    db 5, 6
    dw 23, 20, 21, 20, 24, 28  ; HP MP ATK DEF AGL INT
    db 200, 150, 150, 50  ; AI weights
    db $27, $2B, $FF, $FF  ; MagicBack, Heal, -, -
EnemyStats_366:  ; TreeBoy Lv5 join 5
    db 101
    dw 76
    db 5, 5
    dw 37, 45, 16, 21, 19, 37  ; HP MP ATK DEF AGL INT
    db 100, 150, 200, 200  ; AI weights
    db $0C, $2B, $30, $FF  ; IceBolt, Heal, Vivify, -
EnemyStats_367:  ; AgDevil Lv5 join 5
    db 132
    dw 86
    db 5, 5
    dw 30, 36, 32, 23, 23, 45  ; HP MP ATK DEF AGL INT
    db 200, 150, 200, 200  ; AI weights
    db $3D, $88, $8E, $FF  ; Beserker, Cover, StrongD, -
EnemyStats_368:  ; Wyvern Lv12 join 5
    db 71
    dw 183
    db 5, 12
    dw 46, 32, 52, 28, 48, 84  ; HP MP ATK DEF AGL INT
    db 200, 50, 100, 0  ; AI weights
    db $50, $55, $58, $FF  ; BiAttack, SquallHit, WindBeast, -
EnemyStats_369:  ; AmberWeed Lv13 join 5
    db 97
    dw 186
    db 5, 13
    dw 36, 64, 50, 36, 39, 42  ; HP MP ATK DEF AGL INT
    db 250, 0, 0, 150  ; AI weights
    db $03, $4C, $5D, $FF  ; Firebal, DevilCut, BlazeAir, -
EnemyStats_370:  ; ArcDemon Lv12 join 5
    db 131
    dw 200
    db 5, 12
    dw 48, 46, 53, 42, 18, 88  ; HP MP ATK DEF AGL INT
    db 200, 100, 200, 150  ; AI weights
    db $44, $46, $47, $FF  ; FireSlash, VacuSlash, IceSlash, -
EnemyStats_371:  ; IceMan Lv12 join 3
    db 193
    dw 216
    db 3, 12
    dw 38, 41, 47, 40, 21, 51  ; HP MP ATK DEF AGL INT
    db 200, 0, 0, 200  ; AI weights
    db $3F, $55, $D8, $FF  ; Massacre, SquallHit, Branching, -
EnemyStats_372:  ; SlimeBorg Lv12 join 5
    db 12
    dw 203
    db 5, 12
    dw 52, 24, 43, 31, 49, 61  ; HP MP ATK DEF AGL INT
    db 250, 100, 100, 150  ; AI weights
    db $4E, $56, $7D, $FF  ; CleanCut, PsycheUp, WarCry, -
EnemyStats_373:  ; ArmyCrab Lv12 join 5
    db 125
    dw 190
    db 5, 12
    dw 46, 31, 50, 36, 28, 50  ; HP MP ATK DEF AGL INT
    db 100, 0, 150, 50  ; AI weights
    db $6F, $75, $D7, $FF  ; Curse, OddDance, Sheldodge, -
EnemyStats_374:  ; Shadow Lv13 join 5
    db 162
    dw 166
    db 5, 13
    dw 59, 40, 54, 50, 26, 46  ; HP MP ATK DEF AGL INT
    db 150, 50, 200, 150  ; AI weights
    db $15, $1A, $23, $FF  ; Sleep, RobMagic, SpeedUp, -
EnemyStats_375:  ; LizardMan Lv13 join 5
    db 25
    dw 176
    db 5, 13
    dw 55, 34, 52, 34, 32, 48  ; HP MP ATK DEF AGL INT
    db 200, 100, 200, 0  ; AI weights
    db $19, $78, $7B, $FF  ; PanicAll, LureDance, LegSweep, -
EnemyStats_376:  ; MadHornet Lv13 join 6
    db 126
    dw 210
    db 6, 13
    dw 60, 37, 54, 31, 54, 55  ; HP MP ATK DEF AGL INT
    db 150, 50, 200, 250  ; AI weights
    db $6F, $72, $8A, $FF  ; Curse, SandStorm, TailWind, -
EnemyStats_377:  ; FireWeed Lv12 join 5
    db 91
    dw 153
    db 5, 12
    dw 49, 42, 40, 29, 30, 46  ; HP MP ATK DEF AGL INT
    db 100, 0, 250, 150  ; AI weights
    db $6E, $79, $7D, $FF  ; PaniDance, LushLicks, WarCry, -
EnemyStats_378:  ; WindMerge Lv12 join 5
    db 167
    dw 196
    db 5, 12
    dw 44, 45, 38, 40, 40, 51  ; HP MP ATK DEF AGL INT
    db 150, 100, 50, 200  ; AI weights
    db $2B, $88, $8A, $FF  ; Heal, Cover, TailWind, -
EnemyStats_379:  ; Orc Lv13 join 5
    db 143
    dw 180
    db 5, 13
    dw 51, 29, 36, 25, 44, 57  ; HP MP ATK DEF AGL INT
    db 200, 200, 200, 50  ; AI weights
    db $2B, $30, $78, $FF  ; Heal, Vivify, LureDance, -
EnemyStats_380:  ; Droll Lv12 join 5
    db 124
    dw 150
    db 5, 12
    dw 39, 50, 40, 28, 31, 55  ; HP MP ATK DEF AGL INT
    db 0, 200, 200, 250  ; AI weights
    db $2B, $83, $88, $FF  ; Heal, ThickFog, Cover, -
EnemyStats_381:  ; Phoenix Lv12 join 5
    db 85
    dw 193
    db 5, 12
    dw 50, 47, 53, 27, 41, 47  ; HP MP ATK DEF AGL INT
    db 200, 200, 200, 250  ; AI weights
    db $2B, $5D, $8A, $FF  ; Heal, BlazeAir, TailWind, -
EnemyStats_382:  ; GiantMoth Lv12 join 5
    db 123
    dw 170
    db 5, 12
    dw 41, 46, 40, 36, 29, 57  ; HP MP ATK DEF AGL INT
    db 200, 150, 200, 100  ; AI weights
    db $2B, $67, $75, $FF  ; Heal, PoisonHit, OddDance, -
EnemyStats_383:  ; Grizzly Lv13 join 6
    db 58
    dw 183
    db 6, 13
    dw 57, 43, 62, 23, 48, 24  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $2B, $3F, $73, $FF  ; Heal, Massacre, Radiant, -
EnemyStats_384:  ; WildApe Lv20 join 5
    db 64
    dw 500
    db 5, 20
    dw 65, 46, 78, 38, 51, 47  ; HP MP ATK DEF AGL INT
    db 250, 0, 0, 100  ; AI weights
    db $41, $48, $4E, $FF  ; ChargeUP, MetalCut, CleanCut, -
EnemyStats_385:  ; Blizzardy Lv20 join 5
    db 84
    dw 513
    db 5, 20
    dw 72, 53, 71, 46, 46, 57  ; HP MP ATK DEF AGL INT
    db 200, 100, 100, 150  ; AI weights
    db $0A, $3B, $42, $FF  ; Infermore, TwinSlash, HighJump, -
EnemyStats_386:  ; EvilWand Lv21 join 5
    db 176
    dw 526
    db 5, 21
    dw 66, 55, 59, 45, 53, 45  ; HP MP ATK DEF AGL INT
    db 250, 0, 200, 100  ; AI weights
    db $01, $07, $41, $FF  ; Blazemore, Boom, ChargeUP, -
EnemyStats_387:  ; LavaMan Lv21 join 5
    db 192
    dw 546
    db 5, 21
    dw 80, 43, 88, 49, 40, 51  ; HP MP ATK DEF AGL INT
    db 200, 50, 50, 150  ; AI weights
    db $01, $44, $48, $FF  ; Blazemore, FireSlash, MetalCut, -
EnemyStats_388:  ; CurseLamp Lv20 join 5
    db 188
    dw 553
    db 5, 20
    dw 60, 70, 62, 50, 42, 59  ; HP MP ATK DEF AGL INT
    db 250, 100, 100, 0  ; AI weights
    db $0D, $14, $49, $FF  ; SnowStorm, Sacrifice, DrakSlash, -
EnemyStats_389:  ; MadSpirit Lv20 join 5
    db 166
    dw 546
    db 5, 20
    dw 63, 68, 85, 55, 64, 60  ; HP MP ATK DEF AGL INT
    db 150, 0, 200, 100  ; AI weights
    db $19, $1D, $28, $FF  ; PanicAll, Defence, Bounce, -
EnemyStats_390:  ; Gismo Lv21 join 5
    db 191
    dw 563
    db 5, 21
    dw 57, 47, 69, 52, 72, 46  ; HP MP ATK DEF AGL INT
    db 150, 50, 150, 100  ; AI weights
    db $16, $21, $6D, $FF  ; SleepAll, SlowAll, PoisonAir, -
EnemyStats_391:  ; DeadNite Lv20 join 5
    db 161
    dw 516
    db 5, 20
    dw 80, 65, 72, 67, 52, 77  ; HP MP ATK DEF AGL INT
    db 100, 0, 100, 100  ; AI weights
    db $23, $7D, $91, $FF  ; SpeedUp, WarCry, DanceShut, -
EnemyStats_392:  ; RogueNite Lv21 join 5
    db 182
    dw 533
    db 5, 21
    dw 75, 61, 103, 120, 40, 61  ; HP MP ATK DEF AGL INT
    db 200, 100, 200, 200  ; AI weights
    db $1B, $6F, $7A, $FF  ; TakeMagic, Curse, SickLick, -
EnemyStats_393:  ; KingCobra Lv21 join 5
    db 35
    dw 563
    db 5, 21
    dw 100, 39, 80, 72, 110, 41  ; HP MP ATK DEF AGL INT
    db 150, 50, 150, 0  ; AI weights
    db $12, $25, $74, $FF  ; Beat, TwinHits, EerieLite, -
EnemyStats_394:  ; Phoenix Lv20 join 5
    db 85
    dw 533
    db 5, 20
    dw 81, 46, 77, 51, 66, 40  ; HP MP ATK DEF AGL INT
    db 200, 150, 0, 150  ; AI weights
    db $2B, $26, $46, $FF  ; Heal, MagicWall, VacuSlash, -
EnemyStats_395:  ; Dragon Lv21 join 5
    db 28
    dw 563
    db 5, 21
    dw 105, 36, 83, 63, 48, 64  ; HP MP ATK DEF AGL INT
    db 200, 200, 200, 200  ; AI weights
    db $2B, $52, $88, $FF  ; Heal, CallHelp, Cover, -
EnemyStats_396:  ; Metaly Lv20 join 6
    db 16
    dw 4000
    db 6, 20
    dw 10, 200, 45, 300, 250, 66  ; HP MP ATK DEF AGL INT
    db 250, 200, 200, 250  ; AI weights
    db $2B, $3F, $89, $FF  ; Heal, Massacre, Guardian, -
EnemyStats_397:  ; LandOwl Lv21 join 5
    db 81
    dw 516
    db 5, 21
    dw 95, 57, 110, 57, 53, 48  ; HP MP ATK DEF AGL INT
    db 200, 200, 200, 250  ; AI weights
    db $0A, $2B, $81, $FF  ; Infermore, Heal, Surge, -
EnemyStats_398:  ; EvilBeast Lv20 join 5
    db 137
    dw 546
    db 5, 20
    dw 84, 53, 110, 71, 64, 100  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 0  ; AI weights
    db $0F, $2B, $7C, $FF  ; Bolt, Heal, BigTrip, -
EnemyStats_399:  ; Lipsy Lv20 join 5
    db 116
    dw 333
    db 5, 20
    dw 52, 43, 46, 46, 36, 57  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $2E, $32, $3E, $FF  ; HealUs, Farewell, Kamikaze, -
EnemyStats_400:  ; Lionex Lv26 join 5
    db 141
    dw 1000
    db 5, 26
    dw 110, 70, 100, 106, 122, 117  ; HP MP ATK DEF AGL INT
    db 250, 150, 200, 200  ; AI weights
    db $04, $43, $5E, $FF  ; Firebane, SuckAir, Scorching, -
EnemyStats_401:  ; Rayburn Lv26 join 5
    db 31
    dw 1006
    db 5, 26
    dw 93, 55, 104, 62, 136, 65  ; HP MP ATK DEF AGL INT
    db 200, 0, 0, 250  ; AI weights
    db $5A, $62, $69, $FF  ; Lightning, IceStorm, Paralyze, -
EnemyStats_402:  ; ManEater Lv27 join 5
    db 106
    dw 1033
    db 5, 27
    dw 88, 114, 93, 45, 42, 57  ; HP MP ATK DEF AGL INT
    db 200, 100, 150, 200  ; AI weights
    db $10, $5B, $79, $FF  ; Zap, RockThrow, LushLicks, -
EnemyStats_403:  ; RotRaven Lv26 join 5
    db 158
    dw 1020
    db 5, 26
    dw 67, 84, 114, 70, 120, 102  ; HP MP ATK DEF AGL INT
    db 150, 50, 100, 0  ; AI weights
    db $12, $46, $50, $FF  ; Beat, VacuSlash, BiAttack, -
EnemyStats_404:  ; Ogre Lv27 join 5
    db 144
    dw 1043
    db 5, 27
    dw 134, 72, 120, 107, 52, 115  ; HP MP ATK DEF AGL INT
    db 50, 0, 0, 0  ; AI weights
    db $3B, $4A, $59, $FF  ; TwinSlash, BeastCut, Vacuum, -
EnemyStats_405:  ; IronTurt Lv26 join 5
    db 55
    dw 1020
    db 5, 26
    dw 140, 60, 130, 100, 61, 91  ; HP MP ATK DEF AGL INT
    db 100, 100, 100, 100  ; AI weights
    db $14, $24, $84, $FF  ; Sacrifice, Barrier, TatsuCall, -
EnemyStats_406:  ; Copycat Lv26 join 5
    db 174
    dw 1066
    db 5, 26
    dw 55, 45, 82, 61, 64, 57  ; HP MP ATK DEF AGL INT
    db 150, 150, 150, 50  ; AI weights
    db $26, $7F, $83, $FF  ; MagicWall, Imitate, ThickFog, -
EnemyStats_407:  ; DarkCrab Lv25 join 5
    db 160
    dw 1006
    db 5, 25
    dw 130, 64, 136, 111, 54, 70  ; HP MP ATK DEF AGL INT
    db 50, 0, 150, 250  ; AI weights
    db $17, $76, $7A, $FF  ; StopSpell, RobDance, SickLick, -
EnemyStats_408:  ; WingSnake Lv26 join 5
    db 39
    dw 1060
    db 5, 26
    dw 132, 77, 120, 89, 85, 78  ; HP MP ATK DEF AGL INT
    db 100, 50, 100, 100  ; AI weights
    db $1D, $6E, $D8, $FF  ; Defence, PaniDance, Branching, -
EnemyStats_409:  ; DanceVegi Lv25 join 5
    db 100
    dw 1066
    db 5, 25
    dw 83, 61, 59, 120, 156, 85  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $25, $78, $92, $FF  ; TwinHits, LureDance, MouthShut, -
EnemyStats_410:  ; Grendal Lv26 join 5
    db 147
    dw 996
    db 5, 26
    dw 99, 41, 135, 155, 112, 113  ; HP MP ATK DEF AGL INT
    db 150, 150, 150, 100  ; AI weights
    db $2C, $56, $95, $FF  ; HealMore, PsycheUp, LifeSong, -
EnemyStats_411:  ; JewelBag Lv25 join 5
    db 175
    dw 1050
    db 5, 25
    dw 68, 76, 123, 126, 40, 130  ; HP MP ATK DEF AGL INT
    db 200, 200, 200, 50  ; AI weights
    db $2E, $77, $85, $FF  ; HealUs, SideStep, DiagoCall, -
EnemyStats_412:  ; Phoenix Lv26 join 5
    db 85
    dw 1040
    db 5, 26
    dw 110, 65, 125, 70, 100, 75  ; HP MP ATK DEF AGL INT
    db 100, 100, 100, 250  ; AI weights
    db $52, $6D, $94, $FF  ; CallHelp, PoisonAir, Hustle, -
EnemyStats_413:  ; Goategon Lv25 join 5
    db 63
    dw 1023
    db 5, 25
    dw 133, 107, 155, 82, 98, 128  ; HP MP ATK DEF AGL INT
    db 200, 150, 200, 150  ; AI weights
    db $2D, $30, $55, $FF  ; HealAll, Vivify, SquallHit, -
EnemyStats_414:  ; FaceTree Lv26 join 5
    db 102
    dw 1040
    db 5, 26
    dw 125, 119, 67, 74, 51, 86  ; HP MP ATK DEF AGL INT
    db 50, 0, 50, 0  ; AI weights
    db $26, $89, $D7, $FF  ; MagicWall, Guardian, Sheldodge, -
EnemyStats_415:  ; Swordgon Lv25 join 5
    db 27
    dw 1093
    db 5, 25
    dw 126, 95, 95, 128, 46, 67  ; HP MP ATK DEF AGL INT
    db 250, 200, 200, 250  ; AI weights
    db $10, $1F, $2C, $FF  ; Zap, Increase, HealMore, -
EnemyStats_416:  ; SuperTen Lv33 join 5
    db 54
    dw 1666
    db 5, 33
    dw 156, 60, 77, 60, 136, 78  ; HP MP ATK DEF AGL INT
    db 100, 0, 100, 200  ; AI weights
    db $05, $44, $51, $FF  ; Firebolt, FireSlash, QuadHits, -
EnemyStats_417:  ; MadMirror Lv33 join 5
    db 181
    dw 1666
    db 5, 33
    dw 164, 62, 71, 64, 170, 120  ; HP MP ATK DEF AGL INT
    db 150, 50, 50, 250  ; AI weights
    db $07, $4B, $57, $FF  ; Boom, BirdBlow, RainSlash, -
EnemyStats_418:  ; Yeti Lv34 join 5
    db 59
    dw 1706
    db 5, 34
    dw 198, 110, 170, 170, 80, 94  ; HP MP ATK DEF AGL INT
    db 250, 150, 100, 100  ; AI weights
    db $0B, $42, $59, $FF  ; Infermost, HighJump, Vacuum, -
EnemyStats_419:  ; Skullgon Lv33 join 5
    db 156
    dw 1720
    db 5, 33
    dw 164, 63, 132, 174, 85, 169  ; HP MP ATK DEF AGL INT
    db 200, 100, 50, 250  ; AI weights
    db $02, $3B, $55, $FF  ; Blazemost, TwinSlash, SquallHit, -
EnemyStats_420:  ; Centasaur Lv33 join 5
    db 151
    dw 1756
    db 5, 33
    dw 200, 126, 225, 270, 320, 220  ; HP MP ATK DEF AGL INT
    db 250, 50, 50, 150  ; AI weights
    db $14, $59, $67, $FF  ; Sacrifice, Vacuum, PoisonHit, -
EnemyStats_421:  ; EvilArmor Lv34 join 5
    db 152
    dw 1716
    db 5, 34
    dw 185, 102, 229, 420, 135, 148  ; HP MP ATK DEF AGL INT
    db 200, 50, 250, 100  ; AI weights
    db $16, $24, $57, $FF  ; SleepAll, Barrier, RainSlash, -
EnemyStats_422:  ; Voodoll Lv33 join 5
    db 184
    dw 1760
    db 5, 33
    dw 154, 148, 168, 164, 120, 133  ; HP MP ATK DEF AGL INT
    db 100, 50, 150, 200  ; AI weights
    db $28, $6D, $7D, $FF  ; Bounce, PoisonAir, WarCry, -
EnemyStats_423:  ; Golem Lv33 join 5
    db 196
    dw 1723
    db 5, 33
    dw 210, 59, 108, 182, 52, 192  ; HP MP ATK DEF AGL INT
    db 100, 100, 100, 250  ; AI weights
    db $6E, $76, $94, $FF  ; PaniDance, RobDance, Hustle, -
EnemyStats_424:  ; LavaMan Lv33 join 5
    db 192
    dw 1713
    db 5, 33
    dw 180, 63, 158, 179, 87, 101  ; HP MP ATK DEF AGL INT
    db 200, 50, 200, 150  ; AI weights
    db $6F, $74, $86, $FF  ; Curse, EerieLite, SamsiCall, -
EnemyStats_425:  ; Blizzardy Lv33 join 5
    db 84
    dw 1746
    db 5, 33
    dw 182, 103, 121, 116, 152, 107  ; HP MP ATK DEF AGL INT
    db 200, 100, 200, 150  ; AI weights
    db $72, $7A, $8B, $FF  ; SandStorm, SickLick, StormWind, -
EnemyStats_426:  ; MadCat Lv34 join 5
    db 68
    dw 1726
    db 5, 34
    dw 166, 64, 159, 124, 163, 107  ; HP MP ATK DEF AGL INT
    db 150, 150, 150, 250  ; AI weights
    db $2C, $47, $78, $FF  ; HealMore, IceSlash, LureDance, -
EnemyStats_427:  ; StoneMan Lv34 join 5
    db 197
    dw 1740
    db 5, 34
    dw 220, 96, 147, 220, 71, 125  ; HP MP ATK DEF AGL INT
    db 200, 150, 200, 200  ; AI weights
    db $05, $2E, $8F, $FF  ; Firebolt, HealUs, SuckAll, -
EnemyStats_428:  ; BigEye Lv33 join 5
    db 69
    dw 1703
    db 5, 33
    dw 155, 134, 162, 122, 137, 100  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $2E, $32, $42, $FF  ; HealUs, Farewell, HighJump, -
EnemyStats_429:  ; Metaly Lv30 join 6
    db 16
    dw 6076
    db 6, 30
    dw 15, 300, 65, 400, 350, 86  ; HP MP ATK DEF AGL INT
    db 250, 200, 250, 100  ; AI weights
    db $2B, $3E, $8F, $FF  ; Heal, Kamikaze, SuckAll, -
EnemyStats_430:  ; Gasgon Lv34 join 5
    db 23
    dw 1746
    db 5, 34
    dw 164, 58, 67, 117, 80, 97  ; HP MP ATK DEF AGL INT
    db 150, 50, 100, 0  ; AI weights
    db $2C, $53, $8F, $FF  ; HealMore, YellHelp, SuckAll, -
EnemyStats_431:  ; Gigantes Lv33 join 5
    db 150
    dw 1730
    db 5, 33
    dw 210, 20, 226, 84, 128, 18  ; HP MP ATK DEF AGL INT
    db 100, 100, 100, 100  ; AI weights
    db $7F, $89, $D6, $FF  ; Imitate, Guardian, Smashlime, -
EnemyStats_432:  ; Skeletor Lv39 join 5
    db 172
    dw 3433
    db 5, 39
    dw 145, 160, 272, 224, 128, 166  ; HP MP ATK DEF AGL INT
    db 200, 50, 50, 150  ; AI weights
    db $4B, $54, $D7, $FF  ; BirdBlow, Focus, Sheldodge, -
EnemyStats_433:  ; Snapper Lv40 join 5
    db 107
    dw 3520
    db 5, 40
    dw 186, 161, 234, 124, 127, 118  ; HP MP ATK DEF AGL INT
    db 250, 0, 100, 200  ; AI weights
    db $43, $5F, $D8, $FF  ; SuckAir, WhiteFire, Branching, -
EnemyStats_434:  ; LavaMan Lv38 join 5
    db 192
    dw 3546
    db 5, 38
    dw 190, 113, 198, 159, 140, 101  ; HP MP ATK DEF AGL INT
    db 200, 50, 50, 150  ; AI weights
    db $11, $3B, $55, $FF  ; Thordain, TwinSlash, SquallHit, -
EnemyStats_435:  ; Phoenix Lv40 join 5
    db 85
    dw 3533
    db 5, 40
    dw 181, 116, 177, 121, 155, 81  ; HP MP ATK DEF AGL INT
    db 200, 50, 0, 150  ; AI weights
    db $4C, $68, $87, $FF  ; DevilCut, NapAttack, BazooCall, -
EnemyStats_436:  ; KingSlime Lv38 join 5
    db 15
    dw 3483
    db 5, 38
    dw 250, 94, 218, 181, 206, 200  ; HP MP ATK DEF AGL INT
    db 250, 150, 0, 200  ; AI weights
    db $0E, $40, $49, $FF  ; Blizzard, EvilSlash, DrakSlash, -
EnemyStats_437:  ; MadPecker Lv38 join 5
    db 75
    dw 3516
    db 5, 38
    dw 139, 88, 197, 115, 186, 127  ; HP MP ATK DEF AGL INT
    db 200, 0, 200, 100  ; AI weights
    db $16, $25, $4A, $FF  ; SleepAll, TwinHits, BeastCut, -
EnemyStats_438:  ; BombCrag Lv40 join 5
    db 198
    dw 3496
    db 5, 40
    dw 260, 174, 156, 233, 20, 134  ; HP MP ATK DEF AGL INT
    db 150, 50, 150, 0  ; AI weights
    db $29, $6B, $7C, $FF  ; Transform, PalsyAir, BigTrip, -
EnemyStats_439:  ; FangSlime Lv33 join 5
    db 10
    dw 3553
    db 5, 33
    dw 184, 78, 166, 151, 311, 141  ; HP MP ATK DEF AGL INT
    db 100, 0, 200, 250  ; AI weights
    db $1F, $74, $7D, $FF  ; Increase, EerieLite, WarCry, -
EnemyStats_440:  ; ZapBird Lv39 join 5
    db 86
    dw 3583
    db 5, 39
    dw 224, 87, 187, 167, 210, 222  ; HP MP ATK DEF AGL INT
    db 100, 100, 100, 50  ; AI weights
    db $82, $91, $92, $FF  ; UltraDown, DanceShut, MouthShut, -
EnemyStats_441:  ; Spikerous Lv28 join 5
    db 36
    dw 3466
    db 5, 28
    dw 204, 18, 177, 300, 81, 104  ; HP MP ATK DEF AGL INT
    db 200, 200, 200, 100  ; AI weights
    db $28, $67, $83, $FF  ; Bounce, PoisonHit, ThickFog, -
EnemyStats_442:  ; Centasaur Lv40 join 5
    db 151
    dw 3540
    db 5, 40
    dw 251, 124, 290, 352, 338, 211  ; HP MP ATK DEF AGL INT
    db 200, 200, 200, 200  ; AI weights
    db $30, $44, $70, $FF  ; Vivify, FireSlash, Ahhh, -
EnemyStats_443:  ; BombCrag Lv39 join 5
    db 198
    dw 3483
    db 5, 39
    dw 210, 157, 138, 239, 18, 132  ; HP MP ATK DEF AGL INT
    db 100, 100, 100, 150  ; AI weights
    db $46, $81, $92, $FF  ; VacuSlash, Surge, MouthShut, -
EnemyStats_444:  ; SkyDragon Lv33 join 5
    db 43
    dw 3516
    db 5, 33
    dw 165, 164, 198, 175, 123, 112  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $14, $23, $31, $FF  ; Sacrifice, SpeedUp, Revive, -
EnemyStats_445:  ; BattleRex Lv39 join 5
    db 42
    dw 3473
    db 5, 39
    dw 187, 122, 286, 187, 200, 141  ; HP MP ATK DEF AGL INT
    db 200, 150, 150, 0  ; AI weights
    db $63, $6F, $94, $FF  ; WhiteAir, Curse, Hustle, -
EnemyStats_446:  ; FunkyBird Lv39 join 5
    db 88
    dw 3540
    db 5, 39
    dw 178, 197, 151, 227, 143, 198  ; HP MP ATK DEF AGL INT
    db 50, 50, 50, 0  ; AI weights
    db $1F, $2E, $5A, $FF  ; Increase, HealUs, Lightning, -
EnemyStats_447:  ; StoneMan Lv40 join 5
    db 197
    dw 3496
    db 5, 40
    dw 222, 126, 199, 257, 107, 184  ; HP MP ATK DEF AGL INT
    db 100, 100, 100, 100  ; AI weights
    db $17, $87, $89, $FF  ; StopSpell, BazooCall, Guardian, -
EnemyStats_448:  ; GulpBeast Lv38 join 6
    db 50
    dw 7140
    db 6, 38
    dw 340, 90, 300, 185, 150, 90  ; HP MP ATK DEF AGL INT
    db 250, 0, 100, 50  ; AI weights
    db $0E, $42, $4D, $FF  ; Blizzard, HighJump, ZombieCut, -
EnemyStats_449:  ; GreatDrak Lv45 join 6
    db 37
    dw 7260
    db 6, 45
    dw 350, 130, 240, 210, 170, 210  ; HP MP ATK DEF AGL INT
    db 250, 0, 50, 200  ; AI weights
    db $0B, $41, $D6, $FF  ; Infermost, ChargeUP, Smashlime, -
EnemyStats_450:  ; Trumpeter Lv45 join 6
    db 65
    dw 7480
    db 6, 45
    dw 190, 150, 330, 210, 190, 130  ; HP MP ATK DEF AGL INT
    db 200, 50, 100, 200  ; AI weights
    db $02, $45, $4C, $FF  ; Blazemost, BoltSlash, DevilCut, -
EnemyStats_451:  ; MetalDrak Lv43 join 6
    db 185
    dw 7836
    db 6, 43
    dw 310, 105, 240, 220, 250, 130  ; HP MP ATK DEF AGL INT
    db 150, 50, 50, 100  ; AI weights
    db $08, $40, $47, $FF  ; Explodet, EvilSlash, IceSlash, -
EnemyStats_452:  ; ZapBird Lv45 join 6
    db 86
    dw 7933
    db 6, 45
    dw 260, 120, 210, 200, 240, 255  ; HP MP ATK DEF AGL INT
    db 250, 50, 150, 100  ; AI weights
    db $3F, $46, $59, $FF  ; Massacre, VacuSlash, Vacuum, -
EnemyStats_453:  ; WhipBird Lv45 join 6
    db 87
    dw 7273
    db 6, 45
    dw 480, 200, 150, 250, 240, 230  ; HP MP ATK DEF AGL INT
    db 200, 200, 150, 250  ; AI weights
    db $32, $51, $72, $FF  ; Farewell, QuadHits, SandStorm, -
EnemyStats_454:  ; Metabble Lv38 join 6
    db 17
    dw 30376
    db 6, 38
    dw 23, 490, 190, 670, 511, 255  ; HP MP ATK DEF AGL INT
    db 100, 50, 150, 0  ; AI weights
    db $28, $3C, $53, $FF  ; Bounce, Ramming, YellHelp, -
EnemyStats_455:  ; Balzak Lv33 join 6
    db 186
    dw 7783
    db 6, 33
    dw 330, 165, 210, 320, 280, 180  ; HP MP ATK DEF AGL INT
    db 250, 100, 200, 250  ; AI weights
    db $16, $69, $78, $FF  ; SleepAll, Paralyze, LureDance, -
EnemyStats_456:  ; MadDragon Lv33 join 6
    db 30
    dw 7176
    db 6, 33
    dw 200, 24, 335, 130, 190, 30  ; HP MP ATK DEF AGL INT
    db 250, 0, 200, 150  ; AI weights
    db $43, $63, $92, $FF  ; SuckAir, WhiteAir, MouthShut, -
EnemyStats_457:  ; GoatHorn Lv33 join 6
    db 142
    dw 7200
    db 6, 33
    dw 150, 190, 220, 150, 190, 240  ; HP MP ATK DEF AGL INT
    db 200, 150, 250, 0  ; AI weights
    db $1D, $6F, $7A, $FF  ; Defence, Curse, SickLick, -
EnemyStats_458:  ; DeadNoble Lv46 join 6
    db 169
    dw 7540
    db 6, 46
    dw 340, 240, 340, 280, 280, 215  ; HP MP ATK DEF AGL INT
    db 200, 250, 200, 200  ; AI weights
    db $2D, $44, $8C, $FF  ; HealAll, FireSlash, Dodge, -
EnemyStats_459:  ; Roboster Lv38 join 6
    db 189
    dw 7033
    db 6, 38
    dw 280, 245, 340, 230, 360, 210  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 50  ; AI weights
    db $2E, $4F, $8B, $FF  ; HealUs, MultiCut, StormWind, -
EnemyStats_460:  ; Andreal Lv45 join 6
    db 34
    dw 7116
    db 6, 45
    dw 340, 280, 200, 320, 200, 250  ; HP MP ATK DEF AGL INT
    db 250, 250, 200, 200  ; AI weights
    db $31, $81, $8F, $FF  ; Revive, Surge, SuckAll, -
EnemyStats_461:  ; Unicorn Lv45 join 6
    db 62
    dw 9506
    db 6, 45
    dw 200, 330, 200, 150, 290, 255  ; HP MP ATK DEF AGL INT
    db 200, 250, 250, 250  ; AI weights
    db $55, $78, $89, $FF  ; SquallHit, LureDance, Guardian, -
EnemyStats_462:  ; Digster Lv46 join 6
    db 129
    dw 7033
    db 6, 46
    dw 267, 115, 197, 257, 110, 185  ; HP MP ATK DEF AGL INT
    db 150, 150, 150, 50  ; AI weights
    db $94, $96, $D8, $FF  ; Hustle, LifeDance, Branching, -
EnemyStats_463:  ; Copycat Lv38 join 6
    db 174
    dw 7513
    db 6, 38
    dw 210, 210, 120, 167, 138, 200  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $29, $3E, $63, $FF  ; Transform, Kamikaze, WhiteAir, -
EnemyStats_464:  ; GreatDrak Lv50 join 6
    db 37
    dw 13400
    db 6, 50
    dw 370, 150, 250, 220, 190, 230  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $25, $4F, $7A, $FF  ; TwinHits, MultiCut, SickLick, -
EnemyStats_465:  ; Roboster Lv38 join 6
    db 189
    dw 13500
    db 6, 38
    dw 300, 260, 350, 240, 380, 250  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $2C, $54, $55, $FF  ; HealMore, Focus, SquallHit, -
EnemyStats_466:  ; Balzak Lv33 join 6
    db 186
    dw 13666
    db 6, 33
    dw 380, 190, 240, 340, 300, 210  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $11, $2E, $83, $FF  ; Thordain, HealUs, ThickFog, -
EnemyStats_467:  ; WhipBird Lv50 join 6
    db 87
    dw 13616
    db 6, 50
    dw 500, 200, 180, 260, 250, 255  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $40, $87, $94, $FF  ; EvilSlash, BazooCall, Hustle, -
EnemyStats_468:  ; MetalDrak Lv43 join 6
    db 185
    dw 13373
    db 6, 43
    dw 330, 120, 260, 240, 250, 160  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $39, $6E, $7C, $FF  ; Chance, PaniDance, BigTrip, -
EnemyStats_469:  ; GateGuard Lv48 join 6
    db 145
    dw 13516
    db 6, 48
    dw 340, 300, 330, 210, 150, 210  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $63, $7F, $89, $FF  ; WhiteAir, Imitate, Guardian, -
EnemyStats_470:  ; ChopClown Lv48 join 6
    db 146
    dw 13600
    db 6, 48
    dw 310, 300, 300, 200, 260, 255  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $14, $54, $93, $FF  ; Sacrifice, Focus, Meditate, -
EnemyStats_471:  ; MetalKing Lv50 join 6
    db 18
    dw 30376
    db 6, 50
    dw 25, 700, 290, 700, 511, 255  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $68, $89, $96, $FF  ; NapAttack, Guardian, LifeDance, -
EnemyStats_472:  ; Orochi Lv50 join 6
    db 41
    dw 13440
    db 6, 50
    dw 360, 150, 360, 350, 200, 180  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $13, $78, $94, $FF  ; Defeat, LureDance, Hustle, -
EnemyStats_473:  ; Trumpeter Lv48 join 6
    db 65
    dw 13600
    db 6, 48
    dw 220, 170, 250, 220, 210, 150  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $08, $7D, $91, $FF  ; Explodet, WarCry, DanceShut, -
EnemyStats_474:  ; Snapper Lv50 join 6
    db 107
    dw 13650
    db 6, 50
    dw 250, 210, 250, 160, 160, 200  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $42, $4F, $7A, $FF  ; HighJump, MultiCut, SickLick, -
EnemyStats_475:  ; HornBeet Lv48 join 6
    db 127
    dw 13556
    db 6, 48
    dw 380, 190, 240, 250, 300, 200  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $67, $72, $93, $FF  ; PoisonHit, SandStorm, Meditate, -
EnemyStats_476:  ; DeadNoble Lv48 join 6
    db 169
    dw 13526
    db 6, 48
    dw 340, 350, 350, 190, 290, 230  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $66, $77, $8E, $FF  ; MegaMagic, SideStep, StrongD, -
EnemyStats_477:  ; Servant Lv50 join 6
    db 173
    dw 13573
    db 6, 50
    dw 240, 340, 210, 320, 290, 250  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $5F, $6F, $8B, $FF  ; WhiteFire, Curse, StormWind, -
EnemyStats_478:  ; StoneMan Lv48 join 6
    db 197
    dw 13416
    db 6, 48
    dw 360, 160, 240, 360, 100, 200  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $43, $63, $74, $FF  ; SuckAir, WhiteAir, EerieLite, -
EnemyStats_479:  ; BombCrag Lv48 join 6
    db 198
    dw 13630
    db 6, 48
    dw 290, 200, 180, 260, 20, 150  ; HP MP ATK DEF AGL INT
    db 250, 250, 250, 250  ; AI weights
    db $57, $7F, $D5, $FF  ; RainSlash, Imitate, BeDragon, -
EnemyStats_480:  ; Slime Lv1 join 1
    db 8
    dw 65000
    db 1, 1
    dw 2, 0, 2, 2, 2, 2  ; HP MP ATK DEF AGL INT
    db 100, 100, 100, 100  ; AI weights
    db $FF, $FF, $FF, $FF  ; -, -, -, -
EnemyStats_481:  ; GoldSlime Lv70 join 7
    db 19
    dw 0
    db 7, 70
    dw 900, 600, 400, 999, 411, 255  ; HP MP ATK DEF AGL INT
    db 0, 250, 0, 250  ; AI weights
    db $2E, $31, $81, $FF  ; HealUs, Revive, Surge, -
EnemyStats_482:  ; Divinegon Lv70 join 7
    db 44
    dw 0
    db 7, 70
    dw 6500, 999, 700, 400, 280, 255  ; HP MP ATK DEF AGL INT
    db 250, 0, 250, 250  ; AI weights
    db $40, $54, $64, $FF  ; EvilSlash, Focus, Hellblast, -
EnemyStats_483:  ; Rosevine Lv70 join 7
    db 108
    dw 0
    db 7, 70
    dw 1800, 999, 600, 500, 400, 255  ; HP MP ATK DEF AGL INT
    db 0, 0, 250, 250  ; AI weights
    db $7F, $80, $8B, $FF  ; Imitate, DeMagic, StormWind, -
EnemyStats_484:  ; Dragon Lv6 join 0
    db 28
    dw 0
    db 0, 6
    dw 60, 20, 40, 25, 20, 30  ; HP MP ATK DEF AGL INT
    db 250, 50, 0, 250  ; AI weights
    db $44, $5C, $FF, $FF  ; FireSlash, FireAir, -, -
EnemyStats_485:  ; Golem Lv7 join 0
    db 196
    dw 0
    db 0, 7
    dw 80, 20, 45, 35, 15, 70  ; HP MP ATK DEF AGL INT
    db 150, 150, 150, 200  ; AI weights
    db $41, $56, $8E, $FF  ; ChargeUP, PsycheUp, StrongD, -
EnemyStats_486:  ; Dracky Lv1 join 1
    db 78
    dw 4
    db 1, 1
    dw 14, 20, 12, 4, 12, 14  ; HP MP ATK DEF AGL INT
    db 200, 0, 0, 200  ; AI weights
    db $33, $FF, $FF, $FF  ; Antidote, -, -, -
; @BUILD_PROJECT END gd_enemy_stats

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

    ld hl, $7202                ; [ANCHOR S73] was `ld a,$ff / ld [$da5e],a / ret`
    rst $10                     ;   (6 bytes -> 3+1+1+nop, byte-neutral). Bank $72
    ret                         ;   entry 2 (AnchorField14Tail) handles $E4 (context
    nop                         ;   classify + dialog-script arm) and reproduces the
                                ;   vanilla $da5e=$FF fizzle default for other ids.


Jump_014_7bf4:
    call LoadEnem_7d00
    ret nz

    ld a, [$da60]
    ld hl, $cb13
    call ReadMonsterWord

SaveEnem_7c01:
    push bc
    ld a, [$da60]
    ld hl, $cb11
    call ReadMonsterWord
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
    call SetEnem_7d03
    jr nz, jr_014_7c4a

    ld a, $00
    ld hl, $cb13
    call ReadMonsterWord
    push bc
    ld a, $00
    ld hl, $cb11
    call ReadMonsterWord
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
    call SetEnem_7d03
    jr nz, jr_014_7c73

    ld a, $01
    ld hl, $cb13
    call ReadMonsterWord
    push bc
    ld a, $01
    ld hl, $cb11
    call ReadMonsterWord
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
    call SetEnem_7d03
    jr nz, jr_014_7c95

    ld a, $02
    ld hl, $cb13
    call ReadMonsterWord
    push bc
    ld a, $02
    ld hl, $cb11
    call ReadMonsterWord
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
    call ReadMonsterByte
    bit 7, a
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


Jump_014_7cad:
    call LoadEnem_7d00
    ret nz

    ld a, [$da60]
    ld hl, $cb0b
    call ReadMonsterByte
    bit 2, a
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


Jump_014_7cc3:
    call LoadEnem_7d00
    ret nz

    ld a, [$da60]
    ld hl, $cb0b
    call ReadMonsterByte
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


LoadEnem_7d00:
    ld a, [$da60]

SetEnem_7d03:
    ld hl, $cb0b
    call ReadMonsterByte
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
    call Div8x8
    add $1e
    ld l, a
    ld h, $00
    ld a, [$da60]
    call GetMonsterSkillData
    ret


Jump_014_7d6d:
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $10
    call Div8x8
    add $4b
    ld l, a
    ld h, $00
    ld a, [$da60]
    call GetMonsterSkillData
    ret


Jump_014_7d85:
    ld a, [$da60]
    ld hl, $cb13
    call ReadMonsterWord
    ld a, [$da60]
    ld hl, $cb11
    call WriteMonsterWord
    ret


Jump_014_7d98:
    ld a, $00
    ld [$da60], a
    ld a, $00
    call SetEnem_7db7
    ld a, $01
    ld [$da60], a
    ld a, $01
    call SetEnem_7db7
    ld a, $02
    ld [$da60], a
    ld a, $02
    call SetEnem_7db7
    ret


SetEnem_7db7:
    ld hl, $cb0b
    call ReadMonsterByte
    bit 7, a
    ret nz

    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $1f
    call Div8x8
    add $5a
    ld l, a
    ld h, $00
    ld a, [$da60]
    call GetMonsterSkillData
    ret


Jump_014_7dd8:
    ld a, $00
    call SetEnem_7d03
    jr nz, jr_014_7def

    ld a, $00
    ld hl, $cb13
    call ReadMonsterWord
    ld a, $00
    ld hl, $cb11
    call WriteMonsterWord

jr_014_7def:
    ld a, $01
    call SetEnem_7d03
    jr nz, jr_014_7e06

    ld a, $01
    ld hl, $cb13
    call ReadMonsterWord
    ld a, $01
    ld hl, $cb11
    call WriteMonsterWord

jr_014_7e06:
    ld a, $02
    call SetEnem_7d03
    jr nz, jr_014_7e1d

    ld a, $02
    ld hl, $cb13
    call ReadMonsterWord
    ld a, $02
    ld hl, $cb11
    call WriteMonsterWord

jr_014_7e1d:
    ret


Jump_014_7e1e:
    ld a, [wRNG1]
    bit 0, a
    jr nz, jr_014_7e47

    ld a, [$da60]
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    ld [hl], $00
    ld a, [$da60]
    ld hl, $cb13
    call ReadMonsterWord
    srl b
    rr c
    ld a, [$da60]
    ld hl, $cb11
    call WriteMonsterWord
    ret


jr_014_7e47:
    ld hl, $0e05
    call SetupTilemapTransfer
    ret


Jump_014_7e4e:
    ld a, [$da60]
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    ld [hl], $00
    ld a, [$da60]
    ld hl, $cb13
    call ReadMonsterWord
    ld a, [$da60]
    ld hl, $cb11
    call WriteMonsterWord
    ret


Jump_014_7e6c:
    ld a, [$da60]
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    res 2, [hl]
    ret


Jump_014_7e78:
    ld a, [$da60]
    ld hl, $cb0b
    call GetCurrentMonsterPtr
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



; --- free space $7EAD-$7ECB (31 B; vanilla zeros) ---
; S30-S104 held the Gorbunok enemy row (EID 518 @ $7EB3, reached with no fork as
; EID*25+$4C1D). Retired S105 (P3.9b): a new species' enemy rows are ordinary
; project enemies (progression.enemies, EID 519+, bank $6B — MONSTER_DATA
; "Project enemy rows"); EIDs 487-518 are code / this free space.
    ds 31, $00
; ===== S101: PROJECT ENEMY ROWS + REDIRECT EXTENSION (was the S70 12-row
; quest_enemy_stats region; MONSTER_DATA "Project enemy rows") ============
; LoadEnemyStatsExt — the LoadEnemyStats head jumps here. (S127: $0F00-$0F03 =
; a random breeder's slot, resolved first.) EIDs 519+ are the
; project's enemy rows, stored in bank $6B (compiler-generated
; patches/bank_06b.asm, 25 B/row, row = EID-519): bank $6B entry 0
; CopyEnemyRowExt copies the row to [DE] (DE advanced by 25, as the vanilla
; loop leaves it). rst $10 keeps DE; BC/HL are clobbered, which no caller
; reads (the 4 bank-$14 call sites return or jump right after). EIDs <= 518
; (vanilla 0-486; 518 was the S30 Gorbunok row, free space since S105) take
; the vanilla path unchanged.
LoadEnemyStatsExt:
    ld a, [$da13]            ; EID high
    cp $0f                   ; S127 (P3.14e2): $0F00 + k = a RANDOM breeder's
    jr nz, .notSlot          ;   mate (op $42): bank $77 entry 8 BreedSlotEID
    ld hl, $7708             ;   rolls slot k once and writes the real row to
    rst $10                  ;   wTempEnemyStatsId / $DA13 (keeps DE), then
    jr LoadEnemyStatsExt     ;   that row loads as any other (PROJECT_COMPILER §2.40)
.notSlot:
    cp $02
    jr c, .vanilla           ; < $0200
    jr nz, .ext              ; >= $0300
    ld a, [wTempEnemyStatsId]
    cp $07
    jr c, .vanilla           ; $0200-$0206 (< 519)
.ext:
    ld hl, $6b00             ; bank $6B entry 0: CopyEnemyRowExt
    rst $10
    ret
.vanilla:
    push de
    ld a, [wTempEnemyStatsId]
    jp LoadEnemyStatsResume
; @BUILD_PROJECT BEGIN boss_redirects
; BossRedirectTableExt (S101): fight EID -> join EID, scanned by the
; rewritten LookupBossRedirect (bank $14 entry 6). Project rows first
; (progression.enemies[].join_as), then the 34 vanilla rows, then
; $FFFF. Generated by editor2 `redirects14`; the pad fills the bank.
BossRedirectTableExt:
    dw 4, 486
    dw 11, 12
    dw 31, 484
    dw 32, 485
    dw 51, 52
    dw 53, 54
    dw 55, 56
    dw 75, 76
    dw 77, 78
    dw 79, 80
    dw 99, 100
    dw 101, 102
    dw 103, 104
    dw 123, 124
    dw 125, 126
    dw 127, 128
    dw 147, 148
    dw 149, 150
    dw 153, 154
    dw 175, 176
    dw 177, 178
    dw 179, 180
    dw 199, 200
    dw 201, 202
    dw 203, 204
    dw 205, 206
    dw 207, 208
    dw 209, 210
    dw 211, 212
    dw 213, 214
    dw 215, 216
    dw 217, 218
    dw 219, 220
    dw 221, 222
    dw $FFFF, $0000
    ds $8000 - @, $00
; @BUILD_PROJECT END boss_redirects
