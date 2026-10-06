; =============================================================================
; BANK $60 — CUSTOM ROOM OVERFLOW BANK
; =============================================================================
; Entry points (called via rst $10):
;   Entry 0: CustomReadStep     — returns DE = [step_id, tileset_bank]
;   Entry 1: CustomReadInteract — copies NPC data to wCustomNPCBuffer (S117:
;            every non-gate room; flag-conditioned NPCs; vanilla NPC overrides)
;   Entry 2: CustomExitCheck    — copies exit data to wCustomExitBuffer
;   Entry 3: CustomTilesetInfo  — returns source mapID from wCustomRoomFlag
;   Entry 4: CustomScriptRead   — triple-index script data reader
;   Entry 5: CustomTextDisplay  — custom text renderer via ROM0 CallTextEngine
;   Entry 6: GateAwareDispatch  — B-fix: bank-$0F script dispatch routed by wMapID
;   Entry 7: VanillaExitResolve — S70: unified exit resolve (custom rooms AND
;            compiler-authored vanilla-room exit EXTENSIONS; HL=list or 0)
;   Entry 8: CustomStateRules   — S97: flag-driven room states (P3.5a); writes
;            the current screen's step counter from CustomStateRulePtrTable
;   Entry 9: CustomDrawTiles    — S119: script op $24 (tile patch) in a custom room
;   Entry 10: CustomDrawAttrs   — S119: script op $61 (the patch's colours)
;   Entry 11: NpcColourDraw     — S123: the field NPC draw (bank $06) with the
;            NPC colours of the room's $A2 prefixes (any of the 8 OBJ palettes)
;   Entry 12: CustomDescentFeel — S123 r2: bank $0B CustomDescentInGate's body —
;            only a STAIRS-DOWN exit of a custom room is an in-gate floor change
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
    dw CustomDrawTiles      ; Entry 9 — S119 op $24 in custom rooms (bank $04 ScriptCmd24 same-size redirect)
    dw CustomDrawAttrs      ; Entry 10 — S119 op $61 in custom rooms (bank $04 ScriptCmd61 same-size redirect)
    dw NpcColourDraw        ; Entry 11 — S123 NPC colours (bank $06 NPCDrawSlot same-size redirect)
    dw CustomDescentFeel    ; Entry 12 — S123 r2 gate-flag exit feel (bank $0B CustomDescentInGate far-calls it)

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
    ; S117 (NG2): reached for EVERY non-gate room (bank $0B GetRoomDataPtr,
    ; same-size rewrite — the exits' entry-7 pattern). Returns HL = the NPC /
    ; interact list to parse (wCustomNPCBuffer) or HL = 0 = "no override —
    ; run the vanilla SharedPtrChase path". rst $10 keeps HL, clobbers A.
    ld a, [wMapID]
    cp CUSTOM_ROOM_START
    jr c, .vanilla
    call CustomPtrChase
    inc hl
    inc hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jr CopyNPCListToBuffer
.vanilla:
    ; VanillaNPCExtTable (compiler-generated, bank $60): the vanilla rooms
    ; whose gate-swirl objects follow a project gate's "cleared" flag (a
    ; portal re-bossed or re-routed). Row format = VanillaExitExtTable's:
    ; db mapID, screen / dw step_counter / db n_steps / dw list0..listN-1;
    ; db $FF ends the table. Variant = min([counter], n-1).
    ld c, a
    ld hl, VanillaNPCExtTable
.scan:
    ld a, [hl+]
    cp $FF
    jr z, .none
    cp c
    jr nz, .skipRow
    ld a, [hl]
    ld b, a
    ld a, [wScreenIndex]
    cp b
    jr z, .match
.skipRow:
    inc hl                      ; screen
    inc hl                      ; step counter (2)
    inc hl
    ld a, [hl+]                 ; n_steps
    add a
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
    inc hl
    ld a, [hl+]
    ld e, a
    ld a, [hl+]
    ld d, a                     ; DE = the screen's vanilla step counter
    ld a, [hl+]
    ld b, a                     ; B = n_steps
    ld a, [de]
    cp b
    jr c, .stepOk
    ld a, b
    dec a
.stepOk:
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a                     ; HL = the variant's list (ROM, bank $60)
    ; fall through

; -----------------------------------------------------------------------------
; CopyNPCListToBuffer (S117) — HL = a 5-byte interact list ($FF-terminated)
; -> wCustomNPCBuffer, returns HL = the buffer. CONDITION PREFIXES: an entry
; whose byte 0 is $A0 / $A1 is not copied; it says "the NEXT NPC is shown only
; while flag [byte1 | byte2 << 8] is SET ($A0) / CLEAR ($A1)". Several
; prefixes AND together. A failed condition sets the NPC's HIDDEN bit (type
; bit 6 — measured S97: not drawn, not solid, no behaviour, no talk), so the
; slot numbers of every later NPC are unchanged. Examine / step spots (bit 7)
; are copied verbatim. The engine never sees a prefix (bit 7 set + $A_ is no
; vanilla interact kind; both bank $0B scans stop at the first NPC anyway).
; S123 — COLOUR PREFIX: `$A2, palette, flag lo, flag hi, $FF` = the NEXT NPC is
; drawn in OBJ palette 0-7 instead of its sprite's own (flag $FFFF = always,
; else only while that flag is SET). The colours go to wNpcColour[slot] (slot =
; the NPC's place among the list's NPC entries — spots take no slot, hidden
; NPCs keep theirs: bank $0B Call_00b_477e) tagged with wMapID / wScreenIndex;
; entry 11 NpcColourDraw applies them at draw time.
; Clobbers A/BC/DE.
; -----------------------------------------------------------------------------
CopyNPCListToBuffer:
    push hl
    ld hl, wNpcColour
    xor a
    ld c, 8
.clearColour:
    ld [hl+], a
    dec c
    jr nz, .clearColour
    ld [wNpcColourNext], a
    ld [wNpcColourK], a
    ld a, [wMapID]
    ld [wNpcColourMap], a
    ld a, [wScreenIndex]
    ld [wNpcColourScr], a
    pop hl
    ld de, wCustomNPCBuffer
    ld b, $00                   ; B = $40 when the next NPC must be hidden
.copyNPC:
    ld a, [hl]
    cp $FF
    jr z, .npcDone
    cp $A2
    jp z, .colour
    and $FE
    cp $A0
    jr z, .cond
    ld a, [hl+]
    bit 7, a
    jr nz, .verbatim            ; a spot: never hidden, takes no NPC slot
    or b
    ld b, $00
    call NpcColourRecord        ; S123: this NPC's colour -> wNpcColour[slot]
.verbatim:
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
.cond:
    ld a, [hl+]                 ; $A0 = must be SET, $A1 = must be CLEAR
    push de
    and $01
    ld d, a                     ; D = 1: the flag must be clear
    ld e, b                     ; E = hide so far
    ld c, [hl]
    inc hl
    ld b, [hl]                  ; BC = flag index
    inc hl
    inc hl                      ; bytes 3-4 are padding
    inc hl
    push hl
    call TestEventFlag          ; Z = clear, NZ = set (A/HL clobbered; BC/DE kept)
    pop hl
    ld a, d
    jr z, .isClear
    or a
    jr nz, .fail                ; set, but must be clear
    jr .condOk
.isClear:
    or a
    jr z, .fail                 ; clear, but must be set
    jr .condOk
.fail:
    ld e, $40
.condOk:
    ld b, e
    pop de
    jr .copyNPC
.colour:
    inc hl                      ; S123: $A2, palette, flag lo, flag hi, $FF
    ld a, [hl+]
    and $07
    or $80
    push de
    ld d, a                     ; D = $80 | palette
    ld a, [hl+]
    ld c, a
    ld a, [hl+]
    inc hl                      ; byte 4 is padding
    push hl
    ld e, b                     ; E = hide so far
    ld b, a                     ; BC = flag index ($FFFF = always)
    and c
    inc a
    jr z, .colourOn
    call TestEventFlag          ; Z = clear, NZ = set (A/HL clobbered; BC/DE kept)
    jr z, .colourOff
.colourOn:
    ld a, d
    ld [wNpcColourNext], a
.colourOff:
    ld b, e
    pop hl
    pop de
    jp .copyNPC
.npcDone:
    ld a, $FF
    ld [de], a
    ld hl, wCustomNPCBuffer
    ret

; NpcColourRecord (S123) — CopyNPCListToBuffer met an NPC entry: its slot
; (wNpcColourK, the NPC entries so far) takes the pending colour. Keeps A/BC/DE/HL.
NpcColourRecord:
    push af
    push hl
    ld a, [wNpcColourK]
    cp 8
    jr nc, .full
    ld l, a
    inc a
    ld [wNpcColourK], a
    ld h, $00
    push de
    ld de, wNpcColour
    add hl, de
    pop de
    ld a, [wNpcColourNext]
    ld [hl], a
    xor a
    ld [wNpcColourNext], a
.full:
    pop hl
    pop af
    ret

; -----------------------------------------------------------------------------
; Entry 12: CustomDescentFeel (S123 r2; user: "The entry into the custom gate …
; should be a full start-of-gate effect (screen whirling around and slowly
; vanishing) instead of go-down-a-floor effect (screen closing with a whoosh
; sound)"). Called by bank $0B CustomDescentInGate at the gate-flag exit
; transition (jr_00b_466b). Since S41 that routine set wInGateworld = $01 for
; EVERY gate-flag exit of a custom room, so the transition reads "already in a
; gate" -> the floor-change ladder ($C905 states $10-$17, sound $55). That is
; right for a STAIRS-DOWN cell (gate flag $80) but wrong for a GATE ENTRANCE
; (gate flag 1, dest = the gate): there the vanilla portal flow must run as from
; a vanilla portal room ($C905 states 1-6, the whirl) — wInGateworld stays 0.
; Measured (PyBoy): vanilla room $24 portal = states 1..6; a custom-room portal
; before this fix = $10..$17. Clobbers A only.
; -----------------------------------------------------------------------------
CustomDescentFeel:
    ld a, [wMapID]
    cp CUSTOM_ROOM_START
    ret c                       ; vanilla source rooms: untouched (as since S41)
    ld a, [wWarpFlag]
    bit 7, a                    ; $80 = Stairs down (an in-gate floor change)
    ret z                       ; 1 = a gate entrance: the game's own gate entry
    ld a, $01
    ld [wInGateworld], a        ; transient: the in-gate floor change feel
    ret

; -----------------------------------------------------------------------------
; Entry 11: NpcColourDraw (S123) — bank $06 NPCDrawSlot (was SaveMapS_4d0a), the field draw of one
; NPC slot (non-monster), far-calls this instead of bank $05 entry 0 (same-size:
; `ld hl, $0500` -> `ld hl, $600B`). DE = the slot + $0F. The NPC is drawn by
; bank $05 entry 0 exactly as before; then, if the last CopyNPCListToBuffer was
; for THIS map and screen (never on gate floors) and gave this slot a colour,
; the palette bits (attr bits 0-2) of the OAM buffer entries the draw added
; ($C000 + 4 * index, index from the $FFCB counter before to after) become it.
; Clobbers A/BC/HL (as the bank $05 call did); keeps DE.
; -----------------------------------------------------------------------------
NpcColourDraw:
    ld a, [wInGateworld]
    or a
    jr nz, .plain
    ld a, [wNpcColourMap]
    ld b, a
    ld a, [wMapID]
    cp b
    jr nz, .plain
    ld a, [wNpcColourScr]
    ld b, a
    ld a, [wScreenIndex]
    cp b
    jr nz, .plain
    ld a, e
    sub LOW($D7D2 + $0F)        ; slot k: DE = $D7D2 + 32k + $0F
    and $E0
    swap a
    srl a                       ; A = slot 0-7
    ld hl, wNpcColour
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    bit 7, a
    jr z, .plain
    and $07
    ld c, a                     ; C = palette
    ldh a, [$CB]
    ld b, a                     ; B = first OAM index of this draw
    push de
    push bc
    ld hl, $0500
    rst $10                     ; bank $05 entry 0 (keeps DE; A/BC clobbered)
    pop bc
    ldh a, [$CB]
    sub b
    jr z, .done
    jr c, .done
    ld e, a                     ; E = pieces drawn
    ld a, b
    add a
    add a
    add $03
    ld l, a
    ld h, $C0                   ; HL = attr byte of the first piece
.recolour:
    ld a, [hl]
    and $F8
    or c
    ld [hl+], a
    inc hl
    inc hl
    inc hl
    dec e
    jr nz, .recolour
.done:
    pop de
    ret
.plain:
    ld hl, $0500
    rst $10
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
; S101: first writes the screen's MONSTER CAST (CustomMonsterCast below) —
; the same load hooks run before the bank $0B NPC parse reads it.
CustomStateRules:
    call CustomMonsterCast
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

; -----------------------------------------------------------------------------
; CustomMonsterCast (S101) — MONSTER NPCs (a species drawn with its follower
; art). The bank $0B NPC sheet resolver maps sprite ids $F0-$F3 to the
; display-list pairs at $D7CA + 2n ([draw id, is_monster]; is_monster != 0 ->
; draw id = species+$10, follower sheet + layout + palette — the arena lobby's
; own mechanism, ROOM_DATA_FORMAT "Monster NPCs"). Custom rooms carry a
; generated per-screen cast: CustomMonsterCastPtrTable (dw per room, $0000 =
; none) -> { db screen / 8 bytes = 4 pairs } ... db $FF. The pairs of the
; current wScreenIndex are copied to $D7CA-$D7D1 at every custom load, before
; the NPC parse; screens without a cast leave the list alone.
; -----------------------------------------------------------------------------
CustomMonsterCast:
    ld a, [wMapID]
    sub CUSTOM_ROOM_START
    ret c
    add a
    ld hl, CustomMonsterCastPtrTable
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    or h
    ret z                        ; room has no monster NPCs
.scr:
    ld a, [hl+]
    cp $FF
    ret z                        ; this screen has no cast
    ld b, a
    ld a, [wScreenIndex]
    cp b
    jr z, .copy
    ld a, l
    add 8
    ld l, a
    ld a, $00
    adc h
    ld h, a
    jr .scr
.copy:
    ld de, $d7ca
    ld b, 8
.byte:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, .byte
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
    cp CUSTOM_ROOM_START        ;   Any other type >= $6B (e.g. $FF armed by the
    jr nc, .customRoom          ;   Anchor field-skill, S105) reads bank $60 scripts
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
; S105 (P3.9b): script TYPE $FF = a custom SKILL's own dialog script
; (SkillScriptPtrTable, emitted into every build from editor2/core/
; skill_scripts.json, id = [wScriptNPCId]) — so a field-cast skill needs no
; custom room. Anchor (bank $72 AnchorField14Tail) arms $FF / ids 2-5; S73-S104
; armed $71 = the example project's medal_vault, which other projects lack.
; $FF routes exactly like $71 everywhere else: >= $40 -> bank $0F dispatch ->
; GateAwareDispatch (>= $6B, != $70) -> here.
SKILL_SCRIPT_TYPE EQU $FF
CustomScriptRead:
    ld a, [wScriptMapType]
    cp SKILL_SCRIPT_TYPE
    jr nz, .room
    ld de, SkillScriptPtrTable
    jr .byScript
.room:
    sub CUSTOM_ROOM_START
    ld l, a
    ld h, $00
    add hl, hl
    ld de, CustomScriptMasterTable
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]

.byScript:
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
; Entries 9 / 10: CustomDrawTiles / CustomDrawAttrs (S119, ROADMAP P3.8 part d)
; =============================================================================
; Script ops $24 draw_tiles / $61 draw_attrs far-call entry 1 / 2 of the map's
; SCRIPT bank, which reads ONE more script word (the patch address in that
; bank) and draws the patch [offset word, bytes …, $D8 next row, $D9 end]
; onto the visible BG map (bank $0C entries 1 / 2, BANK04_SCRIPT_ENGINE "Tile
; patches"). Every map type >= $40 went to bank $0F, whose reader looks the
; word up in bank $0F's tables — wrong for a custom room (bank $60 scripts).
; Bank $04 now calls these two entries instead of $0F01 / $0F02 (same size):
; a custom script (the GateAwareDispatch rule) reads its word through
; CustomScriptRead and its patch from bank $60 (the compiler's patch_data);
; anything else goes on to bank $0F exactly as before.
; S127 (ROADMAP P3.14e2): a word $FF00-$FFFF is no patch (patches sit at
; $4000-$7FFF) but a COMMAND of the compiler: bank $77 entry 10 ScriptCommand
; with E = the low byte (0 = put the breeding mate's name in insert slot 0). The drawing below is a
; copy of bank $0C's (ScriptBank0CDrawTiles / …DrawAttrs, byte for byte the
; same algorithm): offset = row * 32 + column in 8-px tiles from the visible
; top-left ($FFB7 / $FFBB scroll), tiles also staged at $C300 + offset, the
; colour nibbles at $C200 + offset / 2.
CustomDrawTiles:
    call CutPatchRoute
    jr c, .custom
    ld hl, $0f01
    rst $10
    ret
.custom:
    call CutPatchParam
    ld a, b
    cp $ff
    jr z, .command                      ; S127: op $24 $FFxx = a compiler command
    push bc
    call CutPatchCursor
    pop bc
    push bc
    call CutPatchStage
    pop bc
    jp CutPatchDraw
.command:                               ; (ROADMAP P3.14b's reserved word range)
    ld e, c
    ld hl, $770a                        ; bank $77 entry 10 ScriptCommand, E = xx
    rst $10
    ret

CustomDrawAttrs:
    call CutPatchRoute
    jr c, .custom
    ld hl, $0f02
    rst $10
    ret
.custom:
    call CutPatchCursor
    call CutPatchParam
    push bc
    call CutPatchStageAttr
    pop bc
    ld a, [wIsGBC]
    or a
    ret z
    di
    call WaitVRAM
    ld a, $01
    ldh [rVBK], a
    ei
    call CutPatchDraw
    di
    call WaitVRAM
    ld a, $00
    ldh [rVBK], a
    ei
    ret

; CF set = the running script is a bank $60 script (GateAwareDispatch's rule)
CutPatchRoute:
    ld a, [wScriptMapType]
    cp $70
    jr z, .byRoom
    cp CUSTOM_ROOM_START
    jr nc, .custom
.byRoom:
    ld a, [wMapID]
    cp CUSTOM_ROOM_START
    jr nc, .custom
    and a
    ret
.custom:
    scf
    ret

; BC = the next script word (the patch address), counter advanced
CutPatchParam:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    jp CustomScriptRead

; $D8E7/$D8E8 = the BG map address of the visible top-left tile
CutPatchCursor:
    ld hl, $ffb7
    ld a, [hl]
    and $f8
    ld [hl], a
    ld hl, $ffbb
    ld a, [hl]
    and $f8
    ld [hl], a
    ldh a, [$bb]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    ldh a, [$b7]
    rrca
    rrca
    rrca
    add l
    ld l, a
    ld a, h
    adc $98
    ld h, a
    ld a, h
    and $03
    or $98
    ld h, a
    ld a, l
    ld [$d8e7], a
    ld a, h
    ld [$d8e8], a
    ret

; draw the patch at BC onto the BG map (VRAM bank as selected)
CutPatchDraw:
    ld a, [bc]
    ld l, a
    inc bc
    ld a, [bc]
    ld h, a
    inc bc
    push bc
    ld b, l
    ld a, l
    and $e0
    ld l, a
    ld a, [$d8e7]
    add l
    ld l, a
    ld a, [$d8e8]
    adc h
    and $03
    ld h, a
    ld a, [$d8e8]
    and $fc
    or h
    ld h, a
    ld a, b
    and $1f
    jr z, .col0
    ld b, a
.cols:
    call CutPatchNextCol
    dec b
    jr nz, .cols
.col0:
    ld a, l
    ld [$d8e7], a
    ld a, h
    ld [$d8e8], a
    pop bc
.byte:
    ld a, [bc]
    inc bc
    cp $d9
    ret z
    cp $d8
    jr nz, .put
    ld a, [$d8e7]
    ld l, a
    ld a, [$d8e8]
    ld h, a
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, h
    and $03
    or $98
    ld h, a
    ld a, l
    ld [$d8e7], a
    ld a, h
    ld [$d8e8], a
    jr .byte
.put:
    call Write_gfx_tile
    call CutPatchNextCol
    jr .byte

CutPatchNextCol:
    ld a, l
    and $e0
    push af
    ld a, l
    inc a
    and $1f
    ld l, a
    pop af
    or l
    ld l, a
    ret

; the tiles also go to the $C300 screen buffer (rows of 32)
CutPatchStage:
    ld a, [bc]
    ld l, a
    inc bc
    ld a, [bc]
    ld h, a
    inc bc
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c3
    ld h, a
.row:
    push hl
.byte:
    ld a, [bc]
    inc bc
    cp $d9
    jr z, .done
    cp $d8
    jr nz, .put
    pop hl
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr .row
.put:
    ld [hl+], a
    jr .byte
.done:
    pop hl
    ret

; the colours also go to the $C200 nibble buffer (two tiles per byte)
CutPatchStageAttr:
    ld a, [bc]
    ld l, a
    inc bc
    ld a, [bc]
    ld h, a
    inc bc
.row:
    push hl
.byte:
    ld a, [bc]
    inc bc
    cp $d9
    jr z, .done
    cp $d8
    jr nz, .put
    pop hl
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr .row
.put:
    call CutPatchNibble
    inc hl
    jr .byte
.done:
    pop hl
    ret

CutPatchNibble:
    push hl
    srl h
    rr l
    push af
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c2
    ld h, a
    pop af
    jr c, .low
    swap a
    and $f0
    ld d, a
    ld a, [hl]
    and $0f
    jr .put
.low:
    and $0f
    ld d, a
    ld a, [hl]
    and $f0
.put:
    or d
    ld [hl], a
    pop hl
    ret
