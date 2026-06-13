; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

; ===========================================================================
; Bank $04 — NPC Interaction Engine & Script System
; ===========================================================================
; This bank is the core NPC interaction handler. It manages:
;   - NPC sprite loading and OAM assembly (entries 0-3)
;   - Per-frame NPC interaction state machine (entry 4)
;   - Script executor with 100-opcode command set (entry 5)
;   - Text ID dispatch to ROM0 text rendering (entry 6)
;
; Script Architecture:
;   Entry 5 calls MapTypeDispatch which dispatches to banks $0C/$0D/$0E/$0F
;   based on $D8D3 (map_type). Those banks return the next script command
;   as a BC pair:
;     BC = $FFFF → script ended
;     B != $FF  → BC is a 16-bit text ID, queued to $D8D9/$D8DA
;     B == $FF  → C is an opcode index into the 100-entry command table
;
; Key RAM Variables:
;   $D7D2+     NPC RAM buffer (32 bytes per NPC, up to 40 NPCs)
;   $D8D3      Map type copy (selects script data bank via MapTypeDispatch)
;   $D8D4      NPC script_id (selects per-NPC script data in script bank)
;   $D8D5-D8D6 Script counter / event counter (16-bit)
;   $D8D7      Script state flags (see bit definitions below)
;   $D8D8      Secondary state flags
;   $D8D9-D8DA Queued text ID (16-bit, low/high)
;   $D8DB      Delay counter (frames to wait)
;   $D8DC      NPC number for pending interaction
;   $D8DD-D8DE NPC X movement delta (signed 16-bit)
;   $D8DF-D8E0 NPC Y movement delta (signed 16-bit)
;
; $D8D7 Bit Definitions:
;   Bit 0: Script is active/running
;   Bit 1: Text ID queued for display (consumed by entry 6)
;   Bit 2: Delay/wait active (countdown via $D8DB)
;   Bit 3: NPC walk-toward-player pending
;   Bit 4: NPC position update pending (group A)
;   Bit 5: Movement lock / suppress NPC facing updates
;   Bit 6: NPC position update pending (group B)
; ===========================================================================

SECTION "ROM Bank $004", ROMX[$4000], BANK[$4]

  db $04 ;ROM Bank

; Jump table: 7 entry points called via rst $10 with H=$04
    dw NPCSpriteLoad         ; Entry 0 ($400F): NPC sprite dispatch (via $0D91)
    dw NPCSpriteLoadAlt      ; Entry 1 ($4016): NPC sprite dispatch variant (via SaveScr_40cd)
    dw NPCInteractDispatch   ; Entry 2 ($4081): NPC interaction routing by $FFC7
    dw NPCInteractDispatchB  ; Entry 3 ($40A7): NPC interaction routing variant
    dw NPCFrameUpdate        ; Entry 4 ($4167): Per-frame NPC state machine (MAIN ENTRY)
    dw ScriptInit            ; Entry 5 ($55EC): Initialize & run NPC script
    dw TextQueueCheck        ; Entry 6 ($56FA): Check & dispatch queued text ID

; ---------------------------------------------------------------------------
; Entry 0: NPCSpriteLoad
; Loads NPC sprite data into OAM via the sprite table at $401D.
; Called during room initialization to set up NPC visuals.
; ---------------------------------------------------------------------------
NPCSpriteLoad:
label400f:
    ld de, $401d
    call $0d91
    ret

; ---------------------------------------------------------------------------
; Entry 1: NPCSpriteLoadAlt
; Variant of entry 0, uses SaveScr_40cd instead of $0D91.
; ---------------------------------------------------------------------------
NPCSpriteLoadAlt:
label4016:
    ld de, $401d
    call SaveScr_40cd
    ret

    db $23, $40, $2a, $40, $3d, $40, $25, $40, $00, $00, $00, $00, $80, $2c, $40, $00
    db $00, $00, $10, $00, $08, $01, $10, $08, $00, $02, $10, $08, $08, $03, $10, $80
    db $45, $40, $4e, $40, $63, $40, $70, $40, $00, $00, $90, $00, $08, $00, $91, $00
    db $80, $00, $00, $a6, $00, $00, $08, $a7, $00, $00, $10, $a8, $00, $00, $30, $a4
    db $00, $08, $30, $a5, $00, $80, $f8, $08, $00, $00, $00, $00, $01, $00, $00, $08
    db $02, $00, $80, $00, $00, $00, $00, $00, $08, $01, $00, $08, $00, $10, $00, $08
    db $08, $11, $00, $80


; ---------------------------------------------------------------------------
; Entry 2: NPCInteractDispatch
; Routes NPC interactions based on $FFC7 (NPC interaction index).
; $FFC7 < $10:  local handler via HramScr_4126 + sprite table
; $FFC7 $10-$8F: bank $10 entry 0 (rst $10 → $10:fn0)
; $FFC7 >= $90:  bank $11 entry 0 (rst $10 → $11:fn0)
; ---------------------------------------------------------------------------
NPCInteractDispatch:
label4081:
    ldh a, [$c7]        ; load(h) the contents of ffc7 into a
    cp $90              ; compare $90 to a (ffc7)
    jr nc, NPCDispatchBank11  ; jump if a(ffc7) >= $90

    cp $10              ; compare $10 to a(ffc7)
    jr nc, NPCDispatchBank10  ; jump if a(ffc7) >= $10

    call HramScr_4126
    ld de, data_4137        ; load 4137 into de
    call $0d91
    ret


NPCDispatchBank10:
    sub $10            ; subreact $10 from a(ffc7)
    ldh [$c7], a       ; load(h) a(ffc7 -$10) into the contents of ffc7
    ld hl, $1000
    rst $10
    ret


NPCDispatchBank11:
    sub $90            ; subtract $90 from a(ffc7)
    ldh [$c7], a       ; load(h) a(ffc7 -$90) into the contents of ffc7
    ld hl, $1100       ; load 1100 into hl
    rst $10            ; call bank ff10 func 4005
    ret

; ---------------------------------------------------------------------------
; Entry 3: NPCInteractDispatchB
; Same routing as entry 2 but uses SaveScr_40cd instead of $0D91.
; ---------------------------------------------------------------------------
NPCInteractDispatchB:
label40a7:
    ldh a, [$c7]       ; load(h) the contents of ffc7 into a
    cp $90             ; compare $90 to a (ffc7)
    jr nc, NPCDispatchBBank11 ; jump if a(ffc7) >= $90

    cp $10             ; compare $10 to a(ffc7)
    jr nc, NPCDispatchBBank10 ; jump if a(ffc7) >= $10

    call HramScr_4126
    ld de, data_4137       ;  load 4137 into de
    call SaveScr_40cd
    ret


NPCDispatchBBank10:
    sub $10            ; subreact $10 from a(ffc7)
    ldh [$c7], a       ; load(h) a(ffc7 -$10) into the contents of ffc7
    ld hl, $1001       ; load 1000 into hl
    rst $10            ; call bank $10 func 4005
    ret


NPCDispatchBBank11:
    sub $90            ; subtract $90 from a(ffc7)
    ldh [$c7], a       ; load(h) a(ffc7 -$90) into the contents of ffc7
    ld hl, $1101       ; load 1100 into hl
    rst $10            ; call bank $10 func 4005
    ret


SaveScr_40cd:
    push af
    push bc
    push de
    push hl
    ldh a, [$cb]       ; load(h) the contents of ffcb into a
    cp $28             ; compare $28 to a
    jr nc, SpriteLoadDone ; jump if a(ffcb) >= $28

    ldh a, [$c7]       ; load(h)ffc7 into a
    ld l, a            ; load a into l
    ld h, $00          ; load $00 into h
    add hl, hl         ; x2 hl
    add hl, de         ; de + hl (hl x2)
    ld e, [hl]         ; load the contents of hl(hlx2+de) into e
    inc hl             ; +1 to hl(hlx2+de)
    ld d, [hl]         ; load the contents of hl(hlx2+de+1) into d
    ldh a, [$c8]       ; load(h) the contents of ffc8 into a
    ld l, a            ; load a(ffc8) into l
    ld h, $00          ; load $00 into h
    add hl, hl         ; x2 hl
    add hl, de         ; add de to hl([hlx2+de+1] x2)
    ld e, [hl]         ; load the contents of hl ([hlx2+de+1]x2 +de) into e
    inc hl             ; +1 to hl([hlx2+de+1] x2 +de)
    ld d, [hl]         ; load the contents of hl([hlx2+de+1] x2 +de +1) into d
    ldh a, [$cb]       ; load(h) ffcb into a
    sla a              ; x2 a(ffcb)
    sla a              ; x2 a(ffcbx2)
    ld l, a            ; load a((ffcbx2) x2) into a
    ld h, $c0          ; load $c0 into h

CopySpriteDataLoop:
    ld a, [de]         ; load the contents of de(hlx2+1) into a
    inc de             ; +1 to de
    cp $80             ; compare $80 to a
    jr z, SpriteLoadDone  ; jump to 4121 if not 0

    ld b, a            ; load a(hlx2+1) into b
    ldh a, [$c5]       ; load(h) the contents of ffc5 into a
    add b              ; add b(hlx2+1) to a(ffc5)
    add $10            ; +$10 to a
    ld [hl+], a        ; load a(ffc5 + $10) into hl and +1
    ld a, [de]         ; load the contents of de(hlx2+2) into a
    inc de             ; +1 to de
    ld b, a            ; load a(hlx2+2) into b
    ldh a, [$c3]       ;
    add b
    add $08
    ld [hl+], a
    ldh a, [$c9]
    ld b, a
    ld a, [de]
    inc de
    add b
    ld [hl+], a
    ld a, [de]
    inc de
    ld b, a
    ldh a, [$ca]
    xor b
    ld [hl+], a
    ldh a, [$cb]
    inc a
    ldh [$cb], a
    cp $28
    jr c, CopySpriteDataLoop

SpriteLoadDone:
    pop hl
    pop de
    pop bc
    pop af
    ret


HramScr_4126:
    ldh a, [$c7]
    ld hl, data_4157
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ldh a, [$ca]
    or [hl]
    ldh [$ca], a
    ret

data_4137:
    db $37, $72, $38, $77, $38, $77, $38, $77, $38, $77, $38, $77, $38, $77, $38, $77
    db $38, $77, $38, $77, $38, $77, $38, $77, $38, $77, $38, $77, $38, $77, $38, $77

data_4157:
    db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02


; ---------------------------------------------------------------------------
; Entry 4: NPCFrameUpdate — Per-Frame NPC Interaction State Machine
; ---------------------------------------------------------------------------
; Called every frame by the game loop. Manages the script state machine:
;
; Flow:
; 1. Guard checks: wGameState bits, $C850 busy, $C825 UI busy
; 2. Check $D8D7 bit 0 (script active):
;    - If clear → return (no script running)
;    - If set, check bit 1 (text queued):
;      * If text queued → return (wait for text display to finish)
; 3. Handle pending operations:
;    - Bit 4/6: NPC position updates via LoadScr_43ec
;    - Bit 2: Delay countdown ($D8DB)
;    - Bit 3: NPC walk-toward via CheckPendingNPC → ResolveNPCIndex
; 4. If none pending: call LoadScr_55f5 to execute next script command
; ---------------------------------------------------------------------------
NPCFrameUpdate:
label4167:
    ld a, [wGameState]
    res 0, a
    res 2, a
    or a
    ret nz

    ld a, [wGameState]
    bit 0, a
    jr z, CheckDelayBit

    ld a, [$c915]
    cp $0b
    ret nz

    jr CheckScriptBusy

CheckDelayBit:
    bit 2, a
    jr z, CheckScriptBusy

    ld a, [$c91e]
    cp $02
    ret nz

CheckScriptBusy:
    ld a, [$c850]            ; System busy flag
    or a
    ret nz                   ; Return if system busy

    ld a, [$c825]            ; UI interaction busy flag
    or a
    ret nz                   ; Return if UI busy

    ld a, [wScriptStateFlags]            ; Script state flags
    bit 0, a
    jp z, RetFromFrameUpdate      ; Bit 0 clear = no script running → return

    bit 1, a
    jp nz, RetFromFrameUpdate     ; Bit 1 set = text queued, wait for display → return

    ld a, [wScriptStateFlags]
    bit 4, a                 ; Bit 4: NPC position update pending (group A)
    call nz, LoadScr_43ec
    ld a, [wScriptStateFlags]
    bit 6, a                 ; Bit 6: NPC position update pending (group B)
    call nz, LoadScr_43ec
    ld a, [wScriptStateFlags]
    bit 2, a                 ; Bit 2: delay/wait active
    jr nz, CheckFrameCounter

    bit 3, a                 ; Bit 3: NPC walk-toward pending
    jp nz, CheckPendingNPC

CheckSecondaryDelay:
    ld a, [$d8d8]            ; Secondary state flags
    bit 2, a                 ; Bit 2: secondary delay active
    jp nz, DecrementDelay

ContinueScript:
    call LoadScr_55f5       ; → ScriptExecContinue: run next script command

RetFromFrameUpdate:
    ret


CheckFrameCounter:
    ld a, [$c8a4]
    and $07
    jr nz, JumpToRetFromFrame

    ld a, [$d8db]
    dec a
    ld [$d8db], a
    jr nz, JumpToRetFromFrame

    ld hl, wScriptStateFlags
    res 2, [hl]

JumpToRetFromFrame:
    jp RetFromFrameUpdate


; ---------------------------------------------------------------------------
; NPCWalkToward — Handle NPC walking toward player
; ---------------------------------------------------------------------------
; When bit 3 of $D8D7 is set, an NPC is walking toward the player.
; $D8DC holds the NPC number. If non-zero, goes to NPCIndexLookup.
; Otherwise handles the step-by-step movement using $D8DD/$D8DE (X delta)
; and $D8DF/$D8E0 (Y delta), updating NPC position via HRAM $FF90-$FF96.
;
; Movement direction is written to $FF8E:
;   $00 = down, $01 = up, $02 = right, $03 = left
; ---------------------------------------------------------------------------
CheckPendingNPC:
    ld a, [$d8dc]            ; NPC number for pending interaction
    or a
    jp nz, ResolveNPCIndex     ; If NPC specified → NPCIndexLookup

    ld hl, $ff90
    set 0, [hl]              ; Mark NPC as moving
    ld a, [$c8a4]            ; Interaction type
    and $03
    cp $01
    jp z, RetToCallerAlias      ; Type 1 → skip movement

    ld a, [$d8dd]
    ld l, a
    ld a, [$d8de]
    ld h, a
    ld a, h
    or l
    jr z, ProcessNPCMoveYSetup

    bit 7, h
    jr nz, ProcessNPCMoveX

    ld a, [$d8dd]
    sub $01
    ld [$d8dd], a
    ld a, [$d8de]
    sbc $00
    ld [$d8de], a
    ldh a, [$92]
    add $01
    ldh [$92], a
    ldh a, [$93]
    adc $00
    ldh [$93], a
    ld a, [wScriptStateFlags]
    bit 5, a
    jp nz, CallWalkAndReturnAlias

    ld a, $03
    ldh [$8e], a
    jp CallWalkAndReturnAlias


ProcessNPCMoveX:
    ld a, [$d8dd]
    add $01
    ld [$d8dd], a
    ld a, [$d8de]
    adc $00
    ld [$d8de], a
    ldh a, [$92]
    sub $01
    ldh [$92], a
    ldh a, [$93]
    sbc $00
    ldh [$93], a
    ld a, [wScriptStateFlags]
    bit 5, a
    jr nz, CallWalkAndReturn

    ld a, $01
    ldh [$8e], a
    jr CallWalkAndReturn

ProcessNPCMoveYSetup:
    ld a, [$d8df]
    ld l, a
    ld a, [$d8e0]
    ld h, a
    ld a, h
    or l
    jr z, ClearMovementLock

    bit 7, h
    jr nz, ProcessNPCMoveY

    ld a, [$d8df]
    sub $01
    ld [$d8df], a
    ld a, [$d8e0]
    sbc $00
    ld [$d8e0], a
    ldh a, [$95]
    add $01
    ldh [$95], a
    ldh a, [$96]
    adc $00
    ldh [$96], a
    ld a, [wScriptStateFlags]
    bit 5, a
    jr nz, CallWalkAndReturn

    ld a, $00
    ldh [$8e], a
    jr CallWalkAndReturn

ProcessNPCMoveY:
    ld a, [$d8df]
    add $01
    ld [$d8df], a
    ld a, [$d8e0]
    adc $00
    ld [$d8e0], a
    ldh a, [$95]
    sub $01
    ldh [$95], a
    ldh a, [$96]
    sbc $00
    ldh [$96], a
    ld a, [wScriptStateFlags]
    bit 5, a
    jr nz, CallWalkAndReturn

    ld a, $02
    ldh [$8e], a

CallWalkAndReturnAlias:
CallWalkAndReturn:
    call LoadScr_454b
    jp RetToCallerAlias


ClearMovementLock:
    ld hl, $ff90
    res 0, [hl]
    ld hl, wScriptStateFlags
    res 3, [hl]
    jp RetToCallerAlias


; ---------------------------------------------------------------------------
; NPCIndexLookup — Calculate NPC RAM buffer address from NPC number
; ---------------------------------------------------------------------------
; Input:  A = NPC number (1-based)
; Output: HL = $D7D2 + (A-1) × 32 (NPC RAM buffer start)
;         $FFD5/$FFD6 = HL (cached NPC pointer)
;         Sets bit 0 at HL+5 (interacting flag)
;
; Then checks interaction type ($C8A4 AND 3):
;   == 1: just set flags and return
;   != 1: proceed to NPC movement/walk-toward logic using $D8DD/$D8DE
; ---------------------------------------------------------------------------
ResolveNPCIndex:
    dec a                    ; NPC number 1-based → 0-based
    swap a                   ; × 16
    add a                    ; × 32 (total: 32 bytes per NPC)
    ld hl, $d7d2             ; NPC RAM buffer base
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a                  ; HL = $D7D2 + (npc-1)*32
    ld a, l
    ldh [$d5], a             ; Cache NPC pointer low → $FFD5
    ld a, h
    ldh [$d6], a             ; Cache NPC pointer high → $FFD6
    ld a, l
    add $05
    ld l, a
    ld a, h
    adc $00
    ld h, a                  ; HL = NPC buffer + 5 (status byte)
    set 0, [hl]              ; Set bit 0: NPC is being interacted with
    res 6, [hl]              ; Clear bit 6
    ld a, [$c8a4]            ; Interaction type
    and $03
    cp $01                   ; Type 1 = simple talk (no walk-toward)
    jp z, RetToCallerAlias      ; → return via main exit

    ld a, [$d8dd]
    ld e, a
    ld a, [$d8de]
    ld d, a
    ld a, d
    or e
    jr z, SetupNPCMoveYDelta

    bit 7, d
    jr nz, AdvanceNPCMoveX

    ld a, [$d8dd]
    sub $01
    ld [$d8dd], a
    ld a, [$d8de]
    sbc $00
    ld [$d8de], a
    inc hl
    ld a, [wScriptStateFlags]
    bit 5, a
    jr nz, AddNPCXOffset

    ld [hl], $03

AddNPCXOffset:
    ld a, l
    add $12
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    inc de
    dec hl
    ld [hl], e
    inc hl
    ld [hl], d
    jp RetToCallerAlias


AdvanceNPCMoveX:
    ld a, [$d8dd]
    add $01
    ld [$d8dd], a
    ld a, [$d8de]
    adc $00
    ld [$d8de], a
    inc hl
    ld a, [wScriptStateFlags]
    bit 5, a
    jr nz, AddNPCYOffset

    ld [hl], $01

AddNPCYOffset:
    ld a, l
    add $12
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    dec de
    dec hl
    ld [hl], e
    inc hl
    ld [hl], d
    jr RetToCaller

SetupNPCMoveYDelta:
    ld a, [$d8df]
    ld e, a
    ld a, [$d8e0]
    ld d, a
    ld a, d
    or e
    jr z, CacheNPCPointer

    bit 7, d
    jr nz, AdvanceNPCMoveY

    ld a, [$d8df]
    sub $01
    ld [$d8df], a
    ld a, [$d8e0]
    sbc $00
    ld [$d8e0], a
    inc hl
    ld a, [wScriptStateFlags]
    bit 5, a
    jr nz, AddNPCYOffsetB

    ld [hl], $00

AddNPCYOffsetB:
    ld a, l
    add $14
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    inc de
    dec hl
    ld [hl], e
    inc hl
    ld [hl], d
    jr RetToCaller

AdvanceNPCMoveY:
    ld a, [$d8df]
    add $01
    ld [$d8df], a
    ld a, [$d8e0]
    adc $00
    ld [$d8e0], a
    inc hl
    ld a, [wScriptStateFlags]
    bit 5, a
    jr nz, AddNPCYOffsetC

    ld [hl], $02

AddNPCYOffsetC:
    ld a, l
    add $14
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    dec de
    dec hl
    ld [hl], e
    inc hl
    ld [hl], d
    jr RetToCaller

; Movement complete: clear NPC interaction flags
CacheNPCPointer:
    ldh a, [$d5]             ; Cached NPC pointer low
    add $05
    ld l, a
    ldh a, [$d6]             ; Cached NPC pointer high
    adc $00
    ld h, a                  ; HL = NPC buffer + 5 (status byte)
    res 0, [hl]              ; Clear interacting flag
    ld hl, wScriptStateFlags
    res 3, [hl]              ; Clear walk-toward pending flag

; ---------------------------------------------------------------------------
; ScriptReturn — Main exit point for entry 4
; All paths through entry 4 converge here via JP/JR.
; ---------------------------------------------------------------------------
RetToCallerAlias:
RetToCaller:
    jp RetFromFrameUpdate         ; Return to caller


DecrementDelay:
    ld a, [$d8db]
    dec a
    ld [$d8db], a
    jr nz, JumpRetFromFrame2

    ld hl, $d8d8
    res 2, [hl]

JumpRetFromFrame2:
    jp RetFromFrameUpdate


; ---------------------------------------------------------------------------
; NPCPositionUpdateAll — Check and update positions for up to 8 NPCs
; ---------------------------------------------------------------------------
; Iterates through 8 NPC movement buffers at $D8E9, $D8F1, $D8F9, ...
; (spaced 8 bytes apart). Accumulates OR of all movement states.
; If all NPCs have finished moving (result is zero), clears bits 4 and 6
; of $D8D7 (position update pending flags).
; ---------------------------------------------------------------------------
LoadScr_43ec:
    ld a, [$d8e9]
    push af
    call LoadScr_443d
    pop af
    ld hl, $d8f1
    or [hl]
    push af
    call ReadScr_4584
    pop af
    ld hl, $d8f9
    or [hl]
    push af
    call ReadScr_4584
    pop af
    ld hl, $d901
    or [hl]
    push af
    call ReadScr_4584
    pop af
    ld hl, $d909
    or [hl]
    push af
    call ReadScr_4584
    pop af
    ld hl, $d911
    or [hl]
    push af
    call ReadScr_4584
    pop af
    ld hl, $d919
    or [hl]
    push af
    call ReadScr_4584
    pop af
    ld hl, $d921
    or [hl]
    push af
    call ReadScr_4584
    pop af
    or a
    ret nz

    ld hl, wScriptStateFlags
    res 4, [hl]
    res 6, [hl]
    ret


LoadScr_443d:
    ld a, [$d8e9]
    or a
    ret z

    ld a, [wScriptStateFlags]
    set 4, a
    ld [wScriptStateFlags], a
    ld hl, $d8e9
    ld a, l
    ldh [$d7], a
    ld a, h
    ldh [$d8], a
    ld a, [$d8eb]
    ld hl, $ff95
    cp $01
    jp z, SetupOpcodeTable

    cp $03
    jp z, OpcodeHandler0B

    cp $04
    jp z, OpcodeHandler1A

    cp $06
    jp z, OpcodeHandlerAdvance

    cp $07
    jp z, OpcodeHandler0D

    cp $1a
    jp z, OpcodeHandler2D

    ld hl, $ff90
    set 0, [hl]
    ld a, [$c8a4]
    and $03
    cp $01
    ret z

    ld a, [$d8ed]
    ld l, a
    ld a, [$d8ee]
    ld h, a
    ld a, h
    or l
    jr z, SetupWalkYDelta

    bit 7, h
    jr nz, AdvanceWalkCounterX

    ld a, [$d8ed]
    sub $01
    ld [$d8ed], a
    ld a, [$d8ee]
    sbc $00
    ld [$d8ee], a
    ldh a, [$92]
    add $01
    ldh [$92], a
    ldh a, [$93]
    adc $00
    ldh [$93], a
    ld a, [wScriptStateFlags]
    bit 5, a
    jp nz, Jump_004_454b

    ld a, $03
    ldh [$8e], a
    jp Jump_004_454b


AdvanceWalkCounterX:
    ld a, [$d8ed]
    add $01
    ld [$d8ed], a
    ld a, [$d8ee]
    adc $00
    ld [$d8ee], a
    ldh a, [$92]
    sub $01
    ldh [$92], a
    ldh a, [$93]
    sbc $00
    ldh [$93], a
    ld a, [wScriptStateFlags]
    bit 5, a
    jp nz, Jump_004_454b

    ld a, $01
    ldh [$8e], a
    jp Jump_004_454b


SetupWalkYDelta:
    ld a, [$d8ef]
    ld l, a
    ld a, [$d8f0]
    ld h, a
    ld a, h
    or l
    jp z, ClearMoveLockBit

    bit 7, h
    jr nz, AdvanceWalkCounterY

    ld a, [$d8ef]
    sub $01
    ld [$d8ef], a
    ld a, [$d8f0]
    sbc $00
    ld [$d8f0], a
    ldh a, [$95]
    add $01
    ldh [$95], a
    ldh a, [$96]
    adc $00
    ldh [$96], a
    ld a, [wScriptStateFlags]
    bit 5, a
    jr nz, ClearMovementFlags

    ld a, $00
    ldh [$8e], a
    jr ClearMovementFlags

AdvanceWalkCounterY:
    ld a, [$d8ef]
    add $01
    ld [$d8ef], a
    ld a, [$d8f0]
    adc $00
    ld [$d8f0], a
    ldh a, [$95]
    sub $01
    ldh [$95], a
    ldh a, [$96]
    sbc $00
    ldh [$96], a
    ld a, [wScriptStateFlags]
    bit 5, a
    jr nz, ClearMovementFlags

    ld a, $02
    ldh [$8e], a

; ---------------------------------------------------------------------------
; NPCMovementSetup — Convert direction to movement rendering parameters
; ---------------------------------------------------------------------------
; Reads $FF8E (direction: 0=down, 1=up, 2=right, 3=left)
; Sets $FF8D (sprite offset) and $FF8F (movement axis):
;   Dir 0 (down):  $8D=$00, $8F=$00
;   Dir 1 (up):    $8D=$20, $8F=$01
;   Dir 2 (right): $8D=$00, $8F=$02
;   Dir 3 (left):  $8D=$00, $8F=$01
; ---------------------------------------------------------------------------
LoadScr_454b:
Jump_004_454b:
ClearMovementFlags:
    ld a, $00
    ldh [$8d], a
    ld a, $00
    ldh [$8f], a
    ldh a, [$8e]
    or a
    ret z

    ld a, $20
    ldh [$8d], a
    ld a, $01
    ldh [$8f], a
    ldh a, [$8e]
    cp $01
    ret z

    ld a, $00
    ldh [$8d], a
    ld a, $02
    ldh [$8f], a
    ldh a, [$8e]
    cp $02
    ret z

    ld a, $00
    ldh [$8d], a
    ld a, $01
    ldh [$8f], a
    ret


ClearMoveLockBit:
    ld hl, $ff90
    res 0, [hl]
    xor a
    ld [$d8e9], a
    ret


ReadScr_4584:
    ld a, [hl]
    or a
    ret z

    ld a, [wScriptStateFlags]
    set 4, a
    ld [wScriptStateFlags], a
    ld a, l
    ldh [$d7], a
    ld a, h
    ldh [$d8], a
    inc hl
    inc hl
    inc hl
    ld a, [hl]
    dec a
    swap a
    add a
    ld hl, $d7d2
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, l
    ldh [$d5], a
    ld a, h
    ldh [$d6], a
    ldh a, [$d7]
    add $02
    ld c, a
    ldh a, [$d8]
    adc $00
    ld b, a
    ld a, [bc]
    push af
    ldh a, [$d5]
    add $1a
    ld l, a
    ldh a, [$d6]
    adc $00
    ld h, a
    pop af
    cp $01
    jp z, SetupOpcodeTable

    cp $02
    jp z, OpcodeHandler0A

    cp $04
    jp z, OpcodeHandler1A

    cp $05
    jp z, OpcodeHandler1B

    cp $08
    jp z, OpcodeHandlerAdvance2

    cp $09
    jp z, OpcodeHandler0E

    cp $0a
    jp z, OpcodeHandler12

    cp $0b
    jp z, OpcodeHandler1C

    cp $0c
    jp z, OpcodeHandler47

    cp $0d
    jp z, OpcodeHandlerAdvance3

    cp $0e
    jp z, OpcodeHandler48

    cp $0f
    jp z, OpcodeHandler49

    cp $10
    jp z, OpcodeHandler14

    cp $11
    jp z, OpcodeHandler15

    cp $12
    jp z, OpcodeHandler16

    cp $13
    jp z, OpcodeHandler17

    cp $14
    jp z, OpcodeHandler22

    cp $15
    jp z, OpcodeHandlerAdvance4

    cp $16
    jp z, OpcodeHandlerAdvance5

    cp $17
    jp z, OpcodeHandlerE3

    cp $18
    jp z, OpcodeHandlerE3B

    cp $19
    jp z, OpcodeHandler2C

    ldh a, [$d5]
    add $05
    ld l, a
    ldh a, [$d6]
    adc $00
    ld h, a
    set 0, [hl]
    res 6, [hl]
    ld a, [$c8a4]
    and $03
    cp $01
    ret z

    ldh a, [$d7]
    add $04
    ld c, a
    ldh a, [$d8]
    adc $00
    ld b, a
    ld a, [bc]
    ld e, a
    inc bc
    ld a, [bc]
    ld d, a
    ld a, d
    or e
    jr z, AddYAddrOffset

    bit 7, d
    jr nz, AddXAddrOffset

    ldh a, [$d7]
    add $04
    ld c, a
    ldh a, [$d8]
    adc $00
    ld b, a
    ld a, [bc]
    sub $01
    ld [bc], a
    inc bc
    ld a, [bc]
    sbc $00
    ld [bc], a
    inc hl
    ld a, [wScriptStateFlags]
    bit 5, a
    jr nz, AddXCoordOffset

    ld [hl], $03

AddXCoordOffset:
    ld a, l
    add $12
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    inc de
    dec hl
    ld [hl], e
    inc hl
    ld [hl], d
    ret


AddXAddrOffset:
    ldh a, [$d7]
    add $04
    ld c, a
    ldh a, [$d8]
    adc $00
    ld b, a
    ld a, [bc]
    add $01
    ld [bc], a
    inc bc
    ld a, [bc]
    adc $00
    ld [bc], a
    inc hl
    ld a, [wScriptStateFlags]
    bit 5, a
    jr nz, AddYCoordOffset

    ld [hl], $01

AddYCoordOffset:
    ld a, l
    add $12
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    dec de
    dec hl
    ld [hl], e
    inc hl
    ld [hl], d
    ret


AddYAddrOffset:
    ldh a, [$d7]
    add $06
    ld c, a
    ldh a, [$d8]
    adc $00
    ld b, a
    ld a, [bc]
    ld e, a
    inc bc
    ld a, [bc]
    ld d, a
    ld a, d
    or e
    jr z, CacheNPCPtrLow

    bit 7, d
    jr nz, AddYAddrOffsetB

    ldh a, [$d7]
    add $06
    ld c, a
    ldh a, [$d8]
    adc $00
    ld b, a
    ld a, [bc]
    sub $01
    ld [bc], a
    inc bc
    ld a, [bc]
    sbc $00
    ld [bc], a
    inc hl
    ld a, [wScriptStateFlags]
    bit 5, a
    jr nz, AddXCoordOffsetB

    ld [hl], $00

AddXCoordOffsetB:
    ld a, l
    add $14
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    inc de
    dec hl
    ld [hl], e
    inc hl
    ld [hl], d
    ret


AddYAddrOffsetB:
    ldh a, [$d7]
    add $06
    ld c, a
    ldh a, [$d8]
    adc $00
    ld b, a
    ld a, [bc]
    add $01
    ld [bc], a
    inc bc
    ld a, [bc]
    adc $00
    ld [bc], a
    inc hl
    ld a, [wScriptStateFlags]
    bit 5, a
    jr nz, AddYCoordOffsetB

    ld [hl], $02

AddYCoordOffsetB:
    ld a, l
    add $14
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    dec de
    dec hl
    ld [hl], e
    inc hl
    ld [hl], d
    ret


CacheNPCPtrLow:
    ldh a, [$d5]
    add $05
    ld l, a
    ldh a, [$d6]
    adc $00
    ld h, a
    res 0, [hl]
    ldh a, [$d7]
    ld l, a
    ldh a, [$d8]
    ld h, a
    ld [hl], $00
    ret


SetupOpcodeTable:
    ld bc, $4770

HramScr_4745:
Jump_004_4745:
    ldh a, [$d7]
    add $01
    ld e, a
    ldh a, [$d8]
    adc $00
    ld d, a
    ld a, [de]
    push af
    inc a
    ld [de], a
    pop af
    add a
    add c
    ld c, a
    ld a, $00
    adc b
    ld b, a
    ld a, [bc]
    cp $80
    jr z, ReadScriptWord

    add [hl]
    ld [hl+], a
    inc bc
    ld a, [bc]
    adc [hl]
    ld [hl], a
    ret


ReadScriptWordAlias:
ReadScriptWord:
    ldh a, [$d7]
    ld l, a
    ldh a, [$d8]
    ld h, a
    ld [hl], $00
    ret


    db $fd, $ff, $fd, $ff, $fe, $ff, $ff, $ff, $ff, $ff, $00, $00, $00, $00, $01, $00
    db $01, $00, $02, $00, $03, $00, $03, $00, $80, $80

OpcodeHandler0A:
    ld bc, $4790
    jp Jump_004_4745


    db $fb, $ff, $fb, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fd, $ff, $fd, $ff
    db $fd, $ff, $fe, $ff, $fe, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $00, $00, $00, $00
    db $01, $00, $01, $00, $01, $00, $02, $00, $02, $00, $03, $00, $80, $80

OpcodeHandler0B:
    ld bc, $47d9
    call HramScr_4745
    ld a, [$c850]
    or a
    ret nz

    ld a, [$c8a6]
    and $03
    ret z

    ldh a, [$8e]
    inc a
    and $03
    ldh [$8e], a
    jp Jump_004_454b


    db $fe, $ff, $fe, $ff, $fe, $ff, $fd, $ff, $fd, $ff, $fc, $ff, $fc, $ff, $fc, $ff
    db $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff
    db $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $04, $00, $04, $00
    db $04, $00, $04, $00, $04, $00, $04, $00, $04, $00, $04, $00, $80, $80

OpcodeHandler1A:
    ld bc, $485d
    jp Jump_004_4745


    db $fc, $ff, $fd, $ff, $fd, $ff, $fe, $ff, $fe, $ff, $ff, $ff, $ff, $ff, $00, $00
    db $00, $00, $01, $00, $01, $00, $02, $00, $02, $00, $03, $00, $03, $00, $04, $00
    db $80, $80

OpcodeHandler1B:
    ld bc, $4892
    call HramScr_4745
    ldh a, [$d5]
    add $18
    ld l, a
    ldh a, [$d6]
    adc $00
    ld h, a
    inc [hl]
    inc [hl]
    ret


    db $fb, $ff, $fb, $ff, $fb, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fd, $ff, $fd, $ff
    db $fe, $ff, $ff, $ff, $ff, $ff, $00, $00, $00, $00, $00, $00, $01, $00, $01, $00
    db $02, $00, $02, $00, $02, $00, $03, $00, $03, $00, $03, $00, $04, $00, $04, $00
    db $04, $00, $fa, $ff, $fc, $ff, $fd, $ff, $fe, $ff, $ff, $ff, $ff, $ff, $00, $00
    db $00, $00, $01, $00, $01, $00, $02, $00, $03, $00, $04, $00, $06, $00, $80, $80

OpcodeHandlerAdvance:
    ldh a, [$d7]
    add $01
    ld e, a
    ldh a, [$d8]
    adc $00
    ld d, a
    ld a, [de]
    inc a
    ld [de], a
    cp $40
    jr nz, ReadPartyMemberAddr

    ldh a, [$d7]
    ld l, a
    ldh a, [$d8]
    ld h, a
    ld [hl], $00
    ret


ReadPartyMemberAddr:
    ld a, [$ca37]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    ld a, l
    add $73
    ld l, a
    ld a, h
    adc $c9
    ld h, a
    ldh a, [$92]
    ld [hl+], a
    ldh a, [$95]
    ld [hl+], a
    ldh a, [$93]
    swap a
    ld c, a
    ldh a, [$96]
    or c
    ld [hl+], a
    ldh a, [$8b]
    ld c, a
    ldh a, [$8d]
    or c
    ld [hl+], a
    ld a, [$ca37]
    inc a
    ld [$ca37], a
    cp $31
    ret c

    xor a
    ld [$ca37], a
    ret


OpcodeHandler0D:
    ld bc, $494c
    call HramScr_4745
    ldh a, [$92]
    ld l, a
    ldh a, [$93]
    ld h, a
    ld a, l
    sub $02
    ld l, a
    ld a, h
    sbc $00
    ld h, a
    ld a, l
    ldh [$92], a
    ld a, h
    ldh [$93], a
    ret


    db $fc, $ff, $fc, $ff, $fd, $ff, $fd, $ff, $fe, $ff, $fe, $ff, $fe, $ff, $fe, $ff
    db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $01, $00, $01, $00, $01, $00, $01, $00, $02, $00
    db $02, $00, $02, $00, $02, $00, $03, $00, $03, $00, $04, $00, $04, $00, $80, $80

OpcodeHandlerAdvance2:
    ldh a, [$d7]
    add $01
    ld e, a
    ldh a, [$d8]
    adc $00
    ld d, a
    ld a, [de]
    inc a
    ld [de], a
    cp $ff
    jr nz, PushAndCachePtr

    ldh a, [$d7]
    ld l, a
    ldh a, [$d8]
    ld h, a
    ld [hl], $00
    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
    ld h, a
    ld [hl], $00
    ret


PushAndCachePtr:
    push af
    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
    ld h, a
    pop af
    ld b, $0f
    cp $20
    jr c, CheckAndBranch

    ld b, $07
    cp $50
    jr c, CheckAndBranch

    ld b, $03
    cp $90
    jr c, CheckAndBranch

    ld b, $01

CheckAndBranch:
    and b
    or a
    ld [hl], $00
    ret z

    ld [hl], $40
    ret


OpcodeHandler0E:
    ld bc, $4a0a
    call HramScr_4745
    ld a, [$c850]
    or a
    ret nz

    ldh a, [$d5]
    add $05
    ld l, a
    ldh a, [$d6]
    adc $00
    ld h, a
    ld [hl], $00
    ldh a, [$d7]
    add $01
    ld e, a
    ldh a, [$d8]
    adc $00
    ld d, a
    ld a, [de]
    srl a
    srl a
    and $03
    push af
    ldh a, [$d5]
    add $06
    ld l, a
    ldh a, [$d6]
    adc $00
    ld h, a
    pop af
    ld [hl], a
    jp Jump_004_454b


    db $fc, $ff, $fd, $ff, $fd, $ff, $fe, $ff, $fe, $ff, $ff, $ff, $ff, $ff, $00, $00
    db $00, $00, $01, $00, $01, $00, $02, $00, $02, $00, $03, $00, $03, $00, $04, $00
    db $80, $80

OpcodeHandler12:
    ld bc, $4a32
    jp Jump_004_4745


    db $fb, $ff, $fb, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fd, $ff, $fd, $ff, $fd, $ff
    db $fe, $ff, $fe, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $00, $00, $00, $00, $80, $80

OpcodeHandler1C:
    ld bc, $4a58
    jp Jump_004_4745


    db $fc, $ff, $fc, $ff, $fc, $ff, $fd, $ff, $fd, $ff, $fd, $ff, $fe, $ff, $fe, $ff
    db $ff, $ff, $ff, $ff, $ff, $ff, $00, $00, $00, $00, $01, $00, $01, $00, $02, $00
    db $02, $00, $02, $00, $00, $00, $00, $00, $00, $00, $fb, $ff, $fb, $ff, $fc, $ff
    db $fc, $ff, $fc, $ff, $fd, $ff, $fd, $ff, $fd, $ff, $fe, $ff, $fe, $ff, $ff, $ff
    db $ff, $ff, $ff, $ff, $00, $00, $00, $00, $80, $80

OpcodeHandler47:
    ld bc, $4ab5
    call HramScr_4745
    ldh a, [$d5]
    add $18
    ld l, a
    ldh a, [$d6]
    adc $00
    ld h, a
    dec [hl]
    dec [hl]
    ret


    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $01, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00
    db $01, $00, $01, $00, $01, $00, $01, $00, $02, $00, $01, $00, $02, $00, $01, $00
    db $02, $00, $01, $00, $02, $00, $01, $00, $02, $00, $02, $00, $02, $00, $02, $00
    db $02, $00, $02, $00, $02, $00, $02, $00, $02, $00, $03, $00, $02, $00, $03, $00
    db $80, $80

OpcodeHandlerAdvance3:
    ldh a, [$d7]
    add $01
    ld e, a
    ldh a, [$d8]
    adc $00
    ld d, a
    ld a, [de]
    inc a
    ld [de], a
    cp $ff
    jr nz, PushAndCachePtr2

    ldh a, [$d7]
    ld l, a
    ldh a, [$d8]
    ld h, a
    ld [hl], $00
    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
    ld h, a
    ld [hl], $40
    ret


PushAndCachePtr2:
    push af
    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
    ld h, a
    pop af
    ld b, $0f
    cp $20
    jr c, CheckAndBranch2

    ld b, $07
    cp $50
    jr c, CheckAndBranch2

    ld b, $03
    cp $90
    jr c, CheckAndBranch2

    ld b, $01

CheckAndBranch2:
    and b
    or a
    ld [hl], $40
    ret z

    ld [hl], $00
    ret


OpcodeHandler48:
    ld a, [$c8a6]
    and $03
    ret nz

    ld bc, $4b79
    jp Jump_004_4745


    db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
    db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
    db $80, $80

OpcodeHandler49:
    ld bc, $4ba1
    jp Jump_004_4745


    db $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff
    db $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff
    db $fd, $ff, $fd, $ff, $fd, $ff, $fe, $ff, $fe, $ff, $ff, $ff, $ff, $ff, $ff, $ff
    db $00, $00, $00, $00, $01, $00, $01, $00, $01, $00, $02, $00, $02, $00, $03, $00
    db $03, $00, $03, $00, $80, $80

OpcodeHandler14:
    ld bc, $4bed
    jp Jump_004_4745


    db $fd, $ff, $fd, $ff, $fd, $ff, $fe, $ff, $fe, $ff, $ff, $ff, $ff, $ff, $ff, $ff
    db $00, $00, $00, $00, $01, $00, $01, $00, $01, $00, $02, $00, $02, $00, $03, $00
    db $03, $00, $03, $00, $04, $00, $04, $00, $04, $00, $04, $00, $04, $00, $04, $00
    db $04, $00, $04, $00, $04, $00, $04, $00, $04, $00, $04, $00, $04, $00, $04, $00
    db $04, $00, $04, $00, $80, $80

OpcodeHandler15:
    ld bc, $4c39
    jp Jump_004_4745


    db $03, $00, $03, $00, $03, $00, $03, $00, $03, $00, $03, $00, $03, $00, $03, $00
    db $03, $00, $03, $00, $03, $00, $03, $00, $03, $00, $03, $00, $03, $00, $03, $00
    db $03, $00, $03, $00, $03, $00, $03, $00, $04, $00, $80, $80

OpcodeHandler16:
    ld bc, $4c6b
    jp Jump_004_4745


    db $fd, $ff, $fd, $ff, $fd, $ff, $fe, $ff, $fe, $ff, $ff, $ff, $ff, $ff, $ff, $ff
    db $00, $00, $00, $00, $01, $00, $01, $00, $01, $00, $02, $00, $02, $00, $03, $00
    db $03, $00, $03, $00, $04, $00, $04, $00, $04, $00, $05, $00, $05, $00, $05, $00
    db $05, $00, $80, $80

OpcodeHandler17:
    ld bc, $4ca5
    jp Jump_004_4745


    db $fe, $ff, $fe, $ff, $fe, $ff, $fd, $ff, $fd, $ff, $fc, $ff, $fc, $ff, $fc, $ff
    db $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff
    db $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $04, $00, $04, $00
    db $04, $00, $04, $00, $04, $00, $04, $00, $04, $00, $04, $00, $04, $00, $04, $00
    db $80, $80

OpcodeHandler22:
    call LoadScr_4d5c
    ld a, [$c850]
    or a
    ret nz

    ldh a, [$d5]
    add $05
    ld l, a
    ldh a, [$d6]
    adc $00
    ld h, a
    ld [hl], $00
    ldh a, [$d7]
    add $01
    ld e, a
    ldh a, [$d8]
    adc $00
    ld d, a
    ld a, [de]
    srl a
    srl a
    and $03
    push af
    ldh a, [$d5]
    add $06
    ld l, a
    ldh a, [$d6]
    adc $00
    ld h, a
    pop af
    ld [hl], a
    jp Jump_004_454b


LoadScr_4d5c:
    ld a, [$c8a6]
    and $01
    ret nz

    ldh a, [$d7]
    add $01
    ld e, a
    ldh a, [$d8]
    adc $00
    ld d, a
    ld a, [de]
    inc a
    ld [de], a
    cp $ff
    jr nz, PushAndCachePtr3

    ldh a, [$d7]
    ld l, a
    ldh a, [$d8]
    ld h, a
    ld [hl], $00
    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
    ld h, a
    ld [hl], $00
    ret


PushAndCachePtr3:
    push af
    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
    ld h, a
    pop af
    ld b, $0f
    cp $20
    jr c, CheckAndBranch3

    ld b, $07
    cp $50
    jr c, CheckAndBranch3

    ld b, $03
    cp $90
    jr c, CheckAndBranch3

    ld b, $01

CheckAndBranch3:
    and b
    or a
    ld [hl], $00
    ret z

    ld [hl], $40
    ret


OpcodeHandlerAdvance4:
    ldh a, [$d7]
    add $01
    ld e, a
    ldh a, [$d8]
    adc $00
    ld d, a
    ld a, [de]
    or a
    jr nz, SetupBranchTable

    ld a, [$d8e3]
    ld c, a
    ld a, $0a
    sub c
    add a
    add a
    add a
    inc a
    ld [de], a

SetupBranchTable:
    ld a, [$d8e4]
    ld bc, $4df3
    cp $01
    jr z, CallAndCachePtr

    ld bc, $4e95
    cp $02
    jr z, CallAndCachePtr

    ld bc, $4f37
    cp $03
    jr z, CallAndCachePtr

    ld bc, $4fd9

CallAndCachePtr:
    call HramScr_4745
    ldh a, [$d5]
    add $18
    ld l, a
    ldh a, [$d6]
    adc $00
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    dec bc
    dec bc
    ld a, b
    ld [hl-], a
    ld [hl], c
    ret


    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00, $00, $00
    db $01, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00
    db $01, $00, $01, $00, $01, $00, $01, $00, $02, $00, $01, $00, $02, $00, $02, $00
    db $80, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00
    db $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01, $00
    db $01, $00, $01, $00, $01, $00, $02, $00, $01, $00, $02, $00, $01, $00, $02, $00
    db $01, $00, $02, $00, $01, $00, $02, $00, $01, $00, $02, $00, $02, $00, $02, $00
    db $03, $00, $80, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00
    db $01, $00, $00, $00, $01, $00, $01, $00, $01, $00, $01, $00, $02, $00, $01, $00
    db $02, $00, $01, $00, $02, $00, $01, $00, $02, $00, $01, $00, $02, $00, $02, $00
    db $02, $00, $02, $00, $02, $00, $02, $00, $02, $00, $03, $00, $02, $00, $03, $00
    db $03, $00, $03, $00, $80, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00, $00, $00, $01, $00
    db $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01, $00
    db $01, $00, $01, $00, $01, $00, $02, $00, $01, $00, $02, $00, $01, $00, $02, $00
    db $01, $00, $02, $00, $02, $00, $02, $00, $02, $00, $02, $00, $02, $00, $02, $00
    db $02, $00, $03, $00, $02, $00, $02, $00, $03, $00, $02, $00, $03, $00, $04, $00
    db $03, $00, $04, $00, $04, $00, $80, $80

OpcodeHandlerAdvance5:
    ldh a, [$d7]
    add $01
    ld e, a
    ldh a, [$d8]
    adc $00
    ld d, a
    ld a, [de]
    or a
    jr nz, SetupBranchTable2

    ld a, [$d8e3]
    ld c, a
    ld a, $0a
    sub c
    add a
    add a
    add a
    inc a
    ld [de], a

SetupBranchTable2:
    ld a, [$d8e4]
    ld bc, $4df3
    cp $01
    jr z, CallAndCachePtr2

    ld bc, $4e95
    cp $02
    jr z, CallAndCachePtr2

    ld bc, $4f37
    cp $03
    jr z, CallAndCachePtr2

    ld bc, $4fd9

CallAndCachePtr2:
    call HramScr_4745
    ldh a, [$d5]
    add $18
    ld l, a
    ldh a, [$d6]
    adc $00
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    inc bc
    inc bc
    ld a, b
    ld [hl-], a
    ld [hl], c
    ret


OpcodeHandlerE3:
    ld a, [$d8e3]
    ld bc, $5144
    cp $01
    jr z, OpcodeAdvanceE3

    ld bc, $5156
    cp $02
    jr z, OpcodeAdvanceE3

    ld bc, $5178
    cp $03
    jr z, OpcodeAdvanceE3

    ld bc, $51aa
    cp $04
    jr z, OpcodeAdvanceE3

    ld bc, $51ec
    cp $05
    jr z, OpcodeAdvanceE3

    ld bc, $523e
    cp $06
    jr z, OpcodeAdvanceE3

    ld bc, $52a0
    cp $07
    jr z, OpcodeAdvanceE3

    ld bc, $5312
    cp $08
    jr z, OpcodeAdvanceE3

    ld bc, $5394
    cp $09
    jr z, OpcodeAdvanceE3

    ld bc, $5426

OpcodeAdvanceE3:
    ldh a, [$d7]
    add $01
    ld e, a
    ldh a, [$d8]
    adc $00
    ld d, a
    ld a, [de]
    push af
    inc a
    ld [de], a
    pop af
    add a
    add c
    ld c, a
    ld a, $00
    adc b
    ld b, a
    ld a, [bc]
    cp $80
    jp z, ReadScriptWordAlias

    ld d, a
    ld a, [hl]
    sub d
    ld [hl+], a
    inc bc
    ld a, [bc]
    ld d, a
    ld a, [hl]
    sbc d
    ld [hl], a
    ldh a, [$d5]
    add $18
    ld l, a
    ldh a, [$d6]
    adc $00
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    dec bc
    dec bc
    ld a, b
    ld [hl-], a
    ld [hl], c
    ret


    db $03, $00, $03, $00, $03, $00, $02, $00, $03, $00, $02, $00, $02, $00, $02, $00
    db $80, $80, $03, $00, $03, $00, $03, $00, $02, $00, $03, $00, $02, $00, $02, $00
    db $02, $00, $02, $00, $02, $00, $02, $00, $02, $00, $01, $00, $02, $00, $01, $00
    db $02, $00, $80, $80, $03, $00, $03, $00, $03, $00, $02, $00, $03, $00, $02, $00
    db $02, $00, $02, $00, $02, $00, $02, $00, $02, $00, $02, $00, $01, $00, $02, $00
    db $01, $00, $02, $00, $01, $00, $02, $00, $01, $00, $02, $00, $01, $00, $01, $00
    db $01, $00, $01, $00, $80, $80, $03, $00, $03, $00, $03, $00, $02, $00, $03, $00
    db $02, $00, $02, $00, $02, $00, $02, $00, $02, $00, $02, $00, $02, $00, $01, $00
    db $02, $00, $01, $00, $02, $00, $01, $00, $02, $00, $01, $00, $02, $00, $01, $00
    db $01, $00, $01, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00
    db $01, $00, $00, $00, $01, $00, $80, $80, $03, $00, $03, $00, $03, $00, $02, $00
    db $03, $00, $02, $00, $02, $00, $02, $00, $02, $00, $02, $00, $02, $00, $02, $00
    db $01, $00, $02, $00, $01, $00, $02, $00, $01, $00, $02, $00, $01, $00, $02, $00
    db $01, $00, $01, $00, $01, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01, $00
    db $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $80, $80, $03, $00, $03, $00, $03, $00
    db $02, $00, $03, $00, $02, $00, $02, $00, $02, $00, $02, $00, $02, $00, $02, $00
    db $02, $00, $01, $00, $02, $00, $01, $00, $02, $00, $01, $00, $02, $00, $01, $00
    db $02, $00, $01, $00, $01, $00, $01, $00, $01, $00, $00, $00, $01, $00, $00, $00
    db $01, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $80, $03, $00, $03, $00
    db $03, $00, $02, $00, $03, $00, $02, $00, $02, $00, $02, $00, $02, $00, $02, $00
    db $02, $00, $02, $00, $01, $00, $02, $00, $01, $00, $02, $00, $01, $00, $02, $00
    db $01, $00, $02, $00, $01, $00, $01, $00, $01, $00, $01, $00, $00, $00, $01, $00
    db $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $80, $03, $00
    db $03, $00, $03, $00, $02, $00, $03, $00, $02, $00, $02, $00, $02, $00, $02, $00
    db $02, $00, $02, $00, $02, $00, $01, $00, $02, $00, $01, $00, $02, $00, $01, $00
    db $02, $00, $01, $00, $02, $00, $01, $00, $01, $00, $01, $00, $01, $00, $00, $00
    db $01, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $80
    db $03, $00, $03, $00, $03, $00, $02, $00, $03, $00, $02, $00, $02, $00, $02, $00
    db $02, $00, $02, $00, $02, $00, $02, $00, $01, $00, $02, $00, $01, $00, $02, $00
    db $01, $00, $02, $00, $01, $00, $02, $00, $01, $00, $01, $00, $01, $00, $01, $00
    db $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $80, $80, $03, $00, $03, $00, $03, $00, $02, $00, $03, $00, $02, $00, $02, $00
    db $02, $00, $02, $00, $02, $00, $02, $00, $02, $00, $01, $00, $02, $00, $01, $00
    db $02, $00, $01, $00, $02, $00, $01, $00, $02, $00, $01, $00, $01, $00, $01, $00
    db $01, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00
    db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $80, $80

OpcodeHandlerE3B:
    ld a, [$d8e3]
    ld bc, $5144
    cp $01
    jr z, OpcodeAdvanceE3B

    ld bc, $5156
    cp $02
    jr z, OpcodeAdvanceE3B

    ld bc, $5178
    cp $03
    jr z, OpcodeAdvanceE3B

    ld bc, $51aa
    cp $04
    jr z, OpcodeAdvanceE3B

    ld bc, $51ec
    cp $05
    jr z, OpcodeAdvanceE3B

    ld bc, $523e
    cp $06
    jr z, OpcodeAdvanceE3B

    ld bc, $52a0
    cp $07
    jr z, OpcodeAdvanceE3B

    ld bc, $5312
    cp $08
    jr z, OpcodeAdvanceE3B

    ld bc, $5394
    cp $09
    jr z, OpcodeAdvanceE3B

    ld bc, $5426

OpcodeAdvanceE3B:
    ldh a, [$d7]
    add $01
    ld e, a
    ldh a, [$d8]
    adc $00
    ld d, a
    ld a, [de]
    push af
    inc a
    ld [de], a
    pop af
    add a
    add c
    ld c, a
    ld a, $00
    adc b
    ld b, a
    ld a, [bc]
    cp $80
    jp z, ReadScriptWordAlias

    ld d, a
    ld a, [hl]
    sub d
    ld [hl+], a
    inc bc
    ld a, [bc]
    ld d, a
    ld a, [hl]
    sbc d
    ld [hl], a
    ldh a, [$d5]
    add $18
    ld l, a
    ldh a, [$d6]
    adc $00
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    inc bc
    inc bc
    ld a, b
    ld [hl-], a
    ld [hl], c
    ret


OpcodeHandler2C:
    ld bc, $5559
    call HramScr_4745
    ldh a, [$d5]
    add $18
    ld l, a
    ldh a, [$d6]
    adc $00
    ld h, a
    dec [hl]
    dec [hl]
    ret


    db $fa, $ff, $fc, $ff, $fd, $ff, $fe, $ff, $ff, $ff, $ff, $ff, $00, $00, $00, $00
    db $01, $00, $01, $00, $02, $00, $03, $00, $04, $00, $06, $00, $fc, $ff, $fc, $ff
    db $fc, $ff, $fd, $ff, $fd, $ff, $fd, $ff, $fe, $ff, $fe, $ff, $fe, $ff, $ff, $ff
    db $ff, $ff, $00, $00, $00, $00, $00, $00, $01, $00, $01, $00, $02, $00, $03, $00
    db $03, $00, $04, $00, $04, $00, $04, $00, $05, $00, $05, $00, $05, $00, $80, $80

OpcodeHandler2D:
    ld bc, $55ca
    call HramScr_4745
    ld a, [$c850]
    or a
    ret nz

    ldh a, [$d7]
    add $01
    ld e, a
    ldh a, [$d8]
    adc $00
    ld d, a
    ld a, [de]
    srl a
    srl a
    and $03
    ldh [$8e], a
    jp Jump_004_454b


    db $fc, $ff, $fd, $ff, $fd, $ff, $fe, $ff, $fe, $ff, $ff, $ff, $ff, $ff, $00, $00
    db $00, $00, $01, $00, $01, $00, $02, $00, $02, $00, $03, $00, $03, $00, $04, $00
    db $80, $80

; ===========================================================================
; Entry 5: ScriptInit — Initialize and begin NPC script execution
; ===========================================================================
; Resets the script counter ($D8D5/$D8D6) to 0, then falls through to the
; main script execution loop at ScriptExecNext.
; ---------------------------------------------------------------------------
ScriptInit:
label55ec:
    xor a
    ld [wScriptCounter], a            ; Reset script counter low
    ld [$d8d6], a            ; Reset script counter high
    jr ScriptExecLoop           ; → ScriptExecNext

; ---------------------------------------------------------------------------
; ScriptExecContinue — Advance counter and execute next script command
; ---------------------------------------------------------------------------
; Called from NPCFrameUpdate (entry 4) each frame when script is running
; and no text/delay is pending. Increments the event counter then runs
; the next command.
; ---------------------------------------------------------------------------
LoadScr_55f5:
Jump_004_55f5:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a            ; Increment script counter low
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a            ; Increment script counter high (16-bit inc)

; ---------------------------------------------------------------------------
; ScriptExecNext — Main script dispatch loop
; ---------------------------------------------------------------------------
; Calls ScriptDataRead (MapTypeDispatch) to fetch next BC pair from the
; script data bank ($0C/$0D/$0E/$0F based on map type).
;
; Dispatch logic:
;   BC == $FFFF → Script ended. Clear $D8D7, return.
;   B != $FF   → BC is a 16-bit text ID. Queue it via TextIDQueue ($56EC).
;   B == $FF   → C is a script opcode (0-99). Dispatch via rst $00 to
;                the 100-entry ScriptCommandTable.
; ---------------------------------------------------------------------------
ScriptExecLoopAlias:
ScriptExecLoop:
    call MapTypeDispatch       ; → ScriptDataRead: fetch next BC from script bank
    ld a, b
    and c
    cp $ff                   ; Check if BC == $FFFF
    jr nz, MarkScriptActive

    xor a
    ld [wScriptStateFlags], a            ; Script ended: clear all state flags
    ret


MarkScriptActive:
    ld hl, wScriptStateFlags
    set 0, [hl]              ; Mark script as active (bit 0)
    ld a, b
    cp $ff
    jp nz, $56ec             ; B != $FF → TextIDQueue (BC = text ID)

    ; B == $FF: C is a script command opcode
    ld a, c
    rst $00                  ; Dispatch via rst $00 jump table

; ===========================================================================
; ScriptCommandTable — 100 script opcodes ($00-$63, indexed by C when B=$FF)
; ===========================================================================
; Each entry is a 2-byte pointer to a handler function.
; Commands handle: conditional branches, variable reads/writes, NPC movement,
; sound effects, screen effects, event triggers, menu operations, etc.
;
; SCRIPT COMMAND CATALOG (refined via code analysis):
; Cmd  Label       Cat          Description
; ---  ----------  -----------  -----------
; $00  $5711       Flow         ConditionalBranchNZ: branch if flag clear
; $01  $5740       Flow         ConditionalBranchZ: branch if flag set
; $02  $576F       Event        ClearEventFlag: clear bit in $D99B+ bitfield
; $03  $5788       Event        SetEventFlag: set bit in $D99B+ bitfield
; $04  $57A1       Screen       TriggerScreenEffect: set $C8EF/$C8F0/$C8F1
; $05  $57EB       Battle       TriggerBattle: set enemy in $DA03, start fight
; $06  $5819       State        IncrementC915: inc $C915 dialogue counter
; $07  $5824       State        InitDialogMode: set wGameState bit 0, init $C917
; $08  $5842       Flow         NOP: no operation
; $09  $5843       Timer        SetDelay: set frame countdown in $D8DB
; $0A  $5860       NPC          SetNPCMoveX: set NPC + X delta, trigger walk
; $0B  $5898       NPC          SetNPCMoveY: set NPC + Y delta, trigger walk
; $0C  $58D0       NPC          SetNPCFacing: set facing via NPC buffer (81 lines)
; $0D  $5968       NPC          WriteNPCBuffer: write byte to NPC buffer (52 lines)
; $0E  $59D2       Flow         BranchByScreen: branch based on $C925 screen index
; $0F  $5A02       Map          MapTransitionFull: write $C96D-$C96F, set $C88F
; $10  $5A6F       NPC          NPCMoveToPos: move NPC to position via $D7EA (47 lines)
; $11  $5AC5       NPC          NPCMoveToPos2: move NPC to position via $D7EC
; $12  $5B1B       Flow         SkipScriptData: increment counter 2x (skip 2 params)
; $13  $5B49       Flow         ReadScriptParams: read 2 params, store to RAM
; $14  $5B79       Flow         BranchAlways: unconditional branch via $7212
; $15  $5B8F       Flow         ConditionalBranch3: complex condition + branch
; $16  $5BD4       State        ReturnFromScript: pop and continue
; $17  $5BDB       Map          GateSetup: configure gate tileset ($9380/$9600)
; $18  $5C14       Monster      MonsterPartyOp: party monster operation (bank $01/$14)
; $19  $5C6D       Timer        SetDelayAndFlags: delay + set $D8D7 flags
; $1A  $5C86       NPC          NPCMoveSequence: multi-step NPC movement ($D8E9)
; $1B  $5CCF       NPC          NPCMoveSequence2: movement variant with $D8E9
; $1C  $5D1A       NPC          NPCMoveCheck: check NPC movement completion
; $1D  $5D4B       NPC          LockMovement: set $D8D7 bit 5, suppress facing
; $1E  $5D53       NPC          UnlockMovement: clear $D8D7 bit 5
; $1F  $5D5B       Event        LargeEventHandler: 157-line event dispatcher
;                                Accesses $D7CA-$D7CE, calls bank $00/$01
; $20  $5E5E       Battle       SetBattleMode: set $DA09, $C905, $C8EB
; $21  $5E6D       Flow         SkipScriptData2: read 1 param, discard
; $22  $5E87       Script       SetD8D7Bit3: set NPC walk-toward flag
; $23  $5E8F       Monster      MonsterCheck: check monster in $CAC1 storage (62 lines)
; $24  $5F13       Data         CallScriptBank_E1: call bank $0C/$0D/$0E entry 1
; $25  $5F36       Monster      CheckPartyMonster: check party via bank $01
; $26  $5F52       State        SetC88F: set movement suppression flag
; $27  $5F5C       Monster      MonsterPartyOp2: bank $01 entry 3/9
; $28  $5F67       Monster      CheckStorageFull: branch if 20 monsters stored
; $29  $5F9A       Monster      AddMonster: add to storage by enemy stats ID
; $2A  $5FDB       Inventory    GiveItem: add item to first empty slot
; $2B  $6002       Monster      CheckMonsterLevel: check levels in storage (62 lines)
; $2C  $6064       Inventory    CheckInvFull: branch if inventory full
; $2D  $6093       Event        MassiveEventHandler: 263-line event processor
;                                Accesses $C600-$C800, bank $03/$01
; $2E  $61E0       Event        CheckStepVariable: read $D9DF/$D9E0
; $2F  $623A       Flow         ReadAndDiscard: read 2 params, continue
; $30  $6253       Monster      CheckMonsterSpecies: check $CAC2 species data
; $31  $62AB       Monster      CheckPartyLevel: check $CA94 party level
; $32  $62DD       Monster      CheckMonsterSpecies2: check $CACA species
; $33  $6332       Flow         SkipScriptData3: skip params
; $34  $634F       Monster      CheckMonsterSpecies3: check $CAEA species (50 lines)
; $35  $63BB       Monster      ResetPartyOrder: bank $01 entry 3/9
; $36  $63C6       Battle       SetupBossEncounter: set $DA02-$DA04, $CAB4
; $37  $6401       Event        CheckStoryVariable: check $D9CF region
; $38  $643F       Monster      CheckPartyMonster2: check $CAEA data (48 lines)
; $39  $64A7       Flow         ReadAndContinue: read params, continue
; $3A  $64C2       Map          GateTransition: 113-line gate transition handler
;                                Accesses $C8F2-$C8FF, bank $00/$16
; $3B  $65AB       Map          MapTransitionFade: transition with $C96D + fade
; $3C  $6618       Script       SetSecondaryDelay: set $D8D8 bit 2
; $3D  $6620       Script       ClearSecondaryDelay: clear $D8D8 bit 2
; $3E  $6628       State        ToggleC88E: toggle map rendering flag
; $3F  $6632       Monster      CheckSpeciesInParty: check $CACA for species
; $40  $6646       Monster      CheckMonsterWithBGM: monster check + $C8B6 BGM
; $41  $669D       Sound        SetBGM: save current, play new BGM
; $42  $66BD       Map          SaveMapPosition: save $C8F7-$C8FF for return
; $43  $6723       Map          RestoreMapPosition: restore and transition back
; $44  $676F       NPC          SetNPCPosAndFace: set position+facing via buffer
; $45  $67B1       Monster      FullMonsterOp: bank $01 entries 3/5/9
; $46  $67FD       Event        CheckDungeonFlags: check $DDB4/$DDCE/$DDE8
; $47  $6822       NPC          NPCBufferCheck: check NPC buffer $D7D8 area
; $48  $684D       Flow         ReadAndContinue2: read params, continue
; $49  $6866       Flow         ReadAndContinue3: read params, continue
; $4A  $687F       Flow         ReadAndContinue4: read params, continue
; $4B  $6898       Sound        ReadSavedBGM: read $C8B6 (prev BGM)
; $4C  $68A1       Sound        RestoreBGM: restore BGM from $C8B6
; $4D  $68BA       Timer        SetLongDelay: extended delay via $D8D8
; $4E  $68D7       Map          SaveGateInfo: save $C8FB-$C8FF gate state
; $4F  $690B       Map          RestoreFromGate: restore gate state, transition
; $50  $6957       NPC          SetNPCField: write to $D7F8 NPC field
; $51  $696C       Event        CheckAndBranch: check $CA94, branch (42 lines)
; $52  $69A9       Battle       BossSetup: 106-line boss battle configuration
;                                Accesses $CA8E-$CB0C monster stats
; $53  $6A61       NPC          NPCComplexOp: 74-line NPC buffer manipulation
; $54  $6ACE       State        CheckC180: check $C180 game flag
; $55  $6AFA       Monster      MonsterGive: give monster via bank $03
; $56  $6B3A       State        CheckC180_2: check $C180 variant
; $57  $6B73       State        CheckC180_3: check $C180 variant
; $58  $6BA0       Map          MapTransitionSpec: special map transition ($C939)
; $59  $6BDF       Event        HugeNPCHandler: 184-line NPC event processor
;                                Accesses $CAC0-$CAC2, bank $00/$14
; $5A  $6D56       Battle       TriggerBattle3: battle with $DA02/$DA03
; $5B  $6D84       Battle       SetBattleFlags: set $C905/$DA09
; $5C  $6D93       Battle       HugeBattleSetup: 249-line battle configuration
;                                Accesses $CA8E-$CB0C, bank $02/$0D/$14
; $5D  $6F64       Event        CheckStoryRegion: check $D9D0 region var
; $5E  $6F89       State        CheckLabyrinth: check $D951/$C0D8
; $5F  $6F9B       Monster      CheckMultiSpecies: check party species (44 lines)
; $60  $6FFB       Monster      CheckInventoryItem: check $CA40/$CB23
; $61  $7038       Data         CallScriptBank_E2: call bank $0C/$0D/$0E entry 2
; $62  $705B       Screen       VRAMTileOp: VRAM operation at $9800
; $63  $707F       Monster      MonsterSpecialOp: bank $01 entry 3 (62 lines)
; ===========================================================================

    dw label4_5711
    dw label4_5740
    dw label4_576f
    dw label4_5788
    dw label4_57a1
    dw label4_57eb
    dw label4_5819
    dw label4_5824
    dw label4_5842
    dw label4_5843
    dw label4_5860
    dw label4_5898
    dw label4_58d0
    dw label4_5968
    dw label4_59d2
    dw label4_5a02
    dw label4_5a6f
    dw label4_5ac5
    dw ArenaGenerateBattles
    dw label4_5b49
    dw label4_5b79
    dw label4_5b8f
    dw label4_5bd4
    dw label4_5bdb
    dw label4_5c14
    dw label4_5c6d
    dw label4_5c86
    dw label4_5ccf
    dw label4_5d1a
    dw label4_5d4b
    dw label4_5d53
    dw label4_5d5b
    dw label4_5e5e
    dw label4_5e6d
    dw label4_5e87
    dw label4_5e8f
    dw label4_5f13
    dw label4_5f36
    dw label4_5f52
    dw label4_5f5c
    dw label4_5f67
    dw label4_5f9a
    dw label4_5fdb
    dw label4_6002
    dw label4_6064
    dw label4_6093
    dw label4_61e0
    dw label4_623a
    dw label4_6253
    dw label4_62ab
    dw label4_62dd
    dw label4_6332
    dw label4_634f
    dw label4_63bb
    dw label4_63c6
    dw label4_6401
    dw label4_643f
    dw label4_64a7
    dw label4_64c2
    dw label4_65ab
    dw label4_6618
    dw label4_6620
    dw label4_6628
    dw label4_6632
    dw label4_6646
    dw label4_669d
    dw label4_66bd
    dw label4_6723
    dw label4_676f
    dw label4_67b1
    dw label4_67fd
    dw label4_6822
    dw label4_684d
    dw label4_6866
    dw label4_687f
    dw label4_6898
    dw label4_68a1
    dw label4_68ba
    dw label4_68d7
    dw label4_690b
    dw label4_6957
    dw label4_696c
    dw label4_69a9
    dw label4_6a61
    dw label4_6ace
    dw label4_6afa
    dw label4_6b3a
    dw label4_6b73
    dw label4_6ba0
    dw label4_6bdf
    dw label4_6d56
    dw label4_6d84
    dw ColiseumInitPrize
    dw label4_6f64
    dw label4_6f89
    dw label4_6f9b
    dw label4_6ffb
    dw label4_7038
    dw label4_705b
    dw label4_707f
    dw label4_70d5
    dw label4_71d2


; ---------------------------------------------------------------------------
; TextIDQueue — Store text ID from script and flag for display
; ---------------------------------------------------------------------------
; Input:  BC = 16-bit text ID (C=low, B=high)
; Effect: Sets $D8D7 bit 1 (text queued), stores ID to $D8D9/$D8DA
; Called when script emits a text command (B != $FF in the script stream).
; Entry 6 (TextQueueCheck) will pick this up on the next frame.
; ---------------------------------------------------------------------------
LAB_rom4__56ec:
    ld hl, wScriptStateFlags
    set 1, [hl]              ; Flag: text ID queued for display
    ld a, c
    ld [wScriptQueuedTextId], a            ; Store text ID low byte
    ld a, b
    ld [$d8da], a            ; Store text ID high byte
    ret

; ===========================================================================
; Entry 6: TextQueueCheck — Check for queued text and dispatch to ROM0
; ===========================================================================
; Called per-frame. If bit 1 of $D8D7 is set (text queued by script),
; loads the text ID from $D8D9/$D8DA into HL and calls ROM0 $0AD9
; (TextDispatchCascade) which routes to the appropriate script handler
; bank ($42-$4E) based on the text ID range.
; ---------------------------------------------------------------------------
TextQueueCheck:
label56fa:
    ld a, [wScriptStateFlags]
    bit 1, a                 ; Text queued?
    ret z                    ; No → return

ClearTextQueuedFlag:
    ld hl, wScriptStateFlags
    res 1, [hl]              ; Clear text-queued flag
    ld a, [wScriptQueuedTextId]
    ld l, a                  ; Text ID low → L
    ld a, [$d8da]
    ld h, a                  ; Text ID high → H
    call TextBankDispatch       ; → ROM0 TextDispatchCascade
    ret

; ---------------------------------------------------------------------------
; Script Command $00: ConditionalBranchNZ
; Reads next BC (condition value), calls TestEventFlag (RAM compare?).
; If NZ (condition true): continue to next command.
; If Z (condition false): read another BC and branch via ScriptBranch.
; ---------------------------------------------------------------------------
label4_5711:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch       ; Read condition parameter
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call TestEventFlag       ; Evaluate condition
    jp nz, Jump_004_55f5     ; True → continue script

    call MapTypeDispatch       ; Read branch target
    jp ScriptReturnProcess         ; → ScriptBranch (jump to target)

; ---------------------------------------------------------------------------
; Script Command $01: ConditionalBranchZ
; Same as $00 but inverted: branches if condition IS true (Z flag).
; ---------------------------------------------------------------------------
label4_5740:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call TestEventFlag
    jp z, Jump_004_55f5

    call MapTypeDispatch
    jp ScriptReturnProcess

; ---------------------------------------------------------------------------
; Script Command $02: ClearEventFlag
; Reads event flag index from script, clears that bit in the $D99B
; event bitfield via ClearEventFlag. Used to reset story state.
; ---------------------------------------------------------------------------
label4_576f:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch       ; Read event flag index
    call ClearEventFlag       ; Clear event flag
    jp Jump_004_55f5         ; Continue script

; ---------------------------------------------------------------------------
; Script Command $03: SetEventFlag
; Reads event flag index from script, sets that bit in the $D99B
; event bitfield via SetEventFlag. Used to mark story progress.
; ---------------------------------------------------------------------------
label4_5788:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    call SetEventFlag
    jp Jump_004_55f5

; ---------------------------------------------------------------------------
; Script Command $04: TriggerScreenEffect
; Reads two BC pairs: first sets $C8EF (effect type), second sets
; $C8F0/$C8F1 (effect parameters). Sets wGameState bit 4.
; Plays sound effect $59 unless effect type is $09 or $0A.
; ---------------------------------------------------------------------------
label4_57a1:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld [$c8ef], a
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld [$c8f0], a
    ld a, b
    ld [$c8f1], a
    ld hl, wGameState
    set 4, [hl]
    xor a
    ld [$c905], a
    ld a, [$c8ef]
    cp $09
    ret z

    cp $0a
    ret z

    ld a, $59
    call PlaySoundEffect
    ret


; ---------------------------------------------------------------------------
; Script Command $05: TriggerBattle
; Reads enemy stats ID from script, writes to $DA03/$DA04 (battle enemy),
; sets wGameState bit 6 (battle pending), sets $DA09=1 (battle trigger).
; ---------------------------------------------------------------------------
label4_57eb:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch       ; Read enemy stats ID
    ld a, c
    ld [wTempEnemyId1], a            ; Enemy 1 stats ID low
    ld a, b
    ld [$da04], a            ; Enemy 1 stats ID high
    xor a
    ld [$da02], a            ; Clear battle type
    ld hl, wGameState
    set 6, [hl]              ; Set battle pending flag
    xor a
    ld [$c905], a
    ld a, $01
    ld [$da09], a            ; Trigger battle
    ret


label4_5819:
    ld a, [wGameState]
    bit 0, a
    ret z

    ld hl, $c915
    inc [hl]
    ret

label4_5824:
    ld a, [wGameState]
    bit 0, a
    ret nz

    ld hl, $ffff
    ld a, l
    ld [$c917], a
    ld a, h
    ld [$c918], a
    ld hl, wGameState
    set 0, [hl]
    xor a
    ld [$c915], a
    ld [$c916], a
    ret

; ---------------------------------------------------------------------------
; Script Command $08: NOP — No operation, just returns
; ---------------------------------------------------------------------------
label4_5842:
    ret

; ---------------------------------------------------------------------------
; Script Command $09: SetDelay
; Reads delay value from script, stores to $D8DB (frame counter).
; Sets $D8D7 bit 2 (delay active). Entry 4 will decrement each frame
; and resume script execution when counter reaches 0.
; ---------------------------------------------------------------------------
label4_5843:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch       ; Read delay frame count
    ld a, c
    ld [$d8db], a            ; Set delay counter
    ld hl, wScriptStateFlags
    set 2, [hl]              ; Flag: delay active
    ret

; ---------------------------------------------------------------------------
; Script Command $0A: SetNPCMoveX
; Reads NPC number from script → $D8DC
; Reads X movement delta (signed 16-bit) → $D8DD/$D8DE
; Sets $D8D7 bit 3 (NPC walk-toward pending).
; Entry 4 will animate the NPC moving step-by-step.
; ---------------------------------------------------------------------------
label4_5860:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch       ; Read NPC number
    ld a, c
    ld [$d8dc], a            ; Store NPC number
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch       ; Read X movement delta
    ld a, c
    ld [$d8dd], a            ; X delta low (signed)
    ld a, b
    ld [$d8de], a            ; X delta high (signed, bit 7 = negative)
    ld hl, wScriptStateFlags
    set 3, [hl]              ; Flag: NPC walk-toward pending
    ret

; ---------------------------------------------------------------------------
; Script Command $0B: SetNPCMoveY
; Same as $0A but for Y axis. Reads NPC number → $D8DC,
; Y movement delta → $D8DF/$D8E0. Sets bit 3.
; ---------------------------------------------------------------------------
label4_5898:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld [$d8dc], a
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld [$d8df], a
    ld a, b
    ld [$d8e0], a
    ld hl, wScriptStateFlags
    set 3, [hl]
    ret

label4_58d0:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    or a
    jr nz, TextOpcodeNPCIndex

    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch

ScriptEndCheck:
    ld a, c
    or a
    jr nz, TextOpcodeCheck1

    ld a, $00
    ldh [$8d], a
    ld a, $00
    ldh [$8f], a
    ld a, $00
    ldh [$8e], a
    jp Jump_004_55f5

TextOpcodeCheck1Alias:
TextOpcodeCheck1:
    cp $01
    jr nz, TextOpcodeCheck2

    ld a, $20
    ldh [$8d], a
    ld a, $01
    ldh [$8f], a
    ld a, $01
    ldh [$8e], a
    jp Jump_004_55f5

TextOpcodeCheck2Alias:
TextOpcodeCheck2:
    cp $02
    jr nz, TextOpcodeCheck3

    ld a, $00
    ldh [$8d], a
    ld a, $02
    ldh [$8f], a
    ld a, $02
    ldh [$8e], a
    jp Jump_004_55f5

TextOpcodeCheck3Alias:
TextOpcodeCheck3:
    ld a, $00
    ldh [$8d], a
    ld a, $01
    ldh [$8f], a
    ld a, $03
    ldh [$8e], a
    jp Jump_004_55f5

TextOpcodeNPCIndexAlias:
TextOpcodeNPCIndex:
    dec a
    swap a
    add a
    ld hl, $d7d8
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    push hl
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    pop hl
    ld [hl], c
    jp Jump_004_55f5

label4_5968:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    or a
    jr nz, TextOpcodeNPCIndex2

    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld l, c
    ld h, b
    jr TextReadScriptPtr

TextOpcodeNPCIndex2:
    dec a
    swap a
    add a
    ld hl, $d7d2
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    push hl
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    pop hl
    add hl, bc

TextReadScriptPtr:
    push hl
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    pop hl
    ld [hl], c
    jp Jump_004_55f5

; ---------------------------------------------------------------------------
; Script Command $0E: BranchByScreen
; Reads screen_index and branch_target from script.
; If current wScreenIndex ($C925) == screen_index, branches to target.
; Otherwise skips both params and continues.
; NOTE: This is NOT a map transition (that is opcode $0F).
; ---------------------------------------------------------------------------
label4_59d2:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    ld a, [wScreenIndex]
    cp c
    jp nz, Jump_004_55f5

    call MapTypeDispatch
    jp ScriptReturnProcess

label4_5a02:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld [wWarpGateId], a
    ld a, b
    ld [wWarpFlag], a
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld [wWarpSpawnXLo], a
    ld a, b
    ld [wWarpSpawnXHi], a
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld [wWarpSpawnYLo], a
    ld a, b
    ld [wWarpSpawnYHi], a
    ld a, $01
    ld [wIsPlayerChangingMaps], a
    ld a, $03
    call SetGBCPalette
    ld hl, $c88f
    inc [hl]
    xor a
    ld [wScriptStateFlags], a
    ld hl, wGameState
    res 0, [hl]
    xor a
    ld [$c825], a
    ret

label4_5a6f:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld [$d8dc], a
    ld hl, $ff92
    or a
    jr z, TextFollowPointer

    dec a
    swap a
    add a
    ld hl, $d7ea
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a

TextFollowPointer:
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    push hl
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    pop hl
    ld a, c
    sub l
    ld c, a
    ld a, b
    sbc h
    ld b, a
    ld a, c
    ld [$d8dd], a
    ld a, b
    ld [$d8de], a
    ld hl, wScriptStateFlags
    set 3, [hl]
    ret

label4_5ac5:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld [$d8dc], a
    ld hl, $ff95
    or a
    jr z, TextFollowPointer2

    dec a
    swap a
    add a
    ld hl, $d7ec
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a

TextFollowPointer2:
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    push hl
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    pop hl
    ld a, c
    sub l
    ld c, a
    ld a, b
    sbc h
    ld b, a
    ld a, c
    ld [$d8df], a
    ld a, b
    ld [$d8e0], a
    ld hl, wScriptStateFlags
    set 3, [hl]
    ret

                        ; begining of function relating to tresure chests
ArenaGenerateBattles:                        ; inc unknown counter
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a

    call MapTypeDispatch
    ld l, c             ; load c into l
    ld h, b             ; load b into h
    push hl             ; push hl (location in ram of opened tresure chest flags)
    ld a, [wScriptCounter]       ; inc unknown counter
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a

    call MapTypeDispatch
    pop hl              ; pop hl (location in ram of opened tresure chest flags)
    ld [hl], c          ; load c (chests id bit) into the contents of hl (opened chest bit plane)
    jp Jump_004_55f5

label4_5b49:
    ld a, [wScriptCounter]       ; inc unknown counter
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a

    call MapTypeDispatch
    ld l, c             ; load c into l
    ld h, b             ; load b into h
    push hl             ; push hl (unknown)
    ld a, [wScriptCounter]       ; inc unknown counter
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a

    call MapTypeDispatch
    pop hl              ; pop hl (unknown)
    ld [hl], c          ; load c into the contents of hl (unknown)
    inc hl              ; add 1 to the pointer in hl (unknown pointer)
    ld [hl], b          ; loads b into the contents of hl (unknown)
    jp Jump_004_55f5

label4_5b79:
    ld a, [wScriptCounter]       ; inc unknown counter
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a

    call MapTypeDispatch
    jp ScriptReturnProcess

label4_5b8f:
    ld a, [wScriptCounter]       ; inc unknown counter
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a

    call MapTypeDispatch
    ld l, c             ; load c into l
    ld h, b             ; load b into h
    push hl             ; push hl (unknown)
    ld a, [wScriptCounter]       ; inc unknown counter
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a

    call MapTypeDispatch
    pop hl               ; pop hl (unknown)
    ld a, [wScriptCounter]        ; inc unknown counter
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    ld a, [hl]           ; load the contents of hl (unknown) into a
    cp c                 ; compare c to a
    jp nz, Jump_004_55f5 ; jump if a >= c

    call MapTypeDispatch
    jp ScriptReturnProcess

label4_5bd4:
    call UpdateOAMSprites
    call GetBGMapAddress
    ret

label4_5bdb:
    ld a, [wMapID]
    cp MAP_TERRYS
    jr nz, RetFromArena

    ld a, [wScreenIndex]
    cp $04
    jr z, ArenaSetupTilemap

    cp $05
    jr nz, RetFromArena

ArenaSetupTilemap:
    ld hl, $9380
    ld de, $9360
    ld b, $20
    call IntScr_5c05
    ld hl, $9600
    ld de, $9620
    ld b, $20
    call IntScr_5c05
    ret


RetFromArena:
    ret


IntScr_5c05:
jr_004_5c05:
    di
    call WaitVRAM
    ld c, [hl]
    ld a, [de]
    ld [hl+], a
    ld a, c
    ld [de], a
    ei
    inc de
    dec b
    jr nz, jr_004_5c05

    ret

label4_5c14:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld [wTempEnemyStatsId], a
    ld a, b
    ld [$da13], a
    ld de, $cac1
    ld b, $14
    ld c, $00

CheckEnemyData:
    ld a, [de]
    or a
    jr z, StoreEnemyID

    inc c
    ld a, e
    add $95
    ld e, a
    ld a, d
    adc $00
    ld d, a
    dec b
    jr nz, CheckEnemyData

    ld c, $13

StoreEnemyID:
    ld a, c
    ld [$da14], a
    ld hl, $1402
    rst $10   ;calls function at 14:4005
    ld a, [$ca8d]
    cp $03
    jr z, CallBank01ForArena

    ld hl, $ca8e
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$da14]
    ld [hl], a
    ld hl, $ca8d
    inc [hl]

CallBank01ForArena:
    ld hl, $0103
    rst $10
    ret

label4_5c6d:
    ld a, [wScriptStateFlags]
    bit 4, a
    jp z, Jump_004_55f5

    ld a, [wScriptCounter]
    sub $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    sbc $00
    ld [$d8d6], a
    ret

label4_5c86:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld hl, $d8e9
    ld a, c
    add a
    add a
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $01
    inc hl
    inc hl
    ld [hl], $00
    inc hl
    ld [hl], c
    inc hl
    push hl
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    pop hl
    ld [hl], c
    inc hl
    ld [hl], b
    ld hl, wScriptStateFlags
    set 4, [hl]
    jp Jump_004_55f5

label4_5ccf:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld hl, $d8e9
    ld a, c
    add a
    add a
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $01
    inc hl
    inc hl
    ld [hl], $00
    inc hl
    ld [hl], c
    inc hl
    inc hl
    inc hl
    push hl
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    pop hl
    ld [hl], c
    inc hl
    ld [hl], b
    ld hl, wScriptStateFlags
    set 4, [hl]
    jp Jump_004_55f5

label4_5d1a:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld hl, $d8e9
    ld a, c
    add a
    add a
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $01
    inc hl
    ld [hl], $00
    inc hl
    ld [hl], b
    inc hl
    ld [hl], c
    ld hl, wScriptStateFlags
    set 4, [hl]
    jp Jump_004_55f5

; ---------------------------------------------------------------------------
; Script Command $1D: LockMovement
; Sets bit 5 of $D8D7 which suppresses NPC facing direction updates
; during walk-toward sequences. Used during cutscenes to prevent NPCs
; from turning to face the player while being scripted to move.
; ---------------------------------------------------------------------------
label4_5d4b:
    ld hl, wScriptStateFlags
    set 5, [hl]              ; Lock NPC facing updates
    jp Jump_004_55f5          ; Continue script

; ---------------------------------------------------------------------------
; Script Command $1E: UnlockMovement
; Clears bit 5 of $D8D7, re-enabling normal NPC facing behavior.
; ---------------------------------------------------------------------------
label4_5d53:
    ld hl, wScriptStateFlags
    res 5, [hl]              ; Unlock NPC facing updates
    jp Jump_004_55f5          ; Continue script

label4_5d5b:
    ld a, [wArenaGroup]
    ld b, a
    add a
    add b
    ld b, a
    ld a, [wColiseumBattle]
    add b
    ld b, a
    add a
    add b
    ld hl, $00e0
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, l
    ld [wTempEnemyId1], a
    ld a, h
    ld [$da04], a
    inc hl
    ld a, l
    ld [$da05], a
    ld a, h
    ld [$da06], a
    inc hl
    ld a, l
    ld [$da07], a
    ld a, h
    ld [$da08], a
    ld a, $02
    ld [$da02], a
    ld a, [wArenaGroup]
    cp $09
    jr nz, ReadArenaGroup

    ld hl, $01e1
    ld a, l
    ld [wTempEnemyId1], a
    ld a, h
    ld [$da04], a
    ld hl, $01e2
    ld a, l
    ld [$da05], a
    ld a, h
    ld [$da06], a
    ld hl, $01e3
    ld a, l
    ld [$da07], a
    ld a, h
    ld [$da08], a

ReadArenaGroup:
    ld a, [wArenaGroup]  ;
    ld b, a
    add a
    add b
    ld b, a
    ld a, [wColiseumBattle]
    add b
    add a
    ld hl, $5e22
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld [$d7ca], a
    ld a, [hl]
    ld [$d7cb], a
    ld a, [wTempEnemyId1]
    ld l, a
    ld a, [$da04]
    ld h, a
    call LoadScr_5e10
    ld [$d7ce], a
    ld a, $01
    ld [$d7cf], a
    ld a, [$da05]
    ld l, a
    ld a, [$da06]
    ld h, a
    call LoadScr_5e10
    ld [$d7cc], a
    ld a, $01
    ld [$d7cd], a
    ld a, [$da07]
    ld l, a
    ld a, [$da08]
    ld h, a
    call LoadScr_5e10
    ld [$d7d0], a
    ld a, $01
    ld [$d7d1], a
    ret


LoadScr_5e10:
    ld a, l
    ld [wTempEnemyStatsId], a
    ld a, h
    ld [$da13], a
    ld hl, $1401
    rst $10
    ld a, [$da18]
    add $10
    ret


    dec bc
    nop
    ld a, [bc]
    nop
    ld de, $0b00
    nop
    ld a, [bc]
    nop
    jp c, DispatchBank42Rst

    nop
    ld a, [bc]
    nop
    dec bc
    nop
    dec bc
    nop
    ld a, [bc]
    nop
    ld [bc], a
    nop
    dec bc
    nop
    ld a, [bc]
    nop
    dec bc
    nop
    dec bc
    nop
    ld a, [bc]
    nop
    rrca
    nop
    dec bc
    nop
    ld a, [bc]
    nop
    inc c
    nop
    dec bc
    nop
    ld a, [bc]
    nop
    inc de
    nop
    dec bc
    nop
    ld a, [bc]
    nop
    inc d
    nop
    ld [$0800], sp
    nop
    db $08, $00


label4_5e5e:
    ld hl, $c8eb
    set 6, [hl]
    xor a
    ld [$c905], a
    ld a, $01
    ld [$da09], a
    ret

label4_5e6d:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    call PlaySoundEffect
    jp Jump_004_55f5

label4_5e87:
    ld hl, wScriptStateFlags
    set 6, [hl]
    jp Jump_004_55f5

label4_5e8f:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    ld a, c
    ld a, [$ca8d]
    cp c
    jp z, Jump_004_55f5

    jp c, Jump_004_55f5

    ld a, c
    ld hl, $caea
    push bc
    call GetCurrentMonsterPtr
    pop bc
    ld b, $08

CheckItemSlot:
    ld a, [hl+]
    cp $00
    jr z, StoreItemResult

    cp $01
    jr z, StoreItemResult

    cp $02
    jr z, StoreItemResult

    cp $03
    jr z, StoreItemResult

    cp $04
    jr z, StoreItemResult

    cp $05
    jr z, StoreItemResult

    cp $44
    jr z, StoreItemResult

    cp $5c
    jr z, StoreItemResult

    cp $5d
    jr z, StoreItemResult

    cp $5e
    jr z, StoreItemResult

    cp $5f
    jr z, StoreItemResult

    dec b
    jr nz, CheckItemSlot

    jp Jump_004_55f5


StoreItemResult:
    ld a, c
    ld [$d8e1], a
    ld hl, $cac2
    call GetCurrentMonsterPtr
    ld e, l
    ld d, h
    ld hl, $c180
    call Copy4Bytes
    call MapTypeDispatch
    jp ScriptReturnProcess

label4_5f13:
    ld a, [wScriptMapType]
    cp $06
    jr nc, CheckMapType20

    ld hl, $0c01
    rst $10
    ret


CheckMapType20:
    cp $20
    jr nc, CheckMapType40

    ld hl, $0d01
    rst $10
    ret


CheckMapType40:
    cp $40
    jr nc, CallBank0FForItem

    ld hl, $0e01
    rst $10
    ret


CallBank0FForItem:
    ld hl, $0f01
    rst $10
    ret

label4_5f36:
    ld a, [$d8e1]
    ld hl, $cac1
    call GetCurrentMonsterPtr
    ld [hl], $00
    ld hl, $0105
    rst $10
    ld hl, $0103
    rst $10
    call UpdateOAMSprites
    call GetBGMapAddress
    jp Jump_004_55f5

label4_5f52:
    ld a, $03
    call SetGBCPalette
    ld hl, $c88f
    inc [hl]
    ret

label4_5f5c:
    ld hl, $0109
    rst $10
    ld hl, $0103
    rst $10
    jp Jump_004_55f5

; ---------------------------------------------------------------------------
; Script Command $28: CheckMonsterStorageFull
; Iterates 20 monster slots ($CAC1, stride $95=149 bytes).
; Counts occupied slots. If count >= 20 (all full), reads branch target
; and jumps. Otherwise continues script execution.
; ---------------------------------------------------------------------------
label4_5f67:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    ld hl, $cac1
    ld b, $14
    ld c, $00

CheckInventorySlot:
    ld a, [hl]
    or a
    jr z, CheckItemCount14

    ld a, l
    add $95
    ld l, a
    ld a, h
    adc $00
    ld h, a
    inc c
    dec b
    jr nz, CheckInventorySlot

CheckItemCount14:
    ld a, c
    cp $14
    jp c, Jump_004_55f5

    call MapTypeDispatch
    jp ScriptReturnProcess

; ---------------------------------------------------------------------------
; Script Command $29: AddMonsterToStorage
; Reads enemy_stats_id from script → $DA12/$DA13.
; Finds first empty monster slot in $CAC1 array (20 slots, stride $95).
; Loads enemy stats and copies to the empty slot to add the monster.
; ---------------------------------------------------------------------------
label4_5f9a:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld [wTempEnemyStatsId], a
    ld a, b
    ld [$da13], a
    ld de, $cac1
    ld b, $14
    ld c, $00

CheckItemData:
    ld a, [de]
    or a
    jr z, StoreItemID

    inc c
    ld a, e
    add $95
    ld e, a
    ld a, d
    adc $00
    ld d, a
    dec b
    jr nz, CheckItemData

    jr RetFromItem

StoreItemID:
    ld a, c
    ld [$da14], a
    ld hl, $1402
    rst $10
    ld hl, $0103
    rst $10

RetFromItem:
    ret

; ---------------------------------------------------------------------------
; Script Command $2A: GiveItem
; Reads item ID from script. Scans wInventory (20 slots) for first empty
; slot ($00 or $FF). If found, places item there. If full, returns
; without giving (script should check with CheckInvFull first).
; ---------------------------------------------------------------------------
label4_5fdb:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld hl, wInventory
    ld b, $14

CheckEmptySlot:
    ld a, [hl]
    or a
    jr z, WriteItemToSlot

    cp $ff
    jr z, WriteItemToSlot

    inc hl
    dec b
    jr nz, CheckEmptySlot

    ret


WriteItemToSlot:
    ld [hl], c  ;loads item into empty inventory slot from treasure chest [MAY BE MORE]
    ret

label4_6002:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    ld hl, $cac1
    ld b, $14
    ld c, $00

PushAndReadSlot:
    push hl
    ld a, [hl]
    or a
    jr z, PopAndAdvance

    cp $01
    jr z, PopAndAdvance

    ld a, l
    add $4b
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl]
    cp $0a
    jr c, PopAndAdvance

    ld a, l
    add $b6
    ld l, a
    ld a, h
    adc $ff
    ld h, a
    ld de, $605c
    ld b, $08

CompareItemSlots:
    ld a, [de]
    cp [hl]
    jr nz, PopAndAdvance

    inc de
    inc hl
    dec b
    jr nz, CompareItemSlots

    pop hl
    call MapTypeDispatch
    jp ScriptReturnProcess


PopAndAdvance:
    pop hl
    ld a, l
    add $95
    ld l, a
    ld a, h
    adc $00
    ld h, a
    inc c
    dec b
    jr nz, PushAndReadSlot

    jp Jump_004_55f5


    ld h, a
    add l
    ld b, d
    adc l
    ld h, $f0
    ldh a, [$f0]


label4_6064:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    ld hl, wInventory
    ld b, $14
    ld c, $00

CheckNextSlot:
    ld a, [hl+]
    or a
    jr z, CheckSlotCount14

    cp $ff
    jr z, CheckSlotCount14

    inc c
    dec b
    jr nz, CheckNextSlot

CheckSlotCount14:
    ld a, c
    cp $14
    jp c, Jump_004_55f5

    call MapTypeDispatch
    jp ScriptReturnProcess

label4_6093:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld hl, $ca8e
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $ff
    ret z

    push af
    ld hl, $caca
    call GetMonsterDataPtr
    ld a, [hl]
    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10
    ld a, [$da33]
    add a
    ld hl, FamilyTextPtrTable
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    pop af
    push hl
    ld d, a
    ld hl, $0107
    rst $10
    ld a, d
    add a
    pop hl
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld hl, wScriptStateFlags
    set 1, [hl]
    ld a, c
    ld [wScriptQueuedTextId], a
    ld a, b
    ld [$d8da], a
    ret


; =============================================================================
; MONSTER FAMILY TEXT TABLE ($60F4 - $61DF)
; Used by opcode $2D (MonsterSlotDialogue) handler.
; =============================================================================

FamilyTextPtrTable:  ; $60F4 — 10 entries, indexed by family ID
    dw FamilyTextGroup_A  ; 0 = Slime
    dw FamilyTextGroup_B  ; 1 = Dragon
    dw FamilyTextGroup_C  ; 2 = Beast
    dw FamilyTextGroup_B  ; 3 = Bird
    dw FamilyTextGroup_A  ; 4 = Plant
    dw FamilyTextGroup_C  ; 5 = Bug
    dw FamilyTextGroup_C  ; 6 = Devil
    dw FamilyTextGroup_A  ; 7 = Zombie
    dw FamilyTextGroup_B  ; 8 = Material
    dw FamilyTextGroup_D  ; 9 = Boss

FamilyTextGroup_A:  ; $6108 — Slime/Plant/Zombie
    dw $0075
    dw $0079
    dw $007D
    dw $0081
    dw $0085
    dw $0089
    dw $008D
    dw $0091
    dw $0095
    dw $0099
    dw $009D
    dw $00A1
    dw $00A5
    dw $00A9
    dw $00AD
    dw $00B1
    dw $00B5
    dw $00B9
    dw $00BD
    dw $00C1
    dw $00C5
    dw $00C9
    dw $00CD
    dw $00D1
    dw $00D5
    dw $00D9
    dw $00DE

FamilyTextGroup_B:  ; $613E — Dragon/Bird/Material
    dw $0076
    dw $007A
    dw $007E
    dw $0082
    dw $0086
    dw $008A
    dw $008E
    dw $0092
    dw $0096
    dw $009A
    dw $009E
    dw $00A2
    dw $00A6
    dw $00AA
    dw $00AE
    dw $00B2
    dw $00B6
    dw $00BA
    dw $00BE
    dw $00C2
    dw $00C6
    dw $00CA
    dw $00CE
    dw $00D2
    dw $00D6
    dw $00DA
    dw $00DF

FamilyTextGroup_C:  ; $6174 — Beast/Bug/Devil
    dw $0077
    dw $007B
    dw $007F
    dw $0083
    dw $0087
    dw $008B
    dw $008F
    dw $0093
    dw $0097
    dw $009B
    dw $009F
    dw $00A3
    dw $00A7
    dw $00AB
    dw $00AF
    dw $00B3
    dw $00B7
    dw $00BB
    dw $00BF
    dw $00C3
    dw $00C7
    dw $00CB
    dw $00CF
    dw $00D3
    dw $00D7
    dw $00DB
    dw $00E0

FamilyTextGroup_D:  ; $61AA — Boss
    dw $0078
    dw $007C
    dw $0080
    dw $0084
    dw $0088
    dw $008C
    dw $0090
    dw $0094
    dw $0098
    dw $009C
    dw $00A0
    dw $00A4
    dw $00A8
    dw $00AC
    dw $00B0
    dw $00B4
    dw $00B8
    dw $00BC
    dw $00C0
    dw $00C4
    dw $00C8
    dw $00CC
    dw $00D0
    dw $00D4
    dw $00D8
    dw $00DC
    dw $00E1

label4_61e0:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    add a
    add a
    add c
    ld c, a
    ld a, [$d9df]
    dec a
    add c
    ld hl, $620d
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$d9e0], a
    jp Jump_004_55f5


    db $01, $01, $00, $02, $02, $02, $01, $02, $01, $02, $01, $01, $02, $00, $01, $01
    db $01, $00, $02, $01, $00, $02, $00, $00, $00, $01, $02, $00, $00, $01, $00, $01
    db $01, $01, $01, $02, $01, $02, $01, $00, $01, $01, $00, $01, $00

label4_623a:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld l, c
    ld h, b
    inc [hl]
    jp Jump_004_55f5

label4_6253:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    ld a, c
    ld a, [$ca8d]
    cp c
    jp z, Jump_004_55f5

    jp c, Jump_004_55f5

    ld a, c
    ld hl, $cb19
    push bc
    call GetCurrentMonsterPtr
    pop bc
    ld a, [hl+]
    sub $64
    ld a, [hl]
    sbc $00
    jp c, Jump_004_55f5

    ld a, c
    ld [$d8e1], a
    ld hl, $cac2
    call GetCurrentMonsterPtr
    ld e, l
    ld d, h
    ld hl, $c180
    call Copy4Bytes
    call MapTypeDispatch
    jp ScriptReturnProcess

label4_62ab:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    ld b, $00
    ld c, $00

PushAndReadParty:
    push bc
    ld hl, $ca94
    ld a, b
    call TestBitInArray
    pop bc
    jr z, IncrementAndCheck

    inc c

IncrementAndCheck:
    inc b
    ld a, b
    cp $f0
    jr nz, PushAndReadParty

    ld a, c
    cp $64
    jp c, Jump_004_55f5

    call MapTypeDispatch
    jp ScriptReturnProcess

label4_62dd:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    ld a, c
    ld a, [$ca8d]
    cp c
    jp z, Jump_004_55f5

    jp c, Jump_004_55f5

    ld a, c
    ld hl, $caca
    push bc
    call GetCurrentMonsterPtr
    pop bc
    ld a, [hl]
    cp $af
    jp nz, Jump_004_55f5

    ld a, c
    ld [$d8e1], a
    ld hl, $cac2
    call GetCurrentMonsterPtr
    ld e, l
    ld d, h
    ld hl, $c180
    call Copy4Bytes
    call MapTypeDispatch
    jp ScriptReturnProcess

label4_6332:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld l, c
    ld h, b
    ld e, $00
    call CompareGold
    jp Jump_004_55f5

label4_634f:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    ld a, c
    ld a, [$ca8d]
    cp c
    jp z, Jump_004_55f5

    jp c, Jump_004_55f5

    ld a, c
    ld hl, $caea
    push bc
    call GetCurrentMonsterPtr
    pop bc
    ld b, $08

CheckMonsterFamily:
    ld a, [hl+]
    cp $0f
    jr z, StoreMonsterResult

    cp $10
    jr z, StoreMonsterResult

    cp $45
    jr z, StoreMonsterResult

    cp $11
    jr z, StoreMonsterResult

    cp $5a
    jr z, StoreMonsterResult

    dec b
    jr nz, CheckMonsterFamily

    jp Jump_004_55f5


StoreMonsterResult:
    ld a, c
    ld [$d8e1], a
    ld hl, $cac2
    call GetCurrentMonsterPtr
    ld e, l
    ld d, h
    ld hl, $c180
    call Copy4Bytes
    call MapTypeDispatch
    jp ScriptReturnProcess

label4_63bb:
    ld hl, $0109
    rst $10
    ld hl, $0103
    rst $10
    jp Jump_004_55f5

label4_63c6:
    ld a, [$cab4]
    add a
    ld hl, $63ef
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld [wTempEnemyId1], a
    ld a, [hl]
    ld [$da04], a
    ld a, $00
    ld [$da02], a
    ld hl, wGameState
    set 6, [hl]
    xor a
    ld [$c905], a
    ld a, $01
    ld [$da09], a
    ret


    db $3d, $01, $3e, $01, $3f, $01, $40, $01, $41, $01, $42, $01, $43, $01, $44, $01
    db $44, $01

label4_6401:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld hl, $d9cf
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld c, [hl]
    ld hl, wInventory
    ld b, $14

CheckMonsterSlotEmpty:
    ld a, [hl]
    or a
    jr z, WriteMonsterToSlot

    cp $ff
    jr z, WriteMonsterToSlot

    inc hl
    dec b
    jr nz, CheckMonsterSlotEmpty

    jr SetupMonsterHL

WriteMonsterToSlot:
    ld [hl], c

SetupMonsterHL:
    ld l, c
    ld h, $08
    ld de, $c180
    call SetupVRAMParams
    jp Jump_004_55f5

label4_643f:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    ld a, c
    ld a, [$ca8d]
    cp c
    jp z, Jump_004_55f5

    jp c, Jump_004_55f5

    ld a, c
    ld hl, $caea
    push bc
    call GetCurrentMonsterPtr
    pop bc
    ld b, $08

CheckSkillSlot:
    ld a, [hl+]
    cp $84
    jr z, StoreSkillResult

    cp $85
    jr z, StoreSkillResult

    cp $86
    jr z, StoreSkillResult

    cp $87
    jr z, StoreSkillResult

    dec b
    jr nz, CheckSkillSlot

    jp Jump_004_55f5


StoreSkillResult:
    ld a, c
    ld [$d8e1], a
    ld hl, $cac2
    call GetCurrentMonsterPtr
    ld e, l
    ld d, h
    ld hl, $c180
    call Copy4Bytes
    call MapTypeDispatch
    jp ScriptReturnProcess

label4_64a7:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld l, c
    ld h, b
    call TextBankDispatch
    jp Jump_004_55f5

label4_64c2:
    ld a, [$ca40]
    ld [$cac0], a
    ld hl, $1604
    rst $10
    ld hl, wGameState
    res 4, [hl]
    res 0, [hl]
    xor a
    ld [$c905], a
    ld a, [$cac0]
    ld hl, $caca
    call GetMonsterDataPtr
    ld l, [hl]
    ld h, $05
    ld de, $c190
    call SetupVRAMParams
    ld a, [$cac0]
    ld hl, $cb23
    call GetMonsterDataPtr
    ld a, [hl]
    ld de, $c190
    call MaskScr_6583
    ld a, [$cac0]
    ld hl, $cacc
    call GetMonsterDataPtr
    ld a, [hl]
    ld de, $c190
    call SaveScr_6598
    ld a, [$cac0]
    ld hl, $caca
    call GetMonsterDataPtr
    ld a, [hl]
    add $10
    ld [$c8f4], a
    ld [$d7ca], a
    ld a, $01
    ld [$d7cb], a
    ld a, [$cac0]
    ld hl, $cac2
    call GetMonsterDataPtr
    ld a, l
    ld [$c8f2], a
    ld a, h
    ld [$c8f3], a
    ld a, [$cac0]
    ld hl, $cacc
    call GetMonsterDataPtr
    ld a, [hl]
    ld [$c8f6], a
    ld a, [$cac0]
    ld hl, $caca
    call GetMonsterDataPtr
    ld a, [hl]
    ld [$c8f5], a
    ld a, $08
    ld [wWarpGateId], a
    ld a, $00
    ld [wWarpFlag], a
    ld hl, $0048
    ld a, l
    ld [wWarpSpawnXLo], a
    ld a, h
    ld [wWarpSpawnXHi], a
    ld hl, $0048
    ld a, l
    ld [wWarpSpawnYLo], a
    ld a, h
    ld [wWarpSpawnYHi], a
    ld a, $01
    ld [wIsPlayerChangingMaps], a
    ld a, $02
    ld [$d951], a
    xor a
    ld [wScriptStateFlags], a
    ld a, $03
    call SetGBCPalette
    ld hl, $c88f
    inc [hl]
    ret


MaskScr_6583:
    or a
    ret z

    push af

MaskReadDE:
    ld a, [de]
    inc de
    cp $f0
    jr nz, MaskReadDE

    dec de
    ld a, $a2
    ld [de], a
    inc de
    pop af
    ld l, e
    ld h, d
    call ExtractDigits
    ret


SaveScr_6598:
    push af

SaveReadDE:
    ld a, [de]
    inc de
    cp $f0
    jr nz, SaveReadDE

    dec de
    pop af
    and $01
    add $a7
    ld [de], a
    inc de
    ld a, $f0
    ld [de], a
    ret

label4_65ab:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld [wWarpGateId], a
    ld a, b
    ld [wWarpFlag], a
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld [wWarpSpawnXLo], a
    ld a, b
    ld [wWarpSpawnXHi], a
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld [wWarpSpawnYLo], a
    ld a, b
    ld [wWarpSpawnYHi], a
    ld a, $01
    ld [wIsPlayerChangingMaps], a
    ld hl, wGameState
    set 5, [hl]
    xor a
    ld [$c905], a
    xor a
    ld [wScriptStateFlags], a
    ld hl, wGameState
    res 0, [hl]
    xor a
    ld [$c825], a
    ret


label4_6618:
    ld hl, $d8d8
    set 0, [hl]
    jp Jump_004_55f5


label4_6620:
    ld hl, $d8d8
    set 1, [hl]
    jp Jump_004_55f5


label4_6628:
    ld a, $04
    call SetGBCPalette
    ld hl, $c88e
    inc [hl]
    ret


label4_6632:
    ld a, $00
    ld hl, $caca
    call GetCurrentMonsterPtr
    ld l, [hl]
    ld h, $05
    ld de, $c180
    call SetupVRAMParams
    jp Jump_004_55f5


label4_6646:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld d, c
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    ld hl, $cac1
    ld b, $14
    ld c, $00

PushAndCheckHL:
    push hl
    ld a, [hl]
    or a
    jr z, PopAndAdvanceL

    cp $01
    jr z, PopAndAdvanceL

    ld a, l
    add $09
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl]
    cp d
    jr nz, PopAndAdvanceL

    pop hl
    call MapTypeDispatch
    jp ScriptReturnProcess


PopAndAdvanceL:
    pop hl
    ld a, l
    add $95
    ld l, a
    ld a, h
    adc $00
    ld h, a
    inc c
    dec b
    jr nz, PushAndCheckHL

    jp Jump_004_55f5


; ---------------------------------------------------------------------------
; Script Command $41: SetBGM
; Saves current BGM to $C8B6 (for later restore), reads new BGM offset
; from script, calls SetBGM to change the music.
; ---------------------------------------------------------------------------
label4_669d:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, [wCurrPlayingBGM]
    ld [$c8b6], a
    ld a, c
    call SetBGM
    jp Jump_004_55f5


label4_66bd:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld [$c8f7], a
    ld a, b
    ld [$c8f8], a
    ld a, [wMapID]
    ld c, a
    ld a, [wInGateworld]
    ld b, a
    ld a, c
    ld [$c8fb], a
    ld a, b
    ld [$c8fc], a
    ldh a, [$92]
    ld c, a
    ldh a, [$93]
    ld b, a
    ld a, c
    ld [$c8fd], a
    ld a, b
    ld [$c8fe], a
    ldh a, [$95]
    ld c, a
    ldh a, [$96]
    ld b, a
    ld a, c
    ld [$c8ff], a
    ld a, b
    ld [$c900], a
    ldh a, [$8e]
    ld [$c901], a
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld [$c902], a
    jp Jump_004_55f5


label4_6723:
    ld a, [$c8fb]
    ld c, a
    ld a, [$c8fc]
    ld b, a
    ld a, c
    ld [wWarpGateId], a
    ld a, b
    ld [wWarpFlag], a
    ld a, [$c8fd]
    ld c, a
    ld a, [$c8fe]
    ld b, a
    ld a, c
    ld [wWarpSpawnXLo], a
    ld a, b
    ld [wWarpSpawnXHi], a
    ld a, [$c8ff]
    ld c, a
    ld a, [$c900]
    ld b, a
    ld a, c
    ld [wWarpSpawnYLo], a
    ld a, b
    ld [wWarpSpawnYHi], a
    ld a, $01
    ld [wIsPlayerChangingMaps], a
    ld a, $03
    call SetGBCPalette
    ld hl, $c88f
    inc [hl]
    xor a
    ld [wScriptStateFlags], a
    ld hl, wGameState
    res 0, [hl]
    xor a
    ld [$c825], a
    ret


label4_676f:
    ld a, [$c901]
    ldh [$8e], a
    call LoadScr_454b
    ld a, [$c902]
    dec a
    swap a
    add a
    ld hl, $d7d8
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ldh a, [$8e]
    add $02
    and $03
    ld [hl], a
    ld a, [$c8f0]
    ld c, a
    ld a, [$c8f1]
    ld b, a
    ld a, c
    add $09
    ld c, a
    ld a, b
    adc $00
    ld b, a
    ld hl, wScriptStateFlags
    set 1, [hl]
    ld a, c
    ld [wScriptQueuedTextId], a
    ld a, b
    ld [$d8da], a
    ld hl, wGameState
    set 0, [hl]
    ret


label4_67b1:
    ld hl, $cab9
    ld a, [hl+]
    ld [$ca8d], a
    ld a, [hl+]
    ld [$ca8e], a
    ld a, [hl+]
    ld [$ca8f], a
    ld a, [hl+]
    ld [$ca90], a
    ld a, [hl+]
    ld [$ca91], a
    ld a, [hl+]
    ld [$ca92], a
    ld a, [hl+]
    ld [$ca93], a
    ld a, [$ca8e]
    call CmpScr_67f1
    ld a, [$ca8f]
    call CmpScr_67f1
    ld a, [$ca90]
    call CmpScr_67f1
    ld hl, $0105
    rst $10
    ld hl, $0109
    rst $10
    ld hl, $0103
    rst $10
    jp Jump_004_55f5


CmpScr_67f1:
    cp $ff
    ret z

    ld hl, $cac1
    call GetMonsterDataPtr
    ld [hl], $02
    ret


label4_67fd:
    ld a, [$ddb4]
    ld hl, $ddce
    and [hl]
    ld hl, $dde8
    and [hl]
    ld hl, $de02
    and [hl]
    cp $ff
    jp z, Jump_004_55f5

    ld a, [wScriptCounter]
    sub $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    sbc $00
    ld [$d8d6], a
    ret


label4_6822:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld c, $02

CheckZeroJPEnd:
    or a
    jp z, ScriptEndCheck

    dec a
    swap a
    add a
    ld hl, $d7d8
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], c
    jp Jump_004_55f5


label4_684d:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld c, $00
    jp CheckZeroJPEnd


label4_6866:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld c, $01
    jp CheckZeroJPEnd


label4_687f:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld c, $03
    jp CheckZeroJPEnd


label4_6898:
    ld a, [$c8b6]
    call SetBGM
    jp Jump_004_55f5


label4_68a1:
    ld a, [wJoypad_current_frame]
    and $f0
    jp nz, Jump_004_55f5

    ld a, [wScriptCounter]
    sub $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    sbc $00
    ld [$d8d6], a
    ret


label4_68ba:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld [$d8db], a
    ld hl, $d8d8
    set 2, [hl]
    ret


label4_68d7:
    ld a, [wMapID]
    ld c, a
    ld a, [wInGateworld]
    ld b, a
    ld a, c
    ld [$c8fb], a
    ld a, b
    ld [$c8fc], a
    ldh a, [$92]
    ld c, a
    ldh a, [$93]
    ld b, a
    ld a, c
    ld [$c8fd], a
    ld a, b
    ld [$c8fe], a
    ldh a, [$95]
    ld c, a
    ldh a, [$96]
    ld b, a
    ld a, c
    ld [$c8ff], a
    ld a, b
    ld [$c900], a
    ldh a, [$8e]
    ld [$c901], a
    jp Jump_004_55f5


label4_690b:
    ld a, [$c8fb]
    ld c, a
    ld a, [$c8fc]
    ld b, a
    ld a, c
    ld [wWarpGateId], a
    ld a, b
    ld [wWarpFlag], a
    ld a, [$c8fd]
    ld c, a
    ld a, [$c8fe]
    ld b, a
    ld a, c
    ld [wWarpSpawnXLo], a
    ld a, b
    ld [wWarpSpawnXHi], a
    ld a, [$c8ff]
    ld c, a
    ld a, [$c900]
    ld b, a
    ld a, c
    ld [wWarpSpawnYLo], a
    ld a, b
    ld [wWarpSpawnYHi], a
    ld a, $01
    ld [wIsPlayerChangingMaps], a
    ld a, $03
    call SetGBCPalette
    ld hl, $c88f
    inc [hl]
    xor a
    ld [wScriptStateFlags], a
    ld hl, wGameState
    res 0, [hl]
    xor a
    ld [$c825], a
    ret


label4_6957:
    ld a, [$c901]
    ldh [$8e], a
    call LoadScr_454b
    ld hl, $d7f8
    ldh a, [$8e]
    add $02
    and $03
    ld [hl], a
    jp Jump_004_55f5


label4_696c:
    ld b, $00
    ld c, $00

PushAndScanParty:
    push bc
    ld hl, $ca94
    ld a, b
    call TestBitInArray
    pop bc
    jr z, ScanPartyLoop

    inc c

ScanPartyLoop:
    inc b
    ld a, b
    cp $f0
    jr nz, PushAndScanParty

    push bc
    ld a, c
    ld hl, $c180
    call ExtractDigits
    pop bc
    ld hl, $699d
    ld a, c
    ld e, $ff

CompareAndAdvance:
    cp [hl]
    inc hl
    inc e
    jr nc, CompareAndAdvance

    ld a, e
    ld [$d8e1], a
    jp Jump_004_55f5


    rlca
    db $10
    ld a, [de]
    ld h, $32
    ld b, a
    ld h, h
    add e
    and c
    ret z

    rst $10
    rst $38

label4_69a9:
    ld bc, $0000
    ld a, [$ca8e]
    call $6a4e
    ld a, [$ca8f]
    call $6a4e
    ld a, [$ca90]
    call $6a4e
    ld l, c
    ld h, b
    inc hl
    ld a, $14
    call Div16x8To16
    ld a, l
    cp $07
    jr c, LookupOpcodeTable

    ld a, $07

LookupOpcodeTable:
    ld hl, $6a3c
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    push hl
    call GenerateRNG
    pop hl
    push hl
    ld a, [wRNG1]
    and $0f
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, l
    ld [wTempEnemyId1], a
    ld a, h
    ld [$da04], a
    pop hl
    push hl
    call GenerateRNG
    pop hl
    push hl
    ld a, [wRNG1]
    and $0f
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, l
    ld [$da05], a
    ld a, h
    ld [$da06], a
    pop hl
    push hl
    call GenerateRNG
    pop hl
    push hl
    ld a, [wRNG1]
    and $0f
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, l
    ld [$da07], a
    ld a, h
    ld [$da08], a
    pop hl
    ld a, $02
    ld [$da02], a
    ld hl, wGameState
    set 6, [hl]
    xor a
    ld [$c905], a
    ld a, $02
    ld [$da09], a
    ret


    ld h, b
    ld bc, $0170
    add b
    ld bc, $0190
    and b
    ld bc, $01b0
    ret nz

    ld bc, $01d0
    ret nc

    ld bc, $fffe
    ret z

    push bc
    ld hl, $cb0c
    call GetMonsterDataPtr
    pop bc
    ld a, [hl]
    add c
    ld c, a
    ld a, $00
    adc b
    ld b, a
    ret


label4_6a61:
    ldh a, [$95]
    and $f0
    ld l, a
    ldh a, [$96]
    ld h, a
    ld a, [$d7ec]
    and $f0
    ld e, a
    ld a, [$d7ed]
    ld d, a
    push hl
    ld a, l
    sub e
    ld l, a
    ld a, h
    sbc d
    ld h, a
    ld a, h
    or l
    pop hl
    jr z, MaskA_F0

    ld a, l
    sub e
    ld l, a
    ld a, h
    sbc d
    ld h, a
    ld a, $00
    jr c, StoreAndClearMove

    ld a, $02
    jr StoreAndClearMove

MaskA_F0:
    ldh a, [$92]
    and $f0
    ld l, a
    ldh a, [$93]
    ld h, a
    ld a, [$d7ea]
    and $f0
    ld e, a
    ld a, [$d7eb]
    ld d, a
    push hl
    ld a, l
    sub e
    ld l, a
    ld a, h
    sbc d
    ld h, a
    ld a, h
    or l
    pop hl
    jr z, JumpToScriptInit

    ld a, l
    sub e
    ld l, a
    ld a, h
    sbc d
    ld h, a
    ld a, $03
    jr c, StoreAndClearMove

    ld a, $01
    jr StoreAndClearMove

JumpToScriptInit:
    jp Jump_004_55f5


StoreAndClearMove:
    ldh [$8e], a
    call LoadScr_454b
    ld hl, $d7d8
    ldh a, [$8e]
    add $02
    and $03
    ld [hl], a
    jp Jump_004_55f5


label4_6ace:
    ld a, [wRNG1]
    ld b, a
    ld a, $25
    call Div8x8
    inc a
    ld c, a
    ld hl, wInventory
    ld b, $14

CheckSlotHL:
    ld a, [hl]
    or a
    jr z, WriteAndSetupHL

    cp $ff
    jr z, WriteAndSetupHL

    inc hl
    dec b
    jr nz, CheckSlotHL

    jp Jump_004_55f5


WriteAndSetupHL:
    ld [hl], c
    ld l, c
    ld h, $08
    ld de, $c180
    call SetupVRAMParams
    jp Jump_004_55f5


label4_6afa:
    ld hl, wInventory
    ld b, $14
    ld c, $00

CheckSlotHLAlt:
    ld a, [hl]
    or a
    jr z, StoreScriptResult

    cp $ff
    jr z, StoreScriptResult

    inc hl
    inc c
    dec b
    jr nz, CheckSlotHLAlt

StoreScriptResult:
    ld a, c
    ld [$d8e1], a
    or a
    jp z, Jump_004_55f5

    ld a, [wRNG1]
    ld b, a
    ld a, c
    call Div8x8
    ld hl, wInventory
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld c, [hl]
    ld [hl], $ff
    ld l, c
    ld h, $08
    ld de, $c180
    call SetupVRAMParams
    ld hl, $0305
    rst $10
    jp Jump_004_55f5


label4_6b3a:
    ld a, [wCurrGoldLo]
    ld l, a
    ld a, [wCurrGoldMid]
    ld h, a
    ld a, [wCurrGoldHi]
    ld e, a
    ld a, $0a
    call Div24x8To16
    ld a, h
    or l
    or e
    ld [$d8e1], a
    or a
    jp z, Jump_004_55f5

    ld a, l
    ldh [$d5], a
    ld a, h
    ldh [$d6], a
    ld a, e
    ldh [$d7], a
    ld hl, $c180
    call FormatLargeNumber
    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
    ld h, a
    ldh a, [$d7]
    ld e, a
    call AddGold
    jp Jump_004_55f5


label4_6b73:
    ld a, [wRNG1]
    ld b, a
    ld a, $05
    call Div8x8
    add $13
    ld c, a
    ld hl, wInventory
    ld b, $14

CheckSlotHLB:
    ld a, [hl]
    or a
    jr z, WriteAndSetupHLB

    cp $ff
    jr z, WriteAndSetupHLB

    inc hl
    dec b
    jr nz, CheckSlotHLB

    jp Jump_004_55f5


WriteAndSetupHLB:
    ld [hl], c
    ld l, c
    ld h, $08
    ld de, $c180
    call SetupVRAMParams
    jp Jump_004_55f5


label4_6ba0:
    ld a, [wLastFloor]
    dec a
    dec a
    ld b, a
    ld a, [wCurrentFloor]
    cp b
    jr z, SetMapChangeFlag

    add $13
    ld [wCurrentFloor], a
    cp b
    jr c, SetMapChangeFlag

    ld a, b
    dec a
    ld [wCurrentFloor], a

SetMapChangeFlag:
    ld a, $01
    ld [wIsPlayerChangingMaps], a
    ld a, $00
    ld [wWarpGateId], a
    ld a, $80
    ld [wWarpFlag], a
    ld hl, wGameState
    set 5, [hl]
    xor a
    ld [$c905], a
    xor a
    ld [wScriptStateFlags], a
    ld hl, wGameState
    res 0, [hl]
    xor a
    ld [$c825], a
    ret

label4_6bdf:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld hl, $ca8e
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$d8e1], a
    cp $ff
    jp z, Jump_004_55f5

    ld [$cac0], a
    ld hl, $cb13
    call GetMonsterDataPtr
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    ld hl, $cb17
    call CallScr_6d40
    jr c, ReadATKStat

    ld hl, $cb19
    call CallScr_6d40
    jr c, ReadATKStat

    ld hl, $cb1b
    call CallScr_6d40
    jr c, ReadATKStat

    ld hl, $cb1d
    call CallScr_6d35
    jr c, ReadATKStat

    ld hl, $cb1f
    call CallScr_6d29
    jr c, ReadATKStat

    ld hl, $0014
    ld a, [$cac0]
    call AddMonsterHP
    ld a, $00
    jp CalcStatOffsetAlias


ReadATKStat:
    ld a, [$cac0]
    ld hl, $cb17
    call GetMonsterDataPtr
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    ld hl, $cb19
    call CallScr_6d40
    jr c, ReadDEFStat

    ld hl, $cb1b
    call CallScr_6d40
    jr c, ReadDEFStat

    ld hl, $cb1d
    call CallScr_6d35
    jr c, ReadDEFStat

    ld hl, $cb1f
    call CallScr_6d29
    jr c, ReadDEFStat

    ld hl, $0014
    ld a, [$cac0]
    call AddMonsterMP
    ld a, $01
    jp CalcStatOffsetAlias


ReadDEFStat:
    ld a, [$cac0]
    ld hl, $cb19
    call GetMonsterDataPtr
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    ld hl, $cb1b
    call CallScr_6d40
    jr c, ReadAGLStat

    ld hl, $cb1d
    call CallScr_6d35
    jr c, ReadAGLStat

    ld hl, $cb1f
    call CallScr_6d29
    jr c, ReadAGLStat

    ld hl, $0014
    ld a, [$cac0]
    call AddMonsterATK
    ld a, $02
    jr CalcStatOffset

ReadAGLStat:
    ld a, [$cac0]
    ld hl, $cb1b
    call GetMonsterDataPtr
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    ld hl, $cb1d
    call CallScr_6d35
    jr c, ReadINTStat

    ld hl, $cb1f
    call CallScr_6d29
    jr c, ReadINTStat

    ld hl, $0014
    ld a, [$cac0]
    call AddMonsterDEF
    ld a, $03
    jr CalcStatOffset

ReadINTStat:
    ld a, [$cac0]
    ld hl, $cb1d
    call GetMonsterDataPtr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    add hl, hl
    ld e, l
    ld d, h
    ld hl, $cb1f
    call CallScr_6d29
    jr c, ReadLevelStat

    ld hl, $0014
    ld a, [$cac0]
    call AddMonsterAGL
    ld a, $04
    jr CalcStatOffset

ReadLevelStat:
    ld hl, $0014
    ld a, [$cac0]
    call AddMonsterINT
    ld a, $05

CalcStatOffsetAlias:
CalcStatOffset:
    add $35
    ld l, a
    ld h, $02
    ld de, $c190
    call SetupVRAMParams
    ld a, [$cac0]
    ld hl, $cac2
    call GetMonsterDataPtr
    ld e, l
    ld d, h
    ld hl, $c180
    call Copy4Bytes
    jp Jump_004_55f5


CallScr_6d29:
    call SaveScr_6d4a
    add hl, hl
    add hl, hl
    ld a, l
    sub e
    ld l, a
    ld a, h
    sbc d
    ld h, a
    ret


CallScr_6d35:
    call SaveScr_6d4a
    add hl, hl
    ld a, l
    sub e
    ld l, a
    ld a, h
    sbc d
    ld h, a
    ret


CallScr_6d40:
    call SaveScr_6d4a
    ld a, l
    sub e
    ld l, a
    ld a, h
    sbc d
    ld h, a
    ret


SaveScr_6d4a:
    push de
    ld a, [$cac0]
    call GetMonsterDataPtr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    pop de
    ret


label4_6d56:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, c
    ld [wTempEnemyId1], a
    ld a, b
    ld [$da04], a
    xor a
    ld [$da02], a
    ld hl, wGameState
    set 6, [hl]
    xor a
    ld [$c905], a
    ld a, $03
    ld [$da09], a
    ret


label4_6d84:
    ld hl, wGameState
    set 6, [hl]
    xor a
    ld [$c905], a
    ld a, $03
    ld [$da09], a
    ret


ColiseumInitPrize:
    ld a, [$d9cf]
    bit 7, a
    jr nz, ColiseumCallAndRead

    ld hl, $d9cf
    inc [hl]

ColiseumCallAndRead:
    call FuncScr_6eb3
    ld a, [wTempEnemyId1]
    ld l, a
    ld a, [$da04]
    ld h, a
    ld a, l
    ld [$d9d1], a
    ld a, h
    ld [$d9d2], a
    ld a, [$da05]
    ld l, a
    ld a, [$da06]
    ld h, a
    ld a, l
    ld [$d9d3], a
    ld a, h
    ld [$d9d4], a
    ld a, [$da07]
    ld l, a
    ld a, [$da08]
    ld h, a
    ld a, l
    ld [$d9d5], a
    ld a, h
    ld [$d9d6], a
    call FuncScr_6eb3
    ld a, [wTempEnemyId1]
    ld l, a
    ld a, [$da04]
    ld h, a
    ld a, l
    ld [$d9d9], a
    ld a, h
    ld [$d9da], a
    ld a, [$da05]
    ld l, a
    ld a, [$da06]
    ld h, a
    ld a, l
    ld [$d9db], a
    ld a, h
    ld [$d9dc], a
    ld a, [$da07]
    ld l, a
    ld a, [$da08]
    ld h, a
    ld a, l
    ld [$d9dd], a
    ld a, h
    ld [$d9de], a
    call FuncScr_6eb3
    ld hl, $d7ca
    call SaveScr_6e41
    ld hl, $6f44
    ld a, [$d9cf]
    cp $09
    jr c, ColiseumRNGPrize

    ld hl, $6f54

ColiseumRNGPrize:
    push hl
    call GenerateRNG
    ld a, [wRNG1]
    and $0f
    pop hl
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$d9d0], a
    xor a
    ld [wColiseumBattle], a
    ld a, [$d9d0]
    ld l, a
    ld h, $08
    ld de, $c180
    call SetupVRAMParams
    jp Jump_004_55f5


SaveScr_6e41:
    push hl
    ld a, $ff
    ld [hl+], a
    xor a
    ld [hl+], a
    ld a, $ff
    ld [hl+], a
    xor a
    ld [hl+], a
    ld a, $ff
    ld [hl+], a
    xor a
    ld [hl], a
    pop hl
    push hl
    ld a, [wTempEnemyId1]
    ld l, a
    ld a, [$da04]
    ld h, a
    ld a, l
    ld [wTempEnemyStatsId], a
    ld a, h
    ld [$da13], a
    call SetScr_6ea9
    pop hl
    ld [hl+], a
    ld a, $01
    ld [hl+], a
    ld a, [$da02]
    or a
    ret z

    push hl
    ld a, [$da05]
    ld l, a
    ld a, [$da06]
    ld h, a
    ld a, l
    ld [wTempEnemyStatsId], a
    ld a, h
    ld [$da13], a
    call SetScr_6ea9
    pop hl
    ld [hl+], a
    ld a, $01
    ld [hl+], a
    ld a, [$da02]
    cp $01
    ret z

    push hl
    ld a, [$da07]
    ld l, a
    ld a, [$da08]
    ld h, a
    ld a, l
    ld [wTempEnemyStatsId], a
    ld a, h
    ld [$da13], a
    call SetScr_6ea9
    pop hl
    ld [hl+], a
    ld a, $01
    ld [hl+], a
    ret


SetScr_6ea9:
    ld hl, $1401
    rst $10
    ld a, [$da18]
    add $10
    ret


FuncScr_6eb3:
    ld b, $00
    ld a, [$ca8e]
    call CmpScr_6f05
    ld a, [$ca8f]
    call CmpScr_6f05
    ld a, [$ca90]
    call CmpScr_6f05
    ld a, b
    ld hl, $0209
    cp $04
    jr c, SetBattleMode2

    ld hl, $0d12
    cp $0a
    jr c, SetBattleMode2

    ld hl, $2112
    cp $10
    jr c, SetBattleMode2

    ld hl, AudioReadE5Bit7
    cp $16
    jr c, SetBattleMode2

    ld hl, $5112
    cp $1c
    jr c, SetBattleMode2

    ld hl, $6912
    cp $22
    jr c, SetBattleMode2

    ld hl, $8112
    cp $28
    jr c, SetBattleMode2

    ld hl, $9d12
    cp $2e
    jr c, SetBattleMode2

    ld hl, $b512
    jr SetBattleMode2

CmpScr_6f05:
    cp $ff
    ret z

    ld hl, $cb0c
    call GetMonsterDataPtr
    ld a, [hl]
    cp b
    ret c

    ld b, a
    ret


SetBattleMode2:
    ld a, $02
    ld [$da02], a
    call SaveScr_6f35
    ld [wTempEnemyId1], a
    call SaveScr_6f35
    ld [$da05], a
    call SaveScr_6f35
    ld [$da07], a
    xor a
    ld [$da04], a
    ld [$da06], a
    ld [$da08], a
    ret


SaveScr_6f35:
    push hl
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, l
    call Div8x8
    pop hl
    add h
    ret


    inc bc
    inc b
    ld b, $0c
    dec d
    rla
    jr @+$1b

    ld a, [de]
    dec de
    inc e
    dec h
    ld a, [de]
    dec de
    inc e
    dec h
    dec c
    ld c, $0f
    db $10
    ld de, $1e12
    rra
    jr nz, FindEmptySlotLoop

    ld [hl+], a
    inc hl
    jr nz, @+$23

    ld [hl+], a
    inc hl

label4_6f64:
    ld a, [$d9d0]
    ld l, a
    ld h, $08
    ld de, $c180
    call SetupVRAMParams
    ld hl, wInventory
    ld b, $14

FindEmptySlot:
    ld a, [hl]
    or a
    jr z, WriteToEmptySlot

    cp $ff
    jr z, WriteToEmptySlot

    inc hl
    dec b

FindEmptySlotLoop:
    jr nz, FindEmptySlot

    ret


WriteToEmptySlot:
    ld a, [$d9d0]
    ld [hl], a
    jp Jump_004_55f5


label4_6f89:
    ld a, $07
    ld [$d951], a
    xor a
    ld hl, $c0d8
    ld bc, $0028
    call FillNBytesWithRegA
    jp Jump_004_55f5


label4_6f9b:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call MapTypeDispatch
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    ld a, c
    ld a, [$ca8d]
    cp c
    jp z, Jump_004_55f5

    jp c, Jump_004_55f5

    ld a, c
    ld hl, $cb0d
    push bc
    call GetCurrentMonsterPtr
    ld a, [hl]
    push hl
    ld hl, $c190
    call ExtractDigits
    pop hl
    pop bc
    push hl
    ld a, c
    ld [$d8e1], a
    ld hl, $cac2
    call GetCurrentMonsterPtr
    ld e, l
    ld d, h
    ld hl, $c180
    call Copy4Bytes
    pop hl
    ld a, [hl-]
    dec a
    cp [hl]
    jp nc, Jump_004_55f5

    call MapTypeDispatch
    jp ScriptReturnProcess


label4_6ffb:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    ld a, [$ca40]
    ld hl, $cb23
    call GetMonsterDataPtr
    ld a, [hl]
    inc a
    ld c, $0a
    call Mul8x8To16
    ld a, [wCurrGoldLo]
    sub l
    ld a, [wCurrGoldMid]
    sbc h
    ld a, [wCurrGoldHi]
    sbc $00
    jr nc, AddGoldReward

    call MapTypeDispatch
    jp ScriptReturnProcess


AddGoldReward:
    ld e, $00
    call AddGold
    jp Jump_004_55f5


label4_7038:
    ld a, [wScriptMapType]
    cp $06
    jr nc, CheckGoldMapType20

    ld hl, $0c02
    rst $10
    ret


CheckGoldMapType20:
    cp $20
    jr nc, CheckGoldMapType40

    ld hl, $0d02
    rst $10
    ret


CheckGoldMapType40:
    cp $40
    jr nc, CallBank0F_Gold

    ld hl, $0e02
    rst $10
    ret


CallBank0F_Gold:
    ld hl, $0f02
    rst $10
    ret


label4_705b:
    ld hl, $8da0
    ld b, $10
    ld a, $ff

WriteTileLoop:
    call Write_gfx_tile_and_inc_HL
    dec b
    jr nz, WriteTileLoop

    ld hl, $9800
    ld b, $00
    ld a, $da

WriteTilePair:
    call Write_gfx_tile_and_inc_HL
    call Write_gfx_tile_and_inc_HL
    call Write_gfx_tile_and_inc_HL
    call Write_gfx_tile_and_inc_HL
    dec b
    jr nz, WriteTilePair

    ret


label4_707f:
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

DrawRowSetup:
    ld b, $14
    push hl

DrawRowLoop:
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
    jr nz, DrawRowLoop

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
    jr nz, DrawRowSetup

    ld hl, $0103
    rst $10
    ret


label4_70d5:
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    ld a, [$ca8d]
    or a
    jp z, ScriptExecMapAlias

    ld a, $00
    ld hl, $cb0b
    call ReadMonsterByte
    or a
    jp nz, JumpToScriptInitAlias

    ld a, $00
    ld hl, $cb13
    call ReadMonsterWord
    push bc
    ld a, $00
    ld hl, $cb11
    call ReadMonsterWord
    pop hl
    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    ld a, h
    or l
    jp nz, JumpToScriptInitAlias

    ld a, $00
    ld hl, $cb17
    call ReadMonsterWord
    push bc
    ld a, $00
    ld hl, $cb15
    call ReadMonsterWord
    pop hl
    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    ld a, h
    or l
    jp nz, JumpToScriptInitAlias

    ld a, [$ca8d]
    cp $01
    jp z, ScriptExecMapAlias

    ld a, $01
    ld hl, $cb0b
    call ReadMonsterByte
    or a
    jp nz, JumpToScriptInitAlias

    ld a, $01
    ld hl, $cb13
    call ReadMonsterWord
    push bc
    ld a, $01
    ld hl, $cb11
    call ReadMonsterWord
    pop hl
    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    ld a, h
    or l
    jr nz, JumpToScriptInitEntry

    ld a, $01
    ld hl, $cb17
    call ReadMonsterWord
    push bc
    ld a, $01
    ld hl, $cb15
    call ReadMonsterWord
    pop hl
    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    ld a, h
    or l
    jr nz, JumpToScriptInitEntry

    ld a, [$ca8d]
    cp $02
    jr z, ScriptExecMapDispatch

    ld a, $02
    ld hl, $cb0b
    call ReadMonsterByte
    or a
    jp nz, JumpToScriptInitAlias

    ld a, $02
    ld hl, $cb13
    call ReadMonsterWord
    push bc
    ld a, $02
    ld hl, $cb11
    call ReadMonsterWord
    pop hl
    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    ld a, h
    or l
    jr nz, JumpToScriptInitEntry

    ld a, $02
    ld hl, $cb17
    call ReadMonsterWord
    push bc
    ld a, $02
    ld hl, $cb15
    call ReadMonsterWord
    pop hl
    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    ld a, h
    or l
    jr nz, JumpToScriptInitEntry

ScriptExecMapAlias:
ScriptExecMapDispatch:
    call MapTypeDispatch
    jp ScriptReturnProcess


JumpToScriptInitAlias:
JumpToScriptInitEntry:
    jp Jump_004_55f5


label4_71d2:
    ld a, [$dd80]
    ld hl, $dd9a
    and [hl]
    cp $ff
    jp z, Jump_004_55f5

    ld a, [wScriptCounter]
    sub $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    sbc $00
    ld [$d8d6], a
    ret


; ===========================================================================
; ScriptDataRead — Fetch next script command from per-map-type bank
; ===========================================================================
; Reads the next BC pair from the script data bank. The bank is selected
; based on $D8D3 (copy of current map type):
;   $D8D3 < $06  → bank $0C entry 0 (Castle, GreatTree, Bazaar, etc.)
;   $D8D3 < $20  → bank $0D entry 0 (gate rooms, special rooms)
;   $D8D3 < $40  → bank $0E entry 0 (gate entrance rooms, boss rooms)
;   $D8D3 >= $40 → bank $0F entry 0 (labyrinth, arena, post-game)
;
; Each script bank's entry 0 uses $D8D5/$D8D6 (script counter) to index
; into its script data and returns the next command in BC.
; ---------------------------------------------------------------------------
MapTypeDispatch:
    ld a, [wScriptMapType]            ; Map type copy
    cp $06
    jr nc, DispatchCheckMap20

    ld hl, $0c00             ; Bank $0C entry 0
    rst $10
    ret


DispatchCheckMap20:
    cp $20
    jr nc, DispatchCheckMap40

    ld hl, $0d00             ; Bank $0D entry 0
    rst $10

RetFromDispatch:
    ret


DispatchCheckMap40:
    cp $40
    jr nc, DispatchBank0F

    ld hl, $0e00             ; Bank $0E entry 0
    rst $10
    ret


DispatchBank0F:
    ld hl, $0f00             ; Bank $0F entry 0
    rst $10
    ret


; ---------------------------------------------------------------------------
; ScriptBranch — Relative branch within script data
; ---------------------------------------------------------------------------
; Computes a signed offset from BC relative to HL (some reference point),
; divides by 2 (preserving sign via bit 7), adds to script counter
; ($D8D5/$D8D6), then loops back to ScriptExecNext.
; Used by conditional branch commands to skip or rewind script instructions.
; ---------------------------------------------------------------------------
ScriptReturnProcess:
    ld a, c
    sub l
    ld c, a
    ld a, b
    sbc h
    ld b, a                  ; BC = BC - HL (signed offset)
    ld a, b
    push af
    srl b
    rr c                     ; BC >>= 1 (divide by 2)
    pop af
    and $80
    or b
    ld b, a                  ; Restore sign bit
    ld a, [wScriptCounter]
    ld l, a
    ld a, [$d8d6]
    ld h, a                  ; HL = current script counter
    add hl, bc               ; HL += signed offset
    ld a, l
    ld [wScriptCounter], a
    ld a, h
    ld [$d8d6], a            ; Update script counter
    jp ScriptExecLoopAlias          ; → ScriptExecNext (continue execution)


    ld h, c
    ld [hl], d
    ld [hl], d
    ld [hl], d
    add e
    ld [hl], d
    sub h
    ld [hl], d
    and l
    ld [hl], d
    or [hl]
    ld [hl], d
    rst $00
    ld [hl], d
    rst $00
    ld [hl], d
    rst $00
    ld [hl], d
    rst $00
    ld [hl], d
    rst $00
    ld [hl], d
    rst $00
    ld [hl], d
    rst $00
    ld [hl], d
    rst $00
    ld [hl], d
    rst $00
    ld [hl], d
    rst $00
    ld [hl], d
    rst $00
    ld [hl], d
    or h
    ld [hl], e
    sbc c
    ld [hl], h
    add d
    ld [hl], l
    ld l, e
    db $76
    ldh a, [$f8]
    nop
    nop
    ldh a, [rP1]
    nop
    jr nz, @-$06

    ld hl, sp+$01
    nop
    ld hl, sp+$00
    ld [bc], a
    nop
    add b
    ldh a, [$f8]
    inc bc
    nop
    ld hl, sp-$08
    inc b
    nop
    ld hl, sp+$00
    dec b
    nop
    ldh a, [rP1]
    inc bc
    jr nz, RetFromDispatch

    ldh a, [$f8]
    ld b, $00
    ldh a, [rP1]
    rlca
    nop
    ld hl, sp-$08
    ld [$f800], sp
    nop
    add hl, bc
    nop
    add b
    ldh a, [rP1]
    ld a, [bc]
    nop
    ld hl, sp-$08
    dec bc
    nop
    ld hl, sp+$00
    inc c
    nop
    ldh a, [$f8]
    inc de
    nop
    add b
    ldh a, [$f8]
    dec c
    nop
    ldh a, [rP1]
    dec c
    jr nz, @-$06

    ld hl, sp+$0e
    nop
    ld hl, sp+$00
    rrca
    nop
    add b
    ldh a, [$f8]
    stop
    ldh a, [rP1]
    db $10
    jr nz, @-$06

    ld hl, sp+$11
    nop
    ld hl, sp+$00
    ld [de], a
    nop
    add b
    ret z

    ldh [rP1], a
    db $10
    ret z

    add sp, $01
    db $10
    ret z

    ldh a, [rSC]
    db $10
    ret z

    ld hl, sp+$03
    db $10
    ret z

    nop
    inc b
    db $10
    ret z

    ld [$1005], sp
    ret z

    db $10
    ld b, $10
    ret z

    jr @+$09

    db $10
    ret nc

    ldh [rNR10], a
    db $10
    ret nc

    add sp, $11
    db $10
    ret nc

    ldh a, [rNR12]
    db $10
    ret nc

    ld hl, sp+$13
    db $10
    ret nc

    nop
    inc d
    db $10
    ret nc

    ld [$1015], sp
    ret nc

    db $10
    ld d, $10
    ret nc

    jr @+$19

    db $10
    ret c

    ldh [rNR41], a
    nop
    ret c

    add sp, $21
    nop
    ret c

    ldh a, [rNR43]
    nop
    ret c

    ld hl, sp+$23
    nop
    ret c

    nop
    inc h
    nop
    ret c

    ld [$0025], sp
    ret c

    db $10
    ld h, $00
    ldh [$e0], a
    jr nc, OpcodeData_7337

    ldh [$e8], a
    ld sp, $e010
    ldh a, [$32]
    db $10
    ldh [$f8], a
    inc sp
    db $10
    ldh [rP1], a
    inc [hl]
    db $10

OpcodeData_7337:
    ldh [$08], a
    dec [hl]
    db $10
    ldh [rNR10], a
    ld [hl], $10
    add sp, -$20
    ld b, b
    db $10
    add sp, -$18
    ld b, c
    db $10
    add sp, -$10
    ld b, d
    db $10
    add sp, -$08
    ld b, e
    db $10
    add sp, $00
    ld b, h
    db $10
    add sp, $08
    ld b, l
    db $10
    add sp, $10
    ld b, [hl]
    db $10
    ldh a, [$e0]
    ld d, b
    db $10
    ldh a, [$e8]
    ld d, c
    db $10
    ldh a, [$f0]
    ld d, d
    db $10
    ldh a, [$f8]
    ld d, e
    db $10
    ldh a, [rP1]
    ld d, h
    db $10
    ldh a, [$08]
    ld d, l
    db $10
    ldh a, [rNR10]
    ld d, [hl]
    db $10
    ld hl, sp-$20
    ld h, b
    nop
    ld hl, sp-$18
    ld h, c
    nop
    ld hl, sp-$10
    ld h, d
    nop
    ld hl, sp-$08
    ld h, e
    nop
    ld hl, sp+$00
    ld h, h
    nop
    ld hl, sp+$08
    ld h, l
    nop
    ld hl, sp+$10
    ld h, [hl]
    nop
    nop
    ldh [rSVBK], a
    stop
    add sp, $71
    nop
    nop
    ldh a, [$72]
    nop
    nop
    ld hl, sp+$73
    nop
    nop
    nop
    ld [hl], h
    nop
    nop
    ld [$0075], sp
    nop
    db $10
    halt
    nop
    jr @+$79

    nop
    add b
    ret z

    ldh [rP1], a
    db $10
    ret z

    jr @+$09

    db $10
    ret nc

    ldh [rNR10], a
    db $10
    ret nc

    jr @+$19

    db $10
    ret c

    ldh [rNR41], a
    nop
    ldh [$e0], a
    jr nc, OpcodeData_73DC

    add sp, -$20
    ld b, b
    db $10
    ldh a, [$e0]
    ld d, b
    db $10
    ld hl, sp-$20
    ld h, b
    nop
    ret z

    add sp, $07
    db $10

OpcodeData_73DC:
    ret z

    ldh a, [$08]
    db $10
    ret z

    ld hl, sp+$09
    db $10
    ret z

    nop
    ld a, [bc]
    db $10
    ret z

    ld [$100b], sp
    ret z

    db $10
    inc c
    db $10
    ret nc

    add sp, $17
    db $10
    ret nc

    ldh a, [rNR23]
    db $10
    ret nc

    ld hl, sp+$19
    db $10
    ret nc

    nop
    ld a, [de]
    db $10
    ret nc

    ld [$101b], sp
    ret nc

    db $10
    inc e
    db $10
    ret c

    add sp, $27
    nop
    ret c

    ldh a, [$28]
    nop
    ret c

    ld hl, sp+$29
    nop
    ret c

    nop
    ld a, [hl+]
    nop
    ret c

    ld [$002b], sp
    ret c

    db $10
    inc l
    nop
    ldh [$e8], a
    scf
    db $10
    ldh [$f0], a
    jr c, OpcodeData_7438

    ldh [$f8], a
    add hl, sp
    db $10
    ldh [rP1], a
    ld a, [hl-]
    db $10
    ldh [$08], a
    dec sp
    db $10
    ldh [rNR10], a
    inc a
    db $10

OpcodeData_7438:
    add sp, -$18
    ld b, a
    db $10
    add sp, -$10
    ld c, b
    db $10
    add sp, -$08
    ld c, c
    db $10
    add sp, $00
    ld c, d
    db $10
    add sp, $08
    ld c, e
    db $10
    add sp, $10
    ld c, h
    db $10
    ldh a, [$e8]
    ld d, a
    db $10
    ldh a, [$f0]
    ld e, b
    db $10
    ldh a, [$f8]
    ld e, c
    db $10
    ldh a, [rP1]
    ld e, d
    db $10
    ldh a, [$08]
    ld e, e
    db $10
    ldh a, [rNR10]
    ld e, h
    db $10
    ld hl, sp-$18
    ld h, a
    nop
    ld hl, sp-$10
    ld l, b
    nop
    ld hl, sp-$08
    ld l, c
    nop
    ld hl, sp+$00
    ld l, d
    nop
    ld hl, sp+$08
    ld l, e
    nop
    ld hl, sp+$10
    ld l, h
    nop
    nop
    add sp, $77
    nop
    nop
    ldh a, [$78]
    nop
    nop
    ld hl, sp+$79
    nop
    nop
    nop
    ld a, d
    nop
    nop
    ld [$007b], sp
    nop
    db $10
    ld a, h
    nop
    add b
    ret z

    ldh [rP1], a
    db $10
    ret z

    jr @+$09

    db $10
    ret nc

    ldh [rNR10], a
    db $10
    ret nc

    jr @+$19

    db $10
    ret c

    ldh [rNR41], a
    nop
    ldh [$e0], a
    jr nc, OpcodeData_74C1

    add sp, -$20
    ld b, b
    db $10
    ldh a, [$e0]
    ld d, b
    db $10
    ld hl, sp-$20
    ld h, b
    nop
    ret nc

    add sp, -$6f
    db $10

OpcodeData_74C1:
    ret nc

    ldh a, [$92]
    db $10
    ret nc

    ld hl, sp-$6d
    db $10
    ret nc

    nop
    sub h
    db $10
    ret nc

    ld [$1095], sp
    ret nc

    db $10
    sub [hl]
    db $10
    ret c

    add sp, -$5f
    nop
    ret c

    ldh a, [$a2]
    nop
    ret c

    ld hl, sp-$5d
    nop
    ret c

    nop
    and h
    nop
    ret c

    ld [$00a5], sp
    ret c

    db $10
    and [hl]
    nop
    ldh [$e8], a
    or c
    db $10
    ldh [$f0], a
    or d
    db $10
    ldh [$f8], a
    or e
    db $10
    ldh [rP1], a
    or h
    db $10
    ldh [$08], a
    or l
    db $10
    ldh [rNR10], a
    or [hl]
    db $10
    add sp, -$18
    pop bc
    db $10
    add sp, -$10
    jp nz, $e810

    ld hl, sp-$3d
    db $10
    add sp, $00
    call nz, $e810
    ld [$10c5], sp
    add sp, $10
    add $10
    ldh a, [$e8]
    pop de
    db $10
    ldh a, [$f0]
    jp nc, $f010

    ld hl, sp-$2d
    db $10
    ldh a, [rP1]
    call nc, $f010
    ld [$10d5], sp
    ldh a, [rNR10]
    sub $10
    ld hl, sp-$18
    pop hl
    nop
    ld hl, sp-$10
    ld [c], a
    nop
    ld hl, sp-$08
    db $e3
    nop
    ld hl, sp+$00
    db $e4
    nop
    ld hl, sp+$08
    push hl
    nop
    ld hl, sp+$10
    and $00
    ret z

    add sp, -$7f
    db $10
    ret z

    ldh a, [$82]
    db $10
    ret z

    ld hl, sp-$7d
    db $10
    ret z

    nop
    add h
    db $10
    ret z

    ld [$1085], sp
    ret z

    db $10
    add [hl]
    stop
    ldh [$f0], a
    stop
    add sp, -$0f
    stop
    ldh a, [$f2]
    stop
    ld hl, sp-$0d
    stop
    nop
    db $f4
    stop
    ld [$10f5], sp
    nop
    db $10
    or $10
    add b
    ret z

    ldh [rP1], a
    db $10
    ret z

    jr @+$09

    db $10
    ret nc

    ldh [rNR10], a
    db $10
    ret nc

    jr @+$19

    db $10
    ret c

    ldh [rNR41], a
    nop
    ldh [$e0], a
    jr nc, OpcodeData_75AA

    add sp, -$20
    ld b, b
    db $10
    ldh a, [$e0]
    ld d, b
    db $10
    ld hl, sp-$20
    ld h, b
    nop
    ret z

    add sp, -$79
    db $10

OpcodeData_75AA:
    ret z

    ldh a, [$88]
    db $10
    ret z

    ld hl, sp-$77
    db $10
    ret z

    nop
    adc d
    db $10
    ret z

    ld [$108b], sp
    ret z

    db $10
    adc h
    db $10
    ret nc

    add sp, -$69
    db $10
    ret nc

    ldh a, [$98]
    db $10
    ret nc

    ld hl, sp-$67
    db $10
    ret nc

    nop
    sbc d
    db $10
    ret nc

    ld [$109b], sp
    ret nc

    db $10
    sbc h
    db $10
    ret c

    add sp, -$59
    nop
    ret c

    ldh a, [$a8]
    nop
    ret c

    ld hl, sp-$57
    nop
    ret c

    nop
    xor d
    nop
    ret c

    ld [$00ab], sp
    ret c

    db $10
    xor h
    nop
    ldh [$e8], a
    or a
    db $10
    ldh [$f0], a
    cp b
    db $10
    ldh [$f8], a
    cp c
    db $10
    ldh [rP1], a
    cp d
    db $10
    ldh [$08], a
    cp e
    db $10
    ldh [rNR10], a
    cp h
    db $10
    add sp, -$18
    rst $00
    db $10
    add sp, -$10
    ret z

    db $10
    add sp, -$08
    ret


    db $10
    add sp, $00
    jp z, $e810

    ld [$10cb], sp
    add sp, $10
    call z, $f010
    add sp, -$29
    db $10
    ldh a, [$f0]
    ret c

    db $10
    ldh a, [$f8]
    reti


    db $10
    ldh a, [rP1]
    jp c, $f010

    ld [$10db], sp
    ldh a, [rNR10]
    call c, $f810
    add sp, -$19
    nop
    ld hl, sp-$10
    add sp, $00
    ld hl, sp-$08
    jp hl


    nop
    ld hl, sp+$00
    ld [$f800], a
    ld [$00eb], sp
    ld hl, sp+$10
    db $ec
    nop
    nop
    add sp, -$09
    stop
    ldh a, [$f8]
    stop
    ld hl, sp-$07
    stop
    nop
    ld a, [$0010]
    ld [$10fb], sp
    nop
    db $10
    db $fc
    stop
    jr @-$01

    db $10
    add b
    ret z

    ldh [rP1], a
    db $10
    ret z

    jr @+$09

    db $10
    ret nc

    ldh [rNR10], a
    db $10
    ret nc

    jr @+$19

    db $10
    ret c

    ldh [rNR41], a
    db $10
    ldh [$e0], a
    jr nc, OpcodeData_7693

    add sp, -$20
    ld b, b
    db $10
    ldh a, [$e0]
    ld d, b
    db $10
    ld hl, sp-$20
    ld h, b
    db $10
    ret z

    add sp, -$79
    db $10

OpcodeData_7693:
    ret z

    ldh a, [$88]
    db $10
    ret z

    ld hl, sp-$77
    db $10
    ret z

    nop
    adc d
    db $10
    ret z

    ld [$108b], sp
    ret z

    db $10
    adc h
    db $10
    ret nc

    add sp, -$69
    db $10
    ret nc

    ldh a, [$98]
    db $10
    ret nc

    ld hl, sp-$67
    db $10
    ret nc

    nop
    sbc d
    db $10
    ret nc

    ld [$109b], sp
    ret nc

    db $10
    sbc h
    db $10
    ret c

    add sp, -$59
    db $10
    ret c

    ldh a, [$a8]
    db $10
    ret c

    ld hl, sp-$57
    db $10
    ret c

    nop
    xor d
    db $10
    ret c

    ld [$10ab], sp
    ret c

    db $10
    xor h
    db $10
    ldh [$e8], a
    or a
    db $10
    ldh [$f0], a
    cp b
    db $10
    ldh [$f8], a
    cp c
    db $10
    ldh [rP1], a
    cp d
    db $10
    ldh [$08], a
    cp e
    db $10
    ldh [rNR10], a
    cp h
    db $10
    add sp, -$18
    rst $00
    db $10
    add sp, -$10
    ret z

    db $10
    add sp, -$08
    ret


    db $10
    add sp, $00
    jp z, $e810

    ld [$10cb], sp
    add sp, $10
    call z, $f010
    add sp, -$29
    db $10
    ldh a, [$f0]
    ret c

    db $10
    ldh a, [$f8]
    reti


    db $10
    ldh a, [rP1]
    jp c, $f010

    ld [$10db], sp
    ldh a, [rNR10]
    call c, $f810
    add sp, -$19
    db $10
    ld hl, sp-$10
    add sp, $10
    ld hl, sp-$08
    jp hl


    db $10
    ld hl, sp+$00
    ld [$f810], a
    ld [$10eb], sp
    ld hl, sp+$10
    db $ec
    db $10
    add b
    ld b, h
    ld [hl], a
    ld d, l
    ld [hl], a
    ld h, [hl]
    ld [hl], a
    ld [hl], a
    ld [hl], a
    adc b
    ld [hl], a
    sbc c
    ld [hl], a
    ldh a, [$f8]
    nop
    nop
    ldh a, [rP1]
    ld bc, $f800
    ld hl, sp+$02
    nop
    ld hl, sp+$00
    inc bc
    nop
    add b
    ldh a, [$f8]
    nop
    nop
    ldh a, [rP1]
    ld bc, $f800
    ld hl, sp+$02
    nop
    ld hl, sp+$00
    inc bc
    nop
    add b
    ldh a, [$f8]
    inc b
    nop
    ldh a, [rP1]
    dec b
    nop
    ld hl, sp-$08
    ld b, $00
    ld hl, sp+$00
    rlca
    nop
    add b
    ldh a, [$f8]
    inc b
    nop
    ldh a, [rP1]
    dec b
    nop
    ld hl, sp-$08
    ld b, $00
    ld hl, sp+$00
    rlca
    nop
    add b
    ldh a, [$f8]
    ld [$f000], sp
    nop
    add hl, bc
    nop

OpcodeData_7790:
    ld hl, sp-$08
    ld a, [bc]
    nop
    ld hl, sp+$00
    dec bc
    nop
    add b
    ldh a, [$f8]
    ld [$f000], sp
    nop
    add hl, bc
    nop
    ld hl, sp-$08
    ld a, [bc]
    nop
    ld hl, sp+$00
    dec bc
    nop
    add b
    ld e, e
    ld a, a
    adc [hl]
    inc h
    nop
    ret nc

    ret


    inc bc
    inc de
    rra
    inc [hl]
    dec h
    ld [hl+], a
    dec h
    ccf
    rst $38
    ld e, e
    ld a, a
    adc [hl]
    ld d, h
    jr nz, OpcodeData_7790

    ret


    nop
    ld [de], a
    db $10
    jr nc, OpcodeData_77E6

    jr nz, OpcodeData_77ED

    ccf
    adc a
    inc hl
    rlca
    ld b, $04
    nop
    ret nc

    ret


    dec [hl]
    dec de
    ld b, c
    ld e, $ae
    inc d
    dec de
    nop
    db $fc
    and a
    dec de
    scf
    ld [hl], c
    pop af
    or e
    rst $18
    ld b, $0a
    and $f4
    or [hl]

OpcodeData_77E6:
    sbc a
    db $fd
    ld c, a
    ld a, [hl]
    nop
    ld [hl], l
    push af

OpcodeData_77ED:
    db $eb
    ei
    push af
    push af
    adc e
    ld [hl], a
    ld b, b
    ccf
    cpl
    jr nz, OpcodeData_7827

    ccf
    jr nz, OpcodeData_787A

    nop
    rst $38
    rst $38
    nop
    rst $38
    rst $38
    nop
    rst $38
    nop
    ld b, [hl]
    ld d, c
    add d
    nop
    ld bc, OpcodeHandler2C
    sbc c
    ld bc, $f65f
    sbc $56
    ld a, a
    sub $5f
    rst $30
    rst $38
    push af
    rst $30
    db $fd
    rst $30
    db $fd
    rst $38
    rst $30
    db $e3

OpcodeData_781E:
    cp c
    db $eb
    xor c
    ei
    jp hl


    and c
    db $eb
    ld a, a
    add e

OpcodeData_7827:
    ld a, a
    add b
    add b
    ld b, l
    sbc a

OpcodeData_782C:
    add e
    rst $38

OpcodeData_782E:
    nop
    nop
    ld b, l
    rst $38

OpcodeData_7832:
    add e
    cp $01
    ld bc, $f945
    ld b, l
    sbc a
    ld b, d
    add b
    add c
    ld a, a
    ld b, l
    rst $38
    ld [bc], a
    add c
    rst $38
    ld b, l
    ld sp, hl
    ld b, d
    ld bc, $fe81
    ld c, b
    sbc a
    ld c, b
    rst $38
    ld c, b
    ld sp, hl
    add e
    rra
    ccf
    ld a, a
    ld b, l
    rst $38
    add e
    ld hl, sp-$04
    cp $45
    rst $38
    ld c, b
    ld b, b
    ld c, b
    ld a, [bc]
    add h
    ld b, e
    ld c, h
    ld [hl], b
    ret nz

    inc b
    ld b, h
    ld a, [bc]
    add h
    dec bc
    inc c
    jr nc, OpcodeData_782C

    inc b
    adc b
    inc bc
    inc c
    jr nc, OpcodeData_7832

    inc bc
    inc c
    jr nc, @-$3e

    inc b
    add c
    ccf
    ld b, a

OpcodeData_787A:
    ld b, b
    add c
    rst $38
    rlca
    add c
    db $fc
    ld b, a
    ld [bc], a
    sbc b
    nop
    ld [$0c08], sp
    inc b
    ld b, $02
    inc bc
    ld b, $0e
    ld [bc], a
    inc bc
    inc bc
    rlca
    ld [bc], a
    inc bc
    rrca
    ld [bc], a
    ld b, $04
    inc c
    ld [$0818], sp
    jr OpcodeData_781E

    ccf
    ld b, a
    ld b, b
    add c
    rst $38
    add hl, bc
    add e
    ld b, $08
    db $10
    ld b, e
    jr nz, OpcodeData_782E

    nop
    ld [$82e4], sp
    ld b, h
    add c
    ld c, b
    jr nz, OpcodeData_78FB

    add c
    dec b
    or l
    jr c, OpcodeData_78DC

    ld [de], a
    nop
    nop
    inc bc
    rrca

OpcodeData_78BD:
    inc a
    ld c, b
    sub b
    sub c
    nop
    ld a, a
    call nz, $2018
    ld a, h
    db $c4, $89, $00
    ret nz

    jr nc, OpcodeData_78D9

    ld a, $c7
    add c
    nop
    ld de, $0c0a
    inc d
    inc h
    inc h
    ld [hl+], a
    cpl

OpcodeData_78D9:
    cp $e4
    add e

OpcodeData_78DC:
    inc b
    inc e
    add hl, hl
    add sp, $70
    add hl, bc
    db $10
    db $e3
    ld [de], a
    inc c
    call nz, $82a6
    nop
    add b
    inc bc
    ld b, d
    ld b, b
    cp [hl]
    ld h, b
    inc de
    ld d, $1c
    inc d
    rrca
    ld [bc], a
    ld a, $57
    add hl, de
    ld l, $28

OpcodeData_78FB:
    ld h, e
    xor h
    sub b
    ld h, $cc
    add e
    add c
    add c
    ld bc, $433d
    rra
    jr nz, OpcodeData_7941

    jr c, @+$3e

    rra
    ld e, $1c
    cp b
    ldh a, [rHDMA4]
    ld [hl], $4c
    ld b, [hl]
    ld a, [hl-]
    daa
    inc e
    nop
    ld [de], a
    ld [hl+], a
    ld b, c
    add c
    add b
    nop
    ld bc, $2002
    jr OpcodeData_7943

    jr nz, OpcodeData_78BD

    sub b
    adc a
    ld b, h
    ld b, b
    nop
    inc bc
    ld b, a
    ld a, h
    ld b, c
    ldh [$82], a
    ret nz

    ldh [rTMA], a
    sbc c
    inc bc
    inc b
    inc b
    ld [$0909], sp
    dec b
    ld [hl], d
    adc [hl]
    add b
    ld [hl+], a
    rst $38
    pop bc

OpcodeData_7941:
    pop bc
    add b

OpcodeData_7943:
    add b
    pop bc
    pop bc
    jr nc, OpcodeData_7960

    sbc b
    sbc b
    or b
    and a
    ld a, b
    inc b
    add l
    rrca
    jr c, OpcodeData_799A

    sub b
    sub e
    inc bc
    add l
    cp $01
    ld a, $e4
    adc b
    inc b
    adc a
    ret nz

    jr nc, OpcodeData_7968

OpcodeData_7960:
    ld b, $08
    db $10
    pop hl
    ld [de], a
    ld c, $c4
    and [hl]

OpcodeData_7968:
    add d
    inc sp
    ld c, l
    pop bc
    dec b
    cp d
    inc de
    ld d, $1c
    inc d
    rrca
    ld [bc], a
    ld e, $2b
    add e
    add e
    add a
    inc c
    inc a
    ld e, b
    jr c, @+$72

    nop
    add b
    nop
    ld bc, $1f07
    rrca
    inc c
    ld a, [hl]
    add c
    add b
    ld h, b
    add b
    pop hl
    ld b, e
    ld a, $3f
    ldh a, [$80]
    nop
    nop
    add b
    ldh [$3f], a
    ld hl, sp+$7c
    inc c
    inc b

OpcodeData_799A:
    nop
    ld bc, $fe3f
    jr OpcodeData_79B8

    jr nc, OpcodeData_7A02

    ldh [$c0], a
    ret nz

    ldh [rSB], a
    ld [bc], a
    ld b, e
    inc b
    adc e
    inc a
    ld h, $12
    ldh a, [rNR32]
    cpl
    ld b, a
    jr nz, OpcodeData_79D4

    ld b, b
    ld b, c
    inc bc
    sub d

OpcodeData_79B8:
    rlca
    add hl, de
    dec hl
    ld l, d
    xor d
    ld de, $0c0a
    inc [hl]
    db $e4
    inc h
    ld [hl+], a
    ld l, a
    xor l

OpcodeData_79C6:
    or a
    cp a
    ld a, [hl]
    jr c, @+$05

    adc [hl]
    di
    or $fc
    inc d
    rrca
    ld [bc], a
    ld [bc], a
    inc bc

OpcodeData_79D4:
    inc b
    ld b, $04
    ld [bc], a
    ld [bc], a
    ld bc, $b006
    jr OpcodeData_79F2

    ld [de], a
    ld [de], a
    nop
    ld a, a
    call nz, AudioCheckRange12
    ld c, b
    adc b
    add hl, bc
    ld de, $0c0a
    rla
    ld a, [hl+]
    jr z, OpcodeData_7A17

    cpl
    cp $e4

OpcodeData_79F2:
    add e
    ld [hl], h
    xor b
    adc c
    adc b
    ld [hl], b
    ld de, $0c0a
    rla
    jr z, @+$2c

    jr z, OpcodeData_7A2F

    cp $e4

OpcodeData_7A02:
    add e
    ld [hl], h
    adc b
    xor c
    adc b
    ld [hl], b
    rla
    ld a, [bc]
    ld [$4318], sp
    jr z, OpcodeData_79C6

    cpl
    db $76
    xor h
    adc e
    adc h
    adc b
    adc c
    adc b

OpcodeData_7A17:
    ld [hl], b
    inc de
    ld d, $1c
    inc d
    rrca
    nop
    ld a, c
    xor [hl]
    add hl, de
    ld l, $2a
    ld c, e
    call $fa61
    ld b, $a4
    ld h, h
    sub h
    adc a
    ld a, d
    ld b, a
    inc a

OpcodeData_7A2F:
    nop
    dec b
    ld a, l
    db $db
    ld c, e
    sub h
    db $f4
    adc c
    ld [hl], d
    ccf
    ld b, b
    ld e, a
    ld e, a
    ld d, b
    ld b, b
    ld e, a
    ccf
    rst $38
    nop
    rst $38
    rst $38
    nop
    nop
    ld b, e
    rst $38
    ld b, [hl]
    add b
    ld b, d
    rst $38
    ld b, [hl]
    dec bc
    sbc c
    rst $38
    xor b
    adc c
    and c
    xor c
    and b
    xor c
    xor b
    adc b
    ld [bc], a
    ld a, [bc]
    ld [$0a02], sp
    ld [bc], a
    ld [bc], a
    ld a, [bc]
    ld e, a
    ld c, a
    rra
    ld e, a
    ld c, a
    ld e, a
    ld e, a
    rra
    rst $38
    add l
    ccf
    ld a, a
    rst $38
    ld a, a
    ld a, a
    ld b, l
    rst $38
    xor e
    cp $ff
    ld a, [$e8fc]
    ldh a, [$c2]
    pop hl
    pop hl
    ret nz

    add b
    ret nz

    ret nz

    add b
    adc d
    add h
    ld d, $8f
    and [hl]
    rla
    nop
    ld hl, $ffff
    rst $08
    sbc a
    add a
    rrca
    rrca
    rlca
    rrca
    rlca
    ld b, e
    add a
    ld de, $8862
    ld de, $f0e8
    ld a, [$fefc]
    ld b, e
    rst $38
    sub c
    di
    rst $38
    ld a, [$58f9]
    inc a
    add [hl]
    inc c
    ret nz

    ldh [$80], a
    ret nz

    nop
    add b
    add b
    nop
    inc bc
    rlca
    cp [hl]
    ld b, b
    jr nz, OpcodeData_7AB6

OpcodeData_7AB6:
    ld b, b
    nop
    ld b, b
    add b
    ld b, b
    nop
    ld hl, sp+$08
    ld b, $02
    ld bc, $0001
    inc b
    adc b
    ld b, b
    add h
    dec [hl]
    ld [hl], d
    jr nz, @+$7e

    nop
    ld h, d
    nop
    ld b, d
    ld d, h
    add d
    ld h, b
    sbc h
    ld b, b
    add d
    db $10
    ld h, b
    inc b
    jr @+$04

    inc b
    ld de, $4262
    add c
    nop
    pop bc
    nop
    ld hl, $0000
    ld [bc], a
    ld bc, $0708

OpcodeData_7AE9:
    dec b
    add hl, de
    inc hl
    ld bc, $0303
    rlca
    inc bc
    ld b, c
    inc bc
    cp [hl]
    rlca
    ld b, d
    inc a
    jr z, OpcodeData_7AE9

    db $f4
    ld hl, sp-$18
    db $f4
    jp nz, $85e4

    jp nz, $e7c8

    db $e3
    rst $38
    sub b
    ld h, b
    ld h, c
    nop
    inc b
    inc bc
    ld [$1204], sp
    inc c
    ret


    ld a, $34
    ei
    ld hl, sp-$10
    ld b, b
    ld hl, $c120
    add d
    ld bc, $8241
    inc b
    ld b, d
    ld c, d
    add h
    sub h
    ld [$3048], sp
    rlca
    rlca
    rrca
    rlca
    rlca
    rrca
    rra
    rrca
    jr OpcodeData_7B3E

    db $10
    add hl, bc
    ld [bc], a
    ld b, c
    db $10
    add d
    jr nz, @+$12

    ld c, b
    rst $38
    sbc e
    cp a
    rst $08
    adc a
    rlca

OpcodeData_7B3E:
    inc bc
    rlca
    rlca
    inc bc
    pop af
    ldh [$e4], a
    db $e3
    jp z, $e4e4

    ret z

    adc b
    ret nc

    add b
    ret nc

    adc b
    ret nc

    call nz, ReformatDigitResult
    ret nz

    add b
    dec c
    rst $38
    ld h, b
    ld bc, $00fd
    xor $30
    inc bc
    rlca
    rrca

OpcodeData_7B60:
    inc c
    dec de
    ld d, $ff
    ld [hl], $2d
    ld e, l
    ld h, e
    ld a, a
    ret nz

    rst $38
    add c
    rst $38
    rst $38
    add b
    db $fd
    add e
    rst $28
    sbc a
    pop af
    ei
    db $fd
    ld bc, $0008
    nop
    ld bc, $1f1f
    rra
    ld de, $cdff
    db $eb
    xor l
    ld a, a
    db $d3

OpcodeData_7B85:
    dec sp
    add sp, -$68
    rst $38
    add sp, $18
    add sp, $18
    ret z

    jr c, OpcodeData_7B60

    cp b
    rst $38
    jr nz, OpcodeData_7B85

    pop bc
    pop hl
    ld sp, hl
    ld a, a

OpcodeData_7B98:
    rst $20
    cp a
    db $fd
    and c
    db $fc
    jr nc, OpcodeData_7B98

    daa
    ld a, [$a417]
    ld a, [hl]
    rst $38
    ld hl, sp-$04
    ccf
    ld l, a
    inc a
    scf
    inc [hl]
    cpl
    rst $38
    jr @+$41

    db $10
    rra
    db $10
    rra
    dec d
    rra
    rst $38
    dec c
    rrca
    ld a, l
    rst $38
    and a
    ei
    add d
    rst $38
    ei
    cp $fe
    xor $31
    jr OpcodeData_7C02

    jr c, @+$3e

    jr nz, @+$01

    ldh a, [$fe]
    rst $38
    ld [hl], $ff
    db $10
    ldh a, [rNR10]

OpcodeData_7BD2:
    rst $38
    ldh a, [$5e]
    rst $38
    ld [hl], l
    rst $38
    ld h, c
    rst $38
    jp $bf9f


    adc h
    cp $70
    ld hl, sp-$12
    ld sp, $33f0
    rra
    rst $30
    db $10
    scf
    ld l, $fa
    ccf
    nop
    ld bc, $0000
    rst $38
    ld a, $3e
    cp $e2
    cp d
    db $76
    jp c, $fb3e

    xor $1e
    jr OpcodeData_7BFF

    ret z

OpcodeData_7BFF:
    jr c, OpcodeData_7BD2

    cp c

OpcodeData_7C02:
    ld hl, $f3cf
    jp $fae3


    daa
    rrca
    add hl, sp
    ld b, $75
    rst $38
    rst $38
    xor l
    rst $38
    add l
    rst $38
    ld h, e
    rst $38
    inc e
    dec a
    cp $ee
    ld sp, $3030
    jr nc, OpcodeData_7C8E

    ld h, b
    ld h, b
    ld c, h
    rst $18
    xor $fc
    cp $30
    ld hl, sp+$5c
    ld bc, $f050
    rst $38
    ld [hl], b
    ldh a, [$60]
    ldh [$fe], a
    rst $38
    push bc
    cp a
    rst $38
    add c
    rst $38
    rst $38
    rst $38
    nop
    nop
    db $10
    ld a, b
    rst $38
    ld l, b

OpcodeData_7C3F:
    sbc b
    ld hl, sp+$0c
    rst $30
    rrca
    ldh a, [rIF]
    rst $38
    ld h, b
    sbc a
    ld h, d
    sbc l
    ld h, $d9
    ld d, [hl]
    ld a, e
    rst $38
    ld [hl], $7b
    ld a, [bc]
    dec e
    dec e
    inc de
    dec de
    inc d
    cp a
    dec c
    ld e, $0b
    rrca
    rrca
    rra
    ccf
    nop
    inc de
    rst $38
    rla
    ld a, [de]
    dec de
    ld e, $17
    rra
    inc d
    inc e
    or e
    jr OpcodeData_7C8A

    ld l, h
    inc bc
    ld e, $17
    ldh [$f0], a
    ld e, l
    nop
    sub b
    ccf
    call c, $a4bc
    db $fc
    ld hl, sp-$04
    ld e, $1d
    xor $31
    nop
    ld [bc], a
    cp l
    nop

OpcodeData_7C86:
    xor $38
    inc b
    inc bc

OpcodeData_7C8A:
    inc bc
    inc b
    xor $33

OpcodeData_7C8E:
    add b
    rst $30
    ld h, b
    ld b, b
    and b
    ld b, $01
    ld b, d
    cp h
    ld [bc], a
    dec b
    rst $28
    inc bc
    inc b
    inc b
    inc bc
    xor $37
    ld a, l
    add d
    ld b, [hl]
    rst $38
    cp c
    dec hl
    db $c4, $05, $02
    nop
    ld bc, $ff20
    jr OpcodeData_7CC0

    jr z, OpcodeData_7D07

    add hl, hl
    ld e, h
    inc h
    adc h
    rst $38

OpcodeData_7CB6:
    ld [hl], h
    nop
    adc b
    jr nz, OpcodeData_7C3F

    nop
    and d
    ld b, b
    rst $38
    sbc c

OpcodeData_7CC0:
    jr z, OpcodeData_7C86

    add b
    inc a
    jr nc, OpcodeData_7D18

    jr nc, @+$01

    ld [de], a
    jr z, OpcodeData_7CD2

    inc b
    jr c, @-$53

    ld b, h
    ld b, b
    rst $38
    add e

OpcodeData_7CD2:
    inc b
    nop
    ld [bc], a
    ld bc, $204e
    inc b
    rst $38
    ld b, b
    inc b
    ld b, b
    adc [hl]
    ld c, d
    ld c, $ca
    and h
    sbc a
    ld b, b
    ld b, h
    dec sp
    ld a, [bc]
    inc h
    xor $39
    ld l, c
    rrca
    nop
    rst $38
    nop
    ld d, b
    jr nz, @+$22

    db $10
    jr nz, @+$12

    jr z, @+$01

    db $10
    ld hl, $101e
    ld h, c

OpcodeData_7CFC:
    ld b, b
    add b
    ld [$00df], sp
    ld bc, $0288
    ld [$0590], sp

OpcodeData_7D07:
    ld bc, $5f08
    add hl, bc
    inc b
    add e
    nop
    ld b, h
    sbc a
    nop
    jr z, OpcodeData_7CB6

    ld bc, ReadLevelStat
    jr z, OpcodeData_7D84

OpcodeData_7D18:
    add hl, sp
    nop
    adc b
    inc b
    ld c, b
    cp $af
    inc b
    ld d, b
    inc c
    sub h
    ld [$1820], sp
    nop
    cp a
    nop
    add c
    nop
    nop
    rst $38
    add b
    xor $30
    inc bc
    db $fd
    nop
    db $fd
    ld sp, $6488
    ld b, b
    sub h
    add b
    inc [hl]
    rst $38
    db $10
    ld h, h
    ld c, b
    inc h
    add h
    ld [$0458], sp
    rst $38
    ld [$8604], sp
    ld [hl], b
    nop
    ld [hl], b
    inc b
    ld [hl+], a
    rst $38
    nop
    inc e
    nop
    nop
    ld b, d
    add c
    nop
    cp $ff
    nop
    rst $38
    inc b
    inc bc
    dec bc
    inc b
    rlca
    ld [$17ff], sp
    ld [$130c], sp
    cpl
    db $10
    rra
    jr nz, @+$01

    rra
    jr nz, OpcodeData_7CFC

    ld h, b
    ldh [rNR10], a
    sub b
    ld h, b
    rst $38
    add sp, $10

OpcodeData_7D74:
    db $f4
    ld [$8478], sp
    ld a, d
    add h
    ld l, a
    ld a, h
    add d
    ld e, a
    jr nz, OpcodeData_7DB0

    dec bc
    cp h
    ld b, d
    ld b, b

OpcodeData_7D84:
    dec bc
    rst $38
    ld e, a
    jr nz, @+$41

    ld b, b
    ccf
    ld b, b
    cp a
    ld b, b
    cp $56
    dec b
    ret nc

    jr nz, OpcodeData_7D74

    db $10
    ldh [rNR10], a
    add sp, $56
    add l
    rrca
    ld [$9903], sp
    inc c
    xor e
    xor c
    inc c
    ret nc

    cp c
    ld [bc], a
    cp $0e
    dec de
    sub b
    inc h
    ld [bc], a
    inc [hl]
    ld h, c
    ld a, [de]
    ld h, d
    rst $38

OpcodeData_7DB0:
    add hl, de
    jr OpcodeData_7DD8

    ld b, c
    inc h
    and h
    ld b, d
    inc h
    rst $38
    jp nz, DataLookup_2790

    add hl, bc
    ld b, $04
    jr @+$12

    ei
    ld hl, sp-$10
    and e
    db $10
    ld [hl], h
    ld hl, sp-$08
    ld a, h
    ld a, b
    rst $38
    inc a
    add h
    ld e, c
    ld bc, $0323
    rra
    rla
    rst $38
    rst $00
    ld c, a
    cpl

OpcodeData_7DD8:
    ld b, $2f
    ld h, $16
    jr nz, @+$01

    ld d, $31
    ret nz

    jp nz, $8881

    add [hl]
    add b
    rst $38
    jr c, OpcodeData_7E09

    ld b, b

OpcodeData_7DEA:
    db $10
    ld h, b
    ld l, b

OpcodeData_7DED:
    sub b
    ld [hl], h
    rst $38
    adc b
    add b
    ld a, c
    ld [hl], c
    adc [hl]
    cp $01
    ld a, h
    rst $38
    add e
    sbc h
    ld h, e
    inc h
    dec de
    db $10
    rrca
    ld e, d
    db $fd
    and h
    sbc $01
    nop
    jr nz, OpcodeData_7E10

    db $10

OpcodeData_7E09:
    db $10
    jr OpcodeData_7E4B

    ld e, d
    sbc c
    jr OpcodeData_7DEA

OpcodeData_7E10:
    jr OpcodeData_7DED

    add b
    nop
    rst $38
    ccf
    ld a, a
    ld e, a
    ldh [$bf], a
    ret nz

    and $99
    ld a, a
    cp e
    rst $38
    xor $ff
    ld b, h
    xor $00
    db $fc
    ld sp, $01ff
    nop
    ld bc, $0301
    inc bc
    ld b, $07
    rst $38
    dec b
    ld b, $07
    nop
    nop
    rst $38
    rst $38
    rst $38
    rst $28
    nop
    rst $38
    nop
    ld h, [hl]
    push af
    ld [hl-], a
    call nz, $9cff
    rst $38
    db $e3
    sbc [hl]
    ld sp, hl
    or [hl]
    call $e79e

OpcodeData_7E4B:
    ld e, [hl]
    rst $38
    rst $20
    xor $f1
    or [hl]
    ld sp, hl
    inc e
    ccf
    rlca
    rst $38
    rrca
    jr c, OpcodeData_7ED5

    ld d, h
    xor $ba
    add $ba
    rst $38
    add $92
    xor $c6
    cp $7c
    cp $38
    ld sp, hl
    ld a, h
    db $fc
    ld [hl-], a
    ld a, $08
    ld b, d
    inc a
    cp l
    ld b, d
    ld e, e
    rst $38
    cp l
    ld [hl], a
    xor l
    ld l, l
    or a
    scf
    rst $08
    rst $18
    rlca
    ld a, [hl]
    ld a, [hl]
    inc a
    ld a, $0d
    nop
    sbc d
    dec b
    add e
    inc l
    dec l
    ld l, $11
    adc e
    ld [hl-], a
    inc sp
    nop
    ld [hl-], a
    inc sp
    nop
    nop
    jr nz, @+$23

    ld hl, $0522
    adc b
    inc l
    dec l
    ld l, $00
    nop
    jr z, @+$2b

    ld a, [hl+]
    dec b
    adc [hl]
    inc l
    dec l
    ld l, $30
    ld sp, $3000
    ld sp, $0000
    dec h
    ld h, $00
    daa
    ld [$208a], sp
    ld hl, $2625
    daa
    nop
    nop
    jr nz, OpcodeData_7EDB

    ld [hl+], a
    inc bc
    cp [hl]
    ld [hl-], a
    inc sp
    nop
    ld [hl-], a
    inc sp
    nop
    nop
    dec h
    nop
    jr z, OpcodeData_7EF1

    ld a, [hl+]
    ld l, l
    ld l, [hl]
    ld l, a
    ld [hl], b
    ld l, l
    ld l, [hl]
    ld l, a
    dec h
    ld h, $25
    jr z, OpcodeData_7EFE

OpcodeData_7ED5:
    ld a, [hl+]
    ld l, [hl]
    dec h
    ld h, $27
    ld l, l

OpcodeData_7EDB:
    ld l, [hl]
    ld l, a
    jr nc, OpcodeData_7F10

    ld l, [hl]
    jr nc, OpcodeData_7F13

    ld l, a
    ld [hl], b
    inc hl
    nop
    dec h
    ld h, $27
    ld [hl], c
    ld [hl], d
    ld [hl], e
    ld [hl], h
    ld [hl], c
    ld [hl], d
    ld [hl], e
    dec h

OpcodeData_7EF1:
    ld h, $23
    inc hl
    ld h, $27
    ld [hl], d
    inc hl
    ld h, $27
    ld [hl], c
    ld b, c
    ld [hl], d
    adc l

OpcodeData_7EFE:
    ld [hl], e
    ld [hl-], a
    inc sp
    ld [hl], d
    ld [hl-], a
    inc sp
    ld [hl], e
    ld [hl], h
    dec h
    nop
    dec h
    nop
    daa
    rlca
    adc d
    inc hl
    jr z, OpcodeData_7F39

OpcodeData_7F10:
    ld a, [hl+]
    nop
    daa

OpcodeData_7F13:
    nop
    dec h
    nop
    inc h
    inc bc
    adc h
    jr nc, OpcodeData_7F4C

    nop
    jr nc, OpcodeData_7F4F

    nop
    nop
    inc hl
    nop
    inc hl
    nop
    inc h
    rlca
    adc d
    inc hl
    dec h
    ld h, $00
    nop
    inc h
    nop
    inc hl
    nop
    daa
    inc bc
    add l
    ld [hl-], a
    inc sp
    nop
    ld [hl-], a
    inc sp
    inc b

OpcodeData_7F39:
    add c
    inc hl
    ld a, [bc]
    add c
    inc hl
    dec b
    add c
    inc hl
    dec b
    add l
    inc [hl]
    cpl
    nop
    inc [hl]
    cpl
    ld [bc], a
    rst $38
    nop
    sbc d

OpcodeData_7F4C:
    inc hl
    add e
    ld h, h

OpcodeData_7F4F:
    ld h, l
    ld h, [hl]
    inc bc
    adc d
    ld h, h
    ld h, l
    ld h, [hl]
    nop
    ld h, h
    ld h, l
    ld h, [hl]
    nop
    nop
    ld h, d
    ld b, $8a
    ld h, h
    ld h, l
    ld h, [hl]
    nop
    ld e, [hl]
    ld e, a
    nop
    nop
    ld h, h
    ld h, l
    ld b, e
    dec a
    add e
    ld h, [hl]
    ld h, h
    ld h, l
    ld b, e
    dec a
    add c
    ld h, l
    ld b, e
    dec a
    or b
    ld h, l
    ld h, [hl]
    ld h, a
    nop
    ld h, h
    ld h, l
    ld h, [hl]
    ld h, h
    ld h, l
    dec a
    dec a
    ld l, b
    nop
    ld h, b
    ld h, c
    nop
    ld e, b
    ld e, c
    ld e, b
    ld e, c
    ld e, b
    ld e, c
    ld e, b
    ld e, c
    ld e, b
    ld e, c
    ld e, b
    ld e, c
    ld e, b
    ld e, c
    ld e, b
    ld e, c
    ld e, b
    ld e, c
    ld e, b
    ld e, c
    ld e, b
    ld e, c
    ld e, b
    ld e, c
    ld e, b
    ld e, c
    ld e, b
    ld e, c
    ld e, b
    ld e, c
    ld e, b
    ld e, c
    ld a, a
    ldh [$9b], a
    ld h, b
    dec a
    rst $38
    ld a, $c7
    ld [$c990], a
    call $1392
    ld a, $03
    ld [$c9a6], a
    xor a
    ld [$c98b], a
    ld [$c98c], a
    ld [$c988], a
    ld [$c9a1], a
    ld [$ddc7], a
    ld [$ddc8], a
    ld [$c99a], a
    ld [$c9a4], a
    ld [$c9a7], a
    jp Jump_000_15e6


    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    inc b
