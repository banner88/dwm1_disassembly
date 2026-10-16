; =============================================================================
; BANK $6B — PROJECT ENEMY ROWS (S101; compiler-owned, patches/bank_06b.asm)
; =============================================================================
; The vanilla enemy-stats table is bank $14 EnemyStatsTable ($4C1D, 25 B/row,
; EIDs 0-486; 487-517 would land in code; 518 = bank-$14 free space — the
; S30 Gorbunok row until S105). Every EID >= 519 is a PROJECT enemy row
; (a new species' rows too, S105), 25 B each, row index = EID - 519, in the
; vanilla row format (MONSTER_DATA "Enemy Stats Table"): [species, exp:2,
; joinability, level, hp:2, mp:2, atk:2, def:2, agl:2, int:2, ai:4, skills:4].
;
; S149 (ROADMAP ARC CAP5, battles at campaign scale): the rows start HERE and
; continue in BATTLE BANKS $80+ (templates/battle_bank.asm; up to 3,321 rows =
; EIDs 519-3839 — $0F00+ are the random breeders' slots, bank $14
; LoadEnemyStatsExt). This bank keeps the first ROWS_HERE rows; RowBankTable
; names the battle bank of every later row. Every project row also has a
; GENDER CODE here (ProjectEnemyGender, one byte a row: $00 male / $01 female
; fixed, $FF = rolled by the species' ratio — the vanilla EnemyGroupTable
; meaning; the vanilla table covers EIDs 0-511 only, and its unbounded read gave
; every project row a fixed or junk gender until S149).
;
; Entry 0 (HL=$6B00) CopyEnemyRowExt — called by bank $14 LoadEnemyStatsExt
; (the rewritten LoadEnemyStats head) for EIDs >= 519. In: wTempEnemyStatsId
; ($DA12/$DA13) = EID, DE = destination. Out: 25 bytes at [DE], DE advanced
; by 25 (exactly what the vanilla copy loop leaves). rst $10 preserves DE on
; the way in and hands the callee's DE back (a battle bank's copier advances
; it the same way); A/BC/HL are clobbered (no LoadEnemyStats caller reads
; them). An EID past the last row copies row 0 (never emitted: the compiler
; only references rows it emits — validators).
;
; Entry 1 (HL=$6B01, S149) EnemyGenderOf — called by bank $14 EnemyGenderCode
; (the monster constructor's gender read, label14_40b4) for EIDs >= $200.
; In: wTempEnemyStatsId = EID. Out: E = the row's gender code ($FF for an EID
; that is not a project row). Clobbers A/BC/HL.
;
; Generated below the head: PROJECT_EID_BASE / PROJECT_ENEMY_ROWS / ROWS_HERE
; EQUs, RowBankTable ([dw end row (exclusive), db bank] per battle bank, in
; row order), ProjectEnemyGender, ProjectEnemyRows (the first ROWS_HERE rows).
; =============================================================================

SECTION "ROM Bank $06B", ROMX[$4000], BANK[$6B]

    db $6B                              ; bank self-ID at $4000

; rst-$10 entry table at $4001
    dw CopyEnemyRowExt                  ; entry 0  (HL=$6B00)
    dw EnemyGenderOf                    ; entry 1  (HL=$6B01, S149)

; RowIndexOf: HL := EID - PROJECT_EID_BASE; carry = not a project row
; (below the base or past the last row). Clobbers A.
RowIndexOf:
    ld a, [wTempEnemyStatsId]
    sub LOW(PROJECT_EID_BASE)
    ld l, a
    ld a, [wTempEnemyStatsId + 1]
    sbc HIGH(PROJECT_EID_BASE)
    ld h, a                             ; HL = row index (carry = EID < base)
    ret c
    ld a, l
    sub LOW(PROJECT_ENEMY_ROWS)
    ld a, h
    sbc HIGH(PROJECT_ENEMY_ROWS)
    ccf                                 ; carry = index >= row count
    ret

CopyEnemyRowExt:
    call RowIndexOf
    jr nc, .inRange
    ld hl, $0000                        ; out of range -> row 0
.inRange:
    ld a, l
    sub LOW(ROWS_HERE)
    ld a, h
    sbc HIGH(ROWS_HERE)
    jr nc, .far                         ; a row of a battle bank
    push de
    ld d, h
    ld e, l                             ; DE = i
    add hl, hl                          ; 2i
    add hl, hl                          ; 4i
    add hl, hl                          ; 8i
    ld b, h
    ld c, l                             ; BC = 8i
    add hl, hl                          ; 16i
    add hl, bc                          ; 24i
    add hl, de                          ; 25i
    ld de, ProjectEnemyRows
    add hl, de                          ; HL = &row
    pop de
    ld b, 25
.copy:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, .copy
    ret
.far:
    ld b, h
    ld c, l                             ; BC = row index
    ld hl, RowBankTable
.find:
    ld a, c
    sub [hl]
    inc hl
    ld a, b
    sbc [hl]
    inc hl
    jr c, .found                        ; index < this bank's end
    inc hl
    jr .find
.found:
    ld h, [hl]
    ld l, $00                           ; that battle bank's entry 0 BattleRowCopy
    rst $10                             ; (it reads the EID itself; DE comes back +25)
    ret

EnemyGenderOf:
    ld e, $FF
    call RowIndexOf
    ret c                               ; not a project row: rolled
    ld bc, ProjectEnemyGender
    add hl, bc
    ld e, [hl]
    ret

; ------------------------------- generated (editor2/core/battles.py) --------

; =============================================================================
; BATTLE DATA (generated by editor2/core/battles.py from progression.enemies —
; PROJECT_COMPILER §2.57). Row = EID - 519; an empty project keeps one zero row.
; =============================================================================
PROJECT_EID_BASE EQU 519
PROJECT_ENEMY_ROWS EQU 2
ROWS_HERE EQU 2
RowBankTable:  ; [dw end row (exclusive), db battle bank] in row order
ProjectEnemyGender:  ; per row: $FF rolled by the species' ratio, $00 male, $01 female
    db $FF, $FF  ; rows 0-1
ProjectEnemyRows:
ProjectEnemy_519:   ; EID 519 vault_goldslime — species 19 L30, joinability 0
    db $13, $E0, $2E, $00, $1E, $7C, $01, $5A, $00, $A5, $00, $40, $01, $BE, $00, $82, $00, $FA, $96, $C8, $00, $1E, $1A, $3C, $FF
ProjectEnemy_520:   ; EID 520 gorbunok_wild — species 224 L1, joinability 2
    db $E0, $03, $00, $02, $01, $08, $00, $00, $00, $08, $00, $05, $00, $07, $00, $01, $00, $C8, $32, $64, $C8, $FF, $FF, $FF, $FF
