; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $00e", ROMX[$4000], BANK[$e]

    db $0e ;ROM BANK

    dw LoadBe_4007
    dw labele_402f
    dw labele_4110

; ---------------------------------------------------------------------------
; ScriptDataLookup — Same triple-index as bank $0C (see bank_00c.asm)
; $D8D3 (map_type) → $41BA → per-map table
; $D8D4 (script_id) → per-NPC data pointer
; $D8D5/$D8D6 (counter) → BC command pair
; ---------------------------------------------------------------------------
LoadBe_4007:
    ld a, [wScriptMapType]
    ld l, a
    ld h, $00
    add hl, hl
    ld de, $41ba
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

labele_402f:
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
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call LoadBe_4007
    push bc
    call LoadBe_40e7
    pop bc

LoadBe_4075:
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
    jr z, jr_00e_40a0

    ld b, a

jr_00e_409a:
    call LoadBe_40da
    dec b
    jr nz, jr_00e_409a

jr_00e_40a0:
    ld a, l
    ld [$d8e7], a
    ld a, h
    ld [$d8e8], a
    pop bc

jr_00e_40a9:
    ld a, [bc]
    inc bc
    cp $d9
    ret z

    cp $d8
    jr nz, jr_00e_40d2

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
    jr jr_00e_40a9

jr_00e_40d2:
    call Write_gfx_tile
    call LoadBe_40da
    jr jr_00e_40a9

LoadBe_40da:
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


LoadBe_40e7:
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

jr_00e_40f5:
    push hl

jr_00e_40f6:
    ld a, [bc]
    inc bc
    cp $d9
    jr z, jr_00e_410e

    cp $d8
    jr nz, jr_00e_410b

    pop hl
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_00e_40f5

jr_00e_410b:
    ld [hl+], a
    jr jr_00e_40f6

jr_00e_410e:
    pop hl
    ret

labele_4110:
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
    ld a, [wScriptCounter]
    add $01
    ld [wScriptCounter], a
    ld a, [$d8d6]
    adc $00
    ld [$d8d6], a
    call LoadBe_4007
    push bc
    call LoadBe_4171
    pop bc
    ld a, [wIsGBC]
    or a
    ret z

    di
    call WaitVRAM
    ld a, $01
    ldh [rVBK], a
    ei
    call LoadBe_4075
    di
    call WaitVRAM
    ld a, $00
    ldh [rVBK], a
    ei
    ret


LoadBe_4171:
    ld a, [bc]
    ld l, a
    inc bc
    ld a, [bc]
    ld h, a
    inc bc

jr_00e_4177:
    push hl

jr_00e_4178:
    ld a, [bc]
    inc bc
    cp $d9
    jr z, jr_00e_4193

    cp $d8
    jr nz, jr_00e_418d

    pop hl
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_00e_4177

jr_00e_418d:
    call SaveBe_4195
    inc hl
    jr jr_00e_4178

jr_00e_4193:
    pop hl
    ret


SaveBe_4195:
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
    jr c, jr_00e_41b0

    swap a
    and $f0
    ld d, a
    ld a, [hl]
    and $0f
    jr jr_00e_41b6

jr_00e_41b0:
    and $0f
    ld d, a
    ld a, [hl]
    and $f0

jr_00e_41b6:
    or d
    ld [hl], a
    pop hl
    ret


; ===========================================================================
; Script Data — Bank $0E
; 130 scripts across 32 maps, 287 labels
; ===========================================================================

; ---------------------------------------------------------------------------
; Bank0E_ScriptMasterTable
; ---------------------------------------------------------------------------
Bank0E_ScriptMasterTable:
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    dw $6AE2
    db $3A
    db $42
    db $3E
    db $42
    db $42
    db $42
    db $46
    db $42
    db $5A
    db $42
    db $64
    db $42
    db $6E
    db $42
    db $78
    db $42
    db $B0
    db $42
    db $BA
    db $42
    db $C4
    db $42
    db $CE
    db $42
    db $FA
    db $42
    db $04
    db $43
    db $0E
    db $43
    db $18
    db $43
    db $48
    db $4E
    db $16
    db $4F
    db $7E
    db $50
    db $4E
    db $52
    db $44
    db $53
    db $B6
    db $54
    db $B6
    db $55
    db $52
    db $57
    db $4E
    db $5A
    db $26
    db $5E
    db $4A
    db $5F
    db $48
    db $61
    db $36
    db $62
    db $64
    db $66
    db $F2
    db $68
    db $E6
    db $69
; ---------------------------------------------------------------------------
; Map20 Per-Script Table (map_type=$20, 1 scripts)
; ---------------------------------------------------------------------------
Map20_ScriptPtrTable:
    dw Map20_Script00                  ; script 0
; ---------------------------------------------------------------------------
; Map20_Script00
; ---------------------------------------------------------------------------
Map20_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map21 Per-Script Table (map_type=$21, 1 scripts)
; ---------------------------------------------------------------------------
Map21_ScriptPtrTable:
    dw Map21_Script00                  ; script 0
; ---------------------------------------------------------------------------
; Map21_Script00
; ---------------------------------------------------------------------------
Map21_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map22 Per-Script Table (map_type=$22, 1 scripts)
; ---------------------------------------------------------------------------
Map22_ScriptPtrTable:
    dw Map22_Script00                  ; script 0
; ---------------------------------------------------------------------------
; Map22_Script00
; ---------------------------------------------------------------------------
Map22_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map23 Per-Script Table (map_type=$23, 2 scripts)
; ---------------------------------------------------------------------------
Map23_ScriptPtrTable:
    dw Map23_Script00                  ; script 0
    dw Map23_Script01                  ; script 1
; ---------------------------------------------------------------------------
; Map23_Script00
; ---------------------------------------------------------------------------
Map23_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map23_Script01
; ---------------------------------------------------------------------------
Map23_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $0009  ; Text $0009: "You speak monster talk don't you? Where "
    dw Bank0E_ScriptAddr_4256          ; -> branch target
    dw $0057  ; Text $0057: "How do you do. I'm Hale. I know you are "
    dw $FFFF  ; END

Bank0E_ScriptAddr_4256:
    dw $011F  ; Text $011F: "[HERO] looked into the jar. A piece of p"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; RoomVillagerTalisman Per-Script Table (map_type=$24, 2 scripts)
; ---------------------------------------------------------------------------
RoomVillagerTalisman_ScriptPtrTable:
    dw RoomVillagerTalisman_Script00   ; script 0
    dw RoomVillagerTalisman_Script01   ; script 1
; ---------------------------------------------------------------------------
; RoomVillagerTalisman_Script00
; ---------------------------------------------------------------------------
RoomVillagerTalisman_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; RoomVillagerTalisman_Script01
; ---------------------------------------------------------------------------
RoomVillagerTalisman_Script01:
    dw $01A1  ; Text $01A1: "I'm conducting secret research at the bo"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; RoomMemoriesBewilder Per-Script Table (map_type=$25, 2 scripts)
; ---------------------------------------------------------------------------
RoomMemoriesBewilder_ScriptPtrTable:
    dw RoomMemoriesBewilder_Script00   ; script 0
    dw RoomMemoriesBewilder_Script01   ; script 1
; ---------------------------------------------------------------------------
; RoomMemoriesBewilder_Script00
; ---------------------------------------------------------------------------
RoomMemoriesBewilder_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; RoomMemoriesBewilder_Script01
; ---------------------------------------------------------------------------
RoomMemoriesBewilder_Script01:
    dw $01E1  ; Text $01E1: "Hey [HERO]. Welcome. I am Master Teto. D"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; RoomPeaceBravery Per-Script Table (map_type=$26, 2 scripts)
; ---------------------------------------------------------------------------
RoomPeaceBravery_ScriptPtrTable:
    dw RoomPeaceBravery_Script00       ; script 0
    dw RoomPeaceBravery_Script01       ; script 1
; ---------------------------------------------------------------------------
; RoomPeaceBravery_Script00
; ---------------------------------------------------------------------------
RoomPeaceBravery_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; RoomPeaceBravery_Script01
; ---------------------------------------------------------------------------
RoomPeaceBravery_Script01:
    dw $026E  ; Text $026E: "You're my opponent? Is this a joke? You "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map27 Per-Script Table (map_type=$27, 3 scripts)
; ---------------------------------------------------------------------------
Map27_ScriptPtrTable:
    dw Map27_Script00                  ; script 0
    dw Map27_Script01                  ; script 1
    dw Map27_Script02                  ; script 2
; ---------------------------------------------------------------------------
; Map27_Script00
; ---------------------------------------------------------------------------
Map27_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map27_Script01
; ---------------------------------------------------------------------------
Map27_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0E_ScriptAddr_4294          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0E_ScriptAddr_4290          ; -> branch target
    dw $029C  ; Text $029C: "Monsters are flooding out from the Gate "
    dw $FFFF  ; END

Bank0E_ScriptAddr_4290:
    dw $032E  ; Text $032E: "Thank you very much [HERO]! // Hello [HE"
    dw $FFFF  ; END

Bank0E_ScriptAddr_4294:
    dw $082A  ; Text $082A: "Natto? What's that? You're making it up!"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map27_Script02
; ---------------------------------------------------------------------------
Map27_Script02:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0E_ScriptAddr_42AC          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw Bank0E_ScriptAddr_42A8          ; -> branch target
    dw $029D  ; Text $029D: "It's my wish that... my family in this w"
    dw $FFFF  ; END

Bank0E_ScriptAddr_42A8:
    dw $032F  ; Text $032F: "Hello [HERO]! I was expecting you. Befor"
    dw $FFFF  ; END

Bank0E_ScriptAddr_42AC:
    dw $082B  ; Text $082B: "Victory... You've conquered one of the b"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; RoomJoyWisdom Per-Script Table (map_type=$28, 2 scripts)
; ---------------------------------------------------------------------------
RoomJoyWisdom_ScriptPtrTable:
    dw RoomJoyWisdom_Script00          ; script 0
    dw RoomJoyWisdom_Script01          ; script 1
; ---------------------------------------------------------------------------
; RoomJoyWisdom_Script00
; ---------------------------------------------------------------------------
RoomJoyWisdom_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; RoomJoyWisdom_Script01
; ---------------------------------------------------------------------------
RoomJoyWisdom_Script01:
    dw $035D  ; Text $035D: "Oooo! Ahhhh! Where am I? What? The arena"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; RoomHappinessTemptation Per-Script Table (map_type=$29, 2 scripts)
; ---------------------------------------------------------------------------
RoomHappinessTemptation_ScriptPtrTable:
    dw RoomHappinessTemptation_Script00; script 0
    dw RoomHappinessTemptation_Script01; script 1
; ---------------------------------------------------------------------------
; RoomHappinessTemptation_Script00
; ---------------------------------------------------------------------------
RoomHappinessTemptation_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; RoomHappinessTemptation_Script01
; ---------------------------------------------------------------------------
RoomHappinessTemptation_Script01:
    dw $03DD  ; Text $03DD: "Welcome to A class. I was expecting you!"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; RoomLabyrinthJudgment Per-Script Table (map_type=$2A, 2 scripts)
; ---------------------------------------------------------------------------
RoomLabyrinthJudgment_ScriptPtrTable:
    dw RoomLabyrinthJudgment_Script00  ; script 0
    dw RoomLabyrinthJudgment_Script01  ; script 1
; ---------------------------------------------------------------------------
; RoomLabyrinthJudgment_Script00
; ---------------------------------------------------------------------------
RoomLabyrinthJudgment_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; RoomLabyrinthJudgment_Script01
; ---------------------------------------------------------------------------
RoomLabyrinthJudgment_Script01:
    dw $0408  ; Text $0408: "Behind the Gate of Peace live BigRoosts,"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2B Per-Script Table (map_type=$2B, 2 scripts)
; ---------------------------------------------------------------------------
Map2B_ScriptPtrTable:
    dw Map2B_Script00                  ; script 0
    dw Map2B_Script01                  ; script 1
; ---------------------------------------------------------------------------
; Map2B_Script00
; ---------------------------------------------------------------------------
Map2B_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2B_Script01
; ---------------------------------------------------------------------------
Map2B_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "Let's play rock paperscissors![Y/N] // H"
    dw Bank0E_ScriptAddr_42F6          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "[HERO] returned the book to the bookshel"
    dw Bank0E_ScriptAddr_42F2          ; -> branch target
    dw $046A
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0E_ScriptAddr_42EE          ; -> branch target
    dw $046B
    dw $FFFF  ; END

Bank0E_ScriptAddr_42EE:
    dw $046C  ; Text $046C: "to know, that's fine. Come again! // How"
    dw $FFFF  ; END

Bank0E_ScriptAddr_42F2:
    dw $04DE  ; Text $04DE: "Ladies Gents! Welcome! Tonight is the ni"
    dw $FFFF  ; END

Bank0E_ScriptAddr_42F6:
    dw $082C  ; Text $082C: "You won! But you know there is always so"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; RoomAmbitionDemolition Per-Script Table (map_type=$2C, 2 scripts)
; ---------------------------------------------------------------------------
RoomAmbitionDemolition_ScriptPtrTable:
    dw RoomAmbitionDemolition_Script00 ; script 0
    dw RoomAmbitionDemolition_Script01 ; script 1
; ---------------------------------------------------------------------------
; RoomAmbitionDemolition_Script00
; ---------------------------------------------------------------------------
RoomAmbitionDemolition_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; RoomAmbitionDemolition_Script01
; ---------------------------------------------------------------------------
RoomAmbitionDemolition_Script01:
    dw $082D  ; Text $082D: "Y..you defeated the Master Monster Tamer"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; RoomMastermindControl Per-Script Table (map_type=$2D, 2 scripts)
; ---------------------------------------------------------------------------
RoomMastermindControl_ScriptPtrTable:
    dw RoomMastermindControl_Script00  ; script 0
    dw RoomMastermindControl_Script01  ; script 1
; ---------------------------------------------------------------------------
; RoomMastermindControl_Script00
; ---------------------------------------------------------------------------
RoomMastermindControl_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; RoomMastermindControl_Script01
; ---------------------------------------------------------------------------
RoomMastermindControl_Script01:
    dw $082E  ; Text $082E: "I also was brought here by Watabou a lon"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2E Per-Script Table (map_type=$2E, 2 scripts)
; ---------------------------------------------------------------------------
Map2E_ScriptPtrTable:
    dw Map2E_Script00                  ; script 0
    dw Map2E_Script01                  ; script 1
; ---------------------------------------------------------------------------
; Map2E_Script00
; ---------------------------------------------------------------------------
Map2E_Script00:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2E_Script01
; ---------------------------------------------------------------------------
Map2E_Script01:
    dw $082F  ; Text $082F: "Ha Ha Ha! I made a comeback! You're stil"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F Per-Script Table (map_type=$2F, 15 scripts)
; ---------------------------------------------------------------------------
Map2F_ScriptPtrTable:
    dw Map2F_Script00                  ; script 0
    dw Map2F_Script01                  ; script 1
    dw Map2F_Script02                  ; script 2
    dw Map2F_Script03                  ; script 3
    dw Map2F_Script04                  ; script 4
    dw Map2F_Script05                  ; script 5
    dw Map2F_Script06                  ; script 6
    dw Map2F_Script07                  ; script 7
    dw Map2F_Script08                  ; script 8
    dw Map2F_Script09                  ; script 9
    dw Map2F_Script10                  ; script 10
    dw Map2F_Script11                  ; script 11
    dw Map2F_Script12                  ; script 12
    dw Map2F_Script13                  ; script 13
    dw Map2F_Script14                  ; script 14
; ---------------------------------------------------------------------------
; Map2F_Script00
; ---------------------------------------------------------------------------
Map2F_Script00:
    dw $FF0E  ; SetMapTransition
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw Bank0E_ScriptAddr_4344          ; -> branch target
    dw $FF0E  ; SetMapTransition
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw Bank0E_ScriptAddr_48E4          ; -> branch target
    dw $FFFF  ; END

Bank0E_ScriptAddr_4344:
    dw $FF01  ; BranchIfFlagSet
    dw $00EF  ; Text $00EF: "In the back, they teach kids about the m"
    dw $4342
    dw $FF01  ; BranchIfFlagSet
    dw $00EE  ; Text $00EE: "Gwrr, Gwrr... // In the back, they teach"
    dw $47CE
    dw $FF01  ; BranchIfFlagSet
    dw $00ED  ; Text $00ED: "H...Hello! I'm T..T..Teto. I'm nervous b"
    dw $4620
    dw $FF01  ; BranchIfFlagSet
    dw $00EC  ; Text $00EC: "Only those registered are allowed here! "
    dw $4342
    dw $FF01  ; BranchIfFlagSet
    dw $00EB  ; Text $00EB: "You hear a voice. // Only those register"
    dw $4342
    dw $FF01  ; BranchIfFlagSet
    dw $00EA  ; Text $00EA: "Get out of my way! Huff! // You hear a v"
    dw $45C0
    dw $FF01  ; BranchIfFlagSet
    dw $00E9  ; Text $00E9: "Eeek! What? Talk to me from the front! /"
    dw $4342
    dw $FF01  ; BranchIfFlagSet
    dw $00E4  ; Text $00E4: "Well done! You survived G class! // Oh, "
    dw $455C
    dw $FF01  ; BranchIfFlagSet
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $4342
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF08  ; NOP
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFE0  ; Cmd$E0
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFE0  ; Cmd$E0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFF0  ; Cmd$F0
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFF0  ; Cmd$F0
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFE0  ; Cmd$E0
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFE0  ; Cmd$E0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFE0  ; Cmd$E0
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFE0  ; Cmd$E0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFF0  ; Cmd$F0
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFF0  ; Cmd$F0
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFE0  ; Cmd$E0
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFE0  ; Cmd$E0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFE0  ; Cmd$E0
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFE0  ; Cmd$E0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFF0  ; Cmd$F0
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFF0  ; Cmd$F0
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFE0  ; Cmd$E0
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFE0  ; Cmd$E0
    dw $FF19  ; FadeEffect
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF07  ; InitDialogMode
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF06  ; IncrementCounter
    dw $FF0A  ; NPCMoveX
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0020  ; Text $0020: "KingOh [HERO]! Will you comply with my w"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF0A  ; NPCMoveX
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFF0  ; Cmd$F0
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFF0  ; Cmd$F0
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0020  ; Text $0020: "KingOh [HERO]! Will you comply with my w"
    dw $FF08  ; NOP
    dw $FF4C  ; RestoreBGM
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFFF  ; END

    db $0D
    db $FF
    db $05
    db $00
    db $00
    db $00
    db $00
    db $00
    db $08
    db $FF
    db $09
    db $FF
    db $10
    db $00
    db $0D
    db $FF
    db $05
    db $00
    db $00
    db $00
    db $00
    db $00
    db $0D
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $00
    db $00
    db $0D
    db $FF
    db $05
    db $00
    db $00
    db $00
    db $40
    db $00
    db $0A
    db $FF
    db $00
    db $00
    db $10
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $48
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $49
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $4A
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $49
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $48
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $03
    db $FF
    db $E9
    db $00
    db $12
    db $FF
    db $74
    db $D9
    db $03
    db $00
    db $FF
    db $FF
    db $0D
    db $FF
    db $01
    db $00
    db $18
    db $00
    db $68
    db $00
    db $09
    db $FF
    db $06
    db $00
    db $0D
    db $FF
    db $01
    db $00
    db $00
    db $00
    db $00
    db $00
    db $0D
    db $FF
    db $03
    db $00
    db $00
    db $00
    db $40
    db $00
    db $48
    db $FF
    db $01
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $0A
    db $FF
    db $01
    db $00
    db $10
    db $00
    db $09
    db $FF
    db $06
    db $00
    db $0A
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $4A
    db $FF
    db $01
    db $00
    db $07
    db $FF
    db $11
    db $05
    db $15
    db $FF
    db $3C
    db $C8
    db $01
    db $00
    db $12
    db $46
    db $12
    db $05
    db $03
    db $FF
    db $EB
    db $00
    db $14
    db $FF
    db $18
    db $46
    db $13
    db $05
    db $03
    db $FF
    db $EC
    db $00
    db $12
    db $FF
    db $74
    db $D9
    db $04
    db $00
    db $FF
    db $FF
    db $0D
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $40
    db $00
    db $09
    db $FF
    db $10
    db $00
    db $21
    db $FF
    db $5F
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $21
    db $FF
    db $55
    db $00
    db $0D
    db $FF
    db $02
    db $00
    db $00
    db $00
    db $00
    db $00
    db $1C
    db $FF
    db $02
    db $0C
    db $19
    db $FF
    db $48
    db $FF
    db $02
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $0D
    db $FF
    db $01
    db $00
    db $00
    db $00
    db $00
    db $00
    db $0D
    db $FF
    db $03
    db $00
    db $00
    db $00
    db $40
    db $00
    db $48
    db $FF
    db $01
    db $00
    db $0D
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $00
    db $00
    db $0D
    db $FF
    db $05
    db $00
    db $00
    db $00
    db $40
    db $00
    db $48
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $1A
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $0A
    db $FF
    db $01
    db $00
    db $10
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $47
    db $FF
    db $00
    db $00
    db $47
    db $FF
    db $01
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $1C
    db $FF
    db $00
    db $01
    db $1C
    db $FF
    db $01
    db $01
    db $19
    db $FF
    db $09
    db $FF
    db $04
    db $00
    db $07
    db $FF
    db $18
    db $05
    db $06
    db $FF
    db $1C
    db $FF
    db $00
    db $01
    db $1C
    db $FF
    db $01
    db $01
    db $19
    db $FF
    db $09
    db $FF
    db $04
    db $00
    db $1C
    db $FF
    db $02
    db $01
    db $19
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $07
    db $FF
    db $19
    db $05
    db $06
    db $FF
    db $09
    db $FF
    db $08
    db $00
    db $4A
    db $FF
    db $00
    db $00
    db $49
    db $FF
    db $01
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $1C
    db $FF
    db $00
    db $04
    db $1C
    db $FF
    db $01
    db $04
    db $19
    db $FF
    db $09
    db $FF
    db $04
    db $00
    db $1C
    db $FF
    db $00
    db $1A
    db $19
    db $FF
    db $09
    db $FF
    db $08
    db $00
    db $47
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $22
    db $FF
    db $1B
    db $FF
    db $00
    db $00
    db $F0
    db $FF
    db $19
    db $FF
    db $22
    db $FF
    db $1A
    db $FF
    db $00
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $09
    db $FF
    db $06
    db $00
    db $49
    db $FF
    db $02
    db $00
    db $09
    db $FF
    db $10
    db $00
    db $03
    db $FF
    db $EE
    db $00
    db $12
    db $FF
    db $2B
    db $D9
    db $04
    db $00
    db $12
    db $FF
    db $2C
    db $D9
    db $00
    db $00
    db $12
    db $FF
    db $2D
    db $D9
    db $04
    db $00
    db $12
    db $FF
    db $33
    db $D9
    db $03
    db $00
    db $12
    db $FF
    db $3D
    db $D9
    db $04
    db $00
    db $12
    db $FF
    db $3E
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $3F
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $40
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $42
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $43
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $44
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $47
    db $D9
    db $00
    db $00
    db $12
    db $FF
    db $4E
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $52
    db $D9
    db $01
    db $00
    db $12
    db $FF
    db $67
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $74
    db $D9
    db $06
    db $00
    db $12
    db $FF
    db $3A
    db $D9
    db $04
    db $00
    db $01
    db $FF
    db $15
    db $00
    db $8E
    db $47
    db $12
    db $FF
    db $3A
    db $D9
    db $03
    db $00
    db $12
    db $FF
    db $41
    db $D9
    db $03
    db $00
    db $01
    db $FF
    db $1B
    db $00
    db $A0
    db $47
    db $12
    db $FF
    db $41
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $5E
    db $D9
    db $05
    db $00
    db $01
    db $FF
    db $21
    db $00
    db $BE
    db $47
    db $12
    db $FF
    db $5E
    db $D9
    db $04
    db $00
    db $01
    db $FF
    db $1E
    db $01
    db $BE
    db $47
    db $12
    db $FF
    db $5E
    db $D9
    db $03
    db $00
    db $12
    db $FF
    db $8A
    db $C8
    db $04
    db $00
    db $12
    db $FF
    db $8B
    db $C8
    db $01
    db $00
    db $3E
    db $FF
    db $FF
    db $FF
    db $0D
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $40
    db $00
    db $0D
    db $FF
    db $01
    db $00
    db $00
    db $00
    db $40
    db $00
    db $0D
    db $FF
    db $05
    db $00
    db $00
    db $00
    db $00
    db $00
    db $21
    db $FF
    db $55
    db $00
    db $0D
    db $FF
    db $02
    db $00
    db $00
    db $00
    db $00
    db $00
    db $1C
    db $FF
    db $02
    db $0C
    db $19
    db $FF
    db $48
    db $FF
    db $02
    db $00
    db $09
    db $FF
    db $08
    db $00
    db $1C
    db $FF
    db $02
    db $01
    db $19
    db $FF
    db $09
    db $FF
    db $04
    db $00
    db $1C
    db $FF
    db $02
    db $01
    db $19
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $1C
    db $FF
    db $02
    db $01
    db $19
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $1B
    db $FF
    db $00
    db $00
    db $10
    db $00
    db $0A
    db $FF
    db $02
    db $00
    db $E0
    db $FF
    db $0B
    db $FF
    db $02
    db $00
    db $20
    db $00
    db $0A
    db $FF
    db $02
    db $00
    db $20
    db $00
    db $0B
    db $FF
    db $02
    db $00
    db $E0
    db $FF
    db $0A
    db $FF
    db $02
    db $00
    db $E0
    db $FF
    db $0B
    db $FF
    db $02
    db $00
    db $20
    db $00
    db $0A
    db $FF
    db $02
    db $00
    db $20
    db $00
    db $0B
    db $FF
    db $02
    db $00
    db $E0
    db $FF
    db $48
    db $FF
    db $02
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $1C
    db $FF
    db $02
    db $01
    db $19
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $1C
    db $FF
    db $02
    db $01
    db $19
    db $FF
    db $09
    db $FF
    db $02
    db $00
    db $1C
    db $FF
    db $02
    db $01
    db $19
    db $FF
    db $09
    db $FF
    db $08
    db $00
    db $0D
    db $FF
    db $00
    db $00
    db $90
    db $FF
    db $00
    db $00
    db $0D
    db $FF
    db $05
    db $00
    db $00
    db $00
    db $40
    db $00
    db $0A
    db $FF
    db $00
    db $00
    db $10
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $49
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $4A
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $04
    db $00
    db $47
    db $FF
    db $00
    db $00
    db $09
    db $FF
    db $02
    db $00
    db $1C
    db $FF
    db $02
    db $01
    db $19
    db $FF
    db $07
    db $FF
    db $B4
    db $05
    db $06
    db $FF
    db $0A
    db $FF
    db $02
    db $00
    db $40
    db $00
    db $0B
    db $FF
    db $02
    db $00
    db $10
    db $00
    db $0A
    db $FF
    db $02
    db $00
    db $30
    db $00
    db $0D
    db $FF
    db $02
    db $00
    db $00
    db $00
    db $40
    db $00
    db $03
    db $FF
    db $EF
    db $00
    db $12
    db $FF
    db $74
    db $D9
    db $03
    db $00
    db $12
    db $FF
    db $75
    db $D9
    db $01
    db $00
    db $FF
    db $FF
Bank0E_ScriptAddr_48E4:
    dw $FF01  ; BranchIfFlagSet
    dw $00F0  ; Text $00F0: "Where did the MiniDrak go? // Let's play"
    dw $4342
    dw $FF01  ; BranchIfFlagSet
    dw $00EF  ; Text $00EF: "In the back, they teach kids about the m"
    dw $4B60
    dw $FF01  ; BranchIfFlagSet
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $4342
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF21  ; TriggerBattle2
    dw $0060  ; Text $0060: "Oh boy! This looks dangerous! Oh, no! //"
    dw $FF17  ; SetupBossBattle
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "Welcome to the Chamber of Travelers' Gat"
    dw $FF1C  ; CompareRAM
    dw $1202
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF0A  ; NPCMoveX
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF90  ; Cmd$90
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF07  ; InitDialogMode
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF06  ; IncrementCounter
    dw $FF1D  ; LockMovement
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF21  ; TriggerBattle2
    dw $0054  ; Text $0054: "Hale was the cherished pet of the King. "
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0080  ; Text $0080: "PulioThank you [HERO]! Now I can go back"
    dw $FF0B  ; NPCMoveY
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF0A  ; NPCMoveX
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FFE0  ; Cmd$E0
    dw $FF09  ; SetDelay
    dw $0016  ; Text $0016: "Please listen to his wish. // This is th"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0018  ; Text $0018: "Hurry! Go see the King! // I see..... //"
    dw $0098
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF1D  ; LockMovement
    dw $FF1A  ; Cmd1A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF1A  ; Cmd1A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF1A  ; Cmd1A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF1A  ; Cmd1A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF1D  ; LockMovement
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FFF0  ; Cmd$F0
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF48  ; Cmd48
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF1D  ; LockMovement
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF1A  ; Cmd1A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF49  ; Cmd49
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF1D  ; LockMovement
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF1A  ; Cmd1A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF1A  ; Cmd1A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF1A  ; Cmd1A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF1A  ; Cmd1A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF1E  ; UnlockMovement
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF1C  ; CompareRAM
    dw $0100  ; Text $0100: "Welcome to the arena. Huh? Me? I'm famou"
    dw $FF19  ; FadeEffect
    dw $FF1D  ; LockMovement
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF48  ; Cmd48
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "Welcome to the Chamber of Travelers' Gat"
    dw $FF1C  ; CompareRAM
    dw $1302
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "Welcome to the Chamber of Travelers' Gat"
    dw $FF1C  ; CompareRAM
    dw $1303
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF21  ; TriggerBattle2
    dw $0060  ; Text $0060: "Oh boy! This looks dangerous! Oh, no! //"
    dw $FF17  ; SetupBossBattle
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFE0  ; Cmd$E0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0030  ; Text $0030: "Upper floor, the monster farm. Pulio tak"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $000C  ; Text $000C: "Terry looked in front of him. The clock "
    dw $FF21  ; TriggerBattle2
    dw $0060  ; Text $0060: "Oh boy! This looks dangerous! Oh, no! //"
    dw $FF17  ; SetupBossBattle
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "Welcome to the Chamber of Travelers' Gat"
    dw $FF1C  ; CompareRAM
    dw $1201
    dw $FF19  ; FadeEffect
    dw $FF07  ; InitDialogMode
    dw $0009  ; Text $0009: "You speak monster talk don't you? Where "
    dw $FF06  ; IncrementCounter
    dw $FF09  ; SetDelay
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF09  ; SetDelay
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF09  ; SetDelay
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF09  ; SetDelay
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF09  ; SetDelay
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF1C  ; CompareRAM
    dw $0100  ; Text $0100: "Welcome to the arena. Huh? Me? I'm famou"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF1C  ; CompareRAM
    dw $0101  ; Text $0101: "Too bad. You need more training. There a"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0A  ; NPCMoveX
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFD0  ; Cmd$D0
    dw $FF07  ; InitDialogMode
    dw $000A  ; Text $000A: "Terry looks at the bookshelf. Encycloped"
    dw $FF06  ; IncrementCounter
    dw $FF0A  ; NPCMoveX
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0030  ; Text $0030: "Upper floor, the monster farm. Pulio tak"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF1C  ; CompareRAM
    dw $0201  ; Text $0201: "[HERO] looked at the bookshelf. The secr"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFF0  ; Cmd$F0
    dw $FF21  ; TriggerBattle2
    dw $0060  ; Text $0060: "Oh boy! This looks dangerous! Oh, no! //"
    dw $FF17  ; SetupBossBattle
    dw $FF03  ; SetEventFlag
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF12  ; WriteRAM
    dw $D974  ; RAM $D974
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFFF  ; END

    db $0D
    db $FF
    db $01
    db $00
    db $00
    db $00
    db $00
    db $00
    db $4A
    db $FF
    db $00
    db $00
    db $47
    db $FF
    db $01
    db $00
    db $08
    db $FF
    db $09
    db $FF
    db $04
    db $00
    db $21
    db $FF
    db $60
    db $00
    db $17
    db $FF
    db $09
    db $FF
    db $06
    db $00
    db $1D
    db $FF
    db $1B
    db $FF
    db $01
    db $00
    db $10
    db $00
    db $19
    db $FF
    db $1E
    db $FF
    db $09
    db $FF
    db $08
    db $00
    db $1C
    db $FF
    db $01
    db $02
    db $19
    db $FF
    db $0D
    db $FF
    db $01
    db $00
    db $00
    db $00
    db $40
    db $00
    db $0B
    db $FF
    db $01
    db $00
    db $F0
    db $FF
    db $21
    db $FF
    db $60
    db $00
    db $17
    db $FF
    db $03
    db $FF
    db $F0
    db $00
    db $12
    db $FF
    db $74
    db $D9
    db $00
    db $00
    db $FF
    db $FF
    db $FF
    db $FF
; ---------------------------------------------------------------------------
; Map2F_Script01
; ---------------------------------------------------------------------------
Map2F_Script01:
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script02
; ---------------------------------------------------------------------------
Map2F_Script02:
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script03
; ---------------------------------------------------------------------------
Map2F_Script03:
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script04
; ---------------------------------------------------------------------------
Map2F_Script04:
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script05
; ---------------------------------------------------------------------------
Map2F_Script05:
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script06
; ---------------------------------------------------------------------------
Map2F_Script06:
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script07
; ---------------------------------------------------------------------------
Map2F_Script07:
    dw $FF01  ; BranchIfFlagSet
    dw $00EE  ; Text $00EE: "Gwrr, Gwrr... // In the back, they teach"
    dw Bank0E_ScriptAddr_4BEE          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00EC  ; Text $00EC: "Only those registered are allowed here! "
    dw Bank0E_ScriptAddr_4BEA          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00EB  ; Text $00EB: "You hear a voice. // Only those register"
    dw Bank0E_ScriptAddr_4BE6          ; -> branch target
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFFF  ; END

Bank0E_ScriptAddr_4BE6:
    dw $0514  ; Text $0514: "MilayouGood night [HERO]! Go to sleep. /"
    dw $FFFF  ; END

Bank0E_ScriptAddr_4BEA:
    dw $0515  ; Text $0515: "Milayou...Oh? ...[HERO]! // MilayouWhat'"
    dw $FFFF  ; END

Bank0E_ScriptAddr_4BEE:
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script08
; ---------------------------------------------------------------------------
Map2F_Script08:
    dw $FF01  ; BranchIfFlagSet
    dw $00E4  ; Text $00E4: "Well done! You survived G class! // Oh, "
    dw Bank0E_ScriptAddr_4BFC          ; -> branch target
    dw $000B  ; Text $000B: "Terry looked at the bookshelf. Too diffi"
    dw $FFFF  ; END

Bank0E_ScriptAddr_4BFC:
    dw $051A  ; Text $051A: "[NUM];[HERO] looked in the dresser. And "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script09
; ---------------------------------------------------------------------------
Map2F_Script09:
    dw $000C  ; Text $000C: "Terry looked in front of him. The clock "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script10
; ---------------------------------------------------------------------------
Map2F_Script10:
    dw $FF01  ; BranchIfFlagSet
    dw $00F0  ; Text $00F0: "Where did the MiniDrak go? // Let's play"
    dw Bank0E_ScriptAddr_4CB4          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00E4  ; Text $00E4: "Well done! You survived G class! // Oh, "
    dw Bank0E_ScriptAddr_4CAC          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $0060  ; Text $0060: "Oh boy! This looks dangerous! Oh, no! //"
    dw $FF17  ; SetupBossBattle
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF1D  ; LockMovement
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF1C  ; CompareRAM
    dw $0100  ; Text $0100: "Welcome to the arena. Huh? Me? I'm famou"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF1C  ; CompareRAM
    dw $0300  ; Text $0300: "You snuck in here because I'm so beautif"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF12  ; WriteRAM
    dw $D951  ; RAM $D951
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF3B  ; Cmd3B
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $0048  ; Text $0048: "KingArrgh! You! You let my precious Hale"
    dw $FFFF  ; END

Bank0E_ScriptAddr_4CAC:
    dw $051B  ; Text $051B: "There are cliffs that we can jump off if"
    dw $FF03  ; SetEventFlag
    dw $00EA  ; Text $00EA: "Get out of my way! Huff! // You hear a v"
    dw $FFFF  ; END

Bank0E_ScriptAddr_4CB4:
    dw $FF21  ; TriggerBattle2
    dw $0060  ; Text $0060: "Oh boy! This looks dangerous! Oh, no! //"
    dw $FF17  ; SetupBossBattle
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF1D  ; LockMovement
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF1C  ; CompareRAM
    dw $0100  ; Text $0100: "Welcome to the arena. Huh? Me? I'm famou"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF1C  ; CompareRAM
    dw $0300  ; Text $0300: "You snuck in here because I'm so beautif"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF12  ; WriteRAM
    dw $D951  ; RAM $D951
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF3B  ; Cmd3B
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $0048  ; Text $0048: "KingArrgh! You! You let my precious Hale"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script11
; ---------------------------------------------------------------------------
Map2F_Script11:
    dw $000E  ; Text $000E: "Oh, you must be the master. You must hav"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script12
; ---------------------------------------------------------------------------
Map2F_Script12:
    dw $000D  ; Text $000D: "Terry looked at a stuffed animal. Someth"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script13
; ---------------------------------------------------------------------------
Map2F_Script13:
    dw $FF01  ; BranchIfFlagSet
    dw $00EB  ; Text $00EB: "You hear a voice. // Only those register"
    dw Bank0E_ScriptAddr_4D66          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00EC  ; Text $00EC: "Only those registered are allowed here! "
    dw Bank0E_ScriptAddr_4D66          ; -> branch target
    dw $FFFF  ; END

Bank0E_ScriptAddr_4D66:
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF1C  ; CompareRAM
    dw $0101  ; Text $0101: "Too bad. You need more training. There a"
    dw $FF19  ; FadeEffect
    dw $FF07  ; InitDialogMode
    dw $0516  ; Text $0516: "MilayouWhat's in your pocket? // Watabou"
    dw $FF06  ; IncrementCounter
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0020  ; Text $0020: "KingOh [HERO]! Will you comply with my w"
    dw $FF07  ; InitDialogMode
    dw $0517  ; Text $0517: "WatabouGimme that meat. // WatabouGimme "
    dw $FF06  ; IncrementCounter
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $000C  ; Text $000C: "Terry looked in front of him. The clock "
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $000C  ; Text $000C: "Terry looked in front of him. The clock "
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF1C  ; CompareRAM
    dw $0400  ; Text $0400: "He looks a bit nervous. I wonder why? Ma"
    dw $FF1C  ; CompareRAM
    dw $0401  ; Text $0401: "I'm the Monster Minister! Do you want to"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF12  ; WriteRAM
    dw $D974  ; RAM $D974
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF03  ; SetEventFlag
    dw $00ED  ; Text $00ED: "H...Hello! I'm T..T..Teto. I'm nervous b"
    dw $FF41  ; SetBGM
    dw $0047  ; Text $0047: "PulioYour Majesty please forgive me! Hal"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF65  ; Cmd$65
    dw $FF12  ; WriteRAM
    dw $C88A  ; RAM $C88A
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF12  ; WriteRAM
    dw $C88B  ; RAM $C88B
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF3E  ; Cmd3E
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script14
; ---------------------------------------------------------------------------
Map2F_Script14:
    dw $FF01  ; BranchIfFlagSet
    dw $00EB  ; Text $00EB: "You hear a voice. // Only those register"
    dw Bank0E_ScriptAddr_4E1A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00EC  ; Text $00EC: "Only those registered are allowed here! "
    dw Bank0E_ScriptAddr_4E1A          ; -> branch target
    dw $FFFF  ; END

Bank0E_ScriptAddr_4E1A:
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF1C  ; CompareRAM
    dw $0101  ; Text $0101: "Too bad. You need more training. There a"
    dw $FF19  ; FadeEffect
    dw $FF07  ; InitDialogMode
    dw $0516  ; Text $0516: "MilayouWhat's in your pocket? // Watabou"
    dw $FF06  ; IncrementCounter
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF07  ; InitDialogMode
    dw $0517  ; Text $0517: "WatabouGimme that meat. // WatabouGimme "
    dw $FF06  ; IncrementCounter
    dw $FF14  ; ClearGameFlags
    dw $4D8E
; ---------------------------------------------------------------------------
; BossBeginning Per-Script Table (map_type=$30, 2 scripts)
; ---------------------------------------------------------------------------
BossBeginning_ScriptPtrTable:
    dw BossBeginning_Script00          ; script 0
    dw BossBeginning_Script01          ; script 1
; ---------------------------------------------------------------------------
; BossBeginning_Script00
; ---------------------------------------------------------------------------
BossBeginning_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBeginning_Script01
; ---------------------------------------------------------------------------
BossBeginning_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $003D  ; Text $003D: "You came here to get monsters? // I'm Pu"
    dw Bank0E_ScriptAddr_4F0E          ; -> branch target
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FF03  ; SetEventFlag
    dw $003D  ; Text $003D: "You came here to get monsters? // I'm Pu"
    dw $FF5A  ; Cmd5A
    dw $000B  ; Text $000B: "Terry looked at the bookshelf. Too diffi"
    dw $FF07  ; InitDialogMode
    dw $0059  ; Text $0059: "KingOh, [HERO]! Did you bring back Hale!"
    dw $FF06  ; IncrementCounter
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0307  ; Text $0307: "Betty was actually a CopyCat! Nooooooooo"
    dw $FF1C  ; CompareRAM
    dw $1502
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF07  ; InitDialogMode
    dw $0146  ; Text $0146: "[HERO] found an Herb. But cannot carry a"
    dw $FF1C  ; CompareRAM
    dw $0402  ; Text $0402: "If you don't want to know, that's fine. "
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0030  ; Text $0030: "Upper floor, the monster farm. Pulio tak"
    dw $FF03  ; SetEventFlag
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF12  ; WriteRAM
    dw $D968  ; RAM $D968
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF12  ; WriteRAM
    dw $D976  ; RAM $D976
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $00E8  ; Text $00E8: "The last battle in G class is with the p"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FFFF  ; END

Bank0E_ScriptAddr_4F0E:
    dw $013F  ; Text $013F: "Leeet's Rumble! // For the 1st match, th"
    dw $FF14  ; ClearGameFlags
    dw $4E68
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossVillager Per-Script Table (map_type=$31, 3 scripts)
; ---------------------------------------------------------------------------
BossVillager_ScriptPtrTable:
    dw BossVillager_Script00           ; script 0
    dw BossVillager_Script01           ; script 1
    dw BossVillager_Script02           ; script 2
; ---------------------------------------------------------------------------
; BossVillager_Script00
; ---------------------------------------------------------------------------
BossVillager_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossVillager_Script01
; ---------------------------------------------------------------------------
BossVillager_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00B6  ; Text $00B6: "ed a treasure chest! // [HERO] picked up"
    dw Bank0E_ScriptAddr_4FA8          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00B2
    dw Bank0E_ScriptAddr_4F8E          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00B5
    dw Bank0E_ScriptAddr_4F80          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00B4  ; Text $00B4: "Warubou? I'm not Warubou. I am Watabou! "
    dw Bank0E_ScriptAddr_4F6E          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00B3
    dw Bank0E_ScriptAddr_4F5C          ; -> branch target
    dw $0220  ; Text $0220: "Ha ha ha... It's E class. I survived E c"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw Bank0E_ScriptAddr_4FAC          ; -> branch target
    dw $0221  ; Text $0221: "The bishop over there taught me a song. "
    dw $FF03  ; SetEventFlag
    dw $00B3
    dw $FFFF  ; END

Bank0E_ScriptAddr_4F5C:
    dw $0220  ; Text $0220: "Ha ha ha... It's E class. I survived E c"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw Bank0E_ScriptAddr_4FAC          ; -> branch target
    dw $0222  ; Text $0222: "BigRoost is roasting big time! // Hee he"
    dw $FF03  ; SetEventFlag
    dw $00B4  ; Text $00B4: "Warubou? I'm not Warubou. I am Watabou! "
    dw $FFFF  ; END

Bank0E_ScriptAddr_4F6E:
    dw $0220  ; Text $0220: "Ha ha ha... It's E class. I survived E c"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw Bank0E_ScriptAddr_4FAC          ; -> branch target
    dw $0223  ; Text $0223: "Hee hee! Dude! Wanna know who you're gon"
    dw $FF03  ; SetEventFlag
    dw $00B5
    dw $FFFF  ; END

Bank0E_ScriptAddr_4F80:
    dw $0220  ; Text $0220: "Ha ha ha... It's E class. I survived E c"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw Bank0E_ScriptAddr_4FAC          ; -> branch target
    dw $0224  ; Text $0224: "Teto in the waiting room will fight you "
    dw $FFFF  ; END

Bank0E_ScriptAddr_4F8E:
    dw $0227  ; Text $0227: "After breeding, the parent monsters will"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $4FA0
    dw $0228  ; Text $0228: "[HERO] looked at the bookshelf. Everythi"
    dw $FF14  ; ClearGameFlags
    dw $4F90
    dw $FFFF  ; END

    db $29
    db $02
    db $03
    db $FF
    db $B6
    db $00
    db $FF
    db $FF
Bank0E_ScriptAddr_4FA8:
    dw $0250  ; Text $0250: "Zzz... zzzz.... // Zzz... zzzz.... ....b"
    dw $FFFF  ; END

Bank0E_ScriptAddr_4FAC:
    dw $0225  ; Text $0225: "Oh, long time no see! Remember me? I am "
    dw $0226  ; Text $0226: "Hey! Lemme tell ya. when you breed... fi"
    dw $FF03  ; SetEventFlag
    dw $00B2
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossVillager_Script02
; ---------------------------------------------------------------------------
BossVillager_Script02:
    dw $FF01  ; BranchIfFlagSet
    dw $00B7
    dw Bank0E_ScriptAddr_5076          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00B6  ; Text $00B6: "ed a treasure chest! // [HERO] picked up"
    dw Bank0E_ScriptAddr_4FC6          ; -> branch target
    dw $0251  ; Text $0251: "Zzz... zzzz.... ....bust! It's been a lo"
    dw $FFFF  ; END

Bank0E_ScriptAddr_4FC6:
    dw $0252  ; Text $0252: "...zzz. You came again! // You're strong"
    dw $FF03  ; SetEventFlag
    dw $00B7
    dw $FF5A  ; Cmd5A
    dw $001F  ; Text $001F: "Welcome! I am the King of this kingdom. "
    dw $FF07  ; InitDialogMode
    dw $0254  ; Text $0254: "WatabouYou couldn't carry the princess. "
    dw $FF06  ; IncrementCounter
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0304  ; Text $0304: "You again!? I'm really gonna get you now"
    dw $FF1C  ; CompareRAM
    dw $1602
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF07  ; InitDialogMode
    dw $0255  ; Text $0255: "........ // You, stop right there! You s"
    dw $FF1C  ; CompareRAM
    dw $0402  ; Text $0402: "If you don't want to know, that's fine. "
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0031  ; Text $0031: "Watabou brings us capable masters. Hmm. "
    dw $FF03  ; SetEventFlag
    dw $0011  ; Text $0011: "Yes indeed, I'm taking him to see the Ki"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF12  ; WriteRAM
    dw $D969  ; RAM $D969
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF12  ; WriteRAM
    dw $D977  ; RAM $D977
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF00  ; BranchIfFlagClear
    dw $0012  ; Text $0012: "Good luck at the Starry Night Tournament"
    dw $506A
    dw $FF12  ; WriteRAM
    dw $D969  ; RAM $D969
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $00E8  ; Text $00E8: "The last battle in G class is with the p"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5076:
    dw $0253  ; Text $0253: "You're strong!! // WatabouYou couldn't c"
    dw $FF14  ; ClearGameFlags
    dw $4FCC
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossTalisman Per-Script Table (map_type=$32, 3 scripts)
; ---------------------------------------------------------------------------
BossTalisman_ScriptPtrTable:
    dw BossTalisman_Script00           ; script 0
    dw BossTalisman_Script01           ; script 1
    dw BossTalisman_Script02           ; script 2
; ---------------------------------------------------------------------------
; BossTalisman_Script00
; ---------------------------------------------------------------------------
BossTalisman_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF01  ; BranchIfFlagSet
    dw $00B8  ; Text $00B8: "late! Warubou? I'm not Warubou. I am Wat"
    dw Bank0E_ScriptAddr_517E          ; -> branch target
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0B  ; NPCMoveY
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0020  ; Text $0020: "KingOh [HERO]! Will you comply with my w"
    dw $FF0A  ; NPCMoveX
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FFD0  ; Cmd$D0
    dw $FF0B  ; NPCMoveY
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0020  ; Text $0020: "KingOh [HERO]! Will you comply with my w"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF09  ; SetDelay
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1C  ; CompareRAM
    dw $0102  ; Text $0102: "Well done! You survived G class! // Oh, "
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF1C  ; CompareRAM
    dw $0102  ; Text $0102: "Well done! You survived G class! // Oh, "
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF1C  ; CompareRAM
    dw $0102  ; Text $0102: "Well done! You survived G class! // Oh, "
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF1C  ; CompareRAM
    dw $0102  ; Text $0102: "Well done! You survived G class! // Oh, "
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF1D  ; LockMovement
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF21  ; TriggerBattle2
    dw $0054  ; Text $0054: "Hale was the cherished pet of the King. "
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0305  ; Text $0305: "You don't seem to be a bad guy after all"
    dw $FF1C  ; CompareRAM
    dw $1802
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF03  ; SetEventFlag
    dw $00B8  ; Text $00B8: "late! Warubou? I'm not Warubou. I am Wat"
    dw $FFFF  ; END

Bank0E_ScriptAddr_517E:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossTalisman_Script01
; ---------------------------------------------------------------------------
BossTalisman_Script01:
    dw $0256  ; Text $0256: "You, stop right there! You shall not pas"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossTalisman_Script02
; ---------------------------------------------------------------------------
BossTalisman_Script02:
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF07  ; InitDialogMode
    dw $FF01  ; BranchIfFlagSet
    dw $00B9  ; Text $00B9: "ou leave the monsters here. SlioBut the "
    dw Bank0E_ScriptAddr_5246          ; -> branch target
    dw $0257  ; Text $0257: "Must I repeat myself? You shall not pass"
    dw $FF03  ; SetEventFlag
    dw $00B9  ; Text $00B9: "ou leave the monsters here. SlioBut the "
    dw $FF5A  ; Cmd5A
    dw $0020  ; Text $0020: "KingOh [HERO]! Will you comply with my w"
    dw $FF07  ; InitDialogMode
    dw $0259  ; Text $0259: "Want to match with my CatFly? // You are"
    dw $FF06  ; IncrementCounter
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0405  ; Text $0405: "How about monsters living behind the Gat"
    dw $FF1C  ; CompareRAM
    dw $1503
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF07  ; InitDialogMode
    dw $0262  ; Text $0262: "Grrrr... Whoosh! Whoooosh! // Guffaw Guf"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4A  ; Cmd4A
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF49  ; Cmd49
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0032  ; Text $0032: "I wonder where I can get treats. // [HER"
    dw $FF03  ; SetEventFlag
    dw $0012  ; Text $0012: "Good luck at the Starry Night Tournament"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF12  ; WriteRAM
    dw $D969  ; RAM $D969
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF12  ; WriteRAM
    dw $D978  ; RAM $D978
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF00  ; BranchIfFlagClear
    dw $0011  ; Text $0011: "Yes indeed, I'm taking him to see the Ki"
    dw Bank0E_ScriptAddr_523A          ; -> branch target
    dw $FF12  ; WriteRAM
    dw $D969  ; RAM $D969
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
Bank0E_ScriptAddr_523A:
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $00E8  ; Text $00E8: "The last battle in G class is with the p"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5246:
    dw $0258  ; Text $0258: "You are powerful. But defeating me doesn"
    dw $FF14  ; ClearGameFlags
    dw $519A
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossMemories Per-Script Table (map_type=$33, 2 scripts)
; ---------------------------------------------------------------------------
BossMemories_ScriptPtrTable:
    dw BossMemories_Script00           ; script 0
    dw BossMemories_Script01           ; script 1
; ---------------------------------------------------------------------------
; BossMemories_Script00
; ---------------------------------------------------------------------------
BossMemories_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossMemories_Script01
; ---------------------------------------------------------------------------
BossMemories_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00BC  ; Text $00BC: "e alone with my brother. Hope no horribl"
    dw Bank0E_ScriptAddr_533C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00BB
    dw Bank0E_ScriptAddr_5284          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00BA  ; Text $00BA: "ed a treasure chest! // [HERO] picked up"
    dw Bank0E_ScriptAddr_527C          ; -> branch target
    dw $0263  ; Text $0263: "Guffaw Guffaw..? Cackle cackle...? // Gr"
    dw $FF03  ; SetEventFlag
    dw $00BA  ; Text $00BA: "ed a treasure chest! // [HERO] picked up"
    dw $FFFF  ; END

Bank0E_ScriptAddr_527C:
    dw $0264  ; Text $0264: "Grrrr... Whoosh! Whoooosh! ......cackle!"
    dw $FF03  ; SetEventFlag
    dw $00BB
    dw $FFFF  ; END

Bank0E_ScriptAddr_5284:
    dw $0265  ; Text $0265: "Grrrr... Cackle cackle!! // [HERO]! [HER"
    dw $FF03  ; SetEventFlag
    dw $00BC  ; Text $00BC: "e alone with my brother. Hope no horribl"
    dw $FF5A  ; Cmd5A
    dw $0033  ; Text $0033: "[HERO] read the sign. Danger, Don't rush"
    dw $FF07  ; InitDialogMode
    dw $0267  ; Text $0267: "WatabouIt seems MadCat is attached to [H"
    dw $FF06  ; IncrementCounter
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0407  ; Text $0407: "How about the monsters behind the Gates "
    dw $FF1C  ; CompareRAM
    dw $1502
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF07  ; InitDialogMode
    dw $0268  ; Text $0268: "[HERO] read the sign. Youth goes in hast"
    dw $FF1C  ; CompareRAM
    dw $0402  ; Text $0402: "If you don't want to know, that's fine. "
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0033  ; Text $0033: "[HERO] read the sign. Danger, Don't rush"
    dw $FF03  ; SetEventFlag
    dw $0013  ; Text $0013: "Now it's time to go see the King. // I'm"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF12  ; WriteRAM
    dw $D96A  ; RAM $D96A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF12  ; WriteRAM
    dw $D979  ; RAM $D979
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF00  ; BranchIfFlagClear
    dw $0014  ; Text $0014: "I'm the minister of this kingdom. Are yo"
    dw $5330
    dw $FF12  ; WriteRAM
    dw $D96A  ; RAM $D96A
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $00E8  ; Text $00E8: "The last battle in G class is with the p"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FFFF  ; END

Bank0E_ScriptAddr_533C:
    dw $0266  ; Text $0266: "[HERO]! [HERO]!! Meow. Purrrr... // Wata"
    dw $FF14  ; ClearGameFlags
    dw $528A
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBewilder Per-Script Table (map_type=$34, 11 scripts)
; ---------------------------------------------------------------------------
BossBewilder_ScriptPtrTable:
    dw BossBewilder_Script00           ; script 0
    dw BossBewilder_Script01           ; script 1
    dw BossBewilder_Script02           ; script 2
    dw BossBewilder_Script03           ; script 3
    dw BossBewilder_Script04           ; script 4
    dw BossBewilder_Script05           ; script 5
    dw BossBewilder_Script06           ; script 6
    dw BossBewilder_Script07           ; script 7
    dw BossBewilder_Script08           ; script 8
    dw BossBewilder_Script09           ; script 9
    dw BossBewilder_Script10           ; script 10
; ---------------------------------------------------------------------------
; BossBewilder_Script00
; ---------------------------------------------------------------------------
BossBewilder_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script01
; ---------------------------------------------------------------------------
BossBewilder_Script01:
    dw $0269  ; Text $0269: "Hee hee hee! I didn't think you could ma"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script02
; ---------------------------------------------------------------------------
BossBewilder_Script02:
    dw $FF01  ; BranchIfFlagSet
    dw $0117  ; Text $0117: "Want to know where the wife of the King."
    dw Bank0E_ScriptAddr_5422          ; -> branch target
    dw $026A  ; Text $026A: "No matter how many times you fight, it w"
    dw $FF03  ; SetEventFlag
    dw $0117  ; Text $0117: "Want to know where the wife of the King."
    dw $FF5A  ; Cmd5A
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw $FF07  ; InitDialogMode
    dw $0290  ; Text $0290: "Squeaking squeaking. // // WatabouYou di"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0205  ; Text $0205: "Welcome to the Master School! [HERO]! It"
    dw $FF1C  ; CompareRAM
    dw $1505
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF07  ; InitDialogMode
    dw $0293  ; Text $0293: "Wel...come... // Come.....again.. // // "
    dw $FF1C  ; CompareRAM
    dw $0405  ; Text $0405: "How about monsters living behind the Gat"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF49  ; Cmd49
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0034  ; Text $0034: "No! You'll be hurt if you fall. // If it"
    dw $FF03  ; SetEventFlag
    dw $0014  ; Text $0014: "I'm the minister of this kingdom. Are yo"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF12  ; WriteRAM
    dw $D96A  ; RAM $D96A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF12  ; WriteRAM
    dw $D97A  ; RAM $D97A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF00  ; BranchIfFlagClear
    dw $0013  ; Text $0013: "Now it's time to go see the King. // I'm"
    dw Bank0E_ScriptAddr_5416          ; -> branch target
    dw $FF12  ; WriteRAM
    dw $D96A  ; RAM $D96A
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
Bank0E_ScriptAddr_5416:
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $00E8  ; Text $00E8: "The last battle in G class is with the p"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5422:
    dw $026B  ; Text $026B: "You want to breed with my LizardMan? // "
    dw $FF14  ; ClearGameFlags
    dw $537A
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script03
; ---------------------------------------------------------------------------
BossBewilder_Script03:
    dw $FF01  ; BranchIfFlagSet
    dw $00BD  ; Text $00BD: "the Starry Night! KingLegend has it that"
    dw Bank0E_ScriptAddr_543E          ; -> branch target
    dw $0291  ; Text $0291: "// WatabouYou did a good job solving the"
    dw $FF06  ; IncrementCounter
    dw $FF05  ; TriggerBattle
    dw $0155  ; Text $0155: "[HERO] looked into the barrel. Something"
    dw $FF03  ; SetEventFlag
    dw $00BD  ; Text $00BD: "the Starry Night! KingLegend has it that"
    dw $FFFF  ; END

Bank0E_ScriptAddr_543E:
    dw $0292  ; Text $0292: "WatabouYou did a good job solving the Fo"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script04
; ---------------------------------------------------------------------------
BossBewilder_Script04:
    dw $FF01  ; BranchIfFlagSet
    dw $00BE  ; Text $00BE: "Milayou... zzz. // Terry looked at a stu"
    dw Bank0E_ScriptAddr_5456          ; -> branch target
    dw $0291  ; Text $0291: "// WatabouYou did a good job solving the"
    dw $FF06  ; IncrementCounter
    dw $FF05  ; TriggerBattle
    dw $0155  ; Text $0155: "[HERO] looked into the barrel. Something"
    dw $FF03  ; SetEventFlag
    dw $00BE  ; Text $00BE: "Milayou... zzz. // Terry looked at a stu"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5456:
    dw $0292  ; Text $0292: "WatabouYou did a good job solving the Fo"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script05
; ---------------------------------------------------------------------------
BossBewilder_Script05:
    dw $FF01  ; BranchIfFlagSet
    dw $00BF  ; Text $00BF: "monsters here. SlioBut the monsters will"
    dw Bank0E_ScriptAddr_546E          ; -> branch target
    dw $0291  ; Text $0291: "// WatabouYou did a good job solving the"
    dw $FF06  ; IncrementCounter
    dw $FF05  ; TriggerBattle
    dw $0155  ; Text $0155: "[HERO] looked into the barrel. Something"
    dw $FF03  ; SetEventFlag
    dw $00BF  ; Text $00BF: "monsters here. SlioBut the monsters will"
    dw $FFFF  ; END

Bank0E_ScriptAddr_546E:
    dw $0292  ; Text $0292: "WatabouYou did a good job solving the Fo"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script06
; ---------------------------------------------------------------------------
BossBewilder_Script06:
    dw $FF01  ; BranchIfFlagSet
    dw $00C0  ; Text $00C0: "Kingdom of GreatLog. WarubouDon't you fo"
    dw Bank0E_ScriptAddr_5486          ; -> branch target
    dw $0291  ; Text $0291: "// WatabouYou did a good job solving the"
    dw $FF06  ; IncrementCounter
    dw $FF05  ; TriggerBattle
    dw $0155  ; Text $0155: "[HERO] looked into the barrel. Something"
    dw $FF03  ; SetEventFlag
    dw $00C0  ; Text $00C0: "Kingdom of GreatLog. WarubouDon't you fo"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5486:
    dw $0292  ; Text $0292: "WatabouYou did a good job solving the Fo"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script07
; ---------------------------------------------------------------------------
BossBewilder_Script07:
    dw $FF10  ; NPCAnimStart
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0078
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script08
; ---------------------------------------------------------------------------
BossBewilder_Script08:
    dw $FF01  ; BranchIfFlagSet
    dw $00BF  ; Text $00BF: "monsters here. SlioBut the monsters will"
    dw Bank0E_ScriptAddr_549E          ; -> branch target
    dw $FF10  ; NPCAnimStart
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0048  ; Text $0048: "KingArrgh! You! You let my precious Hale"
Bank0E_ScriptAddr_549E:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script09
; ---------------------------------------------------------------------------
BossBewilder_Script09:
    dw $FF01  ; BranchIfFlagSet
    dw $00C0  ; Text $00C0: "Kingdom of GreatLog. WarubouDon't you fo"
    dw Bank0E_ScriptAddr_54AC          ; -> branch target
    dw $FF11  ; NPCAnimSetup
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
Bank0E_ScriptAddr_54AC:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script10
; ---------------------------------------------------------------------------
BossBewilder_Script10:
    dw $FF10  ; NPCAnimStart
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map35 Per-Script Table (map_type=$35, 4 scripts)
; ---------------------------------------------------------------------------
Map35_ScriptPtrTable:
    dw Map35_Script00                  ; script 0
    dw Map35_Script01                  ; script 1
    dw Map35_Script02                  ; script 2
    dw Map35_Script03                  ; script 3
; ---------------------------------------------------------------------------
; Map35_Script00
; ---------------------------------------------------------------------------
Map35_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map35_Script01
; ---------------------------------------------------------------------------
Map35_Script01:
    dw $0294  ; Text $0294: "Come.....again.. // // // WatabouThis pl"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map35_Script02
; ---------------------------------------------------------------------------
Map35_Script02:
    dw $0295  ; Text $0295: "// // WatabouThis place was ruined by mo"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map35_Script03
; ---------------------------------------------------------------------------
Map35_Script03:
    dw $0296  ; Text $0296: "// WatabouThis place was ruined by monst"
    dw $FF5A  ; Cmd5A
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw $FF07  ; InitDialogMode
    dw $0297  ; Text $0297: "WatabouThis place was ruined by monsters"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0204  ; Text $0204: "[HERO] looked into the big kettle. ...So"
    dw $FF1C  ; CompareRAM
    dw $1502
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF07  ; InitDialogMode
    dw $0298  ; Text $0298: "[HERO] pulled the slot machine! The symb"
    dw $FF1C  ; CompareRAM
    dw $0402  ; Text $0402: "If you don't want to know, that's fine. "
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0035  ; Text $0035: "If it was not for this hole... Oh my dea"
    dw $FF03  ; SetEventFlag
    dw $0015  ; Text $0015: "His Majesty is in trouble. Please provid"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF12  ; WriteRAM
    dw $D93A  ; RAM $D93A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF12  ; WriteRAM
    dw $D97B  ; RAM $D97B
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF00  ; BranchIfFlagClear
    dw $002D  ; Text $002D: "Here it is again. The Starry Night comes"
    dw Bank0E_ScriptAddr_557C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F6  ; Text $00F6: "It's a tie... In this case... I win anyw"
    dw Bank0E_ScriptAddr_55A0          ; -> branch target
Bank0E_ScriptAddr_557C:
    dw $FF01  ; BranchIfFlagSet
    dw $00F6  ; Text $00F6: "It's a tie... In this case... I win anyw"
    dw Bank0E_ScriptAddr_5596          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00EE  ; Text $00EE: "Gwrr, Gwrr... // In the back, they teach"
    dw Bank0E_ScriptAddr_558C          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_55AA          ; -> branch target
Bank0E_ScriptAddr_558C:
    dw $FF12  ; WriteRAM
    dw $D93A  ; RAM $D93A
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_55AA          ; -> branch target
Bank0E_ScriptAddr_5596:
    dw $FF12  ; WriteRAM
    dw $D93A  ; RAM $D93A
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_55AA          ; -> branch target
Bank0E_ScriptAddr_55A0:
    dw $FF12  ; WriteRAM
    dw $D93A  ; RAM $D93A
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_55AA          ; -> branch target
Bank0E_ScriptAddr_55AA:
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $00E8  ; Text $00E8: "The last battle in G class is with the p"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossPeace Per-Script Table (map_type=$36, 9 scripts)
; ---------------------------------------------------------------------------
BossPeace_ScriptPtrTable:
    dw BossPeace_Script00              ; script 0
    dw BossPeace_Script01              ; script 1
    dw BossPeace_Script02              ; script 2
    dw BossPeace_Script03              ; script 3
    dw BossPeace_Script04              ; script 4
    dw BossPeace_Script05              ; script 5
    dw BossPeace_Script06              ; script 6
    dw BossPeace_Script07              ; script 7
    dw BossPeace_Script08              ; script 8
; ---------------------------------------------------------------------------
; BossPeace_Script00
; ---------------------------------------------------------------------------
BossPeace_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossPeace_Script01
; ---------------------------------------------------------------------------
BossPeace_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $0016  ; Text $0016: "Please listen to his wish. // This is th"
    dw Bank0E_ScriptAddr_55FE          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00C2
    dw Bank0E_ScriptAddr_55FA          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00C1  ; Text $00C1: "level. KingGo and ask Pulio for your mon"
    dw Bank0E_ScriptAddr_55F2          ; -> branch target
    dw $0299  ; Text $0299: "MickAs proof of my friendship let's bree"
    dw $FF03  ; SetEventFlag
    dw $00C1  ; Text $00C1: "level. KingGo and ask Pulio for your mon"
    dw $FFFF  ; END

Bank0E_ScriptAddr_55F2:
    dw $0311  ; Text $0311: "The slot machine is out of order. // The"
    dw $FF03  ; SetEventFlag
    dw $00C2
    dw $FFFF  ; END

Bank0E_ScriptAddr_55FA:
    dw $0312  ; Text $0312: "There are 3 Slimes sleeping inside. // ["
    dw $FFFF  ; END

Bank0E_ScriptAddr_55FE:
    dw $0313  ; Text $0313: "[HERO] pulled the slot machine! The reel"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossPeace_Script02
; ---------------------------------------------------------------------------
BossPeace_Script02:
    dw $FF01  ; BranchIfFlagSet
    dw $0016  ; Text $0016: "Please listen to his wish. // This is th"
    dw Bank0E_ScriptAddr_5628          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00C4
    dw Bank0E_ScriptAddr_5624          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00C3  ; Text $00C3: "the new master Watabou brought here? // "
    dw Bank0E_ScriptAddr_561C          ; -> branch target
    dw $0314  ; Text $0314: "[HERO] pulled the arm of the slot machin"
    dw $FF03  ; SetEventFlag
    dw $00C3  ; Text $00C3: "the new master Watabou brought here? // "
    dw $FFFF  ; END

Bank0E_ScriptAddr_561C:
    dw $0315  ; Text $0315: "It's out of order. // 3 Metalys are swea"
    dw $FF03  ; SetEventFlag
    dw $00C4
    dw $FFFF  ; END

Bank0E_ScriptAddr_5624:
    dw $0316  ; Text $0316: "3 Metalys are sweating inside the machin"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5628:
    dw $0317  ; Text $0317: "[HERO] pulled the arm of the slot machin"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossPeace_Script03
; ---------------------------------------------------------------------------
BossPeace_Script03:
    dw $FF01  ; BranchIfFlagSet
    dw $0016  ; Text $0016: "Please listen to his wish. // This is th"
    dw Bank0E_ScriptAddr_5644          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00C5
    dw Bank0E_ScriptAddr_5640          ; -> branch target
    dw $0318  ; Text $0318: "The reel is spinning... // [HERO] pulled"
    dw $FF03  ; SetEventFlag
    dw $00C5
    dw $FFFF  ; END

Bank0E_ScriptAddr_5640:
    dw $0319  ; Text $0319: "[HERO] pulled the slot machine! The reel"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5644:
    dw $0843
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossPeace_Script04
; ---------------------------------------------------------------------------
BossPeace_Script04:
    dw $FF01  ; BranchIfFlagSet
    dw $0016  ; Text $0016: "Please listen to his wish. // This is th"
    dw Bank0E_ScriptAddr_5660          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00C6  ; Text $00C6: "master? His Majesty has a favor to ask y"
    dw Bank0E_ScriptAddr_565C          ; -> branch target
    dw $031A  ; Text $031A: "What do you say? Why don't you breed wit"
    dw $FF03  ; SetEventFlag
    dw $00C6  ; Text $00C6: "master? His Majesty has a favor to ask y"
    dw $FFFF  ; END

Bank0E_ScriptAddr_565C:
    dw $0322  ; Text $0322: "There is a sign on the slot machine. No "
    dw $FFFF  ; END

Bank0E_ScriptAddr_5660:
    dw $0323  ; Text $0323: "Welcome to the Casino! Gold here is only"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossPeace_Script05
; ---------------------------------------------------------------------------
BossPeace_Script05:
    dw $0324  ; Text $0324: "How's your luck? // I need to get good a"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossPeace_Script06
; ---------------------------------------------------------------------------
BossPeace_Script06:
    dw $FF01  ; BranchIfFlagSet
    dw $0016  ; Text $0016: "Please listen to his wish. // This is th"
    dw Bank0E_ScriptAddr_5672          ; -> branch target
    dw $0325  ; Text $0325: "I need to get good at it. // That custom"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5672:
    dw $0326  ; Text $0326: "That customer has an attitude! Can you d"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossPeace_Script07
; ---------------------------------------------------------------------------
BossPeace_Script07:
    dw $FF01  ; BranchIfFlagSet
    dw $0016  ; Text $0016: "Please listen to his wish. // This is th"
    dw Bank0E_ScriptAddr_5680          ; -> branch target
    dw $0327  ; Text $0327: "No violence in this store. // Gwrrrrrrrr"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5680:
    dw $0328  ; Text $0328: "Gwrrrrrrrr.. This machine gave me nothin"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossPeace_Script08
; ---------------------------------------------------------------------------
BossPeace_Script08:
    dw $FF01  ; BranchIfFlagSet
    dw $00C7  ; Text $00C7: "ou leave the monsters here. SlioBut the "
    dw Bank0E_ScriptAddr_574A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00C6  ; Text $00C6: "master? His Majesty has a favor to ask y"
    dw Bank0E_ScriptAddr_5694          ; -> branch target
    dw $0329  ; Text $0329: "Gwrrrrrrrr.. Why are you the only lucky "
    dw $FFFF  ; END

Bank0E_ScriptAddr_5694:
    dw $032A  ; Text $032A: "It's mine now!! // Because you trusted m"
    dw $FF03  ; SetEventFlag
    dw $00C7  ; Text $00C7: "ou leave the monsters here. SlioBut the "
    dw $FF5A  ; Cmd5A
    dw $004B  ; Text $004B: "KingI see. Now [HERO], proceed to the Tr"
    dw $FF07  ; InitDialogMode
    dw $0346  ; Text $0346: "WatabouDid you have a good time at the c"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0304  ; Text $0304: "You again!? I'm really gonna get you now"
    dw $FF1C  ; CompareRAM
    dw $1605
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF07  ; InitDialogMode
    dw $0347  ; Text $0347: "Ha ha ha! I made Gigantes smug! // Well."
    dw $FF1C  ; CompareRAM
    dw $0405  ; Text $0405: "How about monsters living behind the Gat"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0036  ; Text $0036: "[HERO] read the sign. When the GreatTree"
    dw $FF03  ; SetEventFlag
    dw $0016  ; Text $0016: "Please listen to his wish. // This is th"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF12  ; WriteRAM
    dw $D96B  ; RAM $D96B
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF12  ; WriteRAM
    dw $D97C  ; RAM $D97C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF00  ; BranchIfFlagClear
    dw $0017  ; Text $0017: "This is the castle of GreatTree. // Hurr"
    dw $573E
    dw $FF12  ; WriteRAM
    dw $D96B  ; RAM $D96B
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $00E8  ; Text $00E8: "The last battle in G class is with the p"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FFFF  ; END

Bank0E_ScriptAddr_574A:
    dw $032B  ; Text $032B: "Because you trusted me, I'll give you so"
    dw $FF14  ; ClearGameFlags
    dw $569A
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBravery Per-Script Table (map_type=$37, 5 scripts)
; ---------------------------------------------------------------------------
BossBravery_ScriptPtrTable:
    dw BossBravery_Script00            ; script 0
    dw BossBravery_Script01            ; script 1
    dw BossBravery_Script02            ; script 2
    dw BossBravery_Script03            ; script 3
    dw BossBravery_Script04            ; script 4
; ---------------------------------------------------------------------------
; BossBravery_Script00
; ---------------------------------------------------------------------------
BossBravery_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF15  ; PlaySE
    dw $D9E5  ; RAM $D9E5
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0E_ScriptAddr_5774          ; -> branch target
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5774:
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0050  ; Text $0050: "These stairs bring you to the Chamber of"
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0060  ; Text $0060: "Oh boy! This looks dangerous! Oh, no! //"
    dw $FF1B  ; MultiRAMWrite
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $0070
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF12  ; WriteRAM
    dw $D9E5  ; RAM $D9E5
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBravery_Script01
; ---------------------------------------------------------------------------
BossBravery_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00C9  ; Text $00C9: "ou leave the monsters here. SlioBut the "
    dw Bank0E_ScriptAddr_58D4          ; -> branch target
    dw $03F6  ; Text $03F6: "When a monster learns two certain skills"
    dw $FF03  ; SetEventFlag
    dw $00C9  ; Text $00C9: "ou leave the monsters here. SlioBut the "
    dw $FF5A  ; Cmd5A
    dw $004D  ; Text $004D: "Give the courageous master [HERO] the po"
    dw $FF07  ; InitDialogMode
    dw $051C  ; Text $051C: "WatabouGood job finding the invisible fl"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0D  ; WriteNPCByte
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0406  ; Text $0406: "Behind the Gate of Memories are, Goopis,"
    dw $FF1C  ; CompareRAM
    dw $1507
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF07  ; InitDialogMode
    dw $051D  ; Text $051D: "Wow! Yummy meat! Yum! // Wow, yummy meat"
    dw $FF1C  ; CompareRAM
    dw $0407  ; Text $0407: "How about the monsters behind the Gates "
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF47  ; Cmd47
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw $FF03  ; SetEventFlag
    dw $0017  ; Text $0017: "This is the castle of GreatTree. // Hurr"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF12  ; WriteRAM
    dw $D96B  ; RAM $D96B
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF12  ; WriteRAM
    dw $D97D  ; RAM $D97D
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF00  ; BranchIfFlagClear
    dw $0016  ; Text $0016: "Please listen to his wish. // This is th"
    dw Bank0E_ScriptAddr_58C8          ; -> branch target
    dw $FF12  ; WriteRAM
    dw $D96B  ; RAM $D96B
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
Bank0E_ScriptAddr_58C8:
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $00E8  ; Text $00E8: "The last battle in G class is with the p"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FFFF  ; END

Bank0E_ScriptAddr_58D4:
    dw $0467  ; Text $0467: "om nowhere in a foreign kingdom. When th"
    dw $FF14  ; ClearGameFlags
    dw $5824
; ---------------------------------------------------------------------------
; BossBravery_Script02
; ---------------------------------------------------------------------------
BossBravery_Script02:
    dw $FF01  ; BranchIfFlagSet
    dw $00AA  ; Text $00AA: "ou... zzz. // Terry looked at a stuffed "
    dw Bank0E_ScriptAddr_59B0          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00C8
    dw Bank0E_ScriptAddr_59B0          ; -> branch target
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF47  ; Cmd47
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0B  ; NPCMoveY
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FFF0  ; Cmd$F0
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0080  ; Text $0080: "PulioThank you [HERO]! Now I can go back"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF1D  ; LockMovement
    dw $FF1C  ; CompareRAM
    dw $0F06
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0B  ; NPCMoveY
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FFF0  ; Cmd$F0
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF4A  ; Cmd4A
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF47  ; Cmd47
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF1C  ; CompareRAM
    dw $0105  ; Text $0105: "The battle classes go from S,A down to G"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF49  ; Cmd49
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF49  ; Cmd49
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF48  ; Cmd48
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF07  ; InitDialogMode
    dw $03F5  ; Text $03F5: "There are cliffs that you can jump down."
    dw $FF06  ; IncrementCounter
    dw $FF0B  ; NPCMoveY
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0080  ; Text $0080: "PulioThank you [HERO]! Now I can go back"
    dw $FF1D  ; LockMovement
    dw $FF1C  ; CompareRAM
    dw $1006
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0B  ; NPCMoveY
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF03  ; SetEventFlag
    dw $00C8
    dw $FFFF  ; END

Bank0E_ScriptAddr_59B0:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBravery_Script03
; ---------------------------------------------------------------------------
BossBravery_Script03:
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "Welcome to the Chamber of Travelers' Gat"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFF0  ; Cmd$F0
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFF0  ; Cmd$F0
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFF0  ; Cmd$F0
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $000F  ; Text $000F: "This kingdom is created inside a big tre"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF12  ; WriteRAM
    dw $D9E5  ; RAM $D9E5
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF0F  ; SetScreenScroll
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $0078
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBravery_Script04
; ---------------------------------------------------------------------------
BossBravery_Script04:
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "Welcome to the Chamber of Travelers' Gat"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $000F  ; Text $000F: "This kingdom is created inside a big tre"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF12  ; WriteRAM
    dw $D9E5  ; RAM $D9E5
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF0F  ; SetScreenScroll
    dw $0037  ; Text $0037: "I heard that Pulio let the monsters esca"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $0078
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map38 Per-Script Table (map_type=$38, 17 scripts)
; ---------------------------------------------------------------------------
Map38_ScriptPtrTable:
    dw Map38_Script00                  ; script 0
    dw Map38_Script01                  ; script 1
    dw Map38_Script02                  ; script 2
    dw Map38_Script03                  ; script 3
    dw Map38_Script04                  ; script 4
    dw Map38_Script05                  ; script 5
    dw Map38_Script06                  ; script 6
    dw Map38_Script07                  ; script 7
    dw Map38_Script08                  ; script 8
    dw Map38_Script09                  ; script 9
    dw Map38_Script10                  ; script 10
    dw Map38_Script11                  ; script 11
    dw Map38_Script12                  ; script 12
    dw Map38_Script13                  ; script 13
    dw Map38_Script14                  ; script 14
    dw Map38_Script15                  ; script 15
    dw Map38_Script16                  ; script 16
; ---------------------------------------------------------------------------
; Map38_Script00
; ---------------------------------------------------------------------------
Map38_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF15  ; PlaySE
    dw $D9E5  ; RAM $D9E5
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0E_ScriptAddr_5A88          ; -> branch target
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5A88:
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0020  ; Text $0020: "KingOh [HERO]! Will you comply with my w"
    dw $FF1B  ; MultiRAMWrite
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $0030  ; Text $0030: "Upper floor, the monster farm. Pulio tak"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF12  ; WriteRAM
    dw $D9E5  ; RAM $D9E5
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map38_Script01
; ---------------------------------------------------------------------------
Map38_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00CA  ; Text $00CA: "opened a treasure chest! // [HERO] picke"
    dw Bank0E_ScriptAddr_5BD6          ; -> branch target
    dw $051E  ; Text $051E: "Wow, yummy meat comming this way again! "
    dw $FF03  ; SetEventFlag
    dw $00CA  ; Text $00CA: "opened a treasure chest! // [HERO] picke"
    dw $FF5A  ; Cmd5A
    dw $004F  ; Text $004F: "PulioSorry [HERO], It's my fault... Puli"
    dw $FF07  ; InitDialogMode
    dw $0520  ; Text $0520: "WatabouIt seems you had a hard time in t"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0D  ; WriteNPCByte
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0308  ; Text $0308: "The quake of GreatTree must have some co"
    dw $FF1C  ; CompareRAM
    dw $1607
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF07  ; InitDialogMode
    dw $0521  ; Text $0521: "[HERO] checked out a treasure chest! Wow"
    dw $FF1C  ; CompareRAM
    dw $0407  ; Text $0407: "How about the monsters behind the Gates "
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF48  ; Cmd48
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0038  ; Text $0038: "Hey, Mr.Monster Master. I wonder what I "
    dw $FF03  ; SetEventFlag
    dw $0018  ; Text $0018: "Hurry! Go see the King! // I see..... //"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF12  ; WriteRAM
    dw $D960  ; RAM $D960
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF12  ; WriteRAM
    dw $D97E  ; RAM $D97E
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $00E8  ; Text $00E8: "The last battle in G class is with the p"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5BD6:
    dw $051F  ; Text $051F: "Wow! I'll do anything for the meat! // W"
    dw $FF14  ; ClearGameFlags
    dw $5B32
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map38_Script02
; ---------------------------------------------------------------------------
Map38_Script02:
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_5C9C          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_5C4E          ; -> branch target
; ---------------------------------------------------------------------------
; Map38_Script03
; ---------------------------------------------------------------------------
Map38_Script03:
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_5CA4          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_5C4E          ; -> branch target
; ---------------------------------------------------------------------------
; Map38_Script04
; ---------------------------------------------------------------------------
Map38_Script04:
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_5CAC          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_5C4E          ; -> branch target
; ---------------------------------------------------------------------------
; Map38_Script05
; ---------------------------------------------------------------------------
Map38_Script05:
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_5CB4          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_5C4E          ; -> branch target
; ---------------------------------------------------------------------------
; Map38_Script06
; ---------------------------------------------------------------------------
Map38_Script06:
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_5CBC          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_5C4E          ; -> branch target
; ---------------------------------------------------------------------------
; Map38_Script07
; ---------------------------------------------------------------------------
Map38_Script07:
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_5CC4          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_5C4E          ; -> branch target
; ---------------------------------------------------------------------------
; Map38_Script08
; ---------------------------------------------------------------------------
Map38_Script08:
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_5CCC          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_5C4E          ; -> branch target
; ---------------------------------------------------------------------------
; Map38_Script09
; ---------------------------------------------------------------------------
Map38_Script09:
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_5CD4          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_5C4E          ; -> branch target
; ---------------------------------------------------------------------------
; Map38_Script10
; ---------------------------------------------------------------------------
Map38_Script10:
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_5CDC          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_5C4E          ; -> branch target
; ---------------------------------------------------------------------------
; Map38_Script11
; ---------------------------------------------------------------------------
Map38_Script11:
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_5CE4          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_5C4E          ; -> branch target
; ---------------------------------------------------------------------------
; Map38_Script12
; ---------------------------------------------------------------------------
Map38_Script12:
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_5CEC          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_5C4E          ; -> branch target
; ---------------------------------------------------------------------------
; Map38_Script13
; ---------------------------------------------------------------------------
Map38_Script13:
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_5CF4          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_5C4E          ; -> branch target
; ---------------------------------------------------------------------------
; Map38_Script14
; ---------------------------------------------------------------------------
Map38_Script14:
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_5CFC          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_5C4E          ; -> branch target
; ---------------------------------------------------------------------------
; Map38_Script15
; ---------------------------------------------------------------------------
Map38_Script15:
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_5D04          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_5C4E          ; -> branch target
Bank0E_ScriptAddr_5C4E:
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "Welcome to the Chamber of Travelers' Gat"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFF0  ; Cmd$F0
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFF0  ; Cmd$F0
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $000F  ; Text $000F: "This kingdom is created inside a big tre"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF12  ; WriteRAM
    dw $D9E5  ; RAM $D9E5
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF0F  ; SetScreenScroll
    dw $0038  ; Text $0038: "Hey, Mr.Monster Master. I wonder what I "
    dw $0088
    dw $0038  ; Text $0038: "Hey, Mr.Monster Master. I wonder what I "
    dw $FFFF  ; END

Bank0E_ScriptAddr_5C9C:
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5CA4:
    dw $000A  ; Text $000A: "Terry looks at the bookshelf. Encycloped"
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5CAC:
    dw $000C  ; Text $000C: "Terry looked in front of him. The clock "
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5CB4:
    dw $0042  ; Text $0042: "SlioDn'a wanna know about the farm? [Y/N"
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5CBC:
    dw $008A
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5CC4:
    dw $0090
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5CCC:
    dw $0104  ; Text $0104: "Welcome to the arena! Want to hear about"
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5CD4:
    dw $0106  ; Text $0106: "The last battle in G class is with the p"
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5CDC:
    dw $0108  ; Text $0108: "Get out of my way! Huff! // You hear a v"
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5CE4:
    dw $010E  ; Text $010E: "Where did the MiniDrak go? // Let's play"
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5CEC:
    dw $0110  ; Text $0110: "Hm, its not fun. // Select your choice b"
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5CF4:
    dw $014E  ; Text $014E: "The Gate is shut tight. // The Gate is s"
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5CFC:
    dw $0182  ; Text $0182: "So, you don't have enough money to buy i"
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5D04:
    dw $018A  ; Text $018A: "Wow! No way! Such a thing in a place lik"
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
; ---------------------------------------------------------------------------
; Map38_Script16
; ---------------------------------------------------------------------------
Map38_Script16:
    dw $FF15  ; PlaySE
    dw $D9E4  ; RAM $D9E4
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw Bank0E_ScriptAddr_5D1C          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $00CB  ; Text $00CB: "uTerry! Wait! It's time for bed! Milayou"
    dw Bank0E_ScriptAddr_5D1C          ; -> branch target
    dw $FFFF  ; END

Bank0E_ScriptAddr_5D1C:
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0030  ; Text $0030: "Upper floor, the monster farm. Pulio tak"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF49  ; Cmd49
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0A  ; NPCMoveX
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FFF0  ; Cmd$F0
    dw $FF0B  ; NPCMoveY
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0020  ; Text $0020: "KingOh [HERO]! Will you comply with my w"
    dw $FF0A  ; NPCMoveX
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF09  ; SetDelay
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF47  ; Cmd47
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0A  ; NPCMoveX
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FFF0  ; Cmd$F0
    dw $FF0B  ; NPCMoveY
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FFE0  ; Cmd$E0
    dw $FF0A  ; NPCMoveX
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0030  ; Text $0030: "Upper floor, the monster farm. Pulio tak"
    dw $FF0B  ; NPCMoveY
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FFF0  ; Cmd$F0
    dw $FF0A  ; NPCMoveX
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_5CBC          ; -> branch target
    dw $FF4D  ; SetLongDelay
    dw $000A  ; Text $000A: "Terry looks at the bookshelf. Encycloped"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0020  ; Text $0020: "KingOh [HERO]! Will you comply with my w"
    dw $FF49  ; Cmd49
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $000A  ; Text $000A: "Terry looks at the bookshelf. Encycloped"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $000A  ; Text $000A: "Terry looks at the bookshelf. Encycloped"
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $000A  ; Text $000A: "Terry looks at the bookshelf. Encycloped"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0080  ; Text $0080: "PulioThank you [HERO]! Now I can go back"
    dw $FF09  ; SetDelay
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "Welcome to the Chamber of Travelers' Gat"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF09  ; SetDelay
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF12  ; WriteRAM
    dw $D9E4  ; RAM $D9E4
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF03  ; SetEventFlag
    dw $00CB  ; Text $00CB: "uTerry! Wait! It's time for bed! Milayou"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map39 Per-Script Table (map_type=$39, 5 scripts)
; ---------------------------------------------------------------------------
Map39_ScriptPtrTable:
    dw Map39_Script00                  ; script 0
    dw Map39_Script01                  ; script 1
    dw Map39_Script02                  ; script 2
    dw Map39_Script03                  ; script 3
    dw Map39_Script04                  ; script 4
; ---------------------------------------------------------------------------
; Map39_Script00
; ---------------------------------------------------------------------------
Map39_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0080  ; Text $0080: "PulioThank you [HERO]! Now I can go back"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map39_Script01
; ---------------------------------------------------------------------------
Map39_Script01:
    dw $0523  ; Text $0523: "...... // So,yoooou saaaw my face...!! /"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map39_Script02
; ---------------------------------------------------------------------------
Map39_Script02:
    dw $0522  ; Text $0522: "[HERO] looked into a jar. There was a da"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map39_Script03
; ---------------------------------------------------------------------------
Map39_Script03:
    dw $FF00  ; BranchIfFlagClear
    dw $00CC  ; Text $00CC: "ree... Want to read the book?[Y/N] // It"
    dw Bank0E_ScriptAddr_5E5C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00CD  ; Text $00CD: "to be powerful! // SlioDn'a wanna know a"
    dw Bank0E_ScriptAddr_5F1E          ; -> branch target
Bank0E_ScriptAddr_5E5C:
    dw $FF01  ; BranchIfFlagSet
    dw $00CD  ; Text $00CD: "to be powerful! // SlioDn'a wanna know a"
    dw Bank0E_ScriptAddr_5F1A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00CC  ; Text $00CC: "ree... Want to read the book?[Y/N] // It"
    dw Bank0E_ScriptAddr_5E6C          ; -> branch target
    dw $0524  ; Text $0524: "So,yoooou saaaw my face...!! // It's yoo"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5E6C:
    dw $0525  ; Text $0525: "It's yoooou agaaaain! // Yoooou win...!!"
    dw $FF03  ; SetEventFlag
    dw $00CD  ; Text $00CD: "to be powerful! // SlioDn'a wanna know a"
    dw $FF02  ; ClearEventFlag
    dw $00CC  ; Text $00CC: "ree... Want to read the book?[Y/N] // It"
    dw $FF5A  ; Cmd5A
    dw $0063  ; Text $0063: "Oh [HERO], it's you. I am getting old. J"
    dw $FF07  ; InitDialogMode
    dw $0527  ; Text $0527: "WatabouGood work! So,let's gooooo baaack"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0308  ; Text $0308: "The quake of GreatTree must have some co"
    dw $FF1C  ; CompareRAM
    dw $1502
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF07  ; InitDialogMode
    dw $0528  ; Text $0528: "Squeak squeak! Strike! // Good lord, You"
    dw $FF1C  ; CompareRAM
    dw $0402  ; Text $0402: "If you don't want to know, that's fine. "
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0039  ; Text $0039: "[HERO] looked into the jar. // [HERO] lo"
    dw $FF03  ; SetEventFlag
    dw $0019  ; Text $0019: "I see..... // [HERO] opened a treasure c"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF12  ; WriteRAM
    dw $D96C  ; RAM $D96C
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF12  ; WriteRAM
    dw $D97F  ; RAM $D97F
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $00E8  ; Text $00E8: "The last battle in G class is with the p"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5F1A:
    dw $0524  ; Text $0524: "So,yoooou saaaw my face...!! // It's yoo"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5F1E:
    dw $0526  ; Text $0526: "Yoooou win...!! // WatabouGood work! So,"
    dw $FF02  ; ClearEventFlag
    dw $00CC  ; Text $00CC: "ree... Want to read the book?[Y/N] // It"
    dw $FF14  ; ClearGameFlags
    dw $5E76
; ---------------------------------------------------------------------------
; Map39_Script04
; ---------------------------------------------------------------------------
Map39_Script04:
    dw $FF01  ; BranchIfFlagSet
    dw $00CC  ; Text $00CC: "ree... Want to read the book?[Y/N] // It"
    dw Bank0E_ScriptAddr_5F48          ; -> branch target
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF08  ; NOP
    dw $FF10  ; NPCAnimStart
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0038  ; Text $0038: "Hey, Mr.Monster Master. I wonder what I "
    dw $FF11  ; NPCAnimSetup
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FF03  ; SetEventFlag
    dw $00CC  ; Text $00CC: "ree... Want to read the book?[Y/N] // It"
Bank0E_ScriptAddr_5F48:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3A Per-Script Table (map_type=$3A, 9 scripts)
; ---------------------------------------------------------------------------
Map3A_ScriptPtrTable:
    dw Map3A_Script00                  ; script 0
    dw Map3A_Script01                  ; script 1
    dw Map3A_Script02                  ; script 2
    dw Map3A_Script03                  ; script 3
    dw Map3A_Script04                  ; script 4
    dw Map3A_Script05                  ; script 5
    dw Map3A_Script06                  ; script 6
    dw Map3A_Script07                  ; script 7
    dw Map3A_Script08                  ; script 8
; ---------------------------------------------------------------------------
; Map3A_Script00
; ---------------------------------------------------------------------------
Map3A_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF15  ; PlaySE
    dw $D9E5  ; RAM $D9E5
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0E_ScriptAddr_5F74          ; -> branch target
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5F74:
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0050  ; Text $0050: "These stairs bring you to the Chamber of"
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0060  ; Text $0060: "Oh boy! This looks dangerous! Oh, no! //"
    dw $FF1B  ; MultiRAMWrite
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $0070
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF12  ; WriteRAM
    dw $D9E5  ; RAM $D9E5
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3A_Script01
; ---------------------------------------------------------------------------
Map3A_Script01:
    dw $0529  ; Text $0529: "Good lord, You're good! // WatabouGood w"
    dw $FF5A  ; Cmd5A
    dw $007D
    dw $FF07  ; InitDialogMode
    dw $052A  ; Text $052A: "WatabouGood work reading SkyDragon's mov"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0105  ; Text $0105: "The battle classes go from S,A down to G"
    dw $FF1C  ; CompareRAM
    dw $1506
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF07  ; InitDialogMode
    dw $052B  ; Text $052B: "Look at my cool steps! // Why don't you "
    dw $FF1C  ; CompareRAM
    dw $0406  ; Text $0406: "Behind the Gate of Memories are, Goopis,"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF48  ; Cmd48
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $003A  ; Text $003A: "[HERO] looked into the jar. The jar is f"
    dw $FF03  ; SetEventFlag
    dw $001A  ; Text $001A: "[HERO] opened a treasure chest! // [HERO"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF12  ; WriteRAM
    dw $D96D  ; RAM $D96D
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF12  ; WriteRAM
    dw $D980  ; RAM $D980
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF00  ; BranchIfFlagClear
    dw $001C  ; Text $001C: "[HERO] found an Herb. But cannot carry a"
    dw Bank0E_ScriptAddr_60BE          ; -> branch target
    dw $FF12  ; WriteRAM
    dw $D96D  ; RAM $D96D
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
Bank0E_ScriptAddr_60BE:
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $00E8  ; Text $00E8: "The last battle in G class is with the p"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3A_Script02
; ---------------------------------------------------------------------------
Map3A_Script02:
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "Welcome to the Chamber of Travelers' Gat"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFF0  ; Cmd$F0
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $000F  ; Text $000F: "This kingdom is created inside a big tre"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF12  ; WriteRAM
    dw $D9E5  ; RAM $D9E5
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF0F  ; SetScreenScroll
    dw $003A  ; Text $003A: "[HERO] looked into the jar. The jar is f"
    dw $0018  ; Text $0018: "Hurry! Go see the King! // I see..... //"
    dw $0078
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3A_Script03
; ---------------------------------------------------------------------------
Map3A_Script03:
    dw $FF10  ; NPCAnimStart
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0078
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3A_Script04
; ---------------------------------------------------------------------------
Map3A_Script04:
    dw $FF10  ; NPCAnimStart
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3A_Script05
; ---------------------------------------------------------------------------
Map3A_Script05:
    dw $FF10  ; NPCAnimStart
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0018  ; Text $0018: "Hurry! Go see the King! // I see..... //"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3A_Script06
; ---------------------------------------------------------------------------
Map3A_Script06:
    dw $FF10  ; NPCAnimStart
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0078
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3A_Script07
; ---------------------------------------------------------------------------
Map3A_Script07:
    dw $FF10  ; NPCAnimStart
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3A_Script08
; ---------------------------------------------------------------------------
Map3A_Script08:
    dw $FF10  ; NPCAnimStart
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0038  ; Text $0038: "Hey, Mr.Monster Master. I wonder what I "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3B Per-Script Table (map_type=$3B, 2 scripts)
; ---------------------------------------------------------------------------
Map3B_ScriptPtrTable:
    dw Map3B_Script00                  ; script 0
    dw Map3B_Script01                  ; script 1
; ---------------------------------------------------------------------------
; Map3B_Script00
; ---------------------------------------------------------------------------
Map3B_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3B_Script01
; ---------------------------------------------------------------------------
Map3B_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00CF
    dw Bank0E_ScriptAddr_622E          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00CE
    dw Bank0E_ScriptAddr_6170          ; -> branch target
    dw $052C  ; Text $052C: "Why don't you dance with me? // You came"
    dw $FF03  ; SetEventFlag
    dw $00CE
    dw $FFFF  ; END

Bank0E_ScriptAddr_6170:
    dw $052D  ; Text $052D: "You came again to dance with me? Ready? "
    dw $FF03  ; SetEventFlag
    dw $00CF
    dw $FF5A  ; Cmd5A
    dw $007B
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF07  ; InitDialogMode
    dw $052F  ; Text $052F: "Did you enjoy dancing? Well, let's go ba"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0405  ; Text $0405: "How about monsters living behind the Gat"
    dw $FF1C  ; CompareRAM
    dw $1502
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF07  ; InitDialogMode
    dw $0530  ; Text $0530: "There is a voice coming from out of nowh"
    dw $FF1C  ; CompareRAM
    dw $0402  ; Text $0402: "If you don't want to know, that's fine. "
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $003B  ; Text $003B: "Hey you! You came here to steal my monst"
    dw $FF03  ; SetEventFlag
    dw $001C  ; Text $001C: "[HERO] found an Herb. But cannot carry a"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF12  ; WriteRAM
    dw $D96D  ; RAM $D96D
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF12  ; WriteRAM
    dw $D981  ; RAM $D981
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF00  ; BranchIfFlagClear
    dw $001A  ; Text $001A: "[HERO] opened a treasure chest! // [HERO"
    dw $6222
    dw $FF12  ; WriteRAM
    dw $D96D  ; RAM $D96D
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $00E8  ; Text $00E8: "The last battle in G class is with the p"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FFFF  ; END

Bank0E_ScriptAddr_622E:
    dw $052E  ; Text $052E: "You're a great dancer! // Did you enjoy "
    dw $FF14  ; ClearGameFlags
    dw $6176
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3C Per-Script Table (map_type=$3C, 9 scripts)
; ---------------------------------------------------------------------------
Map3C_ScriptPtrTable:
    dw Map3C_Script00                  ; script 0
    dw Map3C_Script01                  ; script 1
    dw Map3C_Script02                  ; script 2
    dw Map3C_Script03                  ; script 3
    dw Map3C_Script04                  ; script 4
    dw Map3C_Script05                  ; script 5
    dw Map3C_Script06                  ; script 6
    dw Map3C_Script07                  ; script 7
    dw Map3C_Script08                  ; script 8
; ---------------------------------------------------------------------------
; Map3C_Script00
; ---------------------------------------------------------------------------
Map3C_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF01  ; BranchIfFlagSet
    dw $0077
    dw Bank0E_ScriptAddr_627C          ; -> branch target
    dw $FF02  ; ClearEventFlag
    dw $006F  ; Text $006F: "If you take monsters on a journey, they "
    dw $FF02  ; ClearEventFlag
    dw $0070
    dw $FF02  ; ClearEventFlag
    dw $0071
    dw $FF02  ; ClearEventFlag
    dw $0072
    dw $FF02  ; ClearEventFlag
    dw $0073
    dw $FF02  ; ClearEventFlag
    dw $0074
    dw $FF02  ; ClearEventFlag
    dw $0075
    dw $FF02  ; ClearEventFlag
    dw $0076
Bank0E_ScriptAddr_627C:
    dw $FFFF  ; END

Bank0E_ScriptAddr_627E:
    dw $0088
    dw $4B4A
    dw $5AD8
    dw $D95B  ; RAM $D95B
Bank0E_ScriptAddr_6286:
    dw $00C4
    dw $4B4A
    dw $5AD8
    dw $D95B  ; RAM $D95B
Bank0E_ScriptAddr_628E:
    dw $0102  ; Text $0102: "Well done! You survived G class! // Oh, "
    dw $4B4A
    dw $5AD8
    dw $D95B  ; RAM $D95B
Bank0E_ScriptAddr_6296:
    dw $0110  ; Text $0110: "Hm, its not fun. // Select your choice b"
    dw $4B4A
    dw $5AD8
    dw $D95B  ; RAM $D95B
Bank0E_ScriptAddr_629E:
    dw $014C  ; Text $014C: "Great! Go to the room above then. // We "
    dw $4B4A
    dw $5AD8
    dw $D95B  ; RAM $D95B
Bank0E_ScriptAddr_62A6:
    dw $00C6  ; Text $00C6: "master? His Majesty has a favor to ask y"
    dw $4B4A
    dw $5AD8
    dw $D95B  ; RAM $D95B
Bank0E_ScriptAddr_62AE:
    dw $010E  ; Text $010E: "Where did the MiniDrak go? // Let's play"
    dw $4B4A
    dw $5AD8
    dw $D95B  ; RAM $D95B
    dw $0084
    dw $4B4A
    dw $4B4A
    dw $4B4A
    dw $5AD8
    dw $5A5B
    dw $5A5B
    dw $D85B  ; RAM $D85B
    dw $4B4A
    dw $4B4A
    dw $5AD8
    dw $5A5B
    dw $D95B  ; RAM $D95B
    dw $00C2
    dw $4B4A
    dw $5AD8
    dw $D85B  ; RAM $D85B
    dw $4B4A
    dw $5AD8
    dw $D95B  ; RAM $D95B
    dw $014C  ; Text $014C: "Great! Go to the room above then. // We "
    dw $4B4A
    dw $4B4A
    dw $5AD8
    dw $5A5B
    dw $D85B  ; RAM $D85B
    dw $4B4A
    dw $4B4A
    dw $5AD8
    dw $5A5B
    dw $D85B  ; RAM $D85B
    dw $4B4A
    dw $5AD8
    dw $D95B  ; RAM $D95B
; ---------------------------------------------------------------------------
; Map3C_Script01
; ---------------------------------------------------------------------------
Map3C_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $0077
    dw Bank0E_ScriptAddr_631C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0070
    dw Bank0E_ScriptAddr_631C          ; -> branch target
    dw $02A2  ; Text $02A2: "[HERO] looked at the egg. The egg is cra"
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_627E          ; -> branch target
    dw $FF06  ; IncrementCounter
    dw $FF03  ; SetEventFlag
    dw $006F  ; Text $006F: "If you take monsters on a journey, they "
    dw $FF03  ; SetEventFlag
    dw $0070
    dw $FF05  ; TriggerBattle
    dw $015D  ; Text $015D: "How many times do I have to say it?! I d"
    dw $FFFF  ; END

Bank0E_ScriptAddr_631C:
    dw $02A3  ; Text $02A3: "Arrrgh! How dare you crack all my eggs! "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3C_Script02
; ---------------------------------------------------------------------------
Map3C_Script02:
    dw $FF01  ; BranchIfFlagSet
    dw $0077
    dw Bank0E_ScriptAddr_6342          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0071
    dw Bank0E_ScriptAddr_6342          ; -> branch target
    dw $02A2  ; Text $02A2: "[HERO] looked at the egg. The egg is cra"
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_6286          ; -> branch target
    dw $FF06  ; IncrementCounter
    dw $FF03  ; SetEventFlag
    dw $006F  ; Text $006F: "If you take monsters on a journey, they "
    dw $FF03  ; SetEventFlag
    dw $0071
    dw $FF05  ; TriggerBattle
    dw $015D  ; Text $015D: "How many times do I have to say it?! I d"
    dw $FFFF  ; END

Bank0E_ScriptAddr_6342:
    dw $02A3  ; Text $02A3: "Arrrgh! How dare you crack all my eggs! "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3C_Script03
; ---------------------------------------------------------------------------
Map3C_Script03:
    dw $FF01  ; BranchIfFlagSet
    dw $0077
    dw Bank0E_ScriptAddr_6368          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0072
    dw Bank0E_ScriptAddr_6368          ; -> branch target
    dw $02A2  ; Text $02A2: "[HERO] looked at the egg. The egg is cra"
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_628E          ; -> branch target
    dw $FF06  ; IncrementCounter
    dw $FF03  ; SetEventFlag
    dw $006F  ; Text $006F: "If you take monsters on a journey, they "
    dw $FF03  ; SetEventFlag
    dw $0072
    dw $FF05  ; TriggerBattle
    dw $015D  ; Text $015D: "How many times do I have to say it?! I d"
    dw $FFFF  ; END

Bank0E_ScriptAddr_6368:
    dw $02A3  ; Text $02A3: "Arrrgh! How dare you crack all my eggs! "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3C_Script04
; ---------------------------------------------------------------------------
Map3C_Script04:
    dw $FF01  ; BranchIfFlagSet
    dw $0077
    dw Bank0E_ScriptAddr_638E          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0073
    dw Bank0E_ScriptAddr_638E          ; -> branch target
    dw $02A2  ; Text $02A2: "[HERO] looked at the egg. The egg is cra"
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_6296          ; -> branch target
    dw $FF06  ; IncrementCounter
    dw $FF03  ; SetEventFlag
    dw $006F  ; Text $006F: "If you take monsters on a journey, they "
    dw $FF03  ; SetEventFlag
    dw $0073
    dw $FF05  ; TriggerBattle
    dw $015D  ; Text $015D: "How many times do I have to say it?! I d"
    dw $FFFF  ; END

Bank0E_ScriptAddr_638E:
    dw $02A3  ; Text $02A3: "Arrrgh! How dare you crack all my eggs! "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3C_Script05
; ---------------------------------------------------------------------------
Map3C_Script05:
    dw $FF01  ; BranchIfFlagSet
    dw $0077
    dw Bank0E_ScriptAddr_63B4          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0074
    dw Bank0E_ScriptAddr_63B4          ; -> branch target
    dw $02A2  ; Text $02A2: "[HERO] looked at the egg. The egg is cra"
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_629E          ; -> branch target
    dw $FF06  ; IncrementCounter
    dw $FF03  ; SetEventFlag
    dw $006F  ; Text $006F: "If you take monsters on a journey, they "
    dw $FF03  ; SetEventFlag
    dw $0074
    dw $FF05  ; TriggerBattle
    dw $015D  ; Text $015D: "How many times do I have to say it?! I d"
    dw $FFFF  ; END

Bank0E_ScriptAddr_63B4:
    dw $02A3  ; Text $02A3: "Arrrgh! How dare you crack all my eggs! "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3C_Script06
; ---------------------------------------------------------------------------
Map3C_Script06:
    dw $FF01  ; BranchIfFlagSet
    dw $0077
    dw Bank0E_ScriptAddr_63DA          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0075
    dw Bank0E_ScriptAddr_63DA          ; -> branch target
    dw $02A2  ; Text $02A2: "[HERO] looked at the egg. The egg is cra"
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_62A6          ; -> branch target
    dw $FF06  ; IncrementCounter
    dw $FF03  ; SetEventFlag
    dw $006F  ; Text $006F: "If you take monsters on a journey, they "
    dw $FF03  ; SetEventFlag
    dw $0075
    dw $FF05  ; TriggerBattle
    dw $015D  ; Text $015D: "How many times do I have to say it?! I d"
    dw $FFFF  ; END

Bank0E_ScriptAddr_63DA:
    dw $02A3  ; Text $02A3: "Arrrgh! How dare you crack all my eggs! "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3C_Script07
; ---------------------------------------------------------------------------
Map3C_Script07:
    dw $FF01  ; BranchIfFlagSet
    dw $0077
    dw Bank0E_ScriptAddr_6400          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0076
    dw Bank0E_ScriptAddr_6400          ; -> branch target
    dw $02A2  ; Text $02A2: "[HERO] looked at the egg. The egg is cra"
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_62AE          ; -> branch target
    dw $FF06  ; IncrementCounter
    dw $FF03  ; SetEventFlag
    dw $006F  ; Text $006F: "If you take monsters on a journey, they "
    dw $FF03  ; SetEventFlag
    dw $0076
    dw $FF05  ; TriggerBattle
    dw $015D  ; Text $015D: "How many times do I have to say it?! I d"
    dw $FFFF  ; END

Bank0E_ScriptAddr_6400:
    dw $02A3  ; Text $02A3: "Arrrgh! How dare you crack all my eggs! "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3C_Script08
; ---------------------------------------------------------------------------
Map3C_Script08:
    dw $FF01  ; BranchIfFlagSet
    dw $0078
    dw Bank0E_ScriptAddr_665C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0077
    dw Bank0E_ScriptAddr_6564          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $006F  ; Text $006F: "If you take monsters on a journey, they "
    dw Bank0E_ScriptAddr_641A          ; -> branch target
    dw $029E  ; Text $029E: "That my family in this world prospers..."
    dw $FFFF  ; END

Bank0E_ScriptAddr_641A:
    dw $029F  ; Text $029F: "Shoot! Not here either! // Who are you? "
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFF0  ; Cmd$F0
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF1C  ; CompareRAM
    dw $0100  ; Text $0100: "Welcome to the arena. Huh? Me? I'm famou"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF10  ; NPCAnimStart
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0030  ; Text $0030: "Upper floor, the monster farm. Pulio tak"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFE0  ; Cmd$E0
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFF0  ; Cmd$F0
    dw $FF0A  ; NPCMoveX
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0020  ; Text $0020: "KingOh [HERO]! Will you comply with my w"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFF0  ; Cmd$F0
    dw $FF0A  ; NPCMoveX
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFF0  ; Cmd$F0
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0080  ; Text $0080: "PulioThank you [HERO]! Now I can go back"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0080  ; Text $0080: "PulioThank you [HERO]! Now I can go back"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF1C  ; CompareRAM
    dw $0101  ; Text $0101: "Too bad. You need more training. There a"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF1C  ; CompareRAM
    dw $0101  ; Text $0101: "Too bad. You need more training. There a"
    dw $FF19  ; FadeEffect
    dw $FF1C  ; CompareRAM
    dw $0101  ; Text $0101: "Too bad. You need more training. There a"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF1C  ; CompareRAM
    dw $0103  ; Text $0103: "Oh, Sir [HERO]. Congratulations on your "
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF3C  ; Cmd3C
    dw $FF07  ; InitDialogMode
    dw $02A0  ; Text $02A0: "Who are you? You're a monster master are"
    dw $FF1C  ; CompareRAM
    dw $0401  ; Text $0401: "I'm the Monster Minister! Do you want to"
    dw $FF19  ; FadeEffect
    dw $FF12  ; WriteRAM
    dw $C8B2  ; RAM $C8B2
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF21  ; TriggerBattle2
    dw $0064  ; Text $0064: "Once I picked up a TinyMedal, back when "
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $00D2
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_62AE          ; -> branch target
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_6296          ; -> branch target
    dw $FF24  ; Cmd24
    dw $62B6
    dw $FF24  ; Cmd24
    dw $62D0
    dw $FF24  ; Cmd24
    dw $62DE
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $00D2
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF0A  ; NPCMoveX
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFF0  ; Cmd$F0
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF0A  ; NPCMoveX
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFF0  ; Cmd$F0
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF3D  ; Cmd3D
    dw $FF07  ; InitDialogMode
    dw $02A1  ; Text $02A1: "[HERO] looked at the egg. A monster hatc"
    dw $FF0A  ; NPCMoveX
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFF0  ; Cmd$F0
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0020  ; Text $0020: "KingOh [HERO]! Will you comply with my w"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF03  ; SetEventFlag
    dw $0077
    dw $FF12  ; WriteRAM
    dw $D982  ; RAM $D982
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFFF  ; END

Bank0E_ScriptAddr_6564:
    dw $02A4  ; Text $02A4: "It's you again! You'll pay for what you'"
    dw $FF03  ; SetEventFlag
    dw $0078
    dw $FF5A  ; Cmd5A
    dw $0065  ; Text $0065: "Would you like to see the list of Travel"
    dw $FF07  ; InitDialogMode
    dw $02A6  ; Text $02A6: "WatabouThose eggs were the reason there "
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0204  ; Text $0204: "[HERO] looked into the big kettle. ...So"
    dw $FF1C  ; CompareRAM
    dw $1602
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF07  ; InitDialogMode
    dw $02A7  ; Text $02A7: "Soon you will become powerful! During my"
    dw $FF1C  ; CompareRAM
    dw $0402  ; Text $0402: "If you don't want to know, that's fine. "
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $003C  ; Text $003C: "C'mon, I'll give you a beating. Sniff sn"
    dw $FF03  ; SetEventFlag
    dw $001D  ; Text $001D: "[HERO] opened a treasure chest! // This "
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF12  ; WriteRAM
    dw $D933  ; RAM $D933
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF12  ; WriteRAM
    dw $D934  ; RAM $D934
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF12  ; WriteRAM
    dw $D935  ; RAM $D935
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF12  ; WriteRAM
    dw $D936  ; RAM $D936
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF12  ; WriteRAM
    dw $D937  ; RAM $D937
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF12  ; WriteRAM
    dw $D938  ; RAM $D938
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF12  ; WriteRAM
    dw $D93F  ; RAM $D93F
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF12  ; WriteRAM
    dw $D941  ; RAM $D941
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF12  ; WriteRAM
    dw $D942  ; RAM $D942
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF12  ; WriteRAM
    dw $D943  ; RAM $D943
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF12  ; WriteRAM
    dw $D944  ; RAM $D944
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF12  ; WriteRAM
    dw $D966  ; RAM $D966
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF12  ; WriteRAM
    dw $D967  ; RAM $D967
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF12  ; WriteRAM
    dw $D96C  ; RAM $D96C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF12  ; WriteRAM
    dw $D982  ; RAM $D982
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $00E8  ; Text $00E8: "The last battle in G class is with the p"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FFFF  ; END

Bank0E_ScriptAddr_665C:
    dw $02A5  ; Text $02A5: "That sword man looked like you... // Wat"
    dw $FF14  ; ClearGameFlags
    dw $656A
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3D Per-Script Table (map_type=$3D, 4 scripts)
; ---------------------------------------------------------------------------
Map3D_ScriptPtrTable:
    dw Map3D_Script00                  ; script 0
    dw Map3D_Script01                  ; script 1
    dw Map3D_Script02                  ; script 2
    dw Map3D_Script03                  ; script 3
; ---------------------------------------------------------------------------
; Map3D_Script00
; ---------------------------------------------------------------------------
Map3D_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3D_Script02
; ---------------------------------------------------------------------------
Map3D_Script02:
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0018  ; Text $0018: "Hurry! Go see the King! // I see..... //"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0018  ; Text $0018: "Hurry! Go see the King! // I see..... //"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0018  ; Text $0018: "Hurry! Go see the King! // I see..... //"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $0018  ; Text $0018: "Hurry! Go see the King! // I see..... //"
    dw $00A8  ; Text $00A8: "oBut the monsters will get more points i"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0018  ; Text $0018: "Hurry! Go see the King! // I see..... //"
    dw $0048  ; Text $0048: "KingArrgh! You! You let my precious Hale"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFF0  ; Cmd$F0
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF49  ; Cmd49
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0305  ; Text $0305: "You don't seem to be a bad guy after all"
    dw $FF1C  ; CompareRAM
    dw $1504
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_6718          ; -> branch target
; ---------------------------------------------------------------------------
; Map3D_Script01
; ---------------------------------------------------------------------------
Map3D_Script01:
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0018  ; Text $0018: "Hurry! Go see the King! // I see..... //"
    dw $0048  ; Text $0048: "KingArrgh! You! You let my precious Hale"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0018  ; Text $0018: "Hurry! Go see the King! // I see..... //"
    dw $0048  ; Text $0048: "KingArrgh! You! You let my precious Hale"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $0018  ; Text $0018: "Hurry! Go see the King! // I see..... //"
    dw $0048  ; Text $0048: "KingArrgh! You! You let my precious Hale"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $0018  ; Text $0018: "Hurry! Go see the King! // I see..... //"
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0018  ; Text $0018: "Hurry! Go see the King! // I see..... //"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF4A  ; Cmd4A
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0304  ; Text $0304: "You again!? I'm really gonna get you now"
    dw $FF1C  ; CompareRAM
    dw $1604
Bank0E_ScriptAddr_6718:
    dw $FF19  ; FadeEffect
    dw $FF48  ; Cmd48
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF1D  ; LockMovement
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FFD0  ; Cmd$D0
    dw $FF1B  ; MultiRAMWrite
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FFD0  ; Cmd$D0
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF1C  ; CompareRAM
    dw $0405  ; Text $0405: "How about monsters living behind the Gat"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "Welcome to the Chamber of Travelers' Gat"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0010  ; Text $0010: "Hey, is he the new master Watabou brough"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF21  ; TriggerBattle2
    dw $0066  ; Text $0066: "You can enter the locked rooms only when"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF0B  ; NPCMoveY
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FFF8  ; Cmd$F8
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF07  ; InitDialogMode
    dw $0531  ; Text $0531: "Hello...the traveler over there... I'm t"
    dw $0532  ; Text $0532: "Now, wait there. // Then, would you like"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0E_ScriptAddr_679C          ; -> branch target
    dw $0533  ; Text $0533: "Then, would you like me to send you back"
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_67AE          ; -> branch target
Bank0E_ScriptAddr_679C:
    dw $0534  ; Text $0534: "It was actually a monster that fell wasn"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0E_ScriptAddr_67AC          ; -> branch target
    dw $0535  ; Text $0535: "Was it this meat that fell in the spring"
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_67AE          ; -> branch target
Bank0E_ScriptAddr_67AC:
    dw $0535  ; Text $0535: "Was it this meat that fell in the spring"
Bank0E_ScriptAddr_67AE:
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF1C  ; CompareRAM
    dw $0802  ; Text $0802: "WatabouOh well, you don't need me... [HE"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF07  ; InitDialogMode
    dw $0536  ; Text $0536: "...you're a liar. I'll give your monster"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0E_ScriptAddr_67CE          ; -> branch target
    dw $0537  ; Text $0537: "I see. Now, wait a moment for me. // Now"
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_68AE          ; -> branch target
Bank0E_ScriptAddr_67CE:
    dw $0538  ; Text $0538: "Now, is this the old guy who fell in the"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF1C  ; CompareRAM
    dw $0D02
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0080  ; Text $0080: "PulioThank you [HERO]! Now I can go back"
    dw $FF1C  ; CompareRAM
    dw $0803  ; Text $0803: "WatabouHey, you have too many pals! Wata"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF07  ; InitDialogMode
    dw $0539  ; Text $0539: "...you're a liar. I'll give your monster"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0E_ScriptAddr_6802          ; -> branch target
    dw $053A  ; Text $053A: "I see. Now,wait a minute for me. // Now "
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_68AE          ; -> branch target
Bank0E_ScriptAddr_6802:
    dw $053B  ; Text $053B: "Now is this the 0, the monster that fell"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF1C  ; CompareRAM
    dw $0D03
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0080  ; Text $0080: "PulioThank you [HERO]! Now I can go back"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $001A  ; Text $001A: "[HERO] opened a treasure chest! // [HERO"
    dw $0028  ; Text $0028: "I wanna be a master. What should I do? /"
    dw $FF1C  ; CompareRAM
    dw $0801  ; Text $0801: "WatabouYou made it! [HERO]!! You beathem"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF3F  ; Cmd3F
    dw $FF07  ; InitDialogMode
    dw $053C  ; Text $053C: "I don't understand you... I'll give you "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw Bank0E_ScriptAddr_6840          ; -> branch target
    dw $053D  ; Text $053D: "You're honest. I'll give you back the mo"
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_68AE          ; -> branch target
Bank0E_ScriptAddr_6840:
    dw $053E  ; Text $053E: "You did well. Please go back to your hom"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF05  ; TriggerBattle
    dw $007F
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $003D  ; Text $003D: "You came here to get monsters? // I'm Pu"
    dw $FF03  ; SetEventFlag
    dw $001E  ; Text $001E: "This is the Kingdom of GreatTree! // Wel"
    dw $FF07  ; InitDialogMode
    dw $053F  ; Text $053F: "Oh, it's you again. Would you like to go"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF12  ; WriteRAM
    dw $D94C  ; RAM $D94C
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF12  ; WriteRAM
    dw $D983  ; RAM $D983
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF00  ; BranchIfFlagClear
    dw $002E  ; Text $002E: "The tournament is held on the Starry Nig"
    dw Bank0E_ScriptAddr_6890          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $010C  ; Text $010C: "Gwrr, Gwrr... // In the back, they teach"
    dw Bank0E_ScriptAddr_68A4          ; -> branch target
Bank0E_ScriptAddr_6890:
    dw $FF01  ; BranchIfFlagSet
    dw $010C  ; Text $010C: "Gwrr, Gwrr... // In the back, they teach"
    dw Bank0E_ScriptAddr_689A          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_68AE          ; -> branch target
Bank0E_ScriptAddr_689A:
    dw $FF12  ; WriteRAM
    dw $D94C  ; RAM $D94C
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_68AE          ; -> branch target
Bank0E_ScriptAddr_68A4:
    dw $FF12  ; WriteRAM
    dw $D94C  ; RAM $D94C
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_68AE          ; -> branch target
Bank0E_ScriptAddr_68AE:
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0040  ; Text $0040: "SlioYou can drop off up to 19 monsters a"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $00E8  ; Text $00E8: "The last battle in G class is with the p"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3D_Script03
; ---------------------------------------------------------------------------
Map3D_Script03:
    dw $0531  ; Text $0531: "Hello...the traveler over there... I'm t"
    dw $0540  ; Text $0540: "Take your time. // Now so long... // Com"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw Bank0E_ScriptAddr_68EE          ; -> branch target
    dw $0542  ; Text $0542: "Comrade! Now is the time for us to unite"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $00E8  ; Text $00E8: "The last battle in G class is with the p"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FFFF  ; END

Bank0E_ScriptAddr_68EE:
    dw $0541  ; Text $0541: "Now so long... // Comrade! Now is the ti"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3E Per-Script Table (map_type=$3E, 2 scripts)
; ---------------------------------------------------------------------------
Map3E_ScriptPtrTable:
    dw Map3E_Script00                  ; script 0
    dw Map3E_Script01                  ; script 1
; ---------------------------------------------------------------------------
; Map3E_Script00
; ---------------------------------------------------------------------------
Map3E_Script00:
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3E_Script01
; ---------------------------------------------------------------------------
Map3E_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00D2
    dw Bank0E_ScriptAddr_69DE          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00D1  ; Text $00D1: "Warubou? I'm not Warubou. I am Watabou! "
    dw Bank0E_ScriptAddr_6928          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00D0
    dw Bank0E_ScriptAddr_6920          ; -> branch target
    dw $0543  ; Text $0543: "I'll promise you, comrade! A world where"
    dw $FF03  ; SetEventFlag
    dw $00D0
    dw $FFFF  ; END

Bank0E_ScriptAddr_6920:
    dw $0544  ; Text $0544: "Hm!? I don't know why but I feel somethi"
    dw $FF03  ; SetEventFlag
    dw $00D1  ; Text $00D1: "Warubou? I'm not Warubou. I am Watabou! "
    dw $FFFF  ; END

Bank0E_ScriptAddr_6928:
    dw $0545  ; Text $0545: "Sirloin steak is totally yummy! Therefor"
    dw $FF03  ; SetEventFlag
    dw $00D2
    dw $FF5A  ; Cmd5A
    dw $0093
    dw $FF07  ; InitDialogMode
    dw $0547  ; Text $0547: "Hee hee hee. I love burning villages! Wa"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "Huh? What happened? Where is Milayou? //"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "Terry looked in front of him. A flame sp"
    dw $0005  ; Text $0005: "[NUM];Terry looked in the dresser. It's "
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0304  ; Text $0304: "You again!? I'm really gonna get you now"
    dw $FF1C  ; CompareRAM
    dw $1501
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF07  ; InitDialogMode
    dw $0844
    dw $FF1C  ; CompareRAM
    dw $0401  ; Text $0401: "I'm the Monster Minister! Do you want to"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "Terry looked at the bookshelf. Diary of "
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $003E  ; Text $003E: "I'm Pulio I take care of this farm. Puli"
    dw $FF03  ; SetEventFlag
    dw $001F  ; Text $001F: "Welcome! I am the King of this kingdom. "
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "Are you Milayou? Hm, You don't look like"
    dw $FF12  ; WriteRAM
    dw $D96E  ; RAM $D96E
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF12  ; WriteRAM
    dw $D984  ; RAM $D984
    dw $0001  ; Text $0001: "Terry looked at a stuffed animal. Someth"
    dw $FF00  ; BranchIfFlagClear
    dw $0020  ; Text $0020: "KingOh [HERO]! Will you comply with my w"
    dw $69D2
    dw $FF12  ; WriteRAM
    dw $D96E  ; RAM $D96E
    dw $0003  ; Text $0003: "Terry looked at the bookshelf. A Fairy T"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $00E8  ; Text $00E8: "The last battle in G class is with the p"
    dw $0058  ; Text $0058: "You are strong! I like you, [HERO]. // K"
    dw $FFFF  ; END

Bank0E_ScriptAddr_69DE:
    dw $0546  ; Text $0546: "I demand one sirloin steak a day! // Hee"
    dw $FF14  ; ClearGameFlags
    dw $692E
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3F Per-Script Table (map_type=$3F, 0 scripts)
; ---------------------------------------------------------------------------
Map3F_ScriptPtrTable:
    dw $69EA
    dw $69FA
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0006  ; Text $0006: "[NUM];Terry looked in the dresser. It's "
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "Milayou... zzz. // Terry looked at a stu"
    dw $FFFF  ; END

    db $01
    db $FF
    db $D3
    db $00
    db $DA
    db $6A
    db $48
    db $05
    db $15
    db $FF
    db $3C
    db $C8
    db $01
    db $00
    db $0E
    db $6A
    db $49
    db $05
    db $FF
    db $FF
    db $4A
    db $05
    db $03
    db $FF
    db $D3
    db $00
    db $13
    db $FF
    db $03
    db $DA
    db $97
    db $00
    db $13
    db $FF
    db $05
    db $DA
    db $95
    db $00
    db $13
    db $FF
    db $07
    db $DA
    db $98
    db $00
    db $12
    db $FF
    db $02
    db $DA
    db $02
    db $00
    db $5B
    db $FF
    db $07
    db $FF
    db $4C
    db $05
    db $09
    db $FF
    db $08
    db $00
    db $0D
    db $FF
    db $01
    db $00
    db $05
    db $00
    db $00
    db $00
    db $0D
    db $FF
    db $02
    db $00
    db $00
    db $00
    db $00
    db $00
    db $13
    db $FF
    db $E3
    db $D8
    db $09
    db $04
    db $1C
    db $FF
    db $02
    db $15
    db $19
    db $FF
    db $4D
    db $FF
    db $04
    db $00
    db $49
    db $FF
    db $02
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $47
    db $FF
    db $02
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $4A
    db $FF
    db $02
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $48
    db $FF
    db $02
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $47
    db $FF
    db $00
    db $00
    db $07
    db $FF
    db $4D
    db $05
    db $1C
    db $FF
    db $02
    db $04
    db $19
    db $FF
    db $4D
    db $FF
    db $04
    db $00
    db $49
    db $FF
    db $02
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $47
    db $FF
    db $02
    db $00
    db $4D
    db $FF
    db $04
    db $00
    db $4A
    db $FF
    db $02
    db $00
    db $4D
    db $FF
    db $06
    db $00
    db $48
    db $FF
    db $02
    db $00
    db $08
    db $FF
    db $12
    db $FF
    db $E3
    db $D9
    db $3F
    db $00
    db $03
    db $FF
    db $20
    db $00
    db $12
    db $FF
    db $2B
    db $D9
    db $07
    db $00
    db $12
    db $FF
    db $6E
    db $D9
    db $02
    db $00
    db $12
    db $FF
    db $85
    db $D9
    db $01
    db $00
    db $00
    db $FF
    db $1F
    db $00
    db $CE
    db $6A
    db $12
    db $FF
    db $6E
    db $D9
    db $03
    db $00
    db $06
    db $FF
    db $3B
    db $FF
    db $00
    db $00
    db $E8
    db $00
    db $58
    db $00
    db $FF
    db $FF
    db $4B
    db $05
    db $14
    db $FF
    db $14
    db $6A
    db $FF
    db $FF
    db $E4
    db $6A
    db $FF
    db $FF
    db $7C
    db $25
    db $24
    db $7C
    db $7C
    db $29
    db $6A
    db $79
    db $6A
    db $03
    db $79
    db $81
    db $6A
    db $05
    db $79
    db $81
    db $6A
    db $04
    db $79
    db $87
    db $6A
    db $79
    db $79
    db $6A
    db $79
    db $0D
    db $0F
    db $04
    db $6A
    db $81
    db $2A
    db $03
    db $71
    db $81
    db $0D
    db $14
    db $0E
    db $81
    db $14
    db $03
    db $7C
    db $83
    db $5D
    db $5E
    db $5D
    db $03
    db $7C
    db $81
    db $1B
    db $03
    db $10
    db $84
    db $1B
    db $7C
    db $7C
    db $1C
    db $03
    db $7C
    db $03
    db $71
    db $03
    db $7C
    db $84
    db $1C
    db $7C
    db $7C
    db $24
    db $03
    db $71
    db $87
    db $7C
    db $25
    db $1C
    db $1C
    db $7C
    db $7C
    db $0D
    db $07
    db $0E
    db $81
    db $26
    db $03
    db $06
    db $8E
    db $27
    db $0E
    db $0F
    db $36
    db $2D
    db $37
    db $78
    db $34
    db $2E
    db $2F
    db $33
    db $36
    db $2D
    db $37
    db $03
    db $70
    db $8E
    db $36
    db $37
    db $70
    db $36
    db $37
    db $33
    db $78
    db $70
    db $15
    db $16
    db $17
    db $36
    db $2D
    db $37
    db $04
    db $78
    db $85
    db $36
    db $37
    db $34
    db $78
    db $0D
    db $04
    db $0E
    db $84
    db $0F
    db $79
    db $79
    db $2A
    db $03
    db $7C
    db $86
    db $25
    db $7C
    db $7C
    db $29
    db $79
    db $6A
    db $04
    db $79
    db $86
    db $05
    db $06
    db $06
    db $07
    db $79
    db $6A
    db $04
    db $79
    db $88
    db $6A
    db $79
    db $79
    db $6A
    db $79
    db $05
    db $27
    db $0F
    db $04
    db $6A
    db $81
    db $2A
    db $03
    db $71
    db $81
    db $0D
    db $14
    db $0E
    db $86
    db $14
    db $7C
    db $FC
    db $7C
    db $7C
    db $55
    db $03
    db $7C
    db $81
    db $1B
    db $03
    db $10
    db $88
    db $1B
    db $7C
    db $7C
    db $24
    db $7C
    db $25
    db $1C
    db $7C
    db $04
    db $71
    db $86
    db $7C
    db $24
    db $7C
    db $25
    db $24
    db $7C
    db $03
    db $71
    db $87
    db $7C
    db $24
    db $7C
    db $7C
    db $25
    db $24
    db $0D
    db $0D
    db $0E
    db $9C
    db $0F
    db $3D
    db $3F
    db $70
    db $70
    db $34
    db $36
    db $37
    db $33
    db $3D
    db $3F
    db $70
    db $78
    db $70
    db $78
    db $35
    db $78
    db $70
    db $35
    db $78
    db $33
    db $70
    db $78
    db $33
    db $70
    db $34
    db $3D
    db $3F
    db $04
    db $70
    db $86
    db $78
    db $35
    db $78
    db $34
    db $78
    db $0D
    db $04
    db $0E
    db $8E
    db $0F
    db $79
    db $1D
    db $2A
    db $5D
    db $5E
    db $5D
    db $7C
    db $25
    db $7C
    db $29
    db $05
    db $06
    db $07
    db $03
    db $79
    db $84
    db $0D
    db $0E
    db $0E
    db $26
    db $04
    db $06
    db $81
    db $07
    db $06
    db $79
    db $83
    db $0D
    db $0E
    db $0F
    db $04
    db $6A
    db $81
    db $2A
    db $03
    db $71
    db $81
    db $0D
    db $14
    db $0E
    db $82
    db $0B
    db $0C
    db $0A
    db $10
    db $89
    db $1B
    db $7C
    db $7C
    db $24
    db $7C
    db $7C
    db $24
    db $7C
    db $25
    db $08
    db $7C
    db $81
    db $25
    db $04
    db $7C
    db $81
    db $24
    db $03
    db $7C
    db $83
    db $24
    db $7C
    db $0D
    db $0D
    db $0E
    db $89
    db $0F
    db $78
    db $70
    db $70
    db $78
    db $34
    db $35
    db $78
    db $33
    db $03
    db $78
    db $06
    db $70
    db $8A
    db $78
    db $78
    db $33
    db $78
    db $78
    db $05
    db $06
    db $07
    db $78
    db $78
    db $03
    db $70
    db $87
    db $78
    db $70
    db $78
    db $78
    db $34
    db $70
    db $0D
    db $04
    db $0E
    db $8E
    db $0F
    db $79
    db $F6
    db $2A
    db $7C
    db $55
    db $7C
    db $05
    db $07
    db $30
    db $4C
    db $15
    db $16
    db $17
    db $03
    db $4C
    db $81
    db $15
    db $07
    db $16
    db $81
    db $17
    db $06
    db $4C
    db $83
    db $15
    db $16
    db $17
    db $05
    db $4C
    db $03
    db $30
    db $81
    db $0D
    db $14
    db $0E
    db $83
    db $39
    db $0B
    db $0C
    db $0A
    db $39
    db $1B
    db $30
    db $81
    db $0D
    db $0D
    db $0E
    db $89
    db $26
    db $56
    db $70
    db $70
    db $78
    db $34
    db $78
    db $78
    db $33
    db $04
    db $78
    db $90
    db $70
    db $78
    db $70
    db $78
    db $70
    db $78
    db $78
    db $33
    db $78
    db $70
    db $0D
    db $0E
    db $0F
    db $70
    db $70
    db $78
    db $04
    db $70
    db $85
    db $78
    db $78
    db $34
    db $70
    db $0D
    db $04
    db $0E
    db $81
    db $26
    db $06
    db $06
    db $84
    db $27
    db $0F
    db $78
    db $78
    db $20
    db $1A
    db $81
    db $0D
    db $14
    db $0E
    db $84
    db $44
    db $44
    db $0B
    db $0C
    db $09
    db $44
    db $90
    db $78
    db $78
    db $2E
    db $2D
    db $2F
    db $78
    db $3D
    db $3E
    db $3F
    db $35
    db $78
    db $78
    db $3D
    db $3F
    db $2E
    db $2F
    db $03
    db $78
    db $89
    db $2E
    db $2F
    db $35
    db $78
    db $3D
    db $3F
    db $78
    db $78
    db $0D
    db $0E
    db $0E
    db $81
    db $0F
    db $03
    db $78
    db $84
    db $34
    db $78
    db $78
    db $33
    db $0B
    db $78
    db $86
    db $33
    db $78
    db $78
    db $0D
    db $0E
    db $0F
    db $09
    db $78
    db $83
    db $34
    db $78
    db $0D
    db $0C
    db $0E
    db $83
    db $0F
    db $78
    db $78
    db $20
    db $1A
    db $81
    db $0D
    db $0D
    db $0E
    db $83
    db $1E
    db $16
    db $1F
    db $03
    db $0E
    db $8F
    db $1E
    db $16
    db $16
    db $1F
    db $0E
    db $0E
    db $1E
    db $1F
    db $0E
    db $0E
    db $1E
    db $1F
    db $1E
    db $16
    db $1F
    db $41
    db $0E
    db $83
    db $1E
    db $16
    db $1F
    db $05
    db $0E
    db $84
    db $1E
    db $16
    db $16
    db $1F
    db $35
    db $0E
    db $84
    db $1E
    db $16
    db $16
    db $1F
    db $04
    db $0E
    db $84
    db $1E
    db $4A
    db $7B
    db $4B
    db $03
    db $16
    db $90
    db $4A
    db $7B
    db $7B
    db $4B
    db $16
    db $16
    db $4A
    db $4B
    db $1F
    db $1E
    db $4A
    db $4B
    db $4A
    db $7B
    db $4B
    db $1F
    db $31
    db $0E
    db $81
    db $1E
    db $03
    db $16
    db $81
    db $1F
    db $07
    db $0E
    db $93
    db $1E
    db $16
    db $16
    db $4A
    db $7B
    db $4B
    db $16
    db $1F
    db $0E
    db $0E
    db $1E
    db $4A
    db $7B
    db $7B
    db $4B
    db $16
    db $1F
    db $1E
    db $1F
    db $31
    db $0E
    db $84
    db $0F
    db $6B
    db $6B
    db $0D
    db $04
    db $0E
    db $81
    db $0F
    db $04
    db $6B
    db $0A
    db $7B
    db $83
    db $4B
    db $4A
    db $7B
    db $04
    db $6B
    db $81
    db $0D
    db $31
    db $0E
    db $81
    db $0F
    db $03
    db $6B
    db $81
    db $0D
    db $06
    db $0E
    db $82
    db $1E
    db $4A
    db $06
    db $7B
    db $84
    db $4B
    db $1F
    db $1E
    db $4A
    db $05
    db $7B
    db $84
    db $4B
    db $4A
    db $4B
    db $1F
    db $30
    db $0E
    db $83
    db $0F
    db $6B
    db $6B
    db $05
    db $62
    db $81
    db $5B
    db $04
    db $6B
    db $0D
    db $7B
    db $04
    db $6B
    db $81
    db $0D
    db $31
    db $0E
    db $81
    db $0F
    db $03
    db $6B
    db $81
    db $0D
    db $06
    db $0E
    db $81
    db $0F
    db $08
    db $7B
    db $82
    db $0D
    db $0F
    db $09
    db $7B
    db $81
    db $0D
    db $30
    db $0E
    db $83
    db $0F
    db $6B
    db $6B
    db $05
    db $62
    db $81
    db $5B
    db $04
    db $7B
    db $81
    db $23
    db $05
    db $7B
    db $82
    db $05
    db $07
    db $04
    db $7B
    db $81
    db $23
    db $04
    db $7B
    db $81
    db $0D
    db $31
    db $0E
    db $81
    db $0F
    db $03
    db $6B
    db $07
    db $62
    db $81
    db $5B
    db $08
    db $7B
    db $82
    db $15
    db $17
    db $09
    db $7B
    db $81
    db $0D
    db $30
    db $0E
    db $84
    db $0F
    db $6B
    db $6B
    db $0D
    db $04
    db $0E
    db $81
    db $0F
    db $04
    db $7B
    db $83
    db $23
    db $7B
    db $32
    db $03
    db $7B
    db $87
    db $0D
    db $0F
    db $7B
    db $7B
    db $32
    db $7B
    db $23
    db $04
    db $7B
    db $81
    db $0D
    db $2A
    db $0E
    db $06
    db $79
    db $82
    db $0F
    db $0F
    db $03
    db $6B
    db $07
    db $62
    db $81
    db $5B
    db $03
    db $7B
    db $81
    db $32
    db $08
    db $7B
    db $81
    db $32
    db $06
    db $7B
    db $81
    db $0D
    db $30
    db $0E
    db $84
    db $0F
    db $6B
    db $6B
    db $0D
    db $04
    db $0E
    db $81
    db $0F
    db $04
    db $7B
    db $8D
    db $23
    db $7B
    db $F6
    db $7B
    db $7B
    db $20
    db $0D
    db $0F
    db $22
    db $7B
    db $F6
    db $7B
    db $23
    db $04
    db $7B
    db $81
    db $0D
    db $04
    db $0E
    db $87
    db $0F
    db $7C
    db $42
    db $7A
    db $7A
    db $41
    db $42
    db $04
    db $7A
    db $90
    db $48
    db $48
    db $7A
    db $7A
    db $48
    db $7A
    db $7A
    db $0D
    db $0E
    db $0F
    db $6A
    db $02
    db $03
    db $0D
    db $0E
    db $0F
    db $0B
    db $7A
    db $81
    db $29
    db $05
    db $79
    db $82
    db $0D
    db $0F
    db $03
    db $6B
    db $07
    db $62
    db $81
    db $5B
    db $03
    db $7B
    db $81
    db $F6
    db $08
    db $7B
    db $84
    db $F6
    db $7B
    db $20
    db $22
    db $03
    db $7B
    db $81
    db $0D
    db $30
    db $0E
    db $84
    db $26
    db $5A
    db $06
    db $27
    db $04
    db $0E
    db $81
    db $26
    db $03
    db $5A
    db $07
    db $06
    db $82
    db $27
    db $26
    db $06
    db $06
    db $03
    db $5A
    db $81
    db $27
    db $04
    db $0E
    db $A1
    db $0F
    db $1C
    db $7C
    db $42
    db $41
    db $7C
    db $7C
    db $42
    db $48
    db $48
    db $41
    db $7C
    db $7C
    db $42
    db $41
    db $7C
    db $42
    db $7A
    db $0D
    db $0E
    db $0F
    db $6A
    db $7E
    db $7F
    db $0D
    db $0E
    db $0F
    db $7A
    db $00
    db $01
    db $7A
    db $48
    db $48
    db $05
    db $7A
    db $81
    db $29
    db $05
    db $79
    db $82
    db $0D
    db $26
    db $03
    db $06
    db $81
    db $27
    db $06
    db $0E
    db $88
    db $0F
    db $7B
    db $7B
    db $20
    db $21
    db $21
    db $22
    db $05
    db $0C
    db $06
    db $81
    db $27
    db $31
    db $0E
    db $82
    db $62
    db $62
    db $06
    db $0E
    db $05
    db $62
    db $0B
    db $0E
    db $05
    db $62
    db $05
    db $0E
    db $84
    db $0F
    db $7C
    db $25
    db $24
    db $03
    db $7C
    db $83
    db $24
    db $7C
    db $25
    db $03
    db $7C
    db $81
    db $24
    db $03
    db $7C
    db $9C
    db $42
    db $0D
    db $0E
    db $0F
    db $02
    db $03
    db $6A
    db $0D
    db $0E
    db $0F
    db $42
    db $08
    db $09
    db $41
    db $7C
    db $7C
    db $42
    db $7A
    db $7A
    db $48
    db $41
    db $29
    db $79
    db $79
    db $1D
    db $79
    db $79
    db $0D
    db $0B
    db $0E
    db $81
    db $0F
    db $06
    db $7B
    db $81
    db $4B
    db $04
    db $16
    db $84
    db $1F
    db $0E
    db $0E
    db $1E
    db $04
    db $16
    db $81
    db $1F
    db $30
    db $0E
    db $84
    db $0F
    db $21
    db $6B
    db $0D
    db $04
    db $0E
    db $82
    db $0F
    db $22
    db $04
    db $7B
    db $82
    db $16
    db $1F
    db $07
    db $0E
    db $82
    db $1E
    db $16
    db $04
    db $7B
    db $82
    db $20
    db $0D
    db $04
    db $0E
    db $87
    db $0F
    db $7C
    db $24
    db $7C
    db $7C
    db $1C
    db $24
    db $03
    db $7C
    db $83
    db $25
    db $7C
    db $24
    db $04
    db $71
    db $8D
    db $7C
    db $15
    db $16
    db $17
    db $7E
    db $7F
    db $6A
    db $15
    db $16
    db $17
    db $7C
    db $42
    db $41
    db $04
    db $7C
    db $8B
    db $42
    db $41
    db $7C
    db $25
    db $29
    db $79
    db $79
    db $F6
    db $79
    db $79
    db $0D
    db $0B
    db $0E
    db $83
    db $26
    db $06
    db $07
    db $09
    db $7B
    db $84
    db $4B
    db $16
    db $16
    db $4A
    db $04
    db $6B
    db $81
    db $0D
    db $30
    db $0E
    db $84
    db $0F
    db $6B
    db $6B
    db $0D
    db $04
    db $0E
    db $82
    db $0F
    db $2A
    db $04
    db $7B
    db $82
    db $6B
    db $15
    db $07
    db $16
    db $81
    db $17
    db $03
    db $6B
    db $89
    db $7B
    db $7B
    db $29
    db $0D
    db $0E
    db $1E
    db $16
    db $16
    db $17
    db $03
    db $7C
    db $83
    db $24
    db $7C
    db $25
    db $04
    db $7C
    db $82
    db $25
    db $7C
    db $04
    db $71
    db $84
    db $7C
    db $29
    db $79
    db $2A
    db $03
    db $79
    db $84
    db $29
    db $79
    db $2A
    db $7C
    db $07
    db $71
    db $84
    db $25
    db $7C
    db $7C
    db $05
    db $05
    db $06
    db $81
    db $27
    db $0D
    db $0E
    db $83
    db $26
    db $06
    db $07
    db $05
    db $7B
    db $03
    db $23
    db $03
    db $7B
    db $04
    db $6B
    db $81
    db $0D
    db $30
    db $0E
    db $84
    db $0F
    db $21
    db $6B
    db $0D
    db $04
    db $0E
    db $83
    db $26
    db $06
    db $07
    db $03
    db $7B
    db $82
    db $6B
    db $59
    db $07
    db $6B
    db $81
    db $59
    db $03
    db $6B
    db $8C
    db $7B
    db $05
    db $06
    db $27
    db $0E
    db $0F
    db $79
    db $79
    db $2A
    db $7C
    db $7C
    db $24
    db $04
    db $7C
    db $82
    db $05
    db $07
    db $03
    db $7C
    db $04
    db $71
    db $84
    db $7C
    db $29
    db $79
    db $2A
    db $03
    db $79
    db $84
    db $29
    db $79
    db $2A
    db $7C
    db $07
    db $71
    db $84
    db $7C
    db $25
    db $24
    db $0D
    db $15
    db $0E
    db $81
    db $0F
    db $05
    db $7B
    db $03
    db $23
    db $03
    db $7B
    db $04
    db $6B
    db $81
    db $0D
    db $30
    db $0E
    db $84
    db $0F
    db $6B
    db $6B
    db $0D
    db $06
    db $0E
    db $86
    db $0F
    db $7B
    db $7B
    db $6B
    db $6B
    db $59
    db $07
    db $6B
    db $81
    db $59
    db $03
    db $6B
    db $82
    db $7B
    db $0D
    db $03
    db $0E
    db $90
    db $0F
    db $79
    db $1D
    db $2A
    db $7C
    db $5D
    db $5E
    db $5D
    db $7C
    db $7C
    db $05
    db $27
    db $26
    db $07
    db $7C
    db $7C
    db $04
    db $71
    db $84
    db $7C
    db $29
    db $79
    db $2A
    db $03
    db $79
    db $84
    db $29
    db $79
    db $2A
    db $7C
    db $07
    db $71
    db $84
    db $7C
    db $24
    db $7C
    db $0D
    db $15
    db $0E
    db $84
    db $26
    db $06
    db $06
    db $07
    db $06
    db $23
    db $06
    db $7B
    db $81
    db $0D
    db $30
    db $0E
    db $84
    db $0F
    db $21
    db $6B
    db $0D
    db $06
    db $0E
    db $86
    db $26
    db $07
    db $7B
    db $6B
    db $6B
    db $59
    db $07
    db $6B
    db $81
    db $59
    db $03
    db $6B
    db $82
    db $05
    db $27
    db $03
    db $0E
    db $8F
    db $0F
    db $79
    db $F6
    db $2A
    db $7C
    db $7C
    db $55
    db $7C
    db $7C
    db $05
    db $27
    db $0E
    db $0E
    db $26
    db $07
    db $06
    db $30
    db $09
    db $4C
    db $0B
    db $30
    db $81
    db $0D
    db $18
    db $0E
    db $81
    db $0F
    db $06
    db $23
    db $06
    db $7B
    db $81
    db $0D
    db $30
    db $0E
    db $84
    db $0F
    db $6B
    db $6B
    db $0D
    db $07
    db $0E
    db $81
    db $26
    db $0F
    db $06
    db $81
    db $27
    db $04
    db $0E
    db $81
    db $26
    db $08
    db $06
    db $81
    db $27
    db $04
    db $0E
    db $82
    db $26
    db $07
    db $03
    db $78
    db $16
    db $1A
    db $81
    db $0D
    db $18
    db $0E
    db $81
    db $26
    db $0C
    db $06
    db $81
    db $27
    db $30
    db $0E
    db $84
    db $26
    db $06
    db $06
    db $27
    db $2B
    db $0E
    db $84
    db $26
    db $07
    db $78
    db $78
    db $16
    db $1A
    db $81
    db $0D
    db $7F
    db $0E
    db $7F
    db $0E
    db $7F
    db $0E
    db $7F
    db $0E
    db $7F
    db $0E
    db $7F
    db $0E
    db $7F
    db $0E
    db $7F
    db $0E
    db $7F
    db $0E
    db $7F
    db $0E
    db $7F
    db $0E
    db $7F
    db $0E
    db $7F
    db $0E
    db $7F
    db $0E
    db $7F
    db $0E
    db $7F
    db $0E
    db $7F
    db $0E
    db $7F
    db $0E
    db $7F
    db $0E
    db $7F
    db $0E
    db $6A
    db $0E
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
    db $00
