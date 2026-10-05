; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $00e", ROMX[$4000], BANK[$e]

    db $0e ;ROM BANK

    dw LoadBe_4007
    dw ScriptBank0EDrawTiles
    dw ScriptBank0EDrawAttrs

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
    ld de, Bank0E_ScriptMasterTable
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

; S118: script op $24 draw_tiles (bank $04 ScriptCmd24_DrawTiles far-calls
; entry 1 of the map's script bank). It READS ONE MORE SCRIPT WORD itself
; (counter + 1, then the entry-0 lookup): an address in THIS bank of a tile
; patch — [dest offset word, tile bytes …, $D8 = next row, $D9 = end] — drawn
; onto the visible BG map ($FFB7/$FFBB scroll, $D8E7/$D8E8 cursor) and staged
; at $C300+. So op $24 takes 1 parameter (the S96 tracer stops at rst $10).
; Custom rooms (bank $60): $24 goes to bank $0F entry 1, whose lookup reads bank
; $0F's own tables, not bank $60 — MEASURED S119 (PyBoy, a copy of the Castle:
; its chest patch is not drawn). Patched builds: bank $04 calls bank $60
; entries 9 / 10 (CustomDrawTiles / CustomDrawAttrs) instead, which draw a
; custom room's patch from bank $60 and pass everything else on to here.
ScriptBank0EDrawTiles:
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

; S118: script op $61 draw_attrs (ScriptCmd61_DrawAttrs, entry 2): like entry 1
; it reads ONE more script word (a patch address in this bank) and writes the
; patch to VRAM bank 1 (the BG attributes) on GBC.
ScriptBank0EDrawAttrs:
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
    dw $0009  ; Text $0009: "$42:$4590 *:Huh? What happened? // Where is Milayo"
    dw Bank0E_ScriptAddr_4256          ; -> branch target
    dw $0057  ; Text $0057: "$42:$6F60 *:We are at the Chamber of // Travelers'"
    dw $FFFF  ; END

Bank0E_ScriptAddr_4256:
    dw $011F  ; Text $011F: "$43:$5D7D *:You are at the Room of Beginning. // *"
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
    dw $01A1  ; Text $01A1: "$44:$477B *:Here's the Room of Villager // & Talis"
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
    dw $01E1  ; Text $01E1: "$44:$7206 *:This is the room of Memories & // Bewi"
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
    dw $026E  ; Text $026E: "$45:$5163 *:This is the Room of Peace & // Bravery"
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
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0E_ScriptAddr_4294          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0E_ScriptAddr_4290          ; -> branch target
    dw $029C  ; Text $029C: "$45:$6803 *:[HERO], here is the Room of // Strengt"
    dw $FFFF  ; END

Bank0E_ScriptAddr_4290:
    dw $032E  ; Text $032E: "$46:$530C *:[HERO]! Thanks for saving me. // *:You"
    dw $FFFF  ; END

Bank0E_ScriptAddr_4294:
    dw $082A  ; Text $082A: "$3F:$5BFE *:Oh my, it is Master [HERO]. // Welcome"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map27_Script02
; ---------------------------------------------------------------------------
Map27_Script02:
    dw $FF01  ; BranchIfFlagSet
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0E_ScriptAddr_42AC          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw Bank0E_ScriptAddr_42A8          ; -> branch target
    dw $029D  ; Text $029D: "$45:$686F *:Monsters are flooding out from // the "
    dw $FFFF  ; END

Bank0E_ScriptAddr_42A8:
    dw $032F  ; Text $032F: "$46:$53A3 *:Thank you very much [HERO]!"
    dw $FFFF  ; END

Bank0E_ScriptAddr_42AC:
    dw $082B  ; Text $082B: "$3F:$5C95 *:Oh, [HERO], Master [HERO] is // here!"
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
    dw $035D  ; Text $035D: "$46:$6597 *:You're at the Room of // Joy and Wisdo"
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
    dw $03DD  ; Text $03DD: "$47:$4A04 *:You're in the Room of // Happiness & T"
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
    dw $0408  ; Text $0408: "$21:$44CC *:You're at the Room of the // Labyrinth"
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
    dw $00F1  ; Text $00F1: "$43:$48ED *:Let's play rock- paper-scissors! [YES/"
    dw Bank0E_ScriptAddr_42F6          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $0025  ; Text $0025: "$42:$5285 :It's a little kingdom built // inside a"
    dw Bank0E_ScriptAddr_42F2          ; -> branch target
    dw $046A
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0E_ScriptAddr_42EE          ; -> branch target
    dw $046B
    dw $FFFF  ; END

Bank0E_ScriptAddr_42EE:
    dw $046C  ; Text $046C: "$21:$76D3 *:I...I agree with you. I'm sorry to // "
    dw $FFFF  ; END

Bank0E_ScriptAddr_42F2:
    dw $04DE  ; Text $04DE: "$48:$7411 *:[HERO]! You are the first person // *:"
    dw $FFFF  ; END

Bank0E_ScriptAddr_42F6:
    dw $082C  ; Text $082C: "$3F:$5CB8 *:Welcome to the Room of // Reflection. "
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
    dw $082D  ; Text $082D: "$3F:$5D0E *:Welcome! // *:Go right to the Gate of "
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
    dw $082E  ; Text $082E: "$3F:$5D6A *:Welcome! Master! // *:Go up for the Ga"
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
    dw $082F  ; Text $082F: "$3F:$5DD4 *:How are you? // *:Go right to the Gate"
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
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw Bank0E_ScriptAddr_4344          ; -> branch target
    dw $FF0E  ; SetMapTransition
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw Bank0E_ScriptAddr_48E4          ; -> branch target
    dw $FFFF  ; END

Bank0E_ScriptAddr_4344:
    dw $FF01  ; BranchIfFlagSet
    dw $00EF  ; Text $00EF: "$43:$486E *:In the back, they teach kids // about "
    dw $4342
    dw $FF01  ; BranchIfFlagSet
    dw $00EE  ; Text $00EE: "$43:$485A *:Gwrr, Gwrr..."
    dw $47CE
    dw $FF01  ; BranchIfFlagSet
    dw $00ED  ; Text $00ED: "$43:$47A4 *:H...Hello! I'm T..T..Teto. // *:I'm ne"
    dw $4620
    dw $FF01  ; BranchIfFlagSet
    dw $00EC  ; Text $00EC: "$43:$4772 *:Only those registered are // allowed h"
    dw $4342
    dw $FF01  ; BranchIfFlagSet
    dw $00EB  ; Text $00EB: "$43:$475D You hear a voice."
    dw $4342
    dw $FF01  ; BranchIfFlagSet
    dw $00EA  ; Text $00EA: "$43:$473F *:Get out of my way! Huff!"
    dw $45C0
    dw $FF01  ; BranchIfFlagSet
    dw $00E9  ; Text $00E9: "$43:$470E *:Eeek! What? Talk to me // from the fro"
    dw $4342
    dw $FF01  ; BranchIfFlagSet
    dw $00E4  ; Text $00E4: "$43:$43F5 *:Well done! You survived // G class!"
    dw $455C
    dw $FF01  ; BranchIfFlagSet
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $4342
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF08  ; NOP
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFE0  ; Cmd$E0
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFE0  ; Cmd$E0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFE0  ; Cmd$E0
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFE0  ; Cmd$E0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFE0  ; Cmd$E0
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFE0  ; Cmd$E0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFE0  ; Cmd$E0
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFE0  ; Cmd$E0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFE0  ; Cmd$E0
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFE0  ; Cmd$E0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFE0  ; Cmd$E0
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFE0  ; Cmd$E0
    dw $FF19  ; FadeEffect
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF06  ; IncrementCounter
    dw $FF0A  ; NPCMoveX
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF0A  ; NPCMoveX
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF0  ; Cmd$F0
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF08  ; NOP
    dw $FF4C  ; RestoreBGM
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
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
    dw $00F0  ; Text $00F0: "$43:$48CD *:Where did the MiniDrak go?"
    dw $4342
    dw $FF01  ; BranchIfFlagSet
    dw $00EF  ; Text $00EF: "$43:$486E *:In the back, they teach kids // about "
    dw $4B60
    dw $FF01  ; BranchIfFlagSet
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $4342
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF21  ; TriggerBattle2
    dw $0060  ; Text $0060: "$42:$7430 *:This is the castle of // GreatTree. //"
    dw $FF17  ; SetupBossBattle
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "$42:$6E72 *:Hale was the cherished pet of // the K"
    dw $FF1C  ; CompareRAM
    dw $1202
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0A  ; NPCMoveX
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF90  ; Cmd$90
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF06  ; IncrementCounter
    dw $FF1D  ; LockMovement
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF21  ; TriggerBattle2
    dw $0054  ; Text $0054: "$42:$6DC6 *:You will find items scattered // aroun"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
    dw $FF0B  ; NPCMoveY
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF0A  ; NPCMoveX
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FFE0  ; Cmd$E0
    dw $FF09  ; SetDelay
    dw $0016  ; Text $0016: "$42:$4B9C *:His Majesty is in trouble. // Please p"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $0098
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF1D  ; LockMovement
    dw $FF1A  ; Cmd1A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF1A  ; Cmd1A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF1A  ; Cmd1A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF1A  ; Cmd1A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF1D  ; LockMovement
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FFF0  ; Cmd$F0
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF48  ; Cmd48
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF1D  ; LockMovement
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF1A  ; Cmd1A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF49  ; Cmd49
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF1D  ; LockMovement
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF1A  ; Cmd1A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF1A  ; Cmd1A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF1A  ; Cmd1A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF1A  ; Cmd1A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF1E  ; UnlockMovement
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF1C  ; CompareRAM
    dw $0100  ; Text $0100: "$43:$4DEC [HERO] looked into the jar. // An old la"
    dw $FF19  ; FadeEffect
    dw $FF1D  ; LockMovement
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF48  ; Cmd48
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "$42:$6E72 *:Hale was the cherished pet of // the K"
    dw $FF1C  ; CompareRAM
    dw $1302
    dw $FF1A  ; Cmd1A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "$42:$6E72 *:Hale was the cherished pet of // the K"
    dw $FF1C  ; CompareRAM
    dw $1303
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
; Bedroom script 0 from pos 951 ($0E:$4AA4, 94 words to the END) (S121 trace):
; the dresser glows (sound $60, op $17 the tile swap, delay 8) after Warubou and
; Milayou rose into it (pos 929-947); then Terry / Watabou's part and the hand-
; back to the player. The comments mgbdis put on these words read them as text
; ids — they are opcodes ($FFxx) and their parameters (BANK04_SCRIPT_ENGINE).
; S121 (ROADMAP P3.16, the Milly hook): the bedroom script 0 from pos 951 ($0E:$4AA4)
; to its end (pos 1044, $4B5E) — compiler region (editor2/core/milly.py): the vanilla
; words, or the hook's dresser whirl to the project's arrival (custom.milly_hook).
; @BUILD_PROJECT BEGIN milly_bedroom_script
; vanilla (Milly hook off): the dresser glow, Terry runs up, Watabou, end
    dw $FF21
    dw $0060
    dw $FF17
    dw $FF09
    dw $0008
    dw $FF22
    dw $FF1B
    dw $0000
    dw $FFE0
    dw $FF19
    dw $FF22
    dw $FF1A
    dw $0000
    dw $0030
    dw $FF19
    dw $FF09
    dw $000C
    dw $FF21
    dw $0060
    dw $FF17
    dw $FF09
    dw $0008
    dw $FF0D
    dw $0001
    dw $0000
    dw $0000
    dw $FF21
    dw $0055
    dw $FF1C
    dw $1201
    dw $FF19
    dw $FF07
    dw $0009
    dw $FF06
    dw $FF09
    dw $0003
    dw $FF49
    dw $0001
    dw $FF09
    dw $0003
    dw $FF4A
    dw $0001
    dw $FF09
    dw $0003
    dw $FF48
    dw $0001
    dw $FF09
    dw $0005
    dw $FF49
    dw $0001
    dw $FF09
    dw $0005
    dw $FF1C
    dw $0100
    dw $FF19
    dw $FF09
    dw $0004
    dw $FF1C
    dw $0101
    dw $FF19
    dw $FF09
    dw $0008
    dw $FF0A
    dw $0001
    dw $FFD0
    dw $FF07
    dw $000A
    dw $FF06
    dw $FF0A
    dw $0001
    dw $0030
    dw $FF47
    dw $0001
    dw $FF09
    dw $0002
    dw $FF1C
    dw $0201
    dw $FF19
    dw $FF0D
    dw $0001
    dw $0000
    dw $0040
    dw $FF0B
    dw $0001
    dw $FFF0
    dw $FF21
    dw $0060
    dw $FF17
    dw $FF03
    dw $0000
    dw $FF12
    dw $D974
    dw $0001
    dw $FFFF
; @BUILD_PROJECT END milly_bedroom_script

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
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script02
; ---------------------------------------------------------------------------
Map2F_Script02:
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script03
; ---------------------------------------------------------------------------
Map2F_Script03:
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script04
; ---------------------------------------------------------------------------
Map2F_Script04:
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script05
; ---------------------------------------------------------------------------
Map2F_Script05:
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script06
; ---------------------------------------------------------------------------
Map2F_Script06:
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script07
; ---------------------------------------------------------------------------
Map2F_Script07:
    dw $FF01  ; BranchIfFlagSet
    dw $00EE  ; Text $00EE: "$43:$485A *:Gwrr, Gwrr..."
    dw Bank0E_ScriptAddr_4BEE          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00EC  ; Text $00EC: "$43:$4772 *:Only those registered are // allowed h"
    dw Bank0E_ScriptAddr_4BEA          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00EB  ; Text $00EB: "$43:$475D You hear a voice."
    dw Bank0E_ScriptAddr_4BE6          ; -> branch target
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFFF  ; END

Bank0E_ScriptAddr_4BE6:
    dw $0514  ; Text $0514: "$49:$42CB Milayou:Good night [HERO]! // Sweet drea"
    dw $FFFF  ; END

Bank0E_ScriptAddr_4BEA:
    dw $0515  ; Text $0515: "$49:$42F7 Milayou:Good night [HERO]! Go to // slee"
    dw $FFFF  ; END

Bank0E_ScriptAddr_4BEE:
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script08
; ---------------------------------------------------------------------------
Map2F_Script08:
    dw $FF01  ; BranchIfFlagSet
    dw $00E4  ; Text $00E4: "$43:$43F5 *:Well done! You survived // G class!"
    dw Bank0E_ScriptAddr_4BFC          ; -> branch target
    dw $000B  ; Text $000B: "$42:$476A Terry looks at the bookshelf. // :Encycl"
    dw $FFFF  ; END

Bank0E_ScriptAddr_4BFC:
    dw $051A  ; Text $051A: "$49:$43AC [HERO] checked out the bookshelf. // :En"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script09
; ---------------------------------------------------------------------------
Map2F_Script09:
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script10
; ---------------------------------------------------------------------------
Map2F_Script10:
    dw $FF01  ; BranchIfFlagSet
    dw $00F0  ; Text $00F0: "$43:$48CD *:Where did the MiniDrak go?"
    dw Bank0E_ScriptAddr_4CB4          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00E4  ; Text $00E4: "$43:$43F5 *:Well done! You survived // G class!"
    dw Bank0E_ScriptAddr_4CAC          ; -> branch target
    dw $FF21  ; TriggerBattle2
    dw $0060  ; Text $0060: "$42:$7430 *:This is the castle of // GreatTree. //"
    dw $FF17  ; SetupBossBattle
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF1D  ; LockMovement
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF1C  ; CompareRAM
    dw $0100  ; Text $0100: "$43:$4DEC [HERO] looked into the jar. // An old la"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF1C  ; CompareRAM
    dw $0300  ; Text $0300: "$46:$4180 *:Hey, little thief, I think // it's pas"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF12  ; WriteRAM
    dw $D951  ; RAM $D951
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF3B  ; Cmd3B
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $0048  ; Text $0048: "$42:$6612 Pulio:Your Majesty please forgive me! //"
    dw $FFFF  ; END

Bank0E_ScriptAddr_4CAC:
    dw $051B  ; Text $051B: "$49:$43FA [SOUND 60][HERO] looked in the dresser. "
    dw $FF03  ; SetEventFlag
    dw $00EA  ; Text $00EA: "$43:$473F *:Get out of my way! Huff!"
    dw $FFFF  ; END

Bank0E_ScriptAddr_4CB4:
    dw $FF21  ; TriggerBattle2
    dw $0060  ; Text $0060: "$42:$7430 *:This is the castle of // GreatTree. //"
    dw $FF17  ; SetupBossBattle
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF1D  ; LockMovement
    dw $FF1B  ; MultiRAMWrite
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF1C  ; CompareRAM
    dw $0100  ; Text $0100: "$43:$4DEC [HERO] looked into the jar. // An old la"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF1C  ; CompareRAM
    dw $0300  ; Text $0300: "$46:$4180 *:Hey, little thief, I think // it's pas"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF12  ; WriteRAM
    dw $D951  ; RAM $D951
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF3B  ; Cmd3B
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $0048  ; Text $0048: "$42:$6612 Pulio:Your Majesty please forgive me! //"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script11
; ---------------------------------------------------------------------------
Map2F_Script11:
    dw $000E  ; Text $000E: "$42:$483B Terry looked at a stuffed animal. // Som"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script12
; ---------------------------------------------------------------------------
Map2F_Script12:
    dw $000D  ; Text $000D: "$42:$47FB Terry looked in front of him. // The clo"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script13
; ---------------------------------------------------------------------------
Map2F_Script13:
    dw $FF01  ; BranchIfFlagSet
    dw $00EB  ; Text $00EB: "$43:$475D You hear a voice."
    dw Bank0E_ScriptAddr_4D66          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00EC  ; Text $00EC: "$43:$4772 *:Only those registered are // allowed h"
    dw Bank0E_ScriptAddr_4D66          ; -> branch target
    dw $FFFF  ; END

Bank0E_ScriptAddr_4D66:
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF1C  ; CompareRAM
    dw $0101  ; Text $0101: "$43:$4E4F [HERO] looked into the jar. // A piece o"
    dw $FF19  ; FadeEffect
    dw $FF07  ; InitDialogMode
    dw $0516  ; Text $0516: "$49:$4322 Milayou:...Oh? ...[HERO]!"
    dw $FF06  ; IncrementCounter
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF07  ; InitDialogMode
    dw $0517  ; Text $0517: "$49:$433A Milayou:What's in your pocket?"
    dw $FF06  ; IncrementCounter
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF1C  ; CompareRAM
    dw $0400  ; Text $0400: "$21:$4106 *:I heard a rumor that a terrible // mas"
    dw $FF1C  ; CompareRAM
    dw $0401  ; Text $0401: "$21:$420F *:I think I'm gonna quit // staying up a"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF12  ; WriteRAM
    dw $D974  ; RAM $D974
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF03  ; SetEventFlag
    dw $00ED  ; Text $00ED: "$43:$47A4 *:H...Hello! I'm T..T..Teto. // *:I'm ne"
    dw $FF41  ; SetBGM
    dw $0047  ; Text $0047: "$42:$65E5 King:Pulio, did Hale escape // as well?"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF65  ; Cmd$65
    dw $FF12  ; WriteRAM
    dw $C88A  ; RAM $C88A
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF12  ; WriteRAM
    dw $C88B  ; RAM $C88B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF3E  ; Cmd3E
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map2F_Script14
; ---------------------------------------------------------------------------
Map2F_Script14:
    dw $FF01  ; BranchIfFlagSet
    dw $00EB  ; Text $00EB: "$43:$475D You hear a voice."
    dw Bank0E_ScriptAddr_4E1A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00EC  ; Text $00EC: "$43:$4772 *:Only those registered are // allowed h"
    dw Bank0E_ScriptAddr_4E1A          ; -> branch target
    dw $FFFF  ; END

Bank0E_ScriptAddr_4E1A:
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF1C  ; CompareRAM
    dw $0101  ; Text $0101: "$43:$4E4F [HERO] looked into the jar. // A piece o"
    dw $FF19  ; FadeEffect
    dw $FF07  ; InitDialogMode
    dw $0516  ; Text $0516: "$49:$4322 Milayou:...Oh? ...[HERO]!"
    dw $FF06  ; IncrementCounter
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF07  ; InitDialogMode
    dw $0517  ; Text $0517: "$49:$433A Milayou:What's in your pocket?"
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
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBeginning_Script01
; ---------------------------------------------------------------------------
BossBeginning_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $003D  ; Text $003D: "$42:$5F5F *:C'mon, I'll give you a beating. // Sni"
    dw Bank0E_ScriptAddr_4F0E          ; -> branch target
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FF03  ; SetEventFlag
    dw $003D  ; Text $003D: "$42:$5F5F *:C'mon, I'll give you a beating. // Sni"
    dw $FF5A  ; Cmd5A
    dw $000B  ; Text $000B: "$42:$476A Terry looks at the bookshelf. // :Encycl"
    dw $FF07  ; InitDialogMode
    dw $0059  ; Text $0059: "$42:$7092 *:You are strong! I like you, // [HERO]."
    dw $FF06  ; IncrementCounter
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0307  ; Text $0307: "$46:$4359 *:It can't be! My Betty is... // *:actua"
    dw $FF1C  ; CompareRAM
    dw $1502
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $0146  ; Text $0146: "$43:$685F Watabou:Right on! [HERO]! // I'll take y"
    dw $FF1C  ; CompareRAM
    dw $0402  ; Text $0402: "$21:$4248 *:You defeated me. I didn't even have //"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw $FF03  ; SetEventFlag
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D968  ; RAM $D968
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D976  ; RAM $D976
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

Bank0E_ScriptAddr_4F0E:
    dw $013F  ; Text $013F: "$43:$6649 *:How many times do I have to say // it?"
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
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossVillager_Script01
; ---------------------------------------------------------------------------
BossVillager_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00B6  ; Text $00B6: "$1A:$5342 *:...I am not a rebel!"
    dw Bank0E_ScriptAddr_4FA8          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00B2
    dw Bank0E_ScriptAddr_4F8E          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00B5
    dw Bank0E_ScriptAddr_4F80          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00B4  ; Text $00B4: "$1A:$52C2 *:No matter what, you keep fighting. // "
    dw Bank0E_ScriptAddr_4F6E          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00B3
    dw Bank0E_ScriptAddr_4F5C          ; -> branch target
    dw $0220  ; Text $0220: "$1B:$4E33 *:Oh, my prince! // *:You came here to s"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0E_ScriptAddr_4FAC          ; -> branch target
    dw $0221  ; Text $0221: "$1B:$4E68 *:I see..."
    dw $FF03  ; SetEventFlag
    dw $00B3
    dw $FFFF  ; END

Bank0E_ScriptAddr_4F5C:
    dw $0220  ; Text $0220: "$1B:$4E33 *:Oh, my prince! // *:You came here to s"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0E_ScriptAddr_4FAC          ; -> branch target
    dw $0222  ; Text $0222: "$1B:$4E77 *:I want to go back to the // castle..."
    dw $FF03  ; SetEventFlag
    dw $00B4  ; Text $00B4: "$1A:$52C2 *:No matter what, you keep fighting. // "
    dw $FFFF  ; END

Bank0E_ScriptAddr_4F6E:
    dw $0220  ; Text $0220: "$1B:$4E33 *:Oh, my prince! // *:You came here to s"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0E_ScriptAddr_4FAC          ; -> branch target
    dw $0223  ; Text $0223: "$1B:$4EA4 *:*sigh*"
    dw $FF03  ; SetEventFlag
    dw $00B5
    dw $FFFF  ; END

Bank0E_ScriptAddr_4F80:
    dw $0220  ; Text $0220: "$1B:$4E33 *:Oh, my prince! // *:You came here to s"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0E_ScriptAddr_4FAC          ; -> branch target
    dw $0224  ; Text $0224: "$1B:$4EB1 *:I want to go back to the // castle..."
    dw $FFFF  ; END

Bank0E_ScriptAddr_4F8E:
    dw $0227  ; Text $0227: "$1B:$4F6B *:It is okay. You're still // little. //"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $4FA0
    dw $0228  ; Text $0228: "$1B:$4FD9 *:Please leave quietly. [YES/NO]"
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
    dw $0250  ; Text $0250: "$45:$481E *:I know. // *:There will be a youth... "
    dw $FFFF  ; END

Bank0E_ScriptAddr_4FAC:
    dw $0225  ; Text $0225: "$1B:$4EDE *:Oh, I'm so happy! // *blush* // *:Oh p"
    dw $0226  ; Text $0226: "$1B:$4F33 [HERO] tried to pick up the // princess."
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
    dw $00B6  ; Text $00B6: "$1A:$5342 *:...I am not a rebel!"
    dw Bank0E_ScriptAddr_4FC6          ; -> branch target
    dw $0251  ; Text $0251: "$45:$4883 *:Zzz... zzzz...."
    dw $FFFF  ; END

Bank0E_ScriptAddr_4FC6:
    dw $0252  ; Text $0252: "$45:$4899 *:Zzz... zzzz.... ....*bust!* // *:It's "
    dw $FF03  ; SetEventFlag
    dw $00B7
    dw $FF5A  ; Cmd5A
    dw $001F  ; Text $001F: "$42:$4D08 *:This is the Kingdom of // GreatTree!"
    dw $FF07  ; InitDialogMode
    dw $0254  ; Text $0254: "$45:$490F *:You're strong!!"
    dw $FF06  ; IncrementCounter
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0304  ; Text $0304: "$46:$4292 *:Eeek! I cannot stand you! // *:I'm gon"
    dw $FF1C  ; CompareRAM
    dw $1602
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $0255  ; Text $0255: "$45:$4924 Watabou:You couldn't carry the // prince"
    dw $FF1C  ; CompareRAM
    dw $0402  ; Text $0402: "$21:$4248 *:You defeated me. I didn't even have //"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0031  ; Text $0031: "$42:$5B3C *:Upper floor, the monster farm. // *:Pu"
    dw $FF03  ; SetEventFlag
    dw $0011  ; Text $0011: "$42:$4A3E *:Hey, is he the new master // Watabou b"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D969  ; RAM $D969
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D977  ; RAM $D977
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF00  ; BranchIfFlagClear
    dw $0012  ; Text $0012: "$42:$4A77 *:Yes indeed, I'm taking him to see // t"
    dw $506A
    dw $FF12  ; WriteRAM
    dw $D969  ; RAM $D969
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5076:
    dw $0253  ; Text $0253: "$45:$48F2 *:...zzz. You came again!"
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
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF01  ; BranchIfFlagSet
    dw $00B8  ; Text $00B8: "$1A:$53A9 *:What? Are we having the match // now? "
    dw Bank0E_ScriptAddr_517E          ; -> branch target
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0B  ; NPCMoveY
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF0A  ; NPCMoveX
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FFD0  ; Cmd$D0
    dw $FF0B  ; NPCMoveY
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1C  ; CompareRAM
    dw $0102  ; Text $0102: "$43:$4EEE *:Hm.. It doesn't listen to me much. // "
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF1C  ; CompareRAM
    dw $0102  ; Text $0102: "$43:$4EEE *:Hm.. It doesn't listen to me much. // "
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF1C  ; CompareRAM
    dw $0102  ; Text $0102: "$43:$4EEE *:Hm.. It doesn't listen to me much. // "
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF1C  ; CompareRAM
    dw $0102  ; Text $0102: "$43:$4EEE *:Hm.. It doesn't listen to me much. // "
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF1D  ; LockMovement
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF0  ; Cmd$F0
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF22  ; Cmd22
    dw $FF1A  ; Cmd1A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF21  ; TriggerBattle2
    dw $0054  ; Text $0054: "$42:$6DC6 *:You will find items scattered // aroun"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0305  ; Text $0305: "$46:$42D5 *:You again!? I'm really gonna // get yo"
    dw $FF1C  ; CompareRAM
    dw $1802
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF03  ; SetEventFlag
    dw $00B8  ; Text $00B8: "$1A:$53A9 *:What? Are we having the match // now? "
    dw $FFFF  ; END

Bank0E_ScriptAddr_517E:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossTalisman_Script01
; ---------------------------------------------------------------------------
BossTalisman_Script01:
    dw $0256  ; Text $0256: "$45:$4977 *:........"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossTalisman_Script02
; ---------------------------------------------------------------------------
BossTalisman_Script02:
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF07  ; InitDialogMode
    dw $FF01  ; BranchIfFlagSet
    dw $00B9  ; Text $00B9: "$1A:$541F *:I just wanna attack the enemy!"
    dw Bank0E_ScriptAddr_5246          ; -> branch target
    dw $0257  ; Text $0257: "$45:$4986 *:You, stop right there! // *:You shall "
    dw $FF03  ; SetEventFlag
    dw $00B9  ; Text $00B9: "$1A:$541F *:I just wanna attack the enemy!"
    dw $FF5A  ; Cmd5A
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF07  ; InitDialogMode
    dw $0259  ; Text $0259: "$45:$4A25 *:You are powerful. // *:But defeating m"
    dw $FF06  ; IncrementCounter
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0405  ; Text $0405: "$21:$43D8 *:...fine. If you change your // mind, l"
    dw $FF1C  ; CompareRAM
    dw $1503
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $0262  ; Text $0262: "$45:$4DAD Watabou:This village is an // illusion o"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4A  ; Cmd4A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF49  ; Cmd49
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0032  ; Text $0032: "$42:$5B99 *:Watabou brings us capable // masters. "
    dw $FF03  ; SetEventFlag
    dw $0012  ; Text $0012: "$42:$4A77 *:Yes indeed, I'm taking him to see // t"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D969  ; RAM $D969
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D978  ; RAM $D978
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF00  ; BranchIfFlagClear
    dw $0011  ; Text $0011: "$42:$4A3E *:Hey, is he the new master // Watabou b"
    dw Bank0E_ScriptAddr_523A          ; -> branch target
    dw $FF12  ; WriteRAM
    dw $D969  ; RAM $D969
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
Bank0E_ScriptAddr_523A:
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5246:
    dw $0258  ; Text $0258: "$45:$49EF *:Must I repeat myself? // *:You shall n"
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
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossMemories_Script01
; ---------------------------------------------------------------------------
BossMemories_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00BC  ; Text $00BC: "$1A:$548D *:Are you telling me what // to do? What"
    dw Bank0E_ScriptAddr_533C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00BB
    dw Bank0E_ScriptAddr_5284          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00BA  ; Text $00BA: "$1A:$5443 *:Too bad, attacking will be // the focu"
    dw Bank0E_ScriptAddr_527C          ; -> branch target
    dw $0263  ; Text $0263: "$45:$4E3D *:Grrrr... Whoosh! Whoooosh!"
    dw $FF03  ; SetEventFlag
    dw $00BA  ; Text $00BA: "$1A:$5443 *:Too bad, attacking will be // the focu"
    dw $FFFF  ; END

Bank0E_ScriptAddr_527C:
    dw $0264  ; Text $0264: "$45:$4E5D *:Guffaw Guffaw..? Cackle cackle...?"
    dw $FF03  ; SetEventFlag
    dw $00BB
    dw $FFFF  ; END

Bank0E_ScriptAddr_5284:
    dw $0265  ; Text $0265: "$45:$4E85 *:Grrrr... Whoosh! Whoooosh! // *:......"
    dw $FF03  ; SetEventFlag
    dw $00BC  ; Text $00BC: "$1A:$548D *:Are you telling me what // to do? What"
    dw $FF5A  ; Cmd5A
    dw $0033  ; Text $0033: "$42:$5C54 *:I wonder where I can get treats."
    dw $FF07  ; InitDialogMode
    dw $0267  ; Text $0267: "$45:$4ED9 *:[HERO]! [HERO]!! // *:Meow. Purrrr..."
    dw $FF06  ; IncrementCounter
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0407  ; Text $0407: "$21:$44A2 *:It's a LifeAcorn. // Use it wisely."
    dw $FF1C  ; CompareRAM
    dw $1502
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $0268  ; Text $0268: "$45:$4EFC Watabou:It seems MadCat is attached // t"
    dw $FF1C  ; CompareRAM
    dw $0402  ; Text $0402: "$21:$4248 *:You defeated me. I didn't even have //"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0033  ; Text $0033: "$42:$5C54 *:I wonder where I can get treats."
    dw $FF03  ; SetEventFlag
    dw $0013  ; Text $0013: "$42:$4AAC *:Good luck at the Starry Night // Tourn"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D96A  ; RAM $D96A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D979  ; RAM $D979
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF00  ; BranchIfFlagClear
    dw $0014  ; Text $0014: "$42:$4AE0 *:Now it's time to go see the King."
    dw $5330
    dw $FF12  ; WriteRAM
    dw $D96A  ; RAM $D96A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

Bank0E_ScriptAddr_533C:
    dw $0266  ; Text $0266: "$45:$4EBB *:Grrrr... Cackle cackle!!"
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
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script01
; ---------------------------------------------------------------------------
BossBewilder_Script01:
    dw $0269  ; Text $0269: "$45:$4F48 [HERO] read the sign. // :Youth goes in "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script02
; ---------------------------------------------------------------------------
BossBewilder_Script02:
    dw $FF01  ; BranchIfFlagSet
    dw $0117  ; Text $0117: "$43:$581F [HERO] read the blackboard. // :Do's & D"
    dw Bank0E_ScriptAddr_5422          ; -> branch target
    dw $026A  ; Text $026A: "$45:$4FA2 *:Hee hee hee! I didn't think // you cou"
    dw $FF03  ; SetEventFlag
    dw $0117  ; Text $0117: "$43:$581F [HERO] read the blackboard. // :Do's & D"
    dw $FF5A  ; Cmd5A
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw $FF07  ; InitDialogMode
    dw $0290  ; Text $0290: "$45:$64F5 *:Ha ha ha! You beat me!"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0205  ; Text $0205: "$1B:$4486 K-thump! Something // hit [HERO]."
    dw $FF1C  ; CompareRAM
    dw $1505
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $0293  ; Text $0293: "$45:$6535 Watabou:You did a good job solving // th"
    dw $FF1C  ; CompareRAM
    dw $0405  ; Text $0405: "$21:$43D8 *:...fine. If you change your // mind, l"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF49  ; Cmd49
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0034  ; Text $0034: "$42:$5C7A [HERO] read the sign. // :Danger, Don't "
    dw $FF03  ; SetEventFlag
    dw $0014  ; Text $0014: "$42:$4AE0 *:Now it's time to go see the King."
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D96A  ; RAM $D96A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D97A  ; RAM $D97A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF00  ; BranchIfFlagClear
    dw $0013  ; Text $0013: "$42:$4AAC *:Good luck at the Starry Night // Tourn"
    dw Bank0E_ScriptAddr_5416          ; -> branch target
    dw $FF12  ; WriteRAM
    dw $D96A  ; RAM $D96A
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
Bank0E_ScriptAddr_5416:
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5422:
    dw $026B  ; Text $026B: "$45:$5010 *:No matter how many times you // fight,"
    dw $FF14  ; ClearGameFlags
    dw $537A
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script03
; ---------------------------------------------------------------------------
BossBewilder_Script03:
    dw $FF01  ; BranchIfFlagSet
    dw $00BD  ; Text $00BD: "$1A:$54C2 *:I cannot stand by and let the // monst"
    dw Bank0E_ScriptAddr_543E          ; -> branch target
    dw $0291  ; Text $0291: "$45:$6511 *:Squeaking squeaking."
    dw $FF06  ; IncrementCounter
    dw $FF05  ; TriggerBattle
    dw $0155  ; Text $0155: "$43:$6FFA *:I see...Hm.."
    dw $FF03  ; SetEventFlag
    dw $00BD  ; Text $00BD: "$1A:$54C2 *:I cannot stand by and let the // monst"
    dw $FFFF  ; END

Bank0E_ScriptAddr_543E:
    dw $0292  ; Text $0292: "$45:$652B *:… …"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script04
; ---------------------------------------------------------------------------
BossBewilder_Script04:
    dw $FF01  ; BranchIfFlagSet
    dw $00BE  ; Text $00BE: "$1A:$5501 *:I don't like attacking // that much."
    dw Bank0E_ScriptAddr_5456          ; -> branch target
    dw $0291  ; Text $0291: "$45:$6511 *:Squeaking squeaking."
    dw $FF06  ; IncrementCounter
    dw $FF05  ; TriggerBattle
    dw $0155  ; Text $0155: "$43:$6FFA *:I see...Hm.."
    dw $FF03  ; SetEventFlag
    dw $00BE  ; Text $00BE: "$1A:$5501 *:I don't like attacking // that much."
    dw $FFFF  ; END

Bank0E_ScriptAddr_5456:
    dw $0292  ; Text $0292: "$45:$652B *:… …"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script05
; ---------------------------------------------------------------------------
BossBewilder_Script05:
    dw $FF01  ; BranchIfFlagSet
    dw $00BF  ; Text $00BF: "$1A:$552C *:I am fine as long as everyone // is co"
    dw Bank0E_ScriptAddr_546E          ; -> branch target
    dw $0291  ; Text $0291: "$45:$6511 *:Squeaking squeaking."
    dw $FF06  ; IncrementCounter
    dw $FF05  ; TriggerBattle
    dw $0155  ; Text $0155: "$43:$6FFA *:I see...Hm.."
    dw $FF03  ; SetEventFlag
    dw $00BF  ; Text $00BF: "$1A:$552C *:I am fine as long as everyone // is co"
    dw $FFFF  ; END

Bank0E_ScriptAddr_546E:
    dw $0292  ; Text $0292: "$45:$652B *:… …"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script06
; ---------------------------------------------------------------------------
BossBewilder_Script06:
    dw $FF01  ; BranchIfFlagSet
    dw $00C0  ; Text $00C0: "$1A:$556C *:I cannot stand still when I see // mon"
    dw Bank0E_ScriptAddr_5486          ; -> branch target
    dw $0291  ; Text $0291: "$45:$6511 *:Squeaking squeaking."
    dw $FF06  ; IncrementCounter
    dw $FF05  ; TriggerBattle
    dw $0155  ; Text $0155: "$43:$6FFA *:I see...Hm.."
    dw $FF03  ; SetEventFlag
    dw $00C0  ; Text $00C0: "$1A:$556C *:I cannot stand still when I see // mon"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5486:
    dw $0292  ; Text $0292: "$45:$652B *:… …"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script07
; ---------------------------------------------------------------------------
BossBewilder_Script07:
    dw $FF10  ; NPCAnimStart
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0078
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script08
; ---------------------------------------------------------------------------
BossBewilder_Script08:
    dw $FF01  ; BranchIfFlagSet
    dw $00BF  ; Text $00BF: "$1A:$552C *:I am fine as long as everyone // is co"
    dw Bank0E_ScriptAddr_549E          ; -> branch target
    dw $FF10  ; NPCAnimStart
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0048  ; Text $0048: "$42:$6612 Pulio:Your Majesty please forgive me! //"
Bank0E_ScriptAddr_549E:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script09
; ---------------------------------------------------------------------------
BossBewilder_Script09:
    dw $FF01  ; BranchIfFlagSet
    dw $00C0  ; Text $00C0: "$1A:$556C *:I cannot stand still when I see // mon"
    dw Bank0E_ScriptAddr_54AC          ; -> branch target
    dw $FF11  ; NPCAnimSetup
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
Bank0E_ScriptAddr_54AC:
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script10
; ---------------------------------------------------------------------------
BossBewilder_Script10:
    dw $FF10  ; NPCAnimStart
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
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
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map35_Script01
; ---------------------------------------------------------------------------
Map35_Script01:
    dw $0294  ; Text $0294: "$45:$65BF *:Wel...come..."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map35_Script02
; ---------------------------------------------------------------------------
Map35_Script02:
    dw $0295  ; Text $0295: "$45:$65D3 *:Come.....again.."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map35_Script03
; ---------------------------------------------------------------------------
Map35_Script03:
    dw $0296  ; Text $0296: "$45:$65EA *:… … …"
    dw $FF5A  ; Cmd5A
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw $FF07  ; InitDialogMode
    dw $0297  ; Text $0297: "$45:$65F6 *:… … …"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0204  ; Text $0204: "$1B:$444A *:Oh well, nobody's here. // I wanna hav"
    dw $FF1C  ; CompareRAM
    dw $1502
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $0298  ; Text $0298: "$45:$6602 Watabou:This place was ruined // by mons"
    dw $FF1C  ; CompareRAM
    dw $0402  ; Text $0402: "$21:$4248 *:You defeated me. I didn't even have //"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0035  ; Text $0035: "$42:$5CC2 *:No! You'll be hurt if you fall."
    dw $FF03  ; SetEventFlag
    dw $0015  ; Text $0015: "$42:$4B06 *:I'm the minister of this kingdom. // A"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D93A  ; RAM $D93A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D97B  ; RAM $D97B
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF00  ; BranchIfFlagClear
    dw $002D  ; Text $002D: "$42:$58B2 *:Should I repeat the legend of the // S"
    dw Bank0E_ScriptAddr_557C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00F6  ; Text $00F6: "$43:$4A22 *:It's a tie... In this case... // *:I w"
    dw Bank0E_ScriptAddr_55A0          ; -> branch target
Bank0E_ScriptAddr_557C:
    dw $FF01  ; BranchIfFlagSet
    dw $00F6  ; Text $00F6: "$43:$4A22 *:It's a tie... In this case... // *:I w"
    dw Bank0E_ScriptAddr_5596          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00EE  ; Text $00EE: "$43:$485A *:Gwrr, Gwrr..."
    dw Bank0E_ScriptAddr_558C          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_55AA          ; -> branch target
Bank0E_ScriptAddr_558C:
    dw $FF12  ; WriteRAM
    dw $D93A  ; RAM $D93A
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_55AA          ; -> branch target
Bank0E_ScriptAddr_5596:
    dw $FF12  ; WriteRAM
    dw $D93A  ; RAM $D93A
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_55AA          ; -> branch target
Bank0E_ScriptAddr_55A0:
    dw $FF12  ; WriteRAM
    dw $D93A  ; RAM $D93A
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_55AA          ; -> branch target
Bank0E_ScriptAddr_55AA:
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
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
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossPeace_Script01
; ---------------------------------------------------------------------------
BossPeace_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $0016  ; Text $0016: "$42:$4B9C *:His Majesty is in trouble. // Please p"
    dw Bank0E_ScriptAddr_55FE          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00C2
    dw Bank0E_ScriptAddr_55FA          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00C1  ; Text $00C1: "$1A:$55B7 *:I..I.. is it o..o..okay to just // h.."
    dw Bank0E_ScriptAddr_55F2          ; -> branch target
    dw $0299  ; Text $0299: "$45:$667C [HERO] pulled the slot machine! // The s"
    dw $FF03  ; SetEventFlag
    dw $00C1  ; Text $00C1: "$1A:$55B7 *:I..I.. is it o..o..okay to just // h.."
    dw $FFFF  ; END

Bank0E_ScriptAddr_55F2:
    dw $0311  ; Text $0311: "$46:$47D2 [HERO] pulled the arm of the // slot mac"
    dw $FF03  ; SetEventFlag
    dw $00C2
    dw $FFFF  ; END

Bank0E_ScriptAddr_55FA:
    dw $0312  ; Text $0312: "$46:$4835 The slot machine is out of order."
    dw $FFFF  ; END

Bank0E_ScriptAddr_55FE:
    dw $0313  ; Text $0313: "$46:$4859 There are 3 Slimes sleeping inside."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossPeace_Script02
; ---------------------------------------------------------------------------
BossPeace_Script02:
    dw $FF01  ; BranchIfFlagSet
    dw $0016  ; Text $0016: "$42:$4B9C *:His Majesty is in trouble. // Please p"
    dw Bank0E_ScriptAddr_5628          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00C4
    dw Bank0E_ScriptAddr_5624          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00C3  ; Text $00C3: "$1A:$5624 *:Arghhh... Flee or should I // go for i"
    dw Bank0E_ScriptAddr_561C          ; -> branch target
    dw $0314  ; Text $0314: "$46:$487F [HERO] pulled the slot machine! // The r"
    dw $FF03  ; SetEventFlag
    dw $00C3  ; Text $00C3: "$1A:$5624 *:Arghhh... Flee or should I // go for i"
    dw $FFFF  ; END

Bank0E_ScriptAddr_561C:
    dw $0315  ; Text $0315: "$46:$4937 [HERO] pulled the arm of the // slot mac"
    dw $FF03  ; SetEventFlag
    dw $00C4
    dw $FFFF  ; END

Bank0E_ScriptAddr_5624:
    dw $0316  ; Text $0316: "$46:$4988 It's out of order."
    dw $FFFF  ; END

Bank0E_ScriptAddr_5628:
    dw $0317  ; Text $0317: "$46:$499D 3 Metalys are sweating inside // the mac"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossPeace_Script03
; ---------------------------------------------------------------------------
BossPeace_Script03:
    dw $FF01  ; BranchIfFlagSet
    dw $0016  ; Text $0016: "$42:$4B9C *:His Majesty is in trouble. // Please p"
    dw Bank0E_ScriptAddr_5644          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00C5
    dw Bank0E_ScriptAddr_5640          ; -> branch target
    dw $0318  ; Text $0318: "$46:$49CF [HERO] pulled the arm of the // slot mac"
    dw $FF03  ; SetEventFlag
    dw $00C5
    dw $FFFF  ; END

Bank0E_ScriptAddr_5640:
    dw $0319  ; Text $0319: "$46:$4B14 The reel is spinning..."
    dw $FFFF  ; END

Bank0E_ScriptAddr_5644:
    dw $0843
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossPeace_Script04
; ---------------------------------------------------------------------------
BossPeace_Script04:
    dw $FF01  ; BranchIfFlagSet
    dw $0016  ; Text $0016: "$42:$4B9C *:His Majesty is in trouble. // Please p"
    dw Bank0E_ScriptAddr_5660          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00C6  ; Text $00C6: "$1A:$56D6 *:I know I'm careless but // I do help m"
    dw Bank0E_ScriptAddr_565C          ; -> branch target
    dw $031A  ; Text $031A: "$46:$4B2E [HERO] pulled the slot machine! // The r"
    dw $FF03  ; SetEventFlag
    dw $00C6  ; Text $00C6: "$1A:$56D6 *:I know I'm careless but // I do help m"
    dw $FFFF  ; END

Bank0E_ScriptAddr_565C:
    dw $0322  ; Text $0322: "$46:$4F85 There is a sign on the slot machine. // "
    dw $FFFF  ; END

Bank0E_ScriptAddr_5660:
    dw $0323  ; Text $0323: "$46:$4FCF There is a sign on the slot machine. // "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossPeace_Script05
; ---------------------------------------------------------------------------
BossPeace_Script05:
    dw $0324  ; Text $0324: "$46:$500E *:Welcome to the Casino! // Gold here is"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossPeace_Script06
; ---------------------------------------------------------------------------
BossPeace_Script06:
    dw $FF01  ; BranchIfFlagSet
    dw $0016  ; Text $0016: "$42:$4B9C *:His Majesty is in trouble. // Please p"
    dw Bank0E_ScriptAddr_5672          ; -> branch target
    dw $0325  ; Text $0325: "$46:$504E *:How's your luck?"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5672:
    dw $0326  ; Text $0326: "$46:$5064 *:I need to get good at it."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossPeace_Script07
; ---------------------------------------------------------------------------
BossPeace_Script07:
    dw $FF01  ; BranchIfFlagSet
    dw $0016  ; Text $0016: "$42:$4B9C *:His Majesty is in trouble. // Please p"
    dw Bank0E_ScriptAddr_5680          ; -> branch target
    dw $0327  ; Text $0327: "$46:$5083 *:That customer has an attitude! // *:Ca"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5680:
    dw $0328  ; Text $0328: "$46:$50D1 *:No violence in this store."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossPeace_Script08
; ---------------------------------------------------------------------------
BossPeace_Script08:
    dw $FF01  ; BranchIfFlagSet
    dw $00C7  ; Text $00C7: "$1A:$570A *:Careless monster is my middle name."
    dw Bank0E_ScriptAddr_574A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00C6  ; Text $00C6: "$1A:$56D6 *:I know I'm careless but // I do help m"
    dw Bank0E_ScriptAddr_5694          ; -> branch target
    dw $0329  ; Text $0329: "$46:$50F1 *:Gwrrrrrrrr.. This machine gave // me n"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5694:
    dw $032A  ; Text $032A: "$46:$5126 *:Gwrrrrrrrr.. Why are you the // only l"
    dw $FF03  ; SetEventFlag
    dw $00C7  ; Text $00C7: "$1A:$570A *:Careless monster is my middle name."
    dw $FF5A  ; Cmd5A
    dw $004B  ; Text $004B: "$42:$6791 Pulio:Majesty, Hale escaped // through t"
    dw $FF07  ; InitDialogMode
    dw $0346  ; Text $0346: "$46:$5D41 *:No luck today! // *:Hey, you don't hav"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0304  ; Text $0304: "$46:$4292 *:Eeek! I cannot stand you! // *:I'm gon"
    dw $FF1C  ; CompareRAM
    dw $1605
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $0347  ; Text $0347: "$46:$5DC6 Watabou:Did you have a good time // at t"
    dw $FF1C  ; CompareRAM
    dw $0405  ; Text $0405: "$21:$43D8 *:...fine. If you change your // mind, l"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0036  ; Text $0036: "$42:$5CE6 *:If it was not for this hole... // *:Oh"
    dw $FF03  ; SetEventFlag
    dw $0016  ; Text $0016: "$42:$4B9C *:His Majesty is in trouble. // Please p"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D96B  ; RAM $D96B
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D97C  ; RAM $D97C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF00  ; BranchIfFlagClear
    dw $0017  ; Text $0017: "$42:$4BD7 *:Please listen to his wish."
    dw $573E
    dw $FF12  ; WriteRAM
    dw $D96B  ; RAM $D96B
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

Bank0E_ScriptAddr_574A:
    dw $032B  ; Text $032B: "$46:$517C *:It's mine now!!"
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
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF15  ; PlaySE
    dw $D9E5  ; RAM $D9E5
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0E_ScriptAddr_5774          ; -> branch target
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5774:
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0050  ; Text $0050: "$42:$6ABA Pulio:Sorry [HERO], It's my fault... // "
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0060  ; Text $0060: "$42:$7430 *:This is the castle of // GreatTree. //"
    dw $FF1B  ; MultiRAMWrite
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0070
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF12  ; WriteRAM
    dw $D9E5  ; RAM $D9E5
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBravery_Script01
; ---------------------------------------------------------------------------
BossBravery_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00C9  ; Text $00C9: "$1A:$5798 *:I guarantee a comfortable // environme"
    dw Bank0E_ScriptAddr_58D4          ; -> branch target
    dw $03F6  ; Text $03F6: "$47:$561C *:There are cliffs that you can jump // "
    dw $FF03  ; SetEventFlag
    dw $00C9  ; Text $00C9: "$1A:$5798 *:I guarantee a comfortable // environme"
    dw $FF5A  ; Cmd5A
    dw $004D  ; Text $004D: "$42:$68DF *:His Majesty seems to be // very upset."
    dw $FF07  ; InitDialogMode
    dw $051C  ; Text $051C: "$49:$4430 *:There are cliffs that we can jump // o"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0406  ; Text $0406: "$21:$4411 *:My StoneMan can use Ahhh! // *:Boy mon"
    dw $FF1C  ; CompareRAM
    dw $1507
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $051D  ; Text $051D: "$49:$446E Watabou:Good job finding the // invisibl"
    dw $FF1C  ; CompareRAM
    dw $0407  ; Text $0407: "$21:$44A2 *:It's a LifeAcorn. // Use it wisely."
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF47  ; Cmd47
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw $FF03  ; SetEventFlag
    dw $0017  ; Text $0017: "$42:$4BD7 *:Please listen to his wish."
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D96B  ; RAM $D96B
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D97D  ; RAM $D97D
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF00  ; BranchIfFlagClear
    dw $0016  ; Text $0016: "$42:$4B9C *:His Majesty is in trouble. // Please p"
    dw Bank0E_ScriptAddr_58C8          ; -> branch target
    dw $FF12  ; WriteRAM
    dw $D96B  ; RAM $D96B
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
Bank0E_ScriptAddr_58C8:
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

Bank0E_ScriptAddr_58D4:
    dw $0467  ; Text $0467: "$21:$7305 *:You came back again. I wonder // if yo"
    dw $FF14  ; ClearGameFlags
    dw $5824
; ---------------------------------------------------------------------------
; BossBravery_Script02
; ---------------------------------------------------------------------------
BossBravery_Script02:
    dw $FF01  ; BranchIfFlagSet
    dw $00AA  ; Text $00AA: "$1A:$5071 *:If you behave naturally. // You win na"
    dw Bank0E_ScriptAddr_59B0          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00C8
    dw Bank0E_ScriptAddr_59B0          ; -> branch target
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF47  ; Cmd47
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0B  ; NPCMoveY
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FFF0  ; Cmd$F0
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF1D  ; LockMovement
    dw $FF1C  ; CompareRAM
    dw $0F06
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0B  ; NPCMoveY
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FFF0  ; Cmd$F0
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF4A  ; Cmd4A
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF47  ; Cmd47
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF1C  ; CompareRAM
    dw $0105  ; Text $0105: "$43:$4FE2 *:Its the principal of the // school."
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF49  ; Cmd49
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF49  ; Cmd49
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF48  ; Cmd48
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF07  ; InitDialogMode
    dw $03F5  ; Text $03F5: "$47:$55FE *:Tut! Not in here either!"
    dw $FF06  ; IncrementCounter
    dw $FF0B  ; NPCMoveY
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
    dw $FF1D  ; LockMovement
    dw $FF1C  ; CompareRAM
    dw $1006
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0B  ; NPCMoveY
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
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
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "$42:$6E72 *:Hale was the cherished pet of // the K"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $000F  ; Text $000F: "$42:$48B2 *:Oh, you must be the master. // You mus"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF12  ; WriteRAM
    dw $D9E5  ; RAM $D9E5
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF0F  ; SetScreenScroll
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $0078
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; BossBravery_Script04
; ---------------------------------------------------------------------------
BossBravery_Script04:
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "$42:$6E72 *:Hale was the cherished pet of // the K"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $000F  ; Text $000F: "$42:$48B2 *:Oh, you must be the master. // You mus"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF12  ; WriteRAM
    dw $D9E5  ; RAM $D9E5
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF0F  ; SetScreenScroll
    dw $0037  ; Text $0037: "$42:$5D55 [HERO] read the sign. // :When the Great"
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
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
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF15  ; PlaySE
    dw $D9E5  ; RAM $D9E5
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0E_ScriptAddr_5A88          ; -> branch target
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5A88:
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF1B  ; MultiRAMWrite
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF12  ; WriteRAM
    dw $D9E5  ; RAM $D9E5
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map38_Script01
; ---------------------------------------------------------------------------
Map38_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00CA  ; Text $00CA: "$1A:$57E6 *:If you want to take the fight one // c"
    dw Bank0E_ScriptAddr_5BD6          ; -> branch target
    dw $051E  ; Text $051E: "$49:$44B1 *:Wow! Yummy meat! Yum!"
    dw $FF03  ; SetEventFlag
    dw $00CA  ; Text $00CA: "$1A:$57E6 *:If you want to take the fight one // c"
    dw $FF5A  ; Cmd5A
    dw $004F  ; Text $004F: "$42:$69A4 *:In the Chamber of Travelers' // Gates "
    dw $FF07  ; InitDialogMode
    dw $0520  ; Text $0520: "$49:$44FE *:Wow! I'll do anything for // the meat!"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0308  ; Text $0308: "$46:$43A5 *:Betty was actually // a CopyCat! Noooo"
    dw $FF1C  ; CompareRAM
    dw $1607
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $0521  ; Text $0521: "$49:$452B Watabou:It seems you had a hard // time "
    dw $FF1C  ; CompareRAM
    dw $0407  ; Text $0407: "$21:$44A2 *:It's a LifeAcorn. // Use it wisely."
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF48  ; Cmd48
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0038  ; Text $0038: "$42:$5E08 *:I heard that Pulio let the // monsters"
    dw $FF03  ; SetEventFlag
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D960  ; RAM $D960
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D97E  ; RAM $D97E
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5BD6:
    dw $051F  ; Text $051F: "$49:$44CC *:Wow, yummy meat comming this // way ag"
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
    dw $0055  ; Text $0055: "$42:$6E72 *:Hale was the cherished pet of // the K"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $000F  ; Text $000F: "$42:$48B2 *:Oh, you must be the master. // You mus"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF12  ; WriteRAM
    dw $D9E5  ; RAM $D9E5
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF0F  ; SetScreenScroll
    dw $0038  ; Text $0038: "$42:$5E08 *:I heard that Pulio let the // monsters"
    dw $0088
    dw $0038  ; Text $0038: "$42:$5E08 *:I heard that Pulio let the // monsters"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5C9C:
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5CA4:
    dw $000A  ; Text $000A: "$42:$45C1 *:You speak monster talk // don't you? /"
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5CAC:
    dw $000C  ; Text $000C: "$42:$47BF Terry looked at the bookshelf. // Too di"
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5CB4:
    dw $0042  ; Text $0042: "$42:$6437 Slio:Raise the monster to be // powerful"
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
    dw $0104  ; Text $0104: "$43:$4FA8 *:Yo man, wanna know who your // match i"
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5CD4:
    dw $0106  ; Text $0106: "$43:$500D *:Well,it'll be OK too."
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5CDC:
    dw $0108  ; Text $0108: "$43:$506B *:StubSucks & GoHoppers, // Anteaters & "
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5CE4:
    dw $010E  ; Text $010E: "$43:$5294 *:What the heck is an onigiri? // Why ca"
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5CEC:
    dw $0110  ; Text $0110: "$43:$5375 *:Oh, welcome Mas...ahem. // I am the Me"
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5CF4:
    dw $014E  ; Text $014E: "$43:$6D0E King:Well maybe I'm exaggerating a // li"
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5CFC:
    dw $0182  ; Text $0182: "$1A:$6713 *:Greetings. I manage the Vault. // *:Yo"
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
Bank0E_ScriptAddr_5D04:
    dw $018A  ; Text $018A: "$1A:$6AA5 [HERO] looked at the bookshelf. // :Seon"
    dw $5554
    dw $56D8
    dw $D957  ; RAM $D957
; ---------------------------------------------------------------------------
; Map38_Script16
; ---------------------------------------------------------------------------
Map38_Script16:
    dw $FF15  ; PlaySE
    dw $D9E4  ; RAM $D9E4
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0E_ScriptAddr_5D1C          ; -> branch target
    dw $FF00  ; BranchIfFlagClear
    dw $00CB  ; Text $00CB: "$1A:$5842 *:Don't mix me up with those guys // who"
    dw Bank0E_ScriptAddr_5D1C          ; -> branch target
    dw $FFFF  ; END

Bank0E_ScriptAddr_5D1C:
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF49  ; Cmd49
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0A  ; NPCMoveX
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FFF0  ; Cmd$F0
    dw $FF0B  ; NPCMoveY
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF0A  ; NPCMoveX
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF09  ; SetDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF47  ; Cmd47
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0A  ; NPCMoveX
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FFF0  ; Cmd$F0
    dw $FF0B  ; NPCMoveY
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FFE0  ; Cmd$E0
    dw $FF0A  ; NPCMoveX
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw $FF0B  ; NPCMoveY
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FFF0  ; Cmd$F0
    dw $FF0A  ; NPCMoveX
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_5CBC          ; -> branch target
    dw $FF4D  ; SetLongDelay
    dw $000A  ; Text $000A: "$42:$45C1 *:You speak monster talk // don't you? /"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF4D  ; SetLongDelay
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF49  ; Cmd49
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF4D  ; SetLongDelay
    dw $000A  ; Text $000A: "$42:$45C1 *:You speak monster talk // don't you? /"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF4D  ; SetLongDelay
    dw $000A  ; Text $000A: "$42:$45C1 *:You speak monster talk // don't you? /"
    dw $FF4A  ; Cmd4A
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF4D  ; SetLongDelay
    dw $000A  ; Text $000A: "$42:$45C1 *:You speak monster talk // don't you? /"
    dw $FF48  ; Cmd48
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
    dw $FF09  ; SetDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "$42:$6E72 *:Hale was the cherished pet of // the K"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF09  ; SetDelay
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF12  ; WriteRAM
    dw $D9E4  ; RAM $D9E4
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF03  ; SetEventFlag
    dw $00CB  ; Text $00CB: "$1A:$5842 *:Don't mix me up with those guys // who"
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
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map39_Script01
; ---------------------------------------------------------------------------
Map39_Script01:
    dw $0523  ; Text $0523: "$49:$4603 [HERO] looked into a jar. // There was a"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map39_Script02
; ---------------------------------------------------------------------------
Map39_Script02:
    dw $0522  ; Text $0522: "$49:$4572 [HERO] checked out a treasure // chest! "
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map39_Script03
; ---------------------------------------------------------------------------
Map39_Script03:
    dw $FF00  ; BranchIfFlagClear
    dw $00CC  ; Text $00CC: "$1A:$5885 *:Grrr...Nobody can catch me // by surpr"
    dw Bank0E_ScriptAddr_5E5C          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00CD  ; Text $00CD: "$1A:$58B8 *:Just sit back and wait for the // figh"
    dw Bank0E_ScriptAddr_5F1E          ; -> branch target
Bank0E_ScriptAddr_5E5C:
    dw $FF01  ; BranchIfFlagSet
    dw $00CD  ; Text $00CD: "$1A:$58B8 *:Just sit back and wait for the // figh"
    dw Bank0E_ScriptAddr_5F1A          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00CC  ; Text $00CC: "$1A:$5885 *:Grrr...Nobody can catch me // by surpr"
    dw Bank0E_ScriptAddr_5E6C          ; -> branch target
    dw $0524  ; Text $0524: "$49:$4653 *:......"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5E6C:
    dw $0525  ; Text $0525: "$49:$4660 *:So,yoooou saaaw my face...!!"
    dw $FF03  ; SetEventFlag
    dw $00CD  ; Text $00CD: "$1A:$58B8 *:Just sit back and wait for the // figh"
    dw $FF02  ; ClearEventFlag
    dw $00CC  ; Text $00CC: "$1A:$5885 *:Grrr...Nobody can catch me // by surpr"
    dw $FF5A  ; Cmd5A
    dw $0063  ; Text $0063: "$42:$7527 *:Fhew! I'm glad that I didn't get // hu"
    dw $FF07  ; InitDialogMode
    dw $0527  ; Text $0527: "$49:$469C *:Yoooou win...!!"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0308  ; Text $0308: "$46:$43A5 *:Betty was actually // a CopyCat! Noooo"
    dw $FF1C  ; CompareRAM
    dw $1502
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $0528  ; Text $0528: "$49:$46B2 Watabou:Good work! So,let's // gooooo ba"
    dw $FF1C  ; CompareRAM
    dw $0402  ; Text $0402: "$21:$4248 *:You defeated me. I didn't even have //"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $0039  ; Text $0039: "$42:$5E3E *:Hey, Mr.Monster Master. I wonder // wh"
    dw $FF03  ; SetEventFlag
    dw $0019  ; Text $0019: "$42:$4C22 *:Hurry! Go see the King!"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D96C  ; RAM $D96C
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D97F  ; RAM $D97F
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5F1A:
    dw $0524  ; Text $0524: "$49:$4653 *:......"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5F1E:
    dw $0526  ; Text $0526: "$49:$4682 *:It's yoooou agaaaain!"
    dw $FF02  ; ClearEventFlag
    dw $00CC  ; Text $00CC: "$1A:$5885 *:Grrr...Nobody can catch me // by surpr"
    dw $FF14  ; ClearGameFlags
    dw $5E76
; ---------------------------------------------------------------------------
; Map39_Script04
; ---------------------------------------------------------------------------
Map39_Script04:
    dw $FF01  ; BranchIfFlagSet
    dw $00CC  ; Text $00CC: "$1A:$5885 *:Grrr...Nobody can catch me // by surpr"
    dw Bank0E_ScriptAddr_5F48          ; -> branch target
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF08  ; NOP
    dw $FF10  ; NPCAnimStart
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0038  ; Text $0038: "$42:$5E08 *:I heard that Pulio let the // monsters"
    dw $FF11  ; NPCAnimSetup
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FF03  ; SetEventFlag
    dw $00CC  ; Text $00CC: "$1A:$5885 *:Grrr...Nobody can catch me // by surpr"
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
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF15  ; PlaySE
    dw $D9E5  ; RAM $D9E5
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0E_ScriptAddr_5F74          ; -> branch target
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

Bank0E_ScriptAddr_5F74:
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF1B  ; MultiRAMWrite
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0050  ; Text $0050: "$42:$6ABA Pulio:Sorry [HERO], It's my fault... // "
    dw $FF1B  ; MultiRAMWrite
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0060  ; Text $0060: "$42:$7430 *:This is the castle of // GreatTree. //"
    dw $FF1B  ; MultiRAMWrite
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0070
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF12  ; WriteRAM
    dw $D9E5  ; RAM $D9E5
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3A_Script01
; ---------------------------------------------------------------------------
Map3A_Script01:
    dw $0529  ; Text $0529: "$49:$46E4 *:Squeak squeak! Strike!"
    dw $FF5A  ; Cmd5A
    dw $007D
    dw $FF07  ; InitDialogMode
    dw $052A  ; Text $052A: "$49:$4700 *:Good lord, You're good!"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0105  ; Text $0105: "$43:$4FE2 *:Its the principal of the // school."
    dw $FF1C  ; CompareRAM
    dw $1506
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $052B  ; Text $052B: "$49:$471C Watabou:Good work reading // SkyDragon's"
    dw $FF1C  ; CompareRAM
    dw $0406  ; Text $0406: "$21:$4411 *:My StoneMan can use Ahhh! // *:Boy mon"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF48  ; Cmd48
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $003A  ; Text $003A: "$42:$5ED1 [HERO] looked into the jar."
    dw $FF03  ; SetEventFlag
    dw $001A  ; Text $001A: "$42:$4C3F *:I see....."
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D96D  ; RAM $D96D
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D980  ; RAM $D980
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF00  ; BranchIfFlagClear
    dw $001C  ; Text $001C: "$42:$4C6E [HERO] picked up an Herb."
    dw Bank0E_ScriptAddr_60BE          ; -> branch target
    dw $FF12  ; WriteRAM
    dw $D96D  ; RAM $D96D
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
Bank0E_ScriptAddr_60BE:
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3A_Script02
; ---------------------------------------------------------------------------
Map3A_Script02:
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "$42:$6E72 *:Hale was the cherished pet of // the K"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $000F  ; Text $000F: "$42:$48B2 *:Oh, you must be the master. // You mus"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF12  ; WriteRAM
    dw $D9E5  ; RAM $D9E5
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF0F  ; SetScreenScroll
    dw $003A  ; Text $003A: "$42:$5ED1 [HERO] looked into the jar."
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $0078
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3A_Script03
; ---------------------------------------------------------------------------
Map3A_Script03:
    dw $FF10  ; NPCAnimStart
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0078
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3A_Script04
; ---------------------------------------------------------------------------
Map3A_Script04:
    dw $FF10  ; NPCAnimStart
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3A_Script05
; ---------------------------------------------------------------------------
Map3A_Script05:
    dw $FF10  ; NPCAnimStart
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3A_Script06
; ---------------------------------------------------------------------------
Map3A_Script06:
    dw $FF10  ; NPCAnimStart
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0078
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3A_Script07
; ---------------------------------------------------------------------------
Map3A_Script07:
    dw $FF10  ; NPCAnimStart
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3A_Script08
; ---------------------------------------------------------------------------
Map3A_Script08:
    dw $FF10  ; NPCAnimStart
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0038  ; Text $0038: "$42:$5E08 *:I heard that Pulio let the // monsters"
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
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
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
    dw $052C  ; Text $052C: "$49:$47A5 *:Look at my cool steps!"
    dw $FF03  ; SetEventFlag
    dw $00CE
    dw $FFFF  ; END

Bank0E_ScriptAddr_6170:
    dw $052D  ; Text $052D: "$49:$47C1 *:Why don't you dance with me?"
    dw $FF03  ; SetEventFlag
    dw $00CF
    dw $FF5A  ; Cmd5A
    dw $007B
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $052F  ; Text $052F: "$49:$481D *:You're a great dancer!"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0405  ; Text $0405: "$21:$43D8 *:...fine. If you change your // mind, l"
    dw $FF1C  ; CompareRAM
    dw $1502
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $0530  ; Text $0530: "$49:$4838 *:Did you enjoy dancing? Well, // let's "
    dw $FF1C  ; CompareRAM
    dw $0402  ; Text $0402: "$21:$4248 *:You defeated me. I didn't even have //"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $003B  ; Text $003B: "$42:$5EEB [HERO] looked into the jar. // The jar i"
    dw $FF03  ; SetEventFlag
    dw $001C  ; Text $001C: "$42:$4C6E [HERO] picked up an Herb."
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D96D  ; RAM $D96D
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D981  ; RAM $D981
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF00  ; BranchIfFlagClear
    dw $001A  ; Text $001A: "$42:$4C3F *:I see....."
    dw $6222
    dw $FF12  ; WriteRAM
    dw $D96D  ; RAM $D96D
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

Bank0E_ScriptAddr_622E:
    dw $052E  ; Text $052E: "$49:$47E2 *:You came again to dance with me? // Re"
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
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF01  ; BranchIfFlagSet
    dw $0077
    dw Bank0E_ScriptAddr_627C          ; -> branch target
    dw $FF02  ; ClearEventFlag
    dw $006F  ; Text $006F: "$42:$7C16 *:Treats! BeefJerky, // PorkChop, Rib. /"
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
    dw $0102  ; Text $0102: "$43:$4EEE *:Hm.. It doesn't listen to me much. // "
    dw $4B4A
    dw $5AD8
    dw $D95B  ; RAM $D95B
Bank0E_ScriptAddr_6296:
    dw $0110  ; Text $0110: "$43:$5375 *:Oh, welcome Mas...ahem. // I am the Me"
    dw $4B4A
    dw $5AD8
    dw $D95B  ; RAM $D95B
Bank0E_ScriptAddr_629E:
    dw $014C  ; Text $014C: "$43:$6B82 *:The Room of Villager & // Talisman is "
    dw $4B4A
    dw $5AD8
    dw $D95B  ; RAM $D95B
Bank0E_ScriptAddr_62A6:
    dw $00C6  ; Text $00C6: "$1A:$56D6 *:I know I'm careless but // I do help m"
    dw $4B4A
    dw $5AD8
    dw $D95B  ; RAM $D95B
Bank0E_ScriptAddr_62AE:
    dw $010E  ; Text $010E: "$43:$5294 *:What the heck is an onigiri? // Why ca"
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
    dw $014C  ; Text $014C: "$43:$6B82 *:The Room of Villager & // Talisman is "
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
    dw $02A2  ; Text $02A2: "$45:$6AA0 [HERO] looked at the egg. // A monster h"
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_627E          ; -> branch target
    dw $FF06  ; IncrementCounter
    dw $FF03  ; SetEventFlag
    dw $006F  ; Text $006F: "$42:$7C16 *:Treats! BeefJerky, // PorkChop, Rib. /"
    dw $FF03  ; SetEventFlag
    dw $0070
    dw $FF05  ; TriggerBattle
    dw $015D  ; Text $015D: "$43:$7229 [HERO] looked into the jar. // But there"
    dw $FFFF  ; END

Bank0E_ScriptAddr_631C:
    dw $02A3  ; Text $02A3: "$45:$6AD6 [HERO] looked at the egg. // The egg is "
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
    dw $02A2  ; Text $02A2: "$45:$6AA0 [HERO] looked at the egg. // A monster h"
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_6286          ; -> branch target
    dw $FF06  ; IncrementCounter
    dw $FF03  ; SetEventFlag
    dw $006F  ; Text $006F: "$42:$7C16 *:Treats! BeefJerky, // PorkChop, Rib. /"
    dw $FF03  ; SetEventFlag
    dw $0071
    dw $FF05  ; TriggerBattle
    dw $015D  ; Text $015D: "$43:$7229 [HERO] looked into the jar. // But there"
    dw $FFFF  ; END

Bank0E_ScriptAddr_6342:
    dw $02A3  ; Text $02A3: "$45:$6AD6 [HERO] looked at the egg. // The egg is "
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
    dw $02A2  ; Text $02A2: "$45:$6AA0 [HERO] looked at the egg. // A monster h"
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_628E          ; -> branch target
    dw $FF06  ; IncrementCounter
    dw $FF03  ; SetEventFlag
    dw $006F  ; Text $006F: "$42:$7C16 *:Treats! BeefJerky, // PorkChop, Rib. /"
    dw $FF03  ; SetEventFlag
    dw $0072
    dw $FF05  ; TriggerBattle
    dw $015D  ; Text $015D: "$43:$7229 [HERO] looked into the jar. // But there"
    dw $FFFF  ; END

Bank0E_ScriptAddr_6368:
    dw $02A3  ; Text $02A3: "$45:$6AD6 [HERO] looked at the egg. // The egg is "
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
    dw $02A2  ; Text $02A2: "$45:$6AA0 [HERO] looked at the egg. // A monster h"
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_6296          ; -> branch target
    dw $FF06  ; IncrementCounter
    dw $FF03  ; SetEventFlag
    dw $006F  ; Text $006F: "$42:$7C16 *:Treats! BeefJerky, // PorkChop, Rib. /"
    dw $FF03  ; SetEventFlag
    dw $0073
    dw $FF05  ; TriggerBattle
    dw $015D  ; Text $015D: "$43:$7229 [HERO] looked into the jar. // But there"
    dw $FFFF  ; END

Bank0E_ScriptAddr_638E:
    dw $02A3  ; Text $02A3: "$45:$6AD6 [HERO] looked at the egg. // The egg is "
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
    dw $02A2  ; Text $02A2: "$45:$6AA0 [HERO] looked at the egg. // A monster h"
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_629E          ; -> branch target
    dw $FF06  ; IncrementCounter
    dw $FF03  ; SetEventFlag
    dw $006F  ; Text $006F: "$42:$7C16 *:Treats! BeefJerky, // PorkChop, Rib. /"
    dw $FF03  ; SetEventFlag
    dw $0074
    dw $FF05  ; TriggerBattle
    dw $015D  ; Text $015D: "$43:$7229 [HERO] looked into the jar. // But there"
    dw $FFFF  ; END

Bank0E_ScriptAddr_63B4:
    dw $02A3  ; Text $02A3: "$45:$6AD6 [HERO] looked at the egg. // The egg is "
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
    dw $02A2  ; Text $02A2: "$45:$6AA0 [HERO] looked at the egg. // A monster h"
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_62A6          ; -> branch target
    dw $FF06  ; IncrementCounter
    dw $FF03  ; SetEventFlag
    dw $006F  ; Text $006F: "$42:$7C16 *:Treats! BeefJerky, // PorkChop, Rib. /"
    dw $FF03  ; SetEventFlag
    dw $0075
    dw $FF05  ; TriggerBattle
    dw $015D  ; Text $015D: "$43:$7229 [HERO] looked into the jar. // But there"
    dw $FFFF  ; END

Bank0E_ScriptAddr_63DA:
    dw $02A3  ; Text $02A3: "$45:$6AD6 [HERO] looked at the egg. // The egg is "
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
    dw $02A2  ; Text $02A2: "$45:$6AA0 [HERO] looked at the egg. // A monster h"
    dw $FF24  ; Cmd24
    dw Bank0E_ScriptAddr_62AE          ; -> branch target
    dw $FF06  ; IncrementCounter
    dw $FF03  ; SetEventFlag
    dw $006F  ; Text $006F: "$42:$7C16 *:Treats! BeefJerky, // PorkChop, Rib. /"
    dw $FF03  ; SetEventFlag
    dw $0076
    dw $FF05  ; TriggerBattle
    dw $015D  ; Text $015D: "$43:$7229 [HERO] looked into the jar. // But there"
    dw $FFFF  ; END

Bank0E_ScriptAddr_6400:
    dw $02A3  ; Text $02A3: "$45:$6AD6 [HERO] looked at the egg. // The egg is "
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
    dw $006F  ; Text $006F: "$42:$7C16 *:Treats! BeefJerky, // PorkChop, Rib. /"
    dw Bank0E_ScriptAddr_641A          ; -> branch target
    dw $029E  ; Text $029E: "$45:$68FF *:It's my wish that... // *:my family in"
    dw $FFFF  ; END

Bank0E_ScriptAddr_641A:
    dw $029F  ; Text $029F: "$45:$6977 *:That my family in this world // prospe"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF0  ; Cmd$F0
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF1C  ; CompareRAM
    dw $0100  ; Text $0100: "$43:$4DEC [HERO] looked into the jar. // An old la"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF10  ; NPCAnimStart
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FF0B  ; NPCMoveY
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0030  ; Text $0030: "$42:$5B00 *:Pulio from the farm is goofy but // a "
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFE0  ; Cmd$E0
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF0  ; Cmd$F0
    dw $FF0A  ; NPCMoveX
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF0  ; Cmd$F0
    dw $FF0A  ; NPCMoveX
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF0  ; Cmd$F0
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF1C  ; CompareRAM
    dw $0101  ; Text $0101: "$43:$4E4F [HERO] looked into the jar. // A piece o"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF1C  ; CompareRAM
    dw $0101  ; Text $0101: "$43:$4E4F [HERO] looked into the jar. // A piece o"
    dw $FF19  ; FadeEffect
    dw $FF1C  ; CompareRAM
    dw $0101  ; Text $0101: "$43:$4E4F [HERO] looked into the jar. // A piece o"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF1C  ; CompareRAM
    dw $0103  ; Text $0103: "$43:$4F3C *:Hi Ho Hi Ho. // *:Sigh.. I'm starving."
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF3C  ; Cmd3C
    dw $FF07  ; InitDialogMode
    dw $02A0  ; Text $02A0: "$45:$6A11 *:Shoot! Not here either!"
    dw $FF1C  ; CompareRAM
    dw $0401  ; Text $0401: "$21:$420F *:I think I'm gonna quit // staying up a"
    dw $FF19  ; FadeEffect
    dw $FF12  ; WriteRAM
    dw $C8B2  ; RAM $C8B2
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF21  ; TriggerBattle2
    dw $0064  ; Text $0064: "$42:$756F *:Oh [HERO], it's you. // I am getting o"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $00D2
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $C89B  ; RAM $C89B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
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
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF0A  ; NPCMoveX
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF0  ; Cmd$F0
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF0A  ; NPCMoveX
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF0  ; Cmd$F0
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF3D  ; Cmd3D
    dw $FF07  ; InitDialogMode
    dw $02A1  ; Text $02A1: "$45:$6A2E *:Who are you? You're a monster // maste"
    dw $FF0A  ; NPCMoveX
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFF0  ; Cmd$F0
    dw $FF0B  ; NPCMoveY
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF03  ; SetEventFlag
    dw $0077
    dw $FF12  ; WriteRAM
    dw $D982  ; RAM $D982
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFFF  ; END

Bank0E_ScriptAddr_6564:
    dw $02A4  ; Text $02A4: "$45:$6B05 *:Arrrgh! How dare you crack all my // e"
    dw $FF03  ; SetEventFlag
    dw $0078
    dw $FF5A  ; Cmd5A
    dw $0065  ; Text $0065: "$42:$75F1 *:Once I picked up a TinyMedal, // *:bac"
    dw $FF07  ; InitDialogMode
    dw $02A6  ; Text $02A6: "$45:$6BA7 *:That sword man looked like you..."
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0204  ; Text $0204: "$1B:$444A *:Oh well, nobody's here. // I wanna hav"
    dw $FF1C  ; CompareRAM
    dw $1602
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $02A7  ; Text $02A7: "$45:$6BCE Watabou:Those eggs were the // reason th"
    dw $FF1C  ; CompareRAM
    dw $0402  ; Text $0402: "$21:$4248 *:You defeated me. I didn't even have //"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF4A  ; Cmd4A
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $003C  ; Text $003C: "$42:$5F28 *:Hey you! You came here to // steal my "
    dw $FF03  ; SetEventFlag
    dw $001D  ; Text $001D: "$42:$4C85 [HERO] found an Herb. // But cannot carr"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D933  ; RAM $D933
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D934  ; RAM $D934
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D935  ; RAM $D935
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D936  ; RAM $D936
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D937  ; RAM $D937
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D938  ; RAM $D938
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D93F  ; RAM $D93F
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D941  ; RAM $D941
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D942  ; RAM $D942
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D943  ; RAM $D943
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D944  ; RAM $D944
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $D966  ; RAM $D966
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D967  ; RAM $D967
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D96C  ; RAM $D96C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D982  ; RAM $D982
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

Bank0E_ScriptAddr_665C:
    dw $02A5  ; Text $02A5: "$45:$6B6F *:It's you again! You'll pay for // what"
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
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3D_Script02
; ---------------------------------------------------------------------------
Map3D_Script02:
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $00A8  ; Text $00A8: "$1A:$4F33 *:Let me tell you something useful. // T"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $0048  ; Text $0048: "$42:$6612 Pulio:Your Majesty please forgive me! //"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFF0  ; Cmd$F0
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF49  ; Cmd49
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0305  ; Text $0305: "$46:$42D5 *:You again!? I'm really gonna // get yo"
    dw $FF1C  ; CompareRAM
    dw $1504
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_6718          ; -> branch target
; ---------------------------------------------------------------------------
; Map3D_Script01
; ---------------------------------------------------------------------------
Map3D_Script01:
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $0048  ; Text $0048: "$42:$6612 Pulio:Your Majesty please forgive me! //"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $0048  ; Text $0048: "$42:$6612 Pulio:Your Majesty please forgive me! //"
    dw $FF0D  ; WriteNPCByte
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $0048  ; Text $0048: "$42:$6612 Pulio:Your Majesty please forgive me! //"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0018  ; Text $0018: "$42:$4BF7 *:This is the castle of // GreatTree."
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FF0A  ; NPCMoveX
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF47  ; Cmd47
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF4A  ; Cmd4A
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0304  ; Text $0304: "$46:$4292 *:Eeek! I cannot stand you! // *:I'm gon"
    dw $FF1C  ; CompareRAM
    dw $1604
Bank0E_ScriptAddr_6718:
    dw $FF19  ; FadeEffect
    dw $FF48  ; Cmd48
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF09  ; SetDelay
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF1D  ; LockMovement
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FFD0  ; Cmd$D0
    dw $FF1B  ; MultiRAMWrite
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FFD0  ; Cmd$D0
    dw $FF19  ; FadeEffect
    dw $FF1E  ; UnlockMovement
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF1C  ; CompareRAM
    dw $0405  ; Text $0405: "$21:$43D8 *:...fine. If you change your // mind, l"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF21  ; TriggerBattle2
    dw $0055  ; Text $0055: "$42:$6E72 *:Hale was the cherished pet of // the K"
    dw $FF22  ; Cmd22
    dw $FF1B  ; MultiRAMWrite
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0010  ; Text $0010: "$42:$49CF *:This kingdom is created inside // a bi"
    dw $FF19  ; FadeEffect
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF21  ; TriggerBattle2
    dw $0066  ; Text $0066: "$42:$7779 *:Would you like to see the list of // T"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0B  ; NPCMoveY
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FFF8  ; Cmd$F8
    dw $FF0D  ; WriteNPCByte
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF07  ; InitDialogMode
    dw $0531  ; Text $0531: "$49:$486D There is a voice coming from out // of n"
    dw $0532  ; Text $0532: "$49:$48A3 *:Hello...the traveler over // there... "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0E_ScriptAddr_679C          ; -> branch target
    dw $0533  ; Text $0533: "$49:$4957 *:Now, wait there."
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_67AE          ; -> branch target
Bank0E_ScriptAddr_679C:
    dw $0534  ; Text $0534: "$49:$496C *:Then, would you like me to send // you"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0E_ScriptAddr_67AC          ; -> branch target
    dw $0535  ; Text $0535: "$49:$49B2 *:It was actually a monster that // fell"
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_67AE          ; -> branch target
Bank0E_ScriptAddr_67AC:
    dw $0535  ; Text $0535: "$49:$49B2 *:It was actually a monster that // fell"
Bank0E_ScriptAddr_67AE:
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF1C  ; CompareRAM
    dw $0802  ; Text $0802: "$3F:$469B *:Oh my! So, this is // the GoldSlime! /"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF07  ; InitDialogMode
    dw $0536  ; Text $0536: "$49:$4A29 *:Was it this meat that fell in the // s"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0E_ScriptAddr_67CE          ; -> branch target
    dw $0537  ; Text $0537: "$49:$4A5D *:...you're a liar. // *:I'll give your "
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_68AE          ; -> branch target
Bank0E_ScriptAddr_67CE:
    dw $0538  ; Text $0538: "$49:$4AA7 *:I see. Now, wait a moment for me."
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF1C  ; CompareRAM
    dw $0D02
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0D  ; WriteNPCByte
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
    dw $FF1C  ; CompareRAM
    dw $0803  ; Text $0803: "$3F:$4720 *:If you show me a GoldSlime, // *:I'll "
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF07  ; InitDialogMode
    dw $0539  ; Text $0539: "$49:$4ACE *:Now, is this the old guy who // fell i"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0E_ScriptAddr_6802          ; -> branch target
    dw $053A  ; Text $053A: "$49:$4B08 *:...you're a liar. // *:I'll give your "
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_68AE          ; -> branch target
Bank0E_ScriptAddr_6802:
    dw $053B  ; Text $053B: "$49:$4B52 *:I see. Now,wait a minute for me."
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF1C  ; CompareRAM
    dw $0D03
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0080  ; Text $0080: "$1A:$4628 *:I don't care how strong the enemies //"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $001A  ; Text $001A: "$42:$4C3F *:I see....."
    dw $0028  ; Text $0028: "$42:$5474 :People who understand monster // talk a"
    dw $FF1C  ; CompareRAM
    dw $0801  ; Text $0801: "$3F:$45DC *:Oh, I see. I heard about you // from m"
    dw $FF19  ; FadeEffect
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF3F  ; Cmd3F
    dw $FF07  ; InitDialogMode
    dw $053C  ; Text $053C: "$49:$4B78 *:Now is this the [INS 00], the // monst"
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw Bank0E_ScriptAddr_6840          ; -> branch target
    dw $053D  ; Text $053D: "$49:$4BBA *:I don't understand you... // *:I'll gi"
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_68AE          ; -> branch target
Bank0E_ScriptAddr_6840:
    dw $053E  ; Text $053E: "$49:$4C3D *:You're honest. I'll give you // back t"
    dw $FF09  ; SetDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF05  ; TriggerBattle
    dw $007F
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $003D  ; Text $003D: "$42:$5F5F *:C'mon, I'll give you a beating. // Sni"
    dw $FF03  ; SetEventFlag
    dw $001E  ; Text $001E: "$42:$4CEA [HERO] opened a treasure chest!"
    dw $FF07  ; InitDialogMode
    dw $053F  ; Text $053F: "$49:$4CEE *:You did well. Please go back to // you"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D94C  ; RAM $D94C
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF12  ; WriteRAM
    dw $D983  ; RAM $D983
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF00  ; BranchIfFlagClear
    dw $002E  ; Text $002E: "$42:$58EC *:Here it is again. // *:The Starry Nigh"
    dw Bank0E_ScriptAddr_6890          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $010C  ; Text $010C: "$43:$526F BeBe:Boo Baa Boo Baa."
    dw Bank0E_ScriptAddr_68A4          ; -> branch target
Bank0E_ScriptAddr_6890:
    dw $FF01  ; BranchIfFlagSet
    dw $010C  ; Text $010C: "$43:$526F BeBe:Boo Baa Boo Baa."
    dw Bank0E_ScriptAddr_689A          ; -> branch target
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_68AE          ; -> branch target
Bank0E_ScriptAddr_689A:
    dw $FF12  ; WriteRAM
    dw $D94C  ; RAM $D94C
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_68AE          ; -> branch target
Bank0E_ScriptAddr_68A4:
    dw $FF12  ; WriteRAM
    dw $D94C  ; RAM $D94C
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF14  ; ClearGameFlags
    dw Bank0E_ScriptAddr_68AE          ; -> branch target
Bank0E_ScriptAddr_68AE:
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF0D  ; WriteNPCByte
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0040  ; Text $0040: "$42:$6159 *:I'm Slio. I am the grandson // of Gran"
    dw $FF12  ; WriteRAM
    dw $C8ED  ; RAM $C8ED
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3D_Script03
; ---------------------------------------------------------------------------
Map3D_Script03:
    dw $0531  ; Text $0531: "$49:$486D There is a voice coming from out // of n"
    dw $0540  ; Text $0540: "$49:$4D2B *:Oh, it's you again. Would you // like "
    dw $FF15  ; PlaySE
    dw $C83C  ; RAM $C83C
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw Bank0E_ScriptAddr_68EE          ; -> branch target
    dw $0542  ; Text $0542: "$49:$4D8B *:Now so long..."
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

Bank0E_ScriptAddr_68EE:
    dw $0541  ; Text $0541: "$49:$4D75 *:Take your time."
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
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FFFF  ; END

; ---------------------------------------------------------------------------
; Map3E_Script01
; ---------------------------------------------------------------------------
Map3E_Script01:
    dw $FF01  ; BranchIfFlagSet
    dw $00D2
    dw Bank0E_ScriptAddr_69DE          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00D1  ; Text $00D1: "$1A:$59B0 *:Huh? it's okay, let's heal // for the "
    dw Bank0E_ScriptAddr_6928          ; -> branch target
    dw $FF01  ; BranchIfFlagSet
    dw $00D0
    dw Bank0E_ScriptAddr_6920          ; -> branch target
    dw $0543  ; Text $0543: "$49:$4DA0 *:Comrade! Now is the time // for us to "
    dw $FF03  ; SetEventFlag
    dw $00D0
    dw $FFFF  ; END

Bank0E_ScriptAddr_6920:
    dw $0544  ; Text $0544: "$49:$4E49 *:I'll promise you, comrade! // *:A worl"
    dw $FF03  ; SetEventFlag
    dw $00D1  ; Text $00D1: "$1A:$59B0 *:Huh? it's okay, let's heal // for the "
    dw $FFFF  ; END

Bank0E_ScriptAddr_6928:
    dw $0545  ; Text $0545: "$49:$4EB9 *:Hm!? I don't know why // but I feel so"
    dw $FF03  ; SetEventFlag
    dw $00D2
    dw $FF5A  ; Cmd5A
    dw $0093
    dw $FF07  ; InitDialogMode
    dw $0547  ; Text $0547: "$49:$4FC7 *:I demand one sirloin steak // a day!"
    dw $FF09  ; SetDelay
    dw $0008  ; Text $0008: "$42:$44BA *:Are you Milayou? // *:Hm, You don't lo"
    dw $FF0D  ; WriteNPCByte
    dw $0002  ; Text $0002: "$42:$4259 Terry looked at a stuffed animal. // Som"
    dw $0005  ; Text $0005: "$42:$43B0 Terry looked at the bookshelf. // :Diary"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF0D  ; WriteNPCByte
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF13  ; SetGameFlags
    dw $D8E3  ; RAM $D8E3
    dw $0304  ; Text $0304: "$46:$4292 *:Eeek! I cannot stand you! // *:I'm gon"
    dw $FF1C  ; CompareRAM
    dw $1501
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF07  ; InitDialogMode
    dw $0844
    dw $FF1C  ; CompareRAM
    dw $0401  ; Text $0401: "$21:$420F *:I think I'm gonna quit // staying up a"
    dw $FF19  ; FadeEffect
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF4A  ; Cmd4A
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF48  ; Cmd48
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0004  ; Text $0004: "$42:$4323 Terry looked at the bookshelf. // :A Fai"
    dw $FF49  ; Cmd49
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF4D  ; SetLongDelay
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF47  ; Cmd47
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF08  ; NOP
    dw $FF12  ; WriteRAM
    dw $D9E3  ; RAM $D9E3
    dw $003E  ; Text $003E: "$42:$6007 *:You came here to get monsters?"
    dw $FF03  ; SetEventFlag
    dw $001F  ; Text $001F: "$42:$4D08 *:This is the Kingdom of // GreatTree!"
    dw $FF12  ; WriteRAM
    dw $D92B  ; RAM $D92B
    dw $0007  ; Text $0007: "$42:$4473 [SOUND 60]Terry looked in the dresser. /"
    dw $FF12  ; WriteRAM
    dw $D96E  ; RAM $D96E
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF12  ; WriteRAM
    dw $D984  ; RAM $D984
    dw $0001  ; Text $0001: "$42:$4244 Milayou:... zzz."
    dw $FF00  ; BranchIfFlagClear
    dw $0020  ; Text $0020: "$42:$4D34 *:Welcome! I am the King of this // king"
    dw $69D2
    dw $FF12  ; WriteRAM
    dw $D96E  ; RAM $D96E
    dw $0003  ; Text $0003: "$42:$42D0 Terry looked in front of him. // A flame"
    dw $FF06  ; IncrementCounter
    dw $FF3B  ; Cmd3B
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $00E8  ; Text $00E8: "$43:$46B7 *:The last battle in G class is with // "
    dw $0058  ; Text $0058: "$42:$6FFE *:How do you do. I'm Hale. // *:I know y"
    dw $FFFF  ; END

Bank0E_ScriptAddr_69DE:
    dw $0546  ; Text $0546: "$49:$4F36 *:Sirloin steak is totally yummy! // The"
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
    dw $0006  ; Text $0006: "$42:$4431 [SOUND 60]Terry looked in the dresser. /"
    dw $FF0D  ; WriteNPCByte
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
    dw $FF90  ; Cmd$90
    dw $0000  ; Text $0000: "$42:$4142 Milayou:Terry! Wait! It's time // for be"
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
