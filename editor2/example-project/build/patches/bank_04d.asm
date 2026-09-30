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
    ; ---- Entries 3-10 ALSO serve as the $4007 TEXT MODE-TABLE (read by
    ;      SaveBankAndSwitch as [$4007 + mode*2]). See TEXT_SYSTEM.md. ----
    dw $400B                          ; Entry 3 | mode0 = detail line1 name template (256 entries)
    dw $420B                          ; Entry 4 | mode1 = detail line2 DESCRIPTION table — 215 entries (0-214); id>=215 OVERSHOOTS into routine code -> freeze. Forked by HighDetailTextFork.
    dw $43CE                          ; Entry 5 | mode2 (routine target, not per-species)
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
    dw $53D3                          ; Entry 261
    dw $53F7                          ; Entry 262
    dw $541D                          ; Entry 263
    dw $5444                          ; Entry 264
    dw $546F                          ; Entry 265
    dw $5494                          ; Entry 266
    dw $54C8                          ; Entry 267
    dw $54EE                          ; Entry 268
    dw $5520                          ; Entry 269
    dw $5549                          ; Entry 270
    dw $5573                          ; Entry 271
    dw $559E                          ; Entry 272
    dw $55BA                          ; Entry 273
    dw $55E6                          ; Entry 274
    dw $5610                          ; Entry 275
    dw $5647                          ; Entry 276
    dw $567A                          ; Entry 277
    dw $56A9                          ; Entry 278
    dw $56CF                          ; Entry 279
    dw $56FA                          ; Entry 280
    dw $5724                          ; Entry 281
    dw $574A                          ; Entry 282
    dw $577A                          ; Entry 283
    dw $57A9                          ; Entry 284
    dw $57D4                          ; Entry 285
    dw $5800                          ; Entry 286
    dw $5830                          ; Entry 287
    dw $5865                          ; Entry 288
    dw $5890                          ; Entry 289
    dw $58B4                          ; Entry 290
    dw $58E4                          ; Entry 291
    dw $5914                          ; Entry 292
    dw $593C                          ; Entry 293
    dw $5962                          ; Entry 294
    dw $5987                          ; Entry 295
    dw $59B7                          ; Entry 296
    dw $59E5                          ; Entry 297
    dw $5A16                          ; Entry 298
    dw $5A3E                          ; Entry 299
    dw $5A6B                          ; Entry 300
    dw $5A97                          ; Entry 301
    dw $5AC5                          ; Entry 302
    dw $5AFA                          ; Entry 303
    dw $5B24                          ; Entry 304
    dw $5B54                          ; Entry 305
    dw $5B80                          ; Entry 306
    dw $5BAB                          ; Entry 307
    dw $5BD9                          ; Entry 308
    dw $5C00                          ; Entry 309
    dw $5C22                          ; Entry 310
    dw $5C47                          ; Entry 311
    dw $5C6B                          ; Entry 312
    dw $5C95                          ; Entry 313
    dw $5CC6                          ; Entry 314
    dw $5CF1                          ; Entry 315
    dw $5D16                          ; Entry 316
    dw $5D49                          ; Entry 317
    dw $5D63                          ; Entry 318
    dw $5D86                          ; Entry 319
    dw $5DAF                          ; Entry 320
    dw $5DD4                          ; Entry 321
    dw $5DFF                          ; Entry 322
    dw $5E28                          ; Entry 323
    dw $5E4B                          ; Entry 324
    dw $5E7A                          ; Entry 325
    dw $5EA6                          ; Entry 326
    dw $5ECE                          ; Entry 327
    dw $5EFD                          ; Entry 328
    dw $5F1C                          ; Entry 329
    dw $5F41                          ; Entry 330
    dw $5F69                          ; Entry 331
    dw $5F8F                          ; Entry 332
    dw $5FBB                          ; Entry 333
    dw $5FDE                          ; Entry 334
    dw $600C                          ; Entry 335
    dw $6039                          ; Entry 336
    dw $6067                          ; Entry 337
    dw $608F                          ; Entry 338
    dw $60BC                          ; Entry 339
    dw $60EC                          ; Entry 340
    dw $610A                          ; Entry 341
    dw $611F                          ; Entry 342
    dw $6151                          ; Entry 343
    dw $617B                          ; Entry 344
    dw $61B2                          ; Entry 345
    dw $61DF                          ; Entry 346
    dw $6205                          ; Entry 347
    dw $6238                          ; Entry 348
    dw $626B                          ; Entry 349
    dw $6281                          ; Entry 350
    dw $62B1                          ; Entry 351
    dw $62D4                          ; Entry 352
    dw $62FA                          ; Entry 353
    dw $632A                          ; Entry 354
    dw $6359                          ; Entry 355
    dw $638C                          ; Entry 356
    dw $63BD                          ; Entry 357
    dw $63E7                          ; Entry 358
    dw $640A                          ; Entry 359
    dw $643A                          ; Entry 360
    dw $6466                          ; Entry 361
    dw $6499                          ; Entry 362
    dw $64C0                          ; Entry 363
    dw $64EA                          ; Entry 364
    dw $6518                          ; Entry 365
    dw $6543                          ; Entry 366
    dw $6569                          ; Entry 367
    dw $6594                          ; Entry 368
    dw $65BE                          ; Entry 369
    dw $65E6                          ; Entry 370
    dw $6606                          ; Entry 371
    dw $662B                          ; Entry 372
    dw $665B                          ; Entry 373
    dw $6686                          ; Entry 374
    dw $66B7                          ; Entry 375
    dw $66E7                          ; Entry 376
    dw $6714                          ; Entry 377
    dw $673C                          ; Entry 378
    dw $675F                          ; Entry 379
    dw $678A                          ; Entry 380
    dw $67AC                          ; Entry 381
    dw $67D7                          ; Entry 382
    dw $6803                          ; Entry 383
    dw $6829                          ; Entry 384
    dw $6854                          ; Entry 385
    dw $6882                          ; Entry 386
    dw $68B7                          ; Entry 387
    dw $68D9                          ; Entry 388
    dw $68FC                          ; Entry 389
    dw $6920                          ; Entry 390
    dw $6948                          ; Entry 391
    dw $6973                          ; Entry 392
    dw $69A1                          ; Entry 393
    dw $69BD                          ; Entry 394
    dw $69EB                          ; Entry 395
    dw $6A0F                          ; Entry 396
    dw $6A38                          ; Entry 397
    dw $6A5D                          ; Entry 398
    dw $6A86                          ; Entry 399
    dw $6AA8                          ; Entry 400
    dw $6AD6                          ; Entry 401
    dw $6B08                          ; Entry 402
    dw $6B24                          ; Entry 403
    dw $6B57                          ; Entry 404
    dw $6B7C                          ; Entry 405
    dw $6BAF                          ; Entry 406
    dw $6BE0                          ; Entry 407
    dw $6C0B                          ; Entry 408
    dw $6C35                          ; Entry 409
    dw $6C64                          ; Entry 410
    dw $6C8D                          ; Entry 411
    dw $6CC1                          ; Entry 412
    dw $6CDF                          ; Entry 413
    dw $6D11                          ; Entry 414
    dw $6D35                          ; Entry 415
    dw $6D5E                          ; Entry 416
    dw $6D7B                          ; Entry 417
    dw $6D9E                          ; Entry 418
    dw $6DC9                          ; Entry 419
    dw $6DEF                          ; Entry 420
    dw $6E22                          ; Entry 421
    dw $6E43                          ; Entry 422
    dw $6E6F                          ; Entry 423
    dw $6EA4                          ; Entry 424
    dw $6ECD                          ; Entry 425
    dw $6EF5                          ; Entry 426
    dw $6F20                          ; Entry 427
    dw $6F3C                          ; Entry 428
    dw $6F6A                          ; Entry 429
    dw $6F90                          ; Entry 430
    dw $6FC2                          ; Entry 431
    dw $6FF3                          ; Entry 432
    dw $701F                          ; Entry 433
    dw $704B                          ; Entry 434
    dw $7076                          ; Entry 435
    dw $70A4                          ; Entry 436
    dw $70D2                          ; Entry 437
    dw $70FB                          ; Entry 438
    dw $7124                          ; Entry 439
    dw $7139                          ; Entry 440
    dw $7167                          ; Entry 441
    dw $717D                          ; Entry 442
    dw $71AA                          ; Entry 443
    dw $71DD                          ; Entry 444
    dw $7204                          ; Entry 445
    dw $7220                          ; Entry 446
    dw $7240                          ; Entry 447
    dw $726F                          ; Entry 448
    dw $72A3                          ; Entry 449
    dw $72D9                          ; Entry 450
    dw $7309                          ; Entry 451
    dw $732D                          ; Entry 452
    dw $7355                          ; Entry 453
    dw $737C                          ; Entry 454
    dw $73A1                          ; Entry 455
    dw $73D0                          ; Entry 456
    dw $73FC                          ; Entry 457
    dw $7425                          ; Entry 458
    dw $744F                          ; Entry 459
    dw $747A                          ; Entry 460
    dw $74A1                          ; Entry 461
    dw $74CF                          ; Entry 462
    dw $74F6                          ; Entry 463
    dw $7523                          ; Entry 464
    dw $7551                          ; Entry 465
    dw $7576                          ; Entry 466
    dw $758D                          ; Entry 467
    dw $75BC                          ; Entry 468
    dw $75EA                          ; Entry 469
    dw $7619                          ; Entry 470
    dw $763F                          ; Entry 471
    dw $7664                          ; Entry 472
    dw $7696                          ; Entry 473
    dw $76C5                          ; Entry 474
    dw $76F6                          ; Entry 475

SetB4d_43b9:
    jp HighDetailTextFork   ; FORK: species 221-239 use custom mode-table (byte-neutral 3+4)
    nop
    nop
    nop
    nop


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
; @BUILD_PROJECT BEGIN gd_library_text
; (generated by editor2 `gd_library_text`: the encyclopedia recipe line
;  per species, dispatch entry = species + 5 → these slots. A family slot
;  the project changed gets its string regenerated in place — coherence
;  Set 1, BREEDING_SYSTEM "Library recipe TEXT")
LibRecipeTextBlock:
LibRecipeText_000:  ; 0 DrakSlime: "<bird>family  <dragon>family  "  ; REGENERATED (project family recipe)
    db $13, $43, $3E, $4A, $46, $49, $56, $62, $62, $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
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
LibRecipeText_037:  ; 37 GreatDrak: "<dragon>family  <dragon>family  "  ; REGENERATED (project family recipe)
    db $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
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
LibRecipeText_046:  ; 46 Almiraj: "<slime>family  <dragon>family  "  ; REGENERATED (project family recipe)
    db $10, $43, $3E, $4A, $46, $49, $56, $62, $62, $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
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
LibRecipeText_071:  ; 71 Wyvern: "<beast>family  <dragon>family  "  ; REGENERATED (project family recipe)
    db $12, $43, $3E, $4A, $46, $49, $56, $62, $62, $11, $43, $3E, $4A, $46, $49, $56, $62, $62, $F0
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
; @BUILD_PROJECT END gd_library_text
; $53D3: first byte of the next item (split from a mis-decoded instruction)
    db $30
    ld c, h
    ld d, e
    ld b, d
    ld d, b
    ld h, d
    or [hl]
    ld h, d
    ld b, a
    ld d, d
    ld c, d

jr_04d_53de:
    ld c, l
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld d, c
    ld a, $46
    ld c, c
    ld h, d
    or [hl]
    ld h, d

jr_04d_53f1:
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ldh a, [$2f]
    ld a, $4f
    ld b, h

jr_04d_53fb:
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld a, $4b
    ld h, d
    ld a, $f1
    ld c, a
    ld b, d
    ld b, h
    ld d, d
    ld c, c
    ld a, $4f
    ld h, d
    ld d, b
    ld c, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    or [hl]
    pop af
    ld d, b
    ld c, l
    ld c, h
    ld d, c
    ld d, c
    ld b, d
    ld b, c
    ldh a, [$29]
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    pop af
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld b, h
    ld c, a
    ld b, d
    ld d, h
    ld h, d
    ld c, h
    ld c, e
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld c, c
    ld b, d
    ld a, $43
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    ld c, l
    pop af
    ld a, $3f
    ld d, b
    ld c, h
    ld c, a
    ccf
    ld d, b
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, a
    ld b, h
    ld d, [hl]
    pop af
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, b
    ld d, d
    ld c, e
    ld c, c
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ldh a, [$2b]
    ld b, [hl]
    ld b, c
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld d, b
    ld b, l
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    pop af
    ld d, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld c, b
    ld c, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld c, a
    ld b, [hl]
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    pop af
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, b
    ld c, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld c, l
    ld a, $4f
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld l, b
    ld h, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ldh a, [rNR52]
    ld a, $4b
    ld h, d
    ld d, c
    ld c, a
    ld a, $4b
    ld d, b
    ld b, e
    ld c, h
    ld c, a
    ld c, d
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    pop af
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld d, b
    ld b, l
    ld a, $4d
    ld b, d
    ldh a, [rNR51]
    ld b, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, a
    ld a, $4d
    ld c, l
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld a, $f1
    ccf
    ld c, h
    ld d, l
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    pop af
    ld d, b
    ld c, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld l, b
    ld h, d
    ld d, b
    ld b, l
    ld a, $4d
    ld b, d
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld c, h
    ld d, b
    ld d, c
    ld h, d
    ld a, $3f
    ld d, d
    ld c, e
    ld b, c
    ld a, $4b
    ld d, c
    pop af
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, l
    ld c, h
    ld c, l
    ld d, d
    ld c, c
    ld a, $4f
    pop af
    ld d, b
    ld c, l
    ld b, d
    ld b, b
    ld b, [hl]
    ld b, d
    ldh a, [$38]
    ld d, b
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld b, e
    ld d, d
    ld c, c
    pop af
    ld d, c
    ld b, d
    ld c, e
    ld d, c
    ld a, $40
    ld c, c
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    pop af
    ld c, d
    ld c, h
    ld d, e
    ld b, d
    ld h, d
    ld a, $3f
    ld c, h
    ld d, d
    ld d, c
    ldh a, [$2b]
    ld a, $50
    ld h, d
    ld a, $62
    ld c, a
    ld b, d
    ld b, c
    ld h, d
    jr nc, jr_04d_55cb

    ld b, l
    ld a, $54
    ld c, b
    pop af
    ld a, $4b
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ccf
    ld c, a
    ld a, $53
    ld b, d
    pop af
    or [hl]
    ld h, d
    ld c, l
    ld c, a
    ld c, h
    ld d, d
    ld b, c
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $50
    pop af
    ld b, l
    ld a, $4f
    ld b, c
    ld h, d
    ld a, $50
    ld h, d
    ld c, a
    ld c, h
    ld b, b
    ld c, b
    ldh a, [$32]
    ld b, [hl]
    ld c, c
    ld h, d
    ld b, e
    ld c, c
    ld c, h
    ld d, h
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l

jr_04d_55cb:
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld a, $41
    pop af
    ld c, h
    ld b, e
    ld h, d
    ccf
    ld c, c
    ld c, h
    ld c, h
    ld b, c
    ldh a, [$29]
    ld c, c
    ld b, d
    ld b, d
    ld d, b
    ld h, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld b, e
    ld a, $50
    ld d, c
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
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    pop af
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld c, c
    ld b, d
    ld b, h
    ld d, b
    ldh a, [$36]
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld a, $49
    ld h, d
    ld [hl], $4d
    ld c, h
    ld d, c
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    ld d, b
    pop af
    ld b, b
    ld c, h
    ld c, d
    ccf
    ld b, [hl]
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ldh a, [$36]
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld a, $49
    ld h, d
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    ld d, b
    pop af
    ld b, b
    ld c, h
    ld c, d
    ccf
    ld b, [hl]
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, d
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld b, [hl]
    ld c, a
    ld c, h
    ld c, e
    pop af
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, b
    ld c, c
    ld b, [hl]
    ld c, d
    ld b, d
    pop af
    ld a, $62
    ld c, d
    ld b, d
    ld d, c
    ld a, $49
    ld h, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ldh a, [$33]
    ld c, a
    ld c, h
    ld b, c
    ld d, d
    ld b, b
    ld b, d
    ld d, b
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    pop af
    ld d, h
    ld b, d
    ld a, $4d
    ld c, h
    ld c, e
    ld d, b
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ldh a, [$36]
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld a, $49
    ld h, d
    jr nc, jr_04d_571b

    ld d, c
    ld a, $49
    ld d, [hl]
    ld d, b
    pop af
    ld b, b
    ld c, h
    ld c, d
    ccf
    ld b, [hl]
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld c, d
    pop af
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld b, d
    ld d, b
    ld d, c
    pop af
    ld b, b
    ld c, a
    ld b, d
    ld a, $51
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    ld d, b
    ld c, c
    ld b, [hl]
    ld c, d

jr_04d_571b:
    ld b, d
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ldh a, [$2c]
    ld d, c
    ld h, d
    ld b, c
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, h
    ld c, a
    ld c, h
    ld d, h
    pop af
    ld a, $4b
    ld d, [hl]
    ld h, d
    ccf
    ld b, [hl]
    ld b, h
    ld b, h
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld a, $4b
    pop af
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ldh a, [$2c]
    ld d, c
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld a, $62
    ld d, c
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    pop af
    ld d, b
    ld b, l
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    pop af
    ld b, l
    ld b, [hl]
    ld b, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ldh a, [$29]
    ld c, c
    ld a, $4d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, c
    ld a, $4f
    ld b, h
    ld b, d
    pop af
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld b, e
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, b
    pop af
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $52
    ld d, c
    ld b, l
    ld c, h
    ld c, a
    ld b, [hl]
    ld d, c
    ld d, [hl]
    ldh a, [$37]
    ld c, a
    ld a, $4d
    ld d, b
    ld h, d
    ld b, h
    ld a, $50
    pop af
    ld b, [hl]
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ccf
    ld b, d
    ld c, c
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    pop af
    ld b, e
    ld c, c
    ld c, h
    ld a, $51
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, $46
    ld c, a
    ldh a, [$38]
    ld d, b
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld c, e
    ld b, h
    ld d, d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    pop af
    ld d, b
    ld d, d
    ld b, b
    ld c, b
    ld h, d
    ld c, e
    ld b, d
    ld b, b
    ld d, c
    ld a, $4f
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    pop af
    ld b, e
    ld c, c
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld d, b
    ldh a, [$36]
    ld c, d
    ld a, $4f
    ld d, c
    ld h, d
    ld b, d
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    ld d, c
    ld c, h
    pop af
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld b, e
    ld d, d
    ld c, c
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld h, d
    ld a, $f1
    ld d, b
    ld d, h
    ld c, h
    ld c, a
    ld b, c
    ld h, d
    or [hl]
    ld h, d
    ld d, b
    ld b, l
    ld b, [hl]
    ld b, d
    ld c, c
    ld b, c
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld c, c
    ld d, d
    ld b, [hl]
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld d, b
    ld b, d
    ld b, b
    ld c, a
    ld b, d
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld b, e
    ld b, [hl]
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, l
    ld c, h
    ld b, [hl]
    ld d, b
    ld c, h
    ld c, e
    ld c, h
    ld d, d
    ld d, b
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    pop af
    ld d, b
    ld d, h
    ld c, h
    ld c, a
    ld b, c
    sbc h
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld d, b
    ld c, l
    ld b, [hl]
    ld c, b
    ld b, d
    ld d, b
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld c, c
    ld b, c
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, h
    pop af
    ld d, b
    ld c, l
    ld b, d
    ld b, b
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld b, c
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ldh a, [$35]
    ld d, d
    ld c, e
    ld d, b
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld d, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld b, l
    ld a, $4b
    ld b, c
    ld d, b
    ld h, d
    or [hl]
    ld h, d
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    pop af
    ld d, c
    ld a, $46
    ld c, c
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ccf
    ld a, $49
    ld a, $4b
    ld b, b
    ld b, d
    ldh a, [$35]
    ld d, d
    ld c, e
    ld d, b
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld d, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld b, l
    ld a, $4b
    ld b, c
    ld d, b
    ld h, d
    or [hl]
    ld h, d
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    pop af
    ld d, c
    ld a, $46
    ld c, c
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ccf
    ld a, $49
    ld a, $4b
    ld b, b
    ld b, d
    ldh a, [rNR52]
    ld a, $4b
    ld h, d
    ld b, h
    ld c, a
    ld a, $3f
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
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
    ld d, c
    ld a, $49
    ld c, h
    ld c, e
    ld d, b
    pop af
    or [hl]
    ld h, d
    ld b, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld c, h
    ld b, e
    ld b, e
    ldh a, [rNR52]
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, e
    ld h, d
    ld b, b
    ld c, h
    ld c, c
    ld c, h
    ld c, a
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    pop af
    ld b, b
    ld a, $4a
    ld c, h
    ld d, d
    ld b, e
    ld c, c
    ld a, $44
    ld b, d
    ldh a, [$2b]
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    pop af
    ld c, d
    ld b, [hl]
    ld b, c
    ld a, $46
    ld c, a
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ldh a, [$36]
    ld b, l
    ld a, $4f
    ld c, l
    ld h, d
    ld b, b
    ld c, c
    ld a, $54
    ld d, b
    ld h, d
    or [hl]
    pop af
    ld b, e
    ld a, $4b
    ld b, h
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, d
    ld c, h
    ld d, b
    ld d, c
    pop af
    ld b, c
    ld b, d
    ld a, $41
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, d
    ld a, $4d
    ld c, h
    ld c, e
    ld d, b
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld c, l
    ld c, h
    ld b, [hl]
    ld d, b
    ld c, h
    ld c, e
    ld c, h
    ld d, d
    ld d, b
    ld h, d
    ccf
    ld b, [hl]
    ld d, c
    ld b, d
    pop af
    ld a, $4b
    ld b, c
    ld h, d
    ld d, b
    ld b, l
    ld a, $4f
    ld c, l
    ld h, d
    ld b, e
    ld a, $4b
    ld b, h
    ld d, b
    pop af
    ld a, $4f
    ld b, d
    ld h, d
    ld b, c
    ld b, d
    ld a, $41
    ld c, c
    ld d, [hl]
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld d, b
    ld c, l
    ld b, [hl]
    ld c, b
    ld d, [hl]
    ld h, d
    ld b, l
    ld a, $4f
    ld b, c
    pop af
    ld d, b
    ld b, l
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld c, l
    ld c, a
    ld c, h
    ld d, c
    ld b, d
    ld b, b
    ld d, c
    ld d, b
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld b, c
    ld a, $4b
    ld b, h
    ld b, d
    ld c, a
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld b, [hl]
    ld b, h
    ld b, h
    ld b, d
    ld d, b
    ld d, c
    pop af
    ld b, c
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    ld b, c
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ldh a, [$2c]
    ld d, c
    ld h, d
    ld d, b
    ld b, l
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld b, b
    ld c, a
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, d
    ld c, a
    ld c, a
    ld c, h
    ld c, a
    ld b, [hl]
    ld d, a
    ld b, d
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, d
    ld b, [hl]
    ld b, d
    ld d, b
    ldh a, [$2a]
    ld c, c
    ld b, [hl]
    ld b, c
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, $46
    ld c, a
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld c, c
    ld a, $4f
    ld b, h
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ldh a, [rNR52]
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld c, a
    ld b, [hl]
    ld b, b
    ld d, c
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
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
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld b, e
    ld d, d
    ld c, c
    ld h, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    dec b
    ld h, d
    ld b, l
    ld b, d
    ld a, $41
    ld d, b
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, c
    ld c, h
    pop af
    ld b, c
    ld b, [hl]
    ld b, e
    ld b, e
    ld b, d
    ld c, a
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    pop af
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld a, $4a
    ld b, d
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ldh a, [rNR50]
    ld d, c
    ld d, c
    ld a, $40
    ld c, b
    ld d, b
    ld h, d
    ccf
    ld d, [hl]
    pop af
    ld d, b
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld b, e
    ld d, d
    ld c, c
    ld h, d
    ld b, h
    ld b, [hl]
    ld a, $4b
    ld d, c
    ld h, d
    ld a, $55
    ldh a, [$29]
    ld c, c
    ld c, h
    ld a, $51
    ld d, b
    ld h, d
    ld b, e
    ld c, a
    ld b, d
    ld b, d
    ld c, c
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld c, e
    pop af
    ld c, d
    ld b, [hl]
    ld b, c
    ld a, $46
    ld c, a
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld c, d
    ld a, $44
    ld b, [hl]
    ld b, b
    ld a, $49
    ld h, d
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld d, b
    ldh a, [$2c]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    ld h, d
    ld b, [hl]
    ld d, c
    ld e, [hl]
    pop af
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, l
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    pop af
    ccf
    ld b, d
    ld h, d
    ld b, h
    ld c, a
    ld a, $4b
    ld d, c
    ld b, d
    ld b, c
    ldh a, [$30]
    ld c, h
    ld d, e
    ld b, d
    ld d, b
    ld h, d
    ld d, b
    ld c, c
    ld c, h
    ld d, h
    ld c, c
    ld d, [hl]
    pop af
    ccf
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    pop af
    ld d, c
    ld c, h
    ld c, e
    ld b, h
    ld d, d
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, c
    ld b, d
    ld a, $41
    ld c, c
    ld d, [hl]
    ldh a, [$3a]
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld b, b
    ld c, h
    ld c, a
    ld c, e
    ld b, d
    ld c, a
    ld b, d
    ld b, c
    ld e, [hl]
    ld b, [hl]
    ld d, c
    pop af
    ld b, b
    ld b, l
    ld a, $4f
    ld b, h
    ld b, d
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld d, b
    ld b, l
    ld a, $4f
    ld c, l
    ld h, d
    ld b, l
    ld c, h
    ld c, a
    ld c, e
    ld d, b
    ldh a, [rNR52]
    ld a, $4b
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    ld b, c
    ld a, $4f
    ld c, b
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
    ld d, b
    pop af
    ld a, $51
    ld h, d
    ld c, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ldh a, [$36]
    ld c, h
    ld b, e
    ld d, c
    ld h, d
    or [hl]
    ld h, d
    ld b, e
    ld c, c
    ld d, d
    ld b, e
    ld b, e
    ld d, [hl]
    pop af
    ld b, e
    ld d, d
    ld c, a
    ld h, d
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ldh a, [$2f]
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld a, $f1
    ld d, b
    ld a, $40
    ld c, b
    ld h, d
    ld c, d
    ld a, $41
    ld b, d
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    pop af
    ld c, h
    ld b, e
    ld h, d
    ccf
    ld c, a
    ld a, $4b
    ld b, b
    ld b, l
    ld b, d
    ld d, b
    ldh a, [$2c]
    ld d, c
    ld h, d
    ld b, c
    ld b, d
    ld d, e
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    pop af
    ccf
    ld b, [hl]
    ld b, h
    ld h, d
    ld b, h
    ld d, d
    ld c, c
    ld c, l
    ldh a, [rNR50]
    ld d, c
    ld d, c
    ld a, $40
    ld c, b
    ld d, b
    ld h, d
    ccf
    ld d, [hl]
    pop af
    ld d, c
    ld b, l
    ld c, a
    ld c, h
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, b
    ld c, b
    ld d, d
    ld c, c
    ld c, c
    ld d, b
    pop af
    ld a, $51
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, d
    ld b, [hl]
    ld b, d
    ld d, b
    ldh a, [rNR52]
    ld c, a
    ld b, d
    ld a, $51
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld c, a
    ld c, e
    ld a, $41
    ld c, h
    ld b, d
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
    ld c, c
    ld b, d
    ld b, h
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    pop af
    ld b, c
    ld b, d
    ld b, e
    ld b, d
    ld c, e
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    ldh a, [$38]
    ld d, b
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld c, e
    ld b, h
    ld d, d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    pop af
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld h, d
    or [hl]
    ld h, d
    ld d, b
    ld c, e
    ld a, $4f
    ld b, d
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
    ldh a, [$2c]
    ld d, c
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, h
    pop af
    ld c, h
    ld b, e
    ld b, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld b, c
    ld a, $4b
    ld b, b
    ld b, d
    pop af
    ld c, d
    ld c, h
    ld d, e
    ld b, d
    ld d, b
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld d, b
    ld c, l
    ld b, [hl]
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld d, b
    ld b, l
    ld b, d
    ld c, c
    ld c, c
    pop af
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    pop af
    ld d, b
    ld c, c
    ld a, $4a
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld h, d
    ld b, c
    ld b, d
    ld a, $41
    ld c, c
    ld d, [hl]
    ldh a, [$2c]
    ld d, c
    ld h, d
    ld b, e
    ld c, h
    ld c, c
    ld c, c
    ld c, h
    ld d, h
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    pop af
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld a, $62
    ld b, c
    ld c, h
    ld b, h
    ldh a, [$2c]
    ld d, c
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld a, $62
    ld b, l
    ld a, $4a
    ld c, d
    ld b, d
    ld c, a
    pop af
    ccf
    ld b, [hl]
    ld b, h
    ld b, h
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld a, $4b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    ldh a, [$38]
    ld d, b
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    pop af
    ld a, $4f
    ld c, d
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld c, [hl]
    ld d, d
    ld b, d
    ld b, d
    ld d, a
    ld b, d
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $f1
    ld d, c
    ld b, l
    ld b, [hl]
    ld b, b
    ld c, b
    ld h, d
    ld b, e
    ld d, d
    ld c, a
    ldh a, [$2c]
    ld d, c
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, h
    ld h, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    pop af
    ld b, c
    ld b, d
    ld b, d
    ld c, l
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, d
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, e
    ld b, d
    ld c, c
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld b, d
    ld a, $4f
    ld d, b
    ld h, d
    ld a, $40
    ld d, c
    ld h, d
    ld a, $50
    pop af
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ld h, d
    ld a, $49
    ld c, c
    ld c, h
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, h
    pop af
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, e
    ld c, c
    ld d, [hl]
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld b, l
    ld c, h
    ld c, a
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld b, c
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld b, b
    ld b, [hl]
    ld c, e
    ld b, d
    ld d, b
    ldh a, [rNR52]
    ld b, l
    ld a, $4f
    ld b, h
    ld b, d
    ld d, b
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, d
    ld b, [hl]
    ld b, d
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
    ld d, b
    ld b, l
    ld a, $4f
    ld c, l
    ld h, d
    or [hl]
    pop af
    ld d, c
    ld d, h
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld b, l
    ld c, h
    ld c, a
    ld c, e
    ld d, b
    ldh a, [$2f]
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld b, h
    ld c, a
    ld c, h
    ld d, d
    ld c, l
    ld d, b
    pop af
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld b, c
    ld c, h
    ld c, d
    ld b, [hl]
    ld c, e
    ld a, $4b
    ld d, c
    pop af
    ld c, d
    ld a, $49
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld d, b
    ld d, b
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld d, c
    ld d, d
    ld d, b
    ld c, b
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld b, c
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld b, b
    ld c, a
    ld b, d
    ld a, $51
    ld b, d
    ld h, d
    ld b, b
    ld c, a
    ld a, $43
    ld d, c
    pop af
    ld d, h
    ld c, h
    ld c, a
    ld c, b
    ldh a, [$38]
    ld d, b
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    inc b
    ld h, d
    ld b, l
    ld a, $4b
    ld b, c
    ld d, b
    ld h, d
    or [hl]
    pop af
    inc b
    ld h, d
    ld a, $4f
    ld c, d
    ld d, b
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld b, e
    ld d, d
    ld c, c
    ld c, c
    ld d, [hl]
    pop af
    ld b, [hl]
    ld c, e
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ccf
    ld a, $51
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld c, l
    ld b, d
    ld c, c
    ld d, c
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, d
    ld a, $4b
    ld b, c
    ld d, b
    pop af
    ld a, $62
    ld b, l
    ld b, [hl]
    ld b, h
    ld b, l
    ld h, d
    ld c, l
    ld c, a
    ld b, [hl]
    ld b, b
    ld b, d
    ldh a, [$30]
    ld c, h
    ld d, e
    ld b, d
    ld d, b
    ld h, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld d, b
    ld d, h
    ld b, [hl]
    ld b, e
    ld d, c
    ld c, c
    ld d, [hl]
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld b, b
    ld a, $51
    ld b, b
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
    ldh a, [$2f]
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    ld d, b
    ld c, b
    ld d, [hl]
    ld h, d
    or [hl]
    ld h, d
    ld b, c
    ld c, h
    ld d, a
    ld b, d
    ld d, b
    pop af
    ld c, h
    ld b, e
    ld b, e
    ld h, d
    ld a, $49
    ld c, c
    ld h, d
    ld b, c
    ld a, $56
    ldh a, [$2c]
    ld d, c
    ld l, b
    ld h, d
    ld b, e
    ld c, c
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    pop af
    ccf
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld c, a
    ld d, d
    ld c, e
    pop af
    ld c, [hl]
    ld d, d
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld d, [hl]
    ldh a, [$2c]
    ld d, c
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld a, $4b
    ld h, d
    ld b, d
    ld a, $44
    ld c, c
    ld b, d
    ld l, b
    pop af
    ld b, l
    ld b, d
    ld a, $41
    ld h, d
    or [hl]
    ld h, d
    ld a, $62
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    pop af
    ld c, h
    ld b, e
    ld h, d
    ld a, $62
    ld d, b
    ld b, d
    ld c, a
    ld c, l
    ld b, d
    ld c, e
    ld d, c
    ldh a, [$36]
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld d, b
    ld h, d
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld a, $43
    ld d, c
    ld b, d
    ld c, a
    pop af
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld a, $62
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld b, e
    ld c, c
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    pop af
    ld b, e
    ld a, $40
    ld b, d
    ld h, d
    ld c, c
    ld d, d
    ld c, a
    ld b, d
    ld d, b
    ld h, d
    ccf
    ld d, d
    ld b, h
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld b, [hl]
    ld c, a
    ld h, d
    ld b, c
    ld c, h
    ld c, h
    ld c, d
    ldh a, [$36]
    ld c, l
    ld c, a
    ld b, d
    ld a, $41
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ccf
    ld b, [hl]
    ld b, h
    ld b, h
    ld b, d
    ld c, a
    ldh a, [$35]
    ld b, [hl]
    ld c, l
    ld d, b
    ld h, d
    ld b, e
    ld c, c
    ld b, d
    ld d, b
    ld b, l
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ccf
    ld b, d
    ld a, $48
    ldh a, [rNR50]
    ld d, c
    ld d, c
    ld a, $40
    ld c, b
    ld d, b
    ld h, d
    ccf
    ld d, [hl]
    pop af
    ld b, c
    ld c, a
    ld c, h
    ld c, l
    ld c, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, b
    ld c, b
    ld d, d
    ld c, c
    ld c, c
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
    ld a, $46
    ld c, a
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld c, d
    ld b, [hl]
    ld d, b
    ld d, c
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    pop af
    ld b, h
    ld c, c
    ld c, h
    ld d, h
    ld d, b
    ld h, d
    ld c, l
    ld b, [hl]
    ld c, e
    ld c, b
    ld b, [hl]
    ld d, b
    ld b, l
    ld h, d
    ld b, [hl]
    ld c, e
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld a, $4f
    ld c, b
    ldh a, [$33]
    ld c, a
    ld b, d
    ld b, e
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld b, c
    ld a, $4f
    ld c, b
    ld c, e
    ld b, d
    ld d, b
    ld d, b
    pop af
    ld a, $4b
    ld b, c
    ld h, d
    ld d, b
    ld d, d
    ld b, b
    ld c, b
    ld d, b
    ld h, d
    ccf
    ld c, c
    ld c, h
    ld c, h
    ld b, c
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
    ld b, e
    ld a, $4b
    ld b, h
    ld d, b
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, a
    ld c, d
    ld h, d
    ld b, e
    ld c, c
    ld b, d
    ld d, b
    ld b, l
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld b, d
    ld a, $51
    ld b, [hl]
    ld c, e
    ld b, h
    ldh a, [rNR50]
    ld h, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld d, b
    ld d, c
    ld d, d
    ccf
    ccf
    ld c, h
    ld c, a
    ld c, e
    pop af
    ccf
    ld b, [hl]
    ld c, a
    ld b, c
    ldh a, [rNR50]
    ld h, d
    ld b, e
    ld c, c
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    ld c, h
    ld d, h
    ld c, c
    pop af
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld a, $49
    ld c, h
    ld c, e
    ld d, b
    pop af
    or [hl]
    ld h, d
    ld d, b
    ld b, l
    ld a, $4f
    ld c, l
    ld h, d
    ld b, b
    ld c, c
    ld a, $54
    ld d, b
    ldh a, [rNR50]
    ld h, d
    ld c, d
    ld b, [hl]
    ld b, h
    ld c, a
    ld a, $51
    ld c, h
    ld c, a
    ld d, [hl]
    pop af
    ccf
    ld b, [hl]
    ld c, a
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ccf
    ld b, d
    pop af
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld d, e
    ld b, [hl]
    ld c, h
    ld c, c
    ld b, d
    ld c, e
    ld d, c
    ldh a, [$2c]
    ld d, c
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ccf
    ld b, [hl]
    ld b, h
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ld e, [hl]
    pop af
    ld b, c
    ld b, d
    ld a, $41
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, b
    ld b, l
    ld a, $4f
    ld c, l
    ld h, d
    ld b, b
    ld c, c
    ld a, $54
    ld d, b
    pop af
    or [hl]
    ld h, d
    ld a, $62
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld b, e
    ld d, d
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld a, $48
    ldh a, [rNR51]
    ld c, a
    ld b, d
    ld a, $51
    ld b, l
    ld b, d
    ld d, b
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    pop af
    ld b, e
    ld c, a
    ld b, d
    ld b, d
    ld d, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $46
    ld c, a
    ld h, d
    ld d, c
    ld c, h
    pop af
    ld b, c
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
    ldh a, [$35]
    ld c, h
    ld a, $50
    ld d, c
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
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
    ld b, e
    ld b, [hl]
    ld b, d
    ld c, a
    ld d, [hl]
    pop af
    ccf
    ld c, a
    ld b, d
    ld a, $51
    ld b, l
    ldh a, [rNR50]
    ld d, c
    ld d, c
    ld a, $40
    ld c, b
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
    pop af
    ld d, c
    ld b, l
    ld d, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld b, b
    ld c, c
    ld c, h
    ld d, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    pop af
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ldh a, [rNR50]
    ld d, c
    ld d, c
    ld a, $40
    ld c, b
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld d, h
    ld b, l
    ld b, [hl]
    ld c, l
    sbc h
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld b, h
    ld d, b
    ld h, d
    or [hl]
    pop af
    ld c, b
    ld c, e
    ld b, [hl]
    ld b, e
    ld b, d
    sbc h
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld b, b
    ld c, c
    ld a, $54
    ld d, b
    ldh a, [$2f]
    ld b, [hl]
    ld c, b
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, c
    ld a, $4b
    ld b, b
    ld b, d
    pop af
    or [hl]
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ldh a, [$2c]
    ld d, c
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    inc b
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    pop af
    ld c, c
    ld b, d
    ld b, h
    ld d, b
    ld h, d
    or [hl]
    ld h, d
    ld a, $62
    ld c, l
    ld a, $46
    ld c, a
    ld h, d
    ld c, h
    ld b, e
    pop af
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld b, e
    ld d, d
    ld c, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ldh a, [$36]
    ld b, d
    ld b, b
    ld c, a
    ld b, d
    ld d, c
    ld b, d
    ld d, b
    ld h, d
    ld d, b
    ld d, h
    ld b, d
    ld b, d
    ld d, c
    pop af
    ld d, b
    ld a, $4d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld a, $51
    ld d, c
    ld c, a
    ld a, $40
    ld d, c
    pop af
    ccf
    ld d, d
    ld b, h
    ld d, b
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld b, e
    ld c, c
    ld a, $4a
    ld b, d
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld a, $51
    ld b, l
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld b, c
    ld b, d
    ld a, $41
    ld c, c
    ld d, [hl]
    pop af
    ld d, h
    ld b, d
    ld a, $4d
    ld c, h
    ld c, e
    ldh a, [rNR52]
    ld a, $4b
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld d, b
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld a, $49
    pop af
    ld b, l
    ld d, d
    ld c, e
    ld b, c
    ld c, a
    ld b, d
    ld b, c
    ld h, d
    ld d, [hl]
    ld b, d
    ld a, $4f
    ld d, b
    pop af
    ld a, $4b
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, d
    ldh a, [$36]
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    ld h, d
    ld b, h
    ld a, $50
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    pop af
    ld b, e
    ld c, c
    ld c, h
    ld a, $51
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, $46
    ld c, a
    ldh a, [$36]
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    ld h, d
    ld d, h
    ld a, $51
    ld b, d
    ld c, a
    pop af
    ld b, [hl]
    ld c, e
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    pop af
    ld d, b
    ld d, d
    ld c, a
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld b, c
    ld b, d
    ld d, b
    ld b, d
    ld c, a
    ld d, c
    ld d, b
    ldh a, [$2a]
    ld d, d
    ld c, c
    ld c, l
    ld d, b
    ld h, d
    ld d, d
    ld c, l
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
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld b, b
    ld c, b
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld d, b
    ldh a, [$33]
    ld c, c
    ld a, $4b
    ld d, c
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld d, b
    ld c, l
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    pop af
    ld c, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    pop af
    ld c, d
    ld d, d
    ld c, c
    ld d, c
    ld b, [hl]
    ld c, l
    ld c, c
    ld d, [hl]
    ldh a, [$36]
    ld b, d
    ld b, b
    ld c, a
    ld b, d
    ld d, c
    ld b, d
    ld d, b
    ld h, d
    ld d, b
    ld a, $4d
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    pop af
    ld b, l
    ld a, $4f
    ld b, c
    ld b, d
    ld c, e
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ldh a, [$38]
    ld d, b
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld d, c
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld d, d
    ld b, b
    ld c, b
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
    ld d, b
    ld h, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, d
    ld b, e
    ld c, c
    ld d, d
    ld b, [hl]
    ld b, c
    ldh a, [$2a]
    ld c, a
    ld c, h
    ld d, h
    ld d, b
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld c, a
    ld c, h
    ld c, h
    ld d, c
    ld d, b
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld c, a
    ld b, d
    ld a, $41
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ccf
    ld a, $41
    ld h, d
    ccf
    ld a, $49
    ld a, $4b
    ld b, b
    ld b, d
    pop af
    ld b, e
    ld c, h
    ld c, a
    ld b, b
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, h
    ld a, $49
    ld c, b
    pop af
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld l, b
    ld h, d
    ld b, c
    ld a, $4b
    ld b, b
    ld b, [hl]
    ld c, e
    ld b, h
    ldh a, [rNR50]
    ld h, d
    ld d, b
    ld c, l
    ld b, [hl]
    ld c, a
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    pop af
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld a, $62
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    pop af
    ld c, h
    ld c, c
    ld b, c
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld b, d
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld d, c
    ld d, b
    ld h, d
    ld d, b
    ld d, d
    ld b, b
    ld c, b
    pop af
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
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
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld d, c
    ld d, b
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ccf
    ld b, d
    pop af
    ld d, d
    ld d, b
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    pop af
    ld a, $62
    ld b, b
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld b, b
    ld b, [hl]
    ld c, e
    ld b, d
    ldh a, [$37]
    ld c, a
    ld a, $53
    ld b, d
    ld c, c
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
    pop af
    ld a, $62
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, l
    ld c, c
    ld a, $4b
    ld d, c
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld b, c
    ld d, b
    ldh a, [rNR52]
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld b, l
    ld c, h
    ld d, b
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld d, c
    ld b, d
    ld c, e
    ld d, c
    ld a, $40
    ld c, c
    ld b, d
    ld d, b
    ldh a, [$27]
    ld b, [hl]
    ld d, b
    ld d, b
    ld c, h
    ld c, c
    ld d, e
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld b, c
    ld b, [hl]
    ld b, h
    ld b, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld a, $40
    ld b, [hl]
    ld b, c
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    inc bc
    ld h, d
    ccf
    ld d, d
    ld b, c
    ld d, b
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld c, b
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld b, [hl]
    ld c, a
    ld h, d
    ld d, c
    ld b, d
    ld b, d
    ld d, c
    ld b, l
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
    ldh a, [$36]
    ld c, [hl]
    ld d, d
    ld b, d
    ld b, d
    ld d, a
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld d, c
    ld b, l
    ld c, h
    ld c, a
    ld c, e
    ld d, [hl]
    ld h, d
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, d
    ld d, b
    ldh a, [rNR50]
    ld h, d
    ld c, d
    ld b, [hl]
    ld d, b
    ld b, b
    ld b, l
    ld b, [hl]
    ld b, d
    ld d, e
    ld c, h
    ld d, d
    ld d, b
    pop af
    ld c, d
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld a, $49
    ld h, d
    ld b, b
    ld c, a
    ld b, d
    ld a, $51
    ld d, d
    ld c, a
    ld b, d
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld c, d
    ld d, d
    ld b, b
    ld d, d
    ld d, b
    ld h, d
    ld b, b
    ld c, h
    ld c, e
    ld d, c
    ld a, $46
    ld c, e
    ld d, b
    pop af
    ld b, c
    ld b, [hl]
    ld b, h
    ld b, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld b, d
    ld c, e
    ld d, a
    ld d, [hl]
    ld c, d
    ld b, d
    ld d, b
    ldh a, [$37]
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, b
    ld a, $51
    ld b, d
    ld c, a
    ld c, l
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, $4f
    pop af
    ld b, c
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, h
    ld c, a
    ld c, h
    ld d, h
    ld h, d
    ld d, c
    ld c, h
    pop af
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld a, $62
    ld c, d
    ld c, h
    ld d, c
    ld b, l
    ldh a, [$36]
    ld b, [hl]
    ld c, e
    ld b, b
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    pop af
    ld d, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld b, h
    ld c, a
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld e, [hl]
    ld h, d
    ld b, [hl]
    ld d, c
    pop af
    ld b, l
    ld a, $51
    ld b, d
    ld d, b
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ldh a, [$33]
    ld c, h
    ld d, h
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld b, l
    ld a, $49
    ld c, c
    ld d, d
    sbc h
    pop af
    ld b, b
    ld b, [hl]
    ld c, e
    ld c, h
    ld b, h
    ld b, d
    ld c, e
    ld b, [hl]
    ld b, b
    ld h, d
    ld b, d
    ld b, e
    ld b, e
    ld b, d
    ld b, b
    ld d, c
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld d, h
    ld b, d
    ld b, d
    ld b, c
    sbc h
    ld d, c
    ld c, h
    ld c, l
    ld h, d
    ld d, b
    ld d, d
    ld b, b
    ld c, b
    ld d, b
    pop af
    ld d, d
    ld c, l
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, a
    ld b, h
    ld d, [hl]
    ld h, d
    or [hl]
    ld h, d
    ld b, d
    ld c, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ldh a, [$29]
    ld b, [hl]
    ld c, e
    ld b, c
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
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
    ld a, $40
    ld d, d
    ld d, c
    ld b, d
    pop af
    ld d, b
    ld b, d
    ld c, e
    ld d, b
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, b
    ld c, d
    ld b, d
    ld c, c
    ld c, c
    ldh a, [$33]
    ld a, $4f
    ld a, $49
    ld d, [hl]
    ld d, a
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
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
    ld b, c
    ld b, d
    ld a, $41
    ld c, c
    ld d, [hl]
    pop af
    ld c, b
    ld b, [hl]
    ld d, b
    ld d, b
    ldh a, [$35]
    ld b, d
    ld c, l
    ld b, d
    ld c, c
    ld d, b
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
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
    ld b, l
    ld a, $4f
    ld b, c
    pop af
    ld d, b
    ld b, l
    ld b, d
    ld c, c
    ld c, c
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, b
    ld c, d
    ld a, $49
    ld c, c
    ld e, [hl]
    pop af
    ccf
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld b, a
    ld a, $54
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld b, e
    ld d, d
    ld c, c
    ldh a, [$30]
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld a, $62
    ld d, h
    ld b, d
    ld b, [hl]
    ld c, a
    ld b, c
    pop af
    ld d, b
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, c
    pop af
    ld b, e
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, b
    ldh a, [$36]
    ld d, d
    ld b, b
    ld c, b
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld d, c
    ld a, $46
    ld c, c
    sbc h
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld c, d
    ld c, h
    ld d, d
    ld d, c
    ld b, l
    ldh a, [rNR50]
    ld h, d
    ld d, b
    ld b, l
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld c, l
    ld c, a
    ld c, h
    ld d, c
    ld b, d
    ld b, b
    ld d, c
    ld d, b
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ccf
    ld b, d
    ld c, c
    ld c, c
    ld d, [hl]
    ldh a, [$28]
    ld a, $40
    ld b, l
    ld h, d
    ld d, c
    ld b, d
    ld c, e
    ld d, c
    ld a, $40
    ld c, c
    ld b, d
    pop af
    ld b, l
    ld a, $50
    ld h, d
    ld a, $62
    ld d, b
    ld c, l
    ld b, d
    ld b, b
    ld b, [hl]
    ld b, e
    ld b, [hl]
    ld b, b
    pop af
    ld b, e
    ld d, d
    ld c, e
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ldh a, [rNR52]
    ld c, a
    ld b, d
    ld a, $51
    ld b, d
    ld d, b
    ld h, d
    ld a, $62
    ld d, e
    ld b, [hl]
    ld c, h
    ld c, c
    ld b, d
    ld c, e
    ld d, c
    pop af
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld b, l
    ld d, d
    ld b, h
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ldh a, [$33]
    ld c, a
    ld c, h
    ld d, c
    ld c, a
    ld d, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, d
    ld d, [hl]
    ld b, d
    ld d, b
    pop af
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    ld h, d
    ld a, $62
    ld c, c
    ld a, $4f
    ld b, h
    ld b, d
    pop af
    ld b, e
    ld b, [hl]
    ld b, d
    ld c, c
    ld b, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, e
    ld b, [hl]
    ld d, b
    ld b, [hl]
    ld c, h
    ld c, e
    ldh a, [rNR50]
    ld d, c
    ld d, c
    ld a, $40
    ld c, b
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld a, $62
    ld b, h
    ld c, a
    ld c, h
    ld d, d
    ld c, l
    pop af
    or [hl]
    ld h, d
    ld b, b
    ld d, d
    ld d, c
    ld d, b
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
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
    ld b, b
    ld c, c
    ld a, $54
    ld d, b
    ldh a, [$33]
    ld a, $4f
    ld a, $49
    ld d, [hl]
    ld d, a
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
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
    ld d, b
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ldh a, [rNR52]
    ld b, l
    ld a, $4f
    ld b, h
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
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
    ccf
    ld b, [hl]
    ld b, h
    ld h, d
    ld b, l
    ld c, h
    ld c, a
    ld c, e
    ldh a, [$38]
    ld c, e
    ld c, l
    ld c, a
    ld c, h
    ld d, c
    ld b, d
    ld b, b
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld b, a
    ld c, h
    ld b, [hl]
    ld c, e
    ld d, c
    ld d, b
    pop af
    ld a, $4f
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld d, h
    ld b, d
    ld a, $48
    ld c, e
    ld b, d
    ld d, b
    ld d, b
    ldh a, [$27]
    ld b, [hl]
    ld b, h
    ld d, b
    ld h, d
    ld b, b
    ld a, $53
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    pop af
    ld b, [hl]
    ld c, e
    ld h, d
    ld a, $62
    ld b, c
    ld a, $4f
    ld c, b
    ld h, d
    ld b, l
    ld d, d
    ld c, d
    ld b, [hl]
    ld b, c
    pop af
    ld b, l
    ld c, h
    ld c, d
    ld b, d
    ldh a, [$2f]
    ld c, h
    ld d, e
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, l
    ld c, c
    ld a, $56
    pop af
    ld c, l
    ld c, a
    ld a, $4b
    ld c, b
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld c, d
    ld a, $44
    ld b, [hl]
    ld b, b
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld c, c
    ld c, c
    ld d, b
    ldh a, [$37]
    ld c, h
    ld c, h
    ld h, d
    ld b, e
    ld a, $51
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, e
    ld c, c
    ld d, [hl]
    pop af
    ccf
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld b, d
    ld c, e
    ld b, h
    ld d, c
    ld b, l
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld b, b
    ld c, a
    ld b, d
    ld b, c
    ld b, [hl]
    ccf
    ld c, c
    ld b, d
    ldh a, [$39]
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld c, [hl]
    ld d, d
    ld b, [hl]
    ld b, b
    ld c, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld d, c
    ld b, d
    ld b, c
    pop af
    or [hl]
    ld h, d
    ld b, b
    ld d, d
    ld c, e
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ldh a, [$36]
    ld c, d
    ld a, $4f
    ld d, c
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld e, [hl]
    ld h, d
    ld c, c
    ld a, $40
    ld c, b
    ld d, b
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, b
    ld a, $50
    ld d, c
    pop af
    ccf
    ld b, [hl]
    ld b, h
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld c, c
    ld c, c
    ld d, b
    ldh a, [rNR52]
    ld a, $51
    ld b, b
    ld b, l
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
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
    ld d, c
    ld b, d
    ld c, e
    ld d, c
    ld a, $40
    ld c, c
    ld b, d
    ld d, b
    ldh a, [$2b]
    ld d, d
    ld c, e
    ld d, c
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld c, c
    ld a, $4f
    ld b, h
    ld b, d
    ld h, d
    ld b, d
    ld d, [hl]
    ld b, d
    ld h, d
    or [hl]
    ld h, d
    ld b, e
    ld a, $50
    ld d, c
    pop af
    ld d, c
    ld d, h
    ld c, h
    ld h, d
    ld c, c
    ld b, d
    ld b, h
    ld d, b
    ldh a, [$35]
    ld b, d
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    ld h, d
    ld b, c
    ld b, d
    ld a, $41
    pop af
    ccf
    ld b, d
    ld a, $50
    ld d, c
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    pop af
    ld a, $50
    ld h, d
    ld d, b
    ld c, c
    ld a, $53
    ld b, d
    ld d, b
    ldh a, [$37]
    ld c, a
    ld a, $46
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ld b, l
    ld a, $4f
    ld b, c
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld a, $51
    ld d, c
    ld a, $46
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld b, d
    ld c, e
    ld b, h
    ld d, c
    ld b, l
    ldh a, [$38]
    ld d, b
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld d, h
    ld a, $4b
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    pop af
    ld b, b
    ld a, $50
    ld d, c
    ld h, d
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld c, c
    ld c, c
    ld d, b
    ldh a, [$30]
    ld b, [hl]
    ld d, b
    ld b, b
    ld b, l
    ld b, [hl]
    ld b, d
    ld d, e
    ld c, h
    ld d, d
    ld d, b
    ld h, d
    or [hl]
    pop af
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, l
    ld c, c
    ld a, $56
    pop af
    ld d, c
    ld c, a
    ld b, [hl]
    ld b, b
    ld c, b
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, c
    ld c, a
    ld a, $4d
    ld d, b
    ldh a, [rNR50]
    ld h, d
    ld b, c
    ld b, d
    ld a, $41
    ld c, c
    ld d, [hl]
    ld h, d
    ccf
    ld a, $49
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    pop af
    ld d, b
    ld c, e
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $4b
    pop af
    ld b, d
    ld d, [hl]
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld b, d
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ldh a, [rNR50]
    ld h, d
    ld c, e
    ld a, $51
    ld d, d
    ld c, a
    ld a, $49
    ld h, d
    ccf
    ld c, h
    ld c, a
    ld c, e
    pop af
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld b, d
    ld c, a
    ldh a, [rNR50]
    ld h, d
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld b, e
    ld d, d
    ld c, c
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    pop af
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, l
    ld c, h
    ld c, a
    ld c, e
    ld d, b
    ld h, d
    or [hl]
    pop af
    ld c, c
    ld b, d
    ld b, h
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, $62
    ld b, h
    ld c, h
    ld a, $51
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld b, c
    ld b, d
    ld c, e
    ld d, b
    ld b, d
    ld h, d
    ld c, l
    ld b, d
    ld c, c
    ld d, c
    pop af
    ld a, $40
    ld d, c
    ld d, b
    ld h, d
    ld a, $50
    ld h, d
    ld c, e
    ld a, $51
    ld d, d
    ld c, a
    ld a, $49
    pop af
    ld a, $4f
    ld c, d
    ld c, h
    ld c, a
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld b, e
    ld c, c
    ld a, $46
    ld c, c
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld a, $f1
    ld c, d
    ld b, d
    ld d, c
    ld a, $49
    ld h, d
    ccf
    ld a, $49
    ld c, c
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld l, b
    pop af
    ccf
    ld b, [hl]
    ld b, h
    ld b, h
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld a, $4b
    ld h, d
    ld a, $62
    ld c, d
    ld a, $4b
    ldh a, [$38]
    ld d, b
    ld b, d
    ld d, b
    ld h, d
    ld a, $62
    ld d, b
    ld b, b
    ld d, [hl]
    ld d, c
    ld b, l
    ld b, d
    pop af
    ld a, $50
    ld h, d
    ld d, c
    ld a, $49
    ld c, c
    ld h, d
    ld a, $50
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, h
    ld d, h
    ld c, e
    pop af
    ld d, c
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, l
    ld b, d
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ldh a, [$2b]
    ld a, $50
    ld h, d
    ld a, $40
    ld b, l
    ld b, [hl]
    ld b, d
    ld d, e
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    ld d, d
    ld d, c
    ld c, d
    ld c, h
    ld d, b
    ld d, c
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    pop af
    ld d, b
    ld d, h
    ld b, [hl]
    ld b, e
    ld d, c
    ld c, e
    ld b, d
    ld d, b
    ld d, b
    ldh a, [$31]
    ld c, h
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld h, d
    ld b, b
    ld c, c
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld e, [hl]
    pop af
    ccf
    ld d, d
    ld d, c
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld d, h
    ld b, d
    ld a, $4d
    ld c, h
    ld c, e
    ld d, b
    ld h, d
    ld d, h
    ld b, d
    ld c, c
    ld c, c
    ldh a, [rNR52]
    ld c, h
    ld c, d
    ccf
    ld b, [hl]
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    pop af
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, b
    ld d, d
    ld c, l
    ld b, d
    ld c, a
    sbc h
    pop af
    ld b, l
    ld d, d
    ld c, d
    ld a, $4b
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld b, d
    ld c, e
    ld b, h
    ld d, c
    ld b, l
    ldh a, [rNR52]
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    pop af
    ld a, $4f
    ld c, d
    ld c, h
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld c, e
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld c, a
    ld b, d
    ld c, d
    ld c, h
    ld d, e
    ld b, d
    ld b, c
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld b, [hl]
    ld b, h
    ld b, h
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    ld b, c
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ccf
    ld d, d
    ld d, c
    pop af
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld d, b
    ld c, d
    ld a, $4f
    ld d, c
    ldh a, [rNR50]
    ld h, d
    ld b, l
    ld d, [hl]
    ccf
    ld c, a
    ld b, [hl]
    ld b, c
    ld h, d
    ld b, c
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    pop af
    ld c, d
    ld a, $4b
    ld h, d
    or [hl]
    ld h, d
    ccf
    ld b, d
    ld a, $50
    ld d, c
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld c, a
    ld b, d
    ld a, $49
    ld h, d
    ld b, [hl]
    ld b, c
    ld b, d
    ld c, e
    ld d, c
    ld b, [hl]
    ld d, c
    ld d, [hl]
    pop af
    ld d, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld c, e
    ld b, d
    ld a, $51
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    ld a, $4f
    ld c, d
    ld c, h
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, d
    ld c, e
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld c, e
    ldh a, [rNR50]
    ld h, d
    ld b, l
    ld d, [hl]
    ccf
    ld c, a
    ld b, [hl]
    ld b, c
    ld h, d
    ld b, c
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    pop af
    ld a, $4b
    ld h, d
    ld b, d
    ld a, $44
    ld c, c
    ld b, d
    ld h, d
    or [hl]
    ld h, d
    ld a, $62
    ld c, c
    ld b, [hl]
    ld c, h
    ld c, e
    ldh a, [rNR50]
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld a, $49
    ld c, c
    sbc h
    ld c, a
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    pop af
    ld c, e
    ld a, $51
    ld d, d
    ld c, a
    ld a, $49
    ld h, d
    ccf
    ld c, h
    ld c, a
    ld c, e
    pop af
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld b, l
    ld c, h
    ccf
    ccf
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    pop af
    ld d, b
    ld b, b
    ld a, $4f
    ld b, d
    ld h, d
    ld c, l
    ld b, d
    ld c, h
    ld c, l
    ld c, c
    ld b, d
    ldh a, [rNR50]
    ld h, d
    ld b, c
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    pop af
    ld d, c
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    ld c, a
    ld b, [hl]
    ld d, b
    ld b, d
    ld c, e
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
    ld b, c
    ld b, d
    ld a, $41
    ldh a, [$2c]
    ld d, c
    ld l, b
    ld h, d
    ld b, e
    ld b, d
    ld a, $4f
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    pop af
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, b
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, c
    ld c, h
    ld b, d
    ld d, b
    ld c, e
    ld h, a
    pop af
    ld b, e
    ld b, d
    ld b, d
    ld c, c
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld c, l
    ld a, $46
    ld c, e
    ldh a, [$27]
    ld c, h
    ld d, a
    ld b, d
    ld d, b
    ld h, d
    ld a, $49
    ld c, c
    ld h, d
    ld b, c
    ld a, $56
    pop af
    ld b, [hl]
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld b, l
    ld a, $49
    ld b, e
    ld h, d
    ld c, a
    ld c, h
    ld d, c
    ld d, c
    ld b, d
    ld b, c
    pop af
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, c
    ld c, c
    ld b, d
    ld b, c
    pop af
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ccf
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    pop af
    ld c, l
    ld c, a
    ld b, d
    ld d, e
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld b, c
    ld b, d
    ld b, b
    ld a, $56
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld d, b
    ld b, l
    ld b, d
    ld c, c
    ld c, c
    pop af
    ld c, a
    ld b, d
    ld d, b
    ld b, d
    ld c, d
    ccf
    ld c, c
    ld b, d
    ld d, b
    ld h, d
    ld a, $f1
    ld b, l
    ld d, d
    ld c, d
    ld a, $4b
    ld h, d
    ld b, e
    ld a, $40
    ld b, d
    ldh a, [$2e]
    ld c, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld c, a
    ld b, d
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    ld b, c
    pop af
    ld a, $50
    ld h, d
    ld a, $62
    ld d, a
    ld c, h
    ld c, d
    ccf
    ld b, [hl]
    ld b, d
    ld e, [hl]
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    pop af
    ld c, e
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, a
    ld b, d
    ld d, b
    ldh a, [$35]
    ld b, d
    ld a, $49
    ld h, d
    ld b, [hl]
    ld b, c
    ld b, d
    ld c, e
    ld d, c
    ld b, [hl]
    ld d, c
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld d, d
    ld c, e
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld b, c
    ld d, d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld d, b
    ld b, l
    ld a, $41
    ld c, h
    ld d, h
    sbc h
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld a, $40
    ld b, [hl]
    ld b, c
    ld b, [hl]
    ld b, b
    ld h, d
    ld d, b
    ld a, $49
    ld b, [hl]
    ld d, e
    ld a, $f1
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, c
    ld b, [hl]
    ld d, b
    ld d, b
    ld c, h
    ld c, c
    ld d, e
    ld b, d
    pop af
    ld a, $4b
    ld d, [hl]
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ldh a, [rNR50]
    ld h, d
    ld d, b
    ld d, h
    ld a, $4a
    ld c, l
    ld h, d
    ld c, d
    ld d, d
    ld b, c
    pop af
    ld b, [hl]
    ld c, e
    ld b, e
    ld b, d
    ld d, b
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld d, b
    ld c, l
    ld b, [hl]
    ld c, a
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld b, d
    ld a, $41
    ldh a, [$29]
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    ld a, $46
    ld c, a
    ld h, d
    ld c, c
    ld b, d
    ld a, $53
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $f1
    ld d, b
    ld d, c
    ld c, a
    ld b, d
    ld a, $48
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ldh a, [$2f]
    ld c, h
    ld d, b
    ld d, c
    ld h, d
    ld d, b
    ld c, l
    ld b, [hl]
    ld c, a
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld b, e
    ld d, d
    ld d, b
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld b, h
    ld b, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ldh a, [$36]
    ld d, c
    ld c, a
    ld a, $4b
    ld b, h
    ld b, d
    ld c, c
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld b, h
    ld a, $4f
    ld c, d
    ld b, d
    ld c, e
    ld d, c
    ldh a, [$2a]
    ld d, d
    ld b, [hl]
    ld b, c
    ld b, d
    ld d, b
    ld h, d
    ld b, c
    ld b, d
    ld a, $41
    pop af
    ld d, b
    ld c, l
    ld b, [hl]
    ld c, a
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    ld d, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld d, h
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ldh a, [$35]
    ld b, [hl]
    ld b, c
    ld b, d
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld a, $62
    ld b, l
    ld c, h
    ld c, a
    ld d, b
    ld b, d
    ld h, d
    or [hl]
    pop af
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld d, b
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, d
    ld b, [hl]
    ld b, d
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
    ld c, c
    ld a, $4b
    ld b, b
    ld b, d
    ldh a, [$2b]
    ld a, $50
    ld h, d
    ld c, a
    ld b, d
    ld d, c
    ld a, $46
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld b, l
    ld b, [hl]
    ld b, h
    ld b, l
    ld h, d
    inc l
    ld sp, $6237
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    pop af
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld a, $49
    ld b, [hl]
    ld d, e
    ld b, d
    ldh a, [$35]
    ld b, d
    ld d, b
    ld d, d
    ld c, a
    ld c, a
    ld b, d
    ld b, b
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld a, $50
    ld h, d
    ld a, $f1
    ld d, a
    ld c, h
    ld c, d
    ccf
    ld b, [hl]
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld c, a
    ld d, e
    ld b, d
    pop af
    ld b, l
    ld a, $4f
    ld b, c
    ld h, d
    ld c, c
    ld a, $3f
    ld c, h
    ld c, a
    ldh a, [rNR50]
    ld d, c
    ld d, c
    ld a, $40
    ld c, b
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    pop af
    ld a, $62
    ld d, b
    ld d, h
    ld c, h
    ld c, a
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld b, d
    ld a, $40
    ld b, l
    pop af
    ld c, h
    ld b, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld b, $62
    ld b, l
    ld a, $4b
    ld b, c
    ld d, b
    ldh a, [rNR52]
    ld c, a
    ld b, d
    ld a, $51
    ld b, d
    ld b, c
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    pop af
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld d, b
    ld e, [hl]
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld a, $f1
    ld b, l
    ld b, [hl]
    ld b, h
    ld b, l
    ld h, d
    inc l
    ld sp, $f037
    ld h, $3e
    ld c, e
    ld h, d
    ld b, c
    ld b, [hl]
    ld d, b
    ld b, h
    ld d, d
    ld b, [hl]
    ld d, b
    ld b, d
    ld h, d
    ld a, $50
    pop af
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, a
    ld b, d
    ld a, $51
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    or [hl]
    pop af
    ld c, d
    ld b, [hl]
    ld c, d
    ld b, [hl]
    ld b, b
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld c, d
    ld c, h
    ld d, e
    ld b, d
    ldh a, [$2f]
    ld b, [hl]
    ld c, b
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, d
    ld a, $51
    pop af
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld a, $4f
    ld b, d
    pop af
    ld c, l
    ld c, a
    ld b, d
    ld b, b
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
    ld h, d
    or [hl]
    ld h, d
    ld d, b
    ld b, l
    ld b, [hl]
    ld c, e
    ld d, [hl]
    ldh a, [rNR50]
    ld c, e
    ld h, d
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld c, l
    ld b, [hl]
    ld c, a
    ld b, [hl]
    ld d, c
    pop af
    ld c, l
    ld c, h
    ld d, b
    ld d, b
    ld b, d
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $f1
    ld d, h
    ld b, [hl]
    ld d, a
    ld a, $4f
    ld b, c
    ld l, b
    ld h, d
    ld d, h
    ld a, $4b
    ld b, c
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ld b, b
    ld a, $4b
    ld b, c
    ld c, c
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    pop af
    ld c, a
    ld b, d
    ld c, d
    ld a, $46
    ld c, e
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, d
    ld c, e
    ld d, c
    ld b, [hl]
    ld c, c
    pop af
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, d
    ld d, b
    ldh a, [$28]
    ld c, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld a, $4b
    pop af
    ld b, d
    ld b, d
    ld c, a
    ld b, [hl]
    ld b, d
    ld h, d
    ld c, e
    ld c, h
    ld b, [hl]
    ld d, b
    ld b, d
    ldh a, [rNR50]
    ld c, e
    ld h, d
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld c, l
    ld b, [hl]
    ld c, a
    ld b, [hl]
    ld d, c
    pop af
    ld b, l
    ld a, $50
    ld h, d
    ld c, l
    ld c, h
    ld d, b
    ld d, b
    ld b, d
    ld d, b
    ld d, b
    ld b, d
    ld b, c
    pop af
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, h
    ld c, h
    ld c, h
    ld b, c
    ld b, d
    ld c, e
    ld h, d
    ld c, d
    ld a, $50
    ld c, b
    ldh a, [$28]
    ld d, l
    ld c, l
    ld c, c
    ld c, h
    ld b, c
    ld b, d
    ld d, b
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    pop af
    ld a, $4b
    ld b, h
    ld b, d
    ld c, a
    ld b, d
    ld b, c
    ldh a, [rNR50]
    ccf
    ld d, b
    ld c, h
    ld c, a
    ccf
    ld d, b
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    pop af
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld c, a
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, d
    ld b, [hl]
    ld c, a
    ld c, a
    ld c, h
    ld c, a
    ldh a, [$2f]
    ld b, [hl]
    ld b, e
    ld b, d
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ccf
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $4f
    ld c, d
    ld c, h
    ld c, a
    ld h, d
    or [hl]
    ld h, d
    ld b, [hl]
    ld d, c
    pop af
    ld c, a
    ld c, h
    ld a, $4a
    ld d, b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
    ldh a, [$2a]
    ld c, a
    ld a, $3f
    ld d, b
    ld h, d
    or [hl]
    ld h, d
    ld c, l
    ld a, $4f
    ld a, $49
    ld d, [hl]
    ld d, a
    ld b, d
    ld d, b
    pop af
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    pop af
    ld c, l
    ld a, $50
    ld d, b
    ld b, d
    ld d, b
    ldh a, [rNR50]
    ld h, d
    ld b, b
    ld c, c
    ld a, $56
    ld h, d
    ld b, c
    ld c, h
    ld c, c
    ld c, c
    pop af
    ccf
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, e
    ld b, d
    ldh a, [rNR50]
    ld h, d
    ld b, c
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    pop af
    ld b, b
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld c, a
    ld d, d
    ld b, b
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    pop af
    ld c, d
    ld b, d
    ld d, c
    ld a, $49
    ldh a, [rNR50]
    ld h, d
    ld b, b
    ld c, a
    ld b, d
    ld a, $51
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld b, b
    ld c, a
    ld b, d
    ld a, $51
    ld b, d
    ld b, c
    pop af
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ldh a, [$29]
    ld a, $50
    ld b, l
    ld b, [hl]
    ld c, h
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, b
    ld c, h
    pop af
    ld c, d
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld c, l
    ld a, $50
    ld d, b
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    pop af
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, b
    ld a, $4a
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, e
    ld b, d
    ldh a, [$2c]
    ld d, c
    ld d, b
    ld h, d
    ccf
    ld b, d
    ld b, d
    ld c, e
    ld h, d
    ld d, b
    ld a, $46
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $4b
    ld h, d
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    pop af
    ld b, h
    ld b, d
    ld c, e
    ld b, [hl]
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld a, $4a
    ld c, l
    ldh a, [$2f]
    ld a, $50
    ld d, c
    ld h, d
    ld d, b
    ld d, d
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, h
    ld a, $4f
    pop af
    ld c, a
    ld c, h
    ccf
    ld c, h
    ld d, c
    ld h, d
    ld c, d
    ld a, $41
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    pop af
    ld a, $4b
    ld h, d
    ld a, $4b
    ld b, b
    ld b, [hl]
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ldh a, [$2f]
    ld d, d
    ld c, a
    ld c, b
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld a, $f1
    ld c, l
    ld c, h
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, l
    ld b, [hl]
    ld b, c
    ld b, d
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld b, [hl]
    ld b, c
    ld b, d
    ld c, e
    ld d, c
    ld b, [hl]
    ld d, c
    ld d, [hl]
    ldh a, [$2f]
    ld b, [hl]
    ld b, e
    ld b, d
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ccf
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ccf
    ld a, $49
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    pop af
    ld b, d
    ld c, e
    ld b, d
    ld c, a
    ld b, h
    ld d, [hl]
    ldh a, [$2c]
    ld d, c
    ld l, b
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, l
    ld c, h
    ld d, b
    ld b, d
    ld b, c
    pop af
    ld c, h
    ld b, e
    ld h, d
    ld a, $4b
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, a
    ld b, h
    ld d, [hl]
    pop af
    ld b, b
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    or [hl]
    ld h, d
    ld c, d
    ld a, $44
    ld c, d
    ld a, $f0
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, l
    ld c, h
    ld d, b
    ld b, d
    ld b, c
    pop af
    ld c, h
    ld b, e
    ld h, d
    ld a, $4b
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, a
    ld b, h
    ld d, [hl]
    pop af
    ld b, b
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    or [hl]
    ld h, d
    ld b, [hl]
    ld b, b
    ld b, d
    ldh a, [rNR50]
    ld d, c
    ld d, c
    ld a, $40
    ld c, b
    ld d, b
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld c, h
    ld c, e
    ld b, d
    pop af
    ld d, h
    ld b, l
    ld c, h
    ld h, d
    ld d, c
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld d, c
    ld b, d
    ld a, $49
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld a, $50
    ld d, d
    ld c, a
    ld b, d
    ldh a, [rNR50]
    ld h, d
    ld c, b
    ld c, e
    ld b, d
    ld a, $41
    ld b, d
    ld b, c
    ld h, d
    ld b, c
    ld c, a
    ld b, [hl]
    ld b, d
    ld b, c
    pop af
    ld b, b
    ld c, c
    ld a, $56
    ld h, d
    ld b, c
    ld c, h
    ld c, c
    ld c, c
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    pop af
    ld b, b
    ld a, $4a
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, e
    ld b, d
    ldh a, [rNR50]
    ld h, d
    ld d, b
    ld d, c
    ld a, $40
    ld c, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, a
    ld c, h
    ld b, b
    ld c, b
    pop af
    ccf
    ld c, a
    ld b, [hl]
    ld b, b
    ld c, b
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld b, b
    ld a, $4a
    ld b, d
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, e
    ld b, d
    ldh a, [rNR50]
    ld h, d
    ld d, b
    ld d, c
    ld a, $51
    ld d, d
    ld b, d
    ld h, d
    ld c, d
    ld a, $41
    ld b, d
    pop af
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld c, a
    ld c, h
    ld b, b
    ld c, b
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    pop af
    ld b, b
    ld a, $4a
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, e
    ld b, d
    ldh a, [$38]
    ld d, b
    ld d, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld h, d
    ld b, c
    ld c, h
    ld c, a
    ld c, d
    ld a, $4b
    ld d, c
    pop af
    or [hl]
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld a, $f1
    ld c, e
    ld c, h
    ld c, a
    ld c, d
    ld a, $49
    ld h, d
    ld c, a
    ld c, h
    ld b, b
    ld c, b
    ldh a, [$30]
    ld a, $41
    ld b, d
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, $4b
    pop af
    ld b, d
    ld c, c
    ld a, $50
    ld d, c
    ld b, [hl]
    ld b, b
    ld h, d
    or [hl]
    ld h, d
    ld b, c
    ld d, d
    ld c, a
    ld a, $3f
    ld c, c
    ld b, d
    pop af
    ld c, d
    ld b, d
    ld d, c
    ld a, $49
    ldh a, [$37]
    ld c, a
    ld b, [hl]
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, d
    ld c, e
    ld b, [hl]
    ld d, c
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    ld d, c
    ld c, h
    ld h, d
    ld c, a
    ld d, d
    ld c, c
    ld b, d
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ldh a, [$37]
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
    ld h, d
    ld d, c
    ld c, a
    ld d, d
    ld b, d
    pop af
    ld b, [hl]
    ld b, c
    ld b, d
    ld c, e
    ld d, c
    ld b, [hl]
    ld d, c
    ld d, [hl]
    ld h, d
    ld c, h
    ld b, e
    pop af
    daa
    ld c, a
    ld a, $40
    ld c, h
    cpl
    ld c, h
    ld c, a
    ld b, c
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    pop af
    ld c, l
    ld c, c
    ld a, $4b
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, a
    ld b, d
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    daa
    ld b, d
    ld d, b
    ld d, c
    ld c, a
    ld d, d
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ldh a, [rNR50]
    ld c, e
    ld h, d
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld b, c
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    pop af
    ld c, c
    ld c, h
    ld c, a
    ld b, c
    ld e, [hl]
    ld h, d
    ld c, a
    ld d, d
    ld c, c
    ld b, d
    ld c, a
    ld h, d
    ld c, h
    ld b, e
    pop af
    ld a, $49
    ld c, c
    ld h, d
    ld b, c
    ld b, d
    ld d, b
    ld d, c
    ld c, a
    ld d, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ldh a, [$37]
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld c, c
    ld c, h
    ld c, a
    ld b, c
    pop af
    ld b, b
    ld c, h
    ld c, e
    ld d, c
    ld c, a
    ld c, h
    ld c, c
    ld d, b
    ld h, d
    ld a, $49
    ld c, c
    pop af
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, h
    ld d, d
    ld c, a
    ld b, b
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    pop af
    ld a, $49
    ld c, c
    ld h, d
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ldh a, [rNR50]
    ld d, c
    ld d, c
    ld a, $46
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
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
    ld c, l
    ld b, d
    ld a, $4f
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    pop af
    ld b, d
    ld d, e
    ld c, h
    ld c, c
    ld d, d
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ldh a, [$28]
    ld d, l
    ld b, [hl]
    ld d, b
    ld d, c
    ld d, b
    ld h, d
    ccf
    ld b, d
    ld d, [hl]
    ld c, h
    ld c, e
    ld b, c
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    pop af
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld d, b
    ld c, l
    ld a, $40
    ld b, d
    ldh a, [rNR50]
    ld c, e
    ld h, d
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld c, c
    ld c, h
    ld c, a
    ld b, c
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    pop af
    ld d, c
    ld c, a
    ld b, [hl]
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, a
    ld d, d
    ld c, c
    ld b, d
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, l
    ld d, d
    ld c, d
    ld a, $4b
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ldh a, [$37]
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
    ld h, d
    ld d, c
    ld c, a
    ld d, d
    ld b, d
    pop af
    ld b, [hl]
    ld b, c
    ld b, d
    ld c, e
    ld d, c
    ld b, [hl]
    ld d, c
    ld d, [hl]
    pop af
    ld c, h
    ld b, e
    ld h, d
    jr nc, jr_04d_767e

    ld c, a
    ld d, d
    ld b, c
    ld a, $3e
    ld d, b
    ldh a, [$37]
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld c, c
    ld c, h
    ld c, a
    ld b, c
    pop af
    ld b, b
    ld c, h
    ld c, e
    ld d, c
    ld c, a
    ld c, h
    ld c, c
    ld d, b
    ld h, d
    ld a, $49
    ld c, c
    pop af
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ldh a, [rNR50]
    ld c, e
    ld h, d
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld c, c
    ld c, h
    ld c, a
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    pop af
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    ld h, d
    ccf
    ld b, d

jr_04d_767e:
    ld d, c
    ld d, h
    ld b, d
    ld b, d
    ld c, e
    pop af
    ld c, a
    ld b, d
    ld a, $49
    ld b, [hl]
    ld d, c
    ld d, [hl]
    ld h, d
    or [hl]
    ld h, d
    ld b, e
    ld a, $4b
    ld d, c
    ld a, $50
    ld d, [hl]
    ldh a, [$36]
    ld b, l
    ld b, d
    ld b, c
    ld h, d
    ld c, h
    ld b, e
    ld b, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld b, c
    ld b, [hl]
    ld d, b
    ld b, h
    ld d, d
    ld b, [hl]
    ld d, b
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, h
    pop af
    ld c, h
    ld b, e
    ld b, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld b, d
    ld c, e
    ld b, h
    ld d, c
    ld b, l
    ldh a, [$32]
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld a, $62
    ld d, c
    ld c, a
    ld d, d
    ld b, d
    pop af
    ld d, h
    ld a, $4f
    ld c, a
    ld b, [hl]
    ld c, h
    ld c, a
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld c, a
    ld b, d
    ld d, e
    ld b, d
    ld a, $49
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, a
    ld b, d
    ld a, $49
    ld h, d
    ld b, [hl]
    ld b, c
    ld b, d
    ld c, e
    ld d, c
    ld b, [hl]
    ld d, c
    ld d, [hl]
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld c, h
    ld b, e
    pop af
    ld b, c
    ld b, d
    ld d, b
    ld d, c
    ld c, a
    ld d, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, d
    or [hl]
    pop af
    ld b, b
    ld a, $4f
    ld c, e
    ld a, $44
    ld b, d
    ldh a, [rP1]

; =============================================================================
; HighDetailTextFork — encyclopedia DETAIL text for NEW species (ids 221-239; S105 G3, was 224).
; Vanilla mode-1 (line-2 description) pointer table at $420b is only 215 entries
; (0-214); species 224 overshoots into routine code at $43CB, reading $0609 and
; rendering ROM0 code as text forever (the WaitScreenUpdateDone freeze). For
; id>=221 we swap the $4007 mode-table for a custom one whose mode-1 base is set
; so [base + id*2] lands on a valid description pointer. Modes 0/2-7 keep vanilla
; bases (their tables are 256 entries, no overshoot).
; =============================================================================
HighDetailTextFork:
    ld a, [$c823]                 ; species id
    cp $dd                        ; >= 221 ?
    jr nc, .high
    ld de, $4007                  ; vanilla mode-table
    jr .go
.high:
    ld de, HighModeTable4D
.go:
    call CallTextEngine
    ret

HighModeTable4D:
    dw HighMode0Ptrs - $01BA      ; mode0 (line1 lineage/recipe) base: [base+221*2]=HighMode0Ptrs (was $400b -> shared "?????" @ $53C4)
    dw HighLine2Ptrs - $01BA      ; mode1 (line2) base: [base + 221*2] = HighLine2Ptrs
    dw $43ce, $43e1, $43f4, $4407, $441a, $442d   ; modes 2-7 vanilla

; S105 (P3.9b; G3: 19 ids 221-239): the per-new-species pointer words (2 x 19) + recipe lines are the
; compiler region ns_detail_text (project.json custom.species; editor2/core/
; species.py). Line 2 = the description of `description_from`'s species; line 1
; = "Parent1  Parent2" derived from the first special breeding entry producing
; the species (the vanilla recipe format: two 9-char fields — e.g. slot 200
; "Servant  GreatDrak"), or the vanilla "?????" line $53C4 when nothing breeds
; it. An undeclared id = the vanilla words ($60BC-style description of species 0 / "?????"); no species
; at all = the same (never read: nothing can hold an undeclared id).
; @BUILD_PROJECT BEGIN ns_detail_text
HighLine2Ptrs:                    ; line 2 (description) pointers, ids 221-239
    dw $53C4   ; [221] (none)
    dw $53C4   ; [222] (none)
    dw $53C4   ; [223] (none)
    dw $60BC   ; [224] Gorbunok: species 78's description
    dw $53C4   ; [225] (none)
    dw $53C4   ; [226] (none)
    dw $53C4   ; [227] (none)
    dw $53C4   ; [228] (none)
    dw $53C4   ; [229] (none)
    dw $53C4   ; [230] (none)
    dw $53C4   ; [231] (none)
    dw $53C4   ; [232] (none)
    dw $53C4   ; [233] (none)
    dw $53C4   ; [234] (none)
    dw $53C4   ; [235] (none)
    dw $53C4   ; [236] (none)
    dw $53C4   ; [237] (none)
    dw $53C4   ; [238] (none)
    dw $53C4   ; [239] (none)
HighMode0Ptrs:                    ; line 1 (recipe) pointers, ids 221-239
    dw $53C4   ; [221] (none)
    dw $53C4   ; [222] (none)
    dw $53C4   ; [223] (none)
    dw NewSpeciesRecipeLine_224
    dw $53C4   ; [225] (none)
    dw $53C4   ; [226] (none)
    dw $53C4   ; [227] (none)
    dw $53C4   ; [228] (none)
    dw $53C4   ; [229] (none)
    dw $53C4   ; [230] (none)
    dw $53C4   ; [231] (none)
    dw $53C4   ; [232] (none)
    dw $53C4   ; [233] (none)
    dw $53C4   ; [234] (none)
    dw $53C4   ; [235] (none)
    dw $53C4   ; [236] (none)
    dw $53C4   ; [237] (none)
    dw $53C4   ; [238] (none)
    dw $53C4   ; [239] (none)
NewSpeciesRecipeLine_224:   ; derived from the first special entry breeding 224
    db $36, $4B, $3E, $46, $49, $56, $62, $62, $62, $25, $3E, $51, $51, $49, $42, $35, $42, $55, $F0
; @BUILD_PROJECT END ns_detail_text

    ds $8000 - @, $00             ; pad remainder of bank with $00 (byte-exact)
