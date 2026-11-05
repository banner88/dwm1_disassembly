; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $048", ROMX[$4000], BANK[$48]

    db $48 ; Bank number

    ; Cross-bank dispatch table (112 entries)
    ; Called via: ld hl, $48XX / rst $10
    dw LoadB48_40e1                  ; Entry 0
    dw TextRunB48_410f               ; Entry 1
    dw TextShowRefreshB48_413d       ; Entry 2
    dw $4009                          ; Entry 3 — mode 0 -> table $4009 (mode list $4007)
    dw TextStr_48_416b               ; Entry 4 — [table $4009]; text $0474 "Durran:Come on Terry! Fight to yo…"
    dw TextStr_48_41d2               ; Entry 5 — text $0475 "Durran:Ha ha ha! How easily you d…"
    dw TextStr_48_4294               ; Entry 6 — text $0476 "Durran:Want a real thrill? Fight …"
    dw TextStr_48_42ff               ; Entry 7 — text $0477 "Durran:How was it? Learn anything…"
    dw TextStr_48_435d               ; Entry 8 — text $0478 "Durran:Here I come!!"
    dw TextStr_48_4375               ; Entry 9 — text $0479 "Durran:Did I lose? .. I lost... D…"
    dw TextStr_48_44b1               ; Entry 10 — text $047A "TERRY?:..You're strong... You eve…"
    dw TextStr_48_45fc               ; Entry 11 — text $047B "Do you really want to tell your t…"
    dw TextStr_48_4636               ; Entry 12 — text $047C "TERRY?:It's okay. I know..."
    dw TextStr_48_4655               ; Entry 13 — text $047D "TERRY?:No. It's okay... I know..."
    dw TextStr_48_467a               ; Entry 14 — text $047E "*:Good luck on your journey!"
    dw TextStr_48_469a               ; Entry 15 — text $047F "TERRY?:Ahhh... For some reason, I…"
    dw TextStr_48_477f               ; Entry 16 — text $0480 "TERRY?:[HERO], don't become like …"
    dw TextStr_48_485f               ; Entry 17 — text $0481 "TERRY?:Farewell [HERO]! I'm takin…"
    dw TextStr_48_48b0               ; Entry 18 — text $0482 "TERRY?:Take care of your sister. …"
    dw TextStr_48_48ea               ; Entry 19 — text $0483 "TERRY?:...You don't want to hear …"
    dw TextStr_48_4962               ; Entry 20 — text $0484 "Watabou:Let's go back!"
    dw TextStr_48_497b               ; Entry 21 — text $0485 "King:[HERO]! How was it? What lie…"
    dw TextStr_48_4aa9               ; Entry 22 — text $0486 "King:Oh [HERO]! Did you rest? Kin…"
    dw TextStr_48_4b62               ; Entry 23 — text $0487 "*:You're at the Chamber of Travel…"
    dw TextStr_48_4c3f               ; Entry 24 — text $0488 "King:Anyway! Your wish will come …"
    dw TextStr_48_4e5a               ; Entry 25 — text $0489 "*:Now, head to the arena! *:A gre…"
    dw TextStr_48_4eaf               ; Entry 26 — text $048A "*:Let me tell you the legend of t…"
    dw TextStr_48_506e               ; Entry 27 — text $048B "*:Oh bless Starry Night and Maste…"
    dw TextStr_48_509c               ; Entry 28 — text $048C "*:Long long ago.. an ancestor of …"
    dw TextStr_48_51aa               ; Entry 29 — text $048D "*:You're at the castle of GreatTr…"
    dw TextStr_48_51f7               ; Entry 30 — text $048E "*:Good luck at the Starry Night T…"
    dw TextStr_48_5239               ; Entry 31 — text $048F "*:You don't have it? You should b…"
    dw TextStr_48_52cc               ; Entry 32 — text $0490 "*:Bring them to the Medal Man ups…"
    dw TextStr_48_533f               ; Entry 33 — text $0491 "*:Many people are heading to Grea…"
    dw TextStr_48_53b5               ; Entry 34 — text $0492 "*:Watabou will be happy if you wi…"
    dw TextStr_48_542c               ; Entry 35 — text $0493 "*:You can win! ...I feel it! *:I …"
    dw TextStr_48_54b9               ; Entry 36 — text $0494 "*:Proceed to the Vault. Good luck!"
    dw TextStr_48_54df               ; Entry 37 — text $0495 "*:Go right to the Bazaar! *:It's …"
    dw TextStr_48_5524               ; Entry 38 — text $0496 "*:Go right to the Bazaar! *:Oh [H…"
    dw TextStr_48_5568               ; Entry 39 — text $0497 "*:Are you... really competing in …"
    dw TextStr_48_55a1               ; Entry 40 — text $0498 "*:...Don't lose."
    dw TextStr_48_55b5               ; Entry 41 — text $0499 "*:...Don't lose. Don't make me sa…"
    dw TextStr_48_55f0               ; Entry 42 — text $049A "*:You're right! It's impossible f…"
    dw TextStr_48_5629               ; Entry 43 — text $049B "*:...you. Don't you regret saying…"
    dw TextStr_48_5658               ; Entry 44 — text $049C "*:The Master Monster Tamer downst…"
    dw TextStr_48_56b5               ; Entry 45 — text $049D "*:A surprise awaits you in your f…"
    dw TextStr_48_5726               ; Entry 46 — text $049E "*:I wish you good luck! All rooms…"
    dw TextStr_48_57f4               ; Entry 47 — text $049F "*:All Gates are now yours! *:The …"
    dw TextStr_48_58af               ; Entry 48 — text $04A0 "*:What kind of future did you see…"
    dw TextStr_48_593a               ; Entry 49 — text $04A1 "*:We'll spend the Starry Night, t…"
    dw TextStr_48_597f               ; Entry 50 — text $04A2 "*:Hello. Down to the stable. Blea…"
    dw TextStr_48_59f3               ; Entry 51 — text $04A3 "*:The Starry Night is soon. Yeah!…"
    dw TextStr_48_5a27               ; Entry 52 — text $04A4 "*:There's something good about ha…"
    dw TextStr_48_5a67               ; Entry 53 — text $04A5 "*:As the Starry Night nears, I wa…"
    dw TextStr_48_5aa4               ; Entry 54 — text $04A6 "*:As the Starry Night nears, it m…"
    dw TextStr_48_5b12               ; Entry 55 — text $04A7 "*:Power is flowing all around me!…"
    dw TextStr_48_5b66               ; Entry 56 — text $04A8 "*:When the Starry Night nears, my…"
    dw TextStr_48_5ba2               ; Entry 57 — text $04A9 "*:Zzz..... ..zzz. Bust! *:Mm? Is …"
    dw TextStr_48_5be8               ; Entry 58 — text $04AA "*:I feel it! GreatTree is shaking…"
    dw TextStr_48_5c4f               ; Entry 59 — text $04AB "*:Of course GreatTree will triump…"
    dw TextStr_48_5c7b               ; Entry 60 — text $04AC "*:It's GreatLog! GreatLog, will c…"
    dw TextStr_48_5cb1               ; Entry 61 — text $04AD "*:I believe DeadTree will be vict…"
    dw TextStr_48_5ce2               ; Entry 62 — text $04AE "*:You win, GreatTree happy. Eek!"
    dw TextStr_48_5d0b               ; Entry 63 — text $04AF "*:You made it! Good job! *:Fight …"
    dw TextStr_48_5d5f               ; Entry 64 — text $04B0 "*:Let me know when you're ready."
    dw TextStr_48_5d82               ; Entry 65 — text $04B1 "*:Announcing the rep of GreatTree…"
    dw TextStr_48_5db0               ; Entry 66 — text $04B2 "*:The Starry Night Tournament is …"
    dw TextStr_48_5e79               ; Entry 67 — text $04B3 "*:Want to listen to the descripti…"
    dw TextStr_48_5eb8               ; Entry 68 — text $04B4 "*:Everybody in the kingdom is beh…"
    dw TextStr_48_5f05               ; Entry 69 — text $04B5 "*:You made it! *:I can't even com…"
    dw TextStr_48_5f4b               ; Entry 70 — text $04B6 "*:Oh! Its a HornBeet! What a magn…"
    dw TextStr_48_5fb0               ; Entry 71 — text $04B7 "*:Wyvern!"
    dw TextStr_48_5fbe               ; Entry 72 — text $04B8 "*:Come on! Pray! Pray to the stat…"
    dw TextStr_48_602c               ; Entry 73 — text $04B9 "[HERO] reads the blackboard. :The…"
    dw TextStr_48_60a0               ; Entry 74 — text $04BA "*:Here is MysticNut. Use it wisel…"
    dw TextStr_48_60cc               ; Entry 75 — text $04BB "*:My heart is pounding! The battl…"
    dw TextStr_48_616a               ; Entry 76 — text $04BC "*:This is Shoyu! Bebe! Repeat aft…"
    dw TextStr_48_61a0               ; Entry 77 — text $04BD "*:What the heck is Shoyu! Can't y…"
    dw TextStr_48_61de               ; Entry 78 — text $04BE "*:Splash Splash! When the Starry …"
    dw TextStr_48_624d               ; Entry 79 — text $04BF "*:I would like to go deep in the …"
    dw TextStr_48_62f0               ; Entry 80 — text $04C0 "[HERO] looked at the bookshelf. :…"
    dw TextStr_48_6383               ; Entry 81 — text $04C1 ":[HERO] already conquered D class…"
    dw TextStr_48_646b               ; Entry 82 — text $04C2 ":At last [HERO] will participate …"
    dw TextStr_48_64e0               ; Entry 83 — text $04C3 "*:The combination with the same m…"
    dw TextStr_48_65d3               ; Entry 84 — text $04C4 "*:Many Stars fall from the sky on…"
    dw TextStr_48_6634               ; Entry 85 — text $04C5 "*:Do you know my daughter? [YES/N…"
    dw TextStr_48_6652               ; Entry 86 — text $04C6 "*:No!? You don't know such a cute…"
    dw TextStr_48_66d1               ; Entry 87 — text $04C7 "*:She's the most graceful girl in…"
    dw TextStr_48_6713               ; Entry 88 — text $04C8 "*:You're promising! Let me tell y…"
    dw TextStr_48_6813               ; Entry 89 — text $04C9 "*:My hubby adores our girl.. *:Re…"
    dw TextStr_48_6857               ; Entry 90 — text $04CA ":Journal of My Baby, Part 3 :Flat…"
    dw TextStr_48_691e               ; Entry 91 — text $04CB ":Journal of My Baby, Part 4 :I gu…"
    dw TextStr_48_69cc               ; Entry 92 — text $04CC "*:I heard a wish will come true w…"
    dw TextStr_48_6acb               ; Entry 93 — text $04CD "*:I'm looking for a book. *:I can…"
    dw TextStr_48_6b4f               ; Entry 94 — text $04CE "*:I am the Monster Minister. All …"
    dw TextStr_48_6bc7               ; Entry 95 — text $04CF "*:How about the monsters behind t…"
    dw TextStr_48_6c1a               ; Entry 96 — text $04D0 "*:Behind the Gate of Joy live Sna…"
    dw TextStr_48_6d13               ; Entry 97 — text $04D1 "*:How about the monsters behind t…"
    dw TextStr_48_6d70               ; Entry 98 — text $04D2 "*:Behind the Gate of Happiness li…"
    dw TextStr_48_6e6a               ; Entry 99 — text $04D3 "*:How about the monsters behind t…"
    dw TextStr_48_6ec4               ; Entry 100 — text $04D4 "*:Behind the Gate of Labyrinth li…"
    dw TextStr_48_6ff5               ; Entry 101 — text $04D5 "*:How about the monsters living b…"
    dw TextStr_48_704c               ; Entry 102 — text $04D6 "*:Behind the Gate of Reflection l…"
    dw TextStr_48_7116               ; Entry 103 — text $04D7 "*:I will do anything for you!"
    dw TextStr_48_7137               ; Entry 104 — text $04D8 "*:Ha ha ha! I made Gigantes brave…"
    dw TextStr_48_71a2               ; Entry 105 — text $04D9 "*:Oh, you have it! Then... *:Hm? …"
    dw TextStr_48_7228               ; Entry 106 — text $04DA "*:Flaring.... I am MadCandle. *:M…"
    dw TextStr_48_72bb               ; Entry 107 — text $04DB "*:You must listen to my request! …"
    dw TextStr_48_7319               ; Entry 108 — text $04DC "*:Oh, it is a Reaper! What a shar…"
    dw TextStr_48_737a               ; Entry 109 — text $04DD "*:[HERO], lemme tell you. *:I hea…"
    dw TextStr_48_7411               ; Entry 110 — text $04DE "*:[HERO]! You are the first perso…"
    dw TextStr_48_74ad               ; Entry 111 — text $04DF "*:Ladies & Gents! Welcome! *:Toni…"

LoadB48_40e1:
    ld a, [$c822]
    cp $01
    jr nz, jr_048_40f2

    ld a, $02
    ld [$c822], a
    ld hl, $1f00
    rst $10
    ret


jr_048_40f2:
    ld a, [$c823]
    cp $6c
    jr c, jr_048_4108

    sub $6c
    ld [$c823], a
    ld a, $01
    ld [$c822], a
    ld hl, $1f00
    rst $10
    ret


jr_048_4108:
    ld de, $4007
    call CallTextEngine
    ret


; [S166] copy a text of this bank (RunTextHandler); ids past the bank's range go to its overflow bank (TEXT_SYSTEM "Text id resolution")
TextRunB48_410f:
    ld a, [$c822]
    cp $01
    jr nz, jr_048_4120

    ld a, $02
    ld [$c822], a
    ld hl, $1f01
    rst $10
    ret


jr_048_4120:
    ld a, [$c823]
    cp $6c
    jr c, jr_048_4136

    sub $6c
    ld [$c823], a
    ld a, $01
    ld [$c822], a
    ld hl, $1f01
    rst $10
    ret


jr_048_4136:
    ld de, $4007
    call RunTextHandler
    ret


; [S166] show a text (entry 0) then RequestScreenUpdate
TextShowRefreshB48_413d:
    ld a, [$c822]
    cp $01
    jr nz, jr_048_414e

    ld a, $02
    ld [$c822], a

jr_048_4149:
    ld hl, $1f02
    rst $10
    ret


jr_048_414e:
    ld a, [$c823]
    cp $6c
    jr c, jr_048_4164

    sub $6c
    ld [$c823], a
    ld a, $01
    ld [$c822], a
    ld hl, $1f02
    rst $10
    ret


jr_048_4164:
    call LoadB48_40e1
    call RequestScreenUpdate
    ret


; --- BEGIN re-sectioned text run (bank $48: $416b-$75f2) ---
; DTE-encoded dialogue strings, one label per text id (text_id_map.json).
; Labels/comments only; bytes are byte-identical to the original ROM.
TextStr_48_416b:           ; id $0474
    ; "Durran:Come on Terry! Fight / to your heart's content. / Durran:Show him how tough / you are!"
    db $ea, $27, $52, $4f, $4f, $3e, $4b, $a3, $26, $4c, $4a, $42, $62, $4c, $4b, $ef
    db $ee, $37, $42, $4f, $4f, $56, $63, $62, $29, $46, $44, $45, $51, $fa, $f7, $ef
    db $ee, $51, $4c, $62, $56, $4c, $52, $4f, $62, $45, $42, $3e, $4f, $51, $68, $ef
    db $ee, $40, $4c, $4b, $51, $42, $4b, $51, $5f, $fa, $f7, $ef, $ee, $27, $52, $4f
    db $4f, $3e, $4b, $a3, $36, $45, $4c, $54, $ef, $ee, $45, $46, $4a, $62, $45, $4c
    db $54, $62, $51, $4c, $52, $44, $45, $fa, $f7, $ef, $ee, $56, $4c, $52, $62, $3e
    db $4f, $42, $63, $ef, $ee, $f7, $f0
TextStr_48_41d2:           ; id $0475
    ; "Durran:Ha ha ha! How easily you / defeated such a brutal opponent!! / Durran:You're not bad! You're my / kind of fighter. / Durran:To have s..."
    db $ea, $27, $52, $4f, $4f, $3e, $4b, $a3, $2b, $3e, $62, $45, $3e, $62, $45, $3e
    db $63, $ef, $ee, $2b, $4c, $54, $62, $42, $3e, $50, $46, $49, $56, $62, $56, $4c
    db $52, $fa, $f7, $ef, $ee, $41, $42, $43, $42, $3e, $51, $42, $41, $62, $50, $52
    db $40, $45, $62, $3e, $ef, $ee, $3f, $4f, $52, $51, $3e, $49, $62, $4c, $4d, $4d
    db $4c, $4b, $42, $4b, $51, $63, $63, $fa, $f7, $ef, $ee, $27, $52, $4f, $4f, $3e
    db $4b, $a3, $3c, $4c, $52, $69, $42, $62, $4b, $4c, $51, $ef, $ee, $3f, $3e, $41
    db $63, $62, $3c, $4c, $52, $69, $42, $62, $4a, $56, $fa, $f7, $ef, $ee, $48, $46
    db $4b, $41, $62, $4c, $43, $62, $43, $46, $44, $45, $51, $42, $4f, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $27, $52, $4f, $4f, $3e, $4b, $a3, $37, $4c, $62, $45, $3e
    db $53, $42, $ef, $ee, $50, $52, $40, $45, $62, $3e, $62, $43, $46, $44, $45, $51
    db $42, $4f, $fa, $f7, $ef, $ee, $50, $4c, $62, $4b, $42, $3e, $4f, $5f, $5f, $5f
    db $ef, $ee, $5f, $5f, $5f, $51, $45, $4f, $46, $49, $49, $46, $4b, $44, $63, $63
    db $f7, $f0
TextStr_48_4294:           ; id $0476
    ; "Durran:Want a real thrill? / Fight me! / Durran:Satisfy my blood lust! Taste / my steel! Fight!"
    db $ea, $27, $52, $4f, $4f, $3e, $4b, $a3, $3a, $3e, $4b, $51, $62, $3e, $ef, $ee
    db $4f, $42, $3e, $49, $62, $51, $45, $4f, $46, $49, $49, $64, $fa, $f7, $ef, $ee
    db $29, $46, $44, $45, $51, $62, $4a, $42, $63, $ef, $ee, $fa, $f7, $ef, $ee, $27
    db $52, $4f, $4f, $3e, $4b, $a3, $36, $3e, $51, $46, $50, $43, $56, $62, $4a, $56
    db $ef, $ee, $3f, $49, $4c, $4c, $41, $62, $49, $52, $50, $51, $63, $62, $37, $3e
    db $50, $51, $42, $fa, $f7, $ef, $ee, $4a, $56, $62, $50, $51, $42, $42, $49, $63
    db $62, $29, $46, $44, $45, $51, $63, $ef, $ee, $f7, $f0
TextStr_48_42ff:           ; id $0477
    ; "Durran:How was it? Learn anything? / Durran:A man like you... / I could fight again..."
    db $ea, $27, $52, $4f, $4f, $3e, $4b, $a3, $2b, $4c, $54, $62, $54, $3e, $50, $62
    db $46, $51, $64, $ef, $ee, $2f, $42, $3e, $4f, $4b, $62, $3e, $4b, $56, $51, $45
    db $46, $4b, $44, $64, $fa, $f7, $ef, $ee, $27, $52, $4f, $4f, $3e, $4b, $a3, $24
    db $62, $4a, $3e, $4b, $62, $49, $46, $48, $42, $ef, $ee, $56, $4c, $52, $5f, $5f
    db $5f, $fa, $f7, $ef, $ee, $2c, $62, $40, $4c, $52, $49, $41, $ef, $ee, $43, $46
    db $44, $45, $51, $62, $3e, $44, $3e, $46, $4b, $5f, $5f, $5f, $f7, $f0
TextStr_48_435d:           ; id $0478
    ; "Durran:Here I come!!"
    db $ea, $27, $52, $4f, $4f, $3e, $4b, $a3, $2b, $42, $4f, $42, $ef, $ee, $2c, $62
    db $40, $4c, $4a, $42, $63, $63, $f7, $f0
TextStr_48_4375:           ; id $0479
    ; "Durran:Did I lose? .. I lost... / Durran:You fought masterfully! / I was utterly defeated. / Durran:I didn't think a monster / master of you..."
    db $ea, $27, $52, $4f, $4f, $3e, $4b, $a3, $27, $46, $41, $62, $2c, $62, $49, $4c
    db $50, $42, $64, $ef, $ee, $5f, $5f, $62, $2c, $62, $49, $4c, $50, $51, $5f, $5f
    db $5f, $fa, $f7, $ef, $ee, $27, $52, $4f, $4f, $3e, $4b, $a3, $3c, $4c, $52, $62
    db $43, $4c, $52, $44, $45, $51, $ef, $ee, $4a, $3e, $50, $51, $42, $4f, $43, $52
    db $49, $49, $56, $63, $fa, $f7, $ef, $ee, $2c, $62, $54, $3e, $50, $62, $52, $51
    db $51, $42, $4f, $49, $56, $ef, $ee, $41, $42, $43, $42, $3e, $51, $42, $41, $5f
    db $fa, $f7, $ef, $ee, $27, $52, $4f, $4f, $3e, $4b, $a3, $2c, $62, $41, $46, $41
    db $4b, $67, $ef, $ee, $51, $45, $46, $4b, $48, $62, $3e, $62, $4a, $4c, $4b, $50
    db $51, $42, $4f, $fa, $f7, $ef, $ee, $4a, $3e, $50, $51, $42, $4f, $62, $4c, $43
    db $62, $56, $4c, $52, $4f, $ef, $ee, $40, $3e, $49, $46, $3f, $42, $4f, $62, $42
    db $55, $46, $50, $51, $42, $41, $5f, $fa, $f7, $ef, $ee, $27, $52, $4f, $4f, $3e
    db $4b, $a3, $2f, $4c, $4c, $48, $63, $62, $2c, $6a, $ef, $ee, $50, $51, $46, $49
    db $49, $62, $50, $45, $3e, $48, $46, $4b, $44, $fa, $f7, $ef, $ee, $43, $4f, $4c
    db $4a, $62, $51, $45, $42, $ef, $ee, $42, $55, $40, $46, $51, $42, $4a, $42, $4b
    db $51, $63, $fa, $f7, $ef, $ee, $27, $52, $4f, $4f, $3e, $4b, $a3, $2c, $6a, $ef
    db $ee, $45, $4c, $4b, $4c, $4f, $42, $41, $62, $51, $4c, $62, $45, $3e, $53, $42
    db $fa, $f7, $ef, $ee, $45, $3e, $41, $62, $51, $45, $42, $62, $40, $45, $3e, $4b
    db $40, $42, $ef, $ee, $51, $4c, $62, $43, $46, $44, $45, $51, $62, $56, $4c, $52
    db $5f, $fa, $f7, $ef, $ee, $27, $52, $4f, $4f, $3e, $4b, $a3, $2b, $3e, $62, $45
    db $3e, $ef, $ee, $45, $3e, $62, $45, $3e, $63, $63, $f7, $f0
TextStr_48_44b1:           ; id $047A
    ; "TERRY?:..You're strong... / You even defeated him... / TERRY?:I couldn't beat ...that guy! / TERRY?:I mocked you. Calling you a / coward. So..."
    db $ea, $37, $28, $35, $35, $3c, $64, $a3, $5f, $5f, $3c, $4c, $52, $69, $42, $ef
    db $ee, $50, $51, $4f, $4c, $4b, $44, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $3c, $4c
    db $52, $62, $42, $53, $42, $4b, $62, $41, $42, $43, $42, $3e, $51, $42, $41, $ef
    db $ee, $45, $46, $4a, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $37, $28, $35, $35, $3c
    db $64, $a3, $2c, $62, $40, $4c, $52, $49, $41, $4b, $67, $ef, $ee, $3f, $42, $3e
    db $51, $62, $5f, $5f, $5f, $51, $45, $3e, $51, $62, $44, $52, $56, $63, $fa, $f7
    db $ef, $ee, $37, $28, $35, $35, $3c, $64, $a3, $2c, $62, $4a, $4c, $40, $48, $42
    db $41, $ef, $ee, $56, $4c, $52, $5f, $62, $26, $3e, $49, $49, $46, $4b, $44, $62
    db $56, $4c, $52, $62, $3e, $fa, $f7, $ef, $ee, $40, $4c, $54, $3e, $4f, $41, $5f
    db $62, $36, $4c, $4a, $42, $4c, $4b, $42, $ef, $ee, $54, $45, $4c, $62, $40, $3e
    db $4b, $67, $62, $42, $53, $42, $4b, $62, $52, $50, $42, $fa, $f7, $ef, $ee, $3e
    db $62, $50, $54, $4c, $4f, $41, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $37
    db $28, $35, $35, $3c, $64, $a3, $2c, $62, $51, $3e, $48, $42, $ef, $ee, $46, $51
    db $62, $3f, $3e, $40, $48, $5f, $62, $3c, $4c, $52, $69, $42, $fa, $f7, $ef, $ee
    db $46, $4b, $53, $46, $4b, $40, $46, $3f, $49, $42, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $37, $28, $35, $35, $3c, $64, $a3, $28, $53, $42, $4b, $ef, $ee, $54, $46
    db $51, $45, $4c, $52, $51, $62, $3e, $62, $50, $54, $4c, $4f, $41, $5e, $fa, $f7
    db $ef, $ee, $56, $4c, $52, $69, $42, $62, $51, $45, $42, $62, $3f, $42, $50, $51
    db $ef, $ee, $43, $46, $44, $45, $51, $42, $4f, $5f, $fa, $f7, $ef, $ee, $37, $28
    db $35, $35, $3c, $64, $a3, $5f, $5f, $5f, $3a, $45, $3e, $51, $68, $ef, $ee, $56
    db $4c, $52, $4f, $62, $4b, $3e, $4a, $42, $64, $f7, $f0
TextStr_48_45fc:           ; id $047B
    ; "Do you really want to tell your / true name to TERRY? [YES/NO]"
    db $27, $4c, $62, $56, $4c, $52, $62, $4f, $42, $3e, $49, $49, $56, $ef, $ee, $54
    db $3e, $4b, $51, $62, $51, $4c, $62, $51, $42, $49, $49, $62, $56, $4c, $52, $4f
    db $fa, $f7, $ef, $ee, $51, $4f, $52, $42, $62, $4b, $3e, $4a, $42, $62, $51, $4c
    db $ef, $ee, $37, $28, $35, $35, $3c, $64, $ff, $f0
TextStr_48_4636:           ; id $047C
    ; "TERRY?:It's okay. I know..."
    db $ea, $37, $28, $35, $35, $3c, $64, $a3, $2c, $51, $68, $62, $4c, $48, $3e, $56
    db $5f, $ef, $ee, $2c, $62, $48, $4b, $4c, $54, $5f, $5f, $5f, $fa, $f7, $f0
TextStr_48_4655:           ; id $047D
    ; "TERRY?:No. It's okay... I know..."
    db $ea, $37, $28, $35, $35, $3c, $64, $a3, $31, $4c, $5f, $62, $2c, $51, $68, $ef
    db $ee, $4c, $48, $3e, $56, $5f, $5f, $5f, $62, $2c, $62, $48, $4b, $4c, $54, $5f
    db $5f, $5f, $fa, $f7, $f0
TextStr_48_467a:           ; id $047E
    ; "*:Good luck on your journey!"
    db $ea, $9f, $a3, $2a, $4c, $4c, $41, $62, $49, $52, $40, $48, $62, $4c, $4b, $ef
    db $ee, $56, $4c, $52, $4f, $62, $47, $4c, $52, $4f, $4b, $42, $56, $63, $f7, $f0
TextStr_48_469a:           ; id $047F
    ; "TERRY?:Ahhh... For some reason, / I feel relieved. / TERRY?:... It's morning...time / to wake up. / TERRY?:So long [HERO]! Will we / meet ag..."
    db $ea, $37, $28, $35, $35, $3c, $64, $a3, $24, $45, $45, $45, $5f, $5f, $5f, $ef
    db $ee, $29, $4c, $4f, $62, $50, $4c, $4a, $42, $62, $4f, $42, $3e, $50, $4c, $4b
    db $5e, $fa, $f7, $ef, $ee, $2c, $62, $43, $42, $42, $49, $62, $4f, $42, $49, $46
    db $42, $53, $42, $41, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $37, $28, $35, $35, $3c
    db $64, $a3, $5f, $5f, $5f, $62, $2c, $51, $68, $ef, $ee, $4a, $4c, $4f, $4b, $46
    db $4b, $44, $5f, $5f, $5f, $51, $46, $4a, $42, $fa, $f7, $ef, $ee, $51, $4c, $62
    db $54, $3e, $48, $42, $62, $52, $4d, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $37, $28
    db $35, $35, $3c, $64, $a3, $36, $4c, $62, $49, $4c, $4b, $44, $ef, $ee, $f6, $63
    db $62, $3a, $46, $49, $49, $62, $54, $42, $fa, $f7, $ef, $ee, $4a, $42, $42, $51
    db $62, $3e, $44, $3e, $46, $4b, $64, $ef, $ee, $fa, $f7, $ef, $ee, $37, $28, $35
    db $35, $3c, $64, $a3, $31, $4c, $5e, $62, $4a, $3e, $56, $3f, $42, $ef, $ee, $54
    db $42, $62, $50, $45, $4c, $52, $49, $41, $4b, $67, $5f, $fa, $f7, $ef, $ee, $37
    db $28, $35, $35, $3c, $64, $a3, $2f, $42, $51, $62, $4a, $42, $62, $44, $46, $53
    db $42, $ef, $ee, $56, $4c, $52, $62, $50, $4c, $4a, $42, $62, $3e, $41, $53, $46
    db $40, $42, $5f, $f7, $f0
TextStr_48_477f:           ; id $0480
    ; "TERRY?:[HERO], don't become / like me. / TERRY?:Once you've tasted power, you / gorge upon it and it will choke you. / TERRY?:Perhaps it's t..."
    db $ea, $37, $28, $35, $35, $3c, $64, $a3, $f6, $5e, $ef, $ee, $41, $4c, $4b, $67
    db $62, $3f, $42, $40, $4c, $4a, $42, $62, $fa, $f7, $ef, $ee, $49, $46, $48, $42
    db $62, $4a, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $37, $28, $35, $35, $3c, $64
    db $a3, $32, $4b, $40, $42, $62, $56, $4c, $52, $6c, $42, $ef, $ee, $51, $3e, $50
    db $51, $42, $41, $62, $4d, $4c, $54, $42, $4f, $5e, $62, $56, $4c, $52, $fa, $f7
    db $ef, $ee, $44, $4c, $4f, $44, $42, $62, $52, $4d, $4c, $4b, $62, $46, $51, $62
    db $3e, $4b, $41, $ef, $ee, $46, $51, $62, $54, $46, $49, $49, $62, $40, $45, $4c
    db $48, $42, $62, $56, $4c, $52, $5f, $fa, $f7, $ef, $ee, $37, $28, $35, $35, $3c
    db $64, $a3, $33, $42, $4f, $45, $3e, $4d, $50, $ef, $ee, $46, $51, $68, $62, $51
    db $4c, $4c, $62, $49, $3e, $51, $42, $62, $43, $4c, $4f, $fa, $f7, $ef, $ee, $4a
    db $42, $5f, $62, $25, $52, $51, $62, $56, $4c, $52, $62, $40, $3e, $4b, $ef, $ee
    db $50, $51, $46, $49, $49, $62, $40, $45, $4c, $4c, $50, $42, $5f, $fa, $f7, $ef
    db $ee, $3c, $4c, $52, $62, $41, $4c, $4b, $67, $62, $54, $3e, $4b, $51, $62, $51
    db $4c, $ef, $ee, $3f, $42, $62, $49, $46, $48, $42, $62, $4a, $42, $5f, $f7, $f0
TextStr_48_485f:           ; id $0481
    ; "TERRY?:Farewell [HERO]! / I'm taking off. / TERRY?:One more piece of advice... [YES/NO]"
    db $ea, $37, $28, $35, $35, $3c, $64, $a3, $29, $3e, $4f, $42, $54, $42, $49, $49
    db $ef, $ee, $f6, $63, $fa, $f7, $ef, $ee, $2c, $6a, $62, $51, $3e, $48, $46, $4b
    db $44, $62, $4c, $43, $43, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $37, $28, $35, $35
    db $3c, $64, $a3, $32, $4b, $42, $62, $4a, $4c, $4f, $42, $ef, $ee, $4d, $46, $42
    db $40, $42, $62, $4c, $43, $62, $3e, $41, $53, $46, $40, $42, $5f, $5f, $5f, $ff
    db $f0
TextStr_48_48b0:           ; id $0482
    ; "TERRY?:Take care of your sister. / No matter what!!"
    db $ea, $37, $28, $35, $35, $3c, $64, $a3, $37, $3e, $48, $42, $62, $40, $3e, $4f
    db $42, $ef, $ee, $4c, $43, $62, $56, $4c, $52, $4f, $62, $50, $46, $50, $51, $42
    db $4f, $5f, $fa, $f7, $ef, $ee, $31, $4c, $62, $4a, $3e, $51, $51, $42, $4f, $62
    db $54, $45, $3e, $51, $63, $63, $ef, $ee, $f7, $f0
TextStr_48_48ea:           ; id $0483
    ; "TERRY?:...You don't want to / hear this, but I'll say it. / TERRY?:Take care of your sister. / No matter what!!"
    db $ea, $37, $28, $35, $35, $3c, $64, $a3, $5f, $5f, $5f, $3c, $4c, $52, $ef, $ee
    db $41, $4c, $4b, $67, $62, $54, $3e, $4b, $51, $62, $51, $4c, $fa, $f7, $ef, $ee
    db $45, $42, $3e, $4f, $62, $51, $45, $46, $50, $5e, $ef, $ee, $3f, $52, $51, $62
    db $2c, $66, $49, $62, $50, $3e, $56, $62, $46, $51, $5f, $fa, $f7, $ef, $ee, $37
    db $28, $35, $35, $3c, $64, $a3, $37, $3e, $48, $42, $62, $40, $3e, $4f, $42, $ef
    db $ee, $4c, $43, $62, $56, $4c, $52, $4f, $62, $50, $46, $50, $51, $42, $4f, $5f
    db $fa, $f7, $ef, $ee, $31, $4c, $62, $4a, $3e, $51, $51, $42, $4f, $62, $54, $45
    db $3e, $51, $63, $63, $ef, $ee, $f7, $f0
TextStr_48_4962:           ; id $0484
    ; "Watabou:Let's go back!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $2f, $42, $51, $68, $ef, $ee, $44
    db $4c, $62, $3f, $3e, $40, $48, $63, $f7, $f0
TextStr_48_497b:           ; id $0485
    ; "King:[HERO]! How was it? / What lies in your future? / King:What? You didn't find out / about the tournament? / King:...Hmmm. ....Hmmm.. / K..."
    db $ea, $2e, $46, $4b, $44, $a3, $f6, $63, $ef, $ee, $2b, $4c, $54, $62, $54, $3e
    db $50, $62, $46, $51, $64, $fa, $f7, $ef, $ee, $3a, $45, $3e, $51, $62, $49, $46
    db $42, $50, $62, $46, $4b, $ef, $ee, $56, $4c, $52, $4f, $62, $43, $52, $51, $52
    db $4f, $42, $64, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $3a, $45, $3e, $51
    db $64, $62, $3c, $4c, $52, $ef, $ee, $41, $46, $41, $4b, $67, $62, $43, $46, $4b
    db $41, $62, $4c, $52, $51, $fa, $f7, $ef, $ee, $3e, $3f, $4c, $52, $51, $62, $51
    db $45, $42, $ef, $ee, $51, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $64, $fa
    db $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $5f, $5f, $5f, $2b, $4a, $4a, $4a, $5f
    db $ef, $ee, $5f, $5f, $5f, $5f, $2b, $4a, $4a, $4a, $5f, $5f, $fa, $f7, $ef, $ee
    db $2e, $46, $4b, $44, $a3, $2c, $51, $62, $41, $4c, $42, $50, $4b, $67, $ef, $ee
    db $4a, $3e, $51, $51, $42, $4f, $5f, $62, $3c, $4c, $52, $69, $42, $fa, $f7, $ef
    db $ee, $44, $4c, $46, $4b, $44, $62, $51, $4c, $62, $54, $46, $4b, $ef, $ee, $3e
    db $4b, $56, $54, $3e, $56, $63, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $37
    db $45, $42, $62, $36, $51, $3e, $4f, $4f, $56, $ef, $ee, $31, $46, $44, $45, $51
    db $62, $46, $50, $fa, $f7, $ef, $ee, $3e, $4d, $4d, $4f, $4c, $3e, $40, $45, $46
    db $4b, $44, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $33, $4f
    db $42, $4d, $3e, $4f, $42, $ef, $ee, $56, $4c, $52, $4f, $50, $42, $49, $43, $62
    db $3e, $4b, $41, $62, $4f, $42, $50, $51, $fa, $f7, $ef, $ee, $56, $4c, $52, $4f
    db $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f, $ef, $ee, $f7, $f0
TextStr_48_4aa9:           ; id $0486
    ; "King:Oh [HERO]! Did you rest? / King:Tonight is the night! of / the Tournament! / King:Masters from a far are waiting / for you in the arena..."
    db $ea, $2e, $46, $4b, $44, $a3, $32, $45, $62, $f6, $63, $ef, $ee, $27, $46, $41
    db $62, $56, $4c, $52, $62, $4f, $42, $50, $51, $64, $fa, $f7, $ef, $ee, $2e, $46
    db $4b, $44, $a3, $37, $4c, $4b, $46, $44, $45, $51, $ef, $ee, $46, $50, $62, $51
    db $45, $42, $62, $4b, $46, $44, $45, $51, $63, $62, $4c, $43, $fa, $f7, $ef, $ee
    db $51, $45, $42, $62, $37, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $63, $ef
    db $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $30, $3e, $50, $51, $42, $4f
    db $50, $62, $43, $4f, $4c, $4a, $ef, $ee, $3e, $62, $43, $3e, $4f, $62, $3e, $4f
    db $42, $62, $54, $3e, $46, $51, $46, $4b, $44, $fa, $f7, $ef, $ee, $43, $4c, $4f
    db $62, $56, $4c, $52, $62, $46, $4b, $62, $51, $45, $42, $ef, $ee, $3e, $4f, $42
    db $4b, $3e, $63, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $25, $42, $3e, $51
    db $62, $51, $45, $42, $4a, $ef, $ee, $46, $4b, $51, $4c, $62, $51, $45, $42, $62
    db $44, $4f, $4c, $52, $4b, $41, $63, $f7, $f0
TextStr_48_4b62:           ; id $0487
    ; "*:You're at the Chamber of / Travelers' Gates. / *:Healer can heal monsters with its / spell. / *:It's very useful on a journey so / you sho..."
    db $ea, $9f, $a3, $3c, $4c, $52, $69, $42, $62, $3e, $51, $62, $51, $45, $42, $ef
    db $ee, $26, $45, $3e, $4a, $3f, $42, $4f, $62, $4c, $43, $fa, $f7, $ef, $ee, $37
    db $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $62, $2a, $3e, $51, $42, $50, $5f
    db $ef, $ee, $fa, $f7, $ef, $ee, $f3, $9f, $a3, $2b, $42, $3e, $49, $42, $4f, $62
    db $40, $3e, $4b, $62, $45, $42, $3e, $49, $ef, $ee, $4a, $4c, $4b, $50, $51, $42
    db $4f, $50, $62, $54, $46, $51, $45, $62, $46, $51, $50, $fa, $f7, $ef, $ee, $50
    db $4d, $42, $49, $49, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $51, $68
    db $62, $53, $42, $4f, $56, $62, $52, $50, $42, $43, $52, $49, $ef, $ee, $4c, $4b
    db $62, $3e, $62, $47, $4c, $52, $4f, $4b, $42, $56, $62, $50, $4c, $fa, $f7, $ef
    db $ee, $56, $4c, $52, $62, $50, $45, $4c, $52, $49, $41, $4b, $67, $62, $49, $42
    db $51, $ef, $ee, $46, $51, $62, $44, $4c, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $30
    db $33, $62, $54, $46, $49, $49, $62, $4f, $42, $40, $4c, $53, $42, $4f, $ef, $ee
    db $44, $4f, $3e, $41, $52, $3e, $49, $49, $56, $62, $3e, $50, $62, $56, $4c, $52
    db $fa, $f7, $ef, $ee, $54, $3e, $49, $48, $63, $ef, $ee, $f7, $f0
TextStr_48_4c3f:           ; id $0488
    ; "King:Anyway! Your wish will come / true when you win the tournament. / King:I thought it was to find / your kidnapped sister... / King:or wa..."
    db $ea, $2e, $46, $4b, $44, $a3, $24, $4b, $56, $54, $3e, $56, $63, $62, $3c, $4c
    db $52, $4f, $ef, $ee, $54, $46, $50, $45, $62, $54, $46, $49, $49, $62, $40, $4c
    db $4a, $42, $fa, $f7, $ef, $ee, $51, $4f, $52, $42, $62, $54, $45, $42, $4b, $62
    db $56, $4c, $52, $62, $54, $46, $4b, $ef, $ee, $51, $45, $42, $62, $51, $4c, $52
    db $4f, $4b, $3e, $4a, $42, $4b, $51, $5f, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44
    db $a3, $2c, $62, $51, $45, $4c, $52, $44, $45, $51, $ef, $ee, $46, $51, $62, $54
    db $3e, $50, $62, $51, $4c, $62, $43, $46, $4b, $41, $fa, $f7, $ef, $ee, $56, $4c
    db $52, $4f, $62, $48, $46, $41, $4b, $3e, $4d, $4d, $42, $41, $ef, $ee, $50, $46
    db $50, $51, $42, $4f, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3
    db $4c, $4f, $62, $54, $3e, $50, $62, $46, $51, $62, $51, $4c, $ef, $ee, $44, $4c
    db $62, $3f, $3e, $40, $48, $62, $51, $4c, $62, $56, $4c, $52, $4f, $fa, $f7, $ef
    db $ee, $45, $4c, $4a, $42, $62, $54, $4c, $4f, $49, $41, $5f, $5f, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $35, $42, $44, $3e, $4f, $41, $49
    db $42, $50, $50, $5e, $ef, $ee, $56, $4c, $52, $6c, $42, $62, $54, $4c, $4f, $48
    db $42, $41, $fa, $f7, $ef, $ee, $53, $42, $4f, $56, $62, $45, $3e, $4f, $41, $63
    db $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $25, $4c, $51, $45, $62
    db $51, $45, $42, $ef, $ee, $4d, $42, $4c, $4d, $49, $42, $62, $4c, $43, $62, $4a
    db $56, $fa, $f7, $ef, $ee, $48, $46, $4b, $44, $41, $4c, $4a, $62, $3e, $4b, $41
    db $62, $2c, $ef, $ee, $51, $4f, $52, $50, $51, $62, $56, $4c, $52, $4f, $fa, $f7
    db $ef, $ee, $3e, $3f, $46, $49, $46, $51, $56, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $2e, $46, $4b, $44, $a3, $3c, $4c, $52, $5f, $62, $3c, $4c, $52, $62, $54, $46
    db $49, $49, $ef, $ee, $3f, $4f, $46, $4b, $44, $62, $44, $49, $4c, $4f, $56, $62
    db $51, $4c, $fa, $f7, $ef, $ee, $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $63
    db $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $2c, $51, $68, $62, $52
    db $4d, $62, $51, $4c, $ef, $ee, $56, $4c, $52, $62, $4b, $4c, $54, $62, $4a, $3e
    db $50, $51, $42, $4f, $fa, $f7, $ef, $ee, $f6, $63, $ef, $ee, $fa, $f7, $ef, $ee
    db $2e, $46, $4b, $44, $a3, $32, $45, $62, $3f, $49, $42, $50, $50, $ef, $ee, $2a
    db $4f, $42, $3e, $51, $37, $4f, $42, $42, $62, $b6, $62, $56, $4c, $52, $63, $63
    db $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $2c, $62, $45, $3e, $53, $42, $62
    db $51, $4c, $ef, $ee, $4d, $4f, $42, $4d, $3e, $4f, $42, $62, $43, $4c, $4f, $fa
    db $f7, $ef, $ee, $51, $45, $42, $62, $51, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b
    db $51, $5f, $ef, $ee, $27, $46, $50, $4a, $46, $50, $50, $42, $41, $63, $fa, $f7
    db $ef, $ee, $2e, $46, $4b, $44, $a3, $25, $52, $50, $56, $63, $62, $25, $52, $50
    db $56, $63, $ef, $ee, $25, $52, $50, $56, $63, $f7, $f0
TextStr_48_4e5a:           ; id $0489
    ; "*:Now, head to the arena! / *:A great audience is waiting for / you Master [HERO]!"
    db $ea, $9f, $a3, $31, $4c, $54, $5e, $62, $45, $42, $3e, $41, $62, $51, $4c, $ef
    db $ee, $51, $45, $42, $62, $3e, $4f, $42, $4b, $3e, $63, $fa, $f7, $ef, $ee, $9f
    db $a3, $24, $62, $44, $4f, $42, $3e, $51, $62, $3e, $52, $41, $46, $42, $4b, $40
    db $42, $ef, $ee, $46, $50, $62, $54, $3e, $46, $51, $46, $4b, $44, $62, $43, $4c
    db $4f, $fa, $f7, $ef, $ee, $56, $4c, $52, $62, $30, $3e, $50, $51, $42, $4f, $ef
    db $ee, $f6, $63, $f7, $f0
TextStr_48_4eaf:           ; id $048A
    ; "*:Let me tell you the legend of the / Starry Night again. / *:The Starry Night comes after every / 47th full moon. / *:Hundreds of thousands..."
    db $eb, $9f, $a3, $2f, $42, $51, $62, $4a, $42, $62, $51, $42, $49, $49, $62, $56
    db $4c, $52, $ef, $ee, $51, $45, $42, $62, $49, $42, $44, $42, $4b, $41, $62, $4c
    db $43, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $36, $51, $3e, $4f, $4f, $56, $62
    db $31, $46, $44, $45, $51, $ef, $ee, $3e, $44, $3e, $46, $4b, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $37, $45, $42, $62, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46
    db $44, $45, $51, $ef, $ee, $40, $4c, $4a, $42, $50, $62, $3e, $43, $51, $42, $4f
    db $62, $42, $53, $42, $4f, $56, $fa, $f7, $ef, $ee, $04, $07, $51, $45, $62, $43
    db $52, $49, $49, $62, $4a, $4c, $4c, $4b, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $2b, $52, $4b, $41, $4f, $42, $41, $50, $62, $4c, $43, $ef, $ee, $51, $45
    db $4c, $52, $50, $3e, $4b, $41, $50, $62, $4c, $43, $62, $50, $51, $3e, $4f, $50
    db $fa, $f7, $ef, $ee, $9f, $a3, $43, $3e, $49, $49, $62, $3e, $4b, $41, $62, $43
    db $46, $49, $49, $ef, $ee, $51, $45, $42, $62, $50, $48, $56, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $2b, $52, $4b, $41, $4f, $42, $41, $50, $62, $4c, $43, $ef, $ee
    db $51, $45, $4c, $52, $50, $3e, $4b, $41, $50, $62, $4c, $43, $62, $50, $51, $3e
    db $4f, $50, $fa, $f7, $ef, $ee, $9f, $a3, $40, $4c, $53, $42, $4f, $62, $51, $45
    db $42, $62, $54, $4c, $4f, $49, $41, $ef, $ee, $54, $46, $51, $45, $62, $49, $46
    db $44, $45, $51, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $3e, $51, $68, $62
    db $51, $45, $42, $ef, $ee, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45
    db $51, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $4b, $46, $44, $45
    db $51, $62, $54, $45, $42, $4b, $ef, $ee, $40, $4c, $52, $4b, $51, $49, $42, $50
    db $50, $62, $49, $46, $53, $42, $50, $fa, $f7, $ef, $ee, $50, $45, $4c, $54, $42
    db $4f, $62, $41, $4c, $54, $4b, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37
    db $4c, $62, $40, $42, $49, $42, $3f, $4f, $3e, $51, $42, $5e, $ef, $ee, $3e, $62
    db $44, $4f, $42, $3e, $51, $fa, $f7, $ef, $ee, $51, $4c, $52, $4f, $4b, $3e, $4a
    db $42, $4b, $51, $62, $46, $50, $ef, $ee, $45, $42, $49, $41, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $37, $45, $46, $50, $62, $46, $50, $62, $51, $45, $42, $ef, $ee
    db $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45, $51, $fa, $f7, $ef, $ee
    db $37, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $5f, $ef, $ee, $f7, $f0
TextStr_48_506e:           ; id $048B
    ; "*:Oh bless Starry Night and / Master [HERO]!"
    db $eb, $9f, $a3, $32, $45, $62, $3f, $49, $42, $50, $50, $ef, $ee, $36, $51, $3e
    db $4f, $4f, $56, $62, $31, $46, $44, $45, $51, $62, $3e, $4b, $41, $fa, $f7, $ef
    db $ee, $30, $3e, $50, $51, $42, $4f, $62, $f6, $63, $ef, $ee, $f7, $f0
TextStr_48_509c:           ; id $048C
    ; "*:Long long ago.. an ancestor of / Watabou locked the monsters... / *:behind the Travelers' Gates / because they were harmful to humans. / *..."
    db $eb, $9f, $a3, $2f, $4c, $4b, $44, $62, $49, $4c, $4b, $44, $62, $3e, $44, $4c
    db $5f, $5f, $ef, $ee, $3e, $4b, $62, $3e, $4b, $40, $42, $50, $51, $4c, $4f, $62
    db $4c, $43, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $62, $49, $4c
    db $40, $48, $42, $41, $ef, $ee, $51, $45, $42, $62, $4a, $4c, $4b, $50, $51, $42
    db $4f, $50, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3f, $42, $45, $46, $4b
    db $41, $62, $51, $45, $42, $ef, $ee, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50
    db $5c, $62, $2a, $3e, $51, $42, $50, $fa, $f7, $ef, $ee, $3f, $42, $40, $3e, $52
    db $50, $42, $62, $51, $45, $42, $56, $62, $54, $42, $4f, $42, $ef, $ee, $45, $3e
    db $4f, $4a, $43, $52, $49, $62, $51, $4c, $62, $45, $52, $4a, $3e, $4b, $50, $5f
    db $fa, $f7, $ef, $ee, $9f, $a3, $32, $52, $4f, $62, $3e, $4b, $40, $42, $50, $51
    db $4c, $4f, $50, $ef, $ee, $41, $42, $4a, $3e, $4b, $41, $42, $41, $62, $54, $42
    db $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $45, $4c, $49, $41, $62, $3e, $ef
    db $ee, $51, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $62, $42, $53, $42, $4f
    db $56, $fa, $f7, $ef, $ee, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45
    db $51, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $30, $3e, $50, $51, $42, $4f
    db $62, $f6, $ef, $ee, $54, $46, $4b, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $51
    db $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $63, $ef, $ee, $f7, $f0
TextStr_48_51aa:           ; id $048D
    ; "*:You're at the castle of / GreatTree. Good luck at the / tournament!"
    db $ea, $9f, $a3, $3c, $4c, $52, $69, $42, $62, $3e, $51, $62, $51, $45, $42, $ef
    db $ee, $40, $3e, $50, $51, $49, $42, $62, $4c, $43, $fa, $f7, $ef, $ee, $2a, $4f
    db $42, $3e, $51, $37, $4f, $42, $42, $5f, $ef, $ee, $2a, $4c, $4c, $41, $62, $49
    db $52, $40, $48, $62, $3e, $51, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $51, $4c
    db $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $63, $ef, $ee, $f7, $f0
TextStr_48_51f7:           ; id $048E
    ; "*:Good luck at the Starry Night / Tournament! We're with you!"
    db $eb, $9f, $a3, $2a, $4c, $4c, $41, $62, $49, $52, $40, $48, $62, $3e, $51, $62
    db $51, $45, $42, $ef, $ee, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45
    db $51, $fa, $f7, $ef, $ee, $37, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $63
    db $ef, $ee, $3a, $42, $69, $42, $62, $54, $46, $51, $45, $62, $56, $4c, $52, $63
    db $f7, $f0
TextStr_48_5239:           ; id $048F
    ; "*:You don't have it? You should be / able to find it somewhere on the / ground. / *:I thought you would be busy with / the tournament."
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $41, $4c, $4b, $67, $62, $45, $3e, $53, $42
    db $ef, $ee, $46, $51, $64, $62, $3c, $4c, $52, $62, $50, $45, $4c, $52, $49, $41
    db $62, $3f, $42, $fa, $f7, $ef, $ee, $3e, $3f, $49, $42, $62, $51, $4c, $62, $43
    db $46, $4b, $41, $62, $46, $51, $ef, $ee, $50, $4c, $4a, $42, $54, $45, $42, $4f
    db $42, $62, $4c, $4b, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $44, $4f, $4c, $52
    db $4b, $41, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $51, $45, $4c
    db $52, $44, $45, $51, $62, $56, $4c, $52, $ef, $ee, $54, $4c, $52, $49, $41, $62
    db $3f, $42, $62, $3f, $52, $50, $56, $62, $54, $46, $51, $45, $fa, $f7, $ef, $ee
    db $51, $45, $42, $62, $51, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $5f, $ef
    db $ee, $f7, $f0
TextStr_48_52cc:           ; id $0490
    ; "*:Bring them to the Medal Man / upstairs. He'll be thrilled! / *:But that man is really / restless today."
    db $ea, $9f, $a3, $25, $4f, $46, $4b, $44, $62, $51, $45, $42, $4a, $62, $51, $4c
    db $ef, $ee, $51, $45, $42, $62, $30, $42, $41, $3e, $49, $62, $30, $3e, $4b, $fa
    db $f7, $ef, $ee, $52, $4d, $50, $51, $3e, $46, $4f, $50, $5f, $62, $2b, $42, $66
    db $49, $ef, $ee, $3f, $42, $62, $51, $45, $4f, $46, $49, $49, $42, $41, $63, $fa
    db $f7, $ef, $ee, $9f, $a3, $25, $52, $51, $62, $51, $45, $3e, $51, $62, $4a, $3e
    db $4b, $ef, $ee, $46, $50, $62, $4f, $42, $3e, $49, $49, $56, $fa, $f7, $ef, $ee
    db $4f, $42, $50, $51, $49, $42, $50, $50, $62, $51, $4c, $41, $3e, $56, $5f, $ef
    db $ee, $f7, $f0
TextStr_48_533f:           ; id $0491
    ; "*:Many people are heading to / GreatTree. / *:The arena will be packed by the / time the tournament starts!"
    db $eb, $9f, $a3, $30, $3e, $4b, $56, $62, $4d, $42, $4c, $4d, $49, $42, $62, $3e
    db $4f, $42, $ef, $ee, $45, $42, $3e, $41, $46, $4b, $44, $62, $51, $4c, $fa, $f7
    db $ef, $ee, $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $37, $45, $42, $62, $3e, $4f, $42, $4b, $3e, $62, $54, $46
    db $49, $49, $ef, $ee, $3f, $42, $62, $4d, $3e, $40, $48, $42, $41, $62, $3f, $56
    db $62, $51, $45, $42, $fa, $f7, $ef, $ee, $51, $46, $4a, $42, $62, $51, $45, $42
    db $ef, $ee, $51, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $62, $50, $51, $3e
    db $4f, $51, $50, $63, $f7, $f0
TextStr_48_53b5:           ; id $0492
    ; "*:Watabou will be happy if you / win! / *:It says so in the book from the / library. I wonder what it means?"
    db $ea, $9f, $a3, $3a, $3e, $51, $3e, $3f, $4c, $52, $62, $54, $46, $49, $49, $ef
    db $ee, $3f, $42, $62, $45, $3e, $4d, $4d, $56, $62, $46, $43, $62, $56, $4c, $52
    db $fa, $f7, $ef, $ee, $54, $46, $4b, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $2c, $51, $62, $50, $3e, $56, $50, $62, $50, $4c, $62, $46, $4b, $ef, $ee, $51
    db $45, $42, $62, $3f, $4c, $4c, $48, $62, $43, $4f, $4c, $4a, $62, $51, $45, $42
    db $fa, $f7, $ef, $ee, $49, $46, $3f, $4f, $3e, $4f, $56, $5f, $62, $2c, $62, $54
    db $4c, $4b, $41, $42, $4f, $ef, $ee, $54, $45, $3e, $51, $62, $46, $51, $62, $4a
    db $42, $3e, $4b, $50, $64, $f7, $f0
TextStr_48_542c:           ; id $0493
    ; "*:You can win! ...I feel it! / *:I heard a wish will come true / if you win... / *:But I'll be be satisfied with / your victory."
    db $eb, $9f, $a3, $3c, $4c, $52, $62, $40, $3e, $4b, $62, $54, $46, $4b, $63, $ef
    db $ee, $5f, $5f, $5f, $2c, $62, $43, $42, $42, $49, $62, $46, $51, $63, $fa, $f7
    db $ef, $ee, $9f, $a3, $2c, $62, $45, $42, $3e, $4f, $41, $62, $3e, $62, $54, $46
    db $50, $45, $ef, $ee, $54, $46, $49, $49, $62, $40, $4c, $4a, $42, $62, $51, $4f
    db $52, $42, $fa, $f7, $ef, $ee, $46, $43, $62, $56, $4c, $52, $62, $54, $46, $4b
    db $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25, $52, $51, $62, $2c
    db $66, $49, $62, $3f, $42, $ef, $ee, $3f, $42, $62, $50, $3e, $51, $46, $50, $43
    db $46, $42, $41, $62, $54, $46, $51, $45, $fa, $f7, $ef, $ee, $56, $4c, $52, $4f
    db $62, $53, $46, $40, $51, $4c, $4f, $56, $5f, $ef, $ee, $f7, $f0
TextStr_48_54b9:           ; id $0494
    ; "*:Proceed to the Vault. Good luck!"
    db $ea, $9f, $a3, $33, $4f, $4c, $40, $42, $42, $41, $62, $51, $4c, $62, $51, $45
    db $42, $ef, $ee, $39, $3e, $52, $49, $51, $5f, $62, $2a, $4c, $4c, $41, $62, $49
    db $52, $40, $48, $63, $f7, $f0
TextStr_48_54df:           ; id $0495
    ; "*:Go right to the Bazaar! / *:It's [HERO]! I'll go see you / fight!"
    db $eb, $9f, $a3, $2a, $4c, $62, $4f, $46, $44, $45, $51, $62, $51, $4c, $62, $51
    db $45, $42, $ef, $ee, $25, $3e, $57, $3e, $3e, $4f, $63, $fa, $f7, $ef, $ee, $9f
    db $a3, $2c, $51, $68, $62, $f6, $63, $ef, $ee, $2c, $66, $49, $62, $44, $4c, $62
    db $50, $42, $42, $62, $56, $4c, $52, $fa, $f7, $ef, $ee, $43, $46, $44, $45, $51
    db $63, $ef, $ee, $f7, $f0
TextStr_48_5524:           ; id $0496
    ; "*:Go right to the Bazaar! / *:Oh [HERO]! I'll go see you / fight!"
    db $eb, $9f, $a3, $2a, $4c, $62, $4f, $46, $44, $45, $51, $62, $51, $4c, $62, $51
    db $45, $42, $ef, $ee, $25, $3e, $57, $3e, $3e, $4f, $63, $fa, $f7, $ef, $ee, $9f
    db $a3, $32, $45, $62, $f6, $63, $ef, $ee, $2c, $66, $49, $62, $44, $4c, $62, $50
    db $42, $42, $62, $56, $4c, $52, $fa, $f7, $ef, $ee, $43, $46, $44, $45, $51, $63
    db $ef, $ee, $f7, $f0
TextStr_48_5568:           ; id $0497
    ; "*:Are you... really competing / in the tournament? [YES/NO]"
    db $eb, $9f, $a3, $24, $4f, $42, $62, $56, $4c, $52, $5f, $5f, $5f, $ef, $ee, $4f
    db $42, $3e, $49, $49, $56, $62, $40, $4c, $4a, $4d, $42, $51, $46, $4b, $44, $fa
    db $f7, $ef, $ee, $46, $4b, $62, $51, $45, $42, $62, $51, $4c, $52, $4f, $4b, $3e
    db $4a, $42, $4b, $51, $64, $ef, $ee, $ff, $f0
TextStr_48_55a1:           ; id $0498
    ; "*:...Don't lose."
    db $eb, $9f, $a3, $5f, $5f, $5f, $27, $4c, $4b, $67, $62, $49, $4c, $50, $42, $5f
    db $ef, $ee, $f7, $f0
TextStr_48_55b5:           ; id $0499
    ; "*:...Don't lose. Don't make me say / it again & again!"
    db $eb, $9f, $a3, $5f, $5f, $5f, $27, $4c, $4b, $67, $62, $49, $4c, $50, $42, $5f
    db $ef, $ee, $27, $4c, $4b, $67, $62, $4a, $3e, $48, $42, $62, $4a, $42, $62, $50
    db $3e, $56, $fa, $f7, $ef, $ee, $46, $51, $62, $3e, $44, $3e, $46, $4b, $62, $b6
    db $62, $3e, $44, $3e, $46, $4b, $63, $ef, $ee, $f7, $f0
TextStr_48_55f0:           ; id $049A
    ; "*:You're right! It's impossible / for you to compete!"
    db $eb, $9f, $a3, $3c, $4c, $52, $69, $42, $62, $4f, $46, $44, $45, $51, $63, $ef
    db $ee, $2c, $51, $68, $62, $46, $4a, $4d, $4c, $50, $50, $46, $3f, $49, $42, $fa
    db $f7, $ef, $ee, $43, $4c, $4f, $62, $56, $4c, $52, $62, $51, $4c, $ef, $ee, $40
    db $4c, $4a, $4d, $42, $51, $42, $63, $f7, $f0
TextStr_48_5629:           ; id $049B
    ; "*:...you. Don't you regret / saying that?"
    db $eb, $9f, $a3, $5f, $5f, $5f, $56, $4c, $52, $5f, $62, $27, $4c, $4b, $67, $ef
    db $ee, $56, $4c, $52, $62, $4f, $42, $44, $4f, $42, $51, $fa, $f7, $ef, $ee, $50
    db $3e, $56, $46, $4b, $44, $62, $51, $45, $3e, $51, $64, $ef, $ee, $f7, $f0
TextStr_48_5658:           ; id $049C
    ; "*:The Master Monster Tamer / downstairs said you can win! / *:He knows you can do it!"
    db $ea, $9f, $a3, $37, $45, $42, $62, $30, $3e, $50, $51, $42, $4f, $ef, $ee, $30
    db $4c, $4b, $50, $51, $42, $4f, $62, $37, $3e, $4a, $42, $4f, $fa, $f7, $ef, $ee
    db $41, $4c, $54, $4b, $50, $51, $3e, $46, $4f, $50, $62, $50, $3e, $46, $41, $ef
    db $ee, $56, $4c, $52, $62, $40, $3e, $4b, $62, $54, $46, $4b, $63, $fa, $f7, $ef
    db $ee, $9f, $a3, $2b, $42, $62, $48, $4b, $4c, $54, $50, $ef, $ee, $56, $4c, $52
    db $62, $40, $3e, $4b, $62, $41, $4c, $62, $46, $51, $63, $f7, $f0
TextStr_48_56b5:           ; id $049D
    ; "*:A surprise awaits you / in your future! / *:Hmm...! I can't say anymore. / See it with your own eyes!"
    db $eb, $9f, $a3, $24, $62, $50, $52, $4f, $4d, $4f, $46, $50, $42, $ef, $ee, $3e
    db $54, $3e, $46, $51, $50, $62, $56, $4c, $52, $fa, $f7, $ef, $ee, $46, $4b, $62
    db $56, $4c, $52, $4f, $62, $43, $52, $51, $52, $4f, $42, $63, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $2b, $4a, $4a, $5f, $5f, $5f, $63, $62, $2c, $62, $40, $3e
    db $4b, $67, $ef, $ee, $50, $3e, $56, $62, $3e, $4b, $56, $4a, $4c, $4f, $42, $5f
    db $fa, $f7, $ef, $ee, $36, $42, $42, $62, $46, $51, $62, $54, $46, $51, $45, $62
    db $56, $4c, $52, $4f, $ef, $ee, $4c, $54, $4b, $62, $42, $56, $42, $50, $63, $f7
    db $f0
TextStr_48_5726:           ; id $049E
    ; "*:I wish you good luck! All rooms / are now yours! / *:Go left to the Room of Joy & / Wisdom. / *:Center to the Room of Strength / & Anger. ..."
    db $ea, $9f, $a3, $2c, $62, $54, $46, $50, $45, $62, $56, $4c, $52, $62, $44, $4c
    db $4c, $41, $ef, $ee, $49, $52, $40, $48, $63, $62, $24, $49, $49, $62, $4f, $4c
    db $4c, $4a, $50, $fa, $f7, $ef, $ee, $3e, $4f, $42, $62, $4b, $4c, $54, $62, $56
    db $4c, $52, $4f, $50, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2a, $4c, $62
    db $49, $42, $43, $51, $62, $51, $4c, $62, $51, $45, $42, $ef, $ee, $35, $4c, $4c
    db $4a, $62, $4c, $43, $62, $2d, $4c, $56, $62, $b6, $fa, $f7, $ef, $ee, $3a, $46
    db $50, $41, $4c, $4a, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $26, $42, $4b
    db $51, $42, $4f, $62, $51, $4c, $62, $51, $45, $42, $ef, $ee, $35, $4c, $4c, $4a
    db $62, $4c, $43, $62, $36, $51, $4f, $42, $4b, $44, $51, $45, $fa, $f7, $ef, $ee
    db $b6, $62, $24, $4b, $44, $42, $4f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $35, $46, $44, $45, $51, $62, $51, $4c, $62, $51, $45, $42, $ef, $ee, $35, $4c
    db $4c, $4a, $50, $62, $4c, $43, $62, $33, $42, $3e, $40, $42, $62, $b6, $fa, $f7
    db $ef, $ee, $25, $4f, $3e, $53, $42, $4f, $56, $63, $ef, $ee, $f7, $f0
TextStr_48_57f4:           ; id $049F
    ; "*:All Gates are now yours! / *:The Room of Joy & Wisdom is to the / left. The Room of Strength & Anger / to the center, / *:and the Room of ..."
    db $ea, $9f, $a3, $24, $49, $49, $62, $2a, $3e, $51, $42, $50, $62, $3e, $4f, $42
    db $ef, $ee, $4b, $4c, $54, $62, $56, $4c, $52, $4f, $50, $63, $fa, $f7, $ef, $ee
    db $9f, $a3, $37, $45, $42, $62, $35, $4c, $4c, $4a, $62, $4c, $43, $62, $2d, $4c
    db $56, $ef, $ee, $b6, $62, $3a, $46, $50, $41, $4c, $4a, $62, $46, $50, $62, $51
    db $4c, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $49, $42, $43, $51, $5f, $62, $37
    db $45, $42, $62, $35, $4c, $4c, $4a, $62, $4c, $43, $ef, $ee, $36, $51, $4f, $42
    db $4b, $44, $51, $45, $62, $b6, $62, $24, $4b, $44, $42, $4f, $fa, $f7, $ef, $ee
    db $51, $4c, $62, $51, $45, $42, $62, $40, $42, $4b, $51, $42, $4f, $5e, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $3e, $4b, $41, $62, $51, $45, $42, $62, $35, $4c
    db $4c, $4a, $ef, $ee, $4c, $43, $62, $33, $42, $3e, $40, $42, $62, $b6, $62, $25
    db $4f, $3e, $53, $42, $4f, $56, $fa, $f7, $ef, $ee, $51, $4c, $62, $51, $45, $42
    db $62, $4f, $46, $44, $45, $51, $63, $ef, $ee, $f7, $f0
TextStr_48_58af:           ; id $04A0
    ; "*:What kind of future did you see / behind the Gate of Reflection? / *:No matter who the [HERO] from / the future is... / *:[HERO] is [HERO]..."
    db $ea, $9f, $a3, $3a, $45, $3e, $51, $62, $48, $46, $4b, $41, $62, $4c, $43, $ef
    db $ee, $43, $52, $51, $52, $4f, $42, $62, $41, $46, $41, $62, $56, $4c, $52, $62
    db $50, $42, $42, $fa, $f7, $ef, $ee, $3f, $42, $45, $46, $4b, $41, $62, $51, $45
    db $42, $62, $2a, $3e, $51, $42, $62, $4c, $43, $ef, $ee, $35, $42, $43, $49, $42
    db $40, $51, $46, $4c, $4b, $64, $fa, $f7, $ef, $ee, $9f, $a3, $31, $4c, $62, $4a
    db $3e, $51, $51, $42, $4f, $62, $54, $45, $4c, $ef, $ee, $51, $45, $42, $62, $f6
    db $62, $43, $4f, $4c, $4a, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $43, $52, $51
    db $52, $4f, $42, $62, $46, $50, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $f6, $62, $46, $50, $ef, $ee, $f6, $63, $f7, $f0
TextStr_48_593a:           ; id $04A1
    ; "*:We'll spend the Starry Night, / together - just the two of us!"
    db $ea, $9f, $a3, $3a, $42, $66, $49, $62, $50, $4d, $42, $4b, $41, $ef, $ee, $51
    db $45, $42, $62, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45, $51, $5e
    db $fa, $f7, $ef, $ee, $51, $4c, $44, $42, $51, $45, $42, $4f, $62, $9c, $62, $47
    db $52, $50, $51, $ef, $ee, $51, $45, $42, $62, $51, $54, $4c, $62, $4c, $43, $62
    db $52, $50, $63, $f7, $f0
TextStr_48_597f:           ; id $04A2
    ; "*:Hello. Down to the stable. / Bleat. / *:Everybody is excited because / the Starry Night is soon. Bleat."
    db $ea, $9f, $a3, $2b, $42, $49, $49, $4c, $5f, $62, $27, $4c, $54, $4b, $ef, $ee
    db $51, $4c, $62, $51, $45, $42, $62, $50, $51, $3e, $3f, $49, $42, $5f, $fa, $f7
    db $ef, $ee, $25, $49, $42, $3e, $51, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $28, $53, $42, $4f, $56, $3f, $4c, $41, $56, $62, $46, $50, $ef, $ee, $42, $55
    db $40, $46, $51, $42, $41, $62, $3f, $42, $40, $3e, $52, $50, $42, $fa, $f7, $ef
    db $ee, $51, $45, $42, $62, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45
    db $51, $ef, $ee, $46, $50, $62, $50, $4c, $4c, $4b, $5f, $62, $25, $49, $42, $3e
    db $51, $5f, $f7, $f0
TextStr_48_59f3:           ; id $04A3
    ; "*:The Starry Night is soon. Yeah! / Ha ha ha!"
    db $ea, $9f, $a3, $37, $45, $42, $62, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46
    db $44, $45, $51, $ef, $ee, $46, $50, $62, $50, $4c, $4c, $4b, $5f, $62, $3c, $42
    db $3e, $45, $63, $fa, $f7, $ef, $ee, $2b, $3e, $62, $45, $3e, $62, $45, $3e, $63
    db $ef, $ee, $f7, $f0
TextStr_48_5a27:           ; id $04A4
    ; "*:There's something good / about having a good personality!"
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $68, $ef, $ee, $50, $4c, $4a, $42, $51
    db $45, $46, $4b, $44, $62, $44, $4c, $4c, $41, $fa, $f7, $ef, $ee, $3e, $3f, $4c
    db $52, $51, $62, $45, $3e, $53, $46, $4b, $44, $62, $3e, $ef, $ee, $44, $4c, $4c
    db $41, $62, $4d, $42, $4f, $50, $4c, $4b, $3e, $49, $46, $51, $56, $63, $f7, $f0
TextStr_48_5a67:           ; id $04A5
    ; "*:As the Starry Night nears, I / want to sing! Kwa Kwa!"
    db $eb, $9f, $a3, $24, $50, $62, $51, $45, $42, $62, $36, $51, $3e, $4f, $4f, $56
    db $ef, $ee, $31, $46, $44, $45, $51, $62, $4b, $42, $3e, $4f, $50, $5e, $62, $2c
    db $fa, $f7, $ef, $ee, $54, $3e, $4b, $51, $62, $51, $4c, $62, $50, $46, $4b, $44
    db $63, $ef, $ee, $2e, $54, $3e, $62, $2e, $54, $3e, $63, $f7, $f0
TextStr_48_5aa4:           ; id $04A6
    ; "*:As the Starry Night nears, it / makes even me want to howl! / *:Bwoooooone! Bwooone! / Bone Bone!"
    db $ea, $9f, $a3, $24, $50, $62, $51, $45, $42, $62, $36, $51, $3e, $4f, $4f, $56
    db $ef, $ee, $31, $46, $44, $45, $51, $62, $4b, $42, $3e, $4f, $50, $5e, $62, $46
    db $51, $fa, $f7, $ef, $ee, $4a, $3e, $48, $42, $50, $62, $42, $53, $42, $4b, $62
    db $4a, $42, $ef, $ee, $54, $3e, $4b, $51, $62, $51, $4c, $62, $45, $4c, $54, $49
    db $63, $fa, $f7, $ef, $ee, $9f, $a3, $25, $54, $4c, $4c, $4c, $4c, $4c, $4c, $4b
    db $42, $63, $ef, $ee, $25, $54, $4c, $4c, $4c, $4b, $42, $63, $fa, $f7, $ef, $ee
    db $25, $4c, $4b, $42, $62, $25, $4c, $4b, $42, $63, $ef, $ee, $f7, $f0
TextStr_48_5b12:           ; id $04A7
    ; "*:Power is flowing all around me! / *:Watch me dance in the Starry / Night!"
    db $eb, $9f, $a3, $33, $4c, $54, $42, $4f, $62, $46, $50, $62, $43, $49, $4c, $54
    db $46, $4b, $44, $ef, $ee, $3e, $49, $49, $62, $3e, $4f, $4c, $52, $4b, $41, $62
    db $4a, $42, $63, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $3e, $51, $40, $45, $62, $4a
    db $42, $62, $41, $3e, $4b, $40, $42, $ef, $ee, $46, $4b, $62, $51, $45, $42, $62
    db $36, $51, $3e, $4f, $4f, $56, $fa, $f7, $ef, $ee, $31, $46, $44, $45, $51, $63
    db $ef, $ee, $f7, $f0
TextStr_48_5b66:           ; id $04A8
    ; "*:When the Starry Night nears, my / skin becomes taut!"
    db $eb, $9f, $a3, $3a, $45, $42, $4b, $62, $51, $45, $42, $62, $36, $51, $3e, $4f
    db $4f, $56, $ef, $ee, $31, $46, $44, $45, $51, $62, $4b, $42, $3e, $4f, $50, $5e
    db $62, $4a, $56, $fa, $f7, $ef, $ee, $50, $48, $46, $4b, $62, $3f, $42, $40, $4c
    db $4a, $42, $50, $ef, $ee, $51, $3e, $52, $51, $63, $f7, $f0
TextStr_48_5ba2:           ; id $04A9
    ; "*:Zzz..... ..zzz. Bust! / *:Mm? Is it already / Starry Night?"
    db $ea, $9f, $a3, $3d, $57, $57, $5f, $5f, $5f, $5f, $5f, $ef, $ee, $5f, $5f, $57
    db $57, $57, $5f, $62, $25, $52, $50, $51, $63, $fa, $f7, $ef, $ee, $9f, $a3, $30
    db $4a, $64, $ef, $ee, $2c, $50, $62, $46, $51, $62, $3e, $49, $4f, $42, $3e, $41
    db $56, $fa, $f7, $ef, $ee, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45
    db $51, $64, $ef, $ee, $f7, $f0
TextStr_48_5be8:           ; id $04AA
    ; "*:I feel it! GreatTree is / shaking! / *:It shakes with joy! The Starry / Night is nearing."
    db $ea, $9f, $a3, $2c, $62, $43, $42, $42, $49, $62, $46, $51, $63, $ef, $ee, $2a
    db $4f, $42, $3e, $51, $37, $4f, $42, $42, $62, $46, $50, $fa, $f7, $ef, $ee, $50
    db $45, $3e, $48, $46, $4b, $44, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c
    db $51, $62, $50, $45, $3e, $48, $42, $50, $62, $54, $46, $51, $45, $ef, $ee, $47
    db $4c, $56, $63, $62, $37, $45, $42, $62, $36, $51, $3e, $4f, $4f, $56, $fa, $f7
    db $ef, $ee, $31, $46, $44, $45, $51, $62, $46, $50, $62, $4b, $42, $3e, $4f, $46
    db $4b, $44, $5f, $ef, $ee, $f7, $f0
TextStr_48_5c4f:           ; id $04AB
    ; "*:Of course GreatTree will / triumph!"
    db $eb, $9f, $a3, $32, $43, $62, $40, $4c, $52, $4f, $50, $42, $ef, $ee, $2a, $4f
    db $42, $3e, $51, $37, $4f, $42, $42, $62, $54, $46, $49, $49, $fa, $f7, $ef, $ee
    db $51, $4f, $46, $52, $4a, $4d, $45, $63, $ef, $ee, $f7, $f0
TextStr_48_5c7b:           ; id $04AC
    ; "*:It's GreatLog! GreatLog, will / carry the day!"
    db $ea, $9f, $a3, $2c, $51, $68, $62, $2a, $4f, $42, $3e, $51, $2f, $4c, $44, $63
    db $ef, $ee, $2a, $4f, $42, $3e, $51, $2f, $4c, $44, $5e, $62, $54, $46, $49, $49
    db $fa, $f7, $ef, $ee, $40, $3e, $4f, $4f, $56, $62, $51, $45, $42, $62, $41, $3e
    db $56, $63, $ef, $ee, $f7, $f0
TextStr_48_5cb1:           ; id $04AD
    ; "*:I believe DeadTree will / be victorious!"
    db $eb, $9f, $a3, $2c, $62, $3f, $42, $49, $46, $42, $53, $42, $ef, $ee, $27, $42
    db $3e, $41, $37, $4f, $42, $42, $62, $54, $46, $49, $49, $fa, $f7, $ef, $ee, $3f
    db $42, $62, $53, $46, $40, $51, $4c, $4f, $46, $4c, $52, $50, $63, $ef, $ee, $f7
    db $f0
TextStr_48_5ce2:           ; id $04AE
    ; "*:You win, GreatTree happy. / Eek!"
    db $eb, $9f, $a3, $3c, $4c, $52, $62, $54, $46, $4b, $5e, $ef, $ee, $2a, $4f, $42
    db $3e, $51, $37, $4f, $42, $42, $62, $45, $3e, $4d, $4d, $56, $5f, $fa, $f7, $ef
    db $ee, $28, $42, $48, $63, $ef, $ee, $f7, $f0
TextStr_48_5d0b:           ; id $04AF
    ; "*:You made it! Good job! / *:Fight to your heart's content. / Are you ready? [YES/NO]"
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $4a, $3e, $41, $42, $62, $46, $51, $63, $ef
    db $ee, $2a, $4c, $4c, $41, $62, $47, $4c, $3f, $63, $fa, $f7, $ef, $ee, $9f, $a3
    db $29, $46, $44, $45, $51, $62, $51, $4c, $62, $56, $4c, $52, $4f, $ef, $ee, $45
    db $42, $3e, $4f, $51, $68, $62, $40, $4c, $4b, $51, $42, $4b, $51, $5f, $fa, $f7
    db $ef, $ee, $24, $4f, $42, $62, $56, $4c, $52, $62, $4f, $42, $3e, $41, $56, $64
    db $ef, $ee, $ff, $f0
TextStr_48_5d5f:           ; id $04B0
    ; "*:Let me know when you're ready."
    db $ea, $9f, $a3, $2f, $42, $51, $62, $4a, $42, $62, $48, $4b, $4c, $54, $62, $54
    db $45, $42, $4b, $ef, $ee, $56, $4c, $52, $69, $42, $62, $4f, $42, $3e, $41, $56
    db $5f, $f7, $f0
TextStr_48_5d82:           ; id $04B1
    ; "*:Announcing the rep of GreatTree, / [HERO]!"
    db $ea, $9f, $a3, $24, $4b, $4b, $4c, $52, $4b, $40, $46, $4b, $44, $62, $51, $45
    db $42, $ef, $ee, $4f, $42, $4d, $62, $4c, $43, $62, $2a, $4f, $42, $3e, $51, $37
    db $4f, $42, $42, $5e, $fa, $f7, $ef, $ee, $f6, $63, $ef, $ee, $f7, $f0
TextStr_48_5db0:           ; id $04B2
    ; "*:The Starry Night Tournament / is fought among kingdoms. / *:The participants this time are / BigTrunk, DeadTree, / *:and GreatLog. / *:If ..."
    db $eb, $9f, $a3, $37, $45, $42, $62, $36, $51, $3e, $4f, $4f, $56, $ef, $ee, $31
    db $46, $44, $45, $51, $62, $37, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $fa
    db $f7, $ef, $ee, $46, $50, $62, $43, $4c, $52, $44, $45, $51, $62, $3e, $4a, $4c
    db $4b, $44, $ef, $ee, $48, $46, $4b, $44, $41, $4c, $4a, $50, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $37, $45, $42, $62, $4d, $3e, $4f, $51, $46, $40, $46, $4d, $3e
    db $4b, $51, $50, $ef, $ee, $51, $45, $46, $50, $62, $51, $46, $4a, $42, $62, $3e
    db $4f, $42, $fa, $f7, $ef, $ee, $25, $46, $44, $37, $4f, $52, $4b, $48, $5e, $ef
    db $ee, $27, $42, $3e, $41, $37, $4f, $42, $42, $5e, $fa, $f7, $ef, $ee, $9f, $a3
    db $3e, $4b, $41, $62, $2a, $4f, $42, $3e, $51, $2f, $4c, $44, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $2c, $43, $62, $56, $4c, $52, $62, $50, $52, $4f, $53
    db $46, $53, $42, $ef, $ee, $51, $45, $42, $50, $42, $62, $51, $45, $4f, $42, $42
    db $fa, $f7, $ef, $ee, $48, $46, $4b, $44, $41, $4c, $4a, $50, $5e, $ef, $ee, $56
    db $4c, $52, $62, $54, $46, $4b, $63, $f7, $f0
TextStr_48_5e79:           ; id $04B3
    ; "*:Want to listen to the description / of the tournament? [YES/NO]"
    db $eb, $9f, $a3, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $49, $46, $50, $51, $42
    db $4b, $ef, $ee, $51, $4c, $62, $51, $45, $42, $62, $41, $42, $50, $40, $4f, $46
    db $4d, $51, $46, $4c, $4b, $fa, $f7, $ef, $ee, $4c, $43, $62, $51, $45, $42, $62
    db $51, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $64, $ef, $ee, $ff, $f0
TextStr_48_5eb8:           ; id $04B4
    ; "*:Everybody in the kingdom is behind / you! / *:[HERO]! Good luck! *kiss*"
    db $eb, $9f, $a3, $28, $53, $42, $4f, $56, $3f, $4c, $41, $56, $62, $46, $4b, $62
    db $51, $45, $42, $ef, $ee, $48, $46, $4b, $44, $41, $4c, $4a, $62, $46, $50, $62
    db $3f, $42, $45, $46, $4b, $41, $fa, $f7, $ef, $ee, $56, $4c, $52, $63, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $f6, $63, $ef, $ee, $2a, $4c, $4c, $41, $62, $49
    db $52, $40, $48, $63, $62, $9f, $48, $46, $50, $50, $9f, $f7, $f0
TextStr_48_5f05:           ; id $04B5
    ; "*:You made it! / *:I can't even come close, [HERO]. / *:Good luck!"
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $4a, $3e, $41, $42, $62, $46, $51, $63, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $40, $3e, $4b, $67, $62, $42, $53
    db $42, $4b, $ef, $ee, $40, $4c, $4a, $42, $62, $40, $49, $4c, $50, $42, $5e, $62
    db $f6, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2a, $4c, $4c, $41, $62, $49, $52, $40
    db $48, $63, $ef, $ee, $f7, $f0
TextStr_48_5f4b:           ; id $04B6
    ; "*:Oh! Its a HornBeet! What a / magnificent horn! / *:Well done! I'll give you / a reward."
    db $eb, $9f, $a3, $32, $45, $63, $62, $2c, $51, $50, $62, $3e, $ef, $ee, $2b, $4c
    db $4f, $4b, $25, $42, $42, $51, $63, $62, $3a, $45, $3e, $51, $62, $3e, $fa, $f7
    db $ef, $ee, $4a, $3e, $44, $4b, $46, $43, $46, $40, $42, $4b, $51, $62, $45, $4c
    db $4f, $4b, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $42, $49, $49, $62
    db $41, $4c, $4b, $42, $63, $ef, $ee, $2c, $66, $49, $62, $44, $46, $53, $42, $62
    db $56, $4c, $52, $fa, $f7, $ef, $ee, $3e, $62, $4f, $42, $54, $3e, $4f, $41, $5f
    db $ef, $ee, $fa, $f7, $f0
TextStr_48_5fb0:           ; id $04B7
    ; "*:Wyvern!"
    db $ea, $9f, $a3, $3a, $56, $53, $42, $4f, $4b, $63, $ef, $ee, $f7, $f0
TextStr_48_5fbe:           ; id $04B8
    ; "*:Come on! Pray! Pray to the / statue of Watabou! / *:Pray to the statue of / Watabou and you'll win!"
    db $ea, $9f, $a3, $26, $4c, $4a, $42, $62, $4c, $4b, $63, $62, $33, $4f, $3e, $56
    db $63, $ef, $ee, $33, $4f, $3e, $56, $62, $51, $4c, $62, $51, $45, $42, $fa, $f7
    db $ef, $ee, $50, $51, $3e, $51, $52, $42, $62, $4c, $43, $ef, $ee, $3a, $3e, $51
    db $3e, $3f, $4c, $52, $63, $fa, $f7, $ef, $ee, $9f, $a3, $33, $4f, $3e, $56, $62
    db $51, $4c, $62, $51, $45, $42, $ef, $ee, $50, $51, $3e, $51, $52, $42, $62, $4c
    db $43, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $62, $3e, $4b, $41
    db $ef, $ee, $56, $4c, $52, $66, $49, $62, $54, $46, $4b, $63, $f7, $f0
TextStr_48_602c:           ; id $04B9
    ; "[HERO] reads the blackboard. / :The principal hides his bald / head under his hat. / :Baldy baldy baldy baldy..."
    db $f6, $62, $4f, $42, $3e, $41, $50, $62, $51, $45, $42, $ef, $ee, $3f, $49, $3e
    db $40, $48, $3f, $4c, $3e, $4f, $41, $5f, $fa, $f7, $ef, $ee, $a3, $37, $45, $42
    db $62, $4d, $4f, $46, $4b, $40, $46, $4d, $3e, $49, $ef, $ee, $45, $46, $41, $42
    db $50, $62, $45, $46, $50, $62, $3f, $3e, $49, $41, $fa, $f7, $ef, $ee, $45, $42
    db $3e, $41, $62, $52, $4b, $41, $42, $4f, $62, $45, $46, $50, $ef, $ee, $45, $3e
    db $51, $5f, $fa, $f7, $ef, $ee, $a3, $25, $3e, $49, $41, $56, $62, $3f, $3e, $49
    db $41, $56, $ef, $ee, $3f, $3e, $49, $41, $56, $62, $3f, $3e, $49, $41, $56, $5f
    db $5f, $5f, $f7, $f0
TextStr_48_60a0:           ; id $04BA
    ; "*:Here is MysticNut. / Use it wisely."
    db $eb, $9f, $a3, $2b, $42, $4f, $42, $62, $46, $50, $ef, $ee, $30, $56, $50, $51
    db $46, $40, $31, $52, $51, $5f, $fa, $f7, $ef, $ee, $38, $50, $42, $62, $46, $51
    db $62, $54, $46, $50, $42, $49, $56, $5f, $ef, $ee, $f7, $f0
TextStr_48_60cc:           ; id $04BB
    ; "*:My heart is pounding! / The battle is about to begin! / *:The terrible master of the / rumors will be there! / *:Just run before you are e..."
    db $eb, $9f, $a3, $30, $56, $62, $45, $42, $3e, $4f, $51, $62, $46, $50, $ef, $ee
    db $4d, $4c, $52, $4b, $41, $46, $4b, $44, $63, $fa, $f7, $ef, $ee, $37, $45, $42
    db $62, $3f, $3e, $51, $51, $49, $42, $62, $46, $50, $ef, $ee, $3e, $3f, $4c, $52
    db $51, $62, $51, $4c, $62, $3f, $42, $44, $46, $4b, $63, $fa, $f7, $ef, $ee, $9f
    db $a3, $37, $45, $42, $62, $51, $42, $4f, $4f, $46, $3f, $49, $42, $ef, $ee, $4a
    db $3e, $50, $51, $42, $4f, $62, $4c, $43, $62, $51, $45, $42, $fa, $f7, $ef, $ee
    db $4f, $52, $4a, $4c, $4f, $50, $62, $54, $46, $49, $49, $62, $3f, $42, $ef, $ee
    db $51, $45, $42, $4f, $42, $63, $fa, $f7, $ef, $ee, $9f, $a3, $2d, $52, $50, $51
    db $62, $4f, $52, $4b, $62, $3f, $42, $43, $4c, $4f, $42, $ef, $ee, $56, $4c, $52
    db $62, $3e, $4f, $42, $62, $42, $3e, $51, $42, $4b, $63, $63, $f7, $f0
TextStr_48_616a:           ; id $04BC
    ; "*:This is Shoyu! Bebe! Repeat after / me. C'mon!"
    db $ea, $9f, $a3, $37, $45, $46, $50, $62, $46, $50, $62, $36, $45, $4c, $56, $52
    db $63, $ef, $ee, $25, $42, $3f, $42, $63, $62, $35, $42, $4d, $42, $3e, $51, $62
    db $3e, $43, $51, $42, $4f, $fa, $f7, $ef, $ee, $4a, $42, $5f, $62, $26, $6a, $4c
    db $4b, $63, $ef, $ee, $f7, $f0
TextStr_48_61a0:           ; id $04BD
    ; "*:What the heck is Shoyu! / Can't you just say soy sauce!"
    db $ea, $9f, $a3, $3a, $45, $3e, $51, $62, $51, $45, $42, $62, $45, $42, $40, $48
    db $ef, $ee, $46, $50, $62, $36, $45, $4c, $56, $52, $63, $fa, $f7, $ef, $ee, $26
    db $3e, $4b, $67, $62, $56, $4c, $52, $62, $47, $52, $50, $51, $ef, $ee, $50, $3e
    db $56, $62, $50, $4c, $56, $62, $50, $3e, $52, $40, $42, $63, $f7, $f0
TextStr_48_61de:           ; id $04BE
    ; "*:Splash Splash! When the Starry / Night nears... / *:I cannot help becoming a splash! / ??splash??"
    db $eb, $9f, $a3, $36, $4d, $49, $3e, $50, $45, $62, $36, $4d, $49, $3e, $50, $45
    db $63, $ef, $ee, $3a, $45, $42, $4b, $62, $51, $45, $42, $62, $36, $51, $3e, $4f
    db $4f, $56, $fa, $f7, $ef, $ee, $31, $46, $44, $45, $51, $62, $4b, $42, $3e, $4f
    db $50, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $40, $3e
    db $4b, $4b, $4c, $51, $62, $45, $42, $49, $4d, $ef, $ee, $3f, $42, $40, $4c, $4a
    db $46, $4b, $44, $62, $3e, $62, $50, $4d, $49, $3e, $50, $45, $63, $fa, $f7, $ef
    db $ee, $64, $64, $50, $4d, $49, $3e, $50, $45, $64, $64, $ef, $ee, $f7, $f0
TextStr_48_624d:           ; id $04BF
    ; "*:I would like to go deep in the / chambers of the Shrine... / *:but the Master Monster Tamer / wouldn't let me in. / *:What could be hiding..."
    db $ea, $9f, $a3, $2c, $62, $54, $4c, $52, $49, $41, $62, $49, $46, $48, $42, $62
    db $51, $4c, $ef, $ee, $44, $4c, $62, $41, $42, $42, $4d, $62, $46, $4b, $62, $51
    db $45, $42, $fa, $f7, $ef, $ee, $40, $45, $3e, $4a, $3f, $42, $4f, $50, $62, $4c
    db $43, $62, $51, $45, $42, $ef, $ee, $36, $45, $4f, $46, $4b, $42, $5f, $5f, $5f
    db $fa, $f7, $ef, $ee, $9f, $a3, $3f, $52, $51, $62, $51, $45, $42, $62, $30, $3e
    db $50, $51, $42, $4f, $ef, $ee, $30, $4c, $4b, $50, $51, $42, $4f, $62, $37, $3e
    db $4a, $42, $4f, $fa, $f7, $ef, $ee, $54, $4c, $52, $49, $41, $4b, $67, $62, $49
    db $42, $51, $62, $4a, $42, $ef, $ee, $46, $4b, $5f, $fa, $f7, $ef, $ee, $9f, $a3
    db $3a, $45, $3e, $51, $62, $40, $4c, $52, $49, $41, $62, $3f, $42, $ef, $ee, $45
    db $46, $41, $46, $4b, $44, $62, $3f, $3e, $40, $48, $62, $51, $45, $42, $4f, $42
    db $63, $f7, $f0
TextStr_48_62f0:           ; id $04C0
    ; "[HERO] looked at the bookshelf. / :Saying of the day... / :Breeding the same monsters / can create a different monster! / Want to read more?..."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $3e, $51, $ef, $ee, $51, $45, $42
    db $62, $3f, $4c, $4c, $48, $50, $45, $42, $49, $43, $5f, $fa, $f7, $ef, $ee, $a3
    db $36, $3e, $56, $46, $4b, $44, $62, $4c, $43, $62, $51, $45, $42, $ef, $ee, $41
    db $3e, $56, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $a3, $25, $4f, $42, $42, $41, $46
    db $4b, $44, $62, $51, $45, $42, $ef, $ee, $50, $3e, $4a, $42, $62, $4a, $4c, $4b
    db $50, $51, $42, $4f, $50, $fa, $f7, $ef, $ee, $40, $3e, $4b, $62, $40, $4f, $42
    db $3e, $51, $42, $62, $3e, $ef, $ee, $41, $46, $43, $43, $42, $4f, $42, $4b, $51
    db $62, $4a, $4c, $4b, $50, $51, $42, $4f, $63, $fa, $f7, $ef, $ee, $3a, $3e, $4b
    db $51, $62, $51, $4c, $62, $4f, $42, $3e, $41, $62, $4a, $4c, $4f, $42, $64, $ef
    db $ee, $ff, $f0
TextStr_48_6383:           ; id $04C1
    ; ":[HERO] already conquered D class! / :He finished the King's quest / without any difficulty. / :He made the eggs of BattleRex / vanish with ..."
    db $a3, $f6, $62, $3e, $49, $4f, $42, $3e, $41, $56, $ef, $ee, $40, $4c, $4b, $4e
    db $52, $42, $4f, $42, $41, $62, $27, $62, $40, $49, $3e, $50, $50, $63, $fa, $f7
    db $ef, $ee, $a3, $2b, $42, $62, $43, $46, $4b, $46, $50, $45, $42, $41, $62, $51
    db $45, $42, $ef, $ee, $2e, $46, $4b, $44, $68, $62, $4e, $52, $42, $50, $51, $fa
    db $f7, $ef, $ee, $54, $46, $51, $45, $4c, $52, $51, $62, $3e, $4b, $56, $ef, $ee
    db $41, $46, $43, $43, $46, $40, $52, $49, $51, $56, $5f, $fa, $f7, $ef, $ee, $a3
    db $2b, $42, $62, $4a, $3e, $41, $42, $62, $51, $45, $42, $62, $42, $44, $44, $50
    db $ef, $ee, $4c, $43, $62, $25, $3e, $51, $51, $49, $42, $35, $42, $55, $fa, $f7
    db $ef, $ee, $53, $3e, $4b, $46, $50, $45, $62, $54, $46, $51, $45, $62, $4c, $4b
    db $42, $ef, $ee, $3e, $51, $51, $3e, $40, $48, $63, $fa, $f7, $ef, $ee, $a3, $37
    db $45, $46, $50, $62, $51, $46, $4a, $42, $5e, $ef, $ee, $3a, $3e, $51, $3e, $3f
    db $4c, $52, $62, $3f, $4f, $4c, $52, $44, $45, $51, $fa, $f7, $ef, $ee, $3e, $62
    db $44, $4c, $4c, $41, $62, $4a, $3e, $50, $51, $42, $4f, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $4f, $42, $3e, $41, $62, $4a
    db $4c, $4f, $42, $64, $ef, $ee, $ff, $f0
TextStr_48_646b:           ; id $04C2
    ; ":At last [HERO] will participate / in the tournament! / :You're something! You look like me / in my younger days!"
    db $a3, $24, $51, $62, $49, $3e, $50, $51, $62, $f6, $ef, $ee, $54, $46, $49, $49
    db $62, $4d, $3e, $4f, $51, $46, $40, $46, $4d, $3e, $51, $42, $fa, $f7, $ef, $ee
    db $46, $4b, $62, $51, $45, $42, $62, $51, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b
    db $51, $63, $ef, $ee, $fa, $f7, $ef, $ee, $a3, $3c, $4c, $52, $69, $42, $62, $50
    db $4c, $4a, $42, $51, $45, $46, $4b, $44, $63, $ef, $ee, $3c, $4c, $52, $62, $49
    db $4c, $4c, $48, $62, $49, $46, $48, $42, $62, $4a, $42, $fa, $f7, $ef, $ee, $46
    db $4b, $62, $4a, $56, $62, $56, $4c, $52, $4b, $44, $42, $4f, $ef, $ee, $41, $3e
    db $56, $50, $63, $f7, $f0
TextStr_48_64e0:           ; id $04C3
    ; "*:The combination with the same / monsters creates a different monster. / *:Did you believe this could happen? / *:It seems you can make dif..."
    db $ea, $9f, $a3, $37, $45, $42, $62, $40, $4c, $4a, $3f, $46, $4b, $3e, $51, $46
    db $4c, $4b, $ef, $ee, $54, $46, $51, $45, $62, $51, $45, $42, $62, $50, $3e, $4a
    db $42, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $40, $4f
    db $42, $3e, $51, $42, $50, $62, $3e, $ef, $ee, $41, $46, $43, $43, $42, $4f, $42
    db $4b, $51, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $5f, $fa, $f7, $ef, $ee, $9f
    db $a3, $27, $46, $41, $62, $56, $4c, $52, $62, $3f, $42, $49, $46, $42, $53, $42
    db $ef, $ee, $51, $45, $46, $50, $62, $40, $4c, $52, $49, $41, $62, $45, $3e, $4d
    db $4d, $42, $4b, $64, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $51, $62, $50, $42, $42
    db $4a, $50, $62, $56, $4c, $52, $62, $40, $3e, $4b, $ef, $ee, $4a, $3e, $48, $42
    db $62, $41, $46, $43, $43, $42, $4f, $42, $4b, $51, $fa, $f7, $ef, $ee, $4a, $4c
    db $4b, $50, $51, $42, $4f, $50, $62, $42, $53, $42, $4b, $62, $3f, $56, $ef, $ee
    db $3f, $4f, $42, $42, $41, $46, $4b, $44, $62, $51, $45, $42, $fa, $f7, $ef, $ee
    db $50, $3e, $4a, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $ef, $ee, $43
    db $4f, $4c, $4a, $62, $51, $45, $42, $62, $50, $3e, $4a, $42, $fa, $f7, $ef, $ee
    db $4a, $4c, $4b, $50, $51, $42, $4f, $62, $43, $3e, $4a, $46, $49, $56, $5f, $ef
    db $ee, $f7, $f0
TextStr_48_65d3:           ; id $04C4
    ; "*:Many Stars fall from the sky on / the Starry Night. / *:I wonder where those stars go?"
    db $ea, $9f, $a3, $30, $3e, $4b, $56, $62, $36, $51, $3e, $4f, $50, $62, $43, $3e
    db $49, $49, $ef, $ee, $43, $4f, $4c, $4a, $62, $51, $45, $42, $62, $50, $48, $56
    db $62, $4c, $4b, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $36, $51, $3e, $4f, $4f
    db $56, $62, $31, $46, $44, $45, $51, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $2c, $62, $54, $4c, $4b, $41, $42, $4f, $62, $54, $45, $42, $4f, $42, $ef, $ee
    db $51, $45, $4c, $50, $42, $62, $50, $51, $3e, $4f, $50, $62, $44, $4c, $64, $f7
    db $f0
TextStr_48_6634:           ; id $04C5
    ; "*:Do you know my daughter? [YES/NO]"
    db $ea, $9f, $a3, $27, $4c, $62, $56, $4c, $52, $62, $48, $4b, $4c, $54, $62, $4a
    db $56, $ef, $ee, $41, $3e, $52, $44, $45, $51, $42, $4f, $64, $ff, $f0
TextStr_48_6652:           ; id $04C6
    ; "*:No!? You don't know such a cute / kind and graceful girl! / *:She's playing outside. Go see / her with your own eyes."
    db $ea, $9f, $a3, $31, $4c, $63, $64, $62, $3c, $4c, $52, $62, $41, $4c, $4b, $67
    db $ef, $ee, $48, $4b, $4c, $54, $62, $50, $52, $40, $45, $62, $3e, $62, $40, $52
    db $51, $42, $fa, $f7, $ef, $ee, $48, $46, $4b, $41, $62, $3e, $4b, $41, $62, $44
    db $4f, $3e, $40, $42, $43, $52, $49, $ef, $ee, $44, $46, $4f, $49, $63, $fa, $f7
    db $ef, $ee, $9f, $a3, $36, $45, $42, $68, $62, $4d, $49, $3e, $56, $46, $4b, $44
    db $ef, $ee, $4c, $52, $51, $50, $46, $41, $42, $5f, $62, $2a, $4c, $62, $50, $42
    db $42, $fa, $f7, $ef, $ee, $45, $42, $4f, $62, $54, $46, $51, $45, $62, $56, $4c
    db $52, $4f, $62, $4c, $54, $4b, $ef, $ee, $42, $56, $42, $50, $5f, $f7, $f0
TextStr_48_66d1:           ; id $04C7
    ; "*:She's the most graceful girl in / GreatTree. Isn't she cute? [YES/NO]"
    db $ea, $9f, $a3, $36, $45, $42, $68, $62, $51, $45, $42, $62, $4a, $4c, $50, $51
    db $ef, $ee, $44, $4f, $3e, $40, $42, $43, $52, $49, $62, $44, $46, $4f, $49, $62
    db $46, $4b, $fa, $f7, $ef, $ee, $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $5f
    db $ef, $ee, $2c, $50, $4b, $67, $62, $50, $45, $42, $62, $40, $52, $51, $42, $64
    db $ff, $f0
TextStr_48_6713:           ; id $04C8
    ; "*:You're promising! / Let me tell you something. / *:It's good to have your kid / read books. / *:Even if they have a warped / personality, ..."
    db $eb, $9f, $a3, $3c, $4c, $52, $69, $42, $ef, $ee, $4d, $4f, $4c, $4a, $46, $50
    db $46, $4b, $44, $63, $fa, $f7, $ef, $ee, $2f, $42, $51, $62, $4a, $42, $62, $51
    db $42, $49, $49, $62, $56, $4c, $52, $ef, $ee, $50, $4c, $4a, $42, $51, $45, $46
    db $4b, $44, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $51, $68, $62, $44, $4c, $4c
    db $41, $62, $51, $4c, $ef, $ee, $45, $3e, $53, $42, $62, $56, $4c, $52, $4f, $62
    db $48, $46, $41, $fa, $f7, $ef, $ee, $4f, $42, $3e, $41, $62, $3f, $4c, $4c, $48
    db $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $28, $53, $42, $4b, $62, $46
    db $43, $62, $51, $45, $42, $56, $ef, $ee, $45, $3e, $53, $42, $62, $3e, $62, $54
    db $3e, $4f, $4d, $42, $41, $fa, $f7, $ef, $ee, $4d, $42, $4f, $50, $4c, $4b, $3e
    db $49, $46, $51, $56, $5e, $62, $3f, $4c, $4c, $48, $50, $ef, $ee, $40, $3e, $4b
    db $62, $4a, $3e, $48, $42, $62, $51, $45, $42, $4a, $62, $51, $3e, $4a, $42, $fa
    db $f7, $ef, $ee, $3e, $4b, $41, $62, $44, $42, $4b, $51, $49, $42, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $32, $43, $62, $40, $4c, $52, $4f, $50, $42, $62
    db $4a, $56, $ef, $ee, $41, $3e, $52, $44, $45, $51, $42, $4f, $62, $46, $50, $62
    db $3e, $62, $44, $4c, $4c, $41, $fa, $f7, $ef, $ee, $44, $46, $4f, $49, $62, $54
    db $46, $51, $45, $4c, $52, $51, $ef, $ee, $3f, $4c, $4c, $48, $50, $63, $f7, $f0
TextStr_48_6813:           ; id $04C9
    ; "*:My hubby adores our girl.. / *:Read his journal if you like."
    db $eb, $9f, $a3, $30, $56, $62, $45, $52, $3f, $3f, $56, $62, $3e, $41, $4c, $4f
    db $42, $50, $ef, $ee, $4c, $52, $4f, $62, $44, $46, $4f, $49, $5f, $5f, $fa, $f7
    db $ef, $ee, $9f, $a3, $35, $42, $3e, $41, $62, $45, $46, $50, $62, $47, $4c, $52
    db $4f, $4b, $3e, $49, $ef, $ee, $46, $43, $62, $56, $4c, $52, $62, $49, $46, $48
    db $42, $5f, $f7, $f0
TextStr_48_6857:           ; id $04CA
    ; ":Journal of My Baby, Part 3 / :Flatter with treats and give / strict orders sometimes...? / :What? How to raise your / monster? I was readin..."
    db $a3, $2d, $4c, $52, $4f, $4b, $3e, $49, $62, $4c, $43, $62, $30, $56, $ef, $ee
    db $25, $3e, $3f, $56, $5e, $62, $33, $3e, $4f, $51, $62, $03, $fa, $f7, $ef, $ee
    db $a3, $29, $49, $3e, $51, $51, $42, $4f, $62, $54, $46, $51, $45, $ef, $ee, $51
    db $4f, $42, $3e, $51, $50, $62, $3e, $4b, $41, $62, $44, $46, $53, $42, $fa, $f7
    db $ef, $ee, $50, $51, $4f, $46, $40, $51, $62, $4c, $4f, $41, $42, $4f, $50, $ef
    db $ee, $50, $4c, $4a, $42, $51, $46, $4a, $42, $50, $5f, $5f, $5f, $64, $fa, $f7
    db $ef, $ee, $a3, $3a, $45, $3e, $51, $64, $62, $2b, $4c, $54, $62, $51, $4c, $ef
    db $ee, $4f, $3e, $46, $50, $42, $62, $56, $4c, $52, $4f, $fa, $f7, $ef, $ee, $4a
    db $4c, $4b, $50, $51, $42, $4f, $64, $62, $2c, $62, $54, $3e, $50, $ef, $ee, $4f
    db $42, $3e, $41, $46, $4b, $44, $62, $51, $45, $42, $62, $54, $4f, $4c, $4b, $44
    db $fa, $f7, $ef, $ee, $3f, $4c, $4c, $48, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $4f, $42, $3e, $41, $62, $4a, $4c
    db $4f, $42, $64, $ef, $ee, $ff, $f0
TextStr_48_691e:           ; id $04CB
    ; ":Journal of My Baby, Part 4 / :I guess I've forgotten an / important thing. / :I forgot to name my baby! / :She was so cute that I completel..."
    db $a3, $2d, $4c, $52, $4f, $4b, $3e, $49, $62, $4c, $43, $62, $30, $56, $ef, $ee
    db $25, $3e, $3f, $56, $5e, $62, $33, $3e, $4f, $51, $62, $04, $fa, $f7, $ef, $ee
    db $a3, $2c, $62, $44, $52, $42, $50, $50, $62, $2c, $6c, $42, $ef, $ee, $43, $4c
    db $4f, $44, $4c, $51, $51, $42, $4b, $62, $3e, $4b, $fa, $f7, $ef, $ee, $46, $4a
    db $4d, $4c, $4f, $51, $3e, $4b, $51, $62, $51, $45, $46, $4b, $44, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $a3, $2c, $62, $43, $4c, $4f, $44, $4c, $51, $62, $51, $4c
    db $62, $4b, $3e, $4a, $42, $ef, $ee, $4a, $56, $62, $3f, $3e, $3f, $56, $63, $fa
    db $f7, $ef, $ee, $a3, $36, $45, $42, $62, $54, $3e, $50, $62, $50, $4c, $62, $40
    db $52, $51, $42, $ef, $ee, $51, $45, $3e, $51, $62, $2c, $62, $40, $4c, $4a, $4d
    db $49, $42, $51, $42, $49, $56, $fa, $f7, $ef, $ee, $43, $4c, $4f, $44, $4c, $51
    db $62, $3e, $3f, $4c, $52, $51, $62, $46, $51, $5f, $ef, $ee, $f7, $f0
TextStr_48_69cc:           ; id $04CC
    ; "*:I heard a wish will come true / when you win a victory in the / tournament. / *:[HERO], Please win for me! / for me! / *:I want to be the ..."
    db $ea, $9f, $a3, $2c, $62, $45, $42, $3e, $4f, $41, $62, $3e, $62, $54, $46, $50
    db $45, $ef, $ee, $54, $46, $49, $49, $62, $40, $4c, $4a, $42, $62, $51, $4f, $52
    db $42, $fa, $f7, $ef, $ee, $54, $45, $42, $4b, $62, $56, $4c, $52, $62, $54, $46
    db $4b, $62, $3e, $ef, $ee, $53, $46, $40, $51, $4c, $4f, $56, $62, $46, $4b, $62
    db $51, $45, $42, $fa, $f7, $ef, $ee, $51, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b
    db $51, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $f6, $5e, $62, $33, $49, $42
    db $3e, $50, $42, $ef, $ee, $54, $46, $4b, $62, $43, $4c, $4f, $62, $4a, $42, $63
    db $fa, $f7, $ef, $ee, $43, $4c, $4f, $62, $4a, $42, $63, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $2c, $62, $54, $3e, $4b, $51, $62, $51, $4c, $62, $3f, $42, $62
    db $51, $45, $42, $ef, $ee, $4c, $54, $4b, $42, $4f, $62, $4c, $43, $62, $51, $45
    db $42, $fa, $f7, $ef, $ee, $39, $3e, $52, $49, $51, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $3f, $56, $62, $45, $3e, $53, $46, $4b, $44, $62, $51, $45, $42, $ef
    db $ee, $40, $52, $4f, $4f, $42, $4b, $51, $62, $4c, $54, $4b, $42, $4f, $fa, $f7
    db $ef, $ee, $4f, $42, $51, $46, $4f, $42, $5f, $5f, $63, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $33, $49, $42, $3e, $50, $42, $62, $41, $4c, $4b, $67, $ef, $ee
    db $51, $42, $49, $49, $62, $3e, $4b, $56, $3f, $4c, $41, $56, $5f, $f7, $f0
TextStr_48_6acb:           ; id $04CD
    ; "*:I'm looking for a book. / *:I can't find it. Where could it be? / *:I want to study about the origin / of the tournament."
    db $ea, $9f, $a3, $2c, $6a, $62, $49, $4c, $4c, $48, $46, $4b, $44, $62, $43, $4c
    db $4f, $ef, $ee, $3e, $62, $3f, $4c, $4c, $48, $5f, $fa, $f7, $ef, $ee, $9f, $a3
    db $2c, $62, $40, $3e, $4b, $67, $62, $43, $46, $4b, $41, $62, $46, $51, $5f, $ef
    db $ee, $3a, $45, $42, $4f, $42, $62, $40, $4c, $52, $49, $41, $62, $46, $51, $62
    db $3f, $42, $64, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $54, $3e, $4b, $51, $62
    db $51, $4c, $62, $50, $51, $52, $41, $56, $ef, $ee, $3e, $3f, $4c, $52, $51, $62
    db $51, $45, $42, $62, $4c, $4f, $46, $44, $46, $4b, $fa, $f7, $ef, $ee, $4c, $43
    db $62, $51, $45, $42, $62, $51, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $5f
    db $ef, $ee, $f7, $f0
TextStr_48_6b4f:           ; id $04CE
    ; "*:I am the Monster Minister. / All hail! / *:I can tell you about places where / many kinds of monsters live. [YES/NO]"
    db $ea, $9f, $a3, $2c, $62, $3e, $4a, $62, $51, $45, $42, $62, $30, $4c, $4b, $50
    db $51, $42, $4f, $ef, $ee, $30, $46, $4b, $46, $50, $51, $42, $4f, $5f, $fa, $f7
    db $ef, $ee, $24, $49, $49, $62, $45, $3e, $46, $49, $63, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $2c, $62, $40, $3e, $4b, $62, $51, $42, $49, $49, $62, $56, $4c
    db $52, $ef, $ee, $3e, $3f, $4c, $52, $51, $62, $4d, $49, $3e, $40, $42, $50, $62
    db $54, $45, $42, $4f, $42, $fa, $f7, $ef, $ee, $4a, $3e, $4b, $56, $62, $48, $46
    db $4b, $41, $50, $62, $4c, $43, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50
    db $62, $49, $46, $53, $42, $5f, $ff, $f0
TextStr_48_6bc7:           ; id $04CF
    ; "*:How about the monsters behind / the Gates in the Room of Joy & / Wisdom? [YES/NO]"
    db $ea, $9f, $a3, $2b, $4c, $54, $62, $3e, $3f, $4c, $52, $51, $62, $51, $45, $42
    db $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $3f, $42, $45, $46, $4b
    db $41, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $2a, $3e, $51, $42, $50, $62, $46
    db $4b, $62, $51, $45, $42, $ef, $ee, $35, $4c, $4c, $4a, $62, $4c, $43, $62, $2d
    db $4c, $56, $62, $b6, $fa, $f7, $ef, $ee, $3a, $46, $50, $41, $4c, $4a, $64, $ef
    db $ee, $ff, $f0
TextStr_48_6c1a:           ; id $04D0
    ; "*:Behind the Gate of Joy live / Snailys, Saccers, / *:Gulpples, EyeBalls, / Mummys, Babbles.. and / *:MadPeckers. / *:Behind the Gate of Wis..."
    db $ea, $9f, $a3, $25, $42, $45, $46, $4b, $41, $62, $51, $45, $42, $62, $2a, $3e
    db $51, $42, $ef, $ee, $4c, $43, $62, $2d, $4c, $56, $62, $49, $46, $53, $42, $fa
    db $f7, $ef, $ee, $36, $4b, $3e, $46, $49, $56, $50, $5e, $62, $36, $3e, $40, $40
    db $42, $4f, $50, $5e, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2a, $52, $49, $4d
    db $4d, $49, $42, $50, $5e, $ef, $ee, $28, $56, $42, $25, $3e, $49, $49, $50, $5e
    db $fa, $f7, $ef, $ee, $30, $52, $4a, $4a, $56, $50, $5e, $62, $25, $3e, $3f, $3f
    db $49, $42, $50, $5f, $5f, $ef, $ee, $3e, $4b, $41, $fa, $f7, $ef, $ee, $9f, $a3
    db $30, $3e, $41, $33, $42, $40, $48, $42, $4f, $50, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $25, $42, $45, $46, $4b, $41, $62, $51, $45, $42, $62, $2a, $3e
    db $51, $42, $ef, $ee, $4c, $43, $62, $3a, $46, $50, $41, $4c, $4a, $62, $49, $46
    db $53, $42, $5e, $fa, $f7, $ef, $ee, $29, $3e, $40, $42, $4f, $50, $5e, $ef, $ee
    db $37, $4c, $4b, $44, $52, $42, $49, $49, $3e, $50, $5e, $fa, $f7, $ef, $ee, $9f
    db $a3, $29, $49, $4c, $4f, $3e, $47, $3e, $56, $50, $5e, $ef, $ee, $24, $4f, $4a
    db $4c, $4f, $33, $42, $41, $42, $50, $5e, $62, $3e, $4b, $41, $fa, $f7, $ef, $ee
    db $9f, $a3, $33, $51, $42, $4f, $3e, $4b, $4c, $41, $50, $5e, $ef, $ee, $30, $3e
    db $41, $33, $49, $3e, $4b, $51, $5f, $f7, $f0
TextStr_48_6d13:           ; id $04D1
    ; "*:How about the monsters behind / the Gates in the Room of Happiness / & Temptation? [YES/NO]"
    db $ea, $9f, $a3, $2b, $4c, $54, $62, $3e, $3f, $4c, $52, $51, $62, $51, $45, $42
    db $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $3f, $42, $45, $46, $4b
    db $41, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $2a, $3e, $51, $42, $50, $62, $46
    db $4b, $62, $51, $45, $42, $ef, $ee, $35, $4c, $4c, $4a, $62, $4c, $43, $62, $2b
    db $3e, $4d, $4d, $46, $4b, $42, $50, $50, $fa, $f7, $ef, $ee, $b6, $62, $37, $42
    db $4a, $4d, $51, $3e, $51, $46, $4c, $4b, $64, $ef, $ee, $ff, $f0
TextStr_48_6d70:           ; id $04D2
    ; "*:Behind the Gate of Happiness live / Onionos, Gasgons, / *:Gophecadas, Pixys, StubBirds, / and DeadNites. / *:Behind the gate of Temptation..."
    db $ea, $9f, $a3, $25, $42, $45, $46, $4b, $41, $62, $51, $45, $42, $62, $2a, $3e
    db $51, $42, $ef, $ee, $4c, $43, $62, $2b, $3e, $4d, $4d, $46, $4b, $42, $50, $50
    db $62, $49, $46, $53, $42, $fa, $f7, $ef, $ee, $32, $4b, $46, $4c, $4b, $4c, $50
    db $5e, $ef, $ee, $2a, $3e, $50, $44, $4c, $4b, $50, $5e, $fa, $f7, $ef, $ee, $9f
    db $a3, $2a, $4c, $4d, $45, $42, $40, $3e, $41, $3e, $50, $5e, $ef, $ee, $33, $46
    db $55, $56, $50, $5e, $62, $36, $51, $52, $3f, $25, $46, $4f, $41, $50, $5e, $fa
    db $f7, $ef, $ee, $3e, $4b, $41, $62, $27, $42, $3e, $41, $31, $46, $51, $42, $50
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25, $42, $45, $46, $4b, $41, $62
    db $51, $45, $42, $62, $44, $3e, $51, $42, $ef, $ee, $4c, $43, $62, $37, $42, $4a
    db $4d, $51, $3e, $51, $46, $4c, $4b, $62, $49, $46, $53, $42, $fa, $f7, $ef, $ee
    db $36, $4d, $46, $48, $56, $25, $4c, $56, $50, $5e, $ef, $ee, $2e, $46, $4b, $44
    db $26, $4c, $3f, $4f, $3e, $50, $5e, $fa, $f7, $ef, $ee, $30, $4c, $4a, $4a, $4c
    db $4b, $47, $3e, $50, $5e, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $36, $51, $3e
    db $44, $25, $52, $44, $50, $5e, $ef, $ee, $36, $49, $46, $4a, $42, $31, $46, $51
    db $42, $50, $5e, $62, $3e, $4b, $41, $fa, $f7, $ef, $ee, $30, $46, $50, $51, $56
    db $3a, $46, $4b, $44, $50, $5f, $ef, $ee, $f7, $f0
TextStr_48_6e6a:           ; id $04D3
    ; "*:How about the monsters behind / the Gates in the Room of / Labyrinth & Judgment. [YES/NO]"
    db $ea, $9f, $a3, $2b, $4c, $54, $62, $3e, $3f, $4c, $52, $51, $62, $51, $45, $42
    db $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $3f, $42, $45, $46, $4b
    db $41, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $2a, $3e, $51, $42, $50, $62, $46
    db $4b, $62, $51, $45, $42, $ef, $ee, $35, $4c, $4c, $4a, $62, $4c, $43, $fa, $f7
    db $ef, $ee, $2f, $3e, $3f, $56, $4f, $46, $4b, $51, $45, $ef, $ee, $b6, $62, $2d
    db $52, $41, $44, $4a, $42, $4b, $51, $5f, $ff, $f0
TextStr_48_6ec4:           ; id $04D4
    ; "*:Behind the Gate of Labyrinth live / Chamelgons, RockSlimes, / DuckKites, / *:CactiBalls, TailEaters, / AgDevils, / *:and WindMerges. / *:B..."
    db $ea, $9f, $a3, $25, $42, $45, $46, $4b, $41, $62, $51, $45, $42, $62, $2a, $3e
    db $51, $42, $ef, $ee, $4c, $43, $62, $2f, $3e, $3f, $56, $4f, $46, $4b, $51, $45
    db $62, $49, $46, $53, $42, $fa, $f7, $ef, $ee, $26, $45, $3e, $4a, $42, $49, $44
    db $4c, $4b, $50, $5e, $ef, $ee, $35, $4c, $40, $48, $36, $49, $46, $4a, $42, $50
    db $5e, $fa, $f7, $ef, $ee, $27, $52, $40, $48, $2e, $46, $51, $42, $50, $5e, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $26, $3e, $40, $51, $46, $25, $3e, $49, $49
    db $50, $5e, $ef, $ee, $37, $3e, $46, $49, $28, $3e, $51, $42, $4f, $50, $5e, $fa
    db $f7, $ef, $ee, $24, $44, $27, $42, $53, $46, $49, $50, $5e, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $3e, $4b, $41, $62, $3a, $46, $4b, $41, $30, $42, $4f, $44
    db $42, $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25, $42, $45, $46, $4b
    db $41, $62, $51, $45, $42, $62, $2a, $3e, $51, $42, $ef, $ee, $4c, $43, $62, $2d
    db $52, $41, $44, $4a, $42, $4b, $51, $62, $49, $46, $53, $42, $fa, $f7, $ef, $ee
    db $2b, $3e, $4a, $4a, $42, $4f, $30, $42, $4b, $5e, $ef, $ee, $3a, $42, $42, $41
    db $25, $52, $44, $50, $5e, $fa, $f7, $ef, $ee, $30, $3e, $41, $2a, $42, $42, $50
    db $42, $5e, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $4f, $42, $42, $25, $4c
    db $56, $50, $5e, $ef, $ee, $36, $4d, $4c, $51, $2e, $46, $4b, $44, $50, $5e, $62
    db $27, $4f, $4c, $49, $49, $50, $5e, $fa, $f7, $ef, $ee, $2f, $46, $57, $3e, $4f
    db $41, $29, $49, $56, $50, $5e, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3e, $4b
    db $41, $62, $2a, $46, $3e, $4b, $51, $30, $4c, $51, $45, $50, $63, $ef, $ee, $f7
    db $f0
TextStr_48_6ff5:           ; id $04D5
    ; "*:How about the monsters living / behind the Gate in the Room of / Reflection. [YES/NO]"
    db $ea, $9f, $a3, $2b, $4c, $54, $62, $3e, $3f, $4c, $52, $51, $62, $51, $45, $42
    db $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $49, $46, $53, $46, $4b
    db $44, $fa, $f7, $ef, $ee, $3f, $42, $45, $46, $4b, $41, $62, $51, $45, $42, $62
    db $2a, $3e, $51, $42, $ef, $ee, $46, $4b, $62, $51, $45, $42, $62, $35, $4c, $4c
    db $4a, $62, $4c, $43, $fa, $f7, $ef, $ee, $35, $42, $43, $49, $42, $40, $51, $46
    db $4c, $4b, $5f, $ef, $ee, $ff, $f0
TextStr_48_704c:           ; id $04D6
    ; "*:Behind the Gate of Reflection live / EvilBeasts, Shadows, / *:EvilWands, LizardMen, / SlimeBorgs, FireWeeds, / *:Wyverns, MadHornets, / Li..."
    db $ea, $9f, $a3, $25, $42, $45, $46, $4b, $41, $62, $51, $45, $42, $62, $2a, $3e
    db $51, $42, $ef, $ee, $4c, $43, $62, $35, $42, $43, $49, $42, $40, $51, $46, $4c
    db $4b, $62, $49, $46, $53, $42, $fa, $f7, $ef, $ee, $28, $53, $46, $49, $25, $42
    db $3e, $50, $51, $50, $5e, $ef, $ee, $36, $45, $3e, $41, $4c, $54, $50, $5e, $fa
    db $f7, $ef, $ee, $9f, $a3, $28, $53, $46, $49, $3a, $3e, $4b, $41, $50, $5e, $ef
    db $ee, $2f, $46, $57, $3e, $4f, $41, $30, $42, $4b, $5e, $fa, $f7, $ef, $ee, $36
    db $49, $46, $4a, $42, $25, $4c, $4f, $44, $50, $5e, $ef, $ee, $29, $46, $4f, $42
    db $3a, $42, $42, $41, $50, $5e, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $56, $53, $42
    db $4f, $4b, $50, $5e, $ef, $ee, $30, $3e, $41, $2b, $4c, $4f, $4b, $42, $51, $50
    db $5e, $fa, $f7, $ef, $ee, $2f, $46, $4c, $4b, $42, $55, $50, $5e, $ef, $ee, $35
    db $4c, $51, $35, $3e, $53, $42, $4b, $50, $5e, $fa, $f7, $ef, $ee, $9f, $a3, $2a
    db $4f, $46, $57, $57, $49, $56, $50, $5e, $ef, $ee, $3e, $4b, $41, $62, $2d, $42
    db $54, $42, $49, $25, $3e, $44, $50, $63, $f7, $f0
TextStr_48_7116:           ; id $04D7
    ; "*:I will do anything for you!"
    db $ea, $9f, $a3, $2c, $62, $54, $46, $49, $49, $62, $41, $4c, $ef, $ee, $3e, $4b
    db $56, $51, $45, $46, $4b, $44, $62, $43, $4c, $4f, $62, $56, $4c, $52, $63, $f7
    db $f0
TextStr_48_7137:           ; id $04D8
    ; "*:Ha ha ha! I made Gigantes brave! / *:Books are fun! I can change their / personalities so easily!"
    db $ea, $9f, $a3, $2b, $3e, $62, $45, $3e, $62, $45, $3e, $63, $62, $2c, $62, $4a
    db $3e, $41, $42, $ef, $ee, $2a, $46, $44, $3e, $4b, $51, $42, $50, $62, $3f, $4f
    db $3e, $53, $42, $63, $fa, $f7, $ef, $ee, $9f, $a3, $25, $4c, $4c, $48, $50, $62
    db $3e, $4f, $42, $62, $43, $52, $4b, $63, $ef, $ee, $2c, $62, $40, $3e, $4b, $62
    db $40, $45, $3e, $4b, $44, $42, $62, $51, $45, $42, $46, $4f, $fa, $f7, $ef, $ee
    db $4d, $42, $4f, $50, $4c, $4b, $3e, $49, $46, $51, $46, $42, $50, $ef, $ee, $50
    db $4c, $62, $42, $3e, $50, $46, $49, $56, $63, $f7, $f0
TextStr_48_71a2:           ; id $04D9
    ; "*:Oh, you have it! Then... / *:Hm? You only have one monster / with you! / *:I can't take it because you only / have one!"
    db $ea, $9f, $a3, $32, $45, $5e, $62, $56, $4c, $52, $62, $45, $3e, $53, $42, $62
    db $46, $51, $63, $ef, $ee, $37, $45, $42, $4b, $5f, $5f, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $2b, $4a, $64, $62, $3c, $4c, $52, $62, $4c, $4b, $49, $56, $ef, $ee
    db $45, $3e, $53, $42, $62, $4c, $4b, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f
    db $fa, $f7, $ef, $ee, $54, $46, $51, $45, $62, $56, $4c, $52, $63, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $2c, $62, $40, $3e, $4b, $67, $62, $51, $3e, $48, $42
    db $62, $46, $51, $ef, $ee, $3f, $42, $40, $3e, $52, $50, $42, $62, $56, $4c, $52
    db $62, $4c, $4b, $49, $56, $fa, $f7, $ef, $ee, $45, $3e, $53, $42, $62, $4c, $4b
    db $42, $63, $ef, $ee, $f7, $f0
TextStr_48_7228:           ; id $04DA
    ; "*:Flaring.... I am MadCandle. / *:My flame is more intense / than usual... / *:I wonder if it is because the / Starry Night is near..."
    db $ea, $9f, $a3, $29, $49, $3e, $4f, $46, $4b, $44, $5f, $5f, $5f, $5f, $ef, $ee
    db $2c, $62, $3e, $4a, $62, $30, $3e, $41, $26, $3e, $4b, $41, $49, $42, $5f, $fa
    db $f7, $ef, $ee, $9f, $a3, $30, $56, $62, $43, $49, $3e, $4a, $42, $62, $46, $50
    db $ef, $ee, $4a, $4c, $4f, $42, $62, $46, $4b, $51, $42, $4b, $50, $42, $fa, $f7
    db $ef, $ee, $51, $45, $3e, $4b, $62, $52, $50, $52, $3e, $49, $5f, $5f, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $54, $4c, $4b, $41, $42, $4f, $62
    db $46, $43, $62, $46, $51, $ef, $ee, $46, $50, $62, $3f, $42, $40, $3e, $52, $50
    db $42, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $36, $51, $3e, $4f, $4f, $56, $62
    db $31, $46, $44, $45, $51, $62, $46, $50, $ef, $ee, $4b, $42, $3e, $4f, $5f, $5f
    db $5f, $f7, $f0
TextStr_48_72bb:           ; id $04DB
    ; "*:You must listen to my request! / *:Bring me A Reaper! / *:A Reaper has a big scythe!"
    db $eb, $9f, $a3, $3c, $4c, $52, $62, $4a, $52, $50, $51, $62, $49, $46, $50, $51
    db $42, $4b, $ef, $ee, $51, $4c, $62, $4a, $56, $62, $4f, $42, $4e, $52, $42, $50
    db $51, $63, $fa, $f7, $ef, $ee, $9f, $a3, $25, $4f, $46, $4b, $44, $62, $4a, $42
    db $ef, $ee, $24, $62, $35, $42, $3e, $4d, $42, $4f, $63, $fa, $f7, $ef, $ee, $9f
    db $a3, $24, $62, $35, $42, $3e, $4d, $42, $4f, $62, $45, $3e, $50, $62, $3e, $ef
    db $ee, $3f, $46, $44, $62, $50, $40, $56, $51, $45, $42, $63, $f7, $f0
TextStr_48_7319:           ; id $04DC
    ; "*:Oh, it is a Reaper! What a / sharp scythe! / *:Well done. I'll give you a / reward."
    db $eb, $9f, $a3, $32, $45, $5e, $62, $46, $51, $62, $46, $50, $ef, $ee, $3e, $62
    db $35, $42, $3e, $4d, $42, $4f, $63, $62, $3a, $45, $3e, $51, $62, $3e, $fa, $f7
    db $ef, $ee, $50, $45, $3e, $4f, $4d, $62, $50, $40, $56, $51, $45, $42, $63, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $42, $49, $49, $62, $41, $4c, $4b, $42
    db $5f, $ef, $ee, $2c, $66, $49, $62, $44, $46, $53, $42, $62, $56, $4c, $52, $62
    db $3e, $fa, $f7, $ef, $ee, $4f, $42, $54, $3e, $4f, $41, $5f, $ef, $ee, $fa, $f7
    db $f0
TextStr_48_737a:           ; id $04DD
    ; "*:[HERO], lemme tell you. / *:I heard a terrible master is / participating in the tournament. / *:Be careful! They say this master / is brut..."
    db $eb, $9f, $a3, $f6, $5e, $62, $49, $42, $4a, $4a, $42, $ef, $ee, $51, $42, $49
    db $49, $62, $56, $4c, $52, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $45, $42
    db $3e, $4f, $41, $62, $3e, $ef, $ee, $51, $42, $4f, $4f, $46, $3f, $49, $42, $62
    db $4a, $3e, $50, $51, $42, $4f, $62, $46, $50, $fa, $f7, $ef, $ee, $4d, $3e, $4f
    db $51, $46, $40, $46, $4d, $3e, $51, $46, $4b, $44, $62, $46, $4b, $ef, $ee, $51
    db $45, $42, $62, $51, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $5f, $fa, $f7
    db $ef, $ee, $9f, $a3, $25, $42, $62, $40, $3e, $4f, $42, $43, $52, $49, $63, $62
    db $37, $45, $42, $56, $ef, $ee, $50, $3e, $56, $62, $51, $45, $46, $50, $62, $4a
    db $3e, $50, $51, $42, $4f, $fa, $f7, $ef, $ee, $46, $50, $62, $3f, $4f, $52, $51
    db $3e, $49, $63, $ef, $ee, $f7, $f0
TextStr_48_7411:           ; id $04DE
    ; "*:[HERO]! You are the first person / *:who ever came back unaffected! / *:You're at the Room of / Reflection. The Gate of Reflection / is ov..."
    db $ea, $9f, $a3, $f6, $63, $62, $3c, $4c, $52, $62, $3e, $4f, $42, $ef, $ee, $51
    db $45, $42, $62, $43, $46, $4f, $50, $51, $62, $4d, $42, $4f, $50, $4c, $4b, $fa
    db $f7, $ef, $ee, $9f, $a3, $54, $45, $4c, $62, $42, $53, $42, $4f, $62, $40, $3e
    db $4a, $42, $ef, $ee, $3f, $3e, $40, $48, $62, $52, $4b, $3e, $43, $43, $42, $40
    db $51, $42, $41, $63, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $69, $42, $62
    db $3e, $51, $ef, $ee, $51, $45, $42, $62, $35, $4c, $4c, $4a, $62, $4c, $43, $fa
    db $f7, $ef, $ee, $35, $42, $43, $49, $42, $40, $51, $46, $4c, $4b, $5f, $62, $37
    db $45, $42, $ef, $ee, $2a, $3e, $51, $42, $62, $4c, $43, $62, $35, $42, $43, $49
    db $42, $40, $51, $46, $4c, $4b, $fa, $f7, $ef, $ee, $46, $50, $62, $4c, $53, $42
    db $4f, $62, $51, $45, $42, $4f, $42, $63, $ef, $ee, $f7, $f0
TextStr_48_74ad:           ; id $04DF
    ; "*:Ladies & Gents! Welcome! / *:Tonight is the night you've been / waiting for!! / *:Monster masters from all over the / world will display /..."
    db $eb, $9f, $a3, $2f, $3e, $41, $46, $42, $50, $62, $b6, $62, $2a, $42, $4b, $51
    db $50, $63, $ef, $ee, $3a, $42, $49, $40, $4c, $4a, $42, $63, $fa, $f7, $ef, $ee
    db $9f, $a3, $37, $4c, $4b, $46, $44, $45, $51, $62, $46, $50, $62, $51, $45, $42
    db $ef, $ee, $4b, $46, $44, $45, $51, $62, $56, $4c, $52, $6c, $42, $62, $3f, $42
    db $42, $4b, $fa, $f7, $ef, $ee, $54, $3e, $46, $51, $46, $4b, $44, $62, $43, $4c
    db $4f, $63, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $30, $4c, $4b, $50, $51
    db $42, $4f, $62, $4a, $3e, $50, $51, $42, $4f, $50, $ef, $ee, $43, $4f, $4c, $4a
    db $62, $3e, $49, $49, $62, $4c, $53, $42, $4f, $62, $51, $45, $42, $fa, $f7, $ef
    db $ee, $54, $4c, $4f, $49, $41, $62, $54, $46, $49, $49, $62, $41, $46, $50, $4d
    db $49, $3e, $56, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $51, $45, $42, $46, $4f
    db $62, $51, $3e, $49, $42, $4b, $51, $50, $ef, $ee, $43, $4c, $4f, $62, $52, $50
    db $63, $63, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $48, $46, $4b, $44
    db $41, $4c, $4a, $62, $51, $45, $3e, $51, $ef, $ee, $41, $42, $43, $42, $3e, $51
    db $50, $62, $3e, $49, $49, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $4c, $51, $45
    db $42, $4f, $50, $62, $54, $46, $49, $49, $62, $4c, $54, $4b, $ef, $ee, $51, $45
    db $42, $62, $41, $3e, $56, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45, $46, $40
    db $45, $62, $48, $46, $4b, $44, $41, $4c, $4a, $ef, $ee, $54, $46, $49, $49, $62
    db $54, $42, $3e, $4f, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $40, $4f, $4c, $54
    db $4b, $62, $4c, $43, $62, $53, $46, $40, $51, $4c, $4f, $56, $64, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $2f, $42, $51, $68, $62, $3f, $42, $44, $46, $4b, $63
    db $ef, $ee, $f7, $f0, $00
; --- END re-sectioned text run (bank $48) ---
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

