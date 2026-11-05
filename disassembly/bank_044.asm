; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $044", ROMX[$4000], BANK[$44]

    db $44 ; Bank number

    ; Cross-bank dispatch table (102 entries)
    ; Called via: ld hl, $44XX / rst $10
    dw LoadB44_40cd                  ; Entry 0
    dw TextRunB44_40fb               ; Entry 1
    dw TextShowRefreshB44_4129       ; Entry 2
    dw $4009                          ; Entry 3 — mode 0 -> table $4009 (mode list $4007)
    dw TextStr_44_4157               ; Entry 4 — [table $4009]; text $0198 "*:Good evening. Or is it day? *:I…"
    dw TextStr_44_41ae               ; Entry 5 — text $0199 "[HERO] looked at the bookshelf. :…"
    dw TextStr_44_4328               ; Entry 6 — text $019A "[HERO] looked at the bookshelf. :…"
    dw TextStr_44_44c6               ; Entry 7 — text $019B "[HERO] looked at the bookshelf. :…"
    dw TextStr_44_45a4               ; Entry 8 — text $019C "[HERO] looked into the jar. It wa…"
    dw TextStr_44_45ee               ; Entry 9 — text $019D "[HERO] looked into the big kettle…"
    dw TextStr_44_4645               ; Entry 10 — text $019E "*:Welcome to the Master School! *…"
    dw TextStr_44_46db               ; Entry 11 — text $019F "*:It's always better to have a Wa…"
    dw TextStr_44_474d               ; Entry 12 — text $01A0 "*:You are good. You beat the teac…"
    dw TextStr_44_477b               ; Entry 13 — text $01A1 "*:Here's the Room of Villager & T…"
    dw TextStr_44_47f5               ; Entry 14 — text $01A2 "*:I'm conducting secret research …"
    dw TextStr_44_488a               ; Entry 15 — text $01A3 "*:Being a master and a fighter is…"
    dw TextStr_44_48d8               ; Entry 16 — text $01A4 "*:Congratulations on surviving F …"
    dw TextStr_44_49ec               ; Entry 17 — text $01A5 "*:Are you familiar with the Gate …"
    dw TextStr_44_4a22               ; Entry 18 — text $01A6 "*:My years of research lead me to…"
    dw TextStr_44_4add               ; Entry 19 — text $01A7 "*:Are you familiar with the Gate …"
    dw TextStr_44_4b13               ; Entry 20 — text $01A8 "*:A monster is living deep in a c…"
    dw TextStr_44_4bd6               ; Entry 21 — text $01A9 "*:I would like to tell you more. …"
    dw TextStr_44_4c0c               ; Entry 22 — text $01AA "*:The devil settled in a town of …"
    dw TextStr_44_4c98               ; Entry 23 — text $01AB "King:Oh [HERO]! You beat MadCat! …"
    dw TextStr_44_4d24               ; Entry 24 — text $01AC "King:It reminds me. Have you been…"
    dw TextStr_44_4e34               ; Entry 25 — text $01AD "*:Starry Night Tournament is a ma…"
    dw TextStr_44_4f10               ; Entry 26 — text $01AE "King:Oh [HERO]! You defeated Face…"
    dw TextStr_44_4fa7               ; Entry 27 — text $01AF "*:The girl down below who blocked…"
    dw TextStr_44_5005               ; Entry 28 — text $01B0 "*:I want you to win the tournamen…"
    dw TextStr_44_50f1               ; Entry 29 — text $01B1 "*:I heard you got stronger. *:But…"
    dw TextStr_44_513d               ; Entry 30 — text $01B2 "*:Whew! At last we made it to the…"
    dw TextStr_44_51af               ; Entry 31 — text $01B3 "*:Meet the old man of the Shrine …"
    dw TextStr_44_521a               ; Entry 32 — text $01B4 "*:Here you are at the Chamber of …"
    dw TextStr_44_5325               ; Entry 33 — text $01B5 "*:The place to hatch eggs? Now I …"
    dw TextStr_44_539b               ; Entry 34 — text $01B6 "*:Well done! You survived E class…"
    dw TextStr_44_5457               ; Entry 35 — text $01B7 "*:Well done! You survived E class…"
    dw TextStr_44_5512               ; Entry 36 — text $01B8 "*:The last match of the E class i…"
    dw TextStr_44_5558               ; Entry 37 — text $01B9 "*:Ha ha ha... It's E class. I sur…"
    dw TextStr_44_55d8               ; Entry 38 — text $01BA "*:The bishop over there taught me…"
    dw TextStr_44_570b               ; Entry 39 — text $01BB "*:BigRoost is roasting big time!"
    dw TextStr_44_572f               ; Entry 40 — text $01BC "*:Hee hee! Dude! Wanna know who y…"
    dw TextStr_44_577e               ; Entry 41 — text $01BD "*:Teto in the waiting room will f…"
    dw TextStr_44_589c               ; Entry 42 — text $01BE "*:Oh, long time no see! Remember …"
    dw TextStr_44_5a5d               ; Entry 43 — text $01BF "*:Hey! Lemme tell ya. when you br…"
    dw TextStr_44_5ca5               ; Entry 44 — text $01C0 "*:After breeding, the parent mons…"
    dw TextStr_44_5e5d               ; Entry 45 — text $01C1 "[HERO] looked at the bookshelf. :…"
    dw TextStr_44_5eea               ; Entry 46 — text $01C2 ":Breeding is to wed monsters. :Af…"
    dw TextStr_44_6055               ; Entry 47 — text $01C3 "[HERO] looked at the bookshelf. :…"
    dw TextStr_44_60fd               ; Entry 48 — text $01C4 ":Monster Journal by Master Monste…"
    dw TextStr_44_61d0               ; Entry 49 — text $01C5 "*:Master Monster Tamer is in the …"
    dw TextStr_44_6238               ; Entry 50 — text $01C6 "*:The level of a newborn monster …"
    dw TextStr_44_62f4               ; Entry 51 — text $01C7 "*:The secret of breeding is to co…"
    dw TextStr_44_6413               ; Entry 52 — text $01C8 "*:Oh! What a cute monster master …"
    dw TextStr_44_65a2               ; Entry 53 — text $01C9 "[HERO] looked at the bookshelf. :…"
    dw TextStr_44_6655               ; Entry 54 — text $01CA "[HERO] looked at the bookshelf. :…"
    dw TextStr_44_6762               ; Entry 55 — text $01CB "[HERO] looked at the bookshelf. :…"
    dw TextStr_44_6859               ; Entry 56 — text $01CC "*:You, do you know my daughter? […"
    dw TextStr_44_687c               ; Entry 57 — text $01CD "*:You don't!? Such a pretty, gent…"
    dw TextStr_44_68f6               ; Entry 58 — text $01CE "*:See, isn't she the prettiest gi…"
    dw TextStr_44_692f               ; Entry 59 — text $01CF "*:What does the person living nex…"
    dw TextStr_44_6983               ; Entry 60 — text $01D0 "*:I am never going to let anyone …"
    dw TextStr_44_69e8               ; Entry 61 — text $01D1 "[SOUND 60][HERO] looked inside th…"
    dw TextStr_44_6a0f               ; Entry 62 — text $01D2 "Wow! A TinyMedal! But cannot carr…"
    dw TextStr_44_6a75               ; Entry 63 — text $01D3 "The dresser is filled with girl's…"
    dw TextStr_44_6aa6               ; Entry 64 — text $01D4 "[HERO] looked at the bookshelf. :…"
    dw TextStr_44_6b3c               ; Entry 65 — text $01D5 "[HERO] looked into the jar. Someo…"
    dw TextStr_44_6bab               ; Entry 66 — text $01D6 "*:Get out! I'm not gonna give my …"
    dw TextStr_44_6bf9               ; Entry 67 — text $01D7 "*:Oh,it was you. Appearances can …"
    dw TextStr_44_6cf0               ; Entry 68 — text $01D8 "*:My professor is a genius and ha…"
    dw TextStr_44_6d60               ; Entry 69 — text $01D9 "*:Welcome to the Master School! *…"
    dw TextStr_44_6ddb               ; Entry 70 — text $01DA "*:I took notes about how to catch…"
    dw TextStr_44_6e1d               ; Entry 71 — text $01DB "*:Let me know if you do!"
    dw TextStr_44_6e39               ; Entry 72 — text $01DC "[HERO] opens the notebook. :Givin…"
    dw TextStr_44_6f3e               ; Entry 73 — text $01DD "*:In the far recesses of the Cham…"
    dw TextStr_44_7035               ; Entry 74 — text $01DE "*:There are foreign masters who..…"
    dw TextStr_44_7103               ; Entry 75 — text $01DF "*:What kind of guardian is waitin…"
    dw TextStr_44_713f               ; Entry 76 — text $01E0 "*:I heard monsters of the bugs fa…"
    dw TextStr_44_7206               ; Entry 77 — text $01E1 "*:This is the room of Memories & …"
    dw TextStr_44_7283               ; Entry 78 — text $01E2 "*:Hey [HERO]. Welcome. *:I am Mas…"
    dw TextStr_44_7309               ; Entry 79 — text $01E3 "*:Welcome back. Don't worry about…"
    dw TextStr_44_734d               ; Entry 80 — text $01E4 "*:Let me tell you. [YES/NO]"
    dw TextStr_44_7364               ; Entry 81 — text $01E5 "*:We're the hosts. You have to wi…"
    dw TextStr_44_738a               ; Entry 82 — text $01E6 "*:The family of the monster you c…"
    dw TextStr_44_748b               ; Entry 83 — text $01E7 "*:Want to learn about breeding mo…"
    dw TextStr_44_74bc               ; Entry 84 — text $01E8 "*:Victories in the arena will all…"
    dw TextStr_44_751e               ; Entry 85 — text $01E9 "*:When monsters from the same fam…"
    dw TextStr_44_7635               ; Entry 86 — text $01EA "*:Congratulation on surviving E c…"
    dw TextStr_44_7698               ; Entry 87 — text $01EB "*:[HERO]! Doing good huh? *:The R…"
    dw TextStr_44_7717               ; Entry 88 — text $01EC "*:Are you familiar with the Gate …"
    dw TextStr_44_774c               ; Entry 89 — text $01ED "*:Despair is a part of hope! Hope…"
    dw TextStr_44_77c9               ; Entry 90 — text $01EE "Are you familiar with the Gate of…"
    dw TextStr_44_77fa               ; Entry 91 — text $01EF "*:Discretion is the better part o…"
    dw TextStr_44_78a6               ; Entry 92 — text $01F0 "[SOUND 60][HERO] looked into the …"
    dw TextStr_44_78e4               ; Entry 93 — text $01F1 "*:In an enormous underground dung…"
    dw TextStr_44_79a6               ; Entry 94 — text $01F2 "King:Oh [HERO]! You beat BigEye! …"
    dw TextStr_44_7b2c               ; Entry 95 — text $01F3 "[HERO] checked out the stuffed an…"
    dw TextStr_44_7b7c               ; Entry 96 — text $01F4 "King:Oh,[HERO] you beat FangSlime…"
    dw TextStr_44_7c1e               ; Entry 97 — text $01F5 "*:There's a reason why wild monst…"
    dw TextStr_44_7d92               ; Entry 98 — text $01F6 "*:You are at the castle of GreatT…"
    dw TextStr_44_7e4a               ; Entry 99 — text $01F7 "*:Wishing upon the stars on Starr…"
    dw TextStr_44_7e9f               ; Entry 100 — text $01F8 "*:GreatLog is the closest country…"
    dw TextStr_44_7f05               ; Entry 101 — text $01F9 "*:You've been babied forever! *:C…"

LoadB44_40cd:
    ld a, [$c822]
    cp $01
    jr nz, jr_044_40de

    ld a, $01
    ld [$c822], a
    ld hl, $1b00
    rst $10
    ret


jr_044_40de:
    ld a, [$c823]
    cp $62
    jr c, jr_044_40f4

    sub $62
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $1b00
    rst $10
    ret


jr_044_40f4:
    ld de, $4007
    call CallTextEngine
    ret


; [S166] copy a text of this bank (RunTextHandler); ids past the bank's range go to its overflow bank (TEXT_SYSTEM "Text id resolution")
TextRunB44_40fb:
    ld a, [$c822]
    cp $01
    jr nz, jr_044_410c

    ld a, $01
    ld [$c822], a
    ld hl, $1b01
    rst $10
    ret


jr_044_410c:
    ld a, [$c823]
    cp $62
    jr c, jr_044_4122

    sub $62
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $1b01
    rst $10
    ret


jr_044_4122:
    ld de, $4007
    call RunTextHandler
    ret


; [S166] show a text (entry 0) then RequestScreenUpdate
TextShowRefreshB44_4129:
    ld a, [$c822]
    cp $01
    jr nz, jr_044_413a

    ld a, $01
    ld [$c822], a
    ld hl, $1b02
    rst $10
    ret


jr_044_413a:
    ld a, [$c823]
    cp $62
    jr c, jr_044_4150

    sub $62
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $1b02
    rst $10
    ret


jr_044_4150:
    call LoadB44_40cd
    call RequestScreenUpdate
    ret


; --- BEGIN re-sectioned text run (bank $44: $4157-$7f6a) ---
; DTE-encoded dialogue strings, one label per text id (text_id_map.json).
; Labels/comments only; bytes are byte-identical to the original ROM.
TextStr_44_4157:           ; id $0198
    ; "*:Good evening. Or is it day? / *:I'm an assistant to the professor. / Hee Hee."
    db $eb, $9f, $a3, $2a, $4c, $4c, $41, $62, $42, $53, $42, $4b, $46, $4b, $44, $5f
    db $ef, $ee, $32, $4f, $62, $46, $50, $62, $46, $51, $62, $41, $3e, $56, $64, $fa
    db $f7, $ef, $ee, $9f, $a3, $2c, $6a, $62, $3e, $4b, $62, $3e, $50, $50, $46, $50
    db $51, $3e, $4b, $51, $ef, $ee, $51, $4c, $62, $51, $45, $42, $62, $4d, $4f, $4c
    db $43, $42, $50, $50, $4c, $4f, $5f, $fa, $f7, $ef, $ee, $2b, $42, $42, $62, $2b
    db $42, $42, $5f, $ef, $ee, $f7, $f0
TextStr_44_41ae:           ; id $0199
    ; "[HERO] looked at the bookshelf. / :My research on monsters... / :Each monster family has its / characteristics. / :For example, Slimes easil..."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $3e, $51, $ef, $ee, $51, $45, $42
    db $62, $3f, $4c, $4c, $48, $50, $45, $42, $49, $43, $5f, $fa, $f7, $ef, $ee, $a3
    db $30, $56, $62, $4f, $42, $50, $42, $3e, $4f, $40, $45, $62, $4c, $4b, $ef, $ee
    db $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $a3
    db $28, $3e, $40, $45, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $ef, $ee, $43, $3e
    db $4a, $46, $49, $56, $62, $45, $3e, $50, $62, $46, $51, $50, $fa, $f7, $ef, $ee
    db $40, $45, $3e, $4f, $3e, $40, $51, $42, $4f, $46, $50, $51, $46, $40, $50, $5f
    db $ef, $ee, $fa, $f7, $ef, $ee, $a3, $29, $4c, $4f, $62, $42, $55, $3e, $4a, $4d
    db $49, $42, $5e, $ef, $ee, $36, $49, $46, $4a, $42, $50, $62, $42, $3e, $50, $46
    db $49, $56, $fa, $f7, $ef, $ee, $46, $4b, $40, $4f, $42, $3e, $50, $42, $62, $51
    db $45, $42, $46, $4f, $ef, $ee, $3e, $44, $46, $49, $46, $51, $56, $5f, $fa, $f7
    db $ef, $ee, $a3, $37, $45, $42, $56, $62, $45, $3e, $53, $42, $62, $50, $51, $4f
    db $4c, $4b, $44, $ef, $ee, $4f, $42, $50, $46, $50, $51, $3e, $4b, $40, $42, $62
    db $51, $4c, $fa, $f7, $ef, $ee, $50, $52, $4d, $4d, $4c, $4f, $51, $46, $4b, $44
    db $62, $50, $4d, $42, $49, $49, $50, $ef, $ee, $50, $52, $40, $45, $62, $3e, $50
    db $62, $36, $49, $4c, $54, $24, $49, $49, $62, $b6, $fa, $f7, $ef, $ee, $36, $3e
    db $4d, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $a3, $27, $42, $53, $46, $49, $50, $62
    db $b6, $62, $27, $4f, $3e, $44, $4c, $4b, $50, $ef, $ee, $3e, $4f, $42, $62, $4f
    db $42, $50, $46, $50, $51, $3e, $4b, $51, $62, $51, $4c, $fa, $f7, $ef, $ee, $43
    db $46, $4f, $42, $62, $50, $4d, $42, $49, $49, $50, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $a3, $2c, $62, $54, $3e, $4b, $51, $62, $3e, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $ef, $ee, $54, $46, $51, $45, $62, $3e, $49, $49, $62, $51, $45, $42
    db $50, $42, $fa, $f7, $ef, $ee, $40, $45, $3e, $4f, $3e, $40, $51, $42, $4f, $46
    db $50, $51, $46, $40, $50, $63, $ef, $ee, $f7, $f0
TextStr_44_4328:           ; id $019A
    ; "[HERO] looked at the bookshelf. / :The secret of GreatTree... / :Not only GreatTree, but / also other kingdoms are / created inside big tree..."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $3e, $51, $ef, $ee, $51, $45, $42
    db $62, $3f, $4c, $4c, $48, $50, $45, $42, $49, $43, $5f, $fa, $f7, $ef, $ee, $a3
    db $37, $45, $42, $62, $50, $42, $40, $4f, $42, $51, $62, $4c, $43, $ef, $ee, $2a
    db $4f, $42, $3e, $51, $37, $4f, $42, $42, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $a3
    db $31, $4c, $51, $62, $4c, $4b, $49, $56, $ef, $ee, $2a, $4f, $42, $3e, $51, $37
    db $4f, $42, $42, $5e, $62, $3f, $52, $51, $fa, $f7, $ef, $ee, $3e, $49, $50, $4c
    db $62, $4c, $51, $45, $42, $4f, $ef, $ee, $48, $46, $4b, $44, $41, $4c, $4a, $50
    db $62, $3e, $4f, $42, $fa, $f7, $ef, $ee, $40, $4f, $42, $3e, $51, $42, $41, $62
    db $46, $4b, $50, $46, $41, $42, $ef, $ee, $3f, $46, $44, $62, $51, $4f, $42, $42
    db $50, $5f, $fa, $f7, $ef, $ee, $a3, $37, $4f, $42, $42, $50, $62, $44, $4f, $4c
    db $54, $62, $3e, $4b, $41, $ef, $ee, $41, $46, $42, $5f, $62, $37, $45, $52, $50
    db $5e, $62, $51, $45, $42, $4f, $42, $fa, $f7, $ef, $ee, $46, $50, $62, $3e, $62
    db $49, $46, $43, $42, $62, $50, $4d, $3e, $4b, $62, $43, $4c, $4f, $ef, $ee, $51
    db $4f, $42, $42, $62, $48, $46, $4b, $44, $41, $4c, $4a, $5f, $fa, $f7, $ef, $ee
    db $a3, $37, $45, $42, $62, $48, $46, $4b, $44, $41, $4c, $4a, $5e, $ef, $ee, $3e
    db $4d, $4d, $4f, $4c, $4d, $4f, $46, $3e, $51, $42, $49, $56, $fa, $f7, $ef, $ee
    db $4b, $3e, $4a, $42, $41, $5e, $62, $27, $42, $3e, $41, $37, $4f, $42, $42, $5e
    db $ef, $ee, $46, $50, $62, $3e, $49, $4a, $4c, $50, $51, $fa, $f7, $ef, $ee, $43
    db $46, $4b, $46, $50, $45, $42, $41, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $a3, $24
    db $50, $62, $51, $4f, $42, $42, $50, $62, $41, $46, $42, $5e, $62, $4b, $42, $54
    db $ef, $ee, $4c, $4b, $42, $50, $62, $4f, $42, $4d, $49, $3e, $40, $42, $62, $51
    db $45, $42, $4a, $5f, $fa, $f7, $ef, $ee, $a3, $2b, $4c, $54, $42, $53, $42, $4f
    db $5e, $62, $46, $51, $62, $50, $42, $42, $4a, $50, $ef, $ee, $4a, $3e, $4b, $56
    db $62, $4b, $42, $54, $62, $51, $4f, $42, $42, $50, $62, $3e, $4f, $42, $fa, $f7
    db $ef, $ee, $3f, $4c, $4f, $4b, $62, $4c, $4b, $62, $51, $45, $42, $62, $36, $51
    db $3e, $4f, $4f, $56, $ef, $ee, $31, $46, $44, $45, $51, $5f, $f7, $f0
TextStr_44_44c6:           ; id $019B
    ; "[HERO] looked at the bookshelf. / :The Master Monster Tamer... / :An old man who breeds new species / by wedding monsters. / :I wonder how t..."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $3e, $51, $ef, $ee, $51, $45, $42
    db $62, $3f, $4c, $4c, $48, $50, $45, $42, $49, $43, $5f, $fa, $f7, $ef, $ee, $a3
    db $37, $45, $42, $62, $30, $3e, $50, $51, $42, $4f, $ef, $ee, $30, $4c, $4b, $50
    db $51, $42, $4f, $62, $37, $3e, $4a, $42, $4f, $5f, $5f, $5f, $fa, $f7, $ef, $ee
    db $a3, $24, $4b, $62, $4c, $49, $41, $62, $4a, $3e, $4b, $62, $54, $45, $4c, $ef
    db $ee, $3f, $4f, $42, $42, $41, $50, $62, $4b, $42, $54, $62, $50, $4d, $42, $40
    db $46, $42, $50, $fa, $f7, $ef, $ee, $3f, $56, $62, $54, $42, $41, $41, $46, $4b
    db $44, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f, $fa, $f7, $ef, $ee
    db $a3, $2c, $62, $54, $4c, $4b, $41, $42, $4f, $62, $45, $4c, $54, $ef, $ee, $51
    db $45, $46, $50, $62, $46, $50, $62, $4d, $4c, $50, $50, $46, $3f, $49, $42, $64
    db $fa, $f7, $ef, $ee, $a3, $37, $45, $42, $62, $50, $42, $40, $4f, $42, $51, $62
    db $4a, $52, $50, $51, $ef, $ee, $3f, $42, $62, $46, $4b, $62, $51, $45, $42, $62
    db $36, $45, $4f, $46, $4b, $42, $fa, $f7, $ef, $ee, $4c, $43, $62, $36, $51, $3e
    db $4f, $4f, $56, $62, $31, $46, $44, $45, $51, $63, $ef, $ee, $f7, $f0
TextStr_44_45a4:           ; id $019C
    ; "[HERO] looked into the jar. / It was a denture case for an old / woman."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $46, $4b, $51, $4c, $ef, $ee, $51
    db $45, $42, $62, $47, $3e, $4f, $5f, $fa, $f7, $ef, $ee, $2c, $51, $62, $54, $3e
    db $50, $62, $3e, $62, $41, $42, $4b, $51, $52, $4f, $42, $ef, $ee, $40, $3e, $50
    db $42, $62, $43, $4c, $4f, $62, $3e, $4b, $62, $4c, $49, $41, $fa, $f7, $ef, $ee
    db $54, $4c, $4a, $3e, $4b, $5f, $ef, $ee, $f7, $f0
TextStr_44_45ee:           ; id $019D
    ; "[HERO] looked into the big kettle. / ...Some unknown liquid is boiling / & bubbling!"
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $46, $4b, $51, $4c, $ef, $ee, $51
    db $45, $42, $62, $3f, $46, $44, $62, $48, $42, $51, $51, $49, $42, $5f, $fa, $f7
    db $ef, $ee, $5f, $5f, $5f, $36, $4c, $4a, $42, $62, $52, $4b, $48, $4b, $4c, $54
    db $4b, $ef, $ee, $49, $46, $4e, $52, $46, $41, $62, $46, $50, $62, $3f, $4c, $46
    db $49, $46, $4b, $44, $fa, $f7, $ef, $ee, $b6, $62, $3f, $52, $3f, $3f, $49, $46
    db $4b, $44, $63, $ef, $ee, $f7, $f0
TextStr_44_4645:           ; id $019E
    ; "*:Welcome to the Master School! / *:[HERO]! It was an excellent / fight! / *:Today's lecture is about how to / snare a monster. Want to list..."
    db $ea, $9f, $a3, $3a, $42, $49, $40, $4c, $4a, $42, $62, $51, $4c, $62, $51, $45
    db $42, $ef, $ee, $30, $3e, $50, $51, $42, $4f, $62, $36, $40, $45, $4c, $4c, $49
    db $63, $fa, $f7, $ef, $ee, $9f, $a3, $f6, $63, $62, $2c, $51, $62, $54, $3e, $50
    db $ef, $ee, $3e, $4b, $62, $42, $55, $40, $42, $49, $49, $42, $4b, $51, $fa, $f7
    db $ef, $ee, $43, $46, $44, $45, $51, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $37, $4c, $41, $3e, $56, $68, $62, $49, $42, $40, $51, $52, $4f, $42, $ef, $ee
    db $46, $50, $62, $3e, $3f, $4c, $52, $51, $62, $45, $4c, $54, $62, $51, $4c, $fa
    db $f7, $ef, $ee, $50, $4b, $3e, $4f, $42, $62, $3e, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $5f, $ef, $ee, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $49, $46, $50
    db $51, $42, $4b, $64, $ff, $f0
TextStr_44_46db:           ; id $019F
    ; "*:It's always better to have a / WarpWing with you. / *:Then you can come back to the / castle anytime."
    db $eb, $9f, $a3, $2c, $51, $68, $62, $3e, $49, $54, $3e, $56, $50, $ef, $ee, $3f
    db $42, $51, $51, $42, $4f, $62, $51, $4c, $62, $45, $3e, $53, $42, $62, $3e, $fa
    db $f7, $ef, $ee, $3a, $3e, $4f, $4d, $3a, $46, $4b, $44, $62, $54, $46, $51, $45
    db $62, $56, $4c, $52, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42
    db $4b, $62, $56, $4c, $52, $62, $40, $3e, $4b, $ef, $ee, $40, $4c, $4a, $42, $62
    db $3f, $3e, $40, $48, $62, $51, $4c, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $40
    db $3e, $50, $51, $49, $42, $62, $3e, $4b, $56, $51, $46, $4a, $42, $5f, $ef, $ee
    db $f7, $f0
TextStr_44_474d:           ; id $01A0
    ; "*:You are good. You beat the / teacher!"
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $3e, $4f, $42, $62, $44, $4c, $4c, $41, $5f
    db $ef, $ee, $3c, $4c, $52, $62, $3f, $42, $3e, $51, $62, $51, $45, $42, $fa, $f7
    db $ef, $ee, $51, $42, $3e, $40, $45, $42, $4f, $63, $ef, $ee, $f7, $f0
TextStr_44_477b:           ; id $01A1
    ; "*:Here's the Room of Villager / & Talisman. / *:Go up to the Gate of Villager / or down to the Gate of Talisman."
    db $ea, $9f, $a3, $2b, $42, $4f, $42, $68, $62, $51, $45, $42, $ef, $ee, $35, $4c
    db $4c, $4a, $62, $4c, $43, $62, $39, $46, $49, $49, $3e, $44, $42, $4f, $fa, $f7
    db $ef, $ee, $b6, $62, $37, $3e, $49, $46, $50, $4a, $3e, $4b, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $2a, $4c, $62, $52, $4d, $62, $51, $4c, $62, $51, $45
    db $42, $ef, $ee, $2a, $3e, $51, $42, $62, $4c, $43, $62, $39, $46, $49, $49, $3e
    db $44, $42, $4f, $fa, $f7, $ef, $ee, $4c, $4f, $62, $41, $4c, $54, $4b, $62, $51
    db $4c, $62, $51, $45, $42, $ef, $ee, $2a, $3e, $51, $42, $62, $4c, $43, $62, $37
    db $3e, $49, $46, $50, $4a, $3e, $4b, $5f, $f7, $f0
TextStr_44_47f5:           ; id $01A2
    ; "*:I'm conducting secret research / at the bottom of the well. / *:And I'm a super top class monster / master. / *:Come on! Try to take me!"
    db $ea, $9f, $a3, $2c, $6a, $62, $40, $4c, $4b, $41, $52, $40, $51, $46, $4b, $44
    db $ef, $ee, $50, $42, $40, $4f, $42, $51, $62, $4f, $42, $50, $42, $3e, $4f, $40
    db $45, $fa, $f7, $ef, $ee, $3e, $51, $62, $51, $45, $42, $62, $3f, $4c, $51, $51
    db $4c, $4a, $62, $4c, $43, $ef, $ee, $51, $45, $42, $62, $54, $42, $49, $49, $5f
    db $fa, $f7, $ef, $ee, $9f, $a3, $24, $4b, $41, $62, $2c, $6a, $62, $3e, $62, $50
    db $52, $4d, $42, $4f, $ef, $ee, $51, $4c, $4d, $62, $40, $49, $3e, $50, $50, $62
    db $4a, $4c, $4b, $50, $51, $42, $4f, $fa, $f7, $ef, $ee, $4a, $3e, $50, $51, $42
    db $4f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $26, $4c, $4a, $42, $62, $4c
    db $4b, $63, $62, $37, $4f, $56, $62, $51, $4c, $ef, $ee, $51, $3e, $48, $42, $62
    db $4a, $42, $63, $f7, $f0
TextStr_44_488a:           ; id $01A3
    ; "*:Being a master and a fighter / is one form of research. / *:Try me!"
    db $ea, $9f, $a3, $25, $42, $46, $4b, $44, $62, $3e, $62, $4a, $3e, $50, $51, $42
    db $4f, $ef, $ee, $3e, $4b, $41, $62, $3e, $62, $43, $46, $44, $45, $51, $42, $4f
    db $fa, $f7, $ef, $ee, $46, $50, $62, $4c, $4b, $42, $62, $43, $4c, $4f, $4a, $62
    db $4c, $43, $ef, $ee, $4f, $42, $50, $42, $3e, $4f, $40, $45, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $37, $4f, $56, $62, $4a, $42, $63, $ef, $ee, $f7, $f0
TextStr_44_48d8:           ; id $01A4
    ; "*:Congratulations on surviving F / class. / *:The Room of Memories & / Bewilder are now open as your / prize. / *:Go to the Shrine of Starry..."
    db $ea, $9f, $a3, $26, $4c, $4b, $44, $4f, $3e, $51, $52, $49, $3e, $51, $46, $4c
    db $4b, $50, $ef, $ee, $4c, $4b, $62, $50, $52, $4f, $53, $46, $53, $46, $4b, $44
    db $62, $29, $fa, $f7, $ef, $ee, $40, $49, $3e, $50, $50, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $37, $45, $42, $62, $35, $4c, $4c, $4a, $62, $4c, $43, $ef
    db $ee, $30, $42, $4a, $4c, $4f, $46, $42, $50, $62, $b6, $fa, $f7, $ef, $ee, $25
    db $42, $54, $46, $49, $41, $42, $4f, $62, $3e, $4f, $42, $62, $4b, $4c, $54, $ef
    db $ee, $4c, $4d, $42, $4b, $62, $3e, $50, $62, $56, $4c, $52, $4f, $fa, $f7, $ef
    db $ee, $4d, $4f, $46, $57, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2a
    db $4c, $62, $51, $4c, $62, $51, $45, $42, $62, $36, $45, $4f, $46, $4b, $42, $ef
    db $ee, $4c, $43, $62, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45, $51
    db $fa, $f7, $ef, $ee, $43, $4c, $4f, $62, $3f, $4f, $42, $42, $41, $46, $4b, $44
    db $62, $b6, $ef, $ee, $45, $3e, $51, $40, $45, $46, $4b, $44, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $3c, $4c, $52, $66, $49, $62, $43, $46, $4b, $41, $62, $46, $51
    db $ef, $ee, $54, $45, $42, $4b, $62, $56, $4c, $52, $62, $44, $4c, $62, $51, $4c
    db $62, $51, $45, $42, $fa, $f7, $ef, $ee, $53, $46, $49, $49, $3e, $44, $42, $62
    db $43, $4f, $4c, $4a, $62, $51, $45, $42, $ef, $ee, $26, $3e, $50, $51, $49, $42
    db $62, $3e, $4b, $41, $62, $44, $4c, $fa, $f7, $ef, $ee, $41, $4c, $54, $4b, $5f
    db $ef, $ee, $f7, $f0
TextStr_44_49ec:           ; id $01A5
    ; "*:Are you familiar with the Gate of / Bewilder? [YES/NO]"
    db $eb, $9f, $a3, $24, $4f, $42, $62, $56, $4c, $52, $62, $43, $3e, $4a, $46, $49
    db $46, $3e, $4f, $ef, $ee, $54, $46, $51, $45, $62, $51, $45, $42, $62, $2a, $3e
    db $51, $42, $62, $4c, $43, $fa, $f7, $ef, $ee, $25, $42, $54, $46, $49, $41, $42
    db $4f, $64, $ef, $ee, $ff, $f0
TextStr_44_4a22:           ; id $01A6
    ; "*:My years of research lead me / to believe that... / *:Sometimes mushrooms, rocks / & trees with faces are born. / *:From the report of the..."
    db $eb, $9f, $a3, $30, $56, $62, $56, $42, $3e, $4f, $50, $62, $4c, $43, $ef, $ee
    db $4f, $42, $50, $42, $3e, $4f, $40, $45, $62, $49, $42, $3e, $41, $62, $4a, $42
    db $fa, $f7, $ef, $ee, $51, $4c, $62, $3f, $42, $49, $46, $42, $53, $42, $ef, $ee
    db $51, $45, $3e, $51, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $36, $4c, $4a
    db $42, $51, $46, $4a, $42, $50, $ef, $ee, $4a, $52, $50, $45, $4f, $4c, $4c, $4a
    db $50, $5e, $62, $4f, $4c, $40, $48, $50, $fa, $f7, $ef, $ee, $b6, $62, $51, $4f
    db $42, $42, $50, $62, $54, $46, $51, $45, $62, $43, $3e, $40, $42, $50, $ef, $ee
    db $3e, $4f, $42, $62, $3f, $4c, $4f, $4b, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $29
    db $4f, $4c, $4a, $62, $51, $45, $42, $62, $4f, $42, $4d, $4c, $4f, $51, $ef, $ee
    db $4c, $43, $62, $51, $45, $42, $62, $43, $46, $4f, $50, $51, $fa, $f7, $ef, $ee
    db $41, $46, $4f, $42, $40, $51, $4c, $4f, $62, $4c, $43, $62, $51, $45, $42, $ef
    db $ee, $49, $46, $3f, $4f, $3e, $4f, $56, $5f, $f7, $f0
TextStr_44_4add:           ; id $01A7
    ; "*:Are you familiar with the Gate of / Memories? [YES/NO]"
    db $eb, $9f, $a3, $24, $4f, $42, $62, $56, $4c, $52, $62, $43, $3e, $4a, $46, $49
    db $46, $3e, $4f, $ef, $ee, $54, $46, $51, $45, $62, $51, $45, $42, $62, $2a, $3e
    db $51, $42, $62, $4c, $43, $fa, $f7, $ef, $ee, $30, $42, $4a, $4c, $4f, $46, $42
    db $50, $64, $ef, $ee, $ff, $f0
TextStr_44_4b13:           ; id $01A8
    ; "*:A monster is living deep in a / cave. / *:The monster screams with a / peculiar voice as if it is calling / someone. / *:From the journey ..."
    db $eb, $9f, $a3, $24, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $46, $50, $ef
    db $ee, $49, $46, $53, $46, $4b, $44, $62, $41, $42, $42, $4d, $62, $46, $4b, $62
    db $3e, $fa, $f7, $ef, $ee, $40, $3e, $53, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $37, $45, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $ef, $ee, $50
    db $40, $4f, $42, $3e, $4a, $50, $62, $54, $46, $51, $45, $62, $3e, $fa, $f7, $ef
    db $ee, $4d, $42, $40, $52, $49, $46, $3e, $4f, $62, $53, $4c, $46, $40, $42, $62
    db $3e, $50, $ef, $ee, $46, $43, $62, $46, $51, $62, $46, $50, $62, $40, $3e, $49
    db $49, $46, $4b, $44, $fa, $f7, $ef, $ee, $50, $4c, $4a, $42, $4c, $4b, $42, $5f
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $29, $4f, $4c, $4a, $62, $51, $45, $42
    db $62, $47, $4c, $52, $4f, $4b, $42, $56, $ef, $ee, $41, $46, $3e, $4f, $56, $62
    db $4c, $43, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $49, $42, $44, $42, $4b, $41
    db $3e, $4f, $56, $62, $4a, $3e, $50, $51, $42, $4f, $ef, $ee, $30, $3e, $4f, $56
    db $5f, $f7, $f0
TextStr_44_4bd6:           ; id $01A9
    ; "*:I would like to tell you more. / Do you mind? [YES/NO]"
    db $eb, $9f, $a3, $2c, $62, $54, $4c, $52, $49, $41, $62, $49, $46, $48, $42, $62
    db $51, $4c, $ef, $ee, $51, $42, $49, $49, $62, $56, $4c, $52, $62, $4a, $4c, $4f
    db $42, $5f, $fa, $f7, $ef, $ee, $27, $4c, $62, $56, $4c, $52, $62, $4a, $46, $4b
    db $41, $64, $ef, $ee, $ff, $f0
TextStr_44_4c0c:           ; id $01AA
    ; "*:The devil settled in a / town of ruins. / *:As if a guardian of the ruins... / *:This is the last record of the lost / town."
    db $eb, $9f, $a3, $37, $45, $42, $62, $41, $42, $53, $46, $49, $ef, $ee, $50, $42
    db $51, $51, $49, $42, $41, $62, $46, $4b, $62, $3e, $fa, $f7, $ef, $ee, $51, $4c
    db $54, $4b, $62, $4c, $43, $62, $4f, $52, $46, $4b, $50, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $24, $50, $62, $46, $43, $62, $3e, $62, $44, $52, $3e, $4f
    db $41, $46, $3e, $4b, $ef, $ee, $4c, $43, $62, $51, $45, $42, $62, $4f, $52, $46
    db $4b, $50, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $46, $50, $62
    db $46, $50, $62, $51, $45, $42, $62, $49, $3e, $50, $51, $ef, $ee, $4f, $42, $40
    db $4c, $4f, $41, $62, $4c, $43, $62, $51, $45, $42, $62, $49, $4c, $50, $51, $fa
    db $f7, $ef, $ee, $51, $4c, $54, $4b, $5f, $ef, $ee, $f7, $f0
TextStr_44_4c98:           ; id $01AB
    ; "King:Oh [HERO]! You beat MadCat! / King:They say MadCat has the / agility of the wind. / King:Your agility must be like a / tornado!"
    db $ea, $2e, $46, $4b, $44, $a3, $32, $45, $62, $f6, $63, $ef, $ee, $3c, $4c, $52
    db $62, $3f, $42, $3e, $51, $62, $30, $3e, $41, $26, $3e, $51, $63, $fa, $f7, $ef
    db $ee, $2e, $46, $4b, $44, $a3, $37, $45, $42, $56, $62, $50, $3e, $56, $ef, $ee
    db $30, $3e, $41, $26, $3e, $51, $62, $45, $3e, $50, $62, $51, $45, $42, $fa, $f7
    db $ef, $ee, $3e, $44, $46, $49, $46, $51, $56, $62, $4c, $43, $62, $51, $45, $42
    db $ef, $ee, $54, $46, $4b, $41, $5f, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3
    db $3c, $4c, $52, $4f, $62, $3e, $44, $46, $49, $46, $51, $56, $ef, $ee, $4a, $52
    db $50, $51, $62, $3f, $42, $62, $49, $46, $48, $42, $62, $3e, $fa, $f7, $ef, $ee
    db $51, $4c, $4f, $4b, $3e, $41, $4c, $63, $ef, $ee, $f7, $f0
TextStr_44_4d24:           ; id $01AC
    ; "King:It reminds me. Have you been / going to the Shrine of Starry / Night to breed your monsters? / King:Master breeding and you / will mast..."
    db $ea, $2e, $46, $4b, $44, $a3, $2c, $51, $62, $4f, $42, $4a, $46, $4b, $41, $50
    db $ef, $ee, $4a, $42, $5f, $62, $2b, $3e, $53, $42, $62, $56, $4c, $52, $62, $3f
    db $42, $42, $4b, $fa, $f7, $ef, $ee, $44, $4c, $46, $4b, $44, $62, $51, $4c, $62
    db $51, $45, $42, $ef, $ee, $36, $45, $4f, $46, $4b, $42, $62, $4c, $43, $62, $36
    db $51, $3e, $4f, $4f, $56, $fa, $f7, $ef, $ee, $31, $46, $44, $45, $51, $62, $51
    db $4c, $62, $3f, $4f, $42, $42, $41, $ef, $ee, $56, $4c, $52, $4f, $62, $4a, $4c
    db $4b, $50, $51, $42, $4f, $50, $64, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3
    db $30, $3e, $50, $51, $42, $4f, $ef, $ee, $3f, $4f, $42, $42, $41, $46, $4b, $44
    db $62, $3e, $4b, $41, $62, $56, $4c, $52, $fa, $f7, $ef, $ee, $54, $46, $49, $49
    db $62, $4a, $3e, $50, $51, $42, $4f, $ef, $ee, $3f, $3e, $51, $51, $49, $42, $5f
    db $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $25, $42, $51, $51, $42, $4f, $ef
    db $ee, $3f, $4f, $42, $42, $41, $46, $4b, $44, $62, $4a, $3e, $48, $42, $50, $fa
    db $f7, $ef, $ee, $50, $51, $4f, $4c, $4b, $44, $42, $4f, $62, $4a, $4c, $4b, $50
    db $51, $42, $4f, $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3
    db $3c, $4c, $52, $62, $3e, $4f, $42, $ef, $ee, $41, $46, $50, $4a, $46, $50, $50
    db $42, $41, $5f, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $25, $52, $50, $56
    db $63, $62, $25, $52, $50, $56, $63, $ef, $ee, $25, $52, $50, $56, $63, $f7, $f0
TextStr_44_4e34:           ; id $01AD
    ; "*:Starry Night Tournament is a / match among kingdoms. / *:The contestants in the Tournament / are the kingdoms of BigTrunk, / DeadTree & Gr..."
    db $ea, $9f, $a3, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45, $51, $ef
    db $ee, $37, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $62, $46, $50, $62, $3e
    db $fa, $f7, $ef, $ee, $4a, $3e, $51, $40, $45, $62, $3e, $4a, $4c, $4b, $44, $ef
    db $ee, $48, $46, $4b, $44, $41, $4c, $4a, $50, $5f, $fa, $f7, $ef, $ee, $9f, $a3
    db $37, $45, $42, $62, $40, $4c, $4b, $51, $42, $50, $51, $3e, $4b, $51, $50, $ef
    db $ee, $46, $4b, $62, $51, $45, $42, $62, $37, $4c, $52, $4f, $4b, $3e, $4a, $42
    db $4b, $51, $fa, $f7, $ef, $ee, $3e, $4f, $42, $62, $51, $45, $42, $62, $48, $46
    db $4b, $44, $41, $4c, $4a, $50, $ef, $ee, $4c, $43, $62, $25, $46, $44, $37, $4f
    db $52, $4b, $48, $5e, $fa, $f7, $ef, $ee, $27, $42, $3e, $41, $37, $4f, $42, $42
    db $62, $b6, $ef, $ee, $2a, $4f, $42, $3e, $51, $2f, $4c, $44, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $2c, $43, $62, $56, $4c, $52, $62, $41, $42, $43, $42, $3e, $51
    db $ef, $ee, $51, $45, $42, $50, $42, $62, $03, $62, $48, $46, $4b, $44, $41, $4c
    db $4a, $50, $5e, $fa, $f7, $ef, $ee, $53, $46, $40, $51, $4c, $4f, $56, $62, $46
    db $50, $62, $56, $4c, $52, $4f, $50, $63, $ef, $ee, $f7, $f0
TextStr_44_4f10:           ; id $01AE
    ; "King:Oh [HERO]! You defeated / FaceTree! / King:I heard FaceTree casts / curses. / King:Why don't you cast a curse on / the King of GreatLog..."
    db $ea, $2e, $46, $4b, $44, $a3, $32, $45, $62, $f6, $63, $ef, $ee, $3c, $4c, $52
    db $62, $41, $42, $43, $42, $3e, $51, $42, $41, $fa, $f7, $ef, $ee, $29, $3e, $40
    db $42, $37, $4f, $42, $42, $63, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44
    db $a3, $2c, $62, $45, $42, $3e, $4f, $41, $ef, $ee, $29, $3e, $40, $42, $37, $4f
    db $42, $42, $62, $40, $3e, $50, $51, $50, $fa, $f7, $ef, $ee, $40, $52, $4f, $50
    db $42, $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $3a, $45
    db $56, $62, $41, $4c, $4b, $67, $62, $56, $4c, $52, $ef, $ee, $40, $3e, $50, $51
    db $62, $3e, $62, $40, $52, $4f, $50, $42, $62, $4c, $4b, $fa, $f7, $ef, $ee, $51
    db $45, $42, $62, $2e, $46, $4b, $44, $62, $4c, $43, $ef, $ee, $2a, $4f, $42, $3e
    db $51, $2f, $4c, $44, $64, $f7, $f0
TextStr_44_4fa7:           ; id $01AF
    ; "*:The girl down below who blocked / a path moved away! / *:She came to see you fight."
    db $ea, $9f, $a3, $37, $45, $42, $62, $44, $46, $4f, $49, $62, $41, $4c, $54, $4b
    db $ef, $ee, $3f, $42, $49, $4c, $54, $62, $54, $45, $4c, $62, $3f, $49, $4c, $40
    db $48, $42, $41, $fa, $f7, $ef, $ee, $3e, $62, $4d, $3e, $51, $45, $62, $4a, $4c
    db $53, $42, $41, $62, $3e, $54, $3e, $56, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $36, $45, $42, $62, $40, $3e, $4a, $42, $62, $51, $4c, $ef, $ee, $50, $42
    db $42, $62, $56, $4c, $52, $62, $43, $46, $44, $45, $51, $5f, $f7, $f0
TextStr_44_5005:           ; id $01B0
    ; "*:I want you to win the tournament / this time. / *:I heard that wishes come true / if you win the tournament. / *:But I wonder, what would ..."
    db $eb, $9f, $a3, $2c, $62, $54, $3e, $4b, $51, $62, $56, $4c, $52, $62, $51, $4c
    db $ef, $ee, $54, $46, $4b, $62, $51, $45, $42, $62, $51, $4c, $52, $4f, $4b, $3e
    db $4a, $42, $4b, $51, $fa, $f7, $ef, $ee, $51, $45, $46, $50, $62, $51, $46, $4a
    db $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $45, $42, $3e, $4f
    db $41, $62, $51, $45, $3e, $51, $ef, $ee, $54, $46, $50, $45, $42, $50, $62, $40
    db $4c, $4a, $42, $62, $51, $4f, $52, $42, $fa, $f7, $ef, $ee, $46, $43, $62, $56
    db $4c, $52, $62, $54, $46, $4b, $62, $51, $45, $42, $ef, $ee, $51, $4c, $52, $4f
    db $4b, $3e, $4a, $42, $4b, $51, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $25, $52, $51
    db $62, $2c, $62, $54, $4c, $4b, $41, $42, $4f, $5e, $ef, $ee, $54, $45, $3e, $51
    db $62, $54, $4c, $52, $49, $41, $62, $56, $4c, $52, $4f, $fa, $f7, $ef, $ee, $54
    db $46, $50, $45, $62, $3f, $42, $62, $46, $43, $62, $56, $4c, $52, $ef, $ee, $54
    db $46, $4b, $64, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45, $3e, $51, $64, $62, $30
    db $3e, $50, $51, $42, $4f, $ef, $ee, $30, $4c, $4b, $50, $51, $42, $4f, $62, $37
    db $3e, $4a, $42, $4f, $64, $fa, $f7, $ef, $ee, $2b, $42, $68, $62, $41, $4c, $54
    db $4b, $62, $3f, $42, $49, $4c, $54, $63, $ef, $ee, $f7, $f0
TextStr_44_50f1:           ; id $01B1
    ; "*:I heard you got stronger. / *:But I still don't think / you'll win."
    db $eb, $9f, $a3, $2c, $62, $45, $42, $3e, $4f, $41, $62, $56, $4c, $52, $62, $44
    db $4c, $51, $ef, $ee, $50, $51, $4f, $4c, $4b, $44, $42, $4f, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $25, $52, $51, $62, $2c, $62, $50, $51, $46, $49, $49, $ef, $ee
    db $41, $4c, $4b, $67, $62, $51, $45, $46, $4b, $48, $fa, $f7, $ef, $ee, $56, $4c
    db $52, $66, $49, $62, $54, $46, $4b, $5f, $ef, $ee, $f7, $f0
TextStr_44_513d:           ; id $01B2
    ; "*:Whew! At last we made it to the / bottom. / *:The stairs below lead to the Shrine / of Starry Night."
    db $ea, $9f, $a3, $3a, $45, $42, $54, $63, $62, $24, $51, $62, $49, $3e, $50, $51
    db $ef, $ee, $54, $42, $62, $4a, $3e, $41, $42, $62, $46, $51, $62, $51, $4c, $62
    db $51, $45, $42, $fa, $f7, $ef, $ee, $3f, $4c, $51, $51, $4c, $4a, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $50, $51, $3e, $46, $4f, $50
    db $62, $3f, $42, $49, $4c, $54, $ef, $ee, $49, $42, $3e, $41, $62, $51, $4c, $62
    db $51, $45, $42, $62, $36, $45, $4f, $46, $4b, $42, $fa, $f7, $ef, $ee, $4c, $43
    db $62, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45, $51, $5f, $ef, $ee
    db $f7, $f0
TextStr_44_51af:           ; id $01B3
    ; "*:Meet the old man of the Shrine / of Starry Night. / *:Meeting him will change / your future!!"
    db $eb, $9f, $a3, $30, $42, $42, $51, $62, $51, $45, $42, $62, $4c, $49, $41, $62
    db $4a, $3e, $4b, $ef, $ee, $4c, $43, $62, $51, $45, $42, $62, $36, $45, $4f, $46
    db $4b, $42, $fa, $f7, $ef, $ee, $4c, $43, $62, $36, $51, $3e, $4f, $4f, $56, $62
    db $31, $46, $44, $45, $51, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $30, $42
    db $42, $51, $46, $4b, $44, $62, $45, $46, $4a, $ef, $ee, $54, $46, $49, $49, $62
    db $40, $45, $3e, $4b, $44, $42, $fa, $f7, $ef, $ee, $56, $4c, $52, $4f, $62, $43
    db $52, $51, $52, $4f, $42, $63, $63, $ef, $ee, $f7, $f0
TextStr_44_521a:           ; id $01B4
    ; "*:Here you are at the Chamber of / Travelers' Gates. / *:The Room of Memories & / Bewilder are now open! / *:Healer will heal your monsters ..."
    db $ea, $9f, $a3, $2b, $42, $4f, $42, $62, $56, $4c, $52, $62, $3e, $4f, $42, $62
    db $3e, $51, $ef, $ee, $51, $45, $42, $62, $26, $45, $3e, $4a, $3f, $42, $4f, $62
    db $4c, $43, $fa, $f7, $ef, $ee, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c
    db $62, $2a, $3e, $51, $42, $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37
    db $45, $42, $62, $35, $4c, $4c, $4a, $62, $4c, $43, $ef, $ee, $30, $42, $4a, $4c
    db $4f, $46, $42, $50, $62, $b6, $fa, $f7, $ef, $ee, $25, $42, $54, $46, $49, $41
    db $42, $4f, $62, $3e, $4f, $42, $ef, $ee, $4b, $4c, $54, $62, $4c, $4d, $42, $4b
    db $63, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $42, $3e, $49, $42, $4f, $62, $54, $46
    db $49, $49, $ef, $ee, $45, $42, $3e, $49, $62, $56, $4c, $52, $4f, $62, $4a, $4c
    db $4b, $50, $51, $42, $4f, $50, $fa, $f7, $ef, $ee, $54, $46, $51, $45, $62, $45
    db $46, $50, $62, $50, $4d, $42, $49, $49, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $2c, $51, $68, $62, $53, $42, $4f, $56, $62, $52, $50, $42, $43, $52, $49
    db $ef, $ee, $27, $4c, $4b, $67, $62, $49, $42, $51, $62, $46, $51, $62, $44, $4c
    db $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $4f, $62, $30, $33, $62, $54
    db $46, $49, $49, $ef, $ee, $4f, $42, $40, $4c, $53, $42, $4f, $62, $3f, $46, $51
    db $62, $3f, $56, $fa, $f7, $ef, $ee, $3f, $46, $51, $62, $3e, $50, $62, $56, $4c
    db $52, $62, $54, $3e, $49, $48, $63, $ef, $ee, $f7, $f0
TextStr_44_5325:           ; id $01B5
    ; "*:The place to hatch eggs? / Now I remember! / *:S.t.a.r.r.y S.h.r.i.n.e! / It's the Shrine of Starry Night!"
    db $ea, $9f, $a3, $37, $45, $42, $62, $4d, $49, $3e, $40, $42, $62, $51, $4c, $ef
    db $ee, $45, $3e, $51, $40, $45, $62, $42, $44, $44, $50, $64, $fa, $f7, $ef, $ee
    db $31, $4c, $54, $62, $2c, $62, $4f, $42, $4a, $42, $4a, $3f, $42, $4f, $63, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $36, $5f, $51, $5f, $3e, $5f, $4f, $5f, $4f
    db $5f, $56, $ef, $ee, $36, $5f, $45, $5f, $4f, $5f, $46, $5f, $4b, $5f, $42, $63
    db $fa, $f7, $ef, $ee, $2c, $51, $68, $62, $51, $45, $42, $62, $36, $45, $4f, $46
    db $4b, $42, $62, $4c, $43, $ef, $ee, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46
    db $44, $45, $51, $63, $f7, $f0
TextStr_44_539b:           ; id $01B6
    ; "*:Well done! You survived / E class! / *:The King opened the Room of Peace / & Bravery for you! / *:More Travelers' Gates with / stronger mo..."
    db $ea, $9f, $a3, $3a, $42, $49, $49, $62, $41, $4c, $4b, $42, $63, $ef, $ee, $3c
    db $4c, $52, $62, $50, $52, $4f, $53, $46, $53, $42, $41, $fa, $f7, $ef, $ee, $28
    db $62, $40, $49, $3e, $50, $50, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37
    db $45, $42, $62, $2e, $46, $4b, $44, $62, $4c, $4d, $42, $4b, $42, $41, $ef, $ee
    db $51, $45, $42, $62, $35, $4c, $4c, $4a, $62, $4c, $43, $62, $33, $42, $3e, $40
    db $42, $fa, $f7, $ef, $ee, $b6, $62, $25, $4f, $3e, $53, $42, $4f, $56, $62, $43
    db $4c, $4f, $62, $56, $4c, $52, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $30
    db $4c, $4f, $42, $62, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $ef, $ee
    db $2a, $3e, $51, $42, $50, $62, $54, $46, $51, $45, $fa, $f7, $ef, $ee, $50, $51
    db $4f, $4c, $4b, $44, $42, $4f, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $ef
    db $ee, $3e, $4f, $42, $62, $54, $3e, $46, $51, $46, $4b, $44, $62, $43, $4c, $4f
    db $fa, $f7, $ef, $ee, $56, $4c, $52, $63, $ef, $ee, $f7, $f0
TextStr_44_5457:           ; id $01B7
    ; "*:Well done! You survived / E class! / *:The King opened the Room of Peace / & Bravery... and / *:Memories & Bewilder for you! / *:New adven..."
    db $ea, $9f, $a3, $3a, $42, $49, $49, $62, $41, $4c, $4b, $42, $63, $ef, $ee, $3c
    db $4c, $52, $62, $50, $52, $4f, $53, $46, $53, $42, $41, $fa, $f7, $ef, $ee, $28
    db $62, $40, $49, $3e, $50, $50, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37
    db $45, $42, $62, $2e, $46, $4b, $44, $62, $4c, $4d, $42, $4b, $42, $41, $ef, $ee
    db $51, $45, $42, $62, $35, $4c, $4c, $4a, $62, $4c, $43, $62, $33, $42, $3e, $40
    db $42, $fa, $f7, $ef, $ee, $b6, $62, $25, $4f, $3e, $53, $42, $4f, $56, $5f, $5f
    db $5f, $62, $3e, $4b, $41, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $30, $42, $4a
    db $4c, $4f, $46, $42, $50, $62, $b6, $ef, $ee, $25, $42, $54, $46, $49, $41, $42
    db $4f, $62, $43, $4c, $4f, $62, $56, $4c, $52, $63, $fa, $f7, $ef, $ee, $9f, $a3
    db $31, $42, $54, $62, $3e, $41, $53, $42, $4b, $51, $52, $4f, $42, $50, $ef, $ee
    db $3e, $4f, $42, $62, $54, $3e, $46, $51, $46, $4b, $44, $62, $43, $4c, $4f, $fa
    db $f7, $ef, $ee, $56, $4c, $52, $63, $ef, $ee, $f7, $f0
TextStr_44_5512:           ; id $01B8
    ; "*:The last match of the E class is / with.. / *:Master Teto!"
    db $eb, $9f, $a3, $37, $45, $42, $62, $49, $3e, $50, $51, $62, $4a, $3e, $51, $40
    db $45, $ef, $ee, $4c, $43, $62, $51, $45, $42, $62, $28, $62, $40, $49, $3e, $50
    db $50, $62, $46, $50, $fa, $f7, $ef, $ee, $54, $46, $51, $45, $5f, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $30, $3e, $50, $51, $42, $4f, $62, $37, $42, $51
    db $4c, $63, $ef, $ee, $f7, $f0
TextStr_44_5558:           ; id $01B9
    ; "*:Ha ha ha... It's E class. I / survived E class! / *:Oh, you're still in F class? / *:Call me Master Teto from now on!"
    db $ea, $9f, $a3, $2b, $3e, $62, $45, $3e, $62, $45, $3e, $5f, $5f, $5f, $ef, $ee
    db $2c, $51, $68, $62, $28, $62, $40, $49, $3e, $50, $50, $5f, $62, $2c, $fa, $f7
    db $ef, $ee, $50, $52, $4f, $53, $46, $53, $42, $41, $62, $28, $62, $40, $49, $3e
    db $50, $50, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $32, $45, $5e, $62, $56
    db $4c, $52, $69, $42, $62, $50, $51, $46, $49, $49, $ef, $ee, $46, $4b, $62, $29
    db $62, $40, $49, $3e, $50, $50, $64, $fa, $f7, $ef, $ee, $9f, $a3, $26, $3e, $49
    db $49, $62, $4a, $42, $62, $30, $3e, $50, $51, $42, $4f, $ef, $ee, $37, $42, $51
    db $4c, $62, $43, $4f, $4c, $4a, $62, $4b, $4c, $54, $62, $4c, $4b, $63, $f7, $f0
TextStr_44_55d8:           ; id $01BA
    ; "*:The bishop over there taught / me a song. / *:StepGuard's for Mimic, DarkCrab, / Droll, WingTree and GiantWorm... / *:MapMagic's for MadMi..."
    db $ea, $9f, $a3, $37, $45, $42, $62, $3f, $46, $50, $45, $4c, $4d, $ef, $ee, $4c
    db $53, $42, $4f, $62, $51, $45, $42, $4f, $42, $62, $51, $3e, $52, $44, $45, $51
    db $fa, $f7, $ef, $ee, $4a, $42, $62, $3e, $62, $50, $4c, $4b, $44, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $36, $51, $42, $4d, $2a, $52, $3e, $4f, $41, $68
    db $62, $43, $4c, $4f, $ef, $ee, $30, $46, $4a, $46, $40, $5e, $62, $27, $3e, $4f
    db $48, $26, $4f, $3e, $3f, $5e, $fa, $f7, $ef, $ee, $27, $4f, $4c, $49, $49, $5e
    db $62, $3a, $46, $4b, $44, $37, $4f, $42, $42, $ef, $ee, $3e, $4b, $41, $62, $2a
    db $46, $3e, $4b, $51, $3a, $4c, $4f, $4a, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f
    db $a3, $30, $3e, $4d, $30, $3e, $44, $46, $40, $68, $62, $43, $4c, $4f, $ef, $ee
    db $30, $3e, $41, $30, $46, $4f, $4f, $4c, $4f, $5e, $62, $28, $56, $42, $41, $42
    db $4f, $5e, $fa, $f7, $ef, $ee, $25, $42, $3e, $4b, $30, $3e, $4b, $62, $3e, $4b
    db $41, $ef, $ee, $28, $53, $46, $49, $3a, $3e, $4b, $41, $63, $fa, $f7, $ef, $ee
    db $9f, $a3, $39, $46, $53, $46, $43, $56, $68, $62, $43, $4c, $4f, $ef, $ee, $32
    db $4f, $40, $5e, $62, $2e, $46, $4b, $44, $36, $49, $46, $4a, $42, $fa, $f7, $ef
    db $ee, $38, $4b, $46, $40, $4c, $4f, $4b, $62, $3e, $4b, $41, $ef, $ee, $30, $52
    db $41, $4f, $4c, $4b, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $42, $3e
    db $49, $38, $50, $24, $49, $49, $62, $46, $50, $62, $43, $4c, $4f, $ef, $ee, $2b
    db $42, $3e, $49, $42, $4f, $5e, $62, $2f, $46, $4c, $4b, $42, $55, $5e, $fa, $f7
    db $ef, $ee, $3e, $4b, $41, $62, $27, $42, $3e, $41, $31, $46, $51, $42, $63, $ef
    db $ee, $f7, $f0
TextStr_44_570b:           ; id $01BB
    ; "*:BigRoost is roasting big time!"
    db $ea, $9f, $a3, $25, $46, $44, $35, $4c, $4c, $50, $51, $62, $46, $50, $ef, $ee
    db $4f, $4c, $3e, $50, $51, $46, $4b, $44, $62, $3f, $46, $44, $62, $51, $46, $4a
    db $42, $63, $f7, $f0
TextStr_44_572f:           ; id $01BC
    ; "*:Hee hee! Dude! Wanna know who / you're gonna fight with in E / class? [YES/NO]"
    db $ea, $9f, $a3, $2b, $42, $42, $62, $45, $42, $42, $63, $62, $27, $52, $41, $42
    db $63, $ef, $ee, $3a, $3e, $4b, $4b, $3e, $62, $48, $4b, $4c, $54, $62, $54, $45
    db $4c, $fa, $f7, $ef, $ee, $56, $4c, $52, $69, $42, $62, $44, $4c, $4b, $4b, $3e
    db $ef, $ee, $43, $46, $44, $45, $51, $62, $54, $46, $51, $45, $62, $46, $4b, $62
    db $28, $fa, $f7, $ef, $ee, $40, $49, $3e, $50, $50, $64, $ef, $ee, $ff, $f0
TextStr_44_577e:           ; id $01BD
    ; "*:Teto in the waiting room will / fight you in the final match of E / class. / *:The guy has ArmorPede & two / Snailys. / *:A monster called..."
    db $ea, $9f, $a3, $37, $42, $51, $4c, $62, $46, $4b, $62, $51, $45, $42, $ef, $ee
    db $54, $3e, $46, $51, $46, $4b, $44, $62, $4f, $4c, $4c, $4a, $62, $54, $46, $49
    db $49, $fa, $f7, $ef, $ee, $43, $46, $44, $45, $51, $62, $56, $4c, $52, $62, $46
    db $4b, $62, $51, $45, $42, $ef, $ee, $43, $46, $4b, $3e, $49, $62, $4a, $3e, $51
    db $40, $45, $62, $4c, $43, $62, $28, $fa, $f7, $ef, $ee, $40, $49, $3e, $50, $50
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $44, $52, $56
    db $62, $45, $3e, $50, $ef, $ee, $24, $4f, $4a, $4c, $4f, $33, $42, $41, $42, $62
    db $b6, $62, $51, $54, $4c, $fa, $f7, $ef, $ee, $36, $4b, $3e, $46, $49, $56, $50
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $24, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $62, $40, $3e, $49, $49, $42, $41, $ef, $ee, $33, $4c, $46, $50, $4c
    db $4b, $44, $4c, $4b, $62, $54, $46, $49, $49, $fa, $f7, $ef, $ee, $50, $45, $4c
    db $54, $62, $52, $4d, $62, $3e, $51, $62, $51, $45, $42, $ef, $ee, $43, $46, $4f
    db $50, $51, $62, $4a, $3e, $51, $40, $45, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c
    db $51, $66, $49, $62, $44, $46, $53, $42, $ef, $ee, $33, $4c, $46, $50, $4c, $4b
    db $2b, $46, $51, $5f, $fa, $f7, $ef, $ee, $3c, $4c, $52, $66, $49, $62, $4b, $42
    db $42, $41, $ef, $ee, $24, $4b, $51, $46, $41, $4c, $51, $42, $62, $4c, $4f, $62
    db $56, $4c, $52, $66, $49, $fa, $f7, $ef, $ee, $45, $3e, $53, $42, $62, $3e, $62
    db $45, $3e, $4f, $41, $62, $51, $46, $4a, $42, $63, $ef, $ee, $f7, $f0
TextStr_44_589c:           ; id $01BE
    ; "*:Oh, long time no see! Remember me? / *:I am the old man who took you / to the castle when you first / came to GreatTree. / *:People call m..."
    db $ea, $9f, $a3, $32, $45, $5e, $62, $49, $4c, $4b, $44, $62, $51, $46, $4a, $42
    db $62, $4b, $4c, $ef, $ee, $50, $42, $42, $63, $62, $35, $42, $4a, $42, $4a, $3f
    db $42, $4f, $62, $4a, $42, $64, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $3e, $4a
    db $62, $51, $45, $42, $62, $4c, $49, $41, $ef, $ee, $4a, $3e, $4b, $62, $54, $45
    db $4c, $62, $51, $4c, $4c, $48, $62, $56, $4c, $52, $fa, $f7, $ef, $ee, $51, $4c
    db $62, $51, $45, $42, $62, $40, $3e, $50, $51, $49, $42, $ef, $ee, $54, $45, $42
    db $4b, $62, $56, $4c, $52, $62, $43, $46, $4f, $50, $51, $fa, $f7, $ef, $ee, $40
    db $3e, $4a, $42, $62, $51, $4c, $62, $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $33, $42, $4c, $4d, $49, $42, $62
    db $40, $3e, $49, $49, $62, $4a, $42, $ef, $ee, $30, $3e, $50, $51, $42, $4f, $62
    db $30, $4c, $4b, $50, $51, $42, $4f, $fa, $f7, $ef, $ee, $37, $3e, $4a, $42, $4f
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $46, $50, $62, $46, $50
    db $62, $51, $45, $42, $ef, $ee, $36, $45, $4f, $46, $4b, $42, $62, $4c, $43, $62
    db $36, $51, $3e, $4f, $4f, $56, $fa, $f7, $ef, $ee, $31, $46, $44, $45, $51, $5f
    db $62, $2c, $51, $62, $46, $50, $62, $51, $45, $42, $ef, $ee, $4d, $49, $3e, $40
    db $42, $62, $43, $4c, $4f, $62, $3f, $4f, $42, $42, $41, $46, $4b, $44, $fa, $f7
    db $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $3e, $4b, $41, $ef, $ee
    db $45, $3e, $51, $40, $45, $46, $4b, $44, $62, $42, $44, $44, $50, $5f, $fa, $f7
    db $ef, $ee, $9f, $a3, $25, $4f, $42, $42, $41, $46, $4b, $44, $62, $46, $50, $ef
    db $ee, $51, $45, $42, $62, $54, $42, $41, $41, $46, $4b, $44, $62, $4c, $43, $fa
    db $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $3a, $45, $42, $4b, $62, $51, $45, $42, $56, $62, $3e, $4f
    db $42, $ef, $ee, $54, $42, $41, $5e, $62, $3e, $4b, $62, $42, $44, $44, $fa, $f7
    db $ef, $ee, $46, $50, $62, $49, $3e, $46, $41, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $28, $44, $44, $50, $62, $45, $3e, $51, $40, $45, $62, $46, $4b, $51
    db $4c, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $3a, $45, $3e, $51, $62, $40, $3e, $4b, $62, $2c, $62, $41, $4c, $ef
    db $ee, $43, $4c, $4f, $62, $56, $4c, $52, $62, $51, $4c, $41, $3e, $56, $64, $f7
    db $f0
TextStr_44_5a5d:           ; id $01BF
    ; "*:Hey! Lemme tell ya. / when you breed... / *:first choose the monster family you / like to keep as the pedigree! / *:Pedigrees & families....."
    db $eb, $9f, $a3, $2b, $42, $56, $63, $62, $ef, $ee, $2f, $42, $4a, $4a, $42, $62
    db $51, $42, $49, $49, $62, $56, $3e, $5f, $62, $fa, $f7, $ef, $ee, $54, $45, $42
    db $4b, $62, $56, $4c, $52, $62, $3f, $4f, $42, $42, $41, $5f, $5f, $5f, $62, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $43, $46, $4f, $50, $51, $62, $40, $45, $4c
    db $4c, $50, $42, $62, $51, $45, $42, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f
    db $62, $43, $3e, $4a, $46, $49, $56, $62, $56, $4c, $52, $fa, $f7, $ef, $ee, $49
    db $46, $48, $42, $62, $51, $4c, $62, $48, $42, $42, $4d, $62, $3e, $50, $ef, $ee
    db $51, $45, $42, $62, $4d, $42, $41, $46, $44, $4f, $42, $42, $63, $fa, $f7, $ef
    db $ee, $9f, $a3, $33, $42, $41, $46, $44, $4f, $42, $42, $50, $62, $b6, $ef, $ee
    db $43, $3e, $4a, $46, $49, $46, $42, $50, $5f, $5f, $62, $2c, $51, $50, $62, $3e
    db $fa, $f7, $ef, $ee, $3f, $46, $51, $62, $45, $3e, $4f, $41, $62, $51, $4c, $ef
    db $ee, $52, $4b, $41, $42, $4f, $50, $51, $3e, $4b, $41, $5f, $5f, $5f, $fa, $f7
    db $ef, $ee, $9f, $a3, $36, $4c, $5e, $62, $46, $43, $62, $56, $4c, $52, $62, $54
    db $3e, $4b, $4b, $3e, $ef, $ee, $40, $4f, $42, $3e, $51, $42, $62, $3e, $62, $4a
    db $4c, $4b, $50, $51, $42, $4f, $fa, $f7, $ef, $ee, $43, $4f, $4c, $4a, $62, $51
    db $45, $42, $62, $36, $49, $46, $4a, $42, $ef, $ee, $43, $3e, $4a, $46, $49, $56
    db $62, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $43, $46, $4f, $50, $51, $62
    db $40, $45, $4c, $4c, $50, $42, $62, $3e, $ef, $ee, $4a, $4c, $4b, $50, $51, $42
    db $4f, $62, $43, $4f, $4c, $4a, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $36, $49
    db $46, $4a, $42, $62, $43, $3e, $4a, $46, $49, $56, $62, $43, $4c, $4f, $ef, $ee
    db $51, $45, $42, $62, $4d, $42, $41, $46, $44, $4f, $42, $42, $63, $fa, $f7, $ef
    db $ee, $9f, $a3, $2c, $43, $62, $56, $4c, $52, $62, $54, $3e, $4b, $4b, $3e, $ef
    db $ee, $40, $4f, $42, $3e, $51, $42, $62, $3e, $62, $4a, $4c, $4b, $50, $51, $42
    db $4f, $fa, $f7, $ef, $ee, $43, $4f, $4c, $4a, $62, $51, $45, $42, $62, $27, $4f
    db $3e, $44, $4c, $4b, $ef, $ee, $43, $3e, $4a, $46, $49, $56, $62, $5f, $5f, $5f
    db $fa, $f7, $ef, $ee, $9f, $a3, $43, $46, $4f, $50, $51, $62, $40, $45, $4c, $4c
    db $50, $42, $62, $3e, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $43, $4f
    db $4c, $4a, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $27, $4f, $3e, $44, $4c, $4b
    db $62, $43, $3e, $4a, $46, $49, $56, $62, $43, $4c, $4f, $ef, $ee, $51, $45, $42
    db $62, $4d, $42, $41, $46, $44, $4f, $42, $42, $63, $fa, $f7, $ef, $ee, $9f, $a3
    db $37, $45, $42, $62, $3f, $3e, $3f, $56, $62, $4a, $4c, $4b, $50, $51, $42, $4f
    db $ef, $ee, $54, $46, $49, $49, $62, $45, $3e, $53, $42, $62, $50, $46, $4a, $46
    db $49, $3e, $4f, $fa, $f7, $ef, $ee, $40, $45, $3e, $4f, $3e, $40, $51, $42, $4f
    db $46, $50, $51, $46, $40, $50, $ef, $ee, $3e, $50, $62, $51, $45, $42, $62, $4a
    db $4c, $4b, $50, $51, $42, $4f, $fa, $f7, $ef, $ee, $56, $4c, $52, $62, $40, $45
    db $4c, $50, $42, $62, $43, $4c, $4f, $ef, $ee, $51, $45, $42, $62, $4d, $42, $41
    db $46, $44, $4f, $42, $42, $5f, $f7, $f0
TextStr_44_5ca5:           ; id $01C0
    ; "*:After breeding, the parent / monsters will go back to the wild. / *:But the skills of the parents / will be passed on to the kids. / *:For..."
    db $eb, $9f, $a3, $24, $43, $51, $42, $4f, $62, $3f, $4f, $42, $42, $41, $46, $4b
    db $44, $5e, $ef, $ee, $51, $45, $42, $62, $4d, $3e, $4f, $42, $4b, $51, $fa, $f7
    db $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $54, $46, $49, $49, $62
    db $44, $4c, $ef, $ee, $3f, $3e, $40, $48, $62, $51, $4c, $62, $51, $45, $42, $62
    db $54, $46, $49, $41, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $25, $52, $51, $62, $51
    db $45, $42, $62, $50, $48, $46, $49, $49, $50, $ef, $ee, $4c, $43, $62, $51, $45
    db $42, $62, $4d, $3e, $4f, $42, $4b, $51, $50, $fa, $f7, $ef, $ee, $54, $46, $49
    db $49, $62, $3f, $42, $62, $4d, $3e, $50, $50, $42, $41, $ef, $ee, $4c, $4b, $62
    db $51, $4c, $62, $51, $45, $42, $62, $48, $46, $41, $50, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $29, $4c, $4f, $62, $3e, $4b, $62, $42, $55, $3e, $4a, $4d, $49, $42
    db $5e, $ef, $ee, $54, $45, $42, $4b, $62, $3e, $62, $27, $4f, $3e, $44, $4c, $4b
    db $62, $46, $50, $fa, $f7, $ef, $ee, $40, $45, $4c, $50, $42, $4b, $62, $3e, $50
    db $62, $51, $45, $42, $ef, $ee, $4d, $42, $41, $46, $44, $4f, $42, $42, $62, $3e
    db $4b, $41, $62, $3f, $4f, $42, $41, $fa, $f7, $ef, $ee, $54, $46, $51, $45, $62
    db $3e, $62, $2b, $42, $3e, $49, $42, $4f, $5e, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $3e, $62, $27, $4f, $3e, $44, $4c, $4b, $2e, $46, $41, $62, $51, $45, $3e
    db $51, $ef, $ee, $40, $3e, $4b, $62, $49, $42, $3e, $4f, $4b, $62, $2b, $42, $3e
    db $49, $42, $4f, $68, $fa, $f7, $ef, $ee, $50, $48, $46, $49, $49, $50, $62, $54
    db $46, $49, $49, $62, $3f, $42, $ef, $ee, $3f, $4c, $4f, $4b, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $35, $3e, $46, $50, $42, $62, $51, $45, $42, $ef, $ee, $27, $4f
    db $3e, $44, $4c, $4b, $2e, $46, $41, $62, $3e, $4b, $41, $fa, $f7, $ef, $ee, $3f
    db $4f, $42, $42, $41, $62, $46, $51, $62, $54, $46, $51, $45, $ef, $ee, $3e, $4b
    db $4c, $51, $45, $42, $4f, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $5f, $5f, $5f
    db $fa, $f7, $ef, $ee, $9f, $a3, $3e, $4b, $41, $62, $50, $4c, $62, $4c, $4b, $5f
    db $ef, $ee, $3c, $4c, $52, $62, $40, $3e, $4b, $62, $4a, $3e, $48, $42, $fa, $f7
    db $ef, $ee, $4a, $3e, $4b, $56, $62, $50, $51, $4f, $4c, $4b, $44, $ef, $ee, $4a
    db $4c, $4b, $50, $51, $42, $4f, $50, $62, $51, $45, $46, $50, $fa, $f7, $ef, $ee
    db $54, $3e, $56, $63, $ef, $ee, $f7, $f0
TextStr_44_5e5d:           ; id $01C1
    ; "[HERO] looked at the bookshelf. / :Everything you want to know about / breeding... by Master Monster / Tamer. / Want to read the book? [YES/..."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $3e, $51, $ef, $ee, $51, $45, $42
    db $62, $3f, $4c, $4c, $48, $50, $45, $42, $49, $43, $5f, $fa, $f7, $ef, $ee, $a3
    db $28, $53, $42, $4f, $56, $51, $45, $46, $4b, $44, $62, $56, $4c, $52, $ef, $ee
    db $54, $3e, $4b, $51, $62, $51, $4c, $62, $48, $4b, $4c, $54, $62, $3e, $3f, $4c
    db $52, $51, $fa, $f7, $ef, $ee, $3f, $4f, $42, $42, $41, $46, $4b, $44, $5f, $5f
    db $5f, $ef, $ee, $3f, $56, $62, $30, $3e, $50, $51, $42, $4f, $62, $30, $4c, $4b
    db $50, $51, $42, $4f, $fa, $f7, $ef, $ee, $37, $3e, $4a, $42, $4f, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $4f, $42, $3e, $41
    db $62, $51, $45, $42, $ef, $ee, $3f, $4c, $4c, $48, $64, $ff, $f0
TextStr_44_5eea:           ; id $01C2
    ; ":Breeding is to wed monsters. / :After breeding, the parent / monsters will go back to the wild. / :An egg capable of learning its / parents..."
    db $a3, $25, $4f, $42, $42, $41, $46, $4b, $44, $62, $46, $50, $62, $51, $4c, $ef
    db $ee, $54, $42, $41, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f, $fa, $f7
    db $ef, $ee, $a3, $24, $43, $51, $42, $4f, $62, $3f, $4f, $42, $42, $41, $46, $4b
    db $44, $5e, $ef, $ee, $51, $45, $42, $62, $4d, $3e, $4f, $42, $4b, $51, $fa, $f7
    db $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $54, $46, $49, $49, $62
    db $44, $4c, $ef, $ee, $3f, $3e, $40, $48, $62, $51, $4c, $62, $51, $45, $42, $62
    db $54, $46, $49, $41, $5f, $fa, $f7, $ef, $ee, $a3, $24, $4b, $62, $42, $44, $44
    db $62, $40, $3e, $4d, $3e, $3f, $49, $42, $62, $4c, $43, $ef, $ee, $49, $42, $3e
    db $4f, $4b, $46, $4b, $44, $62, $46, $51, $50, $fa, $f7, $ef, $ee, $4d, $3e, $4f
    db $42, $4b, $51, $50, $5c, $62, $50, $48, $46, $49, $49, $50, $ef, $ee, $54, $45
    db $42, $4b, $62, $45, $3e, $51, $40, $45, $42, $41, $62, $54, $46, $49, $49, $fa
    db $f7, $ef, $ee, $3f, $42, $62, $49, $3e, $46, $41, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $a3, $37, $45, $42, $62, $47, $4c, $52, $4f, $4b, $3e, $49, $ef, $ee, $54
    db $46, $49, $49, $62, $4f, $42, $40, $4c, $4f, $41, $62, $51, $45, $42, $fa, $f7
    db $ef, $ee, $4f, $42, $50, $52, $49, $51, $50, $62, $4c, $43, $62, $51, $45, $46
    db $50, $ef, $ee, $3f, $4f, $42, $42, $41, $46, $4b, $44, $5f, $fa, $f7, $ef, $ee
    db $a3, $3c, $4c, $52, $62, $40, $3e, $4b, $62, $4b, $4c, $51, $ef, $ee, $52, $4b
    db $41, $4c, $62, $3f, $4f, $42, $42, $41, $46, $4b, $44, $5f, $fa, $f7, $ef, $ee
    db $36, $4c, $62, $3f, $42, $62, $40, $3e, $4f, $42, $43, $52, $49, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $a3, $37, $52, $4f, $4b, $62, $56, $4c, $52, $4f, $62, $42
    db $44, $44, $50, $ef, $ee, $46, $4b, $51, $4c, $62, $4a, $4c, $4b, $50, $51, $42
    db $4f, $50, $62, $3f, $56, $fa, $f7, $ef, $ee, $45, $3e, $51, $40, $45, $46, $4b
    db $44, $62, $51, $45, $42, $4a, $5f, $ef, $ee, $f7, $f0
TextStr_44_6055:           ; id $01C3
    ; "[HERO] looked at the bookshelf. / :Saying of the day. / :The higher the levels of the / parents, the higher the / abilities of the child! / ..."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $3e, $51, $ef, $ee, $51, $45, $42
    db $62, $3f, $4c, $4c, $48, $50, $45, $42, $49, $43, $5f, $fa, $f7, $ef, $ee, $a3
    db $36, $3e, $56, $46, $4b, $44, $62, $4c, $43, $62, $51, $45, $42, $ef, $ee, $41
    db $3e, $56, $5f, $fa, $f7, $ef, $ee, $a3, $37, $45, $42, $62, $45, $46, $44, $45
    db $42, $4f, $62, $51, $45, $42, $ef, $ee, $49, $42, $53, $42, $49, $50, $62, $4c
    db $43, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $4d, $3e, $4f, $42, $4b, $51, $50
    db $5e, $62, $51, $45, $42, $ef, $ee, $45, $46, $44, $45, $42, $4f, $62, $51, $45
    db $42, $62, $fa, $f7, $ef, $ee, $3e, $3f, $46, $49, $46, $51, $46, $42, $50, $62
    db $4c, $43, $62, $51, $45, $42, $ef, $ee, $40, $45, $46, $49, $41, $63, $fa, $f7
    db $ef, $ee, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $4f, $42, $3e, $41, $62, $4a
    db $4c, $4f, $42, $64, $ef, $ee, $ff, $f0
TextStr_44_60fd:           ; id $01C4
    ; ":Monster Journal by Master Monster / Tamer / :[HERO] is a promising kid. / :I heard he saved Pulio from being / thrown in the dungeon! / :Wa..."
    db $a3, $30, $4c, $4b, $50, $51, $42, $4f, $62, $2d, $4c, $52, $4f, $4b, $3e, $49
    db $ef, $ee, $3f, $56, $62, $30, $3e, $50, $51, $42, $4f, $62, $30, $4c, $4b, $50
    db $51, $42, $4f, $fa, $f7, $ef, $ee, $37, $3e, $4a, $42, $4f, $ef, $ee, $fa, $f7
    db $ef, $ee, $a3, $f6, $62, $46, $50, $62, $3e, $ef, $ee, $4d, $4f, $4c, $4a, $46
    db $50, $46, $4b, $44, $62, $48, $46, $41, $5f, $fa, $f7, $ef, $ee, $a3, $2c, $62
    db $45, $42, $3e, $4f, $41, $62, $45, $42, $62, $50, $3e, $53, $42, $41, $ef, $ee
    db $33, $52, $49, $46, $4c, $62, $43, $4f, $4c, $4a, $62, $3f, $42, $46, $4b, $44
    db $fa, $f7, $ef, $ee, $51, $45, $4f, $4c, $54, $4b, $62, $46, $4b, $62, $51, $45
    db $42, $ef, $ee, $41, $52, $4b, $44, $42, $4c, $4b, $63, $fa, $f7, $ef, $ee, $a3
    db $3a, $3e, $51, $3e, $3f, $4c, $52, $62, $50, $52, $4f, $42, $ef, $ee, $41, $4c
    db $42, $50, $62, $45, $3e, $53, $42, $62, $44, $4c, $4c, $41, $fa, $f7, $ef, $ee
    db $42, $56, $42, $50, $62, $54, $45, $42, $4b, $62, $40, $45, $4c, $4c, $50, $46
    db $4b, $44, $ef, $ee, $3e, $62, $4b, $42, $54, $62, $4a, $3e, $50, $51, $42, $4f
    db $63, $f7, $f0
TextStr_44_61d0:           ; id $01C5
    ; "*:Master Monster Tamer is in the / back. / *:You can go up to the top by / climbing the ivy!"
    db $eb, $9f, $a3, $30, $3e, $50, $51, $42, $4f, $62, $30, $4c, $4b, $50, $51, $42
    db $4f, $ef, $ee, $37, $3e, $4a, $42, $4f, $62, $46, $50, $62, $46, $4b, $62, $51
    db $45, $42, $fa, $f7, $ef, $ee, $3f, $3e, $40, $48, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $3c, $4c, $52, $62, $40, $3e, $4b, $62, $44, $4c, $ef, $ee, $52
    db $4d, $62, $51, $4c, $62, $51, $45, $42, $62, $51, $4c, $4d, $62, $3f, $56, $fa
    db $f7, $ef, $ee, $40, $49, $46, $4a, $3f, $46, $4b, $44, $62, $51, $45, $42, $62
    db $46, $53, $56, $63, $ef, $ee, $f7, $f0
TextStr_44_6238:           ; id $01C6
    ; "*:The level of a newborn monster / is always 1. / *:You'll be in trouble if all the / monsters with you are level 1. / *:It'll be less risky..."
    db $ea, $9f, $a3, $37, $45, $42, $62, $49, $42, $53, $42, $49, $62, $4c, $43, $62
    db $3e, $ef, $ee, $4b, $42, $54, $3f, $4c, $4f, $4b, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $fa, $f7, $ef, $ee, $46, $50, $62, $3e, $49, $54, $3e, $56, $50, $62
    db $01, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $66, $49, $62
    db $3f, $42, $62, $46, $4b, $ef, $ee, $51, $4f, $4c, $52, $3f, $49, $42, $62, $46
    db $43, $62, $3e, $49, $49, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $4a, $4c, $4b
    db $50, $51, $42, $4f, $50, $62, $54, $46, $51, $45, $62, $56, $4c, $52, $ef, $ee
    db $3e, $4f, $42, $62, $49, $42, $53, $42, $49, $62, $01, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $2c, $51, $66, $49, $62, $3f, $42, $62, $49, $42, $50, $50, $ef, $ee
    db $4f, $46, $50, $48, $56, $62, $46, $43, $62, $56, $4c, $52, $62, $3f, $4f, $42
    db $42, $41, $fa, $f7, $ef, $ee, $4c, $4b, $42, $62, $4d, $3e, $46, $4f, $62, $3e
    db $51, $62, $3e, $ef, $ee, $51, $46, $4a, $42, $5f, $f7, $f0
TextStr_44_62f4:           ; id $01C7
    ; "*:The secret of breeding is to / collect males and females / carefully. / *:Sometimes, you might be / disappointed by not having the / right..."
    db $ea, $9f, $a3, $37, $45, $42, $62, $50, $42, $40, $4f, $42, $51, $62, $4c, $43
    db $ef, $ee, $3f, $4f, $42, $42, $41, $46, $4b, $44, $62, $46, $50, $62, $51, $4c
    db $fa, $f7, $ef, $ee, $40, $4c, $49, $49, $42, $40, $51, $62, $4a, $3e, $49, $42
    db $50, $ef, $ee, $3e, $4b, $41, $62, $43, $42, $4a, $3e, $49, $42, $50, $fa, $f7
    db $ef, $ee, $40, $3e, $4f, $42, $43, $52, $49, $49, $56, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $36, $4c, $4a, $42, $51, $46, $4a, $42, $50, $5e, $62, $56
    db $4c, $52, $ef, $ee, $4a, $46, $44, $45, $51, $62, $3f, $42, $fa, $f7, $ef, $ee
    db $41, $46, $50, $3e, $4d, $4d, $4c, $46, $4b, $51, $42, $41, $62, $3f, $56, $ef
    db $ee, $4b, $4c, $51, $62, $45, $3e, $53, $46, $4b, $44, $62, $51, $45, $42, $fa
    db $f7, $ef, $ee, $4f, $46, $44, $45, $51, $62, $44, $42, $4b, $41, $42, $4f, $5f
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25, $52, $51, $62, $51, $45, $42, $4f
    db $42, $62, $46, $50, $ef, $ee, $3e, $4b, $62, $42, $44, $44, $62, $40, $4c, $4b
    db $50, $52, $49, $51, $3e, $4b, $51, $fa, $f7, $ef, $ee, $50, $4c, $4a, $42, $54
    db $45, $42, $4f, $42, $62, $46, $4b, $62, $51, $45, $46, $50, $ef, $ee, $48, $46
    db $4b, $44, $41, $4c, $4a, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $36, $45, $42, $62
    db $40, $3e, $4b, $62, $3f, $49, $42, $50, $50, $ef, $ee, $51, $45, $42, $62, $42
    db $44, $44, $62, $51, $4c, $62, $40, $45, $3e, $4b, $44, $42, $fa, $f7, $ef, $ee
    db $46, $51, $68, $62, $44, $42, $4b, $41, $42, $4f, $63, $ef, $ee, $f7, $f0
TextStr_44_6413:           ; id $01C8
    ; "*:Oh! What a cute monster master / you are! / *:What's your name? / [HERO]... / So you're little [HERO]. / *:I am an egg consultant. / Nice ..."
    db $eb, $9f, $a3, $32, $45, $63, $62, $3a, $45, $3e, $51, $62, $3e, $62, $40, $52
    db $51, $42, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $4a, $3e, $50, $51
    db $42, $4f, $fa, $f7, $ef, $ee, $56, $4c, $52, $62, $3e, $4f, $42, $63, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45, $3e, $51, $68, $62, $56, $4c, $52, $4f
    db $ef, $ee, $4b, $3e, $4a, $42, $64, $fa, $f7, $ef, $ee, $f6, $5f, $5f, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $36, $4c, $62, $56, $4c, $52, $69, $42, $62, $49, $46
    db $51, $51, $49, $42, $ef, $ee, $f6, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62
    db $3e, $4a, $62, $3e, $4b, $62, $42, $44, $44, $ef, $ee, $40, $4c, $4b, $50, $52
    db $49, $51, $3e, $4b, $51, $5f, $fa, $f7, $ef, $ee, $31, $46, $40, $42, $62, $51
    db $4c, $62, $4a, $42, $42, $51, $62, $56, $4c, $52, $63, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $2c, $66, $49, $62, $65, $42, $53, $3e, $49, $52, $3e, $51, $42
    db $65, $ef, $ee, $56, $4c, $52, $4f, $62, $42, $44, $44, $62, $3e, $51, $62, $4a
    db $56, $fa, $f7, $ef, $ee, $4d, $49, $3e, $40, $42, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $24, $4b, $41, $62, $2c, $62, $40, $3e, $4b, $62, $43, $46, $4b
    db $41, $ef, $ee, $4c, $52, $51, $62, $43, $4c, $4f, $62, $56, $4c, $52, $62, $54
    db $45, $3e, $51, $fa, $f7, $ef, $ee, $48, $46, $4b, $41, $62, $4c, $43, $62, $3f
    db $3e, $3f, $56, $62, $46, $50, $62, $46, $4b, $ef, $ee, $56, $4c, $52, $4f, $62
    db $42, $44, $44, $50, $63, $fa, $f7, $ef, $ee, $9f, $a3, $30, $56, $62, $4c, $51
    db $45, $42, $4f, $62, $47, $4c, $3f, $ef, $ee, $46, $50, $62, $65, $3f, $49, $42
    db $50, $50, $46, $4b, $44, $65, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $25, $49, $42
    db $50, $50, $46, $4b, $44, $62, $40, $45, $3e, $4b, $44, $42, $50, $ef, $ee, $51
    db $45, $42, $62, $44, $42, $4b, $41, $42, $4f, $62, $4c, $43, $fa, $f7, $ef, $ee
    db $4a, $4c, $4b, $50, $51, $42, $4f, $50, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $2a, $4c, $51, $62, $46, $51, $64, $62, $2b, $4c, $54, $62, $40, $3e, $4b
    db $ef, $ee, $2c, $62, $45, $42, $49, $4d, $62, $56, $4c, $52, $64, $f7, $f0
TextStr_44_65a2:           ; id $01C9
    ; "[HERO] looked at the bookshelf. / :Gender of Monsters / :There are families that / will have only boy babies / :and others only girl babies!..."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $3e, $51, $ef, $ee, $51, $45, $42
    db $62, $3f, $4c, $4c, $48, $50, $45, $42, $49, $43, $5f, $fa, $f7, $ef, $ee, $a3
    db $2a, $42, $4b, $41, $42, $4f, $62, $4c, $43, $ef, $ee, $30, $4c, $4b, $50, $51
    db $42, $4f, $50, $fa, $f7, $ef, $ee, $a3, $37, $45, $42, $4f, $42, $62, $3e, $4f
    db $42, $ef, $ee, $43, $3e, $4a, $46, $49, $46, $42, $50, $62, $51, $45, $3e, $51
    db $fa, $f7, $ef, $ee, $54, $46, $49, $49, $62, $45, $3e, $53, $42, $62, $4c, $4b
    db $49, $56, $ef, $ee, $3f, $4c, $56, $62, $3f, $3e, $3f, $46, $42, $50, $fa, $f7
    db $ef, $ee, $a3, $3e, $4b, $41, $62, $4c, $51, $45, $42, $4f, $50, $62, $4c, $4b
    db $49, $56, $ef, $ee, $44, $46, $4f, $49, $62, $3f, $3e, $3f, $46, $42, $50, $63
    db $fa, $f7, $ef, $ee, $a3, $36, $42, $42, $5e, $62, $3f, $49, $42, $50, $50, $46
    db $4b, $44, $ef, $ee, $2c, $50, $62, $46, $4a, $4d, $4c, $4f, $51, $3e, $4b, $51
    db $63, $f7, $f0
TextStr_44_6655:           ; id $01CA
    ; "[HERO] looked at the bookshelf. / :The limit of monster levels. / :Different species have different / limits of monster levels. / :But you c..."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $3e, $51, $ef, $ee, $51, $45, $42
    db $62, $3f, $4c, $4c, $48, $50, $45, $42, $49, $43, $5f, $fa, $f7, $ef, $ee, $a3
    db $37, $45, $42, $62, $49, $46, $4a, $46, $51, $62, $4c, $43, $ef, $ee, $4a, $4c
    db $4b, $50, $51, $42, $4f, $62, $49, $42, $53, $42, $49, $50, $5f, $fa, $f7, $ef
    db $ee, $a3, $27, $46, $43, $43, $42, $4f, $42, $4b, $51, $62, $50, $4d, $42, $40
    db $46, $42, $50, $ef, $ee, $45, $3e, $53, $42, $62, $41, $46, $43, $43, $42, $4f
    db $42, $4b, $51, $fa, $f7, $ef, $ee, $49, $46, $4a, $46, $51, $50, $62, $4c, $43
    db $62, $4a, $4c, $4b, $50, $51, $42, $4f, $ef, $ee, $49, $42, $53, $42, $49, $50
    db $5f, $fa, $f7, $ef, $ee, $a3, $25, $52, $51, $62, $56, $4c, $52, $62, $40, $3e
    db $4b, $62, $50, $49, $4c, $54, $ef, $ee, $51, $45, $42, $62, $50, $4d, $42, $42
    db $41, $62, $3e, $51, $62, $54, $45, $46, $40, $45, $fa, $f7, $ef, $ee, $51, $45
    db $42, $62, $49, $46, $4a, $46, $51, $62, $46, $50, $ef, $ee, $4f, $42, $3e, $40
    db $45, $42, $41, $5f, $fa, $f7, $ef, $ee, $a3, $37, $45, $42, $62, $4a, $4c, $4f
    db $42, $62, $56, $4c, $52, $ef, $ee, $3f, $4f, $42, $42, $41, $62, $4a, $4c, $4b
    db $50, $51, $42, $4f, $50, $5e, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $50, $49
    db $4c, $54, $42, $4f, $62, $51, $45, $42, $56, $ef, $ee, $4f, $42, $3e, $40, $45
    db $62, $51, $45, $42, $62, $49, $46, $4a, $46, $51, $63, $f7, $f0
TextStr_44_6762:           ; id $01CB
    ; "[HERO] looked at the bookshelf. / :Skills of Monsters / :Kids receive the skills of their / parents! / :The secret of breeding is... / :to p..."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $3e, $51, $ef, $ee, $51, $45, $42
    db $62, $3f, $4c, $4c, $48, $50, $45, $42, $49, $43, $5f, $fa, $f7, $ef, $ee, $a3
    db $36, $48, $46, $49, $49, $50, $62, $4c, $43, $ef, $ee, $30, $4c, $4b, $50, $51
    db $42, $4f, $50, $fa, $f7, $ef, $ee, $a3, $2e, $46, $41, $50, $62, $4f, $42, $40
    db $42, $46, $53, $42, $62, $51, $45, $42, $ef, $ee, $50, $48, $46, $49, $49, $50
    db $62, $4c, $43, $62, $51, $45, $42, $46, $4f, $fa, $f7, $ef, $ee, $4d, $3e, $4f
    db $42, $4b, $51, $50, $63, $ef, $ee, $fa, $f7, $ef, $ee, $a3, $37, $45, $42, $62
    db $50, $42, $40, $4f, $42, $51, $62, $4c, $43, $ef, $ee, $3f, $4f, $42, $42, $41
    db $46, $4b, $44, $62, $46, $50, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $a3, $51, $4c
    db $62, $4d, $46, $40, $48, $62, $4d, $3e, $4f, $42, $4b, $51, $50, $ef, $ee, $54
    db $46, $51, $45, $62, $51, $45, $42, $62, $50, $48, $46, $49, $49, $50, $fa, $f7
    db $ef, $ee, $56, $4c, $52, $62, $54, $3e, $4b, $51, $62, $3e, $4b, $41, $5f, $5f
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $a3, $4d, $46, $40, $48, $62, $51, $45, $42
    db $62, $50, $51, $4f, $4c, $4b, $44, $42, $4f, $ef, $ee, $4c, $4b, $42, $62, $43
    db $4c, $4f, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $4d, $42, $41, $46, $44, $4f
    db $42, $42, $5f, $ef, $ee, $f7, $f0
TextStr_44_6859:           ; id $01CC
    ; "*:You, do you know my daughter? [YES/NO]"
    db $ea, $9f, $a3, $3c, $4c, $52, $5e, $62, $41, $4c, $62, $56, $4c, $52, $62, $48
    db $4b, $4c, $54, $ef, $ee, $4a, $56, $62, $41, $3e, $52, $44, $45, $51, $42, $4f
    db $64, $ff, $f0
TextStr_44_687c:           ; id $01CD
    ; "*:You don't!? Such a pretty, / gentle & graceful girl!? / *:She must be playing outside. / You should go see her."
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $41, $4c, $4b, $67, $63, $64, $ef, $ee, $36
    db $52, $40, $45, $62, $3e, $62, $4d, $4f, $42, $51, $51, $56, $5e, $fa, $f7, $ef
    db $ee, $44, $42, $4b, $51, $49, $42, $62, $b6, $62, $44, $4f, $3e, $40, $42, $43
    db $52, $49, $ef, $ee, $44, $46, $4f, $49, $63, $64, $fa, $f7, $ef, $ee, $9f, $a3
    db $36, $45, $42, $62, $4a, $52, $50, $51, $62, $3f, $42, $ef, $ee, $4d, $49, $3e
    db $56, $46, $4b, $44, $62, $4c, $52, $51, $50, $46, $41, $42, $5f, $fa, $f7, $ef
    db $ee, $3c, $4c, $52, $62, $50, $45, $4c, $52, $49, $41, $62, $44, $4c, $ef, $ee
    db $50, $42, $42, $62, $45, $42, $4f, $5f, $f7, $f0
TextStr_44_68f6:           ; id $01CE
    ; "*:See, isn't she the prettiest girl / in GreatTree?"
    db $ea, $9f, $a3, $36, $42, $42, $5e, $62, $46, $50, $4b, $67, $62, $50, $45, $42
    db $ef, $ee, $51, $45, $42, $62, $4d, $4f, $42, $51, $51, $46, $42, $50, $51, $62
    db $44, $46, $4f, $49, $fa, $f7, $ef, $ee, $46, $4b, $62, $2a, $4f, $42, $3e, $51
    db $37, $4f, $42, $42, $64, $ef, $ee, $f7, $f0
TextStr_44_692f:           ; id $01CF
    ; "*:What does the person living / next to you do? / *:A man or a woman Or...?"
    db $eb, $9f, $a3, $3a, $45, $3e, $51, $62, $41, $4c, $42, $50, $62, $51, $45, $42
    db $ef, $ee, $4d, $42, $4f, $50, $4c, $4b, $62, $49, $46, $53, $46, $4b, $44, $fa
    db $f7, $ef, $ee, $4b, $42, $55, $51, $62, $51, $4c, $62, $56, $4c, $52, $62, $41
    db $4c, $64, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $24, $62, $4a, $3e, $4b, $62
    db $4c, $4f, $62, $3e, $62, $54, $4c, $4a, $3e, $4b, $ef, $ee, $32, $4f, $5f, $5f
    db $5f, $64, $f7, $f0
TextStr_44_6983:           ; id $01D0
    ; "*:I am never going to let anyone / through my Travelers' Gate! / *:I'll show you stubbornness!"
    db $ea, $9f, $a3, $2c, $62, $3e, $4a, $62, $4b, $42, $53, $42, $4f, $62, $44, $4c
    db $46, $4b, $44, $ef, $ee, $51, $4c, $62, $49, $42, $51, $62, $3e, $4b, $56, $4c
    db $4b, $42, $fa, $f7, $ef, $ee, $51, $45, $4f, $4c, $52, $44, $45, $62, $4a, $56
    db $ef, $ee, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $62, $2a, $3e, $51
    db $42, $63, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $66, $49, $62, $50, $45, $4c, $54
    db $62, $56, $4c, $52, $ef, $ee, $50, $51, $52, $3f, $3f, $4c, $4f, $4b, $4b, $42
    db $50, $50, $63, $f7, $f0
TextStr_44_69e8:           ; id $01D1
    ; "[SOUND 60][HERO] looked inside the / dresser."
    db $e9, $60, $f6, $62, $49, $4c, $4c, $48, $42, $41, $ef, $ee, $46, $4b, $50, $46
    db $41, $42, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $41, $4f, $42, $50, $50, $42
    db $4f, $5f, $ef, $ee, $fa, $f7, $f0
TextStr_44_6a0f:           ; id $01D2
    ; "Wow! A TinyMedal! But cannot carry / any more! / [HERO] returned the TinyMedal to / the dresser."
    db $3a, $4c, $54, $63, $62, $24, $62, $37, $46, $4b, $56, $30, $42, $41, $3e, $49
    db $63, $ef, $ee, $25, $52, $51, $62, $40, $3e, $4b, $4b, $4c, $51, $62, $40, $3e
    db $4f, $4f, $56, $fa, $f7, $ef, $ee, $3e, $4b, $56, $62, $4a, $4c, $4f, $42, $63
    db $ef, $ee, $fa, $f7, $ef, $ee, $f6, $62, $4f, $42, $51, $52, $4f, $4b, $42, $41
    db $ef, $ee, $51, $45, $42, $62, $37, $46, $4b, $56, $30, $42, $41, $3e, $49, $62
    db $51, $4c, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $41, $4f, $42, $50, $50, $42
    db $4f, $5f, $ef, $ee, $f7, $f0
TextStr_44_6a75:           ; id $01D3
    ; "The dresser is filled with girl's / dresses."
    db $37, $45, $42, $62, $41, $4f, $42, $50, $50, $42, $4f, $62, $46, $50, $ef, $ee
    db $43, $46, $49, $49, $42, $41, $62, $54, $46, $51, $45, $62, $44, $46, $4f, $49
    db $68, $fa, $f7, $ef, $ee, $41, $4f, $42, $50, $50, $42, $50, $5f, $ef, $ee, $f7
    db $f0
TextStr_44_6aa6:           ; id $01D4
    ; "[HERO] looked at the bookshelf. / :Journal of My Baby, Part 1 / :My baby girl was born. / :She's so pretty, like her parents! / To be contin..."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $3e, $51, $ef, $ee, $51, $45, $42
    db $62, $3f, $4c, $4c, $48, $50, $45, $42, $49, $43, $5f, $fa, $f7, $ef, $ee, $a3
    db $2d, $4c, $52, $4f, $4b, $3e, $49, $62, $4c, $43, $62, $30, $56, $ef, $ee, $25
    db $3e, $3f, $56, $5e, $62, $33, $3e, $4f, $51, $62, $01, $fa, $f7, $ef, $ee, $a3
    db $30, $56, $62, $3f, $3e, $3f, $56, $62, $44, $46, $4f, $49, $ef, $ee, $54, $3e
    db $50, $62, $3f, $4c, $4f, $4b, $5f, $fa, $f7, $ef, $ee, $a3, $36, $45, $42, $68
    db $62, $50, $4c, $62, $4d, $4f, $42, $51, $51, $56, $5e, $ef, $ee, $49, $46, $48
    db $42, $62, $45, $42, $4f, $62, $4d, $3e, $4f, $42, $4b, $51, $50, $63, $fa, $f7
    db $ef, $ee, $37, $4c, $62, $3f, $42, $62, $40, $4c, $4b, $51, $46, $4b, $52, $42
    db $41, $5f, $ef, $ee, $f7, $f0
TextStr_44_6b3c:           ; id $01D5
    ; "[HERO] looked into the jar. / Someone is looking back at you! / But it's a reflection of / [HERO] on the water..."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $46, $4b, $51, $4c, $ef, $ee, $51
    db $45, $42, $62, $47, $3e, $4f, $5f, $fa, $f7, $ef, $ee, $36, $4c, $4a, $42, $4c
    db $4b, $42, $62, $46, $50, $62, $49, $4c, $4c, $48, $46, $4b, $44, $ef, $ee, $3f
    db $3e, $40, $48, $62, $3e, $51, $62, $56, $4c, $52, $63, $fa, $f7, $ef, $ee, $25
    db $52, $51, $62, $46, $51, $68, $62, $3e, $ef, $ee, $4f, $42, $43, $49, $42, $40
    db $51, $46, $4c, $4b, $62, $4c, $43, $fa, $f7, $ef, $ee, $f6, $62, $4c, $4b, $62
    db $51, $45, $42, $ef, $ee, $54, $3e, $51, $42, $4f, $5f, $5f, $5f, $f7, $f0
TextStr_44_6bab:           ; id $01D6
    ; "*:Get out! I'm not gonna give my / Betty to anybody! / *:Oh my Betty!"
    db $ea, $9f, $a3, $2a, $42, $51, $62, $4c, $52, $51, $63, $62, $2c, $6a, $62, $4b
    db $4c, $51, $ef, $ee, $44, $4c, $4b, $4b, $3e, $62, $44, $46, $53, $42, $62, $4a
    db $56, $fa, $f7, $ef, $ee, $25, $42, $51, $51, $56, $62, $51, $4c, $62, $3e, $4b
    db $56, $3f, $4c, $41, $56, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $32, $45
    db $62, $4a, $56, $62, $25, $42, $51, $51, $56, $63, $ef, $ee, $f7, $f0
TextStr_44_6bf9:           ; id $01D7
    ; "*:Oh,it was you. Appearances can be / misleading... You were strong! / *:By the way, I'm doing a research / on monsters. / *:I'm also doing ..."
    db $ea, $9f, $a3, $32, $45, $5e, $46, $51, $62, $54, $3e, $50, $62, $56, $4c, $52
    db $5f, $ef, $ee, $24, $4d, $4d, $42, $3e, $4f, $3e, $4b, $40, $42, $50, $62, $40
    db $3e, $4b, $62, $3f, $42, $fa, $f7, $ef, $ee, $4a, $46, $50, $49, $42, $3e, $41
    db $46, $4b, $44, $5f, $5f, $5f, $ef, $ee, $3c, $4c, $52, $62, $54, $42, $4f, $42
    db $62, $50, $51, $4f, $4c, $4b, $44, $63, $fa, $f7, $ef, $ee, $9f, $a3, $25, $56
    db $62, $51, $45, $42, $62, $54, $3e, $56, $5e, $62, $2c, $6a, $ef, $ee, $41, $4c
    db $46, $4b, $44, $62, $3e, $62, $4f, $42, $50, $42, $3e, $4f, $40, $45, $fa, $f7
    db $ef, $ee, $4c, $4b, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $2c, $6a, $62, $3e, $49, $50, $4c, $62, $41, $4c
    db $46, $4b, $44, $62, $3e, $ef, $ee, $4f, $42, $50, $42, $3e, $4f, $40, $45, $62
    db $4c, $4b, $fa, $f7, $ef, $ee, $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $5f
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $40, $3e, $4b, $62, $51, $42
    db $49, $49, $62, $56, $4c, $52, $ef, $ee, $46, $4b, $51, $42, $4f, $42, $50, $51
    db $46, $4b, $44, $fa, $f7, $ef, $ee, $50, $51, $4c, $4f, $46, $42, $50, $5f, $62
    db $26, $4c, $4a, $42, $ef, $ee, $53, $46, $50, $46, $51, $62, $4a, $42, $62, $3e
    db $44, $3e, $46, $4b, $5f, $f7, $f0
TextStr_44_6cf0:           ; id $01D8
    ; "*:My professor is a genius and / handsome. / *:If you want to listen to his / lecture, stop by again!"
    db $eb, $9f, $a3, $30, $56, $62, $4d, $4f, $4c, $43, $42, $50, $50, $4c, $4f, $62
    db $46, $50, $ef, $ee, $3e, $62, $44, $42, $4b, $46, $52, $50, $62, $3e, $4b, $41
    db $fa, $f7, $ef, $ee, $45, $3e, $4b, $41, $50, $4c, $4a, $42, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $2c, $43, $62, $56, $4c, $52, $62, $54, $3e, $4b, $51
    db $62, $51, $4c, $ef, $ee, $49, $46, $50, $51, $42, $4b, $62, $51, $4c, $62, $45
    db $46, $50, $fa, $f7, $ef, $ee, $49, $42, $40, $51, $52, $4f, $42, $5e, $ef, $ee
    db $50, $51, $4c, $4d, $62, $3f, $56, $62, $3e, $44, $3e, $46, $4b, $63, $f7, $f0
TextStr_44_6d60:           ; id $01D9
    ; "*:Welcome to the Master School! / *:Today's lecture is about the / characteristics of monsters. / Want to listen? [YES/NO]"
    db $ea, $9f, $a3, $3a, $42, $49, $40, $4c, $4a, $42, $62, $51, $4c, $62, $51, $45
    db $42, $ef, $ee, $30, $3e, $50, $51, $42, $4f, $62, $36, $40, $45, $4c, $4c, $49
    db $63, $fa, $f7, $ef, $ee, $9f, $a3, $37, $4c, $41, $3e, $56, $68, $62, $49, $42
    db $40, $51, $52, $4f, $42, $ef, $ee, $46, $50, $62, $3e, $3f, $4c, $52, $51, $62
    db $51, $45, $42, $fa, $f7, $ef, $ee, $40, $45, $3e, $4f, $3e, $40, $51, $42, $4f
    db $46, $50, $51, $46, $40, $50, $62, $4c, $43, $ef, $ee, $4a, $4c, $4b, $50, $51
    db $42, $4f, $50, $5f, $fa, $f7, $ef, $ee, $3a, $3e, $4b, $51, $62, $51, $4c, $62
    db $49, $46, $50, $51, $42, $4b, $64, $ef, $ee, $ff, $f0
TextStr_44_6ddb:           ; id $01DA
    ; "*:I took notes about how to catch / monsters. You want them? [YES/NO]"
    db $eb, $9f, $a3, $2c, $62, $51, $4c, $4c, $48, $62, $4b, $4c, $51, $42, $50, $ef
    db $ee, $3e, $3f, $4c, $52, $51, $62, $45, $4c, $54, $62, $51, $4c, $62, $40, $3e
    db $51, $40, $45, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f
    db $62, $3c, $4c, $52, $62, $54, $3e, $4b, $51, $ef, $ee, $51, $45, $42, $4a, $64
    db $ff, $f0
TextStr_44_6e1d:           ; id $01DB
    ; "*:Let me know if you do!"
    db $eb, $9f, $a3, $2f, $42, $51, $62, $4a, $42, $62, $48, $4b, $4c, $54, $ef, $ee
    db $46, $43, $62, $56, $4c, $52, $62, $41, $4c, $63, $f7, $f0
TextStr_44_6e39:           ; id $01DC
    ; "[HERO] opens the notebook. / :Giving monsters meat treats makes / them easier to tame. / :The more expensive the / treat, the better it work..."
    db $f6, $62, $4c, $4d, $42, $4b, $50, $62, $51, $45, $42, $ef, $ee, $4b, $4c, $51
    db $42, $3f, $4c, $4c, $48, $5f, $fa, $f7, $ef, $ee, $a3, $2a, $46, $53, $46, $4b
    db $44, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $ef, $ee, $4a, $42, $3e, $51
    db $62, $51, $4f, $42, $3e, $51, $50, $62, $4a, $3e, $48, $42, $50, $fa, $f7, $ef
    db $ee, $51, $45, $42, $4a, $62, $42, $3e, $50, $46, $42, $4f, $62, $51, $4c, $ef
    db $ee, $51, $3e, $4a, $42, $5f, $fa, $f7, $ef, $ee, $a3, $37, $45, $42, $62, $4a
    db $4c, $4f, $42, $ef, $ee, $42, $55, $4d, $42, $4b, $50, $46, $53, $42, $62, $51
    db $45, $42, $fa, $f7, $ef, $ee, $51, $4f, $42, $3e, $51, $5e, $62, $51, $45, $42
    db $62, $3f, $42, $51, $51, $42, $4f, $ef, $ee, $46, $51, $62, $54, $4c, $4f, $48
    db $50, $5f, $fa, $f7, $ef, $ee, $a3, $2c, $43, $62, $4c, $4b, $42, $62, $46, $50
    db $62, $4b, $4c, $51, $ef, $ee, $42, $4b, $4c, $52, $44, $45, $5e, $62, $44, $46
    db $53, $42, $62, $51, $45, $42, $4a, $fa, $f7, $ef, $ee, $51, $54, $4c, $62, $4c
    db $4f, $62, $51, $45, $4f, $42, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $a3, $2c
    db $4a, $4d, $4c, $4f, $51, $3e, $4b, $51, $63, $ef, $ee, $2e, $4b, $4c, $40, $48
    db $62, $4c, $52, $51, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50
    db $51, $42, $4f, $62, $56, $4c, $52, $62, $49, $46, $48, $42, $ef, $ee, $49, $3e
    db $50, $51, $5f, $f7, $f0
TextStr_44_6f3e:           ; id $01DD
    ; "*:In the far recesses of the / Chamber of Travelers' / Gates... / *:They say gates exist for every / family of monsters. / *:Every family......"
    db $ea, $9f, $a3, $2c, $4b, $62, $51, $45, $42, $62, $43, $3e, $4f, $ef, $ee, $4f
    db $42, $40, $42, $50, $50, $42, $50, $62, $4c, $43, $62, $51, $45, $42, $fa, $f7
    db $ef, $ee, $26, $45, $3e, $4a, $3f, $42, $4f, $62, $4c, $43, $ef, $ee, $37, $4f
    db $3e, $53, $42, $49, $42, $4f, $50, $5c, $fa, $f7, $ef, $ee, $2a, $3e, $51, $42
    db $50, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $56
    db $62, $50, $3e, $56, $62, $44, $3e, $51, $42, $50, $ef, $ee, $42, $55, $46, $50
    db $51, $62, $43, $4c, $4f, $62, $42, $53, $42, $4f, $56, $fa, $f7, $ef, $ee, $43
    db $3e, $4a, $46, $49, $56, $62, $4c, $43, $ef, $ee, $4a, $4c, $4b, $50, $51, $42
    db $4f, $50, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $28, $53, $42, $4f, $56, $62, $43
    db $3e, $4a, $46, $49, $56, $5f, $5f, $5f, $ef, $ee, $4a, $3e, $56, $3f, $42, $62
    db $46, $4b, $62, $51, $45, $42, $4f, $42, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f
    db $a3, $3c, $4c, $52, $62, $40, $3e, $4b, $62, $42, $3e, $50, $46, $49, $56, $ef
    db $ee, $43, $46, $4b, $41, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $56
    db $4c, $52, $fa, $f7, $ef, $ee, $4a, $46, $50, $50, $42, $41, $62, $51, $4c, $62
    db $3f, $42, $40, $4c, $4a, $42, $ef, $ee, $43, $4f, $46, $42, $4b, $41, $50, $62
    db $54, $46, $51, $45, $5f, $f7, $f0
TextStr_44_7035:           ; id $01DE
    ; "*:There are foreign masters / who... / *:...restore your power. / ...give you lots of meat treats. / *:...send you somewhere. / ...improve o..."
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $62, $3e, $4f, $42, $ef, $ee, $43, $4c
    db $4f, $42, $46, $44, $4b, $62, $4a, $3e, $50, $51, $42, $4f, $50, $fa, $f7, $ef
    db $ee, $54, $45, $4c, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $5f
    db $5f, $5f, $4f, $42, $50, $51, $4c, $4f, $42, $62, $56, $4c, $52, $4f, $ef, $ee
    db $4d, $4c, $54, $42, $4f, $5f, $fa, $f7, $ef, $ee, $5f, $5f, $5f, $44, $46, $53
    db $42, $62, $56, $4c, $52, $62, $49, $4c, $51, $50, $ef, $ee, $4c, $43, $62, $4a
    db $42, $3e, $51, $62, $51, $4f, $42, $3e, $51, $50, $5f, $fa, $f7, $ef, $ee, $9f
    db $a3, $5f, $5f, $5f, $50, $42, $4b, $41, $62, $56, $4c, $52, $ef, $ee, $50, $4c
    db $4a, $42, $54, $45, $42, $4f, $42, $5f, $fa, $f7, $ef, $ee, $5f, $5f, $5f, $46
    db $4a, $4d, $4f, $4c, $53, $42, $62, $4c, $52, $4f, $ef, $ee, $3e, $3f, $46, $49
    db $46, $51, $46, $42, $50, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $4c, $54, $62
    db $40, $3e, $4b, $62, $51, $45, $42, $50, $42, $ef, $ee, $4a, $3e, $50, $51, $42
    db $4f, $50, $62, $3f, $42, $62, $43, $4c, $52, $4b, $41, $64, $f7, $f0
TextStr_44_7103:           ; id $01DF
    ; "*:What kind of guardian is / waiting behind that gate?"
    db $ea, $9f, $a3, $3a, $45, $3e, $51, $62, $48, $46, $4b, $41, $62, $4c, $43, $ef
    db $ee, $44, $52, $3e, $4f, $41, $46, $3e, $4b, $62, $46, $50, $fa, $f7, $ef, $ee
    db $54, $3e, $46, $51, $46, $4b, $44, $62, $3f, $42, $45, $46, $4b, $41, $ef, $ee
    db $51, $45, $3e, $51, $62, $44, $3e, $51, $42, $64, $f7, $f0
TextStr_44_713f:           ; id $01E0
    ; "*:I heard monsters of the bugs family / are behind the gate. / *:They say the king of the / dragons is the guardian. / *:I heard a rumor abo..."
    db $ea, $9f, $a3, $2c, $62, $45, $42, $3e, $4f, $41, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $50, $ef, $ee, $4c, $43, $62, $51, $45, $42, $62, $3f, $52, $44, $50
    db $62, $43, $3e, $4a, $46, $49, $56, $fa, $f7, $ef, $ee, $3e, $4f, $42, $62, $3f
    db $42, $45, $46, $4b, $41, $62, $51, $45, $42, $ef, $ee, $44, $3e, $51, $42, $5f
    db $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $56, $62, $50, $3e, $56, $62, $51
    db $45, $42, $ef, $ee, $48, $46, $4b, $44, $62, $4c, $43, $62, $51, $45, $42, $fa
    db $f7, $ef, $ee, $41, $4f, $3e, $44, $4c, $4b, $50, $62, $46, $50, $62, $51, $45
    db $42, $ef, $ee, $44, $52, $3e, $4f, $41, $46, $3e, $4b, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $2c, $62, $45, $42, $3e, $4f, $41, $62, $3e, $62, $4f, $52, $4a, $4c
    db $4f, $ef, $ee, $3e, $3f, $4c, $52, $51, $62, $51, $45, $42, $62, $2a, $3e, $51
    db $42, $62, $4c, $43, $fa, $f7, $ef, $ee, $27, $42, $4a, $4c, $49, $46, $51, $46
    db $4c, $4b, $5f, $ef, $ee, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $45, $42, $3e
    db $4f, $62, $46, $51, $64, $ff, $f0
TextStr_44_7206:           ; id $01E1
    ; "*:This is the room of Memories & / Bewilder. / *:Go right to the Gate of Bewilder. / Left to the Gate of Memories."
    db $ea, $9f, $a3, $37, $45, $46, $50, $62, $46, $50, $62, $51, $45, $42, $62, $4f
    db $4c, $4c, $4a, $ef, $ee, $4c, $43, $62, $30, $42, $4a, $4c, $4f, $46, $42, $50
    db $62, $b6, $fa, $f7, $ef, $ee, $25, $42, $54, $46, $49, $41, $42, $4f, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2a, $4c, $62, $4f, $46, $44, $45, $51, $62
    db $51, $4c, $62, $51, $45, $42, $ef, $ee, $2a, $3e, $51, $42, $62, $4c, $43, $62
    db $25, $42, $54, $46, $49, $41, $42, $4f, $5f, $fa, $f7, $ef, $ee, $2f, $42, $43
    db $51, $62, $51, $4c, $62, $51, $45, $42, $62, $2a, $3e, $51, $42, $ef, $ee, $4c
    db $43, $62, $30, $42, $4a, $4c, $4f, $46, $42, $50, $5f, $f7, $f0
TextStr_44_7283:           ; id $01E2
    ; "*:Hey [HERO]. Welcome. / *:I am Master Teto. Do you / think you can defeat me? / *:Ha ha ha! Don't let your / defeat bother you!"
    db $ea, $9f, $a3, $2b, $42, $56, $62, $f6, $5f, $ef, $ee, $3a, $42, $49, $40, $4c
    db $4a, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $3e, $4a, $62, $30, $3e
    db $50, $51, $42, $4f, $ef, $ee, $37, $42, $51, $4c, $5f, $62, $27, $4c, $62, $56
    db $4c, $52, $fa, $f7, $ef, $ee, $51, $45, $46, $4b, $48, $62, $56, $4c, $52, $62
    db $40, $3e, $4b, $ef, $ee, $41, $42, $43, $42, $3e, $51, $62, $4a, $42, $64, $fa
    db $f7, $ef, $ee, $9f, $a3, $2b, $3e, $62, $45, $3e, $62, $45, $3e, $63, $ef, $ee
    db $27, $4c, $4b, $67, $62, $49, $42, $51, $62, $56, $4c, $52, $4f, $fa, $f7, $ef
    db $ee, $41, $42, $43, $42, $3e, $51, $62, $3f, $4c, $51, $45, $42, $4f, $ef, $ee
    db $56, $4c, $52, $63, $f7, $f0
TextStr_44_7309:           ; id $01E3
    ; "*:Welcome back. Don't worry about / losing! Just try your best!"
    db $ea, $9f, $a3, $3a, $42, $49, $40, $4c, $4a, $42, $62, $3f, $3e, $40, $48, $5f
    db $ef, $ee, $27, $4c, $4b, $67, $62, $54, $4c, $4f, $4f, $56, $62, $3e, $3f, $4c
    db $52, $51, $fa, $f7, $ef, $ee, $49, $4c, $50, $46, $4b, $44, $63, $62, $2d, $52
    db $50, $51, $62, $51, $4f, $56, $ef, $ee, $56, $4c, $52, $4f, $62, $3f, $42, $50
    db $51, $63, $f7, $f0
TextStr_44_734d:           ; id $01E4
    ; "*:Let me tell you. [YES/NO]"
    db $eb, $9f, $a3, $2f, $42, $51, $62, $4a, $42, $62, $51, $42, $49, $49, $62, $56
    db $4c, $52, $5f, $ef, $ee, $ff, $f0
TextStr_44_7364:           ; id $01E5
    ; "*:We're the hosts. You have to win!"
    db $eb, $9f, $a3, $3a, $42, $69, $42, $62, $51, $45, $42, $62, $45, $4c, $50, $51
    db $50, $5f, $ef, $ee, $3c, $4c, $52, $62, $45, $3e, $53, $42, $62, $51, $4c, $62
    db $54, $46, $4b, $63, $f7, $f0
TextStr_44_738a:           ; id $01E6
    ; "*:The family of the monster you / chose for the pedigree will be / the family of the child! / *:For example, choosing a Dragon / as the pedi..."
    db $eb, $9f, $a3, $37, $45, $42, $62, $43, $3e, $4a, $46, $49, $56, $62, $4c, $43
    db $ef, $ee, $51, $45, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $56, $4c
    db $52, $fa, $f7, $ef, $ee, $40, $45, $4c, $50, $42, $62, $43, $4c, $4f, $62, $51
    db $45, $42, $ef, $ee, $4d, $42, $41, $46, $44, $4f, $42, $42, $62, $54, $46, $49
    db $49, $62, $3f, $42, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $43, $3e, $4a, $46
    db $49, $56, $62, $4c, $43, $62, $51, $45, $42, $ef, $ee, $40, $45, $46, $49, $41
    db $63, $fa, $f7, $ef, $ee, $9f, $a3, $29, $4c, $4f, $62, $42, $55, $3e, $4a, $4d
    db $49, $42, $5e, $ef, $ee, $40, $45, $4c, $4c, $50, $46, $4b, $44, $62, $3e, $62
    db $27, $4f, $3e, $44, $4c, $4b, $fa, $f7, $ef, $ee, $3e, $50, $62, $51, $45, $42
    db $62, $4d, $42, $41, $46, $44, $4f, $42, $42, $62, $b6, $ef, $ee, $36, $49, $46
    db $4a, $42, $62, $43, $4c, $4f, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $4c, $51
    db $45, $42, $4f, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $30, $3e
    db $48, $42, $50, $62, $3e, $ef, $ee, $27, $4f, $3e, $44, $4c, $4b, $2e, $46, $41
    db $5f, $fa, $f7, $ef, $ee, $2a, $4c, $51, $62, $46, $51, $64, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $25, $52, $51, $63, $62, $37, $45, $42, $4f, $42, $62, $3e
    db $4f, $42, $ef, $ee, $42, $55, $40, $42, $4d, $51, $46, $4c, $4b, $50, $63, $f7
    db $f0
TextStr_44_748b:           ; id $01E7
    ; "*:Want to learn about breeding / monsters? [YES/NO]"
    db $eb, $9f, $a3, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $49, $42, $3e, $4f, $4b
    db $ef, $ee, $3e, $3f, $4c, $52, $51, $62, $3f, $4f, $42, $42, $41, $46, $4b, $44
    db $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $64, $ef, $ee, $ff
    db $f0
TextStr_44_74bc:           ; id $01E8
    ; "*:Victories in the arena will / allow you to participate in / the Starry Night Tournament."
    db $eb, $9f, $a3, $39, $46, $40, $51, $4c, $4f, $46, $42, $50, $62, $46, $4b, $ef
    db $ee, $51, $45, $42, $62, $3e, $4f, $42, $4b, $3e, $62, $54, $46, $49, $49, $fa
    db $f7, $ef, $ee, $3e, $49, $49, $4c, $54, $62, $56, $4c, $52, $62, $51, $4c, $ef
    db $ee, $4d, $3e, $4f, $51, $46, $40, $46, $4d, $3e, $51, $42, $62, $46, $4b, $fa
    db $f7, $ef, $ee, $51, $45, $42, $62, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46
    db $44, $45, $51, $ef, $ee, $37, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $5f
    db $f7, $f0
TextStr_44_751e:           ; id $01E9
    ; "*:When monsters from the same / family are bred together... / *:a monster will be born that's the / same as the pedigree. / *:When you breed..."
    db $eb, $9f, $a3, $3a, $45, $42, $4b, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50
    db $ef, $ee, $43, $4f, $4c, $4a, $62, $51, $45, $42, $62, $50, $3e, $4a, $42, $fa
    db $f7, $ef, $ee, $43, $3e, $4a, $46, $49, $56, $62, $3e, $4f, $42, $62, $3f, $4f
    db $42, $41, $ef, $ee, $51, $4c, $44, $42, $51, $45, $42, $4f, $5f, $5f, $5f, $fa
    db $f7, $ef, $ee, $9f, $a3, $3e, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $54
    db $46, $49, $49, $ef, $ee, $3f, $42, $62, $3f, $4c, $4f, $4b, $62, $51, $45, $3e
    db $51, $68, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $50, $3e, $4a, $42, $62, $3e
    db $50, $62, $51, $45, $42, $ef, $ee, $4d, $42, $41, $46, $44, $4f, $42, $42, $5f
    db $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45, $42, $4b, $62, $56, $4c, $52, $62, $3f
    db $4f, $42, $42, $41, $ef, $ee, $3e, $62, $36, $49, $46, $4a, $42, $62, $3e, $4b
    db $41, $62, $3e, $fa, $f7, $ef, $ee, $2b, $42, $3e, $49, $42, $4f, $5f, $5f, $5f
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $24, $62, $36, $49, $46, $4a, $42, $62
    db $54, $46, $49, $49, $62, $3f, $42, $ef, $ee, $3f, $4c, $4f, $4b, $5f, $fa, $f7
    db $ef, $ee, $2c, $50, $62, $51, $45, $46, $50, $62, $40, $49, $42, $3e, $4f, $64
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $32, $43, $62, $40, $4c, $52, $4f, $50
    db $42, $5e, $62, $51, $45, $42, $4f, $42, $ef, $ee, $3e, $4f, $42, $62, $3e, $49
    db $54, $3e, $56, $50, $fa, $f7, $ef, $ee, $42, $55, $40, $42, $4d, $51, $46, $4c
    db $4b, $50, $5f, $ef, $ee, $f7, $f0
TextStr_44_7635:           ; id $01EA
    ; "*:Congratulation on surviving E / class. / *:The Room of Peace & Bravery / is now open!"
    db $ea, $9f, $a3, $26, $4c, $4b, $44, $4f, $3e, $51, $52, $49, $3e, $51, $46, $4c
    db $4b, $ef, $ee, $4c, $4b, $62, $50, $52, $4f, $53, $46, $53, $46, $4b, $44, $62
    db $28, $fa, $f7, $ef, $ee, $40, $49, $3e, $50, $50, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $37, $45, $42, $62, $35, $4c, $4c, $4a, $62, $4c, $43, $ef, $ee
    db $33, $42, $3e, $40, $42, $62, $b6, $62, $25, $4f, $3e, $53, $42, $4f, $56, $fa
    db $f7, $ef, $ee, $46, $50, $62, $4b, $4c, $54, $62, $4c, $4d, $42, $4b, $63, $ef
    db $ee, $f7, $f0
TextStr_44_7698:           ; id $01EB
    ; "*:[HERO]! Doing good huh? / *:The Room of Peace & Bravery / and the Room of Memories & / Bewilder are... / *:now open!"
    db $ea, $9f, $a3, $f6, $63, $ef, $ee, $27, $4c, $46, $4b, $44, $62, $44, $4c, $4c
    db $41, $62, $45, $52, $45, $64, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62
    db $35, $4c, $4c, $4a, $62, $4c, $43, $ef, $ee, $33, $42, $3e, $40, $42, $62, $b6
    db $62, $25, $4f, $3e, $53, $42, $4f, $56, $fa, $f7, $ef, $ee, $3e, $4b, $41, $62
    db $51, $45, $42, $62, $35, $4c, $4c, $4a, $62, $4c, $43, $ef, $ee, $30, $42, $4a
    db $4c, $4f, $46, $42, $50, $62, $b6, $fa, $f7, $ef, $ee, $25, $42, $54, $46, $49
    db $41, $42, $4f, $62, $3e, $4f, $42, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $4b, $4c, $54, $62, $4c, $4d, $42, $4b, $63, $ef, $ee, $f7, $f0
TextStr_44_7717:           ; id $01EC
    ; "*:Are you familiar with the Gate of / Bravery? [YES/NO]"
    db $eb, $9f, $a3, $24, $4f, $42, $62, $56, $4c, $52, $62, $43, $3e, $4a, $46, $49
    db $46, $3e, $4f, $ef, $ee, $54, $46, $51, $45, $62, $51, $45, $42, $62, $2a, $3e
    db $51, $42, $62, $4c, $43, $fa, $f7, $ef, $ee, $25, $4f, $3e, $53, $42, $4f, $56
    db $64, $ef, $ee, $ff, $f0
TextStr_44_774c:           ; id $01ED
    ; "*:Despair is a part of hope! / Hope is embedded in despair! / *:A quote from Happy Ways to / Overcome Your Despair."
    db $eb, $9f, $a3, $27, $42, $50, $4d, $3e, $46, $4f, $62, $46, $50, $62, $3e, $ef
    db $ee, $4d, $3e, $4f, $51, $62, $4c, $43, $62, $45, $4c, $4d, $42, $63, $fa, $f7
    db $ef, $ee, $2b, $4c, $4d, $42, $62, $46, $50, $62, $42, $4a, $3f, $42, $41, $41
    db $42, $41, $ef, $ee, $46, $4b, $62, $41, $42, $50, $4d, $3e, $46, $4f, $63, $fa
    db $f7, $ef, $ee, $9f, $a3, $24, $62, $4e, $52, $4c, $51, $42, $62, $43, $4f, $4c
    db $4a, $ef, $ee, $2b, $3e, $4d, $4d, $56, $62, $3a, $3e, $56, $50, $62, $51, $4c
    db $fa, $f7, $ef, $ee, $32, $53, $42, $4f, $40, $4c, $4a, $42, $62, $3c, $4c, $52
    db $4f, $ef, $ee, $27, $42, $50, $4d, $3e, $46, $4f, $5f, $f7, $f0
TextStr_44_77c9:           ; id $01EE
    ; "Are you familiar with the Gate of / Peace? [YES/NO]"
    db $eb, $24, $4f, $42, $62, $56, $4c, $52, $62, $43, $3e, $4a, $46, $49, $46, $3e
    db $4f, $ef, $ee, $54, $46, $51, $45, $62, $51, $45, $42, $62, $2a, $3e, $51, $42
    db $62, $4c, $43, $fa, $f7, $ef, $ee, $33, $42, $3e, $40, $42, $64, $ef, $ee, $ff
    db $f0
TextStr_44_77fa:           ; id $01EF
    ; "*:Discretion is the better part of / valor. / *:Danger! Do not talk to the people / who are not making much money!! / *:A quote from Make Yo..."
    db $eb, $9f, $a3, $27, $46, $50, $40, $4f, $42, $51, $46, $4c, $4b, $62, $46, $50
    db $ef, $ee, $51, $45, $42, $62, $3f, $42, $51, $51, $42, $4f, $62, $4d, $3e, $4f
    db $51, $62, $4c, $43, $fa, $f7, $ef, $ee, $53, $3e, $49, $4c, $4f, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $27, $3e, $4b, $44, $42, $4f, $63, $62, $27, $4c
    db $62, $4b, $4c, $51, $ef, $ee, $51, $3e, $49, $48, $62, $51, $4c, $62, $51, $45
    db $42, $62, $4d, $42, $4c, $4d, $49, $42, $fa, $f7, $ef, $ee, $54, $45, $4c, $62
    db $3e, $4f, $42, $62, $4b, $4c, $51, $62, $4a, $3e, $48, $46, $4b, $44, $ef, $ee
    db $4a, $52, $40, $45, $62, $4a, $4c, $4b, $42, $56, $63, $63, $fa, $f7, $ef, $ee
    db $9f, $a3, $24, $62, $4e, $52, $4c, $51, $42, $62, $43, $4f, $4c, $4a, $ef, $ee
    db $30, $3e, $48, $42, $62, $3c, $4c, $52, $4f, $62, $30, $4c, $4b, $42, $56, $fa
    db $f7, $ef, $ee, $2a, $4f, $4c, $54, $5f, $ef, $ee, $f7, $f0
TextStr_44_78a6:           ; id $01F0
    ; "[SOUND 60][HERO] looked into the dresser. / It is packed with dresses!"
    db $e9, $60, $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $46, $4b, $51, $4c, $ef
    db $ee, $51, $45, $42, $62, $41, $4f, $42, $50, $50, $42, $4f, $5f, $fa, $f7, $ef
    db $ee, $2c, $51, $62, $46, $50, $62, $4d, $3e, $40, $48, $42, $41, $62, $54, $46
    db $51, $45, $ef, $ee, $41, $4f, $42, $50, $50, $42, $50, $63, $f7, $f0
TextStr_44_78e4:           ; id $01F1
    ; "*:In an enormous underground / dungeon. / *:I fear pitfalls with every step / I take... / *:Will I ever make it out? / *:A quote from the ma..."
    db $eb, $9f, $a3, $2c, $4b, $62, $3e, $4b, $62, $42, $4b, $4c, $4f, $4a, $4c, $52
    db $50, $ef, $ee, $52, $4b, $41, $42, $4f, $44, $4f, $4c, $52, $4b, $41, $fa, $f7
    db $ef, $ee, $41, $52, $4b, $44, $42, $4c, $4b, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $2c, $62, $43, $42, $3e, $4f, $62, $4d, $46, $51, $43, $3e, $49, $49
    db $50, $ef, $ee, $54, $46, $51, $45, $62, $42, $53, $42, $4f, $56, $62, $50, $51
    db $42, $4d, $fa, $f7, $ef, $ee, $2c, $62, $51, $3e, $48, $42, $5f, $5f, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $46, $49, $49, $62, $2c, $62, $42, $53
    db $42, $4f, $ef, $ee, $4a, $3e, $48, $42, $62, $46, $51, $62, $4c, $52, $51, $64
    db $fa, $f7, $ef, $ee, $9f, $a3, $24, $62, $4e, $52, $4c, $51, $42, $62, $43, $4f
    db $4c, $4a, $ef, $ee, $51, $45, $42, $62, $4a, $3e, $50, $51, $42, $4f, $4d, $46
    db $42, $40, $42, $5e, $fa, $f7, $ef, $ee, $24, $62, $2d, $4c, $52, $4f, $4b, $42
    db $56, $62, $51, $4c, $ef, $ee, $2f, $4c, $4b, $41, $42, $49, $48, $46, $3e, $5f
    db $f7, $f0
TextStr_44_79a6:           ; id $01F2
    ; "King:Oh [HERO]! You beat BigEye! / King:What? BigEye refused / to be your pal? / King:Oh well, these things / happen. / King:I forgot to tel..."
    db $ea, $2e, $46, $4b, $44, $a3, $32, $45, $62, $f6, $63, $ef, $ee, $3c, $4c, $52
    db $62, $3f, $42, $3e, $51, $62, $25, $46, $44, $28, $56, $42, $63, $fa, $f7, $ef
    db $ee, $2e, $46, $4b, $44, $a3, $3a, $45, $3e, $51, $64, $ef, $ee, $25, $46, $44
    db $28, $56, $42, $62, $4f, $42, $43, $52, $50, $42, $41, $fa, $f7, $ef, $ee, $51
    db $4c, $62, $3f, $42, $62, $56, $4c, $52, $4f, $62, $4d, $3e, $49, $64, $ef, $ee
    db $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $32, $45, $62, $54, $42, $49, $49
    db $5e, $ef, $ee, $51, $45, $42, $50, $42, $62, $51, $45, $46, $4b, $44, $50, $fa
    db $f7, $ef, $ee, $45, $3e, $4d, $4d, $42, $4b, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $2e, $46, $4b, $44, $a3, $2c, $62, $43, $4c, $4f, $44, $4c, $51, $62, $51, $4c
    db $ef, $ee, $51, $42, $49, $49, $62, $56, $4c, $52, $5e, $62, $3f, $52, $51, $fa
    db $f7, $ef, $ee, $3f, $4c, $50, $50, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50
    db $ef, $ee, $41, $4c, $4b, $67, $62, $4b, $42, $42, $41, $62, $51, $4f, $42, $3e
    db $51, $50, $5f, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $37, $45, $42, $56
    db $62, $3f, $42, $40, $4c, $4a, $42, $ef, $ee, $56, $4c, $52, $4f, $62, $4d, $3e
    db $49, $62, $54, $45, $42, $4b, $fa, $f7, $ef, $ee, $51, $45, $42, $56, $62, $54
    db $3e, $4b, $51, $62, $51, $4c, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b
    db $44, $a3, $2c, $43, $62, $51, $45, $42, $56, $ef, $ee, $41, $4c, $4b, $67, $62
    db $54, $3e, $4b, $51, $62, $51, $4c, $fa, $f7, $ef, $ee, $51, $45, $42, $56, $62
    db $41, $4c, $4b, $67, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3
    db $36, $4c, $62, $56, $4c, $52, $62, $41, $4c, $4b, $67, $ef, $ee, $4b, $42, $42
    db $41, $62, $51, $4c, $62, $54, $3e, $50, $51, $42, $fa, $f7, $ef, $ee, $51, $4f
    db $42, $3e, $51, $50, $62, $4c, $4b, $62, $51, $45, $42, $4a, $ef, $ee, $fa, $f7
    db $ef, $ee, $2e, $46, $4b, $44, $a3, $3e, $4b, $41, $62, $56, $4c, $52, $62, $40
    db $3e, $4b, $ef, $ee, $50, $3e, $53, $42, $62, $56, $4c, $52, $4f, $62, $44, $4c
    db $49, $41, $63, $63, $f7, $f0
TextStr_44_7b2c:           ; id $01F3
    ; "[HERO] checked out the stuffed / animal. / The stuffed animal looks familiar."
    db $f6, $62, $40, $45, $42, $40, $48, $42, $41, $62, $4c, $52, $51, $ef, $ee, $51
    db $45, $42, $62, $50, $51, $52, $43, $43, $42, $41, $fa, $f7, $ef, $ee, $3e, $4b
    db $46, $4a, $3e, $49, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $37, $45, $42, $62, $50
    db $51, $52, $43, $43, $42, $41, $62, $3e, $4b, $46, $4a, $3e, $49, $ef, $ee, $49
    db $4c, $4c, $48, $50, $62, $43, $3e, $4a, $46, $49, $46, $3e, $4f, $5f, $f7, $f0
TextStr_44_7b7c:           ; id $01F4
    ; "King:Oh,[HERO] you beat / FangSlime! / King:You visited the casino? Did / you have any luck? / King:What? Monster Gold? It isn't / worth any..."
    db $ea, $2e, $46, $4b, $44, $a3, $32, $45, $5e, $f6, $ef, $ee, $56, $4c, $52, $62
    db $3f, $42, $3e, $51, $fa, $f7, $ef, $ee, $29, $3e, $4b, $44, $36, $49, $46, $4a
    db $42, $63, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $3c, $4c, $52
    db $62, $53, $46, $50, $46, $51, $42, $41, $ef, $ee, $51, $45, $42, $62, $40, $3e
    db $50, $46, $4b, $4c, $64, $62, $27, $46, $41, $fa, $f7, $ef, $ee, $56, $4c, $52
    db $62, $45, $3e, $53, $42, $62, $3e, $4b, $56, $62, $49, $52, $40, $48, $64, $ef
    db $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $3a, $45, $3e, $51, $64, $62
    db $30, $4c, $4b, $50, $51, $42, $4f, $ef, $ee, $2a, $4c, $49, $41, $64, $62, $2c
    db $51, $62, $46, $50, $4b, $67, $fa, $f7, $ef, $ee, $54, $4c, $4f, $51, $45, $62
    db $3e, $4b, $56, $51, $45, $46, $4b, $44, $ef, $ee, $45, $42, $4f, $42, $63, $63
    db $f7, $f0
TextStr_44_7c1e:           ; id $01F5
    ; "*:There's a reason why wild / monsters don't live on this side. / *:Long long ago... An ancestor of / Watabou locked the monsters... / *:beh..."
    db $eb, $9f, $a3, $37, $45, $42, $4f, $42, $68, $62, $3e, $ef, $ee, $4f, $42, $3e
    db $50, $4c, $4b, $62, $54, $45, $56, $62, $54, $46, $49, $41, $fa, $f7, $ef, $ee
    db $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $41, $4c, $4b, $67, $ef, $ee, $49
    db $46, $53, $42, $62, $4c, $4b, $62, $51, $45, $46, $50, $62, $50, $46, $41, $42
    db $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2f, $4c, $4b, $44, $62, $49, $4c, $4b, $44
    db $62, $3e, $44, $4c, $5f, $5f, $5f, $ef, $ee, $24, $4b, $62, $3e, $4b, $40, $42
    db $50, $51, $4c, $4f, $62, $4c, $43, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f
    db $4c, $52, $62, $49, $4c, $40, $48, $42, $41, $ef, $ee, $51, $45, $42, $62, $4a
    db $4c, $4b, $50, $51, $42, $4f, $50, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3
    db $3f, $42, $45, $46, $4b, $41, $62, $51, $45, $42, $ef, $ee, $37, $4f, $3e, $53
    db $42, $49, $42, $4f, $50, $5c, $62, $2a, $3e, $51, $42, $50, $fa, $f7, $ef, $ee
    db $51, $4c, $62, $4d, $4f, $4c, $51, $42, $40, $51, $62, $45, $52, $4a, $3e, $4b
    db $50, $ef, $ee, $43, $4f, $4c, $4a, $62, $51, $45, $42, $4a, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $32, $52, $4f, $62, $3e, $4b, $40, $42, $50, $51, $4c, $4f, $50
    db $ef, $ee, $41, $42, $40, $4f, $42, $42, $41, $62, $51, $45, $3e, $51, $62, $3e
    db $fa, $f7, $ef, $ee, $9f, $a3, $37, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51
    db $62, $3f, $42, $ef, $ee, $45, $42, $49, $41, $62, $42, $53, $42, $4f, $56, $fa
    db $f7, $ef, $ee, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45, $51, $63
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $41, $4c, $4b, $67, $62, $48
    db $4b, $4c, $54, $62, $46, $43, $ef, $ee, $46, $51, $68, $62, $51, $4f, $52, $42
    db $5f, $62, $25, $52, $51, $fa, $f7, $ef, $ee, $51, $45, $3e, $51, $62, $46, $50
    db $62, $54, $45, $56, $62, $54, $42, $ef, $ee, $45, $4c, $49, $41, $62, $51, $45
    db $42, $fa, $f7, $ef, $ee, $51, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $5f
    db $ef, $ee, $f7, $f0
TextStr_44_7d92:           ; id $01F6
    ; "*:You are at the castle of / GreatTree. / *:To get to the village of / GreatTree, go down to the outside. / *:For the Shrine of Starry Night..."
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $3e, $4f, $42, $62, $3e, $51, $ef, $ee, $51
    db $45, $42, $62, $40, $3e, $50, $51, $49, $42, $62, $4c, $43, $fa, $f7, $ef, $ee
    db $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $37, $4c, $62, $44, $42, $51, $62, $51, $4c, $62, $51, $45, $42, $ef
    db $ee, $53, $46, $49, $49, $3e, $44, $42, $62, $4c, $43, $fa, $f7, $ef, $ee, $2a
    db $4f, $42, $3e, $51, $37, $4f, $42, $42, $5e, $62, $44, $4c, $62, $41, $4c, $54
    db $4b, $ef, $ee, $51, $4c, $62, $51, $45, $42, $62, $4c, $52, $51, $50, $46, $41
    db $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $29, $4c, $4f, $62, $51, $45, $42, $62
    db $36, $45, $4f, $46, $4b, $42, $ef, $ee, $4c, $43, $62, $36, $51, $3e, $4f, $4f
    db $56, $62, $31, $46, $44, $45, $51, $5e, $fa, $f7, $ef, $ee, $44, $4c, $62, $41
    db $4c, $54, $4b, $62, $43, $4f, $4c, $4a, $62, $51, $45, $42, $ef, $ee, $53, $46
    db $49, $49, $3e, $44, $42, $5f, $f7, $f0
TextStr_44_7e4a:           ; id $01F7
    ; "*:Wishing upon the stars on / Starry Night, / *:makes your wish come true..."
    db $eb, $9f, $a3, $3a, $46, $50, $45, $46, $4b, $44, $62, $52, $4d, $4c, $4b, $62
    db $51, $45, $42, $ef, $ee, $50, $51, $3e, $4f, $50, $62, $4c, $4b, $fa, $f7, $ef
    db $ee, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45, $51, $5e, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $4a, $3e, $48, $42, $50, $62, $56, $4c, $52, $4f
    db $ef, $ee, $54, $46, $50, $45, $62, $40, $4c, $4a, $42, $62, $51, $4f, $52, $42
    db $5f, $5f, $5f, $f7, $f0
TextStr_44_7e9f:           ; id $01F8
    ; "*:GreatLog is the closest country / to GreatTree. / *:Lots of strong masters live / there."
    db $eb, $9f, $a3, $2a, $4f, $42, $3e, $51, $2f, $4c, $44, $62, $46, $50, $62, $51
    db $45, $42, $ef, $ee, $40, $49, $4c, $50, $42, $50, $51, $62, $40, $4c, $52, $4b
    db $51, $4f, $56, $fa, $f7, $ef, $ee, $51, $4c, $62, $2a, $4f, $42, $3e, $51, $37
    db $4f, $42, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2f, $4c, $51, $50
    db $62, $4c, $43, $62, $50, $51, $4f, $4c, $4b, $44, $ef, $ee, $4a, $3e, $50, $51
    db $42, $4f, $50, $62, $49, $46, $53, $42, $fa, $f7, $ef, $ee, $51, $45, $42, $4f
    db $42, $5f, $ef, $ee, $f7, $f0
TextStr_44_7f05:           ; id $01F9
    ; "*:You've been babied forever! / *:Can someone like that really make / it to the Starry Night?"
    db $eb, $9f, $a3, $3c, $4c, $52, $6c, $42, $62, $3f, $42, $42, $4b, $ef, $ee, $3f
    db $3e, $3f, $46, $42, $41, $62, $43, $4c, $4f, $42, $53, $42, $4f, $63, $fa, $f7
    db $ef, $ee, $9f, $a3, $26, $3e, $4b, $62, $50, $4c, $4a, $42, $4c, $4b, $42, $62
    db $49, $46, $48, $42, $ef, $ee, $51, $45, $3e, $51, $62, $4f, $42, $3e, $49, $49
    db $56, $62, $4a, $3e, $48, $42, $fa, $f7, $ef, $ee, $46, $51, $62, $51, $4c, $62
    db $51, $45, $42, $62, $36, $51, $3e, $4f, $4f, $56, $ef, $ee, $31, $46, $44, $45
    db $51, $64, $f7, $f0, $00
; --- END re-sectioned text run (bank $44) ---
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

