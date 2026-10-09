; =============================================================================
; PLACE READERS{P} — the custom-room data readers of ONE place bank
; (S136, ROADMAP ARC CAP2b; template editor2/core/templates/place_readers.asm)
; =============================================================================
; A place (a custom room) keeps ALL its bank $60-class data in its HOME BANK:
; its script table + scripts, tile patches, screen sub-table, step entries,
; NPC / exit lists, state rules and monster cast; text sections are placed the
; same way. Bank $60 is the first home bank; places that do not fit go to banks
; $80+ (editor2/core/project.py place_plan, first fit). Every home bank carries
; this reader block (the compiler pastes it with {P} = "" in bank $60 and
; {P} = "_P<bank>" in a place bank, where it starts at $4001 so that
; PlaceEntries{P} IS the bank's rst $10 entry table).
;
; The engine never calls a place bank: it calls bank $60's fixed entries, whose
; forwarders (bank_060_head.asm PlaceOf / PlaceGo) look the place up in
; PlaceDirectory on EVERY call — no cached bank — write its index inside the
; home bank to wPlaceIdx and call the matching entry here. So every reader
; indexes its tables with [wPlaceIdx], never with wMapID - $6B.
; Entry numbers equal bank $60's: 0 step, 1 NPC list, 2 exit list, 4 script
; word, 5 text, 8 state rules, 9 / 10 tile patches, 13 render row (S137)
; (3 / 6 / 7 / 11 / 12 = no-ops).
; =============================================================================
PlaceEntries{P}:
    dw CustomReadStep{P}        ; 0
    dw CustomReadInteract{P}    ; 1 (custom rooms only — bank $60 keeps the vanilla branch)
    dw CustomExitCheck{P}       ; 2
    dw PlaceNoop{P}             ; 3
    dw CustomScriptRead{P}      ; 4
    dw CustomTextDisplay{P}     ; 5
    dw PlaceNoop{P}             ; 6
    dw PlaceNoop{P}             ; 7
    dw CustomStateRules{P}      ; 8
    dw CustomDrawTiles{P}       ; 9
    dw CustomDrawAttrs{P}       ; 10
    dw PlaceNoop{P}             ; 11
    dw PlaceNoop{P}             ; 12
    dw CustomRenderCopy{P}      ; 13 (S137)

PlaceNoop{P}:
    ret

; =============================================================================
; CustomPtrChase — HL = the current step entry of the place's current screen
; =============================================================================
CustomPtrChase{P}:
    ld hl, PlaceSourceTable{P}
    ld a, [wPlaceIdx]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [wCustomRoomFlag], a
    ld hl, PlaceRoomTable{P}
    ld a, [wPlaceIdx]
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
    ld hl, DummyStepEntry{P}
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

DummyStepEntry{P}:
    db 1, $2A
    dw DummyNPCs{P}
    dw DummyExits{P}
DummyNPCs{P}:
    db $FF
DummyExits{P}:
    db $03, $07, $01, $00, $80, $04, $04
    db $05, $07, $01, $00, $80, $04, $04
    db $07, $07, $01, $00, $80, $04, $04
    db $03, $00, $01, $00, $80, $04, $04
    db $05, $00, $01, $00, $80, $04, $04
    db $FF

; =============================================================================
; Entries 0-2: room data readers
; =============================================================================
CustomReadStep{P}:
    call CustomStateRules{P}     ; S97: flag rules pick the state BEFORE the counter read
    call CustomPtrChase{P}
    ld e, [hl]
    inc hl
    ld d, [hl]
    ret

; Entry 1 (custom rooms): HL = wCustomNPCBuffer, the place's current NPC list.
CustomReadInteract{P}:
    call CustomPtrChase{P}
    inc hl
    inc hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
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
CopyNPCListToBuffer{P}:
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
    call NpcColourRecord{P}     ; S123: this NPC's colour -> wNpcColour[slot]
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
NpcColourRecord{P}:
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

CustomExitCheck{P}:
    ; S70v3: custom branch of the y-skip arming (see bank $60 VanillaExitResolve):
    ; $FE never equals a real trigger_y, so Entry 6's scan no longer skips
    ; y=7 rows here — custom-room boundary exits fire on WALK-ON arrival.
    ; Entry 9 (push) reads the same list and still works as a fallback.
    ld a, $FE
    ld [wCustomY7Cmp], a
    call CustomPtrChase{P}
    inc hl
    inc hl
    inc hl
    inc hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ; fall through into the shared copy loop (S70 factoring; 7-byte entries,
    ; first-byte-$FF terminator only, KEY_LESSONS v3-v4)
CopyExitListToBuffer{P}:
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

; =============================================================================
; Entry 8: CustomStateRules  (S97 — ROADMAP P3.5a, declarative room states)
; =============================================================================
; Custom-room step counters live in the transient $CD80 window (zeroed at every
; save-restore, PROJECT_COMPILER §2.6), so a state reached by a script is lost
; on reload. Event flags persist. This routine re-derives the CURRENT screen's
; state from flags: the compiler emits, per place, a list of screens that
; carry rules, each with an ordered rule list; the FIRST rule whose terms all
; hold writes its state into that screen's step counter. No match = counter
; untouched (scripts that write_ram the counter keep working until the next
; load). Idempotent, so it runs from every custom (re)load path:
;   * bank $17 CustomAttrCheck (the FIRST custom hook of a room load — the
;     attr/palette walk reads the counter before bank $0B Entry 0 does,
;     PyBoy-measured S97), via bank $60 entry 13 -> CustomRenderCopy below
;     (S97-S136: StateRulesHook17 + rst $10 bank $60 entry 8);
;   * CustomReadStep (Entry 0) itself, before CustomPtrChase.
; Tables (generated, in the place's home bank):
;   PlaceRuleTable: dw per place (index wPlaceIdx), $0000 = none
;   room list:  { db screen / dw step_counter / dw rules } ... db $FF
;   rules:      { db state / db n_terms / n_terms x dw flag } ... db $FF
;               flag word: bits 0-14 = event flag index, bit 15 = must be CLEAR
;               (n_terms 0 = always).
; Clobbers A/BC/DE/HL (callers preserve what they need).
; S101: first writes the screen's MONSTER CAST (CustomMonsterCast below) —
; the same load hooks run before the bank $0B NPC parse reads it.
CustomStateRules{P}:
    call CustomMonsterCast{P}
    ld a, [wPlaceIdx]
    add a
    ld hl, PlaceRuleTable{P}
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
; own mechanism, ROOM_DATA_FORMAT "Monster NPCs"). Places carry a generated
; per-screen cast: PlaceCastTable (dw per place, $0000 = none) ->
; { db screen / 8 bytes = 4 pairs } ... db $FF. The pairs of the current
; wScreenIndex are copied to $D7CA-$D7D1 at every custom load, before the NPC
; parse; screens without a cast leave the list alone.
; -----------------------------------------------------------------------------
CustomMonsterCast{P}:
    ld a, [wPlaceIdx]
    add a
    ld hl, PlaceCastTable{P}
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
; Entry 4: CustomScriptRead — BC = the running script's next word
; =============================================================================
; The place = the running script's TYPE (wScriptMapType, the bank $60
; forwarder's key — a script that warps out keeps reading its own room);
; script table [wPlaceIdx] -> [wScriptNPCId] -> word [wScriptCounter].
; ScriptWordAt: DE = a script pointer table (bank $60's skill scripts use it).
CustomScriptRead{P}:
    ld a, [wPlaceIdx]
    ld l, a
    ld h, $00
    add hl, hl
    ld de, PlaceScriptTable{P}
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
ScriptWordAt{P}:
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
; Entry 5: CustomTextDisplay — the custom text id [$C822] section / [$C823]
; entry through ROM0 CallTextEngine (SaveBankAndSwitch reads table[$C822 * 2]
; -> section[$C823 * 2]; the text engine keeps THIS bank in $C824 —
; [$4000] — and reads every byte from it, TEXT_SYSTEM). The table holds this
; bank's sections only: its base is biased by the first one it holds.
; =============================================================================
CustomTextDisplay{P}:
    ld de, PlaceTextRows{P} - 2 * PLACE_TEXT_FIRST{P}
    call CallTextEngine
    ret

; =============================================================================
; Entries 9 / 10: CustomDrawTiles / CustomDrawAttrs (S119, ROADMAP P3.8 part d)
; =============================================================================
; Script ops $24 draw_tiles / $61 draw_attrs far-call bank $60 entry 9 / 10
; (bank $04 ScriptCmd24 / ScriptCmd61 same-size redirect); bank $60 decides
; "a custom script" (CutPatchRoute — GateAwareDispatch's rule) and forwards
; here. One more script word is read (the patch address in this bank) and the
; patch [offset word, bytes …, $D8 next row, $D9 end] is drawn onto the
; visible BG map (BANK04_SCRIPT_ENGINE "Tile patches").
; S127 (ROADMAP P3.14e2): a word $FF00-$FFFF is no patch (patches sit at
; $4000-$7FFF) but a COMMAND of the compiler: bank $77 entry 10 ScriptCommand
; with E = the low byte. The drawing below is a copy of bank $0C's
; (ScriptBank0CDrawTiles / …DrawAttrs, byte for byte the same algorithm):
; offset = row * 32 + column in 8-px tiles from the visible top-left ($FFB7 /
; $FFBB scroll), tiles also staged at $C300 + offset, the colour nibbles at
; $C200 + offset / 2.
CustomDrawTiles{P}:
    call CutPatchParam{P}
    ld a, b
    cp $ff
    jr z, .command                      ; S127: op $24 $FFxx = a compiler command
    push bc
    call CutPatchCursor{P}
    pop bc
    push bc
    call CutPatchStage{P}
    pop bc
    jp CutPatchDraw{P}
.command:                               ; (ROADMAP P3.14b's reserved word range)
    ld e, c
    ld hl, $770a                        ; bank $77 entry 10 ScriptCommand, E = xx
    rst $10
    ret

CustomDrawAttrs{P}:
    call CutPatchCursor{P}
    call CutPatchParam{P}
    push bc
    call CutPatchStageAttr{P}
    pop bc
    ld a, [wIsGBC]
    or a
    ret z
    di
    call WaitVRAM
    ld a, $01
    ldh [rVBK], a
    ei
    call CutPatchDraw{P}
    di
    call WaitVRAM
    ld a, $00
    ldh [rVBK], a
    ei
    ret

; BC = the next script word (the patch address), counter advanced
CutPatchParam{P}:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    jp CustomScriptRead{P}

; $D8E7/$D8E8 = the BG map address of the visible top-left tile
CutPatchCursor{P}:
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
CutPatchDraw{P}:
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
    call CutPatchNextCol{P}
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
    call CutPatchNextCol{P}
    jr .byte

CutPatchNextCol{P}:
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
CutPatchStage{P}:
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
CutPatchStageAttr{P}:
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
    call CutPatchNibble{P}
    inc hl
    jr .byte
.done:
    pop hl
    ret

CutPatchNibble{P}:
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

; =============================================================================
; Entry 13: CustomRenderCopy (S137, ROADMAP ARC CAP2c) — the RENDER ROW
; =============================================================================
; Bank $17 entries 0 (palette) and 1 (attr map) walk a VANILLA-format table:
; table[A] dw -> [wScreenIndex] dw -> [counter ptr:2] -> + [counter] * 4 ->
; [attr_entry, attr_bank, pal_ptr:2]; LoadPal_46a1 then copies slots 0-3
; (32 B) from pal_ptr IN BANK $17. A place's table lives here instead (with its
; palettes), so bank $17 CustomAttrCheck far-calls this through bank $60 entry
; 13 and the walk reads the WRAM block built below (wram.asm wRenderTable…).
; Runs the state rules first (this is the earliest custom hook of a room load,
; PyBoy S97 — it used to be StateRulesHook17's job).
; Tables (generated, this bank):
;   PlaceRenderTable: dw per place (wPlaceIdx), $0000 = no table (placeholder)
;   RoomAttr_<mid>:   16 x dw (screen 0-15) -> ScrAttr ($0000 = no screen)
;   ScrAttr_<mid>_<k>: dw step counter, db n_states, n x [db attr_entry,
;                     attr_bank / dw pal_ptr]
;   pal_ptr bit 15 SET = a vanilla palette in BANK $17 (a borrow; the walk reads
;   it there: bit 15 cleared), else a palette block of THIS bank (32 B copied
;   to wRenderPal). Bit 15 is free: every ROMX address is $4000-$7FFF.
; The counter is clamped to the last state (the old bank $17 table had no
; count: a counter past the states read the next screen's bytes).
; Returns HL = wRenderTable (the walk's base; bank $17 uses index 0) or
; HL = 0 = no table here (no place table / screen word $0000 — the Castle
; fallback; the old walk followed a $0000 screen word into ROM0, S135).
; Clobbers A/BC/DE.
; -----------------------------------------------------------------------------
CustomRenderCopy{P}:
    call CustomStateRules{P}     ; the state (and the monster cast) first
    ld a, [wPlaceIdx]
    add a
    ld hl, PlaceRenderTable{P}
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    or h
    jr z, .none                  ; no render table (placeholder room)
    ld a, [wScreenIndex]
    and $0F
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    or h
    jr z, .none                  ; a screen the room does not have
    ld e, [hl]
    inc hl
    ld d, [hl]                   ; DE = the screen's step counter
    inc hl
    ld a, [hl+]
    ld b, a                      ; B = n_states (>= 1)
    ld a, [de]
    cp b
    jr c, .stateOk
    ld a, b
    dec a                        ; past the last state: the last state
.stateOk:
    add a
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a                      ; HL = this state's row
    ld a, [hl+]
    ld [wRenderRow + 2], a       ; attr entry
    ld a, [hl+]
    ld [wRenderRow + 3], a       ; attr bank
    ld a, [hl+]
    ld e, a
    ld d, [hl]                   ; DE = pal_ptr
    bit 7, d
    jr z, .own
    res 7, d                     ; a vanilla palette: read in bank $17 itself
    jr .row
.own:
    ld hl, wRenderPal
    ld b, 32                     ; slots 0-3
.copy:
    ld a, [de]
    ld [hl+], a
    inc de
    dec b
    jr nz, .copy
    ld de, wRenderPal
.row:
    ld a, e
    ld [wRenderRow + 4], a
    ld a, d
    ld [wRenderRow + 5], a
    ld a, LOW(wRenderZero)       ; the walk's "step counter" = a zero byte
    ld [wRenderRow], a
    ld a, HIGH(wRenderZero)
    ld [wRenderRow + 1], a
    xor a
    ld [wRenderZero], a
    ld a, LOW(wRenderRow)
    ld [wRenderScr], a
    ld a, HIGH(wRenderRow)
    ld [wRenderScr + 1], a
    ld a, [wScreenIndex]         ; the walk adds wScreenIndex * 2 to this word
    add a
    ld b, a
    ld a, LOW(wRenderScr)
    sub b
    ld [wRenderTable], a
    ld a, HIGH(wRenderScr)
    sbc $00
    ld [wRenderTable + 1], a
    ld hl, wRenderTable
    ret
.none:
    ld hl, $0000
    ret
