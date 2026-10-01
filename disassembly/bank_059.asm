; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $059", ROMX[$4000], BANK[$59]

    db $59 ; Bank number

    ; Cross-bank dispatch table (9 entries)
    ; Called via: ld hl, $59XX / rst $10
    dw $4013                          ; Entry 0
    dw $40EF                          ; Entry 1
    dw $458F                          ; Entry 2
    dw $4680                          ; Entry 3
    dw $4824                          ; Entry 4
    dw $48D0                          ; Entry 5
    dw SetB59_52e4                  ; Entry 6
    dw $52EB                          ; Entry 7
    dw CallB59_52f2                  ; Entry 8

; --- Dispatch entry 0 ($4013) ---
DispatchEntry_59_0:
    xor a
    ld hl, $c0d8
    ld bc, $0028
    call FillNBytesWithRegA
    xor a
    ld hl, wMenu_selection
    ld bc, $0008
    call FillNBytesWithRegA
    xor a
    ld hl, $ffc3
    ld bc, $0012
    call FillNBytesWithRegA
    xor a
    ld hl, $dd62
    ld bc, $0006
    call FillNBytesWithRegA
    xor a
    ld hl, $c500
    ld bc, $0240
    call FillNBytesWithRegA
    call ClearSTATMode
    ld hl, $c817
    ld [hl], $00
    inc hl
    ld [hl], $00
    ld hl, $0801
    rst $10
    xor a
    ld [$dd60], a
    xor a
    ld [$c8ec], a
    ld hl, $9700
    ld de, WaitSTATForOverlayB
    call SetupVRAMCopy
    call LoadB59_42c0
    ld hl, $8800
    ld de, CopyDEtoHLByte
    call SetupVRAMCopy
    xor a
    ld [$c823], a
    ld a, $03
    ld [$c822], a
    call SetB59_52e4
    ld hl, $9700
    ld de, WaitSTATForOverlayB
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld de, $2e00
    ld hl, $8d00
    call WaitLCDTransfer
    ld hl, $9800
    ld a, l
    ld [$d9f8], a
    ld a, h
    ld [$d9f9], a
    ld hl, $c500
    ld de, $4511
    call LoadB59_5cd2
    ld hl, $c500
    ld de, $4546
    call LoadB59_5cd2
    call LoadB59_42ec
    call SetB59_432d
    ld a, $fc
    call SetGBCPalette
    ld a, $07
    ldh [$b5], a
    ld a, $ff
    ldh [$b6], a
    ld a, $00
    ldh [$bb], a
    ld a, $00
    ldh [$b7], a
    call ApplyScrollRegisters
    xor a
    ld [$c8a4], a
    ld [$c8a5], a
    xor a
    ld [$c892], a
    ld a, $03
    ld [$c8a1], a
    call EnableLYCInterrupt
    ld a, $01
    jp EnableLCDAndInterrupts


    ld a, [$c850]
    or a
    ret nz

    ld a, [$c843]
    xor $ff
    ld b, a
    ld a, [$c842]
    ld [$c76c], a
    or a
    jr z, jr_059_4104

    and b

jr_059_4104:
    ld [$c76d], a
    ld a, [$c0d8]
    rst $00
    rla
    ld b, c
    ld e, l
    ld b, c
    ld h, l
    ld b, c
    ld l, [hl]
    ld b, c
    ld a, [bc]
    ld b, d
    ld h, b
    ld b, d
    call SetB59_4276
    ld a, [$c76d]
    and $01
    jr nz, jr_059_413c

    ld a, [$c76d]
    and $02
    jr nz, jr_059_4152

    ld a, [$c76d]
    and $c0
    jr nz, jr_059_4130

    ret


jr_059_4130:
    ld a, [wMenu_selection]
    xor $01
    ld [wMenu_selection], a
    call SetB59_432d
    ret


jr_059_413c:
    ld a, [wMenu_selection]
    set 7, a
    ld [wMenu_selection], a
    call SetB59_432d
    ld a, [wMenu_selection]
    and $01
    add $03
    ld [$c0d8], a
    ret


jr_059_4152:
    ld a, $04
    call SetGBCPalette
    ld a, $05
    ld [$c0d8], a
    ret


    ld hl, $c0d8
    inc [hl]
    call LoadB59_42c0
    ret


    ld a, $04
    ld [$c0d8], a
    call LoadB59_42ec
    ret


    call SetB59_4276
    ld a, [$c842]
    and $40
    jr nz, jr_059_419c

    ld a, [$c842]
    and $80
    jr nz, jr_059_41a7

    ld a, [$c842]
    and $20
    jr nz, jr_059_41b2

    ld a, [$c842]
    and $10
    jr nz, jr_059_41bd

    ld a, [$c76d]
    and $01
    jr nz, jr_059_41c8

    ld a, [$c76d]
    and $02
    jr nz, jr_059_41fa

    ret


jr_059_419c:
    ld a, $02
    ld [$dd64], a
    ld a, $00
    ldh [$ca], a
    jr jr_059_41db

jr_059_41a7:
    ld a, $00
    ld [$dd64], a
    ld a, $00
    ldh [$ca], a
    jr jr_059_41db

jr_059_41b2:
    ld a, $01
    ld [$dd64], a
    ld a, $20
    ldh [$ca], a
    jr jr_059_41db

jr_059_41bd:
    ld a, $01
    ld [$dd64], a
    ld a, $00
    ldh [$ca], a
    jr jr_059_41db

jr_059_41c8:
    ld a, [$c0e1]
    ld b, a
    ld a, [$dd64]
    sub b
    ld [$dd64], a
    ld a, [$c0e1]
    xor $03
    ld [$c0e1], a

jr_059_41db:
    ld a, [$c0e1]
    ld b, a
    ld a, [$dd64]
    add b
    ld [$dd64], a
    xor a
    ld [$dd65], a
    ld hl, $dd63
    ld a, l
    ld [$d7b4], a
    ld a, h
    ld [$d7b5], a
    ld hl, $0205
    rst $10
    ret


jr_059_41fa:
    ld a, [wMenu_selection]
    res 7, a
    ld [wMenu_selection], a
    call SetB59_432d
    xor a
    ld [$c0d8], a
    ret


    ld a, [$c76d]
    and $01
    jr nz, jr_059_424a

    call SetB59_4276
    ld a, [$c76d]
    and $02
    jr nz, jr_059_4250

    ld a, [$c842]
    and $20
    jr nz, jr_059_422a

    ld a, [$c842]
    and $10
    jr nz, jr_059_423a

    ret


jr_059_422a:
    ld a, [wPLAN_selection]
    or a
    jr nz, jr_059_4232

    ld a, $d7

jr_059_4232:
    dec a
    ld [wPLAN_selection], a
    call LoadB59_42ec
    ret


jr_059_423a:
    ld a, [wPLAN_selection]
    inc a
    cp $d7
    jr c, jr_059_4243

    xor a

jr_059_4243:
    ld [wPLAN_selection], a
    call LoadB59_42ec
    ret


jr_059_424a:
    ld a, $01
    ld [$c0d8], a
    ret


jr_059_4250:
    ld a, [wMenu_selection]
    res 7, a
    ld [wMenu_selection], a
    call SetB59_432d
    xor a
    ld [$c0d8], a
    ret


    ld a, $00
    ld [wGameMode], a
    xor a
    ld [$c88b], a
    xor a
    ld [$c88c], a
    xor a
    ld [$c88d], a
    ld hl, $c88e
    inc [hl]
    ret


SetB59_4276:
    ld hl, $ffc3
    ld a, $50
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $48
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, [$c0e0]
    add $10
    ld [hl+], a
    inc hl
    ld a, $00
    ld [hl], a
    ld hl, $dd63
    ld a, l
    ld [$d7b4], a
    ld a, h
    ld [$d7b5], a
    ld hl, $0205
    rst $10
    ldh a, [$c8]
    cp $ff
    ret z

    ld hl, $0402
    rst $10
    ld hl, $dd62
    ld a, l
    ld [$d7b4], a
    ld a, h
    ld [$d7b5], a
    ld hl, $0200
    rst $10
    ld a, [$dd62]
    or a
    ret nz

    xor a
    ld [$dd65], a
    ret


LoadB59_42c0:
    ld a, [wPLAN_selection]   ; A = species (raw-species index for this copy)
    ld l, a
    ld [$c0e0], a
    ld h, $00
    add hl, hl
    ld a, l
    add LOW(SaveSlotPtrTable)    ; [8/8] follower gfx-ID copy ($4363; label is mgbdis-
    ld l, a                      ;   misleading — NOT save-slot data; raw-species index).
    ld a, h                      ;   Repoint all 8 on a swap; new species id>=224 overshoots.
    adc HIGH(SaveSlotPtrTable)
    ld h, a
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld h, $80
    ld l, $00
    call WaitDMATransfer
    ld a, [wPLAN_selection]
    ld [$c823], a
    ld a, $05
    ld [$c822], a
    ld hl, $4102
    rst $10
    ret


LoadB59_42ec:
    ld a, [$c0e0]
    ld l, a
    ld h, $00
    call $5ba7
    ld hl, $c521
    ld a, [$c0e8]
    add $f0
    ld [hl+], a
    ld a, [$c0e9]
    add $f0
    ld [hl+], a
    ld a, [$c0ea]
    add $f0
    ld [hl+], a
    ld a, [wPLAN_selection]
    ld l, a
    ld h, $00
    call $5ba7
    ld hl, $c708
    ld a, [$c0e8]
    add $f0
    ld [hl+], a
    ld a, [$c0e9]
    add $f0
    ld [hl+], a
    ld a, [$c0ea]
    add $f0
    ld [hl], a
    ld hl, $5005
    rst $10
    ret


SetB59_432d:
    ld hl, $c500
    ld de, $457f
    call LoadB59_5cd2
    ld a, [wMenu_selection]
    ld hl, $458b
    and $01
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
    ld a, [wMenu_selection]
    bit 7, a
    jr nz, jr_059_435b

    ld a, $e8
    jr jr_059_435d

jr_059_435b:
    ld a, $e9

jr_059_435d:
    ld [hl], a
    ld hl, $5005
    rst $10
    ret


FollowerGfxTable59:
SaveSlotPtrTable:   ; (mgbdis name, kept: referenced by the readers / patches)
    ; FOLLOWER (walking) gfx-ID table — one of the EIGHT per-screen copies
    ; (MONSTER_DATA 'Follower-art table has EIGHT copies'; bank $01's
    ; ScreenTransDataTable is the overworld one). Read by the battle-side party list $42CA (raw species).
    ; Index = species -> gfx-ID (bank<<8 | index) -> $<bank>:$4001 + index*2.
    ; 215 words: species 0-214; ids 215+ read past the end (never followers).
    ; A re-arted species writes the SAME new gfx-ID into all eight copies
    ; (S107: compiler region art_walk_59, gamedata.art).
    ; Re-sectioned S107 (tools/resection_monster_art_tables.py), byte-identical.
    dw $2f01   ; [  0] species 0 DrakSlime
    dw $2f02   ; [  1] species 1 SpotSlime
    dw $2f03   ; [  2] species 2 WingSlime
    dw $2f04   ; [  3] species 3 TreeSlime
    dw $2f05   ; [  4] species 4 Snaily
    dw $2f06   ; [  5] species 5 SlimeNite
    dw $2f07   ; [  6] species 6 Babble
    dw $2f08   ; [  7] species 7 BoxSlime
    dw $2f09   ; [  8] species 8 Slime
    dw $2f0a   ; [  9] species 9 Healer
    dw $2f0b   ; [ 10] species 10 FangSlime
    dw $2f0c   ; [ 11] species 11 RockSlime
    dw $2f0d   ; [ 12] species 12 SlimeBorg
    dw $2f0e   ; [ 13] species 13 Slabbit
    dw $2f0f   ; [ 14] species 14 SpotKing
    dw $2f10   ; [ 15] species 15 KingSlime
    dw $3800   ; [ 16] species 16 Metaly
    dw $3801   ; [ 17] species 17 Metabble
    dw $3802   ; [ 18] species 18 MetalKing
    dw $3803   ; [ 19] species 19 GoldSlime
    dw $3804   ; [ 20] species 20 DragonKid
    dw $3805   ; [ 21] species 21 Tortragon
    dw $3806   ; [ 22] species 22 Pteranod
    dw $3807   ; [ 23] species 23 Gasgon
    dw $3808   ; [ 24] species 24 FairyDrak
    dw $3809   ; [ 25] species 25 LizardMan
    dw $380a   ; [ 26] species 26 Poisongon
    dw $380b   ; [ 27] species 27 Swordgon
    dw $380c   ; [ 28] species 28 Dragon
    dw $380d   ; [ 29] species 29 MiniDrak
    dw $380e   ; [ 30] species 30 MadDragon
    dw $380f   ; [ 31] species 31 Rayburn
    dw $3810   ; [ 32] species 32 Chamelgon
    dw $3811   ; [ 33] species 33 LizardFly
    dw $3812   ; [ 34] species 34 Andreal
    dw $3813   ; [ 35] species 35 KingCobra
    dw $3814   ; [ 36] species 36 Spikerous
    dw $3815   ; [ 37] species 37 GreatDrak
    dw $3816   ; [ 38] species 38 Crestpent
    dw $3817   ; [ 39] species 39 WingSnake
    dw $3818   ; [ 40] species 40 Coatol
    dw $3819   ; [ 41] species 41 Orochi
    dw $381a   ; [ 42] species 42 BattleRex
    dw $381b   ; [ 43] species 43 SkyDragon
    dw $381c   ; [ 44] species 44 Divinegon
    dw $381d   ; [ 45] species 45 Tonguella
    dw $381e   ; [ 46] species 46 Almiraj
    dw $381f   ; [ 47] species 47 CatFly
    dw $3820   ; [ 48] species 48 PillowRat
    dw $3821   ; [ 49] species 49 Saccer
    dw $3822   ; [ 50] species 50 GulpBeast
    dw $3823   ; [ 51] species 51 Skullroo
    dw $3824   ; [ 52] species 52 WindBeast
    dw $3825   ; [ 53] species 53 Anteater
    dw $3826   ; [ 54] species 54 SuperTen
    dw $3827   ; [ 55] species 55 IronTurt
    dw $3828   ; [ 56] species 56 Mommonja
    dw $3829   ; [ 57] species 57 HammerMan
    dw $382a   ; [ 58] species 58 Grizzly
    dw $382b   ; [ 59] species 59 Yeti
    dw $382c   ; [ 60] species 60 MadGopher
    dw $382d   ; [ 61] species 61 FairyRat
    dw $382e   ; [ 62] species 62 Unicorn
    dw $382f   ; [ 63] species 63 Goategon
    dw $3830   ; [ 64] species 64 WildApe
    dw $3831   ; [ 65] species 65 Trumpeter
    dw $3832   ; [ 66] species 66 KingLeo
    dw $3833   ; [ 67] species 67 DarkHorn
    dw $3834   ; [ 68] species 68 MadCat
    dw $3835   ; [ 69] species 69 BigEye
    dw $3836   ; [ 70] species 70 Picky
    dw $3837   ; [ 71] species 71 Wyvern
    dw $3838   ; [ 72] species 72 BullBird
    dw $3839   ; [ 73] species 73 Florajay
    dw $383a   ; [ 74] species 74 DuckKite
    dw $383b   ; [ 75] species 75 MadPecker
    dw $383c   ; [ 76] species 76 MadRaven
    dw $383d   ; [ 77] species 77 MistyWing
    dw $383e   ; [ 78] species 78 Dracky
    dw $383f   ; [ 79] species 79 BigRoost
    dw $3840   ; [ 80] species 80 StubBird
    dw $3841   ; [ 81] species 81 LandOwl
    dw $3842   ; [ 82] species 82 MadGoose
    dw $3843   ; [ 83] species 83 MadCondor
    dw $3844   ; [ 84] species 84 Blizzardy
    dw $3845   ; [ 85] species 85 Phoenix
    dw $3846   ; [ 86] species 86 ZapBird
    dw $3847   ; [ 87] species 87 WhipBird
    dw $3900   ; [ 88] species 88 FunkyBird
    dw $3901   ; [ 89] species 89 RainHawk
    dw $3902   ; [ 90] species 90 MadPlant
    dw $3903   ; [ 91] species 91 FireWeed
    dw $3904   ; [ 92] species 92 FloraMan
    dw $3905   ; [ 93] species 93 WingTree
    dw $3906   ; [ 94] species 94 CactiBall
    dw $3907   ; [ 95] species 95 Gulpple
    dw $3908   ; [ 96] species 96 Toadstool
    dw $3909   ; [ 97] species 97 AmberWeed
    dw $390a   ; [ 98] species 98 Stubsuck
    dw $390b   ; [ 99] species 99 Oniono
    dw $390c   ; [100] species 100 DanceVegi
    dw $390d   ; [101] species 101 TreeBoy
    dw $390e   ; [102] species 102 FaceTree
    dw $390f   ; [103] species 103 HerbMan
    dw $3910   ; [104] species 104 BeanMan
    dw $3911   ; [105] species 105 EvilSeed
    dw $3912   ; [106] species 106 ManEater
    dw $3913   ; [107] species 107 Snapper
    dw $3914   ; [108] species 108 Rosevine
    dw $3915   ; [109] species 109 Watabou
    dw $3916   ; [110] species 110 GiantSlug
    dw $3917   ; [111] species 111 Catapila
    dw $3918   ; [112] species 112 Gophecada
    dw $3919   ; [113] species 113 Butterfly
    dw $391a   ; [114] species 114 WeedBug
    dw $391b   ; [115] species 115 GiantWorm
    dw $391c   ; [116] species 116 Lipsy
    dw $391d   ; [117] species 117 StagBug
    dw $391e   ; [118] species 118 ArmyAnt
    dw $391f   ; [119] species 119 GoHopper
    dw $3920   ; [120] species 120 TailEater
    dw $3921   ; [121] species 121 ArmorPede
    dw $3922   ; [122] species 122 Eyeder
    dw $3923   ; [123] species 123 GiantMoth
    dw $3924   ; [124] species 124 Droll
    dw $3925   ; [125] species 125 ArmyCrab
    dw $3926   ; [126] species 126 MadHornet
    dw $3927   ; [127] species 127 HornBeet
    dw $3928   ; [128] species 128 Armorpion
    dw $3929   ; [129] species 129 Digster
    dw $392a   ; [130] species 130 Pixy
    dw $392b   ; [131] species 131 ArcDemon
    dw $392c   ; [132] species 132 AgDevil
    dw $392d   ; [133] species 133 Demonite
    dw $392e   ; [134] species 134 DarkEye
    dw $392f   ; [135] species 135 EyeBall
    dw $3930   ; [136] species 136 SkulRider
    dw $3931   ; [137] species 137 EvilBeast
    dw $3932   ; [138] species 138 1EyeClown
    dw $3933   ; [139] species 139 Gremlin
    dw $3934   ; [140] species 140 MedusaEye
    dw $3935   ; [141] species 141 Lionex
    dw $3936   ; [142] species 142 GoatHorn
    dw $3937   ; [143] species 143 Orc
    dw $3938   ; [144] species 144 Ogre
    dw $3939   ; [145] species 145 GateGuard
    dw $393a   ; [146] species 146 ChopClown
    dw $393b   ; [147] species 147 Grendal
    dw $393c   ; [148] species 148 Akubar
    dw $393d   ; [149] species 149 MadKnight
    dw $393e   ; [150] species 150 Gigantes
    dw $393f   ; [151] species 151 Centasaur
    dw $3940   ; [152] species 152 EvilArmor
    dw $3941   ; [153] species 153 Jamirus
    dw $3942   ; [154] species 154 Durran
    dw $3943   ; [155] species 155 Spooky
    dw $3944   ; [156] species 156 Skullgon
    dw $3945   ; [157] species 157 Putrepup
    dw $3946   ; [158] species 158 RotRaven
    dw $3947   ; [159] species 159 Mummy
    dw $3a00   ; [160] species 160 DarkCrab
    dw $3a01   ; [161] species 161 DeadNite
    dw $3a02   ; [162] species 162 Shadow
    dw $3a03   ; [163] species 163 Hork
    dw $3a04   ; [164] species 164 Mudron
    dw $3a05   ; [165] species 165 NiteWhip
    dw $3a06   ; [166] species 166 MadSpirit
    dw $3a07   ; [167] species 167 WindMerge
    dw $3a08   ; [168] species 168 Reaper
    dw $3a09   ; [169] species 169 DeadNoble
    dw $3a0a   ; [170] species 170 WhiteKing
    dw $3a0b   ; [171] species 171 BoneSlave
    dw $3a0c   ; [172] species 172 Skeletor
    dw $3a0d   ; [173] species 173 Servant
    dw $3a0e   ; [174] species 174 Copycat
    dw $3a0f   ; [175] species 175 JewelBag
    dw $3a10   ; [176] species 176 EvilWand
    dw $3a11   ; [177] species 177 MadCandle
    dw $3a12   ; [178] species 178 CoilBird
    dw $3a13   ; [179] species 179 Facer
    dw $3a14   ; [180] species 180 SpikyBoy
    dw $3a15   ; [181] species 181 MadMirror
    dw $3a16   ; [182] species 182 RogueNite
    dw $3a17   ; [183] species 183 Goopi
    dw $3a18   ; [184] species 184 Voodoll
    dw $3a19   ; [185] species 185 MetalDrak
    dw $3a1a   ; [186] species 186 Balzak
    dw $3a1b   ; [187] species 187 SabreMan
    dw $3a1c   ; [188] species 188 CurseLamp
    dw $3a1d   ; [189] species 189 Roboster
    dw $3a1e   ; [190] species 190 EvilPot
    dw $3a1f   ; [191] species 191 Gismo
    dw $3a20   ; [192] species 192 LavaMan
    dw $3a21   ; [193] species 193 IceMan
    dw $3a22   ; [194] species 194 Mimic
    dw $3a23   ; [195] species 195 MudDoll
    dw $3a24   ; [196] species 196 Golem
    dw $3a25   ; [197] species 197 StoneMan
    dw $3a26   ; [198] species 198 BombCrag
    dw $3a27   ; [199] species 199 GoldGolem
    dw $3a28   ; [200] species 200 DracoLord
    dw $3a29   ; [201] species 201 DracoLord
    dw $3a2a   ; [202] species 202 Hargon
    dw $3a2b   ; [203] species 203 Sidoh
    dw $3a2c   ; [204] species 204 Baramos
    dw $3a2d   ; [205] species 205 Zoma
    dw $3a2e   ; [206] species 206 Pizzaro
    dw $3a2f   ; [207] species 207 Esterk
    dw $3a30   ; [208] species 208 Mirudraas
    dw $3a31   ; [209] species 209 Mirudraas
    dw $3a32   ; [210] species 210 Mudou
    dw $3a33   ; [211] species 211 DeathMore
    dw $3a34   ; [212] species 212 DeathMore
    dw $3a35   ; [213] species 213 DeathMore
    dw $3a36   ; [214] species 214 Darkdrium
; NOTE: unreferenced fake-decode labels removed with this block: jr_059_438a, jr_059_4390, jr_059_4396, jr_059_439c, jr_059_43a2, jr_059_43a8, jr_059_43ae, jr_059_43b4, jr_059_43ba, jr_059_43c0, jr_059_43c6, jr_059_43cc, jr_059_43d2, jr_059_43d8, jr_059_43de, jr_059_43e4, jr_059_43ea, jr_059_43f0, jr_059_43f6, jr_059_43fc, jr_059_4402, jr_059_4408, jr_059_440e, jr_059_4414, jr_059_441a, jr_059_441d, jr_059_4423, jr_059_4426, jr_059_4429, jr_059_442c, jr_059_442f, jr_059_4432, jr_059_4435, jr_059_4438, jr_059_443b, jr_059_443e, jr_059_4441, jr_059_4447, jr_059_444a, jr_059_444d, jr_059_4453, jr_059_4459, jr_059_447e, jr_059_448e, jr_059_449e, jr_059_44ae, jr_059_44be, jr_059_450f
    nop
    nop
    ld a, [$efef]
    rst $28
    ei
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28

jr_059_451f:
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    ldh [$e0], a
    rst $38
    cp $70
    ld [hl], c
    ld [hl], d
    ld [hl], e
    ld [hl], h

jr_059_452f:
    ld [hl], l
    db $76
    ld [hl], a
    ld a, b
    rst $38
    ret c

    db $fc
    xor $ee
    xor $fd
    db $fc
    xor $ee
    xor $ee

jr_059_453f:
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
    ei
    ret c

    cp $e0
    add b
    add c
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ld a, [$efef]
    rst $28
    ei
    ret c

    cp $e0
    add d
    add e
    add h
    add l
    rst $38
    cp $e0
    ldh [$e0], a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    db $fc
    xor $ee
    xor $fd
    reti


    and c
    ld bc, $d8ef
    ldh [$d8], a
    ldh [$d8], a
    ldh [$d8], a
    xor $d9
    pop bc
    ld bc, $0201
    xor a
    ld hl, $c827
    ld bc, $0012
    call FillNBytesWithRegA
    xor a
    ld hl, $c0d8
    ld bc, $0028
    call FillNBytesWithRegA
    ld hl, $99c1
    ld a, l
    ld [$c83e], a
    ld a, h
    ld [$c83f], a
    call ClearSTATMode
    ld hl, $c817
    ld [hl], $00
    inc hl
    ld [hl], $00
    ld hl, $0801
    rst $10
    xor a
    ld [$dd60], a
    xor a
    ld [$c8ec], a
    call LoadB59_5d0f
    ld de, $2e00
    ld hl, $8d00
    call WaitLCDTransfer
    ld hl, $9700
    ld de, $0401
    call SetupVRAMCopy
    ld a, $00
    ld [$c823], a
    ld a, $01
    ld [$c822], a
    call CallB59_52f2
    ld hl, $96c0
    ld de, $0401
    call SetupVRAMCopy
    ld a, $00
    ld [$c823], a
    ld a, $03
    ld [$c822], a
    ld hl, $4c02
    rst $10
    ld hl, $97c0
    ld de, $0401
    call SetupVRAMCopy
    ld a, $01
    ld [$c823], a
    ld a, $03
    ld [$c822], a
    ld hl, $4c02
    rst $10
    ld hl, $8800
    ld de, $0401
    call SetupVRAMCopy
    ld a, $05
    ld [$c823], a
    ld a, $03
    ld [$c822], a
    ld hl, $4c02
    rst $10
    ld hl, $8b00
    ld de, $1202
    call SetupVRAMCopy
    call CallB59_5d27
    ld de, $5e2f
    ld hl, $c500
    call LoadB59_5cd2
    ld a, $fc
    call SetGBCPalette
    ld hl, $9800
    ld a, l
    ld [$d9f8], a
    ld a, h
    ld [$d9f9], a
    ld hl, $5005
    rst $10
    ld a, $07
    ldh [$b5], a
    ld a, $ff
    ldh [$b6], a
    ld a, $d8
    ldh [$bb], a
    ld a, $00
    ldh [$b7], a
    call ApplyScrollRegisters
    xor a
    ld [$c8a4], a
    ld [$c8a5], a
    xor a
    ld [$c892], a
    ld a, $03
    ld [$c8a1], a
    call EnableLYCInterrupt
    ld a, $01
    jp EnableLCDAndInterrupts


    ld a, [$c0d9]
    rst $00
    dec b
    ld b, a
    dec sp
    ld b, a
    rrca
    ld b, a
    ld c, l
    ld b, a
    dec h
    ld b, a
    call c, $8546
    ld b, a
    ei
    ld b, [hl]
    sub [hl]
    ld b, a
    ei
    ld b, [hl]
    push hl
    ld b, [hl]
    dec h
    ld b, a
    call c, $a746
    ld b, a
    ei
    ld b, [hl]
    push hl
    ld b, [hl]
    dec h
    ld b, a
    dec h
    ld e, h
    dec h
    ld b, a
    call c, $b846
    ld b, a
    ei
    ld b, [hl]
    push hl
    ld b, [hl]
    dec h
    ld b, a
    db $fc
    ld e, e
    rrca
    ld b, a
    ld c, [hl]
    ld e, h
    dec h
    ld b, a
    call c, $c946
    ld b, a
    ei
    ld b, [hl]
    push hl
    ld b, [hl]
    dec h
    ld b, a
    ld [hl], a
    ld e, h
    dec h
    ld b, a
    call c, $da46
    ld b, a
    ei
    ld b, [hl]
    db $eb
    ld b, a
    ei
    ld b, [hl]
    push hl
    ld b, [hl]
    dec h
    ld b, a
    db $fc
    ld b, a
    ld b, $48
    call SetB59_5cf7
    ret nz

    ld hl, $c0d9
    inc [hl]
    ret


    call SetB59_5d03
    ret nz

    ld a, $01
    ld [$c823], a
    ld a, $01
    ld [$c822], a
    call CallB59_52f2
    ld hl, $c0d9
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, $c0d9
    inc [hl]
    ret


    ld a, [$c850]
    or a
    ret nz

    ld hl, $c0d9
    inc [hl]
    ret


    call SetB59_5ca0
    ld hl, $c0da
    inc [hl]
    ld a, [$c0da]
    cp $0f
    ret nz

    ld hl, $c0d9
    inc [hl]
    xor a
    ld [$c0da], a
    ret


    call SetB59_5ca0
    ld hl, $c0da
    inc [hl]
    ld a, [$c0da]
    cp $28
    ret nz

    ld hl, $c0d9
    inc [hl]
    xor a
    ld [$c0da], a
    ret


    ld a, $02
    ld [$c823], a
    ld a, $01
    ld [$c822], a
    call SetB59_52e4
    ld hl, $c0d9
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $01
    ld [$c823], a
    ld a, $01
    ld [$c822], a
    call CallB59_52f2
    call CallB59_5d27
    ld de, $5e9a
    ld hl, $c500
    call LoadB59_5cd2
    ld hl, $c621
    ld [hl], $e8
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    xor a
    ld [$c0db], a
    ld hl, $5005
    rst $10
    ld hl, $c0d9
    inc [hl]
    ret


    ld a, $00
    ld [$c823], a
    xor a
    ld [$c822], a
    call SetB59_52e4
    ld hl, $c0d9
    inc [hl]
    ret


    ld a, $01
    ld [$c823], a
    xor a
    ld [$c822], a
    call SetB59_52e4
    ld hl, $c0d9
    inc [hl]
    ret


    ld a, $02
    ld [$c823], a
    xor a
    ld [$c822], a
    call SetB59_52e4
    ld hl, $c0d9
    inc [hl]
    ret


    ld a, $03
    ld [$c823], a
    xor a
    ld [$c822], a
    call SetB59_52e4
    ld hl, $c0d9
    inc [hl]
    ret


    ld a, $04
    ld [$c823], a
    xor a
    ld [$c822], a
    call SetB59_52e4
    ld hl, $c0d9
    inc [hl]
    ret


    ld a, $05
    ld [$c823], a
    xor a
    ld [$c822], a
    call SetB59_52e4
    ld hl, $c0d9
    inc [hl]
    ret


    ld a, $06
    ld [$c823], a
    xor a
    ld [$c822], a
    call SetB59_52e4
    ld hl, $c0d9
    inc [hl]
    ret


    ld a, $04
    call SetGBCPalette
    ld hl, $c0d9
    inc [hl]
    ret


    ld a, [$c850]
    or a
    ret nz

    ld a, $00
    ld [wGameMode], a
    ld a, $00
    ld [$c88b], a
    ld a, $00
    ld [$c88c], a
    ld a, $00
    ld [$c88d], a
    ld hl, $c88e
    inc [hl]
    ret


    xor a
    ld hl, $c827
    ld bc, $0012
    call FillNBytesWithRegA
    xor a
    ld hl, $c0d8
    ld bc, $0028
    call FillNBytesWithRegA
    xor a
    ld hl, wEventStateMachineIndex
    ld bc, $0008
    call FillNBytesWithRegA
    xor a
    ld hl, wMenu_selection
    ld bc, $0008
    call FillNBytesWithRegA
    xor a
    ld hl, $c8e2
    ld bc, $0008
    call FillNBytesWithRegA
    ld hl, $99c1
    ld a, l
    ld [$c83e], a
    ld a, h
    ld [$c83f], a
    ld hl, $9800
    ld a, l
    ld [$d9f8], a
    ld a, h
    ld [$d9f9], a
    ld a, l
    ld [$d9ea], a
    ld a, h
    ld [$d9eb], a
    call ClearSTATMode
    ld hl, $c817
    ld [hl], $00
    inc hl
    ld [hl], $00
    ld hl, $0801
    rst $10
    xor a
    ld [$dd60], a
    xor a
    ld [$c8ec], a
    call LoadB59_5d0f
    call LoadB59_513c
    ld de, $2e00
    ld hl, $8d00
    call WaitLCDTransfer
    call LoadB59_4ec6
    call SetB59_5087
    ld a, $fc
    call SetGBCPalette
    ld a, $07
    ldh [$b5], a
    ld a, $ff
    ldh [$b6], a
    ld a, $00
    ldh [$b7], a
    ld a, $00
    ldh [$bb], a
    call ApplyScrollRegisters
    xor a
    ld [$c8a4], a
    ld [$c8a5], a
    xor a
    ld [$c892], a
    ld a, $03
    ld [$c8a1], a
    call EnableLYCInterrupt
    ld a, $01
    jp EnableLCDAndInterrupts


    ld a, [$c850]
    or a
    ret nz

    ld a, [$c843]
    xor $ff
    ld b, a
    ld a, [$c842]
    ld [$c76c], a
    or a
    jr z, jr_059_48e5

    and b

jr_059_48e5:
    ld [$c76d], a
    ld a, [$c0d8]
    rst $00
    cp $48
    cp [hl]
    ld c, c
    ld l, d
    ld c, d
    ld l, c
    ld c, e
    rst $08
    ld c, e
    jp nc, Jump_059_734c

    ld c, l
    ld b, b
    ld c, [hl]
    ld a, a
    ld c, [hl]
    ld a, [$c8df]
    or a
    jr z, jr_059_4912

    ld hl, $c8df
    inc [hl]
    ld a, [$c8df]
    cp $08
    ret c

    xor a
    ld [$c8df], a

jr_059_4912:
    call LoadB59_5279
    ld a, [$c76d]
    and $01
    jr nz, jr_059_4933

    ld a, [$c76c]
    and $c0
    jr nz, jr_059_495a

    ld a, [$c76c]
    and $30
    jr nz, jr_059_497b

    ld a, [$c76d]
    and $02
    jp nz, Jump_059_499c

    ret


jr_059_4933:
    xor a
    ld [$c8e0], a
    ld a, $01
    ld [$c8e1], a
    ld hl, $c8df
    inc [hl]
    ld a, [wMenu_selection]
    set 7, a
    ld [wMenu_selection], a
    ld a, $02
    ld [$d9f6], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ld a, $01
    ld [$c0d8], a
    ret


jr_059_495a:
    xor a
    ld [$c8e0], a
    xor a
    ld [$c8e1], a
    ld hl, $c8df
    inc [hl]
    ld a, [wMenu_selection]
    xor $01
    ld [wMenu_selection], a
    ld a, $02
    ld [$d9f6], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ret


jr_059_497b:
    xor a
    ld [$c8e0], a
    xor a
    ld [$c8e1], a
    ld hl, $c8df
    inc [hl]
    ld a, [wMenu_selection]
    xor $02
    ld [wMenu_selection], a
    ld a, $02
    ld [$d9f6], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ret


Jump_059_499c:
    xor a
    ld [$c8e0], a
    xor a
    ld [$c8e1], a
    ld hl, $c8df
    inc [hl]
    ld a, $02
    ld [$d9f6], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    xor a
    ld [$c0d9], a
    ld a, $04
    ld [$c0d8], a
    ret


    ld a, [$c0d9]
    rst $00
    ret z

    ld c, c
    db $dd
    ld c, c
    ld a, [c]
    ld c, c
    xor a
    ld [$d9f6], a
    ld a, $01
    ld [$d9f5], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ld hl, $c0d9
    inc [hl]
    ret


    ld a, [wMenu_selection]
    and $03
    ld [$c823], a
    ld a, $02
    ld [$c822], a
    call SetB59_52e4
    ld hl, $c0d9
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, [wMenu_selection]
    res 7, a
    cp $01
    jr z, jr_059_4a1e

    cp $03
    jr z, jr_059_4a59

    ld [wMenu_selection], a
    xor a
    ld [$c0d8], a
    ld [$c0d9], a
    xor a
    ld [$d9f6], a
    xor a
    ld [$d9f5], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ret


jr_059_4a1e:
    ld a, [$ca8d]
    cp $02
    jr nc, jr_059_4a3f

    ld a, $02
    ld [$c0d8], a
    xor a
    ld [$c0d9], a
    xor a
    ld [$d9f6], a
    ld a, $02
    ld [$d9f5], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ret


jr_059_4a3f:
    ld a, $05
    ld [$c0d8], a
    xor a
    ld [$c0d9], a
    xor a
    ld [$d9f6], a
    ld a, $04
    ld [$d9f5], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ret


jr_059_4a59:
    ld [wMenu_selection], a
    xor a
    ld [$c8e1], a
    ld a, $04
    ld [$c0d8], a
    xor a
    ld [$c0d9], a
    ret


    ld a, [$c8df]
    or a
    jr z, jr_059_4a7e

    ld hl, $c8df
    inc [hl]
    ld a, [$c8df]
    cp $08
    ret c

    xor a
    ld [$c8df], a

jr_059_4a7e:
    call LoadB59_5279
    ld a, [$c76d]
    and $01
    jr nz, jr_059_4aa0

    ld a, [$c76c]
    and $40
    jr nz, jr_059_4ac7

    ld a, [$c76c]
    and $80
    jp nz, Jump_059_4aee

    ld a, [$c76d]
    and $02
    jp nz, Jump_059_4b15

    ret


jr_059_4aa0:
    xor a
    ld [$c8e0], a
    ld a, $01
    ld [$c8e1], a
    ld hl, $c8df
    inc [hl]
    ld a, [wOPTN_and_Item_selection]
    set 7, a
    ld [wOPTN_and_Item_selection], a
    ld a, $02
    ld [$d9f6], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ld a, $03
    ld [$c0d8], a
    ret


jr_059_4ac7:
    xor a
    ld [$c8e0], a
    xor a
    ld [$c8e1], a
    ld hl, $c8df
    inc [hl]
    ld a, [wOPTN_and_Item_selection]
    or a
    jr z, jr_059_4adc

    dec a
    jr jr_059_4ade

jr_059_4adc:
    ld a, $03

jr_059_4ade:
    ld [wOPTN_and_Item_selection], a
    ld a, $02
    ld [$d9f6], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ret


Jump_059_4aee:
    xor a
    ld [$c8e0], a
    xor a
    ld [$c8e1], a
    ld hl, $c8df
    inc [hl]
    ld a, [wOPTN_and_Item_selection]
    cp $03
    jr z, jr_059_4b04

    inc a
    jr jr_059_4b05

jr_059_4b04:
    xor a

jr_059_4b05:
    ld [wOPTN_and_Item_selection], a
    ld a, $02
    ld [$d9f6], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ret


Jump_059_4b15:
    xor a
    ld [$c8e0], a
    xor a
    ld [$c8e1], a
    ld hl, $c8df
    inc [hl]
    ld a, [$ca8d]
    cp $02
    jr c, jr_059_4b4a

    ld a, [$c8e3]
    res 7, a
    ld [$c8e3], a
    xor a
    ld [$d9f6], a
    ld a, $04
    ld [$d9f5], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ld a, $05
    ld [$c0d8], a
    xor a
    ld [$c0d9], a
    ret


jr_059_4b4a:
    ld a, [wMenu_selection]
    res 7, a
    ld [wMenu_selection], a
    xor a
    ld [$c0d8], a
    ld [$c0d9], a
    ld [wOPTN_and_Item_selection], a
    ld [$d9f6], a
    ld [$d9f5], a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ret


    ld a, [$c0d9]
    rst $00
    ret z

    ld c, c
    ld [hl], e
    ld c, e
    adc d
    ld c, e
    ld a, [wOPTN_and_Item_selection]
    and $03
    add $04
    ld [$c823], a
    ld a, $02
    ld [$c822], a
    call SetB59_52e4
    ld hl, $c0d9
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, [wOPTN_and_Item_selection]
    and $03
    cp $03
    jr z, jr_059_4bb6

    res 7, a
    ld [wOPTN_and_Item_selection], a
    ld a, $02
    ld [$c0d8], a
    xor a
    ld [$c0d9], a
    ld [$d9f6], a
    ld a, $02
    ld [$d9f5], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ret


jr_059_4bb6:
    ld a, $06
    ld [$c0d8], a
    xor a
    ld [$c0d9], a
    ld [$d9f6], a
    ld a, $05
    ld [$d9f5], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ret


    ld a, [$c0d9]
    rst $00
    db $db
    ld c, e
    ld bc, $a34c
    ld c, h
    or h
    ld c, h
    xor a
    ld [$c8e2], a
    xor a
    ld [$d9f6], a
    ld a, $03
    ld [$d9f5], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ld a, $08
    ld [$c823], a
    ld a, $02
    ld [$c822], a
    call SetB59_52e4
    ld hl, $c0d9
    inc [hl]
    ret


    ld a, [$c8df]
    or a
    jr z, jr_059_4c15

    ld hl, $c8df
    inc [hl]
    ld a, [$c8df]
    cp $08
    ret c

    xor a
    ld [$c8df], a

jr_059_4c15:
    call LoadB59_5279
    ld a, [$c76d]
    and $01
    jr nz, jr_059_4c2e

    ld a, [$c76c]
    and $c0
    jr nz, jr_059_4c59

    ld a, [$c76d]
    and $02
    jr nz, jr_059_4c7f

    ret


jr_059_4c2e:
    xor a
    ld [$c8e0], a
    ld a, $01
    ld [$c8e1], a
    ld hl, $c8df
    inc [hl]
    ld a, [$c8e2]
    set 7, a
    ld [$c8e2], a
    ld a, $01
    ld [$d9f6], a
    ld a, $03
    ld [$d9f5], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ld hl, $c0d9
    inc [hl]
    ret


jr_059_4c59:
    xor a
    ld [$c8e0], a
    xor a
    ld [$c8e1], a
    ld hl, $c8df
    inc [hl]
    ld a, [$c8e2]
    xor $01
    ld [$c8e2], a
    ld a, $01
    ld [$d9f6], a
    ld a, $03
    ld [$d9f5], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ret


jr_059_4c7f:
    xor a
    ld [$c8e0], a
    xor a
    ld [$c8e1], a
    ld hl, $c8df
    inc [hl]
    xor a
    ld [$d9f6], a
    xor a
    ld [$d9f5], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    xor a
    ld [$c0d8], a
    xor a
    ld [$c0d9], a
    ret


    ld a, [$c8e2]
    and $01
    jr nz, jr_059_4c7f

    ld a, $04
    call SetGBCPalette
    ld hl, $c0d9
    inc [hl]
    ret


    ld a, [$c850]
    or a
    ret nz

    ld a, $00
    ld [wGameMode], a
    ld a, $00
    ld [$c88b], a
    ld a, $00
    ld [$c88c], a
    ld a, $00
    ld [$c88d], a
    ld hl, $c88e
    inc [hl]
    ret


    ld a, [$c8df]
    or a
    jr z, jr_059_4ce6

    ld hl, $c8df
    inc [hl]
    ld a, [$c8df]
    cp $08
    ret c

    xor a
    ld [$c8df], a

jr_059_4ce6:
    call LoadB59_5279
    ld a, [$c76d]
    and $01
    jr nz, jr_059_4cff

    ld a, [$c76c]
    and $c0
    jr nz, jr_059_4d26

    ld a, [$c76d]
    and $02
    jr nz, jr_059_4d47

    ret


jr_059_4cff:
    xor a
    ld [$c8e0], a
    ld a, $01
    ld [$c8e1], a
    ld hl, $c8df
    inc [hl]
    ld a, [$c8e3]
    set 7, a
    ld [$c8e3], a
    ld a, $01
    ld [$d9f6], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ld a, $07
    ld [$c0d8], a
    ret


jr_059_4d26:
    xor a
    ld [$c8e0], a
    xor a
    ld [$c8e1], a
    ld hl, $c8df
    inc [hl]
    ld a, [$c8e3]
    xor $01
    ld [$c8e3], a
    ld a, $01
    ld [$d9f6], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ret


jr_059_4d47:
    ld a, [wMenu_selection]
    res 7, a
    ld [wMenu_selection], a
    xor a
    ld [$c8e0], a
    xor a
    ld [$c8e1], a
    ld hl, $c8df
    inc [hl]
    xor a
    ld [$d9f6], a
    xor a
    ld [$d9f5], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    xor a
    ld [$c0d8], a
    xor a
    ld [$c0d9], a
    ret


    ld a, [$c8df]
    or a
    jr z, jr_059_4d87

    ld hl, $c8df
    inc [hl]
    ld a, [$c8df]
    cp $08
    ret c

    xor a
    ld [$c8df], a

jr_059_4d87:
    call LoadB59_5279
    ld a, [$c76d]
    and $01
    jr nz, jr_059_4da7

    ld a, [$c76c]
    and $40
    jr nz, jr_059_4dce

    ld a, [$c76c]
    and $80
    jr nz, jr_059_4df5

    ld a, [$c76d]
    and $02
    jr nz, jr_059_4e1a

    ret


jr_059_4da7:
    xor a
    ld [$c8e0], a
    ld a, $01
    ld [$c8e1], a
    ld hl, $c8df
    inc [hl]
    ld a, [$c8e4]
    set 7, a
    ld [$c8e4], a
    ld a, $01
    ld [$d9f6], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ld a, $08
    ld [$c0d8], a
    ret


jr_059_4dce:
    xor a
    ld [$c8e0], a
    xor a
    ld [$c8e1], a
    ld hl, $c8df
    inc [hl]
    ld a, [$c8e4]
    or a
    jr z, jr_059_4de3

    dec a
    jr jr_059_4de5

jr_059_4de3:
    ld a, $02

jr_059_4de5:
    ld [$c8e4], a
    ld a, $01
    ld [$d9f6], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ret


jr_059_4df5:
    xor a
    ld [$c8e0], a
    xor a
    ld [$c8e1], a
    ld hl, $c8df
    inc [hl]
    ld a, [$c8e4]
    inc a
    cp $03
    jr c, jr_059_4e0a

    xor a

jr_059_4e0a:
    ld [$c8e4], a
    ld a, $01
    ld [$d9f6], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ret


jr_059_4e1a:
    xor a
    ld [$c8e0], a
    xor a
    ld [$c8e1], a
    ld hl, $c8df
    inc [hl]
    xor a
    ld [$d9f6], a
    ld a, $02
    ld [$d9f5], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ld a, $02
    ld [$c0d8], a
    xor a
    ld [$c0d9], a
    ret


    ld a, [$c0d9]
    rst $00
    ret z

    ld c, c
    ld c, d
    ld c, [hl]
    ld h, c
    ld c, [hl]
    ld a, [$c8e3]
    and $03
    add $09
    ld [$c823], a
    ld a, $02
    ld [$c822], a
    call SetB59_52e4
    ld hl, $c0d9
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $02
    ld [$c0d8], a
    xor a
    ld [$c0d9], a
    ld [$d9f6], a
    ld a, $02
    ld [$d9f5], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ret


    ld a, [$c0d9]
    rst $00
    ret z

    ld c, c
    adc c
    ld c, [hl]
    and b
    ld c, [hl]
    ld a, [$c8e4]
    and $03
    add $0b
    ld [$c823], a
    ld a, $02
    ld [$c822], a
    call SetB59_52e4
    ld hl, $c0d9
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, [$c8e4]
    res 7, a
    ld [$c8e4], a
    ld a, $06
    ld [$c0d8], a
    xor a
    ld [$c0d9], a
    ld [$d9f6], a
    ld a, $05
    ld [$d9f5], a
    xor a
    ld [wEventStateMachineIndex], a
    call LoadB59_4ec6
    ret


LoadB59_4ec6:
    ld a, [wEventStateMachineIndex]
    or a
    ret nz

    ld a, [$d9f5]
    rst $00
    db $db
    ld c, [hl]
    jr nz, @+$51

    ld [hl-], a
    ld c, a
    ld [hl], a
    ld c, a
    ret


    ld c, a
    inc c
    ld d, b
    ld a, [$d9f6]
    rst $00
    push hl
    ld c, [hl]
    db $eb
    ld c, [hl]
    db $eb
    ld c, [hl]
    call LoadB59_5d4f
    call LoadB59_5060
    ld de, $608f
    ld hl, $c500
    call LoadB59_5cd2
    ld a, [wMenu_selection]
    and $0f
    ld hl, $52d0
    call CalcB59_5bf1
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    ld a, l
    ld [$c8dd], a
    ld a, h
    ld [$c8de], a
    ld a, [wMenu_selection]
    bit 7, a
    jr z, jr_059_4f1b

    ld [hl], $e9
    jp Jump_059_504d


jr_059_4f1b:
    ld [hl], $e8
    jp Jump_059_504d


    call LoadB59_5d4f
    call LoadB59_5060
    ld de, $5dc4
    ld hl, $c500
    call LoadB59_5cd2
    jp Jump_059_504d


    ld a, [$d9f6]
    rst $00
    inc a
    ld c, a
    ld b, d
    ld c, a
    ld b, d
    ld c, a
    call LoadB59_5d4f
    call LoadB59_5060
    ld de, $611d
    ld hl, $c500
    call LoadB59_5cd2
    ld a, [wOPTN_and_Item_selection]
    and $0f
    ld hl, $52d8
    call CalcB59_5bf1
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    ld a, l
    ld [$c8dd], a
    ld a, h
    ld [$c8de], a
    ld a, [wOPTN_and_Item_selection]
    bit 7, a
    jr z, jr_059_4f72

    ld [hl], $e9
    jp Jump_059_504d


jr_059_4f72:
    ld [hl], $e8
    jp Jump_059_504d


    ld a, [$d9f6]
    rst $00
    ld a, a
    ld c, a
    adc [hl]
    ld c, a
    call LoadB59_5d4f
    call LoadB59_5060
    ld de, $5dc4
    ld hl, $c500
    call LoadB59_5cd2
    ld de, $5f1c
    ld hl, $c500
    call LoadB59_5cd2
    ld a, [$c8e2]
    and $0f
    ld hl, $52e0
    call CalcB59_5bf1
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    ld a, l
    ld [$c8dd], a
    ld a, h
    ld [$c8de], a
    ld a, [$c8e2]
    bit 7, a
    jr z, jr_059_4fbd

    ld [hl], $e9
    jr jr_059_4fbf

jr_059_4fbd:
    ld [hl], $e8

jr_059_4fbf:
    ld a, [$d9f6]
    or a
    jp nz, Jump_059_5056

    jp Jump_059_504d


    ld a, [$d9f6]
    rst $00
    pop de
    ld c, a
    rst $10
    ld c, a
    call LoadB59_5d4f
    call LoadB59_5060
    ld de, $60d7
    ld hl, $c500
    call LoadB59_5cd2
    ld a, [$c8e3]
    and $0f
    add $02
    ld hl, $52d8
    call CalcB59_5bf1
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    ld a, l
    ld [$c8dd], a
    ld a, h
    ld [$c8de], a
    ld a, [$c8e3]
    bit 7, a
    jr z, jr_059_5008

    ld [hl], $e9
    jr jr_059_504d

jr_059_5008:
    ld [hl], $e8
    jr jr_059_504d

    ld a, [$d9f6]
    rst $00
    inc d
    ld d, b
    ld a, [de]
    ld d, b
    call LoadB59_5d4f
    call LoadB59_5060
    ld de, $5f41
    ld hl, $c500
    call LoadB59_5cd2
    ld a, [$c8e4]
    and $0f
    add $01
    ld hl, $52d8
    call CalcB59_5bf1
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    ld a, l
    ld [$c8dd], a
    ld a, h
    ld [$c8de], a
    ld a, [$c8e4]
    bit 7, a
    jr z, jr_059_504b

    ld [hl], $e9
    jr jr_059_504d

jr_059_504b:
    ld [hl], $e8

Jump_059_504d:
jr_059_504d:
    ld hl, $8b00
    ld de, $1202
    call SetupVRAMCopy

Jump_059_5056:
    ld hl, $5005
    rst $10
    ld a, $01
    ld [wEventStateMachineIndex], a
    ret


LoadB59_5060:
    ld a, [$ca8d]
    or a
    jr z, jr_059_507d

    ld hl, $52c2
    ld a, [$ca8d]
    call CalcB59_5bf1
    ld d, h
    ld e, l
    ld hl, $c500
    call LoadB59_5cd2
    call ClrB59_51a8
    call ClrB59_5240

jr_059_507d:
    ld de, $5d98
    ld hl, $c500
    call LoadB59_5cd2
    ret


SetB59_5087:
    ld hl, $96c0
    ld de, $0401
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld a, $00
    ld [$c823], a
    ld a, $03
    ld [$c822], a
    ld hl, $4c02
    rst $10
    ld hl, $97c0
    ld de, $0401
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld a, $01
    ld [$c823], a
    ld a, $03
    ld [$c822], a
    ld hl, $4c02
    rst $10
    ld hl, $8850
    ld de, $1401
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld a, $03
    ld [$c823], a
    ld a, $03
    ld [$c822], a
    ld hl, $4c02
    rst $10
    ld hl, $8990
    ld de, $0501
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld a, $04
    ld [$c823], a
    ld a, $03
    ld [$c822], a
    ld hl, $4c02
    rst $10
    ld hl, $8800
    ld de, $0501
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld a, $05
    ld [$c823], a
    ld a, $03
    ld [$c822], a
    ld hl, $4c02
    rst $10
    ret


LoadB59_513c:
    ld a, [$ca8d]
    or a
    ret z

    xor a
    ld [$c0eb], a
    ld hl, $9700
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld de, $0401
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a

jr_059_515b:
    ld a, [$c0eb]
    ld hl, $ca8e
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    call FuncB59_521e
    ld hl, $c0eb
    inc [hl]
    ld a, [$c827]
    ld l, a
    ld a, [$c828]
    ld h, a
    ld a, l
    add $40
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, [$c0eb]
    ld d, a
    ld a, [$ca8d]
    cp d
    jr nz, jr_059_515b

    ld hl, $8b00
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld de, $1202
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ret


ClrB59_51a8:
    xor a
    ld [$c0eb], a

jr_059_51ac:
    ld a, [$c0eb]
    ld hl, $ca8e
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    call FuncB59_51cb
    ld hl, $c0eb
    inc [hl]
    ld a, [$c0eb]
    ld d, a
    ld a, [$ca8d]
    cp d
    jr nz, jr_059_51ac

    ret


FuncB59_51cb:
    ld c, $95
    ld b, $00
    call MaskB59_5d5b
    push bc
    ld hl, $cb11
    call CalcB59_5bec
    call $5ba7
    ld a, [$c0eb]
    ld hl, $52b0
    call CalcB59_5bf1
    call LoadB59_51ff
    pop bc
    ld hl, $cb15
    call CalcB59_5bec
    call $5ba7
    ld a, [$c0eb]
    ld hl, $52b6
    call CalcB59_5bf1
    call LoadB59_51ff
    ret


LoadB59_51ff:
    ld a, [$c0e8]
    ld e, a
    or a
    jr z, jr_059_5209

    add $f0
    ld [hl], a

jr_059_5209:
    inc hl
    ld a, [$c0e9]
    or e
    jr z, jr_059_5216

    ld a, [$c0e9]
    add $f0
    ld [hl], a

jr_059_5216:
    inc hl
    ld a, [$c0ea]
    add $f0
    ld [hl], a
    ret


FuncB59_521e:
    ld c, $95
    ld b, $00
    call MaskB59_5d5b
    ld hl, $cac2
    add hl, bc
    ld d, h
    ld e, l
    ld hl, $c180
    call Copy4Bytes
    ld a, $02
    ld [$c822], a
    ld a, $00
    ld [$c823], a
    ld hl, $4102
    rst $10
    ret


ClrB59_5240:
    xor a
    ld [$c0eb], a
    call SetB59_5248
    ret


SetB59_5248:
    ld hl, $c180
    ld a, $f0
    ld [hl], a
    ld a, [$c0eb]
    ld hl, $52ca
    call CalcB59_5bf1
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld de, $0301
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
    ret


LoadB59_5279:
    ld a, [$c8e1]
    or a
    ret nz

    ld hl, $c8e0
    inc [hl]
    ld a, [$c8e0]
    cp $0a
    jr z, jr_059_528e

    cp $14
    jr z, jr_059_529d

    ret


jr_059_528e:
    ld a, [$c8dd]
    ld l, a
    ld a, [$c8de]
    ld h, a
    ld [hl], $e0
    ld hl, $5005
    rst $10
    ret


jr_059_529d:
    ld a, [$c8dd]
    ld l, a
    ld a, [$c8de]
    ld h, a
    ld [hl], $e8
    ld hl, $5005
    rst $10
    xor a
    ld [$c8e0], a
    ret


    ld h, d
    push bc
    ld l, b
    push bc
    ld l, [hl]
    push bc
    add d
    push bc
    adc b
    push bc
    adc [hl]
    push bc
    nop
    sub a
    ld b, b
    sub a
    add b
    sub a
    ld d, a
    ld h, b
    ld d, a
    ld h, b
    ei
    ld e, a
    ld a, e
    ld e, a
    and b
    adc l
    or b
    adc l
    ret nz

    adc l
    pop bc
    ld bc, $0201
    rst $00
    ld bc, $0207
    ld b, c
    ld bc, $0181
    pop bc
    ld bc, $0201
    cpl
    ld bc, $016f

SetB59_52e4:
    ld de, $52f9
    call CallTextEngine
    ret


    ld de, $52f9
    call RunTextHandler
    ret


CallB59_52f2:
    call SetB59_52e4
    call RequestScreenUpdate
    ret


    ld bc, $0f53
    ld d, e
    dec d
    ld d, e
    ld sp, $3353
    ld d, e
    ld d, h
    ld d, e
    ld l, c
    ld d, h
    dec e
    ld d, l
    ld d, d
    ld d, [hl]
    di
    ld d, [hl]
    ld b, d
    ld d, a
    add e
    ld d, a
    adc b
    ld d, a
    adc d
    ld d, a
    and [hl]
    ld d, a
    ei
    ld d, a
    or l
    ld e, b
    ld b, [hl]
    ld e, c
    sbc c
    ld e, c
    adc $59
    nop
    ld e, d
    dec [hl]
    ld e, d
    ld l, a
    ld e, d
    ld a, b
    ld e, d
    or [hl]
    ld e, d
    or $5a
    dec d
    ld e, e
    ld e, h
    ld e, e
    sbc b
    ld e, e
    sbc a
    and e
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $65
    dec h
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ld [hl], $40
    ld c, a
    ld b, d
    ld b, d
    ld c, e
    ld h, l
    ld e, a
    rst $30
    ldh a, [$9f]
    and e
    ld [hl], $42
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld h, d
    ld h, l
    add hl, hl
    inc l
    ld a, [hl+]
    dec hl
    scf
    ld h, l
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld a, [$f0fb]
    rst $28
    xor $3e
    ld d, d
    ld d, c
    ld c, h
    ld c, d
    ld a, $51
    ld b, [hl]
    ld b, b
    ld a, $49
    ld c, c
    ld d, [hl]
    ld e, a
    rst $28
    xor $fa
    ei
    ldh a, [$ef]
    xor $9f
    and e
    ld [hl], $42
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld h, d
    ld h, l
    inc sp
    cpl
    inc h
    ld sp, $6265
    ld d, c
    ld c, h
    rst $28
    xor $50
    ld b, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld c, c
    ld a, $4b
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld a, [$f0fb]
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    rst $28
    xor $42
    ld a, $40
    ld b, l
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$f0fb]
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld e, a
    rst $28
    xor $fa
    ei
    ldh a, [$ef]
    xor $9f
    and e
    ld [hl], $42
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld h, d
    ld h, l
    inc l
    scf
    jr z, jr_059_542a

    ld h, l
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld b, l
    ld b, d
    ld c, c
    ld c, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, [$f0fb]
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $46
    ld d, c
    ld b, d
    ld c, d
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d

jr_059_542a:
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld e, a
    ld a, [$f0fb]
    rst $28
    xor $9f
    and e
    inc h
    ld c, e
    ld b, c
    ld h, d
    ld d, b
    ld b, d
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld h, d
    ld h, l
    dec [hl]
    jr c, jr_059_5477

    ld h, l
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld b, e
    ld c, c
    ld b, d
    ld b, d
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld a, [$f0fb]
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$9f]
    and e
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld h, l
    add hl, hl
    inc l
    ld a, [hl+]
    dec hl
    scf
    ld h, l

jr_059_5477:
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $50
    ld b, d
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, d
    ld b, c
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$f0fb]
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld e, [hl]
    rst $28
    xor $fa
    ei
    ldh a, [$ef]
    xor $9f
    and e
    ld b, b
    ld b, l
    ld c, h
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld b, [hl]
    ld c, a
    rst $28
    xor $4c
    ld d, h
    ld c, e
    ld h, d
    ld c, d
    ld c, h
    ld d, e
    ld b, d
    ld d, b
    ld e, a
    ld a, [$f0fb]
    rst $28
    xor $9f
    and e
    inc l
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $45
    ld a, $53
    ld b, d
    ld l, [hl]
    ld c, d
    ld h, d
    ld c, l
    ld b, d
    ld c, a
    ld b, e
    ld c, h
    ld c, a
    ld c, d
    ld a, [$f0fb]
    rst $28
    xor $40
    ld b, d
    ld c, a
    ld d, c
    ld a, $46
    ld c, e
    ld h, d
    ld c, d
    ld c, h
    ld d, e
    ld b, d
    ld d, b
    rst $28
    xor $40
    ld c, h
    ld c, e
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld c, a
    ld e, [hl]
    ld a, [$f0fb]
    rst $28
    xor $9f
    and e
    ld d, c
    ld b, l
    ld b, d
    ld b, [hl]
    ld c, a
    rst $28
    xor $65
    ld c, l
    ld b, d
    ld c, a
    ld d, b
    ld c, h
    ld c, e
    ld a, $49
    ld b, [hl]
    ld d, c
    ld d, [hl]
    ld h, l
    ld h, e
    rst $30
    ldh a, [$9f]
    and e
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld h, l
    inc sp
    cpl
    inc h
    ld sp, $6265
    ld b, [hl]
    ld d, b
    rst $28
    xor $50
    ld b, d
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, d
    ld b, c
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld b, d
    ld d, c
    ld a, [$f0fb]
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld c, e
    ld b, d
    rst $28
    xor $fa
    ei
    ldh a, [$ef]
    xor $9f
    and e
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld e, a
    ld e, a
    rst $28
    xor $fa
    ei
    ldh a, [$ef]
    xor $9f
    and e
    ld h, l
    ld h, $2b
    inc h
    dec [hl]
    ld a, [hl+]
    jr z, jr_059_55da

    ld h, l
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld a, $44
    ld c, a
    ld b, d
    ld d, b
    ld d, b
    ld b, [hl]
    ld d, e
    ld b, d
    ld e, [hl]
    ld a, [$f0fb]
    rst $28
    xor $9f
    and e
    ld h, l
    jr nc, jr_059_55c5

    dec sp
    jr z, jr_059_55c3

    ld h, l
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld d, b
    ld d, d
    ld c, l
    ld c, l
    ld c, h
    ld c, a
    ld d, c
    ld a, [$f0fb]
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld b, [hl]
    ld c, a
    ld h, d
    ld b, e
    ld c, a
    ld b, [hl]
    ld b, d
    ld c, e
    ld b, c
    ld d, b

jr_059_55c3:
    ld e, a
    ld e, a

jr_059_55c5:
    ld e, a
    rst $28
    xor $fa
    ei
    ldh a, [$ef]
    xor $9f
    and e
    ld h, l
    ld h, $24
    jr c, jr_059_560b

    inc l
    ld [hl-], a
    jr c, jr_059_560e

    ld h, l
    ld h, d

jr_059_55da:
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld a, [$f0fb]
    rst $28
    xor $40
    ld a, $52
    ld d, c
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
    ld c, c
    ld d, [hl]
    ld e, a
    rst $28
    xor $fa
    ei
    ldh a, [$ef]
    xor $9f
    and e
    dec h
    ld d, [hl]
    ld h, d
    ld d, b
    ld b, d
    ld c, c
    ld b, d

jr_059_560b:
    ld b, b
    ld d, c
    ld b, [hl]

jr_059_560e:
    ld c, e
    ld b, h
    rst $28
    xor $65
    ld h, $32
    jr nc, jr_059_5647

    inc h
    ld sp, $6527
    ld e, [hl]
    ld a, [$f0fb]
    rst $28
    xor $9f
    and e
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, d
    ld a, $4b
    ld b, c
    ld d, b
    ld a, [$f0fb]
    rst $28
    xor $41
    ld b, [hl]
    ld c, a
    ld b, d

jr_059_5647:
    ld b, b
    ld d, c
    ld c, c
    ld d, [hl]
    ld e, a
    rst $28
    xor $ef
    xor $f7
    ldh a, [$9f]
    and e
    dec h
    ld d, [hl]
    ld h, d
    ld d, b
    ld b, d
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $65
    inc l
    scf
    jr z, jr_059_5697

    ld h, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld a, [$f0fb]
    rst $28
    xor $45
    ld b, d
    ld c, c
    ld c, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$f0fb]
    rst $28
    xor $9f

jr_059_5697:
    and e
    ld e, a
    ld e, a
    ld e, a
    ccf
    ld d, [hl]
    ld h, d
    ld d, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $46
    ld d, c
    ld b, d
    ld c, d
    ld d, b
    ld e, [hl]
    ld a, [$f0fb]
    rst $28
    xor $9f
    and e
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld d, c
    ld a, $4a
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, d
    ld d, [hl]
    ld l, b
    ld a, [$f0fb]
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    rst $28
    xor $fa
    ei
    ldh a, [$ef]
    xor $9f
    and e
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, d
    ld b, d
    ld a, $51
    ld h, e
    rst $28
    xor $ef
    xor $f7
    ldh a, [$9f]
    and e
    ld [hl], $42
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld h, d
    ld h, l
    dec [hl]
    jr c, jr_059_5731

    ld h, l
    rst $28
    xor $54
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld a, [$f0fb]
    rst $28
    xor $43
    ld c, c
    ld b, d
    ld b, d
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    rst $28
    xor $fa
    ei
    ldh a, [$ef]
    xor $9f
    and e
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, d
    ld c, e
    ld b, d

jr_059_5731:
    ld c, d
    ld d, [hl]
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld e, a
    rst $28
    xor $f7
    ldh a, [$9f]
    and e
    scf
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    ld a, $49
    ld c, c
    ld h, d
    ld a, $3f
    ld c, h
    ld d, d
    ld d, c
    rst $28
    xor $65
    ccf
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld h, l
    ld e, a
    ld a, [$f0fb]
    rst $28
    xor $9f
    and e
    cpl
    ld b, d
    ld a, $4f
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld d, c
    rst $28
    xor $4c
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, h
    ld d, h
    ld c, e
    ld e, a
    rst $30
    ldh a, [$36]
    ld c, c
    ld b, [hl]
    ld c, h
    ldh a, [$ed]
    ldh a, [$ed]
    ld a, [hl+]
    ld c, a
    ld a, $4b
    ld b, c
    ld c, l
    ld a, $62
    ld [hl], $3e
    ld c, b
    ld a, $4a
    ld c, h
    ld d, c
    ld c, h
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    db $ec
    ldh a, [$36]
    ld b, d
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld h, d
    ld h, l
    add hl, hl
    inc l
    ld a, [hl+]
    dec hl
    scf
    ld h, l
    ld h, d
    or [hl]
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld a, $40
    ld d, c
    ld a, [$f0fb]
    rst $28
    xor $3f
    ld a, $50
    ld b, d
    ld b, c
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4d
    ld c, a
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
    ld h, d
    ld c, l
    ld c, c
    ld a, $4b
    ld a, [$f0fb]
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld b, l
    ld c, h
    ld d, b
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$36]
    ld b, d
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld h, d
    ld h, l
    inc sp
    cpl
    inc h
    ld sp, $6265
    ld a, $4b
    ld b, c
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld d, b
    ld b, d
    ld d, c
    ld a, [$f0fb]
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $3f
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld a, $51
    ld b, d
    ld b, h
    ld d, [hl]
    ld e, a
    ld a, [$f0fb]
    rst $28
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $40
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$f0fb]
    rst $28
    xor $50
    ld d, c
    ld c, a
    ld a, $51
    ld b, d
    ld b, h
    ld d, [hl]
    ld h, d
    ld d, d
    ld c, e
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld a, [$f0fb]
    rst $28
    xor $49
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $40
    ld c, h
    ld c, d
    ld c, d
    ld a, $4b
    ld b, c
    ld d, b
    ld e, a
    rst $30
    ldh a, [$36]
    ld b, d
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld h, l
    inc l
    scf
    jr z, jr_059_58f4

    ld h, l
    rst $28
    xor $3e
    ld c, c
    ld c, c
    ld c, h
    ld d, h
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld a, [$f0fb]
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d

jr_059_58f4:
    ld c, a
    ld d, b
    ld h, d
    ld b, c
    ld b, [hl]
    ld c, a
    ld b, d
    ld b, b
    ld d, c
    ld c, c
    ld d, [hl]
    ld e, a
    ld a, [$f0fb]
    rst $28
    xor $24
    ld c, c
    ld d, b
    ld c, h
    ld e, [hl]
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld a, $49
    ld c, c
    ld c, h
    ld d, h
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld a, $49
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld a, [$f0fb]
    rst $28
    xor $42
    ld b, [hl]
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, d
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld c, h
    ld c, a
    rst $28
    xor $43
    ld c, a
    ld b, [hl]
    ld b, d
    ld c, e
    ld b, c
    ld d, b
    ld e, a
    rst $30
    ldh a, [$36]
    ld b, d
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld h, d
    ld h, l
    dec [hl]
    jr c, jr_059_5982

    ld h, l
    rst $28
    xor $54
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, a
    ld b, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld a, [$f0fb]
    rst $28
    xor $54
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, e
    ld c, c
    ld b, d
    ld b, d
    ld e, a
    rst $28
    xor $fa
    ei
    ldh a, [$ef]
    xor $25
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c

jr_059_5982:
    ld h, d
    ld b, c
    ld c, h
    ld b, d
    ld d, b
    ld c, e
    ld h, a
    rst $28
    xor $3e
    ld c, c
    ld d, h
    ld a, $56
    ld d, b
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, b
    ld e, a
    rst $30
    ldh a, [$36]
    ld b, d
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld h, d
    ld h, l
    ld h, $2b
    inc h
    dec [hl]
    ld a, [hl+]
    jr z, @+$65

    ld h, l
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld a, $4b
    ld h, d
    ld a, $44
    ld b, h
    ld c, a
    ld b, d
    ld d, b
    ld d, b
    ld b, [hl]
    ld d, e
    ld b, d
    ld a, [$f0fb]
    rst $28
    xor $50
    ld d, c
    ld c, a
    ld a, $51
    ld b, d
    ld b, h
    ld d, [hl]
    ld e, a
    rst $28
    xor $f7
    ldh a, [$36]
    ld b, d
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld h, d
    ld h, l
    jr nc, jr_059_5a04

    dec sp
    jr z, jr_059_5a02

    ld h, l
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld a, $62
    ld d, b
    ld d, d
    ld c, l
    ld c, l
    ld c, h
    ld c, a
    ld d, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld a, [$f0fb]
    rst $28
    xor $50
    ld d, c
    ld c, a
    ld a, $51
    ld b, d
    ld b, h
    ld d, [hl]
    ld e, a
    rst $28
    xor $f7
    ldh a, [$36]
    ld b, d

jr_059_5a02:
    ld c, c
    ld b, d

jr_059_5a04:
    ld b, b
    ld d, c
    ld h, d
    ld h, l
    ld h, $24
    jr c, @+$39

    inc l
    ld [hl-], a
    jr c, jr_059_5a46

    ld h, l
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld a, $62
    ld d, b
    ld d, c
    ld c, a
    ld a, $51
    ld b, d
    ld b, h
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    ld a, [$f0fb]
    rst $28
    xor $50
    ld a, $53
    ld b, d
    ld h, d
    dec hl
    inc sp
    ld e, a
    rst $28
    xor $f7
    ldh a, [$36]
    ld b, d
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    rst $28
    xor $65
    ld h, $32
    jr nc, jr_059_5a76

jr_059_5a46:
    inc h
    ld sp, $6527
    ld h, d
    ld a, $49
    ld c, c
    ld c, h
    ld d, h
    ld d, b
    ld a, [$f0fb]
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, [hl]
    ld d, b
    ld d, b
    ld d, d
    ld b, d
    rst $28
    xor $40
    ld c, h
    ld c, d
    ld c, d
    ld a, $4b
    ld b, c
    ld d, b
    ld e, a
    rst $30
    ldh a, [$ed]
    jr z, jr_059_5abd

    ld c, h
    ld d, d
    ld b, h
    ld b, l

jr_059_5a76:
    ld h, h
    ldh a, [$36]
    ld b, d
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld h, d
    ld h, l
    inc h
    cpl
    cpl
    ld h, l
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $44
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld a, $62
    ld d, b
    ld d, c
    ld c, a
    ld a, $51
    ld b, d
    ld b, h
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    ld a, [$f0fb]
    rst $28
    xor $3e
    ld c, c
    ld c, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld e, a
    rst $28
    xor $f7
    ldh a, [$36]
    ld b, d
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld h, d

jr_059_5abd:
    ld h, l
    jr z, jr_059_5ae4

    ld h, $2b
    ld h, l
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld a, $62
    ld d, b
    ld d, c
    ld c, a
    ld a, $51
    ld b, d
    ld b, h
    ld d, [hl]
    ld a, [$f0fb]
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld b, [hl]
    ld c, e
    ld b, c
    ld b, [hl]
    ld d, e

jr_059_5ae4:
    ld b, [hl]
    ld b, c
    ld d, d
    ld a, $49
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld e, a
    rst $30
    ldh a, [$65]
    inc h
    scf
    ld l, $65
    ld h, d
    ld c, d
    ld b, d
    ld a, $4b
    ld d, b
    ld h, d
    ld a, $ef
    xor $4b
    ld c, h
    ld c, a
    ld c, d
    ld a, $49
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld e, a
    rst $30
    ldh a, [$3c]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld d, b
    ld b, d
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$f0fb]
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ccf
    ld d, [hl]
    rst $28
    xor $50
    ld b, d
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld h, l
    ld [hl], $2e
    inc l
    cpl
    ld h, l
    ld e, a
    rst $30
    ldh a, [$3c]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, d
    ld a, $4b
    ld b, c
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, e
    ld b, d
    ld d, l
    ld d, c
    ld h, d
    ld b, c
    ld b, d
    ld b, e
    ld b, d
    ld c, e
    ld d, b
    ld b, d
    ld a, [$f0fb]
    rst $28
    xor $3f
    ld d, [hl]
    ld h, d
    ld d, b
    ld b, d
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $65
    daa
    jr z, jr_059_5bbd

    ld h, l
    ld e, a
    rst $30
    ldh a, [$ed]
    daa
    ld b, [hl]
    ld c, a
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, d
    ld sp, $5f4c
    ldh a, [$af]
    ld [$c0e8], a
    ld [$c0e9], a
    ld [$c0ea], a

jr_059_5bb1:
    ld a, [$c0e8]
    inc a
    ld [$c0e8], a
    ld bc, $ff9c
    add hl, bc
    ld a, h

jr_059_5bbd:
    rlc a
    jr nc, jr_059_5bb1

    ld bc, $0064
    add hl, bc
    ld a, [$c0e8]
    dec a
    ld [$c0e8], a

jr_059_5bcc:
    ld a, [$c0e9]
    inc a
    ld [$c0e9], a
    ld bc, $fff6
    add hl, bc
    ld a, h
    rlc a
    jr nc, jr_059_5bcc

    ld bc, $000a
    add hl, bc
    ld a, [$c0e9]
    dec a
    ld [$c0e9], a
    ld a, l
    ld [$c0ea], a
    ret


CalcB59_5bec:
    add hl, bc
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ret


CalcB59_5bf1:
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


    ld hl, $c621
    ld [hl], $e8
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ld hl, $c661
    ld [hl], $e0
    ld hl, $c627
    ld [hl], $e0
    ld hl, $c667
    ld [hl], $e0
    ld hl, $5005
    rst $10
    ld hl, $c0d9
    inc [hl]
    xor a
    ld [$c0db], a
    ret


    ld hl, $c621
    ld [hl], $e0
    ld hl, $c661
    ld [hl], $e8
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ld hl, $c627
    ld [hl], $e0
    ld hl, $c667
    ld [hl], $e0
    ld hl, $5005
    rst $10
    ld hl, $c0d9
    inc [hl]
    xor a
    ld [$c0db], a
    ret


    ld hl, $c621
    ld [hl], $e0
    ld hl, $c661
    ld [hl], $e0
    ld hl, $c627
    ld [hl], $e8
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ld hl, $c667
    ld [hl], $e0
    ld hl, $5005
    rst $10
    ld hl, $c0d9
    inc [hl]
    xor a
    ld [$c0db], a
    ret


    ld hl, $c621
    ld [hl], $e0
    ld hl, $c661
    ld [hl], $e0
    ld hl, $c627
    ld [hl], $e0
    ld hl, $c667
    ld [hl], $e8
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ld hl, $5005
    rst $10
    ld hl, $c0d9
    inc [hl]
    xor a
    ld [$c0db], a
    ret


SetB59_5ca0:
    ld hl, $c0db
    inc [hl]
    ld a, [$c0db]
    cp $0a
    jr z, jr_059_5cb0

    cp $14
    jr z, jr_059_5cbf

    ret


jr_059_5cb0:
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    ld [hl], $e0
    ld hl, $5005
    rst $10
    ret


jr_059_5cbf:
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    ld [hl], $e8
    ld hl, $5005
    rst $10
    xor a
    ld [$c0db], a
    ret


LoadB59_5cd2:
    ld a, [de]
    inc de
    ld c, a
    ld a, [de]
    inc de
    ld b, a
    add hl, bc

jr_059_5cd9:
    push hl

jr_059_5cda:
    ld a, [de]
    inc de
    cp $d8
    jr z, jr_059_5cea

    cp $d9
    jr z, jr_059_5cf5

    call Write_gfx_tile
    inc hl
    jr jr_059_5cda

jr_059_5cea:
    pop hl
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_059_5cd9

jr_059_5cf5:
    pop hl
    ret


SetB59_5cf7:
    ld hl, $ffbb
    inc [hl]
    call ApplyScrollRegisters
    ldh a, [$bb]
    cp $00
    ret


SetB59_5d03:
    ld hl, $ffbb
    dec [hl]
    call ApplyScrollRegisters
    ldh a, [$bb]
    cp $d8
    ret


LoadB59_5d0f:
    ld a, $aa
    ld l, a
    ld h, $00
    add hl, hl
    ld a, l
    add $9f
    ld l, a
    ld a, h
    adc $2b
    ld h, a
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld hl, $9000
    call WaitDMATransfer
    ret


CallB59_5d27:
    call LoadB59_5d4f
    ld de, $5ee2
    ld hl, $9b60
    call LoadB59_5cd2
    ld de, $5f11
    ld hl, $c500
    call LoadB59_5cd2
    ld de, $5d6c
    ld hl, $c500
    call LoadB59_5cd2
    ld de, $5dc4
    ld hl, $c500
    call LoadB59_5cd2
    ret


LoadB59_5d4f:
    ld a, $e0
    ld hl, $c500
    ld bc, $0240
    call FillNBytesWithRegA
    ret


MaskB59_5d5b:
    or a
    jr z, jr_059_5d68

    ld hl, $0000

jr_059_5d61:
    add hl, bc
    dec a
    jr nz, jr_059_5d61

    ld b, h
    ld c, l
    ret


jr_059_5d68:
    ld bc, $0000
    ret


    daa
    nop
    nop
    ld bc, $0302
    inc b
    dec b
    ret c

    ld b, $07
    ld [$0a09], sp
    dec bc
    ret c

    inc c
    dec c
    ld c, $0f
    db $10
    ld de, $12d8
    inc de
    inc d
    dec d
    ld d, $17
    ret c

    jr @+$1b

    ld a, [de]
    dec de
    inc e
    dec e
    ret c

    ld e, $1f
    jr nz, jr_059_5db6

    ld [hl+], a
    inc hl
    reti


    rst $00
    nop
    nop
    ld bc, $0302
    inc b
    dec b
    ret c

    ld b, $07
    ld [$0a09], sp
    dec bc
    ret c

    inc c
    dec c
    ld c, $0f
    db $10
    ld de, $12d8
    inc de
    inc d
    dec d
    ld d, $17
    ret c

jr_059_5db6:
    jr jr_059_5dd1

    ld a, [de]
    dec de
    inc e
    dec e
    ret c

    ld e, $1f
    jr nz, jr_059_5de2

    ld [hl+], a
    inc hl
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

jr_059_5dd1:
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

    cp $b0
    or c
    or d
    or e
    or h
    or l

jr_059_5de2:
    or [hl]
    or a
    cp b
    cp c
    cp d
    cp e
    cp h
    cp l
    cp [hl]
    cp a
    ret nz

    pop bc
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

    cp $c2
    jp $c5c4


    add $c7
    ret z

    ret


    jp z, $cccb

    call $cfce
    ret nc

    pop de
    jp nc, $ffd3

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

    cp $b0
    or c
    or d
    or e
    or h
    or l
    or [hl]
    or a
    cp b
    cp c
    cp d
    cp e
    cp h
    cp l
    cp [hl]
    cp a
    ret nz

    pop bc
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

    cp $c2
    jp $c5c4


    add $c7
    ret z

    ret


    jp z, $cccb

    call $cfce
    ret nc

    pop de
    jp nc, $ffd3

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
    ld l, h
    ld l, h
    add e
    ld a, h
    ldh [$e0], a
    ld l, l
    ld a, h
    ld l, [hl]
    ldh [rIE], a
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
    ld a, [hl]
    ld a, l
    ld a, a
    add d
    ldh [$e0], a
    add c
    add b
    ld l, a
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
    ldh [$e0], a
    rst $38
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
    ldh [$f1], a
    ld sp, hl
    ldh [$e0], a
    rst $38
    ret c

    cp $e2
    ldh [$e0], a
    ld a, [c]
    ldh [$e0], a
    rst $38
    reti


    nop
    nop
    db $fc
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


    ld h, b
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    add a
    ld a, h
    add b
    sbc h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sbc e
    ld a, l
    sbc l
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    adc d
    ld a, h
    sbc h
    adc e
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
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
    jp c, Jump_059_74e0

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
    jp c, Jump_059_74e0

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
    jr c, jr_059_63a7

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

jr_059_63a7:
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
    jr nz, jr_059_6536

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
    jr z, jr_059_655e

    ld a, [hl+]

jr_059_6536:
    dec hl
    inc l
    dec l
    ld l, $2f
    jr nc, jr_059_656e

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

jr_059_655e:
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

jr_059_656e:
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
    jr nc, jr_059_6615

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
    jr c, jr_059_6638

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

jr_059_6615:
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

jr_059_6638:
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


    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

Jump_059_734c:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

Jump_059_74e0:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
