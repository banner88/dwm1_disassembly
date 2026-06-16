; =============================================================================
; BANK $0B — ROOM SYSTEM
; =============================================================================
; This bank contains the entire room loading pipeline:
;   - Tileset/graphics loading (entries 0,1)
;   - Screen/scroll management (entry 2)
;   - NPC interaction dispatch (entries 3,4,5)
;   - Exit detection — runs EVERY STEP (entry 6)
;   - Room initialization after transition (entry 7)
;   - Step block reader (entry 8)
;   - Special room handlers (entry 9)
;
; Cross-bank calls use `rst $10` where HL = (bank << 8) | entry_index.
; rst $10 saves current bank, switches to bank H, calls $4001+(L*2) jump
; table entry, then restores original bank.
;
; Room Data Chain:
;   ptr_table[$4B43 + mapID*2] → screen_ptr_block (N screen slots × 2, varies per room)
;     → step_block: [ram_flag_ptr:2] then [step_entry × N] + terminator
;       → step_entry (6 bytes): [step_id:1][tileset:1][interact_ptr:2][exit_ptr:2]
;         → interact_block: NPC entries (5 bytes each) + $FF terminator
;         → exit_block: exit entries (7 bytes each) + $FF terminator
;
; Sources: Mallos31/dwm disassembly, NiyaDev/DWM rst docs,
;          user reverse-engineering (ROUTING_DISCOVERIES.md, NPC_AND_ROUTING_HANDOFF.md)
; =============================================================================

SECTION "ROM Bank $00b Code", ROMX[$4000], BANK[$b]
    db $0b	; ROM bank ID

; -----------------------------------------------------------------------------
; JUMP TABLE — dispatched via rst $10 with H=$0B
; Called from bank $51 game loop. Entry = L value in HL before rst $10.
; -----------------------------------------------------------------------------
    dw RoomEntry0_TilesetLoader     ; Entry 0: load tileset + apply map change
    dw RoomEntry1_GraphicsLoader    ; Entry 1: load tileset only (no map change)
    dw RoomEntry2_ScreenScroll      ; Entry 2: screen/scroll position manager
    dw RoomEntry3_NPCDispatch       ; Entry 3: NPC interaction handler
    dw RoomEntry4_NPCMovement       ; Entry 4: NPC movement/patrol
    dw RoomEntry5_NPCRender         ; Entry 5: NPC sprite render
    dw RoomEntry6_ExitChecker       ; Entry 6: exit detection (RUNS EVERY STEP)
    dw RoomEntry7_RoomInit          ; Entry 7: room initializer (after transition)
    dw ReadStepBlock                ; Entry 8: read step_id + tileset from ptr table
    dw RoomEntry9_SpecialRooms      ; Entry 9: special room handlers (mazes, arenas)

; =============================================================================
; ENTRY 0: RoomEntry0_TilesetLoader ($4015)
; =============================================================================
; Called during room transitions. If wIsPlayerChangingMaps is set, copies the
; destination map_type from $C96D to wMapID (making the transition "real").
; Then loads the tileset graphics from the tileset table at $26DD (normal) or
; $2A5D (gate worlds). Does NOT read the room pointer table at $4B43.
; -----------------------------------------------------------------------------
RoomEntry0_TilesetLoader:
labelb_4015:
    ld a, [wIsPlayerChangingMaps]   ; $C96C — is a map change pending?
    or a
    jr z, jr_00b_4027               ; skip if no pending change

    ; Apply pending map change: copy destination to active
    ld a, [wWarpGateId]                   ; destination map_type (set by exit checker)
    ld [wMapID], a                  ; $C968 — now the active map
    ld a, [wWarpFlag]                   ; destination gate flag
    ld [wInGateworld], a            ; $C969 — gate/normal mode

jr_00b_4027:
    ld hl, $1605	; rst $10: bank $16, entry 5 — tileset prep function
    rst $10



    ; Select tileset table based on gate flag
    ; Normal rooms: $26DD (bank 0), Gate rooms: $2A5D (bank 0)
    ; Each entry is 8 bytes: [gfx_ptr:2][spawn_data:6]
    ld de, $26dd                    ; tileset_table (normal rooms)
    ld a, [wInGateworld]
    or a
    jr z, jr_00b_4037

    ld de, $2a5d                    ; tileset_table (gate rooms)

jr_00b_4037:
    ; Index into table: DE = tileset_table + mapID * 8
    ; For custom rooms: raw mapID indexes the $2A35 entry (combined tileset)
    call CustomGFXMapID         ; ROM0: raw mapID for $6B → reads $2A35 (bank $67)
    ld l, a
    ld h, $00
    add hl, hl                      ; × 2
    add hl, hl                      ; × 4
    add hl, hl                      ; × 8
    add hl, de                      ; HL = &tileset_table[mapID]
    ld e, [hl]
    inc hl
    ld d, [hl]
    inc hl
    push hl
    ld hl, $9000
    call WaitDMATransfer
    ld a, [wMapID]
    ld a, $08
    jr nz, jr_00b_4076

    ld de, $291d
    ld hl, $8800
    call WaitDMATransfer
    xor a
    ld [$c8a6], a
    ld [$c8a7], a
    jr jr_00b_4076

    ld a, [$d951]
    cp $07
    jr nz, jr_00b_4076

    xor a
    ld hl, $c0d8
    ld bc, $0028
    call FillNBytesWithRegA

jr_00b_4076:
    pop hl
    ld a, [hl+]
    ldh [$9d], a
    ld a, [hl+]
    ldh [$9e], a
    ld a, [hl+]
    ldh [$9f], a
    ld a, [hl]
    ldh [$a0], a
    ld hl, $1606
    rst $10
    ret

; =============================================================================
; ENTRY 1: RoomEntry1_GraphicsLoader ($4088)
; =============================================================================
; Same as Entry 0 but WITHOUT applying pending map change.
; Used for graphics refresh when room doesn't change (e.g., screen scroll).
; Does NOT read the room pointer table at $4B43.
; Reads from tileset table $26DD/$2A5D only.
; -----------------------------------------------------------------------------
RoomEntry1_GraphicsLoader:
labelb_4088:
    ld de, $26dd
    ld a, [wInGateworld]
    or a
    jr z, jr_00b_4094

    ld de, $2a5d

jr_00b_4094:
    ; For custom rooms: raw mapID indexes the $2A35 entry (combined tileset)
    call CustomGFXMapID         ; ROM0: raw mapID for $6B → reads $2A35 (bank $67)
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
    inc hl
    push hl
    ld hl, $9000
    call WaitDMATransfer
    ld a, [wMapID]
    ld a, $08
    jr nz, jr_00b_40c0

    ld de, $291d
    ld hl, $8800
    call WaitDMATransfer
    xor a
    ld [$c8a6], a
    ld [$c8a7], a

jr_00b_40c0:
    pop hl
    ld a, [hl+]
    ldh [$9d], a
    ld a, [hl+]
    ldh [$9e], a
    ld a, [hl+]
    ldh [$9f], a
    ld a, [hl]
    ldh [$a0], a
    ret

RoomEntry2_ScreenScroll:
labelb_40ce:
    ldh a, [$95]
    ld l, a
    ldh a, [$96]
    ld h, a
    ld a, $80
    call Div16x8To16
    ld a, l
    add a
    add a
    ld [wScreenIndex], a
    ld a, $80
    ld c, l
    ld b, h
    call Mul16x8To24
    ld a, l
    ldh [$bb], a
    ld a, h
    ldh [$bc], a
    ldh a, [$92]
    ld l, a
    ldh a, [$93]
    ld h, a
    ld a, $a0
    call Div16x8To16
    ld a, [wScreenIndex]
    add l
    ld [wScreenIndex], a
    ld a, $a0
    ld c, l
    ld b, h
    call Mul16x8To24
    ld a, l
    ldh [$b7], a
    ld a, h
    ldh [$b8], a
    ld a, [wGameState]
    bit 1, a
    jr nz, jr_00b_4134

    bit 3, a
    jr nz, jr_00b_4134

    ld hl, $1700
    rst $10
    ld a, [$c8ea]
    bit 7, a
    jr nz, jr_00b_4134

    call LoadRoom_4239
    ld hl, $c300
    call WaitLCDTransfer
    ld de, $c300
    call LoadRoom_4309
    ld hl, $1701
    rst $10

jr_00b_4134:
    ld a, [wIsGBC]
    or a
    jr z, jr_00b_41b3

    di
    call WaitVRAM
    ld a, $01
    ldh [rVBK], a
    ei
    ldh a, [$bb]
    and $f8
    ld l, a
    xor a
    sla l
    rla
    sla l
    rla
    ld h, $98
    add h
    ld h, a
    ldh a, [$b7]
    rrca
    rrca
    rrca
    and $1f
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld de, $c200
    ld c, $10

jr_00b_4165:
    ld b, $0a
    push hl

jr_00b_4168:
    ld a, [de]
    swap a
    and $0f
    call Write_gfx_tile
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
    ld a, [de]
    and $0f
    call Write_gfx_tile
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
    inc de
    dec b
    jr nz, jr_00b_4168

    pop hl
    ld a, e
    add $06
    ld e, a
    ld a, d
    adc $00
    ld d, a
    push bc
    ld bc, $0020
    add hl, bc
    ld a, h
    and $03
    or $98
    ld h, a
    pop bc
    dec c
    jr nz, jr_00b_4165

    di
    call WaitVRAM
    ld a, $00
    ldh [rVBK], a
    ei

jr_00b_41b3:
    ldh a, [$bb]
    and $f8
    ld l, a
    xor a
    sla l
    rla
    sla l
    rla
    ld h, $98
    add h
    ld h, a
    ldh a, [$b7]
    rrca
    rrca
    rrca
    and $1f
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld de, $c300
    ld c, $10

jr_00b_41d5:
    ld b, $14
    push hl

jr_00b_41d8:
    ld a, [de]
    call Write_gfx_tile
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
    inc de
    dec b
    jr nz, jr_00b_41d8

    pop hl
    ld a, e
    add $0c
    ld e, a
    ld a, d
    adc $00
    ld d, a
    push bc
    ld bc, $0020
    add hl, bc
    ld a, h
    and $03
    or $98
    ld h, a
    pop bc
    dec c
    jr nz, jr_00b_41d5

    ld a, [wScreenIndex]
    ld hl, $c950
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $01
    ret

RoomEntry3_NPCDispatch:
labelb_4213:
    ld hl, $1700
    rst $10
    call LoadRoom_4239
    ld hl, $c500
    call WaitLCDTransfer
    ld de, $c500
    call LoadRoom_4309
    ld hl, $1701
    rst $10
    ld a, [wScreenIndex]
    ld hl, $c950
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $01
    ret


; =============================================================================
; ENTRY 8: ReadStepBlock ($4239)
; =============================================================================
; Reads step_id and tileset from the room pointer table.
; Returns: DE = [step_id, tileset] (first 2 bytes of current step entry)
;
; THIS IS ONE OF FOUR FUNCTIONS THAT READ THE POINTER TABLE AT $4B43.
; All four share identical pointer-chasing code but return different fields:
;   ReadStepBlock ($4239): returns bytes 0-1 (step_id + tileset) → DE
;   ReadInteractPtr ($4274): skips 2, returns bytes 2-3 (interact_ptr) → HL
;   ExitChecker ($451D): skips 4, returns bytes 4-5 (exit_ptr) → HL
;   ~$44A7 func: skips 4, returns bytes 4-5 (exit_ptr) → HL
;
; For cross-bank rooms, ALL FOUR must be modified to support data
; outside bank $0B. This is the key architectural constraint.
; -----------------------------------------------------------------------------
ReadStepBlock:
LoadRoom_4239:
    ld a, [wInGateworld]            ; gate rooms use different path
    or a
    jr z, jr_00b_4244

    ld hl, $1609                    ; rst $10: bank $16, entry 9 — gate step reader
    rst $10
    ret


jr_00b_4244:
    ; Check for custom overflow room
    ld a, [wMapID]
    cp CUSTOM_ROOM_START
    jr c, .normalStep
    ld hl, $6000                ; rst $10: bank $60, entry 0 (CustomReadStep)
    rst $10
    ret
.normalStep:
    ; Shared pointer table read → HL = step_entry
    call SharedPtrChase

    ; ReadStepBlock specific: return bytes 0-1 as DE
    ld e, [hl]                      ; step_id
    inc hl
    ld d, [hl]                      ; tileset byte
    ret


; =============================================================================
; ReadInteractPtr ($4274)
; =============================================================================
; Reads the interact_ptr (NPC data pointer) from the room pointer table.
; Returns: HL = interact_ptr (bytes 2-3 of current step entry)
;
; Same pointer-chasing as ReadStepBlock but skips step_id+tileset (2 bytes)
; and returns interact_ptr instead.
; Called by Entry 7 (RoomEntry7_RoomInit) to load NPC data after transition.
; -----------------------------------------------------------------------------
ReadInteractPtr:
; ---------------------------------------------------------------------------
; GetCurrentNPCList — Trace room data chain to find NPC interact block
; ---------------------------------------------------------------------------
; Follows the room data pointer chain to find the NPC list for the
; current room, screen, and step:
;
;   $4B43[wMapID × 2] → screen_ptr_block
;   screen_ptr_block[$C925 × 2] → step_block
;   step_block[0:2] → ram_flag_ptr (DE) → [DE] = current step_id
;   step_block + 2 + step_id × 6 → step_entry
;   step_entry[2:4] → interact_ptr = NPC list
;
; Output: HL = pointer to first NPC entry (5-byte entries, $FF terminated)
; ---------------------------------------------------------------------------
GetRoomDataPtr:
    ld a, [wInGateworld]
    or a
    jr nz, jr_00b_42ac       ; Gate world uses different lookup path

    ; Check for custom overflow room
    ld a, [wMapID]
    cp CUSTOM_ROOM_START
    jr c, .normalInteract
    ld hl, $6001                ; rst $10: bank $60, entry 1 (CustomReadInteract)
    rst $10
    ret
.normalInteract:
    ; Shared pointer table read → HL = step_entry
    call SharedPtrChase
    inc hl
    inc hl                   ; Skip byte 0 (step_id) and byte 1 (tileset)
    ld a, [hl+]
    ld h, [hl]
    ld l, a                  ; HL = interact_ptr (NPC list)
    ret


jr_00b_42ac:
    ld a, [$c926]
    cp $ff
    jr nz, jr_00b_42b7

    ld hl, $4308
    ret


jr_00b_42b7:
    ld hl, $42c8
    ld a, [$c92b]
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ret


    ret c

    ld b, d
    sbc $42
    db $e4
    ld b, d
    ld [$f042], a
    ld b, d
    or $42
    db $fc
    ld b, d
    ld [bc], a
    ld b, e
    rrca
    dec bc
    ld bc, $0101
    rst $38
    rrca
    dec bc
    ld bc, $0101
    rst $38
    rrca
    inc c
    ld bc, $0201
    rst $38
    rrca
    inc c
    ld bc, $0201
    rst $38
    rrca
    ld de, $0101
    inc bc
    rst $38
    rrca
    ld [$0101], sp
    inc b
    rst $38
    rrca
    rrca
    ld bc, $0501
    rst $38
    rrca
    ld b, $01
    ld bc, $ff06
    rst $38

LoadRoom_4309:
    ld a, [wInGateworld]
    or a
    ret z

    ld hl, $c960
    ld a, [wScreenIndex]
    cp [hl]
    ret nz

    ld a, [$c962]
    ld l, a
    ld a, [$c963]
    ld h, a
    add hl, de
    ld a, $3c
    ld [hl+], a
    inc a
    ld [hl], a
    ld a, l
    add $1f
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, $3e
    ld [hl+], a
    inc a
    ld [hl], a
    ret

RoomEntry4_NPCMovement:
labelb_4332:
    ld a, $00
    ldh [$d6], a
    ld hl, $d7d2
    call ReadRoom_433f
    ldh [$d5], a
    ret


ReadRoom_433f:
jr_00b_433f:
    ld a, [hl]
    cp $ff
    jr z, jr_00b_4366

    bit 6, a
    jr nz, jr_00b_4357

    call SaveRoom_43e5
    jr nz, jr_00b_4357

    ld a, l
    add $04
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl]
    ret


jr_00b_4357:
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ldh a, [$d6]
    inc a
    ldh [$d6], a
    jr jr_00b_433f

jr_00b_4366:
    ld a, $ff
    ldh [$d6], a
    call GetRoomDataPtr

jr_00b_436d:
    ld a, [hl]
    cp $ff
    ret z

    bit 7, a
    jr z, jr_00b_43a1

    and $f0
    cp $80
    jr nz, jr_00b_4397

    call CheckExitCoords
    jr nz, jr_00b_4397

    ld a, [hl]
    and $0f
    cp $0f
    jr z, jr_00b_438d

    ld b, a
    ldh a, [$8e]
    cp b
    jr nz, jr_00b_4397

jr_00b_438d:
    ld a, l
    add $04
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl]
    ret


jr_00b_4397:
    ld a, l
    add $05
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_00b_436d

jr_00b_43a1:
    ld a, $ff
    ret

; ---------------------------------------------------------------------------
; Entry 5: NPCScriptIDLookup — Find NPC at facing position, return script_id
; ---------------------------------------------------------------------------
; Called by bank $01 NPCTalkHandler when player presses A.
; Player position is pre-loaded to $FFDB-$FFDE by the caller.
;
; Flow:
;   1. Default $FFD5 = $FF (no NPC)
;   2. Guard: if $FF90 bit 6 set or $D8D7 non-zero → return
;   3. Call SearchNPCAtFacing:
;      a. Get current room's NPC list (interact block) via GetRoomDataPtr
;      b. Walk NPC entries (5 bytes each, $FF terminated)
;      c. For each: check type byte (bit 7 must be set = interactable)
;      d. If type & $F0 == $90: check if NPC is at player's facing position
;      e. If match: return byte 4 (script_id) in A
;      f. If no match: advance 5 bytes, check next NPC
;   4. Result stored to $FFD5 by caller
;
; NPC entry format (5 bytes): [type] [sprite] [X] [Y] [script_id]
; Returns: A = script_id ($FF if no interactable NPC found)
; ---------------------------------------------------------------------------
RoomEntry5_NPCRender:
labelb_43a4:
    ld a, $ff
    ldh [$d5], a             ; Default: no NPC found
    ldh a, [$90]
    bit 6, a
    ret nz                   ; Busy flag set → return

    ld a, [wScriptStateFlags]
    or a
    ret nz                   ; Script already running → return

    call SearchNPCAtFacing       ; Search for NPC at facing position
    ldh [$d5], a             ; Store result (script_id or $FF)
    ret


; ---------------------------------------------------------------------------
; NPCSearchAtFacing — Walk NPC list, find match at player's facing position
; ---------------------------------------------------------------------------
SearchNPCAtFacing:
    call GetRoomDataPtr       ; Get interact_block pointer for current room/step

jr_00b_43bb:
    ld a, [hl]               ; Read NPC type byte (byte 0)
    cp $ff
    ret z                    ; $FF terminator → no more NPCs, return $FF

    bit 7, a
    jr z, jr_00b_43e2        ; Bit 7 clear → NPC not interactable, return $FF

    and $f0
    cp $90
    jr nz, jr_00b_43d8       ; Type != $9x → skip this NPC

    call CheckExitCoords       ; Check if NPC is at player's facing position
    jr nz, jr_00b_43d8       ; Not at facing position → skip

    ; NPC found at facing position! Read script_id (byte 4)
    ld a, l
    add $04
    ld l, a
    ld a, h
    adc $00
    ld h, a                  ; HL = NPC entry + 4
    ld a, [hl]               ; A = script_id (byte 4 of NPC entry)
    ret


jr_00b_43d8:
    ld a, l
    add $05                  ; Advance to next NPC entry (+5 bytes)
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_00b_43bb           ; Check next NPC

jr_00b_43e2:
    ld a, $ff                ; No interactable NPC → return $FF
    ret


SaveRoom_43e5:
    push hl
    push bc
    push de
    ld a, l
    add $05
    ld l, a
    ld a, h
    adc $00
    ld h, a
    bit 0, [hl]
    jr nz, jr_00b_444c

    ld a, l
    add $13
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ldh a, [$db]
    sub [hl]
    inc hl
    ld c, a
    ldh a, [$dc]
    sbc [hl]
    inc hl
    ld b, a
    jr nz, jr_00b_440f

    ld a, c
    cp $10
    jr nc, jr_00b_444c

    jr jr_00b_4422

jr_00b_440f:
    ld a, c
    cpl
    add $01
    ld c, a
    ld a, b
    cpl
    adc $00
    ld b, a
    ld a, b
    or a
    jr nz, jr_00b_444c

    ld a, c
    cp $10
    jr nc, jr_00b_444c

jr_00b_4422:
    ldh a, [$dd]
    sub [hl]
    inc hl
    ld c, a
    ldh a, [$de]
    sbc [hl]
    ld b, a
    jr nz, jr_00b_4434

    ld a, c
    cp $10
    jr nc, jr_00b_444c

    jr jr_00b_4447

jr_00b_4434:
    ld a, c
    cpl
    add $01
    ld c, a
    ld a, b
    cpl
    adc $00
    ld b, a
    ld a, b
    or a
    jr nz, jr_00b_444c

    ld a, c
    cp $10
    jr nc, jr_00b_444c

jr_00b_4447:
    xor a
    pop de
    pop bc
    pop hl
    ret


jr_00b_444c:
    xor a
    inc a
    pop de
    pop bc
    pop hl
    ret


; ---------------------------------------------------------------------------
; CheckNPCAtFacing — Compare NPC position against player's facing position
; ---------------------------------------------------------------------------
; Input:  HL = pointer to NPC entry (byte 0 = type)
;         $FFDB/$FFDC = player facing X position
;         $FFDD/$FFDE = player facing Y position
; Output: Z = NPC is at facing position (match)
;         NZ = NPC is NOT at facing position
;
; Compares NPC entry bytes 2 (X) and 3 (Y) against computed facing coords.
; ---------------------------------------------------------------------------
CheckExitCoords:
    push hl
    push bc
    push de
    inc hl
    inc hl
    ldh a, [$db]
    swap a
    and $0f
    ld b, a
    ldh a, [$dc]
    swap a
    and $f0
    or b
    ld b, a
    ld a, $0a
    call Div8x8
    cp [hl]
    jr nz, jr_00b_444c

    inc hl
    ldh a, [$dd]
    swap a
    and $0f
    ld b, a
    ldh a, [$de]
    swap a
    and $f0
    or b
    ld b, a
    ld a, $08
    call Div8x8
    cp [hl]
    jr nz, jr_00b_444c

    jr jr_00b_4447



RoomEntry9_SpecialRooms:
labelb_4488:
    ld a, [$c850]
    or a
    ret nz

    ld a, [$c88e]
    or a
    ret nz

    ld a, [$c88f]
    or a
    ret nz

    ld a, [wGameState]
    bit 0, a
    ret nz

    ldh a, [$90]
    bit 0, a
    ret nz

    ld a, [wInGateworld]
    or a
    ret nz

    ; Shared pointer table read → HL = step_entry
    ; Check for custom overflow room
    ld a, [wMapID]
    cp CUSTOM_ROOM_START
    jr c, .normalSpecial
    ld hl, $6002                ; rst $10: bank $60, entry 2 (CustomExitCheck)
    rst $10
    jr .specialDataReady
.normalSpecial:
    call SharedPtrChase
    inc hl
    inc hl
    inc hl
    inc hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
.specialDataReady:
    ld bc, $2de7
    ld a, [wScreenIndex]
    add a
    add c
    ld c, a
    ld a, $00
    adc b
    ld b, a
    ld a, [bc]
    ld e, a
    inc bc
    ld a, [bc]
    ld d, a

jr_00b_44ec:
    ld a, [hl]
    cp $ff
    ret z

    ld a, [hl]
    or a
    jr z, jr_00b_4504

    cp $09
    jr z, jr_00b_4504

    inc hl
    ld a, [hl]
    dec hl
    or a
    jr z, jr_00b_4504

    cp $07
    jr z, jr_00b_4504

    jr jr_00b_4513

jr_00b_4504:
    ldh a, [$97]
    sub e
    cp [hl]
    jr nz, jr_00b_4513

    inc hl
    ldh a, [$98]
    sub d
    cp [hl]
    dec hl
    jp z, Jump_00b_45a8

jr_00b_4513:
    ld a, l
    add $07
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_00b_44ec


; =============================================================================
; ENTRY 6: RoomEntry6_ExitChecker ($451D)
; =============================================================================
; **RUNS EVERY GAME STEP** — checks if player is standing on an exit tile.
; This is the most performance-critical room function.
;
; For non-gate rooms: reads exit_ptr from pointer table, scans exit entries,
; compares player position against each exit's trigger coordinates.
; If match found, writes destination to $C96D and sets transition flag.
;
; For gate rooms: uses separate gate exit logic at Jump_00b_46a7.
;
; CRITICAL FOR CUSTOM ROOMS: This function reads the pointer table during
; EVERY step, including during the fade transition before Entry 7 runs.
; If the pointer table points to invalid data, this function will crash
; or block the state machine from advancing.
; 
; Exit entry format (7 bytes each, in the exit_block):
;   [trigger_X:1][trigger_Y:1][dest_map_type:1][gate_flag:1]
;   [screen_byte:1][spawn_X:1][spawn_Y:1]
; Terminated by $FF.
; -----------------------------------------------------------------------------
RoomEntry6_ExitChecker:
labelb_451d:
;check if text box open
    ld a, [wGameState]              ; $C8EB — current game UI state
    bit 0, a                        ; bit 0 = text box open
    jp nz, Jump_00b_4674            ; skip if text box open

    ldh a, [$90]                    ; animation/movement state
    bit 0, a
    jp nz, Jump_00b_4674            ; skip if animating

    ld a, [wInGateworld]            ; $C969
    or a
    jp nz, Jump_00b_46a7            ; gate rooms use separate exit logic

    ; Shared pointer table read → HL = step_entry
    ; Check for custom overflow room
    ld a, [wMapID]
    cp CUSTOM_ROOM_START
    jr c, .normalExit
    ld hl, $6002                ; rst $10: bank $60, entry 2 (CustomExitCheck)
    rst $10
    jr .exitDataReady
.normalExit:
    call SharedPtrChase

    ; Skip step_id(1) + tileset(1) + interact_ptr(2) = 4 bytes → exit_ptr
    inc hl
    inc hl
    inc hl
    inc hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a                         ; HL → exit_block (list of 7-byte exit entries)

.exitDataReady:

    ; Load screen offset from $2DE7 table for position comparison
    ld bc, $2de7                    ; screen position offset table (16 entries × 2)
    ld a, [wScreenIndex]                   ; screen_index
    add a                           ; × 2
    add c
    ld c, a
    ld a, $00
    adc b
    ld b, a                         ; BC → $2DE7[screen_index]
    ld a, [bc]
    ld e, a                         ; E = screen X offset
    inc bc
    ld a, [bc]
    ld d, a                         ; D = screen Y offset

; --- EXIT SCAN LOOP ---
; Iterates through exit entries (7 bytes each), comparing player position.
; HL points to current exit entry, DE = screen offset for position calc.
jr_00b_4578:
    ; Check terminator
    ld a, [hl]
    cp $ff
    jp z, Jump_00b_4674             ; $FF = end of exit list, no match

    ; Skip non-exit entries (type 0x00 = arrival point, 0x09 = special)
    ld a, [hl]
    or a
    jr z, jr_00b_459e               ; skip type $00

    cp $09
    jr z, jr_00b_459e               ; skip type $09

    ; Compare trigger X: player_col - screen_X_offset == exit.trigger_X?
    ldh a, [$97]                    ; player column (pixel units)
    sub e                           ; subtract screen X offset
    cp [hl]                         ; compare with exit trigger_X (byte 0)
    jr nz, jr_00b_459e              ; no match

    ; Validate trigger_Y is reasonable
    inc hl
    ld a, [hl]
    dec hl
    or a
    jr z, jr_00b_459e               ; Y=0 means invalid

    cp $07
    jr z, jr_00b_459e               ; Y=7 means invalid

    ; Compare trigger Y: player_row - screen_Y_offset == exit.trigger_Y?
    inc hl
    ldh a, [$98]                    ; player row (pixel units)
    sub d                           ; subtract screen Y offset
    cp [hl]                         ; compare with exit trigger_Y (byte 1)
    dec hl
    jr z, jr_00b_45a8               ; MATCH! → process transition

jr_00b_459e:
    ; Advance to next exit entry (+7 bytes)
    ld a, l
    add $07
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_00b_4578                  ; continue scanning

; =============================================================================
; EXIT MATCH — PROCESS ROOM TRANSITION ($45AB)
; =============================================================================
; Player stepped on an exit. HL points to the matched exit entry.
; Read transition data (bytes 2-6) and set up the room change.
;
; Exit entry layout (HL currently at byte 0):
;   +0: trigger_X (already matched)
;   +1: trigger_Y (already matched)
;   +2: dest_map_type → written to $C96D
;   +3: gate_flag → written to $C96E
;   +4: screen_byte → indexes $2DE7 table for spawn position
;   +5: spawn_X → added to table value, SWAP'd for pixel position
;   +6: spawn_Y → added to table value, SWAP'd for pixel position
;
; THIS IS THE ONLY PATCHABLE TRANSITION CODE PATH for ROM data.
; Other paths ($524B, $52E8, $52F3, $5A16, $46C1) use RAM/register values.
;
; Flat ROM address = $2C000 + (HL - $4000) when breakpoint fires here.
; Use `breakpoint $0B:$45AB` in SameBoy to capture any transition.
; -----------------------------------------------------------------------------
Jump_00b_45a8:
jr_00b_45a8:
    inc hl                          ; skip trigger_X (byte 0)
    inc hl                          ; skip trigger_Y (byte 1)
    ld a, [hl+]                     ; byte 2: dest_map_type
    ld [wWarpGateId], a                   ; → destination map_type
    ld a, [hl+]                     ; byte 3: gate_flag
    ld [wWarpFlag], a                   ; → destination gate flag

    ; === SPAWN POSITION CALCULATION ===
    ; Screen byte (byte 4) indexes $2DE7 table for base position.
    ; Lower nibble selects table entry, bit 7 adds extra $08 to Y.
    ld de, $2de7                    ; spawn offset table
    ld a, [hl+]                     ; byte 4: screen_byte
    push af                         ; save for bit 7 check later
    and $0f                         ; lower nibble = table index
    add a                           ; × 2 (entries are 2 bytes)
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a                         ; DE → $2DE7[screen_byte & $0F]

    ; X position: table[index].X + spawn_X, then SWAP for pixels
    ld a, [de]                      ; table X base
    add [hl]                        ; + spawn_X (byte 5)
    inc de
    inc hl
    swap a                          ; nibble swap = multiply by 16
    ld b, a
    and $f0
    ld c, a
    ld a, b
    and $0f
    ld b, a
    ld a, c
    add $08                         ; add 8 pixel offset
    ld c, a
    ld a, b
    adc $00
    ld b, a
    ld a, c
    ld [wWarpSpawnXLo], a                   ; X spawn position low
    ld a, b
    ld [wWarpSpawnXHi], a                   ; X spawn position high

    ; Y position: same calculation
    ld a, [de]                      ; table Y base
    add [hl]                        ; + spawn_Y (byte 6)
    inc de
    inc hl
    swap a
    ld b, a
    and $f0
    ld c, a
    ld a, b
    and $0f
    ld b, a
    ld a, c
    add $08
    ld c, a
    ld a, b
    adc $00
    ld b, a
    pop af                          ; recover screen_byte
    bit 7, a                        ; bit 7 set = multi-screen offset
    jr z, jr_00b_4601

    ; Add extra $08 to Y for multi-screen rooms (bit 7 of screen_byte)
    ld a, c
    add $08
    ld c, a
    ld a, b
    adc $00
    ld b, a

jr_00b_4601:
    ld a, c
    ld [wWarpSpawnYLo], a                   ; Y spawn position low
    ld a, b
    ld [wWarpSpawnYHi], a                   ; Y spawn position high

    ; === TRIGGER THE TRANSITION ===
    ld a, $01
    ld [wIsPlayerChangingMaps], a	; $C96C — signal map change to Entry 0
    ld a, [wWarpFlag]
    or a
    jr nz, jr_00b_466b

    ld a, [wInGateworld]
    or a
    jr nz, jr_00b_4627

    ld a, [wMapID]
    cp $10
    jr nz, jr_00b_4627

    ldh a, [$95]
    cp $68
    jr z, jr_00b_462c

jr_00b_4627:
    call CheckGateWorldMapType
    jr z, jr_00b_465b

jr_00b_462c:
    ld a, [wMapID]
    ld l, a
    ld a, [wInGateworld]
    ld h, a
    push hl
    ld a, [wWarpGateId]
    ld l, a
    ld a, [wWarpFlag]
    ld h, a
    ld a, l
    ld [wMapID], a
    ld a, h
    ld [wInGateworld], a
    call CheckGateWorldMapType
    pop hl
    push af
    ld a, l
    ld [wMapID], a
    ld a, h
    ld [wInGateworld], a
    pop af
    jr nz, jr_00b_465b

    ld hl, $0109
    rst $10
    jr jr_00b_466b

jr_00b_465b:
    ld a, $03
    call SetGBCPalette
    ld hl, $c88f
    inc [hl]
    ld a, $51
    call PlaySoundEffect
    jr jr_00b_4674

jr_00b_466b:
    ld hl, wGameState
    set 5, [hl]
    xor a
    ld [$c905], a

; --- Post-transition or no-exit: special room handling ---
; Checks if current room is a special type (mazes, conveyors, etc.)
; that need per-step processing beyond normal exit checking.
Jump_00b_4674:
jr_00b_4674:
    ld a, [wMapID]
    ld a, [wMapID]                  ; (loaded twice — original bug or intentional?)
    ; Special room map_types that get per-step processing:
    cp $53                          ; Forest Maze
    jr z, jr_00b_46d5

    cp $61                          ; sub-room 1
    jr z, jr_00b_46d5

    cp $62                          ; sub-room 2
    jr z, jr_00b_46d5

    cp $63                          ; sub-room 3
    jr z, jr_00b_46d5

    cp $64                          ; sub-room 4
    jr z, jr_00b_46d5

    cp $54                          ; Conveyor Belt Maze 1
    jr z, jr_00b_46d5

    cp $55                          ; Conveyor Belt Maze 2
    jr z, jr_00b_46d5

    cp $56                          ; Conveyor Belt Maze 3
    jr z, jr_00b_46d5

    cp $57                          ; Maze 1
    jr z, jr_00b_46d5

    cp $58                          ; Maze 2
    jr z, jr_00b_46d5

    cp $59                          ; Maze 3
    jr z, jr_00b_46d5

    cp $6B                          ; custom MedalMan room — random encounters enabled
    jr z, Seed6BEncounterPool

    ret


; Seed6BEncounterPool — pin the encounter pool for custom Room $6B.
; Runs every step in $6B (deterministic; independent of screen index or
; room-entry-script timing, which proved unreliable — gate ID stayed stale
; at battle time, drawing from whatever real gate the player last visited).
; gate 0 / floor 1 → pool 0 = Gate of Beginning (Slime / Anteater / Dracky).
; wGateID/wCurrentFloor are consumed only when a battle fires (by
; EncounterMonsterSelect → LoadNextDungeonFloor), so writing them here before
; the per-step encounter handler is safe.
Seed6BEncounterPool:
    xor a
    ld [wGateID], a                 ; $C935 = 0  (gate 0)
    inc a
    ld [wCurrentFloor], a           ; $C939 = 1  (floor 1)
    jp jr_00b_46d5                  ; run the per-step encounter handler


; --- Gate world exit handler ---
; For rooms inside gates ($C969 != 0), exit logic is different:
; checks $C960 (gate exit screen) and $FFAA position to detect
; when player reaches the gate floor exit.
Jump_00b_46a7:
    ld hl, $c960
    ld a, [wScreenIndex]
    cp [hl]
    jr nz, jr_00b_46d5

    ldh a, [$aa]
    srl a
    srl a
    cp $0f
    jr nz, jr_00b_46d5

    ld a, $01
    ld [wIsPlayerChangingMaps], a
    ld a, $00
    ld [wWarpGateId], a
    ld a, $80
    ld [wWarpFlag], a
    call LoadRoom_46da
    ld hl, wGameState
    set 5, [hl]
    xor a
    ld [$c905], a

jr_00b_46d5:
    ld hl, $1608
    rst $10
    ret


LoadRoom_46da:
    ld a, [wInGateworld]
    or a
    ret z

    ld hl, $c940
    ld de, $c950
    ld b, $10
    ld c, $00

jr_00b_46e9:
    ld a, [hl]
    and $f0
    cp $f0
    jr z, jr_00b_46f4

    ld a, [de]
    or a
    ret z

    inc c

jr_00b_46f4:
    inc hl
    inc de
    dec b
    jr nz, jr_00b_46e9

    ld a, c
    cp $10
    jr z, jr_00b_4703

    cp $02
    jr z, jr_00b_4709

    ret


jr_00b_4703:
    ld a, $05
    ld [$c92d], a
    ret


jr_00b_4709:
    ld a, $06
    ld [$c92d], a
    ret

; =============================================================================
; ENTRY 7: RoomEntry7_RoomInit ($470F)
; =============================================================================
; Called AFTER the fade transition completes. Initializes the new room:
; loads NPC data via ReadInteractPtr, sets up NPC sprites, positions, etc.
;
; State machine: checks $C8EA bit 7 (transition_phase).
;   If SET → fade still in progress, calls bank 6 fade handler, returns.
;   If CLEAR → fade done, proceeds with room initialization.
;
; CRITICAL: This function only runs AFTER the exit checker + Entry 0 have
; already processed the transition. If the exit checker crashes (e.g., from
; invalid pointer table data), this function NEVER RUNS.
; -----------------------------------------------------------------------------
RoomEntry7_RoomInit:
labelb_470f:
    ld a, [$c8ea]
    bit 7, a
    jr z, jr_00b_471b

    ld hl, $0604
    rst $10
    ret


jr_00b_471b:
    ld hl, $d7d2
    ld bc, $0101
    ld a, $00
    call FillNBytesWithRegA
    call SetRoom_482b
    ld a, $ff
    ld [$d7d2], a
    call GetRoomDataPtr
    ld a, [wInGateworld]
    or a
    jr z, jr_00b_477e

    ld a, [$c926]
    cp $ff
    jr z, jr_00b_477e

    ld a, [wScreenIndex]
    ld b, a
    ld a, [$c926]
    ld [wScreenIndex], a
    ld a, b
    ld [$c926], a
    call SetRoom_477e
    ld a, [wScreenIndex]
    ld b, a
    ld a, [$c926]
    ld [wScreenIndex], a
    ld a, b
    ld [$c926], a
    ld a, [$c927]
    ld l, a
    ld a, [$c928]
    ld h, a
    ld a, l
    ld [$d7ea], a
    ld a, h
    ld [$d7eb], a
    ld a, [$c929]
    ld l, a
    ld a, [$c92a]
    ld h, a
    ld a, l
    ld [$d7ec], a
    ld a, h
    ld [$d7ed], a
    ret


SetRoom_477e:
jr_00b_477e:
    ld de, $d7d2

Jump_00b_4781:
jr_00b_4781:
    ld a, e
    ldh [$d5], a
    ld a, d
    ldh [$d6], a
    ld a, [hl+]
    ld [de], a
    cp $ff
    ret z

    bit 7, a
    jr z, jr_00b_479a

    ld a, l
    add $04
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_00b_4781

jr_00b_479a:
    ldh [$d7], a
    ld bc, $2de7
    ld a, [wScreenIndex]
    add a
    add c
    ld c, a
    ld a, $00
    adc b
    ld b, a
    push de
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [bc]
    add [hl]
    ld [de], a
    inc hl
    inc de
    inc bc
    ld a, [bc]
    add [hl]
    ld [de], a
    inc hl
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    inc de
    ldh a, [$d7]
    swap a
    and $03
    ld [de], a
    push hl
    ldh a, [$d5]
    ld e, a
    ldh a, [$d6]
    ld d, a
    ld a, e
    add $11
    ld e, a
    ld a, d
    adc $00
    ld d, a
    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
    ld h, a
    inc hl
    ld a, [hl+]
    ld [de], a
    push hl
    call CmpRoom_4839
    pop hl
    push af
    ldh a, [$d5]
    ld e, a
    ldh a, [$d6]
    ld d, a
    ld a, e
    add $16
    ld e, a
    ld a, d
    adc $00
    ld d, a
    pop af
    ld [de], a
    ldh a, [$d5]
    ld e, a
    ldh a, [$d6]
    ld d, a
    ld a, e
    add $18
    ld e, a
    ld a, d
    adc $00
    ld d, a
    ld a, [hl+]
    swap a
    ld c, a
    and $f0
    or $08
    ld [de], a
    inc de
    ld a, c
    and $0f
    ld [de], a
    inc de
    ld a, [hl]
    swap a
    ld c, a
    and $f0
    or $08
    ld [de], a
    inc de
    ld a, c
    and $0f
    ld [de], a
    inc de
    pop hl
    pop de
    ld a, e
    add $20
    ld e, a
    ld a, d
    adc $00
    ld d, a
    jp Jump_00b_4781


SetRoom_482b:
    ld hl, $d7be
    ld b, $06

jr_00b_4830:
    ld a, $ff
    ld [hl+], a
    xor a
    ld [hl+], a
    dec b
    jr nz, jr_00b_4830

    ret


CmpRoom_4839:
    cp $ff
    ret z

    ld b, $00
    cp $e0
    jr z, jr_00b_48ba

    ld b, $20
    cp $e1
    jr z, jr_00b_48bf

    ld b, $30
    cp $e2
    jr z, jr_00b_48bf

    ld b, $40
    cp $e3
    jr z, jr_00b_48bf

    cp $f0
    jr c, jr_00b_488a

    and $03
    add a
    ld hl, $d7ca
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    inc hl
    dec de
    dec de
    ld a, [hl-]
    ld [de], a
    inc de
    inc de
    ld b, a
    ld a, [hl]
    ld [de], a
    cp $ff
    jr nz, jr_00b_4887

    push de
    ld a, e
    sub $10
    ld e, a
    ld a, d
    sbc $00
    ld d, a
    ld a, $ff
    ld [de], a
    dec de
    dec de
    ld a, $00
    ld [de], a
    pop de
    ld a, $00
    ret


jr_00b_4887:
    ld e, b
    jr jr_00b_488c

jr_00b_488a:
    ld e, $00

jr_00b_488c:
    ld hl, $d7be
    ld b, $06
    ld c, $00
    ld d, a

jr_00b_4894:
    ld a, [hl]
    cp $ff
    jr z, jr_00b_48f6

    cp d
    jr nz, jr_00b_48a2

    inc hl
    ld a, [hl-]
    cp e
    jp z, Jump_00b_4945

jr_00b_48a2:
    ld a, [hl]
    cp $55
    jr z, jr_00b_48ab

    cp $15
    jr nz, jr_00b_48b1

jr_00b_48ab:
    inc hl
    ld a, [hl-]
    or a
    jr nz, jr_00b_48b1

    inc c

jr_00b_48b1:
    inc hl
    inc hl
    inc c
    dec b
    jr nz, jr_00b_4894

    ld a, $50
    ret


jr_00b_48ba:
    ld a, $5e
    ld [de], a
    ld a, b
    ret


jr_00b_48bf:
    sub $e1
    push af
    ld hl, $ca8e
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $ff
    jr nz, jr_00b_48e1

    pop af
    push de
    ld a, e
    sub $10
    ld e, a
    ld a, d
    sbc $00
    ld d, a
    ld a, $ff
    ld [de], a
    pop de
    ld a, $00
    ret


jr_00b_48e1:
    pop af
    ld hl, $ca91
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [de], a
    dec de
    dec de
    ld a, $01
    ld [de], a
    inc de
    inc de
    ld a, b
    ret


jr_00b_48f6:
    ld [hl], d
    inc hl
    ld [hl], e
    push bc
    ld a, e
    or a
    jr nz, jr_00b_490b

    ld hl, $2adf
    ld a, d
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    jr jr_00b_4917

jr_00b_490b:
    ld l, d
    ld h, $00
    add hl, hl
    ld a, l
    add LOW(RoomScreenPtrTable)
    ld l, a
    ld a, h
    adc HIGH(RoomScreenPtrTable)
    ld h, a

jr_00b_4917:
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld a, c
    add $80
    ld h, a
    ld a, [wInGateworld]
    or a
    jr z, jr_00b_492a

    ld a, h
    add $07
    ld h, a
    jr jr_00b_493f

jr_00b_492a:
    ld a, [wMapID]
    cp $08
    jr z, jr_00b_493f

    cp $45
    jr nz, jr_00b_493b

    ld a, h
    add $02
    ld h, a
    jr jr_00b_493f

jr_00b_493b:
    ld a, h
    add $05
    ld h, a

jr_00b_493f:
    ld l, $00
    call WaitDMATransfer
    pop bc

Jump_00b_4945:
    ld a, [wInGateworld]
    or a
    jr nz, jr_00b_4964

    ld a, [wMapID]
    cp $08
    jr z, jr_00b_495e

    cp $45
    jr z, jr_00b_496c

    ld a, c
    add a
    add a
    add a
    add a
    add $50
    ret


jr_00b_495e:
    ld a, c
    add a
    add a
    add a
    add a
    ret


jr_00b_4964:
    ld a, c
    add a
    add a
    add a
    add a
    add $70
    ret


jr_00b_496c:
    ld a, c
    add a
    add a
    add a
    add a
    add $20
    ret

;DATA
    nop
    cpl
    ld b, b
    ld sp, $3140
    ld b, b
    ld sp, $3140
    ld b, b
    ld sp, $3140
    ld b, b
    ld sp, $3140
    ld b, b
    ld sp, $3140
    ld b, b
    ld sp, $3140
    ld b, b
    ld sp, $3140
    ld b, b
    ld sp, $2f01
    ld [bc], a
    cpl
    inc bc
    cpl
    inc b
    cpl
    dec b
    cpl
    ld b, $2f
    rlca
    cpl
    ld [$092f], sp
    cpl
    ld a, [bc]
    cpl
    dec bc
    cpl
    inc c
    cpl
    dec c
    cpl
    ld c, $2f
    rrca
    cpl
    db $10
    cpl
    nop
    jr c, @+$03

    jr c, jr_00b_49bb

    jr c, @+$05

jr_00b_49bb:
    jr c, jr_00b_49c1

    jr c, @+$07

    jr c, jr_00b_49c7

jr_00b_49c1:
    jr c, @+$09

    jr c, jr_00b_49cd

    jr c, @+$0b

jr_00b_49c7:
    jr c, jr_00b_49d3

    jr c, @+$0d

    jr c, jr_00b_49d9

jr_00b_49cd:
    jr c, @+$0f

    jr c, jr_00b_49df

    jr c, @+$11

jr_00b_49d3:
    jr c, jr_00b_49e5

    jr c, @+$13

    jr c, jr_00b_49eb

jr_00b_49d9:
    jr c, @+$15

    jr c, jr_00b_49f1

    jr c, @+$17

jr_00b_49df:
    jr c, jr_00b_49f7

    jr c, @+$19

    jr c, jr_00b_49fd

jr_00b_49e5:
    jr c, @+$1b

    jr c, jr_00b_4a03

    jr c, @+$1d

jr_00b_49eb:
    jr c, jr_00b_4a09

    jr c, @+$1f

    jr c, jr_00b_4a0f

jr_00b_49f1:
    jr c, @+$21

    jr c, jr_00b_4a15

    jr c, @+$23

jr_00b_49f7:
    jr c, jr_00b_4a1b

    jr c, @+$25

    jr c, jr_00b_4a21

jr_00b_49fd:
    jr c, @+$27

    jr c, jr_00b_4a27

    jr c, @+$29

jr_00b_4a03:
    jr c, jr_00b_4a2d

    jr c, @+$2b

    jr c, jr_00b_4a33

jr_00b_4a09:
    jr c, @+$2d

    jr c, jr_00b_4a39

    jr c, @+$2f

jr_00b_4a0f:
    jr c, jr_00b_4a3f

    jr c, @+$31

    jr c, jr_00b_4a45

jr_00b_4a15:
    db $38, $31         ; data (was: jr c, @+$33)
    db $38              ; data (was: jr c, jr_00b_4a4b — opcode)
RoomScreenPtrTable:     ; $4974 — screen index lookup table
    db $32              ; data (offset byte)
    db $38, $33         ; data (was: jr c, jr_00b_4a4e)

jr_00b_4a1b:
    jr c, @+$36

    jr c, jr_00b_4a54

    jr c, jr_00b_4a57

jr_00b_4a21:
    jr c, jr_00b_4a5a

    jr c, jr_00b_4a5d

    jr c, jr_00b_4a60

jr_00b_4a27:
    jr c, jr_00b_4a63

    jr c, jr_00b_4a66

    jr c, jr_00b_4a69

jr_00b_4a2d:
    jr c, jr_00b_4a6c

    jr c, jr_00b_4a6f

    jr c, jr_00b_4a72

jr_00b_4a33:
    jr c, @+$42

    jr c, jr_00b_4a78

    jr c, jr_00b_4a7b

jr_00b_4a39:
    jr c, jr_00b_4a7e

    jr c, @+$46

    jr c, jr_00b_4a84

jr_00b_4a3f:
    jr c, @+$48

    jr c, jr_00b_4a8a

    jr c, jr_00b_4a45

jr_00b_4a45:
    add hl, sp
    ld bc, $0239
    add hl, sp
    inc bc

jr_00b_4a4b:
    add hl, sp
    inc b
    add hl, sp

jr_00b_4a4e:
    dec b
    add hl, sp
    ld b, $39
    rlca
    add hl, sp

jr_00b_4a54:
    ld [$0939], sp

jr_00b_4a57:
    add hl, sp
    ld a, [bc]
    add hl, sp

jr_00b_4a5a:
    dec bc
    add hl, sp
    inc c

jr_00b_4a5d:
    add hl, sp
    dec c
    add hl, sp

jr_00b_4a60:
    ld c, $39
    rrca

jr_00b_4a63:
    add hl, sp
    db $10
    add hl, sp

jr_00b_4a66:
    ld de, $1239

jr_00b_4a69:
    add hl, sp
    inc de
    add hl, sp

jr_00b_4a6c:
    inc d
    add hl, sp
    dec d

jr_00b_4a6f:
    add hl, sp
    ld d, $39

jr_00b_4a72:
    rla
    add hl, sp
    jr jr_00b_4aaf

    add hl, de
    add hl, sp

jr_00b_4a78:
    ld a, [de]
    add hl, sp
    dec de

jr_00b_4a7b:
    add hl, sp
    inc e
    add hl, sp

jr_00b_4a7e:
    dec e
    add hl, sp
    ld e, $39
    rra
    add hl, sp

jr_00b_4a84:
    jr nz, jr_00b_4abf

    ld hl, $2239
    add hl, sp

jr_00b_4a8a:
    inc hl
    add hl, sp
    inc h
    add hl, sp
    dec h
    add hl, sp
    ld h, $39
    daa
    add hl, sp
    jr z, jr_00b_4acf

    add hl, hl
    add hl, sp
    ld a, [hl+]
    add hl, sp
    dec hl
    add hl, sp
    inc l
    add hl, sp
    dec l
    add hl, sp
    ld l, $39
    cpl
    add hl, sp
    jr nc, jr_00b_4adf

    ld sp, $3239
    add hl, sp
    inc sp
    add hl, sp
    inc [hl]
    add hl, sp
    dec [hl]

jr_00b_4aaf:
    add hl, sp
    ld [hl], $39
    scf
    add hl, sp
    jr c, jr_00b_4aef

    add hl, sp
    add hl, sp
    ld a, [hl-]
    add hl, sp
    dec sp
    add hl, sp
    inc a
    add hl, sp
    dec a

jr_00b_4abf:
    add hl, sp
    ld a, $39
    ccf
    add hl, sp
    ld b, b
    add hl, sp
    ld b, c
    add hl, sp
    ld b, d
    add hl, sp
    ld b, e
    add hl, sp
    ld b, h
    add hl, sp
    ld b, l

jr_00b_4acf:
    add hl, sp
    ld b, [hl]
    add hl, sp
    ld b, a
    add hl, sp
    nop
    ld a, [hl-]
    ld bc, $023a
    ld a, [hl-]
    inc bc
    ld a, [hl-]
    inc b
    ld a, [hl-]
    dec b

jr_00b_4adf:
    ld a, [hl-]
    ld b, $3a
    rlca
    ld a, [hl-]
    ld [$093a], sp
    ld a, [hl-]
    ld a, [bc]
    ld a, [hl-]
    dec bc
    ld a, [hl-]
    inc c
    ld a, [hl-]
    dec c

jr_00b_4aef:
    ld a, [hl-]
    ld c, $3a
    rrca
    ld a, [hl-]
    db $10
    ld a, [hl-]
    ld de, $123a
    ld a, [hl-]
    inc de
    ld a, [hl-]
    inc d
    ld a, [hl-]
    dec d
    ld a, [hl-]
    ld d, $3a
    rla
    ld a, [hl-]
    jr jr_00b_4b40

    add hl, de
    ld a, [hl-]
    ld a, [de]
    ld a, [hl-]
    dec de
    ld a, [hl-]
    inc e
    ld a, [hl-]
    dec e
    ld a, [hl-]
    ld e, $3a
    rra
    ld a, [hl-]
    db $20, $3a  ; data (not code)

    ld hl, $223a
    ld a, [hl-]
    inc hl
    ld a, [hl-]
    inc h
    ld a, [hl-]
    dec h
    ld a, [hl-]
    ld h, $3a
    daa
    ld a, [hl-]
    db $28, $3a  ; data (not code)

    add hl, hl
    ld a, [hl-]
    ld a, [hl+]
    ld a, [hl-]
    dec hl
    ld a, [hl-]
    inc l
    ld a, [hl-]
    dec l
    ld a, [hl-]
    ld l, $3a
    cpl
    ld a, [hl-]
    db $30, $3a  ; data (not code)

    ld sp, $323a
    ld a, [hl-]
    inc sp
    ld a, [hl-]
    inc [hl]
    ld a, [hl-]
    dec [hl]
    ld a, [hl-]

jr_00b_4b40:
    ld [hl], $3a
    rst $38


; =============================================================================
; SharedPtrChase — Shared room data pointer-chase function
; =============================================================================
; Called by ReadStepBlock, ReadInteractPtr, RoomEntry9, RoomEntry6.
; Output: HL = pointer to start of current 6-byte step entry
; Clobbers: A, DE
; =============================================================================
SharedPtrChase:
    ld hl, RoomPtrTable
    ld a, [wMapID]
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
    ld e, [hl]
    inc hl
    ld d, [hl]
    inc hl
    ld a, [de]
    ld e, a
    add a
    add e
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ret

; =============================================================================
; ROOM DATA SECTION ($4B43 - $7FFF)
; Generated by tools/gen_room_data_db.py from ROM data
; =============================================================================
;
; Pointer chain: RoomPtrTable[mapID×2] → sub_table → step_block
;   Sub-table: 8 × dw screen_ptrs ($FFFF = unused screen)
;   Step block: dw ram_counter + steps × [step_id, tileset_bank, dw interact, dw exit]
;   Interact: 5-byte entries (NPC/spawn), $FF terminated
;   Exit: 7-byte entries (walk-on triggers), $FF terminated
;
; NPC entry:  [type, sprite, x, y, script]
;   type bits 5-4=facing (0=down,1=left,2=up,3=right)
;   type bit 6=non-interactable, bits 3-0=behavior
; Spawn entry: [type($8F/$90), param, x, y, source_mt]
; Exit entry: [trig_x, trig_y, dest_mt, gate_flag, screen, spawn_x, spawn_y]

SECTION "ROM Bank $00b Data", ROMX[$4B43], BANK[$b]

; =============================================================================
; ROOM DATA SECTION ($4B43 - $7FFF)
; Generated by tools/gen_room_data_db.py from ROM data
; =============================================================================
;
; Pointer chain: RoomPtrTable[mapID×2] → sub_table → step_block
;   Sub-table: 8 × dw screen_ptrs ($FFFF = unused screen)
;   Step block: dw ram_counter + steps × [step_id, tileset_bank, dw interact, dw exit]
;   Interact: 5-byte entries (NPC/spawn), $FF terminated
;   Exit: 7-byte entries (walk-on triggers), $FF terminated
;
; NPC entry:  [type, sprite, x, y, script]
;   type bits 5-4=facing (0=down,1=left,2=up,3=right)
;   type bit 6=non-interactable, bits 3-0=behavior
; Spawn entry: [type($8F/$90), param, x, y, source_mt]
; Exit entry: [trig_x, trig_y, dest_mt, gate_flag, screen, spawn_x, spawn_y]

RoomPtrTable:  ; 107 entries × 2B, indexed by wMapID ($C968)
    dw RoomSub_Castle  ; $00 Castle
    dw RoomSub_GreatTree  ; $01 GreatTree
    dw RoomSub_Bazaar  ; $02 Bazaar
    dw RoomSub_GateHub  ; $03 GateHub
    dw RoomSub_Farm  ; $04 Farm
    dw RoomSub_Stable  ; $05 Stable
    db $9E  ; $06 ArenaLobby ptr low
jr_00b_4b50:
    db $59  ; $06 ArenaLobby ptr high → $599E
    dw RoomSub_ArenaRooms  ; $07 ArenaRooms
    dw RoomSub_Gate_08  ; $08 Gate_08
    dw RoomSub_StarryShrine  ; $09 StarryShrine
    dw RoomSub_SecretPassage  ; $0A SecretPassage
    dw RoomSub_Castle  ; $0B Castle_0B (=mt$00)
    dw RoomSub_Gate_0C  ; $0C Gate_0C
    dw RoomSub_OldManGate  ; $0D OldManGate
    db $13  ; $0E Castle_0E ptr low
jr_00b_4b60:
    db $4C  ; $0E Castle_0E ptr high → $4C13
    dw RoomSub_Room_0F  ; $0F Room_0F
    dw RoomSub_CopycatRoom  ; $10 CopycatRoom
    dw RoomSub_Castle  ; $11 Castle_11 (=mt$00)
    dw RoomSub_Library  ; $12 Library
    dw RoomSub_Room_13  ; $13 Room_13
    dw RoomSub_Castle  ; $14 Castle_14 (=mt$00)
    dw RoomSub_Castle  ; $15 Castle_15 (=mt$00)
    db $39  ; $16 MedalManRoom ptr low
jr_00b_4b70:
    db $61  ; $16 MedalManRoom ptr high → $6139
    dw RoomSub_CopycatRoom  ; $17 Copycat_17 (=mt$10)
    dw RoomSub_Well  ; $18 Well
    dw RoomSub_Room_19  ; $19 Room_19
    dw RoomSub_Room_1A  ; $1A Room_1A
    dw RoomSub_Room_1B  ; $1B Room_1B
    dw RoomSub_Room_1C  ; $1C Room_1C
    dw RoomSub_Room_1D  ; $1D Room_1D
    dw RoomSub_Room_1E  ; $1E Room_1E
    dw RoomSub_Room_1F  ; $1F Room_1F
    dw RoomSub_Castle  ; $20 Castle_20 (=mt$00)
    dw RoomSub_Castle  ; $21 Castle_21 (=mt$00)
    dw RoomSub_Castle  ; $22 Castle_22 (=mt$00)
    dw RoomSub_RoomOfBeginning  ; $23 RoomOfBeginning
    dw RoomSub_RoomOfVillagerTalisman  ; $24 RoomOfVillagerTalisman
    dw RoomSub_RoomOfMemoriesBewilder  ; $25 RoomOfMemoriesBewilder
    dw RoomSub_RoomOfPeaceBravery  ; $26 RoomOfPeaceBravery
    dw RoomSub_RoomOfStrengthAnger  ; $27 RoomOfStrengthAnger
    dw RoomSub_RoomOfJoyWisdom  ; $28 RoomOfJoyWisdom
    dw RoomSub_RoomOfHappinessTemptation  ; $29 RoomOfHappinessTemptation
    dw RoomSub_RoomOfLabyrinthJudgment  ; $2A RoomOfLabyrinthJudgment
    dw RoomSub_RoomOfReflection  ; $2B RoomOfReflection
    dw RoomSub_RoomOfAmbitionDemolition  ; $2C RoomOfAmbitionDemolition
    dw RoomSub_RoomOfMastermindControl  ; $2D RoomOfMastermindControl
    dw RoomSub_RoomOfExtinctionSleep  ; $2E RoomOfExtinctionSleep
    dw RoomSub_Room_2F  ; $2F Room_2F
    dw RoomSub_Boss_Beginning  ; $30 Boss_Beginning
    dw RoomSub_Boss_Villager  ; $31 Boss_Villager
    dw RoomSub_Boss_Talisman  ; $32 Boss_Talisman
    dw RoomSub_Boss_Memories  ; $33 Boss_Memories
    dw RoomSub_Boss_Bewilder  ; $34 Boss_Bewilder
    dw RoomSub_Room_35  ; $35 Room_35
    dw RoomSub_Boss_Peace  ; $36 Boss_Peace
    dw RoomSub_Boss_Bravery  ; $37 Boss_Bravery
    dw RoomSub_Room_38  ; $38 Room_38
    dw RoomSub_Room_39  ; $39 Room_39
    dw RoomSub_Room_3A  ; $3A Room_3A
    dw RoomSub_Room_3B  ; $3B Room_3B
    dw RoomSub_Room_3C  ; $3C Room_3C
    dw RoomSub_Room_3D  ; $3D Room_3D
    dw RoomSub_Room_3E  ; $3E Room_3E
    dw RoomSub_Room_3F  ; $3F Room_3F
    dw RoomSub_Room_40  ; $40 Room_40
    dw RoomSub_Room_41  ; $41 Room_41
    dw RoomSub_Labyrinth  ; $42 Labyrinth
    dw RoomSub_Room_43  ; $43 Room_43
    dw RoomSub_Room_44  ; $44 Room_44
    dw RoomSub_Room_45  ; $45 Room_45
    dw RoomSub_Boss_Ambition  ; $46 Boss_Ambition
    dw RoomSub_Room_47  ; $47 Room_47
    dw RoomSub_Room_48  ; $48 Room_48
    dw RoomSub_Room_49  ; $49 Room_49
    dw RoomSub_Room_4A  ; $4A Room_4A
    dw RoomSub_Room_4B  ; $4B Room_4B
    dw RoomSub_Room_4C  ; $4C Room_4C
    dw RoomSub_Boss_ArenaRight  ; $4D Boss_ArenaRight
    dw RoomSub_Room_4E  ; $4E Room_4E
    dw RoomSub_Boss_UnusedGate  ; $4F Boss_UnusedGate
    dw RoomSub_Room_50  ; $50 Room_50
    dw RoomSub_Room_51  ; $51 Room_51
    dw RoomSub_Coliseum  ; $52 Coliseum
    dw RoomSub_ForestMaze  ; $53 ForestMaze
    dw RoomSub_ConveyorBelt1  ; $54 ConveyorBelt1
    dw RoomSub_ConveyorBelt2  ; $55 ConveyorBelt2
    dw RoomSub_ConveyorBelt3  ; $56 ConveyorBelt3
    dw RoomSub_Maze1  ; $57 Maze1
    dw RoomSub_Maze2  ; $58 Maze2
    dw RoomSub_Maze3  ; $59 Maze3
    dw RoomSub_TreasureChest1  ; $5A TreasureChest1
    dw RoomSub_Room_5B  ; $5B Room_5B
    dw RoomSub_TreasureChest3  ; $5C TreasureChest3
    dw RoomSub_ArenaBattle  ; $5D ArenaBattle
    dw RoomSub_Room_5E  ; $5E Room_5E
    dw RoomSub_Room_50  ; $5F Room_5F (=mt$50)
    dw RoomSub_LabyrinthFinal  ; $60 LabyrinthFinal
    dw RoomSub_Room_61  ; $61 Room_61
    dw RoomSub_Room_62  ; $62 Room_62
    dw RoomSub_Room_63  ; $63 Room_63
    dw RoomSub_Room_64  ; $64 Room_64
    dw RoomSub_LabyrinthFinal  ; $65 Unused_65 (=mt$60)
    dw RoomSub_LabyrinthFinal  ; $66 Unused_66 (=mt$60)
    dw RoomSub_LabyrinthFinal  ; $67 Unused_67 (=mt$60)
RoomSub_Castle:  ; overlaps pointer table at $4C13
    dw $4C23  ; $68 CastleOvl_68
    dw $4C3D  ; $69 CastleOvl_69
    dw $FFFF  ; $6A Unused_6A (unused)

; --- ROOM DATA BLOCKS ---

RoomSub_Castle_cont:  ; $4C13 — mt=[$00, $0B, $0E, $11, $14, $15, $20, $21, $22] (first 3 slots in ptr table)
    dw $FFFF  ; screen 3 (unused)
    dw $FFFF  ; screen 4 (unused)
    dw StepBlk_Castle_s5  ; screen 5
    dw $FFFF  ; screen 6 (unused)
    dw $FFFF  ; screen 7 (unused)

StepBlk_Castle_s0:  ; $4C23 — RAM=$D92A, 4 steps
    dw $D92A  ; RAM step counter
    db $01, $2A  ; step 0: layout=$01 bank=$2A
    dw Interact_Castle_s0  ; → interact/NPC data
    dw Exit_Castle_s0  ; → exit data
    db $02, $2A  ; step 1: layout=$02 bank=$2A
    dw Interact_Castle_s0  ; → interact/NPC data
    dw Exit_Castle_s0  ; → exit data
    db $03, $2A  ; step 2: layout=$03 bank=$2A
    dw Interact_Castle_s0  ; → interact/NPC data
    dw Exit_Castle_s0  ; → exit data
    db $04, $2A  ; step 3: layout=$04 bank=$2A
    dw Interact_Castle_s0  ; → interact/NPC data
    dw Exit_Castle_s0  ; → exit data

StepBlk_Castle_s1:  ; $4C3D — RAM=$D92B, 9 steps
    dw $D92B  ; RAM step counter
    db $05, $2A  ; step 0: layout=$05 bank=$2A
    dw Interact_Castle_s1  ; → interact/NPC data
    dw Exit_Castle_s1_v1  ; → exit data
    db $06, $2A  ; step 1: layout=$06 bank=$2A
    dw Interact_Castle_s1_v1  ; → interact/NPC data
    dw Exit_Castle_s1_v1  ; → exit data
    db $06, $2A  ; step 2: layout=$06 bank=$2A
    dw Interact_Castle_s1_v2  ; → interact/NPC data
    dw Exit_Castle_s1_v1  ; → exit data
    db $06, $2A  ; step 3: layout=$06 bank=$2A
    dw Interact_Castle_s1_v3  ; → interact/NPC data
    dw Exit_Castle_s1_v1  ; → exit data
    db $06, $2A  ; step 4: layout=$06 bank=$2A
    dw Interact_Castle_s1_v4  ; → interact/NPC data
    dw Exit_Castle_s1_v1  ; → exit data
    db $06, $2A  ; step 5: layout=$06 bank=$2A
    dw Interact_Castle_s1_v5  ; → interact/NPC data
    dw Exit_Castle_s1_v1  ; → exit data
    db $06, $2A  ; step 6: layout=$06 bank=$2A
    dw Interact_Castle_s1_v7  ; → interact/NPC data
    dw Exit_Castle_s1_v1  ; → exit data
    db $05, $2A  ; step 7: layout=$05 bank=$2A
    dw Interact_Castle_s1_v6  ; → interact/NPC data
    dw Exit_Castle_s1  ; → exit data
    db $06, $2A  ; step 8: layout=$06 bank=$2A
    dw Interact_Castle_s1_v7  ; → interact/NPC data
    dw Exit_Castle_s1_v1  ; → exit data

StepBlk_Castle_s5:  ; $4C75 — RAM=$D92C, 5 steps
    dw $D92C  ; RAM step counter
    db $07, $2A  ; step 0: layout=$07 bank=$2A
    dw Interact_Castle_s5  ; → interact/NPC data
    dw Exit_Castle_s5  ; → exit data
    db $07, $2A  ; step 1: layout=$07 bank=$2A
    dw Interact_Castle_s5_v1  ; → interact/NPC data
    dw Exit_Castle_s5  ; → exit data
    db $07, $2A  ; step 2: layout=$07 bank=$2A
    dw Interact_Castle_s5_v2  ; → interact/NPC data
    dw Exit_Castle_s5  ; → exit data
    db $07, $2A  ; step 3: layout=$07 bank=$2A
    dw Interact_Castle_s5_v3  ; → interact/NPC data
    dw Exit_Castle_s5  ; → exit data
    db $07, $2A  ; step 4: layout=$07 bank=$2A
    dw Interact_Castle_s5_v4  ; → interact/NPC data
    dw Exit_Castle_s5  ; → exit data

Interact_Castle_s0:  ; $4C95 — 9 spawns, 2 NPCs
    db $8F, $FF, $01, $01, $01  ; spawn (1,1) mt$01 GreatTree
    db $8F, $FF, $02, $01, $02  ; spawn (2,1) mt$02 Bazaar
    db $8F, $FF, $03, $02, $03  ; spawn (3,2) mt$03 GateHub
    db $8F, $FF, $04, $02, $04  ; spawn (4,2) mt$04 Farm
    db $8F, $FF, $02, $07, $05  ; spawn (2,7) mt$05 Stable
    db $8F, $FF, $03, $07, $06  ; spawn (3,7) mt$06 ArenaLobby
    db $8F, $FF, $04, $07, $07  ; spawn (4,7) mt$07 ArenaRooms
    db $8F, $FF, $05, $07, $08  ; spawn (5,7) mt$08 Gate_08
    db $8F, $FF, $06, $07, $13  ; spawn (6,7) mt$13 Room_13
    db $01, $10, $05, $02, $09  ; NPC down b=1 spr=$10 (5,2) script=$09
    db $00, $10, $07, $04, $0A  ; NPC down b=0 spr=$10 (7,4) script=$0A
    db $FF  ; terminator

Interact_Castle_s1:  ; $4CCD — 6 NPCs
    db $00, $10, $02, $02, $0C  ; NPC down b=0 spr=$10 (2,2) script=$0C
    db $00, $10, $07, $02, $0D  ; NPC down b=0 spr=$10 (7,2) script=$0D
    db $30, $11, $03, $05, $0E  ; NPC right b=0 spr=$11 (3,5) script=$0E
    db $60, $00, $06, $08, $0F  ; NPC noTalk up b=0 spr=$00 (6,8) script=$0F
    db $00, $0D, $04, $03, $0B  ; NPC down b=0 spr=$0D (4,3) script=$0B
    db $60, $37, $05, $08, $FF  ; NPC noTalk up b=0 spr=$37 (5,8) script=none
    db $FF  ; terminator

Interact_Castle_s1_v1:  ; $4CEC — 4 NPCs
    db $00, $10, $02, $02, $0C  ; NPC down b=0 spr=$10 (2,2) script=$0C
    db $00, $10, $07, $02, $0D  ; NPC down b=0 spr=$10 (7,2) script=$0D
    db $30, $11, $03, $05, $0E  ; NPC right b=0 spr=$11 (3,5) script=$0E
    db $20, $00, $06, $06, $0F  ; NPC up b=0 spr=$00 (6,6) script=$0F
    db $FF  ; terminator

Interact_Castle_s1_v2:  ; $4D01 — 5 NPCs
    db $00, $10, $02, $02, $0C  ; NPC down b=0 spr=$10 (2,2) script=$0C
    db $00, $10, $07, $02, $0D  ; NPC down b=0 spr=$10 (7,2) script=$0D
    db $30, $11, $03, $05, $0E  ; NPC right b=0 spr=$11 (3,5) script=$0E
    db $20, $00, $06, $06, $0F  ; NPC up b=0 spr=$00 (6,6) script=$0F
    db $00, $0D, $04, $03, $0B  ; NPC down b=0 spr=$0D (4,3) script=$0B
    db $FF  ; terminator

Interact_Castle_s1_v3:  ; $4D1B — 3 NPCs
    db $00, $10, $02, $02, $0C  ; NPC down b=0 spr=$10 (2,2) script=$0C
    db $00, $10, $07, $02, $0D  ; NPC down b=0 spr=$10 (7,2) script=$0D
    db $30, $11, $03, $05, $0E  ; NPC right b=0 spr=$11 (3,5) script=$0E
    db $FF  ; terminator

Interact_Castle_s1_v4:  ; $4D2B — 8 NPCs
    db $00, $10, $02, $02, $0C  ; NPC down b=0 spr=$10 (2,2) script=$0C
    db $00, $10, $07, $02, $0D  ; NPC down b=0 spr=$10 (7,2) script=$0D
    db $20, $11, $04, $06, $0E  ; NPC up b=0 spr=$11 (4,6) script=$0E
    db $60, $00, $06, $06, $FF  ; NPC noTalk up b=0 spr=$00 (6,6) script=none
    db $00, $0D, $04, $03, $0B  ; NPC down b=0 spr=$0D (4,3) script=$0B
    db $60, $00, $06, $06, $FF  ; NPC noTalk up b=0 spr=$00 (6,6) script=none
    db $40, $E0, $04, $05, $FF  ; NPC noTalk down b=0 spr=$E0 (4,5) script=none
    db $40, $52, $04, $06, $FF  ; NPC noTalk down b=0 spr=$52 (4,6) script=none
    db $FF  ; terminator

Interact_Castle_s1_v5:  ; $4D54 — 3 NPCs
    db $00, $10, $02, $02, $0C  ; NPC down b=0 spr=$10 (2,2) script=$0C
    db $00, $10, $08, $02, $0D  ; NPC down b=0 spr=$10 (8,2) script=$0D
    db $30, $11, $03, $05, $0E  ; NPC right b=0 spr=$11 (3,5) script=$0E
    db $FF  ; terminator

Interact_Castle_s1_v6:  ; $4D64 — 7 NPCs
    db $00, $10, $02, $02, $0C  ; NPC down b=0 spr=$10 (2,2) script=$0C
    db $00, $10, $07, $02, $0D  ; NPC down b=0 spr=$10 (7,2) script=$0D
    db $30, $11, $03, $05, $0E  ; NPC right b=0 spr=$11 (3,5) script=$0E
    db $60, $00, $06, $06, $FF  ; NPC noTalk up b=0 spr=$00 (6,6) script=none
    db $00, $0D, $04, $03, $FF  ; NPC down b=0 spr=$0D (4,3) script=none
    db $60, $38, $05, $08, $FF  ; NPC noTalk up b=0 spr=$38 (5,8) script=none
    db $40, $10, $08, $02, $0D  ; NPC noTalk down b=0 spr=$10 (8,2) script=$0D
    db $FF  ; terminator

Interact_Castle_s1_v7:  ; $4D88 — 5 NPCs
    db $00, $10, $02, $02, $0C  ; NPC down b=0 spr=$10 (2,2) script=$0C
    db $00, $10, $07, $02, $0D  ; NPC down b=0 spr=$10 (7,2) script=$0D
    db $30, $11, $03, $05, $0E  ; NPC right b=0 spr=$11 (3,5) script=$0E
    db $60, $00, $06, $06, $0F  ; NPC noTalk up b=0 spr=$00 (6,6) script=$0F
    db $40, $10, $08, $02, $0D  ; NPC noTalk down b=0 spr=$10 (8,2) script=$0D
    db $FF  ; terminator

Interact_Castle_s5:  ; $4DA2 — 5 NPCs
    db $30, $0B, $02, $05, $10  ; NPC right b=0 spr=$0B (2,5) script=$10
    db $10, $0B, $07, $05, $11  ; NPC left b=0 spr=$0B (7,5) script=$11
    db $10, $0B, $06, $03, $12  ; NPC left b=0 spr=$0B (6,3) script=$12
    db $00, $11, $04, $04, $FF  ; NPC down b=0 spr=$11 (4,4) script=none
    db $60, $E0, $04, $07, $FF  ; NPC noTalk up b=0 spr=$E0 (4,7) script=none
    db $FF  ; terminator

Interact_Castle_s5_v1:  ; $4DBC — 3 NPCs
    db $30, $0B, $02, $05, $10  ; NPC right b=0 spr=$0B (2,5) script=$10
    db $10, $0B, $07, $05, $11  ; NPC left b=0 spr=$0B (7,5) script=$11
    db $10, $0B, $06, $03, $12  ; NPC left b=0 spr=$0B (6,3) script=$12
    db $FF  ; terminator

Interact_Castle_s5_v2:  ; $4DCC — 3 NPCs
    db $30, $0B, $02, $05, $10  ; NPC right b=0 spr=$0B (2,5) script=$10
    db $10, $0B, $08, $05, $11  ; NPC left b=0 spr=$0B (8,5) script=$11
    db $10, $0B, $06, $03, $12  ; NPC left b=0 spr=$0B (6,3) script=$12
    db $FF  ; terminator

Interact_Castle_s5_v3:  ; $4DDC — 3 NPCs
    db $30, $0B, $01, $04, $10  ; NPC right b=0 spr=$0B (1,4) script=$10
    db $10, $0B, $07, $05, $11  ; NPC left b=0 spr=$0B (7,5) script=$11
    db $10, $0B, $06, $03, $12  ; NPC left b=0 spr=$0B (6,3) script=$12
    db $FF  ; terminator

Interact_Castle_s5_v4:  ; $4DEC — 3 NPCs
    db $30, $0B, $01, $04, $10  ; NPC right b=0 spr=$0B (1,4) script=$10
    db $10, $0B, $08, $05, $11  ; NPC left b=0 spr=$0B (8,5) script=$11
    db $10, $0B, $06, $03, $12  ; NPC left b=0 spr=$0B (6,3) script=$12
    db $FF  ; terminator

Exit_Castle_s0:  ; $4DFC — 0 exits
    db $FF  ; terminator

Exit_Castle_s1:  ; $4DFD — 0 exits
    db $FF  ; terminator

Exit_Castle_s1_v1:  ; $4DFE — 1 exits
    db $07, $01, $0A, $00, $00, $07, $07  ; exit (7,1)→mt$0A SecretPassage  scr=0 spawn(7,7)
    db $FF  ; terminator

Exit_Castle_s5:  ; $4E06 — 4 exits
    db $02, $05, $03, $00, $01, $02, $05  ; exit (2,5)→mt$03 GateHub  scr=1 spawn(2,5)
    db $07, $05, $04, $00, $05, $07, $05  ; exit (7,5)→mt$04 Farm  scr=5 spawn(7,5)
    db $04, $07, $01, $00, $80, $04, $04  ; exit (4,7)→mt$01 GreatTree  scr=0+Y8 spawn(4,4)
    db $05, $07, $01, $00, $80, $05, $04  ; exit (5,7)→mt$01 GreatTree  scr=0+Y8 spawn(5,4)
    db $FF  ; terminator

RoomSub_GreatTree:  ; $4E23 — mt=[$01]
    dw StepBlk_GreatTree_s0  ; screen 0
    dw StepBlk_GreatTree_s1  ; screen 1
    dw $FFFF  ; screen 2 (unused)
    dw $FFFF  ; screen 3 (unused)
    dw StepBlk_GreatTree_s4  ; screen 4
    dw StepBlk_GreatTree_s5  ; screen 5
    dw $FFFF  ; screen 6 (unused)
    dw $FFFF  ; screen 7 (unused)
    dw StepBlk_GreatTree_s8  ; screen 8
    dw StepBlk_GreatTree_s9  ; screen 9
    dw $FFFF  ; screen 10 (unused)
    dw $FFFF  ; screen 11 (unused)
    dw StepBlk_GreatTree_s12  ; screen 12
    dw StepBlk_GreatTree_s13  ; screen 13
    dw $FFFF  ; screen 14 (unused)
    dw $FFFF  ; screen 15 (unused)

StepBlk_GreatTree_s0:  ; $4E43 — RAM=$D92D, 5 steps
    dw $D92D  ; RAM step counter
    db $09, $2A  ; step 0: layout=$09 bank=$2A
    dw Interact_GreatTree_s0  ; → interact/NPC data
    dw Exit_GreatTree_s0  ; → exit data
    db $09, $2A  ; step 1: layout=$09 bank=$2A
    dw Interact_GreatTree_s0_v1  ; → interact/NPC data
    dw Exit_GreatTree_s0_v1  ; → exit data
    db $09, $2A  ; step 2: layout=$09 bank=$2A
    dw Interact_GreatTree_s0_v2  ; → interact/NPC data
    dw Exit_GreatTree_s0_v1  ; → exit data
    db $09, $2A  ; step 3: layout=$09 bank=$2A
    dw Interact_GreatTree_s0_v3  ; → interact/NPC data
    dw Exit_GreatTree_s0_v1  ; → exit data
    db $09, $2A  ; step 4: layout=$09 bank=$2A
    dw Interact_GreatTree_s0_v4  ; → interact/NPC data
    dw Exit_GreatTree_s0  ; → exit data

StepBlk_GreatTree_s1:  ; $4E63 — RAM=$D92E, 1 steps
    dw $D92E  ; RAM step counter
    db $0A, $2A  ; step 0: layout=$0A bank=$2A
    dw Interact_GreatTree_s1  ; → interact/NPC data
    dw Exit_GreatTree_s1  ; → exit data

StepBlk_GreatTree_s4:  ; $4E6B — RAM=$D92F, 4 steps
    dw $D92F  ; RAM step counter
    db $0B, $2A  ; step 0: layout=$0B bank=$2A
    dw Interact_GreatTree_s4  ; → interact/NPC data
    dw Exit_GreatTree_s4  ; → exit data
    db $0B, $2A  ; step 1: layout=$0B bank=$2A
    dw Interact_GreatTree_s4_v1  ; → interact/NPC data
    dw Exit_GreatTree_s4  ; → exit data
    db $0B, $2A  ; step 2: layout=$0B bank=$2A
    dw Interact_GreatTree_s4_v2  ; → interact/NPC data
    dw Exit_GreatTree_s4  ; → exit data
    db $0B, $2A  ; step 3: layout=$0B bank=$2A
    dw Interact_GreatTree_s4_v3  ; → interact/NPC data
    dw Exit_GreatTree_s4  ; → exit data

StepBlk_GreatTree_s5:  ; $4E85 — RAM=$D930, 1 steps
    dw $D930  ; RAM step counter
    db $0C, $2A  ; step 0: layout=$0C bank=$2A
    dw Interact_GreatTree_s5  ; → interact/NPC data
    dw Exit_GreatTree_s5  ; → exit data

StepBlk_GreatTree_s8:  ; $4E8D — RAM=$D931, 3 steps
    dw $D931  ; RAM step counter
    db $0D, $2A  ; step 0: layout=$0D bank=$2A
    dw Interact_GreatTree_s8  ; → interact/NPC data
    dw Exit_GreatTree_s8  ; → exit data
    db $0D, $2A  ; step 1: layout=$0D bank=$2A
    dw Interact_GreatTree_s8_v1  ; → interact/NPC data
    dw Exit_GreatTree_s8  ; → exit data
    db $0D, $2A  ; step 2: layout=$0D bank=$2A
    dw Interact_GreatTree_s8_v2  ; → interact/NPC data
    dw Exit_GreatTree_s8  ; → exit data

StepBlk_GreatTree_s9:  ; $4EA1 — RAM=$D932, 1 steps
    dw $D932  ; RAM step counter
    db $0E, $2A  ; step 0: layout=$0E bank=$2A
    dw Interact_GreatTree_s9  ; → interact/NPC data
    dw Exit_GreatTree_s9  ; → exit data

StepBlk_GreatTree_s12:  ; $4EA9 — RAM=$D933, 4 steps
    dw $D933  ; RAM step counter
    db $0F, $2A  ; step 0: layout=$0F bank=$2A
    dw Interact_GreatTree_s12  ; → interact/NPC data
    dw Exit_GreatTree_s12  ; → exit data
    db $0F, $2A  ; step 1: layout=$0F bank=$2A
    dw Interact_GreatTree_s12_v1  ; → interact/NPC data
    dw Exit_GreatTree_s12  ; → exit data
    db $10, $2A  ; step 2: layout=$10 bank=$2A
    dw Interact_GreatTree_s12_v2  ; → interact/NPC data
    dw Exit_GreatTree_s12_v1  ; → exit data
    db $10, $2A  ; step 3: layout=$10 bank=$2A
    dw Interact_GreatTree_s12  ; → interact/NPC data
    dw Exit_GreatTree_s12_v1  ; → exit data

StepBlk_GreatTree_s13:  ; $4EC3 — RAM=$D934, 3 steps
    dw $D934  ; RAM step counter
    db $11, $2A  ; step 0: layout=$11 bank=$2A
    dw Interact_GreatTree_s13  ; → interact/NPC data
    dw Exit_GreatTree_s13  ; → exit data
    db $12, $2A  ; step 1: layout=$12 bank=$2A
    dw Interact_GreatTree_s13_v1  ; → interact/NPC data
    dw Exit_GreatTree_s13_v1  ; → exit data
    db $13, $2A  ; step 2: layout=$13 bank=$2A
    dw Interact_GreatTree_s13_v2  ; → interact/NPC data
    dw Exit_GreatTree_s13_v2  ; → exit data

Interact_GreatTree_s0:  ; $4ED7 — 2 NPCs
    db $20, $08, $02, $06, $FF  ; NPC up b=0 spr=$08 (2,6) script=none
    db $10, $05, $06, $05, $02  ; NPC left b=0 spr=$05 (6,5) script=$02
    db $FF  ; terminator

Interact_GreatTree_s0_v1:  ; $4EE2 — 2 NPCs
    db $00, $08, $02, $06, $01  ; NPC down b=0 spr=$08 (2,6) script=$01
    db $00, $05, $06, $05, $02  ; NPC down b=0 spr=$05 (6,5) script=$02
    db $FF  ; terminator

Interact_GreatTree_s0_v2:  ; $4EED — 1 spawns, 1 NPCs
    db $90, $FF, $06, $06, $12  ; walk_exit (6,6) mt$12 Library
    db $00, $05, $06, $05, $02  ; NPC down b=0 spr=$05 (6,5) script=$02
    db $FF  ; terminator

Interact_GreatTree_s0_v3:  ; $4EF8 — 1 spawns
    db $90, $FF, $06, $06, $12  ; walk_exit (6,6) mt$12 Library
    db $FF  ; terminator

Interact_GreatTree_s0_v4:  ; $4EFE — 1 spawns, 1 NPCs
    db $90, $FF, $06, $06, $12  ; walk_exit (6,6) mt$12 Library
    db $20, $08, $02, $06, $FF  ; NPC up b=0 spr=$08 (2,6) script=none
    db $FF  ; terminator

Interact_GreatTree_s1:  ; $4F09 — 1 NPCs
    db $30, $03, $05, $02, $03  ; NPC right b=0 spr=$03 (5,2) script=$03
    db $FF  ; terminator

Interact_GreatTree_s4:  ; $4F0F — 3 NPCs
    db $20, $08, $02, $06, $FF  ; NPC up b=0 spr=$08 (2,6) script=none
    db $00, $03, $07, $03, $04  ; NPC down b=0 spr=$03 (7,3) script=$04
    db $40, $0B, $04, $03, $FF  ; NPC noTalk down b=0 spr=$0B (4,3) script=none
    db $FF  ; terminator

Interact_GreatTree_s4_v1:  ; $4F1F — 1 spawns, 3 NPCs
    db $90, $FF, $06, $06, $13  ; walk_exit (6,6) mt$13 Room_13
    db $00, $03, $07, $03, $04  ; NPC down b=0 spr=$03 (7,3) script=$04
    db $00, $05, $06, $05, $05  ; NPC down b=0 spr=$05 (6,5) script=$05
    db $00, $08, $02, $06, $06  ; NPC down b=0 spr=$08 (2,6) script=$06
    db $FF  ; terminator

Interact_GreatTree_s4_v2:  ; $4F34 — 1 spawns, 1 NPCs
    db $90, $FF, $06, $06, $13  ; walk_exit (6,6) mt$13 Room_13
    db $00, $03, $07, $03, $04  ; NPC down b=0 spr=$03 (7,3) script=$04
    db $FF  ; terminator

Interact_GreatTree_s4_v3:  ; $4F3F — 1 spawns, 2 NPCs
    db $90, $FF, $06, $06, $13  ; walk_exit (6,6) mt$13 Room_13
    db $00, $03, $07, $03, $04  ; NPC down b=0 spr=$03 (7,3) script=$04
    db $00, $0B, $03, $05, $07  ; NPC down b=0 spr=$0B (3,5) script=$07
    db $FF  ; terminator

Interact_GreatTree_s5:  ; $4F4F — 2 NPCs
    db $00, $0B, $03, $02, $08  ; NPC down b=0 spr=$0B (3,2) script=$08
    db $30, $0F, $06, $01, $09  ; NPC right b=0 spr=$0F (6,1) script=$09
    db $FF  ; terminator

Interact_GreatTree_s8:  ; $4F5A — 1 spawns, 3 NPCs
    db $90, $FF, $06, $07, $14  ; walk_exit (6,7) mt$14 Castle_14
    db $20, $08, $02, $06, $FF  ; NPC up b=0 spr=$08 (2,6) script=none
    db $17, $01, $03, $06, $0A  ; NPC left b=7 spr=$01 (3,6) script=$0A
    db $00, $09, $08, $03, $0B  ; NPC down b=0 spr=$09 (8,3) script=$0B
    db $FF  ; terminator

Interact_GreatTree_s8_v1:  ; $4F6F — 1 spawns, 3 NPCs
    db $90, $FF, $06, $07, $14  ; walk_exit (6,7) mt$14 Castle_14
    db $00, $09, $08, $03, $0B  ; NPC down b=0 spr=$09 (8,3) script=$0B
    db $07, $01, $02, $07, $0A  ; NPC down b=7 spr=$01 (2,7) script=$0A
    db $00, $05, $06, $06, $0C  ; NPC down b=0 spr=$05 (6,6) script=$0C
    db $FF  ; terminator

Interact_GreatTree_s8_v2:  ; $4F84 — 1 spawns, 2 NPCs
    db $90, $FF, $06, $07, $14  ; walk_exit (6,7) mt$14 Castle_14
    db $00, $09, $08, $03, $0B  ; NPC down b=0 spr=$09 (8,3) script=$0B
    db $10, $04, $03, $06, $0D  ; NPC left b=0 spr=$04 (3,6) script=$0D
    db $FF  ; terminator

Interact_GreatTree_s9:  ; $4F94 — 2 NPCs
    db $00, $02, $04, $02, $0E  ; NPC down b=0 spr=$02 (4,2) script=$0E
    db $10, $00, $07, $04, $0F  ; NPC left b=0 spr=$00 (7,4) script=$0F
    db $FF  ; terminator

Interact_GreatTree_s12:  ; $4F9F — 1 NPCs
    db $20, $08, $04, $05, $FF  ; NPC up b=0 spr=$08 (4,5) script=none
    db $FF  ; terminator

Interact_GreatTree_s12_v1:  ; $4FA5 — 2 NPCs
    db $07, $01, $01, $06, $10  ; NPC down b=7 spr=$01 (1,6) script=$10
    db $00, $05, $07, $05, $11  ; NPC down b=0 spr=$05 (7,5) script=$11
    db $FF  ; terminator

Interact_GreatTree_s12_v2:  ; $4FB0 — 2 NPCs
    db $07, $01, $01, $06, $10  ; NPC down b=7 spr=$01 (1,6) script=$10
    db $00, $05, $07, $05, $11  ; NPC down b=0 spr=$05 (7,5) script=$11
    db $FF  ; terminator

Interact_GreatTree_s13:  ; $4FBB — empty
    db $FF  ; terminator

Interact_GreatTree_s13_v1:  ; $4FBC — empty
    db $FF  ; terminator

Interact_GreatTree_s13_v2:  ; $4FBD — empty
    db $FF  ; terminator

Exit_GreatTree_s0:  ; $4FBE — 0 exits
    db $FF  ; terminator

Exit_GreatTree_s0_v1:  ; $4FBF — 2 exits
    db $04, $04, $00, $00, $05, $04, $07  ; exit (4,4)→mt$00 Castle  scr=5 spawn(4,7)
    db $05, $04, $00, $00, $05, $05, $07  ; exit (5,4)→mt$00 Castle  scr=5 spawn(5,7)
    db $FF  ; terminator

Exit_GreatTree_s1:  ; $4FCE — 1 exits
    db $03, $02, $16, $00, $00, $03, $07  ; exit (3,2)→mt$16 MedalManRoom  scr=0 spawn(3,7)
    db $FF  ; terminator

Exit_GreatTree_s4:  ; $4FD6 — 2 exits
    db $04, $03, $06, $00, $01, $04, $07  ; exit (4,3)→mt$06 ArenaLobby  scr=1 spawn(4,7)
    db $05, $03, $06, $00, $01, $05, $07  ; exit (5,3)→mt$06 ArenaLobby  scr=1 spawn(5,7)
    db $FF  ; terminator

Exit_GreatTree_s5:  ; $4FE5 — 0 exits
    db $FF  ; terminator

Exit_GreatTree_s8:  ; $4FE6 — 2 exits
    db $05, $03, $12, $00, $04, $05, $07  ; exit (5,3)→mt$12 Library  scr=4 spawn(5,7)
    db $04, $05, $6B, $00, $00, $07, $06  ; exit (4,5)→mt$6B CUSTOM ROOM  scr=0 spawn(7,6)
    db $FF  ; terminator

Exit_GreatTree_s9:  ; $4FF5 — 2 exits
    db $05, $01, $0F, $00, $00, $05, $07  ; exit (5,1)→mt$0F Room_0F  scr=0 spawn(5,7)
    db $09, $03, $02, $00, $00, $00, $03  ; special marker (skipped)
    db $FF  ; terminator

Exit_GreatTree_s12:  ; $5004 — 3 exits
    db $04, $06, $09, $00, $04, $04, $06  ; exit (4,6)→mt$09 StarryShrine  scr=4 spawn(4,6)
    db $05, $01, $0D, $00, $00, $05, $07  ; exit (5,1)→mt$0D OldManGate  scr=0 spawn(5,7)
    db $04, $04, $10, $00, $00, $04, $07  ; exit (4,4)→mt$10 CopycatRoom  scr=0 spawn(4,7)
    db $FF  ; terminator

Exit_GreatTree_s12_v1:  ; $501A — 3 exits
    db $04, $06, $09, $00, $04, $04, $06  ; exit (4,6)→mt$09 StarryShrine  scr=4 spawn(4,6)
    db $05, $01, $0D, $00, $00, $05, $07  ; exit (5,1)→mt$0D OldManGate  scr=0 spawn(5,7)
    db $04, $04, $10, $00, $00, $04, $07  ; exit (4,4)→mt$10 CopycatRoom  scr=0 spawn(4,7)
    db $FF  ; terminator

Exit_GreatTree_s13:  ; $5030 — 1 exits
    db $02, $01, $0C, $00, $00, $02, $07  ; exit (2,1)→mt$0C Gate_0C  scr=0 spawn(2,7)
    db $FF  ; terminator

Exit_GreatTree_s13_v1:  ; $5038 — 2 exits
    db $02, $01, $0C, $00, $00, $02, $07  ; exit (2,1)→mt$0C Gate_0C  scr=0 spawn(2,7)
    db $01, $04, $19, $00, $00, $01, $07  ; exit (1,4)→mt$19 Room_19  scr=0 spawn(1,7)
    db $FF  ; terminator

Exit_GreatTree_s13_v2:  ; $5047 — 3 exits
    db $02, $01, $0C, $00, $00, $02, $07  ; exit (2,1)→mt$0C Gate_0C  scr=0 spawn(2,7)
    db $01, $04, $19, $00, $00, $01, $07  ; exit (1,4)→mt$19 Room_19  scr=0 spawn(1,7)
    db $04, $06, $1A, $00, $00, $04, $07  ; exit (4,6)→mt$1A Room_1A  scr=0 spawn(4,7)
    db $FF  ; terminator

RoomSub_Bazaar:  ; $505D — mt=[$02]
    dw StepBlk_Bazaar_s0  ; screen 0
    dw StepBlk_Bazaar_s1  ; screen 1
    dw StepBlk_Bazaar_s2  ; screen 2
    dw $FFFF  ; screen 3 (unused)
    dw StepBlk_Bazaar_s4  ; screen 4
    dw StepBlk_Bazaar_s5  ; screen 5
    dw StepBlk_Bazaar_s6  ; screen 6
    dw $FFFF  ; screen 7 (unused)

StepBlk_Bazaar_s0:  ; $506D — RAM=$D935, 2 steps
    dw $D935  ; RAM step counter
    db $15, $2A  ; step 0: layout=$15 bank=$2A
    dw Interact_Bazaar_s0  ; → interact/NPC data
    dw Exit_Bazaar_s0  ; → exit data
    db $15, $2A  ; step 1: layout=$15 bank=$2A
    dw Interact_Bazaar_s0_v1  ; → interact/NPC data
    dw Exit_Bazaar_s0  ; → exit data

StepBlk_Bazaar_s1:  ; $507B — RAM=$D936, 3 steps
    dw $D936  ; RAM step counter
    db $16, $2A  ; step 0: layout=$16 bank=$2A
    dw Interact_Bazaar_s1  ; → interact/NPC data
    dw Exit_Bazaar_s1  ; → exit data
    db $16, $2A  ; step 1: layout=$16 bank=$2A
    dw Interact_Bazaar_s1_v1  ; → interact/NPC data
    dw Exit_Bazaar_s1  ; → exit data
    db $16, $2A  ; step 2: layout=$16 bank=$2A
    dw Interact_Bazaar_s1_v2  ; → interact/NPC data
    dw Exit_Bazaar_s1  ; → exit data

StepBlk_Bazaar_s2:  ; $508F — RAM=$D937, 3 steps
    dw $D937  ; RAM step counter
    db $17, $2A  ; step 0: layout=$17 bank=$2A
    dw Interact_Bazaar_s2  ; → interact/NPC data
    dw Exit_Bazaar_s2  ; → exit data
    db $18, $2A  ; step 1: layout=$18 bank=$2A
    dw Interact_Bazaar_s2_v1  ; → interact/NPC data
    dw Exit_Bazaar_s2_v1  ; → exit data
    db $18, $2A  ; step 2: layout=$18 bank=$2A
    dw Interact_Bazaar_s2_v2  ; → interact/NPC data
    dw Exit_Bazaar_s2_v1  ; → exit data

StepBlk_Bazaar_s4:  ; $50A3 — RAM=$D938, 3 steps
    dw $D938  ; RAM step counter
    db $19, $2A  ; step 0: layout=$19 bank=$2A
    dw Interact_Bazaar_s4  ; → interact/NPC data
    dw Exit_Bazaar_s4  ; → exit data
    db $1A, $2A  ; step 1: layout=$1A bank=$2A
    dw Interact_Bazaar_s4_v1  ; → interact/NPC data
    dw Exit_Bazaar_s4_v1  ; → exit data
    db $19, $2A  ; step 2: layout=$19 bank=$2A
    dw Interact_Bazaar_s4_v2  ; → interact/NPC data
    dw Exit_Bazaar_s4  ; → exit data

StepBlk_Bazaar_s5:  ; $50B7 — RAM=$D939, 3 steps
    dw $D939  ; RAM step counter
    db $1B, $2A  ; step 0: layout=$1B bank=$2A
    dw Interact_Bazaar_s5  ; → interact/NPC data
    dw Exit_Bazaar_s5  ; → exit data
    db $1C, $2A  ; step 1: layout=$1C bank=$2A
    dw Interact_Bazaar_s5_v1  ; → interact/NPC data
    dw Exit_Bazaar_s5_v1  ; → exit data
    db $1C, $2A  ; step 2: layout=$1C bank=$2A
    dw Interact_Bazaar_s5_v2  ; → interact/NPC data
    dw Exit_Bazaar_s5_v1  ; → exit data

StepBlk_Bazaar_s6:  ; $50CB — RAM=$D93A, 9 steps
    dw $D93A  ; RAM step counter
    db $1D, $2A  ; step 0: layout=$1D bank=$2A
    dw Interact_Bazaar_s6  ; → interact/NPC data
    dw Exit_Bazaar_s6  ; → exit data
    db $1E, $2A  ; step 1: layout=$1E bank=$2A
    dw Interact_Bazaar_s6_v1  ; → interact/NPC data
    dw Exit_Bazaar_s6_v1  ; → exit data
    db $1E, $2A  ; step 2: layout=$1E bank=$2A
    dw Interact_Bazaar_s6_v2  ; → interact/NPC data
    dw Exit_Bazaar_s6_v1  ; → exit data
    db $1F, $2A  ; step 3: layout=$1F bank=$2A
    dw Interact_Bazaar_s6_v3  ; → interact/NPC data
    dw Exit_Bazaar_s6_v2  ; → exit data
    db $1F, $2A  ; step 4: layout=$1F bank=$2A
    dw Interact_Bazaar_s6_v4  ; → interact/NPC data
    dw Exit_Bazaar_s6_v2  ; → exit data
    db $20, $2A  ; step 5: layout=$20 bank=$2A
    dw Interact_Bazaar_s6_v5  ; → interact/NPC data
    dw Exit_Bazaar_s6_v3  ; → exit data
    db $20, $2A  ; step 6: layout=$20 bank=$2A
    dw Interact_Bazaar_s6_v6  ; → interact/NPC data
    dw Exit_Bazaar_s6_v3  ; → exit data
    db $20, $2A  ; step 7: layout=$20 bank=$2A
    dw Interact_Bazaar_s6_v7  ; → interact/NPC data
    dw Exit_Bazaar_s6_v3  ; → exit data
    db $20, $2A  ; step 8: layout=$20 bank=$2A
    dw Interact_Bazaar_s6_v8  ; → interact/NPC data
    dw Exit_Bazaar_s6_v3  ; → exit data

Interact_Bazaar_s0:  ; $5103 — 3 spawns, 2 NPCs
    db $8F, $FF, $06, $02, $01  ; spawn (6,2) mt$01 GreatTree
    db $8F, $FF, $08, $02, $02  ; spawn (8,2) mt$02 Bazaar
    db $8F, $FF, $08, $01, $03  ; spawn (8,1) mt$03 GateHub
    db $00, $06, $07, $02, $04  ; NPC down b=0 spr=$06 (7,2) script=$04
    db $00, $03, $03, $04, $05  ; NPC down b=0 spr=$03 (3,4) script=$05
    db $FF  ; terminator

Interact_Bazaar_s0_v1:  ; $511D — 3 spawns, 3 NPCs
    db $8F, $FF, $06, $02, $01  ; spawn (6,2) mt$01 GreatTree
    db $8F, $FF, $08, $02, $02  ; spawn (8,2) mt$02 Bazaar
    db $8F, $FF, $08, $01, $03  ; spawn (8,1) mt$03 GateHub
    db $00, $06, $07, $02, $04  ; NPC down b=0 spr=$06 (7,2) script=$04
    db $00, $03, $03, $04, $05  ; NPC down b=0 spr=$03 (3,4) script=$05
    db $30, $04, $04, $05, $06  ; NPC right b=0 spr=$04 (4,5) script=$06
    db $FF  ; terminator

Interact_Bazaar_s1:  ; $513C — 3 NPCs
    db $00, $04, $04, $04, $07  ; NPC down b=0 spr=$04 (4,4) script=$07
    db $20, $04, $04, $05, $08  ; NPC up b=0 spr=$04 (4,5) script=$08
    db $50, $39, $0A, $04, $FF  ; NPC noTalk left b=0 spr=$39 (10,4) script=none
    db $FF  ; terminator

Interact_Bazaar_s1_v1:  ; $514C — 4 NPCs
    db $00, $04, $04, $04, $07  ; NPC down b=0 spr=$04 (4,4) script=$07
    db $20, $04, $04, $05, $08  ; NPC up b=0 spr=$04 (4,5) script=$08
    db $50, $39, $0A, $04, $FF  ; NPC noTalk left b=0 spr=$39 (10,4) script=none
    db $00, $00, $03, $02, $09  ; NPC down b=0 spr=$00 (3,2) script=$09
    db $FF  ; terminator

Interact_Bazaar_s1_v2:  ; $5161 — 4 NPCs
    db $00, $04, $04, $04, $07  ; NPC down b=0 spr=$04 (4,4) script=$07
    db $20, $04, $04, $05, $08  ; NPC up b=0 spr=$04 (4,5) script=$08
    db $50, $39, $0A, $04, $FF  ; NPC noTalk left b=0 spr=$39 (10,4) script=none
    db $02, $00, $04, $02, $09  ; NPC down b=2 spr=$00 (4,2) script=$09
    db $FF  ; terminator

Interact_Bazaar_s2:  ; $5176 — 1 NPCs
    db $30, $0F, $01, $04, $0A  ; NPC right b=0 spr=$0F (1,4) script=$0A
    db $FF  ; terminator

Interact_Bazaar_s2_v1:  ; $517C — 1 spawns, 2 NPCs
    db $8F, $FF, $06, $03, $0B  ; spawn (6,3) mt$0B Castle_0B
    db $32, $0F, $02, $04, $0A  ; NPC right b=2 spr=$0F (2,4) script=$0A
    db $10, $06, $07, $03, $0C  ; NPC left b=0 spr=$06 (7,3) script=$0C
    db $FF  ; terminator

Interact_Bazaar_s2_v2:  ; $518C — 1 spawns, 3 NPCs
    db $8F, $FF, $06, $03, $0B  ; spawn (6,3) mt$0B Castle_0B
    db $32, $0F, $02, $04, $0A  ; NPC right b=2 spr=$0F (2,4) script=$0A
    db $10, $06, $07, $03, $0C  ; NPC left b=0 spr=$06 (7,3) script=$0C
    db $00, $12, $04, $06, $0D  ; NPC down b=0 spr=$12 (4,6) script=$0D
    db $FF  ; terminator

Interact_Bazaar_s4:  ; $51A1 — 2 NPCs
    db $30, $06, $03, $03, $0E  ; NPC right b=0 spr=$06 (3,3) script=$0E
    db $00, $0A, $08, $01, $0F  ; NPC down b=0 spr=$0A (8,1) script=$0F
    db $FF  ; terminator

Interact_Bazaar_s4_v1:  ; $51AC — 2 NPCs
    db $30, $06, $03, $03, $0E  ; NPC right b=0 spr=$06 (3,3) script=$0E
    db $00, $0A, $08, $01, $0F  ; NPC down b=0 spr=$0A (8,1) script=$0F
    db $FF  ; terminator

Interact_Bazaar_s4_v2:  ; $51B7 — 2 NPCs
    db $30, $06, $03, $03, $0E  ; NPC right b=0 spr=$06 (3,3) script=$0E
    db $00, $0A, $08, $01, $0F  ; NPC down b=0 spr=$0A (8,1) script=$0F
    db $FF  ; terminator

Interact_Bazaar_s5:  ; $51C2 — 1 NPCs
    db $10, $05, $08, $02, $10  ; NPC left b=0 spr=$05 (8,2) script=$10
    db $FF  ; terminator

Interact_Bazaar_s5_v1:  ; $51C8 — 2 spawns, 2 NPCs
    db $8F, $FF, $04, $03, $11  ; spawn (4,3) mt$11 Castle_11
    db $8F, $FF, $06, $03, $12  ; spawn (6,3) mt$12 Library
    db $20, $06, $05, $03, $13  ; NPC up b=0 spr=$06 (5,3) script=$13
    db $10, $05, $08, $02, $10  ; NPC left b=0 spr=$05 (8,2) script=$10
    db $FF  ; terminator

Interact_Bazaar_s5_v2:  ; $51DD — 2 spawns, 3 NPCs
    db $8F, $FF, $04, $03, $11  ; spawn (4,3) mt$11 Castle_11
    db $8F, $FF, $06, $03, $12  ; spawn (6,3) mt$12 Library
    db $20, $06, $05, $03, $13  ; NPC up b=0 spr=$06 (5,3) script=$13
    db $10, $05, $08, $02, $10  ; NPC left b=0 spr=$05 (8,2) script=$10
    db $00, $03, $02, $01, $14  ; NPC down b=0 spr=$03 (2,1) script=$14
    db $FF  ; terminator

Interact_Bazaar_s6:  ; $51F7 — 1 spawns, 4 NPCs
    db $8F, $FF, $03, $01, $15  ; spawn (3,1) mt$15 Castle_15
    db $17, $0A, $04, $01, $16  ; NPC left b=7 spr=$0A (4,1) script=$16
    db $27, $0A, $03, $02, $17  ; NPC up b=7 spr=$0A (3,2) script=$17
    db $00, $07, $04, $03, $18  ; NPC down b=0 spr=$07 (4,3) script=$18
    db $00, $4D, $07, $04, $FF  ; NPC down b=0 spr=$4D (7,4) script=none
    db $FF  ; terminator

Interact_Bazaar_s6_v1:  ; $5211 — 5 NPCs
    db $17, $0A, $04, $01, $16  ; NPC left b=7 spr=$0A (4,1) script=$16
    db $27, $0A, $03, $02, $17  ; NPC up b=7 spr=$0A (3,2) script=$17
    db $00, $07, $04, $03, $18  ; NPC down b=0 spr=$07 (4,3) script=$18
    db $00, $4D, $03, $01, $FF  ; NPC down b=0 spr=$4D (3,1) script=none
    db $00, $4D, $07, $04, $FF  ; NPC down b=0 spr=$4D (7,4) script=none
    db $FF  ; terminator

Interact_Bazaar_s6_v2:  ; $522B — 4 NPCs
    db $17, $0A, $04, $01, $16  ; NPC left b=7 spr=$0A (4,1) script=$16
    db $27, $0A, $03, $02, $17  ; NPC up b=7 spr=$0A (3,2) script=$17
    db $00, $07, $04, $03, $18  ; NPC down b=0 spr=$07 (4,3) script=$18
    db $00, $4D, $07, $04, $FF  ; NPC down b=0 spr=$4D (7,4) script=none
    db $FF  ; terminator

Interact_Bazaar_s6_v3:  ; $5240 — 1 spawns, 4 NPCs
    db $8F, $FF, $07, $04, $15  ; spawn (7,4) mt$15 Castle_15
    db $07, $0A, $07, $03, $16  ; NPC down b=7 spr=$0A (7,3) script=$16
    db $37, $0A, $06, $04, $17  ; NPC right b=7 spr=$0A (6,4) script=$17
    db $00, $07, $04, $02, $18  ; NPC down b=0 spr=$07 (4,2) script=$18
    db $00, $4D, $03, $01, $FF  ; NPC down b=0 spr=$4D (3,1) script=none
    db $FF  ; terminator

Interact_Bazaar_s6_v4:  ; $525A — 1 spawns, 3 NPCs
    db $8F, $FF, $07, $04, $15  ; spawn (7,4) mt$15 Castle_15
    db $07, $0A, $07, $03, $16  ; NPC down b=7 spr=$0A (7,3) script=$16
    db $37, $0A, $06, $04, $17  ; NPC right b=7 spr=$0A (6,4) script=$17
    db $00, $07, $04, $02, $18  ; NPC down b=0 spr=$07 (4,2) script=$18
    db $FF  ; terminator

Interact_Bazaar_s6_v5:  ; $526F — 5 NPCs
    db $07, $0A, $07, $03, $16  ; NPC down b=7 spr=$0A (7,3) script=$16
    db $37, $0A, $06, $04, $17  ; NPC right b=7 spr=$0A (6,4) script=$17
    db $20, $07, $04, $02, $18  ; NPC up b=0 spr=$07 (4,2) script=$18
    db $00, $4D, $03, $01, $FF  ; NPC down b=0 spr=$4D (3,1) script=none
    db $00, $4D, $07, $04, $FF  ; NPC down b=0 spr=$4D (7,4) script=none
    db $FF  ; terminator

Interact_Bazaar_s6_v6:  ; $5289 — 4 NPCs
    db $07, $0A, $07, $03, $16  ; NPC down b=7 spr=$0A (7,3) script=$16
    db $37, $0A, $06, $04, $17  ; NPC right b=7 spr=$0A (6,4) script=$17
    db $20, $07, $04, $02, $18  ; NPC up b=0 spr=$07 (4,2) script=$18
    db $00, $4D, $07, $04, $FF  ; NPC down b=0 spr=$4D (7,4) script=none
    db $FF  ; terminator

Interact_Bazaar_s6_v7:  ; $529E — 4 NPCs
    db $07, $0A, $07, $03, $16  ; NPC down b=7 spr=$0A (7,3) script=$16
    db $37, $0A, $06, $04, $17  ; NPC right b=7 spr=$0A (6,4) script=$17
    db $20, $07, $04, $02, $18  ; NPC up b=0 spr=$07 (4,2) script=$18
    db $00, $4D, $03, $01, $FF  ; NPC down b=0 spr=$4D (3,1) script=none
    db $FF  ; terminator

Interact_Bazaar_s6_v8:  ; $52B3 — 3 NPCs
    db $07, $0A, $07, $03, $16  ; NPC down b=7 spr=$0A (7,3) script=$16
    db $37, $0A, $06, $04, $17  ; NPC right b=7 spr=$0A (6,4) script=$17
    db $20, $07, $04, $02, $18  ; NPC up b=0 spr=$07 (4,2) script=$18
    db $FF  ; terminator

Exit_Bazaar_s0:  ; $52C3 — 1 exits
    db $00, $03, $01, $00, $09, $09, $03  ; arrival marker (skipped)
    db $FF  ; terminator

Exit_Bazaar_s1:  ; $52CB — 0 exits
    db $FF  ; terminator

Exit_Bazaar_s2:  ; $52CC — 0 exits
    db $FF  ; terminator

Exit_Bazaar_s2_v1:  ; $52CD — 0 exits
    db $FF  ; terminator

Exit_Bazaar_s4:  ; $52CE — 0 exits
    db $FF  ; terminator

Exit_Bazaar_s4_v1:  ; $52CF — 0 exits
    db $FF  ; terminator

Exit_Bazaar_s5:  ; $52D0 — 0 exits
    db $FF  ; terminator

Exit_Bazaar_s5_v1:  ; $52D1 — 0 exits
    db $FF  ; terminator

Exit_Bazaar_s6:  ; $52D2 — 0 exits
    db $FF  ; terminator

Exit_Bazaar_s6_v1:  ; $52D3 — 1 exits
    db $03, $01, $05, $01, $00, $00, $00  ; exit (3,1)→mt$05 Stable gate scr=0 spawn(0,0)
    db $FF  ; terminator

Exit_Bazaar_s6_v2:  ; $52DB — 1 exits
    db $03, $01, $05, $01, $00, $00, $00  ; exit (3,1)→mt$05 Stable gate scr=0 spawn(0,0)
    db $FF  ; terminator

Exit_Bazaar_s6_v3:  ; $52E3 — 2 exits
    db $03, $01, $05, $01, $00, $00, $00  ; exit (3,1)→mt$05 Stable gate scr=0 spawn(0,0)
    db $07, $04, $1C, $01, $00, $00, $00  ; exit (7,4)→mt$1C Room_1C gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_GateHub:  ; $52F2 — mt=[$03]
    dw StepBlk_GateHub_s0  ; screen 0
    dw StepBlk_GateHub_s1  ; screen 1
    dw $FFFF  ; screen 2 (unused)
    dw $FFFF  ; screen 3 (unused)
    dw StepBlk_GateHub_s4  ; screen 4
    dw StepBlk_GateHub_s5  ; screen 5
    dw $FFFF  ; screen 6 (unused)
    dw $FFFF  ; screen 7 (unused)

StepBlk_GateHub_s0:  ; $5302 — RAM=$D93B, 4 steps
    dw $D93B  ; RAM step counter
    db $22, $2A  ; step 0: layout=$22 bank=$2A
    dw Interact_GateHub_s0  ; → interact/NPC data
    dw Exit_GateHub_s0  ; → exit data
    db $23, $2A  ; step 1: layout=$23 bank=$2A
    dw Interact_GateHub_s0_v1  ; → interact/NPC data
    dw Exit_GateHub_s0_v1  ; → exit data
    db $24, $2A  ; step 2: layout=$24 bank=$2A
    dw Interact_GateHub_s0_v2  ; → interact/NPC data
    dw Exit_GateHub_s0_v2  ; → exit data
    db $25, $2A  ; step 3: layout=$25 bank=$2A
    dw Interact_GateHub_s0_v3  ; → interact/NPC data
    dw Exit_GateHub_s0_v3  ; → exit data

StepBlk_GateHub_s1:  ; $531C — RAM=$D93C, 5 steps
    dw $D93C  ; RAM step counter
    db $26, $2A  ; step 0: layout=$26 bank=$2A
    dw Interact_GateHub_s1  ; → interact/NPC data
    dw Exit_GateHub_s1  ; → exit data
    db $27, $2A  ; step 1: layout=$27 bank=$2A
    dw Interact_GateHub_s1_v1  ; → interact/NPC data
    dw Exit_GateHub_s1_v1  ; → exit data
    db $27, $2A  ; step 2: layout=$27 bank=$2A
    dw Interact_GateHub_s1_v2  ; → interact/NPC data
    dw Exit_GateHub_s1_v1  ; → exit data
    db $28, $2A  ; step 3: layout=$28 bank=$2A
    dw Interact_GateHub_s1_v3  ; → interact/NPC data
    dw Exit_GateHub_s1_v2  ; → exit data
    db $29, $2A  ; step 4: layout=$29 bank=$2A
    dw Interact_GateHub_s1_v4  ; → interact/NPC data
    dw Exit_GateHub_s1_v3  ; → exit data

StepBlk_GateHub_s4:  ; $533C — RAM=$D93D, 5 steps
    dw $D93D  ; RAM step counter
    db $2A, $2A  ; step 0: layout=$2A bank=$2A
    dw Interact_GateHub_s4  ; → interact/NPC data
    dw Exit_GateHub_s4  ; → exit data
    db $2B, $2A  ; step 1: layout=$2B bank=$2A
    dw Interact_GateHub_s4_v1  ; → interact/NPC data
    dw Exit_GateHub_s4_v1  ; → exit data
    db $2C, $2A  ; step 2: layout=$2C bank=$2A
    dw Interact_GateHub_s4_v2  ; → interact/NPC data
    dw Exit_GateHub_s4_v2  ; → exit data
    db $2D, $2A  ; step 3: layout=$2D bank=$2A
    dw Interact_GateHub_s4_v3  ; → interact/NPC data
    dw Exit_GateHub_s4_v3  ; → exit data
    db $2D, $2A  ; step 4: layout=$2D bank=$2A
    dw Interact_GateHub_s4_v4  ; → interact/NPC data
    dw Exit_GateHub_s4_v3  ; → exit data

StepBlk_GateHub_s5:  ; $535C — RAM=$D93E, 2 steps
    dw $D93E  ; RAM step counter
    db $2E, $2A  ; step 0: layout=$2E bank=$2A
    dw Interact_GateHub_s5  ; → interact/NPC data
    dw Exit_GateHub_s5  ; → exit data
    db $00, $29  ; step 1: layout=$00 bank=$29
    dw Interact_GateHub_s5_v1  ; → interact/NPC data
    dw Exit_GateHub_s5_v1  ; → exit data

Interact_GateHub_s0:  ; $536A — 4 spawns, 1 NPCs
    db $8F, $FF, $04, $01, $01  ; spawn (4,1) mt$01 GreatTree
    db $8F, $FF, $05, $01, $01  ; spawn (5,1) mt$01 GreatTree
    db $8F, $FF, $02, $02, $02  ; spawn (2,2) mt$02 Bazaar
    db $8F, $FF, $07, $02, $03  ; spawn (7,2) mt$03 GateHub
    db $20, $0B, $03, $05, $04  ; NPC up b=0 spr=$0B (3,5) script=$04
    db $FF  ; terminator

Interact_GateHub_s0_v1:  ; $5384 — 3 spawns, 1 NPCs
    db $8F, $FF, $04, $01, $01  ; spawn (4,1) mt$01 GreatTree
    db $8F, $FF, $05, $01, $01  ; spawn (5,1) mt$01 GreatTree
    db $8F, $FF, $02, $02, $02  ; spawn (2,2) mt$02 Bazaar
    db $20, $0B, $03, $05, $04  ; NPC up b=0 spr=$0B (3,5) script=$04
    db $FF  ; terminator

Interact_GateHub_s0_v2:  ; $5399 — 1 spawns, 1 NPCs
    db $8F, $FF, $02, $02, $02  ; spawn (2,2) mt$02 Bazaar
    db $20, $0B, $03, $05, $04  ; NPC up b=0 spr=$0B (3,5) script=$04
    db $FF  ; terminator

Interact_GateHub_s0_v3:  ; $53A4 — 1 NPCs
    db $20, $0B, $03, $05, $04  ; NPC up b=0 spr=$0B (3,5) script=$04
    db $FF  ; terminator

Interact_GateHub_s1:  ; $53AA — 4 spawns, 3 NPCs
    db $8F, $FF, $04, $01, $05  ; spawn (4,1) mt$05 Stable
    db $8F, $FF, $05, $01, $05  ; spawn (5,1) mt$05 Stable
    db $8F, $FF, $02, $02, $06  ; spawn (2,2) mt$06 ArenaLobby
    db $8F, $FF, $07, $02, $07  ; spawn (7,2) mt$07 ArenaRooms
    db $30, $0B, $00, $04, $08  ; NPC right b=0 spr=$0B (0,4) script=$08
    db $30, $0B, $00, $05, $09  ; NPC right b=0 spr=$0B (0,5) script=$09
    db $20, $0B, $04, $06, $0A  ; NPC up b=0 spr=$0B (4,6) script=$0A
    db $FF  ; terminator

Interact_GateHub_s1_v1:  ; $53CE — 2 spawns, 3 NPCs
    db $8F, $FF, $02, $02, $06  ; spawn (2,2) mt$06 ArenaLobby
    db $8F, $FF, $07, $02, $07  ; spawn (7,2) mt$07 ArenaRooms
    db $30, $0B, $00, $04, $08  ; NPC right b=0 spr=$0B (0,4) script=$08
    db $30, $0B, $00, $05, $09  ; NPC right b=0 spr=$0B (0,5) script=$09
    db $20, $0B, $04, $06, $0A  ; NPC up b=0 spr=$0B (4,6) script=$0A
    db $FF  ; terminator

Interact_GateHub_s1_v2:  ; $53E8 — 2 spawns, 1 NPCs
    db $8F, $FF, $02, $02, $06  ; spawn (2,2) mt$06 ArenaLobby
    db $8F, $FF, $07, $02, $07  ; spawn (7,2) mt$07 ArenaRooms
    db $22, $0B, $05, $05, $0A  ; NPC up b=2 spr=$0B (5,5) script=$0A
    db $FF  ; terminator

Interact_GateHub_s1_v3:  ; $53F8 — 1 spawns, 1 NPCs
    db $8F, $FF, $07, $02, $07  ; spawn (7,2) mt$07 ArenaRooms
    db $22, $0B, $05, $05, $0A  ; NPC up b=2 spr=$0B (5,5) script=$0A
    db $FF  ; terminator

Interact_GateHub_s1_v4:  ; $5403 — 1 NPCs
    db $22, $0B, $05, $05, $0A  ; NPC up b=2 spr=$0B (5,5) script=$0A
    db $FF  ; terminator

Interact_GateHub_s4:  ; $5409 — 4 spawns, 2 NPCs
    db $8F, $FF, $04, $01, $0B  ; spawn (4,1) mt$0B Castle_0B
    db $8F, $FF, $05, $01, $0B  ; spawn (5,1) mt$0B Castle_0B
    db $8F, $FF, $02, $02, $0C  ; spawn (2,2) mt$0C Gate_0C
    db $8F, $FF, $07, $02, $0D  ; spawn (7,2) mt$0D OldManGate
    db $10, $0B, $09, $04, $0E  ; NPC left b=0 spr=$0B (9,4) script=$0E
    db $10, $0B, $09, $05, $0F  ; NPC left b=0 spr=$0B (9,5) script=$0F
    db $FF  ; terminator

Interact_GateHub_s4_v1:  ; $5428 — 3 spawns, 2 NPCs
    db $8F, $FF, $04, $01, $0B  ; spawn (4,1) mt$0B Castle_0B
    db $8F, $FF, $05, $01, $0B  ; spawn (5,1) mt$0B Castle_0B
    db $8F, $FF, $02, $02, $0C  ; spawn (2,2) mt$0C Gate_0C
    db $10, $0B, $09, $04, $0E  ; NPC left b=0 spr=$0B (9,4) script=$0E
    db $10, $0B, $09, $05, $0F  ; NPC left b=0 spr=$0B (9,5) script=$0F
    db $FF  ; terminator

Interact_GateHub_s4_v2:  ; $5442 — 2 spawns, 2 NPCs
    db $8F, $FF, $04, $01, $0B  ; spawn (4,1) mt$0B Castle_0B
    db $8F, $FF, $05, $01, $0B  ; spawn (5,1) mt$0B Castle_0B
    db $10, $0B, $09, $04, $0E  ; NPC left b=0 spr=$0B (9,4) script=$0E
    db $10, $0B, $09, $05, $0F  ; NPC left b=0 spr=$0B (9,5) script=$0F
    db $FF  ; terminator

Interact_GateHub_s4_v3:  ; $5457 — 2 NPCs
    db $10, $0B, $09, $04, $0E  ; NPC left b=0 spr=$0B (9,4) script=$0E
    db $10, $0B, $09, $05, $0F  ; NPC left b=0 spr=$0B (9,5) script=$0F
    db $FF  ; terminator

Interact_GateHub_s4_v4:  ; $5462 — 1 NPCs
    db $00, $0B, $03, $04, $0E  ; NPC down b=0 spr=$0B (3,4) script=$0E
    db $FF  ; terminator

Interact_GateHub_s5:  ; $5468 — 4 spawns, 1 NPCs
    db $8F, $FF, $04, $01, $10  ; spawn (4,1) mt$10 CopycatRoom
    db $8F, $FF, $05, $01, $10  ; spawn (5,1) mt$10 CopycatRoom
    db $8F, $FF, $02, $02, $11  ; spawn (2,2) mt$11 Castle_11
    db $8F, $FF, $07, $02, $12  ; spawn (7,2) mt$12 Library
    db $20, $0B, $04, $06, $13  ; NPC up b=0 spr=$0B (4,6) script=$13
    db $FF  ; terminator

Interact_GateHub_s5_v1:  ; $5482 — 1 NPCs
    db $20, $0B, $04, $06, $13  ; NPC up b=0 spr=$0B (4,6) script=$13
    db $FF  ; terminator

Exit_GateHub_s0:  ; $5488 — 1 exits
    db $07, $05, $03, $00, $04, $07, $05  ; exit (7,5)→mt$03 GateHub  scr=4 spawn(7,5)
    db $FF  ; terminator

Exit_GateHub_s0_v1:  ; $5490 — 2 exits
    db $07, $05, $03, $00, $04, $07, $05  ; exit (7,5)→mt$03 GateHub  scr=4 spawn(7,5)
    db $07, $02, $26, $00, $00, $08, $07  ; exit (7,2)→mt$26 RoomOfPeaceBravery  scr=0 spawn(8,7)
    db $FF  ; terminator

Exit_GateHub_s0_v2:  ; $549F — 4 exits
    db $07, $05, $03, $00, $04, $07, $05  ; exit (7,5)→mt$03 GateHub  scr=4 spawn(7,5)
    db $07, $02, $26, $00, $00, $08, $07  ; exit (7,2)→mt$26 RoomOfPeaceBravery  scr=0 spawn(8,7)
    db $04, $01, $27, $00, $00, $04, $07  ; exit (4,1)→mt$27 RoomOfStrengthAnger  scr=0 spawn(4,7)
    db $05, $01, $27, $00, $00, $05, $07  ; exit (5,1)→mt$27 RoomOfStrengthAnger  scr=0 spawn(5,7)
    db $FF  ; terminator

Exit_GateHub_s0_v3:  ; $54BC — 5 exits
    db $07, $05, $03, $00, $04, $07, $05  ; exit (7,5)→mt$03 GateHub  scr=4 spawn(7,5)
    db $07, $02, $26, $00, $00, $08, $07  ; exit (7,2)→mt$26 RoomOfPeaceBravery  scr=0 spawn(8,7)
    db $04, $01, $27, $00, $00, $04, $07  ; exit (4,1)→mt$27 RoomOfStrengthAnger  scr=0 spawn(4,7)
    db $05, $01, $27, $00, $00, $05, $07  ; exit (5,1)→mt$27 RoomOfStrengthAnger  scr=0 spawn(5,7)
    db $02, $02, $28, $00, $00, $04, $07  ; exit (2,2)→mt$28 RoomOfJoyWisdom  scr=0 spawn(4,7)
    db $FF  ; terminator

Exit_GateHub_s1:  ; $54E0 — 1 exits
    db $02, $05, $00, $00, $05, $02, $05  ; exit (2,5)→mt$00 Castle  scr=5 spawn(2,5)
    db $FF  ; terminator

Exit_GateHub_s1_v1:  ; $54E8 — 3 exits
    db $02, $05, $00, $00, $05, $02, $05  ; exit (2,5)→mt$00 Castle  scr=5 spawn(2,5)
    db $04, $01, $23, $00, $00, $07, $07  ; exit (4,1)→mt$23 RoomOfBeginning  scr=0 spawn(7,7)
    db $05, $01, $23, $00, $00, $08, $07  ; exit (5,1)→mt$23 RoomOfBeginning  scr=0 spawn(8,7)
    db $FF  ; terminator

Exit_GateHub_s1_v2:  ; $54FE — 4 exits
    db $02, $05, $00, $00, $05, $02, $05  ; exit (2,5)→mt$00 Castle  scr=5 spawn(2,5)
    db $04, $01, $23, $00, $00, $07, $07  ; exit (4,1)→mt$23 RoomOfBeginning  scr=0 spawn(7,7)
    db $05, $01, $23, $00, $00, $08, $07  ; exit (5,1)→mt$23 RoomOfBeginning  scr=0 spawn(8,7)
    db $02, $02, $24, $00, $00, $06, $07  ; exit (2,2)→mt$24 RoomOfVillagerTalisman  scr=0 spawn(6,7)
    db $FF  ; terminator

Exit_GateHub_s1_v3:  ; $551B — 5 exits
    db $02, $05, $00, $00, $05, $02, $05  ; exit (2,5)→mt$00 Castle  scr=5 spawn(2,5)
    db $04, $01, $23, $00, $00, $07, $07  ; exit (4,1)→mt$23 RoomOfBeginning  scr=0 spawn(7,7)
    db $05, $01, $23, $00, $00, $08, $07  ; exit (5,1)→mt$23 RoomOfBeginning  scr=0 spawn(8,7)
    db $02, $02, $24, $00, $00, $06, $07  ; exit (2,2)→mt$24 RoomOfVillagerTalisman  scr=0 spawn(6,7)
    db $07, $02, $25, $00, $00, $01, $07  ; exit (7,2)→mt$25 RoomOfMemoriesBewilder  scr=0 spawn(1,7)
    db $FF  ; terminator

Exit_GateHub_s4:  ; $553F — 1 exits
    db $07, $05, $03, $00, $00, $07, $05  ; exit (7,5)→mt$03 GateHub  scr=0 spawn(7,5)
    db $FF  ; terminator

Exit_GateHub_s4_v1:  ; $5547 — 2 exits
    db $07, $05, $03, $00, $00, $07, $05  ; exit (7,5)→mt$03 GateHub  scr=0 spawn(7,5)
    db $07, $02, $29, $00, $00, $04, $07  ; exit (7,2)→mt$29 RoomOfHappinessTemptation  scr=0 spawn(4,7)
    db $FF  ; terminator

Exit_GateHub_s4_v2:  ; $5556 — 3 exits
    db $07, $05, $03, $00, $00, $07, $05  ; exit (7,5)→mt$03 GateHub  scr=0 spawn(7,5)
    db $07, $02, $29, $00, $00, $04, $07  ; exit (7,2)→mt$29 RoomOfHappinessTemptation  scr=0 spawn(4,7)
    db $02, $02, $2A, $00, $00, $04, $07  ; exit (2,2)→mt$2A RoomOfLabyrinthJudgment  scr=0 spawn(4,7)
    db $FF  ; terminator

Exit_GateHub_s4_v3:  ; $556C — 5 exits
    db $07, $05, $03, $00, $00, $07, $05  ; exit (7,5)→mt$03 GateHub  scr=0 spawn(7,5)
    db $07, $02, $29, $00, $00, $04, $07  ; exit (7,2)→mt$29 RoomOfHappinessTemptation  scr=0 spawn(4,7)
    db $02, $02, $2A, $00, $00, $04, $07  ; exit (2,2)→mt$2A RoomOfLabyrinthJudgment  scr=0 spawn(4,7)
    db $04, $01, $2B, $00, $00, $07, $07  ; exit (4,1)→mt$2B RoomOfReflection  scr=0 spawn(7,7)
    db $05, $01, $2B, $00, $00, $08, $07  ; exit (5,1)→mt$2B RoomOfReflection  scr=0 spawn(8,7)
    db $FF  ; terminator

Exit_GateHub_s5:  ; $5590 — 0 exits
    db $FF  ; terminator

Exit_GateHub_s5_v1:  ; $5591 — 4 exits
    db $02, $02, $2C, $00, $00, $08, $07  ; exit (2,2)→mt$2C RoomOfAmbitionDemolition  scr=0 spawn(8,7)
    db $07, $02, $2D, $00, $00, $02, $07  ; exit (7,2)→mt$2D RoomOfMastermindControl  scr=0 spawn(2,7)
    db $04, $01, $2E, $00, $00, $06, $07  ; exit (4,1)→mt$2E RoomOfExtinctionSleep  scr=0 spawn(6,7)
    db $05, $01, $2E, $00, $00, $07, $07  ; exit (5,1)→mt$2E RoomOfExtinctionSleep  scr=0 spawn(7,7)
    db $FF  ; terminator

RoomSub_Farm:  ; $55AE — mt=[$04]
    dw StepBlk_Farm_s0  ; screen 0
    dw StepBlk_Farm_s1  ; screen 1
    dw StepBlk_Farm_s2  ; screen 2
    dw $FFFF  ; screen 3 (unused)
    dw StepBlk_Farm_s4  ; screen 4
    dw StepBlk_Farm_s5  ; screen 5
    dw StepBlk_Farm_s6  ; screen 6
    dw $FFFF  ; screen 7 (unused)

StepBlk_Farm_s0:  ; $55BE — RAM=$D93F, 4 steps
    dw $D93F  ; RAM step counter
    db $02, $29  ; step 0: layout=$02 bank=$29
    dw Interact_Farm_s0  ; → interact/NPC data
    dw Exit_Farm_s0  ; → exit data
    db $02, $29  ; step 1: layout=$02 bank=$29
    dw Interact_Farm_s0_v1  ; → interact/NPC data
    dw Exit_Farm_s0  ; → exit data
    db $02, $29  ; step 2: layout=$02 bank=$29
    dw Interact_Farm_s0_v2  ; → interact/NPC data
    dw Exit_Farm_s0  ; → exit data
    db $02, $29  ; step 3: layout=$02 bank=$29
    dw Interact_Farm_s0_v3  ; → interact/NPC data
    dw Exit_Farm_s0  ; → exit data

StepBlk_Farm_s1:  ; $55D8 — RAM=$D940, 3 steps
    dw $D940  ; RAM step counter
    db $03, $29  ; step 0: layout=$03 bank=$29
    dw Interact_Farm_s1  ; → interact/NPC data
    dw Exit_Farm_s1  ; → exit data
    db $03, $29  ; step 1: layout=$03 bank=$29
    dw Interact_Farm_s1_v1  ; → interact/NPC data
    dw Exit_Farm_s1  ; → exit data
    db $03, $29  ; step 2: layout=$03 bank=$29
    dw Interact_Farm_s1_v2  ; → interact/NPC data
    dw Exit_Farm_s1  ; → exit data

StepBlk_Farm_s2:  ; $55EC — RAM=$D941, 5 steps
    dw $D941  ; RAM step counter
    db $04, $29  ; step 0: layout=$04 bank=$29
    dw Interact_Farm_s2  ; → interact/NPC data
    dw Exit_Farm_s2  ; → exit data
    db $04, $29  ; step 1: layout=$04 bank=$29
    dw Interact_Farm_s2_v1  ; → interact/NPC data
    dw Exit_Farm_s2  ; → exit data
    db $05, $29  ; step 2: layout=$05 bank=$29
    dw Interact_Farm_s2_v2  ; → interact/NPC data
    dw Exit_Farm_s2_v1  ; → exit data
    db $05, $29  ; step 3: layout=$05 bank=$29
    dw Interact_Farm_s2_v3  ; → interact/NPC data
    dw Exit_Farm_s2_v1  ; → exit data
    db $05, $29  ; step 4: layout=$05 bank=$29
    dw Interact_Farm_s2_v4  ; → interact/NPC data
    dw Exit_Farm_s2_v1  ; → exit data

StepBlk_Farm_s4:  ; $560C — RAM=$D942, 4 steps
    dw $D942  ; RAM step counter
    db $06, $29  ; step 0: layout=$06 bank=$29
    dw Interact_Farm_s4  ; → interact/NPC data
    dw Exit_Farm_s4  ; → exit data
    db $06, $29  ; step 1: layout=$06 bank=$29
    dw Interact_Farm_s4_v1  ; → interact/NPC data
    dw Exit_Farm_s4  ; → exit data
    db $06, $29  ; step 2: layout=$06 bank=$29
    dw Interact_Farm_s4_v2  ; → interact/NPC data
    dw Exit_Farm_s4  ; → exit data
    db $06, $29  ; step 3: layout=$06 bank=$29
    dw Interact_Farm_s4_v3  ; → interact/NPC data
    dw Exit_Farm_s4  ; → exit data

StepBlk_Farm_s5:  ; $5626 — RAM=$D943, 3 steps
    dw $D943  ; RAM step counter
    db $07, $29  ; step 0: layout=$07 bank=$29
    dw Interact_Farm_s5  ; → interact/NPC data
    dw Exit_Farm_s5  ; → exit data
    db $07, $29  ; step 1: layout=$07 bank=$29
    dw Interact_Farm_s5_v1  ; → interact/NPC data
    dw Exit_Farm_s5  ; → exit data
    db $07, $29  ; step 2: layout=$07 bank=$29
    dw Interact_Farm_s5_v2  ; → interact/NPC data
    dw Exit_Farm_s5  ; → exit data

StepBlk_Farm_s6:  ; $563A — RAM=$D944, 4 steps
    dw $D944  ; RAM step counter
    db $08, $29  ; step 0: layout=$08 bank=$29
    dw Interact_Farm_s6  ; → interact/NPC data
    dw Exit_Farm_s6  ; → exit data
    db $08, $29  ; step 1: layout=$08 bank=$29
    dw Interact_Farm_s6_v1  ; → interact/NPC data
    dw Exit_Farm_s6  ; → exit data
    db $08, $29  ; step 2: layout=$08 bank=$29
    dw Interact_Farm_s6_v2  ; → interact/NPC data
    dw Exit_Farm_s6  ; → exit data
    db $08, $29  ; step 3: layout=$08 bank=$29
    dw Interact_Farm_s6_v3  ; → interact/NPC data
    dw Exit_Farm_s6  ; → exit data

Interact_Farm_s0:  ; $5654 — empty
    db $FF  ; terminator

Interact_Farm_s0_v1:  ; $5655 — 1 spawns, 3 NPCs
    db $90, $FF, $06, $05, $02  ; walk_exit (6,5) mt$02 Bazaar
    db $02, $18, $04, $01, $FF  ; NPC down b=2 spr=$18 (4,1) script=none
    db $10, $20, $04, $06, $01  ; NPC left b=0 spr=$20 (4,6) script=$01
    db $40, $53, $06, $01, $FF  ; NPC noTalk down b=0 spr=$53 (6,1) script=none
    db $FF  ; terminator

Interact_Farm_s0_v2:  ; $566A — 1 spawns, 3 NPCs
    db $90, $FF, $06, $05, $02  ; walk_exit (6,5) mt$02 Bazaar
    db $02, $1B, $04, $01, $FF  ; NPC down b=2 spr=$1B (4,1) script=none
    db $00, $2C, $04, $06, $03  ; NPC down b=0 spr=$2C (4,6) script=$03
    db $40, $53, $06, $01, $FF  ; NPC noTalk down b=0 spr=$53 (6,1) script=none
    db $FF  ; terminator

Interact_Farm_s0_v3:  ; $567F — 3 NPCs
    db $02, $1B, $04, $01, $FF  ; NPC down b=2 spr=$1B (4,1) script=none
    db $30, $0C, $04, $06, $04  ; NPC right b=0 spr=$0C (4,6) script=$04
    db $30, $02, $06, $05, $05  ; NPC right b=0 spr=$02 (6,5) script=$05
    db $FF  ; terminator

Interact_Farm_s1:  ; $568F — 2 spawns, 1 NPCs
    db $90, $FF, $05, $02, $06  ; walk_exit (5,2) mt$06 ArenaLobby
    db $8F, $FF, $04, $01, $07  ; spawn (4,1) mt$07 ArenaRooms
    db $00, $19, $06, $02, $08  ; NPC down b=0 spr=$19 (6,2) script=$08
    db $FF  ; terminator

Interact_Farm_s1_v1:  ; $569F — 2 spawns, 2 NPCs
    db $90, $FF, $05, $02, $06  ; walk_exit (5,2) mt$06 ArenaLobby
    db $8F, $FF, $04, $01, $07  ; spawn (4,1) mt$07 ArenaRooms
    db $00, $19, $06, $02, $08  ; NPC down b=0 spr=$19 (6,2) script=$08
    db $00, $19, $03, $04, $09  ; NPC down b=0 spr=$19 (3,4) script=$09
    db $FF  ; terminator

Interact_Farm_s1_v2:  ; $56B4 — 6 NPCs
    db $00, $0D, $05, $02, $0A  ; NPC down b=0 spr=$0D (5,2) script=$0A
    db $00, $0E, $04, $02, $0B  ; NPC down b=0 spr=$0E (4,2) script=$0B
    db $00, $10, $02, $03, $0C  ; NPC down b=0 spr=$10 (2,3) script=$0C
    db $00, $10, $01, $04, $0D  ; NPC down b=0 spr=$10 (1,4) script=$0D
    db $00, $10, $07, $03, $0E  ; NPC down b=0 spr=$10 (7,3) script=$0E
    db $00, $10, $08, $04, $0F  ; NPC down b=0 spr=$10 (8,4) script=$0F
    db $FF  ; terminator

Interact_Farm_s2:  ; $56D3 — 1 spawns, 3 NPCs
    db $8F, $FF, $04, $05, $10  ; spawn (4,5) mt$10 CopycatRoom
    db $26, $1D, $05, $06, $11  ; NPC up b=6 spr=$1D (5,6) script=$11
    db $06, $1C, $05, $03, $12  ; NPC down b=6 spr=$1C (5,3) script=$12
    db $00, $4D, $08, $02, $FF  ; NPC down b=0 spr=$4D (8,2) script=none
    db $FF  ; terminator

Interact_Farm_s2_v1:  ; $56E8 — 2 spawns, 3 NPCs
    db $90, $FF, $05, $05, $29  ; walk_exit (5,5) mt$29 RoomOfHappinessTemptation
    db $8F, $FF, $04, $05, $10  ; spawn (4,5) mt$10 CopycatRoom
    db $37, $1D, $01, $04, $11  ; NPC right b=7 spr=$1D (1,4) script=$11
    db $06, $1C, $05, $03, $12  ; NPC down b=6 spr=$1C (5,3) script=$12
    db $00, $4D, $08, $02, $FF  ; NPC down b=0 spr=$4D (8,2) script=none
    db $FF  ; terminator

Interact_Farm_s2_v2:  ; $5702 — 4 spawns, 3 NPCs
    db $90, $FF, $05, $04, $29  ; walk_exit (5,4) mt$29 RoomOfHappinessTemptation
    db $90, $FF, $05, $05, $29  ; walk_exit (5,5) mt$29 RoomOfHappinessTemptation
    db $90, $FF, $07, $04, $2A  ; walk_exit (7,4) mt$2A RoomOfLabyrinthJudgment
    db $90, $FF, $07, $05, $2A  ; walk_exit (7,5) mt$2A RoomOfLabyrinthJudgment
    db $37, $1D, $04, $02, $11  ; NPC right b=7 spr=$1D (4,2) script=$11
    db $16, $1C, $05, $02, $12  ; NPC left b=6 spr=$1C (5,2) script=$12
    db $00, $4D, $08, $02, $FF  ; NPC down b=0 spr=$4D (8,2) script=none
    db $FF  ; terminator

Interact_Farm_s2_v3:  ; $5726 — 4 spawns, 2 NPCs
    db $90, $FF, $05, $04, $29  ; walk_exit (5,4) mt$29 RoomOfHappinessTemptation
    db $90, $FF, $05, $05, $29  ; walk_exit (5,5) mt$29 RoomOfHappinessTemptation
    db $90, $FF, $07, $04, $2A  ; walk_exit (7,4) mt$2A RoomOfLabyrinthJudgment
    db $90, $FF, $07, $05, $2A  ; walk_exit (7,5) mt$2A RoomOfLabyrinthJudgment
    db $37, $1D, $04, $02, $11  ; NPC right b=7 spr=$1D (4,2) script=$11
    db $16, $1C, $05, $02, $12  ; NPC left b=6 spr=$1C (5,2) script=$12
    db $FF  ; terminator

Interact_Farm_s2_v4:  ; $5745 — 4 spawns, 4 NPCs
    db $90, $FF, $05, $04, $29  ; walk_exit (5,4) mt$29 RoomOfHappinessTemptation
    db $90, $FF, $05, $05, $29  ; walk_exit (5,5) mt$29 RoomOfHappinessTemptation
    db $90, $FF, $07, $04, $2A  ; walk_exit (7,4) mt$2A RoomOfLabyrinthJudgment
    db $90, $FF, $07, $05, $2A  ; walk_exit (7,5) mt$2A RoomOfLabyrinthJudgment
    db $36, $1D, $04, $02, $11  ; NPC right b=6 spr=$1D (4,2) script=$11
    db $16, $1C, $05, $02, $12  ; NPC left b=6 spr=$1C (5,2) script=$12
    db $10, $08, $04, $05, $13  ; NPC left b=0 spr=$08 (4,5) script=$13
    db $10, $0F, $05, $06, $14  ; NPC left b=0 spr=$0F (5,6) script=$14
    db $FF  ; terminator

Interact_Farm_s4:  ; $576E — 1 spawns, 2 NPCs
    db $8F, $FF, $02, $01, $15  ; spawn (2,1) mt$15 Castle_15
    db $17, $05, $02, $02, $16  ; NPC left b=7 spr=$05 (2,2) script=$16
    db $00, $3F, $06, $04, $17  ; NPC down b=0 spr=$3F (6,4) script=$17
    db $FF  ; terminator

Interact_Farm_s4_v1:  ; $577E — 1 spawns, 2 NPCs
    db $8F, $FF, $02, $01, $15  ; spawn (2,1) mt$15 Castle_15
    db $17, $05, $02, $02, $16  ; NPC left b=7 spr=$05 (2,2) script=$16
    db $00, $3F, $05, $04, $17  ; NPC down b=0 spr=$3F (5,4) script=$17
    db $FF  ; terminator

Interact_Farm_s4_v2:  ; $578E — 1 spawns, 2 NPCs
    db $8F, $FF, $02, $01, $15  ; spawn (2,1) mt$15 Castle_15
    db $17, $05, $02, $02, $16  ; NPC left b=7 spr=$05 (2,2) script=$16
    db $00, $1A, $05, $04, $18  ; NPC down b=0 spr=$1A (5,4) script=$18
    db $FF  ; terminator

Interact_Farm_s4_v3:  ; $579E — 1 spawns, 3 NPCs
    db $8F, $FF, $02, $01, $15  ; spawn (2,1) mt$15 Castle_15
    db $17, $05, $02, $02, $16  ; NPC left b=7 spr=$05 (2,2) script=$16
    db $00, $1A, $06, $04, $18  ; NPC down b=0 spr=$1A (6,4) script=$18
    db $03, $00, $06, $01, $19  ; NPC down b=3 spr=$00 (6,1) script=$19
    db $FF  ; terminator

Interact_Farm_s5:  ; $57B3 — 3 NPCs
    db $00, $00, $05, $03, $1A  ; NPC down b=0 spr=$00 (5,3) script=$1A
    db $00, $3A, $05, $02, $1B  ; NPC down b=0 spr=$3A (5,2) script=$1B
    db $30, $44, $04, $06, $1C  ; NPC right b=0 spr=$44 (4,6) script=$1C
    db $FF  ; terminator

Interact_Farm_s5_v1:  ; $57C3 — 3 NPCs
    db $00, $00, $05, $03, $1A  ; NPC down b=0 spr=$00 (5,3) script=$1A
    db $00, $3A, $05, $02, $1B  ; NPC down b=0 spr=$3A (5,2) script=$1B
    db $30, $45, $04, $06, $1D  ; NPC right b=0 spr=$45 (4,6) script=$1D
    db $FF  ; terminator

Interact_Farm_s5_v2:  ; $57D3 — 5 NPCs
    db $00, $00, $05, $03, $1A  ; NPC down b=0 spr=$00 (5,3) script=$1A
    db $00, $3A, $05, $02, $1B  ; NPC down b=0 spr=$3A (5,2) script=$1B
    db $32, $01, $04, $05, $1E  ; NPC right b=2 spr=$01 (4,5) script=$1E
    db $00, $11, $07, $05, $1F  ; NPC down b=0 spr=$11 (7,5) script=$1F
    db $33, $0B, $02, $02, $20  ; NPC right b=3 spr=$0B (2,2) script=$20
    db $FF  ; terminator

Interact_Farm_s6:  ; $57ED — empty
    db $FF  ; terminator

Interact_Farm_s6_v1:  ; $57EE — 1 NPCs
    db $00, $46, $03, $03, $21  ; NPC down b=0 spr=$46 (3,3) script=$21
    db $FF  ; terminator

Interact_Farm_s6_v2:  ; $57F4 — 2 NPCs
    db $02, $47, $02, $01, $22  ; NPC down b=2 spr=$47 (2,1) script=$22
    db $00, $48, $03, $03, $23  ; NPC down b=0 spr=$48 (3,3) script=$23
    db $FF  ; terminator

Interact_Farm_s6_v3:  ; $57FF — 6 NPCs
    db $10, $12, $05, $01, $24  ; NPC left b=0 spr=$12 (5,1) script=$24
    db $10, $12, $05, $02, $25  ; NPC left b=0 spr=$12 (5,2) script=$25
    db $10, $12, $05, $03, $26  ; NPC left b=0 spr=$12 (5,3) script=$26
    db $01, $04, $01, $02, $27  ; NPC down b=1 spr=$04 (1,2) script=$27
    db $00, $0F, $02, $05, $28  ; NPC down b=0 spr=$0F (2,5) script=$28
    db $40, $54, $05, $00, $FF  ; NPC noTalk down b=0 spr=$54 (5,0) script=none
    db $FF  ; terminator

Exit_Farm_s0:  ; $581E — 0 exits
    db $FF  ; terminator

Exit_Farm_s1:  ; $581F — 0 exits
    db $FF  ; terminator

Exit_Farm_s2:  ; $5820 — 0 exits
    db $FF  ; terminator

Exit_Farm_s2_v1:  ; $5821 — 1 exits
    db $08, $02, $0B, $01, $00, $00, $00  ; exit (8,2)→mt$0B Castle_0B gate scr=0 spawn(0,0)
    db $FF  ; terminator

Exit_Farm_s4:  ; $5829 — 1 exits
    db $06, $04, $05, $00, $02, $06, $04  ; exit (6,4)→mt$05 Stable  scr=2 spawn(6,4)
    db $FF  ; terminator

Exit_Farm_s5:  ; $5831 — 1 exits
    db $07, $05, $00, $00, $05, $07, $05  ; exit (7,5)→mt$00 Castle  scr=5 spawn(7,5)
    db $FF  ; terminator

Exit_Farm_s6:  ; $5839 — 0 exits
    db $FF  ; terminator

RoomSub_Stable:  ; $583A — mt=[$05]
    dw StepBlk_Stable_s0  ; screen 0
    dw StepBlk_Stable_s1  ; screen 1
    dw StepBlk_Stable_s2  ; screen 2

StepBlk_Stable_s0:  ; $5840 — RAM=$D945, 2 steps
    dw $D945  ; RAM step counter
    db $0A, $29  ; step 0: layout=$0A bank=$29
    dw Interact_Stable_s0  ; → interact/NPC data
    dw Exit_Stable_s0  ; → exit data
    db $0B, $29  ; step 1: layout=$0B bank=$29
    dw Interact_Stable_s0_v1  ; → interact/NPC data
    dw Exit_Stable_s0_v1  ; → exit data

StepBlk_Stable_s1:  ; $584E — RAM=$D946, 2 steps
    dw $D946  ; RAM step counter
    db $0C, $29  ; step 0: layout=$0C bank=$29
    dw Interact_Stable_s1  ; → interact/NPC data
    dw Exit_Stable_s1  ; → exit data
    db $0C, $29  ; step 1: layout=$0C bank=$29
    dw Interact_Stable_s1_v1  ; → interact/NPC data
    dw Exit_Stable_s1  ; → exit data

StepBlk_Stable_s2:  ; $585C — RAM=$D947, 4 steps
    dw $D947  ; RAM step counter
    db $0D, $29  ; step 0: layout=$0D bank=$29
    dw Interact_Stable_s2  ; → interact/NPC data
    dw Exit_Stable_s2  ; → exit data
    db $0D, $29  ; step 1: layout=$0D bank=$29
    dw Interact_Stable_s2_v1  ; → interact/NPC data
    dw Exit_Stable_s2  ; → exit data
    db $0D, $29  ; step 2: layout=$0D bank=$29
    dw Interact_Stable_s2_v2  ; → interact/NPC data
    dw Exit_Stable_s2  ; → exit data
    db $0D, $29  ; step 3: layout=$0D bank=$29
    dw Interact_Stable_s2_v3  ; → interact/NPC data
    dw Exit_Stable_s2  ; → exit data

Interact_Stable_s0:  ; $5876 — 3 NPCs
    db $01, $3B, $02, $02, $01  ; NPC down b=1 spr=$3B (2,2) script=$01
    db $36, $3A, $04, $06, $02  ; NPC right b=6 spr=$3A (4,6) script=$02
    db $00, $3A, $05, $06, $03  ; NPC down b=0 spr=$3A (5,6) script=$03
    db $FF  ; terminator

Interact_Stable_s0_v1:  ; $5886 — 4 spawns, 3 NPCs
    db $8F, $FF, $04, $03, $04  ; spawn (4,3) mt$04 Farm
    db $8F, $FF, $05, $03, $04  ; spawn (5,3) mt$04 Farm
    db $8F, $FF, $04, $04, $04  ; spawn (4,4) mt$04 Farm
    db $8F, $FF, $05, $04, $04  ; spawn (5,4) mt$04 Farm
    db $01, $1B, $02, $02, $05  ; NPC down b=1 spr=$1B (2,2) script=$05
    db $06, $2A, $04, $06, $06  ; NPC down b=6 spr=$2A (4,6) script=$06
    db $00, $16, $05, $06, $07  ; NPC down b=0 spr=$16 (5,6) script=$07
    db $FF  ; terminator

Interact_Stable_s1:  ; $58AA — 4 spawns
    db $8F, $FF, $04, $02, $FF  ; spawn (4,2) mt$FF $FF
    db $8F, $FF, $05, $02, $FF  ; spawn (5,2) mt$FF $FF
    db $8F, $FF, $04, $03, $08  ; spawn (4,3) mt$08 Gate_08
    db $8F, $FF, $05, $03, $08  ; spawn (5,3) mt$08 Gate_08
    db $FF  ; terminator

Interact_Stable_s1_v1:  ; $58BF — 4 spawns, 3 NPCs
    db $8F, $FF, $04, $02, $FF  ; spawn (4,2) mt$FF $FF
    db $8F, $FF, $05, $02, $FF  ; spawn (5,2) mt$FF $FF
    db $8F, $FF, $04, $03, $08  ; spawn (4,3) mt$08 Gate_08
    db $8F, $FF, $05, $03, $08  ; spawn (5,3) mt$08 Gate_08
    db $00, $49, $01, $01, $09  ; NPC down b=0 spr=$49 (1,1) script=$09
    db $10, $4A, $08, $03, $0A  ; NPC left b=0 spr=$4A (8,3) script=$0A
    db $20, $4B, $03, $06, $0B  ; NPC up b=0 spr=$4B (3,6) script=$0B
    db $FF  ; terminator

Interact_Stable_s2:  ; $58E3 — 4 spawns, 3 NPCs
    db $8F, $FF, $04, $03, $0C  ; spawn (4,3) mt$0C Gate_0C
    db $8F, $FF, $05, $03, $0D  ; spawn (5,3) mt$0D OldManGate
    db $8F, $FF, $07, $00, $0E  ; spawn (7,0) mt$0E Castle_0E
    db $8F, $FF, $08, $00, $0F  ; spawn (8,0) mt$0F Room_0F
    db $06, $25, $02, $01, $11  ; NPC down b=6 spr=$25 (2,1) script=$11
    db $00, $3E, $08, $02, $12  ; NPC down b=0 spr=$3E (8,2) script=$12
    db $37, $21, $03, $03, $10  ; NPC right b=7 spr=$21 (3,3) script=$10
    db $FF  ; terminator

Interact_Stable_s2_v1:  ; $5907 — 4 spawns, 2 NPCs
    db $8F, $FF, $04, $03, $0C  ; spawn (4,3) mt$0C Gate_0C
    db $8F, $FF, $05, $03, $0D  ; spawn (5,3) mt$0D OldManGate
    db $8F, $FF, $07, $00, $0E  ; spawn (7,0) mt$0E Castle_0E
    db $8F, $FF, $08, $00, $0F  ; spawn (8,0) mt$0F Room_0F
    db $06, $25, $02, $01, $11  ; NPC down b=6 spr=$25 (2,1) script=$11
    db $00, $3E, $08, $02, $12  ; NPC down b=0 spr=$3E (8,2) script=$12
    db $FF  ; terminator

Interact_Stable_s2_v2:  ; $5926 — 4 spawns, 3 NPCs
    db $8F, $FF, $04, $03, $0C  ; spawn (4,3) mt$0C Gate_0C
    db $8F, $FF, $05, $03, $0D  ; spawn (5,3) mt$0D OldManGate
    db $8F, $FF, $07, $00, $0E  ; spawn (7,0) mt$0E Castle_0E
    db $8F, $FF, $08, $00, $0F  ; spawn (8,0) mt$0F Room_0F
    db $06, $25, $02, $01, $11  ; NPC down b=6 spr=$25 (2,1) script=$11
    db $00, $3D, $08, $02, $14  ; NPC down b=0 spr=$3D (8,2) script=$14
    db $37, $39, $03, $03, $13  ; NPC right b=7 spr=$39 (3,3) script=$13
    db $FF  ; terminator

Interact_Stable_s2_v3:  ; $594A — 4 spawns, 2 NPCs
    db $8F, $FF, $04, $03, $0C  ; spawn (4,3) mt$0C Gate_0C
    db $8F, $FF, $05, $03, $0D  ; spawn (5,3) mt$0D OldManGate
    db $8F, $FF, $07, $00, $0E  ; spawn (7,0) mt$0E Castle_0E
    db $8F, $FF, $08, $00, $0F  ; spawn (8,0) mt$0F Room_0F
    db $06, $25, $02, $01, $11  ; NPC down b=6 spr=$25 (2,1) script=$11
    db $00, $3D, $08, $02, $14  ; NPC down b=0 spr=$3D (8,2) script=$14
    db $FF  ; terminator

Exit_Stable_s0:  ; $5969 — 2 exits
    db $04, $00, $1B, $00, $00, $04, $07  ; exit (4,0)→mt$1B Room_1B  scr=0 spawn(4,7)
    db $05, $00, $1B, $00, $00, $05, $07  ; exit (5,0)→mt$1B Room_1B  scr=0 spawn(5,7)
    db $FF  ; terminator

Exit_Stable_s0_v1:  ; $5978 — 2 exits
    db $04, $00, $1B, $00, $00, $04, $07  ; exit (4,0)→mt$1B Room_1B  scr=0 spawn(4,7)
    db $05, $00, $1B, $00, $00, $05, $07  ; exit (5,0)→mt$1B Room_1B  scr=0 spawn(5,7)
    db $FF  ; terminator

Exit_Stable_s1:  ; $5987 — 2 exits
    db $04, $00, $1C, $00, $00, $04, $07  ; exit (4,0)→mt$1C Room_1C  scr=0 spawn(4,7)
    db $05, $00, $1C, $00, $00, $05, $07  ; exit (5,0)→mt$1C Room_1C  scr=0 spawn(5,7)
    db $FF  ; terminator

Exit_Stable_s2:  ; $5996 — 1 exits
    db $06, $04, $04, $00, $04, $06, $04  ; exit (6,4)→mt$04 Farm  scr=4 spawn(6,4)
    db $FF  ; terminator

RoomSub_ArenaLobby:  ; $599E — mt=[$06]
    dw StepBlk_ArenaLobby_s0  ; screen 0
    dw StepBlk_ArenaLobby_s1  ; screen 1
    dw StepBlk_ArenaLobby_s2  ; screen 2
    dw $FFFF  ; screen 3 (unused)

StepBlk_ArenaLobby_s0:  ; $59A6 — RAM=$D948, 1 steps
    dw $D948  ; RAM step counter
    db $0F, $29  ; step 0: layout=$0F bank=$29
    dw Interact_ArenaLobby_s0  ; → interact/NPC data
    dw Exit_ArenaLobby_s0  ; → exit data

StepBlk_ArenaLobby_s1:  ; $59AE — RAM=$D949, 1 steps
    dw $D949  ; RAM step counter
    db $10, $29  ; step 0: layout=$10 bank=$29
    dw Interact_ArenaLobby_s1  ; → interact/NPC data
    dw Exit_ArenaLobby_s1  ; → exit data

StepBlk_ArenaLobby_s2:  ; $59B6 — RAM=$D94A, 1 steps
    dw $D94A  ; RAM step counter
    db $11, $29  ; step 0: layout=$11 bank=$29
    dw Interact_ArenaLobby_s2  ; → interact/NPC data
    dw Exit_ArenaLobby_s2  ; → exit data

Interact_ArenaLobby_s0:  ; $59BE — 1 spawns, 4 NPCs
    db $90, $FF, $05, $04, $01  ; walk_exit (5,4) mt$01 GreatTree
    db $50, $E0, $05, $04, $FF  ; NPC noTalk left b=0 spr=$E0 (5,4) script=none
    db $70, $E1, $03, $05, $02  ; NPC noTalk right b=0 spr=$E1 (3,5) script=$02
    db $40, $E2, $02, $04, $03  ; NPC noTalk down b=0 spr=$E2 (2,4) script=$03
    db $50, $E3, $03, $03, $04  ; NPC noTalk left b=0 spr=$E3 (3,3) script=$04
    db $FF  ; terminator

Interact_ArenaLobby_s1:  ; $59D8 — 4 spawns, 4 NPCs
    db $8F, $FF, $04, $02, $05  ; spawn (4,2) mt$05 Stable
    db $8F, $FF, $05, $02, $05  ; spawn (5,2) mt$05 Stable
    db $8F, $FF, $03, $04, $06  ; spawn (3,4) mt$06 ArenaLobby
    db $8F, $FF, $06, $06, $07  ; spawn (6,6) mt$07 ArenaRooms
    db $37, $12, $02, $04, $08  ; NPC right b=7 spr=$12 (2,4) script=$08
    db $17, $12, $07, $06, $09  ; NPC left b=7 spr=$12 (7,6) script=$09
    db $60, $11, $04, $08, $0E  ; NPC noTalk up b=0 spr=$11 (4,8) script=$0E
    db $40, $54, $06, $05, $FF  ; NPC noTalk down b=0 spr=$54 (6,5) script=none
    db $FF  ; terminator

Interact_ArenaLobby_s2:  ; $5A01 — 1 spawns, 1 NPCs
    db $82, $FF, $06, $05, $0A  ; spc_82 (6,5) mt$0A SecretPassage
    db $00, $0B, $06, $04, $0B  ; NPC down b=0 spr=$0B (6,4) script=$0B
    db $FF  ; terminator

Exit_ArenaLobby_s0:  ; $5A0C — 1 exits
    db $05, $00, $07, $00, $04, $05, $07  ; exit (5,0)→mt$07 ArenaRooms  scr=4 spawn(5,7)
    db $FF  ; terminator

Exit_ArenaLobby_s1:  ; $5A14 — 2 exits
    db $04, $07, $01, $00, $84, $04, $03  ; exit (4,7)→mt$01 GreatTree  scr=4+Y8 spawn(4,3)
    db $05, $07, $01, $00, $84, $05, $03  ; exit (5,7)→mt$01 GreatTree  scr=4+Y8 spawn(5,3)
    db $FF  ; terminator

Exit_ArenaLobby_s2:  ; $5A23 — 1 exits
    db $04, $00, $07, $00, $06, $04, $07  ; exit (4,0)→mt$07 ArenaRooms  scr=6 spawn(4,7)
    db $FF  ; terminator

RoomSub_ArenaRooms:  ; $5A2B — mt=[$07]
    dw StepBlk_ArenaRooms_s0  ; screen 0
    dw StepBlk_ArenaRooms_s1  ; screen 1
    dw StepBlk_ArenaRooms_s2  ; screen 2
    dw $FFFF  ; screen 3 (unused)
    dw StepBlk_ArenaRooms_s4  ; screen 4
    dw StepBlk_ArenaRooms_s5  ; screen 5
    dw StepBlk_ArenaRooms_s6  ; screen 6
    dw $FFFF  ; screen 7 (unused)

StepBlk_ArenaRooms_s0:  ; $5A3B — RAM=$D94B, 1 steps
    dw $D94B  ; RAM step counter
    db $13, $29  ; step 0: layout=$13 bank=$29
    dw Interact_ArenaRooms_s0  ; → interact/NPC data
    dw Exit_ArenaRooms_s0  ; → exit data

StepBlk_ArenaRooms_s1:  ; $5A43 — RAM=$D94C, 8 steps
    dw $D94C  ; RAM step counter
    db $14, $29  ; step 0: layout=$14 bank=$29
    dw Interact_ArenaRooms_s1  ; → interact/NPC data
    dw Exit_ArenaRooms_s1  ; → exit data
    db $15, $29  ; step 1: layout=$15 bank=$29
    dw Interact_ArenaRooms_s1  ; → interact/NPC data
    dw Exit_ArenaRooms_s1_v1  ; → exit data
    db $16, $29  ; step 2: layout=$16 bank=$29
    dw Interact_ArenaRooms_s1_v1  ; → interact/NPC data
    dw Exit_ArenaRooms_s1_v2  ; → exit data
    db $16, $29  ; step 3: layout=$16 bank=$29
    dw Interact_ArenaRooms_s1_v2  ; → interact/NPC data
    dw Exit_ArenaRooms_s1_v2  ; → exit data
    db $17, $29  ; step 4: layout=$17 bank=$29
    dw Interact_ArenaRooms_s1_v3  ; → interact/NPC data
    dw Exit_ArenaRooms_s1_v3  ; → exit data
    db $17, $29  ; step 5: layout=$17 bank=$29
    dw Interact_ArenaRooms_s1_v4  ; → interact/NPC data
    dw Exit_ArenaRooms_s1_v3  ; → exit data
    db $17, $29  ; step 6: layout=$17 bank=$29
    dw Interact_ArenaRooms_s1_v5  ; → interact/NPC data
    dw Exit_ArenaRooms_s1_v3  ; → exit data
    db $17, $29  ; step 7: layout=$17 bank=$29
    dw Interact_ArenaRooms_s1_v6  ; → interact/NPC data
    dw Exit_ArenaRooms_s1_v3  ; → exit data

StepBlk_ArenaRooms_s2:  ; $5A75 — RAM=$D94D, 1 steps
    dw $D94D  ; RAM step counter
    db $18, $29  ; step 0: layout=$18 bank=$29
    dw Interact_ArenaRooms_s2  ; → interact/NPC data
    dw Exit_ArenaRooms_s2  ; → exit data

StepBlk_ArenaRooms_s4:  ; $5A7D — RAM=$D94E, 2 steps
    dw $D94E  ; RAM step counter
    db $19, $29  ; step 0: layout=$19 bank=$29
    dw Interact_ArenaRooms_s4  ; → interact/NPC data
    dw Exit_ArenaRooms_s4  ; → exit data
    db $19, $29  ; step 1: layout=$19 bank=$29
    dw Interact_ArenaRooms_s4_v1  ; → interact/NPC data
    dw Exit_ArenaRooms_s4  ; → exit data

StepBlk_ArenaRooms_s5:  ; $5A8B — RAM=$D94F, 1 steps
    dw $D94F  ; RAM step counter
    db $1A, $29  ; step 0: layout=$1A bank=$29
    dw Interact_ArenaRooms_s5  ; → interact/NPC data
    dw Exit_ArenaRooms_s5  ; → exit data

StepBlk_ArenaRooms_s6:  ; $5A93 — RAM=$D950, 1 steps
    dw $D950  ; RAM step counter
    db $1B, $29  ; step 0: layout=$1B bank=$29
    dw Interact_ArenaRooms_s6  ; → interact/NPC data
    dw Exit_ArenaRooms_s6  ; → exit data

Interact_ArenaRooms_s0:  ; $5A9B — 1 spawns, 4 NPCs
    db $82, $FF, $03, $04, $01  ; spc_82 (3,4) mt$01 GreatTree
    db $00, $41, $08, $03, $02  ; NPC down b=0 spr=$41 (8,3) script=$02
    db $40, $52, $03, $04, $FF  ; NPC noTalk down b=0 spr=$52 (3,4) script=none
    db $40, $E0, $03, $04, $FF  ; NPC noTalk down b=0 spr=$E0 (3,4) script=none
    db $00, $11, $04, $02, $1A  ; NPC down b=0 spr=$11 (4,2) script=$1A
    db $FF  ; terminator

Interact_ArenaRooms_s1:  ; $5AB5 — 3 spawns, 3 NPCs
    db $90, $FF, $03, $05, $03  ; walk_exit (3,5) mt$03 GateHub
    db $90, $FF, $04, $05, $04  ; walk_exit (4,5) mt$04 Farm
    db $90, $FF, $05, $05, $05  ; walk_exit (5,5) mt$05 Stable
    db $06, $1F, $04, $02, $06  ; NPC down b=6 spr=$1F (4,2) script=$06
    db $00, $08, $03, $06, $07  ; NPC down b=0 spr=$08 (3,6) script=$07
    db $00, $08, $07, $05, $08  ; NPC down b=0 spr=$08 (7,5) script=$08
    db $FF  ; terminator

Interact_ArenaRooms_s1_v1:  ; $5AD4 — 3 spawns, 4 NPCs
    db $90, $FF, $03, $05, $03  ; walk_exit (3,5) mt$03 GateHub
    db $90, $FF, $04, $05, $04  ; walk_exit (4,5) mt$04 Farm
    db $90, $FF, $05, $05, $05  ; walk_exit (5,5) mt$05 Stable
    db $06, $1F, $04, $02, $06  ; NPC down b=6 spr=$1F (4,2) script=$06
    db $00, $08, $03, $06, $07  ; NPC down b=0 spr=$08 (3,6) script=$07
    db $00, $08, $07, $05, $08  ; NPC down b=0 spr=$08 (7,5) script=$08
    db $00, $4D, $02, $04, $FF  ; NPC down b=0 spr=$4D (2,4) script=none
    db $FF  ; terminator

Interact_ArenaRooms_s1_v2:  ; $5AF8 — 3 spawns, 3 NPCs
    db $90, $FF, $03, $05, $03  ; walk_exit (3,5) mt$03 GateHub
    db $90, $FF, $04, $05, $04  ; walk_exit (4,5) mt$04 Farm
    db $90, $FF, $05, $05, $05  ; walk_exit (5,5) mt$05 Stable
    db $06, $1F, $04, $02, $06  ; NPC down b=6 spr=$1F (4,2) script=$06
    db $00, $08, $03, $06, $07  ; NPC down b=0 spr=$08 (3,6) script=$07
    db $00, $08, $07, $05, $08  ; NPC down b=0 spr=$08 (7,5) script=$08
    db $FF  ; terminator

Interact_ArenaRooms_s1_v3:  ; $5B17 — 3 spawns, 5 NPCs
    db $90, $FF, $03, $05, $03  ; walk_exit (3,5) mt$03 GateHub
    db $90, $FF, $04, $05, $04  ; walk_exit (4,5) mt$04 Farm
    db $90, $FF, $05, $05, $05  ; walk_exit (5,5) mt$05 Stable
    db $06, $1F, $04, $02, $06  ; NPC down b=6 spr=$1F (4,2) script=$06
    db $00, $08, $03, $06, $07  ; NPC down b=0 spr=$08 (3,6) script=$07
    db $00, $08, $07, $05, $08  ; NPC down b=0 spr=$08 (7,5) script=$08
    db $00, $4D, $02, $04, $FF  ; NPC down b=0 spr=$4D (2,4) script=none
    db $00, $4D, $06, $04, $FF  ; NPC down b=0 spr=$4D (6,4) script=none
    db $FF  ; terminator

Interact_ArenaRooms_s1_v4:  ; $5B40 — 3 spawns, 4 NPCs
    db $90, $FF, $03, $05, $03  ; walk_exit (3,5) mt$03 GateHub
    db $90, $FF, $04, $05, $04  ; walk_exit (4,5) mt$04 Farm
    db $90, $FF, $05, $05, $05  ; walk_exit (5,5) mt$05 Stable
    db $06, $1F, $04, $02, $06  ; NPC down b=6 spr=$1F (4,2) script=$06
    db $00, $08, $03, $06, $07  ; NPC down b=0 spr=$08 (3,6) script=$07
    db $00, $08, $07, $05, $08  ; NPC down b=0 spr=$08 (7,5) script=$08
    db $00, $4D, $06, $04, $FF  ; NPC down b=0 spr=$4D (6,4) script=none
    db $FF  ; terminator

Interact_ArenaRooms_s1_v5:  ; $5B64 — 3 spawns, 4 NPCs
    db $90, $FF, $03, $05, $03  ; walk_exit (3,5) mt$03 GateHub
    db $90, $FF, $04, $05, $04  ; walk_exit (4,5) mt$04 Farm
    db $90, $FF, $05, $05, $05  ; walk_exit (5,5) mt$05 Stable
    db $06, $1F, $04, $02, $06  ; NPC down b=6 spr=$1F (4,2) script=$06
    db $00, $08, $03, $06, $07  ; NPC down b=0 spr=$08 (3,6) script=$07
    db $00, $08, $07, $05, $08  ; NPC down b=0 spr=$08 (7,5) script=$08
    db $00, $4D, $02, $04, $FF  ; NPC down b=0 spr=$4D (2,4) script=none
    db $FF  ; terminator

Interact_ArenaRooms_s1_v6:  ; $5B88 — 3 spawns, 3 NPCs
    db $90, $FF, $03, $05, $03  ; walk_exit (3,5) mt$03 GateHub
    db $90, $FF, $04, $05, $04  ; walk_exit (4,5) mt$04 Farm
    db $90, $FF, $05, $05, $05  ; walk_exit (5,5) mt$05 Stable
    db $06, $1F, $04, $02, $06  ; NPC down b=6 spr=$1F (4,2) script=$06
    db $00, $08, $03, $06, $07  ; NPC down b=0 spr=$08 (3,6) script=$07
    db $00, $08, $07, $05, $08  ; NPC down b=0 spr=$08 (7,5) script=$08
    db $FF  ; terminator

Interact_ArenaRooms_s2:  ; $5BA7 — 2 spawns, 3 NPCs
    db $8F, $FF, $01, $02, $09  ; spawn (1,2) mt$09 StarryShrine
    db $8F, $FF, $02, $02, $0A  ; spawn (2,2) mt$0A SecretPassage
    db $00, $04, $03, $04, $0B  ; NPC down b=0 spr=$04 (3,4) script=$0B
    db $00, $0B, $06, $02, $0C  ; NPC down b=0 spr=$0B (6,2) script=$0C
    db $17, $0A, $08, $05, $0D  ; NPC left b=7 spr=$0A (8,5) script=$0D
    db $FF  ; terminator

Interact_ArenaRooms_s4:  ; $5BC1 — 3 NPCs
    db $07, $09, $02, $01, $0E  ; NPC down b=7 spr=$09 (2,1) script=$0E
    db $04, $42, $08, $05, $0F  ; NPC down b=4 spr=$42 (8,5) script=$0F
    db $30, $0A, $01, $06, $10  ; NPC right b=0 spr=$0A (1,6) script=$10
    db $FF  ; terminator

Interact_ArenaRooms_s4_v1:  ; $5BD1 — 3 NPCs
    db $04, $09, $08, $05, $0E  ; NPC down b=4 spr=$09 (8,5) script=$0E
    db $06, $42, $02, $01, $0F  ; NPC down b=6 spr=$42 (2,1) script=$0F
    db $30, $0A, $01, $06, $10  ; NPC right b=0 spr=$0A (1,6) script=$10
    db $FF  ; terminator

Interact_ArenaRooms_s5:  ; $5BE1 — 3 NPCs
    db $00, $0B, $05, $01, $11  ; NPC down b=0 spr=$0B (5,1) script=$11
    db $20, $0F, $05, $02, $12  ; NPC up b=0 spr=$0F (5,2) script=$12
    db $22, $17, $04, $05, $FF  ; NPC up b=2 spr=$17 (4,5) script=none
    db $FF  ; terminator

Interact_ArenaRooms_s6:  ; $5BF1 — 4 spawns, 7 NPCs
    db $8F, $FF, $08, $03, $13  ; spawn (8,3) mt$13 Room_13
    db $8F, $FF, $07, $04, $14  ; spawn (7,4) mt$14 Castle_14
    db $8F, $FF, $06, $05, $15  ; spawn (6,5) mt$15 Castle_15
    db $8F, $FF, $06, $06, $16  ; spawn (6,6) mt$16 MedalManRoom
    db $06, $0A, $03, $02, $17  ; NPC down b=6 spr=$0A (3,2) script=$17
    db $26, $20, $03, $03, $18  ; NPC up b=6 spr=$20 (3,3) script=$18
    db $30, $0B, $02, $06, $19  ; NPC right b=0 spr=$0B (2,6) script=$19
    db $40, $E0, $05, $00, $FF  ; NPC noTalk down b=0 spr=$E0 (5,0) script=none
    db $40, $E1, $05, $00, $FF  ; NPC noTalk down b=0 spr=$E1 (5,0) script=none
    db $40, $E2, $05, $00, $FF  ; NPC noTalk down b=0 spr=$E2 (5,0) script=none
    db $40, $E3, $05, $00, $FF  ; NPC noTalk down b=0 spr=$E3 (5,0) script=none
    db $FF  ; terminator

Exit_ArenaRooms_s0:  ; $5C29 — 1 exits
    db $05, $01, $1D, $00, $00, $05, $07  ; exit (5,1)→mt$1D Room_1D  scr=0 spawn(5,7)
    db $FF  ; terminator

Exit_ArenaRooms_s1:  ; $5C31 — 0 exits
    db $FF  ; terminator

Exit_ArenaRooms_s1_v1:  ; $5C32 — 1 exits
    db $05, $02, $1F, $00, $00, $05, $02  ; exit (5,2)→mt$1F Room_1F  scr=0 spawn(5,2)
    db $FF  ; terminator

Exit_ArenaRooms_s1_v2:  ; $5C3A — 2 exits
    db $05, $02, $1F, $00, $00, $05, $02  ; exit (5,2)→mt$1F Room_1F  scr=0 spawn(5,2)
    db $02, $04, $0E, $01, $00, $00, $00  ; exit (2,4)→mt$0E Castle_0E gate scr=0 spawn(0,0)
    db $FF  ; terminator

Exit_ArenaRooms_s1_v3:  ; $5C49 — 3 exits
    db $05, $02, $1F, $00, $00, $05, $02  ; exit (5,2)→mt$1F Room_1F  scr=0 spawn(5,2)
    db $02, $04, $0E, $01, $00, $00, $00  ; exit (2,4)→mt$0E Castle_0E gate scr=0 spawn(0,0)
    db $06, $04, $1D, $01, $00, $00, $00  ; exit (6,4)→mt$1D Room_1D gate scr=0 spawn(0,0)
    db $FF  ; terminator

Exit_ArenaRooms_s2:  ; $5C5F — 1 exits
    db $05, $01, $1E, $00, $00, $05, $07  ; exit (5,1)→mt$1E Room_1E  scr=0 spawn(5,7)
    db $FF  ; terminator

Exit_ArenaRooms_s4:  ; $5C67 — 1 exits
    db $05, $07, $06, $00, $00, $05, $00  ; exit (5,7)→mt$06 ArenaLobby  scr=0 spawn(5,0)
    db $FF  ; terminator

Exit_ArenaRooms_s5:  ; $5C6F — 2 exits
    db $04, $07, $06, $00, $01, $04, $03  ; exit (4,7)→mt$06 ArenaLobby  scr=1 spawn(4,3)
    db $05, $07, $06, $00, $01, $05, $03  ; exit (5,7)→mt$06 ArenaLobby  scr=1 spawn(5,3)
    db $FF  ; terminator

Exit_ArenaRooms_s6:  ; $5C7E — 1 exits
    db $04, $07, $06, $00, $02, $04, $00  ; exit (4,7)→mt$06 ArenaLobby  scr=2 spawn(4,0)
    db $FF  ; terminator

RoomSub_Gate_08:  ; $5C86 — mt=[$08]
    dw StepBlk_Gate_08_s0  ; screen 0

StepBlk_Gate_08_s0:  ; $5C88 — RAM=$D951, 9 steps
    dw $D951  ; RAM step counter
    db $1E, $29  ; step 0: layout=$1E bank=$29
    dw Interact_Gate_08_s0  ; → interact/NPC data
    dw $FFFF  ; → exit data
    db $1E, $29  ; step 1: layout=$1E bank=$29
    dw Interact_Gate_08_s0_v1  ; → interact/NPC data
    dw $FFFF  ; → exit data
    db $1E, $29  ; step 2: layout=$1E bank=$29
    dw Interact_Gate_08_s0_v2  ; → interact/NPC data
    dw $FFFF  ; → exit data
    db $1E, $29  ; step 3: layout=$1E bank=$29
    dw Interact_Gate_08_s0_v2  ; → interact/NPC data
    dw $FFFF  ; → exit data
    db $1E, $29  ; step 4: layout=$1E bank=$29
    dw Interact_Gate_08_s0_v3  ; → interact/NPC data
    dw $FFFF  ; → exit data
    db $1E, $29  ; step 5: layout=$1E bank=$29
    dw Interact_Gate_08_s0_v4  ; → interact/NPC data
    dw $FFFF  ; → exit data
    db $1E, $29  ; step 6: layout=$1E bank=$29
    dw Interact_Gate_08_s0_v5  ; → interact/NPC data
    dw $FFFF  ; → exit data
    db $1E, $29  ; step 7: layout=$1E bank=$29
    dw Interact_Gate_08_s0_v6  ; → interact/NPC data
    dw $FFFF  ; → exit data
    db $1E, $29  ; step 8: layout=$1E bank=$29
    dw Interact_Gate_08_s0_v7  ; → interact/NPC data
    dw $FFFF  ; → exit data

Interact_Gate_08_s0:  ; $5CC0 — 3 NPCs
    db $20, $08, $05, $08, $FF  ; NPC up b=0 spr=$08 (5,8) script=none
    db $40, $F0, $05, $04, $FF  ; NPC noTalk down b=0 spr=$F0 (5,4) script=none
    db $40, $F1, $05, $04, $FF  ; NPC noTalk down b=0 spr=$F1 (5,4) script=none
    db $FF  ; terminator

Interact_Gate_08_s0_v1:  ; $5CD0 — 3 NPCs
    db $20, $08, $05, $08, $FF  ; NPC up b=0 spr=$08 (5,8) script=none
    db $00, $55, $05, $04, $FF  ; NPC down b=0 spr=$55 (5,4) script=none
    db $00, $55, $05, $04, $FF  ; NPC down b=0 spr=$55 (5,4) script=none
    db $FF  ; terminator

Interact_Gate_08_s0_v2:  ; $5CE0 — 3 NPCs
    db $20, $08, $05, $08, $FF  ; NPC up b=0 spr=$08 (5,8) script=none
    db $40, $F0, $05, $04, $FF  ; NPC noTalk down b=0 spr=$F0 (5,4) script=none
    db $40, $55, $05, $04, $FF  ; NPC noTalk down b=0 spr=$55 (5,4) script=none
    db $FF  ; terminator

Interact_Gate_08_s0_v3:  ; $5CF0 — 3 NPCs
    db $20, $08, $05, $08, $FF  ; NPC up b=0 spr=$08 (5,8) script=none
    db $40, $F0, $05, $04, $FF  ; NPC noTalk down b=0 spr=$F0 (5,4) script=none
    db $40, $F1, $05, $04, $FF  ; NPC noTalk down b=0 spr=$F1 (5,4) script=none
    db $FF  ; terminator

Interact_Gate_08_s0_v4:  ; $5D00 — 3 NPCs
    db $20, $08, $05, $08, $FF  ; NPC up b=0 spr=$08 (5,8) script=none
    db $00, $55, $05, $04, $FF  ; NPC down b=0 spr=$55 (5,4) script=none
    db $00, $55, $05, $04, $FF  ; NPC down b=0 spr=$55 (5,4) script=none
    db $FF  ; terminator

Interact_Gate_08_s0_v5:  ; $5D10 — 2 NPCs
    db $60, $08, $05, $08, $FF  ; NPC noTalk up b=0 spr=$08 (5,8) script=none
    db $20, $5E, $05, $04, $FF  ; NPC up b=0 spr=$5E (5,4) script=none
    db $FF  ; terminator

Interact_Gate_08_s0_v6:  ; $5D1B — 4 NPCs
    db $60, $08, $05, $08, $FF  ; NPC noTalk up b=0 spr=$08 (5,8) script=none
    db $70, $21, $00, $04, $FF  ; NPC noTalk right b=0 spr=$21 (0,4) script=none
    db $40, $55, $05, $04, $FF  ; NPC noTalk down b=0 spr=$55 (5,4) script=none
    db $20, $5E, $05, $07, $FF  ; NPC up b=0 spr=$5E (5,7) script=none
    db $FF  ; terminator

Interact_Gate_08_s0_v7:  ; $5D30 — 4 NPCs
    db $20, $08, $05, $07, $FF  ; NPC up b=0 spr=$08 (5,7) script=none
    db $40, $21, $05, $04, $FF  ; NPC noTalk down b=0 spr=$21 (5,4) script=none
    db $40, $55, $05, $04, $FF  ; NPC noTalk down b=0 spr=$55 (5,4) script=none
    db $20, $5E, $05, $06, $FF  ; NPC up b=0 spr=$5E (5,6) script=none
    db $FF  ; terminator

RoomSub_StarryShrine:  ; $5D45 — mt=[$09]
    dw $FFFF  ; screen 0 (unused)
    dw StepBlk_StarryShrine_s1  ; screen 1
    dw $FFFF  ; screen 2 (unused)
    dw $FFFF  ; screen 3 (unused)
    dw StepBlk_StarryShrine_s4  ; screen 4
    dw StepBlk_StarryShrine_s5  ; screen 5
    dw $FFFF  ; screen 6 (unused)
    dw $FFFF  ; screen 7 (unused)

StepBlk_StarryShrine_s1:  ; $5D55 — RAM=$D952, 3 steps
    dw $D952  ; RAM step counter
    db $20, $29  ; step 0: layout=$20 bank=$29
    dw Interact_StarryShrine_s1  ; → interact/NPC data
    dw Exit_StarryShrine_s1  ; → exit data
    db $20, $29  ; step 1: layout=$20 bank=$29
    dw Interact_StarryShrine_s1_v1  ; → interact/NPC data
    dw Exit_StarryShrine_s1  ; → exit data
    db $20, $29  ; step 2: layout=$20 bank=$29
    dw Interact_StarryShrine_s1_v2  ; → interact/NPC data
    dw Exit_StarryShrine_s1  ; → exit data

StepBlk_StarryShrine_s4:  ; $5D69 — RAM=$D953, 3 steps
    dw $D953  ; RAM step counter
    db $21, $29  ; step 0: layout=$21 bank=$29
    dw Interact_StarryShrine_s4  ; → interact/NPC data
    dw Exit_StarryShrine_s4  ; → exit data
    db $21, $29  ; step 1: layout=$21 bank=$29
    dw Interact_StarryShrine_s4_v1  ; → interact/NPC data
    dw Exit_StarryShrine_s4  ; → exit data
    db $21, $29  ; step 2: layout=$21 bank=$29
    dw Interact_StarryShrine_s4  ; → interact/NPC data
    dw Exit_StarryShrine_s4_v1  ; → exit data

StepBlk_StarryShrine_s5:  ; $5D7D — RAM=$D954, 2 steps
    dw $D954  ; RAM step counter
    db $22, $29  ; step 0: layout=$22 bank=$29
    dw Interact_StarryShrine_s5  ; → interact/NPC data
    dw Exit_StarryShrine_s5  ; → exit data
    db $22, $29  ; step 1: layout=$22 bank=$29
    dw Interact_StarryShrine_s5_v1  ; → interact/NPC data
    dw Exit_StarryShrine_s5  ; → exit data

Interact_StarryShrine_s1:  ; $5D8B — 3 spawns, 7 NPCs
    db $8F, $FF, $05, $00, $01  ; spawn (5,0) mt$01 GreatTree
    db $8F, $FF, $07, $00, $02  ; spawn (7,0) mt$02 Bazaar
    db $8F, $FF, $08, $00, $03  ; spawn (8,0) mt$03 GateHub
    db $00, $26, $02, $01, $04  ; NPC down b=0 spr=$26 (2,1) script=$04
    db $00, $08, $05, $01, $05  ; NPC down b=0 spr=$08 (5,1) script=$05
    db $00, $0F, $06, $04, $06  ; NPC down b=0 spr=$0F (6,4) script=$06
    db $40, $E0, $05, $00, $FF  ; NPC noTalk down b=0 spr=$E0 (5,0) script=none
    db $40, $E1, $05, $00, $FF  ; NPC noTalk down b=0 spr=$E1 (5,0) script=none
    db $40, $E2, $05, $00, $FF  ; NPC noTalk down b=0 spr=$E2 (5,0) script=none
    db $40, $E3, $05, $00, $FF  ; NPC noTalk down b=0 spr=$E3 (5,0) script=none
    db $FF  ; terminator

Interact_StarryShrine_s1_v1:  ; $5DBE — 4 spawns, 7 NPCs
    db $8F, $FF, $05, $00, $01  ; spawn (5,0) mt$01 GreatTree
    db $8F, $FF, $07, $00, $02  ; spawn (7,0) mt$02 Bazaar
    db $8F, $FF, $08, $00, $03  ; spawn (8,0) mt$03 GateHub
    db $81, $FF, $05, $03, $07  ; spc_81 (5,3) mt$07 ArenaRooms
    db $00, $26, $02, $01, $04  ; NPC down b=0 spr=$26 (2,1) script=$04
    db $00, $08, $04, $03, $05  ; NPC down b=0 spr=$08 (4,3) script=$05
    db $00, $0F, $06, $04, $06  ; NPC down b=0 spr=$0F (6,4) script=$06
    db $40, $E0, $07, $00, $FF  ; NPC noTalk down b=0 spr=$E0 (7,0) script=none
    db $40, $E1, $07, $00, $FF  ; NPC noTalk down b=0 spr=$E1 (7,0) script=none
    db $40, $E2, $07, $00, $FF  ; NPC noTalk down b=0 spr=$E2 (7,0) script=none
    db $40, $E3, $07, $00, $FF  ; NPC noTalk down b=0 spr=$E3 (7,0) script=none
    db $FF  ; terminator

Interact_StarryShrine_s1_v2:  ; $5DF6 — 3 spawns, 7 NPCs
    db $8F, $FF, $05, $00, $01  ; spawn (5,0) mt$01 GreatTree
    db $8F, $FF, $07, $00, $02  ; spawn (7,0) mt$02 Bazaar
    db $8F, $FF, $08, $00, $03  ; spawn (8,0) mt$03 GateHub
    db $40, $26, $02, $02, $04  ; NPC noTalk down b=0 spr=$26 (2,2) script=$04
    db $30, $08, $06, $05, $FF  ; NPC right b=0 spr=$08 (6,5) script=none
    db $40, $E0, $02, $00, $FF  ; NPC noTalk down b=0 spr=$E0 (2,0) script=none
    db $40, $E0, $07, $00, $FF  ; NPC noTalk down b=0 spr=$E0 (7,0) script=none
    db $40, $E1, $07, $00, $FF  ; NPC noTalk down b=0 spr=$E1 (7,0) script=none
    db $40, $E2, $07, $00, $FF  ; NPC noTalk down b=0 spr=$E2 (7,0) script=none
    db $40, $E3, $07, $00, $FF  ; NPC noTalk down b=0 spr=$E3 (7,0) script=none
    db $FF  ; terminator

Interact_StarryShrine_s4:  ; $5E29 — 1 NPCs
    db $10, $08, $08, $06, $FF  ; NPC left b=0 spr=$08 (8,6) script=none
    db $FF  ; terminator

Interact_StarryShrine_s4_v1:  ; $5E2F — empty
    db $FF  ; terminator

Interact_StarryShrine_s5:  ; $5E30 — 1 spawns, 4 NPCs
    db $90, $FF, $08, $01, $0B  ; walk_exit (8,1) mt$0B Castle_0B
    db $00, $07, $03, $02, $08  ; NPC down b=0 spr=$07 (3,2) script=$08
    db $00, $0B, $02, $04, $09  ; NPC down b=0 spr=$0B (2,4) script=$09
    db $00, $11, $07, $05, $0A  ; NPC down b=0 spr=$11 (7,5) script=$0A
    db $00, $08, $04, $01, $FF  ; NPC down b=0 spr=$08 (4,1) script=none
    db $FF  ; terminator

Interact_StarryShrine_s5_v1:  ; $5E4A — 1 spawns, 3 NPCs
    db $90, $FF, $08, $01, $0B  ; walk_exit (8,1) mt$0B Castle_0B
    db $00, $07, $03, $02, $08  ; NPC down b=0 spr=$07 (3,2) script=$08
    db $00, $0B, $02, $04, $09  ; NPC down b=0 spr=$0B (2,4) script=$09
    db $00, $11, $07, $05, $0A  ; NPC down b=0 spr=$11 (7,5) script=$0A
    db $FF  ; terminator

Exit_StarryShrine_s1:  ; $5E5F — 0 exits
    db $FF  ; terminator

Exit_StarryShrine_s4:  ; $5E60 — 1 exits
    db $04, $06, $01, $00, $0C, $04, $06  ; exit (4,6)→mt$01 GreatTree  scr=12 spawn(4,6)
    db $FF  ; terminator

Exit_StarryShrine_s4_v1:  ; $5E68 — 0 exits
    db $FF  ; terminator

Exit_StarryShrine_s5:  ; $5E69 — 0 exits
    db $FF  ; terminator

RoomSub_SecretPassage:  ; $5E6A — mt=[$0A]
    dw StepBlk_SecretPassage_s0  ; screen 0
    dw StepBlk_SecretPassage_s1  ; screen 1
    dw $FFFF  ; screen 2 (unused)
    dw $FFFF  ; screen 3 (unused)

StepBlk_SecretPassage_s0:  ; $5E72 — RAM=$D955, 1 steps
    dw $D955  ; RAM step counter
    db $24, $29  ; step 0: layout=$24 bank=$29
    dw Interact_SecretPassage_s0  ; → interact/NPC data
    dw Exit_SecretPassage_s0  ; → exit data

StepBlk_SecretPassage_s1:  ; $5E7A — RAM=$D956, 1 steps
    dw $D956  ; RAM step counter
    db $25, $29  ; step 0: layout=$25 bank=$29
    dw Interact_SecretPassage_s1  ; → interact/NPC data
    dw Exit_SecretPassage_s1  ; → exit data

Interact_SecretPassage_s0:  ; $5E82 — empty
    db $FF  ; terminator

Interact_SecretPassage_s1:  ; $5E83 — empty
    db $FF  ; terminator

Exit_SecretPassage_s0:  ; $5E84 — 1 exits
    db $07, $07, $00, $00, $81, $07, $01  ; exit (7,7)→mt$00 Castle  scr=1+Y8 spawn(7,1)
    db $FF  ; terminator

Exit_SecretPassage_s1:  ; $5E8C — 1 exits
    db $03, $07, $16, $00, $80, $03, $01  ; exit (3,7)→mt$16 MedalManRoom  scr=0+Y8 spawn(3,1)
    db $FF  ; terminator

RoomSub_Gate_0C:  ; $5E94 — mt=[$0C]
    dw StepBlk_Gate_0C_s0  ; screen 0

StepBlk_Gate_0C_s0:  ; $5E96 — RAM=$D957, 1 steps
    dw $D957  ; RAM step counter
    db $27, $29  ; step 0: layout=$27 bank=$29
    dw Interact_Gate_0C_s0  ; → interact/NPC data
    dw Exit_Gate_0C_s0  ; → exit data

Interact_Gate_0C_s0:  ; $5E9E — 4 spawns, 1 NPCs
    db $8F, $FF, $01, $01, $01  ; spawn (1,1) mt$01 GreatTree
    db $8F, $FF, $02, $01, $02  ; spawn (2,1) mt$02 Bazaar
    db $8F, $FF, $03, $01, $03  ; spawn (3,1) mt$03 GateHub
    db $82, $FF, $02, $04, $04  ; spc_82 (2,4) mt$04 Farm
    db $00, $0F, $02, $03, $05  ; NPC down b=0 spr=$0F (2,3) script=$05
    db $FF  ; terminator

Exit_Gate_0C_s0:  ; $5EB8 — 1 exits
    db $02, $07, $01, $00, $8D, $02, $01  ; exit (2,7)→mt$01 GreatTree  scr=13+Y8 spawn(2,1)
    db $FF  ; terminator

RoomSub_OldManGate:  ; $5EC0 — mt=[$0D]
    dw StepBlk_OldManGate_s0  ; screen 0

StepBlk_OldManGate_s0:  ; $5EC2 — RAM=$D958, 2 steps
    dw $D958  ; RAM step counter
    db $01, $30  ; step 0: layout=$01 bank=$30
    dw Interact_OldManGate_s0  ; → interact/NPC data
    dw Exit_OldManGate_s0  ; → exit data
    db $01, $30  ; step 1: layout=$01 bank=$30
    dw Interact_OldManGate_s0_v1  ; → interact/NPC data
    dw Exit_OldManGate_s0  ; → exit data

Interact_OldManGate_s0:  ; $5ED0 — 7 spawns, 4 NPCs
    db $90, $FF, $06, $04, $08  ; walk_exit (6,4) mt$08 Gate_08
    db $90, $FF, $07, $05, $08  ; walk_exit (7,5) mt$08 Gate_08
    db $90, $FF, $08, $05, $09  ; walk_exit (8,5) mt$09 StarryShrine
    db $8F, $FF, $02, $01, $01  ; spawn (2,1) mt$01 GreatTree
    db $8F, $FF, $03, $01, $02  ; spawn (3,1) mt$02 Bazaar
    db $8F, $FF, $01, $05, $03  ; spawn (1,5) mt$03 GateHub
    db $8F, $FF, $01, $06, $04  ; spawn (1,6) mt$04 Farm
    db $00, $05, $03, $05, $05  ; NPC down b=0 spr=$05 (3,5) script=$05
    db $00, $04, $06, $03, $06  ; NPC down b=0 spr=$04 (6,3) script=$06
    db $00, $08, $08, $04, $07  ; NPC down b=0 spr=$08 (8,4) script=$07
    db $00, $4D, $08, $02, $FF  ; NPC down b=0 spr=$4D (8,2) script=none
    db $FF  ; terminator

Interact_OldManGate_s0_v1:  ; $5F08 — 7 spawns, 3 NPCs
    db $90, $FF, $06, $04, $08  ; walk_exit (6,4) mt$08 Gate_08
    db $90, $FF, $07, $05, $08  ; walk_exit (7,5) mt$08 Gate_08
    db $90, $FF, $08, $05, $09  ; walk_exit (8,5) mt$09 StarryShrine
    db $8F, $FF, $02, $01, $01  ; spawn (2,1) mt$01 GreatTree
    db $8F, $FF, $03, $01, $02  ; spawn (3,1) mt$02 Bazaar
    db $8F, $FF, $01, $05, $03  ; spawn (1,5) mt$03 GateHub
    db $8F, $FF, $01, $06, $04  ; spawn (1,6) mt$04 Farm
    db $00, $05, $03, $05, $05  ; NPC down b=0 spr=$05 (3,5) script=$05
    db $00, $04, $06, $03, $06  ; NPC down b=0 spr=$04 (6,3) script=$06
    db $00, $08, $08, $04, $07  ; NPC down b=0 spr=$08 (8,4) script=$07
    db $FF  ; terminator

Exit_OldManGate_s0:  ; $5F3B — 2 exits
    db $05, $07, $01, $00, $8C, $05, $01  ; exit (5,7)→mt$01 GreatTree  scr=12+Y8 spawn(5,1)
    db $08, $02, $1E, $01, $00, $00, $00  ; exit (8,2)→mt$1E Room_1E gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_Room_0F:  ; $5F4A — mt=[$0F]
    dw StepBlk_Room_0F_s0  ; screen 0

StepBlk_Room_0F_s0:  ; $5F4C — RAM=$D959, 1 steps
    dw $D959  ; RAM step counter
    db $03, $30  ; step 0: layout=$03 bank=$30
    dw Interact_Room_0F_s0  ; → interact/NPC data
    dw Exit_Room_0F_s0  ; → exit data

Interact_Room_0F_s0:  ; $5F54 — 2 spawns, 2 NPCs
    db $8F, $FF, $05, $03, $01  ; spawn (5,3) mt$01 GreatTree
    db $8F, $FF, $03, $05, $02  ; spawn (3,5) mt$02 Bazaar
    db $00, $09, $05, $02, $01  ; NPC down b=0 spr=$09 (5,2) script=$01
    db $30, $02, $02, $05, $02  ; NPC right b=0 spr=$02 (2,5) script=$02
    db $FF  ; terminator

Exit_Room_0F_s0:  ; $5F69 — 1 exits
    db $05, $07, $01, $00, $89, $05, $01  ; exit (5,7)→mt$01 GreatTree  scr=9+Y8 spawn(5,1)
    db $FF  ; terminator

RoomSub_CopycatRoom:  ; $5F71 — mt=[$10, $17]
    dw StepBlk_CopycatRoom_s0  ; screen 0

StepBlk_CopycatRoom_s0:  ; $5F73 — RAM=$D95A, 2 steps
    dw $D95A  ; RAM step counter
    db $05, $30  ; step 0: layout=$05 bank=$30
    dw Interact_CopycatRoom_s0  ; → interact/NPC data
    dw Exit_CopycatRoom_s0  ; → exit data
    db $06, $30  ; step 1: layout=$06 bank=$30
    dw Interact_CopycatRoom_s0_v1  ; → interact/NPC data
    dw Exit_CopycatRoom_s0_v1  ; → exit data

Interact_CopycatRoom_s0:  ; $5F81 — 4 spawns, 3 NPCs
    db $8F, $FF, $02, $01, $01  ; spawn (2,1) mt$01 GreatTree
    db $8F, $FF, $03, $01, $02  ; spawn (3,1) mt$02 Bazaar
    db $8F, $FF, $04, $01, $03  ; spawn (4,1) mt$03 GateHub
    db $82, $FF, $05, $04, $04  ; spc_82 (5,4) mt$04 Farm
    db $20, $03, $05, $03, $05  ; NPC up b=0 spr=$03 (5,3) script=$05
    db $00, $0A, $04, $06, $06  ; NPC down b=0 spr=$0A (4,6) script=$06
    db $50, $21, $0A, $00, $FF  ; NPC noTalk left b=0 spr=$21 (10,0) script=none
    db $FF  ; terminator

Interact_CopycatRoom_s0_v1:  ; $5FA5 — 5 spawns, 1 NPCs
    db $90, $FF, $07, $06, $07  ; walk_exit (7,6) mt$07 ArenaRooms
    db $90, $FF, $08, $05, $07  ; walk_exit (8,5) mt$07 ArenaRooms
    db $8F, $FF, $02, $01, $01  ; spawn (2,1) mt$01 GreatTree
    db $8F, $FF, $03, $01, $02  ; spawn (3,1) mt$02 Bazaar
    db $8F, $FF, $04, $01, $03  ; spawn (4,1) mt$03 GateHub
    db $00, $0A, $04, $06, $06  ; NPC down b=0 spr=$0A (4,6) script=$06
    db $FF  ; terminator

Exit_CopycatRoom_s0:  ; $5FC4 — 1 exits
    db $04, $07, $01, $00, $8C, $04, $04  ; exit (4,7)→mt$01 GreatTree  scr=12+Y8 spawn(4,4)
    db $FF  ; terminator

Exit_CopycatRoom_s0_v1:  ; $5FCC — 2 exits
    db $04, $07, $01, $00, $8C, $04, $04  ; exit (4,7)→mt$01 GreatTree  scr=12+Y8 spawn(4,4)
    db $08, $06, $00, $00, $01, $04, $05  ; exit (8,6)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Library:  ; $5FDB — mt=[$12]
    dw StepBlk_Library_s0  ; screen 0
    dw $FFFF  ; screen 1 (unused)
    dw $FFFF  ; screen 2 (unused)
    dw $FFFF  ; screen 3 (unused)
    dw StepBlk_Library_s4  ; screen 4
    dw $FFFF  ; screen 5 (unused)
    dw $FFFF  ; screen 6 (unused)
    dw $FFFF  ; screen 7 (unused)

StepBlk_Library_s0:  ; $5FEB — RAM=$D95B, 1 steps
    dw $D95B  ; RAM step counter
    db $08, $30  ; step 0: layout=$08 bank=$30
    dw Interact_Library_s0  ; → interact/NPC data
    dw Exit_Library_s0  ; → exit data

StepBlk_Library_s4:  ; $5FF3 — RAM=$D95C, 2 steps
    dw $D95C  ; RAM step counter
    db $09, $30  ; step 0: layout=$09 bank=$30
    dw Interact_Library_s4  ; → interact/NPC data
    dw Exit_Library_s4  ; → exit data
    db $09, $30  ; step 1: layout=$09 bank=$30
    dw Interact_Library_s4_v1  ; → interact/NPC data
    dw Exit_Library_s4  ; → exit data

Interact_Library_s0:  ; $6001 — 12 spawns, 1 NPCs
    db $8F, $FF, $01, $01, $01  ; spawn (1,1) mt$01 GreatTree
    db $8F, $FF, $02, $01, $02  ; spawn (2,1) mt$02 Bazaar
    db $8F, $FF, $03, $01, $03  ; spawn (3,1) mt$03 GateHub
    db $8F, $FF, $04, $01, $04  ; spawn (4,1) mt$04 Farm
    db $8F, $FF, $07, $01, $05  ; spawn (7,1) mt$05 Stable
    db $8F, $FF, $08, $01, $06  ; spawn (8,1) mt$06 ArenaLobby
    db $8F, $FF, $02, $04, $07  ; spawn (2,4) mt$07 ArenaRooms
    db $8F, $FF, $03, $04, $08  ; spawn (3,4) mt$08 Gate_08
    db $8F, $FF, $04, $04, $09  ; spawn (4,4) mt$09 StarryShrine
    db $8F, $FF, $06, $04, $0A  ; spawn (6,4) mt$0A SecretPassage
    db $8F, $FF, $07, $04, $0B  ; spawn (7,4) mt$0B Castle_0B
    db $8F, $FF, $06, $01, $0C  ; spawn (6,1) mt$0C Gate_0C
    db $10, $02, $02, $06, $0D  ; NPC left b=0 spr=$02 (2,6) script=$0D
    db $FF  ; terminator

Interact_Library_s4:  ; $6043 — 1 spawns, 4 NPCs
    db $82, $FF, $04, $03, $0E  ; spc_82 (4,3) mt$0E Castle_0E
    db $00, $02, $04, $02, $0F  ; NPC down b=0 spr=$02 (4,2) script=$0F
    db $00, $03, $06, $03, $11  ; NPC down b=0 spr=$03 (6,3) script=$11
    db $30, $03, $01, $06, $10  ; NPC right b=0 spr=$03 (1,6) script=$10
    db $40, $54, $06, $02, $FF  ; NPC noTalk down b=0 spr=$54 (6,2) script=none
    db $FF  ; terminator

Interact_Library_s4_v1:  ; $605D — 1 spawns, 2 NPCs
    db $82, $FF, $04, $03, $0E  ; spc_82 (4,3) mt$0E Castle_0E
    db $00, $02, $04, $02, $0F  ; NPC down b=0 spr=$02 (4,2) script=$0F
    db $30, $03, $01, $06, $10  ; NPC right b=0 spr=$03 (1,6) script=$10
    db $FF  ; terminator

Exit_Library_s0:  ; $606D — 0 exits
    db $FF  ; terminator

Exit_Library_s4:  ; $606E — 2 exits
    db $05, $07, $01, $00, $88, $05, $03  ; exit (5,7)→mt$01 GreatTree  scr=8+Y8 spawn(5,3)
    db $06, $01, $13, $00, $00, $06, $07  ; exit (6,1)→mt$13 Room_13  scr=0 spawn(6,7)
    db $FF  ; terminator

RoomSub_Room_13:  ; $607D — mt=[$13]
    dw StepBlk_Room_13_s0  ; screen 0

StepBlk_Room_13_s0:  ; $607F — RAM=$D95D, 2 steps
    dw $D95D  ; RAM step counter
    db $0B, $30  ; step 0: layout=$0B bank=$30
    dw Interact_Room_13_s0  ; → interact/NPC data
    dw Exit_Room_13_s0  ; → exit data
    db $0B, $30  ; step 1: layout=$0B bank=$30
    dw Interact_Room_13_s0_v1  ; → interact/NPC data
    dw Exit_Room_13_s0  ; → exit data

Interact_Room_13_s0:  ; $608D — 14 spawns, 2 NPCs
    db $8F, $FF, $01, $01, $01  ; spawn (1,1) mt$01 GreatTree
    db $8F, $FF, $02, $01, $02  ; spawn (2,1) mt$02 Bazaar
    db $8F, $FF, $03, $01, $03  ; spawn (3,1) mt$03 GateHub
    db $8F, $FF, $04, $01, $04  ; spawn (4,1) mt$04 Farm
    db $8F, $FF, $05, $01, $05  ; spawn (5,1) mt$05 Stable
    db $8F, $FF, $06, $01, $06  ; spawn (6,1) mt$06 ArenaLobby
    db $8F, $FF, $07, $01, $07  ; spawn (7,1) mt$07 ArenaRooms
    db $8F, $FF, $08, $01, $08  ; spawn (8,1) mt$08 Gate_08
    db $8F, $FF, $01, $04, $09  ; spawn (1,4) mt$09 StarryShrine
    db $8F, $FF, $02, $04, $0A  ; spawn (2,4) mt$0A SecretPassage
    db $8F, $FF, $03, $04, $0B  ; spawn (3,4) mt$0B Castle_0B
    db $8F, $FF, $04, $04, $0C  ; spawn (4,4) mt$0C Gate_0C
    db $8F, $FF, $07, $04, $0D  ; spawn (7,4) mt$0D OldManGate
    db $8F, $FF, $08, $04, $0E  ; spawn (8,4) mt$0E Castle_0E
    db $10, $03, $06, $04, $0F  ; NPC left b=0 spr=$03 (6,4) script=$0F
    db $00, $4D, $01, $06, $FF  ; NPC down b=0 spr=$4D (1,6) script=none
    db $FF  ; terminator

Interact_Room_13_s0_v1:  ; $60DE — 14 spawns, 1 NPCs
    db $8F, $FF, $01, $01, $01  ; spawn (1,1) mt$01 GreatTree
    db $8F, $FF, $02, $01, $02  ; spawn (2,1) mt$02 Bazaar
    db $8F, $FF, $03, $01, $03  ; spawn (3,1) mt$03 GateHub
    db $8F, $FF, $04, $01, $04  ; spawn (4,1) mt$04 Farm
    db $8F, $FF, $05, $01, $05  ; spawn (5,1) mt$05 Stable
    db $8F, $FF, $06, $01, $06  ; spawn (6,1) mt$06 ArenaLobby
    db $8F, $FF, $07, $01, $07  ; spawn (7,1) mt$07 ArenaRooms
    db $8F, $FF, $08, $01, $08  ; spawn (8,1) mt$08 Gate_08
    db $8F, $FF, $01, $04, $09  ; spawn (1,4) mt$09 StarryShrine
    db $8F, $FF, $02, $04, $0A  ; spawn (2,4) mt$0A SecretPassage
    db $8F, $FF, $03, $04, $0B  ; spawn (3,4) mt$0B Castle_0B
    db $8F, $FF, $04, $04, $0C  ; spawn (4,4) mt$0C Gate_0C
    db $8F, $FF, $07, $04, $0D  ; spawn (7,4) mt$0D OldManGate
    db $8F, $FF, $08, $04, $0E  ; spawn (8,4) mt$0E Castle_0E
    db $10, $03, $06, $04, $0F  ; NPC left b=0 spr=$03 (6,4) script=$0F
    db $FF  ; terminator

Exit_Room_13_s0:  ; $612A — 2 exits
    db $06, $07, $12, $00, $84, $06, $01  ; exit (6,7)→mt$12 Library  scr=4+Y8 spawn(6,1)
    db $01, $06, $14, $01, $00, $00, $00  ; exit (1,6)→mt$14 Castle_14 gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_MedalManRoom:  ; $6139 — mt=[$16]
    dw StepBlk_MedalManRoom_s0  ; screen 0

StepBlk_MedalManRoom_s0:  ; $613B — RAM=$D95E, 6 steps
    dw $D95E  ; RAM step counter
    db $0D, $30  ; step 0: layout=$0D bank=$30
    dw Interact_MedalManRoom_s0  ; → interact/NPC data
    dw Exit_MedalManRoom_s0  ; → exit data
    db $0E, $30  ; step 1: layout=$0E bank=$30
    dw Interact_MedalManRoom_s0_v1  ; → interact/NPC data
    dw Exit_MedalManRoom_s0_v1  ; → exit data
    db $0E, $30  ; step 2: layout=$0E bank=$30
    dw Interact_MedalManRoom_s0_v2  ; → interact/NPC data
    dw Exit_MedalManRoom_s0_v1  ; → exit data
    db $0D, $30  ; step 3: layout=$0D bank=$30
    dw Interact_MedalManRoom_s0_v3  ; → interact/NPC data
    dw Exit_MedalManRoom_s0_v2  ; → exit data
    db $0E, $30  ; step 4: layout=$0E bank=$30
    dw Interact_MedalManRoom_s0_v4  ; → interact/NPC data
    dw Exit_MedalManRoom_s0_v1  ; → exit data
    db $0E, $30  ; step 5: layout=$0E bank=$30
    dw Interact_MedalManRoom_s0_v5  ; → interact/NPC data
    dw Exit_MedalManRoom_s0_v1  ; → exit data

Interact_MedalManRoom_s0:  ; $6161 — 1 spawns, 2 NPCs
    db $82, $FF, $02, $04, $01  ; spc_82 (2,4) mt$01 GreatTree
    db $00, $13, $02, $03, $02  ; NPC down b=0 spr=$13 (2,3) script=$02
    db $00, $4C, $03, $02, $03  ; NPC down b=0 spr=$4C (3,2) script=$03
    db $FF  ; terminator

Interact_MedalManRoom_s0_v1:  ; $6171 — 1 spawns, 3 NPCs
    db $82, $FF, $02, $04, $01  ; spc_82 (2,4) mt$01 GreatTree
    db $00, $13, $02, $03, $02  ; NPC down b=0 spr=$13 (2,3) script=$02
    db $00, $4C, $03, $02, $03  ; NPC down b=0 spr=$4C (3,2) script=$03
    db $00, $4D, $01, $06, $FF  ; NPC down b=0 spr=$4D (1,6) script=none
    db $FF  ; terminator

Interact_MedalManRoom_s0_v2:  ; $6186 — 1 spawns, 2 NPCs
    db $82, $FF, $02, $04, $01  ; spc_82 (2,4) mt$01 GreatTree
    db $00, $13, $02, $03, $02  ; NPC down b=0 spr=$13 (2,3) script=$02
    db $00, $4C, $03, $02, $03  ; NPC down b=0 spr=$4C (3,2) script=$03
    db $FF  ; terminator

Interact_MedalManRoom_s0_v3:  ; $6196 — 1 spawns, 2 NPCs
    db $82, $FF, $02, $04, $01  ; spc_82 (2,4) mt$01 GreatTree
    db $00, $13, $02, $03, $02  ; NPC down b=0 spr=$13 (2,3) script=$02
    db $00, $4C, $01, $02, $03  ; NPC down b=0 spr=$4C (1,2) script=$03
    db $FF  ; terminator

Interact_MedalManRoom_s0_v4:  ; $61A6 — 1 spawns, 3 NPCs
    db $82, $FF, $02, $04, $01  ; spc_82 (2,4) mt$01 GreatTree
    db $00, $13, $02, $03, $02  ; NPC down b=0 spr=$13 (2,3) script=$02
    db $00, $4C, $01, $02, $03  ; NPC down b=0 spr=$4C (1,2) script=$03
    db $00, $4D, $01, $06, $FF  ; NPC down b=0 spr=$4D (1,6) script=none
    db $FF  ; terminator

Interact_MedalManRoom_s0_v5:  ; $61BB — 1 spawns, 2 NPCs
    db $82, $FF, $02, $04, $01  ; spc_82 (2,4) mt$01 GreatTree
    db $00, $13, $02, $03, $02  ; NPC down b=0 spr=$13 (2,3) script=$02
    db $00, $4C, $01, $02, $03  ; NPC down b=0 spr=$4C (1,2) script=$03
    db $FF  ; terminator

Exit_MedalManRoom_s0:  ; $61CB — 1 exits
    db $03, $07, $01, $00, $81, $03, $02  ; exit (3,7)→mt$01 GreatTree  scr=1+Y8 spawn(3,2)
    db $FF  ; terminator

Exit_MedalManRoom_s0_v1:  ; $61D3 — 3 exits
    db $03, $07, $01, $00, $81, $03, $02  ; exit (3,7)→mt$01 GreatTree  scr=1+Y8 spawn(3,2)
    db $03, $01, $0A, $00, $01, $03, $07  ; exit (3,1)→mt$0A SecretPassage  scr=1 spawn(3,7)
    db $01, $06, $11, $01, $00, $00, $00  ; exit (1,6)→mt$11 Castle_11 gate scr=0 spawn(0,0)
    db $FF  ; terminator

Exit_MedalManRoom_s0_v2:  ; $61E9 — 2 exits
    db $03, $07, $01, $00, $81, $03, $02  ; exit (3,7)→mt$01 GreatTree  scr=1+Y8 spawn(3,2)
    db $03, $01, $0A, $00, $01, $03, $07  ; exit (3,1)→mt$0A SecretPassage  scr=1 spawn(3,7)
    db $FF  ; terminator

RoomSub_Well:  ; $61F8 — mt=[$18]
    dw StepBlk_Well_s0  ; screen 0
    dw $FFFF  ; screen 1 (unused)
    dw $FFFF  ; screen 2 (unused)
    dw $FFFF  ; screen 3 (unused)
    dw StepBlk_Well_s4  ; screen 4
    dw $FFFF  ; screen 5 (unused)
    dw $FFFF  ; screen 6 (unused)
    dw $FFFF  ; screen 7 (unused)

StepBlk_Well_s0:  ; $6208 — RAM=$D95F, 1 steps
    dw $D95F  ; RAM step counter
    db $10, $30  ; step 0: layout=$10 bank=$30
    dw Interact_Well_s0  ; → interact/NPC data
    dw Exit_Well_s0  ; → exit data

StepBlk_Well_s4:  ; $6210 — RAM=$D960, 3 steps
    dw $D960  ; RAM step counter
    db $11, $30  ; step 0: layout=$11 bank=$30
    dw Interact_Well_s4  ; → interact/NPC data
    dw Exit_Well_s4  ; → exit data
    db $12, $30  ; step 1: layout=$12 bank=$30
    dw Interact_Well_s4_v1  ; → interact/NPC data
    dw Exit_Well_s4_v1  ; → exit data
    db $12, $30  ; step 2: layout=$12 bank=$30
    dw Interact_Well_s4_v2  ; → interact/NPC data
    dw Exit_Well_s4_v1  ; → exit data

Interact_Well_s0:  ; $6224 — empty
    db $FF  ; terminator

Interact_Well_s4:  ; $6225 — 9 spawns, 2 NPCs
    db $8F, $FF, $01, $01, $01  ; spawn (1,1) mt$01 GreatTree
    db $8F, $FF, $07, $01, $02  ; spawn (7,1) mt$02 Bazaar
    db $8F, $FF, $08, $01, $03  ; spawn (8,1) mt$03 GateHub
    db $8F, $FF, $02, $05, $04  ; spawn (2,5) mt$04 Farm
    db $8F, $FF, $03, $05, $04  ; spawn (3,5) mt$04 Farm
    db $8F, $FF, $02, $06, $04  ; spawn (2,6) mt$04 Farm
    db $8F, $FF, $03, $06, $04  ; spawn (3,6) mt$04 Farm
    db $8F, $FF, $01, $06, $05  ; spawn (1,6) mt$05 Stable
    db $82, $FF, $06, $04, $06  ; spc_82 (6,4) mt$06 ArenaLobby
    db $07, $43, $06, $03, $07  ; NPC down b=7 spr=$43 (6,3) script=$07
    db $02, $07, $06, $05, $08  ; NPC down b=2 spr=$07 (6,5) script=$08
    db $FF  ; terminator

Interact_Well_s4_v1:  ; $625D — 5 spawns, 3 NPCs
    db $8F, $FF, $01, $01, $01  ; spawn (1,1) mt$01 GreatTree
    db $8F, $FF, $07, $01, $02  ; spawn (7,1) mt$02 Bazaar
    db $8F, $FF, $08, $01, $03  ; spawn (8,1) mt$03 GateHub
    db $8F, $FF, $01, $06, $05  ; spawn (1,6) mt$05 Stable
    db $82, $FF, $06, $04, $06  ; spc_82 (6,4) mt$06 ArenaLobby
    db $07, $43, $06, $03, $07  ; NPC down b=7 spr=$43 (6,3) script=$07
    db $02, $07, $06, $05, $08  ; NPC down b=2 spr=$07 (6,5) script=$08
    db $00, $4D, $02, $06, $FF  ; NPC down b=0 spr=$4D (2,6) script=none
    db $FF  ; terminator

Interact_Well_s4_v2:  ; $6286 — 5 spawns, 2 NPCs
    db $8F, $FF, $01, $01, $01  ; spawn (1,1) mt$01 GreatTree
    db $8F, $FF, $07, $01, $02  ; spawn (7,1) mt$02 Bazaar
    db $8F, $FF, $08, $01, $03  ; spawn (8,1) mt$03 GateHub
    db $8F, $FF, $01, $06, $05  ; spawn (1,6) mt$05 Stable
    db $82, $FF, $06, $04, $06  ; spc_82 (6,4) mt$06 ArenaLobby
    db $07, $43, $06, $03, $07  ; NPC down b=7 spr=$43 (6,3) script=$07
    db $02, $07, $06, $05, $08  ; NPC down b=2 spr=$07 (6,5) script=$08
    db $FF  ; terminator

Exit_Well_s0:  ; $62AA — 1 exits
    db $04, $00, $01, $00, $08, $04, $05  ; exit (4,0)→mt$01 GreatTree  scr=8 spawn(4,5)
    db $FF  ; terminator

Exit_Well_s4:  ; $62B2 — 0 exits
    db $FF  ; terminator

Exit_Well_s4_v1:  ; $62B3 — 1 exits
    db $02, $06, $08, $01, $00, $00, $00  ; exit (2,6)→mt$08 Gate_08 gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_Room_19:  ; $62BB — mt=[$19]
    dw StepBlk_Room_19_s0  ; screen 0

StepBlk_Room_19_s0:  ; $62BD — RAM=$D961, 1 steps
    dw $D961  ; RAM step counter
    db $14, $30  ; step 0: layout=$14 bank=$30
    dw Interact_Room_19_s0  ; → interact/NPC data
    dw Exit_Room_19_s0  ; → exit data

Interact_Room_19_s0:  ; $62C5 — 3 spawns, 1 NPCs
    db $90, $FF, $01, $04, $02  ; walk_exit (1,4) mt$02 Bazaar
    db $90, $FF, $02, $04, $03  ; walk_exit (2,4) mt$03 GateHub
    db $90, $FF, $03, $04, $04  ; walk_exit (3,4) mt$04 Farm
    db $06, $1F, $02, $02, $01  ; NPC down b=6 spr=$1F (2,2) script=$01
    db $FF  ; terminator

Exit_Room_19_s0:  ; $62DA — 1 exits
    db $01, $07, $01, $00, $8D, $01, $04  ; exit (1,7)→mt$01 GreatTree  scr=13+Y8 spawn(1,4)
    db $FF  ; terminator

RoomSub_Room_1A:  ; $62E2 — mt=[$1A]
    dw StepBlk_Room_1A_s0  ; screen 0

StepBlk_Room_1A_s0:  ; $62E4 — RAM=$D962, 1 steps
    dw $D962  ; RAM step counter
    db $16, $30  ; step 0: layout=$16 bank=$30
    dw Interact_Room_1A_s0  ; → interact/NPC data
    dw Exit_Room_1A_s0  ; → exit data

Interact_Room_1A_s0:  ; $62EC — 3 spawns, 3 NPCs
    db $90, $FF, $03, $04, $04  ; walk_exit (3,4) mt$04 Farm
    db $90, $FF, $04, $04, $05  ; walk_exit (4,4) mt$05 Stable
    db $90, $FF, $05, $04, $06  ; walk_exit (5,4) mt$06 ArenaLobby
    db $06, $1F, $04, $02, $01  ; NPC down b=6 spr=$1F (4,2) script=$01
    db $00, $11, $05, $05, $02  ; NPC down b=0 spr=$11 (5,5) script=$02
    db $08, $3B, $02, $06, $03  ; NPC down b=8 spr=$3B (2,6) script=$03
    db $FF  ; terminator

Exit_Room_1A_s0:  ; $630B — 1 exits
    db $04, $07, $01, $00, $8D, $04, $06  ; exit (4,7)→mt$01 GreatTree  scr=13+Y8 spawn(4,6)
    db $FF  ; terminator

RoomSub_Room_1B:  ; $6313 — mt=[$1B]
    dw StepBlk_Room_1B_s0  ; screen 0

StepBlk_Room_1B_s0:  ; $6315 — RAM=$D963, 3 steps
    dw $D963  ; RAM step counter
    db $18, $30  ; step 0: layout=$18 bank=$30
    dw Interact_Room_1B_s0  ; → interact/NPC data
    dw Exit_Room_1B_s0  ; → exit data
    db $18, $30  ; step 1: layout=$18 bank=$30
    dw Interact_Room_1B_s0_v1  ; → interact/NPC data
    dw Exit_Room_1B_s0  ; → exit data
    db $18, $30  ; step 2: layout=$18 bank=$30
    dw Interact_Room_1B_s0_v2  ; → interact/NPC data
    dw Exit_Room_1B_s0  ; → exit data

Interact_Room_1B_s0:  ; $6329 — 2 NPCs
    db $00, $22, $04, $02, $01  ; NPC down b=0 spr=$22 (4,2) script=$01
    db $00, $FF, $05, $02, $01  ; NPC down b=0 spr=$FF (5,2) script=$01
    db $FF  ; terminator

Interact_Room_1B_s0_v1:  ; $6334 — 2 NPCs
    db $00, $24, $04, $02, $02  ; NPC down b=0 spr=$24 (4,2) script=$02
    db $00, $FF, $05, $02, $02  ; NPC down b=0 spr=$FF (5,2) script=$02
    db $FF  ; terminator

Interact_Room_1B_s0_v2:  ; $633F — 3 NPCs
    db $00, $3B, $03, $03, $03  ; NPC down b=0 spr=$3B (3,3) script=$03
    db $00, $24, $04, $02, $02  ; NPC down b=0 spr=$24 (4,2) script=$02
    db $00, $FF, $05, $02, $02  ; NPC down b=0 spr=$FF (5,2) script=$02
    db $FF  ; terminator

Exit_Room_1B_s0:  ; $634F — 2 exits
    db $04, $07, $05, $00, $80, $04, $00  ; exit (4,7)→mt$05 Stable  scr=0+Y8 spawn(4,0)
    db $05, $07, $05, $00, $80, $05, $00  ; exit (5,7)→mt$05 Stable  scr=0+Y8 spawn(5,0)
    db $FF  ; terminator

RoomSub_Room_1C:  ; $635E — mt=[$1C]
    dw StepBlk_Room_1C_s0  ; screen 0

StepBlk_Room_1C_s0:  ; $6360 — RAM=$D964, 2 steps
    dw $D964  ; RAM step counter
    db $1A, $30  ; step 0: layout=$1A bank=$30
    dw Interact_Room_1C_s0  ; → interact/NPC data
    dw Exit_Room_1C_s0  ; → exit data
    db $1A, $30  ; step 1: layout=$1A bank=$30
    dw Interact_Room_1C_s0_v1  ; → interact/NPC data
    dw Exit_Room_1C_s0  ; → exit data

Interact_Room_1C_s0:  ; $636E — 4 spawns, 3 NPCs
    db $8F, $FF, $04, $02, $01  ; spawn (4,2) mt$01 GreatTree
    db $8F, $FF, $05, $02, $01  ; spawn (5,2) mt$01 GreatTree
    db $8F, $FF, $01, $04, $02  ; spawn (1,4) mt$02 Bazaar
    db $8F, $FF, $08, $04, $03  ; spawn (8,4) mt$03 GateHub
    db $40, $41, $04, $02, $01  ; NPC noTalk down b=0 spr=$41 (4,2) script=$01
    db $40, $41, $05, $02, $01  ; NPC noTalk down b=0 spr=$41 (5,2) script=$01
    db $02, $40, $03, $05, $04  ; NPC down b=2 spr=$40 (3,5) script=$04
    db $FF  ; terminator

Interact_Room_1C_s0_v1:  ; $6392 — 4 spawns, 3 NPCs
    db $8F, $FF, $04, $02, $05  ; spawn (4,2) mt$05 Stable
    db $8F, $FF, $05, $02, $05  ; spawn (5,2) mt$05 Stable
    db $8F, $FF, $01, $04, $02  ; spawn (1,4) mt$02 Bazaar
    db $8F, $FF, $08, $04, $03  ; spawn (8,4) mt$03 GateHub
    db $40, $2B, $04, $02, $05  ; NPC noTalk down b=0 spr=$2B (4,2) script=$05
    db $40, $2B, $05, $02, $05  ; NPC noTalk down b=0 spr=$2B (5,2) script=$05
    db $02, $1E, $03, $05, $06  ; NPC down b=2 spr=$1E (3,5) script=$06
    db $FF  ; terminator

Exit_Room_1C_s0:  ; $63B6 — 2 exits
    db $04, $07, $05, $00, $81, $04, $00  ; exit (4,7)→mt$05 Stable  scr=1+Y8 spawn(4,0)
    db $05, $07, $05, $00, $81, $05, $00  ; exit (5,7)→mt$05 Stable  scr=1+Y8 spawn(5,0)
    db $FF  ; terminator

RoomSub_Room_1D:  ; $63C5 — mt=[$1D]
    dw StepBlk_Room_1D_s0  ; screen 0

StepBlk_Room_1D_s0:  ; $63C7 — RAM=$D965, 1 steps
    dw $D965  ; RAM step counter
    db $1C, $30  ; step 0: layout=$1C bank=$30
    dw Interact_Room_1D_s0  ; → interact/NPC data
    dw Exit_Room_1D_s0  ; → exit data

Interact_Room_1D_s0:  ; $63CF — 3 spawns, 3 NPCs
    db $8F, $FF, $04, $01, $01  ; spawn (4,1) mt$01 GreatTree
    db $8F, $FF, $06, $01, $02  ; spawn (6,1) mt$02 Bazaar
    db $8F, $FF, $05, $03, $03  ; spawn (5,3) mt$03 GateHub
    db $07, $11, $05, $02, $04  ; NPC down b=7 spr=$11 (5,2) script=$04
    db $27, $00, $03, $05, $05  ; NPC up b=7 spr=$00 (3,5) script=$05
    db $20, $02, $08, $06, $06  ; NPC up b=0 spr=$02 (8,6) script=$06
    db $FF  ; terminator

Exit_Room_1D_s0:  ; $63EE — 1 exits
    db $05, $07, $07, $00, $80, $05, $01  ; exit (5,7)→mt$07 ArenaRooms  scr=0+Y8 spawn(5,1)
    db $FF  ; terminator

RoomSub_Room_1E:  ; $63F6 — mt=[$1E]
    dw StepBlk_Room_1E_s0  ; screen 0

StepBlk_Room_1E_s0:  ; $63F8 — RAM=$D966, 2 steps
    dw $D966  ; RAM step counter
    db $1E, $30  ; step 0: layout=$1E bank=$30
    dw Interact_Room_1E_s0  ; → interact/NPC data
    dw Exit_Room_1E_s0  ; → exit data
    db $1E, $30  ; step 1: layout=$1E bank=$30
    dw Interact_Room_1E_s0_v1  ; → interact/NPC data
    dw Exit_Room_1E_s0  ; → exit data

Interact_Room_1E_s0:  ; $6406 — 1 spawns, 3 NPCs
    db $8F, $FF, $05, $03, $01  ; spawn (5,3) mt$01 GreatTree
    db $00, $05, $05, $02, $01  ; NPC down b=0 spr=$05 (5,2) script=$01
    db $37, $0F, $02, $03, $02  ; NPC right b=7 spr=$0F (2,3) script=$02
    db $20, $0B, $06, $04, $03  ; NPC up b=0 spr=$0B (6,4) script=$03
    db $FF  ; terminator

Interact_Room_1E_s0_v1:  ; $641B — 1 spawns, 3 NPCs
    db $8F, $FF, $05, $03, $01  ; spawn (5,3) mt$01 GreatTree
    db $00, $05, $05, $02, $01  ; NPC down b=0 spr=$05 (5,2) script=$01
    db $37, $0F, $02, $03, $02  ; NPC right b=7 spr=$0F (2,3) script=$02
    db $20, $0C, $06, $04, $04  ; NPC up b=0 spr=$0C (6,4) script=$04
    db $FF  ; terminator

Exit_Room_1E_s0:  ; $6430 — 1 exits
    db $05, $07, $07, $00, $82, $05, $01  ; exit (5,7)→mt$07 ArenaRooms  scr=2+Y8 spawn(5,1)
    db $FF  ; terminator

RoomSub_Room_1F:  ; $6438 — mt=[$1F]
    dw StepBlk_Room_1F_s0  ; screen 0

StepBlk_Room_1F_s0:  ; $643A — RAM=$D967, 3 steps
    dw $D967  ; RAM step counter
    db $01, $2D  ; step 0: layout=$01 bank=$2D
    dw Interact_Room_1F_s0  ; → interact/NPC data
    dw Exit_Room_1F_s0  ; → exit data
    db $01, $2D  ; step 1: layout=$01 bank=$2D
    dw Interact_Room_1F_s0_v1  ; → interact/NPC data
    dw Exit_Room_1F_s0  ; → exit data
    db $01, $2D  ; step 2: layout=$01 bank=$2D
    dw Interact_Room_1F_s0_v2  ; → interact/NPC data
    dw Exit_Room_1F_s0  ; → exit data

Interact_Room_1F_s0:  ; $644E — 2 spawns, 3 NPCs
    db $8F, $FF, $02, $06, $01  ; spawn (2,6) mt$01 GreatTree
    db $00, $0E, $05, $06, $02  ; NPC down b=0 spr=$0E (5,6) script=$02
    db $00, $11, $07, $03, $03  ; NPC down b=0 spr=$11 (7,3) script=$03
    db $00, $02, $04, $04, $04  ; NPC down b=0 spr=$02 (4,4) script=$04
    db $81, $FF, $05, $04, $07  ; spc_81 (5,4) mt$07 ArenaRooms
    db $FF  ; terminator

Interact_Room_1F_s0_v1:  ; $6468 — 2 spawns, 3 NPCs
    db $8F, $FF, $02, $06, $01  ; spawn (2,6) mt$01 GreatTree
    db $00, $0E, $05, $06, $02  ; NPC down b=0 spr=$0E (5,6) script=$02
    db $00, $11, $07, $03, $03  ; NPC down b=0 spr=$11 (7,3) script=$03
    db $00, $13, $04, $04, $05  ; NPC down b=0 spr=$13 (4,4) script=$05
    db $81, $FF, $05, $04, $08  ; spc_81 (5,4) mt$08 Gate_08
    db $FF  ; terminator

Interact_Room_1F_s0_v2:  ; $6482 — 2 spawns, 3 NPCs
    db $8F, $FF, $02, $06, $01  ; spawn (2,6) mt$01 GreatTree
    db $00, $0E, $05, $06, $02  ; NPC down b=0 spr=$0E (5,6) script=$02
    db $00, $11, $07, $03, $03  ; NPC down b=0 spr=$11 (7,3) script=$03
    db $00, $14, $04, $04, $06  ; NPC down b=0 spr=$14 (4,4) script=$06
    db $81, $FF, $05, $04, $09  ; spc_81 (5,4) mt$09 StarryShrine
    db $FF  ; terminator

Exit_Room_1F_s0:  ; $649C — 1 exits
    db $05, $02, $07, $00, $01, $05, $02  ; exit (5,2)→mt$07 ArenaRooms  scr=1 spawn(5,2)
    db $FF  ; terminator

RoomSub_RoomOfBeginning:  ; $64A4 — mt=[$23]
    dw StepBlk_RoomOfBeginning_s0  ; screen 0

StepBlk_RoomOfBeginning_s0:  ; $64A6 — RAM=$D968, 2 steps
    dw $D968  ; RAM step counter
    db $03, $2D  ; step 0: layout=$03 bank=$2D
    dw Interact_RoomOfBeginning_s0  ; → interact/NPC data
    dw Exit_RoomOfBeginning_s0  ; → exit data
    db $03, $2D  ; step 1: layout=$03 bank=$2D
    dw Interact_RoomOfBeginning_s0_v1  ; → interact/NPC data
    dw Exit_RoomOfBeginning_s0  ; → exit data

Interact_RoomOfBeginning_s0:  ; $64B4 — 2 NPCs
    db $00, $0B, $08, $05, $01  ; NPC down b=0 spr=$0B (8,5) script=$01
    db $00, $4D, $08, $02, $FF  ; NPC down b=0 spr=$4D (8,2) script=none
    db $FF  ; terminator

Interact_RoomOfBeginning_s0_v1:  ; $64BF — 1 NPCs
    db $00, $0B, $08, $05, $01  ; NPC down b=0 spr=$0B (8,5) script=$01
    db $FF  ; terminator

Exit_RoomOfBeginning_s0:  ; $64C5 — 3 exits
    db $07, $07, $03, $00, $81, $04, $01  ; exit (7,7)→mt$03 GateHub  scr=1+Y8 spawn(4,1)
    db $08, $07, $03, $00, $81, $05, $01  ; exit (8,7)→mt$03 GateHub  scr=1+Y8 spawn(5,1)
    db $08, $02, $00, $01, $00, $00, $00  ; exit (8,2)→mt$00 Castle gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_RoomOfVillagerTalisman:  ; $64DB — mt=[$24]
    dw StepBlk_RoomOfVillagerTalisman_s0  ; screen 0

StepBlk_RoomOfVillagerTalisman_s0:  ; $64DD — RAM=$D969, 4 steps
    dw $D969  ; RAM step counter
    db $05, $2D  ; step 0: layout=$05 bank=$2D
    dw Interact_RoomOfVillagerTalisman_s0  ; → interact/NPC data
    dw Exit_RoomOfVillagerTalisman_s0  ; → exit data
    db $05, $2D  ; step 1: layout=$05 bank=$2D
    dw Interact_RoomOfVillagerTalisman_s0_v1  ; → interact/NPC data
    dw Exit_RoomOfVillagerTalisman_s0  ; → exit data
    db $05, $2D  ; step 2: layout=$05 bank=$2D
    dw Interact_RoomOfVillagerTalisman_s0_v2  ; → interact/NPC data
    dw Exit_RoomOfVillagerTalisman_s0  ; → exit data
    db $05, $2D  ; step 3: layout=$05 bank=$2D
    dw Interact_RoomOfVillagerTalisman_s0_v3  ; → interact/NPC data
    dw Exit_RoomOfVillagerTalisman_s0  ; → exit data

Interact_RoomOfVillagerTalisman_s0:  ; $64F7 — 3 NPCs
    db $10, $0B, $07, $05, $01  ; NPC left b=0 spr=$0B (7,5) script=$01
    db $00, $4D, $02, $02, $FF  ; NPC down b=0 spr=$4D (2,2) script=none
    db $00, $4D, $02, $06, $FF  ; NPC down b=0 spr=$4D (2,6) script=none
    db $FF  ; terminator

Interact_RoomOfVillagerTalisman_s0_v1:  ; $6507 — 2 NPCs
    db $10, $0B, $07, $05, $01  ; NPC left b=0 spr=$0B (7,5) script=$01
    db $00, $4D, $02, $06, $FF  ; NPC down b=0 spr=$4D (2,6) script=none
    db $FF  ; terminator

Interact_RoomOfVillagerTalisman_s0_v2:  ; $6512 — 2 NPCs
    db $10, $0B, $07, $05, $01  ; NPC left b=0 spr=$0B (7,5) script=$01
    db $00, $4D, $02, $02, $FF  ; NPC down b=0 spr=$4D (2,2) script=none
    db $FF  ; terminator

Interact_RoomOfVillagerTalisman_s0_v3:  ; $651D — 1 NPCs
    db $10, $0B, $07, $05, $01  ; NPC left b=0 spr=$0B (7,5) script=$01
    db $FF  ; terminator

Exit_RoomOfVillagerTalisman_s0:  ; $6523 — 3 exits
    db $06, $07, $03, $00, $81, $02, $02  ; exit (6,7)→mt$03 GateHub  scr=1+Y8 spawn(2,2)
    db $02, $02, $01, $01, $00, $00, $00  ; exit (2,2)→mt$01 GreatTree gate scr=0 spawn(0,0)
    db $02, $06, $02, $01, $00, $00, $00  ; exit (2,6)→mt$02 Bazaar gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_RoomOfMemoriesBewilder:  ; $6539 — mt=[$25]
    dw StepBlk_RoomOfMemoriesBewilder_s0  ; screen 0

StepBlk_RoomOfMemoriesBewilder_s0:  ; $653B — RAM=$D96A, 4 steps
    dw $D96A  ; RAM step counter
    db $07, $2D  ; step 0: layout=$07 bank=$2D
    dw Interact_RoomOfMemoriesBewilder_s0  ; → interact/NPC data
    dw Exit_RoomOfMemoriesBewilder_s0  ; → exit data
    db $07, $2D  ; step 1: layout=$07 bank=$2D
    dw Interact_RoomOfMemoriesBewilder_s0_v1  ; → interact/NPC data
    dw Exit_RoomOfMemoriesBewilder_s0  ; → exit data
    db $07, $2D  ; step 2: layout=$07 bank=$2D
    dw Interact_RoomOfMemoriesBewilder_s0_v2  ; → interact/NPC data
    dw Exit_RoomOfMemoriesBewilder_s0  ; → exit data
    db $07, $2D  ; step 3: layout=$07 bank=$2D
    dw Interact_RoomOfMemoriesBewilder_s0_v3  ; → interact/NPC data
    dw Exit_RoomOfMemoriesBewilder_s0  ; → exit data

Interact_RoomOfMemoriesBewilder_s0:  ; $6555 — 3 NPCs
    db $00, $0B, $06, $03, $01  ; NPC down b=0 spr=$0B (6,3) script=$01
    db $00, $4D, $05, $01, $FF  ; NPC down b=0 spr=$4D (5,1) script=none
    db $00, $4D, $07, $01, $FF  ; NPC down b=0 spr=$4D (7,1) script=none
    db $FF  ; terminator

Interact_RoomOfMemoriesBewilder_s0_v1:  ; $6565 — 2 NPCs
    db $00, $0B, $06, $03, $01  ; NPC down b=0 spr=$0B (6,3) script=$01
    db $00, $4D, $07, $01, $FF  ; NPC down b=0 spr=$4D (7,1) script=none
    db $FF  ; terminator

Interact_RoomOfMemoriesBewilder_s0_v2:  ; $6570 — 2 NPCs
    db $00, $0B, $06, $03, $01  ; NPC down b=0 spr=$0B (6,3) script=$01
    db $00, $4D, $05, $01, $FF  ; NPC down b=0 spr=$4D (5,1) script=none
    db $FF  ; terminator

Interact_RoomOfMemoriesBewilder_s0_v3:  ; $657B — 1 NPCs
    db $00, $0B, $06, $03, $01  ; NPC down b=0 spr=$0B (6,3) script=$01
    db $FF  ; terminator

Exit_RoomOfMemoriesBewilder_s0:  ; $6581 — 3 exits
    db $01, $07, $03, $00, $81, $07, $02  ; exit (1,7)→mt$03 GateHub  scr=1+Y8 spawn(7,2)
    db $05, $01, $03, $01, $00, $00, $00  ; exit (5,1)→mt$03 GateHub gate scr=0 spawn(0,0)
    db $07, $01, $04, $01, $00, $00, $00  ; exit (7,1)→mt$04 Farm gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_RoomOfPeaceBravery:  ; $6597 — mt=[$26]
    dw StepBlk_RoomOfPeaceBravery_s0  ; screen 0

StepBlk_RoomOfPeaceBravery_s0:  ; $6599 — RAM=$D96B, 4 steps
    dw $D96B  ; RAM step counter
    db $09, $2D  ; step 0: layout=$09 bank=$2D
    dw Interact_RoomOfPeaceBravery_s0  ; → interact/NPC data
    dw Exit_RoomOfPeaceBravery_s0  ; → exit data
    db $09, $2D  ; step 1: layout=$09 bank=$2D
    dw Interact_RoomOfPeaceBravery_s0_v1  ; → interact/NPC data
    dw Exit_RoomOfPeaceBravery_s0  ; → exit data
    db $09, $2D  ; step 2: layout=$09 bank=$2D
    dw Interact_RoomOfPeaceBravery_s0_v2  ; → interact/NPC data
    dw Exit_RoomOfPeaceBravery_s0  ; → exit data
    db $09, $2D  ; step 3: layout=$09 bank=$2D
    dw Interact_RoomOfPeaceBravery_s0_v3  ; → interact/NPC data
    dw Exit_RoomOfPeaceBravery_s0  ; → exit data

Interact_RoomOfPeaceBravery_s0:  ; $65B3 — 3 NPCs
    db $00, $0B, $08, $05, $01  ; NPC down b=0 spr=$0B (8,5) script=$01
    db $00, $4D, $03, $03, $FF  ; NPC down b=0 spr=$4D (3,3) script=none
    db $00, $4D, $06, $03, $FF  ; NPC down b=0 spr=$4D (6,3) script=none
    db $FF  ; terminator

Interact_RoomOfPeaceBravery_s0_v1:  ; $65C3 — 2 NPCs
    db $00, $0B, $08, $05, $01  ; NPC down b=0 spr=$0B (8,5) script=$01
    db $00, $4D, $06, $03, $FF  ; NPC down b=0 spr=$4D (6,3) script=none
    db $FF  ; terminator

Interact_RoomOfPeaceBravery_s0_v2:  ; $65CE — 2 NPCs
    db $00, $0B, $08, $05, $01  ; NPC down b=0 spr=$0B (8,5) script=$01
    db $00, $4D, $03, $03, $FF  ; NPC down b=0 spr=$4D (3,3) script=none
    db $FF  ; terminator

Interact_RoomOfPeaceBravery_s0_v3:  ; $65D9 — 1 NPCs
    db $00, $0B, $08, $05, $01  ; NPC down b=0 spr=$0B (8,5) script=$01
    db $FF  ; terminator

Exit_RoomOfPeaceBravery_s0:  ; $65DF — 3 exits
    db $08, $07, $03, $00, $80, $07, $02  ; exit (8,7)→mt$03 GateHub  scr=0+Y8 spawn(7,2)
    db $03, $03, $06, $01, $00, $00, $00  ; exit (3,3)→mt$06 ArenaLobby gate scr=0 spawn(0,0)
    db $06, $03, $07, $01, $00, $00, $00  ; exit (6,3)→mt$07 ArenaRooms gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_RoomOfStrengthAnger:  ; $65F5 — mt=[$27]
    dw StepBlk_RoomOfStrengthAnger_s0  ; screen 0

StepBlk_RoomOfStrengthAnger_s0:  ; $65F7 — RAM=$D96C, 3 steps
    dw $D96C  ; RAM step counter
    db $0B, $2D  ; step 0: layout=$0B bank=$2D
    dw Interact_RoomOfStrengthAnger_s0  ; → interact/NPC data
    dw Exit_RoomOfStrengthAnger_s0  ; → exit data
    db $0B, $2D  ; step 1: layout=$0B bank=$2D
    dw Interact_RoomOfStrengthAnger_s0_v1  ; → interact/NPC data
    dw Exit_RoomOfStrengthAnger_s0  ; → exit data
    db $0B, $2D  ; step 2: layout=$0B bank=$2D
    dw Interact_RoomOfStrengthAnger_s0_v2  ; → interact/NPC data
    dw Exit_RoomOfStrengthAnger_s0  ; → exit data

Interact_RoomOfStrengthAnger_s0:  ; $660B — 4 NPCs
    db $01, $0B, $02, $04, $01  ; NPC down b=1 spr=$0B (2,4) script=$01
    db $01, $0B, $08, $05, $02  ; NPC down b=1 spr=$0B (8,5) script=$02
    db $00, $4D, $02, $03, $FF  ; NPC down b=0 spr=$4D (2,3) script=none
    db $00, $4D, $07, $03, $FF  ; NPC down b=0 spr=$4D (7,3) script=none
    db $FF  ; terminator

Interact_RoomOfStrengthAnger_s0_v1:  ; $6620 — 3 NPCs
    db $20, $0B, $01, $06, $01  ; NPC up b=0 spr=$0B (1,6) script=$01
    db $10, $0B, $08, $05, $02  ; NPC left b=0 spr=$0B (8,5) script=$02
    db $00, $4D, $02, $03, $FF  ; NPC down b=0 spr=$4D (2,3) script=none
    db $FF  ; terminator

Interact_RoomOfStrengthAnger_s0_v2:  ; $6630 — 2 NPCs
    db $20, $0B, $01, $06, $01  ; NPC up b=0 spr=$0B (1,6) script=$01
    db $10, $0B, $08, $05, $02  ; NPC left b=0 spr=$0B (8,5) script=$02
    db $FF  ; terminator

Exit_RoomOfStrengthAnger_s0:  ; $663B — 4 exits
    db $04, $07, $03, $00, $80, $04, $01  ; exit (4,7)→mt$03 GateHub  scr=0+Y8 spawn(4,1)
    db $05, $07, $03, $00, $80, $05, $01  ; exit (5,7)→mt$03 GateHub  scr=0+Y8 spawn(5,1)
    db $02, $03, $09, $01, $00, $00, $00  ; exit (2,3)→mt$09 StarryShrine gate scr=0 spawn(0,0)
    db $07, $03, $0A, $01, $00, $00, $00  ; exit (7,3)→mt$0A SecretPassage gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_RoomOfJoyWisdom:  ; $6658 — mt=[$28]
    dw StepBlk_RoomOfJoyWisdom_s0  ; screen 0

StepBlk_RoomOfJoyWisdom_s0:  ; $665A — RAM=$D96D, 4 steps
    dw $D96D  ; RAM step counter
    db $0D, $2D  ; step 0: layout=$0D bank=$2D
    dw Interact_RoomOfJoyWisdom_s0  ; → interact/NPC data
    dw Exit_RoomOfJoyWisdom_s0  ; → exit data
    db $0D, $2D  ; step 1: layout=$0D bank=$2D
    dw Interact_RoomOfJoyWisdom_s0_v1  ; → interact/NPC data
    dw Exit_RoomOfJoyWisdom_s0  ; → exit data
    db $0D, $2D  ; step 2: layout=$0D bank=$2D
    dw Interact_RoomOfJoyWisdom_s0_v2  ; → interact/NPC data
    dw Exit_RoomOfJoyWisdom_s0  ; → exit data
    db $0D, $2D  ; step 3: layout=$0D bank=$2D
    dw Interact_RoomOfJoyWisdom_s0_v3  ; → interact/NPC data
    dw Exit_RoomOfJoyWisdom_s0  ; → exit data

Interact_RoomOfJoyWisdom_s0:  ; $6674 — 3 NPCs
    db $10, $0B, $06, $06, $01  ; NPC left b=0 spr=$0B (6,6) script=$01
    db $00, $4D, $03, $02, $FF  ; NPC down b=0 spr=$4D (3,2) script=none
    db $00, $4D, $05, $02, $FF  ; NPC down b=0 spr=$4D (5,2) script=none
    db $FF  ; terminator

Interact_RoomOfJoyWisdom_s0_v1:  ; $6684 — 2 NPCs
    db $10, $0B, $06, $06, $01  ; NPC left b=0 spr=$0B (6,6) script=$01
    db $00, $4D, $03, $02, $FF  ; NPC down b=0 spr=$4D (3,2) script=none
    db $FF  ; terminator

Interact_RoomOfJoyWisdom_s0_v2:  ; $668F — 2 NPCs
    db $10, $0B, $06, $06, $01  ; NPC left b=0 spr=$0B (6,6) script=$01
    db $00, $4D, $05, $02, $FF  ; NPC down b=0 spr=$4D (5,2) script=none
    db $FF  ; terminator

Interact_RoomOfJoyWisdom_s0_v3:  ; $669A — 1 NPCs
    db $10, $0B, $06, $06, $01  ; NPC left b=0 spr=$0B (6,6) script=$01
    db $FF  ; terminator

Exit_RoomOfJoyWisdom_s0:  ; $66A0 — 3 exits
    db $04, $07, $03, $00, $80, $02, $02  ; exit (4,7)→mt$03 GateHub  scr=0+Y8 spawn(2,2)
    db $03, $02, $0C, $01, $00, $00, $00  ; exit (3,2)→mt$0C Gate_0C gate scr=0 spawn(0,0)
    db $05, $02, $0D, $01, $00, $00, $00  ; exit (5,2)→mt$0D OldManGate gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_RoomOfHappinessTemptation:  ; $66B6 — mt=[$29]
    dw StepBlk_RoomOfHappinessTemptation_s0  ; screen 0

StepBlk_RoomOfHappinessTemptation_s0:  ; $66B8 — RAM=$D96E, 4 steps
    dw $D96E  ; RAM step counter
    db $0F, $2D  ; step 0: layout=$0F bank=$2D
    dw Interact_RoomOfHappinessTemptation_s0  ; → interact/NPC data
    dw Exit_RoomOfHappinessTemptation_s0  ; → exit data
    db $0F, $2D  ; step 1: layout=$0F bank=$2D
    dw Interact_RoomOfHappinessTemptation_s0_v1  ; → interact/NPC data
    dw Exit_RoomOfHappinessTemptation_s0  ; → exit data
    db $0F, $2D  ; step 2: layout=$0F bank=$2D
    dw Interact_RoomOfHappinessTemptation_s0_v2  ; → interact/NPC data
    dw Exit_RoomOfHappinessTemptation_s0  ; → exit data
    db $0F, $2D  ; step 3: layout=$0F bank=$2D
    dw Interact_RoomOfHappinessTemptation_s0_v3  ; → interact/NPC data
    dw Exit_RoomOfHappinessTemptation_s0  ; → exit data

Interact_RoomOfHappinessTemptation_s0:  ; $66D2 — 3 NPCs
    db $10, $0B, $07, $06, $01  ; NPC left b=0 spr=$0B (7,6) script=$01
    db $00, $4D, $03, $02, $FF  ; NPC down b=0 spr=$4D (3,2) script=none
    db $00, $4D, $06, $02, $FF  ; NPC down b=0 spr=$4D (6,2) script=none
    db $FF  ; terminator

Interact_RoomOfHappinessTemptation_s0_v1:  ; $66E2 — 2 NPCs
    db $10, $0B, $07, $06, $01  ; NPC left b=0 spr=$0B (7,6) script=$01
    db $00, $4D, $06, $02, $FF  ; NPC down b=0 spr=$4D (6,2) script=none
    db $FF  ; terminator

Interact_RoomOfHappinessTemptation_s0_v2:  ; $66ED — 2 NPCs
    db $10, $0B, $07, $06, $01  ; NPC left b=0 spr=$0B (7,6) script=$01
    db $00, $4D, $03, $02, $FF  ; NPC down b=0 spr=$4D (3,2) script=none
    db $FF  ; terminator

Interact_RoomOfHappinessTemptation_s0_v3:  ; $66F8 — 1 NPCs
    db $10, $0B, $07, $06, $01  ; NPC left b=0 spr=$0B (7,6) script=$01
    db $FF  ; terminator

Exit_RoomOfHappinessTemptation_s0:  ; $66FE — 3 exits
    db $04, $07, $03, $00, $84, $07, $02  ; exit (4,7)→mt$03 GateHub  scr=4+Y8 spawn(7,2)
    db $03, $02, $0F, $01, $00, $00, $00  ; exit (3,2)→mt$0F Room_0F gate scr=0 spawn(0,0)
    db $06, $02, $10, $01, $00, $00, $00  ; exit (6,2)→mt$10 CopycatRoom gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_RoomOfLabyrinthJudgment:  ; $6714 — mt=[$2A]
    dw StepBlk_RoomOfLabyrinthJudgment_s0  ; screen 0

StepBlk_RoomOfLabyrinthJudgment_s0:  ; $6716 — RAM=$D96F, 4 steps
    dw $D96F  ; RAM step counter
    db $11, $2D  ; step 0: layout=$11 bank=$2D
    dw Interact_RoomOfLabyrinthJudgment_s0  ; → interact/NPC data
    dw Exit_RoomOfLabyrinthJudgment_s0  ; → exit data
    db $11, $2D  ; step 1: layout=$11 bank=$2D
    dw Interact_RoomOfLabyrinthJudgment_s0_v1  ; → interact/NPC data
    dw Exit_RoomOfLabyrinthJudgment_s0  ; → exit data
    db $11, $2D  ; step 2: layout=$11 bank=$2D
    dw Interact_RoomOfLabyrinthJudgment_s0_v2  ; → interact/NPC data
    dw Exit_RoomOfLabyrinthJudgment_s0  ; → exit data
    db $11, $2D  ; step 3: layout=$11 bank=$2D
    dw Interact_RoomOfLabyrinthJudgment_s0_v3  ; → interact/NPC data
    dw Exit_RoomOfLabyrinthJudgment_s0  ; → exit data

Interact_RoomOfLabyrinthJudgment_s0:  ; $6730 — 3 NPCs
    db $00, $0B, $05, $02, $01  ; NPC down b=0 spr=$0B (5,2) script=$01
    db $00, $4D, $02, $04, $FF  ; NPC down b=0 spr=$4D (2,4) script=none
    db $00, $4D, $07, $04, $FF  ; NPC down b=0 spr=$4D (7,4) script=none
    db $FF  ; terminator

Interact_RoomOfLabyrinthJudgment_s0_v1:  ; $6740 — 2 NPCs
    db $00, $0B, $05, $02, $01  ; NPC down b=0 spr=$0B (5,2) script=$01
    db $00, $4D, $07, $04, $FF  ; NPC down b=0 spr=$4D (7,4) script=none
    db $FF  ; terminator

Interact_RoomOfLabyrinthJudgment_s0_v2:  ; $674B — 2 NPCs
    db $00, $0B, $05, $02, $01  ; NPC down b=0 spr=$0B (5,2) script=$01
    db $00, $4D, $02, $04, $FF  ; NPC down b=0 spr=$4D (2,4) script=none
    db $FF  ; terminator

Interact_RoomOfLabyrinthJudgment_s0_v3:  ; $6756 — 1 NPCs
    db $00, $0B, $05, $02, $01  ; NPC down b=0 spr=$0B (5,2) script=$01
    db $FF  ; terminator

Exit_RoomOfLabyrinthJudgment_s0:  ; $675C — 3 exits
    db $04, $07, $03, $00, $84, $02, $02  ; exit (4,7)→mt$03 GateHub  scr=4+Y8 spawn(2,2)
    db $02, $04, $12, $01, $00, $00, $00  ; exit (2,4)→mt$12 Library gate scr=0 spawn(0,0)
    db $07, $04, $13, $01, $00, $00, $00  ; exit (7,4)→mt$13 Room_13 gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_RoomOfReflection:  ; $6772 — mt=[$2B]
    dw StepBlk_RoomOfReflection_s0  ; screen 0

StepBlk_RoomOfReflection_s0:  ; $6774 — RAM=$D970, 2 steps
    dw $D970  ; RAM step counter
    db $13, $2D  ; step 0: layout=$13 bank=$2D
    dw Interact_RoomOfReflection_s0  ; → interact/NPC data
    dw Exit_RoomOfReflection_s0  ; → exit data
    db $13, $2D  ; step 1: layout=$13 bank=$2D
    dw Interact_RoomOfReflection_s0_v1  ; → interact/NPC data
    dw Exit_RoomOfReflection_s0  ; → exit data

Interact_RoomOfReflection_s0:  ; $6782 — 2 NPCs
    db $30, $0B, $01, $06, $01  ; NPC right b=0 spr=$0B (1,6) script=$01
    db $00, $4D, $03, $02, $FF  ; NPC down b=0 spr=$4D (3,2) script=none
    db $FF  ; terminator

Interact_RoomOfReflection_s0_v1:  ; $678D — 1 NPCs
    db $30, $0B, $01, $06, $01  ; NPC right b=0 spr=$0B (1,6) script=$01
    db $FF  ; terminator

Exit_RoomOfReflection_s0:  ; $6793 — 3 exits
    db $07, $07, $03, $00, $84, $04, $01  ; exit (7,7)→mt$03 GateHub  scr=4+Y8 spawn(4,1)
    db $08, $07, $03, $00, $84, $05, $01  ; exit (8,7)→mt$03 GateHub  scr=4+Y8 spawn(5,1)
    db $03, $02, $15, $01, $00, $00, $00  ; exit (3,2)→mt$15 Castle_15 gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_RoomOfAmbitionDemolition:  ; $67A9 — mt=[$2C]
    dw StepBlk_RoomOfAmbitionDemolition_s0  ; screen 0

StepBlk_RoomOfAmbitionDemolition_s0:  ; $67AB — RAM=$D971, 4 steps
    dw $D971  ; RAM step counter
    db $15, $2D  ; step 0: layout=$15 bank=$2D
    dw Interact_RoomOfAmbitionDemolition_s0  ; → interact/NPC data
    dw Exit_RoomOfAmbitionDemolition_s0  ; → exit data
    db $15, $2D  ; step 1: layout=$15 bank=$2D
    dw Interact_RoomOfAmbitionDemolition_s0_v1  ; → interact/NPC data
    dw Exit_RoomOfAmbitionDemolition_s0  ; → exit data
    db $15, $2D  ; step 2: layout=$15 bank=$2D
    dw Interact_RoomOfAmbitionDemolition_s0_v2  ; → interact/NPC data
    dw Exit_RoomOfAmbitionDemolition_s0  ; → exit data
    db $15, $2D  ; step 3: layout=$15 bank=$2D
    dw Interact_RoomOfAmbitionDemolition_s0_v3  ; → interact/NPC data
    dw Exit_RoomOfAmbitionDemolition_s0  ; → exit data

Interact_RoomOfAmbitionDemolition_s0:  ; $67C5 — 3 NPCs
    db $30, $0B, $01, $06, $01  ; NPC right b=0 spr=$0B (1,6) script=$01
    db $00, $4D, $01, $03, $FF  ; NPC down b=0 spr=$4D (1,3) script=none
    db $00, $4D, $03, $03, $FF  ; NPC down b=0 spr=$4D (3,3) script=none
    db $FF  ; terminator

Interact_RoomOfAmbitionDemolition_s0_v1:  ; $67D5 — 2 NPCs
    db $30, $0B, $01, $06, $01  ; NPC right b=0 spr=$0B (1,6) script=$01
    db $00, $4D, $03, $03, $FF  ; NPC down b=0 spr=$4D (3,3) script=none
    db $FF  ; terminator

Interact_RoomOfAmbitionDemolition_s0_v2:  ; $67E0 — 2 NPCs
    db $30, $0B, $01, $06, $01  ; NPC right b=0 spr=$0B (1,6) script=$01
    db $00, $4D, $01, $03, $FF  ; NPC down b=0 spr=$4D (1,3) script=none
    db $FF  ; terminator

Interact_RoomOfAmbitionDemolition_s0_v3:  ; $67EB — 1 NPCs
    db $30, $0B, $01, $06, $01  ; NPC right b=0 spr=$0B (1,6) script=$01
    db $FF  ; terminator

Exit_RoomOfAmbitionDemolition_s0:  ; $67F1 — 3 exits
    db $08, $07, $03, $00, $85, $02, $02  ; exit (8,7)→mt$03 GateHub  scr=5+Y8 spawn(2,2)
    db $01, $03, $16, $01, $00, $00, $00  ; exit (1,3)→mt$16 MedalManRoom gate scr=0 spawn(0,0)
    db $03, $03, $17, $01, $00, $00, $00  ; exit (3,3)→mt$17 Copycat_17 gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_RoomOfMastermindControl:  ; $6807 — mt=[$2D]
    dw StepBlk_RoomOfMastermindControl_s0  ; screen 0

StepBlk_RoomOfMastermindControl_s0:  ; $6809 — RAM=$D972, 4 steps
    dw $D972  ; RAM step counter
    db $17, $2D  ; step 0: layout=$17 bank=$2D
    dw Interact_RoomOfMastermindControl_s0  ; → interact/NPC data
    dw Exit_RoomOfMastermindControl_s0  ; → exit data
    db $17, $2D  ; step 1: layout=$17 bank=$2D
    dw Interact_RoomOfMastermindControl_s0_v1  ; → interact/NPC data
    dw Exit_RoomOfMastermindControl_s0  ; → exit data
    db $17, $2D  ; step 2: layout=$17 bank=$2D
    dw Interact_RoomOfMastermindControl_s0_v2  ; → interact/NPC data
    dw Exit_RoomOfMastermindControl_s0  ; → exit data
    db $17, $2D  ; step 3: layout=$17 bank=$2D
    dw Interact_RoomOfMastermindControl_s0_v3  ; → interact/NPC data
    dw Exit_RoomOfMastermindControl_s0  ; → exit data

Interact_RoomOfMastermindControl_s0:  ; $6823 — 3 NPCs
    db $00, $0B, $02, $02, $01  ; NPC down b=0 spr=$0B (2,2) script=$01
    db $00, $4D, $06, $02, $FF  ; NPC down b=0 spr=$4D (6,2) script=none
    db $00, $4D, $06, $04, $FF  ; NPC down b=0 spr=$4D (6,4) script=none
    db $FF  ; terminator

Interact_RoomOfMastermindControl_s0_v1:  ; $6833 — 2 NPCs
    db $00, $0B, $02, $02, $01  ; NPC down b=0 spr=$0B (2,2) script=$01
    db $00, $4D, $06, $04, $FF  ; NPC down b=0 spr=$4D (6,4) script=none
    db $FF  ; terminator

Interact_RoomOfMastermindControl_s0_v2:  ; $683E — 2 NPCs
    db $00, $0B, $02, $02, $01  ; NPC down b=0 spr=$0B (2,2) script=$01
    db $00, $4D, $06, $02, $FF  ; NPC down b=0 spr=$4D (6,2) script=none
    db $FF  ; terminator

Interact_RoomOfMastermindControl_s0_v3:  ; $6849 — 1 NPCs
    db $00, $0B, $02, $02, $01  ; NPC down b=0 spr=$0B (2,2) script=$01
    db $FF  ; terminator

Exit_RoomOfMastermindControl_s0:  ; $684F — 3 exits
    db $02, $07, $03, $00, $85, $07, $02  ; exit (2,7)→mt$03 GateHub  scr=5+Y8 spawn(7,2)
    db $06, $02, $18, $01, $00, $00, $00  ; exit (6,2)→mt$18 Well gate scr=0 spawn(0,0)
    db $06, $04, $19, $01, $00, $00, $00  ; exit (6,4)→mt$19 Room_19 gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_RoomOfExtinctionSleep:  ; $6865 — mt=[$2E]
    dw StepBlk_RoomOfExtinctionSleep_s0  ; screen 0

StepBlk_RoomOfExtinctionSleep_s0:  ; $6867 — RAM=$D973, 4 steps
    dw $D973  ; RAM step counter
    db $19, $2D  ; step 0: layout=$19 bank=$2D
    dw Interact_RoomOfExtinctionSleep_s0  ; → interact/NPC data
    dw Exit_RoomOfExtinctionSleep_s0  ; → exit data
    db $19, $2D  ; step 1: layout=$19 bank=$2D
    dw Interact_RoomOfExtinctionSleep_s0_v1  ; → interact/NPC data
    dw Exit_RoomOfExtinctionSleep_s0  ; → exit data
    db $19, $2D  ; step 2: layout=$19 bank=$2D
    dw Interact_RoomOfExtinctionSleep_s0_v2  ; → interact/NPC data
    dw Exit_RoomOfExtinctionSleep_s0  ; → exit data
    db $19, $2D  ; step 3: layout=$19 bank=$2D
    dw Interact_RoomOfExtinctionSleep_s0_v3  ; → interact/NPC data
    dw Exit_RoomOfExtinctionSleep_s0  ; → exit data

Interact_RoomOfExtinctionSleep_s0:  ; $6881 — 3 NPCs
    db $00, $0B, $03, $04, $01  ; NPC down b=0 spr=$0B (3,4) script=$01
    db $00, $4D, $02, $02, $FF  ; NPC down b=0 spr=$4D (2,2) script=none
    db $00, $4D, $04, $02, $FF  ; NPC down b=0 spr=$4D (4,2) script=none
    db $FF  ; terminator

Interact_RoomOfExtinctionSleep_s0_v1:  ; $6891 — 2 NPCs
    db $00, $0B, $03, $04, $01  ; NPC down b=0 spr=$0B (3,4) script=$01
    db $00, $4D, $04, $02, $FF  ; NPC down b=0 spr=$4D (4,2) script=none
    db $FF  ; terminator

Interact_RoomOfExtinctionSleep_s0_v2:  ; $689C — 2 NPCs
    db $00, $0B, $03, $04, $01  ; NPC down b=0 spr=$0B (3,4) script=$01
    db $00, $4D, $02, $02, $FF  ; NPC down b=0 spr=$4D (2,2) script=none
    db $FF  ; terminator

Interact_RoomOfExtinctionSleep_s0_v3:  ; $68A7 — 1 NPCs
    db $00, $0B, $03, $04, $01  ; NPC down b=0 spr=$0B (3,4) script=$01
    db $FF  ; terminator

Exit_RoomOfExtinctionSleep_s0:  ; $68AD — 4 exits
    db $06, $07, $03, $00, $85, $04, $01  ; exit (6,7)→mt$03 GateHub  scr=5+Y8 spawn(4,1)
    db $07, $07, $03, $00, $85, $05, $01  ; exit (7,7)→mt$03 GateHub  scr=5+Y8 spawn(5,1)
    db $02, $02, $1A, $01, $00, $00, $00  ; exit (2,2)→mt$1A Room_1A gate scr=0 spawn(0,0)
    db $04, $02, $1B, $01, $00, $00, $00  ; exit (4,2)→mt$1B Room_1B gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_Room_2F:  ; $68CA — mt=[$2F]
    dw $FFFF  ; screen 0 (unused)
    dw $FFFF  ; screen 1 (unused)
    dw $FFFF  ; screen 2 (unused)
    dw $FFFF  ; screen 3 (unused)
    dw StepBlk_Room_2F_s4  ; screen 4
    dw StepBlk_Room_2F_s5  ; screen 5

StepBlk_Room_2F_s4:  ; $68D6 — RAM=$D974, 7 steps
    dw $D974  ; RAM step counter
    db $1B, $2D  ; step 0: layout=$1B bank=$2D
    dw Interact_Room_2F_s4  ; → interact/NPC data
    dw Exit_Room_2F_s4  ; → exit data
    db $1B, $2D  ; step 1: layout=$1B bank=$2D
    dw Interact_Room_2F_s4_v1  ; → interact/NPC data
    dw Exit_Room_2F_s4  ; → exit data
    db $1B, $2D  ; step 2: layout=$1B bank=$2D
    dw Interact_Room_2F_s4_v2  ; → interact/NPC data
    dw Exit_Room_2F_s4  ; → exit data
    db $1B, $2D  ; step 3: layout=$1B bank=$2D
    dw Interact_Room_2F_s4_v3  ; → interact/NPC data
    dw Exit_Room_2F_s4  ; → exit data
    db $1B, $2D  ; step 4: layout=$1B bank=$2D
    dw Interact_Room_2F_s4_v4  ; → interact/NPC data
    dw Exit_Room_2F_s4  ; → exit data
    db $1B, $2D  ; step 5: layout=$1B bank=$2D
    dw Interact_Room_2F_s4_v5  ; → interact/NPC data
    dw Exit_Room_2F_s4  ; → exit data
    db $1B, $2D  ; step 6: layout=$1B bank=$2D
    dw Interact_Room_2F_s4_v2  ; → interact/NPC data
    dw Exit_Room_2F_s4  ; → exit data

StepBlk_Room_2F_s5:  ; $6902 — RAM=$D975, 2 steps
    dw $D975  ; RAM step counter
    db $1C, $2D  ; step 0: layout=$1C bank=$2D
    dw Interact_Room_2F_s5  ; → interact/NPC data
    dw Exit_Room_2F_s5  ; → exit data
    db $1C, $2D  ; step 1: layout=$1C bank=$2D
    dw Interact_Room_2F_s5_v1  ; → interact/NPC data
    dw Exit_Room_2F_s5  ; → exit data

Interact_Room_2F_s4:  ; $6910 — 7 spawns, 3 NPCs
    db $8F, $FF, $01, $01, $01  ; spawn (1,1) mt$01 GreatTree
    db $8F, $FF, $02, $01, $02  ; spawn (2,1) mt$02 Bazaar
    db $8F, $FF, $07, $01, $03  ; spawn (7,1) mt$03 GateHub
    db $8F, $FF, $08, $01, $04  ; spawn (8,1) mt$04 Farm
    db $8F, $FF, $05, $04, $05  ; spawn (5,4) mt$05 Stable
    db $8F, $FF, $04, $01, $06  ; spawn (4,1) mt$06 ArenaLobby
    db $8F, $FF, $05, $01, $06  ; spawn (5,1) mt$06 ArenaLobby
    db $50, $14, $05, $03, $07  ; NPC noTalk left b=0 spr=$14 (5,3) script=$07
    db $00, $51, $06, $04, $07  ; NPC down b=0 spr=$51 (6,4) script=$07
    db $40, $50, $03, $04, $FF  ; NPC noTalk down b=0 spr=$50 (3,4) script=none
    db $FF  ; terminator

Interact_Room_2F_s4_v1:  ; $6943 — 7 spawns
    db $8F, $FF, $01, $01, $01  ; spawn (1,1) mt$01 GreatTree
    db $8F, $FF, $02, $01, $02  ; spawn (2,1) mt$02 Bazaar
    db $8F, $FF, $07, $01, $03  ; spawn (7,1) mt$03 GateHub
    db $8F, $FF, $08, $01, $04  ; spawn (8,1) mt$04 Farm
    db $8F, $FF, $05, $04, $05  ; spawn (5,4) mt$05 Stable
    db $8F, $FF, $04, $01, $06  ; spawn (4,1) mt$06 ArenaLobby
    db $8F, $FF, $05, $01, $06  ; spawn (5,1) mt$06 ArenaLobby
    db $FF  ; terminator

Interact_Room_2F_s4_v2:  ; $6967 — 7 spawns, 5 NPCs
    db $8F, $FF, $01, $01, $01  ; spawn (1,1) mt$01 GreatTree
    db $8F, $FF, $02, $01, $02  ; spawn (2,1) mt$02 Bazaar
    db $8F, $FF, $07, $01, $03  ; spawn (7,1) mt$03 GateHub
    db $8F, $FF, $08, $01, $04  ; spawn (8,1) mt$04 Farm
    db $8F, $FF, $05, $04, $05  ; spawn (5,4) mt$05 Stable
    db $8F, $FF, $04, $01, $06  ; spawn (4,1) mt$06 ArenaLobby
    db $8F, $FF, $05, $01, $06  ; spawn (5,1) mt$06 ArenaLobby
    db $50, $14, $07, $04, $07  ; NPC noTalk left b=0 spr=$14 (7,4) script=$07
    db $50, $21, $0B, $00, $FF  ; NPC noTalk left b=0 spr=$21 (11,0) script=none
    db $00, $51, $06, $04, $07  ; NPC down b=0 spr=$51 (6,4) script=$07
    db $40, $5F, $05, $03, $FF  ; NPC noTalk down b=0 spr=$5F (5,3) script=none
    db $40, $50, $03, $04, $FF  ; NPC noTalk down b=0 spr=$50 (3,4) script=none
    db $FF  ; terminator

Interact_Room_2F_s4_v3:  ; $69A4 — 7 spawns, 5 NPCs
    db $8F, $FF, $01, $01, $01  ; spawn (1,1) mt$01 GreatTree
    db $8F, $FF, $02, $01, $02  ; spawn (2,1) mt$02 Bazaar
    db $8F, $FF, $07, $01, $03  ; spawn (7,1) mt$03 GateHub
    db $8F, $FF, $08, $01, $04  ; spawn (8,1) mt$04 Farm
    db $8F, $FF, $05, $04, $05  ; spawn (5,4) mt$05 Stable
    db $8F, $FF, $04, $01, $06  ; spawn (4,1) mt$06 ArenaLobby
    db $8F, $FF, $05, $01, $06  ; spawn (5,1) mt$06 ArenaLobby
    db $50, $14, $07, $04, $07  ; NPC noTalk left b=0 spr=$14 (7,4) script=$07
    db $50, $21, $0B, $00, $FF  ; NPC noTalk left b=0 spr=$21 (11,0) script=none
    db $00, $51, $06, $04, $07  ; NPC down b=0 spr=$51 (6,4) script=$07
    db $40, $5F, $05, $03, $FF  ; NPC noTalk down b=0 spr=$5F (5,3) script=none
    db $40, $50, $03, $04, $FF  ; NPC noTalk down b=0 spr=$50 (3,4) script=none
    db $FF  ; terminator

Interact_Room_2F_s4_v4:  ; $69E1 — 9 spawns, 5 NPCs
    db $90, $FF, $02, $03, $0D  ; walk_exit (2,3) mt$0D OldManGate
    db $90, $FF, $04, $03, $0E  ; walk_exit (4,3) mt$0E Castle_0E
    db $8F, $FF, $01, $01, $01  ; spawn (1,1) mt$01 GreatTree
    db $8F, $FF, $02, $01, $02  ; spawn (2,1) mt$02 Bazaar
    db $8F, $FF, $07, $01, $03  ; spawn (7,1) mt$03 GateHub
    db $8F, $FF, $08, $01, $04  ; spawn (8,1) mt$04 Farm
    db $8F, $FF, $05, $04, $05  ; spawn (5,4) mt$05 Stable
    db $8F, $FF, $04, $01, $06  ; spawn (4,1) mt$06 ArenaLobby
    db $8F, $FF, $05, $01, $06  ; spawn (5,1) mt$06 ArenaLobby
    db $10, $14, $07, $04, $07  ; NPC left b=0 spr=$14 (7,4) script=$07
    db $40, $21, $0B, $04, $FF  ; NPC noTalk down b=0 spr=$21 (11,4) script=none
    db $70, $14, $07, $04, $07  ; NPC noTalk right b=0 spr=$14 (7,4) script=$07
    db $40, $5F, $05, $03, $FF  ; NPC noTalk down b=0 spr=$5F (5,3) script=none
    db $40, $50, $03, $04, $FF  ; NPC noTalk down b=0 spr=$50 (3,4) script=none
    db $FF  ; terminator

Interact_Room_2F_s4_v5:  ; $6A28 — 7 spawns, 5 NPCs
    db $8F, $FF, $01, $01, $01  ; spawn (1,1) mt$01 GreatTree
    db $8F, $FF, $02, $01, $02  ; spawn (2,1) mt$02 Bazaar
    db $8F, $FF, $07, $01, $03  ; spawn (7,1) mt$03 GateHub
    db $8F, $FF, $08, $01, $04  ; spawn (8,1) mt$04 Farm
    db $8F, $FF, $05, $04, $05  ; spawn (5,4) mt$05 Stable
    db $8F, $FF, $04, $01, $06  ; spawn (4,1) mt$06 ArenaLobby
    db $8F, $FF, $05, $01, $06  ; spawn (5,1) mt$06 ArenaLobby
    db $50, $14, $06, $04, $06  ; NPC noTalk left b=0 spr=$14 (6,4) script=$06
    db $50, $21, $0B, $00, $FF  ; NPC noTalk left b=0 spr=$21 (11,0) script=none
    db $00, $51, $06, $04, $06  ; NPC down b=0 spr=$51 (6,4) script=$06
    db $00, $5F, $04, $05, $FF  ; NPC down b=0 spr=$5F (4,5) script=none
    db $00, $50, $03, $04, $FF  ; NPC down b=0 spr=$50 (3,4) script=none
    db $FF  ; terminator

Interact_Room_2F_s5:  ; $6A65 — 5 spawns, 3 NPCs
    db $8F, $FF, $01, $01, $08  ; spawn (1,1) mt$08 Gate_08
    db $8F, $FF, $02, $01, $09  ; spawn (2,1) mt$09 StarryShrine
    db $8F, $FF, $08, $01, $0A  ; spawn (8,1) mt$0A SecretPassage
    db $8F, $FF, $08, $05, $0B  ; spawn (8,5) mt$0B Castle_0B
    db $8F, $FF, $05, $01, $0C  ; spawn (5,1) mt$0C Gate_0C
    db $40, $21, $08, $01, $FF  ; NPC noTalk down b=0 spr=$21 (8,1) script=none
    db $40, $39, $08, $01, $FF  ; NPC noTalk down b=0 spr=$39 (8,1) script=none
    db $50, $14, $00, $04, $07  ; NPC noTalk left b=0 spr=$14 (0,4) script=$07
    db $FF  ; terminator

Interact_Room_2F_s5_v1:  ; $6A8E — 5 spawns, 1 NPCs
    db $8F, $FF, $01, $01, $08  ; spawn (1,1) mt$08 Gate_08
    db $8F, $FF, $02, $01, $09  ; spawn (2,1) mt$09 StarryShrine
    db $8F, $FF, $08, $01, $0A  ; spawn (8,1) mt$0A SecretPassage
    db $8F, $FF, $08, $05, $0B  ; spawn (8,5) mt$0B Castle_0B
    db $8F, $FF, $05, $01, $0C  ; spawn (5,1) mt$0C Gate_0C
    db $40, $21, $08, $02, $FF  ; NPC noTalk down b=0 spr=$21 (8,2) script=none
    db $FF  ; terminator

Exit_Room_2F_s4:  ; $6AAD — 0 exits
    db $FF  ; terminator

Exit_Room_2F_s5:  ; $6AAE — 0 exits
    db $FF  ; terminator

RoomSub_Boss_Beginning:  ; $6AAF — mt=[$30]
    dw StepBlk_Boss_Beginning_s0  ; screen 0

StepBlk_Boss_Beginning_s0:  ; $6AB1 — RAM=$D976, 2 steps
    dw $D976  ; RAM step counter
    db $0D, $26  ; step 0: layout=$0D bank=$26
    dw Interact_Boss_Beginning_s0  ; → interact/NPC data
    dw Exit_Boss_Beginning_s0  ; → exit data
    db $0E, $26  ; step 1: layout=$0E bank=$26
    dw Interact_Boss_Beginning_s0_v1  ; → interact/NPC data
    dw Exit_Boss_Beginning_s0_v1  ; → exit data

Interact_Boss_Beginning_s0:  ; $6ABF — 2 NPCs
    db $00, $16, $01, $02, $01  ; NPC down b=0 spr=$16 (1,2) script=$01
    db $50, $21, $0A, $00, $FF  ; NPC noTalk left b=0 spr=$21 (10,0) script=none
    db $FF  ; terminator

Interact_Boss_Beginning_s0_v1:  ; $6ACA — empty
    db $FF  ; terminator

Exit_Boss_Beginning_s0:  ; $6ACB — 0 exits
    db $FF  ; terminator

Exit_Boss_Beginning_s0_v1:  ; $6ACC — 1 exits
    db $01, $02, $00, $00, $01, $04, $05  ; exit (1,2)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Boss_Villager:  ; $6AD4 — mt=[$31]
    dw StepBlk_Boss_Villager_s0  ; screen 0

StepBlk_Boss_Villager_s0:  ; $6AD6 — RAM=$D977, 2 steps
    dw $D977  ; RAM step counter
    db $10, $26  ; step 0: layout=$10 bank=$26
    dw Interact_Boss_Villager_s0  ; → interact/NPC data
    dw Exit_Boss_Villager_s0  ; → exit data
    db $11, $26  ; step 1: layout=$11 bank=$26
    dw Interact_Boss_Villager_s0_v1  ; → interact/NPC data
    dw Exit_Boss_Villager_s0_v1  ; → exit data

Interact_Boss_Villager_s0:  ; $6AE4 — 4 spawns, 2 NPCs
    db $8F, $FF, $04, $01, $02  ; spawn (4,1) mt$02 Bazaar
    db $8F, $FF, $05, $01, $02  ; spawn (5,1) mt$02 Bazaar
    db $8F, $FF, $04, $02, $02  ; spawn (4,2) mt$02 Bazaar
    db $8F, $FF, $05, $02, $02  ; spawn (5,2) mt$02 Bazaar
    db $00, $0E, $08, $03, $01  ; NPC down b=0 spr=$0E (8,3) script=$01
    db $70, $21, $00, $00, $FF  ; NPC noTalk right b=0 spr=$21 (0,0) script=none
    db $FF  ; terminator

Interact_Boss_Villager_s0_v1:  ; $6B03 — 1 NPCs
    db $00, $0E, $08, $03, $01  ; NPC down b=0 spr=$0E (8,3) script=$01
    db $FF  ; terminator

Exit_Boss_Villager_s0:  ; $6B09 — 0 exits
    db $FF  ; terminator

Exit_Boss_Villager_s0_v1:  ; $6B0A — 1 exits
    db $04, $01, $00, $00, $01, $04, $05  ; exit (4,1)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Boss_Talisman:  ; $6B12 — mt=[$32]
    dw StepBlk_Boss_Talisman_s0  ; screen 0

StepBlk_Boss_Talisman_s0:  ; $6B14 — RAM=$D978, 2 steps
    dw $D978  ; RAM step counter
    db $16, $24  ; step 0: layout=$16 bank=$24
    dw Interact_Boss_Talisman_s0  ; → interact/NPC data
    dw Exit_Boss_Talisman_s0  ; → exit data
    db $17, $24  ; step 1: layout=$17 bank=$24
    dw Interact_Boss_Talisman_s0_v1  ; → interact/NPC data
    dw Exit_Boss_Talisman_s0_v1  ; → exit data

Interact_Boss_Talisman_s0:  ; $6B22 — 1 spawns, 3 NPCs
    db $90, $FF, $05, $04, $02  ; walk_exit (5,4) mt$02 Bazaar
    db $00, $20, $04, $04, $01  ; NPC down b=0 spr=$20 (4,4) script=$01
    db $40, $39, $08, $00, $FF  ; NPC noTalk down b=0 spr=$39 (8,0) script=none
    db $50, $21, $0A, $01, $FF  ; NPC noTalk left b=0 spr=$21 (10,1) script=none
    db $FF  ; terminator

Interact_Boss_Talisman_s0_v1:  ; $6B37 — empty
    db $FF  ; terminator

Exit_Boss_Talisman_s0:  ; $6B38 — 0 exits
    db $FF  ; terminator

Exit_Boss_Talisman_s0_v1:  ; $6B39 — 1 exits
    db $05, $04, $00, $00, $01, $04, $05  ; exit (5,4)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Boss_Memories:  ; $6B41 — mt=[$33]
    dw StepBlk_Boss_Memories_s0  ; screen 0

StepBlk_Boss_Memories_s0:  ; $6B43 — RAM=$D979, 2 steps
    dw $D979  ; RAM step counter
    db $13, $26  ; step 0: layout=$13 bank=$26
    dw Interact_Boss_Memories_s0  ; → interact/NPC data
    dw Exit_Boss_Memories_s0  ; → exit data
    db $14, $26  ; step 1: layout=$14 bank=$26
    dw Interact_Boss_Memories_s0_v1  ; → interact/NPC data
    dw Exit_Boss_Memories_s0_v1  ; → exit data

Interact_Boss_Memories_s0:  ; $6B51 — 2 NPCs
    db $00, $3C, $04, $04, $01  ; NPC down b=0 spr=$3C (4,4) script=$01
    db $50, $21, $0A, $00, $FF  ; NPC noTalk left b=0 spr=$21 (10,0) script=none
    db $FF  ; terminator

Interact_Boss_Memories_s0_v1:  ; $6B5C — empty
    db $FF  ; terminator

Exit_Boss_Memories_s0:  ; $6B5D — 0 exits
    db $FF  ; terminator

Exit_Boss_Memories_s0_v1:  ; $6B5E — 1 exits
    db $01, $04, $00, $00, $01, $04, $05  ; exit (1,4)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Boss_Bewilder:  ; $6B66 — mt=[$34]
    dw StepBlk_Boss_Bewilder_s0  ; screen 0

StepBlk_Boss_Bewilder_s0:  ; $6B68 — RAM=$D97A, 2 steps
    dw $D97A  ; RAM step counter
    db $16, $26  ; step 0: layout=$16 bank=$26
    dw Interact_Boss_Bewilder_s0  ; → interact/NPC data
    dw Exit_Boss_Bewilder_s0  ; → exit data
    db $17, $26  ; step 1: layout=$17 bank=$26
    dw Interact_Boss_Bewilder_s0_v1  ; → interact/NPC data
    dw Exit_Boss_Bewilder_s0_v1  ; → exit data

Interact_Boss_Bewilder_s0:  ; $6B76 — 7 spawns, 5 NPCs
    db $90, $FF, $07, $01, $07  ; walk_exit (7,1) mt$07 ArenaRooms
    db $90, $FF, $04, $04, $08  ; walk_exit (4,4) mt$08 Gate_08
    db $90, $FF, $05, $05, $09  ; walk_exit (5,5) mt$09 StarryShrine
    db $90, $FF, $01, $03, $0A  ; walk_exit (1,3) mt$0A SecretPassage
    db $8F, $FF, $00, $06, $01  ; spawn (0,6) mt$01 GreatTree
    db $8F, $FF, $04, $01, $02  ; spawn (4,1) mt$02 Bazaar
    db $8F, $FF, $05, $01, $02  ; spawn (5,1) mt$02 Bazaar
    db $06, $25, $01, $02, $03  ; NPC down b=6 spr=$25 (1,2) script=$03
    db $06, $25, $08, $00, $04  ; NPC down b=6 spr=$25 (8,0) script=$04
    db $06, $25, $05, $03, $05  ; NPC down b=6 spr=$25 (5,3) script=$05
    db $06, $25, $06, $06, $06  ; NPC down b=6 spr=$25 (6,6) script=$06
    db $50, $21, $0A, $00, $FF  ; NPC noTalk left b=0 spr=$21 (10,0) script=none
    db $FF  ; terminator

Interact_Boss_Bewilder_s0_v1:  ; $6BB3 — 1 spawns
    db $8F, $FF, $00, $06, $01  ; spawn (0,6) mt$01 GreatTree
    db $FF  ; terminator

Exit_Boss_Bewilder_s0:  ; $6BB9 — 0 exits
    db $FF  ; terminator

Exit_Boss_Bewilder_s0_v1:  ; $6BBA — 1 exits
    db $05, $01, $00, $00, $01, $04, $05  ; exit (5,1)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Room_35:  ; $6BC2 — mt=[$35]
    dw StepBlk_Room_35_s0  ; screen 0

StepBlk_Room_35_s0:  ; $6BC4 — RAM=$D97B, 2 steps
    dw $D97B  ; RAM step counter
    db $19, $26  ; step 0: layout=$19 bank=$26
    dw Interact_Room_35_s0  ; → interact/NPC data
    dw Exit_Room_35_s0  ; → exit data
    db $1A, $26  ; step 1: layout=$1A bank=$26
    dw Interact_Room_35_s0_v1  ; → interact/NPC data
    dw Exit_Room_35_s0_v1  ; → exit data

Interact_Room_35_s0:  ; $6BD2 — 2 spawns, 2 NPCs
    db $8F, $FF, $06, $06, $01  ; spawn (6,6) mt$01 GreatTree
    db $82, $FF, $05, $00, $02  ; spc_82 (5,0) mt$02 Bazaar
    db $10, $1D, $07, $03, $03  ; NPC left b=0 spr=$1D (7,3) script=$03
    db $50, $21, $0A, $00, $FF  ; NPC noTalk left b=0 spr=$21 (10,0) script=none
    db $FF  ; terminator

Interact_Room_35_s0_v1:  ; $6BE7 — 2 spawns
    db $8F, $FF, $06, $06, $01  ; spawn (6,6) mt$01 GreatTree
    db $82, $FF, $05, $00, $02  ; spc_82 (5,0) mt$02 Bazaar
    db $FF  ; terminator

Exit_Room_35_s0:  ; $6BF2 — 0 exits
    db $FF  ; terminator

Exit_Room_35_s0_v1:  ; $6BF3 — 1 exits
    db $07, $03, $00, $00, $01, $04, $05  ; exit (7,3)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Boss_Peace:  ; $6BFB — mt=[$36]
    dw StepBlk_Boss_Peace_s0  ; screen 0

StepBlk_Boss_Peace_s0:  ; $6BFD — RAM=$D97C, 2 steps
    dw $D97C  ; RAM step counter
    db $1C, $26  ; step 0: layout=$1C bank=$26
    dw Interact_Boss_Peace_s0  ; → interact/NPC data
    dw Exit_Boss_Peace_s0  ; → exit data
    db $1D, $26  ; step 1: layout=$1D bank=$26
    dw Interact_Boss_Peace_s0_v1  ; → interact/NPC data
    dw Exit_Boss_Peace_s0_v1  ; → exit data

Interact_Boss_Peace_s0:  ; $6C0B — 9 spawns, 5 NPCs
    db $82, $FF, $06, $02, $01  ; spc_82 (6,2) mt$01 GreatTree
    db $80, $FF, $06, $02, $01  ; spc_80 (6,2) mt$01 GreatTree
    db $82, $FF, $08, $02, $02  ; spc_82 (8,2) mt$02 Bazaar
    db $80, $FF, $08, $02, $02  ; spc_80 (8,2) mt$02 Bazaar
    db $82, $FF, $06, $04, $03  ; spc_82 (6,4) mt$03 GateHub
    db $80, $FF, $06, $04, $03  ; spc_80 (6,4) mt$03 GateHub
    db $82, $FF, $08, $04, $04  ; spc_82 (8,4) mt$04 Farm
    db $80, $FF, $08, $04, $04  ; spc_80 (8,4) mt$04 Farm
    db $8F, $FF, $04, $06, $07  ; spawn (4,6) mt$07 ArenaRooms
    db $00, $12, $03, $01, $05  ; NPC down b=0 spr=$12 (3,1) script=$05
    db $00, $12, $03, $02, $06  ; NPC down b=0 spr=$12 (3,2) script=$06
    db $30, $02, $03, $06, $07  ; NPC right b=0 spr=$02 (3,6) script=$07
    db $20, $17, $08, $05, $08  ; NPC up b=0 spr=$17 (8,5) script=$08
    db $70, $21, $00, $02, $FF  ; NPC noTalk right b=0 spr=$21 (0,2) script=none
    db $FF  ; terminator

Interact_Boss_Peace_s0_v1:  ; $6C52 — 5 spawns, 3 NPCs
    db $8F, $FF, $06, $02, $01  ; spawn (6,2) mt$01 GreatTree
    db $8F, $FF, $08, $02, $02  ; spawn (8,2) mt$02 Bazaar
    db $8F, $FF, $06, $04, $03  ; spawn (6,4) mt$03 GateHub
    db $8F, $FF, $08, $04, $04  ; spawn (8,4) mt$04 Farm
    db $8F, $FF, $04, $06, $07  ; spawn (4,6) mt$07 ArenaRooms
    db $00, $12, $03, $01, $05  ; NPC down b=0 spr=$12 (3,1) script=$05
    db $00, $12, $03, $02, $06  ; NPC down b=0 spr=$12 (3,2) script=$06
    db $30, $02, $03, $06, $07  ; NPC right b=0 spr=$02 (3,6) script=$07
    db $FF  ; terminator

Exit_Boss_Peace_s0:  ; $6C7B — 0 exits
    db $FF  ; terminator

Exit_Boss_Peace_s0_v1:  ; $6C7C — 1 exits
    db $08, $06, $00, $00, $01, $04, $05  ; exit (8,6)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Boss_Bravery:  ; $6C84 — mt=[$37]
    dw StepBlk_Boss_Bravery_s0  ; screen 0

StepBlk_Boss_Bravery_s0:  ; $6C86 — RAM=$D97D, 2 steps
    dw $D97D  ; RAM step counter
    db $1B, $25  ; step 0: layout=$1B bank=$25
    dw Interact_Boss_Bravery_s0  ; → interact/NPC data
    dw Exit_Boss_Bravery_s0  ; → exit data
    db $1C, $25  ; step 1: layout=$1C bank=$25
    dw Interact_Boss_Bravery_s0_v1  ; → interact/NPC data
    dw Exit_Boss_Bravery_s0_v1  ; → exit data

Interact_Boss_Bravery_s0:  ; $6C94 — 7 spawns, 7 NPCs
    db $90, $FF, $04, $04, $03  ; walk_exit (4,4) mt$03 GateHub
    db $90, $FF, $03, $05, $03  ; walk_exit (3,5) mt$03 GateHub
    db $90, $FF, $03, $06, $03  ; walk_exit (3,6) mt$03 GateHub
    db $90, $FF, $06, $04, $04  ; walk_exit (6,4) mt$04 Farm
    db $90, $FF, $06, $05, $04  ; walk_exit (6,5) mt$04 Farm
    db $90, $FF, $05, $06, $04  ; walk_exit (5,6) mt$04 Farm
    db $90, $FF, $05, $03, $02  ; walk_exit (5,3) mt$02 Bazaar
    db $40, $E0, $05, $00, $FF  ; NPC noTalk down b=0 spr=$E0 (5,0) script=none
    db $40, $E1, $05, $00, $FF  ; NPC noTalk down b=0 spr=$E1 (5,0) script=none
    db $40, $E2, $05, $00, $FF  ; NPC noTalk down b=0 spr=$E2 (5,0) script=none
    db $40, $E3, $05, $00, $FF  ; NPC noTalk down b=0 spr=$E3 (5,0) script=none
    db $00, $19, $04, $01, $01  ; NPC down b=0 spr=$19 (4,1) script=$01
    db $60, $15, $04, $08, $FF  ; NPC noTalk up b=0 spr=$15 (4,8) script=none
    db $50, $21, $0A, $01, $FF  ; NPC noTalk left b=0 spr=$21 (10,1) script=none
    db $FF  ; terminator

Interact_Boss_Bravery_s0_v1:  ; $6CDB — 6 spawns, 4 NPCs
    db $90, $FF, $04, $04, $03  ; walk_exit (4,4) mt$03 GateHub
    db $90, $FF, $03, $05, $03  ; walk_exit (3,5) mt$03 GateHub
    db $90, $FF, $03, $06, $03  ; walk_exit (3,6) mt$03 GateHub
    db $90, $FF, $06, $04, $04  ; walk_exit (6,4) mt$04 Farm
    db $90, $FF, $06, $05, $04  ; walk_exit (6,5) mt$04 Farm
    db $90, $FF, $05, $06, $04  ; walk_exit (5,6) mt$04 Farm
    db $40, $E0, $05, $00, $FF  ; NPC noTalk down b=0 spr=$E0 (5,0) script=none
    db $40, $E1, $05, $00, $FF  ; NPC noTalk down b=0 spr=$E1 (5,0) script=none
    db $40, $E2, $05, $00, $FF  ; NPC noTalk down b=0 spr=$E2 (5,0) script=none
    db $40, $E3, $05, $00, $FF  ; NPC noTalk down b=0 spr=$E3 (5,0) script=none
    db $FF  ; terminator

Exit_Boss_Bravery_s0:  ; $6D0E — 0 exits
    db $FF  ; terminator

Exit_Boss_Bravery_s0_v1:  ; $6D0F — 1 exits
    db $04, $01, $00, $00, $01, $04, $05  ; exit (4,1)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Room_38:  ; $6D17 — mt=[$38]
    dw StepBlk_Room_38_s0  ; screen 0

StepBlk_Room_38_s0:  ; $6D19 — RAM=$D97E, 2 steps
    dw $D97E  ; RAM step counter
    db $01, $25  ; step 0: layout=$01 bank=$25
    dw Interact_Room_38_s0  ; → interact/NPC data
    dw Exit_Room_38_s0  ; → exit data
    db $02, $25  ; step 1: layout=$02 bank=$25
    dw Interact_Room_38_s0_v1  ; → interact/NPC data
    dw Exit_Room_38_s0_v1  ; → exit data

Interact_Room_38_s0:  ; $6D27 — 15 spawns, 7 NPCs
    db $90, $FF, $04, $00, $02  ; walk_exit (4,0) mt$02 Bazaar
    db $90, $FF, $05, $00, $03  ; walk_exit (5,0) mt$03 GateHub
    db $90, $FF, $06, $00, $04  ; walk_exit (6,0) mt$04 Farm
    db $90, $FF, $01, $01, $05  ; walk_exit (1,1) mt$05 Stable
    db $90, $FF, $05, $02, $06  ; walk_exit (5,2) mt$06 ArenaLobby
    db $90, $FF, $08, $02, $07  ; walk_exit (8,2) mt$07 ArenaRooms
    db $90, $FF, $02, $04, $08  ; walk_exit (2,4) mt$08 Gate_08
    db $90, $FF, $03, $04, $09  ; walk_exit (3,4) mt$09 StarryShrine
    db $90, $FF, $04, $04, $0A  ; walk_exit (4,4) mt$0A SecretPassage
    db $90, $FF, $07, $04, $0B  ; walk_exit (7,4) mt$0B Castle_0B
    db $90, $FF, $08, $04, $0C  ; walk_exit (8,4) mt$0C Gate_0C
    db $90, $FF, $07, $05, $0D  ; walk_exit (7,5) mt$0D OldManGate
    db $90, $FF, $01, $06, $0E  ; walk_exit (1,6) mt$0E Castle_0E
    db $90, $FF, $05, $06, $0F  ; walk_exit (5,6) mt$0F Room_0F
    db $90, $FF, $06, $02, $10  ; walk_exit (6,2) mt$10 CopycatRoom
    db $40, $E0, $08, $00, $FF  ; NPC noTalk down b=0 spr=$E0 (8,0) script=none
    db $40, $E1, $08, $00, $FF  ; NPC noTalk down b=0 spr=$E1 (8,0) script=none
    db $40, $E2, $08, $00, $FF  ; NPC noTalk down b=0 spr=$E2 (8,0) script=none
    db $40, $E3, $08, $00, $FF  ; NPC noTalk down b=0 spr=$E3 (8,0) script=none
    db $40, $39, $02, $00, $FF  ; NPC noTalk down b=0 spr=$39 (2,0) script=none
    db $00, $1E, $08, $05, $01  ; NPC down b=0 spr=$1E (8,5) script=$01
    db $70, $21, $00, $00, $FF  ; NPC noTalk right b=0 spr=$21 (0,0) script=none
    db $FF  ; terminator

Interact_Room_38_s0_v1:  ; $6D96 — 14 spawns, 4 NPCs
    db $90, $FF, $04, $00, $02  ; walk_exit (4,0) mt$02 Bazaar
    db $90, $FF, $05, $00, $03  ; walk_exit (5,0) mt$03 GateHub
    db $90, $FF, $06, $00, $04  ; walk_exit (6,0) mt$04 Farm
    db $90, $FF, $01, $01, $05  ; walk_exit (1,1) mt$05 Stable
    db $90, $FF, $05, $02, $06  ; walk_exit (5,2) mt$06 ArenaLobby
    db $90, $FF, $08, $02, $07  ; walk_exit (8,2) mt$07 ArenaRooms
    db $90, $FF, $02, $04, $08  ; walk_exit (2,4) mt$08 Gate_08
    db $90, $FF, $03, $04, $09  ; walk_exit (3,4) mt$09 StarryShrine
    db $90, $FF, $04, $04, $0A  ; walk_exit (4,4) mt$0A SecretPassage
    db $90, $FF, $07, $04, $0B  ; walk_exit (7,4) mt$0B Castle_0B
    db $90, $FF, $08, $04, $0C  ; walk_exit (8,4) mt$0C Gate_0C
    db $90, $FF, $07, $05, $0D  ; walk_exit (7,5) mt$0D OldManGate
    db $90, $FF, $01, $06, $0E  ; walk_exit (1,6) mt$0E Castle_0E
    db $90, $FF, $05, $06, $0F  ; walk_exit (5,6) mt$0F Room_0F
    db $40, $E0, $08, $00, $FF  ; NPC noTalk down b=0 spr=$E0 (8,0) script=none
    db $40, $E1, $08, $00, $FF  ; NPC noTalk down b=0 spr=$E1 (8,0) script=none
    db $40, $E2, $08, $00, $FF  ; NPC noTalk down b=0 spr=$E2 (8,0) script=none
    db $40, $E3, $08, $00, $FF  ; NPC noTalk down b=0 spr=$E3 (8,0) script=none
    db $FF  ; terminator

Exit_Room_38_s0:  ; $6DF1 — 0 exits
    db $FF  ; terminator

Exit_Room_38_s0_v1:  ; $6DF2 — 1 exits
    db $08, $05, $00, $00, $01, $04, $05  ; exit (8,5)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Room_39:  ; $6DFA — mt=[$39]
    dw StepBlk_Room_39_s0  ; screen 0

StepBlk_Room_39_s0:  ; $6DFC — RAM=$D97F, 2 steps
    dw $D97F  ; RAM step counter
    db $04, $23  ; step 0: layout=$04 bank=$23
    dw Interact_Room_39_s0  ; → interact/NPC data
    dw Exit_Room_39_s0  ; → exit data
    db $05, $23  ; step 1: layout=$05 bank=$23
    dw Interact_Room_39_s0_v1  ; → interact/NPC data
    dw Exit_Room_39_s0_v1  ; → exit data

Interact_Room_39_s0:  ; $6E0A — 3 spawns, 2 NPCs
    db $90, $FF, $06, $06, $04  ; walk_exit (6,6) mt$04 Farm
    db $8F, $FF, $08, $06, $01  ; spawn (8,6) mt$01 GreatTree
    db $8F, $FF, $07, $04, $02  ; spawn (7,4) mt$02 Bazaar
    db $00, $2C, $01, $01, $03  ; NPC down b=0 spr=$2C (1,1) script=$03
    db $50, $21, $0A, $00, $FF  ; NPC noTalk left b=0 spr=$21 (10,0) script=none
    db $FF  ; terminator

Interact_Room_39_s0_v1:  ; $6E24 — 1 spawns
    db $8F, $FF, $07, $04, $02  ; spawn (7,4) mt$02 Bazaar
    db $FF  ; terminator

Exit_Room_39_s0:  ; $6E2A — 0 exits
    db $FF  ; terminator

Exit_Room_39_s0_v1:  ; $6E2B — 1 exits
    db $07, $06, $00, $00, $01, $04, $05  ; exit (7,6)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Room_3A:  ; $6E33 — mt=[$3A]
    dw StepBlk_Room_3A_s0  ; screen 0

StepBlk_Room_3A_s0:  ; $6E35 — RAM=$D980, 2 steps
    dw $D980  ; RAM step counter
    db $04, $25  ; step 0: layout=$04 bank=$25
    dw Interact_Room_3A_s0  ; → interact/NPC data
    dw Exit_Room_3A_s0  ; → exit data
    db $05, $25  ; step 1: layout=$05 bank=$25
    dw Interact_Room_3A_s0_v1  ; → interact/NPC data
    dw Exit_Room_3A_s0_v1  ; → exit data

Interact_Room_3A_s0:  ; $6E43 — 22 spawns, 6 NPCs
    db $90, $FF, $02, $02, $02  ; walk_exit (2,2) mt$02 Bazaar
    db $90, $FF, $02, $03, $02  ; walk_exit (2,3) mt$02 Bazaar
    db $90, $FF, $02, $05, $02  ; walk_exit (2,5) mt$02 Bazaar
    db $90, $FF, $02, $06, $02  ; walk_exit (2,6) mt$02 Bazaar
    db $90, $FF, $04, $02, $02  ; walk_exit (4,2) mt$02 Bazaar
    db $90, $FF, $04, $04, $02  ; walk_exit (4,4) mt$02 Bazaar
    db $90, $FF, $04, $06, $02  ; walk_exit (4,6) mt$02 Bazaar
    db $90, $FF, $06, $02, $02  ; walk_exit (6,2) mt$02 Bazaar
    db $90, $FF, $06, $03, $02  ; walk_exit (6,3) mt$02 Bazaar
    db $90, $FF, $06, $05, $02  ; walk_exit (6,5) mt$02 Bazaar
    db $90, $FF, $06, $06, $02  ; walk_exit (6,6) mt$02 Bazaar
    db $90, $FF, $08, $02, $02  ; walk_exit (8,2) mt$02 Bazaar
    db $90, $FF, $08, $03, $02  ; walk_exit (8,3) mt$02 Bazaar
    db $90, $FF, $08, $04, $02  ; walk_exit (8,4) mt$02 Bazaar
    db $90, $FF, $08, $05, $02  ; walk_exit (8,5) mt$02 Bazaar
    db $90, $FF, $08, $06, $02  ; walk_exit (8,6) mt$02 Bazaar
    db $90, $FF, $01, $05, $03  ; walk_exit (1,5) mt$03 GateHub
    db $90, $FF, $02, $04, $04  ; walk_exit (2,4) mt$04 Farm
    db $90, $FF, $05, $03, $05  ; walk_exit (5,3) mt$05 Stable
    db $90, $FF, $05, $04, $06  ; walk_exit (5,4) mt$06 ArenaLobby
    db $90, $FF, $07, $03, $07  ; walk_exit (7,3) mt$07 ArenaRooms
    db $90, $FF, $07, $05, $08  ; walk_exit (7,5) mt$08 Gate_08
    db $40, $E0, $01, $00, $FF  ; NPC noTalk down b=0 spr=$E0 (1,0) script=none
    db $40, $E1, $01, $00, $FF  ; NPC noTalk down b=0 spr=$E1 (1,0) script=none
    db $40, $E2, $01, $00, $FF  ; NPC noTalk down b=0 spr=$E2 (1,0) script=none
    db $40, $E3, $01, $00, $FF  ; NPC noTalk down b=0 spr=$E3 (1,0) script=none
    db $00, $18, $01, $01, $01  ; NPC down b=0 spr=$18 (1,1) script=$01
    db $50, $21, $0A, $00, $FF  ; NPC noTalk left b=0 spr=$21 (10,0) script=none
    db $FF  ; terminator

Interact_Room_3A_s0_v1:  ; $6ED0 — 16 spawns, 4 NPCs
    db $90, $FF, $02, $02, $02  ; walk_exit (2,2) mt$02 Bazaar
    db $90, $FF, $02, $03, $02  ; walk_exit (2,3) mt$02 Bazaar
    db $90, $FF, $02, $05, $02  ; walk_exit (2,5) mt$02 Bazaar
    db $90, $FF, $02, $06, $02  ; walk_exit (2,6) mt$02 Bazaar
    db $90, $FF, $04, $02, $02  ; walk_exit (4,2) mt$02 Bazaar
    db $90, $FF, $04, $04, $02  ; walk_exit (4,4) mt$02 Bazaar
    db $90, $FF, $04, $06, $02  ; walk_exit (4,6) mt$02 Bazaar
    db $90, $FF, $06, $02, $02  ; walk_exit (6,2) mt$02 Bazaar
    db $90, $FF, $06, $03, $02  ; walk_exit (6,3) mt$02 Bazaar
    db $90, $FF, $06, $05, $02  ; walk_exit (6,5) mt$02 Bazaar
    db $90, $FF, $06, $06, $02  ; walk_exit (6,6) mt$02 Bazaar
    db $90, $FF, $08, $02, $02  ; walk_exit (8,2) mt$02 Bazaar
    db $90, $FF, $08, $03, $02  ; walk_exit (8,3) mt$02 Bazaar
    db $90, $FF, $08, $04, $02  ; walk_exit (8,4) mt$02 Bazaar
    db $90, $FF, $08, $05, $02  ; walk_exit (8,5) mt$02 Bazaar
    db $90, $FF, $08, $06, $02  ; walk_exit (8,6) mt$02 Bazaar
    db $40, $E0, $01, $00, $FF  ; NPC noTalk down b=0 spr=$E0 (1,0) script=none
    db $40, $E1, $01, $00, $FF  ; NPC noTalk down b=0 spr=$E1 (1,0) script=none
    db $40, $E2, $01, $00, $FF  ; NPC noTalk down b=0 spr=$E2 (1,0) script=none
    db $40, $E3, $01, $00, $FF  ; NPC noTalk down b=0 spr=$E3 (1,0) script=none
    db $FF  ; terminator

Exit_Room_3A_s0:  ; $6F35 — 0 exits
    db $FF  ; terminator

Exit_Room_3A_s0_v1:  ; $6F36 — 1 exits
    db $01, $01, $00, $00, $01, $04, $05  ; exit (1,1)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Room_3B:  ; $6F3E — mt=[$3B]
    dw StepBlk_Room_3B_s0  ; screen 0

StepBlk_Room_3B_s0:  ; $6F40 — RAM=$D981, 2 steps
    dw $D981  ; RAM step counter
    db $07, $24  ; step 0: layout=$07 bank=$24
    dw Interact_Room_3B_s0  ; → interact/NPC data
    dw Exit_Room_3B_s0  ; → exit data
    db $08, $24  ; step 1: layout=$08 bank=$24
    dw Interact_Room_3B_s0_v1  ; → interact/NPC data
    dw Exit_Room_3B_s0_v1  ; → exit data

Interact_Room_3B_s0:  ; $6F4E — 2 NPCs
    db $05, $1B, $03, $04, $01  ; NPC down b=5 spr=$1B (3,4) script=$01
    db $50, $21, $0A, $01, $FF  ; NPC noTalk left b=0 spr=$21 (10,1) script=none
    db $FF  ; terminator

Interact_Room_3B_s0_v1:  ; $6F59 — empty
    db $FF  ; terminator

Exit_Room_3B_s0:  ; $6F5A — 0 exits
    db $FF  ; terminator

Exit_Room_3B_s0_v1:  ; $6F5B — 1 exits
    db $05, $03, $00, $00, $01, $04, $05  ; exit (5,3)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Room_3C:  ; $6F63 — mt=[$3C]
    dw StepBlk_Room_3C_s0  ; screen 0

StepBlk_Room_3C_s0:  ; $6F65 — RAM=$D982, 3 steps
    dw $D982  ; RAM step counter
    db $07, $23  ; step 0: layout=$07 bank=$23
    dw Interact_Room_3C_s0  ; → interact/NPC data
    dw Exit_Room_3C_s0  ; → exit data
    db $09, $23  ; step 1: layout=$09 bank=$23
    dw Interact_Room_3C_s0  ; → interact/NPC data
    dw Exit_Room_3C_s0_v1  ; → exit data
    db $08, $23  ; step 2: layout=$08 bank=$23
    dw Interact_Room_3C_s0_v1  ; → interact/NPC data
    dw Exit_Room_3C_s0_v1  ; → exit data

Interact_Room_3C_s0:  ; $6F79 — 7 spawns, 5 NPCs
    db $8F, $FF, $04, $02, $01  ; spawn (4,2) mt$01 GreatTree
    db $8F, $FF, $02, $03, $02  ; spawn (2,3) mt$02 Bazaar
    db $8F, $FF, $01, $04, $03  ; spawn (1,4) mt$03 GateHub
    db $8F, $FF, $08, $04, $04  ; spawn (8,4) mt$04 Farm
    db $8F, $FF, $06, $05, $05  ; spawn (6,5) mt$05 Stable
    db $8F, $FF, $03, $03, $06  ; spawn (3,3) mt$06 ArenaLobby
    db $8F, $FF, $07, $04, $07  ; spawn (7,4) mt$07 ArenaRooms
    db $60, $15, $02, $06, $FF  ; NPC noTalk up b=0 spr=$15 (2,6) script=none
    db $70, $21, $00, $00, $FF  ; NPC noTalk right b=0 spr=$21 (0,0) script=none
    db $00, $23, $05, $01, $08  ; NPC down b=0 spr=$23 (5,1) script=$08
    db $00, $FF, $05, $01, $08  ; NPC down b=0 spr=$FF (5,1) script=$08
    db $00, $FF, $06, $01, $08  ; NPC down b=0 spr=$FF (6,1) script=$08
    db $FF  ; terminator

Interact_Room_3C_s0_v1:  ; $6FB6 — 7 spawns
    db $8F, $FF, $04, $02, $01  ; spawn (4,2) mt$01 GreatTree
    db $8F, $FF, $02, $03, $02  ; spawn (2,3) mt$02 Bazaar
    db $8F, $FF, $01, $04, $03  ; spawn (1,4) mt$03 GateHub
    db $8F, $FF, $08, $04, $04  ; spawn (8,4) mt$04 Farm
    db $8F, $FF, $06, $05, $05  ; spawn (6,5) mt$05 Stable
    db $8F, $FF, $03, $03, $06  ; spawn (3,3) mt$06 ArenaLobby
    db $8F, $FF, $07, $04, $07  ; spawn (7,4) mt$07 ArenaRooms
    db $FF  ; terminator

Exit_Room_3C_s0:  ; $6FDA — 0 exits
    db $FF  ; terminator

Exit_Room_3C_s0_v1:  ; $6FDB — 1 exits
    db $06, $01, $00, $00, $01, $04, $05  ; exit (6,1)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Room_3D:  ; $6FE3 — mt=[$3D]
    dw StepBlk_Room_3D_s0  ; screen 0

StepBlk_Room_3D_s0:  ; $6FE5 — RAM=$D983, 2 steps
    dw $D983  ; RAM step counter
    db $07, $25  ; step 0: layout=$07 bank=$25
    dw Interact_Room_3D_s0  ; → interact/NPC data
    dw Exit_Room_3D_s0  ; → exit data
    db $07, $25  ; step 1: layout=$07 bank=$25
    dw Interact_Room_3D_s0_v1  ; → interact/NPC data
    dw Exit_Room_3D_s0  ; → exit data

Interact_Room_3D_s0:  ; $6FF3 — 2 spawns, 5 NPCs
    db $90, $FF, $04, $04, $01  ; walk_exit (4,4) mt$01 GreatTree
    db $90, $FF, $05, $04, $02  ; walk_exit (5,4) mt$02 Bazaar
    db $40, $E1, $04, $04, $FF  ; NPC noTalk down b=0 spr=$E1 (4,4) script=none
    db $40, $5F, $04, $02, $FF  ; NPC noTalk down b=0 spr=$5F (4,2) script=none
    db $40, $05, $04, $02, $FF  ; NPC noTalk down b=0 spr=$05 (4,2) script=none
    db $40, $39, $00, $00, $FF  ; NPC noTalk down b=0 spr=$39 (0,0) script=none
    db $60, $E0, $05, $04, $FF  ; NPC noTalk up b=0 spr=$E0 (5,4) script=none
    db $FF  ; terminator

Interact_Room_3D_s0_v1:  ; $7017 — 2 spawns
    db $90, $FF, $04, $04, $03  ; walk_exit (4,4) mt$03 GateHub
    db $90, $FF, $05, $04, $03  ; walk_exit (5,4) mt$03 GateHub
    db $FF  ; terminator

Exit_Room_3D_s0:  ; $7022 — 0 exits
    db $FF  ; terminator

RoomSub_Room_3E:  ; $7023 — mt=[$3E]
    dw StepBlk_Room_3E_s0  ; screen 0

StepBlk_Room_3E_s0:  ; $7025 — RAM=$D984, 2 steps
    dw $D984  ; RAM step counter
    db $09, $25  ; step 0: layout=$09 bank=$25
    dw Interact_Room_3E_s0  ; → interact/NPC data
    dw Exit_Room_3E_s0  ; → exit data
    db $0A, $25  ; step 1: layout=$0A bank=$25
    dw Interact_Room_3E_s0_v1  ; → interact/NPC data
    dw Exit_Room_3E_s0_v1  ; → exit data

Interact_Room_3E_s0:  ; $7033 — 4 NPCs
    db $50, $21, $0A, $01, $FF  ; NPC noTalk left b=0 spr=$21 (10,1) script=none
    db $00, $28, $04, $05, $01  ; NPC down b=0 spr=$28 (4,5) script=$01
    db $00, $FF, $04, $04, $01  ; NPC down b=0 spr=$FF (4,4) script=$01
    db $00, $FF, $05, $04, $01  ; NPC down b=0 spr=$FF (5,4) script=$01
    db $FF  ; terminator

Interact_Room_3E_s0_v1:  ; $7048 — empty
    db $FF  ; terminator

Exit_Room_3E_s0:  ; $7049 — 0 exits
    db $FF  ; terminator

Exit_Room_3E_s0_v1:  ; $704A — 1 exits
    db $01, $03, $00, $00, $01, $04, $05  ; exit (1,3)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Room_3F:  ; $7052 — mt=[$3F]
    dw StepBlk_Room_3F_s0  ; screen 0

StepBlk_Room_3F_s0:  ; $7054 — RAM=$D985, 2 steps
    dw $D985  ; RAM step counter
    db $01, $24  ; step 0: layout=$01 bank=$24
    dw Interact_Room_3F_s0  ; → interact/NPC data
    dw Exit_Room_3F_s0  ; → exit data
    db $02, $24  ; step 1: layout=$02 bank=$24
    dw Interact_Room_3F_s0_v1  ; → interact/NPC data
    dw Exit_Room_3F_s0_v1  ; → exit data

Interact_Room_3F_s0:  ; $7062 — 2 NPCs
    db $00, $2B, $01, $05, $01  ; NPC down b=0 spr=$2B (1,5) script=$01
    db $50, $21, $0A, $00, $FF  ; NPC noTalk left b=0 spr=$21 (10,0) script=none
    db $FF  ; terminator

Interact_Room_3F_s0_v1:  ; $706D — empty
    db $FF  ; terminator

Exit_Room_3F_s0:  ; $706E — 0 exits
    db $FF  ; terminator

Exit_Room_3F_s0_v1:  ; $706F — 1 exits
    db $01, $05, $00, $00, $01, $04, $05  ; exit (1,5)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Room_40:  ; $7077 — mt=[$40]
    dw StepBlk_Room_40_s0  ; screen 0

StepBlk_Room_40_s0:  ; $7079 — RAM=$D986, 1 steps
    dw $D986  ; RAM step counter
    db $16, $25  ; step 0: layout=$16 bank=$25
    dw Interact_Room_40_s0  ; → interact/NPC data
    dw Exit_Room_40_s0  ; → exit data

Interact_Room_40_s0:  ; $7081 — 8 spawns, 3 NPCs
    db $90, $FF, $01, $01, $06  ; walk_exit (1,1) mt$06 ArenaLobby
    db $90, $FF, $02, $01, $06  ; walk_exit (2,1) mt$06 ArenaLobby
    db $90, $FF, $04, $01, $07  ; walk_exit (4,1) mt$07 ArenaRooms
    db $90, $FF, $05, $01, $07  ; walk_exit (5,1) mt$07 ArenaRooms
    db $90, $FF, $07, $01, $08  ; walk_exit (7,1) mt$08 Gate_08
    db $90, $FF, $08, $01, $08  ; walk_exit (8,1) mt$08 Gate_08
    db $8F, $FF, $03, $03, $01  ; spawn (3,3) mt$01 GreatTree
    db $8F, $FF, $06, $03, $02  ; spawn (6,3) mt$02 Bazaar
    db $00, $05, $02, $02, $03  ; NPC down b=0 spr=$05 (2,2) script=$03
    db $00, $05, $05, $02, $04  ; NPC down b=0 spr=$05 (5,2) script=$04
    db $00, $05, $08, $02, $05  ; NPC down b=0 spr=$05 (8,2) script=$05
    db $FF  ; terminator

Exit_Room_40_s0:  ; $70B9 — 6 exits
    db $01, $01, $41, $00, $00, $01, $06  ; exit (1,1)→mt$41 Room_41  scr=0 spawn(1,6)
    db $02, $01, $41, $00, $00, $02, $06  ; exit (2,1)→mt$41 Room_41  scr=0 spawn(2,6)
    db $04, $01, $41, $00, $00, $04, $06  ; exit (4,1)→mt$41 Room_41  scr=0 spawn(4,6)
    db $05, $01, $41, $00, $00, $05, $06  ; exit (5,1)→mt$41 Room_41  scr=0 spawn(5,6)
    db $07, $01, $41, $00, $00, $07, $06  ; exit (7,1)→mt$41 Room_41  scr=0 spawn(7,6)
    db $08, $01, $41, $00, $00, $08, $06  ; exit (8,1)→mt$41 Room_41  scr=0 spawn(8,6)
    db $FF  ; terminator

RoomSub_Room_41:  ; $70E4 — mt=[$41]
    dw StepBlk_Room_41_s0  ; screen 0

StepBlk_Room_41_s0:  ; $70E6 — RAM=$D987, 4 steps
    dw $D987  ; RAM step counter
    db $18, $25  ; step 0: layout=$18 bank=$25
    dw Interact_Room_41_s0  ; → interact/NPC data
    dw Exit_Room_41_s0  ; → exit data
    db $18, $25  ; step 1: layout=$18 bank=$25
    dw Interact_Room_41_s0_v1  ; → interact/NPC data
    dw Exit_Room_41_s0  ; → exit data
    db $18, $25  ; step 2: layout=$18 bank=$25
    dw Interact_Room_41_s0_v2  ; → interact/NPC data
    dw Exit_Room_41_s0  ; → exit data
    db $19, $25  ; step 3: layout=$19 bank=$25
    dw $4B42  ; → interact/NPC data
    dw Exit_Room_41_s0_v1  ; → exit data

Interact_Room_41_s0:  ; $7100 — 2 NPCs
    db $00, $1C, $01, $04, $01  ; NPC down b=0 spr=$1C (1,4) script=$01
    db $50, $21, $0A, $00, $FF  ; NPC noTalk left b=0 spr=$21 (10,0) script=none
    db $FF  ; terminator

Interact_Room_41_s0_v1:  ; $710B — 4 NPCs
    db $00, $22, $04, $03, $02  ; NPC down b=0 spr=$22 (4,3) script=$02
    db $50, $21, $0A, $00, $FF  ; NPC noTalk left b=0 spr=$21 (10,0) script=none
    db $00, $FF, $04, $03, $02  ; NPC down b=0 spr=$FF (4,3) script=$02
    db $00, $FF, $05, $03, $02  ; NPC down b=0 spr=$FF (5,3) script=$02
    db $FF  ; terminator

Interact_Room_41_s0_v2:  ; $7120 — 2 NPCs
    db $00, $3E, $07, $04, $03  ; NPC down b=0 spr=$3E (7,4) script=$03
    db $50, $21, $0A, $00, $FF  ; NPC noTalk left b=0 spr=$21 (10,0) script=none
    db $FF  ; terminator

Exit_Room_41_s0:  ; $712B — 0 exits
    db $FF  ; terminator

Exit_Room_41_s0_v1:  ; $712C — 3 exits
    db $01, $02, $00, $00, $01, $04, $05  ; exit (1,2)→mt$00 Castle  scr=1 spawn(4,5)
    db $04, $02, $00, $00, $01, $04, $05  ; exit (4,2)→mt$00 Castle  scr=1 spawn(4,5)
    db $07, $02, $00, $00, $01, $04, $05  ; exit (7,2)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Labyrinth:  ; $7142 — mt=[$42]
    dw StepBlk_Labyrinth_s0  ; screen 0

RoomSub_LabyrinthFinal:  ; $7144 — mt=[$60, $65, $66, $67]
    dw StepBlk_Labyrinth_s1  ; screen 1

StepBlk_Labyrinth_s0:  ; $7146 — RAM=$D988, 10 steps
    dw $D988  ; RAM step counter
    db $13, $24  ; step 0: layout=$13 bank=$24
    dw Interact_Labyrinth_s0  ; → interact/NPC data
    dw Exit_Labyrinth_s0_v1  ; → exit data
    db $13, $24  ; step 1: layout=$13 bank=$24
    dw Interact_Labyrinth_s0_v1  ; → interact/NPC data
    dw Exit_Labyrinth_s0  ; → exit data
    db $13, $24  ; step 2: layout=$13 bank=$24
    dw Interact_Labyrinth_s0_v2  ; → interact/NPC data
    dw Exit_Labyrinth_s0  ; → exit data
    db $13, $24  ; step 3: layout=$13 bank=$24
    dw Interact_Labyrinth_s0_v3  ; → interact/NPC data
    dw Exit_Labyrinth_s0_v2  ; → exit data
    db $13, $24  ; step 4: layout=$13 bank=$24
    dw Interact_Labyrinth_s0_v4  ; → interact/NPC data
    dw Exit_Labyrinth_s0  ; → exit data
    db $13, $24  ; step 5: layout=$13 bank=$24
    dw Interact_Labyrinth_s0_v5  ; → interact/NPC data
    dw Exit_Labyrinth_s0_v3  ; → exit data
    db $13, $24  ; step 6: layout=$13 bank=$24
    dw Interact_Labyrinth_s0_v6  ; → interact/NPC data
    dw Exit_Labyrinth_s0  ; → exit data
    db $13, $24  ; step 7: layout=$13 bank=$24
    dw Interact_Labyrinth_s0_v7  ; → interact/NPC data
    dw Exit_Labyrinth_s0  ; → exit data
    db $13, $24  ; step 8: layout=$13 bank=$24
    dw Interact_Labyrinth_s0_v8  ; → interact/NPC data
    dw Exit_Labyrinth_s0  ; → exit data
    db $13, $24  ; step 9: layout=$13 bank=$24
    dw Interact_Labyrinth_s0_v9  ; → interact/NPC data
    dw Exit_Labyrinth_s0_v4  ; → exit data

StepBlk_Labyrinth_s1:  ; $7184 — RAM=$D989, 2 steps
    dw $D989  ; RAM step counter
    db $14, $24  ; step 0: layout=$14 bank=$24
    dw Interact_Labyrinth_s1  ; → interact/NPC data
    dw Exit_Labyrinth_s1  ; → exit data
    db $14, $24  ; step 1: layout=$14 bank=$24
    dw Interact_Labyrinth_s1_v1  ; → interact/NPC data
    dw Exit_Labyrinth_s1  ; → exit data

Interact_Labyrinth_s0:  ; $7192 — 9 spawns
    db $90, $FF, $04, $04, $0F  ; walk_exit (4,4) mt$0F Room_0F
    db $90, $FF, $02, $07, $01  ; walk_exit (2,7) mt$01 GreatTree
    db $90, $FF, $07, $07, $01  ; walk_exit (7,7) mt$01 GreatTree
    db $90, $FF, $09, $02, $0F  ; walk_exit (9,2) mt$0F Room_0F
    db $90, $FF, $09, $05, $0F  ; walk_exit (9,5) mt$0F Room_0F
    db $90, $FF, $02, $00, $04  ; walk_exit (2,0) mt$04 Farm
    db $90, $FF, $07, $00, $04  ; walk_exit (7,0) mt$04 Farm
    db $90, $FF, $00, $02, $0F  ; walk_exit (0,2) mt$0F Room_0F
    db $90, $FF, $00, $05, $0F  ; walk_exit (0,5) mt$0F Room_0F
    db $FF  ; terminator

Interact_Labyrinth_s0_v1:  ; $71C0 — 9 spawns
    db $90, $FF, $04, $04, $0F  ; walk_exit (4,4) mt$0F Room_0F
    db $90, $FF, $02, $07, $02  ; walk_exit (2,7) mt$02 Bazaar
    db $90, $FF, $07, $07, $02  ; walk_exit (7,7) mt$02 Bazaar
    db $90, $FF, $09, $02, $0F  ; walk_exit (9,2) mt$0F Room_0F
    db $90, $FF, $09, $05, $0F  ; walk_exit (9,5) mt$0F Room_0F
    db $90, $FF, $02, $00, $0F  ; walk_exit (2,0) mt$0F Room_0F
    db $90, $FF, $07, $00, $0F  ; walk_exit (7,0) mt$0F Room_0F
    db $90, $FF, $00, $02, $0F  ; walk_exit (0,2) mt$0F Room_0F
    db $90, $FF, $00, $05, $0F  ; walk_exit (0,5) mt$0F Room_0F
    db $FF  ; terminator

Interact_Labyrinth_s0_v2:  ; $71EE — 9 spawns
    db $90, $FF, $04, $04, $0F  ; walk_exit (4,4) mt$0F Room_0F
    db $90, $FF, $02, $07, $03  ; walk_exit (2,7) mt$03 GateHub
    db $90, $FF, $07, $07, $03  ; walk_exit (7,7) mt$03 GateHub
    db $90, $FF, $09, $02, $0F  ; walk_exit (9,2) mt$0F Room_0F
    db $90, $FF, $09, $05, $0F  ; walk_exit (9,5) mt$0F Room_0F
    db $90, $FF, $02, $00, $0F  ; walk_exit (2,0) mt$0F Room_0F
    db $90, $FF, $07, $00, $0F  ; walk_exit (7,0) mt$0F Room_0F
    db $90, $FF, $00, $02, $0F  ; walk_exit (0,2) mt$0F Room_0F
    db $90, $FF, $00, $05, $0F  ; walk_exit (0,5) mt$0F Room_0F
    db $FF  ; terminator

Interact_Labyrinth_s0_v3:  ; $721C — 9 spawns
    db $90, $FF, $04, $04, $0F  ; walk_exit (4,4) mt$0F Room_0F
    db $90, $FF, $02, $07, $0F  ; walk_exit (2,7) mt$0F Room_0F
    db $90, $FF, $07, $07, $0F  ; walk_exit (7,7) mt$0F Room_0F
    db $90, $FF, $09, $02, $0F  ; walk_exit (9,2) mt$0F Room_0F
    db $90, $FF, $09, $05, $03  ; walk_exit (9,5) mt$03 GateHub
    db $90, $FF, $02, $00, $0F  ; walk_exit (2,0) mt$0F Room_0F
    db $90, $FF, $07, $00, $0F  ; walk_exit (7,0) mt$0F Room_0F
    db $90, $FF, $00, $02, $0F  ; walk_exit (0,2) mt$0F Room_0F
    db $90, $FF, $00, $05, $0F  ; walk_exit (0,5) mt$0F Room_0F
    db $FF  ; terminator

Interact_Labyrinth_s0_v4:  ; $724A — 9 spawns
    db $90, $FF, $04, $04, $0F  ; walk_exit (4,4) mt$0F Room_0F
    db $90, $FF, $02, $07, $0F  ; walk_exit (2,7) mt$0F Room_0F
    db $90, $FF, $07, $07, $0F  ; walk_exit (7,7) mt$0F Room_0F
    db $90, $FF, $09, $02, $0F  ; walk_exit (9,2) mt$0F Room_0F
    db $90, $FF, $09, $05, $0F  ; walk_exit (9,5) mt$0F Room_0F
    db $90, $FF, $02, $00, $05  ; walk_exit (2,0) mt$05 Stable
    db $90, $FF, $07, $00, $05  ; walk_exit (7,0) mt$05 Stable
    db $90, $FF, $00, $02, $0F  ; walk_exit (0,2) mt$0F Room_0F
    db $90, $FF, $00, $05, $0F  ; walk_exit (0,5) mt$0F Room_0F
    db $FF  ; terminator

Interact_Labyrinth_s0_v5:  ; $7278 — 9 spawns
    db $90, $FF, $04, $04, $0F  ; walk_exit (4,4) mt$0F Room_0F
    db $90, $FF, $02, $07, $0F  ; walk_exit (2,7) mt$0F Room_0F
    db $90, $FF, $07, $07, $0F  ; walk_exit (7,7) mt$0F Room_0F
    db $90, $FF, $09, $02, $0F  ; walk_exit (9,2) mt$0F Room_0F
    db $90, $FF, $09, $05, $0F  ; walk_exit (9,5) mt$0F Room_0F
    db $90, $FF, $02, $00, $06  ; walk_exit (2,0) mt$06 ArenaLobby
    db $90, $FF, $07, $00, $06  ; walk_exit (7,0) mt$06 ArenaLobby
    db $90, $FF, $00, $02, $0F  ; walk_exit (0,2) mt$0F Room_0F
    db $90, $FF, $00, $05, $05  ; walk_exit (0,5) mt$05 Stable
    db $FF  ; terminator

Interact_Labyrinth_s0_v6:  ; $72A6 — 9 spawns
    db $90, $FF, $04, $04, $0F  ; walk_exit (4,4) mt$0F Room_0F
    db $90, $FF, $02, $07, $0F  ; walk_exit (2,7) mt$0F Room_0F
    db $90, $FF, $07, $07, $0F  ; walk_exit (7,7) mt$0F Room_0F
    db $90, $FF, $09, $02, $0F  ; walk_exit (9,2) mt$0F Room_0F
    db $90, $FF, $09, $05, $0F  ; walk_exit (9,5) mt$0F Room_0F
    db $90, $FF, $02, $00, $0F  ; walk_exit (2,0) mt$0F Room_0F
    db $90, $FF, $07, $00, $0F  ; walk_exit (7,0) mt$0F Room_0F
    db $90, $FF, $00, $02, $07  ; walk_exit (0,2) mt$07 ArenaRooms
    db $90, $FF, $00, $05, $07  ; walk_exit (0,5) mt$07 ArenaRooms
    db $FF  ; terminator

Interact_Labyrinth_s0_v7:  ; $72D4 — 9 spawns
    db $90, $FF, $04, $04, $0F  ; walk_exit (4,4) mt$0F Room_0F
    db $90, $FF, $02, $07, $08  ; walk_exit (2,7) mt$08 Gate_08
    db $90, $FF, $07, $07, $08  ; walk_exit (7,7) mt$08 Gate_08
    db $90, $FF, $09, $02, $0F  ; walk_exit (9,2) mt$0F Room_0F
    db $90, $FF, $09, $05, $0F  ; walk_exit (9,5) mt$0F Room_0F
    db $90, $FF, $02, $00, $0F  ; walk_exit (2,0) mt$0F Room_0F
    db $90, $FF, $07, $00, $0F  ; walk_exit (7,0) mt$0F Room_0F
    db $90, $FF, $00, $02, $0F  ; walk_exit (0,2) mt$0F Room_0F
    db $90, $FF, $00, $05, $0F  ; walk_exit (0,5) mt$0F Room_0F
    db $FF  ; terminator

Interact_Labyrinth_s0_v8:  ; $7302 — 9 spawns
    db $90, $FF, $04, $04, $0F  ; walk_exit (4,4) mt$0F Room_0F
    db $90, $FF, $02, $07, $09  ; walk_exit (2,7) mt$09 StarryShrine
    db $90, $FF, $07, $07, $09  ; walk_exit (7,7) mt$09 StarryShrine
    db $90, $FF, $09, $02, $0F  ; walk_exit (9,2) mt$0F Room_0F
    db $90, $FF, $09, $05, $0F  ; walk_exit (9,5) mt$0F Room_0F
    db $90, $FF, $02, $00, $0F  ; walk_exit (2,0) mt$0F Room_0F
    db $90, $FF, $07, $00, $0F  ; walk_exit (7,0) mt$0F Room_0F
    db $90, $FF, $00, $02, $0F  ; walk_exit (0,2) mt$0F Room_0F
    db $90, $FF, $00, $05, $0F  ; walk_exit (0,5) mt$0F Room_0F
    db $FF  ; terminator

Interact_Labyrinth_s0_v9:  ; $7330 — 9 spawns
    db $90, $FF, $04, $04, $0F  ; walk_exit (4,4) mt$0F Room_0F
    db $90, $FF, $02, $07, $0F  ; walk_exit (2,7) mt$0F Room_0F
    db $90, $FF, $07, $07, $0F  ; walk_exit (7,7) mt$0F Room_0F
    db $90, $FF, $09, $02, $0F  ; walk_exit (9,2) mt$0F Room_0F
    db $90, $FF, $09, $05, $0F  ; walk_exit (9,5) mt$0F Room_0F
    db $90, $FF, $02, $00, $0F  ; walk_exit (2,0) mt$0F Room_0F
    db $90, $FF, $07, $00, $0F  ; walk_exit (7,0) mt$0F Room_0F
    db $90, $FF, $00, $02, $09  ; walk_exit (0,2) mt$09 StarryShrine
    db $90, $FF, $00, $05, $0F  ; walk_exit (0,5) mt$0F Room_0F
    db $FF  ; terminator

Interact_Labyrinth_s1:  ; $735E — 2 spawns, 2 NPCs
    db $8F, $FF, $03, $02, $10  ; spawn (3,2) mt$10 CopycatRoom
    db $8F, $FF, $03, $05, $12  ; spawn (3,5) mt$12 Library
    db $00, $1A, $06, $02, $11  ; NPC down b=0 spr=$1A (6,2) script=$11
    db $70, $21, $00, $01, $FF  ; NPC noTalk right b=0 spr=$21 (0,1) script=none
    db $FF  ; terminator

Interact_Labyrinth_s1_v1:  ; $7373 — 2 spawns
    db $8F, $FF, $03, $02, $10  ; spawn (3,2) mt$10 CopycatRoom
    db $8F, $FF, $03, $05, $12  ; spawn (3,5) mt$12 Library
    db $FF  ; terminator

Exit_Labyrinth_s0:  ; $737E — 9 exits
    db $05, $05, $00, $00, $01, $04, $05  ; exit (5,5)→mt$00 Castle  scr=1 spawn(4,5)
    db $02, $00, $42, $00, $00, $02, $07  ; exit (2,0)→mt$42 Labyrinth  scr=0 spawn(2,7)
    db $07, $00, $42, $00, $00, $07, $07  ; exit (7,0)→mt$42 Labyrinth  scr=0 spawn(7,7)
    db $00, $02, $42, $00, $00, $09, $02  ; arrival marker (skipped)
    db $00, $05, $42, $00, $00, $09, $05  ; arrival marker (skipped)
    db $02, $07, $42, $00, $00, $02, $00  ; exit (2,7)→mt$42 Labyrinth  scr=0 spawn(2,0)
    db $07, $07, $42, $00, $00, $07, $00  ; exit (7,7)→mt$42 Labyrinth  scr=0 spawn(7,0)
    db $09, $02, $42, $00, $00, $00, $02  ; special marker (skipped)
    db $09, $05, $42, $00, $00, $00, $05  ; special marker (skipped)
    db $FF  ; terminator

Exit_Labyrinth_s0_v1:  ; $73BE — 9 exits
    db $05, $05, $00, $00, $01, $04, $05  ; exit (5,5)→mt$00 Castle  scr=1 spawn(4,5)
    db $02, $00, $42, $00, $00, $02, $07  ; exit (2,0)→mt$42 Labyrinth  scr=0 spawn(2,7)
    db $07, $00, $42, $00, $00, $07, $07  ; exit (7,0)→mt$42 Labyrinth  scr=0 spawn(7,7)
    db $00, $02, $42, $00, $00, $09, $02  ; arrival marker (skipped)
    db $00, $05, $42, $00, $00, $09, $05  ; arrival marker (skipped)
    db $02, $07, $42, $00, $00, $02, $00  ; exit (2,7)→mt$42 Labyrinth  scr=0 spawn(2,0)
    db $07, $07, $42, $00, $00, $07, $00  ; exit (7,7)→mt$42 Labyrinth  scr=0 spawn(7,0)
    db $09, $02, $60, $00, $00, $00, $02  ; special marker (skipped)
    db $09, $05, $42, $00, $00, $00, $05  ; special marker (skipped)
    db $FF  ; terminator

Exit_Labyrinth_s0_v2:  ; $73FE — 9 exits
    db $05, $05, $00, $00, $01, $04, $05  ; exit (5,5)→mt$00 Castle  scr=1 spawn(4,5)
    db $02, $00, $42, $00, $00, $02, $07  ; exit (2,0)→mt$42 Labyrinth  scr=0 spawn(2,7)
    db $07, $00, $42, $00, $00, $07, $07  ; exit (7,0)→mt$42 Labyrinth  scr=0 spawn(7,7)
    db $00, $02, $42, $00, $00, $09, $02  ; arrival marker (skipped)
    db $00, $05, $42, $00, $00, $09, $05  ; arrival marker (skipped)
    db $02, $07, $42, $00, $00, $02, $00  ; exit (2,7)→mt$42 Labyrinth  scr=0 spawn(2,0)
    db $07, $07, $42, $00, $00, $07, $00  ; exit (7,7)→mt$42 Labyrinth  scr=0 spawn(7,0)
    db $09, $02, $42, $00, $00, $00, $02  ; special marker (skipped)
    db $09, $05, $60, $00, $00, $00, $05  ; special marker (skipped)
    db $FF  ; terminator

Exit_Labyrinth_s0_v3:  ; $743E — 9 exits
    db $05, $05, $00, $00, $01, $04, $05  ; exit (5,5)→mt$00 Castle  scr=1 spawn(4,5)
    db $02, $00, $42, $00, $00, $02, $07  ; exit (2,0)→mt$42 Labyrinth  scr=0 spawn(2,7)
    db $07, $00, $42, $00, $00, $07, $07  ; exit (7,0)→mt$42 Labyrinth  scr=0 spawn(7,7)
    db $00, $02, $42, $00, $00, $09, $02  ; arrival marker (skipped)
    db $00, $05, $60, $00, $00, $09, $05  ; arrival marker (skipped)
    db $02, $07, $42, $00, $00, $02, $00  ; exit (2,7)→mt$42 Labyrinth  scr=0 spawn(2,0)
    db $07, $07, $42, $00, $00, $07, $00  ; exit (7,7)→mt$42 Labyrinth  scr=0 spawn(7,0)
    db $09, $02, $42, $00, $00, $00, $02  ; special marker (skipped)
    db $09, $05, $42, $00, $00, $00, $05  ; special marker (skipped)
    db $FF  ; terminator

Exit_Labyrinth_s0_v4:  ; $747E — 9 exits
    db $05, $05, $00, $00, $01, $04, $05  ; exit (5,5)→mt$00 Castle  scr=1 spawn(4,5)
    db $02, $00, $42, $00, $00, $02, $07  ; exit (2,0)→mt$42 Labyrinth  scr=0 spawn(2,7)
    db $07, $00, $42, $00, $00, $07, $07  ; exit (7,0)→mt$42 Labyrinth  scr=0 spawn(7,7)
    db $00, $02, $60, $00, $00, $09, $02  ; arrival marker (skipped)
    db $00, $05, $42, $00, $00, $09, $05  ; arrival marker (skipped)
    db $02, $07, $42, $00, $00, $02, $00  ; exit (2,7)→mt$42 Labyrinth  scr=0 spawn(2,0)
    db $07, $07, $42, $00, $00, $07, $00  ; exit (7,7)→mt$42 Labyrinth  scr=0 spawn(7,0)
    db $09, $02, $42, $00, $00, $00, $02  ; special marker (skipped)
    db $09, $05, $42, $00, $00, $00, $05  ; special marker (skipped)
    db $FF  ; terminator

Exit_Labyrinth_s1:  ; $74BE — 4 exits
    db $00, $02, $42, $00, $00, $09, $02  ; arrival marker (skipped)
    db $00, $05, $42, $00, $00, $09, $05  ; arrival marker (skipped)
    db $09, $02, $42, $00, $00, $00, $02  ; special marker (skipped)
    db $09, $05, $42, $00, $00, $00, $05  ; special marker (skipped)
    db $FF  ; terminator

RoomSub_Room_43:  ; $74DB — mt=[$43]
    dw StepBlk_Room_43_s0  ; screen 0

StepBlk_Room_43_s0:  ; $74DD — RAM=$D98A, 2 steps
    dw $D98A  ; RAM step counter
    db $10, $24  ; step 0: layout=$10 bank=$24
    dw Interact_Room_43_s0  ; → interact/NPC data
    dw Exit_Room_43_s0  ; → exit data
    db $11, $24  ; step 1: layout=$11 bank=$24
    dw Interact_Room_43_s0_v1  ; → interact/NPC data
    dw Exit_Room_43_s0_v1  ; → exit data

Interact_Room_43_s0:  ; $74EB — 2 spawns, 4 NPCs
    db $82, $FF, $07, $05, $01  ; spc_82 (7,5) mt$01 GreatTree
    db $82, $FF, $08, $05, $01  ; spc_82 (8,5) mt$01 GreatTree
    db $50, $21, $0A, $01, $FF  ; NPC noTalk left b=0 spr=$21 (10,1) script=none
    db $06, $27, $04, $02, $02  ; NPC down b=6 spr=$27 (4,2) script=$02
    db $00, $FF, $04, $02, $02  ; NPC down b=0 spr=$FF (4,2) script=$02
    db $00, $FF, $05, $02, $02  ; NPC down b=0 spr=$FF (5,2) script=$02
    db $FF  ; terminator

Interact_Room_43_s0_v1:  ; $750A — 2 spawns
    db $82, $FF, $07, $05, $01  ; spc_82 (7,5) mt$01 GreatTree
    db $82, $FF, $08, $05, $01  ; spc_82 (8,5) mt$01 GreatTree
    db $FF  ; terminator

Exit_Room_43_s0:  ; $7515 — 0 exits
    db $FF  ; terminator

Exit_Room_43_s0_v1:  ; $7516 — 1 exits
    db $02, $05, $00, $00, $01, $04, $05  ; exit (2,5)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Room_44:  ; $751E — mt=[$44]
    dw StepBlk_Room_44_s0  ; screen 0

StepBlk_Room_44_s0:  ; $7520 — RAM=$D98B, 2 steps
    dw $D98B  ; RAM step counter
    db $19, $24  ; step 0: layout=$19 bank=$24
    dw Interact_Room_44_s0  ; → interact/NPC data
    dw Exit_Room_44_s0  ; → exit data
    db $1A, $24  ; step 1: layout=$1A bank=$24
    dw Interact_Room_44_s0_v1  ; → interact/NPC data
    dw Exit_Room_44_s0_v1  ; → exit data

Interact_Room_44_s0:  ; $752E — 8 NPCs
    db $60, $15, $00, $07, $02  ; NPC noTalk up b=0 spr=$15 (0,7) script=$02
    db $50, $21, $0A, $01, $FF  ; NPC noTalk left b=0 spr=$21 (10,1) script=none
    db $00, $24, $05, $02, $01  ; NPC down b=0 spr=$24 (5,2) script=$01
    db $60, $E0, $05, $03, $FF  ; NPC noTalk up b=0 spr=$E0 (5,3) script=none
    db $60, $E1, $05, $04, $FF  ; NPC noTalk up b=0 spr=$E1 (5,4) script=none
    db $60, $E2, $05, $04, $FF  ; NPC noTalk up b=0 spr=$E2 (5,4) script=none
    db $60, $E3, $05, $04, $FF  ; NPC noTalk up b=0 spr=$E3 (5,4) script=none
    db $00, $FF, $06, $02, $01  ; NPC down b=0 spr=$FF (6,2) script=$01
    db $FF  ; terminator

Interact_Room_44_s0_v1:  ; $7557 — empty
    db $FF  ; terminator

Exit_Room_44_s0:  ; $7558 — 0 exits
    db $FF  ; terminator

Exit_Room_44_s0_v1:  ; $7559 — 1 exits
    db $06, $01, $00, $00, $01, $04, $05  ; exit (6,1)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Room_45:  ; $7561 — mt=[$45]
    dw StepBlk_Room_45_s0  ; screen 0

StepBlk_Room_45_s0:  ; $7563 — RAM=$D98C, 3 steps
    dw $D98C  ; RAM step counter
    db $0A, $24  ; step 0: layout=$0A bank=$24
    dw Interact_Room_45_s0  ; → interact/NPC data
    dw Exit_Room_45_s0  ; → exit data
    db $0B, $24  ; step 1: layout=$0B bank=$24
    dw Interact_Room_45_s0_v2  ; → interact/NPC data
    dw Exit_Room_45_s0_v1  ; → exit data
    db $0A, $24  ; step 2: layout=$0A bank=$24
    dw Interact_Room_45_s0_v1  ; → interact/NPC data
    dw Exit_Room_45_s0  ; → exit data

Interact_Room_45_s0:  ; $7577 — 7 NPCs
    db $20, $E0, $04, $07, $FF  ; NPC up b=0 spr=$E0 (4,7) script=none
    db $40, $2B, $04, $06, $FF  ; NPC noTalk down b=0 spr=$2B (4,6) script=none
    db $40, $2B, $05, $06, $FF  ; NPC noTalk down b=0 spr=$2B (5,6) script=none
    db $40, $15, $04, $06, $FF  ; NPC noTalk down b=0 spr=$15 (4,6) script=none
    db $40, $39, $04, $00, $FF  ; NPC noTalk down b=0 spr=$39 (4,0) script=none
    db $50, $21, $0A, $01, $FF  ; NPC noTalk left b=0 spr=$21 (10,1) script=none
    db $00, $29, $04, $05, $FF  ; NPC down b=0 spr=$29 (4,5) script=none
    db $FF  ; terminator

Interact_Room_45_s0_v1:  ; $759B — 7 NPCs
    db $20, $E0, $04, $07, $FF  ; NPC up b=0 spr=$E0 (4,7) script=none
    db $40, $2B, $04, $06, $FF  ; NPC noTalk down b=0 spr=$2B (4,6) script=none
    db $40, $2B, $05, $06, $FF  ; NPC noTalk down b=0 spr=$2B (5,6) script=none
    db $20, $15, $03, $04, $FF  ; NPC up b=0 spr=$15 (3,4) script=none
    db $40, $39, $04, $00, $FF  ; NPC noTalk down b=0 spr=$39 (4,0) script=none
    db $50, $21, $0A, $01, $FF  ; NPC noTalk left b=0 spr=$21 (10,1) script=none
    db $00, $29, $04, $05, $FF  ; NPC down b=0 spr=$29 (4,5) script=none
    db $FF  ; terminator

Interact_Room_45_s0_v2:  ; $75BF — empty
    db $FF  ; terminator

Exit_Room_45_s0:  ; $75C0 — 0 exits
    db $FF  ; terminator

Exit_Room_45_s0_v1:  ; $75C1 — 1 exits
    db $05, $05, $00, $00, $01, $04, $05  ; exit (5,5)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Boss_Ambition:  ; $75C9 — mt=[$46]
    dw StepBlk_Boss_Ambition_s0  ; screen 0

StepBlk_Boss_Ambition_s0:  ; $75CB — RAM=$D98D, 2 steps
    dw $D98D  ; RAM step counter
    db $01, $23  ; step 0: layout=$01 bank=$23
    dw Interact_Boss_Ambition_s0  ; → interact/NPC data
    dw Exit_Boss_Ambition_s0  ; → exit data
    db $02, $23  ; step 1: layout=$02 bank=$23
    dw Interact_Boss_Ambition_s0_v1  ; → interact/NPC data
    dw Exit_Boss_Ambition_s0_v1  ; → exit data

Interact_Boss_Ambition_s0:  ; $75D9 — 4 NPCs
    db $50, $21, $0A, $00, $FF  ; NPC noTalk left b=0 spr=$21 (10,0) script=none
    db $00, $2D, $04, $03, $01  ; NPC down b=0 spr=$2D (4,3) script=$01
    db $00, $FF, $04, $03, $01  ; NPC down b=0 spr=$FF (4,3) script=$01
    db $00, $FF, $05, $03, $01  ; NPC down b=0 spr=$FF (5,3) script=$01
    db $FF  ; terminator

Interact_Boss_Ambition_s0_v1:  ; $75EE — empty
    db $FF  ; terminator

Exit_Boss_Ambition_s0:  ; $75EF — 0 exits
    db $FF  ; terminator

Exit_Boss_Ambition_s0_v1:  ; $75F0 — 1 exits
    db $02, $04, $00, $00, $01, $04, $05  ; exit (2,4)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Room_47:  ; $75F8 — mt=[$47]
    dw StepBlk_Room_47_s0  ; screen 0

StepBlk_Room_47_s0:  ; $75FA — RAM=$D98E, 3 steps
    dw $D98E  ; RAM step counter
    db $1C, $24  ; step 0: layout=$1C bank=$24
    dw Interact_Room_47_s0  ; → interact/NPC data
    dw Exit_Room_47_s0  ; → exit data
    db $1C, $24  ; step 1: layout=$1C bank=$24
    dw Interact_Room_47_s0_v1  ; → interact/NPC data
    dw Exit_Room_47_s0_v1  ; → exit data
    db $1D, $24  ; step 2: layout=$1D bank=$24
    dw Interact_Room_47_s0_v2  ; → interact/NPC data
    dw Exit_Room_47_s0_v2  ; → exit data

Interact_Room_47_s0:  ; $760E — 4 NPCs
    db $50, $21, $0A, $00, $FF  ; NPC noTalk left b=0 spr=$21 (10,0) script=none
    db $00, $2E, $04, $03, $01  ; NPC down b=0 spr=$2E (4,3) script=$01
    db $00, $FF, $05, $03, $01  ; NPC down b=0 spr=$FF (5,3) script=$01
    db $00, $FF, $04, $03, $01  ; NPC down b=0 spr=$FF (4,3) script=$01
    db $FF  ; terminator

Interact_Room_47_s0_v1:  ; $7623 — 4 NPCs
    db $50, $21, $0A, $00, $FF  ; NPC noTalk left b=0 spr=$21 (10,0) script=none
    db $00, $2F, $04, $03, $02  ; NPC down b=0 spr=$2F (4,3) script=$02
    db $00, $FF, $05, $03, $02  ; NPC down b=0 spr=$FF (5,3) script=$02
    db $00, $FF, $04, $03, $02  ; NPC down b=0 spr=$FF (4,3) script=$02
    db $FF  ; terminator

Interact_Room_47_s0_v2:  ; $7638 — empty
    db $FF  ; terminator

Exit_Room_47_s0:  ; $7639 — 0 exits
    db $FF  ; terminator

Exit_Room_47_s0_v1:  ; $763A — 0 exits
    db $FF  ; terminator

Exit_Room_47_s0_v2:  ; $763B — 1 exits
    db $03, $04, $00, $00, $01, $04, $05  ; exit (3,4)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Room_48:  ; $7643 — mt=[$48]
    dw StepBlk_Room_48_s0  ; screen 0

StepBlk_Room_48_s0:  ; $7645 — RAM=$D98F, 2 steps
    dw $D98F  ; RAM step counter
    db $0D, $24  ; step 0: layout=$0D bank=$24
    dw Interact_Room_48_s0  ; → interact/NPC data
    dw Exit_Room_48_s0  ; → exit data
    db $0E, $24  ; step 1: layout=$0E bank=$24
    dw Interact_Room_48_s0_v1  ; → interact/NPC data
    dw Exit_Room_48_s0_v1  ; → exit data

Interact_Room_48_s0:  ; $7653 — 4 NPCs
    db $50, $21, $0A, $00, $FF  ; NPC noTalk left b=0 spr=$21 (10,0) script=none
    db $00, $30, $04, $01, $01  ; NPC down b=0 spr=$30 (4,1) script=$01
    db $00, $FF, $04, $01, $01  ; NPC down b=0 spr=$FF (4,1) script=$01
    db $00, $FF, $05, $01, $01  ; NPC down b=0 spr=$FF (5,1) script=$01
    db $FF  ; terminator

Interact_Room_48_s0_v1:  ; $7668 — empty
    db $FF  ; terminator

Exit_Room_48_s0:  ; $7669 — 0 exits
    db $FF  ; terminator

Exit_Room_48_s0_v1:  ; $766A — 1 exits
    db $04, $01, $00, $00, $01, $04, $05  ; exit (4,1)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Room_49:  ; $7672 — mt=[$49]
    dw StepBlk_Room_49_s0  ; screen 0

StepBlk_Room_49_s0:  ; $7674 — RAM=$D990, 2 steps
    dw $D990  ; RAM step counter
    db $0C, $25  ; step 0: layout=$0C bank=$25
    dw Interact_Room_49_s0  ; → interact/NPC data
    dw Exit_Room_49_s0  ; → exit data
    db $0D, $25  ; step 1: layout=$0D bank=$25
    dw Interact_Room_49_s0_v1  ; → interact/NPC data
    dw Exit_Room_49_s0_v1  ; → exit data

Interact_Room_49_s0:  ; $7682 — 4 NPCs
    db $50, $21, $0A, $00, $FF  ; NPC noTalk left b=0 spr=$21 (10,0) script=none
    db $00, $31, $04, $02, $01  ; NPC down b=0 spr=$31 (4,2) script=$01
    db $00, $FF, $04, $02, $01  ; NPC down b=0 spr=$FF (4,2) script=$01
    db $00, $FF, $05, $02, $01  ; NPC down b=0 spr=$FF (5,2) script=$01
    db $FF  ; terminator

Interact_Room_49_s0_v1:  ; $7697 — empty
    db $FF  ; terminator

Exit_Room_49_s0:  ; $7698 — 0 exits
    db $FF  ; terminator

Exit_Room_49_s0_v1:  ; $7699 — 1 exits
    db $02, $04, $00, $00, $01, $04, $05  ; exit (2,4)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Room_4A:  ; $76A1 — mt=[$4A]
    dw StepBlk_Room_4A_s0  ; screen 0

StepBlk_Room_4A_s0:  ; $76A3 — RAM=$D991, 2 steps
    dw $D991  ; RAM step counter
    db $0B, $23  ; step 0: layout=$0B bank=$23
    dw Interact_Room_4A_s0  ; → interact/NPC data
    dw Exit_Room_4A_s0  ; → exit data
    db $0C, $23  ; step 1: layout=$0C bank=$23
    dw Interact_Room_4A_s0_v1  ; → interact/NPC data
    dw Exit_Room_4A_s0_v1  ; → exit data

Interact_Room_4A_s0:  ; $76B1 — 4 NPCs
    db $50, $21, $0A, $00, $FF  ; NPC noTalk left b=0 spr=$21 (10,0) script=none
    db $00, $32, $04, $01, $01  ; NPC down b=0 spr=$32 (4,1) script=$01
    db $00, $FF, $04, $01, $01  ; NPC down b=0 spr=$FF (4,1) script=$01
    db $00, $FF, $05, $01, $01  ; NPC down b=0 spr=$FF (5,1) script=$01
    db $FF  ; terminator

Interact_Room_4A_s0_v1:  ; $76C6 — empty
    db $FF  ; terminator

Exit_Room_4A_s0:  ; $76C7 — 0 exits
    db $FF  ; terminator

Exit_Room_4A_s0_v1:  ; $76C8 — 1 exits
    db $05, $03, $00, $00, $01, $04, $05  ; exit (5,3)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Room_4B:  ; $76D0 — mt=[$4B]
    dw StepBlk_Room_4B_s0  ; screen 0

StepBlk_Room_4B_s0:  ; $76D2 — RAM=$D992, 2 steps
    dw $D992  ; RAM step counter
    db $0E, $23  ; step 0: layout=$0E bank=$23
    dw Interact_Room_4B_s0  ; → interact/NPC data
    dw Exit_Room_4B_s0  ; → exit data
    db $0F, $23  ; step 1: layout=$0F bank=$23
    dw Interact_Room_4B_s0_v1  ; → interact/NPC data
    dw Exit_Room_4B_s0_v1  ; → exit data

Interact_Room_4B_s0:  ; $76E0 — 4 NPCs
    db $50, $21, $0A, $00, $FF  ; NPC noTalk left b=0 spr=$21 (10,0) script=none
    db $00, $33, $04, $01, $01  ; NPC down b=0 spr=$33 (4,1) script=$01
    db $00, $FF, $04, $01, $01  ; NPC down b=0 spr=$FF (4,1) script=$01
    db $00, $FF, $05, $01, $01  ; NPC down b=0 spr=$FF (5,1) script=$01
    db $FF  ; terminator

Interact_Room_4B_s0_v1:  ; $76F5 — empty
    db $FF  ; terminator

Exit_Room_4B_s0:  ; $76F6 — 0 exits
    db $FF  ; terminator

Exit_Room_4B_s0_v1:  ; $76F7 — 1 exits
    db $04, $03, $00, $00, $01, $04, $05  ; exit (4,3)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Room_4C:  ; $76FF — mt=[$4C]
    dw StepBlk_Room_4C_s0  ; screen 0

StepBlk_Room_4C_s0:  ; $7701 — RAM=$D993, 2 steps
    dw $D993  ; RAM step counter
    db $11, $23  ; step 0: layout=$11 bank=$23
    dw Interact_Room_4C_s0  ; → interact/NPC data
    dw Exit_Room_4C_s0  ; → exit data
    db $12, $23  ; step 1: layout=$12 bank=$23
    dw Interact_Room_4C_s0_v1  ; → interact/NPC data
    dw Exit_Room_4C_s0_v1  ; → exit data

Interact_Room_4C_s0:  ; $770F — 4 NPCs
    db $50, $21, $0A, $02, $FF  ; NPC noTalk left b=0 spr=$21 (10,2) script=none
    db $00, $34, $04, $02, $01  ; NPC down b=0 spr=$34 (4,2) script=$01
    db $00, $FF, $04, $03, $01  ; NPC down b=0 spr=$FF (4,3) script=$01
    db $00, $FF, $05, $03, $01  ; NPC down b=0 spr=$FF (5,3) script=$01
    db $FF  ; terminator

Interact_Room_4C_s0_v1:  ; $7724 — empty
    db $FF  ; terminator

Exit_Room_4C_s0:  ; $7725 — 0 exits
    db $FF  ; terminator

Exit_Room_4C_s0_v1:  ; $7726 — 1 exits
    db $04, $04, $00, $00, $01, $04, $05  ; exit (4,4)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Boss_ArenaRight:  ; $772E — mt=[$4D]
    dw StepBlk_Boss_ArenaRight_s0  ; screen 0

StepBlk_Boss_ArenaRight_s0:  ; $7730 — RAM=$D994, 2 steps
    dw $D994  ; RAM step counter
    db $0F, $25  ; step 0: layout=$0F bank=$25
    dw Interact_Boss_ArenaRight_s0  ; → interact/NPC data
    dw Exit_Boss_ArenaRight_s0  ; → exit data
    db $10, $25  ; step 1: layout=$10 bank=$25
    dw Interact_Boss_ArenaRight_s0_v1  ; → interact/NPC data
    dw Exit_Boss_ArenaRight_s0_v1  ; → exit data

Interact_Boss_ArenaRight_s0:  ; $773E — 4 NPCs
    db $50, $21, $0A, $00, $FF  ; NPC noTalk left b=0 spr=$21 (10,0) script=none
    db $00, $35, $04, $01, $01  ; NPC down b=0 spr=$35 (4,1) script=$01
    db $00, $FF, $04, $01, $01  ; NPC down b=0 spr=$FF (4,1) script=$01
    db $00, $FF, $05, $01, $01  ; NPC down b=0 spr=$FF (5,1) script=$01
    db $FF  ; terminator

Interact_Boss_ArenaRight_s0_v1:  ; $7753 — empty
    db $FF  ; terminator

Exit_Boss_ArenaRight_s0:  ; $7754 — 0 exits
    db $FF  ; terminator

Exit_Boss_ArenaRight_s0_v1:  ; $7755 — 1 exits
    db $03, $03, $00, $00, $01, $04, $05  ; exit (3,3)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Room_4E:  ; $775D — mt=[$4E]
    dw StepBlk_Room_4E_s0  ; screen 0
    dw $FFFF  ; screen 1 (unused)
    dw $FFFF  ; screen 2 (unused)
    dw $FFFF  ; screen 3 (unused)
    dw StepBlk_Room_4E_s4  ; screen 4
    dw $FFFF  ; screen 5 (unused)
    dw $FFFF  ; screen 6 (unused)
    dw $FFFF  ; screen 7 (unused)

StepBlk_Room_4E_s0:  ; $776D — RAM=$D995, 2 steps
    dw $D995  ; RAM step counter
    db $12, $25  ; step 0: layout=$12 bank=$25
    dw Interact_Room_4E_s0  ; → interact/NPC data
    dw Exit_Room_4E_s0  ; → exit data
    db $13, $25  ; step 1: layout=$13 bank=$25
    dw Interact_Room_4E_s0_v1  ; → interact/NPC data
    dw Exit_Room_4E_s0_v1  ; → exit data

StepBlk_Room_4E_s4:  ; $777B — RAM=$D996, 1 steps
    dw $D996  ; RAM step counter
    db $14, $25  ; step 0: layout=$14 bank=$25
    dw Interact_Room_4E_s4  ; → interact/NPC data
    dw Exit_Room_4E_s4  ; → exit data

Interact_Room_4E_s0:  ; $7783 — 5 NPCs
    db $50, $21, $0A, $01, $FF  ; NPC noTalk left b=0 spr=$21 (10,1) script=none
    db $0A, $36, $04, $02, $01  ; NPC down b=10 spr=$36 (4,2) script=$01
    db $00, $FF, $03, $03, $01  ; NPC down b=0 spr=$FF (3,3) script=$01
    db $00, $FF, $04, $03, $01  ; NPC down b=0 spr=$FF (4,3) script=$01
    db $00, $FF, $05, $03, $01  ; NPC down b=0 spr=$FF (5,3) script=$01
    db $FF  ; terminator

Interact_Room_4E_s0_v1:  ; $779D — empty
    db $FF  ; terminator

Interact_Room_4E_s4:  ; $779E — empty
    db $FF  ; terminator

Exit_Room_4E_s0:  ; $779F — 0 exits
    db $FF  ; terminator

Exit_Room_4E_s0_v1:  ; $77A0 — 1 exits
    db $04, $04, $00, $00, $01, $04, $05  ; exit (4,4)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

Exit_Room_4E_s4:  ; $77A8 — 0 exits
    db $FF  ; terminator

RoomSub_Boss_UnusedGate:  ; $77A9 — mt=[$4F]
    dw StepBlk_Boss_UnusedGate_s0  ; screen 0

StepBlk_Boss_UnusedGate_s0:  ; $77AB — RAM=$D997, 2 steps
    dw $D997  ; RAM step counter
    db $04, $24  ; step 0: layout=$04 bank=$24
    dw Interact_Boss_UnusedGate_s0  ; → interact/NPC data
    dw Exit_Boss_UnusedGate_s0  ; → exit data
    db $05, $24  ; step 1: layout=$05 bank=$24
    dw Interact_Boss_UnusedGate_s0_v1  ; → interact/NPC data
    dw Exit_Boss_UnusedGate_s0_v1  ; → exit data

Interact_Boss_UnusedGate_s0:  ; $77B9 — 2 spawns, 3 NPCs
    db $90, $FF, $04, $04, $01  ; walk_exit (4,4) mt$01 GreatTree
    db $90, $FF, $05, $04, $01  ; walk_exit (5,4) mt$01 GreatTree
    db $40, $37, $04, $03, $02  ; NPC noTalk down b=0 spr=$37 (4,3) script=$02
    db $40, $FF, $04, $03, $02  ; NPC noTalk down b=0 spr=$FF (4,3) script=$02
    db $40, $FF, $05, $03, $02  ; NPC noTalk down b=0 spr=$FF (5,3) script=$02
    db $FF  ; terminator

Interact_Boss_UnusedGate_s0_v1:  ; $77D3 — empty
    db $FF  ; terminator

Exit_Boss_UnusedGate_s0:  ; $77D4 — 0 exits
    db $FF  ; terminator

Exit_Boss_UnusedGate_s0_v1:  ; $77D5 — 1 exits
    db $03, $05, $00, $00, $01, $04, $05  ; exit (3,5)→mt$00 Castle  scr=1 spawn(4,5)
    db $FF  ; terminator

RoomSub_Room_50:  ; $77DD — mt=[$50, $5F]
    dw StepBlk_Room_50_s0  ; screen 0

StepBlk_Room_50_s0:  ; $77DF — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $01, $26  ; step 0: layout=$01 bank=$26
    dw Interact_Room_50_s0  ; → interact/NPC data
    dw Exit_Room_50_s0  ; → exit data

Interact_Room_50_s0:  ; $77E7 — 1 spawns, 1 NPCs
    db $8F, $FF, $04, $03, $01  ; spawn (4,3) mt$01 GreatTree
    db $00, $06, $04, $02, $01  ; NPC down b=0 spr=$06 (4,2) script=$01
    db $FF  ; terminator

Exit_Room_50_s0:  ; $77F2 — 1 exits
    db $01, $06, $00, $80, $00, $00, $00  ; exit (1,6)→mt$00 Castle gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_Room_51:  ; $77FA — mt=[$51]
    dw StepBlk_Room_51_s0  ; screen 0

StepBlk_Room_51_s0:  ; $77FC — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $03, $26  ; step 0: layout=$03 bank=$26
    dw Interact_Room_51_s0  ; → interact/NPC data
    dw Exit_Room_51_s0  ; → exit data

Interact_Room_51_s0:  ; $7804 — 1 spawns, 1 NPCs
    db $82, $FF, $04, $03, $02  ; spc_82 (4,3) mt$02 Bazaar
    db $00, $11, $04, $02, $01  ; NPC down b=0 spr=$11 (4,2) script=$01
    db $FF  ; terminator

Exit_Room_51_s0:  ; $780F — 1 exits
    db $08, $02, $00, $80, $00, $00, $00  ; exit (8,2)→mt$00 Castle gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_Coliseum:  ; $7817 — mt=[$52]
    dw StepBlk_Coliseum_s0  ; screen 0

StepBlk_Coliseum_s0:  ; $7819 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $05, $26  ; step 0: layout=$05 bank=$26
    dw Interact_Coliseum_s0  ; → interact/NPC data
    dw Exit_Coliseum_s0  ; → exit data

Interact_Coliseum_s0:  ; $7821 — 8 NPCs
    db $00, $0B, $04, $03, $FF  ; NPC down b=0 spr=$0B (4,3) script=none
    db $00, $F0, $03, $03, $FF  ; NPC down b=0 spr=$F0 (3,3) script=none
    db $00, $F1, $05, $03, $FF  ; NPC down b=0 spr=$F1 (5,3) script=none
    db $00, $F2, $06, $03, $FF  ; NPC down b=0 spr=$F2 (6,3) script=none
    db $20, $E1, $05, $05, $FF  ; NPC up b=0 spr=$E1 (5,5) script=none
    db $20, $E2, $03, $05, $FF  ; NPC up b=0 spr=$E2 (3,5) script=none
    db $20, $E3, $06, $05, $FF  ; NPC up b=0 spr=$E3 (6,5) script=none
    db $20, $E0, $04, $05, $FF  ; NPC up b=0 spr=$E0 (4,5) script=none
    db $FF  ; terminator

Exit_Coliseum_s0:  ; $784A — 0 exits
    db $FF  ; terminator

RoomSub_ForestMaze:  ; $784B — mt=[$53]
    dw StepBlk_ForestMaze_s0  ; screen 0

RoomSub_Room_61:  ; $784D — mt=[$61]
    dw StepBlk_ForestMaze_s1  ; screen 1

RoomSub_Room_62:  ; $784F — mt=[$62]
    dw StepBlk_ForestMaze_s2  ; screen 2

RoomSub_Room_63:  ; $7851 — mt=[$63]
    dw StepBlk_ForestMaze_s3  ; screen 3

RoomSub_Room_64:  ; $7853 — mt=[$64]
    dw StepBlk_ForestMaze_s4  ; screen 4

StepBlk_ForestMaze_s0:  ; $7855 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $19, $23  ; step 0: layout=$19 bank=$23
    dw $787D  ; → interact/NPC data
    dw $787E  ; → exit data

StepBlk_ForestMaze_s1:  ; $785D — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $1A, $23  ; step 0: layout=$1A bank=$23
    dw $787D  ; → interact/NPC data
    dw Exit_ForestMaze_s1  ; → exit data

StepBlk_ForestMaze_s2:  ; $7865 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $1B, $23  ; step 0: layout=$1B bank=$23
    dw $787D  ; → interact/NPC data
    dw Exit_ForestMaze_s2  ; → exit data

StepBlk_ForestMaze_s3:  ; $786D — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $1C, $23  ; step 0: layout=$1C bank=$23
    dw $787D  ; → interact/NPC data
    dw Exit_ForestMaze_s3  ; → exit data

StepBlk_ForestMaze_s4:  ; $7875 — RAM=$D998, 2 steps
    dw $D998  ; RAM step counter
    db $1D, $23  ; step 0: layout=$1D bank=$23
    dw $787D  ; → interact/NPC data
    dw Exit_ForestMaze_s4  ; → exit data
    db $FF, $00  ; step 1: layout=$FF bank=$00
    dw $6203  ; → interact/NPC data
    dw $0000  ; → exit data

; --- gap $7883-$789A (24 bytes) ---
    db $09, $03, $01, $00, $61, $00, $00, $01, $07, $08, $00, $63, $00, $00, $08, $07
    db $09, $03, $61, $00, $00, $00, $03, $FF

Exit_ForestMaze_s1:  ; $789B — 4 exits
    db $01, $07, $53, $00, $00, $01, $00  ; exit (1,7)→mt$53 ForestMaze  scr=0 spawn(1,0)
    db $08, $07, $53, $00, $00, $08, $00  ; exit (8,7)→mt$53 ForestMaze  scr=0 spawn(8,0)
    db $00, $03, $53, $00, $00, $09, $03  ; arrival marker (skipped)
    db $01, $00, $62, $00, $00, $01, $07  ; exit (1,0)→mt$62 Room_62  scr=0 spawn(1,7)
    db $FF  ; terminator

Exit_ForestMaze_s2:  ; $78B8 — 3 exits
    db $01, $07, $61, $00, $00, $01, $00  ; exit (1,7)→mt$61 Room_61  scr=0 spawn(1,0)
    db $08, $00, $61, $00, $00, $08, $07  ; exit (8,0)→mt$61 Room_61  scr=0 spawn(8,7)
    db $09, $03, $53, $00, $00, $00, $03  ; special marker (skipped)
    db $FF  ; terminator

Exit_ForestMaze_s3:  ; $78CE — 6 exits
    db $08, $07, $62, $00, $00, $08, $00  ; exit (8,7)→mt$62 Room_62  scr=0 spawn(8,0)
    db $09, $05, $63, $00, $00, $00, $05  ; special marker (skipped)
    db $01, $00, $63, $00, $00, $01, $07  ; exit (1,0)→mt$63 Room_63  scr=0 spawn(1,7)
    db $04, $00, $64, $00, $00, $04, $07  ; exit (4,0)→mt$64 Room_64  scr=0 spawn(4,7)
    db $00, $05, $63, $00, $00, $09, $05  ; arrival marker (skipped)
    db $01, $07, $63, $00, $00, $01, $00  ; exit (1,7)→mt$63 Room_63  scr=0 spawn(1,0)
    db $FF  ; terminator

Exit_ForestMaze_s4:  ; $78F9 — 2 exits
    db $04, $07, $63, $00, $00, $04, $00  ; exit (4,7)→mt$63 Room_63  scr=0 spawn(4,0)
    db $04, $04, $00, $80, $00, $00, $00  ; exit (4,4)→mt$00 Castle gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_ConveyorBelt1:  ; $7908 — mt=[$54]
    dw StepBlk_ConveyorBelt1_s0  ; screen 0
    dw StepBlk_ConveyorBelt1_s1  ; screen 1
    dw StepBlk_ConveyorBelt1_s2  ; screen 2
    dw $FFFF  ; screen 3 (unused)
    dw StepBlk_ConveyorBelt1_s4  ; screen 4
    dw StepBlk_ConveyorBelt1_s5  ; screen 5
    dw StepBlk_ConveyorBelt1_s6  ; screen 6
    dw $FFFF  ; screen 7 (unused)
    dw StepBlk_ConveyorBelt1_s8  ; screen 8
    dw StepBlk_ConveyorBelt1_s9  ; screen 9
    dw StepBlk_ConveyorBelt1_s10  ; screen 10
    dw $FFFF  ; screen 11 (unused)

StepBlk_ConveyorBelt1_s0:  ; $7920 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $01, $37  ; step 0: layout=$01 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt1_s0  ; → exit data

StepBlk_ConveyorBelt1_s1:  ; $7928 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $02, $37  ; step 0: layout=$02 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt1_s1  ; → exit data

StepBlk_ConveyorBelt1_s2:  ; $7930 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $03, $37  ; step 0: layout=$03 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt1_s2  ; → exit data

StepBlk_ConveyorBelt1_s4:  ; $7938 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $04, $37  ; step 0: layout=$04 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt1_s4  ; → exit data

StepBlk_ConveyorBelt1_s5:  ; $7940 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $05, $37  ; step 0: layout=$05 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt1_s5  ; → exit data

StepBlk_ConveyorBelt1_s6:  ; $7948 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $06, $37  ; step 0: layout=$06 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt1_s6  ; → exit data

StepBlk_ConveyorBelt1_s8:  ; $7950 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $07, $37  ; step 0: layout=$07 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt1_s8  ; → exit data

StepBlk_ConveyorBelt1_s9:  ; $7958 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $08, $37  ; step 0: layout=$08 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt1_s9  ; → exit data

StepBlk_ConveyorBelt1_s10:  ; $7960 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $09, $37  ; step 0: layout=$09 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt1_s10  ; → exit data

Exit_ConveyorBelt1_s0:  ; $7968 — 0 exits
    db $FF  ; terminator

Exit_ConveyorBelt1_s1:  ; $7969 — 0 exits
    db $FF  ; terminator

Exit_ConveyorBelt1_s2:  ; $796A — 0 exits
    db $FF  ; terminator

Exit_ConveyorBelt1_s4:  ; $796B — 0 exits
    db $FF  ; terminator

Exit_ConveyorBelt1_s5:  ; $796C — 0 exits
    db $FF  ; terminator

Exit_ConveyorBelt1_s6:  ; $796D — 0 exits
    db $FF  ; terminator

Exit_ConveyorBelt1_s8:  ; $796E — 0 exits
    db $FF  ; terminator

Exit_ConveyorBelt1_s9:  ; $796F — 0 exits
    db $FF  ; terminator

Exit_ConveyorBelt1_s10:  ; $7970 — 1 exits
    db $08, $02, $00, $80, $00, $00, $00  ; exit (8,2)→mt$00 Castle gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_ConveyorBelt2:  ; $7978 — mt=[$55]
    dw StepBlk_ConveyorBelt2_s0  ; screen 0
    dw StepBlk_ConveyorBelt2_s1  ; screen 1
    dw StepBlk_ConveyorBelt2_s2  ; screen 2
    dw $FFFF  ; screen 3 (unused)
    dw StepBlk_ConveyorBelt2_s4  ; screen 4
    dw StepBlk_ConveyorBelt2_s5  ; screen 5
    dw StepBlk_ConveyorBelt2_s6  ; screen 6
    dw $FFFF  ; screen 7 (unused)
    dw StepBlk_ConveyorBelt2_s8  ; screen 8
    dw StepBlk_ConveyorBelt2_s9  ; screen 9
    dw StepBlk_ConveyorBelt2_s10  ; screen 10
    dw $FFFF  ; screen 11 (unused)

StepBlk_ConveyorBelt2_s0:  ; $7990 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $0B, $37  ; step 0: layout=$0B bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt2_s0  ; → exit data

StepBlk_ConveyorBelt2_s1:  ; $7998 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $0C, $37  ; step 0: layout=$0C bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt2_s1  ; → exit data

StepBlk_ConveyorBelt2_s2:  ; $79A0 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $0D, $37  ; step 0: layout=$0D bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt2_s2  ; → exit data

StepBlk_ConveyorBelt2_s4:  ; $79A8 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $0E, $37  ; step 0: layout=$0E bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt2_s4  ; → exit data

StepBlk_ConveyorBelt2_s5:  ; $79B0 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $0F, $37  ; step 0: layout=$0F bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt2_s5  ; → exit data

StepBlk_ConveyorBelt2_s6:  ; $79B8 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $10, $37  ; step 0: layout=$10 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt2_s6  ; → exit data

StepBlk_ConveyorBelt2_s8:  ; $79C0 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $11, $37  ; step 0: layout=$11 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt2_s8  ; → exit data

StepBlk_ConveyorBelt2_s9:  ; $79C8 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $12, $37  ; step 0: layout=$12 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt2_s9  ; → exit data

StepBlk_ConveyorBelt2_s10:  ; $79D0 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $13, $37  ; step 0: layout=$13 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt2_s10  ; → exit data

Exit_ConveyorBelt2_s0:  ; $79D8 — 0 exits
    db $FF  ; terminator

Exit_ConveyorBelt2_s1:  ; $79D9 — 0 exits
    db $FF  ; terminator

Exit_ConveyorBelt2_s2:  ; $79DA — 0 exits
    db $FF  ; terminator

Exit_ConveyorBelt2_s4:  ; $79DB — 0 exits
    db $FF  ; terminator

Exit_ConveyorBelt2_s5:  ; $79DC — 0 exits
    db $FF  ; terminator

Exit_ConveyorBelt2_s6:  ; $79DD — 0 exits
    db $FF  ; terminator

Exit_ConveyorBelt2_s8:  ; $79DE — 1 exits
    db $06, $06, $00, $80, $00, $00, $00  ; exit (6,6)→mt$00 Castle gate scr=0 spawn(0,0)
    db $FF  ; terminator

Exit_ConveyorBelt2_s9:  ; $79E6 — 0 exits
    db $FF  ; terminator

Exit_ConveyorBelt2_s10:  ; $79E7 — 0 exits
    db $FF  ; terminator

RoomSub_ConveyorBelt3:  ; $79E8 — mt=[$56]
    dw StepBlk_ConveyorBelt3_s0  ; screen 0
    dw StepBlk_ConveyorBelt3_s1  ; screen 1
    dw StepBlk_ConveyorBelt3_s2  ; screen 2
    dw $FFFF  ; screen 3 (unused)
    dw StepBlk_ConveyorBelt3_s4  ; screen 4
    dw StepBlk_ConveyorBelt3_s5  ; screen 5
    dw StepBlk_ConveyorBelt3_s6  ; screen 6
    dw $FFFF  ; screen 7 (unused)
    dw StepBlk_ConveyorBelt3_s8  ; screen 8
    dw StepBlk_ConveyorBelt3_s9  ; screen 9
    dw StepBlk_ConveyorBelt3_s10  ; screen 10
    dw $FFFF  ; screen 11 (unused)

StepBlk_ConveyorBelt3_s0:  ; $7A00 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $15, $37  ; step 0: layout=$15 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt3_s0  ; → exit data

StepBlk_ConveyorBelt3_s1:  ; $7A08 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $16, $37  ; step 0: layout=$16 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt3_s1  ; → exit data

StepBlk_ConveyorBelt3_s2:  ; $7A10 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $17, $37  ; step 0: layout=$17 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt3_s2  ; → exit data

StepBlk_ConveyorBelt3_s4:  ; $7A18 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $18, $37  ; step 0: layout=$18 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt3_s4  ; → exit data

StepBlk_ConveyorBelt3_s5:  ; $7A20 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $19, $37  ; step 0: layout=$19 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt3_s5  ; → exit data

StepBlk_ConveyorBelt3_s6:  ; $7A28 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $1A, $37  ; step 0: layout=$1A bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt3_s6  ; → exit data

StepBlk_ConveyorBelt3_s8:  ; $7A30 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $1B, $37  ; step 0: layout=$1B bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt3_s8  ; → exit data

StepBlk_ConveyorBelt3_s9:  ; $7A38 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $1C, $37  ; step 0: layout=$1C bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt3_s9  ; → exit data

StepBlk_ConveyorBelt3_s10:  ; $7A40 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $1D, $37  ; step 0: layout=$1D bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_ConveyorBelt3_s10  ; → exit data

Exit_ConveyorBelt3_s0:  ; $7A48 — 0 exits
    db $FF  ; terminator

Exit_ConveyorBelt3_s1:  ; $7A49 — 0 exits
    db $FF  ; terminator

Exit_ConveyorBelt3_s2:  ; $7A4A — 1 exits
    db $03, $03, $00, $80, $00, $00, $00  ; exit (3,3)→mt$00 Castle gate scr=0 spawn(0,0)
    db $FF  ; terminator

Exit_ConveyorBelt3_s4:  ; $7A52 — 0 exits
    db $FF  ; terminator

Exit_ConveyorBelt3_s5:  ; $7A53 — 0 exits
    db $FF  ; terminator

Exit_ConveyorBelt3_s6:  ; $7A54 — 0 exits
    db $FF  ; terminator

Exit_ConveyorBelt3_s8:  ; $7A55 — 0 exits
    db $FF  ; terminator

Exit_ConveyorBelt3_s9:  ; $7A56 — 0 exits
    db $FF  ; terminator

Exit_ConveyorBelt3_s10:  ; $7A57 — 0 exits
    db $FF  ; terminator

RoomSub_Maze1:  ; $7A58 — mt=[$57]
    dw StepBlk_Maze1_s0  ; screen 0
    dw StepBlk_Maze1_s1  ; screen 1
    dw StepBlk_Maze1_s2  ; screen 2
    dw $FFFF  ; screen 3 (unused)
    dw StepBlk_Maze1_s4  ; screen 4
    dw StepBlk_Maze1_s5  ; screen 5
    dw StepBlk_Maze1_s6  ; screen 6
    dw $FFFF  ; screen 7 (unused)
    dw StepBlk_Maze1_s8  ; screen 8
    dw StepBlk_Maze1_s9  ; screen 9
    dw StepBlk_Maze1_s10  ; screen 10
    dw $FFFF  ; screen 11 (unused)

StepBlk_Maze1_s0:  ; $7A70 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $1F, $37  ; step 0: layout=$1F bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze1_s0  ; → exit data

StepBlk_Maze1_s1:  ; $7A78 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $20, $37  ; step 0: layout=$20 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze1_s1  ; → exit data

StepBlk_Maze1_s2:  ; $7A80 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $21, $37  ; step 0: layout=$21 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze1_s2  ; → exit data

StepBlk_Maze1_s4:  ; $7A88 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $22, $37  ; step 0: layout=$22 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze1_s4  ; → exit data

StepBlk_Maze1_s5:  ; $7A90 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $23, $37  ; step 0: layout=$23 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze1_s5  ; → exit data

StepBlk_Maze1_s6:  ; $7A98 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $24, $37  ; step 0: layout=$24 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze1_s6  ; → exit data

StepBlk_Maze1_s8:  ; $7AA0 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $25, $37  ; step 0: layout=$25 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze1_s8  ; → exit data

StepBlk_Maze1_s9:  ; $7AA8 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $26, $37  ; step 0: layout=$26 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze1_s9  ; → exit data

StepBlk_Maze1_s10:  ; $7AB0 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $27, $37  ; step 0: layout=$27 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze1_s10  ; → exit data

Exit_Maze1_s0:  ; $7AB8 — 0 exits
    db $FF  ; terminator

Exit_Maze1_s1:  ; $7AB9 — 0 exits
    db $FF  ; terminator

Exit_Maze1_s2:  ; $7ABA — 0 exits
    db $FF  ; terminator

Exit_Maze1_s4:  ; $7ABB — 0 exits
    db $FF  ; terminator

Exit_Maze1_s5:  ; $7ABC — 0 exits
    db $FF  ; terminator

Exit_Maze1_s6:  ; $7ABD — 0 exits
    db $FF  ; terminator

Exit_Maze1_s8:  ; $7ABE — 1 exits
    db $01, $06, $00, $80, $00, $00, $00  ; exit (1,6)→mt$00 Castle gate scr=0 spawn(0,0)
    db $FF  ; terminator

Exit_Maze1_s9:  ; $7AC6 — 0 exits
    db $FF  ; terminator

Exit_Maze1_s10:  ; $7AC7 — 0 exits
    db $FF  ; terminator

RoomSub_Maze2:  ; $7AC8 — mt=[$58]
    dw StepBlk_Maze2_s0  ; screen 0
    dw StepBlk_Maze2_s1  ; screen 1
    dw StepBlk_Maze2_s2  ; screen 2
    dw $FFFF  ; screen 3 (unused)
    dw StepBlk_Maze2_s4  ; screen 4
    dw StepBlk_Maze2_s5  ; screen 5
    dw StepBlk_Maze2_s6  ; screen 6
    dw $FFFF  ; screen 7 (unused)
    dw StepBlk_Maze2_s8  ; screen 8
    dw StepBlk_Maze2_s9  ; screen 9
    dw StepBlk_Maze2_s10  ; screen 10
    dw $FFFF  ; screen 11 (unused)

StepBlk_Maze2_s0:  ; $7AE0 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $29, $37  ; step 0: layout=$29 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze2_s0  ; → exit data

StepBlk_Maze2_s1:  ; $7AE8 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $2A, $37  ; step 0: layout=$2A bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze2_s1  ; → exit data

StepBlk_Maze2_s2:  ; $7AF0 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $2B, $37  ; step 0: layout=$2B bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze2_s2  ; → exit data

StepBlk_Maze2_s4:  ; $7AF8 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $2C, $37  ; step 0: layout=$2C bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze2_s4  ; → exit data

StepBlk_Maze2_s5:  ; $7B00 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $2D, $37  ; step 0: layout=$2D bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze2_s5  ; → exit data

StepBlk_Maze2_s6:  ; $7B08 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $2E, $37  ; step 0: layout=$2E bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze2_s6  ; → exit data

StepBlk_Maze2_s8:  ; $7B10 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $2F, $37  ; step 0: layout=$2F bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze2_s8  ; → exit data

StepBlk_Maze2_s9:  ; $7B18 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $30, $37  ; step 0: layout=$30 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze2_s9  ; → exit data

StepBlk_Maze2_s10:  ; $7B20 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $31, $37  ; step 0: layout=$31 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze2_s10  ; → exit data

Exit_Maze2_s0:  ; $7B28 — 0 exits
    db $FF  ; terminator

Exit_Maze2_s1:  ; $7B29 — 0 exits
    db $FF  ; terminator

Exit_Maze2_s2:  ; $7B2A — 0 exits
    db $FF  ; terminator

Exit_Maze2_s4:  ; $7B2B — 0 exits
    db $FF  ; terminator

Exit_Maze2_s5:  ; $7B2C — 0 exits
    db $FF  ; terminator

Exit_Maze2_s6:  ; $7B2D — 0 exits
    db $FF  ; terminator

Exit_Maze2_s8:  ; $7B2E — 0 exits
    db $FF  ; terminator

Exit_Maze2_s9:  ; $7B2F — 1 exits
    db $03, $06, $00, $80, $00, $00, $00  ; exit (3,6)→mt$00 Castle gate scr=0 spawn(0,0)
    db $FF  ; terminator

Exit_Maze2_s10:  ; $7B37 — 0 exits
    db $FF  ; terminator

RoomSub_Maze3:  ; $7B38 — mt=[$59]
    dw StepBlk_Maze3_s0  ; screen 0
    dw StepBlk_Maze3_s1  ; screen 1
    dw StepBlk_Maze3_s2  ; screen 2
    dw $FFFF  ; screen 3 (unused)
    dw StepBlk_Maze3_s4  ; screen 4
    dw StepBlk_Maze3_s5  ; screen 5
    dw StepBlk_Maze3_s6  ; screen 6
    dw $FFFF  ; screen 7 (unused)
    dw StepBlk_Maze3_s8  ; screen 8
    dw StepBlk_Maze3_s9  ; screen 9
    dw StepBlk_Maze3_s10  ; screen 10
    dw $FFFF  ; screen 11 (unused)

StepBlk_Maze3_s0:  ; $7B50 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $33, $37  ; step 0: layout=$33 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze3_s0  ; → exit data

StepBlk_Maze3_s1:  ; $7B58 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $34, $37  ; step 0: layout=$34 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze3_s1  ; → exit data

StepBlk_Maze3_s2:  ; $7B60 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $35, $37  ; step 0: layout=$35 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze3_s2  ; → exit data

StepBlk_Maze3_s4:  ; $7B68 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $36, $37  ; step 0: layout=$36 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze3_s4  ; → exit data

StepBlk_Maze3_s5:  ; $7B70 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $37, $37  ; step 0: layout=$37 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze3_s5  ; → exit data

StepBlk_Maze3_s6:  ; $7B78 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $38, $37  ; step 0: layout=$38 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze3_s6  ; → exit data

StepBlk_Maze3_s8:  ; $7B80 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $39, $37  ; step 0: layout=$39 bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze3_s8  ; → exit data

StepBlk_Maze3_s9:  ; $7B88 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $3A, $37  ; step 0: layout=$3A bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze3_s9  ; → exit data

StepBlk_Maze3_s10:  ; $7B90 — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $3B, $37  ; step 0: layout=$3B bank=$37
    dw $4B42  ; → interact/NPC data
    dw Exit_Maze3_s10  ; → exit data

Exit_Maze3_s0:  ; $7B98 — 0 exits
    db $FF  ; terminator

Exit_Maze3_s1:  ; $7B99 — 0 exits
    db $FF  ; terminator

Exit_Maze3_s2:  ; $7B9A — 0 exits
    db $FF  ; terminator

Exit_Maze3_s4:  ; $7B9B — 0 exits
    db $FF  ; terminator

Exit_Maze3_s5:  ; $7B9C — 0 exits
    db $FF  ; terminator

Exit_Maze3_s6:  ; $7B9D — 0 exits
    db $FF  ; terminator

Exit_Maze3_s8:  ; $7B9E — 0 exits
    db $FF  ; terminator

Exit_Maze3_s9:  ; $7B9F — 0 exits
    db $FF  ; terminator

Exit_Maze3_s10:  ; $7BA0 — 1 exits
    db $08, $06, $00, $80, $00, $00, $00  ; exit (8,6)→mt$00 Castle gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_TreasureChest1:  ; $7BA8 — mt=[$5A]
    dw StepBlk_TreasureChest1_s0  ; screen 0

StepBlk_TreasureChest1_s0:  ; $7BAA — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $07, $26  ; step 0: layout=$07 bank=$26
    dw Interact_TreasureChest1_s0  ; → interact/NPC data
    dw Exit_TreasureChest1_s0  ; → exit data

Interact_TreasureChest1_s0:  ; $7BB2 — 6 spawns
    db $8F, $FF, $01, $02, $01  ; spawn (1,2) mt$01 GreatTree
    db $8F, $FF, $08, $02, $02  ; spawn (8,2) mt$02 Bazaar
    db $8F, $FF, $03, $03, $03  ; spawn (3,3) mt$03 GateHub
    db $8F, $FF, $06, $03, $04  ; spawn (6,3) mt$04 Farm
    db $8F, $FF, $02, $05, $05  ; spawn (2,5) mt$05 Stable
    db $8F, $FF, $07, $05, $06  ; spawn (7,5) mt$06 ArenaLobby
    db $FF  ; terminator

Exit_TreasureChest1_s0:  ; $7BD1 — 1 exits
    db $05, $06, $00, $80, $00, $00, $00  ; exit (5,6)→mt$00 Castle gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_Room_5B:  ; $7BD9 — mt=[$5B]
    dw StepBlk_Room_5B_s0  ; screen 0

StepBlk_Room_5B_s0:  ; $7BDB — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $09, $26  ; step 0: layout=$09 bank=$26
    dw Interact_Room_5B_s0  ; → interact/NPC data
    dw Exit_Room_5B_s0  ; → exit data

Interact_Room_5B_s0:  ; $7BE3 — 6 spawns
    db $8F, $FF, $03, $03, $01  ; spawn (3,3) mt$01 GreatTree
    db $8F, $FF, $06, $03, $02  ; spawn (6,3) mt$02 Bazaar
    db $8F, $FF, $03, $04, $03  ; spawn (3,4) mt$03 GateHub
    db $8F, $FF, $06, $04, $04  ; spawn (6,4) mt$04 Farm
    db $8F, $FF, $03, $05, $05  ; spawn (3,5) mt$05 Stable
    db $8F, $FF, $06, $05, $06  ; spawn (6,5) mt$06 ArenaLobby
    db $FF  ; terminator

Exit_Room_5B_s0:  ; $7C02 — 1 exits
    db $05, $02, $00, $80, $00, $00, $00  ; exit (5,2)→mt$00 Castle gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_TreasureChest3:  ; $7C0A — mt=[$5C]
    dw StepBlk_TreasureChest3_s0  ; screen 0

StepBlk_TreasureChest3_s0:  ; $7C0C — RAM=$D998, 1 steps
    dw $D998  ; RAM step counter
    db $0B, $26  ; step 0: layout=$0B bank=$26
    dw Interact_TreasureChest3_s0  ; → interact/NPC data
    dw Exit_TreasureChest3_s0  ; → exit data

Interact_TreasureChest3_s0:  ; $7C14 — 8 spawns
    db $8F, $FF, $03, $02, $01  ; spawn (3,2) mt$01 GreatTree
    db $8F, $FF, $04, $02, $02  ; spawn (4,2) mt$02 Bazaar
    db $8F, $FF, $05, $02, $03  ; spawn (5,2) mt$03 GateHub
    db $8F, $FF, $06, $02, $04  ; spawn (6,2) mt$04 Farm
    db $8F, $FF, $03, $06, $05  ; spawn (3,6) mt$05 Stable
    db $8F, $FF, $04, $06, $06  ; spawn (4,6) mt$06 ArenaLobby
    db $8F, $FF, $05, $06, $07  ; spawn (5,6) mt$07 ArenaRooms
    db $8F, $FF, $06, $06, $08  ; spawn (6,6) mt$08 Gate_08
    db $FF  ; terminator

Exit_TreasureChest3_s0:  ; $7C3D — 1 exits
    db $03, $04, $00, $80, $00, $00, $00  ; exit (3,4)→mt$00 Castle gate scr=0 spawn(0,0)
    db $FF  ; terminator

RoomSub_ArenaBattle:  ; $7C45 — mt=[$5D]
    dw StepBlk_ArenaBattle_s0  ; screen 0

StepBlk_ArenaBattle_s0:  ; $7C47 — RAM=$D999, 5 steps
    dw $D999  ; RAM step counter
    db $14, $23  ; step 0: layout=$14 bank=$23
    dw Interact_ArenaBattle_s0  ; → interact/NPC data
    dw $FFFF  ; → exit data
    db $15, $23  ; step 1: layout=$15 bank=$23
    dw Interact_ArenaBattle_s0  ; → interact/NPC data
    dw $FFFF  ; → exit data
    db $15, $23  ; step 2: layout=$15 bank=$23
    dw Interact_ArenaBattle_s0_v1  ; → interact/NPC data
    dw $FFFF  ; → exit data
    db $15, $23  ; step 3: layout=$15 bank=$23
    dw Interact_ArenaBattle_s0_v2  ; → interact/NPC data
    dw $FFFF  ; → exit data
    db $15, $23  ; step 4: layout=$15 bank=$23
    dw Interact_ArenaBattle_s0  ; → interact/NPC data
    dw $FFFF  ; → exit data

Interact_ArenaBattle_s0:  ; $7C67 — 8 NPCs
    db $10, $F0, $04, $09, $FF  ; NPC left b=0 spr=$F0 (4,9) script=none
    db $10, $F1, $04, $0A, $FF  ; NPC left b=0 spr=$F1 (4,10) script=none
    db $10, $F3, $04, $0B, $FF  ; NPC left b=0 spr=$F3 (4,11) script=none
    db $10, $F2, $04, $0C, $FF  ; NPC left b=0 spr=$F2 (4,12) script=none
    db $10, $E0, $07, $05, $FF  ; NPC left b=0 spr=$E0 (7,5) script=none
    db $10, $E1, $06, $05, $FF  ; NPC left b=0 spr=$E1 (6,5) script=none
    db $10, $E2, $06, $04, $FF  ; NPC left b=0 spr=$E2 (6,4) script=none
    db $10, $E3, $06, $06, $FF  ; NPC left b=0 spr=$E3 (6,6) script=none
    db $FF  ; terminator

Interact_ArenaBattle_s0_v1:  ; $7C90 — 8 NPCs
    db $40, $F0, $04, $05, $FF  ; NPC noTalk down b=0 spr=$F0 (4,5) script=none
    db $70, $F3, $03, $04, $FF  ; NPC noTalk right b=0 spr=$F3 (3,4) script=none
    db $70, $F1, $03, $05, $FF  ; NPC noTalk right b=0 spr=$F1 (3,5) script=none
    db $70, $F2, $03, $06, $FF  ; NPC noTalk right b=0 spr=$F2 (3,6) script=none
    db $10, $E1, $06, $05, $FF  ; NPC left b=0 spr=$E1 (6,5) script=none
    db $10, $E2, $06, $04, $FF  ; NPC left b=0 spr=$E2 (6,4) script=none
    db $10, $E3, $06, $06, $FF  ; NPC left b=0 spr=$E3 (6,6) script=none
    db $40, $52, $04, $05, $FF  ; NPC noTalk down b=0 spr=$52 (4,5) script=none
    db $FF  ; terminator

Interact_ArenaBattle_s0_v2:  ; $7CB9 — 8 NPCs
    db $30, $F0, $02, $05, $FF  ; NPC right b=0 spr=$F0 (2,5) script=none
    db $30, $F3, $03, $04, $FF  ; NPC right b=0 spr=$F3 (3,4) script=none
    db $30, $F1, $03, $05, $FF  ; NPC right b=0 spr=$F1 (3,5) script=none
    db $30, $F2, $03, $06, $FF  ; NPC right b=0 spr=$F2 (3,6) script=none
    db $10, $E1, $06, $05, $FF  ; NPC left b=0 spr=$E1 (6,5) script=none
    db $10, $E2, $06, $04, $FF  ; NPC left b=0 spr=$E2 (6,4) script=none
    db $50, $39, $0A, $01, $FF  ; NPC noTalk left b=0 spr=$39 (10,1) script=none
    db $10, $E3, $06, $06, $FF  ; NPC left b=0 spr=$E3 (6,6) script=none
    db $FF  ; terminator

RoomSub_Room_5E:  ; $7CE2 — mt=[$5E]
    dw StepBlk_Room_5E_s0  ; screen 0

StepBlk_Room_5E_s0:  ; $7CE4 — RAM=$D99A, 4 steps
    dw $D99A  ; RAM step counter
    db $17, $23  ; step 0: layout=$17 bank=$23
    dw Interact_Room_5E_s0  ; → interact/NPC data
    dw $FFFF  ; → exit data
    db $17, $23  ; step 1: layout=$17 bank=$23
    dw Interact_Room_5E_s0_v1  ; → interact/NPC data
    dw $FFFF  ; → exit data
    db $17, $23  ; step 2: layout=$17 bank=$23
    dw Interact_Room_5E_s0_v2  ; → interact/NPC data
    dw $FFFF  ; → exit data
    db $17, $23  ; step 3: layout=$17 bank=$23
    dw $4B42  ; → interact/NPC data
    dw $FFFF  ; → exit data

Interact_Room_5E_s0:  ; $7CFE — 3 NPCs
    db $10, $E0, $07, $05, $FF  ; NPC left b=0 spr=$E0 (7,5) script=none
    db $40, $57, $04, $00, $FF  ; NPC noTalk down b=0 spr=$57 (4,0) script=none
    db $40, $52, $04, $05, $FF  ; NPC noTalk down b=0 spr=$52 (4,5) script=none
    db $FF  ; terminator

Interact_Room_5E_s0_v1:  ; $7D0E — 2 NPCs
    db $70, $08, $00, $04, $FF  ; NPC noTalk right b=0 spr=$08 (0,4) script=none
    db $40, $55, $05, $04, $FF  ; NPC noTalk down b=0 spr=$55 (5,4) script=none
    db $FF  ; terminator

Interact_Room_5E_s0_v2:  ; $7D19 — 2 NPCs
    db $20, $E0, $05, $05, $FF  ; NPC up b=0 spr=$E0 (5,5) script=none
    db $50, $21, $09, $05, $FF  ; NPC noTalk left b=0 spr=$21 (9,5) script=none
    db $FF  ; terminator

; --- TRAILING DATA ($7D24-$7FFF, 732 bytes) ---
; Sprite/tile graphics data
    db $E0, $1F, $70, $8F, $18, $E7, $83, $7C, $07, $F8, $C1, $3E, $81, $FF, $C0, $FF
    db $C0, $FF, $81, $FF, $81, $FF, $03, $FF, $03, $FF, $81, $FF, $04, $04, $0A, $0E
    db $35, $3B, $CA, $F7, $33, $CF, $81, $FF, $67, $FF, $9C, $7F, $1C, $E3, $36, $C9
    db $22, $DD, $82, $7D, $C0, $3F, $C1, $3E, $49, $B6, $1D, $E2, $07, $F8, $70, $8F
    db $C1, $3E, $83, $7C, $C1, $3E, $60, $9F, $0E, $F1, $1C, $E3, $C0, $FF, $81, $FF
    db $81, $FF, $03, $FF, $03, $FF, $81, $FF, $81, $FF, $C0, $FF, $01, $01, $82, $83
    db $4D, $CE, $B2, $FD, $CC, $F3, $62, $FF, $9D, $FF, $72, $FD, $11, $EE, $41, $BE
    db $60, $9F, $E0, $1F, $A4, $5B, $8E, $71, $0E, $F1, $1B, $E4, $C1, $3E, $07, $F8
    db $0E, $F1, $07, $F8, $81, $7E, $38, $C7, $70, $8F, $1C, $E3, $81, $FF, $03, $FF
    db $03, $FF, $81, $FF, $81, $FF, $C0, $FF, $C0, $FF, $81, $FF, $40, $40, $A0, $E0
    db $53, $B3, $AC, $7F, $33, $FC, $18, $FF, $76, $FF, $C9, $F7, $30, $CF, $70, $8F
    db $52, $AD, $47, $B8, $07, $F8, $8D, $72, $88, $77, $A0, $5F, $1C, $E3, $38, $C7
    db $1C, $E3, $06, $F9, $E0, $1F, $C1, $3E, $70, $8F, $07, $F8, $03, $FF, $81, $FF
    db $81, $FF, $C0, $FF, $C0, $FF, $81, $FF, $81, $FF, $03, $FF, $00, $FF, $00, $FF
    db $00, $FF, $10, $EF, $20, $CF, $40, $8F, $40, $9E, $40, $88, $00, $FF, $00, $FF
    db $00, $FF, $08, $F7, $04, $F3, $02, $F1, $02, $79, $02, $11, $20, $C0, $60, $80
    db $A0, $10, $92, $22, $97, $17, $97, $17, $BE, $3E, $B8, $38, $04, $03, $06, $01
    db $05, $08, $49, $44, $E9, $E8, $E9, $E8, $7D, $7C, $1D, $1C, $04, $FB, $0E, $F5
    db $0F, $F6, $0F, $F7, $0F, $F7, $3F, $CF, $7D, $AD, $78, $A8, $20, $DF, $70, $AF
    db $F0, $6F, $F0, $EF, $F0, $EF, $FC, $F3, $BE, $B5, $1E, $15, $70, $B0, $60, $A0
    db $60, $A0, $20, $C0, $20, $C0, $10, $E0, $10, $E0, $10, $E0, $0E, $0D, $06, $05
    db $06, $05, $04, $03, $04, $03, $08, $07, $08, $07, $08, $07, $00, $FF, $00, $FF
    db $00, $FF, $10, $EF, $20, $CF, $40, $8F, $40, $9E, $40, $88, $00, $FF, $00, $FF
    db $00, $FF, $08, $F7, $04, $F3, $02, $F1, $02, $79, $02, $11, $20, $C0, $60, $80
    db $A0, $10, $92, $22, $97, $17, $97, $17, $BE, $3E, $B8, $38, $04, $03, $06, $01
    db $05, $08, $49, $44, $E9, $E8, $E9, $E8, $7D, $7C, $1D, $1C, $04, $FB, $0E, $F5
    db $0F, $F6, $0F, $F7, $0F, $F7, $3F, $CF, $7D, $AD, $78, $A8, $20, $DF, $70, $AF
    db $F0, $6F, $F0, $EF, $F0, $EF, $FC, $F3, $BE, $B5, $1E, $15, $70, $B0, $60, $A0
    db $60, $A0, $20, $C0, $20, $C0, $10, $E0, $10, $E0, $10, $E0, $0E, $0D, $06, $05
    db $06, $05, $04, $03, $04, $03, $08, $07, $08, $07, $08, $07, $10, $10, $28, $38
    db $D4, $EC, $2B, $DF, $CC, $3F, $26, $FF, $D9, $FF, $27, $DF, $06, $F9, $1D, $E2
    db $3B, $C4, $F7, $08, $2E, $D1, $6D, $92, $6D, $92, $B6, $48, $C0, $3F, $6A, $95
    db $BA, $45, $BA, $45, $DC, $23, $6A, $95, $6E, $91, $DC, $23, $00, $FF, $40, $BA
    db $A0, $5F, $40, $BF, $00, $FF, $08, $57, $14, $EB, $08, $F7, $04, $04, $0A, $0E
    db $35, $3B, $CA, $F7, $33, $CF, $81, $FF, $67, $FF, $9C, $7F, $03, $FC, $16, $E9
    db $0E, $F1, $FD, $02, $1B, $E4, $36, $C9, $55, $AA, $BA, $44, $60, $9F, $BA, $45
    db $DA, $25, $DE, $21, $EC, $13, $F6, $09, $76, $89, $EE, $11, $00, $FF, $00, $FA
    db $08, $F7, $14, $EB, $09, $F6, $82, $5D, $01, $EE, $00, $FF, $01, $01, $82, $83
    db $4D, $CE, $B2, $FD, $CC, $F3, $62, $FF, $9D, $FF, $72, $FD, $06, $F9, $1D, $E2
    db $3B, $C4, $F7, $08, $2E, $D1, $6D, $92, $6D, $92, $B6, $48, $C0, $3F, $6A, $95
    db $BA, $45, $BA, $45, $DC, $23, $6A, $95, $6E, $91, $DC, $23, $00, $FF, $02, $F8
    db $05, $FA, $02, $FD, $00, $FF, $40, $1F, $A0, $4F, $40, $BF, $40, $40, $A0, $E0
    db $53, $B3, $AC, $7F, $33, $FC, $18, $FF, $76, $FF, $C9, $F7, $03, $FC, $16, $E9
    db $0E, $F1, $FD, $02, $1B, $E4, $36, $C9, $55, $AA, $BA, $44, $60, $9F, $BA, $45
    db $DA, $25, $DE, $21, $EC, $13, $F6, $09, $76, $89, $EE, $11, $00, $FF, $00, $FA
    db $80, $7F, $41, $BE, $90, $6F, $28, $57, $10, $CF, $00, $FF
