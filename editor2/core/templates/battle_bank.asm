; =============================================================================
; BATTLE BANK{B} — enemy rows and battle lists past banks $6B / $76
; (S149, ROADMAP ARC CAP5; template editor2/core/templates/battle_bank.asm)
; =============================================================================
; A project's enemy rows fill bank $6B first, its own battle lists bank $76;
; the rest go to battle banks $80+ (editor2/core/battles.py plan, after the
; stream / place / animation / song banks). Each battle bank holds a run of
; rows (EIDs ROW_FIRST{B} ..) and / or a run of lists (project list indexes
; LIST_FIRST{B} ..) and this copier block, pasted at $4001 with {B} = "_B<bank>"
; so that BattleEntries{B} IS the bank's rst $10 entry table.
;
; Entry 0 BattleRowCopy{B} — far-called by bank $6B CopyEnemyRowExt for a row
;   past bank $6B. In: wTempEnemyStatsId = EID (one of this bank's rows), DE =
;   destination. Out: the 25-byte row at [DE], DE advanced by 25 (rst $10 hands
;   the callee's DE back). Clobbers A/BC/HL.
; Entry 1 BattleListCopy{B} — far-called by bank $76 EncResolve for a project
;   list past bank $76. In: DE = the project list index (list number - 128).
;   Out: its 26 bytes in wEncListBuf. Clobbers A/BC/DE/HL.
; =============================================================================
BattleEntries{B}:
    dw BattleRowCopy{B}                 ; entry 0
    dw BattleListCopy{B}                ; entry 1

BattleRowCopy{B}:
    ld a, [wTempEnemyStatsId]
    sub LOW(ROW_FIRST{B})
    ld l, a
    ld a, [wTempEnemyStatsId + 1]
    sbc HIGH(ROW_FIRST{B})
    ld h, a                             ; HL = i (this bank's row)
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
    ld de, BattleRows{B}
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

BattleListCopy{B}:
    ld a, e
    sub LOW(LIST_FIRST{B})
    ld l, a
    ld a, d
    sbc HIGH(LIST_FIRST{B})
    ld h, a                             ; HL = n (this bank's list)
    add hl, hl                          ; 2n
    ld d, h
    ld e, l                             ; DE = 2n
    add hl, hl                          ; 4n
    add hl, hl                          ; 8n
    ld b, h
    ld c, l                             ; BC = 8n
    add hl, hl                          ; 16n
    add hl, bc                          ; 24n
    add hl, de                          ; 26n
    ld de, BattleLists{B}
    add hl, de                          ; HL = &list
    ld de, wEncListBuf
    ld c, 26
.copy:
    ld a, [hl+]
    ld [de], a
    inc de
    dec c
    jr nz, .copy
    ret

; ------------------------------- generated (editor2/core/battles.py) --------
