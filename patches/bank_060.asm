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
; SCRIPT DATA
; =============================================================================
; CRITICAL: Index 0 = room entry script (runs on every screen enter/scroll).
;           NPC scripts start at index 1+.
;           NPC data byte 4 (script_id) must match.
; =============================================================================

CustomScriptMasterTable:
    dw CustomRoom0_ScriptPtrTable   ; mapID $6B
    dw CustomRoom1_ScriptPtrTable   ; mapID $6C
    dw CustomRoom2_ScriptPtrTable   ; mapID $6D (Pillar B gate-rotation room)

; --- Room 0 ($6B) scripts ---
CustomRoom0_ScriptPtrTable:
    dw CustomRoom0_RoomEntry        ; [0] room entry
    dw CustomRoom0_NPC00            ; [1] MedalMan NPC — gives item
    dw CustomRoom0_NPC01            ; [2] Monster NPC — gives Slime
    dw CustomRoom0_NPC02            ; [3] BGM NPC — changes music

CustomRoom0_RoomEntry:
    ; Arms the random-encounter step counter on room load / post-battle reload.
    ; (gate ID / floor are pinned in ASM every step — see Seed6BEncounterPool in
    ; bank_00b — because the room-entry script runs only on scroll/reload, not
    ; reliably at initial entry.)  write_ram writes the LOW byte of the value.
    dw $FF12                        ; write_ram
    dw $CA39                        ; wEncounterCounterLo = $64
    dw $0064
    dw $FF12                        ; write_ram
    dw $CA3A                        ; wEncounterCounterHi = $00  → counter = 100 (~4-5 steps)
    dw $0000
    dw $FFFF                        ; end of room-entry script

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

; --- Room 0 ($6B) NPC 2: gives a Slime (AddMonster opcode $29) ---
CustomRoom0_NPC01:
    dw $0A07                        ; "Want a SkyDragon egg?" [Y/N]
    dw $FF15                        ; CheckAndBranch
    dw $C83C                        ; check choice result
    dw $0001                        ; compare to 1 (NO)
    dw .declined                    ; branch if NO
    dw $FF28                        ; CheckStorageFull
    dw .storageFull                 ; branch if all 20 slots full
    dw $FF29                        ; AddMonster (creates egg in storage)
    dw $015E                        ; enemy_stats_id = 350 (SkyDragon — same as Farm event)
    dw $0A08                        ; "Got a SkyDragon egg!"
    dw $FFFF
.storageFull:
    dw $0A10                        ; "Monster storage is full!"
    dw $FFFF
.declined:
    dw $0A09                        ; "Maybe another time."
    dw $FFFF

; --- Room 0 ($6B) NPC 3: BGM change (SetBGM opcode $41) ---
CustomRoom0_NPC02:
    dw $0A0D                        ; "Change the music?" [Y/N]
    dw $FF15                        ; CheckAndBranch
    dw $C83C                        ; check choice result
    dw $0001                        ; compare to 1 (NO)
    dw .declined                    ; branch if NO
    dw $FF41                        ; SetBGM (opcode $41)
    dw $001E                        ; track $1E = Arena music
    dw $0A0E                        ; "Now playing Arena music!"
    dw $FFFF
.declined:
    dw $0A0F                        ; "Keeping current music."
    dw $FFFF

; --- Room 1 ($6C) scripts ---
CustomRoom1_ScriptPtrTable:
    dw CustomRoom1_RoomEntry        ; [0] room entry
    dw CustomRoom1_NPC00            ; [1] throne room NPC — YES/NO demo
    dw CustomRoom1_NPC01            ; [2] teleport to Castle (vanilla)
    dw CustomRoom1_NPC02            ; [3] teleport to MedalMan room (custom $6B)
    dw CustomRoom1_NPC03            ; [4] Gatekeeper — advances step counter
    dw CustomRoom1_NPC04            ; [5] Guard — post-step greeting

CustomRoom1_RoomEntry:
    ; Mirror $6B: arm the random-encounter step counter on room load so the
    ; entry leaves the player in the same movement/encounter state $6B does
    ; (the no-op version left this unset, the one behavioral gap vs $6B).
    dw $FF12                        ; write_ram
    dw $CA39                        ; wEncounterCounterLo = $64
    dw $0064
    dw $FF12                        ; write_ram
    dw $CA3A                        ; wEncounterCounterHi = $00  → counter = 100
    dw $0000
    dw $FFFF                        ; end of room-entry script

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

; --- Room 1 ($6C) NPC 2: teleport to Castle (opcode $0F test — vanilla) ---
CustomRoom1_NPC01:
    dw $0A0A                        ; "Teleport to Castle?" [Y/N]
    dw $FF15                        ; CheckAndBranch
    dw $C83C                        ; check choice result
    dw $0001                        ; compare to 1 (NO)
    dw .declined                    ; branch if NO
    dw $FF0F                        ; MapTransitionFull (opcode $0F)
    dw $0000                        ; gate_id=$00 (Castle), flag=$00
    dw $00E8                        ; spawn X = 232 pixels
    dw $0078                        ; spawn Y = 120 pixels
    dw $FFFF                        ; (transition fires before this)
.declined:
    dw $0A0B                        ; "Changed your mind."
    dw $FFFF

; --- Room 1 ($6C) NPC 3: teleport to custom room $6B (opcode $0F — custom) ---
CustomRoom1_NPC02:
    dw $0A0C                        ; "Teleport to MedalMan room?" [Y/N]
    dw $FF15                        ; CheckAndBranch
    dw $C83C                        ; check choice result
    dw $0001                        ; compare to 1 (NO)
    dw .declined                    ; branch if NO
    dw $FF0F                        ; MapTransitionFull (opcode $0F)
    dw $006B                        ; gate_id=$6B (custom room), flag=$00
    dw $0078                        ; spawn X = 120 pixels (grid 7)
    dw $0068                        ; spawn Y = 104 pixels (grid 6)
    dw $FFFF
.declined:
    dw $0A0B                        ; "Changed your mind." (reuse)
    dw $FFFF

; --- Room 1 ($6C) NPC 4: Gatekeeper — advances step counter (step system demo) ---
CustomRoom1_NPC03:
    dw $0A11                        ; "Open the gate?" [Y/N]
    dw $FF15                        ; CheckAndBranch
    dw $C83C                        ; check choice result
    dw $0001                        ; compare to 1 (NO)
    dw .declined                    ; branch if NO
    dw $FF12                        ; WriteRAM (opcode $12)
    dw wCustomStep_Room6C_S0        ; target = Room $6C screen 0 step counter
    dw $0001                        ; set value = 1
    dw $0A12                        ; "Gate opened! Leave and return."
    dw $FFFF
.declined:
    dw $0A13                        ; "Gate stays closed."
    dw $FFFF

; --- Room 1 ($6C) NPC 5: Guard — appears at step 1 (proves step system) ---
CustomRoom1_NPC04:
    dw $0A14                        ; "The gate has been opened!"
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
    dw CustomText_07                ; $0A07: monster offer [Y/N]
    dw CustomText_08                ; $0A08: monster joined
    dw CustomText_09                ; $0A09: monster declined
    dw CustomText_0A                ; $0A0A: teleport Castle [Y/N]
    dw CustomText_0B                ; $0A0B: teleport declined
    dw CustomText_0C                ; $0A0C: teleport MedalMan [Y/N]
    dw CustomText_0D                ; $0A0D: BGM change offer [Y/N]
    dw CustomText_0E                ; $0A0E: BGM changed
    dw CustomText_0F                ; $0A0F: BGM declined
    dw CustomText_10                ; $0A10: monster storage full
    dw CustomText_11                ; $0A11: gatekeeper offer [Y/N]
    dw CustomText_12                ; $0A12: gate opened
    dw CustomText_13                ; $0A13: gate declined
    dw CustomText_14                ; $0A14: guard greeting (post-step)

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

; Monster NPC texts (Room $6B NPC 2)
CustomText_07:
    db $EA, $9F, $A3
    db "Want a SkyDragon", $EF, $EE
    db "egg?", $EF, $EE
    db $E7, $F0

CustomText_08:
    db $EA, $9F, $A3
    db "Got a SkyDragon", $EF, $EE
    db "egg!", $F7, $F0

CustomText_09:
    db $EA, $9F, $A3
    db "Maybe another", $EF, $EE
    db "time then.", $F7, $F0

; Teleport NPC texts (Room $6C NPCs 2-3)
CustomText_0A:
    db $EA, $9F, $A3
    db "Teleport to", $EF, $EE
    db "the Castle?", $EF, $EE
    db $E7, $F0

CustomText_0B:
    db $EA, $9F, $A3
    db "Changed your", $EF, $EE
    db "mind.", $F7, $F0

CustomText_0C:
    db $EA, $9F, $A3
    db "Teleport to", $EF, $EE
    db "MedalMan room?", $EF, $EE
    db $E7, $F0

; BGM NPC texts (Room $6B NPC 3)
CustomText_0D:
    db $EA, $9F, $A3
    db "Change the", $EF, $EE
    db "music?", $EF, $EE
    db $E7, $F0

CustomText_0E:
    db $EA, $9F, $A3
    db "Now playing", $EF, $EE
    db "Arena music!", $F7, $F0

CustomText_0F:
    db $EA, $9F, $A3
    db "Keeping current", $EF, $EE
    db "music.", $F7, $F0

CustomText_10:
    db $EA, $9F, $A3
    db "Monster storage", $EF, $EE
    db "is full!", $F7, $F0

; Step system demo texts (Room $6C Gatekeeper/Guard)
CustomText_11:
    db $EA, $9F, $A3
    db "Open the gate?", $EF, $EE
    db "NPCs will change!", $EF, $EE
    db $E7, $F0

CustomText_12:
    db $EA, $9F, $A3
    db "Gate opened!", $EF, $EE
    db "Leave and return", $EF, $EE
    db "to see the change.", $F7, $F0

CustomText_13:
    db $EA, $9F, $A3
    db "The gate stays", $EF, $EE
    db "closed for now.", $F7, $F0

CustomText_14:
    db $EA, $9F, $A3
    db "The gate has been", $EF, $EE
    db "opened! I replaced", $EF, $EE
    db "the Gatekeeper.", $F7, $F0

; =============================================================================
; ROOM DATA — Restored from proven patches
; =============================================================================
CustomSourceMapTable:
    db $04                      ; Room 0 ($6B) → Farm
    db $04                      ; Room 1 ($6C) → Farm (mirror $6B; CustomSourceMapTable)
    db $04                      ; Room 2 ($6D) → Farm (Pillar B gate-rotation room)
    db $04                      ; Room 3 ($6E) → Farm (placeholder, never entered)
    db $04                      ; Room 4 ($6F) → Farm (placeholder, never entered)
    db $04                      ; Room 5 ($70) → Farm (keystone proof room)

CustomRoomPtrTable:
    dw CustomRoom0_SubTable      ; $6B
    dw CustomRoom1_SubTable      ; $6C
    dw CustomRoom2_SubTable      ; $6D
    dw CustomRoomDummy_SubTable  ; $6E placeholder
    dw CustomRoomDummy_SubTable  ; $6F placeholder
    dw CustomRoom5_SubTable      ; $70 keystone proof room

; =============================================
; Room 0 (mapID $6B) — 2-screen vertical room
; Screen 0 = top, Screen 1 = bottom
; Scroll between screens is automatic
; =============================================
CustomRoom0_SubTable:
    dw CustomRoom0_Screen0
    dw $FFFF, $FFFF, $FFFF
    dw CustomRoom0_Screen1
    dw $FFFF, $FFFF, $FFFF

CustomRoom0_Screen0:
    dw wCustomStep_Room6B_S0    ; $D478 — safe step counter
    db 0, $64                   ; step_id=0 from bank $64 (custom layout screen 0)
    dw CustomRoom0_S0_NPCs
    dw CustomRoom0_S0_Exits

CustomRoom0_S0_NPCs:
    db $8F, $FF, $07, $06, $00     ; spawn point (7,6), script_id=0 (room entry = no-op)
    db $00, $0B, $02, $07, $01     ; NPC at (2,7), script_id=1 — gives item
    db $FF

CustomRoom0_S0_Exits:
    db $03, $01, $6C, $00, $00, $07, $06  ; exit: (3,1) → Room $6C screen 0 spawn (7,6)
                                          ; byte4=screen_byte: $00 → $2DE7[0] X-offset 0 (in-room).
                                          ; was $01 = +10 metatiles → tile col 35, OFF-MAP (movement bug).
    db $FF

CustomRoom0_Screen1:
    dw wCustomStep_Room6B_S1    ; $D479 — safe step counter
    db 2, $64                   ; step_id=2 from bank $64 (custom layout screen 1)
    dw CustomRoom0_S1_NPCs
    dw CustomRoom0_S1_Exits

CustomRoom0_S1_NPCs:
    db $8F, $FF, $05, $03, $00     ; spawn point (5,3)
    db $00, $09, $05, $04, $02     ; NPC at (5,4), script_id=2 — monster giver
    db $FF

CustomRoom0_S1_Exits:
    db $03, $07, $01, $00, $08, $04, $05  ; south edge exit: (3,7) → GreatTree screen 8
    db $FF

; =============================================
; Room 1 (mapID $6C) — 2-screen custom room (Pillar A proof)
; Structurally MIRRORS $6B: same gate tileset, same layouts (bank $64 entries
; 0/2) and attrs (entries 1/3 via CustomRoomAttr[1]), same Farm source-map. The
; ONLY difference is its own DUSK palette from CustomRoomPalPtr[1]. This proves
; per-room palette is table-driven on the exact render path $6B already validates.
; =============================================
CustomRoom1_SubTable:
    dw CustomRoom1_Screen0
    dw $FFFF, $FFFF, $FFFF
    dw CustomRoom1_Screen1
    dw $FFFF, $FFFF, $FFFF

CustomRoom1_Screen0:
    dw wCustomStep_Room6C_S0
    db 0, $64                       ; reuse $6B screen-0 layout (bank $64 entry 0)
    dw CustomRoom1_S0_NPCs
    dw CustomRoom1_S0_Exits

CustomRoom1_S0_NPCs:
    db $8F, $FF, $07, $06, $00     ; spawn (7,6) — same as $6B S0 (walkable)
    db $00, $09, $05, $04, $03     ; NPC (5,4), script_id=3 — teleport back to $6B
    db $FF

CustomRoom1_S0_Exits:
    db $03, $01, $70, $00, $00, $07, $06  ; edge exit (3,1) → Room $70 spawn (7,6)
    db $FF                          ; (NPC script_id=3 still offers a return to $6B)

CustomRoom1_Screen1:
    dw wCustomStep_Room6C_S1
    db 2, $64                       ; reuse $6B screen-1 layout (bank $64 entry 2)
    dw CustomRoom1_S1_NPCs
    dw CustomRoom1_S1_Exits

CustomRoom1_S1_NPCs:
    db $8F, $FF, $05, $03, $00     ; spawn (5,3) — same as $6B S1 (walkable)
    db $FF

CustomRoom1_S1_Exits:
    db $FF

; =============================================================================
; Room 2 (mapID $6D) — Pillar B: custom room in the Gate of Villager rotation
; =============================================================================
; Inserted into gate 1's floor rotation by the bank-$16 fork (CustomGate1Setup
; sets wMapID=$6D, wInGateworld=0, spawn $0048/$0068). Renders via the same
; table-driven Pillar A path as $6B/$6C: reuses $6B's gate-island screen-0
; layout (bank $64 entry 0), attr (CustomRoomAttr[2] = bank $64 entry 1) and
; gate palette (CustomRoomPalPtr[2] = CustomPaletteColors_6B). Single screen.
;
; DESCENT: the lone exit sits on the island's PIT metatile at walk (col5,row3)
; and carries gate_flag=$80 — byte-identical to how special rooms $50/$51
; descend. That re-enters gate floor setup (entry 5), increments wCurrentFloor,
; and (gate still 1) re-runs CustomGate1Setup → the next floor is $6D again,
; until wCurrentFloor+1 == last_floor (5) yields the boss floor.
; =============================================================================
CustomRoom2_ScriptPtrTable:
    dw CustomRoom2_RoomEntry        ; [0] room entry (no-op)

CustomRoom2_RoomEntry:
    dw $FFFF                        ; no-op room-entry script

CustomRoom2_SubTable:
    dw CustomRoom2_Screen0          ; screen 0 (only screen — 1 col × 1 row room)
    dw $FFFF, $FFFF, $FFFF          ; screens 1-3 invalid

CustomRoom2_Screen0:
    dw wCustomStep_Room6D_S0        ; $D47D — safe step counter
    db 0, $64                       ; step_id=0 from bank $64 (reuse $6B island screen 0)
    dw CustomRoom2_S0_NPCs
    dw CustomRoom2_S0_Exits

CustomRoom2_S0_NPCs:
    db $8F, $FF, $04, $06, $00      ; spawn point walk (col4,row6) — matches wWarpSpawn $0048/$0068 (central sand)
    db $FF

CustomRoom2_S0_Exits:
    db $05, $03, $00, $80, $00, $00, $00  ; descent: PIT walk (col5,row3), gate_flag=$80 → next gate floor
    db $FF                          ; gate-rotation room ONLY (reached via Gate of Villager, not the walk loop)

; =============================================================================
; Dummy subtable for unallocated custom mapIDs ($6E/$6F placeholders).
; Never entered (no exit leads here); all screens invalid.
; =============================================================================
CustomRoomDummy_SubTable:
    dw $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF

; =============================================================================
; Room 5 (mapID $70) — KEYSTONE PROOF: first room PAST the old $6F ceiling.
; =============================================================================
; Renders via the same fully table-driven path as $6B-$6D, but its $26DD-style
; record (tileset / dimensions / collision threshold) is supplied by bank $71's
; far Custom26DDTable[0] — NOT the in-ROM0 $26DD table (whose $70 slot collides
; with the gate tileset table at $2A5D). Reuses $6B's gate-island screen-0 layout
; (bank $64 entry 0), gate attr (CustomRoomAttr[5] = bank $64 entry 1) and its OWN ember
; palette (CustomRoomPalPtr[5] = CustomPaletteColors_70). Single screen.
; Encounters enabled (RoomEncTable[5]).
; A single edge exit closes the loop back to $6B.
; =============================================================================
CustomRoom5_SubTable:
    dw CustomRoom5_Screen0
    dw $FFFF, $FFFF, $FFFF

CustomRoom5_Screen0:
    dw wCustomStep_Room70_S0        ; $D47E — safe step counter
    db 0, $64                       ; reuse $6B island layout (bank $64 entry 0)
    dw CustomRoom5_S0_NPCs
    dw CustomRoom5_S0_Exits

CustomRoom5_S0_NPCs:
    db $8F, $FF, $07, $06, $00      ; spawn (7,6) — central walkable (matches $6B S0)
    db $FF

CustomRoom5_S0_Exits:
    db $03, $01, $6B, $00, $00, $07, $06  ; edge exit (3,1) → Room $6B spawn (7,6) — close the loop
    db $FF
