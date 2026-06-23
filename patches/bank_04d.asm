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
    jp HighDetailTextFork   ; FORK: species>=224 use custom mode-table (byte-neutral 3+4)
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


    db $10
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld de, $3e43
    ld c, d
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR10]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld [de], a
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]

jr_04d_43f1:
    ld h, d
    ld h, d
    ldh a, [rNR10]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc de
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR10]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR10]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    dec d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR10]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld d, $43
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR10]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    rla
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR10]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    jr jr_04d_44a1

    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [$64]
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR10]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    jr nc, jr_04d_44c2

    ld b, c
    inc sp
    ld c, c
    ld a, $4b
    ld d, c
    ld h, d
    ldh a, [rNR10]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc h
    ld c, c
    ld c, d
    ld b, [hl]
    ld c, a
    ld a, $47
    ld h, d
    ld h, d
    ldh a, [rNR10]
    ld b, e

jr_04d_44a1:
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    dec h
    ld c, h
    ld c, d
    ccf
    ld h, $4f
    ld a, $44
    ld h, d
    ldh a, [rNR10]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    dec [hl]
    ld c, h
    ccf
    ld c, h
    ld d, b
    ld d, c
    ld b, d

jr_04d_44c2:
    ld c, a
    ld h, d
    ldh a, [rNR10]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld [hl], $48
    ld d, d
    ld c, c
    ld c, c
    ld c, a
    ld c, h
    ld c, h
    ld h, d
    ldh a, [$64]
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR10]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR10]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    jr nc, jr_04d_454b

    ld d, c
    ld a, $49
    daa
    ld c, a
    ld a, $48
    ldh a, [$30]
    ld b, d
    ld d, c
    ld a, $49
    ld d, [hl]
    ld h, d
    ld h, d
    ld h, d
    jr nc, jr_04d_455e

    ld d, c
    ld a, $49
    ld d, [hl]
    ld h, d
    ld h, d
    ld h, d
    ldh a, [$30]
    ld b, d
    ld d, c
    ld a, $3f
    ccf
    ld c, c
    ld b, d
    ld h, d
    jr nc, jr_04d_4571

    ld d, c
    ld a, $3f
    ccf
    ld c, c
    ld b, d
    ld h, d
    ldh a, [$30]
    ld b, d
    ld d, c
    ld a, $49
    ld l, $46
    ld c, e
    ld b, h
    jr nc, jr_04d_4584

    ld d, c
    ld a, $49
    ld l, $46
    ld c, e
    ld b, h
    ldh a, [rNR11]

jr_04d_454b:
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    db $10
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR11]

jr_04d_455e:
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld [de], a
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR11]

jr_04d_4571:
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc de
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR11]

jr_04d_4584:
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR11]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    dec d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR11]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld d, $43
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR11]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    rla
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR11]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    jr jr_04d_461d

    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [$27]
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld l, $46
    ld b, c
    daa
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld l, $46
    ld b, c
    ldh a, [rNR11]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc sp
    ld b, [hl]
    ld b, b
    ld c, b
    ld d, [hl]
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR11]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld a, [hl+]
    ld d, d
    ld c, c
    ld c, l
    dec h
    ld b, d
    ld a, $50
    ld d, c
    ldh a, [rNR11]
    ld b, e

jr_04d_461d:
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    jr nc, jr_04d_4664

    ld b, c
    ld h, $4c
    ld c, e
    ld b, c
    ld c, h
    ld c, a
    ldh a, [rNR11]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    add hl, sp
    ld c, h
    ld c, h
    ld b, c
    ld c, h
    ld c, c
    ld c, c
    ld h, d
    ld h, d
    ldh a, [rNR11]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld a, [hl+]
    ld c, h
    dec hl
    ld c, h
    ld c, l
    ld c, l
    ld b, d
    ld c, a
    ld h, d
    ldh a, [rNR11]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld a, [hl+]
    ld d, d
    ld c, c
    ld c, l
    ld c, l
    ld c, c
    ld b, d

jr_04d_4664:
    ld h, d
    ld h, d
    ldh a, [rNR11]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    dec h
    ld a, $3f
    ccf
    ld c, c
    ld b, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR11]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc h
    ld c, a
    ld c, d
    ld d, [hl]
    ld h, $4f
    ld a, $3f
    ld h, d
    ldh a, [$64]
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR11]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    dec h
    ld b, [hl]
    ld b, h
    dec [hl]
    ld c, h
    ld c, h
    ld d, b
    ld d, c
    ld h, d
    ldh a, [rNR52]
    ld c, a
    ld b, d
    ld d, b
    ld d, c
    ld c, l
    ld b, d
    ld c, e
    ld d, c
    ld h, $4f
    ld b, d
    ld d, b
    ld d, c
    ld c, l
    ld b, d
    ld c, e
    ld d, c
    ldh a, [$3a]
    ld b, [hl]
    ld c, e
    ld b, h
    ld [hl], $4b
    ld a, $48
    ld b, d
    ld a, [hl-]
    ld b, [hl]
    ld c, e
    ld b, h
    ld [hl], $4b
    ld a, $48
    ld b, d
    ldh a, [rNR50]
    ld c, e
    ld b, c
    ld c, a
    ld b, d
    ld a, $49
    ld h, d
    ld h, d
    jr nc, jr_04d_4726

    ld b, c
    ld d, d
    ld d, b
    ld a, $28
    ld d, [hl]
    ld b, d
    ldh a, [rNR11]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    cpl
    ld b, [hl]
    ld c, h
    ld c, e
    ld b, d
    ld d, l
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR11]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc sp
    ld b, l
    ld c, h
    ld b, d
    ld c, e
    ld b, [hl]
    ld d, l
    ld h, d
    ld h, d
    ldh a, [$36]
    ld c, b
    ld d, [hl]
    daa
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld [hl-], a
    ld c, a
    ld c, h
    ld b, b
    ld b, l
    ld b, [hl]
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR12]

jr_04d_4726:
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    db $10
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR12]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld de, $3e43
    ld c, d
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR12]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc de
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR12]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR12]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    dec d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [$64]
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR12]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    rla
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR12]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    jr jr_04d_47f8

    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [$64]
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR12]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    jr nc, jr_04d_482d

    ld b, c
    ld c, a
    ld c, h
    ld c, e
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR12]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    scf
    ld c, h
    ld c, a
    ld d, c
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ldh a, [rNR12]
    ld b, e

jr_04d_47f8:
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    daa
    ld d, d
    ld b, b
    ld c, b
    ld l, $46
    ld d, c
    ld b, d
    ld h, d
    ldh a, [rNR12]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld [hl], $51
    ld d, d
    ccf
    ld d, b
    ld d, d
    ld b, b
    ld c, b
    ld h, d
    ldh a, [rNR12]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld d, $43
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d

jr_04d_482d:
    ld h, d
    ldh a, [rNR12]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld [hl-], a
    ld c, a
    ld b, b
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR12]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld [hl], $3e
    ccf
    ld c, a
    ld b, d
    jr nc, jr_04d_4890

    ld c, e
    ld h, d
    ldh a, [rNR12]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    cpl
    ld b, [hl]
    ld d, a
    ld a, $4f
    ld b, c
    add hl, hl
    ld c, c
    ld d, [hl]
    ldh a, [rNR12]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    add hl, hl
    ld a, $4b
    ld b, h
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    ldh a, [rNR12]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    daa
    ld c, a
    ld a, $48
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    ldh a, [rNR12]
    ld b, e

jr_04d_4890:
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    jr nc, jr_04d_48d7

    ld b, c
    inc sp
    ld b, d
    ld b, b
    ld c, b
    ld b, d
    ld c, a
    ldh a, [$3a]
    ld b, [hl]
    ld c, c
    ld b, c
    inc h
    ld c, l
    ld b, d
    ld h, d
    ld h, d
    ld a, [hl-]
    ld b, [hl]
    ld c, c
    ld b, c
    inc h
    ld c, l
    ld b, d
    ld h, d
    ld h, d
    ldh a, [$37]
    ld c, a
    ld d, d
    ld c, d
    ld c, l
    ld b, d
    ld d, c
    ld b, d
    ld c, a
    scf
    ld c, a
    ld d, d
    ld c, d
    ld c, l
    ld b, d
    ld d, c
    ld b, d
    ld c, a
    ldh a, [rNR12]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d

jr_04d_48d7:
    ld h, d
    ld h, d
    ldh a, [rNR12]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    daa
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR12]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    jr z, jr_04d_494e

    ld b, d
    dec h
    ld a, $49
    ld c, c
    ld h, d
    ld h, d
    ldh a, [rNR13]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    db $10
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR13]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld de, $3e43
    ld c, d
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR13]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld [de], a
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR13]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR13]
    ld b, e

jr_04d_494e:
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    dec d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR13]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld d, $43
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR13]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    rla
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR13]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    jr jr_04d_49d3

    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [$64]
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [$64]
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR13]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    dec [hl]
    ld c, h
    ld b, b
    ld c, b
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    ldh a, [$64]
    ld h, h

jr_04d_49d3:
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR13]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    daa
    ld c, a
    ld c, h
    ld c, c
    ld c, c
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR13]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld h, $4c
    ld b, [hl]
    ld c, c
    dec h
    ld b, [hl]
    ld c, a
    ld b, c
    ld h, d
    ldh a, [rNR13]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc l
    ld b, b
    ld b, d
    jr nc, @+$40

    ld c, e
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR13]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld a, [hl+]
    ld b, [hl]
    ld d, b
    ld c, d
    ld c, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [$64]
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR13]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    dec [hl]
    ld a, $56
    ccf
    ld d, d
    ld c, a
    ld c, e
    ld h, d
    ld h, d
    ldh a, [rNR13]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    daa
    ld a, $4b
    ld b, b
    ld b, d
    add hl, sp
    ld b, d
    ld b, h
    ld b, [hl]
    ldh a, [rNR51]
    ld c, c
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld b, c
    ld d, [hl]
    inc sp
    ld b, l
    ld c, h
    ld b, d
    ld c, e
    ld b, [hl]
    ld d, l
    ld h, d
    ld h, d
    ldh a, [rNR14]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    db $10
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR14]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld de, $3e43
    ld c, d
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR14]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld [de], a
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR14]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc de
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR14]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    dec d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR14]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld d, $43
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR14]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    rla
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR14]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    jr jr_04d_4b4f

    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [$64]
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR14]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld a, [hl+]
    ld c, h
    ld c, l
    ld b, l
    ld b, d
    ld b, b
    ld a, $41
    ld a, $f0
    inc d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    add hl, hl
    ld a, $40
    ld b, d
    ld c, a
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR14]
    ld b, e

jr_04d_4b4f:
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc sp
    ld b, [hl]
    ld d, l
    ld d, [hl]
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR14]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld sp, $5146
    ld b, d
    ld a, [hl-]
    ld b, l
    ld b, [hl]
    ld c, l
    ld h, d
    ldh a, [rNR14]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    add hl, hl
    ld d, d
    ld c, e
    ld c, b
    ld d, [hl]
    dec h
    ld b, [hl]
    ld c, a
    ld b, c
    ldh a, [rNR14]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc sp
    ld b, [hl]
    ld c, c
    ld c, c
    ld c, h
    ld d, h
    dec [hl]
    ld a, $51
    ldh a, [rNR14]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    daa
    ld a, $4f
    ld c, b
    jr z, jr_04d_4bfe

    ld b, d
    ld h, d
    ld h, d
    ldh a, [$28]
    ld d, e
    ld b, [hl]
    ld c, c
    ld [hl], $42
    ld b, d
    ld b, c
    ld h, d
    jr z, jr_04d_4c0a

    ld b, [hl]
    ld c, c
    ld [hl], $42
    ld b, d
    ld b, c
    ld h, d
    ldh a, [$30]
    ld a, $4b
    jr z, jr_04d_4c02

    ld d, c
    ld b, d
    ld c, a
    ld h, d
    jr nc, jr_04d_4c08

    ld c, e
    jr z, @+$40

    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ldh a, [rNR14]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [$64]
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [$15]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c

jr_04d_4bfe:
    ld d, [hl]
    ld h, d
    ld h, d
    db $10

jr_04d_4c02:
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]

jr_04d_4c08:
    ld h, d
    ld h, d

jr_04d_4c0a:
    ldh a, [$15]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld de, $3e43
    ld c, d
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [$15]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld [de], a
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [$15]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc de
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [$15]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [$15]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld d, $43
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [$15]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    rla
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [$15]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    jr jr_04d_4ccb

    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [$64]
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [$64]
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [$15]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    add hl, hl
    ld c, c
    ld c, h
    ld c, a
    ld a, $30
    ld a, $4b
    ld h, d
    ldh a, [$15]
    ld b, e

jr_04d_4ccb:
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc l
    ld c, a
    ld c, h
    ld c, e
    scf
    ld d, d
    ld c, a
    ld d, c
    ld h, d
    ldh a, [$15]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc h
    ld c, d
    ccf
    ld b, d
    ld c, a
    ld a, [hl-]
    ld b, d
    ld b, d
    ld b, c
    ldh a, [$15]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld [hl], $3e
    ld b, b
    ld b, b
    ld b, d
    ld c, a
    ld h, d
    ld h, d
    ld h, d
    ldh a, [$15]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld [hl], $4d
    ld c, h
    ld c, h
    ld c, b
    ld d, [hl]
    ld h, d
    ld h, d
    ld h, d
    ldh a, [$15]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    daa
    ld a, $4f
    ld c, b
    ld h, $4f
    ld a, $3f
    ld h, d
    ldh a, [$15]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    add hl, hl
    ld a, $46
    ld c, a
    ld d, [hl]
    dec [hl]
    ld a, $51
    ld h, d
    ldh a, [$36]
    ld d, c
    ld a, $44
    dec h
    ld d, d
    ld b, h
    ld h, d
    ld h, d
    ld [hl], $51
    ld a, $44
    dec h
    ld d, d
    ld b, h
    ld h, d
    ld h, d
    ldh a, [$2b]
    ld c, h
    ld c, a
    ld c, e
    dec h
    ld b, d
    ld b, d
    ld d, c
    ld h, d
    dec hl
    ld c, h
    ld c, a
    ld c, e
    dec h
    ld b, d
    ld b, d
    ld d, c
    ld h, d
    ldh a, [$15]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR21]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    db $10
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR21]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [$64]
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR21]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc de
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR21]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR21]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    dec d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR21]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    rla
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR21]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    jr jr_04d_4e47

    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [$64]
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR21]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld [de], a
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR21]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld de, $3e43
    ld c, d
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR21]
    ld b, e

jr_04d_4e47:
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    cpl
    ld b, [hl]
    ld d, a
    ld a, $4f
    ld b, c
    jr nc, jr_04d_4e94

    ld c, e
    ldh a, [rNR21]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    daa
    ld a, $4f
    ld c, b
    dec hl
    ld c, h
    ld c, a
    ld c, e
    ld h, d
    ldh a, [rNR21]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    dec h
    ld b, d
    ld a, $4b
    jr nc, jr_04d_4eb8

    ld c, e
    ld h, d
    ld h, d
    ldh a, [rNR21]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    dec hl
    ld a, $4a
    ld c, d
    ld b, d
    ld c, a
    jr nc, jr_04d_4ecd

    ld c, e
    ldh a, [$27]
    ld b, d
    ld c, d

jr_04d_4e94:
    ld c, h
    ld c, e
    ld b, [hl]
    ld d, c
    ld b, d
    ld h, d
    daa
    ld b, d
    ld c, d
    ld c, h
    ld c, e
    ld b, [hl]
    ld d, c
    ld b, d
    ld h, d
    ldh a, [rSB]
    jr z, @+$58

    ld b, d
    ld h, $49
    ld c, h
    ld d, h
    ld c, e
    ld bc, $5628
    ld b, d
    ld h, $49
    ld c, h
    ld d, h
    ld c, e
    ldh a, [rNR21]

jr_04d_4eb8:
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    jr nc, jr_04d_4f00

    ld b, c
    daa
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ldh a, [$2a]
    ld c, a
    ld b, d

jr_04d_4ecd:
    ld c, e
    ld a, $41
    ld a, $49
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld c, e
    ld a, $41
    ld a, $49
    ld h, d
    ldh a, [rNR21]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    dec [hl]
    ld c, h
    ld b, h
    ld d, d
    ld b, d
    ld sp, $5146
    ld b, d
    ldh a, [rNR21]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    dec h
    ld b, [hl]
    ld b, h
    jr z, jr_04d_4f54

    ld b, d
    ld h, d

jr_04d_4f00:
    ld h, d
    ld h, d
    ldh a, [$64]
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR21]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc h
    ld c, a
    ld c, d
    ld c, h
    ld c, a
    inc sp
    ld b, d
    ld b, c
    ld b, d
    ldh a, [rNR50]
    ld c, b
    ld d, d
    ccf
    ld a, $4f
    ld h, d
    ld h, d
    ld h, d
    dec [hl]
    ld a, $46
    ld c, e
    dec hl
    ld a, $54
    ld c, b
    ld h, d
    ldh a, [rNR52]
    ld b, d
    ld c, e
    ld d, c
    ld a, $50
    ld a, $52
    ld c, a
    ld a, [hl+]
    ld c, h
    ld c, c
    ld b, c
    ld a, [hl+]
    ld c, h
    ld c, c
    ld b, d
    ld c, d
    ldh a, [rNR22]
    ld b, e
    ld a, $4a
    ld b, [hl]

jr_04d_4f54:
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    db $10
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR22]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld [hl], $54
    ld c, h
    ld c, a
    ld b, c
    ld b, h
    ld c, h
    ld c, e
    ld h, d
    ldh a, [rNR22]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld [de], a
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR22]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc de
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR22]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR22]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    dec d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR22]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld d, $43
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR22]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    jr jr_04d_5022

    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [$64]
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR22]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld a, [hl+]
    ld b, [hl]
    ld a, $4b
    ld d, c
    ld [hl], $49
    ld d, d
    ld b, h
    ldh a, [rNR22]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    jr nc, @+$48

    ld d, b
    ld d, c
    ld d, [hl]
    ld a, [hl-]
    ld b, [hl]
    ld c, e
    ld b, h
    ldh a, [rNR22]
    ld b, e

jr_04d_5022:
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld de, $3e43
    ld c, d
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR22]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld a, [hl-]
    ld b, [hl]
    ld c, e
    ld b, c
    dec h
    ld b, d
    ld a, $50
    ld d, c
    ldh a, [rNR22]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld a, [hl-]
    ld b, d
    ld b, d
    ld b, c
    dec h
    ld d, d
    ld b, h
    ld h, d
    ld h, d
    ldh a, [$27]
    ld b, d
    ld a, $41
    ld sp, $5146
    ld b, d
    ld h, d
    daa
    ld b, d
    ld a, $41
    ld sp, $5146
    ld b, d
    ld h, d
    ldh a, [rNR22]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [$2b]
    ld c, h
    ld c, a
    ld c, b
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    dec hl
    ld c, h
    ld c, a
    ld c, b
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR51]
    ld c, h
    ld c, e
    ld b, d
    ld [hl], $49
    ld a, $53
    ld b, d
    dec h
    ld c, h
    ld c, e
    ld b, d
    ld [hl], $49
    ld a, $53
    ld b, d
    ldh a, [$36]
    ld c, b
    ld b, d
    ld c, c
    ld b, d
    ld d, c
    ld c, h
    ld c, a
    ld h, d
    ld [hl], $48
    ld b, d
    ld c, c
    ld b, d
    ld d, c
    ld c, h
    ld c, a
    ld h, d
    ldh a, [$64]
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR23]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    db $10
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR23]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld de, $3e43
    ld c, d
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR23]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld [de], a
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR23]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc de
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR23]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR23]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    dec d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR23]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld d, $43
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [rNR23]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    rla
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ldh a, [$64]
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR23]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    cpl
    ld b, [hl]
    ld c, l
    ld d, b
    ld d, [hl]
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR23]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    inc h
    ld c, e
    ld b, c
    ld c, a
    ld b, d
    ld a, $49
    ld h, d
    ld h, d
    ldh a, [rNR23]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [rNR23]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld a, [hl+]
    ld b, [hl]
    ld a, $4b
    ld d, c
    ld a, [hl-]
    ld c, h
    ld c, a
    ld c, d
    ldh a, [rNR23]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld a, [hl-]
    ld b, [hl]
    ld c, e
    ld b, h
    scf
    ld c, a
    ld b, d
    ld b, d
    ld h, d
    ldh a, [rNR23]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld [hl], $48
    ld d, d
    ld c, c
    dec [hl]
    ld b, [hl]
    ld b, c
    ld b, d
    ld c, a
    ldh a, [rNR23]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld [hl], $4b
    ld a, $46
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    ld h, d
    ldh a, [$2a]
    ld c, h
    ld c, h
    ld c, l
    ld b, [hl]
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    add hl, hl
    ld b, [hl]
    ld c, a
    ld b, d
    ld a, [hl-]
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ldh a, [$30]
    ld b, d
    ld d, c
    ld a, $49
    daa
    ld c, a
    ld a, $48
    inc h
    ld c, a
    ld b, b
    daa
    ld b, d
    ld c, d
    ld c, h
    ld c, e
    ld h, d
    ldh a, [$35]
    ld c, h
    ccf
    ld c, h
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    cpl
    ld b, d
    ld c, h
    ld h, d
    ld h, d
    ldh a, [rNR23]
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld h, d
    dec h
    ld c, h
    ld d, l
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    ldh a, [$2a]
    ld c, h
    ld c, h
    ld c, l
    ld b, [hl]
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld a, [hl+]
    ld c, h
    ld c, h
    ld c, l
    ld b, [hl]
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [$30]
    ld d, d
    ld b, c
    daa
    ld c, h
    ld c, c
    ld c, c
    ld h, d
    ld h, d
    jr nc, @+$54

    ld b, c
    daa
    ld c, h
    ld c, c
    ld c, c
    ld h, d
    ld h, d
    ldh a, [$2a]
    ld c, h
    ld c, c
    ld b, d
    ld c, d
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld a, [hl+]
    ld c, h
    ld c, c
    ld b, d
    ld c, d
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [$36]
    ld c, l
    ld b, [hl]
    ld c, b
    ld d, [hl]
    dec h
    ld c, h
    ld d, [hl]
    ld h, d
    ld [hl], $4d
    ld b, [hl]
    ld c, b
    ld d, [hl]
    dec h
    ld c, h
    ld d, [hl]
    ld h, d
    ldh a, [$2c]
    ld b, b
    ld b, d
    jr nc, @+$40

    ld c, e
    ld h, d
    ld h, d
    ld h, d
    cpl
    ld a, $53
    ld a, $30
    ld a, $4b
    ld h, d
    ld h, d
    ldh a, [$36]
    ld b, d
    ld c, a
    ld d, e
    ld a, $4b
    ld d, c
    ld h, d
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    daa
    ld c, a
    ld a, $48
    ldh a, [$27]
    ld c, a
    ld a, $40
    ld c, h
    cpl
    ld c, h
    ld c, a
    ld b, c
    daa
    ld b, [hl]
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, d
    ld b, h
    ld c, h
    ld c, e
    ldh a, [$3a]
    ld b, l
    ld b, [hl]
    ld d, c
    ld b, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    jr nc, jr_04d_5319

    ld d, c
    ld a, $49
    ld l, $46
    ld c, e
    ld b, h
    ldh a, [$2d]
    ld a, $4a
    ld b, [hl]
    ld c, a
    ld d, d
    ld d, b
    ld h, d
    ld h, d
    dec [hl]
    ld c, h
    ld d, b
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, d
    ld h, d
    ldh a, [$2b]
    ld a, $4f
    ld b, h
    ld c, h
    ld c, e
    ld h, d
    ld h, d
    ld h, d
    ld [hl-], a
    ld c, a
    ld c, h
    ld b, b
    ld b, l
    ld b, [hl]
    ld h, d
    ld h, d
    ld h, d
    ldh a, [$27]
    ld c, a
    ld a, $40
    ld c, h
    cpl
    ld c, h
    ld c, a
    ld b, c
    ld [hl], $46
    ld b, c
    ld c, h
    ld b, l
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [$27]

jr_04d_5319:
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    ld h, d
    ld h, d
    ld h, d
    daa
    ld b, [hl]
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, d
    ld b, h
    ld c, h
    ld c, e
    ld h, d
    ldh a, [$33]
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld c, h
    ld h, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    cpl
    ld b, d
    ld c, h
    ld h, d
    ld h, d
    ldh a, [$28]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld c, b
    ld h, d
    ld h, d
    ld h, d
    ld a, [hl+]
    ld c, h
    ld c, c
    ld b, c
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    ldh a, [$30]
    ld b, [hl]
    ld c, a
    ld d, d
    ld b, c
    ld c, a
    ld a, $3e
    ld d, b
    ld [hl], $4d
    ld b, [hl]
    ld c, b
    ld b, d
    ld c, a
    ld c, h
    ld d, d
    ld d, b
    ldh a, [rNR51]
    ld a, $4f
    ld a, $4a
    ld c, h
    ld d, b
    ld h, d
    ld h, d
    daa
    ld a, $4f
    ld c, b
    dec hl
    ld c, h
    ld c, a
    ld c, e
    ld h, d
    ldh a, [$3d]
    ld c, h
    ld c, d
    ld a, $62
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    jr nc, jr_04d_53c9

    ld c, a
    ld d, d
    ld b, c
    ld c, a
    ld a, $3e
    ld d, b
    ldh a, [$27]
    ld b, d
    ld a, $51
    ld b, l
    jr nc, jr_04d_53de

    ld c, a
    ld b, d
    inc h
    ld c, a
    ld c, d
    ld c, h
    ld c, a
    ld c, l
    ld b, [hl]
    ld c, h
    ld c, e
    ldh a, [$27]
    ld b, d
    ld a, $51
    ld b, l
    jr nc, jr_04d_53f1

    ld c, a
    ld b, d
    jr nc, jr_04d_53fb

    ld b, c
    ld c, h
    ld d, d
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ldh a, [$27]
    ld b, d
    ld a, $51
    ld b, l
    jr nc, @+$4e

    ld c, a
    ld b, d
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, d
    ld h, d
    ldh a, [$64]
    ld h, h
    ld h, h
    ld h, h
    ld h, h

jr_04d_53c9:
    ld h, d
    ld h, d
    ld h, d
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ld h, h
    ldh a, [$30]
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
; HighDetailTextFork — encyclopedia DETAIL text for NEW species (id>=224).
; Vanilla mode-1 (line-2 description) pointer table at $420b is only 215 entries
; (0-214); species 224 overshoots into routine code at $43CB, reading $0609 and
; rendering ROM0 code as text forever (the WaitScreenUpdateDone freeze). For
; id>=224 we swap the $4007 mode-table for a custom one whose mode-1 base is set
; so [base + id*2] lands on a valid description pointer. Modes 0/2-7 keep vanilla
; bases (their tables are 256 entries, no overshoot).
; =============================================================================
HighDetailTextFork:
    ld a, [$c823]                 ; species id
    cp $e0                        ; >= 224 ?
    jr nc, .high
    ld de, $4007                  ; vanilla mode-table
    jr .go
.high:
    ld de, HighModeTable4D
.go:
    call CallTextEngine
    ret

HighModeTable4D:
    dw $400b                      ; mode0 (name)  vanilla 256-entry table
    dw HighLine2Ptrs - $01C0      ; mode1 (line2) base: [base + 224*2] = HighLine2Ptrs
    dw $43ce, $43e1, $43f4, $4407, $441a, $442d   ; modes 2-7 vanilla

HighLine2Ptrs:                    ; per-high-species line-2 description pointers (id 224+)
    dw $60bc                      ; id 224 (Gorbunok): Dracky's description (valid placeholder)

; Phase N: recipe (mode-0 line 1) string for new species. mode-0[224] in the
; vanilla $400b table (read by detail entry 2) was a "?????    ?????" placeholder;
; it is repointed here. Format matches Armorpion ("P1 <sp> P2 <sp> $F0").
GorbunokRecipeLine:               ; "Snaily BattleRex"
    db $36, $4b, $3e, $46, $49, $56, $62      ; "Snaily" + space
    db $25, $3e, $51, $51, $49, $42, $35, $42, $55, $62, $f0  ; "BattleRex" + space + term

    ds $8000 - @, $00             ; pad remainder of bank with $00 (byte-exact)
