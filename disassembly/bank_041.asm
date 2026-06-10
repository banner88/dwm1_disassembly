; =============================================================================
; BANK $41 — NAME TABLES (MONSTERS, SKILLS, PERSONALITIES, ITEMS)
; =============================================================================
; Contains:
;   - Code/data at $4000-$4338
;   - Monster name pointer table at $4339 (256 × dw → MonsterName_XXX labels)
;   - Skill name pointer table at $4539 (256 × dw → SkillName_XXX labels)
;   - Other pointer/data tables at $4739-$5B1E
;   - Monster name strings at $5B1F (222 unique, $F0 terminated, charmap encoded)
;   - Skill name strings at $628E (256 entries, $F0 terminated, charmap encoded)
;   - Personality/family/item strings after $6A55
;
; TEXT ENCODING: Uses charmap.asm (A=$24, a=$3E, space=$62, etc.)
;   Names terminated by $F0. Edit strings directly: db "NewName", $F0
;   Pointer tables use labels — name length changes auto-update!
;
; Sources: gen_name_tables_db.py, charmap.asm
; =============================================================================

SECTION "ROM Bank $041", ROMX[$4000], BANK[$41]

; --- Code/data ($4000-$4338, 825 bytes) ---
    db $41, $93, $4A, $9A, $4A, $A1, $4A, $25, $40, $39, $40, $01, $41, $E3, $41, $23
    db $43, $39, $43, $39, $45, $39, $47, $E7, $48, $3F, $49, $97, $49, $CD, $49, $17
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
    dw MonsterName_220_Unused_220  ; [224]
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
    dw MonsterName_225_Unused_225  ; [254]
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
    dw SkillName_215_Sheldodge  ; [215]
    dw SkillName_216_Branching  ; [216]
    dw SkillName_217_GigaSlash  ; [217]
    dw SkillName_218_LIFE  ; [218]
    dw SkillName_219_RUN  ; [219]
    dw SkillName_220_IRONIZE  ; [220]
    dw SkillName_221_Ahhh  ; [221]
    dw SkillName_222_Unused_222  ; [222]
    dw SkillName_222_Unused_222  ; [223]
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

; --- Other pointer/data tables ($4739-$5B1E, 5094 bytes) ---
; Includes family names, item tables, personality pointers, etc.
    db $F2, $69, $F5, $69, $F8, $69, $FB, $69, $FE, $69, $01, $6A, $04, $6A, $07, $6A
    db $0A, $6A, $0D, $6A, $10, $6A, $13, $6A, $16, $6A, $19, $6A, $1C, $6A, $1F, $6A
    db $22, $6A, $25, $6A, $28, $6A, $2B, $6A, $2E, $6A, $31, $6A, $34, $6A, $37, $6A
    db $3A, $6A, $3D, $6A, $40, $6A, $43, $6A, $46, $6A, $49, $6A, $4C, $6A, $4F, $6A
    db $52, $6A, $55, $6A, $58, $6A, $5B, $6A, $5E, $6A, $61, $6A, $64, $6A, $67, $6A
    db $6A, $6A, $6D, $6A, $70, $6A, $73, $6A, $76, $6A, $79, $6A, $7C, $6A, $7F, $6A
    db $82, $6A, $85, $6A, $88, $6A, $8B, $6A, $8E, $6A, $91, $6A, $94, $6A, $97, $6A
    db $9A, $6A, $9D, $6A, $A0, $6A, $A3, $6A, $A6, $6A, $A9, $6A, $AC, $6A, $AF, $6A
    db $B2, $6A, $B5, $6A, $B8, $6A, $BB, $6A, $BE, $6A, $C1, $6A, $C4, $6A, $C7, $6A
    db $CA, $6A, $CD, $6A, $D0, $6A, $D3, $6A, $D6, $6A, $D9, $6A, $DC, $6A, $DF, $6A
    db $E2, $6A, $E5, $6A, $E8, $6A, $EB, $6A, $EE, $6A, $F1, $6A, $F4, $6A, $F7, $6A
    db $FA, $6A, $FD, $6A, $00, $6B, $03, $6B, $06, $6B, $09, $6B, $0C, $6B, $0F, $6B
    db $12, $6B, $15, $6B, $18, $6B, $1B, $6B, $1E, $6B, $21, $6B, $24, $6B, $27, $6B
    db $2A, $6B, $2D, $6B, $30, $6B, $33, $6B, $36, $6B, $39, $6B, $3C, $6B, $3F, $6B
    db $42, $6B, $45, $6B, $48, $6B, $4B, $6B, $4E, $6B, $51, $6B, $54, $6B, $57, $6B
    db $5A, $6B, $5D, $6B, $60, $6B, $63, $6B, $66, $6B, $69, $6B, $6C, $6B, $6F, $6B
    db $72, $6B, $75, $6B, $78, $6B, $7B, $6B, $7E, $6B, $81, $6B, $84, $6B, $87, $6B
    db $8A, $6B, $8D, $6B, $90, $6B, $93, $6B, $96, $6B, $99, $6B, $9C, $6B, $9F, $6B
    db $A2, $6B, $A5, $6B, $A8, $6B, $AB, $6B, $AE, $6B, $B1, $6B, $B4, $6B, $B7, $6B
    db $BA, $6B, $BD, $6B, $C0, $6B, $C3, $6B, $C6, $6B, $C9, $6B, $CC, $6B, $CF, $6B
    db $D2, $6B, $D5, $6B, $D8, $6B, $DB, $6B, $DE, $6B, $E1, $6B, $E4, $6B, $E7, $6B
    db $EA, $6B, $ED, $6B, $F0, $6B, $F3, $6B, $F6, $6B, $F9, $6B, $FC, $6B, $FF, $6B
    db $02, $6C, $05, $6C, $08, $6C, $0B, $6C, $0E, $6C, $11, $6C, $14, $6C, $17, $6C
    db $1A, $6C, $1D, $6C, $20, $6C, $23, $6C, $26, $6C, $29, $6C, $2C, $6C, $2F, $6C
    db $32, $6C, $35, $6C, $38, $6C, $3B, $6C, $3E, $6C, $41, $6C, $44, $6C, $47, $6C
    db $4A, $6C, $4D, $6C, $50, $6C, $53, $6C, $56, $6C, $59, $6C, $5C, $6C, $5F, $6C
    db $62, $6C, $65, $6C, $68, $6C, $6B, $6C, $6E, $6C, $71, $6C, $74, $6C, $77, $6C
    db $78, $6C, $7D, $6C, $87, $6C, $91, $6C, $9A, $6C, $A1, $6C, $AA, $6C, $B3, $6C
    db $BC, $6C, $C4, $6C, $CB, $6C, $D5, $6C, $DF, $6C, $E9, $6C, $F3, $6C, $FB, $6C
    db $03, $6D, $0B, $6D, $13, $6D, $1D, $6D, $26, $6D, $2A, $6D, $32, $6D, $3A, $6D
    db $44, $6D, $4E, $6D, $58, $6D, $62, $6D, $6C, $6D, $75, $6D, $7F, $6D, $87, $6D
    db $90, $6D, $99, $6D, $A3, $6D, $AB, $6D, $B4, $6D, $BE, $6D, $C8, $6D, $D2, $6D
    db $DC, $6D, $E6, $6D, $EE, $6D, $F7, $6D, $F8, $6D, $15, $6E, $32, $6E, $4F, $6E
    db $67, $6E, $84, $6E, $97, $6E, $A5, $6E, $B5, $6E, $C6, $6E, $D5, $6E, $E6, $6E
    db $F6, $6E, $0C, $6F, $22, $6F, $3E, $6F, $5B, $6F, $73, $6F, $8F, $6F, $8F, $6F
    db $8F, $6F, $8F, $6F, $8F, $6F, $9F, $6F, $C2, $6F, $DD, $6F, $F7, $6F, $0F, $70
    db $2E, $70, $4D, $70, $6E, $70, $6E, $70, $6E, $70, $6E, $70, $6E, $70, $6E, $70
    db $8B, $70, $AD, $70, $CD, $70, $E4, $70, $F4, $70, $16, $71, $38, $71, $59, $71
    db $62, $71, $69, $71, $73, $71, $7D, $71, $82, $71, $8B, $71, $90, $71, $97, $71
    db $A0, $71, $AA, $71, $B1, $71, $B6, $71, $BF, $71, $C8, $71, $CE, $71, $D7, $71
    db $DD, $71, $E5, $71, $EC, $71, $F6, $71, $FF, $71, $07, $72, $10, $72, $19, $72
    db $1D, $72, $24, $72, $29, $72, $47, $72, $60, $72, $8B, $72, $A1, $72, $E5, $72
    db $F7, $72, $06, $73, $1D, $73, $35, $73, $40, $73, $49, $73, $4F, $73, $5E, $73
    db $5E, $73, $78, $73, $A8, $73, $F8, $73, $5C, $74, $78, $74, $96, $74, $B1, $74
    db $DC, $74, $F5, $74, $08, $75, $28, $75, $41, $75, $4D, $75, $5C, $75, $68, $75
    db $88, $75, $F1, $75, $5A, $76, $7B, $76, $8F, $76, $B3, $76, $CD, $76, $01, $77
    db $01, $77, $39, $77, $4E, $77, $6B, $77, $81, $77, $98, $77, $AA, $77, $D1, $77
    db $E5, $77, $F7, $77, $05, $78, $20, $78, $2E, $78, $51, $78, $5F, $78, $6C, $78
    db $87, $78, $A2, $78, $BA, $78, $D2, $78, $EA, $78, $02, $79, $18, $79, $43, $79
    db $94, $79, $B3, $79, $E6, $79, $02, $7A, $26, $7A, $43, $7A, $5E, $7A, $6F, $7A
    db $80, $7A, $99, $7A, $CE, $7A, $FE, $7A, $35, $7B, $68, $7B, $94, $7B, $C6, $7B
    db $F1, $7B, $03, $7C, $27, $7C, $5D, $7C, $6C, $7C, $92, $7C, $A4, $7C, $C3, $7C
    db $E3, $7C, $FD, $7C, $0B, $7D, $21, $7D, $35, $7D, $47, $7D, $57, $7D, $6C, $7D
    db $7A, $7D, $99, $7D, $C7, $7D, $D5, $7D, $E6, $7D, $11, $07, $40, $CD, $B6, $05
    db $C9, $11, $07, $40, $CD, $F6, $05, $C9, $CD, $93, $4A, $CD, $09, $06, $C9, $96
    db $62, $27, $28, $25, $38, $2A, $62, $30, $32, $27, $28, $F1, $62, $62, $62, $62
    db $36, $28, $2F, $28, $26, $37, $62, $62, $62, $97, $F1, $62, $01, $A3, $2A, $32
    db $37, $32, $62, $33, $35, $32, $2A, $35, $24, $30, $62, $62, $02, $A3, $30, $32
    db $31, $36, $37, $28, $35, $62, $62, $62, $62, $62, $62, $62, $03, $A3, $2A, $24
    db $30, $28, $62, $28, $27, $2C, $37, $62, $62, $62, $62, $62, $04, $A3, $36, $32
    db $38, $31, $27, $62, $37, $28, $36, $37, $62, $62, $62, $62, $05, $A3, $25, $24
    db $37, $37, $2F, $28, $62, $28, $27, $2C, $37, $62, $62, $62, $62, $9C, $62, $62
    db $35, $28, $37, $38, $35, $31, $62, $62, $9C, $62, $62, $F0, $62, $62, $9C, $62
    db $28, $27, $2C, $37, $62, $9C, $F1, $F1, $30, $24, $33, $37, $3C, $33, $28, $F1
    db $29, $2F, $32, $32, $35, $62, $62, $F1, $24, $2F, $2F, $3C, $62, $62, $62, $F1
    db $30, $32, $31, $36, $37, $35, $01, $F1, $30, $32, $31, $36, $37, $35, $02, $F1
    db $30, $32, $31, $36, $37, $35, $03, $F1, $62, $27, $38, $30, $30, $3C, $62, $F1
    db $62, $27, $28, $25, $38, $2A, $62, $F0, $62, $00, $01, $02, $03, $04, $05, $06
    db $07, $08, $09, $24, $25, $26, $27, $28, $29, $F0, $62, $62, $9C, $62, $36, $32
    db $38, $31, $27, $62, $9C, $F1, $F1, $62, $62, $25, $2A, $30, $F1, $62, $62, $36
    db $28, $F0, $9C, $62, $2A, $32, $37, $32, $33, $35, $2A, $62, $9C, $F1, $F1, $F1
    db $62, $33, $35, $2A, $31, $32, $01, $F1, $62, $33, $35, $2A, $31, $32, $02, $F1
    db $62, $33, $35, $2A, $31, $32, $03, $F0, $37, $2C, $37, $2F, $28, $62, $9D, $01
    db $62, $62, $2A, $24, $30, $28, $62, $62, $62, $25, $24, $37, $37, $2F, $28, $62
    db $28, $39, $37, $27, $28, $30, $32, $62, $62, $36, $37, $24, $29, $29, $62, $62
    db $62, $28, $29, $29, $28, $26, $37, $62, $62, $35, $28, $36, $38, $2F, $37, $62
    db $27, $28, $25, $38, $2A, $62, $9D, $02, $32, $25, $2D, $37, $28, $36, $37, $62
    db $31, $32, $62, $30, $32, $35, $28, $5F, $5F, $9C, $62, $25, $24, $37, $37, $2F
    db $28, $62, $9C, $F1, $F1, $28, $31, $28, $30, $3C, $62, $62, $F1, $30, $32, $31
    db $36, $37, $35, $01, $F1, $30, $32, $31, $36, $37, $35, $01, $F1, $30, $32, $31
    db $36, $37, $35, $02, $F1, $30, $32, $31, $36, $37, $35, $02, $F1, $30, $32, $31
    db $36, $37, $35, $03, $F1, $30, $32, $31, $36, $37, $35, $03, $F1, $62, $27, $38
    db $30, $30, $3C, $62, $F1, $31, $32, $35, $30, $24, $2F, $F0, $24, $26, $35, $28
    db $24, $37, $28, $F0, $36, $37, $24, $2A, $28, $2C, $27, $F0, $26, $24, $36, $37
    db $2F, $28, $F0, $39, $2C, $2F, $2F, $24, $2A, $28, $F0, $25, $24, $3D, $24, $24
    db $35, $F0, $37, $35, $39, $2A, $24, $37, $28, $F0, $29, $24, $35, $30, $F0, $36
    db $2B, $33, $35, $27, $F0, $25, $24, $37, $37, $2F, $28, $01, $F0, $25, $24, $37
    db $37, $2F, $28, $02, $F0, $31, $28, $36, $37, $F0, $36, $37, $35, $27, $31, $2A
    db $31, $F0, $3A, $37, $30, $28, $27, $24, $2F, $F0, $F0, $28, $2A, $26, $31, $36
    db $2F, $37, $F0, $33, $35, $27, $33, $35, $31, $37, $F0, $F0, $26, $2B, $2E, $36
    db $37, $31, $27, $F0, $26, $38, $37, $3C, $2A, $35, $2F, $F0, $F0, $2F, $2C, $25
    db $35, $24, $35, $3C, $F0, $36, $37, $24, $26, $2E, $F0, $F0, $F0, $30, $28, $27
    db $24, $2F, $30, $24, $31, $F0, $F0, $2C, $31, $62, $3A, $28, $2F, $2F, $F0, $30
    db $27, $3C, $2B, $24, $31, $27, $F0, $36, $33, $32, $31, $36, $28, $35, $F0, $36
    db $37, $24, $25, $2F, $28, $2F, $F0, $36, $37, $24, $25, $2F, $28, $35, $F0, $36
    db $26, $2B, $32, $32, $2F, $F0, $25, $24, $35, $F0, $34, $38, $28, $28, $28, $31
    db $F0, $F0, $F0, $F0, $26, $2B, $30, $25, $35, $32, $33, $F0, $26, $2B, $30, $25
    db $35, $62, $2A, $F0, $26, $2B, $30, $25, $35, $62, $29, $F0, $26, $2B, $30, $25
    db $35, $62, $28, $F0, $26, $2B, $30, $25, $35, $62, $27, $F0, $26, $2B, $30, $25
    db $35, $62, $26, $F0, $26, $2B, $30, $25, $35, $62, $25, $F0, $26, $2B, $30, $25
    db $35, $62, $24, $F0, $26, $2B, $30, $25, $35, $62, $36, $F0, $26, $2B, $30, $25
    db $35, $62, $01, $F0, $26, $2B, $30, $25, $35, $62, $02, $F0, $26, $2B, $30, $25
    db $35, $62, $03, $F0, $37, $28, $35, $35, $3C, $36, $F0, $32, $2F, $27, $3A, $28
    db $2F, $2F, $F0, $36, $62, $26, $24, $39, $28, $F0, $30, $28, $2F, $2E, $2C, $27
    db $F0, $31, $28, $36, $37, $F0, $2C, $2F, $30, $3A, $32, $32, $27, $F0, $37, $32
    db $30, $27, $32, $2F, $24, $F0, $26, $24, $36, $2C, $31, $32, $F0, $2A, $32, $27
    db $37, $3A, $35, $F0, $2F, $32, $31, $27, $24, $35, $2A, $35, $F0, $35, $28, $31
    db $38, $2F, $F0, $24, $35, $33, $37, $3A, $35, $F0, $27, $24, $31, $26, $28, $35
    db $F0, $37, $62, $26, $24, $39, $28, $F0, $36, $33, $35, $2C, $31, $2A, $F0, $2B
    db $24, $33, $33, $3C, $F0, $2F, $2C, $29, $28, $26, $32, $27, $F0, $37, $35, $2C
    db $24, $2F, $01, $F0, $37, $35, $2C, $24, $2F, $02, $F0, $30, $62, $26, $24, $39
    db $28, $F0, $33, $35, $2C, $36, $32, $31, $F0, $3D, $62, $26, $24, $39, $28, $F0
    db $2B, $28, $2F, $26, $2F, $27, $F0, $27, $35, $2A, $26, $36, $37, $2F, $F0, $2B
    db $35, $2A, $31, $26, $36, $2F, $F0, $25, $35, $30, $36, $26, $36, $2F, $F0, $3D
    db $32, $30, $24, $26, $36, $2F, $F0, $30, $37, $62, $37, $32, $33, $F0, $24, $37
    db $37, $32, $30, $F0, $28, $39, $2C, $2F, $62, $30, $37, $F0, $30, $38, $27, $32
    db $26, $36, $2F, $F0, $25, $37, $3A, $28, $26, $36, $2F, $F0, $36, $26, $35, $37
    db $30, $24, $33, $F0, $2C, $37, $28, $30, $36, $33, $F0, $26, $2B, $38, $35, $26
    db $2B, $F0, $26, $32, $2F, $2C, $36, $38, $30, $F0, $30, $24, $3D, $28, $3A, $32
    db $27, $F0, $36, $2F, $27, $29, $2F, $35, $01, $F0, $36, $2F, $27, $29, $2F, $35
    db $02, $F0, $36, $2F, $27, $29, $2F, $35, $03, $F0, $30, $24, $3D, $28, $01, $F0
    db $30, $24, $3D, $28, $02, $F0, $30, $24, $3D, $28, $03, $F0, $30, $30, $26, $35
    db $30, $01, $F0, $30, $30, $26, $35, $30, $02, $F0, $30, $30, $26, $35, $30, $03
    db $F0, $25, $37, $2F, $27, $28, $30, $32, $F0, $26, $36, $2F, $25, $2A, $F0, $F0
    db $F9, $00, $F0, $3A, $3E, $4B, $51, $62, $51, $4C, $62, $41, $52, $4A, $4D, $F1
    db $F9, $10, $64, $F0, $F9, $00, $62, $41, $52, $4A, $4D, $50, $F1, $F9, $10, $62
    db $3E, $54, $3E, $56, $63, $F7, $F0, $26, $3E, $4B, $4B, $4C, $51, $62, $41, $52
    db $4A, $4D, $62, $45, $42, $4F, $42, $63, $F7, $F0, $F9, $00, $62, $52, $50, $42
    db $50, $F1, $01, $62, $F9, $10, $5F, $F7, $F0, $F9, $00, $62, $44, $3E, $53, $42
    db $50, $F1, $F9, $10, $FA, $F7, $F2, $01, $62, $F9, $20, $5F, $F1, $F7, $F0, $31
    db $4C, $51, $45, $46, $4B, $44, $62, $45, $3E, $4D, $4D, $42, $4B, $50, $5F, $F7
    db $F0, $35, $42, $40, $4C, $4F, $41, $62, $51, $4C, $62, $51, $45, $42, $F1, $2D
    db $4C, $52, $4F, $4B, $3E, $49, $64, $F7, $F0, $F6, $62, $43, $4C, $52, $4B, $41
    db $F1, $01, $62, $F9, $00, $F7, $F0, $2C, $50, $62, $F9, $00, $62, $4C, $48, $3E
    db $56, $F1, $43, $4C, $4F, $62, $51, $45, $42, $62, $4B, $3E, $4A, $42, $64, $F0
    db $33, $49, $42, $3E, $50, $42, $62, $40, $45, $4C, $4C, $50, $42, $F1, $3E, $4B
    db $4C, $51, $45, $42, $4F, $62, $4B, $3E, $4A, $42, $5F, $F7, $F0, $33, $38, $37
    db $62, $37, $24, $2E, $28, $28, $3B, $2C, $37, $F0, $2C, $37, $28, $30, $2A, $32
    db $2F, $27, $28, $3B, $2C, $37, $F0, $28, $4A, $4D, $51, $56, $F0, $28, $44, $44
    db $F0, $3A, $3E, $4B, $51, $62, $51, $4C, $62, $4B, $3E, $4A, $42, $F1, $F9, $10
    db $62, $3E, $50, $FA, $F7, $F2, $F9, $00, $64, $F1, $F0, $28, $3B, $2C, $37, $62
    db $2C, $31, $29, $32, $F0, $29, $4C, $52, $4B, $41, $62, $01, $62, $F9, $00, $5F
    db $F1, $25, $52, $51, $62, $40, $3E, $4B, $4B, $4C, $51, $62, $40, $3E, $4F, $4F
    db $56, $FA, $F7, $F2, $3E, $4B, $56, $62, $4A, $4C, $4F, $42, $5F, $F1, $F7, $F0
    db $2A, $46, $53, $42, $50, $62, $52, $4D, $F1, $F9, $00, $63, $F7, $F0, $27, $52
    db $4A, $4D, $62, $54, $45, $46, $40, $45, $62, $46, $51, $42, $4A, $64, $F0, $27
    db $52, $4A, $4D, $42, $41, $62, $F9, $10, $F1, $3E, $4B, $41, $62, $44, $4C, $51
    db $62, $F9, $00, $5F, $F7, $F0, $F6, $62, $43, $4C, $52, $4B, $41, $F1, $F9, $00
    db $2A, $5F, $F7, $F0, $29, $46, $4B, $41, $50, $62, $F9, $00, $2A, $5F, $F1, $26
    db $3E, $4B, $4B, $4C, $51, $62, $51, $3E, $48, $42, $62, $4A, $4C, $4F, $42, $5F
    db $F7, $F0, $37, $45, $42, $62, $51, $4F, $42, $3E, $50, $52, $4F, $42, $62, $3F
    db $4C, $55, $F1, $46, $50, $62, $4F, $42, $3E, $49, $49, $56, $62, $3E, $62, $30
    db $46, $4A, $46, $40, $63, $F7, $F0, $F9, $00, $F1, $43, $3E, $46, $4B, $51, $50
    db $5F, $F7, $F0, $F9, $00, $F1, $43, $3E, $46, $4B, $51, $50, $5F, $F7, $F2, $F9
    db $10, $F1, $43, $3E, $46, $4B, $51, $50, $5F, $F7, $F0, $F6, $68, $62, $50, $46
    db $41, $42, $62, $46, $50, $F1, $54, $46, $4D, $42, $41, $62, $4C, $52, $51, $63
    db $F7, $F0, $31, $4C, $51, $62, $4F, $42, $3E, $41, $56, $62, $43, $4C, $4F, $F1
    db $49, $46, $4B, $48, $62, $52, $4D, $5F, $FA, $F7, $F2, $26, $45, $42, $40, $48
    db $62, $3E, $4B, $41, $F1, $51, $4F, $56, $62, $3E, $44, $3E, $46, $4B, $5F, $F7
    db $F0, $26, $45, $4C, $4C, $50, $42, $62, $3E, $62, $4A, $4C, $4B, $50, $51, $42
    db $4F, $F1, $43, $4C, $4F, $62, $3F, $4F, $42, $42, $41, $46, $4B, $44, $5F, $F0
    db $26, $3E, $4B, $4B, $4C, $51, $62, $40, $45, $4C, $4C, $50, $42, $62, $51, $45
    db $42, $F1, $4C, $4B, $49, $56, $62, $4A, $4C, $4B, $50, $51, $42, $4F, $62, $49
    db $42, $43, $51, $FA, $F7, $F2, $46, $4B, $62, $56, $4C, $52, $4F, $62, $40, $52
    db $4F, $4F, $42, $4B, $51, $F1, $4D, $3E, $4F, $51, $56, $5F, $F7, $F0, $36, $3E
    db $4A, $42, $62, $44, $42, $4B, $41, $42, $4F, $5F, $F1, $26, $3E, $4B, $4B, $4C
    db $51, $62, $3F, $4F, $42, $42, $41, $5F, $F7, $F0, $32, $4B, $42, $62, $4A, $4C
    db $4A, $42, $4B, $51, $62, $4D, $49, $42, $3E, $50, $42, $5F, $F0, $3A, $3E, $4B
    db $51, $62, $51, $4C, $62, $3F, $4F, $42, $42, $41, $64, $F0, $35, $42, $43, $52
    db $50, $42, $41, $62, $51, $4C, $62, $3F, $4F, $42, $42, $41, $5F, $F0, $25, $4F
    db $42, $42, $41, $46, $4B, $44, $62, $4F, $42, $43, $52, $50, $42, $41, $5F, $F0
    db $36, $3E, $53, $42, $62, $51, $45, $42, $62, $4F, $42, $50, $52, $49, $51, $62
    db $4C, $43, $F1, $3F, $4F, $42, $42, $41, $46, $4B, $44, $64, $F0, $37, $45, $42
    db $62, $40, $42, $4F, $42, $4A, $4C, $4B, $56, $63, $F0, $26, $45, $4C, $4C, $50
    db $42, $62, $4A, $4C, $4B, $50, $51, $42, $4F, $A0, $50, $A1, $F1, $43, $4C, $4F
    db $62, $51, $45, $42, $62, $3F, $3E, $51, $51, $49, $42, $5F, $F0, $3A, $45, $3E
    db $51, $62, $54, $4C, $52, $49, $41, $62, $56, $4C, $52, $F1, $49, $46, $48, $42
    db $62, $51, $4C, $62, $41, $4C, $64, $F0, $26, $45, $4C, $4C, $50, $42, $62, $3E
    db $4B, $4C, $51, $45, $42, $4F, $F1, $4A, $4C, $4B, $50, $51, $42, $4F, $64, $F7
    db $F0, $36, $52, $3F, $4A, $46, $51, $62, $3E, $62, $4D, $4F, $46, $57, $42, $64
    db $F7, $F0, $31, $4C, $62, $4A, $4C, $4B, $50, $51, $42, $4F, $50, $62, $49, $42
    db $43, $51, $F1, $3E, $51, $62, $51, $45, $42, $62, $43, $3E, $4F, $4A, $5F, $FA
    db $F7, $F2, $37, $45, $52, $50, $5E, $62, $4B, $4C, $62, $4D, $4F, $46, $57, $42
    db $5F, $F1, $F7, $F0, $26, $45, $4C, $4C, $50, $42, $62, $3E, $62, $4A, $4C, $4B
    db $50, $51, $42, $4F, $F1, $43, $4C, $4F, $62, $51, $45, $42, $62, $4D, $4F, $46
    db $57, $42, $64, $F0, $24, $4F, $42, $62, $56, $4C, $52, $62, $4F, $42, $3E, $41
    db $56, $F1, $51, $4C, $62, $43, $46, $44, $45, $51, $64, $F0, $29, $46, $44, $45
    db $51, $63, $63, $F0, $35, $42, $43, $52, $50, $42, $41, $62, $51, $45, $42, $F1
    db $3F, $3E, $51, $51, $49, $42, $5F, $F0, $25, $3E, $51, $51, $49, $42, $62, $4F
    db $42, $43, $52, $50, $42, $41, $5F, $F0, $31, $4C, $62, $4D, $4F, $46, $57, $42
    db $5F, $F7, $F0, $3C, $4C, $52, $4F, $62, $4A, $4C, $4B, $50, $51, $42, $4F, $62
    db $46, $50, $F1, $4B, $4C, $51, $62, $4C, $49, $41, $62, $42, $4B, $4C, $52, $44
    db $45, $FA, $F7, $F2, $43, $4C, $4F, $62, $3F, $4F, $42, $42, $41, $46, $4B, $44
    db $5F, $F1, $FA, $F7, $F2, $25, $4F, $46, $4B, $44, $62, $46, $51, $62, $3F, $3E
    db $40, $48, $62, $54, $45, $42, $4B, $F1, $46, $51, $68, $62, $3E, $62, $3F, $46
    db $51, $62, $4C, $49, $41, $42, $4F, $5F, $F7, $F0, $31, $4C, $62, $36, $3E, $53
    db $42, $5F, $F0, $35, $42, $40, $4C, $4F, $41, $42, $41, $62, $46, $4B, $62, $51
    db $45, $42, $F1, $2D, $4C, $52, $4F, $4B, $3E, $49, $5F, $F7, $F0, $62, $62, $1B
    db $14, $1C, $1D, $F0, $69, $67, $15, $6F, $1C, $1D, $F0, $2B, $33, $F0, $30, $33
    db $F0, $24, $37, $37, $24, $26, $2E, $62, $4D, $4C, $54, $42, $4F, $F0, $27, $28
    db $29, $28, $31, $36, $28, $62, $4D, $4C, $54, $42, $4F, $F0, $24, $2A, $2C, $2F
    db $2C, $37, $3C, $F0, $2C, $31, $37, $28, $2F, $2F, $2C, $2A, $28, $31, $26, $28
    db $F0, $AE, $F0, $AF, $F0, $A9, $F0, $B0, $F0, $B1, $F0, $AD, $F0, $B2, $F0, $B3
    db $F0, $26, $3E, $4B, $4B, $4C, $51, $62, $4F, $42, $40, $4C, $4F, $41, $62, $46
    db $4B, $F1, $51, $45, $42, $62, $2D, $4C, $52, $4F, $4B, $3E, $49, $62, $45, $42
    db $4F, $42, $5F, $F7, $F0, $1E, $59, $13, $B4, $62, $F0, $37, $45, $42, $62, $50
    db $3E, $4A, $42, $62, $4B, $3E, $4A, $42, $F1, $3E, $49, $4F, $42, $3E, $41, $56
    db $62, $42, $55, $46, $50, $51, $50, $5F, $FA, $F7, $F2, $2C, $50, $62, $51, $45
    db $42, $62, $4B, $3E, $4A, $42, $F1, $F9, $00, $62, $4C, $48, $62, $43, $4C, $4F
    db $FA, $F7, $F2, $F9, $10, $64, $F1, $F0, $3C, $4C, $52, $62, $54, $46, $4B, $63
    db $FA, $F7, $F0, $3C, $4C, $52, $62, $49, $4C, $50, $42, $63, $FA, $F7, $F0, $F9
    db $00, $62, $50, $52, $4F, $4F, $42, $4B, $41, $42, $4F, $42, $41, $F1, $F9, $10
    db $5F, $F7, $F0, $F9, $10, $62, $54, $3E, $50, $F1, $51, $3E, $48, $42, $4B, $62
    db $3F, $56, $62, $F9, $00, $5F, $F7, $F0, $3A, $2B, $32, $2C, $31, $29, $32, $32
    db $2E, $30, $32, $31, $28, $2A, $2A, $F0, $37, $45, $42, $62, $4A, $4C, $4B, $50
    db $51, $42, $4F, $EF, $EE, $43, $3E, $4F, $4A, $62, $46, $50, $62, $43, $52, $49
    db $49, $63, $FA, $F7, $EF, $EE, $27, $4C, $62, $56, $4C, $52, $62, $54, $3E, $4B
    db $51, $62, $51, $4C, $EF, $EE, $4F, $42, $4D, $49, $3E, $40, $42, $62, $4C, $4B
    db $42, $62, $4C, $43, $FA, $F7, $EF, $EE, $56, $4C, $52, $4F, $62, $4A, $4C, $4B
    db $50, $51, $42, $4F, $50, $EF, $EE, $54, $46, $51, $45, $62, $51, $45, $46, $50
    db $62, $4C, $4B, $42, $64, $F0, $F9, $10, $62, $F1, $46, $50, $62, $4F, $42, $51
    db $52, $4F, $4B, $42, $41, $62, $51, $4C, $FA, $F7, $F2, $51, $45, $42, $62, $54
    db $46, $49, $41, $5F, $F1, $F7, $F0, $35, $42, $4D, $49, $3E, $40, $42, $62, $54
    db $46, $51, $45, $F1, $54, $45, $46, $40, $45, $62, $4A, $4C, $4B, $50, $51, $42
    db $4F, $64, $F0, $2C, $50, $62, $51, $45, $46, $50, $62, $4A, $4C, $4B, $50, $51
    db $42, $4F, $F1, $32, $2E, $62, $51, $4C, $62, $4F, $42, $4D, $49, $3E, $40, $42
    db $64, $F0, $27, $4C, $62, $56, $4C, $52, $62, $54, $3E, $4B, $51, $62, $51, $4C
    db $F1, $4F, $42, $4D, $49, $3E, $40, $42, $62, $4C, $4B, $42, $62, $4C, $43, $FA
    db $F7, $F2, $56, $4C, $52, $4F, $62, $4A, $4C, $4B, $50, $51, $42, $4F, $50, $F1
    db $54, $46, $51, $45, $62, $51, $45, $46, $50, $62, $4C, $4B, $42, $64, $F0, $37
    db $45, $42, $4F, $42, $62, $54, $46, $49, $49, $62, $3F, $42, $62, $4B, $4C, $F1
    db $4C, $4B, $42, $62, $49, $42, $43, $51, $62, $46, $4B, $62, $51, $45, $42, $FA
    db $F7, $F2, $40, $52, $4F, $4F, $42, $4B, $51, $62, $4D, $3E, $4F, $51, $56, $62
    db $51, $4C, $F1, $43, $46, $44, $45, $51, $5F, $F7, $F0, $35, $42, $4D, $49, $3E
    db $40, $42, $62, $54, $46, $51, $45, $F1, $54, $45, $46, $40, $45, $62, $4A, $4C
    db $4B, $50, $51, $42, $4F, $64, $F0, $31, $4C, $62, $42, $44, $44, $5F, $F7, $F0
    db $35, $42, $4D, $49, $3E, $40, $42, $62, $54, $46, $51, $45, $F1, $54, $45, $46
    db $40, $45, $62, $42, $44, $44, $64, $F0, $F9, $10, $62, $F1, $46, $50, $62, $4F
    db $42, $51, $52, $4F, $4B, $42, $41, $62, $51, $4C, $FA, $F7, $F2, $51, $45, $42
    db $62, $54, $46, $49, $41, $5F, $F1, $F7, $F0, $2C, $37, $28, $30, $F0, $3A, $3E
    db $4B, $51, $62, $51, $4C, $62, $4F, $42, $40, $4C, $4F, $41, $F1, $56, $4C, $52
    db $4F, $62, $4E, $52, $42, $50, $51, $64, $E6, $F0, $36, $3E, $53, $42, $41, $63
    db $62, $33, $49, $42, $3E, $50, $42, $62, $51, $52, $4F, $4B, $F1, $4C, $43, $43
    db $62, $51, $45, $42, $62, $4D, $4C, $54, $42, $4F, $5F, $F0, $37, $45, $3E, $4B
    db $48, $62, $56, $4C, $52, $63, $F1, $F7, $F2, $33, $49, $42, $3E, $50, $42, $62
    db $51, $52, $4F, $4B, $62, $4C, $43, $43, $F1, $51, $45, $42, $62, $4D, $4C, $54
    db $42, $4F, $5F, $F0, $40, $45, $42, $4B, $5F, $47, $5F, $4B, $B4, $9B, $F0, $3C
    db $4C, $52, $62, $40, $3E, $4B, $4B, $4C, $51, $62, $40, $45, $4C, $4C, $50, $42
    db $F1, $51, $45, $42, $62, $4A, $4C, $4B, $50, $51, $42, $4F, $62, $46, $4B, $FA
    db $F7, $F2, $56, $4C, $52, $4F, $62, $40, $52, $4F, $4F, $42, $4B, $51, $62, $4D
    db $3E, $4F, $51, $56, $F1, $3E, $50, $62, $3E, $62, $4D, $4F, $46, $57, $42, $5F
    db $F7, $F0, $33, $49, $42, $3E, $50, $42, $62, $40, $45, $4C, $4C, $50, $42, $62
    db $3E, $F1, $4A, $4C, $4B, $50, $51, $42, $4F, $62, $43, $4F, $4C, $4A, $62, $51
    db $45, $42, $FA, $F7, $F2, $43, $3E, $4F, $4A, $5F, $F1, $F7, $F0, $37, $4C, $4C
    db $62, $3F, $3E, $41, $5F, $5F, $5F, $F1, $25, $4F, $42, $42, $41, $46, $4B, $44
    db $62, $43, $3E, $46, $49, $42, $41, $5F, $F7, $F0, $25, $28, $2A, $2C, $31, $31
    db $2C, $31, $2A, $A3, $F0, $39, $2C, $2F, $2F, $24, $2A, $28, $35, $A3, $F0, $37
    db $24, $2F, $2C, $36, $30, $24, $31, $A3, $F0, $30, $28, $30, $32, $35, $2C, $28
    db $36, $A3, $F0, $25, $28, $3A, $2C, $2F, $27, $28, $35, $A3, $F0, $33, $28, $24
    db $26, $28, $A3, $F0, $25, $35, $24, $39, $28, $35, $3C, $A3, $F0, $36, $37, $35
    db $28, $31, $2A, $37, $2B, $A3, $F0, $24, $31, $2A, $28, $35, $A3, $F0, $2D, $32
    db $3C, $A3, $F0, $3A, $2C, $36, $27, $32, $30, $A3, $F0, $2B, $24, $33, $33, $2C
    db $31, $28, $36, $36, $A3, $F0, $37, $28, $30, $33, $37, $24, $37, $2C, $32, $31
    db $A3, $F0, $2F, $24, $25, $3C, $35, $2C, $31, $37, $2B, $A3, $F0, $2D, $38, $27
    db $2A, $30, $28, $31, $37, $A3, $F0, $35, $28, $29, $2F, $28, $26, $37, $2C, $32
    db $31, $A3, $F0, $F0, $37, $45, $46, $50, $62, $32, $4D, $51, $46, $4C, $4B, $62
    db $46, $50, $F1, $52, $4B, $3E, $53, $3E, $46, $49, $3E, $3F, $49, $42, $62, $54
    db $46, $51, $45, $FA, $F7, $F2, $36, $52, $4D, $42, $4F, $62, $2A, $3E, $4A, $42
    db $62, $25, $4C, $56, $5F, $F1, $F7, $F0, $36, $2F, $2C, $35, $F0, $36, $2F, $38
    db $33, $F0, $35, $38, $2E, $3C, $F0, $36, $24, $2F, $3C, $F0, $33, $32, $36, $3C
    db $F0, $33, $28, $37, $28, $F0, $36, $2F, $24, $26, $F0, $30, $28, $2F, $37, $F0
    db $36, $2F, $28, $28, $F0, $26, $24, $2F, $F0, $36, $2C, $2F, $F0, $36, $24, $2F
    db $F0, $30, $2C, $2F, $2C, $F0, $2F, $2C, $30, $28, $F0, $30, $24, $35, $26, $F0
    db $24, $38, $37, $30, $F0, $35, $28, $3B, $F0, $30, $32, $39, $28, $F0, $26, $2F
    db $32, $3A, $F0, $37, $24, $33, $F0, $2E, $2C, $37, $28, $F0, $3A, $2C, $2F, $27
    db $F0, $2A, $28, $28, $2E, $F0, $37, $2C, $28, $F0, $27, $35, $24, $26, $F0, $26
    db $24, $35, $3C, $F0, $25, $28, $37, $2B, $F0, $2F, $38, $2F, $38, $F0, $2C, $36
    db $3C, $36, $F0, $26, $2B, $28, $36, $F0, $2A, $2C, $35, $2F, $F0, $25, $28, $2F
    db $2F, $F0, $36, $24, $39, $3C, $F0, $33, $38, $2E, $3C, $F0, $25, $38, $2E, $3C
    db $F0, $25, $32, $31, $2A, $F0, $2A, $38, $31, $3C, $F0, $36, $38, $31, $3C, $F0
    db $30, $24, $3B, $F0, $27, $28, $2F, $32, $F0, $31, $28, $39, $3C, $F0, $37, $2C
    db $2F, $F0, $3C, $28, $37, $24, $F0, $36, $24, $36, $24, $F0, $30, $32, $2E, $32
    db $F0, $2E, $24, $35, $3C, $F0, $25, $24, $25, $3C, $F0, $2E, $2C, $37, $24, $F0
    db $25, $2C, $35, $27, $F0, $2F, $38, $26, $2E, $F0, $26, $2B, $2C, $33, $F0, $33
    db $24, $35, $2E, $F0, $2B, $28, $2E, $3C, $F0, $35, $24, $39, $28, $F0, $37, $32
    db $31, $3C, $F0, $35, $24, $27, $3C, $F0, $26, $38, $2E, $3C, $F0, $26, $32, $32
    db $F0, $2D, $32, $27, $3C, $F0, $25, $32, $31, $3C, $F0, $30, $2C, $36, $24, $F0
    db $30, $28, $2A, $F0, $2E, $28, $2F, $3C, $F0, $29, $28, $3C, $F0, $25, $32, $31
    db $3D, $F0, $3D, $32, $32, $2F, $F0, $25, $24, $25, $24, $F0, $30, $2C, $37, $3C
    db $F0, $2B, $32, $2F, $3C, $F0, $2E, $2C, $31, $3C, $F0, $2F, $38, $30, $33, $F0
    db $36, $2C, $32, $31, $F0, $28, $39, $28, $F0, $2F, $32, $37, $36, $F0, $35, $32
    db $36, $28, $F0, $26, $38, $2F, $F0, $2D, $2C, $2F, $2F, $F0, $25, $28, $26, $2E
    db $F0, $36, $2B, $3C, $F0, $29, $38, $35, $F0, $2E, $2C, $26, $36, $F0, $2D, $32
    db $2B, $31, $F0, $35, $2C, $30, $33, $F0, $33, $28, $28, $37, $F0, $2A, $35, $38
    db $F0, $25, $35, $38, $37, $F0, $37, $32, $33, $3C, $F0, $36, $37, $2C, $2E, $F0
    db $30, $24, $35, $3C, $F0, $2F, $3C, $31, $31, $F0, $25, $28, $37, $3C, $F0, $2B
    db $32, $31, $3C, $F0, $33, $32, $2F, $3C, $F0, $26, $32, $32, $2F, $F0, $2B, $24
    db $31, $24, $F0, $36, $38, $31, $F0, $30, $28, $29, $3C, $F0, $25, $28, $35, $2A
    db $F0, $30, $28, $35, $28, $F0, $25, $24, $35, $37, $F0, $25, $35, $38, $31, $F0
    db $25, $32, $2F, $27, $F0, $2F, $38, $2E, $28, $F0, $24, $30, $32, $36, $F0, $36
    db $24, $2F, $24, $F0, $33, $32, $2F, $24, $F0, $2D, $38, $27, $3C, $F0, $39, $2C
    db $39, $2C, $F0, $29, $2F, $32, $35, $F0, $36, $24, $27, $3C, $F0, $24, $30, $3C
    db $F0, $35, $32, $31, $24, $F0, $30, $2C, $2F, $F0, $3A, $2C, $2F, $F0, $37, $32
    db $32, $F0, $31, $28, $2E, $F0, $37, $28, $2E, $F0, $37, $32, $37, $32, $F0, $39
    db $32, $30, $2C, $F0, $2F, $2C, $2F, $2C, $F0, $25, $28, $2F, $3C, $F0, $2D, $28
    db $31, $3C, $F0, $29, $35, $24, $31, $F0, $27, $32, $35, $F0, $37, $3A, $28, $28
    db $F0, $2E, $24, $31, $24, $F0, $35, $24, $3C, $F0, $2D, $28, $36, $3C, $F0, $31
    db $2C, $37, $35, $F0, $33, $28, $33, $F0, $35, $32, $2E, $3C, $F0, $30, $28, $2A
    db $24, $F0, $29, $32, $37, $F0, $39, $2C, $31, $3C, $F0, $25, $32, $25, $F0, $35
    db $32, $25, $F0, $2D, $28, $2F, $F0, $35, $38, $25, $3C, $F0, $33, $24, $35, $2F
    db $F0, $24, $30, $28, $37, $F0, $33, $2C, $24, $F0, $37, $2C, $24, $F0, $36, $28
    db $35, $24, $F0, $35, $28, $27, $24, $F0, $27, $35, $24, $31, $F0, $33, $38, $33
    db $36, $F0, $26, $24, $35, $2F, $F0, $3D, $28, $28, $2E, $F0, $26, $35, $2C, $36
    db $F0, $2A, $32, $2F, $27, $F0, $2A, $2C, $2A, $24, $F0, $26, $28, $31, $37, $F0
    db $30, $24, $35, $2C, $F0, $24, $31, $31, $24, $F0, $28, $2F, $2F, $3C, $F0, $2F
    db $2C, $3D, $24, $F0, $25, $28, $2F, $24, $F0, $2F, $2C, $2F, $3C, $F0, $24, $31
    db $31, $F0, $25, $24, $35, $25, $F0, $30, $24, $35, $2C, $F0, $24, $31, $31, $24
    db $F0, $10, $F0, $11, $F0, $12, $F0, $13, $F0, $14, $F0, $15, $F0, $16, $F0, $17
    db $F0, $18, $F0, $19, $F0, $F0

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
; 256 entries, $F0 terminated, charmap encoded
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
SkillName_215_Sheldodge: db "Sheldodge", $F0
SkillName_216_Branching: db "Branching", $F0
SkillName_217_GigaSlash: db "GigaSlash", $F0
SkillName_218_LIFE: db "LIFE", $F0
SkillName_219_RUN: db "RUN", $F0
SkillName_220_IRONIZE: db "IRONIZE", $F0
SkillName_221_Ahhh: db "Ahhh", $F0
SkillName_222_Unused_222: db $F0
SkillName_223_DS: db "DS", $F0
SkillName_224_SP: db "SP", $F0
SkillName_225_WS: db "WS", $F0
SkillName_226_TS: db "TS", $F0
SkillName_227_SN: db "SN", $F0
SkillName_228_KN: db "KN", $F0
SkillName_229_BB: db "BB", $F0
SkillName_230_BX: db "BX", $F0
SkillName_231_SL: db "SL", $F0
SkillName_232_HL: db "HL", $F0
SkillName_233_FS: db "FS", $F0
SkillName_234_RS: db "RS", $F0
SkillName_235_SB: db "SB", $F0
SkillName_236_ST: db "ST", $F0
SkillName_237_SK: db "SK", $F0
SkillName_238_KS: db "KS", $F0
SkillName_239_MK: db "MK", $F0
SkillName_240_MB: db "MB", $F0
SkillName_241_MT: db "MT", $F0
SkillName_242_GS: db "GS", $F0
SkillName_243_DK: db "DK", $F0
SkillName_244_TG: db "TG", $F0
SkillName_245_PT: db "PT", $F0
SkillName_246_BG: db "BG", $F0
SkillName_247_BD: db "BD", $F0
SkillName_248_LM: db "LM", $F0
SkillName_249_PG: db "PG", $F0
SkillName_250_SD: db "SD", $F0
SkillName_251_DR: db "DR", $F0
SkillName_252_MD: db "MD", $F0
SkillName_253_DK: db "DK", $F0
SkillName_254_RB: db "RB", $F0
SkillName_255_CH: db "CH", $F0

; Unknown string data ($6A55-$6A83)
    db $2F, $29, $F0, $24, $27, $F0, $2F, $26, $F0, $36, $36, $F0, $2A, $27, $F0, $26  ; $6A55
    db $33, $F0, $3A, $36, $F0, $26, $37, $F0, $32, $35, $F0, $25, $35, $F0, $36, $27  ; $6A65
    db $F0, $27, $2A, $F0, $37, $2A, $F0, $2B, $25, $F0, $26, $29, $F0, $33, $35  ; $6A75

jr_041_6a84:
    ldh a, [$36]
    ld h, $f0
    ld a, [hl+]
    dec h
    ldh a, [$36]
    cpl

jr_041_6a8d:
    ldh a, [$3a]
    dec h

jr_041_6a90:
    ldh a, [rNR50]
    jr z, jr_041_6a84

    ld [hl], $37
    ldh a, [$2c]
    scf
    ldh a, [$30]
    jr nc, jr_041_6a8d

    dec hl
    jr nc, jr_041_6a90

    ld a, [hl+]
    dec a
    ldh a, [$3c]
    scf
    ldh a, [$30]
    ld a, [hl+]
    ldh a, [$29]
    dec [hl]
    ldh a, [$38]
    ld h, $f0
    ld a, [hl+]
    ld a, [hl+]
    ldh a, [$2e]
    inc h

jr_041_6ab4:
    ldh a, [$37]
    inc sp
    ldh a, [$2e]
    cpl
    ldh a, [$27]
    dec hl
    ldh a, [$30]
    ld h, $f0
    dec h
    jr z, jr_041_6ab4

    inc sp
    ld l, $f0
    ld a, [hl-]
    add hl, sp
    ldh a, [rNR51]
    dec h
    ldh a, [$29]
    dec l
    ldh a, [$27]
    ld l, $f0
    jr nc, @+$35

    ldh a, [$30]
    dec [hl]
    ldh a, [$30]
    ld a, [hl-]
    ldh a, [$27]
    ld l, $f0
    dec h
    dec [hl]
    ldh a, [$36]
    dec h
    ldh a, [$2f]
    ld [hl-], a
    ldh a, [$30]
    ld a, [hl+]
    ldh a, [$30]
    ld h, $f0
    dec h
    dec a
    ldh a, [$33]
    ld sp, $37f0
    dec hl
    ldh a, [$3a]
    dec hl

jr_041_6af9:
    ldh a, [$29]
    dec h
    ldh a, [$35]
    dec h
    ldh a, [$30]
    inc sp
    ldh a, [$29]
    ld a, [hl-]
    ldh a, [$29]
    jr nc, jr_041_6af9

    ld a, [hl-]
    scf
    ldh a, [rNR52]
    dec h
    ldh a, [$2a]
    inc sp
    ldh a, [$29]
    ld a, [hl+]
    ldh a, [rNR50]
    ld a, [hl-]
    ldh a, [$36]
    ld [hl], $f0
    ld [hl-], a
    ld sp, $27f0
    add hl, sp
    ldh a, [$37]
    dec h

jr_041_6b23:
    ldh a, [$29]
    scf
    ldh a, [$2b]
    jr nc, @-$0e

    dec h
    jr nc, @-$0e

    jr z, @+$38

    ldh a, [$30]
    jr z, jr_041_6b23

    ld [hl], $33
    ldh a, [$32]
    add hl, sp
    ldh a, [$3a]
    scf
    ldh a, [$2a]
    ld [hl], $f0
    ld h, $33
    ldh a, [$2a]
    ld h, $f0
    dec h
    add hl, hl
    ldh a, [$3a]
    dec h
    ldh a, [$2a]
    ld a, [hl-]

jr_041_6b4d:
    ldh a, [$2f]
    inc sp
    ldh a, [$36]
    dec h
    ldh a, [rNR50]
    inc h

jr_041_6b56:
    ldh a, [$2a]
    dec hl
    ldh a, [$37]
    jr z, jr_041_6b4d

    inc h
    inc sp
    ldh a, [$28]
    daa
    ldh a, [$2a]
    jr nc, jr_041_6b56

    daa
    dec [hl]
    ldh a, [rNR50]
    ld h, $f0
    jr nc, @+$2d

    ldh a, [$2b]
    dec h
    ldh a, [rNR50]
    inc sp

jr_041_6b74:
    ldh a, [$27]
    ld a, [hl+]

jr_041_6b77:
    ldh a, [$33]
    dec sp
    ldh a, [rNR50]
    daa
    ldh a, [rNR50]
    daa
    ldh a, [$27]
    jr nc, jr_041_6b74

    daa
    jr z, jr_041_6b77

    jr z, @+$27

    ldh a, [rNR51]
    dec [hl]
    ldh a, [$28]
    dec h
    ldh a, [rSB]
    jr z, @-$0e

    ld a, [hl+]
    dec [hl]
    ldh a, [$30]
    daa
    ldh a, [$2f]
    dec sp
    ldh a, [$2a]
    dec hl
    ldh a, [$32]
    ld h, $f0
    ld [hl-], a
    ld a, [hl+]
    ldh a, [$2a]
    ld a, [hl+]
    ldh a, [rNR52]
    ld h, $f0
    ld a, [hl+]
    dec [hl]
    ldh a, [rNR50]
    ld l, $f0
    jr nc, @+$30

    ldh a, [$2a]
    ld a, [hl+]
    ldh a, [rNR52]
    ld [hl], $f0
    jr z, jr_041_6be0

    ldh a, [$2d]
    inc h
    ldh a, [$27]
    dec [hl]

jr_041_6bc2:
    ldh a, [$36]
    inc sp
    ldh a, [$36]
    ld l, $f0
    daa
    dec a
    ldh a, [$35]
    dec [hl]
    ldh a, [$30]
    jr nc, jr_041_6bc2

    daa
    ld h, $f0
    daa
    ld sp, $36f0
    dec hl

jr_041_6bda:
    ldh a, [$33]
    scf
    ldh a, [$30]
    daa

jr_041_6be0:
    ldh a, [$31]
    ld a, [hl-]
    ldh a, [$28]
    ld [hl], $f0
    ld a, [hl-]
    jr nc, jr_041_6bda

    ld [hl], $37
    ldh a, [$27]
    ld sp, $2cf0
    ld l, $f0
    dec h
    ld [hl], $f0
    ld [hl], $2e
    ldh a, [$36]
    add hl, sp
    ldh a, [rNR52]
    ld h, $f0
    dec l
    dec h
    ldh a, [$28]
    ld a, [hl-]

jr_041_6c04:
    ldh a, [$30]
    ld h, $f0
    ld h, $25
    ldh a, [$30]
    ld l, $f0
    ld [hl], $25

jr_041_6c10:
    ldh a, [$30]
    jr nc, jr_041_6c04

    dec [hl]
    inc h

jr_041_6c16:
    ldh a, [$30]
    dec hl
    ldh a, [$39]
    daa
    ldh a, [$27]
    jr nc, jr_041_6c10

    dec h
    dec a
    ldh a, [$36]
    jr nc, jr_041_6c16

    ld h, $2f
    ldh a, [$2e]
    dec h
    ldh a, [$28]
    inc sp
    ldh a, [$2a]
    dec a
    ldh a, [$2f]
    jr nc, @-$0e

    inc l
    ld h, $f0
    jr nc, jr_041_6c6a

    ldh a, [$30]
    daa
    ldh a, [$2a]
    cpl
    ldh a, [$30]
    ld [hl], $f0
    dec h
    ld h, $f0
    ld a, [hl+]
    ld a, [hl+]

jr_041_6c49:
    ldh a, [$27]
    cpl

jr_041_6c4c:
    ldh a, [$27]
    cpl
    ldh a, [$2b]
    ld a, [hl+]
    ldh a, [$36]
    daa
    ldh a, [rNR51]
    jr nc, jr_041_6c49

    dec a
    jr nc, jr_041_6c4c

    inc sp
    dec a

jr_041_6c5e:
    ldh a, [$28]
    ld [hl], $f0
    jr nc, jr_041_6c8b

jr_041_6c64:
    ldh a, [$30]
    daa
    ldh a, [$30]
    daa

jr_041_6c6a:
    ldh a, [$27]
    jr nc, jr_041_6c5e

    daa
    jr nc, @-$0e

    daa
    jr nc, jr_041_6c64

    daa
    daa
    ldh a, [$f0]
    dec hl
    ld b, d
    ld c, a
    ccf
    ldh a, [$2f]
    ld c, h
    ld d, e
    ld b, d
    ld d, h
    ld a, $51
    ld b, d
    ld c, a
    ldh a, [$36]
    ld a, $44
    ld b, d

jr_041_6c8b:
    ld [hl], $51
    ld c, h
    ld c, e
    ld b, d
    ldh a, [$3a]
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    daa
    ld b, d
    ld d, h
    ldh a, [$33]
    ld c, h
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ldh a, [$28]
    ld c, c
    ld b, e
    ld a, [hl-]
    ld a, $51
    ld b, d
    ld c, a
    ldh a, [rNR50]
    ld c, e
    ld d, c
    ld b, [hl]
    ld b, c
    ld c, h
    ld d, c
    ld b, d
    ldh a, [$30]
    ld c, h
    ld c, h
    ld c, e
    dec hl
    ld b, d
    ld c, a
    ccf
    ldh a, [$36]
    ld c, b
    ld d, [hl]
    dec h
    ld b, d
    ld c, c
    ld c, c
    ldh a, [$2f]
    ld a, $52
    ld c, a
    ld b, d
    ld c, c
    ldh a, [rNR50]
    ld d, h
    ld a, $48
    ld b, d
    ld [hl], $3e
    ld c, e
    ld b, c
    ldh a, [$3a]
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    cpl
    ld b, d
    ld a, $43
    ldh a, [$2f]
    ld b, [hl]
    ld b, e
    ld b, d
    inc h
    ld b, b
    ld c, h
    ld c, a
    ld c, e
    ldh a, [$30]
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld sp, $5152
    ldh a, [rNR50]
    scf
    ld l, $50
    ld b, d
    ld b, d
    ld b, c
    ldh a, [$27]
    jr z, jr_041_6d27

    ld d, b
    ld b, d
    ld b, d
    ld b, c
    ldh a, [rNR50]
    ld a, [hl+]
    cpl
    ld d, b
    ld b, d
    ld b, d
    ld b, c
    ldh a, [$2c]
    ld sp, $5037
    ld b, d
    ld b, d
    ld b, c
    ldh a, [rNR51]
    ld b, d
    ld b, d
    ld b, e
    dec l
    ld b, d
    ld c, a
    ld c, b
    ld d, [hl]
    ldh a, [$33]
    ld c, h
    ld c, a
    ld c, b
    ld h, $45
    ld c, h
    ld c, l
    ldh a, [$35]

jr_041_6d27:
    ld b, [hl]
    ccf
    ldh a, [rNR51]
    ld a, $41
    jr nc, jr_041_6d71

    ld a, $51
    ldh a, [$36]
    ld b, [hl]
    ld c, a
    ld c, c
    ld c, h
    ld b, [hl]
    ld c, e
    ldh a, [rNR51]
    ld c, h
    ld c, c
    ld d, c
    ld [hl], $51
    ld a, $43
    ld b, e
    ldh a, [$3a]
    ld b, [hl]
    ld c, e
    ld b, c
    ld [hl], $51
    ld a, $43
    ld b, e
    ldh a, [$30]
    ld b, [hl]
    ld d, b
    ld d, c
    ld [hl], $51
    ld a, $43
    ld b, e
    ldh a, [$2f]
    ld a, $53
    ld a, $36
    ld d, c
    ld a, $43
    ld b, e
    ldh a, [$36]
    ld c, e
    ld c, h
    ld d, h
    ld [hl], $51
    ld a, $43
    ld b, e
    ldh a, [$3a]
    ld a, $4f
    ld c, l
    ld a, [hl-]

jr_041_6d71:
    ld b, [hl]
    ld c, e
    ld b, h
    ldh a, [$37]
    ld b, [hl]
    ld c, e
    ld d, [hl]
    jr nc, jr_041_6dbd

    ld b, c
    ld a, $49
    ldh a, [$34]
    ld d, d
    ld b, d
    ld d, b
    ld d, c
    dec h
    ld c, b
    ldh a, [$2b]
    ld c, h
    ld c, a
    ld c, a
    ld c, h
    ld c, a
    dec h
    ld l, $f0
    dec h
    ld b, d
    ld sp, $4046
    ld b, d
    dec h
    ld l, $f0
    ld h, $45
    ld b, d
    ld a, $51
    ld b, d
    ld c, a
    dec h
    ld l, $f0
    ld [hl], $4a
    ld a, $4f
    ld d, c
    dec h
    ld l, $f0
    ld h, $4c
    ld c, d
    ld b, d
    ld b, c
    ld d, [hl]
    dec h
    ld l, $f0
    add hl, hl
    ld b, [hl]
    ld c, a
    ld b, d
    ld [hl], $51
    ld a, $43
    ld b, e

jr_041_6dbd:
    ldh a, [rNR51]
    ld b, d
    ld a, $50
    ld d, c
    scf
    ld a, $46
    ld c, c
    ldh a, [$3a]
    ld a, $4f
    ld c, l
    ld [hl], $51
    ld a, $43
    ld b, e
    ldh a, [$35]
    ld b, d
    ld c, l
    ld b, d
    ld c, c
    ld c, c
    ld b, d
    ld c, e
    ld d, c
    ldh a, [$36]
    ld b, l
    ld b, [hl]
    ld c, e
    ld d, [hl]
    dec hl
    ld a, $4f
    ld c, l
    ldh a, [$30]
    ld a, $4d
    dec hl
    ld b, d
    ld c, a
    ccf
    ldh a, [rNR51]
    ld c, h
    ld c, h
    ld c, b
    jr nc, @+$40

    ld c, a
    ld c, b
    ldh a, [$f0]
    dec [hl]
    ld b, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    ld h, d
    ccf
    ld b, d
    ld d, c
    ld d, h
    ld b, d
    ld b, d
    ld c, e
    pop af
    inc bc
    nop
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    inc b
    nop
    ld h, d
    dec hl
    inc sp
    ldh a, [$35]
    ld b, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    ld h, d
    ccf
    ld b, d
    ld d, c
    ld d, h
    ld b, d
    ld b, d
    ld c, e
    pop af
    ld b, $00
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    rlca
    nop
    ld h, d
    dec hl
    inc sp
    ldh a, [$35]
    ld b, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    ld h, d
    ld b, $00
    ld h, d
    ld d, c
    ld c, h
    pop af
    rlca
    nop
    ld h, d
    dec hl
    inc sp
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld a, $49
    ld c, c
    ldh a, [$35]
    ld b, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    pop af
    ld c, d
    ld a, $55
    ld h, d
    dec hl
    inc sp
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld a, $49
    ld c, c
    ldh a, [$35]
    ld b, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    ld h, d
    ccf
    ld b, d
    ld d, c
    ld d, h
    ld b, d
    ld b, d
    ld c, e
    pop af
    ld [bc], a
    nop
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    inc bc
    nop
    ld h, d
    jr nc, jr_041_6eb6

    ldh a, [$35]
    ld b, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    ld h, d
    jr nc, jr_041_6ec2

    ld h, d
    ld d, c
    ld c, h
    pop af
    ld c, d
    ld a, $55
    ldh a, [rNR52]
    ld d, d
    ld c, a
    ld b, d
    ld d, b
    ld h, d
    ld c, l
    ld c, h
    ld b, [hl]
    ld d, b
    ld c, h
    ld c, e
    pop af
    ldh a, [rNR52]
    ld d, d
    ld c, a
    ld b, d
    ld d, b
    pop af
    ld c, l
    ld a, $4f
    ld a, $49
    ld d, [hl]
    ld d, b
    ld b, [hl]
    ld d, b
    ldh a, [rNR52]

jr_041_6eb6:
    ld d, d
    ld c, a
    ld b, d
    ld d, b
    ld h, d
    ld b, b
    ld c, h
    ld c, e
    ld b, e
    ld d, d
    ld d, b
    ld b, [hl]

jr_041_6ec2:
    ld c, h
    ld c, e
    pop af
    ldh a, [rNR51]
    ld c, a
    ld b, d
    ld a, $48
    ld d, b
    ld h, d
    ld a, $62
    ld b, b
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ldh a, [$3a]
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld a, $4b
    ld h, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ldh a, [$35]
    ld b, d
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    ld h, d
    ld a, $4b
    ld h, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ldh a, [$2c]
    ld c, e
    ld b, b
    ld c, a
    ld b, d
    ld a, $50
    ld b, d
    ld d, b
    ld h, d
    ld c, d
    ld a, $55
    ld h, d
    dec hl
    inc sp
    pop af
    ccf
    ld d, [hl]
    ld h, d
    dec b
    ldh a, [$2c]
    ld c, e
    ld b, b
    ld c, a
    ld b, d
    ld a, $50
    ld b, d
    ld d, b
    ld h, d
    ld c, d
    ld a, $55
    ld h, d
    jr nc, jr_041_6f4f

    pop af
    ccf
    ld d, [hl]
    ld h, d
    dec b
    ldh a, [$2c]
    ld c, e
    ld b, b
    ld c, a
    ld b, d
    ld a, $50
    ld b, d
    ld d, b
    ld h, d
    inc h
    scf
    scf
    inc h
    ld h, $2e
    pop af
    inc sp
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    inc bc
    ldh a, [$2c]
    ld c, e
    ld b, b
    ld c, a
    ld b, d
    ld a, $50
    ld b, d
    ld d, b
    ld h, d
    daa
    jr z, jr_041_6f74

    jr z, jr_041_6f7e

    ld [hl], $28

jr_041_6f4f:
    pop af
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    inc bc
    ldh a, [$2c]
    ld c, e
    ld b, b
    ld c, a
    ld b, d
    ld a, $50
    ld b, d
    ld d, b
    ld h, d
    inc h
    ld a, [hl+]
    inc l
    cpl
    inc l
    scf
    inc a
    ld h, d
    pop af
    ccf
    ld d, [hl]
    ld h, d
    inc bc
    ldh a, [$2c]

jr_041_6f74:
    ld c, e
    ld b, b
    ld c, a
    ld b, d
    ld a, $50
    ld b, d
    ld d, b
    pop af
    inc l

jr_041_6f7e:
    ld sp, $2837
    cpl
    cpl
    inc l
    ld a, [hl+]
    jr z, jr_041_6fb8

    ld h, $28
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    inc bc
    ldh a, [$37]
    ld a, $4a
    ld b, d
    ld d, b
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    pop af
    ldh a, [$30]
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld b, c
    ld a, $4a
    ld a, $44
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    pop af
    ld a, $62
    ld c, c
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c

jr_041_6fb8:
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ccf
    ld c, h
    ld c, c
    ld d, c
    ldh a, [$30]
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld b, c
    ld a, $4a
    ld a, $44
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    pop af
    ld a, $62
    ld d, e
    ld a, $40
    ld d, d
    ld d, d
    ld c, d
    ldh a, [rNR51]
    ld c, c
    ld c, h
    ld b, b
    ld c, b
    ld d, b
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld c, c
    ld c, c
    ld d, b
    pop af
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
    ld c, d
    ld b, [hl]
    ld d, b
    ld d, c
    ldh a, [$30]
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld b, c
    ld a, $4a
    ld a, $44
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    pop af
    ld c, d
    ld a, $44
    ld c, d
    ld a, $f0
    jr nc, jr_041_704f

    ld c, b
    ld b, d
    ld d, b
    ld h, d
    ld b, c
    ld a, $4a
    ld a, $44
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    pop af
    ld a, $62
    ld d, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld c, d
    ldh a, [$3a]
    ld a, $4f
    ld c, l
    ld d, b
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    pop af
    ld b, b
    ld a, $50
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, b
    ld d, c
    ld a, $4b
    ld d, c
    ld c, c
    ld d, [hl]
    ldh a, [rNR52]
    ld c, h

jr_041_704f:
    ld c, c
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    pop af
    ld b, d
    ld d, l
    ld b, b
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, c
    ld b, d
    ld c, d
    ld d, b
    ldh a, [rNR52]
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld d, b
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld l, b
    pop af
    inc sp
    ld b, d
    ld c, a
    ld d, b
    ld c, h
    ld c, e
    ld a, $49
    ld b, [hl]
    ld d, c
    ld d, [hl]
    ldh a, [rNR51]
    ld d, d
    ld c, a
    ld c, e
    ld d, b
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, d
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    pop af
    ld a, $62
    ld c, d
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld d, [hl]
    ld h, d
    ccf
    ld c, c
    ld a, $57
    ld b, d
    ldh a, [$33]
    ld c, h
    ld b, [hl]
    ld c, e
    ld d, c
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld a, $56
    ld h, d
    ld d, c
    ld c, h
    pop af
    ld a, $62
    ld c, d
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, d
    ldh a, [$3a]
    ld a, $4f
    ld c, l
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld a, $f1
    ld c, d
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, d
    ldh a, [$35]
    ld b, d
    ld c, l
    ld b, d
    ld c, c
    ld d, b
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ldh a, [rNR50]
    ld d, c
    ld d, c
    ld c, a
    ld a, $40
    ld d, c
    ld d, b
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    pop af
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, d
    ld b, d
    ld c, c
    ld c, h
    ld b, c
    ld d, [hl]
    ldh a, [$2f]
    ld b, d
    ld d, c
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    ld b, d
    ld c, e
    ld d, c
    ld b, [hl]
    ld c, a
    ld b, d
    ld h, d
    ld c, c
    ld a, $4b
    ld b, c
    ld d, b
    ld b, b
    ld a, $4d
    ld b, d
    ldh a, [$35]
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    ld d, b
    ld h, d
    ld c, l
    ld c, a
    ld c, h
    ld b, h
    ld c, a
    ld b, d
    ld d, b
    ld d, b
    pop af
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    dec l
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ldh a, [$2b]
    ld [hl-], a
    scf
    dec h
    cpl
    ld [hl-], a
    ld [hl-], a
    daa
    ldh a, [$27]
    inc h
    dec [hl]
    inc l
    ld sp, $f02a
    daa
    inc h
    dec [hl]
    jr z, jr_041_7195

    jr z, @+$3b

    inc l
    cpl
    ldh a, [$2f]
    ld [hl-], a
    ld sp, $6228
    ld a, [hl-]
    ld [hl-], a
    cpl
    add hl, hl
    ldh a, [$39]
    inc h
    inc l
    ld sp, $28f0
    dec a
    ld h, d
    ld a, [hl+]
    ld [hl-], a
    inc l
    ld sp, $f02a
    ld [hl], $30
    jr c, jr_041_71b9

    ldh a, [$36]
    ld sp, $2532
    dec h

jr_041_7195:
    inc a
    ldh a, [$35]
    jr z, jr_041_71c0

jr_041_719a:
    ld l, $2f
    jr z, jr_041_71d4

    ld [hl], $f0
    ld h, $32
    ld [hl-], a
    cpl
    sbc [hl]
    ld h, $24
    cpl
    jr nc, jr_041_719a

    ld a, [hl-]
    dec hl
    inc l
    jr nc, @+$38

    inc a
    ldh a, [$31]
    ld [hl-], a
    ld [hl], $3c
    ldh a, [$3a]
    dec hl
    inc l

jr_041_71b9:
    dec a
    ld h, d
    ld l, $2c
    daa
    ldh a, [$32]

jr_041_71c0:
    dec [hl]
    daa
    inc l
    ld sp, $3524
    inc a
    ldh a, [$2b]
    inc h
    ld [hl], $37
    inc a
    ldh a, [$36]
    scf
    jr c, jr_041_71f7

    dec h
    ld [hl-], a

jr_041_71d4:
    dec [hl]
    ld sp, $35f0
    jr z, jr_041_71ff

    jr z, @+$31

    ldh a, [$36]
    inc sp
    ld [hl-], a
    inc l
    cpl
    jr z, @+$29

    ldh a, [$2b]
    jr c, @+$32

    inc h
    ld sp, $f028
    jr c, jr_041_721f

    ld h, $28
    dec [hl]
    scf
    inc h
    inc l
    ld sp, $26f0

jr_041_71f7:
    inc h
    dec [hl]
    jr z, jr_041_722a

    jr z, jr_041_7233

    ld [hl], $f0

jr_041_71ff:
    ld [hl], $2b
    dec [hl]
    jr z, jr_041_723e

    jr z, jr_041_722d

    ldh a, [rNR52]
    inc h

jr_041_7209:
    dec [hl]
    jr z, jr_041_7235

    dec [hl]
    jr z, @+$2a

    ldh a, [$2a]
    jr c, @+$31

    cpl
    inc l
    dec h
    cpl
    jr z, jr_041_7209

    ld [hl], $2f
    inc a
    ldh a, [rNR52]
    ld [hl-], a

jr_041_721f:
    ld a, [hl-]
    inc h

jr_041_7221:
    dec [hl]
    daa
    ldh a, [$2f]
    inc h
    dec a
    inc a
    ldh a, [rNR52]

jr_041_722a:
    dec hl
    inc h
    dec [hl]

jr_041_722d:
    ld a, [hl+]
    jr z, jr_041_7221

    jr nc, @+$2e

    dec sp

jr_041_7233:
    jr z, jr_041_725c

jr_041_7235:
    pop af
    ld h, $24
    jr c, jr_041_7271

    inc l
    ld [hl-], a
    jr c, jr_041_7274

jr_041_723e:
    pop af
    ld h, $32
    jr nc, jr_041_7273

    inc h
    ld sp, $f027
    ld sp, hl
    nop
    ld h, d
    ld b, [hl]
    ld c, e
    ld b, b
    ld c, a
    ld b, d
    ld a, $50
    ld b, d
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    cpl
    add hl, sp
    ld h, d
    ld sp, hl
    db $10

jr_041_725c:
    ld h, e
    ld a, [$f0f7]
    db $ed
    ld sp, hl
    nop
    ld h, d
    ld b, [hl]
    ld c, e
    ld b, b
    ld c, a
    ld b, d
    ld a, $50
    ld b, d
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d

jr_041_7271:
    cpl
    add hl, sp

jr_041_7273:
    ld h, d

jr_041_7274:
    ld sp, hl
    db $10
    ld a, [$f2f7]
    ld a, $4b
    ld b, c
    ld h, d
    ld c, c
    ld b, d
    ld a, $4f
    ld c, e
    ld b, d
    ld b, c

jr_041_7284:
    pop af
    ld sp, hl
    jr nz, jr_041_72eb

    ld a, [$f0f7]
    db $ed
    ld sp, hl
    nop
    ld l, b
    ld h, d
    ld sp, hl
    jr nc, jr_041_7284

    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld d, b
    ld h, d
    ld sp, hl
    jr nz, jr_041_7301

    ld a, [$f0f7]
    db $ed
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld sp, hl
    nop
    pop af
    ld b, b
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld a, [$f2f7]
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    ld h, e
    pop af
    ld a, [$f2f7]
    di
    db $ed
    add hl, hl
    ld c, h
    ld c, a
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld d, h
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    pop af
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, h
    ld a, [$f0f7]
    db $ed
    ld [hl-], a
    ld l, $62
    ld d, c
    ld c, h

jr_041_72eb:
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld b, h
    ld b, d
    ld d, c
    pop af
    ld sp, hl
    nop
    ld h, h
    ldh a, [$ed]
    add hl, hl
    ld c, h
    ld c, a
    ld b, h
    ld b, d
    ld d, c
    ld d, b
    ld h, d
    ld sp, hl

jr_041_7301:
    nop
    ld h, e
    ld a, [$f0f7]
    db $ed
    add hl, hl
    ld c, h
    ld c, a
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld d, h
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    pop af
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, h
    ld a, [$f0f7]
    jr z, jr_041_7372

    ld b, d
    ld c, a
    ld d, [hl]
    ld c, h
    ld c, e
    ld b, d
    pop af
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld a, $51
    ld h, d
    ld a, $62
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld e, a
    ldh a, [$3a]
    ld b, l
    ld c, h
    ld h, d
    jr c, @+$52

    ld h, d
    scf
    ld b, l
    ld c, d
    ldh a, [$3a]
    dec hl
    ld [hl-], a
    ld [hl], $37
    dec [hl]
    ld [hl-], a
    ld l, $f0
    add hl, hl
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ldh a, [rNR13]
    rst $18
    ld [de], a
    adc l
    db $10
    ld e, $11
    db $10
    adc l
    pop de
    adc l
    db $10
    adc l
    ld h, a
    ldh a, [$ed]
    or $62
    ld c, a
    ld b, d
    ld b, b
    ld b, d
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    nop
    ld h, d
    jr z, jr_041_73c4

    ld c, l
    ld h, d
    ld c, l

jr_041_7372:
    ld d, c
    ld d, b
    ld h, e
    ld a, [$f0f7]
    db $ed
    ld sp, hl
    nop
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld b, b
    ld b, l
    ld a, $4b
    ld b, b
    ld b, d
    ld e, [hl]
    pop af
    ld c, a
    ld b, d
    ld b, b
    ld a, $49

jr_041_738c:
    ld c, c
    ld d, b
    ld h, d
    ld sp, hl
    jr nz, jr_041_738c

    rst $30
    ld a, [c]
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, d
    ld b, d
    ld c, d
    ld c, h
    ld c, a
    ld d, [hl]
    ld h, e
    pop af
    ld a, [$f0f7]
    db $ed
    ld a, [hl-]
    ld c, h
    ld d, h
    ld h, e
    ld h, d
    ld sp, hl
    nop
    pop af
    ld b, h
    ld c, h
    ld d, c
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$f2f7]
    ld c, c
    ld c, h
    ld c, h

jr_041_73c4:
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $51
    ld h, d
    ld d, d
    ld d, b
    ld h, e
    pop af
    ld a, [$f2f7]
    db $ed
    ld a, [hl-]
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    pop af
    ld sp, hl
    nop
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    ld a, [$f2f7]
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, l
    ld a, $4f
    ld d, c
    ld d, [hl]
    ld h, h
    pop af
    ldh a, [$ed]
    ld h, $3e
    ld c, e
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld h, d
    ld a, $4b
    ld d, [hl]
    pop af
    ld c, d
    ld c, h
    ld c, a
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
    ld h, e
    ld a, [$f2f7]
    db $ed
    ld a, [hl-]
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld a, $56
    ld h, d
    ccf
    ld d, [hl]
    ld b, d
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$f2f7]
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    pop af
    ld a, $62
    ld c, e
    ld b, d
    ld d, h
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, h
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    pop af
    ld d, b
    ld a, $41
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld c, c
    ld b, d
    ld a, $53
    ld b, d
    ld d, b
    ld e, a
    ld a, [$f0f7]
    db $ed
    ld h, $45
    ld c, h
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld a, $62
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld c, a
    ld b, d
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld e, a
    ldh a, [$ed]
    dec [hl]
    ld b, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld d, b
    ld h, d
    ld sp, hl
    nop
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld b, c
    ld e, a
    ld a, [$f0f7]
    db $ed
    ld a, [hl-]
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    pop af
    ld sp, hl
    nop
    ld a, [$f2f7]
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, h
    ld c, e
    pop af
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, [hl]
    ld d, d
    ld b, d
    ld d, b
    ld d, c
    ld h, h
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld b, l
    ld b, d
    ld a, $41
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld e, a
    ld a, [$f0f7]
    db $ed
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    pop af
    ld sp, hl
    nop
    ld e, a
    ld a, [$f0f7]
    db $ed
    ld h, $45
    ld c, h
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld a, $62
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    pop af
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld e, a
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld b, l
    ld b, d
    ld a, $41
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld e, a
    ld a, [$f0f7]
    db $ed
    ld a, [hl-]
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, h
    ldh a, [$62]
    ld h, d
    ld h, d
    ld h, d
    jr nc, jr_041_7585

    ld sp, $2a28
    ld a, [hl+]
    inc l
    ld sp, $3229
    ldh a, [$ed]
    ld sp, $624c
    ld b, d
    ld b, h
    ld b, h
    ld d, b
    ld e, a
    ld a, [$f0f7]
    db $ed
    dec [hl]
    ld b, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, h

jr_041_7581:
    ld b, [hl]
    ld c, c
    ld b, c
    ld e, a

jr_041_7585:
    ld a, [$f0f7]
    db $ed
    ld sp, hl
    nop
    add sp, $08
    nop
    jr nc, @+$40

    ld d, l
    ld h, d
    dec hl
    inc sp
    ld h, d
    and d
    ld sp, hl
    jr nz, jr_041_7581

    nop
    ld bc, $392f
    ld sp, hl
    db $10
    add sp, $08
    ld bc, $3e30
    ld d, l

jr_041_75a5:
    ld h, d
    jr nc, jr_041_75db

    ld h, d
    and d
    ld sp, hl
    inc h
    ld a, [$f2f7]
    db $ed
    ld sp, hl
    nop
    add sp, $08
    nop
    inc h
    scf
    ld l, $62
    and d
    ld sp, hl
    jr z, jr_041_75a5

    nop
    ld bc, $392f
    ld sp, hl
    db $10
    add sp, $08
    ld bc, $2827
    add hl, hl
    ld h, d
    and d
    ld sp, hl
    inc l
    ld a, [$f2f7]
    db $ed
    ld sp, hl
    nop
    add sp, $08
    nop
    inc h
    ld a, [hl+]
    cpl
    ld h, d
    and d

jr_041_75db:
    ld sp, hl
    jr nc, @-$16

    nop
    ld bc, $392f
    ld sp, hl
    db $10
    add sp, $08
    ld bc, $312c
    scf

jr_041_75ea:
    ld h, d
    and d
    ld sp, hl
    inc [hl]
    ld a, [$f0f7]
    db $ed
    ld sp, hl
    nop
    add sp, $08
    nop
    jr nc, @+$40

    ld d, l
    ld h, d
    dec hl
    inc sp
    ld h, d
    sbc h
    ld sp, hl
    jr nz, jr_041_75ea

    nop
    ld bc, $392f
    ld sp, hl
    db $10
    add sp, $08
    ld bc, $3e30
    ld d, l

jr_041_760e:
    ld h, d
    jr nc, jr_041_7644

    ld h, d
    sbc h
    ld sp, hl
    inc h
    ld a, [$f2f7]
    db $ed
    ld sp, hl
    nop
    add sp, $08
    nop
    inc h
    scf
    ld l, $62
    sbc h
    ld sp, hl
    jr z, jr_041_760e

    nop
    ld bc, $392f
    ld sp, hl
    db $10
    add sp, $08
    ld bc, $2827
    add hl, hl
    ld h, d
    sbc h
    ld sp, hl
    inc l
    ld a, [$f2f7]
    db $ed
    ld sp, hl
    nop
    add sp, $08
    nop
    inc h
    ld a, [hl+]
    cpl
    ld h, d
    sbc h

jr_041_7644:
    ld sp, hl
    jr nc, @-$16

    nop
    ld bc, $392f
    ld sp, hl
    db $10
    add sp, $08
    ld bc, $312c
    scf
    ld h, d
    sbc h
    ld sp, hl
    inc [hl]
    ld a, [$f0f7]
    db $ed
    inc a
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
    ld h, d
    ld b, l
    ld a, $50
    pop af
    ld b, e
    ld d, d
    ld c, c
    ld c, c
    ld d, [hl]
    ld h, d
    ld b, h
    ld c, a
    ld c, h
    ld d, h
    ld c, e
    ld e, a
    ld a, [$f0f7]
    db $ed
    ld sp, hl
    nop
    pop af
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld d, b
    rst $30
    ld a, [c]
    ld sp, hl
    db $10
    ld h, e
    pop af
    ld a, [$f0f7]
    db $ed
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld b, b
    ld b, l
    ld c, h
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld a, $4b
    pop af
    ld b, d
    ld b, h
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld c, e
    ld b, c
    ld h, d
    ld a, $54
    ld a, $56
    ld e, a
    ldh a, [$ed]
    or $62
    ld c, a
    ld b, d
    ld b, b
    ld b, d
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    nop
    ld h, d
    jr z, jr_041_7719

    ld c, l
    ld h, d
    ld c, l
    ld d, c
    ld d, b
    ld e, a
    ld a, [$f0f7]
    db $ed
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld c, e
    ld c, h
    pop af
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld c, c
    ld b, d
    ld b, e
    ld d, c
    ld a, [$f2f7]
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, l
    ld a, $4f
    ld d, c
    ld d, [hl]
    ld e, a
    pop af
    ld a, [$f0f7]
    db $ed
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, d
    ld a, $4d
    ld c, l
    ld b, d
    ld a, $4f
    ld d, b
    pop af
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d

jr_041_7719:
    ld c, e
    ld c, h
    ld d, h
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    ld a, [$f2f7]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    pop af
    ld b, c
    ld b, [hl]
    ld d, b
    ld a, $4d

jr_041_7731:
    ld c, l
    ld b, d
    ld a, $4f
    ld d, b
    ld h, e
    rst $30
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld sp, hl
    jr nz, jr_041_7731

    ld b, e
    ld a, $49
    ld c, c
    ld d, b
    ld h, d
    ld a, $4d
    ld a, $4f
    ld d, c
    ld h, e
    rst $30
    ldh a, [$f9]
    nop
    ld h, d
    ld d, d
    ld d, b
    ld b, d

jr_041_7754:
    ld d, b
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld sp, hl
    jr nz, jr_041_7754

    ld a, [c]
    ld a, $50
    ld h, d
    ld a, $62
    ld d, c
    ld c, h
    ld c, h
    ld c, c
    ld e, a
    pop af
    rst $30
    ldh a, [rNR51]
    ld d, d
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    pop af
    ld b, l
    ld a, $4d
    ld c, l
    ld b, d
    ld c, e
    ld d, b
    ld e, a
    rst $30
    ldh a, [$f9]
    nop
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld d, b
    pop af
    ld bc, $f962
    jr nz, jr_041_77f0

    ld c, h
    ld c, e
    rst $30
    ld a, [c]
    ld sp, hl
    db $10
    ld e, a
    pop af
    rst $30
    ldh a, [$f9]
    db $10
    ld l, b
    pop af
    ld d, h
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld a, $49
    ld d, b
    ld e, a
    rst $30
    ldh a, [$f9]
    nop
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, c
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    ld [hl], $3e
    ld b, h
    ld b, d
    ld [hl], $51
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$f2f7]
    ld d, b
    ld c, b
    ld d, [hl]
    ld h, e
    pop af
    rst $30
    ldh a, [$f9]
    nop
    pop af
    ld d, b
    ld c, l
    ld c, a
    ld b, [hl]
    ld c, e
    ld c, b
    ld c, c
    ld b, d
    ld d, b
    rst $30
    ld a, [c]
    ld sp, hl
    jr nz, jr_041_7845

    pop af
    rst $30
    ldh a, [$f9]
    db $10
    ld l, b
    pop af
    jr nc, jr_041_781e

    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld c, h

jr_041_77f0:
    ld d, e
    ld b, d
    ld c, a
    ld d, b
    ld h, e
    rst $30
    ldh a, [$f9]
    db $10
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, b
    ld d, d
    ld c, a
    ld b, d
    ld b, c
    ld h, e
    rst $30
    ldh a, [$f9]
    db $10
    ld l, b
    pop af
    ld c, l
    ld a, $4f
    ld a, $49
    ld d, [hl]
    ld d, b
    ld b, [hl]
    ld d, b
    rst $30
    ld a, [c]
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, b
    ld d, d
    ld c, a
    ld b, d
    ld b, c
    ld h, e
    pop af

jr_041_781e:
    rst $30
    ldh a, [$f9]
    db $10
    pop af
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld d, b
    ld h, e
    rst $30
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld h, d
    ld b, b
    ld a, $50
    ld d, c
    ld h, d
    ld c, h
    ld c, e
    pop af
    ld sp, hl
    db $10
    rst $30
    ld a, [c]
    ld b, [hl]

jr_041_7845:
    ld d, b
    ld h, d
    ccf
    ld c, a
    ld c, h
    ld c, b
    ld b, d
    ld c, e
    ld h, e
    pop af
    rst $30
    ldh a, [$f9]
    db $10
    pop af
    ld d, h
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld d, d
    ld c, l
    ld h, e
    rst $30
    ldh a, [$f9]
    db $10
    pop af
    ld c, a
    ld b, d
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    ld h, e
    rst $30
    ldh a, [$f9]
    db $10
    ld l, b
    ld h, d
    ld c, d
    ld a, $55
    ld h, d
    dec hl
    inc sp
    pop af
    ld b, h
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld sp, hl
    jr nc, jr_041_78e8

    rst $30
    ldh a, [$f9]
    db $10
    ld l, b
    ld h, d
    ld c, d
    ld a, $55
    ld h, d
    jr nc, jr_041_78c4

    pop af
    ld b, h
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld sp, hl
    jr nc, jr_041_7903

    rst $30
    ldh a, [$f9]
    db $10
    ld l, b
    ld h, d
    inc h
    scf
    ld l, $f1
    ld b, h
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld sp, hl
    jr nc, jr_041_791b

    rst $30
    ldh a, [$f9]
    db $10
    ld l, b
    ld h, d
    daa
    jr z, @+$2b

    pop af
    ld b, h
    ld c, h

jr_041_78c4:
    ld b, d
    ld d, b
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld sp, hl
    jr nc, jr_041_7933

    rst $30
    ldh a, [$f9]
    db $10
    ld l, b
    ld h, d
    inc h
    ld a, [hl+]
    cpl
    pop af
    ld b, h
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld sp, hl
    jr nc, jr_041_794b

jr_041_78e8:
    rst $30
    ldh a, [$f9]
    db $10
    ld l, b
    ld h, d
    inc l
    ld sp, $f137
    ld b, h
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld sp, hl
    jr nc, jr_041_7963

    rst $30
    ldh a, [$f9]

jr_041_7903:
    nop
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld e, [hl]
    rst $30
    ld a, [c]
    ld a, $62
    ld sp, hl
    jr nz, jr_041_7978

    pop af
    rst $30
    ldh a, [$f9]
    db $10
    ld h, d

jr_041_791b:
    ld b, d
    ld a, $51
    ld d, b
    pop af
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, l
    ld a, $4d
    ld c, l
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, e
    rst $30
    ld a, [c]
    ld sp, hl
    db $10
    ld h, d
    ccf
    ld b, d
    ld b, h

jr_041_7933:
    ld b, [hl]
    ld c, e
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    or $63
    rst $30
    ldh a, [$f9]
    db $10
    ld h, d
    ld b, d
    ld a, $51
    ld d, b
    pop af

jr_041_794b:
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, b
    ld a, $52
    ld d, c
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
    ld c, c
    ld d, [hl]
    ld h, e
    rst $30
    ld a, [c]
    ld sp, hl
    db $10
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld c, c
    ld c, h

jr_041_7963:
    ld c, h
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, h
    ld a, $56
    rst $30
    ld a, [c]
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d

jr_041_7978:
    ld a, $62
    ld b, e
    ld c, a
    ld c, h
    ld d, h
    ld c, e
    ld e, a
    pop af
    rst $30
    ld a, [c]
    ld sp, hl
    db $10
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld c, l
    ld c, h
    ld b, [hl]
    ld d, b
    ld c, h
    ld c, e
    ld b, d
    ld b, c
    ld e, a
    rst $30
    ldh a, [$f9]
    nop
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, c

jr_041_799b:
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    ld sp, hl
    jr nz, jr_041_799b

    ld a, [c]
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, b
    ld d, [hl]
    ld h, e
    pop af
    rst $30
    ldh a, [rNR50]
    ld h, d
    ld d, c
    ld b, l
    ld d, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ccf
    ld c, h
    ld c, c
    ld d, c
    pop af
    ld c, c
    ld b, d
    ld a, $4d
    ld d, b
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $30
    ld a, [c]
    ld d, c
    ld b, [hl]
    ld c, l
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $43
    ld b, e
    ld h, e
    pop af
    rst $30
    ldh a, [rNR50]
    ld h, d
    ld d, e
    ld a, $40
    ld d, d
    ld d, d
    ld c, d
    ld h, d
    ld d, b
    ld d, h
    ld b, [hl]
    ld c, a
    ld c, c
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, b
    ld c, a
    ld b, d
    ld a, $51
    ld b, d
    ld b, c
    ld h, e
    rst $30
    ldh a, [rNR50]
    ld h, d
    ld c, d
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
    ld h, d
    ld c, d
    ld b, [hl]
    ld d, b
    ld d, c
    pop af
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld a, $63
    rst $30
    ldh a, [$2f]
    ld a, $53
    ld a, $62
    ld c, h
    ld c, h
    ld d, a
    ld b, d
    ld d, b
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, h
    ld c, a
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, e
    rst $30
    ldh a, [rNR50]
    ld h, d
    ccf
    ld c, c
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld b, c
    pop af
    ld d, b
    ld d, h
    ld b, [hl]
    ld c, a
    ld c, c
    ld d, b
    ld h, d
    ld a, $40
    ld c, a
    ld c, h
    ld d, b
    ld d, b
    ld e, a
    rst $30
    ldh a, [$f9]
    nop
    ld h, d
    ld d, c
    ld b, l
    ld c, a
    ld c, h
    ld d, h
    ld d, b
    pop af
    ld a, $62
    ld sp, hl
    jr nz, jr_041_7ad0

    rst $30
    ldh a, [$f9]
    nop
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld d, b
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld sp, hl
    jr nz, jr_041_7ae1

    rst $30
    ldh a, [$f9]
    nop
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    ld d, b
    pop af
    ld a, $62
    ld sp, hl
    jr nz, jr_041_7af0

    ld d, c
    ld c, h
    ld a, [$f2f7]
    ld sp, hl
    db $10
    ld e, a
    pop af
    rst $30
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld b, d
    ld d, l
    ld b, b
    ld b, [hl]
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    pop af
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld sp, hl
    db $10
    ld a, [$f2f7]
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    ld h, d
    ld a, $62
    ccf
    ld c, a
    ld a, $53
    ld b, d
    pop af
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $30
    ldh a, [$37]
    ld b, l

jr_041_7ad0:
    ld b, d
    ld h, d
    ld b, l
    ld c, h
    ld c, a
    ld c, a
    ld b, [hl]
    ld b, e
    ld d, [hl]
    ld b, [hl]
    ld c, e
    ld b, h
    pop af
    ld d, b
    ld d, c
    ld c, h
    ld c, a

jr_041_7ae1:
    ld d, [hl]
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    ld a, [$f2f7]
    ld sp, hl
    db $10
    ld h, d
    ld b, [hl]
    ld c, e

jr_041_7af0:
    ld d, c
    ld c, h
    pop af
    ld a, $62
    ld b, b
    ld c, h
    ld d, h
    ld a, $4f
    ld b, c
    ld e, a
    rst $30
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld c, d
    ld c, h
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, h
    pop af
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    ld a, [$f2f7]
    ld sp, hl
    db $10
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    pop af
    ld a, $62
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $30
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld d, c
    ld d, [hl]
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    pop af
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld sp, hl
    db $10
    ld a, [$f2f7]
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    ld h, d
    ld a, $62
    ld d, b
    ld b, l
    ld c, a
    ld b, d
    ld d, h
    ld b, c
    pop af
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $30
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    pop af
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld sp, hl
    db $10
    ld a, [$f2f7]
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    ld h, d
    ld a, $62
    ld d, b
    ld c, d
    ld a, $4f
    ld d, c
    pop af
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $30
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld d, d
    ld c, e
    ld c, e
    ld d, [hl]
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    pop af
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld sp, hl
    db $10
    ld a, [$f2f7]
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    ld h, d
    ld a, $62
    ld c, e
    ld a, $46
    ld d, e
    ld b, d
    pop af
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $30
    ldh a, [$29]
    ld c, c
    ld a, $4a
    ld b, d
    ld d, b
    ld h, d
    ld c, c
    ld b, d
    ld a, $4d
    ld d, b
    pop af
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, l
    rst $30
    ld a, [c]
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $43
    ld b, e
    ld e, a
    pop af
    rst $30
    ldh a, [$f9]
    jr nc, jr_041_7c5c

    pop af
    ld d, h
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld a, $49
    ld d, b
    ld h, e
    rst $30
    ldh a, [$f9]
    jr nc, jr_041_7c6e

    pop af
    ld d, h
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld a, $49
    ld d, b
    ld h, e
    rst $30
    ld a, [c]
    ld sp, hl
    ld b, b
    ld l, b
    pop af
    ld d, h
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld a, $49
    ld d, b
    ld h, e
    rst $30
    ldh a, [$f9]
    jr nc, @+$6a

    pop af
    ld d, h
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld a, $49
    ld d, b
    ld h, e
    rst $30
    ld a, [c]
    ld sp, hl
    ld b, b
    ld l, b
    pop af
    ld d, h
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld a, $49
    ld d, b
    ld h, e
    rst $30
    ld a, [c]
    ld sp, hl
    ld d, b
    ld l, b
    pop af
    ld d, h
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld a, $49
    ld d, b
    ld h, e
    rst $30

jr_041_7c5c:
    ldh a, [$f9]
    jr nz, jr_041_7cc2

    ld c, l
    ld c, h
    ld b, [hl]
    ld c, e
    ld d, c
    ld d, b
    pop af
    ld sp, hl
    jr nc, jr_041_7cc9

    rst $30
    ldh a, [$37]
    ld b, l

jr_041_7c6e:
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld c, e
    ld c, h
    ld h, d
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    pop af
    ld d, b
    ld b, [hl]
    ld b, h
    ld c, e
    ld d, b
    ld h, d
    ld c, h
    ld b, e
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
    rst $30
    ldh a, [$f9]
    nop
    ld h, d
    ld c, l
    ld c, c
    ld a, $56
    ld d, b
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld sp, hl
    jr nz, jr_041_7d05

    rst $30
    ldh a, [$36]
    ld d, c
    ld a, $4f
    ld d, c
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, d
    ld c, e
    ld d, c
    ld b, [hl]
    ld c, a
    ld b, d
    ld h, d
    ld c, d
    ld a, $4d
    ld h, e
    rst $30

jr_041_7cc2:
    ldh a, [$3a]
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c

jr_041_7cc9:
    ld c, h
    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    pop af
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    dec l
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld h, h
    and $f0
    dec [hl]
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    dec l
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld e, a
    rst $30
    ldh a, [$f9]
    nop
    ld h, d
    ld b, b
    ld a, $50
    ld d, c
    ld d, b

jr_041_7d05:
    pop af
    ld sp, hl
    jr nz, @+$65

    rst $30
    ldh a, [rNR51]
    ld d, d
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    pop af
    ld b, l
    ld a, $4d
    ld c, l
    ld b, d
    ld c, e
    ld d, b
    ld h, e
    rst $30
    ldh a, [rNR51]
    ld d, d
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, d
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    jr nc, jr_041_7d65

    ld h, e
    rst $30
    ldh a, [$f9]
    db $10
    ld l, b
    pop af
    ld d, h
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld a, $49
    ld d, b
    ld h, e
    rst $30
    ldh a, [$f9]
    db $10
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, a
    ld b, d
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    ld b, c
    ld h, e
    rst $30
    ldh a, [$f9]
    db $10
    ld h, d
    ld b, c
    ld c, h
    ld b, d
    ld d, b
    pop af
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld c, a
    ld b, d

jr_041_7d65:
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    ld e, a
    rst $30
    ldh a, [$f9]
    db $10
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld b, b
    ld d, d
    ld c, a
    ld b, d
    ld b, c
    ld e, a
    rst $30
    ldh a, [rNR52]
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld h, d
    ld b, b
    ld a, $50
    ld d, c
    ld h, d
    ld c, h
    ld c, e
    pop af
    ld sp, hl
    db $10
    ld h, d
    ld b, [hl]
    ld d, b
    rst $30
    ld a, [c]
    ccf
    ld c, a
    ld c, h
    ld c, b
    ld b, d
    ld c, e
    ld h, e
    pop af
    rst $30
    ldh a, [rNR51]
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, e
    ld a, $4b
    ld b, [hl]
    ld d, b
    ld b, l
    ld b, d
    ld d, b
    pop af
    ld b, c
    ld d, d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld a, $f7
    ld a, [c]
    ld c, d
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld b, b
    ld b, d
    ld h, e
    pop af
    rst $30
    ldh a, [$f9]
    nop
    pop af
    ld d, h
    ld b, l
    ld b, [hl]
    ld d, b
    ld d, c
    ld c, c
    ld b, d
    ld d, b
    ld h, e
    rst $30
    ldh a, [rNR52]
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld e, a
    rst $30
    ldh a, [rNR52]
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    pop af
    ld c, h
    ld b, e
    ld h, d
    ld a, $62
    ld c, b
    ld c, e
    ld c, h
    ld b, b
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    rst $30
    ld a, [c]
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    pop af
    rst $30
    ldh a, [rP1]
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
