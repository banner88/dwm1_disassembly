; =============================================================================
; BANK $41 — NAME TABLES (MONSTERS, SKILLS, ITEMS, PERSONALITIES, GAME TEXT)
; =============================================================================
; Contains:
;   - Code/dispatch table at $4000-$4338 (73-entry dispatch + handler code)
;   - MonsterNamePtrTable at $4339 (256 × dw → MonsterName_XXX labels)
;   - SkillNamePtrTable at $4539 (256 × dw → SkillName_XXX labels)
;   - FamilyCodePtrTable at $4739 (215 × dw → FamilyCode_XXX labels)
;   - ItemNamePtrTable at $48E7 (44 × dw → ItemName_XX labels)
;   - ItemDescPtrTable at $493F (44 × dw → ItemDesc_XX labels)
;   - PersonalityNamePtrTable at $4997 (27 × dw → PersonalityName_XX labels)
;   - MiscTextPtrTable at $49CD (37 × dw — battle/level up text)
;   - WatabouTextPtrTable at $4A17 (2 × dw)
;   - ItemUseTextPtrTable at $4A1B (48 × dw — item use messages)
;   - SpellUseTextPtrTable at $4A7B (12 × dw — spell cast messages)
;   - Code functions at $4A93 (3 × 7 bytes)
;   - Dispatch text strings at $4AA8-$5B1E (game text, raw hex w/ labels)
;   - MonsterNameStrings at $5B1F (222 unique, $F0 terminated)
;   - SkillNameStrings at $628E (222 unique + 1 empty, $F0 terminated)
;   - FamilyCodeStrings at $69F2 (215 entries, 2 chars + $F0)
;   - ItemNameStrings at $6C78 (43 entries, $F0 terminated)
;   - ItemDescStrings at $6DF8 (43 entries, with $F1=newline control codes)
;   - PersonalityNameStrings at $7159 (27 entries, $F0 terminated)
;   - Game text at $7229-$7FFF (misc/item use/spell use text, raw hex w/ labels)
;
; TEXT ENCODING: Uses charmap.asm (A=$24, a=$3E, space=$62, etc.)
;   Names terminated by $F0. Edit strings directly: db "NewName", $F0
;   All pointer tables use labels — name length changes auto-update!
;   Bank is exactly full — adding bytes requires shortening elsewhere.
;
; Sources: gen_name_tables_db.py, gen_bank41_remaining_db.py, charmap.asm
; =============================================================================

SECTION "ROM Bank $041", ROMX[$4000], BANK[$41]

; --- Code/data ($4000-$4338, 825 bytes) ---
    db $41, $93, $4A, $9A, $4A, $A1, $4A, $25, $40, $39, $40, $01, $41, $E3, $41, $18
    db $7E, $39, $43, $39, $45, $39, $47, $E7, $48, $3F, $49, $97, $49, $CD, $49, $17
    db $4A, $1B, $4A, $7B, $4A, $A8, $4A, $A8, $4A, $A8, $4A, $A8, $4A, $25, $4B, $71
    db $4B, $83, $4B, $9B, $4B, $C1, $4B, $12, $4C, $5E, $4C, $65, $4C, $6D, $4C, $6D
    db $4C, $75, $4C, $7C, $4C, $84, $4C, $8B, $4C, $93, $4C, $98, $4C, $9E, $4C, $A6
    db $4C, $AE, $4C, $B3, $4C, $BB, $4C, $C3, $4C, $C4, $4C, $CC, $4C, $D4, $4C, $D5
    db $4C, $DD, $4C, $E5, $4C, $E6, $4C, $EE, $4C, $F4, $4C, $F5, $4C, $F6, $4C, $FF
    db $4C, $00, $4D, $08, $4D, $10, $4D, $18, $4D, $20, $4D, $28, $4D, $2F, $4D, $33
    db $4D, $3A, $4D, $3B, $4D, $3C, $4D, $3D, $4D, $45, $4D, $4D, $4D, $55, $4D, $5D
    db $4D, $65, $4D, $6D, $4D, $75, $4D, $7D, $4D, $85, $4D, $8D, $4D, $95, $4D, $9D
    db $4D, $A4, $4D, $AC, $4D, $B3, $4D, $BA, $4D, $BF, $4D, $C7, $4D, $CF, $4D, $D6
    db $4D, $DD, $4D, $E6, $4D, $EC, $4D, $F3, $4D, $FA, $4D, $01, $4E, $08, $4E, $0E
    db $4E, $16, $4E, $1D, $4E, $24, $4E, $2B, $4E, $32, $4E, $39, $4E, $40, $4E, $48
    db $4E, $50, $4E, $58, $4E, $60, $4E, $67, $4E, $6D, $4E, $75, $4E, $7D, $4E, $85
    db $4E, $8D, $4E, $94, $4E, $9B, $4E, $A3, $4E, $AB, $4E, $B3, $4E, $BB, $4E, $C3
    db $4E, $C9, $4E, $CF, $4E, $D5, $4E, $DC, $4E, $E3, $4E, $EA, $4E, $F2, $4E, $F8
    db $4E, $F9, $4E, $FC, $4E, $0D, $4F, $20, $4F, $33, $4F, $42, $4F, $58, $4F, $6A
    db $4F, $82, $4F, $90, $4F, $A9, $4F, $C6, $4F, $D3, $4F, $E0, $4F, $E6, $4F, $EA
    db $4F, $04, $50, $0E, $50, $39, $50, $47, $50, $58, $50, $6F, $50, $7D, $50, $9B
    db $50, $C0, $50, $CC, $50, $E4, $50, $FB, $50, $2A, $51, $49, $51, $87, $51, $A3
    db $51, $B6, $51, $C5, $51, $D7, $51, $E9, $51, $06, $52, $14, $52, $36, $52, $51
    db $52, $6A, $52, $7B, $52, $AD, $52, $CD, $52, $E5, $52, $ED, $52, $01, $53, $11
    db $53, $1C, $53, $73, $53, $7C, $53, $96, $53, $9D, $53, $A4, $53, $A7, $53, $AA
    db $53, $B7, $53, $C5, $53, $CD, $53, $DA, $53, $DC, $53, $DE, $53, $E0, $53, $E2
    db $53, $E4, $53, $E6, $53, $E8, $53, $EA, $53, $0E, $54, $14, $54, $51, $54, $5C
    db $54, $68, $54, $7C, $54, $91, $54, $A1, $54, $FF, $54, $20, $55, $3C, $55, $5B
    db $55, $98, $55, $D4, $55, $F0, $55, $F9, $55, $11, $56, $32, $56, $37, $56, $53
    db $56, $75, $56, $9D, $56, $A8, $56, $A8, $56, $A8, $56, $EB, $56, $16, $57, $33
    db $57, $3E, $57, $48, $57, $52, $57, $5C, $57, $66, $57, $6D, $57, $76, $57, $80
    db $57, $87, $57, $8C, $57, $94, $57, $9F, $57, $AB, $57, $B6, $57, $C0, $57, $CC
    db $57, $CD, $57, $01, $58, $06, $58, $0B, $58, $10, $58, $15, $58, $1A, $58, $29
    db $58, $2E, $58, $32, $58, $36, $58, $3A, $58, $3F, $58, $44, $58, $49, $58, $4E
    db $58, $52, $58, $57, $58, $5C, $58, $60, $58, $65, $58, $6A, $58, $6F, $58, $73
    db $58, $78, $58, $7D, $58, $82, $58, $87, $58, $8C, $58, $91, $58, $96, $58, $9B
    db $58, $A0, $58, $A5, $58, $AA, $58, $AF, $58, $B4, $58, $B9, $58, $BD, $58, $C2
    db $58, $C7, $58, $CB, $58, $D0, $58, $D5, $58, $DA, $58, $DF, $58, $E4, $58, $E9
    db $58, $EE, $58, $F3, $58, $F8, $58, $FD, $58, $02, $59, $07, $59, $0C, $59, $11
    db $59, $16, $59, $1A, $59, $1F, $59, $24, $59, $29, $59, $2D, $59, $32, $59, $36
    db $59, $3B, $59, $40, $59, $45, $59, $4A, $59, $4F, $59, $54, $59, $59, $59, $5E
    db $59, $62, $59, $67, $59, $6C, $59, $70, $59, $75, $59, $7A, $59, $7E, $59, $82
    db $59, $87, $59, $8C, $59, $91, $59, $96, $59, $9A, $59, $9F, $59, $A4, $59, $A9
    db $59, $AE, $59, $B3, $59, $B8, $59, $BD, $59, $C2, $59, $C7, $59, $CC, $59, $D0
    db $59, $D5, $59, $DA, $59, $DF, $59, $E4, $59, $E9, $59, $EE, $59, $F3, $59, $F8
    db $59, $FD, $59, $02, $5A, $07, $5A, $0C, $5A, $11, $5A, $16, $5A, $1A, $5A, $1F
    db $5A, $23, $5A, $27, $5A, $2B, $5A, $2F, $5A, $33, $5A, $38, $5A, $3D, $5A, $42
    db $5A, $47, $5A, $4C, $5A, $51, $5A, $55, $5A, $5A, $5A, $5F, $5A, $63, $5A, $68
    db $5A, $6D, $5A, $71, $5A, $76, $5A, $7B, $5A, $7F, $5A, $84, $5A, $88, $5A, $8C
    db $5A, $90, $5A, $95, $5A, $9A, $5A, $9F, $5A, $A3, $5A, $A7, $5A, $AC, $5A, $B1
    db $5A, $B6, $5A, $BB, $5A, $C0, $5A, $C5, $5A, $CA, $5A, $CF, $5A, $D4, $5A, $D9
    db $5A, $DE, $5A, $E3, $5A, $E8, $5A, $ED, $5A, $F2, $5A, $F7, $5A, $FB, $5A, $00
    db $5B, $05, $5B, $0A, $5B, $0C, $5B, $0E, $5B, $10, $5B, $12, $5B, $14, $5B, $16
    db $5B, $18, $5B, $1A, $5B, $1C, $5B, $1E, $5B

MonsterNamePtrTable:  ; $4339 — 256 entries, indexed by monster ID
    dw MonsterName_000_DrakSlime  ; [  0]
    dw MonsterName_001_SpotSlime  ; [  1]
    dw MonsterName_002_WingSlime  ; [  2]
    dw MonsterName_003_TreeSlime  ; [  3]
    dw MonsterName_004_Snaily  ; [  4]
    dw MonsterName_005_SlimeNite  ; [  5]
    dw MonsterName_006_Babble  ; [  6]
    dw MonsterName_007_BoxSlime  ; [  7]
    dw MonsterName_008_Slime  ; [  8]
    dw MonsterName_009_Healer  ; [  9]
    dw MonsterName_010_FangSlime  ; [ 10]
    dw MonsterName_011_RockSlime  ; [ 11]
    dw MonsterName_012_SlimeBorg  ; [ 12]
    dw MonsterName_013_Slabbit  ; [ 13]
    dw MonsterName_014_SpotKing  ; [ 14]
    dw MonsterName_015_KingSlime  ; [ 15]
    dw MonsterName_016_Metaly  ; [ 16]
    dw MonsterName_017_Metabble  ; [ 17]
    dw MonsterName_018_MetalKing  ; [ 18]
    dw MonsterName_019_GoldSlime  ; [ 19]
    dw MonsterName_020_DragonKid  ; [ 20]
    dw MonsterName_021_Tortragon  ; [ 21]
    dw MonsterName_022_Pteranod  ; [ 22]
    dw MonsterName_023_Gasgon  ; [ 23]
    dw MonsterName_024_FairyDrak  ; [ 24]
    dw MonsterName_025_LizardMan  ; [ 25]
    dw MonsterName_026_Poisongon  ; [ 26]
    dw MonsterName_027_Swordgon  ; [ 27]
    dw MonsterName_028_Dragon  ; [ 28]
    dw MonsterName_029_MiniDrak  ; [ 29]
    dw MonsterName_030_MadDragon  ; [ 30]
    dw MonsterName_031_Rayburn  ; [ 31]
    dw MonsterName_032_Chamelgon  ; [ 32]
    dw MonsterName_033_LizardFly  ; [ 33]
    dw MonsterName_034_Andreal  ; [ 34]
    dw MonsterName_035_KingCobra  ; [ 35]
    dw MonsterName_036_Spikerous  ; [ 36]
    dw MonsterName_037_GreatDrak  ; [ 37]
    dw MonsterName_038_Crestpent  ; [ 38]
    dw MonsterName_039_WingSnake  ; [ 39]
    dw MonsterName_040_Coatol  ; [ 40]
    dw MonsterName_041_Orochi  ; [ 41]
    dw MonsterName_042_BattleRex  ; [ 42]
    dw MonsterName_043_SkyDragon  ; [ 43]
    dw MonsterName_044_Divinegon  ; [ 44]
    dw MonsterName_045_Tonguella  ; [ 45]
    dw MonsterName_046_Almiraj  ; [ 46]
    dw MonsterName_047_CatFly  ; [ 47]
    dw MonsterName_048_PillowRat  ; [ 48]
    dw MonsterName_049_Saccer  ; [ 49]
    dw MonsterName_050_GulpBeast  ; [ 50]
    dw MonsterName_051_Skullroo  ; [ 51]
    dw MonsterName_052_WindBeast  ; [ 52]
    dw MonsterName_053_Anteater  ; [ 53]
    dw MonsterName_054_SuperTen  ; [ 54]
    dw MonsterName_055_IronTurt  ; [ 55]
    dw MonsterName_056_Mommonja  ; [ 56]
    dw MonsterName_057_HammerMan  ; [ 57]
    dw MonsterName_058_Grizzly  ; [ 58]
    dw MonsterName_059_Yeti  ; [ 59]
    dw MonsterName_060_MadGopher  ; [ 60]
    dw MonsterName_061_FairyRat  ; [ 61]
    dw MonsterName_062_Unicorn  ; [ 62]
    dw MonsterName_063_Goategon  ; [ 63]
    dw MonsterName_064_WildApe  ; [ 64]
    dw MonsterName_065_Trumpeter  ; [ 65]
    dw MonsterName_066_KingLeo  ; [ 66]
    dw MonsterName_067_DarkHorn  ; [ 67]
    dw MonsterName_068_MadCat  ; [ 68]
    dw MonsterName_069_BigEye  ; [ 69]
    dw MonsterName_070_Picky  ; [ 70]
    dw MonsterName_071_Wyvern  ; [ 71]
    dw MonsterName_072_BullBird  ; [ 72]
    dw MonsterName_073_Florajay  ; [ 73]
    dw MonsterName_074_DuckKite  ; [ 74]
    dw MonsterName_075_MadPecker  ; [ 75]
    dw MonsterName_076_MadRaven  ; [ 76]
    dw MonsterName_077_MistyWing  ; [ 77]
    dw MonsterName_078_Dracky  ; [ 78]
    dw MonsterName_079_BigRoost  ; [ 79]
    dw MonsterName_080_StubBird  ; [ 80]
    dw MonsterName_081_LandOwl  ; [ 81]
    dw MonsterName_082_MadGoose  ; [ 82]
    dw MonsterName_083_MadCondor  ; [ 83]
    dw MonsterName_084_Blizzardy  ; [ 84]
    dw MonsterName_085_Phoenix  ; [ 85]
    dw MonsterName_086_ZapBird  ; [ 86]
    dw MonsterName_087_WhipBird  ; [ 87]
    dw MonsterName_088_FunkyBird  ; [ 88]
    dw MonsterName_089_RainHawk  ; [ 89]
    dw MonsterName_090_MadPlant  ; [ 90]
    dw MonsterName_091_FireWeed  ; [ 91]
    dw MonsterName_092_FloraMan  ; [ 92]
    dw MonsterName_093_WingTree  ; [ 93]
    dw MonsterName_094_CactiBall  ; [ 94]
    dw MonsterName_095_Gulpple  ; [ 95]
    dw MonsterName_096_Toadstool  ; [ 96]
    dw MonsterName_097_AmberWeed  ; [ 97]
    dw MonsterName_098_Stubsuck  ; [ 98]
    dw MonsterName_099_Oniono  ; [ 99]
    dw MonsterName_100_DanceVegi  ; [100]
    dw MonsterName_101_TreeBoy  ; [101]
    dw MonsterName_102_FaceTree  ; [102]
    dw MonsterName_103_HerbMan  ; [103]
    dw MonsterName_104_BeanMan  ; [104]
    dw MonsterName_105_EvilSeed  ; [105]
    dw MonsterName_106_ManEater  ; [106]
    dw MonsterName_107_Snapper  ; [107]
    dw MonsterName_108_Rosevine  ; [108]
    dw MonsterName_109_Watabou  ; [109]
    dw MonsterName_110_GiantSlug  ; [110]
    dw MonsterName_111_Catapila  ; [111]
    dw MonsterName_112_Gophecada  ; [112]
    dw MonsterName_113_Butterfly  ; [113]
    dw MonsterName_114_WeedBug  ; [114]
    dw MonsterName_115_GiantWorm  ; [115]
    dw MonsterName_116_Lipsy  ; [116]
    dw MonsterName_117_StagBug  ; [117]
    dw MonsterName_118_ArmyAnt  ; [118]
    dw MonsterName_119_GoHopper  ; [119]
    dw MonsterName_120_TailEater  ; [120]
    dw MonsterName_121_ArmorPede  ; [121]
    dw MonsterName_122_Eyeder  ; [122]
    dw MonsterName_123_GiantMoth  ; [123]
    dw MonsterName_124_Droll  ; [124]
    dw MonsterName_125_ArmyCrab  ; [125]
    dw MonsterName_126_MadHornet  ; [126]
    dw MonsterName_127_HornBeet  ; [127]
    dw MonsterName_128_Armorpion  ; [128]
    dw MonsterName_129_Digster  ; [129]
    dw MonsterName_130_Pixy  ; [130]
    dw MonsterName_131_ArcDemon  ; [131]
    dw MonsterName_132_AgDevil  ; [132]
    dw MonsterName_133_Demonite  ; [133]
    dw MonsterName_134_DarkEye  ; [134]
    dw MonsterName_135_EyeBall  ; [135]
    dw MonsterName_136_SkulRider  ; [136]
    dw MonsterName_137_EvilBeast  ; [137]
    dw MonsterName_138_1EyeClown  ; [138]
    dw MonsterName_139_Gremlin  ; [139]
    dw MonsterName_140_MedusaEye  ; [140]
    dw MonsterName_141_Lionex  ; [141]
    dw MonsterName_142_GoatHorn  ; [142]
    dw MonsterName_143_Orc  ; [143]
    dw MonsterName_144_Ogre  ; [144]
    dw MonsterName_145_GateGuard  ; [145]
    dw MonsterName_146_ChopClown  ; [146]
    dw MonsterName_147_Grendal  ; [147]
    dw MonsterName_148_Akubar  ; [148]
    dw MonsterName_149_MadKnight  ; [149]
    dw MonsterName_150_Gigantes  ; [150]
    dw MonsterName_151_Centasaur  ; [151]
    dw MonsterName_152_EvilArmor  ; [152]
    dw MonsterName_153_Jamirus  ; [153]
    dw MonsterName_154_Durran  ; [154]
    dw MonsterName_155_Spooky  ; [155]
    dw MonsterName_156_Skullgon  ; [156]
    dw MonsterName_157_Putrepup  ; [157]
    dw MonsterName_158_RotRaven  ; [158]
    dw MonsterName_159_Mummy  ; [159]
    dw MonsterName_160_DarkCrab  ; [160]
    dw MonsterName_161_DeadNite  ; [161]
    dw MonsterName_162_Shadow  ; [162]
    dw MonsterName_163_Hork  ; [163]
    dw MonsterName_164_Mudron  ; [164]
    dw MonsterName_165_NiteWhip  ; [165]
    dw MonsterName_166_MadSpirit  ; [166]
    dw MonsterName_167_WindMerge  ; [167]
    dw MonsterName_168_Reaper  ; [168]
    dw MonsterName_169_DeadNoble  ; [169]
    dw MonsterName_170_WhiteKing  ; [170]
    dw MonsterName_171_BoneSlave  ; [171]
    dw MonsterName_172_Skeletor  ; [172]
    dw MonsterName_173_Servant  ; [173]
    dw MonsterName_174_Copycat  ; [174]
    dw MonsterName_175_JewelBag  ; [175]
    dw MonsterName_176_EvilWand  ; [176]
    dw MonsterName_177_MadCandle  ; [177]
    dw MonsterName_178_CoilBird  ; [178]
    dw MonsterName_179_Facer  ; [179]
    dw MonsterName_180_SpikyBoy  ; [180]
    dw MonsterName_181_MadMirror  ; [181]
    dw MonsterName_182_RogueNite  ; [182]
    dw MonsterName_183_Goopi  ; [183]
    dw MonsterName_184_Voodoll  ; [184]
    dw MonsterName_185_MetalDrak  ; [185]
    dw MonsterName_186_Balzak  ; [186]
    dw MonsterName_187_SabreMan  ; [187]
    dw MonsterName_188_CurseLamp  ; [188]
    dw MonsterName_189_Roboster  ; [189]
    dw MonsterName_190_EvilPot  ; [190]
    dw MonsterName_191_Gismo  ; [191]
    dw MonsterName_192_LavaMan  ; [192]
    dw MonsterName_193_IceMan  ; [193]
    dw MonsterName_194_Mimic  ; [194]
    dw MonsterName_195_MudDoll  ; [195]
    dw MonsterName_196_Golem  ; [196]
    dw MonsterName_197_StoneMan  ; [197]
    dw MonsterName_198_BombCrag  ; [198]
    dw MonsterName_199_GoldGolem  ; [199]
    dw MonsterName_200_DracoLord  ; [200]
    dw MonsterName_201_DracoLord  ; [201]
    dw MonsterName_202_Hargon  ; [202]
    dw MonsterName_203_Sidoh  ; [203]
    dw MonsterName_204_Baramos  ; [204]
    dw MonsterName_205_Zoma  ; [205]
    dw MonsterName_206_Pizzaro  ; [206]
    dw MonsterName_207_Esterk  ; [207]
    dw MonsterName_208_Mirudraas  ; [208]
    dw MonsterName_209_Mirudraas  ; [209]
    dw MonsterName_210_Mudou  ; [210]
    dw MonsterName_211_DeathMore  ; [211]
    dw MonsterName_212_DeathMore  ; [212]
    dw MonsterName_213_DeathMore  ; [213]
    dw MonsterName_214_Darkdrium  ; [214]
    dw MonsterName_215_TERRY  ; [215]
    dw MonsterName_216_Tatsu  ; [216]
    dw MonsterName_217_Diago  ; [217]
    dw MonsterName_218_Samsi  ; [218]
    dw MonsterName_219_Bazoo  ; [219]
    dw MonsterName_220_Unused_220  ; [220]
    dw MonsterName_220_Unused_220  ; [221]
    dw MonsterName_220_Unused_220  ; [222]
    dw MonsterName_220_Unused_220  ; [223]
    dw MonsterName_224_Gorbunok  ; [224]
    dw MonsterName_225_Unused_225  ; [225]
    dw MonsterName_225_Unused_225  ; [226]
    dw MonsterName_225_Unused_225  ; [227]
    dw MonsterName_225_Unused_225  ; [228]
    dw MonsterName_225_Unused_225  ; [229]
    dw MonsterName_225_Unused_225  ; [230]
    dw MonsterName_225_Unused_225  ; [231]
    dw MonsterName_225_Unused_225  ; [232]
    dw MonsterName_225_Unused_225  ; [233]
    dw MonsterName_225_Unused_225  ; [234]
    dw MonsterName_225_Unused_225  ; [235]
    dw MonsterName_225_Unused_225  ; [236]
    dw MonsterName_225_Unused_225  ; [237]
    dw MonsterName_225_Unused_225  ; [238]
    dw MonsterName_225_Unused_225  ; [239]
    dw MonsterName_225_Unused_225  ; [240]
    dw MonsterName_225_Unused_225  ; [241]
    dw MonsterName_225_Unused_225  ; [242]
    dw MonsterName_225_Unused_225  ; [243]
    dw MonsterName_225_Unused_225  ; [244]
    dw MonsterName_225_Unused_225  ; [245]
    dw MonsterName_225_Unused_225  ; [246]
    dw MonsterName_225_Unused_225  ; [247]
    dw MonsterName_225_Unused_225  ; [248]
    dw MonsterName_225_Unused_225  ; [249]
    dw MonsterName_225_Unused_225  ; [250]
    dw MonsterName_225_Unused_225  ; [251]
    dw MonsterName_225_Unused_225  ; [252]
    dw MonsterName_225_Unused_225  ; [253]
    dw MonsterName_220_Unused_220  ; [254] reserved library unseen-marker -> blank name
    dw MonsterName_225_Unused_225  ; [255]

SkillNamePtrTable:  ; $4539 — 256 entries, indexed by skill ID
    dw SkillName_000_Blaze  ; [  0]
    dw SkillName_001_Blazemore  ; [  1]
    dw SkillName_002_Blazemost  ; [  2]
    dw SkillName_003_Firebal  ; [  3]
    dw SkillName_004_Firebane  ; [  4]
    dw SkillName_005_Firebolt  ; [  5]
    dw SkillName_006_Bang  ; [  6]
    dw SkillName_007_Boom  ; [  7]
    dw SkillName_008_Explodet  ; [  8]
    dw SkillName_009_Infernos  ; [  9]
    dw SkillName_010_Infermore  ; [ 10]
    dw SkillName_011_Infermost  ; [ 11]
    dw SkillName_012_IceBolt  ; [ 12]
    dw SkillName_013_SnowStorm  ; [ 13]
    dw SkillName_014_Blizzard  ; [ 14]
    dw SkillName_015_Bolt  ; [ 15]
    dw SkillName_016_Zap  ; [ 16]
    dw SkillName_017_Thordain  ; [ 17]
    dw SkillName_018_Beat  ; [ 18]
    dw SkillName_019_Defeat  ; [ 19]
    dw SkillName_020_Sacrifice  ; [ 20]
    dw SkillName_021_Sleep  ; [ 21]
    dw SkillName_022_SleepAll  ; [ 22]
    dw SkillName_023_StopSpell  ; [ 23]
    dw SkillName_024_Surround  ; [ 24]
    dw SkillName_025_PanicAll  ; [ 25]
    dw SkillName_026_RobMagic  ; [ 26]
    dw SkillName_027_TakeMagic  ; [ 27]
    dw SkillName_028_Sap  ; [ 28]
    dw SkillName_029_Defence  ; [ 29]
    dw SkillName_030_Upper  ; [ 30]
    dw SkillName_031_Increase  ; [ 31]
    dw SkillName_032_Slow  ; [ 32]
    dw SkillName_033_SlowAll  ; [ 33]
    dw SkillName_034_Speed  ; [ 34]
    dw SkillName_035_SpeedUp  ; [ 35]
    dw SkillName_036_Barrier  ; [ 36]
    dw SkillName_037_TwinHits  ; [ 37]
    dw SkillName_038_MagicWall  ; [ 38]
    dw SkillName_039_MagicBack  ; [ 39]
    dw SkillName_040_Bounce  ; [ 40]
    dw SkillName_041_Transform  ; [ 41]
    dw SkillName_042_Ironize  ; [ 42]
    dw SkillName_043_Heal  ; [ 43]
    dw SkillName_044_HealMore  ; [ 44]
    dw SkillName_045_HealAll  ; [ 45]
    dw SkillName_046_HealUs  ; [ 46]
    dw SkillName_047_HealUsAll  ; [ 47]
    dw SkillName_048_Vivify  ; [ 48]
    dw SkillName_049_Revive  ; [ 49]
    dw SkillName_050_Farewell  ; [ 50]
    dw SkillName_051_Antidote  ; [ 51]
    dw SkillName_052_NumbOff  ; [ 52]
    dw SkillName_053_DeChaos  ; [ 53]
    dw SkillName_054_CurseOff  ; [ 54]
    dw SkillName_055_StepGuard  ; [ 55]
    dw SkillName_056_MapMagic  ; [ 56]
    dw SkillName_057_Chance  ; [ 57]
    dw SkillName_058_Attack  ; [ 58]
    dw SkillName_059_TwinSlash  ; [ 59]
    dw SkillName_060_Ramming  ; [ 60]
    dw SkillName_061_Beserker  ; [ 61]
    dw SkillName_062_Kamikaze  ; [ 62]
    dw SkillName_063_Massacre  ; [ 63]
    dw SkillName_064_EvilSlash  ; [ 64]
    dw SkillName_065_ChargeUP  ; [ 65]
    dw SkillName_066_HighJump  ; [ 66]
    dw SkillName_067_SuckAir  ; [ 67]
    dw SkillName_068_FireSlash  ; [ 68]
    dw SkillName_069_BoltSlash  ; [ 69]
    dw SkillName_070_VacuSlash  ; [ 70]
    dw SkillName_071_IceSlash  ; [ 71]
    dw SkillName_072_MetalCut  ; [ 72]
    dw SkillName_073_DrakSlash  ; [ 73]
    dw SkillName_074_BeastCut  ; [ 74]
    dw SkillName_075_BirdBlow  ; [ 75]
    dw SkillName_076_DevilCut  ; [ 76]
    dw SkillName_077_ZombieCut  ; [ 77]
    dw SkillName_078_CleanCut  ; [ 78]
    dw SkillName_079_MultiCut  ; [ 79]
    dw SkillName_080_BiAttack  ; [ 80]
    dw SkillName_081_QuadHits  ; [ 81]
    dw SkillName_082_CallHelp  ; [ 82]
    dw SkillName_083_YellHelp  ; [ 83]
    dw SkillName_084_Focus  ; [ 84]
    dw SkillName_085_SquallHit  ; [ 85]
    dw SkillName_086_PsycheUp  ; [ 86]
    dw SkillName_087_RainSlash  ; [ 87]
    dw SkillName_088_WindBeast  ; [ 88]
    dw SkillName_089_Vacuum  ; [ 89]
    dw SkillName_090_Lightning  ; [ 90]
    dw SkillName_091_RockThrow  ; [ 91]
    dw SkillName_092_FireAir  ; [ 92]
    dw SkillName_093_BlazeAir  ; [ 93]
    dw SkillName_094_Scorching  ; [ 94]
    dw SkillName_095_WhiteFire  ; [ 95]
    dw SkillName_096_FrigidAir  ; [ 96]
    dw SkillName_097_IceAir  ; [ 97]
    dw SkillName_098_IceStorm  ; [ 98]
    dw SkillName_099_WhiteAir  ; [ 99]
    dw SkillName_100_Hellblast  ; [100]
    dw SkillName_101_BigBang  ; [101]
    dw SkillName_102_MegaMagic  ; [102]
    dw SkillName_103_PoisonHit  ; [103]
    dw SkillName_104_NapAttack  ; [104]
    dw SkillName_105_Paralyze  ; [105]
    dw SkillName_106_SleepAir  ; [106]
    dw SkillName_107_PalsyAir  ; [107]
    dw SkillName_108_PoisonGas  ; [108]
    dw SkillName_109_PoisonAir  ; [109]
    dw SkillName_110_PaniDance  ; [110]
    dw SkillName_111_Curse  ; [111]
    dw SkillName_112_Ahhh  ; [112]
    dw SkillName_113_KODance  ; [113]
    dw SkillName_114_SandStorm  ; [114]
    dw SkillName_115_Radiant  ; [115]
    dw SkillName_116_EerieLite  ; [116]
    dw SkillName_117_OddDance  ; [117]
    dw SkillName_118_RobDance  ; [118]
    dw SkillName_119_SideStep  ; [119]
    dw SkillName_120_LureDance  ; [120]
    dw SkillName_121_LushLicks  ; [121]
    dw SkillName_122_SickLick  ; [122]
    dw SkillName_123_LegSweep  ; [123]
    dw SkillName_124_BigTrip  ; [124]
    dw SkillName_125_WarCry  ; [125]
    dw SkillName_126_Whistle  ; [126]
    dw SkillName_127_Imitate  ; [127]
    dw SkillName_128_DeMagic  ; [128]
    dw SkillName_129_Surge  ; [129]
    dw SkillName_130_UltraDown  ; [130]
    dw SkillName_131_ThickFog  ; [131]
    dw SkillName_132_TatsuCall  ; [132]
    dw SkillName_133_DiagoCall  ; [133]
    dw SkillName_134_SamsiCall  ; [134]
    dw SkillName_135_BazooCall  ; [135]
    dw SkillName_136_Cover  ; [136]
    dw SkillName_137_Guardian  ; [137]
    dw SkillName_138_TailWind  ; [138]
    dw SkillName_139_StormWind  ; [139]
    dw SkillName_140_Dodge  ; [140]
    dw SkillName_141_Defence  ; [141]
    dw SkillName_142_StrongD  ; [142]
    dw SkillName_143_SuckAll  ; [143]
    dw SkillName_144_BladeD  ; [144]
    dw SkillName_145_DanceShut  ; [145]
    dw SkillName_146_MouthShut  ; [146]
    dw SkillName_147_Meditate  ; [147]
    dw SkillName_148_Hustle  ; [148]
    dw SkillName_149_LifeSong  ; [149]
    dw SkillName_150_LifeDance  ; [150]
    dw SkillName_151_Run  ; [151]
    dw SkillName_152_Daze  ; [152]
    dw SkillName_153_HitAlly  ; [153]
    dw SkillName_154_HitEnemy  ; [154]
    dw SkillName_155_HitRandom  ; [155]
    dw SkillName_156_Scared  ; [156]
    dw SkillName_157_Dance  ; [157]
    dw SkillName_158_Trip  ; [158]
    dw SkillName_159_Paralyze  ; [159]
    dw SkillName_160_CANTMOVE  ; [160]
    dw SkillName_161_RUN  ; [161]
    dw SkillName_162_CALLHOROR  ; [162]
    dw SkillName_163_HealUsAll  ; [163]
    dw SkillName_164_Smashed  ; [164]
    dw SkillName_165_FILTHZONE  ; [165]
    dw SkillName_166_ALLCHANGE  ; [166]
    dw SkillName_167_BIGSLEEP  ; [167]
    dw SkillName_168_MP0  ; [168]
    dw SkillName_169_ECHO  ; [169]
    dw SkillName_170_CHGDRAGON  ; [170]
    dw SkillName_171_CALLEVIL  ; [171]
    dw SkillName_172_FREEZY  ; [172]
    dw SkillName_173_ALLREVIVE  ; [173]
    dw SkillName_174_RESTOREMP  ; [174]
    dw SkillName_175_METEOR  ; [175]
    dw SkillName_176_HERB  ; [176]
    dw SkillName_177_HEALWATER  ; [177]
    dw SkillName_178_SAGESTONE  ; [178]
    dw SkillName_179_WARLDDEW  ; [179]
    dw SkillName_180_POTION  ; [180]
    dw SkillName_181_ELFWATER  ; [181]
    dw SkillName_182_ANTIDOTE  ; [182]
    dw SkillName_183_MOONHERB  ; [183]
    dw SkillName_184_SKYBELL  ; [184]
    dw SkillName_185_LAUREL  ; [185]
    dw SkillName_186_AWAKESAND  ; [186]
    dw SkillName_187_WARLDLEAF  ; [187]
    dw SkillName_188_LIFEACORN  ; [188]
    dw SkillName_189_MYSTICNUT  ; [189]
    dw SkillName_190_PWRSEED  ; [190]
    dw SkillName_191_DEFSEED  ; [191]
    dw SkillName_192_AGILSEED  ; [192]
    dw SkillName_193_INTSEED  ; [193]
    dw SkillName_194_FEEDMEAT  ; [194]
    dw SkillName_195_BEFFJERKY  ; [195]
    dw SkillName_196_PORKCHOP  ; [196]
    dw SkillName_197_BADMEAT  ; [197]
    dw SkillName_198_SIRLOIN  ; [198]
    dw SkillName_199_BOLTSTAFF  ; [199]
    dw SkillName_200_STAFF  ; [200]
    dw SkillName_201_BLOKSTAFF  ; [201]
    dw SkillName_202_LAVASTAFF  ; [202]
    dw SkillName_203_SNOWSTAFF  ; [203]
    dw SkillName_204_FIRESTAFF  ; [204]
    dw SkillName_205_WARPWING  ; [205]
    dw SkillName_206_TINYMEDAL  ; [206]
    dw SkillName_207_QuestBk  ; [207]
    dw SkillName_208_HORRORBK  ; [208]
    dw SkillName_209_BENICEBK  ; [209]
    dw SkillName_210_CHEATERBK  ; [210]
    dw SkillName_211_SMARTBK  ; [211]
    dw SkillName_212_COMEDYBK  ; [212]
    dw SkillName_213_BeDragon  ; [213]
    dw SkillName_214_Smashlime  ; [214]
    dw SkillName_215_BugCut  ; [215] renamed from "Sheldodge" (= Bug-family cut)
    dw SkillName_216_Branching  ; [216]
    dw SkillName_217_GigaSlash  ; [217]
    dw SkillName_218_LIFE  ; [218]
    dw SkillName_219_RUN  ; [219]
    dw SkillName_220_IRONIZE  ; [220]
    dw SkillName_221_Ahhh  ; [221]
    dw SkillName_222_Scorch  ; [222]
    dw SkillName_223_Smite  ; [223]
    dw SkillName_222_Unused_222  ; [224]
    dw SkillName_222_Unused_222  ; [225]
    dw SkillName_222_Unused_222  ; [226]
    dw SkillName_222_Unused_222  ; [227]
    dw SkillName_222_Unused_222  ; [228]
    dw SkillName_222_Unused_222  ; [229]
    dw SkillName_222_Unused_222  ; [230]
    dw SkillName_222_Unused_222  ; [231]
    dw SkillName_222_Unused_222  ; [232]
    dw SkillName_222_Unused_222  ; [233]
    dw SkillName_222_Unused_222  ; [234]
    dw SkillName_222_Unused_222  ; [235]
    dw SkillName_222_Unused_222  ; [236]
    dw SkillName_222_Unused_222  ; [237]
    dw SkillName_222_Unused_222  ; [238]
    dw SkillName_222_Unused_222  ; [239]
    dw SkillName_222_Unused_222  ; [240]
    dw SkillName_222_Unused_222  ; [241]
    dw SkillName_222_Unused_222  ; [242]
    dw SkillName_222_Unused_222  ; [243]
    dw SkillName_222_Unused_222  ; [244]
    dw SkillName_222_Unused_222  ; [245]
    dw SkillName_222_Unused_222  ; [246]
    dw SkillName_222_Unused_222  ; [247]
    dw SkillName_222_Unused_222  ; [248]
    dw SkillName_222_Unused_222  ; [249]
    dw SkillName_222_Unused_222  ; [250]
    dw SkillName_222_Unused_222  ; [251]
    dw SkillName_222_Unused_222  ; [252]
    dw SkillName_222_Unused_222  ; [253]
    dw SkillName_222_Unused_222  ; [254]
    dw SkillName_222_Unused_222  ; [255]


; ---------------------------------------------------------------
; Family Code Pointer Table ($4739)
; 215 entries x 2 bytes = 430 bytes
; 2-letter family abbreviation per monster ID (0-214)
; ---------------------------------------------------------------

FamilyCodePtrTable:  ; $4739
    dw FamilyCode_000_DS  ; [0] DS
    dw FamilyCode_001_SP  ; [1] SP
    dw FamilyCode_002_WS  ; [2] WS
    dw FamilyCode_003_TS  ; [3] TS
    dw FamilyCode_004_SN  ; [4] SN
    dw FamilyCode_005_KN  ; [5] KN
    dw FamilyCode_006_BB  ; [6] BB
    dw FamilyCode_007_BX  ; [7] BX
    dw FamilyCode_008_SL  ; [8] SL
    dw FamilyCode_009_HL  ; [9] HL
    dw FamilyCode_010_FS  ; [10] FS
    dw FamilyCode_011_RS  ; [11] RS
    dw FamilyCode_012_SB  ; [12] SB
    dw FamilyCode_013_ST  ; [13] ST
    dw FamilyCode_014_SK  ; [14] SK
    dw FamilyCode_015_KS  ; [15] KS
    dw FamilyCode_016_MK  ; [16] MK
    dw FamilyCode_017_MB  ; [17] MB
    dw FamilyCode_018_MT  ; [18] MT
    dw FamilyCode_019_GS  ; [19] GS
    dw FamilyCode_020_DK  ; [20] DK
    dw FamilyCode_021_TG  ; [21] TG
    dw FamilyCode_022_PT  ; [22] PT
    dw FamilyCode_023_BG  ; [23] BG
    dw FamilyCode_024_BD  ; [24] BD
    dw FamilyCode_025_LM  ; [25] LM
    dw FamilyCode_026_PG  ; [26] PG
    dw FamilyCode_027_SD  ; [27] SD
    dw FamilyCode_028_DR  ; [28] DR
    dw FamilyCode_029_MD  ; [29] MD
    dw FamilyCode_030_DK  ; [30] DK
    dw FamilyCode_031_RB  ; [31] RB
    dw FamilyCode_032_CH  ; [32] CH
    dw FamilyCode_033_LF  ; [33] LF
    dw FamilyCode_034_AD  ; [34] AD
    dw FamilyCode_035_LC  ; [35] LC
    dw FamilyCode_036_SS  ; [36] SS
    dw FamilyCode_037_GD  ; [37] GD
    dw FamilyCode_038_CP  ; [38] CP
    dw FamilyCode_039_WS  ; [39] WS
    dw FamilyCode_040_CT  ; [40] CT
    dw FamilyCode_041_OR  ; [41] OR
    dw FamilyCode_042_BR  ; [42] BR
    dw FamilyCode_043_SD  ; [43] SD
    dw FamilyCode_044_DG  ; [44] DG
    dw FamilyCode_045_TG  ; [45] TG
    dw FamilyCode_046_HB  ; [46] HB
    dw FamilyCode_047_CF  ; [47] CF
    dw FamilyCode_048_PR  ; [48] PR
    dw FamilyCode_049_SC  ; [49] SC
    dw FamilyCode_050_GB  ; [50] GB
    dw FamilyCode_051_SL  ; [51] SL
    dw FamilyCode_052_WB  ; [52] WB
    dw FamilyCode_053_AE  ; [53] AE
    dw FamilyCode_054_ST  ; [54] ST
    dw FamilyCode_055_IT  ; [55] IT
    dw FamilyCode_056_MM  ; [56] MM
    dw FamilyCode_057_HM  ; [57] HM
    dw FamilyCode_058_GZ  ; [58] GZ
    dw FamilyCode_059_YT  ; [59] YT
    dw FamilyCode_060_MG  ; [60] MG
    dw FamilyCode_061_FR  ; [61] FR
    dw FamilyCode_062_UC  ; [62] UC
    dw FamilyCode_063_GG  ; [63] GG
    dw FamilyCode_064_KA  ; [64] KA
    dw FamilyCode_065_TP  ; [65] TP
    dw FamilyCode_066_KL  ; [66] KL
    dw FamilyCode_067_DH  ; [67] DH
    dw FamilyCode_068_MC  ; [68] MC
    dw FamilyCode_069_BE  ; [69] BE
    dw FamilyCode_070_PK  ; [70] PK
    dw FamilyCode_071_WV  ; [71] WV
    dw FamilyCode_072_BB  ; [72] BB
    dw FamilyCode_073_FJ  ; [73] FJ
    dw FamilyCode_074_DK  ; [74] DK
    dw FamilyCode_075_MP  ; [75] MP
    dw FamilyCode_076_MR  ; [76] MR
    dw FamilyCode_077_MW  ; [77] MW
    dw FamilyCode_078_DK  ; [78] DK
    dw FamilyCode_079_BR  ; [79] BR
    dw FamilyCode_080_SB  ; [80] SB
    dw FamilyCode_081_LO  ; [81] LO
    dw FamilyCode_082_MG  ; [82] MG
    dw FamilyCode_083_MC  ; [83] MC
    dw FamilyCode_084_BZ  ; [84] BZ
    dw FamilyCode_085_PN  ; [85] PN
    dw FamilyCode_086_TH  ; [86] TH
    dw FamilyCode_087_WH  ; [87] WH
    dw FamilyCode_088_FB  ; [88] FB
    dw FamilyCode_089_RB  ; [89] RB
    dw FamilyCode_090_MP  ; [90] MP
    dw FamilyCode_091_FW  ; [91] FW
    dw FamilyCode_092_FM  ; [92] FM
    dw FamilyCode_093_WT  ; [93] WT
    dw FamilyCode_094_CB  ; [94] CB
    dw FamilyCode_095_GP  ; [95] GP
    dw FamilyCode_096_FG  ; [96] FG
    dw FamilyCode_097_AW  ; [97] AW
    dw FamilyCode_098_SS  ; [98] SS
    dw FamilyCode_099_ON  ; [99] ON
    dw FamilyCode_100_DV  ; [100] DV
    dw FamilyCode_101_TB  ; [101] TB
    dw FamilyCode_102_FT  ; [102] FT
    dw FamilyCode_103_HM  ; [103] HM
    dw FamilyCode_104_BM  ; [104] BM
    dw FamilyCode_105_ES  ; [105] ES
    dw FamilyCode_106_ME  ; [106] ME
    dw FamilyCode_107_SP  ; [107] SP
    dw FamilyCode_108_OV  ; [108] OV
    dw FamilyCode_109_WT  ; [109] WT
    dw FamilyCode_110_GS  ; [110] GS
    dw FamilyCode_111_CP  ; [111] CP
    dw FamilyCode_112_GC  ; [112] GC
    dw FamilyCode_113_BF  ; [113] BF
    dw FamilyCode_114_WB  ; [114] WB
    dw FamilyCode_115_GW  ; [115] GW
    dw FamilyCode_116_LP  ; [116] LP
    dw FamilyCode_117_SB  ; [117] SB
    dw FamilyCode_118_AA  ; [118] AA
    dw FamilyCode_119_GH  ; [119] GH
    dw FamilyCode_120_TE  ; [120] TE
    dw FamilyCode_121_AP  ; [121] AP
    dw FamilyCode_122_ED  ; [122] ED
    dw FamilyCode_123_GM  ; [123] GM
    dw FamilyCode_124_DR  ; [124] DR
    dw FamilyCode_125_AC  ; [125] AC
    dw FamilyCode_126_MH  ; [126] MH
    dw FamilyCode_127_HB  ; [127] HB
    dw FamilyCode_128_AP  ; [128] AP
    dw FamilyCode_129_DG  ; [129] DG
    dw FamilyCode_130_PX  ; [130] PX
    dw FamilyCode_131_AD  ; [131] AD
    dw FamilyCode_132_AD  ; [132] AD
    dw FamilyCode_133_DM  ; [133] DM
    dw FamilyCode_134_DE  ; [134] DE
    dw FamilyCode_135_EB  ; [135] EB
    dw FamilyCode_136_BR  ; [136] BR
    dw FamilyCode_137_EB  ; [137] EB
    dw FamilyCode_138_1E  ; [138] 1E
    dw FamilyCode_139_GR  ; [139] GR
    dw FamilyCode_140_MD  ; [140] MD
    dw FamilyCode_141_LX  ; [141] LX
    dw FamilyCode_142_GH  ; [142] GH
    dw FamilyCode_143_OC  ; [143] OC
    dw FamilyCode_144_OG  ; [144] OG
    dw FamilyCode_145_GG  ; [145] GG
    dw FamilyCode_146_CC  ; [146] CC
    dw FamilyCode_147_GR  ; [147] GR
    dw FamilyCode_148_AK  ; [148] AK
    dw FamilyCode_149_MK  ; [149] MK
    dw FamilyCode_150_GG  ; [150] GG
    dw FamilyCode_151_CS  ; [151] CS
    dw FamilyCode_152_EA  ; [152] EA
    dw FamilyCode_153_JA  ; [153] JA
    dw FamilyCode_154_DR  ; [154] DR
    dw FamilyCode_155_SP  ; [155] SP
    dw FamilyCode_156_SK  ; [156] SK
    dw FamilyCode_157_DZ  ; [157] DZ
    dw FamilyCode_158_RR  ; [158] RR
    dw FamilyCode_159_MM  ; [159] MM
    dw FamilyCode_160_DC  ; [160] DC
    dw FamilyCode_161_DN  ; [161] DN
    dw FamilyCode_162_SH  ; [162] SH
    dw FamilyCode_163_PT  ; [163] PT
    dw FamilyCode_164_MD  ; [164] MD
    dw FamilyCode_165_NW  ; [165] NW
    dw FamilyCode_166_ES  ; [166] ES
    dw FamilyCode_167_WM  ; [167] WM
    dw FamilyCode_168_ST  ; [168] ST
    dw FamilyCode_169_DN  ; [169] DN
    dw FamilyCode_170_IK  ; [170] IK
    dw FamilyCode_171_BS  ; [171] BS
    dw FamilyCode_172_SK  ; [172] SK
    dw FamilyCode_173_SV  ; [173] SV
    dw FamilyCode_174_CC  ; [174] CC
    dw FamilyCode_175_JB  ; [175] JB
    dw FamilyCode_176_EW  ; [176] EW
    dw FamilyCode_177_MC  ; [177] MC
    dw FamilyCode_178_CB  ; [178] CB
    dw FamilyCode_179_MK  ; [179] MK
    dw FamilyCode_180_SB  ; [180] SB
    dw FamilyCode_181_MM  ; [181] MM
    dw FamilyCode_182_RA  ; [182] RA
    dw FamilyCode_183_MH  ; [183] MH
    dw FamilyCode_184_VD  ; [184] VD
    dw FamilyCode_185_DM  ; [185] DM
    dw FamilyCode_186_BZ  ; [186] BZ
    dw FamilyCode_187_SM  ; [187] SM
    dw FamilyCode_188_CL  ; [188] CL
    dw FamilyCode_189_KB  ; [189] KB
    dw FamilyCode_190_EP  ; [190] EP
    dw FamilyCode_191_GZ  ; [191] GZ
    dw FamilyCode_192_LM  ; [192] LM
    dw FamilyCode_193_IC  ; [193] IC
    dw FamilyCode_194_MM  ; [194] MM
    dw FamilyCode_195_MD  ; [195] MD
    dw FamilyCode_196_GL  ; [196] GL
    dw FamilyCode_197_MS  ; [197] MS
    dw FamilyCode_198_BC  ; [198] BC
    dw FamilyCode_199_GG  ; [199] GG
    dw FamilyCode_200_DL  ; [200] DL
    dw FamilyCode_201_DL  ; [201] DL
    dw FamilyCode_202_HG  ; [202] HG
    dw FamilyCode_203_SD  ; [203] SD
    dw FamilyCode_204_BM  ; [204] BM
    dw FamilyCode_205_ZM  ; [205] ZM
    dw FamilyCode_206_PZ  ; [206] PZ
    dw FamilyCode_207_ES  ; [207] ES
    dw FamilyCode_208_MD  ; [208] MD
    dw FamilyCode_209_MD  ; [209] MD
    dw FamilyCode_210_MD  ; [210] MD
    dw FamilyCode_211_DM  ; [211] DM
    dw FamilyCode_212_DM  ; [212] DM
    dw FamilyCode_213_DM  ; [213] DM
    dw FamilyCode_214_DD  ; [214] DD

; ---------------------------------------------------------------
; Item Name Pointer Table ($48E7)
; 44 entries x 2 bytes = 88 bytes
; Index 0 = no item (empty), 1-43 = item names
; ---------------------------------------------------------------

ItemNamePtrTable:  ; $48E7
    dw ItemName_00_Empty  ; [0] 
    dw ItemName_01_Herb  ; [1] Herb
    dw ItemName_02_Lovewater  ; [2] Lovewater
    dw ItemName_03_SageStone  ; [3] SageStone
    dw ItemName_04_WorldDew  ; [4] WorldDew
    dw ItemName_05_Potion  ; [5] Potion
    dw ItemName_06_ElfWater  ; [6] ElfWater
    dw ItemName_07_Antidote  ; [7] Antidote
    dw ItemName_08_MoonHerb  ; [8] MoonHerb
    dw ItemName_09_SkyBell  ; [9] SkyBell
    dw ItemName_10_Laurel  ; [10] Laurel
    dw ItemName_11_AwakeSand  ; [11] AwakeSand
    dw ItemName_12_WorldLeaf  ; [12] WorldLeaf
    dw ItemName_13_LifeAcorn  ; [13] LifeAcorn
    dw ItemName_14_MysticNut  ; [14] MysticNut
    dw ItemName_15_ATKseed  ; [15] ATKseed
    dw ItemName_16_DEFseed  ; [16] DEFseed
    dw ItemName_17_AGLseed  ; [17] AGLseed
    dw ItemName_18_INTseed  ; [18] INTseed
    dw ItemName_19_BeefJerky  ; [19] BeefJerky
    dw ItemName_20_PorkChop  ; [20] PorkChop
    dw ItemName_21_Rib  ; [21] Rib
    dw ItemName_22_BadMeat  ; [22] BadMeat
    dw ItemName_23_Sirloin  ; [23] Sirloin
    dw ItemName_24_BoltStaff  ; [24] BoltStaff
    dw ItemName_25_WindStaff  ; [25] WindStaff
    dw ItemName_26_MistStaff  ; [26] MistStaff
    dw ItemName_27_LavaStaff  ; [27] LavaStaff
    dw ItemName_28_SnowStaff  ; [28] SnowStaff
    dw ItemName_29_WarpWing  ; [29] WarpWing
    dw ItemName_30_TinyMedal  ; [30] TinyMedal
    dw ItemName_31_QuestBk  ; [31] QuestBk
    dw ItemName_32_HorrorBK  ; [32] HorrorBK
    dw ItemName_33_BeNiceBK  ; [33] BeNiceBK
    dw ItemName_34_CheaterBK  ; [34] CheaterBK
    dw ItemName_35_SmartBK  ; [35] SmartBK
    dw ItemName_36_ComedyBK  ; [36] ComedyBK
    dw ItemName_37_FireStaff  ; [37] FireStaff
    dw ItemName_38_BeastTail  ; [38] BeastTail
    dw ItemName_39_WarpStaff  ; [39] WarpStaff
    dw ItemName_40_Repellent  ; [40] Repellent
    dw ItemName_41_ShinyHarp  ; [41] ShinyHarp
    dw ItemName_42_MapHerb  ; [42] MapHerb
    dw ItemName_43_BookMark  ; [43] BookMark

; ---------------------------------------------------------------
; Item Description Pointer Table ($493F)
; 44 entries x 2 bytes = 88 bytes
; Text descriptions for items, with control codes
; ---------------------------------------------------------------

ItemDescPtrTable:  ; $493F
    dw ItemDesc_00  ; [0] empty
    dw ItemDesc_01  ; [1] Herb
    dw ItemDesc_02  ; [2] Lovewater
    dw ItemDesc_03  ; [3] SageStone
    dw ItemDesc_04  ; [4] WorldDew
    dw ItemDesc_05  ; [5] Potion
    dw ItemDesc_06  ; [6] ElfWater
    dw ItemDesc_07  ; [7] Antidote
    dw ItemDesc_08  ; [8] MoonHerb
    dw ItemDesc_09  ; [9] SkyBell
    dw ItemDesc_10  ; [10] Laurel
    dw ItemDesc_11  ; [11] AwakeSand
    dw ItemDesc_12  ; [12] WorldLeaf
    dw ItemDesc_13  ; [13] LifeAcorn
    dw ItemDesc_14  ; [14] MysticNut
    dw ItemDesc_15  ; [15] ATKseed
    dw ItemDesc_16  ; [16] DEFseed
    dw ItemDesc_17  ; [17] AGLseed
    dw ItemDesc_18  ; [18] INTseed
    dw ItemDesc_19  ; [19] BeefJerky
    dw ItemDesc_19  ; [20] PorkChop
    dw ItemDesc_19  ; [21] Rib
    dw ItemDesc_19  ; [22] BadMeat
    dw ItemDesc_19  ; [23] Sirloin
    dw ItemDesc_24  ; [24] BoltStaff
    dw ItemDesc_25  ; [25] WindStaff
    dw ItemDesc_26  ; [26] MistStaff
    dw ItemDesc_27  ; [27] LavaStaff
    dw ItemDesc_28  ; [28] SnowStaff
    dw ItemDesc_29  ; [29] WarpWing
    dw ItemDesc_30  ; [30] TinyMedal
    dw ItemDesc_31  ; [31] QuestBk
    dw ItemDesc_31  ; [32] HorrorBK
    dw ItemDesc_31  ; [33] BeNiceBK
    dw ItemDesc_31  ; [34] CheaterBK
    dw ItemDesc_31  ; [35] SmartBK
    dw ItemDesc_31  ; [36] ComedyBK
    dw ItemDesc_37  ; [37] FireStaff
    dw ItemDesc_38  ; [38] BeastTail
    dw ItemDesc_39  ; [39] WarpStaff
    dw ItemDesc_40  ; [40] Repellent
    dw ItemDesc_41  ; [41] ShinyHarp
    dw ItemDesc_42  ; [42] MapHerb
    dw ItemDesc_43  ; [43] BookMark

; ---------------------------------------------------------------
; Personality Name Pointer Table ($4997)
; 27 entries x 2 bytes = 54 bytes
; ---------------------------------------------------------------

PersonalityNamePtrTable:  ; $4997
    dw PersonalityName_00_HOTBLOOD  ; [0]
    dw PersonalityName_01_DARING  ; [1]
    dw PersonalityName_02_DAREDEVIL  ; [2]
    dw PersonalityName_03_LONE_WOLF  ; [3]
    dw PersonalityName_04_VAIN  ; [4]
    dw PersonalityName_05_EZ_GOING  ; [5]
    dw PersonalityName_06_SMUG  ; [6]
    dw PersonalityName_07_SNOBBY  ; [7]
    dw PersonalityName_08_RECKLESS  ; [8]
    dw PersonalityName_09_COOL_CALM  ; [9]
    dw PersonalityName_10_WHIMSY  ; [10]
    dw PersonalityName_11_NOSY  ; [11]
    dw PersonalityName_12_WHIZ_KID  ; [12]
    dw PersonalityName_13_ORDINARY  ; [13]
    dw PersonalityName_14_HASTY  ; [14]
    dw PersonalityName_15_STUBBORN  ; [15]
    dw PersonalityName_16_REBEL  ; [16]
    dw PersonalityName_17_SPOILED  ; [17]
    dw PersonalityName_18_HUMANE  ; [18]
    dw PersonalityName_19_UNCERTAIN  ; [19]
    dw PersonalityName_20_CARELESS  ; [20]
    dw PersonalityName_21_SHREWED  ; [21]
    dw PersonalityName_22_CAREFREE  ; [22]
    dw PersonalityName_23_GULLIBLE  ; [23]
    dw PersonalityName_24_SLY  ; [24]
    dw PersonalityName_25_COWARD  ; [25]
    dw PersonalityName_26_LAZY  ; [26]

; ---------------------------------------------------------------
; Misc Text Pointer Table ($49CD)
; 37 entries — battle tactics, level up messages, skill learning
; ---------------------------------------------------------------

MiscTextPtrTable:  ; $49CD
    dw MiscText_00  ; [0]
    dw MiscText_01  ; [1]
    dw MiscText_02  ; [2]
    dw MiscText_03  ; [3]
    dw MiscText_04  ; [4]
    dw MiscText_05  ; [5]
    dw MiscText_06  ; [6]
    dw MiscText_07  ; [7]
    dw MiscText_08  ; [8]
    dw MiscText_09  ; [9]
    dw MiscText_10  ; [10]
    dw MiscText_11  ; [11]
    dw MiscText_12  ; [12]
    dw MiscText_13  ; [13]
    dw MiscText_13  ; [14]
    dw MiscText_15  ; [15]
    dw MiscText_16  ; [16]
    dw MiscText_17  ; [17]
    dw MiscText_18  ; [18]
    dw MiscText_19  ; [19]
    dw MiscText_20  ; [20]
    dw MiscText_21  ; [21]
    dw MiscText_22  ; [22]
    dw MiscText_23  ; [23]
    dw MiscText_24  ; [24]
    dw MiscText_25  ; [25]
    dw MiscText_26  ; [26]
    dw MiscText_27  ; [27]
    dw MiscText_28  ; [28]
    dw MiscText_29  ; [29]
    dw MiscText_30  ; [30]
    dw MiscText_31  ; [31]
    dw MiscText_32  ; [32]
    dw MiscText_33  ; [33]
    dw MiscText_34  ; [34]
    dw MiscText_35  ; [35]
    dw MiscText_36  ; [36]

; ---------------------------------------------------------------
; Watabou Text Pointer Table ($4A17)
; 2 entries
; ---------------------------------------------------------------

WatabouTextPtrTable:  ; $4A17
    dw WatabouText_00  ; [0]
    dw WatabouText_00  ; [1]

; ---------------------------------------------------------------
; Item Use Text Pointer Table ($4A1B)
; 48 entries — messages when using items in battle/field
; ---------------------------------------------------------------

ItemUseTextPtrTable:  ; $4A1B
    dw ItemUseText_00  ; [0]
    dw ItemUseText_01  ; [1]
    dw ItemUseText_02  ; [2]
    dw ItemUseText_03  ; [3]
    dw ItemUseText_04  ; [4]
    dw ItemUseText_05  ; [5]
    dw ItemUseText_06  ; [6]
    dw ItemUseText_07  ; [7]
    dw ItemUseText_08  ; [8]
    dw ItemUseText_09  ; [9]
    dw ItemUseText_10  ; [10]
    dw ItemUseText_11  ; [11]
    dw ItemUseText_12  ; [12]
    dw ItemUseText_13  ; [13]
    dw ItemUseText_14  ; [14]
    dw ItemUseText_15  ; [15]
    dw ItemUseText_16  ; [16]
    dw ItemUseText_17  ; [17]
    dw ItemUseText_18  ; [18]
    dw ItemUseText_19  ; [19]
    dw ItemUseText_20  ; [20]
    dw ItemUseText_21  ; [21]
    dw ItemUseText_22  ; [22]
    dw ItemUseText_23  ; [23]
    dw ItemUseText_24  ; [24]
    dw ItemUseText_25  ; [25]
    dw ItemUseText_26  ; [26]
    dw ItemUseText_27  ; [27]
    dw ItemUseText_28  ; [28]
    dw ItemUseText_29  ; [29]
    dw ItemUseText_30  ; [30]
    dw ItemUseText_31  ; [31]
    dw ItemUseText_32  ; [32]
    dw ItemUseText_33  ; [33]
    dw ItemUseText_34  ; [34]
    dw ItemUseText_35  ; [35]
    dw ItemUseText_36  ; [36]
    dw ItemUseText_37  ; [37]
    dw ItemUseText_38  ; [38]
    dw ItemUseText_39  ; [39]
    dw ItemUseText_40  ; [40]
    dw ItemUseText_41  ; [41]
    dw ItemUseText_42  ; [42]
    dw ItemUseText_43  ; [43]
    dw ItemUseText_44  ; [44]
    dw ItemUseText_45  ; [45]
    dw ItemUseText_46  ; [46]
    dw ItemUseText_47  ; [47]

; ---------------------------------------------------------------
; Spell Use Text Pointer Table ($4A7B)
; 12 entries — messages when casting spells
; ---------------------------------------------------------------

SpellUseTextPtrTable:  ; $4A7B
    dw SpellUseText_00  ; [0]
    dw SpellUseText_01  ; [1]
    dw SpellUseText_02  ; [2]
    dw SpellUseText_03  ; [3]
    dw SpellUseText_04  ; [4]
    dw SpellUseText_05  ; [5]
    dw SpellUseText_06  ; [6]
    dw SpellUseText_07  ; [7]
    dw SpellUseText_08  ; [8]
    dw SpellUseText_09  ; [9]
    dw SpellUseText_10  ; [10]
    dw SpellUseText_11  ; [11]

; ---------------------------------------------------------------
; Code functions ($4A93-$4AA7)
; 3 small helper functions, 7 bytes each
; ---------------------------------------------------------------

Func_Bank41_GetText:  ; $4A93
    ld de, $4007
    call $05B6
    ret

Func_Bank41_PutText:  ; $4A9A
    ld de, $4007
    call $05F6
    ret

Func_Bank41_GetPutText:  ; $4AA1
    call Func_Bank41_GetText
    call $0609
    ret

; ---------------------------------------------------------------
; Dispatch Text Strings ($4AA8-$5B1E)
; Various game text referenced by dispatch table at $4001
; Contains control codes: $F1=newline, $F2=continue,
; $F7=end, $F9=param, $FA=wait, $ED=prefix, etc.
; ---------------------------------------------------------------

DispatchText_18:
    db $96, $62, $27, $28, $25, $38, $2A, $62, $30, $32, $27, $28, $F1, $62, $62, $62  ; $4AA8
    db $62, $36, $28, $2F, $28, $26, $37, $62, $62, $62, $97, $F1, $62, $01, $A3, $2A  ; $4AB8
    db $32, $37, $32, $62, $33, $35, $32, $2A, $35, $24, $30, $62, $62, $02, $A3, $30  ; $4AC8
    db $32, $31, $36, $37, $28, $35, $62, $62, $62, $62, $62, $62, $62, $03, $A3, $2A  ; $4AD8
    db $24, $30, $28, $62, $28, $27, $2C, $37, $62, $62, $62, $62, $62, $04, $A3, $36  ; $4AE8
    db $32, $38, $31, $27, $62, $37, $28, $36, $37, $62, $62, $62, $62, $05, $A3, $25  ; $4AF8
    db $24, $37, $37, $2F, $28, $62, $28, $27, $2C, $37, $62, $62, $62, $62, $9C, $62  ; $4B08
    db $62, $35, $28, $37, $38, $35, $31, $62, $62, $9C, $62, $62, $F0  ; $4B18
DispatchText_22:
    db $62, $62, $9C, $62, $28, $27, $2C, $37, $62, $9C, $F1, $F1, $30, $24, $33, $37  ; $4B25
    db $3C, $33, $28, $F1, $29, $2F, $32, $32, $35, $62, $62, $F1, $24, $2F, $2F, $3C  ; $4B35
    db $62, $62, $62, $F1, $30, $32, $31, $36, $37, $35, $01, $F1, $30, $32, $31, $36  ; $4B45
    db $37, $35, $02, $F1, $30, $32, $31, $36, $37, $35, $03, $F1, $62, $27, $38, $30  ; $4B55
    db $30, $3C, $62, $F1, $62, $27, $28, $25, $38, $2A, $62, $F0  ; $4B65
DispatchText_23:
    db $62, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $24, $25, $26, $27, $28  ; $4B71
    db $29, $F0  ; $4B81
DispatchText_24:
    db $62, $62, $9C, $62, $36, $32, $38, $31, $27, $62, $9C, $F1, $F1, $62, $62, $25  ; $4B83
    db $2A, $30, $F1, $62, $62, $36, $28, $F0  ; $4B93
DispatchText_25:
    db $9C, $62, $2A, $32, $37, $32, $33, $35, $2A, $62, $9C, $F1, $F1, $F1, $62, $33  ; $4B9B
    db $35, $2A, $31, $32, $01, $F1, $62, $33, $35, $2A, $31, $32, $02, $F1, $62, $33  ; $4BAB
    db $35, $2A, $31, $32, $03, $F0  ; $4BBB
DispatchText_26:
    db $37, $2C, $37, $2F, $28, $62, $9D, $01, $62, $62, $2A, $24, $30, $28, $62, $62  ; $4BC1
    db $62, $25, $24, $37, $37, $2F, $28, $62, $28, $39, $37, $27, $28, $30, $32, $62  ; $4BD1
    db $62, $36, $37, $24, $29, $29, $62, $62, $62, $28, $29, $29, $28, $26, $37, $62  ; $4BE1
    db $62, $35, $28, $36, $38, $2F, $37, $62, $27, $28, $25, $38, $2A, $62, $9D, $02  ; $4BF1
    db $32, $25, $2D, $37, $28, $36, $37, $62, $31, $32, $62, $30, $32, $35, $28, $5F  ; $4C01
    db $5F  ; $4C11
DispatchText_27:
    db $9C, $62, $25, $24, $37, $37, $2F, $28, $62, $9C, $F1, $F1, $28, $31, $28, $30  ; $4C12
    db $3C, $62, $62, $F1, $30, $32, $31, $36, $37, $35, $01, $F1, $30, $32, $31, $36  ; $4C22
    db $37, $35, $01, $F1, $30, $32, $31, $36, $37, $35, $02, $F1, $30, $32, $31, $36  ; $4C32
    db $37, $35, $02, $F1, $30, $32, $31, $36, $37, $35, $03, $F1, $30, $32, $31, $36  ; $4C42
    db $37, $35, $03, $F1, $62, $27, $38, $30, $30, $3C, $62, $F1  ; $4C52
DispatchText_28:
    db $31, $32, $35, $30, $24, $2F, $F0  ; $4C5E
DispatchText_29:
    db $24, $26, $35, $28, $24, $37, $28, $F0  ; $4C65
DispatchText_30:
    db $36, $37, $24, $2A, $28, $2C, $27, $F0  ; $4C6D
DispatchText_32:
    db $26, $24, $36, $37, $2F, $28, $F0  ; $4C75
DispatchText_33:
    db $39, $2C, $2F, $2F, $24, $2A, $28, $F0  ; $4C7C
DispatchText_34:
    db $25, $24, $3D, $24, $24, $35, $F0  ; $4C84
DispatchText_35:
    db $37, $35, $39, $2A, $24, $37, $28, $F0  ; $4C8B
DispatchText_36:
    db $29, $24, $35, $30, $F0  ; $4C93
DispatchText_37:
    db $36, $2B, $33, $35, $27, $F0  ; $4C98
DispatchText_38:
    db $25, $24, $37, $37, $2F, $28, $01, $F0  ; $4C9E
DispatchText_39:
    db $25, $24, $37, $37, $2F, $28, $02, $F0  ; $4CA6
DispatchText_40:
    db $31, $28, $36, $37, $F0  ; $4CAE
DispatchText_41:
    db $36, $37, $35, $27, $31, $2A, $31, $F0  ; $4CB3
DispatchText_42:
    db $3A, $37, $30, $28, $27, $24, $2F, $F0  ; $4CBB
DispatchText_43:
    db $F0  ; $4CC3
DispatchText_44:
    db $28, $2A, $26, $31, $36, $2F, $37, $F0  ; $4CC4
DispatchText_45:
    db $33, $35, $27, $33, $35, $31, $37, $F0  ; $4CCC
DispatchText_46:
    db $F0  ; $4CD4
DispatchText_47:
    db $26, $2B, $2E, $36, $37, $31, $27, $F0  ; $4CD5
DispatchText_48:
    db $26, $38, $37, $3C, $2A, $35, $2F, $F0  ; $4CDD
DispatchText_49:
    db $F0  ; $4CE5
DispatchText_50:
    db $2F, $2C, $25, $35, $24, $35, $3C, $F0  ; $4CE6
DispatchText_51:
    db $36, $37, $24, $26, $2E, $F0  ; $4CEE
DispatchText_52:
    db $F0  ; $4CF4
DispatchText_53:
    db $F0  ; $4CF5
DispatchText_54:
    db $30, $28, $27, $24, $2F, $30, $24, $31, $F0  ; $4CF6
DispatchText_55:
    db $F0  ; $4CFF
DispatchText_56:
    db $2C, $31, $62, $3A, $28, $2F, $2F, $F0  ; $4D00
DispatchText_57:
    db $30, $27, $3C, $2B, $24, $31, $27, $F0  ; $4D08
DispatchText_58:
    db $36, $33, $32, $31, $36, $28, $35, $F0  ; $4D10
DispatchText_59:
    db $36, $37, $24, $25, $2F, $28, $2F, $F0  ; $4D18
DispatchText_60:
    db $36, $37, $24, $25, $2F, $28, $35, $F0  ; $4D20
DispatchText_61:
    db $36, $26, $2B, $32, $32, $2F, $F0  ; $4D28
DispatchText_62:
    db $25, $24, $35, $F0  ; $4D2F
DispatchText_63:
    db $34, $38, $28, $28, $28, $31, $F0  ; $4D33
DispatchText_64:
    db $F0  ; $4D3A
DispatchText_65:
    db $F0  ; $4D3B
DispatchText_66:
    db $F0  ; $4D3C
DispatchText_67:
    db $26, $2B, $30, $25, $35, $32, $33, $F0  ; $4D3D
DispatchText_68:
    db $26, $2B, $30, $25, $35, $62, $2A, $F0  ; $4D45
DispatchText_69:
    db $26, $2B, $30, $25, $35, $62, $29, $F0  ; $4D4D
DispatchText_70:
    db $26, $2B, $30, $25, $35, $62, $28, $F0  ; $4D55
DispatchText_71:
    db $26, $2B, $30, $25, $35, $62, $27, $F0  ; $4D5D
DispatchText_72:
    db $26, $2B, $30, $25, $35, $62, $26, $F0, $26, $2B, $30, $25, $35, $62, $25, $F0  ; $4D65
    db $26, $2B, $30, $25, $35, $62, $24, $F0, $26, $2B, $30, $25, $35, $62, $36, $F0  ; $4D75
    db $26, $2B, $30, $25, $35, $62, $01, $F0, $26, $2B, $30, $25, $35, $62, $02, $F0  ; $4D85
    db $26, $2B, $30, $25, $35, $62, $03, $F0, $37, $28, $35, $35, $3C, $36, $F0, $32  ; $4D95
    db $2F, $27, $3A, $28, $2F, $2F, $F0, $36, $62, $26, $24, $39, $28, $F0, $30, $28  ; $4DA5
    db $2F, $2E, $2C, $27, $F0, $31, $28, $36, $37, $F0, $2C, $2F, $30, $3A, $32, $32  ; $4DB5
    db $27, $F0, $37, $32, $30, $27, $32, $2F, $24, $F0, $26, $24, $36, $2C, $31, $32  ; $4DC5
    db $F0, $2A, $32, $27, $37, $3A, $35, $F0, $2F, $32, $31, $27, $24, $35, $2A, $35  ; $4DD5
    db $F0, $35, $28, $31, $38, $2F, $F0, $24, $35, $33, $37, $3A, $35, $F0, $27, $24  ; $4DE5
    db $31, $26, $28, $35, $F0, $37, $62, $26, $24, $39, $28, $F0, $36, $33, $35, $2C  ; $4DF5
    db $31, $2A, $F0, $2B, $24, $33, $33, $3C, $F0, $2F, $2C, $29, $28, $26, $32, $27  ; $4E05
    db $F0, $37, $35, $2C, $24, $2F, $01, $F0, $37, $35, $2C, $24, $2F, $02, $F0, $30  ; $4E15
    db $62, $26, $24, $39, $28, $F0, $33, $35, $2C, $36, $32, $31, $F0, $3D, $62, $26  ; $4E25
    db $24, $39, $28, $F0, $2B, $28, $2F, $26, $2F, $27, $F0, $27, $35, $2A, $26, $36  ; $4E35
    db $37, $2F, $F0, $2B, $35, $2A, $31, $26, $36, $2F, $F0, $25, $35, $30, $36, $26  ; $4E45
    db $36, $2F, $F0, $3D, $32, $30, $24, $26, $36, $2F, $F0, $30, $37, $62, $37, $32  ; $4E55
    db $33, $F0, $24, $37, $37, $32, $30, $F0, $28, $39, $2C, $2F, $62, $30, $37, $F0  ; $4E65
    db $30, $38, $27, $32, $26, $36, $2F, $F0, $25, $37, $3A, $28, $26, $36, $2F, $F0  ; $4E75
    db $36, $26, $35, $37, $30, $24, $33, $F0, $2C, $37, $28, $30, $36, $33, $F0, $26  ; $4E85
    db $2B, $38, $35, $26, $2B, $F0, $26, $32, $2F, $2C, $36, $38, $30, $F0, $30, $24  ; $4E95
    db $3D, $28, $3A, $32, $27, $F0, $36, $2F, $27, $29, $2F, $35, $01, $F0, $36, $2F  ; $4EA5
    db $27, $29, $2F, $35, $02, $F0, $36, $2F, $27, $29, $2F, $35, $03, $F0, $30, $24  ; $4EB5
    db $3D, $28, $01, $F0, $30, $24, $3D, $28, $02, $F0, $30, $24, $3D, $28, $03, $F0  ; $4EC5
    db $30, $30, $26, $35, $30, $01, $F0, $30, $30, $26, $35, $30, $02, $F0, $30, $30  ; $4ED5
    db $26, $35, $30, $03, $F0, $25, $37, $2F, $27, $28, $30, $32, $F0, $26, $36, $2F  ; $4EE5
    db $25, $2A, $F0, $F0, $F9, $00, $F0, $3A, $3E, $4B, $51, $62, $51, $4C, $62, $41  ; $4EF5
    db $52, $4A, $4D, $F1, $F9, $10, $64, $F0, $F9, $00, $62, $41, $52, $4A, $4D, $50  ; $4F05
    db $F1, $F9, $10, $62, $3E, $54, $3E, $56, $63, $F7, $F0, $26, $3E, $4B, $4B, $4C  ; $4F15
    db $51, $62, $41, $52, $4A, $4D, $62, $45, $42, $4F, $42, $63, $F7, $F0, $F9, $00  ; $4F25
    db $62, $52, $50, $42, $50, $F1, $01, $62, $F9, $10, $5F, $F7, $F0, $F9, $00, $62  ; $4F35
    db $44, $3E, $53, $42, $50, $F1, $F9, $10, $FA, $F7, $F2, $01, $62, $F9, $20, $5F  ; $4F45
    db $F1, $F7, $F0, $31, $4C, $51, $45, $46, $4B, $44, $62, $45, $3E, $4D, $4D, $42  ; $4F55
    db $4B, $50, $5F, $F7, $F0, $35, $42, $40, $4C, $4F, $41, $62, $51, $4C, $62, $51  ; $4F65
    db $45, $42, $F1, $2D, $4C, $52, $4F, $4B, $3E, $49, $64, $F7, $F0, $F6, $62, $43  ; $4F75
    db $4C, $52, $4B, $41, $F1, $01, $62, $F9, $00, $F7, $F0, $2C, $50, $62, $F9, $00  ; $4F85
    db $62, $4C, $48, $3E, $56, $F1, $43, $4C, $4F, $62, $51, $45, $42, $62, $4B, $3E  ; $4F95
    db $4A, $42, $64, $F0, $33, $49, $42, $3E, $50, $42, $62, $40, $45, $4C, $4C, $50  ; $4FA5
    db $42, $F1, $3E, $4B, $4C, $51, $45, $42, $4F, $62, $4B, $3E, $4A, $42, $5F, $F7  ; $4FB5
    db $F0, $33, $38, $37, $62, $37, $24, $2E, $28, $28, $3B, $2C, $37, $F0, $2C, $37  ; $4FC5
    db $28, $30, $2A, $32, $2F, $27, $28, $3B, $2C, $37, $F0, $28, $4A, $4D, $51, $56  ; $4FD5
    db $F0, $28, $44, $44, $F0, $3A, $3E, $4B, $51, $62, $51, $4C, $62, $4B, $3E, $4A  ; $4FE5
    db $42, $F1, $F9, $10, $62, $3E, $50, $FA, $F7, $F2, $F9, $00, $64, $F1, $F0, $28  ; $4FF5
    db $3B, $2C, $37, $62, $2C, $31, $29, $32, $F0, $29, $4C, $52, $4B, $41, $62, $01  ; $5005
    db $62, $F9, $00, $5F, $F1, $25, $52, $51, $62, $40, $3E, $4B, $4B, $4C, $51, $62  ; $5015
    db $40, $3E, $4F, $4F, $56, $FA, $F7, $F2, $3E, $4B, $56, $62, $4A, $4C, $4F, $42  ; $5025
    db $5F, $F1, $F7, $F0, $2A, $46, $53, $42, $50, $62, $52, $4D, $F1, $F9, $00, $63  ; $5035
    db $F7, $F0, $27, $52, $4A, $4D, $62, $54, $45, $46, $40, $45, $62, $46, $51, $42  ; $5045
    db $4A, $64, $F0, $27, $52, $4A, $4D, $42, $41, $62, $F9, $10, $F1, $3E, $4B, $41  ; $5055
    db $62, $44, $4C, $51, $62, $F9, $00, $5F, $F7, $F0, $F6, $62, $43, $4C, $52, $4B  ; $5065
    db $41, $F1, $F9, $00, $2A, $5F, $F7, $F0, $29, $46, $4B, $41, $50, $62, $F9, $00  ; $5075
    db $2A, $5F, $F1, $26, $3E, $4B, $4B, $4C, $51, $62, $51, $3E, $48, $42, $62, $4A  ; $5085
    db $4C, $4F, $42, $5F, $F7, $F0, $37, $45, $42, $62, $51, $4F, $42, $3E, $50, $52  ; $5095
    db $4F, $42, $62, $3F, $4C, $55, $F1, $46, $50, $62, $4F, $42, $3E, $49, $49, $56  ; $50A5
    db $62, $3E, $62, $30, $46, $4A, $46, $40, $63, $F7, $F0, $F9, $00, $F1, $43, $3E  ; $50B5
    db $46, $4B, $51, $50, $5F, $F7, $F0, $F9, $00, $F1, $43, $3E, $46, $4B, $51, $50  ; $50C5
    db $5F, $F7, $F2, $F9, $10, $F1, $43, $3E, $46, $4B, $51, $50, $5F, $F7, $F0, $F6  ; $50D5
    db $68, $62, $50, $46, $41, $42, $62, $46, $50, $F1, $54, $46, $4D, $42, $41, $62  ; $50E5
    db $4C, $52, $51, $63, $F7, $F0, $31, $4C, $51, $62, $4F, $42, $3E, $41, $56, $62  ; $50F5
    db $43, $4C, $4F, $F1, $49, $46, $4B, $48, $62, $52, $4D, $5F, $FA, $F7, $F2, $26  ; $5105
    db $45, $42, $40, $48, $62, $3E, $4B, $41, $F1, $51, $4F, $56, $62, $3E, $44, $3E  ; $5115
    db $46, $4B, $5F, $F7, $F0, $26, $45, $4C, $4C, $50, $42, $62, $3E, $62, $4A, $4C  ; $5125
    db $4B, $50, $51, $42, $4F, $F1, $43, $4C, $4F, $62, $3F, $4F, $42, $42, $41, $46  ; $5135
    db $4B, $44, $5F, $F0, $26, $3E, $4B, $4B, $4C, $51, $62, $40, $45, $4C, $4C, $50  ; $5145
    db $42, $62, $51, $45, $42, $F1, $4C, $4B, $49, $56, $62, $4A, $4C, $4B, $50, $51  ; $5155
    db $42, $4F, $62, $49, $42, $43, $51, $FA, $F7, $F2, $46, $4B, $62, $56, $4C, $52  ; $5165
    db $4F, $62, $40, $52, $4F, $4F, $42, $4B, $51, $F1, $4D, $3E, $4F, $51, $56, $5F  ; $5175
    db $F7, $F0, $36, $3E, $4A, $42, $62, $44, $42, $4B, $41, $42, $4F, $5F, $F1, $26  ; $5185
    db $3E, $4B, $4B, $4C, $51, $62, $3F, $4F, $42, $42, $41, $5F, $F7, $F0, $32, $4B  ; $5195
    db $42, $62, $4A, $4C, $4A, $42, $4B, $51, $62, $4D, $49, $42, $3E, $50, $42, $5F  ; $51A5
    db $F0, $3A, $3E, $4B, $51, $62, $51, $4C, $62, $3F, $4F, $42, $42, $41, $64, $F0  ; $51B5
    db $35, $42, $43, $52, $50, $42, $41, $62, $51, $4C, $62, $3F, $4F, $42, $42, $41  ; $51C5
    db $5F, $F0, $25, $4F, $42, $42, $41, $46, $4B, $44, $62, $4F, $42, $43, $52, $50  ; $51D5
    db $42, $41, $5F, $F0, $36, $3E, $53, $42, $62, $51, $45, $42, $62, $4F, $42, $50  ; $51E5
    db $52, $49, $51, $62, $4C, $43, $F1, $3F, $4F, $42, $42, $41, $46, $4B, $44, $64  ; $51F5
    db $F0, $37, $45, $42, $62, $40, $42, $4F, $42, $4A, $4C, $4B, $56, $63, $F0, $26  ; $5205
    db $45, $4C, $4C, $50, $42, $62, $4A, $4C, $4B, $50, $51, $42, $4F, $A0, $50, $A1  ; $5215
    db $F1, $43, $4C, $4F, $62, $51, $45, $42, $62, $3F, $3E, $51, $51, $49, $42, $5F  ; $5225
    db $F0, $3A, $45, $3E, $51, $62, $54, $4C, $52, $49, $41, $62, $56, $4C, $52, $F1  ; $5235
    db $49, $46, $48, $42, $62, $51, $4C, $62, $41, $4C, $64, $F0, $26, $45, $4C, $4C  ; $5245
    db $50, $42, $62, $3E, $4B, $4C, $51, $45, $42, $4F, $F1, $4A, $4C, $4B, $50, $51  ; $5255
    db $42, $4F, $64, $F7, $F0, $36, $52, $3F, $4A, $46, $51, $62, $3E, $62, $4D, $4F  ; $5265
    db $46, $57, $42, $64, $F7, $F0, $31, $4C, $62, $4A, $4C, $4B, $50, $51, $42, $4F  ; $5275
    db $50, $62, $49, $42, $43, $51, $F1, $3E, $51, $62, $51, $45, $42, $62, $43, $3E  ; $5285
    db $4F, $4A, $5F, $FA, $F7, $F2, $37, $45, $52, $50, $5E, $62, $4B, $4C, $62, $4D  ; $5295
    db $4F, $46, $57, $42, $5F, $F1, $F7, $F0, $26, $45, $4C, $4C, $50, $42, $62, $3E  ; $52A5
    db $62, $4A, $4C, $4B, $50, $51, $42, $4F, $F1, $43, $4C, $4F, $62, $51, $45, $42  ; $52B5
    db $62, $4D, $4F, $46, $57, $42, $64, $F0, $24, $4F, $42, $62, $56, $4C, $52, $62  ; $52C5
    db $4F, $42, $3E, $41, $56, $F1, $51, $4C, $62, $43, $46, $44, $45, $51, $64, $F0  ; $52D5
    db $29, $46, $44, $45, $51, $63, $63, $F0, $35, $42, $43, $52, $50, $42, $41, $62  ; $52E5
    db $51, $45, $42, $F1, $3F, $3E, $51, $51, $49, $42, $5F, $F0, $25, $3E, $51, $51  ; $52F5
    db $49, $42, $62, $4F, $42, $43, $52, $50, $42, $41, $5F, $F0, $31, $4C, $62, $4D  ; $5305
    db $4F, $46, $57, $42, $5F, $F7, $F0, $3C, $4C, $52, $4F, $62, $4A, $4C, $4B, $50  ; $5315
    db $51, $42, $4F, $62, $46, $50, $F1, $4B, $4C, $51, $62, $4C, $49, $41, $62, $42  ; $5325
    db $4B, $4C, $52, $44, $45, $FA, $F7, $F2, $43, $4C, $4F, $62, $3F, $4F, $42, $42  ; $5335
    db $41, $46, $4B, $44, $5F, $F1, $FA, $F7, $F2, $25, $4F, $46, $4B, $44, $62, $46  ; $5345
    db $51, $62, $3F, $3E, $40, $48, $62, $54, $45, $42, $4B, $F1, $46, $51, $68, $62  ; $5355
    db $3E, $62, $3F, $46, $51, $62, $4C, $49, $41, $42, $4F, $5F, $F7, $F0, $31, $4C  ; $5365
    db $62, $36, $3E, $53, $42, $5F, $F0, $35, $42, $40, $4C, $4F, $41, $42, $41, $62  ; $5375
    db $46, $4B, $62, $51, $45, $42, $F1, $2D, $4C, $52, $4F, $4B, $3E, $49, $5F, $F7  ; $5385
    db $F0, $62, $62, $1B, $14, $1C, $1D, $F0, $69, $67, $15, $6F, $1C, $1D, $F0, $2B  ; $5395
    db $33, $F0, $30, $33, $F0, $24, $37, $37, $24, $26, $2E, $62, $4D, $4C, $54, $42  ; $53A5
    db $4F, $F0, $27, $28, $29, $28, $31, $36, $28, $62, $4D, $4C, $54, $42, $4F, $F0  ; $53B5
    db $24, $2A, $2C, $2F, $2C, $37, $3C, $F0, $2C, $31, $37, $28, $2F, $2F, $2C, $2A  ; $53C5
    db $28, $31, $26, $28, $F0, $AE, $F0, $AF, $F0, $A9, $F0, $B0, $F0, $B1, $F0, $AD  ; $53D5
    db $F0, $B2, $F0, $B3, $F0, $26, $3E, $4B, $4B, $4C, $51, $62, $4F, $42, $40, $4C  ; $53E5
    db $4F, $41, $62, $46, $4B, $F1, $51, $45, $42, $62, $2D, $4C, $52, $4F, $4B, $3E  ; $53F5
    db $49, $62, $45, $42, $4F, $42, $5F, $F7, $F0, $1E, $59, $13, $B4, $62, $F0, $37  ; $5405
    db $45, $42, $62, $50, $3E, $4A, $42, $62, $4B, $3E, $4A, $42, $F1, $3E, $49, $4F  ; $5415
    db $42, $3E, $41, $56, $62, $42, $55, $46, $50, $51, $50, $5F, $FA, $F7, $F2, $2C  ; $5425
    db $50, $62, $51, $45, $42, $62, $4B, $3E, $4A, $42, $F1, $F9, $00, $62, $4C, $48  ; $5435
    db $62, $43, $4C, $4F, $FA, $F7, $F2, $F9, $10, $64, $F1, $F0, $3C, $4C, $52, $62  ; $5445
    db $54, $46, $4B, $63, $FA, $F7, $F0, $3C, $4C, $52, $62, $49, $4C, $50, $42, $63  ; $5455
    db $FA, $F7, $F0, $F9, $00, $62, $50, $52, $4F, $4F, $42, $4B, $41, $42, $4F, $42  ; $5465
    db $41, $F1, $F9, $10, $5F, $F7, $F0, $F9, $10, $62, $54, $3E, $50, $F1, $51, $3E  ; $5475
    db $48, $42, $4B, $62, $3F, $56, $62, $F9, $00, $5F, $F7, $F0, $3A, $2B, $32, $2C  ; $5485
    db $31, $29, $32, $32, $2E, $30, $32, $31, $28, $2A, $2A, $F0, $37, $45, $42, $62  ; $5495
    db $4A, $4C, $4B, $50, $51, $42, $4F, $EF, $EE, $43, $3E, $4F, $4A, $62, $46, $50  ; $54A5
    db $62, $43, $52, $49, $49, $63, $FA, $F7, $EF, $EE, $27, $4C, $62, $56, $4C, $52  ; $54B5
    db $62, $54, $3E, $4B, $51, $62, $51, $4C, $EF, $EE, $4F, $42, $4D, $49, $3E, $40  ; $54C5
    db $42, $62, $4C, $4B, $42, $62, $4C, $43, $FA, $F7, $EF, $EE, $56, $4C, $52, $4F  ; $54D5
    db $62, $4A, $4C, $4B, $50, $51, $42, $4F, $50, $EF, $EE, $54, $46, $51, $45, $62  ; $54E5
    db $51, $45, $46, $50, $62, $4C, $4B, $42, $64, $F0, $F9, $10, $62, $F1, $46, $50  ; $54F5
    db $62, $4F, $42, $51, $52, $4F, $4B, $42, $41, $62, $51, $4C, $FA, $F7, $F2, $51  ; $5505
    db $45, $42, $62, $54, $46, $49, $41, $5F, $F1, $F7, $F0, $35, $42, $4D, $49, $3E  ; $5515
    db $40, $42, $62, $54, $46, $51, $45, $F1, $54, $45, $46, $40, $45, $62, $4A, $4C  ; $5525
    db $4B, $50, $51, $42, $4F, $64, $F0, $2C, $50, $62, $51, $45, $46, $50, $62, $4A  ; $5535
    db $4C, $4B, $50, $51, $42, $4F, $F1, $32, $2E, $62, $51, $4C, $62, $4F, $42, $4D  ; $5545
    db $49, $3E, $40, $42, $64, $F0, $27, $4C, $62, $56, $4C, $52, $62, $54, $3E, $4B  ; $5555
    db $51, $62, $51, $4C, $F1, $4F, $42, $4D, $49, $3E, $40, $42, $62, $4C, $4B, $42  ; $5565
    db $62, $4C, $43, $FA, $F7, $F2, $56, $4C, $52, $4F, $62, $4A, $4C, $4B, $50, $51  ; $5575
    db $42, $4F, $50, $F1, $54, $46, $51, $45, $62, $51, $45, $46, $50, $62, $4C, $4B  ; $5585
    db $42, $64, $F0, $37, $45, $42, $4F, $42, $62, $54, $46, $49, $49, $62, $3F, $42  ; $5595
    db $62, $4B, $4C, $F1, $4C, $4B, $42, $62, $49, $42, $43, $51, $62, $46, $4B, $62  ; $55A5
    db $51, $45, $42, $FA, $F7, $F2, $40, $52, $4F, $4F, $42, $4B, $51, $62, $4D, $3E  ; $55B5
    db $4F, $51, $56, $62, $51, $4C, $F1, $43, $46, $44, $45, $51, $5F, $F7, $F0, $35  ; $55C5
    db $42, $4D, $49, $3E, $40, $42, $62, $54, $46, $51, $45, $F1, $54, $45, $46, $40  ; $55D5
    db $45, $62, $4A, $4C, $4B, $50, $51, $42, $4F, $64, $F0, $31, $4C, $62, $42, $44  ; $55E5
    db $44, $5F, $F7, $F0, $35, $42, $4D, $49, $3E, $40, $42, $62, $54, $46, $51, $45  ; $55F5
    db $F1, $54, $45, $46, $40, $45, $62, $42, $44, $44, $64, $F0, $F9, $10, $62, $F1  ; $5605
    db $46, $50, $62, $4F, $42, $51, $52, $4F, $4B, $42, $41, $62, $51, $4C, $FA, $F7  ; $5615
    db $F2, $51, $45, $42, $62, $54, $46, $49, $41, $5F, $F1, $F7, $F0, $2C, $37, $28  ; $5625
    db $30, $F0, $3A, $3E, $4B, $51, $62, $51, $4C, $62, $4F, $42, $40, $4C, $4F, $41  ; $5635
    db $F1, $56, $4C, $52, $4F, $62, $4E, $52, $42, $50, $51, $64, $E6, $F0, $36, $3E  ; $5645
    db $53, $42, $41, $63, $62, $33, $49, $42, $3E, $50, $42, $62, $51, $52, $4F, $4B  ; $5655
    db $F1, $4C, $43, $43, $62, $51, $45, $42, $62, $4D, $4C, $54, $42, $4F, $5F, $F0  ; $5665
    db $37, $45, $3E, $4B, $48, $62, $56, $4C, $52, $63, $F1, $F7, $F2, $33, $49, $42  ; $5675
    db $3E, $50, $42, $62, $51, $52, $4F, $4B, $62, $4C, $43, $43, $F1, $51, $45, $42  ; $5685
    db $62, $4D, $4C, $54, $42, $4F, $5F, $F0, $40, $45, $42, $4B, $5F, $47, $5F, $4B  ; $5695
    db $B4, $9B, $F0, $3C, $4C, $52, $62, $40, $3E, $4B, $4B, $4C, $51, $62, $40, $45  ; $56A5
    db $4C, $4C, $50, $42, $F1, $51, $45, $42, $62, $4A, $4C, $4B, $50, $51, $42, $4F  ; $56B5
    db $62, $46, $4B, $FA, $F7, $F2, $56, $4C, $52, $4F, $62, $40, $52, $4F, $4F, $42  ; $56C5
    db $4B, $51, $62, $4D, $3E, $4F, $51, $56, $F1, $3E, $50, $62, $3E, $62, $4D, $4F  ; $56D5
    db $46, $57, $42, $5F, $F7, $F0, $33, $49, $42, $3E, $50, $42, $62, $40, $45, $4C  ; $56E5
    db $4C, $50, $42, $62, $3E, $F1, $4A, $4C, $4B, $50, $51, $42, $4F, $62, $43, $4F  ; $56F5
    db $4C, $4A, $62, $51, $45, $42, $FA, $F7, $F2, $43, $3E, $4F, $4A, $5F, $F1, $F7  ; $5705
    db $F0, $37, $4C, $4C, $62, $3F, $3E, $41, $5F, $5F, $5F, $F1, $25, $4F, $42, $42  ; $5715
    db $41, $46, $4B, $44, $62, $43, $3E, $46, $49, $42, $41, $5F, $F7, $F0, $25, $28  ; $5725
    db $2A, $2C, $31, $31, $2C, $31, $2A, $A3, $F0, $39, $2C, $2F, $2F, $24, $2A, $28  ; $5735
    db $35, $A3, $F0, $37, $24, $2F, $2C, $36, $30, $24, $31, $A3, $F0, $30, $28, $30  ; $5745
    db $32, $35, $2C, $28, $36, $A3, $F0, $25, $28, $3A, $2C, $2F, $27, $28, $35, $A3  ; $5755
    db $F0, $33, $28, $24, $26, $28, $A3, $F0, $25, $35, $24, $39, $28, $35, $3C, $A3  ; $5765
    db $F0, $36, $37, $35, $28, $31, $2A, $37, $2B, $A3, $F0, $24, $31, $2A, $28, $35  ; $5775
    db $A3, $F0, $2D, $32, $3C, $A3, $F0, $3A, $2C, $36, $27, $32, $30, $A3, $F0, $2B  ; $5785
    db $24, $33, $33, $2C, $31, $28, $36, $36, $A3, $F0, $37, $28, $30, $33, $37, $24  ; $5795
    db $37, $2C, $32, $31, $A3, $F0, $2F, $24, $25, $3C, $35, $2C, $31, $37, $2B, $A3  ; $57A5
    db $F0, $2D, $38, $27, $2A, $30, $28, $31, $37, $A3, $F0, $35, $28, $29, $2F, $28  ; $57B5
    db $26, $37, $2C, $32, $31, $A3, $F0, $F0, $37, $45, $46, $50, $62, $32, $4D, $51  ; $57C5
    db $46, $4C, $4B, $62, $46, $50, $F1, $52, $4B, $3E, $53, $3E, $46, $49, $3E, $3F  ; $57D5
    db $49, $42, $62, $54, $46, $51, $45, $FA, $F7, $F2, $36, $52, $4D, $42, $4F, $62  ; $57E5
    db $2A, $3E, $4A, $42, $62, $25, $4C, $56, $5F, $F1, $F7, $F0, $36, $2F, $2C, $35  ; $57F5
    db $F0, $36, $2F, $38, $33, $F0, $35, $38, $2E, $3C, $F0, $36, $24, $2F, $3C, $F0  ; $5805
    db $33, $32, $36, $3C, $F0, $33, $28, $37, $28, $F0, $36, $2F, $24, $26, $F0, $30  ; $5815
    db $28, $2F, $37, $F0, $36, $2F, $28, $28, $F0, $26, $24, $2F, $F0, $36, $2C, $2F  ; $5825
    db $F0, $36, $24, $2F, $F0, $30, $2C, $2F, $2C, $F0, $2F, $2C, $30, $28, $F0, $30  ; $5835
    db $24, $35, $26, $F0, $24, $38, $37, $30, $F0, $35, $28, $3B, $F0, $30, $32, $39  ; $5845
    db $28, $F0, $26, $2F, $32, $3A, $F0, $37, $24, $33, $F0, $2E, $2C, $37, $28, $F0  ; $5855
    db $3A, $2C, $2F, $27, $F0, $2A, $28, $28, $2E, $F0, $37, $2C, $28, $F0, $27, $35  ; $5865
    db $24, $26, $F0, $26, $24, $35, $3C, $F0, $25, $28, $37, $2B, $F0, $2F, $38, $2F  ; $5875
    db $38, $F0, $2C, $36, $3C, $36, $F0, $26, $2B, $28, $36, $F0, $2A, $2C, $35, $2F  ; $5885
    db $F0, $25, $28, $2F, $2F, $F0, $36, $24, $39, $3C, $F0, $33, $38, $2E, $3C, $F0  ; $5895
    db $25, $38, $2E, $3C, $F0, $25, $32, $31, $2A, $F0, $2A, $38, $31, $3C, $F0, $36  ; $58A5
    db $38, $31, $3C, $F0, $30, $24, $3B, $F0, $27, $28, $2F, $32, $F0, $31, $28, $39  ; $58B5
    db $3C, $F0, $37, $2C, $2F, $F0, $3C, $28, $37, $24, $F0, $36, $24, $36, $24, $F0  ; $58C5
    db $30, $32, $2E, $32, $F0, $2E, $24, $35, $3C, $F0, $25, $24, $25, $3C, $F0, $2E  ; $58D5
    db $2C, $37, $24, $F0, $25, $2C, $35, $27, $F0, $2F, $38, $26, $2E, $F0, $26, $2B  ; $58E5
    db $2C, $33, $F0, $33, $24, $35, $2E, $F0, $2B, $28, $2E, $3C, $F0, $35, $24, $39  ; $58F5
    db $28, $F0, $37, $32, $31, $3C, $F0, $35, $24, $27, $3C, $F0, $26, $38, $2E, $3C  ; $5905
    db $F0, $26, $32, $32, $F0, $2D, $32, $27, $3C, $F0, $25, $32, $31, $3C, $F0, $30  ; $5915
    db $2C, $36, $24, $F0, $30, $28, $2A, $F0, $2E, $28, $2F, $3C, $F0, $29, $28, $3C  ; $5925
    db $F0, $25, $32, $31, $3D, $F0, $3D, $32, $32, $2F, $F0, $25, $24, $25, $24, $F0  ; $5935
    db $30, $2C, $37, $3C, $F0, $2B, $32, $2F, $3C, $F0, $2E, $2C, $31, $3C, $F0, $2F  ; $5945
    db $38, $30, $33, $F0, $36, $2C, $32, $31, $F0, $28, $39, $28, $F0, $2F, $32, $37  ; $5955
    db $36, $F0, $35, $32, $36, $28, $F0, $26, $38, $2F, $F0, $2D, $2C, $2F, $2F, $F0  ; $5965
    db $25, $28, $26, $2E, $F0, $36, $2B, $3C, $F0, $29, $38, $35, $F0, $2E, $2C, $26  ; $5975
    db $36, $F0, $2D, $32, $2B, $31, $F0, $35, $2C, $30, $33, $F0, $33, $28, $28, $37  ; $5985
    db $F0, $2A, $35, $38, $F0, $25, $35, $38, $37, $F0, $37, $32, $33, $3C, $F0, $36  ; $5995
    db $37, $2C, $2E, $F0, $30, $24, $35, $3C, $F0, $2F, $3C, $31, $31, $F0, $25, $28  ; $59A5
    db $37, $3C, $F0, $2B, $32, $31, $3C, $F0, $33, $32, $2F, $3C, $F0, $26, $32, $32  ; $59B5
    db $2F, $F0, $2B, $24, $31, $24, $F0, $36, $38, $31, $F0, $30, $28, $29, $3C, $F0  ; $59C5
    db $25, $28, $35, $2A, $F0, $30, $28, $35, $28, $F0, $25, $24, $35, $37, $F0, $25  ; $59D5
    db $35, $38, $31, $F0, $25, $32, $2F, $27, $F0, $2F, $38, $2E, $28, $F0, $24, $30  ; $59E5
    db $32, $36, $F0, $36, $24, $2F, $24, $F0, $33, $32, $2F, $24, $F0, $2D, $38, $27  ; $59F5
    db $3C, $F0, $39, $2C, $39, $2C, $F0, $29, $2F, $32, $35, $F0, $36, $24, $27, $3C  ; $5A05
    db $F0, $24, $30, $3C, $F0, $35, $32, $31, $24, $F0, $30, $2C, $2F, $F0, $3A, $2C  ; $5A15
    db $2F, $F0, $37, $32, $32, $F0, $31, $28, $2E, $F0, $37, $28, $2E, $F0, $37, $32  ; $5A25
    db $37, $32, $F0, $39, $32, $30, $2C, $F0, $2F, $2C, $2F, $2C, $F0, $25, $28, $2F  ; $5A35
    db $3C, $F0, $2D, $28, $31, $3C, $F0, $29, $35, $24, $31, $F0, $27, $32, $35, $F0  ; $5A45
    db $37, $3A, $28, $28, $F0, $2E, $24, $31, $24, $F0, $35, $24, $3C, $F0, $2D, $28  ; $5A55
    db $36, $3C, $F0, $31, $2C, $37, $35, $F0, $33, $28, $33, $F0, $35, $32, $2E, $3C  ; $5A65
    db $F0, $30, $28, $2A, $24, $F0, $29, $32, $37, $F0, $39, $2C, $31, $3C, $F0, $25  ; $5A75
    db $32, $25, $F0, $35, $32, $25, $F0, $2D, $28, $2F, $F0, $35, $38, $25, $3C, $F0  ; $5A85
    db $33, $24, $35, $2F, $F0, $24, $30, $28, $37, $F0, $33, $2C, $24, $F0, $37, $2C  ; $5A95
    db $24, $F0, $36, $28, $35, $24, $F0, $35, $28, $27, $24, $F0, $27, $35, $24, $31  ; $5AA5
    db $F0, $33, $38, $33, $36, $F0, $26, $24, $35, $2F, $F0, $3D, $28, $28, $2E, $F0  ; $5AB5
    db $26, $35, $2C, $36, $F0, $2A, $32, $2F, $27, $F0, $2A, $2C, $2A, $24, $F0, $26  ; $5AC5
    db $28, $31, $37, $F0, $30, $24, $35, $2C, $F0, $24, $31, $31, $24, $F0, $28, $2F  ; $5AD5
    db $2F, $3C, $F0, $2F, $2C, $3D, $24, $F0, $25, $28, $2F, $24, $F0, $2F, $2C, $2F  ; $5AE5
    db $3C, $F0, $24, $31, $31, $F0, $25, $24, $35, $25, $F0, $30, $24, $35, $2C, $F0  ; $5AF5
    db $24, $31, $31, $24, $F0, $10, $F0, $11, $F0, $12, $F0, $13, $F0, $14, $F0, $15  ; $5B05
    db $F0, $16, $F0, $17, $F0, $18, $F0, $19, $F0, $F0  ; $5B15

; Monster Name Strings ($5B1F)
; $F0 terminated, charmap encoded
; ---------------------------------------------------------------

MonsterNameStrings:
MonsterName_000_DrakSlime: db "DrakSlime", $F0
MonsterName_001_SpotSlime: db "SpotSlime", $F0
MonsterName_002_WingSlime: db "WingSlime", $F0
MonsterName_003_TreeSlime: db "TreeSlime", $F0
MonsterName_004_Snaily: db "Snaily", $F0
MonsterName_005_SlimeNite: db "SlimeNite", $F0
MonsterName_006_Babble: db "Babble", $F0
MonsterName_007_BoxSlime: db "BoxSlime", $F0
MonsterName_008_Slime: db "Slime", $F0
MonsterName_009_Healer: db "Healer", $F0
MonsterName_010_FangSlime: db "FangSlime", $F0
MonsterName_011_RockSlime: db "RockSlime", $F0
MonsterName_012_SlimeBorg: db "SlimeBorg", $F0
MonsterName_013_Slabbit: db "Slabbit", $F0
MonsterName_014_SpotKing: db "SpotKing", $F0
MonsterName_015_KingSlime: db "KingSlime", $F0
MonsterName_016_Metaly: db "Metaly", $F0
MonsterName_017_Metabble: db "Metabble", $F0
MonsterName_018_MetalKing: db "MetalKing", $F0
MonsterName_019_GoldSlime: db "GoldSlime", $F0
MonsterName_020_DragonKid: db "DragonKid", $F0
MonsterName_021_Tortragon: db "Tortragon", $F0
MonsterName_022_Pteranod: db "Pteranod", $F0
MonsterName_023_Gasgon: db "Gasgon", $F0
MonsterName_024_FairyDrak: db "FairyDrak", $F0
MonsterName_025_LizardMan: db "LizardMan", $F0
MonsterName_026_Poisongon: db "Poisongon", $F0
MonsterName_027_Swordgon: db "Swordgon", $F0
MonsterName_028_Dragon: db "Dragon", $F0
MonsterName_029_MiniDrak: db "MiniDrak", $F0
MonsterName_030_MadDragon: db "MadDragon", $F0
MonsterName_031_Rayburn: db "Rayburn", $F0
MonsterName_032_Chamelgon: db "Chamelgon", $F0
MonsterName_033_LizardFly: db "LizardFly", $F0
MonsterName_034_Andreal: db "Andreal", $F0
MonsterName_035_KingCobra: db "KingCobra", $F0
MonsterName_036_Spikerous: db "Spikerous", $F0
MonsterName_037_GreatDrak: db "GreatDrak", $F0
MonsterName_038_Crestpent: db "Crestpent", $F0
MonsterName_039_WingSnake: db "WingSnake", $F0
MonsterName_040_Coatol: db "Coatol", $F0
MonsterName_041_Orochi: db "Orochi", $F0
MonsterName_042_BattleRex: db "BattleRex", $F0
MonsterName_043_SkyDragon: db "SkyDragon", $F0
MonsterName_044_Divinegon: db "Divinegon", $F0
MonsterName_045_Tonguella: db "Tonguella", $F0
MonsterName_046_Almiraj: db "Almiraj", $F0
MonsterName_047_CatFly: db "CatFly", $F0
MonsterName_048_PillowRat: db "PillowRat", $F0
MonsterName_049_Saccer: db "Saccer", $F0
MonsterName_050_GulpBeast: db "GulpBeast", $F0
MonsterName_051_Skullroo: db "Skullroo", $F0
MonsterName_052_WindBeast: db "WindBeast", $F0
MonsterName_053_Anteater: db "Anteater", $F0
MonsterName_054_SuperTen: db "SuperTen", $F0
MonsterName_055_IronTurt: db "IronTurt", $F0
MonsterName_056_Mommonja: db "Mommonja", $F0
MonsterName_057_HammerMan: db "HammerMan", $F0
MonsterName_058_Grizzly: db "Grizzly", $F0
MonsterName_059_Yeti: db "Yeti", $F0
MonsterName_060_MadGopher: db "MadGopher", $F0
MonsterName_061_FairyRat: db "FairyRat", $F0
MonsterName_062_Unicorn: db "Unicorn", $F0
MonsterName_063_Goategon: db "Goategon", $F0
MonsterName_064_WildApe: db "WildApe", $F0
MonsterName_065_Trumpeter: db "Trumpeter", $F0
MonsterName_066_KingLeo: db "KingLeo", $F0
MonsterName_067_DarkHorn: db "DarkHorn", $F0
MonsterName_068_MadCat: db "MadCat", $F0
MonsterName_069_BigEye: db "BigEye", $F0
MonsterName_070_Picky: db "Picky", $F0
MonsterName_071_Wyvern: db "Wyvern", $F0
MonsterName_072_BullBird: db "BullBird", $F0
MonsterName_073_Florajay: db "Florajay", $F0
MonsterName_074_DuckKite: db "DuckKite", $F0
MonsterName_075_MadPecker: db "MadPecker", $F0
MonsterName_076_MadRaven: db "MadRaven", $F0
MonsterName_077_MistyWing: db "MistyWing", $F0
MonsterName_078_Dracky: db "Dracky", $F0
MonsterName_079_BigRoost: db "BigRoost", $F0
MonsterName_080_StubBird: db "StubBird", $F0
MonsterName_081_LandOwl: db "LandOwl", $F0
MonsterName_082_MadGoose: db "MadGoose", $F0
MonsterName_083_MadCondor: db "MadCondor", $F0
MonsterName_084_Blizzardy: db "Blizzardy", $F0
MonsterName_085_Phoenix: db "Phoenix", $F0
MonsterName_086_ZapBird: db "ZapBird", $F0
MonsterName_087_WhipBird: db "WhipBird", $F0
MonsterName_088_FunkyBird: db "FunkyBird", $F0
MonsterName_089_RainHawk: db "RainHawk", $F0
MonsterName_090_MadPlant: db "MadPlant", $F0
MonsterName_091_FireWeed: db "FireWeed", $F0
MonsterName_092_FloraMan: db "FloraMan", $F0
MonsterName_093_WingTree: db "WingTree", $F0
MonsterName_094_CactiBall: db "CactiBall", $F0
MonsterName_095_Gulpple: db "Gulpple", $F0
MonsterName_096_Toadstool: db "Toadstool", $F0
MonsterName_097_AmberWeed: db "AmberWeed", $F0
MonsterName_098_Stubsuck: db "Stubsuck", $F0
MonsterName_099_Oniono: db "Oniono", $F0
MonsterName_100_DanceVegi: db "DanceVegi", $F0
MonsterName_101_TreeBoy: db "TreeBoy", $F0
MonsterName_102_FaceTree: db "FaceTree", $F0
MonsterName_103_HerbMan: db "HerbMan", $F0
MonsterName_104_BeanMan: db "BeanMan", $F0
MonsterName_105_EvilSeed: db "EvilSeed", $F0
MonsterName_106_ManEater: db "ManEater", $F0
MonsterName_107_Snapper: db "Snapper", $F0
MonsterName_108_Rosevine: db "Rosevine", $F0
MonsterName_109_Watabou: db "Watabou", $F0
MonsterName_110_GiantSlug: db "GiantSlug", $F0
MonsterName_111_Catapila: db "Catapila", $F0
MonsterName_112_Gophecada: db "Gophecada", $F0
MonsterName_113_Butterfly: db "Butterfly", $F0
MonsterName_114_WeedBug: db "WeedBug", $F0
MonsterName_115_GiantWorm: db "GiantWorm", $F0
MonsterName_116_Lipsy: db "Lipsy", $F0
MonsterName_117_StagBug: db "StagBug", $F0
MonsterName_118_ArmyAnt: db "ArmyAnt", $F0
MonsterName_119_GoHopper: db "GoHopper", $F0
MonsterName_120_TailEater: db "TailEater", $F0
MonsterName_121_ArmorPede: db "ArmorPede", $F0
MonsterName_122_Eyeder: db "Eyeder", $F0
MonsterName_123_GiantMoth: db "GiantMoth", $F0
MonsterName_124_Droll: db "Droll", $F0
MonsterName_125_ArmyCrab: db "ArmyCrab", $F0
MonsterName_126_MadHornet: db "MadHornet", $F0
MonsterName_127_HornBeet: db "HornBeet", $F0
MonsterName_128_Armorpion: db "Armorpion", $F0
MonsterName_129_Digster: db "Digster", $F0
MonsterName_130_Pixy: db "Pixy", $F0
MonsterName_131_ArcDemon: db "ArcDemon", $F0
MonsterName_132_AgDevil: db "AgDevil", $F0
MonsterName_133_Demonite: db "Demonite", $F0
MonsterName_134_DarkEye: db "DarkEye", $F0
MonsterName_135_EyeBall: db "EyeBall", $F0
MonsterName_136_SkulRider: db "SkulRider", $F0
MonsterName_137_EvilBeast: db "EvilBeast", $F0
MonsterName_138_1EyeClown: db "1EyeClown", $F0
MonsterName_139_Gremlin: db "Gremlin", $F0
MonsterName_140_MedusaEye: db "MedusaEye", $F0
MonsterName_141_Lionex: db "Lionex", $F0
MonsterName_142_GoatHorn: db "GoatHorn", $F0
MonsterName_143_Orc: db "Orc", $F0
MonsterName_144_Ogre: db "Ogre", $F0
MonsterName_145_GateGuard: db "GateGuard", $F0
MonsterName_146_ChopClown: db "ChopClown", $F0
MonsterName_147_Grendal: db "Grendal", $F0
MonsterName_148_Akubar: db "Akubar", $F0
MonsterName_149_MadKnight: db "MadKnight", $F0
MonsterName_150_Gigantes: db "Gigantes", $F0
MonsterName_151_Centasaur: db "Centasaur", $F0
MonsterName_152_EvilArmor: db "EvilArmor", $F0
MonsterName_153_Jamirus: db "Jamirus", $F0
MonsterName_154_Durran: db "Durran", $F0
MonsterName_155_Spooky: db "Spooky", $F0
MonsterName_156_Skullgon: db "Skullgon", $F0
MonsterName_157_Putrepup: db "Putrepup", $F0
MonsterName_158_RotRaven: db "RotRaven", $F0
MonsterName_159_Mummy: db "Mummy", $F0
MonsterName_160_DarkCrab: db "DarkCrab", $F0
MonsterName_161_DeadNite: db "DeadNite", $F0
MonsterName_162_Shadow: db "Shadow", $F0
MonsterName_163_Hork: db "Hork", $F0
MonsterName_164_Mudron: db "Mudron", $F0
MonsterName_165_NiteWhip: db "NiteWhip", $F0
MonsterName_166_MadSpirit: db "MadSpirit", $F0
MonsterName_167_WindMerge: db "WindMerge", $F0
MonsterName_168_Reaper: db "Reaper", $F0
MonsterName_169_DeadNoble: db "DeadNoble", $F0
MonsterName_170_WhiteKing: db "WhiteKing", $F0
MonsterName_171_BoneSlave: db "BoneSlave", $F0
MonsterName_172_Skeletor: db "Skeletor", $F0
MonsterName_173_Servant: db "Servant", $F0
MonsterName_174_Copycat: db "Copycat", $F0
MonsterName_175_JewelBag: db "JewelBag", $F0
MonsterName_176_EvilWand: db "EvilWand", $F0
MonsterName_177_MadCandle: db "MadCandle", $F0
MonsterName_178_CoilBird: db "CoilBird", $F0
MonsterName_179_Facer: db "Facer", $F0
MonsterName_180_SpikyBoy: db "SpikyBoy", $F0
MonsterName_181_MadMirror: db "MadMirror", $F0
MonsterName_182_RogueNite: db "RogueNite", $F0
MonsterName_183_Goopi: db "Goopi", $F0
MonsterName_184_Voodoll: db "Voodoll", $F0
MonsterName_185_MetalDrak: db "MetalDrak", $F0
MonsterName_186_Balzak: db "Balzak", $F0
MonsterName_187_SabreMan: db "SabreMan", $F0
MonsterName_188_CurseLamp: db "CurseLamp", $F0
MonsterName_189_Roboster: db "Roboster", $F0
MonsterName_190_EvilPot: db "EvilPot", $F0
MonsterName_191_Gismo: db "Gismo", $F0
MonsterName_192_LavaMan: db "LavaMan", $F0
MonsterName_193_IceMan: db "IceMan", $F0
MonsterName_194_Mimic: db "Mimic", $F0
MonsterName_195_MudDoll: db "MudDoll", $F0
MonsterName_196_Golem: db "Golem", $F0
MonsterName_197_StoneMan: db "StoneMan", $F0
MonsterName_198_BombCrag: db "BombCrag", $F0
MonsterName_199_GoldGolem: db "GoldGolem", $F0
MonsterName_200_DracoLord: db "DracoLord", $F0
MonsterName_201_DracoLord: db "DracoLord", $F0
MonsterName_202_Hargon: db "Hargon", $F0
MonsterName_203_Sidoh: db "Sidoh", $F0
MonsterName_204_Baramos: db "Baramos", $F0
MonsterName_205_Zoma: db "Zoma", $F0
MonsterName_206_Pizzaro: db "Pizzaro", $F0
MonsterName_207_Esterk: db "Esterk", $F0
MonsterName_208_Mirudraas: db "Mirudraas", $F0
MonsterName_209_Mirudraas: db "Mirudraas", $F0
MonsterName_210_Mudou: db "Mudou", $F0
MonsterName_211_DeathMore: db "DeathMore", $F0
MonsterName_212_DeathMore: db "DeathMore", $F0
MonsterName_213_DeathMore: db "DeathMore", $F0
MonsterName_214_Darkdrium: db "Darkdrium", $F0
MonsterName_215_TERRY: db "TERRY?", $F0
MonsterName_216_Tatsu: db "Tatsu", $F0
MonsterName_217_Diago: db "Diago", $F0
MonsterName_218_Samsi: db "Samsi", $F0
MonsterName_219_Bazoo: db "Bazoo", $F0
MonsterName_220_Unused_220: db $F0
MonsterName_225_Unused_225: db "?????", $F0

; ---------------------------------------------------------------
; Skill Name Strings ($628E)
; 222 unique entries + 1 empty terminator, $F0 terminated
; Pointer table at $4539 references these by label
; Entries 222-255 in the pointer table point to the empty entry
; ---------------------------------------------------------------

SkillNameStrings:
SkillName_000_Blaze: db "Blaze", $F0
SkillName_001_Blazemore: db "Blazemore", $F0
SkillName_002_Blazemost: db "Blazemost", $F0
SkillName_003_Firebal: db "Firebal", $F0
SkillName_004_Firebane: db "Firebane", $F0
SkillName_005_Firebolt: db "Firebolt", $F0
SkillName_006_Bang: db "Bang", $F0
SkillName_007_Boom: db "Boom", $F0
SkillName_008_Explodet: db "Explodet", $F0
SkillName_009_Infernos: db "Infernos", $F0
SkillName_010_Infermore: db "Infermore", $F0
SkillName_011_Infermost: db "Infermost", $F0
SkillName_012_IceBolt: db "IceBolt", $F0
SkillName_013_SnowStorm: db "SnowStorm", $F0
SkillName_014_Blizzard: db "Blizzard", $F0
SkillName_015_Bolt: db "Bolt", $F0
SkillName_016_Zap: db "Zap", $F0
SkillName_017_Thordain: db "Thordain", $F0
SkillName_018_Beat: db "Beat", $F0
SkillName_019_Defeat: db "Defeat", $F0
SkillName_020_Sacrifice: db "Sacrifice", $F0
SkillName_021_Sleep: db "Sleep", $F0
SkillName_022_SleepAll: db "SleepAll", $F0
SkillName_023_StopSpell: db "StopSpell", $F0
SkillName_024_Surround: db "Surround", $F0
SkillName_025_PanicAll: db "PanicAll", $F0
SkillName_026_RobMagic: db "RobMagic", $F0
SkillName_027_TakeMagic: db "TakeMagic", $F0
SkillName_028_Sap: db "Sap", $F0
SkillName_029_Defence: db "Defence", $F0
SkillName_030_Upper: db "Upper", $F0
SkillName_031_Increase: db "Increase", $F0
SkillName_032_Slow: db "Slow", $F0
SkillName_033_SlowAll: db "SlowAll", $F0
SkillName_034_Speed: db "Speed", $F0
SkillName_035_SpeedUp: db "SpeedUp", $F0
SkillName_036_Barrier: db "Barrier", $F0
SkillName_037_TwinHits: db "TwinHits", $F0
SkillName_038_MagicWall: db "MagicWall", $F0
SkillName_039_MagicBack: db "MagicBack", $F0
SkillName_040_Bounce: db "Bounce", $F0
SkillName_041_Transform: db "Transform", $F0
SkillName_042_Ironize: db "Ironize", $F0
SkillName_043_Heal: db "Heal", $F0
SkillName_044_HealMore: db "HealMore", $F0
SkillName_045_HealAll: db "HealAll", $F0
SkillName_046_HealUs: db "HealUs", $F0
SkillName_047_HealUsAll: db "HealUsAll", $F0
SkillName_048_Vivify: db "Vivify", $F0
SkillName_049_Revive: db "Revive", $F0
SkillName_050_Farewell: db "Farewell", $F0
SkillName_051_Antidote: db "Antidote", $F0
SkillName_052_NumbOff: db "NumbOff", $F0
SkillName_053_DeChaos: db "DeChaos", $F0
SkillName_054_CurseOff: db "CurseOff", $F0
SkillName_055_StepGuard: db "StepGuard", $F0
SkillName_056_MapMagic: db "MapMagic", $F0
SkillName_057_Chance: db "Chance", $F0
SkillName_058_Attack: db "Attack", $F0
SkillName_059_TwinSlash: db "TwinSlash", $F0
SkillName_060_Ramming: db "Ramming", $F0
SkillName_061_Beserker: db "Beserker", $F0
SkillName_062_Kamikaze: db "Kamikaze", $F0
SkillName_063_Massacre: db "Massacre", $F0
SkillName_064_EvilSlash: db "EvilSlash", $F0
SkillName_065_ChargeUP: db "ChargeUP", $F0
SkillName_066_HighJump: db "HighJump", $F0
SkillName_067_SuckAir: db "SuckAir", $F0
SkillName_068_FireSlash: db "FireSlash", $F0
SkillName_069_BoltSlash: db "BoltSlash", $F0
SkillName_070_VacuSlash: db "VacuSlash", $F0
SkillName_071_IceSlash: db "IceSlash", $F0
SkillName_072_MetalCut: db "MetalCut", $F0
SkillName_073_DrakSlash: db "DrakSlash", $F0
SkillName_074_BeastCut: db "BeastCut", $F0
SkillName_075_BirdBlow: db "BirdBlow", $F0
SkillName_076_DevilCut: db "DevilCut", $F0
SkillName_077_ZombieCut: db "ZombieCut", $F0
SkillName_078_CleanCut: db "CleanCut", $F0
SkillName_079_MultiCut: db "MultiCut", $F0
SkillName_080_BiAttack: db "BiAttack", $F0
SkillName_081_QuadHits: db "QuadHits", $F0
SkillName_082_CallHelp: db "CallHelp", $F0
SkillName_083_YellHelp: db "YellHelp", $F0
SkillName_084_Focus: db "Focus", $F0
SkillName_085_SquallHit: db "SquallHit", $F0
SkillName_086_PsycheUp: db "PsycheUp", $F0
SkillName_087_RainSlash: db "RainSlash", $F0
SkillName_088_WindBeast: db "WindBeast", $F0
SkillName_089_Vacuum: db "Vacuum", $F0
SkillName_090_Lightning: db "Lightning", $F0
SkillName_091_RockThrow: db "RockThrow", $F0
SkillName_092_FireAir: db "FireAir", $F0
SkillName_093_BlazeAir: db "BlazeAir", $F0
SkillName_094_Scorching: db "Scorching", $F0
SkillName_095_WhiteFire: db "WhiteFire", $F0
SkillName_096_FrigidAir: db "FrigidAir", $F0
SkillName_097_IceAir: db "IceAir", $F0
SkillName_098_IceStorm: db "IceStorm", $F0
SkillName_099_WhiteAir: db "WhiteAir", $F0
SkillName_100_Hellblast: db "Hellblast", $F0
SkillName_101_BigBang: db "BigBang", $F0
SkillName_102_MegaMagic: db "MegaMagic", $F0
SkillName_103_PoisonHit: db "PoisonHit", $F0
SkillName_104_NapAttack: db "NapAttack", $F0
SkillName_105_Paralyze: db "Paralyze", $F0
SkillName_106_SleepAir: db "SleepAir", $F0
SkillName_107_PalsyAir: db "PalsyAir", $F0
SkillName_108_PoisonGas: db "PoisonGas", $F0
SkillName_109_PoisonAir: db "PoisonAir", $F0
SkillName_110_PaniDance: db "PaniDance", $F0
SkillName_111_Curse: db "Curse", $F0
SkillName_112_Ahhh: db "Ahhh", $F0
SkillName_113_KODance: db "K.O.Dance", $F0
SkillName_114_SandStorm: db "SandStorm", $F0
SkillName_115_Radiant: db "Radiant", $F0
SkillName_116_EerieLite: db "EerieLite", $F0
SkillName_117_OddDance: db "OddDance", $F0
SkillName_118_RobDance: db "RobDance", $F0
SkillName_119_SideStep: db "SideStep", $F0
SkillName_120_LureDance: db "LureDance", $F0
SkillName_121_LushLicks: db "LushLicks", $F0
SkillName_122_SickLick: db "SickLick", $F0
SkillName_123_LegSweep: db "LegSweep", $F0
SkillName_124_BigTrip: db "BigTrip", $F0
SkillName_125_WarCry: db "WarCry", $F0
SkillName_126_Whistle: db "Whistle", $F0
SkillName_127_Imitate: db "Imitate", $F0
SkillName_128_DeMagic: db "DeMagic", $F0
SkillName_129_Surge: db "Surge", $F0
SkillName_130_UltraDown: db "UltraDown", $F0
SkillName_131_ThickFog: db "ThickFog", $F0
SkillName_132_TatsuCall: db "TatsuCall", $F0
SkillName_133_DiagoCall: db "DiagoCall", $F0
SkillName_134_SamsiCall: db "SamsiCall", $F0
SkillName_135_BazooCall: db "BazooCall", $F0
SkillName_136_Cover: db "Cover", $F0
SkillName_137_Guardian: db "Guardian", $F0
SkillName_138_TailWind: db "TailWind", $F0
SkillName_139_StormWind: db "StormWind", $F0
SkillName_140_Dodge: db "Dodge", $F0
SkillName_141_Defence: db "Defence", $F0
SkillName_142_StrongD: db "StrongD", $F0
SkillName_143_SuckAll: db "SuckAll", $F0
SkillName_144_BladeD: db "BladeD", $F0
SkillName_145_DanceShut: db "DanceShut", $F0
SkillName_146_MouthShut: db "MouthShut", $F0
SkillName_147_Meditate: db "Meditate", $F0
SkillName_148_Hustle: db "Hustle", $F0
SkillName_149_LifeSong: db "LifeSong", $F0
SkillName_150_LifeDance: db "LifeDance", $F0
SkillName_151_Run: db "Run", $F0
SkillName_152_Daze: db "Daze", $F0
SkillName_153_HitAlly: db "HitAlly", $F0
SkillName_154_HitEnemy: db "HitEnemy", $F0
SkillName_155_HitRandom: db "HitRandom", $F0
SkillName_156_Scared: db "Scared", $F0
SkillName_157_Dance: db "Dance", $F0
SkillName_158_Trip: db "Trip", $F0
SkillName_159_Paralyze: db "Paralyze", $F0
SkillName_160_CANTMOVE: db "CANTMOVE", $F0
SkillName_161_RUN: db "RUN", $F0
SkillName_162_CALLHOROR: db "CALLHOROR", $F0
SkillName_163_HealUsAll: db "HealUsAll", $F0
SkillName_164_Smashed: db "Smashed", $F0
SkillName_165_FILTHZONE: db "FILTHZONE", $F0
SkillName_166_ALLCHANGE: db "ALLCHANGE", $F0
SkillName_167_BIGSLEEP: db "BIGSLEEP", $F0
SkillName_168_MP0: db "MP0", $F0
SkillName_169_ECHO: db "ECHO", $F0
SkillName_170_CHGDRAGON: db "CHGDRAGON", $F0
SkillName_171_CALLEVIL: db "CALLEVIL", $F0
SkillName_172_FREEZY: db "FREEZY", $F0
SkillName_173_ALLREVIVE: db "ALLREVIVE", $F0
SkillName_174_RESTOREMP: db "RESTOREMP", $F0
SkillName_175_METEOR: db "METEOR", $F0
SkillName_176_HERB: db "HERB", $F0
SkillName_177_HEALWATER: db "HEALWATER", $F0
SkillName_178_SAGESTONE: db "SAGESTONE", $F0
SkillName_179_WARLDDEW: db "WARLDDEW", $F0
SkillName_180_POTION: db "POTION", $F0
SkillName_181_ELFWATER: db "ELFWATER", $F0
SkillName_182_ANTIDOTE: db "ANTIDOTE", $F0
SkillName_183_MOONHERB: db "MOONHERB", $F0
SkillName_184_SKYBELL: db "SKYBELL", $F0
SkillName_185_LAUREL: db "LAUREL", $F0
SkillName_186_AWAKESAND: db "AWAKESAND", $F0
SkillName_187_WARLDLEAF: db "WARLDLEAF", $F0
SkillName_188_LIFEACORN: db "LIFEACORN", $F0
SkillName_189_MYSTICNUT: db "MYSTICNUT", $F0
SkillName_190_PWRSEED: db "PWRSEED", $F0
SkillName_191_DEFSEED: db "DEFSEED", $F0
SkillName_192_AGILSEED: db "AGILSEED", $F0
SkillName_193_INTSEED: db "INTSEED", $F0
SkillName_194_FEEDMEAT: db "FEEDMEAT", $F0
SkillName_195_BEFFJERKY: db "BEFFJERKY", $F0
SkillName_196_PORKCHOP: db "PORKCHOP", $F0
SkillName_197_BADMEAT: db "BADMEAT", $F0
SkillName_198_SIRLOIN: db "SIRLOIN", $F0
SkillName_199_BOLTSTAFF: db "BOLTSTAFF", $F0
SkillName_200_STAFF: db "STAFF", $F0
SkillName_201_BLOKSTAFF: db "BLOKSTAFF", $F0
SkillName_202_LAVASTAFF: db "LAVASTAFF", $F0
SkillName_203_SNOWSTAFF: db "SNOWSTAFF", $F0
SkillName_204_FIRESTAFF: db "FIRESTAFF", $F0
SkillName_205_WARPWING: db "WARPWING", $F0
SkillName_206_TINYMEDAL: db "TINYMEDAL", $F0
SkillName_207_QuestBk: db "QuestBk", $F0
SkillName_208_HORRORBK: db "HORRORBK", $F0
SkillName_209_BENICEBK: db "BENICEBK", $F0
SkillName_210_CHEATERBK: db "CHEATERBK", $F0
SkillName_211_SMARTBK: db "SMARTBK", $F0
SkillName_212_COMEDYBK: db "COMEDYBK", $F0
SkillName_213_BeDragon: db "BeDragon", $F0
SkillName_214_Smashlime: db "Smashlime", $F0
SkillName_215_BugCut: db "BugCut", $F0, $F0, $F0, $F0  ; was "Sheldodge" (placeholder); id 215 = Bug-family cut (family code $05). 3 trailing $F0 pad keeps the 10-byte slot so downstream strings don't shift.
SkillName_216_Branching: db "Branching", $F0
SkillName_217_GigaSlash: db "GigaSlash", $F0
SkillName_218_LIFE: db "LIFE", $F0
SkillName_219_RUN: db "RUN", $F0
SkillName_220_IRONIZE: db "IRONIZE", $F0
SkillName_221_Ahhh: db "Ahhh", $F0
SkillName_222_Unused_222: db $F0

; ---------------------------------------------------------------
; Family Code Strings ($69F2-$6C77)
; 2-letter family abbreviation + $F0 terminator
; Indexed by FamilyCodePtrTable at $4739
; ---------------------------------------------------------------

FamilyCodeStrings:
FamilyCode_000_DS: db "DS", $F0
FamilyCode_001_SP: db "SP", $F0
FamilyCode_002_WS: db "WS", $F0
FamilyCode_003_TS: db "TS", $F0
FamilyCode_004_SN: db "SN", $F0
FamilyCode_005_KN: db "KN", $F0
FamilyCode_006_BB: db "BB", $F0
FamilyCode_007_BX: db "BX", $F0
FamilyCode_008_SL: db "SL", $F0
FamilyCode_009_HL: db "HL", $F0
FamilyCode_010_FS: db "FS", $F0
FamilyCode_011_RS: db "RS", $F0
FamilyCode_012_SB: db "SB", $F0
FamilyCode_013_ST: db "ST", $F0
FamilyCode_014_SK: db "SK", $F0
FamilyCode_015_KS: db "KS", $F0
FamilyCode_016_MK: db "MK", $F0
FamilyCode_017_MB: db "MB", $F0
FamilyCode_018_MT: db "MT", $F0
FamilyCode_019_GS: db "GS", $F0
FamilyCode_020_DK: db "DK", $F0
FamilyCode_021_TG: db "TG", $F0
FamilyCode_022_PT: db "PT", $F0
FamilyCode_023_BG: db "BG", $F0
FamilyCode_024_BD: db "BD", $F0
FamilyCode_025_LM: db "LM", $F0
FamilyCode_026_PG: db "PG", $F0
FamilyCode_027_SD: db "SD", $F0
FamilyCode_028_DR: db "DR", $F0
FamilyCode_029_MD: db "MD", $F0
FamilyCode_030_DK: db "DK", $F0
FamilyCode_031_RB: db "RB", $F0
FamilyCode_032_CH: db "CH", $F0
FamilyCode_033_LF: db "LF", $F0
FamilyCode_034_AD: db "AD", $F0
FamilyCode_035_LC: db "LC", $F0
FamilyCode_036_SS: db "SS", $F0
FamilyCode_037_GD: db "GD", $F0
FamilyCode_038_CP: db "CP", $F0
FamilyCode_039_WS: db "WS", $F0
FamilyCode_040_CT: db "CT", $F0
FamilyCode_041_OR: db "OR", $F0
FamilyCode_042_BR: db "BR", $F0
FamilyCode_043_SD: db "SD", $F0
FamilyCode_044_DG: db "DG", $F0
FamilyCode_045_TG: db "TG", $F0
FamilyCode_046_HB: db "HB", $F0
FamilyCode_047_CF: db "CF", $F0
FamilyCode_048_PR: db "PR", $F0
FamilyCode_049_SC: db "SC", $F0
FamilyCode_050_GB: db "GB", $F0
FamilyCode_051_SL: db "SL", $F0
FamilyCode_052_WB: db "WB", $F0
FamilyCode_053_AE: db "AE", $F0
FamilyCode_054_ST: db "ST", $F0
FamilyCode_055_IT: db "IT", $F0
FamilyCode_056_MM: db "MM", $F0
FamilyCode_057_HM: db "HM", $F0
FamilyCode_058_GZ: db "GZ", $F0
FamilyCode_059_YT: db "YT", $F0
FamilyCode_060_MG: db "MG", $F0
FamilyCode_061_FR: db "FR", $F0
FamilyCode_062_UC: db "UC", $F0
FamilyCode_063_GG: db "GG", $F0
FamilyCode_064_KA: db "KA", $F0
FamilyCode_065_TP: db "TP", $F0
FamilyCode_066_KL: db "KL", $F0
FamilyCode_067_DH: db "DH", $F0
FamilyCode_068_MC: db "MC", $F0
FamilyCode_069_BE: db "BE", $F0
FamilyCode_070_PK: db "PK", $F0
FamilyCode_071_WV: db "WV", $F0
FamilyCode_072_BB: db "BB", $F0
FamilyCode_073_FJ: db "FJ", $F0
FamilyCode_074_DK: db "DK", $F0
FamilyCode_075_MP: db "MP", $F0
FamilyCode_076_MR: db "MR", $F0
FamilyCode_077_MW: db "MW", $F0
FamilyCode_078_DK: db "DK", $F0
FamilyCode_079_BR: db "BR", $F0
FamilyCode_080_SB: db "SB", $F0
FamilyCode_081_LO: db "LO", $F0
FamilyCode_082_MG: db "MG", $F0
FamilyCode_083_MC: db "MC", $F0
FamilyCode_084_BZ: db "BZ", $F0
FamilyCode_085_PN: db "PN", $F0
FamilyCode_086_TH: db "TH", $F0
FamilyCode_087_WH: db "WH", $F0
FamilyCode_088_FB: db "FB", $F0
FamilyCode_089_RB: db "RB", $F0
FamilyCode_090_MP: db "MP", $F0
FamilyCode_091_FW: db "FW", $F0
FamilyCode_092_FM: db "FM", $F0
FamilyCode_093_WT: db "WT", $F0
FamilyCode_094_CB: db "CB", $F0
FamilyCode_095_GP: db "GP", $F0
FamilyCode_096_FG: db "FG", $F0
FamilyCode_097_AW: db "AW", $F0
FamilyCode_098_SS: db "SS", $F0
FamilyCode_099_ON: db "ON", $F0
FamilyCode_100_DV: db "DV", $F0
FamilyCode_101_TB: db "TB", $F0
FamilyCode_102_FT: db "FT", $F0
FamilyCode_103_HM: db "HM", $F0
FamilyCode_104_BM: db "BM", $F0
FamilyCode_105_ES: db "ES", $F0
FamilyCode_106_ME: db "ME", $F0
FamilyCode_107_SP: db "SP", $F0
FamilyCode_108_OV: db "OV", $F0
FamilyCode_109_WT: db "WT", $F0
FamilyCode_110_GS: db "GS", $F0
FamilyCode_111_CP: db "CP", $F0
FamilyCode_112_GC: db "GC", $F0
FamilyCode_113_BF: db "BF", $F0
FamilyCode_114_WB: db "WB", $F0
FamilyCode_115_GW: db "GW", $F0
FamilyCode_116_LP: db "LP", $F0
FamilyCode_117_SB: db "SB", $F0
FamilyCode_118_AA: db "AA", $F0
FamilyCode_119_GH: db "GH", $F0
FamilyCode_120_TE: db "TE", $F0
FamilyCode_121_AP: db "AP", $F0
FamilyCode_122_ED: db "ED", $F0
FamilyCode_123_GM: db "GM", $F0
FamilyCode_124_DR: db "DR", $F0
FamilyCode_125_AC: db "AC", $F0
FamilyCode_126_MH: db "MH", $F0
FamilyCode_127_HB: db "HB", $F0
FamilyCode_128_AP: db "AP", $F0
FamilyCode_129_DG: db "DG", $F0
FamilyCode_130_PX: db "PX", $F0
FamilyCode_131_AD: db "AD", $F0
FamilyCode_132_AD: db "AD", $F0
FamilyCode_133_DM: db "DM", $F0
FamilyCode_134_DE: db "DE", $F0
FamilyCode_135_EB: db "EB", $F0
FamilyCode_136_BR: db "BR", $F0
FamilyCode_137_EB: db "EB", $F0
FamilyCode_138_1E: db "1E", $F0
FamilyCode_139_GR: db "GR", $F0
FamilyCode_140_MD: db "MD", $F0
FamilyCode_141_LX: db "LX", $F0
FamilyCode_142_GH: db "GH", $F0
FamilyCode_143_OC: db "OC", $F0
FamilyCode_144_OG: db "OG", $F0
FamilyCode_145_GG: db "GG", $F0
FamilyCode_146_CC: db "CC", $F0
FamilyCode_147_GR: db "GR", $F0
FamilyCode_148_AK: db "AK", $F0
FamilyCode_149_MK: db "MK", $F0
FamilyCode_150_GG: db "GG", $F0
FamilyCode_151_CS: db "CS", $F0
FamilyCode_152_EA: db "EA", $F0
FamilyCode_153_JA: db "JA", $F0
FamilyCode_154_DR: db "DR", $F0
FamilyCode_155_SP: db "SP", $F0
FamilyCode_156_SK: db "SK", $F0
FamilyCode_157_DZ: db "DZ", $F0
FamilyCode_158_RR: db "RR", $F0
FamilyCode_159_MM: db "MM", $F0
FamilyCode_160_DC: db "DC", $F0
FamilyCode_161_DN: db "DN", $F0
FamilyCode_162_SH: db "SH", $F0
FamilyCode_163_PT: db "PT", $F0
FamilyCode_164_MD: db "MD", $F0
FamilyCode_165_NW: db "NW", $F0
FamilyCode_166_ES: db "ES", $F0
FamilyCode_167_WM: db "WM", $F0
FamilyCode_168_ST: db "ST", $F0
FamilyCode_169_DN: db "DN", $F0
FamilyCode_170_IK: db "IK", $F0
FamilyCode_171_BS: db "BS", $F0
FamilyCode_172_SK: db "SK", $F0
FamilyCode_173_SV: db "SV", $F0
FamilyCode_174_CC: db "CC", $F0
FamilyCode_175_JB: db "JB", $F0
FamilyCode_176_EW: db "EW", $F0
FamilyCode_177_MC: db "MC", $F0
FamilyCode_178_CB: db "CB", $F0
FamilyCode_179_MK: db "MK", $F0
FamilyCode_180_SB: db "SB", $F0
FamilyCode_181_MM: db "MM", $F0
FamilyCode_182_RA: db "RA", $F0
FamilyCode_183_MH: db "MH", $F0
FamilyCode_184_VD: db "VD", $F0
FamilyCode_185_DM: db "DM", $F0
FamilyCode_186_BZ: db "BZ", $F0
FamilyCode_187_SM: db "SM", $F0
FamilyCode_188_CL: db "CL", $F0
FamilyCode_189_KB: db "KB", $F0
FamilyCode_190_EP: db "EP", $F0
FamilyCode_191_GZ: db "GZ", $F0
FamilyCode_192_LM: db "LM", $F0
FamilyCode_193_IC: db "IC", $F0
FamilyCode_194_MM: db "MM", $F0
FamilyCode_195_MD: db "MD", $F0
FamilyCode_196_GL: db "GL", $F0
FamilyCode_197_MS: db "MS", $F0
FamilyCode_198_BC: db "BC", $F0
FamilyCode_199_GG: db "GG", $F0
FamilyCode_200_DL: db "DL", $F0
FamilyCode_201_DL: db "DL", $F0
FamilyCode_202_HG: db "HG", $F0
FamilyCode_203_SD: db "SD", $F0
FamilyCode_204_BM: db "BM", $F0
FamilyCode_205_ZM: db "ZM", $F0
FamilyCode_206_PZ: db "PZ", $F0
FamilyCode_207_ES: db "ES", $F0
FamilyCode_208_MD: db "MD", $F0
FamilyCode_209_MD: db "MD", $F0
FamilyCode_210_MD: db "MD", $F0
FamilyCode_211_DM: db "DM", $F0
FamilyCode_212_DM: db "DM", $F0
FamilyCode_213_DM: db "DM", $F0
FamilyCode_214_DD: db "DD", $F0
ItemName_00_Empty: db $F0  ; no item

; ---------------------------------------------------------------
; Item Name Strings ($6C78-$6DF7)
; 43 items, $F0 terminated, charmap encoded
; Indexed by ItemNamePtrTable at $48E7
; ---------------------------------------------------------------

ItemNameStrings:
ItemName_01_Herb: db "Herb", $F0
ItemName_02_Lovewater: db "Lovewater", $F0
ItemName_03_SageStone: db "SageStone", $F0
ItemName_04_WorldDew: db "WorldDew", $F0
ItemName_05_Potion: db "Potion", $F0
ItemName_06_ElfWater: db "ElfWater", $F0
ItemName_07_Antidote: db "Antidote", $F0
ItemName_08_MoonHerb: db "MoonHerb", $F0
ItemName_09_SkyBell: db "SkyBell", $F0
ItemName_10_Laurel: db "Laurel", $F0
ItemName_11_AwakeSand: db "AwakeSand", $F0
ItemName_12_WorldLeaf: db "WorldLeaf", $F0
ItemName_13_LifeAcorn: db "LifeAcorn", $F0
ItemName_14_MysticNut: db "MysticNut", $F0
ItemName_15_ATKseed: db "ATKseed", $F0
ItemName_16_DEFseed: db "DEFseed", $F0
ItemName_17_AGLseed: db "AGLseed", $F0
ItemName_18_INTseed: db "INTseed", $F0
ItemName_19_BeefJerky: db "BeefJerky", $F0
ItemName_20_PorkChop: db "PorkChop", $F0
ItemName_21_Rib: db "Rib", $F0
ItemName_22_BadMeat: db "BadMeat", $F0
ItemName_23_Sirloin: db "Sirloin", $F0
ItemName_24_BoltStaff: db "BoltStaff", $F0
ItemName_25_WindStaff: db "WindStaff", $F0
ItemName_26_MistStaff: db "MistStaff", $F0
ItemName_27_LavaStaff: db "LavaStaff", $F0
ItemName_28_SnowStaff: db "SnowStaff", $F0
ItemName_29_WarpWing: db "WarpWing", $F0
ItemName_30_TinyMedal: db "TinyMedal", $F0
ItemName_31_QuestBk: db "QuestBk", $F0
ItemName_32_HorrorBK: db "HorrorBK", $F0
ItemName_33_BeNiceBK: db "BeNiceBK", $F0
ItemName_34_CheaterBK: db "CheaterBK", $F0
ItemName_35_SmartBK: db "SmartBK", $F0
ItemName_36_ComedyBK: db "ComedyBK", $F0
ItemName_37_FireStaff: db "FireStaff", $F0
ItemName_38_BeastTail: db "BeastTail", $F0
ItemName_39_WarpStaff: db "WarpStaff", $F0
ItemName_40_Repellent: db "Repellent", $F0
ItemName_41_ShinyHarp: db "ShinyHarp", $F0
ItemName_42_MapHerb: db "MapHerb", $F0
ItemName_43_BookMark: db "BookMark", $F0
ItemDesc_00: db $F0  ; no description

; ---------------------------------------------------------------
; Item Description Strings ($6DF8-$7158)
; 43 entries with control codes ($F1=newline)
; Indexed by ItemDescPtrTable at $493F
; ---------------------------------------------------------------

ItemDescStrings:
ItemDesc_01: db "Restores between", $F1, "30 to 40 HP", $F0  ; Herb
ItemDesc_02: db "Restores between", $F1, "60 to 70 HP", $F0  ; Lovewater
ItemDesc_03: db "Restores 60 to", $F1, "70 HP for all", $F0  ; SageStone
ItemDesc_04: db "Restores", $F1, "max HP for all", $F0  ; WorldDew
ItemDesc_05: db "Restores between", $F1, "20 to 30 MP", $F0  ; Potion
ItemDesc_06: db "Restores MP to", $F1, "max", $F0  ; ElfWater
ItemDesc_07: db "Cures poison", $F1, $F0  ; Antidote
ItemDesc_08: db "Cures", $F1, "paralysis", $F0  ; MoonHerb
ItemDesc_09: db "Cures confusion", $F1, $F0  ; SkyBell
ItemDesc_10: db "Breaks a curse", $F0  ; Laurel
ItemDesc_11: db "Wakes up an ally", $F0  ; AwakeSand
ItemDesc_12: db "Revives an ally", $F0  ; WorldLeaf
ItemDesc_13: db "Increases max HP", $F1, "by 5", $F0  ; LifeAcorn
ItemDesc_14: db "Increases max MP", $F1, "by 5", $F0  ; MysticNut
ItemDesc_15: db "Increases ATTACK", $F1, "Power by 3", $F0  ; ATKseed
ItemDesc_16: db "Increases DEFENSE", $F1, "power by 3", $F0  ; DEFseed
ItemDesc_17: db "Increases AGILITY ", $F1, "by 3", $F0  ; AGLseed
ItemDesc_18: db "Increases", $F1, "INTELLIGENCE by 3", $F0  ; INTseed
ItemDesc_19: db "Tames monsters", $F1, $F0  ; BeefJerky
ItemDesc_24: db "Makes damage with", $F1, "a lightning bolt", $F0  ; BoltStaff
ItemDesc_25: db "Makes damage with", $F1, "a vacuum", $F0  ; WindStaff
ItemDesc_26: db "Blocks spells", $F1, "with a mist", $F0  ; MistStaff
ItemDesc_27: db "Makes damage with", $F1, "magma", $F0  ; LavaStaff
ItemDesc_28: db "Makes damage with", $F1, "a snow storm", $F0  ; SnowStaff
ItemDesc_29: db "Warps back to", $F1, "castle instantly", $F0  ; WarpWing
ItemDesc_30: db "Collect it to", $F1, "exchange for items", $F0  ; TinyMedal
ItemDesc_31: db "Changes monster", $68, $F1, "Personality", $F0  ; QuestBk
ItemDesc_37: db "Burns enemies with", $F1, "a mighty blaze", $F0  ; FireStaff
ItemDesc_38: db "Points the way to", $F1, "a mystic hole", $F0  ; BeastTail
ItemDesc_39: db "Warps to a", $F1, "mystic hole", $F0  ; WarpStaff
ItemDesc_40: db "Repels monsters", $F0  ; Repellent
ItemDesc_41: db "Attracts monsters", $F1, "with its melody", $F0  ; ShinyHarp
ItemDesc_42: db "Lets you see the", $F1, "entire landscape", $F0  ; MapHerb
ItemDesc_43: db "Records progress", $F1, "in your Journal", $F0  ; BookMark

; ---------------------------------------------------------------
; Personality Name Strings ($7159-$7228)
; 27 entries, $F0 terminated
; Indexed by PersonalityNamePtrTable at $4997
; ---------------------------------------------------------------

PersonalityNameStrings:
PersonalityName_00_HOTBLOOD: db "HOTBLOOD", $F0
PersonalityName_01_DARING: db "DARING", $F0
PersonalityName_02_DAREDEVIL: db "DAREDEVIL", $F0
PersonalityName_03_LONE_WOLF: db "LONE WOLF", $F0
PersonalityName_04_VAIN: db "VAIN", $F0
PersonalityName_05_EZ_GOING: db "EZ GOING", $F0
PersonalityName_06_SMUG: db "SMUG", $F0
PersonalityName_07_SNOBBY: db "SNOBBY", $F0
PersonalityName_08_RECKLESS: db "RECKLESS", $F0
PersonalityName_09_COOL_CALM: db "COOL", $9E, "CALM", $F0
PersonalityName_10_WHIMSY: db "WHIMSY", $F0
PersonalityName_11_NOSY: db "NOSY", $F0
PersonalityName_12_WHIZ_KID: db "WHIZ KID", $F0
PersonalityName_13_ORDINARY: db "ORDINARY", $F0
PersonalityName_14_HASTY: db "HASTY", $F0
PersonalityName_15_STUBBORN: db "STUBBORN", $F0
PersonalityName_16_REBEL: db "REBEL", $F0
PersonalityName_17_SPOILED: db "SPOILED", $F0
PersonalityName_18_HUMANE: db "HUMANE", $F0
PersonalityName_19_UNCERTAIN: db "UNCERTAIN", $F0
PersonalityName_20_CARELESS: db "CARELESS", $F0
PersonalityName_21_SHREWED: db "SHREWED", $F0
PersonalityName_22_CAREFREE: db "CAREFREE", $F0
PersonalityName_23_GULLIBLE: db "GULLIBLE", $F0
PersonalityName_24_SLY: db "SLY", $F0
PersonalityName_25_COWARD: db "COWARD", $F0
PersonalityName_26_LAZY: db "LAZY", $F0

; ---------------------------------------------------------------
; Game Text Strings ($7229-$7FFF)
; Battle tactics, level up messages, item/spell use text, etc.
; Contains control codes throughout
; ---------------------------------------------------------------

MiscText_00:
    db $26, $2B, $24, $35, $2A, $28, $F1, $30, $2C, $3B, $28, $27, $F1, $26, $24, $38  ; $7229
    db $37, $2C, $32, $38, $36, $F1, $26, $32, $30, $30, $24, $31, $27, $F0  ; $7239
MiscText_01:
    db $F9, $00, $62, $46, $4B, $40, $4F, $42, $3E, $50, $42, $50, $F1, $51, $4C, $62  ; $7247
    db $2F, $39, $62, $F9, $10, $63, $FA, $F7, $F0  ; $7257
MiscText_02:
    db $ED, $F9, $00, $62, $46, $4B, $40, $4F, $42, $3E, $50, $42, $50, $F1, $51, $4C  ; $7260
    db $62, $2F, $39, $62, $F9, $10, $FA, $F7, $F2, $3E, $4B, $41, $62, $49, $42, $3E  ; $7270
    db $4F, $4B, $42, $41, $F1, $F9, $20, $63, $FA, $F7, $F0  ; $7280
MiscText_03:
    db $ED, $F9, $00, $68, $62, $F9, $30, $F1, $3F, $42, $40, $4C, $4A, $42, $50, $62  ; $728B
    db $F9, $20, $63, $FA, $F7, $F0  ; $729B
MiscText_04:
    db $ED, $25, $52, $51, $62, $F9, $00, $F1, $40, $3E, $4B, $4B, $4C, $51, $62, $4A  ; $72A1
    db $3E, $50, $51, $42, $4F, $62, $3E, $4B, $56, $FA, $F7, $F2, $4A, $4C, $4F, $42  ; $72B1
    db $62, $50, $48, $46, $49, $49, $50, $63, $F1, $FA, $F7, $F2, $F3, $ED, $29, $4C  ; $72C1
    db $4F, $44, $42, $51, $62, $54, $45, $46, $40, $45, $F1, $50, $48, $46, $49, $49  ; $72D1
    db $64, $FA, $F7, $F0  ; $72E1
MiscText_05:
    db $ED, $32, $2E, $62, $51, $4C, $62, $43, $4C, $4F, $44, $42, $51, $F1, $F9, $00  ; $72E5
    db $64, $F0  ; $72F5
MiscText_06:
    db $ED, $29, $4C, $4F, $44, $42, $51, $50, $62, $F9, $00, $63, $FA, $F7, $F0  ; $72F7
MiscText_07:
    db $ED, $29, $4C, $4F, $44, $42, $51, $62, $54, $45, $46, $40, $45, $F1, $50, $48  ; $7306
    db $46, $49, $49, $64, $FA, $F7, $F0  ; $7316
MiscText_08:
    db $28, $53, $42, $4F, $56, $4C, $4B, $42, $F1, $4C, $4B, $42, $62, $3E, $51, $62  ; $731D
    db $3E, $62, $51, $46, $4A, $42, $5F, $F0  ; $732D
MiscText_09:
    db $3A, $45, $4C, $62, $38, $50, $62, $37, $45, $4A, $F0  ; $7335
MiscText_10:
    db $3A, $2B, $32, $36, $37, $35, $32, $2E, $F0  ; $7340
MiscText_11:
    db $29, $46, $44, $45, $51, $F0  ; $7349
MiscText_12:
    db $13, $DF, $12, $8D, $10, $1E, $11, $10, $8D, $D1, $8D, $10, $8D, $67, $F0  ; $734F
MiscText_13:
    db $ED, $F6, $62, $4F, $42, $40, $42, $46, $53, $42, $50, $F1, $F9, $00, $62, $28  ; $735E
    db $55, $4D, $62, $4D, $51, $50, $63, $FA, $F7, $F0  ; $736E
MiscText_15:
    db $ED, $F9, $00, $62, $3F, $56, $62, $40, $45, $3E, $4B, $40, $42, $5E, $F1, $4F  ; $7378
    db $42, $40, $3E, $49, $49, $50, $62, $F9, $20, $FA, $F7, $F2, $43, $4F, $4C, $4A  ; $7388
    db $62, $45, $46, $50, $62, $4A, $42, $4A, $4C, $4F, $56, $63, $F1, $FA, $F7, $F0  ; $7398
MiscText_16:
    db $ED, $3A, $4C, $54, $63, $62, $F9, $00, $F1, $44, $4C, $51, $62, $52, $4D, $62  ; $73A8
    db $3E, $4B, $41, $62, $46, $50, $FA, $F7, $F2, $49, $4C, $4C, $48, $46, $4B, $44  ; $73B8
    db $62, $3E, $51, $62, $52, $50, $63, $F1, $FA, $F7, $F2, $ED, $3A, $3E, $4B, $51  ; $73C8
    db $62, $51, $4C, $62, $51, $3E, $48, $42, $F1, $F9, $00, $62, $46, $4B, $51, $4C  ; $73D8
    db $FA, $F7, $F2, $56, $4C, $52, $4F, $62, $4D, $3E, $4F, $51, $56, $64, $F1, $F0  ; $73E8
MiscText_17:
    db $ED, $26, $3E, $4B, $4B, $4C, $51, $62, $51, $3E, $48, $42, $62, $3E, $4B, $56  ; $73F8
    db $F1, $4A, $4C, $4F, $42, $62, $4A, $4C, $4B, $50, $51, $42, $4F, $50, $63, $FA  ; $7408
    db $F7, $F2, $ED, $3A, $3E, $4B, $51, $62, $51, $4C, $62, $50, $3E, $56, $62, $3F  ; $7418
    db $56, $42, $F1, $51, $4C, $62, $4C, $4B, $42, $62, $4C, $43, $62, $56, $4C, $52  ; $7428
    db $4F, $FA, $F7, $F2, $4A, $4C, $4B, $50, $51, $42, $4F, $50, $62, $3E, $4B, $41  ; $7438
    db $62, $51, $3E, $48, $42, $F1, $3E, $62, $4B, $42, $54, $62, $4C, $4B, $42, $62  ; $7448
    db $46, $4B, $64, $F0  ; $7458
MiscText_18:
    db $ED, $F9, $00, $62, $49, $4C, $4C, $48, $50, $F1, $50, $3E, $41, $62, $3E, $4B  ; $745C
    db $41, $62, $49, $42, $3E, $53, $42, $50, $5F, $FA, $F7, $F0  ; $746C
MiscText_19:
    db $ED, $26, $45, $4C, $4C, $50, $42, $62, $3E, $62, $4A, $4C, $4B, $50, $51, $42  ; $7478
    db $4F, $F1, $51, $4C, $62, $4F, $42, $49, $42, $3E, $50, $42, $5F, $F0  ; $7488
MiscText_20:
    db $ED, $35, $42, $51, $52, $4F, $4B, $50, $62, $F9, $00, $F1, $51, $4C, $62, $51  ; $7496
    db $45, $42, $62, $54, $46, $49, $41, $5F, $FA, $F7, $F0  ; $74A6
MiscText_21:
    db $ED, $3A, $3E, $4B, $51, $62, $51, $4C, $62, $51, $3E, $48, $42, $F1, $F9, $00  ; $74B1
    db $FA, $F7, $F2, $54, $46, $51, $45, $62, $56, $4C, $52, $62, $4C, $4B, $F1, $56  ; $74C1
    db $4C, $52, $4F, $62, $4E, $52, $42, $50, $51, $64, $F0  ; $74D1
MiscText_22:
    db $ED, $F9, $00, $62, $45, $42, $3E, $41, $50, $F1, $51, $4C, $62, $51, $45, $42  ; $74DC
    db $62, $43, $3E, $4F, $4A, $5F, $FA, $F7, $F0  ; $74EC
MiscText_23:
    db $ED, $33, $49, $42, $3E, $50, $42, $62, $4B, $3E, $4A, $42, $F1, $F9, $00, $5F  ; $74F5
    db $FA, $F7, $F0  ; $7505
MiscText_24:
    db $ED, $26, $45, $4C, $4C, $50, $42, $62, $3E, $62, $4A, $4C, $4B, $50, $51, $42  ; $7508
    db $4F, $F1, $3F, $3E, $40, $48, $62, $51, $4C, $62, $43, $3E, $4F, $4A, $5F, $F0  ; $7518
MiscText_25:
    db $ED, $F9, $00, $62, $45, $42, $3E, $41, $50, $F1, $51, $4C, $62, $51, $45, $42  ; $7528
    db $62, $43, $3E, $4F, $4A, $5F, $FA, $F7, $F0  ; $7538
MiscText_26:
    db $ED, $3A, $45, $46, $40, $45, $62, $4C, $4B, $42, $64, $F0  ; $7541
MiscText_27:
    db $62, $62, $62, $62, $30, $32, $31, $28, $2A, $2A, $2C, $31, $29, $32, $F0  ; $754D
MiscText_28:
    db $ED, $31, $4C, $62, $42, $44, $44, $50, $5F, $FA, $F7, $F0  ; $755C
MiscText_29:
    db $ED, $35, $42, $51, $52, $4F, $4B, $50, $62, $51, $45, $42, $62, $42, $44, $44  ; $7568
    db $F1, $51, $4C, $62, $51, $45, $42, $62, $54, $46, $49, $41, $5F, $FA, $F7, $F0  ; $7578
MiscText_30:
    db $ED, $F9, $00, $E8, $08, $00, $30, $3E, $55, $62, $2B, $33, $62, $A2, $F9, $20  ; $7588
    db $E8, $00, $01, $2F, $39, $F9, $10, $E8, $08, $01, $30, $3E, $55, $62, $30, $33  ; $7598
    db $62, $A2, $F9, $24, $FA, $F7, $F2, $ED, $F9, $00, $E8, $08, $00, $24, $37, $2E  ; $75A8
    db $62, $A2, $F9, $28, $E8, $00, $01, $2F, $39, $F9, $10, $E8, $08, $01, $27, $28  ; $75B8
    db $29, $62, $A2, $F9, $2C, $FA, $F7, $F2, $ED, $F9, $00, $E8, $08, $00, $24, $2A  ; $75C8
    db $2F, $62, $A2, $F9, $30, $E8, $00, $01, $2F, $39, $F9, $10, $E8, $08, $01, $2C  ; $75D8
    db $31, $37, $62, $A2, $F9, $34, $FA, $F7, $F0  ; $75E8
MiscText_31:
    db $ED, $F9, $00, $E8, $08, $00, $30, $3E, $55, $62, $2B, $33, $62, $9C, $F9, $20  ; $75F1
    db $E8, $00, $01, $2F, $39, $F9, $10, $E8, $08, $01, $30, $3E, $55, $62, $30, $33  ; $7601
    db $62, $9C, $F9, $24, $FA, $F7, $F2, $ED, $F9, $00, $E8, $08, $00, $24, $37, $2E  ; $7611
    db $62, $9C, $F9, $28, $E8, $00, $01, $2F, $39, $F9, $10, $E8, $08, $01, $27, $28  ; $7621
    db $29, $62, $9C, $F9, $2C, $FA, $F7, $F2, $ED, $F9, $00, $E8, $08, $00, $24, $2A  ; $7631
    db $2F, $62, $9C, $F9, $30, $E8, $00, $01, $2F, $39, $F9, $10, $E8, $08, $01, $2C  ; $7641
    db $31, $37, $62, $9C, $F9, $34, $FA, $F7, $F0  ; $7651
MiscText_32:
    db $ED, $3C, $4C, $52, $4F, $62, $4A, $4C, $4B, $50, $51, $42, $4F, $62, $45, $3E  ; $765A
    db $50, $F1, $43, $52, $49, $49, $56, $62, $44, $4F, $4C, $54, $4B, $5F, $FA, $F7  ; $766A
    db $F0  ; $767A
MiscText_33:
    db $ED, $F9, $00, $F1, $3F, $42, $40, $4C, $4A, $42, $50, $F7, $F2, $F9, $10, $63  ; $767B
    db $F1, $FA, $F7, $F0  ; $768B
MiscText_34:
    db $ED, $33, $49, $42, $3E, $50, $42, $62, $40, $45, $4C, $4C, $50, $42, $62, $3E  ; $768F
    db $4B, $F1, $42, $44, $44, $62, $51, $4C, $62, $50, $42, $4B, $41, $62, $3E, $54  ; $769F
    db $3E, $56, $5F, $F0  ; $76AF
MiscText_35:
    db $ED, $F6, $62, $4F, $42, $40, $42, $46, $53, $42, $50, $F1, $F9, $00, $62, $28  ; $76B3
    db $55, $4D, $62, $4D, $51, $50, $5F, $FA, $F7, $F0  ; $76C3
MiscText_36:
    db $ED, $37, $45, $42, $4F, $42, $62, $54, $46, $49, $49, $62, $3F, $42, $62, $4B  ; $76CD
    db $4C, $F1, $4A, $4C, $4B, $50, $51, $42, $4F, $50, $62, $49, $42, $43, $51, $FA  ; $76DD
    db $F7, $F2, $46, $4B, $62, $56, $4C, $52, $4F, $62, $4D, $3E, $4F, $51, $56, $5F  ; $76ED
    db $F1, $FA, $F7, $F0  ; $76FD
WatabouText_00:
    db $ED, $3A, $3E, $51, $3E, $3F, $4C, $52, $62, $3E, $4D, $4D, $42, $3E, $4F, $50  ; $7701
    db $F1, $4C, $52, $51, $62, $4C, $43, $62, $4B, $4C, $54, $45, $42, $4F, $42, $63  ; $7711
    db $FA, $F7, $F2, $3A, $3E, $51, $3E, $3F, $4C, $52, $F1, $41, $46, $50, $3E, $4D  ; $7721
    db $4D, $42, $3E, $4F, $50, $63, $F7, $F0  ; $7731
ItemUseText_00:
    db $37, $45, $42, $62, $F9, $20, $F1, $43, $3E, $49, $49, $50, $62, $3E, $4D, $3E  ; $7739
    db $4F, $51, $63, $F7, $F0  ; $7749
ItemUseText_01:
    db $F9, $00, $62, $52, $50, $42, $50, $F1, $51, $45, $42, $62, $F9, $20, $F7, $F2  ; $774E
    db $3E, $50, $62, $3E, $62, $51, $4C, $4C, $49, $5F, $F1, $F7, $F0  ; $775E
ItemUseText_02:
    db $25, $52, $51, $62, $4B, $4C, $51, $45, $46, $4B, $44, $F1, $45, $3E, $4D, $4D  ; $776B
    db $42, $4B, $50, $5F, $F7, $F0  ; $777B
ItemUseText_03:
    db $F9, $00, $62, $52, $50, $42, $50, $F1, $01, $62, $F9, $20, $62, $4C, $4B, $F7  ; $7781
    db $F2, $F9, $10, $5F, $F1, $F7, $F0  ; $7791
ItemUseText_04:
    db $F9, $10, $68, $F1, $54, $4C, $52, $4B, $41, $62, $45, $42, $3E, $49, $50, $5F  ; $7798
    db $F7, $F0  ; $77A8
ItemUseText_05:
    db $F9, $00, $62, $45, $4C, $49, $41, $50, $62, $51, $45, $42, $F1, $36, $3E, $44  ; $77AA
    db $42, $36, $51, $4C, $4B, $42, $62, $51, $4C, $62, $51, $45, $42, $FA, $F7, $F2  ; $77BA
    db $50, $48, $56, $63, $F1, $F7, $F0  ; $77CA
ItemUseText_06:
    db $F9, $00, $F1, $50, $4D, $4F, $46, $4B, $48, $49, $42, $50, $F7, $F2, $F9, $20  ; $77D1
    db $63, $F1, $F7, $F0  ; $77E1
ItemUseText_07:
    db $F9, $10, $68, $F1, $30, $33, $62, $4F, $42, $40, $4C, $53, $42, $4F, $50, $63  ; $77E5
    db $F7, $F0  ; $77F5
ItemUseText_08:
    db $F9, $10, $F1, $46, $50, $62, $40, $52, $4F, $42, $41, $63, $F7, $F0  ; $77F7
ItemUseText_09:
    db $F9, $10, $68, $F1, $4D, $3E, $4F, $3E, $49, $56, $50, $46, $50, $F7, $F2, $46  ; $7805
    db $50, $62, $40, $52, $4F, $42, $41, $63, $F1, $F7, $F0  ; $7815
ItemUseText_10:
    db $F9, $10, $F1, $4F, $42, $40, $4C, $53, $42, $4F, $50, $63, $F7, $F0  ; $7820
ItemUseText_11:
    db $37, $45, $42, $62, $40, $52, $4F, $50, $42, $62, $40, $3E, $50, $51, $62, $4C  ; $782E
    db $4B, $F1, $F9, $10, $F7, $F2, $46, $50, $62, $3F, $4F, $4C, $48, $42, $4B, $63  ; $783E
    db $F1, $F7, $F0  ; $784E
ItemUseText_12:
    db $F9, $10, $F1, $54, $3E, $48, $42, $50, $62, $52, $4D, $63, $F7, $F0  ; $7851
ItemUseText_13:
    db $F9, $10, $F1, $4F, $42, $53, $46, $53, $42, $50, $63, $F7, $F0  ; $785F
ItemUseText_14:
    db $F9, $10, $68, $62, $4A, $3E, $55, $62, $2B, $33, $F1, $44, $4C, $42, $50, $62  ; $786C
    db $52, $4D, $62, $3F, $56, $62, $F9, $30, $63, $F7, $F0  ; $787C
ItemUseText_15:
    db $F9, $10, $68, $62, $4A, $3E, $55, $62, $30, $33, $F1, $44, $4C, $42, $50, $62  ; $7887
    db $52, $4D, $62, $3F, $56, $62, $F9, $30, $63, $F7, $F0  ; $7897
ItemUseText_16:
    db $F9, $10, $68, $62, $24, $37, $2E, $F1, $44, $4C, $42, $50, $62, $52, $4D, $62  ; $78A2
    db $3F, $56, $62, $F9, $30, $63, $F7, $F0  ; $78B2
ItemUseText_17:
    db $F9, $10, $68, $62, $27, $28, $29, $F1, $44, $4C, $42, $50, $62, $52, $4D, $62  ; $78BA
    db $3F, $56, $62, $F9, $30, $63, $F7, $F0  ; $78CA
ItemUseText_18:
    db $F9, $10, $68, $62, $24, $2A, $2F, $F1, $44, $4C, $42, $50, $62, $52, $4D, $62  ; $78D2
    db $3F, $56, $62, $F9, $30, $63, $F7, $F0  ; $78E2
ItemUseText_19:
    db $F9, $10, $68, $62, $2C, $31, $37, $F1, $44, $4C, $42, $50, $62, $52, $4D, $62  ; $78EA
    db $3F, $56, $62, $F9, $30, $63, $F7, $F0  ; $78FA
ItemUseText_20:
    db $F9, $00, $62, $44, $46, $53, $42, $50, $F1, $F9, $10, $5E, $F7, $F2, $3E, $62  ; $7902
    db $F9, $20, $63, $F1, $F7, $F0  ; $7912
ItemUseText_21:
    db $F9, $10, $62, $42, $3E, $51, $50, $F1, $46, $51, $62, $45, $3E, $4D, $4D, $46  ; $7918
    db $49, $56, $63, $F7, $F2, $F9, $10, $62, $3F, $42, $44, $46, $4B, $50, $F1, $51  ; $7928
    db $4C, $62, $49, $46, $48, $42, $62, $F6, $63, $F7, $F0  ; $7938
ItemUseText_22:
    db $F9, $10, $62, $42, $3E, $51, $50, $F1, $46, $51, $62, $40, $3E, $52, $51, $46  ; $7943
    db $4C, $52, $50, $49, $56, $63, $F7, $F2, $F9, $10, $62, $46, $50, $F1, $49, $4C  ; $7953
    db $4C, $48, $46, $4B, $44, $62, $51, $45, $46, $50, $62, $54, $3E, $56, $F7, $F2  ; $7963
    db $54, $46, $51, $45, $62, $3E, $62, $43, $4F, $4C, $54, $4B, $5F, $F1, $F7, $F2  ; $7973
    db $F9, $10, $62, $46, $50, $F1, $4D, $4C, $46, $50, $4C, $4B, $42, $41, $5F, $F7  ; $7983
    db $F0  ; $7993
ItemUseText_23:
    db $F9, $00, $62, $45, $4C, $49, $41, $50, $62, $51, $45, $42, $F1, $F9, $20, $F7  ; $7994
    db $F2, $51, $4C, $62, $51, $45, $42, $62, $50, $48, $56, $63, $F1, $F7, $F0  ; $79A4
ItemUseText_24:
    db $24, $62, $51, $45, $52, $4B, $41, $42, $4F, $62, $3F, $4C, $49, $51, $F1, $49  ; $79B3
    db $42, $3E, $4D, $50, $62, $43, $4F, $4C, $4A, $62, $51, $45, $42, $F7, $F2, $51  ; $79C3
    db $46, $4D, $62, $4C, $43, $62, $51, $45, $42, $62, $50, $51, $3E, $43, $43, $63  ; $79D3
    db $F1, $F7, $F0  ; $79E3
ItemUseText_25:
    db $24, $62, $53, $3E, $40, $52, $52, $4A, $62, $50, $54, $46, $4F, $49, $F1, $46  ; $79E6
    db $50, $62, $40, $4F, $42, $3E, $51, $42, $41, $63, $F7, $F0  ; $79F6
ItemUseText_26:
    db $24, $62, $4A, $56, $50, $51, $42, $4F, $46, $4C, $52, $50, $62, $4A, $46, $50  ; $7A02
    db $51, $F1, $40, $4C, $53, $42, $4F, $50, $62, $51, $45, $42, $62, $3E, $4F, $42  ; $7A12
    db $3E, $63, $F7, $F0  ; $7A22
ItemUseText_27:
    db $2F, $3E, $53, $3E, $62, $4C, $4C, $57, $42, $50, $62, $43, $4F, $4C, $4A, $F1  ; $7A26
    db $51, $45, $42, $62, $44, $4F, $4C, $52, $4B, $41, $63, $F7, $F0  ; $7A36
ItemUseText_28:
    db $24, $62, $3F, $49, $46, $57, $57, $3E, $4F, $41, $F1, $50, $54, $46, $4F, $49  ; $7A43
    db $50, $62, $3E, $40, $4F, $4C, $50, $50, $5F, $F7, $F0  ; $7A53
ItemUseText_29:
    db $F9, $00, $62, $51, $45, $4F, $4C, $54, $50, $F1, $3E, $62, $F9, $20, $63, $F7  ; $7A5E
    db $F0  ; $7A6E
ItemUseText_30:
    db $F9, $00, $62, $52, $50, $42, $50, $F1, $51, $45, $42, $62, $F9, $20, $63, $F7  ; $7A6F
    db $F0  ; $7A7F
ItemUseText_31:
    db $F9, $00, $62, $4F, $42, $3E, $41, $50, $F1, $3E, $62, $F9, $20, $62, $51, $4C  ; $7A80
    db $FA, $F7, $F2, $F9, $10, $5F, $F1, $F7, $F0  ; $7A90
ItemUseText_32:
    db $37, $45, $42, $62, $42, $55, $40, $46, $51, $46, $4B, $44, $62, $50, $51, $4C  ; $7A99
    db $4F, $56, $F1, $4A, $3E, $48, $42, $50, $62, $F9, $10, $FA, $F7, $F2, $46, $4B  ; $7AA9
    db $51, $4C, $62, $3E, $62, $3F, $4F, $3E, $53, $42, $F1, $4A, $4C, $4B, $50, $51  ; $7AB9
    db $42, $4F, $5F, $F7, $F0  ; $7AC9
ItemUseText_33:
    db $37, $45, $42, $62, $45, $4C, $4F, $4F, $46, $43, $56, $46, $4B, $44, $F1, $50  ; $7ACE
    db $51, $4C, $4F, $56, $62, $4A, $3E, $48, $42, $50, $FA, $F7, $F2, $F9, $10, $62  ; $7ADE
    db $46, $4B, $51, $4C, $F1, $3E, $62, $40, $4C, $54, $3E, $4F, $41, $5F, $F7, $F0  ; $7AEE
ItemUseText_34:
    db $37, $45, $42, $62, $53, $42, $4F, $56, $62, $4A, $4C, $53, $46, $4B, $44, $F1  ; $7AFE
    db $50, $51, $4C, $4F, $56, $62, $4A, $3E, $48, $42, $50, $FA, $F7, $F2, $F9, $10  ; $7B0E
    db $62, $46, $4B, $51, $4C, $F1, $3E, $62, $48, $46, $4B, $41, $62, $4A, $4C, $4B  ; $7B1E
    db $50, $51, $42, $4F, $5F, $F7, $F0  ; $7B2E
ItemUseText_35:
    db $37, $45, $42, $62, $54, $46, $51, $51, $56, $62, $50, $51, $4C, $4F, $56, $F1  ; $7B35
    db $4A, $3E, $48, $42, $50, $62, $F9, $10, $FA, $F7, $F2, $46, $4B, $51, $4C, $62  ; $7B45
    db $3E, $62, $50, $45, $4F, $42, $54, $41, $F1, $4A, $4C, $4B, $50, $51, $42, $4F  ; $7B55
    db $5F, $F7, $F0  ; $7B65
ItemUseText_36:
    db $37, $45, $42, $62, $50, $51, $4C, $4F, $56, $F1, $4A, $3E, $48, $42, $50, $62  ; $7B68
    db $F9, $10, $FA, $F7, $F2, $46, $4B, $51, $4C, $62, $3E, $62, $50, $4A, $3E, $4F  ; $7B78
    db $51, $F1, $4A, $4C, $4B, $50, $51, $42, $4F, $5F, $F7, $F0  ; $7B88
ItemUseText_37:
    db $37, $45, $42, $62, $43, $52, $4B, $4B, $56, $62, $50, $51, $4C, $4F, $56, $F1  ; $7B94
    db $4A, $3E, $48, $42, $50, $62, $F9, $10, $FA, $F7, $F2, $46, $4B, $51, $4C, $62  ; $7BA4
    db $3E, $62, $4B, $3E, $46, $53, $42, $F1, $4A, $4C, $4B, $50, $51, $42, $4F, $5F  ; $7BB4
    db $F7, $F0  ; $7BC4
ItemUseText_38:
    db $29, $49, $3E, $4A, $42, $50, $62, $49, $42, $3E, $4D, $50, $F1, $43, $4F, $4C  ; $7BC6
    db $4A, $62, $51, $45, $42, $62, $51, $46, $4D, $F7, $F2, $4C, $43, $62, $51, $45  ; $7BD6
    db $42, $62, $50, $51, $3E, $43, $43, $5F, $F1, $F7, $F0  ; $7BE6
ItemUseText_39:
    db $F9, $30, $68, $F1, $54, $4C, $52, $4B, $41, $62, $45, $42, $3E, $49, $50, $63  ; $7BF1
    db $F7, $F0  ; $7C01
ItemUseText_40:
    db $F9, $30, $68, $F1, $54, $4C, $52, $4B, $41, $62, $45, $42, $3E, $49, $50, $63  ; $7C03
    db $F7, $F2, $F9, $40, $68, $F1, $54, $4C, $52, $4B, $41, $62, $45, $42, $3E, $49  ; $7C13
    db $50, $63, $F7, $F0  ; $7C23
ItemUseText_41:
    db $F9, $30, $68, $F1, $54, $4C, $52, $4B, $41, $62, $45, $42, $3E, $49, $50, $63  ; $7C27
    db $F7, $F2, $F9, $40, $68, $F1, $54, $4C, $52, $4B, $41, $62, $45, $42, $3E, $49  ; $7C37
    db $50, $63, $F7, $F2, $F9, $50, $68, $F1, $54, $4C, $52, $4B, $41, $62, $45, $42  ; $7C47
    db $3E, $49, $50, $63, $F7, $F0  ; $7C57
ItemUseText_42:
    db $F9, $20, $62, $4D, $4C, $46, $4B, $51, $50, $F1, $F9, $30, $5F, $F7, $F0  ; $7C5D
ItemUseText_43:
    db $37, $45, $42, $4F, $42, $62, $3E, $4F, $42, $62, $4B, $4C, $62, $4A, $4C, $4F  ; $7C6C
    db $42, $F1, $50, $46, $44, $4B, $50, $62, $4C, $43, $62, $4A, $4C, $4B, $50, $51  ; $7C7C
    db $42, $4F, $50, $5F, $F7, $F0  ; $7C8C
ItemUseText_44:
    db $F9, $00, $62, $4D, $49, $3E, $56, $50, $F1, $51, $45, $42, $62, $F9, $20, $63  ; $7C92
    db $F7, $F0  ; $7CA2
ItemUseText_45:
    db $36, $51, $3E, $4F, $51, $50, $62, $51, $4C, $62, $50, $42, $42, $F1, $51, $45  ; $7CA4
    db $42, $62, $42, $4B, $51, $46, $4F, $42, $62, $4A, $3E, $4D, $63, $F7, $F0  ; $7CB4
ItemUseText_46:
    db $3A, $3E, $4B, $51, $62, $51, $4C, $62, $4F, $42, $40, $4C, $4F, $41, $F1, $46  ; $7CC3
    db $4B, $62, $51, $45, $42, $62, $2D, $4C, $52, $4F, $4B, $3E, $49, $64, $E6, $F0  ; $7CD3
ItemUseText_47:
    db $35, $42, $40, $4C, $4F, $41, $42, $41, $62, $46, $4B, $62, $51, $45, $42, $F1  ; $7CE3
    db $2D, $4C, $52, $4F, $4B, $3E, $49, $5F, $F7, $F0  ; $7CF3
SpellUseText_00:
    db $F9, $00, $62, $40, $3E, $50, $51, $50, $F1, $F9, $20, $63, $F7, $F0  ; $7CFD
SpellUseText_01:
    db $25, $52, $51, $62, $4B, $4C, $51, $45, $46, $4B, $44, $F1, $45, $3E, $4D, $4D  ; $7D0B
    db $42, $4B, $50, $63, $F7, $F0  ; $7D1B
SpellUseText_02:
    db $25, $52, $51, $62, $4B, $4C, $51, $62, $42, $4B, $4C, $52, $44, $45, $62, $30  ; $7D21
    db $33, $63, $F7, $F0  ; $7D31
SpellUseText_03:
    db $F9, $10, $68, $F1, $54, $4C, $52, $4B, $41, $62, $45, $42, $3E, $49, $50, $63  ; $7D35
    db $F7, $F0  ; $7D45
SpellUseText_04:
    db $F9, $10, $F1, $46, $50, $62, $4F, $42, $53, $46, $53, $42, $41, $63, $F7, $F0  ; $7D47
SpellUseText_05:
    db $F9, $10, $62, $41, $4C, $42, $50, $F1, $4B, $4C, $51, $62, $4F, $42, $53, $46  ; $7D57
    db $53, $42, $5F, $F7, $F0  ; $7D67
SpellUseText_06:
    db $F9, $10, $62, $46, $50, $F1, $40, $52, $4F, $42, $41, $5F, $F7, $F0  ; $7D6C
SpellUseText_07:
    db $26, $52, $4F, $50, $42, $62, $40, $3E, $50, $51, $62, $4C, $4B, $F1, $F9, $10  ; $7D7A
    db $62, $46, $50, $F7, $F2, $3F, $4F, $4C, $48, $42, $4B, $63, $F1, $F7, $F0  ; $7D8A
SpellUseText_08:
    db $25, $52, $51, $62, $46, $51, $62, $53, $3E, $4B, $46, $50, $45, $42, $50, $F1  ; $7D99
    db $41, $52, $42, $62, $51, $4C, $62, $3E, $F7, $F2, $4A, $56, $50, $51, $42, $4F  ; $7DA9
    db $46, $4C, $52, $50, $62, $43, $4C, $4F, $40, $42, $63, $F1, $F7, $F0  ; $7DB9
SpellUseText_09:
    db $F9, $00, $F1, $54, $45, $46, $50, $51, $49, $42, $50, $63, $F7, $F0  ; $7DC7
SpellUseText_10:
    db $26, $3E, $4B, $4B, $4C, $51, $62, $52, $50, $42, $62, $4B, $4C, $54, $5F, $F7  ; $7DD5
    db $F0  ; $7DE5
SpellUseText_11:
    db $26, $3E, $4B, $4B, $4C, $51, $62, $52, $50, $42, $62, $50, $48, $46, $49, $49  ; $7DE6
    db $50, $F1, $4C, $43, $62, $3E, $62, $48, $4B, $4C, $40, $48, $42, $41, $62, $4C  ; $7DF6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7E06
    db $19, $F0, $0A, $5B, $0C, $5B, $0E, $5B, $10, $5B, $12, $5B, $14, $5B, $16, $5B  ; $7E16 (B9 S28: Spirit lib icon = $19 whip)
    db $18, $5B, $1A, $5B, $1C, $5B, $16, $7E, $1E, $5B, $1E, $5B, $1E, $5B, $1E, $5B  ; $7E26
    db $1E, $5B, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7E36
MonsterName_224_Gorbunok:  ; $7E46 — Phase N new species
    db $2a, $4c, $4f, $3f, $52, $4b, $4c, $48, $f0  ; "Gorbunok" literal (no DTE) + terminator
    db $00, $00, $00, $00, $00, $00, $00  ; $7E4F (remaining fill)
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7E56
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7E66
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7E76
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7E86
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7E96
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7EA6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7EB6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7EC6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7ED6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7EE6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7EF6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7F06
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7F16
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7F26
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7F36
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7F46
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7F56
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7F66
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7F76
SkillName_222_Scorch:                                             ; $7F86
    db $36, $40, $4c, $4f, $40, $45, $f0                          ; "Scorch" + terminator
SkillName_223_Smite:                                              ; $7F8D
    db $36, $4a, $46, $51, $42, $f0                               ; "Smite" + terminator
    db $00, $00, $00                                              ; $7F93-$7F95 pad
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7F96
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7FA6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7FB6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7FC6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7FD6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; $7FE6
;   Phase N: new-species SHORT (default-nickname) name table tail.
;   The default-name redirect (bank $00 LoadModeBaseRedirect) sends id>=224 to
;   base $7E39, so id 224 lands at $7FF9. Holds the first 4 letters of the name
;   ("Gorb"), used for BOTH the nickname field and the "take X with you" line.
    db $00, $00, $00                              ; $7FF6-$7FF8 pad
NewSpeciesShortName224:                           ; $7FF9 (= $7E39 + 224*2)
    dw .gorb                                      ; -> short name string
.gorb:
    db $2a, $4c, $4f, $3f, $f0                    ; "Gorb" (first 4 of "Gorbunok") + terminator
