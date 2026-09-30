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
;
; $DA33 = byte 0 = FAMILY (0=Slime..9=Boss/???). Family-byte READER TRACE (S18,
; for B6): every consumer outside breeding uses it for DISPLAY or copies it into
; the party/battle struct (+$0A) — none gate scout/recruit/AI/resistance on it:
;   bank $01 (~$2667) battle: copies family into the battle struct
;   bank $04 (~$4162) FamilyTextPtrTable: per-family text dispatch (display)
;   bank $07 (~$1383/$1421) farm/scout sprite + icon (display)
;   bank $09 (~$6603) builds a VRAM tile/sprite index (display)
;   bank $14 (~$0316) recruit: stamps fresh family into struct +$0A at creation
; Scout/recruit eligibility is the enemy-stats joinability byte ($14 +$3) + boss
; table ($14:$4897), independent of this byte. So a monster can be moved between
; ANY families (incl. in/out of ??? / Boss=9) by a same-size family-byte edit.
; The library tab grouping is the ONE exception — it groups by id-range, not this
; byte (see SetItem_6242 in bank $12 + BREEDING_SYSTEM "Dynamic library").
; ===========================================================================
; N2 — Info-table FORK (Phase N: add new species ids >= 224).
; Zero-shift, byte-perfect: this whole block occupies exactly the vanilla
; 34 bytes ($443f..$4460), so MonsterInfoTable stays at $4461 and nothing
; downstream shifts. For species id < 224 the behaviour is byte-for-byte the
; vanilla copy from MonsterInfoTable ($4461 + id*43). For id >= 224 (first
; free slot, $E0) it far-calls bank $6A entry 0 (NewSpeciesInfoCopy), which
; copies the 43-byte entry from the free-bank high info-table into $DA33.
; DE ($DA33) is preserved across the dispatch (rst $10 leaves DE alone; the
; vanilla Mul8x8To16 also preserves DE, so the old push/pop is unnecessary
; and frees the bytes the compare needs).  Sole caller: entry 1 ($4001+2)
; via `dw label443f`; SaveMon_4446 had no external callers.
;   Authored by tools/build_new_species.py (extracted/new_species.json).
; ===========================================================================
label443f:
    ld de, $da33             ; dest = WRAM $DA33 (byte 0 = family); preserved below
    ld a, [wTempSpeciesId]   ; $DA31 = species ID
    cp $e0                   ; >= 224 ($E0)? -> new-species high table
    jr nc, NewSpeciesInfoHigh
SaveMon_4446:                ; vanilla low path (ids 0..220), behaviourally identical
    ld c, $2b                ; 43 = entry size
    call Mul8x8To16          ; HL = species_id * 43
    ld bc, MonsterInfoTable  ; + base ($4461); BC is free after the multiply
    add hl, bc
    ld b, $2b                ; copy 43 bytes
jr_003_445a:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, jr_003_445a
    ret
NewSpeciesInfoHigh:
    ld hl, $6a00             ; bank $6A, entry 0 (NewSpeciesInfoCopy)
    rst $10                  ; far-call: copies high-table entry -> $DA33
    ret
    nop                      ; pad: keep MonsterInfoTable pinned at $4461


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

; @BUILD_PROJECT BEGIN gd_monster_info
; (generated by editor2 `gd_monsters` from gamedata.monsters — vanilla
;  rows + project overrides; 43 B: family, cap, exp curve, female ratio,
;  fly, metal, 3 skills, 6 growth curves, 27 resistances, tier)
MonsterInfoTable:
MonsterInfo_000_DrakSlime:  ; DrakSlime — Slime
    db $00, $2D, $0D, $02, $00, $00, $43, $5C, $D5, $10, $0A, $0D, $08, $14, $10
    db $01, $01, $01, $00, $00, $00, $02, $02, $02, $02, $02, $02, $02, $02, $03, $02, $02, $01, $00, $01, $00, $00, $00, $00, $00, $00, $00, $04
MonsterInfo_001_SpotSlime:  ; SpotSlime — Slime
    db $00, $23, $0A, $02, $00, $00, $52, $79, $7F, $11, $01, $11, $04, $11, $08
    db $00, $00, $00, $00, $00, $00, $02, $02, $02, $02, $02, $02, $03, $03, $02, $02, $00, $00, $00, $00, $00, $01, $01, $01, $01, $01, $00, $04
MonsterInfo_002_WingSlime:  ; WingSlime — Slime
    db $00, $23, $0A, $02, $01, $00, $55, $58, $8A, $0D, $02, $0B, $0B, $18, $08
    db $00, $00, $00, $01, $01, $00, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $00, $00, $00, $00, $00, $01, $01, $01, $01, $01, $00, $04
MonsterInfo_003_TreeSlime:  ; TreeSlime — Slime
    db $00, $32, $0B, $02, $00, $00, $1C, $69, $6A, $0D, $0B, $08, $0E, $11, $11
    db $00, $00, $00, $01, $01, $00, $02, $02, $02, $03, $03, $02, $02, $02, $02, $02, $00, $00, $00, $00, $00, $01, $01, $01, $00, $00, $00, $04
MonsterInfo_004_Snaily:  ; Snaily — Slime
    db $00, $1E, $08, $02, $00, $00, $0C, $34, $52, $0B, $0A, $11, $14, $14, $08
    db $00, $00, $00, $00, $00, $00, $02, $03, $02, $02, $03, $02, $02, $02, $02, $02, $00, $00, $01, $01, $01, $00, $00, $00, $01, $01, $00, $03
MonsterInfo_005_SlimeNite:  ; SlimeNite — Slime
    db $00, $28, $0F, $02, $00, $00, $1E, $2B, $4A, $0E, $01, $0F, $0E, $14, $0E
    db $01, $01, $01, $01, $01, $01, $02, $02, $03, $02, $02, $02, $02, $02, $03, $02, $01, $00, $00, $01, $00, $00, $00, $00, $00, $00, $00, $04
MonsterInfo_006_Babble:  ; Babble — Slime
    db $00, $2D, $0C, $02, $00, $00, $18, $67, $74, $11, $07, $11, $08, $0E, $0D
    db $00, $00, $00, $00, $00, $00, $03, $03, $03, $02, $02, $03, $02, $02, $02, $02, $00, $00, $03, $01, $01, $00, $00, $00, $00, $00, $00, $04
MonsterInfo_007_BoxSlime:  ; BoxSlime — Slime
    db $00, $32, $0B, $02, $00, $00, $00, $1E, $3C, $0B, $0A, $0E, $13, $0E, $0D
    db $00, $00, $01, $00, $00, $01, $02, $02, $03, $02, $02, $02, $02, $02, $03, $02, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $03
MonsterInfo_008_Slime:  ; Slime — Slime
    db $00, $28, $10, $02, $00, $00, $03, $66, $73, $16, $0B, $0E, $11, $0B, $0D
    db $00, $00, $00, $00, $00, $00, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
MonsterInfo_009_Healer:  ; Healer — Slime
    db $00, $32, $0B, $02, $00, $00, $1E, $2B, $2E, $0B, $0F, $0B, $0B, $14, $12
    db $00, $00, $00, $01, $01, $00, $02, $02, $02, $03, $03, $02, $02, $02, $02, $02, $00, $00, $00, $00, $00, $01, $02, $02, $00, $00, $00, $03
MonsterInfo_010_FangSlime:  ; FangSlime — Slime
    db $00, $23, $0A, $02, $00, $00, $41, $52, $7D, $19, $01, $12, $0D, $14, $0D
    db $00, $00, $00, $00, $00, $00, $02, $02, $03, $02, $02, $02, $03, $03, $03, $02, $00, $00, $00, $01, $00, $01, $01, $01, $01, $01, $00, $05
MonsterInfo_011_RockSlime:  ; RockSlime — Slime
    db $00, $32, $0B, $02, $00, $00, $42, $5B, $8E, $0D, $0A, $0E, $17, $10, $0E
    db $00, $00, $01, $00, $00, $02, $02, $02, $03, $02, $02, $02, $02, $02, $03, $02, $00, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $05
MonsterInfo_012_SlimeBorg:  ; SlimeBorg — Slime
    db $00, $32, $0B, $02, $00, $00, $57, $5A, $90, $12, $0B, $14, $0F, $0E, $0D
    db $01, $01, $00, $01, $02, $01, $02, $02, $03, $02, $02, $03, $02, $02, $03, $02, $01, $01, $00, $01, $00, $00, $00, $00, $00, $00, $00, $05
MonsterInfo_013_Slabbit:  ; Slabbit — Slime
    db $00, $23, $0A, $02, $00, $00, $77, $7B, $7E, $0F, $07, $0E, $08, $15, $0F
    db $00, $00, $00, $00, $00, $00, $02, $02, $02, $02, $02, $02, $03, $03, $02, $02, $00, $00, $00, $00, $00, $02, $01, $01, $02, $01, $00, $04
MonsterInfo_014_SpotKing:  ; SpotKing — Slime
    db $00, $28, $09, $02, $00, $00, $4E, $68, $92, $12, $0B, $12, $0B, $14, $0F
    db $01, $01, $01, $00, $00, $01, $03, $02, $03, $02, $02, $03, $03, $03, $03, $02, $01, $01, $00, $01, $00, $02, $02, $02, $02, $02, $00, $05
MonsterInfo_015_KingSlime:  ; KingSlime — Slime
    db $00, $28, $0C, $02, $00, $00, $24, $2B, $30, $12, $0E, $0F, $0E, $14, $0F
    db $01, $01, $01, $01, $01, $01, $03, $02, $03, $02, $02, $03, $03, $03, $03, $02, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $05
MonsterInfo_016_Metaly:  ; Metaly — Slime
    db $00, $14, $19, $02, $00, $01, $00, $0C, $12, $00, $1E, $0B, $1E, $1F, $0D
    db $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $01, $03, $03, $03, $03, $03, $00, $00, $00, $03, $00, $00, $06
MonsterInfo_017_Metabble:  ; Metabble — Slime
    db $00, $28, $1B, $02, $00, $01, $03, $06, $14, $00, $1E, $0E, $1F, $1F, $0F
    db $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $02, $03, $03, $03, $03, $03, $00, $00, $00, $03, $00, $00, $06
MonsterInfo_018_MetalKing:  ; MetalKing — Slime
    db $00, $3C, $1D, $02, $00, $01, $0F, $2A, $64, $00, $1F, $0F, $1F, $1F, $12
    db $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $02, $03, $03, $03, $03, $03, $00, $00, $00, $03, $01, $00, $06
MonsterInfo_019_GoldSlime:  ; GoldSlime — Slime
    db $00, $50, $1F, $02, $00, $00, $39, $65, $81, $00, $1F, $13, $1F, $1F, $12
    db $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $02, $03, $03, $03, $03, $03, $01, $01, $01, $03, $02, $00, $06
MonsterInfo_020_DragonKid:  ; DragonKid — Dragon
    db $01, $19, $07, $02, $00, $00, $5C, $6A, $8C, $0A, $03, $11, $02, $05, $05
    db $01, $02, $02, $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01, $03, $01, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $04
MonsterInfo_021_Tortragon:  ; Tortragon — Dragon
    db $01, $23, $11, $02, $00, $00, $27, $2A, $5A, $0F, $0B, $12, $06, $07, $0D
    db $02, $02, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $02, $00, $02, $01, $00, $00, $00, $01, $01, $01, $01, $01, $00, $04
MonsterInfo_022_Pteranod:  ; Pteranod — Dragon
    db $01, $23, $10, $02, $01, $00, $03, $58, $8A, $0E, $0B, $12, $02, $14, $04
    db $02, $02, $02, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, $00, $02, $00, $00, $00, $00, $01, $01, $01, $01, $01, $00, $03
MonsterInfo_023_Gasgon:  ; Gasgon — Dragon
    db $01, $32, $12, $02, $01, $00, $14, $32, $3D, $11, $0F, $0D, $0B, $07, $12
    db $02, $02, $02, $01, $01, $00, $00, $00, $00, $01, $01, $00, $00, $00, $02, $00, $02, $00, $00, $00, $00, $01, $01, $01, $00, $00, $00, $04
MonsterInfo_024_FairyDrak:  ; FairyDrak — Dragon
    db $01, $1E, $0F, $02, $01, $00, $18, $6A, $79, $09, $0D, $11, $10, $0E, $04
    db $02, $02, $02, $00, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $02, $00, $02, $00, $01, $01, $01, $00, $00, $00, $01, $01, $00, $03
MonsterInfo_025_LizardMan:  ; LizardMan — Dragon
    db $01, $28, $14, $02, $00, $00, $40, $4A, $D9, $11, $0A, $13, $0D, $05, $10
    db $02, $02, $02, $01, $01, $00, $00, $00, $01, $00, $00, $00, $00, $00, $03, $00, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $04
MonsterInfo_026_Poisongon:  ; Poisongon — Dragon
    db $01, $2D, $13, $02, $00, $00, $67, $6C, $79, $15, $10, $0F, $0D, $07, $01
    db $02, $02, $02, $00, $00, $00, $01, $01, $01, $00, $00, $01, $00, $00, $02, $00, $02, $00, $02, $01, $01, $00, $00, $00, $00, $00, $00, $03
MonsterInfo_027_Swordgon:  ; Swordgon — Dragon
    db $01, $32, $14, $02, $00, $00, $4E, $57, $90, $09, $03, $17, $06, $01, $05
    db $02, $02, $03, $00, $00, $01, $00, $00, $01, $00, $00, $00, $00, $00, $03, $00, $02, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $04
MonsterInfo_028_Dragon:  ; Dragon — Dragon
    db $01, $28, $14, $02, $00, $00, $44, $5C, $8F, $11, $01, $14, $10, $07, $04
    db $02, $02, $02, $00, $00, $00, $00, $02, $00, $00, $00, $01, $00, $00, $02, $00, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $03
MonsterInfo_029_MiniDrak:  ; MiniDrak — Dragon
    db $01, $23, $10, $02, $00, $00, $3C, $52, $72, $0E, $08, $11, $0E, $12, $0A
    db $02, $02, $02, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, $00, $02, $00, $00, $00, $00, $02, $01, $02, $01, $01, $00, $03
MonsterInfo_030_MadDragon:  ; MadDragon — Dragon
    db $01, $23, $13, $02, $00, $00, $3F, $40, $78, $13, $00, $15, $05, $08, $00
    db $02, $02, $02, $00, $00, $00, $00, $01, $00, $00, $00, $00, $01, $01, $02, $00, $02, $00, $00, $00, $00, $02, $02, $01, $02, $02, $00, $05
MonsterInfo_031_Rayburn:  ; Rayburn — Dragon
    db $01, $23, $11, $02, $01, $00, $46, $4C, $67, $0E, $02, $11, $10, $0F, $05
    db $02, $02, $02, $02, $02, $00, $00, $02, $00, $00, $00, $01, $00, $00, $02, $00, $02, $01, $00, $00, $00, $00, $02, $01, $02, $01, $00, $04
MonsterInfo_032_Chamelgon:  ; Chamelgon — Dragon
    db $01, $32, $13, $02, $00, $00, $19, $69, $6B, $11, $12, $0B, $06, $08, $0D
    db $01, $02, $02, $00, $00, $00, $00, $00, $02, $01, $00, $03, $00, $00, $03, $00, $03, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $04
MonsterInfo_033_LizardFly:  ; LizardFly — Dragon
    db $01, $1E, $10, $02, $01, $00, $03, $58, $5C, $0B, $0B, $11, $11, $0D, $05
    db $01, $02, $02, $00, $00, $00, $00, $01, $00, $00, $00, $01, $00, $00, $02, $00, $03, $00, $01, $01, $01, $00, $00, $00, $01, $01, $00, $03
MonsterInfo_034_Andreal:  ; Andreal — Dragon
    db $01, $32, $16, $02, $00, $00, $09, $18, $6C, $15, $0F, $13, $11, $13, $0C
    db $02, $02, $02, $00, $00, $00, $00, $02, $02, $02, $00, $02, $00, $00, $02, $00, $02, $02, $00, $00, $00, $01, $01, $01, $00, $00, $00, $05
MonsterInfo_035_KingCobra:  ; KingCobra — Dragon
    db $01, $28, $14, $02, $00, $00, $67, $6F, $71, $12, $08, $10, $0D, $13, $0B
    db $01, $02, $02, $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01, $03, $01, $02, $00, $02, $00, $02, $00, $00, $00, $00, $00, $00, $04
MonsterInfo_036_Spikerous:  ; Spikerous — Dragon
    db $01, $1E, $13, $02, $00, $00, $3D, $3E, $5B, $14, $08, $13, $18, $01, $02
    db $02, $02, $02, $00, $00, $00, $00, $01, $01, $00, $00, $01, $00, $00, $03, $00, $02, $00, $01, $01, $01, $00, $00, $00, $01, $01, $00, $05
MonsterInfo_037_GreatDrak:  ; GreatDrak — Dragon
    db $01, $3C, $17, $02, $00, $00, $47, $60, $8F, $15, $05, $17, $0E, $10, $0B
    db $02, $03, $02, $01, $01, $01, $01, $02, $03, $01, $01, $02, $01, $01, $03, $00, $03, $01, $01, $03, $01, $01, $01, $01, $01, $01, $00, $06
MonsterInfo_038_Crestpent:  ; Crestpent — Dragon
    db $01, $23, $12, $02, $00, $00, $17, $67, $D5, $0E, $04, $0F, $05, $13, $08
    db $02, $02, $02, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, $00, $02, $00, $00, $00, $00, $02, $02, $01, $01, $01, $00, $03
MonsterInfo_039_WingSnake:  ; WingSnake — Dragon
    db $01, $2D, $14, $01, $00, $00, $42, $55, $6C, $0F, $08, $14, $11, $0E, $0B
    db $03, $03, $02, $01, $01, $00, $00, $00, $02, $00, $01, $00, $00, $00, $03, $00, $03, $00, $00, $00, $00, $02, $02, $01, $01, $01, $00, $04
MonsterInfo_040_Coatol:  ; Coatol — Dragon
    db $01, $3C, $17, $02, $00, $00, $06, $40, $45, $19, $0E, $14, $16, $12, $0E
    db $02, $02, $02, $01, $01, $01, $01, $02, $02, $01, $01, $01, $01, $01, $03, $01, $03, $01, $01, $01, $01, $02, $02, $01, $01, $01, $00, $06
MonsterInfo_041_Orochi:  ; Orochi — Dragon
    db $01, $3C, $16, $02, $00, $00, $44, $50, $5C, $18, $0D, $18, $15, $0B, $08
    db $02, $02, $02, $01, $01, $01, $02, $02, $02, $01, $01, $03, $01, $01, $03, $00, $03, $01, $02, $02, $02, $01, $01, $01, $01, $01, $00, $06
MonsterInfo_042_BattleRex:  ; BattleRex — Dragon
    db $01, $3C, $16, $02, $00, $00, $40, $48, $5C, $17, $10, $1A, $14, $11, $10
    db $02, $02, $02, $02, $02, $01, $01, $02, $02, $01, $01, $01, $01, $01, $03, $00, $03, $01, $01, $02, $01, $01, $01, $01, $01, $01, $00, $06
MonsterInfo_043_SkyDragon:  ; SkyDragon — Dragon
    db $01, $23, $12, $03, $01, $00, $43, $4F, $5C, $0F, $0B, $14, $0E, $12, $08
    db $01, $02, $02, $02, $02, $01, $01, $02, $02, $01, $01, $01, $01, $01, $03, $00, $03, $01, $01, $02, $01, $02, $02, $02, $02, $02, $00, $05
MonsterInfo_044_Divinegon:  ; Divinegon — Dragon
    db $01, $50, $1C, $03, $01, $00, $60, $65, $93, $1A, $19, $1C, $18, $14, $17
    db $02, $03, $03, $02, $02, $02, $02, $02, $03, $02, $02, $03, $02, $02, $03, $01, $03, $02, $02, $03, $02, $02, $02, $02, $02, $02, $00, $06
MonsterInfo_045_Tonguella:  ; Tonguella — Beast
    db $02, $28, $0C, $02, $00, $00, $68, $6A, $79, $0E, $05, $0F, $0C, $0B, $10
    db $00, $00, $00, $00, $00, $00, $01, $01, $01, $01, $01, $01, $03, $03, $01, $01, $00, $00, $00, $00, $00, $02, $02, $02, $02, $02, $00, $03
MonsterInfo_046_Almiraj:  ; Almiraj — Beast
    db $02, $2D, $0D, $02, $00, $00, $15, $3D, $41, $12, $05, $0E, $09, $0F, $04
    db $01, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, $02, $01, $00, $01, $00, $00, $00, $00, $02, $02, $02, $02, $02, $00, $03
MonsterInfo_047_CatFly:  ; CatFly — Beast
    db $02, $23, $0A, $02, $01, $00, $17, $20, $75, $0B, $0A, $0D, $08, $12, $0E
    db $00, $00, $00, $01, $01, $00, $00, $00, $00, $00, $00, $00, $02, $02, $00, $00, $00, $00, $00, $00, $00, $03, $03, $03, $03, $03, $00, $03
MonsterInfo_048_PillowRat:  ; PillowRat — Beast
    db $02, $32, $0B, $02, $00, $00, $3C, $52, $77, $0E, $11, $08, $08, $13, $0D
    db $00, $00, $00, $01, $01, $00, $00, $00, $00, $01, $01, $00, $02, $02, $00, $00, $00, $00, $00, $00, $00, $03, $03, $03, $02, $02, $00, $03
MonsterInfo_049_Saccer:  ; Saccer — Beast
    db $02, $28, $09, $02, $00, $00, $1E, $56, $6B, $10, $05, $09, $11, $00, $0D
    db $00, $00, $00, $00, $00, $00, $00, $01, $00, $00, $00, $01, $02, $02, $00, $00, $00, $00, $01, $01, $01, $02, $02, $02, $03, $03, $00, $03
MonsterInfo_050_GulpBeast:  ; GulpBeast — Beast
    db $02, $2D, $0D, $02, $00, $00, $3C, $3F, $7D, $18, $01, $1A, $0D, $07, $01
    db $01, $01, $01, $01, $01, $01, $00, $00, $01, $00, $00, $00, $02, $02, $01, $00, $00, $00, $00, $00, $00, $02, $02, $02, $02, $02, $00, $04
MonsterInfo_051_Skullroo:  ; Skullroo — Beast
    db $02, $2D, $0C, $02, $00, $00, $41, $49, $6E, $0E, $0A, $0B, $08, $10, $02
    db $00, $00, $00, $00, $00, $00, $01, $01, $01, $00, $00, $01, $02, $02, $01, $00, $00, $00, $01, $01, $01, $02, $02, $02, $02, $02, $00, $03
MonsterInfo_052_WindBeast:  ; WindBeast — Beast
    db $02, $32, $0C, $02, $00, $00, $09, $0C, $46, $0D, $14, $0D, $0F, $0F, $0D
    db $00, $00, $00, $02, $00, $01, $00, $00, $01, $00, $00, $00, $02, $02, $01, $00, $00, $01, $00, $00, $00, $02, $02, $02, $02, $02, $00, $03
MonsterInfo_053_Anteater:  ; Anteater — Beast
    db $02, $28, $08, $02, $00, $00, $48, $55, $79, $0E, $07, $11, $0B, $09, $0B
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, $02, $00, $00, $00, $00, $00, $00, $00, $02, $02, $02, $02, $02, $00, $00
MonsterInfo_054_SuperTen:  ; SuperTen — Beast
    db $02, $2D, $09, $02, $00, $00, $71, $7F, $94, $12, $07, $0D, $0C, $0B, $07
    db $00, $00, $00, $00, $00, $00, $01, $02, $01, $00, $00, $02, $02, $02, $00, $00, $00, $00, $01, $01, $01, $02, $02, $02, $02, $02, $00, $05
MonsterInfo_055_IronTurt:  ; IronTurt — Beast
    db $02, $2D, $0A, $02, $00, $00, $27, $88, $8E, $12, $05, $11, $17, $02, $0B
    db $01, $01, $01, $00, $00, $01, $00, $00, $00, $00, $00, $00, $02, $02, $01, $00, $02, $02, $00, $00, $00, $02, $02, $02, $02, $02, $00, $04
MonsterInfo_056_Mommonja:  ; Mommonja — Beast
    db $02, $23, $0B, $02, $00, $00, $0C, $78, $92, $0E, $0B, $10, $0E, $14, $08
    db $00, $00, $00, $01, $01, $00, $00, $00, $01, $00, $00, $01, $02, $02, $00, $00, $00, $00, $00, $00, $00, $03, $03, $03, $03, $03, $00, $04
MonsterInfo_057_HammerMan:  ; HammerMan — Beast
    db $02, $32, $0B, $02, $00, $00, $3E, $40, $41, $11, $13, $11, $0B, $11, $0A
    db $00, $00, $00, $01, $01, $00, $00, $00, $00, $02, $02, $00, $02, $02, $00, $00, $00, $00, $00, $00, $00, $03, $03, $03, $02, $02, $00, $04
MonsterInfo_058_Grizzly:  ; Grizzly — Beast
    db $02, $28, $0E, $02, $00, $00, $3B, $55, $7B, $14, $00, $1B, $07, $09, $01
    db $01, $01, $01, $01, $01, $01, $00, $00, $01, $00, $00, $00, $02, $02, $01, $00, $00, $00, $00, $00, $00, $03, $02, $02, $03, $02, $00, $05
MonsterInfo_059_Yeti:  ; Yeti — Beast
    db $02, $28, $0D, $02, $00, $00, $0C, $47, $7D, $12, $0B, $0F, $09, $0A, $08
    db $01, $01, $01, $01, $01, $02, $00, $00, $01, $00, $00, $00, $02, $02, $01, $00, $00, $03, $00, $00, $00, $02, $02, $02, $02, $02, $00, $05
MonsterInfo_060_MadGopher:  ; MadGopher — Beast
    db $02, $32, $0C, $02, $00, $00, $41, $4B, $4D, $0E, $0D, $11, $09, $08, $0B
    db $01, $01, $00, $00, $00, $01, $00, $00, $02, $00, $00, $00, $02, $02, $02, $00, $01, $01, $00, $00, $00, $02, $02, $02, $02, $02, $00, $04
MonsterInfo_061_FairyRat:  ; FairyRat — Beast
    db $02, $2D, $0B, $02, $01, $00, $18, $20, $D6, $0C, $05, $0D, $0E, $11, $07
    db $01, $01, $01, $00, $00, $01, $00, $01, $00, $00, $00, $01, $02, $02, $01, $00, $01, $01, $00, $00, $00, $02, $02, $02, $02, $02, $00, $03
MonsterInfo_062_Unicorn:  ; Unicorn — Beast
    db $02, $32, $0E, $02, $00, $00, $2B, $30, $33, $13, $15, $0E, $0D, $0C, $19
    db $00, $00, $00, $00, $00, $00, $01, $02, $02, $01, $01, $02, $03, $03, $01, $01, $00, $02, $00, $01, $01, $03, $02, $02, $03, $02, $00, $06
MonsterInfo_063_Goategon:  ; Goategon — Beast
    db $02, $28, $0B, $02, $00, $00, $03, $20, $6A, $13, $09, $11, $0D, $11, $03
    db $00, $01, $01, $00, $00, $02, $01, $01, $01, $01, $01, $01, $03, $03, $01, $01, $01, $02, $00, $00, $00, $02, $02, $02, $02, $02, $00, $04
MonsterInfo_064_WildApe:  ; WildApe — Beast
    db $02, $23, $0D, $02, $00, $00, $3B, $52, $7B, $0D, $01, $14, $0A, $08, $04
    db $00, $00, $00, $01, $01, $00, $00, $00, $01, $00, $00, $00, $02, $02, $01, $00, $00, $00, $00, $00, $00, $03, $03, $03, $03, $03, $00, $05
MonsterInfo_065_Trumpeter:  ; Trumpeter — Beast
    db $02, $32, $0E, $02, $00, $00, $3D, $72, $7D, $11, $08, $15, $11, $0E, $0D
    db $00, $01, $01, $01, $01, $01, $00, $00, $02, $00, $00, $01, $02, $03, $01, $00, $00, $01, $00, $00, $00, $03, $03, $03, $03, $03, $00, $06
MonsterInfo_066_KingLeo:  ; KingLeo — Beast
    db $02, $46, $0F, $02, $00, $00, $03, $50, $60, $14, $0E, $18, $17, $11, $0E
    db $01, $01, $01, $02, $02, $01, $01, $01, $03, $01, $01, $02, $03, $03, $03, $01, $01, $02, $01, $02, $01, $03, $03, $03, $03, $03, $00, $06
MonsterInfo_067_DarkHorn:  ; DarkHorn — Beast
    db $02, $32, $0D, $02, $00, $00, $15, $17, $56, $11, $04, $13, $12, $0A, $0C
    db $01, $01, $00, $00, $00, $01, $01, $02, $03, $01, $03, $01, $03, $03, $03, $01, $01, $01, $00, $02, $01, $03, $03, $03, $03, $03, $00, $06
MonsterInfo_068_MadCat:  ; MadCat — Beast
    db $02, $28, $0C, $02, $00, $00, $46, $55, $7B, $0F, $07, $12, $0E, $11, $0B
    db $01, $01, $01, $00, $00, $01, $00, $01, $03, $00, $00, $00, $02, $02, $03, $00, $01, $01, $00, $01, $00, $03, $02, $02, $02, $02, $00, $06
MonsterInfo_069_BigEye:  ; BigEye — Beast
    db $02, $28, $0B, $02, $00, $00, $0C, $2B, $60, $0E, $08, $0E, $0B, $07, $09
    db $01, $01, $01, $01, $01, $01, $00, $01, $03, $00, $02, $00, $02, $02, $03, $00, $00, $00, $00, $01, $00, $02, $02, $02, $02, $02, $00, $05
MonsterInfo_070_Picky:  ; Picky — Bird
    db $03, $28, $04, $02, $00, $00, $18, $1C, $D7, $0B, $0C, $0E, $08, $12, $0D
    db $00, $00, $00, $02, $02, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $00, $00, $00, $00, $02, $02, $02, $02, $02, $00, $03
MonsterInfo_071_Wyvern:  ; Wyvern — Bird
    db $03, $2D, $06, $02, $01, $00, $15, $2B, $60, $11, $0D, $13, $0B, $10, $14
    db $01, $01, $01, $02, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00, $01, $00, $00, $00, $00, $02, $02, $02, $02, $02, $00, $04
MonsterInfo_072_BullBird:  ; BullBird — Bird
    db $03, $23, $05, $02, $00, $00, $3C, $41, $D8, $0E, $08, $11, $09, $06, $04
    db $00, $00, $00, $02, $02, $00, $00, $00, $00, $00, $00, $00, $01, $01, $00, $00, $00, $00, $00, $00, $00, $03, $03, $03, $03, $03, $00, $04
MonsterInfo_073_Florajay:  ; Florajay — Bird
    db $03, $32, $05, $02, $01, $00, $22, $4A, $95, $06, $12, $0C, $03, $15, $13
    db $00, $00, $00, $03, $03, $00, $00, $00, $00, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $03, $03, $03, $02, $02, $00, $03
MonsterInfo_074_DuckKite:  ; DuckKite — Bird
    db $03, $1E, $03, $02, $01, $00, $15, $19, $6F, $0B, $0B, $09, $0C, $12, $07
    db $00, $00, $00, $02, $02, $00, $00, $01, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $01, $01, $01, $02, $02, $02, $03, $03, $00, $03
MonsterInfo_075_MadPecker:  ; MadPecker — Bird
    db $03, $28, $04, $02, $00, $00, $09, $1C, $46, $09, $07, $14, $0E, $17, $0D
    db $01, $01, $01, $03, $03, $01, $00, $00, $01, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $02, $02, $02, $02, $02, $00, $04
MonsterInfo_076_MadRaven:  ; MadRaven — Bird
    db $03, $2D, $05, $02, $01, $00, $42, $49, $8A, $06, $0E, $11, $0C, $12, $05
    db $00, $00, $00, $02, $02, $00, $01, $01, $01, $00, $00, $01, $00, $00, $00, $00, $00, $00, $01, $01, $01, $02, $02, $02, $02, $02, $00, $03
MonsterInfo_077_MistyWing:  ; MistyWing — Bird
    db $03, $32, $05, $02, $01, $00, $18, $24, $74, $0C, $11, $08, $0F, $16, $0D
    db $00, $00, $00, $02, $02, $01, $00, $00, $01, $00, $00, $00, $00, $00, $01, $00, $00, $01, $00, $00, $00, $02, $02, $02, $02, $02, $00, $03
MonsterInfo_078_Dracky:  ; Dracky — Spirit  ; EDITED (project gamedata)
    db $0A, $28, $02, $02, $01, $00, $15, $1A, $33, $0B, $04, $08, $0D, $11, $0B
    db $00, $00, $00, $02, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, $02, $02, $02, $02, $00, $00
MonsterInfo_079_BigRoost:  ; BigRoost — Bird
    db $03, $28, $03, $02, $01, $00, $46, $72, $8C, $08, $05, $0E, $0C, $11, $08
    db $00, $00, $00, $02, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, $02, $02, $02, $02, $00, $03
MonsterInfo_080_StubBird:  ; StubBird — Bird
    db $03, $28, $06, $02, $00, $00, $25, $57, $D7, $10, $0C, $14, $14, $0E, $0B
    db $00, $00, $00, $02, $02, $02, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $02, $00, $00, $00, $02, $02, $02, $02, $02, $00, $04
MonsterInfo_081_LandOwl:  ; LandOwl — Bird
    db $03, $23, $07, $02, $00, $00, $09, $45, $77, $0F, $0A, $15, $0D, $0B, $12
    db $00, $00, $00, $02, $02, $00, $00, $01, $01, $00, $00, $01, $02, $02, $01, $00, $00, $00, $00, $00, $00, $03, $03, $03, $03, $03, $00, $05
MonsterInfo_082_MadGoose:  ; MadGoose — Bird
    db $03, $1E, $05, $02, $01, $00, $19, $75, $78, $11, $06, $11, $0F, $14, $08
    db $00, $00, $00, $02, $02, $00, $00, $02, $01, $00, $00, $02, $00, $00, $00, $00, $00, $00, $02, $01, $01, $02, $02, $02, $03, $03, $00, $04
MonsterInfo_083_MadCondor:  ; MadCondor — Bird
    db $03, $32, $06, $02, $01, $00, $03, $2E, $4F, $0E, $0B, $12, $0C, $11, $0D
    db $01, $01, $00, $02, $02, $01, $00, $00, $02, $00, $01, $01, $00, $00, $02, $00, $01, $02, $00, $00, $00, $02, $02, $02, $02, $02, $00, $05
MonsterInfo_084_Blizzardy:  ; Blizzardy — Bird
    db $03, $32, $07, $03, $01, $00, $12, $47, $60, $14, $07, $0B, $11, $13, $0B
    db $01, $01, $00, $02, $02, $03, $00, $00, $02, $00, $00, $01, $00, $00, $01, $00, $01, $03, $00, $01, $00, $02, $02, $02, $02, $02, $00, $05
MonsterInfo_085_Phoenix:  ; Phoenix — Bird
    db $03, $32, $07, $01, $01, $00, $55, $5C, $8A, $10, $0D, $13, $08, $13, $0C
    db $02, $02, $02, $01, $01, $00, $00, $00, $00, $01, $01, $01, $00, $00, $00, $00, $03, $00, $00, $01, $00, $03, $03, $03, $02, $02, $00, $05
MonsterInfo_086_ZapBird:  ; ZapBird — Bird
    db $03, $32, $07, $02, $01, $00, $45, $5A, $64, $14, $07, $13, $11, $16, $0C
    db $01, $01, $01, $03, $03, $01, $00, $00, $01, $02, $00, $02, $00, $00, $01, $00, $01, $01, $00, $01, $00, $02, $02, $02, $02, $02, $00, $05
MonsterInfo_087_WhipBird:  ; WhipBird — Bird
    db $03, $3C, $0F, $02, $01, $00, $2A, $83, $84, $1B, $13, $0C, $14, $17, $17
    db $01, $01, $01, $02, $02, $01, $01, $01, $02, $00, $00, $01, $00, $00, $02, $00, $01, $01, $00, $02, $00, $02, $02, $02, $02, $02, $00, $06
MonsterInfo_088_FunkyBird:  ; FunkyBird — Bird
    db $03, $32, $05, $02, $00, $00, $6E, $94, $96, $0E, $14, $08, $09, $10, $14
    db $00, $00, $00, $03, $03, $00, $01, $00, $02, $01, $01, $01, $00, $00, $03, $00, $00, $00, $00, $02, $00, $03, $03, $03, $02, $02, $00, $06
MonsterInfo_089_RainHawk:  ; RainHawk — Bird
    db $03, $46, $18, $01, $00, $00, $66, $81, $8E, $19, $1B, $0F, $18, $12, $18
    db $02, $02, $02, $03, $02, $02, $01, $01, $02, $01, $01, $03, $01, $01, $03, $01, $02, $03, $01, $02, $01, $03, $03, $03, $03, $03, $00, $06
MonsterInfo_090_MadPlant:  ; MadPlant — Plant
    db $04, $28, $0A, $02, $00, $00, $1C, $20, $34, $0F, $18, $0B, $0D, $06, $12
    db $00, $00, $00, $02, $02, $00, $01, $01, $01, $03, $03, $01, $01, $01, $01, $01, $00, $00, $00, $00, $00, $02, $02, $02, $00, $00, $00, $04
MonsterInfo_091_FireWeed:  ; FireWeed — Plant
    db $04, $2D, $0F, $02, $00, $00, $00, $35, $6B, $0E, $1A, $0A, $0C, $05, $11
    db $01, $01, $01, $02, $02, $00, $00, $00, $00, $02, $02, $00, $00, $00, $01, $00, $02, $00, $00, $00, $00, $02, $02, $02, $00, $00, $00, $04
MonsterInfo_092_FloraMan:  ; FloraMan — Plant
    db $04, $23, $07, $02, $00, $00, $03, $33, $36, $11, $14, $06, $09, $02, $13
    db $00, $00, $00, $02, $02, $00, $00, $00, $00, $02, $02, $00, $01, $01, $00, $00, $00, $00, $00, $00, $00, $03, $03, $03, $02, $02, $00, $04
MonsterInfo_093_WingTree:  ; WingTree — Plant
    db $04, $23, $07, $02, $01, $00, $32, $37, $4D, $0C, $14, $06, $0B, $0E, $07
    db $00, $00, $00, $03, $03, $00, $00, $00, $00, $02, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $03, $03, $03, $02, $02, $00, $04
MonsterInfo_094_CactiBall:  ; CactiBall — Plant
    db $04, $1E, $06, $02, $00, $00, $42, $69, $75, $12, $12, $0C, $0F, $09, $05
    db $00, $00, $00, $02, $02, $00, $00, $01, $00, $02, $02, $01, $00, $00, $00, $00, $00, $00, $01, $01, $01, $02, $02, $02, $01, $01, $00, $04
MonsterInfo_095_Gulpple:  ; Gulpple — Plant
    db $04, $28, $0B, $02, $00, $00, $09, $15, $68, $10, $11, $09, $06, $02, $0E
    db $01, $01, $01, $02, $02, $01, $00, $00, $01, $02, $02, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $02, $02, $02, $00, $00, $00, $04
MonsterInfo_096_Toadstool:  ; Toadstool — Plant
    db $04, $2D, $09, $02, $00, $00, $68, $6A, $92, $0E, $12, $08, $09, $0D, $0D
    db $00, $00, $00, $02, $02, $00, $01, $01, $01, $02, $02, $01, $00, $00, $01, $00, $00, $00, $01, $01, $01, $02, $02, $02, $00, $00, $00, $03
MonsterInfo_097_AmberWeed:  ; AmberWeed — Plant
    db $04, $32, $0C, $02, $00, $00, $24, $25, $26, $0C, $18, $08, $11, $0C, $0A
    db $00, $00, $00, $02, $02, $01, $00, $00, $01, $02, $02, $00, $00, $00, $01, $00, $00, $01, $00, $00, $00, $02, $02, $02, $00, $00, $00, $04
MonsterInfo_098_Stubsuck:  ; Stubsuck — Plant
    db $04, $28, $08, $02, $00, $00, $15, $37, $4D, $11, $0B, $04, $02, $09, $0E
    db $00, $00, $00, $02, $02, $00, $00, $00, $00, $02, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, $02, $02, $00, $00, $00, $03
MonsterInfo_099_Oniono:  ; Oniono — Plant
    db $04, $23, $09, $02, $00, $00, $1A, $41, $6A, $0D, $14, $0E, $0B, $03, $10
    db $00, $00, $00, $02, $02, $00, $00, $01, $00, $02, $02, $01, $00, $00, $00, $00, $00, $00, $01, $01, $01, $02, $02, $02, $01, $01, $00, $04
MonsterInfo_100_DanceVegi:  ; DanceVegi — Plant
    db $04, $32, $0C, $02, $00, $00, $71, $77, $78, $0B, $15, $07, $06, $14, $0B
    db $01, $01, $00, $02, $02, $01, $00, $00, $02, $03, $02, $00, $00, $00, $01, $00, $01, $01, $00, $00, $00, $02, $03, $03, $00, $00, $00, $05
MonsterInfo_101_TreeBoy:  ; TreeBoy — Plant
    db $04, $28, $0B, $02, $00, $00, $0C, $2B, $36, $0F, $12, $08, $03, $0C, $0F
    db $01, $01, $01, $03, $03, $01, $00, $01, $02, $02, $02, $01, $00, $00, $02, $00, $00, $00, $00, $00, $00, $02, $02, $02, $00, $00, $00, $04
MonsterInfo_102_FaceTree:  ; FaceTree — Plant
    db $04, $2D, $09, $02, $00, $00, $17, $6F, $75, $0C, $14, $0B, $08, $0A, $11
    db $00, $00, $00, $02, $02, $00, $01, $02, $02, $02, $02, $01, $00, $00, $03, $00, $00, $00, $01, $02, $02, $02, $02, $02, $00, $00, $00, $06
MonsterInfo_103_HerbMan:  ; HerbMan — Plant
    db $04, $28, $0D, $02, $00, $00, $54, $6F, $91, $13, $11, $07, $0A, $0F, $17
    db $00, $00, $00, $03, $03, $00, $00, $00, $02, $02, $02, $00, $00, $00, $03, $00, $00, $00, $00, $02, $00, $03, $03, $03, $01, $01, $00, $06
MonsterInfo_104_BeanMan:  ; BeanMan — Plant
    db $04, $23, $0A, $02, $00, $00, $1A, $25, $38, $0E, $0F, $0C, $0E, $0F, $09
    db $00, $00, $00, $02, $02, $00, $00, $00, $01, $02, $02, $00, $01, $01, $01, $00, $00, $00, $00, $00, $00, $03, $03, $03, $02, $02, $00, $04
MonsterInfo_105_EvilSeed:  ; EvilSeed — Plant
    db $04, $1E, $06, $02, $00, $00, $4E, $69, $73, $08, $0B, $08, $05, $01, $03
    db $01, $01, $01, $03, $03, $01, $00, $00, $01, $02, $02, $01, $00, $00, $02, $00, $00, $00, $00, $00, $00, $02, $02, $02, $00, $00, $00, $03
MonsterInfo_106_ManEater:  ; ManEater — Plant
    db $04, $32, $09, $02, $00, $00, $49, $56, $6A, $0E, $0C, $13, $07, $0A, $06
    db $01, $01, $01, $02, $02, $01, $00, $00, $01, $03, $03, $01, $00, $00, $02, $00, $00, $00, $00, $00, $00, $03, $03, $03, $00, $00, $00, $05
MonsterInfo_107_Snapper:  ; Snapper — Plant
    db $04, $3C, $0B, $02, $00, $00, $17, $52, $57, $11, $0E, $14, $0D, $0A, $10
    db $01, $01, $01, $02, $02, $01, $00, $00, $02, $03, $03, $01, $00, $00, $03, $00, $00, $00, $00, $00, $00, $03, $03, $03, $00, $00, $00, $06
MonsterInfo_108_Rosevine:  ; Rosevine — Plant
    db $04, $50, $18, $03, $00, $00, $50, $82, $90, $18, $1E, $17, $15, $12, $12
    db $01, $01, $01, $03, $03, $01, $01, $01, $02, $03, $03, $01, $01, $01, $03, $01, $01, $01, $01, $02, $01, $03, $03, $03, $01, $01, $00, $06
MonsterInfo_109_Watabou:  ; Watabou — Plant
    db $04, $50, $00, $02, $00, $00, $39, $7E, $7F, $0A, $1B, $0B, $0E, $18, $1E
    db $02, $02, $02, $03, $03, $03, $01, $03, $03, $03, $03, $03, $01, $01, $03, $01, $02, $03, $03, $03, $03, $03, $03, $03, $01, $01, $00, $06
MonsterInfo_110_GiantSlug:  ; GiantSlug — Bug
    db $05, $23, $02, $02, $00, $00, $79, $7E, $8C, $0B, $08, $0E, $09, $0B, $07
    db $00, $00, $00, $00, $00, $00, $01, $03, $01, $01, $01, $03, $01, $01, $01, $01, $00, $00, $02, $02, $02, $00, $00, $00, $02, $02, $00, $04
MonsterInfo_111_Catapila:  ; Catapila — Bug
    db $05, $28, $04, $02, $00, $00, $1E, $6C, $83, $0D, $05, $0B, $0E, $0B, $09
    db $01, $01, $01, $00, $00, $01, $00, $02, $00, $00, $00, $02, $00, $00, $01, $00, $01, $01, $02, $02, $02, $00, $00, $00, $02, $02, $00, $03
MonsterInfo_112_Gophecada:  ; Gophecada — Bug
    db $05, $1E, $01, $02, $00, $00, $12, $27, $52, $06, $0B, $0E, $12, $08, $07
    db $00, $00, $00, $00, $00, $00, $00, $02, $00, $00, $00, $02, $01, $01, $00, $00, $00, $00, $02, $02, $02, $02, $02, $02, $03, $03, $00, $05
MonsterInfo_113_Butterfly:  ; Butterfly — Bug
    db $05, $1E, $00, $02, $01, $00, $18, $52, $6F, $0B, $02, $0D, $07, $0C, $08
    db $00, $00, $00, $01, $01, $00, $00, $02, $00, $00, $00, $02, $00, $00, $00, $00, $00, $00, $02, $02, $02, $01, $01, $01, $03, $03, $00, $04
MonsterInfo_114_WeedBug:  ; WeedBug — Bug
    db $05, $2D, $04, $02, $00, $00, $1A, $24, $26, $11, $0D, $0A, $0C, $05, $13
    db $00, $00, $00, $01, $01, $00, $00, $02, $00, $01, $01, $02, $00, $00, $00, $00, $00, $00, $02, $02, $02, $01, $01, $01, $02, $02, $00, $04
MonsterInfo_115_GiantWorm:  ; GiantWorm — Bug
    db $05, $23, $06, $02, $00, $00, $37, $4A, $75, $0D, $08, $10, $08, $0D, $0E
    db $01, $01, $01, $01, $01, $01, $00, $02, $01, $00, $00, $02, $00, $00, $01, $00, $00, $00, $02, $02, $02, $00, $00, $00, $02, $02, $00, $04
MonsterInfo_116_Lipsy:  ; Lipsy — Bug
    db $05, $28, $04, $02, $00, $00, $68, $70, $79, $0C, $08, $09, $09, $04, $01
    db $00, $00, $00, $00, $00, $00, $01, $03, $01, $00, $00, $03, $00, $00, $01, $00, $00, $00, $03, $03, $03, $00, $00, $00, $02, $02, $00, $03
MonsterInfo_117_StagBug:  ; StagBug — Bug
    db $05, $2D, $03, $02, $00, $00, $15, $5C, $7B, $0D, $07, $10, $14, $09, $07
    db $01, $01, $00, $00, $00, $01, $00, $02, $01, $00, $00, $02, $00, $00, $01, $00, $01, $01, $02, $02, $02, $00, $00, $00, $02, $02, $00, $05
MonsterInfo_118_ArmyAnt:  ; ArmyAnt — Bug
    db $05, $23, $02, $02, $00, $00, $3E, $52, $68, $08, $04, $0B, $11, $0D, $01
    db $00, $00, $00, $00, $00, $00, $00, $02, $00, $00, $00, $02, $00, $00, $00, $00, $00, $00, $02, $02, $02, $00, $00, $00, $02, $02, $00, $03
MonsterInfo_119_GoHopper:  ; GoHopper — Bug
    db $05, $23, $00, $02, $00, $00, $1A, $41, $52, $0B, $04, $08, $0E, $0E, $04
    db $00, $00, $00, $00, $00, $00, $00, $02, $00, $00, $00, $02, $00, $00, $00, $00, $00, $00, $02, $02, $02, $00, $00, $00, $02, $02, $00, $04
MonsterInfo_120_TailEater:  ; TailEater — Bug
    db $05, $2D, $05, $02, $00, $00, $47, $6C, $73, $0C, $0A, $10, $0B, $0E, $05
    db $00, $00, $00, $01, $01, $00, $00, $02, $00, $01, $01, $02, $00, $00, $00, $00, $00, $00, $02, $02, $02, $01, $02, $02, $02, $02, $00, $04
MonsterInfo_121_ArmorPede:  ; ArmorPede — Bug
    db $05, $1E, $06, $02, $00, $00, $1E, $25, $3B, $0F, $0A, $11, $14, $0B, $02
    db $01, $01, $01, $01, $01, $01, $00, $02, $00, $00, $00, $02, $00, $00, $00, $00, $01, $01, $02, $02, $02, $01, $01, $01, $03, $03, $00, $04
MonsterInfo_122_Eyeder:  ; Eyeder — Bug
    db $05, $2D, $04, $02, $01, $00, $03, $2B, $38, $09, $0B, $06, $03, $0A, $09
    db $00, $00, $00, $01, $01, $00, $00, $02, $01, $01, $01, $02, $00, $00, $01, $00, $00, $00, $02, $02, $02, $01, $01, $01, $02, $02, $00, $04
MonsterInfo_123_GiantMoth:  ; GiantMoth — Bug
    db $05, $1E, $02, $02, $01, $00, $58, $69, $73, $0E, $09, $10, $0C, $14, $0C
    db $00, $00, $00, $00, $00, $00, $00, $03, $01, $00, $00, $02, $01, $01, $01, $00, $00, $00, $03, $02, $02, $01, $01, $01, $03, $03, $00, $05
MonsterInfo_124_Droll:  ; Droll — Bug
    db $05, $28, $05, $02, $00, $00, $20, $37, $D8, $11, $0A, $0F, $10, $07, $0E
    db $00, $00, $00, $00, $00, $00, $01, $03, $01, $01, $00, $03, $00, $00, $01, $00, $00, $00, $03, $03, $03, $01, $01, $01, $02, $02, $00, $04
MonsterInfo_125_ArmyCrab:  ; ArmyCrab — Bug
    db $05, $28, $06, $02, $00, $00, $1E, $48, $52, $10, $08, $0E, $13, $05, $01
    db $00, $00, $00, $00, $00, $00, $01, $03, $01, $00, $00, $03, $00, $00, $00, $00, $00, $00, $03, $03, $03, $00, $00, $00, $03, $03, $00, $05
MonsterInfo_126_MadHornet:  ; MadHornet — Bug
    db $05, $28, $07, $02, $01, $00, $67, $69, $8A, $14, $05, $13, $0D, $14, $04
    db $01, $01, $01, $00, $00, $01, $00, $02, $00, $00, $00, $02, $01, $01, $00, $00, $01, $01, $02, $02, $02, $01, $01, $01, $03, $03, $00, $05
MonsterInfo_127_HornBeet:  ; HornBeet — Bug
    db $05, $32, $07, $02, $00, $00, $45, $4C, $5B, $15, $13, $17, $14, $0C, $0E, $02, $02, $02, $00, $00, $02, $00, $02, $01, $00, $00
DataMon_59d0:  ; (referenced from elsewhere in the bank)
    db $02, $00, $00, $01, $00, $02, $02, $02, $03, $02, $00, $00, $00, $02, $02, $00, $06
MonsterInfo_128_Armorpion:  ; Armorpion — Bug
    db $05, $3C, $18, $02, $00, $00, $40, $4D, $57, $16, $14, $18, $17, $0F, $12
    db $02, $02, $02, $01, $01, $02, $01, $03, $02, $01, $01, $03, $01, $01, $03, $01, $02, $02, $03, $03, $03, $01, $01, $01, $03, $03, $00, $06
MonsterInfo_129_Digster:  ; Digster — Bug
    db $05, $32, $0B, $02, $00, $00, $32, $8E, $8F, $18, $0A, $13, $1A, $01, $0F
    db $01, $01, $01, $00, $00, $01, $01, $02, $02, $00, $00, $02, $00, $00, $03, $00, $01, $01, $02, $02, $02, $00, $00, $00, $02, $02, $00, $06
MonsterInfo_130_Pixy:  ; Pixy — Devil
    db $06, $28, $13, $02, $00, $00, $22, $25, $33, $0B, $07, $0F, $08, $0F, $04
    db $02, $02, $01, $01, $01, $02, $01, $01, $03, $02, $02, $02, $01, $01, $03, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $04
MonsterInfo_131_ArcDemon:  ; ArcDemon — Devil
    db $06, $2D, $14, $02, $00, $00, $06, $45, $4B, $0E, $0D, $11, $0C, $07, $15
    db $02, $03, $02, $02, $02, $02, $00, $00, $03, $00, $01, $00, $00, $00, $03, $00, $01, $00, $00, $02, $01, $00, $00, $00, $00, $01, $00, $04
MonsterInfo_132_AgDevil:  ; AgDevil — Devil
    db $06, $23, $10, $02, $00, $00, $03, $14, $6A, $10, $0B, $12, $0C, $10, $13
    db $01, $01, $02, $02, $02, $02, $00, $00, $02, $00, $00, $00, $01, $01, $02, $00, $00, $00, $00, $00, $00, $02, $01, $01, $02, $01, $00, $04
MonsterInfo_133_Demonite:  ; Demonite — Devil
    db $06, $19, $0D, $02, $00, $00, $00, $44, $60, $0D, $01, $05, $04, $09, $14
    db $01, $01, $01, $03, $03, $02, $00, $00, $02, $00, $00, $00, $00, $00, $02, $00, $00, $00, $00, $00, $00, $01, $02, $02, $02, $01, $00, $04
MonsterInfo_134_DarkEye:  ; DarkEye — Devil
    db $06, $32, $12, $02, $01, $00, $48, $6B, $73, $0B, $12, $0A, $10, $09, $0C
    db $02, $02, $01, $03, $03, $01, $00, $00, $02, $01, $01, $00, $00, $00, $02, $00, $00, $00, $00, $00, $00, $02, $02, $01, $00, $00, $00, $03
MonsterInfo_135_EyeBall:  ; EyeBall — Devil
    db $06, $23, $10, $02, $00, $00, $27, $2A, $7D, $10, $11, $0E, $0E, $0D, $08
    db $02, $02, $02, $02, $02, $02, $00, $01, $02, $00, $00, $01, $00, $00, $02, $00, $00, $00, $01, $01, $01, $00, $00, $00, $01, $01, $00, $04
MonsterInfo_136_SkulRider:  ; SkulRider — Devil
    db $06, $2D, $12, $02, $00, $00, $44, $57, $7B, $11, $0B, $11, $0D, $0F, $0C
    db $02, $02, $02, $01, $01, $02, $01, $01, $03, $00, $00, $01, $00, $00, $03, $00, $00, $00, $02, $02, $01, $00, $00, $00, $00, $00, $00, $04
MonsterInfo_137_EvilBeast:  ; EvilBeast — Devil
    db $06, $32, $14, $02, $00, $00, $03, $2A, $60, $10, $0A, $14, $16, $04, $0C
    db $02, $02, $01, $02, $02, $03, $00, $00, $03, $01, $01, $01, $00, $00, $03, $00, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $04
MonsterInfo_138_1EyeClown:  ; 1EyeClown — Devil
    db $06, $19, $0D, $02, $01, $00, $00, $03, $0C, $0A, $01, $05, $09, $09, $11
    db $01, $01, $01, $02, $02, $02, $00, $00, $03, $00, $01, $00, $00, $00, $03, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $04
MonsterInfo_139_Gremlin:  ; Gremlin — Devil
    db $06, $19, $0D, $02, $01, $00, $03, $17, $2B, $0D, $07, $08, $04, $02, $12
    db $02, $02, $02, $01, $01, $01, $00, $00, $03, $00, $00, $01, $00, $00, $03, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $04
MonsterInfo_140_MedusaEye:  ; MedusaEye — Devil
    db $06, $23, $13, $02, $01, $00, $18, $1C, $D8, $0B, $0D, $0E, $0F, $08, $0B
    db $02, $02, $02, $01, $01, $01, $00, $01, $02, $00, $00, $01, $00, $00, $02, $00, $00, $00, $02, $02, $02, $01, $01, $00, $01, $01, $00, $04
MonsterInfo_141_Lionex:  ; Lionex — Devil
    db $06, $2D, $15, $02, $00, $00, $09, $2E, $46, $0F, $0B, $0E, $0F, $0C, $13
    db $03, $03, $02, $02, $02, $02, $00, $00, $03, $01, $01, $01, $00, $00, $03, $00, $02, $02, $00, $00, $02, $00, $00, $00, $00, $00, $00, $05
MonsterInfo_142_GoatHorn:  ; GoatHorn — Devil
    db $06, $23, $16, $02, $00, $00, $06, $09, $0C, $14, $0B, $11, $0D, $0B, $14
    db $02, $02, $02, $02, $02, $02, $00, $00, $03, $00, $01, $01, $02, $02, $03, $00, $00, $00, $00, $00, $00, $02, $02, $02, $02, $02, $00, $05
MonsterInfo_143_Orc:  ; Orc — Devil
    db $06, $32, $11, $02, $00, $00, $1C, $30, $4B, $13, $07, $13, $0D, $0D, $12
    db $01, $01, $01, $03, $03, $02, $00, $00, $02, $01, $01, $00, $01, $01, $02, $00, $00, $00, $00, $00, $00, $02, $02, $02, $00, $00, $00, $04
MonsterInfo_144_Ogre:  ; Ogre — Devil
    db $06, $23, $13, $02, $00, $00, $3F, $48, $57, $0F, $08, $14, $0C, $0A, $0C
    db $01, $01, $02, $02, $02, $02, $00, $00, $02, $00, $00, $00, $01, $01, $02, $00, $00, $00, $00, $00, $00, $02, $02, $02, $02, $01, $00, $05
MonsterInfo_145_GateGuard:  ; GateGuard — Devil
    db $06, $32, $17, $02, $00, $00, $00, $4E, $83, $12, $0C, $12, $0E, $0A, $0E
    db $02, $02, $02, $03, $03, $02, $01, $01, $03, $00, $00, $00, $00, $00, $03, $00, $00, $00, $00, $00, $00, $01, $02, $02, $02, $01, $00, $05
MonsterInfo_146_ChopClown:  ; ChopClown — Devil
    db $06, $32, $16, $02, $00, $00, $25, $46, $55, $11, $0C, $14, $0B, $14, $0F
    db $02, $02, $02, $02, $02, $03, $01, $00, $03, $01, $01, $00, $01, $01, $03, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $05
MonsterInfo_147_Grendal:  ; Grendal — Devil
    db $06, $3C, $14, $02, $00, $00, $44, $49, $88, $17, $01, $12, $18, $0C, $0C
    db $02, $02, $02, $02, $02, $01, $01, $01, $03, $01, $01, $01, $01, $01, $03, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $06
MonsterInfo_148_Akubar:  ; Akubar — Devil
    db $06, $50, $1E, $02, $00, $00, $06, $54, $60, $18, $1E, $17, $15, $12, $15
    db $02, $02, $03, $02, $02, $02, $01, $02, $03, $01, $03, $02, $01, $01, $03, $00, $02, $01, $00, $02, $00, $01, $00, $00, $00, $00, $00, $06
MonsterInfo_149_MadKnight:  ; MadKnight — Devil
    db $06, $32, $17, $02, $00, $00, $3F, $4A, $D9, $11, $09, $12, $14, $0A, $0C
    db $02, $02, $01, $01, $01, $02, $01, $01, $03, $00, $01, $01, $01, $01, $03, $00, $01, $01, $00, $02, $00, $01, $00, $00, $00, $00, $00, $05
MonsterInfo_150_Gigantes:  ; Gigantes — Devil
    db $06, $23, $16, $02, $00, $00, $40, $41, $4D, $1B, $00, $1B, $07, $00, $00
    db $01, $01, $01, $01, $01, $01, $00, $01, $03, $00, $00, $00, $02, $02, $03, $00, $00, $00, $00, $02, $00, $02, $01, $01, $01, $01, $00, $05
MonsterInfo_151_Centasaur:  ; Centasaur — Devil
    db $06, $2D, $17, $02, $00, $00, $17, $44, $57, $14, $01, $18, $15, $12, $13
    db $03, $03, $02, $01, $01, $02, $00, $00, $02, $00, $01, $01, $01, $01, $03, $00, $01, $01, $00, $02, $00, $01, $00, $00, $00, $00, $00, $06
MonsterInfo_152_EvilArmor:  ; EvilArmor — Devil
    db $06, $1E, $16, $02, $00, $00, $44, $45, $49, $10, $01, $11, $1D, $05, $0D
    db $02, $02, $02, $02, $02, $01, $00, $01, $03, $00, $00, $01, $00, $00, $02, $00, $00, $00, $01, $02, $01, $01, $00, $00, $01, $01, $00, $06
MonsterInfo_153_Jamirus:  ; Jamirus — Devil
    db $06, $3C, $15, $02, $00, $00, $00, $50, $8A, $18, $09, $15, $18, $17, $12
    db $02, $02, $02, $03, $03, $01, $01, $01, $03, $01, $01, $01, $01, $01, $03, $00, $00, $00, $00, $02, $00, $01, $01, $01, $01, $01, $00, $06
MonsterInfo_154_Durran:  ; Durran — Devil
    db $06, $46, $1C, $02, $00, $00, $49, $4B, $58, $19, $18, $17, $0F, $11, $14
    db $02, $02, $03, $02, $01, $03, $02, $02, $03, $01, $02, $02, $01, $01, $03, $01, $01, $01, $03, $03, $02, $01, $00, $00, $00, $00, $00, $06
MonsterInfo_155_Spooky:  ; Spooky — Zombie
    db $07, $28, $0B, $02, $01, $00, $73, $79, $92, $0B, $0C, $0D, $08, $12, $0F
    db $00, $00, $00, $00, $00, $00, $03, $03, $03, $01, $01, $03, $01, $01, $03, $01, $00, $00, $02, $02, $02, $00, $00, $00, $00, $00, $00, $03
MonsterInfo_156_Skullgon:  ; Skullgon — Zombie
    db $07, $2D, $0D, $02, $00, $00, $3B, $47, $60, $06, $01, $17, $0F, $04, $06
    db $01, $01, $01, $00, $00, $02, $02, $02, $02, $00, $00, $02, $00, $00, $03, $00, $00, $02, $02, $02, $02, $00, $00, $00, $00, $00, $00, $04
MonsterInfo_157_Putrepup:  ; Putrepup — Zombie
    db $07, $23, $06, $02, $00, $00, $1C, $20, $27, $11, $0D, $11, $08, $0B, $04
    db $00, $00, $00, $00, $00, $00, $02, $02, $02, $00, $00, $02, $01, $01, $02, $00, $00, $00, $02, $02, $02, $01, $01, $01, $01, $01, $00, $04
MonsterInfo_158_RotRaven:  ; RotRaven — Zombie
    db $07, $23, $05, $02, $00, $00, $3E, $45, $5A, $0E, $08, $0C, $0B, $12, $09
    db $00, $00, $00, $01, $01, $00, $02, $02, $02, $00, $00, $02, $00, $00, $02, $00, $00, $00, $02, $02, $02, $01, $01, $01, $01, $01, $00, $04
MonsterInfo_159_Mummy:  ; Mummy — Zombie
    db $07, $32, $0A, $02, $00, $00, $40, $52, $69, $0F, $11, $0C, $09, $04, $08
    db $00, $00, $00, $01, $01, $00, $02, $02, $02, $01, $01, $02, $00, $00, $02, $00, $00, $00, $02, $02, $02, $01, $01, $01, $00, $00, $00, $04
MonsterInfo_160_DarkCrab:  ; DarkCrab — Zombie
    db $07, $1E, $08, $02, $00, $00, $26, $2A, $37, $0C, $08, $0F, $14, $01, $0B
    db $00, $00, $00, $00, $00, $00, $02, $03, $02, $00, $00, $03, $00, $00, $02, $00, $00, $00, $03, $03, $03, $00, $00, $00, $01, $01, $00, $04
MonsterInfo_161_DeadNite:  ; DeadNite — Zombie
    db $07, $2D, $0D, $02, $00, $00, $2B, $35, $36, $11, $07, $13, $09, $0C, $08
    db $01, $01, $01, $01, $01, $01, $02, $02, $03, $00, $00, $02, $00, $00, $03, $00, $00, $00, $02, $02, $02, $00, $00, $00, $00, $00, $00, $04
MonsterInfo_162_Shadow:  ; Shadow — Zombie
    db $07, $32, $0C, $02, $01, $00, $60, $71, $83, $09, $06, $06, $14, $08, $0C
    db $00, $00, $00, $00, $00, $01, $02, $02, $03, $00, $00, $02, $00, $00, $03, $00, $00, $01, $02, $02, $02, $00, $00, $00, $00, $00, $00, $03
MonsterInfo_163_Hork:  ; Hork — Zombie
    db $07, $28, $08, $02, $00, $00, $6C, $74, $79, $11, $0D, $10, $08, $0B, $0A
    db $00, $00, $00, $00, $00, $00, $02, $02, $02, $00, $00, $02, $00, $00, $02, $00, $00, $00, $02, $02, $02, $00, $00, $00, $00, $00, $00, $03
MonsterInfo_164_Mudron:  ; Mudron — Zombie
    db $07, $1E, $0A, $02, $00, $00, $12, $2B, $30, $06, $0A, $0B, $11, $07, $0E
    db $00, $00, $00, $00, $00, $00, $02, $03, $02, $00, $00, $03, $01, $01, $02, $00, $00, $00, $03, $03, $03, $00, $00, $00, $01, $01, $00, $03
MonsterInfo_165_NiteWhip:  ; NiteWhip — Zombie
    db $07, $23, $0C, $02, $01, $00, $58, $5A, $5C, $11, $04, $0A, $03, $0F, $09
    db $00, $00, $00, $02, $01, $01, $02, $02, $02, $00, $00, $02, $00, $00, $02, $00, $00, $00, $02, $02, $02, $01, $01, $01, $01, $01, $00, $03
MonsterInfo_166_MadSpirit:  ; MadSpirit — Zombie
    db $07, $32, $0D, $02, $01, $00, $6A, $73, $83, $0E, $0C, $0F, $0C, $10, $0A
    db $00, $00, $00, $01, $01, $01, $02, $02, $03, $01, $01, $03, $00, $00, $03, $00, $00, $00, $02, $02, $02, $01, $01, $01, $00, $00, $00, $04
MonsterInfo_167_WindMerge:  ; WindMerge — Zombie
    db $07, $23, $09, $02, $01, $00, $09, $24, $36, $10, $13, $13, $0C, $0D, $06
    db $00, $00, $00, $03, $01, $00, $02, $02, $02, $00, $00, $02, $01, $01, $02, $00, $00, $00, $02, $02, $02, $01, $01, $01, $01, $01, $00, $03
MonsterInfo_168_Reaper:  ; Reaper — Zombie
    db $07, $32, $0A, $02, $01, $00, $4C, $6F, $74, $13, $03, $15, $11, $13, $06
    db $00, $00, $00, $01, $01, $00, $02, $03, $02, $01, $01, $03, $00, $00, $02, $00, $00, $01, $03, $03, $03, $01, $01, $00, $01, $01, $00, $03
MonsterInfo_169_DeadNoble:  ; DeadNoble — Zombie
    db $07, $32, $10, $02, $00, $00, $12, $2E, $84, $15, $02, $1A, $13, $0F, $0D
    db $01, $01, $01, $02, $01, $02, $02, $02, $03, $01, $01, $02, $00, $00, $03, $00, $00, $02, $02, $03, $02, $01, $00, $00, $00, $00, $00, $06
MonsterInfo_170_WhiteKing:  ; WhiteKing — Zombie
    db $07, $46, $19, $02, $00, $00, $09, $0F, $39, $14, $18, $0E, $14, $0F, $1B
    db $01, $01, $02, $03, $01, $03, $02, $02, $03, $01, $01, $03, $01, $01, $03, $01, $01, $02, $03, $03, $03, $01, $01, $01, $01, $01, $00, $06
MonsterInfo_171_BoneSlave:  ; BoneSlave — Zombie
    db $07, $28, $0A, $02, $00, $00, $06, $45, $4B, $0E, $0D, $11, $0C, $07, $01
    db $00, $00, $00, $01, $00, $01, $02, $02, $02, $01, $01, $02, $00, $00, $02, $00, $00, $00, $02, $02, $02, $00, $00, $00, $00, $00, $00, $03
MonsterInfo_172_Skeletor:  ; Skeletor — Zombie
    db $07, $3C, $0C, $02, $00, $00, $1C, $4B, $50, $10, $0B, $12, $0C, $10, $13
    db $00, $00, $01, $02, $00, $02, $02, $02, $03, $01, $01, $02, $00, $00, $03, $00, $00, $01, $02, $02, $02, $00, $00, $00, $00, $00, $00, $06
MonsterInfo_173_Servant:  ; Servant — Zombie
    db $07, $50, $14, $02, $00, $00, $00, $0C, $54, $17, $15, $19, $12, $0F, $14
    db $01, $01, $03, $02, $01, $02, $02, $02, $03, $01, $01, $03, $01, $01, $03, $01, $01, $02, $03, $03, $03, $01, $01, $01, $01, $01, $00, $06
MonsterInfo_174_Copycat:  ; Copycat — Zombie
    db $07, $28, $01, $02, $01, $00, $29, $75, $7F, $0B, $14, $01, $02, $15, $05
    db $00, $00, $00, $00, $00, $00, $02, $02, $03, $00, $00, $02, $00, $00, $02, $00, $00, $00, $02, $03, $02, $01, $00, $00, $00, $00, $00, $05
MonsterInfo_175_JewelBag:  ; JewelBag — Material
    db $08, $28, $0C, $02, $00, $00, $03, $17, $19, $0D, $0B, $09, $12, $11, $0F
    db $00, $00, $00, $00, $00, $02, $01, $01, $03, $01, $01, $01, $01, $01, $03, $01, $00, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $04
MonsterInfo_176_EvilWand:  ; EvilWand — Material
    db $08, $32, $0E, $02, $01, $00, $35, $38, $60, $0E, $0F, $11, $0C, $09, $0D
    db $01, $01, $01, $00, $00, $02, $00, $00, $03, $00, $00, $00, $00, $00, $03, $00, $01, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $04
MonsterInfo_177_MadCandle:  ; MadCandle — Material
    db $08, $23, $0A, $02, $00, $00, $00, $56, $7E, $0C, $0A, $0E, $06, $11, $0C
    db $02, $02, $00, $00, $00, $00, $00, $00, $02, $00, $00, $00, $01, $01, $02, $00, $02, $00, $00, $00, $00, $01, $01, $01, $01, $01, $00, $04
MonsterInfo_178_CoilBird:  ; CoilBird — Material
    db $08, $23, $08, $02, $00, $00, $34
DataMon_624e:  ; (referenced from elsewhere in the bank)
    db $35, $8F, $10, $0D, $05, $0E, $0E, $07, $00, $00, $00, $01, $01, $02, $00, $00, $02, $00, $00, $00, $00, $00, $02, $00, $00, $02, $00, $00, $00, $01, $01, $01, $01, $01, $00, $03
MonsterInfo_179_Facer:  ; Facer — Material
    db $08, $32, $0C, $02, $00, $00, $09, $14, $95, $08, $17, $0B, $0C, $03, $13
    db $00, $00, $00, $01, $01, $02, $00, $00, $02, $01, $01, $00, $00, $00, $02, $00, $00, $02, $00, $00, $00, $01, $01, $01, $00, $00, $00, $03
MonsterInfo_180_SpikyBoy:  ; SpikyBoy — Material
    db $08, $1E, $08, $02, $00, $00, $14, $42, $D6, $09, $0D, $0E, $11, $07, $0B
    db $00, $00, $00, $00, $00, $02, $00, $01, $02, $00, $00, $01, $00, $00, $02, $00, $00, $02, $01, $01, $01, $00, $00, $00, $01, $01, $00, $03
MonsterInfo_181_MadMirror:  ; MadMirror — Material
    db $08, $2D, $0E, $02, $00, $00, $27, $29, $38, $0F, $0B, $08, $06, $0B, $13
    db $01, $01, $01, $01, $01, $02, $00, $00, $03, $00, $00, $00, $00, $00, $03, $00, $00, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $04
MonsterInfo_182_RogueNite:  ; RogueNite — Material
    db $08, $2D, $0C, $02, $00, $00, $2B, $40, $48, $0E, $04, $14, $15, $0A, $0D
    db $00, $00, $00, $00, $00, $02, $01, $01, $03, $00, $00, $01, $00, $00, $03, $00, $00, $02, $01, $01, $01, $00, $00, $00, $00, $00, $00, $03
MonsterInfo_183_Goopi:  ; Goopi — Material
    db $08, $28, $08, $02, $00, $00, $52, $7B, $8C, $08, $0D, $0B, $0E, $07, $04
    db $00, $00, $00, $00, $00, $02, $00, $00, $02, $00, $00, $00, $00, $00, $02, $00, $00, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $03
MonsterInfo_184_Voodoll:  ; Voodoll — Material
    db $08, $23, $0B, $02, $00, $00, $18, $19, $1C, $0E, $11, $0C, $0C, $08, $0E
    db $00, $00, $00, $00, $00, $02, $00, $01, $02, $00, $00, $01, $00, $00, $02, $00, $00, $02, $02, $02, $01, $00, $00, $00, $01, $01, $00, $04
MonsterInfo_185_MetalDrak:  ; MetalDrak — Material
    db $08, $2D, $0F, $02, $00, $00, $3F, $5B, $72, $12, $0D, $14, $17, $09, $0A
    db $01, $01, $01, $00, $00, $02, $00, $00, $02, $00, $00, $00, $00, $00, $03, $00, $01, $03, $02, $02, $00, $00, $00, $00, $00, $00, $00, $06
MonsterInfo_186_Balzak:  ; Balzak — Material
    db $08, $23, $0D, $02, $00, $00, $06, $0F, $4F, $15, $0B, $17, $15, $12, $13
    db $00, $00, $00, $00, $00, $02, $01, $01, $02, $01, $01, $01, $01, $01, $02, $01, $00, $02, $00, $00, $00, $01, $01, $01, $01, $01, $00, $06
MonsterInfo_187_SabreMan:  ; SabreMan — Material
    db $08, $1E, $0B, $02, $01, $00, $1A, $4C, $69, $08, $03, $09, $0B, $0C, $06
    db $00, $00, $01, $01, $00, $02, $00, $01, $02, $01, $01, $01, $00, $00, $02, $00, $00, $02, $01, $01, $01, $00, $00, $00, $01, $01, $00, $04
MonsterInfo_188_CurseLamp:  ; CurseLamp — Material
    db $08, $32, $09, $02, $01, $00, $1E, $22, $25, $0C, $12, $09, $13, $0D, $0F
    db $00, $00, $00, $02, $01, $02, $00, $00, $02, $01, $01, $00, $00, $00, $02, $00, $00, $02, $00, $00, $00, $02, $02, $02, $00, $00, $00, $03
MonsterInfo_189_Roboster:  ; Roboster — Material
    db $08, $28, $0D, $02, $00, $00, $50, $55, $57, $0C, $05, $15, $16, $18, $11
    db $01, $01, $01, $01, $01, $02, $01, $02, $03, $00, $00, $00, $00, $00, $03, $00, $01, $02, $02, $02, $00, $00, $00, $00, $00, $00, $00, $05
MonsterInfo_190_EvilPot:  ; EvilPot — Material
    db $08, $28, $0B, $02, $01, $00, $12, $15, $3F, $12, $13, $0F, $12, $09, $13, $00, $00, $00, $00, $00, $02, $02, $02, $03, $01, $01, $01, $01, $01, $03, $01, $00, $02, $00, $00, $00, $00, $00, $00, $00
Jump_003_6473:  ; (referenced from elsewhere in the bank)
    db $00, $00, $03
MonsterInfo_191_Gismo:  ; Gismo — Material
    db $08, $28, $09, $02, $01, $00, $43, $5C, $60, $0D, $0F, $0B, $0E, $14, $12, $00, $00, $00, $02, $01, $02, $00, $00, $02
Jump_003_648e:  ; (referenced from elsewhere in the bank)
    db $00, $00, $00, $00, $01, $02, $00, $00, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $04
MonsterInfo_192_LavaMan:  ; LavaMan — Material
    db $08, $28, $0D, $02, $00, $00, $00, $5C, $88, $12, $0C, $11, $18, $04, $07
    db $03, $03, $01, $02, $00, $01, $00, $00, $03, $00, $00, $01, $00, $00, $03, $00, $03, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $06
MonsterInfo_193_IceMan:  ; IceMan — Material
    db $08, $28, $0D, $02, $00, $00, $0C, $60, $8E, $10, $06, $12, $18, $04, $07
    db $01, $01, $01, $02, $00, $03, $00, $00, $03, $00, $00, $00, $01, $00, $03, $00, $01, $03, $00, $00, $00, $00, $00, $00, $00, $00, $00, $06
MonsterInfo_194_Mimic:  ; Mimic — Material
    db $08, $28, $0B, $02, $01, $00, $00, $12, $37, $19, $0A, $14, $0C, $01, $14
    db $00, $00, $01, $02, $01, $02, $01, $01, $03, $01, $01, $01, $01, $01, $03, $01, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $06
MonsterInfo_195_MudDoll:  ; MudDoll — Material
    db $08, $28, $08, $02, $00, $00, $75, $77, $94, $0C, $03, $0D, $0E, $01, $0F
    db $00, $00, $01, $01, $00, $03, $01, $00, $03, $00, $00, $00, $00, $00, $03, $00, $00, $03, $00, $00, $00, $00, $00, $00, $00, $00, $00, $04
MonsterInfo_196_Golem:  ; Golem — Material
    db $08, $28, $12, $02, $00, $00, $41, $56, $8E, $11, $04, $0C, $15, $04, $06
    db $00, $00, $01, $01, $00, $03, $01, $01, $03, $00, $00, $00, $00, $00, $03, $00, $00, $03, $00, $00, $00, $01, $01, $01, $01, $01, $00, $05
MonsterInfo_197_StoneMan:  ; StoneMan — Material
    db $08, $32, $0F, $02, $00, $00, $88, $8F, $93, $18, $0A, $17, $18, $01, $0E
    db $01, $01, $01, $01, $00, $03, $01, $01, $03, $00, $01, $00, $00, $00, $03, $00, $01, $03, $00, $02, $01, $01, $01, $01, $01, $01, $00, $06
MonsterInfo_198_BombCrag:  ; BombCrag — Material
    db $08, $32, $0E, $02, $00, $00, $14, $32, $93, $0F, $0B, $11, $14, $00, $0D
    db $01, $01, $00, $00, $00, $02, $00, $01, $03, $01, $01, $01, $01, $01, $03, $00, $01, $02, $01, $01, $01, $00, $00, $00, $01, $01, $00, $05
MonsterInfo_199_GoldGolem:  ; GoldGolem — Material
    db $08, $50, $12, $01, $00, $00, $65, $81, $84, $18, $15, $18, $1B, $11, $17
    db $02, $02, $02, $02, $01, $02, $03, $03, $03, $03, $03, $03, $02, $02, $03, $01, $02, $02, $03, $03, $03, $02, $02, $02, $01, $01, $00, $06
MonsterInfo_200_DracoLord:  ; DracoLord — Boss
    db $09, $32, $18, $00, $00, $00, $03, $93, $D5, $14, $1E, $15, $14, $17, $17
    db $01, $01, $00, $00, $00, $01, $03, $03, $03, $02, $03, $03, $03, $03, $03, $00, $01, $01, $03, $02, $03, $03, $03, $03, $00, $00, $00, $06
MonsterInfo_201_DracoLord:  ; DracoLord — Boss
    db $09, $50, $19, $00, $00, $00, $3F, $5C, $81, $15, $1E, $18, $15, $17, $15
    db $02, $02, $01, $01, $01, $02, $03, $03, $03, $03, $03, $03, $03, $03, $03, $01, $02, $02, $03, $03, $03, $03, $03, $03, $01, $01, $00, $06
MonsterInfo_202_Hargon:  ; Hargon — Boss
    db $09, $46, $18, $00, $00, $00, $03, $06, $84, $13, $1E, $14, $15, $17, $17
    db $01, $01, $01, $01, $00, $01, $03, $03, $03, $02, $03, $03, $03, $03, $03, $01, $00, $00, $03, $02, $03, $03, $03, $03, $02, $00, $00, $06
MonsterInfo_203_Sidoh:  ; Sidoh — Boss
    db $09, $50, $19, $00, $01, $00, $5C, $60, $64, $18, $1E, $18, $15, $17, $17
    db $01, $01, $01, $01, $01, $01, $03, $03, $03, $03, $03, $03, $03, $03, $03, $01, $00, $00, $03, $03, $03, $03, $03, $03, $02, $01, $00, $06
MonsterInfo_204_Baramos:  ; Baramos — Boss
    db $09, $46, $18, $00, $00, $00, $06, $5B, $64, $14, $1E, $14, $14, $16, $15
    db $01, $01, $01, $02, $00, $02, $03, $03, $03, $02, $03, $03, $02, $02, $03, $01, $01, $01, $03, $03, $03, $03, $03, $03, $00, $00, $00, $06
MonsterInfo_205_Zoma:  ; Zoma — Boss
    db $09, $50, $19, $00, $00, $00, $60, $65, $80, $18, $1E, $1A, $15, $17, $17
    db $01, $02, $03, $03, $01, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $02, $02, $02, $03, $03, $03, $03, $03, $03, $02, $01, $00, $06
MonsterInfo_206_Pizzaro:  ; Pizzaro — Boss
    db $09, $46, $18, $00, $00, $00, $50, $5C, $64, $15, $1E, $1A, $15, $17, $17, $01, $01, $01, $01, $00, $02, $03, $03, $03, $03, $03, $03, $03, $03, $03
Jump_003_6719:  ; (referenced from elsewhere in the bank)
    db $01, $00, $00, $03, $03, $03, $03, $03, $03, $02, $01, $00, $06
MonsterInfo_207_Esterk:  ; Esterk — Boss
    db $09, $50, $1F, $00, $00, $00, $57, $80, $D9, $1D, $1E, $1A, $18, $17, $17
    db $01, $02, $02, $02, $00, $01, $03, $03, $03, $03, $03, $03, $02, $02, $03, $01, $02, $01, $03, $02, $03, $03, $03, $03, $01, $01, $00, $06
MonsterInfo_208_Mirudraas:  ; Mirudraas — Boss
    db $09, $46, $1E, $00, $00, $00, $00, $06, $0F, $15, $1E, $1A, $15, $17, $17
    db $02, $02, $02, $01, $02, $02, $03, $03, $03, $02, $03, $03, $03, $03, $03, $01, $01, $02, $03, $02, $03, $03, $03, $03, $01, $01, $00, $06
MonsterInfo_209_Mirudraas:  ; Mirudraas — Boss
    db $09, $50, $1F, $00, $00, $00, $43, $5C, $80, $1D, $1E, $1A, $15, $17, $17
    db $02, $02, $02, $00, $00, $00, $03, $03, $03, $03, $03, $03, $02, $02, $03, $01, $03, $01, $03, $03, $03, $03, $03, $03, $01, $01, $00, $06
MonsterInfo_210_Mudou:  ; Mudou — Boss
    db $09, $46, $1C, $00, $00, $00, $5C, $60, $6C, $15, $1E, $1A, $18, $17, $17
    db $01, $01, $01, $03, $00, $01, $03, $03, $03, $02, $03, $03, $02, $03, $03, $00, $03, $03, $03, $02, $03, $03, $03, $03, $00, $00, $00, $06
MonsterInfo_211_DeathMore:  ; DeathMore — Boss
    db $09, $3C, $1B, $00, $01, $00, $64, $65, $84, $15, $1E, $1A, $15, $17, $17
    db $01, $02, $02, $01, $01, $02, $03, $03, $03, $02, $03, $03, $03, $03, $03, $01, $01, $02, $03, $02, $03, $03, $03, $03, $01, $00, $00, $06
MonsterInfo_212_DeathMore:  ; DeathMore — Boss
    db $09, $46, $1D, $00, $00, $00, $3C, $5C, $82, $18, $1E, $1A, $15, $17, $17
    db $02, $02, $02, $01, $01, $02, $03, $03, $03, $03, $03, $03, $03, $03, $03, $01, $01, $02, $03, $02, $03, $03, $03, $03, $02, $01, $00, $06
MonsterInfo_213_DeathMore:  ; DeathMore — Boss
    db $09, $50, $1F, $00, $01, $00, $54, $65, $80, $1D, $1E, $1E, $18, $17, $17
    db $02, $02, $02, $02, $02, $02, $03, $03, $03, $03, $03, $03, $02, $02, $03, $01, $02, $02, $03, $03, $03, $03, $03, $03, $03, $02, $00, $06
MonsterInfo_214_Darkdrium:  ; Darkdrium — Spirit  ; EDITED (project gamedata)
    db $0A, $50, $1E, $00, $00, $00, $0F, $5C, $60, $1F, $1E, $1F, $18, $17, $17
    db $02, $02, $02, $02, $02, $03, $03, $03, $02, $02, $03, $03, $02, $03, $03, $02, $02, $02, $03, $03, $03, $03, $03, $03, $03, $03, $00, $07
MonsterInfo_215_TERRY:  ; TERRY? — Boss
    db $09, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $01, $02, $01, $01, $00, $01, $02, $03, $03, $01, $01, $02, $00, $00, $02, $00, $01, $01, $00, $03, $00, $01, $00, $00, $01, $01, $00, $07
MonsterInfo_216_Tatsu:  ; Tatsu — Boss
    db $09, $00
Jump_003_68ab:  ; (referenced from elsewhere in the bank)
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $02, $02, $03, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $07
MonsterInfo_217_Diago:  ; Diago — Boss
    db $09, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $03, $02, $02, $00, $00, $01, $01, $01, $02, $01, $00, $01, $01, $01, $00, $00, $03, $00, $01, $01, $01, $01, $01, $01, $01, $01, $00, $07
MonsterInfo_218_Samsi:  ; Samsi — Boss
    db $09, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $01, $02, $01, $03, $00, $01, $02, $02, $03, $01, $01, $01, $00, $01, $00, $00, $01, $02, $01, $01, $01, $01, $01, $01, $01, $01, $00, $07
MonsterInfo_219_Bazoo:  ; Bazoo — Boss
    db $09, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $01, $02, $02, $01, $02, $03, $03, $03, $03, $02, $02, $02, $02, $02, $01, $00, $01, $03, $02, $02, $02, $02, $02, $02, $02, $02, $00, $07
MonsterInfo_220_Unused_220:  ; (unused) — Boss
    db $09, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $14, $00, $00, $00
    db $02, $02, $02, $02, $02, $02, $02, $02, $03, $01, $01, $02, $02, $01, $01, $00, $03, $03, $02, $03, $02, $02, $01, $01, $02, $02, $00, $07
; @BUILD_PROJECT END gd_monster_info

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
    add LOW(SpriteFrameDataTable)
    ld l, a
    ld a, h
    adc HIGH(SpriteFrameDataTable)
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
    call SubMonsterWLD
    call CallMon_7134
    ret


    ld a, [$da6b]
    ld l, a
    ld h, $00
    ld a, [$da60]
    call SubMonsterWLD
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
    call SubMonsterWLD
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
    call AddMonsterAIWeightCat1
    call CallMon_7134
    ret


    ld a, [$da6b]
    ld l, a
    ld h, $00
    ld a, [$da60]
    call SubMonsterAIWeightCat1
    call CallMon_7134
    ret


    ld a, [$da6b]
    ld l, a
    ld h, $00
    ld a, [$da60]
    call AddMonsterAIWeightCat3
    call CallMon_7134
    ret


    ld a, [$da6b]
    ld l, a
    ld h, $00
    ld a, [$da60]
    call SubMonsterAIWeightCat3
    call CallMon_7134
    ret


    ld a, [$da6b]
    ld l, a
    ld h, $00
    ld a, [$da60]
    call AddMonsterAIWeightCat2
    call CallMon_7134
    ret


    ld a, [$da6b]
    ld l, a
    ld h, $00
    ld a, [$da60]
    call SubMonsterAIWeightCat2
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


SpriteFrameDataTable:
    nop
    nop
    nop
    nop
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
    ld bc, Boot
    ld bc, Div8Subtract
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
    jp CallBank4B


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

    ld bc, NopReturn
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

    ld bc, Boot
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
    jp DataLookup_3B7C


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
    cp $29                      ; FX1: BCD nav cap "29" = binary 41 (staging 41;
    ret z                       ; vanilla capped at BCD "16" = binary 22)

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
