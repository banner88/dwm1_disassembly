; =============================================================================
; BANK $03 — LINK/SERIAL COMMUNICATION, MONSTER INFO TABLE
; =============================================================================
; Contains:
;   - Serial/link cable communication (entry 0)
;   - Monster info table loader (entry 1 → MonsterInfoLoad at $443F)
;   - Monster info table data at $4461 (221 entries × 43 bytes)
;
; MONSTER INFO TABLE ($4461):
;   Format per 43-byte entry:
;     +$00: Family (0=Slime,1=Dragon,2=Beast,3=Flying,4=Plant,5=Bug,
;                    6=Devil,7=Zombie,8=Material,9=Boss)
;     +$01: Base level cap
;     +$02: Experience table index (selects growth curve in bank $13)
;     +$03: Female ratio (0=0%, 1≈10%, 2=50%, 3≈84%)
;     +$04: Can fly flag (1=floating/flying sprite)
;     +$05: Metal body flag (1=Metaly/Metabble/MetalKing only)
;     +$06: Skill 1 ID
;     +$07: Skill 2 ID
;     +$08: Skill 3 ID
;     +$09: HP growth rate (curve index for bank $13:$6706 table)
;     +$0A: MP growth rate
;     +$0B: ATK growth rate (gets bonus scaling via Call_013_4163)
;     +$0C: DEF growth rate
;     +$0D: AGL growth rate
;     +$0E: INT growth rate
;     +$0F-$29: Resistances (27 bytes, values 0=weak..3=immune)
;                 Index 0-25 = types A-Z: Fire,Heat,Explosion,Wind,Lightning,Ice,
;                 Accuracy,Sleep,Death,MP,SpellBlock,Confusion,DefDown,AglDown,
;                 Sacrifice,MegaMagic,FireBreath,IceBreath,Poison,Paralyze,Curse,
;                 MissATurn,DanceBlock,BreathBlock,Aid,GigaSlash
;                 Index 26 = unused (always 0)
;     +$2A: Monster tier/rank (0=starter, 3-6=normal, 7=endgame boss)
;
; RAM VARIABLES:
;   $DA31:   Species ID input for loader
;   $DA33+:  43-byte copy of loaded monster info entry
;
; Sources: dump_monsters.py, known_ROM_map.md, bank $13 level-up analysis
; =============================================================================

    ; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $003", ROMX[$4000], BANK[$3]

    db $03

    ; Bank $03 jump table (9 entries, called via rst $10 with H=$03)
    dw label4013             ; Entry 0: Serial/link communication
    dw label443f             ; Entry 1: MonsterInfoLoad → $DA33
    dw SetMon_6980         ; Entry 2
    dw label69a2             ; Entry 3
    dw label6e24             ; Entry 4
    dw SetMon_7160         ; Entry 5
    dw label7190             ; Entry 6
    dw label71b6             ; Entry 7
    dw CallMon_7134         ; Entry 8

label4013:
    ld a, [$c864]
    bit 7, a
    jr z, jr_003_4020

    set 6, a
    ld [$c864], a
    ret


jr_003_4020:
    ld a, [$c865]
    rst $00

    inc l
    ld b, b
    ld c, l
    ld b, c
    add d
    ld b, c
    or a
    ld b, c


    call WaitForSerialTransferEnd		;check for Seral Transfer Start (Link cable)
    ldh a, [rSB]
    ld b, a
    cp $f0
    jr z, jr_003_4071

    cp $f1
    jr z, jr_003_4071

    cp $f2
    jr nz, jr_003_4049

    ld a, [wMenu_selection]
    and $7f
    cp $02
    jr z, jr_003_405e

    jr jr_003_4056

jr_003_4049:
    cp $f3
    jr nz, jr_003_4056

    ld a, [wMenu_selection]
    and $7f
    cp $03
    jr z, jr_003_405e

jr_003_4056:
    ld a, $ff
    ld [$c8df], a
    jp Jump_003_4142


jr_003_405e:
    ld a, [$c863]
    set 0, a
    res 1, a
    ld [$c863], a
    ld a, b
    cp $f2
    jp nz, Jump_003_4107

    jp Jump_003_40c8


jr_003_4071:
    ld hl, $a002
    call EnableSRAM
    or a
    jp z, Jump_003_4142

    ld a, [wGameMode]
    or a
    jr nz, jr_003_40b5

    ld a, [$c88b]
    cp $01
    jr nz, jr_003_40b5

    ld a, [$c8d2]
    cp $01
    jr nz, jr_003_40b5

    ld a, b
    cp $f0
    jr nz, jr_003_40a2

    ld a, [wMenu_selection]
    cp $02
    jr z, jr_003_40b8

    ld a, $02
    ld [$c8e0], a
    jr jr_003_40b5

jr_003_40a2:
    ld a, b
    cp $f1
    jr nz, jr_003_40b5

    ld a, [wMenu_selection]
    cp $03
    jr z, jr_003_40b8

    ld a, $03
    ld [$c8e0], a
    jr jr_003_40b5

jr_003_40b5:
    jp Jump_003_4142


jr_003_40b8:
    ld a, [$c863]
    set 0, a
    set 1, a
    ld [$c863], a
    ld a, b
    cp $f0
    jp nz, Jump_003_4107

Jump_003_40c8:
    ld a, $59
    call PlaySoundEffect
    ld a, $00
    ld [$c841], a
    ld a, $01
    ld [$c86c], a
    di
    call SRAMAccess_21B2
    ei
    ld hl, $0109
    rst $10
    ld hl, wGameMode
    ld a, $00
    ld [hl+], a
    ld a, $02
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld [hl], $00
    ld hl, $c88e
    inc [hl]
    ld a, $02
    ld [$c865], a
    xor a
    ld [$c866], a
    ld a, $00
    ld [$c867], a
    xor a
    ld [$c86d], a
    jp Jump_003_4142


Jump_003_4107:
    ld a, $59
    call PlaySoundEffect
    ld a, $00
    ld [$c841], a
    ld a, $01
    ld [$c86c], a
    di
    call SRAMAccess_21B2
    ei
    ld hl, wGameMode
    ld a, $00
    ld [hl+], a
    ld a, $03
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld [hl], $00
    ld hl, $c88e
    inc [hl]
    ld a, $03
    ld [$c865], a
    xor a
    ld [$c866], a
    ld a, $00
    ld [$c867], a
    xor a
    ld [$c86d], a
    jp Jump_003_4142


Jump_003_4142:
    ld a, $03
    ld [$c864], a
    ld a, $f8
    call SerialTransfer
    ret


    ld a, [$c86c]
    or a
    jr z, jr_003_415d

    ld a, [$c863]
    bit 0, a
    jr z, jr_003_415d

    call LoadMon_415e

jr_003_415d:
    ret


LoadMon_415e:
    ld a, [$c866]
    rst $00
    ld h, [hl]
    ld b, c
    ld l, d
    ld b, c
    call LoadMon_42d5
    ret


    call LoadMon_4387
    ld hl, $c8a2
    bit 7, [hl]
    res 7, [hl]
    ret nz

CallMon_4175:
    call LoadMon_441b
    ld hl, $5002
    rst $10
    ld hl, $c8a2
    res 1, [hl]
    ret


    ld a, [$c86c]
    or a
    jr z, jr_003_4192

    ld a, [$c863]
    bit 0, a
    jr z, jr_003_4192

    call LoadMon_4193

jr_003_4192:
    ret


LoadMon_4193:
    ld a, [$c866]
    rst $00
    sbc e
    ld b, c
    sbc a
    ld b, c
    call LoadMon_42d5
    ret


    call LoadMon_4387
    ld hl, $c8a2
    bit 7, [hl]
    res 7, [hl]
    ret nz

    call LoadMon_441b
    ld hl, $1502
    rst $10
    ld hl, $c8a2
    res 1, [hl]
    ret


    ld a, [$c86c]
    or a
    jr z, jr_003_41c7

    ld a, [$c863]
    bit 0, a
    jr z, jr_003_41c7

    call LoadMon_41c8

jr_003_41c7:
    ret


LoadMon_41c8:
    ld a, [$c866]
    rst $00
    ret nc

    ld b, c
    call nc, $cd41
    push de
    ld b, d
    ret


    call LoadMon_4387
    ld hl, $c8a2
    bit 7, [hl]
    res 7, [hl]
    ret nz

    call LoadMon_441b
    ld hl, $1503
    rst $10
    ld hl, $c8a2
    res 1, [hl]
    ret


    ld a, [$c863]
    bit 1, a
    jr nz, jr_003_41fd

    ld a, $01
    ld [$c866], a
    ld a, $f9
    jp Jump_000_1275


jr_003_41fd:
    ld a, [$c8a2]
    bit 1, a
    jr nz, jr_003_4226

    ldh a, [rSB]
    ld [$c86a], a
    ld a, [$c844]
    ld [$c845], a
    ld a, [$c86a]
    ld [$c844], a
    call UpdateSGBJoypad
    call UpdateJoypadState
    ld a, $01
    ld [$c866], a
    ld a, [$c842]
    jp Jump_000_126b


Jump_003_4226:
jr_003_4226:
    ld a, $20

jr_003_4228:
    dec a
    jr nz, jr_003_4228

    ld hl, $c8a2
    set 2, [hl]
    ld a, $01
    ld [$c866], a
    ld a, $f3
    jp Jump_000_126b


    ld a, [$c863]
    bit 1, a
    jr nz, jr_003_42a6

    ld a, [$c8c7]
    or a
    jr nz, jr_003_4253

    ldh a, [rSB]
    ld [$c86a], a
    cp $f3
    jp z, Jump_003_4279

    jr jr_003_4258

jr_003_4253:
    ldh a, [rSB]
    ld [$c86a], a

jr_003_4258:
    ld hl, $c8a2
    set 1, [hl]
    ld a, [$c844]
    ld [$c845], a
    ld a, [$c86a]
    ld [$c844], a
    call UpdateJoypadState
    call LoadMon_441b
    xor a
    ld [$c866], a
    ld hl, $c8a2
    res 1, [hl]
    ret


Jump_003_4279:
    ld a, [$c84e]
    ld [$c842], a
    ld a, [$c84f]
    ld [$c843], a
    ld a, [$c873]
    cp $ff
    jr nz, jr_003_429c

    ld a, [$c874]
    sub $01
    ld [$c874], a
    ld a, [$c875]
    sbc $00
    ld [$c875], a

jr_003_429c:
    xor a
    ld [$c866], a
    ld hl, $c8a2
    set 7, [hl]
    ret


jr_003_42a6:
    ld hl, $c8a2
    bit 2, [hl]
    jr nz, jr_003_42c1

    set 1, [hl]
    xor a
    ld [$c866], a
    ld a, $fa
    call SerialTransfer
    call LoadMon_441b
    ld hl, $c8a2
    res 1, [hl]
    ret


Jump_003_42c1:
jr_003_42c1:
    ld hl, $c8a2
    res 2, [hl]
    xor a
    ld [$c866], a
    ld a, $fb
    call SerialTransfer
    ld hl, $c8a2
    set 7, [hl]
    ret


LoadMon_42d5:
    ld a, [$c863]
    bit 1, a
    jr nz, jr_003_42e6

    ld a, $01
    ld [$c866], a
    ld a, $f9
    jp Jump_000_1275


jr_003_42e6:
    ld a, [$c8a2]
    bit 1, a
    jp nz, Jump_003_4226

    ld a, [$c873]
    cp $ff
    jr z, jr_003_4311

    ldh a, [rSB]
    ld [$c86a], a
    ld a, [$c86a]
    ld [$c86e], a
    call UpdateSGBJoypad
    call UpdateJoypadState
    ld a, $01
    ld [$c866], a
    ld a, [$c873]
    jp Jump_000_126b


jr_003_4311:
    ld hl, $c871
    ld a, [hl+]
    or [hl]
    jr z, jr_003_436c

    ld a, [$c86f]
    ld l, a
    ld a, [$c870]
    ld h, a
    ldh a, [rSB]
    ld [hl], a
    call UpdateSGBJoypad
    call UpdateJoypadState
    ld a, [$c86f]
    add $01
    ld [$c86f], a
    ld a, [$c870]
    adc $00
    ld [$c870], a
    ld a, [$c871]
    sub $01
    ld [$c871], a
    ld a, [$c872]
    sbc $00
    ld [$c872], a
    ld a, [$c874]
    ld l, a
    ld a, [$c875]
    ld h, a
    push hl
    ld a, [$c874]
    add $01
    ld [$c874], a
    ld a, [$c875]
    adc $00
    ld [$c875], a
    pop hl
    ld a, $01
    ld [$c866], a
    ld a, [hl]
    jp Jump_000_126b


jr_003_436c:
    ld a, $01
    ld [$c866], a
    ldh a, [rSB]
    ld [$c86a], a
    ld a, [$c86a]
    ld [$c86e], a
    call UpdateSGBJoypad
    call UpdateJoypadState
    ld a, $f0
    jp Jump_000_126b


LoadMon_4387:
    ld a, [$c863]
    bit 1, a
    jr nz, jr_003_4407

    ld a, [$c8c7]
    or a
    jr nz, jr_003_43a0

    ldh a, [rSB]
    ld [$c86a], a
    cp $f3
    jp z, Jump_003_4279

    jr jr_003_43a5

jr_003_43a0:
    ldh a, [rSB]
    ld [$c86a], a

jr_003_43a5:
    ld hl, $c8a2
    set 1, [hl]
    ld a, [$c873]
    cp $ff
    jr z, jr_003_43bf

    ld a, [$c86a]
    ld [$c86e], a
    call UpdateJoypadState
    xor a
    ld [$c866], a
    ret


jr_003_43bf:
    ld hl, $c871
    ld a, [hl+]
    or [hl]
    jr z, jr_003_43f9

    ld a, [$c86f]
    ld l, a
    ld a, [$c870]
    ld h, a
    ldh a, [rSB]
    ld [hl], a
    call UpdateJoypadState
    ld a, [$c86f]
    add $01
    ld [$c86f], a
    ld a, [$c870]
    adc $00
    ld [$c870], a
    ld a, [$c871]
    sub $01
    ld [$c871], a
    ld a, [$c872]
    sbc $00
    ld [$c872], a
    xor a
    ld [$c866], a
    ret


jr_003_43f9:
    ld a, [$c86a]
    ld [$c86e], a
    call UpdateJoypadState
    xor a
    ld [$c866], a
    ret


jr_003_4407:
    ld hl, $c8a2
    bit 2, [hl]
    jp nz, Jump_003_42c1

    set 1, [hl]
    xor a
    ld [$c866], a
    ld a, $fa
    call SerialTransfer
    ret


LoadMon_441b:
    ld a, [$c825]
    or a
    jr z, jr_003_4424

    call CheckState_C826_0618

jr_003_4424:
    call CheckState_C850_17EC
    ld a, [$c8a4]
    add $01
    ld [$c8a4], a
    ld a, [$c8a5]
    adc $00
    ld [$c8a5], a
    xor a
    ld [$c8c8], a
    ld [$c8c9], a
    ret

; MonsterInfoLoad — Entry 1: Load monster info to $DA33
; Input: $DA31 = species ID
; Output: 43 bytes copied to $DA33-$DA5D
label443f:
    ld de, $da33             ; destination = WRAM $DA33
    call SaveMon_4446
    ret


; MonsterInfoCopy — Calculate table address and copy 43 bytes
; Input: $DA31 = species ID, DE = destination
; Calculates: $4461 + species_id × 43($2B)
SaveMon_4446:
    push de
    ld a, [wTempSpeciesId]            ; species ID
    ld c, $2b                ; 43 = entry size
    call Mul8x8To16       ; HL = species_id × 43
    ld a, l
    add $61                  ; HL += $4461 (monster info table base)
    ld l, a
    ld a, h
    adc $44
    ld h, a
    pop de
    ld b, $2b                ; copy 43 bytes

jr_003_445a:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, jr_003_445a

    ret


; ---------------------------------------------------------------
; Monster Info Table ($4461)
; 221 entries x 43 bytes = 9503 bytes
;
; Format (43 bytes per entry):
;   +$00  Family (0=Slime..9=Boss)
;   +$01  Level cap
;   +$02  Exp table index
;   +$03  Female ratio (0=0%, 1=~10%, 2=50/50, 3=~84%)
;   +$04  Can fly       +$05  Metal body
;   +$06  Skill 1 ID    +$07  Skill 2 ID    +$08  Skill 3 ID
;   +$09  HP growth     +$0A  MP growth
;   +$0B  ATK growth    +$0C  DEF growth
;   +$0D  AGL growth    +$0E  INT growth
;   +$0F-$29  Resistances (27 bytes: A-Z + unused)
;             0=weak, 1=some resist, 2=normal, 3=immune
;   +$2A  Tier/rank
; ---------------------------------------------------------------

MonsterInfoTable:
; --- Monster $00 (0): DrakSlime ---
MonsterInfo_000_DrakSlime:
    db 0  ; Family: Slime
    db 45  ; Level cap
    db 13  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 67, 92, 213  ; Skills: SuckAir, FireAir, BeDragon
    db 16, 10, 13, 8, 20, 16  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 0, 0, 0, 2, 2, 2, 2, 2, 2, 2, 2  ; Resist A-N: Fire..AglDown
    db 3, 2, 2, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $01 (1): SpotSlime ---
MonsterInfo_001_SpotSlime:
    db 0  ; Family: Slime
    db 35  ; Level cap
    db 10  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 82, 121, 127  ; Skills: CallHelp, LushLicks, Imitate
    db 17, 1, 17, 4, 17, 8  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 3, 3  ; Resist A-N: Fire..AglDown
    db 2, 2, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $02 (2): WingSlime ---
MonsterInfo_002_WingSlime:
    db 0  ; Family: Slime
    db 35  ; Level cap
    db 10  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 85, 88, 138  ; Skills: SquallHit, WindBeast, TailWind
    db 13, 2, 11, 11, 24, 8  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 1, 1, 0, 2, 2, 2, 2, 2, 2, 2, 2  ; Resist A-N: Fire..AglDown
    db 2, 2, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $03 (3): TreeSlime ---
MonsterInfo_003_TreeSlime:
    db 0  ; Family: Slime
    db 50  ; Level cap
    db 11  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 28, 105, 106  ; Skills: Sap, Paralyze, SleepAir
    db 13, 11, 8, 14, 17, 17  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 1, 1, 0, 2, 2, 2, 3, 3, 2, 2, 2  ; Resist A-N: Fire..AglDown
    db 2, 2, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $04 (4): Snaily ---
MonsterInfo_004_Snaily:
    db 0  ; Family: Slime
    db 30  ; Level cap
    db 8  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 12, 52, 82  ; Skills: IceBolt, NumbOff, CallHelp
    db 11, 10, 17, 20, 20, 8  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 2, 3, 2, 2, 3, 2, 2, 2  ; Resist A-N: Fire..AglDown
    db 2, 2, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $05 (5): SlimeNite ---
MonsterInfo_005_SlimeNite:
    db 0  ; Family: Slime
    db 40  ; Level cap
    db 15  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 30, 43, 74  ; Skills: Upper, Heal, BeastCut
    db 14, 1, 15, 14, 20, 14  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 1, 1, 1, 2, 2, 3, 2, 2, 2, 2, 2  ; Resist A-N: Fire..AglDown
    db 3, 2, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $06 (6): Babble ---
MonsterInfo_006_Babble:
    db 0  ; Family: Slime
    db 45  ; Level cap
    db 12  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 24, 103, 116  ; Skills: Surround, PoisonHit, EerieLite
    db 17, 7, 17, 8, 14, 13  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 3, 3, 3, 2, 2, 3, 2, 2  ; Resist A-N: Fire..AglDown
    db 2, 2, 0, 0, 3, 1, 1, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $07 (7): BoxSlime ---
MonsterInfo_007_BoxSlime:
    db 0  ; Family: Slime
    db 50  ; Level cap
    db 11  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 0, 30, 60  ; Skills: Blaze, Upper, Ramming
    db 11, 10, 14, 19, 14, 13  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 1, 0, 0, 1, 2, 2, 3, 2, 2, 2, 2, 2  ; Resist A-N: Fire..AglDown
    db 3, 2, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $08 (8): Slime ---
MonsterInfo_008_Slime:
    db 0  ; Family: Slime
    db 40  ; Level cap
    db 16  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 3, 102, 115  ; Skills: Firebal, MegaMagic, Radiant
    db 22, 11, 14, 17, 11, 13  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 2, 2  ; Resist A-N: Fire..AglDown
    db 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 0  ; Tier/rank

; --- Monster $09 (9): Healer ---
MonsterInfo_009_Healer:
    db 0  ; Family: Slime
    db 50  ; Level cap
    db 11  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 30, 43, 46  ; Skills: Upper, Heal, HealUs
    db 11, 15, 11, 11, 20, 18  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 1, 1, 0, 2, 2, 2, 3, 3, 2, 2, 2  ; Resist A-N: Fire..AglDown
    db 2, 2, 0, 0, 0, 0, 0, 1, 2, 2, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $0A (10): FangSlime ---
MonsterInfo_010_FangSlime:
    db 0  ; Family: Slime
    db 35  ; Level cap
    db 10  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 65, 82, 125  ; Skills: ChargeUP, CallHelp, WarCry
    db 25, 1, 18, 13, 20, 13  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 2, 2, 3, 2, 2, 2, 3, 3  ; Resist A-N: Fire..AglDown
    db 3, 2, 0, 0, 0, 1, 0, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $0B (11): RockSlime ---
MonsterInfo_011_RockSlime:
    db 0  ; Family: Slime
    db 50  ; Level cap
    db 11  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 66, 91, 142  ; Skills: HighJump, RockThrow, StrongD
    db 13, 10, 14, 23, 16, 14  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 1, 0, 0, 2, 2, 2, 3, 2, 2, 2, 2, 2  ; Resist A-N: Fire..AglDown
    db 3, 2, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $0C (12): SlimeBorg ---
MonsterInfo_012_SlimeBorg:
    db 0  ; Family: Slime
    db 50  ; Level cap
    db 11  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 87, 90, 144  ; Skills: RainSlash, Lightning, BladeD
    db 18, 11, 20, 15, 14, 13  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 0, 1, 2, 1, 2, 2, 3, 2, 2, 3, 2, 2  ; Resist A-N: Fire..AglDown
    db 3, 2, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $0D (13): Slabbit ---
MonsterInfo_013_Slabbit:
    db 0  ; Family: Slime
    db 35  ; Level cap
    db 10  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 119, 123, 126  ; Skills: SideStep, LegSweep, Whistle
    db 15, 7, 14, 8, 21, 15  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 3, 3  ; Resist A-N: Fire..AglDown
    db 2, 2, 0, 0, 0, 0, 0, 2, 1, 1, 2, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $0E (14): SpotKing ---
MonsterInfo_014_SpotKing:
    db 0  ; Family: Slime
    db 40  ; Level cap
    db 9  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 78, 104, 146  ; Skills: CleanCut, NapAttack, MouthShut
    db 18, 11, 18, 11, 20, 15  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 0, 0, 1, 3, 2, 3, 2, 2, 3, 3, 3  ; Resist A-N: Fire..AglDown
    db 3, 2, 1, 1, 0, 1, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $0F (15): KingSlime ---
MonsterInfo_015_KingSlime:
    db 0  ; Family: Slime
    db 40  ; Level cap
    db 12  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 36, 43, 48  ; Skills: Barrier, Heal, Vivify
    db 18, 14, 15, 14, 20, 15  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 1, 1, 1, 3, 2, 3, 2, 2, 3, 3, 3  ; Resist A-N: Fire..AglDown
    db 3, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $10 (16): Metaly ---
MonsterInfo_016_Metaly:
    db 0  ; Family: Slime
    db 20  ; Level cap
    db 25  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 1  ; Can fly: no, Metal: yes
    db 0, 12, 18  ; Skills: Blaze, IceBolt, Beat
    db 0, 30, 11, 30, 31, 13  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3  ; Resist A-N: Fire..AglDown
    db 3, 1, 3, 3, 3, 3, 3, 0, 0, 0, 3, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $11 (17): Metabble ---
MonsterInfo_017_Metabble:
    db 0  ; Family: Slime
    db 40  ; Level cap
    db 27  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 1  ; Can fly: no, Metal: yes
    db 3, 6, 20  ; Skills: Firebal, Bang, Sacrifice
    db 0, 30, 14, 31, 31, 15  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3  ; Resist A-N: Fire..AglDown
    db 3, 2, 3, 3, 3, 3, 3, 0, 0, 0, 3, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $12 (18): MetalKing ---
MonsterInfo_018_MetalKing:
    db 0  ; Family: Slime
    db 60  ; Level cap
    db 29  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 1  ; Can fly: no, Metal: yes
    db 15, 42, 100  ; Skills: Bolt, Ironize, Hellblast
    db 0, 31, 15, 31, 31, 18  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3  ; Resist A-N: Fire..AglDown
    db 3, 2, 3, 3, 3, 3, 3, 0, 0, 0, 3, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $13 (19): GoldSlime ---
MonsterInfo_019_GoldSlime:
    db 0  ; Family: Slime
    db 80  ; Level cap
    db 31  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 57, 101, 129  ; Skills: Chance, BigBang, Surge
    db 0, 31, 19, 31, 31, 18  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3  ; Resist A-N: Fire..AglDown
    db 3, 2, 3, 3, 3, 3, 3, 1, 1, 1, 3, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $14 (20): DragonKid ---
MonsterInfo_020_DragonKid:
    db 1  ; Family: Dragon
    db 25  ; Level cap
    db 7  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 92, 106, 140  ; Skills: FireAir, SleepAir, Dodge
    db 10, 3, 17, 2, 5, 5  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 2, 2, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $15 (21): Tortragon ---
MonsterInfo_021_Tortragon:
    db 1  ; Family: Dragon
    db 35  ; Level cap
    db 17  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 39, 42, 90  ; Skills: MagicBack, Ironize, Lightning
    db 15, 11, 18, 6, 7, 13  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1  ; Resist A-N: Fire..AglDown
    db 2, 0, 2, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $16 (22): Pteranod ---
MonsterInfo_022_Pteranod:
    db 1  ; Family: Dragon
    db 35  ; Level cap
    db 16  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 3, 88, 138  ; Skills: Firebal, WindBeast, TailWind
    db 14, 11, 18, 2, 20, 4  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 2, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $17 (23): Gasgon ---
MonsterInfo_023_Gasgon:
    db 1  ; Family: Dragon
    db 50  ; Level cap
    db 18  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 20, 50, 61  ; Skills: Sacrifice, Farewell, Beserker
    db 17, 15, 13, 11, 7, 18  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 2, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $18 (24): FairyDrak ---
MonsterInfo_024_FairyDrak:
    db 1  ; Family: Dragon
    db 30  ; Level cap
    db 15  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 24, 106, 121  ; Skills: Surround, SleepAir, LushLicks
    db 9, 13, 17, 16, 14, 4  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 2, 0, 1, 1, 1, 0, 0, 0, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $19 (25): LizardMan ---
MonsterInfo_025_LizardMan:
    db 1  ; Family: Dragon
    db 40  ; Level cap
    db 20  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 64, 74, 217  ; Skills: EvilSlash, BeastCut, GigaSlash
    db 17, 10, 19, 13, 5, 16  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $1A (26): Poisongon ---
MonsterInfo_026_Poisongon:
    db 1  ; Family: Dragon
    db 45  ; Level cap
    db 19  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 103, 108, 121  ; Skills: PoisonHit, PoisonGas, LushLicks
    db 21, 16, 15, 13, 7, 1  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 2, 0, 2, 1, 1, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $1B (27): Swordgon ---
MonsterInfo_027_Swordgon:
    db 1  ; Family: Dragon
    db 50  ; Level cap
    db 20  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 78, 87, 144  ; Skills: CleanCut, RainSlash, BladeD
    db 9, 3, 23, 6, 1, 5  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 3, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $1C (28): Dragon ---
MonsterInfo_028_Dragon:
    db 1  ; Family: Dragon
    db 40  ; Level cap
    db 20  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 68, 92, 143  ; Skills: FireSlash, FireAir, SuckAll
    db 17, 1, 20, 16, 7, 4  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 0, 0, 0, 0, 2, 0, 0, 0, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $1D (29): MiniDrak ---
MonsterInfo_029_MiniDrak:
    db 1  ; Family: Dragon
    db 35  ; Level cap
    db 16  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 60, 82, 114  ; Skills: Ramming, CallHelp, SandStorm
    db 14, 8, 17, 14, 18, 10  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 2, 0, 0, 0, 0, 2, 1, 2, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $1E (30): MadDragon ---
MonsterInfo_030_MadDragon:
    db 1  ; Family: Dragon
    db 35  ; Level cap
    db 19  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 63, 64, 120  ; Skills: Massacre, EvilSlash, LureDance
    db 19, 0, 21, 5, 8, 0  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1  ; Resist A-N: Fire..AglDown
    db 2, 0, 2, 0, 0, 0, 0, 2, 2, 1, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $1F (31): Rayburn ---
MonsterInfo_031_Rayburn:
    db 1  ; Family: Dragon
    db 35  ; Level cap
    db 17  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 70, 76, 103  ; Skills: VacuSlash, DevilCut, PoisonHit
    db 14, 2, 17, 16, 15, 5  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 2, 2, 0, 0, 2, 0, 0, 0, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 2, 1, 0, 0, 0, 0, 2, 1, 2, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $20 (32): Chamelgon ---
MonsterInfo_032_Chamelgon:
    db 1  ; Family: Dragon
    db 50  ; Level cap
    db 19  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 25, 105, 107  ; Skills: PanicAll, Paralyze, PalsyAir
    db 17, 18, 11, 6, 8, 13  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 2, 2, 0, 0, 0, 0, 0, 2, 1, 0, 3, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $21 (33): LizardFly ---
MonsterInfo_033_LizardFly:
    db 1  ; Family: Dragon
    db 30  ; Level cap
    db 16  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 3, 88, 92  ; Skills: Firebal, WindBeast, FireAir
    db 11, 11, 17, 17, 13, 5  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 2, 2, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 3, 0, 1, 1, 1, 0, 0, 0, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $22 (34): Andreal ---
MonsterInfo_034_Andreal:
    db 1  ; Family: Dragon
    db 50  ; Level cap
    db 22  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 9, 24, 108  ; Skills: Infernos, Surround, PoisonGas
    db 21, 15, 19, 17, 19, 12  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 0, 0, 0, 0, 2, 2, 2, 0, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 2, 2, 0, 0, 0, 1, 1, 1, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $23 (35): KingCobra ---
MonsterInfo_035_KingCobra:
    db 1  ; Family: Dragon
    db 40  ; Level cap
    db 20  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 103, 111, 113  ; Skills: PoisonHit, Curse, K.O.Dance
    db 18, 8, 16, 13, 19, 11  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 2, 2, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 1, 2, 0, 2, 0, 2, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $24 (36): Spikerous ---
MonsterInfo_036_Spikerous:
    db 1  ; Family: Dragon
    db 30  ; Level cap
    db 19  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 61, 62, 91  ; Skills: Beserker, Kamikaze, RockThrow
    db 20, 8, 19, 24, 1, 2  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 2, 0, 1, 1, 1, 0, 0, 0, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $25 (37): GreatDrak ---
MonsterInfo_037_GreatDrak:
    db 1  ; Family: Dragon
    db 60  ; Level cap
    db 23  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 71, 96, 143  ; Skills: IceSlash, FrigidAir, SuckAll
    db 21, 5, 23, 14, 16, 11  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 3, 2, 1, 1, 1, 1, 2, 3, 1, 1, 2, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 0, 3, 1, 1, 3, 1, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $26 (38): Crestpent ---
MonsterInfo_038_Crestpent:
    db 1  ; Family: Dragon
    db 35  ; Level cap
    db 18  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 23, 103, 213  ; Skills: StopSpell, PoisonHit, BeDragon
    db 14, 4, 15, 5, 19, 8  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 2, 0, 0, 0, 0, 2, 2, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $27 (39): WingSnake ---
MonsterInfo_039_WingSnake:
    db 1  ; Family: Dragon
    db 45  ; Level cap
    db 20  ; Exp table
    db 1  ; Female ratio (~10%)
    db 0, 0  ; Can fly: no, Metal: no
    db 66, 85, 108  ; Skills: HighJump, SquallHit, PoisonGas
    db 15, 8, 20, 17, 14, 11  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 3, 3, 2, 1, 1, 0, 0, 0, 2, 0, 1, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 3, 0, 0, 0, 0, 2, 2, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $28 (40): Coatol ---
MonsterInfo_040_Coatol:
    db 1  ; Family: Dragon
    db 60  ; Level cap
    db 23  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 6, 64, 69  ; Skills: Bang, EvilSlash, BoltSlash
    db 25, 14, 20, 22, 18, 14  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 1, 3, 1, 1, 1, 1, 2, 2, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $29 (41): Orochi ---
MonsterInfo_041_Orochi:
    db 1  ; Family: Dragon
    db 60  ; Level cap
    db 22  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 68, 80, 92  ; Skills: FireSlash, BiAttack, FireAir
    db 24, 13, 24, 21, 11, 8  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 1, 1, 1, 2, 2, 2, 1, 1, 3, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 0, 3, 1, 2, 2, 2, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $2A (42): BattleRex ---
MonsterInfo_042_BattleRex:
    db 1  ; Family: Dragon
    db 60  ; Level cap
    db 22  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 64, 72, 92  ; Skills: EvilSlash, MetalCut, FireAir
    db 23, 16, 26, 20, 17, 16  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 2, 2, 1, 1, 2, 2, 1, 1, 1, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 0, 3, 1, 1, 2, 1, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $2B (43): SkyDragon ---
MonsterInfo_043_SkyDragon:
    db 1  ; Family: Dragon
    db 35  ; Level cap
    db 18  ; Exp table
    db 3  ; Female ratio (~84%)
    db 1, 0  ; Can fly: yes, Metal: no
    db 67, 79, 92  ; Skills: SuckAir, MultiCut, FireAir
    db 15, 11, 20, 14, 18, 8  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 2, 2, 2, 2, 1, 1, 2, 2, 1, 1, 1, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 0, 3, 1, 1, 2, 1, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $2C (44): Divinegon ---
MonsterInfo_044_Divinegon:
    db 1  ; Family: Dragon
    db 80  ; Level cap
    db 28  ; Exp table
    db 3  ; Female ratio (~84%)
    db 1, 0  ; Can fly: yes, Metal: no
    db 96, 101, 147  ; Skills: FrigidAir, BigBang, Meditate
    db 26, 25, 28, 24, 20, 23  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 3, 3, 2, 2, 2, 2, 2, 3, 2, 2, 3, 2, 2  ; Resist A-N: Fire..AglDown
    db 3, 1, 3, 2, 2, 3, 2, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $2D (45): Tonguella ---
MonsterInfo_045_Tonguella:
    db 2  ; Family: Beast
    db 40  ; Level cap
    db 12  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 104, 106, 121  ; Skills: NapAttack, SleepAir, LushLicks
    db 14, 5, 15, 12, 11, 16  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 3, 3  ; Resist A-N: Fire..AglDown
    db 1, 1, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $2E (46): Almiraj ---
MonsterInfo_046_Almiraj:
    db 2  ; Family: Beast
    db 45  ; Level cap
    db 13  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 21, 61, 65  ; Skills: Sleep, Beserker, ChargeUP
    db 18, 5, 14, 9, 15, 4  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2  ; Resist A-N: Fire..AglDown
    db 1, 0, 1, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $2F (47): CatFly ---
MonsterInfo_047_CatFly:
    db 2  ; Family: Beast
    db 35  ; Level cap
    db 10  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 23, 32, 117  ; Skills: StopSpell, Slow, OddDance
    db 11, 10, 13, 8, 18, 14  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 2, 2  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 0, 0, 0, 3, 3, 3, 3, 3, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $30 (48): PillowRat ---
MonsterInfo_048_PillowRat:
    db 2  ; Family: Beast
    db 50  ; Level cap
    db 11  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 60, 82, 119  ; Skills: Ramming, CallHelp, SideStep
    db 14, 17, 8, 8, 19, 13  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 2, 2  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 0, 0, 0, 3, 3, 3, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $31 (49): Saccer ---
MonsterInfo_049_Saccer:
    db 2  ; Family: Beast
    db 40  ; Level cap
    db 9  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 30, 86, 107  ; Skills: Upper, PsycheUp, PalsyAir
    db 16, 5, 9, 17, 0, 13  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 2, 2  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $32 (50): GulpBeast ---
MonsterInfo_050_GulpBeast:
    db 2  ; Family: Beast
    db 45  ; Level cap
    db 13  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 60, 63, 125  ; Skills: Ramming, Massacre, WarCry
    db 24, 1, 26, 13, 7, 1  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 2, 2  ; Resist A-N: Fire..AglDown
    db 1, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $33 (51): Skullroo ---
MonsterInfo_051_Skullroo:
    db 2  ; Family: Beast
    db 45  ; Level cap
    db 12  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 65, 73, 110  ; Skills: ChargeUP, DrakSlash, PaniDance
    db 14, 10, 11, 8, 16, 2  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 2, 2  ; Resist A-N: Fire..AglDown
    db 1, 0, 0, 0, 1, 1, 1, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $34 (52): WindBeast ---
MonsterInfo_052_WindBeast:
    db 2  ; Family: Beast
    db 50  ; Level cap
    db 12  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 9, 12, 70  ; Skills: Infernos, IceBolt, VacuSlash
    db 13, 20, 13, 15, 15, 13  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 2, 0, 1, 0, 0, 1, 0, 0, 0, 2, 2  ; Resist A-N: Fire..AglDown
    db 1, 0, 0, 1, 0, 0, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $35 (53): Anteater ---
MonsterInfo_053_Anteater:
    db 2  ; Family: Beast
    db 40  ; Level cap
    db 8  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 72, 85, 121  ; Skills: MetalCut, SquallHit, LushLicks
    db 14, 7, 17, 11, 9, 11  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 0  ; Tier/rank

; --- Monster $36 (54): SuperTen ---
MonsterInfo_054_SuperTen:
    db 2  ; Family: Beast
    db 45  ; Level cap
    db 9  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 113, 127, 148  ; Skills: K.O.Dance, Imitate, Hustle
    db 18, 7, 13, 12, 11, 7  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 1, 2, 1, 0, 0, 2, 2, 2  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $37 (55): IronTurt ---
MonsterInfo_055_IronTurt:
    db 2  ; Family: Beast
    db 45  ; Level cap
    db 10  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 39, 136, 142  ; Skills: MagicBack, Cover, StrongD
    db 18, 5, 17, 23, 2, 11  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 2, 2  ; Resist A-N: Fire..AglDown
    db 1, 0, 2, 2, 0, 0, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $38 (56): Mommonja ---
MonsterInfo_056_Mommonja:
    db 2  ; Family: Beast
    db 35  ; Level cap
    db 11  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 12, 120, 146  ; Skills: IceBolt, LureDance, MouthShut
    db 14, 11, 16, 14, 20, 8  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 2, 2  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 0, 0, 0, 3, 3, 3, 3, 3, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $39 (57): HammerMan ---
MonsterInfo_057_HammerMan:
    db 2  ; Family: Beast
    db 50  ; Level cap
    db 11  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 62, 64, 65  ; Skills: Kamikaze, EvilSlash, ChargeUP
    db 17, 19, 17, 11, 17, 10  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 1, 1, 0, 0, 0, 0, 2, 2, 0, 2, 2  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 0, 0, 0, 3, 3, 3, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $3A (58): Grizzly ---
MonsterInfo_058_Grizzly:
    db 2  ; Family: Beast
    db 40  ; Level cap
    db 14  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 59, 85, 123  ; Skills: TwinSlash, SquallHit, LegSweep
    db 20, 0, 27, 7, 9, 1  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 2, 2  ; Resist A-N: Fire..AglDown
    db 1, 0, 0, 0, 0, 0, 0, 3, 2, 2, 3, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $3B (59): Yeti ---
MonsterInfo_059_Yeti:
    db 2  ; Family: Beast
    db 40  ; Level cap
    db 13  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 12, 71, 125  ; Skills: IceBolt, IceSlash, WarCry
    db 18, 11, 15, 9, 10, 8  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 1, 1, 2, 0, 0, 1, 0, 0, 0, 2, 2  ; Resist A-N: Fire..AglDown
    db 1, 0, 0, 3, 0, 0, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $3C (60): MadGopher ---
MonsterInfo_060_MadGopher:
    db 2  ; Family: Beast
    db 50  ; Level cap
    db 12  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 65, 75, 77  ; Skills: ChargeUP, BirdBlow, ZombieCut
    db 14, 13, 17, 9, 8, 11  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 0, 0, 0, 1, 0, 0, 2, 0, 0, 0, 2, 2  ; Resist A-N: Fire..AglDown
    db 2, 0, 1, 1, 0, 0, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $3D (61): FairyRat ---
MonsterInfo_061_FairyRat:
    db 2  ; Family: Beast
    db 45  ; Level cap
    db 11  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 24, 32, 214  ; Skills: Surround, Slow, Smashlime
    db 12, 5, 13, 14, 17, 7  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 0, 0, 1, 0, 1, 0, 0, 0, 1, 2, 2  ; Resist A-N: Fire..AglDown
    db 1, 0, 1, 1, 0, 0, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $3E (62): Unicorn ---
MonsterInfo_062_Unicorn:
    db 2  ; Family: Beast
    db 50  ; Level cap
    db 14  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 43, 48, 51  ; Skills: Heal, Vivify, Antidote
    db 19, 21, 14, 13, 12, 25  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 1, 2, 2, 1, 1, 2, 3, 3  ; Resist A-N: Fire..AglDown
    db 1, 1, 0, 2, 0, 1, 1, 3, 2, 2, 3, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $3F (63): Goategon ---
MonsterInfo_063_Goategon:
    db 2  ; Family: Beast
    db 40  ; Level cap
    db 11  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 3, 32, 106  ; Skills: Firebal, Slow, SleepAir
    db 19, 9, 17, 13, 17, 3  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 1, 1, 0, 0, 2, 1, 1, 1, 1, 1, 1, 3, 3  ; Resist A-N: Fire..AglDown
    db 1, 1, 1, 2, 0, 0, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $40 (64): WildApe ---
MonsterInfo_064_WildApe:
    db 2  ; Family: Beast
    db 35  ; Level cap
    db 13  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 59, 82, 123  ; Skills: TwinSlash, CallHelp, LegSweep
    db 13, 1, 20, 10, 8, 4  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 2, 2  ; Resist A-N: Fire..AglDown
    db 1, 0, 0, 0, 0, 0, 0, 3, 3, 3, 3, 3, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $41 (65): Trumpeter ---
MonsterInfo_065_Trumpeter:
    db 2  ; Family: Beast
    db 50  ; Level cap
    db 14  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 61, 114, 125  ; Skills: Beserker, SandStorm, WarCry
    db 17, 8, 21, 17, 14, 13  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 1, 1, 1, 1, 1, 0, 0, 2, 0, 0, 1, 2, 3  ; Resist A-N: Fire..AglDown
    db 1, 0, 0, 1, 0, 0, 0, 3, 3, 3, 3, 3, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $42 (66): KingLeo ---
MonsterInfo_066_KingLeo:
    db 2  ; Family: Beast
    db 70  ; Level cap
    db 15  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 3, 80, 96  ; Skills: Firebal, BiAttack, FrigidAir
    db 20, 14, 24, 23, 17, 14  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 2, 2, 1, 1, 1, 3, 1, 1, 2, 3, 3  ; Resist A-N: Fire..AglDown
    db 3, 1, 1, 2, 1, 2, 1, 3, 3, 3, 3, 3, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $43 (67): DarkHorn ---
MonsterInfo_067_DarkHorn:
    db 2  ; Family: Beast
    db 50  ; Level cap
    db 13  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 21, 23, 86  ; Skills: Sleep, StopSpell, PsycheUp
    db 17, 4, 19, 18, 10, 12  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 0, 0, 0, 1, 1, 2, 3, 1, 3, 1, 3, 3  ; Resist A-N: Fire..AglDown
    db 3, 1, 1, 1, 0, 2, 1, 3, 3, 3, 3, 3, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $44 (68): MadCat ---
MonsterInfo_068_MadCat:
    db 2  ; Family: Beast
    db 40  ; Level cap
    db 12  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 70, 85, 123  ; Skills: VacuSlash, SquallHit, LegSweep
    db 15, 7, 18, 14, 17, 11  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 0, 0, 1, 0, 1, 3, 0, 0, 0, 2, 2  ; Resist A-N: Fire..AglDown
    db 3, 0, 1, 1, 0, 1, 0, 3, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $45 (69): BigEye ---
MonsterInfo_069_BigEye:
    db 2  ; Family: Beast
    db 40  ; Level cap
    db 11  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 12, 43, 96  ; Skills: IceBolt, Heal, FrigidAir
    db 14, 8, 14, 11, 7, 9  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 1, 1, 1, 0, 1, 3, 0, 2, 0, 2, 2  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 0, 0, 1, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $46 (70): Picky ---
MonsterInfo_070_Picky:
    db 3  ; Family: Flying
    db 40  ; Level cap
    db 4  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 24, 28, 215  ; Skills: Surround, Sap, Sheldodge
    db 11, 12, 14, 8, 18, 13  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 2, 2, 0, 1, 1, 1, 1, 1, 1, 1, 1  ; Resist A-N: Fire..AglDown
    db 1, 1, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $47 (71): Wyvern ---
MonsterInfo_071_Wyvern:
    db 3  ; Family: Flying
    db 45  ; Level cap
    db 6  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 21, 43, 96  ; Skills: Sleep, Heal, FrigidAir
    db 17, 13, 19, 11, 16, 20  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 1, 0, 1, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $48 (72): BullBird ---
MonsterInfo_072_BullBird:
    db 3  ; Family: Flying
    db 35  ; Level cap
    db 5  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 60, 65, 216  ; Skills: Ramming, ChargeUP, Branching
    db 14, 8, 17, 9, 6, 4  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 1, 1  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 0, 0, 0, 3, 3, 3, 3, 3, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $49 (73): Florajay ---
MonsterInfo_073_Florajay:
    db 3  ; Family: Flying
    db 50  ; Level cap
    db 5  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 34, 74, 149  ; Skills: Speed, BeastCut, LifeSong
    db 6, 18, 12, 3, 21, 19  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 3, 3, 0, 0, 0, 0, 1, 1, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 0, 0, 0, 3, 3, 3, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $4A (74): DuckKite ---
MonsterInfo_074_DuckKite:
    db 3  ; Family: Flying
    db 30  ; Level cap
    db 3  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 21, 25, 111  ; Skills: Sleep, PanicAll, Curse
    db 11, 11, 9, 12, 18, 7  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 2, 2, 0, 0, 1, 0, 0, 0, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $4B (75): MadPecker ---
MonsterInfo_075_MadPecker:
    db 3  ; Family: Flying
    db 40  ; Level cap
    db 4  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 9, 28, 70  ; Skills: Infernos, Sap, VacuSlash
    db 9, 7, 20, 14, 23, 13  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 3, 3, 1, 0, 0, 1, 0, 0, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 1, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $4C (76): MadRaven ---
MonsterInfo_076_MadRaven:
    db 3  ; Family: Flying
    db 45  ; Level cap
    db 5  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 66, 73, 138  ; Skills: HighJump, DrakSlash, TailWind
    db 6, 14, 17, 12, 18, 5  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 2, 2, 0, 1, 1, 1, 0, 0, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $4D (77): MistyWing ---
MonsterInfo_077_MistyWing:
    db 3  ; Family: Flying
    db 50  ; Level cap
    db 5  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 24, 36, 116  ; Skills: Surround, Barrier, EerieLite
    db 12, 17, 8, 15, 22, 13  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 2, 2, 1, 0, 0, 1, 0, 0, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 1, 0, 0, 1, 0, 0, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $4E (78): Dracky ---
MonsterInfo_078_Dracky:
    db 3  ; Family: Flying
    db 40  ; Level cap
    db 2  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 21, 26, 51  ; Skills: Sleep, RobMagic, Antidote
    db 11, 4, 8, 13, 17, 11  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 0  ; Tier/rank

; --- Monster $4F (79): BigRoost ---
MonsterInfo_079_BigRoost:
    db 3  ; Family: Flying
    db 40  ; Level cap
    db 3  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 70, 114, 140  ; Skills: VacuSlash, SandStorm, Dodge
    db 8, 5, 14, 12, 17, 8  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $50 (80): StubBird ---
MonsterInfo_080_StubBird:
    db 3  ; Family: Flying
    db 40  ; Level cap
    db 6  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 37, 87, 215  ; Skills: TwinHits, RainSlash, Sheldodge
    db 16, 12, 20, 20, 14, 11  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1  ; Resist A-N: Fire..AglDown
    db 1, 1, 0, 2, 0, 0, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $51 (81): LandOwl ---
MonsterInfo_081_LandOwl:
    db 3  ; Family: Flying
    db 35  ; Level cap
    db 7  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 9, 69, 119  ; Skills: Infernos, BoltSlash, SideStep
    db 15, 10, 21, 13, 11, 18  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 2, 2, 0, 0, 1, 1, 0, 0, 1, 2, 2  ; Resist A-N: Fire..AglDown
    db 1, 0, 0, 0, 0, 0, 0, 3, 3, 3, 3, 3, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $52 (82): MadGoose ---
MonsterInfo_082_MadGoose:
    db 3  ; Family: Flying
    db 30  ; Level cap
    db 5  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 25, 117, 120  ; Skills: PanicAll, OddDance, LureDance
    db 17, 6, 17, 15, 20, 8  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 2, 2, 0, 0, 2, 1, 0, 0, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 2, 1, 1, 2, 2, 2, 3, 3, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $53 (83): MadCondor ---
MonsterInfo_083_MadCondor:
    db 3  ; Family: Flying
    db 50  ; Level cap
    db 6  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 3, 46, 79  ; Skills: Firebal, HealUs, MultiCut
    db 14, 11, 18, 12, 17, 13  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 0, 2, 2, 1, 0, 0, 2, 0, 1, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 1, 2, 0, 0, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $54 (84): Blizzardy ---
MonsterInfo_084_Blizzardy:
    db 3  ; Family: Flying
    db 50  ; Level cap
    db 7  ; Exp table
    db 3  ; Female ratio (~84%)
    db 1, 0  ; Can fly: yes, Metal: no
    db 18, 71, 96  ; Skills: Beat, IceSlash, FrigidAir
    db 20, 7, 11, 17, 19, 11  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 0, 2, 2, 3, 0, 0, 2, 0, 0, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 1, 0, 1, 3, 0, 1, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $55 (85): Phoenix ---
MonsterInfo_085_Phoenix:
    db 3  ; Family: Flying
    db 50  ; Level cap
    db 7  ; Exp table
    db 1  ; Female ratio (~10%)
    db 1, 0  ; Can fly: yes, Metal: no
    db 85, 92, 138  ; Skills: SquallHit, FireAir, TailWind
    db 16, 13, 19, 8, 19, 12  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 0, 0, 3, 0, 0, 1, 0, 3, 3, 3, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $56 (86): ZapBird ---
MonsterInfo_086_ZapBird:
    db 3  ; Family: Flying
    db 50  ; Level cap
    db 7  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 69, 90, 100  ; Skills: BoltSlash, Lightning, Hellblast
    db 20, 7, 19, 17, 22, 12  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 3, 3, 1, 0, 0, 1, 2, 0, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 1, 0, 1, 1, 0, 1, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $57 (87): WhipBird ---
MonsterInfo_087_WhipBird:
    db 3  ; Family: Flying
    db 60  ; Level cap
    db 15  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 42, 131, 132  ; Skills: Ironize, ThickFog, TatsuCall
    db 27, 19, 12, 20, 23, 23  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 2, 2, 1, 1, 1, 2, 0, 0, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 1, 1, 0, 2, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $58 (88): FunkyBird ---
MonsterInfo_088_FunkyBird:
    db 3  ; Family: Flying
    db 50  ; Level cap
    db 5  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 110, 148, 150  ; Skills: PaniDance, Hustle, LifeDance
    db 14, 20, 8, 9, 16, 20  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 3, 3, 0, 1, 0, 2, 1, 1, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 0, 0, 2, 0, 3, 3, 3, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $59 (89): RainHawk ---
MonsterInfo_089_RainHawk:
    db 3  ; Family: Flying
    db 70  ; Level cap
    db 24  ; Exp table
    db 1  ; Female ratio (~10%)
    db 0, 0  ; Can fly: no, Metal: no
    db 102, 129, 142  ; Skills: MegaMagic, Surge, StrongD
    db 25, 27, 15, 24, 18, 24  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 3, 2, 2, 1, 1, 2, 1, 1, 3, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 1, 2, 3, 1, 2, 1, 3, 3, 3, 3, 3, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $5A (90): MadPlant ---
MonsterInfo_090_MadPlant:
    db 4  ; Family: Plant
    db 40  ; Level cap
    db 10  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 28, 32, 52  ; Skills: Sap, Slow, NumbOff
    db 15, 24, 11, 13, 6, 18  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 2, 2, 0, 1, 1, 1, 3, 3, 1, 1, 1  ; Resist A-N: Fire..AglDown
    db 1, 1, 0, 0, 0, 0, 0, 2, 2, 2, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $5B (91): FireWeed ---
MonsterInfo_091_FireWeed:
    db 4  ; Family: Plant
    db 45  ; Level cap
    db 15  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 0, 53, 107  ; Skills: Blaze, DeChaos, PalsyAir
    db 14, 26, 10, 12, 5, 17  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 2, 2, 0, 0, 0, 0, 2, 2, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 1, 0, 2, 0, 0, 0, 0, 2, 2, 2, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $5C (92): FloraMan ---
MonsterInfo_092_FloraMan:
    db 4  ; Family: Plant
    db 35  ; Level cap
    db 7  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 3, 51, 54  ; Skills: Firebal, Antidote, CurseOff
    db 17, 20, 6, 9, 2, 19  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 2, 2, 0, 0, 0, 0, 2, 2, 0, 1, 1  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 0, 0, 0, 3, 3, 3, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $5D (93): WingTree ---
MonsterInfo_093_WingTree:
    db 4  ; Family: Plant
    db 35  ; Level cap
    db 7  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 50, 55, 77  ; Skills: Farewell, StepGuard, ZombieCut
    db 12, 20, 6, 11, 14, 7  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 3, 3, 0, 0, 0, 0, 2, 2, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 0, 0, 0, 3, 3, 3, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $5E (94): CactiBall ---
MonsterInfo_094_CactiBall:
    db 4  ; Family: Plant
    db 30  ; Level cap
    db 6  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 66, 105, 117  ; Skills: HighJump, Paralyze, OddDance
    db 18, 18, 12, 15, 9, 5  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 2, 2, 0, 0, 1, 0, 2, 2, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $5F (95): Gulpple ---
MonsterInfo_095_Gulpple:
    db 4  ; Family: Plant
    db 40  ; Level cap
    db 11  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 9, 21, 104  ; Skills: Infernos, Sleep, NapAttack
    db 16, 17, 9, 6, 2, 14  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 2, 2, 1, 0, 0, 1, 2, 2, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 1, 0, 0, 0, 0, 0, 0, 2, 2, 2, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $60 (96): Toadstool ---
MonsterInfo_096_Toadstool:
    db 4  ; Family: Plant
    db 45  ; Level cap
    db 9  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 104, 106, 146  ; Skills: NapAttack, SleepAir, MouthShut
    db 14, 18, 8, 9, 13, 13  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 2, 2, 0, 1, 1, 1, 2, 2, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 1, 0, 0, 0, 1, 1, 1, 2, 2, 2, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $61 (97): AmberWeed ---
MonsterInfo_097_AmberWeed:
    db 4  ; Family: Plant
    db 50  ; Level cap
    db 12  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 36, 37, 38  ; Skills: Barrier, TwinHits, MagicWall
    db 12, 24, 8, 17, 12, 10  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 2, 2, 1, 0, 0, 1, 2, 2, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 1, 0, 0, 1, 0, 0, 0, 2, 2, 2, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $62 (98): Stubsuck ---
MonsterInfo_098_Stubsuck:
    db 4  ; Family: Plant
    db 40  ; Level cap
    db 8  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 21, 55, 77  ; Skills: Sleep, StepGuard, ZombieCut
    db 17, 11, 4, 2, 9, 14  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 2, 2, 0, 0, 0, 0, 2, 2, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $63 (99): Oniono ---
MonsterInfo_099_Oniono:
    db 4  ; Family: Plant
    db 35  ; Level cap
    db 9  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 26, 65, 106  ; Skills: RobMagic, ChargeUP, SleepAir
    db 13, 20, 14, 11, 3, 16  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 2, 2, 0, 0, 1, 0, 2, 2, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $64 (100): DanceVegi ---
MonsterInfo_100_DanceVegi:
    db 4  ; Family: Plant
    db 50  ; Level cap
    db 12  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 113, 119, 120  ; Skills: K.O.Dance, SideStep, LureDance
    db 11, 21, 7, 6, 20, 11  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 0, 2, 2, 1, 0, 0, 2, 3, 2, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 1, 0, 1, 1, 0, 0, 0, 2, 3, 3, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $65 (101): TreeBoy ---
MonsterInfo_101_TreeBoy:
    db 4  ; Family: Plant
    db 40  ; Level cap
    db 11  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 12, 43, 54  ; Skills: IceBolt, Heal, CurseOff
    db 15, 18, 8, 3, 12, 15  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 3, 3, 1, 0, 1, 2, 2, 2, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 0, 0, 0, 0, 2, 2, 2, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $66 (102): FaceTree ---
MonsterInfo_102_FaceTree:
    db 4  ; Family: Plant
    db 45  ; Level cap
    db 9  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 23, 111, 117  ; Skills: StopSpell, Curse, OddDance
    db 12, 20, 11, 8, 10, 17  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 2, 2, 0, 1, 2, 2, 2, 2, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 0, 1, 2, 2, 2, 2, 2, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $67 (103): HerbMan ---
MonsterInfo_103_HerbMan:
    db 4  ; Family: Plant
    db 40  ; Level cap
    db 13  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 84, 111, 145  ; Skills: Focus, Curse, DanceShut
    db 19, 17, 7, 10, 15, 23  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 3, 3, 0, 0, 0, 2, 2, 2, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 0, 0, 2, 0, 3, 3, 3, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $68 (104): BeanMan ---
MonsterInfo_104_BeanMan:
    db 4  ; Family: Plant
    db 35  ; Level cap
    db 10  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 26, 37, 56  ; Skills: RobMagic, TwinHits, MapMagic
    db 14, 15, 12, 14, 15, 9  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 2, 2, 0, 0, 0, 1, 2, 2, 0, 1, 1  ; Resist A-N: Fire..AglDown
    db 1, 0, 0, 0, 0, 0, 0, 3, 3, 3, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $69 (105): EvilSeed ---
MonsterInfo_105_EvilSeed:
    db 4  ; Family: Plant
    db 30  ; Level cap
    db 6  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 78, 105, 115  ; Skills: CleanCut, Paralyze, Radiant
    db 8, 11, 8, 5, 1, 3  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 3, 3, 1, 0, 0, 1, 2, 2, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 0, 0, 0, 0, 2, 2, 2, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $6A (106): ManEater ---
MonsterInfo_106_ManEater:
    db 4  ; Family: Plant
    db 50  ; Level cap
    db 9  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 73, 86, 106  ; Skills: DrakSlash, PsycheUp, SleepAir
    db 14, 12, 19, 7, 10, 6  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 2, 2, 1, 0, 0, 1, 3, 3, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 0, 0, 0, 0, 3, 3, 3, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $6B (107): Snapper ---
MonsterInfo_107_Snapper:
    db 4  ; Family: Plant
    db 60  ; Level cap
    db 11  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 23, 82, 87  ; Skills: StopSpell, CallHelp, RainSlash
    db 17, 14, 20, 13, 10, 16  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 2, 2, 1, 0, 0, 2, 3, 3, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 0, 0, 0, 0, 3, 3, 3, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $6C (108): Rosevine ---
MonsterInfo_108_Rosevine:
    db 4  ; Family: Plant
    db 80  ; Level cap
    db 24  ; Exp table
    db 3  ; Female ratio (~84%)
    db 0, 0  ; Can fly: no, Metal: no
    db 80, 130, 144  ; Skills: BiAttack, UltraDown, BladeD
    db 24, 30, 23, 21, 18, 18  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 3, 3, 1, 1, 1, 2, 3, 3, 1, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 1, 1, 1, 1, 2, 1, 3, 3, 3, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $6D (109): Watabou ---
MonsterInfo_109_Watabou:
    db 4  ; Family: Plant
    db 80  ; Level cap
    db 0  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 57, 126, 127  ; Skills: Chance, Whistle, Imitate
    db 10, 27, 11, 14, 24, 30  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 3, 3, 3, 1, 3, 3, 3, 3, 3, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 1, 2, 3, 3, 3, 3, 3, 3, 3, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $6E (110): GiantSlug ---
MonsterInfo_110_GiantSlug:
    db 5  ; Family: Bug
    db 35  ; Level cap
    db 2  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 121, 126, 140  ; Skills: LushLicks, Whistle, Dodge
    db 11, 8, 14, 9, 11, 7  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 1, 3, 1, 1, 1, 3, 1, 1  ; Resist A-N: Fire..AglDown
    db 1, 1, 0, 0, 2, 2, 2, 0, 0, 0, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $6F (111): Catapila ---
MonsterInfo_111_Catapila:
    db 5  ; Family: Bug
    db 40  ; Level cap
    db 4  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 30, 108, 131  ; Skills: Upper, PoisonGas, ThickFog
    db 13, 5, 11, 14, 11, 9  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 0, 0, 1, 0, 2, 0, 0, 0, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 1, 0, 1, 1, 2, 2, 2, 0, 0, 0, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $70 (112): Gophecada ---
MonsterInfo_112_Gophecada:
    db 5  ; Family: Bug
    db 30  ; Level cap
    db 1  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 18, 39, 82  ; Skills: Beat, MagicBack, CallHelp
    db 6, 11, 14, 18, 8, 7  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 2, 1, 1  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 3, 3, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $71 (113): Butterfly ---
MonsterInfo_113_Butterfly:
    db 5  ; Family: Bug
    db 30  ; Level cap
    db 0  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 24, 82, 111  ; Skills: Surround, CallHelp, Curse
    db 11, 2, 13, 7, 12, 8  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 1, 1, 0, 0, 2, 0, 0, 0, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 2, 2, 2, 1, 1, 1, 3, 3, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $72 (114): WeedBug ---
MonsterInfo_114_WeedBug:
    db 5  ; Family: Bug
    db 45  ; Level cap
    db 4  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 26, 36, 38  ; Skills: RobMagic, Barrier, MagicWall
    db 17, 13, 10, 12, 5, 19  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 1, 1, 0, 0, 2, 0, 1, 1, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 2, 2, 2, 1, 1, 1, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $73 (115): GiantWorm ---
MonsterInfo_115_GiantWorm:
    db 5  ; Family: Bug
    db 35  ; Level cap
    db 6  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 55, 74, 117  ; Skills: StepGuard, BeastCut, OddDance
    db 13, 8, 16, 8, 13, 14  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 1, 1, 1, 0, 2, 1, 0, 0, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 1, 0, 0, 0, 2, 2, 2, 0, 0, 0, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $74 (116): Lipsy ---
MonsterInfo_116_Lipsy:
    db 5  ; Family: Bug
    db 40  ; Level cap
    db 4  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 104, 112, 121  ; Skills: NapAttack, Ahhh, LushLicks
    db 12, 8, 9, 9, 4, 1  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 1, 3, 1, 0, 0, 3, 0, 0  ; Resist A-N: Fire..AglDown
    db 1, 0, 0, 0, 3, 3, 3, 0, 0, 0, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $75 (117): StagBug ---
MonsterInfo_117_StagBug:
    db 5  ; Family: Bug
    db 45  ; Level cap
    db 3  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 21, 92, 123  ; Skills: Sleep, FireAir, LegSweep
    db 13, 7, 16, 20, 9, 7  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 0, 0, 0, 1, 0, 2, 1, 0, 0, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 1, 0, 1, 1, 2, 2, 2, 0, 0, 0, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $76 (118): ArmyAnt ---
MonsterInfo_118_ArmyAnt:
    db 5  ; Family: Bug
    db 35  ; Level cap
    db 2  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 62, 82, 104  ; Skills: Kamikaze, CallHelp, NapAttack
    db 8, 4, 11, 17, 13, 1  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 2, 2, 2, 0, 0, 0, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $77 (119): GoHopper ---
MonsterInfo_119_GoHopper:
    db 5  ; Family: Bug
    db 35  ; Level cap
    db 0  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 26, 65, 82  ; Skills: RobMagic, ChargeUP, CallHelp
    db 11, 4, 8, 14, 14, 4  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 2, 2, 2, 0, 0, 0, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $78 (120): TailEater ---
MonsterInfo_120_TailEater:
    db 5  ; Family: Bug
    db 45  ; Level cap
    db 5  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 71, 108, 115  ; Skills: IceSlash, PoisonGas, Radiant
    db 12, 10, 16, 11, 14, 5  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 1, 1, 0, 0, 2, 0, 1, 1, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 2, 2, 2, 1, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $79 (121): ArmorPede ---
MonsterInfo_121_ArmorPede:
    db 5  ; Family: Bug
    db 30  ; Level cap
    db 6  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 30, 37, 59  ; Skills: Upper, TwinHits, TwinSlash
    db 15, 10, 17, 20, 11, 2  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 1, 1, 1, 0, 2, 0, 0, 0, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 0, 0, 1, 1, 2, 2, 2, 1, 1, 1, 3, 3, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $7A (122): Eyeder ---
MonsterInfo_122_Eyeder:
    db 5  ; Family: Bug
    db 45  ; Level cap
    db 4  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 3, 43, 56  ; Skills: Firebal, Heal, MapMagic
    db 9, 11, 6, 3, 10, 9  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 1, 1, 0, 0, 2, 1, 1, 1, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 1, 0, 0, 0, 2, 2, 2, 1, 1, 1, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $7B (123): GiantMoth ---
MonsterInfo_123_GiantMoth:
    db 5  ; Family: Bug
    db 30  ; Level cap
    db 2  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 88, 105, 115  ; Skills: WindBeast, Paralyze, Radiant
    db 14, 9, 16, 12, 20, 12  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 0, 3, 1, 0, 0, 2, 1, 1  ; Resist A-N: Fire..AglDown
    db 1, 0, 0, 0, 3, 2, 2, 1, 1, 1, 3, 3, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $7C (124): Droll ---
MonsterInfo_124_Droll:
    db 5  ; Family: Bug
    db 40  ; Level cap
    db 5  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 32, 55, 216  ; Skills: Slow, StepGuard, Branching
    db 17, 10, 15, 16, 7, 14  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 1, 3, 1, 1, 0, 3, 0, 0  ; Resist A-N: Fire..AglDown
    db 1, 0, 0, 0, 3, 3, 3, 1, 1, 1, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $7D (125): ArmyCrab ---
MonsterInfo_125_ArmyCrab:
    db 5  ; Family: Bug
    db 40  ; Level cap
    db 6  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 30, 72, 82  ; Skills: Upper, MetalCut, CallHelp
    db 16, 8, 14, 19, 5, 1  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 1, 3, 1, 0, 0, 3, 0, 0  ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 0, 3, 3, 3, 0, 0, 0, 3, 3, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $7E (126): MadHornet ---
MonsterInfo_126_MadHornet:
    db 5  ; Family: Bug
    db 40  ; Level cap
    db 7  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 103, 105, 138  ; Skills: PoisonHit, Paralyze, TailWind
    db 20, 5, 19, 13, 20, 4  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 0, 0, 1, 0, 2, 0, 0, 0, 2, 1, 1  ; Resist A-N: Fire..AglDown
    db 0, 0, 1, 1, 2, 2, 2, 1, 1, 1, 3, 3, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $7F (127): HornBeet ---
MonsterInfo_127_HornBeet:
    db 5  ; Family: Bug
    db 50  ; Level cap
    db 7  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 69, 76, 91  ; Skills: BoltSlash, DevilCut, RockThrow
    db 21, 19, 23, 20, 12, 14  ; Growth: HP, MP, ATK, DEF, AGL, INT
    ; Resist A-N: Fire..AglDown
    db 2, 2, 2, 0, 0, 2, 0, 2, 1, 0, 0
DataMon_59d0:
    db 2, 0, 0
    db 1, 0, 2, 2, 2, 3, 2, 0, 0, 0, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $80 (128): Armorpion ---
MonsterInfo_128_Armorpion:
    db 5  ; Family: Bug
    db 60  ; Level cap
    db 24  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 64, 77, 87  ; Skills: EvilSlash, ZombieCut, RainSlash
    db 22, 20, 24, 23, 15, 18  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 1, 1, 2, 1, 3, 2, 1, 1, 3, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 1, 2, 2, 3, 3, 3, 1, 1, 1, 3, 3, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $81 (129): Digster ---
MonsterInfo_129_Digster:
    db 5  ; Family: Bug
    db 50  ; Level cap
    db 11  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 50, 142, 143  ; Skills: Farewell, StrongD, SuckAll
    db 24, 10, 19, 26, 1, 15  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 0, 0, 1, 1, 2, 2, 0, 0, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 1, 1, 2, 2, 2, 0, 0, 0, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $82 (130): Pixy ---
MonsterInfo_130_Pixy:
    db 6  ; Family: Devil
    db 40  ; Level cap
    db 19  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 34, 37, 51  ; Skills: Speed, TwinHits, Antidote
    db 11, 7, 15, 8, 15, 4  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 1, 1, 1, 2, 1, 1, 3, 2, 2, 2, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $83 (131): ArcDemon ---
MonsterInfo_131_ArcDemon:
    db 6  ; Family: Devil
    db 45  ; Level cap
    db 20  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 6, 69, 75  ; Skills: Bang, BoltSlash, BirdBlow
    db 14, 13, 17, 12, 7, 21  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 3, 2, 2, 2, 2, 0, 0, 3, 0, 1, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 1, 0, 0, 2, 1, 0, 0, 0, 0, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $84 (132): AgDevil ---
MonsterInfo_132_AgDevil:
    db 6  ; Family: Devil
    db 35  ; Level cap
    db 16  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 3, 20, 106  ; Skills: Firebal, Sacrifice, SleepAir
    db 16, 11, 18, 12, 16, 19  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 2, 2, 2, 2, 0, 0, 2, 0, 0, 0, 1, 1  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 0, 0, 0, 0, 2, 1, 1, 2, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $85 (133): Demonite ---
MonsterInfo_133_Demonite:
    db 6  ; Family: Devil
    db 25  ; Level cap
    db 13  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 0, 68, 96  ; Skills: Blaze, FireSlash, FrigidAir
    db 13, 1, 5, 4, 9, 20  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 3, 3, 2, 0, 0, 2, 0, 0, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 0, 0, 0, 0, 1, 2, 2, 2, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $86 (134): DarkEye ---
MonsterInfo_134_DarkEye:
    db 6  ; Family: Devil
    db 50  ; Level cap
    db 18  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 72, 107, 115  ; Skills: MetalCut, PalsyAir, Radiant
    db 11, 18, 10, 16, 9, 12  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 1, 3, 3, 1, 0, 0, 2, 1, 1, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 0, 0, 0, 0, 2, 2, 1, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $87 (135): EyeBall ---
MonsterInfo_135_EyeBall:
    db 6  ; Family: Devil
    db 35  ; Level cap
    db 16  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 39, 42, 125  ; Skills: MagicBack, Ironize, WarCry
    db 16, 17, 14, 14, 13, 8  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 2, 2, 2, 0, 1, 2, 0, 0, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $88 (136): SkulRider ---
MonsterInfo_136_SkulRider:
    db 6  ; Family: Devil
    db 45  ; Level cap
    db 18  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 68, 87, 123  ; Skills: FireSlash, RainSlash, LegSweep
    db 17, 11, 17, 13, 15, 12  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 1, 1, 2, 1, 1, 3, 0, 0, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 0, 2, 2, 1, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $89 (137): EvilBeast ---
MonsterInfo_137_EvilBeast:
    db 6  ; Family: Devil
    db 50  ; Level cap
    db 20  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 3, 42, 96  ; Skills: Firebal, Ironize, FrigidAir
    db 16, 10, 20, 22, 4, 12  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 1, 2, 2, 3, 0, 0, 3, 1, 1, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $8A (138): 1EyeClown ---
MonsterInfo_138_1EyeClown:
    db 6  ; Family: Devil
    db 25  ; Level cap
    db 13  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 0, 3, 12  ; Skills: Blaze, Firebal, IceBolt
    db 10, 1, 5, 9, 9, 17  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 2, 2, 2, 0, 0, 3, 0, 1, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $8B (139): Gremlin ---
MonsterInfo_139_Gremlin:
    db 6  ; Family: Devil
    db 25  ; Level cap
    db 13  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 3, 23, 43  ; Skills: Firebal, StopSpell, Heal
    db 13, 7, 8, 4, 2, 18  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 1, 1, 1, 0, 0, 3, 0, 0, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $8C (140): MedusaEye ---
MonsterInfo_140_MedusaEye:
    db 6  ; Family: Devil
    db 35  ; Level cap
    db 19  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 24, 28, 216  ; Skills: Surround, Sap, Branching
    db 11, 13, 14, 15, 8, 11  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 1, 1, 1, 0, 1, 2, 0, 0, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 0, 2, 2, 2, 1, 1, 0, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $8D (141): Lionex ---
MonsterInfo_141_Lionex:
    db 6  ; Family: Devil
    db 45  ; Level cap
    db 21  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 9, 46, 70  ; Skills: Infernos, HealUs, VacuSlash
    db 15, 11, 14, 15, 12, 19  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 3, 3, 2, 2, 2, 2, 0, 0, 3, 1, 1, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 2, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $8E (142): GoatHorn ---
MonsterInfo_142_GoatHorn:
    db 6  ; Family: Devil
    db 35  ; Level cap
    db 22  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 6, 9, 12  ; Skills: Bang, Infernos, IceBolt
    db 20, 11, 17, 13, 11, 20  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 2, 2, 2, 0, 0, 3, 0, 1, 1, 2, 2  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $8F (143): Orc ---
MonsterInfo_143_Orc:
    db 6  ; Family: Devil
    db 50  ; Level cap
    db 17  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 28, 48, 75  ; Skills: Sap, Vivify, BirdBlow
    db 19, 7, 19, 13, 13, 18  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 3, 3, 2, 0, 0, 2, 1, 1, 0, 1, 1  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 0, 0, 0, 0, 2, 2, 2, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $90 (144): Ogre ---
MonsterInfo_144_Ogre:
    db 6  ; Family: Devil
    db 35  ; Level cap
    db 19  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 63, 72, 87  ; Skills: Massacre, MetalCut, RainSlash
    db 15, 8, 20, 12, 10, 12  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 2, 2, 2, 2, 0, 0, 2, 0, 0, 0, 1, 1  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $91 (145): GateGuard ---
MonsterInfo_145_GateGuard:
    db 6  ; Family: Devil
    db 50  ; Level cap
    db 23  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 0, 78, 131  ; Skills: Blaze, CleanCut, ThickFog
    db 18, 12, 18, 14, 10, 14  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 3, 3, 2, 1, 1, 3, 0, 0, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 0, 0, 0, 0, 1, 2, 2, 2, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $92 (146): ChopClown ---
MonsterInfo_146_ChopClown:
    db 6  ; Family: Devil
    db 50  ; Level cap
    db 22  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 37, 70, 85  ; Skills: TwinHits, VacuSlash, SquallHit
    db 17, 12, 20, 11, 20, 15  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 2, 2, 3, 1, 0, 3, 1, 1, 0, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $93 (147): Grendal ---
MonsterInfo_147_Grendal:
    db 6  ; Family: Devil
    db 60  ; Level cap
    db 20  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 68, 73, 136  ; Skills: FireSlash, DrakSlash, Cover
    db 23, 1, 18, 24, 12, 12  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 2, 2, 1, 1, 1, 3, 1, 1, 1, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $94 (148): Akubar ---
MonsterInfo_148_Akubar:
    db 6  ; Family: Devil
    db 80  ; Level cap
    db 30  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 6, 84, 96  ; Skills: Bang, Focus, FrigidAir
    db 24, 30, 23, 21, 18, 21  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 3, 2, 2, 2, 1, 2, 3, 1, 3, 2, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 0, 2, 1, 0, 2, 0, 1, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $95 (149): MadKnight ---
MonsterInfo_149_MadKnight:
    db 6  ; Family: Devil
    db 50  ; Level cap
    db 23  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 63, 74, 217  ; Skills: Massacre, BeastCut, GigaSlash
    db 17, 9, 18, 20, 10, 12  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 1, 1, 1, 2, 1, 1, 3, 0, 1, 1, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 0, 1, 1, 0, 2, 0, 1, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $96 (150): Gigantes ---
MonsterInfo_150_Gigantes:
    db 6  ; Family: Devil
    db 35  ; Level cap
    db 22  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 64, 65, 77  ; Skills: EvilSlash, ChargeUP, ZombieCut
    db 27, 0, 27, 7, 0, 0  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 1, 1, 1, 0, 1, 3, 0, 0, 0, 2, 2  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 0, 0, 2, 0, 2, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $97 (151): Centasaur ---
MonsterInfo_151_Centasaur:
    db 6  ; Family: Devil
    db 45  ; Level cap
    db 23  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 23, 68, 87  ; Skills: StopSpell, FireSlash, RainSlash
    db 20, 1, 24, 21, 18, 19  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 3, 3, 2, 1, 1, 2, 0, 0, 2, 0, 1, 1, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 0, 1, 1, 0, 2, 0, 1, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $98 (152): EvilArmor ---
MonsterInfo_152_EvilArmor:
    db 6  ; Family: Devil
    db 30  ; Level cap
    db 22  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 68, 69, 73  ; Skills: FireSlash, BoltSlash, DrakSlash
    db 16, 1, 17, 29, 5, 13  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 2, 2, 1, 0, 1, 3, 0, 0, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 0, 1, 2, 1, 1, 0, 0, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $99 (153): Jamirus ---
MonsterInfo_153_Jamirus:
    db 6  ; Family: Devil
    db 60  ; Level cap
    db 21  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 0, 80, 138  ; Skills: Blaze, BiAttack, TailWind
    db 24, 9, 21, 24, 23, 18  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 3, 3, 1, 1, 1, 3, 1, 1, 1, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 0, 0, 2, 0, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $9A (154): Durran ---
MonsterInfo_154_Durran:
    db 6  ; Family: Devil
    db 70  ; Level cap
    db 28  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 73, 75, 88  ; Skills: DrakSlash, BirdBlow, WindBeast
    db 25, 24, 23, 15, 17, 20  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 3, 2, 1, 3, 2, 2, 3, 1, 2, 2, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 1, 1, 1, 3, 3, 2, 1, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $9B (155): Spooky ---
MonsterInfo_155_Spooky:
    db 7  ; Family: Zombie
    db 40  ; Level cap
    db 11  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 115, 121, 146  ; Skills: Radiant, LushLicks, MouthShut
    db 11, 12, 13, 8, 18, 15  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 3, 3, 3, 1, 1, 3, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 1, 0, 0, 2, 2, 2, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $9C (156): Skullgon ---
MonsterInfo_156_Skullgon:
    db 7  ; Family: Zombie
    db 45  ; Level cap
    db 13  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 59, 71, 96  ; Skills: TwinSlash, IceSlash, FrigidAir
    db 6, 1, 23, 15, 4, 6  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 0, 0, 2, 2, 2, 2, 0, 0, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $9D (157): Putrepup ---
MonsterInfo_157_Putrepup:
    db 7  ; Family: Zombie
    db 35  ; Level cap
    db 6  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 28, 32, 39  ; Skills: Sap, Slow, MagicBack
    db 17, 13, 17, 8, 11, 4  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 2, 2, 2, 0, 0, 2, 1, 1  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 0, 2, 2, 2, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $9E (158): RotRaven ---
MonsterInfo_158_RotRaven:
    db 7  ; Family: Zombie
    db 35  ; Level cap
    db 5  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 62, 69, 90  ; Skills: Kamikaze, BoltSlash, Lightning
    db 14, 8, 12, 11, 18, 9  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 1, 1, 0, 2, 2, 2, 0, 0, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 0, 2, 2, 2, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $9F (159): Mummy ---
MonsterInfo_159_Mummy:
    db 7  ; Family: Zombie
    db 50  ; Level cap
    db 10  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 64, 82, 105  ; Skills: EvilSlash, CallHelp, Paralyze
    db 15, 17, 12, 9, 4, 8  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 1, 1, 0, 2, 2, 2, 1, 1, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 0, 2, 2, 2, 1, 1, 1, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $A0 (160): DarkCrab ---
MonsterInfo_160_DarkCrab:
    db 7  ; Family: Zombie
    db 30  ; Level cap
    db 8  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 38, 42, 55  ; Skills: MagicWall, Ironize, StepGuard
    db 12, 8, 15, 20, 1, 11  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 2, 3, 2, 0, 0, 3, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 0, 3, 3, 3, 0, 0, 0, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $A1 (161): DeadNite ---
MonsterInfo_161_DeadNite:
    db 7  ; Family: Zombie
    db 45  ; Level cap
    db 13  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 43, 53, 54  ; Skills: Heal, DeChaos, CurseOff
    db 17, 7, 19, 9, 12, 8  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 1, 1, 1, 2, 2, 3, 0, 0, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 0, 2, 2, 2, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $A2 (162): Shadow ---
MonsterInfo_162_Shadow:
    db 7  ; Family: Zombie
    db 50  ; Level cap
    db 12  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 96, 113, 131  ; Skills: FrigidAir, K.O.Dance, ThickFog
    db 9, 6, 6, 20, 8, 12  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 1, 2, 2, 3, 0, 0, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 1, 2, 2, 2, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $A3 (163): Hork ---
MonsterInfo_163_Hork:
    db 7  ; Family: Zombie
    db 40  ; Level cap
    db 8  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 108, 116, 121  ; Skills: PoisonGas, EerieLite, LushLicks
    db 17, 13, 16, 8, 11, 10  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 2, 2, 2, 0, 0, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 0, 2, 2, 2, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $A4 (164): Mudron ---
MonsterInfo_164_Mudron:
    db 7  ; Family: Zombie
    db 30  ; Level cap
    db 10  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 18, 43, 48  ; Skills: Beat, Heal, Vivify
    db 6, 10, 11, 17, 7, 14  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 2, 3, 2, 0, 0, 3, 1, 1  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 0, 3, 3, 3, 0, 0, 0, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $A5 (165): NiteWhip ---
MonsterInfo_165_NiteWhip:
    db 7  ; Family: Zombie
    db 35  ; Level cap
    db 12  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 88, 90, 92  ; Skills: WindBeast, Lightning, FireAir
    db 17, 4, 10, 3, 15, 9  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 2, 1, 1, 2, 2, 2, 0, 0, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 0, 2, 2, 2, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $A6 (166): MadSpirit ---
MonsterInfo_166_MadSpirit:
    db 7  ; Family: Zombie
    db 50  ; Level cap
    db 13  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 106, 115, 131  ; Skills: SleepAir, Radiant, ThickFog
    db 14, 12, 15, 12, 16, 10  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 1, 1, 1, 2, 2, 3, 1, 1, 3, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 0, 2, 2, 2, 1, 1, 1, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $A7 (167): WindMerge ---
MonsterInfo_167_WindMerge:
    db 7  ; Family: Zombie
    db 35  ; Level cap
    db 9  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 9, 36, 54  ; Skills: Infernos, Barrier, CurseOff
    db 16, 19, 19, 12, 13, 6  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 3, 1, 0, 2, 2, 2, 0, 0, 2, 1, 1  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 0, 2, 2, 2, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $A8 (168): Reaper ---
MonsterInfo_168_Reaper:
    db 7  ; Family: Zombie
    db 50  ; Level cap
    db 10  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 76, 111, 116  ; Skills: DevilCut, Curse, EerieLite
    db 19, 3, 21, 17, 19, 6  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 1, 1, 0, 2, 3, 2, 1, 1, 3, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 1, 3, 3, 3, 1, 1, 0, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $A9 (169): DeadNoble ---
MonsterInfo_169_DeadNoble:
    db 7  ; Family: Zombie
    db 50  ; Level cap
    db 16  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 18, 46, 132  ; Skills: Beat, HealUs, TatsuCall
    db 21, 2, 26, 19, 15, 13  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 2, 1, 2, 2, 2, 3, 1, 1, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 2, 2, 3, 2, 1, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $AA (170): WhiteKing ---
MonsterInfo_170_WhiteKing:
    db 7  ; Family: Zombie
    db 70  ; Level cap
    db 25  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 9, 15, 57  ; Skills: Infernos, Bolt, Chance
    db 20, 24, 14, 20, 15, 27  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 2, 3, 1, 3, 2, 2, 3, 1, 1, 3, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 1, 1, 2, 3, 3, 3, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $AB (171): BoneSlave ---
MonsterInfo_171_BoneSlave:
    db 7  ; Family: Zombie
    db 40  ; Level cap
    db 10  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 6, 69, 75  ; Skills: Bang, BoltSlash, BirdBlow
    db 14, 13, 17, 12, 7, 1  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 1, 0, 1, 2, 2, 2, 1, 1, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 0, 2, 2, 2, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $AC (172): Skeletor ---
MonsterInfo_172_Skeletor:
    db 7  ; Family: Zombie
    db 60  ; Level cap
    db 12  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 28, 75, 80  ; Skills: Sap, BirdBlow, BiAttack
    db 16, 11, 18, 12, 16, 19  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 1, 2, 0, 2, 2, 2, 3, 1, 1, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 1, 2, 2, 2, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $AD (173): Servant ---
MonsterInfo_173_Servant:
    db 7  ; Family: Zombie
    db 80  ; Level cap
    db 20  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 0, 12, 84  ; Skills: Blaze, IceBolt, Focus
    db 23, 21, 25, 18, 15, 20  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 3, 2, 1, 2, 2, 2, 3, 1, 1, 3, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 1, 1, 2, 3, 3, 3, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $AE (174): Copycat ---
MonsterInfo_174_Copycat:
    db 7  ; Family: Zombie
    db 40  ; Level cap
    db 1  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 41, 117, 127  ; Skills: Transform, OddDance, Imitate
    db 11, 20, 1, 2, 21, 5  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 0, 2, 2, 3, 0, 0, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 0, 2, 3, 2, 1, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $AF (175): JewelBag ---
MonsterInfo_175_JewelBag:
    db 8  ; Family: Material
    db 40  ; Level cap
    db 12  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 3, 23, 25  ; Skills: Firebal, StopSpell, PanicAll
    db 13, 11, 9, 18, 17, 15  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 2, 1, 1, 3, 1, 1, 1, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 1, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $B0 (176): EvilWand ---
MonsterInfo_176_EvilWand:
    db 8  ; Family: Material
    db 50  ; Level cap
    db 14  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 53, 56, 96  ; Skills: DeChaos, MapMagic, FrigidAir
    db 14, 15, 17, 12, 9, 13  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 0, 0, 2, 0, 0, 3, 0, 0, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $B1 (177): MadCandle ---
MonsterInfo_177_MadCandle:
    db 8  ; Family: Material
    db 35  ; Level cap
    db 10  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 0, 86, 126  ; Skills: Blaze, PsycheUp, Whistle
    db 12, 10, 14, 6, 17, 12  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 1, 1  ; Resist A-N: Fire..AglDown
    db 2, 0, 2, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $B2 (178): CoilBird ---
MonsterInfo_178_CoilBird:
    db 8  ; Family: Material
    db 35  ; Level cap
    db 8  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    ; Skills: NumbOff, DeChaos, SuckAll
    db 52
DataMon_624e:
    db 53, 143
    db 16, 13, 5, 14, 14, 7  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 1, 1, 2, 0, 0, 2, 0, 0, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 2, 0, 0, 0, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $B3 (179): Facer ---
MonsterInfo_179_Facer:
    db 8  ; Family: Material
    db 50  ; Level cap
    db 12  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 9, 20, 149  ; Skills: Infernos, Sacrifice, LifeSong
    db 8, 23, 11, 12, 3, 19  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 1, 1, 2, 0, 0, 2, 1, 1, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 2, 0, 0, 0, 1, 1, 1, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $B4 (180): SpikyBoy ---
MonsterInfo_180_SpikyBoy:
    db 8  ; Family: Material
    db 30  ; Level cap
    db 8  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 20, 66, 214  ; Skills: Sacrifice, HighJump, Smashlime
    db 9, 13, 14, 17, 7, 11  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 2, 0, 1, 2, 0, 0, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 2, 1, 1, 1, 0, 0, 0, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $B5 (181): MadMirror ---
MonsterInfo_181_MadMirror:
    db 8  ; Family: Material
    db 45  ; Level cap
    db 14  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 39, 41, 56  ; Skills: MagicBack, Transform, MapMagic
    db 15, 11, 8, 6, 11, 19  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 1, 1, 2, 0, 0, 3, 0, 0, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $B6 (182): RogueNite ---
MonsterInfo_182_RogueNite:
    db 8  ; Family: Material
    db 45  ; Level cap
    db 12  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 43, 64, 72  ; Skills: Heal, EvilSlash, MetalCut
    db 14, 4, 20, 21, 10, 13  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 2, 1, 1, 3, 0, 0, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $B7 (183): Goopi ---
MonsterInfo_183_Goopi:
    db 8  ; Family: Material
    db 40  ; Level cap
    db 8  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 82, 123, 140  ; Skills: CallHelp, LegSweep, Dodge
    db 8, 13, 11, 14, 7, 4  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 2, 0, 0, 2, 0, 0, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $B8 (184): Voodoll ---
MonsterInfo_184_Voodoll:
    db 8  ; Family: Material
    db 35  ; Level cap
    db 11  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 24, 25, 28  ; Skills: Surround, PanicAll, Sap
    db 14, 17, 12, 12, 8, 14  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 2, 0, 1, 2, 0, 0, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 2, 2, 2, 1, 0, 0, 0, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $B9 (185): MetalDrak ---
MonsterInfo_185_MetalDrak:
    db 8  ; Family: Material
    db 45  ; Level cap
    db 15  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 63, 91, 114  ; Skills: Massacre, RockThrow, SandStorm
    db 18, 13, 20, 23, 9, 10  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 0, 0, 2, 0, 0, 2, 0, 0, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 1, 3, 2, 2, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $BA (186): Balzak ---
MonsterInfo_186_Balzak:
    db 8  ; Family: Material
    db 35  ; Level cap
    db 13  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 6, 15, 79  ; Skills: Bang, Bolt, MultiCut
    db 21, 11, 23, 21, 18, 19  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 2, 1, 1, 2, 1, 1, 1, 1, 1  ; Resist A-N: Fire..AglDown
    db 2, 1, 0, 2, 0, 0, 0, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $BB (187): SabreMan ---
MonsterInfo_187_SabreMan:
    db 8  ; Family: Material
    db 30  ; Level cap
    db 11  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 26, 76, 105  ; Skills: RobMagic, DevilCut, Paralyze
    db 8, 3, 9, 11, 12, 6  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 1, 1, 0, 2, 0, 1, 2, 1, 1, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 2, 1, 1, 1, 0, 0, 0, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $BC (188): CurseLamp ---
MonsterInfo_188_CurseLamp:
    db 8  ; Family: Material
    db 50  ; Level cap
    db 9  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 30, 34, 37  ; Skills: Upper, Speed, TwinHits
    db 12, 18, 9, 19, 13, 15  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 2, 1, 2, 0, 0, 2, 1, 1, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 0, 2, 0, 0, 0, 2, 2, 2, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3  ; Tier/rank

; --- Monster $BD (189): Roboster ---
MonsterInfo_189_Roboster:
    db 8  ; Family: Material
    db 40  ; Level cap
    db 13  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 80, 85, 87  ; Skills: BiAttack, SquallHit, RainSlash
    db 12, 5, 21, 22, 24, 17  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 1, 1, 2, 1, 2, 3, 0, 0, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 1, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $BE (190): EvilPot ---
MonsterInfo_190_EvilPot:
    db 8  ; Family: Material
    db 40  ; Level cap
    db 11  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 18, 21, 63  ; Skills: Beat, Sleep, Massacre
    db 18, 19, 15, 18, 9, 19  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 0, 0, 0, 2, 2, 2, 3, 1, 1, 1, 1, 1  ; Resist A-N: Fire..AglDown
    ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3, 1, 0, 2, 0, 0, 0, 0, 0, 0, 0
Jump_003_6473:
    db 0, 0
    db 3  ; Tier/rank

; --- Monster $BF (191): Gismo ---
MonsterInfo_191_Gismo:
    db 8  ; Family: Material
    db 40  ; Level cap
    db 9  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 67, 92, 96  ; Skills: SuckAir, FireAir, FrigidAir
    db 13, 15, 11, 14, 20, 18  ; Growth: HP, MP, ATK, DEF, AGL, INT
    ; Resist A-N: Fire..AglDown
    db 0, 0, 0, 2, 1, 2, 0, 0, 2
Jump_003_648e:
    db 0, 0, 0, 0, 1
    db 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $C0 (192): LavaMan ---
MonsterInfo_192_LavaMan:
    db 8  ; Family: Material
    db 40  ; Level cap
    db 13  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 0, 92, 136  ; Skills: Blaze, FireAir, Cover
    db 18, 12, 17, 24, 4, 7  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 3, 3, 1, 2, 0, 1, 0, 0, 3, 0, 0, 1, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $C1 (193): IceMan ---
MonsterInfo_193_IceMan:
    db 8  ; Family: Material
    db 40  ; Level cap
    db 13  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 12, 96, 142  ; Skills: IceBolt, FrigidAir, StrongD
    db 16, 6, 18, 24, 4, 7  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 2, 0, 3, 0, 0, 3, 0, 0, 0, 1, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 1, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $C2 (194): Mimic ---
MonsterInfo_194_Mimic:
    db 8  ; Family: Material
    db 40  ; Level cap
    db 11  ; Exp table
    db 2  ; Female ratio (50/50)
    db 1, 0  ; Can fly: yes, Metal: no
    db 0, 18, 55  ; Skills: Blaze, Beat, StepGuard
    db 25, 10, 20, 12, 1, 20  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 1, 2, 1, 2, 1, 1, 3, 1, 1, 1, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $C3 (195): MudDoll ---
MonsterInfo_195_MudDoll:
    db 8  ; Family: Material
    db 40  ; Level cap
    db 8  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 117, 119, 148  ; Skills: OddDance, SideStep, Hustle
    db 12, 3, 13, 14, 1, 15  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 1, 1, 0, 3, 1, 0, 3, 0, 0, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 4  ; Tier/rank

; --- Monster $C4 (196): Golem ---
MonsterInfo_196_Golem:
    db 8  ; Family: Material
    db 40  ; Level cap
    db 18  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 65, 86, 142  ; Skills: ChargeUP, PsycheUp, StrongD
    db 17, 4, 12, 21, 4, 6  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 0, 0, 1, 1, 0, 3, 1, 1, 3, 0, 0, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 0, 3, 0, 0, 0, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $C5 (197): StoneMan ---
MonsterInfo_197_StoneMan:
    db 8  ; Family: Material
    db 50  ; Level cap
    db 15  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 136, 143, 147  ; Skills: Cover, SuckAll, Meditate
    db 24, 10, 23, 24, 1, 14  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 1, 0, 3, 1, 1, 3, 0, 1, 0, 0, 0  ; Resist A-N: Fire..AglDown
    db 3, 0, 1, 3, 0, 2, 1, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $C6 (198): BombCrag ---
MonsterInfo_198_BombCrag:
    db 8  ; Family: Material
    db 50  ; Level cap
    db 14  ; Exp table
    db 2  ; Female ratio (50/50)
    db 0, 0  ; Can fly: no, Metal: no
    db 20, 50, 147  ; Skills: Sacrifice, Farewell, Meditate
    db 15, 11, 17, 20, 0, 13  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 0, 0, 0, 2, 0, 1, 3, 1, 1, 1, 1, 1  ; Resist A-N: Fire..AglDown
    db 3, 0, 1, 2, 1, 1, 1, 0, 0, 0, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 5  ; Tier/rank

; --- Monster $C7 (199): GoldGolem ---
MonsterInfo_199_GoldGolem:
    db 8  ; Family: Material
    db 80  ; Level cap
    db 18  ; Exp table
    db 1  ; Female ratio (~10%)
    db 0, 0  ; Can fly: no, Metal: no
    db 101, 129, 132  ; Skills: BigBang, Surge, TatsuCall
    db 24, 21, 24, 27, 17, 23  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 2, 1, 2, 3, 3, 3, 3, 3, 3, 2, 2  ; Resist A-N: Fire..AglDown
    db 3, 1, 2, 2, 3, 3, 3, 2, 2, 2, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $C8 (200): DracoLord ---
MonsterInfo_200_DracoLord:
    db 9  ; Family: Boss
    db 50  ; Level cap
    db 24  ; Exp table
    db 0  ; Female ratio (0%)
    db 0, 0  ; Can fly: no, Metal: no
    db 3, 147, 213  ; Skills: Firebal, Meditate, BeDragon
    db 20, 30, 21, 20, 23, 23  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 0, 0, 0, 1, 3, 3, 3, 2, 3, 3, 3, 3  ; Resist A-N: Fire..AglDown
    db 3, 0, 1, 1, 3, 2, 3, 3, 3, 3, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $C9 (201): DracoLord ---
MonsterInfo_201_DracoLord:
    db 9  ; Family: Boss
    db 80  ; Level cap
    db 25  ; Exp table
    db 0  ; Female ratio (0%)
    db 0, 0  ; Can fly: no, Metal: no
    db 63, 92, 129  ; Skills: Massacre, FireAir, Surge
    db 21, 30, 24, 21, 23, 21  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 1, 1, 1, 2, 3, 3, 3, 3, 3, 3, 3, 3  ; Resist A-N: Fire..AglDown
    db 3, 1, 2, 2, 3, 3, 3, 3, 3, 3, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $CA (202): Hargon ---
MonsterInfo_202_Hargon:
    db 9  ; Family: Boss
    db 70  ; Level cap
    db 24  ; Exp table
    db 0  ; Female ratio (0%)
    db 0, 0  ; Can fly: no, Metal: no
    db 3, 6, 132  ; Skills: Firebal, Bang, TatsuCall
    db 19, 30, 20, 21, 23, 23  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 1, 0, 1, 3, 3, 3, 2, 3, 3, 3, 3  ; Resist A-N: Fire..AglDown
    db 3, 1, 0, 0, 3, 2, 3, 3, 3, 3, 2, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $CB (203): Sidoh ---
MonsterInfo_203_Sidoh:
    db 9  ; Family: Boss
    db 80  ; Level cap
    db 25  ; Exp table
    db 0  ; Female ratio (0%)
    db 1, 0  ; Can fly: yes, Metal: no
    db 92, 96, 100  ; Skills: FireAir, FrigidAir, Hellblast
    db 24, 30, 24, 21, 23, 23  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 1, 1, 1, 3, 3, 3, 3, 3, 3, 3, 3  ; Resist A-N: Fire..AglDown
    db 3, 1, 0, 0, 3, 3, 3, 3, 3, 3, 2, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $CC (204): Baramos ---
MonsterInfo_204_Baramos:
    db 9  ; Family: Boss
    db 70  ; Level cap
    db 24  ; Exp table
    db 0  ; Female ratio (0%)
    db 0, 0  ; Can fly: no, Metal: no
    db 6, 91, 100  ; Skills: Bang, RockThrow, Hellblast
    db 20, 30, 20, 20, 22, 21  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 2, 0, 2, 3, 3, 3, 2, 3, 3, 2, 2  ; Resist A-N: Fire..AglDown
    db 3, 1, 1, 1, 3, 3, 3, 3, 3, 3, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $CD (205): Zoma ---
MonsterInfo_205_Zoma:
    db 9  ; Family: Boss
    db 80  ; Level cap
    db 25  ; Exp table
    db 0  ; Female ratio (0%)
    db 0, 0  ; Can fly: no, Metal: no
    db 96, 101, 128  ; Skills: FrigidAir, BigBang, DeMagic
    db 24, 30, 26, 21, 23, 23  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 2, 3, 3, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3  ; Resist A-N: Fire..AglDown
    db 3, 2, 2, 2, 3, 3, 3, 3, 3, 3, 2, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $CE (206): Pizzaro ---
MonsterInfo_206_Pizzaro:
    db 9  ; Family: Boss
    db 70  ; Level cap
    db 24  ; Exp table
    db 0  ; Female ratio (0%)
    db 0, 0  ; Can fly: no, Metal: no
    db 80, 92, 100  ; Skills: BiAttack, FireAir, Hellblast
    db 21, 30, 26, 21, 23, 23  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 1, 0, 2, 3, 3, 3, 3, 3, 3, 3, 3  ; Resist A-N: Fire..AglDown
    ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 3
Jump_003_6719:
    db 1, 0, 0, 3, 3, 3, 3, 3, 3, 2, 1, 0
    db 6  ; Tier/rank

; --- Monster $CF (207): Esterk ---
MonsterInfo_207_Esterk:
    db 9  ; Family: Boss
    db 80  ; Level cap
    db 31  ; Exp table
    db 0  ; Female ratio (0%)
    db 0, 0  ; Can fly: no, Metal: no
    db 87, 128, 217  ; Skills: RainSlash, DeMagic, GigaSlash
    db 29, 30, 26, 24, 23, 23  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 2, 2, 2, 0, 1, 3, 3, 3, 3, 3, 3, 2, 2  ; Resist A-N: Fire..AglDown
    db 3, 1, 2, 1, 3, 2, 3, 3, 3, 3, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $D0 (208): Mirudraas ---
MonsterInfo_208_Mirudraas:
    db 9  ; Family: Boss
    db 70  ; Level cap
    db 30  ; Exp table
    db 0  ; Female ratio (0%)
    db 0, 0  ; Can fly: no, Metal: no
    db 0, 6, 15  ; Skills: Blaze, Bang, Bolt
    db 21, 30, 26, 21, 23, 23  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 1, 2, 2, 3, 3, 3, 2, 3, 3, 3, 3  ; Resist A-N: Fire..AglDown
    db 3, 1, 1, 2, 3, 2, 3, 3, 3, 3, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $D1 (209): Mirudraas ---
MonsterInfo_209_Mirudraas:
    db 9  ; Family: Boss
    db 80  ; Level cap
    db 31  ; Exp table
    db 0  ; Female ratio (0%)
    db 0, 0  ; Can fly: no, Metal: no
    db 67, 92, 128  ; Skills: SuckAir, FireAir, DeMagic
    db 29, 30, 26, 21, 23, 23  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 0, 0, 0, 3, 3, 3, 3, 3, 3, 2, 2  ; Resist A-N: Fire..AglDown
    db 3, 1, 3, 1, 3, 3, 3, 3, 3, 3, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $D2 (210): Mudou ---
MonsterInfo_210_Mudou:
    db 9  ; Family: Boss
    db 70  ; Level cap
    db 28  ; Exp table
    db 0  ; Female ratio (0%)
    db 0, 0  ; Can fly: no, Metal: no
    db 92, 96, 108  ; Skills: FireAir, FrigidAir, PoisonGas
    db 21, 30, 26, 24, 23, 23  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 1, 3, 0, 1, 3, 3, 3, 2, 3, 3, 2, 3  ; Resist A-N: Fire..AglDown
    db 3, 0, 3, 3, 3, 2, 3, 3, 3, 3, 0, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $D3 (211): DeathMore ---
MonsterInfo_211_DeathMore:
    db 9  ; Family: Boss
    db 60  ; Level cap
    db 27  ; Exp table
    db 0  ; Female ratio (0%)
    db 1, 0  ; Can fly: yes, Metal: no
    db 100, 101, 132  ; Skills: Hellblast, BigBang, TatsuCall
    db 21, 30, 26, 21, 23, 23  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 2, 2, 1, 1, 2, 3, 3, 3, 2, 3, 3, 3, 3  ; Resist A-N: Fire..AglDown
    db 3, 1, 1, 2, 3, 2, 3, 3, 3, 3, 1, 0, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $D4 (212): DeathMore ---
MonsterInfo_212_DeathMore:
    db 9  ; Family: Boss
    db 70  ; Level cap
    db 29  ; Exp table
    db 0  ; Female ratio (0%)
    db 0, 0  ; Can fly: no, Metal: no
    db 60, 92, 130  ; Skills: Ramming, FireAir, UltraDown
    db 24, 30, 26, 21, 23, 23  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 1, 1, 2, 3, 3, 3, 3, 3, 3, 3, 3  ; Resist A-N: Fire..AglDown
    db 3, 1, 1, 2, 3, 2, 3, 3, 3, 3, 2, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $D5 (213): DeathMore ---
MonsterInfo_213_DeathMore:
    db 9  ; Family: Boss
    db 80  ; Level cap
    db 31  ; Exp table
    db 0  ; Female ratio (0%)
    db 1, 0  ; Can fly: yes, Metal: no
    db 84, 101, 128  ; Skills: Focus, BigBang, DeMagic
    db 29, 30, 30, 24, 23, 23  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 2, 2  ; Resist A-N: Fire..AglDown
    db 3, 1, 2, 2, 3, 3, 3, 3, 3, 3, 3, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 6  ; Tier/rank

; --- Monster $D6 (214): Darkdrium ---
MonsterInfo_214_Darkdrium:
    db 9  ; Family: Boss
    db 80  ; Level cap
    db 30  ; Exp table
    db 0  ; Female ratio (0%)
    db 0, 0  ; Can fly: no, Metal: no
    db 15, 92, 96  ; Skills: Bolt, FireAir, FrigidAir
    db 31, 30, 31, 24, 23, 23  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 2, 2, 3, 3, 3, 2, 2, 3, 3, 2, 3  ; Resist A-N: Fire..AglDown
    db 3, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 7  ; Tier/rank

; --- Monster $D7 (215): TERRY? ---
MonsterInfo_215_TERRY:
    db 9  ; Family: Boss
    db 0  ; Level cap
    db 0  ; Exp table
    db 0  ; Female ratio (0%)
    db 0, 0  ; Can fly: no, Metal: no
    db 0, 0, 0  ; Skills: Blaze, Blaze, Blaze
    db 0, 0, 0, 0, 0, 0  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 2, 1, 1, 0, 1, 2, 3, 3, 1, 1, 2, 0, 0  ; Resist A-N: Fire..AglDown
    db 2, 0, 1, 1, 0, 3, 0, 1, 0, 0, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 7  ; Tier/rank

; --- Monster $D8 (216): Tatsu ---
MonsterInfo_216_Tatsu:
    db 9  ; Family: Boss
    db 0  ; Level cap
    ; Exp table
Jump_003_68ab:
    db 0
    db 0  ; Female ratio (0%)
    db 0, 0  ; Can fly: no, Metal: no
    db 0, 0, 0  ; Skills: Blaze, Blaze, Blaze
    db 0, 0, 0, 0, 0, 0  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 1, 2, 2, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1  ; Resist A-N: Fire..AglDown
    db 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 7  ; Tier/rank

; --- Monster $D9 (217): Diago ---
MonsterInfo_217_Diago:
    db 9  ; Family: Boss
    db 0  ; Level cap
    db 0  ; Exp table
    db 0  ; Female ratio (0%)
    db 0, 0  ; Can fly: no, Metal: no
    db 0, 0, 0  ; Skills: Blaze, Blaze, Blaze
    db 0, 0, 0, 0, 0, 0  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 3, 2, 2, 0, 0, 1, 1, 1, 2, 1, 0, 1, 1, 1  ; Resist A-N: Fire..AglDown
    db 0, 0, 3, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 7  ; Tier/rank

; --- Monster $DA (218): Samsi ---
MonsterInfo_218_Samsi:
    db 9  ; Family: Boss
    db 0  ; Level cap
    db 0  ; Exp table
    db 0  ; Female ratio (0%)
    db 0, 0  ; Can fly: no, Metal: no
    db 0, 0, 0  ; Skills: Blaze, Blaze, Blaze
    db 0, 0, 0, 0, 0, 0  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 2, 1, 3, 0, 1, 2, 2, 3, 1, 1, 1, 0, 1  ; Resist A-N: Fire..AglDown
    db 0, 0, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 7  ; Tier/rank

; --- Monster $DB (219): Bazoo ---
MonsterInfo_219_Bazoo:
    db 9  ; Family: Boss
    db 0  ; Level cap
    db 0  ; Exp table
    db 0  ; Female ratio (0%)
    db 0, 0  ; Can fly: no, Metal: no
    db 0, 0, 0  ; Skills: Blaze, Blaze, Blaze
    db 0, 0, 0, 0, 0, 0  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 1, 2, 2, 1, 2, 3, 3, 3, 3, 2, 2, 2, 2, 2  ; Resist A-N: Fire..AglDown
    db 1, 0, 1, 3, 2, 2, 2, 2, 2, 2, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 7  ; Tier/rank

; --- Monster $DC (220): Unused_220 ---
MonsterInfo_220_Unused_220:
    db 9  ; Family: Boss
    db 0  ; Level cap
    db 0  ; Exp table
    db 0  ; Female ratio (0%)
    db 0, 0  ; Can fly: no, Metal: no
    db 0, 0, 0  ; Skills: Blaze, Blaze, Blaze
    db 0, 0, 20, 0, 0, 0  ; Growth: HP, MP, ATK, DEF, AGL, INT
    db 2, 2, 2, 2, 2, 2, 2, 2, 3, 1, 1, 2, 2, 1  ; Resist A-N: Fire..AglDown
    db 1, 0, 3, 3, 2, 3, 2, 2, 1, 1, 2, 2, 0  ; Resist O-Z+unused: Sacrifice..GigaSlash+unused
    db 7  ; Tier/rank

SetMon_6980:
    ld de, $da62
    call SaveMon_6987
    ret


SaveMon_6987:
    push de
    ld a, [$da5e]
    ld c, $0c
    call Mul8x8To16
    ld a, l
    add $da
    ld l, a
    ld a, h
    adc $71
    ld h, a
    pop de
    ld b, $0c

jr_003_699b:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, jr_003_699b

    ret

label69a2:
    ld a, [$da5e]
    cp $ff
    ret z

    ld a, [$da5e]
    rst $00

Jump_003_69ac:
    inc b
    ld l, d
    dec b
    ld l, d
    dec b
    ld l, d
    inc l
    ld l, d
    inc l
    ld l, d
    add hl, hl
    ld l, e
    add hl, hl
    ld l, e
    ld d, b
    ld l, e
    ld h, [hl]
    ld l, e
    ld a, h
    ld l, e
    sub d
    ld l, e
    xor b
    ld l, e
    cp [hl]
    ld l, e
    ret nc

    ld l, e
    db $e4
    ld l, e

SetMon_69ca:
    ld hl, sp+$6b
    inc c
    ld l, h
    jr nz, @+$6e

    inc [hl]
    ld l, h
    ld c, b
    ld l, h
    ld c, b
    ld l, h
    ld c, b
    ld l, h
    ld c, b
    ld l, h
    ld c, b
    ld l, h
    ld c, h
    ld l, h
    ld c, h
    ld l, h
    ld c, h
    ld l, h
    ld c, h
    ld l, h
    ld c, h
    ld l, h
    ld c, h
    ld l, h
    ld c, h
    ld l, h
    ld c, l
    ld l, h
    ld h, e
    ld l, h
    ld a, b
    ld l, h
    adc [hl]
    ld l, h
    and e
    ld l, h
    cp c
    ld l, h
    adc $6c
    rst $08
    ld l, h
    ret nz

    ld l, l
    call $df6d
    ld l, l
    rst $18
    ld l, l
    ld [wWarpGateId], a
    call LoadMon_6e11
    ret nz

    ld a, [$da60]
    ld hl, $cb13
    call ReadMonsterWord
    push bc
    ld a, [$da60]
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
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


    ld a, [$ca8d]
    or a
    jp z, Jump_003_6ab9

    ld a, $00
    ld hl, $cb0b
    call ReadMonsterByte
    bit 7, a
    jr nz, jr_003_6a5b

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
    jr nz, jr_003_6abf

jr_003_6a5b:
    ld a, [$ca8d]
    cp $01
    jr z, jr_003_6ab9

    ld a, $01
    ld hl, $cb0b
    call ReadMonsterByte
    bit 7, a
    jr nz, jr_003_6a8a

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
    jr nz, jr_003_6abf

jr_003_6a8a:
    ld a, [$ca8d]
    cp $02
    jr z, jr_003_6ab9

    ld a, $02
    ld hl, $cb0b
    call ReadMonsterByte
    bit 7, a
    jr nz, jr_003_6ab9

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
    jr nz, jr_003_6abf

Jump_003_6ab9:
jr_003_6ab9:
    ld a, $ff
    ld [$da5e], a
    ret


jr_003_6abf:
    ld d, $00
    ld a, $00
    call FuncMon_6ad7
    ld a, $01
    call FuncMon_6ad7
    ld a, $02
    call FuncMon_6ad7
    ld a, $26
    add d
    ld [$da6a], a
    ret


FuncMon_6ad7:
    ld [$da60], a
    ld hl, $ca8d
    cp [hl]
    ret nc

    push de
    ld hl, $cb0b
    call ReadMonsterByte
    bit 7, a
    pop de
    ret nz

    push de
    ld a, [$da60]
    ld hl, $cb13
    call ReadMonsterWord
    push bc
    ld a, [$da60]
    ld hl, $cb11
    call ReadMonsterWord
    pop hl
    pop de
    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    ld a, h
    or l
    ret z

    push de
    ld a, d
    swap a
    ld hl, $c1b0
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    push hl
    ld a, [$da60]
    ld hl, $cac2
    call GetCurrentMonsterPtr
    ld e, l
    ld d, h
    pop hl
    call Copy4Bytes
    pop de
    inc d
    ret


    call LoadMon_6e11
    ret nz

    ld a, [$da60]
    ld hl, $cb17
    call ReadMonsterWord
    push bc
    ld a, [$da60]
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
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


    call LoadMon_6e11
    ret nz

    ld a, [$da60]
    ld hl, $cb0b
    call ReadMonsterByte
    bit 2, a
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


    call LoadMon_6e11
    ret nz

    ld a, [$da60]
    ld hl, $cb0b
    call ReadMonsterByte
    bit 3, a
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


    call LoadMon_6e11
    ret nz

    ld a, [$da60]
    ld hl, $cb0b
    call ReadMonsterByte
    bit 4, a
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


    call LoadMon_6e11
    ret nz

    ld a, [$da60]
    ld hl, $cb0b
    call ReadMonsterByte
    bit 0, a
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


    call LoadMon_6e11
    ret nz

    ld a, [$da60]
    ld hl, $cb0b
    call ReadMonsterByte
    bit 1, a
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


    ld a, [$da60]
    ld hl, $cb0b
    call ReadMonsterByte
    bit 7, a
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


    call LoadMon_6e11
    ret nz

    ld a, [$da60]
    ld hl, $cb13
    call ReadMonsterWord
    ld hl, $03e7
    call LoadMon_7110
    ret


    call LoadMon_6e11
    ret nz

    ld a, [$da60]
    ld hl, $cb17
    call ReadMonsterWord
    ld hl, $03e7
    call LoadMon_7110
    ret


    call LoadMon_6e11
    ret nz

    ld a, [$da60]
    ld hl, $cb19
    call ReadMonsterWord
    ld hl, $03e7
    call LoadMon_7110
    ret


    call LoadMon_6e11
    ret nz

    ld a, [$da60]
    ld hl, $cb1b
    call ReadMonsterWord
    ld hl, $03e7
    call LoadMon_7110
    ret


    call LoadMon_6e11
    ret nz

    ld a, [$da60]
    ld hl, $cb1d
    call ReadMonsterWord
    ld hl, $01ff
    call LoadMon_7110
    ret


    call LoadMon_6e11
    ret nz

    ld a, [$da60]
    ld hl, $cb1f
    call ReadMonsterWord
    ld hl, $00ff
    call LoadMon_7110
    ret


    call LoadMon_6e11
    ret nz

    ret


    call LoadMon_6e11
    ret nz

    ld a, [$da60]
    ld hl, $cb25
    call ReadMonsterByte
    cp $ff
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


    call LoadMon_6e11
    ret nz

    ld a, [$da60]
    ld hl, $cb25
    call ReadMonsterByte
    or a
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


    call LoadMon_6e11
    ret nz

    ld a, [$da60]
    ld hl, $cb26
    call ReadMonsterByte
    cp $ff
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


    call LoadMon_6e11
    ret nz

    ld a, [$da60]
    ld hl, $cb26
    call ReadMonsterByte
    or a
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


    call LoadMon_6e11
    ret nz

    ld a, [$da60]
    ld hl, $cb28
    call ReadMonsterByte
    cp $ff
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


    call LoadMon_6e11
    ret nz

    ld a, [$da60]
    ld hl, $cb28
    call ReadMonsterByte
    or a
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


    ret


    ldh a, [$95]
    ld l, a
    ldh a, [$96]
    ld h, a
    ld a, l
    and $f0
    ld l, a
    ld a, [$c966]
    ld e, a
    ld a, [$c967]
    ld d, a
    ld a, e
    and $f0
    ld e, a
    ld a, l
    sub e
    ld l, a
    ld a, h
    sbc d
    ld h, a
    jr nc, jr_003_6cf7

    ld a, l
    cpl
    add $01
    ld l, a
    ld a, h
    cpl
    adc $00
    ld h, a

jr_003_6cf7:
    ldh a, [$92]
    ld e, a
    ldh a, [$93]
    ld d, a
    ld a, e
    and $f0
    ld e, a
    ld a, [$c964]
    ld c, a
    ld a, [$c965]
    ld b, a
    ld a, c
    and $f0
    ld c, a
    ld a, e
    sub c
    ld e, a
    ld a, d
    sbc b
    ld d, a
    jr nc, jr_003_6d1f

    ld a, e
    cpl
    add $01
    ld e, a
    ld a, d
    cpl
    adc $00
    ld d, a

jr_003_6d1f:
    push hl
    push de
    ld a, h
    or a
    jr nz, jr_003_6d44

    ld a, d
    or a
    jr nz, jr_003_6d44

    ld a, l
    cp $20
    jr nz, jr_003_6d37

    ld a, e
    cp $50
    jr c, jr_003_6d44

    ld b, $00
    jr jr_003_6d64

jr_003_6d37:
    cp $10
    jr nz, jr_003_6d44

    ld a, e
    cp $30
    jr c, jr_003_6d44

Jump_003_6d40:
    ld b, $00
    jr jr_003_6d64

jr_003_6d44:
    ldh a, [$95]
    ld l, a
    ldh a, [$96]
    ld h, a
    ld a, [$c966]
    ld e, a
    ld a, [$c967]
    ld d, a
    ld a, l
    sub e
    ld l, a
    ld a, h
    sbc d
    ld h, a
    ld b, $06
    jr c, jr_003_6d64

    ld a, h
    or l
    ld b, $03
    jr nz, jr_003_6d64

    ld b, $00

jr_003_6d64:
    pop de
    pop hl
    ld a, h
    or a
    jr nz, jr_003_6d89

    ld a, d
    or a
    jr nz, jr_003_6d89

    ld a, e
    cp $20
    jr nz, jr_003_6d7c

    ld a, l
    cp $50
    jr c, jr_003_6d89

    ld a, $00
    jr jr_003_6da9

jr_003_6d7c:
    cp $10
    jr nz, jr_003_6d89

    ld a, l
    cp $30
    jr c, jr_003_6d89

    ld a, $00
    jr jr_003_6da9

jr_003_6d89:
    ldh a, [$92]
    ld l, a
    ldh a, [$93]
    ld h, a
    ld a, [$c964]
    ld e, a
    ld a, [$c965]
    ld d, a
    ld a, l
    sub e
    ld l, a
    ld a, h
    sbc d
    ld h, a
    ld a, $02
    jr c, jr_003_6da9

    ld a, h
    or l
    ld a, $01
    jr nz, jr_003_6da9

    ld a, $00

jr_003_6da9:
    add b
    add $3a
    ld l, a
    ld h, $02
    ld de, $c1b0
    call SetupVRAMParams
    ld a, [wInGateworld]
    or a
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


    ld a, [wInGateworld]
    or a
    jr z, jr_003_6dc7

    ret


jr_003_6dc7:
    ld a, $ff
    ld [$da5e], a
    ret


    ld a, [$c93e]
    bit 1, a
    jr nz, jr_003_6dd9

    ld a, [wInGateworld]
    or a
    ret nz

jr_003_6dd9:
    ld a, $ff
    ld [$da5e], a
    ret


    ld a, [wInGateworld]
    or a
    ret nz

    ld a, $ff
    ld [$da5e], a
    ret


    ld a, [wInGateworld]
    or a
    ret nz

    ld a, [wMapID]
    cp $53
    jr c, jr_003_6e0b

    cp $5a
    jr z, jr_003_6e0b

    cp $5b
    jr z, jr_003_6e0b

    cp $5c
    jr z, jr_003_6e0b

    cp $5d
    jr z, jr_003_6e0b

    cp $60
    jr z, jr_003_6e0b

    ret


jr_003_6e0b:
    ld a, $ff
    ld [$da5e], a
    ret


LoadMon_6e11:
    ld a, [$da60]
    ld hl, $cb0b
    call ReadMonsterByte
    bit 7, a
    ret z

    ld a, $ff
    ld [$da5e], a
    or a
    ret

label6e24:
    ld a, [$da5e]
    cp $ff
    ret z

    call SetMon_6980
    ld a, [$da5e]
    rst $00
    adc c
    ld l, [hl]
    adc d
    ld l, [hl]
    adc d
    ld l, [hl]
    xor b
    ld l, [hl]
    rst $18
    ld l, [hl]
    ld de, $2f6f
    ld l, a
    ld b, l
    ld l, a
    ld d, h
    ld l, a
    ld h, e
    ld l, a
    ld [hl], d
    ld l, a
    add c
    ld l, a
    sub b
    ld l, a
    or l
    ld l, a
    push bc
    ld l, a
    push de
    ld l, a
    push hl
    ld l, a
    push af
    ld l, a
    dec b
    ld [hl], b
    dec d
    ld [hl], b
    dec d
    ld [hl], b
    dec d
    ld [hl], b
    dec h
    ld [hl], b
    ld b, b
    ld [hl], b
    ld d, b
    ld [hl], b
    ld d, c
    ld [hl], b
    ld d, d
    ld [hl], b
    ld d, e
    ld [hl], b
    ld d, h
    ld [hl], b
    ld d, l
    ld [hl], b
    ld e, c
    ld [hl], b
    ld e, d
    ld [hl], b
    ld l, d
    ld [hl], b
    ld a, d
    ld [hl], b
    adc d
    ld [hl], b
    sbc d
    ld [hl], b
    xor d
    ld [hl], b
    cp d
    ld [hl], b
    cp e
    ld [hl], b
    cp a
    ld [hl], b
    jp $cc70


    ld [hl], b
    and $70
    push af
    ld [hl], b
    ret


    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $0b
    call Div8x8
    ld b, a
    ld a, [$da6b]
    add b
    ld l, a
    ld h, $00
    ld a, [$da60]
    call GetMonsterSkillData
    call CallMon_7134
    ret


    ld a, $00
    ld [$da60], a
    call CallMon_6ec4
    ld a, $01
    ld [$da60], a
    call CallMon_6ec4
    ld a, $02
    ld [$da60], a
    call CallMon_6ec4
    call CallMon_7134
    ret


CallMon_6ec4:
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $0b
    call Div8x8
    ld b, a
    ld a, [$da6b]
    add b
    ld l, a
    ld h, $00
    ld a, [$da60]
    call GetMonsterSkillData
    ret


    ld a, $00
    call SetMon_6ef2
    ld a, $01
    call SetMon_6ef2
    ld a, $02
    call SetMon_6ef2
    call CallMon_7134
    ret


SetMon_6ef2:
    ld hl, $ca8d
    cp [hl]
    ret nc

    ld [$da60], a
    call LoadMon_6e11
    ret nz

    ld a, [$da60]
    ld hl, $cb13
    call ReadMonsterWord
    ld a, [$da60]
    ld hl, $cb11
    call WriteMonsterWord
    ret


    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $0b
    call Div8x8
    ld b, a
    ld a, [$da6b]
    add b
    ld l, a
    ld h, $00
    ld a, [$da60]
    call GetMonsterSlotAndPush
    call CallMon_7134
    ret


    ld a, [$da60]
    ld hl, $cb17
    call ReadMonsterWord
    ld a, [$da60]
    ld hl, $cb15
    call WriteMonsterWord
    call CallMon_7134
    ret


    ld a, [$da60]
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    res 2, [hl]
    call CallMon_7134
    ret


    ld a, [$da60]
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    res 3, [hl]
    call CallMon_7134
    ret


    ld a, [$da60]
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    res 4, [hl]
    call CallMon_7134
    ret


    ld a, [$da60]
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    res 0, [hl]
    call CallMon_7134
    ret


    ld a, [$da60]
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    res 1, [hl]
    call CallMon_7134
    ret


    ld a, [$da60]
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    ld [hl], $00
    ld a, [$da60]
    ld hl, $cb13
    call ReadMonsterWord
    ld a, [$da60]
    ld hl, $cb11
    call WriteMonsterWord
    ld hl, $0103
    rst $10
    call CallMon_7134
    ret


    ld a, [$da6b]
    ld l, a
    ld h, $00
    ld a, [$da60]
    call AddMonsterHP_Setup
    call CallMon_7134
    ret


    ld a, [$da6b]
    ld l, a
    ld h, $00
    ld a, [$da60]
    call MonsterStatAddWrap
    call CallMon_7134
    ret


    ld a, [$da6b]
    ld l, a
    ld h, $00
    ld a, [$da60]
    call SetATKMax999
    call CallMon_7134
    ret


    ld a, [$da6b]
    ld l, a
    ld h, $00
    ld a, [$da60]
    call SubMonsterATK_Alt
    call CallMon_7134
    ret


    ld a, [$da6b]
    ld l, a
    ld h, $00
    ld a, [$da60]
    call MonsterStatDecLoop
    call CallMon_7134
    ret


    ld a, [$da6b]
    ld l, a
    ld h, $00
    ld a, [$da60]
    call AddMonsterINT_Alt
    call CallMon_7134
    ret


    ld a, [$da6b]
    ld l, a
    ld h, $00
    ld a, [$da60]
    call ClearMonsterAGL
    call CallMon_7134
    ret


    ld a, [$da6b]
    ld l, a
    ld h, $00
    ld a, [$da60]
    call ClearMonsterAGL
    ld a, [$da60]
    ld hl, $cb0b
    call GetCurrentMonsterPtr
    set 2, [hl]
    call CallMon_7134
    ret


    ld a, [$da6b]
    ld l, a
    ld h, $00
    ld a, [$da60]
    call ClearMonsterAGL
    call CallMon_7134
    ret


    ret


    ret


    ret


    ret


    ret


    call CallMon_7134
    ret


    ret


    ld a, [$da6b]
    ld l, a
    ld h, $00
    ld a, [$da60]
    call SetMonsterSkill1
    call CallMon_7134
    ret


    ld a, [$da6b]
    ld l, a
    ld h, $00
    ld a, [$da60]
    call ClearMonsterSkill1
    call CallMon_7134
    ret


    ld a, [$da6b]
    ld l, a
    ld h, $00
    ld a, [$da60]
    call SetMonsterSkill2
    call CallMon_7134
    ret


    ld a, [$da6b]
    ld l, a
    ld h, $00
    ld a, [$da60]
    call ClearMonsterSkill2
    call CallMon_7134
    ret


    ld a, [$da6b]
    ld l, a
    ld h, $00
    ld a, [$da60]
    call SetMonsterSkill3
    call CallMon_7134
    ret


    ld a, [$da6b]
    ld l, a
    ld h, $00
    ld a, [$da60]
    call ClearMonsterSkill3
    call CallMon_7134
    ret


    ret


    call CallMon_7134
    ret


    call CallMon_7134
    ret


    ld hl, $c93e
    set 1, [hl]
    call CallMon_7134
    ret


    ld hl, $010b
    rst $10
    ld hl, wGameState
    set 6, [hl]
    xor a
    ld [$c905], a
    ld a, $00
    ld [$da09], a
    ld hl, $c90d
    inc [hl]
    call CallMon_7134
    ret


    ld hl, $c950
    ld bc, $0010
    ld a, $01
    call FillNBytesWithRegA
    call CallMon_7134
    ret


    ld a, [$c83c]
    or a
    jr nz, jr_003_710f

    call CallMon_7134
    di
    call SaveGameState
    ei
    ld a, $59
    call PlaySoundEffect
    ld h, $0d
    ld l, $2f
    call SetupTilemapTransfer

jr_003_710f:
    ret


LoadMon_7110:
    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    ld a, h
    or l
    jr z, jr_003_712e

    ld a, h
    or a
    ld a, [$da6b]
    jr nz, jr_003_7127

    cp l
    jr z, jr_003_7127

    jr c, jr_003_7127

    ld a, l

jr_003_7127:
    ld hl, $c1b0
    call ExtractDigits
    ret


jr_003_712e:
    ld a, $ff
    ld [$da5e], a
    ret


CallMon_7134:
    call GenerateRNG
    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    ld a, $64
    call Div16x8To16
    ld hl, $da65
    cp [hl]
    ret nc

    ld a, $ff
    ld [$da5e], a
    ld a, [$da5f]
    ld hl, wInventory
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $ff
    call SetMon_7160
    ret


SetMon_7160:
    ld hl, $c0d8
    ld de, wInventory
    ld b, $14

jr_003_7168:
    ld a, [de]
    ld [hl+], a
    inc de
    dec b
    jr nz, jr_003_7168

    ld hl, wInventory
    ld bc, $0014
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $c0d8
    ld de, wInventory
    ld b, $14

jr_003_7181:
    ld a, [hl+]
    cp $ff
    jr z, jr_003_718c

    cp $00
    jr z, jr_003_718c

    ld [de], a
    inc de

jr_003_718c:
    dec b
    jr nz, jr_003_7181

    ret

label7190:
    ld a, [$da5e]
    cp $00
    ret z

    cp $ff
    ret z

    ld hl, wInventory
    ld b, $14

jr_003_719e:
    ld a, [hl]
    cp $00
    jr z, jr_003_71b1

    cp $ff
    jr z, jr_003_71b1

    inc hl
    dec b
    jr nz, jr_003_719e

    ld a, $ff
    ld [$da5e], a
    ret


jr_003_71b1:
    ld a, [$da5e]
    ld [hl], a
    ret

label71b6:
    ld a, [$da5e]
    cp $00
    ret z

    cp $ff
    ret z

    ld hl, wInventory
    ld b, $14

jr_003_71c4:
    ld a, [$da5e]
    cp [hl]
    jr z, jr_003_71d4

    inc hl
    dec b
    jr nz, jr_003_71c4

    ld a, $ff
    ld [$da5e], a
    ret


jr_003_71d4:
    ld [hl], $ff
    call SetMon_7160
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
    ld [$6400], sp
    nop
    inc b
    nop
    inc bc
    inc b
    ld e, $28
    nop
    nop
    ld d, b
    nop
    ld h, h
    nop
    inc b
    ld bc, $0403
    inc a
    ld b, [hl]
    nop
    nop
    add sp, $03
    inc d
    ld [bc], a
    dec b
    nop
    dec b
    inc b
    dec l
    scf
    nop
    nop
    db $f4
    ld bc, $0064
    dec b
    ld bc, $0406
    rst $38
    rst $38
    nop
    nop
    ret z

    nop
    ld h, h
    nop
    inc b
    ld bc, $0703
    inc d
    ld e, $00
    nop
    ret nc

    rlca
    ld h, h
    nop
    inc b
    ld bc, $0703
    rst $38
    rst $38
    nop
    ld bc, $000a
    ld h, h
    nop
    inc b
    nop
    inc bc
    ld [$0000], sp
    nop
    ld bc, $001e
    ld h, h
    nop
    inc b
    nop
    inc bc
    add hl, bc
    nop
    nop
    nop
    ld bc, $0032
    ld h, h
    nop
    inc b
    ld [bc], a
    inc bc
    ld a, [bc]
    nop
    nop
    nop
    ld bc, $0050
    ld h, h
    nop
    inc b
    ld b, $06
    dec bc
    nop
    nop
    nop
    ld bc, $0032
    ld h, h
    nop
    inc b
    ld bc, $0c03
    nop
    nop
    nop
    ld bc, $03e8
    ld h, h
    nop
    inc b
    nop
    inc bc
    dec c
    nop
    nop
    nop
    ld [bc], a
    ld a, [de]
    nop
    ld h, h
    nop
    inc b
    inc bc
    inc bc
    ld c, $05
    nop
    nop
    ld [bc], a
    ld e, $00
    ld h, h
    nop
    inc b
    inc bc
    inc bc
    rrca
    dec b
    nop
    nop
    ld [bc], a
    ld d, $00
    ld h, h
    nop
    inc b
    inc bc
    inc bc
    db $10
    inc bc
    nop
    nop
    ld [bc], a
    ld d, $00
    ld h, h
    nop
    inc b
    inc bc
    inc bc
    ld de, $0003
    nop
    ld [bc], a
    ld [de], a
    nop
    ld h, h
    nop
    inc b
    inc bc
    inc bc
    ld [de], a
    inc bc
    nop
    nop
    ld [bc], a
    rrca
    nop
    ld h, h
    nop
    inc b
    inc bc
    inc bc
    inc de
    inc bc
    nop
    nop
    inc bc
    inc d
    nop
    ld h, h
    nop
    inc b
    inc b
    inc d
    dec d
    dec b
    ld a, [bc]
    nop
    inc bc
    ld d, b
    nop
    ld h, h
    nop
    inc b
    inc b
    inc d
    dec d
    ld a, [bc]
    ld e, $00
    inc bc
    inc l

jr_003_72d8:
    ld bc, $0064
    inc b
    inc b
    inc d
    dec d
    inc d
    ld h, h
    nop
    inc bc
    inc d
    nop
    ld h, h
    nop
    inc b
    inc b
    inc d
    ld d, $05
    dec b
    ld bc, $e803
    inc bc
    ld h, h
    nop
    inc b
    inc b
    inc d
    dec d
    ld h, h
    rst $38
    nop
    inc b
    cp b
    dec bc
    inc d
    ld [bc], a
    inc bc
    dec b
    rla
    jr jr_003_7327

    ld [hl-], a
    nop
    inc b
    call c, $0a05
    ld [bc], a
    inc bc
    dec b
    rla
    add hl, de
    ld [$0018], sp
    inc b
    cp h
    ld [bc], a
    inc d
    ld [bc], a
    inc bc
    dec b
    rla
    ld a, [de]
    nop
    nop
    nop
    inc b
    ret nc

    rlca
    inc d
    ld [bc], a
    inc bc
    dec b
    rla
    dec de

jr_003_7327:
    ld e, $2a
    nop
    inc b
    and b
    rrca
    inc d
    ld [bc], a
    inc bc
    dec b
    rla
    inc e
    ld a, b
    adc h
    nop
    dec b
    ld h, h
    nop
    ld h, h
    ld bc, $0607
    dec e
    nop
    nop
    nop
    nop
    ld b, $01
    nop
    ld h, h
    inc bc
    rlca
    rlca
    ld e, $00
    nop
    nop
    dec b
    ld [bc], a
    adc b
    inc de
    ld h, h
    ld bc, $0000
    rra
    jr nz, jr_003_72d8

    add b
    nop
    ld [bc], a
    adc b
    inc de
    ld h, h
    ld bc, $0000
    rra
    ld hl, $8080
    nop
    ld [bc], a
    adc b
    inc de
    ld h, h
    ld bc, $0000
    rra
    ld [hl+], a
    add b
    add b
    nop
    ld [bc], a
    adc b
    inc de
    ld h, h
    ld bc, $0000
    rra
    inc hl
    add b
    add b
    nop
    ld [bc], a
    adc b
    inc de
    ld h, h
    ld bc, $0000
    rra
    inc h
    add b
    add b
    nop
    ld [bc], a
    adc b
    inc de
    ld h, h
    ld bc, $0000
    rra
    dec h
    add b
    add b
    nop
    inc b
    adc b
    inc de
    inc d
    ld [bc], a
    ld [bc], a
    dec b
    rla
    ld h, $b4
    ret z

    nop
    rlca
    sub b
    ld bc, $0100
    ld bc, $1e07
    ld a, [hl+]
    nop
    nop
    inc b
    rlca
    ld h, h
    nop
    ld h, h
    ld bc, $0701
    ld e, $00
    nop
    nop
    inc b
    rlca
    ret z

    nop
    ld h, h
    ld bc, $0701
    ld e, $2b
    nop
    nop
    nop
    rlca
    cp b
    dec bc
    nop
    ld bc, $0701
    inc l
    nop
    nop
    nop
    inc b
    rlca
    ld b, [hl]
    nop
    ld h, h
    ld bc, $0701
    ld e, $2d
    nop
    nop
    nop
    rlca
    ld h, h
    nop
    ld h, h
    ld bc, $0707
    ld e, $2e
    nop
    nop
    inc b
    xor a
    ld [$cdc7], a
    call LoadMon_7409
    ld hl, $cdc1
    ld b, $05

jr_003_73f6:
    ld a, [hl+]
    inc a
    jp nz, $68c1

    dec b
    jr nz, jr_003_73f6

    ld a, $40
    ld [$cd80], a
    ld a, $12
    ld [$ccb4], a
    ret


LoadMon_7409:
    ld a, [$cdc0]
    rst $00
    dec d
    ld [hl], h
    dec d
    ld [hl], h
    ld l, $74
    dec a
    ld [hl], h

SetMon_7415:
    ld hl, $cb08
    ld de, $cdc1

FuncMon_741b:
Jump_003_741b:
    ld c, [hl]
    dec h
    dec h
    dec h
    dec h
    ld b, [hl]
    dec h
    dec h
    dec h
    dec h
    ld a, [hl]

CallMon_7426:
Jump_003_7426:
    call CmpMon_745a
    sub $52
    ld [de], a
    inc e
    ret


CallMon_742e:
    call SetMon_7415
    ld hl, $ca08
    call FuncMon_741b
    ld hl, $cc08
    jp Jump_003_741b


    call CallMon_742e
    ld hl, $cc08
    ld c, [hl]
    ld h, $c7
    ld b, [hl]
    ld h, $c2
    ld a, [hl]
    call CallMon_7426
    ld hl, $ca08
    ld c, [hl]
    ld h, $c7
    ld b, [hl]
    ld h, $c4
    ld a, [hl]
    jp Jump_003_7426


CmpMon_745a:
    cp b
    jr nz, jr_003_7461

    cp c
    jr nz, jr_003_7461

    ret


jr_003_7461:
    cp $57
    jr nz, jr_003_746b

    cp b
    jr nz, jr_003_746e

    ld a, $58
    ret


jr_003_746b:
    ld a, $51
    ret


jr_003_746e:
    ld a, $59
    ret


LoadMon_7471:
    ld a, [$c982]
    bit 4, a
    jr nz, jr_003_747b

    ld a, $10
    rst $28

jr_003_747b:
    jp $091e


    ld c, $c1
    ld hl, $d8b8

jr_003_7483:
    ld b, $cd
    ld a, [bc]
    inc a
    jp z, $68c1

jr_003_748a:
    push hl
    push af
    call LoadMon_7471
    pop af
    call CalcMon_74c7
    pop hl
    ld a, [$cdc7]
    cp $03
    ret nz

    call $091e

Jump_003_749d:
    xor a
    ld [$cdc7], a
    ld a, $10
    jp $68be


    ld c, $c2
    ld hl, $d8d8
    jr jr_003_7483

    ld c, $c3
    ld hl, $d8f8
    jr jr_003_7483

    ld c, $c4
    ld hl, $d918
    jr jr_003_7483

    ld a, [$cdc5]
    inc a
    jp z, Jump_003_749d

    ld hl, $d938
    jr jr_003_748a

CalcMon_74c7:
    dec a
    ld b, a
    ld a, [$cdc7]
    rst $00
    push de
    ld [hl], h
    dec b
    ld [hl], l
    ld a, a
    ld [hl], l
    sub l
    ld [hl], l
    push bc
    scf
    ld a, b
    ld hl, $75a6
    rst $08
    call $091e
    pop bc
    ld a, b
    ld hl, $7596
    rst $08
    ld a, l
    ld [$cdc6], a
    ld a, h
    ld d, $cd
    rst $20
    ld bc, $101a
    call $05e2
    call SetJoypadAction
    ld a, $27
    call BankTrampolineTable
    ld a, $80

Jump_003_74fd:
    ld [$cdc8], a

Jump_003_7500:
    ld hl, $cdc7
    inc [hl]
    ret


    ld a, [$cdc8]
    or a
    jr z, jr_003_7510

    dec a
    ld [$cdc8], a
    ret


jr_003_7510:
    ld a, [$c982]
    and $0f
    ret nz

    push bc
    ld bc, $9864
    ld hl, $cdc6
    ld a, [hl]
    or a
    jr z, jr_003_752a

    sub $01
    daa
    ld [hl], a
    call PixelToTileCoord
    xor a
    inc a

jr_003_752a:
    pop bc
    jr z, jr_003_753f

    ld a, b
    rst $00
    ld c, l
    ld [hl], l
    ld b, h
    ld [hl], l
    ld e, b
    ld [hl], l
    ld l, a
    ld [hl], l
    ld [hl], a
    ld [hl], l
    ld c, l
    ld [hl], l
    ld c, l
    ld [hl], l
    ld c, l
    ld [hl], l

jr_003_753f:
    ld a, $20
    jp Jump_003_74fd


    call $0be2
    ld bc, $9c46
    jp $0bf3


    ld a, $08
    call BankTrampolineTable
    ld bc, $9c85
    jp Jump_000_0c3a


    ld hl, $c9f1
    ld bc, $9c4b

jr_003_755e:
    push hl
    push bc
    ld b, $01
    call GetScrollTilePosition
    pop bc
    pop hl
    call PixelToTileCoord
    ld a, $14
    jp Jump_000_0515


    ld hl, $c9f3
    ld bc, $9c8b
    jr jr_003_755e

    ld hl, $c9f2
    ld bc, $9c6b
    jr jr_003_755e

    ld hl, $cdc8
    dec [hl]
    ret nz

    ld a, b
    ld hl, $75a6
    rst $08
    scf
    ccf
    call MultiplyHL_091F
    xor a
    ld [$cd07], a
    jp Jump_003_7500


    ret


    ld d, b
    ld h, e
    inc bc
    nop
    dec b
    dec [hl]
    dec b
    scf
    dec b
    ld [hl], $10
    ld h, e
    dec b
    ld h, e
    ld [bc], a
    ld h, e
    jp c, $b675

    ld [hl], l
    ret z

    ld [hl], l
    ret z

    ld [hl], l
    ret z

    ld [hl], l
    adc $75
    ret z

    ld [hl], l
    call nc, CallMon_4175
    sbc b
    add hl, de
    inc e
    cp $61
    sbc b
    ld a, [de]
    dec e
    ld l, $01
    inc b
    cp $81
    sbc b
    dec de
    ld e, $ff
    ld h, e
    sbc b
    ld l, $01
    ld b, $ff
    ld h, e
    sbc b
    ld l, $02
    ld bc, $63ff
    sbc b
    ld l, $01
    inc bc
    rst $38
    ld h, e
    sbc b
    ld l, $06
    ld bc, $cdff
    sbc e
    dec bc
    ret nz

    call $720e
    ld a, $01
    ld [$ccb4], a
    ret


    ld a, [$c994]
    inc a
    ld [$c994], a
    cp $9f
    ret nz

    call $6c28
    jp $68c1


    call SetMon_69ca
    ld hl, $6f79
    jp z, $68f1

    ld a, [$ccb7]
    or a
    jp z, Jump_003_68ab

    call $6e9d
    xor a
    ld [$ccb7], a
    ld a, $21
    call BankTrampolineTable
    jp $68c1


    ld a, [$c994]
    dec a
    ld [$c994], a
    cp $38
    ret nz

    ld a, $01
    ld [$ccb4], a
    ret


    ld a, [$ccb4]
    rst $00
    ld b, h
    db $76
    bit 6, [hl]
    rst $10
    db $76
    ei
    db $76
    inc e
    ld [hl], a
    ld c, c
    ld [hl], a
    adc $77
    ld c, a
    ld a, b
    ld h, c
    ld a, b
    ld a, b
    ld a, b
    call $23dc
    call TileBuffer_1E96
    ld hl, $1f9f
    call ReadHRAM_d6_2042
    ld hl, $4768
    call $12d8
    ld hl, $47ac
    ld de, $9980
    call JoypadBitReformat

Jump_003_765f:
    xor a
    ld [$c983], a
    ld hl, $cdc2
    ld [hl+], a
    inc a
    ld [hl+], a
    ld a, $14
    ld [hl+], a
    ld a, $20
    ld hl, $cd80
    ld [hl], a
    call SetMon_7a6c
    xor a
    ld hl, $cdc1
    ld [hl], a
    call SetMon_7a8f
    ld d, $c0
    ld bc, $407c
    call $05e2
    xor a
    call ShowTextAndWait
    call LoadMon_7939
    call GameStateBit_0686
    ld d, $cc
    ld c, $06

jr_003_7693:
    call $07c1
    ld a, $5e
    rst $20
    ld a, $81
    call ClearJoypadState
    inc d
    dec c
    jr nz, jr_003_7693

    ld d, $cc
    ld c, $50
    call FuncMon_76bb
    ld c, $90
    call FuncMon_76bb
    xor a
    call SetMon_7aa1
    call $1185
    call GetSpriteAddress
    jp $68c1


FuncMon_76bb:
    ld e, $03
    ld b, $24

jr_003_76bf:
    call $05e2
    ld a, b
    add $30
    ld b, a
    inc d
    dec e
    jr nz, jr_003_76bf

    ret


    call LoadMon_7a9c
    ret nz

    ld a, $58
    call $0510
    jp $68c1


    call FuncMon_78b1
    call LoadMon_794b
    call FuncMon_7984
    call SetMon_7a48
    ld a, [hl]
    or a
    ret nz

    ld a, $55
    call $0510
    call $16a0
    ld a, $e0
    ld [$c00f], a
    ld a, $01
    call SetMon_7aa1
    jp $68c1


    call LoadMon_7a9c
    ld hl, $cd98
    ld a, [hl]
    cp $04
    ret nz

    inc [hl]
    ld a, $10
    call BankTrampolineTable
    ld hl, $cdc1
    ld bc, $9c85
    call CallMon_7a92
    ld a, $03
    call SetMon_7aa1
    jp $68c1


    call LookupDoublePtrTable
    ret nz

    ld a, [$c987]
    and $10
    ret z

    call CrossBankCallRet
    ld hl, $7aa7
    ld a, [$cdc1]

jr_003_772f:
    cp [hl]
    inc hl
    jr nc, jr_003_7736

    inc hl
    jr jr_003_772f

jr_003_7736:
    ld a, [hl]
    ld [$cdc5], a
    ld bc, $5970
    or a
    jr nz, jr_003_7743

    ld bc, $597f

jr_003_7743:
    call $0935
    jp $68c1


    call LookupDoublePtrTable
    ret nz

    call LoadMon_7756
    call LoadMon_784a
    jp $68c1


LoadMon_7756:
    ld a, [$cdc5]
    rst $00
    sub b
    ld [hl], a
    ld h, d
    ld [hl], a
    sub c
    ld [hl], a
    or a
    ld [hl], a
    ld a, [$c9c4]
    add $60
    call CallMon_7a30
    ld b, $01
    ld a, [$cdc1]
    sub $30
    daa

jr_003_7772:
    cp $05
    jr c, jr_003_777d

    sub $05
    daa
    inc b
    daa
    jr jr_003_7772

jr_003_777d:
    ld hl, $ccb9
    ld [hl], b
    ld bc, $9c66
    call SaveMon_7a3e
    ld bc, $9c6d
    ld hl, $c9c3
    call SaveMon_7a3e
    ret


    ld a, $05

jr_003_7793:
    ld hl, $ccb9
    ld [hl], a
    push hl
    ld a, [$c9c4]
    add $35
    call CallMon_7a30
    pop hl
    ld bc, $9c66
    call SaveMon_7a3e
    ld bc, $9c6d
    call $04d0
    jp Jump_003_7a3e


jr_003_77b0:
    ld hl, $cdc5
    dec [hl]
    inc a
    jr jr_003_7793

    ld a, [$c9f0]
    ld hl, $c9c5
    sub [hl]
    jr z, jr_003_77b0

    ld a, $0b
    ld bc, $9c63
    call RunScriptEngine
    ld bc, $9c6a
    jp Jump_000_0d19


    call CallScriptByType
    ret nz

    ld a, [$cdc5]
    rst $00
    sbc $77
    db $e3
    ld [hl], a
    inc bc
    ld a, b
    inc hl
    ld a, b

Jump_003_77de:
jr_003_77de:
    ld a, $60
    jp $68be


    call LoadMon_784a
    call $0be2
    ld bc, $9c6e
    call $0bf3

Jump_003_77ef:
    ld a, [$ccb9]
    dec a
    ld [$ccb9], a
    push af
    ld bc, $9c68
    inc a
    call RunScriptEngine
    pop af
    jp z, Jump_003_77de

    ret


    call $04d0
    cp $99
    jr z, jr_003_77de

    call LoadMon_784a
    ld b, $01
    ld a, [$c9c4]
    call GetScrollPixelPosition
    ld bc, $9c6e
    call PixelToTileCoord
    ld a, $14
    call BankTrampolineTable
    jp Jump_003_77ef


    ld a, [$c9f0]
    ld hl, $c9c5
    cp [hl]
    jp z, Jump_003_6d40

    call LoadMon_784a
    ld a, $15
    call BankTrampolineTable
    ld a, $01
    call AdjustTilemapOffset
    ld bc, $9c6a
    call MultiplyHL_0D19
    ld bc, $9c63
    xor a
    call RunScriptEngine
    jp Jump_003_77de


LoadMon_784a:
    ld a, $20
    jp Jump_000_0ba1


    call CallScriptByType
    ret nz

    call $16a0
    call CrossBankCallRet
    ld a, $02
    call SetMon_7aa1
    jp $68c1


    call LookupDoublePtrTable
    ret nz

    ld hl, $7ab3
    call $091e
    ld bc, $9c90
    call $0c0d
    xor a
    ld [$ccb7], a
    jp $68c1


    call SetMon_69ca
    ld hl, $7aaf
    jp z, $68f1

    ld a, $03
    ld [$cd98], a
    ld a, [$ccb7]
    and a
    jp z, Jump_003_78a8

    ld bc, $9c90
    ld a, [$ccb5]
    call LoadEtoA
    jr c, jr_003_78a2

    call CrossBankCallRet
    xor a
    ld [$ccb4], a
    jp Jump_003_765f


jr_003_78a2:
    call JmpMon_78ae
    jp Jump_003_69ac


Jump_003_78a8:
    call JmpMon_78ae
    jp Jump_003_68ab


JmpMon_78ae:
    jp $3bf0


FuncMon_78b1:
    ld d, $c0
    call DispMon_792b
    ld e, $14
    call BankSwitch_1616
    call nz, CallMon_78d9
    call $161c
    call nz, CallMon_78f4
    ld e, $0f
    call $1622
    call nz, LoadMon_790f
    call TextWriteBank
    call nz, LoadMon_7918
    call CallBank5FEntry1_0541
    call nz, LoadMon_791c
    ret


CallMon_78d9:
    call SaveMon_7941
    ld a, [de]
    cp $70
    ret z

    call SetupTextBankSwitch
    jr nz, jr_003_78eb

    ld bc, $3000
    jp $05ea


jr_003_78eb:
    call SetROMBankHigh
    ld bc, $0800
    jp $05ea


CallMon_78f4:
    call SaveMon_7941
    ld a, [de]
    cp $38
    ret z

    call SetupTextBankSwitch
    jr z, jr_003_7906

    ld bc, $d000
    jp $05ea


jr_003_7906:
    call SetROMBankHigh
    ld bc, $f800
    jp $05ea


LoadMon_790f:
    ld a, $3c

jr_003_7911:
    push af
    call SaveMon_7941
    pop af
    ld [de], a
    ret


LoadMon_7918:
    ld a, $7c
    jr jr_003_7911

LoadMon_791c:
    ld a, [$c018]
    or a
    ret nz

    ld a, $08
    call ShowTextAndWait
    ld hl, $c008
    inc [hl]
    ret


DispMon_792b:
    rst $10
    ret nz

    ld a, [$c008]
    bit 0, a
    jr z, jr_003_7939

    ld a, $08
    call ShowTextAndWait

LoadMon_7939:
jr_003_7939:
    ld a, [$c9c4]
    add a
    add $58
    rst $20
    ret


SaveMon_7941:
    push de
    xor a
    call ShowTextAndWait
    call LoadMon_7939
    pop de
    ret


LoadMon_794b:
    ld a, [$cdc2]
    ld hl, $cdc3
    cp [hl]
    ret z

    call SetViewportParams
    and $07
    cp $06
    ret nc

    add $cc
    ld d, a
    ld e, $02
    ld a, [de]
    or a
    ret nz

    ld hl, $cdc2
    inc [hl]
    call SetViewportParams
    set 7, a
    ld e, $0c
    ld [de], a
    call $0589
    ld a, [$c989]
    and $f0
    ld a, $5e
    jr nz, jr_003_797d

    ld a, $64

jr_003_797d:
    rst $20
    call $05bd
    jp $07d3


FuncMon_7984:
    ld d, $cc

jr_003_7986:
    call SetupTilemapRow
    call DrawMenuRowTilemap
    call FuncMon_7999
    call FuncMon_79f2
    inc d
    ld a, d
    cp $d2
    ret nc

    jr jr_003_7986

FuncMon_7999:
    ld e, $02
    ld a, [de]
    rst $00
    xor c
    ld a, c
    xor d
    ld a, c
    pop bc
    ld a, c
    call z, $e179
    ld a, c
    call z, $c979
    call FuncMon_79ec
    or a
    ret nz

    call StoreScreenPointer
    call SetViewportParams
    and $1f
    ld hl, $cd80
    add [hl]
    call ShowTextAndWait
    jp $07d3


    rst $10
    ret nz

    call $0589
    call $05bd
    jp $07d3


    call FuncMon_79ec
    cp $10
    ret c

    call CallBank56Entry8_0569
    xor a
    ld e, $0e
    ld [de], a
    ld hl, $cdc2
    dec [hl]
    xor a
    jp Jump_000_07dd


    rst $10
    ret nz

    ld bc, $0100
    call CallTextRenderer
    jp $07d3


FuncMon_79ec:
    ld e, $0f
    ld a, [de]
    and $3f
    ret


FuncMon_79f2:
    ld e, $02
    ld a, [de]
    cp $04
    ret nc

    ld hl, $c008
    bit 0, [hl]
    ret z

    ld e, $14
    ld a, [de]
    sub $15
    ld l, e
    sub [hl]
    cp $d7
    ret c

    ld e, $0f
    ld a, [de]
    ld l, e
    sub [hl]
    sub $04
    cp $06
    ret nc

    call StoreScreenPointer
    call FuncMon_7a7b
    ld h, d
    ld l, $08
    inc [hl]
    ld a, $20
    call ShowTextAndWait
    ld a, $04
    jp Jump_000_07dd


FuncMon_7a26:
    ld [$cdc6], a
    ld d, $c2
    ld bc, $2820
    jr jr_003_7a37

CallMon_7a30:
    call FuncMon_7a26
    inc d
    ld bc, $6020

jr_003_7a37:
    ld a, [$cdc6]
    rst $20
    jp Jump_000_068a


SaveMon_7a3e:
Jump_003_7a3e:
    push hl
    ld a, $2e
    call TextHandler_0B59
    pop hl
    jp Jump_000_0cb8


SetMon_7a48:
    ld hl, $c983
    inc [hl]
    ld a, [hl]
    cp $3f
    ret nz

    xor a
    ld [hl], a
    ld hl, $cd80
    ld a, [hl]
    dec a
    daa
    ld [hl], a
    ld a, [$cdc4]
    cp [hl]
    jr nz, jr_003_7a6c

    push hl
    ld hl, $cdc3
    add [hl]
    sub $07
    daa
    inc [hl]
    pop hl
    ld [$cdc4], a

SetMon_7a6c:
jr_003_7a6c:
    ld bc, $9825
    jp Jump_000_0cb8


jr_003_7a72:
    ld a, $2a
    call BankTrampolineTable
    ld a, $01
    jr jr_003_7a89

FuncMon_7a7b:
    ld e, $08
    ld a, [de]
    cp $5e
    jr z, jr_003_7a72

    ld a, $2b
    call BankTrampolineTable
    ld a, $05

jr_003_7a89:
    ld hl, $cdc1
    add [hl]
    daa
    ld [hl], a

SetMon_7a8f:
    ld bc, $982c

CallMon_7a92:
    call PixelToTileCoord
    inc c
    inc c
    ld a, $01
    jp Jump_RunScriptEngine


LoadMon_7a9c:
    ld a, $ff
    jp Jump_000_3b7c


SetMon_7aa1:
    ld hl, $5945
    jp $095a


    jr nc, jr_003_7aaa

    ld [hl+], a

jr_003_7aaa:
    ld [bc], a
    dec d
    inc bc
    nop
    nop
    add c
    sbc h
    add l
    sbc h
    add c
    sbc h
    scf
    jr c, @+$3b

    nop
    nop
    inc hl
    inc h
    nop
    nop
    ld a, [hl+]
    dec hl
    inc l
    dec l
    dec c
    ld l, $ff
    ld hl, $c9a2
    dec [hl]
    jr nz, jr_003_7ad7

    ld hl, $c9a3
    inc [hl]
    call SetMon_7ad7
    ld a, h
    ld [$c9a2], a
    ret


SetMon_7ad7:
jr_003_7ad7:
    ld hl, $7ae6
    ld a, [$c9a3]
    rst $08
    ld a, l
    ld [$c986], a
    ld [$c987], a
    ret


    ld bc, $112b
    ld [hl+], a
    ld bc, $1160
    ld b, $01
    ld hl, $1211
    ld bc, $11af
    add hl, bc
    ld bc, $1156
    rlca
    ld bc, $2149
    ld [$2a01], sp
    ld de, $0019
    rst $38

FuncMon_7b04:
    ld d, $04

jr_003_7b06:
    call SaveMon_7b10
    ld a, $04
    rst $18
    dec d
    jr nz, jr_003_7b06

    ret


SaveMon_7b10:
    push bc
    ld hl, $7b2c
    call SaveMon_7b1f
    ld a, $3e
    rst $18
    call SaveMon_7b1f
    pop bc
    ret


SaveMon_7b1f:
    push bc
    call TextIdDispatch
    pop bc
    inc bc
    inc bc
    push bc
    call TextIdDispatch
    pop bc
    ret


    db $db
    rst $18
    ldh [rP1], a
    rst $18
    call c, $e000
    ldh [rP1], a
    db $dd
    rst $18
    nop
    ldh [$df], a
    sbc $fa
    add c
    ret


    rst $00
    ld b, [hl]
    ld a, e
    ld a, c
    ld a, e
    sub d
    ld a, e
    xor a
    ld [$ddc4], a
    call SubHLFromHRAM_A7
    ld bc, $9a42
    call FuncMon_7b04
    ld bc, $1b6f
    call EnableLCD
    call $15f7

FuncMon_7b5c:
    ld c, $7f

SetMon_7b5e:
    ld hl, $7b75
    ld de, $c014
    ld b, $04

jr_003_7b66:
    ld a, [hl+]
    push hl
    call SetJoypadAction
    ld l, $0f
    ld [hl], c
    pop hl
    ld [de], a
    inc d
    dec b
    jr nz, jr_003_7b66

    ret


    jr nz, @+$42

    ld h, b
    add b
    ld hl, $ddc4
    inc [hl]
    ld a, [hl]
    cp $20
    ret nz

FuncMon_7b81:
    ld d, $c4
    ld bc, $2080
    call $05e2
    call SetJoypadAction
    ld a, $3d
    rst $20
    jp $15f7


    call TextSetBank
    jp nz, $139e

    call TextNewLine
    jp nz, Jump_003_7bf4

    ld a, [$cd80]
    ld d, $c0
    or d
    ld d, a
    ld a, [$c987]
    and $03
    jp nz, Jump_003_7bd2

    ld a, [$c987]
    and $0c
    ret z

    ld a, $15
    call BankTrampolineTable
    ld e, $00
    ld a, [$c987]
    and $0c
    rrca
    rrca
    and $01
    call LoadMon_7be9
    ld a, [de]

SetMon_7bc7:
    ld hl, $7bce
    rst $28
    ld a, [hl]
    rst $20
    ret


    nop
    dec [hl]
    ld [hl], $37

Jump_003_7bd2:
    ld a, $0f
    call BankTrampolineTable
    ld de, $cd80
    call BankSwitch_1616
    call LoadMon_7be9
    ld hl, $7b75
    rst $28
    ld a, [hl]
    ld [$c414], a
    ret


LoadMon_7be9:
    ld a, [de]
    jr z, jr_003_7bf1

    inc a

jr_003_7bed:
    and $03
    ld [de], a
    ret


jr_003_7bf1:
    dec a
    jr jr_003_7bed

Jump_003_7bf4:
    ld de, $c000
    ld b, $00
    ld c, $04

jr_003_7bfb:
    ld a, [de]
    or b
    ld b, a
    inc d
    dec c
    jr z, jr_003_7c08

    sla b
    sla b
    jr jr_003_7bfb

jr_003_7c08:
    ld hl, $7c94
    ld a, b
    ld d, $0d

jr_003_7c0e:
    cp [hl]
    jr z, jr_003_7c27

    inc c
    inc hl
    dec d
    jr nz, jr_003_7c0e

    ld a, [$cd81]
    cp $02
    jp z, $139e

    inc a
    ld [$cd81], a
    ld a, $2c
    jp Jump_000_0515


jr_003_7c27:
    ld a, c
    cp $05
    jp nc, Jump_003_7c59

    cp $03
    jp z, Jump_003_7c86

    cp $04
    jp z, Jump_003_7c8b

    push bc
    call $6254
    call ReadJoypadRaw
    call $0ce9
    call $20b7
    call DigitCheckBorrow
    call DataMon_59d0
    pop bc
    ld a, $0d

jr_003_7c4d:
    call TextWaitInput
    ld a, $50
    ld [$c9f4], a
    ld a, c
    jp Jump_003_6719


Jump_003_7c59:
    sub $05

jr_003_7c5b:
    sra a
    inc a
    push af
    call DataMon_624e
    pop af
    ld [$c9c1], a
    jr nc, jr_003_7c79

    ld a, $02
    ld [$c9c2], a
    ld a, [$c9c1]
    cp $04
    jr c, jr_003_7c79

    ld a, $04
    ld [$c9c2], a

jr_003_7c79:
    ld a, [$c9c2]
    or a
    ld a, $05
    jp nz, Jump_000_15e6

    dec a
    jp Jump_000_15e6


Jump_003_7c86:
    ld a, $10
    jp Jump_000_15e6


Jump_003_7c8b:
    ld a, $01
    ld [$c9a7], a
    ld a, $00
    jr jr_003_7c5b

    ld d, l
    ld d, l
    rst $38
    nop
    ld b, b
    dec de
    ld de, $afcc
    db $fc
    ld d, b
    inc a
    jr nc, jr_003_7c4d

    ld a, h
    xor e
    ld a, h
    or b
    ld a, h
    or h
    ld a, h
    cp b
    ld a, h
    dec de
    dec de
    ld de, $1111
    call z, $afcc
    xor a
    db $fc
    db $fc
    ld d, b
    ld d, b
    inc a
    inc a
    inc a
    inc a
    jr nc, @+$32

    ld a, [$c981]
    push af
    cp $02
    call nc, $7d44
    pop af
    rst $00
    push de
    ld a, h
    rla
    ld a, l
    ld h, a
    ld a, l
    sub e
    ld a, l
    jp $d67d


    ld a, l
    call ReadJoypadRaw
    xor a
    ld [$c988], a
    call SetViewportEnd
    ld de, $0760
    call SubHLFromHRAM_A5
    ld a, $54
    call $0510
    call $1e43
    call GetMonsterStatPtr
    ld hl, $7e06
    call LoadSpriteCoords
    ld hl, $7de4
    call $091e
    ld bc, $99a2
    call FuncMon_7b04
    ld c, $77
    call SetMon_7b5e
    xor a
    ld [$c991], a
    ld bc, $1a00
    call EnableLCD
    call GetSpriteAddress
    jp $15f7


    ld hl, $c991
    ld a, [$c982]
    and $03
    ret nz

    dec [hl]
    ld a, [hl]
    cp $f4
    ret nz

    ld d, $c4
    ld bc, $7d3f
    call $02be
    call JoypadActionDone
    ld bc, $b058
    call $05e2
    ld bc, $ff90
    call CallBank59Entry3_055A
    jp $15f7


    ld [$083e], sp
    ccf
    cp $16
    call nz, CheckPartySize
    ld a, l
    call $0298
    db $cd, $da, $08
    call $059c
    rst $30
    jr z, jr_003_7d5e

    cp $c0
    ret c

    cp $e8
    ret nc

    jp $0638


jr_003_7d5e:
    cp $e8
    ret nc

    cp $b0
    ret c

    jp $0638


    call $150b
    ld hl, $7e06
    call LoadSpriteCoords
    ld a, [$c987]
    and $90
    ret z

    ld a, [$c988]
    and $01
    jp nz, $15f7

    ld hl, $c9c1
    xor a
    rst $08
    push hl
    call DataMon_624e
    pop bc
    ld hl, $c9c1
    ld [hl], c
    inc l
    ld [hl], b
    ld a, $05
    jp Jump_000_15e6


    ld hl, $c993
    inc [hl]
    ld a, [hl]
    cp $90
    ret nz

    ld a, [$c9a7]
    or a
    ld a, $40
    jr nz, jr_003_7da9

    ld hl, $7ca1
    call $04bb

jr_003_7da9:
    ldh [$d8], a
    ld d, $c3

jr_003_7dad:
    ldh a, [$d8]
    and $03
    call SetMon_7bc7
    ldh a, [$d8]
    rrca
    rrca
    ldh [$d8], a
    dec d
    ld a, d
    cp $bf
    jr nz, jr_003_7dad

    jp $15f7


    ld a, [$c987]
    and $ff
    ret z

    ld b, $04
    ld d, $c0

jr_003_7dcd:
    xor a
    rst $20
    inc d
    dec b
    jr nz, jr_003_7dcd

    jp $15f7


    ld hl, $c993
    dec [hl]
    ld a, [hl]
    cp $60
    ret nz

    ld a, $02
    ld [$c981], a
    ret


    push hl
    sbc e
    xor a
    and d
    xor d
    and h
    sub b
    and [hl]
    or [hl]
    and h
    and l
    cp $27
    sbc h
    xor h
    and [hl]
    or e
    xor b
    xor c
    or e
    and a
    and h
    cp $67
    sbc h
    and b
    and d
    or l
    or l
    or a
    and [hl]
    and l
    xor l
    rst $38
    dec h
    sbc h
    ld bc, $65fe
    sbc h
    nop
    rst $38
    dec h
    sbc h
    nop
    cp $65
    sbc h
    ld bc, $21ff
    call nz, CopyBlock_35DD
    ld a, [hl]
    cp $20
    ret nz

    call FuncMon_7b81
    ld a, $0c
    ld hl, $c980
    ld [hl+], a
    ld [hl], $02
    ret


    ld a, [$c981]
    rst $00
    ld h, e
    ld a, [hl]
    ld [hl], d
    ld a, [hl]
    add [hl]
    ld a, [hl]
    ld d, $7e
    dec h
    sbc e
    or l
    and [hl]
    and a
    or e
    xor l
    sub b
    xor b
    and h
    or l
    xor b
    cp $67
    sbc e
    xor e
    xor a
    xor d
    rst $38

LoadMon_7e49:
    ld a, [$cac0]
    ld bc, $9b6a
    and $f0
    swap a
    add $94
    call RunScriptEngine
    inc bc
    ld a, [$cac0]
    and $0f
    add $94
    jp Jump_RunScriptEngine


    call $1670
    ld hl, $7e36
    call $091e
    call LoadMon_7e49
    jp $15f7


    ld hl, $ddc4
    inc [hl]
    ld a, [hl]
    cp $54
    ret nz

    jp $15f7


jr_003_7e7d:
    call $050b
    call FuncMon_7b5c
    jp $15f7


    call TextSetBank
    jr nz, jr_003_7e7d

    ld a, [$c987]
    and $10
    jr z, jr_003_7e9d

    ld hl, $7edc
    ld a, [$cac0]
    rst $28
    ld a, [hl]
    jp $0510


jr_003_7e9d:
    ld a, [$c987]
    and $20
    jp nz, $050b

    call LoadMon_7e49
    ld a, [$c987]
    and $04
    jr z, jr_003_7ec1

    ld a, $0f
    call BankTrampolineTable
    ld a, [$cac0]
    cp $16
    ret z

    add $01
    daa
    ld [$cac0], a
    ret


jr_003_7ec1:
    call LoadMon_7e49
    ld a, [$c987]
    and $08
    ret z

    ld a, $0f
    call BankTrampolineTable
    ld a, [$cac0]
    cp $00
    ret z

    sub $01
    daa
    ld [$cac0], a
    ret


    ld c, [hl]
    ld d, c
    ld e, d
    ld e, l
    ld h, b
    ld h, d
    ld d, d
    ld e, c
    ld e, [hl]
    ld h, c
    ld h, c
    ld h, c
    ld h, c
    ld h, c
    ld h, c
    ld h, c
    ld d, b
    ld e, a
    ld e, e
    ld e, h
    ld d, l
    ld d, [hl]
    ld e, b

SetMon_7ef3:
    ld hl, $cd80
    inc [hl]
    ld a, [hl]
    res 7, a
    ret


CallMon_7efb:
    call SetMon_7ef3
    cp $40
    ret c

    ld hl, $7fb3
    bit 3, a
    jr nz, jr_003_7f0b

    ld hl, $7fbb

SetMon_7f0b:
Jump_003_7f0b:
jr_003_7f0b:
    ld bc, $98c9
    jp Jump_000_0aea


    call CallMon_7efb
    call $3c0d
    ld hl, $7fb7
    jr nz, jr_003_7f1f

    ld hl, $7faf

SetMon_7f1f:
jr_003_7f1f:
    ld bc, $9909
    jp Jump_000_0aea


    ld bc, $982e

jr_003_7f28:
    call $647c
    ret nz

    jp Jump_003_648e


    ld bc, $9820
    jr jr_003_7f28

    ld bc, $9841
    ld e, $11
    call $1cc6
    ld hl, $7fdf
    scf
    call MultiplyHL_091F
    ld a, $06
    jp $6514


    ld a, $5b
    call $0510
    ld hl, $7fb3
    call SetMon_7f0b
    call $15f7
    ld a, $07
    jr jr_003_7f7d

    call $3c0d

jr_003_7f5d:
    ld de, $7fc6
    jr nz, jr_003_7f65

    ld de, $7fc3

jr_003_7f65:
    ld bc, $98af
    ld h, $03
    jp Jump_003_6473


jr_003_7f6d:
    call $3c13
    jr jr_003_7f5d

    ld hl, $7fbf
    call SetMon_7f0b
    call $15f7
    ld a, $08

SetMon_7f7d:
jr_003_7f7d:
    ld hl, $4e58
    jp $095a


    ld a, $10
    call $65b0

LoadMon_7f88:
    ld a, $09
    call SetMon_7f7d
    ld a, $02
    ld hl, $cd83
    ld [hl+], a
    ld [hl], a
    ret


    call LookupDoublePtrTable
    jr nz, jr_003_7f6d

    call LoadMon_7f88
    call CallScriptByType
    jp z, $63fb

    cp $0b
    ret nz

    ld hl, $7fb7
    call SetMon_7f1f
    jp Jump_003_7f0b


    ld d, [hl]
    ld d, a
    ld e, e
    ld e, h
    inc a
    dec a
    ld b, d
    ld b, e
    ld h, [hl]
    ld h, a
    ld l, b
    ld l, c
    ld h, d
    ld h, e
    ld h, h
    ld h, l
    ld e, [hl]
    ld e, a
    ld h, b
    ld h, c
    dec hl
    inc l
    dec l
    cpl
    jr nc, jr_003_7ffa

    rst $08
    sbc b
    ld a, d
    ld a, e
    ld a, h
    ld a, l
    rst $38
    ret nz

    sbc b
    ld l, d
    ld l, e
    ld l, h
    ld l, l
    cp $e1
    sbc b
    ld l, [hl]
    ld l, a
    ld [hl], b
    ld [hl], c
    ld [hl], d
    rst $38
    and c
    sbc b
    nop
    dec e
    ld e, $00
    cp $c0
    sbc b
    ld c, [hl]
    ld [hl], e
    ld [hl], h
    ld [hl], l
    db $76
    cp $e1
    sbc b
    nop
    ld [hl], a
    ld a, b
    ld a, c
    ld c, c
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38

jr_003_7ffa:
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    inc bc
