; =============================================================================
; BANK $60 — CUSTOM ROOM OVERFLOW BANK
; =============================================================================
; Contains room data for custom map types ($6B+).
; Reader functions copy NPC/exit data to WRAM buffers so bank $0B code
; can access it after rst $10 returns.
;
; Entry points (called via rst $10 from bank $0B):
;   Entry 0: CustomReadStep    — returns DE = [step_id, tileset_bank]
;   Entry 1: CustomReadInteract — copies NPC data to wCustomNPCBuffer, returns HL
;   Entry 2: CustomExitCheck    — copies exit data to wCustomExitBuffer, returns HL
;   Entry 3: CustomTilesetInfo  — (legacy, unused — source mapID now via wCustomRoomFlag)
; =============================================================================

SECTION "ROM Bank $060", ROMX[$4000], BANK[$60]
    db $60 ; bank number

    ; Dispatch table (4 entries)
    dw CustomReadStep       ; Entry 0
    dw CustomReadInteract   ; Entry 1
    dw CustomExitCheck      ; Entry 2
    dw CustomTilesetInfo    ; Entry 3 (legacy)

; =============================================================================
; CustomPtrChase — Shared pointer-chase for overflow room data
; =============================================================================
; Also sets wCustomRoomFlag to the source mapID for this custom room.
; Input: wMapID, wScreenIndex
; Output: HL = pointer to current 6-byte step entry (in THIS bank)
; =============================================================================
CustomPtrChase:
    ; Set wCustomRoomFlag = source mapID for this custom room
    ld hl, CustomSourceMapTable
    ld a, [wMapID]
    sub CUSTOM_ROOM_START
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [wCustomRoomFlag], a
    ; Pointer chase: CustomRoomPtrTable → sub-table → step block
    ld hl, CustomRoomPtrTable
    ld a, [wMapID]
    sub CUSTOM_ROOM_START
    add a                       ; × 2 for pointer size
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ; HL = sub-table pointer
    ld a, [wScreenIndex]
    add a                       ; × 2
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ; HL = step block ptr — check for $FFFF (unused screen)
    ld a, h
    and l
    cp $FF
    jr nz, .validScreen
    ld hl, DummyStepEntry       ; safe fallback
    ret
.validScreen:
    ; Skip RAM counter (2 bytes), always use step 0
    inc hl
    inc hl
    ret

; Dummy step entry for unused screens (prevents crash)
; Uses Castle screen 0's tileset so decompression doesn't read garbage
DummyStepEntry:
    db 1, $2A                   ; step_id=1, tileset_bank=$2A (Castle valid data)
    dw DummyNPCs
    dw DummyExits
DummyNPCs:
    db $FF
DummyExits:
    ; Bottom exits back to GreatTree at several x positions
    db $03, $07, $01, $00, $80, $04, $04
    db $05, $07, $01, $00, $80, $04, $04
    db $07, $07, $01, $00, $80, $04, $04
    ; Top exits back to GreatTree
    db $03, $00, $01, $00, $80, $04, $04
    db $05, $00, $01, $00, $80, $04, $04
    db $FF

; =============================================================================
; Entry 0: CustomReadStep
; =============================================================================
CustomReadStep:
    call CustomPtrChase
    ld e, [hl]                  ; step_id
    inc hl
    ld d, [hl]                  ; tileset_bank
    ret

; =============================================================================
; Entry 1: CustomReadInteract
; =============================================================================
CustomReadInteract:
    call CustomPtrChase
    inc hl
    inc hl                      ; skip step_id + tileset_bank
    ld a, [hl+]
    ld h, [hl]
    ld l, a                     ; HL = interact_ptr
    ld de, wCustomNPCBuffer
.copyNPCEntry:
    ld a, [hl]
    cp $FF
    jr z, .npcDone
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    jr .copyNPCEntry
.npcDone:
    ld a, $FF
    ld [de], a
    ld hl, wCustomNPCBuffer
    ret

; =============================================================================
; Entry 2: CustomExitCheck
; =============================================================================
CustomExitCheck:
    call CustomPtrChase
    inc hl
    inc hl
    inc hl
    inc hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a                     ; HL = exit_ptr
    ld de, wCustomExitBuffer
.copyExitEntry:
    ld a, [hl]
    cp $FF
    jr z, .exitDone
    ld b, $07
.copyExitByte:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, .copyExitByte
    jr .copyExitEntry
.exitDone:
    ld a, $FF
    ld [de], a
    ld hl, wCustomExitBuffer
    ret

; =============================================================================
; Entry 3: CustomTilesetInfo (legacy — kept for compatibility)
; =============================================================================
CustomTilesetInfo:
    ld a, [wCustomRoomFlag]
    ret

; =============================================================================
; CUSTOM ROOM DATA
; =============================================================================

; Source map type for each custom room (for palette, tileset GFX, collision)
CustomSourceMapTable:
    db $16                      ; Room 0 ($6B) → MedalMan
    db $00                      ; Room 1 ($6C) → Castle

; Room pointer table: (mapID - CUSTOM_ROOM_START) × 2
CustomRoomPtrTable:
    dw CustomRoom0_SubTable     ; mapID $6B — MedalMan clone
    dw CustomRoom1_SubTable     ; mapID $6C — Castle 2-screen clone

; =============================================
; Room 0 (mapID $6B) — MedalMan single-screen
; =============================================
CustomRoom0_SubTable:
    dw CustomRoom0_Screen0
    dw $FFFF
    dw $FFFF
    dw $FFFF
    dw $FFFF
    dw $FFFF
    dw $FFFF
    dw $FFFF

CustomRoom0_Screen0:
    dw $D95E                    ; RAM step counter
    db 13                       ; step_id (MedalMan layout)
    db $30                      ; tileset_bank
    dw CustomRoom0_NPCs
    dw CustomRoom0_Exits

CustomRoom0_NPCs:
    ; Spawn from GreatTree stairway
    db $8F, $FF, $02, $06, $01
    db $FF

CustomRoom0_Exits:
    ; Bottom exit → GreatTree screen 8, matching WellStairway exit exactly
    db $03, $07, $01, $00, $08, $04, $05
    ; Top exit → Castle clone room $6C, screen 1, spawn at bottom
    db $03, $01, $6C, $00, $01, $05, $07
    db $FF

; =============================================
; Room 1 (mapID $6C) — Castle 3-screen clone
; =============================================
; Layout:  [0] [1]
;          [-] [5]
; Screen 0: throne room left, Screen 1: throne room right (double doors)
; Screen 5: below throne room (has exit to GreatTree at bottom)
CustomRoom1_SubTable:
    dw CustomRoom1_Screen0      ; screen 0 (row 0, col 0)
    dw CustomRoom1_Screen1      ; screen 1 (row 0, col 1)
    dw $FFFF                    ; screen 2: unused
    dw $FFFF                    ; screen 3: unused
    dw $FFFF                    ; screen 4: unused (no screen below screen 0)
    dw CustomRoom1_Screen5      ; screen 5 (row 1, col 1) — below screen 1
    dw $FFFF                    ; screen 6: unused
    dw $FFFF                    ; screen 7: unused

CustomRoom1_Screen0:
    dw $D9A0                    ; RAM step counter
    db 1                        ; step_id (Castle screen 0 layout)
    db $2A                      ; tileset_bank (Castle)
    dw CustomRoom1_S0_NPCs
    dw CustomRoom1_S0_Exits

CustomRoom1_S0_NPCs:
    db $8F, $FF, $09, $04, $01  ; spawn point
    db $FF

CustomRoom1_S0_Exits:
    db $FF                      ; no exits on screen 0 (scroll right to screen 1)

CustomRoom1_Screen1:
    dw $D9A1                    ; RAM step counter
    db 5                        ; step_id (Castle screen 1 layout)
    db $2A                      ; tileset_bank (Castle)
    dw CustomRoom1_S1_NPCs
    dw CustomRoom1_S1_Exits

CustomRoom1_S1_NPCs:
    ; Spawn point (entering from MedalMan room)
    db $8F, $FF, $05, $07, $6B
    db $FF

CustomRoom1_S1_Exits:
    ; Double doors exit at (7,1) → GreatTree screen 8
    db $07, $01, $01, $00, $80, $04, $04
    db $FF

CustomRoom1_Screen5:
    dw $D9A2                    ; RAM step counter
    db 7                        ; step_id (Castle screen 5 layout)
    db $2A                      ; tileset_bank (Castle)
    dw CustomRoom1_S5_NPCs
    dw CustomRoom1_S5_Exits

CustomRoom1_S5_NPCs:
    db $8F, $FF, $04, $02, $01  ; spawn point
    db $FF

CustomRoom1_S5_Exits:
    ; Bottom exits → GreatTree screen 8 (matching original Castle exits)
    db $04, $07, $01, $00, $80, $04, $04
    db $05, $07, $01, $00, $80, $04, $04
    db $FF
