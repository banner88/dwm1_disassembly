; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

; ===========================================================================
; Bank $50 — BATTLE MODE manager (wGameMode $C88A == 2)
; ===========================================================================
; CORRECTED S68 (the old header framed this bank as "the main game state" —
; wrong: ROM0's mode tables prove bank $50 runs only while wGameMode==2).
; ROM0 top-level mode dispatch: $00:$030F = mode INIT table (from main loop
; $02B0), $00:$050F = per-frame TICK table. Mode 2 rows: init -> bank $50
; entry 0 (BattleInit $5DC9), tick -> bank $50 entry 1 ($5E21).
; Mode map (both tables, same order): 0=bank $15 (title/link menus),
; 1=bank $01 (FIELD), 2=bank $50 (BATTLE), 3=bank $02, 4/5=bank $5F
; (map-script/cutscene), 6=bank $18, 7=bank $55, 8-10=bank $59, 11/12=bank $56.
;
; ENTRY INTO BATTLE: a trigger (wild: bank $01 sets `set 6,[wGameState]`;
; script opcodes $05/$1F/$20/$36/$52/$5A/$5B: bank $04 handlers stage
; $DA02/$DA03+/$DA09 and `set 6,[wGameState]`, reset $C905) -> the bank $13
; transition machine label13_7366 ($C905: pick battle BGM $4B/$4D, random
; wipe effect $C906) -> $13:$73F5 does the ROM's ONLY `res 6,[wGameState]`
; (bit 6 is a request LATCH) and sets wGameMode=2.
;
; EXIT FROM BATTLE: BattleExitHandler ($640A, battle phase $0E) restores
; wGameMode=1 and `set 7,$C8EA`. $C8EA nonzero makes bank $01's field init
; SKIP its state reset (ClearAnimationState) — so wScriptStateFlags $D8D7 +
; script counter $D8D5/6 SURVIVE and the NPC script RESUMES at the command
; after the battle opcode. This is the engine guarantee behind every boss
; script's "trigger_battle then set flags/counters" pattern (E2).
; LOSS ($DB55==1, non-arena): $D92B=8, engine warp to Castle (writes the
; opcode-$0F cells $C96D-$C972 + $C96C=1, `res 7,$C8EA` -> full re-entry
; clears script state), 24-bit gold $CA4B-4D halved ($1E1E a=2), inventory
; loop drops items whose info byte +$0B bit 2 is clear (keep-on-defeat set
; for TinyMedal/BeastTail/WarpStaff/ShinyHarp/BookMark; table $03:$71DA,
; 12 B/item). Arena map $5D / Coliseum map $52 / $DA09==2 take special
; branches and explicitly clear $D8D7 (script killed).
;
; $D9EC — BATTLE PHASE MACHINE (18 phases; dispatcher BattlePhaseDispatch
; $5F2F, table BattlePhaseTable $5F3A; runs from entry 1 via $5EDE only when
; $DD62==0; frozen while $DB73==$FF until [$DD80]&[$DD9A]==$FF at
; BattlePhaseFreezeWait). Phase roles: see BattlePhaseTable comments.
; Outcome detection lives in bank $52's end-of-round KO scans (~$76C8):
; all party KO'd -> $DB55=1 (+link fork via bank $50 entry $0A); all enemies
; KO'd -> $DB55=0; common tail $52:$7743 XORs $DB55 for the link peer
; ($C863.1), sets victory ($69) / defeat ($4F) jingle, on loss $DB73=$FF,
; then $D9EC=$0A (post-battle phases).
;
; $D9F4 State Machine — NESTED battle sub-machine (11 states, 0-10),
; dispatched by LoadBtl_4017 from battle phase $04. NOTE (S68): the state
; descriptions below predate the mode-table correction; their "(overworld)"
; vs "(gate world)" split is actually LOCAL vs LINK — $C86C is the LINK
; battle flag (set only by bank $03 serial code $40D4/$4113 and bank
; $15/$18 link menus), NOT a gateworld flag (wInGateworld is $C969).
; Per-state RAM lists below are as previously traced; re-verify before use.
;   State 0  ($4031): Battle scene initialization
;     Calls: bank $55 entry 6
;     Writes: $C1C0, $D9F8/$D9F9 (VRAM ptr), $DB88
;     Reads: $C86C (LINK flag), $C863
;   State 1  ($40ED): Main input loop
;     Calls: bank $55 entry 5 (per-frame update)
;     Reads: $C846 (input), $C8DA, $D9F3; Writes: $D9F3, $D9F5
;     Transitions: -> 9 (UI wait), -> 1 (loop)
;   State 2  ($4114): Battle transition check (LOCAL)
;     Calls: bank $55 entry 6
;     Reads: $C846, $C863, $C8DA, $D9F3; Writes: $C8DD, $D9F3, $D9F5
;   State 3  ($41EE): Battle transition check (LINK)
;     Reads: $C846, $C863, $C86C, $C8DA, $D9F3; Writes: $C8C7, $D9F3
;   State 4  ($4215): Post-event processing
;     Reads: $C863, $C86C, $C86E, $D9F3; Writes: $C873, $C8C7, $D9F3
;   State 5  ($425E): Return to init (LOCAL)
;     Reads: $C863, $C86C, $C86E, $C899, $C89A, $C8DA; Writes: $C873
;   State 6  ($426E): Return to init (LINK). Transitions: -> 0
;   State 7  ($4301): Complex event handler (LOCAL)
;     Reads: $C863, $C86C, $C86E; Writes: $C1D5, $C1D6, $C873
;     Transitions: -> 0, -> 4, -> 1
;   State 8  ($43A7): Complex event handler (LINK)
;     Calls: bank $56 entry 5
;     Reads: $C863, $D9F5, $DB74/$DB75
;     Writes: $C8C7, $D9F4, $DB77, $DB88, $DD72/$DD73
;   State 9  ($41E0): UI wait -> return to input loop
;     Reads: $C825 (UI busy flag); Writes: $C8C7, $D9F3, $D9F4
;   State 10 ($59D6): Full reset -> state 0
;     Reads: $DB58-$DB5A, $DB88; Writes: $D9F4, $DB50
;
; Key RAM Variables (S68-verified where noted):
;   $D9EC    wBattlePhase — battle phase index (18 phases) [S68]
;   $D9ED    phase-9 sub-state (BattlePhase09SubTable, 6 entries) [S68]
;   $D9F3    Sub-state counter within current $D9F4 state
;   $D9F4    Nested sub-machine index 0-10 (wEventStateMachineIndex —
;            historical label name; battle-scoped) [S68]
;   $DB55    wBattlePostFlag = battle OUTCOME: 0=win, 1=loss, 2=neutral
;            (flee ends at 2 — resolver $5808: jump phase $0A, exp targets
;            $DD1F-22 masked $FF; caught monster = plain win 0; HW-pinned
;            S68). Also briefly the intro-event marker (see phase $02).
;            Set by bank $52 KO scans; XOR'd for link peer [S68]
;   $DB73    phase-machine freeze gate ($FF = frozen; loss jingle/fade) [S68]
;   $DB74/75 side combatant counts (local/link second side)
;   $DD62    battle-running latch: nonzero -> entry 1 runs bank $02 entry 0
;            instead of the phase machine [S68]
;   $DA33    frame delay counter (phases $00/$07/$08/$0A)
;   $DA80    master-intro loader state (1=loading gfx via $5E84 dw table
;            indexed $DA81; !=1 -> $5EDE battle/post-battle driver)
;   $C846    Input/button state
;   $C863    link context flags (bit 1 = second side present) [S68]
;   $C86C    LINK battle flag (writers: bank $03/$15/$18 only) [S68]
;   $C86E    link context (cleared with $C863-$C86D block at link teardown)
;   $C825    UI busy flag (text box active)
;   $C873    Screen transition flag
;   $C8C7    Event completion flag
;   $C8DA    Animation/effect counter (wMenu_selection alias in battle)
;   $C8EA    field-live/resume flag; battle exit sets bit 7 -> field skips
;            state reset -> SCRIPT RESUMES [S68]
;   $C899/9A wRNG1/2 — the LIVE RNG pair (advances per frame; HW-pinned
;            S68); saved/restored via $C1ED/EE; LoadBtl_5d29's &$1F==$1F
;            checks = 1/32-per-side random battle-intro event roll [S68]
;   $C8ED    follower-render suppression mask; boss win ($DA09==3) sets $0E,
;            kept by bank $01 only while $D92B==7 (cosmetic) [S68]
; ===========================================================================

SECTION "ROM Bank $050", ROMX[$4000], BANK[$50]

    db $50 ; Bank number

; Jump table: 11 external entry points (called via rst $10, H=$50)
    dw $5DC9                    ; Entry 0
    dw $5E21                    ; Entry 1
    dw $5E49                    ; Entry 2
    dw BattleDispatchEntry3            ; Entry 3
    dw BattleDispatchEntry4            ; Entry 4
    dw ClearTileBuffer            ; Entry 5
    dw $79EB                    ; Entry 6
    dw $59EB                    ; Entry 7
    dw $5B58                    ; Entry 8
    dw $5C78                    ; Entry 9
    dw jr_050_5cb4              ; Entry 10

; ---------------------------------------------------------------------------
; LoadBtl_4017 — nested $D9F4 sub-machine dispatcher (battle-scoped, S68)
; ---------------------------------------------------------------------------
; Reads $D9F4 and dispatches via the rst $00 jump table below. Called from
; battle phase $04 (BattlePhase04_SubMachineTick), NOT per-frame globally.
; ---------------------------------------------------------------------------
LoadBtl_4017:
    ld a, [wEventStateMachineIndex]            ; $D9F4 battle sub-state (0-10)
    rst $00                  ; Dispatch via jump table below

; $D9F4 sub-machine dispatch table (11 entries; battle-scoped)
    dw $4031                    ; State 0: Battle scene initialization
    dw Jump_050_40ed            ; State 1: Main input loop
    dw $4114                    ; State 2: Battle transition check (LOCAL)
    dw $41EE                    ; State 3: Battle transition check (LINK)
    dw $4215                    ; State 4: Post-event processing
    dw $425E                    ; State 5: Return to init (LOCAL)
    dw $426E                    ; State 6: Return to init (LINK)
    dw $4301                    ; State 7: Complex event handler (LOCAL)
    dw $43A7                    ; State 8: Complex event handler (LINK)
    dw $41E0                    ; State 9: UI wait -> return to input loop
    dw $59D6                    ; State 10: Full reset → state 0

; ---------------------------------------------------------------------------
; State 0 ($4031): Battle scene initialization
; ---------------------------------------------------------------------------
; Calls bank $55 entry 6 for setup, clears $D9F4-$D9FB (8 bytes),
; initializes VRAM tilemap pointer, validates party monsters.
; ---------------------------------------------------------------------------
    ld hl, $5506
    rst $10
    xor a
    ld hl, wEventStateMachineIndex
    ld bc, $0008
    call FillNBytesWithRegA
    ld hl, $9800
    ld a, l
    ld [$d9f8], a
    ld a, h
    ld [$d9f9], a
    ld a, $ff
    ld [$c1c0], a
    ld bc, $0300
    ld a, [$c86c]
    or a
    jr z, jr_050_4062

    ld a, [$c863]
    bit 1, a
    jr z, jr_050_4062

    ld bc, $0304

jr_050_4062:
    ld d, $00

jr_050_4064:
    ld a, c
    call SaveBtl_5b07
    jr c, jr_050_4081

    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    bit 4, [hl]
    jr nz, jr_050_4081

    inc d
    ld a, [$c1c0]
    cp $ff
    jr nz, jr_050_4081

    ld a, c
    ld [$c1c0], a

jr_050_4081:
    inc c
    dec b
    jr nz, jr_050_4064

    ld a, d
    ld [wBattleAttackerIdx], a
    ld bc, $0404
    ld a, [$c86c]
    or a
    jr z, jr_050_409c

    ld a, [$c863]
    bit 1, a
    jr z, jr_050_409c

    ld bc, $0400

jr_050_409c:
    ld d, $00

jr_050_409e:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_050_40a5

    inc d

jr_050_40a5:
    inc c
    dec b
    jr nz, jr_050_409e

    ld a, d
    ld [wBattleTargetIdx], a
    ld b, $08
    ld hl, $c1cd

jr_050_40b2:
    set 7, [hl]
    inc hl
    dec b
    jr nz, jr_050_40b2

    ld hl, wEventStateMachineIndex
    inc [hl]
    ld bc, $0300
    ld a, [$c863]
    bit 1, a
    jr z, jr_050_40c8

    ld c, $04

jr_050_40c8:
    ld a, c
    ld [$db61], a

jr_050_40cc:
    ld a, c
    call GetMonsterSlotInfo
    jr c, jr_050_40e8

    ld a, c
    ld hl, $db06
    call HL_AddA_x8
    ld a, [hl+]
    and $0c
    jr z, jr_050_40e8

    ld a, [hl]
    and $f0
    jr z, jr_050_40e8

    ld a, c
    ld [$db61], a
    ret


jr_050_40e8:
    inc c
    dec b
    jr nz, jr_050_40cc

    ret


; ---------------------------------------------------------------------------
; State 1 ($40ED): Normal Gameplay — Main Loop
; ---------------------------------------------------------------------------
; Active during normal gameplay. Handles NPC interaction, screen updates,
; and checks for battle/event transitions.
; Transitions: → state 9 (UI wait), → state 1 (loop)
; ---------------------------------------------------------------------------
Jump_050_40ed:
    ld hl, $5505
    rst $10
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ld de, $6ed2
    call LoadPaletteFromDE
    call ClearBattleTurnFlag
    ld de, $419b
    ld a, [wMenu_selection]
    call CalcBattleTableIndex
    call ClearTileBuffer
    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld a, [wJoypad_current_frame]
    and $08
    jr z, jr_050_412d

    ld a, [$d9f3]
    or a
    jr nz, jr_050_4124

    inc a
    jr jr_050_4126

jr_050_4124:
    ld a, $03

jr_050_4126:
    ld [$d9f3], a
    call CmpBtl_7a87
    ret


jr_050_412d:
    ld de, $419b
    ld hl, wMenu_selection
    call BtlFunc_782e
    ld a, [wJoypad_current_frame]
    bit 0, a
    jr z, jr_050_419a

    ld a, $59
    call PlaySoundEffect
    ld hl, wEventStateMachineIndex
    inc [hl]
    xor a
    ld [$d9f5], a
    ld hl, wMenu_selection
    set 7, [hl]
    ld hl, wOPTN_and_Item_selection
    ld bc, $0007
    ld a, $00
    call FillNBytesWithRegA
    ld a, [wMenu_selection]
    and $0f
    cp $01
    ret nz

    ld hl, $5506
    rst $10
    xor a
    ld [$c8dd], a
    ld a, [$c863]
    bit 1, a
    jr z, jr_050_4176

    ld a, $04
    ld [$c8dd], a

jr_050_4176:
    call LoadBtl_41a5
    jr nc, jr_050_41b9

    ld a, [$c1c0]
    ld [$c8dd], a
    ld hl, $d9f5
    inc [hl]
    ld hl, $d9f5
    inc [hl]
    call RefreshBattleGraphics
    ld hl, $d9f5
    inc [hl]
    ld a, $81
    ld [wOPTN_and_Item_selection], a
    ld a, $01
    ld [$d9fc], a

jr_050_419a:
    ret


    pop bc
    ld bc, $0201
    rst $00
    ld bc, $0207
    rst $38
    rst $38

LoadBtl_41a5:
    ld a, [$c8dd]
    ld c, a
    ld b, $03

jr_050_41ab:
    ld a, c
    call SaveBtl_5b07
    jr nc, jr_050_41b7

    inc c
    dec b
    jr nz, jr_050_41ab

    xor a
    ret


jr_050_41b7:
    scf
    ret


jr_050_41b9:
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ld hl, $0002
    ld a, $09
    ld [wEventStateMachineIndex], a
    ld a, l
    ld [$c822], a
    ld a, h
    ld [$c823], a
    ld hl, $4c00
    rst $10
    ld de, $2e07
    call LoadPaletteFromDE
    call ClearTileBuffer
    ret


    ld a, [$c825]
    or a
    ret nz

    call ClearSpriteBuffer
    ld a, $01
    ld [wEventStateMachineIndex], a
    ret


    ld a, [wJoypad_current_frame]
    and $08
    jr z, jr_050_4207

    ld a, [$d9f3]
    or a
    jr nz, jr_050_41fe

    inc a
    jr jr_050_4200

jr_050_41fe:
    ld a, $03

jr_050_4200:
    ld [$d9f3], a
    call CmpBtl_7a87
    ret


jr_050_4207:
    ld a, [wMenu_selection]
    rst $00
    ret z

    ld b, e
    dec de
    ld b, h
    cp e
    ld c, a
    ld [de], a
    ld d, a
    sub h
    ld b, a
    ld a, [$d9f3]
    or a
    jr z, jr_050_4224

    ld a, $03
    ld [$d9f3], a
    call LoadBtl_7b8f
    ret


jr_050_4224:
    ld a, [$c86c]
    or a
    jr z, jr_050_4259

    ld a, $01
    ld [$c8c7], a
    ld de, $cacd
    ld a, [$c863]
    bit 1, a
    jr nz, jr_050_423c

    ld de, $cd21

jr_050_423c:
    ld hl, $c180
    call Copy4Bytes
    ld a, $f6
    call SetTextIdParam
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call SetBtl_79ae
    ld de, $2e07
    call LoadPaletteFromDE
    call ClearTileBuffer

jr_050_4259:
    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld a, [$c86c]
    or a
    jr z, jr_050_4269

    ld a, $01
    ld [$c873], a

jr_050_4269:
    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld a, [$c86c]
    or a
    jp z, Jump_050_42fc

    ld a, [$c86e]
    cp $01
    ret nz

    ld de, $dd03
    ld a, [$c863]
    bit 1, a
    jr z, jr_050_4288

    ld de, $dd07

jr_050_4288:
    ld hl, $c1da
    ld a, [de]
    ld [hl+], a
    inc de
    ld a, [de]
    ld [hl+], a
    inc de
    ld a, [de]
    ld [hl+], a
    ld a, [wRNG1]
    ld [hl+], a
    ld a, [wRNG2]
    ld [hl+], a
    ld a, [wMenu_selection]
    ld [hl+], a
    ld a, [wMenu_selection]
    ld [hl+], a
    ld a, [$c863]
    bit 1, a
    jr nz, jr_050_42af

    ld de, $dcec
    jr jr_050_42b2

jr_050_42af:
    ld de, $dcf4

jr_050_42b2:
    ld a, [de]
    ld [hl+], a
    inc de
    ld a, [de]
    ld [hl+], a
    inc de
    ld a, [de]
    ld [hl+], a
    inc de
    ld a, [de]
    ld [hl+], a
    inc de
    ld a, [de]
    ld [hl+], a
    inc de
    ld a, [de]
    ld [hl+], a
    ld de, $dd13
    ld a, [$c863]
    bit 1, a
    jr z, jr_050_42d0

    ld de, $dd17

jr_050_42d0:
    ld a, [de]
    ld [hl+], a
    inc de
    ld a, [de]
    ld [hl+], a
    inc de
    ld a, [de]
    ld [hl+], a
    ld a, $10
    ld [$c871], a
    xor a
    ld [$c872], a
    ld hl, $c1da
    ld a, l
    ld [$c874], a
    ld a, h
    ld [$c875], a
    ld hl, $c1ea
    ld a, l
    ld [$c86f], a
    ld a, h
    ld [$c870], a
    ld a, $ff
    ld [$c873], a

Jump_050_42fc:
    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld a, [$c86c]
    or a
    jp z, Jump_050_43a2

    ld a, [$c86e]
    cp $f0
    ret nz

    xor a
    ld [$c873], a
    ld de, $dd07
    ld a, [$c863]
    bit 1, a
    jr z, jr_050_431f

    ld de, $dd03

jr_050_431f:
    ld hl, $c1ea
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc hl
    inc hl
    ld a, [hl+]
    ld [$c1d5], a
    ld a, [hl+]
    ld [$c1d6], a
    ld a, [$c863]
    bit 1, a
    jr nz, jr_050_4340

    ld de, $dcf4
    jr jr_050_4343

jr_050_4340:
    ld de, $dcec

jr_050_4343:
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
    ld a, [hl+]
    ld [de], a
    ld de, $dd17
    ld a, [$c863]
    bit 1, a
    jr z, jr_050_4361

    ld de, $dd13

jr_050_4361:
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    ld a, [$c863]
    bit 1, a
    jr nz, jr_050_438a

    ld a, [wRNG1]
    ld [$c1ed], a
    ld a, [wRNG2]
    ld [$c1ee], a
    ld a, [wMenu_selection]
    ld [$c1ef], a
    ld a, [wMenu_selection]
    ld [$c1d5], a
    jr jr_050_43a2

jr_050_438a:
    ld a, [$c1ed]
    ld [wRNG1], a
    ld a, [$c1ee]
    ld [wRNG2], a
    ld a, [wMenu_selection]
    ld [$c1f0], a
    ld a, [wMenu_selection]
    ld [$c1d6], a

Jump_050_43a2:
jr_050_43a2:
    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld hl, $5605
    rst $10
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call SetBtl_79ae
    call ClearTileBuffer
    xor a
    ld [wBattleAttackerIdx], a
    xor a
    ld [$c8c7], a
    xor a
    ld [wEventStateMachineIndex], a
    ld hl, $d9ec
    inc [hl]
    ret


    ld a, [$d9f5]
    rst $00
    ret nc

    ld b, e
    ld de, $2144
    push af
    reti


    inc [hl]
    ld a, [$db74]
    ld b, a
    ld c, $00
    ld hl, $dd13
    ld a, [$c863]
    bit 1, a
    jr z, jr_050_43ed

    ld a, [$db75]
    ld b, a
    ld c, $04
    ld hl, $dd17

jr_050_43ed:
    ld a, c
    ld [$dd72], a
    ld a, b
    ld [$dd73], a

jr_050_43f5:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_050_43ff

    ld [hl], $01
    jr jr_050_4401

jr_050_43ff:
    ld [hl], $ff

jr_050_4401:
    inc hl
    inc c
    dec b
    jr nz, jr_050_43f5

    ld a, $ff
    ld [$db77], a
    ld a, $ff
    ld [$db78], a
    ret


    ld a, $04
    ld [wEventStateMachineIndex], a
    xor a
    ld [$d9f5], a
    ret


    ld a, [$d9f5]
    rst $00
    dec hl
    ld b, h
    ld a, [hl-]
    ld b, h
    ld l, [hl]
    ld b, h
    or b
    ld b, h
    ld l, a
    ld b, l
    ld d, c
    ld b, a
    ld a, $00
    ld [wEventStateMachineIndex], a
    ret


    ld hl, $5506
    rst $10
    ld hl, $d9f5
    inc [hl]
    ret


    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ld a, $00
    ld [wEventStateMachineIndex], a
    ld de, $6ed2
    call LoadPaletteFromDE
    ret


    ld de, $6f1a
    call LoadPaletteFromDE
    call ClearBattleTurnFlag
    ld de, $44aa
    ld a, [$d9fc]
    set 7, a
    ld [wOPTN_and_Item_selection], a
    call CalcBattleTableIndex
    call ClearTileBuffer
    ld hl, $d9f5
    inc [hl]
    ret


    ld de, $44aa
    ld hl, wOPTN_and_Item_selection
    ld b, $02
    call BtlFunc_77f7
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_050_4487

    ld a, $01
    ld [wEventStateMachineIndex], a
    jr jr_050_44a9

jr_050_4487:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_050_44a9

    ld a, [wOPTN_and_Item_selection]
    res 7, a
    ld [$d9fc], a
    ld a, $59
    call PlaySoundEffect
    ld hl, $d9f5
    inc [hl]
    ld a, [$db61]
    ld [$c8dd], a
    call RefreshBattleGraphics

Jump_050_44a9:
jr_050_44a9:
    ret


    pop bc
    ld bc, $0201
    rst $38
    rst $38

Jump_050_44b0:
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ld hl, $cac2
    ld a, [$c8dd]
    call SaveBtl_5b07
    jr c, jr_050_453c

    ld a, [$c8dd]
    call GetCurrentMonsterPtr
    ld e, l
    ld d, h
    ld hl, $96c0
    call SaveBtl_7700
    ld de, $74a3
    ld a, [wOPTN_and_Item_selection]
    cp $81
    call z, LoadPaletteFromDE
    ld de, $6f60
    call LoadPaletteFromDE
    ld a, [$db73]
    cp $02
    call z, LoadBtl_4550
    ld a, [$d9fc]
    or a
    jr z, jr_050_4507

    ld a, [$c8dd]
    and $03
    or a
    jr z, jr_050_4511

    cp $01
    jr z, jr_050_451b

    ld a, $04
    ld [$da01], a
    ld a, [$da00]
    jr jr_050_4523

jr_050_4507:
    ld a, $01
    ld [$da01], a
    ld a, [$d9fd]
    jr jr_050_4523

jr_050_4511:
    ld a, $02
    ld [$da01], a
    ld a, [$d9fe]
    jr jr_050_4523

jr_050_451b:
    ld a, $03
    ld [$da01], a
    ld a, [$d9ff]

jr_050_4523:
    set 7, a
    ld [wPLAN_selection], a
    call ClearBattleTurnFlag
    ld de, $4715
    ld a, [wPLAN_selection]
    call CalcBattleTableIndex
    call ClearTileBuffer
    ld hl, $d9f5
    inc [hl]
    ret


jr_050_453c:
    ld a, [$c8dd]
    inc a
    ld [$c8dd], a
    and $03
    cp $03
    jp c, Jump_050_44b0

    ld hl, $d9f5
    inc [hl]
    inc [hl]
    ret


LoadBtl_4550:
    ld a, [$c86c]
    or a
    ret nz

    ld hl, $0202
    call AdjustBattlePointerHL
    ld de, $4567
    ld b, $08

jr_050_4560:
    ld a, [de]
    ld [hl+], a
    inc de
    dec b
    jr nz, jr_050_4560

    ret


    adc a
    sub b
    ldh [$d6], a
    db $e3
    ldh [$d6], a
    sbc b
    ld de, $4715
    ld hl, wPLAN_selection
    ld b, $04
    call BtlFunc_77f7
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_050_45f5

jr_050_4581:
    ld hl, $5508
    rst $10
    ld a, [wOPTN_and_Item_selection]
    cp $80
    jr z, jr_050_45d6

    ld a, [$c8dd]
    ld hl, $c1c0
    cp [hl]
    jr z, jr_050_45d6

    and $03
    or a
    jr z, jr_050_45d6

    ld a, [$c8dd]
    dec a
    ld [$c8dd], a
    call SaveBtl_5b07
    jr c, jr_050_4581

    ld a, [$c8dd]
    ld hl, $dd13
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $01
    jr nz, jr_050_4581

    ld a, $00
    ld [hl], a
    ld a, [$c8dd]
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $ff
    ld [hl+], a
    ld [hl], a
    ld hl, $d9f5
    dec [hl]
    xor a
    ld [wPLAN_selection], a
    jp Jump_050_4714


jr_050_45d6:
    call LoadBtl_4f6e
    ld hl, $d9f5
    dec [hl]
    dec [hl]
    dec [hl]
    jp Jump_050_4714


    ld a, $00
    ld [$d9f5], a
    ld a, $01
    ld [wEventStateMachineIndex], a
    call RefreshBattleGraphics
    jp Jump_050_40ed


    jp Jump_050_4714


jr_050_45f5:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_050_4714

    ld a, $59
    call PlaySoundEffect
    ld a, [$da01]
    ld hl, $d9fc
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wPLAN_selection]
    res 7, a
    ld [hl], a
    cp $03
    jp z, Jump_050_471f

    ld a, [wOPTN_and_Item_selection]
    cp $80
    jr z, jr_050_466d

LoadBtl_4620:
Jump_050_4620:
    ld a, [$c8dd]
    ld de, $dd13
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, $01
    ld [de], a
    ld a, [$c8dd]
    ld hl, $dd03
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wPLAN_selection]
    ld [hl], a
    res 7, [hl]
    ld a, [hl]
    call CmpBtl_473d
    ld a, [$c8dd]
    inc a
    ld [$c8dd], a
    push af
    ld a, [$c863]
    bit 1, a
    jr nz, jr_050_4659

    ld hl, $db74
    jr jr_050_465c

jr_050_4659:
    ld hl, $db75

jr_050_465c:
    pop af
    and $03
    cp [hl]
    jr z, jr_050_46c6

    ld hl, $d9f5
    dec [hl]
    xor a
    ld [wPLAN_selection], a
    jp Jump_050_4714


jr_050_466d:
    ld a, [wBattleAttackerIdx]
    ld b, a
    ld c, $00
    ld a, [$c863]
    bit 1, a
    jr z, jr_050_467c

    ld c, $04

jr_050_467c:
    ld a, c
    call GetMonsterSlotInfo
    jr c, jr_050_4699

    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    bit 4, [hl]
    jr z, jr_050_469c

    ld a, c
    ld hl, $dd13
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $01

jr_050_4699:
    inc c
    jr jr_050_467c

jr_050_469c:
    ld a, c
    ld hl, $dd13
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $00
    jr nz, jr_050_46c2

    ld a, $01
    ld [hl], a
    ld a, c
    ld hl, $dd03
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wPLAN_selection]
    res 7, a
    ld [hl], a
    ld a, [hl]
    call CmpBtl_473d

jr_050_46c2:
    inc c
    dec b
    jr nz, jr_050_467c

SetBtl_46c6:
jr_050_46c6:
    ld hl, $d9f5
    inc [hl]
    ld bc, $0400
    ld a, [$c863]
    bit 1, a
    jr z, jr_050_46d6

    ld c, $04

jr_050_46d6:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_050_4701

    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    bit 4, [hl]
    jr nz, jr_050_46fe

    ld de, $0003
    add hl, de
    ld a, [hl+]
    and $3f
    jr nz, jr_050_46fe

    bit 2, [hl]
    jr nz, jr_050_46fe

    inc hl
    ld a, [hl]
    and $c0
    jr nz, jr_050_46fe

    bit 4, [hl]
    jr z, jr_050_4701

jr_050_46fe:
    call LoadBtl_4707

jr_050_4701:
    inc c
    dec b
    jr nz, jr_050_46d6

    jr jr_050_4714

LoadBtl_4707:
    ld a, c
    ld hl, $dd13
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $01
    ret


Jump_050_4714:
jr_050_4714:
    ret


    ld b, c
    ld bc, $0181
    pop bc
    ld bc, $0201
    rst $38
    rst $38

Jump_050_471f:
    call LoadBtl_5c2f
    jp z, Jump_050_4620

    ld a, $04
    ld [wMenu_selection], a
    xor a
    ld [$d9f7], a
    call LoadBtl_47be
    ld a, [wBattleAttackerIdx]
    cp $01
    ret z

    ld a, $01
    ld [$c1c1], a
    ret


CmpBtl_473d:
    cp $03
    jr z, jr_050_4750

    push af
    ld hl, $c876
    ld a, [$c8dd]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    pop af
    ld [hl], a

jr_050_4750:
    ret


    call LoadBtl_4764
    call ClearSpriteBuffer
    ld hl, wEventStateMachineIndex
    inc [hl]
    ld a, $ff
    ld [$db77], a
    ld [$db78], a
    ret


LoadBtl_4764:
    ld a, [$c86c]
    or a
    jr z, jr_050_4775

    ld a, [$c863]
    bit 1, a
    jr z, jr_050_4775

    ld c, $04
    jr jr_050_4777

jr_050_4775:
    ld c, $00

jr_050_4777:
    ld b, $03

jr_050_4779:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_050_478f

    ld a, c
    ld hl, $dd13
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    or a
    jr nz, jr_050_478f

    ld [hl], $01

jr_050_478f:
    inc c
    dec b
    jr nz, jr_050_4779

    ret


    ld a, [$d9f7]
    rst $00
    cp [hl]
    ld b, a
    ld d, $48
    ld e, [hl]
    ld c, b
    xor h
    ld c, c
    inc l
    ld c, d
    sub $4c
    inc hl
    ld c, l
    call $184d
    ld c, [hl]
    adc d
    ld c, [hl]
    sbc b
    ld c, [hl]
    xor e
    ld c, [hl]

jr_050_47b0:
    ld hl, $c8dd
    inc [hl]
    ld a, [$c8dd]
    and $03
    cp $03
    jp z, Jump_050_4f36

LoadBtl_47be:
    ld a, [$c8dd]
    call GetMonsterSlotInfo
    jr c, jr_050_47b0

    ld a, [$c8dd]
    ld hl, $db06
    call HL_AddA_x8
    bit 2, [hl]
    jr nz, jr_050_47b0

    inc hl
    bit 4, [hl]
    jr nz, jr_050_47b0

    ld hl, $5507
    rst $10
    ld hl, $5506
    rst $10
    xor a
    ld hl, $c8de
    ld [hl+], a
    ld [hl+], a
    ld [hl], a
    ld [$dd72], a
    ld a, [$c8dd]
    ld hl, $c1cd
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    bit 2, [hl]
    jr z, jr_050_47ff

    ld a, $01
    ld [$c8e0], a

jr_050_47ff:
    ld a, [hl]
    and $03
    ld [$c8df], a
    ld a, [hl]
    swap a
    and $03
    ld [$c8de], a
    ld hl, $d9f7
    inc [hl]
    xor a
    ld [$c1c1], a
    ret


Jump_050_4816:
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ld a, [$c1c1]
    or a
    jr nz, jr_050_4836

    ld hl, $cac2
    ld a, [$c8dd]
    call GetCurrentMonsterPtr
    ld e, l
    ld d, h
    ld hl, $96c0
    call SaveBtl_7700

jr_050_4836:
    ld de, $6f49
    ld a, [wOPTN_and_Item_selection]
    call LoadPaletteFromDE
    ld de, $74ba
    call LoadPaletteFromDE
    call ClearBattleTurnFlag
    ld de, $496d
    ld a, [$c8de]
    set 7, a
    ld [$c8de], a
    call CalcBattleTableIndex
    call ClearTileBuffer
    ld hl, $d9f7
    inc [hl]
    ret


    ld de, $496d
    ld hl, $c8de
    ld b, $03
    call BtlFunc_77f7
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_050_48d5

jr_050_4870:
    ld a, [wOPTN_and_Item_selection]
    cp $80
    jr nz, jr_050_48b7

    ld a, [$c8dd]
    and $03
    or a
    jr z, jr_050_48b7

    ld a, [$c8dd]
    dec a
    ld [$c8dd], a
    call SaveBtl_5b07
    jr c, jr_050_4870

    ld a, [$c8dd]
    ld hl, $db06
    call HL_AddA_x8
    bit 2, [hl]
    jr nz, jr_050_4870

    inc hl
    bit 4, [hl]
    jr nz, jr_050_4870

    ld a, [$c8dd]
    ld hl, $dd13
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $00
    ld [hl], a
    xor a
    ld [$d9f7], a
    call LoadBtl_4f6e
    call LoadBtl_47be
    ret


jr_050_48b7:
    ld hl, $5506
    rst $10
    ld a, $81
    ld [wMenu_selection], a
    ld a, $03
    ld [$d9f5], a
    ld a, [wPLAN_selection]
    res 7, a
    ld [wPLAN_selection], a
    xor a
    ld [$d9f7], a
    jp Jump_050_44b0


    ret


jr_050_48d5:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_050_496c

    ld a, $59
    call PlaySoundEffect
    ld a, [$c8de]
    and $03
    swap a
    ld b, a
    ld a, [$c8dd]
    ld hl, $c1cd
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    and $0f
    or b
    ld [hl], a
    ld a, [$c8de]
    cp $81
    jr z, jr_050_4937

    cp $80
    jr z, jr_050_4918

    ld b, $8d
    ld a, [$c8dd]
    ld c, a

jr_050_490c:
    call CallBtl_4f80
    call GetBattleModeData
    ld a, $0b
    ld [$d9f7], a
    ret


jr_050_4918:
    ld a, $3a
    ld [$db8a], a
    ld a, [$c8dd]
    and $04
    xor $04
    call SaveBtl_4fa4
    ld a, b
    ld b, $3a
    cp $01
    jr z, jr_050_490c

    call LoadBtl_4f86
    ld a, $07
    ld [$d9f7], a
    ret


jr_050_4937:
    call LoadBtl_4975
    ld a, [wBattlePostFlag]
    or a
    jr z, jr_050_4945

    ld hl, $d9f7
    inc [hl]
    ret


jr_050_4945:
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ld hl, $0202
    ld a, $09
    ld [$d9f7], a
    ld a, l
    ld [$c822], a
    ld a, h
    ld [$c823], a
    ld hl, $4c00
    rst $10
    ld de, $2e07
    call LoadPaletteFromDE
    call ClearTileBuffer
    ret


Jump_050_496c:
    ret


    add c
    ld bc, $01c1
    ld bc, $ff02
    rst $38

LoadBtl_4975:
    ld a, [$c8dd]
    ld hl, $dc64
    swap a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    xor a
    ld [wBattlePostFlag], a
    ld bc, $0800

jr_050_498a:
    ld a, [hl+]
    or a
    jr z, jr_050_49a7

    ld a, [hl]
    cp $37
    jr z, jr_050_49a2

    cp $38
    jr z, jr_050_49a2

    cp $7e
    jr z, jr_050_49a2

    ld a, [wBattlePostFlag]
    inc a
    ld [wBattlePostFlag], a

jr_050_49a2:
    inc hl
    inc c
    dec b
    jr nz, jr_050_498a

jr_050_49a7:
    ld a, c
    ld [$d9f6], a
    ret


    call LoadBtl_49d8
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ld de, $74f4
    call LoadPaletteFromDE
    call ClearBattleTurnFlag
    ld de, $4cca
    ld b, $04
    ld a, [$d9f6]
    ld c, a
    ld hl, $c8df
    call ReadBtl_78e9
    call ClearTileBuffer
    ld hl, $d9f7
    inc [hl]
    ret


LoadBtl_49d8:
    ld a, [$c8dd]
    swap a
    ld de, $dc65
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [$c8e0]
    add a
    add a
    add a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld hl, $88c0
    call SaveBtl_49fe
    call SaveBtl_49fe
    call SaveBtl_49fe

SaveBtl_49fe:
    push de
    push hl
    ld a, [de]
    cp $ff
    jr nz, jr_050_4a11

    ld a, $00
    ld [$c823], a
    ld a, $08
    ld [$c822], a
    jr jr_050_4a19

jr_050_4a11:
    ld [$c823], a
    ld a, $06
    ld [$c822], a

jr_050_4a19:
    ld de, WaitSTATForOverlayB
    call LoadBtl_76c7
    pop hl
    ld a, l
    add $90
    ld l, a
    ld a, h
    adc $00
    ld h, a
    pop de
    inc de
    inc de
    ret


    ld de, $4cca
    ld hl, $c8df
    ld a, [$d9f6]
    ld c, a
    ld b, $04
    inc hl
    ld a, [hl-]
    push af
    call LoadBtl_776e
    pop af
    ld hl, $c8e0
    cp [hl]
    jr z, jr_050_4a48

    call LoadBtl_49d8

jr_050_4a48:
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_050_4a65

    ld a, $01
    ld [$d9f7], a
    jp Jump_050_4816


jr_050_4a57:
    ld hl, $0302
    call SaveBtl_4ca4
    ret


jr_050_4a5e:
    ld hl, $0402
    call SaveBtl_4ca4
    ret


jr_050_4a65:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_050_4b97

    ld a, $59
    call PlaySoundEffect
    ld hl, $c8df
    res 7, [hl]
    ld a, [$c8e0]
    add a
    add a
    add [hl]
    ld [$db54], a
    add a
    ld hl, $dc65
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$c8dd]
    swap a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld b, [hl]
    call LoadBtl_4b98
    jr z, jr_050_4a57

    call SaveBtl_4ba4
    jr c, jr_050_4a5e

    call LoadBtl_4f86
; S48: WORKING-ID COMMIT / de-alias point ($50:~$4A55). Sets record-index ($db4c),
; working id ($db8a) and selected-skill ($db4f) from the chosen skill [hl], and the
; action is queued at $dcec. S45's AliasCommit replaces the `call` above to force the
; queued value to $00 (Blaze) for ids $DE/$DF (stash real id in $db86). The proper
; S2d path does NOT templatize -- it lets the real id flow here and relies on the
; consumption forks (BATTLE_SKILL_SYSTEM.md §12).
    ld a, [hl]
    ld [$db4c], a
    ld [$db8a], a
    ld [$db4f], a
    ld a, [$c8dd]
    ld hl, $c1cd
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    and $f0
    ld b, a
    ld a, [$db54]
    or b
    ld [hl], a
    xor a
    ld [$db4d], a
    ld a, $02
    ld [$db4e], a
    ld hl, $5400
    rst $10
    call RefreshBattleScreen
    call LoadBtl_4bd1
    ret c

    ld a, [$db4c]
    bit 0, a
    jp z, Jump_050_4b6b

    bit 4, a
    jr z, jr_050_4af0

    ld a, $07
    ld [$d9f7], a
    ld a, [$c8dd]
    and $04
    xor $04
    jr jr_050_4afe

jr_050_4af0:
    bit 6, a
    jr nz, jr_050_4b54

    ld a, $05
    ld [$d9f7], a
    ld a, [$c8dd]
    and $04

jr_050_4afe:
    call SaveBtl_4fa4
    ld a, b
    cp $01
    ret nz

    ld a, [$db8a]
    cp $30
    jr z, jr_050_4b20

    cp $31
    jr z, jr_050_4b20

    cp $88
    jr z, jr_050_4b20

    call LoadBtl_4f95
    call GetBattleModeData
    ld a, $0b
    ld [$d9f7], a
    ret


jr_050_4b20:
    call LoadBtl_4b26
    jr z, jr_050_4b4d

    ret


LoadBtl_4b26:
    ld a, [$c863]
    bit 1, a
    jr z, jr_050_4b34

    ld c, $04
    ld a, [$db75]
    jr jr_050_4b39

jr_050_4b34:
    ld c, $00
    ld a, [$db74]

jr_050_4b39:
    ld b, a
    ld d, $00

jr_050_4b3c:
    ld a, c
    call CheckMonsterSlot
    jr nc, jr_050_4b44

    jr z, jr_050_4b45

jr_050_4b44:
    inc d

jr_050_4b45:
    inc c
    dec b
    jr nz, jr_050_4b3c

    ld a, d
    cp $01
    ret


SetBtl_4b4d:
jr_050_4b4d:
    ld hl, $fb00
    call SaveBtl_4ca4
    ret


jr_050_4b54:
    ld a, [$c8dd]
    ld c, a
    call LoadBtl_4f95
    call GetBattleModeData
    ld a, $0b
    ld [$d9f7], a
    call RefreshBattleScreen
    ld hl, $5506
    rst $10
    ret


Jump_050_4b6b:
    call GetBattleModeData
    ld a, $0b
    ld [$d9f7], a
    call RefreshBattleScreen
    ld hl, $5506
    rst $10
    ld a, [$c8dd]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$db4c]
    ld b, a
    ld a, [$c8dd]
    and $04
    bit 4, b
    jr z, jr_050_4b96

    xor $04

jr_050_4b96:
    ld [hl], a

Jump_050_4b97:
    ret


LoadBtl_4b98:
    ld a, b
    cp $37
    jr z, jr_050_4ba3

    cp $38
    jr z, jr_050_4ba3

    cp $7e

jr_050_4ba3:
    ret


SaveBtl_4ba4:
    push bc
    ld a, b
    ld [$db4c], a
    xor a
    ld [$db4d], a
    ld a, $04
    ld [$db4e], a
    ld hl, $5400
    rst $10
    ld a, [$db4c]
    ld c, a
    ld b, $00
    ld a, [$c8dd]
    ld hl, wBattleMP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call CmpHLvsBC
    pop bc
    ret


LoadBtl_4bd1:
    ld a, [$db4f]
    cp $14
    jr z, jr_050_4c21

    cp $80
    jr z, jr_050_4c21

    cp $24
    jr z, jr_050_4c34

    cp $26
    jr z, jr_050_4c34

    cp $2a
    jr z, jr_050_4c34

    cp $32
    jr z, jr_050_4c2a

    cp $89
    jr z, jr_050_4c2a

    cp $8b
    jr z, jr_050_4c34

    cp $8f
    jr z, jr_050_4c34

    cp $95
    jr z, jr_050_4c2a

    cp $96
    jr z, jr_050_4c2a

    cp $39
    jr z, jr_050_4c3b

    cp $3f
    jr z, jr_050_4c72

    cp $51
    jr z, jr_050_4c40

    cp $52
    jr z, jr_050_4c40

    cp $53
    jr z, jr_050_4c40

    cp $83
    jr z, jr_050_4c64

    cp $88
    ret nc

    cp $84
    jr nc, jr_050_4c6d

    xor a
    ret


jr_050_4c21:
    ld a, [$c8dd]
    and $04
    xor $04
    jr jr_050_4c96

jr_050_4c2a:
    call LoadBtl_4b26
    jr nz, jr_050_4c34

    call SetBtl_4b4d
    pop hl
    ret


jr_050_4c34:
    ld a, [$c8dd]
    and $04
    jr jr_050_4c96

jr_050_4c3b:
    ld a, [$c8dd]
    jr jr_050_4c96

jr_050_4c40:
    ld a, [wBattleAttackerIdx]
    ld b, a
    ld a, [$db8a]
    ld c, a
    push bc
    ld a, [$c8dd]
    ld [wBattleAttackerIdx], a
    ld a, [$db4f]
    ld [$db8a], a
    ld hl, $5805
    rst $10
    pop bc
    ld a, b
    ld [wBattleAttackerIdx], a
    ld a, c
    ld [$db8a], a
    jr jr_050_4c9a

jr_050_4c64:
    ld a, [$c8dd]
    and $04
    xor $04
    jr jr_050_4c96

jr_050_4c6d:
    ld a, [$c8dd]
    jr jr_050_4c96

jr_050_4c72:
    ld a, [wBattleAttackerIdx]
    ld b, a
    ld a, [$db8a]
    ld c, a
    push bc
    ld a, [$c8dd]
    ld [wBattleAttackerIdx], a
    ld a, [$db4f]
    ld [$db8a], a
    ld hl, $5804
    rst $10
    pop bc
    ld a, b
    ld [wBattleAttackerIdx], a
    ld a, c
    ld [$db8a], a
    jr jr_050_4c9a

jr_050_4c96:
    ld c, a
    call LoadBtl_4f95

jr_050_4c9a:
    call GetBattleModeData
    ld a, $0b
    ld [$d9f7], a
    scf
    ret


SaveBtl_4ca4:
    push hl
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    pop hl
    ld a, $03
    ld [$d9f7], a
    ld a, l
    ld [$c822], a
    ld a, h
    ld [$c823], a
    ld hl, $4c00
    rst $10
    ld de, $2e07
    call LoadPaletteFromDE
    call ClearTileBuffer
    ret


    ld a, [hl+]
    ld [bc], a
    ld b, c
    ld bc, $0181
    pop bc
    ld bc, $0201
    rst $38
    rst $38
    ld a, [$db8a]
    ld [$dd76], a
    ld a, a
    ld [$c1c2], a
    ld hl, $550b
    rst $10
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ld de, $70c9
    call LoadPaletteFromDE
    call LoadBtl_5bd7
    call ClearBattleTurnFlag
    ld de, $5339
    ld a, [$c863]
    rlca
    and $04
    ld b, a
    call CheckMonsterSlot
    jr nc, jr_050_4d10

    inc b
    ld a, b
    call CheckMonsterSlot
    jr nc, jr_050_4d10

    inc b

jr_050_4d10:
    res 2, b
    set 7, b
    ld a, b
    ld [$dd72], a
    call CalcBattleTableIndex
    call ClearTileBuffer
    ld hl, $d9f7
    inc [hl]
    ret


    ld de, $5339
    ld hl, $dd72
    ld a, [$c8dd]
    cp $04
    jr c, jr_050_4d35

    ld a, [$db75]
    jr jr_050_4d38

jr_050_4d35:
    ld a, [$db74]

jr_050_4d38:
    ld b, a
    ld a, [$c863]
    rlca
    and $04
    ld c, a
    call BtlFunc_5b7a
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_050_4d51

    ld a, $03
    ld [$d9f7], a
    jr jr_050_4d9b

jr_050_4d51:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_050_4d9b

    ld a, [$dd72]
    res 7, a
    ld c, a
    ld a, [$c863]
    bit 1, a
    jr z, jr_050_4d68

    set 2, c

jr_050_4d68:
    ld a, c
    call CheckMonsterSlot
    jr nc, jr_050_4d84

    ld a, [$c8dd]
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $30
    jr z, jr_050_4d84

    cp $31
    jr nz, jr_050_4d9c

jr_050_4d84:
    call LoadBtl_4f95
    ld a, $59
    call PlaySoundEffect
    call GetBattleModeData
    ld a, $0b
    ld [$d9f7], a
    call RefreshBattleScreen
    ld hl, $5506
    rst $10

Jump_050_4d9b:
jr_050_4d9b:
    ret


Jump_050_4d9c:
jr_050_4d9c:
    ld a, c
    ld hl, $c180
    ld [$db50], a
    call CheckSlotUnder3
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ld hl, $fa00
    ld a, $0a
    ld [$d9f7], a
    ld a, l
    ld [$c822], a
    ld a, h
    ld [$c823], a
    ld hl, $4c00
    rst $10
    ld de, $2e07
    call LoadPaletteFromDE
    call ClearTileBuffer
    ret


    ld a, [$db8a]
    ld [$dd76], a
    ld a, a
    ld [$c1c2], a
    call LoadBtl_53dc
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ld de, $7113
    call LoadPaletteFromDE
    call ClearBattleTurnFlag
    ld de, $5664
    ld a, [$c863]
    rlca
    and $04
    xor $04
    ld b, a
    call CheckMonsterSlot
    jr nc, jr_050_4e05

    inc b
    ld a, b
    call CheckMonsterSlot
    jr nc, jr_050_4e05

    inc b

jr_050_4e05:
    res 2, b
    set 7, b
    ld a, b
    ld [$dd72], a
    call CalcBattleTableIndex
    call ClearTileBuffer
    ld hl, $d9f7
    inc [hl]
    ret


    ld de, $5664
    ld hl, $dd72
    ld a, [$c8dd]
    cp $04
    jr c, jr_050_4e2a

    ld a, [$db74]
    jr jr_050_4e2d

jr_050_4e2a:
    ld a, [$db75]

jr_050_4e2d:
    ld b, a
    ld a, [$c863]
    rlca
    and $04
    xor $04
    ld c, a
    call BtlFunc_5b7a
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_050_4e54

    ld a, [$c8de]
    cp $80
    ld a, $01
    jr z, jr_050_4e4c

    ld a, $03

jr_050_4e4c:
    ld [$d9f7], a
    call RefreshBattleScreen
    jr jr_050_4e89

jr_050_4e54:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_050_4e89

    ld a, [$dd72]
    res 7, a
    ld c, a
    ld a, [$c863]
    bit 1, a
    jr nz, jr_050_4e6b

    set 2, c

jr_050_4e6b:
    ld a, c
    call CheckMonsterSlot
    jp c, Jump_050_4d9c

    call LoadBtl_4f95
    ld a, $59
    call PlaySoundEffect
    call GetBattleModeData
    ld a, $0b
    ld [$d9f7], a
    call RefreshBattleScreen
    ld hl, $5506
    rst $10

Jump_050_4e89:
jr_050_4e89:
    ret


    ld a, [$c825]
    or a
    ret nz

    call ClearSpriteBuffer
    ld a, $01
    ld [$d9f7], a
    ret


    ld a, [$c825]
    or a
    ret nz

    call ClearSpriteBuffer
    ld a, [$c8de]
    and $01
    add a
    inc a
    ld [$d9f7], a
    ret


    ld a, [wOPTN_and_Item_selection]
    cp $80
    jr z, jr_050_4ed7

    ld a, $81
    ld [wMenu_selection], a
    ld a, $04
    ld [$d9f5], a
    call LoadBtl_4620
    call RefreshBattleScreen
    ld hl, $5506
    rst $10
    jp Jump_050_4f61


jr_050_4ec9:
    ld a, [$c8dd]
    ld hl, $dd13
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $02

jr_050_4ed7:
    ld a, [wBattleAttackerIdx]
    cp $01
    jr z, jr_050_4f36

    ld b, a
    ld a, [$c8dd]
    and $03
    cp b
    jr z, jr_050_4f36

    ld hl, $c8dd
    inc [hl]
    ld a, [hl]
    and $03
    cp $03
    jr z, jr_050_4f36

    ld a, [hl]
    call CheckMonsterSlot
    jr c, jr_050_4ed7

    ld a, [hl]
    call GetMonsterSlotInfo
    jr c, jr_050_4f16

    ld a, [$c8dd]
    ld hl, $db06
    call HL_AddA_x8
    bit 2, [hl]
    jr nz, jr_050_4ec9

    inc hl
    bit 4, [hl]
    jr nz, jr_050_4ec9

    xor a
    ld [$d9f7], a
    jr jr_050_4f61

jr_050_4f16:
    ld a, [hl]
    push bc
    ld b, a
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $3a
    ld [hl+], a
    ld a, b
    ld [hl], a
    pop bc
    ld hl, $dd13
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $01
    jr jr_050_4ed7

Jump_050_4f36:
jr_050_4f36:
    ld a, $81
    ld [wMenu_selection], a
    ld a, $04
    ld [$d9f5], a
    call SetBtl_46c6
    jr jr_050_4f61

GetBattleModeData:
    ld a, [$c8dd]
    ld hl, $dd13
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $01
    ld a, [$c8dd]
    ld hl, $dd03
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $03

Jump_050_4f61:
jr_050_4f61:
    ret


    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ret


    ret


    ret


LoadBtl_4f6e:
    ld a, [$c8dd]
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $ff
    ld [hl+], a
    ld [hl], a
    ret


CallBtl_4f80:
    call LoadBtl_4f86
    inc hl
    ld [hl], c
    ret


; [S45] Action-queue WRITER: stores b -> $dcec[$c8dd*2]. The S2 skill-alias
; framework hooks the player-commit caller (line ~1864) with AliasCommit to
; templatize a custom id ($DE/$DF) to Blaze here. See BATTLE_SKILL_SYSTEM.md.
LoadBtl_4f86:
    ld a, [$c8dd]
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], b
    ret


LoadBtl_4f95:
    ld a, [$c8dd]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], c
    ret


SaveBtl_4fa4:
    push de
    ld c, a
    ld b, $03
    ld de, $0000

jr_050_4fab:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_050_4fb3

    inc d
    ld e, c

jr_050_4fb3:
    inc c
    dec b
    jr nz, jr_050_4fab

    ld b, d
    ld c, e
    pop de
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, [$d9f5]
    rst $00
    ld [c], a
    ld c, a
    ld b, b
    ld d, b
    push bc
    ld d, b
    call z, $0751
    ld d, d
    adc [hl]
    ld d, d
    rst $10
    ld d, d
    ld [hl], d
    ld d, e
    ld [bc], a
    ld d, [hl]
    sub a
    ld d, [hl]
    xor h
    ld d, [hl]
    cp d
    ld d, [hl]
    bit 2, [hl]
    reti


    ld d, [hl]
    db $eb
    ld d, [hl]
    ld a, [$db73]
    cp $02
    jr z, jr_050_503a

    ld bc, $1400

jr_050_4fec:
    ld hl, wInventory
    ld a, c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $ff
    jr z, jr_050_5020

    or a
    jr z, jr_050_5020

    push bc
    ld a, [hl]
    add $af
    ld a, a
    ld [$db4c], a
    ld a, $00
    ld [$db4d], a
    ld a, $0a
    ld [$db4e], a
    ld hl, $5400
    rst $10
    ld a, [$db4c]
    cp $01
    pop bc
    jr nz, jr_050_5035

    inc c
    dec b
    jr nz, jr_050_4fec

jr_050_5020:
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ld hl, $f300
    call LoadBtl_51aa
    ld a, $0b
    ld [$d9f5], a
    ret


jr_050_5035:
    ld hl, $d9f5
    inc [hl]
    ret


jr_050_503a:
    ld a, $f4
    call SaveBtl_5ae5
    ret


    call SetBtl_50ac
    call SetBtl_506f
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ld de, $6fce
    call LoadPaletteFromDE
    call ClearBattleTurnFlag
    ld de, $51c0
    ld b, $04
    ld a, [$d9f6]
    ld c, a
    ld hl, wOPTN_and_Item_selection
    call ReadBtl_78e9
    call ClearTileBuffer
    ld hl, $d9f5
    inc [hl]
    ret


SetBtl_506f:
    ld de, wInventory
    ld a, [wPLAN_selection]
    add a
    add a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld hl, $88c0
    call SaveBtl_5089
    call SaveBtl_5089
    call SaveBtl_5089

SaveBtl_5089:
    push de
    push hl
    ld a, [de]
    cp $ff
    jr nz, jr_050_5092

    ld a, $00

jr_050_5092:
    ld [$c823], a
    ld a, $08
    ld [$c822], a
    ld de, WaitSTATForOverlayB
    call LoadBtl_76c7
    pop hl
    ld a, l
    add $90
    ld l, a
    ld a, h
    adc $00
    ld h, a
    pop de
    inc de
    ret


SetBtl_50ac:
    ld hl, wInventory
    ld b, $14
    ld c, $00

jr_050_50b3:
    ld a, [hl+]
    cp $00
    jr z, jr_050_50c0

    cp $ff
    jr z, jr_050_50c0

    inc c
    dec b
    jr nz, jr_050_50b3

jr_050_50c0:
    ld a, c
    ld [$d9f6], a
    ret


    ld de, $51c0
    ld hl, wOPTN_and_Item_selection
    ld a, [$d9f6]
    ld c, a
    ld b, $04
    inc hl
    ld a, [hl-]
    push af
    call LoadBtl_776e
    pop af
    ld hl, wPLAN_selection
    cp [hl]
    jr z, jr_050_50e1

    call SetBtl_506f

jr_050_50e1:
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_050_50f4

    ld hl, $5508
    rst $10
    ld a, $01
    ld [wEventStateMachineIndex], a
    jp Jump_050_517a


jr_050_50f4:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_050_517a

    ld hl, wOPTN_and_Item_selection
    res 7, [hl]
    ld a, [wPLAN_selection]
    add a
    add a
    add [hl]
    ld hl, wInventory
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $af
    add [hl]
    ld [$db4c], a
    ld hl, $5405
    rst $10
    ld a, [$db4c]
    or a
    jr z, jr_050_5199

    ld a, [$db4c]
    ld [$db77], a
    ld a, [$db4d]
    ld [$db78], a
    ld a, $59
    call PlaySoundEffect
    ld hl, $5509
    rst $10
    ld a, [$db77]
    cp $11
    jr z, jr_050_514e

    cp $12
    jr z, jr_050_515d

    cp $21
    jr z, jr_050_5169

    cp $22
    jr z, jr_050_5170

    ld hl, $d9f5
    inc [hl]
    jr jr_050_517a

jr_050_514e:
    call SetBtl_517b
    jr z, jr_050_5175

    call RefreshBattleScreen
    ld a, $07
    ld [$d9f5], a
    jr jr_050_517a

jr_050_515d:
    ld a, $04
    ld [$db77], a
    ld a, $09
    ld [$d9f5], a
    jr jr_050_517a

jr_050_5169:
    ld a, $05
    ld [$d9f5], a
    jr jr_050_517a

jr_050_5170:
    ld a, $00
    ld [$db77], a

jr_050_5175:
    ld a, $09
    ld [$d9f5], a

Jump_050_517a:
jr_050_517a:
    ret


SetBtl_517b:
    ld hl, $dd1f
    ld a, [$db75]
    ld b, a
    ld c, $00
    ld d, $04

jr_050_5186:
    ld a, [hl+]
    or a
    jr nz, jr_050_518c

    inc c
    ld e, d

jr_050_518c:
    inc d
    dec b
    jr nz, jr_050_5186

    ld a, c
    cp $01
    ret nz

    ld a, e
    ld [$db77], a
    ret


jr_050_5199:
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ld hl, $f200
    ld a, $0a
    ld [$d9f5], a

LoadBtl_51aa:
    ld a, l
    ld [$c822], a
    ld a, h
    ld [$c823], a
    ld hl, $4c00
    rst $10
    ld de, $2e07
    call LoadPaletteFromDE
    call ClearTileBuffer
    ret


    ld a, [hl+]
    ld [bc], a
    ld b, c
    ld bc, $0181
    pop bc
    ld bc, $0201
    rst $38
    rst $38
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ld de, $7045
    call LoadPaletteFromDE
    call ClearBattleTurnFlag
    ld de, $5288
    xor a
    ld [$c8dd], a
    ld a, [$c8dd]
    ld b, a
    ld a, [$db78]
    cp $c2
    jr c, jr_050_51fb

    cp $c7
    jr nc, jr_050_51fb

    ld a, $01
    ld [$c8dd], a
    ld b, $01

jr_050_51fb:
    ld a, b
    call CalcBattleTableIndex
    call ClearTileBuffer
    ld hl, $d9f5
    inc [hl]
    ret


    ld de, $5288
    ld hl, $c8dd
    ld b, $02
    call BtlFunc_77f7
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_050_5227

    ld hl, $d9f5
    dec [hl]
    ld hl, $d9f5
    dec [hl]
    ld hl, $d9f5
    dec [hl]
    jr jr_050_5287

jr_050_5227:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_050_5287

    ld a, $59
    call PlaySoundEffect
    ld hl, $550a
    rst $10
    ld a, $80
    ld [$c8de], a
    ld a, [$c8dd]
    cp $80
    jr z, jr_050_526d

    ld a, [$db78]
    cp $c2
    jr c, jr_050_524f

    cp $c7
    jr c, jr_050_525f

jr_050_524f:
    ld a, [$db77]
    and $0f
    bit 0, a
    jr z, jr_050_525f

    ld a, $07
    ld [$d9f5], a
    jr jr_050_5287

jr_050_525f:
    ld a, $04
    ld [$db77], a
    ld a, $09
    ld [$d9f5], a
    jr jr_050_5287

    jr jr_050_5287

jr_050_526d:
    ld a, [$db77]
    and $0f
    bit 0, a
    jr z, jr_050_527d

    ld a, $05
    ld [$d9f5], a
    jr jr_050_5287

jr_050_527d:
    ld a, $09
    ld [$d9f5], a
    ld a, $00
    ld [$db77], a

Jump_050_5287:
jr_050_5287:
    ret


    pop bc
    ld bc, $0201
    rst $38
    rst $38
    ld a, [$db78]
    ld [$dd76], a
    ld a, a
    ld [$c1c2], a
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ld de, $707f
    call LoadPaletteFromDE
    call LoadBtl_5bd7
    call ClearBattleTurnFlag
    ld de, $5339
    ld a, [$c863]
    rlca
    and $04
    ld b, a
    call CheckMonsterSlot
    jr nc, jr_050_52c4

    inc b
    ld a, b
    call CheckMonsterSlot
    jr nc, jr_050_52c4

    inc b

jr_050_52c4:
    res 2, b
    set 7, b
    ld a, b
    ld [$c8de], a
    call CalcBattleTableIndex
    call ClearTileBuffer
    ld hl, $d9f5
    inc [hl]
    ret


    ld de, $5339
    ld hl, $c8de
    ld a, [$db74]
    ld b, a
    ld a, [$c863]
    rlca
    and $04
    ld c, a
    call BtlFunc_5b7a
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_050_5309

    ld a, [$db77]
    and $f0
    cp $20
    jr z, jr_050_5302

    ld a, $03
    ld [$d9f5], a
    jr jr_050_5338

jr_050_5302:
    ld a, $01
    ld [$d9f5], a
    jr jr_050_5338

jr_050_5309:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_050_5338

    ld a, [$c8de]
    res 7, a
    ld c, a
    call CheckMonsterSlot
    jr nc, jr_050_5323

    ld a, [$db78]
    cp $bb
    jr nz, jr_050_5341

jr_050_5323:
    ld a, c
    ld [$db77], a
    ld a, $59
    call PlaySoundEffect
    ld hl, $d9f5
    inc [hl]
    ld hl, $d9f5
    inc [hl]
    ld hl, $d9f5
    inc [hl]

Jump_050_5338:
jr_050_5338:
    ret


    add c
    ld bc, $01c1
    ld bc, $ff02
    rst $38

jr_050_5341:
    ld a, c
    ld hl, $c180
    ld [$db50], a
    call CheckSlotUnder3
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ld hl, $fa00
    ld a, $0c
    ld [$d9f5], a
    ld a, l
    ld [$c822], a
    ld a, h
    ld [$c823], a
    ld hl, $4c00
    rst $10
    ld de, $2e07
    call LoadPaletteFromDE
    call ClearTileBuffer
    ret


    ld a, [$db78]
    ld [$dd76], a
    ld a, a
    ld [$c1c2], a
    call LoadBtl_53dc
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ld de, $7113
    call LoadPaletteFromDE
    call ClearBattleTurnFlag
    ld de, $5664
    ld a, [$c863]
    rlca
    and $04
    xor $04
    ld b, a
    call CheckMonsterSlot
    jr nc, jr_050_53aa

    inc b
    ld a, b
    call CheckMonsterSlot
    jr nc, jr_050_53aa

    inc b

jr_050_53aa:
    res 2, b
    set 7, b
    ld a, b
    ld [$c8de], a
    call CalcBattleTableIndex
    call ClearTileBuffer
    ld hl, $d9f5
    inc [hl]
    ret


LoadBtl_53bd:
    ld a, [$c863]
    rlca
    and $04
    xor $04
    ld [$dd73], a
    ret


CheckBattlePhase:
    ld a, [$dd76]
    cp $30
    jr z, jr_050_53da

    cp $31
    jr z, jr_050_53da

    cp $bb
    jr z, jr_050_53da

    scf
    ret


jr_050_53da:
    xor a
    ret


LoadBtl_53dc:
    ld a, [$c86c]
    or a
    jp nz, Jump_050_549e

    call LoadBtl_53bd
    call CheckMonsterSlot
    call c, CheckBattlePhase
    jr c, jr_050_53fe

    xor a
    ld [$db4e], a
    ld a, [$c1ca]
    cp $ff
    jr z, jr_050_5403

    call CallBtl_5530
    jr jr_050_540e

jr_050_53fe:
    call SetBtl_547e
    jr jr_050_540e

jr_050_5403:
    call SetBtl_547e
    ld a, $01
    ld [$db4e], a
    call CallBtl_5530

jr_050_540e:
    xor a
    ld [$db4e], a
    ld a, [$da02]
    cp $00
    jr nz, jr_050_541e

    call SetBtl_5485
    jr jr_050_548c

jr_050_541e:
    ld a, [$dd73]
    inc a
    ld [$dd73], a
    call CheckMonsterSlot
    call c, CheckBattlePhase
    jr c, jr_050_5439

    ld a, [$c1cb]
    cp $ff
    jr z, jr_050_543e

    call CallBtl_553d
    jr jr_050_5449

jr_050_5439:
    call SetBtl_5485
    jr jr_050_5449

jr_050_543e:
    call SetBtl_5485
    ld a, $01
    ld [$db4e], a
    call CallBtl_553d

jr_050_5449:
    xor a
    ld [$db4e], a
    ld a, [$da02]
    cp $01
    jr nz, jr_050_5456

    jr jr_050_548c

jr_050_5456:
    ld a, [$dd73]
    inc a
    ld [$dd73], a
    call CheckMonsterSlot
    call c, CheckBattlePhase
    jr c, jr_050_5470

    ld a, [$c1cc]
    cp $ff
    jr z, jr_050_5472

    call CallBtl_554a
    ret


jr_050_5470:
    jr jr_050_548c

jr_050_5472:
    call SetBtl_548c
    ld a, $01
    ld [$db4e], a
    call CallBtl_554a
    ret


SetBtl_547e:
    ld hl, $88c0
    ld b, $a0
    jr jr_050_5491

SetBtl_5485:
    ld hl, $8960
    ld b, $a0
    jr jr_050_5491

SetBtl_548c:
Jump_050_548c:
jr_050_548c:
    ld hl, $8a00
    ld b, $a0

LoadBtl_5491:
jr_050_5491:
    ld a, $ff
    call Write_gfx_tile_and_inc_HL
    xor a
    call Write_gfx_tile_and_inc_HL
    dec b
    jr nz, jr_050_5491

    ret


Jump_050_549e:
    xor a
    ld [$c1d7], a
    ld a, [$db74]
    ld [$c1d8], a
    ld a, [$c863]
    bit 1, a
    jr nz, jr_050_54ba

    ld a, $04
    ld [$c1d7], a
    ld a, [$db75]
    ld [$c1d8], a

jr_050_54ba:
    ld a, [$c1d7]
    call CheckMonsterSlot
    call c, CheckBattlePhase
    jr nc, jr_050_54ca

    call SetBtl_547e
    jr jr_050_54d9

jr_050_54ca:
    ld a, [$c1d7]
    call GetCurrentMonsterData
    ld a, [$c1d7]
    ld hl, $88c0
    call SaveBtl_5557

jr_050_54d9:
    ld a, [$c1d8]
    cp $01
    jr nz, jr_050_54e5

    call SetBtl_5485
    jr jr_050_548c

jr_050_54e5:
    ld hl, $c1d7
    inc [hl]
    ld a, [hl]
    call CheckMonsterSlot
    call c, CheckBattlePhase
    jr nc, jr_050_54f7

    call SetBtl_5485
    jr jr_050_5506

jr_050_54f7:
    ld a, [$c1d7]
    call GetCurrentMonsterData
    ld a, [$c1d7]
    ld hl, $8960
    call SaveBtl_5557

jr_050_5506:
    ld a, [$c1d8]
    cp $02
    jr nz, jr_050_5510

    jp Jump_050_548c


jr_050_5510:
    ld hl, $c1d7
    inc [hl]
    ld a, [hl]
    call CheckMonsterSlot
    call c, CheckBattlePhase
    jr nc, jr_050_5520

    jp Jump_050_548c


jr_050_5520:
    ld a, [$c1d7]
    call GetCurrentMonsterData
    ld a, [$c1d7]
    ld hl, $8a00
    call SaveBtl_5557
    ret


CallBtl_5530:
    call GetCurrentMonsterData
    ld hl, $88c0
    ld a, $00
    ld [$db4c], a
    jr jr_050_556a

CallBtl_553d:
    call GetCurrentMonsterData
    ld hl, $8960
    ld a, $01
    ld [$db4c], a
    jr jr_050_556a

CallBtl_554a:
    call GetCurrentMonsterData
    ld hl, $8a00
    ld a, $02
    ld [$db4c], a
    jr jr_050_556a

SaveBtl_5557:
    push hl
    call SaveBtl_7700
    pop hl
    ld a, l
    add $40
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld b, $30
    call LoadBtl_5491
    ret


jr_050_556a:
    push hl
    push hl
    ld a, [$db4c]
    add $04
    ld [$db50], a
    ld hl, $c180
    call CheckSlotUnder3
    pop hl
    ld a, [$c827]
    ld c, a
    ld a, [$c828]
    ld b, a
    push bc
    ld a, [$c829]
    ld c, a
    ld a, [$c82a]
    ld b, a
    push bc
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, [$db4d]
    or a
    jr nz, jr_050_55a0

    ld de, $0801
    jr jr_050_55a3

jr_050_55a0:
    ld de, WaitSTATForOverlayB

jr_050_55a3:
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld a, $02
    ld [$c822], a
    ld a, $00
    ld [$c823], a
    ld hl, $4102
    rst $10
    pop de
    pop hl
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    pop hl
    ld a, [$db4e]
    or a
    ret nz

    ld a, [$db4d]
    or a
    jr nz, jr_050_55e3

    ld a, l
    add $80
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld b, $18
    jr jr_050_55f5

jr_050_55e3:
    ld a, l
    add $80
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    add $90
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld b, $10

jr_050_55f5:
    call LoadBtl_5491
    ret


GetCurrentMonsterData:
    ld hl, $cac2
    call GetCurrentMonsterPtr
    ld e, l
    ld d, h
    ret


    ld de, $5664
    ld hl, $c8de
    ld a, [$da02]
    inc a
    ld b, a
    ld a, [$c863]
    rlca
    and $04
    xor $04
    ld c, a
    call BtlFunc_5b7a
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_050_563a

    ld a, [$db77]
    and $f0
    cp $10
    jr z, jr_050_5630

    ld a, $03
    ld [$d9f5], a
    jr jr_050_5663

jr_050_5630:
    call RefreshBattleScreen
    ld a, $01
    ld [$d9f5], a
    jr jr_050_5663

jr_050_563a:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_050_5663

    ld a, [$c8de]
    res 7, a
    add $04
    ld c, a
    call CheckMonsterSlot
    jr nc, jr_050_5656

    ld a, [$db78]
    cp $bb
    jr nz, jr_050_566c

jr_050_5656:
    ld a, c
    ld [$db77], a
    ld a, $59
    call PlaySoundEffect
    ld hl, $d9f5
    inc [hl]

Jump_050_5663:
jr_050_5663:
    ret


    add c
    ld bc, $01c1
    ld bc, $ff02
    rst $38

jr_050_566c:
    ld a, c
    ld hl, $c180
    ld [$db50], a
    call CheckSlotUnder3
    call RefreshBattleGraphics
    ld hl, $fa00
    ld a, $0d
    ld [$d9f5], a
    ld a, l
    ld [$c822], a
    ld a, h
    ld [$c823], a
    ld hl, $4c00
    rst $10
    ld de, $2e07
    call LoadPaletteFromDE
    call ClearTileBuffer
    ret


    ld hl, $dd13
    ld a, [$db74]
    ld b, a
    ld a, $01

jr_050_56a0:
    ld [hl+], a
    dec b
    jr nz, jr_050_56a0

    call ClearSpriteBuffer
    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    call ClearSpriteBuffer
    ld a, $01
    ld [$d9f5], a
    ret


    ld a, [$c825]
    or a
    ret nz

    call ClearSpriteBuffer
    xor a
    ld [wEventStateMachineIndex], a
    xor a
    ld [$d9f5], a
    ret


    ld a, [$c825]
    or a
    ret nz

    call ClearSpriteBuffer
    ld a, $05
    ld [$d9f5], a
    ret


    ld a, [$c825]
    or a
    ret nz

    call ClearSpriteBuffer
    ld a, $07
    ld [$d9f5], a
    ret


    ld hl, $5506
    rst $10

RefreshBattleScreen:
    call RefreshBattleGraphics
    ld hl, $88c0

BtlFunc_56f1:
    ld c, $02

jr_050_56f3:
    ld b, $f0

jr_050_56f5:
    ld a, $ff
    call Write_gfx_tile_and_inc_HL
    xor a
    call Write_gfx_tile_and_inc_HL
    dec b
    jr nz, jr_050_56f5

    dec c
    jr nz, jr_050_56f3

    call ClearTileBuffer
    ret


RefreshBattleGraphics:
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ret


    ld a, [$d9f5]
    rst $00
    ld e, $57
    xor b
    ld d, a
    ld sp, $3b58
    ld e, b
    ld a, [$db73]
    or a
    jr z, jr_050_5738

    cp $01
    jr z, jr_050_576c

    ld a, [wScriptMapType]
    cp $5d
    jr nz, jr_050_576c

    call BattleGfx_5772
    ld a, $01
    ld [$c1d5], a
    ret


jr_050_5738:
    ld de, $ca42
    ld hl, $c180
    call Copy4Bytes
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ld a, $2a
    call SetTextIdParam
    ld de, $2e07
    call LoadPaletteFromDE
    call ClearTileBuffer
    ld a, $ff
    ld [$db77], a
    ld a, $ff
    ld [$db78], a
    ld hl, $d9f5
    inc [hl]
    ld a, $6d
    call PlaySoundEffect
    ret


jr_050_576c:
    ld a, $f5
    call SaveBtl_5ae5
    ret


BattleGfx_5772:
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ld hl, $0502
    ld a, $03
    ld [$d9f5], a
    ld a, l
    ld [$c822], a
    ld a, h
    ld [$c823], a
    ld hl, $4c00
    rst $10
    ld de, $2e07
    call LoadPaletteFromDE
    ld hl, $89c0
    ld de, $5112
    call WaitDMATransfer
    ld de, $7213
    call LoadPaletteFromDE
    call ClearTileBuffer
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, [$db73]
    or a
    jr nz, jr_050_5808

    ld a, [$db76]
    or a
    jr z, jr_050_5808

    cp $04
    jr nc, jr_050_5808

    cp $03
    jr z, jr_050_57cd

    cp $02
    jr z, jr_050_57c9

    ld b, $40
    jr jr_050_57cf

jr_050_57c9:
    ld b, $80
    jr jr_050_57cf

jr_050_57cd:
    ld b, $c0

jr_050_57cf:
    ld a, [wRNG1]
    cp b
    jr c, jr_050_5808

    call SetBtl_58a6
    jr c, jr_050_5808

    call SetBtl_58d0
    jr c, jr_050_5808

    ld hl, $dd13
    ld a, [$db74]
    ld b, a
    ld a, $03

jr_050_57e8:
    ld [hl+], a
    dec b
    jr nz, jr_050_57e8

    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ld a, $b9
    call SetTextIdParam
    ld de, $2e07
    call LoadPaletteFromDE
    call ClearTileBuffer
    ld hl, $d9f5
    inc [hl]
    ret


jr_050_5808:
    xor a
    ld [$db4e], a
    ld hl, wEventStateMachineIndex
    inc [hl]
    ld a, $0a
    ld [$d9ec], a
    ld hl, $dd1f
    ld a, $ff
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl], a
    ld a, $02                ; flee: outcome back to 2 = NEUTRAL (HW-pinned S68)
    ld [wBattlePostFlag], a  ; -> no exp/join, no loss penalty at exit
    call SetBtl_590c
    ld a, [$db73]
    or a
    ret z

    ld a, $01
    ld [wBattlePostFlag], a
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, wEventStateMachineIndex
    inc [hl]
    ret


    ld de, $58a0
    ld hl, $c1d5
    ld b, $02
    call BtlFunc_77f7
    ld a, [wJoypad_current_frame]
    bit 0, a
    jr z, jr_050_5892

    ld a, [$c1d5]
    bit 0, a
    jr nz, jr_050_5895

    ld de, $ca42
    ld hl, $c180
    call Copy4Bytes
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ld a, $02
    ld [$c822], a
    ld a, $06
    ld [$c823], a
    ld hl, $4c00
    rst $10
    ld de, $2e07
    call LoadPaletteFromDE
    call ClearTileBuffer
    ld a, $ff
    ld [$db77], a
    ld a, $ff
    ld [$db78], a
    ld a, $6d
    call PlaySoundEffect
    ld a, $01
    ld [$d9f5], a
    ret


jr_050_5892:
    bit 1, a
    ret z

jr_050_5895:
    xor a
    ld [wEventStateMachineIndex], a
    ld [wMenu_selection], a
    ld [$d9f5], a
    ret


    cpl
    ld bc, $016f
    rst $38
    rst $38

SetBtl_58a6:
    ld bc, $0304

jr_050_58a9:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_050_58c8

    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    ld a, [hl+]
    and $d0
    jr nz, jr_050_58c8

    inc hl
    inc hl
    ld a, [hl+]
    and $3f
    jr nz, jr_050_58c8

    inc hl
    ld a, [hl]
    and $c0
    jr z, jr_050_58ce

jr_050_58c8:
    inc c
    dec b
    jr nz, jr_050_58a9

    scf
    ret


jr_050_58ce:
    xor a
    ret


SetBtl_58d0:
    ld bc, $0300
    ld de, $0000

jr_050_58d6:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_050_58e3

    call LoadBtl_5900
    cp d
    jr c, jr_050_58e3

    ld d, a

jr_050_58e3:
    inc c
    dec b
    jr nz, jr_050_58d6

    ld bc, $0304

jr_050_58ea:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_050_58f7

    call LoadBtl_5900
    cp e
    jr c, jr_050_58f7

    ld e, a

jr_050_58f7:
    inc c
    dec b
    jr nz, jr_050_58ea

    ld a, $04
    add e
    cp d
    ret


LoadBtl_5900:
    ld a, c
    ld hl, $db9b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ret


SetBtl_590c:
    ld bc, $0300

Jump_050_590f:
    ld a, c
    ld [$db4c], a
    ld a, b
    ld [$db4d], a
    ld a, c
    call CheckMonsterSlot
    jr c, jr_050_5991

    ld de, $0000
    ld a, c
    ld hl, $dc5c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $97
    jr c, jr_050_5931

    ld e, $10

jr_050_5931:
    ld a, c
    ld hl, $db9b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $0a
    jr c, jr_050_595a

    cp $14
    jr c, jr_050_594e

    cp $1e
    jr c, jr_050_5954

    ld a, e
    add $0c
    ld e, a
    jr jr_050_595a

jr_050_594e:
    ld a, e
    add $04
    ld e, a
    jr jr_050_595a

jr_050_5954:
    ld a, e
    add $08
    ld e, a
    jr jr_050_595a

jr_050_595a:
    ld hl, PersonalityRunTable
    add hl, de
    ld a, [$db4c]
    ld bc, $dc44
    add c
    ld c, a
    ld a, $00
    adc b
    ld b, a
    call BitBtl_599f
    inc hl
    ld a, $08
    add c
    ld c, a
    ld a, $00
    adc b
    ld b, a
    call BitBtl_599f
    inc hl
    ld a, $08
    add c
    ld c, a
    ld a, $00
    adc b
    ld b, a
    call BitBtl_599f
    inc hl
    ld a, $08
    add c
    ld c, a
    ld a, $00
    adc b
    ld b, a
    call BitBtl_599f

jr_050_5991:
    ld a, [$db4c]
    ld c, a
    ld a, [$db4d]
    ld b, a
    inc c
    dec b
    jp nz, Jump_050_590f

    ret


BitBtl_599f:
    bit 7, [hl]
    jr nz, jr_050_59ab

    ld a, [bc]
    add [hl]
    jr nc, jr_050_59b4

    ld a, $ff
    jr jr_050_59b4

jr_050_59ab:
    ld a, [hl]
    cpl
    inc a
    ld d, a
    ld a, [bc]
    sub d
    jr nc, jr_050_59b4

    xor a

jr_050_59b4:
    ld [bc], a
    ret

; ---------------------------------------------------------------
; PersonalityRunTable — 8 rows × 4 bytes (signed)
; Adjustments when player selects "Run" plan in battle.
; Rows 0-3: motivation < 151; rows 4-7: motivation >= 151
; Within each half: level <10, 10-19, 20-29, >=30
; Format: [charge_adj, mixed_adj, cautious_adj, motivation_adj]
; ---------------------------------------------------------------
PersonalityRunTable:
    db $fc, $00, $00, $f6 ; motiv<151, lv< 10: charge -4,             motiv -10
    db $fd, $00, $00, $fb ; motiv<151, lv 10-19: charge -3,            motiv  -5
    db $fe, $00, $00, $fd ; motiv<151, lv 20-29: charge -2,            motiv  -3
    db $ff, $00, $00, $fe ; motiv<151, lv>=30: charge -1,              motiv  -2
    db $f8, $00, $00, $f1 ; motiv>=151, lv< 10: charge -8,             motiv -15
    db $fa, $00, $00, $f6 ; motiv>=151, lv 10-19: charge -6,           motiv -10
    db $fc, $00, $00, $fb ; motiv>=151, lv 20-29: charge -4,           motiv  -5
    db $fe, $00, $00, $fd ; motiv>=151, lv>=30: charge -2,             motiv  -3

    call RefreshBattleGraphics
    ld a, [$db58]
    ld l, a
    ld a, [$db59]
    ld h, a
    call BtlFunc_56f1
    ld a, [$db5a]
    ld [wEventStateMachineIndex], a
    ret


    ld a, [wBattleAttackerIdx]
    ld hl, $c180
    ld [$db50], a
    call CheckSlotUnder3
    ld a, [wBattleAttackerIdx]
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    cp $4f
    jr z, jr_050_5a19

    cp $a6
    jr z, jr_050_5a16

    cp $ac
    jr z, jr_050_5a19

    call ReadBtl_5a53
    jr jr_050_5a1c

jr_050_5a16:
    call ReadBtl_5a5e

jr_050_5a19:
    call ReadBtl_5a71

jr_050_5a1c:
    ld a, [wBattleAttackerIdx]
    ld hl, $dcec
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $ff
    call z, LoadBtl_5a50
    cp $da
    call nc, SaveBtl_5ad2
    ld l, a
    ld h, $06
    ld de, $c190
    call SetupVRAMParams
    ld a, $00
    ld [$c822], a
    ld a, [$db4c]
    ld [$c823], a
    cp $ff
    ret z

    ld hl, $4c00
    rst $10
    ret


LoadBtl_5a50:
    ld a, $3a
    ret


ReadBtl_5a53:
    ld a, [hl]
    ld hl, $c1a0
    ld [$db50], a
    call CheckSlotUnder3
    ret


ReadBtl_5a5e:
    ld a, [hl]
    ld [wBattleTargetIdx], a
    ld hl, $5802
    rst $10
    ld a, [$dd72]
    or a
    jr z, jr_050_5a1c

    ld hl, $c180
    jr jr_050_5a89

ReadBtl_5a71:
    ld a, [hl]
    ld [wBattleTargetIdx], a
    ld hl, $5802
    rst $10
    ld a, [$dd72]
    or a
    jr z, jr_050_5ac5

    cp $01
    jr nz, jr_050_5a9c

    call BattleTarget_5ac5
    ld hl, $c1a0

jr_050_5a89:
    ld a, [hl+]
    cp $f0
    jr nz, jr_050_5a89

jr_050_5a8e:
    dec hl
    ld a, [hl]
    cp $f0
    jr z, jr_050_5a8e

    cp $24
    jr c, jr_050_5a99

    inc hl

jr_050_5a99:
    ld [hl], $f0
    ret


jr_050_5a9c:
    ld a, [$c86c]
    or a
    jr nz, jr_050_5ac5

    ld a, [wBattleTargetIdx]
    cp $04
    jr nc, jr_050_5aad

    call BattleTarget_5ac5
    ret


jr_050_5aad:
    ld hl, $c1a0
    ld a, $3e
    ld [hl+], a
    ld a, $62
    ld [hl+], a
    ld a, $44
    ld [hl+], a
    ld a, $3e
    ld [hl+], a
    ld a, $4b
    ld [hl+], a
    ld a, $44
    ld [hl+], a
    ld [hl], $f0
    ret


BattleTarget_5ac5:
jr_050_5ac5:
    ld a, [wBattleTargetIdx]
    ld hl, $c1a0
    ld [$db50], a
    call CheckSlotUnder3
    ret


SaveBtl_5ad2:
    push hl
    sub $da
    ld hl, $5ae1
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    pop hl
    ret


    add hl, de
    and c
    ld a, [hl+]
    ld [hl], b

SaveBtl_5ae5:
    push af
    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    pop af
    call SetTextIdParam
    ld de, $2e07
    call LoadPaletteFromDE
    call ClearTileBuffer
    ld a, $00
    ld [wEventStateMachineIndex], a
    ld a, $00
    ld [$d9f5], a
    ret


SaveBtl_5b07:
    push bc
    ld [$dd72], a
    ld b, a
    call GetMonsterSlotInfo
    jr c, jr_050_5b55

    ld a, b
    ld bc, $db02
    add a
    add a
    add a
    add c
    ld c, a
    ld a, $00
    adc b
    ld b, a
    ld a, [bc]
    bit 4, a
    jr nz, jr_050_5b35

    inc bc
    inc bc
    inc bc
    inc bc
    ld a, [bc]
    and $0c
    jr nz, jr_050_5b35

    inc bc
    ld a, [bc]
    and $f0
    jr nz, jr_050_5b35

    xor a
    jr jr_050_5b56

jr_050_5b35:
    push hl
    ld a, [$dd72]
    ld hl, $dd03
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    or $e0
    ld [hl], a
    ld a, [$dd72]
    ld hl, $dd13
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $01
    pop hl

jr_050_5b55:
    scf

jr_050_5b56:
    pop bc
    ret


    call ClearSpriteBuffer
    call LoadBattleGraphics
    call UpdateBattleSprites
    ld a, $e0
    call SetTextIdParam
    ld de, $2e07
    call LoadPaletteFromDE
    call ClearTileBuffer
    ld a, $00
    ld [wEventStateMachineIndex], a
    ld a, $00
    ld [$d9f5], a
    ret


BtlFunc_5b7a:
    res 7, [hl]
    ld a, [wJoypad_Current]
    and $40
    jp z, Jump_050_5b9a

jr_050_5b84:
    ld a, [hl]
    dec a
    bit 7, a
    call nz, LoadBtl_5bb7
    call SaveBtl_5bbc
    jp nc, Jump_050_7817

    call SaveBtl_5bc5
    ld [hl], a
    jr nz, jr_050_5b84

    jp Jump_050_7817


Jump_050_5b9a:
    ld a, [wJoypad_Current]
    and $80
    jp z, Jump_050_7820

jr_050_5ba2:
    ld a, [hl]
    inc a
    cp b
    call nc, ClrBtl_5bba
    call SaveBtl_5bbc
    jp nc, Jump_050_7817

    call SaveBtl_5bc5
    ld [hl], a
    jr nz, jr_050_5ba2

    jp Jump_050_7817


LoadBtl_5bb7:
    ld a, b
    dec a
    ret


ClrBtl_5bba:
    xor a
    ret


SaveBtl_5bbc:
    push bc
    ld b, a
    or c
    call CheckMonsterSlot
    ld a, b
    pop bc
    ret


SaveBtl_5bc5:
    push bc
    ld b, a
    ld a, [$c1c2]
    cp $30
    jr z, jr_050_5bd4

    cp $31
    jr z, jr_050_5bd4

    cp $bb

jr_050_5bd4:
    ld a, b
    pop bc
    ret


LoadBtl_5bd7:
    ld a, [$c863]
    rlca
    and $04
    ld c, a
    ld b, $03

jr_050_5be0:
    ld a, c
    call CheckMonsterSlot
    jr nc, jr_050_5bfb

    ld a, [$dd76]
    cp $30
    jr z, jr_050_5bfb

    cp $31
    jr z, jr_050_5bfb

    cp $bb
    jr z, jr_050_5bfb

    ld a, c
    res 2, a
    call SaveBtl_5c00

jr_050_5bfb:
    inc c
    dec b
    jr nz, jr_050_5be0

    ret


SaveBtl_5c00:
    push bc
    ld hl, $0060

jr_050_5c04:
    ld a, c
    and $03
    jr z, jr_050_5c14

    ld a, l
    add $40
    ld l, a
    ld a, h
    adc $00
    ld h, a
    dec c
    jr jr_050_5c04

jr_050_5c14:
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $01
    ld h, a
    call AdjustBattlePointerHL

jr_050_5c1f:
    ld a, [hl]
    cp $ff
    jr z, jr_050_5c2d

    cp $80
    jr nc, jr_050_5c2a

    ld [hl], $e0

jr_050_5c2a:
    inc hl
    jr jr_050_5c1f

jr_050_5c2d:
    pop bc
    ret


LoadBtl_5c2f:
    ld a, [wPLAN_selection]
    cp $83
    ret nz

    ld a, [$db73]
    cp $02
    ret nz

    ld a, [$c86c]
    or a
    ret


LoadBtl_5c40:
    ld a, $00
    ld [$dd23], a
    ld a, $00
    ld [$dd24], a
    ld a, $00
    ld [$dd25], a
    ld a, [$db75]
    ld b, a
    ld hl, $dd1f
    ld de, $dc33

jr_050_5c59:
    ld a, [hl+]
    cp $01
    jr nz, jr_050_5c71

    push hl
    ld hl, $dd23
    ld a, [de]
    add [hl]
    ld [hl+], a
    inc de
    ld a, [de]
    adc [hl]
    ld [hl+], a
    inc de
    ld a, [de]
    adc [hl]
    ld [hl], a
    inc de
    pop hl
    jr jr_050_5c74

jr_050_5c71:
    inc de
    inc de
    inc de

jr_050_5c74:
    dec b
    jr nz, jr_050_5c59

    ret


    ld a, [$c86c]
    or a
    jr nz, jr_050_5cb4

    call LoadBtl_6974
    call SetupBattleAction
    ld bc, $0304
    ld de, $0000

jr_050_5c8a:
    ld a, c
    ld hl, $dd1b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $01
    jr nz, jr_050_5c9a

    inc d

jr_050_5c9a:
    inc c
    dec b
    jr nz, jr_050_5c8a

    ld a, d
    or a
    jr nz, jr_050_5ca4

    ld e, $03

jr_050_5ca4:
    ld a, [$db4c]
    cp $02
    jr c, jr_050_5cad

    ld a, $02

jr_050_5cad:
    add e
    add $ec
    call SetTextIdParam
    ret


jr_050_5cb4:
    ld b, $03
    ld a, [$c863]
    bit 1, a
    jr z, jr_050_5cc1

    ld c, $04
    jr jr_050_5cc3

jr_050_5cc1:
    ld c, $00

jr_050_5cc3:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_050_5cd4

    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    bit 6, [hl]
    jr z, jr_050_5cf5

jr_050_5cd4:
    inc c
    dec b
    jr nz, jr_050_5cc3

    ld a, [$c863]
    bit 1, a
    jr z, jr_050_5ce4

    call SetBtl_5d1f
    jr jr_050_5ce7

jr_050_5ce4:
    call SetBtl_5d1a

jr_050_5ce7:
    ld a, $4f
    ld [$dd72], a
    ld a, $ff
    ld [$db73], a
    ld a, $eb
    jr jr_050_5d0b

jr_050_5cf5:
    ld a, [$c863]
    bit 1, a
    jr z, jr_050_5d01

    call SetBtl_5d1a
    jr jr_050_5d04

jr_050_5d01:
    call SetBtl_5d1f

jr_050_5d04:
    ld a, $69
    ld [$dd72], a
    ld a, $ed

jr_050_5d0b:
    call SetTextIdParam
    ld a, $02
    call SetBGM
    ld a, [$dd72]
    call PlaySoundEffect
    ret


SetBtl_5d1a:
    ld de, $cacd
    jr jr_050_5d22

SetBtl_5d1f:
    ld de, $cd21

jr_050_5d22:
    ld hl, $c180
    call Copy4Bytes
    ret


LoadBtl_5d29:
    ld a, $02
    ld [wBattlePostFlag], a
    ld a, [$db73]
    or a
    jr nz, jr_050_5d46

    ld a, [wRNG1]
    and $1f
    cp $1f
    jr z, jr_050_5d4c

    ld a, [wRNG2]
    and $1f
    cp $1f
    jr z, jr_050_5d71

jr_050_5d46:
    ld a, $01
    ld [$db76], a
    ret


jr_050_5d4c:
    ld hl, $d9ec
    inc [hl]
    call CallBtl_696d
    ld a, [$db4c]
    cp $02
    jr c, jr_050_5d5c

    ld a, $02

jr_050_5d5c:
    ld c, a
    ld a, [wRNG2]
    and $01
    ld b, a
    add a
    add b
    add c
    add $03
    call SetTextIdParam
    ld a, $00
    ld [wBattlePostFlag], a
    ret


jr_050_5d71:
    ld hl, $d9ec
    inc [hl]
    ld hl, $d9ec
    inc [hl]
    call CallBtl_696d
    ld a, $04
    ld [wBattleAttackerIdx], a
    ld a, [$db4c]
    cp $02
    jr c, jr_050_5d8a

    ld a, $02

jr_050_5d8a:
    ld c, a
    ld a, [wRNG1]
    and $01
    ld b, a
    add a
    add b
    add c
    add $09
    call SetTextIdParam
    ld a, $01
    ld [wBattlePostFlag], a
    ret


LoadBtl_5d9f:
    ld a, $ff
    ld hl, $db79
    ld bc, $000a
    call FillNBytesWithRegA
    ld b, $08
    ld c, $00
    ld h, $00

jr_050_5db0:
    ld a, c
    ld e, a
    ld d, a
    ld a, c
    call GetMonsterSlotInfo
    ld a, d
    and a
    jr nz, jr_050_5dbc

    inc h

jr_050_5dbc:
    inc c
    dec b
    jr nz, jr_050_5db0

    ld a, h
    or a
    jr nz, jr_050_5dc8

    ld hl, $d9ec
    inc [hl]

jr_050_5dc8:
    ret


    ld hl, sp+$00
    ld a, l
    ld [$da79], a
    ld a, h
    ld [$da7a], a
    xor a
    ld hl, wMenu_selection
    ld bc, $0008
    call FillNBytesWithRegA
    xor a
    ld hl, $c827
    ld bc, $0012
    call FillNBytesWithRegA
    ld hl, $99c1
    ld a, l
    ld [$c83e], a
    ld a, h
    ld [$c83f], a
    xor a
    ld hl, $d9ec
    ld bc, $0008
    call FillNBytesWithRegA
    xor a
    ld hl, wEventStateMachineIndex
    ld bc, $0008
    call FillNBytesWithRegA
    xor a
    ld [$d9ed], a
    ld [$dd62], a
    call ClearSTATMode
    xor a
    ld [$dd60], a
    xor a
    ld [$c8ec], a
    xor a
    ld [$c87e], a
    ld hl, $5100
    rst $10
    ret


    ld a, [$c86c]
    or a
    jr z, jr_050_5e3e

    call CheckState_C86c_047E
    ld a, [$c850]
    or a
    ret nz

    call ReadBattleStateDA80
    ld a, [$dd62]
    or a
    ret z

    di
    ld hl, $0200
    rst $10
    ei
    ret


jr_050_5e3e:
    ld a, [$c850]
    or a
    ret nz

    call ReadBattleStateDA80
    call LoadBtl_6d78
    ld a, [$c850]
    or a
    ret nz

    ld a, [$da80]
    cp $01
    jp nz, Jump_050_5ede

    ld a, [$da81]
    cp $ff
    ret z

    ld a, [$da81]
    ld [$c81e], a
    ld hl, $170d
    rst $10
    ld hl, $1708
    rst $10
    ld a, [$da81]
    ld hl, $5e84
    ld c, a
    ld b, $00
    add hl, bc
    add hl, bc
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    ld hl, $8000
    call WaitDMATransfer
    ld a, $02
    ld [$da80], a
    ret


    nop
    ld e, d
    ld bc, $025a
    ld e, d
    inc bc
    ld e, d
    inc b
    ld e, d
    dec b
    ld e, d
    ld b, $5a
    rlca
    ld e, d
    ld [$095a], sp
    ld e, d
    ld a, [bc]
    ld e, d
    dec bc
    ld e, d
    inc c
    ld e, d
    dec c
    ld e, d
    ld c, $5a
    rrca
    ld e, d
    db $10
    ld e, d
    ld de, $125a
    ld e, d
    inc de
    ld e, d
    inc d
    ld e, d
    dec d
    ld e, d
    ld d, $5a
    rla
    ld e, d
    jr jr_050_5f10

    add hl, de
    ld e, d
    ld a, [de]
    ld e, d
    dec de
    ld e, d
    inc e
    ld e, d
    dec e
    ld e, d
    ld e, $5a
    rra
    ld e, d
    ld a, [bc]
    ld e, e
    dec bc
    ld e, e
    inc c
    ld e, e
    dec c
    ld e, e
    ld c, $5b
    rrca
    ld e, e
    db $10
    ld e, e
    ld de, $125b
    ld e, e
    inc de
    ld e, e
    inc d
    ld e, e
    dec d
    ld e, e
    ld d, $5b

Jump_050_5ede:
    ld a, [$dd62]
    or a
    jr z, jr_050_5ef9

    ld a, [$c86c]
    or a
    jr nz, jr_050_5eee

    ld hl, $0200
    rst $10

jr_050_5eee:
    ld a, [$dd62]
    or a
    ret nz

    ld a, $00
    ld [$da80], a
    ret


jr_050_5ef9:
    ld a, [$d9ec]
    cp $0d
    jr z, jr_050_5f17

    ld a, [$c825]
    or a
    jr z, jr_050_5f17

    ld a, [$da82]
    or a
    jr z, jr_050_5f17

    ld hl, $5f05
    rst $10

jr_050_5f10:
    ld a, [$c87e]
    or a
    jr nz, jr_050_5f17

    ret


jr_050_5f17:
    ld a, [$da82]
    or a
    jr z, BattlePhaseDispatch

    ld a, [$da83]
    cp $09
    jr nz, BattlePhaseDispatch

    ld hl, $5f05
    rst $10
    ld a, [$c87e]
    or a
    jr nz, BattlePhaseDispatch

    ret


BattlePhaseDispatch:
    ld a, [$db73]
    cp $ff
    jr z, BattlePhaseFreezeWait

    ld a, [$d9ec]            ; wBattlePhase
    rst $00                  ; dispatch via BattlePhaseTable below

; BattlePhaseTable — 18 entries, indexed by $D9EC (battle phase machine).
; Re-sectioned S68 from fake instructions (byte-identical; 36 bytes).
BattlePhaseTable:
    dw $5f6d                 ; $00 intro: party-alive check ($CA8D)
    dw $5f93                 ; $01 intro: $DA33 delay; party empty -> BattleExitHandler
    dw $5fae                 ; $02 intro: LoadBtl_5d29 ($DB55=2 + 1/32-per-side random intro event) + announce
    dw $5fc1                 ; $03 intro: clear $DB42+, stage side slot masks $DD03/$DD07
    dw $6051                 ; $04 tick nested $D9F4 sub-machine (LoadBtl_4017)
    dw $606f                 ; $05 when UI free: far-call bank $58 entry 0
    dw $6079                 ; $06 advance phase + clear $D9ED/$D9EE/$DD75/$DD6C/$DD68
    dw $60b6                 ; $07 far-call bank $52 entry 0 (turn/skill engine)
    dw $60cb                 ; $08 post-turn $DA33 delay -> phase $09
    dw $6aac                 ; $09 turn sequencer sub-machine on $D9ED (6 states)
    dw $60ed                 ; $0A post-battle setup: exp walker / link fork
    dw $62f0                 ; $0B level scan: party list $CA8E-90 + 20-slot loop
    dw $63c1                 ; $0C level display gate ($DB55!=0 -> phase $0E)
    dw $63d2                 ; $0D join dispatcher ($DD61)
    dw $640a                 ; $0E BattleExitHandler (mode->field; loss penalty)
    dw $6951                 ; $0F no-op (ret) parking phase
    dw $65dc                 ; $10 link exit: $C873=1 fade
    dw $65e6                 ; $11 link teardown: commit party to SRAM, clear $C86x

BattlePhaseFreezeWait:
    ld a, [$dd80]
    ld hl, $dd9a
    and [hl]
    cp $ff
    ret nz

    xor a
    ld [$db73], a
    ret

; Phase $00 ($5F6D): battle intro — bank $17 entries 2/8, then party-alive
; count $CA8D: zero -> tilemap $0C00 + advance (wipe path); else announce
; setup LoadBtl_6974 + $DA33=5 frame delay.
BattlePhase00_PartyAliveCheck:
    ld hl, $1702
    rst $10
    ld hl, $1708
    rst $10
    ld a, [$ca8d]
    or a
    jr nz, jr_050_5f86

    ld hl, $0c00
    call SetupTilemapTransfer
    ld hl, $d9ec
    inc [hl]
    ret


jr_050_5f86:
    call LoadBtl_6974
    ld a, $05
    ld [$da33], a
    ld hl, $d9ec
    inc [hl]
    ret

; Phase $01 ($5F93): wait UI + $DA33 countdown; party count 0 -> jp
; BattleExitHandler (pre-battle wipe), else intro announce LoadBtl_69c4.
BattlePhase01_IntroDelay:
    ld a, [$c825]
    or a
    ret nz

    ld a, [$da33]
    or a
    jr z, jr_050_5fa3

    dec a
    ld [$da33], a
    ret


jr_050_5fa3:
    ld a, [$ca8d]
    or a
    jp z, BattleExitHandler

    call LoadBtl_69c4
    ret

; Phase $02 ($5FAE): LoadBtl_5d29 sets $DB55=2 (neutral), then rolls the
; RANDOM BATTLE-INTRO EVENT: [$C899]&$1F==$1F (1/32, live RNG — HW-pinned
; S68) -> player-side variant (msgs 3-8 via $6AA0, +1 phase skip, $DB55=0);
; [$C89A]&$1F==$1F -> enemy-side variant (msgs 9-14, +2 phase skip,
; $DB88=4, $DB55=1). $DB55 doubles as the intro-event marker until the
; bank $52 KO scans overwrite it with the real outcome. + LoadBtl_68fc.
BattlePhase02_IntroAnnounce:
    call LoadBtl_5d29
    call LoadBtl_68fc
    ld hl, $d9ec
    inc [hl]
    xor a
    ld [$d9ed], a
    xor a
    ld [$d9ee], a
    ret

; Phase $03 ($5FC1): advance; clear $C8DA(wMenu_selection alias), $DB42x8;
; stage side slot masks from enemy count $DB74 -> $DD03 (and $DB75 -> $DD07
; when $C863.1 = link second side).
BattlePhase03_InitSideSlots:
    ld hl, $d9ec
    inc [hl]
    xor a
    ld [wMenu_selection], a
    call LoadBtl_5d9f
    call SetBtl_600d
    ld hl, $db42
    ld bc, $0008
    xor a
    call FillNBytesWithRegA
    ld a, [$db74]
    ld b, a
    ld c, $00
    ld hl, $dd03
    call LoadBtl_5ff8
    ld a, [$c863]
    bit 1, a
    ret z

    ld a, [$db75]
    ld b, a
    ld c, $04
    ld hl, $dd07
    call LoadBtl_5ff8
    ret


LoadBtl_5ff8:
jr_050_5ff8:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_050_6004

    ld a, [hl]
    and $0f
    ld [hl+], a
    jr jr_050_6008

jr_050_6004:
    ld a, [hl]
    or $e0
    ld [hl+], a

jr_050_6008:
    inc c
    dec b
    jr nz, jr_050_5ff8

    ret


SetBtl_600d:
    ld de, $dcec
    ld bc, $0800

jr_050_6013:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_050_6046

    ld a, c
    ld hl, $db06
    call HL_AddA_x8
    bit 2, [hl]
    jr z, jr_050_6046

    ld a, c
    ld hl, $c1cd
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    bit 7, [hl]
    jr nz, jr_050_6046

    ld a, c
    ld hl, $dd03
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    bit 6, [hl]
    jr nz, jr_050_6046

    ld a, $ff
    ld [de], a
    inc de
    jr jr_050_604b

jr_050_6046:
    ld a, $ff
    ld [de], a
    inc de
    ld [de], a

jr_050_604b:
    inc de
    inc c
    dec b
    jr nz, jr_050_6013

    ret

; Phase $04 ($6051): tick the nested $D9F4 sub-machine (LoadBtl_4017).
BattlePhase04_SubMachineTick:
    jr jr_050_6067

BattleDispatchEntry3:
    call ClearSpriteBuffer
    call LoadBattleGraphics
    ld a, [$da88]
    or a
    jr nz, jr_050_6063

    call SetBtl_79ae
    ret


jr_050_6063:
    call UpdateBattleSprites
    ret


jr_050_6067:
    call LoadBtl_4017
    xor a
    ld [$d9ed], a
    ret

; Phase $05 ($606F): when UI free, far-call bank $58 entry 0.
BattlePhase05_Bank58Tick:
    ld a, [$c825]
    or a
    ret nz

    ld hl, $5800
    rst $10
    ret

; Phase $06 ($6079): advance + clear $D9ED/$D9EE/$DD75/$DD6C/$DD68; link
; ($C86C!=0): cycle saved RNG pair $C1ED/EE via $C899/$C89A + $12D0.
BattlePhase06_AdvanceAndClear:
    ld hl, $d9ec
    inc [hl]
    xor a
    ld [$d9ed], a
    ld [$d9ee], a
    ld [$dd75], a
    ld [$dd6c], a
    ld [$dd68], a
    ld a, [$c86c]
    or a
    jr z, jr_050_60b6

    ld a, [$c1ed]
    ld l, a
    ld a, [$c1ee]
    ld h, a
    ld a, l
    ld [wRNG1], a
    ld a, h
    ld [wRNG2], a
    call GenerateRNG
    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    ld a, l
    ld [$c1ed], a
    ld a, h
    ld [$c1ee], a

; Phase $07 ($60B6): far-call bank $52 entry 0 (turn/skill engine); the
; engine itself advances $D9EC; on ==8 arm $DA33=5 post-turn delay.
BattlePhase07_TurnEngine:
jr_050_60b6:
    ld hl, $5200
    rst $10
    call UpdateBattleSprites
    call LoadBtl_7627
    ld a, [$d9ec]
    cp $08
    ret nz

    ld a, $05
    ld [$da33], a

; Phase $08 ($60CB): $DA33 countdown, then advance; clear skill id trio
; $DB4C-$DB4E; call $6053 sprites + fall through to phase-9 sequencer.
BattlePhase08_PostTurnDelay:
    ld a, [$da33]
    or a
    jr z, jr_050_60d6

    dec a
    ld [$da33], a
    ret


jr_050_60d6:
    ld hl, $d9ec
    inc [hl]
    xor a
    ld [$db4c], a
    ld [$db4d], a
    ld [$db4e], a
    ld [$d9ed], a
    call BattleDispatchEntry3
    jp BattlePhase09_TurnSequencer

; Phase $0A ($60ED): post-battle setup. LINK ($C86C!=0): no exp — $C8C7=1,
; jump phase $10. Local: exp accumulator $DD23-25 -> exp walker CallBtl_61e2
; (CF2 divert site); $DB55!=0 (loss) skips exp AND join ($DD61=0).
BattlePhase0A_PostBattleSetup:
    ld a, [$c825]
    or a
    ret nz

    ld hl, wBGPalette
    ld a, $d2
    ld [hl+], a
    ld a, $d2
    ld [hl+], a
    ld [hl], $e2
    ld a, [$db4e]
    cp $02
    jr nz, jr_050_6112

    ld hl, $5201
    rst $10
    xor a
    ld [$db4e], a
    ld a, $05
    ld [$da33], a
    ret


jr_050_6112:
    ld a, [$da33]
    or a
    jr z, jr_050_611d

    dec a
    ld [$da33], a
    ret


jr_050_611d:
    call ClearSpriteBuffer
    call SetBtl_79ae
    call ClearTileBuffer
    ld a, [$c86c]
    or a
    jr z, jr_050_6139

    ld a, $01
    ld [$c8c7], a
    ld a, $10
    ld [$d9ec], a
    jp Jump_050_6196


jr_050_6139:
    call LoadBtl_5c40
    ld hl, $5102
    rst $10
    ld a, [wBattlePostFlag]
    or a
    jr z, jr_050_6150

    xor a
    ld [$dd61], a
    ld hl, $d9ec
    inc [hl]
    jr jr_050_6196

jr_050_6150:
    ld hl, $dd23
    ld a, [hl+]
    or [hl]
    inc hl
    or [hl]
    jr z, jr_050_6192

    call CallBtl_61e2
    ld hl, $0106
    rst $10
    call CallBtl_6197
    ld a, l
    ldh [$d5], a
    ld a, h
    ldh [$d6], a
    ld a, e
    ldh [$d7], a
    ld hl, $c180
    call FormatLargeNumber
    call BtlFunc_61cd
    ld a, b
    ld hl, $0b0e
    cp $01
    jr nz, jr_050_618f

    ld a, c
    ld hl, $cac2
    call GetMonsterDataPtr
    ld e, l
    ld d, h
    ld hl, $c190
    call Copy4Bytes
    ld hl, $0b23

jr_050_618f:
    call SetupTilemapTransfer

jr_050_6192:
    ld hl, $d9ec
    inc [hl]

Jump_050_6196:
jr_050_6196:
    ret


CallBtl_6197:
    call BtlFunc_61cd
    ld a, [$dd23]
    ld l, a
    ld a, [$dd24]
    ld h, a
    ld a, [$dd25]
    ld e, a
    ld a, b
    push af
    call Div24x8To16
    pop af
    cp $02
    ret z

    cp $03
    jr z, jr_050_61c0

    ld a, l
    sub $01
    ld l, a
    ld a, h
    sbc $00
    ld h, a
    ld a, e
    sbc $00
    ld e, a
    ret


jr_050_61c0:
    ld a, l
    add $01
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, e
    adc $00
    ld e, a
    ret


BtlFunc_61cd:
    ld b, $00
    ld a, [$ca8e]
    call CmpBtl_62dd
    ld a, [$ca8f]
    call CmpBtl_62dd
    ld a, [$ca90]
    call CmpBtl_62dd
    ret


; =============================================================================
; POST-BATTLE EXP DISTRIBUTION (S56, see MONSTER_DATA CF1 section).
; CallBtl_6197: HRAM $D8-$DA := party share = total($DD23-25) / eligible
;   party count (b from BtlFunc_61cd: listed members not $FF, not KO +$4A
;   bit7; rounding quirk b=3 -> +1, b=1 -> -1).
; Below: HRAM $DB-$DD := farm share = total/16. Then ONE walk over all 20
; slots (Jump_050_6211): flag $02 -> +party share; flag $01 -> +farm share;
; skip empty / egg (+$63!=0) / KO party / level $63 / level>=cap (+$4C);
; clamp $98967F. THE party/farm fork for Cold Farm CF2 is the `cp $02` in
; Jump_050_6211.
; =============================================================================
CallBtl_61e2:
    call CallBtl_6197
    ld a, l
    ldh [$d8], a
    ld a, h
    ldh [$d9], a
    ld a, e
    ldh [$da], a
    ld a, [$dd23]
    ld l, a
    ld a, [$dd24]
    ld h, a
    ld a, [$dd25]
    ld e, a
    ld a, $10
    call Div24x8To16
    ld a, l
    ldh [$db], a
    ld a, h
    ldh [$dc], a
    ld a, e
    ldh [$dd], a
    ld hl, $cac1
    ld b, $14
    xor a
    ld [$cac0], a

Jump_050_6211:
    push hl
    ld a, [hl]
    or a
    jp z, Jump_050_62c4

    cp $02
    jr z, jr_050_6272

    ld a, l
    add $63
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl]
    or a
    jp nz, Jump_050_62c4

    ld a, l
    add $e8
    ld l, a
    ld a, h
    adc $ff
    ld h, a
    ld a, [hl]
    cp $63
    jp z, Jump_050_62c4

    push af
    ld a, l
    add $01
    ld l, a
    ld a, h
    adc $00
    ld h, a
    pop af
    cp [hl]
    jp nc, Jump_050_62c4

    ld a, l
    add $01
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ldh a, [$db]
    add [hl]
    ld [hl+], a
    ld e, a
    ldh a, [$dc]
    adc [hl]
    ld [hl+], a
    ld d, a
    ldh a, [$dd]
    adc [hl]
    ld [hl], a
    ld c, a
    ld a, e
    sub $7f
    ld a, d
    sbc $96
    ld a, c
    sbc $98
    jr c, jr_050_62c4

    ld de, $967f
    ld c, $98
    ld [hl], c
    dec hl
    ld [hl], d
    dec hl
    ld [hl], e
    jr jr_050_62c4

jr_050_6272:
    ld a, l
    add $4a
    ld l, a
    ld a, h
    adc $00
    ld h, a
    bit 7, [hl]
    jr nz, jr_050_62c4

    ld a, l
    add $01
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl]
    cp $63
    jr z, jr_050_62c4

    push af
    ld a, l
    add $01
    ld l, a
    ld a, h
    adc $00
    ld h, a
    pop af
    cp [hl]
    jr nc, jr_050_62c4

    ld a, l
    add $01
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ldh a, [$d8]
    add [hl]
    ld [hl+], a
    ld e, a
    ldh a, [$d9]
    adc [hl]
    ld [hl+], a
    ld d, a
    ldh a, [$da]
    adc [hl]
    ld [hl], a
    ld c, a
    ld a, e
    sub $7f
    ld a, d
    sbc $96
    ld a, c
    sbc $98
    jr c, jr_050_62c4

    ld de, $967f
    ld c, $98
    ld [hl], c
    dec hl
    ld [hl], d
    dec hl
    ld [hl], e

Jump_050_62c4:
jr_050_62c4:
    pop hl
    push bc
    push hl
    call ReadBtl_689e
    ld hl, $cac0
    inc [hl]
    pop hl
    pop bc
    ld a, l
    add $95
    ld l, a
    ld a, h
    adc $00
    ld h, a
    dec b
    jp nz, Jump_050_6211

    ret


CmpBtl_62dd:
    cp $ff
    ret z

    ld hl, $cb0b
    push af
    push bc
    call GetMonsterDataPtr
    pop bc
    pop af
    bit 7, [hl]
    ret nz

    ld c, a
    inc b
    ret

; Phase $0B ($62F0): level scan — party list $CA8E/$CA8F/$CA90 via
; CmpBtl_6383, then the 20-slot b=0..$13 loop (farm scan; CF2 re-bound).
; No hits -> advance + reset $D9F4=0; join pending -> skip 2 phases +
; far-call bank $54 entry 7.
BattlePhase0B_LevelScan:
    ld a, [$c825]
    or a
    ret nz

    ld a, [$ca8e]
    call CmpBtl_6383
    jr nc, jr_050_630d

    ld a, [$ca8f]
    call CmpBtl_6383
    jr nc, jr_050_630d

    ld a, [$ca90]
    call CmpBtl_6383
    jr c, jr_050_6316

jr_050_630d:
    ld hl, $d9ec
    inc [hl]
    xor a
    ld [wEventStateMachineIndex], a
    ret


jr_050_6316:
    ld b, $00

jr_050_6318:
    push bc
    ld a, b
    call CmpBtl_6383
    pop bc
    jr nc, jr_050_6337

    inc b
    ld a, b
    cp $14
    jr nz, jr_050_6318

    ld hl, $d9ec
    inc [hl]
    ld hl, $d9ec
    inc [hl]
    xor a
    ld [wEventStateMachineIndex], a
    ld hl, $5407
    rst $10
    ret


jr_050_6337:
    ld hl, $1302
    rst $10
    ld hl, $510d
    rst $10
    ret


    cp $ff
    ret z

    ld [$cac0], a
    ld a, b
    ld hl, $da15
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    push hl
    ld a, [$cac0]
    ld d, a
    ld hl, $0107
    rst $10
    ld a, d
    pop hl
    cp [hl]
    ret z

    ld [hl], a
    ld l, a
    ld h, $0a
    ld de, $c190
    call SetupVRAMParams
    ld a, [$cac0]
    ld hl, $cac2
    call GetMonsterDataPtr
    ld e, l
    ld d, h
    ld hl, $c180
    call Copy4Bytes
    ld hl, $0b21
    call SetupTilemapTransfer
    ld a, [$c825]
    or a
    ret


; Pending-level-up probe for slot A: carry = skip (empty/$FF/level 99);
; else bank $13 entry 0 threshold fetch + 24-bit exp compare. Callers run
; the party list FIRST, then the all-20 scan jr_050_6318 (farm monsters
; level immediately post-battle in vanilla). (S56)
CmpBtl_6383:
    cp $ff
    jr z, jr_050_63a2

    ld [$cac0], a
    ld hl, $cb0c
    call GetMonsterDataPtr
    ld a, [hl]
    cp $63
    jr z, jr_050_63a2

    ld a, [$cac0]
    ld hl, $cac1
    call GetMonsterDataPtr
    ld a, [hl]
    or a
    jr nz, jr_050_63a4

jr_050_63a2:
    scf
    ret


jr_050_63a4:
    ld hl, $1300
    rst $10
    ld a, [$cac0]
    ld hl, $cb0e
    call GetMonsterDataPtr
    ldh a, [$d5]
    ld b, a
    ld a, [hl+]
    sub b
    ldh a, [$d6]
    ld b, a
    ld a, [hl+]
    sbc b
    ldh a, [$d7]
    ld b, a
    ld a, [hl+]
    sbc b
    ret

; Phase $0C ($63C1): $DB55==0 (win) -> bank $51 entry $0C level display;
; else (loss/undecided) jump straight to phase $0E (BattleExitHandler).
BattlePhase0C_LevelDisplayGate:
    ld a, [wBattlePostFlag]
    or a
    jr nz, jr_050_63cc

    ld hl, $510c
    rst $10
    ret


jr_050_63cc:
    ld a, $0e
    ld [$d9ec], a
    ret

; Phase $0D ($63D2): join dispatcher — $DD61 join candidate ($FF = none).
BattlePhase0D_JoinDispatch:
    ld a, [wEventStateMachineIndex]
    cp $24
    jr z, jr_050_63de

    ld a, [$c825]
    or a
    ret nz

jr_050_63de:
    ld a, [$dd61]
    cp $ff
    jr nz, jr_050_63ea

    ld hl, $d9ec
    inc [hl]
    ret


jr_050_63ea:
    ld a, [$dd61]
    sub $04
    add a
    ld hl, wTempEnemyId1
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld [wTempEnemyStatsId], a
    ld a, [hl]
    ld [$da13], a
    ld hl, $1406
    rst $10
    ld hl, $510e
    rst $10
    ret


BattleExitHandler:
    ld a, [$c825]
    or a
    ret nz

    ld hl, $0106
    rst $10
    ld hl, $c8ea
    set 7, [hl]
    ld a, $04
    call SetGBCPalette
    ld a, $01
    ld [wGameMode], a
    ld a, $00
    ld [$c88b], a
    ld a, $00
    ld [$c88c], a
    ld a, $00
    ld [$c88d], a
    ld hl, $c88e
    inc [hl]
    ld a, [wMapID]
    cp $5d
    jp nz, Jump_050_64e0

    ld hl, $c8ea
    res 7, [hl]
    ld a, [wArenaStarryBattle]
    cp $02
    jr z, jr_050_64a0

    cp $01
    jr z, jr_050_6486

    call LoadArenaEnemyStats
    xor a
    ld [wScriptStateFlags], a
    ld a, [wBattlePostFlag]
    cp $01
    ret nz

    ld a, $ff
    ld [wColiseumBattle], a
    ld hl, $0006
    ld a, l
    ld [wWarpGateId], a
    ld a, h
    ld [wWarpFlag], a
    ld hl, $00e8
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
    ret


jr_050_6486:
    call LoadArenaEnemyStats
    xor a
    ld [wScriptStateFlags], a
    ld a, [wBattlePostFlag]
    cp $01
    jr z, jr_050_64af

    ld a, [wColiseumBattle]
    cp $02
    ret nz

    ld a, $02
    ld [wArenaStarryBattle], a
    ret


jr_050_64a0:
    xor a
    ld [wScriptStateFlags], a
    ld a, $03
    ld [wArenaStarryBattle], a
    ld a, [wBattlePostFlag]
    cp $01
    ret nz

jr_050_64af:
    ld a, $08
    ld [$d92b], a
    ld hl, $0000
    ld a, l
    ld [wWarpGateId], a
    ld a, h
    ld [wWarpFlag], a
    ld hl, $00e8
    ld a, l
    ld [wWarpSpawnXLo], a
    ld a, h
    ld [wWarpSpawnXHi], a
    ld hl, $0058
    ld a, l
    ld [wWarpSpawnYLo], a
    ld a, h
    ld [wWarpSpawnYHi], a
    ld a, $01
    ld [wIsPlayerChangingMaps], a
    ld hl, $c8ea
    res 7, [hl]
    ret


Jump_050_64e0:
    ld a, [wMapID]
    cp $52
    jr nz, jr_050_64f5

    call SetBtl_67ae
    xor a
    ld [wScriptStateFlags], a
    ld hl, $c8ea
    res 7, [hl]
    jr jr_050_6546

jr_050_64f5:
    ld a, [$da09]
    cp $02
    jr nz, jr_050_6546

    ld a, [wBattlePostFlag]
    cp $01
    ret nz

    ld b, $00
    ld c, $00
    ld a, [$ca8e]
    call CmpBtl_6535
    ld a, [$ca8f]
    call CmpBtl_6535
    ld a, [$ca90]
    call CmpBtl_6535
    ld a, b
    cp c
    ret nz

    ld a, [$ca8e]
    ld hl, $cb11
    call GetMonsterDataPtr
    ld [hl], $01
    inc hl
    ld [hl], $00
    ld a, [$ca8e]
    ld hl, $cb0b
    call GetMonsterDataPtr
    ld [hl], $00
    ret


CmpBtl_6535:
    cp $ff
    ret z

    inc b
    ld hl, $cb0b
    call GetMonsterDataPtr
    ld a, [hl]
    and $80
    ld [hl], a
    ret z

    inc c
    ret


jr_050_6546:
    ld a, [wBattlePostFlag]
    cp $01
    jr z, jr_050_6559

    ld a, [$da09]
    cp $03
    ret nz

    ld a, $0e
    ld [$c8ed], a
    ret


jr_050_6559:
    ld a, $08
    ld [$d92b], a
    ld hl, $0000
    ld a, l
    ld [wWarpGateId], a
    ld a, h
    ld [wWarpFlag], a
    ld hl, $00e8
    ld a, l
    ld [wWarpSpawnXLo], a
    ld a, h
    ld [wWarpSpawnXHi], a
    ld hl, $0058
    ld a, l
    ld [wWarpSpawnYLo], a
    ld a, h
    ld [wWarpSpawnYHi], a
    ld a, $01
    ld [wIsPlayerChangingMaps], a
    ld hl, $c8ea
    res 7, [hl]
    ld a, [wCurrGoldLo]
    ld l, a
    ld a, [wCurrGoldMid]
    ld h, a
    ld a, [wCurrGoldHi]
    ld e, a
    ld a, $02
    call Div24x8To16
    ld a, l
    ld [wCurrGoldLo], a
    ld a, h
    ld [wCurrGoldMid], a
    ld a, e
    ld [wCurrGoldHi], a
    ld hl, wInventory
    ld b, $14

jr_050_65ab:
    ld a, [hl]
    or a
    jr z, jr_050_65c7

    cp $ff
    jr z, jr_050_65c7

    ld [$da5e], a
    push hl
    push bc
    ld hl, $0302
    rst $10
    pop bc
    pop hl
    ld a, [$da6d]
    bit 2, a
    jr nz, jr_050_65c7

    ld [hl], $ff

jr_050_65c7:
    inc hl
    dec b
    jr nz, jr_050_65ab

    ld hl, $0305
    rst $10
    xor a
    ldh [$90], a
    xor a
    ld [wScriptStateFlags], a
    ld hl, wGameState
    res 0, [hl]
    ret


    ld a, $01
    ld [$c873], a
    ld hl, $d9ec
    inc [hl]
    ret


    ld a, [$c86e]
    cp $01
    ret nz

    ld hl, $cacd
    ld a, [$c863]
    bit 1, a
    jr nz, jr_050_65f9

    ld hl, $cd21

jr_050_65f9:
    ld de, $c8bb
    ld b, $08
    call ReadBtl_66cc
    ld a, [$c8ba]
    cp $ff
    jr z, jr_050_6663

    ld a, [wBattlePostFlag]
    or a
    jr z, jr_050_6663

    di
    ld hl, $cac1
    ld de, $a1fb
    ld bc, $0ba4
    call LoadBtl_66b9
    ei
    ld a, [$c8ba]
    ld hl, $cac1
    call GetMonsterDataPtr
    ld de, $d665
    ld b, $95
    call ReadBtl_66cc
    ld a, [$c8ba]
    ld hl, $cac1
    call GetMonsterDataPtr
    ld [hl], $00
    di
    ld hl, $ca8d
    ld de, $a1c7
    ld bc, $0007
    call LoadBtl_66b9
    ei
    ld hl, $0105
    rst $10
    di
    call SavePartyToSRAM
    ei
    ld a, $00
    call BtlFunc_669f
    ld a, $01
    call BtlFunc_669f
    ld a, $02
    call BtlFunc_669f
    ld a, $14
    ld [$c8ba], a

jr_050_6663:
    ld a, $04
    call SetGBCPalette
    ld a, $06
    ld [wGameMode], a
    ld a, $00
    ld [$c88b], a
    ld a, $00
    ld [$c88c], a
    ld a, $00
    ld [$c88d], a
    ld hl, $c88e
    inc [hl]
    xor a
    ld [$c865], a
    ld [$c866], a
    xor a
    ld [$c863], a
    ld [$c864], a
    xor a
    ld [$c86c], a
    xor a
    ld [$c86e], a
    xor a
    ld [$c873], a
    xor a
    ld [$c86d], a
    ret


BtlFunc_669f:
    ld c, a
    ld hl, $c8c4
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $ff
    cp [hl]
    ret z

    ld a, [$c8ba]
    cp [hl]
    jr z, jr_050_66b6

    ret nc

    dec [hl]
    ret


jr_050_66b6:
    ld [hl], $14
    ret


LoadBtl_66b9:
    ld a, $0a
    ld [$0100], a

jr_050_66be:
    ld a, [de]
    ld [hl+], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, jr_050_66be

    ld a, $00
    ld [$0100], a
    ret


ReadBtl_66cc:
jr_050_66cc:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, jr_050_66cc

    ret


LoadArenaEnemyStats:
    ld a, [wColiseumBattle]
    cp $03
    ret z

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
    ld b, a
    add a
    add b
    ld b, a
    ld a, [wColiseumBattle]
    add b
    add a
    ld hl, $6778
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
    call SetTempEnemyStatsId
    ld [$d7ce], a
    ld a, $01
    ld [$d7cf], a
    ld a, [$da05]
    ld l, a
    ld a, [$da06]
    ld h, a
    call SetTempEnemyStatsId
    ld [$d7cc], a
    ld a, $01
    ld [$d7cd], a
    ld a, [$da07]
    ld l, a
    ld a, [$da08]
    ld h, a
    call SetTempEnemyStatsId
    ld [$d7d0], a
    ld a, $01
    ld [$d7d1], a
    ret


SetTempEnemyStatsId:
    ld a, l
    ld [wTempEnemyStatsId], a
    ld a, h
    ld [$da13], a
    ld hl, $1401
    rst $10
    ld a, [$da18]
    add $10
    ret


; ---------------------------------------------------------------
; ArenaMasterSpriteTable50 ($50:$6778) — 27-entry duplicate of the
; bank $04 ArenaMasterSpriteTable ($04:$5E22): per-arena-match master
; lobby sprite [gfx_id, is_monster], groups G..S + Starry Night only
; (no King rows — the King battle never re-enters via bank $50's
; LoadArenaEnemyStats, which is the between-matches regenerator).
; ---------------------------------------------------------------
ArenaMasterSpriteTable50:
    db $0b, $00, $0a, $00, $11, $00  ; G  class: matches 0/1/2
    db $0b, $00, $0a, $00, $da, $01  ; F  class (match2 master = Hargon monster sprite)
    db $0b, $00, $0a, $00, $0b, $00  ; E  class
    db $0b, $00, $0a, $00, $02, $00  ; D  class
    db $0b, $00, $0a, $00, $0b, $00  ; C  class
    db $0b, $00, $0a, $00, $0f, $00  ; B  class
    db $0b, $00, $0a, $00, $0c, $00  ; A  class
    db $0b, $00, $0a, $00, $13, $00  ; S  class
    db $0b, $00, $0a, $00, $14, $00  ; Starry Night Tournament

SetBtl_67ae:
    ld hl, $d7ca
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
    ld a, [wColiseumBattle]
    or a
    jr nz, jr_050_682d

    ld a, $01
    ld [wColiseumBattle], a
    ld a, $02
    ld [$da02], a
    ld a, [$d9d1]
    ld l, a
    ld a, [$d9d2]
    ld h, a
    ld a, l
    ld [wTempEnemyId1], a
    ld a, h
    ld [$da04], a
    call SetTempEnemyStatsId
    ld [$d7ca], a
    ld a, $01
    ld [$d7cb], a
    ld a, [$da02]
    or a
    ret z

    ld a, [$d9d3]
    ld l, a
    ld a, [$d9d4]
    ld h, a
    ld a, l
    ld [$da05], a
    ld a, h
    ld [$da06], a
    call SetTempEnemyStatsId
    ld [$d7cc], a
    ld a, $01
    ld [$d7cd], a
    ld a, [$da02]
    cp $01
    ret z

    ld a, [$d9d5]
    ld l, a
    ld a, [$d9d6]
    ld h, a
    ld a, l
    ld [$da07], a
    ld a, h
    ld [$da08], a
    call SetTempEnemyStatsId
    ld [$d7ce], a
    ld a, $01
    ld [$d7cf], a
    ret


jr_050_682d:
    cp $01
    jr nz, jr_050_6898

    ld a, $02
    ld [wColiseumBattle], a
    ld a, $02
    ld [$da02], a
    ld a, [$d9d9]
    ld l, a
    ld a, [$d9da]
    ld h, a
    ld a, l
    ld [wTempEnemyId1], a
    ld a, h
    ld [$da04], a
    call SetTempEnemyStatsId
    ld [$d7ca], a
    ld a, $01
    ld [$d7cb], a
    ld a, [$da02]
    or a
    ret z

    ld a, [$d9db]
    ld l, a
    ld a, [$d9dc]
    ld h, a
    ld a, l
    ld [$da05], a
    ld a, h
    ld [$da06], a
    call SetTempEnemyStatsId
    ld [$d7cc], a
    ld a, $01
    ld [$d7cd], a
    ld a, [$da02]
    cp $01
    ret z

    ld a, [$d9dd]
    ld l, a
    ld a, [$d9de]
    ld h, a
    ld a, l
    ld [$da07], a
    ld a, h
    ld [$da08], a
    call SetTempEnemyStatsId
    ld [$d7ce], a
    ld a, $01
    ld [$d7cf], a
    ret


jr_050_6898:
    ld a, $03
    ld [wColiseumBattle], a
    ret


ReadBtl_689e:
    ld a, [hl]
    or a
    ret z

    ld a, l
    add $4b
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl]
    cp $63
    jr z, jr_050_68fb

    push af
    ld a, l
    add $01
    ld l, a
    ld a, h
    adc $00
    ld h, a
    pop af
    cp [hl]
    jr nc, jr_050_68fb

    push hl
    ld a, l
    add $b4
    ld l, a
    ld a, h
    adc $ff
    ld h, a
    ld a, [hl]
    pop hl
    cp $01
    jr z, jr_050_68fb

    ld a, [hl]
    push af
    ld a, l
    add $ff
    ld l, a
    ld a, h
    adc $ff
    ld h, a
    pop af
    ld b, [hl]
    ld [hl], a
    push bc
    push hl
    ld a, [$cac0]
    call CmpBtl_6383
    pop hl
    pop bc
    ld [hl], b
    jr c, jr_050_68fb

    ld a, l
    add $02
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ldh a, [$d5]
    sub $01
    ld [hl+], a
    ldh a, [$d6]
    sbc $00
    ld [hl+], a
    ldh a, [$d7]
    sbc $00
    ld [hl], a

jr_050_68fb:
    ret


LoadBtl_68fc:
    ld a, [wBattlePostFlag]
    cp $02
    jr z, jr_050_6913

    cp $01
    jr z, jr_050_690d

    ld d, $00
    ld e, $03
    jr jr_050_6922

jr_050_690d:
    ld d, $03
    ld e, $01
    jr jr_050_6922

jr_050_6913:
    ld a, [$c86c]
    or a
    jr nz, jr_050_691f

    ld d, $00
    ld e, $01
    jr jr_050_6922

jr_050_691f:
    ld de, $0000

jr_050_6922:
    ld hl, $dd13
    ld b, $04
    ld c, $00

jr_050_6929:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_050_6932

    ld [hl], d
    jr jr_050_6934

jr_050_6932:
    ld [hl], $ff

jr_050_6934:
    inc hl
    inc c
    dec b
    jr nz, jr_050_6929

    ld hl, $dd17
    ld b, $04
    ld c, $04

jr_050_6940:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_050_6949

    ld [hl], e
    jr jr_050_694b

jr_050_6949:
    ld [hl], $ff

jr_050_694b:
    inc hl
    inc c
    dec b
    jr nz, jr_050_6940

    ret


    ret


jr_050_6952:
    ld de, $cacd
    ld a, [$c863]
    bit 1, a
    jr nz, jr_050_695f

    ld de, $cd21

jr_050_695f:
    ld hl, $c180
    call Copy4Bytes
    ld a, $01
    ld [$c823], a
    jp Jump_050_6a4f


CallBtl_696d:
    call LoadBtl_6974
    call SetupBattleAction
    ret


LoadBtl_6974:
    ld a, [$c86c]
    or a
    jr nz, jr_050_6952

    ld a, [$da02]
    or a
    jr z, jr_050_69bb

    cp $01
    jr z, jr_050_6999

    ld a, [$dc40]
    ld b, a
    ld a, [$dc41]
    cp b
    jr z, jr_050_69ab

    ld b, a
    ld a, [$dc42]
    cp b
    jr z, jr_050_69b9

    ld a, $05
    jr jr_050_69bb

jr_050_6999:
    ld a, [$dc40]
    ld b, a
    ld a, [$dc41]
    cp b
    jr z, jr_050_69a7

    ld a, $02
    jr jr_050_69bb

jr_050_69a7:
    ld a, $01
    jr jr_050_69bb

jr_050_69ab:
    ld a, [$dc41]
    ld b, a
    ld a, [$dc42]
    cp b
    jr z, jr_050_69a7

    ld a, $03
    jr jr_050_69bb

jr_050_69b9:
    ld a, $04

jr_050_69bb:
    ld [$db4c], a
    ld a, $00
    ld [$db4d], a
    ret


LoadBtl_69c4:
    ld a, $00
    ld [$c822], a
    ld a, [$db4d]
    or a
    jr z, jr_050_69d3

    call LoadBtl_6a26
    ret


jr_050_69d3:
    ld a, [$db4c]
    cp $05
    jr z, jr_050_6a1c

    cp $04
    jr z, jr_050_6a12

    cp $03
    jr z, jr_050_6a08

    cp $02
    jr z, jr_050_69fe

    cp $01
    jr z, jr_050_69f4

    call SetupBattleAction
    ld a, $00
    ld [$c823], a
    jr jr_050_6a4f

jr_050_69f4:
    call SetupBattleAction
    ld a, $01
    ld [$c823], a
    jr jr_050_6a4f

jr_050_69fe:
    call LoadBtl_6a71
    ld a, $02
    ld [$c823], a
    jr jr_050_6a4f

jr_050_6a08:
    call SetupBattleAction
    ld a, $01
    ld [$c823], a
    jr jr_050_6a57

jr_050_6a12:
    call SetupBattleAction
    ld a, $00
    ld [$c823], a
    jr jr_050_6a57

jr_050_6a1c:
    call LoadBtl_6a71
    ld a, $02
    ld [$c823], a
    jr jr_050_6a57

LoadBtl_6a26:
    ld a, [$db4c]
    cp $05
    jr z, jr_050_6a45

    cp $04
    jr z, jr_050_6a3b

    call LoadBtl_6a94
    ld a, $00
    ld [$c823], a
    jr jr_050_6a4f

jr_050_6a3b:
    call LoadBtl_6a88
    ld a, $01
    ld [$c823], a
    jr jr_050_6a4f

jr_050_6a45:
    call LoadBtl_6a94
    ld a, $00
    ld [$c823], a
    jr jr_050_6a4f

Jump_050_6a4f:
jr_050_6a4f:
    call ClrBtl_6aa3
    ld hl, $d9ec
    inc [hl]
    ret


jr_050_6a57:
    call ClrBtl_6aa3
    ld a, $01
    ld [$db4d], a
    ld a, $05
    ld [$da33], a
    ret


SetupBattleAction:
    ld a, $04
    ld hl, $c180
    ld [$db50], a
    call SetBattleTargetData
    ret


LoadBtl_6a71:
    ld a, $04
    ld hl, $c180
    ld [$db50], a
    call SetBattleTargetData
    ld a, $05
    ld hl, $c190
    ld [$db50], a
    call SetBattleTargetData
    ret


LoadBtl_6a88:
    ld a, $05
    ld hl, $c180
    ld [$db50], a
    call SetBattleTargetData
    ret


LoadBtl_6a94:
    ld a, $06
    ld hl, $c180
    ld [$db50], a
    call SetBattleTargetData
    ret


SetTextIdParam:
    ld [$c823], a

ClrBtl_6aa3:
    xor a
    ld [$c822], a
    ld hl, $4c00
    rst $10
    ret


BattlePhase09_TurnSequencer:
    ld a, [$d9ed]            ; phase-9 sub-state
    rst $00

; BattlePhase09SubTable — 6 entries indexed by $D9ED (turn sequencing).
; Re-sectioned S68 from fake instructions (byte-identical; 12 bytes).
BattlePhase09SubTable:
    dw $6abc                 ; sub 0: clear per-combatant status bits $DB00+
    dw $6b11                 ; sub 1
    dw $6b25                 ; sub 2
    dw $6c02                 ; sub 3
    dw $6c9b                 ; sub 4
    dw $6d0c                 ; sub 5
    ld hl, $db00
    res 4, [hl]
    res 6, [hl]
    inc hl
    res 4, [hl]
    res 6, [hl]
    inc hl
    ld b, $08

jr_050_6acb:
    inc hl
    inc hl
    res 7, [hl]
    inc hl
    inc hl
    ld a, [hl]
    rrca
    and $55
    ld [hl+], a
    ld a, [hl]
    and $30
    call nz, ReadBtl_6b06
    inc hl
    ld a, [hl]
    and $c0
    ld [hl+], a
    xor a
    ld [hl+], a
    dec b
    jr nz, jr_050_6acb

    ld b, $08
    xor a

jr_050_6ae9:
    ld [hl+], a
    dec b
    jr nz, jr_050_6ae9

    ld a, [hl]
    and $03
    ld [hl+], a
    ld a, [hl]
    and $03
    ld [hl+], a
    ld hl, $d9ed
    inc [hl]
    xor a
    ld [wBattleAttackerIdx], a
    ld [$d9f2], a
    ld [$d9f3], a
    jr jr_050_6b11

    ret


ReadBtl_6b06:
    ld a, [hl]
    and $cf
    ld e, a
    ld a, [hl]
    rrca
    and $10
    or e
    ld [hl], a
    ret


Jump_050_6b11:
jr_050_6b11:
    ld hl, $d9ed
    inc [hl]
    ld a, [wBattleAttackerIdx]
    call CheckMonsterSlot
    jr nc, jr_050_6b25

    ld a, $05
    ld [$d9ed], a
    jp Jump_050_6d0c


jr_050_6b25:
    ld hl, $d9ed
    inc [hl]
    ld a, [wBattleAttackerIdx]
    ld hl, $db07
    call HL_AddA_x8
    ld a, [hl]
    and $3f
    ld d, a
    ld a, [hl]
    and $c0
    jp z, Jump_050_6b5e

    ld b, $00
    push hl
    push de
    sub $40
    jr nz, jr_050_6b4f

    call SetBtl_7e1e
    ld a, $dd
    call SetTextIdParam
    xor a
    ld b, $01

jr_050_6b4f:
    pop de
    pop hl
    or d
    ld [hl], a
    ld a, $05
    ld [$d9ed], a
    ld a, b
    or a
    jp z, Jump_050_6d0c

    ret


Jump_050_6b5e:
    ld a, [wBattleAttackerIdx]
    ld hl, $db02
    call HL_AddA_x8
    ld a, [hl]
    and $03
    jr nz, jr_050_6b74

    ld a, $05
    ld [$d9ed], a
    jp Jump_050_6d0c


jr_050_6b74:
    bit 0, a
    jr z, jr_050_6b81

    ld a, $e1
    ld [$db4c], a
    ld d, $10
    jr jr_050_6b88

jr_050_6b81:
    ld a, $e2
    ld [$db4c], a
    ld d, $06

jr_050_6b88:
    ld a, [wBattleAttackerIdx]
    call GetCombatantMaxHP
    ld a, d
    call Div16x8To16
    ld a, h
    or l
    jr nz, jr_050_6b99

    ld hl, $0001

jr_050_6b99:
    call LoadBtl_6bc4
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ld a, [wBattleAttackerIdx]
    call SetBtl_7e1e
    ld hl, $c190
    ld a, [$db56]
    ld c, a
    ld a, [$db57]
    ld b, a
    call FormatDecimalDigits
    ld a, [$db4c]
    call SetTextIdParam
    ld a, $05
    ld [$da33], a
    ret


LoadBtl_6bc4:
    ld a, [$db4c]
    cp $e1
    jr z, jr_050_6be7

    ld bc, $001e
    call CmpHLvsBC
    jr c, jr_050_6c01

    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    ld a, $0b
    call Div16x8To16
    add $1e
    ld l, a
    ld h, $00
    jr jr_050_6c01

jr_050_6be7:
    ld bc, $000a
    call CmpHLvsBC
    jr c, jr_050_6c01

    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    ld a, $06
    call Div16x8To16
    add $0a
    ld l, a
    ld h, $00

jr_050_6c01:
    ret


    ld a, [$da33]
    or a
    jr z, jr_050_6c14

    dec a
    ld [$da33], a
    or a
    ret nz

    ld a, $fd
    call SetTextIdParam
    ret


jr_050_6c14:
    ld hl, $d9ed
    inc [hl]
    ld a, [wBattleAttackerIdx]
    ld hl, wBattleHP
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    push hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, [$db56]
    ld c, a
    ld a, [$db57]
    ld b, a
    call CmpHLvsBC
    jr z, jr_050_6c40

    jr c, jr_050_6c40

    ld a, l
    sub c
    ld c, a
    ld a, h
    sbc b
    ld b, a
    jr jr_050_6c43

jr_050_6c40:
    ld bc, $0000

jr_050_6c43:
    pop hl
    ld a, c
    ld [hl+], a
    ld [hl], b
    ld a, b
    or c
    jr z, jr_050_6c59

    call UpdateBattleSprites
    call LoadBtl_7627
    ld a, $05
    ld [$d9ed], a
    jp Jump_050_6d0c


jr_050_6c59:
    ld a, [wBattleAttackerIdx]
    ld [wBattleTargetIdx], a
    ld hl, $5801
    rst $10
    ld a, [wBattleAttackerIdx]
    ld [$db4c], a
    ld hl, $5103
    rst $10
    call BattleDispatchEntry4
    ld a, $04
    ld [$d9ed], a
    ld a, [wBattleAttackerIdx]
    call SetBtl_7e1e
    ld a, $ea
    call SetTextIdParam
    call UpdateBattleSprites
    call LoadBtl_7627
    ld a, [$c86c]
    or a
    ret nz

    ld a, [wBattleAttackerIdx]
    cp $04
    ret c

    cp $07
    ret z

    ld a, [wBattleAttackerIdx]
    ld [$dd61], a
    ret


    ld hl, $d9ed
    inc [hl]
    ld a, [wBattleAttackerIdx]
    and $04
    ld c, a
    ld b, $03
    ld a, [$c86c]
    or a
    jr nz, jr_050_6cd3

    ld a, [wBattleAttackerIdx]
    cp $04
    jr c, jr_050_6cd3

jr_050_6cb4:
    ld a, c
    call CheckMonsterSlot
    jr nc, jr_050_6d0c

    inc c
    dec b
    jr nz, jr_050_6cb4

jr_050_6cbe:
    ld a, $00
    ld [wBattlePostFlag], a

jr_050_6cc3:
    ld a, $0a
    ld [$d9ec], a
    ld a, $02
    call SetBGM
    ld a, $02
    ld [$db4e], a
    ret


jr_050_6cd3:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_050_6ce4

    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    bit 6, [hl]
    jr z, jr_050_6d0c

jr_050_6ce4:
    inc c
    dec b
    jr nz, jr_050_6cd3

    ld a, $01
    ld [wBattlePostFlag], a
    ld a, [$c86c]
    or a
    jr z, jr_050_6cc3

    ld a, [$c863]
    bit 1, a
    jr z, jr_050_6d03

    ld a, [wBattleAttackerIdx]
    cp $04
    jr nc, jr_050_6cc3

    jr jr_050_6cbe

jr_050_6d03:
    ld a, [wBattleAttackerIdx]
    cp $04
    jr c, jr_050_6cc3

    jr jr_050_6cbe

Jump_050_6d0c:
jr_050_6d0c:
    ld hl, wBattleAttackerIdx
    inc [hl]
    ld a, [hl]
    cp $08
    jr z, jr_050_6d22

    call CheckMonsterSlot
    jr c, jr_050_6d0c

    ld a, $01
    ld [$d9ed], a
    jp Jump_050_6b11


jr_050_6d22:
    ld bc, $0300
    ld de, $0001
    ld hl, $dd13
    ld a, [$c86c]
    or a
    jr z, jr_050_6d33

    ld e, $00

jr_050_6d33:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_050_6d3c

    ld [hl], d
    jr jr_050_6d3e

jr_050_6d3c:
    ld [hl], $ff

jr_050_6d3e:
    inc hl
    inc c
    dec b
    jr nz, jr_050_6d33

    ld a, c
    call CheckMonsterSlot
    jr c, jr_050_6d4b

    ld [hl], $01

jr_050_6d4b:
    inc hl
    inc c
    ld bc, $0304

jr_050_6d50:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_050_6d59

    ld [hl], e
    jr jr_050_6d5b

jr_050_6d59:
    ld [hl], $ff

jr_050_6d5b:
    inc hl
    inc c
    dec b
    jr nz, jr_050_6d50

    ld a, c
    call CheckMonsterSlot
    jr c, jr_050_6d68

    ld [hl], $01

jr_050_6d68:
    inc hl
    inc c
    ld a, $03
    ld [$d9ec], a
    ld hl, $db76
    ld a, [hl]
    cp $ff
    ret z

    inc [hl]
    ret


LoadBtl_6d78:
    ld a, [$cab5]
    inc a
    ld [$cab5], a
    cp $3c
    ret nz

    xor a
    ld [$cab5], a
    ld a, [$cab6]
    inc a
    ld [$cab6], a
    cp $3c
    ret nz

    xor a
    ld [$cab6], a
    ld a, [$cab7]
    inc a
    ld [$cab7], a
    cp $3c
    ret nz

    xor a
    ld [$cab7], a
    ld a, [$cab8]
    inc a
    ld [$cab8], a
    cp $64
    ret nz

    ld a, $63
    ld [$cab8], a
    ld a, $3b
    ld [$cab7], a
    ld [$cab6], a
    xor a
    ld [$cab5], a
    ret


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $70
    ld [hl], c
    ld [hl], d
    ld [hl], e
    jp c, Jump_050_74e0

    ld [hl], l
    db $76
    ld [hl], a
    db $db
    ldh [$78], a
    ld a, c
    ld a, d
    ld a, e
    call c, $ffe0
    ret c

    db $ec
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $ed
    ret c

    cp $e1
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e1], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e1], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e2
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e2], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e2], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $70
    ld [hl], c
    ld [hl], d
    ld [hl], e
    jp c, Jump_050_74e0

    ld [hl], l
    db $76
    ld [hl], a
    db $db
    ldh [rIE], a
    ret c

    db $ec
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $ed
    ret c

    cp $e1
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e1], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e2
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e2], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $70
    ld [hl], c
    ld [hl], d
    ld [hl], e
    jp c, $ffe0

    ret c

    db $ec
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $ed
    ret c

    cp $e1
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e2
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    and b
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    add l
    add [hl]
    add a
    adc b
    adc c
    ldh [$86], a
    adc c
    adc d
    adc e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld a, h
    add c
    add b
    ld a, a
    ldh [$e0], a
    ld a, l
    ld a, [hl]
    ld a, a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    and b
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sbc d
    add d
    sbc e
    add d
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sub d
    sub e
    sub h
    add h
    sbc h
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    nop
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $6c
    ld l, l
    ld l, [hl]
    ld l, a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    db $fd
    reti


    jr nz, @+$03

    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sub [hl]
    adc b
    sub c
    adc l
    add a
    adc d
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    adc e
    add [hl]
    sub h
    adc d
    sub l
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sub [hl]
    sub c
    adc [hl]
    adc c
    add [hl]
    sub b
    adc [hl]
    adc h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sub [hl]
    sub b
    adc e
    adc e
    sub c
    adc a
    sub l
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    jr nz, @+$03

    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    adc h
    adc l
    adc [hl]
    adc a
    sub b
    sub c
    sub d
    sub e
    sub h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sub l
    sub [hl]
    sub a
    sbc b
    sbc c
    sbc d
    sbc e
    sbc h
    sbc l
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sbc [hl]
    sbc a
    and b
    and c
    and d
    and e
    and h
    and l
    and [hl]
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    and a
    xor b
    xor c
    xor d
    xor e
    xor h
    xor l
    xor [hl]
    xor a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    ld h, b
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    add l
    add [hl]
    add a
    ldh [rIE], a
    ret c

    db $ec
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $ed
    ret c

    cp $e0
    ld a, [hl]
    add h
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    adc b
    add a
    adc c
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    jr nz, @+$03

    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    add l
    add [hl]
    add a
    ldh [rIE], a
    ret c

    db $ec
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $ed
    ret c

    cp $e0
    ld [hl], b
    ld [hl], c
    ld [hl], d
    ld [hl], e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld [hl], h
    ld [hl], l
    db $76
    ld [hl], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld a, b
    ld a, c
    ld a, d
    ld a, e
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    jr nz, @+$03

    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    add [hl]
    adc b
    add a
    ldh [rIE], a
    ret c

    db $ec
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $ed
    ret c

    cp $e0
    ld [hl], b
    ld [hl], c
    ld [hl], d
    ld [hl], e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld [hl], h
    ld [hl], l
    db $76
    ld [hl], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld a, b
    ld a, c
    ld a, d
    ld a, e
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    ld h, b
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    adc h
    adc l
    adc [hl]
    adc a
    sub b
    sub c
    sub d
    sub e
    sub h
    sub l
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sub [hl]
    sub a
    sbc b
    sbc c
    sbc d
    sbc e
    sbc h
    sbc l
    sbc [hl]
    sbc a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    and b
    and c
    and d
    and e
    and h
    and l
    and [hl]
    and a
    xor b
    xor c
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    nop
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    call nc, $d5e0
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    push de
    push de
    sub $ff
    ret c

    db $fc
    xor $ee
    xor $ee
    db $fd
    reti


    ld c, b
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    ld [hl], $37
    jr c, jr_050_71ea

    ld a, [hl-]
    dec sp
    inc a
    dec a
    ld a, $ff
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ccf
    ld b, b
    ld b, c
    ld b, d
    ld b, e
    ld b, h
    ld b, l
    ld b, [hl]
    ld b, a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ld c, b
    ld c, c
    ld c, d
    ld c, e
    ld c, h
    ld c, l
    ld c, [hl]
    ld c, a
    ld d, b

jr_050_71ea:
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ld d, c
    ld d, d
    ld d, e
    ld d, h
    ld d, l
    ld d, [hl]
    ld d, a
    ld e, b
    ld e, c
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    ld c, $01
    ld a, [$efef]
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    call nc, $d6d5
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sbc l
    sbc [hl]
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    db $fd
    reti


    ld b, b
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    add d
    add e
    add h
    ldh [rIE], a
    ret c

    db $ec
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $ed
    ret c

    cp $e0
    adc h
    adc l
    adc [hl]
    adc a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sub b
    sub c
    sub d
    sub e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sub h
    sub l
    sub [hl]
    sub a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sbc b
    sbc c
    sbc d
    sbc e
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    dec c
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    add l
    add [hl]
    add a
    adc b
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    adc c
    adc d
    ldh [$e0], a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    jr nz, @+$03

    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    add d
    add e
    add h
    ldh [rIE], a
    ret c

    db $ec
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $ed
    ret c

    cp $e0
    ld [hl], b
    ld [hl], c
    ld [hl], d
    ld [hl], e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld [hl], h
    ld [hl], l
    db $76
    ld [hl], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld a, b
    ld a, c
    ld a, d
    ld a, e
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    ld h, b
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $00
    ld bc, $0302
    inc b
    dec b
    ld b, $07
    ld [$0a09], sp
    dec bc
    inc c
    dec c
    ld c, $0f
    db $10
    ld de, $d8ff
    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $12
    inc de
    inc d
    dec d
    ld d, $17
    jr @+$1b

    ld a, [de]
    dec de
    inc e
    dec e
    ld e, $1f
    jr nz, jr_050_7379

    ld [hl+], a
    inc hl
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $24
    dec h
    ld h, $27
    jr z, jr_050_73a1

    ld a, [hl+]

jr_050_7379:
    dec hl
    inc l
    dec l
    ld l, $2f
    jr nc, jr_050_73b1

    ld [hl-], a
    inc sp
    inc [hl]
    dec [hl]
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    ret nz

    nop
    ld a, [$efef]
    rst $28

jr_050_73a1:
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $9c
    sub $d5
    ldh [$e2], a
    db $e3
    ldh [rIE], a
    ret c

jr_050_73b1:
    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    push hl
    ldh [$e0], a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    ld c, $01
    ld a, [$efef]
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    and b
    and c
    and d
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    and e
    and h
    and l
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    db $fd
    reti


    add b
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    inc h
    dec h
    ld h, $27
    jr z, @+$2b

    ld a, [hl+]
    dec hl
    inc l
    ld c, b
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    dec l
    ld l, $2f
    jr nc, jr_050_7458

    ld [hl-], a
    inc sp
    inc [hl]
    dec [hl]
    ld c, c
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld [hl], $37
    jr c, jr_050_747b

    ld a, [hl-]
    dec sp
    inc a
    dec a
    ld a, $4a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

jr_050_7458:
    cp $e0
    ccf
    ld b, b
    ld b, c
    ld b, d
    ld b, e
    ld b, h
    ld b, l
    ld b, [hl]
    ld b, a
    ld c, e
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    inc c
    ld bc, $effa
    rst $28
    rst $28
    rst $28

jr_050_747b:
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    and [hl]
    and a
    xor b
    xor c
    xor d
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    adc c
    adc d
    ldh [$e0], a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    ret nz

    nop
    ld a, [$efef]
    rst $28
    rst $28
    ei
    ret c

    cp $6c
    ld l, l
    ld l, [hl]
    ld l, a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    db $fd
    reti


    ld h, b
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    add b
    adc c
    add d
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    add h
    add d
    add [hl]
    add c
    rst $38
    ret c

    cp $e0
    ldh [$e0], a

Jump_050_74e0:
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    add e
    adc d
    add l
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    jr nz, @+$03

    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    adc h
    adc l
    adc [hl]
    adc a
    sub b
    sub c
    sub d
    sub e
    sub h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sub l
    sub [hl]
    sub a
    sbc b
    sbc c
    sbc d
    sbc e
    sbc h
    sbc l
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sbc [hl]
    sbc a
    and b
    and c
    and d
    and e
    and h
    and l
    and [hl]
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    and a
    xor b
    xor c
    xor d
    xor e
    xor h
    xor l
    xor [hl]
    xor a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


SaveBtl_756b:
    push af
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
    pop af
    ret


LoadBtl_757a:
    ld a, [$d9f8]
    add l
    ld l, a
    ld a, [$d9f9]
    adc h
    and $03
    ld h, a
    ld a, [$d9f9]
    and $fc
    or h
    ld h, a
    ret


AdjustBattlePointerHL:
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    ret


SaveBtl_7597:
    push bc
    ld b, l
    ld a, l
    and $e0
    ld l, a
    call LoadBtl_757a
    ld a, b
    and $1f
    jr z, jr_050_75ac

    ld b, a

jr_050_75a6:
    call SaveBtl_756b
    dec b
    jr nz, jr_050_75a6

jr_050_75ac:
    pop bc
    ret


    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld h, a
    inc de
    call SaveBtl_7597
    ld a, l
    ld [$d9ea], a
    ld a, h
    ld [$d9eb], a

jr_050_75bf:
    ld a, [de]
    inc de
    cp $d9
    ret z

    cp $d8
    jr nz, jr_050_75e8

    ld a, [$d9ea]
    ld l, a
    ld a, [$d9eb]
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
    ld [$d9ea], a
    ld a, h
    ld [$d9eb], a
    jr jr_050_75bf

jr_050_75e8:
    call Write_gfx_tile
    call SaveBtl_756b
    jr jr_050_75bf

LoadPaletteFromDE:
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld h, a
    inc de
    call AdjustBattlePointerHL
    ld a, l
    ld [$d9ea], a
    ld a, h
    ld [$d9eb], a

jr_050_7601:
    ld a, [de]
    inc de
    cp $d9
    ret z

    cp $d8
    jr nz, jr_050_7624

    ld a, [$d9ea]
    ld l, a
    ld a, [$d9eb]
    ld h, a
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ld [$d9ea], a
    ld a, h
    ld [$d9eb], a
    jr jr_050_7601

jr_050_7624:
    ld [hl+], a
    jr jr_050_7601

LoadBtl_7627:
    ld a, [$db74]
    ld c, a
    ld a, [$c863]
    bit 1, a
    jr z, jr_050_7636

    ld a, [$db75]
    ld c, a

jr_050_7636:
    push bc
    ld b, $25
    ld c, $62
    call BtlFunc_7656
    pop bc
    dec c
    ret z

    push bc
    ld b, $2b
    ld c, $68
    call BtlFunc_7656
    pop bc
    dec c
    ret z

    push bc
    ld b, $31
    ld c, $6e
    call BtlFunc_7656
    pop bc
    ret


BtlFunc_7656:
    ld l, b
    ld h, $98
    ld a, b
    ld de, $c500
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    call Write_gfx_tile
    ld b, $03
    ld l, c
    ld h, $98
    ld a, c
    ld de, $c500
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    call LoadBtl_76b2
    ld b, $03
    ld a, c
    add $20
    ld l, a
    ld h, $98
    ld de, $c500
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    call LoadBtl_76b2
    ret


ClearTileBuffer:
    ld a, [$d9f8]
    ld l, a
    ld a, [$d9f9]
    ld h, a
    ld de, $c500
    ld c, $12

jr_050_769b:
    ld b, $20
    push hl
    call LoadBtl_76b2
    pop hl
    push bc
    ld bc, $0020
    add hl, bc
    ld a, h
    and $03
    or $98
    ld h, a
    pop bc
    dec c
    jr nz, jr_050_769b

    ret


LoadBtl_76b2:
jr_050_76b2:
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
    jr nz, jr_050_76b2

    ret


LoadBtl_76c7:
    ld a, [$c827]
    ld c, a
    ld a, [$c828]
    ld b, a
    push bc
    ld a, [$c829]
    ld c, a
    ld a, [$c82a]
    ld b, a
    push bc
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld hl, $4102
    rst $10
    pop de
    pop hl
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ret


SaveBtl_7700:
    push hl
    ld hl, $c180
    call Copy4Bytes
    pop hl
    ld a, [$c827]
    ld c, a
    ld a, [$c828]
    ld b, a
    push bc
    ld a, [$c829]
    ld c, a
    ld a, [$c82a]
    ld b, a
    push bc
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld de, $0401
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld a, $02
    ld [$c822], a
    ld a, $00
    ld [$c823], a
    ld hl, $4102
    rst $10
    pop de
    pop hl
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ret


ClearSpriteBuffer:
    ld hl, $c500
    ld bc, $0240

jr_050_7754:
    ld a, $e0
    ld [hl+], a
    dec bc
    ld a, b
    or c
    jr nz, jr_050_7754

    ret


    ld hl, $9800
    ld bc, $0400

jr_050_7763:
    ld a, $e0
    call Write_gfx_tile_and_inc_HL
    dec bc
    ld a, b
    or c
    jr nz, jr_050_7763

    ret


LoadBtl_776e:
    ld a, c
    ld [$c8e1], a
    inc de
    inc de
    ld a, [$c825]
    or a
    jp nz, Jump_050_77d5

    ld a, [wJoypad_Current]
    bit 5, a
    jr z, jr_050_779b

    inc hl
    ld a, [hl]
    dec a
    push af
    push de
    push bc
    ld a, b
    ld b, c
    dec b
    call Div8x8
    ld a, b
    inc a
    pop bc
    pop de
    ld c, a
    pop af
    cp c
    jr c, jr_050_77b9

    ld a, c
    dec a
    jr jr_050_77b9

jr_050_779b:
    ld a, [wJoypad_Current]
    bit 4, a
    jr z, jr_050_77d5

    inc hl
    ld a, [hl]
    inc a
    push af
    push de
    push bc
    ld a, b
    ld b, c
    dec b
    call Div8x8
    ld a, b
    inc a
    pop bc
    pop de
    ld c, a
    pop af
    cp c
    jr c, jr_050_77b9

    ld a, $00

jr_050_77b9:
    ld [hl-], a
    dec c
    cp c
    jr nz, jr_050_7818

    ld a, [$c8e1]
    ld c, a
    push de
    push bc
    ld a, b
    ld b, c
    call Div8x8
    pop bc
    pop de
    or a
    jr z, jr_050_7818

    dec a
    cp [hl]
    jr nc, jr_050_7818

    ld [hl], a
    jr jr_050_7818

Jump_050_77d5:
jr_050_77d5:
    push bc
    push de
    push hl
    call LoadBtl_78b0
    pop hl
    pop de
    pop bc
    push de
    push bc
    ld a, b
    ld b, c
    dec b
    call Div8x8
    ld [$c8e1], a
    ld a, b
    pop bc
    pop de
    ld c, a
    inc hl
    ld a, [hl-]
    cp c
    jr nz, jr_050_77f7

    ld a, [$c8e1]
    inc a
    ld b, a

BtlFunc_77f7:
jr_050_77f7:
    res 7, [hl]
    ld a, [wJoypad_Current]
    bit 6, a
    jr z, jr_050_7809

    ld a, [hl]
    dec a
    cp b
    jr c, jr_050_7817

    dec b
    ld a, b
    jr jr_050_7817

jr_050_7809:
    ld a, [wJoypad_Current]
    bit 7, a
    jr z, jr_050_7820

    ld a, [hl]
    inc a
    cp b
    jr c, jr_050_7817

    ld a, $00

Jump_050_7817:
jr_050_7817:		
    ld [hl], a		;load value a into curent menu option

jr_050_7818:
    xor a
    ld [$d9fb], a
    push hl
    push de
    pop de
    pop hl

Jump_050_7820:
jr_050_7820:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jr z, jr_050_7829

    set 7, [hl]

jr_050_7829:
    ld a, [hl]
    call BtlFunc_784d
    ret


BtlFunc_782e:
    res 7, [hl]
    ld a, [wJoypad_Current]
    and $c0
    jr z, jr_050_783c

    ld a, [hl]
    xor $01
    jr jr_050_7817

jr_050_783c:
    ld a, [wJoypad_Current]
    and $30
    jr z, jr_050_7820

    ld a, [hl]
    xor $02
    jr jr_050_7817

ClearBattleTurnFlag:
    xor a
    ld [$d9fb], a
    ret


BtlFunc_784d:
    ld c, a
    bit 7, a
    jr nz, jr_050_7862

    ld a, [$d9fb]
    and $0f
    push af
    ld a, [$d9fb]
    inc a
    ld [$d9fb], a
    pop af
    ld a, c
    ret nz

jr_050_7862:
    ld c, a
    ld b, $00

jr_050_7865:
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld h, a
    inc de
    and l
    cp $ff
    ret z

    ld a, l
    ld [$d9ea], a
    ld a, h
    ld [$d9eb], a
    push de
    push bc
    call SaveBtl_7597
    pop bc
    pop de
    ld a, c
    and $7f
    cp b
    ld a, $e0
    jr nz, jr_050_7897

    ld a, $e9
    bit 7, c
    jr nz, jr_050_7897

    ld a, [$d9fb]
    bit 4, a
    ld a, $e0
    jr nz, jr_050_7897

    ld a, $e8

jr_050_7897:
    call Write_gfx_tile
    push af
    ld a, [$d9ea]
    ld l, a
    ld a, [$d9eb]
    ld h, a
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    pop af
    ld [hl], a
    inc b
    jr jr_050_7865

LoadBtl_78b0:
    ld a, b
    cp c
    ret nc

    inc hl
    ld c, [hl]
    dec de
    dec de
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld h, a
    inc de
    and l
    cp $ff
    ret z

    dec hl
    ld a, l
    ldh [$d5], a
    ld a, h
    ldh [$d6], a
    push de
    push bc
    call SaveBtl_7597
    pop bc
    pop de
    ld a, c
    and $7f
    add $f1
    call Write_gfx_tile
    push af
    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
    ld h, a
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    pop af
    ld [hl], a
    ret


ReadBtl_78e9:
    ld a, [hl+]
    push af
    push hl
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    inc de
    ld h, a
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    ld a, b
    cp c
    ld a, $ee
    jr nc, jr_050_7902

    ld a, $e7

jr_050_7902:
    ld [hl-], a
    pop bc
    jr nc, jr_050_790a

    ld a, [bc]
    add $f1
    ld [hl], a

jr_050_790a:
    pop af

CalcBattleTableIndex:
    ld c, a
    add a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld h, a
    ld a, l
    ld [$d9ea], a
    ld a, h
    ld [$d9eb], a
    push de
    push bc
    call SaveBtl_7597
    pop bc
    pop de
    ld a, $e9
    bit 7, c
    jr nz, jr_050_7938

    ld a, [$d9fb]
    bit 4, a
    ld a, $e0
    jr nz, jr_050_7938

    ld a, $e8

jr_050_7938:
    push af
    ld a, [$d9ea]
    ld l, a
    ld a, [$d9eb]
    ld h, a
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    pop af
    ld [hl], a
    ret


LoadBattleGraphics:
    ld a, [$c86c]
    or a
    jr z, jr_050_795e

    ld a, [$c863]
    bit 1, a
    jr z, jr_050_795e

    ld a, [$db74]
    jr jr_050_7961

jr_050_795e:
    ld a, [$db75]

jr_050_7961:
    cp $03
    jr z, jr_050_7981

    cp $02
    jr z, jr_050_7972

    ld a, $00
    ld hl, $00c7
    call ProcessBattleSpriteRow
    ret


jr_050_7972:
    ld a, $00
    ld hl, $00c4
    call ProcessBattleSpriteRow
    ld hl, $00ca
    call ProcessBattleSpriteRow
    ret


jr_050_7981:
    ld a, $00
    ld hl, $00c1
    call ProcessBattleSpriteRow
    ld hl, $00c7
    call ProcessBattleSpriteRow
    ld hl, $00cd
    call ProcessBattleSpriteRow
    ret


ProcessBattleSpriteRow:
    ld c, $06

jr_050_7998:
    push hl
    push af
    call AdjustBattlePointerHL
    pop af
    ld b, $06

jr_050_79a0:
    ld [hl+], a
    inc a
    dec b
    jr nz, jr_050_79a0

    pop hl
    ld de, $0020
    add hl, de
    dec c
    jr nz, jr_050_7998

    ret


SetBtl_79ae:
    ld de, $2e07
    call LoadPaletteFromDE

UpdateBattleSprites:
    ld a, [$d9f3]
    or a
    jp nz, Jump_050_7a87

LoadBtl_79bb:
    ld a, [$c86c]
    or a
    jr nz, jr_050_79c6

    ld a, [$ca8d]
    or a
    ret z

jr_050_79c6:
    call SetBtl_79cb
    jr jr_050_79eb

SetBtl_79cb:
    ld hl, $7a7f
    ld a, [$c863]
    bit 1, a
    jr z, jr_050_79da

    ld a, [$db75]

Jump_050_79d8:
    jr jr_050_79dd

jr_050_79da:
    ld a, [$db74]

jr_050_79dd:
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld e, [hl]
    inc hl
    ld d, [hl]
    call LoadPaletteFromDE
    ret


jr_050_79eb:
    ld hl, wBattleHP
    ld a, [$c863]
    bit 1, a
    jr z, jr_050_79f8

    ld hl, $dbab

jr_050_79f8:
    push hl
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld hl, $0062
    call AdjustBattlePointerHL
    call FillMemory
    pop hl
    ld bc, $0020
    add hl, bc
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld hl, $0082
    call AdjustBattlePointerHL
    call FillMemory
    ld a, [$c1d9]
    cp $01
    ret z

    ld hl, $dba5
    ld a, [$c863]
    bit 1, a
    jr z, jr_050_7a29

    ld hl, $dbad

jr_050_7a29:
    push hl
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld hl, $0068
    call AdjustBattlePointerHL
    call FillMemory
    pop hl
    ld bc, $0020
    add hl, bc
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld hl, $0088
    call AdjustBattlePointerHL
    call FillMemory
    ld a, [$c1d9]
    cp $02
    ret z

    ld hl, $dba7
    ld a, [$c863]
    bit 1, a
    jr z, jr_050_7a5a

    ld hl, $dbaf

jr_050_7a5a:
    push hl
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld hl, $006e
    call AdjustBattlePointerHL
    call FillMemory
    pop hl
    ld bc, $0020
    add hl, bc
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld hl, $008e
    call AdjustBattlePointerHL
    call FillMemory
    ret


    db $eb
    ld a, c
    ld d, $7a
    ld b, a
    ld a, d
    sbc d
    ld l, [hl]
    sbc d
    ld l, [hl]
    ld a, $6e
    cp [hl]
    ld l, l

CmpBtl_7a87:
Jump_050_7a87:
    cp $03
    jp z, Jump_050_7b8f

    call SetBtl_79cb
    ld hl, $9800
    ld a, l
    ld [$d9f8], a
    ld a, h
    ld [$d9f9], a
    ld a, [$c1d9]
    ld b, a
    ld c, $00
    ld a, [$c863]
    bit 1, a
    jr z, jr_050_7aa9

    ld c, $04

jr_050_7aa9:
    ld hl, $7bee
    call $7c06
    push hl
    ld a, c
    call CheckMonsterSlot
    jr nc, jr_050_7aba

    ld a, $d9
    jr jr_050_7abc

jr_050_7aba:
    ld a, $e0

jr_050_7abc:
    pop hl
    ld [hl], a
    ld hl, $7bf4
    call $7c06
    ld [hl], $de
    inc hl
    ld a, $e4
    ld [hl-], a
    ld a, $20
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $e0
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl], a
    inc c
    dec b
    jr nz, jr_050_7aa9

    ld a, [$d9f3]
    cp $02
    jr z, jr_050_7b0a

    call ClearTileBuffer
    ld hl, $8da0
    ld a, $02
    call SaveBtl_7c2a
    ld hl, $8db0
    ld a, $04
    call SaveBtl_7c2a
    ld hl, $8dc0
    ld a, $06
    call SaveBtl_7c2a
    ld hl, $8dd0
    ld a, $03
    call SaveBtl_7c2a
    ld hl, $d9f3
    inc [hl]

jr_050_7b0a:
    ld a, [$c1d9]
    ld b, a
    ld c, $00
    ld a, [$c863]
    bit 1, a
    jr z, jr_050_7b19

    ld c, $04

jr_050_7b19:
    ld hl, $7bf4
    call $7c06
    inc hl
    inc hl
    push bc
    ld a, c
    ld bc, $db9b
    add c
    ld c, a
    ld a, $00
    adc b
    ld b, a
    ld a, [bc]
    ld c, a
    ld b, $00
    call CopyHLtoDE
    pop bc
    ld a, c
    call CheckMonsterSlot
    jr c, jr_050_7b87

    ld hl, $7bfa
    call $7c06
    push hl
    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    pop de
    ld a, [hl]
    or a
    jr z, jr_050_7b87

    bit 6, [hl]
    jr z, jr_050_7b56

    ld a, $00
    call LookupBattleTable

jr_050_7b56:
    inc de
    bit 5, [hl]
    jr z, jr_050_7b60

    ld a, $01
    call LookupBattleTable

jr_050_7b60:
    inc de
    bit 4, [hl]
    jr z, jr_050_7b6a

    ld a, $02
    call LookupBattleTable

jr_050_7b6a:
    inc de
    bit 7, [hl]
    jr z, jr_050_7b74

    ld a, $03
    call LookupBattleTable

jr_050_7b74:
    inc de
    bit 1, [hl]
    jr z, jr_050_7b7e

    ld a, $04
    call LookupBattleTable

jr_050_7b7e:
    bit 0, [hl]
    jr z, jr_050_7b87

    ld a, $05
    call LookupBattleTable

jr_050_7b87:
    inc c
    dec b
    jr nz, jr_050_7b19

    call ClearTileBuffer
    ret


LoadBtl_7b8f:
Jump_050_7b8f:
    ld a, [$c1d9]
    ld b, a
    ld c, $00
    ld a, [$c863]
    bit 1, a
    jr z, jr_050_7b9e

    ld c, $04

jr_050_7b9e:
    ld hl, $7bee
    call $7c06
    ld a, c
    and $03
    add $da
    ld [hl], a
    ld hl, $7bf4
    call $7c06
    ld [hl], $e1
    ld a, $20
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $e2
    ld [hl+], a
    ld a, $e0
    ld [hl+], a
    ld [hl+], a
    ld [hl], a
    ld a, c
    ld [wBattleAttackerIdx], a
    ld [wBattleTargetIdx], a
    push af
    push bc
    push de
    push hl
    ld hl, $da0a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $ff
    call BattleDispatchEntry4
    pop hl
    pop de
    pop bc
    pop af
    inc c
    dec b
    jr nz, jr_050_7b9e

    xor a
    ld [$d9f3], a
    call LoadBtl_79bb
    call ClearTileBuffer
    ret


    dec h
    nop
    dec hl
    nop
    ld sp, $6100
    nop
    ld h, a
    nop
    ld l, l
    nop
    add c
    nop
    add a
    nop
    adc l
    nop
    call c, $dbd7
    db $dd
    jp c, Jump_050_79d8

    and $03
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    ret


LookupBattleTable:
    push hl
    ld hl, $7c00
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [de], a
    pop hl
    ret


SaveBtl_7c2a:
    push hl
    ld hl, $7c3d
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld e, [hl]
    inc hl
    ld d, [hl]
    pop hl
    call WaitDMATransfer
    ret


    ld [bc], a
    ld e, e
    inc bc
    ld e, e
    inc b
    ld e, e
    dec b
    ld e, e
    ld b, $5b
    rlca
    ld e, e
    ld [$095b], sp
    ld e, e

BattleDispatchEntry4:
    ld a, [$c86c]
    or a
    jr z, jr_050_7c73

    ld a, [$c863]
    bit 1, a
    jr z, jr_050_7c73

    ld a, [wBattleTargetIdx]
    ld c, a
    cp $04
    jr c, jr_050_7c67

    cp $07
    ret z

    jr jr_050_7c84

jr_050_7c67:
    ld a, [wBattleAttackerIdx]
    ld c, a
    cp $04
    ret c

    cp $07
    ret z

    jr jr_050_7c84

jr_050_7c73:
    ld a, [wBattleTargetIdx]
    ld c, a
    cp $03
    jr c, jr_050_7c86

    ld a, [wBattleAttackerIdx]
    ld c, a
    cp $03
    jr c, jr_050_7c86

    ret


jr_050_7c84:
    xor $04

jr_050_7c86:
    push de
    swap a
    ld hl, $8da0
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    push hl
    ld a, c
    call CheckMonsterSlot
    jr c, jr_050_7cbc

    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    bit 6, [hl]
    jr nz, jr_050_7cc0

    bit 5, [hl]
    jr nz, jr_050_7cc4

    bit 4, [hl]
    jr nz, jr_050_7cc8

    bit 7, [hl]
    jr nz, jr_050_7ccc

    bit 1, [hl]
    jr nz, jr_050_7cd0

    bit 0, [hl]
    jr nz, jr_050_7cd4

    ld a, $00
    jr jr_050_7cd6

jr_050_7cbc:
    ld a, $07
    jr jr_050_7cd6

jr_050_7cc0:
    ld a, $06
    jr jr_050_7cd6

jr_050_7cc4:
    ld a, $05
    jr jr_050_7cd6

jr_050_7cc8:
    ld a, $04
    jr jr_050_7cd6

jr_050_7ccc:
    ld a, $03
    jr jr_050_7cd6

jr_050_7cd0:
    ld a, $02
    jr jr_050_7cd6

jr_050_7cd4:
    ld a, $01

jr_050_7cd6:
    push af
    ld a, c
    ld hl, $da0a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld d, [hl]
    pop af
    cp d
    call nz, WriteBtl_7ced
    pop hl
    call nz, SaveBtl_7c2a
    pop de
    ret


WriteBtl_7ced:
    ld [hl], a
    ret


    ld a, [wIsGBC]
    or a
    ret z

    ld a, $01
    ldh [rVBK], a
    ld a, [$d9f8]
    ld l, a
    ld a, [$d9f9]
    ld h, a
    ld c, $12

jr_050_7d02:
    ld b, $20
    push hl

jr_050_7d05:
    ld a, $00
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
    dec b
    jr nz, jr_050_7d05

    pop hl
    push bc
    ld bc, $0020
    add hl, bc
    ld a, h
    and $03
    or $98
    ld h, a
    pop bc
    dec c
    jr nz, jr_050_7d02

    ld a, $00
    ldh [rVBK], a
    ret


CheckSlotUnder3:
    cp $03
    jr nc, jr_050_7d4c

SaveBtl_7d32:
jr_050_7d32:
    push hl
    ld hl, $cac2
    call GetCurrentMonsterPtr
    ld e, l
    ld d, h
    pop hl
    push hl
    call Copy4Bytes
    pop hl

jr_050_7d41:
    ld a, [hl]
    cp $f0
    ret z

    inc hl
    jr jr_050_7d41

jr_050_7d48:
    ld a, b
    pop bc
    jr jr_050_7d32

jr_050_7d4c:
    push bc
    ld b, a
    and $03
    cp $03
    ld a, b
    pop bc
    jr z, jr_050_7d75

    push bc
    ld b, a
    ld a, [$c86c]
    or a
    jr nz, jr_050_7d48

    push hl
    ld a, b
    and $03
    ld hl, $c1ca
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    pop hl
    cp $ff
    jr nz, jr_050_7d72

    ld a, b

jr_050_7d72:
    pop bc
    jr nz, jr_050_7d9d

jr_050_7d75:
    push af
    call SetBattleTargetData
    pop af
    ld hl, $5104
    rst $10
    ret


SetBattleTargetData:
    ld [$db60], a
    push hl
    ld hl, $dc3c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld l, a
    ld h, $05
    pop de
    ld a, e
    ld [$db5e], a
    ld a, d
    ld [$db5f], a
    call SetupVRAMParams
    ret


jr_050_7d9d:
    call SaveBtl_7d32
    ld a, $2f
    ld [hl+], a
    ld a, $46
    ld [hl+], a
    ld a, $48
    ld [hl+], a
    ld a, $42
    ld [hl+], a
    ld [hl], $f0
    push hl
    ld hl, $c1ca
    ld a, [$db50]
    and $03
    cp $01
    jr z, jr_050_7dc9

    cp $02
    jr z, jr_050_7dd3

    ld a, [hl+]
    cp [hl]
    jr z, jr_050_7def

    inc hl
    cp [hl]
    jr z, jr_050_7def

    jr jr_050_7dfe

jr_050_7dc9:
    ld a, [hl+]
    cp [hl]
    jr z, jr_050_7df4

    ld a, [hl+]
    cp [hl]
    jr z, jr_050_7def

    jr jr_050_7dfe

jr_050_7dd3:
    ld d, $00
    inc hl
    inc hl
    ld a, [hl-]
    dec hl
    cp [hl]
    jr nz, jr_050_7ddd

    inc d

jr_050_7ddd:
    inc hl
    cp [hl]
    jr nz, jr_050_7de2

    inc d

jr_050_7de2:
    ld a, d
    or a
    jr z, jr_050_7dfe

    cp $01
    jr z, jr_050_7df4

    pop hl
    ld a, $03
    jr jr_050_7df7

jr_050_7def:
    pop hl
    ld a, $01
    jr jr_050_7df7

jr_050_7df4:
    pop hl
    ld a, $02

jr_050_7df7:
    ld [$db4d], a
    ld [hl+], a
    ld [hl], $f0
    ret


jr_050_7dfe:
    pop hl
    xor a
    ld [$db4d], a
    ret


    ld hl, $c1a0
    jr jr_050_7e0c

    ld hl, $c180

jr_050_7e0c:
    ld a, l
    ld [$db4e], a
    ld a, h
    ld [$db4f], a
    ld a, [wBattleTargetIdx]
    ld [$db50], a
    call CheckSlotUnder3
    ret


SetBtl_7e1e:
    ld hl, $c180
    ld a, l
    ld [$db4e], a
    ld a, h
    ld [$db4f], a
    ld a, [wBattleAttackerIdx]
    ld [$db50], a
    call CheckSlotUnder3
    ret


    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
