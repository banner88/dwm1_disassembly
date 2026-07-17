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
;   Entry 6: GateAwareDispatch  — B-fix: bank-$0F script dispatch routed by wMapID
; =============================================================================

SECTION "ROM Bank $060", ROMX[$4000], BANK[$60]
    db $60 ; bank number

    dw CustomReadStep       ; Entry 0
    dw CustomReadInteract   ; Entry 1
    dw CustomExitCheck      ; Entry 2
    dw CustomTilesetInfo    ; Entry 3
    dw CustomScriptRead     ; Entry 4
    dw CustomTextDisplay    ; Entry 5
    dw GateAwareDispatch    ; Entry 6 — gate-entry regression fix (B-fix): route by wMapID

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
    ; Read RAM step counter and index into step entries
    ; (matches original ReadStepBlock logic in bank $0B)
    ld e, [hl]
    inc hl
    ld d, [hl]           ; DE = RAM counter address
    inc hl                ; HL = first step entry
    ld a, [de]            ; A = current step counter value
    ; step_value × 6 (each step entry is 6 bytes)
    ld e, a
    add a                 ; ×2
    add e                 ; ×3
    add a                 ; ×6
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a               ; HL = &step_entries[step_value]
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
; Entry 6: GateAwareDispatch  — gate-entry regression fix (B-fix)
; =============================================================================
; Reached from bank $04 DispatchBank0F (script bank dispatch, wScriptMapType >= $40).
; The original bank-$04 hook tested the SCRIPT map-type against $6B to decide a
; custom-room divert, but wScriptMapType >= $6B is legitimate bank-$0F territory
; (gate world hardcodes $70; labyrinth/arena/post-game use $40-$6A). That froze
; gate entry (gate script wrongly read from bank $60) and looped for $40-$6A.
;
; The correct test is the ROOM map-type wMapID ($C968): custom rooms are the ONLY
; things with wMapID >= CUSTOM_ROOM_START ($6B). Everything else (gates, labyrinth,
; all vanilla rooms) dispatches to the real bank $0F entry 0, exactly like vanilla.
; Returns next script command in BC (both paths preserve the vanilla contract).
GateAwareDispatch:
    ld a, [wMapID]              ; $C968 — the actual room map-type
    cp CUSTOM_ROOM_START        ; $6B
    jr nc, .customRoom          ; wMapID >= $6B → genuine custom room
    ld hl, $0f00                ; else: bank $0F entry 0 — vanilla gate/script dispatch
    rst $10
    ret
.customRoom:
    jp CustomScriptRead         ; bank $60 entry 4 logic (same bank); returns BC

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
; SCRIPT DATA (generated by build_project.py)
; CRITICAL: Index 0 = room entry script (runs on scroll/reload).
;           NPC scripts start at index 1+ (KEY_LESSONS Session 2).
; Master table width == compat list (legacy) or ALL rooms (default;
; fixes the S53 master-table overshoot for scroll in rooms >= index
; len(master)).  See PROJECT_COMPILER.md §scripts.
; =============================================================================
CustomScriptMasterTable:
    dw CustomRoom0_ScriptPtrTable   ; mapID $6B
    dw CustomRoom1_ScriptPtrTable   ; mapID $6C
    dw CustomRoom2_ScriptPtrTable   ; mapID $6D

; --- $6B (gate_island) scripts ---
CustomRoom0_ScriptPtrTable:
    dw CustomRoom0_Scr00   ; [0] arm_encounters
    dw CustomRoom0_Scr01   ; [1] give_jerky
    dw CustomRoom0_Scr02   ; [2] give_egg
    dw CustomRoom0_Scr03   ; [3] bgm_change

CustomRoom0_Scr00:
    dw $FF12  ; write_ram
    dw $CA39
    dw $0064
    dw $FF12  ; write_ram
    dw $CA3A
    dw $0000
    dw $FFFF

CustomRoom0_Scr01:
    dw $0A00  ; item offer [Y/N]
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom0_Scr01_declined
    dw $FF2C  ; check_inv_full
    dw CustomRoom0_Scr01_invFull
    dw $FF2A  ; give_item
    dw ITEM_BEEF_JERKY
    dw $0A01  ; item given
    dw $FFFF
CustomRoom0_Scr01_invFull:
    dw $0A06  ; inventory full
    dw $FFFF
CustomRoom0_Scr01_declined:
    dw $0A02  ; declined
    dw $FFFF

CustomRoom0_Scr02:
    dw $0A07  ; monster offer [Y/N]
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom0_Scr02_declined
    dw $FF28  ; check_storage_full
    dw CustomRoom0_Scr02_storageFull
    dw $FF29  ; add_monster
    dw $015E
    dw $0A08  ; monster joined
    dw $FFFF
CustomRoom0_Scr02_storageFull:
    dw $0A10  ; monster storage full
    dw $FFFF
CustomRoom0_Scr02_declined:
    dw $0A09  ; monster declined
    dw $FFFF

CustomRoom0_Scr03:
    dw $0A0D  ; BGM change offer [Y/N]
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom0_Scr03_declined
    dw $FF41  ; set_bgm
    dw $009E
    dw $0A0E  ; BGM changed
    dw $FFFF
CustomRoom0_Scr03_declined:
    dw $0A0F  ; BGM declined
    dw $FFFF

; --- $6C (dusk_mirror) scripts ---
CustomRoom1_ScriptPtrTable:
    dw CustomRoom1_Scr00   ; [0] arm_encounters
    dw CustomRoom1_Scr01   ; [1] first_time_q
    dw CustomRoom1_Scr02   ; [2] teleport_castle
    dw CustomRoom1_Scr03   ; [3] teleport_6b
    dw CustomRoom1_Scr04   ; [4] gate_open
    dw CustomRoom1_Scr05   ; [5] guard_greet
    dw CustomRoom1_Scr06   ; [6] bgm07_change

CustomRoom1_Scr00:
    dw $FF12  ; write_ram
    dw $CA39
    dw $0064
    dw $FF12  ; write_ram
    dw $CA3A
    dw $0000
    dw $FFFF

CustomRoom1_Scr01:
    dw $0A03  ; castle question [Y/N]
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom1_Scr01_noAnswer
    dw $0A04  ; castle YES
    dw $FFFF
CustomRoom1_Scr01_noAnswer:
    dw $0A05  ; castle NO
    dw $FFFF

CustomRoom1_Scr02:
    dw $0A0A  ; teleport Castle [Y/N]
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom1_Scr02_declined
    dw $FF0F  ; map_transition
    dw $0000
    dw $00E8
    dw $0078
    dw $FFFF
CustomRoom1_Scr02_declined:
    dw $0A0B  ; teleport declined
    dw $FFFF

CustomRoom1_Scr03:
    dw $0A0C  ; teleport MedalMan [Y/N]
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom1_Scr03_declined
    dw $FF0F  ; map_transition
    dw $006B
    dw $0078
    dw $0068
    dw $FFFF
CustomRoom1_Scr03_declined:
    dw $0A0B  ; teleport declined
    dw $FFFF

CustomRoom1_Scr04:
    dw $0A11  ; gatekeeper offer [Y/N]
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom1_Scr04_declined
    dw $FF12  ; write_ram
    dw wCustomStep_Room6C_S0
    dw $0001
    dw $0A12  ; gate opened
    dw $FFFF
CustomRoom1_Scr04_declined:
    dw $0A13  ; gate declined
    dw $FFFF

CustomRoom1_Scr05:
    dw $0A14  ; guard greeting (post-step)
    dw $FFFF

CustomRoom1_Scr06:
    dw $0A15  ; v5 BGM #07 offer [Y/N]
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom1_Scr06_declined
    dw $FF41  ; set_bgm
    dw $00A1
    dw $0A16  ; v5 BGM #07 set
    dw $FFFF
CustomRoom1_Scr06_declined:
    dw $0A17  ; v5 BGM #07 declined
    dw $FFFF

; --- $70 (ember_keystone) scripts ---
CustomRoom5_ScriptPtrTable:

; =============================================================================
; TEXT DATA — two-level pointer table (generated)
; SaveBankAndSwitch ($00:$0940) indexes table[$C822*2] -> section,
; section[$C823*2] -> string (TEXT_SYSTEM.md). Flat tables crash.
; Custom ids $0A00+: section = hi-$0A, entry = lo
; (bank $04 TextQueueCheck_Ext).
; =============================================================================
CustomTextPtrTable:
    dw CustomTextSection0

CustomTextSection0:
    dw CustomText_00   ; $0A00: item offer [Y/N]
    dw CustomText_01   ; $0A01: item given
    dw CustomText_02   ; $0A02: declined
    dw CustomText_03   ; $0A03: castle question [Y/N]
    dw CustomText_04   ; $0A04: castle YES
    dw CustomText_05   ; $0A05: castle NO
    dw CustomText_06   ; $0A06: inventory full
    dw CustomText_07   ; $0A07: monster offer [Y/N]
    dw CustomText_08   ; $0A08: monster joined
    dw CustomText_09   ; $0A09: monster declined
    dw CustomText_0A   ; $0A0A: teleport Castle [Y/N]
    dw CustomText_0B   ; $0A0B: teleport declined
    dw CustomText_0C   ; $0A0C: teleport MedalMan [Y/N]
    dw CustomText_0D   ; $0A0D: BGM change offer [Y/N]
    dw CustomText_0E   ; $0A0E: BGM changed
    dw CustomText_0F   ; $0A0F: BGM declined
    dw CustomText_10   ; $0A10: monster storage full
    dw CustomText_11   ; $0A11: gatekeeper offer [Y/N]
    dw CustomText_12   ; $0A12: gate opened
    dw CustomText_13   ; $0A13: gate declined
    dw CustomText_14   ; $0A14: guard greeting (post-step)
    dw CustomText_15   ; $0A15: v5 BGM #07 offer [Y/N]
    dw CustomText_16   ; $0A16: v5 BGM #07 set
    dw CustomText_17   ; $0A17: v5 BGM #07 declined

; $0A00 — item offer [Y/N]
CustomText_00:
    db $EA, $9F, $A3
    db "Want a", $EF, $EE
    db "Beef Jerky?", $EF, $EE, $E7, $F0

; $0A01 — item given
CustomText_01:
    db $EA, $9F, $A3
    db "Received", $EF, $EE
    db "BeefJerky!", $F7, $F0

; $0A02 — declined
CustomText_02:
    db $EA, $9F, $A3
    db "Maybe next time.", $F7, $F0

; $0A03 — castle question [Y/N]
CustomText_03:
    db $EA, $9F, $A3
    db "Is this your", $EF, $EE
    db "first time here?", $EF, $EE, $E7, $F0

; $0A04 — castle YES
CustomText_04:
    db $EA, $9F, $A3
    db "Welcome to this", $EF, $EE
    db "castle!", $F7, $F0

; $0A05 — castle NO
CustomText_05:
    db $EA, $9F, $A3
    db "Good to see", $EF, $EE
    db "you again.", $F7, $F0

; $0A06 — inventory full
CustomText_06:
    db $EA, $9F, $A3
    db "Your inventory", $EF, $EE
    db "is full!", $F7, $F0

; $0A07 — monster offer [Y/N]
CustomText_07:
    db $EA, $9F, $A3
    db "Want a SkyDragon", $EF, $EE
    db "egg?", $EF, $EE, $E7, $F0

; $0A08 — monster joined
CustomText_08:
    db $EA, $9F, $A3
    db "Got a SkyDragon", $EF, $EE
    db "egg!", $F7, $F0

; $0A09 — monster declined
CustomText_09:
    db $EA, $9F, $A3
    db "Maybe another", $EF, $EE
    db "time then.", $F7, $F0

; $0A0A — teleport Castle [Y/N]
CustomText_0A:
    db $EA, $9F, $A3
    db "Teleport to", $EF, $EE
    db "the Castle?", $EF, $EE, $E7, $F0

; $0A0B — teleport declined
CustomText_0B:
    db $EA, $9F, $A3
    db "Changed your", $EF, $EE
    db "mind.", $F7, $F0

; $0A0C — teleport MedalMan [Y/N]
CustomText_0C:
    db $EA, $9F, $A3
    db "Teleport to", $EF, $EE
    db "MedalMan room?", $EF, $EE, $E7, $F0

; $0A0D — BGM change offer [Y/N]
CustomText_0D:
    db $EA, $9F, $A3
    db "Change the", $EF, $EE
    db "music?", $EF, $EE, $E7, $F0

; $0A0E — BGM changed
CustomText_0E:
    db $EA, $9F, $A3
    db "Now playing", $EF, $EE
    db "DWM2 music!", $F7, $F0

; $0A0F — BGM declined
CustomText_0F:
    db $EA, $9F, $A3
    db "Keeping current", $EF, $EE
    db "music.", $F7, $F0

; $0A10 — monster storage full
CustomText_10:
    db $EA, $9F, $A3
    db "Monster storage", $EF, $EE
    db "is full!", $F7, $F0

; $0A11 — gatekeeper offer [Y/N]
CustomText_11:
    db $EA, $9F, $A3
    db "Open the gate?", $EF, $EE
    db "NPCs will change!", $EF, $EE, $E7, $F0

; $0A12 — gate opened
CustomText_12:
    db $EA, $9F, $A3
    db "Gate opened!", $EF, $EE
    db "Leave and return", $EF, $EE
    db "to see the change.", $F7, $F0

; $0A13 — gate declined
CustomText_13:
    db $EA, $9F, $A3
    db "The gate stays", $EF, $EE
    db "closed for now.", $F7, $F0

; $0A14 — guard greeting (post-step)
CustomText_14:
    db $EA, $9F, $A3
    db "The gate has been", $EF, $EE
    db "opened! I replaced", $EF, $EE
    db "the Gatekeeper.", $F7, $F0

; $0A15 — v5 BGM #07 offer [Y/N]
CustomText_15:
    db $EA, $9F, $A3
    db "Hear a", $EF, $EE
    db "second song?", $EF, $EE, $E7, $F0

; $0A16 — v5 BGM #07 set
CustomText_16:
    db $EA, $9F, $A3
    db "Now playing", $EF, $EE
    db "DWM2 song 2!", $F7, $F0

; $0A17 — v5 BGM #07 declined
CustomText_17:
    db $EA, $9F, $A3
    db "Keeping current", $EF, $EE
    db "music.", $F7, $F0

; =============================================================================
; ROOM DATA (generated)
; =============================================================================
CustomSourceMapTable:
    db $04   ; $6B — gate_island
    db $04   ; $6C — dusk_mirror
    db $04   ; $6D — gate_rotation
    db $04   ; $6E — reserved_6e
    db $04   ; $6F — reserved_6f
    db $04   ; $70 — ember_keystone

CustomRoomPtrTable:
    dw CustomRoom0_SubTable   ; $6B
    dw CustomRoom1_SubTable   ; $6C
    dw CustomRoom2_SubTable   ; $6D
    dw CustomRoomDummy_SubTable   ; $6E
    dw CustomRoomDummy_SubTable   ; $6F
    dw CustomRoom5_SubTable   ; $70

; --- $6B (gate_island) room data ---
CustomRoom0_SubTable:
    dw CustomRoom0_Screen0
    dw $FFFF, $FFFF, $FFFF
    dw CustomRoom0_Screen4
    dw $FFFF, $FFFF, $FFFF

CustomRoom0_Screen0:
    dw wCustomStep_Room6B_S0    ; step counter
    db 0, $64   ; step_id, tileset_bank
    dw CustomRoom0_S0_NPCs
    dw CustomRoom0_S0_Exits

CustomRoom0_S0_NPCs:
    db $8F, $FF, $07, $06, $00  ; spawn (7,6)
    db $00, $0B, $02, $07, $01  ; NPC (2,7) script give_jerky
    db $00, $0B, $05, $06, $03  ; NPC (5,6) script bgm_change
    db $FF

CustomRoom0_S0_Exits:
    db $03, $01, $6C, $00, $00, $07, $06  ; exit (3,1) -> Room $6C screen 0 spawn (7,6); screen_byte $00 = in-room ($2DE7[0]); $01 stranded the player off-map (KEY_LESSONS S40)
    db $FF

CustomRoom0_Screen4:
    dw wCustomStep_Room6B_S4    ; step counter
    db 2, $64   ; step_id, tileset_bank
    dw CustomRoom0_S4_NPCs
    dw CustomRoom0_S4_Exits

CustomRoom0_S4_NPCs:
    db $8F, $FF, $05, $03, $00  ; spawn (5,3)
    db $00, $09, $05, $04, $02  ; NPC (5,4) script give_egg
    db $FF

CustomRoom0_S4_Exits:
    db $03, $07, $01, $00, $08, $04, $05  ; south edge exit (3,7) -> GreatTree screen 8 (screen_byte $08 copied from WellStairway per KEY_LESSONS v14-v18)
    db $FF

; --- $6C (dusk_mirror) room data ---
CustomRoom1_SubTable:
    dw CustomRoom1_Screen0
    dw $FFFF, $FFFF, $FFFF
    dw CustomRoom1_Screen4
    dw $FFFF, $FFFF, $FFFF

CustomRoom1_Screen0:
    dw wCustomStep_Room6C_S0    ; step counter
    db 0, $64   ; step_id, tileset_bank
    dw CustomRoom1_S0_NPCs
    dw CustomRoom1_S0_Exits

CustomRoom1_S0_NPCs:
    db $8F, $FF, $07, $06, $00  ; spawn (7,6)
    db $00, $09, $05, $04, $03  ; NPC (5,4) script teleport_6b
    db $00, $09, $05, $06, $06  ; NPC (5,6) script bgm07_change
    db $FF

CustomRoom1_S0_Exits:
    db $03, $01, $70, $00, $00, $07, $06  ; edge exit (3,1) -> Room $70 spawn (7,6) (NPC script still offers a return to $6B)
    db $FF

CustomRoom1_Screen4:
    dw wCustomStep_Room6C_S4    ; step counter
    db 2, $64   ; step_id, tileset_bank
    dw CustomRoom1_S4_NPCs
    dw CustomRoom1_S4_Exits

CustomRoom1_S4_NPCs:
    db $8F, $FF, $05, $03, $00  ; spawn (5,3)
    db $FF

CustomRoom1_S4_Exits:
    db $FF

; --- $6D (gate_rotation) scripts ---
CustomRoom2_ScriptPtrTable:
    dw CustomRoom2_Scr00   ; [0] noop_entry

CustomRoom2_Scr00:
    dw $FFFF

; --- $6D (gate_rotation) room data ---
CustomRoom2_SubTable:
    dw CustomRoom2_Screen0
    dw $FFFF, $FFFF, $FFFF

CustomRoom2_Screen0:
    dw wCustomStep_Room6D_S0    ; step counter
    db 0, $64   ; step_id, tileset_bank
    dw CustomRoom2_S0_NPCs
    dw CustomRoom2_S0_Exits

CustomRoom2_S0_NPCs:
    db $8F, $FF, $04, $06, $00  ; spawn (4,6) — matches wWarpSpawn $0048/$0068 (central sand)
    db $FF

CustomRoom2_S0_Exits:
    db $05, $03, $00, $80, $00, $00, $00  ; descent: PIT walk (col5,row3), gate_flag=$80 -> next gate floor (Pillar B; byte-identical to special rooms $50/$51)
    db $FF

; =============================================================================
; Dummy subtable — placeholder mapIDs (never entered; all screens invalid)
; =============================================================================
CustomRoomDummy_SubTable:
    dw $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF

; --- $70 (ember_keystone) room data ---
CustomRoom5_SubTable:
    dw CustomRoom5_Screen0
    dw $FFFF, $FFFF, $FFFF

CustomRoom5_Screen0:
    dw wCustomStep_Room70_S0    ; step counter
    db 0, $64   ; step_id, tileset_bank
    dw CustomRoom5_S0_NPCs
    dw CustomRoom5_S0_Exits

CustomRoom5_S0_NPCs:
    db $8F, $FF, $07, $06, $00  ; spawn (7,6)
    db $FF

CustomRoom5_S0_Exits:
    db $03, $01, $6B, $00, $00, $07, $06  ; edge exit (3,1) -> Room $6B spawn (7,6) — close the loop
    db $FF

