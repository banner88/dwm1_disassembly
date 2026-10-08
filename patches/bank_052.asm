; =============================================================================
; BANK $52 — BATTLE SYSTEM, SKILL FUNCTIONS
; =============================================================================
; Contains:
;   - Skill Function Table at $4011 (222 entries, ids $00–$DD → handler addresses)
;   - Skill handler functions (115 unique handlers for 222 skills)
;   - Resistance check functions
;   - Battle damage calculation
;
; SKILL DISPATCH: Code at $6CC7 reads skill ID, looks up handler address
;   from SkillFunctionTable ($4011), and calls it. Many skills share handlers
;   (e.g., Blaze/Blazemore/Blazemost all point to $41CD).
;   (NB: older notes said "$4211" — that was wrong. $4211 is merely the first
;    instruction AFTER the 222-entry table; the real load `ld hl, SkillFunctionTable`
;    is at $6CC7.)
;
; Jump table entries (via rst $10 with H=$52):
;   Entry 0: $6C4D    Entry 4: $52C3
;   Entry 1: $76C8    Entry 5: $60D7
;   Entry 2: $7A18    Entry 6: $6A8A
;   Entry 3: $538F    Entry 7: $7EF1
;
; Sources: skill function table analysis, extracted/skill_records.json
;          (skills.json retired S59 — it read this 222-entry table as 256)
; =============================================================================

; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $052", ROMX[$4000], BANK[$52]


    db $52

    ; Bank $52 jump table (8 entries)
    dw $6C4D  ; Entry 0
    dw $76C8  ; Entry 1
    dw $7A18  ; Entry 2
    dw $538F  ; Entry 3
    dw $52C3  ; Entry 4
    dw $60D7  ; Entry 5
    dw $6A8A  ; Entry 6
    dw $7EF1  ; Entry 7

; ---------------------------------------------------------------
; Skill Function Table ($4011)
; 222 entries x 2 bytes = 444 bytes ($4011..$41CC), then handler code begins
; at SkillBlaze ($41CD) — the table's hard upper bound (verified S59).
; (Table entries for ids 222–255 do not exist; skills only run 0–221 = $00–$DD.)
; Maps skill ID -> handler function address within bank $52
; Referenced by code at $6CC7 via: ld hl, SkillFunctionTable
; ---------------------------------------------------------------

SkillFunctionTable:
    dw SkillBlaze  ; [  0] Blaze
    dw SkillBlaze  ; [  1] Blazemore
    dw SkillBlaze  ; [  2] Blazemost
    dw SkillFirebal  ; [  3] Firebal
    dw SkillFirebal  ; [  4] Firebane
    dw SkillFirebal  ; [  5] Firebolt
    dw SkillBang  ; [  6] Bang
    dw SkillBang  ; [  7] Boom
    dw SkillBang  ; [  8] Explodet
    dw SkillInfernos  ; [  9] Infernos
    dw SkillInfernos  ; [ 10] Infermore
    dw SkillInfernos  ; [ 11] Infermost
    dw SkillIceBolt  ; [ 12] IceBolt
    dw SkillIceBolt  ; [ 13] SnowStorm
    dw SkillIceBolt  ; [ 14] Blizzard
    dw SkillBolt  ; [ 15] Bolt
    dw SkillBolt  ; [ 16] Zap
    dw SkillBolt  ; [ 17] Thordain
    dw SkillBeat  ; [ 18] Beat
    dw SkillBeat  ; [ 19] Defeat
    dw SkillSacrifice  ; [ 20] Sacrifice
    dw SkillSleep  ; [ 21] Sleep
    dw SkillSleep  ; [ 22] SleepAll
    dw SkillStopSpell  ; [ 23] StopSpell
    dw SkillSurround  ; [ 24] Surround
    dw SkillPanicAll  ; [ 25] PanicAll
    dw SkillRobMagic  ; [ 26] RobMagic
    dw SkillTakeMagic  ; [ 27] TakeMagic
    dw SkillSap  ; [ 28] Sap
    dw SkillSap  ; [ 29] Defence
    dw SkillUpper  ; [ 30] Upper
    dw SkillUpper  ; [ 31] Increase
    dw SkillSlow  ; [ 32] Slow
    dw SkillSlow  ; [ 33] SlowAll
    dw SkillSpeed  ; [ 34] Speed
    dw SkillSpeed  ; [ 35] SpeedUp
    dw SkillBarrier  ; [ 36] Barrier
    dw SkillTwinHits  ; [ 37] TwinHits
    dw SkillMagicWall  ; [ 38] MagicWall
    dw SkillMagicBack  ; [ 39] MagicBack
    dw SkillMagicBack  ; [ 40] Bounce
    dw SkillTransform  ; [ 41] Transform
    dw SkillIronize  ; [ 42] Ironize
    dw SkillHeal  ; [ 43] Heal
    dw SkillHeal  ; [ 44] HealMore
    dw SkillHeal  ; [ 45] HealAll
    dw SkillHeal  ; [ 46] HealUs
    dw SkillHeal  ; [ 47] HealUsAll
    dw SkillVivify  ; [ 48] Vivify
    dw SkillVivify  ; [ 49] Revive
    dw SkillFarewell  ; [ 50] Farewell
    dw SkillAntidote  ; [ 51] Antidote
    dw SkillNumbOff  ; [ 52] NumbOff
    dw SkillDeChaos  ; [ 53] DeChaos
    dw SkillCurseOff  ; [ 54] CurseOff
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [ 55] StepGuard
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [ 56] MapMagic
    dw SkillChance  ; [ 57] Chance
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [ 58] Attack
    dw SkillPsycheUp_TwinSlash  ; [ 59] TwinSlash
    dw SkillRamming  ; [ 60] Ramming
    dw SkillBeserker  ; [ 61] Beserker
    dw SkillKamikaze  ; [ 62] Kamikaze
    dw SkillMassacre  ; [ 63] Massacre
    dw SkillMassacre  ; [ 64] EvilSlash
    dw SkillChargeUP  ; [ 65] ChargeUP
    dw SkillHighJump  ; [ 66] HighJump
    dw SkillSuckAir  ; [ 67] SuckAir
    dw SkillFireSlash  ; [ 68] FireSlash
    dw SkillBoltSlash  ; [ 69] BoltSlash
    dw SkillVacuSlash  ; [ 70] VacuSlash
    dw SkillIceSlash  ; [ 71] IceSlash
    dw SkillMetalCut  ; [ 72] MetalCut
    dw SkillDrakSlash  ; [ 73] DrakSlash
    dw SkillBeastCut  ; [ 74] BeastCut
    dw SkillBirdBlow  ; [ 75] BirdBlow
    dw SkillDevilCut  ; [ 76] DevilCut
    dw SkillZombieCut  ; [ 77] ZombieCut
    dw SkillCleanCut  ; [ 78] CleanCut
    dw SkillMultiCut  ; [ 79] MultiCut
    dw SkillBiAttack  ; [ 80] BiAttack
    dw SkillBiAttack  ; [ 81] QuadHits
    dw SkillCallHelp  ; [ 82] CallHelp
    dw SkillCallHelp  ; [ 83] YellHelp
    dw SkillFocus  ; [ 84] Focus
    dw SkillSquallHit  ; [ 85] SquallHit
    dw SkillPsycheUp_TwinSlash  ; [ 86] PsycheUp
    dw SkillRainSlash  ; [ 87] RainSlash
    dw SkillWindBeast  ; [ 88] WindBeast
    dw SkillWindBeast  ; [ 89] Vacuum
    dw SkillBolt  ; [ 90] Lightning
    dw SkillRockThrow  ; [ 91] RockThrow
    dw SkillFireAir  ; [ 92] FireAir
    dw SkillFireAir  ; [ 93] BlazeAir
    dw SkillFireAir  ; [ 94] Scorching
    dw SkillFireAir  ; [ 95] WhiteFire
    dw SkillFrigidAir  ; [ 96] FrigidAir
    dw SkillFrigidAir  ; [ 97] IceAir
    dw SkillFrigidAir  ; [ 98] IceStorm
    dw SkillFrigidAir  ; [ 99] WhiteAir
    dw SkillBolt  ; [100] Hellblast
    dw SkillBigBang  ; [101] BigBang
    dw SkillMegaMagic  ; [102] MegaMagic
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [103] PoisonHit
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [104] NapAttack
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [105] Paralyze
    dw SkillSleep  ; [106] SleepAir
    dw SkillPalsyAir  ; [107] PalsyAir
    dw SkillPoisonGas  ; [108] PoisonGas
    dw SkillPoisonGas  ; [109] PoisonAir
    dw SkillPanicAll  ; [110] PaniDance
    dw SkillCurse  ; [111] Curse
    dw SkillAhhh  ; [112] Ahhh
    dw SkillBeat  ; [113] K.O.Dance
    dw SkillSandStorm  ; [114] SandStorm
    dw SkillSandStorm  ; [115] Radiant
    dw SkillEerieLite  ; [116] EerieLite
    dw SkillOddDance  ; [117] OddDance
    dw SkillRobMagic  ; [118] RobDance
    dw SkillSideStep  ; [119] SideStep
    dw SkillLureDance  ; [120] LureDance
    dw SkillLushLicks  ; [121] LushLicks
    dw SkillLushLicks  ; [122] SickLick
    dw SkillLegSweep  ; [123] LegSweep
    dw SkillLegSweep  ; [124] BigTrip
    dw SkillWarCry  ; [125] WarCry
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [126] Whistle
    dw SkillImitate  ; [127] Imitate
    dw SkillDeMagic_ThickFog  ; [128] DeMagic
    dw SkillSurge  ; [129] Surge
    dw SkillUltraDown  ; [130] UltraDown
    dw SkillDeMagic_ThickFog  ; [131] ThickFog
    dw SkillTatsuCall  ; [132] TatsuCall
    dw SkillTatsuCall  ; [133] DiagoCall
    dw SkillTatsuCall  ; [134] SamsiCall
    dw SkillTatsuCall  ; [135] BazooCall
    dw SkillCover  ; [136] Cover
    dw SkillCover  ; [137] Guardian
    dw SkillTailWind  ; [138] TailWind
    dw SkillTailWind  ; [139] StormWind
    dw SkillDodge  ; [140] Dodge
    dw SkillBladeD_Defense  ; [141] Defence
    dw SkillBladeD_Defense  ; [142] StrongD
    dw SkillSuckAll  ; [143] SuckAll
    dw SkillBladeD_Defense  ; [144] BladeD
    dw SkillDanceShut  ; [145] DanceShut
    dw SkillMouthShut  ; [146] MouthShut
    dw SkillMeditate  ; [147] Meditate
    dw SkillHeal  ; [148] Hustle
    dw SkillLifeSong  ; [149] LifeSong
    dw SkillLifeDance  ; [150] LifeDance
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [151] Run
    dw SkillDaze  ; [152] Daze
    dw SkillHitAlly  ; [153] HitAlly
    dw SkillHitEnemy  ; [154] HitEnemy
    dw SkillHitRandom  ; [155] HitRandom
    dw SkillScared  ; [156] Scared
    dw SkillScared  ; [157] Dance
    dw SkillTrip  ; [158] Trip
    dw SkillParalyze  ; [159] Paralyze
    dw SkillParalyze  ; [160] CANTMOVE
    dw SkillRUN  ; [161] RUN
    dw SkillSmashed  ; [162] CALLHOROR
    dw SkillHealUsAll  ; [163] HealUsAll
    dw SkillSmashed  ; [164] Smashed
    dw SkillDeMagic_ThickFog  ; [165] FILTHZONE
    dw SkillALLCHANGE  ; [166] ALLCHANGE
    dw SkillBIGSLEEP  ; [167] BIGSLEEP
    dw SkillMP0  ; [168] MP0
    dw SkillScared  ; [169] ECHO
    dw SkillBeDragon  ; [170] CHGDRAGON
    dw SkillCALLEVIL  ; [171] CALLEVIL
    dw SkillFREEZY  ; [172] FREEZY
    dw SkillVivify  ; [173] ALLREVIVE
    dw SkillRESTOREMP  ; [174] RESTOREMP
    dw SkillMETEOR  ; [175] METEOR
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [176] HERB
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [177] HEALWATER
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [178] SAGESTONE
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [179] WARLDDEW
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [180] POTION
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [181] ELFWATER
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [182] ANTIDOTE
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [183] MOONHERB
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [184] SKYBELL
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [185] LAUREL
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [186] AWAKESAND
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [187] WARLDLEAF
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [188] LIFEACORN
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [189] MYSTICNUT
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [190] PWRSEED
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [191] DEFSEED
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [192] AGILSEED
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [193] INTSEED
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [194] FEEDMEAT
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [195] BEFFJERKY
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [196] PORKCHOP
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [197] BADMEAT
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [198] SIRLOIN
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [199] BOLTSTAFF
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [200] STAFF
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [201] BLOKSTAFF
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [202] LAVASTAFF
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [203] SNOWSTAFF
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [204] FIRESTAFF
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [205] WARPWING
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [206] TINYMEDAL
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [207] QuestBk
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [208] HORRORBK
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [209] BENICEBK
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [210] CHEATERBK
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [211] SMARTBK
    dw SkillPoisonHit_StepGuard_Whistle_Attack  ; [212] COMEDYBK
    dw SkillBeDragon  ; [213] BeDragon
    dw SkillSmashlime  ; [214] Smashlime
    dw SkillSheldodge  ; [215] Sheldodge
    dw SkillBranching  ; [216] Branching
    dw SkillGigaSlash  ; [217] GigaSlash
    dw SkillPanicAll  ; [218] LIFE
    dw SkillRUN  ; [219] RUN
    dw SkillIRONIZE  ; [220] IRONIZE
    dw SkillAhhh2  ; [221] Ahhh

; ---------------------------------------------------------------
; Skill Handler Functions
; Table entries 222-255 overlap with the first 7 handlers below
; (skills 222+ don't exist so those table entries are never read)
; ---------------------------------------------------------------

SkillBlaze:
    call $5BFF
    call $54E7
    ret

SkillFirebal:
    call $5C0D
    call $54E7
    ret

SkillBang:
    call $5C1B
    call $54E7
    ret

SkillInfernos:
    call $5C27
    call $54E7
    ret

SkillIceBolt:
    call $5C43
    call $54E7
    ret

SkillBolt:
    call $5C35
    call $54E7
    ret

; [S130 F1] Beat $12 / Defeat $13 / K.O.Dance $71: no "already" test; HitDeath_5c51
; (BossProtectionGate per victim, then res type 8 on HitLadderBeat_6749 for
; ids < $72); hit -> $DD1B:=1, HP:=0 and the KO state wipes $DB02+8t..+9
; (KOStatusWipe_4c26). Measured S130 (simulator/f1_status_events.json.gz).
SkillBeat:  ; $41F7
    xor a
    ld [$d9f0], a
    call $5C51
    jr nc, BtlOutcomeMissPath_4225
    ld a, [wBattleTargetIdx]
    ld hl, $dd1b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $01
    ld hl, $b8e8
    call LoadBattle_54af
    push hl
    ld a, [wBattleTargetIdx]
    ld hl, wBattleHP
    call HL_AddA_x2
    ld a, $00
    ld [hl+], a
    ld [hl], $00
    pop hl
    ret

BtlOutcomeMissPath_4225:
    ld a, $b8
    call ApplySkillDamage
    ret

SkillSacrifice:


    ld a, $03
    ld [$d9ed], a
    xor a
    ld [$d9ee], a
    ret

; [S130 F1] Sleep $15 / SleepAll $16 / SleepAir $6A: victim +2 & $8C -> msg $BD,
; no roll; else SetHLBattle_5c8f (res 7; $DB42 bit2 sure hit; only $15 rolls
; ladder B $6710, $16/$6A roll the status ladder $6749) -> +2 |= $8C.
SkillSleep:


    ld hl, $c180
    ld a, l
    ld [$db4e], a
    ld a, h
    ld [$db4f], a
    ld a, [wBattleTargetIdx]
    ld [$db50], a
    call CheckTargetInRange
    ld a, [wBattleTargetIdx]
    ld hl, $db02
    call HL_AddA_x8
    ld a, [hl]
    and $8c
    jr nz, jr_052_4276

    call SetHLBattle_5c8f
    jr nc, jr_052_4270

    ld hl, $bccc
    call LoadBattle_54d2

BattleTarget_4262:
    ld a, [wBattleTargetIdx]
    ld hl, $db02
    call HL_AddA_x8
    ld a, [hl]
    or $8c
    ld [hl], a
    ret


jr_052_4270:
    ld a, $bc
    call ApplySkillDamage
    ret


jr_052_4276:
    ld a, $bd
    call BattleFunc_5475
    ret

; [S130 F1] +3 bit0 already -> no roll; SetHLBattle_5cbc (res 10, ladder B).
SkillStopSpell:


    ld a, [wBattleTargetIdx]
    ld hl, $db03
    call HL_AddA_x8
    bit 0, [hl]
    jr nz, jr_052_42a0

    call SetHLBattle_5cbc
    jr nc, jr_052_42a4

    ld a, [wBattleTargetIdx]
    ld hl, $db03
    call HL_AddA_x8
    set 0, [hl]
    ld hl, $b888
    call LoadBattle_54d2
    ret


jr_052_42a0:
    call SetSkillAnimFlag
    ret


jr_052_42a4:
    ld a, $b8
    call ApplySkillDamage
    ret

; [S130 F1] +3 bit1 already -> no roll; SetHLBattle_5cda (res 6, ladder B).
SkillSurround:


    ld a, [wBattleTargetIdx]
    ld hl, $db03
    call HL_AddA_x8
    bit 1, [hl]
    jr nz, jr_052_42ce

    call SetHLBattle_5cda
    jr nc, jr_052_42d2

    ld a, [wBattleTargetIdx]
    ld hl, $db03
    call HL_AddA_x8
    set 1, [hl]
    ld hl, $b898
    call SetSkillAnimB
    ret


jr_052_42ce:
    call SetSkillAnimFlag
    ret


jr_052_42d2:
    ld a, $b8
    call ApplySkillDamage
    ret

; [S130 F1] PanicAll $19 / PaniDance $6E / LIFE $DA: +2 bit4 already -> msg $BE;
; HitConfuse_5d05 (res 11, $DB42 bit2 sure hit, status ladder $6749) -> +2 |= $10.
SkillPanicAll:


    ld a, [wBattleTargetIdx]
    ld hl, $db02
    call HL_AddA_x8
    bit 4, [hl]
    jr z, jr_052_42eb

    ld a, $be
    call BattleFunc_5475
    ret


jr_052_42eb:
    call SetHLBattle_5d05
    jr nc, jr_052_4302

    ld a, [wBattleTargetIdx]
    ld hl, $db02
    call HL_AddA_x8
    set 4, [hl]
    ld hl, $b88e
    call LoadBattle_54af
    ret


jr_052_4302:
    ld a, $b8
    call ApplySkillDamage
    ret

; [S130 F5] RobMagic $1A / RobDance $76: target MP 0 -> msg $BB (no roll);
; SetHLBattle_5d25 hit roll; BattleCall_5d48 drains min(MP, lvl/4+5) and
; gives it to the caster capped at MaxMP (validate_f5.py, 30 casts).
SkillRobMagic:


    ld a, [wBattleTargetIdx]
    ld hl, wBattleMP
    call HL_AddA_x2
    ld a, [hl+]
    or [hl]
    jr z, jr_052_432a

    call SetHLBattle_5d25
    jr nc, jr_052_4324

    call BattleCall_5d48
    ld hl, $b88a
    call LoadBattle_54af
    ret


jr_052_4324:
    ld a, $b8
    call ApplySkillDamage
    ret


jr_052_432a:
    ld a, $bb
    call ApplySkillDamage
    ret

; [S130 F6] TakeMagic $1B: own +4 bit0 (already -> no-effect anim). Consumer: $53 TakeMagicGain_5cbc
; [S130 F6] (effect player, landed flags9-bit0 skill) + TakeMagicApply_5ffa (act state 5): the
; [S130 F6] target gains MP = min(record MP cost, MaxMP-MP). Damage is NOT soaked. Persists (phase 9
; [S130 F6] keeps +4 bits 6:0). Measured S130 (simulator/validate_f6.py takemagic/tm_occur).
SkillTakeMagic:


    ld a, [wBattleAttackerIdx]
    ld hl, $db04
    call HL_AddA_x8
    bit 0, [hl]
    jr nz, jr_052_4346

    set 0, [hl]
    ld hl, $8c00
    call LoadBattle_54a1
    ret


jr_052_4346:
    call SetSkillAnimFlag
    ret

; [S130 F7] Sap $1C / Defence $1D: SapHitRoll_5dcc (res 12) then StatDefDown_5dfc;
; [S130 F7] hit -> target $DB08+8t bit7 (lowered); msg $BB = DEF<=1, $B8 = roll missed.
SkillSap:


    call SapHitRoll_5dcc
    jr nc, jr_052_4367

    call StatDefDown_5dfc
    jr nc, jr_052_4361

    ld a, [wBattleTargetIdx]
    call SetStatLoweredMark_5377
    ld hl, $b886
    call LoadBattle_54af
    ret


jr_052_4361:
    ld a, $bb
    call BattleFunc_5475
    ret


jr_052_4367:
    ld a, $b8
    call ApplySkillDamage
    ret

; [S130 F7] Upper $1E / Increase $1F (tm 33/34): StatDefUp_5e3e, NO roll; target
; [S130 F7] $DB08+8t bit6 (raised); msg $BB = at 999 / at the cap. (No ATK buff exists.)
SkillUpper:


    call StatDefUp_5e3e
    jr nc, jr_052_437f

    ld hl, $9292
    call SetSkillAnimB
    ld a, [wBattleTargetIdx]
    call SetStatRaisedMark_536c
    ret


jr_052_437f:
    ld a, $bb
    call BattleFunc_5475
    ret

; [S130 F7] Slow $20 / SlowAll $21: SlowHitRoll_5e94 (res 13) then StatAglDown_5eb4; bit7.
SkillSlow:


    call SlowHitRoll_5e94
    jr nc, jr_052_43a2

    call StatAglDown_5eb4
    jr nc, jr_052_439c

    ld a, [wBattleTargetIdx]
    call SetStatLoweredMark_5377
    ld hl, $b895
    call LoadBattle_54af
    ret


jr_052_439c:
    ld a, $bb
    call BattleFunc_5475
    ret


jr_052_43a2:
    ld a, $b8
    call ApplySkillDamage
    ret

; [S130 F7] Speed $22 / SpeedUp $23: StatAglUp_5f08, NO roll; bit6; msg $BB at 511 / cap.
SkillSpeed:


    call StatAglUp_5f08
    jr nc, jr_052_43ba

    ld hl, $9797
    call SetSkillAnimB
    ld a, [wBattleTargetIdx]
    call SetStatRaisedMark_536c
    ret


jr_052_43ba:
    ld a, $bb
    call BattleFunc_5475
    ret

; [S130 F6] Barrier $24: the 4 slots of the TARGET side (incl. 3/7): live -> +4 |= 4 (counted when
; [S130 F6] new), dead -> +4 bit2 cleared; none new -> no-effect anim. Consumer: BarrierHalveBreath_5539
; [S130 F6] (FireAir/FrigidAir >> 1, F23). Persists. Measured S130 (setter).
SkillBarrier:


    ld a, [wBattleTargetIdx]
    and $04
    ld c, a
    ld b, $04
    ld d, $00

jr_052_43ca:
    ld a, c
    ld hl, $db04
    call HL_AddA_x8
    ld a, c
    call CheckMonsterSlot
    jr c, jr_052_43f3

    bit 2, [hl]
    jr nz, jr_052_43de

    inc d
    set 2, [hl]

jr_052_43de:
    inc c
    dec b
    jr nz, jr_052_43ca

    ld a, d
    or a
    jr z, jr_052_43f7

    ld hl, $5803
    rst $10
    ld a, [$dd72]
    add $09
    call BattleFunc_5481
    ret


jr_052_43f3:
    res 2, [hl]
    jr jr_052_43de

jr_052_43f7:
    call SetSkillAnimFlag
    ret

; [S130 F4] TwinHits $25: TARGET +3 bit2 (fail anim when already set); the
; flags8-bit5 hits of that monster skip the crit roll and do x2 at $53:$5912.
; Persistent (phase 9 does not clear +3). Measured 14 sets, 58 doublings.
SkillTwinHits:


    ld a, [wBattleTargetIdx]
    ld hl, $db03
    call HL_AddA_x8
    bit 2, [hl]
    jr nz, jr_052_4411

    set 2, [hl]
    ld hl, $9090
    call SetSkillAnimA
    ret


jr_052_4411:
    call SetSkillAnimFlag
    ret

; [S130 F6] MagicWall $26: the CASTER side live slots +5 |= $40 = the guard row of every resistance
; [S130 F6] ladder (spell damage and status hit). Persists (+5 bits 7:6 survive phase 9).
SkillMagicWall:


    ld a, [wBattleAttackerIdx]
    and $04
    ld c, a
    ld b, $03

jr_052_441d:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_052_442c

    ld a, c
    ld hl, $db05
    call HL_AddA_x8
    set 6, [hl]

jr_052_442c:
    inc c
    dec b
    jr nz, jr_052_441d

    call SetSkillAnimFlag
    ret

; [S130 F6] MagicBack $27 / Bounce $28: +4 := (+4 & $DD) | $20 / $02 (each replaces the other; fails
; [S130 F6] msg $BB when its own bit is set). Consumers MagicBackReflect_55ca / MagicBackReflect2_690e:
; [S130 F6] a flags8-bit0 skill aimed at the holder is re-run by the HOLDER on the caster
; [S130 F6] (ReflectRecast_5e38 code 4); Bounce persists, MagicBack bit5 is consumed. Measured S130.
SkillMagicBack:


    ld a, [wBattleAttackerIdx]
    ld hl, $db04
    call HL_AddA_x8
    ld a, [$db8a]
    cp $28
    jr z, jr_052_4455

    bit 5, [hl]
    jr nz, jr_052_4466

    ld a, [hl]
    and $dd
    or $20
    ld [hl], a
    ld hl, $9999
    call SetSkillAnimA
    ret


jr_052_4455:
    bit 1, [hl]
    jr nz, jr_052_4466

    ld a, [hl]
    and $dd
    or $02
    ld [hl], a
    ld hl, $9a9a
    call SetSkillAnimB
    ret


jr_052_4466:
    ld a, $bb
    call BattleFunc_5475
    ret

; [S130 F7] Transform $29: own $DB08+8t |= $C0 (both markers); act state 5
; [S130 F7] (jr_052_6d20) then runs TransformCopyStats_5f5e + own +3 bit5.
SkillTransform:


    ld a, [wBattleAttackerIdx]
    call SetStatBothMarks_5382
    ld hl, $a0a0
    call SetSkillAnimA
    ret

SkillIRONIZE:


    ld a, [wBattleAttackerIdx]
    ld [wBattleTargetIdx], a

SkillIronize:
    ld a, [$c86c]
    or a
    jr nz, jr_052_449c

    ld a, [wBattleTargetIdx]
    bit 2, a
    jr z, jr_052_449c

    ld hl, $db07
    call HL_AddA_x8
    push hl
    pop hl
    ld b, $01
    ld a, [wBattleTargetIdx]
    ld c, a
    jr jr_052_44aa

jr_052_449c:
    ld b, $04
    ld a, [wBattleTargetIdx]
    and $04
    ld c, a
    ld hl, $db07
    call HL_AddA_x8

jr_052_44aa:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_052_44b4

    ld a, [hl]
    or $c0
    ld [hl], a

jr_052_44b4:
    ld a, $08
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    inc c
    dec b
    jr nz, jr_052_44aa

    call LoadBattle_5506
    ret


; [S130 F5] SkillHeal (Heal/HealMore/HealAll/HealUs/HealUsAll/Hustle; $A3
; via SkillHealUsAll): non-live target or HP == MaxHP -> msg $BB; else
; LoadBattle_607d heals (record roll, side fields by StoreDamageResult; FULL
; MaxHP for $2D/$2F/$32/$96). Apply skips the subtract (id < $3A / $94).
; Measured S130: 475 per-victim outcomes, simulator/validate_f5.py.
SkillHeal:
    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    jr nc, jr_052_44d2

jr_052_44cc:
    ld a, $bb
    call ApplySkillDamage
    ret


jr_052_44d2:
    ld a, [wBattleTargetIdx]
    ld hl, wBattleHP
    call HL_AddA_x2
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld a, $0f
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call CmpHLvsBC
    jr z, jr_052_44cc

    call LoadBattle_607d
    ld hl, $bb84
    call LoadBattle_54f8
    ret


; [S130 F5] Vivify $30 / Revive $31 / ALLREVIVE $AD. Target invalid ->
; no effect; LIVE -> Vivify fails ($BB), Revive/ALLREVIVE re-target to the
; FIRST dead own slot from the base (queue byte + wBattleTargetIdx — the
; group loop then continues from it); dead -> Vivify 1 BattleRNG step,
; RNG1 >= $80 fails (msg $C0). HP := MaxHP (/2 for $30), SaveBattle_51dd.
SkillVivify:
    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    jr nc, jr_052_456d

    jr z, jr_052_457a

    ld a, [$db8a]
    cp $30
    jr nz, jr_052_453a

    call BattleRNG
    ld a, [wRNG1]
    cp $80
    jr nc, jr_052_4567

    jr jr_052_453a

jr_052_4515:
    ld a, [wBattleAttackerIdx]
    and $04
    ld c, a
    or $03
    ld b, a

jr_052_451e:
    ld a, c
    call CheckMonsterSlot
    jr z, jr_052_4526

    jr c, jr_052_452d

jr_052_4526:
    inc a
    ld c, a
    cp b
    jr c, jr_052_451e

    jr jr_052_4574

jr_052_452d:
    ld [wBattleTargetIdx], a
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    call HL_AddA_x2
    ld [hl], c

jr_052_453a:
    ld a, [wBattleTargetIdx]
    ld b, a
    ld hl, wBattleMaxHP
    call HL_AddA_x2
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    ld a, [$db8a]
    cp $30
    jr nz, jr_052_4552

    srl d
    rr e

jr_052_4552:
    ld a, b
    ld hl, wBattleHP
    call HL_AddA_x2
    ld a, e
    ld [hl+], a
    ld [hl], d
    ld a, b
    call SaveBattle_51dd
    ld hl, $9e9e
    call SetSkillAnimA
    ret


jr_052_4567:
    ld a, $c0
    call ApplySkillDamage
    ret


jr_052_456d:
    ld a, [$db8a]
    cp $30
    jr nz, jr_052_4515

jr_052_4574:
    ld a, $bb
    call ApplySkillDamage
    ret


jr_052_457a:
    call SetSkillAnimFlag
    ret

; [S130 F5] Farewell $32: act state 4 with $DD72 = 0 -> the bank $53
; entry-14 chain ($53:$6A9B, LifeChain*): revive + full-heal every other own
; slot, caster pays all HP (RNG1 < $7F) or keeps HP/100, then MP := 0.
SkillFarewell:


    ld a, $04
    ld [$d9ed], a
    xor a
    ld [$d9ee], a
    ld [$dd72], a
    xor a
    ld [$d9ef], a
    ret

; [S130 F5] Antidote $33: target +2 & 3 -> cleared (poison + heavy DoT), else $BB.
SkillAntidote:


    call LoadBattle_519e
    and $03
    jr z, jr_052_45a1

    ld a, [hl]
    and $fc
    ld [hl], a
    ld hl, $9c9c
    call SetSkillAnimA
    ret


jr_052_45a1:
    ld a, $bb
    call ApplySkillDamage
    ret

; [S130 F5] NumbOff $34 (all allies): +2 & $CC -> +2 &= $33 (paralysis + sleep
; flag/counter) and $DD13[target] := 3 (the cured slot has used its turn).
SkillNumbOff:


    call LoadBattle_519e
    and $cc
    jr z, jr_052_45d2

    push hl
    bit 6, [hl]
    jr z, jr_052_45b8

    ld hl, $9d9d
    jr jr_052_45bb

jr_052_45b8:
    ld hl, $dbdb

jr_052_45bb:
    call SetSkillAnimA
    pop hl
    ld a, [hl]
    and $33
    ld [hl], a
    ld a, [wBattleTargetIdx]
    ld hl, $dd13
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $03
    ret


jr_052_45d2:
    ld a, $bb
    call ApplySkillDamage
    ret

; [S130 F5] DeChaos $35 (all allies): +2 bit4 -> cleared, $DD13[target] := 3.
SkillDeChaos:


    call LoadBattle_519e
    and $10
    jr z, jr_052_45f8

    ld a, [hl]
    and $ef
    ld [hl], a
    ld a, [wBattleTargetIdx]
    ld hl, $dd13
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $03
    ld hl, $dcdc
    call SetSkillAnimA
    ret


jr_052_45f8:
    ld a, $bb
    call ApplySkillDamage
    ret

; [S130 F5] CurseOff $36 (all allies): +2 bit5 -> cleared, else $BB.
SkillCurseOff:


    call LoadBattle_519e
    and $20
    jr z, jr_052_4610

    ld a, [hl]
    and $df
    ld [hl], a
    ld hl, $9f9f
    call SetSkillAnimA
    ret


jr_052_4610:
    ld a, $bb
    call ApplySkillDamage
    ret

; [S130 F9] Chance $39 (row $63D6 self; the MISS machine ran on its target):
; ChancePick_4d7e ($53 entry 3) rewrites the queue to $A0+n and restarts the act
; machine at state 1 with the new id (target fetch, iron gate, MISS, handler).
SkillChance:


    ld hl, $5303
    rst $10
    ld a, $00
    ld [$dd6b], a
    ld a, $01
    ld [$d9ed], a
    ret

SkillPoisonHit_StepGuard_Whistle_Attack:


    call CalcDefenseWrapper
    ld hl, $b682
    call CheckSkillResistance
    ret

SkillPsycheUp_TwinSlash:


    call CalcDefenseWrapper
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    call SetupBattle_6979
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ld hl, $b682
    call CheckSkillResistance
    ret

SkillRamming:


    call BattleTarget_6214
    call SetHLBattle_54e7
    ret

; [S130 F23] Beserker: sets its OWN guard record $DB08+8a bit2, then x2. The
; mark makes physical hits ON the user x2 for the rest of the round (bank $53
; BeserkerTakenX2_5a44, not $3C/$3E; cleared in phase 9) and halves its DEF in
; the AI HP+DEF target score ($58:LoadBtlFX_43aa). Measured S130.
SkillBeserker:


    ld a, [wBattleAttackerIdx]
    ld hl, $db08
    call HL_AddA_x8
    set 2, [hl]
    call CalcDefenseWrapper
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    sla l
    rl h
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ld hl, $b682
    call CheckSkillResistance
    ret

SkillKamikaze:


    call KamikazeDamage_6232
    call SetHLBattle_54e7
    ret

; [S130 F4] Massacre $3F / EvilSlash $40: dead target -> fail; Massacre -> own
; +4 bit7 = a forced crit built at $53:$5941 from ATK (RNG as found, no step);
; EvilSlash: incapacitated target (GetMonsterSlotInfo) or RNG1 >= $A0 (the
; MISS step's state, no step) -> the same crit, else msg $78 and no apply.
; Measured 90/90 outcomes.
SkillMassacre:


    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    jr c, jr_052_46b4

    ld a, [$db8a]
    cp $3f
    jr z, jr_052_46a2

    ld a, [wBattleTargetIdx]
    call GetMonsterSlotInfo
    jr c, jr_052_46a2

    ld b, $a0
    ld a, [wRNG1]
    cp b
    jr c, jr_052_46b8

MassacreCritSet_46a2:
jr_052_46a2:
    ld a, [wBattleAttackerIdx]
    ld hl, $db04
    call HL_AddA_x8
    set 7, [hl]
    ld hl, $b682
    call CheckSkillResistance
    ret


jr_052_46b4:
    call SetSkillAnimFlag
    ret


EvilSlashFail_46b8:
jr_052_46b8:
    ld a, $78
    call ApplySkillDamage
    ret

SkillChargeUP:


    ld a, [wBattleAttackerIdx]
    ld hl, $db06
    call HL_AddA_x8
    ld a, [hl]
    or $03
    ld [hl], a
    call SetSkillAnimFlag
    ret

SkillHighJump:


    ld a, [wBattleAttackerIdx]
    ld hl, $db06
    call HL_AddA_x8
    ld a, [hl]
    and $0c
    jr nz, jr_052_46ee

    ld a, [hl]
    or $0c
    ld [hl], a
    call SetSkillAnimFlag
    xor a
    ld [$d9ee], a
    ld a, $06
    ld [$d9ed], a
    ret


; [S130 F4] HighJump landing: +6 &= $F3 (after the MISS machine passed),
; CalcSkillDefense x1.5 (SetupBattle_6979). A missed/dodged landing leaves the
; bits to the phase-9 rotate ($04 -> 0). Measured 18 landings, 43 take-offs.
HighJumpLanding_46ee:
jr_052_46ee:
    ld a, [hl]
    and $f3
    ld [hl], a
    call CalcDefenseWrapper
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    call SetupBattle_6979
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ld hl, $b682
    call CheckSkillResistance
    ret

SkillSuckAir:


    ld a, [wBattleAttackerIdx]
    ld hl, $db06
    call HL_AddA_x8
    ld a, [hl]
    or $30
    ld [hl], a
    call SetSkillAnimFlag
    ret

SkillFireSlash:


    call BattleCall_6298
    ld hl, $b682
    call CheckSkillResistance
    ret

SkillBoltSlash:


    call BattleCall_62a9
    ld hl, $b682
    call CheckSkillResistance
    ret

SkillVacuSlash:


    call BattleCall_62ba
    ld hl, $b682
    call CheckSkillResistance
    ret

SkillIceSlash:


    call BattleCall_62cb
    ld hl, $b682
    call CheckSkillResistance
    ret

SkillMetalCut:


    call BattleCall_62dc
    ld hl, $b682
    call CheckSkillResistance
    ret

SkillDrakSlash:


    call CheckIsDragon
    ld hl, $b682
    call CheckSkillResistance
    ret

SkillBeastCut:


    call CheckIsBeast
    ld hl, $b682
    call CheckSkillResistance
    ret

SkillBirdBlow:


    call CheckIsFlying
    ld hl, $b682
    call CheckSkillResistance
    ret

SkillDevilCut:


    call CheckIsDevil
    ld hl, $b682
    call CheckSkillResistance
    ret

SkillZombieCut:


    call CheckIsZombie
    ld hl, $b682
    call CheckSkillResistance
    ret

SkillCleanCut:


    call CheckIsMaterial
    ld hl, $b682
    call CheckSkillResistance
    ret

SkillMultiCut:


    call LoadBattle_6381
    ld hl, $b682
    call CheckSkillResistance
    ret

; [S130 F8] BiAttack $50 / QuadHits $51: ATK temporarily := ATK/2+ATK/4
; (SaveBattle_69c6) / ATK/2+ATK/8 (QuadHits, target re-read from $DCED) for
; ONE CalcSkillDefense, then restored. Runs once per pass of the multi-hit
; loop (continuations $6F83 / $6F71). Measured S130 (validate_f8_multihit).
SkillBiAttack:


    ld a, [$db8a]
    cp $51
    jr z, jr_052_47ac

    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    call c, SetHLBattle_4807
    ld d, $00
    jr jr_052_47bb

jr_052_47ac:
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    call HL_AddA_x2
    ld a, [hl]
    ld [wBattleTargetIdx], a
    ld d, $01

jr_052_47bb:
    ld a, [wBattleAttackerIdx]
    ld hl, wBattleATK
    call HL_AddA_x2
    ld a, l
    ld [$db63], a
    ld a, h
    ld [$db64], a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    push hl
    ld a, d
    or a
    jr nz, jr_052_47d9

    call SaveBattle_69c6
    jr jr_052_47e2

jr_052_47d9:
    call HLsrl1
    ld b, h
    ld c, l
    call BCsrl2
    add hl, bc

jr_052_47e2:
    ld a, [$db63]
    ld c, a
    ld a, [$db64]
    ld b, a
    ld a, l
    ld [bc], a
    inc bc
    ld a, h
    ld [bc], a
    call CalcDefenseWrapper
    pop hl
    ld a, [$db63]
    ld c, a
    ld a, [$db64]
    ld b, a
    ld a, l
    ld [bc], a
    inc bc
    ld a, h
    ld [bc], a
    ld hl, $b682
    call CheckSkillResistance
    ret


; [S130 F8] SkillBiAttack's own dead-target fallback = bank $58 entry 10
; ($41E9, the plain-attack resolver). Unreachable in practice: act state 9
; ($53:$56A8) sends a dead target to the continuation before the handler.
SetHLBattle_4807:
    ld hl, $580a
    rst $10
    ret

; [S130 F8] CallHelp $52 / YellHelp $53. Pass 1 ($DD69==1): one BattleRNG
; step, RNG1 bit0 clear -> fail ($DD69:=$FF, msg $C2, no apply); set -> msg
; $A1, own +8 bit0, $DD69:=$0F (+1 non-link enemy caster, +1 more YellHelp),
; d9ef:=3/d9ee:=0 = straight back to the target fetch (NO continuation, no
; re-pick: helper 1 hits the queued target). Later passes: target $DCED,
; damage LoadBattle_63dc. Measured S130 (223 rolls, both sides).
SkillCallHelp:


    ld a, [$dd69]
    cp $01
    jr nz, jr_052_486b

    call BattleRNG
    ld a, [wRNG1]
    and $01
    jr z, jr_052_4859

    ld a, $03
    ld [$d9ef], a
    ld a, $0f
    ld [$dd69], a
    xor a
    ld [$d9ee], a
    ld [$c822], a
    ld a, $a1
    ld [$c823], a
    ld hl, $4c00
    rst $10
    ld a, [wBattleAttackerIdx]
    ld hl, $db08
    call HL_AddA_x8
    set 0, [hl]
    ld a, [$c86c]
    or a
    ret nz

    ld a, [wBattleAttackerIdx]
    cp $04
    ret c

    ld hl, $dd69
    inc [hl]
    ld a, [$db8a]
    cp $52
    ret z

    inc [hl]
    ret


jr_052_4859:
    ld a, $ff
    ld [$dd69], a
    xor a
    ld [$db56], a
    ld [$db57], a
    ld a, $c2
    call ApplySkillDamage
    ret


jr_052_486b:
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    call HL_AddA_x2
    ld a, [hl]
    ld [wBattleTargetIdx], a
    call CheckMonsterSlot
    jp c, Jump_052_50f8

    call LoadBattle_63dc
    ld hl, $b682
    call CheckSkillResistance
    ret

; [S130 F4] Focus $54: the phase-9 rotate turns bit7 into bit6 for the NEXT
; round, consumed at the end of that round's action by FocusFollowUp_6f5b:
; a flags9-bit4 skill acts AGAIN (measured 20/20; the old 'writer not found').
SkillFocus:


    ld a, [wBattleAttackerIdx]
    ld hl, $db06
    call HL_AddA_x8
    set 7, [hl]
    call SetSkillAnimFlag
    ret

SkillSquallHit:


    call CalcDefenseWrapper
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    call DamageMul8Tenths_69b7
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ld hl, $b682
    call CheckSkillResistance
    ret

; [S130 F8] $DD69 counts real target fetches only: the continuation $6FD4
; walks past dead slots without touching it, so a dead slot does not shift
; the x.8/.6/.4 ladder (measured); with 3 slots per side the 4th hit needs
; a live helper slot 3/7.
SkillRainSlash:


    ld a, [$dd69]
    cp $05
    jr nc, jr_052_4914

    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    jr c, jr_052_48f5

    call CalcDefenseWrapper
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    ld a, [$dd69]
    cp $01
    jr z, jr_052_48de

    cp $02
    jr z, jr_052_48e3

    call DamageMul4Tenths_69e1
    jr jr_052_48e6

jr_052_48de:
    call DamageMul8Tenths_69b7
    jr jr_052_48e6

jr_052_48e3:
    call DamageMul6Tenths_69d2

jr_052_48e6:
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ld hl, $b682
    call CheckSkillResistance
    ret


jr_052_48f5:
    ld a, [wBattleTargetIdx]
    and $04
    or $02
    ld b, a
    ld a, [wBattleTargetIdx]
    cp b
    jr z, jr_052_4914

    inc a
    ld [wBattleTargetIdx], a
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    call HL_AddA_x2
    ld a, [wBattleTargetIdx]
    ld [hl], a

jr_052_4914:
    call SetSkillAnimFlag
    ret

SkillWindBeast:


    ld a, [$db8a]
    cp $59
    jr z, jr_052_4924

    call LoadBattle_641a
    jr jr_052_4927

jr_052_4924:
    call LoadBattle_6491

jr_052_4927:
    call SetHLBattle_54e7
    ret

SkillRockThrow:


    call BattleCall_6506
    call SetHLBattle_54e7
    ret

SkillFireAir:


    call BattleCall_6514
    call BattleTarget_5539
    call SetHLBattle_54e7
    ret

SkillFrigidAir:


    call BattleCall_6522
    call BattleTarget_5539
    call SetHLBattle_54e7
    ret

SkillBigBang:


    call BattleCall_6530
    call SetHLBattle_54e7
    ret

SkillMegaMagic:


    call MegaMagicDamage_653e
    call SetHLBattle_54e7
    ret

; [S130 F1] PalsyAir $6B: +2 bit6 already -> nothing; HitParalyze_65b5 (boss gate
; per victim, res 19, $6749; NO sure-hit) -> +2 |= $40; fail msg $C3.
SkillPalsyAir:


    ld a, [wBattleTargetIdx]
    ld hl, $db02
    call HL_AddA_x8
    bit 6, [hl]
    jr nz, jr_052_4977

    push hl
    call BattleCall_65b5
    pop hl
    jr c, jr_052_496e

    ld a, $c3
    call BattleFunc_5469
    ret


jr_052_496e:
    set 6, [hl]
    ld hl, $cfcf
    call SetSkillAnimA
    ret


jr_052_4977:
    call SetSkillAnimFlag
    ret

; [S130 F1] PoisonGas $6C: +2&3 already; PoisonAir $6D: +2 bit1 already. HitPoison_65c9
; (res 18, $6749) -> $6C sets bit0/clears bit1, $6D sets bit1 (heavy DoT)/clears bit0.
SkillPoisonGas:


    ld a, [wBattleTargetIdx]
    ld hl, $db02
    call HL_AddA_x8
    ld a, [$db8a]
    cp $6d
    jr z, jr_052_4997

    ld a, $ce
    ld [$db4c], a
    ld a, [hl]
    and $03
    jr nz, jr_052_49ce

    jr jr_052_49a0

jr_052_4997:
    ld a, $d0
    ld [$db4c], a
    bit 1, [hl]
    jr nz, jr_052_49ce

jr_052_49a0:
    call BattleCall_65c9
    jr c, jr_052_49ab

    ld a, $c3
    call BattleFunc_5469
    ret


jr_052_49ab:
    ld a, [wBattleTargetIdx]
    ld hl, $db02
    call HL_AddA_x8
    ld a, [$db8a]
    cp $6d
    jr z, jr_052_49c1

    set 0, [hl]
    res 1, [hl]
    jr jr_052_49c5

jr_052_49c1:
    set 1, [hl]
    res 0, [hl]

jr_052_49c5:
    ld a, [$db4c]
    ld h, a
    ld l, a
    call SetSkillAnimA
    ret


jr_052_49ce:
    call SetSkillAnimFlag
    ret

; [S130 F1] Curse $6F: +2 bit5 already; HitCurse_65d5 (res 20, $6749) -> +2 |= $20.
SkillCurse:


    ld a, [wBattleTargetIdx]
    ld hl, $db02
    call HL_AddA_x8
    bit 5, [hl]
    jr nz, jr_052_49fc

    call BattleCall_65d5
    jr c, jr_052_49ea

    ld a, $b8
    call BattleFunc_5469
    ret


jr_052_49ea:
    ld a, [wBattleTargetIdx]
    ld hl, $db02
    call HL_AddA_x8
    set 5, [hl]
    ld hl, $d1d1
    call SetSkillAnimA
    ret


jr_052_49fc:
    call SetSkillAnimFlag
    ret

; [S130 F1] Ahhh $70: the VICTIM's +5 (GetTargetStatus5_5422) bit5 one-shot -> forced
; $18 at its turn; HitCompel_65e3 (res 21, id < $7C -> ladder B).
SkillAhhh:


    call GetAttackerBattleSlot
    bit 5, [hl]
    jr nz, jr_052_4a18

    call BattleCall_65e3
    jr nc, jr_052_4a1c

    call GetAttackerBattleSlot
    set 5, [hl]
    ld hl, $a7a7
    call SetSkillAnimB
    ret


jr_052_4a18:
    call SetSkillAnimFlag
    ret


jr_052_4a1c:
    ld a, $b8
    call BattleFunc_5469
    ret

; [S130 F1] SandStorm $72 / Radiant $73: victim +7&3 already; SetHLBattle_5cda (res 6;
; $72 -> $6749, $73 -> ladder B) -> +7 |= 3 = the attacker-side 37.5% miss of
; flags7-bit1 skills ($53:$5785). Never decays (no writer clears +7 bits1:0 but
; the KO wipe / DeMagic).
SkillSandStorm:


    ld a, [wBattleTargetIdx]
    ld hl, $db07
    call HL_AddA_x8
    ld a, [hl]
    and $03
    jr nz, jr_052_4a53

    call SetHLBattle_5cda
    jr nc, jr_052_4a4d

    ld a, [wBattleTargetIdx]
    ld hl, $db07
    call HL_AddA_x8
    set 1, [hl]
    set 0, [hl]
    ld a, [$db8a]
    add $30
    ld h, a
    ld l, a
    call SetSkillAnimB
    ret


jr_052_4a4d:
    ld a, $b8
    call BattleFunc_5469
    ret


jr_052_4a53:
    call SetSkillAnimFlag
    ret

; [S130 F1] EerieLite $74: victim +5 bit7 already -> msg $BB; HitDeath_5c51 ($74 is
; not boss-listed; id >= $72 -> ladder B, res 8) -> +5 |= $80 = the AMPLIFY row.
SkillEerieLite:


    call GetAttackerBattleSlot
    bit 7, [hl]
    jr nz, jr_052_4a6f

    call BattleCall_5c51
    jr nc, jr_052_4a75

    call GetAttackerBattleSlot
    set 7, [hl]
    ld hl, $a4a4
    call SetSkillAnimB
    ret


jr_052_4a6f:
    ld a, $bb
    call BattleFunc_5475
    ret


jr_052_4a75:
    ld a, $b8
    call BattleFunc_5469
    ret

; [S130 F5] OddDance $75: as RobMagic but BattleTarget_5d7a only — the drained
; MP is lost (measured: caster MP unchanged).
SkillOddDance:


    ld a, [wBattleTargetIdx]
    ld hl, wBattleMP
    call HL_AddA_x2
    ld a, [hl+]
    or [hl]
    jr z, jr_052_4a9d

    call SetHLBattle_5d25
    jr nc, jr_052_4a97

    call BattleTarget_5d7a
    ld hl, $a5a5
    call SetSkillAnimB
    ret


jr_052_4a97:
    ld a, $b8
    call ApplySkillDamage
    ret


jr_052_4a9d:
    ld a, $bb
    call ApplySkillDamage
    ret

; [S130 F1] measured: one step, then +7 bit2 or bit3; the dodge consumer falls
; through to the AGL ladder when RNG1 is odd ($53:$57C1). Permanent (no decay).
SkillSideStep:


    call BattleRNG
    ld a, [wBattleAttackerIdx]
    ld hl, $db07
    call HL_AddA_x8
    ld a, [hl]
    and $0c
    jr nz, jr_052_4ac1

    ld a, [wRNG1]
    and $04
    add $04
    ld b, a
    ld a, [hl]
    and $f3
    or b
    ld [hl], a

jr_052_4ac1:
    call SetSkillAnimFlag
    ret

; [S130 F1] LureDance $78: victim +5 bit1 one-shot (forced $14); HitCompel_65e3 (ladder B).
SkillLureDance:


    call GetAttackerBattleSlot
    bit 1, [hl]
    jr nz, jr_052_4ae3

    call BattleCall_65e3
    jr nc, jr_052_4add

    call GetAttackerBattleSlot
    set 1, [hl]
    ld hl, $a6a6
    call SetSkillAnimB
    ret


jr_052_4add:
    ld a, $c8
    call ApplySkillDamage
    ret


jr_052_4ae3:
    call SetSkillAnimFlag
    ret

; [S130 F1] LushLicks $79 (HitCompel_65e3, ladder B) / SickLick $7A (HitDefDown_5dcc,
; res 12, $6749, $DB42 sure hit): victim +5 bit3 one-shot (forced $15); $7A also
; DEF := 1 and MarkDefLowered_5377 ($DB08+8t bit7).
; [S130 F7] LushLicks $79 / SickLick $7A: +5 bit3 one-shot; $7A also sets the
; [S130 F7] target DEF := 1 and $DB08+8t bit7 (measured S130).
SkillLushLicks:


    call GetAttackerBattleSlot
    bit 3, [hl]
    jr nz, jr_052_4b30

    ld a, [$db8a]
    cp $7a
    jr z, jr_052_4afa

    call BattleCall_65e3
    jr jr_052_4afd

jr_052_4afa:
    call SapHitRoll_5dcc

jr_052_4afd:
    jr nc, jr_052_4b2a

    call GetAttackerBattleSlot
    set 3, [hl]
    ld a, [$db8a]
    cp $79
    jr z, jr_052_4b1f

    ld a, [wBattleTargetIdx]
    ld hl, wBattleDEF
    call HL_AddA_x2
    ld a, $01
    ld [hl+], a
    ld [hl], $00
    ld a, [wBattleTargetIdx]
    call SetStatLoweredMark_5377

jr_052_4b1f:
    ld a, [$db8a]
    add $2f
    ld h, a
    ld l, a
    call SetSkillAnimA
    ret


jr_052_4b2a:
    ld a, $ca
    call BattleFunc_5469
    ret


jr_052_4b30:
    call SetSkillAnimFlag
    ret

; [S130 F1] LegSweep $7B / BigTrip $7C: victim +5 bit2 already; HitTripFlyerGate_65ff:
; a flyer ($DB8B bit4) fails with msg $C1, no roll; else HitCompel_65e3 ($7B ladder B,
; $7C $6749) -> +5 |= 4 (forced $16).
SkillLegSweep:


    call GetAttackerBattleSlot
    bit 2, [hl]
    jr nz, jr_052_4b4c

    call BattleTarget_65ff
    jr nc, jr_052_4b50

    call GetAttackerBattleSlot
    set 2, [hl]
    ld hl, $abab
    call SetSkillAnimA
    ret


jr_052_4b4c:
    call SetSkillAnimFlag
    ret


jr_052_4b50:
    ld a, [wBattleTargetIdx]
    ld hl, $db8b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    bit 4, [hl]
    ld a, $c9
    jr z, jr_052_4b64

    ld a, $c1

jr_052_4b64:
    call ApplySkillDamage
    ret

; [S130 F1] WarCry $7D: dead victim skipped; +5 bit4 already; HitCompel_65e3 ($6749) -> forced $17.
SkillWarCry:


    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    jr c, jr_052_4b88

    call GetAttackerBattleSlot
    bit 4, [hl]
    jr nz, jr_052_4b88

    call BattleCall_65e3
    jr nc, jr_052_4b8c

    call GetAttackerBattleSlot
    set 4, [hl]
    ld hl, $aaaa
    call SetSkillAnimA
    ret


jr_052_4b88:
    call SetSkillAnimFlag
    ret


jr_052_4b8c:
    ld a, $ca
    call BattleFunc_5469
    ret

; [S130 F6] Imitate $7F: own $DB08+8a bit3 (one round: block a+1 +0 &= $C0 in phase 9). Consumer
; [S130 F6] ImitateCheck_7dd7 after every victim (also a missed one).
SkillImitate:


    ld a, [wBattleAttackerIdx]
    ld hl, $db08
    call HL_AddA_x8
    set 3, [hl]
    call SetSkillAnimFlag
    ret

; [S130 F10] DeMagic $80 / ThickFog $83 / FILTHZONE $A5 (after the one-step MISS
; [S130 F10] machine on the one resolved target): d9ed := 3 -> act state 3 runs the
; [S130 F10] bank $53 entry-11 DispelMachine_60b3 (BtlActState_6e2b). Measured S130.
SkillDeMagic_ThickFog:


    ld a, $03
    ld [$d9ed], a
    xor a
    ld [$d9ee], a
    ret

; [S130 F7] Surge $81 (tm 34, sweep from the queued slot): $53 entry 10
; [S130 F7] (SurgeCureTarget_601c) per victim: cures + restores lowered DEF/AGL.
SkillSurge:


    ld hl, $530a
    rst $10
    ld hl, $aeae
    call SetSkillAnimB
    ret

; [S130 F7] UltraDown $82: BattleCall_5c51 roll (res 8, HitLadderKamikaze, NO $DB42
; [S130 F7] sure-hit) + UltraDownFloorCheck_6612, then d9ed=3 -> $53 UltraDownMachine_65ac.
SkillUltraDown:


    call BattleCall_5c51
    jr nc, jr_052_4bca

    call UltraDownFloorCheck_6612
    jr nc, jr_052_4bca

    xor a
    ld [$d9ee], a
    ld a, $03
    ld [$d9ed], a
    ret


jr_052_4bca:
    ld a, $b8
    call ApplySkillDamage
    ret

; [S130 F9] TatsuCall/DiagoCall/SamsiCall/BazooCall $84-$87 (row $58:$63D6 =
; self): one BattleRNG step FIRST, then the side byte $DB00/$DB01 bit2 set ->
; msg $BB (once per side; survives phase 9), RNG1 >= $C0 -> msg $CB, else set
; bit2 and HelperLoad_6648 (bank $51 entry 5-8) fills slot (side|3); $DD1B := 0,
; $DC3C := id+$54 (216-219). $DD13 stays $FF: the helper acts NEXT round.
; Measured both sides, every species (simulator/validate_f9.py).
SkillTatsuCall:


    call BattleRNG
    ld a, [wBattleAttackerIdx]
    rrca
    rrca
    and $01
    ld hl, $db00
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    bit 2, [hl]
    jr nz, jr_052_4c25

    ld a, $c0
    ld b, a
    ld a, [wRNG1]
    cp b
    jr nc, jr_052_4c2b

    set 2, [hl]
    ld a, [$db8a]
    call LoadBattle_6648
    ld a, [$db4c]
    ld hl, $dd1b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $00
    ld a, [$db4c]
    ld hl, $dc3c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$db8a]
    add $54
    ld [hl], a
    ld a, [$db4c]
    ld [wBattleTargetIdx], a
    ld hl, $afaf
    call SetSkillAnimB
    ret


jr_052_4c25:
    ld a, $bb
    call BattleFunc_5475
    ret


jr_052_4c2b:
    ld a, $cb
    call ApplySkillDamage
    ret

SkillCover:


    ld a, $03
    ld [$d9ed], a
    xor a
    ld [$d9ee], a
    ret


; [S130 F6] TailWind $8A: target +4 bit6. StormWind $8B: target..(slot&3 == 2) +4 bit6 (no life check)
; [S130 F6] + side byte $DB00/01 bit5 (message-only, WindMsgCheck_7d7c). Consumer TailWindReflect_5594:
; [S130 F6] a flags7-bit4 breath (not $43/$8F) is reflected (code 1) and the bit CONSUMED. Measured S130.
SkillTailWind:
    ld a, [wBattleTargetIdx]
    ld hl, $db04
    call HL_AddA_x8
    set 6, [hl]
    ld a, [$db8a]
    cp $8a
    jr z, jr_052_4c6e

    ld a, [wBattleTargetIdx]
    and $03
    cp $02
    jr z, jr_052_4c5c

    ld hl, wBattleTargetIdx
    inc [hl]
    jr SkillTailWind

jr_052_4c5c:
    ld a, [wBattleTargetIdx]
    rra
    rra
    and $01
    ld hl, $db00
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    set 5, [hl]

jr_052_4c6e:
    call SetSkillAnimFlag
    ret

SkillDodge:


    ld a, [wBattleAttackerIdx]
    ld hl, $db08
    call HL_AddA_x8
    set 5, [hl]
    call SetSkillAnimFlag
    ret

SkillBladeD_Defense:


    ld a, [wBattleAttackerIdx]
    ld hl, $db09
    call HL_AddA_x8
    ld a, [$db8a]
    cp $90
    jr z, jr_052_4c9b

    sub $8c
    ld b, a
    ld a, [hl]
    and $f0
    or b
    ld [hl], a
    jr jr_052_4ca1

jr_052_4c9b:
    ld a, [hl]
    and $f0
    or $04
    ld [hl], a

jr_052_4ca1:
    call SetSkillAnimFlag
    ret

; [S130 F6] SuckAll $8F: side byte bit6 (set -> nothing), $DB4A+side |= (slot&3)<<2, own $DB08+8a bit1.
; [S130 F6] Consumer SuckAllAbsorbCheck_5458: the side's next breath victim becomes the SuckAll user
; [S130 F6] (it takes the breath), the sweep ends, and SuckAllBreathBack_71f8 breathes it back at the
; [S130 F6] other side ($DD6C = $40). One round (phase 9: side &= ~$50, $DB4A/4B &= 3). Measured S130.
SkillSuckAll:


    ld a, [wBattleAttackerIdx]
    cp $04
    jr c, jr_052_4cb1

    ld hl, $db01
    jr jr_052_4cb4

jr_052_4cb1:
    ld hl, $db00

jr_052_4cb4:
    bit 6, [hl]
    jr nz, jr_052_4cd8

    set 6, [hl]
    ld a, $4a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wBattleAttackerIdx]
    and $03
    rla
    rla
    ld b, a
    ld a, [hl]
    or b
    ld [hl], a
    ld a, [wBattleAttackerIdx]
    ld hl, $db08
    call HL_AddA_x8
    set 1, [hl]

jr_052_4cd8:
    call SetSkillAnimFlag
    ret

; [S130 F1] DanceShut $91: +3 bit6 already; HitDanceShut_6692 (res 22, ladder B) -> +3 |= $40.
SkillDanceShut:


    ld a, [wBattleTargetIdx]
    ld hl, $db03
    call HL_AddA_x8
    bit 6, [hl]
    jr nz, jr_052_4d06

    call BattleCall_6692
    jr nc, jr_052_4d00

    ld a, [wBattleTargetIdx]
    ld hl, $db03
    call HL_AddA_x8
    set 6, [hl]
    ld hl, $b0b0
    call LoadBattle_54d2
    ret


jr_052_4d00:
    ld a, $b8
    call ApplySkillDamage
    ret


jr_052_4d06:
    call SetSkillAnimFlag
    ret

; [S130 F1] MouthShut $92: +3 bit7 already; HitMouthShut_669e (res 23, ladder B) -> +3 |= $80.
SkillMouthShut:


    ld a, [wBattleTargetIdx]
    ld hl, $db03
    call HL_AddA_x8
    bit 7, [hl]
    jr nz, jr_052_4d2e

    call BattleCall_669e
    jr nc, jr_052_4d32

    ld a, [wBattleTargetIdx]
    ld hl, $db03
    call HL_AddA_x8
    set 7, [hl]
    ld hl, $b2b2
    call LoadBattle_54d2
    ret


jr_052_4d2e:
    call SetSkillAnimFlag
    ret


jr_052_4d32:
    ld a, $c9
    call BattleFunc_5469
    ret

; [S130 F5] Meditate $93: own HP == MaxHP -> $BB; else HP := min(HP+500, MaxHP).
SkillMeditate:


    ld a, [wBattleAttackerIdx]
    ld hl, wBattleMaxHP
    call HL_AddA_x2
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld a, c
    ld [$db5a], a
    ld a, b
    ld [$db5b], a
    ld a, [wBattleAttackerIdx]
    ld hl, wBattleHP
    call HL_AddA_x2
    ld a, l
    ld [$db5c], a
    ld a, h
    ld [$db5d], a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call CmpHLvsBC
    jr z, jr_052_4d8c

    ld bc, $01f4
    add hl, bc
    ld a, [$db5a]
    ld c, a
    ld a, [$db5b]
    ld b, a
    call CmpHLvsBC
    jr c, jr_052_4d78

    ld h, b
    ld l, c

jr_052_4d78:
    ld a, [$db5c]
    ld c, a
    ld a, [$db5d]
    ld b, a
    ld a, l
    ld [bc], a
    inc bc
    ld a, h
    ld [bc], a
    ld hl, $8484
    call SetSkillAnimB
    ret


jr_052_4d8c:
    ld a, $bb
    call ApplySkillDamage
    ret

; [S130 F5] LifeSong $95, two turns: own +7 bit4 clear -> +7 = (+7&$CF)|$20
; (phase 9 moves it to bit4; the command loop then skips the actor so the
; queued LifeSong stands, and the 2nd turn pays no MP); bit4 set -> clear
; bits 5:4, 1 BattleRNG step, RNG1 >= $80 AND a dead own slot -> act state
; 4 / $DD72 = 4 = the LifeSong tails ($6F42: LifeSongRevive_7a69 ...), else
; msg $CB.
SkillLifeSong:


    ld a, [wBattleAttackerIdx]
    ld hl, $db07
    call HL_AddA_x8
    ld a, [hl]
    and $10
    jr nz, jr_052_4daa

    ld a, [hl]
    and $cf
    or $20
    ld [hl], a
    call SetSkillAnimFlag
    ret


jr_052_4daa:
    ld a, [hl]
    and $cf
    ld [hl], a
    call BattleRNG
    ld a, [wRNG1]
    cp $80
    jr c, jr_052_4de3

    ld a, [wBattleAttackerIdx]
    and $04
    ld hl, $dd1b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld b, $03

jr_052_4dc8:
    ld a, [hl+]
    cp $01
    jr z, jr_052_4dd2

    dec b
    jr nz, jr_052_4dc8

    jr jr_052_4de3

jr_052_4dd2:
    ld a, $04
    ld [$d9ed], a
    ld [$dd72], a
    xor a
    ld [$d9ee], a
    xor a
    ld [$d9ef], a
    ret


jr_052_4de3:
    ld a, $cb
    call ApplySkillDamage
    ret

; [S130 F5] LifeDance $96: 1 BattleRNG step; RNG1 < $7F -> the bank $53
; entry-14 chain (as Farewell), else msg $BB.
SkillLifeDance:


    call BattleRNG
    ld a, [wRNG1]
    cp $7f
    jr c, jr_052_4df9

    ld a, $bb
    call ApplySkillDamage
    ret


jr_052_4df9:
    ld a, $04
    ld [$d9ed], a
    ld [$dd72], a
    xor a
    ld [$d9ee], a
    xor a
    ld [$d9ef], a
    ret

; [S130 P3.15b] Daze $98 = the disobedient 'loaf' (SetBtlAI_7f5f, all bases <
; $3F): after the usual MISS step (one RNG step, nothing can block it) only the
; animation flag + message — the turn is lost (skillfx/cmd_orders.py).
SkillDaze:


    call SetSkillAnimFlag
    ret

; [S130 F9] BeDragon $D5 / CHGDRAGON $AA (row $6367 self): message only here;
; act state 4 (DragonFormState4_6d0a) does the form change and the rewrite.
SkillBeDragon:


    ld hl, $9191
    call SetSkillAnimA
    ret

SkillSmashlime:


    call CheckIsSlime
    ld hl, $b682
    call CheckSkillResistance
    ret

SkillSheldodge:


    call CheckIsBug
    ld hl, $b682
    call CheckSkillResistance
    ret

SkillBranching:


    call CheckIsPlant
    ld hl, $b682
    call CheckSkillResistance
    ret

SkillGigaSlash:


    call BattleCall_66ac
    call SetHLBattle_54e7
    ret


; [S130 F9] As the $DB RUN skill and inside SkillSmashed: a slot >= 4 also runs
; FleeBookkeeping_7242 -> bank $51 FleeSlot_4be8 (helper: side bit2 cleared;
; else the slot reload) + KOStatusWipe (HP 0, MP clamp, status). Party: $DD1B only.
SkillRUN:
    ld a, [wBattleAttackerIdx]
    ld hl, $dd1b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $ff
    ld a, [wBattleAttackerIdx]
    cp $04
    jr c, jr_052_4e64

    and $03
    ld hl, $dc33
    ld b, a
    add a
    add b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    xor a
    ld [hl+], a
    ld [hl+], a
    ld [hl], a
    call BattleTarget_7242

jr_052_4e64:
    ld a, $01
    ld [$d9ed], a
    call SetSkillAnimFlag
    ret

SkillAhhh2:


    call CalcDefenseWrapper
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    call HLsrl1
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ld hl, $ca82
    call CheckSkillResistance
    ret

SkillHitAlly:


    call BattleRNG
    ld a, [wRNG1]
    cp $40
    jr c, jr_052_4e9e

    call CalcDefenseWrapper
    ld hl, $b682
    call CheckSkillResistance
    ret


jr_052_4e9e:
    ld a, $b6
    call ApplySkillDamage
    ret

SkillHitEnemy:


    call BattleRNG
    ld a, [wRNG1]
    cp $c0
    jr c, jr_052_4eb8

    call CalcDefenseWrapper
    ld hl, $b682
    call CheckSkillResistance
    ret


jr_052_4eb8:
    ld a, $b6
    call ApplySkillDamage
    ret

SkillHitRandom:


    ld a, [wBattleAttackerIdx]
    ld [wBattleTargetIdx], a
    ld hl, $dced
    call HL_AddA_x2
    ld a, [wBattleAttackerIdx]
    ld [hl], a
    call CalcDefenseWrapper
    ld hl, $b682
    call CheckSkillResistance
    ret

SkillTrip:


    ld a, [wBattleAttackerIdx]
    ld hl, $db05
    call HL_AddA_x8
    set 2, [hl]

SkillScared:
    call SetSkillAnimFlag
    ret

SkillParalyze:


    ld a, [wBattleAttackerIdx]
    ld hl, $db02
    call HL_AddA_x8
    set 6, [hl]
    ld hl, $cf00
    call LoadBattle_54a1
    ret

; [S130 F9] CALLHOROR $A2 / Smashed $A4 (Chance outcomes; boss-ungated): target
; HP := 0 + SkillRUN on it; the apply state is skipped and $53 SmashedWalk_6be2
; re-enters this handler for each next live slot up to 6 (no MISS machine).
SkillSmashed:


    ld a, [wBattleTargetIdx]
    ld hl, wBattleHP
    call HL_AddA_x2
    xor a
    ld [hl+], a
    ld [hl], a
    ld a, [wBattleAttackerIdx]
    push af
    ld a, [wBattleTargetIdx]
    ld [wBattleAttackerIdx], a
    call SkillRUN
    pop af
    ld [wBattleAttackerIdx], a
    ld a, $01
    ld [$d9ed], a
    ld hl, $e9e9
    ld a, [$db8a]
    cp $a4
    jr z, jr_052_4f28

    ld hl, DataTable_2929

jr_052_4f28:
    call SetSkillAnimA
    ret

; [S130 F5] HealUsAll $A3 (Chance outcome): $DB8A := $2F, then SkillHeal (full).
SkillHealUsAll:


    ld a, $2f
    ld [$db8a], a
    call SkillHeal
    ret

; [S130 F4] ALLCHANGE $A6 (Chance): every live slot of the caster's side +3
; bit3 = SURE CRIT, no roll, for flags8-bit4 skills ($53:$58A8). Persistent.
SkillALLCHANGE:


    ld a, [wBattleAttackerIdx]
    and $04
    ld c, a
    ld b, $03

jr_052_4f3d:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_052_4f4c

    ld a, c
    ld hl, $db03
    call HL_AddA_x8
    set 3, [hl]

jr_052_4f4c:
    inc c
    dec b
    jr nz, jr_052_4f3d

    call SetSkillAnimFlag
    ret

; [S130 F1] BIGSLEEP $A7 (Chance): no roll; per victim of the $714C 8-step walk
; (both sides, caster included): dead -> nothing, +2 bit7 -> msg $BD, else
; +2 = (+2 & $73) | $8C.
; [S130 F8] Chance outcome $A7, one $714C walk pass: a live target not
; asleep gets +2 := (+2 & $73) | $8C, no roll (caster included; measured).
SkillBIGSLEEP:


    ld a, [wBattleTargetIdx]
    ld c, a
    call CheckMonsterSlot
    jr c, jr_052_4f7b

    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    bit 7, [hl]
    jr nz, jr_052_4f75

    ld a, [hl]
    and $73
    or $8c
    ld [hl], a
    ld hl, $cccc
    call LoadBattle_54d2
    ret


jr_052_4f75:
    ld a, $bd
    call ApplySkillDamage
    ret


jr_052_4f7b:
    call SetSkillAnimFlag
    ret

; [S130 F5] MP0 $A8 (Chance): live target with MP != 0 -> MP := 0; the $714C
; 8-slot walk visits every live combatant, the caster included.
; [S130 F8] Chance outcome $A8, one $714C walk pass: target MP := 0 (measured).
SkillMP0:


    ld a, [wBattleTargetIdx]
    ld c, a
    call CheckMonsterSlot
    jr c, jr_052_4f9d

    ld a, c
    ld hl, wBattleMP
    call HL_AddA_x2
    ld a, [hl+]
    or [hl]
    jr z, jr_052_4f9d

    xor a
    ld [hl-], a
    ld [hl], a
    ld hl, $7272
    call SetSkillAnimA
    ret


jr_052_4f9d:
    call SetSkillAnimFlag
    ret

SkillCALLEVIL:


    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    call HL_AddA_x2
    ld a, [hl]
    ld [wBattleTargetIdx], a
    call CheckMonsterSlot
    jr c, jr_052_4fc8

    call LoadBattle_66ba
    ld a, [wBattleAttackerIdx]
    ld hl, $db08
    call HL_AddA_x8
    set 0, [hl]
    ld hl, $b682
    call CheckSkillResistance
    ret


jr_052_4fc8:
    call SetSkillAnimFlag
    ret

; [S130 F1] FREEZY $AC (Chance): victim +5 bit0 one-shot (forced $12), no roll.
SkillFREEZY:


    call GetAttackerBattleSlot
    bit 0, [hl]
    jr nz, jr_052_4fdc

    set 0, [hl]
    ld hl, $b5b5
    call LoadBattle_54d2
    ret


jr_052_4fdc:
    call SetSkillAnimFlag
    ret


    ld a, [wBattleTargetIdx]
    ld hl, $dd1b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $01
    jr nz, jr_052_4ff8

    ld hl, $9e9e
    call SetSkillAnimB
    ret


jr_052_4ff8:
    call SetSkillAnimFlag
    ret

; [S130 F5] RESTOREMP $AE (Chance): `ld a,[hl+] / cp [hl]` compares MP LOW with
; MP HIGH (bug): equal (MP 0, 257 ...) -> no effect, else MP := MaxMP.
SkillRESTOREMP:


    ld a, [wBattleTargetIdx]
    call GetCombatantMaxMP
    push hl
    ld a, [wBattleTargetIdx]
    ld hl, wBattleMP
    call HL_AddA_x2
    pop bc
    ld a, [hl+]
    cp [hl]
    jr z, jr_052_501b

    ld a, b
    ld [hl-], a
    ld [hl], c
    ld hl, $7676
    call SetSkillAnimA
    ret


jr_052_501b:
    call SetSkillAnimFlag
    ret

; [S130 F8] $AF (Chance outcome), one $714C walk pass ($DD69 1..8): damage
; = HP-1, or 1 when HP == 1 (lethal); no ladder. Hits both sides incl. the
; caster (measured).
SkillMETEOR:


    ld a, [$dd69]
    ld c, a
    dec a
    cp $08
    jr nc, jr_052_5066

    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    jr c, jr_052_506a

    ld a, [wBattleTargetIdx]
    ld hl, wBattleHP
    call HL_AddA_x2
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    cp $01
    jr nz, jr_052_5044

    ld a, d
    or a
    jr z, jr_052_5054

jr_052_5044:
    dec de
    ld a, e
    ld [$db56], a
    ld a, d
    ld [$db57], a
    ld hl, $8585
    call LoadBattle_54f8
    ret


jr_052_5054:
    ld hl, $0001
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ld hl, $8282
    call LoadBattle_54f8
    ret


jr_052_5066:
    call SetSkillAnimFlag
    ret


jr_052_506a:
    ld a, c
    and $03
    ld b, a
    ld a, c
    cp $04
    jr c, jr_052_507b

    ld a, [wBattleAttackerIdx]
    and $04
    or b
    jr jr_052_5083

jr_052_507b:
    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    or b

jr_052_5083:
    ld b, a
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    call HL_AddA_x2
    ld [hl], b
    ld a, b
    ld [wBattleTargetIdx], a
    xor a
    ld [$d9ee], a
    ret


    ld a, $00
    ld [$db56], a
    ld a, $00
    ld [$db57], a

BattleCall_50a1:
    call BattleCall_50e2
    ld a, [wBattlePostFlag]
    ld b, a
    ld a, [$db54]
    or a
    jr z, jr_052_50b5

    ld a, [wBattleAttackerIdx]
    srl a
    srl a

jr_052_50b5:
    add b
    ld l, a
    ld h, $00
    ld a, h
    ld [$c822], a
    ld a, l
    ld [$c823], a
    ld hl, $5f04
    rst $10
    ret


    ld a, $82
    ld [wBattlePostFlag], a
    ld [$db54], a
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    ld a, l
    or h
    jr nz, jr_052_50de

    call SetHLBattle_5143
    ret


jr_052_50de:
    call BattleCall_50a1
    ret


BattleCall_50e2:
    call SetHLBattle_6c23
    call SetHLBattle_50e9
    ret


SetHLBattle_50e9:
    ld hl, $c190
    ld a, [$db56]
    ld c, a
    ld a, [$db57]
    ld b, a
    call FormatDecimalDigits
    ret


Jump_052_50f8:
    ld a, $05
    ld [$db51], a
    ld a, $02
    ld [$dd6b], a
    ret


    ld hl, $c180
    ld a, [wBattleTargetIdx]
    ld [$db50], a
    call CheckTargetInRange
    ld a, $00
    ld [$c822], a
    ld a, $b8
    ld [$c823], a
    ld a, $00
    ld [$dd6b], a
    ld a, $04
    ld [$d9ef], a
    ld a, $6f
    call PlaySoundEffect
    ret


    ld hl, $c180
    ld a, [wBattleTargetIdx]
    ld [$db50], a
    call CheckTargetInRange
    ld hl, $0078
    call LoadBattle_515d
    ret


    ld hl, $00bb
    call LoadBattle_515d
    ret


SetHLBattle_5143:
    ld hl, $c180
    ld a, [wBattleTargetIdx]
    ld [$db50], a
    call CheckTargetInRange
    call LoadBattle_7fcb
    srl a
    srl a
    xor $01
    add $b6
    ld l, a
    ld h, $00

LoadBattle_515d:
    ld a, h
    ld [$c822], a
    ld a, l
    ld [$c823], a
    ld a, $00
    ld [$dd6b], a
    ld hl, $d9ef
    inc [hl]
    ld a, $6f
    call PlaySoundEffect
    ret


    ld hl, $c180
    ld a, [wBattleTargetIdx]
    ld [$db50], a
    call CheckTargetInRange
    ld a, [wBattlePostFlag]
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld a, $02
    ld [$dd6b], a
    ld hl, $d9ef
    inc [hl]
    ld a, $6f
    call PlaySoundEffect
    ret


CalcDefenseWrapper:
    call CalcSkillDefense
    ret


LoadBattle_519e:
    ld a, $00
    ld [$db56], a
    ld a, $00
    ld [$db57], a
    ld a, [wBattleTargetIdx]
    ld hl, $db02
    call HL_AddA_x8
    ld a, [hl]
    ret


; =============================================================================
; [S111] ELEMENT OVERRIDE (BATTLE_SKILL_SYSTEM §15.3 "Element override (S111)").
; These 42 bytes were the S84-audited DEAD twins of the surround-miss / dodge
; rolls ($51B3-$51DC: zero call/jp/jr/dw references ROM-wide, re-checked S111).
; A damage handler reads ONE 2-bit resistance level of the target itself and
; passes it in A to a damage ladder; the 24 ladder calls in this bank now go
; through ElemLadderA / ElemLadderBreath / ElemLadderSlash, which first ask bank
; $72 (entry 5 ElemLevel72) whether the acting skill ($db8a) has an element
; override (gamedata.skills.<id>.element -> StockElemTable / CustomElemTable):
; if so A becomes the target's level for THAT resistance, else A is unchanged
; (identity tables = vanilla). CustomElemTail52 applies the spell ladder after a
; bespoke custom handler (Quake, MagicBurn, Tame, Mourn) when its CustomElemTable
; entry names an element (bank $72 entry 1 returns E = level / $FF, HL = the
; target's status byte $DB05+8*slot).
; =============================================================================
ElemLadderA:                    ; spell ladder (Blaze ... Hellblast, GigaSlash)
    call ElemLevel52
    jp CheckTargetGuardA
ElemLadderBreath:               ; breath ladder (breaths, BigBang, RockThrow, MegaMagic)
    call ElemLevel52
    jp ResLadderBreath_676c
ElemLadderSlash:                ; elemental-slash ladder (FireSlash, BoltSlash, ...)
    call ElemLevel52
    jp ResLadderElemSlash_6782
ElemLevel52:                    ; A = the level the handler read -> A = the level to use
    push bc
    push de
    push hl
    ld e, a
    ld hl, $7205                ; bank $72 entry 5 = ElemLevel72 (E in / E out)
    rst $10
    pop hl
    ld a, e
    pop de
    pop bc
    ret
CustomElemTail52:               ; jp'd at the end of CustomDispatch52
    ld a, e                     ; E = the custom skill's element level, $FF = none
    inc a
    ret z
    dec a
    jp CheckTargetGuardA        ; HL = target status byte (set by bank $72 entry 1)
    ds $51dd - @, $00           ; (4 spare bytes of the old dead code)
    ASSERT @ == $51dd

; [S130 F5] Revive a slot: $DD1B[A] := 0 and $DB02+8A..$DB09+8A := 0 (+2..+7
; and the shifted guard pair), sprite reload. $DD13 is NOT written: the
; slot stays $FF this round and the next command phase re-arms it (measured).
ReviveSlot_51dd:
SaveBattle_51dd:
    push hl
    push bc
    ld b, a
    ld hl, $dd1b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $00
    ld a, b
    ld hl, $db02
    call HL_AddA_x8
    xor a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl], a
    ld a, b
    ld hl, $dc3c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld c, [hl]
    call BattleCall_5213
    pop bc
    pop hl
    ret


    ld a, [$db4c]
    call SaveBattle_51dd
    ret


BattleCall_5213:
    call LoadBattle_5257
    ld a, [$c863]
    bit 1, a
    ld a, b
    jr z, jr_052_5224

    cp $03
    jr nc, jr_052_5256

    jr jr_052_522e

jr_052_5224:
    cp $04
    jr c, jr_052_5256

    cp $07
    jr z, jr_052_5256

    sub $04

jr_052_522e:
    push bc
    ld bc, $0240
    call Mul16x8To24
    ld bc, $9000
    add hl, bc
    pop bc
    push hl
    ld l, c
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
    pop hl
    call WaitDMATransfer
    ld hl, $5110
    rst $10
    ld hl, $1708
    rst $10

jr_052_5256:
    ret


LoadBattle_5257:
    ld a, [wIsGBC]
    or a
    ret z

    ld a, $02
    ldh [rSVBK], a
    ld a, b
    ld hl, $db00
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], c
    ld a, $00
    ldh [rSVBK], a
    ret


; [S130 F7] BC = bank $57 entry 4 base MaxHP of slot A, capped 999. Base source:
; [S130 F7] party/helper/link slot = record (+$52..+$5C), enemy = enemy_stats row.
GetBaseMaxHP_5270:
    push hl
    ld [$dd72], a
    ld hl, $5704
    rst $10
    ld a, [$dd72]
    ld c, a
    ld a, [$dd73]
    ld b, a
    ld hl, $03e7
    call CmpHLvsBC
    jr nc, jr_052_528b

    ld bc, $03e7

jr_052_528b:
    pop hl
    ret


; [S130 F7] BC = bank $57 entry 5 base MaxMP of slot A (record +$56 / row).
GetBaseMaxMP_528d:
    push hl
    ld [$dd72], a
    ld hl, $5705
    rst $10
    ld a, [$dd72]
    ld c, a
    ld a, [$dd73]
    ld b, a
    pop hl
    ret


; [S130 F7] BC = bank $57 entry 6 base ATK of slot A (record +$58 / row).
GetBaseATK_529f:
    push hl
    ld [$dd72], a
    ld hl, $5706
    rst $10
    ld a, [$dd72]
    ld c, a
    ld a, [$dd73]
    ld b, a
    pop hl
    ret


; [S130 F7] BC = bank $57 entry 7 base DEF of slot A (record +$5A / row).
GetBaseDEF_52b1:
    push hl
    ld [$dd72], a
    ld hl, $5707
    rst $10
    ld a, [$dd72]
    ld c, a
    ld a, [$dd73]
    ld b, a
    pop hl
    ret


    ld a, [$dd72]

; [S130 F7] BC = bank $57 entry 8 base AGL of slot A (record +$5C / row).
GetBaseAGL_52c6:
    push hl
    ld [$dd72], a
    ld hl, $5708
    rst $10
    ld a, [$dd72]
    ld c, a
    ld a, [$dd73]
    ld b, a
    pop hl
    ret


SetupBattle_52d8:
    ld b, a
    cp $03
    jr c, jr_052_530d

    and $03
    cp $03
    jr z, jr_052_5315

    ld a, [$c86c]
    or a
    ld a, b
    jr nz, jr_052_530d

    and $03
    ld hl, wTempEnemyId1
    call CalcBattle_6ab1

jr_052_52f2:
    ld a, l
    ld [wTempEnemyStatsId], a
    ld a, h
    ld [$da13], a
    ld hl, $1401
    rst $10
    ld a, [$da18]
    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10
    ld hl, $da42
    jr jr_052_5324

jr_052_530d:
    ld hl, $cb29
    call GetCurrentMonsterPtr
    jr jr_052_5324

jr_052_5315:
    ld a, b
    ld hl, $dc3c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld l, [hl]
    ld h, $01
    jr jr_052_52f2

jr_052_5324:
    ret


SetupBattle_5325:
    ld b, a
    cp $03
    jr c, jr_052_5352

    and $03
    cp $03
    jr z, jr_052_535c

    ld a, [$c86c]
    or a
    ld a, b
    jr nz, jr_052_5352

    sub $04
    ld hl, wTempEnemyId1
    call CalcBattle_6ab1

jr_052_533f:
    ld a, l
    ld [wTempEnemyStatsId], a
    ld a, h
    ld [$da13], a
    ld hl, $1401
    rst $10
    ld hl, $da2d
    ld b, $04
    jr jr_052_536b

jr_052_5352:
    ld hl, $caea
    call GetCurrentMonsterPtr
    ld b, $08
    jr jr_052_536b

jr_052_535c:
    ld a, b
    ld hl, $dc3c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld l, [hl]
    ld h, $01
    jr jr_052_533f

jr_052_536b:
    ret


; [S130 F7] $DB08+8*A |= bit6: "stat raised" marker (survives phase 9).
SetStatRaisedMark_536c:
    push hl
    ld hl, $db08
    call HL_AddA_x8
    set 6, [hl]
    pop hl
    ret


; [S130 F1] $DB08+8*A bit7 = slot A's "DEF lowered" marker (shifted record; survives phase 9).
MarkDefLowered_5377:
SaveBattle_5377:
; [S130 F7] $DB08+8*A |= bit7: "stat lowered" marker (Surge restores on it).
SetStatLoweredMark_5377:
    push hl
    ld hl, $db08
    call HL_AddA_x8
    set 7, [hl]
    pop hl
    ret


; [S130 F7] $DB08+8*A |= $C0: Transform caster marker.
SetStatBothMarks_5382:
    push hl
    ld hl, $db08
    call HL_AddA_x8
    ld a, [hl]
    or $c0
    ld [hl], a
    pop hl
    ret


    ld a, [$db8a]
    cp $3a
    jr c, jr_052_53dc

    cp $7e
    jr z, jr_052_53dc

    cp $40
    jr c, jr_052_53bc

    jr z, jr_052_53c0

    cp $50
    jr c, jr_052_53c4

    cp $55
    jr c, jr_052_53c8

    cp $58
    jr c, jr_052_53cc

    cp $67
    jr c, jr_052_53d0

    cp $d6
    jr c, jr_052_53d4

    cp $dd
    jr c, jr_052_53d8

    ld a, $1b
    jr jr_052_53de

jr_052_53bc:
    sub $3a
    jr jr_052_53de

jr_052_53c0:
    ld a, $05
    jr jr_052_53de

jr_052_53c4:
    sub $3e
    jr jr_052_53de

jr_052_53c8:
    ld a, $11
    jr jr_052_53de

jr_052_53cc:
    sub $42
    jr jr_052_53de

jr_052_53d0:
    ld a, $14
    jr jr_052_53de

jr_052_53d4:
    sub $51
    jr jr_052_53de

jr_052_53d8:
    sub $bd
    jr jr_052_53de

jr_052_53dc:
    ld a, $00

jr_052_53de:
    ld c, a
    ld b, $00
    ld hl, $53e9
    add hl, bc
    add hl, bc
    jp RST_08


    rst $10
    ld h, b
    rst $10
    ld h, b
    inc d
    ld h, d
    rst $10
    ld h, b
    ld [hl-], a
    ld h, d
    rst $10
    ld h, b
    sbc b
    ld h, d
    xor c
    ld h, d
    cp d
    ld h, d
    bit 4, d
    db $dc, $62, $11
    ld h, e
    rra
    ld h, e
    dec l
    ld h, e
    ld d, a
    ld h, e
    ld h, l
    ld h, e
    ld [hl], e
    ld h, e
    rst $10
    ld h, b
    rst $10
    ld h, b
    rst $10
    ld h, b
    ld a, [de]
    ld h, h
    rst $10
    ld h, b
    rst $10
    ld h, b
    rst $10
    ld h, b
    inc b
    ld h, e
    ld c, c
    ld h, e
    dec sp
    ld h, e
    rst $10
    ld h, b
    ret


; [S130 F1] MISNOMER: loads wBattleTargetIdx and returns hl = $DB05 + 8*TARGET —
; the one-shot appliers (Ahhh/Lure/Licks/trips/WarCry/FREEZY/EerieLite) write the
; VICTIM's +5 (measured S130).
GetTargetStatus5_5422:
GetAttackerBattleSlot:
    ld a, [wBattleTargetIdx]
    ld hl, $db05
    call HL_AddA_x8
    ret


    ld a, [wBattleAttackerIdx]
    ld hl, $dd0b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    or a
    ret z

    ld a, [$db8a]
    ld [$db4c], a
    ld a, $00
    ld [$db4d], a
    ld a, $02
    ld [$db4e], a
    ; [S110 rec] record +2 target mode: bit1 = a GROUP skill
    ld hl, $5400
    rst $10
    ld a, [$db4c]
    and $02
    ret nz

    ld hl, $5808
    rst $10
    ld a, $01
    or a
    ret


ApplySkillDamage:
    ld [$dd70], a
    ld [$dd71], a
    ld a, $80
    ld [$dd6f], a
    ret


BattleFunc_5469:
    ld [$dd70], a
    ld [$dd71], a
    ld a, $88
    ld [$dd6f], a
    ret


BattleFunc_5475:
    ld [$dd70], a
    ld [$dd71], a
    ld a, $84
    ld [$dd6f], a
    ret


BattleFunc_5481:
    ld [$dd70], a
    ld [$dd71], a
    ld a, $93
    ld [$dd6f], a
    ret


SetSkillAnimFlag:
    ld a, $40
    ld [$dd6f], a
    ret


SetSkillAnimB:
    ld a, $90
    ld [$dd6f], a
    ld a, l
    ld [$dd70], a
    ld a, h
    ld [$dd71], a
    ret


LoadBattle_54a1:
    ld a, $d0
    ld [$dd6f], a
    ld a, l
    ld [$dd70], a
    ld a, h
    ld [$dd71], a
    ret


LoadBattle_54af:
    ld a, $98
    ld [$dd6f], a
    ld a, l
    ld [$dd70], a
    ld a, h
    ld [$dd71], a
    ret


SetSkillAnimA:
    ld a, $90
    ld [$dd6f], a
    ld a, l
    ld [$dd70], a
    ld a, h
    ld [$dd71], a
    xor a
    ld [$db56], a
    ld [$db57], a
    ret


LoadBattle_54d2:
    ld a, $98
    ld [$dd6f], a
    ld a, l
    ld [$dd70], a
    ld a, h
    ld [$dd71], a
    xor a
    ld [$db56], a
    ld [$db57], a
    ret


SetHLBattle_54e7:
    ld hl, $b882

CheckSkillResistance:
    ld a, $a8
    ld [$dd6f], a
    ld a, l
    ld [$dd70], a
    ld a, h
    ld [$dd71], a
    ret


LoadBattle_54f8:
    ld a, $a0
    ld [$dd6f], a
    ld a, l
    ld [$dd70], a
    ld a, h
    ld [$dd71], a
    ret


LoadBattle_5506:
    ld a, [wBattleAttackerIdx]
    cp $04
    jr nc, jr_052_5512

    ld bc, $0300
    jr jr_052_551b

jr_052_5512:
    ld a, [$c86c]
    or a
    jr z, jr_052_5532

    ld bc, $0304

jr_052_551b:
    ld d, $00

jr_052_551d:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_052_5524

    inc d

jr_052_5524:
    inc c
    dec b
    jr nz, jr_052_551d

    ld a, d
    cp $01
    jr z, jr_052_5532

    ld hl, $9393
    jr jr_052_5535

jr_052_5532:
    ld hl, $9494

jr_052_5535:
    call SetSkillAnimB
    ret


; [S130 F23] Barrier consumer (FireAir/FrigidAir groups only): target +4
; bit2 -> $DB56 >>= 1, after the breath ladder (measured S130).
BarrierHalveBreath_5539:
BattleTarget_5539:
    ld a, [wBattleTargetIdx]
    ld hl, $db04
    call HL_AddA_x8
    bit 2, [hl]
    ret z

    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    call HLsrl1
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ret


BattleRNG:
    ld a, [$c86c]
    or a
    jr nz, jr_052_5563

    call GenerateRNG
    ret


jr_052_5563:
    push hl
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
    pop hl
    ret


LoadBattle_5589:
    ld a, $00
    ld [$db4d], a
    ld a, [$db77]
    ld [wBattleTargetIdx], a
    ld a, [$db78]
    ld [$db4c], a
    sub $b0
    ld hl, $55c1
    call CalcBattle_6ab1
    ld a, [$db78]
    cp $bb
    ld a, [wBattleTargetIdx]
    jr z, jr_052_55b1

    call CheckMonsterSlot
    jr c, jr_052_55b5

jr_052_55b1:
    call BranchBattle_55c0
    ret


jr_052_55b5:
    ld a, $00
    ld [$c822], a
    ld a, $bf
    ld [$c823], a
    ret


BranchBattle_55c0:
    jp hl


    ld [hl], d
    ld d, [hl]
    ld [hl], d
    ld d, [hl]
    ld [hl], d
    ld d, [hl]
    ld [hl], d
    ld d, [hl]
    ld a, d
    ld d, a
    ld a, d
    ld d, a
    ld c, l
    ld e, b
    ld [hl], d
    ld e, b
    sub a
    ld e, b
    cp h
    ld e, b
    sbc $58
    inc bc
    ld e, c
    ld [hl], c
    ld d, [hl]
    ld [hl], c
    ld d, [hl]
    ld [hl], c
    ld d, [hl]
    ld [hl], c
    ld d, [hl]
    ld [hl], c
    ld d, [hl]
    ld [hl], c
    ld d, [hl]
    ld b, b
    ld e, c
    ld b, b
    ld e, c
    ld b, b
    ld e, c
    cp b
    ld e, c
    ld b, b
    ld e, c
    inc bc
    ld e, d
    dec de
    ld e, d
    inc sp
    ld e, d
    ld l, d
    ld e, d
    add d
    ld e, d
    ld [hl], c
    ld d, [hl]
    ld [hl], c
    ld d, [hl]
    ld [hl], c
    ld d, [hl]
    ld [hl], c
    ld d, [hl]
    ld [hl], c
    ld d, [hl]
    ld [hl], c
    ld d, [hl]
    ld [hl], c
    ld d, [hl]
    ld [hl], c
    ld d, [hl]
    sbc d
    ld e, d

LoadBattle_560b:
Jump_052_560b:
    ld a, [$db78]
    cp $b3
    jr z, jr_052_5616

    xor a
    ld [$db8a], a

Jump_052_5616:
jr_052_5616:
    ld a, $bb
    ld [wBattlePostFlag], a

LoadBattle_561b:
    ld a, $00
    ld [$c822], a
    ld a, [wBattlePostFlag]
    ld [$c823], a
    ld a, $00
    ld [$dd6b], a
    ret


ApplySkillHit:
    ld a, $01
    ld [$db8a], a
    ld a, [wBattleTargetIdx]
    ld hl, $5004
    rst $10
    call SetHLBattle_6c23
    ld de, $ca42
    ld hl, $c1a0
    call Copy4Bytes
    ld a, [$db78]
    cp $c2
    jr c, jr_052_565a

    cp $c7
    jr nc, jr_052_565a

    ld hl, $5809
    rst $10
    ld a, $01
    ld [$c822], a
    jr jr_052_5665

jr_052_565a:
    ld a, [wBattlePostFlag]
    ld [$c823], a
    ld a, $00
    ld [$c822], a

jr_052_5665:
    ld a, [$db78]
    ld [$db8a], a
    ld a, $01
    ld [$dd6b], a
    ret


    ret


    ld a, [$db78]
    cp $b3
    jr nz, jr_052_56ce

    ld hl, $dd69
    inc [hl]
    ld a, [$dd69]
    cp $01
    jr nz, jr_052_56a3

    ld a, [wBattleTargetIdx]
    and $04
    ld c, a
    ld b, $03

jr_052_568c:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_052_5698

    ld a, c
    call SaveBattle_69ef
    jr nz, jr_052_56a3

jr_052_5698:
    inc c
    dec b
    jr nz, jr_052_568c

    xor a
    ld [$db8a], a
    jp Jump_052_5616


jr_052_56a3:
    ld a, [wBattleTargetIdx]
    call SaveBattle_69ef
    jp z, Jump_052_560b

    ld a, [wBattleTargetIdx]
    ld hl, wBattleHP
    call HL_AddA_x2
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld a, [wBattleTargetIdx]
    call GetCombatantMaxHP
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    ld a, l
    ld [$db5a], a
    ld a, h
    ld [$db5b], a
    jp Jump_052_5733


jr_052_56ce:
    ld a, [wBattleTargetIdx]
    call SaveBattle_69ef
    jp z, Jump_052_560b

    ld a, [wBattleTargetIdx]
    cp $04
    jr c, jr_052_56e5

    ld a, $0f
    ld [$db4e], a
    jr jr_052_56ea

jr_052_56e5:
    ld a, $0b
    ld [$db4e], a

jr_052_56ea:
    ld hl, $5401
    rst $10
    ld a, [$db4c]
    ld l, a
    ld a, [$db4d]
    ld h, a
    call RecordDamageRoll_679c
    ld a, l
    ld [$db5a], a
    ld a, h
    ld [$db5b], a
    push hl
    ld a, [wBattleTargetIdx]
    call GetCombatantHP
    pop bc
    add hl, bc
    push hl
    ld a, [wBattleTargetIdx]
    call GetCombatantMaxHP
    pop bc
    call CmpHLvsBC
    jr nc, jr_052_5733

    ld a, c
    sub l
    ld c, a
    ld a, b
    sbc h
    ld b, a
    ld a, [$db5a]
    ld l, a
    ld a, [$db5b]
    ld h, a
    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    ld a, l
    ld [$db5a], a
    ld a, h
    ld [$db5b], a

Jump_052_5733:
jr_052_5733:
    ld a, [wBattleTargetIdx]
    ld hl, wBattleHP
    call HL_AddA_x2
    push hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, [$db5a]
    ld c, a
    ld a, [$db5b]
    ld b, a
    add hl, bc
    ld b, h
    ld c, l
    pop hl
    ld a, c
    ld [hl+], a
    ld [hl], b
    ld a, [$db5a]
    ld l, a
    ld a, [$db5b]
    ld h, a
    ld a, [wBattleTargetIdx]
    bit 2, a
    jr z, jr_052_5766

    ld b, h
    ld c, l
    call BCsrl1
    call LoadBattle_5bd1

jr_052_5766:
    ld a, $84
    ld [wBattlePostFlag], a
    call ApplySkillHit
    call BattleTarget_5bc4
    ld hl, $5f06
    rst $10
    xor a
    ld [$dd6b], a
    ret


    ld a, [$db78]
    cp $b5
    jr nz, jr_052_57ac

    ld a, [wBattleTargetIdx]
    call SaveBattle_6a01
    jp z, Jump_052_560b

    ld a, [wBattleTargetIdx]
    ld hl, wBattleMP
    call HL_AddA_x2
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld a, [wBattleTargetIdx]
    call GetCombatantMaxMP
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    ld a, l
    ld [$db5a], a
    ld a, h
    ld [$db5b], a
    jp Jump_052_5811


jr_052_57ac:
    ld a, [wBattleTargetIdx]
    call SaveBattle_6a01
    jp z, Jump_052_560b

    ld a, [wBattleTargetIdx]
    cp $04
    jr c, jr_052_57c3

    ld a, $10
    ld [$db4e], a
    jr jr_052_57c8

jr_052_57c3:
    ld a, $0b
    ld [$db4e], a

jr_052_57c8:
    ld hl, $5401
    rst $10
    ld a, [$db4c]
    ld l, a
    ld a, [$db4d]
    ld h, a
    call RecordDamageRoll_679c
    ld a, l
    ld [$db5a], a
    ld a, h
    ld [$db5b], a
    push hl
    ld a, [wBattleTargetIdx]
    call GetCombatantMP
    pop bc
    add hl, bc
    push hl
    ld a, [wBattleTargetIdx]
    call GetCombatantMaxMP
    pop bc
    call CmpHLvsBC
    jr nc, jr_052_5811

    ld a, c
    sub l
    ld c, a
    ld a, b
    sbc h
    ld b, a
    ld a, [$db5a]
    ld l, a
    ld a, [$db5b]
    ld h, a
    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    ld a, l
    ld [$db5a], a
    ld a, h
    ld [$db5b], a

Jump_052_5811:
jr_052_5811:
    ld a, [wBattleTargetIdx]
    ld hl, wBattleMP
    call HL_AddA_x2
    push hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, [$db5a]
    ld c, a
    ld a, [$db5b]
    ld b, a
    add hl, bc
    ld b, h
    ld c, l
    pop hl
    ld a, c
    ld [hl+], a
    ld [hl], b
    ld a, [$db5a]
    ld l, a
    ld a, [$db5b]
    ld h, a
    ld a, [wBattleTargetIdx]
    bit 2, a
    jr z, jr_052_5841

    ld b, h
    ld c, l
    call LoadBattle_5bd1

jr_052_5841:
    ld a, $76
    ld [wBattlePostFlag], a
    call ApplySkillHit
    call BattleTarget_5bc4
    ret


    ld a, $9c
    ld [wBattlePostFlag], a
    ld a, [wBattleTargetIdx]
    ld hl, $db02
    call HL_AddA_x8
    ld a, [hl]
    and $03
    jr nz, jr_052_5864

    call BattleTarget_5bb9
    ret


jr_052_5864:
    ld a, [hl]
    and $fc
    ld [hl], a
    call BattleTarget_5baa
    call ApplySkillHit
    call BattleTarget_5bc4
    ret


    ld a, $9d
    ld [wBattlePostFlag], a
    ld a, [wBattleTargetIdx]
    ld hl, $db02
    call HL_AddA_x8
    ld a, [hl]
    and $40
    jr nz, jr_052_5889

    call BattleTarget_5bb9
    ret


jr_052_5889:
    call SaveBattle_6b0b
    ld a, [hl]
    and $bf
    ld [hl], a
    call ApplySkillHit
    call BattleTarget_5bc4
    ret


    ld a, $dc
    ld [wBattlePostFlag], a
    ld a, [wBattleTargetIdx]
    ld hl, $db02
    call HL_AddA_x8
    ld a, [hl]
    and $10
    jr nz, jr_052_58ae

    call BattleTarget_5bb9
    ret


jr_052_58ae:
    call SaveBattle_6b0b
    ld a, [hl]
    and $ef
    ld [hl], a
    call ApplySkillHit
    call BattleTarget_5bc4
    ret


    ld a, $9f
    ld [wBattlePostFlag], a
    ld a, [wBattleTargetIdx]
    ld hl, $db02
    call HL_AddA_x8
    ld a, [hl]
    and $20
    jr nz, jr_052_58d3

    call BattleTarget_5bb9
    ret


jr_052_58d3:
    ld a, [hl]
    and $df
    ld [hl], a
    call ApplySkillHit
    call BattleTarget_5bc4
    ret


    ld a, $db
    ld [wBattlePostFlag], a
    ld a, [wBattleTargetIdx]
    ld hl, $db02
    call HL_AddA_x8
    ld a, [hl]
    and $8c
    jr nz, jr_052_58f5

    call BattleTarget_5bb9
    ret


jr_052_58f5:
    call SaveBattle_6b0b
    ld a, [hl]
    and $73
    ld [hl], a
    call ApplySkillHit
    call BattleTarget_5bc4
    ret


    ld a, [$db77]
    call CheckMonsterSlot
    jr nc, jr_052_593c

    jr z, jr_052_593c

    ld a, [$db77]
    ld [$db4c], a
    ld hl, $510a
    rst $10
    ld a, [$db77]
    ld b, a
    call SaveBattle_51dd
    ld a, b
    ld hl, wBattleHP
    call HL_AddA_x2
    ld d, h
    ld e, l
    ld a, b
    ld hl, wBattleMaxHP
    call HL_AddA_x2
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl]
    ld [de], a
    ld a, $9e
    ld [wBattlePostFlag], a
    call ApplySkillHit
    ret


jr_052_593c:
    call BattleTarget_5bb9
    ret


    ld a, $01
    ld [$db8a], a
    ld a, [$db77]
    cp $04
    jr c, jr_052_5984

    sub $04
    ld hl, $db83
    push hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    push hl
    ld a, $0f
    ld [$db4e], a
    ld hl, $5401
    rst $10
    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    ld a, [$db4c]
    ld c, a
    ld a, [$db4d]
    ld b, a
    pop hl
    add hl, bc
    ld bc, $0640
    call CmpHLvsBC
    ld b, h
    ld c, l
    jr c, jr_052_597e

    ld bc, $0640

jr_052_597e:
    pop hl
    ld a, c
    ld [hl+], a
    ld [hl], b
    jr jr_052_59b0

jr_052_5984:
    ld hl, wBattleLVL
    call HL_AddA_x2
    push hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    push hl
    ld a, $0b
    ld [$db4e], a
    ld hl, $5401
    rst $10
    pop hl
    ld a, [$db4c]
    ld c, a
    ld a, [$db4d]
    ld b, a
    ld a, l
    sub c
    ld c, a
    ld a, h
    sbc b
    ld b, a
    jr nc, jr_052_59ac

    ld bc, $0000

jr_052_59ac:
    pop hl
    ld a, c
    ld [hl+], a
    ld [hl], b

jr_052_59b0:
    call ApplySkillHit
    xor a
    ld [$da33], a
    ret


    ld a, $01
    ld [$db8a], a
    ld a, [$db77]
    cp $04
    jr c, jr_052_59e0

    sub $04
    ld hl, $db83
    push hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld bc, $0005
    add hl, bc
    ld bc, $0400
    call CmpHLvsBC
    ld b, h
    ld c, l
    jr c, jr_052_59f7

    ld bc, $0400
    jr jr_052_59f7

jr_052_59e0:
    ld hl, wBattleLVL
    call HL_AddA_x2
    push hl
    ld a, [hl+]
    ld h, [hl]
    sub $05
    ld l, a
    ld a, h
    sbc $00
    ld h, a
    ld b, h
    ld c, l
    jr nc, jr_052_59f7

    ld bc, $0000

jr_052_59f7:
    pop hl
    ld a, c
    ld [hl+], a
    ld [hl], b
    call ApplySkillHit
    xor a
    ld [$da33], a
    ret


    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    ret c

    call LoadBattle_5ab2
    call GetBattleStatAddr1
    swap a
    and $03
    call ElemLadderA
    call LoadBattle_5ad4
    ret


    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    ret c

    call LoadBattle_5ab2
    call GetBattleStatAddr1
    rlca
    rlca
    and $03
    call ElemLadderA
    call LoadBattle_5ad4
    ret


    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    ret c

    ld a, [wBattleTargetIdx]
    ld hl, $db03
    call HL_AddA_x8
    bit 0, [hl]
    ret nz

    call SetHLBattle_5cbc
    jr nc, jr_052_5a62

    ld a, $01
    ld [$db8a], a
    ld a, [$db77]
    ld hl, $db03
    call HL_AddA_x8
    set 0, [hl]
    ld a, $88
    ld [wBattlePostFlag], a
    jr jr_052_5a66

jr_052_5a62:
    call LoadBattle_5b9e
    ret


jr_052_5a66:
    call ApplySkillHit
    ret


    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    ret c

    call LoadBattle_5ab2
    call BattleFunc_67bb
    rrca
    rrca
    and $03
    call ElemLadderA
    call LoadBattle_5ad4
    ret


    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    ret c

    call LoadBattle_5ab2
    call BattleFunc_67cf
    rrca
    rrca
    and $03
    call ElemLadderA
    call LoadBattle_5ad4
    ret


    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    ret c

    call LoadBattle_5ab2
    call BattleFunc_67bb
    swap a
    and $03
    call ElemLadderA
    call LoadBattle_5ad4
    ret


LoadBattle_5ab2:
    ld a, $0b
    ld [$db4e], a
    ld hl, $5401
    rst $10
    ld a, $82
    ld [wBattlePostFlag], a
    ld a, $00
    ld [$db54], a
    ld a, [$db4c]
    ld l, a
    ld a, [$db4d]
    ld h, a
    call RecordDamageRoll_679c
    ld hl, $0000
    ret


LoadBattle_5ad4:
    ld a, [$db56]
    ld e, a
    ld a, [$db57]
    ld d, a
    ld a, e
    or d
    jr z, jr_052_5af2

    call BattleTarget_5af6
    jr c, jr_052_5af2

    call LoadBattle_5b26
    ld hl, $5f04
    rst $10
    ld hl, $5502
    rst $10
    jr jr_052_5af5

jr_052_5af2:
    call BattleFunc_5b98

jr_052_5af5:
    ret


BattleTarget_5af6:
    ld a, [wBattleTargetIdx]
    ld hl, $db09
    call HL_AddA_x8
    ld a, [hl]
    and $03
    jr z, jr_052_5b24

    ld h, d
    ld l, e
    bit 1, a
    jr nz, jr_052_5b0f

    call HLsrl1
    jr jr_052_5b14

jr_052_5b0f:
    ld a, $0a
    call Div16x8To16

jr_052_5b14:
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ld d, h
    ld e, l
    ld a, h
    or l
    jr nz, jr_052_5b24

    scf
    ret


jr_052_5b24:
    xor a
    ret


LoadBattle_5b26:
    ld a, $01
    ld [$db8a], a
    ld a, [wBattleTargetIdx]
    ld hl, wBattleHP
    call HL_AddA_x2
    ld a, l
    ld [$db61], a
    ld a, h
    ld [$db62], a
    ld a, [hl+]
    ld h, [hl]
    sub e
    ld c, a
    ld a, h
    sbc d
    ld b, a
    ld a, e
    ld [$db5a], a
    ld a, d
    ld [$db5b], a
    jr nc, jr_052_5b71

    ld a, [$db61]
    ld l, a
    ld a, [$db62]
    ld h, a
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    ld a, e
    ld [$db5a], a
    ld a, d
    ld [$db5b], a
    ld bc, $0000
    ld a, [wBattleTargetIdx]
    ld hl, $dd1b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    set 0, [hl]

jr_052_5b71:
    push bc
    ld a, [$db5a]
    ld c, a
    ld a, [$db5b]
    ld b, a
    call BCsrl1
    call LoadBattle_5be3
    pop bc
    ld a, [$db61]
    ld l, a
    ld a, [$db62]
    ld h, a
    ld a, c
    ld [hl+], a
    ld [hl], b
    ld a, $82
    ld [wBattlePostFlag], a
    call SetHLBattle_50e9
    call ApplySkillHit
    ret


BattleFunc_5b98:
    ld bc, $0002
    call LoadBattle_5be3

LoadBattle_5b9e:
    ld a, $b8
    ld [wBattlePostFlag], a
    call SetHLBattle_6c23
    call LoadBattle_561b
    ret


BattleTarget_5baa:
    ld a, [wBattleTargetIdx]
    bit 2, a
    jr z, jr_052_5bb8

    ld bc, $0064
    call LoadBattle_5bd1
    ret


jr_052_5bb8:
    ret


BattleTarget_5bb9:
    ld a, [wBattleTargetIdx]
    bit 2, a
    jr z, jr_052_5bc0

jr_052_5bc0:
    call LoadBattle_560b
    ret


BattleTarget_5bc4:
    ld a, [wBattleTargetIdx]
    cp $04
    jr nc, jr_052_5bd0

    ld a, $70
    call PlaySoundEffect

jr_052_5bd0:
    ret


LoadBattle_5bd1:
    ld a, [$db83]
    ld l, a
    ld a, [$db84]
    ld h, a
    add hl, bc
    ld a, l
    ld [$db83], a
    ld a, h
    ld [$db84], a
    ret


LoadBattle_5be3:
    ld a, [$db83]
    ld l, a
    ld a, [$db84]
    ld h, a
    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    jr nc, jr_052_5bf6

    ld hl, $0000

jr_052_5bf6:
    ld a, l
    ld [$db83], a
    ld a, h
    ld [$db84], a
    ret


BattleCall_5bff:
    call StoreDamageResult
    call BattleFunc_67bb
    swap a
    and $03
    call ElemLadderA
    ret


BattleCall_5c0d:
    call StoreDamageResult
    call BattleFunc_67bb
    rrca
    rrca
    and $03
    call ElemLadderA
    ret


BattleCall_5c1b:
    call StoreDamageResult
    call BattleFunc_67bb
    and $03
    call ElemLadderA
    ret


BattleCall_5c27:
    call StoreDamageResult

BattleCall_5c2a:
    call GetBattleStatAddr1
    rlca
    rlca
    and $03
    call ElemLadderA
    ret


BattleCall_5c35:
    call StoreDamageResult
    call GetBattleStatAddr1
    swap a
    and $03
    call ElemLadderA
    ret


BattleCall_5c43:
    call StoreDamageResult
    call GetBattleStatAddr1
    rrca
    rrca
    and $03
    call ElemLadderA
    ret


; [S130 F1] Death-class hit helper (res type 8, $DD2A bits5:4): BossProtectionGate
; first (no step on veto), NO Compare_6adc; id < $72 -> $6749, $82 -> $6733, else B.
HitDeath_5c51:
BattleCall_5c51:
    call SetHLBattle_6b21
    jp z, Jump_052_6b1e

    ld hl, $0000
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    call GetTargetBattleSlot
    call BattleFunc_67c5
    swap a
    and $03
    ld [$db4e], a
    ld a, [$db8a]
    cp $72
    jr c, jr_052_5c81

    cp $82
    jr z, jr_052_5c88

    ld a, [$db4e]
    call CheckTargetGuardB
    ret


jr_052_5c81:
    ld a, [$db4e]
    call HitLadderBeat_6749
    ret


jr_052_5c88:
    ld a, [$db4e]
    call HitLadderKamikaze_6733
    ret


SetHLBattle_5c8f:
    ld hl, $0000
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    call StoreDamageResult
    call BattleFunc_67c5
    rlca
    rlca
    and $03
    ld [$db4e], a
    call Compare_6adc
    jr z, jr_052_5cae

    scf
    ret


jr_052_5cae:
    ld a, [$db8a]
    cp $15
    ld a, [$db4e]
    jp z, Jump_052_6710

    jp Jump_052_6749


SetHLBattle_5cbc:
    ld hl, $0000
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    call GetTargetBattleSlot
    call BattleFunc_67c5
    and $03
    call Compare_6adc
    jr z, jr_052_5cd6

    scf
    ret


jr_052_5cd6:
    call CheckTargetGuardB
    ret


SetHLBattle_5cda:
    ld hl, $0000
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    call GetTargetBattleSlot
    call GetBattleStatAddr1
    and $03
    call Compare_6adc
    jr z, jr_052_5cf4

    scf
    ret


jr_052_5cf4:
    ld b, a
    ld a, [$db8a]
    cp $72
    ld a, b
    jr z, jr_052_5d01

    call CheckTargetGuardB
    ret


jr_052_5d01:
    call HitLadderBeat_6749
    ret


; [S130 F1] Confusion hit helper: res 11 ($DD2B bits7:6), Compare_6adc, $6749.
HitConfuse_5d05:
SetHLBattle_5d05:
    ld hl, $0000
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    call GetTargetBattleSlot
    call BattleFunc_67ca
    rlca
    rlca
    and $03
    call Compare_6adc
    jr z, jr_052_5d21

    scf
    ret


jr_052_5d21:
    call HitLadderBeat_6749
    ret


; [S130 F5] MP-drain hit roll: level = res type 9 ($DD2A+7t bits 3:2);
; Compare_6adc: level 3 -> ladder B "never", $DB42[att] bit2 -> sure hit;
; else CheckTargetGuardB (ladder B on target +5, 1 BattleRNG step). CF=hit.
MPDrainHitRoll_5d25:
SetHLBattle_5d25:
    ld hl, $0000
    ld a, l
    ld [$db5a], a
    ld a, h
    ld [$db5b], a
    call GetTargetBattleSlot
    call BattleFunc_67c5
    rrca
    rrca
    and $03
    ld [$db4e], a
    call Compare_6adc
    jr z, jr_052_5d44

    scf
    ret


jr_052_5d44:
    call CheckTargetGuardB
    ret


; [S130 F5] RobMagic tail: drain (BattleTarget_5d7a), caster MP += it,
; capped at MaxMP (SaveBattle_6a01).
BattleCall_5d48:
    call BattleTarget_5d7a
    ld a, [wBattleAttackerIdx]
    ld hl, wBattleMP
    call HL_AddA_x2
    push hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    add hl, bc
    ld b, h
    ld c, l
    pop hl
    ld a, c
    ld [hl+], a
    ld [hl], b
    ld a, [wBattleAttackerIdx]
    call SaveBattle_6a01
    jr nc, jr_052_5d79

    ld a, [wBattleAttackerIdx]
    ld bc, $dbd4
    add a
    add c
    ld c, a
    ld a, $00
    adc b
    ld b, a
    ld a, [bc]
    ld [hl-], a
    dec bc
    ld a, [bc]
    ld [hl], a

jr_052_5d79:
    ret


; [S130 F5] Drain: $DB56 := min(target MP, (attacker level >> 2) + 5);
; target MP -= it (MP 0 -> 0).
MPDrainAmount_5d7a:
BattleTarget_5d7a:
    ld a, [wBattleTargetIdx]
    ld hl, wBattleMP
    call HL_AddA_x2
    push hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    or h
    jr z, jr_052_5db9

    ld a, [wBattleAttackerIdx]
    ld de, $db9b
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    srl a
    srl a
    add $05
    ld c, a
    ld b, $00
    call CmpHLvsBC
    jr nc, jr_052_5da7

    ld b, h
    ld c, l

jr_052_5da7:
    ld a, c
    ld [$db56], a
    ld a, b
    ld [$db57], a
    ld a, [$db56]
    ld c, a
    ld a, [$db57]
    ld b, a
    jr jr_052_5dc4

jr_052_5db9:
    ld bc, $0000
    ld a, c
    ld [$db56], a
    ld a, b
    ld [$db57], a

jr_052_5dc4:
    pop hl
    ld a, [hl]
    sub c
    ld [hl+], a
    ld a, [hl]
    sbc b
    ld [hl], a
    ret


; [S130 F1] DEF-down hit helper: res 12 ($DD2B bits5:4), Compare_6adc; $7A -> $6749, else B.
HitDefDown_5dcc:
SetHLBattle_5dcc:
; [S130 F7] carry = DEF-down lands: res 12 ($DD2B bits 5:4) L3 never, $DB42[att]
; [S130 F7] bit2 sure, else CheckTargetGuardB (SickLick $7A: HitLadderBeat_6749).
SapHitRoll_5dcc:
    ld hl, $0000
    ld a, l
    ld [$db5a], a
    ld a, h
    ld [$db5b], a
    call GetTargetBattleSlot
    call BattleFunc_67ca
    swap a
    and $03
    ld [$db4e], a
    call Compare_6adc
    jr z, jr_052_5deb

    scf
    ret


jr_052_5deb:
    ld b, a
    ld a, [$db8a]
    cp $7a
    ld a, b
    jr z, jr_052_5df8

    call CheckTargetGuardB
    ret


jr_052_5df8:
    call HitLadderBeat_6749
    ret


; [S130 F7] DEF > 1 required; DEF -= baseDEF>>1 (floor 0); $DB56 = amount; nc = fail.
StatDefDown_5dfc:
    ld a, [wBattleTargetIdx]
    call GetCombatantDEF
    ld b, h
    ld c, l
    ld hl, $0001
    call CmpHLvsBC
    jr c, jr_052_5e0e

    xor a
    ret


jr_052_5e0e:
    ld a, [wBattleTargetIdx]
    call GetBaseDEF_52b1
    call BCsrl1
    ld a, [wBattleTargetIdx]
    ld hl, wBattleDEF
    call HL_AddA_x2
    push hl
    ld a, [hl+]
    ld h, [hl]
    or h
    pop hl
    jr z, jr_052_5e3c

    ld a, c
    ld [$db56], a
    ld a, b
    ld [$db57], a
    ld a, [hl]
    sub c
    ld [hl+], a
    ld a, [hl]
    sbc b
    ld [hl], a
    jr nc, jr_052_5e3a

    xor a
    ld [hl-], a
    ld [hl], a

jr_052_5e3a:
    scf
    ret


jr_052_5e3c:
    xor a
    ret


; [S130 F7] DEF += baseDEF>>1 when strictly under 999 and the cap; over -> clamp to
; [S130 F7] the check's BC (999 even above a x2 cap, else the cap); $DB56 = added.
StatDefUp_5e3e:
    ld a, [wBattleTargetIdx]
    call UpperStatCapCheck_6a13
    jr nc, jr_052_5e92

    jr z, jr_052_5e92

    ld a, [wBattleTargetIdx]
    call GetBaseDEF_52b1
    call BCsrl1
    ld a, c
    ld [$db56], a
    ld a, b
    ld [$db57], a
    ld a, [wBattleTargetIdx]
    ld hl, wBattleDEF
    call HL_AddA_x2
    ld a, [hl]
    add c
    ld [hl+], a
    ld a, [hl]
    adc b
    ld [hl], a
    ld a, [wBattleTargetIdx]
    push hl
    call UpperStatCapCheck_6a13
    pop hl
    jr c, jr_052_5e90

    ld a, [hl-]
    ld e, [hl]
    ld d, a
    ld a, c
    ld [hl+], a
    ld [hl], b
    ld a, e
    sub c
    ld e, a
    ld a, d
    sbc b
    ld d, a
    ld a, [$db56]
    sub e
    ld e, a
    ld a, [$db57]
    sbc d
    ld d, a
    ld a, e
    ld [$db56], a
    ld a, d
    ld [$db57], a

jr_052_5e90:
    scf
    ret


jr_052_5e92:
    xor a
    ret


; [S130 F7] carry = AGL-down lands: res 13 ($DD2B bits 3:2), same ladder as Sap.
SlowHitRoll_5e94:
    ld hl, $0000
    ld a, l
    ld [$db5a], a
    ld a, h
    ld [$db5b], a
    call GetTargetBattleSlot
    call BattleFunc_67ca
    rrca
    rrca
    and $03
    call Compare_6adc
    jr z, jr_052_5eb0

    scf
    ret


jr_052_5eb0:
    call CheckTargetGuardB
    ret


; [S130 F7] AGL >= 2 required; AGL -= baseAGL>>1 (minus 1 if AGL == it); borrow -> 1.
StatAglDown_5eb4:
    ld a, [wBattleTargetIdx]
    call GetBaseAGL_52c6
    call BCsrl1
    ld a, [wBattleTargetIdx]
    ld hl, wBattleAGL
    call HL_AddA_x2
    push hl
    ld d, $00
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call CmpHLvsBC
    jr nz, jr_052_5ed3

    ld d, $01

jr_052_5ed3:
    push bc
    ld bc, $0002
    call CmpHLvsBC
    pop bc
    pop hl
    jr c, jr_052_5f06

    ld a, c
    sub d
    ld c, a
    ld a, b
    sbc $00
    ld b, a
    ld a, c
    ld [$db56], a
    ld a, b
    ld [$db57], a
    ld a, [hl]
    ld e, a
    sub c
    ld [hl+], a
    ld a, [hl]
    ld d, a
    sbc b
    ld [hl], a
    jr nc, jr_052_5f04

    xor a
    ld [hl-], a
    ld [hl], $01
    dec de
    ld a, e
    ld [$db56], a
    ld a, d
    ld [$db57], a

jr_052_5f04:
    scf
    ret


jr_052_5f06:
    xor a
    ret


; [S130 F7] AGL += baseAGL>>1 when under 511 and the cap; over -> clamp (511 or cap).
StatAglUp_5f08:
    ld a, [wBattleTargetIdx]
    call AglUpStatCapCheck_6a49
    jr nc, jr_052_5f5c

    ld a, [wBattleTargetIdx]
    call GetBaseAGL_52c6
    call BCsrl1
    ld a, c
    ld [$db56], a
    ld a, b
    ld [$db57], a
    ld a, [wBattleTargetIdx]
    ld hl, wBattleAGL
    call HL_AddA_x2
    ld a, [hl]
    add c
    ld [hl+], a
    ld a, [hl]
    adc b
    ld [hl], a
    ld a, [wBattleTargetIdx]
    push hl
    call AglUpStatCapCheck_6a49
    pop hl
    jr c, jr_052_5f5a

    dec hl
    ld a, [hl+]
    sub c
    ld e, a
    ld a, [hl]
    sbc b
    ld d, a
    ld a, b
    ld [hl-], a
    ld [hl], c
    ld a, [$db56]
    ld c, a
    ld a, [$db57]
    ld b, a
    ld a, c
    sub e
    ld e, a
    ld a, b
    sbc d
    ld d, a
    ld a, e
    ld [$db56], a
    ld a, d
    ld [$db57], a

jr_052_5f5a:
    scf
    ret


jr_052_5f5c:
    xor a
    ret


; [S130 F7] caster := TARGET base MaxHP(<=999)/MaxMP (HP/MP clamped), ATK/DEF/AGL
; [S130 F7] (not INT), then res ($DD28) + skills ($DC64); target==caster reverts.
; [S130 F9] the res/skill tail: SetupBattle_52d8/_5325 read the target's SOURCE
; (party record / enemy row / for a helper slot the enemy_stats row $0100|$DC3C
; = 472-475, NOT its own row); $DB in the skill list ends it ($FF). Measured.
TransformCopyStats_5f5e:
    ld a, [wBattleAttackerIdx]
    ld hl, $c1cd
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    and $80
    ld [hl], a
    ld a, [wBattleTargetIdx]
    call GetBaseMaxHP_5270
    ld a, [wBattleAttackerIdx]
    ld hl, wBattleHP
    call HL_AddA_x2
    push hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call CmpHLvsBC
    pop hl
    jr c, jr_052_5f8a

    ld a, c
    ld [hl+], a
    ld [hl], b

jr_052_5f8a:
    ld a, [wBattleAttackerIdx]
    ld hl, wBattleMaxHP
    call HL_AddA_x2
    ld a, c
    ld [hl+], a
    ld [hl], b
    ld a, [wBattleTargetIdx]
    call GetBaseMaxMP_528d
    ld a, [wBattleAttackerIdx]
    ld hl, wBattleMP
    call HL_AddA_x2
    push hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call CmpHLvsBC
    pop hl
    jr c, jr_052_5fb2

    ld a, c
    ld [hl+], a
    ld [hl], b

jr_052_5fb2:
    ld a, [wBattleAttackerIdx]
    ld hl, wBattleMaxMP
    call HL_AddA_x2
    ld a, c
    ld [hl+], a
    ld [hl], b
    ld a, [wBattleAttackerIdx]
    ld hl, wBattleATK
    call HL_AddA_x2
    ld a, [wBattleTargetIdx]
    call GetBaseATK_529f
    ld a, c
    ld [hl+], a
    ld [hl], b
    ld a, [wBattleAttackerIdx]
    ld hl, wBattleDEF
    call HL_AddA_x2
    ld a, [wBattleTargetIdx]
    call GetBaseDEF_52b1
    ld a, c
    ld [hl+], a
    ld [hl], b
    ld a, [wBattleAttackerIdx]
    ld hl, wBattleAGL
    call HL_AddA_x2
    ld a, [wBattleTargetIdx]
    call GetBaseAGL_52c6
    ld a, c
    ld [hl+], a
    ld [hl], b
    ld a, [wBattleTargetIdx]
    call SetupBattle_52d8
    ld a, [wBattleAttackerIdx]
    ld de, $dd28
    ld b, a
    add a
    add b
    add a
    add b
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    call LoadBattle_6a75
    ld a, [wBattleTargetIdx]
    call SetupBattle_5325
    ld a, [wBattleAttackerIdx]
    ld de, $dc64
    swap a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld c, $00

jr_052_6024:
    ld a, [hl]
    ld [$db4c], a
    cp $db
    call z, LoadBattle_6077
    cp $ff
    jr z, jr_052_605d

    ld a, $00
    ld [$db4d], a
    ld a, $01
    ld [$db4e], a
    push af
    push bc
    push de
    push hl
    ; [S110 rec] record +1 high nibble = AI option-list tag
    ld hl, $5400
    rst $10
    pop hl
    pop de
    pop bc
    pop af
    ld a, [$db4c]
    swap a
    and $0f
    ld a, a
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    inc c
    dec b
    jr nz, jr_052_6024

    ld a, c
    cp $08
    jr z, jr_052_606b

jr_052_605d:
    ld a, $00
    ld [de], a
    inc de
    ld a, $ff
    ld [de], a
    inc de
    inc c
    ld a, c
    cp $08
    jr nz, jr_052_605d

jr_052_606b:
    call BattleTarget_6acf
    ld c, [hl]
    ld a, [wBattleAttackerIdx]
    ld b, a
    call BattleCall_5213
    ret


LoadBattle_6077:
    ld a, $ff
    ld [$db4c], a
    ret


; [S130 F5] Heal amount: ids $2D/$2F/$32/$96 -> MaxHP, else the record roll
; (StoreDamageResult); HP := min(HP + amount, MaxHP); $DB56 = amount.
HealAmountApply_607d:
LoadBattle_607d:
    ld a, [$db8a]
    cp $2d
    jr z, jr_052_609d

    cp $2f
    jr z, jr_052_609d

    cp $32
    jr z, jr_052_609d

    cp $96
    jr z, jr_052_609d

    call StoreDamageResult
    ld a, [$db56]
    ld e, a
    ld a, [$db57]
    ld d, a
    jr jr_052_60b1

jr_052_609d:
    ld a, [wBattleTargetIdx]
    ld hl, wBattleMaxHP
    call HL_AddA_x2
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    ld a, e
    ld [$db56], a
    ld a, d
    ld [$db57], a

jr_052_60b1:
    ld a, [wBattleTargetIdx]
    ld hl, wBattleHP
    call HL_AddA_x2
    push hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, l
    add e
    ld c, a
    ld a, h
    adc d
    ld b, a
    ld a, [wBattleTargetIdx]
    call GetCombatantMaxHP
    call CmpHLvsBC
    jr nc, jr_052_60d1

    ld b, h
    ld c, l

jr_052_60d1:
    pop hl
    ld a, c
    ld [hl+], a
    ld [hl], b
    scf
    ret


CalcSkillDefense:
    call BattleRNG
    ld a, [wBattleTargetIdx]
    ld hl, wBattleDEF
    call HL_AddA_x2
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    call BCsrl1
    ld a, [wBattleAttackerIdx]
    call GetCombatantATK
    call CmpHLvsBC
    jr z, jr_052_6112

    jr c, jr_052_6112

    ld a, l
    sub c
    ld e, a
    ld a, h
    sbc b
    ld d, a
    srl d
    rr e
    push hl
    push bc
    ld b, d
    ld c, e
    call HLsrl4
    call CmpHLvsBC
    pop bc
    pop hl
    jr z, jr_052_611d

    jr nc, jr_052_611d

    jr jr_052_6138

jr_052_6112:
    ld a, [wRNG1]
    and $01
    ld e, a
    ld d, $00
    jp Jump_052_6183


jr_052_611d:
    call HLsrl4
    ld a, h
    or l
    jr z, jr_052_6112

    ld b, h
    ld c, l
    push hl
    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    call Div16x16To16
    pop hl
    ld d, b
    ld e, c
    jp Jump_052_6183


jr_052_6138:
    push de
    ld h, d
    ld l, e
    call HLsrl3
    pop de
    ld a, h
    or l
    jr z, jr_052_6173

    push hl
    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    pop bc
    ld a, c
    inc a
    push de
    call Div16x8To16
    pop de
    ld c, a
    ld b, $00
    call BCsrl1
    ld a, [wRNG2]
    and $0f
    or a
    jr z, jr_052_6173

    bit 3, a
    jr nz, jr_052_616e

    ld a, e
    sub c
    ld e, a
    ld a, d
    sbc b
    ld d, a
    jr jr_052_6173

jr_052_616e:
    ld h, b
    ld l, c
    add hl, de
    ld d, h
    ld e, l

jr_052_6173:
    ld a, [wRNG1]
    and $03
    or a
    jr z, jr_052_6183

    bit 0, a
    jr z, jr_052_6182

    inc de
    jr jr_052_6183

jr_052_6182:
    dec de

Jump_052_6183:
jr_052_6183:
    ld a, e
    ld [$db56], a
    ld a, d
    ld [$db57], a
    call DamageSlot2AdjustFloor_61ec
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    ld a, h
    or l
    ret nz

    ld b, a
    ld a, [wRNG2]
    and $01
    ld c, a
    ld a, c
    ld [$db56], a
    ld a, b
    ld [$db57], a
    ret


jr_052_61a9:
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    ld a, [wBattleAttackerIdx]
    and $03
    cp $03
    ret z

    or a
    ret z

    jr jr_052_6205

jr_052_61bd:
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    ld a, [wBattleTargetIdx]
    and $03
    cp $03
    ret z

    or a
    ret z

    jr jr_052_6205

    ld a, [$c86c]
    or a
    jr nz, jr_052_61a9

    ld a, [wBattleAttackerIdx]
    cp $03
    ret nc

    or a
    ret z

    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    ld a, [wBattleAttackerIdx]
    jr jr_052_6205

DamageSlot2AdjustFloor_61ec:
    ld a, [$c86c]
    or a
    jr nz, jr_052_61bd

    ld a, [wBattleTargetIdx]
    cp $03
    ret nc

    or a
    ret z

    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    ld a, [wBattleTargetIdx]

jr_052_6205:
    cp $02
    ret nz

    call DamageMul8Tenths_69b7
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ret


; [S130 F23] Ramming damage: target HP*8/10+1, ladder A res 14.
RammingDamage_6214:
BattleTarget_6214:
    ld a, [wBattleTargetIdx]
    call GetCombatantHP
    call DamageMul8Tenths_69b7
    inc hl
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    call GetTargetBattleSlot
    call BattleFunc_67ca
    and $03
    call ElemLadderA
    ret


; [S130 F23] NOT boss-gated: $3E is listed in BossProtectionGate_51aa ($53)
; but nothing on this path calls it (measured: db73=1 hits land).
KamikazeDamage_6232:
    call GetTargetBattleSlot
    call BattleFunc_67ca
    and $03
    call HitLadderKamikaze_6733
    jr nc, jr_052_628b

    ld a, [wBattleAttackerIdx]
    call GetCombatantHP
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, h
    or a
    jr nz, jr_052_6259

    ld a, l
    cp $01
    jr z, jr_052_6281

jr_052_6259:
    ld a, [$c86c]
    or a
    jr nz, jr_052_6265

    ld a, [$db73]
    or a
    jr nz, jr_052_626e

jr_052_6265:
    ld a, [wBattleTargetIdx]
    call GetCombatantHP
    dec hl
    jr jr_052_627a

jr_052_626e:
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    dec hl
    call HLsrl1

jr_052_627a:
    ld a, h
    or l
    jr nz, jr_052_6281

    ld hl, $0001

jr_052_6281:
    scf
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ret


jr_052_628b:
    ld hl, $0000
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    xor a
    ret


FireSlashDamage_6298:            ; [S130 F23] calcdef + slash ladder, res 0
BattleCall_6298:
    call CalcSkillDefense
    call GetTargetBattleSlot
    call BattleFunc_67bb
    swap a
    and $03
    call ElemLadderSlash
    ret


BoltSlashDamage_62a9:            ; [S130 F23] calcdef + slash ladder, res 4
BattleCall_62a9:
    call CalcSkillDefense
    call GetTargetBattleSlot
    call GetBattleStatAddr1
    swap a
    and $03
    call ElemLadderSlash
    ret


VacuSlashDamage_62ba:            ; [S130 F23] calcdef + slash ladder, res 3
BattleCall_62ba:
    call CalcSkillDefense
    call GetTargetBattleSlot
    call GetBattleStatAddr1
    rlca
    rlca
    and $03
    call ElemLadderSlash
    ret


IceSlashDamage_62cb:             ; [S130 F23] calcdef + slash ladder, res 5
BattleCall_62cb:
    call CalcSkillDefense
    call GetTargetBattleSlot
    call GetBattleStatAddr1
    rrca
    rrca
    and $03
    call ElemLadderSlash
    ret


MetalCutDamage_62dc:             ; [S130 F23] calcdef; $DB8B+t bit0 -> x1.5+1
BattleCall_62dc:
    call CalcSkillDefense
    ld a, [wBattleTargetIdx]
    ld hl, $db8b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    bit 0, [hl]
    jr z, jr_052_6303

    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    call SetupBattle_6979
    inc hl
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a

jr_052_6303:
    ret


CheckIsSlime:
    call CalcSkillDefense
    call LookupTargetSpecies
    or a
    jr nz, jr_052_6310

    call LoadDamageValue

jr_052_6310:
    ret


CheckIsDragon:
    call CalcSkillDefense
    call LookupTargetSpecies
    cp $01
    jr nz, jr_052_631e

    call LoadDamageValue

jr_052_631e:
    ret


CheckIsBeast:
    call CalcSkillDefense
    call LookupTargetSpecies
    cp $02
    jr nz, jr_052_632c

    call LoadDamageValue

jr_052_632c:
    ret


CheckIsFlying:
    call CalcSkillDefense
    call LookupTargetSpecies
    cp $03
    jr nz, jr_052_633a

    call LoadDamageValue

jr_052_633a:
    ret


CheckIsPlant:
    call CalcSkillDefense
    call LookupTargetSpecies
    cp $04
    jr nz, jr_052_6348

    call LoadDamageValue

jr_052_6348:
    ret


CheckIsBug:
    call CalcSkillDefense
    call LookupTargetSpecies
    cp $05
    jr nz, jr_052_6356

    call LoadDamageValue

jr_052_6356:
    ret


CheckIsDevil:
    call CalcSkillDefense
    call LookupTargetSpecies
    cp $06
    jr nz, jr_052_6364

    call LoadDamageValue

jr_052_6364:
    ret


CheckIsZombie:
    call CalcSkillDefense
    call LookupTargetSpecies
    cp $07
    jr nz, jr_052_6372

    call LoadDamageValue

jr_052_6372:
    ret


CheckIsMaterial:
    call CalcSkillDefense
    call LookupTargetSpecies
    cp $08
    jr nz, jr_052_6380

    call LoadDamageValue

jr_052_6380:
    ret


; [S130 F23] MultiCut: record roll by side, x1.3125 vs family 7 (Zombie),
; then the BREATH ladder res 3 (measured S130).
MultiCutDamage_6381:
LoadBattle_6381:
    ld a, [$db8a]
    ld [$db4c], a
    ld a, $00
    ld [$db4d], a
    ld a, [$c86c]
    or a
    jr nz, jr_052_63a0

    ld a, [wBattleAttackerIdx]
    cp $04
    jr c, jr_052_63a0

    ld a, $0f
    ld [$db4e], a
    jr jr_052_63a5

jr_052_63a0:
    ld a, $0b
    ld [$db4e], a

jr_052_63a5:
    ld hl, $5401
    rst $10
    ld a, [$db4c]
    ld l, a
    ld a, [$db4d]
    ld h, a
    call RecordDamageRoll_679c
    call LookupTargetSpecies
    cp $07
    jr nz, jr_052_63ce

    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    call SetupBattle_6980
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a

jr_052_63ce:
    call GetTargetBattleSlot
    call GetBattleStatAddr1
    rlca
    rlca
    and $03
    call ElemLadderBreath
    ret


; [S130 F8] CallHelp/YellHelp helper damage: level*2 (party or link caster)
; or level + level>>1 (enemy), then CheckTargetGuardA with the rtype-24
; level ($DD2E+7t bits 5:4). Measured S130: res 0-3, rows 0/$40/$80.
LoadBattle_63dc:
CallHelpDamage_63dc:
    ld a, [wBattleAttackerIdx]
    ld hl, $db9b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld l, [hl]
    ld h, $00
    ld a, [$c86c]
    or a
    jr nz, jr_052_6403

    ld a, [wBattleAttackerIdx]
    cp $04
    jr c, jr_052_6403

    ld a, l
    srl a
    add l
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_052_6404

jr_052_6403:
    add hl, hl

jr_052_6404:
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    call GetTargetBattleSlot
    call BattleFunc_67d9
    swap a
    and $03
    call ElemLadderA
    ret


LoadBattle_641a:
    ld a, [wBattleAttackerIdx]
    ld hl, $db9b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld l, [hl]
    ld h, $00
    ld b, h
    ld c, l
    ld a, [$c86c]
    or a
    jr nz, jr_052_643d

    ld a, [wBattleAttackerIdx]
    cp $04
    jr c, jr_052_643d

    call BCsrl1
    jr jr_052_6442

jr_052_643d:
    add hl, bc
    add hl, bc
    ld bc, $000a

jr_052_6442:
    add hl, bc
    ld bc, $00b4
    call CmpHLvsBC
    jr c, jr_052_644e

    ld hl, $00b4

jr_052_644e:
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    call BattleCall_69e8
    ld b, h
    ld c, l
    call BattleRNG
    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    call Div16x16To16
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    sra b
    rr c
    jr nc, jr_052_647f

    ld a, l
    sub c
    ld c, a
    ld a, h
    sbc b
    ld b, a
    jr jr_052_6482

jr_052_647f:
    add hl, bc
    ld b, h
    ld c, l

jr_052_6482:
    ld a, c
    ld [$db56], a
    ld a, b
    ld [$db57], a
    call GetTargetBattleSlot
    call BattleCall_5c2a
    ret


; [S130 F23] Vacuum: the side test `ld a,[$c86c] / or a / jr nz / cp $04`
; compares the LINK byte (0), not the attacker index -> ENEMY casters
; also take the party formula 2L+30 (measured S130; WindBeast does test
; the attacker). Then ladder A res 3 (BattleCall_5c2a).
VacuumDamage_6491:
LoadBattle_6491:
    ld a, [wBattleAttackerIdx]
    ld hl, $db9b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld l, [hl]
    ld h, $00
    ld a, [$c86c]
    or a
    jr nz, jr_052_64b1

    cp $04
    jr c, jr_052_64b1

    ld b, h
    ld c, l
    call BCsrl1
    jr jr_052_64b5

jr_052_64b1:
    add hl, hl
    ld bc, $001e

jr_052_64b5:
    add hl, bc
    ld bc, $0096
    call CmpHLvsBC
    jr c, jr_052_64c1

    ld hl, $0096

jr_052_64c1:
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ld a, $05
    call Div16x8To16
    ld b, h
    ld c, l
    call BattleRNG
    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    call Div16x16To16
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    sra b
    rr c
    jr c, jr_052_64ef

    add hl, bc
    jr jr_052_64f7

jr_052_64ef:
    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    jr c, jr_052_64ff

jr_052_64f7:
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a

jr_052_64ff:
    call GetTargetBattleSlot
    call BattleCall_5c2a
    ret


RockThrowDamage_6506:            ; [S130 F23] record roll + breath ladder res 24
BattleCall_6506:
    call StoreDamageResult
    call BattleFunc_67d9
    swap a
    and $03
    call ElemLadderBreath
    ret


FireAirDamage_6514:              ; [S130 F23] record roll + breath ladder res 16
BattleCall_6514:
    call StoreDamageResult
    call BattleFunc_67cf
    swap a
    and $03
    call ElemLadderBreath
    ret


FrigidAirDamage_6522:            ; [S130 F23] record roll + breath ladder res 17
BattleCall_6522:
    call StoreDamageResult
    call BattleFunc_67cf
    rrca
    rrca
    and $03
    call ElemLadderBreath
    ret


BigBangDamage_6530:              ; [S130 F23] record roll + breath ladder res 0
BattleCall_6530:
    call StoreDamageResult
    call BattleFunc_67bb
    swap a
    and $03
    call ElemLadderBreath
    ret


MegaMagicDamage_653e:
    ld a, [wBattleAttackerIdx]
    ld e, a
    call GetCombatantMP
    add hl, hl
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ld a, e
    ld hl, $db9b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld l, [hl]
    ld h, $00
    add hl, hl
    ld a, [$db56]
    ld c, a
    ld a, [$db57]
    ld b, a
    add hl, bc
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    call DamageMul4Tenths_69e1
    call HLsrl2
    ld a, l
    or h
    jr z, jr_052_65a7

    ld b, h
    ld c, l
    call BattleRNG
    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    call Div16x16To16
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    ld a, [wRNG1]
    and $01
    jr z, jr_052_659e

    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a
    jr jr_052_659f

jr_052_659e:
    add hl, bc

jr_052_659f:
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a

jr_052_65a7:
    call GetTargetBattleSlot
    call BattleFunc_67cf
    rlca
    rlca
    and $03
    call ElemLadderBreath
    ret


; [S130 F1] Paralysis hit helper: BossProtectionGate, res 19 ($DD2D bits7:6), $6749; no Compare_6adc.
HitParalyze_65b5:
BattleCall_65b5:
    call SetHLBattle_6b21
    jp z, Jump_052_6b1e

    call GetTargetBattleSlot
    call BattleFunc_67d4
    rlca
    rlca
    and $03
    call HitLadderBeat_6749
    ret


; [S130 F1] Poison hit helper: res 18 ($DD2C bits1:0), $6749; no Compare_6adc.
HitPoison_65c9:
BattleCall_65c9:
    call GetTargetBattleSlot
    call BattleFunc_67cf
    and $03
    call HitLadderBeat_6749
    ret


; [S130 F1] Curse hit helper: res 20 ($DD2D bits5:4), $6749; no Compare_6adc.
HitCurse_65d5:
BattleCall_65d5:
    call GetTargetBattleSlot
    call BattleFunc_67d4
    swap a
    and $03
    call HitLadderBeat_6749
    ret


; [S130 F1] One-shot compulsion helper: res 21 ($DD2D bits3:2); id >= $7C -> $6749, else B.
HitCompel_65e3:
BattleCall_65e3:
    call GetTargetBattleSlot
    call BattleFunc_67d4
    rrca
    rrca
    and $03
    ld b, a
    ld a, [$db8a]
    cp $7c
    ld a, b
    jr nc, jr_052_65fb

    call CheckTargetGuardB
    jr jr_052_65fe

jr_052_65fb:
    call HitLadderBeat_6749

jr_052_65fe:
    ret


; [S130 F1] LegSweep/BigTrip gate: flying target ($DB8B bit4) -> fail (nc), else HitCompel_65e3.
HitTripFlyerGate_65ff:
BattleTarget_65ff:
    ld a, [wBattleTargetIdx]
    ld hl, $db8b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    bit 4, [hl]
    ret nz

    call BattleCall_65e3
    ret


; [S130 F7] nc (fail) only when target DEF == 1 and AGL == 1 and +3 bit1 (Surround).
UltraDownFloorCheck_6612:
    ld a, [wBattleTargetIdx]
    ld hl, wBattleDEF
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    dec bc
    ld a, b
    or c
    jr nz, jr_052_6646

    ld a, $0f
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    dec bc
    ld a, b
    or c
    jr nz, jr_052_6646

    ld a, [wBattleTargetIdx]
    ld hl, $db03
    call HL_AddA_x8
    bit 1, [hl]
    jr z, jr_052_6646

    xor a
    ret


jr_052_6646:
    scf
    ret


; [S130 F9] HelperLoad_6648: $84/$85/$86 -> bank $51 entry 5/6/7, else entry 8;
; then the helper slot's 8 status bytes $DB02+8s.. := 0.
HelperLoad_6648:
LoadBattle_6648:
    ld a, [$db8a]
    cp $84
    jr z, jr_052_665d

    cp $85
    jr z, jr_052_6663

    cp $86
    jr z, jr_052_6669

    ld hl, $5108
    rst $10
    jr jr_052_666d

jr_052_665d:
    ld hl, $5105
    rst $10
    jr jr_052_666d

jr_052_6663:
    ld hl, $5106
    rst $10
    jr jr_052_666d

jr_052_6669:
    ld hl, $5107
    rst $10

jr_052_666d:
    ld a, [wBattleAttackerIdx]
    and $04
    or $03
    ld hl, $db02
    call HL_AddA_x8
    xor a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl], a
    ret


; [S130 F9] DragonFormLoad_6684: bank $51 entry 9 = the FIXED dragon form
; (level 50, MaxHP 999, MaxMP 300, ATK 300, DEF/AGL/INT 200; HP/MP untouched;
; res; options {$5E,$62,$80}) + its message ($C9). Measured both sides.
DragonFormLoad_6684:
SetHLBattle_6684:
    ld hl, $5109
    rst $10
    ld c, $c9
    ld a, [wBattleAttackerIdx]
    ld b, a
    call BattleCall_5213
    ret


; [S130 F1] DanceShut hit helper: res 22 ($DD2D bits1:0), ladder B.
HitDanceShut_6692:
BattleCall_6692:
    call GetTargetBattleSlot
    call BattleFunc_67d4
    and $03
    call CheckTargetGuardB
    ret


; [S130 F1] MouthShut hit helper: res 23 ($DD2E bits7:6), ladder B.
HitMouthShut_669e:
BattleCall_669e:
    call GetTargetBattleSlot
    call BattleFunc_67d9
    rlca
    rlca
    and $03
    call CheckTargetGuardB
    ret


GigaSlashDamage_66ac:            ; [S130 F23] record roll + ladder A res 25
BattleCall_66ac:
    call StoreDamageResult
    call BattleFunc_67d9
    rrca
    rrca
    and $03
    call ElemLadderA
    ret


CallEvilAtk400_66ba:             ; [S130 F23] CALLEVIL: calcdef with caster ATK forced $0190
LoadBattle_66ba:
    ld a, [wBattleAttackerIdx]
    ld hl, wBattleATK
    call HL_AddA_x2
    push hl
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    push bc
    ld a, $01
    ld [hl-], a
    ld [hl], $90
    call CalcDefenseWrapper
    pop bc
    pop hl
    ld a, c
    ld [hl+], a
    ld [hl], b
    ret


StoreDamageResult:
    ld a, [$db8a]
    ld [$db4c], a
    ld a, $00
    ld [$db4d], a
    ld a, [$c86c]
    or a
    jr nz, jr_052_66f2

    ld a, [wBattleAttackerIdx]
    bit 2, a
    jr z, jr_052_66f2

    ld a, $0f
    jr jr_052_66f4

jr_052_66f2:
    ld a, $0b

jr_052_66f4:
    ld [$db4e], a
    ld hl, $5401
    rst $10
    ld a, [$db4c]
    ld l, a
    ld a, [$db4d]
    ld h, a
    call RecordDamageRoll_679c

GetTargetBattleSlot:
    ld a, [wBattleTargetIdx]
    ld hl, $db05
    call HL_AddA_x8
    ret


CheckTargetGuardB:
Jump_052_6710:
    bit 6, [hl]
    jr z, jr_052_6719

    call BattleFunc_680f
    jr jr_052_6725

jr_052_6719:
    bit 7, [hl]
    jr z, jr_052_6722

    call Compare_6802
    jr jr_052_6725

jr_052_6722:
    call BattleFunc_67ec

jr_052_6725:
    ret


    bit 6, [hl]
    jr z, jr_052_672f

    call BattleFunc_67ec
    jr jr_052_6732

jr_052_672f:
    call Compare_6802

jr_052_6732:
    ret


HitLadderKamikaze_6733:
    bit 6, [hl]
    jr z, jr_052_673c

    call BattleFunc_6825
    jr jr_052_6748

jr_052_673c:
    bit 7, [hl]
    jr z, jr_052_6745

    call Compare_6802
    jr jr_052_6748

jr_052_6745:
    call BattleFunc_680f

jr_052_6748:
    ret


HitLadderBeat_6749:
Jump_052_6749:
    bit 7, [hl]
    jr z, jr_052_6752

    call BattleFunc_67ec
    jr jr_052_6755

jr_052_6752:
    call BattleFunc_6825

jr_052_6755:
    ret


CheckTargetGuardA:
    bit 6, [hl]
    jr z, jr_052_675f

    call BattleFunc_684f
    jr jr_052_676b

jr_052_675f:
    bit 7, [hl]
    jr z, jr_052_6768

    call BattleFunc_6862
    jr jr_052_676b

jr_052_6768:
    call BattleFunc_683c

jr_052_676b:
    ret


ResLadderBreath_676c:
    bit 6, [hl]
    jr z, jr_052_6775

    call BattleFunc_6879
    jr jr_052_6781

jr_052_6775:
    bit 7, [hl]
    jr z, jr_052_677e

    call BattleFunc_6862
    jr jr_052_6781

jr_052_677e:
    call BattleFunc_684f

jr_052_6781:
    ret


ResLadderElemSlash_6782:
    bit 6, [hl]
    jr z, jr_052_678b

    call BattleFunc_683c
    jr jr_052_678e

jr_052_678b:
    call BattleFunc_6862

jr_052_678e:
    ret


    bit 7, [hl]
    jr z, jr_052_6798

    call BattleFunc_683c
    jr jr_052_679b

jr_052_6798:
    call BattleFunc_6862

jr_052_679b:
    ret


RecordDamageRoll_679c:
    ld a, [$db4e]
    or a
    jr z, jr_052_67b2

    inc a
    ld c, a
    ld a, [wRNG1]

jr_052_67a7:
    cp c
    jr c, jr_052_67ae

    sub c
    jr nc, jr_052_67a7

    ld a, c

jr_052_67ae:
    ld c, a
    ld b, $00
    add hl, bc

jr_052_67b2:
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ret


BattleFunc_67bb:
    ld de, $dd28
    jr jr_052_67dc

GetBattleStatAddr1:
    ld de, $dd29
    jr jr_052_67dc

BattleFunc_67c5:
    ld de, $dd2a
    jr jr_052_67dc

BattleFunc_67ca:
    ld de, $dd2b
    jr jr_052_67dc

BattleFunc_67cf:
    ld de, $dd2c
    jr jr_052_67dc

BattleFunc_67d4:
    ld de, $dd2d
    jr jr_052_67dc

BattleFunc_67d9:
    ld de, $dd2e

jr_052_67dc:
    ld a, [wBattleTargetIdx]
    ld b, a
    add a
    add b
    add a
    add b
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    ret


BattleFunc_67ec:
    and a
    jr nz, jr_052_67f1

    scf
    ret


jr_052_67f1:
    cp $01
    jr nz, jr_052_67f8

    jp Jump_052_6890


jr_052_67f8:
    cp $02
    jr nz, jr_052_67ff

    jp Jump_052_68a2


jr_052_67ff:
    scf
    ccf
    ret


Compare_6802:
    cp $02
    jr nc, jr_052_6807

    ret


jr_052_6807:
    jr nz, jr_052_680c

    jp Jump_052_6899


jr_052_680c:
    scf
    ccf
    ret


BattleFunc_680f:
    and a
    jr nz, jr_052_6814

    scf
    ret


jr_052_6814:
    cp $01
    jr nz, jr_052_681b

    jp Jump_052_6899


jr_052_681b:
    cp $02
    jr nz, jr_052_6822

    jp Jump_052_68ab


jr_052_6822:
    scf
    ccf
    ret


BattleFunc_6825:
    and a
    jr nz, jr_052_682b

    jp Jump_052_6899


jr_052_682b:
    cp $01
    jr nz, jr_052_6832

    jp Jump_052_68a2


jr_052_6832:
    cp $02
    jr nz, jr_052_6839

    jp Jump_052_68b4


jr_052_6839:
    scf
    ccf
    ret


BattleFunc_683c:
    and a
    ret z

    cp $01
    jr nz, jr_052_6845

    jp Jump_052_68e5


jr_052_6845:
    cp $02
    jr nz, jr_052_684c

    jp Jump_052_690d


jr_052_684c:
    jp Jump_052_695d


BattleFunc_684f:
    and a
    ret z

    cp $01
    jr nz, jr_052_6858

    jp Jump_052_68f9


jr_052_6858:
    cp $02
    jr nz, jr_052_685f

    jp Jump_052_6921


jr_052_685f:
    jp Jump_052_695d


BattleFunc_6862:
    and a
    jr nz, jr_052_6868

    jp Jump_052_68bd


jr_052_6868:
    cp $01
    jr nz, jr_052_686f

    jp Jump_052_68d1


jr_052_686f:
    cp $02
    jr nz, jr_052_6876

    jp Jump_052_68f9


jr_052_6876:
    jp Jump_052_6935


BattleFunc_6879:
    and a
    jr nz, jr_052_687f

    jp Jump_052_68f9


jr_052_687f:
    cp $01
    jr nz, jr_052_6886

    jp Jump_052_690d


jr_052_6886:
    cp $02
    jr nz, jr_052_688d

    jp Jump_052_6949


jr_052_688d:
    jp Jump_052_695d


Jump_052_6890:
    call BattleRNG
    ld a, [wRNG1]
    cp $d8
    ret


Jump_052_6899:
    call BattleRNG
    ld a, [wRNG1]
    cp $bf
    ret


Jump_052_68a2:
    call BattleRNG
    ld a, [wRNG1]
    cp $7f
    ret


Jump_052_68ab:
    call BattleRNG
    ld a, [wRNG1]
    cp $66
    ret


Jump_052_68b4:
    call BattleRNG
    ld a, [wRNG1]
    cp $3f
    ret


Jump_052_68bd:
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    call SetupBattle_6980
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ret


Jump_052_68d1:
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    call SetupBattle_698b
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ret


Jump_052_68e5:
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    call SaveBattle_69a8
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ret


Jump_052_68f9:
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    call SaveBattle_69c6
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ret


Jump_052_690d:
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    call HLsrl1
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ret


Jump_052_6921:
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    call DamageMul4Tenths_69e1
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ret


Jump_052_6935:
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    call BattleCall_69e8
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ret


Jump_052_6949:
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    call HLsrl2
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ret


Jump_052_695d:
    xor a
    ld [$db56], a
    ld [$db57], a
    ret


LoadDamageValue:
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    call SetupBattle_6979
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ret


SetupBattle_6979:
    ld b, h
    ld c, l
    call HLsrl1
    add hl, bc
    ret


SetupBattle_6980:
    ld b, h
    ld c, l
    call BCsrl2
    add hl, bc
    call BCsrl2
    add hl, bc
    ret


SetupBattle_698b:
    ld b, h
    ld c, l
    call BCsrl3
    add hl, bc
    call BCsrl2
    add hl, bc
    ret


    call HLsrl1
    ld b, h
    ld c, l
    call BCsrl1
    add hl, bc
    call BCsrl1
    add hl, bc
    call BCsrl2
    add hl, bc
    ret


SaveBattle_69a8:
    push de
    ld b, h
    ld c, l
    ld a, $55
    call Mul16x8To24
    ld a, $64
    call Div24x8To16
    pop de
    ret


DamageMul8Tenths_69b7:
    push de
    ld b, h
    ld c, l
    ld a, $08
    call Mul16x8To24
    ld a, $0a
    call Div24x8To16
    pop de
    ret


SaveBattle_69c6:
    push bc
    call HLsrl1
    ld b, h
    ld c, l
    call BCsrl1
    add hl, bc
    pop bc
    ret


DamageMul6Tenths_69d2:
    push de
    ld b, h
    ld c, l
    ld a, $06
    call Mul16x8To24
    ld a, $0a
    call Div24x8To16
    pop de
    ret


DamageMul4Tenths_69e1:
    call DamageMul8Tenths_69b7
    call HLsrl1
    ret


BattleCall_69e8:
    call DamageMul6Tenths_69d2
    call HLsrl1
    ret


SaveBattle_69ef:
    push hl
    push bc
    ld b, a
    call GetCombatantHP
    push hl
    ld a, b
    call GetCombatantMaxHP
    pop bc
    call CmpHLvsBC
    pop bc
    pop hl
    ret


SaveBattle_6a01:
    push hl
    push bc
    ld b, a
    call GetCombatantMP
    push hl
    ld a, b
    call GetCombatantMaxMP
    pop bc
    call CmpHLvsBC
    pop bc
    pop hl
    ret


; [S130 F7] carry = DEF < min-check: DEF >= 999 -> BC=999; else BC = baseDEF x4
; [S130 F7] (target<4 or link) / x2 (enemy); Z+carry = exactly at it.
UpperStatCapCheck_6a13:
    ld [$db4c], a
    call GetCombatantDEF
    ld bc, $03e7
    call CmpHLvsBC
    jr nc, jr_052_6a45

    push hl
    ld a, [$db4c]
    call GetBaseDEF_52b1
    ld a, [$c86c]
    or a
    jr nz, jr_052_6a35

    ld a, [$db4c]
    cp $04
    jr nc, jr_052_6a39

jr_052_6a35:
    sla c
    rl b

jr_052_6a39:
    sla c
    rl b
    pop hl
    call CmpHLvsBC
    jr nc, jr_052_6a45

jr_052_6a43:
    scf
    ret


jr_052_6a45:
    jr z, jr_052_6a43

    xor a
    ret


; [S130 F7] carry = AGL < 511 and < baseAGL x4/x2 (BC = the bound that failed).
AglUpStatCapCheck_6a49:
    ld [$db4c], a
    ld hl, wBattleAGL
    call CalcBattle_6ab1
    ld bc, $01ff
    call CmpHLvsBC
    jr z, jr_052_6a73

    jr nc, jr_052_6a73

    push hl
    ld a, [$db4c]
    call GetBaseAGL_52c6
    ld a, [$db4c]
    ld [$dd74], a
    call StatCapMul_6af5
    pop hl
    call CmpHLvsBC
    jr nc, jr_052_6a73

    ret


jr_052_6a73:
    xor a
    ret


LoadBattle_6a75:
    ld a, l
    ld [$db4c], a
    ld a, h
    ld [$db4d], a
    ld a, e
    ld [$db4e], a
    ld a, d
    ld [$db4f], a
    ld hl, $5101
    rst $10
    ret


    push af
    push bc
    push de
    push hl
    ld a, [$db4c]
    ld hl, $6aa3
    call HL_AddA_x2
    call RST_08
    ld [$db4c], a
    pop hl
    pop de
    pop bc
    pop af
    ret


    jp hl


    cp e
    ld h, a
    ret nz

    ld h, a
    push bc
    ld h, a
    jp z, $cf67

    ld h, a
    call nc, $d967
    ld h, a

CalcBattle_6ab1:
    call HL_AddA_x2
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ret


HL_AddA_x2:
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ret


; [S130 F23] $DC3C[t] -> bank $03 entry 1 -> $DA33 = family 0 Slime .. 8
; Material, 9 Boss (= monsters_full family_id; 200/200 measured S130).
LookupTargetSpecies:
    call BattleTarget_6acf
    ld a, [hl]
    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10
    ld a, [$da33]
    ret


BattleTarget_6acf:
    ld a, [wBattleTargetIdx]
    ld hl, $dc3c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ret


; [S130 F1] Z = roll the ladder: level 3 (never) or $DB42[attacker] bit2 clear;
; NZ = SURE HIT (caller sets carry, no RNG step). Measured S130 (sure battles).
SureHitCheck_6adc:
Compare_6adc:
    cp $03
    ret z

    push bc
    push hl
    ld b, a
    ld a, [wBattleAttackerIdx]
    ld hl, $db42
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    and $04
    ld a, b
    pop hl
    pop bc
    ret


; [S130 F7] BC *= 4 for slot [$DD74] < 4 or a link battle, else *= 2.
StatCapMul_6af5:
    ld a, [$c86c]
    or a
    jr nz, jr_052_6b02

    ld a, [$dd74]
    cp $04
    jr nc, jr_052_6b06

jr_052_6b02:
    sla c
    rl b

jr_052_6b06:
    sla c
    rl b
    ret


SaveBattle_6b0b:
    push hl
    push af
    ld a, [wBattleTargetIdx]
    ld hl, $dd13
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $03
    pop af
    pop hl
    ret


Jump_052_6b1e:
    scf
    ccf
    ret


SetHLBattle_6b21:
    ld hl, $5310
    rst $10
    ld a, [$db4c]
    or a
    ret


BCsrl3:
    srl b
    rr c

BCsrl2:
    srl b
    rr c

BCsrl1:
    srl b
    rr c
    ret


HLsrl4:
    srl h
    rr l

HLsrl3:
    srl h
    rr l

HLsrl2:
    srl h
    rr l

HLsrl1:
    srl h
    rr l
    ret


CheckTargetInRange:
    cp $03
    jr nc, jr_052_6b66

SaveBattle_6b4c:
jr_052_6b4c:
    push hl
    ld hl, $cac2
    call GetCurrentMonsterPtr
    ld e, l
    ld d, h
    pop hl
    push hl
    call Copy4Bytes
    pop hl

jr_052_6b5b:
    ld a, [hl]
    cp $f0
    ret z

    inc hl
    jr jr_052_6b5b

jr_052_6b62:
    ld a, b
    pop bc
    jr jr_052_6b4c

jr_052_6b66:
    push bc
    ld b, a
    and $03
    cp $03
    ld a, b
    pop bc
    jr z, jr_052_6b8f

    push bc
    ld b, a
    ld a, [$c86c]
    or a
    jr nz, jr_052_6b62

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
    jr nz, jr_052_6b8c

    ld a, b

jr_052_6b8c:
    pop bc
    jr nz, jr_052_6bb7

jr_052_6b8f:
    push af
    call BattleFunc_6b99
    pop af
    ld hl, $5104
    rst $10
    ret


BattleFunc_6b99:
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


jr_052_6bb7:
    call SaveBattle_6b4c
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
    jr z, jr_052_6be3

    cp $02
    jr z, jr_052_6bed

    ld a, [hl+]
    cp [hl]
    jr z, jr_052_6c09

    inc hl
    cp [hl]
    jr z, jr_052_6c09

    jr jr_052_6c18

jr_052_6be3:
    ld a, [hl+]
    cp [hl]
    jr z, jr_052_6c0e

    ld a, [hl+]
    cp [hl]
    jr z, jr_052_6c09

    jr jr_052_6c18

jr_052_6bed:
    ld d, $00
    inc hl
    inc hl
    ld a, [hl-]
    dec hl
    cp [hl]
    jr nz, jr_052_6bf7

    inc d

jr_052_6bf7:
    inc hl
    cp [hl]
    jr nz, jr_052_6bfc

    inc d

jr_052_6bfc:
    ld a, d
    or a
    jr z, jr_052_6c18

    cp $01
    jr z, jr_052_6c0e

    pop hl
    ld a, $03
    jr jr_052_6c11

jr_052_6c09:
    pop hl
    ld a, $01
    jr jr_052_6c11

jr_052_6c0e:
    pop hl
    ld a, $02

jr_052_6c11:
    ld [$db4d], a
    ld [hl+], a
    ld [hl], $f0
    ret


jr_052_6c18:
    pop hl
    xor a
    ld [$db4d], a
    ret


    ld hl, $c1a0
    jr jr_052_6c26

SetHLBattle_6c23:
    ld hl, $c180

jr_052_6c26:
    ld a, l
    ld [$db4e], a
    ld a, h
    ld [$db4f], a
    ld a, [wBattleTargetIdx]
    ld [$db50], a
    call CheckTargetInRange
    ret


    ld hl, $c180
    ld a, l
    ld [$db4e], a
    ld a, h
    ld [$db4f], a
    ld a, [wBattleAttackerIdx]
    ld [$db50], a
    call CheckTargetInRange
    ret


    ld hl, $7204         ; [QUAKE v3] byte-neutral 15-for-15 window: was
    rst $10              ;   `ld a,[$da82] / or a / jr nz,+9 / ld hl,$5f05 /
    ld a, e              ;   rst $10 / ld a,[$da82] / or a / ret z`. Entry 4
    or a                 ;   (QuakeAnimHold72) reproduces vanilla exactly for
    jr nz, jr_052_6c5c   ;   every non-quake id (incl. the nested $5f05 driver
    ret                  ;   call that also ticks the d9ee setup machine); for
                         ;   $E5-$E8/$E9 in the cast-anim slot: shake train or
                         ;   double-slash replay. No branches target $6c55-$6c5b
                         ;   (bank-$53 `call $6c59` is its OWN address space).
MournDispatch52:         ; [MOURN S75] 6 bytes in the dead-code window ($6c56):
    call CalcDefenseWrapper ;   ATK-vs-DEF damage -> $db56/57 (physical attack path)
    jp CustomDispatch52_shared ;   then descriptor + far-call $72 for the multiplier

jr_052_6c5c:
    ld a, [$d9ed]
    rst $00
    sbc b
    ld l, h
    or d
    ld l, h
    ld d, [hl]
    ld l, l
    dec hl
    ld l, [hl]
    ld [hl], h
    ld l, [hl]
    ld d, [hl]
    ld l, a
    ld a, [$276f]
    ld [hl], d
    ld b, d
    ld [hl], d
    ld a, d
    ld [hl], d
    ld d, b
    ld [hl], e
    ld d, $74
    ld [hl], h
    ld [hl], h
    db $ed
    ld [hl], h
    pop af
    ld [hl], h
    sub b
    ld [hl], l
    sbc c
    ld [hl], l
    and e
    ld [hl], l
    sbc b
    ld l, h
    xor b
    ld [hl], l
    or h
    ld [hl], l
    or l
    ld a, [hl]
    reti


    ld a, [hl]
    sbc $7e
    reti


    ld a, [hl]
    sbc $7e
    db $e3
    ld a, [hl]
    add sp, $7e
    ld hl, $5300
    rst $10
    ld a, [$d9ed]
    cp $09
    ret nz

    xor a
    ld hl, $d9ee
    ld [hl+], a
    ld a, $ff
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld a, $fe
    ld [hl], a
    jp Jump_052_727a


    ld a, [$d9ee]
    cp $0b
    jr z, SkillHandlerDispatch_6cc7

    cp $10
    jr z, jr_052_6cf2

    ld hl, $5305
    rst $10
    ld a, [$d9ee]
    cp $0b
    ret nz

SkillHandlerDispatch_6cc7:
    ld hl, $d9ee
    inc [hl]
    xor a
    ld [$c1c9], a
    ld a, [$db8a]
    ld c, a
    ld b, $00
    ; --- S2 custom-skill fork (byte-neutral, 5-for-5) ---
    ; Original was: ld hl,SkillFunctionTable / add hl,bc / add hl,bc  (21 11 40 09 09).
    ; Replaced with a far-call to bank $72 entry 0 (FarSkillFork), which returns
    ; HL = pointer-to-handler-pointer: $4011+id*2 for vanilla ids (<$DE), or
    ; CustomSkillTable52+(id-$DE)*2 for new ids ($DE/$DF). bc(=id) is preserved.
    ; The following unchanged `call RST_08` then derefs [HL] and jp's to the handler.
    ld hl, $7200
    rst $10
    nop
    call RST_08
    ld a, [$d9ee]
    cp $0c
    ret nz

    ld a, [$d9ed]
    cp $01
    ret nz

    ld hl, $5305
    rst $10
    ret


    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jp hl


jr_052_6cf2:
    ld hl, $d9ed
    inc [hl]
    xor a
    ld [$d9ee], a
    ld a, [$db8a]
    cp $29
    jr z, jr_052_6d20

    cp $aa
    jr z, jr_052_6d0a

    cp $d5
    jp nz, BtlActState2Apply_6d56

; [S130 F9] DragonFormState4_6d0a ($AA/$D5): form change, own +3 bit4, then the
; state-4 tail TransformActionRewrite_7ab5 (an extra pass of the whole per-actor
; pipeline this turn).
DragonFormState4_6d0a:
jr_052_6d0a:
    ld a, $04
    ld [$d9ed], a
    call SetHLBattle_6684
    ld a, [wBattleAttackerIdx]
    ld hl, $db03
    call HL_AddA_x8
    set 4, [hl]
    jp Jump_052_6e74


; [S130 F7] Transform act state 5: TransformCopyStats_5f5e, own +3 bit5.
jr_052_6d20:
    ld a, $05
    ld [$d9ed], a
    call TransformCopyStats_5f5e
    ld hl, $d9ed
    inc [hl]
    ld a, [wBattleAttackerIdx]
    ld hl, $db03
    call HL_AddA_x8
    set 5, [hl]
    ld a, [$c86c]
    or a
    jp nz, Jump_052_6f56

    ld a, [wBattleAttackerIdx]
    cp $04
    jp c, Jump_052_6f56

    and $03
    ld hl, $c1ca
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wBattleTargetIdx]
    ld [hl], a
    ret


BtlActState2Apply_6d56:
    ld a, [$dd80]
    ld hl, $dd9a
    and [hl]
    cp $ff
    ret nz

    ld a, [$da82]
    or a
    ret z

    ld a, [$db8a]
    cp $a4
    jr z, jr_052_6d70

    cp $a2
    jr nz, jr_052_6d77

jr_052_6d70:
    ld hl, $d9ed
    inc [hl]
    jp Jump_052_6e6f


jr_052_6d77:
    xor a
    ld [$dd72], a
    ld hl, $d9ed
    inc [hl]
    ld hl, $d9ed
    inc [hl]
    ld a, [$db8a]
    cp $1a
    jp z, Jump_052_6df2

    cp $75
    jp z, Jump_052_6df2

    cp $76
    jp z, Jump_052_6df2

    cp $15
    jr c, jr_052_6db0

    cp $71
    jp z, Jump_052_6df2

    cp $37
    jr z, jr_052_6db0

    cp $38
    jr z, jr_052_6db0

    cp $3a
    jp c, Jump_052_6df2

    cp $94
    jp z, Jump_052_6df2

jr_052_6db0:
    ld a, [$db8a]
    cp $12
    jp z, Jump_052_6df2

    cp $13
    jp z, Jump_052_6df2

    ld a, [$dd6f]
    bit 5, a
    jp z, Jump_052_6df2

    ld a, [wBattleTargetIdx]
    ld hl, wBattleHP
    call HL_AddA_x2
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    ld a, [$db56]
    ld c, a
    ld a, [$db57]
    ld b, a
    ld a, e
    sub c
    ld e, a
    ld a, d
    sbc b
    ld d, a
    jr c, jr_052_6de8

    ld a, d
    ld [hl-], a
    ld [hl], e
    or e
    jp nz, Jump_052_6df2

jr_052_6de8:
    ld a, $1a
    ld [$d9ed], a
    xor a
    ld [$d9f1], a
    ret


Jump_052_6df2:
    ld a, [$c863]
    bit 1, a
    ld a, [wBattleTargetIdx]
    jr z, jr_052_6e02

    cp $03
    jr nc, jr_052_6e26

    jr jr_052_6e0a

jr_052_6e02:
    cp $04
    jr c, jr_052_6e26

    cp $07
    jr z, jr_052_6e26

jr_052_6e0a:
    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    jr nc, jr_052_6e26

    ld a, $1a
    ld [$d9ed], a
    xor a
    ld [$d9f1], a
    ret


    ld hl, $5006
    rst $10
    ld a, $01
    ld [$c87e], a
    ret


jr_052_6e26:
    ld hl, $5006
    rst $10
    ret


    ld a, [$db8a]
    cp $14
    jr z, jr_052_6e60

    cp $80
    jr z, jr_052_6e5b

    cp $82
    jr z, jr_052_6e65

    cp $83
    jr z, jr_052_6e5b

    cp $a5
    jr z, jr_052_6e5b

    cp $88
    jr z, jr_052_6e6a

    cp $89
    jr z, jr_052_6e6a

    cp $a2
    jr z, jr_052_6e6f

    cp $a4
    jr z, jr_052_6e6f

    ld hl, $d9ed
    inc [hl]
    inc [hl]
    inc [hl]
    jp Jump_052_6ffa


jr_052_6e5b:
    ld hl, $530b
    rst $10
    ret


jr_052_6e60:
    ld hl, $530d
    rst $10
    ret


jr_052_6e65:
    ld hl, $530c
    rst $10
    ret


jr_052_6e6a:
    ld hl, $5304
    rst $10
    ret


Jump_052_6e6f:
jr_052_6e6f:
    ld hl, $530f
    rst $10
    ret


Jump_052_6e74:
    ld a, [$c825]
    or a
    ret nz

    ld a, [$da82]
    or a
    ret z

    ld a, [$da33]
    or a
    jr z, jr_052_6e89

    dec a
    ld [$da33], a
    ret


; [S130 F23] State-4 tail dispatcher: skill-specific post-apply chains
; ($32/$96 -> $530E, $3B/$3E/$3C caster tails, $67/$68/$69 status riders,
; $80 BiAttack, $95 LifeSong, $AA/$D5 transform); others -> next state.
Jump_052_6e89:
jr_052_6e89:
    ld a, [$db8a]
    cp $32
    jr z, jr_052_6ef1

    cp $96
    jr z, jr_052_6ef1

    cp $3b
    jr z, jr_052_6ef6

    cp $3e
    jr z, jr_052_6f02

    cp $3c
    jr z, jr_052_6f0e

    cp $67
    jr z, jr_052_6f1a

    cp $68
    jr z, jr_052_6f24

    cp $69
    jp z, Jump_052_6f2e

    cp $80
    jp z, Jump_052_6f38

    cp $95
    jp z, Jump_052_6f42

    cp $aa
    jp z, Jump_052_6f4e

    cp $d5
    jp z, Jump_052_6f4e

    call LoadBattle_6ecf
    jp nz, Jump_052_6f52

    ld hl, $d9ed
    inc [hl]
    jp Jump_052_6f56


    ret


; [S130 F6] BladeD counter gate (act state 4, after an applied hit the target survived): NZ iff
; [S130 F6] $DD6E == 0 (no Cover/dodge/reflect redirect), $DD6C & 8 == 0, target $DB09+8t bit2 (level 4)
; [S130 F6] and flags7 bit7 (physical). Measured S130 (counter_gate 1081/1081, dd6e).
BladeDCounterGate_6ecf:
LoadBattle_6ecf:
    ld a, [$dd6e]
    or a
    jr z, jr_052_6ed7

    xor a
    ret


jr_052_6ed7:
    ld a, [$dd6c]
    and $08
    cp $08
    ret z

    ld a, [wBattleTargetIdx]
    ld hl, $db09
    call HL_AddA_x8
    bit 2, [hl]
    ret z

    ; [S110 rec] flags7 bit7 (physical) vs BladeD (target +9 bit2 = defence level 4)
    ld a, [$dcfd]
    bit 7, a
    ret


jr_052_6ef1:
    ld hl, $530e
    rst $10
    ret


; [S130 F23] STATE-4 TAIL DISPATCH: Jump_052_6e89 branches on $DB8A; each row is
; `ld a,[$d9ee] / rst $00` + a dw table of the skill's sub-states (misassembled as
; code before S130; re-sectioned byte-identically). Sub 0 = caster-alive check +
; anim, sub 1 = the effect, $7920 = commit the saved $D9EF/$D9F0 + redraw,
; $797C = next state (or the BladeD counter). Only reached after an APPLIED hit
; that the target survived (a KO goes to act state $1A) — measured S130.
jr_052_6ef6:                        ; $3B TwinSlash
    ld a, [$d9ee]
    rst $00
    dw TwinSlashTail0_77c8, TwinSlashRecoil_77e2, TailCommitState_7920, Jump_052_797c

jr_052_6f02:                        ; $3E Kamikaze
    ld a, [$d9ee]
    rst $00
    dw KamikazeTail0_7892, KamikazeSelfTail_78a3, TailCommitState_7920, Jump_052_797c

jr_052_6f0e:                        ; $3C Ramming
    ld a, [$d9ee]
    rst $00
    dw RammingTail0_79a4, RammingRecoil_79b5, TailCommitState_7920, Jump_052_797c

jr_052_6f1a:                        ; $67 PoisonHit (rider)
    ld a, [$d9ee]
    rst $00
    dw $7b31, $798e, Jump_052_797c

jr_052_6f24:                        ; $68 SleepHit (rider)
    ld a, [$d9ee]
    rst $00
    dw $7b75, $798e, Jump_052_797c

Jump_052_6f2e:                      ; $69 Paralyze (rider)
    ld a, [$d9ee]
    rst $00
    dw $7bb7, $798e, Jump_052_797c

; [S130 F10] state-4 row of $DB8A == $80: never reached by DeMagic (its machine ends
; [S130 F10] d9ed 3 -> 6; hooked $7A49 in 41 dispel actions: 0 hits). Reachability open.
Jump_052_6f38:                      ; $80 DeMagic (S130 F9: dragon self-revert tail, unreached; was "BiAttack")
    ld a, [$d9ee]
    rst $00
    dw $7a49, $7a5f, Jump_052_797c

Jump_052_6f42:                      ; $95 LifeSong
    ; [S130 F5] LifeSong's act-state-4 tails (dw table after rst $00, was
    ; misassembled as code; byte-identical)
    ld a, [$d9ee]
    rst $00
    dw LifeSongRevive_7a69, LifeSongMsg_7a80, LifeSongNext_7a95, Jump_052_797c

Jump_052_6f4e:
    call ConfusionActionRewrite_7ab5
    ret


Jump_052_6f52:
    call LoadBattle_7bec
    ret


Jump_052_6f56:
    ld hl, $5311
    rst $10
    ret


; [S130 F4] FOCUS FOLLOW-UP: reached from $70A4 at the end of an action when
; own +6 bit6 (Focus, rotated) is set: bit6 cleared; flags9-bit4 skill and a
; live opposing slot (NoLiveOpponent_7fd8) -> d9ed := $12 = the per-actor
; setup again: the same actor acts its queued action a second time.
FocusFollowUp_6f5b:
Jump_052_6f5b:
    res 6, [hl]
    ; [S110 rec] flags9 bit4: a FOLLOW-UP action when the actor's +6 bit6 is set ([S130 F4] writer = SkillFocus bit7 + the phase-9 rotate)
    ld a, [$dcff]
    bit 4, a
    jp z, Jump_052_706c

    call LoadBattle_7fd8
    jp c, Jump_052_706c

    ld a, $12
    ld [$d9ed], a
    ret


; [S130 F8] multi-hit continuation, QuadHits: $DD69 == 4 -> end, else
; re-pick ($58 entry 5 = LoadBtlFX_642c, uniform) before EVERY later hit.
Jump_052_6f71:
MultiHitContQuadHits_6f71:
    ld a, [$dd69]
    cp $04
    jp z, Jump_052_706c

jr_052_6f79:
    ld hl, $5805
    rst $10
    ld a, $01
    ld [$d9ed], a
    ret


; [S130 F8] multi-hit continuation, BiAttack: $DD69 == 2 -> end; a live
; target is hit again, a dead one re-picked via $58 entry 5 (measured).
Jump_052_6f83:
MultiHitContBiAttack_6f83:
    ld a, [$dd69]
    cp $02
    jp z, Jump_052_706c

    ld a, $01
    ld [$d9ed], a
    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    ret nc

    ld hl, $5805
    rst $10
    ret


; [S130 F8] multi-hit continuation, CallHelp: end at $DD69 == $13 (party
; helpers $10-$13, enemy $11-$13), early stop below, else re-pick.
Jump_052_6f9c:
MultiHitContCallHelp_6f9c:
    ld a, [$dd69]
    cp $13
    jp z, Jump_052_706c

    ld b, $03
    jr jr_052_6fb2

; [S130 F8] multi-hit continuation, YellHelp: end at $DD69 == $17 (party
; helpers $10-$17, enemy $12-$17).
Jump_052_6fa8:
MultiHitContYellHelp_6fa8:
    ld a, [$dd69]
    cp $17
    jp z, Jump_052_706c

    ld b, $07

; [S130 F8] early stop: RNG2 AS FOUND (no step) & 3 (& 7) == $DD69 & 3 (& 7),
; or own +8 bit0 clear (failed pass 1) -> end; else re-pick + next fetch.
jr_052_6fb2:
MultiHitHelpEarlyStop_6fb2:
    and b
    ld c, a
    ld a, [wRNG2]
    and b
    cp c
    jp z, Jump_052_706c

    ld a, [wBattleAttackerIdx]
    ld hl, $db08
    call HL_AddA_x8
    bit 0, [hl]
    jp z, Jump_052_706c

    ld hl, $5805
    rst $10
    ld a, $01
    ld [$d9ed], a
    ret


; [S130 F8] multi-hit continuation, RainSlash: $DD69 >= 4 -> end; $DCED += 1
; until a live slot, a slot with &3 == 3 ends the sweep (forward from the
; queued target; measured).
Jump_052_6fd4:
MultiHitContRainSlash_6fd4:
jr_052_6fd4:
    ld a, [$dd69]
    cp $04
    jp nc, Jump_052_706c

    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    call HL_AddA_x2
    ld a, [hl]
    inc a
    ld [hl], a
    and $03
    cp $03
    jr z, jr_052_706c

    ld a, [hl]
    call CheckMonsterSlot
    jr c, jr_052_6fd4

    ld a, $01
    ld [$d9ed], a
    ret


; [S130 F8] driver state 6: counts $DA33 frames down (the RNG idles), then
; the battle-over check (BattleFunc_7782) and the multi-hit continuation
; dispatch at MultiHitContDispatch_7041.
Jump_052_6ffa:
ActDriverState6_6ffa:
    ld a, [$da33]
    or a
    jr z, jr_052_7005

    dec a
    ld [$da33], a
    ret


jr_052_7005:
    ld a, [$c1c8]
    cp $ff
    jr z, jr_052_702c

    ld hl, $5004
    rst $10
    ld a, [$c1c8]
    ld [wBattleTargetIdx], a
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wBattleTargetIdx]
    ld [hl], a
    ld a, $ff
    ld [$c1c8], a

jr_052_702c:
    ld hl, $5004
    rst $10
    call LoadBattle_7e85
    call QuakeVictGate52 ; [QUAKE S74] was `call BattleFunc_7782` (same size).
                         ;   While a quake sweep is mid-flight the side-wiped
                         ;   check must not abort the multi-target iteration —
                         ;   otherwise a battle-winning quake never reaches
                         ;   the caster's own side. The scheduler's second
                         ;   call site ($70bd) still runs the real check right
                         ;   after the action, so victory/defeat land normally.
    jp c, Jump_052_70e0

    call LoadBattle_7dd7
    ret c

    xor a
    ld [$dd6b], a
; [S130 F8] $52:$7041 multi-hit continuation dispatch on $DB8A (hook point
; of simulator/measure_f8_multihit.py 'mh_cont')
MultiHitContDispatch_7041:
    ld a, [$db8a]
    cp $50
    jp z, Jump_052_6f83

    cp $51
    jp z, Jump_052_6f71

    cp $52
    jp z, Jump_052_6f9c

    cp $53
    jp z, Jump_052_6fa8

    cp $57
    jp z, Jump_052_6fd4

    cp $a7
    jp z, Jump_052_714c

    cp $a8
    jp z, Jump_052_714c

    cp $af
    jp z, Jump_052_714c

Jump_052_706c:
jr_052_706c:
    ld a, [wBattleAttackerIdx]
    ld hl, $dd13
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, $03
    ld [hl], a
    ; [S110 rec] target mode &3 == 1: single target, else the group loop steps every victim
    ld a, [$dcfc]
    and $03
    cp $01
    jp nz, Jump_052_7184

BattleCall_7085:
Jump_052_7085:
    call SetHLBattle_7d77
    ld a, [$dd6d]
    or a
    call nz, LoadBattle_7d7c
    call LoadBattle_7b1a
    ld a, [wBattleAttackerIdx]
    ld [wBattleTargetIdx], a
    cp $04
    jr nc, jr_052_70a4

    ld hl, $5004
    rst $10
    ld hl, $5006
    rst $10

jr_052_70a4:
    call LoadBattle_7dcd
    bit 6, [hl]
    jp nz, Jump_052_6f5b

    call LoadBattle_7ef1
    jp nc, Jump_052_706c

jr_052_70b2:
    ld a, [$db82]
    inc a
    ld [$db82], a
    cp $09
    jr nc, jr_052_7120

    call BattleFunc_7782
    jr c, jr_052_70e0

    ld a, [$db82]
    ld hl, $db79
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $ff
    jr z, jr_052_7120

    cp $10
    jr z, jr_052_70dc

    call CheckMonsterSlot
    jr c, jr_052_70b2

jr_052_70dc:
    ld hl, $d9ec
    dec [hl]

Jump_052_70e0:
jr_052_70e0:
    ld a, [$db8a]
    cp $52
    jr c, jr_052_710e

    cp $54
    jr nc, jr_052_710e

    ld a, [$c1c9]
    or a
    jr z, jr_052_7111

    ld hl, $5605
    rst $10
    ld a, $da
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $4c00
    rst $10
    ld a, $1b
    ld [$d9ed], a
    ld a, $07
    ld [$d9ec], a
    ret


BattleCall_710e:
jr_052_710e:
    call BattleFunc_76c8

jr_052_7111:
    call LoadBattle_7b1a
    xor a
    ld hl, $d9ed
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl], a
    ret


jr_052_7120:
    xor a
    ld [$db82], a
    ld hl, $d9ec
    inc [hl]
    ld hl, $db00
    ld a, [hl]
    and $50
    call nz, SaveBattle_7139
    inc hl
    ld a, [hl]
    and $50
    call nz, SaveBattle_7139
    ret


SaveBattle_7139:
    push hl
    ld a, [hl]
    and $af
    ld [hl], a
    ld a, $4a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    and $03
    ld [hl], a
    pop hl
    ret


; [S130 F1] the 8-step target walk (target_mode 1, BIGSLEEP): $DD69 counts
; visited+skipped slots; at 4 jump to the other side's base unchecked; else
; target+1 with CheckMonsterSlot; 8 ends. Measured: queued 4 -> 4,5,6,0,1,2.
; [S130 F5] The 8-slot walk ($A7/$A8/$AF): $DD69 counts fetches + skipped
; slots; at 4 the queue byte jumps to the OTHER side base (no life check);
; else +1, non-live slots only bump $DD69; done at 8. Measured (MP0):
; victims 4,5,6,0,1,2 for a slot-2 caster.
Walk8Victims_714c:
; [S130 F8] 8-slot walk ($A7/$A8/$AF): $DD69 >= 8 -> end; $DD69 == 4 ->
; $DCED := ($DCED & 4) ^ 4 (no live check: a start > base wraps to the SAME
; side's base via slot 8); else $DCED += 1, a dead slot costs $DD69 += 1.
Jump_052_714c:
MultiHitContWalk8_714c:
jr_052_714c:
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    call HL_AddA_x2
    ld a, [$dd69]
    cp $08
    jp nc, Jump_052_706c

    cp $04
    jr nz, jr_052_7169

    ld a, [hl]
    and $04
    xor $04
    ld [hl], a
    jr jr_052_7176

jr_052_7169:
    inc [hl]
    ld a, [hl]
    call CheckMonsterSlot
    jr nc, jr_052_7176

    ld hl, $dd69
    inc [hl]
    jr jr_052_714c

jr_052_7176:
    ld a, $01
    ld [$d9ed], a
    xor a
    ld [$d9ee], a
    xor a
    ld [$d9ef], a
    ret


Jump_052_7184:
jr_052_7184:
    ld a, [$dd6c]
    cp $02
    jp z, Jump_052_71f8

    cp $10
    jr z, jr_052_719c

    cp $04
    jr z, jr_052_7198

    cp $01
    jr nz, jr_052_719c

jr_052_7198:
    call LoadBattle_7ef1
    ret


jr_052_719c:
    ; [QUAKE] All-target sweep-advance fork (byte-neutral 20-for-20). The vanilla
    ; window derived the side ceiling (bit2 -> $03 party / $07 enemy) from the
    ; CURRENT target, finished at ceiling (jp z,$7085), else fell through to
    ; `inc a` (next target). Replaced with a far-call to bank $72 entry 3
    ; (QuakeSweep72), which reproduces those exact semantics for all stock ids
    ; and, for Earthquake tiers $E5-$E8, ALSO (a) skips flying targets
    ; ($db8b[k] bit4) and the caster, and (b) at the first side's ceiling
    ; CROSSES OVER to the caster's own side (allies) instead of finishing,
    ; arming the "seismic wave" message + hold. Contract (rst $10 clobbers
    ; A/BC; DE survives): returns D=1 finish-sweep / D=0 continue with
    ; E = next_target - 1 (the fall-through `inc a` below restores it).
    ld hl, $7203                     ; bank $72 entry 3 = QuakeSweep72
    rst $10
    ld a, e                          ; fall-through target id (D=0 case)
    dec d                            ; Z iff D==1 (iteration finished); C untouched
    jp z, Jump_052_7085
    jr QSweepAfter52                 ; the former pad was EXECUTED fall-through
                                     ; path — jump over the trampoline below
; [QUAKE S74] the 20-byte window's remaining 9 bytes fund the victory-gate
; trampoline. Called from the step-6 head in place of `call BattleFunc_7782`:
; while wQuakePhase != 0 (a quake sweep mid-flight) it reports "nobody wiped"
; (A=0, carry clear) so the iteration reaches the caster's own side even when
; the cast just KO'd the whole enemy team; otherwise it tail-calls the real
; check. The actor scheduler's second call site ($70bd) runs the real check
; unconditionally right after the action, so victory/defeat land normally —
; exactly one action later.
QuakeVictGate52:
    ld a, [$deb4]                    ; wQuakePhase
    or a
    jp z, BattleFunc_7782            ; phase 0: the real side-wiped check
    xor a                            ; mid-quake: A=0 + carry CLEAR = alive
    ret
QSweepAfter52:

    inc a
    push af
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    call HL_AddA_x2
    pop af
    ld [hl], a
    ld [wBattleTargetIdx], a
    ; [S130 F5] $95/$96/$AD visit the next slot without the life check
    ; (measured: ALLREVIVE visits slot 3); every other group skill skips
    ; non-live slots. The loop always continues from wBattleTargetIdx,
    ; which Revive re-targets to the slot it revived.
    ld a, [$db8a]
    cp $95
    jr z, jr_052_71d7

    cp $96
    jr z, jr_052_71d7

    cp $ad
    jr z, jr_052_71d7

    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    jr c, jr_052_7184

jr_052_71d7:
    ld hl, $dd13
    ld a, [wBattleAttackerIdx]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $02
    ld a, $01
    ld [$d9ed], a
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    call HL_AddA_x2
    ld a, [wBattleTargetIdx]
    ld [hl], a
    ret


; [S130 F6] Group loop with $DD6C == 2 (SuckAll absorbed): the user, if capable, breathes the same
; [S130 F6] skill back ($53 entry 9, $DB4C = $40): a full sweep of the other side from its first live
; [S130 F6] slot (bank $58 entry 8). Measured S130 (suckback, absorb_end).
SuckAllBreathBack_71f8:
Jump_052_71f8:
    ld a, [wBattleTargetIdx]
    call GetMonsterSlotInfo
    jp c, Jump_052_7085

    call SetHLBattle_6c23
    ld a, [$db8a]
    ld l, a
    ld h, $06
    ld de, $c190
    call SetupVRAMParams
    xor a
    ld [$c822], a
    ld a, $d7
    ld [$c823], a
    ld hl, $4c00
    rst $10
    ld a, $40
    ld [$db4c], a
    ld hl, $5309
    rst $10
    ret


    xor a
    ld [$d9ed], a
    ld hl, $d9ec
    inc [hl]
    ret


    ld hl, $5f06
    rst $10
    ld hl, $d9ee
    inc [hl]
    ret


    ld hl, $4c00
    rst $10
    ld hl, $d9ee
    inc [hl]
    ret


; [S130 F9] FleeBookkeeping_7242: bank $51 entry 3 (FleeSlot_4be8) on the
; fleeing slot (wBattleTargetIdx).
FleeBookkeeping_7242:
BattleTarget_7242:
    ld a, [wBattleTargetIdx]
    ld [$db4c], a
    ld hl, $5103
    rst $10
    ld a, [$c87e]
    or a
    jr nz, jr_052_7257

    ld a, [$c825]
    or a
    ret nz

jr_052_7257:
    ld a, [$d9f0]
    cp $01
    jr nz, jr_052_7262

    ld hl, $5801
    rst $10

jr_052_7262:
    xor a
    ld [$c87e], a
    ld hl, $5005
    rst $10
    ld a, [$db8a]
    cp $3b
    jr z, jr_052_7274

    cp $3e
    ret nz

jr_052_7274:
    ld a, $04
    ld [$d9ed], a
    ret


Jump_052_727a:
    ld a, [$db78]
    cp $d5
    jr nz, jr_052_7286

    ld hl, $5408
    rst $10
    ret


jr_052_7286:
    xor a
    ld [$d9ef], a
    xor a
    ld [$d9f0], a
    ld a, $80
    ld [wMenu_selection], a
    ld a, $10
    ld [wBattleAttackerIdx], a
    ld hl, $580d
    rst $10
    ld a, $00
    ld [$db8a], a
    ld de, $ca42
    ld hl, $c180
    call Copy4Bytes
    ld a, [$db78]
    sub $af
    ld l, a
    ld h, $08
    ld de, $c190
    call SetupVRAMParams
    ld hl, $c1a0
    ld a, [$db77]
    ld [$db50], a
    call CheckTargetInRange
    ld hl, $5807
    rst $10
    ld a, $18
    ld [$da33], a
    ld a, [$db4c]
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld a, [$db78]
    cp $c2
    jr c, jr_052_72fb

    cp $c7
    jr nc, jr_052_72fb

    ld a, $01
    ld [$c822], a
    ld a, [$db77]
    cp $04
    jr nz, jr_052_72fb

    ld a, [$dc40]
    cp $d7
    jr nz, jr_052_72fb

    ld a, $14
    ld [$d9ed], a

jr_052_72fb:
    ld hl, $4c00
    rst $10
    ld hl, $d9ed
    inc [hl]
    ld a, [$db77]
    ld [$db52], a
    ld a, $10
    ld [wBattleAttackerIdx], a
    ret


jr_052_730f:
    ld hl, $c180
    ld a, [wBattleTargetIdx]
    ld [$db50], a
    call CheckTargetInRange
    ld a, $ba
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $4c00
    rst $10
    ld a, $0c
    ld [$d9ed], a
    ld a, [$db78]
    cp $c2
    ret c

    ld a, $01
    ld [$db8a], a
    ret


jr_052_733a:
    ld a, [$db77]
    ld hl, $db07
    call HL_AddA_x8
    ld a, [hl]
    and $c0
    jr nz, jr_052_730f

    ld hl, $d9ef
    inc [hl]
    call LoadBattle_5589
    ret


    ld a, [$da33]
    or a
    jr z, jr_052_735b

    dec a
    ld [$da33], a
    ret


jr_052_735b:
    ld a, [$d9ef]
    or a
    jr z, jr_052_7375

    cp $01
    jr z, jr_052_73b3

    cp $02
    jr z, jr_052_73bc

    cp $03
    jr z, jr_052_733a

    cp $04
    jp z, Jump_052_73f0

    jp Jump_052_73f0


jr_052_7375:
    ld a, [$db77]
    call CheckMonsterSlot
    jr nc, jr_052_739d

    ld a, [$db78]
    cp $bb
    jr z, jr_052_739d

jr_052_7384:
    ld a, $00
    ld [$c822], a
    ld a, $bb
    ld [$c823], a
    ld hl, $4c00
    rst $10
    ld a, $0c
    ld [$d9ed], a
    ld a, $00
    ld [$db8a], a
    ret


jr_052_739d:
    ld hl, $d9ef
    inc [hl]
    ld a, [$db77]
    ld [wBattleTargetIdx], a
    ld a, [$db78]
    ld [$db8a], a
    call Compare_75b5
    ret c

    jr jr_052_7384

jr_052_73b3:
    ld hl, $5f06
    rst $10
    ld hl, $d9ef
    inc [hl]
    ret


jr_052_73bc:
    ld hl, $d9ef
    inc [hl]
    ld hl, $d9f0
    inc [hl]
    ld a, [$dd68]
    cp $02
    ret nz

    ld a, [$db53]
    ld b, a
    ld a, [$d9f0]
    cp b
    ret z

jr_052_73d3:
    ld a, [wBattleTargetIdx]
    inc a
    ld [wBattleTargetIdx], a
    and $03
    cp $03
    ret z

    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    jr c, jr_052_73d3

    ld hl, $d9ef
    dec [hl]
    ld hl, $d9ef
    dec [hl]
    ret


Jump_052_73f0:
    xor a
    ld [$d9f0], a
    ld a, [$dd6b]
    or a
    jr nz, jr_052_7408

    ld hl, $d9ed
    inc [hl]
    ld a, $04
    ld [$d9ef], a
    ld hl, $4c00
    rst $10
    ret


jr_052_7408:
    ld hl, $5f06
    rst $10
    xor a
    ld [$dd6b], a
    ld a, $0a
    ld [$d9ed], a
    ret


    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    jr c, jr_052_7428

    ld hl, $d9ed
    inc [hl]
    xor a
    ld [$db53], a
    jr jr_052_7474

jr_052_7428:
    ld a, [wBattleTargetIdx]
    and $03
    cp $03
    jr z, jr_052_744b

    ld a, [$db77]
    ld hl, $dd1b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $ff
    jr z, jr_052_746a

    call BattleTarget_7242
    ld a, [$db77]
    ld [$dd61], a

jr_052_744b:
    ld hl, $c180
    ld a, [$db77]
    ld [$db50], a
    call CheckTargetInRange
    ld a, $e4
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $4c00
    rst $10
    ld a, $05
    ld [$da33], a

jr_052_746a:
    ld a, $0c
    ld [$d9ed], a
    xor a
    ld [$db53], a
    ret


jr_052_7474:
    ld a, [$da33]
    or a
    jr z, jr_052_747f

    dec a
    ld [$da33], a
    ret


jr_052_747f:
    ld a, [$db53]
    or a
    jr nz, jr_052_74d1

    ld hl, $5006
    rst $10
    ld a, [$db78]
    ld [$db4c], a
    ld a, $00
    ld [$db4d], a
    ld a, $02
    ld [$db4e], a
    ; [S110 rec] record +2 target mode: bit0 = single target
    ld hl, $5400
    rst $10
    ld a, [$db4c]
    bit 0, a
    jr z, jr_052_74d5

jr_052_74a4:
    ld a, [$db78]
    cp $c5
    jr nz, jr_052_74af

    call RollBattle_74fb
    ret nc

jr_052_74af:
    ld a, [$db78]
    ld b, a
    ld a, $ff
    ld [$db77], a
    ld a, $ff
    ld [$db78], a
    ld a, [$db8a]
    or a
    jr nz, jr_052_74c8

    ld a, b
    cp $c9
    jr nz, jr_052_74d1

jr_052_74c8:
    ld hl, $5406
    rst $10
    ld a, [$db53]
    or a
    ret nz

jr_052_74d1:
    call BattleCall_7085
    ret


jr_052_74d5:
    ld a, [$db77]
    and $03
    cp $03
    jr z, jr_052_74a4

    ld hl, $db77
    inc [hl]
    ld a, [$db77]
    call CheckMonsterSlot
    jr c, jr_052_74d5

    jr jr_052_74f1

    ret


    call BattleCall_7085
    ret


jr_052_74f1:
    ld a, $0a
    ld [$d9ed], a
    ld hl, $d9ef
    dec [hl]
    ret


RollBattle_74fb:
    call GenerateRNG
    ld a, [$dd69]
    or a
    jr nz, jr_052_7514

    ld a, [$db77]
    bit 2, a
    jr z, jr_052_7511

    ld c, $04
    jr jr_052_7515

jr_052_750f:
    scf
    ret


jr_052_7511:
    ld c, a
    jr jr_052_7515

jr_052_7514:
    ld c, a

jr_052_7515:
    ld a, c
    call CheckMonsterSlot
    jr nc, jr_052_7525

    inc c
    ld a, c
    and $03
    cp $02
    jr z, jr_052_750f

    jr jr_052_7515

jr_052_7525:
    ld a, c
    bit 2, a
    jr z, jr_052_7532

    ld a, c
    ld [$dd69], a
    ld hl, $dd69
    inc [hl]

jr_052_7532:
    ld a, c
    ld hl, $dd2c
    add a
    add c
    add a
    add c
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    and $03
    or a
    jr z, jr_052_7552

    cp $01
    jr z, jr_052_7556

    cp $02
    jr z, jr_052_755a

    ld a, $ff
    jr jr_052_755c

jr_052_7552:
    ld a, $40
    jr jr_052_755c

jr_052_7556:
    ld a, $80
    jr jr_052_755c

jr_052_755a:
    ld a, $c0

jr_052_755c:
    ld hl, wRNG1
    cp [hl]
    ld a, c
    ld [wBattleTargetIdx], a
    jr nc, jr_052_758a

    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    ld a, [hl]
    and $03
    jr nz, jr_052_758a

    push bc
    set 0, [hl]
    call SetHLBattle_6c23
    ld a, $ce
    ld [$c823], a
    xor a
    ld [$c822], a
    ld hl, $4c00
    rst $10
    pop bc
    ld hl, $5004
    rst $10

jr_052_758a:
    ld a, [wBattleTargetIdx]
    cp $04
    ret


    call BattleCall_7085
    ld a, $00
    ld [$d9ed], a
    ret


    xor a
    ld [$d9ed], a
    ld a, $01
    ld [$d9ee], a
    ret


    ld hl, $5301
    rst $10
    ret


    ld a, [$d9ee]
    rst $00
    db $76
    ld a, h
    xor c
    ld a, h
    ld l, l
    ld a, l
    ld [hl+], a
    ld a, l
    ret


Compare_75b5:
    cp $c2
    ret c

    cp $c7
    jr c, jr_052_75be

jr_052_75bc:
    scf
    ret


jr_052_75be:
    ld a, [wBattleTargetIdx]
    ld hl, $db02
    call HL_AddA_x8
    ld a, [hl+]
    and $cc
    jr nz, jr_052_75dd

    inc hl
    inc hl
    ld a, [hl+]
    and $3f
    jr nz, jr_052_75dd

    ld a, [hl+]
    and $0c
    jr nz, jr_052_75dd

    ld a, [hl]
    and $c0
    jr z, jr_052_75bc

jr_052_75dd:
    ld hl, wBattleTargetIdx
    inc [hl]
    ld a, [hl]
    call CheckMonsterSlot
    jr nc, jr_052_75be

    ld a, [hl]
    and $03
    cp $02
    jr c, jr_052_75dd

    xor a
    ret


    ld a, [hl]
    and $0c
    jr z, jr_052_7609

    cp $04
    jr z, jr_052_7605

    cp $08
    jr z, jr_052_7601

    ld b, $60
    jr jr_052_760b

jr_052_7601:
    ld b, $a0
    jr jr_052_760b

jr_052_7605:
    ld b, $e0
    jr jr_052_760b

jr_052_7609:
    ld b, $ff

jr_052_760b:
    ld a, [wRNG1]
    cp b
    jr z, jr_052_762d

    jr c, jr_052_762d

    ld a, [hl]
    and $f3
    ld b, a
    ld a, [hl]
    and $0c
    dec a
    push bc
    push af
    pop bc
    bit 5, c
    pop bc
    jr nz, jr_052_7627

    and $0c
    jr jr_052_7628

jr_052_7627:
    xor a

jr_052_7628:
    or b
    ld [hl], a
    ld a, $0f
    ret


jr_052_762d:
    ld a, [hl]
    and $73
    ld [hl], a
    ld a, [wBattleAttackerIdx]
    ld [wBattleTargetIdx], a
    ld hl, $5004
    rst $10
    ld a, $db
    ret


    ld a, [wBattleTargetIdx]
    ld hl, $db07
    call HL_AddA_x8
    ld a, [hl]
    and $c0
    jr z, jr_052_765b

    ld a, [$db8a]
    cp $80
    jr z, jr_052_768e

    cp $83
    jr z, jr_052_768e

    cp $a5
    jr z, jr_052_768e

jr_052_765b:
    dec hl
    ld a, [hl]
    and $0c
    jr z, jr_052_768e

    ld a, [$db8a]
    cp $3a
    jr c, jr_052_768e

    cp $29
    jr c, jr_052_7690

    cp $44
    jr c, jr_052_768e

    cp $5a
    jr c, jr_052_7690

    cp $5b
    jr z, jr_052_7690

    cp $67
    jr c, jr_052_768e

    cp $7e
    jr c, jr_052_7690

    cp $b0
    jr c, jr_052_768e

    cp $d5
    jr c, jr_052_7690

    jr z, jr_052_768e

    cp $da
    jr c, jr_052_7690

jr_052_768e:
    scf
    ret


jr_052_7690:
    ld a, $c1

SaveBattle_7692:
    push af
    ld a, $06
    ld [$d9ed], a
    ld a, [wBattleTargetIdx]
    ld hl, $c180
    ld [$db50], a
    call CheckTargetInRange
    pop af
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $4c00
    rst $10
    scf
    ccf
    ret


    ld a, [wBattleTargetIdx]
    ld hl, $db07
    call HL_AddA_x8
    ld a, [hl]
    and $c0
    ret z

    ld a, $ba
    call SaveBattle_7692
    scf
    ret


BattleFunc_76c8:
    ld bc, $0300

jr_052_76cb:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_052_76dc

    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    bit 6, [hl]
    jr z, jr_052_7709

jr_052_76dc:
    inc c
    dec b
    jr nz, jr_052_76cb

    ld a, $0e
    ld [$d9ec], a
    ld a, [$c86c]
    or a
    jr z, jr_052_76f6

    ld hl, $500a
    rst $10
    ld a, $01
    ld [wBattlePostFlag], a
    jr jr_052_7743

jr_052_76f6:
    ld de, $ca42
    ld hl, $c180
    call Copy4Bytes
    ld hl, $00eb
    ld a, $01
    ld [wBattlePostFlag], a
    jr jr_052_7737

jr_052_7709:
    ld bc, $0304

jr_052_770c:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_052_7723

    ld a, [$c86c]
    or a
    jr z, jr_052_777b

    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    bit 6, [hl]
    jr z, jr_052_777b

jr_052_7723:
    inc c
    dec b
    jr nz, jr_052_770c

    ld a, $00
    ld [wBattlePostFlag], a
    ld a, $00
    ld [$db4e], a
    ld hl, $5009
    rst $10
    jr jr_052_7743

jr_052_7737:
    ld a, h
    ld [$c822], a
    ld a, l
    ld [$c823], a
    ld hl, $4c00
    rst $10

jr_052_7743:
    ld c, $69
    ld a, [$c863]
    bit 1, a
    ld a, [wBattlePostFlag]
    jr z, jr_052_7754

    xor $01
    ld [wBattlePostFlag], a

jr_052_7754:
    or a
    jr z, jr_052_775e

    ld a, $ff
    ld [$db73], a
    ld c, $4f

jr_052_775e:
    push bc
    ld a, $02
    call SetBGM
    pop bc
    ld a, c
    call PlaySoundEffect
    ld a, $00
    ld [$db4e], a
    ld a, $0a
    ld [$d9ec], a
    scf
    ld a, [wBattlePostFlag]
    ld [$dd6b], a
    ret


jr_052_777b:
    ld a, $ff
    ld [$dd6b], a
    xor a
    ret


BattleFunc_7782:
    ld bc, $0300
    call LoadBattle_77a8
    jr nc, jr_052_7795

    inc c
    call LoadBattle_77a8
    jr nc, jr_052_7795

    inc c
    call LoadBattle_77a8
    ret c

jr_052_7795:
    ld bc, $0304
    call LoadBattle_77a8
    jr nc, jr_052_77a7

    inc c
    call LoadBattle_77a8
    jr nc, jr_052_77a7

    inc c
    call LoadBattle_77a8

jr_052_77a7:
    ret


LoadBattle_77a8:
    ld a, [$c86c]
    or a
    jr nz, jr_052_77b7

    ld a, c
    cp $04
    jr c, jr_052_77b7

    call CheckMonsterSlot
    ret


jr_052_77b7:
    ld a, c
    call CheckMonsterSlot
    ret c

    ld a, c
    ld hl, $db02
    call HL_AddA_x8
    bit 6, [hl]
    ret z

    scf
    ret


; [S130 F23] TwinSlash state-4 sub 0: caster alive? (else skip) + anim.
TwinSlashTail0_77c8:
    call LoadBattle_7997
    ret c

    ld a, [wBattleAttackerIdx]
    call CheckMonsterSlot
    jp c, Jump_052_797c

    ld hl, $5f06
    rst $10
    ld hl, $5504
    rst $10
    ld hl, $d9ee
    inc [hl]
    ret


; [S130 F23] TwinSlash RECOIL ($3B only; PsycheUp $56 has no tail): $DB5A =
; max(dmg>>2, 1); caster HP <= recoil -> HP 0 + KO chain, else HP -= recoil.
TwinSlashRecoil_77e2:
    ld hl, $d9ee
    inc [hl]
    ld hl, $d9ee
    inc [hl]
    ld a, [$db56]
    ld c, a
    ld a, [$db57]
    ld b, a
    srl b
    rr c
    srl b
    rr c
    ld a, c
    ld [$db5a], a
    ld a, b
    ld [$db5b], a
    ld a, b
    or c
    jr nz, jr_052_780f

    inc bc
    ld a, c
    ld [$db5a], a
    ld a, b
    ld [$db5b], a

jr_052_780f:
    ld a, [wBattleAttackerIdx]
    ld hl, wBattleHP
    call HL_AddA_x2
    ld d, h
    ld e, l
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call CmpHLvsBC
    ld h, d
    ld l, e
    jr c, jr_052_782e

    jr z, jr_052_782e

    ld a, [hl]
    sub c
    ld [hl+], a
    ld a, [hl]
    sbc b
    ld [hl], a
    jr jr_052_7840

jr_052_782e:
    xor a
    ld [hl-], a
    ld [hl], a
    ld a, $ff
    ld [$d9ef], a
    ld a, $ff
    ld [$d9f0], a
    ld a, $02
    ld [$d9ee], a

SetHLBattle_7840:
jr_052_7840:
    ld hl, $c190
    ld a, [$db5a]
    ld c, a
    ld a, [$db5b]
    ld b, a
    call FormatDecimalDigits
    ld a, $82
    ld [wBattlePostFlag], a
    call LoadBattle_7fcb
    cp $04
    jr c, jr_052_785e

    ld hl, wBattlePostFlag
    inc [hl]

jr_052_785e:
    call LoadBattle_7868
    call z, LoadBattle_7875
    call SetHLBattle_78f4
    ret


LoadBattle_7868:
    ld a, [wBattleAttackerIdx]
    and $04
    ld b, a
    ld a, [wBattleTargetIdx]
    and $04
    cp b
    ret


LoadBattle_7875:
    ld a, [wBattlePostFlag]
    xor $01
    ld [wBattlePostFlag], a
    ret


LoadBattle_787e:
    ld a, [wBattlePostFlag]
    cp $85
    ret z

    cp $e7
    jr z, jr_052_788c

    ld a, $e7
    jr jr_052_788e

jr_052_788c:
    ld a, $ea

jr_052_788e:
    ld [wBattlePostFlag], a
    ret


; [S130 F23] Kamikaze state-4 sub 0: caster alive? (else skip) + anim.
KamikazeTail0_7892:
    call LoadBattle_7997
    ret c

    ld hl, $5f06
    rst $10
    ld hl, $5504
    rst $10
    ld hl, $d9ee
    inc [hl]
    ret


; [S130 F23] Kamikaze caster tail: HP-1 != 0 -> caster HP := 1 (msg $85);
; HP was 1 -> HP := 0 and the KO chain (msg $E7/$EA). Measured S130.
KamikazeSelfTail_78a3:
    ld a, [wBattleAttackerIdx]
    ld hl, wBattleHP
    call HL_AddA_x2
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    dec bc
    ld a, b
    or c
    jr z, jr_052_78c0

    ld a, $03
    ld [$d9ee], a
    ld a, $00
    ld [hl-], a
    ld [hl], $01
    jr jr_052_78e5

jr_052_78c0:
    xor a
    ld [hl-], a
    ld [hl], a
    ld a, $ff
    ld [$d9ef], a
    ld a, $03
    ld [$d9f0], a
    ld a, $02
    ld [$d9ee], a
    ld a, $ea
    ld [wBattlePostFlag], a
    call LoadBattle_7fcb
    cp $04
    jr nc, jr_052_78ea

    ld a, $e7
    ld [wBattlePostFlag], a
    jr jr_052_78ea

jr_052_78e5:
    ld a, $85
    ld [wBattlePostFlag], a

jr_052_78ea:
    call LoadBattle_7868
    call z, LoadBattle_787e
    call SetHLBattle_78f4
    ret


SetHLBattle_78f4:
    ld hl, $5004
    rst $10
    ld hl, $c180
    ld a, l
    ld [$db4e], a
    ld a, h
    ld [$db4f], a
    ld a, [wBattleAttackerIdx]
    ld [$db50], a
    call CheckTargetInRange
    ld a, $00
    ld [$c822], a
    ld a, [wBattlePostFlag]
    ld [$c823], a
    ld hl, $4c00
    rst $10
    ld hl, $5006
    rst $10
    ret


; [S130 F23] Tail sub 2: commit the saved next state ($D9EF/$D9F0 unless $FF),
; redraw the caster, pick the KO/normal message pair.
TailCommitState_7920:
    ld hl, $d9ee
    inc [hl]
    ld a, [$d9ef]
    cp $ff
    jr z, jr_052_792e

    ld [$d9ed], a

jr_052_792e:
    ld a, [$d9f0]
    cp $ff
    jr z, jr_052_7938

    ld [$d9ee], a

jr_052_7938:
    xor a
    ld [$d9ef], a
    ld [$d9f0], a
    call LoadBattle_7a18
    ld hl, $c180
    ld a, l
    ld [$db4e], a
    ld a, h
    ld [$db4f], a
    ld a, [wBattleAttackerIdx]
    ld [$db50], a
    call CheckTargetInRange
    ld a, $00
    ld [$c822], a
    call LoadBattle_7fcb
    cp $04
    jr nc, jr_052_7966

    ld a, $e7
    jr jr_052_7968

jr_052_7966:
    ld a, $ea

jr_052_7968:
    ld [wBattlePostFlag], a
    call LoadBattle_7868
    call z, LoadBattle_787e
    ld a, [wBattlePostFlag]
    ld [$c823], a
    ld hl, $4c00
    rst $10
    ret


Jump_052_797c:
    call LoadBattle_6ecf
    jp nz, Jump_052_7bec

Jump_052_7982:
    ld hl, $d9ed
    inc [hl]
    ld a, $00
    ld [$d9ee], a
    jp Jump_052_6f56


    ld hl, $d9ee
    inc [hl]
    ld hl, $4c00
    rst $10
    ret


LoadBattle_7997:
    ld a, [wBattleAttackerIdx]
    call CheckMonsterSlot
    ret nc

    ld hl, $d9ed
    inc [hl]
    scf
    ret


; [S130 F23] Ramming state-4 sub 0: caster alive? (else skip) + anim.
RammingTail0_79a4:
    call LoadBattle_7997
    ret c

    ld hl, $5f06
    rst $10
    ld hl, $5504
    rst $10
    ld hl, $d9ee
    inc [hl]
    ret


; [S130 F23] Ramming RECOIL: x = caster HP*8/10 + 1 ($DB5A); HP - x, a borrow
; or zero -> HP 0 + KO chain (d9ef=4). Measured S130 (incl. HP<=5 -> KO).
RammingRecoil_79b5:
    ld hl, $d9ee
    inc [hl]
    ld hl, $d9ee
    inc [hl]
    ld a, [wBattleAttackerIdx]
    ld hl, wBattleHP
    call HL_AddA_x2
    push hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    push hl
    call DamageMul8Tenths_69b7
    inc hl
    ld a, l
    ld [$db5a], a
    ld a, h
    ld [$db5b], a
    pop bc
    ld a, c
    sub l
    ld c, a
    ld a, b
    sbc h
    ld b, a
    jr c, jr_052_79e5

    or c
    jr z, jr_052_79e5

    jr jr_052_79e8

jr_052_79e5:
    ld bc, $0000

jr_052_79e8:
    pop hl
    ld a, c
    ld [hl+], a
    ld [hl], b
    or c
    jr nz, jr_052_7a02

    ld hl, $d9ee
    dec [hl]
    ld a, $04
    ld [$d9ef], a
    ld a, $ff
    ld [$d9f0], a
    ld a, $02
    ld [$d9ee], a

jr_052_7a02:
    call SetHLBattle_7840
    ret


    ld a, [$dd69]
    cp $01
    jr nz, jr_052_7a13

    ld a, $01
    ld [$d9ed], a
    ret


jr_052_7a13:
    ld hl, $d9ee
    inc [hl]
    ret


LoadBattle_7a18:
    ld a, [wBattleAttackerIdx]
    ld hl, $dd1b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld [hl], $01
    ld a, [wBattleTargetIdx]
    push af
    ld a, [wBattleAttackerIdx]
    ld [wBattleTargetIdx], a
    call BattleTarget_7242
    pop af
    ld [wBattleTargetIdx], a
    ld a, [wBattleAttackerIdx]
    cp $04
    jr c, jr_052_7a48

    cp $07
    jr z, jr_052_7a48

    ld a, [wBattleAttackerIdx]
    ld [$dd61], a

jr_052_7a48:
    ret


; [S130 F9] DeMagicTailDragon_7a49: DeMagic $80's state-4 tail (+3 bit4 caster ->
; DeMagicTailSelfRevert_7a5f). Never reached in measurement: DeMagic ends inside
; its own bank $53 entry-11 machine (3 dragon casts, 0 hits).
DeMagicTailDragon_7a49:
    ld a, [wBattleAttackerIdx]
    ld hl, $db03
    call HL_AddA_x8
    bit 4, [hl]
    jr nz, jr_052_7a5a

    ld hl, $d9ee
    inc [hl]

jr_052_7a5a:
    ld hl, $d9ee
    inc [hl]
    ret


DeMagicTailSelfRevert_7a5f:
    ld a, [wBattleAttackerIdx]
    ld [wBattleTargetIdx], a
    call TransformCopyStats_5f5e
    ret


; [S130 F5] LifeSong 2nd turn, per own slot from the base: a DEAD slot ->
; SkillVivify with $DB8A = $95 (Revive path: full MaxHP + SaveBattle_51dd);
; live / invalid -> nothing. No caster cost. Measured 45 casts.
LifeSongRevive_7a69:
    ld hl, $d9ee
    inc [hl]
    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    jr z, jr_052_7a7b

    jr nc, jr_052_7a7b

    call SkillVivify
    ret


jr_052_7a7b:
    ld hl, $d9ee
    inc [hl]
    ret


; [S130 F5] LifeSong: the revive message ($9E).
LifeSongMsg_7a80:
    ld hl, $d9ee
    inc [hl]
    call SetHLBattle_6c23
    ld a, $9e
    ld [$c823], a
    xor a
    ld [$c822], a
    ld hl, $4c00
    rst $10
    ret


; [S130 F5] LifeSong: next own slot (skip $DD1B==$FF), stop at side slot 3.
LifeSongNext_7a95:
jr_052_7a95:
    ld hl, $5004
    rst $10
    ld hl, wBattleTargetIdx
    inc [hl]
    ld a, [hl]
    ld b, a
    and $03
    cp $03
    jr z, jr_052_7ab0

    ld a, b
    call CheckMonsterSlot
    jr z, jr_052_7a95

    xor a
    ld [$d9ee], a
    ret


jr_052_7ab0:
    ld hl, $d9ee
    inc [hl]
    ret


ConfusionActionRewrite_7ab5:
    ld a, [wBattleAttackerIdx]
    ld hl, $dcec
    call HL_AddA_x2
    push hl
    ld a, [wRNG1]
    and $03
    ld hl, $7aff
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    pop hl
    ld [hl+], a
    ld c, a
    push hl
    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    ld b, a
    ld a, c
    cp $3a
    jr nz, jr_052_7af6

    ld a, [wRNG1]
    and $03
    add b

jr_052_7ae5:
    ld b, a
    call CheckMonsterSlot
    jr nc, jr_052_7af6

    ld a, b
    and $03
    jr nz, jr_052_7af3

    ld b, a
    or $03

jr_052_7af3:
    dec a
    jr jr_052_7ae5

jr_052_7af6:
    pop hl
    ld a, b
    ld [hl], a
    ld a, $00
    ld [$d9ed], a
    ret


    ld a, [hl-]
    ld e, [hl]
    ld h, d
    add b
    rst $38
    push af
    push bc
    push de
    push hl
    ld a, [wBattleAttackerIdx]
    ld hl, $db05
    call HL_AddA_x8
    ld a, [hl]
    and $c0
    ld [hl], a
    pop hl
    pop de
    pop bc
    pop af
    ret


LoadBattle_7b1a:
    ld a, [$db8a]
    cp $32
    jr z, jr_052_7b24

    cp $66
    ret nz

jr_052_7b24:
    ld a, [wBattleAttackerIdx]
    ld hl, wBattleMP
    call HL_AddA_x2
    xor a
    ld [hl+], a
    ld [hl], a
    ret


    ld hl, $d9ee
    inc [hl]
    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    jr c, jr_052_7b70

    ld a, [wBattleTargetIdx]
    ld hl, $db02
    call HL_AddA_x8
    ld a, l
    ld [$db61], a
    ld a, h
    ld [$db62], a
    ld a, [hl]
    and $03
    jr nz, jr_052_7b70

    call BattleCall_65c9
    jr nc, jr_052_7b70

    ld a, [$db61]
    ld l, a
    ld a, [$db62]
    ld h, a
    set 0, [hl]
    ld a, $ce
    ld [$c823], a
    xor a
    ld [$c822], a
    ld hl, $5f06
    rst $10
    ret


jr_052_7b70:
    ld hl, $d9ee
    inc [hl]
    ret


    ld hl, $d9ee
    inc [hl]
    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    jr c, jr_052_7bb2

    ld a, [wBattleTargetIdx]
    ld hl, $db02
    call HL_AddA_x8
    bit 7, [hl]
    jr nz, jr_052_7bb2

    call SetHLBattle_5c8f
    jr nc, jr_052_7bb2

    call BattleTarget_4262
    ld c, $cc
    call LoadBattle_7fcb
    cp $04
    jr nc, jr_052_7ba0

    inc c

jr_052_7ba0:
    ld a, c
    ld [$c823], a
    xor a
    ld [$c822], a
    ld a, $04
    ld [$d9ed], a
    ld hl, $5f06
    rst $10
    ret


jr_052_7bb2:
    ld hl, $d9ee
    inc [hl]
    ret


    ld hl, $d9ee
    inc [hl]
    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    jr c, jr_052_7be7

    ld a, [wBattleTargetIdx]
    ld hl, $db02
    call HL_AddA_x8
    bit 6, [hl]
    jr nz, jr_052_7be7

    push hl
    call BattleCall_65b5
    pop hl
    jr nc, jr_052_7be7

    set 6, [hl]
    ld a, $cf
    ld [$c823], a
    xor a
    ld [$c822], a
    ld hl, $5f06
    rst $10
    ret


jr_052_7be7:
    ld hl, $d9ee
    inc [hl]
    ret


; [S130 F6] BladeD counter: target incapacitated (GetMonsterSlotInfo) -> none, no RNG. Else ONE
; [S130 F6] BattleRNG step; $DB42[t] bit3 -> RNG1 &= $FE; (dmg>>1) == 0 -> RNG1 := 1 (both write the
; [S130 F6] RNG state); RNG1 even -> act state $13: the attacker loses dmg>>1 HP (0 -> KO).
; [S130 F6] Measured S130 (counter, counter_rng, counter_hp; KO 2).
BladeDCounter_7bec:
LoadBattle_7bec:
Jump_052_7bec:
    ld a, [$dd6e]
    or a
    jp nz, Jump_052_6e89

    ld a, $13
    ld [$d9ed], a
    ld hl, $c180
    ld a, l
    ld [$db4e], a
    ld a, h
    ld [$db4f], a
    ld a, [wBattleTargetIdx]
    ld b, a
    call GetMonsterSlotInfo
    jp c, Jump_052_7982

    ld a, [wBattleTargetIdx]
    ld [$db50], a
    call CheckTargetInRange
    call BattleRNG
    ld b, $00
    ld a, [wBattleTargetIdx]
    ld hl, $db42
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    bit 3, [hl]
    jr z, jr_052_7c32

    ld hl, wRNG1
    res 0, [hl]
    ld b, $01

jr_052_7c32:
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    call HLsrl1
    ld a, h
    or l
    or a
    jr nz, jr_052_7c47

    ld a, $01
    ld [wRNG1], a

jr_052_7c47:
    ld a, [wRNG1]
    and $01
    add $d5
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    bit 0, b
    call nz, LoadBattle_7c92
    ld hl, $4c00
    rst $10
    ld a, [wRNG1]
    and $01
    ld [$d9ee], a
    ld a, [wRNG1]
    and $01
    ret z

    ld a, [$d9ee]
    add $01
    ld [$d9ee], a
    ret


    ld hl, $d9ee
    inc [hl]
    call LoadBattle_7c98
    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    ret c

    ld hl, $5f04
    rst $10
    ld hl, $5500
    rst $10
    ld a, $80
    ld [$db54], a
    ret


LoadBattle_7c92:
    ld a, $6a
    ld [$c823], a
    ret


; [S130 F6] wBattleAttackerIdx <-> wBattleTargetIdx (the counter hits the attacker).
SwapAttackerTarget_7c98:
LoadBattle_7c98:
jr_052_7c98:
    ld a, [wBattleAttackerIdx]
    ld l, a
    ld a, [wBattleTargetIdx]
    ld h, a
    ld a, l
    ld [wBattleTargetIdx], a
    ld a, h
    ld [wBattleAttackerIdx], a
    ret


    ld hl, $d9ee
    inc [hl]
    ld a, [wBattleTargetIdx]
    call CheckMonsterSlot
    jr c, jr_052_7c98

    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    call HLsrl1
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ld a, h
    or l
    jr z, jr_052_7d1e

    call BattleCall_50e2
    ld c, $82
    call LoadBattle_7fcb
    bit 2, a
    jr nz, jr_052_7cda

    ld c, $83

jr_052_7cda:
    ld a, c
    ld [$c823], a
    xor a
    ld [$c822], a
    ld hl, $4c00
    rst $10
    ld a, $01
    ld [$da82], a
    ld a, $00
    ld [$da83], a
    call LoadBattle_7c98
    ld hl, wBattleHP
    call HL_AddA_x2
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    ld a, [$db56]
    ld c, a
    ld a, [$db57]
    ld b, a
    ld a, e
    sub c
    ld e, a
    ld a, d
    sbc b
    ld d, a
    ld [hl], d
    push af
    dec hl
    pop bc
    ld [hl], e
    ld a, d
    or e
    jr z, jr_052_7d16

    push bc
    pop af
    ret nc

jr_052_7d16:
    xor a
    ld [hl+], a
    ld [hl], a
    ld hl, $d9ee
    inc [hl]
    ret


jr_052_7d1e:
    call SetHLBattle_5143
    ret


    ld hl, $c180
    ld a, l
    ld [$db4e], a
    ld a, h
    ld [$db4f], a
    ld a, [wBattleAttackerIdx]
    ld [$db50], a
    call CheckTargetInRange
    ld a, $00
    ld [$c822], a
    ld b, $e3
    ld a, [wBattleAttackerIdx]
    rrca
    rrca
    and $01
    add b
    ld [$c823], a
    ld hl, $4c00
    rst $10
    ld hl, $d9ee
    dec [hl]
    ld a, [wBattleAttackerIdx]
    ld [$db4c], a
    ld hl, $5103
    rst $10
    ld a, [wBattleTargetIdx]
    push af
    ld a, [wBattleAttackerIdx]
    ld [wBattleTargetIdx], a
    ld hl, $5801
    rst $10
    pop af
    ld [wBattleTargetIdx], a
    ret


    ld a, $05
    ld [$d9ed], a
    xor a
    ld [$d9ee], a
    ret


SetHLBattle_7d77:
    ld hl, $5701
    rst $10
    ret


; [S130 F6] After a TailWind reflection ($DD6D == 2) with the side byte bit5 (StormWind) set: a
; [S130 F6] message choice only (no state change modelled).
WindMsgCheck_7d7c:
LoadBattle_7d7c:
    ld a, [$dd6d]
    cp $02
    jr nz, jr_052_7dc8

    ld a, [wBattleTargetIdx]
    rrca
    rrca
    and $01
    ld hl, $db00
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    bit 5, [hl]
    jr z, jr_052_7dc8

    ld a, [wBattleTargetIdx]
    ld e, a
    and $04
    ld c, a
    cp $04
    jr c, jr_052_7da7

    ld a, [$db75]
    jr jr_052_7daa

jr_052_7da7:
    ld a, [$db74]

jr_052_7daa:
    ld b, a

jr_052_7dab:
    ld a, c
    cp e
    jr z, jr_052_7db1

    jr nc, jr_052_7db7

jr_052_7db1:
    inc c
    dec b
    jr nz, jr_052_7dab

    jr jr_052_7dc8

jr_052_7db7:
    ld a, c
    call CheckMonsterSlot
    jr nc, jr_052_7dc3

    inc c
    dec b
    jr nz, jr_052_7db7

    jr jr_052_7dc8

jr_052_7dc3:
    xor a
    ld [$dd6d], a
    ret


jr_052_7dc8:
    ld hl, $4c03
    rst $10
    ret


LoadBattle_7dcd:
    ld a, [wBattleAttackerIdx]
    ld hl, $db06
    call HL_AddA_x8
    ret


; [S130 F6] Imitate check after every victim (hit or fail route): not $7F, $DD6E == 0, $DD6C == 0
; [S130 F6] ($20 -> restore), attacker not airborne, target-mode bit4, victim $DB08+8t bit3 and capable
; [S130 F6] -> flags9 bit2 ? msg $D3 + re-cast by the victim ($DD6C = 8, setup sub-state 2: the
; [S130 F6] imitator PAYS the MP / can be vetoed) : msg $D4. Measured S130 (imitate*, imitate_veto).
ImitateCheck_7dd7:
LoadBattle_7dd7:
    ld a, [$db8a]
    cp $7f
    jr nz, jr_052_7de0

jr_052_7dde:
    xor a
    ret


jr_052_7de0:
    ld a, [$dd6e]
    or a
    jr nz, jr_052_7dde

    ld a, [$dd6c]
    or a
    jr z, jr_052_7df9

    cp $08
    jr z, jr_052_7dde

    cp $20
    jr nz, jr_052_7dde

    call LoadBattle_7ef1
    jr jr_052_7dde

jr_052_7df9:
    ld a, [wBattleAttackerIdx]
    ld hl, $db06
    call HL_AddA_x8
    ld a, [hl]
    and $0c
    cp $0c
    ret z

    ; [S110 rec] target mode bit4 (aimed at the foes) + target Imitate (+8 bit3) -> flags9 bit2 decides
    ld a, [$dcfc]
    bit 4, a
    jr z, jr_052_7dde

    ld a, [wBattleTargetIdx]
    ld hl, $db08
    call HL_AddA_x8
    bit 3, [hl]
    jr z, jr_052_7dde

    ld a, [wBattleTargetIdx]
    call GetMonsterSlotInfo
    jr c, jr_052_7dde

    ; [S110 rec] flags9 bit2: Imitate turns it back ("gets even!" $D3), else "can't get even!" $D4
    ld a, [$dcff]
    bit 2, a
    jr z, jr_052_7e44

    ld a, $d3
    call SaveBattle_7e74
    ld a, $08
    ld [$dd6c], a
    ld a, $08
    ld [$db4c], a
    ld hl, $5309
    rst $10
    xor a
    ld [$c1c9], a
    scf
    ret


jr_052_7e44:
    ld a, $d4
    call SaveBattle_7e74
    xor a
    ret


    ld a, [wBattleTargetIdx]
    ld hl, $db03
    call HL_AddA_x8
    ; [S110 rec] flags7 bit6 spell / bit5 dance / bit4 breath -> which seal applies (StopSpell or side +0 bit3 / DanceShut / MouthShut)
    ld a, [$dcfd]
    bit 6, a
    jr nz, jr_052_7e64

    bit 5, a
    jr nz, jr_052_7e6e

    bit 4, a
    jr nz, jr_052_7e71

    ret


jr_052_7e64:
    bit 0, [hl]
    jr nz, jr_052_7e44

    ld a, [$db00]
    bit 3, a
    ret


jr_052_7e6e:
    bit 6, [hl]
    ret


jr_052_7e71:
    bit 7, [hl]
    ret


SaveBattle_7e74:
    push af
    call SetHLBattle_6c23
    pop af
    ld [$c823], a
    xor a
    ld [$c822], a
    ld hl, $4c00
    rst $10
    ret


LoadBattle_7e85:
    ld a, [$dd6e]
    or a
    ret z

    cp $01
    jr z, jr_052_7e96

    ld a, [$dd6d]
    cp $02
    jr z, jr_052_7ea7

    ret


jr_052_7e96:
    call LoadBattle_7ea7
    ld hl, $db08
    call HL_AddA_x8
    res 4, [hl]
    inc hl
    ld a, [hl]
    and $0f
    ld [hl], a
    ret


LoadBattle_7ea7:
jr_052_7ea7:
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    call HL_AddA_x2
    ld a, [hl]
    ld [wBattleTargetIdx], a
    ret


    ld a, $bb
    ld [$c823], a
    xor a
    ld [$c822], a
    ld hl, $4c00
    rst $10
    ld a, $01
    ld [$db8a], a
    ld a, $ff
    ld [$db77], a
    ld a, $ff
    ld [$db78], a
    ld hl, $5406
    rst $10
    call BattleCall_7085
    ret


    ld hl, $5700
    rst $10
    ret


    ld hl, $580c
    rst $10
    ret


    ld hl, $510f
    rst $10
    ret


    ld a, [$c825]
    or a
    ret nz

    call BattleCall_710e
    ret


; [S130 F6] Restore after a reflect / re-cast ($DD6C != 0): attacker, target, $DD69, both queue pairs
; [S130 F6] and $DD13 from $C1C0; the original sweep then continues with its next victim.
ReflectRestore_7ef1:
LoadBattle_7ef1:
    ld a, [$dd6c]
    or a
    jp z, Jump_052_7fc9

    ld hl, $c1c0
    ld a, [hl+]
    ld [wBattleAttackerIdx], a
    ld a, [hl+]
    ld [wBattleTargetIdx], a
    ld a, [hl+]
    ld [$dd69], a
    ld a, [wBattleAttackerIdx]
    ld de, $dcec
    add a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    ld a, [wBattleTargetIdx]
    ld de, $dcec
    add a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    ld a, [wBattleTargetIdx]
    ld de, $dd13
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [hl]
    ld [de], a
    ld a, [$dd6c]
    cp $40
    jp z, Jump_052_7fc9

    cp $01
    jr z, jr_052_7f9e

    cp $02
    jr z, jr_052_7f55

    cp $04
    call z, LoadBattle_7fb2

jr_052_7f4e:
    ld a, $00
    ld [$dd6c], a
    xor a
    ret


jr_052_7f55:
    ld a, [wBattleTargetIdx]
    rrca
    rrca
    and $01
    ld hl, $db4a
    add l
    ld l, a
    ld a, [hl]
    rrca
    rrca
    and $03
    ld l, a
    ld a, [wBattleTargetIdx]
    and $04
    or l
    ld [$db4c], a
    call GetMonsterSlotInfo
    jr c, jr_052_7f83

    ld a, [$db4c]
    ld hl, $db02
    call HL_AddA_x8
    ld a, [hl]
    and $c0
    jr z, jr_052_7f4e

jr_052_7f83:
    ld a, [wBattleTargetIdx]
    or $03
    ld [wBattleTargetIdx], a
    ld a, [wBattleAttackerIdx]
    ld hl, $dced
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    or $03
    ld [hl], a
    jr jr_052_7fc9

jr_052_7f9e:
    ld a, $d9
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $4c00
    rst $10
    xor a
    ld [$dd6d], a
    jr jr_052_7f4e

LoadBattle_7fb2:
    ld a, [$dd6d]
    cp $07
    ret nz

    ld a, $de
    ld [$c823], a
    xor a
    ld [$c822], a
    ld [$dd6d], a
    ld hl, $4c00
    rst $10
    ret


Jump_052_7fc9:
jr_052_7fc9:
    scf
    ret


LoadBattle_7fcb:
    ld a, [$c863]
    bit 1, a
    ld a, [wBattleTargetIdx]
    ret z

    ld a, [wBattleAttackerIdx]
    ret


; [S130 F4] CF set = no live slot on the attacker's opposing side.
NoLiveOpponent_7fd8:
LoadBattle_7fd8:
    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    ld c, a
    ld b, $03

jr_052_7fe2:
    ld a, c
    call CheckMonsterSlot
    ret nc

    inc c
    dec b
    jr nz, jr_052_7fe2

    scf
    ret


; =============================================================================
; [S2d] CUSTOM-SKILL BATTLE DISPATCH TRAMPOLINE
; (replaces the retired alias POCs; same 19 bytes of $00 padding at $7FED-$7FFF)
; -----------------------------------------------------------------------------
; De-aliased model: a custom id ($DE-$FF) flows with its REAL value. FarSkillFork
; (bank $72) returns HL = &CustomSkillPtr for any custom id. The dispatcher's
; `call RST_08` then derefs [CustomSkillPtr] -> CustomDispatch52 and jp's to it
; with bank $52 mapped. CustomDispatch52 far-calls bank $72 entry 1
; (CustomBattleExec), which selects + runs the per-id handler (ROM0 + RAM only),
; returns; the rst restores bank $52; the trailing `ret` returns into the
; dispatcher (after its `call RST_08`). Scales to all 34 custom ids via $72.
; =============================================================================
CustomSkillPtr:              ; $7FED — the single &handler-pointer FarSkillFork returns
    dw CustomDispatch52
CustomDispatch52:            ; $7FEF — jp'd in $52 ctx; runs the standard damage-skill
                             ; CONTEXT setup here (only callable with bank $52 mapped),
                             ; THEN far-calls $72 for the per-skill custom override.
    call MegaMagicDamage_653e     ; MegaMagic's exact setup: damage-result context + base $db56
CustomDispatch52_shared:     ; [MOURN S75] shared tail — MournDispatch52 jp's here after
                             ; calling CalcDefenseWrapper (defense-calc path vs MegaMagic path)
    call SetHLBattle_54e7    ; descriptor $dd6f=$a8, msg pair $dd70/71=$b882 (hit/miss ids)
    ld hl, $7201             ; bank $72, entry 1 = CustomBattleExec
    rst $10                  ; far-call: override $db56 with the skill's real damage + cost
    jp CustomElemTail52      ; [S111] + the skill's element (E = level / $FF, HL = status)
MournDispatchPtr:            ; [MOURN S75] the dw FarSkillFork returns for $E9 Mourn — 
    dw MournDispatch52       ;   dereffed by the dispatcher to jp MournDispatch52 ($6c56)
.pad
    ds $8000 - .pad, $00     ; pad remaining tail (preserves bank size)
