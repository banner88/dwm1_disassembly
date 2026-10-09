; =============================================================================
; BANK $60 — CUSTOM ROOM BANK: the engine's one address for custom-room data
; =============================================================================
; Entry points (called via rst $10 from banks $04/$06/$0B/$17/$77):
;   Entry 0: step entry         — DE = [step_id, tileset_bank]   (forwarded)
;   Entry 1: NPC / interact list — HL = wCustomNPCBuffer or 0 (S117: every
;            non-gate room; vanilla rooms read VanillaNPCExtTable here;
;            custom rooms forwarded)
;   Entry 2: exit list          — HL = wCustomExitBuffer          (forwarded)
;   Entry 3: CustomTilesetInfo  — returns wCustomRoomFlag (no caller)
;   Entry 4: script word        — BC = the running script's next word
;            (type $FF = the custom skills' scripts, here; rooms forwarded)
;   Entry 5: custom text        — [$C822] section / [$C823] entry (forwarded
;            by section)
;   Entry 6: GateAwareDispatch  — B-fix: bank-$0F script dispatch routed by wMapID
;   Entry 7: VanillaExitResolve — S70: unified exit resolve (custom rooms AND
;            compiler-authored vanilla-room exit EXTENSIONS; HL=list or 0)
;   Entry 8: state rules        — S97: flag-driven room states   (forwarded)
;   Entry 9: tile patch         — S119: script op $24              (forwarded)
;   Entry 10: tile patch colours — S119: script op $61             (forwarded)
;   Entry 11: NpcColourDraw     — S123: the field NPC draw (bank $06) with the
;            NPC colours of the room's $A2 prefixes (any of the 8 OBJ palettes)
;   Entry 12: CustomDescentFeel — S123 r2: bank $0B CustomDescentInGate's body —
;            only a STAIRS-DOWN exit of a custom room is an in-gate floor change
;   Entry 13: render row        — S137: bank $17 CustomAttrCheck: the current
;            screen + state's attr row and palette -> WRAM (forwarded)
;
; S136 (ROADMAP ARC CAP2b) — PLACE BANKS. A place (custom room) keeps its
; scripts, tile patches, screens, NPC / exit lists, state rules and monster
; cast in its HOME BANK: bank $60 itself first, then banks $80+ for the places
; that do not fit (editor2/core/project.py place_plan, first fit); text
; sections are placed the same way. Every home bank carries the same reader
; block (templates/place_readers.asm — pasted below this head with no suffix,
; and at $4001 of every place bank). Entries 0/1/2/4/5/8/9/10/13 are FORWARDERS:
; on EVERY call they look the place up in PlaceDirectory (map id or script
; type) / TextSectionBanks (text section) — nothing is cached, so the map-id
; writes outside the room commit (gate insert, boss floor, save load, new
; game, Play here) need no refresh — and call that bank's entry of the same
; number (PlaceGo: a local jump when the home is bank $60). Bank $60 keeps the
; global things: the custom skills' scripts, VanillaExitExtTable /
; VanillaNPCExtTable, entries 3 / 6 / 7 / 11 / 12.
; =============================================================================

SECTION "ROM Bank $060", ROMX[$4000], BANK[$60]
    db $60 ; bank number

    dw PlaceFwdStep         ; Entry 0
    dw PlaceFwdInteract     ; Entry 1
    dw PlaceFwdExit         ; Entry 2
    dw CustomTilesetInfo    ; Entry 3
    dw PlaceFwdScript       ; Entry 4
    dw PlaceFwdText         ; Entry 5
    dw GateAwareDispatch    ; Entry 6 — gate-entry regression fix (B-fix): route by wMapID
    dw VanillaExitResolve   ; Entry 7 — S70 unified exit resolve (bank $0B Entry 6 calls this for EVERY non-gate room)
    dw PlaceFwdRules        ; Entry 8 — S97 state rules (bank $17 CustomAttrCheck calls it)
    dw PlaceFwdTiles        ; Entry 9 — S119 op $24 in custom rooms (bank $04 ScriptCmd24 same-size redirect)
    dw PlaceFwdAttrs        ; Entry 10 — S119 op $61 in custom rooms (bank $04 ScriptCmd61 same-size redirect)
    dw NpcColourDraw        ; Entry 11 — S123 NPC colours (bank $06 NPCDrawSlot same-size redirect)
    dw CustomDescentFeel    ; Entry 12 — S123 r2 gate-flag exit feel (bank $0B CustomDescentInGate far-calls it)
    dw PlaceFwdRender       ; Entry 13 — S137 render row + palette -> WRAM (bank $17 CustomAttrCheck)

; =============================================================================
; S136 — the place lookup
; =============================================================================
; PlaceOf: A = a map id or script type. CF clear: H = the place's home bank,
; [wPlaceIdx] = its index inside that bank. CF set: no place — a vanilla id
; ($00-$6A), or past the last place (PLACE_COUNT; e.g. a transient script
; type $70 with fewer than 6 places, which read past the old tables).
; PlaceDirectory (generated) = per place, in map id order: db bank, db index.
; Clobbers A/DE/HL; keeps BC.
PlaceOf:
    sub CUSTOM_ROOM_START
    ret c
    cp PLACE_COUNT
    ccf
    ret c
    ld l, a
    ld h, $00
    add hl, hl
    ld de, PlaceDirectory
    add hl, de
    ld a, [hl+]
    ld e, a                     ; E = home bank
    ld a, [hl]
    ld [wPlaceIdx], a
    ld h, e
    and a                       ; CF clear
    ret

; PlaceGo: H = home bank, L = entry -> that bank's reader entry L (its rst $10
; table = PlaceEntries at $4001); bank $60's own readers by a local jump
; (PlaceEntries below the head). Returns whatever the reader returns (rst $10
; keeps BC / DE / HL on the way back, clobbers A).
PlaceGo:
    ld a, h
    cp $60
    jr z, .here
    rst $10
    ret
.here:
    ld a, l
    add a
    ld hl, PlaceEntries
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jp hl

; Entry 0 — the current screen's step entry (bank $0B RoomEntry0's custom
; branch). No place: bank $60's dummy step [1, $2A] (DummyStepEntry).
PlaceFwdStep:
    ld a, [wMapID]
    call PlaceOf
    jr c, .none
    ld l, $00
    jp PlaceGo
.none:
    ld de, $2A01
    ret

; Entry 1 — the NPC / interact list (bank $0B GetRoomDataPtr, every non-gate
; room). Returns HL = the list to parse (wCustomNPCBuffer) or HL = 0 = "no
; override — run the vanilla SharedPtrChase path". rst $10 keeps HL.
PlaceFwdInteract:
    ld a, [wMapID]
    cp CUSTOM_ROOM_START
    jp c, VanillaInteract
    call PlaceOf
    jr c, .none
    ld l, $01
    jp PlaceGo
.none:
    ld hl, wCustomNPCBuffer
    ld [hl], $FF
    ret

; Entry 2 — the exit list (entry 7's custom branch). No place: the dummy
; step's exits (DummyExits — the player must always have a way out,
; KEY_LESSONS v14-v17), as for an undefined screen.
PlaceFwdExit:
    ld a, [wMapID]
    call PlaceOf
    jr c, .none
    ld l, $02
    jp PlaceGo
.none:
    ld a, $FE
    ld [wCustomY7Cmp], a
    ld hl, DummyExits
    jp CopyExitListToBuffer

; Entry 4 (and GateAwareDispatch's custom branch) — BC = the running script's
; next word, HL = its address. The place = the script TYPE wScriptMapType
; (what the reader always indexed: a script that warps out keeps reading its
; own room); type $FF = a custom skill's script (here). No place: BC = $FFFF
; (end). HL matters: bank $04's branch tail ScriptReturnProcess computes
; counter += (target - HL) / 2 with the target an ABSOLUTE address in the
; script's own bank — rst $10 hands BC / DE / HL back unchanged (only A is
; the caller's bank), so both survive the two nested far calls.
PlaceFwdScript:
    ld a, [wScriptMapType]
    cp SKILL_SCRIPT_TYPE
    jp z, SkillScriptRead
    call PlaceOf
    jr c, .none
    ld l, $04
    jp PlaceGo
.none:
    ld bc, $FFFF
    ret

; Entry 5 — the custom text [$C822] section / [$C823] entry (bank $04
; TextQueueCheck_Ext, bank $77 SayText): the section's home bank shows it.
PlaceFwdText:
    ld a, [$c822]
    cp TEXT_SECTIONS
    ret nc                      ; no such section: no text (defensive)
    ld l, a
    ld h, $00
    ld de, TextSectionBanks
    add hl, de
    ld h, [hl]
    ld l, $05
    jp PlaceGo

; Entry 8 — state rules + monster cast of the current screen. Vanilla rooms /
; no place: nothing. (S97-S136: bank $17 CustomAttrCheck called it through
; StateRulesHook17; S137: the render reader, entry 13, runs the rules itself —
; no caller left; kept so the entry numbers stay.)
PlaceFwdRules:
    ld a, [wMapID]
    call PlaceOf
    ret c
    ld l, $08
    jp PlaceGo

; Entry 13 (S137, ROADMAP ARC CAP2c) — bank $17 CustomAttrCheck, at the start
; of BOTH bank $17 table walks (entry 0 the palette, entry 1 the attr map): the
; place's reader runs the state rules, then copies the current screen + state's
; render row (+ its palette, 32 B) into the WRAM walk block and returns
; HL = wRenderTable. No place (stale save, past PLACE_COUNT): HL = 0 -> bank
; $17 takes the Castle fallback, as a placeholder room always has.
PlaceFwdRender:
    ld a, [wMapID]
    call PlaceOf
    jr c, .none
    ld l, $0D
    jp PlaceGo
.none:
    ld hl, $0000
    ret

; Entries 9 / 10 — script ops $24 / $61: a custom script's tile patch lives with
; its script (the place = the script type); anything else goes on to bank $0F
; exactly as before. No place: the op's one word is stepped over so the script
; stays in step. The custom skills' scripts (type $FF) use neither op — the
; compiler refuses one there (places.py _skill_lines) — so type $FF lands in
; that case too.
PlaceFwdTiles:
    call CutPatchRoute
    jr c, .custom
    ld hl, $0f01
    rst $10
    ret
.custom:
    ld a, [wScriptMapType]
    call PlaceOf
    jr c, PlaceSkipParam
    ld l, $09
    jp PlaceGo

PlaceFwdAttrs:
    call CutPatchRoute
    jr c, .custom
    ld hl, $0f02
    rst $10
    ret
.custom:
    ld a, [wScriptMapType]
    call PlaceOf
    jr c, PlaceSkipParam
    ld l, $0A
    jp PlaceGo

PlaceSkipParam:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    ret

; CF set = the running script is a custom one (GateAwareDispatch's rule)
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

; =============================================================================
; Entry 1's vanilla branch: VanillaNPCExtTable (compiler-generated, bank $60):
; the vanilla rooms whose gate-swirl objects follow a project gate's "cleared"
; flag (a portal re-bossed or re-routed). Row format = VanillaExitExtTable's:
; db mapID, screen / dw step_counter / db n_steps / dw list0..listN-1;
; db $FF ends the table. Variant = min([counter], n-1). A = wMapID.
; =============================================================================
VanillaInteract:
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
    jp CopyNPCListToBuffer      ; bank $60's reader copy (place_readers.asm)

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
;   wMapID >= $6B  -> jp PlaceFwdExit (the place's own exit list, S136)
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
    jp PlaceFwdExit             ; custom room — the place's exit list
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
    jp CopyExitListToBuffer     ; bank $60's reader copy -> HL = wCustomExitBuffer

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
    jp PlaceFwdScript           ; entry 4 (S136: the script type's home bank); returns BC

; =============================================================================
; The custom skills' scripts (script type $FF)
; =============================================================================
; S105 (P3.9b): script TYPE $FF = a custom SKILL's own dialog script
; (SkillScriptPtrTable, emitted into every build from editor2/core/
; skill_scripts.json, id = [wScriptNPCId]) — so a field-cast skill needs no
; custom room. Anchor (bank $72 AnchorField14Tail) arms $FF / ids 2-5; S73-S104
; armed $71 = the example project's medal_vault, which other projects lack.
; $FF routes exactly like $71 everywhere else: >= $40 -> bank $0F dispatch ->
; GateAwareDispatch (>= $6B, != $70) -> entry 4 -> here. They stay in bank $60.
SKILL_SCRIPT_TYPE EQU $FF
SkillScriptRead:
    ld de, SkillScriptPtrTable
    jp ScriptWordAt             ; bank $60's reader copy; returns BC
