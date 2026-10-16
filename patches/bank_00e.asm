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
    dw $6AE2                ; map type $00: another bank's — filler, never read here
    dw $6AE2                ; map type $01: another bank's — filler, never read here
    dw $6AE2                ; map type $02: another bank's — filler, never read here
    dw $6AE2                ; map type $03: another bank's — filler, never read here
    dw $6AE2                ; map type $04: another bank's — filler, never read here
    dw $6AE2                ; map type $05: another bank's — filler, never read here
    dw $6AE2                ; map type $06: another bank's — filler, never read here
    dw $6AE2                ; map type $07: another bank's — filler, never read here
    dw $6AE2                ; map type $08: another bank's — filler, never read here
    dw $6AE2                ; map type $09: another bank's — filler, never read here
    dw $6AE2                ; map type $0A: another bank's — filler, never read here
    dw $6AE2                ; map type $0B: another bank's — filler, never read here
    dw $6AE2                ; map type $0C: another bank's — filler, never read here
    dw $6AE2                ; map type $0D: another bank's — filler, never read here
    dw $6AE2                ; map type $0E: another bank's — filler, never read here
    dw $6AE2                ; map type $0F: another bank's — filler, never read here
    dw $6AE2                ; map type $10: another bank's — filler, never read here
    dw $6AE2                ; map type $11: another bank's — filler, never read here
    dw $6AE2                ; map type $12: another bank's — filler, never read here
    dw $6AE2                ; map type $13: another bank's — filler, never read here
    dw $6AE2                ; map type $14: another bank's — filler, never read here
    dw $6AE2                ; map type $15: another bank's — filler, never read here
    dw $6AE2                ; map type $16: another bank's — filler, never read here
    dw $6AE2                ; map type $17: another bank's — filler, never read here
    dw $6AE2                ; map type $18: another bank's — filler, never read here
    dw $6AE2                ; map type $19: another bank's — filler, never read here
    dw $6AE2                ; map type $1A: another bank's — filler, never read here
    dw $6AE2                ; map type $1B: another bank's — filler, never read here
    dw $6AE2                ; map type $1C: another bank's — filler, never read here
    dw $6AE2                ; map type $1D: another bank's — filler, never read here
    dw $6AE2                ; map type $1E: another bank's — filler, never read here
    dw $6AE2                ; map type $1F: another bank's — filler, never read here
    dw Map20_ScriptPtrTable ; map type $20: Castle (unused copy 6)
    dw Map21_ScriptPtrTable ; map type $21: Castle (unused copy 7)
    dw Map22_ScriptPtrTable ; map type $22: Castle (unused copy 8)
    dw Map23_ScriptPtrTable ; map type $23: Room of Beginning
    dw RoomVillagerTalisman_ScriptPtrTable ; map type $24: Room: Villager/Talisman
    dw RoomMemoriesBewilder_ScriptPtrTable ; map type $25: Room: Memories/Bewilder
    dw RoomPeaceBravery_ScriptPtrTable ; map type $26: Room: Peace/Bravery
    dw Map27_ScriptPtrTable ; map type $27: Room: Strength/Anger
    dw RoomJoyWisdom_ScriptPtrTable ; map type $28: Room: Joy/Wisdom
    dw RoomHappinessTemptation_ScriptPtrTable ; map type $29: Room: Happiness/Temptation
    dw RoomLabyrinthJudgment_ScriptPtrTable ; map type $2A: Room: Labyrinth/Judgment
    dw Map2B_ScriptPtrTable ; map type $2B: Room: Reflection
    dw RoomAmbitionDemolition_ScriptPtrTable ; map type $2C: Room: Ambition/Demolition
    dw RoomMastermindControl_ScriptPtrTable ; map type $2D: Room: Mastermind/Control
    dw Map2E_ScriptPtrTable ; map type $2E: Room: Extinction/Sleep
    dw Map2F_ScriptPtrTable ; map type $2F: Intro Bedroom (2-screen, crashes)
    dw BossBeginning_ScriptPtrTable ; map type $30: Boss: Beginning (Healer)
    dw BossVillager_ScriptPtrTable ; map type $31: Boss: Villager (Dragon)
    dw BossTalisman_ScriptPtrTable ; map type $32: Boss: Talisman (Golem)
    dw BossMemories_ScriptPtrTable ; map type $33: Boss: Memories (MadCat)
    dw BossBewilder_ScriptPtrTable ; map type $34: Boss: Bewilder (FaceTree)
    dw Map35_ScriptPtrTable ; map type $35: Boss: Bazaar (MadKnight)
    dw BossPeace_ScriptPtrTable ; map type $36: Boss: Peace (FangSlime)
    dw BossBravery_ScriptPtrTable ; map type $37: Boss: Bravery (BigEye)
    dw Map38_ScriptPtrTable ; map type $38: Boss: Well (Gigantes)
    dw Map39_ScriptPtrTable ; map type $39: Boss: Strength (StoneMan)
    dw Map3A_ScriptPtrTable ; map type $3A: Boss: Wisdom (SkyDragon)
    dw Map3B_ScriptPtrTable ; map type $3B: Boss: Joy (FunkyBird)
    dw Map3C_ScriptPtrTable ; map type $3C: Boss: Anger (BattleRex)
    dw Map3D_ScriptPtrTable ; map type $3D: Boss: Arena Left (Digster)
    dw Map3E_ScriptPtrTable ; map type $3E: Boss: Happiness (Jamirus)
    dw Map3F_ScriptPtrTable ; map type $3F: Boss: Temptation (Servant)
; ---------------------------------------------------------------------------
; Map20 Per-Script Table (map_type=$20, 1 scripts)
; ---------------------------------------------------------------------------
Map20_ScriptPtrTable:
    dw Map20_Script00       ; script 0
; ---------------------------------------------------------------------------
; Map20_Script00
; ---------------------------------------------------------------------------
Map20_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map21 Per-Script Table (map_type=$21, 1 scripts)
; ---------------------------------------------------------------------------
Map21_ScriptPtrTable:
    dw Map21_Script00       ; script 0
; ---------------------------------------------------------------------------
; Map21_Script00
; ---------------------------------------------------------------------------
Map21_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map22 Per-Script Table (map_type=$22, 1 scripts)
; ---------------------------------------------------------------------------
Map22_ScriptPtrTable:
    dw Map22_Script00       ; script 0
; ---------------------------------------------------------------------------
; Map22_Script00
; ---------------------------------------------------------------------------
Map22_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map23 Per-Script Table (map_type=$23, 2 scripts)
; ---------------------------------------------------------------------------
Map23_ScriptPtrTable:
    dw Map23_Script00       ; script 0
    dw Map23_Script01       ; script 1
; ---------------------------------------------------------------------------
; Map23_Script00
; ---------------------------------------------------------------------------
Map23_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map23_Script01
; ---------------------------------------------------------------------------
Map23_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $0009 is set → Bank0E_ScriptAddr_4256
    dw $0009                ;   flag
    dw Bank0E_ScriptAddr_4256 ;   target
    dw $0057                ; text $0057: "*:We are at the Chamber of Travelers' Ga…"
    dw $FFFF                ; END

Bank0E_ScriptAddr_4256:
    dw $011F                ; text $011F: "*:You are at the Room of Beginning. *:Th…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; RoomVillagerTalisman Per-Script Table (map_type=$24, 2 scripts)
; ---------------------------------------------------------------------------
RoomVillagerTalisman_ScriptPtrTable:
    dw RoomVillagerTalisman_Script00 ; script 0
    dw RoomVillagerTalisman_Script01 ; script 1
; ---------------------------------------------------------------------------
; RoomVillagerTalisman_Script00
; ---------------------------------------------------------------------------
RoomVillagerTalisman_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; RoomVillagerTalisman_Script01
; ---------------------------------------------------------------------------
RoomVillagerTalisman_Script01:
    dw $01A1                ; text $01A1: "*:Here's the Room of Villager & Talisman…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; RoomMemoriesBewilder Per-Script Table (map_type=$25, 2 scripts)
; ---------------------------------------------------------------------------
RoomMemoriesBewilder_ScriptPtrTable:
    dw RoomMemoriesBewilder_Script00 ; script 0
    dw RoomMemoriesBewilder_Script01 ; script 1
; ---------------------------------------------------------------------------
; RoomMemoriesBewilder_Script00
; ---------------------------------------------------------------------------
RoomMemoriesBewilder_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; RoomMemoriesBewilder_Script01
; ---------------------------------------------------------------------------
RoomMemoriesBewilder_Script01:
    dw $01E1                ; text $01E1: "*:This is the room of Memories & Bewilde…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; RoomPeaceBravery Per-Script Table (map_type=$26, 2 scripts)
; ---------------------------------------------------------------------------
RoomPeaceBravery_ScriptPtrTable:
    dw RoomPeaceBravery_Script00 ; script 0
    dw RoomPeaceBravery_Script01 ; script 1
; ---------------------------------------------------------------------------
; RoomPeaceBravery_Script00
; ---------------------------------------------------------------------------
RoomPeaceBravery_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; RoomPeaceBravery_Script01
; ---------------------------------------------------------------------------
RoomPeaceBravery_Script01:
    dw $026E                ; text $026E: "*:This is the Room of Peace & Bravery. *…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map27 Per-Script Table (map_type=$27, 3 scripts)
; ---------------------------------------------------------------------------
Map27_ScriptPtrTable:
    dw Map27_Script00       ; script 0
    dw Map27_Script01       ; script 1
    dw Map27_Script02       ; script 2
; ---------------------------------------------------------------------------
; Map27_Script00
; ---------------------------------------------------------------------------
Map27_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map27_Script01
; ---------------------------------------------------------------------------
Map27_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0E_ScriptAddr_4294
    dw $00F1                ;   flag
    dw Bank0E_ScriptAddr_4294 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0E_ScriptAddr_4290
    dw $001D                ;   flag
    dw Bank0E_ScriptAddr_4290 ;   target
    dw $029C                ; text $029C: "*:[HERO], here is the Room of Strength &…"
    dw $FFFF                ; END

Bank0E_ScriptAddr_4290:
    dw $032E                ; text $032E: "*:[HERO]! Thanks for saving me. *:You're…"
    dw $FFFF                ; END

Bank0E_ScriptAddr_4294:
    dw $082A                ; text $082A: "*:Oh my, it is Master [HERO]. Welcome to…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map27_Script02
; ---------------------------------------------------------------------------
Map27_Script02:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0E_ScriptAddr_42AC
    dw $00F1                ;   flag
    dw Bank0E_ScriptAddr_42AC ;   target
    dw $FF01                ; $01 if_flag_set: If flag $001D is set → Bank0E_ScriptAddr_42A8
    dw $001D                ;   flag
    dw Bank0E_ScriptAddr_42A8 ;   target
    dw $029D                ; text $029D: "*:Monsters are flooding out from the Gat…"
    dw $FFFF                ; END

Bank0E_ScriptAddr_42A8:
    dw $032F                ; text $032F: "*:Thank you very much [HERO]!"
    dw $FFFF                ; END

Bank0E_ScriptAddr_42AC:
    dw $082B                ; text $082B: "*:Oh, [HERO], Master [HERO] is here!"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; RoomJoyWisdom Per-Script Table (map_type=$28, 2 scripts)
; ---------------------------------------------------------------------------
RoomJoyWisdom_ScriptPtrTable:
    dw RoomJoyWisdom_Script00 ; script 0
    dw RoomJoyWisdom_Script01 ; script 1
; ---------------------------------------------------------------------------
; RoomJoyWisdom_Script00
; ---------------------------------------------------------------------------
RoomJoyWisdom_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; RoomJoyWisdom_Script01
; ---------------------------------------------------------------------------
RoomJoyWisdom_Script01:
    dw $035D                ; text $035D: "*:You're at the Room of Joy and Wisdom. …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; RoomHappinessTemptation Per-Script Table (map_type=$29, 2 scripts)
; ---------------------------------------------------------------------------
RoomHappinessTemptation_ScriptPtrTable:
    dw RoomHappinessTemptation_Script00 ; script 0
    dw RoomHappinessTemptation_Script01 ; script 1
; ---------------------------------------------------------------------------
; RoomHappinessTemptation_Script00
; ---------------------------------------------------------------------------
RoomHappinessTemptation_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; RoomHappinessTemptation_Script01
; ---------------------------------------------------------------------------
RoomHappinessTemptation_Script01:
    dw $03DD                ; text $03DD: "*:You're in the Room of Happiness & Temp…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; RoomLabyrinthJudgment Per-Script Table (map_type=$2A, 2 scripts)
; ---------------------------------------------------------------------------
RoomLabyrinthJudgment_ScriptPtrTable:
    dw RoomLabyrinthJudgment_Script00 ; script 0
    dw RoomLabyrinthJudgment_Script01 ; script 1
; ---------------------------------------------------------------------------
; RoomLabyrinthJudgment_Script00
; ---------------------------------------------------------------------------
RoomLabyrinthJudgment_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; RoomLabyrinthJudgment_Script01
; ---------------------------------------------------------------------------
RoomLabyrinthJudgment_Script01:
    dw $0408                ; text $0408: "*:You're at the Room of the Labyrinth & …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map2B Per-Script Table (map_type=$2B, 2 scripts)
; ---------------------------------------------------------------------------
Map2B_ScriptPtrTable:
    dw Map2B_Script00       ; script 0
    dw Map2B_Script01       ; script 1
; ---------------------------------------------------------------------------
; Map2B_Script00
; ---------------------------------------------------------------------------
Map2B_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map2B_Script01
; ---------------------------------------------------------------------------
Map2B_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $00F1 is set → Bank0E_ScriptAddr_42F6
    dw $00F1                ;   flag
    dw Bank0E_ScriptAddr_42F6 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0025 is set → Bank0E_ScriptAddr_42F2
    dw $0025                ;   flag
    dw Bank0E_ScriptAddr_42F2 ;   target
    dw $046A                ; text $046A: "*:You're at the Room of Reflection. Plea…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0E_ScriptAddr_42EE  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0E_ScriptAddr_42EE ;   target
    dw $046B                ; text $046B: "*:Actually, nobody has survived the Room…"
    dw $FFFF                ; END

Bank0E_ScriptAddr_42EE:
    dw $046C                ; text $046C: "*:I...I agree with you. I'm sorry to kee…"
    dw $FFFF                ; END

Bank0E_ScriptAddr_42F2:
    dw $04DE                ; text $04DE: "*:[HERO]! You are the first person *:who…"
    dw $FFFF                ; END

Bank0E_ScriptAddr_42F6:
    dw $082C                ; text $082C: "*:Welcome to the Room of Reflection. The…"
    dw $FFFF                ; END

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
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; RoomAmbitionDemolition_Script01
; ---------------------------------------------------------------------------
RoomAmbitionDemolition_Script01:
    dw $082D                ; text $082D: "*:Welcome! *:Go right to the Gate of Dem…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; RoomMastermindControl Per-Script Table (map_type=$2D, 2 scripts)
; ---------------------------------------------------------------------------
RoomMastermindControl_ScriptPtrTable:
    dw RoomMastermindControl_Script00 ; script 0
    dw RoomMastermindControl_Script01 ; script 1
; ---------------------------------------------------------------------------
; RoomMastermindControl_Script00
; ---------------------------------------------------------------------------
RoomMastermindControl_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; RoomMastermindControl_Script01
; ---------------------------------------------------------------------------
RoomMastermindControl_Script01:
    dw $082E                ; text $082E: "*:Welcome! Master! *:Go up for the Gate …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map2E Per-Script Table (map_type=$2E, 2 scripts)
; ---------------------------------------------------------------------------
Map2E_ScriptPtrTable:
    dw Map2E_Script00       ; script 0
    dw Map2E_Script01       ; script 1
; ---------------------------------------------------------------------------
; Map2E_Script00
; ---------------------------------------------------------------------------
Map2E_Script00:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map2E_Script01
; ---------------------------------------------------------------------------
Map2E_Script01:
    dw $082F                ; text $082F: "*:How are you? *:Go right to the Gate of…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map2F Per-Script Table (map_type=$2F, 15 scripts)
; ---------------------------------------------------------------------------
Map2F_ScriptPtrTable:
    dw Map2F_Script00       ; script 0
    dw Map2F_Script01       ; script 1
    dw Map2F_Script02       ; script 2
    dw Map2F_Script03       ; script 3
    dw Map2F_Script04       ; script 4
    dw Map2F_Script05       ; script 5
    dw Map2F_Script06       ; script 6
    dw Map2F_Script07       ; script 7
    dw Map2F_Script08       ; script 8
    dw Map2F_Script09       ; script 9
    dw Map2F_Script10       ; script 10
    dw Map2F_Script11       ; script 11
    dw Map2F_Script12       ; script 12
    dw Map2F_Script13       ; script 13
    dw Map2F_Script14       ; script 14
; ---------------------------------------------------------------------------
; Map2F_Script00
; ---------------------------------------------------------------------------
Map2F_Script00:
    dw $FF0E                ; $0E branch_screen: If on screen 4 → Bank0E_ScriptAddr_4344
    dw $0004                ;   screen
    dw Bank0E_ScriptAddr_4344 ;   target
    dw $FF0E                ; $0E branch_screen: If on screen 5 → Bank0E_ScriptAddr_48E4
    dw $0005                ;   screen
    dw Bank0E_ScriptAddr_48E4 ;   target
Bank0E_ScriptAddr_4342:
    dw $FFFF                ; END

Bank0E_ScriptAddr_4344:
    dw $FF01                ; $01 if_flag_set: If flag $00EF is set → Bank0E_ScriptAddr_4342
    dw $00EF                ;   flag
    dw Bank0E_ScriptAddr_4342 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00EE is set → Bank0E_ScriptAddr_47CE
    dw $00EE                ;   flag
    dw Bank0E_ScriptAddr_47CE ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00ED is set → Bank0E_ScriptAddr_4620
    dw $00ED                ;   flag
    dw Bank0E_ScriptAddr_4620 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00EC is set → Bank0E_ScriptAddr_4342
    dw $00EC                ;   flag
    dw Bank0E_ScriptAddr_4342 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00EB is set → Bank0E_ScriptAddr_4342
    dw $00EB                ;   flag
    dw Bank0E_ScriptAddr_4342 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00EA is set → Bank0E_ScriptAddr_45C0
    dw $00EA                ;   flag
    dw Bank0E_ScriptAddr_45C0 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00E9 is set → Bank0E_ScriptAddr_4342
    dw $00E9                ;   flag
    dw Bank0E_ScriptAddr_4342 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00E4 is set → Bank0E_ScriptAddr_455C
    dw $00E4                ;   flag
    dw Bank0E_ScriptAddr_455C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0000 is set → Bank0E_ScriptAddr_4342
    dw $0000                ;   flag
    dw Bank0E_ScriptAddr_4342 ;   target
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is hidden
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: the player walks left 2 tiles
    dw $0000                ;   actor
    dw $FFE0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 2 tiles
    dw $0001                ;   actor
    dw $FFE0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: the player walks up 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: the player walks right 1 tile
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: the player walks right 4 tiles
    dw $0000                ;   actor
    dw $0040                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks right 4 tiles
    dw $0001                ;   actor
    dw $0040                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: the player walks down 1 tile
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks right 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: the player walks left 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: the player walks left 2 tiles
    dw $0000                ;   actor
    dw $FFE0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 2 tiles
    dw $0001                ;   actor
    dw $FFE0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: the player walks left 2 tiles
    dw $0000                ;   actor
    dw $FFE0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 2 tiles
    dw $0001                ;   actor
    dw $FFE0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: the player walks up 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: the player walks right 1 tile
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: the player walks right 4 tiles
    dw $0000                ;   actor
    dw $0040                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks right 4 tiles
    dw $0001                ;   actor
    dw $0040                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: the player walks down 1 tile
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks right 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: the player walks left 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: the player walks left 2 tiles
    dw $0000                ;   actor
    dw $FFE0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 2 tiles
    dw $0001                ;   actor
    dw $FFE0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: the player walks left 2 tiles
    dw $0000                ;   actor
    dw $FFE0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 2 tiles
    dw $0001                ;   actor
    dw $FFE0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: the player walks up 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: the player walks right 1 tile
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: the player walks right 4 tiles
    dw $0000                ;   actor
    dw $0040                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks right 4 tiles
    dw $0001                ;   actor
    dw $0040                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: the player walks down 1 tile
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks right 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: the player walks left 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: the player walks left 2 tiles
    dw $0000                ;   actor
    dw $FFE0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 2 tiles
    dw $0001                ;   actor
    dw $FFE0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0000                ; text $0000: "Milayou:Terry! Wait! It's time for bed! …"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF0A                ; $0A walk_x_wait: NPC 1 walks right 2 tiles (script waits)
    dw $0001                ;   actor
    dw $0020                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks down 1 tile (script waits)
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: NPC 1 walks left 1 tile (script waits)
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF0D                ; $0D npc_write: NPC 1 is hidden
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: the player walks down 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: the player walks left 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 1 is hidden
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 32 ticks (~256 frames)
    dw $0020                ;   ticks
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF4C                ; $4C wait_dpad: Wait until the player presses a direction on the D-pad
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0A                ; $0A walk_x_wait: the player walks right 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FFFF                ; END

Bank0E_ScriptAddr_455C:
    dw $FF0D                ; $0D npc_write: NPC 5 is shown
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF09                ; $09 delay: Wait 16 ticks (~128 frames)
    dw $0010                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 5 is shown
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 5 is hidden
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0A                ; $0A walk_x_wait: the player walks right 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF03                ; $03 set_flag: Set flag $00E9
    dw $00E9                ;   flag
    dw $FF12                ; $12 write_ram: The intro bedroom screen 4 state: 3  [$D974 := 3]
    dw $D974                ;   address
    dw $0003                ;   value
    dw $FFFF                ; END
Bank0E_ScriptAddr_45C0:
    dw $FF0D                ; $0D npc_write: NPC 1: x low byte := 104
    dw $0001                ;   actor
    dw $0018                ;   field
    dw $0068                ;   value
    dw $FF09                ; $09 delay: Wait 6 ticks (~48 frames)
    dw $0006                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0A                ; $0A walk_x_wait: NPC 1 walks right 1 tile (script waits)
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF09                ; $09 delay: Wait 6 ticks (~48 frames)
    dw $0006                ;   ticks
    dw $FF0A                ; $0A walk_x_wait: the player walks left 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0511                ; text $0511: "Milayou:Yawn... I slept well... Milayou:…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0E_ScriptAddr_4612  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0E_ScriptAddr_4612 ;   target
    dw $0512                ; text $0512: "Milayou:Yes, it feels like the fight was…"
    dw $FF03                ; $03 set_flag: Set flag $00EB
    dw $00EB                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_4618
    dw Bank0E_ScriptAddr_4618 ;   target
Bank0E_ScriptAddr_4612:
    dw $0513                ; text $0513: "Milayou:Yes, it was truly a fun dream! M…"
    dw $FF03                ; $03 set_flag: Set flag $00EC
    dw $00EC                ;   flag
Bank0E_ScriptAddr_4618:
    dw $FF12                ; $12 write_ram: The intro bedroom screen 4 state: 4  [$D974 := 4]
    dw $D974                ;   address
    dw $0004                ;   value
    dw $FFFF                ; END
Bank0E_ScriptAddr_4620:
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 16 ticks (~128 frames)
    dw $0010                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $5F
    dw $005F                ;   sound
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $55
    dw $0055                ;   sound
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 2: run off left, sinking
    dw $0C02                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 5 is hidden
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF1A                ; $1A npc_walk_x: the player walks left 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: NPC 1 walks right 1 tile (script waits)
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1C                ; $1C trigger_anim: the player: hop
    dw $0100                ;   program_actor
    dw $FF1C                ; $1C trigger_anim: NPC 1: hop
    dw $0101                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0518                ; text $0518: "Watabou:Gimme that meat."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF1C                ; $1C trigger_anim: the player: hop
    dw $0100                ;   program_actor
    dw $FF1C                ; $1C trigger_anim: NPC 1: hop
    dw $0101                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 2: hop
    dw $0102                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0519                ; text $0519: "Watabou:Gimme the meat and I'll be your …"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF1C                ; $1C trigger_anim: the player: jump
    dw $0400                ;   program_actor
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1C                ; $1C trigger_anim: the player: spin jump
    dw $1A00                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: the player walks up 1 tile
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: the player walks right 1 tile
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 6 ticks (~48 frames)
    dw $0006                ;   ticks
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 16 ticks (~128 frames)
    dw $0010                ;   ticks
    dw $FF03                ; $03 set_flag: Set flag $00EE
    dw $00EE                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 4  [$D92B := 4]
    dw $D92B                ;   address
    dw $0004                ;   value
    dw $FF12                ; $12 write_ram: Room state of Castle screen 5 (+8 room variant(s) sharing it) → state 0  [$D92C := 0]
    dw $D92C                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 0 → state 4  [$D92D := 4]
    dw $D92D                ;   address
    dw $0004                ;   value
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 12 → state 3  [$D933 := 3]
    dw $D933                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: Room state of Gate Hub screen 4 → state 4  [$D93D := 4]
    dw $D93D                ;   address
    dw $0004                ;   value
    dw $FF12                ; $12 write_ram: Room state of Gate Hub screen 5 → state 1  [$D93E := 1]
    dw $D93E                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Farm screen 0 → state 2  [$D93F := 2]
    dw $D93F                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Farm screen 1 → state 1  [$D940 := 1]
    dw $D940                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Farm screen 4 → state 2  [$D942 := 2]
    dw $D942                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Farm screen 5 → state 1  [$D943 := 1]
    dw $D943                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Farm screen 6 → state 2  [$D944 := 2]
    dw $D944                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Stable screen 2 → state 0  [$D947 := 0]
    dw $D947                ;   address
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: Room state of Arena Rooms screen 4 → state 1  [$D94E := 1]
    dw $D94E                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Starry Shrine screen 1 → state 1  [$D952 := 1]
    dw $D952                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Queen Room screen 0 → state 2  [$D967 := 2]
    dw $D967                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: The intro bedroom screen 4 state: the intro finished  [$D974 := 6]
    dw $D974                ;   address
    dw $0006                ;   value
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 6 → state 4  [$D93A := 4]
    dw $D93A                ;   address
    dw $0004                ;   value
    dw $FF01                ; $01 if_flag_set: If flag $0015 is set → Bank0E_ScriptAddr_478E
    dw $0015                ;   flag
    dw Bank0E_ScriptAddr_478E ;   target
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 6 → state 3  [$D93A := 3]
    dw $D93A                ;   address
    dw $0003                ;   value
Bank0E_ScriptAddr_478E:
    dw $FF12                ; $12 write_ram: Room state of Farm screen 2 → state 3  [$D941 := 3]
    dw $D941                ;   address
    dw $0003                ;   value
    dw $FF01                ; $01 if_flag_set: If flag $001B is set → Bank0E_ScriptAddr_47A0
    dw $001B                ;   flag
    dw Bank0E_ScriptAddr_47A0 ;   target
    dw $FF12                ; $12 write_ram: Room state of Farm screen 2 → state 2  [$D941 := 2]
    dw $D941                ;   address
    dw $0002                ;   value
Bank0E_ScriptAddr_47A0:
    dw $FF12                ; $12 write_ram: Room state of MedalMan screen 0 → state 5  [$D95E := 5]
    dw $D95E                ;   address
    dw $0005                ;   value
    dw $FF01                ; $01 if_flag_set: If flag $0021 is set → Bank0E_ScriptAddr_47BE
    dw $0021                ;   flag
    dw Bank0E_ScriptAddr_47BE ;   target
    dw $FF12                ; $12 write_ram: Room state of MedalMan screen 0 → state 4  [$D95E := 4]
    dw $D95E                ;   address
    dw $0004                ;   value
    dw $FF01                ; $01 if_flag_set: If flag $011E is set → Bank0E_ScriptAddr_47BE
    dw $011E                ;   flag
    dw Bank0E_ScriptAddr_47BE ;   target
    dw $FF12                ; $12 write_ram: Room state of MedalMan screen 0 → state 3  [$D95E := 3]
    dw $D95E                ;   address
    dw $0003                ;   value
Bank0E_ScriptAddr_47BE:
    dw $FF12                ; $12 write_ram: The game mode: the bank $5F cutscene engine  [$C88A := 4]
    dw $C88A                ;   address
    dw $0004                ;   value
    dw $FF12                ; $12 write_ram: The next game mode: the field  [$C88B := 1]
    dw $C88B                ;   address
    dw $0001                ;   value
    dw $FF3E                ; $3E change_game_mode: Fade out and switch to the game mode in $C88B (e.g. a naming screen) — $C88E is the main loop's mode request
    dw $FFFF                ; END
Bank0E_ScriptAddr_47CE:
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 1 is hidden
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 5 is shown
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF21                ; $21 sound: Sound effect $55
    dw $0055                ;   sound
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 2: run off left, sinking
    dw $0C02                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 2: hop
    dw $0102                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 2: hop
    dw $0102                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 2: hop
    dw $0102                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF1B                ; $1B npc_walk_y: the player walks down 1 tile
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: NPC 2 walks left 2 tiles (script waits)
    dw $0002                ;   actor
    dw $FFE0                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: NPC 2 walks down 2 tiles (script waits)
    dw $0002                ;   actor
    dw $0020                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: NPC 2 walks right 2 tiles (script waits)
    dw $0002                ;   actor
    dw $0020                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: NPC 2 walks up 2 tiles (script waits)
    dw $0002                ;   actor
    dw $FFE0                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: NPC 2 walks left 2 tiles (script waits)
    dw $0002                ;   actor
    dw $FFE0                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: NPC 2 walks down 2 tiles (script waits)
    dw $0002                ;   actor
    dw $0020                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: NPC 2 walks right 2 tiles (script waits)
    dw $0002                ;   actor
    dw $0020                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: NPC 2 walks up 2 tiles (script waits)
    dw $0002                ;   actor
    dw $FFE0                ;   pixels
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 2: hop
    dw $0102                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 2: hop
    dw $0102                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 2: hop
    dw $0102                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 5 is hidden
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0A                ; $0A walk_x_wait: the player walks right 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 2: hop
    dw $0102                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $05B4                ; text $05B4: "Watabou:Good morning [HERO]! It's time t…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF0A                ; $0A walk_x_wait: NPC 2 walks right 4 tiles (script waits)
    dw $0002                ;   actor
    dw $0040                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: NPC 2 walks down 1 tile (script waits)
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: NPC 2 walks right 3 tiles (script waits)
    dw $0002                ;   actor
    dw $0030                ;   pixels
    dw $FF0D                ; $0D npc_write: NPC 2 is hidden
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF03                ; $03 set_flag: Set flag $00EF
    dw $00EF                ;   flag
    dw $FF12                ; $12 write_ram: The intro bedroom screen 4 state: 3  [$D974 := 3]
    dw $D974                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: Room state of Intro Bedroom (2-screen, crashes) screen 5 → state 1  [$D975 := 1]
    dw $D975                ;   address
    dw $0001                ;   value
    dw $FFFF                ; END
Bank0E_ScriptAddr_48E4:
    dw $FF01                ; $01 if_flag_set: If flag $00F0 is set → Bank0E_ScriptAddr_4342
    dw $00F0                ;   flag
    dw Bank0E_ScriptAddr_4342 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00EF is set → Bank0E_ScriptAddr_4B60
    dw $00EF                ;   flag
    dw Bank0E_ScriptAddr_4B60 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0000 is set → Bank0E_ScriptAddr_4342
    dw $0000                ;   flag
    dw Bank0E_ScriptAddr_4342 ;   target
    dw $FF0A                ; $0A walk_x_wait: the player walks right 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF21                ; $21 sound: Sound effect $60
    dw $0060                ;   sound
    dw $FF17                ; $17 bedroom_tile_swap: Switch the intro bedroom to its night look (tile swap)
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF21                ; $21 sound: Sound effect $55
    dw $0055                ;   sound
    dw $FF1C                ; $1C trigger_anim: NPC 2: hop, then drop 2 tiles
    dw $1202                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0A                ; $0A walk_x_wait: NPC 2 walks left 7 tiles (script waits)
    dw $0002                ;   actor
    dw $FF90                ;   pixels
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0008                ; text $0008: "*:Are you Milayou? *:Hm, You don't look …"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks up 1 tile
    dw $0002                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks down 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF21                ; $21 sound: Sound effect $54
    dw $0054                ;   sound
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: the player walks down 1 tile
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: The player is shown (player flags := $80)
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0080                ;   value
    dw $FF0B                ; $0B walk_y_wait: NPC 2 walks down 1 tile (script waits)
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: NPC 2 walks left 2 tiles (script waits)
    dw $0002                ;   actor
    dw $FFE0                ;   pixels
    dw $FF09                ; $09 delay: Wait 22 ticks (~176 frames)
    dw $0016                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 3: x low byte := 152
    dw $0003                ;   actor
    dw $0018                ;   field
    dw $0098                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF1A                ; $1A npc_walk_x: NPC 2 walks right 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF1A                ; $1A npc_walk_x: NPC 2 walks right 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 3 walks right 1 tile
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF1A                ; $1A npc_walk_x: NPC 2 walks right 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 3 walks right 1 tile
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF1A                ; $1A npc_walk_x: NPC 2 walks right 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 3 walks right 1 tile
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks up 1 tile
    dw $0002                ;   actor
    dw $FFF0                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 3 walks right 1 tile
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF48                ; $48 face_down: NPC 3 faces down
    dw $0003                ;   actor
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF1A                ; $1A npc_walk_x: NPC 2 walks right 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks up 1 tile
    dw $0003                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF49                ; $49 face_left: NPC 3 faces left
    dw $0003                ;   actor
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF1A                ; $1A npc_walk_x: NPC 2 walks right 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 3 walks right 1 tile
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF1A                ; $1A npc_walk_x: NPC 2 walks right 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 3 walks right 1 tile
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF1A                ; $1A npc_walk_x: NPC 2 walks right 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 3 walks right 1 tile
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF1A                ; $1A npc_walk_x: NPC 2 walks right 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF1A                ; $1A npc_walk_x: NPC 3 walks right 1 tile
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF1C                ; $1C trigger_anim: the player: hop
    dw $0100                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF48                ; $48 face_down: NPC 3 faces down
    dw $0003                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $55
    dw $0055                ;   sound
    dw $FF1C                ; $1C trigger_anim: NPC 2: rise high, hang, settle 40 px up
    dw $1302                ;   program_actor
    dw $FF1A                ; $1A npc_walk_x: NPC 3 walks right 1 tile
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF0D                ; $0D npc_write: NPC 2 is hidden
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF21                ; $21 sound: Sound effect $55
    dw $0055                ;   sound
    dw $FF1C                ; $1C trigger_anim: NPC 3: rise high, hang, settle 40 px up
    dw $1303                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
; Bedroom script 0 from pos 951 ($0E:$4AA4, 94 words to the END) (S121 trace):
; the dresser glows (sound $60, op $17 the tile swap, delay 8) after Warubou and
; Milayou rose into it (pos 929-947); then Terry / Watabou's part and the hand-
; back to the player.
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

Bank0E_ScriptAddr_4B60:
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $60
    dw $0060                ;   sound
    dw $FF17                ; $17 bedroom_tile_swap: Switch the intro bedroom to its night look (tile swap)
    dw $FF09                ; $09 delay: Wait 6 ticks (~48 frames)
    dw $0006                ;   ticks
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump up 2 tiles
    dw $0201                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 1 is hidden
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks up 1 tile (script waits)
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF21                ; $21 sound: Sound effect $60
    dw $0060                ;   sound
    dw $FF17                ; $17 bedroom_tile_swap: Switch the intro bedroom to its night look (tile swap)
    dw $FF03                ; $03 set_flag: Set flag $00F0
    dw $00F0                ;   flag
    dw $FF12                ; $12 write_ram: The intro bedroom screen 4 state: 0  [$D974 := 0]
    dw $D974                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
; ---------------------------------------------------------------------------
; Map2F_Script01
; ---------------------------------------------------------------------------
Map2F_Script01:
    dw $0004                ; text $0004: "Terry looked at the bookshelf. :A Fairy …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map2F_Script02
; ---------------------------------------------------------------------------
Map2F_Script02:
    dw $0005                ; text $0005: "Terry looked at the bookshelf. :Diary of…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map2F_Script03
; ---------------------------------------------------------------------------
Map2F_Script03:
    dw $0006                ; text $0006: "[SOUND 60]Terry looked in the dresser. I…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map2F_Script04
; ---------------------------------------------------------------------------
Map2F_Script04:
    dw $0007                ; text $0007: "[SOUND 60]Terry looked in the dresser. I…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map2F_Script05
; ---------------------------------------------------------------------------
Map2F_Script05:
    dw $0002                ; text $0002: "Terry looked at a stuffed animal. Someth…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map2F_Script06
; ---------------------------------------------------------------------------
Map2F_Script06:
    dw $0003                ; text $0003: "Terry looked in front of him. A flame sp…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map2F_Script07
; ---------------------------------------------------------------------------
Map2F_Script07:
    dw $FF01                ; $01 if_flag_set: If flag $00EE is set → Bank0E_ScriptAddr_4BEE
    dw $00EE                ;   flag
    dw Bank0E_ScriptAddr_4BEE ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00EC is set → Bank0E_ScriptAddr_4BEA
    dw $00EC                ;   flag
    dw Bank0E_ScriptAddr_4BEA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00EB is set → Bank0E_ScriptAddr_4BE6
    dw $00EB                ;   flag
    dw Bank0E_ScriptAddr_4BE6 ;   target
    dw $0001                ; text $0001: "Milayou:... zzz."
    dw $FFFF                ; END

Bank0E_ScriptAddr_4BE6:
    dw $0514                ; text $0514: "Milayou:Good night [HERO]! Sweet dreams!"
    dw $FFFF                ; END

Bank0E_ScriptAddr_4BEA:
    dw $0515                ; text $0515: "Milayou:Good night [HERO]! Go to sleep."
    dw $FFFF                ; END

Bank0E_ScriptAddr_4BEE:
    dw $0001                ; text $0001: "Milayou:... zzz."
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map2F_Script08
; ---------------------------------------------------------------------------
Map2F_Script08:
    dw $FF01                ; $01 if_flag_set: If flag $00E4 is set → Bank0E_ScriptAddr_4BFC
    dw $00E4                ;   flag
    dw Bank0E_ScriptAddr_4BFC ;   target
    dw $000B                ; text $000B: "Terry looks at the bookshelf. :Encyclope…"
    dw $FFFF                ; END

Bank0E_ScriptAddr_4BFC:
    dw $051A                ; text $051A: "[HERO] checked out the bookshelf. :Encyc…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map2F_Script09
; ---------------------------------------------------------------------------
Map2F_Script09:
    dw $000C                ; text $000C: "Terry looked at the bookshelf. Too diffi…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map2F_Script10
; ---------------------------------------------------------------------------
Map2F_Script10:
    dw $FF01                ; $01 if_flag_set: If flag $00F0 is set → Bank0E_ScriptAddr_4CB4
    dw $00F0                ;   flag
    dw Bank0E_ScriptAddr_4CB4 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00E4 is set → Bank0E_ScriptAddr_4CAC
    dw $00E4                ;   flag
    dw Bank0E_ScriptAddr_4CAC ;   target
    dw $FF21                ; $21 sound: Sound effect $60
    dw $0060                ;   sound
    dw $FF17                ; $17 bedroom_tile_swap: Switch the intro bedroom to its night look (tile swap)
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF1B                ; $1B npc_walk_y: the player walks down 1 tile
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1C                ; $1C trigger_anim: the player: hop
    dw $0100                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: the player walks down 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF1C                ; $1C trigger_anim: the player: spin and float up 3 tiles
    dw $0300                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF12                ; $12 write_ram: The breeding-shrine stage / return code: from the intro bedroom  [$D951 := 6]
    dw $D951                ;   address
    dw $0006                ;   value
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Starry Shrine Breeding Cutscene at (5, 4)
    dw $0008                ;   map
    dw $0058                ;   x
    dw $0048                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0E_ScriptAddr_4CAC:
    dw $051B                ; text $051B: "[SOUND 60][HERO] looked in the dresser. …"
    dw $FF03                ; $03 set_flag: Set flag $00EA
    dw $00EA                ;   flag
    dw $FFFF                ; END

Bank0E_ScriptAddr_4CB4:
    dw $FF21                ; $21 sound: Sound effect $60
    dw $0060                ;   sound
    dw $FF17                ; $17 bedroom_tile_swap: Switch the intro bedroom to its night look (tile swap)
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF1B                ; $1B npc_walk_y: the player walks down 1 tile
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1C                ; $1C trigger_anim: the player: hop
    dw $0100                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: the player walks down 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF1C                ; $1C trigger_anim: the player: spin and float up 3 tiles
    dw $0300                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF12                ; $12 write_ram: The breeding-shrine stage / return code: from the intro bedroom  [$D951 := 6]
    dw $D951                ;   address
    dw $0006                ;   value
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Starry Shrine Breeding Cutscene at (5, 4)
    dw $0008                ;   map
    dw $0058                ;   x
    dw $0048                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map2F_Script11
; ---------------------------------------------------------------------------
Map2F_Script11:
    dw $000E                ; text $000E: "Terry looked at a stuffed animal. Someth…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map2F_Script12
; ---------------------------------------------------------------------------
Map2F_Script12:
    dw $000D                ; text $000D: "Terry looked in front of him. The clock …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map2F_Script13
; ---------------------------------------------------------------------------
Map2F_Script13:
    dw $FF01                ; $01 if_flag_set: If flag $00EB is set → Bank0E_ScriptAddr_4D66
    dw $00EB                ;   flag
    dw Bank0E_ScriptAddr_4D66 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00EC is set → Bank0E_ScriptAddr_4D66
    dw $00EC                ;   flag
    dw Bank0E_ScriptAddr_4D66 ;   target
    dw $FFFF                ; END

Bank0E_ScriptAddr_4D66:
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 1: hop
    dw $0101                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0516                ; text $0516: "Milayou:...Oh? ...[HERO]!"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0A                ; $0A walk_x_wait: the player walks right 2 tiles (script waits)
    dw $0000                ;   actor
    dw $0020                ;   pixels
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0517                ; text $0517: "Milayou:What's in your pocket?"
    dw $FF06                ; $06 close_text: Close the open text box
Bank0E_ScriptAddr_4D8E:
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 12 ticks (~96 frames)
    dw $000C                ;   ticks
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 12 ticks (~96 frames)
    dw $000C                ;   ticks
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 4 is shown
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1C                ; $1C trigger_anim: the player: jump
    dw $0400                ;   program_actor
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF12                ; $12 write_ram: The intro bedroom screen 4 state: 5  [$D974 := 5]
    dw $D974                ;   address
    dw $0005                ;   value
    dw $FF03                ; $03 set_flag: Set flag $00ED
    dw $00ED                ;   flag
    dw $FF41                ; $41 set_bgm: Music $47
    dw $0047                ;   song
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF65                ; $65 wait_dd80: Wait until the running effect / animation finishes
    dw $FF12                ; $12 write_ram: The game mode: the bank $5F cutscene engine  [$C88A := 4]
    dw $C88A                ;   address
    dw $0004                ;   value
    dw $FF12                ; $12 write_ram: The next game mode: the title screen  [$C88B := 0]
    dw $C88B                ;   address
    dw $0000                ;   value
    dw $FF3E                ; $3E change_game_mode: Fade out and switch to the game mode in $C88B (e.g. a naming screen) — $C88E is the main loop's mode request
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map2F_Script14
; ---------------------------------------------------------------------------
Map2F_Script14:
    dw $FF01                ; $01 if_flag_set: If flag $00EB is set → Bank0E_ScriptAddr_4E1A
    dw $00EB                ;   flag
    dw Bank0E_ScriptAddr_4E1A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00EC is set → Bank0E_ScriptAddr_4E1A
    dw $00EC                ;   flag
    dw Bank0E_ScriptAddr_4E1A ;   target
    dw $FFFF                ; END

Bank0E_ScriptAddr_4E1A:
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 1: hop
    dw $0101                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0516                ; text $0516: "Milayou:...Oh? ...[HERO]!"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0517                ; text $0517: "Milayou:What's in your pocket?"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_4D8E
    dw Bank0E_ScriptAddr_4D8E ;   target
; ---------------------------------------------------------------------------
; BossBeginning Per-Script Table (map_type=$30, 2 scripts)
; ---------------------------------------------------------------------------
BossBeginning_ScriptPtrTable:
    dw BossBeginning_Script00 ; script 0
    dw BossBeginning_Script01 ; script 1
; ---------------------------------------------------------------------------
; BossBeginning_Script00
; ---------------------------------------------------------------------------
; S132 (decode + PyBoy, tools/census_story_state.py): the room's ENTRY script —
; on every arrival $D92B := 6, the Castle's "gate return" code (a WarpWing out of
; the unbeaten gate gets the priest's heal; the win below writes 7). Every vanilla
; gate boss room does the same (GATE_GENERATION §7.7).
BossBeginning_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value ‖ value 6 = the priest path (was mis-commented as text $0006)
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossBeginning_Script01
; ---------------------------------------------------------------------------
BossBeginning_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $003D is set → Bank0E_ScriptAddr_4F0E
    dw $003D                ;   flag
    dw Bank0E_ScriptAddr_4F0E ;   target
    dw $0058                ; text $0058: "*:How do you do. I'm Hale. *:I know you …"
    dw $FF03                ; $03 set_flag: Set flag $003D
    dw $003D                ;   flag
Bank0E_ScriptAddr_4E68:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 11 (boss)
    dw $000B                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0059                ; text $0059: "*:You are strong! I like you, [HERO]."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 7, curve 3  [$D8E3 := $0307]
    dw $D8E3                ;   address
    dw $0307                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 2: fly in down-left (the flight path set above)
    dw $1502                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0146                ; text $0146: "Watabou:Right on! [HERO]! I'll take you …"
    dw $FF1C                ; $1C trigger_anim: NPC 2: jump
    dw $0402                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
; S132: THE WIN (script 1 pos 69 on): the King's speech code, the gate's
; cleared flag, the Castle event 7 (= the King's speech chain on $D9E3), then
; the WIN TAIL $0E:$4EF6 (extracted/gate_names.json win_tails[0]): the boss
; room's state 1 (beaten) and the "Room of" counter, close, the wavy warp to
; the Castle (map $00, pixel $E8,$58 = screen 1 cell (4,5)). Run by
; editor2/core/story_state.py; == PyBoy (tools/census_story_state.py).
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 48  [$D9E3 := 48]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $0030                ;   value ‖ value $30 = speech $30 (Healer; sets $0009 "go to the arena")
    dw $FF03                ; $03 set_flag: Set flag $0010
    dw $0010                ;   flag ‖ flag $0010 = Gate of Beginning cleared
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value ‖ value 7 = the King's speech chain
    dw $FF12                ; $12 write_ram: Room state of Room of Beginning screen 0 → state 1  [$D968 := 1] ‖ WriteRAM — the win tail starts here ($0E:$4EF6)
    dw $D968                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Beginning (Healer) screen 0 → state 1  [$D976 := 1]
    dw $D976                ;   address
    dw $0001                ;   value ‖ value 1 = state 1, the boss beaten
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5) ‖ warp_fade (op $3B: the wavy fade)
    dw $0000                ;   map ‖ map $00 (the Castle; high byte 0 = a room, not a gate)
    dw $00E8                ;   x ‖ pixel X $E8 (screen 1, cell 4)
    dw $0058                ;   y ‖ pixel Y $58 (cell 5)
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0E_ScriptAddr_4F0E:
    dw $013F                ; text $013F: "*:How many times do I have to say it?! I…"
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_4E68
    dw Bank0E_ScriptAddr_4E68 ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; BossVillager Per-Script Table (map_type=$31, 3 scripts)
; ---------------------------------------------------------------------------
BossVillager_ScriptPtrTable:
    dw BossVillager_Script00 ; script 0
    dw BossVillager_Script01 ; script 1
    dw BossVillager_Script02 ; script 2
; ---------------------------------------------------------------------------
; BossVillager_Script00
; ---------------------------------------------------------------------------
BossVillager_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossVillager_Script01
; ---------------------------------------------------------------------------
BossVillager_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $00B6 is set → Bank0E_ScriptAddr_4FA8
    dw $00B6                ;   flag
    dw Bank0E_ScriptAddr_4FA8 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00B2 is set → Bank0E_ScriptAddr_4F8E
    dw $00B2                ;   flag
    dw Bank0E_ScriptAddr_4F8E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00B5 is set → Bank0E_ScriptAddr_4F80
    dw $00B5                ;   flag
    dw Bank0E_ScriptAddr_4F80 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00B4 is set → Bank0E_ScriptAddr_4F6E
    dw $00B4                ;   flag
    dw Bank0E_ScriptAddr_4F6E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00B3 is set → Bank0E_ScriptAddr_4F5C
    dw $00B3                ;   flag
    dw Bank0E_ScriptAddr_4F5C ;   target
    dw $0220                ; text $0220: "*:Oh, my prince! *:You came here to save…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0E_ScriptAddr_4FAC  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0E_ScriptAddr_4FAC ;   target
    dw $0221                ; text $0221: "*:I see..."
    dw $FF03                ; $03 set_flag: Set flag $00B3
    dw $00B3                ;   flag
    dw $FFFF                ; END

Bank0E_ScriptAddr_4F5C:
    dw $0220                ; text $0220: "*:Oh, my prince! *:You came here to save…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0E_ScriptAddr_4FAC  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0E_ScriptAddr_4FAC ;   target
    dw $0222                ; text $0222: "*:I want to go back to the castle..."
    dw $FF03                ; $03 set_flag: Set flag $00B4
    dw $00B4                ;   flag
    dw $FFFF                ; END

Bank0E_ScriptAddr_4F6E:
    dw $0220                ; text $0220: "*:Oh, my prince! *:You came here to save…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0E_ScriptAddr_4FAC  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0E_ScriptAddr_4FAC ;   target
    dw $0223                ; text $0223: "*:*sigh*"
    dw $FF03                ; $03 set_flag: Set flag $00B5
    dw $00B5                ;   flag
    dw $FFFF                ; END

Bank0E_ScriptAddr_4F80:
    dw $0220                ; text $0220: "*:Oh, my prince! *:You came here to save…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0E_ScriptAddr_4FAC  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0E_ScriptAddr_4FAC ;   target
    dw $0224                ; text $0224: "*:I want to go back to the castle..."
    dw $FFFF                ; END

Bank0E_ScriptAddr_4F8E:
    dw $0227                ; text $0227: "*:It is okay. You're still little. *:Tha…"
Bank0E_ScriptAddr_4F90:
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0E_ScriptAddr_4FA0  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0E_ScriptAddr_4FA0 ;   target
    dw $0228                ; text $0228: "*:Please leave quietly. [YES/NO]"
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_4F90
    dw Bank0E_ScriptAddr_4F90 ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0E_ScriptAddr_4FA0:
    dw $0229                ; text $0229: "*:I'll wait for a stronger hero to save …"
    dw $FF03                ; $03 set_flag: Set flag $00B6
    dw $00B6                ;   flag
    dw $FFFF                ; END
Bank0E_ScriptAddr_4FA8:
    dw $0250                ; text $0250: "*:I know. *:There will be a youth... *:B…"
    dw $FFFF                ; END

Bank0E_ScriptAddr_4FAC:
    dw $0225                ; text $0225: "*:Oh, I'm so happy! *blush* *:Oh please …"
    dw $0226                ; text $0226: "[HERO] tried to pick up the princess... …"
    dw $FF03                ; $03 set_flag: Set flag $00B2
    dw $00B2                ;   flag
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossVillager_Script02
; ---------------------------------------------------------------------------
BossVillager_Script02:
    dw $FF01                ; $01 if_flag_set: If flag $00B7 is set → Bank0E_ScriptAddr_5076
    dw $00B7                ;   flag
    dw Bank0E_ScriptAddr_5076 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00B6 is set → Bank0E_ScriptAddr_4FC6
    dw $00B6                ;   flag
    dw Bank0E_ScriptAddr_4FC6 ;   target
    dw $0251                ; text $0251: "*:Zzz... zzzz...."
    dw $FFFF                ; END

Bank0E_ScriptAddr_4FC6:
    dw $0252                ; text $0252: "*:Zzz... zzzz.... ....*bust!* *:It's bee…"
    dw $FF03                ; $03 set_flag: Set flag $00B7
    dw $00B7                ;   flag
Bank0E_ScriptAddr_4FCC:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 31 (boss)
    dw $001F                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0254                ; text $0254: "*:You're strong!!"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 4, curve 3  [$D8E3 := $0304]
    dw $D8E3                ;   address
    dw $0304                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 2: fly in down-right (the flight path set above)
    dw $1602                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0255                ; text $0255: "Watabou:You couldn't carry the princess.…"
    dw $FF1C                ; $1C trigger_anim: NPC 2: jump
    dw $0402                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 49  [$D9E3 := 49]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $0031                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0011
    dw $0011                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Room: Villager/Talisman screen 0 → state 1  [$D969 := 1]
    dw $D969                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Villager (Dragon) screen 0 → state 1  [$D977 := 1]
    dw $D977                ;   address
    dw $0001                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $0012 is clear → Bank0E_ScriptAddr_506A
    dw $0012                ;   flag
    dw Bank0E_ScriptAddr_506A ;   target
    dw $FF12                ; $12 write_ram: Room state of Room: Villager/Talisman screen 0 → state 3  [$D969 := 3]
    dw $D969                ;   address
    dw $0003                ;   value
Bank0E_ScriptAddr_506A:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0E_ScriptAddr_5076:
    dw $0253                ; text $0253: "*:...zzz. You came again!"
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_4FCC
    dw Bank0E_ScriptAddr_4FCC ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; BossTalisman Per-Script Table (map_type=$32, 3 scripts)
; ---------------------------------------------------------------------------
BossTalisman_ScriptPtrTable:
    dw BossTalisman_Script00 ; script 0
    dw BossTalisman_Script01 ; script 1
    dw BossTalisman_Script02 ; script 2
; ---------------------------------------------------------------------------
; BossTalisman_Script00
; ---------------------------------------------------------------------------
BossTalisman_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF01                ; $01 if_flag_set: If flag $00B8 is set → Bank0E_ScriptAddr_517E
    dw $00B8                ;   flag
    dw Bank0E_ScriptAddr_517E ;   target
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0B                ; $0B walk_y_wait: NPC 2 walks down 2 tiles (script waits)
    dw $0002                ;   actor
    dw $0020                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: NPC 2 walks left 3 tiles (script waits)
    dw $0002                ;   actor
    dw $FFD0                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: NPC 2 walks down 2 tiles (script waits)
    dw $0002                ;   actor
    dw $0020                ;   pixels
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF09                ; $09 delay: Wait 16 ticks (~128 frames)
    dw $0010                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 2: hop
    dw $0102                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 2: hop
    dw $0102                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 2: hop
    dw $0102                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 2: hop
    dw $0102                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks left 1 tile
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1A                ; $1A npc_walk_x: NPC 1 walks right 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF21                ; $21 sound: Sound effect $54
    dw $0054                ;   sound
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 5, curve 3  [$D8E3 := $0305]
    dw $D8E3                ;   address
    dw $0305                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 2: fly off up-right (the flight path set above)
    dw $1802                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF03                ; $03 set_flag: Set flag $00B8
    dw $00B8                ;   flag
    dw $FFFF                ; END

Bank0E_ScriptAddr_517E:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossTalisman_Script01
; ---------------------------------------------------------------------------
BossTalisman_Script01:
    dw $0256                ; text $0256: "*:........"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossTalisman_Script02
; ---------------------------------------------------------------------------
BossTalisman_Script02:
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $FF01                ; $01 if_flag_set: If flag $00B9 is set → Bank0E_ScriptAddr_5246
    dw $00B9                ;   flag
    dw Bank0E_ScriptAddr_5246 ;   target
    dw $0257                ; text $0257: "*:You, stop right there! *:You shall not…"
    dw $FF03                ; $03 set_flag: Set flag $00B9
    dw $00B9                ;   flag
Bank0E_ScriptAddr_519A:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 32 (boss)
    dw $0020                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0259                ; text $0259: "*:You are powerful. *:But defeating me d…"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 5, curve 4  [$D8E3 := $0405]
    dw $D8E3                ;   address
    dw $0405                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 3: fly in down-left (the flight path set above)
    dw $1503                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 3 faces right
    dw $0003                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 3 faces down
    dw $0003                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 3 faces left
    dw $0003                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 3 faces up
    dw $0003                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0262                ; text $0262: "Watabou:This village is an illusion of G…"
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF4A                ; $4A face_right: NPC 3 faces right
    dw $0003                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 3 faces down
    dw $0003                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF49                ; $49 face_left: NPC 3 faces left
    dw $0003                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 3 faces up
    dw $0003                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 50  [$D9E3 := 50]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $0032                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0012
    dw $0012                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Room: Villager/Talisman screen 0 → state 2  [$D969 := 2]
    dw $D969                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Talisman (Golem) screen 0 → state 1  [$D978 := 1]
    dw $D978                ;   address
    dw $0001                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $0011 is clear → Bank0E_ScriptAddr_523A
    dw $0011                ;   flag
    dw Bank0E_ScriptAddr_523A ;   target
    dw $FF12                ; $12 write_ram: Room state of Room: Villager/Talisman screen 0 → state 3  [$D969 := 3]
    dw $D969                ;   address
    dw $0003                ;   value
Bank0E_ScriptAddr_523A:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0E_ScriptAddr_5246:
    dw $0258                ; text $0258: "*:Must I repeat myself? *:You shall not …"
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_519A
    dw Bank0E_ScriptAddr_519A ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; BossMemories Per-Script Table (map_type=$33, 2 scripts)
; ---------------------------------------------------------------------------
BossMemories_ScriptPtrTable:
    dw BossMemories_Script00 ; script 0
    dw BossMemories_Script01 ; script 1
; ---------------------------------------------------------------------------
; BossMemories_Script00
; ---------------------------------------------------------------------------
BossMemories_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossMemories_Script01
; ---------------------------------------------------------------------------
BossMemories_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $00BC is set → Bank0E_ScriptAddr_533C
    dw $00BC                ;   flag
    dw Bank0E_ScriptAddr_533C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00BB is set → Bank0E_ScriptAddr_5284
    dw $00BB                ;   flag
    dw Bank0E_ScriptAddr_5284 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00BA is set → Bank0E_ScriptAddr_527C
    dw $00BA                ;   flag
    dw Bank0E_ScriptAddr_527C ;   target
    dw $0263                ; text $0263: "*:Grrrr... Whoosh! Whoooosh!"
    dw $FF03                ; $03 set_flag: Set flag $00BA
    dw $00BA                ;   flag
    dw $FFFF                ; END

Bank0E_ScriptAddr_527C:
    dw $0264                ; text $0264: "*:Guffaw Guffaw..? Cackle cackle...?"
    dw $FF03                ; $03 set_flag: Set flag $00BB
    dw $00BB                ;   flag
    dw $FFFF                ; END

Bank0E_ScriptAddr_5284:
    dw $0265                ; text $0265: "*:Grrrr... Whoosh! Whoooosh! *:......cac…"
    dw $FF03                ; $03 set_flag: Set flag $00BC
    dw $00BC                ;   flag
Bank0E_ScriptAddr_528A:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 51 (boss)
    dw $0033                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0267                ; text $0267: "*:[HERO]! [HERO]!! *:Meow. Purrrr..."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 7, curve 4  [$D8E3 := $0407]
    dw $D8E3                ;   address
    dw $0407                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 2: fly in down-left (the flight path set above)
    dw $1502                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0268                ; text $0268: "Watabou:It seems MadCat is attached to […"
    dw $FF1C                ; $1C trigger_anim: NPC 2: jump
    dw $0402                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 51  [$D9E3 := 51]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $0033                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0013
    dw $0013                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Room: Memories/Bewilder screen 0 → state 1  [$D96A := 1]
    dw $D96A                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Memories (MadCat) screen 0 → state 1  [$D979 := 1]
    dw $D979                ;   address
    dw $0001                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $0014 is clear → Bank0E_ScriptAddr_5330
    dw $0014                ;   flag
    dw Bank0E_ScriptAddr_5330 ;   target
    dw $FF12                ; $12 write_ram: Room state of Room: Memories/Bewilder screen 0 → state 3  [$D96A := 3]
    dw $D96A                ;   address
    dw $0003                ;   value
Bank0E_ScriptAddr_5330:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0E_ScriptAddr_533C:
    dw $0266                ; text $0266: "*:Grrrr... Cackle cackle!!"
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_528A
    dw Bank0E_ScriptAddr_528A ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; BossBewilder Per-Script Table (map_type=$34, 11 scripts)
; ---------------------------------------------------------------------------
BossBewilder_ScriptPtrTable:
    dw BossBewilder_Script00 ; script 0
    dw BossBewilder_Script01 ; script 1
    dw BossBewilder_Script02 ; script 2
    dw BossBewilder_Script03 ; script 3
    dw BossBewilder_Script04 ; script 4
    dw BossBewilder_Script05 ; script 5
    dw BossBewilder_Script06 ; script 6
    dw BossBewilder_Script07 ; script 7
    dw BossBewilder_Script08 ; script 8
    dw BossBewilder_Script09 ; script 9
    dw BossBewilder_Script10 ; script 10
; ---------------------------------------------------------------------------
; BossBewilder_Script00
; ---------------------------------------------------------------------------
BossBewilder_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script01
; ---------------------------------------------------------------------------
BossBewilder_Script01:
    dw $0269                ; text $0269: "[HERO] read the sign. :Youth goes in has…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script02
; ---------------------------------------------------------------------------
BossBewilder_Script02:
    dw $FF01                ; $01 if_flag_set: If flag $0117 is set → Bank0E_ScriptAddr_5422
    dw $0117                ;   flag
    dw Bank0E_ScriptAddr_5422 ;   target
    dw $026A                ; text $026A: "*:Hee hee hee! I didn't think you could …"
    dw $FF03                ; $03 set_flag: Set flag $0117
    dw $0117                ;   flag
Bank0E_ScriptAddr_537A:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 53 (boss)
    dw $0035                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0290                ; text $0290: "*:Ha ha ha! You beat me!"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 5 is shown
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 5, curve 2  [$D8E3 := $0205]
    dw $D8E3                ;   address
    dw $0205                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 5: fly in down-left (the flight path set above)
    dw $1505                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 5 faces up
    dw $0005                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 5 faces right
    dw $0005                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 5 faces down
    dw $0005                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 5 faces left
    dw $0005                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: the player faces right
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0293                ; text $0293: "Watabou:You did a good job solving the F…"
    dw $FF1C                ; $1C trigger_anim: NPC 5: jump
    dw $0405                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 5 faces up
    dw $0005                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 5 faces right
    dw $0005                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 5 faces down
    dw $0005                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF49                ; $49 face_left: NPC 5 faces left
    dw $0005                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 52  [$D9E3 := 52]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $0034                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0014
    dw $0014                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Room: Memories/Bewilder screen 0 → state 2  [$D96A := 2]
    dw $D96A                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Bewilder (FaceTree) screen 0 → state 1  [$D97A := 1]
    dw $D97A                ;   address
    dw $0001                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $0013 is clear → Bank0E_ScriptAddr_5416
    dw $0013                ;   flag
    dw Bank0E_ScriptAddr_5416 ;   target
    dw $FF12                ; $12 write_ram: Room state of Room: Memories/Bewilder screen 0 → state 3  [$D96A := 3]
    dw $D96A                ;   address
    dw $0003                ;   value
Bank0E_ScriptAddr_5416:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0E_ScriptAddr_5422:
    dw $026B                ; text $026B: "*:No matter how many times you fight, it…"
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_537A
    dw Bank0E_ScriptAddr_537A ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; BossBewilder_Script03
; ---------------------------------------------------------------------------
BossBewilder_Script03:
    dw $FF01                ; $01 if_flag_set: If flag $00BD is set → Bank0E_ScriptAddr_543E
    dw $00BD                ;   flag
    dw Bank0E_ScriptAddr_543E ;   target
    dw $0291                ; text $0291: "*:Squeaking squeaking."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF05                ; $05 battle: Battle: enemy row 341
    dw $0155                ;   enemy
    dw $FF03                ; $03 set_flag: Set flag $00BD
    dw $00BD                ;   flag
    dw $FFFF                ; END

Bank0E_ScriptAddr_543E:
    dw $0292                ; text $0292: "*:… …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script04
; ---------------------------------------------------------------------------
BossBewilder_Script04:
    dw $FF01                ; $01 if_flag_set: If flag $00BE is set → Bank0E_ScriptAddr_5456
    dw $00BE                ;   flag
    dw Bank0E_ScriptAddr_5456 ;   target
    dw $0291                ; text $0291: "*:Squeaking squeaking."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF05                ; $05 battle: Battle: enemy row 341
    dw $0155                ;   enemy
    dw $FF03                ; $03 set_flag: Set flag $00BE
    dw $00BE                ;   flag
    dw $FFFF                ; END

Bank0E_ScriptAddr_5456:
    dw $0292                ; text $0292: "*:… …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script05
; ---------------------------------------------------------------------------
BossBewilder_Script05:
    dw $FF01                ; $01 if_flag_set: If flag $00BF is set → Bank0E_ScriptAddr_546E
    dw $00BF                ;   flag
    dw Bank0E_ScriptAddr_546E ;   target
    dw $0291                ; text $0291: "*:Squeaking squeaking."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF05                ; $05 battle: Battle: enemy row 341
    dw $0155                ;   enemy
    dw $FF03                ; $03 set_flag: Set flag $00BF
    dw $00BF                ;   flag
    dw $FFFF                ; END

Bank0E_ScriptAddr_546E:
    dw $0292                ; text $0292: "*:… …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script06
; ---------------------------------------------------------------------------
BossBewilder_Script06:
    dw $FF01                ; $01 if_flag_set: If flag $00C0 is set → Bank0E_ScriptAddr_5486
    dw $00C0                ;   flag
    dw Bank0E_ScriptAddr_5486 ;   target
    dw $0291                ; text $0291: "*:Squeaking squeaking."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF05                ; $05 battle: Battle: enemy row 341
    dw $0155                ;   enemy
    dw $FF03                ; $03 set_flag: Set flag $00C0
    dw $00C0                ;   flag
    dw $FFFF                ; END

Bank0E_ScriptAddr_5486:
    dw $0292                ; text $0292: "*:… …"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script07
; ---------------------------------------------------------------------------
BossBewilder_Script07:
    dw $FF10                ; $10 walk_to_x: NPC 2 walks to x = 120 px (script waits)
    dw $0002                ;   actor
    dw $0078                ;   x
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script08
; ---------------------------------------------------------------------------
BossBewilder_Script08:
    dw $FF01                ; $01 if_flag_set: If flag $00BF is set → Bank0E_ScriptAddr_549E
    dw $00BF                ;   flag
    dw Bank0E_ScriptAddr_549E ;   target
    dw $FF10                ; $10 walk_to_x: NPC 3 walks to x = 72 px (script waits)
    dw $0003                ;   actor
    dw $0048                ;   x
Bank0E_ScriptAddr_549E:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script09
; ---------------------------------------------------------------------------
BossBewilder_Script09:
    dw $FF01                ; $01 if_flag_set: If flag $00C0 is set → Bank0E_ScriptAddr_54AC
    dw $00C0                ;   flag
    dw Bank0E_ScriptAddr_54AC ;   target
    dw $FF11                ; $11 walk_to_y: NPC 4 walks to y = 88 px (script waits)
    dw $0004                ;   actor
    dw $0058                ;   y
Bank0E_ScriptAddr_54AC:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossBewilder_Script10
; ---------------------------------------------------------------------------
BossBewilder_Script10:
    dw $FF10                ; $10 walk_to_x: NPC 1 walks to x = 8 px (script waits)
    dw $0001                ;   actor
    dw $0008                ;   x
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map35 Per-Script Table (map_type=$35, 4 scripts)
; ---------------------------------------------------------------------------
Map35_ScriptPtrTable:
    dw Map35_Script00       ; script 0
    dw Map35_Script01       ; script 1
    dw Map35_Script02       ; script 2
    dw Map35_Script03       ; script 3
; ---------------------------------------------------------------------------
; Map35_Script00
; ---------------------------------------------------------------------------
Map35_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map35_Script01
; ---------------------------------------------------------------------------
Map35_Script01:
    dw $0294                ; text $0294: "*:Wel...come..."
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map35_Script02
; ---------------------------------------------------------------------------
Map35_Script02:
    dw $0295                ; text $0295: "*:Come.....again.."
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map35_Script03
; ---------------------------------------------------------------------------
Map35_Script03:
    dw $0296                ; text $0296: "*:… … …"
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 55 (boss)
    dw $0037                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0297                ; text $0297: "*:… … …"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 4, curve 2  [$D8E3 := $0204]
    dw $D8E3                ;   address
    dw $0204                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 2: fly in down-left (the flight path set above)
    dw $1502                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0298                ; text $0298: "Watabou:This place was ruined by monster…"
    dw $FF1C                ; $1C trigger_anim: NPC 2: jump
    dw $0402                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 53  [$D9E3 := 53]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $0035                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0015
    dw $0015                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 6 → state 2  [$D93A := 2]
    dw $D93A                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Bazaar (MadKnight) screen 0 → state 1  [$D97B := 1]
    dw $D97B                ;   address
    dw $0001                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $002D is clear → Bank0E_ScriptAddr_557C
    dw $002D                ;   flag
    dw Bank0E_ScriptAddr_557C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00F6 is set → Bank0E_ScriptAddr_55A0
    dw $00F6                ;   flag
    dw Bank0E_ScriptAddr_55A0 ;   target
Bank0E_ScriptAddr_557C:
    dw $FF01                ; $01 if_flag_set: If flag $00F6 is set → Bank0E_ScriptAddr_5596
    dw $00F6                ;   flag
    dw Bank0E_ScriptAddr_5596 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00EE is set → Bank0E_ScriptAddr_558C
    dw $00EE                ;   flag
    dw Bank0E_ScriptAddr_558C ;   target
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_55AA
    dw Bank0E_ScriptAddr_55AA ;   target
Bank0E_ScriptAddr_558C:
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 6 → state 4  [$D93A := 4]
    dw $D93A                ;   address
    dw $0004                ;   value
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_55AA
    dw Bank0E_ScriptAddr_55AA ;   target
Bank0E_ScriptAddr_5596:
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 6 → state 6  [$D93A := 6]
    dw $D93A                ;   address
    dw $0006                ;   value
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_55AA
    dw Bank0E_ScriptAddr_55AA ;   target
Bank0E_ScriptAddr_55A0:
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 6 → state 8  [$D93A := 8]
    dw $D93A                ;   address
    dw $0008                ;   value
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_55AA
    dw Bank0E_ScriptAddr_55AA ;   target
Bank0E_ScriptAddr_55AA:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; BossPeace Per-Script Table (map_type=$36, 9 scripts)
; ---------------------------------------------------------------------------
BossPeace_ScriptPtrTable:
    dw BossPeace_Script00   ; script 0
    dw BossPeace_Script01   ; script 1
    dw BossPeace_Script02   ; script 2
    dw BossPeace_Script03   ; script 3
    dw BossPeace_Script04   ; script 4
    dw BossPeace_Script05   ; script 5
    dw BossPeace_Script06   ; script 6
    dw BossPeace_Script07   ; script 7
    dw BossPeace_Script08   ; script 8
; ---------------------------------------------------------------------------
; BossPeace_Script00
; ---------------------------------------------------------------------------
BossPeace_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossPeace_Script01
; ---------------------------------------------------------------------------
BossPeace_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $0016 is set → Bank0E_ScriptAddr_55FE
    dw $0016                ;   flag
    dw Bank0E_ScriptAddr_55FE ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00C2 is set → Bank0E_ScriptAddr_55FA
    dw $00C2                ;   flag
    dw Bank0E_ScriptAddr_55FA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00C1 is set → Bank0E_ScriptAddr_55F2
    dw $00C1                ;   flag
    dw Bank0E_ScriptAddr_55F2 ;   target
    dw $0299                ; text $0299: "[HERO] pulled the slot machine! The symb…"
    dw $FF03                ; $03 set_flag: Set flag $00C1
    dw $00C1                ;   flag
    dw $FFFF                ; END

Bank0E_ScriptAddr_55F2:
    dw $0311                ; text $0311: "[HERO] pulled the arm of the slot machin…"
    dw $FF03                ; $03 set_flag: Set flag $00C2
    dw $00C2                ;   flag
    dw $FFFF                ; END

Bank0E_ScriptAddr_55FA:
    dw $0312                ; text $0312: "The slot machine is out of order."
    dw $FFFF                ; END

Bank0E_ScriptAddr_55FE:
    dw $0313                ; text $0313: "There are 3 Slimes sleeping inside."
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossPeace_Script02
; ---------------------------------------------------------------------------
BossPeace_Script02:
    dw $FF01                ; $01 if_flag_set: If flag $0016 is set → Bank0E_ScriptAddr_5628
    dw $0016                ;   flag
    dw Bank0E_ScriptAddr_5628 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00C4 is set → Bank0E_ScriptAddr_5624
    dw $00C4                ;   flag
    dw Bank0E_ScriptAddr_5624 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00C3 is set → Bank0E_ScriptAddr_561C
    dw $00C3                ;   flag
    dw Bank0E_ScriptAddr_561C ;   target
    dw $0314                ; text $0314: "[HERO] pulled the slot machine! The reel…"
    dw $FF03                ; $03 set_flag: Set flag $00C3
    dw $00C3                ;   flag
    dw $FFFF                ; END

Bank0E_ScriptAddr_561C:
    dw $0315                ; text $0315: "[HERO] pulled the arm of the slot machin…"
    dw $FF03                ; $03 set_flag: Set flag $00C4
    dw $00C4                ;   flag
    dw $FFFF                ; END

Bank0E_ScriptAddr_5624:
    dw $0316                ; text $0316: "It's out of order."
    dw $FFFF                ; END

Bank0E_ScriptAddr_5628:
    dw $0317                ; text $0317: "3 Metalys are sweating inside the machin…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossPeace_Script03
; ---------------------------------------------------------------------------
BossPeace_Script03:
    dw $FF01                ; $01 if_flag_set: If flag $0016 is set → Bank0E_ScriptAddr_5644
    dw $0016                ;   flag
    dw Bank0E_ScriptAddr_5644 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00C5 is set → Bank0E_ScriptAddr_5640
    dw $00C5                ;   flag
    dw Bank0E_ScriptAddr_5640 ;   target
    dw $0318                ; text $0318: "[HERO] pulled the arm of the slot machin…"
    dw $FF03                ; $03 set_flag: Set flag $00C5
    dw $00C5                ;   flag
    dw $FFFF                ; END

Bank0E_ScriptAddr_5640:
    dw $0319                ; text $0319: "The reel is spinning..."
    dw $FFFF                ; END

Bank0E_ScriptAddr_5644:
    dw $0843                ; text $0843: "Slot is beaten."
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossPeace_Script04
; ---------------------------------------------------------------------------
BossPeace_Script04:
    dw $FF01                ; $01 if_flag_set: If flag $0016 is set → Bank0E_ScriptAddr_5660
    dw $0016                ;   flag
    dw Bank0E_ScriptAddr_5660 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00C6 is set → Bank0E_ScriptAddr_565C
    dw $00C6                ;   flag
    dw Bank0E_ScriptAddr_565C ;   target
    dw $031A                ; text $031A: "[HERO] pulled the slot machine! The reel…"
    dw $FF03                ; $03 set_flag: Set flag $00C6
    dw $00C6                ;   flag
    dw $FFFF                ; END

Bank0E_ScriptAddr_565C:
    dw $0322                ; text $0322: "There is a sign on the slot machine. :No…"
    dw $FFFF                ; END

Bank0E_ScriptAddr_5660:
    dw $0323                ; text $0323: "There is a sign on the slot machine. :No…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossPeace_Script05
; ---------------------------------------------------------------------------
BossPeace_Script05:
    dw $0324                ; text $0324: "*:Welcome to the Casino! Gold here is on…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossPeace_Script06
; ---------------------------------------------------------------------------
BossPeace_Script06:
    dw $FF01                ; $01 if_flag_set: If flag $0016 is set → Bank0E_ScriptAddr_5672
    dw $0016                ;   flag
    dw Bank0E_ScriptAddr_5672 ;   target
    dw $0325                ; text $0325: "*:How's your luck?"
    dw $FFFF                ; END

Bank0E_ScriptAddr_5672:
    dw $0326                ; text $0326: "*:I need to get good at it."
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossPeace_Script07
; ---------------------------------------------------------------------------
BossPeace_Script07:
    dw $FF01                ; $01 if_flag_set: If flag $0016 is set → Bank0E_ScriptAddr_5680
    dw $0016                ;   flag
    dw Bank0E_ScriptAddr_5680 ;   target
    dw $0327                ; text $0327: "*:That customer has an attitude! *:Can y…"
    dw $FFFF                ; END

Bank0E_ScriptAddr_5680:
    dw $0328                ; text $0328: "*:No violence in this store."
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossPeace_Script08
; ---------------------------------------------------------------------------
BossPeace_Script08:
    dw $FF01                ; $01 if_flag_set: If flag $00C7 is set → Bank0E_ScriptAddr_574A
    dw $00C7                ;   flag
    dw Bank0E_ScriptAddr_574A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00C6 is set → Bank0E_ScriptAddr_5694
    dw $00C6                ;   flag
    dw Bank0E_ScriptAddr_5694 ;   target
    dw $0329                ; text $0329: "*:Gwrrrrrrrr.. This machine gave me noth…"
    dw $FFFF                ; END

Bank0E_ScriptAddr_5694:
    dw $032A                ; text $032A: "*:Gwrrrrrrrr.. Why are you the only luck…"
    dw $FF03                ; $03 set_flag: Set flag $00C7
    dw $00C7                ;   flag
Bank0E_ScriptAddr_569A:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 75 (boss)
    dw $004B                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0346                ; text $0346: "*:No luck today! *:Hey, you don't have a…"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 4: stands still (status cleared)  [slot +$05 := $00]
    dw $0004                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 5 is shown
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 4, curve 3  [$D8E3 := $0304]
    dw $D8E3                ;   address
    dw $0304                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 5: fly in down-right (the flight path set above)
    dw $1605                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 5 faces up
    dw $0005                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 5 faces left
    dw $0005                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 5 faces down
    dw $0005                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 5 faces right
    dw $0005                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0347                ; text $0347: "Watabou:Did you have a good time at the …"
    dw $FF1C                ; $1C trigger_anim: NPC 5: jump
    dw $0405                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 5 faces up
    dw $0005                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 5 faces left
    dw $0005                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 5 faces down
    dw $0005                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF4A                ; $4A face_right: NPC 5 faces right
    dw $0005                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 54  [$D9E3 := 54]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $0036                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0016
    dw $0016                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Room: Peace/Bravery screen 0 → state 1  [$D96B := 1]
    dw $D96B                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Peace (FangSlime) screen 0 → state 1  [$D97C := 1]
    dw $D97C                ;   address
    dw $0001                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $0017 is clear → Bank0E_ScriptAddr_573E
    dw $0017                ;   flag
    dw Bank0E_ScriptAddr_573E ;   target
    dw $FF12                ; $12 write_ram: Room state of Room: Peace/Bravery screen 0 → state 3  [$D96B := 3]
    dw $D96B                ;   address
    dw $0003                ;   value
Bank0E_ScriptAddr_573E:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0E_ScriptAddr_574A:
    dw $032B                ; text $032B: "*:It's mine now!!"
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_569A
    dw Bank0E_ScriptAddr_569A ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; BossBravery Per-Script Table (map_type=$37, 5 scripts)
; ---------------------------------------------------------------------------
BossBravery_ScriptPtrTable:
    dw BossBravery_Script00 ; script 0
    dw BossBravery_Script01 ; script 1
    dw BossBravery_Script02 ; script 2
    dw BossBravery_Script03 ; script 3
    dw BossBravery_Script04 ; script 4
; ---------------------------------------------------------------------------
; BossBravery_Script00
; ---------------------------------------------------------------------------
BossBravery_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF15                ; $15 check_and_branch: If “the party is falling through a hole” is yes  (meaning inferred from the scripts that use it) → Bank0E_ScriptAddr_5774  [$D9E5 = 1]
    dw $D9E5                ;   address
    dw $0001                ;   value
    dw Bank0E_ScriptAddr_5774 ;   target
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0E_ScriptAddr_5774:
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks down 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks down 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks down 1 tile
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 4 is shown
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 4 tiles
    dw $0001                ;   actor
    dw $0040                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks down 5 tiles
    dw $0002                ;   actor
    dw $0050                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks down 6 tiles
    dw $0003                ;   actor
    dw $0060                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks down 7 tiles
    dw $0004                ;   actor
    dw $0070                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 1 is hidden
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is hidden
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 4 is hidden
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: The party is falling through a hole: no  [$D9E5 := 0]  (meaning inferred from the scripts that use it)
    dw $D9E5                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossBravery_Script01
; ---------------------------------------------------------------------------
BossBravery_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $00C9 is set → Bank0E_ScriptAddr_58D4
    dw $00C9                ;   flag
    dw Bank0E_ScriptAddr_58D4 ;   target
    dw $03F6                ; text $03F6: "*:There are cliffs that you can jump dow…"
    dw $FF03                ; $03 set_flag: Set flag $00C9
    dw $00C9                ;   flag
Bank0E_ScriptAddr_5824:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 77 (boss)
    dw $004D                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $051C                ; text $051C: "*:There are cliffs that we can jump off …"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 5: stands still (status cleared)  [slot +$05 := $00]
    dw $0005                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 7 is shown
    dw $0007                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 6, curve 4  [$D8E3 := $0406]
    dw $D8E3                ;   address
    dw $0406                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 7: fly in down-left (the flight path set above)
    dw $1507                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 7 faces left
    dw $0007                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 7 faces down
    dw $0007                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 7 faces right
    dw $0007                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 7 faces up
    dw $0007                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $051D                ; text $051D: "Watabou:Good job finding the invisible f…"
    dw $FF1C                ; $1C trigger_anim: NPC 7: jump
    dw $0407                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 7 faces left
    dw $0007                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 7 faces down
    dw $0007                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 7 faces right
    dw $0007                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF47                ; $47 face_up: NPC 7 faces up
    dw $0007                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 55  [$D9E3 := 55]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $0037                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0017
    dw $0017                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Room: Peace/Bravery screen 0 → state 2  [$D96B := 2]
    dw $D96B                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Bravery (BigEye) screen 0 → state 1  [$D97D := 1]
    dw $D97D                ;   address
    dw $0001                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $0016 is clear → Bank0E_ScriptAddr_58C8
    dw $0016                ;   flag
    dw Bank0E_ScriptAddr_58C8 ;   target
    dw $FF12                ; $12 write_ram: Room state of Room: Peace/Bravery screen 0 → state 3  [$D96B := 3]
    dw $D96B                ;   address
    dw $0003                ;   value
Bank0E_ScriptAddr_58C8:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0E_ScriptAddr_58D4:
    dw $0467                ; text $0467: "*:You came back again. I wonder if you h…"
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_5824
    dw Bank0E_ScriptAddr_5824 ;   target
; ---------------------------------------------------------------------------
; BossBravery_Script02
; ---------------------------------------------------------------------------
BossBravery_Script02:
    dw $FF01                ; $01 if_flag_set: If flag $00AA is set → Bank0E_ScriptAddr_59B0
    dw $00AA                ;   flag
    dw Bank0E_ScriptAddr_59B0 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00C8 is set → Bank0E_ScriptAddr_59B0
    dw $00C8                ;   flag
    dw Bank0E_ScriptAddr_59B0 ;   target
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF48                ; $48 face_down: NPC 5 faces down
    dw $0005                ;   actor
    dw $FF47                ; $47 face_up: NPC 6 faces up
    dw $0006                ;   actor
    dw $FF0D                ; $0D npc_write: NPC 6 is shown
    dw $0006                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0B                ; $0B walk_y_wait: NPC 6 walks up 1 tile (script waits)
    dw $0006                ;   actor
    dw $FFF0                ;   pixels
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 6: animation frozen (kept out of the animation picker)  [slot +$05 := $80]
    dw $0006                ;   actor
    dw $0005                ;   field
    dw $0080                ;   value
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF1C                ; $1C trigger_anim: NPC 6: leap up 4 tiles
    dw $0F06                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF0D                ; $0D npc_write: NPC 6: stands still (status cleared)  [slot +$05 := $00]
    dw $0006                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0B                ; $0B walk_y_wait: NPC 6 walks up 1 tile (script waits)
    dw $0006                ;   actor
    dw $FFF0                ;   pixels
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF4A                ; $4A face_right: NPC 6 faces right
    dw $0006                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF47                ; $47 face_up: NPC 6 faces up
    dw $0006                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 5: hop
    dw $0105                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF49                ; $49 face_left: NPC 5 faces left
    dw $0005                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF4A                ; $4A face_right: NPC 5 faces right
    dw $0005                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF49                ; $49 face_left: NPC 5 faces left
    dw $0005                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF4A                ; $4A face_right: NPC 5 faces right
    dw $0005                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF48                ; $48 face_down: NPC 5 faces down
    dw $0005                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF48                ; $48 face_down: NPC 6 faces down
    dw $0006                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $03F5                ; text $03F5: "*:Tut! Not in here either!"
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF0B                ; $0B walk_y_wait: NPC 6 walks down 1 tile (script waits)
    dw $0006                ;   actor
    dw $0010                ;   pixels
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 6: animation frozen (kept out of the animation picker)  [slot +$05 := $80]
    dw $0006                ;   actor
    dw $0005                ;   field
    dw $0080                ;   value
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF1C                ; $1C trigger_anim: NPC 6: hop, then drop 4 tiles
    dw $1006                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF0D                ; $0D npc_write: NPC 6: stands still (status cleared)  [slot +$05 := $00]
    dw $0006                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0B                ; $0B walk_y_wait: NPC 6 walks down 1 tile (script waits)
    dw $0006                ;   actor
    dw $0010                ;   pixels
    dw $FF0D                ; $0D npc_write: NPC 6 is hidden
    dw $0006                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF03                ; $03 set_flag: Set flag $00C8
    dw $00C8                ;   flag
    dw $FFFF                ; END

Bank0E_ScriptAddr_59B0:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; BossBravery_Script03
; ---------------------------------------------------------------------------
BossBravery_Script03:
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $55
    dw $0055                ;   sound
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry hidden  [$C8ED := 1]
    dw $C8ED                ;   address
    dw $0001                ;   value
    dw $FF0A                ; $0A walk_x_wait: the player walks left 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monster 1 hidden  [$C8ED := 3]
    dw $C8ED                ;   address
    dw $0003                ;   value
    dw $FF0A                ; $0A walk_x_wait: the player walks left 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monsters 1-2 hidden  [$C8ED := 7]
    dw $C8ED                ;   address
    dw $0007                ;   value
    dw $FF0A                ; $0A walk_x_wait: the player walks left 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry and all monsters hidden  [$C8ED := 15]
    dw $C8ED                ;   address
    dw $000F                ;   value
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF12                ; $12 write_ram: The party is falling through a hole: yes  [$D9E5 := 1]  (meaning inferred from the scripts that use it)
    dw $D9E5                ;   address
    dw $0001                ;   value
    dw $FF0F                ; $0F map_transition: Go to Boss: Bravery (BigEye) at (5, 7)
    dw $0037                ;   map
    dw $0058                ;   x
    dw $0078                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; BossBravery_Script04
; ---------------------------------------------------------------------------
BossBravery_Script04:
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $55
    dw $0055                ;   sound
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry hidden  [$C8ED := 1]
    dw $C8ED                ;   address
    dw $0001                ;   value
    dw $FF0A                ; $0A walk_x_wait: the player walks right 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monster 1 hidden  [$C8ED := 3]
    dw $C8ED                ;   address
    dw $0003                ;   value
    dw $FF0A                ; $0A walk_x_wait: the player walks right 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monsters 1-2 hidden  [$C8ED := 7]
    dw $C8ED                ;   address
    dw $0007                ;   value
    dw $FF0A                ; $0A walk_x_wait: the player walks right 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry and all monsters hidden  [$C8ED := 15]
    dw $C8ED                ;   address
    dw $000F                ;   value
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF12                ; $12 write_ram: The party is falling through a hole: yes  [$D9E5 := 1]  (meaning inferred from the scripts that use it)
    dw $D9E5                ;   address
    dw $0001                ;   value
    dw $FF0F                ; $0F map_transition: Go to Boss: Bravery (BigEye) at (5, 7)
    dw $0037                ;   map
    dw $0058                ;   x
    dw $0078                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map38 Per-Script Table (map_type=$38, 17 scripts)
; ---------------------------------------------------------------------------
Map38_ScriptPtrTable:
    dw Map38_Script00       ; script 0
    dw Map38_Script01       ; script 1
    dw Map38_Script02       ; script 2
    dw Map38_Script03       ; script 3
    dw Map38_Script04       ; script 4
    dw Map38_Script05       ; script 5
    dw Map38_Script06       ; script 6
    dw Map38_Script07       ; script 7
    dw Map38_Script08       ; script 8
    dw Map38_Script09       ; script 9
    dw Map38_Script10       ; script 10
    dw Map38_Script11       ; script 11
    dw Map38_Script12       ; script 12
    dw Map38_Script13       ; script 13
    dw Map38_Script14       ; script 14
    dw Map38_Script15       ; script 15
    dw Map38_Script16       ; script 16
; ---------------------------------------------------------------------------
; Map38_Script00
; ---------------------------------------------------------------------------
Map38_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF15                ; $15 check_and_branch: If “the party is falling through a hole” is yes  (meaning inferred from the scripts that use it) → Bank0E_ScriptAddr_5A88  [$D9E5 = 1]
    dw $D9E5                ;   address
    dw $0001                ;   value
    dw Bank0E_ScriptAddr_5A88 ;   target
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0E_ScriptAddr_5A88:
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks down 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks down 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks down 1 tile
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 4 is shown
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks down 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks down 2 tiles
    dw $0003                ;   actor
    dw $0020                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks down 3 tiles
    dw $0004                ;   actor
    dw $0030                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 1 is hidden
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is hidden
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 4 is hidden
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: The party is falling through a hole: no  [$D9E5 := 0]  (meaning inferred from the scripts that use it)
    dw $D9E5                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map38_Script01
; ---------------------------------------------------------------------------
Map38_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $00CA is set → Bank0E_ScriptAddr_5BD6
    dw $00CA                ;   flag
    dw Bank0E_ScriptAddr_5BD6 ;   target
    dw $051E                ; text $051E: "*:Wow! Yummy meat! Yum!"
    dw $FF03                ; $03 set_flag: Set flag $00CA
    dw $00CA                ;   flag
Bank0E_ScriptAddr_5B32:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 79 (boss)
    dw $004F                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0520                ; text $0520: "*:Wow! I'll do anything for the meat!"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 6: stands still (status cleared)  [slot +$05 := $00]
    dw $0006                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 7 is shown
    dw $0007                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 8, curve 3  [$D8E3 := $0308]
    dw $D8E3                ;   address
    dw $0308                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 7: fly in down-right (the flight path set above)
    dw $1607                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 7 faces left
    dw $0007                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 7 faces up
    dw $0007                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 7 faces right
    dw $0007                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 7 faces down
    dw $0007                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0521                ; text $0521: "Watabou:It seems you had a hard time in …"
    dw $FF1C                ; $1C trigger_anim: NPC 7: jump
    dw $0407                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 7 faces left
    dw $0007                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 7 faces up
    dw $0007                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 7 faces right
    dw $0007                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF48                ; $48 face_down: NPC 7 faces down
    dw $0007                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 56  [$D9E3 := 56]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $0038                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0018
    dw $0018                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Well screen 4 → state 2  [$D960 := 2]
    dw $D960                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Well (Gigantes) screen 0 → state 1  [$D97E := 1]
    dw $D97E                ;   address
    dw $0001                ;   value
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0E_ScriptAddr_5BD6:
    dw $051F                ; text $051F: "*:Wow, yummy meat comming this way again…"
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_5B32
    dw Bank0E_ScriptAddr_5B32 ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map38_Script02
; ---------------------------------------------------------------------------
Map38_Script02:
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5C9C)
    dw Bank0E_ScriptAddr_5C9C ;   data
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_5C4E
    dw Bank0E_ScriptAddr_5C4E ;   target
; ---------------------------------------------------------------------------
; Map38_Script03
; ---------------------------------------------------------------------------
Map38_Script03:
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5CA4)
    dw Bank0E_ScriptAddr_5CA4 ;   data
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_5C4E
    dw Bank0E_ScriptAddr_5C4E ;   target
; ---------------------------------------------------------------------------
; Map38_Script04
; ---------------------------------------------------------------------------
Map38_Script04:
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5CAC)
    dw Bank0E_ScriptAddr_5CAC ;   data
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_5C4E
    dw Bank0E_ScriptAddr_5C4E ;   target
; ---------------------------------------------------------------------------
; Map38_Script05
; ---------------------------------------------------------------------------
Map38_Script05:
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5CB4)
    dw Bank0E_ScriptAddr_5CB4 ;   data
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_5C4E
    dw Bank0E_ScriptAddr_5C4E ;   target
; ---------------------------------------------------------------------------
; Map38_Script06
; ---------------------------------------------------------------------------
Map38_Script06:
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5CBC)
    dw Bank0E_ScriptAddr_5CBC ;   data
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_5C4E
    dw Bank0E_ScriptAddr_5C4E ;   target
; ---------------------------------------------------------------------------
; Map38_Script07
; ---------------------------------------------------------------------------
Map38_Script07:
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5CC4)
    dw Bank0E_ScriptAddr_5CC4 ;   data
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_5C4E
    dw Bank0E_ScriptAddr_5C4E ;   target
; ---------------------------------------------------------------------------
; Map38_Script08
; ---------------------------------------------------------------------------
Map38_Script08:
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5CCC)
    dw Bank0E_ScriptAddr_5CCC ;   data
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_5C4E
    dw Bank0E_ScriptAddr_5C4E ;   target
; ---------------------------------------------------------------------------
; Map38_Script09
; ---------------------------------------------------------------------------
Map38_Script09:
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5CD4)
    dw Bank0E_ScriptAddr_5CD4 ;   data
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_5C4E
    dw Bank0E_ScriptAddr_5C4E ;   target
; ---------------------------------------------------------------------------
; Map38_Script10
; ---------------------------------------------------------------------------
Map38_Script10:
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5CDC)
    dw Bank0E_ScriptAddr_5CDC ;   data
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_5C4E
    dw Bank0E_ScriptAddr_5C4E ;   target
; ---------------------------------------------------------------------------
; Map38_Script11
; ---------------------------------------------------------------------------
Map38_Script11:
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5CE4)
    dw Bank0E_ScriptAddr_5CE4 ;   data
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_5C4E
    dw Bank0E_ScriptAddr_5C4E ;   target
; ---------------------------------------------------------------------------
; Map38_Script12
; ---------------------------------------------------------------------------
Map38_Script12:
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5CEC)
    dw Bank0E_ScriptAddr_5CEC ;   data
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_5C4E
    dw Bank0E_ScriptAddr_5C4E ;   target
; ---------------------------------------------------------------------------
; Map38_Script13
; ---------------------------------------------------------------------------
Map38_Script13:
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5CF4)
    dw Bank0E_ScriptAddr_5CF4 ;   data
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_5C4E
    dw Bank0E_ScriptAddr_5C4E ;   target
; ---------------------------------------------------------------------------
; Map38_Script14
; ---------------------------------------------------------------------------
Map38_Script14:
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5CFC)
    dw Bank0E_ScriptAddr_5CFC ;   data
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_5C4E
    dw Bank0E_ScriptAddr_5C4E ;   target
; ---------------------------------------------------------------------------
; Map38_Script15
; ---------------------------------------------------------------------------
Map38_Script15:
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5D04)
    dw Bank0E_ScriptAddr_5D04 ;   data
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_5C4E
    dw Bank0E_ScriptAddr_5C4E ;   target
Bank0E_ScriptAddr_5C4E:
    dw $FF21                ; $21 sound: Sound effect $55
    dw $0055                ;   sound
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry hidden  [$C8ED := 1]
    dw $C8ED                ;   address
    dw $0001                ;   value
    dw $FF0A                ; $0A walk_x_wait: the player walks left 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monster 1 hidden  [$C8ED := 3]
    dw $C8ED                ;   address
    dw $0003                ;   value
    dw $FF0A                ; $0A walk_x_wait: the player walks right 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monsters 1-2 hidden  [$C8ED := 7]
    dw $C8ED                ;   address
    dw $0007                ;   value
    dw $FF0A                ; $0A walk_x_wait: the player walks left 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry and all monsters hidden  [$C8ED := 15]
    dw $C8ED                ;   address
    dw $000F                ;   value
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF12                ; $12 write_ram: The party is falling through a hole: yes  [$D9E5 := 1]  (meaning inferred from the scripts that use it)
    dw $D9E5                ;   address
    dw $0001                ;   value
    dw $FF0F                ; $0F map_transition: Go to Boss: Well (Gigantes) at (8, 3)
    dw $0038                ;   map
    dw $0088                ;   x
    dw $0038                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0E_ScriptAddr_5C9C:
    db $08, $00, $54, $55, $D8, $56, $57, $D9  ; tile patch (op $24): BG offset $0008 (row 0, column 8), tiles 54 55 / 56 57; $D8 = next row, $D9 = end
Bank0E_ScriptAddr_5CA4:
    db $0A, $00, $54, $55, $D8, $56, $57, $D9  ; tile patch (op $24): BG offset $000A (row 0, column 10), tiles 54 55 / 56 57; $D8 = next row, $D9 = end
Bank0E_ScriptAddr_5CAC:
    db $0C, $00, $54, $55, $D8, $56, $57, $D9  ; tile patch (op $24): BG offset $000C (row 0, column 12), tiles 54 55 / 56 57; $D8 = next row, $D9 = end
Bank0E_ScriptAddr_5CB4:
    db $42, $00, $54, $55, $D8, $56, $57, $D9  ; tile patch (op $24): BG offset $0042 (row 2, column 2), tiles 54 55 / 56 57; $D8 = next row, $D9 = end
Bank0E_ScriptAddr_5CBC:
    db $8A, $00, $54, $55, $D8, $56, $57, $D9  ; tile patch (op $24): BG offset $008A (row 4, column 10), tiles 54 55 / 56 57; $D8 = next row, $D9 = end
Bank0E_ScriptAddr_5CC4:
    db $90, $00, $54, $55, $D8, $56, $57, $D9  ; tile patch (op $24): BG offset $0090 (row 4, column 16), tiles 54 55 / 56 57; $D8 = next row, $D9 = end
Bank0E_ScriptAddr_5CCC:
    db $04, $01, $54, $55, $D8, $56, $57, $D9  ; tile patch (op $24): BG offset $0104 (row 8, column 4), tiles 54 55 / 56 57; $D8 = next row, $D9 = end
Bank0E_ScriptAddr_5CD4:
    db $06, $01, $54, $55, $D8, $56, $57, $D9  ; tile patch (op $24): BG offset $0106 (row 8, column 6), tiles 54 55 / 56 57; $D8 = next row, $D9 = end
Bank0E_ScriptAddr_5CDC:
    db $08, $01, $54, $55, $D8, $56, $57, $D9  ; tile patch (op $24): BG offset $0108 (row 8, column 8), tiles 54 55 / 56 57; $D8 = next row, $D9 = end
Bank0E_ScriptAddr_5CE4:
    db $0E, $01, $54, $55, $D8, $56, $57, $D9  ; tile patch (op $24): BG offset $010E (row 8, column 14), tiles 54 55 / 56 57; $D8 = next row, $D9 = end
Bank0E_ScriptAddr_5CEC:
    db $10, $01, $54, $55, $D8, $56, $57, $D9  ; tile patch (op $24): BG offset $0110 (row 8, column 16), tiles 54 55 / 56 57; $D8 = next row, $D9 = end
Bank0E_ScriptAddr_5CF4:
    db $4E, $01, $54, $55, $D8, $56, $57, $D9  ; tile patch (op $24): BG offset $014E (row 10, column 14), tiles 54 55 / 56 57; $D8 = next row, $D9 = end
Bank0E_ScriptAddr_5CFC:
    db $82, $01, $54, $55, $D8, $56, $57, $D9  ; tile patch (op $24): BG offset $0182 (row 12, column 2), tiles 54 55 / 56 57; $D8 = next row, $D9 = end
Bank0E_ScriptAddr_5D04:
    db $8A, $01, $54, $55, $D8, $56, $57, $D9  ; tile patch (op $24): BG offset $018A (row 12, column 10), tiles 54 55 / 56 57; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map38_Script16
; ---------------------------------------------------------------------------
Map38_Script16:
    dw $FF15                ; $15 check_and_branch: If “the Well boss's tile event seen” is not yet  (meaning inferred from the scripts that use it) → Bank0E_ScriptAddr_5D1C  [$D9E4 = 0]
    dw $D9E4                ;   address
    dw $0000                ;   value
    dw Bank0E_ScriptAddr_5D1C ;   target
    dw $FF00                ; $00 if_flag_clear: If flag $00CB is clear → Bank0E_ScriptAddr_5D1C
    dw $00CB                ;   flag
    dw Bank0E_ScriptAddr_5D1C ;   target
    dw $FFFF                ; END

Bank0E_ScriptAddr_5D1C:
    dw $FF0D                ; $0D npc_write: NPC 5 is shown
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 5 walks down 3 tiles
    dw $0005                ;   actor
    dw $0030                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 6 ticks (~48 frames)
    dw $0006                ;   ticks
    dw $FF4A                ; $4A face_right: NPC 5 faces right
    dw $0005                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF48                ; $48 face_down: NPC 5 faces down
    dw $0005                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF49                ; $49 face_left: NPC 5 faces left
    dw $0005                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF48                ; $48 face_down: NPC 5 faces down
    dw $0005                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF4A                ; $4A face_right: NPC 5 faces right
    dw $0005                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF48                ; $48 face_down: NPC 5 faces down
    dw $0005                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0A                ; $0A walk_x_wait: NPC 5 walks left 1 tile (script waits)
    dw $0005                ;   actor
    dw $FFF0                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: NPC 5 walks down 2 tiles (script waits)
    dw $0005                ;   actor
    dw $0020                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: NPC 5 walks right 1 tile (script waits)
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF09                ; $09 delay: Wait 6 ticks (~48 frames)
    dw $0006                ;   ticks
    dw $FF4A                ; $4A face_right: NPC 5 faces right
    dw $0005                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF48                ; $48 face_down: NPC 5 faces down
    dw $0005                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF4A                ; $4A face_right: NPC 5 faces right
    dw $0005                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF47                ; $47 face_up: NPC 5 faces up
    dw $0005                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF4A                ; $4A face_right: NPC 5 faces right
    dw $0005                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF48                ; $48 face_down: NPC 5 faces down
    dw $0005                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF4A                ; $4A face_right: NPC 5 faces right
    dw $0005                ;   actor
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0A                ; $0A walk_x_wait: NPC 5 walks left 1 tile (script waits)
    dw $0005                ;   actor
    dw $FFF0                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: NPC 5 walks up 2 tiles (script waits)
    dw $0005                ;   actor
    dw $FFE0                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: NPC 5 walks right 3 tiles (script waits)
    dw $0005                ;   actor
    dw $0030                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: NPC 5 walks up 1 tile (script waits)
    dw $0005                ;   actor
    dw $FFF0                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: NPC 5 walks right 1 tile (script waits)
    dw $0005                ;   actor
    dw $0010                ;   pixels
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $5CBC)
    dw Bank0E_ScriptAddr_5CBC ;   data
    dw $FF4D                ; $4D long_delay: Wait 10 frames
    dw $000A                ;   frames
    dw $FF48                ; $48 face_down: NPC 5 faces down
    dw $0005                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 32 frames
    dw $0020                ;   frames
    dw $FF49                ; $49 face_left: NPC 5 faces left
    dw $0005                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 10 frames
    dw $000A                ;   frames
    dw $FF48                ; $48 face_down: NPC 5 faces down
    dw $0005                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 10 frames
    dw $000A                ;   frames
    dw $FF4A                ; $4A face_right: NPC 5 faces right
    dw $0005                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 10 frames
    dw $000A                ;   frames
    dw $FF48                ; $48 face_down: NPC 5 faces down
    dw $0005                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF0D                ; $0D npc_write: NPC 5: animation frozen (kept out of the animation picker)  [slot +$05 := $80]
    dw $0005                ;   actor
    dw $0005                ;   field
    dw $0080                ;   value
    dw $FF09                ; $09 delay: Wait 6 ticks (~48 frames)
    dw $0006                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $55
    dw $0055                ;   sound
    dw $FF0D                ; $0D npc_write: NPC 5 is hidden
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 16 ticks (~128 frames)
    dw $0010                ;   ticks
    dw $FF12                ; $12 write_ram: The Well boss's tile event seen: seen  [$D9E4 := 1]  (meaning inferred from the scripts that use it)
    dw $D9E4                ;   address
    dw $0001                ;   value
    dw $FF03                ; $03 set_flag: Set flag $00CB
    dw $00CB                ;   flag
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map39 Per-Script Table (map_type=$39, 5 scripts)
; ---------------------------------------------------------------------------
Map39_ScriptPtrTable:
    dw Map39_Script00       ; script 0
    dw Map39_Script01       ; script 1
    dw Map39_Script02       ; script 2
    dw Map39_Script03       ; script 3
    dw Map39_Script04       ; script 4
; ---------------------------------------------------------------------------
; Map39_Script00
; ---------------------------------------------------------------------------
Map39_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 1: animation frozen (kept out of the animation picker)  [slot +$05 := $80]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0080                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map39_Script01
; ---------------------------------------------------------------------------
Map39_Script01:
    dw $0523                ; text $0523: "[HERO] looked into a jar. There was a da…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map39_Script02
; ---------------------------------------------------------------------------
Map39_Script02:
    dw $0522                ; text $0522: "[HERO] checked out a treasure chest! Wow…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map39_Script03
; ---------------------------------------------------------------------------
Map39_Script03:
    dw $FF00                ; $00 if_flag_clear: If flag $00CC is clear → Bank0E_ScriptAddr_5E5C
    dw $00CC                ;   flag
    dw Bank0E_ScriptAddr_5E5C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00CD is set → Bank0E_ScriptAddr_5F1E
    dw $00CD                ;   flag
    dw Bank0E_ScriptAddr_5F1E ;   target
Bank0E_ScriptAddr_5E5C:
    dw $FF01                ; $01 if_flag_set: If flag $00CD is set → Bank0E_ScriptAddr_5F1A
    dw $00CD                ;   flag
    dw Bank0E_ScriptAddr_5F1A ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00CC is set → Bank0E_ScriptAddr_5E6C
    dw $00CC                ;   flag
    dw Bank0E_ScriptAddr_5E6C ;   target
    dw $0524                ; text $0524: "*:......"
    dw $FFFF                ; END

Bank0E_ScriptAddr_5E6C:
    dw $0525                ; text $0525: "*:So,yoooou saaaw my face...!!"
    dw $FF03                ; $03 set_flag: Set flag $00CD
    dw $00CD                ;   flag
    dw $FF02                ; $02 clear_flag: Clear flag $00CC
    dw $00CC                ;   flag
Bank0E_ScriptAddr_5E76:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 99 (boss)
    dw $0063                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0527                ; text $0527: "*:Yoooou win...!!"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 8, curve 3  [$D8E3 := $0308]
    dw $D8E3                ;   address
    dw $0308                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 2: fly in down-left (the flight path set above)
    dw $1502                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0528                ; text $0528: "Watabou:Good work! So,let's gooooo baaac…"
    dw $FF1C                ; $1C trigger_anim: NPC 2: jump
    dw $0402                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 57  [$D9E3 := 57]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $0039                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0019
    dw $0019                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Room: Strength/Anger screen 0 → state 2  [$D96C := 2]
    dw $D96C                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Strength (StoneMan) screen 0 → state 1  [$D97F := 1]
    dw $D97F                ;   address
    dw $0001                ;   value
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0E_ScriptAddr_5F1A:
    dw $0524                ; text $0524: "*:......"
    dw $FFFF                ; END

Bank0E_ScriptAddr_5F1E:
    dw $0526                ; text $0526: "*:It's yoooou agaaaain!"
    dw $FF02                ; $02 clear_flag: Clear flag $00CC
    dw $00CC                ;   flag
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_5E76
    dw Bank0E_ScriptAddr_5E76 ;   target
; ---------------------------------------------------------------------------
; Map39_Script04
; ---------------------------------------------------------------------------
Map39_Script04:
    dw $FF01                ; $01 if_flag_set: If flag $00CC is set → Bank0E_ScriptAddr_5F48
    dw $00CC                ;   flag
    dw Bank0E_ScriptAddr_5F48 ;   target
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF10                ; $10 walk_to_x: NPC 1 walks to x = 56 px (script waits)
    dw $0001                ;   actor
    dw $0038                ;   x
    dw $FF11                ; $11 walk_to_y: NPC 1 walks to y = 88 px (script waits)
    dw $0001                ;   actor
    dw $0058                ;   y
    dw $FF03                ; $03 set_flag: Set flag $00CC
    dw $00CC                ;   flag
Bank0E_ScriptAddr_5F48:
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map3A Per-Script Table (map_type=$3A, 9 scripts)
; ---------------------------------------------------------------------------
Map3A_ScriptPtrTable:
    dw Map3A_Script00       ; script 0
    dw Map3A_Script01       ; script 1
    dw Map3A_Script02       ; script 2
    dw Map3A_Script03       ; script 3
    dw Map3A_Script04       ; script 4
    dw Map3A_Script05       ; script 5
    dw Map3A_Script06       ; script 6
    dw Map3A_Script07       ; script 7
    dw Map3A_Script08       ; script 8
; ---------------------------------------------------------------------------
; Map3A_Script00
; ---------------------------------------------------------------------------
Map3A_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF15                ; $15 check_and_branch: If “the party is falling through a hole” is yes  (meaning inferred from the scripts that use it) → Bank0E_ScriptAddr_5F74  [$D9E5 = 1]
    dw $D9E5                ;   address
    dw $0001                ;   value
    dw Bank0E_ScriptAddr_5F74 ;   target
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

Bank0E_ScriptAddr_5F74:
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks down 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 3 is shown
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks down 1 tile
    dw $0002                ;   actor
    dw $0010                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks down 1 tile
    dw $0003                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 4 is shown
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 4 tiles
    dw $0001                ;   actor
    dw $0040                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 2 walks down 5 tiles
    dw $0002                ;   actor
    dw $0050                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 3 walks down 6 tiles
    dw $0003                ;   actor
    dw $0060                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks down 7 tiles
    dw $0004                ;   actor
    dw $0070                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 1 is hidden
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is hidden
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3 is hidden
    dw $0003                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 4 is hidden
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF12                ; $12 write_ram: The party is falling through a hole: no  [$D9E5 := 0]  (meaning inferred from the scripts that use it)
    dw $D9E5                ;   address
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map3A_Script01
; ---------------------------------------------------------------------------
Map3A_Script01:
    dw $0529                ; text $0529: "*:Squeak squeak! Strike!"
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 125 (boss)
    dw $007D                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $052A                ; text $052A: "*:Good lord, You're good!"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 5: stands still (status cleared)  [slot +$05 := $00]
    dw $0005                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 6 is shown
    dw $0006                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 5, curve 1  [$D8E3 := $0105]
    dw $D8E3                ;   address
    dw $0105                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 6: fly in down-left (the flight path set above)
    dw $1506                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 6 faces left
    dw $0006                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 6 faces up
    dw $0006                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 6 faces right
    dw $0006                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 6 faces down
    dw $0006                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $052B                ; text $052B: "Watabou:Good work reading SkyDragon's mo…"
    dw $FF1C                ; $1C trigger_anim: NPC 6: jump
    dw $0406                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 6 faces left
    dw $0006                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 6 faces up
    dw $0006                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 6 faces right
    dw $0006                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF48                ; $48 face_down: NPC 6 faces down
    dw $0006                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 58  [$D9E3 := 58]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $003A                ;   value
    dw $FF03                ; $03 set_flag: Set flag $001A
    dw $001A                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Room: Joy/Wisdom screen 0 → state 1  [$D96D := 1]
    dw $D96D                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Wisdom (SkyDragon) screen 0 → state 1  [$D980 := 1]
    dw $D980                ;   address
    dw $0001                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $001C is clear → Bank0E_ScriptAddr_60BE
    dw $001C                ;   flag
    dw Bank0E_ScriptAddr_60BE ;   target
    dw $FF12                ; $12 write_ram: Room state of Room: Joy/Wisdom screen 0 → state 3  [$D96D := 3]
    dw $D96D                ;   address
    dw $0003                ;   value
Bank0E_ScriptAddr_60BE:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map3A_Script02
; ---------------------------------------------------------------------------
Map3A_Script02:
    dw $FF21                ; $21 sound: Sound effect $55
    dw $0055                ;   sound
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry hidden  [$C8ED := 1]
    dw $C8ED                ;   address
    dw $0001                ;   value
    dw $FF0A                ; $0A walk_x_wait: the player walks right 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monster 1 hidden  [$C8ED := 3]
    dw $C8ED                ;   address
    dw $0003                ;   value
    dw $FF0A                ; $0A walk_x_wait: the player walks left 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monsters 1-2 hidden  [$C8ED := 7]
    dw $C8ED                ;   address
    dw $0007                ;   value
    dw $FF0A                ; $0A walk_x_wait: the player walks right 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry and all monsters hidden  [$C8ED := 15]
    dw $C8ED                ;   address
    dw $000F                ;   value
    dw $FF0D                ; $0D npc_write: The player is hidden
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF12                ; $12 write_ram: The party is falling through a hole: yes  [$D9E5 := 1]  (meaning inferred from the scripts that use it)
    dw $D9E5                ;   address
    dw $0001                ;   value
    dw $FF0F                ; $0F map_transition: Go to Boss: Wisdom (SkyDragon) at (1, 7)
    dw $003A                ;   map
    dw $0018                ;   x
    dw $0078                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map3A_Script03
; ---------------------------------------------------------------------------
Map3A_Script03:
    dw $FF10                ; $10 walk_to_x: NPC 5 walks to x = 120 px (script waits)
    dw $0005                ;   actor
    dw $0078                ;   x
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map3A_Script04
; ---------------------------------------------------------------------------
Map3A_Script04:
    dw $FF10                ; $10 walk_to_x: NPC 5 walks to x = 88 px (script waits)
    dw $0005                ;   actor
    dw $0058                ;   x
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map3A_Script05
; ---------------------------------------------------------------------------
Map3A_Script05:
    dw $FF10                ; $10 walk_to_x: NPC 5 walks to x = 24 px (script waits)
    dw $0005                ;   actor
    dw $0018                ;   x
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map3A_Script06
; ---------------------------------------------------------------------------
Map3A_Script06:
    dw $FF10                ; $10 walk_to_x: NPC 5 walks to x = 120 px (script waits)
    dw $0005                ;   actor
    dw $0078                ;   x
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map3A_Script07
; ---------------------------------------------------------------------------
Map3A_Script07:
    dw $FF10                ; $10 walk_to_x: NPC 5 walks to x = 88 px (script waits)
    dw $0005                ;   actor
    dw $0058                ;   x
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map3A_Script08
; ---------------------------------------------------------------------------
Map3A_Script08:
    dw $FF10                ; $10 walk_to_x: NPC 5 walks to x = 56 px (script waits)
    dw $0005                ;   actor
    dw $0038                ;   x
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map3B Per-Script Table (map_type=$3B, 2 scripts)
; ---------------------------------------------------------------------------
Map3B_ScriptPtrTable:
    dw Map3B_Script00       ; script 0
    dw Map3B_Script01       ; script 1
; ---------------------------------------------------------------------------
; Map3B_Script00
; ---------------------------------------------------------------------------
Map3B_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map3B_Script01
; ---------------------------------------------------------------------------
Map3B_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $00CF is set → Bank0E_ScriptAddr_622E
    dw $00CF                ;   flag
    dw Bank0E_ScriptAddr_622E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00CE is set → Bank0E_ScriptAddr_6170
    dw $00CE                ;   flag
    dw Bank0E_ScriptAddr_6170 ;   target
    dw $052C                ; text $052C: "*:Look at my cool steps!"
    dw $FF03                ; $03 set_flag: Set flag $00CE
    dw $00CE                ;   flag
    dw $FFFF                ; END

Bank0E_ScriptAddr_6170:
    dw $052D                ; text $052D: "*:Why don't you dance with me?"
    dw $FF03                ; $03 set_flag: Set flag $00CF
    dw $00CF                ;   flag
Bank0E_ScriptAddr_6176:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 123 (boss)
    dw $007B                ;   enemy
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $052F                ; text $052F: "*:You're a great dancer!"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 5, curve 4  [$D8E3 := $0405]
    dw $D8E3                ;   address
    dw $0405                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 2: fly in down-left (the flight path set above)
    dw $1502                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0530                ; text $0530: "*:Did you enjoy dancing? Well, let's go …"
    dw $FF1C                ; $1C trigger_anim: NPC 2: jump
    dw $0402                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 59  [$D9E3 := 59]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $003B                ;   value
    dw $FF03                ; $03 set_flag: Set flag $001C
    dw $001C                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Room: Joy/Wisdom screen 0 → state 2  [$D96D := 2]
    dw $D96D                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Joy (FunkyBird) screen 0 → state 1  [$D981 := 1]
    dw $D981                ;   address
    dw $0001                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $001A is clear → Bank0E_ScriptAddr_6222
    dw $001A                ;   flag
    dw Bank0E_ScriptAddr_6222 ;   target
    dw $FF12                ; $12 write_ram: Room state of Room: Joy/Wisdom screen 0 → state 3  [$D96D := 3]
    dw $D96D                ;   address
    dw $0003                ;   value
Bank0E_ScriptAddr_6222:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0E_ScriptAddr_622E:
    dw $052E                ; text $052E: "*:You came again to dance with me? Ready…"
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_6176
    dw Bank0E_ScriptAddr_6176 ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map3C Per-Script Table (map_type=$3C, 9 scripts)
; ---------------------------------------------------------------------------
Map3C_ScriptPtrTable:
    dw Map3C_Script00       ; script 0
    dw Map3C_Script01       ; script 1
    dw Map3C_Script02       ; script 2
    dw Map3C_Script03       ; script 3
    dw Map3C_Script04       ; script 4
    dw Map3C_Script05       ; script 5
    dw Map3C_Script06       ; script 6
    dw Map3C_Script07       ; script 7
    dw Map3C_Script08       ; script 8
; ---------------------------------------------------------------------------
; Map3C_Script00
; ---------------------------------------------------------------------------
Map3C_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FF01                ; $01 if_flag_set: If flag $0077 is set → Bank0E_ScriptAddr_627C
    dw $0077                ;   flag
    dw Bank0E_ScriptAddr_627C ;   target
    dw $FF02                ; $02 clear_flag: Clear flag $006F
    dw $006F                ;   flag
    dw $FF02                ; $02 clear_flag: Clear flag $0070
    dw $0070                ;   flag
    dw $FF02                ; $02 clear_flag: Clear flag $0071
    dw $0071                ;   flag
    dw $FF02                ; $02 clear_flag: Clear flag $0072
    dw $0072                ;   flag
    dw $FF02                ; $02 clear_flag: Clear flag $0073
    dw $0073                ;   flag
    dw $FF02                ; $02 clear_flag: Clear flag $0074
    dw $0074                ;   flag
    dw $FF02                ; $02 clear_flag: Clear flag $0075
    dw $0075                ;   flag
    dw $FF02                ; $02 clear_flag: Clear flag $0076
    dw $0076                ;   flag
Bank0E_ScriptAddr_627C:
    dw $FFFF                ; END

Bank0E_ScriptAddr_627E:
    db $88, $00, $4A, $4B, $D8, $5A, $5B, $D9  ; tile patch (op $24): BG offset $0088 (row 4, column 8), tiles 4A 4B / 5A 5B; $D8 = next row, $D9 = end
Bank0E_ScriptAddr_6286:
    db $C4, $00, $4A, $4B, $D8, $5A, $5B, $D9  ; tile patch (op $24): BG offset $00C4 (row 6, column 4), tiles 4A 4B / 5A 5B; $D8 = next row, $D9 = end
Bank0E_ScriptAddr_628E:
    db $02, $01, $4A, $4B, $D8, $5A, $5B, $D9  ; tile patch (op $24): BG offset $0102 (row 8, column 2), tiles 4A 4B / 5A 5B; $D8 = next row, $D9 = end
Bank0E_ScriptAddr_6296:
    db $10, $01, $4A, $4B, $D8, $5A, $5B, $D9  ; tile patch (op $24): BG offset $0110 (row 8, column 16), tiles 4A 4B / 5A 5B; $D8 = next row, $D9 = end
Bank0E_ScriptAddr_629E:
    db $4C, $01, $4A, $4B, $D8, $5A, $5B, $D9  ; tile patch (op $24): BG offset $014C (row 10, column 12), tiles 4A 4B / 5A 5B; $D8 = next row, $D9 = end
Bank0E_ScriptAddr_62A6:
    db $C6, $00, $4A, $4B, $D8, $5A, $5B, $D9  ; tile patch (op $24): BG offset $00C6 (row 6, column 6), tiles 4A 4B / 5A 5B; $D8 = next row, $D9 = end
Bank0E_ScriptAddr_62AE:
    db $0E, $01, $4A, $4B, $D8, $5A, $5B, $D9  ; tile patch (op $24): BG offset $010E (row 8, column 14), tiles 4A 4B / 5A 5B; $D8 = next row, $D9 = end
Bank0E_TilePatch_62B6:
    db $84, $00, $4A, $4B, $4A, $4B, $4A, $4B, $D8, $5A, $5B, $5A, $5B, $5A, $5B, $D8, $4A, $4B, $4A, $4B, $D8, $5A, $5B, $5A, $5B, $D9  ; tile patch (op $24): BG offset $0084 (row 4, column 4), tiles 4A 4B 4A 4B 4A 4B / 5A 5B 5A 5B 5A 5B / 4A 4B 4A 4B / 5A 5B 5A 5B; $D8 = next row, $D9 = end
Bank0E_TilePatch_62D0:
    db $C2, $00, $4A, $4B, $D8, $5A, $5B, $D8, $4A, $4B, $D8, $5A, $5B, $D9  ; tile patch (op $24): BG offset $00C2 (row 6, column 2), tiles 4A 4B / 5A 5B / 4A 4B / 5A 5B; $D8 = next row, $D9 = end
Bank0E_TilePatch_62DE:
    db $4C, $01, $4A, $4B, $4A, $4B, $D8, $5A, $5B, $5A, $5B, $D8, $4A, $4B, $4A, $4B, $D8, $5A, $5B, $5A, $5B, $D8, $4A, $4B, $D8, $5A, $5B, $D9  ; tile patch (op $24): BG offset $014C (row 10, column 12), tiles 4A 4B 4A 4B / 5A 5B 5A 5B / 4A 4B 4A 4B / 5A 5B 5A 5B / 4A 4B / 5A 5B; $D8 = next row, $D9 = end
; ---------------------------------------------------------------------------
; Map3C_Script01
; ---------------------------------------------------------------------------
Map3C_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $0077 is set → Bank0E_ScriptAddr_631C
    dw $0077                ;   flag
    dw Bank0E_ScriptAddr_631C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0070 is set → Bank0E_ScriptAddr_631C
    dw $0070                ;   flag
    dw Bank0E_ScriptAddr_631C ;   target
    dw $02A2                ; text $02A2: "[HERO] looked at the egg. A monster hatc…"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $627E)
    dw Bank0E_ScriptAddr_627E ;   data
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF03                ; $03 set_flag: Set flag $006F
    dw $006F                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0070
    dw $0070                ;   flag
    dw $FF05                ; $05 battle: Battle: enemy row 349
    dw $015D                ;   enemy
    dw $FFFF                ; END

Bank0E_ScriptAddr_631C:
    dw $02A3                ; text $02A3: "[HERO] looked at the egg. The egg is cra…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map3C_Script02
; ---------------------------------------------------------------------------
Map3C_Script02:
    dw $FF01                ; $01 if_flag_set: If flag $0077 is set → Bank0E_ScriptAddr_6342
    dw $0077                ;   flag
    dw Bank0E_ScriptAddr_6342 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0071 is set → Bank0E_ScriptAddr_6342
    dw $0071                ;   flag
    dw Bank0E_ScriptAddr_6342 ;   target
    dw $02A2                ; text $02A2: "[HERO] looked at the egg. A monster hatc…"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6286)
    dw Bank0E_ScriptAddr_6286 ;   data
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF03                ; $03 set_flag: Set flag $006F
    dw $006F                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0071
    dw $0071                ;   flag
    dw $FF05                ; $05 battle: Battle: enemy row 349
    dw $015D                ;   enemy
    dw $FFFF                ; END

Bank0E_ScriptAddr_6342:
    dw $02A3                ; text $02A3: "[HERO] looked at the egg. The egg is cra…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map3C_Script03
; ---------------------------------------------------------------------------
Map3C_Script03:
    dw $FF01                ; $01 if_flag_set: If flag $0077 is set → Bank0E_ScriptAddr_6368
    dw $0077                ;   flag
    dw Bank0E_ScriptAddr_6368 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0072 is set → Bank0E_ScriptAddr_6368
    dw $0072                ;   flag
    dw Bank0E_ScriptAddr_6368 ;   target
    dw $02A2                ; text $02A2: "[HERO] looked at the egg. A monster hatc…"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $628E)
    dw Bank0E_ScriptAddr_628E ;   data
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF03                ; $03 set_flag: Set flag $006F
    dw $006F                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0072
    dw $0072                ;   flag
    dw $FF05                ; $05 battle: Battle: enemy row 349
    dw $015D                ;   enemy
    dw $FFFF                ; END

Bank0E_ScriptAddr_6368:
    dw $02A3                ; text $02A3: "[HERO] looked at the egg. The egg is cra…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map3C_Script04
; ---------------------------------------------------------------------------
Map3C_Script04:
    dw $FF01                ; $01 if_flag_set: If flag $0077 is set → Bank0E_ScriptAddr_638E
    dw $0077                ;   flag
    dw Bank0E_ScriptAddr_638E ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0073 is set → Bank0E_ScriptAddr_638E
    dw $0073                ;   flag
    dw Bank0E_ScriptAddr_638E ;   target
    dw $02A2                ; text $02A2: "[HERO] looked at the egg. A monster hatc…"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6296)
    dw Bank0E_ScriptAddr_6296 ;   data
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF03                ; $03 set_flag: Set flag $006F
    dw $006F                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0073
    dw $0073                ;   flag
    dw $FF05                ; $05 battle: Battle: enemy row 349
    dw $015D                ;   enemy
    dw $FFFF                ; END

Bank0E_ScriptAddr_638E:
    dw $02A3                ; text $02A3: "[HERO] looked at the egg. The egg is cra…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map3C_Script05
; ---------------------------------------------------------------------------
Map3C_Script05:
    dw $FF01                ; $01 if_flag_set: If flag $0077 is set → Bank0E_ScriptAddr_63B4
    dw $0077                ;   flag
    dw Bank0E_ScriptAddr_63B4 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0074 is set → Bank0E_ScriptAddr_63B4
    dw $0074                ;   flag
    dw Bank0E_ScriptAddr_63B4 ;   target
    dw $02A2                ; text $02A2: "[HERO] looked at the egg. A monster hatc…"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $629E)
    dw Bank0E_ScriptAddr_629E ;   data
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF03                ; $03 set_flag: Set flag $006F
    dw $006F                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0074
    dw $0074                ;   flag
    dw $FF05                ; $05 battle: Battle: enemy row 349
    dw $015D                ;   enemy
    dw $FFFF                ; END

Bank0E_ScriptAddr_63B4:
    dw $02A3                ; text $02A3: "[HERO] looked at the egg. The egg is cra…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map3C_Script06
; ---------------------------------------------------------------------------
Map3C_Script06:
    dw $FF01                ; $01 if_flag_set: If flag $0077 is set → Bank0E_ScriptAddr_63DA
    dw $0077                ;   flag
    dw Bank0E_ScriptAddr_63DA ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0075 is set → Bank0E_ScriptAddr_63DA
    dw $0075                ;   flag
    dw Bank0E_ScriptAddr_63DA ;   target
    dw $02A2                ; text $02A2: "[HERO] looked at the egg. A monster hatc…"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $62A6)
    dw Bank0E_ScriptAddr_62A6 ;   data
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF03                ; $03 set_flag: Set flag $006F
    dw $006F                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0075
    dw $0075                ;   flag
    dw $FF05                ; $05 battle: Battle: enemy row 349
    dw $015D                ;   enemy
    dw $FFFF                ; END

Bank0E_ScriptAddr_63DA:
    dw $02A3                ; text $02A3: "[HERO] looked at the egg. The egg is cra…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map3C_Script07
; ---------------------------------------------------------------------------
Map3C_Script07:
    dw $FF01                ; $01 if_flag_set: If flag $0077 is set → Bank0E_ScriptAddr_6400
    dw $0077                ;   flag
    dw Bank0E_ScriptAddr_6400 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0076 is set → Bank0E_ScriptAddr_6400
    dw $0076                ;   flag
    dw Bank0E_ScriptAddr_6400 ;   target
    dw $02A2                ; text $02A2: "[HERO] looked at the egg. A monster hatc…"
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $62AE)
    dw Bank0E_ScriptAddr_62AE ;   data
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF03                ; $03 set_flag: Set flag $006F
    dw $006F                ;   flag
    dw $FF03                ; $03 set_flag: Set flag $0076
    dw $0076                ;   flag
    dw $FF05                ; $05 battle: Battle: enemy row 349
    dw $015D                ;   enemy
    dw $FFFF                ; END

Bank0E_ScriptAddr_6400:
    dw $02A3                ; text $02A3: "[HERO] looked at the egg. The egg is cra…"
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map3C_Script08
; ---------------------------------------------------------------------------
Map3C_Script08:
    dw $FF01                ; $01 if_flag_set: If flag $0078 is set → Bank0E_ScriptAddr_665C
    dw $0078                ;   flag
    dw Bank0E_ScriptAddr_665C ;   target
    dw $FF01                ; $01 if_flag_set: If flag $0077 is set → Bank0E_ScriptAddr_6564
    dw $0077                ;   flag
    dw Bank0E_ScriptAddr_6564 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $006F is set → Bank0E_ScriptAddr_641A
    dw $006F                ;   flag
    dw Bank0E_ScriptAddr_641A ;   target
    dw $029E                ; text $029E: "*:It's my wish that... *:my family in th…"
    dw $FFFF                ; END

Bank0E_ScriptAddr_641A:
    dw $029F                ; text $029F: "*:That my family in this world prospers.…"
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks up 1 tile (script waits)
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 3: stands still (status cleared)  [slot +$05 := $00]
    dw $0003                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF1C                ; $1C trigger_anim: the player: hop
    dw $0100                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF10                ; $10 walk_to_x: the player walks to x = 88 px (script waits)
    dw $0000                ;   actor
    dw $0058                ;   x
    dw $FF0B                ; $0B walk_y_wait: the player walks down 3 tiles (script waits)
    dw $0000                ;   actor
    dw $0030                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: the player walks left 2 tiles (script waits)
    dw $0000                ;   actor
    dw $FFE0                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks up 1 tile (script waits)
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: NPC 1 walks right 2 tiles (script waits)
    dw $0001                ;   actor
    dw $0020                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks up 1 tile (script waits)
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: NPC 1 walks right 1 tile (script waits)
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks up 1 tile (script waits)
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF0D                ; $0D npc_write: NPC 1: animation frozen (kept out of the animation picker)  [slot +$05 := $80]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0080                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3: animation frozen (kept out of the animation picker)  [slot +$05 := $80]
    dw $0003                ;   actor
    dw $0005                ;   field
    dw $0080                ;   value
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 1: hop
    dw $0101                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 1: hop
    dw $0101                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1C                ; $1C trigger_anim: NPC 1: hop
    dw $0101                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 3: hop
    dw $0103                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 6 ticks (~48 frames)
    dw $0006                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3: stands still (status cleared)  [slot +$05 := $00]
    dw $0003                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF3C                ; $3C text_box_bottom: The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $02A0                ; text $02A0: "*:Shoot! Not here either!"
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF12                ; $12 write_ram: Screen shake (left / right): 8  [$C8B2 := 8]
    dw $C8B2                ;   address
    dw $0008                ;   value
    dw $FF21                ; $21 sound: Sound effect $64
    dw $0064                ;   sound
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF12                ; $12 write_ram: The background palette (fade): all white (flash)  [$C89B := 0]
    dw $C89B                ;   address
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89B := 210]
    dw $C89B                ;   address
    dw $00D2                ;   value
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF12                ; $12 write_ram: The background palette (fade): all white (flash)  [$C89B := 0]
    dw $C89B                ;   address
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 1 ticks (~8 frames)
    dw $0001                ;   ticks
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $62AE)
    dw Bank0E_ScriptAddr_62AE ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $6296)
    dw Bank0E_ScriptAddr_6296 ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $62B6)
    dw Bank0E_TilePatch_62B6 ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $62D0)
    dw Bank0E_TilePatch_62D0 ;   data
    dw $FF24                ; $24 draw_tiles: Change the look of part of the screen (tile patch $62DE)
    dw Bank0E_TilePatch_62DE ;   data
    dw $FF12                ; $12 write_ram: The background palette (fade): shades 2-0-1-3 (0 light … 3 dark)  [$C89B := 210]
    dw $C89B                ;   address
    dw $00D2                ;   value
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks down 1 tile (script waits)
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: NPC 1 walks left 1 tile (script waits)
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks down 1 tile (script waits)
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF0A                ; $0A walk_x_wait: NPC 1 walks left 1 tile (script waits)
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF3D                ; $3D text_box_top: The next text box opens at the TOP of the screen ($D8D8 bit 1)
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $02A1                ; text $02A1: "*:Who are you? You're a monster master a…"
    dw $FF0A                ; $0A walk_x_wait: NPC 1 walks left 1 tile (script waits)
    dw $0001                ;   actor
    dw $FFF0                ;   pixels
    dw $FF0B                ; $0B walk_y_wait: NPC 1 walks down 2 tiles (script waits)
    dw $0001                ;   actor
    dw $0020                ;   pixels
    dw $FF0D                ; $0D npc_write: NPC 1 is hidden
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0077
    dw $0077                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Boss: Anger (BattleRex) screen 0 → state 1  [$D982 := 1]
    dw $D982                ;   address
    dw $0001                ;   value
    dw $FFFF                ; END

Bank0E_ScriptAddr_6564:
    dw $02A4                ; text $02A4: "*:Arrrgh! How dare you crack all my eggs…"
    dw $FF03                ; $03 set_flag: Set flag $0078
    dw $0078                ;   flag
Bank0E_ScriptAddr_656A:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 101 (boss)
    dw $0065                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $02A6                ; text $02A6: "*:That sword man looked like you..."
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 3: stands still (status cleared)  [slot +$05 := $00]
    dw $0003                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 4, curve 2  [$D8E3 := $0204]
    dw $D8E3                ;   address
    dw $0204                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 2: fly in down-right (the flight path set above)
    dw $1602                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: the player faces left
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $02A7                ; text $02A7: "Watabou:Those eggs were the reason there…"
    dw $FF1C                ; $1C trigger_anim: NPC 2: jump
    dw $0402                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 60  [$D9E3 := 60]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $003C                ;   value
    dw $FF03                ; $03 set_flag: Set flag $001D
    dw $001D                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 12 → state 2  [$D933 := 2]
    dw $D933                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of GreatTree screen 13 → state 1  [$D934 := 1]
    dw $D934                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 0 → state 1  [$D935 := 1]
    dw $D935                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 1 → state 1  [$D936 := 1]
    dw $D936                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 2 → state 1  [$D937 := 1]
    dw $D937                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Bazaar screen 4 → state 1  [$D938 := 1]
    dw $D938                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Farm screen 0 → state 2  [$D93F := 2]
    dw $D93F                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Farm screen 2 → state 2  [$D941 := 2]
    dw $D941                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Farm screen 4 → state 2  [$D942 := 2]
    dw $D942                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Farm screen 5 → state 1  [$D943 := 1]
    dw $D943                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Farm screen 6 → state 2  [$D944 := 2]
    dw $D944                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Restaurant screen 0 → state 1  [$D966 := 1]
    dw $D966                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Queen Room screen 0 → state 1  [$D967 := 1]
    dw $D967                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Room: Strength/Anger screen 0 → state 1  [$D96C := 1]
    dw $D96C                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Anger (BattleRex) screen 0 → state 2  [$D982 := 2]
    dw $D982                ;   address
    dw $0002                ;   value
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0E_ScriptAddr_665C:
    dw $02A5                ; text $02A5: "*:It's you again! You'll pay for what yo…"
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_656A
    dw Bank0E_ScriptAddr_656A ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map3D Per-Script Table (map_type=$3D, 4 scripts)
; ---------------------------------------------------------------------------
Map3D_ScriptPtrTable:
    dw Map3D_Script00       ; script 0
    dw Map3D_Script01       ; script 1
    dw Map3D_Script02       ; script 2
    dw Map3D_Script03       ; script 3
; ---------------------------------------------------------------------------
; Map3D_Script00
; ---------------------------------------------------------------------------
Map3D_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map3D_Script02
; ---------------------------------------------------------------------------
Map3D_Script02:
    dw $FF0D                ; $0D npc_write: NPC 1: x low byte := 88
    dw $0001                ;   actor
    dw $0018                ;   field
    dw $0058                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2: x low byte := 88
    dw $0002                ;   actor
    dw $0018                ;   field
    dw $0058                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3: x low byte := 88
    dw $0003                ;   actor
    dw $0018                ;   field
    dw $0058                ;   value
    dw $FF0D                ; $0D npc_write: NPC 4: x low byte := 168
    dw $0004                ;   actor
    dw $0018                ;   field
    dw $00A8                ;   value
    dw $FF0D                ; $0D npc_write: NPC 5: x low byte := 72
    dw $0005                ;   actor
    dw $0018                ;   field
    dw $0048                ;   value
    dw $FF0A                ; $0A walk_x_wait: the player walks left 1 tile (script waits)
    dw $0000                ;   actor
    dw $FFF0                ;   pixels
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 4 is shown
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF49                ; $49 face_left: NPC 4 faces left
    dw $0004                ;   actor
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 5, curve 3  [$D8E3 := $0305]
    dw $D8E3                ;   address
    dw $0305                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 4: fly in down-left (the flight path set above)
    dw $1504                ;   program_actor
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_6718
    dw Bank0E_ScriptAddr_6718 ;   target
; ---------------------------------------------------------------------------
; Map3D_Script01
; ---------------------------------------------------------------------------
Map3D_Script01:
    dw $FF0D                ; $0D npc_write: NPC 1: x low byte := 72
    dw $0001                ;   actor
    dw $0018                ;   field
    dw $0048                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2: x low byte := 72
    dw $0002                ;   actor
    dw $0018                ;   field
    dw $0048                ;   value
    dw $FF0D                ; $0D npc_write: NPC 3: x low byte := 72
    dw $0003                ;   actor
    dw $0018                ;   field
    dw $0048                ;   value
    dw $FF0D                ; $0D npc_write: NPC 4: x low byte := 8
    dw $0004                ;   actor
    dw $0018                ;   field
    dw $0008                ;   value
    dw $FF0D                ; $0D npc_write: NPC 5: x low byte := 88
    dw $0005                ;   actor
    dw $0018                ;   field
    dw $0058                ;   value
    dw $FF0A                ; $0A walk_x_wait: the player walks right 1 tile (script waits)
    dw $0000                ;   actor
    dw $0010                ;   pixels
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 4 is shown
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF4A                ; $4A face_right: NPC 4 faces right
    dw $0004                ;   actor
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 4, curve 3  [$D8E3 := $0304]
    dw $D8E3                ;   address
    dw $0304                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 4: fly in down-right (the flight path set above)
    dw $1604                ;   program_actor
Bank0E_ScriptAddr_6718:
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF48                ; $48 face_down: NPC 4 faces down
    dw $0004                ;   actor
    dw $FF09                ; $09 delay: Wait 2 ticks (~16 frames)
    dw $0002                ;   ticks
    dw $FF12                ; $12 write_ram: Hidden sprites: Terry + monster 1 hidden  [$C8ED := 3]
    dw $C8ED                ;   address
    dw $0003                ;   value
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 5 is shown
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF1D                ; $1D lock_movement: Walks and programs no longer turn the actors (walk backwards)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks up 3 tiles
    dw $0001                ;   actor
    dw $FFD0                ;   pixels
    dw $FF1B                ; $1B npc_walk_y: NPC 4 walks up 3 tiles
    dw $0004                ;   actor
    dw $FFD0                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF1E                ; $1E unlock_movement: Walks turn the actors again
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 5: jump
    dw $0405                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF21                ; $21 sound: Sound effect $55
    dw $0055                ;   sound
    dw $FF22                ; $22 walk_fast: The next queued walks run at double speed (until they finish)
    dw $FF1B                ; $1B npc_walk_y: NPC 1 walks down 1 tile
    dw $0001                ;   actor
    dw $0010                ;   pixels
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF0D                ; $0D npc_write: NPC 1 is hidden
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF21                ; $21 sound: Sound effect $66
    dw $0066                ;   sound
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0B                ; $0B walk_y_wait: NPC 4 walks up 8 px (script waits)
    dw $0004                ;   actor
    dw $FFF8                ;   pixels
    dw $FF0D                ; $0D npc_write: NPC 4 is hidden
    dw $0004                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0531                ; text $0531: "There is a voice coming from out of nowh…"
    dw $0532                ; text $0532: "*:Hello...the traveler over there... *:I…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0E_ScriptAddr_679C  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0E_ScriptAddr_679C ;   target
    dw $0533                ; text $0533: "*:Now, wait there."
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_67AE
    dw Bank0E_ScriptAddr_67AE ;   target
Bank0E_ScriptAddr_679C:
    dw $0534                ; text $0534: "*:Then, would you like me to send you ba…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0E_ScriptAddr_67AC  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0E_ScriptAddr_67AC ;   target
    dw $0535                ; text $0535: "*:It was actually a monster that fell wa…"
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_67AE
    dw Bank0E_ScriptAddr_67AE ;   target
Bank0E_ScriptAddr_67AC:
    dw $0535                ; text $0535: "*:It was actually a monster that fell wa…"
Bank0E_ScriptAddr_67AE:
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 2: appear (flicker in)
    dw $0802                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0536                ; text $0536: "*:Was it this meat that fell in the spri…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0E_ScriptAddr_67CE  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0E_ScriptAddr_67CE ;   target
    dw $0537                ; text $0537: "*:...you're a liar. *:I'll give your mon…"
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_68AE
    dw Bank0E_ScriptAddr_68AE ;   target
Bank0E_ScriptAddr_67CE:
    dw $0538                ; text $0538: "*:I see. Now, wait a moment for me."
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 2: vanish (flicker out)
    dw $0D02                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 6: animation frozen (kept out of the animation picker)  [slot +$05 := $80]
    dw $0006                ;   actor
    dw $0005                ;   field
    dw $0080                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 3: appear (flicker in)
    dw $0803                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0539                ; text $0539: "*:Now, is this the old guy who fell in t…"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0E_ScriptAddr_6802  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0E_ScriptAddr_6802 ;   target
    dw $053A                ; text $053A: "*:...you're a liar. *:I'll give your mon…"
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_68AE
    dw Bank0E_ScriptAddr_68AE ;   target
Bank0E_ScriptAddr_6802:
    dw $053B                ; text $053B: "*:I see. Now,wait a minute for me."
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF1C                ; $1C trigger_anim: NPC 3: vanish (flicker out)
    dw $0D03                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2: animation frozen (kept out of the animation picker)  [slot +$05 := $80]
    dw $0002                ;   actor
    dw $0005                ;   field
    dw $0080                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2: y low byte := 40
    dw $0002                ;   actor
    dw $001A                ;   field
    dw $0028                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 1: appear (flicker in)
    dw $0801                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF3F                ; $3F load_lead_name: Put the first party monster's name in $C180 for the next text
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $053C                ; text $053C: "*:Now is this the [INS 00], the monster …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is YES → Bank0E_ScriptAddr_6840  [$C83C = 0]
    dw $C83C                ;   address
    dw $0000                ;   value
    dw Bank0E_ScriptAddr_6840 ;   target
    dw $053D                ; text $053D: "*:I don't understand you... *:I'll give …"
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_68AE
    dw Bank0E_ScriptAddr_68AE ;   target
Bank0E_ScriptAddr_6840:
    dw $053E                ; text $053E: "*:You're honest. I'll give you back the …"
    dw $FF09                ; $09 delay: Wait 4 ticks (~32 frames)
    dw $0004                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1 is hidden
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 5 is hidden
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF12                ; $12 write_ram: Hidden sprites: everyone shown  [$C8ED := 0]
    dw $C8ED                ;   address
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF05                ; $05 battle: Battle: enemy row 127
    dw $007F                ;   enemy
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 61  [$D9E3 := 61]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $003D                ;   value
    dw $FF03                ; $03 set_flag: Set flag $001E
    dw $001E                ;   flag
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $053F                ; text $053F: "*:You did well. Please go back to your h…"
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Arena Rooms screen 1 → state 3  [$D94C := 3]
    dw $D94C                ;   address
    dw $0003                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Arena Left (Digster) screen 0 → state 1  [$D983 := 1]
    dw $D983                ;   address
    dw $0001                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $002E is clear → Bank0E_ScriptAddr_6890
    dw $002E                ;   flag
    dw Bank0E_ScriptAddr_6890 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $010C is set → Bank0E_ScriptAddr_68A4
    dw $010C                ;   flag
    dw Bank0E_ScriptAddr_68A4 ;   target
Bank0E_ScriptAddr_6890:
    dw $FF01                ; $01 if_flag_set: If flag $010C is set → Bank0E_ScriptAddr_689A
    dw $010C                ;   flag
    dw Bank0E_ScriptAddr_689A ;   target
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_68AE
    dw Bank0E_ScriptAddr_68AE ;   target
Bank0E_ScriptAddr_689A:
    dw $FF12                ; $12 write_ram: Room state of Arena Rooms screen 1 → state 5  [$D94C := 5]
    dw $D94C                ;   address
    dw $0005                ;   value
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_68AE
    dw Bank0E_ScriptAddr_68AE ;   target
Bank0E_ScriptAddr_68A4:
    dw $FF12                ; $12 write_ram: Room state of Arena Rooms screen 1 → state 7  [$D94C := 7]
    dw $D94C                ;   address
    dw $0007                ;   value
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_68AE
    dw Bank0E_ScriptAddr_68AE ;   target
Bank0E_ScriptAddr_68AE:
    dw $FF0D                ; $0D npc_write: NPC 1 is hidden
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF0D                ; $0D npc_write: NPC 5 is hidden
    dw $0005                ;   actor
    dw $0000                ;   field
    dw $0040                ;   value
    dw $FF12                ; $12 write_ram: Hidden sprites: everyone shown  [$C8ED := 0]
    dw $C8ED                ;   address
    dw $0000                ;   value
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map3D_Script03
; ---------------------------------------------------------------------------
Map3D_Script03:
    dw $0531                ; text $0531: "There is a voice coming from out of nowh…"
    dw $0540                ; text $0540: "*:Oh, it's you again. Would you like to …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0E_ScriptAddr_68EE  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0E_ScriptAddr_68EE ;   target
    dw $0542                ; text $0542: "*:Now so long..."
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0E_ScriptAddr_68EE:
    dw $0541                ; text $0541: "*:Take your time."
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map3E Per-Script Table (map_type=$3E, 2 scripts)
; ---------------------------------------------------------------------------
Map3E_ScriptPtrTable:
    dw Map3E_Script00       ; script 0
    dw Map3E_Script01       ; script 1
; ---------------------------------------------------------------------------
; Map3E_Script00
; ---------------------------------------------------------------------------
Map3E_Script00:
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

; ---------------------------------------------------------------------------
; Map3E_Script01
; ---------------------------------------------------------------------------
Map3E_Script01:
    dw $FF01                ; $01 if_flag_set: If flag $00D2 is set → Bank0E_ScriptAddr_69DE
    dw $00D2                ;   flag
    dw Bank0E_ScriptAddr_69DE ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00D1 is set → Bank0E_ScriptAddr_6928
    dw $00D1                ;   flag
    dw Bank0E_ScriptAddr_6928 ;   target
    dw $FF01                ; $01 if_flag_set: If flag $00D0 is set → Bank0E_ScriptAddr_6920
    dw $00D0                ;   flag
    dw Bank0E_ScriptAddr_6920 ;   target
    dw $0543                ; text $0543: "*:Comrade! Now is the time for us to uni…"
    dw $FF03                ; $03 set_flag: Set flag $00D0
    dw $00D0                ;   flag
    dw $FFFF                ; END

Bank0E_ScriptAddr_6920:
    dw $0544                ; text $0544: "*:I'll promise you, comrade! *:A world w…"
    dw $FF03                ; $03 set_flag: Set flag $00D1
    dw $00D1                ;   flag
    dw $FFFF                ; END

Bank0E_ScriptAddr_6928:
    dw $0545                ; text $0545: "*:Hm!? I don't know why but I feel somet…"
    dw $FF03                ; $03 set_flag: Set flag $00D2
    dw $00D2                ;   flag
Bank0E_ScriptAddr_692E:
    dw $FF5A                ; $5A trigger_battle3: Battle: enemy row 147 (boss)
    dw $0093                ;   enemy
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0547                ; text $0547: "*:I demand one sirloin steak a day!"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 2: stands still (status cleared)  [slot +$05 := $00]
    dw $0002                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 1 is shown
    dw $0001                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 4, curve 3  [$D8E3 := $0304]
    dw $D8E3                ;   address
    dw $0304                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 1: fly in down-left (the flight path set above)
    dw $1501                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: the player faces down
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $0844                ; text $0844: "Watabou:How're you doing?... Let's go ho…"
    dw $FF1C                ; $1C trigger_anim: NPC 1: jump
    dw $0401                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 1 faces right
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 1 faces down
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 1 faces left
    dw $0001                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF47                ; $47 face_up: NPC 1 faces up
    dw $0001                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 62  [$D9E3 := 62]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $003E                ;   value
    dw $FF03                ; $03 set_flag: Set flag $001F
    dw $001F                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Room: Happiness/Temptation screen 0 → state 1  [$D96E := 1]
    dw $D96E                ;   address
    dw $0001                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Happiness (Jamirus) screen 0 → state 1  [$D984 := 1]
    dw $D984                ;   address
    dw $0001                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $0020 is clear → Bank0E_ScriptAddr_69D2
    dw $0020                ;   flag
    dw Bank0E_ScriptAddr_69D2 ;   target
    dw $FF12                ; $12 write_ram: Room state of Room: Happiness/Temptation screen 0 → state 3  [$D96E := 3]
    dw $D96E                ;   address
    dw $0003                ;   value
Bank0E_ScriptAddr_69D2:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

Bank0E_ScriptAddr_69DE:
    dw $0546                ; text $0546: "*:Sirloin steak is totally yummy! Theref…"
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_692E
    dw Bank0E_ScriptAddr_692E ;   target
    dw $FFFF                ; END — not reached (after a room change / no script runs here)

; ---------------------------------------------------------------------------
; Map3F Per-Script Table (map_type=$3F, 0 scripts)
; ---------------------------------------------------------------------------
Map3F_ScriptPtrTable:
    dw $69EA                ; script 0
    dw $69FA                ; script 1
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 6  [$D92B := 6]
    dw $D92B                ;   address
    dw $0006                ;   value
    dw $FF0D                ; $0D npc_write: The player is shown
    dw $0000                ;   actor
    dw $FF90                ;   field
    dw $0000                ;   value
    dw $FFFF                ; END

    dw $FF01                ; $01 if_flag_set: If flag $00D3 is set → Bank0E_ScriptAddr_6ADA
    dw $00D3                ;   flag
    dw Bank0E_ScriptAddr_6ADA ;   target
    dw $0548                ; text $0548: "*:Hee hee hee. I love burning villages! …"
    dw $FF15                ; $15 check_and_branch: If “the YES/NO answer” is NO → Bank0E_ScriptAddr_6A0E  [$C83C = 1]
    dw $C83C                ;   address
    dw $0001                ;   value
    dw Bank0E_ScriptAddr_6A0E ;   target
    dw $0549                ; text $0549: "*:Hee hee hee. Burn'em burn'em all! *:Go…"
    dw $FFFF                ; END
Bank0E_ScriptAddr_6A0E:
    dw $054A                ; text $054A: "*:You are so boring! *:You wanna be burn…"
    dw $FF03                ; $03 set_flag: Set flag $00D3
    dw $00D3                ;   flag
Bank0E_ScriptAddr_6A14:
    dw $FF13                ; $13 write_ram2: The battle: enemy 1: 151  [$DA03 := $0097]
    dw $DA03                ;   address
    dw $0097                ;   value
    dw $FF13                ; $13 write_ram2: The battle: enemy 2: 149  [$DA05 := $0095]
    dw $DA05                ;   address
    dw $0095                ;   value
    dw $FF13                ; $13 write_ram2: The battle: enemy 3: 152  [$DA07 := $0098]
    dw $DA07                ;   address
    dw $0098                ;   value
    dw $FF12                ; $12 write_ram: The battle: number of enemies: 3 enemies  [$DA02 := 2]
    dw $DA02                ;   address
    dw $0002                ;   value
    dw $FF5B                ; $5B boss_battle: Start the battle set up above (enemies / count) — a boss battle
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $054C                ; text $054C: "*:Burn me, boil me! Whatever! Ahrg!"
    dw $FF09                ; $09 delay: Wait 8 ticks (~64 frames)
    dw $0008                ;   ticks
    dw $FF0D                ; $0D npc_write: NPC 1: stands still (status cleared)  [slot +$05 := $00]
    dw $0001                ;   actor
    dw $0005                ;   field
    dw $0000                ;   value
    dw $FF0D                ; $0D npc_write: NPC 2 is shown
    dw $0002                ;   actor
    dw $0000                ;   field
    dw $0000                ;   value
    dw $FF13                ; $13 write_ram2: The next fly-in / fly-off: length 9, curve 4  [$D8E3 := $0409]
    dw $D8E3                ;   address
    dw $0409                ;   value
    dw $FF1C                ; $1C trigger_anim: NPC 2: fly in down-left (the flight path set above)
    dw $1502                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: the player faces up
    dw $0000                ;   actor
    dw $FF07                ; $07 init_dialog: Open dialog mode (needed before text in a script that did not start by talking to someone)
    dw $054D                ; text $054D: "Watabou:Ouch! I'm gonna put out the fire…"
    dw $FF1C                ; $1C trigger_anim: NPC 2: jump
    dw $0402                ;   program_actor
    dw $FF19                ; $19 wait_movement: Wait until every queued movement / animation has finished
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF49                ; $49 face_left: NPC 2 faces left
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF47                ; $47 face_up: NPC 2 faces up
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 4 frames
    dw $0004                ;   frames
    dw $FF4A                ; $4A face_right: NPC 2 faces right
    dw $0002                ;   actor
    dw $FF4D                ; $4D long_delay: Wait 6 frames
    dw $0006                ;   frames
    dw $FF48                ; $48 face_down: NPC 2 faces down
    dw $0002                ;   actor
    dw $FF08                ; $08 nop: Nothing (one tick)
    dw $FF12                ; $12 write_ram: The King's speech for the next Castle arrival: 63  [$D9E3 := 63]  (meaning inferred from the scripts that use it)
    dw $D9E3                ;   address
    dw $003F                ;   value
    dw $FF03                ; $03 set_flag: Set flag $0020
    dw $0020                ;   flag
    dw $FF12                ; $12 write_ram: Room state of Castle screen 1 (+8 room variant(s) sharing it) → state 7  [$D92B := 7]
    dw $D92B                ;   address
    dw $0007                ;   value
    dw $FF12                ; $12 write_ram: Room state of Room: Happiness/Temptation screen 0 → state 2  [$D96E := 2]
    dw $D96E                ;   address
    dw $0002                ;   value
    dw $FF12                ; $12 write_ram: Room state of Boss: Temptation (Servant) screen 0 → state 1  [$D985 := 1]
    dw $D985                ;   address
    dw $0001                ;   value
    dw $FF00                ; $00 if_flag_clear: If flag $001F is clear → Bank0E_ScriptAddr_6ACE
    dw $001F                ;   flag
    dw Bank0E_ScriptAddr_6ACE ;   target
    dw $FF12                ; $12 write_ram: Room state of Room: Happiness/Temptation screen 0 → state 3  [$D96E := 3]
    dw $D96E                ;   address
    dw $0003                ;   value
Bank0E_ScriptAddr_6ACE:
    dw $FF06                ; $06 close_text: Close the open text box
    dw $FF3B                ; $3B warp_fade: Warp (wavy fade) to Castle at (14, 5)
    dw $0000                ;   map
    dw $00E8                ;   x
    dw $0058                ;   y
    dw $FFFF                ; END — not reached (after a room change / no script runs here)
Bank0E_ScriptAddr_6ADA:
    dw $054B                ; text $054B: "*:You again! You really wanna be burnt d…"
    dw $FF14                ; $14 goto: Go to Bank0E_ScriptAddr_6A14
    dw Bank0E_ScriptAddr_6A14 ;   target
    dw $FFFF                ; not reached by any script path
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
