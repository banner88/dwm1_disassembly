; =============================================================================
; BANK $60 — CUSTOM ROOM OVERFLOW BANK
; =============================================================================
; Entry points (called via rst $10):
;   Entry 0: CustomReadStep     — returns DE = [step_id, tileset_bank]
;   Entry 1: CustomReadInteract — copies NPC data to wCustomNPCBuffer
;   Entry 2: CustomExitCheck    — copies exit data to wCustomExitBuffer
;   Entry 3: CustomTilesetInfo  — returns source mapID from wCustomRoomFlag
;   Entry 4: CustomScriptRead   — triple-index script data reader
;   Entry 5: CustomTextDisplay  — custom text renderer via ROM0 CallTextEngine
; =============================================================================

SECTION "ROM Bank $060", ROMX[$4000], BANK[$60]
    db $60 ; bank number

    dw CustomReadStep       ; Entry 0
    dw CustomReadInteract   ; Entry 1
    dw CustomExitCheck      ; Entry 2
    dw CustomTilesetInfo    ; Entry 3
    dw CustomScriptRead     ; Entry 4
    dw CustomTextDisplay    ; Entry 5

; =============================================================================
; CustomPtrChase
; =============================================================================
CustomPtrChase:
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
    ld hl, CustomRoomPtrTable
    ld a, [wMapID]
    sub CUSTOM_ROOM_START
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, [wScreenIndex]
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, h
    and l
    cp $FF
    jr nz, .validScreen
    ld hl, DummyStepEntry
    ret
.validScreen:
    inc hl
    inc hl
    ret

DummyStepEntry:
    db 1, $2A
    dw DummyNPCs
    dw DummyExits
DummyNPCs:
    db $FF
DummyExits:
    db $03, $07, $01, $00, $80, $04, $04
    db $05, $07, $01, $00, $80, $04, $04
    db $07, $07, $01, $00, $80, $04, $04
    db $03, $00, $01, $00, $80, $04, $04
    db $05, $00, $01, $00, $80, $04, $04
    db $FF

; =============================================================================
; Entry 0-3: Room data readers (proven, unchanged)
; =============================================================================
CustomReadStep:
    call CustomPtrChase
    ld e, [hl]
    inc hl
    ld d, [hl]
    ret

CustomReadInteract:
    call CustomPtrChase
    inc hl
    inc hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld de, wCustomNPCBuffer
.copyNPC:
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
    jr .copyNPC
.npcDone:
    ld a, $FF
    ld [de], a
    ld hl, wCustomNPCBuffer
    ret

CustomExitCheck:
    call CustomPtrChase
    inc hl
    inc hl
    inc hl
    inc hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld de, wCustomExitBuffer
.copyExit:
    ld a, [hl]
    cp $FF
    jr z, .exitDone
    ld b, $07
.copyByte:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, .copyByte
    jr .copyExit
.exitDone:
    ld a, $FF
    ld [de], a
    ld hl, wCustomExitBuffer
    ret

CustomTilesetInfo:
    ld a, [wCustomRoomFlag]
    ret

; =============================================================================
; Entry 4: CustomScriptRead
; =============================================================================
CustomScriptRead:
    ld a, [wScriptMapType]
    sub CUSTOM_ROOM_START
    ld l, a
    ld h, $00
    add hl, hl
    ld de, CustomScriptMasterTable
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]

    ld a, [wScriptNPCId]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]

    ld a, [wScriptCounter]
    ld l, a
    ld a, [$d8d6]
    ld h, a
    add hl, hl
    add hl, de
    ld c, [hl]
    inc hl
    ld b, [hl]
    dec hl
    ret

; =============================================================================
; Entry 5: CustomTextDisplay
; =============================================================================
CustomTextDisplay:
    ld de, CustomTextPtrTable
    call CallTextEngine
    ret

; =============================================================================
; SCRIPT DATA
; =============================================================================
; CRITICAL: Index 0 = room entry script (runs on every screen enter/scroll).
;           NPC scripts start at index 1+.
;           NPC data byte 4 (script_id) must match.
; =============================================================================

CustomScriptMasterTable:
    dw CustomRoom0_ScriptPtrTable   ; mapID $6B
    dw CustomRoom1_ScriptPtrTable   ; mapID $6C

; --- Room 0 ($6B) scripts ---
CustomRoom0_ScriptPtrTable:
    dw CustomRoom0_RoomEntry        ; [0] room entry
    dw CustomRoom0_NPC00            ; [1] MedalMan NPC — gives item

CustomRoom0_RoomEntry:
    dw $FFFF

CustomRoom0_NPC00:
    dw $0A00                        ; "Want a Beef Jerky?" [Y/N]
    dw $FF15                        ; CheckAndBranch
    dw $C83C                        ; check choice result
    dw $0001                        ; compare to 1 (NO)
    dw .declined                    ; branch if NO
    dw $FF2C                        ; check_inv_full
    dw .invFull                     ; branch if inventory full
    dw $FF2A                        ; GiveItem (first empty slot)
    dw ITEM_BEEF_JERKY
    dw $0A01                        ; "Received BeefJerky!"
    dw $FFFF
.invFull:
    dw $0A06                        ; "Inventory is full!"
    dw $FFFF
.declined:
    dw $0A02                        ; "Maybe next time."
    dw $FFFF

; --- Room 1 ($6C) scripts ---
CustomRoom1_ScriptPtrTable:
    dw CustomRoom1_RoomEntry        ; [0] room entry
    dw CustomRoom1_NPC00            ; [1] throne room NPC — YES/NO demo

CustomRoom1_RoomEntry:
    dw $FFFF

CustomRoom1_NPC00:
    dw $0A03                        ; "Is this your first time here?" [Y/N]
    dw $FF15                        ; CheckAndBranch
    dw $C83C                        ; check choice result
    dw $0001                        ; compare to 1 (NO)
    dw .noAnswer                    ; branch if NO
    dw $0A04                        ; YES → "Welcome to this castle!"
    dw $FFFF
.noAnswer:
    dw $0A05                        ; NO → "Good to see you again."
    dw $FFFF

; =============================================================================
; TEXT DATA — Two-level pointer table
; =============================================================================
CustomTextPtrTable:
    dw CustomTextSection0

CustomTextSection0:
    dw CustomText_00                ; $0A00: item offer [Y/N]
    dw CustomText_01                ; $0A01: item given
    dw CustomText_02                ; $0A02: declined
    dw CustomText_03                ; $0A03: castle question [Y/N]
    dw CustomText_04                ; $0A04: castle YES
    dw CustomText_05                ; $0A05: castle NO
    dw CustomText_06                ; $0A06: inventory full

; Room $6B NPC texts
CustomText_00:
    db $EA, $9F, $A3
    db "Want a", $EF, $EE
    db "Beef Jerky?", $EF, $EE
    db $E7, $F0

CustomText_01:
    db $EA, $9F, $A3
    db "Received", $EF, $EE
    db "BeefJerky!", $F7, $F0

CustomText_02:
    db $EA, $9F, $A3
    db "Maybe next time.", $F7, $F0

; Room $6C NPC texts
CustomText_03:
    db $EA, $9F, $A3
    db "Is this your", $EF, $EE
    db "first time here?", $EF, $EE
    db $E7, $F0

CustomText_04:
    db $EA, $9F, $A3
    db "Welcome to this", $EF, $EE
    db "castle!", $F7, $F0

CustomText_05:
    db $EA, $9F, $A3
    db "Good to see", $EF, $EE
    db "you again.", $F7, $F0

CustomText_06:
    db $EA, $9F, $A3
    db "Your inventory", $EF, $EE
    db "is full!", $F7, $F0

; =============================================================================
; ROOM DATA — Restored from proven patches
; =============================================================================
CustomSourceMapTable:
    db $16                      ; Room 0 ($6B) → MedalMan
    db $00                      ; Room 1 ($6C) → Castle

CustomRoomPtrTable:
    dw CustomRoom0_SubTable
    dw CustomRoom1_SubTable

; =============================================
; Room 0 (mapID $6B) — MedalMan single-screen
; =============================================
CustomRoom0_SubTable:
    dw CustomRoom0_Screen0
    dw $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF

CustomRoom0_Screen0:
    dw $D95E
    db 13, $30
    dw CustomRoom0_NPCs
    dw CustomRoom0_Exits

CustomRoom0_NPCs:
    db $8F, $FF, $02, $06, $01     ; spawn point
    db $00, $0B, $02, $02, $01     ; NPC at (2,2), script_id=1 (not 0!)
    db $FF

CustomRoom0_Exits:
    db $03, $07, $01, $00, $08, $04, $05
    db $03, $01, $6C, $00, $01, $05, $07
    db $FF

; =============================================
; Room 1 (mapID $6C) — Castle 3-screen clone
; =============================================
CustomRoom1_SubTable:
    dw CustomRoom1_Screen0
    dw CustomRoom1_Screen1
    dw $FFFF
    dw $FFFF
    dw $FFFF
    dw CustomRoom1_Screen5
    dw $FFFF
    dw $FFFF

CustomRoom1_Screen0:
    dw $D9A0
    db 1, $2A
    dw CustomRoom1_S0_NPCs
    dw CustomRoom1_S0_Exits

CustomRoom1_S0_NPCs:
    db $8F, $FF, $09, $04, $01     ; spawn (from screen 1)
    db $00, $0B, $05, $02, $01     ; NPC at (5,2), script_id=1 (not 0!)
    db $FF

CustomRoom1_S0_Exits:
    db $FF

CustomRoom1_Screen1:
    dw $D9A1
    db 5, $2A
    dw CustomRoom1_S1_NPCs
    dw CustomRoom1_S1_Exits

CustomRoom1_S1_NPCs:
    db $8F, $FF, $05, $07, $6B     ; spawn (from MedalMan room)
    db $FF

CustomRoom1_S1_Exits:
    db $07, $01, $01, $00, $80, $04, $04
    db $FF

CustomRoom1_Screen5:
    dw $D9A2
    db 7, $2A
    dw CustomRoom1_S5_NPCs
    dw CustomRoom1_S5_Exits

CustomRoom1_S5_NPCs:
    db $8F, $FF, $04, $02, $01     ; spawn point
    db $FF

CustomRoom1_S5_Exits:
    ; Bottom exits → GreatTree
    db $04, $07, $01, $00, $80, $04, $04  ; left door
    db $05, $07, $01, $00, $80, $05, $04  ; right door (fixed dest X)
    db $FF
