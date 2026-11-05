; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $042", ROMX[$4000], BANK[$42]

    db $42 ; Bank number

    ; Cross-bank dispatch table (117 entries)
    ; Called via: ld hl, $42XX / rst $10
    dw LoadB42_40eb                  ; Entry 0
    dw TextRunB42_4108               ; Entry 1
    dw TextShowRefreshB42_4125       ; Entry 2
    dw $4009                          ; Entry 3 — mode 0 -> table $4009 (mode list $4007)
    dw TextStr_42_4142               ; Entry 4 — [table $4009]; text $0000 "Milayou:Terry! Wait! It's time fo…"
    dw TextStr_42_4244               ; Entry 5 — text $0001 "Milayou:... zzz."
    dw TextStr_42_4259               ; Entry 6 — text $0002 "Terry looked at a stuffed animal.…"
    dw TextStr_42_42d0               ; Entry 7 — text $0003 "Terry looked in front of him. A f…"
    dw TextStr_42_4323               ; Entry 8 — text $0004 "Terry looked at the bookshelf. :A…"
    dw TextStr_42_43b0               ; Entry 9 — text $0005 "Terry looked at the bookshelf. :D…"
    dw TextStr_42_4431               ; Entry 10 — text $0006 "[SOUND 60]Terry looked in the dre…"
    dw TextStr_42_4473               ; Entry 11 — text $0007 "[SOUND 60]Terry looked in the dre…"
    dw TextStr_42_44ba               ; Entry 12 — text $0008 "*:Are you Milayou? *:Hm, You don'…"
    dw TextStr_42_4590               ; Entry 13 — text $0009 "*:Huh? What happened? Where is Mi…"
    dw TextStr_42_45c1               ; Entry 14 — text $000A "*:You speak monster talk don't yo…"
    dw TextStr_42_476a               ; Entry 15 — text $000B "Terry looks at the bookshelf. :En…"
    dw TextStr_42_47bf               ; Entry 16 — text $000C "Terry looked at the bookshelf. To…"
    dw TextStr_42_47fb               ; Entry 17 — text $000D "Terry looked in front of him. The…"
    dw TextStr_42_483b               ; Entry 18 — text $000E "Terry looked at a stuffed animal.…"
    dw TextStr_42_48b2               ; Entry 19 — text $000F "*:Oh, you must be the master. You…"
    dw TextStr_42_49cf               ; Entry 20 — text $0010 "*:This kingdom is created inside …"
    dw TextStr_42_4a3e               ; Entry 21 — text $0011 "*:Hey, is he the new master Watab…"
    dw TextStr_42_4a77               ; Entry 22 — text $0012 "*:Yes indeed, I'm taking him to s…"
    dw TextStr_42_4aac               ; Entry 23 — text $0013 "*:Good luck at the Starry Night T…"
    dw TextStr_42_4ae0               ; Entry 24 — text $0014 "*:Now it's time to go see the Kin…"
    dw TextStr_42_4b06               ; Entry 25 — text $0015 "*:I'm the minister of this kingdo…"
    dw TextStr_42_4b9c               ; Entry 26 — text $0016 "*:His Majesty is in trouble. Plea…"
    dw TextStr_42_4bd7               ; Entry 27 — text $0017 "*:Please listen to his wish."
    dw TextStr_42_4bf7               ; Entry 28 — text $0018 "*:This is the castle of GreatTree."
    dw TextStr_42_4c22               ; Entry 29 — text $0019 "*:Hurry! Go see the King!"
    dw TextStr_42_4c3f               ; Entry 30 — text $001A "*:I see....."
    dw TextStr_42_4c50               ; Entry 31 — text $001B "[HERO] opened a treasure chest!"
    dw TextStr_42_4c6e               ; Entry 32 — text $001C "[HERO] picked up an Herb."
    dw TextStr_42_4c85               ; Entry 33 — text $001D "[HERO] found an Herb. But cannot …"
    dw TextStr_42_4cea               ; Entry 34 — text $001E "[HERO] opened a treasure chest!"
    dw TextStr_42_4d08               ; Entry 35 — text $001F "*:This is the Kingdom of GreatTre…"
    dw TextStr_42_4d34               ; Entry 36 — text $0020 "*:Welcome! I am the King of this …"
    dw TextStr_42_4d91               ; Entry 37 — text $0021 "King:Oh [HERO]! Will you comply w…"
    dw TextStr_42_517b               ; Entry 38 — text $0022 "*:Everybody will be happy if you …"
    dw TextStr_42_51db               ; Entry 39 — text $0023 "*:I have a feeling that your vict…"
    dw TextStr_42_522c               ; Entry 40 — text $0024 "[HERO] looked at the bookshelf. :…"
    dw TextStr_42_5285               ; Entry 41 — text $0025 ":It's a little kingdom built insi…"
    dw TextStr_42_53f1               ; Entry 42 — text $0026 "[HERO] returned the book to the b…"
    dw TextStr_42_541e               ; Entry 43 — text $0027 "[HERO] looked at the bookshelf. T…"
    dw TextStr_42_5474               ; Entry 44 — text $0028 ":People who understand monster ta…"
    dw TextStr_42_55d7               ; Entry 45 — text $0029 "*:I wanna be a master. What shoul…"
    dw TextStr_42_5608               ; Entry 46 — text $002A "King:The monster farm is on the u…"
    dw TextStr_42_5677               ; Entry 47 — text $002B "*:My kingdom has been losing in t…"
    dw TextStr_42_56fd               ; Entry 48 — text $002C "*:Let me tell you about the legen…"
    dw TextStr_42_58b2               ; Entry 49 — text $002D "*:Should I repeat the legend of t…"
    dw TextStr_42_58ec               ; Entry 50 — text $002E "*:Here it is again. *:The Starry …"
    dw TextStr_42_5a53               ; Entry 51 — text $002F "*:The tournament is held on the S…"
    dw TextStr_42_5b00               ; Entry 52 — text $0030 "*:Pulio from the farm is goofy bu…"
    dw TextStr_42_5b3c               ; Entry 53 — text $0031 "*:Upper floor, the monster farm. …"
    dw TextStr_42_5b99               ; Entry 54 — text $0032 "*:Watabou brings us capable maste…"
    dw TextStr_42_5c54               ; Entry 55 — text $0033 "*:I wonder where I can get treats."
    dw TextStr_42_5c7a               ; Entry 56 — text $0034 "[HERO] read the sign. :Danger, Do…"
    dw TextStr_42_5cc2               ; Entry 57 — text $0035 "*:No! You'll be hurt if you fall."
    dw TextStr_42_5ce6               ; Entry 58 — text $0036 "*:If it was not for this hole... …"
    dw TextStr_42_5d55               ; Entry 59 — text $0037 "[HERO] read the sign. :When the G…"
    dw TextStr_42_5e08               ; Entry 60 — text $0038 "*:I heard that Pulio let the mons…"
    dw TextStr_42_5e3e               ; Entry 61 — text $0039 "*:Hey, Mr.Monster Master. I wonde…"
    dw TextStr_42_5ed1               ; Entry 62 — text $003A "[HERO] looked into the jar."
    dw TextStr_42_5eeb               ; Entry 63 — text $003B "[HERO] looked into the jar. The j…"
    dw TextStr_42_5f28               ; Entry 64 — text $003C "*:Hey you! You came here to steal…"
    dw TextStr_42_5f5f               ; Entry 65 — text $003D "*:C'mon, I'll give you a beating.…"
    dw TextStr_42_6007               ; Entry 66 — text $003E "*:You came here to get monsters?"
    dw TextStr_42_602c               ; Entry 67 — text $003F "*:I'm Pulio I take care of this f…"
    dw TextStr_42_6159               ; Entry 68 — text $0040 "*:I'm Slio. I am the grandson of …"
    dw TextStr_42_61bd               ; Entry 69 — text $0041 "Slio:You can drop off up to 19 mo…"
    dw TextStr_42_6437               ; Entry 70 — text $0042 "Slio:Raise the monster to be powe…"
    dw TextStr_42_6466               ; Entry 71 — text $0043 "Slio:D'ya wanna know about the fa…"
    dw TextStr_42_6492               ; Entry 72 — text $0044 "*:You are at the monster farm."
    dw TextStr_42_64b4               ; Entry 73 — text $0045 "King:Oh, this monster is the form…"
    dw TextStr_42_65b6               ; Entry 74 — text $0046 "Pulio:Your Majesty, please forgiv…"
    dw TextStr_42_65e5               ; Entry 75 — text $0047 "King:Pulio, did Hale escape as we…"
    dw TextStr_42_6612               ; Entry 76 — text $0048 "Pulio:Your Majesty please forgive…"
    dw TextStr_42_6651               ; Entry 77 — text $0049 "King:Arrgh! You! You let my preci…"
    dw TextStr_42_66cc               ; Entry 78 — text $004A "King:What? [HERO]! You have somet…"
    dw TextStr_42_6791               ; Entry 79 — text $004B "Pulio:Majesty, Hale escaped throu…"
    dw TextStr_42_67d1               ; Entry 80 — text $004C "King:I see. Now [HERO], proceed t…"
    dw TextStr_42_68df               ; Entry 81 — text $004D "*:His Majesty seems to be very up…"
    dw TextStr_42_6966               ; Entry 82 — text $004E "*:Give the courageous master [HER…"
    dw TextStr_42_69a4               ; Entry 83 — text $004F "*:In the Chamber of Travelers' Ga…"
    dw TextStr_42_6aba               ; Entry 84 — text $0050 "Pulio:Sorry [HERO], It's my fault…"
    dw TextStr_42_6b5b               ; Entry 85 — text $0051 "*:These stairs bring you to the C…"
    dw TextStr_42_6ba3               ; Entry 86 — text $0052 "*:Please bring Hale back as soon …"
    dw TextStr_42_6bd9               ; Entry 87 — text $0053 "*:When you enter the Travelers' G…"
    dw TextStr_42_6dc6               ; Entry 88 — text $0054 "*:You will find items scattered a…"
    dw TextStr_42_6e72               ; Entry 89 — text $0055 "*:Hale was the cherished pet of t…"
    dw TextStr_42_6f1c               ; Entry 90 — text $0056 "*:Welcome to the Chamber of Trave…"
    dw TextStr_42_6f60               ; Entry 91 — text $0057 "*:We are at the Chamber of Travel…"
    dw TextStr_42_6ffe               ; Entry 92 — text $0058 "*:How do you do. I'm Hale. *:I kn…"
    dw TextStr_42_7092               ; Entry 93 — text $0059 "*:You are strong! I like you, [HE…"
    dw TextStr_42_70bb               ; Entry 94 — text $005A "King:Oh, [HERO]! Did you bring ba…"
    dw TextStr_42_71fe               ; Entry 95 — text $005B "Pulio:Thank you [HERO]! Now I can…"
    dw TextStr_42_7236               ; Entry 96 — text $005C "King:[HERO]. Go to the arena. Kin…"
    dw TextStr_42_7314               ; Entry 97 — text $005D "Slio:[HERO]! Congratulations on y…"
    dw TextStr_42_736b               ; Entry 98 — text $005E "*:To get to the arena, go straigh…"
    dw TextStr_42_73fe               ; Entry 99 — text $005F "*:These stairs go up to the monst…"
    dw TextStr_42_7430               ; Entry 100 — text $0060 "*:This is the castle of GreatTree…"
    dw TextStr_42_749a               ; Entry 101 — text $0061 "*:Oh boy! This looks dangerous! O…"
    dw TextStr_42_74ca               ; Entry 102 — text $0062 "*:This is the village of GreatTre…"
    dw TextStr_42_7527               ; Entry 103 — text $0063 "*:Fhew! I'm glad that I didn't ge…"
    dw TextStr_42_756f               ; Entry 104 — text $0064 "*:Oh [HERO], it's you. I am getti…"
    dw TextStr_42_75f1               ; Entry 105 — text $0065 "*:Once I picked up a TinyMedal, *…"
    dw TextStr_42_7779               ; Entry 106 — text $0066 "*:Would you like to see the list …"
    dw TextStr_42_77b7               ; Entry 107 — text $0067 "*:You can enter the locked rooms …"
    dw TextStr_42_78fc               ; Entry 108 — text $0068 "*:Monsters have personalities too…"
    dw TextStr_42_7a31               ; Entry 109 — text $0069 "*:Hey Master! D'ya have an egg? […"
    dw TextStr_42_7a53               ; Entry 110 — text $006A "Splat... Poop hit [HERO]."
    dw TextStr_42_7a6a               ; Entry 111 — text $006B "Thwack! It was the egg of a SkyDr…"
    dw TextStr_42_7aaf               ; Entry 112 — text $006C "[HERO] took the egg of a SkyDrago…"
    dw TextStr_42_7b2f               ; Entry 113 — text $006D "Could not keep the egg because th…"
    dw TextStr_42_7c00               ; Entry 114 — text $006E "Splash! Poop hit [HERO]."
    dw TextStr_42_7c16               ; Entry 115 — text $006F "*:Treats! BeefJerky, PorkChop, Ri…"
    dw TextStr_42_7cc6               ; Entry 116 — text $0070 "*:If you take monsters on a journ…"

LoadB42_40eb:
    ld a, [$c823]
    cp $71
    jr c, jr_042_4101

    sub $71
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $1a00
    rst $10
    ret


jr_042_4101:
    ld de, $4007
    call CallTextEngine
    ret


; [S166] copy a text of this bank (RunTextHandler); ids past the bank's range go to its overflow bank (TEXT_SYSTEM "Text id resolution")
TextRunB42_4108:
    ld a, [$c823]
    cp $71
    jr c, jr_042_411e

    sub $71
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $1a01
    rst $10
    ret


jr_042_411e:
    ld de, $4007
    call RunTextHandler
    ret


; [S166] show a text (entry 0) then RequestScreenUpdate
TextShowRefreshB42_4125:
    ld a, [$c823]
    cp $71
    jr c, jr_042_413b

    sub $71
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $1a02
    rst $10
    ret


jr_042_413b:
    call LoadB42_40eb
    call RequestScreenUpdate
    ret


; --- BEGIN re-sectioned text run (bank $42: $4142-$7dc5) ---
; DTE-encoded dialogue strings, one label per text id (text_id_map.json).
; Labels/comments only; bytes are byte-identical to the original ROM.
TextStr_42_4142:           ; id $0000
    ; "Milayou:Terry! Wait! It's time / for bed! / Milayou:Did you forget what Mom / and Dad told us? / Milayou:Stay up too late and you / will be ..."
    db $eb, $30, $46, $49, $3e, $56, $4c, $52, $a3, $37, $42, $4f, $4f, $56, $63, $ef
    db $ee, $3a, $3e, $46, $51, $63, $62, $2c, $51, $68, $62, $51, $46, $4a, $42, $fa
    db $f7, $ef, $ee, $43, $4c, $4f, $62, $3f, $42, $41, $63, $ef, $ee, $fa, $f7, $ef
    db $ee, $30, $46, $49, $3e, $56, $4c, $52, $a3, $27, $46, $41, $62, $56, $4c, $52
    db $ef, $ee, $43, $4c, $4f, $44, $42, $51, $62, $54, $45, $3e, $51, $62, $30, $4c
    db $4a, $fa, $f7, $ef, $ee, $3e, $4b, $41, $62, $27, $3e, $41, $62, $51, $4c, $49
    db $41, $62, $52, $50, $64, $ef, $ee, $fa, $f7, $ef, $ee, $30, $46, $49, $3e, $56
    db $4c, $52, $a3, $36, $51, $3e, $56, $62, $52, $4d, $ef, $ee, $51, $4c, $4c, $62
    db $49, $3e, $51, $42, $62, $3e, $4b, $41, $62, $56, $4c, $52, $fa, $f7, $ef, $ee
    db $54, $46, $49, $49, $62, $3f, $42, $62, $40, $3e, $4f, $4f, $46, $42, $41, $ef
    db $ee, $3e, $54, $3e, $56, $62, $3f, $56, $62, $4a, $4c, $4b, $50, $51, $42, $4f
    db $50, $5f, $fa, $f7, $ef, $ee, $30, $46, $49, $3e, $56, $4c, $52, $a3, $3a, $45
    db $3e, $51, $64, $62, $3c, $4c, $52, $ef, $ee, $54, $3e, $4b, $4b, $3e, $62, $4a
    db $42, $42, $51, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $64
    db $ef, $ee, $27, $4c, $4b, $67, $62, $3f, $42, $62, $50, $46, $49, $49, $56, $5e
    db $fa, $f7, $ef, $ee, $44, $4c, $62, $51, $4c, $62, $3f, $42, $41, $63, $ef, $ee
    db $f7, $f0
TextStr_42_4244:           ; id $0001
    ; "Milayou:... zzz."
    db $eb, $30, $46, $49, $3e, $56, $4c, $52, $a3, $5f, $5f, $5f, $62, $57, $57, $57
    db $5f, $ef, $ee, $f7, $f0
TextStr_42_4259:           ; id $0002
    ; "Terry looked at a stuffed animal. / Something is written on it in / tiny cute letters. / :Property of Milayou"
    db $37, $42, $4f, $4f, $56, $62, $49, $4c, $4c, $48, $42, $41, $62, $3e, $51, $ef
    db $ee, $3e, $62, $50, $51, $52, $43, $43, $42, $41, $62, $3e, $4b, $46, $4a, $3e
    db $49, $5f, $fa, $f7, $ef, $ee, $36, $4c, $4a, $42, $51, $45, $46, $4b, $44, $62
    db $46, $50, $ef, $ee, $54, $4f, $46, $51, $51, $42, $4b, $62, $4c, $4b, $62, $46
    db $51, $62, $46, $4b, $fa, $f7, $ef, $ee, $51, $46, $4b, $56, $62, $40, $52, $51
    db $42, $62, $49, $42, $51, $51, $42, $4f, $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $a3, $33, $4f, $4c, $4d, $42, $4f, $51, $56, $62, $4c, $43, $ef, $ee, $30, $46
    db $49, $3e, $56, $4c, $52, $f7, $f0
TextStr_42_42d0:           ; id $0003
    ; "Terry looked in front of him. / A flame sparkles and vanishes in / the air."
    db $37, $42, $4f, $4f, $56, $62, $49, $4c, $4c, $48, $42, $41, $ef, $ee, $46, $4b
    db $62, $43, $4f, $4c, $4b, $51, $62, $4c, $43, $62, $45, $46, $4a, $5f, $fa, $f7
    db $ef, $ee, $24, $62, $43, $49, $3e, $4a, $42, $62, $50, $4d, $3e, $4f, $48, $49
    db $42, $50, $ef, $ee, $3e, $4b, $41, $62, $53, $3e, $4b, $46, $50, $45, $42, $50
    db $62, $46, $4b, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $3e, $46, $4f, $5f, $ef
    db $ee, $f7, $f0
TextStr_42_4323:           ; id $0004
    ; "Terry looked at the bookshelf. / :A Fairy Tale / :Once upon a time there was a / little boy and a little girl in a / village..."
    db $37, $42, $4f, $4f, $56, $62, $49, $4c, $4c, $48, $42, $41, $62, $3e, $51, $ef
    db $ee, $51, $45, $42, $62, $3f, $4c, $4c, $48, $50, $45, $42, $49, $43, $5f, $fa
    db $f7, $ef, $ee, $a3, $24, $62, $29, $3e, $46, $4f, $56, $62, $37, $3e, $49, $42
    db $ef, $ee, $fa, $f7, $ef, $ee, $f3, $a3, $32, $4b, $40, $42, $62, $52, $4d, $4c
    db $4b, $62, $3e, $62, $51, $46, $4a, $42, $ef, $ee, $51, $45, $42, $4f, $42, $62
    db $54, $3e, $50, $62, $3e, $fa, $f7, $ef, $ee, $49, $46, $51, $51, $49, $42, $62
    db $3f, $4c, $56, $62, $3e, $4b, $41, $62, $3e, $ef, $ee, $49, $46, $51, $51, $49
    db $42, $62, $44, $46, $4f, $49, $62, $46, $4b, $62, $3e, $fa, $f7, $ef, $ee, $53
    db $46, $49, $49, $3e, $44, $42, $5f, $5f, $5f, $ef, $ee, $f7, $f0
TextStr_42_43b0:           ; id $0005
    ; "Terry looked at the bookshelf. / :Diary of Milayou / :Home alone with my brother. Hope / no horrible monsters come out."
    db $37, $42, $4f, $4f, $56, $62, $49, $4c, $4c, $48, $42, $41, $62, $3e, $51, $ef
    db $ee, $51, $45, $42, $62, $3f, $4c, $4c, $48, $50, $45, $42, $49, $43, $5f, $fa
    db $f7, $ef, $ee, $a3, $27, $46, $3e, $4f, $56, $62, $4c, $43, $62, $30, $46, $49
    db $3e, $56, $4c, $52, $ef, $ee, $fa, $f7, $ef, $ee, $a3, $2b, $4c, $4a, $42, $62
    db $3e, $49, $4c, $4b, $42, $62, $54, $46, $51, $45, $ef, $ee, $4a, $56, $62, $3f
    db $4f, $4c, $51, $45, $42, $4f, $5f, $62, $2b, $4c, $4d, $42, $fa, $f7, $ef, $ee
    db $4b, $4c, $62, $45, $4c, $4f, $4f, $46, $3f, $49, $42, $ef, $ee, $4a, $4c, $4b
    db $50, $51, $42, $4f, $50, $62, $40, $4c, $4a, $42, $62, $4c, $52, $51, $5f, $f7
    db $f0
TextStr_42_4431:           ; id $0006
    ; "[SOUND 60]Terry looked in the dresser. / It's filled with his clothes."
    db $e9, $60, $37, $42, $4f, $4f, $56, $62, $49, $4c, $4c, $48, $42, $41, $62, $46
    db $4b, $ef, $ee, $51, $45, $42, $62, $41, $4f, $42, $50, $50, $42, $4f, $5f, $fa
    db $f7, $ef, $ee, $2c, $51, $68, $62, $43, $46, $49, $49, $42, $41, $62, $54, $46
    db $51, $45, $ef, $ee, $45, $46, $50, $62, $40, $49, $4c, $51, $45, $42, $50, $5f
    db $f7, $f0
TextStr_42_4473:           ; id $0007
    ; "[SOUND 60]Terry looked in the dresser. / It's filled with Milayou's clothes."
    db $e9, $60, $37, $42, $4f, $4f, $56, $62, $49, $4c, $4c, $48, $42, $41, $62, $46
    db $4b, $ef, $ee, $51, $45, $42, $62, $41, $4f, $42, $50, $50, $42, $4f, $5f, $fa
    db $f7, $ef, $ee, $2c, $51, $68, $62, $43, $46, $49, $49, $42, $41, $62, $54, $46
    db $51, $45, $ef, $ee, $30, $46, $49, $3e, $56, $4c, $52, $68, $62, $40, $49, $4c
    db $51, $45, $42, $50, $5f, $f7, $f0
TextStr_42_44ba:           ; id $0008
    ; "*:Are you Milayou? / *:Hm, You don't look like her. / Milayou's a girl. / *:Your name is Terry? You're / not the one. / *:I'm Warubou from t..."
    db $ea, $9f, $a3, $24, $4f, $42, $62, $56, $4c, $52, $62, $30, $46, $49, $3e, $56
    db $4c, $52, $64, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $4a, $5e, $62, $3c
    db $4c, $52, $62, $41, $4c, $4b, $67, $ef, $ee, $49, $4c, $4c, $48, $62, $49, $46
    db $48, $42, $62, $45, $42, $4f, $5f, $fa, $f7, $ef, $ee, $30, $46, $49, $3e, $56
    db $4c, $52, $68, $62, $3e, $62, $44, $46, $4f, $49, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $3c, $4c, $52, $4f, $62, $4b, $3e, $4a, $42, $62, $46, $50, $ef
    db $ee, $37, $42, $4f, $4f, $56, $64, $62, $3c, $4c, $52, $69, $42, $fa, $f7, $ef
    db $ee, $4b, $4c, $51, $62, $51, $45, $42, $62, $4c, $4b, $42, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $2c, $6a, $62, $3a, $3e, $4f, $52, $3f, $4c, $52, $ef
    db $ee, $43, $4f, $4c, $4a, $62, $51, $45, $42, $62, $2e, $46, $4b, $44, $41, $4c
    db $4a, $fa, $f7, $ef, $ee, $4c, $43, $62, $2a, $4f, $42, $3e, $51, $2f, $4c, $44
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $3a, $3e, $4f, $52, $3f, $4c, $52, $a3, $27
    db $4c, $4b, $67, $ef, $ee, $56, $4c, $52, $62, $43, $4c, $4f, $44, $42, $51, $62
    db $46, $51, $63, $63, $f7, $f0
TextStr_42_4590:           ; id $0009
    ; "*:Huh? What happened? / Where is Milayou?"
    db $eb, $9f, $a3, $2b, $52, $45, $64, $62, $ef, $ee, $3a, $45, $3e, $51, $62, $45
    db $3e, $4d, $4d, $42, $4b, $42, $41, $64, $fa, $f7, $ef, $ee, $3a, $45, $42, $4f
    db $42, $62, $46, $50, $62, $30, $46, $49, $3e, $56, $4c, $52, $64, $ef, $ee, $f7
    db $f0
TextStr_42_45c1:           ; id $000A
    ; "*:You speak monster talk / don't you? / *:Where is Milayou? / *:Taken away!? Oh no, I was too / late! / *:Warubou? I'm not Warubou. / I am W..."
    db $eb, $9f, $a3, $3c, $4c, $52, $62, $50, $4d, $42, $3e, $48, $ef, $ee, $4a, $4c
    db $4b, $50, $51, $42, $4f, $62, $51, $3e, $49, $48, $fa, $f7, $ef, $ee, $41, $4c
    db $4b, $67, $62, $56, $4c, $52, $64, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3a
    db $45, $42, $4f, $42, $62, $46, $50, $ef, $ee, $30, $46, $49, $3e, $56, $4c, $52
    db $64, $fa, $f7, $ef, $ee, $9f, $a3, $37, $3e, $48, $42, $4b, $62, $3e, $54, $3e
    db $56, $63, $64, $ef, $ee, $32, $45, $62, $4b, $4c, $5e, $62, $2c, $62, $54, $3e
    db $50, $62, $51, $4c, $4c, $fa, $f7, $ef, $ee, $49, $3e, $51, $42, $63, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $3a, $3e, $4f, $52, $3f, $4c, $52, $64, $62, $2c
    db $6a, $ef, $ee, $4b, $4c, $51, $62, $3a, $3e, $4f, $52, $3f, $4c, $52, $5f, $fa
    db $f7, $ef, $ee, $2c, $62, $3e, $4a, $62, $3a, $3e, $51, $3e, $3f, $4c, $52, $63
    db $ef, $ee, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $3a, $45
    db $3e, $51, $64, $ef, $ee, $3c, $4c, $52, $62, $54, $3e, $4b, $4b, $3e, $62, $48
    db $4b, $4c, $54, $fa, $f7, $ef, $ee, $54, $45, $42, $4f, $42, $62, $56, $4c, $52
    db $4f, $62, $50, $46, $50, $51, $42, $4f, $ef, $ee, $46, $50, $64, $fa, $f7, $ef
    db $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $3a, $42, $49, $49, $5e, $ef, $ee
    db $43, $4c, $49, $49, $4c, $54, $62, $4a, $42, $5f, $62, $30, $3e, $56, $3f, $42
    db $fa, $f7, $ef, $ee, $56, $4c, $52, $62, $40, $3e, $4b, $62, $43, $46, $4b, $41
    db $62, $45, $42, $4f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f
    db $4c, $52, $a3, $2c, $62, $45, $4c, $4d, $42, $ef, $ee, $56, $4c, $52, $69, $42
    db $62, $3e, $62, $50, $48, $46, $49, $49, $42, $41, $fa, $f7, $ef, $ee, $4a, $3e
    db $50, $51, $42, $4f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f
    db $4c, $52, $a3, $3c, $4c, $52, $ef, $ee, $41, $4c, $4b, $67, $62, $52, $4b, $41
    db $42, $4f, $50, $51, $3e, $4b, $41, $fa, $f7, $ef, $ee, $54, $45, $3e, $51, $62
    db $2c, $6a, $62, $51, $3e, $49, $48, $46, $4b, $44, $ef, $ee, $3e, $3f, $4c, $52
    db $51, $64, $fa, $f7, $ef, $ee, $3c, $4c, $52, $66, $49, $62, $43, $46, $4b, $41
    db $62, $4c, $52, $51, $62, $46, $43, $ef, $ee, $56, $4c, $52, $62, $43, $4c, $49
    db $49, $4c, $54, $62, $4a, $42, $5f, $f7, $f0
TextStr_42_476a:           ; id $000B
    ; "Terry looks at the bookshelf. / :Encyclopedia of Monsters / Author..Unknown.."
    db $37, $42, $4f, $4f, $56, $62, $49, $4c, $4c, $48, $50, $62, $3e, $51, $ef, $ee
    db $51, $45, $42, $62, $3f, $4c, $4c, $48, $50, $45, $42, $49, $43, $5f, $fa, $f7
    db $ef, $ee, $a3, $28, $4b, $40, $56, $40, $49, $4c, $4d, $42, $41, $46, $3e, $ef
    db $ee, $4c, $43, $62, $30, $4c, $4b, $50, $51, $42, $4f, $50, $fa, $f7, $ef, $ee
    db $24, $52, $51, $45, $4c, $4f, $5f, $5f, $38, $4b, $48, $4b, $4c, $54, $4b, $5f
    db $5f, $ef, $ee, $f7, $f0
TextStr_42_47bf:           ; id $000C
    ; "Terry looked at the bookshelf. / Too difficult to read!"
    db $37, $42, $4f, $4f, $56, $62, $49, $4c, $4c, $48, $42, $41, $62, $3e, $51, $ef
    db $ee, $51, $45, $42, $62, $3f, $4c, $4c, $48, $50, $45, $42, $49, $43, $5f, $fa
    db $f7, $ef, $ee, $37, $4c, $4c, $62, $41, $46, $43, $43, $46, $40, $52, $49, $51
    db $ef, $ee, $51, $4c, $62, $4f, $42, $3e, $41, $63, $f7, $f0
TextStr_42_47fb:           ; id $000D
    ; "Terry looked in front of him. / The clock reads midnight..."
    db $37, $42, $4f, $4f, $56, $62, $49, $4c, $4c, $48, $42, $41, $62, $46, $4b, $ef
    db $ee, $43, $4f, $4c, $4b, $51, $62, $4c, $43, $62, $45, $46, $4a, $5f, $fa, $f7
    db $ef, $ee, $37, $45, $42, $62, $40, $49, $4c, $40, $48, $62, $4f, $42, $3e, $41
    db $50, $ef, $ee, $4a, $46, $41, $4b, $46, $44, $45, $51, $5f, $5f, $5f, $f7, $f0
TextStr_42_483b:           ; id $000E
    ; "Terry looked at a stuffed animal. / Something is written on it in / tiny cute letters. / :Property of Milayou"
    db $37, $42, $4f, $4f, $56, $62, $49, $4c, $4c, $48, $42, $41, $62, $3e, $51, $ef
    db $ee, $3e, $62, $50, $51, $52, $43, $43, $42, $41, $62, $3e, $4b, $46, $4a, $3e
    db $49, $5f, $fa, $f7, $ef, $ee, $36, $4c, $4a, $42, $51, $45, $46, $4b, $44, $62
    db $46, $50, $ef, $ee, $54, $4f, $46, $51, $51, $42, $4b, $62, $4c, $4b, $62, $46
    db $51, $62, $46, $4b, $fa, $f7, $ef, $ee, $51, $46, $4b, $56, $62, $40, $52, $51
    db $42, $62, $49, $42, $51, $51, $42, $4f, $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $a3, $33, $4f, $4c, $4d, $42, $4f, $51, $56, $62, $4c, $43, $ef, $ee, $30, $46
    db $49, $3e, $56, $4c, $52, $f7, $f0
TextStr_42_48b2:           ; id $000F
    ; "*:Oh, you must be the master. / You must have had a long trip here. / *:What? You don't know where you / are? You're in the Kingdom of / Gre..."
    db $ea, $9f, $a3, $32, $45, $5e, $62, $56, $4c, $52, $62, $4a, $52, $50, $51, $62
    db $3f, $42, $ef, $ee, $51, $45, $42, $62, $4a, $3e, $50, $51, $42, $4f, $5f, $fa
    db $f7, $ef, $ee, $3c, $4c, $52, $62, $4a, $52, $50, $51, $62, $45, $3e, $53, $42
    db $62, $45, $3e, $41, $ef, $ee, $3e, $62, $49, $4c, $4b, $44, $62, $51, $4f, $46
    db $4d, $62, $45, $42, $4f, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45, $3e
    db $51, $64, $62, $3c, $4c, $52, $62, $41, $4c, $4b, $67, $ef, $ee, $48, $4b, $4c
    db $54, $62, $54, $45, $42, $4f, $42, $62, $56, $4c, $52, $62, $fa, $f7, $ef, $ee
    db $3e, $4f, $42, $64, $62, $3c, $4c, $52, $69, $42, $62, $46, $4b, $62, $ef, $ee
    db $51, $45, $42, $62, $2e, $46, $4b, $44, $41, $4c, $4a, $62, $4c, $43, $62, $fa
    db $f7, $ef, $ee, $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $3a, $3e, $51, $3e, $3f, $4c, $52, $ef, $ee, $3f, $4f
    db $4c, $52, $44, $45, $51, $62, $56, $4c, $52, $62, $45, $42, $4f, $42, $5f, $fa
    db $f7, $ef, $ee, $9f, $a3, $2f, $42, $51, $68, $62, $44, $42, $51, $62, $44, $4c
    db $46, $4b, $44, $5f, $ef, $ee, $3a, $42, $62, $45, $3e, $53, $42, $62, $51, $4c
    db $62, $53, $46, $50, $46, $51, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $40, $3e
    db $50, $51, $49, $42, $62, $51, $4c, $62, $4d, $3e, $56, $ef, $ee, $4c, $52, $4f
    db $62, $4f, $42, $50, $4d, $42, $40, $51, $50, $62, $51, $4c, $fa, $f7, $ef, $ee
    db $51, $45, $42, $62, $2e, $46, $4b, $44, $5f, $ef, $ee, $f7, $f0
TextStr_42_49cf:           ; id $0010
    ; "*:This kingdom is created inside / a big tree. / *:We are at the bottom. / The castle is at the top."
    db $ea, $9f, $a3, $37, $45, $46, $50, $62, $48, $46, $4b, $44, $41, $4c, $4a, $62
    db $46, $50, $ef, $ee, $40, $4f, $42, $3e, $51, $42, $41, $62, $46, $4b, $50, $46
    db $41, $42, $fa, $f7, $ef, $ee, $3e, $62, $3f, $46, $44, $62, $51, $4f, $42, $42
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $42, $62, $3e, $4f, $42, $62
    db $3e, $51, $62, $51, $45, $42, $ef, $ee, $3f, $4c, $51, $51, $4c, $4a, $5f, $fa
    db $f7, $ef, $ee, $37, $45, $42, $62, $40, $3e, $50, $51, $49, $42, $62, $46, $50
    db $ef, $ee, $3e, $51, $62, $51, $45, $42, $62, $51, $4c, $4d, $5f, $f7, $f0
TextStr_42_4a3e:           ; id $0011
    ; "*:Hey, is he the new master / Watabou brought here?"
    db $ea, $9f, $a3, $2b, $42, $56, $5e, $62, $46, $50, $62, $45, $42, $62, $51, $45
    db $42, $ef, $ee, $4b, $42, $54, $62, $4a, $3e, $50, $51, $42, $4f, $fa, $f7, $ef
    db $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $62, $3f, $4f, $4c, $52, $44, $45, $51
    db $ef, $ee, $45, $42, $4f, $42, $64, $f7, $f0
TextStr_42_4a77:           ; id $0012
    ; "*:Yes indeed, I'm taking him to see / the King."
    db $ea, $9f, $a3, $3c, $42, $50, $62, $46, $4b, $41, $42, $42, $41, $5e, $62, $2c
    db $6a, $ef, $ee, $51, $3e, $48, $46, $4b, $44, $62, $45, $46, $4a, $62, $51, $4c
    db $62, $50, $42, $42, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $2e, $46, $4b, $44
    db $5f, $ef, $ee, $f7, $f0
TextStr_42_4aac:           ; id $0013
    ; "*:Good luck at the Starry Night / Tournament!"
    db $ea, $9f, $a3, $2a, $4c, $4c, $41, $62, $49, $52, $40, $48, $62, $3e, $51, $ef
    db $ee, $51, $45, $42, $62, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45
    db $51, $fa, $f7, $ef, $ee, $37, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $63
    db $ef, $ee, $f7, $f0
TextStr_42_4ae0:           ; id $0014
    ; "*:Now it's time to go see the King."
    db $ea, $9f, $a3, $31, $4c, $54, $62, $46, $51, $68, $62, $51, $46, $4a, $42, $62
    db $51, $4c, $ef, $ee, $44, $4c, $62, $50, $42, $42, $62, $51, $45, $42, $62, $2e
    db $46, $4b, $44, $5f, $f7, $f0
TextStr_42_4b06:           ; id $0015
    ; "*:I'm the minister of this kingdom. / Are you the new master? / *:His Majesty has a favor to ask / you. / Please comply with his request!"
    db $ea, $9f, $a3, $2c, $6a, $62, $51, $45, $42, $62, $4a, $46, $4b, $46, $50, $51
    db $42, $4f, $ef, $ee, $4c, $43, $62, $51, $45, $46, $50, $62, $48, $46, $4b, $44
    db $41, $4c, $4a, $5f, $fa, $f7, $ef, $ee, $24, $4f, $42, $62, $56, $4c, $52, $62
    db $51, $45, $42, $62, $4b, $42, $54, $ef, $ee, $4a, $3e, $50, $51, $42, $4f, $64
    db $fa, $f7, $ef, $ee, $9f, $a3, $2b, $46, $50, $62, $30, $3e, $47, $42, $50, $51
    db $56, $62, $45, $3e, $50, $ef, $ee, $3e, $62, $43, $3e, $53, $4c, $4f, $62, $51
    db $4c, $62, $3e, $50, $48, $62, $fa, $f7, $ef, $ee, $56, $4c, $52, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $33, $49, $42, $3e, $50, $42, $62, $40, $4c, $4a, $4d, $49
    db $56, $62, $54, $46, $51, $45, $ef, $ee, $45, $46, $50, $62, $4f, $42, $4e, $52
    db $42, $50, $51, $63, $f7, $f0
TextStr_42_4b9c:           ; id $0016
    ; "*:His Majesty is in trouble. / Please provide us aid."
    db $ea, $9f, $a3, $2b, $46, $50, $62, $30, $3e, $47, $42, $50, $51, $56, $62, $46
    db $50, $ef, $ee, $46, $4b, $62, $51, $4f, $4c, $52, $3f, $49, $42, $5f, $fa, $f7
    db $ef, $ee, $33, $49, $42, $3e, $50, $42, $62, $4d, $4f, $4c, $53, $46, $41, $42
    db $ef, $ee, $52, $50, $62, $3e, $46, $41, $5f, $f7, $f0
TextStr_42_4bd7:           ; id $0017
    ; "*:Please listen to his wish."
    db $ea, $9f, $a3, $33, $49, $42, $3e, $50, $42, $62, $49, $46, $50, $51, $42, $4b
    db $62, $51, $4c, $ef, $ee, $45, $46, $50, $62, $54, $46, $50, $45, $5f, $f7, $f0
TextStr_42_4bf7:           ; id $0018
    ; "*:This is the castle of / GreatTree."
    db $ea, $9f, $a3, $37, $45, $46, $50, $62, $46, $50, $62, $51, $45, $42, $ef, $ee
    db $40, $3e, $50, $51, $49, $42, $62, $4c, $43, $fa, $f7, $ef, $ee, $2a, $4f, $42
    db $3e, $51, $37, $4f, $42, $42, $5f, $ef, $ee, $f7, $f0
TextStr_42_4c22:           ; id $0019
    ; "*:Hurry! Go see the King!"
    db $ea, $9f, $a3, $2b, $52, $4f, $4f, $56, $63, $62, $2a, $4c, $ef, $ee, $50, $42
    db $42, $62, $51, $45, $42, $62, $2e, $46, $4b, $44, $63, $f7, $f0
TextStr_42_4c3f:           ; id $001A
    ; "*:I see....."
    db $eb, $9f, $a3, $2c, $62, $50, $42, $42, $5f, $5f, $5f, $5f, $5f, $ef, $ee, $f7
    db $f0
TextStr_42_4c50:           ; id $001B
    ; "[HERO] opened a treasure chest!"
    db $f6, $62, $4c, $4d, $42, $4b, $42, $41, $62, $3e, $ef, $ee, $51, $4f, $42, $3e
    db $50, $52, $4f, $42, $62, $40, $45, $42, $50, $51, $63, $fa, $f7, $f0
TextStr_42_4c6e:           ; id $001C
    ; "[HERO] picked up an Herb."
    db $f6, $62, $4d, $46, $40, $48, $42, $41, $62, $52, $4d, $ef, $ee, $3e, $4b, $62
    db $2b, $42, $4f, $3f, $5f, $f7, $f0
TextStr_42_4c85:           ; id $001D
    ; "[HERO] found an Herb. / But cannot carry anymore. / [HERO] returned the Herb to the / treasure chest."
    db $f6, $62, $43, $4c, $52, $4b, $41, $ef, $ee, $3e, $4b, $62, $2b, $42, $4f, $3f
    db $5f, $fa, $f7, $ef, $ee, $25, $52, $51, $62, $40, $3e, $4b, $4b, $4c, $51, $62
    db $40, $3e, $4f, $4f, $56, $ef, $ee, $3e, $4b, $56, $4a, $4c, $4f, $42, $5f, $fa
    db $f7, $ef, $ee, $f6, $62, $4f, $42, $51, $52, $4f, $4b, $42, $41, $ef, $ee, $51
    db $45, $42, $62, $2b, $42, $4f, $3f, $62, $51, $4c, $62, $51, $45, $42, $fa, $f7
    db $ef, $ee, $51, $4f, $42, $3e, $50, $52, $4f, $42, $62, $40, $45, $42, $50, $51
    db $5f, $ef, $ee, $f7, $f0
TextStr_42_4cea:           ; id $001E
    ; "[HERO] opened a treasure chest!"
    db $f6, $62, $4c, $4d, $42, $4b, $42, $41, $62, $3e, $ef, $ee, $51, $4f, $42, $3e
    db $50, $52, $4f, $42, $62, $40, $45, $42, $50, $51, $63, $fa, $f7, $f0
TextStr_42_4d08:           ; id $001F
    ; "*:This is the Kingdom of / GreatTree!"
    db $ea, $9f, $a3, $37, $45, $46, $50, $62, $46, $50, $62, $51, $45, $42, $ef, $ee
    db $2e, $46, $4b, $44, $41, $4c, $4a, $62, $4c, $43, $fa, $f7, $ef, $ee, $2a, $4f
    db $42, $3e, $51, $37, $4f, $42, $42, $63, $ef, $ee, $f7, $f0
TextStr_42_4d34:           ; id $0020
    ; "*:Welcome! I am the King of this / kingdom. / King:Identify yourself, / my child."
    db $ea, $9f, $a3, $3a, $42, $49, $40, $4c, $4a, $42, $63, $62, $2c, $62, $3e, $4a
    db $ef, $ee, $51, $45, $42, $62, $2e, $46, $4b, $44, $62, $4c, $43, $62, $51, $45
    db $46, $50, $fa, $f7, $ef, $ee, $48, $46, $4b, $44, $41, $4c, $4a, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $2c, $41, $42, $4b, $51, $46, $43
    db $56, $ef, $ee, $56, $4c, $52, $4f, $50, $42, $49, $43, $5e, $fa, $f7, $ef, $ee
    db $4a, $56, $62, $40, $45, $46, $49, $41, $5f, $ef, $ee, $f7, $f0
TextStr_42_4d91:           ; id $0021
    ; "King:Oh [HERO]! Will you comply / with my wish? / King:My wish is nothing but... / King:For you to participate and / win the tournament of t..."
    db $ea, $2e, $46, $4b, $44, $a3, $32, $45, $62, $f6, $63, $ef, $ee, $3a, $46, $49
    db $49, $62, $56, $4c, $52, $62, $40, $4c, $4a, $4d, $49, $56, $fa, $f7, $ef, $ee
    db $54, $46, $51, $45, $62, $4a, $56, $62, $54, $46, $50, $45, $64, $ef, $ee, $fa
    db $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $30, $56, $62, $54, $46, $50, $45, $62
    db $46, $50, $ef, $ee, $4b, $4c, $51, $45, $46, $4b, $44, $62, $3f, $52, $51, $5f
    db $5f, $5f, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $29, $4c, $4f, $62, $56
    db $4c, $52, $62, $51, $4c, $ef, $ee, $4d, $3e, $4f, $51, $46, $40, $46, $4d, $3e
    db $51, $42, $62, $3e, $4b, $41, $fa, $f7, $ef, $ee, $54, $46, $4b, $62, $51, $45
    db $42, $62, $51, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $ef, $ee, $4c, $43
    db $62, $51, $45, $42, $62, $36, $51, $3e, $4f, $4f, $56, $fa, $f7, $ef, $ee, $31
    db $46, $44, $45, $51, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3
    db $3a, $45, $3e, $51, $64, $62, $3c, $4c, $52, $ef, $ee, $50, $3e, $56, $62, $56
    db $4c, $52, $62, $54, $4c, $52, $49, $41, $fa, $f7, $ef, $ee, $4f, $3e, $51, $45
    db $42, $4f, $62, $43, $46, $4b, $41, $62, $56, $4c, $52, $4f, $ef, $ee, $48, $46
    db $41, $4b, $3e, $4d, $4d, $42, $41, $62, $50, $46, $50, $51, $42, $4f, $64, $fa
    db $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $27, $46, $41, $4b, $67, $62, $56, $4c
    db $52, $ef, $ee, $40, $4c, $4a, $42, $62, $45, $42, $4f, $42, $62, $51, $4c, $fa
    db $f7, $ef, $ee, $40, $4c, $4a, $4d, $49, $56, $62, $54, $46, $51, $45, $ef, $ee
    db $4a, $56, $62, $4f, $42, $4e, $52, $42, $50, $51, $64, $fa, $f7, $ef, $ee, $2e
    db $46, $4b, $44, $a3, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $2b, $4a, $ef, $ee
    db $5f, $5f, $5f, $5f, $5f, $5f, $2b, $4a, $4a, $4a, $4a, $4a, $5f, $fa, $f7, $ef
    db $ee, $2e, $46, $4b, $44, $a3, $5f, $5f, $5f, $63, $62, $2b, $4c, $54, $42, $53
    db $42, $4f, $5e, $ef, $ee, $51, $45, $42, $4f, $42, $62, $46, $50, $62, $3e, $4b
    db $fa, $f7, $ef, $ee, $42, $3e, $50, $46, $42, $4f, $62, $54, $3e, $56, $62, $51
    db $45, $3e, $4b, $ef, $ee, $50, $42, $3e, $4f, $40, $45, $46, $4b, $44, $62, $43
    db $4c, $4f, $fa, $f7, $ef, $ee, $45, $42, $4f, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $2e, $46, $4b, $44, $a3, $3a, $46, $4b, $62, $51, $45, $42, $ef, $ee, $51, $4c
    db $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $62, $4c, $43, $62, $51, $45, $42, $fa
    db $f7, $ef, $ee, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45, $51, $63
    db $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $2f, $42, $44, $42, $4b
    db $41, $62, $45, $3e, $50, $62, $46, $51, $ef, $ee, $51, $45, $3e, $51, $62, $51
    db $45, $42, $62, $4c, $4b, $42, $62, $54, $45, $4c, $fa, $f7, $ef, $ee, $46, $50
    db $62, $53, $46, $40, $51, $4c, $4f, $46, $4c, $52, $50, $62, $46, $4b, $ef, $ee
    db $51, $45, $42, $62, $51, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $62, $4c
    db $43, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $36, $51, $3e, $4f, $4f, $56, $62
    db $31, $46, $44, $45, $51, $ef, $ee, $54, $46, $49, $49, $62, $3f, $42, $62, $44
    db $4f, $3e, $4b, $51, $42, $41, $fa, $f7, $ef, $ee, $3e, $62, $54, $46, $50, $45
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $3c, $4c, $52, $4f
    db $62, $54, $46, $50, $45, $62, $51, $4c, $ef, $ee, $43, $46, $4b, $41, $62, $56
    db $4c, $52, $4f, $62, $50, $46, $50, $51, $42, $4f, $fa, $f7, $ef, $ee, $54, $46
    db $49, $49, $62, $3f, $42, $62, $44, $4f, $3e, $4b, $51, $42, $41, $63, $ef, $ee
    db $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $37, $45, $3e, $51, $62, $54, $3e
    db $56, $62, $54, $42, $ef, $ee, $3f, $4c, $51, $45, $62, $54, $46, $4b, $5f, $5f
    db $5f, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $30, $42, $3e, $4b, $54, $45
    db $46, $49, $42, $5e, $ef, $ee, $50, $42, $3e, $4f, $40, $45, $62, $43, $4c, $4f
    db $62, $56, $4c, $52, $4f, $fa, $f7, $ef, $ee, $50, $46, $50, $51, $42, $4f, $62
    db $54, $45, $46, $49, $42, $62, $56, $4c, $52, $ef, $ee, $4d, $4f, $42, $4d, $3e
    db $4f, $42, $62, $43, $4c, $4f, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $51, $4c
    db $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $63, $ef, $ee, $fa, $f7, $ef, $ee, $2e
    db $46, $4b, $44, $a3, $2b, $42, $4f, $42, $5e, $62, $2c, $62, $50, $45, $3e, $49
    db $49, $ef, $ee, $44, $46, $53, $42, $62, $56, $4c, $52, $62, $50, $4c, $4a, $42
    db $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $3a, $46, $51, $45, $4c, $52, $51, $62
    db $3e, $4b, $56, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5e, $62, $56
    db $4c, $52, $fa, $f7, $ef, $ee, $40, $3e, $4b, $4b, $4c, $51, $62, $50, $42, $4f
    db $53, $42, $ef, $ee, $3e, $50, $62, $3e, $62, $4a, $3e, $50, $51, $42, $4f, $63
    db $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $37, $45, $42, $62, $4a, $4c, $4b
    db $50, $51, $42, $4f, $ef, $ee, $43, $3e, $4f, $4a, $62, $46, $50, $62, $4c, $4b
    db $62, $51, $45, $42, $fa, $f7, $ef, $ee, $52, $4d, $4d, $42, $4f, $62, $49, $42
    db $53, $42, $49, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $2a
    db $4c, $62, $3e, $4b, $41, $62, $3e, $50, $48, $ef, $ee, $33, $52, $49, $46, $4c
    db $62, $43, $4c, $4f, $62, $56, $4c, $52, $4f, $fa, $f7, $ef, $ee, $4a, $4c, $4b
    db $50, $51, $42, $4f, $50, $5f, $ef, $ee, $f7, $f0
TextStr_42_517b:           ; id $0022
    ; "*:Everybody will be happy if you / become the champion of the / Starry Night Tournament."
    db $eb, $9f, $a3, $28, $53, $42, $4f, $56, $3f, $4c, $41, $56, $62, $54, $46, $49
    db $49, $ef, $ee, $3f, $42, $62, $45, $3e, $4d, $4d, $56, $62, $46, $43, $62, $56
    db $4c, $52, $fa, $f7, $ef, $ee, $3f, $42, $40, $4c, $4a, $42, $62, $51, $45, $42
    db $ef, $ee, $40, $45, $3e, $4a, $4d, $46, $4c, $4b, $62, $4c, $43, $62, $51, $45
    db $42, $fa, $f7, $ef, $ee, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45
    db $51, $ef, $ee, $37, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $5f, $f7, $f0
TextStr_42_51db:           ; id $0023
    ; "*:I have a feeling that your / victory will help you find your / sister."
    db $eb, $9f, $a3, $2c, $62, $45, $3e, $53, $42, $62, $3e, $ef, $ee, $43, $42, $42
    db $49, $46, $4b, $44, $62, $51, $45, $3e, $51, $62, $56, $4c, $52, $4f, $fa, $f7
    db $ef, $ee, $53, $46, $40, $51, $4c, $4f, $56, $62, $54, $46, $49, $49, $62, $45
    db $42, $49, $4d, $ef, $ee, $56, $4c, $52, $62, $43, $46, $4b, $41, $62, $56, $4c
    db $52, $4f, $fa, $f7, $ef, $ee, $50, $46, $50, $51, $42, $4f, $5f, $ef, $ee, $f7
    db $f0
TextStr_42_522c:           ; id $0024
    ; "[HERO] looked at the bookshelf. / :The Kingdom of GreatTree... / Want to read the book? [YES/NO]"
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $3e, $51, $ef, $ee, $51, $45, $42
    db $62, $3f, $4c, $4c, $48, $50, $45, $42, $49, $43, $5f, $fa, $f7, $ef, $ee, $a3
    db $37, $45, $42, $62, $2e, $46, $4b, $44, $41, $4c, $4a, $62, $4c, $43, $ef, $ee
    db $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $5f, $5f, $5f, $fa, $f7, $ef, $ee
    db $3a, $3e, $4b, $51, $62, $51, $4c, $62, $4f, $42, $3e, $41, $62, $51, $45, $42
    db $ef, $ee, $3f, $4c, $4c, $48, $64, $ff, $f0
TextStr_42_5285:           ; id $0025
    ; ":It's a little kingdom built / inside a big tree. / :Other kingdoms are also built / in big trees. / :All the kingdoms have something / call..."
    db $a3, $2c, $51, $68, $62, $3e, $62, $49, $46, $51, $51, $49, $42, $ef, $ee, $48
    db $46, $4b, $44, $41, $4c, $4a, $62, $3f, $52, $46, $49, $51, $fa, $f7, $ef, $ee
    db $46, $4b, $50, $46, $41, $42, $62, $3e, $62, $3f, $46, $44, $62, $51, $4f, $42
    db $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $a3, $32, $51, $45, $42, $4f, $62, $48
    db $46, $4b, $44, $41, $4c, $4a, $50, $ef, $ee, $3e, $4f, $42, $62, $3e, $49, $50
    db $4c, $62, $3f, $52, $46, $49, $51, $fa, $f7, $ef, $ee, $46, $4b, $62, $3f, $46
    db $44, $62, $51, $4f, $42, $42, $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $a3, $24
    db $49, $49, $62, $51, $45, $42, $62, $48, $46, $4b, $44, $41, $4c, $4a, $50, $ef
    db $ee, $45, $3e, $53, $42, $62, $50, $4c, $4a, $42, $51, $45, $46, $4b, $44, $fa
    db $f7, $ef, $ee, $40, $3e, $49, $49, $42, $41, $62, $37, $4f, $3e, $53, $42, $49
    db $42, $4f, $50, $5c, $ef, $ee, $2a, $3e, $51, $42, $50, $5f, $fa, $f7, $ef, $ee
    db $a3, $25, $42, $56, $4c, $4b, $41, $62, $51, $45, $42, $62, $2a, $3e, $51, $42
    db $50, $ef, $ee, $3e, $4f, $42, $62, $51, $45, $42, $62, $4a, $56, $50, $51, $46
    db $40, $fa, $f7, $ef, $ee, $54, $4c, $4f, $49, $41, $50, $62, $54, $45, $42, $4f
    db $42, $62, $51, $45, $42, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62
    db $49, $46, $53, $42, $5f, $fa, $f7, $ef, $ee, $a3, $3a, $45, $42, $4b, $62, $51
    db $45, $42, $62, $36, $51, $3e, $4f, $4f, $56, $ef, $ee, $31, $46, $44, $45, $51
    db $62, $37, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $fa, $f7, $ef, $ee, $4b
    db $42, $3e, $4f, $50, $5e, $62, $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $ef
    db $ee, $51, $4f, $42, $4a, $3f, $49, $42, $50, $5f, $fa, $f7, $ef, $ee, $a3, $2c
    db $51, $68, $62, $3e, $62, $50, $46, $44, $4b, $ef, $ee, $51, $45, $3e, $51, $62
    db $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $62, $46, $50, $fa, $f7, $ef, $ee
    db $44, $4f, $4c, $54, $46, $4b, $44, $5f, $ef, $ee, $f7, $f0
TextStr_42_53f1:           ; id $0026
    ; "[HERO] returned the book to the / bookshelf."
    db $f6, $62, $4f, $42, $51, $52, $4f, $4b, $42, $41, $ef, $ee, $51, $45, $42, $62
    db $3f, $4c, $4c, $48, $62, $51, $4c, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $3f
    db $4c, $4c, $48, $50, $45, $42, $49, $43, $5f, $ef, $ee, $f7, $f0
TextStr_42_541e:           ; id $0027
    ; "[HERO] looked at the bookshelf. / The Master of Monsters... / Want to read the book? [YES/NO]"
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $3e, $51, $ef, $ee, $51, $45, $42
    db $62, $3f, $4c, $4c, $48, $50, $45, $42, $49, $43, $5f, $fa, $f7, $ef, $ee, $37
    db $45, $42, $62, $30, $3e, $50, $51, $42, $4f, $62, $4c, $43, $ef, $ee, $30, $4c
    db $4b, $50, $51, $42, $4f, $50, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $3a, $3e, $4b
    db $51, $62, $51, $4c, $62, $4f, $42, $3e, $41, $62, $51, $45, $42, $ef, $ee, $3f
    db $4c, $4c, $48, $64, $ff, $f0
TextStr_42_5474:           ; id $0028
    ; ":People who understand monster / talk and are able to tame them. / :There are few masters who / can understand and tame / monsters. / :It is..."
    db $a3, $33, $42, $4c, $4d, $49, $42, $62, $54, $45, $4c, $ef, $ee, $52, $4b, $41
    db $42, $4f, $50, $51, $3e, $4b, $41, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $fa
    db $f7, $ef, $ee, $51, $3e, $49, $48, $62, $3e, $4b, $41, $62, $3e, $4f, $42, $62
    db $3e, $3f, $49, $42, $ef, $ee, $51, $4c, $62, $51, $3e, $4a, $42, $62, $51, $45
    db $42, $4a, $5f, $fa, $f7, $ef, $ee, $a3, $37, $45, $42, $4f, $42, $62, $3e, $4f
    db $42, $ef, $ee, $43, $42, $54, $62, $4a, $3e, $50, $51, $42, $4f, $50, $62, $54
    db $45, $4c, $fa, $f7, $ef, $ee, $40, $3e, $4b, $62, $52, $4b, $41, $42, $4f, $50
    db $51, $3e, $4b, $41, $ef, $ee, $3e, $4b, $41, $62, $51, $3e, $4a, $42, $fa, $f7
    db $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $a3, $2c, $51, $62, $46, $50, $62, $46, $4a, $4d, $4c, $4f, $51, $3e, $4b
    db $51, $ef, $ee, $4b, $4c, $51, $62, $4c, $4b, $49, $56, $62, $51, $4c, $fa, $f7
    db $ef, $ee, $52, $4b, $41, $42, $4f, $50, $51, $3e, $4b, $41, $62, $51, $45, $42
    db $4a, $ef, $ee, $3f, $52, $51, $62, $3e, $49, $50, $4c, $62, $51, $4c, $62, $3f
    db $42, $fa, $f7, $ef, $ee, $49, $46, $48, $42, $41, $62, $3f, $56, $62, $51, $45
    db $42, $4a, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $a3, $37, $45, $42, $4f, $42, $62
    db $3e, $4f, $42, $62, $4a, $3e, $50, $51, $42, $4f, $50, $ef, $ee, $43, $4f, $4c
    db $4a, $62, $51, $45, $46, $50, $62, $54, $4c, $4f, $49, $41, $fa, $f7, $ef, $ee
    db $a3, $3e, $4b, $41, $62, $4a, $3e, $50, $51, $42, $4f, $50, $62, $54, $45, $4c
    db $ef, $ee, $3e, $4f, $42, $62, $3f, $4f, $4c, $52, $44, $45, $51, $62, $3f, $56
    db $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $62, $54, $45, $4c, $62
    db $46, $50, $ef, $ee, $51, $45, $42, $62, $50, $4d, $46, $4f, $46, $51, $62, $4c
    db $43, $fa, $f7, $ef, $ee, $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $5f, $ef
    db $ee, $f7, $f0
TextStr_42_55d7:           ; id $0029
    ; "*:I wanna be a master. / What should I do?"
    db $eb, $9f, $a3, $2c, $62, $54, $3e, $4b, $4b, $3e, $62, $3f, $42, $62, $3e, $ef
    db $ee, $4a, $3e, $50, $51, $42, $4f, $5f, $fa, $f7, $ef, $ee, $3a, $45, $3e, $51
    db $62, $50, $45, $4c, $52, $49, $41, $62, $2c, $62, $41, $4c, $64, $ef, $ee, $f7
    db $f0
TextStr_42_5608:           ; id $002A
    ; "King:The monster farm is on the / upper level. / King:Go and ask Pulio to give / you some monsters."
    db $ea, $2e, $46, $4b, $44, $a3, $37, $45, $42, $62, $4a, $4c, $4b, $50, $51, $42
    db $4f, $ef, $ee, $43, $3e, $4f, $4a, $62, $46, $50, $62, $4c, $4b, $62, $51, $45
    db $42, $fa, $f7, $ef, $ee, $52, $4d, $4d, $42, $4f, $62, $49, $42, $53, $42, $49
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $2a, $4c, $62, $3e
    db $4b, $41, $62, $3e, $50, $48, $ef, $ee, $33, $52, $49, $46, $4c, $62, $51, $4c
    db $62, $44, $46, $53, $42, $fa, $f7, $ef, $ee, $56, $4c, $52, $62, $50, $4c, $4a
    db $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f, $ef, $ee, $f7, $f0
TextStr_42_5677:           ; id $002B
    ; "*:My kingdom has been losing / in the Starry Night Tournament. / *:This time, we are hosting the / tournament. We must win!"
    db $ea, $9f, $a3, $30, $56, $62, $48, $46, $4b, $44, $41, $4c, $4a, $ef, $ee, $45
    db $3e, $50, $62, $3f, $42, $42, $4b, $62, $49, $4c, $50, $46, $4b, $44, $fa, $f7
    db $ef, $ee, $46, $4b, $62, $51, $45, $42, $62, $36, $51, $3e, $4f, $4f, $56, $ef
    db $ee, $31, $46, $44, $45, $51, $62, $37, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b
    db $51, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $46, $50, $62, $51, $46, $4a
    db $42, $5e, $62, $54, $42, $ef, $ee, $3e, $4f, $42, $62, $45, $4c, $50, $51, $46
    db $4b, $44, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $51, $4c, $52, $4f, $4b, $3e
    db $4a, $42, $4b, $51, $5f, $ef, $ee, $3a, $42, $62, $4a, $52, $50, $51, $62, $54
    db $46, $4b, $63, $62, $f7, $f0
TextStr_42_56fd:           ; id $002C
    ; "*:Let me tell you about the legend / of the Starry Night. / *:The Starry Night comes after every / 47th full moon. / *:Hundreds of thousands..."
    db $eb, $9f, $a3, $2f, $42, $51, $62, $4a, $42, $62, $51, $42, $49, $49, $62, $56
    db $4c, $52, $ef, $ee, $3e, $3f, $4c, $52, $51, $62, $51, $45, $42, $62, $49, $42
    db $44, $42, $4b, $41, $fa, $f7, $ef, $ee, $4c, $43, $62, $51, $45, $42, $62, $36
    db $51, $3e, $4f, $4f, $56, $ef, $ee, $31, $46, $44, $45, $51, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $37, $45, $42, $62, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46
    db $44, $45, $51, $ef, $ee, $40, $4c, $4a, $42, $50, $62, $3e, $43, $51, $42, $4f
    db $62, $42, $53, $42, $4f, $56, $fa, $f7, $ef, $ee, $04, $07, $51, $45, $62, $43
    db $52, $49, $49, $62, $4a, $4c, $4c, $4b, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $2b, $52, $4b, $41, $4f, $42, $41, $50, $62, $4c, $43, $ef, $ee, $51, $45
    db $4c, $52, $50, $3e, $4b, $41, $50, $62, $4c, $43, $62, $50, $51, $3e, $4f, $50
    db $fa, $f7, $ef, $ee, $9f, $a3, $43, $3e, $49, $49, $62, $3e, $4b, $41, $62, $43
    db $46, $49, $49, $ef, $ee, $51, $45, $42, $62, $50, $48, $56, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $29, $4f, $3e, $44, $4a, $42, $4b, $51, $50, $62, $4c, $43, $ef
    db $ee, $49, $46, $44, $45, $51, $62, $40, $4c, $53, $42, $4f, $62, $51, $45, $42
    db $fa, $f7, $ef, $ee, $54, $4c, $4f, $49, $41, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $37, $45, $3e, $51, $68, $62, $51, $45, $42, $ef, $ee, $36, $51, $3e
    db $4f, $4f, $56, $62, $31, $46, $44, $45, $51, $5f, $fa, $f7, $ef, $ee, $9f, $a3
    db $37, $45, $42, $62, $4b, $46, $44, $45, $51, $62, $54, $45, $42, $4b, $ef, $ee
    db $40, $4c, $52, $4b, $51, $49, $42, $50, $50, $62, $49, $46, $53, $42, $50, $fa
    db $f7, $ef, $ee, $50, $45, $4c, $54, $42, $4f, $62, $41, $4c, $54, $4b, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $f3, $9f, $a3, $37, $4c, $62, $40, $42, $49, $42, $3f
    db $4f, $3e, $51, $42, $62, $51, $45, $42, $ef, $ee, $4b, $46, $44, $45, $51, $5e
    db $62, $51, $45, $42, $fa, $f7, $ef, $ee, $51, $4c, $52, $4f, $4b, $3e, $4a, $42
    db $4b, $51, $62, $46, $50, $ef, $ee, $45, $42, $49, $41, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $37, $45, $46, $50, $62, $46, $50, $62, $51, $45, $42, $ef, $ee, $51
    db $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $62, $4c, $43, $62, $51, $45, $42
    db $fa, $f7, $ef, $ee, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45, $51
    db $5f, $ef, $ee, $f7, $f0
TextStr_42_58b2:           ; id $002D
    ; "*:Should I repeat the legend of the / Starry Night? [YES/NO]"
    db $eb, $9f, $a3, $36, $45, $4c, $52, $49, $41, $62, $2c, $62, $4f, $42, $4d, $42
    db $3e, $51, $ef, $ee, $51, $45, $42, $62, $49, $42, $44, $42, $4b, $41, $62, $4c
    db $43, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $36, $51, $3e, $4f, $4f, $56, $62
    db $31, $46, $44, $45, $51, $64, $ef, $ee, $ff, $f0
TextStr_42_58ec:           ; id $002E
    ; "*:Here it is again. / *:The Starry Night comes after every / 47th full moon. / *:On that night, many stars tumble / down one after another. ..."
    db $eb, $9f, $a3, $2b, $42, $4f, $42, $62, $46, $51, $62, $46, $50, $ef, $ee, $3e
    db $44, $3e, $46, $4b, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $36
    db $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45, $51, $ef, $ee, $40, $4c, $4a
    db $42, $50, $62, $3e, $43, $51, $42, $4f, $62, $42, $53, $42, $4f, $56, $fa, $f7
    db $ef, $ee, $04, $07, $51, $45, $62, $43, $52, $49, $49, $62, $4a, $4c, $4c, $4b
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $32, $4b, $62, $51, $45, $3e, $51
    db $62, $4b, $46, $44, $45, $51, $5e, $ef, $ee, $4a, $3e, $4b, $56, $62, $50, $51
    db $3e, $4f, $50, $62, $51, $52, $4a, $3f, $49, $42, $fa, $f7, $ef, $ee, $41, $4c
    db $54, $4b, $62, $4c, $4b, $42, $62, $3e, $43, $51, $42, $4f, $ef, $ee, $3e, $4b
    db $4c, $51, $45, $42, $4f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62
    db $3e, $4b, $40, $46, $42, $4b, $51, $ef, $ee, $4d, $4c, $42, $51, $50, $62, $50
    db $3e, $46, $41, $62, $51, $45, $3e, $51, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3
    db $37, $45, $42, $62, $3f, $4f, $46, $44, $45, $51, $4b, $42, $50, $50, $ef, $ee
    db $4c, $43, $62, $51, $45, $42, $62, $50, $51, $3e, $4f, $50, $62, $46, $50, $fa
    db $f7, $ef, $ee, $49, $46, $48, $42, $62, $3e, $62, $50, $45, $46, $4b, $46, $4b
    db $44, $ef, $ee, $49, $46, $43, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37, $4c
    db $62, $40, $42, $49, $42, $3f, $4f, $3e, $51, $42, $62, $51, $45, $42, $ef, $ee
    db $4b, $46, $44, $45, $51, $62, $3e, $62, $51, $4c, $52, $4f, $4b, $3e, $4a, $42
    db $4b, $51, $fa, $f7, $ef, $ee, $46, $50, $62, $45, $42, $49, $41, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $3a, $42, $62, $40, $3e, $49, $49, $62, $51, $45
    db $46, $50, $62, $51, $45, $42, $ef, $ee, $36, $51, $3e, $4f, $4f, $56, $62, $31
    db $46, $44, $45, $51, $fa, $f7, $ef, $ee, $37, $4c, $52, $4f, $4b, $3e, $4a, $42
    db $4b, $51, $5f, $ef, $ee, $f7, $f0
TextStr_42_5a53:           ; id $002F
    ; "*:The tournament is held on the / Starry Night! / *:The masters who are chosen to / represent their kingdom... / *:Fight to be the greatest ..."
    db $eb, $9f, $a3, $37, $45, $42, $62, $51, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b
    db $51, $ef, $ee, $46, $50, $62, $45, $42, $49, $41, $62, $4c, $4b, $62, $51, $45
    db $42, $fa, $f7, $ef, $ee, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45
    db $51, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $4a, $3e
    db $50, $51, $42, $4f, $50, $62, $54, $45, $4c, $ef, $ee, $3e, $4f, $42, $62, $40
    db $45, $4c, $50, $42, $4b, $62, $51, $4c, $fa, $f7, $ef, $ee, $4f, $42, $4d, $4f
    db $42, $50, $42, $4b, $51, $62, $51, $45, $42, $46, $4f, $ef, $ee, $48, $46, $4b
    db $44, $41, $4c, $4a, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $29, $46, $44
    db $45, $51, $62, $51, $4c, $62, $3f, $42, $62, $51, $45, $42, $ef, $ee, $44, $4f
    db $42, $3e, $51, $42, $50, $51, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $fa, $f7
    db $ef, $ee, $4a, $3e, $50, $51, $42, $4f, $5f, $ef, $ee, $f7, $f0
TextStr_42_5b00:           ; id $0030
    ; "*:Pulio from the farm is goofy but / a very good guy."
    db $ea, $9f, $a3, $33, $52, $49, $46, $4c, $62, $43, $4f, $4c, $4a, $62, $51, $45
    db $42, $ef, $ee, $43, $3e, $4f, $4a, $62, $46, $50, $62, $44, $4c, $4c, $43, $56
    db $62, $3f, $52, $51, $fa, $f7, $ef, $ee, $3e, $62, $53, $42, $4f, $56, $62, $44
    db $4c, $4c, $41, $62, $44, $52, $56, $5f, $ef, $ee, $f7, $f0
TextStr_42_5b3c:           ; id $0031
    ; "*:Upper floor, the monster farm. / *:Pulio takes care of the monsters / on the farm."
    db $ea, $9f, $a3, $38, $4d, $4d, $42, $4f, $62, $43, $49, $4c, $4c, $4f, $5e, $ef
    db $ee, $51, $45, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $43, $3e, $4f
    db $4a, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $33, $52, $49, $46, $4c, $62, $51, $3e
    db $48, $42, $50, $62, $40, $3e, $4f, $42, $ef, $ee, $4c, $43, $62, $51, $45, $42
    db $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $fa, $f7, $ef, $ee, $4c, $4b, $62
    db $51, $45, $42, $62, $43, $3e, $4f, $4a, $5f, $ef, $ee, $f7, $f0
TextStr_42_5b99:           ; id $0032
    ; "*:Watabou brings us capable / masters. / *:Hmm. You want to win the tournament / to find your kidnapped sister? / *:I am sure that your sist..."
    db $ea, $9f, $a3, $3a, $3e, $51, $3e, $3f, $4c, $52, $62, $3f, $4f, $46, $4b, $44
    db $50, $ef, $ee, $52, $50, $62, $40, $3e, $4d, $3e, $3f, $49, $42, $fa, $f7, $ef
    db $ee, $4a, $3e, $50, $51, $42, $4f, $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $2b, $4a, $4a, $5f, $62, $3c, $4c, $52, $62, $54, $3e, $4b, $51, $62, $51
    db $4c, $ef, $ee, $54, $46, $4b, $62, $51, $45, $42, $62, $51, $4c, $52, $4f, $4b
    db $3e, $4a, $42, $4b, $51, $fa, $f7, $ef, $ee, $51, $4c, $62, $43, $46, $4b, $41
    db $62, $56, $4c, $52, $4f, $62, $ef, $ee, $48, $46, $41, $4b, $3e, $4d, $4d, $42
    db $41, $62, $50, $46, $50, $51, $42, $4f, $64, $fa, $f7, $ef, $ee, $9f, $a3, $2c
    db $62, $3e, $4a, $62, $50, $52, $4f, $42, $62, $51, $45, $3e, $51, $ef, $ee, $56
    db $4c, $52, $4f, $62, $50, $46, $50, $51, $42, $4f, $62, $46, $50, $fa, $f7, $ef
    db $ee, $50, $4c, $4a, $42, $54, $45, $42, $4f, $42, $62, $46, $4b, $ef, $ee, $51
    db $45, $46, $50, $62, $49, $3e, $4b, $41, $5f, $f7, $f0
TextStr_42_5c54:           ; id $0033
    ; "*:I wonder where I can get treats."
    db $ea, $9f, $a3, $2c, $62, $54, $4c, $4b, $41, $42, $4f, $62, $54, $45, $42, $4f
    db $42, $62, $2c, $ef, $ee, $40, $3e, $4b, $62, $44, $42, $51, $62, $51, $4f, $42
    db $3e, $51, $50, $5f, $f7, $f0
TextStr_42_5c7a:           ; id $0034
    ; "[HERO] read the sign. / :Danger, Don't rush. Go for it / with courage."
    db $f6, $62, $4f, $42, $3e, $41, $ef, $ee, $51, $45, $42, $62, $50, $46, $44, $4b
    db $5f, $fa, $f7, $ef, $ee, $a3, $27, $3e, $4b, $44, $42, $4f, $5e, $62, $27, $4c
    db $4b, $67, $ef, $ee, $4f, $52, $50, $45, $5f, $62, $2a, $4c, $62, $43, $4c, $4f
    db $62, $46, $51, $fa, $f7, $ef, $ee, $54, $46, $51, $45, $62, $40, $4c, $52, $4f
    db $3e, $44, $42, $5f, $ef, $ee, $f7, $f0
TextStr_42_5cc2:           ; id $0035
    ; "*:No! You'll be hurt if you fall."
    db $ea, $9f, $a3, $31, $4c, $63, $62, $3c, $4c, $52, $66, $49, $62, $3f, $42, $ef
    db $ee, $45, $52, $4f, $51, $62, $46, $43, $62, $56, $4c, $52, $62, $43, $3e, $49
    db $49, $5f, $f7, $f0
TextStr_42_5ce6:           ; id $0036
    ; "*:If it was not for this hole... / *:Oh my dear Lipsy! / *:We are so close yet I cannot touch / you!"
    db $ea, $9f, $a3, $2c, $43, $62, $46, $51, $62, $54, $3e, $50, $62, $4b, $4c, $51
    db $ef, $ee, $43, $4c, $4f, $62, $51, $45, $46, $50, $62, $45, $4c, $49, $42, $5f
    db $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $32, $45, $62, $4a, $56, $62, $41, $42
    db $3e, $4f, $ef, $ee, $2f, $46, $4d, $50, $56, $63, $fa, $f7, $ef, $ee, $9f, $a3
    db $3a, $42, $62, $3e, $4f, $42, $62, $50, $4c, $62, $40, $49, $4c, $50, $42, $ef
    db $ee, $56, $42, $51, $62, $2c, $62, $40, $3e, $4b, $4b, $4c, $51, $62, $51, $4c
    db $52, $40, $45, $fa, $f7, $ef, $ee, $56, $4c, $52, $63, $ef, $ee, $f7, $f0
TextStr_42_5d55:           ; id $0037
    ; "[HERO] read the sign. / :When the GreatTree grows, / the ground trembles. / :This hole is evidence of the / GreatTree's growth. / :The previ..."
    db $f6, $62, $4f, $42, $3e, $41, $62, $51, $45, $42, $ef, $ee, $50, $46, $44, $4b
    db $5f, $fa, $f7, $ef, $ee, $a3, $3a, $45, $42, $4b, $62, $51, $45, $42, $ef, $ee
    db $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $62, $44, $4f, $4c, $54, $50, $5e
    db $fa, $f7, $ef, $ee, $51, $45, $42, $62, $44, $4f, $4c, $52, $4b, $41, $ef, $ee
    db $51, $4f, $42, $4a, $3f, $49, $42, $50, $5f, $fa, $f7, $ef, $ee, $a3, $37, $45
    db $46, $50, $62, $45, $4c, $49, $42, $62, $46, $50, $ef, $ee, $42, $53, $46, $41
    db $42, $4b, $40, $42, $62, $4c, $43, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $2a
    db $4f, $42, $3e, $51, $37, $4f, $42, $42, $68, $ef, $ee, $44, $4f, $4c, $54, $51
    db $45, $5f, $fa, $f7, $ef, $ee, $a3, $37, $45, $42, $62, $4d, $4f, $42, $53, $46
    db $4c, $52, $50, $ef, $ee, $51, $4f, $42, $4a, $4c, $4f, $50, $62, $4a, $3e, $41
    db $42, $fa, $f7, $ef, $ee, $51, $45, $46, $50, $62, $45, $4c, $49, $42, $5f, $ef
    db $ee, $f7, $f0
TextStr_42_5e08:           ; id $0038
    ; "*:I heard that Pulio let the / monsters escape."
    db $ea, $9f, $a3, $2c, $62, $45, $42, $3e, $4f, $41, $62, $51, $45, $3e, $51, $ef
    db $ee, $33, $52, $49, $46, $4c, $62, $49, $42, $51, $62, $51, $45, $42, $fa, $f7
    db $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $42, $50, $40, $3e, $4d
    db $42, $5f, $ef, $ee, $f7, $f0
TextStr_42_5e3e:           ; id $0039
    ; "*:Hey, Mr.Monster Master. I wonder / what I can catch here? / *:I will put my catch in / the jar. / *:Come and see my catch sometimes."
    db $ea, $9f, $a3, $2b, $42, $56, $5e, $62, $30, $4f, $5f, $30, $4c, $4b, $50, $51
    db $42, $4f, $ef, $ee, $30, $3e, $50, $51, $42, $4f, $5f, $62, $2c, $62, $54, $4c
    db $4b, $41, $42, $4f, $fa, $f7, $ef, $ee, $54, $45, $3e, $51, $62, $2c, $62, $40
    db $3e, $4b, $ef, $ee, $40, $3e, $51, $40, $45, $62, $45, $42, $4f, $42, $64, $fa
    db $f7, $ef, $ee, $9f, $a3, $2c, $62, $54, $46, $49, $49, $62, $4d, $52, $51, $62
    db $4a, $56, $ef, $ee, $40, $3e, $51, $40, $45, $62, $46, $4b, $fa, $f7, $ef, $ee
    db $51, $45, $42, $62, $47, $3e, $4f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $26, $4c, $4a, $42, $62, $3e, $4b, $41, $62, $50, $42, $42, $62, $4a, $56, $ef
    db $ee, $40, $3e, $51, $40, $45, $62, $50, $4c, $4a, $42, $51, $46, $4a, $42, $50
    db $5f, $f7, $f0
TextStr_42_5ed1:           ; id $003A
    ; "[HERO] looked into the jar."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $46, $4b, $51, $4c, $ef, $ee, $51
    db $45, $42, $62, $47, $3e, $4f, $5f, $fa, $f7, $f0
TextStr_42_5eeb:           ; id $003B
    ; "[HERO] looked into the jar. / The jar is filled with garbage."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $46, $4b, $51, $4c, $ef, $ee, $51
    db $45, $42, $62, $47, $3e, $4f, $5f, $fa, $f7, $ef, $ee, $37, $45, $42, $62, $47
    db $3e, $4f, $62, $46, $50, $62, $43, $46, $49, $49, $42, $41, $ef, $ee, $54, $46
    db $51, $45, $62, $44, $3e, $4f, $3f, $3e, $44, $42, $5f, $f7, $f0
TextStr_42_5f28:           ; id $003C
    ; "*:Hey you! You came here to / steal my monsters? [YES/NO]"
    db $eb, $9f, $a3, $2b, $42, $56, $62, $56, $4c, $52, $63, $ef, $ee, $3c, $4c, $52
    db $62, $40, $3e, $4a, $42, $62, $45, $42, $4f, $42, $62, $51, $4c, $fa, $f7, $ef
    db $ee, $50, $51, $42, $3e, $49, $62, $4a, $56, $62, $4a, $4c, $4b, $50, $51, $42
    db $4f, $50, $64, $ef, $ee, $ff, $f0
TextStr_42_5f5f:           ; id $003D
    ; "*:C'mon, I'll give you a beating. / Sniff sniff.. / *:Oh, you are a monster master. / I know by your scent. / *:You have the makings of a / ..."
    db $eb, $9f, $a3, $26, $6a, $4c, $4b, $5e, $62, $2c, $66, $49, $62, $44, $46, $53
    db $42, $ef, $ee, $56, $4c, $52, $62, $3e, $62, $3f, $42, $3e, $51, $46, $4b, $44
    db $5f, $fa, $f7, $ef, $ee, $36, $4b, $46, $43, $43, $62, $50, $4b, $46, $43, $43
    db $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $32, $45, $5e, $62, $56, $4c
    db $52, $62, $3e, $4f, $42, $62, $3e, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f
    db $62, $4a, $3e, $50, $51, $42, $4f, $5f, $fa, $f7, $ef, $ee, $2c, $62, $48, $4b
    db $4c, $54, $62, $3f, $56, $62, $56, $4c, $52, $4f, $ef, $ee, $50, $40, $42, $4b
    db $51, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $62, $45, $3e, $53, $42
    db $62, $51, $45, $42, $ef, $ee, $4a, $3e, $48, $46, $4b, $44, $50, $62, $4c, $43
    db $62, $3e, $fa, $f7, $ef, $ee, $44, $4f, $42, $3e, $51, $62, $4a, $3e, $50, $51
    db $42, $4f, $5f, $ef, $ee, $fa, $f7, $f0
TextStr_42_6007:           ; id $003E
    ; "*:You came here to get monsters?"
    db $eb, $9f, $a3, $3c, $4c, $52, $62, $40, $3e, $4a, $42, $62, $45, $42, $4f, $42
    db $62, $51, $4c, $ef, $ee, $44, $42, $51, $62, $4a, $4c, $4b, $50, $51, $42, $4f
    db $50, $64, $fa, $f7, $f0
TextStr_42_602c:           ; id $003F
    ; "*:I'm Pulio I take care / of this farm. / Pulio:I heard about you from / the King.Take your monsters. / Pulio:Well, actually, I only / have ..."
    db $eb, $9f, $a3, $2c, $6a, $62, $33, $52, $49, $46, $4c, $ef, $ee, $2c, $62, $51
    db $3e, $48, $42, $62, $40, $3e, $4f, $42, $fa, $f7, $ef, $ee, $4c, $43, $62, $51
    db $45, $46, $50, $62, $43, $3e, $4f, $4a, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $33
    db $52, $49, $46, $4c, $a3, $2c, $62, $45, $42, $3e, $4f, $41, $ef, $ee, $3e, $3f
    db $4c, $52, $51, $62, $56, $4c, $52, $62, $43, $4f, $4c, $4a, $fa, $f7, $ef, $ee
    db $51, $45, $42, $62, $2e, $46, $4b, $44, $5f, $37, $3e, $48, $42, $62, $56, $4c
    db $52, $4f, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f, $fa, $f7, $ef
    db $ee, $33, $52, $49, $46, $4c, $a3, $3a, $42, $49, $49, $5e, $ef, $ee, $3e, $40
    db $51, $52, $3e, $49, $49, $56, $5e, $62, $2c, $62, $4c, $4b, $49, $56, $fa, $f7
    db $ef, $ee, $45, $3e, $53, $42, $62, $4c, $4b, $42, $ef, $ee, $4a, $4c, $4b, $50
    db $51, $42, $4f, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $3e, $4b, $62, $4c, $49, $41
    db $62, $4c, $4b, $42, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $33, $52, $49
    db $46, $4c, $a3, $2c, $51, $68, $62, $36, $49, $46, $3f, $5f, $ef, $ee, $2c, $51
    db $62, $54, $3e, $50, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $43, $3e, $53, $4c
    db $4f, $46, $51, $42, $62, $4c, $43, $62, $4c, $52, $4f, $ef, $ee, $49, $3e, $50
    db $51, $62, $2e, $46, $4b, $44, $5f, $fa, $f7, $ef, $ee, $33, $52, $49, $46, $4c
    db $a3, $26, $45, $4c, $4c, $50, $42, $ef, $ee, $96, $33, $2c, $26, $2e, $62, $38
    db $33, $97, $62, $51, $4c, $62, $51, $3e, $48, $42, $fa, $f7, $ef, $ee, $51, $45
    db $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $5f, $ef, $ee, $f0
TextStr_42_6159:           ; id $0040
    ; "*:I'm Slio. I am the grandson / of Grandpa Slib. / Slio:D'ya wanna know about the / farm? [YES/NO]"
    db $eb, $9f, $a3, $2c, $6a, $62, $36, $49, $46, $4c, $5f, $62, $2c, $62, $ef, $ee
    db $3e, $4a, $62, $51, $45, $42, $62, $44, $4f, $3e, $4b, $41, $50, $4c, $4b, $fa
    db $f7, $ef, $ee, $4c, $43, $62, $2a, $4f, $3e, $4b, $41, $4d, $3e, $62, $36, $49
    db $46, $3f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $36, $49, $46, $4c, $a3, $27, $6b
    db $3e, $62, $54, $3e, $4b, $4b, $3e, $ef, $ee, $48, $4b, $4c, $54, $62, $3e, $3f
    db $4c, $52, $51, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $43, $3e, $4f, $4a, $64
    db $ef, $ee, $ff, $f0
TextStr_42_61bd:           ; id $0041
    ; "Slio:You can drop off up to 19 / monsters and eggs here. / Slio:The monsters can still get the / experience points even if you leave / the m..."
    db $eb, $36, $49, $46, $4c, $a3, $3c, $4c, $52, $62, $40, $3e, $4b, $62, $41, $4f
    db $4c, $4d, $ef, $ee, $4c, $43, $43, $62, $52, $4d, $62, $51, $4c, $62, $01, $09
    db $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $3e, $4b, $41
    db $ef, $ee, $42, $44, $44, $50, $62, $45, $42, $4f, $42, $5f, $fa, $f7, $ef, $ee
    db $36, $49, $46, $4c, $a3, $37, $45, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f
    db $50, $ef, $ee, $40, $3e, $4b, $62, $50, $51, $46, $49, $49, $62, $44, $42, $51
    db $62, $51, $45, $42, $fa, $f7, $ef, $ee, $42, $55, $4d, $42, $4f, $46, $42, $4b
    db $40, $42, $62, $4d, $4c, $46, $4b, $51, $50, $ef, $ee, $42, $53, $42, $4b, $62
    db $46, $43, $62, $56, $4c, $52, $62, $49, $42, $3e, $53, $42, $fa, $f7, $ef, $ee
    db $51, $45, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $45, $42, $4f
    db $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $36, $49, $46, $4c, $a3, $25, $52, $51
    db $62, $51, $45, $42, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $54
    db $46, $49, $49, $fa, $f7, $ef, $ee, $44, $42, $51, $62, $4a, $4c, $4f, $42, $62
    db $4d, $4c, $46, $4b, $51, $50, $ef, $ee, $46, $43, $62, $56, $4c, $52, $62, $51
    db $3e, $48, $42, $62, $51, $45, $42, $4a, $fa, $f7, $ef, $ee, $54, $46, $51, $45
    db $62, $56, $4c, $52, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $36, $49, $46, $4c, $a3
    db $3a, $45, $42, $4b, $62, $56, $4c, $52, $ef, $ee, $4f, $42, $3e, $40, $45, $62
    db $51, $45, $42, $62, $49, $46, $4a, $46, $51, $5e, $fa, $f7, $ef, $ee, $56, $4c
    db $52, $62, $40, $3e, $4b, $62, $4a, $3e, $48, $42, $62, $50, $4c, $4a, $42, $ef
    db $ee, $4c, $43, $62, $51, $45, $42, $4a, $62, $50, $49, $42, $42, $4d, $5f, $fa
    db $f7, $ef, $ee, $36, $49, $46, $4c, $a3, $36, $49, $42, $42, $4d, $62, $40, $3e
    db $4b, $62, $4d, $52, $51, $ef, $ee, $3e, $49, $49, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $50, $62, $4c, $4b, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $43, $3e
    db $4f, $4a, $62, $46, $4b, $62, $3e, $ef, $ee, $41, $42, $42, $4d, $62, $50, $49
    db $42, $42, $4d, $5f, $fa, $f7, $ef, $ee, $36, $49, $46, $4c, $a3, $37, $45, $42
    db $4b, $5e, $62, $56, $4c, $52, $62, $40, $3e, $4b, $ef, $ee, $41, $4f, $4c, $4d
    db $62, $4c, $43, $43, $62, $01, $09, $62, $4a, $4c, $4f, $42, $fa, $f7, $ef, $ee
    db $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $3e, $51, $62, $51, $45, $42, $ef
    db $ee, $43, $3e, $4f, $4a, $5f, $fa, $f7, $ef, $ee, $36, $49, $46, $4c, $a3, $24
    db $4b, $41, $62, $46, $43, $62, $56, $4c, $52, $ef, $ee, $4f, $42, $3e, $40, $45
    db $62, $51, $45, $42, $62, $49, $46, $4a, $46, $51, $fa, $f7, $ef, $ee, $3e, $44
    db $3e, $46, $4b, $5e, $62, $56, $4c, $52, $62, $54, $46, $49, $49, $62, $ef, $ee
    db $45, $3e, $53, $42, $62, $51, $4c, $62, $4d, $3e, $4f, $51, $62, $54, $46, $51
    db $45, $fa, $f7, $ef, $ee, $50, $4c, $4a, $42, $62, $4a, $4c, $4b, $50, $51, $42
    db $4f, $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $36, $49, $46, $4c, $a3, $3c, $4c
    db $52, $62, $40, $3e, $4b, $67, $ef, $ee, $51, $3e, $48, $42, $62, $51, $45, $42
    db $62, $42, $44, $44, $50, $fa, $f7, $ef, $ee, $54, $46, $51, $45, $62, $56, $4c
    db $52, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $36, $49, $46, $4c, $a3, $33, $49, $42
    db $3e, $50, $42, $62, $41, $4f, $4c, $4d, $ef, $ee, $51, $45, $42, $4a, $62, $4c
    db $43, $43, $62, $45, $42, $4f, $42, $5f, $f7, $f0
TextStr_42_6437:           ; id $0042
    ; "Slio:Raise the monster to be / powerful!"
    db $eb, $36, $49, $46, $4c, $a3, $35, $3e, $46, $50, $42, $62, $51, $45, $42, $ef
    db $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $51, $4c, $62, $3f, $42, $fa, $f7
    db $ef, $ee, $4d, $4c, $54, $42, $4f, $43, $52, $49, $63, $ef, $ee, $f7, $f0
TextStr_42_6466:           ; id $0043
    ; "Slio:D'ya wanna know about the / farm? [YES/NO]"
    db $eb, $36, $49, $46, $4c, $a3, $27, $6b, $3e, $62, $54, $3e, $4b, $4b, $3e, $ef
    db $ee, $48, $4b, $4c, $54, $62, $3e, $3f, $4c, $52, $51, $62, $51, $45, $42, $fa
    db $f7, $ef, $ee, $43, $3e, $4f, $4a, $64, $ef, $ee, $ff, $f0
TextStr_42_6492:           ; id $0044
    ; "*:You are at the monster farm."
    db $eb, $9f, $a3, $3c, $4c, $52, $62, $3e, $4f, $42, $62, $3e, $51, $62, $51, $45
    db $42, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $43, $3e, $4f, $4a, $5f
    db $f7, $f0
TextStr_42_64b4:           ; id $0045
    ; "King:Oh, this monster is the / former king's... / King:[HERO]! Why did you adopt / that monster? / King:Huh? This is the only one left? / Th..."
    db $ea, $2e, $46, $4b, $44, $a3, $32, $45, $5e, $62, $51, $45, $46, $50, $ef, $ee
    db $4a, $4c, $4b, $50, $51, $42, $4f, $62, $46, $50, $62, $51, $45, $42, $fa, $f7
    db $ef, $ee, $43, $4c, $4f, $4a, $42, $4f, $62, $48, $46, $4b, $44, $68, $5f, $5f
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $f6, $63, $62, $3a
    db $45, $56, $ef, $ee, $41, $46, $41, $62, $56, $4c, $52, $62, $3e, $41, $4c, $4d
    db $51, $fa, $f7, $ef, $ee, $51, $45, $3e, $51, $62, $4a, $4c, $4b, $50, $51, $42
    db $4f, $64, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $2b, $52, $45
    db $64, $62, $37, $45, $46, $50, $62, $46, $50, $ef, $ee, $51, $45, $42, $62, $4c
    db $4b, $49, $56, $62, $4c, $4b, $42, $62, $49, $42, $43, $51, $64, $fa, $f7, $ef
    db $ee, $37, $45, $3e, $51, $62, $33, $52, $49, $46, $4c, $63, $63, $63, $ef, $ee
    db $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $2b, $42, $62, $4a, $52, $50, $51
    db $6c, $42, $ef, $ee, $49, $42, $51, $62, $51, $45, $42, $62, $4c, $51, $45, $42
    db $4f, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $42, $50
    db $40, $3e, $4d, $42, $63, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3
    db $33, $52, $49, $46, $4c, $63, $62, $33, $52, $49, $46, $4c, $63, $ef, $ee, $25
    db $4f, $46, $4b, $44, $62, $33, $52, $49, $46, $4c, $62, $45, $42, $4f, $42, $63
    db $f7, $f0
TextStr_42_65b6:           ; id $0046
    ; "Pulio:Your Majesty, please / forgive me."
    db $eb, $33, $52, $49, $46, $4c, $a3, $3c, $4c, $52, $4f, $ef, $ee, $30, $3e, $47
    db $42, $50, $51, $56, $5e, $62, $4d, $49, $42, $3e, $50, $42, $fa, $f7, $ef, $ee
    db $43, $4c, $4f, $44, $46, $53, $42, $62, $4a, $42, $5f, $ef, $ee, $f7, $f0
TextStr_42_65e5:           ; id $0047
    ; "King:Pulio, did Hale escape / as well?"
    db $ea, $2e, $46, $4b, $44, $a3, $33, $52, $49, $46, $4c, $5e, $62, $41, $46, $41
    db $ef, $ee, $2b, $3e, $49, $42, $62, $42, $50, $40, $3e, $4d, $42, $fa, $f7, $ef
    db $ee, $3e, $50, $62, $54, $42, $49, $49, $64, $ef, $ee, $f7, $f0
TextStr_42_6612:           ; id $0048
    ; "Pulio:Your Majesty please forgive me! / Hale escaped too."
    db $eb, $33, $52, $49, $46, $4c, $a3, $3c, $4c, $52, $4f, $62, $30, $3e, $47, $42
    db $50, $51, $56, $ef, $ee, $4d, $49, $42, $3e, $50, $42, $62, $43, $4c, $4f, $44
    db $46, $53, $42, $62, $4a, $42, $63, $fa, $f7, $ef, $ee, $2b, $3e, $49, $42, $62
    db $42, $50, $40, $3e, $4d, $42, $41, $ef, $ee, $51, $4c, $4c, $5f, $f7, $f0
TextStr_42_6651:           ; id $0049
    ; "King:Arrgh! You! You let my / precious Hale escape too! / King:This is unforgivable! / Throw him in the dungeon!!"
    db $ea, $2e, $46, $4b, $44, $a3, $24, $4f, $4f, $44, $45, $63, $62, $3c, $4c, $52
    db $63, $ef, $ee, $3c, $4c, $52, $62, $49, $42, $51, $62, $4a, $56, $fa, $f7, $ef
    db $ee, $4d, $4f, $42, $40, $46, $4c, $52, $50, $62, $2b, $3e, $49, $42, $ef, $ee
    db $42, $50, $40, $3e, $4d, $42, $62, $51, $4c, $4c, $63, $fa, $f7, $ef, $ee, $2e
    db $46, $4b, $44, $a3, $37, $45, $46, $50, $62, $46, $50, $ef, $ee, $52, $4b, $43
    db $4c, $4f, $44, $46, $53, $3e, $3f, $49, $42, $63, $fa, $f7, $ef, $ee, $37, $45
    db $4f, $4c, $54, $62, $45, $46, $4a, $62, $46, $4b, $ef, $ee, $51, $45, $42, $62
    db $41, $52, $4b, $44, $42, $4c, $4b, $63, $63, $f7, $f0
TextStr_42_66cc:           ; id $004A
    ; "King:What? [HERO]! / You have something to say?! / King:What? You will / catch Hale to free Pulio? / King:You say you will catch Hale? / Kin..."
    db $ea, $2e, $46, $4b, $44, $a3, $3a, $45, $3e, $51, $64, $ef, $ee, $f6, $63, $fa
    db $f7, $ef, $ee, $3c, $4c, $52, $62, $45, $3e, $53, $42, $ef, $ee, $50, $4c, $4a
    db $42, $51, $45, $46, $4b, $44, $62, $51, $4c, $62, $50, $3e, $56, $64, $63, $fa
    db $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $3a, $45, $3e, $51, $64, $ef, $ee, $3c
    db $4c, $52, $62, $54, $46, $49, $49, $fa, $f7, $ef, $ee, $40, $3e, $51, $40, $45
    db $62, $2b, $3e, $49, $42, $62, $51, $4c, $ef, $ee, $43, $4f, $42, $42, $62, $33
    db $52, $49, $46, $4c, $64, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $3c, $4c
    db $52, $62, $50, $3e, $56, $62, $56, $4c, $52, $ef, $ee, $54, $46, $49, $49, $62
    db $40, $3e, $51, $40, $45, $62, $2b, $3e, $49, $42, $64, $fa, $f7, $ef, $ee, $2e
    db $46, $4b, $44, $a3, $38, $4a, $4a, $4a, $5f, $5f, $5f, $36, $4c, $52, $4b, $41
    db $50, $ef, $ee, $46, $4b, $51, $42, $4f, $42, $50, $51, $46, $4b, $44, $5f, $62
    db $3c, $4c, $52, $fa, $f7, $ef, $ee, $4a, $3e, $56, $62, $51, $4f, $56, $62, $f6
    db $5f, $ef, $ee, $f7, $f0
TextStr_42_6791:           ; id $004B
    ; "Pulio:Majesty, Hale escaped / through the Travelers' Gate."
    db $eb, $33, $52, $49, $46, $4c, $a3, $30, $3e, $47, $42, $50, $51, $56, $5e, $ef
    db $ee, $2b, $3e, $49, $42, $62, $42, $50, $40, $3e, $4d, $42, $41, $fa, $f7, $ef
    db $ee, $51, $45, $4f, $4c, $52, $44, $45, $62, $51, $45, $42, $ef, $ee, $37, $4f
    db $3e, $53, $42, $49, $42, $4f, $50, $5c, $62, $2a, $3e, $51, $42, $5f, $f7, $f0
TextStr_42_67d1:           ; id $004C
    ; "King:I see. Now [HERO], proceed / to the Travelers' Gate. / King:If you bring Hale back, / I will pardon Pulio. / King:The treasure chest in..."
    db $ea, $2e, $46, $4b, $44, $a3, $2c, $62, $50, $42, $42, $5f, $62, $31, $4c, $54
    db $ef, $ee, $f6, $5e, $62, $4d, $4f, $4c, $40, $42, $42, $41, $fa, $f7, $ef, $ee
    db $51, $4c, $62, $51, $45, $42, $62, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50
    db $5c, $ef, $ee, $2a, $3e, $51, $42, $5f, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44
    db $a3, $2c, $43, $62, $56, $4c, $52, $62, $3f, $4f, $46, $4b, $44, $ef, $ee, $2b
    db $3e, $49, $42, $62, $3f, $3e, $40, $48, $5e, $fa, $f7, $ef, $ee, $2c, $62, $54
    db $46, $49, $49, $62, $4d, $3e, $4f, $41, $4c, $4b, $ef, $ee, $33, $52, $49, $46
    db $4c, $5f, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $37, $45, $42, $62, $51
    db $4f, $42, $3e, $50, $52, $4f, $42, $ef, $ee, $40, $45, $42, $50, $51, $62, $46
    db $4b, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $4b, $42, $55, $51, $62, $4f, $4c
    db $4c, $4a, $62, $46, $50, $ef, $ee, $4b, $4c, $54, $62, $56, $4c, $52, $4f, $50
    db $5f, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $24, $50, $48, $62, $51, $45
    db $42, $ef, $ee, $4a, $46, $4b, $46, $50, $51, $42, $4f, $62, $3e, $3f, $4c, $52
    db $51, $62, $46, $51, $5f, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $3c, $4c
    db $52, $62, $3e, $4f, $42, $ef, $ee, $41, $46, $50, $4a, $46, $50, $50, $42, $41
    db $5f, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $25, $52, $50, $56, $63, $62
    db $25, $52, $50, $56, $63, $ef, $ee, $25, $52, $50, $56, $63, $f7, $f0
TextStr_42_68df:           ; id $004D
    ; "*:His Majesty seems to be / very upset. / *:Please proceed to the Travelers' / Gate and bring Hale back. / *:[HERO], good luck."
    db $ea, $9f, $a3, $2b, $46, $50, $62, $30, $3e, $47, $42, $50, $51, $56, $ef, $ee
    db $50, $42, $42, $4a, $50, $62, $51, $4c, $62, $3f, $42, $fa, $f7, $ef, $ee, $53
    db $42, $4f, $56, $62, $52, $4d, $50, $42, $51, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $33, $49, $42, $3e, $50, $42, $62, $4d, $4f, $4c, $40, $42, $42, $41
    db $ef, $ee, $51, $4c, $62, $51, $45, $42, $62, $37, $4f, $3e, $53, $42, $49, $42
    db $4f, $50, $5c, $fa, $f7, $ef, $ee, $2a, $3e, $51, $42, $62, $3e, $4b, $41, $62
    db $3f, $4f, $46, $4b, $44, $ef, $ee, $2b, $3e, $49, $42, $62, $3f, $3e, $40, $48
    db $5f, $fa, $f7, $ef, $ee, $9f, $a3, $f6, $5e, $ef, $ee, $44, $4c, $4c, $41, $62
    db $49, $52, $40, $48, $5f, $f7, $f0
TextStr_42_6966:           ; id $004E
    ; "*:Give the courageous master / [HERO] the power of GreatTree!"
    db $ea, $9f, $a3, $2a, $46, $53, $42, $62, $51, $45, $42, $ef, $ee, $40, $4c, $52
    db $4f, $3e, $44, $42, $4c, $52, $50, $62, $4a, $3e, $50, $51, $42, $4f, $fa, $f7
    db $ef, $ee, $f6, $62, $51, $45, $42, $62, $4d, $4c, $54, $42, $4f, $ef, $ee, $4c
    db $43, $62, $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $63, $f7, $f0
TextStr_42_69a4:           ; id $004F
    ; "*:In the Chamber of Travelers' / Gates exist the mystic spirals. / *:You can go to mystic worlds / through them. / *:There are no wild monst..."
    db $eb, $9f, $a3, $2c, $4b, $62, $51, $45, $42, $62, $26, $45, $3e, $4a, $3f, $42
    db $4f, $ef, $ee, $4c, $43, $62, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c
    db $fa, $f7, $ef, $ee, $2a, $3e, $51, $42, $50, $62, $42, $55, $46, $50, $51, $62
    db $51, $45, $42, $ef, $ee, $4a, $56, $50, $51, $46, $40, $62, $50, $4d, $46, $4f
    db $3e, $49, $50, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $62, $40, $3e
    db $4b, $62, $44, $4c, $62, $51, $4c, $ef, $ee, $4a, $56, $50, $51, $46, $40, $62
    db $54, $4c, $4f, $49, $41, $50, $fa, $f7, $ef, $ee, $51, $45, $4f, $4c, $52, $44
    db $45, $62, $51, $45, $42, $4a, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37
    db $45, $42, $4f, $42, $62, $3e, $4f, $42, $62, $4b, $4c, $ef, $ee, $54, $46, $49
    db $41, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $fa, $f7, $ef, $ee, $49, $46
    db $53, $46, $4b, $44, $62, $4c, $4b, $62, $51, $45, $46, $50, $ef, $ee, $50, $46
    db $41, $42, $62, $4c, $43, $62, $51, $45, $42, $62, $2a, $3e, $51, $42, $5f, $fa
    db $f7, $ef, $ee, $9f, $a3, $24, $49, $49, $62, $51, $45, $42, $62, $54, $46, $49
    db $41, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $49, $46, $53, $42
    db $62, $4c, $4b, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $4c, $51, $45, $42, $4f
    db $62, $50, $46, $41, $42, $62, $4c, $43, $ef, $ee, $51, $45, $42, $62, $37, $4f
    db $3e, $53, $42, $49, $42, $4f, $50, $5c, $fa, $f7, $ef, $ee, $2a, $3e, $51, $42
    db $50, $5f, $ef, $ee, $f7, $f0
TextStr_42_6aba:           ; id $0050
    ; "Pulio:Sorry [HERO], It's my fault... / Pulio:I know, lemme tell ya a / useful thing. / Pulio:You can record your quest / using the JOURNAL u..."
    db $eb, $33, $52, $49, $46, $4c, $a3, $36, $4c, $4f, $4f, $56, $62, $f6, $5e, $ef
    db $ee, $2c, $51, $68, $62, $4a, $56, $62, $43, $3e, $52, $49, $51, $5f, $5f, $5f
    db $fa, $f7, $ef, $ee, $33, $52, $49, $46, $4c, $a3, $2c, $62, $48, $4b, $4c, $54
    db $5e, $ef, $ee, $49, $42, $4a, $4a, $42, $62, $51, $42, $49, $49, $62, $56, $3e
    db $62, $3e, $fa, $f7, $ef, $ee, $52, $50, $42, $43, $52, $49, $62, $51, $45, $46
    db $4b, $44, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $33, $52, $49, $46, $4c, $a3, $3c
    db $4c, $52, $62, $40, $3e, $4b, $ef, $ee, $4f, $42, $40, $4c, $4f, $41, $62, $56
    db $4c, $52, $4f, $62, $4e, $52, $42, $50, $51, $fa, $f7, $ef, $ee, $52, $50, $46
    db $4b, $44, $62, $51, $45, $42, $62, $2d, $32, $38, $35, $31, $24, $2f, $ef, $ee
    db $52, $4b, $41, $42, $4f, $62, $51, $45, $42, $62, $32, $33, $37, $31, $5f, $f7
    db $f0
TextStr_42_6b5b:           ; id $0051
    ; "*:These stairs bring you to the / Chamber of the Travelers' Gates."
    db $ea, $9f, $a3, $37, $45, $42, $50, $42, $62, $50, $51, $3e, $46, $4f, $50, $ef
    db $ee, $3f, $4f, $46, $4b, $44, $62, $56, $4c, $52, $62, $51, $4c, $62, $51, $45
    db $42, $fa, $f7, $ef, $ee, $26, $45, $3e, $4a, $3f, $42, $4f, $62, $4c, $43, $62
    db $51, $45, $42, $ef, $ee, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $62
    db $2a, $3e, $51, $42, $50, $5f, $f7, $f0
TextStr_42_6ba3:           ; id $0052
    ; "*:Please bring Hale back as soon / as possible!"
    db $ea, $9f, $a3, $33, $49, $42, $3e, $50, $42, $62, $3f, $4f, $46, $4b, $44, $ef
    db $ee, $2b, $3e, $49, $42, $62, $3f, $3e, $40, $48, $62, $3e, $50, $62, $50, $4c
    db $4c, $4b, $fa, $f7, $ef, $ee, $3e, $50, $62, $4d, $4c, $50, $50, $46, $3f, $49
    db $42, $63, $ef, $ee, $f7, $f0
TextStr_42_6bd9:           ; id $0053
    ; "*:When you enter the Travelers' / Gates, you will be sent to an alien / world. / *:There are magical holes / in the mystic world / *:and you..."
    db $eb, $9f, $a3, $3a, $45, $42, $4b, $62, $56, $4c, $52, $62, $42, $4b, $51, $42
    db $4f, $ef, $ee, $51, $45, $42, $62, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50
    db $5c, $fa, $f7, $ef, $ee, $2a, $3e, $51, $42, $50, $5e, $62, $56, $4c, $52, $62
    db $54, $46, $49, $49, $62, $3f, $42, $ef, $ee, $50, $42, $4b, $51, $62, $51, $4c
    db $62, $3e, $4b, $62, $3e, $49, $46, $42, $4b, $fa, $f7, $ef, $ee, $54, $4c, $4f
    db $49, $41, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $4f, $42
    db $62, $3e, $4f, $42, $ef, $ee, $4a, $3e, $44, $46, $40, $3e, $49, $62, $45, $4c
    db $49, $42, $50, $fa, $f7, $ef, $ee, $46, $4b, $62, $51, $45, $42, $62, $4a, $56
    db $50, $51, $46, $40, $ef, $ee, $54, $4c, $4f, $49, $41, $fa, $f7, $ef, $ee, $9f
    db $a3, $3e, $4b, $41, $62, $56, $4c, $52, $62, $40, $3e, $4b, $62, $54, $3e, $4f
    db $4d, $ef, $ee, $51, $4c, $62, $51, $45, $42, $62, $4b, $42, $55, $51, $fa, $f7
    db $ef, $ee, $49, $42, $53, $42, $49, $62, $4c, $43, $62, $51, $45, $42, $ef, $ee
    db $54, $4c, $4f, $49, $41, $62, $51, $45, $4f, $4c, $52, $44, $45, $fa, $f7, $ef
    db $ee, $51, $45, $42, $62, $45, $4c, $49, $42, $50, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $3c, $4c, $52, $62, $50, $45, $4c, $52, $49, $41, $62, $3f, $42
    db $ef, $ee, $3e, $3f, $49, $42, $62, $51, $4c, $62, $40, $4c, $4a, $42, $62, $3f
    db $3e, $40, $48, $fa, $f7, $ef, $ee, $54, $45, $42, $4b, $62, $56, $4c, $52, $62
    db $41, $42, $43, $42, $3e, $51, $ef, $ee, $51, $45, $42, $62, $4a, $4c, $4b, $50
    db $51, $42, $4f, $62, $4c, $4b, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $49, $3e
    db $50, $51, $62, $49, $42, $53, $42, $49, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $27, $52, $4f, $46, $4b, $44, $62, $51, $45, $42, $ef, $ee, $3e, $41, $53
    db $42, $4b, $51, $52, $4f, $42, $5e, $62, $46, $43, $fa, $f7, $ef, $ee, $56, $4c
    db $52, $62, $54, $3e, $4b, $51, $62, $51, $4c, $62, $50, $42, $42, $ef, $ee, $51
    db $45, $42, $62, $4a, $3e, $4d, $62, $4c, $43, $62, $54, $45, $42, $4f, $42, $fa
    db $f7, $ef, $ee, $56, $4c, $52, $6c, $42, $62, $3f, $42, $42, $4b, $5e, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $4d, $4f, $42, $50, $50, $62, $51, $45, $42, $ef
    db $ee, $36, $28, $2f, $28, $26, $37, $62, $3f, $52, $51, $51, $4c, $4b, $5f, $fa
    db $f7, $ef, $ee, $25, $52, $51, $62, $46, $51, $62, $54, $4c, $4f, $48, $50, $ef
    db $ee, $4c, $4b, $49, $56, $62, $54, $45, $42, $4b, $62, $56, $4c, $52, $fa, $f7
    db $ef, $ee, $3e, $4f, $42, $62, $46, $4b, $62, $51, $45, $42, $ef, $ee, $4a, $56
    db $50, $51, $46, $40, $62, $54, $4c, $4f, $49, $41, $5f, $f7, $f0
TextStr_42_6dc6:           ; id $0054
    ; "*:You will find items scattered / around in the Travelers' Gates. / *:Use them well to continue your / adventure. / *:You can only carry up ..."
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $54, $46, $49, $49, $62, $43, $46, $4b, $41
    db $ef, $ee, $46, $51, $42, $4a, $50, $62, $50, $40, $3e, $51, $51, $42, $4f, $42
    db $41, $fa, $f7, $ef, $ee, $3e, $4f, $4c, $52, $4b, $41, $62, $46, $4b, $62, $51
    db $45, $42, $ef, $ee, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $62, $2a
    db $3e, $51, $42, $50, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $38, $50, $42, $62, $51
    db $45, $42, $4a, $62, $54, $42, $49, $49, $62, $51, $4c, $ef, $ee, $40, $4c, $4b
    db $51, $46, $4b, $52, $42, $62, $56, $4c, $52, $4f, $fa, $f7, $ef, $ee, $3e, $41
    db $53, $42, $4b, $51, $52, $4f, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $3c, $4c, $52, $62, $40, $3e, $4b, $62, $4c, $4b, $49, $56, $ef, $ee, $40, $3e
    db $4f, $4f, $56, $62, $52, $4d, $62, $51, $4c, $62, $02, $00, $fa, $f7, $ef, $ee
    db $4c, $43, $62, $51, $45, $42, $4a, $5f, $ef, $ee, $f7, $f0
TextStr_42_6e72:           ; id $0055
    ; "*:Hale was the cherished pet of / the King. / *:Why did it run away... / *:Over there, the room with the door / open is the Chamber of / Tra..."
    db $ea, $9f, $a3, $2b, $3e, $49, $42, $62, $54, $3e, $50, $62, $51, $45, $42, $ef
    db $ee, $40, $45, $42, $4f, $46, $50, $45, $42, $41, $62, $4d, $42, $51, $62, $4c
    db $43, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $2e, $46, $4b, $44, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45, $56, $62, $41, $46, $41, $62, $46, $51
    db $62, $4f, $52, $4b, $ef, $ee, $3e, $54, $3e, $56, $5f, $5f, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $32, $53, $42, $4f, $62, $51, $45, $42, $4f, $42, $5e, $62, $51
    db $45, $42, $ef, $ee, $4f, $4c, $4c, $4a, $62, $54, $46, $51, $45, $62, $51, $45
    db $42, $62, $41, $4c, $4c, $4f, $fa, $f7, $ef, $ee, $4c, $4d, $42, $4b, $62, $46
    db $50, $62, $51, $45, $42, $ef, $ee, $26, $45, $3e, $4a, $3f, $42, $4f, $62, $4c
    db $43, $fa, $f7, $ef, $ee, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $62
    db $2a, $3e, $51, $42, $50, $5f, $ef, $ee, $f7, $f0
TextStr_42_6f1c:           ; id $0056
    ; "*:Welcome to the Chamber of / Travelers' Gates, little master."
    db $ea, $9f, $a3, $3a, $42, $49, $40, $4c, $4a, $42, $62, $51, $4c, $62, $51, $45
    db $42, $ef, $ee, $26, $45, $3e, $4a, $3f, $42, $4f, $62, $4c, $43, $fa, $f7, $ef
    db $ee, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $62, $2a, $3e, $51, $42
    db $50, $5e, $ef, $ee, $49, $46, $51, $51, $49, $42, $62, $4a, $3e, $50, $51, $42
    db $4f, $5f, $f7, $f0
TextStr_42_6f60:           ; id $0057
    ; "*:We are at the Chamber of / Travelers' Gates. / This way to the Travelers' Gate. / *:Hale escaped through this Gate. / *:We're counting on ..."
    db $ea, $9f, $a3, $3a, $42, $62, $3e, $4f, $42, $62, $3e, $51, $62, $51, $45, $42
    db $ef, $ee, $26, $45, $3e, $4a, $3f, $42, $4f, $62, $4c, $43, $fa, $f7, $ef, $ee
    db $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $62, $2a, $3e, $51, $42, $50
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $37, $45, $46, $50, $62, $54, $3e, $56, $62
    db $51, $4c, $62, $51, $45, $42, $ef, $ee, $37, $4f, $3e, $53, $42, $49, $42, $4f
    db $50, $5c, $62, $2a, $3e, $51, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $3e
    db $49, $42, $62, $42, $50, $40, $3e, $4d, $42, $41, $ef, $ee, $51, $45, $4f, $4c
    db $52, $44, $45, $62, $51, $45, $46, $50, $62, $2a, $3e, $51, $42, $5f, $fa, $f7
    db $ef, $ee, $9f, $a3, $3a, $42, $69, $42, $62, $40, $4c, $52, $4b, $51, $46, $4b
    db $44, $ef, $ee, $4c, $4b, $62, $56, $4c, $52, $5e, $f6, $63, $f7, $f0
TextStr_42_6ffe:           ; id $0058
    ; "*:How do you do. I'm Hale. / *:I know you are here to catch me. / But you can forget it. / *:The farm is boring. I don't / wanna go back!"
    db $eb, $9f, $a3, $2b, $4c, $54, $62, $41, $4c, $62, $56, $4c, $52, $62, $41, $4c
    db $5f, $ef, $ee, $2c, $6a, $62, $2b, $3e, $49, $42, $5f, $fa, $f7, $ef, $ee, $9f
    db $a3, $2c, $62, $48, $4b, $4c, $54, $62, $56, $4c, $52, $62, $3e, $4f, $42, $ef
    db $ee, $45, $42, $4f, $42, $62, $51, $4c, $62, $40, $3e, $51, $40, $45, $62, $4a
    db $42, $5f, $fa, $f7, $ef, $ee, $25, $52, $51, $62, $56, $4c, $52, $62, $40, $3e
    db $4b, $ef, $ee, $43, $4c, $4f, $44, $42, $51, $62, $46, $51, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $37, $45, $42, $62, $43, $3e, $4f, $4a, $62, $46, $50, $ef, $ee
    db $3f, $4c, $4f, $46, $4b, $44, $5f, $62, $2c, $62, $41, $4c, $4b, $67, $fa, $f7
    db $ef, $ee, $54, $3e, $4b, $4b, $3e, $62, $44, $4c, $62, $3f, $3e, $40, $48, $63
    db $ef, $ee, $f7, $f0
TextStr_42_7092:           ; id $0059
    ; "*:You are strong! I like you, / [HERO]."
    db $eb, $9f, $a3, $3c, $4c, $52, $62, $3e, $4f, $42, $62, $50, $51, $4f, $4c, $4b
    db $44, $63, $ef, $ee, $2c, $62, $49, $46, $48, $42, $62, $56, $4c, $52, $5e, $fa
    db $f7, $ef, $ee, $f6, $5f, $ef, $ee, $f7, $f0
TextStr_42_70bb:           ; id $005A
    ; "King:Oh, [HERO]! Did you bring / back Hale!? / King:What? Hale said he doesn't / want to come back to me? / King:..But he said he would / ra..."
    db $ea, $2e, $46, $4b, $44, $a3, $32, $45, $5e, $62, $f6, $63, $ef, $ee, $27, $46
    db $41, $62, $56, $4c, $52, $62, $3f, $4f, $46, $4b, $44, $fa, $f7, $ef, $ee, $3f
    db $3e, $40, $48, $62, $2b, $3e, $49, $42, $63, $64, $ef, $ee, $fa, $f7, $ef, $ee
    db $2e, $46, $4b, $44, $a3, $3a, $45, $3e, $51, $64, $62, $2b, $3e, $49, $42, $ef
    db $ee, $50, $3e, $46, $41, $62, $45, $42, $62, $41, $4c, $42, $50, $4b, $67, $fa
    db $f7, $ef, $ee, $54, $3e, $4b, $51, $62, $51, $4c, $62, $40, $4c, $4a, $42, $ef
    db $ee, $3f, $3e, $40, $48, $62, $51, $4c, $62, $4a, $42, $64, $fa, $f7, $ef, $ee
    db $2e, $46, $4b, $44, $a3, $5f, $5f, $25, $52, $51, $62, $45, $42, $ef, $ee, $50
    db $3e, $46, $41, $62, $45, $42, $62, $54, $4c, $52, $49, $41, $fa, $f7, $ef, $ee
    db $4f, $3e, $51, $45, $42, $4f, $62, $47, $4c, $46, $4b, $62, $56, $4c, $52, $64
    db $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $2b, $4a, $4a, $5f, $5f
    db $62, $2c, $62, $50, $42, $42, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46
    db $4b, $44, $a3, $2b, $4a, $4a, $a4, $62, $3c, $4c, $52, $ef, $ee, $50, $52, $4f
    db $42, $62, $3e, $4f, $42, $62, $44, $4c, $4c, $41, $fa, $f7, $ef, $ee, $54, $46
    db $51, $45, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f, $ef, $ee, $3a, $42
    db $49, $49, $62, $41, $4c, $4b, $42, $63, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44
    db $a3, $2c, $6a, $62, $4d, $49, $42, $3e, $50, $42, $41, $ef, $ee, $54, $46, $51
    db $45, $62, $56, $4c, $52, $4f, $fa, $f7, $ef, $ee, $4d, $42, $4f, $43, $4c, $4f
    db $4a, $3e, $4b, $40, $42, $63, $ef, $ee, $2c, $62, $54, $46, $49, $49, $62, $49
    db $42, $51, $62, $33, $52, $49, $46, $4c, $fa, $f7, $ef, $ee, $44, $4c, $63, $ef
    db $ee, $f7, $f0
TextStr_42_71fe:           ; id $005B
    ; "Pulio:Thank you [HERO]! Now I / can go back to my farm!"
    db $eb, $33, $52, $49, $46, $4c, $a3, $37, $45, $3e, $4b, $48, $62, $56, $4c, $52
    db $ef, $ee, $f6, $63, $62, $31, $4c, $54, $62, $2c, $fa, $f7, $ef, $ee, $40, $3e
    db $4b, $62, $44, $4c, $62, $3f, $3e, $40, $48, $62, $51, $4c, $62, $4a, $56, $ef
    db $ee, $43, $3e, $4f, $4a, $63, $f7, $f0
TextStr_42_7236:           ; id $005C
    ; "King:[HERO]. Go to the arena. / King:Your rivals are waiting for / you at the arena. / King:You can compete in the / tournament if you defea..."
    db $ea, $2e, $46, $4b, $44, $a3, $f6, $5f, $ef, $ee, $2a, $4c, $62, $51, $4c, $62
    db $51, $45, $42, $62, $3e, $4f, $42, $4b, $3e, $5f, $fa, $f7, $ef, $ee, $2e, $46
    db $4b, $44, $a3, $3c, $4c, $52, $4f, $62, $4f, $46, $53, $3e, $49, $50, $ef, $ee
    db $3e, $4f, $42, $62, $54, $3e, $46, $51, $46, $4b, $44, $62, $43, $4c, $4f, $fa
    db $f7, $ef, $ee, $56, $4c, $52, $62, $3e, $51, $62, $51, $45, $42, $62, $3e, $4f
    db $42, $4b, $3e, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $3c
    db $4c, $52, $62, $40, $3e, $4b, $ef, $ee, $40, $4c, $4a, $4d, $42, $51, $42, $62
    db $46, $4b, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $51, $4c, $52, $4f, $4b, $3e
    db $4a, $42, $4b, $51, $62, $46, $43, $62, $56, $4c, $52, $ef, $ee, $41, $42, $43
    db $42, $3e, $51, $62, $3e, $49, $49, $62, $4c, $43, $fa, $f7, $ef, $ee, $51, $45
    db $42, $4a, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $3c, $4c
    db $52, $62, $3e, $4f, $42, $ef, $ee, $41, $46, $50, $4a, $46, $50, $50, $42, $41
    db $5f, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $25, $52, $50, $56, $63, $62
    db $25, $52, $50, $56, $63, $ef, $ee, $25, $52, $50, $56, $63, $f7, $f0
TextStr_42_7314:           ; id $005D
    ; "Slio:[HERO]! Congratulations / on your victory! / Slio:Grandpa Slib would be proud!"
    db $ea, $36, $49, $46, $4c, $a3, $f6, $63, $ef, $ee, $26, $4c, $4b, $44, $4f, $3e
    db $51, $52, $49, $3e, $51, $46, $4c, $4b, $50, $fa, $f7, $ef, $ee, $4c, $4b, $62
    db $56, $4c, $52, $4f, $62, $53, $46, $40, $51, $4c, $4f, $56, $63, $ef, $ee, $fa
    db $f7, $ef, $ee, $36, $49, $46, $4c, $a3, $2a, $4f, $3e, $4b, $41, $4d, $3e, $62
    db $36, $49, $46, $3f, $ef, $ee, $54, $4c, $52, $49, $41, $62, $3f, $42, $62, $4d
    db $4f, $4c, $52, $41, $63, $f7, $f0
TextStr_42_736b:           ; id $005E
    ; "*:To get to the arena, go straight / out of the castle and go down. / *:If you survive in the arena, / you can compete in the tournament!"
    db $ea, $9f, $a3, $37, $4c, $62, $44, $42, $51, $62, $51, $4c, $62, $51, $45, $42
    db $ef, $ee, $3e, $4f, $42, $4b, $3e, $5e, $62, $44, $4c, $62, $50, $51, $4f, $3e
    db $46, $44, $45, $51, $fa, $f7, $ef, $ee, $4c, $52, $51, $62, $4c, $43, $62, $51
    db $45, $42, $62, $40, $3e, $50, $51, $49, $42, $ef, $ee, $3e, $4b, $41, $62, $44
    db $4c, $62, $41, $4c, $54, $4b, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $43, $62
    db $56, $4c, $52, $62, $50, $52, $4f, $53, $46, $53, $42, $ef, $ee, $46, $4b, $62
    db $51, $45, $42, $62, $3e, $4f, $42, $4b, $3e, $5e, $fa, $f7, $ef, $ee, $56, $4c
    db $52, $62, $40, $3e, $4b, $62, $40, $4c, $4a, $4d, $42, $51, $42, $ef, $ee, $46
    db $4b, $62, $51, $45, $42, $62, $51, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51
    db $63, $f7, $f0
TextStr_42_73fe:           ; id $005F
    ; "*:These stairs go up to the / monster farm."
    db $ea, $9f, $a3, $37, $45, $42, $50, $42, $62, $50, $51, $3e, $46, $4f, $50, $62
    db $44, $4c, $ef, $ee, $52, $4d, $62, $51, $4c, $62, $51, $45, $42, $fa, $f7, $ef
    db $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $43, $3e, $4f, $4a, $5f, $ef, $ee
    db $f7, $f0
TextStr_42_7430:           ; id $0060
    ; "*:This is the castle of / GreatTree. / *:For the village of GreatTree, go / down and outside."
    db $ea, $9f, $a3, $37, $45, $46, $50, $62, $46, $50, $62, $51, $45, $42, $ef, $ee
    db $40, $3e, $50, $51, $49, $42, $62, $4c, $43, $fa, $f7, $ef, $ee, $2a, $4f, $42
    db $3e, $51, $37, $4f, $42, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $f3, $9f, $a3
    db $29, $4c, $4f, $62, $51, $45, $42, $62, $53, $46, $49, $49, $3e, $44, $42, $ef
    db $ee, $4c, $43, $62, $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $5e, $62, $44
    db $4c, $fa, $f7, $ef, $ee, $41, $4c, $54, $4b, $62, $3e, $4b, $41, $62, $4c, $52
    db $51, $50, $46, $41, $42, $5f, $ef, $ee, $f7, $f0
TextStr_42_749a:           ; id $0061
    ; "*:Oh boy! This looks dangerous! / Oh, no!"
    db $ea, $9f, $a3, $32, $45, $62, $3f, $4c, $56, $63, $62, $37, $45, $46, $50, $ef
    db $ee, $49, $4c, $4c, $48, $50, $62, $41, $3e, $4b, $44, $42, $4f, $4c, $52, $50
    db $63, $fa, $f7, $ef, $ee, $32, $45, $5e, $62, $4b, $4c, $63, $ef, $ee, $f7, $f0
TextStr_42_74ca:           ; id $0062
    ; "*:This is the village of / GreatTree. / *:The arena is over there in / the hole."
    db $eb, $9f, $a3, $37, $45, $46, $50, $62, $46, $50, $62, $51, $45, $42, $ef, $ee
    db $53, $46, $49, $49, $3e, $44, $42, $62, $4c, $43, $fa, $f7, $ef, $ee, $2a, $4f
    db $42, $3e, $51, $37, $4f, $42, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $f3, $9f
    db $a3, $37, $45, $42, $62, $3e, $4f, $42, $4b, $3e, $62, $46, $50, $ef, $ee, $4c
    db $53, $42, $4f, $62, $51, $45, $42, $4f, $42, $62, $46, $4b, $fa, $f7, $ef, $ee
    db $51, $45, $42, $62, $45, $4c, $49, $42, $5f, $ef, $ee, $f7, $f0
TextStr_42_7527:           ; id $0063
    ; "*:Fhew! I'm glad that I didn't get / hurt! I should be more careful."
    db $ea, $9f, $a3, $29, $45, $42, $54, $63, $62, $2c, $6a, $62, $44, $49, $3e, $41
    db $ef, $ee, $51, $45, $3e, $51, $62, $2c, $62, $41, $46, $41, $4b, $67, $62, $44
    db $42, $51, $fa, $f7, $ef, $ee, $45, $52, $4f, $51, $63, $62, $2c, $62, $50, $45
    db $4c, $52, $49, $41, $62, $3f, $42, $ef, $ee, $4a, $4c, $4f, $42, $62, $40, $3e
    db $4f, $42, $43, $52, $49, $5f, $f7, $f0
TextStr_42_756f:           ; id $0064
    ; "*:Oh [HERO], it's you. / I am getting old. / *:Just going down stairs hurts me. / *:You're going to the arena? / Good luck."
    db $ea, $9f, $a3, $32, $45, $62, $f6, $5e, $ef, $ee, $46, $51, $68, $62, $56, $4c
    db $52, $5f, $fa, $f7, $ef, $ee, $2c, $62, $3e, $4a, $62, $44, $42, $51, $51, $46
    db $4b, $44, $62, $4c, $49, $41, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2d
    db $52, $50, $51, $62, $44, $4c, $46, $4b, $44, $62, $41, $4c, $54, $4b, $ef, $ee
    db $50, $51, $3e, $46, $4f, $50, $62, $45, $52, $4f, $51, $50, $62, $4a, $42, $5f
    db $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $69, $42, $62, $44, $4c, $46, $4b
    db $44, $62, $51, $4c, $ef, $ee, $51, $45, $42, $62, $3e, $4f, $42, $4b, $3e, $64
    db $fa, $f7, $ef, $ee, $2a, $4c, $4c, $41, $62, $49, $52, $40, $48, $5f, $ef, $ee
    db $f7, $f0
TextStr_42_75f1:           ; id $0065
    ; "*:Once I picked up a TinyMedal, / *:back when I was on a journey / through the Travelers' Gate. / *:Oh! Let me tell you something / useful. ..."
    db $eb, $9f, $a3, $32, $4b, $40, $42, $62, $2c, $62, $4d, $46, $40, $48, $42, $41
    db $62, $52, $4d, $ef, $ee, $3e, $62, $37, $46, $4b, $56, $30, $42, $41, $3e, $49
    db $5e, $fa, $f7, $ef, $ee, $9f, $a3, $3f, $3e, $40, $48, $62, $54, $45, $42, $4b
    db $62, $2c, $62, $54, $3e, $50, $ef, $ee, $4c, $4b, $62, $3e, $62, $47, $4c, $52
    db $4f, $4b, $42, $56, $fa, $f7, $ef, $ee, $51, $45, $4f, $4c, $52, $44, $45, $62
    db $51, $45, $42, $ef, $ee, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $62
    db $2a, $3e, $51, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $32, $45, $63, $62, $2f
    db $42, $51, $62, $4a, $42, $ef, $ee, $51, $42, $49, $49, $62, $56, $4c, $52, $62
    db $50, $4c, $4a, $42, $51, $45, $46, $4b, $44, $fa, $f7, $ef, $ee, $52, $50, $42
    db $43, $52, $49, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25, $42, $56, $4c
    db $4b, $41, $62, $51, $45, $42, $ef, $ee, $37, $4f, $3e, $53, $42, $49, $42, $4f
    db $50, $5c, $62, $2a, $3e, $51, $42, $50, $5e, $fa, $f7, $ef, $ee, $50, $4c, $4a
    db $42, $51, $46, $4a, $42, $50, $62, $56, $4c, $52, $62, $40, $3e, $4b, $ef, $ee
    db $43, $46, $4b, $41, $62, $50, $4a, $3e, $49, $49, $62, $4f, $4c, $4c, $4a, $50
    db $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $62, $40, $3e, $4b, $62, $4f
    db $42, $40, $4c, $4f, $41, $ef, $ee, $56, $4c, $52, $4f, $62, $4e, $52, $42, $50
    db $51, $62, $46, $4b, $62, $56, $4c, $52, $4f, $fa, $f7, $ef, $ee, $2d, $4c, $52
    db $4f, $4b, $3e, $49, $62, $54, $45, $46, $49, $42, $62, $46, $4b, $ef, $ee, $51
    db $45, $4c, $50, $42, $62, $4f, $4c, $4c, $4a, $50, $5f, $fa, $f7, $ef, $ee, $9f
    db $a3, $37, $45, $4c, $50, $42, $62, $4f, $4c, $4c, $4a, $50, $62, $3e, $4f, $42
    db $ef, $ee, $51, $45, $42, $62, $4c, $4b, $49, $56, $62, $4d, $49, $3e, $40, $42
    db $50, $fa, $f7, $ef, $ee, $56, $4c, $52, $62, $40, $3e, $4b, $62, $4f, $42, $40
    db $4c, $4f, $41, $ef, $ee, $56, $4c, $52, $4f, $62, $4e, $52, $42, $50, $51, $62
    db $3f, $42, $56, $4c, $4b, $41, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $2a, $3e
    db $51, $42, $50, $5f, $ef, $ee, $f7, $f0
TextStr_42_7779:           ; id $0066
    ; "*:Would you like to see the list of / Travelers' Gates? [YES/NO]"
    db $ea, $9f, $a3, $3a, $4c, $52, $49, $41, $62, $56, $4c, $52, $62, $49, $46, $48
    db $42, $ef, $ee, $51, $4c, $62, $50, $42, $42, $62, $51, $45, $42, $62, $49, $46
    db $50, $51, $62, $4c, $43, $fa, $f7, $ef, $ee, $37, $4f, $3e, $53, $42, $49, $42
    db $4f, $50, $5c, $62, $2a, $3e, $51, $42, $50, $64, $ef, $ee, $ff, $f0
TextStr_42_77b7:           ; id $0067
    ; "*:You can enter the locked rooms / only when you win matches in / the arena. / *:They say that the masters who / won in the Starry Night Tou..."
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $40, $3e, $4b, $62, $42, $4b, $51, $42, $4f
    db $ef, $ee, $51, $45, $42, $62, $49, $4c, $40, $48, $42, $41, $62, $4f, $4c, $4c
    db $4a, $50, $fa, $f7, $ef, $ee, $4c, $4b, $49, $56, $62, $54, $45, $42, $4b, $62
    db $56, $4c, $52, $62, $54, $46, $4b, $ef, $ee, $4a, $3e, $51, $40, $45, $42, $50
    db $62, $46, $4b, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $3e, $4f, $42, $4b, $3e
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $56, $62, $50, $3e
    db $56, $62, $51, $45, $3e, $51, $ef, $ee, $51, $45, $42, $62, $4a, $3e, $50, $51
    db $42, $4f, $50, $62, $54, $45, $4c, $fa, $f7, $ef, $ee, $54, $4c, $4b, $62, $46
    db $4b, $62, $51, $45, $42, $62, $36, $51, $3e, $4f, $4f, $56, $ef, $ee, $31, $46
    db $44, $45, $51, $62, $37, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $fa, $f7
    db $ef, $ee, $46, $4b, $62, $51, $45, $42, $62, $4d, $3e, $50, $51, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $53, $46, $50, $46, $51, $42, $41, $62, $51, $45, $42
    db $62, $50, $3e, $4a, $42, $ef, $ee, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50
    db $5c, $62, $2a, $3e, $51, $42, $50, $fa, $f7, $ef, $ee, $3e, $44, $3e, $46, $4b
    db $62, $3e, $4b, $41, $62, $3e, $44, $3e, $46, $4b, $5e, $ef, $ee, $54, $45, $42
    db $4b, $62, $51, $45, $42, $56, $62, $40, $4c, $52, $49, $41, $4b, $67, $fa, $f7
    db $ef, $ee, $54, $46, $4b, $62, $3e, $62, $4a, $3e, $51, $40, $45, $5e, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $3e, $4b, $41, $62, $51, $4f, $3e, $46, $4b, $42
    db $41, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $4c, $4f, $62, $3e
    db $41, $41, $42, $41, $fa, $f7, $ef, $ee, $4b, $42, $54, $62, $4c, $4b, $42, $50
    db $5f, $ef, $ee, $f7, $f0
TextStr_42_78fc:           ; id $0068
    ; "*:Monsters have personalities too. / *:Depending on the PLAN used in / battles,their personalities / change. / *:When [CHARGE] is chosen, / ..."
    db $ea, $9f, $a3, $30, $4c, $4b, $50, $51, $42, $4f, $50, $62, $45, $3e, $53, $42
    db $ef, $ee, $4d, $42, $4f, $50, $4c, $4b, $3e, $49, $46, $51, $46, $42, $50, $62
    db $51, $4c, $4c, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $27, $42, $4d, $42, $4b, $41
    db $46, $4b, $44, $62, $4c, $4b, $62, $51, $45, $42, $ef, $ee, $33, $2f, $24, $31
    db $62, $52, $50, $42, $41, $62, $46, $4b, $fa, $f7, $ef, $ee, $3f, $3e, $51, $51
    db $49, $42, $50, $5e, $51, $45, $42, $46, $4f, $ef, $ee, $4d, $42, $4f, $50, $4c
    db $4b, $3e, $49, $46, $51, $46, $42, $50, $fa, $f7, $ef, $ee, $40, $45, $3e, $4b
    db $44, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45, $42, $4b, $62
    db $96, $26, $2b, $24, $35, $2a, $28, $97, $ef, $ee, $46, $50, $62, $40, $45, $4c
    db $50, $42, $4b, $5e, $fa, $f7, $ef, $ee, $51, $45, $42, $56, $62, $3f, $42, $40
    db $4c, $4a, $42, $62, $3f, $4f, $3e, $53, $42, $ef, $ee, $4a, $4c, $4b, $50, $51
    db $42, $4f, $50, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45, $42, $4b
    db $62, $96, $30, $2c, $3b, $28, $27, $97, $ef, $ee, $46, $50, $62, $40, $45, $4c
    db $50, $42, $4b, $5e, $fa, $f7, $ef, $ee, $51, $45, $42, $56, $62, $3f, $42, $40
    db $4c, $4a, $42, $ef, $ee, $51, $45, $4c, $52, $44, $45, $51, $43, $52, $49, $5f
    db $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3e, $4b, $41, $62, $54, $45, $42, $4b
    db $ef, $ee, $96, $26, $24, $38, $37, $2c, $32, $38, $36, $97, $62, $46, $50, $fa
    db $f7, $ef, $ee, $40, $45, $4c, $50, $42, $4b, $62, $51, $45, $42, $56, $62, $3f
    db $42, $40, $4c, $4a, $42, $ef, $ee, $40, $4c, $4b, $50, $46, $41, $42, $4f, $3e
    db $51, $42, $5f, $f7, $f0
TextStr_42_7a31:           ; id $0069
    ; "*:Hey Master! D'ya have an egg? [YES/NO]"
    db $ea, $9f, $a3, $2b, $42, $56, $62, $30, $3e, $50, $51, $42, $4f, $63, $62, $27
    db $6b, $3e, $ef, $ee, $45, $3e, $53, $42, $62, $3e, $4b, $62, $42, $44, $44, $64
    db $ff, $f0
TextStr_42_7a53:           ; id $006A
    ; "Splat... Poop hit [HERO]."
    db $36, $4d, $49, $3e, $51, $5f, $5f, $5f, $ef, $ee, $33, $4c, $4c, $4d, $62, $45
    db $46, $51, $62, $f6, $5f, $f7, $f0
TextStr_42_7a6a:           ; id $006B
    ; "Thwack! / It was the egg of a SkyDragon that / hit [HERO]'s head!!"
    db $37, $45, $54, $3e, $40, $48, $63, $ef, $ee, $fa, $f7, $ef, $ee, $f3, $2c, $51
    db $62, $54, $3e, $50, $62, $51, $45, $42, $62, $42, $44, $44, $62, $4c, $43, $ef
    db $ee, $3e, $62, $36, $48, $56, $27, $4f, $3e, $44, $4c, $4b, $62, $51, $45, $3e
    db $51, $fa, $f7, $ef, $ee, $45, $46, $51, $62, $f6, $68, $ef, $ee, $45, $42, $3e
    db $41, $63, $63, $f7, $f0
TextStr_42_7aaf:           ; id $006C
    ; "[HERO] took the egg of a / SkyDragon! / But, eggs cannot be carried around. / The egg was left with Pulio on the / farm!"
    db $f6, $62, $51, $4c, $4c, $48, $62, $51, $45, $42, $ef, $ee, $42, $44, $44, $62
    db $4c, $43, $62, $3e, $fa, $f7, $ef, $ee, $36, $48, $56, $27, $4f, $3e, $44, $4c
    db $4b, $63, $ef, $ee, $fa, $f7, $ef, $ee, $25, $52, $51, $5e, $62, $42, $44, $44
    db $50, $62, $40, $3e, $4b, $4b, $4c, $51, $ef, $ee, $3f, $42, $62, $40, $3e, $4f
    db $4f, $46, $42, $41, $62, $3e, $4f, $4c, $52, $4b, $41, $5f, $fa, $f7, $ef, $ee
    db $37, $45, $42, $62, $42, $44, $44, $62, $54, $3e, $50, $62, $49, $42, $43, $51
    db $ef, $ee, $54, $46, $51, $45, $62, $33, $52, $49, $46, $4c, $62, $4c, $4b, $62
    db $51, $45, $42, $fa, $f7, $ef, $ee, $43, $3e, $4f, $4a, $63, $ef, $ee, $f7, $f0
TextStr_42_7b2f:           ; id $006D
    ; "Could not keep the egg because there / are too many monster friends. / The egg was left at the farm / because eggs cannot be / carried out. ..."
    db $26, $4c, $52, $49, $41, $62, $4b, $4c, $51, $62, $48, $42, $42, $4d, $62, $51
    db $45, $42, $ef, $ee, $42, $44, $44, $62, $3f, $42, $40, $3e, $52, $50, $42, $62
    db $51, $45, $42, $4f, $42, $fa, $f7, $ef, $ee, $3e, $4f, $42, $62, $51, $4c, $4c
    db $62, $4a, $3e, $4b, $56, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $43
    db $4f, $46, $42, $4b, $41, $50, $5f, $fa, $f7, $ef, $ee, $37, $45, $42, $62, $42
    db $44, $44, $62, $54, $3e, $50, $62, $49, $42, $43, $51, $ef, $ee, $3e, $51, $62
    db $51, $45, $42, $62, $43, $3e, $4f, $4a, $fa, $f7, $ef, $ee, $3f, $42, $40, $3e
    db $52, $50, $42, $62, $42, $44, $44, $50, $ef, $ee, $40, $3e, $4b, $4b, $4c, $51
    db $62, $3f, $42, $fa, $f7, $ef, $ee, $40, $3e, $4f, $4f, $46, $42, $41, $62, $4c
    db $52, $51, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $26, $4c, $4a, $42, $62, $3f, $3e
    db $40, $48, $62, $3e, $44, $3e, $46, $4b, $ef, $ee, $54, $45, $42, $4b, $62, $56
    db $4c, $52, $62, $45, $3e, $53, $42, $fa, $f7, $ef, $ee, $4f, $4c, $4c, $4a, $62
    db $43, $4c, $4f, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f, $ef, $ee, $f7
    db $f0
TextStr_42_7c00:           ; id $006E
    ; "Splash! Poop hit [HERO]."
    db $36, $4d, $49, $3e, $50, $45, $63, $ef, $ee, $33, $4c, $4c, $4d, $62, $45, $46
    db $51, $62, $f6, $5f, $f7, $f0
TextStr_42_7c16:           ; id $006F
    ; "*:Treats! BeefJerky, / PorkChop, Rib. / *:BeefJerky is the least tasty! / *:Ribs are better than PorkChops. / *:But Sirloin is the best! / I..."
    db $ea, $9f, $a3, $37, $4f, $42, $3e, $51, $50, $63, $ef, $ee, $25, $42, $42, $43
    db $2d, $42, $4f, $48, $56, $5e, $fa, $f7, $ef, $ee, $33, $4c, $4f, $48, $26, $45
    db $4c, $4d, $5e, $ef, $ee, $35, $46, $3f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $25
    db $42, $42, $43, $2d, $42, $4f, $48, $56, $62, $46, $50, $ef, $ee, $51, $45, $42
    db $62, $49, $42, $3e, $50, $51, $62, $51, $3e, $50, $51, $56, $63, $fa, $f7, $ef
    db $ee, $9f, $a3, $35, $46, $3f, $50, $62, $3e, $4f, $42, $62, $3f, $42, $51, $51
    db $42, $4f, $ef, $ee, $51, $45, $3e, $4b, $62, $33, $4c, $4f, $48, $26, $45, $4c
    db $4d, $50, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $25, $52, $51, $62, $36, $46, $4f
    db $49, $4c, $46, $4b, $62, $46, $50, $ef, $ee, $51, $45, $42, $62, $3f, $42, $50
    db $51, $63, $fa, $f7, $ef, $ee, $2c, $51, $68, $62, $3e, $50, $62, $56, $52, $4a
    db $4a, $56, $ef, $ee, $3e, $50, $62, $40, $3e, $4b, $62, $3f, $42, $63, $f7, $f0
TextStr_42_7cc6:           ; id $0070
    ; "*:If you take monsters on a / journey, they become attached / to you. / *:When they are left on the farm / all the time, they will not / lis..."
    db $ea, $9f, $a3, $2c, $43, $62, $56, $4c, $52, $62, $51, $3e, $48, $42, $ef, $ee
    db $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $4c, $4b, $62, $3e, $fa, $f7, $ef
    db $ee, $47, $4c, $52, $4f, $4b, $42, $56, $5e, $62, $51, $45, $42, $56, $ef, $ee
    db $3f, $42, $40, $4c, $4a, $42, $62, $3e, $51, $51, $3e, $40, $45, $42, $41, $fa
    db $f7, $ef, $ee, $51, $4c, $62, $56, $4c, $52, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $3a, $45, $42, $4b, $62, $51, $45, $42, $56, $62, $3e, $4f, $42, $ef
    db $ee, $49, $42, $43, $51, $62, $4c, $4b, $62, $51, $45, $42, $62, $43, $3e, $4f
    db $4a, $fa, $f7, $ef, $ee, $3e, $49, $49, $62, $51, $45, $42, $62, $51, $46, $4a
    db $42, $5e, $ef, $ee, $51, $45, $42, $56, $62, $54, $46, $49, $49, $62, $4b, $4c
    db $51, $fa, $f7, $ef, $ee, $49, $46, $50, $51, $42, $4b, $62, $51, $4c, $62, $56
    db $4c, $52, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25, $52, $51, $5e, $46
    db $43, $62, $56, $4c, $52, $62, $44, $46, $53, $42, $ef, $ee, $51, $45, $42, $4a
    db $62, $51, $4f, $42, $3e, $51, $50, $5e, $fa, $f7, $ef, $ee, $51, $45, $42, $56
    db $62, $54, $46, $49, $49, $62, $3f, $42, $40, $4c, $4a, $42, $ef, $ee, $4f, $42
    db $42, $42, $3e, $49, $49, $56, $62, $3e, $51, $51, $3e, $40, $45, $42, $41, $fa
    db $f7, $ef, $ee, $51, $4c, $62, $56, $4c, $52, $63, $ef, $ee, $f7, $f0, $00
; --- END re-sectioned text run (bank $42) ---
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

