; =============================================================================
; BANK $6B — PROJECT ENEMY ROWS (S101; compiler-owned, patches/bank_06b.asm)
; =============================================================================
; The vanilla enemy-stats table is bank $14 EnemyStatsTable ($4C1D, 25 B/row,
; EIDs 0-486; 487-517 would land in code; 518 = bank-$14 free space — the
; S30 Gorbunok row until S105). Every EID >= 519 is a PROJECT enemy row stored
; HERE (a new species' rows too, S105), 25 B each, row
; index = EID - 519, in the vanilla row format (MONSTER_DATA "Enemy Stats
; Table"): [species, exp:2, joinability, level, hp:2, mp:2, atk:2, def:2,
; agl:2, int:2, ai:4, skills:4].
;
; Entry 0 (HL=$6B00) CopyEnemyRowExt — called by bank $14 LoadEnemyStatsExt
; (the rewritten LoadEnemyStats head) for EIDs >= 519. In: wTempEnemyStatsId
; ($DA12/$DA13) = EID, DE = destination. Out: 25 bytes at [DE], DE advanced
; by 25 (exactly what the vanilla copy loop leaves). rst $10 preserves DE on
; the way in and out; A/BC/HL are clobbered (no LoadEnemyStats caller reads
; them). An EID past the last row copies row 0 (never emitted: the compiler
; only references rows it emits — validators).
; =============================================================================

SECTION "ROM Bank $06B", ROMX[$4000], BANK[$6B]

    db $6B                              ; bank self-ID at $4000

; rst-$10 entry table at $4001
    dw CopyEnemyRowExt                  ; entry 0  (HL=$6B00)

CopyEnemyRowExt:
    ld a, [wTempEnemyStatsId]
    sub LOW(PROJECT_EID_BASE)
    ld l, a
    ld a, [wTempEnemyStatsId + 1]
    sbc HIGH(PROJECT_EID_BASE)
    ld h, a                             ; HL = row index (carry = EID < base)
    jr c, .first
    ld a, l
    sub LOW(PROJECT_ENEMY_ROWS)
    ld a, h
    sbc HIGH(PROJECT_ENEMY_ROWS)
    jr c, .inRange                      ; index < row count
.first:
    ld hl, $0000                        ; out of range -> row 0
.inRange:
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
