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

; =============================================================================
; PLACE READERS — the custom-room data readers of ONE place bank
; (S136, ROADMAP ARC CAP2b; template editor2/core/templates/place_readers.asm)
; =============================================================================
; A place (a custom room) keeps ALL its bank $60-class data in its HOME BANK:
; its script table + scripts, tile patches, screen sub-table, step entries,
; NPC / exit lists, state rules and monster cast; text sections are placed the
; same way. Bank $60 is the first home bank; places that do not fit go to banks
; $80+ (editor2/core/project.py place_plan, first fit). Every home bank carries
; this reader block (the compiler pastes it with  = "" in bank $60 and
;  = "_P<bank>" in a place bank, where it starts at $4001 so that
; PlaceEntries IS the bank's rst $10 entry table).
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
PlaceEntries:
    dw CustomReadStep        ; 0
    dw CustomReadInteract    ; 1 (custom rooms only — bank $60 keeps the vanilla branch)
    dw CustomExitCheck       ; 2
    dw PlaceNoop             ; 3
    dw CustomScriptRead      ; 4
    dw CustomTextDisplay     ; 5
    dw PlaceNoop             ; 6
    dw PlaceNoop             ; 7
    dw CustomStateRules      ; 8
    dw CustomDrawTiles       ; 9
    dw CustomDrawAttrs       ; 10
    dw PlaceNoop             ; 11
    dw PlaceNoop             ; 12
    dw CustomRenderCopy      ; 13 (S137)

PlaceNoop:
    ret

; =============================================================================
; CustomPtrChase — HL = the current step entry of the place's current screen
; =============================================================================
CustomPtrChase:
    ld hl, PlaceSourceTable
    ld a, [wPlaceIdx]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [wCustomRoomFlag], a
    ld hl, PlaceRoomTable
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
; Entries 0-2: room data readers
; =============================================================================
CustomReadStep:
    call CustomStateRules     ; S97: flag rules pick the state BEFORE the counter read
    call CustomPtrChase
    ld e, [hl]
    inc hl
    ld d, [hl]
    ret

; Entry 1 (custom rooms): HL = wCustomNPCBuffer, the place's current NPC list.
CustomReadInteract:
    call CustomPtrChase
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
    call NpcColourRecord     ; S123: this NPC's colour -> wNpcColour[slot]
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

CustomExitCheck:
    ; S70v3: custom branch of the y-skip arming (see bank $60 VanillaExitResolve):
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
    ; fall through into the shared copy loop (S70 factoring; 7-byte entries,
    ; first-byte-$FF terminator only, KEY_LESSONS v3-v4)
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
CustomStateRules:
    call CustomMonsterCast
    ld a, [wPlaceIdx]
    add a
    ld hl, PlaceRuleTable
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
CustomMonsterCast:
    ld a, [wPlaceIdx]
    add a
    ld hl, PlaceCastTable
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
CustomScriptRead:
    ld a, [wPlaceIdx]
    ld l, a
    ld h, $00
    add hl, hl
    ld de, PlaceScriptTable
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
ScriptWordAt:
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
CustomTextDisplay:
    ld de, PlaceTextRows - 2 * PLACE_TEXT_FIRST
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
CustomDrawTiles:
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
CustomRenderCopy:
    call CustomStateRules     ; the state (and the monster cast) first
    ld a, [wPlaceIdx]
    add a
    ld hl, PlaceRenderTable
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

; =============================================================================
; PLACE DATA (generated) — bank $60: SCRIPT DATA (generated) + places
; Bank $60's own data: the custom skills' scripts, the place directory,
; the text section banks, its places' tables and blocks, its text
; sections, the vanilla-room exit / NPC overrides (editor2/core/places.py).
; Index 0 of a place's script table = its room entry script.
; =============================================================================
SkillScriptPtrTable:   ; script type $FF — custom skills' dialogs (bank $60 only)
    dw SkillScrNoop   ; [0] never armed
    dw SkillScrNoop   ; [1] never armed
    dw SkillScr02   ; [2] skill:anchor_gate_confirm
    dw SkillScr03   ; [3] skill:anchor_return_confirm
    dw SkillScr04   ; [4] skill:anchor_err_special
    dw SkillScr05   ; [5] skill:anchor_err_none
SkillScrNoop:
    dw $FFFF

SkillScr02:
    dw $FF07  ; init_dialog
    dw $0A26  ; [S73] Anchor gate-side confirm [Y/N]
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw SkillScr02_no
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
SkillScr02_no:
    dw $FFFF

SkillScr03:
    dw $FF07  ; init_dialog
    dw $0A27  ; [S73] Anchor return confirm [Y/N] — charge lands on arrival
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw SkillScr03_no
    dw $FF12  ; write_ram
    dw $DEB2
    dw $0002
    dw $FF0F  ; map_transition
    dw $8000
    dw $0000
    dw $0000
    dw $FFFF
SkillScr03_no:
    dw $FFFF

SkillScr04:
    dw $FF07  ; init_dialog
    dw $0A28  ; [S73] cast in a special/boss/custom gate room
    dw $FFFF

SkillScr05:
    dw $FF07  ; init_dialog
    dw $0A29  ; [S73] cast in town with no stored anchor
    dw $FFFF

PlaceDirectory:   ; per place (map id $6B + n): home bank, index there
    db $60, 0   ; $6B gate_island
    db $60, 1   ; $6C dusk_mirror
    db $60, 2   ; $6D gate_rotation
    db $60, 3   ; $6E reserved_6e
    db $60, 4   ; $6F reserved_6f
    db $60, 5   ; $70 ember_keystone
    db $60, 6   ; $71 medal_vault
    db $60, 7   ; $72 arena_clone
    db $60, 8   ; $73 island_copy
TextSectionBanks:   ; per text section ($0A00 + 256 n): its home bank
    db $60   ; section 0

; place tables of bank $60 — index = wPlaceIdx (PlaceDirectory, bank $60)
PlaceRoomTable:
    dw CustomRoom0_SubTable   ; $6B = place 0 here
    dw CustomRoom1_SubTable   ; $6C = place 1 here
    dw CustomRoom2_SubTable   ; $6D = place 2 here
    dw CustomRoom3_SubTable   ; $6E = place 3 here
    dw CustomRoom4_SubTable   ; $6F = place 4 here
    dw CustomRoom5_SubTable   ; $70 = place 5 here
    dw CustomRoom6_SubTable   ; $71 = place 6 here
    dw CustomRoom7_SubTable   ; $72 = place 7 here
    dw CustomRoom8_SubTable   ; $73 = place 8 here
PlaceScriptTable:
    dw CustomRoom0_ScriptPtrTable   ; mapID $6B
    dw CustomRoom1_ScriptPtrTable   ; mapID $6C
    dw CustomRoom2_ScriptPtrTable   ; mapID $6D
    dw CustomRoom3_ScriptPtrTable   ; mapID $6E
    dw CustomRoom4_ScriptPtrTable   ; mapID $6F
    dw CustomRoom5_ScriptPtrTable   ; mapID $70
    dw CustomRoom6_ScriptPtrTable   ; mapID $71
    dw CustomRoom7_ScriptPtrTable   ; mapID $72
    dw CustomRoom8_ScriptPtrTable   ; mapID $73
PlaceRuleTable:
    dw $0000   ; $6B (no rules)
    dw $0000   ; $6C (no rules)
    dw $0000   ; $6D (no rules)
    dw $0000   ; $6E (no rules)
    dw $0000   ; $6F (no rules)
    dw $0000   ; $70 (no rules)
    dw $0000   ; $71 (no rules)
    dw CustomRoom7_StateRules   ; $72 arena_clone
    dw $0000   ; $73 (no rules)
PlaceCastTable:
    dw $0000   ; $6B (no monster NPCs)
    dw $0000   ; $6C (no monster NPCs)
    dw $0000   ; $6D (no monster NPCs)
    dw $0000   ; $6E (no monster NPCs)
    dw $0000   ; $6F (no monster NPCs)
    dw $0000   ; $70 (no monster NPCs)
    dw $0000   ; $71 (no monster NPCs)
    dw $0000   ; $72 (no monster NPCs)
    dw $0000   ; $73 (no monster NPCs)
PlaceRenderTable:   ; S137: render rows + palettes (bank $17 via entry 13)
    dw RoomAttr_6B   ; $6B gate_island
    dw RoomAttr_6C   ; $6C dusk_mirror
    dw RoomAttr_6D   ; $6D gate_rotation
    dw $0000   ; $6E (no render table: the Castle's)
    dw $0000   ; $6F (no render table: the Castle's)
    dw RoomAttr_70   ; $70 ember_keystone
    dw RoomAttr_71   ; $71 medal_vault
    dw RoomAttr_72   ; $72 arena_clone
    dw RoomAttr_73   ; $73 island_copy
PlaceSourceTable:
    db $04   ; $6B — gate_island
    db $04   ; $6C — dusk_mirror
    db $04   ; $6D — gate_rotation
    db $04   ; $6E — reserved_6e
    db $04   ; $6F — reserved_6f
    db $04   ; $70 — ember_keystone
    db $04   ; $71 — medal_vault
    db $06   ; $72 — arena_clone
    db $04   ; $73 — island_copy
PlaceTextRows:   ; text sections 0-0
    dw CustomTextSection0

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

RoomAttr_6B:    ; gate_island: render rows, screen 0-15 (S137, CAP2c)
    dw ScrAttr_6B_0, $0000, $0000, $0000
    dw ScrAttr_6B_4, $0000, $0000, $0000
    dw $0000, $0000, $0000, $0000
    dw $0000, $0000, $0000, $0000
ScrAttr_6B_0:
    dw wCustomStep_Room6B_S0    ; step counter
    db 1    ; states
    db $01, $64    ; state 0: attr entry, bank
    dw RPal_6B_0    ; state 0: palette pal_6b
ScrAttr_6B_4:
    dw wCustomStep_Room6B_S4    ; step counter
    db 1    ; states
    db $03, $64    ; state 0: attr entry, bank
    dw RPal_6B_0    ; state 0: palette pal_6b
RPal_6B_0:   ; palette pal_6b (slots 0-3)
    db $EE, $04, $FF, $6B, $7A, $02, $00, $00  ; palette 0  04ee 6bff 027a 0000
    db $40, $7D, $FF, $6B, $81, $7F, $00, $00  ; palette 1  7d40 6bff 7f81 0000
    db $F0, $00, $FF, $6B, $1A, $02, $00, $00  ; palette 2  00f0 6bff 021a 0000
    db $A1, $01, $FF, $6B, $AA, $03, $00, $00  ; palette 3  01a1 6bff 03aa 0000

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

RoomAttr_6C:    ; dusk_mirror: render rows, screen 0-15 (S137, CAP2c)
    dw ScrAttr_6C_0, $0000, $0000, $0000
    dw ScrAttr_6C_4, $0000, $0000, $0000
    dw $0000, $0000, $0000, $0000
    dw $0000, $0000, $0000, $0000
ScrAttr_6C_0:
    dw wCustomStep_Room6C_S0    ; step counter
    db 1    ; states
    db $01, $64    ; state 0: attr entry, bank
    dw RPal_6C_0    ; state 0: palette pal_6c
ScrAttr_6C_4:
    dw wCustomStep_Room6C_S4    ; step counter
    db 1    ; states
    db $03, $64    ; state 0: attr entry, bank
    dw RPal_6C_0    ; state 0: palette pal_6c
RPal_6C_0:   ; palette pal_6c (slots 0-3)
    db $CC, $51, $16, $7B, $07, $39, $21, $10  ; pal0 ground(slate)
    db $C4, $48, $16, $7B, $88, $61, $21, $10  ; pal1 water(navy)
    db $D0, $59, $16, $7B, $C8, $30, $21, $10  ; pal2 accent(violet)
    db $C6, $31, $16, $7B, $E2, $18, $21, $10  ; pal3 tree(teal)

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

RoomAttr_6D:    ; gate_rotation: render rows, screen 0-15 (S137, CAP2c)
    dw ScrAttr_6D_0, $0000, $0000, $0000
    dw $0000, $0000, $0000, $0000
    dw $0000, $0000, $0000, $0000
    dw $0000, $0000, $0000, $0000
ScrAttr_6D_0:
    dw wCustomStep_Room6D_S0    ; step counter
    db 1    ; states
    db $01, $64    ; state 0: attr entry, bank
    dw RPal_6D_0    ; state 0: palette pal_6d
RPal_6D_0:   ; palette pal_6d (slots 0-3)
    db $C4, $11, $E9, $2B, $48, $23, $00, $00  ; sub-pal 0
    db $E9, $2B, $E9, $2B, $E9, $2B, $00, $00  ; sub-pal 1
    db $05, $16, $E9, $2B, $48, $23, $00, $00  ; sub-pal 2
    db $A4, $11, $E9, $2B, $A9, $27, $00, $00  ; sub-pal 3

; --- $6E (reserved_6e) placeholder (never entered; all screens invalid) ---
CustomRoom3_SubTable:
    dw $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF
CustomRoom3_ScriptPtrTable:
    dw CustomRoom3_Scr00   ; [0] room entry (no-op)
CustomRoom3_Scr00:
    dw $FFFF

; --- $6F (reserved_6f) placeholder (never entered; all screens invalid) ---
CustomRoom4_SubTable:
    dw $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF
CustomRoom4_ScriptPtrTable:
    dw CustomRoom4_Scr00   ; [0] room entry (no-op)
CustomRoom4_Scr00:
    dw $FFFF

; --- $70 (ember_keystone) no scripts ---
CustomRoom5_ScriptPtrTable:
    dw CustomRoom5_Scr00   ; [0] room entry (no-op)
CustomRoom5_Scr00:
    dw $FFFF

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

RoomAttr_70:    ; ember_keystone: render rows, screen 0-15 (S137, CAP2c)
    dw ScrAttr_70_0, $0000, $0000, $0000
    dw $0000, $0000, $0000, $0000
    dw $0000, $0000, $0000, $0000
    dw $0000, $0000, $0000, $0000
ScrAttr_70_0:
    dw wCustomStep_Room70_S0    ; step counter
    db 1    ; states
    db $01, $64    ; state 0: attr entry, bank
    dw RPal_70_0    ; state 0: palette pal_70
RPal_70_0:   ; palette pal_70 (slots 0-3)
    db $2E, $09, $7F, $12, $1A, $0E, $00, $00  ; sub-pal 0
    db $7F, $12, $7F, $12, $7F, $12, $00, $00  ; sub-pal 1
    db $50, $09, $7F, $12, $1A, $0E, $00, $00  ; sub-pal 2
    db $0D, $09, $7F, $12, $5D, $0E, $00, $00  ; sub-pal 3

; --- $71 (medal_vault) scripts ---
CustomRoom6_ScriptPtrTable:
    dw CustomRoom6_Scr00   ; [0] entry:medal_vault
    dw CustomRoom6_Scr01   ; [1] quest:medal_vault
    dw CustomRoom6_Scr02   ; [2] medal_vault_quest

CustomRoom6_Scr00:
    dw $FF01  ; if_flag_set
    dw $015A
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
    dw $FF0D  ; npc_write
    dw $0001
    dw $0000
    dw $0040
    dw $FFFF

CustomRoom6_Scr01:
    dw $FF01  ; if_flag_set
    dw $015A
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
    dw $015A
    dw $FF07  ; init_dialog
    dw $0A1E  ; win tail; GoldSlime joins engine-side (phase $0D)
    dw $FF0D  ; npc_write
    dw $0001
    dw $0000
    dw $0040
    dw $FFFF
CustomRoom6_Scr01_declined:
    dw $0A1C  ; vault_decline
    dw $FFFF
CustomRoom6_Scr01_qdone:
    dw $0A1F  ; vault_done
    dw $FFFF

CustomRoom6_Scr02:
    dw $FF00  ; if_flag_clear
    dw $015C
    dw CustomRoom6_Scr02_else1
    dw $0A25  ; quest mini_medal_quest: done
    dw $FF14  ; goto
    dw CustomRoom6_Scr02_fi1
CustomRoom6_Scr02_else1:
    dw $FF00  ; if_flag_clear
    dw $015B
    dw CustomRoom6_Scr02_else2
    dw $FF00  ; if_flag_clear
    dw $1800
    dw CustomRoom6_Scr02_else3
    dw $FF24  ; opcode $24
    dw $FF01
    dw $FF07  ; init_dialog
    dw $0A20  ; quest mini_medal_quest: complete
    dw $FF24  ; opcode $24
    dw $FF02
    dw $FF03  ; set_flag
    dw $015C
    dw $FF14  ; goto
    dw CustomRoom6_Scr02_fi3
CustomRoom6_Scr02_else3:
    dw $0A21  ; quest mini_medal_quest: progress
CustomRoom6_Scr02_fi3:
    dw $FF14  ; goto
    dw CustomRoom6_Scr02_fi2
CustomRoom6_Scr02_else2:
    dw $0A22  ; quest mini_medal_quest: offer
    dw $FF15  ; check_and_branch
    dw $C83C
    dw $0001
    dw CustomRoom6_Scr02_no4
    dw $FF03  ; set_flag
    dw $015B
    dw $0A23  ; quest mini_medal_quest: accept
    dw $FF14  ; goto
    dw CustomRoom6_Scr02_join4
CustomRoom6_Scr02_no4:
    dw $0A24  ; quest mini_medal_quest: decline
CustomRoom6_Scr02_join4:
CustomRoom6_Scr02_fi2:
CustomRoom6_Scr02_fi1:
    dw $FFFF

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
    db $00, $1D, $02, $05, $02  ; NPC (2,5) script medal_vault_quest
    db $FF

CustomRoom6_S0_Exits:
    db $07, $06, $16, $00, $00, $01, $02  ; back to MedalMan (1,2) vault-door tile; spawn-on-exit-tile is vanilla-precedented (SecretPassage->MedalMan lands on the north exit)
    db $08, $03, $72, $00, $01, $04, $07  ; S92 staircase (visible, metatile 8,3) -> arena_clone; sb/spawn copied from the vanilla GreatTree->Lobby exit
    db $FF

RoomAttr_71:    ; medal_vault: render rows, screen 0-15 (S137, CAP2c)
    dw ScrAttr_71_0, $0000, $0000, $0000
    dw $0000, $0000, $0000, $0000
    dw $0000, $0000, $0000, $0000
    dw $0000, $0000, $0000, $0000
ScrAttr_71_0:
    dw wCustomStep_Room71_S0    ; step counter
    db 1    ; states
    db $08, $64    ; state 0: attr entry, bank
    dw RPal_71_0    ; state 0: palette pal_71
RPal_71_0:   ; palette pal_71 (slots 0-3)
    db $90, $09, $FF, $6B, $FF, $16, $00, $00
    db $D3, $0D, $FF, $6B, $3F, $17, $00, $00
    db $91, $09, $FF, $6B, $DD, $16, $00, $00
    db $4E, $09, $FF, $6B, $FF, $16, $00, $00

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
    dw $FF0E  ; branch_screen
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
    dw $FF0D  ; npc_write
    dw $0000
    dw $FF90
    dw $0000
    dw $FFFF
CustomRoom7_Scr00_L4242:
    dw $FF27  ; monster_party_op2
    dw $FF0D  ; npc_write
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
    dw $FF0D  ; npc_write
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
    dw $FF0D  ; npc_write
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
    dw $FF0D  ; npc_write
    dw $0000
    dw $FF90
    dw $0040
    dw $FF0D  ; npc_write
    dw $0003
    dw $0000
    dw $0040
    dw $FF08  ; nop
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
    dw $FF0D  ; npc_write
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
    dw $FF0D  ; npc_write
    dw $0000
    dw $FF90
    dw $0040
    dw $FF0D  ; npc_write
    dw $0003
    dw $0000
    dw $0040
    dw $FF08  ; nop
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
    dw $FF0D  ; npc_write
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
    dw $FF0D  ; npc_write
    dw $0000
    dw $FF90
    dw $0040
    dw $FF0D  ; npc_write
    dw $0003
    dw $0000
    dw $0040
    dw $FF08  ; nop
    dw $FF0F  ; map_transition
    dw $0000
    dw $00E8
    dw $0058
    dw $FFFF
CustomRoom7_Scr00_L46F2:
    dw $FF0D  ; npc_write
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
    dw $FF0D  ; npc_write
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
    dw $FF0D  ; npc_write
    dw $0004
    dw $0000
    dw $0000
    dw $FF0A  ; opcode $0A
    dw $0000
    dw $0010
    dw $FF12  ; write_ram
    dw $C8ED
    dw $000D
    dw $FF0D  ; npc_write
    dw $0003
    dw $0000
    dw $0000
    dw $FF0A  ; opcode $0A
    dw $0000
    dw $0010
    dw $FF12  ; write_ram
    dw $C8ED
    dw $000F
    dw $FF0D  ; npc_write
    dw $0002
    dw $0000
    dw $0000
    dw $FF4A  ; face_right
    dw $0002
    dw $FF4A  ; face_right
    dw $0003
    dw $FF4A  ; face_right
    dw $0004
    dw $FF0A  ; opcode $0A
    dw $0000
    dw $0010
    dw $FF0B  ; opcode $0B
    dw $0000
    dw $FFF0
    dw $FF49  ; npc_show
    dw $0000
    dw $FF08  ; nop
    dw $FF0D  ; npc_write
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
    dw $FF47  ; face_up
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
    dw $FF0D  ; npc_write
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
    dw $FF47  ; face_up
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
    dw $FF47  ; face_up
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
    dw $FF47  ; face_up
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
    dw $FF47  ; face_up
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
    dw $FF0D  ; npc_write
    dw $0004
    dw $0010
    dw $0000
    dw $FF0D  ; npc_write
    dw $0004
    dw $001A
    dw $0060
    dw $FF0D  ; npc_write
    dw $0004
    dw $0000
    dw $0000
    dw $FF09  ; delay
    dw $0010
    dw $FF0D  ; npc_write
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

CustomRoom7_StateRules:
    db 1
    dw wCustomStep_ArenaClone_S1
    dw CustomRoom7_S1_Rules
    db $FF
CustomRoom7_S1_Rules:
    db 1, 1   ; state 1 when $0030
    dw $0030
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

RoomAttr_72:    ; arena_clone: render rows, screen 0-15 (S137, CAP2c)
    dw ScrAttr_72_0, ScrAttr_72_1, ScrAttr_72_2, $0000
    dw $0000, $0000, $0000, $0000
    dw $0000, $0000, $0000, $0000
    dw $0000, $0000, $0000, $0000
ScrAttr_72_0:
    dw wCustomStep_Room72_S0    ; step counter
    db 1    ; states
    db $04, $64    ; state 0: attr entry, bank
    dw RPal_72_0    ; state 0: palette pal_arena_clone
ScrAttr_72_1:
    dw wCustomStep_ArenaClone_S1    ; step counter
    db 2    ; states
    db $05, $64    ; state 0: attr entry, bank
    dw RPal_72_0    ; state 0: palette pal_arena_clone
    db $05, $64    ; state 1: attr entry, bank
    dw RPal_72_0    ; state 1: palette pal_arena_clone
ScrAttr_72_2:
    dw wCustomStep_Room72_S2    ; step counter
    db 1    ; states
    db $06, $64    ; state 0: attr entry, bank
    dw RPal_72_0    ; state 0: palette pal_arena_clone
RPal_72_0:   ; palette pal_arena_clone (slots 0-3)
    db $D0, $19, $FF, $6B, $3D, $43, $00, $00
    db $32, $05, $FF, $6B, $9F, $02, $00, $00
    db $32, $05, $FF, $6B, $99, $2E, $00, $00
    db $32, $05, $FF, $6B, $99, $2E, $00, $00

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

RoomAttr_73:    ; island_copy: render rows, screen 0-15 (S137, CAP2c)
    dw ScrAttr_73_0, $0000, $0000, $0000
    dw ScrAttr_73_4, $0000, $0000, $0000
    dw $0000, $0000, $0000, $0000
    dw $0000, $0000, $0000, $0000
ScrAttr_73_0:
    dw wCustomStep_Room73_S0    ; step counter
    db 1    ; states
    db $01, $64    ; state 0: attr entry, bank
    dw RPal_73_0    ; state 0: palette pal_6b
ScrAttr_73_4:
    dw wCustomStep_Room73_S4    ; step counter
    db 1    ; states
    db $03, $64    ; state 0: attr entry, bank
    dw RPal_73_0    ; state 0: palette pal_6b
RPal_73_0:   ; palette pal_6b (slots 0-3)
    db $EE, $04, $FF, $6B, $7A, $02, $00, $00  ; palette 0  04ee 6bff 027a 0000
    db $40, $7D, $FF, $6B, $81, $7F, $00, $00  ; palette 1  7d40 6bff 7f81 0000
    db $F0, $00, $FF, $6B, $1A, $02, $00, $00  ; palette 2  00f0 6bff 021a 0000
    db $A1, $01, $FF, $6B, $AA, $03, $00, $00  ; palette 3  01a1 6bff 03aa 0000

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
    dw CustomText_20   ; $0A20: quest mini_medal_quest: complete
    dw CustomText_21   ; $0A21: quest mini_medal_quest: progress
    dw CustomText_22   ; $0A22: quest mini_medal_quest: offer
    dw CustomText_23   ; $0A23: quest mini_medal_quest: accept
    dw CustomText_24   ; $0A24: quest mini_medal_quest: decline
    dw CustomText_25   ; $0A25: quest mini_medal_quest: done
    dw CustomText_26   ; $0A26: [S73] Anchor gate-side confirm [Y/N]
    dw CustomText_27   ; $0A27: [S73] Anchor return confirm [Y/N] — charge lands on arrival
    dw CustomText_28   ; $0A28: [S73] cast in a special/boss/custom gate room
    dw CustomText_29   ; $0A29: [S73] cast in town with no stored anchor

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

; $0A20 — quest mini_medal_quest: complete
CustomText_20:
    db $EA, $9F, $A3
    db "Two TinyMedals!", $EF, $EE
    db "Here are 500 gold.", $F7, $F0

; $0A21 — quest mini_medal_quest: progress
CustomText_21:
    db $EA, $9F, $A3
    db "Two TinyMedals,", $EF, $EE
    db "please.", $F7, $F0

; $0A22 — quest mini_medal_quest: offer
CustomText_22:
    db $EA, $9F, $A3
    db "I keep the", $EF, $EE
    db "vault. Bring me", $FA, $F7, $EF, $EE
    db "two TinyMedals?", $E7, $F0

; $0A23 — quest mini_medal_quest: accept
CustomText_23:
    db $EA, $9F, $A3
    db "Splendid. Two", $EF, $EE
    db "TinyMedals, then!", $F7, $F0

; $0A24 — quest mini_medal_quest: decline
CustomText_24:
    db $EA, $9F, $A3
    db "Another time.", $F7, $F0

; $0A25 — quest mini_medal_quest: done
CustomText_25:
    db $EA, $9F, $A3
    db "The vault thanks", $EF, $EE
    db "you.", $F7, $F0

; $0A26 — [S73] Anchor gate-side confirm [Y/N]
CustomText_26:
    db $EA, $9F, $A3
    db "Set an anchor", $EF, $EE
    db "here and warp", $EF, $EE
    db "to GreatTree?", $EF, $EE, $E7, $F0

; $0A27 — [S73] Anchor return confirm [Y/N] — charge lands on arrival
CustomText_27:
    db $EA, $9F, $A3
    db "Spend most MP", $EF, $EE
    db "to return to the", $EF, $EE
    db "anchored floor?", $EF, $EE, $E7, $F0

; $0A28 — [S73] cast in a special/boss/custom gate room
CustomText_28:
    db $EA, $9F, $A3
    db "The anchor", $EF, $EE
    db "fails here!", $F7, $F0

; $0A29 — [S73] cast in town with no stored anchor
CustomText_29:
    db $EA, $9F, $A3
    db "No anchor", $EF, $EE
    db "is set!", $F7, $F0

PLACE_TEXT_FIRST EQU 0

; =============================================================================
; VANILLA-ROOM EXIT EXTENSIONS (S70, generated)
; Read by bank $60 entry 7 (VanillaExitResolve, template head) on
; EVERY non-gate room step via bank $0B RoomEntry6_ExitChecker.
; Variant selected by [step_counter], clamped to n_steps-1.
; Lists are copied to wCustomExitBuffer (<= 17 rows + terminator).
; =============================================================================
VanillaExitExtTable:
    db $16, $FF   ; mapID, screen ($FF = any) — MedalMan + Medal Vault door at (1,2); per-step lists mirror disassembly Exit_MedalManRoom_s0/_v1/_v2 (steps 0/1-2-4-5/3) + the door row
    dw $D95E   ; vanilla step counter (WRAM)
    db 6   ; n_steps (variant count)
    dw VExt16_V0, VExt16_V1, VExt16_V1, VExt16_V2, VExt16_V1, VExt16_V1   ; per-step variant lists (deduped)
    db $01, $08   ; mapID, screen ($FF = any) — entrance_redirects: vanilla $01 screen 8 (5,3)->room:$72, (4,5)->room:$6B
    dw $D931   ; vanilla step counter (WRAM)
    db 3   ; n_steps (variant count)
    dw VExt01_V0, VExt01_V0, VExt01_V0   ; per-step variant lists (deduped)
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

VExt01_V0:
    db $05, $03, $72, $00, $01, $04, $07  ; S92 testing stance as DATA (S94b): GreatTree 2F Library door (5,3) -> arena_clone $72 screen 1 spawn (4,7); vanilla dest was Library $12
    db $04, $05, $6B, $00, $00, $07, $06  ; S1-era Room $6B entrance as DATA (S94b): GreatTree 2F (4,5) -> gate_island $6B spawn (7,6); vanilla dest was $18
    db $FF

; =============================================================================
; VANILLA-ROOM NPC OVERRIDES — gate swirls (S117, generated)
; Read by bank $60 entry 1 (CustomReadInteract) for every vanilla room
; via bank $0B GetRoomDataPtr; no row = the vanilla list unchanged.
; =============================================================================
VanillaNPCExtTable:
    db $FF   ; table terminator

PLACE_COUNT EQU 9
TEXT_SECTIONS EQU 1
