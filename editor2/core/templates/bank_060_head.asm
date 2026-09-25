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
;   Entry 8: CustomStateRules   — S97: flag-driven room states (P3.5a); writes
;            the current screen's step counter from CustomStateRulePtrTable
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
    dw CustomStateRules     ; Entry 8 — S97 state rules (bank $17 CustomAttrCheck + CustomReadStep call it)

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
    call CustomStateRules        ; S97: flag rules pick the state BEFORE the counter read
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
; Entry 8: CustomStateRules  (S97 — ROADMAP P3.5a, declarative room states)
; =============================================================================
; Custom-room step counters live in the transient $CD80 window (zeroed at every
; save-restore, PROJECT_COMPILER §2.6), so a state reached by a script is lost
; on reload. Event flags persist. This routine re-derives the CURRENT screen's
; state from flags: the compiler emits, per custom room, a list of screens that
; carry rules, each with an ordered rule list; the FIRST rule whose terms all
; hold writes its state into that screen's step counter. No match = counter
; untouched (scripts that write_ram the counter keep working until the next
; load). Idempotent, so it runs from every custom (re)load path:
;   * bank $17 CustomAttrCheck (the FIRST custom hook of a room load — the
;     attr/palette walk reads the counter before bank $0B Entry 0 does,
;     PyBoy-measured S97), via StateRulesHook17 + rst $10 entry 8;
;   * CustomReadStep (Entry 0) itself, before CustomPtrChase.
; Tables (generated, bank $60):
;   CustomStateRulePtrTable: dw per custom room (mapID - $6B), $0000 = none
;   room list:  { db screen / dw step_counter / dw rules } ... db $FF
;   rules:      { db state / db n_terms / n_terms x dw flag } ... db $FF
;               flag word: bits 0-14 = event flag index, bit 15 = must be CLEAR
;               (n_terms 0 = always).
; Clobbers A/BC/DE/HL (callers preserve what they need).
CustomStateRules:
    ld a, [wMapID]
    sub CUSTOM_ROOM_START
    ret c                        ; not a custom room (defensive)
    add a
    ld hl, CustomStateRulePtrTable
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    or h
    ret z                        ; room has no rules
.screen:
    ld a, [hl+]
    cp $FF
    ret z                        ; this screen has no rules
    ld b, a
    ld a, [wScreenIndex]
    cp b
    jr z, .found
    inc hl                       ; skip dw counter + dw rules
    inc hl
    inc hl
    inc hl
    jr .screen
.found:
    ld e, [hl]
    inc hl
    ld d, [hl]                   ; DE = step counter address
    inc hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a                      ; HL = rule list
.rule:
    ld a, [hl+]                  ; target state
    cp $FF
    ret z                        ; no rule matched: counter untouched
    push de                      ; [sp+2] counter
    push af                      ; [sp]   A = state
    ld a, [hl+]                  ; n_terms
    or a
    jr z, .match                 ; no terms = always
.term:
    push af                      ; terms left (incl. this one)
    ld c, [hl]
    inc hl
    ld b, [hl]
    inc hl
    push hl
    ld a, b
    and $80
    ld d, a                      ; D bit 7 = term wants the flag CLEAR
    res 7, b
    call TestEventFlag           ; Z = clear, NZ = set (clobbers A, HL)
    pop hl
    jr z, .isClear
    bit 7, d
    jr nz, .fail                 ; set, but must be clear
    jr .next
.isClear:
    bit 7, d
    jr z, .fail                  ; clear, but must be set
.next:
    pop af
    dec a
    jr nz, .term
.match:
    pop af                       ; A = state
    pop de                       ; DE = counter
    ld [de], a
    ret
.fail:
    pop af                       ; terms left incl. the failed one
    dec a
    add a                        ; skip the remaining terms (2 B each)
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    pop af                       ; drop the state
    pop de                       ; DE = counter again
    jr .rule

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
;       row: db mapID, screen ($FF = any) / dw step_counter_addr / db n_steps /
;            dw list0..listN-1; table terminated by db $FF.
;       Match (mapID AND wScreenIndex): variant = min([counter], n-1),
;       copy that 7-byte exit list to wCustomExitBuffer, return HL=buffer.
;       No match: HL=0.
; S94b: bank $0B Entry 9 (boundary y=0/7 push exits) calls this entry too, so
; extension rows with trigger_y 0/7 are LIVE (they were inert before S94b).
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
    jr nz, .skipRow
    ; S94b: rows are keyed per SCREEN too — db mapID, screen ($FF = any
    ; screen, the S70 semantics). Multi-screen vanilla rooms (GreatTree)
    ; can now have one door redirected without cross-firing on the other
    ; floors (the S92 wholesale-replacement trap, KEY_LESSONS S92).
    ld a, [hl]                  ; screen byte
    cp $FF
    jr z, .match
    ld b, a
    ld a, [wScreenIndex]
    cp b
    jr z, .match
.skipRow:
    inc hl                      ; skip screen (1)
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
    inc hl                      ; past the screen byte
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

