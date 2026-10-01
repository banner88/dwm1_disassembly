; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $04d", ROMX[$4000], BANK[$4d]

    db $4D ; Bank number

    ; Cross-bank dispatch table (476 entries)
    ; Called via: ld hl, $4DXX / rst $10
    dw SetB4d_43b9                  ; Entry 0
    dw $43C0                          ; Entry 1
    dw $43C7                          ; Entry 2
    dw $400B                          ; Entry 3
    dw $420B                          ; Entry 4
    dw $43CE                          ; Entry 5
    dw $43E1                          ; Entry 6
    dw $43F4                          ; Entry 7
    dw $4407                          ; Entry 8
    dw $441A                          ; Entry 9
    dw $442D                          ; Entry 10
    dw $4440                          ; Entry 11
    dw $4453                          ; Entry 12
    dw $4466                          ; Entry 13
    dw $4479                          ; Entry 14
    dw $448C                          ; Entry 15
    dw $449F                          ; Entry 16
    dw $44B2                          ; Entry 17
    dw $44C5                          ; Entry 18
    dw $44D8                          ; Entry 19
    dw $44EB                          ; Entry 20
    dw $44FE                          ; Entry 21
    dw $4511                          ; Entry 22
    dw $4524                          ; Entry 23
    dw $4537                          ; Entry 24
    dw $454A                          ; Entry 25
    dw $455D                          ; Entry 26
    dw $4570                          ; Entry 27
    dw $4583                          ; Entry 28
    dw $4596                          ; Entry 29
    dw $45A9                          ; Entry 30
    dw $45BC                          ; Entry 31
    dw $45CF                          ; Entry 32
    dw $45E2                          ; Entry 33
    dw $45F5                          ; Entry 34
    dw $4608                          ; Entry 35
    dw $461B                          ; Entry 36
    dw $462E                          ; Entry 37
    dw $4641                          ; Entry 38
    dw $4654                          ; Entry 39
    dw $4667                          ; Entry 40
    dw $467A                          ; Entry 41
    dw $468D                          ; Entry 42
    dw $46A0                          ; Entry 43
    dw $46B3                          ; Entry 44
    dw $46C6                          ; Entry 45
    dw $46D9                          ; Entry 46
    dw $46EC                          ; Entry 47
    dw $46FF                          ; Entry 48
    dw $4712                          ; Entry 49
    dw $4725                          ; Entry 50
    dw $4738                          ; Entry 51
    dw $474B                          ; Entry 52
    dw $475E                          ; Entry 53
    dw $4771                          ; Entry 54
    dw $4784                          ; Entry 55
    dw $4797                          ; Entry 56
    dw $47AA                          ; Entry 57
    dw $47BD                          ; Entry 58
    dw $47D0                          ; Entry 59
    dw $47E3                          ; Entry 60
    dw $47F6                          ; Entry 61
    dw $4809                          ; Entry 62
    dw $481C                          ; Entry 63
    dw $482F                          ; Entry 64
    dw $4842                          ; Entry 65
    dw $4855                          ; Entry 66
    dw $4868                          ; Entry 67
    dw $487B                          ; Entry 68
    dw $488E                          ; Entry 69
    dw $48A1                          ; Entry 70
    dw $48B4                          ; Entry 71
    dw $48C7                          ; Entry 72
    dw $48DA                          ; Entry 73
    dw $48ED                          ; Entry 74
    dw $4900                          ; Entry 75
    dw $4913                          ; Entry 76
    dw $4926                          ; Entry 77
    dw $4939                          ; Entry 78
    dw $494C                          ; Entry 79
    dw $495F                          ; Entry 80
    dw $4972                          ; Entry 81
    dw $4985                          ; Entry 82
    dw $4998                          ; Entry 83
    dw $49AB                          ; Entry 84
    dw $49BE                          ; Entry 85
    dw $49D1                          ; Entry 86
    dw $49E4                          ; Entry 87
    dw $49F7                          ; Entry 88
    dw $4A0A                          ; Entry 89
    dw $4A1D                          ; Entry 90
    dw $4A30                          ; Entry 91
    dw $4A43                          ; Entry 92
    dw $4A56                          ; Entry 93
    dw $4A69                          ; Entry 94
    dw $4A7C                          ; Entry 95
    dw $4A8F                          ; Entry 96
    dw $4AA2                          ; Entry 97
    dw $4AB5                          ; Entry 98
    dw $4AC8                          ; Entry 99
    dw $4ADB                          ; Entry 100
    dw $4AEE                          ; Entry 101
    dw $4B01                          ; Entry 102
    dw $4B14                          ; Entry 103
    dw $4B27                          ; Entry 104
    dw $4B3A                          ; Entry 105
    dw $4B4D                          ; Entry 106
    dw $4B60                          ; Entry 107
    dw $4B73                          ; Entry 108
    dw $4B86                          ; Entry 109
    dw $4B99                          ; Entry 110
    dw $4BAC                          ; Entry 111
    dw $4BBF                          ; Entry 112
    dw $4BD2                          ; Entry 113
    dw $4BE5                          ; Entry 114
    dw $4BF8                          ; Entry 115
    dw $4C0B                          ; Entry 116
    dw $4C1E                          ; Entry 117
    dw $4C31                          ; Entry 118
    dw $4C44                          ; Entry 119
    dw $4C57                          ; Entry 120
    dw $4C6A                          ; Entry 121
    dw $4C7D                          ; Entry 122
    dw $4C90                          ; Entry 123
    dw $4CA3                          ; Entry 124
    dw $4CB6                          ; Entry 125
    dw $4CC9                          ; Entry 126
    dw $4CDC                          ; Entry 127
    dw $4CEF                          ; Entry 128
    dw $4D02                          ; Entry 129
    dw $4D15                          ; Entry 130
    dw $4D28                          ; Entry 131
    dw $4D3B                          ; Entry 132
    dw $4D4E                          ; Entry 133
    dw $4D61                          ; Entry 134
    dw $4D74                          ; Entry 135
    dw $4D87                          ; Entry 136
    dw $4D9A                          ; Entry 137
    dw $4DAD                          ; Entry 138
    dw $4DC0                          ; Entry 139
    dw $4DD3                          ; Entry 140
    dw $4DE6                          ; Entry 141
    dw $4DF9                          ; Entry 142
    dw $4E0C                          ; Entry 143
    dw $4E1F                          ; Entry 144
    dw $4E32                          ; Entry 145
    dw $4E45                          ; Entry 146
    dw $4E58                          ; Entry 147
    dw $4E6B                          ; Entry 148
    dw $4E7E                          ; Entry 149
    dw $4E91                          ; Entry 150
    dw $4EA4                          ; Entry 151
    dw $4EB7                          ; Entry 152
    dw $4ECA                          ; Entry 153
    dw $4EDD                          ; Entry 154
    dw $4EF0                          ; Entry 155
    dw $4F03                          ; Entry 156
    dw $4F16                          ; Entry 157
    dw $4F29                          ; Entry 158
    dw $4F3C                          ; Entry 159
    dw $4F4F                          ; Entry 160
    dw $4F62                          ; Entry 161
    dw $4F75                          ; Entry 162
    dw $4F88                          ; Entry 163
    dw $4F9B                          ; Entry 164
    dw $4FAE                          ; Entry 165
    dw $4FC1                          ; Entry 166
    dw $4FD4                          ; Entry 167
    dw $4FE7                          ; Entry 168
    dw $4FFA                          ; Entry 169
    dw $500D                          ; Entry 170
    dw $5020                          ; Entry 171
    dw $5033                          ; Entry 172
    dw $5046                          ; Entry 173
    dw $5059                          ; Entry 174
    dw $506C                          ; Entry 175
    dw $507F                          ; Entry 176
    dw $5092                          ; Entry 177
    dw $50A5                          ; Entry 178
    dw $50B8                          ; Entry 179
    dw $50CB                          ; Entry 180
    dw $50DE                          ; Entry 181
    dw $50F1                          ; Entry 182
    dw $5104                          ; Entry 183
    dw $5117                          ; Entry 184
    dw $512A                          ; Entry 185
    dw $513D                          ; Entry 186
    dw $5150                          ; Entry 187
    dw $5163                          ; Entry 188
    dw $5176                          ; Entry 189
    dw $5189                          ; Entry 190
    dw $519C                          ; Entry 191
    dw $51AF                          ; Entry 192
    dw $51C2                          ; Entry 193
    dw $51D5                          ; Entry 194
    dw $51E8                          ; Entry 195
    dw $51FB                          ; Entry 196
    dw $520E                          ; Entry 197
    dw $5221                          ; Entry 198
    dw $5234                          ; Entry 199
    dw $5247                          ; Entry 200
    dw $525A                          ; Entry 201
    dw $526D                          ; Entry 202
    dw $5280                          ; Entry 203
    dw $5293                          ; Entry 204
    dw $52A6                          ; Entry 205
    dw $52B9                          ; Entry 206
    dw $52CC                          ; Entry 207
    dw $52DF                          ; Entry 208
    dw $52F2                          ; Entry 209
    dw $5305                          ; Entry 210
    dw $5318                          ; Entry 211
    dw $532C                          ; Entry 212
    dw $533F                          ; Entry 213
    dw $5352                          ; Entry 214
    dw $5365                          ; Entry 215
    dw $5378                          ; Entry 216
    dw $538B                          ; Entry 217
    dw $539E                          ; Entry 218
    dw $53B1                          ; Entry 219
    dw $53C4                          ; Entry 220
    dw $53C4                          ; Entry 221
    dw $53C4                          ; Entry 222
    dw $53C4                          ; Entry 223
    dw $53C4                          ; Entry 224
    dw $53C4                          ; Entry 225
    dw $53C4                          ; Entry 226
    dw $53C4                          ; Entry 227
    dw $53C4                          ; Entry 228
    dw $53C4                          ; Entry 229
    dw $53C4                          ; Entry 230
    dw $53C4                          ; Entry 231
    dw $53C4                          ; Entry 232
    dw $53C4                          ; Entry 233
    dw $53C4                          ; Entry 234
    dw $53C4                          ; Entry 235
    dw $53C4                          ; Entry 236
    dw $53C4                          ; Entry 237
    dw $53C4                          ; Entry 238
    dw $53C4                          ; Entry 239
    dw $53C4                          ; Entry 240
    dw $53C4                          ; Entry 241
    dw $53C4                          ; Entry 242
    dw $53C4                          ; Entry 243
    dw $53C4                          ; Entry 244
    dw $53C4                          ; Entry 245
    dw $53C4                          ; Entry 246
    dw $53C4                          ; Entry 247
    dw $53C4                          ; Entry 248
    dw $53C4                          ; Entry 249
    dw $53C4                          ; Entry 250
    dw $53C4                          ; Entry 251
    dw $53C4                          ; Entry 252
    dw $53C4                          ; Entry 253
    dw $53C4                          ; Entry 254
    dw $53C4                          ; Entry 255
    dw $53C4                          ; Entry 256
    dw $53C4                          ; Entry 257
    dw $53C4                          ; Entry 258
    dw $53C4                          ; Entry 259
    dw $53C4                          ; Entry 260
    dw MonsterDesc_000_DrakSlime                               ; Entry 261 ($53D3)
    dw MonsterDesc_001_SpotSlime                               ; Entry 262 ($53F7)
    dw MonsterDesc_002_WingSlime                               ; Entry 263 ($541D)
    dw MonsterDesc_003_TreeSlime                               ; Entry 264 ($5444)
    dw MonsterDesc_004_Snaily                                  ; Entry 265 ($546F)
    dw MonsterDesc_005_SlimeNite                               ; Entry 266 ($5494)
    dw MonsterDesc_006_Babble                                  ; Entry 267 ($54C8)
    dw MonsterDesc_007_BoxSlime                                ; Entry 268 ($54EE)
    dw MonsterDesc_008_Slime                                   ; Entry 269 ($5520)
    dw MonsterDesc_009_Healer                                  ; Entry 270 ($5549)
    dw MonsterDesc_010_FangSlime                               ; Entry 271 ($5573)
    dw MonsterDesc_011_RockSlime                               ; Entry 272 ($559E)
    dw MonsterDesc_012_SlimeBorg                               ; Entry 273 ($55BA)
    dw MonsterDesc_013_Slabbit                                 ; Entry 274 ($55E6)
    dw MonsterDesc_014_SpotKing                                ; Entry 275 ($5610)
    dw MonsterDesc_015_KingSlime                               ; Entry 276 ($5647)
    dw MonsterDesc_016_Metaly                                  ; Entry 277 ($567A)
    dw MonsterDesc_017_Metabble                                ; Entry 278 ($56A9)
    dw MonsterDesc_018_MetalKing                               ; Entry 279 ($56CF)
    dw MonsterDesc_019_GoldSlime                               ; Entry 280 ($56FA)
    dw MonsterDesc_020_DragonKid                               ; Entry 281 ($5724)
    dw MonsterDesc_021_Tortragon                               ; Entry 282 ($574A)
    dw MonsterDesc_022_Pteranod                                ; Entry 283 ($577A)
    dw MonsterDesc_023_Gasgon                                  ; Entry 284 ($57A9)
    dw MonsterDesc_024_FairyDrak                               ; Entry 285 ($57D4)
    dw MonsterDesc_025_LizardMan                               ; Entry 286 ($5800)
    dw MonsterDesc_026_Poisongon                               ; Entry 287 ($5830)
    dw MonsterDesc_027_Swordgon                                ; Entry 288 ($5865)
    dw MonsterDesc_028_Dragon                                  ; Entry 289 ($5890)
    dw MonsterDesc_029_MiniDrak                                ; Entry 290 ($58B4)
    dw MonsterDesc_030_MadDragon                               ; Entry 291 ($58E4)
    dw MonsterDesc_031_Rayburn                                 ; Entry 292 ($5914)
    dw MonsterDesc_032_Chamelgon                               ; Entry 293 ($593C)
    dw MonsterDesc_033_LizardFly                               ; Entry 294 ($5962)
    dw MonsterDesc_034_Andreal                                 ; Entry 295 ($5987)
    dw MonsterDesc_035_KingCobra                               ; Entry 296 ($59B7)
    dw MonsterDesc_036_Spikerous                               ; Entry 297 ($59E5)
    dw MonsterDesc_037_GreatDrak                               ; Entry 298 ($5A16)
    dw MonsterDesc_038_Crestpent                               ; Entry 299 ($5A3E)
    dw MonsterDesc_039_WingSnake                               ; Entry 300 ($5A6B)
    dw MonsterDesc_040_Coatol                                  ; Entry 301 ($5A97)
    dw MonsterDesc_041_Orochi                                  ; Entry 302 ($5AC5)
    dw MonsterDesc_042_BattleRex                               ; Entry 303 ($5AFA)
    dw MonsterDesc_043_SkyDragon                               ; Entry 304 ($5B24)
    dw MonsterDesc_044_Divinegon                               ; Entry 305 ($5B54)
    dw MonsterDesc_045_Tonguella                               ; Entry 306 ($5B80)
    dw MonsterDesc_046_Almiraj                                 ; Entry 307 ($5BAB)
    dw MonsterDesc_047_CatFly                                  ; Entry 308 ($5BD9)
    dw MonsterDesc_048_PillowRat                               ; Entry 309 ($5C00)
    dw MonsterDesc_049_Saccer                                  ; Entry 310 ($5C22)
    dw MonsterDesc_050_GulpBeast                               ; Entry 311 ($5C47)
    dw MonsterDesc_051_Skullroo                                ; Entry 312 ($5C6B)
    dw MonsterDesc_052_WindBeast                               ; Entry 313 ($5C95)
    dw MonsterDesc_053_Anteater                                ; Entry 314 ($5CC6)
    dw MonsterDesc_054_SuperTen                                ; Entry 315 ($5CF1)
    dw MonsterDesc_055_IronTurt                                ; Entry 316 ($5D16)
    dw MonsterDesc_056_Mommonja                                ; Entry 317 ($5D49)
    dw MonsterDesc_057_HammerMan                               ; Entry 318 ($5D63)
    dw MonsterDesc_058_Grizzly                                 ; Entry 319 ($5D86)
    dw MonsterDesc_059_Yeti                                    ; Entry 320 ($5DAF)
    dw MonsterDesc_060_MadGopher                               ; Entry 321 ($5DD4)
    dw MonsterDesc_061_FairyRat                                ; Entry 322 ($5DFF)
    dw MonsterDesc_062_Unicorn                                 ; Entry 323 ($5E28)
    dw MonsterDesc_063_Goategon                                ; Entry 324 ($5E4B)
    dw MonsterDesc_064_WildApe                                 ; Entry 325 ($5E7A)
    dw MonsterDesc_065_Trumpeter                               ; Entry 326 ($5EA6)
    dw MonsterDesc_066_KingLeo                                 ; Entry 327 ($5ECE)
    dw MonsterDesc_067_DarkHorn                                ; Entry 328 ($5EFD)
    dw MonsterDesc_068_MadCat                                  ; Entry 329 ($5F1C)
    dw MonsterDesc_069_BigEye                                  ; Entry 330 ($5F41)
    dw MonsterDesc_070_Picky                                   ; Entry 331 ($5F69)
    dw MonsterDesc_071_Wyvern                                  ; Entry 332 ($5F8F)
    dw MonsterDesc_072_BullBird                                ; Entry 333 ($5FBB)
    dw MonsterDesc_073_Florajay                                ; Entry 334 ($5FDE)
    dw MonsterDesc_074_DuckKite                                ; Entry 335 ($600C)
    dw MonsterDesc_075_MadPecker                               ; Entry 336 ($6039)
    dw MonsterDesc_076_MadRaven                                ; Entry 337 ($6067)
    dw MonsterDesc_077_MistyWing                               ; Entry 338 ($608F)
    dw MonsterDesc_078_Dracky                                  ; Entry 339 ($60BC)
    dw MonsterDesc_079_BigRoost                                ; Entry 340 ($60EC)
    dw MonsterDesc_080_StubBird                                ; Entry 341 ($610A)
    dw MonsterDesc_081_LandOwl                                 ; Entry 342 ($611F)
    dw MonsterDesc_082_MadGoose                                ; Entry 343 ($6151)
    dw MonsterDesc_083_MadCondor                               ; Entry 344 ($617B)
    dw MonsterDesc_084_Blizzardy                               ; Entry 345 ($61B2)
    dw MonsterDesc_085_Phoenix                                 ; Entry 346 ($61DF)
    dw MonsterDesc_086_ZapBird                                 ; Entry 347 ($6205)
    dw MonsterDesc_087_WhipBird                                ; Entry 348 ($6238)
    dw MonsterDesc_088_FunkyBird                               ; Entry 349 ($626B)
    dw MonsterDesc_089_RainHawk                                ; Entry 350 ($6281)
    dw MonsterDesc_090_MadPlant                                ; Entry 351 ($62B1)
    dw MonsterDesc_091_FireWeed                                ; Entry 352 ($62D4)
    dw MonsterDesc_092_FloraMan                                ; Entry 353 ($62FA)
    dw MonsterDesc_093_WingTree                                ; Entry 354 ($632A)
    dw MonsterDesc_094_CactiBall                               ; Entry 355 ($6359)
    dw MonsterDesc_095_Gulpple                                 ; Entry 356 ($638C)
    dw MonsterDesc_096_Toadstool                               ; Entry 357 ($63BD)
    dw MonsterDesc_097_AmberWeed                               ; Entry 358 ($63E7)
    dw MonsterDesc_098_Stubsuck                                ; Entry 359 ($640A)
    dw MonsterDesc_099_Oniono                                  ; Entry 360 ($643A)
    dw MonsterDesc_100_DanceVegi                               ; Entry 361 ($6466)
    dw MonsterDesc_101_TreeBoy                                 ; Entry 362 ($6499)
    dw MonsterDesc_102_FaceTree                                ; Entry 363 ($64C0)
    dw MonsterDesc_103_HerbMan                                 ; Entry 364 ($64EA)
    dw MonsterDesc_104_BeanMan                                 ; Entry 365 ($6518)
    dw MonsterDesc_105_EvilSeed                                ; Entry 366 ($6543)
    dw MonsterDesc_106_ManEater                                ; Entry 367 ($6569)
    dw MonsterDesc_107_Snapper                                 ; Entry 368 ($6594)
    dw MonsterDesc_108_Rosevine                                ; Entry 369 ($65BE)
    dw MonsterDesc_109_Watabou                                 ; Entry 370 ($65E6)
    dw MonsterDesc_110_GiantSlug                               ; Entry 371 ($6606)
    dw MonsterDesc_111_Catapila                                ; Entry 372 ($662B)
    dw MonsterDesc_112_Gophecada                               ; Entry 373 ($665B)
    dw MonsterDesc_113_Butterfly                               ; Entry 374 ($6686)
    dw MonsterDesc_114_WeedBug                                 ; Entry 375 ($66B7)
    dw MonsterDesc_115_GiantWorm                               ; Entry 376 ($66E7)
    dw MonsterDesc_116_Lipsy                                   ; Entry 377 ($6714)
    dw MonsterDesc_117_StagBug                                 ; Entry 378 ($673C)
    dw MonsterDesc_118_ArmyAnt                                 ; Entry 379 ($675F)
    dw MonsterDesc_119_GoHopper                                ; Entry 380 ($678A)
    dw MonsterDesc_120_TailEater                               ; Entry 381 ($67AC)
    dw MonsterDesc_121_ArmorPede                               ; Entry 382 ($67D7)
    dw MonsterDesc_122_Eyeder                                  ; Entry 383 ($6803)
    dw MonsterDesc_123_GiantMoth                               ; Entry 384 ($6829)
    dw MonsterDesc_124_Droll                                   ; Entry 385 ($6854)
    dw MonsterDesc_125_ArmyCrab                                ; Entry 386 ($6882)
    dw MonsterDesc_126_MadHornet                               ; Entry 387 ($68B7)
    dw MonsterDesc_127_HornBeet                                ; Entry 388 ($68D9)
    dw MonsterDesc_128_Armorpion                               ; Entry 389 ($68FC)
    dw MonsterDesc_129_Digster                                 ; Entry 390 ($6920)
    dw MonsterDesc_130_Pixy                                    ; Entry 391 ($6948)
    dw MonsterDesc_131_ArcDemon                                ; Entry 392 ($6973)
    dw MonsterDesc_132_AgDevil                                 ; Entry 393 ($69A1)
    dw MonsterDesc_133_Demonite                                ; Entry 394 ($69BD)
    dw MonsterDesc_134_DarkEye                                 ; Entry 395 ($69EB)
    dw MonsterDesc_135_EyeBall                                 ; Entry 396 ($6A0F)
    dw MonsterDesc_136_SkulRider                               ; Entry 397 ($6A38)
    dw MonsterDesc_137_EvilBeast                               ; Entry 398 ($6A5D)
    dw MonsterDesc_138_1EyeClown                               ; Entry 399 ($6A86)
    dw MonsterDesc_139_Gremlin                                 ; Entry 400 ($6AA8)
    dw MonsterDesc_140_MedusaEye                               ; Entry 401 ($6AD6)
    dw MonsterDesc_141_Lionex                                  ; Entry 402 ($6B08)
    dw MonsterDesc_142_GoatHorn                                ; Entry 403 ($6B24)
    dw MonsterDesc_143_Orc                                     ; Entry 404 ($6B57)
    dw MonsterDesc_144_Ogre                                    ; Entry 405 ($6B7C)
    dw MonsterDesc_145_GateGuard                               ; Entry 406 ($6BAF)
    dw MonsterDesc_146_ChopClown                               ; Entry 407 ($6BE0)
    dw MonsterDesc_147_Grendal                                 ; Entry 408 ($6C0B)
    dw MonsterDesc_148_Akubar                                  ; Entry 409 ($6C35)
    dw MonsterDesc_149_MadKnight                               ; Entry 410 ($6C64)
    dw MonsterDesc_150_Gigantes                                ; Entry 411 ($6C8D)
    dw MonsterDesc_151_Centasaur                               ; Entry 412 ($6CC1)
    dw MonsterDesc_152_EvilArmor                               ; Entry 413 ($6CDF)
    dw MonsterDesc_153_Jamirus                                 ; Entry 414 ($6D11)
    dw MonsterDesc_154_Durran                                  ; Entry 415 ($6D35)
    dw MonsterDesc_155_Spooky                                  ; Entry 416 ($6D5E)
    dw MonsterDesc_156_Skullgon                                ; Entry 417 ($6D7B)
    dw MonsterDesc_157_Putrepup                                ; Entry 418 ($6D9E)
    dw MonsterDesc_158_RotRaven                                ; Entry 419 ($6DC9)
    dw MonsterDesc_159_Mummy                                   ; Entry 420 ($6DEF)
    dw MonsterDesc_160_DarkCrab                                ; Entry 421 ($6E22)
    dw MonsterDesc_161_DeadNite                                ; Entry 422 ($6E43)
    dw MonsterDesc_162_Shadow                                  ; Entry 423 ($6E6F)
    dw MonsterDesc_163_Hork                                    ; Entry 424 ($6EA4)
    dw MonsterDesc_164_Mudron                                  ; Entry 425 ($6ECD)
    dw MonsterDesc_165_NiteWhip                                ; Entry 426 ($6EF5)
    dw MonsterDesc_166_MadSpirit                               ; Entry 427 ($6F20)
    dw MonsterDesc_167_WindMerge                               ; Entry 428 ($6F3C)
    dw MonsterDesc_168_Reaper                                  ; Entry 429 ($6F6A)
    dw MonsterDesc_169_DeadNoble                               ; Entry 430 ($6F90)
    dw MonsterDesc_170_WhiteKing                               ; Entry 431 ($6FC2)
    dw MonsterDesc_171_BoneSlave                               ; Entry 432 ($6FF3)
    dw MonsterDesc_172_Skeletor                                ; Entry 433 ($701F)
    dw MonsterDesc_173_Servant                                 ; Entry 434 ($704B)
    dw MonsterDesc_174_Copycat                                 ; Entry 435 ($7076)
    dw MonsterDesc_175_JewelBag                                ; Entry 436 ($70A4)
    dw MonsterDesc_176_EvilWand                                ; Entry 437 ($70D2)
    dw MonsterDesc_177_MadCandle                               ; Entry 438 ($70FB)
    dw MonsterDesc_178_CoilBird                                ; Entry 439 ($7124)
    dw MonsterDesc_179_Facer                                   ; Entry 440 ($7139)
    dw MonsterDesc_180_SpikyBoy                                ; Entry 441 ($7167)
    dw MonsterDesc_181_MadMirror                               ; Entry 442 ($717D)
    dw MonsterDesc_182_RogueNite                               ; Entry 443 ($71AA)
    dw MonsterDesc_183_Goopi                                   ; Entry 444 ($71DD)
    dw MonsterDesc_184_Voodoll                                 ; Entry 445 ($7204)
    dw MonsterDesc_185_MetalDrak                               ; Entry 446 ($7220)
    dw MonsterDesc_186_Balzak                                  ; Entry 447 ($7240)
    dw MonsterDesc_187_SabreMan                                ; Entry 448 ($726F)
    dw MonsterDesc_188_CurseLamp                               ; Entry 449 ($72A3)
    dw MonsterDesc_189_Roboster                                ; Entry 450 ($72D9)
    dw MonsterDesc_190_EvilPot                                 ; Entry 451 ($7309)
    dw MonsterDesc_191_Gismo                                   ; Entry 452 ($732D)
    dw MonsterDesc_192_LavaMan                                 ; Entry 453 ($7355)
    dw MonsterDesc_193_IceMan                                  ; Entry 454 ($737C)
    dw MonsterDesc_194_Mimic                                   ; Entry 455 ($73A1)
    dw MonsterDesc_195_MudDoll                                 ; Entry 456 ($73D0)
    dw MonsterDesc_196_Golem                                   ; Entry 457 ($73FC)
    dw MonsterDesc_197_StoneMan                                ; Entry 458 ($7425)
    dw MonsterDesc_198_BombCrag                                ; Entry 459 ($744F)
    dw MonsterDesc_199_GoldGolem                               ; Entry 460 ($747A)
    dw MonsterDesc_200_DracoLord                               ; Entry 461 ($74A1)
    dw MonsterDesc_201_DracoLord                               ; Entry 462 ($74CF)
    dw MonsterDesc_202_Hargon                                  ; Entry 463 ($74F6)
    dw MonsterDesc_203_Sidoh                                   ; Entry 464 ($7523)
    dw MonsterDesc_204_Baramos                                 ; Entry 465 ($7551)
    dw MonsterDesc_205_Zoma                                    ; Entry 466 ($7576)
    dw MonsterDesc_206_Pizzaro                                 ; Entry 467 ($758D)
    dw MonsterDesc_207_Esterk                                  ; Entry 468 ($75BC)
    dw MonsterDesc_208_Mirudraas                               ; Entry 469 ($75EA)
    dw MonsterDesc_209_Mirudraas                               ; Entry 470 ($7619)
    dw MonsterDesc_210_Mudou                                   ; Entry 471 ($763F)
    dw MonsterDesc_211_DeathMore                               ; Entry 472 ($7664)
    dw MonsterDesc_212_DeathMore                               ; Entry 473 ($7696)
    dw MonsterDesc_213_DeathMore                               ; Entry 474 ($76C5)
    dw MonsterDesc_214_Darkdrium                               ; Entry 475 ($76F6)

SetB4d_43b9:
    ld de, $4007
    call CallTextEngine
    ret


    ld de, $4007
    call RunTextHandler
    ret


    call SetB4d_43b9
    call RequestScreenUpdate
    ret


; =============================================================================
; LIBRARY RECIPE TEXT — $43CE-$53D2, re-sectioned S103 from code-decoded bytes
; (labels/comments only, byte-neutral). The encyclopedia detail page's recipe
; line: mode 0 of the $4007 mode table ($400B = dispatch entry 5), so species s
; -> entry s + 5 -> one slot here: <parent 1 padded to 9><parent 2 padded to 9>
; $F0 (pad byte $62; a family token is its icon byte $10-$18 + "family"). The
; strings are HAND-AUTHORED (4 typos the tables do not have), read by nothing
; but the text engine — BREEDING_SYSTEM "Library recipe TEXT". Entries 5-10
; (species 0-5) double as the $4007 mode 2-7 bases (TEXT_SYSTEM), so an editor
; rewrites a string IN PLACE and never repoints it (editor2 `gd_library_text`).
; =============================================================================
LibRecipeTextBlock:
LibRecipeText_000:  ; 0 DrakSlime: "<slime>family  <dragon>family  "
    db $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_001:  ; 1 SpotSlime: "<slime>family  <beast>family  "
    db $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_002:  ; 2 WingSlime: "<slime>family  <bird>family  "
    db $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_003:  ; 3 TreeSlime: "<slime>family  <plant>family  "
    db $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_004:  ; 4 Snaily: "<slime>family  <bug>family  "
    db $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_005:  ; 5 SlimeNite: "<slime>family  <devil>family  "
    db $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_006:  ; 6 Babble: "<slime>family  <zombie>family  "
    db $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $17, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_007:  ; 7 BoxSlime: "<slime>family  <material>family  "
    db $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_008:  ; 8 Slime: "?????    ?????    "
    db $64, $64, $64, $64, $64, $62, $62, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_009:  ; 9 Healer: "<slime>family  MadPlant "
    db $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $30, $3E, $41, $33, $49, $3E, $4B, $51, $62, $F0
LibRecipeText_010:  ; 10 FangSlime: "<slime>family  Almiraj  "
    db $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $24, $49, $4A, $46, $4F, $3E, $47, $62, $62, $F0
LibRecipeText_011:  ; 11 RockSlime: "<slime>family  BombCrag "
    db $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $25, $4C, $4A, $3F, $26, $4F, $3E, $44, $62, $F0
LibRecipeText_012:  ; 12 SlimeBorg: "<slime>family  Roboster "
    db $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $35, $4C, $3F, $4C, $50, $51, $42, $4F, $62, $F0
LibRecipeText_013:  ; 13 Slabbit: "<slime>family  Skullroo "
    db $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $36, $48, $52, $49, $49, $4F, $4C, $4C, $62, $F0
LibRecipeText_014:  ; 14 SpotKing: "?????    ?????    "
    db $64, $64, $64, $64, $64, $62, $62, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_015:  ; 15 KingSlime: "<slime>family  ?????    "
    db $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_016:  ; 16 Metaly: "<slime>family  MetalDrak"
    db $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $30, $42, $51, $3E, $49, $27, $4F, $3E, $48, $F0
LibRecipeText_017:  ; 17 Metabble: "Metaly   Metaly   "
    db $30, $42, $51, $3E, $49, $56, $62, $62, $62, $30, $42, $51, $3E, $49, $56, $62, $62, $62, $F0
LibRecipeText_018:  ; 18 MetalKing: "Metabble Metabble "
    db $30, $42, $51, $3E, $3F, $3F, $49, $42, $62, $30, $42, $51, $3E, $3F, $3F, $49, $42, $62, $F0
LibRecipeText_019:  ; 19 GoldSlime: "MetalKingMetalKing"
    db $30, $42, $51, $3E, $49, $2E, $46, $4B, $44, $30, $42, $51, $3E, $49, $2E, $46, $4B, $44, $F0
LibRecipeText_020:  ; 20 DragonKid: "<dragon>family  <slime>family  "
    db $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_021:  ; 21 Tortragon: "<dragon>family  <beast>family  "
    db $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_022:  ; 22 Pteranod: "<dragon>family  <bird>family  "
    db $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_023:  ; 23 Gasgon: "<dragon>family  <plant>family  "
    db $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_024:  ; 24 FairyDrak: "<dragon>family  <bug>family  "
    db $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_025:  ; 25 LizardMan: "<dragon>family  <devil>family  "
    db $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_026:  ; 26 Poisongon: "<dragon>family  <zombie>family  "
    db $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $17, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_027:  ; 27 Swordgon: "<dragon>family  <material>family  "
    db $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_028:  ; 28 Dragon: "DragonKidDragonKid"
    db $27, $4F, $3E, $44, $4C, $4B, $2E, $46, $41, $27, $4F, $3E, $44, $4C, $4B, $2E, $46, $41, $F0
LibRecipeText_029:  ; 29 MiniDrak: "<dragon>family  Picky    "
    db $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $33, $46, $40, $48, $56, $62, $62, $62, $62, $F0
LibRecipeText_030:  ; 30 MadDragon: "<dragon>family  GulpBeast"
    db $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $2A, $52, $49, $4D, $25, $42, $3E, $50, $51, $F0
LibRecipeText_031:  ; 31 Rayburn: "<dragon>family  MadCondor"
    db $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $30, $3E, $41, $26, $4C, $4B, $41, $4C, $4F, $F0
LibRecipeText_032:  ; 32 Chamelgon: "<dragon>family  Voodoll  "
    db $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $39, $4C, $4C, $41, $4C, $49, $49, $62, $62, $F0
LibRecipeText_033:  ; 33 LizardFly: "<dragon>family  GoHopper "
    db $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $2A, $4C, $2B, $4C, $4D, $4D, $42, $4F, $62, $F0
LibRecipeText_034:  ; 34 Andreal: "<dragon>family  Gulpple  "
    db $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $2A, $52, $49, $4D, $4D, $49, $42, $62, $62, $F0
LibRecipeText_035:  ; 35 KingCobra: "<dragon>family  Babble   "
    db $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $25, $3E, $3F, $3F, $49, $42, $62, $62, $62, $F0
LibRecipeText_036:  ; 36 Spikerous: "<dragon>family  ArmyCrab "
    db $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $24, $4F, $4A, $56, $26, $4F, $3E, $3F, $62, $F0
LibRecipeText_037:  ; 37 GreatDrak: "?????    ?????    "
    db $64, $64, $64, $64, $64, $62, $62, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_038:  ; 38 Crestpent: "<dragon>family  BigRoost "
    db $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $25, $46, $44, $35, $4C, $4C, $50, $51, $62, $F0
LibRecipeText_039:  ; 39 WingSnake: "CrestpentCrestpent"
    db $26, $4F, $42, $50, $51, $4D, $42, $4B, $51, $26, $4F, $42, $50, $51, $4D, $42, $4B, $51, $F0
LibRecipeText_040:  ; 40 Coatol: "WingSnakeWingSnake"
    db $3A, $46, $4B, $44, $36, $4B, $3E, $48, $42, $3A, $46, $4B, $44, $36, $4B, $3E, $48, $42, $F0
LibRecipeText_041:  ; 41 Orochi: "Andreal  MedusaEye"
    db $24, $4B, $41, $4F, $42, $3E, $49, $62, $62, $30, $42, $41, $52, $50, $3E, $28, $56, $42, $F0
LibRecipeText_042:  ; 42 BattleRex: "<dragon>family  Lionex   "
    db $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $2F, $46, $4C, $4B, $42, $55, $62, $62, $62, $F0
LibRecipeText_043:  ; 43 SkyDragon: "<dragon>family  Phoenix  "
    db $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $33, $45, $4C, $42, $4B, $46, $55, $62, $62, $F0
LibRecipeText_044:  ; 44 Divinegon: "SkyDragonOrochi   "
    db $36, $48, $56, $27, $4F, $3E, $44, $4C, $4B, $32, $4F, $4C, $40, $45, $46, $62, $62, $62, $F0
LibRecipeText_045:  ; 45 Tonguella: "<beast>family  <slime>family  "
    db $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_046:  ; 46 Almiraj: "<beast>family  <dragon>family  "
    db $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_047:  ; 47 CatFly: "<beast>family  <bird>family  "
    db $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_048:  ; 48 PillowRat: "<beast>family  <plant>family  "
    db $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_049:  ; 49 Saccer: "<beast>family  <bug>family  "
    db $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_050:  ; 50 GulpBeast: "?????    ?????    "
    db $64, $64, $64, $64, $64, $62, $62, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_051:  ; 51 Skullroo: "<beast>family  <zombie>family  "
    db $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $17, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_052:  ; 52 WindBeast: "<beast>family  <material>family  "
    db $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_053:  ; 53 Anteater: "?????    ?????    "
    db $64, $64, $64, $64, $64, $62, $62, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_054:  ; 54 SuperTen: "<beast>family  Mudron   "
    db $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $30, $52, $41, $4F, $4C, $4B, $62, $62, $62, $F0
LibRecipeText_055:  ; 55 IronTurt: "<beast>family  Tortragon"
    db $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $37, $4C, $4F, $51, $4F, $3E, $44, $4C, $4B, $F0
LibRecipeText_056:  ; 56 Mommonja: "<beast>family  DuckKite "
    db $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $27, $52, $40, $48, $2E, $46, $51, $42, $62, $F0
LibRecipeText_057:  ; 57 HammerMan: "<beast>family  Stubsuck "
    db $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $36, $51, $52, $3F, $50, $52, $40, $48, $62, $F0
LibRecipeText_058:  ; 58 Grizzly: "<beast>family  <devil>family  "
    db $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_059:  ; 59 Yeti: "<beast>family  Orc      "
    db $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $32, $4F, $40, $62, $62, $62, $62, $62, $62, $F0
LibRecipeText_060:  ; 60 MadGopher: "<beast>family  SabreMan "
    db $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $36, $3E, $3F, $4F, $42, $30, $3E, $4B, $62, $F0
LibRecipeText_061:  ; 61 FairyRat: "<beast>family  LizardFly"
    db $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $2F, $46, $57, $3E, $4F, $41, $29, $49, $56, $F0
LibRecipeText_062:  ; 62 Unicorn: "<beast>family  FangSlime"
    db $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $29, $3E, $4B, $44, $36, $49, $46, $4A, $42, $F0
LibRecipeText_063:  ; 63 Goategon: "<beast>family  DrakSlime"
    db $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $27, $4F, $3E, $48, $36, $49, $46, $4A, $42, $F0
LibRecipeText_064:  ; 64 WildApe: "<beast>family  MadPecker"
    db $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $30, $3E, $41, $33, $42, $40, $48, $42, $4F, $F0
LibRecipeText_065:  ; 65 Trumpeter: "WildApe  WildApe  "
    db $3A, $46, $49, $41, $24, $4D, $42, $62, $62, $3A, $46, $49, $41, $24, $4D, $42, $62, $62, $F0
LibRecipeText_066:  ; 66 KingLeo: "TrumpeterTrumpeter"
    db $37, $4F, $52, $4A, $4D, $42, $51, $42, $4F, $37, $4F, $52, $4A, $4D, $42, $51, $42, $4F, $F0
LibRecipeText_067:  ; 67 DarkHorn: "<beast>family  ?????    "
    db $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_068:  ; 68 MadCat: "<beast>family  Dragon   "
    db $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $27, $4F, $3E, $44, $4C, $4B, $62, $62, $62, $F0
LibRecipeText_069:  ; 69 BigEye: "<beast>family  EyeBall  "
    db $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $28, $56, $42, $25, $3E, $49, $49, $62, $62, $F0
LibRecipeText_070:  ; 70 Picky: "<bird>family  <slime>family  "
    db $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_071:  ; 71 Wyvern: "<bird>family  <dragon>family  "
    db $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_072:  ; 72 BullBird: "<bird>family  <beast>family  "
    db $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_073:  ; 73 Florajay: "<bird>family  <plant>family  "
    db $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_074:  ; 74 DuckKite: "<bird>family  <bug>family  "
    db $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_075:  ; 75 MadPecker: "<bird>family  <devil>family  "
    db $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_076:  ; 76 MadRaven: "<bird>family  <zombie>family  "
    db $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $17, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_077:  ; 77 MistyWing: "<bird>family  <material>family  "
    db $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_078:  ; 78 Dracky: "?????    ?????    "
    db $64, $64, $64, $64, $64, $62, $62, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_079:  ; 79 BigRoost: "?????    ?????    "
    db $64, $64, $64, $64, $64, $62, $62, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_080:  ; 80 StubBird: "<bird>family  RockSlime"
    db $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $35, $4C, $40, $48, $36, $49, $46, $4A, $42, $F0
LibRecipeText_081:  ; 81 LandOwl: "?????    ?????    "
    db $64, $64, $64, $64, $64, $62, $62, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_082:  ; 82 MadGoose: "<bird>family  Droll    "
    db $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $27, $4F, $4C, $49, $49, $62, $62, $62, $62, $F0
LibRecipeText_083:  ; 83 MadCondor: "<bird>family  CoilBird "
    db $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $26, $4C, $46, $49, $25, $46, $4F, $41, $62, $F0
LibRecipeText_084:  ; 84 Blizzardy: "<bird>family  IceMan   "
    db $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $2C, $40, $42, $30, $3E, $4B, $62, $62, $62, $F0
LibRecipeText_085:  ; 85 Phoenix: "<bird>family  Gismo    "
    db $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $2A, $46, $50, $4A, $4C, $62, $62, $62, $62, $F0
LibRecipeText_086:  ; 86 ZapBird: "?????    ?????    "
    db $64, $64, $64, $64, $64, $62, $62, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_087:  ; 87 WhipBird: "<bird>family  Rayburn  "
    db $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $35, $3E, $56, $3F, $52, $4F, $4B, $62, $62, $F0
LibRecipeText_088:  ; 88 FunkyBird: "<bird>family  DanceVegi"
    db $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $27, $3E, $4B, $40, $42, $39, $42, $44, $46, $F0
LibRecipeText_089:  ; 89 RainHawk: "BlizzardyPhoenix  "
    db $25, $49, $46, $57, $57, $3E, $4F, $41, $56, $33, $45, $4C, $42, $4B, $46, $55, $62, $62, $F0
LibRecipeText_090:  ; 90 MadPlant: "<plant>family  <slime>family  "
    db $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_091:  ; 91 FireWeed: "<plant>family  <dragon>family  "
    db $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_092:  ; 92 FloraMan: "<plant>family  <beast>family  "
    db $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_093:  ; 93 WingTree: "<plant>family  <bird>family  "
    db $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_094:  ; 94 CactiBall: "<plant>family  <bug>family  "
    db $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_095:  ; 95 Gulpple: "<plant>family  <devil>family  "
    db $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_096:  ; 96 Toadstool: "<plant>family  <zombie>family  "
    db $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $17, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_097:  ; 97 AmberWeed: "<plant>family  <material>family  "
    db $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_098:  ; 98 Stubsuck: "?????    ?????    "
    db $64, $64, $64, $64, $64, $62, $62, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_099:  ; 99 Oniono: "<plant>family  Gophecada"
    db $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $2A, $4C, $4D, $45, $42, $40, $3E, $41, $3E, $F0
LibRecipeText_100:  ; 100 DanceVegi: "<plant>family  Facer    "
    db $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $29, $3E, $40, $42, $4F, $62, $62, $62, $62, $F0
LibRecipeText_101:  ; 101 TreeBoy: "<plant>family  Pixy     "
    db $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $33, $46, $55, $56, $62, $62, $62, $62, $62, $F0
LibRecipeText_102:  ; 102 FaceTree: "<plant>family  NiteWhip "
    db $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $31, $46, $51, $42, $3A, $45, $46, $4D, $62, $F0
LibRecipeText_103:  ; 103 HerbMan: "<plant>family  FunkyBird"
    db $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $29, $52, $4B, $48, $56, $25, $46, $4F, $41, $F0
LibRecipeText_104:  ; 104 BeanMan: "<plant>family  PillowRat"
    db $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $33, $46, $49, $49, $4C, $54, $35, $3E, $51, $F0
LibRecipeText_105:  ; 105 EvilSeed: "<plant>family  DarkEye  "
    db $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $27, $3E, $4F, $48, $28, $56, $42, $62, $62, $F0
LibRecipeText_106:  ; 106 ManEater: "EvilSeed EvilSeed "
    db $28, $53, $46, $49, $36, $42, $42, $41, $62, $28, $53, $46, $49, $36, $42, $42, $41, $62, $F0
LibRecipeText_107:  ; 107 Snapper: "ManEater ManEater "
    db $30, $3E, $4B, $28, $3E, $51, $42, $4F, $62, $30, $3E, $4B, $28, $3E, $51, $42, $4F, $62, $F0
LibRecipeText_108:  ; 108 Rosevine: "<plant>family  ?????    "
    db $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_109:  ; 109 Watabou: "?????    ?????    "
    db $64, $64, $64, $64, $64, $62, $62, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_110:  ; 110 GiantSlug: "<bug>family  <slime>family  "
    db $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_111:  ; 111 Catapila: "<bug>family  <dragon>family  "
    db $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_112:  ; 112 Gophecada: "<bug>family  <beast>family  "
    db $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_113:  ; 113 Butterfly: "<bug>family  <bird>family  "
    db $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_114:  ; 114 WeedBug: "<bug>family  <plant>family  "
    db $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_115:  ; 115 GiantWorm: "<bug>family  <devil>family  "
    db $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_116:  ; 116 Lipsy: "<bug>family  <zombie>family  "
    db $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $17, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_117:  ; 117 StagBug: "<bug>family  <material>family  "
    db $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_118:  ; 118 ArmyAnt: "?????    ?????    "
    db $64, $64, $64, $64, $64, $62, $62, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_119:  ; 119 GoHopper: "?????    ?????    "
    db $64, $64, $64, $64, $64, $62, $62, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_120:  ; 120 TailEater: "<bug>family  FloraMan "
    db $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $29, $49, $4C, $4F, $3E, $30, $3E, $4B, $62, $F0
LibRecipeText_121:  ; 121 ArmorPede: "<bug>family  IronTurt "
    db $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $2C, $4F, $4C, $4B, $37, $52, $4F, $51, $62, $F0
LibRecipeText_122:  ; 122 Eyeder: "<bug>family  AmberWeed"
    db $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $24, $4A, $3F, $42, $4F, $3A, $42, $42, $41, $F0
LibRecipeText_123:  ; 123 GiantMoth: "<bug>family  Saccer   "
    db $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $36, $3E, $40, $40, $42, $4F, $62, $62, $62, $F0
LibRecipeText_124:  ; 124 Droll: "<bug>family  Spooky   "
    db $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $36, $4D, $4C, $4C, $48, $56, $62, $62, $62, $F0
LibRecipeText_125:  ; 125 ArmyCrab: "<bug>family  DarkCrab "
    db $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $27, $3E, $4F, $48, $26, $4F, $3E, $3F, $62, $F0
LibRecipeText_126:  ; 126 MadHornet: "<bug>family  FairyRat "
    db $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $29, $3E, $46, $4F, $56, $35, $3E, $51, $62, $F0
LibRecipeText_127:  ; 127 HornBeet: "StagBug  StagBug  "
    db $36, $51, $3E, $44, $25, $52, $44, $62, $62, $36, $51, $3E, $44, $25, $52, $44, $62, $62, $F0
LibRecipeText_128:  ; 128 Armorpion: "HornBeet HornBeet "
    db $2B, $4C, $4F, $4B, $25, $42, $42, $51, $62, $2B, $4C, $4F, $4B, $25, $42, $42, $51, $62, $F0
LibRecipeText_129:  ; 129 Digster: "<bug>family  ?????    "
    db $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_130:  ; 130 Pixy: "<devil>family  <slime>family  "
    db $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_131:  ; 131 ArcDemon: "<devil>family  ?????    "
    db $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_132:  ; 132 AgDevil: "?????    ?????    "
    db $64, $64, $64, $64, $64, $62, $62, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_133:  ; 133 Demonite: "<devil>family  <bird>family  "
    db $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_134:  ; 134 DarkEye: "<devil>family  <plant>family  "
    db $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_135:  ; 135 EyeBall: "<devil>family  <bug>family  "
    db $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_136:  ; 136 SkulRider: "<devil>family  <zombie>family  "
    db $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $17, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_137:  ; 137 EvilBeast: "<devil>family  <material>family  "
    db $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_138:  ; 138 1EyeClown: "?????    ?????    "
    db $64, $64, $64, $64, $64, $62, $62, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_139:  ; 139 Gremlin: "<devil>family  <beast>family  "
    db $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_140:  ; 140 MedusaEye: "<devil>family  <dragon>family  "
    db $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_141:  ; 141 Lionex: "<devil>family  LizardMan"
    db $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $2F, $46, $57, $3E, $4F, $41, $30, $3E, $4B, $F0
LibRecipeText_142:  ; 142 GoatHorn: "<devil>family  DarkHorn "
    db $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $27, $3E, $4F, $48, $2B, $4C, $4F, $4B, $62, $F0
LibRecipeText_143:  ; 143 Orc: "<devil>family  BeanMan  "
    db $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $25, $42, $3E, $4B, $30, $3E, $4B, $62, $62, $F0
LibRecipeText_144:  ; 144 Ogre: "<devil>family  HammerMan"
    db $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $2B, $3E, $4A, $4A, $42, $4F, $30, $3E, $4B, $F0
LibRecipeText_145:  ; 145 GateGuard: "Demonite Demonite "
    db $27, $42, $4A, $4C, $4B, $46, $51, $42, $62, $27, $42, $4A, $4C, $4B, $46, $51, $42, $62, $F0
LibRecipeText_146:  ; 146 ChopClown: "1EyeClown1EyeClown"
    db $01, $28, $56, $42, $26, $49, $4C, $54, $4B, $01, $28, $56, $42, $26, $49, $4C, $54, $4B, $F0
LibRecipeText_147:  ; 147 Grendal: "<devil>family  MadDragon"
    db $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $30, $3E, $41, $27, $4F, $3E, $44, $4C, $4B, $F0
LibRecipeText_148:  ; 148 Akubar: "Grenadal Grenadal "
    db $2A, $4F, $42, $4B, $3E, $41, $3E, $49, $62, $2A, $4F, $42, $4B, $3E, $41, $3E, $49, $62, $F0
LibRecipeText_149:  ; 149 MadKnight: "<devil>family  RogueNite"
    db $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $35, $4C, $44, $52, $42, $31, $46, $51, $42, $F0
LibRecipeText_150:  ; 150 Gigantes: "<devil>family  BigEye   "
    db $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $25, $46, $44, $28, $56, $42, $62, $62, $62, $F0
LibRecipeText_151:  ; 151 Centasaur: "?????    ?????    "
    db $64, $64, $64, $64, $64, $62, $62, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_152:  ; 152 EvilArmor: "<devil>family  ArmorPede"
    db $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $24, $4F, $4A, $4C, $4F, $33, $42, $41, $42, $F0
LibRecipeText_153:  ; 153 Jamirus: "Akubar   RainHawk "
    db $24, $48, $52, $3F, $3E, $4F, $62, $62, $62, $35, $3E, $46, $4B, $2B, $3E, $54, $48, $62, $F0
LibRecipeText_154:  ; 154 Durran: "CentasaurGoldGolem"
    db $26, $42, $4B, $51, $3E, $50, $3E, $52, $4F, $2A, $4C, $49, $41, $2A, $4C, $49, $42, $4A, $F0
LibRecipeText_155:  ; 155 Spooky: "<zombie>family  <slime>family  "
    db $17, $43, $3E, $4A, $46, $49, $56, $62, $62, $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_156:  ; 156 Skullgon: "<zombie>family  Swordgon "
    db $17, $43, $3E, $4A, $46, $49, $56, $62, $62, $36, $54, $4C, $4F, $41, $44, $4C, $4B, $62, $F0
LibRecipeText_157:  ; 157 Putrepup: "<zombie>family  <beast>family  "
    db $17, $43, $3E, $4A, $46, $49, $56, $62, $62, $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_158:  ; 158 RotRaven: "<zombie>family  <bird>family  "
    db $17, $43, $3E, $4A, $46, $49, $56, $62, $62, $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_159:  ; 159 Mummy: "<zombie>family  <plant>family  "
    db $17, $43, $3E, $4A, $46, $49, $56, $62, $62, $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_160:  ; 160 DarkCrab: "<zombie>family  <bug>family  "
    db $17, $43, $3E, $4A, $46, $49, $56, $62, $62, $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_161:  ; 161 DeadNite: "<zombie>family  <devil>family  "
    db $17, $43, $3E, $4A, $46, $49, $56, $62, $62, $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_162:  ; 162 Shadow: "<zombie>family  <material>family  "
    db $17, $43, $3E, $4A, $46, $49, $56, $62, $62, $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_163:  ; 163 Hork: "?????    ?????    "
    db $64, $64, $64, $64, $64, $62, $62, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_164:  ; 164 Mudron: "<zombie>family  GiantSlug"
    db $17, $43, $3E, $4A, $46, $49, $56, $62, $62, $2A, $46, $3E, $4B, $51, $36, $49, $52, $44, $F0
LibRecipeText_165:  ; 165 NiteWhip: "<zombie>family  MistyWing"
    db $17, $43, $3E, $4A, $46, $49, $56, $62, $62, $30, $46, $50, $51, $56, $3A, $46, $4B, $44, $F0
LibRecipeText_166:  ; 166 MadSpirit: "<zombie>family  <dragon>family  "
    db $17, $43, $3E, $4A, $46, $49, $56, $62, $62, $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_167:  ; 167 WindMerge: "<zombie>family  WindBeast"
    db $17, $43, $3E, $4A, $46, $49, $56, $62, $62, $3A, $46, $4B, $41, $25, $42, $3E, $50, $51, $F0
LibRecipeText_168:  ; 168 Reaper: "<zombie>family  WeedBug  "
    db $17, $43, $3E, $4A, $46, $49, $56, $62, $62, $3A, $42, $42, $41, $25, $52, $44, $62, $62, $F0
LibRecipeText_169:  ; 169 DeadNoble: "DeadNite DeadNite "
    db $27, $42, $3E, $41, $31, $46, $51, $42, $62, $27, $42, $3E, $41, $31, $46, $51, $42, $62, $F0
LibRecipeText_170:  ; 170 WhiteKing: "<zombie>family  ?????    "
    db $17, $43, $3E, $4A, $46, $49, $56, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_171:  ; 171 BoneSlave: "Hork     Hork     "
    db $2B, $4C, $4F, $48, $62, $62, $62, $62, $62, $2B, $4C, $4F, $48, $62, $62, $62, $62, $62, $F0
LibRecipeText_172:  ; 172 Skeletor: "BoneSlaveBoneSlave"
    db $25, $4C, $4B, $42, $36, $49, $3E, $53, $42, $25, $4C, $4B, $42, $36, $49, $3E, $53, $42, $F0
LibRecipeText_173:  ; 173 Servant: "Skeletor Skeletor "
    db $36, $48, $42, $49, $42, $51, $4C, $4F, $62, $36, $48, $42, $49, $42, $51, $4C, $4F, $62, $F0
LibRecipeText_174:  ; 174 Copycat: "?????    ?????    "
    db $64, $64, $64, $64, $64, $62, $62, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_175:  ; 175 JewelBag: "<material>family  <slime>family  "
    db $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_176:  ; 176 EvilWand: "<material>family  <dragon>family  "
    db $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_177:  ; 177 MadCandle: "<material>family  <beast>family  "
    db $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_178:  ; 178 CoilBird: "<material>family  <bird>family  "
    db $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_179:  ; 179 Facer: "<material>family  <plant>family  "
    db $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $14, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_180:  ; 180 SpikyBoy: "<material>family  <bug>family  "
    db $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $15, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_181:  ; 181 MadMirror: "<material>family  <devil>family  "
    db $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $16, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_182:  ; 182 RogueNite: "<material>family  <zombie>family  "
    db $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $17, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
LibRecipeText_183:  ; 183 Goopi: "?????    ?????    "
    db $64, $64, $64, $64, $64, $62, $62, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_184:  ; 184 Voodoll: "<material>family  Lipsy    "
    db $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $2F, $46, $4D, $50, $56, $62, $62, $62, $62, $F0
LibRecipeText_185:  ; 185 MetalDrak: "<material>family  Andreal  "
    db $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $24, $4B, $41, $4F, $42, $3E, $49, $62, $62, $F0
LibRecipeText_186:  ; 186 Balzak: "<material>family  ?????    "
    db $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $64, $64, $64, $64, $64, $62, $62, $62, $62, $F0
LibRecipeText_187:  ; 187 SabreMan: "<material>family  GiantWorm"
    db $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $2A, $46, $3E, $4B, $51, $3A, $4C, $4F, $4A, $F0
LibRecipeText_188:  ; 188 CurseLamp: "<material>family  WingTree "
    db $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $3A, $46, $4B, $44, $37, $4F, $42, $42, $62, $F0
LibRecipeText_189:  ; 189 Roboster: "<material>family  SkulRider"
    db $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $36, $48, $52, $49, $35, $46, $41, $42, $4F, $F0
LibRecipeText_190:  ; 190 EvilPot: "<material>family  Snaily   "
    db $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $36, $4B, $3E, $46, $49, $56, $62, $62, $62, $F0
LibRecipeText_191:  ; 191 Gismo: "Goopi    FireWeed "
    db $2A, $4C, $4C, $4D, $46, $62, $62, $62, $62, $29, $46, $4F, $42, $3A, $42, $42, $41, $62, $F0
LibRecipeText_192:  ; 192 LavaMan: "MetalDrakArcDemon "
    db $30, $42, $51, $3E, $49, $27, $4F, $3E, $48, $24, $4F, $40, $27, $42, $4A, $4C, $4B, $62, $F0
LibRecipeText_193:  ; 193 IceMan: "Roboster KingLeo  "
    db $35, $4C, $3F, $4C, $50, $51, $42, $4F, $62, $2E, $46, $4B, $44, $2F, $42, $4C, $62, $62, $F0
LibRecipeText_194:  ; 194 Mimic: "<material>family  BoxSlime "
    db $18, $43, $3E, $4A, $46, $49, $56, $62, $62, $25, $4C, $55, $36, $49, $46, $4A, $42, $62, $F0
LibRecipeText_195:  ; 195 MudDoll: "Goopi    Goopi    "
    db $2A, $4C, $4C, $4D, $46, $62, $62, $62, $62, $2A, $4C, $4C, $4D, $46, $62, $62, $62, $62, $F0
LibRecipeText_196:  ; 196 Golem: "MudDoll  MudDoll  "
    db $30, $52, $41, $27, $4C, $49, $49, $62, $62, $30, $52, $41, $27, $4C, $49, $49, $62, $62, $F0
LibRecipeText_197:  ; 197 StoneMan: "Golem    Golem    "
    db $2A, $4C, $49, $42, $4A, $62, $62, $62, $62, $2A, $4C, $49, $42, $4A, $62, $62, $62, $62, $F0
LibRecipeText_198:  ; 198 BombCrag: "SpikyBoy SpikyBoy "
    db $36, $4D, $46, $48, $56, $25, $4C, $56, $62, $36, $4D, $46, $48, $56, $25, $4C, $56, $62, $F0
LibRecipeText_199:  ; 199 GoldGolem: "IceMan   LavaMan  "
    db $2C, $40, $42, $30, $3E, $4B, $62, $62, $62, $2F, $3E, $53, $3E, $30, $3E, $4B, $62, $62, $F0
LibRecipeText_200:  ; 200 DracoLord: "Servant  GreatDrak"
    db $36, $42, $4F, $53, $3E, $4B, $51, $62, $62, $2A, $4F, $42, $3E, $51, $27, $4F, $3E, $48, $F0
LibRecipeText_201:  ; 201 DracoLord: "DracoLordDivinegon"
    db $27, $4F, $3E, $40, $4C, $2F, $4C, $4F, $41, $27, $46, $53, $46, $4B, $42, $44, $4C, $4B, $F0
LibRecipeText_202:  ; 202 Hargon: "WhitekingMetalKing"
    db $3A, $45, $46, $51, $42, $48, $46, $4B, $44, $30, $42, $51, $3E, $49, $2E, $46, $4B, $44, $F0
LibRecipeText_203:  ; 203 Sidoh: "Jamirus  Rosevine "
    db $2D, $3E, $4A, $46, $4F, $52, $50, $62, $62, $35, $4C, $50, $42, $53, $46, $4B, $42, $62, $F0
LibRecipeText_204:  ; 204 Baramos: "Hargon   Orochi   "
    db $2B, $3E, $4F, $44, $4C, $4B, $62, $62, $62, $32, $4F, $4C, $40, $45, $46, $62, $62, $62, $F0
LibRecipeText_205:  ; 205 Zoma: "DracoLordSidoh    "
    db $27, $4F, $3E, $40, $4C, $2F, $4C, $4F, $41, $36, $46, $41, $4C, $45, $62, $62, $62, $62, $F0
LibRecipeText_206:  ; 206 Pizzaro: "Durran   Divinegon "
    db $27, $52, $4F, $4F, $3E, $4B, $62, $62, $62, $27, $46, $53, $46, $4B, $42, $44, $4C, $4B, $62, $F0
LibRecipeText_207:  ; 207 Esterk: "Pizzaro  KingLeo  "
    db $33, $46, $57, $57, $3E, $4F, $4C, $62, $62, $2E, $46, $4B, $44, $2F, $42, $4C, $62, $62, $F0
LibRecipeText_208:  ; 208 Mirudraas: "Esterk   GoldSlime"
    db $28, $50, $51, $42, $4F, $48, $62, $62, $62, $2A, $4C, $49, $41, $36, $49, $46, $4A, $42, $F0
LibRecipeText_209:  ; 209 Mirudraas: "MirudraasSpikerous"
    db $30, $46, $4F, $52, $41, $4F, $3E, $3E, $50, $36, $4D, $46, $48, $42, $4F, $4C, $52, $50, $F0
LibRecipeText_210:  ; 210 Mudou: "Baramos  DarkHorn "
    db $25, $3E, $4F, $3E, $4A, $4C, $50, $62, $62, $27, $3E, $4F, $48, $2B, $4C, $4F, $4B, $62, $F0
LibRecipeText_211:  ; 211 DeathMore: "Zoma     Mirudraas"
    db $3D, $4C, $4A, $3E, $62, $62, $62, $62, $62, $30, $46, $4F, $52, $41, $4F, $3E, $3E, $50, $F0
LibRecipeText_212:  ; 212 DeathMore: "DeathMoreArmorpion"
    db $27, $42, $3E, $51, $45, $30, $4C, $4F, $42, $24, $4F, $4A, $4C, $4F, $4D, $46, $4C, $4B, $F0
LibRecipeText_213:  ; 213 DeathMore: "DeathMoreMudou    "
    db $27, $42, $3E, $51, $45, $30, $4C, $4F, $42, $30, $52, $41, $4C, $52, $62, $62, $62, $62, $F0
LibRecipeText_214:  ; 214 Darkdrium: "DeathMoreWatabou  "
    db $27, $42, $3E, $51, $45, $30, $4C, $4F, $42, $3A, $3E, $51, $3E, $3F, $4C, $52, $62, $62, $F0
LibRecipeText_215:  ; 215-220 (shared: combat-only species): "?????    ?????"
    db $64, $64, $64, $64, $64, $62, $62, $62, $62, $64, $64, $64, $64, $64, $F0
; =============================================================================
; MONSTER DESCRIPTIONS ($53D3-$7719) — text mode 1 (base $420B = dispatch
; entries 261-475), one string per species 0-214, id order. Library detail
; page line 2: <= 3 lines of <= 18 cells, $F1 = next line, $F0 = end.
; Glyphs beyond the charmap letters: $9C '-', $B6 '&', $67 "'t", $68 "'s".
; S108 re-section (tools/resection_monster_desc.py; was mgbdis fake code);
; bytes unchanged. Patched tree: the compiler region gd_monster_desc
; (gamedata.monster_text, PROJECT_COMPILER §2.24).
; =============================================================================
MonsterDesc_000_DrakSlime:  ; $53D3 "Moves & jumps with/its tail & wings"
    db $30, $4C, $53, $42, $50, $62, $B6, $62, $47, $52, $4A, $4D, $50, $62, $54, $46, $51, $45, $F1, $46, $51, $50, $62, $51, $3E, $46, $49, $62, $B6, $62, $54, $46, $4B, $44, $50, $F0
MonsterDesc_001_SpotSlime:  ; $53F7 "Larger than a/regular slime &/spotted"
    db $2F, $3E, $4F, $44, $42, $4F, $62, $51, $45, $3E, $4B, $62, $3E, $F1, $4F, $42, $44, $52, $49, $3E, $4F, $62, $50, $49, $46, $4A, $42, $62, $B6, $F1, $50, $4D, $4C, $51, $51, $42, $41, $F0
MonsterDesc_002_WingSlime:  ; $541D "Flies with wings/that grew on/its back"
    db $29, $49, $46, $42, $50, $62, $54, $46, $51, $45, $62, $54, $46, $4B, $44, $50, $F1, $51, $45, $3E, $51, $62, $44, $4F, $42, $54, $62, $4C, $4B, $F1, $46, $51, $50, $62, $3F, $3E, $40, $48, $F0
MonsterDesc_003_TreeSlime:  ; $5444 "Its leafy top/absorbs energy/from sunlight"
    db $2C, $51, $50, $62, $49, $42, $3E, $43, $56, $62, $51, $4C, $4D, $F1, $3E, $3F, $50, $4C, $4F, $3F, $50, $62, $42, $4B, $42, $4F, $44, $56, $F1, $43, $4F, $4C, $4A, $62, $50, $52, $4B, $49, $46, $44, $45, $51, $F0
MonsterDesc_004_Snaily:  ; $546F "Hides in its/shell when/under attack"
    db $2B, $46, $41, $42, $50, $62, $46, $4B, $62, $46, $51, $50, $F1, $50, $45, $42, $49, $49, $62, $54, $45, $42, $4B, $F1, $52, $4B, $41, $42, $4F, $62, $3E, $51, $51, $3E, $40, $48, $F0
MonsterDesc_005_SlimeNite:  ; $5494 "The knight riding/on this slime is/part of it's body"
    db $37, $45, $42, $62, $48, $4B, $46, $44, $45, $51, $62, $4F, $46, $41, $46, $4B, $44, $F1, $4C, $4B, $62, $51, $45, $46, $50, $62, $50, $49, $46, $4A, $42, $62, $46, $50, $F1, $4D, $3E, $4F, $51, $62, $4C, $43, $62, $46, $51, $68, $62, $3F, $4C, $41, $56, $F0
MonsterDesc_006_Babble:  ; $54C8 "Can transform/its body into/any shape"
    db $26, $3E, $4B, $62, $51, $4F, $3E, $4B, $50, $43, $4C, $4F, $4A, $F1, $46, $51, $50, $62, $3F, $4C, $41, $56, $62, $46, $4B, $51, $4C, $F1, $3E, $4B, $56, $62, $50, $45, $3E, $4D, $42, $F0
MonsterDesc_007_BoxSlime:  ; $54EE "Being trapped in a/box gives this/slime it's shape"
    db $25, $42, $46, $4B, $44, $62, $51, $4F, $3E, $4D, $4D, $42, $41, $62, $46, $4B, $62, $3E, $F1, $3F, $4C, $55, $62, $44, $46, $53, $42, $50, $62, $51, $45, $46, $50, $F1, $50, $49, $46, $4A, $42, $62, $46, $51, $68, $62, $50, $45, $3E, $4D, $42, $F0
MonsterDesc_008_Slime:  ; $5520 "The most abundant/of this popular/specie"
    db $37, $45, $42, $62, $4A, $4C, $50, $51, $62, $3E, $3F, $52, $4B, $41, $3E, $4B, $51, $F1, $4C, $43, $62, $51, $45, $46, $50, $62, $4D, $4C, $4D, $52, $49, $3E, $4F, $F1, $50, $4D, $42, $40, $46, $42, $F0
MonsterDesc_009_Healer:  ; $5549 "Uses its powerful/tentacles to/move about"
    db $38, $50, $42, $50, $62, $46, $51, $50, $62, $4D, $4C, $54, $42, $4F, $43, $52, $49, $F1, $51, $42, $4B, $51, $3E, $40, $49, $42, $50, $62, $51, $4C, $F1, $4A, $4C, $53, $42, $62, $3E, $3F, $4C, $52, $51, $F0
MonsterDesc_010_FangSlime:  ; $5573 "Has a red Mohawk/and is very brave/& proud"
    db $2B, $3E, $50, $62, $3E, $62, $4F, $42, $41, $62, $30, $4C, $45, $3E, $54, $48, $F1, $3E, $4B, $41, $62, $46, $50, $62, $53, $42, $4F, $56, $62, $3F, $4F, $3E, $53, $42, $F1, $B6, $62, $4D, $4F, $4C, $52, $41, $F0
MonsterDesc_011_RockSlime:  ; $559E "Its skin is as/hard as rock"
    db $2C, $51, $50, $62, $50, $48, $46, $4B, $62, $46, $50, $62, $3E, $50, $F1, $45, $3E, $4F, $41, $62, $3E, $50, $62, $4F, $4C, $40, $48, $F0
MonsterDesc_012_SlimeBorg:  ; $55BA "Oil flows through/its body instead/of blood"
    db $32, $46, $49, $62, $43, $49, $4C, $54, $50, $62, $51, $45, $4F, $4C, $52, $44, $45, $F1, $46, $51, $50, $62, $3F, $4C, $41, $56, $62, $46, $4B, $50, $51, $42, $3E, $41, $F1, $4C, $43, $62, $3F, $49, $4C, $4C, $41, $F0
MonsterDesc_013_Slabbit:  ; $55E6 "Flees very fast/with its strong/hind legs"
    db $29, $49, $42, $42, $50, $62, $53, $42, $4F, $56, $62, $43, $3E, $50, $51, $F1, $54, $46, $51, $45, $62, $46, $51, $50, $62, $50, $51, $4F, $4C, $4B, $44, $F1, $45, $46, $4B, $41, $62, $49, $42, $44, $50, $F0
MonsterDesc_014_SpotKing:  ; $5610 "Several SpotSlimes/combined into one/to form this King"
    db $36, $42, $53, $42, $4F, $3E, $49, $62, $36, $4D, $4C, $51, $36, $49, $46, $4A, $42, $50, $F1, $40, $4C, $4A, $3F, $46, $4B, $42, $41, $62, $46, $4B, $51, $4C, $62, $4C, $4B, $42, $F1, $51, $4C, $62, $43, $4C, $4F, $4A, $62, $51, $45, $46, $50, $62, $2E, $46, $4B, $44, $F0
MonsterDesc_015_KingSlime:  ; $5647 "Several Slimes/combined into one/to form this King"
    db $36, $42, $53, $42, $4F, $3E, $49, $62, $36, $49, $46, $4A, $42, $50, $F1, $40, $4C, $4A, $3F, $46, $4B, $42, $41, $62, $46, $4B, $51, $4C, $62, $4C, $4B, $42, $F1, $51, $4C, $62, $43, $4C, $4F, $4A, $62, $51, $45, $46, $50, $62, $2E, $46, $4B, $44, $F0
MonsterDesc_016_Metaly:  ; $567A "Its diet of iron/gives this slime/a metal body"
    db $2C, $51, $50, $62, $41, $46, $42, $51, $62, $4C, $43, $62, $46, $4F, $4C, $4B, $F1, $44, $46, $53, $42, $50, $62, $51, $45, $46, $50, $62, $50, $49, $46, $4A, $42, $F1, $3E, $62, $4A, $42, $51, $3E, $49, $62, $3F, $4C, $41, $56, $F0
MonsterDesc_017_Metabble:  ; $56A9 "Produces strong/weapons from its/body"
    db $33, $4F, $4C, $41, $52, $40, $42, $50, $62, $50, $51, $4F, $4C, $4B, $44, $F1, $54, $42, $3E, $4D, $4C, $4B, $50, $62, $43, $4F, $4C, $4A, $62, $46, $51, $50, $F1, $3F, $4C, $41, $56, $F0
MonsterDesc_018_MetalKing:  ; $56CF "Several Metalys/combined to form/this King"
    db $36, $42, $53, $42, $4F, $3E, $49, $62, $30, $42, $51, $3E, $49, $56, $50, $F1, $40, $4C, $4A, $3F, $46, $4B, $42, $41, $62, $51, $4C, $62, $43, $4C, $4F, $4A, $F1, $51, $45, $46, $50, $62, $2E, $46, $4B, $44, $F0
MonsterDesc_019_GoldSlime:  ; $56FA "The toughest/creature in the/slime family"
    db $37, $45, $42, $62, $51, $4C, $52, $44, $45, $42, $50, $51, $F1, $40, $4F, $42, $3E, $51, $52, $4F, $42, $62, $46, $4B, $62, $51, $45, $42, $F1, $50, $49, $46, $4A, $42, $62, $43, $3E, $4A, $46, $49, $56, $F0
MonsterDesc_020_DragonKid:  ; $5724 "It does not grow/any bigger than/this"
    db $2C, $51, $62, $41, $4C, $42, $50, $62, $4B, $4C, $51, $62, $44, $4F, $4C, $54, $F1, $3E, $4B, $56, $62, $3F, $46, $44, $44, $42, $4F, $62, $51, $45, $3E, $4B, $F1, $51, $45, $46, $50, $F0
MonsterDesc_021_Tortragon:  ; $574A "It has a tough/shell but it can't/hide inside it"
    db $2C, $51, $62, $45, $3E, $50, $62, $3E, $62, $51, $4C, $52, $44, $45, $F1, $50, $45, $42, $49, $49, $62, $3F, $52, $51, $62, $46, $51, $62, $40, $3E, $4B, $67, $F1, $45, $46, $41, $42, $62, $46, $4B, $50, $46, $41, $42, $62, $46, $51, $F0
MonsterDesc_022_Pteranod:  ; $577A "Flaps its large/wings and flies/with authority"
    db $29, $49, $3E, $4D, $50, $62, $46, $51, $50, $62, $49, $3E, $4F, $44, $42, $F1, $54, $46, $4B, $44, $50, $62, $3E, $4B, $41, $62, $43, $49, $46, $42, $50, $F1, $54, $46, $51, $45, $62, $3E, $52, $51, $45, $4C, $4F, $46, $51, $56, $F0
MonsterDesc_023_Gasgon:  ; $57A9 "Traps gas/in its belly to/float in the air"
    db $37, $4F, $3E, $4D, $50, $62, $44, $3E, $50, $F1, $46, $4B, $62, $46, $51, $50, $62, $3F, $42, $49, $49, $56, $62, $51, $4C, $F1, $43, $49, $4C, $3E, $51, $62, $46, $4B, $62, $51, $45, $42, $62, $3E, $46, $4F, $F0
MonsterDesc_024_FairyDrak:  ; $57D4 "Uses its tongue to/suck nectar from/flowers"
    db $38, $50, $42, $50, $62, $46, $51, $50, $62, $51, $4C, $4B, $44, $52, $42, $62, $51, $4C, $F1, $50, $52, $40, $48, $62, $4B, $42, $40, $51, $3E, $4F, $62, $43, $4F, $4C, $4A, $F1, $43, $49, $4C, $54, $42, $4F, $50, $F0
MonsterDesc_025_LizardMan:  ; $5800 "Smart enough to/skillfully use a/sword & shield"
    db $36, $4A, $3E, $4F, $51, $62, $42, $4B, $4C, $52, $44, $45, $62, $51, $4C, $F1, $50, $48, $46, $49, $49, $43, $52, $49, $49, $56, $62, $52, $50, $42, $62, $3E, $F1, $50, $54, $4C, $4F, $41, $62, $B6, $62, $50, $45, $46, $42, $49, $41, $F0
MonsterDesc_026_Poisongon:  ; $5830 "The fluid that is/secreted from its/fin is poisonous"
    db $37, $45, $42, $62, $43, $49, $52, $46, $41, $62, $51, $45, $3E, $51, $62, $46, $50, $F1, $50, $42, $40, $4F, $42, $51, $42, $41, $62, $43, $4F, $4C, $4A, $62, $46, $51, $50, $F1, $43, $46, $4B, $62, $46, $50, $62, $4D, $4C, $46, $50, $4C, $4B, $4C, $52, $50, $F0
MonsterDesc_027_Swordgon:  ; $5865 "Its body is/covered with/sword-like spikes"
    db $2C, $51, $50, $62, $3F, $4C, $41, $56, $62, $46, $50, $F1, $40, $4C, $53, $42, $4F, $42, $41, $62, $54, $46, $51, $45, $F1, $50, $54, $4C, $4F, $41, $9C, $49, $46, $48, $42, $62, $50, $4D, $46, $48, $42, $50, $F0
MonsterDesc_028_Dragon:  ; $5890 "The oldest living/species of dragon"
    db $37, $45, $42, $62, $4C, $49, $41, $42, $50, $51, $62, $49, $46, $53, $46, $4B, $44, $F1, $50, $4D, $42, $40, $46, $42, $50, $62, $4C, $43, $62, $41, $4F, $3E, $44, $4C, $4B, $F0
MonsterDesc_029_MiniDrak:  ; $58B4 "Runs by using/its hands & long/tail for balance"
    db $35, $52, $4B, $50, $62, $3F, $56, $62, $52, $50, $46, $4B, $44, $F1, $46, $51, $50, $62, $45, $3E, $4B, $41, $50, $62, $B6, $62, $49, $4C, $4B, $44, $F1, $51, $3E, $46, $49, $62, $43, $4C, $4F, $62, $3F, $3E, $49, $3E, $4B, $40, $42, $F0
MonsterDesc_030_MadDragon:  ; $58E4 "Runs by using/its hands & long/tail for balance"
    db $35, $52, $4B, $50, $62, $3F, $56, $62, $52, $50, $46, $4B, $44, $F1, $46, $51, $50, $62, $45, $3E, $4B, $41, $50, $62, $B6, $62, $49, $4C, $4B, $44, $F1, $51, $3E, $46, $49, $62, $43, $4C, $4F, $62, $3F, $3E, $49, $3E, $4B, $40, $42, $F0
MonsterDesc_031_Rayburn:  ; $5914 "Can grab prey/with its talons/& fly off"
    db $26, $3E, $4B, $62, $44, $4F, $3E, $3F, $62, $4D, $4F, $42, $56, $F1, $54, $46, $51, $45, $62, $46, $51, $50, $62, $51, $3E, $49, $4C, $4B, $50, $F1, $B6, $62, $43, $49, $56, $62, $4C, $43, $43, $F0
MonsterDesc_032_Chamelgon:  ; $593C "Changes its/skin color for/camouflage"
    db $26, $45, $3E, $4B, $44, $42, $50, $62, $46, $51, $50, $F1, $50, $48, $46, $4B, $62, $40, $4C, $49, $4C, $4F, $62, $43, $4C, $4F, $F1, $40, $3E, $4A, $4C, $52, $43, $49, $3E, $44, $42, $F0
MonsterDesc_033_LizardFly:  ; $5962 "Hovers in/midair with its/thin wings"
    db $2B, $4C, $53, $42, $4F, $50, $62, $46, $4B, $F1, $4A, $46, $41, $3E, $46, $4F, $62, $54, $46, $51, $45, $62, $46, $51, $50, $F1, $51, $45, $46, $4B, $62, $54, $46, $4B, $44, $50, $F0
MonsterDesc_034_Andreal:  ; $5987 "Sharp claws &/fangs are its most/deadly weapons"
    db $36, $45, $3E, $4F, $4D, $62, $40, $49, $3E, $54, $50, $62, $B6, $F1, $43, $3E, $4B, $44, $50, $62, $3E, $4F, $42, $62, $46, $51, $50, $62, $4A, $4C, $50, $51, $F1, $41, $42, $3E, $41, $49, $56, $62, $54, $42, $3E, $4D, $4C, $4B, $50, $F0
MonsterDesc_035_KingCobra:  ; $59B7 "Its poisonous bite/and sharp fangs/are deadly"
    db $2C, $51, $50, $62, $4D, $4C, $46, $50, $4C, $4B, $4C, $52, $50, $62, $3F, $46, $51, $42, $F1, $3E, $4B, $41, $62, $50, $45, $3E, $4F, $4D, $62, $43, $3E, $4B, $44, $50, $F1, $3E, $4F, $42, $62, $41, $42, $3E, $41, $49, $56, $F0
MonsterDesc_036_Spikerous:  ; $59E5 "Its spiky hard/shell protects/itself from danger"
    db $2C, $51, $50, $62, $50, $4D, $46, $48, $56, $62, $45, $3E, $4F, $41, $F1, $50, $45, $42, $49, $49, $62, $4D, $4F, $4C, $51, $42, $40, $51, $50, $F1, $46, $51, $50, $42, $49, $43, $62, $43, $4F, $4C, $4A, $62, $41, $3E, $4B, $44, $42, $4F, $F0
MonsterDesc_037_GreatDrak:  ; $5A16 "The biggest/dragon in the/dragon family"
    db $37, $45, $42, $62, $3F, $46, $44, $44, $42, $50, $51, $F1, $41, $4F, $3E, $44, $4C, $4B, $62, $46, $4B, $62, $51, $45, $42, $F1, $41, $4F, $3E, $44, $4C, $4B, $62, $43, $3E, $4A, $46, $49, $56, $F0
MonsterDesc_038_Crestpent:  ; $5A3E "It shakes its/crest to terrorize/its enemies"
    db $2C, $51, $62, $50, $45, $3E, $48, $42, $50, $62, $46, $51, $50, $F1, $40, $4F, $42, $50, $51, $62, $51, $4C, $62, $51, $42, $4F, $4F, $4C, $4F, $46, $57, $42, $F1, $46, $51, $50, $62, $42, $4B, $42, $4A, $46, $42, $50, $F0
MonsterDesc_039_WingSnake:  ; $5A6B "Glides through/the air with its/large wings"
    db $2A, $49, $46, $41, $42, $50, $62, $51, $45, $4F, $4C, $52, $44, $45, $F1, $51, $45, $42, $62, $3E, $46, $4F, $62, $54, $46, $51, $45, $62, $46, $51, $50, $F1, $49, $3E, $4F, $44, $42, $62, $54, $46, $4B, $44, $50, $F0
MonsterDesc_040_Coatol:  ; $5A97 "Constricts its/enemies with its/powerful body"
    db $26, $4C, $4B, $50, $51, $4F, $46, $40, $51, $50, $62, $46, $51, $50, $F1, $42, $4B, $42, $4A, $46, $42, $50, $62, $54, $46, $51, $45, $62, $46, $51, $50, $F1, $4D, $4C, $54, $42, $4F, $43, $52, $49, $62, $3F, $4C, $41, $56, $F0
MonsterDesc_041_Orochi:  ; $5AC5 "Its 5 heads can do/different things/at the same time"
    db $2C, $51, $50, $62, $05, $62, $45, $42, $3E, $41, $50, $62, $40, $3E, $4B, $62, $41, $4C, $F1, $41, $46, $43, $43, $42, $4F, $42, $4B, $51, $62, $51, $45, $46, $4B, $44, $50, $F1, $3E, $51, $62, $51, $45, $42, $62, $50, $3E, $4A, $42, $62, $51, $46, $4A, $42, $F0
MonsterDesc_042_BattleRex:  ; $5AFA "Attacks by/swinging its/powerful giant ax"
    db $24, $51, $51, $3E, $40, $48, $50, $62, $3F, $56, $F1, $50, $54, $46, $4B, $44, $46, $4B, $44, $62, $46, $51, $50, $F1, $4D, $4C, $54, $42, $4F, $43, $52, $49, $62, $44, $46, $3E, $4B, $51, $62, $3E, $55, $F0
MonsterDesc_043_SkyDragon:  ; $5B24 "Floats freely in/midair with its/magical powers"
    db $29, $49, $4C, $3E, $51, $50, $62, $43, $4F, $42, $42, $49, $56, $62, $46, $4B, $F1, $4A, $46, $41, $3E, $46, $4F, $62, $54, $46, $51, $45, $62, $46, $51, $50, $F1, $4A, $3E, $44, $46, $40, $3E, $49, $62, $4D, $4C, $54, $42, $4F, $50, $F0
MonsterDesc_044_Divinegon:  ; $5B54 "If you defeat it,/your wish will/be granted"
    db $2C, $43, $62, $56, $4C, $52, $62, $41, $42, $43, $42, $3E, $51, $62, $46, $51, $5E, $F1, $56, $4C, $52, $4F, $62, $54, $46, $50, $45, $62, $54, $46, $49, $49, $F1, $3F, $42, $62, $44, $4F, $3E, $4B, $51, $42, $41, $F0
MonsterDesc_045_Tonguella:  ; $5B80 "Moves slowly/but its long/tongue is deadly"
    db $30, $4C, $53, $42, $50, $62, $50, $49, $4C, $54, $49, $56, $F1, $3F, $52, $51, $62, $46, $51, $50, $62, $49, $4C, $4B, $44, $F1, $51, $4C, $4B, $44, $52, $42, $62, $46, $50, $62, $41, $42, $3E, $41, $49, $56, $F0
MonsterDesc_046_Almiraj:  ; $5BAB "When cornered,it/charges with its/sharp horns"
    db $3A, $45, $42, $4B, $62, $40, $4C, $4F, $4B, $42, $4F, $42, $41, $5E, $46, $51, $F1, $40, $45, $3E, $4F, $44, $42, $50, $62, $54, $46, $51, $45, $62, $46, $51, $50, $F1, $50, $45, $3E, $4F, $4D, $62, $45, $4C, $4F, $4B, $50, $F0
MonsterDesc_047_CatFly:  ; $5BD9 "Can see in the/dark and preys/at night"
    db $26, $3E, $4B, $62, $50, $42, $42, $62, $46, $4B, $62, $51, $45, $42, $F1, $41, $3E, $4F, $48, $62, $3E, $4B, $41, $62, $4D, $4F, $42, $56, $50, $F1, $3E, $51, $62, $4B, $46, $44, $45, $51, $F0
MonsterDesc_048_PillowRat:  ; $5C00 "Soft & fluffy/fur covers its/body"
    db $36, $4C, $43, $51, $62, $B6, $62, $43, $49, $52, $43, $43, $56, $F1, $43, $52, $4F, $62, $40, $4C, $53, $42, $4F, $50, $62, $46, $51, $50, $F1, $3F, $4C, $41, $56, $F0
MonsterDesc_049_Saccer:  ; $5C22 "Lives in a/sack made out/of branches"
    db $2F, $46, $53, $42, $50, $62, $46, $4B, $62, $3E, $F1, $50, $3E, $40, $48, $62, $4A, $3E, $41, $42, $62, $4C, $52, $51, $F1, $4C, $43, $62, $3F, $4F, $3E, $4B, $40, $45, $42, $50, $F0
MonsterDesc_050_GulpBeast:  ; $5C47 "It devours its/prey in one/big gulp"
    db $2C, $51, $62, $41, $42, $53, $4C, $52, $4F, $50, $62, $46, $51, $50, $F1, $4D, $4F, $42, $56, $62, $46, $4B, $62, $4C, $4B, $42, $F1, $3F, $46, $44, $62, $44, $52, $49, $4D, $F0
MonsterDesc_051_Skullroo:  ; $5C6B "Attacks by/throwing skulls/at its enemies"
    db $24, $51, $51, $3E, $40, $48, $50, $62, $3F, $56, $F1, $51, $45, $4F, $4C, $54, $46, $4B, $44, $62, $50, $48, $52, $49, $49, $50, $F1, $3E, $51, $62, $46, $51, $50, $62, $42, $4B, $42, $4A, $46, $42, $50, $F0
MonsterDesc_052_WindBeast:  ; $5C95 "Creates tornadoes/with its legs to/defend itself"
    db $26, $4F, $42, $3E, $51, $42, $50, $62, $51, $4C, $4F, $4B, $3E, $41, $4C, $42, $50, $F1, $54, $46, $51, $45, $62, $46, $51, $50, $62, $49, $42, $44, $50, $62, $51, $4C, $F1, $41, $42, $43, $42, $4B, $41, $62, $46, $51, $50, $42, $49, $43, $F0
MonsterDesc_053_Anteater:  ; $5CC6 "Uses its tongue to/attack & snare/its prey"
    db $38, $50, $42, $50, $62, $46, $51, $50, $62, $51, $4C, $4B, $44, $52, $42, $62, $51, $4C, $F1, $3E, $51, $51, $3E, $40, $48, $62, $B6, $62, $50, $4B, $3E, $4F, $42, $F1, $46, $51, $50, $62, $4D, $4F, $42, $56, $F0
MonsterDesc_054_SuperTen:  ; $5CF1 "It likes to show/off its dance/moves"
    db $2C, $51, $62, $49, $46, $48, $42, $50, $62, $51, $4C, $62, $50, $45, $4C, $54, $F1, $4C, $43, $43, $62, $46, $51, $50, $62, $41, $3E, $4B, $40, $42, $F1, $4A, $4C, $53, $42, $50, $F0
MonsterDesc_055_IronTurt:  ; $5D16 "Its spiked shell/makes its body/slam attack deadly"
    db $2C, $51, $50, $62, $50, $4D, $46, $48, $42, $41, $62, $50, $45, $42, $49, $49, $F1, $4A, $3E, $48, $42, $50, $62, $46, $51, $50, $62, $3F, $4C, $41, $56, $F1, $50, $49, $3E, $4A, $62, $3E, $51, $51, $3E, $40, $48, $62, $41, $42, $3E, $41, $49, $56, $F0
MonsterDesc_056_Mommonja:  ; $5D49 "It follows you/like a dog"
    db $2C, $51, $62, $43, $4C, $49, $49, $4C, $54, $50, $62, $56, $4C, $52, $F1, $49, $46, $48, $42, $62, $3E, $62, $41, $4C, $44, $F0
MonsterDesc_057_HammerMan:  ; $5D63 "It has a hammer/bigger than itself"
    db $2C, $51, $62, $45, $3E, $50, $62, $3E, $62, $45, $3E, $4A, $4A, $42, $4F, $F1, $3F, $46, $44, $44, $42, $4F, $62, $51, $45, $3E, $4B, $62, $46, $51, $50, $42, $49, $43, $F0
MonsterDesc_058_Grizzly:  ; $5D86 "Uses its strong/arms to squeeze/its prey"
    db $38, $50, $42, $50, $62, $46, $51, $50, $62, $50, $51, $4F, $4C, $4B, $44, $F1, $3E, $4F, $4A, $50, $62, $51, $4C, $62, $50, $4E, $52, $42, $42, $57, $42, $F1, $46, $51, $50, $62, $4D, $4F, $42, $56, $F0
MonsterDesc_059_Yeti:  ; $5DAF "Its body is/covered with a/thick fur"
    db $2C, $51, $50, $62, $3F, $4C, $41, $56, $62, $46, $50, $F1, $40, $4C, $53, $42, $4F, $42, $41, $62, $54, $46, $51, $45, $62, $3E, $F1, $51, $45, $46, $40, $48, $62, $43, $52, $4F, $F0
MonsterDesc_060_MadGopher:  ; $5DD4 "It can dig very/deep holes with/its shovel"
    db $2C, $51, $62, $40, $3E, $4B, $62, $41, $46, $44, $62, $53, $42, $4F, $56, $F1, $41, $42, $42, $4D, $62, $45, $4C, $49, $42, $50, $62, $54, $46, $51, $45, $F1, $46, $51, $50, $62, $50, $45, $4C, $53, $42, $49, $F0
MonsterDesc_061_FairyRat:  ; $5DFF "Its ears act as/wings allowing/it to fly"
    db $2C, $51, $50, $62, $42, $3E, $4F, $50, $62, $3E, $40, $51, $62, $3E, $50, $F1, $54, $46, $4B, $44, $50, $62, $3E, $49, $49, $4C, $54, $46, $4B, $44, $F1, $46, $51, $62, $51, $4C, $62, $43, $49, $56, $F0
MonsterDesc_062_Unicorn:  ; $5E28 "Its horn is used/to make medicines"
    db $2C, $51, $50, $62, $45, $4C, $4F, $4B, $62, $46, $50, $62, $52, $50, $42, $41, $F1, $51, $4C, $62, $4A, $3E, $48, $42, $62, $4A, $42, $41, $46, $40, $46, $4B, $42, $50, $F0
MonsterDesc_063_Goategon:  ; $5E4B "Charges enemies/with its sharp &/twisted horns"
    db $26, $45, $3E, $4F, $44, $42, $50, $62, $42, $4B, $42, $4A, $46, $42, $50, $F1, $54, $46, $51, $45, $62, $46, $51, $50, $62, $50, $45, $3E, $4F, $4D, $62, $B6, $F1, $51, $54, $46, $50, $51, $42, $41, $62, $45, $4C, $4F, $4B, $50, $F0
MonsterDesc_064_WildApe:  ; $5E7A "Lives in groups/with one dominant/male boss"
    db $2F, $46, $53, $42, $50, $62, $46, $4B, $62, $44, $4F, $4C, $52, $4D, $50, $F1, $54, $46, $51, $45, $62, $4C, $4B, $42, $62, $41, $4C, $4A, $46, $4B, $3E, $4B, $51, $F1, $4A, $3E, $49, $42, $62, $3F, $4C, $50, $50, $F0
MonsterDesc_065_Trumpeter:  ; $5EA6 "Its tusks are used/to create craft/work"
    db $2C, $51, $50, $62, $51, $52, $50, $48, $50, $62, $3E, $4F, $42, $62, $52, $50, $42, $41, $F1, $51, $4C, $62, $40, $4F, $42, $3E, $51, $42, $62, $40, $4F, $3E, $43, $51, $F1, $54, $4C, $4F, $48, $F0
MonsterDesc_066_KingLeo:  ; $5ECE "Uses its 4 hands &/4 arms skillfully/in combat"
    db $38, $50, $42, $50, $62, $46, $51, $50, $62, $04, $62, $45, $3E, $4B, $41, $50, $62, $B6, $F1, $04, $62, $3E, $4F, $4A, $50, $62, $50, $48, $46, $49, $49, $43, $52, $49, $49, $56, $F1, $46, $4B, $62, $40, $4C, $4A, $3F, $3E, $51, $F0
MonsterDesc_067_DarkHorn:  ; $5EFD "Its pelt commands/a high price"
    db $2C, $51, $50, $62, $4D, $42, $49, $51, $62, $40, $4C, $4A, $4A, $3E, $4B, $41, $50, $F1, $3E, $62, $45, $46, $44, $45, $62, $4D, $4F, $46, $40, $42, $F0
MonsterDesc_068_MadCat:  ; $5F1C "Moves very swiftly/to catch its prey"
    db $30, $4C, $53, $42, $50, $62, $53, $42, $4F, $56, $62, $50, $54, $46, $43, $51, $49, $56, $F1, $51, $4C, $62, $40, $3E, $51, $40, $45, $62, $46, $51, $50, $62, $4D, $4F, $42, $56, $F0
MonsterDesc_069_BigEye:  ; $5F41 "Looks up at the/sky & dozes/off all day"
    db $2F, $4C, $4C, $48, $50, $62, $52, $4D, $62, $3E, $51, $62, $51, $45, $42, $F1, $50, $48, $56, $62, $B6, $62, $41, $4C, $57, $42, $50, $F1, $4C, $43, $43, $62, $3E, $49, $49, $62, $41, $3E, $56, $F0
MonsterDesc_070_Picky:  ; $5F69 "It's flightless/but it can run/quickly"
    db $2C, $51, $68, $62, $43, $49, $46, $44, $45, $51, $49, $42, $50, $50, $F1, $3F, $52, $51, $62, $46, $51, $62, $40, $3E, $4B, $62, $4F, $52, $4B, $F1, $4E, $52, $46, $40, $48, $49, $56, $F0
MonsterDesc_071_Wyvern:  ; $5F8F "It has an eagle's/head & a body/of a serpent"
    db $2C, $51, $62, $45, $3E, $50, $62, $3E, $4B, $62, $42, $3E, $44, $49, $42, $68, $F1, $45, $42, $3E, $41, $62, $B6, $62, $3E, $62, $3F, $4C, $41, $56, $F1, $4C, $43, $62, $3E, $62, $50, $42, $4F, $4D, $42, $4B, $51, $F0
MonsterDesc_072_BullBird:  ; $5FBB "Sleeps right after/it makes a kill"
    db $36, $49, $42, $42, $4D, $50, $62, $4F, $46, $44, $45, $51, $62, $3E, $43, $51, $42, $4F, $F1, $46, $51, $62, $4A, $3E, $48, $42, $50, $62, $3E, $62, $48, $46, $49, $49, $F0
MonsterDesc_073_Florajay:  ; $5FDE "Its flower like/face lures bugs/to their doom"
    db $2C, $51, $50, $62, $43, $49, $4C, $54, $42, $4F, $62, $49, $46, $48, $42, $F1, $43, $3E, $40, $42, $62, $49, $52, $4F, $42, $50, $62, $3F, $52, $44, $50, $F1, $51, $4C, $62, $51, $45, $42, $46, $4F, $62, $41, $4C, $4C, $4A, $F0
MonsterDesc_074_DuckKite:  ; $600C "Spreads its/wings to make/itself look bigger"
    db $36, $4D, $4F, $42, $3E, $41, $50, $62, $46, $51, $50, $F1, $54, $46, $4B, $44, $50, $62, $51, $4C, $62, $4A, $3E, $48, $42, $F1, $46, $51, $50, $42, $49, $43, $62, $49, $4C, $4C, $48, $62, $3F, $46, $44, $44, $42, $4F, $F0
MonsterDesc_075_MadPecker:  ; $6039 "Rips flesh from/its prey with its/strong beak"
    db $35, $46, $4D, $50, $62, $43, $49, $42, $50, $45, $62, $43, $4F, $4C, $4A, $F1, $46, $51, $50, $62, $4D, $4F, $42, $56, $62, $54, $46, $51, $45, $62, $46, $51, $50, $F1, $50, $51, $4F, $4C, $4B, $44, $62, $3F, $42, $3E, $48, $F0
MonsterDesc_076_MadRaven:  ; $6067 "Attacks by/dropping skulls/from the air"
    db $24, $51, $51, $3E, $40, $48, $50, $62, $3F, $56, $F1, $41, $4F, $4C, $4D, $4D, $46, $4B, $44, $62, $50, $48, $52, $49, $49, $50, $F1, $43, $4F, $4C, $4A, $62, $51, $45, $42, $62, $3E, $46, $4F, $F0
MonsterDesc_077_MistyWing:  ; $608F "Its mist like body/glows pinkish in/the dark"
    db $2C, $51, $50, $62, $4A, $46, $50, $51, $62, $49, $46, $48, $42, $62, $3F, $4C, $41, $56, $F1, $44, $49, $4C, $54, $50, $62, $4D, $46, $4B, $48, $46, $50, $45, $62, $46, $4B, $F1, $51, $45, $42, $62, $41, $3E, $4F, $48, $F0
MonsterDesc_078_Dracky:  ; $60BC "Prefers darkness/and sucks blood/with its fangs"
    db $33, $4F, $42, $43, $42, $4F, $50, $62, $41, $3E, $4F, $48, $4B, $42, $50, $50, $F1, $3E, $4B, $41, $62, $50, $52, $40, $48, $50, $62, $3F, $49, $4C, $4C, $41, $F1, $54, $46, $51, $45, $62, $46, $51, $50, $62, $43, $3E, $4B, $44, $50, $F0
MonsterDesc_079_BigRoost:  ; $60EC "Its firm flesh/is good eating"
    db $2C, $51, $50, $62, $43, $46, $4F, $4A, $62, $43, $49, $42, $50, $45, $F1, $46, $50, $62, $44, $4C, $4C, $41, $62, $42, $3E, $51, $46, $4B, $44, $F0
MonsterDesc_080_StubBird:  ; $610A "A very stubborn/bird"
    db $24, $62, $53, $42, $4F, $56, $62, $50, $51, $52, $3F, $3F, $4C, $4F, $4B, $F1, $3F, $46, $4F, $41, $F0
MonsterDesc_081_LandOwl:  ; $611F "A flightless owl/with strong talons/& sharp claws"
    db $24, $62, $43, $49, $46, $44, $45, $51, $49, $42, $50, $50, $62, $4C, $54, $49, $F1, $54, $46, $51, $45, $62, $50, $51, $4F, $4C, $4B, $44, $62, $51, $3E, $49, $4C, $4B, $50, $F1, $B6, $62, $50, $45, $3E, $4F, $4D, $62, $40, $49, $3E, $54, $50, $F0
MonsterDesc_082_MadGoose:  ; $6151 "A migratory/bird that can be/very violent"
    db $24, $62, $4A, $46, $44, $4F, $3E, $51, $4C, $4F, $56, $F1, $3F, $46, $4F, $41, $62, $51, $45, $3E, $51, $62, $40, $3E, $4B, $62, $3F, $42, $F1, $53, $42, $4F, $56, $62, $53, $46, $4C, $49, $42, $4B, $51, $F0
MonsterDesc_083_MadCondor:  ; $617B "It has big wings,/deadly sharp claws/& a powerful beak"
    db $2C, $51, $62, $45, $3E, $50, $62, $3F, $46, $44, $62, $54, $46, $4B, $44, $50, $5E, $F1, $41, $42, $3E, $41, $49, $56, $62, $50, $45, $3E, $4F, $4D, $62, $40, $49, $3E, $54, $50, $F1, $B6, $62, $3E, $62, $4D, $4C, $54, $42, $4F, $43, $52, $49, $62, $3F, $42, $3E, $48, $F0
MonsterDesc_084_Blizzardy:  ; $61B2 "Breathes out/freezing air to/defeat its prey"
    db $25, $4F, $42, $3E, $51, $45, $42, $50, $62, $4C, $52, $51, $F1, $43, $4F, $42, $42, $57, $46, $4B, $44, $62, $3E, $46, $4F, $62, $51, $4C, $F1, $41, $42, $43, $42, $3E, $51, $62, $46, $51, $50, $62, $4D, $4F, $42, $56, $F0
MonsterDesc_085_Phoenix:  ; $61DF "Roasts its prey/with its fiery/breath"
    db $35, $4C, $3E, $50, $51, $50, $62, $46, $51, $50, $62, $4D, $4F, $42, $56, $F1, $54, $46, $51, $45, $62, $46, $51, $50, $62, $43, $46, $42, $4F, $56, $F1, $3F, $4F, $42, $3E, $51, $45, $F0
MonsterDesc_086_ZapBird:  ; $6205 "Attacks with the/thundercloud that/covers its body"
    db $24, $51, $51, $3E, $40, $48, $50, $62, $54, $46, $51, $45, $62, $51, $45, $42, $F1, $51, $45, $52, $4B, $41, $42, $4F, $40, $49, $4C, $52, $41, $62, $51, $45, $3E, $51, $F1, $40, $4C, $53, $42, $4F, $50, $62, $46, $51, $50, $62, $3F, $4C, $41, $56, $F0
MonsterDesc_087_WhipBird:  ; $6238 "Attacks with its/whip-like legs &/knife-like claws"
    db $24, $51, $51, $3E, $40, $48, $50, $62, $54, $46, $51, $45, $62, $46, $51, $50, $F1, $54, $45, $46, $4D, $9C, $49, $46, $48, $42, $62, $49, $42, $44, $50, $62, $B6, $F1, $48, $4B, $46, $43, $42, $9C, $49, $46, $48, $42, $62, $40, $49, $3E, $54, $50, $F0
MonsterDesc_088_FunkyBird:  ; $626B "Likes to dance/& sing"
    db $2F, $46, $48, $42, $50, $62, $51, $4C, $62, $41, $3E, $4B, $40, $42, $F1, $B6, $62, $50, $46, $4B, $44, $F0
MonsterDesc_089_RainHawk:  ; $6281 "It has 4 strong/legs & a pair of/powerful wings"
    db $2C, $51, $62, $45, $3E, $50, $62, $04, $62, $50, $51, $4F, $4C, $4B, $44, $F1, $49, $42, $44, $50, $62, $B6, $62, $3E, $62, $4D, $3E, $46, $4F, $62, $4C, $43, $F1, $4D, $4C, $54, $42, $4F, $43, $52, $49, $62, $54, $46, $4B, $44, $50, $F0
MonsterDesc_090_MadPlant:  ; $62B1 "Secretes sweet/sap to attract/bugs"
    db $36, $42, $40, $4F, $42, $51, $42, $50, $62, $50, $54, $42, $42, $51, $F1, $50, $3E, $4D, $62, $51, $4C, $62, $3E, $51, $51, $4F, $3E, $40, $51, $F1, $3F, $52, $44, $50, $F0
MonsterDesc_091_FireWeed:  ; $62D4 "Its flame breath/is its deadly/weapon"
    db $2C, $51, $50, $62, $43, $49, $3E, $4A, $42, $62, $3F, $4F, $42, $3E, $51, $45, $F1, $46, $50, $62, $46, $51, $50, $62, $41, $42, $3E, $41, $49, $56, $F1, $54, $42, $3E, $4D, $4C, $4B, $F0
MonsterDesc_092_FloraMan:  ; $62FA "Can live several/hundred years/and is very wise"
    db $26, $3E, $4B, $62, $49, $46, $53, $42, $62, $50, $42, $53, $42, $4F, $3E, $49, $F1, $45, $52, $4B, $41, $4F, $42, $41, $62, $56, $42, $3E, $4F, $50, $F1, $3E, $4B, $41, $62, $46, $50, $62, $53, $42, $4F, $56, $62, $54, $46, $50, $42, $F0
MonsterDesc_093_WingTree:  ; $632A "Stores gas inside/its body to/float in the air"
    db $36, $51, $4C, $4F, $42, $50, $62, $44, $3E, $50, $62, $46, $4B, $50, $46, $41, $42, $F1, $46, $51, $50, $62, $3F, $4C, $41, $56, $62, $51, $4C, $F1, $43, $49, $4C, $3E, $51, $62, $46, $4B, $62, $51, $45, $42, $62, $3E, $46, $4F, $F0
MonsterDesc_094_CactiBall:  ; $6359 "Stores water/inside the body to/survive in deserts"
    db $36, $51, $4C, $4F, $42, $50, $62, $54, $3E, $51, $42, $4F, $F1, $46, $4B, $50, $46, $41, $42, $62, $51, $45, $42, $62, $3F, $4C, $41, $56, $62, $51, $4C, $F1, $50, $52, $4F, $53, $46, $53, $42, $62, $46, $4B, $62, $41, $42, $50, $42, $4F, $51, $50, $F0
MonsterDesc_095_Gulpple:  ; $638C "Gulps up monsters/to stock up on its/evil powers"
    db $2A, $52, $49, $4D, $50, $62, $52, $4D, $62, $4A, $4C, $4B, $50, $51, $42, $4F, $50, $F1, $51, $4C, $62, $50, $51, $4C, $40, $48, $62, $52, $4D, $62, $4C, $4B, $62, $46, $51, $50, $F1, $42, $53, $46, $49, $62, $4D, $4C, $54, $42, $4F, $50, $F0
MonsterDesc_096_Toadstool:  ; $63BD "Plants its spores/on its prey to/multiply"
    db $33, $49, $3E, $4B, $51, $50, $62, $46, $51, $50, $62, $50, $4D, $4C, $4F, $42, $50, $F1, $4C, $4B, $62, $46, $51, $50, $62, $4D, $4F, $42, $56, $62, $51, $4C, $F1, $4A, $52, $49, $51, $46, $4D, $49, $56, $F0
MonsterDesc_097_AmberWeed:  ; $63E7 "Secretes sap that/hardens its body"
    db $36, $42, $40, $4F, $42, $51, $42, $50, $62, $50, $3E, $4D, $62, $51, $45, $3E, $51, $F1, $45, $3E, $4F, $41, $42, $4B, $50, $62, $46, $51, $50, $62, $3F, $4C, $41, $56, $F0
MonsterDesc_098_Stubsuck:  ; $640A "Uses its roots/to suck out the/preys body fluid"
    db $38, $50, $42, $50, $62, $46, $51, $50, $62, $4F, $4C, $4C, $51, $50, $F1, $51, $4C, $62, $50, $52, $40, $48, $62, $4C, $52, $51, $62, $51, $45, $42, $F1, $4D, $4F, $42, $56, $50, $62, $3F, $4C, $41, $56, $62, $43, $49, $52, $46, $41, $F0
MonsterDesc_099_Oniono:  ; $643A "Grows out its/roots when its/ready to breed"
    db $2A, $4F, $4C, $54, $50, $62, $4C, $52, $51, $62, $46, $51, $50, $F1, $4F, $4C, $4C, $51, $50, $62, $54, $45, $42, $4B, $62, $46, $51, $50, $F1, $4F, $42, $3E, $41, $56, $62, $51, $4C, $62, $3F, $4F, $42, $42, $41, $F0
MonsterDesc_100_DanceVegi:  ; $6466 "Its bad balance/forces it to walk/like it's dancing"
    db $2C, $51, $50, $62, $3F, $3E, $41, $62, $3F, $3E, $49, $3E, $4B, $40, $42, $F1, $43, $4C, $4F, $40, $42, $50, $62, $46, $51, $62, $51, $4C, $62, $54, $3E, $49, $48, $F1, $49, $46, $48, $42, $62, $46, $51, $68, $62, $41, $3E, $4B, $40, $46, $4B, $44, $F0
MonsterDesc_101_TreeBoy:  ; $6499 "A spirit that/lives in a very/old tree"
    db $24, $62, $50, $4D, $46, $4F, $46, $51, $62, $51, $45, $3E, $51, $F1, $49, $46, $53, $42, $50, $62, $46, $4B, $62, $3E, $62, $53, $42, $4F, $56, $F1, $4C, $49, $41, $62, $51, $4F, $42, $42, $F0
MonsterDesc_102_FaceTree:  ; $64C0 "Its roots suck/evil power from/the ground"
    db $2C, $51, $50, $62, $4F, $4C, $4C, $51, $50, $62, $50, $52, $40, $48, $F1, $42, $53, $46, $49, $62, $4D, $4C, $54, $42, $4F, $62, $43, $4F, $4C, $4A, $F1, $51, $45, $42, $62, $44, $4F, $4C, $52, $4B, $41, $F0
MonsterDesc_103_HerbMan:  ; $64EA "Its roots can be/used to make/a cure medicine"
    db $2C, $51, $50, $62, $4F, $4C, $4C, $51, $50, $62, $40, $3E, $4B, $62, $3F, $42, $F1, $52, $50, $42, $41, $62, $51, $4C, $62, $4A, $3E, $48, $42, $F1, $3E, $62, $40, $52, $4F, $42, $62, $4A, $42, $41, $46, $40, $46, $4B, $42, $F0
MonsterDesc_104_BeanMan:  ; $6518 "Travels to find/a place to plant/its seeds"
    db $37, $4F, $3E, $53, $42, $49, $50, $62, $51, $4C, $62, $43, $46, $4B, $41, $F1, $3E, $62, $4D, $49, $3E, $40, $42, $62, $51, $4C, $62, $4D, $49, $3E, $4B, $51, $F1, $46, $51, $50, $62, $50, $42, $42, $41, $50, $F0
MonsterDesc_105_EvilSeed:  ; $6543 "Clings on its/host with its/tentacles"
    db $26, $49, $46, $4B, $44, $50, $62, $4C, $4B, $62, $46, $51, $50, $F1, $45, $4C, $50, $51, $62, $54, $46, $51, $45, $62, $46, $51, $50, $F1, $51, $42, $4B, $51, $3E, $40, $49, $42, $50, $F0
MonsterDesc_106_ManEater:  ; $6569 "Dissolves its/prey with its/digestive acid"
    db $27, $46, $50, $50, $4C, $49, $53, $42, $50, $62, $46, $51, $50, $F1, $4D, $4F, $42, $56, $62, $54, $46, $51, $45, $62, $46, $51, $50, $F1, $41, $46, $44, $42, $50, $51, $46, $53, $42, $62, $3E, $40, $46, $41, $F0
MonsterDesc_107_Snapper:  ; $6594 "The 3 buds sink/their teeth into/its prey"
    db $37, $45, $42, $62, $03, $62, $3F, $52, $41, $50, $62, $50, $46, $4B, $48, $F1, $51, $45, $42, $46, $4F, $62, $51, $42, $42, $51, $45, $62, $46, $4B, $51, $4C, $F1, $46, $51, $50, $62, $4D, $4F, $42, $56, $F0
MonsterDesc_108_Rosevine:  ; $65BE "Squeezes its/prey with its/thorny vines"
    db $36, $4E, $52, $42, $42, $57, $42, $50, $62, $46, $51, $50, $F1, $4D, $4F, $42, $56, $62, $54, $46, $51, $45, $62, $46, $51, $50, $F1, $51, $45, $4C, $4F, $4B, $56, $62, $53, $46, $4B, $42, $50, $F0
MonsterDesc_109_Watabou:  ; $65E6 "A mischievous/mystical creature"
    db $24, $62, $4A, $46, $50, $40, $45, $46, $42, $53, $4C, $52, $50, $F1, $4A, $56, $50, $51, $46, $40, $3E, $49, $62, $40, $4F, $42, $3E, $51, $52, $4F, $42, $F0
MonsterDesc_110_GiantSlug:  ; $6606 "Its mucus contains/digestive enzymes"
    db $2C, $51, $50, $62, $4A, $52, $40, $52, $50, $62, $40, $4C, $4B, $51, $3E, $46, $4B, $50, $F1, $41, $46, $44, $42, $50, $51, $46, $53, $42, $62, $42, $4B, $57, $56, $4A, $42, $50, $F0
MonsterDesc_111_Catapila:  ; $662B "This caterpillar/does not grow to/become a moth"
    db $37, $45, $46, $50, $62, $40, $3E, $51, $42, $4F, $4D, $46, $49, $49, $3E, $4F, $F1, $41, $4C, $42, $50, $62, $4B, $4C, $51, $62, $44, $4F, $4C, $54, $62, $51, $4C, $F1, $3F, $42, $40, $4C, $4A, $42, $62, $3E, $62, $4A, $4C, $51, $45, $F0
MonsterDesc_112_Gophecada:  ; $665B "Since it lives/underground, it/hates light"
    db $36, $46, $4B, $40, $42, $62, $46, $51, $62, $49, $46, $53, $42, $50, $F1, $52, $4B, $41, $42, $4F, $44, $4F, $4C, $52, $4B, $41, $5E, $62, $46, $51, $F1, $45, $3E, $51, $42, $50, $62, $49, $46, $44, $45, $51, $F0
MonsterDesc_113_Butterfly:  ; $6686 "Powder on its/wings have hallu-/cinogenic effect"
    db $33, $4C, $54, $41, $42, $4F, $62, $4C, $4B, $62, $46, $51, $50, $F1, $54, $46, $4B, $44, $50, $62, $45, $3E, $53, $42, $62, $45, $3E, $49, $49, $52, $9C, $F1, $40, $46, $4B, $4C, $44, $42, $4B, $46, $40, $62, $42, $43, $43, $42, $40, $51, $F0
MonsterDesc_114_WeedBug:  ; $66B7 "Its weed-top sucks/up energy & emits/evil power"
    db $2C, $51, $50, $62, $54, $42, $42, $41, $9C, $51, $4C, $4D, $62, $50, $52, $40, $48, $50, $F1, $52, $4D, $62, $42, $4B, $42, $4F, $44, $56, $62, $B6, $62, $42, $4A, $46, $51, $50, $F1, $42, $53, $46, $49, $62, $4D, $4C, $54, $42, $4F, $F0
MonsterDesc_115_GiantWorm:  ; $66E7 "Finds its prey/with its acute/sense of smell"
    db $29, $46, $4B, $41, $50, $62, $46, $51, $50, $62, $4D, $4F, $42, $56, $F1, $54, $46, $51, $45, $62, $46, $51, $50, $62, $3E, $40, $52, $51, $42, $F1, $50, $42, $4B, $50, $42, $62, $4C, $43, $62, $50, $4A, $42, $49, $49, $F0
MonsterDesc_116_Lipsy:  ; $6714 "Paralyzes its prey/with its deadly/kiss"
    db $33, $3E, $4F, $3E, $49, $56, $57, $42, $50, $62, $46, $51, $50, $62, $4D, $4F, $42, $56, $F1, $54, $46, $51, $45, $62, $46, $51, $50, $62, $41, $42, $3E, $41, $49, $56, $F1, $48, $46, $50, $50, $F0
MonsterDesc_117_StagBug:  ; $673C "Repels attacks/with its hard/shell"
    db $35, $42, $4D, $42, $49, $50, $62, $3E, $51, $51, $3E, $40, $48, $50, $F1, $54, $46, $51, $45, $62, $46, $51, $50, $62, $45, $3E, $4F, $41, $F1, $50, $45, $42, $49, $49, $F0
MonsterDesc_118_ArmyAnt:  ; $675F "Its body is small,/but its jaw is/powerful"
    db $2C, $51, $50, $62, $3F, $4C, $41, $56, $62, $46, $50, $62, $50, $4A, $3E, $49, $49, $5E, $F1, $3F, $52, $51, $62, $46, $51, $50, $62, $47, $3E, $54, $62, $46, $50, $F1, $4D, $4C, $54, $42, $4F, $43, $52, $49, $F0
MonsterDesc_119_GoHopper:  ; $678A "Makes a weird/sound when it/flies"
    db $30, $3E, $48, $42, $50, $62, $3E, $62, $54, $42, $46, $4F, $41, $F1, $50, $4C, $52, $4B, $41, $62, $54, $45, $42, $4B, $62, $46, $51, $F1, $43, $49, $46, $42, $50, $F0
MonsterDesc_120_TailEater:  ; $67AC "Sucks on its/prey with its/tail-like mouth"
    db $36, $52, $40, $48, $50, $62, $4C, $4B, $62, $46, $51, $50, $F1, $4D, $4F, $42, $56, $62, $54, $46, $51, $45, $62, $46, $51, $50, $F1, $51, $3E, $46, $49, $9C, $49, $46, $48, $42, $62, $4A, $4C, $52, $51, $45, $F0
MonsterDesc_121_ArmorPede:  ; $67D7 "A shell protects/its back but not/its belly"
    db $24, $62, $50, $45, $42, $49, $49, $62, $4D, $4F, $4C, $51, $42, $40, $51, $50, $F1, $46, $51, $50, $62, $3F, $3E, $40, $48, $62, $3F, $52, $51, $62, $4B, $4C, $51, $F1, $46, $51, $50, $62, $3F, $42, $49, $49, $56, $F0
MonsterDesc_122_Eyeder:  ; $6803 "Each tentacle/has a specific/function"
    db $28, $3E, $40, $45, $62, $51, $42, $4B, $51, $3E, $40, $49, $42, $F1, $45, $3E, $50, $62, $3E, $62, $50, $4D, $42, $40, $46, $43, $46, $40, $F1, $43, $52, $4B, $40, $51, $46, $4C, $4B, $F0
MonsterDesc_123_GiantMoth:  ; $6829 "Creates a violent/wind with its/huge wings"
    db $26, $4F, $42, $3E, $51, $42, $50, $62, $3E, $62, $53, $46, $4C, $49, $42, $4B, $51, $F1, $54, $46, $4B, $41, $62, $54, $46, $51, $45, $62, $46, $51, $50, $F1, $45, $52, $44, $42, $62, $54, $46, $4B, $44, $50, $F0
MonsterDesc_124_Droll:  ; $6854 "Protruding eyes/gives a large/field of vision"
    db $33, $4F, $4C, $51, $4F, $52, $41, $46, $4B, $44, $62, $42, $56, $42, $50, $F1, $44, $46, $53, $42, $50, $62, $3E, $62, $49, $3E, $4F, $44, $42, $F1, $43, $46, $42, $49, $41, $62, $4C, $43, $62, $53, $46, $50, $46, $4C, $4B, $F0
MonsterDesc_125_ArmyCrab:  ; $6882 "Attacks in a group/& cuts up its prey/with its claws"
    db $24, $51, $51, $3E, $40, $48, $50, $62, $46, $4B, $62, $3E, $62, $44, $4F, $4C, $52, $4D, $F1, $B6, $62, $40, $52, $51, $50, $62, $52, $4D, $62, $46, $51, $50, $62, $4D, $4F, $42, $56, $F1, $54, $46, $51, $45, $62, $46, $51, $50, $62, $40, $49, $3E, $54, $50, $F0
MonsterDesc_126_MadHornet:  ; $68B7 "Paralyzes its prey/with its sting"
    db $33, $3E, $4F, $3E, $49, $56, $57, $42, $50, $62, $46, $51, $50, $62, $4D, $4F, $42, $56, $F1, $54, $46, $51, $45, $62, $46, $51, $50, $62, $50, $51, $46, $4B, $44, $F0
MonsterDesc_127_HornBeet:  ; $68D9 "Charges its prey/with its big horn"
    db $26, $45, $3E, $4F, $44, $42, $50, $62, $46, $51, $50, $62, $4D, $4F, $42, $56, $F1, $54, $46, $51, $45, $62, $46, $51, $50, $62, $3F, $46, $44, $62, $45, $4C, $4F, $4B, $F0
MonsterDesc_128_Armorpion:  ; $68FC "Unprotected joints/are its weakness"
    db $38, $4B, $4D, $4F, $4C, $51, $42, $40, $51, $42, $41, $62, $47, $4C, $46, $4B, $51, $50, $F1, $3E, $4F, $42, $62, $46, $51, $50, $62, $54, $42, $3E, $48, $4B, $42, $50, $50, $F0
MonsterDesc_129_Digster:  ; $6920 "Digs caves to live/in a dark humid/home"
    db $27, $46, $44, $50, $62, $40, $3E, $53, $42, $50, $62, $51, $4C, $62, $49, $46, $53, $42, $F1, $46, $4B, $62, $3E, $62, $41, $3E, $4F, $48, $62, $45, $52, $4A, $46, $41, $F1, $45, $4C, $4A, $42, $F0
MonsterDesc_130_Pixy:  ; $6948 "Loves to play/pranks with its/magic spells"
    db $2F, $4C, $53, $42, $50, $62, $51, $4C, $62, $4D, $49, $3E, $56, $F1, $4D, $4F, $3E, $4B, $48, $50, $62, $54, $46, $51, $45, $62, $46, $51, $50, $F1, $4A, $3E, $44, $46, $40, $62, $50, $4D, $42, $49, $49, $50, $F0
MonsterDesc_131_ArcDemon:  ; $6973 "Too fat to fly/but its strength/is incredible"
    db $37, $4C, $4C, $62, $43, $3E, $51, $62, $51, $4C, $62, $43, $49, $56, $F1, $3F, $52, $51, $62, $46, $51, $50, $62, $50, $51, $4F, $42, $4B, $44, $51, $45, $F1, $46, $50, $62, $46, $4B, $40, $4F, $42, $41, $46, $3F, $49, $42, $F0
MonsterDesc_132_AgDevil:  ; $69A1 "Very quick witted/& cunning"
    db $39, $42, $4F, $56, $62, $4E, $52, $46, $40, $48, $62, $54, $46, $51, $51, $42, $41, $F1, $B6, $62, $40, $52, $4B, $4B, $46, $4B, $44, $F0
MonsterDesc_133_Demonite:  ; $69BD "Smart but, lacks/the power to cast/big spells"
    db $36, $4A, $3E, $4F, $51, $62, $3F, $52, $51, $5E, $62, $49, $3E, $40, $48, $50, $F1, $51, $45, $42, $62, $4D, $4C, $54, $42, $4F, $62, $51, $4C, $62, $40, $3E, $50, $51, $F1, $3F, $46, $44, $62, $50, $4D, $42, $49, $49, $50, $F0
MonsterDesc_134_DarkEye:  ; $69EB "Catches its prey/with its tentacles"
    db $26, $3E, $51, $40, $45, $42, $50, $62, $46, $51, $50, $62, $4D, $4F, $42, $56, $F1, $54, $46, $51, $45, $62, $46, $51, $50, $62, $51, $42, $4B, $51, $3E, $40, $49, $42, $50, $F0
MonsterDesc_135_EyeBall:  ; $6A0F "Hunts with its/large eye & fast/two legs"
    db $2B, $52, $4B, $51, $50, $62, $54, $46, $51, $45, $62, $46, $51, $50, $F1, $49, $3E, $4F, $44, $42, $62, $42, $56, $42, $62, $B6, $62, $43, $3E, $50, $51, $F1, $51, $54, $4C, $62, $49, $42, $44, $50, $F0
MonsterDesc_136_SkulRider:  ; $6A38 "Revives dead/beasts to use/as slaves"
    db $35, $42, $53, $46, $53, $42, $50, $62, $41, $42, $3E, $41, $F1, $3F, $42, $3E, $50, $51, $50, $62, $51, $4C, $62, $52, $50, $42, $F1, $3E, $50, $62, $50, $49, $3E, $53, $42, $50, $F0
MonsterDesc_137_EvilBeast:  ; $6A5D "Trained hard/to attain its/evil strength"
    db $37, $4F, $3E, $46, $4B, $42, $41, $62, $45, $3E, $4F, $41, $F1, $51, $4C, $62, $3E, $51, $51, $3E, $46, $4B, $62, $46, $51, $50, $F1, $42, $53, $46, $49, $62, $50, $51, $4F, $42, $4B, $44, $51, $45, $F0
MonsterDesc_138_1EyeClown:  ; $6A86 "Uses its wand to/cast evil spells"
    db $38, $50, $42, $50, $62, $46, $51, $50, $62, $54, $3E, $4B, $41, $62, $51, $4C, $F1, $40, $3E, $50, $51, $62, $42, $53, $46, $49, $62, $50, $4D, $42, $49, $49, $50, $F0
MonsterDesc_139_Gremlin:  ; $6AA8 "Mischievous &/likes to play/tricks with traps"
    db $30, $46, $50, $40, $45, $46, $42, $53, $4C, $52, $50, $62, $B6, $F1, $49, $46, $48, $42, $50, $62, $51, $4C, $62, $4D, $49, $3E, $56, $F1, $51, $4F, $46, $40, $48, $50, $62, $54, $46, $51, $45, $62, $51, $4F, $3E, $4D, $50, $F0
MonsterDesc_140_MedusaEye:  ; $6AD6 "A deadly ball of/snakes with an/eye in the center"
    db $24, $62, $41, $42, $3E, $41, $49, $56, $62, $3F, $3E, $49, $49, $62, $4C, $43, $F1, $50, $4B, $3E, $48, $42, $50, $62, $54, $46, $51, $45, $62, $3E, $4B, $F1, $42, $56, $42, $62, $46, $4B, $62, $51, $45, $42, $62, $40, $42, $4B, $51, $42, $4F, $F0
MonsterDesc_141_Lionex:  ; $6B08 "A natural born/evil fighter"
    db $24, $62, $4B, $3E, $51, $52, $4F, $3E, $49, $62, $3F, $4C, $4F, $4B, $F1, $42, $53, $46, $49, $62, $43, $46, $44, $45, $51, $42, $4F, $F0
MonsterDesc_142_GoatHorn:  ; $6B24 "A powerful monster/with the horns &/legs of a goat"
    db $24, $62, $4D, $4C, $54, $42, $4F, $43, $52, $49, $62, $4A, $4C, $4B, $50, $51, $42, $4F, $F1, $54, $46, $51, $45, $62, $51, $45, $42, $62, $45, $4C, $4F, $4B, $50, $62, $B6, $F1, $49, $42, $44, $50, $62, $4C, $43, $62, $3E, $62, $44, $4C, $3E, $51, $F0
MonsterDesc_143_Orc:  ; $6B57 "Its dense pelt/acts as natural/armor"
    db $2C, $51, $50, $62, $41, $42, $4B, $50, $42, $62, $4D, $42, $49, $51, $F1, $3E, $40, $51, $50, $62, $3E, $50, $62, $4B, $3E, $51, $52, $4F, $3E, $49, $F1, $3E, $4F, $4A, $4C, $4F, $F0
MonsterDesc_144_Ogre:  ; $6B7C "Its flail has a/metal ball that's/bigger than a man"
    db $2C, $51, $50, $62, $43, $49, $3E, $46, $49, $62, $45, $3E, $50, $62, $3E, $F1, $4A, $42, $51, $3E, $49, $62, $3F, $3E, $49, $49, $62, $51, $45, $3E, $51, $68, $F1, $3F, $46, $44, $44, $42, $4F, $62, $51, $45, $3E, $4B, $62, $3E, $62, $4A, $3E, $4B, $F0
MonsterDesc_145_GateGuard:  ; $6BAF "Uses a scythe/as tall as its own/towering height"
    db $38, $50, $42, $50, $62, $3E, $62, $50, $40, $56, $51, $45, $42, $F1, $3E, $50, $62, $51, $3E, $49, $49, $62, $3E, $50, $62, $46, $51, $50, $62, $4C, $54, $4B, $F1, $51, $4C, $54, $42, $4F, $46, $4B, $44, $62, $45, $42, $46, $44, $45, $51, $F0
MonsterDesc_146_ChopClown:  ; $6BE0 "Has achieved the/utmost limit of/swiftness"
    db $2B, $3E, $50, $62, $3E, $40, $45, $46, $42, $53, $42, $41, $62, $51, $45, $42, $F1, $52, $51, $4A, $4C, $50, $51, $62, $49, $46, $4A, $46, $51, $62, $4C, $43, $F1, $50, $54, $46, $43, $51, $4B, $42, $50, $50, $F0
MonsterDesc_147_Grendal:  ; $6C0B "Not too clever,/but uses its/weapons well"
    db $31, $4C, $51, $62, $51, $4C, $4C, $62, $40, $49, $42, $53, $42, $4F, $5E, $F1, $3F, $52, $51, $62, $52, $50, $42, $50, $62, $46, $51, $50, $F1, $54, $42, $3E, $4D, $4C, $4B, $50, $62, $54, $42, $49, $49, $F0
MonsterDesc_148_Akubar:  ; $6C35 "Combined evil/power with super-/human strength"
    db $26, $4C, $4A, $3F, $46, $4B, $42, $41, $62, $42, $53, $46, $49, $F1, $4D, $4C, $54, $42, $4F, $62, $54, $46, $51, $45, $62, $50, $52, $4D, $42, $4F, $9C, $F1, $45, $52, $4A, $3E, $4B, $62, $50, $51, $4F, $42, $4B, $44, $51, $45, $F0
MonsterDesc_149_MadKnight:  ; $6C64 "Covered with/armor that is/never removed"
    db $26, $4C, $53, $42, $4F, $42, $41, $62, $54, $46, $51, $45, $F1, $3E, $4F, $4A, $4C, $4F, $62, $51, $45, $3E, $51, $62, $46, $50, $F1, $4B, $42, $53, $42, $4F, $62, $4F, $42, $4A, $4C, $53, $42, $41, $F0
MonsterDesc_150_Gigantes:  ; $6C8D "The biggest in the/devil family, but/not very smart"
    db $37, $45, $42, $62, $3F, $46, $44, $44, $42, $50, $51, $62, $46, $4B, $62, $51, $45, $42, $F1, $41, $42, $53, $46, $49, $62, $43, $3E, $4A, $46, $49, $56, $5E, $62, $3F, $52, $51, $F1, $4B, $4C, $51, $62, $53, $42, $4F, $56, $62, $50, $4A, $3E, $4F, $51, $F0
MonsterDesc_151_Centasaur:  ; $6CC1 "A hybrid devil of/man & beast"
    db $24, $62, $45, $56, $3F, $4F, $46, $41, $62, $41, $42, $53, $46, $49, $62, $4C, $43, $F1, $4A, $3E, $4B, $62, $B6, $62, $3F, $42, $3E, $50, $51, $F0
MonsterDesc_152_EvilArmor:  ; $6CDF "Its real identity/underneath the/armor is unknown"
    db $2C, $51, $50, $62, $4F, $42, $3E, $49, $62, $46, $41, $42, $4B, $51, $46, $51, $56, $F1, $52, $4B, $41, $42, $4F, $4B, $42, $3E, $51, $45, $62, $51, $45, $42, $F1, $3E, $4F, $4A, $4C, $4F, $62, $46, $50, $62, $52, $4B, $48, $4B, $4C, $54, $4B, $F0
MonsterDesc_153_Jamirus:  ; $6D11 "A hybrid devil of/an eagle & a lion"
    db $24, $62, $45, $56, $3F, $4F, $46, $41, $62, $41, $42, $53, $46, $49, $62, $4C, $43, $F1, $3E, $4B, $62, $42, $3E, $44, $49, $42, $62, $B6, $62, $3E, $62, $49, $46, $4C, $4B, $F0
MonsterDesc_154_Durran:  ; $6D35 "A strong all-round/natural born/fighter."
    db $24, $62, $50, $51, $4F, $4C, $4B, $44, $62, $3E, $49, $49, $9C, $4F, $4C, $52, $4B, $41, $F1, $4B, $3E, $51, $52, $4F, $3E, $49, $62, $3F, $4C, $4F, $4B, $F1, $43, $46, $44, $45, $51, $42, $4F, $5F, $F0
MonsterDesc_155_Spooky:  ; $6D5E "Its hobby is to/scare people"
    db $2C, $51, $50, $62, $45, $4C, $3F, $3F, $56, $62, $46, $50, $62, $51, $4C, $F1, $50, $40, $3E, $4F, $42, $62, $4D, $42, $4C, $4D, $49, $42, $F0
MonsterDesc_156_Skullgon:  ; $6D7B "A dragon/that's risen from/the dead"
    db $24, $62, $41, $4F, $3E, $44, $4C, $4B, $F1, $51, $45, $3E, $51, $68, $62, $4F, $46, $50, $42, $4B, $62, $43, $4F, $4C, $4A, $F1, $51, $45, $42, $62, $41, $42, $3E, $41, $F0
MonsterDesc_157_Putrepup:  ; $6D9E "It's fearless/since it doesn't/feel any pain"
    db $2C, $51, $68, $62, $43, $42, $3E, $4F, $49, $42, $50, $50, $F1, $50, $46, $4B, $40, $42, $62, $46, $51, $62, $41, $4C, $42, $50, $4B, $67, $F1, $43, $42, $42, $49, $62, $3E, $4B, $56, $62, $4D, $3E, $46, $4B, $F0
MonsterDesc_158_RotRaven:  ; $6DC9 "Dozes all day/in its half rotted/body"
    db $27, $4C, $57, $42, $50, $62, $3E, $49, $49, $62, $41, $3E, $56, $F1, $46, $4B, $62, $46, $51, $50, $62, $45, $3E, $49, $43, $62, $4F, $4C, $51, $51, $42, $41, $F1, $3F, $4C, $41, $56, $F0
MonsterDesc_159_Mummy:  ; $6DEF "Its body is filled/with herbs to/prevent its decay"
    db $2C, $51, $50, $62, $3F, $4C, $41, $56, $62, $46, $50, $62, $43, $46, $49, $49, $42, $41, $F1, $54, $46, $51, $45, $62, $45, $42, $4F, $3F, $50, $62, $51, $4C, $F1, $4D, $4F, $42, $53, $42, $4B, $51, $62, $46, $51, $50, $62, $41, $42, $40, $3E, $56, $F0
MonsterDesc_160_DarkCrab:  ; $6E22 "Its shell/resembles a/human face"
    db $2C, $51, $50, $62, $50, $45, $42, $49, $49, $F1, $4F, $42, $50, $42, $4A, $3F, $49, $42, $50, $62, $3E, $F1, $45, $52, $4A, $3E, $4B, $62, $43, $3E, $40, $42, $F0
MonsterDesc_161_DeadNite:  ; $6E43 "Knight revived/as a zombie, who/never tires"
    db $2E, $4B, $46, $44, $45, $51, $62, $4F, $42, $53, $46, $53, $42, $41, $F1, $3E, $50, $62, $3E, $62, $57, $4C, $4A, $3F, $46, $42, $5E, $62, $54, $45, $4C, $F1, $4B, $42, $53, $42, $4F, $62, $51, $46, $4F, $42, $50, $F0
MonsterDesc_162_Shadow:  ; $6E6F "Real identity is/unknown due to its/shadow-like body"
    db $35, $42, $3E, $49, $62, $46, $41, $42, $4B, $51, $46, $51, $56, $62, $46, $50, $F1, $52, $4B, $48, $4B, $4C, $54, $4B, $62, $41, $52, $42, $62, $51, $4C, $62, $46, $51, $50, $F1, $50, $45, $3E, $41, $4C, $54, $9C, $49, $46, $48, $42, $62, $3F, $4C, $41, $56, $F0
MonsterDesc_163_Hork:  ; $6EA4 "Its acidic saliva/will dissolve/anything"
    db $2C, $51, $50, $62, $3E, $40, $46, $41, $46, $40, $62, $50, $3E, $49, $46, $53, $3E, $F1, $54, $46, $49, $49, $62, $41, $46, $50, $50, $4C, $49, $53, $42, $F1, $3E, $4B, $56, $51, $45, $46, $4B, $44, $F0
MonsterDesc_164_Mudron:  ; $6ECD "A swamp mud/infested spirit of/the dead"
    db $24, $62, $50, $54, $3E, $4A, $4D, $62, $4A, $52, $41, $F1, $46, $4B, $43, $42, $50, $51, $42, $41, $62, $50, $4D, $46, $4F, $46, $51, $62, $4C, $43, $F1, $51, $45, $42, $62, $41, $42, $3E, $41, $F0
MonsterDesc_165_NiteWhip:  ; $6EF5 "Flies in the/air leaving a/streak of light"
    db $29, $49, $46, $42, $50, $62, $46, $4B, $62, $51, $45, $42, $F1, $3E, $46, $4F, $62, $49, $42, $3E, $53, $46, $4B, $44, $62, $3E, $F1, $50, $51, $4F, $42, $3E, $48, $62, $4C, $43, $62, $49, $46, $44, $45, $51, $F0
MonsterDesc_166_MadSpirit:  ; $6F20 "Lost spirits/fused together"
    db $2F, $4C, $50, $51, $62, $50, $4D, $46, $4F, $46, $51, $50, $F1, $43, $52, $50, $42, $41, $62, $51, $4C, $44, $42, $51, $45, $42, $4F, $F0
MonsterDesc_167_WindMerge:  ; $6F3C "Strangely, there/is nothing under/its garment"
    db $36, $51, $4F, $3E, $4B, $44, $42, $49, $56, $5E, $62, $51, $45, $42, $4F, $42, $F1, $46, $50, $62, $4B, $4C, $51, $45, $46, $4B, $44, $62, $52, $4B, $41, $42, $4F, $F1, $46, $51, $50, $62, $44, $3E, $4F, $4A, $42, $4B, $51, $F0
MonsterDesc_168_Reaper:  ; $6F6A "Guides dead/spirits to the/underworld"
    db $2A, $52, $46, $41, $42, $50, $62, $41, $42, $3E, $41, $F1, $50, $4D, $46, $4F, $46, $51, $50, $62, $51, $4C, $62, $51, $45, $42, $F1, $52, $4B, $41, $42, $4F, $54, $4C, $4F, $49, $41, $F0
MonsterDesc_169_DeadNoble:  ; $6F90 "Rides on a horse &/attacks enemies/with its lance"
    db $35, $46, $41, $42, $50, $62, $4C, $4B, $62, $3E, $62, $45, $4C, $4F, $50, $42, $62, $B6, $F1, $3E, $51, $51, $3E, $40, $48, $50, $62, $42, $4B, $42, $4A, $46, $42, $50, $F1, $54, $46, $51, $45, $62, $46, $51, $50, $62, $49, $3E, $4B, $40, $42, $F0
MonsterDesc_170_WhiteKing:  ; $6FC2 "Has retained its/high INT from/when it was alive"
    db $2B, $3E, $50, $62, $4F, $42, $51, $3E, $46, $4B, $42, $41, $62, $46, $51, $50, $F1, $45, $46, $44, $45, $62, $2C, $31, $37, $62, $43, $4F, $4C, $4A, $F1, $54, $45, $42, $4B, $62, $46, $51, $62, $54, $3E, $50, $62, $3E, $49, $46, $53, $42, $F0
MonsterDesc_171_BoneSlave:  ; $6FF3 "Resurrected as a/zombie to serve/hard labor"
    db $35, $42, $50, $52, $4F, $4F, $42, $40, $51, $42, $41, $62, $3E, $50, $62, $3E, $F1, $57, $4C, $4A, $3F, $46, $42, $62, $51, $4C, $62, $50, $42, $4F, $53, $42, $F1, $45, $3E, $4F, $41, $62, $49, $3E, $3F, $4C, $4F, $F0
MonsterDesc_172_Skeletor:  ; $701F "Attacks with/a sword in each/of its 6 hands"
    db $24, $51, $51, $3E, $40, $48, $50, $62, $54, $46, $51, $45, $F1, $3E, $62, $50, $54, $4C, $4F, $41, $62, $46, $4B, $62, $42, $3E, $40, $45, $F1, $4C, $43, $62, $46, $51, $50, $62, $06, $62, $45, $3E, $4B, $41, $50, $F0
MonsterDesc_173_Servant:  ; $704B "Created from evil/powers,it has a/high INT"
    db $26, $4F, $42, $3E, $51, $42, $41, $62, $43, $4F, $4C, $4A, $62, $42, $53, $46, $49, $F1, $4D, $4C, $54, $42, $4F, $50, $5E, $46, $51, $62, $45, $3E, $50, $62, $3E, $F1, $45, $46, $44, $45, $62, $2C, $31, $37, $F0
MonsterDesc_174_Copycat:  ; $7076 "Can disguise as/any creature &/mimic any move"
    db $26, $3E, $4B, $62, $41, $46, $50, $44, $52, $46, $50, $42, $62, $3E, $50, $F1, $3E, $4B, $56, $62, $40, $4F, $42, $3E, $51, $52, $4F, $42, $62, $B6, $F1, $4A, $46, $4A, $46, $40, $62, $3E, $4B, $56, $62, $4A, $4C, $53, $42, $F0
MonsterDesc_175_JewelBag:  ; $70A4 "Likes to eat/things that are/precious & shiny"
    db $2F, $46, $48, $42, $50, $62, $51, $4C, $62, $42, $3E, $51, $F1, $51, $45, $46, $4B, $44, $50, $62, $51, $45, $3E, $51, $62, $3E, $4F, $42, $F1, $4D, $4F, $42, $40, $46, $4C, $52, $50, $62, $B6, $62, $50, $45, $46, $4B, $56, $F0
MonsterDesc_176_EvilWand:  ; $70D2 "An evil spirit/possessing a/wizard's wand"
    db $24, $4B, $62, $42, $53, $46, $49, $62, $50, $4D, $46, $4F, $46, $51, $F1, $4D, $4C, $50, $50, $42, $50, $50, $46, $4B, $44, $62, $3E, $F1, $54, $46, $57, $3E, $4F, $41, $68, $62, $54, $3E, $4B, $41, $F0
MonsterDesc_177_MadCandle:  ; $70FB "Its candle will/remain lit until/it dies"
    db $2C, $51, $50, $62, $40, $3E, $4B, $41, $49, $42, $62, $54, $46, $49, $49, $F1, $4F, $42, $4A, $3E, $46, $4B, $62, $49, $46, $51, $62, $52, $4B, $51, $46, $49, $F1, $46, $51, $62, $41, $46, $42, $50, $F0
MonsterDesc_178_CoilBird:  ; $7124 "Emits an/eerie noise"
    db $28, $4A, $46, $51, $50, $62, $3E, $4B, $F1, $42, $42, $4F, $46, $42, $62, $4B, $4C, $46, $50, $42, $F0
MonsterDesc_179_Facer:  ; $7139 "An evil spirit/has possessed/this wooden mask"
    db $24, $4B, $62, $42, $53, $46, $49, $62, $50, $4D, $46, $4F, $46, $51, $F1, $45, $3E, $50, $62, $4D, $4C, $50, $50, $42, $50, $50, $42, $41, $F1, $51, $45, $46, $50, $62, $54, $4C, $4C, $41, $42, $4B, $62, $4A, $3E, $50, $48, $F0
MonsterDesc_180_SpikyBoy:  ; $7167 "Explodes when/angered"
    db $28, $55, $4D, $49, $4C, $41, $42, $50, $62, $54, $45, $42, $4B, $F1, $3E, $4B, $44, $42, $4F, $42, $41, $F0
MonsterDesc_181_MadMirror:  ; $717D "Absorbs anything/that reflects on/its mirror"
    db $24, $3F, $50, $4C, $4F, $3F, $50, $62, $3E, $4B, $56, $51, $45, $46, $4B, $44, $F1, $51, $45, $3E, $51, $62, $4F, $42, $43, $49, $42, $40, $51, $50, $62, $4C, $4B, $F1, $46, $51, $50, $62, $4A, $46, $4F, $4F, $4C, $4F, $F0
MonsterDesc_182_RogueNite:  ; $71AA "Life was brought/to this armor & it/roams for prey"
    db $2F, $46, $43, $42, $62, $54, $3E, $50, $62, $3F, $4F, $4C, $52, $44, $45, $51, $F1, $51, $4C, $62, $51, $45, $46, $50, $62, $3E, $4F, $4A, $4C, $4F, $62, $B6, $62, $46, $51, $F1, $4F, $4C, $3E, $4A, $50, $62, $43, $4C, $4F, $62, $4D, $4F, $42, $56, $F0
MonsterDesc_183_Goopi:  ; $71DD "Grabs & paralyzes/any prey that/passes"
    db $2A, $4F, $3E, $3F, $50, $62, $B6, $62, $4D, $3E, $4F, $3E, $49, $56, $57, $42, $50, $F1, $3E, $4B, $56, $62, $4D, $4F, $42, $56, $62, $51, $45, $3E, $51, $F1, $4D, $3E, $50, $50, $42, $50, $F0
MonsterDesc_184_Voodoll:  ; $7204 "A clay doll/brought to life"
    db $24, $62, $40, $49, $3E, $56, $62, $41, $4C, $49, $49, $F1, $3F, $4F, $4C, $52, $44, $45, $51, $62, $51, $4C, $62, $49, $46, $43, $42, $F0
MonsterDesc_185_MetalDrak:  ; $7220 "A dragon/constructed from/metal"
    db $24, $62, $41, $4F, $3E, $44, $4C, $4B, $F1, $40, $4C, $4B, $50, $51, $4F, $52, $40, $51, $42, $41, $62, $43, $4F, $4C, $4A, $F1, $4A, $42, $51, $3E, $49, $F0
MonsterDesc_186_Balzak:  ; $7240 "A creature created/to be the/strongest monster"
    db $24, $62, $40, $4F, $42, $3E, $51, $52, $4F, $42, $62, $40, $4F, $42, $3E, $51, $42, $41, $F1, $51, $4C, $62, $3F, $42, $62, $51, $45, $42, $F1, $50, $51, $4F, $4C, $4B, $44, $42, $50, $51, $62, $4A, $4C, $4B, $50, $51, $42, $4F, $F0
MonsterDesc_187_SabreMan:  ; $726F "Fashioned with so/much passion that/it came to life"
    db $29, $3E, $50, $45, $46, $4C, $4B, $42, $41, $62, $54, $46, $51, $45, $62, $50, $4C, $F1, $4A, $52, $40, $45, $62, $4D, $3E, $50, $50, $46, $4C, $4B, $62, $51, $45, $3E, $51, $F1, $46, $51, $62, $40, $3E, $4A, $42, $62, $51, $4C, $62, $49, $46, $43, $42, $F0
MonsterDesc_188_CurseLamp:  ; $72A3 "Its been said that/there is an evil/genie in the lamp"
    db $2C, $51, $50, $62, $3F, $42, $42, $4B, $62, $50, $3E, $46, $41, $62, $51, $45, $3E, $51, $F1, $51, $45, $42, $4F, $42, $62, $46, $50, $62, $3E, $4B, $62, $42, $53, $46, $49, $F1, $44, $42, $4B, $46, $42, $62, $46, $4B, $62, $51, $45, $42, $62, $49, $3E, $4A, $4D, $F0
MonsterDesc_189_Roboster:  ; $72D9 "Last suviving war/robot made in/an ancient time"
    db $2F, $3E, $50, $51, $62, $50, $52, $53, $46, $53, $46, $4B, $44, $62, $54, $3E, $4F, $F1, $4F, $4C, $3F, $4C, $51, $62, $4A, $3E, $41, $42, $62, $46, $4B, $F1, $3E, $4B, $62, $3E, $4B, $40, $46, $42, $4B, $51, $62, $51, $46, $4A, $42, $F0
MonsterDesc_190_EvilPot:  ; $7309 "Lurks in a/pot to hide/its identity"
    db $2F, $52, $4F, $48, $50, $62, $46, $4B, $62, $3E, $F1, $4D, $4C, $51, $62, $51, $4C, $62, $45, $46, $41, $42, $F1, $46, $51, $50, $62, $46, $41, $42, $4B, $51, $46, $51, $56, $F0
MonsterDesc_191_Gismo:  ; $732D "Life was brought/to this ball of/energy"
    db $2F, $46, $43, $42, $62, $54, $3E, $50, $62, $3F, $4F, $4C, $52, $44, $45, $51, $F1, $51, $4C, $62, $51, $45, $46, $50, $62, $3F, $3E, $49, $49, $62, $4C, $43, $F1, $42, $4B, $42, $4F, $44, $56, $F0
MonsterDesc_192_LavaMan:  ; $7355 "It's composed/of an energy/core & magma"
    db $2C, $51, $68, $62, $40, $4C, $4A, $4D, $4C, $50, $42, $41, $F1, $4C, $43, $62, $3E, $4B, $62, $42, $4B, $42, $4F, $44, $56, $F1, $40, $4C, $4F, $42, $62, $B6, $62, $4A, $3E, $44, $4A, $3E, $F0
MonsterDesc_193_IceMan:  ; $737C "It's composed/of an energy/core & ice"
    db $2C, $51, $68, $62, $40, $4C, $4A, $4D, $4C, $50, $42, $41, $F1, $4C, $43, $62, $3E, $4B, $62, $42, $4B, $42, $4F, $44, $56, $F1, $40, $4C, $4F, $42, $62, $B6, $62, $46, $40, $42, $F0
MonsterDesc_194_Mimic:  ; $73A1 "Attacks anyone/who tries to steal/its treasure"
    db $24, $51, $51, $3E, $40, $48, $50, $62, $3E, $4B, $56, $4C, $4B, $42, $F1, $54, $45, $4C, $62, $51, $4F, $46, $42, $50, $62, $51, $4C, $62, $50, $51, $42, $3E, $49, $F1, $46, $51, $50, $62, $51, $4F, $42, $3E, $50, $52, $4F, $42, $F0
MonsterDesc_195_MudDoll:  ; $73D0 "A kneaded dried/clay doll that/came to life"
    db $24, $62, $48, $4B, $42, $3E, $41, $42, $41, $62, $41, $4F, $46, $42, $41, $F1, $40, $49, $3E, $56, $62, $41, $4C, $49, $49, $62, $51, $45, $3E, $51, $F1, $40, $3E, $4A, $42, $62, $51, $4C, $62, $49, $46, $43, $42, $F0
MonsterDesc_196_Golem:  ; $73FC "A stack of rock/bricks that came/to life"
    db $24, $62, $50, $51, $3E, $40, $48, $62, $4C, $43, $62, $4F, $4C, $40, $48, $F1, $3F, $4F, $46, $40, $48, $50, $62, $51, $45, $3E, $51, $62, $40, $3E, $4A, $42, $F1, $51, $4C, $62, $49, $46, $43, $42, $F0
MonsterDesc_197_StoneMan:  ; $7425 "A statue made/from rock that/came to life"
    db $24, $62, $50, $51, $3E, $51, $52, $42, $62, $4A, $3E, $41, $42, $F1, $43, $4F, $4C, $4A, $62, $4F, $4C, $40, $48, $62, $51, $45, $3E, $51, $F1, $40, $3E, $4A, $42, $62, $51, $4C, $62, $49, $46, $43, $42, $F0
MonsterDesc_198_BombCrag:  ; $744F "Usually dormant/& looks like a/normal rock"
    db $38, $50, $52, $3E, $49, $49, $56, $62, $41, $4C, $4F, $4A, $3E, $4B, $51, $F1, $B6, $62, $49, $4C, $4C, $48, $50, $62, $49, $46, $48, $42, $62, $3E, $F1, $4B, $4C, $4F, $4A, $3E, $49, $62, $4F, $4C, $40, $48, $F0
MonsterDesc_199_GoldGolem:  ; $747A "Made out of an/elastic & durable/metal"
    db $30, $3E, $41, $42, $62, $4C, $52, $51, $62, $4C, $43, $62, $3E, $4B, $F1, $42, $49, $3E, $50, $51, $46, $40, $62, $B6, $62, $41, $52, $4F, $3E, $3F, $49, $42, $F1, $4A, $42, $51, $3E, $49, $F0
MonsterDesc_200_DracoLord:  ; $74A1 "Tried to unite the/monsters to rule/the world"
    db $37, $4F, $46, $42, $41, $62, $51, $4C, $62, $52, $4B, $46, $51, $42, $62, $51, $45, $42, $F1, $4A, $4C, $4B, $50, $51, $42, $4F, $50, $62, $51, $4C, $62, $4F, $52, $49, $42, $F1, $51, $45, $42, $62, $54, $4C, $4F, $49, $41, $F0
MonsterDesc_201_DracoLord:  ; $74CF "This is the true/identity of/DracoLord"
    db $37, $45, $46, $50, $62, $46, $50, $62, $51, $45, $42, $62, $51, $4F, $52, $42, $F1, $46, $41, $42, $4B, $51, $46, $51, $56, $62, $4C, $43, $F1, $27, $4F, $3E, $40, $4C, $2F, $4C, $4F, $41, $F0
MonsterDesc_202_Hargon:  ; $74F6 "The one who/planned to revive/the Destructor"
    db $37, $45, $42, $62, $4C, $4B, $42, $62, $54, $45, $4C, $F1, $4D, $49, $3E, $4B, $4B, $42, $41, $62, $51, $4C, $62, $4F, $42, $53, $46, $53, $42, $F1, $51, $45, $42, $62, $27, $42, $50, $51, $4F, $52, $40, $51, $4C, $4F, $F0
MonsterDesc_203_Sidoh:  ; $7523 "An evil dragon/lord, ruler of/all destruction"
    db $24, $4B, $62, $42, $53, $46, $49, $62, $41, $4F, $3E, $44, $4C, $4B, $F1, $49, $4C, $4F, $41, $5E, $62, $4F, $52, $49, $42, $4F, $62, $4C, $43, $F1, $3E, $49, $49, $62, $41, $42, $50, $51, $4F, $52, $40, $51, $46, $4C, $4B, $F0
MonsterDesc_204_Baramos:  ; $7551 "This evil lord/controls all/monsters"
    db $37, $45, $46, $50, $62, $42, $53, $46, $49, $62, $49, $4C, $4F, $41, $F1, $40, $4C, $4B, $51, $4F, $4C, $49, $50, $62, $3E, $49, $49, $F1, $4A, $4C, $4B, $50, $51, $42, $4F, $50, $F0
MonsterDesc_205_Zoma:  ; $7576 "The source of/all evil"
    db $37, $45, $42, $62, $50, $4C, $52, $4F, $40, $42, $62, $4C, $43, $F1, $3E, $49, $49, $62, $42, $53, $46, $49, $F0
MonsterDesc_206_Pizzaro:  ; $758D "Attained its power/from the pearl of/evolution"
    db $24, $51, $51, $3E, $46, $4B, $42, $41, $62, $46, $51, $50, $62, $4D, $4C, $54, $42, $4F, $F1, $43, $4F, $4C, $4A, $62, $51, $45, $42, $62, $4D, $42, $3E, $4F, $49, $62, $4C, $43, $F1, $42, $53, $4C, $49, $52, $51, $46, $4C, $4B, $F0
MonsterDesc_207_Esterk:  ; $75BC "Exists beyond/the boundries of/time and space"
    db $28, $55, $46, $50, $51, $50, $62, $3F, $42, $56, $4C, $4B, $41, $F1, $51, $45, $42, $62, $3F, $4C, $52, $4B, $41, $4F, $46, $42, $50, $62, $4C, $43, $F1, $51, $46, $4A, $42, $62, $3E, $4B, $41, $62, $50, $4D, $3E, $40, $42, $F0
MonsterDesc_208_Mirudraas:  ; $75EA "An evil lord who/tried to rule/the human world"
    db $24, $4B, $62, $42, $53, $46, $49, $62, $49, $4C, $4F, $41, $62, $54, $45, $4C, $F1, $51, $4F, $46, $42, $41, $62, $51, $4C, $62, $4F, $52, $49, $42, $F1, $51, $45, $42, $62, $45, $52, $4A, $3E, $4B, $62, $54, $4C, $4F, $49, $41, $F0
MonsterDesc_209_Mirudraas:  ; $7619 "This is the true/identity/of Mirudaas"
    db $37, $45, $46, $50, $62, $46, $50, $62, $51, $45, $42, $62, $51, $4F, $52, $42, $F1, $46, $41, $42, $4B, $51, $46, $51, $56, $F1, $4C, $43, $62, $30, $46, $4F, $52, $41, $3E, $3E, $50, $F0
MonsterDesc_210_Mudou:  ; $763F "This evil lord/controls all/monsters"
    db $37, $45, $46, $50, $62, $42, $53, $46, $49, $62, $49, $4C, $4F, $41, $F1, $40, $4C, $4B, $51, $4F, $4C, $49, $50, $62, $3E, $49, $49, $F1, $4A, $4C, $4B, $50, $51, $42, $4F, $50, $F0
MonsterDesc_211_DeathMore:  ; $7664 "An evil lord that/lives between/reality & fantasy"
    db $24, $4B, $62, $42, $53, $46, $49, $62, $49, $4C, $4F, $41, $62, $51, $45, $3E, $51, $F1, $49, $46, $53, $42, $50, $62, $3F, $42, $51, $54, $42, $42, $4B, $F1, $4F, $42, $3E, $49, $46, $51, $56, $62, $B6, $62, $43, $3E, $4B, $51, $3E, $50, $56, $F0
MonsterDesc_212_DeathMore:  ; $7696 "Shed off its/disguise to show/off its strength"
    db $36, $45, $42, $41, $62, $4C, $43, $43, $62, $46, $51, $50, $F1, $41, $46, $50, $44, $52, $46, $50, $42, $62, $51, $4C, $62, $50, $45, $4C, $54, $F1, $4C, $43, $43, $62, $46, $51, $50, $62, $50, $51, $4F, $42, $4B, $44, $51, $45, $F0
MonsterDesc_213_DeathMore:  ; $76C5 "Only a true/warrior can reveal/its real identity"
    db $32, $4B, $49, $56, $62, $3E, $62, $51, $4F, $52, $42, $F1, $54, $3E, $4F, $4F, $46, $4C, $4F, $62, $40, $3E, $4B, $62, $4F, $42, $53, $42, $3E, $49, $F1, $46, $51, $50, $62, $4F, $42, $3E, $49, $62, $46, $41, $42, $4B, $51, $46, $51, $56, $F0
MonsterDesc_214_Darkdrium:  ; $76F6 "The master of/destruction &/carnage"
    db $37, $45, $42, $62, $4A, $3E, $50, $51, $42, $4F, $62, $4C, $43, $F1, $41, $42, $50, $51, $4F, $52, $40, $51, $46, $4C, $4B, $62, $B6, $F1, $40, $3E, $4F, $4B, $3E, $44, $42, $F0
; $771A: first byte of the bank's zero tail (was fused with the last
;        terminator into a fake `ldh a, [rP1]` = $F0 $00)
    db $00
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
