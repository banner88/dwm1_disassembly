; =============================================================================
; BANK $76 — ENCOUNTER LISTS (S114; compiler-owned, patches/bank_076.asm)
; =============================================================================
; Which wild-monster LIST a battle draws from (ROADMAP P3.13a; PROJECT_COMPILER
; §2.30; DATA_STRUCTURES "Encounter pool entry" + "Encounter list choice").
;
; Vanilla: bank $01 LoadNextDungeonFloor computed the list number from
; wGateID + wCurrentFloor (GateBasePoolIndex + GateFloorBreakpoints), stored it
; in wEncounterPoolIndex and every reader re-derived EncounterPoolData +
; number*26 + offset. Patched (S114, patches/bank_001.asm, all same size):
; LoadNextDungeonFloor far-calls entry 0 below, copies the chosen list (26 B)
; into wEncListBuf (vanilla numbers 0-127 from bank $01; project lists 128+
; are copied HERE) and loads the rate code; EncounterMonsterSelect,
; SaveRegsForEncounter and LoadFloorAndEncounterData read wEncListBuf.
;
; Entry 0 (HL=$7600) EncResolve — returns
;     D = the list number (0-127 vanilla EncounterPoolData, 128+ = project list
;         D-128 of ProjectEncLists, already copied to wEncListBuf)
;     E = the floor's VALUE number (wEncounterPoolIndex: its one other reader,
;         the gold lying on depth-tier-3 gate floors, bank $01 $5AF8, scales
;         with it — always the VANILLA list number of the gate floor, so a
;         gate given its own lists keeps its treasure)
;     B = rate code override for wC8A9 ($FF = the list's own +0)
;   Order: (1) a CUSTOM room (wInGateworld = 0, wMapID >= $6B) whose
;   EncRoomTable row names a variant list -> the first variant whose flag
;   terms hold; (2) else the gate (wGateID, wCurrentFloor): the vanilla number,
;   replaced by the gate's own plan when GatePlanPtrs has one (first variant
;   whose terms hold -> its floor runs). A room row's rate applies in both
;   cases (a room can keep the gate's list and change only the rate).
;   No RNG is drawn here: battles roll exactly as vanilla.
;
; Data (generated below the template):
;   EncRoomTable: ENC_ROOM_LEN x [dw variant list (0 = none), db rate ($FF)],
;     index wMapID - CUSTOM_ROOM_START.
;   GatePlanPtrs: GATE_PLAN_LEN x dw (0 = vanilla), index wGateID (0-255).
;   Variant list: records [db n_terms][n_terms x dw flag (bit 15 = must be
;     CLEAR)][dw target]; the last record has n_terms 0 (always holds).
;     Room target = the list number; gate target = a floor-run list.
;   Floor runs: [db last_floor, db list] ..., the game's floor numbering
;     (wCurrentFloor + 1, the first floor is 1); the last run has $FF.
;   ProjectEncLists: 26 B per project list (the EncounterPoolData format).
;   VanillaGateBase / VanillaGateBpPtrs / VanillaBreakpoints: byte copies of
;     bank $01 GateBasePoolIndex / GateFloorBreakpoints / FloorBreakpointData
;     (the vanilla rule, gates 0-31). A NEW gate (32+, S115) takes the
;     vanilla rule of the gate it copies (NewGateSource); other numbers 0.
;
; Entry 1 (HL=$7601) NewGateRowCopy (S115, ROADMAP NG1 — new gates): called
;   by bank $16 GateRowPtr for wGateID >= 32. A project new gate (number
;   32 .. 32+NEW_GATE_LEN-1) has its 8-byte GateFloorDataTable-format row
;   copied from NewGateRows to wGateRowBuf and returns E = 1; any other
;   number returns E = 0 (bank $16 then reads the vanilla wrap, gate & 31).
;   Keeps BC; clobbers A, D, HL (rst $10 hands DE / HL back to the caller
;   unchanged and destroys A — KEY_LESSONS v3; GateRowPtr reads E, then
;   restores its own DE and sets HL).
;   NewGateRows: NEW_GATE_LEN x 8 B, index wGateID - 32.
;   NewGateSource: NEW_GATE_LEN x db, the vanilla gate (0-31) each new gate
;     copies — its encounter rule and floor value (EncVanillaNumber).
; =============================================================================

SECTION "ROM Bank $076", ROMX[$4000], BANK[$76]

    db $76                              ; bank self-ID at $4000

; rst-$10 entry table at $4001
    dw EncResolve                       ; entry 0  (HL=$7600)
    dw NewGateRowCopy                   ; entry 1  (HL=$7601, S115)

ENC_VANILLA_GATES EQU 32

EncResolve:
    ld b, $FF                           ; rate: the list's own
    ld a, [wInGateworld]
    or a
    jr nz, .gate                        ; a gate maze floor
    ld a, [wMapID]
    sub CUSTOM_ROOM_START
    jr c, .gate                         ; a vanilla room: vanilla rule
    cp ENC_ROOM_LEN
    jr nc, .gate
    ld l, a
    ld h, $00
    ld e, l
    ld d, h
    add hl, hl
    add hl, de                          ; HL = index * 3
    ld de, EncRoomTable
    add hl, de
    ld a, [hl+]
    ld e, a
    ld a, [hl+]
    ld d, a                             ; DE = the room's variant list
    ld b, [hl]                          ; B = the room's rate ($FF = none)
    ld a, d
    or e
    jr z, .gate                         ; no list of its own: the gate's
    ld h, d
    ld l, e
    push bc
    call EncPickVariant                 ; HL -> target (dw list number)
    pop bc
    ld a, [hl]
    ld d, a                             ; D = list
    ld e, a                             ; E = value (not a gate floor)
    jr .copy
.gate:
    push bc
    call EncVanillaNumber               ; A = the vanilla list number
    pop bc
    ld d, a
    ld e, a
    ld a, [wGateID]
    cp GATE_PLAN_LEN
    jr nc, .copy                        ; no plan table entry
    ld l, a
    ld h, $00
    add hl, hl
    push de
    ld de, GatePlanPtrs
    add hl, de
    pop de
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    or h
    jr z, .copy                         ; this gate keeps the vanilla rule
    push de
    push bc
    call EncPickVariant                 ; HL -> target (dw floor runs)
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call EncFloorRun                    ; A = this floor's list
    pop bc
    pop de
    ld d, a                             ; D = list, E keeps the vanilla value
.copy:
    ld a, d
    bit 7, a
    ret z                               ; vanilla list: bank $01 copies it
    and $7F                             ; project list D-128 -> wEncListBuf
    push bc
    push de
    ld l, a
    ld h, $00
    add hl, hl                          ; 2n
    ld d, h
    ld e, l
    add hl, hl                          ; 4n
    add hl, hl                          ; 8n
    ld b, h
    ld c, l
    add hl, hl                          ; 16n
    add hl, bc                          ; 24n
    add hl, de                          ; 26n
    ld de, ProjectEncLists
    add hl, de
    ld de, wEncListBuf
    ld c, 26
.loop:
    ld a, [hl+]
    ld [de], a
    inc de
    dec c
    jr nz, .loop
    pop de
    pop bc
    ret

; EncPickVariant: HL -> a variant list. Returns HL -> the dw target of the
; first record whose flag terms all hold (the last record has none).
; Clobbers A, BC, DE.
EncPickVariant:
    ld a, [hl+]                         ; n_terms
    or a
    ret z                               ; no terms: always holds
    ld d, a                             ; D = terms left
    push hl                             ; [sp] = first term
.term:
    ld a, [hl+]
    ld c, a
    ld a, [hl+]
    ld b, a                             ; BC = flag word
    push hl
    and $80
    ld e, a                             ; E bit 7 = the flag must be CLEAR
    res 7, b
    push de
    call TestEventFlag                  ; Z = clear, NZ = set (clobbers A, HL)
    pop de
    pop hl
    jr z, .isClear
    bit 7, e
    jr nz, .fail                        ; set, but must be clear
    jr .held
.isClear:
    bit 7, e
    jr z, .fail                         ; clear, but must be set
.held:
    dec d
    jr nz, .term
    pop af                              ; drop the first-term pointer
    ret                                 ; HL -> target
.fail:
    pop hl                              ; first term
    dec hl
    ld a, [hl+]                         ; n_terms
    add a
    add 2                               ; terms + the dw target
    ld e, a
    ld d, $00
    add hl, de                          ; HL -> the next record
    jr EncPickVariant

; EncFloorRun: HL -> floor runs. A := the list of the run holding the floor
; (wCurrentFloor + 1). Clobbers C, HL.
EncFloorRun:
    ld a, [wCurrentFloor]
    inc a
    ld c, a
.run:
    ld a, [hl+]                         ; last floor of this run
    cp c
    jr nc, .take                        ; floor <= last
    inc hl
    jr .run
.take:
    ld a, [hl]
    ret

; EncVanillaNumber: A := the vanilla list number of (wGateID, wCurrentFloor) —
; bank $01 LoadNextDungeonFloor's walk, on the byte copies below. A new gate
; (S115) walks the gate it copies (NewGateSource); other numbers past the 32
; vanilla gates give 0. Clobbers C, DE, HL.
EncVanillaNumber:
    ld a, [wGateID]
    cp ENC_VANILLA_GATES
    jr c, .vanilla
    sub ENC_VANILLA_GATES
    cp NEW_GATE_LEN
    jr nc, .none                        ; not a project new gate
    ld e, a
    ld d, $00
    ld hl, NewGateSource
    add hl, de
    ld a, [hl]                          ; the vanilla gate it copies
    jr .vanilla
.none:
    xor a
    ret
.vanilla:
    ld e, a
    ld d, $00
    ld hl, VanillaGateBase
    add hl, de
    ld a, [hl]
    push af                             ; A = the gate's first list
    ld hl, VanillaGateBpPtrs
    add hl, de
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a                             ; HL = its floor breakpoints
    ld c, $FF
.walk:
    ld a, [wCurrentFloor]
    inc a
    cp [hl]                             ; floor >= breakpoint: next list
    inc c
    inc hl
    jr nc, .walk
    pop af
    add c
    ret

; NewGateRowCopy (entry 1, S115): see the header. E = 1 copied, 0 = not a
; project new gate.
NewGateRowCopy:
    ld e, $00
    ld a, [wGateID]
    sub ENC_VANILLA_GATES
    ret c                               ; a vanilla gate (bank $16 reads it)
    cp NEW_GATE_LEN
    ret nc                              ; not a project new gate
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    add hl, hl                          ; (gate - 32) * 8
    ld de, NewGateRows
    add hl, de
    ld de, wGateRowBuf
    ld a, 8
.copy:
    push af
    ld a, [hl+]
    ld [de], a
    inc de
    pop af
    dec a
    jr nz, .copy
    ld e, $01
    ret

; =============================================================================
; ENCOUNTER DATA (generated by editor2 `enc76` from custom.encounter_lists,
; custom.rooms[].encounters, custom.gates[].encounters — PROJECT_COMPILER §2.30)
; =============================================================================

ENC_ROOM_LEN EQU 9
EncRoomTable:  ; [dw variant list (0 = none), db rate ($FF = the list's)]
    dw 0
    db $FF  ; $6B gate_island
    dw 0
    db $FF  ; $6C dusk_mirror
    dw 0
    db $FF  ; $6D gate_rotation
    dw 0
    db $FF  ; $6E reserved_6e
    dw 0
    db $FF  ; $6F reserved_6f
    dw 0
    db $FF  ; $70 ember_keystone
    dw 0
    db $FF  ; $71 medal_vault
    dw 0
    db $FF  ; $72 arena_clone
    dw 0
    db $FF  ; $73 island_copy


GATE_PLAN_LEN EQU 0
GatePlanPtrs:  ; dw per gate number (0 = the vanilla rule)


NEW_GATE_LEN EQU 0
NewGateRows:  ; 8 B per gate 32+ [ft1, ft2, ft3, floors, boss map, boss x, boss y, tier]
NewGateSource:  ; db per gate 32+: the vanilla gate it copies

ProjectEncLists:  ; 26 B each, numbers 128+ (EncounterPoolData format)

; byte copies of bank $01 GateBasePoolIndex / GateFloorBreakpoints /
; FloorBreakpointData (extracted/gamedata_vanilla.json) — the vanilla rule
VanillaGateBase:
    db 0, 1, 3, 5, 7, 9, 12, 15
    db 18, 22, 26, 30, 34, 39, 44, 49
    db 54, 59, 64, 69, 74, 79, 85, 89
    db 93, 97, 101, 105, 109, 113, 117, 121
VanillaGateBpPtrs:
    dw VanillaBreakpoints + 0, VanillaBreakpoints + 1, VanillaBreakpoints + 1, VanillaBreakpoints + 1
    dw VanillaBreakpoints + 1, VanillaBreakpoints + 1, VanillaBreakpoints + 4, VanillaBreakpoints + 4
    dw VanillaBreakpoints + 4, VanillaBreakpoints + 8, VanillaBreakpoints + 8, VanillaBreakpoints + 8
    dw VanillaBreakpoints + 12, VanillaBreakpoints + 1, VanillaBreakpoints + 12, VanillaBreakpoints + 17
    dw VanillaBreakpoints + 17, VanillaBreakpoints + 4, VanillaBreakpoints + 22, VanillaBreakpoints + 22
    dw VanillaBreakpoints + 22, VanillaBreakpoints + 27, VanillaBreakpoints + 33, VanillaBreakpoints + 33
    dw VanillaBreakpoints + 33, VanillaBreakpoints + 33, VanillaBreakpoints + 33, VanillaBreakpoints + 33
    dw VanillaBreakpoints + 33, VanillaBreakpoints + 33, VanillaBreakpoints + 33, VanillaBreakpoints + 37
VanillaBreakpoints:
    db $FF, $03, $06, $FF, $04, $06, $09, $FF, $04, $06, $09, $FF, $04, $06, $09, $0D
    db $FF, $05, $09, $0D, $11, $FF, $06, $0B, $10, $15, $FF, $06, $0B, $10, $15, $1A
    db $FF, $06, $0B, $15, $FF, $06, $0B, $15, $29, $3D, $51, $FF
