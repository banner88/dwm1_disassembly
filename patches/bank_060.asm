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
;   Entry 7: VanillaExitResolve — S70: unified exit resolve (custom rooms AND
;            compiler-authored vanilla-room exit EXTENSIONS; HL=list or 0)
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
    dw VanillaExitResolve   ; Entry 7 — S70 unified exit resolve (bank $0B Entry 6 calls this for EVERY non-gate room)

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
    ; S70v3: custom branch of the y-skip arming (see VanillaExitResolve):
    ; $FE never equals a real trigger_y, so Entry 6's scan no longer skips
    ; y=7 rows here — custom-room boundary exits fire on WALK-ON arrival.
    ; Entry 9 (push) reads the same list and still works as a fallback.
    ld a, $FE
    ld [wCustomY7Cmp], a
    call CustomPtrChase
    inc hl
    inc hl
    inc hl
    inc hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ; fall through into the shared copy loop (S70 factoring; behavior
    ; identical to the pre-S70 inline loop — 7-byte entries, first-byte-$FF
    ; terminator only, KEY_LESSONS v3-v4)
CopyExitListToBuffer:
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
; Entry 7: VanillaExitResolve  (S70 — vanilla-room exit extensions)
; =============================================================================
; Called by bank $0B RoomEntry6_ExitChecker (patches/bank_00b.asm) for EVERY
; non-gate room step in place of the old ">= $6B -> entry 2" divert.
; Contract: returns HL = exit list to scan (a WRAM buffer copy), or HL = 0
; meaning "no override — caller runs the vanilla SharedPtrChase path".
; rst $10 preserves HL/DE across the far call but clobbers A (bank byte) —
; the caller tests HL, never A (CROSSBANK_ROOMS "rst $10 Clobbers Register A").
;
;   wMapID >= $6B  -> jp CustomExitCheck (identical to the pre-S70 behavior)
;   wMapID <  $6B  -> scan VanillaExitExtTable (compiler-generated):
;       row: db mapID / dw step_counter_addr / db n_steps / dw list0..listN-1
;       table terminated by db $FF. Match: variant = min([counter], n-1),
;       copy that 7-byte exit list to wCustomExitBuffer, return HL=buffer.
;       No match: HL=0.
; Entry 9 (boundary y=0/7 exits) is NOT extended — it still reads the vanilla
; bank $0B lists directly. Extension rows with trigger_y 0/7 are therefore
; inert (Entry 6 skips them); the compiler validator enforces/warns this.
VanillaExitResolve:
    ; S70v3: arm the Entry 6 scan's y-skip compare for the VANILLA branch —
    ; $07 = skip y=7 rows (original engine semantics; y=7 stays Entry-9/push
    ; territory in vanilla rooms). CustomExitCheck writes $FE instead, which
    ; matches no real trigger_y, making custom-room y=7 rows WALK-ON exits.
    ; Entry 6 calls this entry before every scan, so the byte is always fresh.
    ld a, $07
    ld [wCustomY7Cmp], a
    ld a, [wMapID]
    cp CUSTOM_ROOM_START
    jr c, .vanillaScan
    jp CustomExitCheck          ; custom room — exact old entry-2 behavior
.vanillaScan:
    ld c, a                     ; C = mapID
    ld hl, VanillaExitExtTable
.scan:
    ld a, [hl+]
    cp $FF
    jr z, .none                 ; table end — no extension for this room
    cp c
    jr z, .match
    inc hl                      ; skip step_counter addr (2)
    inc hl
    ld a, [hl+]                 ; n_steps
    add a                       ; 2 bytes per variant ptr
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    jr .scan
.none:
    ld hl, $0000
    ret
.match:
    ld a, [hl+]
    ld e, a
    ld a, [hl+]
    ld d, a                     ; DE = step counter address (WRAM)
    ld a, [hl+]                 ; A = n_steps
    ld b, a
    ld a, [de]                  ; current step value
    cp b
    jr c, .stepOk
    ld a, b                     ; clamp out-of-range step to the last variant
    dec a
.stepOk:
    add a                       ; x2 (dw index)
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a                     ; HL = the variant's exit list
    jp CopyExitListToBuffer     ; -> HL = wCustomExitBuffer

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
    ld a, [wScriptMapType]      ; [ANCHOR S73] script TYPE targets the custom bank?
    cp $70                      ;   $70 = the gate-world script type — the B-bug
    jr z, .byRoom               ;   poison value; MUST stay on the wMapID route.
    cp CUSTOM_ROOM_START        ;   Any other type >= $6B (e.g. $71 armed by the
    jr nc, .customRoom          ;   Anchor field-skill) reads bank $60 scripts
.byRoom:                        ;   regardless of the physical room (maze/town).
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
    dw CustomScriptNoop_PtrTable  ; scriptless/placeholder room — safe no-op
    dw CustomScriptNoop_PtrTable  ; scriptless/placeholder room — safe no-op
    dw CustomScriptNoop_PtrTable  ; scriptless/placeholder room — safe no-op
    dw CustomRoom6_ScriptPtrTable   ; mapID $71
    dw CustomRoom7_ScriptPtrTable   ; mapID $72
    dw CustomRoom8_ScriptPtrTable   ; mapID $73

CustomScriptNoop_PtrTable:
    dw CustomScriptNoop_Entry   ; [0] room entry (no-op)
CustomScriptNoop_Entry:
    dw $FFFF

; --- $6B (gate_island) scripts ---
CustomRoom0_ScriptPtrTable:
    dw CustomRoom0_Scr00   ; [0] arm_encounters
    dw CustomRoom0_Scr01   ; [1] give_jerky
    dw CustomRoom0_Scr02   ; [2] give_egg
    dw CustomRoom0_Scr03   ; [3] bgm_change

CustomRoom0_Scr00:
    dw $FF13  ; write_ram2
    dw $CA39
    dw $04B0
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
    dw $FF13  ; write_ram2
    dw $CA39
    dw $04B0
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

; --- $71 (medal_vault) scripts ---
CustomRoom6_ScriptPtrTable:
    dw CustomRoom6_Scr00   ; [0] entry:medal_vault
    dw CustomRoom6_Scr01   ; [1] quest:medal_vault
    dw CustomRoom6_Scr02   ; [2] anchor_gate_confirm
    dw CustomRoom6_Scr03   ; [3] anchor_return_confirm
    dw CustomRoom6_Scr04   ; [4] anchor_err_special
    dw CustomRoom6_Scr05   ; [5] anchor_err_none

CustomRoom6_Scr00:
    dw $FF01  ; if_flag_set
    dw $0030
    dw CustomRoom6_Scr00_S92fArm
    dw $FF14  ; goto
    dw CustomRoom6_Scr00_S92fDone
CustomRoom6_Scr00_S92fArm:
    dw $FF13  ; write_ram2
    dw wCustomStep_ArenaClone_S1
    dw $0001
CustomRoom6_Scr00_S92fDone:
    dw $FF01  ; if_flag_set
    dw $0158
    dw CustomRoom6_Scr00_edone
    dw $FF01  ; if_flag_set
    dw $0159
    dw CustomRoom6_Scr00_eseen
    dw $FF07  ; init_dialog
    dw $0A18  ; S70 cutscene line 1
    dw $FF1C  ; trigger_anim
    dw $0101
    dw $FF09  ; delay
    dw $0019
    dw $FF22  ; begin_walk
    dw $FF1B  ; npc_walk_y
    dw $0001
    dw $0020
    dw $FF09  ; delay
    dw $002D
    dw $FF07  ; init_dialog
    dw $0A19  ; S70 cutscene line 2
    dw $FF1B  ; npc_walk_y
    dw $0001
    dw $FFE0
    dw $FF09  ; delay
    dw $002D
    dw $FF1C  ; trigger_anim
    dw $0100
    dw $FF09  ; delay
    dw $0014
    dw $FF03  ; set_flag
    dw $0159
    dw $FFFF
CustomRoom6_Scr00_eseen:
    dw $FFFF
CustomRoom6_Scr00_edone:
    dw $FF48  ; npc_hide
    dw $0001
    dw $FFFF

CustomRoom6_Scr01:
    dw $FF01  ; if_flag_set
    dw $0158
    dw CustomRoom6_Scr01_qdone
    dw $FF15  ; check_and_branch
    dw $CA8D
    dw $0001
    dw CustomRoom6_Scr01_req0
    dw $0A1A  ; requires $CA8D==1 refusal
    dw $FFFF
CustomRoom6_Scr01_req0:
    dw $0A1B  ; quest YES/NO offer
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom6_Scr01_declined
    dw $0A1D  ; vault_prebattle
    dw $FF5A  ; trigger_battle3
    dw $0207
    dw $FF03  ; set_flag
    dw $0158
    dw $FF07  ; init_dialog
    dw $0A1E  ; win tail; GoldSlime joins engine-side (phase $0D)
    dw $FF48  ; npc_hide
    dw $0001
    dw $FFFF
CustomRoom6_Scr01_declined:
    dw $0A1C  ; vault_decline
    dw $FFFF
CustomRoom6_Scr01_qdone:
    dw $0A1F  ; vault_done
    dw $FFFF

CustomRoom6_Scr02:
    dw $FF07  ; init_dialog
    dw $0A20  ; [S73] Anchor gate-side confirm [Y/N]
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom6_Scr02_no
    dw $FF12  ; write_ram
    dw $DEB2
    dw $0001
    dw $FF12  ; write_ram
    dw $D92B
    dw $0006
    dw $FF0F  ; map_transition
    dw $0000
    dw $00E8
    dw $0058
    dw $FFFF
CustomRoom6_Scr02_no:
    dw $FFFF

CustomRoom6_Scr03:
    dw $FF07  ; init_dialog
    dw $0A21  ; [S73] Anchor return confirm [Y/N] — charge lands on arrival
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom6_Scr03_no
    dw $FF12  ; write_ram
    dw $DEB2
    dw $0002
    dw $FF0F  ; map_transition
    dw $8000
    dw $0000
    dw $0000
    dw $FFFF
CustomRoom6_Scr03_no:
    dw $FFFF

CustomRoom6_Scr04:
    dw $FF07  ; init_dialog
    dw $0A22  ; [S73] cast in a special/boss/custom gate room
    dw $FFFF

CustomRoom6_Scr05:
    dw $FF07  ; init_dialog
    dw $0A23  ; [S73] cast in town with no stored anchor
    dw $FFFF

; --- $72 (arena_clone) scripts ---
CustomRoom7_ScriptPtrTable:
    dw CustomRoom7_Scr00   ; [0] arena_clone_scr00
    dw CustomRoom7_Scr01   ; [1] arena_clone_scr01
    dw CustomRoom7_Scr02   ; [2] arena_clone_scr02
    dw CustomRoom7_Scr03   ; [3] arena_clone_scr03
    dw CustomRoom7_Scr04   ; [4] arena_clone_scr04
    dw CustomRoom7_Scr05   ; [5] arena_clone_scr05
    dw CustomRoom7_Scr06   ; [6] arena_clone_scr06
    dw CustomRoom7_Scr07   ; [7] arena_clone_scr07
    dw CustomRoom7_Scr08   ; [8] arena_clone_scr08
    dw CustomRoom7_Scr09   ; [9] arena_clone_scr09
    dw CustomRoom7_Scr10   ; [10] arena_clone_scr10
    dw CustomRoom7_Scr11   ; [11] arena_clone_scr11

CustomRoom7_Scr00:
    dw $FF01  ; if_flag_set
    dw $0030
    dw CustomRoom7_Scr00_S92rank1
    dw $FF14  ; goto
    dw CustomRoom7_Scr00_S92body
CustomRoom7_Scr00_S92rank1:
    dw $FF13  ; write_ram2
    dw wCustomStep_ArenaClone_S1
    dw $0001
CustomRoom7_Scr00_S92body:
    dw $FF12  ; write_ram
    dw $C8ED
    dw $0000
    dw $FF15  ; check_and_branch
    dw $D951
    dw $00F2
    dw CustomRoom7_Scr00_L46F2
    dw $FF0E  ; opcode $0E
    dw $0001
    dw CustomRoom7_Scr00_L4228
    dw $FFFF
CustomRoom7_Scr00_L4228:
    dw $FF15  ; check_and_branch
    dw $D9CD
    dw $00FE
    dw CustomRoom7_Scr00_L4270
    dw $FF15  ; check_and_branch
    dw $D9CD
    dw $00FF
    dw CustomRoom7_Scr00_L4242
    dw $FF0D  ; opcode $0D
    dw $0000
    dw $FF90
    dw $0000
    dw $FFFF
CustomRoom7_Scr00_L4242:
    dw $FF27  ; monster_party_op2
    dw $FF0D  ; opcode $0D
    dw $0000
    dw $FF90
    dw $0000
    dw $FF49  ; npc_show
    dw $0000
    dw $FF12  ; write_ram
    dw $D9CD
    dw $0000
    dw $FF07  ; init_dialog
    dw $FF01  ; if_flag_set
    dw $0033
    dw CustomRoom7_Scr00_L426C
    dw $FF01  ; if_flag_set
    dw $0030
    dw CustomRoom7_Scr00_L4268
    dw $00E3
    dw $FFFF
CustomRoom7_Scr00_L4268:
    dw $0179
    dw $FFFF
CustomRoom7_Scr00_L426C:
    dw $043A
    dw $FFFF
CustomRoom7_Scr00_L4270:
    dw $FF27  ; monster_party_op2
    dw $FF0D  ; opcode $0D
    dw $0000
    dw $FF90
    dw $0000
    dw $FF49  ; npc_show
    dw $0000
    dw $FF01  ; if_flag_set
    dw $0111
    dw CustomRoom7_Scr00_L42C6
    dw $FF15  ; check_and_branch
    dw $D9CE
    dw $0007
    dw CustomRoom7_Scr00_L45F6
    dw $FF15  ; check_and_branch
    dw $D9CE
    dw $0006
    dw CustomRoom7_Scr00_L4590
    dw $FF15  ; check_and_branch
    dw $D9CE
    dw $0005
    dw CustomRoom7_Scr00_L453A
    dw $FF15  ; check_and_branch
    dw $D9CE
    dw $0004
    dw CustomRoom7_Scr00_L451E
    dw $FF15  ; check_and_branch
    dw $D9CE
    dw $0003
    dw CustomRoom7_Scr00_L4432
    dw $FF15  ; check_and_branch
    dw $D9CE
    dw $0002
    dw CustomRoom7_Scr00_L43D2
    dw $FF15  ; check_and_branch
    dw $D9CE
    dw $0001
    dw CustomRoom7_Scr00_L4392
    dw $FF15  ; check_and_branch
    dw $D9CE
    dw $0000
    dw CustomRoom7_Scr00_L42D6
    dw $FFFF
CustomRoom7_Scr00_L42C6:
    dw $FF07  ; init_dialog
    dw $07D1
    dw $FF03  ; set_flag
    dw $00FD
    dw $FF12  ; write_ram
    dw $D9CD
    dw $0000
    dw $FFFF
CustomRoom7_Scr00_L42D6:
    dw $FF12  ; write_ram
    dw $CAB4
    dw $0001
    dw $FF03  ; set_flag
    dw $0030
    dw $FF12  ; write_ram
    dw $D92B
    dw $0000
    dw $FF12  ; write_ram
    dw $D92F
    dw $0002
    dw $FF12  ; write_ram
    dw $D931
    dw $0001
    dw $FF12  ; write_ram
    dw $D93C
    dw $0003
    dw $FF12  ; write_ram
    dw $D941
    dw $0001
    dw $FF12  ; write_ram
    dw $D9CD
    dw $0000
    dw $FF07  ; init_dialog
    dw $00E4
    dw $FF0D  ; opcode $0D
    dw $0003
    dw $0000
    dw $0000
    dw $FF21  ; opcode $21
    dw $0051
    dw $FF09  ; delay
    dw $0002
    dw $FF0B  ; opcode $0B
    dw $0003
    dw $FFF0
    dw $FF09  ; delay
    dw $0002
    dw $FF48  ; npc_hide
    dw $0000
    dw $FF09  ; delay
    dw $0002
    dw $FF0B  ; opcode $0B
    dw $0003
    dw $FFE0
    dw $FF09  ; delay
    dw $0002
    dw $FF3D  ; opcode $3D
    dw $FF07  ; init_dialog
    dw $00E5
    dw $FF1B  ; npc_walk_y
    dw $0003
    dw $0030
    dw $FF1B  ; npc_walk_y
    dw $0000
    dw $0030
    dw $FF19  ; wait_movement
    dw $FF12  ; write_ram
    dw $C8ED
    dw $0001
    dw $FF0B  ; opcode $0B
    dw $0000
    dw $FFF0
    dw $FF12  ; write_ram
    dw $C8ED
    dw $0003
    dw $FF0B  ; opcode $0B
    dw $0000
    dw $FFF0
    dw $FF12  ; write_ram
    dw $C8ED
    dw $0007
    dw $FF21  ; opcode $21
    dw $0051
    dw $FF0B  ; opcode $0B
    dw $0000
    dw $FFF0
    dw $FF12  ; write_ram
    dw $C8ED
    dw $000F
    dw $FF0D  ; opcode $0D
    dw $0000
    dw $FF90
    dw $0040
    dw $FF0D  ; opcode $0D
    dw $0003
    dw $0000
    dw $0040
    dw $FF08  ; opcode $08
    dw $FF0F  ; map_transition
    dw $0000
    dw $00E8
    dw $0058
    dw $FFFF
CustomRoom7_Scr00_L4392:
    dw $FF12  ; write_ram
    dw $CAB4
    dw $0002
    dw $FF03  ; set_flag
    dw $0031
    dw $FF12  ; write_ram
    dw $D92F
    dw $0003
    dw $FF12  ; write_ram
    dw $D931
    dw $0002
    dw $FF12  ; write_ram
    dw $D933
    dw $0001
    dw $FF12  ; write_ram
    dw $D93C
    dw $0004
    dw $FF12  ; write_ram
    dw $D952
    dw $0001
    dw $FF12  ; write_ram
    dw $D953
    dw $0001
    dw $FF12  ; write_ram
    dw $D954
    dw $0001
    dw $FF12  ; write_ram
    dw $D9CD
    dw $0000
    dw $FF07  ; init_dialog
    dw $017A
    dw $FFFF
CustomRoom7_Scr00_L43D2:
    dw $FF12  ; write_ram
    dw $CAB4
    dw $0003
    dw $FF03  ; set_flag
    dw $0032
    dw $FF12  ; write_ram
    dw $D93B
    dw $0001
    dw $FF12  ; write_ram
    dw $D942
    dw $0001
    dw $FF12  ; write_ram
    dw $D9CD
    dw $0000
    dw $FF00  ; if_flag_clear
    dw $0031
    dw CustomRoom7_Scr00_L43FA
    dw $FF07  ; init_dialog
    dw $01B6
    dw $FFFF
CustomRoom7_Scr00_L43FA:
    dw $FF03  ; set_flag
    dw $0031
    dw $FF03  ; set_flag
    dw $0049
    dw $FF12  ; write_ram
    dw $D92F
    dw $0003
    dw $FF12  ; write_ram
    dw $D931
    dw $0002
    dw $FF12  ; write_ram
    dw $D933
    dw $0001
    dw $FF12  ; write_ram
    dw $D93C
    dw $0004
    dw $FF12  ; write_ram
    dw $D952
    dw $0001
    dw $FF12  ; write_ram
    dw $D953
    dw $0001
    dw $FF12  ; write_ram
    dw $D954
    dw $0001
    dw $FF07  ; init_dialog
    dw $01B7
    dw $FFFF
CustomRoom7_Scr00_L4432:
    dw $FF01  ; if_flag_set
    dw $0032
    dw CustomRoom7_Scr00_L443C
    dw $FF03  ; set_flag
    dw $0119
CustomRoom7_Scr00_L443C:
    dw $FF12  ; write_ram
    dw $CAB4
    dw $0004
    dw $FF03  ; set_flag
    dw $0031
    dw $FF03  ; set_flag
    dw $0032
    dw $FF03  ; set_flag
    dw $0033
    dw $FF12  ; write_ram
    dw $D92B
    dw $0000
    dw $FF12  ; write_ram
    dw $D92F
    dw $0003
    dw $FF12  ; write_ram
    dw $D931
    dw $0002
    dw $FF12  ; write_ram
    dw $D933
    dw $0001
    dw $FF12  ; write_ram
    dw $D93B
    dw $0002
    dw $FF12  ; write_ram
    dw $D93C
    dw $0004
    dw $FF12  ; write_ram
    dw $D942
    dw $0001
    dw $FF12  ; write_ram
    dw $D952
    dw $0001
    dw $FF12  ; write_ram
    dw $D953
    dw $0001
    dw $FF12  ; write_ram
    dw $D954
    dw $0001
    dw $FF12  ; write_ram
    dw $D9CD
    dw $0000
    dw $FF07  ; init_dialog
    dw $021C
    dw $FF0D  ; opcode $0D
    dw $0003
    dw $0000
    dw $0000
    dw $FF21  ; opcode $21
    dw $0051
    dw $FF09  ; delay
    dw $0002
    dw $FF0B  ; opcode $0B
    dw $0003
    dw $FFF0
    dw $FF09  ; delay
    dw $0002
    dw $FF48  ; npc_hide
    dw $0000
    dw $FF09  ; delay
    dw $0002
    dw $FF0B  ; opcode $0B
    dw $0003
    dw $FFE0
    dw $FF09  ; delay
    dw $0002
    dw $FF3D  ; opcode $3D
    dw $FF07  ; init_dialog
    dw $021D
    dw $FF1B  ; npc_walk_y
    dw $0003
    dw $0030
    dw $FF1B  ; npc_walk_y
    dw $0000
    dw $0030
    dw $FF19  ; wait_movement
    dw $FF12  ; write_ram
    dw $C8ED
    dw $0001
    dw $FF0B  ; opcode $0B
    dw $0000
    dw $FFF0
    dw $FF12  ; write_ram
    dw $C8ED
    dw $0003
    dw $FF0B  ; opcode $0B
    dw $0000
    dw $FFF0
    dw $FF12  ; write_ram
    dw $C8ED
    dw $0007
    dw $FF21  ; opcode $21
    dw $0051
    dw $FF0B  ; opcode $0B
    dw $0000
    dw $FFF0
    dw $FF12  ; write_ram
    dw $C8ED
    dw $000F
    dw $FF0D  ; opcode $0D
    dw $0000
    dw $FF90
    dw $0040
    dw $FF0D  ; opcode $0D
    dw $0003
    dw $0000
    dw $0040
    dw $FF08  ; opcode $08
    dw $FF0F  ; map_transition
    dw $0000
    dw $00E8
    dw $0058
    dw $FFFF
CustomRoom7_Scr00_L451E:
    dw $FF12  ; write_ram
    dw $CAB4
    dw $0005
    dw $FF03  ; set_flag
    dw $0034
    dw $FF12  ; write_ram
    dw $D93B
    dw $0003
    dw $FF12  ; write_ram
    dw $D9CD
    dw $0000
    dw $FF07  ; init_dialog
    dw $02E1
    dw $FFFF
CustomRoom7_Scr00_L453A:
    dw $FF12  ; write_ram
    dw $CAB4
    dw $0006
    dw $FF03  ; set_flag
    dw $0035
    dw $FF12  ; write_ram
    dw $D939
    dw $0001
    dw $FF12  ; write_ram
    dw $D93D
    dw $0001
    dw $FF12  ; write_ram
    dw $D945
    dw $0001
    dw $FF12  ; write_ram
    dw $D946
    dw $0001
    dw $FF12  ; write_ram
    dw $D947
    dw $0002
    dw $FF12  ; write_ram
    dw $D963
    dw $0001
    dw $FF12  ; write_ram
    dw $D964
    dw $0001
    dw $FF12  ; write_ram
    dw $D9CD
    dw $0000
    dw $FF00  ; if_flag_clear
    dw $0034
    dw CustomRoom7_Scr00_L4580
    dw $FF07  ; init_dialog
    dw $0341
    dw $FFFF
CustomRoom7_Scr00_L4580:
    dw $FF03  ; set_flag
    dw $0034
    dw $FF12  ; write_ram
    dw $D93B
    dw $0003
    dw $FF07  ; init_dialog
    dw $0342
    dw $FFFF
CustomRoom7_Scr00_L4590:
    dw $FF12  ; write_ram
    dw $CAB4
    dw $0007
    dw $FF03  ; set_flag
    dw $0036
    dw $FF12  ; write_ram
    dw $D93D
    dw $0002
    dw $FF12  ; write_ram
    dw $D9CD
    dw $0000
    dw $FF00  ; if_flag_clear
    dw $0035
    dw CustomRoom7_Scr00_L45B2
    dw $FF07  ; init_dialog
    dw $039F
    dw $FFFF
CustomRoom7_Scr00_L45B2:
    dw $FF03  ; set_flag
    dw $0035
    dw $FF12  ; write_ram
    dw $D939
    dw $0001
    dw $FF12  ; write_ram
    dw $D945
    dw $0001
    dw $FF12  ; write_ram
    dw $D946
    dw $0001
    dw $FF12  ; write_ram
    dw $D947
    dw $0002
    dw $FF12  ; write_ram
    dw $D963
    dw $0001
    dw $FF12  ; write_ram
    dw $D964
    dw $0001
    dw $FF00  ; if_flag_clear
    dw $0034
    dw CustomRoom7_Scr00_L45E6
    dw $FF07  ; init_dialog
    dw $03A1
    dw $FFFF
CustomRoom7_Scr00_L45E6:
    dw $FF03  ; set_flag
    dw $0034
    dw $FF12  ; write_ram
    dw $D93B
    dw $0003
    dw $FF07  ; init_dialog
    dw $03A0
    dw $FFFF
CustomRoom7_Scr00_L45F6:
    dw $FF01  ; if_flag_set
    dw $0036
    dw CustomRoom7_Scr00_L4600
    dw $FF03  ; set_flag
    dw $011C
CustomRoom7_Scr00_L4600:
    dw $FF12  ; write_ram
    dw $CAB4
    dw $0008
    dw $FF03  ; set_flag
    dw $0034
    dw $FF03  ; set_flag
    dw $0035
    dw $FF03  ; set_flag
    dw $0036
    dw $FF03  ; set_flag
    dw $0037
    dw $FF12  ; write_ram
    dw $D92B
    dw $0000
    dw $FF12  ; write_ram
    dw $D936
    dw $0002
    dw $FF12  ; write_ram
    dw $D937
    dw $0002
    dw $FF12  ; write_ram
    dw $D938
    dw $0002
    dw $FF12  ; write_ram
    dw $D939
    dw $0002
    dw $FF12  ; write_ram
    dw $D93B
    dw $0003
    dw $FF12  ; write_ram
    dw $D93D
    dw $0003
    dw $FF12  ; write_ram
    dw $D945
    dw $0001
    dw $FF12  ; write_ram
    dw $D946
    dw $0001
    dw $FF12  ; write_ram
    dw $D947
    dw $0002
    dw $FF12  ; write_ram
    dw $D963
    dw $0001
    dw $FF12  ; write_ram
    dw $D964
    dw $0001
    dw $FF12  ; write_ram
    dw $D9CD
    dw $0000
    dw $FF07  ; init_dialog
    dw $03F1
    dw $FF0D  ; opcode $0D
    dw $0003
    dw $0000
    dw $0000
    dw $FF21  ; opcode $21
    dw $0051
    dw $FF09  ; delay
    dw $0002
    dw $FF0B  ; opcode $0B
    dw $0003
    dw $FFF0
    dw $FF09  ; delay
    dw $0002
    dw $FF48  ; npc_hide
    dw $0000
    dw $FF09  ; delay
    dw $0002
    dw $FF0B  ; opcode $0B
    dw $0003
    dw $FFE0
    dw $FF09  ; delay
    dw $0002
    dw $FF3D  ; opcode $3D
    dw $FF07  ; init_dialog
    dw $03F2
    dw $FF1B  ; npc_walk_y
    dw $0003
    dw $0030
    dw $FF1B  ; npc_walk_y
    dw $0000
    dw $0030
    dw $FF19  ; wait_movement
    dw $FF12  ; write_ram
    dw $C8ED
    dw $0001
    dw $FF0B  ; opcode $0B
    dw $0000
    dw $FFF0
    dw $FF12  ; write_ram
    dw $C8ED
    dw $0003
    dw $FF0B  ; opcode $0B
    dw $0000
    dw $FFF0
    dw $FF12  ; write_ram
    dw $C8ED
    dw $0007
    dw $FF21  ; opcode $21
    dw $0051
    dw $FF0B  ; opcode $0B
    dw $0000
    dw $FFF0
    dw $FF12  ; write_ram
    dw $C8ED
    dw $000F
    dw $FF0D  ; opcode $0D
    dw $0000
    dw $FF90
    dw $0040
    dw $FF0D  ; opcode $0D
    dw $0003
    dw $0000
    dw $0040
    dw $FF08  ; opcode $08
    dw $FF0F  ; map_transition
    dw $0000
    dw $00E8
    dw $0058
    dw $FFFF
CustomRoom7_Scr00_L46F2:
    dw $FF0D  ; opcode $0D
    dw $0000
    dw $FF90
    dw $0000
    dw $FF44  ; opcode $44
    dw $FF12  ; write_ram
    dw $D951
    dw $0000
    dw $FFFF

CustomRoom7_Scr01:
    dw $FF15  ; check_and_branch
    dw $C8ED
    dw $0000
    dw CustomRoom7_Scr01_L470E
    dw $FFFF
CustomRoom7_Scr01_L470E:
    dw $FF12  ; write_ram
    dw $C8ED
    dw $0001
    dw $FF0D  ; opcode $0D
    dw $0001
    dw $0000
    dw $0000
    dw $FF0B  ; opcode $0B
    dw $0000
    dw $FFF0
    dw $FF0A  ; opcode $0A
    dw $0000
    dw $FFD0
    dw $FF0B  ; opcode $0B
    dw $0000
    dw $0020
    dw $FF12  ; write_ram
    dw $C8ED
    dw $0009
    dw $FF0D  ; opcode $0D
    dw $0004
    dw $0000
    dw $0000
    dw $FF0A  ; opcode $0A
    dw $0000
    dw $0010
    dw $FF12  ; write_ram
    dw $C8ED
    dw $000D
    dw $FF0D  ; opcode $0D
    dw $0003
    dw $0000
    dw $0000
    dw $FF0A  ; opcode $0A
    dw $0000
    dw $0010
    dw $FF12  ; write_ram
    dw $C8ED
    dw $000F
    dw $FF0D  ; opcode $0D
    dw $0002
    dw $0000
    dw $0000
    dw $FF4A  ; opcode $4A
    dw $0002
    dw $FF4A  ; opcode $4A
    dw $0003
    dw $FF4A  ; opcode $4A
    dw $0004
    dw $FF0A  ; opcode $0A
    dw $0000
    dw $0010
    dw $FF0B  ; opcode $0B
    dw $0000
    dw $FFF0
    dw $FF49  ; npc_show
    dw $0000
    dw $FF08  ; opcode $08
    dw $FF0D  ; opcode $0D
    dw $0001
    dw $0000
    dw $0040
    dw $FF12  ; write_ram
    dw $C8ED
    dw $000E
    dw $FFFF

CustomRoom7_Scr02:
    dw $FF2D  ; opcode $2D
    dw $0000
    dw $FFFF

CustomRoom7_Scr03:
    dw $FF2D  ; opcode $2D
    dw $0001
    dw $FFFF

CustomRoom7_Scr04:
    dw $FF2D  ; opcode $2D
    dw $0002
    dw $FFFF

CustomRoom7_Scr05:
    dw $00EB
    dw $00EC
    dw $FFFF

CustomRoom7_Scr06:
    dw $FF01  ; if_flag_set
    dw $0103
    dw CustomRoom7_Scr06_L4948
    dw $FF01  ; if_flag_set
    dw $0111
    dw CustomRoom7_Scr06_L4940
    dw $FF01  ; if_flag_set
    dw $0110
    dw CustomRoom7_Scr06_L490E
    dw $FF01  ; if_flag_set
    dw $00F1
    dw CustomRoom7_Scr06_L48DC
    dw $FF01  ; if_flag_set
    dw $0025
    dw CustomRoom7_Scr06_L48A8
    dw $FF01  ; if_flag_set
    dw $0037
    dw CustomRoom7_Scr06_L48A4
    dw $FF01  ; if_flag_set
    dw $007D
    dw CustomRoom7_Scr06_L4882
    dw $FF01  ; if_flag_set
    dw $001D
    dw CustomRoom7_Scr06_L489A
    dw $FF01  ; if_flag_set
    dw $0033
    dw CustomRoom7_Scr06_L4896
    dw $FF01  ; if_flag_set
    dw $005A
    dw CustomRoom7_Scr06_L4882
    dw $FF01  ; if_flag_set
    dw $0030
    dw CustomRoom7_Scr06_L488A
    dw $FF01  ; if_flag_set
    dw $0059
    dw CustomRoom7_Scr06_L4882
    dw $00E2
    dw $FF03  ; set_flag
    dw $0059
    dw $FF14  ; goto
    dw CustomRoom7_Scr06_L47FE
CustomRoom7_Scr06_L47FE:
    dw $FF04  ; opcode $04
    dw $0004
    dw $0710
    dw $FF15  ; check_and_branch
    dw $D9CD
    dw $00FF
    dw CustomRoom7_Scr06_L4878
    dw $FF12  ; write_ram
    dw $D999
    dw $0000
    dw $FF09  ; delay
    dw $0004
    dw $FF47  ; opcode $47
    dw $0000
    dw $FF09  ; delay
    dw $0002
    dw $FF0B  ; opcode $0B
    dw $0000
    dw $FFF0
CustomRoom7_Scr06_L4824:
    dw $FF12  ; write_ram
    dw $C8ED
    dw $0001
    dw $FF09  ; delay
    dw $0002
    dw $FF0B  ; opcode $0B
    dw $0000
    dw $FFF0
    dw $FF12  ; write_ram
    dw $C8ED
    dw $0003
    dw $FF09  ; delay
    dw $0002
    dw $FF0B  ; opcode $0B
    dw $0000
    dw $FFF0
    dw $FF12  ; write_ram
    dw $C8ED
    dw $0007
    dw $FF09  ; delay
    dw $0002
    dw $FF0B  ; opcode $0B
    dw $0000
    dw $FFF0
    dw $FF12  ; write_ram
    dw $C8ED
    dw $000F
    dw $FF09  ; delay
    dw $0002
    dw $FF0D  ; opcode $0D
    dw $0000
    dw $FF90
    dw $0040
    dw $FF12  ; write_ram
    dw $D9CD
    dw $0000
    dw $FF1F  ; opcode $1F
    dw $FF0F  ; map_transition
    dw $005D
    dw $0078
    dw $0058
    dw $FFFF
CustomRoom7_Scr06_L4878:
    dw $0713
    dw $FF12  ; write_ram
    dw $D9CD
    dw $0000
    dw $FFFF
CustomRoom7_Scr06_L4882:
    dw $0710
    dw $FF14  ; goto
    dw CustomRoom7_Scr06_L47FE
CustomRoom7_Scr06_L488A:
    dw $0178
    dw $FF03  ; set_flag
    dw $005A
    dw $FF14  ; goto
    dw CustomRoom7_Scr06_L47FE
CustomRoom7_Scr06_L4896:
    dw $027C
    dw $FFFF
CustomRoom7_Scr06_L489A:
    dw $02E0
    dw $FF03  ; set_flag
    dw $007D
    dw $FF14  ; goto
    dw CustomRoom7_Scr06_L47FE
CustomRoom7_Scr06_L48A4:
    dw $044D
    dw $FFFF
CustomRoom7_Scr06_L48A8:
    dw $04AF
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom7_Scr06_L48D8
    dw $04B1
    dw $FF09  ; delay
    dw $0004
    dw $FF47  ; opcode $47
    dw $0000
    dw $FF09  ; delay
    dw $000C
    dw $FF0B  ; opcode $0B
    dw $0000
    dw $FFF0
    dw $FF12  ; write_ram
    dw $D9CE
    dw $0008
    dw $FF12  ; write_ram
    dw $D999
    dw $0001
    dw $FF14  ; goto
    dw CustomRoom7_Scr06_L4824
CustomRoom7_Scr06_L48D8:
    dw $04B0
    dw $FFFF
CustomRoom7_Scr06_L48DC:
    dw $07C7
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom7_Scr06_L490A
    dw $FF09  ; delay
    dw $0004
    dw $FF47  ; opcode $47
    dw $0000
    dw $FF09  ; delay
    dw $000C
    dw $FF0B  ; opcode $0B
    dw $0000
    dw $FFF0
    dw $FF12  ; write_ram
    dw $D9CE
    dw $0009
    dw $FF12  ; write_ram
    dw $D999
    dw $0004
    dw $FF14  ; goto
    dw CustomRoom7_Scr06_L4824
CustomRoom7_Scr06_L490A:
    dw $07C8
    dw $FFFF
CustomRoom7_Scr06_L490E:
    dw $07CC
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom7_Scr06_L493C
    dw $FF09  ; delay
    dw $0004
    dw $FF47  ; opcode $47
    dw $0000
    dw $FF09  ; delay
    dw $000C
    dw $FF0B  ; opcode $0B
    dw $0000
    dw $FFF0
    dw $FF12  ; write_ram
    dw $D9CE
    dw $0009
    dw $FF12  ; write_ram
    dw $D999
    dw $0004
    dw $FF14  ; goto
    dw CustomRoom7_Scr06_L4824
CustomRoom7_Scr06_L493C:
    dw $07CD
    dw $FFFF
CustomRoom7_Scr06_L4940:
    dw $07D1
    dw $FF03  ; set_flag
    dw $00FD
    dw $FFFF
CustomRoom7_Scr06_L4948:
    dw $07D2
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom7_Scr06_L4978
    dw $08D4
    dw $FF09  ; delay
    dw $0004
    dw $FF47  ; opcode $47
    dw $0000
    dw $FF09  ; delay
    dw $000C
    dw $FF0B  ; opcode $0B
    dw $0000
    dw $FFF0
    dw $FF12  ; write_ram
    dw $D9CE
    dw $0009
    dw $FF12  ; write_ram
    dw $D999
    dw $0004
    dw $FF14  ; goto
    dw CustomRoom7_Scr06_L4824
CustomRoom7_Scr06_L4978:
    dw $08D5
    dw $FFFF

CustomRoom7_Scr07:
    dw $FF01  ; if_flag_set
    dw $00FE
    dw CustomRoom7_Scr07_L4ACA
    dw $FF01  ; if_flag_set
    dw $0111
    dw CustomRoom7_Scr07_L4AC0
    dw $FF01  ; if_flag_set
    dw $0110
    dw CustomRoom7_Scr07_L4AAC
    dw $FF01  ; if_flag_set
    dw $00F1
    dw CustomRoom7_Scr07_L4A98
    dw $FF01  ; if_flag_set
    dw $00B0
    dw CustomRoom7_Scr07_L4A84
    dw $FF01  ; if_flag_set
    dw $0025
    dw CustomRoom7_Scr07_L4A7C
    dw $FF01  ; if_flag_set
    dw $00A4
    dw CustomRoom7_Scr07_L4A78
    dw $FF01  ; if_flag_set
    dw $0037
    dw CustomRoom7_Scr07_L4A70
    dw $FF01  ; if_flag_set
    dw $0036
    dw CustomRoom7_Scr07_L4A5E
    dw $FF01  ; if_flag_set
    dw $0035
    dw CustomRoom7_Scr07_L4A4C
    dw $FF01  ; if_flag_set
    dw $0034
    dw CustomRoom7_Scr07_L4A3A
    dw $FF01  ; if_flag_set
    dw $001D
    dw CustomRoom7_Scr07_L4A28
    dw $FF01  ; if_flag_set
    dw $0033
    dw CustomRoom7_Scr07_L4A24
    dw $FF01  ; if_flag_set
    dw $0032
    dw CustomRoom7_Scr07_L4A12
    dw $FF01  ; if_flag_set
    dw $0031
    dw CustomRoom7_Scr07_L4A00
    dw $FF01  ; if_flag_set
    dw $0030
    dw CustomRoom7_Scr07_L49EE
    dw $00E6
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom7_Scr07_L49EA
    dw $00E7
    dw $FFFF
CustomRoom7_Scr07_L49EA:
    dw $00E8
    dw $FFFF
CustomRoom7_Scr07_L49EE:
    dw $00E6
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom7_Scr07_L49FC
    dw $00E7
    dw $FFFF
CustomRoom7_Scr07_L49FC:
    dw $017B
    dw $FFFF
CustomRoom7_Scr07_L4A00:
    dw $00E6
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom7_Scr07_L4A0E
    dw $00E7
    dw $FFFF
CustomRoom7_Scr07_L4A0E:
    dw $01B8
    dw $FFFF
CustomRoom7_Scr07_L4A12:
    dw $00E6
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom7_Scr07_L4A20
    dw $00E7
    dw $FFFF
CustomRoom7_Scr07_L4A20:
    dw $021E
    dw $FFFF
CustomRoom7_Scr07_L4A24:
    dw $027D
    dw $FFFF
CustomRoom7_Scr07_L4A28:
    dw $00E6
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom7_Scr07_L4A36
    dw $02E2
    dw $FFFF
CustomRoom7_Scr07_L4A36:
    dw $02E3
    dw $FFFF
CustomRoom7_Scr07_L4A3A:
    dw $00E6
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom7_Scr07_L4A48
    dw $02E2
    dw $FFFF
CustomRoom7_Scr07_L4A48:
    dw $0343
    dw $FFFF
CustomRoom7_Scr07_L4A4C:
    dw $00E6
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom7_Scr07_L4A5A
    dw $02E2
    dw $FFFF
CustomRoom7_Scr07_L4A5A:
    dw $03A2
    dw $FFFF
CustomRoom7_Scr07_L4A5E:
    dw $00E6
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom7_Scr07_L4A6C
    dw $02E2
    dw $FFFF
CustomRoom7_Scr07_L4A6C:
    dw $03F3
    dw $FFFF
CustomRoom7_Scr07_L4A70:
    dw $044E
    dw $FF03  ; set_flag
    dw $00A4
    dw $FFFF
CustomRoom7_Scr07_L4A78:
    dw $044F
    dw $FFFF
CustomRoom7_Scr07_L4A7C:
    dw $04B2
    dw $FF03  ; set_flag
    dw $00B0
    dw $FFFF
CustomRoom7_Scr07_L4A84:
    dw $04B3
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom7_Scr07_L4A92
    dw $01AD
    dw $FFFF
CustomRoom7_Scr07_L4A92:
    dw $04B4
    dw $FF14  ; goto
    dw CustomRoom7_Scr07_L4ACC
CustomRoom7_Scr07_L4A98:
    dw $07C9
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom7_Scr07_L4AA6
    dw $07CA
    dw $FFFF
CustomRoom7_Scr07_L4AA6:
    dw $07CB
    dw $FF14  ; goto
    dw CustomRoom7_Scr07_L4ACC
CustomRoom7_Scr07_L4AAC:
    dw $07C9
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom7_Scr07_L4ABA
    dw $07CF
    dw $FFFF
CustomRoom7_Scr07_L4ABA:
    dw $07CB
    dw $FF14  ; goto
    dw CustomRoom7_Scr07_L4ACC
CustomRoom7_Scr07_L4AC0:
    dw $07D3
    dw $FF03  ; set_flag
    dw $00FE
    dw $FF14  ; goto
    dw CustomRoom7_Scr07_L4ACC
CustomRoom7_Scr07_L4ACA:
    dw $07D4
CustomRoom7_Scr07_L4ACC:
    dw $FF0D  ; opcode $0D
    dw $0004
    dw $0010
    dw $0000
    dw $FF0D  ; opcode $0D
    dw $0004
    dw $001A
    dw $0060
    dw $FF0D  ; opcode $0D
    dw $0004
    dw $0000
    dw $0000
    dw $FF09  ; delay
    dw $0010
    dw $FF0D  ; opcode $0D
    dw $0004
    dw $0000
    dw $0040
    dw $FFFF

CustomRoom7_Scr08:
    dw $FF01  ; if_flag_set
    dw $0111
    dw CustomRoom7_Scr08_L4AFC
    dw $00E9
    dw $FFFF
CustomRoom7_Scr08_L4AFC:
    dw $07D5
    dw $FFFF

CustomRoom7_Scr09:
    dw $FF01  ; if_flag_set
    dw $0111
    dw CustomRoom7_Scr09_L4B0A
    dw $00EA
    dw $FFFF
CustomRoom7_Scr09_L4B0A:
    dw $07D6
    dw $FFFF

CustomRoom7_Scr10:
    dw $FF48  ; npc_hide
    dw $0001
    dw $FF01  ; if_flag_set
    dw $00FF
    dw CustomRoom7_Scr10_L4CF8
    dw $FF01  ; if_flag_set
    dw $00F1
    dw CustomRoom7_Scr10_L4CF0
    dw $FF01  ; if_flag_set
    dw $0025
    dw CustomRoom7_Scr10_L4CEC
    dw $FF00  ; if_flag_clear
    dw $0037
    dw CustomRoom7_Scr10_L4B30
    dw $FF01  ; if_flag_set
    dw $0096
    dw CustomRoom7_Scr10_L4CE8
CustomRoom7_Scr10_L4B30:
    dw $FF01  ; if_flag_set
    dw $0096
    dw CustomRoom7_Scr10_L4CE4
    dw $FF01  ; if_flag_set
    dw $0095
    dw CustomRoom7_Scr10_L4CC6
    dw $FF01  ; if_flag_set
    dw $0037
    dw CustomRoom7_Scr10_L4CA4
    dw $FF01  ; if_flag_set
    dw $0036
    dw CustomRoom7_Scr10_L4C82
    dw $FF01  ; if_flag_set
    dw $0035
    dw CustomRoom7_Scr10_L4C7E
    dw $FF01  ; if_flag_set
    dw $008B
    dw CustomRoom7_Scr10_L4C7A
    dw $FF01  ; if_flag_set
    dw $008A
    dw CustomRoom7_Scr10_L4C5C
    dw $FF01  ; if_flag_set
    dw $0034
    dw CustomRoom7_Scr10_L4C3A
    dw $FF01  ; if_flag_set
    dw $0089
    dw CustomRoom7_Scr10_L4C36
    dw $FF01  ; if_flag_set
    dw $007E
    dw CustomRoom7_Scr10_L4C32
    dw $FF01  ; if_flag_set
    dw $001D
    dw CustomRoom7_Scr10_L4C2A
    dw $FF00  ; if_flag_clear
    dw $0058
    dw CustomRoom7_Scr10_L4B7E
    dw $FF01  ; if_flag_set
    dw $0119
    dw CustomRoom7_Scr10_L4D1E
CustomRoom7_Scr10_L4B7E:
    dw $FF00  ; if_flag_clear
    dw $0033
    dw CustomRoom7_Scr10_L4B8A
    dw $FF01  ; if_flag_set
    dw $0058
    dw CustomRoom7_Scr10_L4C26
CustomRoom7_Scr10_L4B8A:
    dw $FF01  ; if_flag_set
    dw $0058
    dw CustomRoom7_Scr10_L4C22
    dw $FF01  ; if_flag_set
    dw $004F
    dw CustomRoom7_Scr10_L4C04
    dw $FF00  ; if_flag_clear
    dw $0033
    dw CustomRoom7_Scr10_L4BA2
    dw $FF01  ; if_flag_set
    dw $0119
    dw CustomRoom7_Scr10_L4CFC
CustomRoom7_Scr10_L4BA2:
    dw $FF01  ; if_flag_set
    dw $0032
    dw CustomRoom7_Scr10_L4BE2
    dw $FF01  ; if_flag_set
    dw $0048
    dw CustomRoom7_Scr10_L4BDE
    dw $FF01  ; if_flag_set
    dw $0031
    dw CustomRoom7_Scr10_L4BDA
    dw $FF01  ; if_flag_set
    dw $0030
    dw CustomRoom7_Scr10_L4BD6
    dw $FF01  ; if_flag_set
    dw $0121
    dw CustomRoom7_Scr10_L4BC4
    dw $00ED
    dw $FFFF
CustomRoom7_Scr10_L4BC4:
    dw $044B
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom7_Scr10_L4BD2
    dw $086B
    dw $FFFF
CustomRoom7_Scr10_L4BD2:
    dw $086A
    dw $FFFF
CustomRoom7_Scr10_L4BD6:
    dw $017C
    dw $FFFF
CustomRoom7_Scr10_L4BDA:
    dw $01B9
    dw $FFFF
CustomRoom7_Scr10_L4BDE:
    dw $017D
    dw $FFFF
CustomRoom7_Scr10_L4BE2:
    dw $FF3C  ; opcode $3C
    dw $021F
    dw $FF03  ; set_flag
    dw $004F
    dw $FF03  ; set_flag
    dw $0058
    dw $FF42  ; opcode $42
    dw $0134
    dw $0001
    dw $FF04  ; opcode $04
    dw $0005
    dw $0600
    dw $FF02  ; clear_flag
    dw $0058
    dw $FF3C  ; opcode $3C
    dw $0600
    dw $FFFF
CustomRoom7_Scr10_L4C04:
    dw $FF3C  ; opcode $3C
    dw $022A
    dw $FF03  ; set_flag
    dw $0058
    dw $FF42  ; opcode $42
    dw $0134
    dw $0001
    dw $FF04  ; opcode $04
    dw $0005
    dw $0600
    dw $FF02  ; clear_flag
    dw $0058
    dw $FF3C  ; opcode $3C
    dw $0600
    dw $FFFF
CustomRoom7_Scr10_L4C22:
    dw $022B
    dw $FFFF
CustomRoom7_Scr10_L4C26:
    dw $027E
    dw $FFFF
CustomRoom7_Scr10_L4C2A:
    dw $02E4
    dw $FF03  ; set_flag
    dw $007E
    dw $FFFF
CustomRoom7_Scr10_L4C32:
    dw $02E5
    dw $FFFF
CustomRoom7_Scr10_L4C36:
    dw $02E6
    dw $FFFF
CustomRoom7_Scr10_L4C3A:
    dw $FF3C  ; opcode $3C
    dw $0344
    dw $FF03  ; set_flag
    dw $008A
    dw $FF03  ; set_flag
    dw $008B
    dw $FF42  ; opcode $42
    dw $0136
    dw $0001
    dw $FF04  ; opcode $04
    dw $0005
    dw $0600
    dw $FF02  ; clear_flag
    dw $008B
    dw $FF3C  ; opcode $3C
    dw $0600
    dw $FFFF
CustomRoom7_Scr10_L4C5C:
    dw $FF3C  ; opcode $3C
    dw $0854
    dw $FF03  ; set_flag
    dw $008B
    dw $FF42  ; opcode $42
    dw $0136
    dw $0001
    dw $FF04  ; opcode $04
    dw $0005
    dw $0600
    dw $FF02  ; clear_flag
    dw $008B
    dw $FF3C  ; opcode $3C
    dw $0600
    dw $FFFF
CustomRoom7_Scr10_L4C7A:
    dw $034F
    dw $FFFF
CustomRoom7_Scr10_L4C7E:
    dw $03A3
    dw $FFFF
CustomRoom7_Scr10_L4C82:
    dw $FF3C  ; opcode $3C
    dw $03F4
    dw $FF03  ; set_flag
    dw $0095
    dw $FF03  ; set_flag
    dw $0096
    dw $FF42  ; opcode $42
    dw $0139
    dw $0001
    dw $FF04  ; opcode $04
    dw $0005
    dw $0600
    dw $FF02  ; clear_flag
    dw $0096
    dw $FF3C  ; opcode $3C
    dw $0600
    dw $FFFF
CustomRoom7_Scr10_L4CA4:
    dw $FF3C  ; opcode $3C
    dw $0450
    dw $FF03  ; set_flag
    dw $0095
    dw $FF03  ; set_flag
    dw $0096
    dw $FF42  ; opcode $42
    dw $0139
    dw $0001
    dw $FF04  ; opcode $04
    dw $0005
    dw $0600
    dw $FF02  ; clear_flag
    dw $0096
    dw $FF3C  ; opcode $3C
    dw $0600
    dw $FFFF
CustomRoom7_Scr10_L4CC6:
    dw $FF3C  ; opcode $3C
    dw $0855
    dw $FF03  ; set_flag
    dw $0096
    dw $FF42  ; opcode $42
    dw $0139
    dw $0001
    dw $FF04  ; opcode $04
    dw $0005
    dw $0600
    dw $FF02  ; clear_flag
    dw $0096
    dw $FF3C  ; opcode $3C
    dw $0600
    dw $FFFF
CustomRoom7_Scr10_L4CE4:
    dw $03F7
    dw $FFFF
CustomRoom7_Scr10_L4CE8:
    dw $0451
    dw $FFFF
CustomRoom7_Scr10_L4CEC:
    dw $04B5
    dw $FFFF
CustomRoom7_Scr10_L4CF0:
    dw $07D7
    dw $FF03  ; set_flag
    dw $00FF
    dw $FFFF
CustomRoom7_Scr10_L4CF8:
    dw $07D8
    dw $FFFF
CustomRoom7_Scr10_L4CFC:
    dw $FF3C  ; opcode $3C
    dw $07D0
    dw $FF03  ; set_flag
    dw $004F
    dw $FF03  ; set_flag
    dw $0058
    dw $FF42  ; opcode $42
    dw $0134
    dw $0001
    dw $FF04  ; opcode $04
    dw $0005
    dw $0600
    dw $FF02  ; clear_flag
    dw $0058
    dw $FF3C  ; opcode $3C
    dw $0600
    dw $FFFF
CustomRoom7_Scr10_L4D1E:
    dw $0858
    dw $FFFF

CustomRoom7_Scr11:
    dw $FF01  ; if_flag_set
    dw $00FF
    dw CustomRoom7_Scr11_L4CF8
    dw $FF01  ; if_flag_set
    dw $00F1
    dw CustomRoom7_Scr11_L4CF0
    dw $FF01  ; if_flag_set
    dw $0025
    dw CustomRoom7_Scr11_L4CEC
    dw $FF00  ; if_flag_clear
    dw $0037
    dw CustomRoom7_Scr11_L4B30
    dw $FF01  ; if_flag_set
    dw $0096
    dw CustomRoom7_Scr11_L4CE8
CustomRoom7_Scr11_L4B30:
    dw $FF01  ; if_flag_set
    dw $0096
    dw CustomRoom7_Scr11_L4CE4
    dw $FF01  ; if_flag_set
    dw $0095
    dw CustomRoom7_Scr11_L4CC6
    dw $FF01  ; if_flag_set
    dw $0037
    dw CustomRoom7_Scr11_L4CA4
    dw $FF01  ; if_flag_set
    dw $0036
    dw CustomRoom7_Scr11_L4C82
    dw $FF01  ; if_flag_set
    dw $0035
    dw CustomRoom7_Scr11_L4C7E
    dw $FF01  ; if_flag_set
    dw $008B
    dw CustomRoom7_Scr11_L4C7A
    dw $FF01  ; if_flag_set
    dw $008A
    dw CustomRoom7_Scr11_L4C5C
    dw $FF01  ; if_flag_set
    dw $0034
    dw CustomRoom7_Scr11_L4C3A
    dw $FF01  ; if_flag_set
    dw $0089
    dw CustomRoom7_Scr11_L4C36
    dw $FF01  ; if_flag_set
    dw $007E
    dw CustomRoom7_Scr11_L4C32
    dw $FF01  ; if_flag_set
    dw $001D
    dw CustomRoom7_Scr11_L4C2A
    dw $FF00  ; if_flag_clear
    dw $0058
    dw CustomRoom7_Scr11_L4B7E
    dw $FF01  ; if_flag_set
    dw $0119
    dw CustomRoom7_Scr11_L4D1E
CustomRoom7_Scr11_L4B7E:
    dw $FF00  ; if_flag_clear
    dw $0033
    dw CustomRoom7_Scr11_L4B8A
    dw $FF01  ; if_flag_set
    dw $0058
    dw CustomRoom7_Scr11_L4C26
CustomRoom7_Scr11_L4B8A:
    dw $FF01  ; if_flag_set
    dw $0058
    dw CustomRoom7_Scr11_L4C22
    dw $FF01  ; if_flag_set
    dw $004F
    dw CustomRoom7_Scr11_L4C04
    dw $FF00  ; if_flag_clear
    dw $0033
    dw CustomRoom7_Scr11_L4BA2
    dw $FF01  ; if_flag_set
    dw $0119
    dw CustomRoom7_Scr11_L4CFC
CustomRoom7_Scr11_L4BA2:
    dw $FF01  ; if_flag_set
    dw $0032
    dw CustomRoom7_Scr11_L4BE2
    dw $FF01  ; if_flag_set
    dw $0048
    dw CustomRoom7_Scr11_L4BDE
    dw $FF01  ; if_flag_set
    dw $0031
    dw CustomRoom7_Scr11_L4BDA
    dw $FF01  ; if_flag_set
    dw $0030
    dw CustomRoom7_Scr11_L4BD6
    dw $FF01  ; if_flag_set
    dw $0121
    dw CustomRoom7_Scr11_L4BC4
    dw $00ED
    dw $FFFF
CustomRoom7_Scr11_L4BC4:
    dw $044B
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom7_Scr11_L4BD2
    dw $086B
    dw $FFFF
CustomRoom7_Scr11_L4BD2:
    dw $086A
    dw $FFFF
CustomRoom7_Scr11_L4BD6:
    dw $017C
    dw $FFFF
CustomRoom7_Scr11_L4BDA:
    dw $01B9
    dw $FFFF
CustomRoom7_Scr11_L4BDE:
    dw $017D
    dw $FFFF
CustomRoom7_Scr11_L4BE2:
    dw $FF3C  ; opcode $3C
    dw $021F
    dw $FF03  ; set_flag
    dw $004F
    dw $FF03  ; set_flag
    dw $0058
    dw $FF42  ; opcode $42
    dw $0134
    dw $0001
    dw $FF04  ; opcode $04
    dw $0005
    dw $0600
    dw $FF02  ; clear_flag
    dw $0058
    dw $FF3C  ; opcode $3C
    dw $0600
    dw $FFFF
CustomRoom7_Scr11_L4C04:
    dw $FF3C  ; opcode $3C
    dw $022A
    dw $FF03  ; set_flag
    dw $0058
    dw $FF42  ; opcode $42
    dw $0134
    dw $0001
    dw $FF04  ; opcode $04
    dw $0005
    dw $0600
    dw $FF02  ; clear_flag
    dw $0058
    dw $FF3C  ; opcode $3C
    dw $0600
    dw $FFFF
CustomRoom7_Scr11_L4C22:
    dw $022B
    dw $FFFF
CustomRoom7_Scr11_L4C26:
    dw $027E
    dw $FFFF
CustomRoom7_Scr11_L4C2A:
    dw $02E4
    dw $FF03  ; set_flag
    dw $007E
    dw $FFFF
CustomRoom7_Scr11_L4C32:
    dw $02E5
    dw $FFFF
CustomRoom7_Scr11_L4C36:
    dw $02E6
    dw $FFFF
CustomRoom7_Scr11_L4C3A:
    dw $FF3C  ; opcode $3C
    dw $0344
    dw $FF03  ; set_flag
    dw $008A
    dw $FF03  ; set_flag
    dw $008B
    dw $FF42  ; opcode $42
    dw $0136
    dw $0001
    dw $FF04  ; opcode $04
    dw $0005
    dw $0600
    dw $FF02  ; clear_flag
    dw $008B
    dw $FF3C  ; opcode $3C
    dw $0600
    dw $FFFF
CustomRoom7_Scr11_L4C5C:
    dw $FF3C  ; opcode $3C
    dw $0854
    dw $FF03  ; set_flag
    dw $008B
    dw $FF42  ; opcode $42
    dw $0136
    dw $0001
    dw $FF04  ; opcode $04
    dw $0005
    dw $0600
    dw $FF02  ; clear_flag
    dw $008B
    dw $FF3C  ; opcode $3C
    dw $0600
    dw $FFFF
CustomRoom7_Scr11_L4C7A:
    dw $034F
    dw $FFFF
CustomRoom7_Scr11_L4C7E:
    dw $03A3
    dw $FFFF
CustomRoom7_Scr11_L4C82:
    dw $FF3C  ; opcode $3C
    dw $03F4
    dw $FF03  ; set_flag
    dw $0095
    dw $FF03  ; set_flag
    dw $0096
    dw $FF42  ; opcode $42
    dw $0139
    dw $0001
    dw $FF04  ; opcode $04
    dw $0005
    dw $0600
    dw $FF02  ; clear_flag
    dw $0096
    dw $FF3C  ; opcode $3C
    dw $0600
    dw $FFFF
CustomRoom7_Scr11_L4CA4:
    dw $FF3C  ; opcode $3C
    dw $0450
    dw $FF03  ; set_flag
    dw $0095
    dw $FF03  ; set_flag
    dw $0096
    dw $FF42  ; opcode $42
    dw $0139
    dw $0001
    dw $FF04  ; opcode $04
    dw $0005
    dw $0600
    dw $FF02  ; clear_flag
    dw $0096
    dw $FF3C  ; opcode $3C
    dw $0600
    dw $FFFF
CustomRoom7_Scr11_L4CC6:
    dw $FF3C  ; opcode $3C
    dw $0855
    dw $FF03  ; set_flag
    dw $0096
    dw $FF42  ; opcode $42
    dw $0139
    dw $0001
    dw $FF04  ; opcode $04
    dw $0005
    dw $0600
    dw $FF02  ; clear_flag
    dw $0096
    dw $FF3C  ; opcode $3C
    dw $0600
    dw $FFFF
CustomRoom7_Scr11_L4CE4:
    dw $03F7
    dw $FFFF
CustomRoom7_Scr11_L4CE8:
    dw $0451
    dw $FFFF
CustomRoom7_Scr11_L4CEC:
    dw $04B5
    dw $FFFF
CustomRoom7_Scr11_L4CF0:
    dw $07D7
    dw $FF03  ; set_flag
    dw $00FF
    dw $FFFF
CustomRoom7_Scr11_L4CF8:
    dw $07D8
    dw $FFFF
CustomRoom7_Scr11_L4CFC:
    dw $FF3C  ; opcode $3C
    dw $07D0
    dw $FF03  ; set_flag
    dw $004F
    dw $FF03  ; set_flag
    dw $0058
    dw $FF42  ; opcode $42
    dw $0134
    dw $0001
    dw $FF04  ; opcode $04
    dw $0005
    dw $0600
    dw $FF02  ; clear_flag
    dw $0058
    dw $FF3C  ; opcode $3C
    dw $0600
    dw $FFFF
CustomRoom7_Scr11_L4D1E:
    dw $0858
    dw $FFFF

; --- $73 (island_copy) scripts ---
CustomRoom8_ScriptPtrTable:
    dw CustomRoom8_Scr00   ; [0] arm_encounters
    dw CustomRoom8_Scr01   ; [1] give_jerky
    dw CustomRoom8_Scr02   ; [2] give_egg
    dw CustomRoom8_Scr03   ; [3] bgm_change

CustomRoom8_Scr00:
    dw $FF13  ; write_ram2
    dw $CA39
    dw $04B0
    dw $FFFF

CustomRoom8_Scr01:
    dw $0A00  ; item offer [Y/N]
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom8_Scr01_declined
    dw $FF2C  ; check_inv_full
    dw CustomRoom8_Scr01_invFull
    dw $FF2A  ; give_item
    dw ITEM_BEEF_JERKY
    dw $0A01  ; item given
    dw $FFFF
CustomRoom8_Scr01_invFull:
    dw $0A06  ; inventory full
    dw $FFFF
CustomRoom8_Scr01_declined:
    dw $0A02  ; declined
    dw $FFFF

CustomRoom8_Scr02:
    dw $0A07  ; monster offer [Y/N]
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom8_Scr02_declined
    dw $FF28  ; check_storage_full
    dw CustomRoom8_Scr02_storageFull
    dw $FF29  ; add_monster
    dw $015E
    dw $0A08  ; monster joined
    dw $FFFF
CustomRoom8_Scr02_storageFull:
    dw $0A10  ; monster storage full
    dw $FFFF
CustomRoom8_Scr02_declined:
    dw $0A09  ; monster declined
    dw $FFFF

CustomRoom8_Scr03:
    dw $0A0D  ; BGM change offer [Y/N]
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom8_Scr03_declined
    dw $FF41  ; set_bgm
    dw $009E
    dw $0A0E  ; BGM changed
    dw $FFFF
CustomRoom8_Scr03_declined:
    dw $0A0F  ; BGM declined
    dw $FFFF

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
    dw CustomText_18   ; $0A18: S70 cutscene line 1
    dw CustomText_19   ; $0A19: S70 cutscene line 2
    dw CustomText_1A   ; $0A1A: requires $CA8D==1 refusal
    dw CustomText_1B   ; $0A1B: quest YES/NO offer
    dw CustomText_1C   ; $0A1C: 
    dw CustomText_1D   ; $0A1D: 
    dw CustomText_1E   ; $0A1E: win tail; GoldSlime joins engine-side (phase $0D)
    dw CustomText_1F   ; $0A1F: 
    dw CustomText_20   ; $0A20: [S73] Anchor gate-side confirm [Y/N]
    dw CustomText_21   ; $0A21: [S73] Anchor return confirm [Y/N] — charge lands on arrival
    dw CustomText_22   ; $0A22: [S73] cast in a special/boss/custom gate room
    dw CustomText_23   ; $0A23: [S73] cast in town with no stored anchor

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

; $0A18 — S70 cutscene line 1
CustomText_18:
    db $EA, $9F, $A3
    db "Bwoing?!", $EF, $EE
    db "An intruder in", $EF, $EE
    db "the Medal Chamber!", $F7, $F0

; $0A19 — S70 cutscene line 2
CustomText_19:
    db $EA, $9F, $A3
    db "I am GoldSlime,", $EF, $EE
    db "keeper of the", $EF, $EE
    db "shiniest hoard!", $F7, $F0

; $0A1A — requires $CA8D==1 refusal
CustomText_1A:
    db $EA, $9F, $A3
    db "Face me alone!", $EF, $EE
    db "Bring exactly", $EF, $EE
    db "one monster.", $F7, $F0

; $0A1B — quest YES/NO offer
CustomText_1B:
    db $EA, $9F, $A3
    db "You smell of", $EF, $EE
    db "medals...", $EF, $EE
    db "Challenge me?", $EF, $EE, $E7, $F0

; $0A1C
CustomText_1C:
    db $EA, $9F, $A3
    db "Then leave my", $EF, $EE
    db "shinies alone!", $F7, $F0

; $0A1D
CustomText_1D:
    db $EA, $9F, $A3
    db "Bwoing!", $EF, $EE
    db "For the hoard!", $F7, $F0

; $0A1E — win tail; GoldSlime joins engine-side (phase $0D)
CustomText_1E:
    db $EA, $9F, $A3
    db "Bwoing...", $EF, $EE
    db "You win. I shall", $EF, $EE
    db "guard YOU now!", $F7, $F0

; $0A1F
CustomText_1F:
    db $EA, $9F, $A3
    db "The chamber is", $EF, $EE
    db "quiet. The", $EF, $EE
    db "shinies sleep.", $F7, $F0

; $0A20 — [S73] Anchor gate-side confirm [Y/N]
CustomText_20:
    db $EA, $9F, $A3
    db "Set an anchor", $EF, $EE
    db "here and warp", $EF, $EE
    db "to GreatTree?", $EF, $EE, $E7, $F0

; $0A21 — [S73] Anchor return confirm [Y/N] — charge lands on arrival
CustomText_21:
    db $EA, $9F, $A3
    db "Spend most MP", $EF, $EE
    db "to return to the", $EF, $EE
    db "anchored floor?", $EF, $EE, $E7, $F0

; $0A22 — [S73] cast in a special/boss/custom gate room
CustomText_22:
    db $EA, $9F, $A3
    db "The anchor", $EF, $EE
    db "fails here!", $F7, $F0

; $0A23 — [S73] cast in town with no stored anchor
CustomText_23:
    db $EA, $9F, $A3
    db "No anchor", $EF, $EE
    db "is set!", $F7, $F0

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
    db $04   ; $71 — medal_vault
    db $06   ; $72 — arena_clone
    db $04   ; $73 — island_copy

CustomRoomPtrTable:
    dw CustomRoom0_SubTable   ; $6B
    dw CustomRoom1_SubTable   ; $6C
    dw CustomRoom2_SubTable   ; $6D
    dw CustomRoomDummy_SubTable   ; $6E
    dw CustomRoomDummy_SubTable   ; $6F
    dw CustomRoom5_SubTable   ; $70
    dw CustomRoom6_SubTable   ; $71
    dw CustomRoom7_SubTable   ; $72
    dw CustomRoom8_SubTable   ; $73

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

; --- $71 (medal_vault) room data ---
CustomRoom6_SubTable:
    dw CustomRoom6_Screen0
    dw $FFFF, $FFFF, $FFFF

CustomRoom6_Screen0:
    dw wCustomStep_Room71_S0    ; step counter
    db 7, $64   ; step_id, tileset_bank
    dw CustomRoom6_S0_NPCs
    dw CustomRoom6_S0_Exits

CustomRoom6_S0_NPCs:
    db $8F, $FF, $07, $06, $00  ; spawn (7,6)
    db $00, $23, $04, $03, $01  ; NPC (4,3) script quest:medal_vault
    db $FF

CustomRoom6_S0_Exits:
    db $07, $06, $16, $00, $00, $01, $02  ; back to MedalMan (1,2) vault-door tile; spawn-on-exit-tile is vanilla-precedented (SecretPassage->MedalMan lands on the north exit)
    db $08, $03, $72, $00, $01, $04, $07  ; S92 staircase (visible, metatile 8,3) -> arena_clone; sb/spawn copied from the vanilla GreatTree->Lobby exit
    db $FF

; --- $72 (arena_clone) room data ---
CustomRoom7_SubTable:
    dw CustomRoom7_Screen0
    dw CustomRoom7_Screen1
    dw CustomRoom7_Screen2
    dw $FFFF

CustomRoom7_Screen0:
    dw wCustomStep_Room72_S0    ; step counter
    db 15, $29   ; step_id, tileset_bank
    dw CustomRoom7_S0_NPCs
    dw CustomRoom7_S0_Exits

CustomRoom7_S0_NPCs:
    db $90, $FF, $05, $04, $01  ; walkon_exit (5,4) [vanilla verbatim]
    db $50, $E0, $05, $04, $FF  ; npc (5,4) [vanilla verbatim]
    db $70, $E1, $03, $05, $02  ; npc (3,5) [vanilla verbatim]
    db $40, $E2, $02, $04, $03  ; npc (2,4) [vanilla verbatim]
    db $50, $E3, $03, $03, $04  ; npc (3,3) [vanilla verbatim]
    db $FF

CustomRoom7_S0_Exits:
    db $05, $00, $07, $00, $04, $05, $07  ; vanilla exit -> map $07 [verbatim]
    db $FF

CustomRoom7_Screen1:
    dw wCustomStep_ArenaClone_S1    ; step counter
    db 16, $29   ; state 0: step_id, tileset_bank — rank 0 (vanilla clone content)
    dw CustomRoom7_S1_V0_NPCs
    dw CustomRoom7_S1_V0_Exits
    db 16, $29   ; state 1: step_id, tileset_bank — rank G+ (flag $0030): the right-hand attendant ($12 at 7,6) LEAVES — visible-by-removal (S92v5: the previous swap target $54 renders empty in field contexts, S91 catalog)
    dw CustomRoom7_S1_V1_NPCs
    dw CustomRoom7_S1_V1_Exits

CustomRoom7_S1_V0_NPCs:
    db $8F, $FF, $04, $02, $05  ; spawn_point (4,2) [vanilla verbatim]
    db $8F, $FF, $05, $02, $05  ; spawn_point (5,2) [vanilla verbatim]
    db $8F, $FF, $03, $04, $06  ; spawn_point (3,4) [vanilla verbatim]
    db $8F, $FF, $06, $06, $07  ; spawn_point (6,6) [vanilla verbatim]
    db $37, $12, $02, $04, $08  ; npc (2,4) [vanilla verbatim]
    db $17, $12, $07, $06, $09  ; npc (7,6) [vanilla verbatim]
    db $60, $11, $04, $08, $0E  ; npc (4,8) [vanilla verbatim]
    db $40, $54, $06, $05, $FF  ; npc (6,5) [vanilla verbatim]
    db $FF

CustomRoom7_S1_V0_Exits:
    db $04, $07, $01, $00, $84, $04, $03  ; vanilla exit -> map $01 [verbatim]
    db $05, $07, $01, $00, $84, $05, $03  ; vanilla exit -> map $01 [verbatim]
    db $FF

CustomRoom7_S1_V1_NPCs:
    db $8F, $FF, $04, $02, $05  ; spawn_point (4,2) [vanilla verbatim]
    db $8F, $FF, $05, $02, $05  ; spawn_point (5,2) [vanilla verbatim]
    db $8F, $FF, $03, $04, $06  ; spawn_point (3,4) [vanilla verbatim]
    db $8F, $FF, $06, $06, $07  ; spawn_point (6,6) [vanilla verbatim]
    db $37, $12, $02, $04, $08  ; npc (2,4) [vanilla verbatim]
    db $60, $11, $04, $08, $0E  ; npc (4,8) [vanilla verbatim]
    db $40, $54, $06, $05, $FF  ; npc (6,5) [vanilla verbatim]
    db $FF

CustomRoom7_S1_V1_Exits:
    db $04, $07, $01, $00, $84, $04, $03  ; vanilla exit -> map $01 [verbatim]
    db $05, $07, $01, $00, $84, $05, $03  ; vanilla exit -> map $01 [verbatim]
    db $FF

CustomRoom7_Screen2:
    dw wCustomStep_Room72_S2    ; step counter
    db 17, $29   ; step_id, tileset_bank
    dw CustomRoom7_S2_NPCs
    dw CustomRoom7_S2_Exits

CustomRoom7_S2_NPCs:
    db $82, $FF, $06, $05, $0A  ; marker_82 (6,5) [vanilla verbatim]
    db $00, $0B, $06, $04, $0B  ; npc (6,4) [vanilla verbatim]
    db $FF

CustomRoom7_S2_Exits:
    db $04, $00, $07, $00, $06, $04, $07  ; vanilla exit -> map $07 [verbatim]
    db $FF

; --- $73 (island_copy) room data ---
CustomRoom8_SubTable:
    dw CustomRoom8_Screen0
    dw $FFFF, $FFFF, $FFFF
    dw CustomRoom8_Screen4
    dw $FFFF, $FFFF, $FFFF

CustomRoom8_Screen0:
    dw wCustomStep_Room73_S0    ; step counter
    db 0, $64   ; step_id, tileset_bank
    dw CustomRoom8_S0_NPCs
    dw CustomRoom8_S0_Exits

CustomRoom8_S0_NPCs:
    db $8F, $FF, $07, $06, $00  ; spawn (7,6)
    db $00, $0B, $02, $07, $01  ; NPC (2,7) script give_jerky
    db $00, $0B, $05, $06, $03  ; NPC (5,6) script bgm_change
    db $FF

CustomRoom8_S0_Exits:
    db $03, $01, $6C, $00, $00, $07, $06  ; exit (3,1) -> Room $6C screen 0 spawn (7,6); screen_byte $00 = in-room ($2DE7[0]); $01 stranded the player off-map (KEY_LESSONS S40)
    db $FF

CustomRoom8_Screen4:
    dw wCustomStep_Room73_S4    ; step counter
    db 2, $64   ; step_id, tileset_bank
    dw CustomRoom8_S4_NPCs
    dw CustomRoom8_S4_Exits

CustomRoom8_S4_NPCs:
    db $8F, $FF, $05, $03, $00  ; spawn (5,3)
    db $00, $09, $05, $04, $02  ; NPC (5,4) script give_egg
    db $FF

CustomRoom8_S4_Exits:
    db $03, $07, $01, $00, $08, $04, $05  ; south edge exit (3,7) -> GreatTree screen 8 (screen_byte $08 copied from WellStairway per KEY_LESSONS v14-v18)
    db $FF

; =============================================================================
; VANILLA-ROOM EXIT EXTENSIONS (S70, generated)
; Read by bank $60 entry 7 (VanillaExitResolve, template head) on
; EVERY non-gate room step via bank $0B RoomEntry6_ExitChecker.
; Variant selected by [step_counter], clamped to n_steps-1.
; Lists are copied to wCustomExitBuffer (<= 17 rows + terminator).
; =============================================================================
VanillaExitExtTable:
    db $16   ; mapID — MedalMan + Medal Vault door at (1,2); per-step lists mirror disassembly Exit_MedalManRoom_s0/_v1/_v2 (steps 0/1-2-4-5/3) + the door row
    dw $D95E   ; vanilla step counter (WRAM)
    db 6   ; n_steps (variant count)
    dw VExt16_V0, VExt16_V1, VExt16_V1, VExt16_V2, VExt16_V1, VExt16_V1   ; per-step variant lists (deduped)
    db $FF   ; table terminator

VExt16_V0:
    db $03, $07, $01, $00, $81, $03, $02  ; vanilla south exit -> GreatTree (INERT here: y=7 = Entry 9 path, unchanged vanilla list serves it; kept for list parity)
    db $01, $02, $71, $00, $00, $07, $06  ; S70 Medal Vault door -> room $71 spawn (7,6)
    db $FF

VExt16_V1:
    db $03, $07, $01, $00, $81, $03, $02  ; vanilla south exit -> GreatTree (INERT here: y=7 = Entry 9 path, unchanged vanilla list serves it; kept for list parity)
    db $03, $01, $0A, $00, $01, $03, $07  ; vanilla north exit -> SecretPassage
    db $01, $06, $11, $01, $00, $00, $00  ; vanilla Medal Gate portal (gate_flag=1, vanilla dest)
    db $01, $02, $71, $00, $00, $07, $06  ; S70 Medal Vault door -> room $71 spawn (7,6)
    db $FF

VExt16_V2:
    db $03, $07, $01, $00, $81, $03, $02  ; vanilla south exit -> GreatTree (INERT here: y=7 = Entry 9 path, unchanged vanilla list serves it; kept for list parity)
    db $03, $01, $0A, $00, $01, $03, $07  ; vanilla north exit -> SecretPassage
    db $01, $02, $71, $00, $00, $07, $06  ; S70 Medal Vault door -> room $71 spawn (7,6)
    db $FF

