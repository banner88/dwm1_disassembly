; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $048", ROMX[$4000], BANK[$48]

    db $48 ; Bank number

    ; Cross-bank dispatch table (112 entries)
    ; Called via: ld hl, $48XX / rst $10
    dw LoadB48_40e1                  ; Entry 0
    dw $410F                          ; Entry 1
    dw $413D                          ; Entry 2
    dw $4009                          ; Entry 3 — mode 0 -> table $4009 (mode list $4007)
    dw $416B                          ; Entry 4 — [table $4009]; text $0474 "Durran:Come on Terry! Fight to yo…"
    dw $41D2                          ; Entry 5 — text $0475 "Durran:Ha ha ha! How easily you d…"
    dw $4294                          ; Entry 6 — text $0476 "Durran:Want a real thrill? Fight …"
    dw $42FF                          ; Entry 7 — text $0477 "Durran:How was it? Learn anything…"
    dw $435D                          ; Entry 8 — text $0478 "Durran:Here I come!!"
    dw $4375                          ; Entry 9 — text $0479 "Durran:Did I lose? .. I lost... D…"
    dw $44B1                          ; Entry 10 — text $047A "TERRY?:..You're strong... You eve…"
    dw $45FC                          ; Entry 11 — text $047B "Do you really want to tell your t…"
    dw $4636                          ; Entry 12 — text $047C "TERRY?:It's okay. I know..."
    dw $4655                          ; Entry 13 — text $047D "TERRY?:No. It's okay... I know..."
    dw $467A                          ; Entry 14 — text $047E "*:Good luck on your journey!"
    dw $469A                          ; Entry 15 — text $047F "TERRY?:Ahhh... For some reason, I…"
    dw $477F                          ; Entry 16 — text $0480 "TERRY?:[HERO], don't become like …"
    dw $485F                          ; Entry 17 — text $0481 "TERRY?:Farewell [HERO]! I'm takin…"
    dw $48B0                          ; Entry 18 — text $0482 "TERRY?:Take care of your sister. …"
    dw $48EA                          ; Entry 19 — text $0483 "TERRY?:...You don't want to hear …"
    dw $4962                          ; Entry 20 — text $0484 "Watabou:Let's go back!"
    dw $497B                          ; Entry 21 — text $0485 "King:[HERO]! How was it? What lie…"
    dw $4AA9                          ; Entry 22 — text $0486 "King:Oh [HERO]! Did you rest? Kin…"
    dw $4B62                          ; Entry 23 — text $0487 "*:You're at the Chamber of Travel…"
    dw $4C3F                          ; Entry 24 — text $0488 "King:Anyway! Your wish will come …"
    dw $4E5A                          ; Entry 25 — text $0489 "*:Now, head to the arena! *:A gre…"
    dw $4EAF                          ; Entry 26 — text $048A "*:Let me tell you the legend of t…"
    dw $506E                          ; Entry 27 — text $048B "*:Oh bless Starry Night and Maste…"
    dw $509C                          ; Entry 28 — text $048C "*:Long long ago.. an ancestor of …"
    dw $51AA                          ; Entry 29 — text $048D "*:You're at the castle of GreatTr…"
    dw $51F7                          ; Entry 30 — text $048E "*:Good luck at the Starry Night T…"
    dw $5239                          ; Entry 31 — text $048F "*:You don't have it? You should b…"
    dw $52CC                          ; Entry 32 — text $0490 "*:Bring them to the Medal Man ups…"
    dw $533F                          ; Entry 33 — text $0491 "*:Many people are heading to Grea…"
    dw $53B5                          ; Entry 34 — text $0492 "*:Watabou will be happy if you wi…"
    dw $542C                          ; Entry 35 — text $0493 "*:You can win! ...I feel it! *:I …"
    dw $54B9                          ; Entry 36 — text $0494 "*:Proceed to the Vault. Good luck!"
    dw $54DF                          ; Entry 37 — text $0495 "*:Go right to the Bazaar! *:It's …"
    dw $5524                          ; Entry 38 — text $0496 "*:Go right to the Bazaar! *:Oh [H…"
    dw $5568                          ; Entry 39 — text $0497 "*:Are you... really competing in …"
    dw $55A1                          ; Entry 40 — text $0498 "*:...Don't lose."
    dw $55B5                          ; Entry 41 — text $0499 "*:...Don't lose. Don't make me sa…"
    dw $55F0                          ; Entry 42 — text $049A "*:You're right! It's impossible f…"
    dw $5629                          ; Entry 43 — text $049B "*:...you. Don't you regret saying…"
    dw $5658                          ; Entry 44 — text $049C "*:The Master Monster Tamer downst…"
    dw $56B5                          ; Entry 45 — text $049D "*:A surprise awaits you in your f…"
    dw $5726                          ; Entry 46 — text $049E "*:I wish you good luck! All rooms…"
    dw $57F4                          ; Entry 47 — text $049F "*:All Gates are now yours! *:The …"
    dw $58AF                          ; Entry 48 — text $04A0 "*:What kind of future did you see…"
    dw $593A                          ; Entry 49 — text $04A1 "*:We'll spend the Starry Night, t…"
    dw $597F                          ; Entry 50 — text $04A2 "*:Hello. Down to the stable. Blea…"
    dw $59F3                          ; Entry 51 — text $04A3 "*:The Starry Night is soon. Yeah!…"
    dw $5A27                          ; Entry 52 — text $04A4 "*:There's something good about ha…"
    dw $5A67                          ; Entry 53 — text $04A5 "*:As the Starry Night nears, I wa…"
    dw $5AA4                          ; Entry 54 — text $04A6 "*:As the Starry Night nears, it m…"
    dw $5B12                          ; Entry 55 — text $04A7 "*:Power is flowing all around me!…"
    dw $5B66                          ; Entry 56 — text $04A8 "*:When the Starry Night nears, my…"
    dw $5BA2                          ; Entry 57 — text $04A9 "*:Zzz..... ..zzz. Bust! *:Mm? Is …"
    dw $5BE8                          ; Entry 58 — text $04AA "*:I feel it! GreatTree is shaking…"
    dw $5C4F                          ; Entry 59 — text $04AB "*:Of course GreatTree will triump…"
    dw $5C7B                          ; Entry 60 — text $04AC "*:It's GreatLog! GreatLog, will c…"
    dw $5CB1                          ; Entry 61 — text $04AD "*:I believe DeadTree will be vict…"
    dw $5CE2                          ; Entry 62 — text $04AE "*:You win, GreatTree happy. Eek!"
    dw $5D0B                          ; Entry 63 — text $04AF "*:You made it! Good job! *:Fight …"
    dw $5D5F                          ; Entry 64 — text $04B0 "*:Let me know when you're ready."
    dw $5D82                          ; Entry 65 — text $04B1 "*:Announcing the rep of GreatTree…"
    dw $5DB0                          ; Entry 66 — text $04B2 "*:The Starry Night Tournament is …"
    dw $5E79                          ; Entry 67 — text $04B3 "*:Want to listen to the descripti…"
    dw $5EB8                          ; Entry 68 — text $04B4 "*:Everybody in the kingdom is beh…"
    dw $5F05                          ; Entry 69 — text $04B5 "*:You made it! *:I can't even com…"
    dw $5F4B                          ; Entry 70 — text $04B6 "*:Oh! Its a HornBeet! What a magn…"
    dw $5FB0                          ; Entry 71 — text $04B7 "*:Wyvern!"
    dw $5FBE                          ; Entry 72 — text $04B8 "*:Come on! Pray! Pray to the stat…"
    dw $602C                          ; Entry 73 — text $04B9 "[HERO] reads the blackboard. :The…"
    dw $60A0                          ; Entry 74 — text $04BA "*:Here is MysticNut. Use it wisel…"
    dw $60CC                          ; Entry 75 — text $04BB "*:My heart is pounding! The battl…"
    dw $616A                          ; Entry 76 — text $04BC "*:This is Shoyu! Bebe! Repeat aft…"
    dw $61A0                          ; Entry 77 — text $04BD "*:What the heck is Shoyu! Can't y…"
    dw $61DE                          ; Entry 78 — text $04BE "*:Splash Splash! When the Starry …"
    dw $624D                          ; Entry 79 — text $04BF "*:I would like to go deep in the …"
    dw $62F0                          ; Entry 80 — text $04C0 "[HERO] looked at the bookshelf. :…"
    dw $6383                          ; Entry 81 — text $04C1 ":[HERO] already conquered D class…"
    dw $646B                          ; Entry 82 — text $04C2 ":At last [HERO] will participate …"
    dw $64E0                          ; Entry 83 — text $04C3 "*:The combination with the same m…"
    dw $65D3                          ; Entry 84 — text $04C4 "*:Many Stars fall from the sky on…"
    dw $6634                          ; Entry 85 — text $04C5 "*:Do you know my daughter? [YES/N…"
    dw $6652                          ; Entry 86 — text $04C6 "*:No!? You don't know such a cute…"
    dw $66D1                          ; Entry 87 — text $04C7 "*:She's the most graceful girl in…"
    dw $6713                          ; Entry 88 — text $04C8 "*:You're promising! Let me tell y…"
    dw $6813                          ; Entry 89 — text $04C9 "*:My hubby adores our girl.. *:Re…"
    dw $6857                          ; Entry 90 — text $04CA ":Journal of My Baby, Part 3 :Flat…"
    dw $691E                          ; Entry 91 — text $04CB ":Journal of My Baby, Part 4 :I gu…"
    dw $69CC                          ; Entry 92 — text $04CC "*:I heard a wish will come true w…"
    dw $6ACB                          ; Entry 93 — text $04CD "*:I'm looking for a book. *:I can…"
    dw $6B4F                          ; Entry 94 — text $04CE "*:I am the Monster Minister. All …"
    dw $6BC7                          ; Entry 95 — text $04CF "*:How about the monsters behind t…"
    dw $6C1A                          ; Entry 96 — text $04D0 "*:Behind the Gate of Joy live Sna…"
    dw $6D13                          ; Entry 97 — text $04D1 "*:How about the monsters behind t…"
    dw $6D70                          ; Entry 98 — text $04D2 "*:Behind the Gate of Happiness li…"
    dw $6E6A                          ; Entry 99 — text $04D3 "*:How about the monsters behind t…"
    dw $6EC4                          ; Entry 100 — text $04D4 "*:Behind the Gate of Labyrinth li…"
    dw $6FF5                          ; Entry 101 — text $04D5 "*:How about the monsters living b…"
    dw $704C                          ; Entry 102 — text $04D6 "*:Behind the Gate of Reflection l…"
    dw $7116                          ; Entry 103 — text $04D7 "*:I will do anything for you!"
    dw $7137                          ; Entry 104 — text $04D8 "*:Ha ha ha! I made Gigantes brave…"
    dw $71A2                          ; Entry 105 — text $04D9 "*:Oh, you have it! Then... *:Hm? …"
    dw $7228                          ; Entry 106 — text $04DA "*:Flaring.... I am MadCandle. *:M…"
    dw $72BB                          ; Entry 107 — text $04DB "*:You must listen to my request! …"
    dw $7319                          ; Entry 108 — text $04DC "*:Oh, it is a Reaper! What a shar…"
    dw $737A                          ; Entry 109 — text $04DD "*:[HERO], lemme tell you. *:I hea…"
    dw $7411                          ; Entry 110 — text $04DE "*:[HERO]! You are the first perso…"
    dw $74AD                          ; Entry 111 — text $04DF "*:Ladies & Gents! Welcome! *:Toni…"

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


    ld [$5227], a
    ld c, a
    ld c, a
    ld a, $4b
    and e
    ld h, $4c
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    rst $28
    xor $37
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, e
    ld h, d
    add hl, hl
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld d, c
    ld l, b
    rst $28
    xor $40
    ld c, h
    ld c, e
    ld d, c
    ld b, d
    ld c, e
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    ld [hl], $45
    ld c, h
    ld d, h
    rst $28
    xor $45
    ld b, [hl]
    ld c, d
    ld h, d
    ld b, l
    ld c, h
    ld d, h
    ld h, d
    ld d, c
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    daa
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    dec hl
    ld a, $62
    ld b, l
    ld a, $62
    ld b, l
    ld a, $63
    rst $28
    xor $2b
    ld c, h
    ld d, h
    ld h, d
    ld b, d
    ld a, $50
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $41
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    ld b, d
    ld b, c
    ld h, d
    ld d, b
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld a, $ef
    xor $3f
    ld c, a
    ld d, d
    ld d, c
    ld a, $49
    ld h, d
    ld c, h
    ld c, l
    ld c, l
    ld c, h
    ld c, e
    ld b, d
    ld c, e
    ld d, c
    ld h, e
    ld h, e
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $3f
    ld a, $41
    ld h, e
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld c, d
    ld d, [hl]
    ld a, [$eff7]
    xor $48
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    scf
    ld c, h
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $50
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld a, $62
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $50
    ld c, h
    ld h, d
    ld c, e
    ld b, d
    ld a, $4f
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $5f
    ld e, a
    ld e, a
    ld d, c
    ld b, l
    ld c, a
    ld b, [hl]
    ld c, c
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
    daa
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    ld a, [hl-]
    ld a, $4b
    ld d, c
    ld h, d
    ld a, $ef
    xor $4f
    ld b, d
    ld a, $49
    ld h, d
    ld d, c
    ld b, l
    ld c, a
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, h
    ld a, [$eff7]
    xor $29
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    ld [hl], $3e
    ld d, c
    ld b, [hl]
    ld d, b
    ld b, e
    ld d, [hl]
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $3f
    ld c, c
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld c, c
    ld d, d
    ld d, b
    ld d, c
    ld h, e
    ld h, d
    scf
    ld a, $50
    ld d, c
    ld b, d
    ld a, [$eff7]
    xor $4a
    ld d, [hl]
    ld h, d
    ld d, b
    ld d, c
    ld b, d
    ld b, d
    ld c, c
    ld h, e
    ld h, d
    add hl, hl
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    daa
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, h
    rst $28
    xor $2f
    ld b, d
    ld a, $4f
    ld c, e
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, h
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    inc h
    ld h, d
    ld c, d
    ld a, $4b
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    rst $28
    xor $43
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld e, a
    ld e, a
    ld e, a
    rst $30
    ldh a, [$ea]
    daa
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    dec hl
    ld b, d
    ld c, a
    ld b, d
    rst $28
    xor $2c
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
    daa
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    daa
    ld b, [hl]
    ld b, c
    ld h, d
    inc l
    ld h, d
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    ld h, h
    rst $28
    xor $5f
    ld e, a
    ld h, d
    inc l
    ld h, d
    ld c, c
    ld c, h
    ld d, b
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    rst $28
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld b, e
    ld d, d
    ld c, c
    ld c, c
    ld d, [hl]
    ld h, e
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld d, d
    ld d, c
    ld d, c
    ld b, d
    ld c, a
    ld c, c
    ld d, [hl]
    rst $28
    xor $41
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    ld b, d
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    inc l
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    ld c, e
    ld h, a
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld c, e
    ld c, b
    ld h, d
    ld a, $62
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $40
    ld a, $49
    ld b, [hl]
    ccf
    ld b, d
    ld c, a
    ld h, d
    ld b, d
    ld d, l
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    cpl
    ld c, h
    ld c, h
    ld c, b
    ld h, e
    ld h, d
    inc l
    ld l, d
    rst $28
    xor $50
    ld d, c
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld d, b
    ld b, l
    ld a, $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $43
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $42
    ld d, l
    ld b, b
    ld b, [hl]
    ld d, c
    ld b, d
    ld c, d
    ld b, d
    ld c, e
    ld d, c
    ld h, e
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    inc l
    ld l, d
    rst $28
    xor $45
    ld c, h
    ld c, e
    ld c, h
    ld c, a
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld a, [$eff7]
    xor $45
    ld a, $41
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld b, l
    ld a, $4b
    ld b, b
    ld b, d
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    dec hl
    ld a, $62
    ld b, l
    ld a, $ef
    xor $45
    ld a, $62
    ld b, l
    ld a, $63
    ld h, e
    rst $30
    ldh a, [$ea]
    scf
    jr z, @+$37

    dec [hl]
    inc a
    ld h, h
    and e
    ld e, a
    ld e, a
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    rst $28
    xor $50
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, e
    ld h, d
    ld b, c
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    ld b, d
    ld b, c
    rst $28
    xor $45
    ld b, [hl]
    ld c, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $37
    jr z, @+$37

    dec [hl]
    inc a
    ld h, h
    and e
    inc l
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld c, e
    ld h, a
    rst $28
    xor $3f
    ld b, d
    ld a, $51
    ld h, d
    ld e, a
    ld e, a
    ld e, a
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld b, h
    ld d, d
    ld d, [hl]
    ld h, e
    ld a, [$eff7]
    xor $37
    jr z, @+$37

    dec [hl]
    inc a
    ld h, h
    and e
    inc l
    ld h, d
    ld c, d
    ld c, h
    ld b, b
    ld c, b
    ld b, d
    ld b, c
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld e, a
    ld h, d
    ld h, $3e
    ld c, c
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $40
    ld c, h
    ld d, h
    ld a, $4f
    ld b, c
    ld e, a
    ld h, d
    ld [hl], $4c
    ld c, d
    ld b, d
    ld c, h
    ld c, e
    ld b, d
    rst $28
    xor $54
    ld b, l
    ld c, h
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, e
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld d, b
    ld d, h
    ld c, h
    ld c, a
    ld b, c
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $37
    jr z, jr_048_45a8

    dec [hl]
    inc a
    ld h, h
    and e
    inc l
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    rst $28
    xor $46
    ld d, c
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld e, a
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld a, [$eff7]
    xor $46
    ld c, e
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, b
    ld b, [hl]
    ccf
    ld c, c
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $37
    jr z, jr_048_45da

    dec [hl]
    inc a
    ld h, h

jr_048_45a8:
    and e
    jr z, jr_048_45fe

    ld b, d
    ld c, e
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld a, $62
    ld d, b
    ld d, h
    ld c, h
    ld c, a
    ld b, c
    ld e, [hl]
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld d, b
    ld d, c
    rst $28
    xor $43
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld b, d
    ld c, a

jr_048_45da:
    ld e, a
    ld a, [$eff7]
    xor $37
    jr z, jr_048_4617

    dec [hl]
    inc a
    ld h, h
    and e
    ld e, a
    ld e, a
    ld e, a
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld l, b
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    ld h, h
    rst $30
    ldh a, [$27]
    ld c, h

jr_048_45fe:
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
    rst $28
    xor $54
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, d
    ld c, c
    ld c, c

jr_048_4617:
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $51
    ld c, a
    ld d, d
    ld b, d
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $37
    jr z, @+$37

    dec [hl]
    inc a
    ld h, h
    rst $38
    ldh a, [$ea]
    scf
    jr z, jr_048_466f

    dec [hl]
    inc a
    ld h, h
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld c, h
    ld c, b
    ld a, $56
    ld e, a
    rst $28
    xor $2c
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld e, a
    ld e, a
    ld e, a
    ld a, [$f0f7]
    ld [$2837], a
    dec [hl]
    dec [hl]
    inc a
    ld h, h
    and e
    ld sp, $5f4c
    ld h, d
    inc l
    ld d, c
    ld l, b
    rst $28
    xor $4c
    ld c, b
    ld a, $56
    ld e, a
    ld e, a
    ld e, a
    ld h, d
    inc l

jr_048_466f:
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld e, a
    ld e, a
    ld e, a
    ld a, [$f0f7]
    ld [$a39f], a
    ld a, [hl+]
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld c, c
    ld d, d
    ld b, b
    ld c, b
    ld h, d
    ld c, h
    ld c, e
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld b, a
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld d, [hl]
    ld h, e
    rst $30
    ldh a, [$ea]
    scf
    jr z, jr_048_46d3

    dec [hl]
    inc a
    ld h, h
    and e
    inc h
    ld b, l
    ld b, l
    ld b, l
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $29
    ld c, h
    ld c, a
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld a, $50
    ld c, h
    ld c, e
    ld e, [hl]
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld b, e
    ld b, d
    ld b, d
    ld c, c
    ld h, d
    ld c, a
    ld b, d
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, e
    ld b, d
    ld b, c
    ld e, a
    rst $28
    xor $fa
    rst $30

jr_048_46d3:
    rst $28
    xor $37
    jr z, jr_048_470d

    dec [hl]
    inc a
    ld h, h
    and e
    ld e, a
    ld e, a
    ld e, a
    ld h, d
    inc l
    ld d, c
    ld l, b
    rst $28
    xor $4a
    ld c, h
    ld c, a
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld e, a
    ld e, a
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld d, h
    ld a, $48
    ld b, d
    ld h, d
    ld d, d
    ld c, l
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $37
    jr z, @+$37

    dec [hl]
    inc a

jr_048_470d:
    ld h, h
    and e
    ld [hl], $4c
    ld h, d
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    rst $28
    xor $f6
    ld h, e
    ld h, d
    ld a, [hl-]
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld d, h
    ld b, d
    ld a, [$eff7]
    xor $4a
    ld b, d
    ld b, d
    ld d, c
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $37
    jr z, jr_048_476f

    dec [hl]
    inc a
    ld h, h
    and e
    ld sp, $5e4c
    ld h, d
    ld c, d
    ld a, $56
    ccf
    ld b, d
    rst $28
    xor $54
    ld b, d
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld c, e
    ld h, a
    ld e, a
    ld a, [$eff7]
    xor $37
    jr z, jr_048_4791

    dec [hl]
    inc a
    ld h, h
    and e
    cpl
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    rst $28
    xor $56
    ld c, h

jr_048_476f:
    ld d, d
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld a, $41
    ld d, e
    ld b, [hl]
    ld b, b
    ld b, d
    ld e, a
    rst $30
    ldh a, [$ea]
    scf
    jr z, jr_048_47b8

    dec [hl]
    inc a
    ld h, h
    and e
    or $5e
    rst $28
    xor $41
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ccf

jr_048_4791:
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $37
    jr z, jr_048_47e1

    dec [hl]
    inc a
    ld h, h
    and e
    ld [hl-], a
    ld c, e
    ld b, b
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d

jr_048_47b8:
    ld l, h
    ld b, d
    rst $28
    xor $51
    ld a, $50
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $44
    ld c, h
    ld c, a
    ld b, h
    ld b, d
    ld h, d
    ld d, d
    ld c, l
    ld c, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld a, $4b

jr_048_47e1:
    ld b, c
    rst $28
    xor $46
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, b
    ld b, l
    ld c, h
    ld c, b
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    ld a, [$eff7]
    xor $37
    jr z, jr_048_4832

    dec [hl]
    inc a
    ld h, h
    and e
    inc sp
    ld b, d
    ld c, a
    ld b, l
    ld a, $4d
    ld d, b
    rst $28
    xor $46
    ld d, c
    ld l, b
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld h, d
    ld c, c
    ld a, $51
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld a, [$eff7]
    xor $4a
    ld b, d
    ld e, a
    ld h, d
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $50
    ld d, c
    ld b, [hl]

jr_048_4832:
    ld c, c
    ld c, c
    ld h, d
    ld b, b
    ld b, l
    ld c, h
    ld c, h
    ld d, b
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    rst $30
    ldh a, [$ea]
    scf
    jr z, jr_048_4898

    dec [hl]
    inc a
    ld h, h
    and e
    add hl, hl
    ld a, $4f
    ld b, d
    ld d, h
    ld b, d
    ld c, c
    ld c, c
    rst $28
    xor $f6
    ld h, e
    ld a, [$eff7]
    xor $2c
    ld l, d
    ld h, d
    ld d, c
    ld a, $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld b, e
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $37
    jr z, @+$37

    dec [hl]
    inc a
    ld h, h
    and e
    ld [hl-], a
    ld c, e
    ld b, d
    ld h, d
    ld c, d
    ld c, h

jr_048_4898:
    ld c, a
    ld b, d
    rst $28
    xor $4d
    ld b, [hl]
    ld b, d
    ld b, b
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, $41
    ld d, e
    ld b, [hl]
    ld b, b
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    rst $38
    ldh a, [$ea]
    scf
    jr z, jr_048_48e9

    dec [hl]
    inc a
    ld h, h
    and e
    scf
    ld a, $48
    ld b, d
    ld h, d
    ld b, b
    ld a, $4f
    ld b, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld d, b
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $31
    ld c, h
    ld h, d
    ld c, d
    ld a, $51
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, h
    ld b, l
    ld a, $51
    ld h, e
    ld h, e
    rst $28
    xor $f7

jr_048_48e9:
    ldh a, [$ea]
    scf
    jr z, jr_048_4923

    dec [hl]
    inc a
    ld h, h
    and e
    ld e, a
    ld e, a
    ld e, a
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $41
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $45
    ld b, d
    ld a, $4f
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld e, [hl]
    rst $28
    xor $3f
    ld d, d
    ld d, c
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld a, $56
    ld h, d
    ld b, [hl]

jr_048_4923:
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $37
    jr z, jr_048_4961

    dec [hl]
    inc a
    ld h, h
    and e
    scf
    ld a, $48
    ld b, d
    ld h, d
    ld b, b
    ld a, $4f
    ld b, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld d, b
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $31
    ld c, h
    ld h, d
    ld c, d
    ld a, $51
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, h
    ld b, l
    ld a, $51
    ld h, e
    ld h, e
    rst $28
    xor $f7

jr_048_4961:
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    cpl
    ld b, d
    ld d, c
    ld l, b
    rst $28
    xor $44
    ld c, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, e
    rst $30
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    or $63
    rst $28
    xor $2b
    ld c, h
    ld d, h
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, h
    ld a, [$eff7]
    xor $3a
    ld b, l
    ld a, $51
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld b, e
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld h, h
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, h
    ld h, d
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $41
    ld b, [hl]
    ld b, c
    ld c, e
    ld h, a
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld a, [$eff7]
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $51
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld h, h
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld e, a
    ld e, a
    ld e, a
    dec hl
    ld c, d
    ld c, d
    ld c, d
    ld e, a
    rst $28
    xor $5f
    ld e, a
    ld e, a
    ld e, a
    dec hl
    ld c, d
    ld c, d
    ld c, d
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc l
    ld d, c
    ld h, d
    ld b, c
    ld c, h
    ld b, d
    ld d, b
    ld c, e
    ld h, a
    rst $28
    xor $4a
    ld a, $51
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld a, [$eff7]
    xor $44
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    rst $28
    xor $3e
    ld c, e
    ld d, [hl]
    ld d, h
    ld a, $56
    ld h, e
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    rst $28
    xor $31
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $3e
    ld c, l
    ld c, l
    ld c, a
    ld c, h
    ld a, $40
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc sp
    ld c, a
    ld b, d
    ld c, l
    ld a, $4f
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld d, c
    ld a, [$eff7]
    xor $56
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
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    or $63
    rst $28
    xor $27
    ld b, [hl]
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld d, c
    ld h, h
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    scf
    ld c, h
    ld c, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, e
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    scf
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    jr nc, jr_048_4b43

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    rst $28
    xor $3e
    ld h, d
    ld b, e
    ld a, $4f
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld d, h
    ld a, $46
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld c, e
    ld a, $63
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e

jr_048_4b43:
    ld b, h
    and e
    dec h
    ld b, d
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    rst $28
    xor $46
    ld c, e
    ld d, c
    ld c, h
    ld h, d
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
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $26
    ld b, l
    ld a, $4a
    ccf
    ld b, d
    ld c, a
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $37
    ld c, a
    ld a, $53
    ld b, d
    ld c, c
    ld b, d
    ld c, a
    ld d, b
    ld e, h
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $f3
    sbc a
    and e
    dec hl
    ld b, d
    ld a, $49
    ld b, d
    ld c, a
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, l
    ld b, d
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
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld a, [$eff7]
    xor $50
    ld c, l
    ld b, d
    ld c, c
    ld c, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    rst $28
    xor $4c
    ld c, e
    ld h, d
    ld a, $62
    ld b, a
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, b
    ld c, h
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld c, e
    ld h, a
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    rst $28
    xor $46
    ld d, c
    ld h, d
    ld b, h
    ld c, h
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    jr nc, jr_048_4c46

    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    rst $28
    xor $44
    ld c, a
    ld a, $41
    ld d, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld h, d
    ld a, $50
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $54
    ld a, $49
    ld c, b
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    inc h

jr_048_4c46:
    ld c, e
    ld d, [hl]
    ld d, h
    ld a, $56
    ld h, e
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $54
    ld b, [hl]
    ld d, b
    ld b, l
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld a, [$eff7]
    xor $51
    ld c, a
    ld d, d
    ld b, d
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc l
    ld h, d
    ld d, c
    ld b, l
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    rst $28
    xor $46
    ld d, c
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, b
    ld b, [hl]
    ld b, c
    ld c, e
    ld a, $4d
    ld c, l
    ld b, d
    ld b, c
    rst $28
    xor $50
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld c, h
    ld c, a
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $44
    ld c, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $45
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    dec [hl]
    ld b, d
    ld b, h
    ld a, $4f
    ld b, c
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld e, [hl]
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld l, h
    ld b, d
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, b
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $53
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld b, l
    ld a, $4f
    ld b, c
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    dec h
    ld c, h
    ld d, c
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4d
    ld b, d
    ld c, h
    ld c, l
    ld c, c
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, d
    ld d, [hl]
    ld a, [$eff7]
    xor $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    inc l
    rst $28
    xor $51
    ld c, a
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $3e
    ccf
    ld b, [hl]
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, [hl]
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc a
    ld c, h
    ld d, d
    ld e, a
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $3f
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, h
    ld c, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $f6
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ccf
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    rst $28
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld h, d
    or [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    ld h, e
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc l
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $4d
    ld c, a
    ld b, d
    ld c, l
    ld a, $4f
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld e, a
    rst $28
    xor $27
    ld b, [hl]
    ld d, b
    ld c, d
    ld b, [hl]
    ld d, b
    ld d, b
    ld b, d
    ld b, c
    ld h, e
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    dec h
    ld d, d
    ld d, b
    ld d, [hl]
    ld h, e
    ld h, d
    dec h
    ld d, d
    ld d, b
    ld d, [hl]
    ld h, e
    rst $28
    xor $25
    ld d, d
    ld d, b
    ld d, [hl]
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld sp, $544c
    ld e, [hl]
    ld h, d
    ld b, l
    ld b, d
    ld a, $41
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld c, e
    ld a, $63
    ld a, [$eff7]
    xor $9f
    and e
    inc h
    ld h, d
    ld b, h
    ld c, a
    ld b, d
    ld a, $51
    ld h, d
    ld a, $52
    ld b, c
    ld b, [hl]
    ld b, d
    ld c, e
    ld b, b
    ld b, d
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld d, h
    ld a, $46
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    jr nc, jr_048_4ee3

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $f6
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    cpl
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld b, h
    ld b, d
    ld c, e
    ld b, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $36
    ld d, c
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l

jr_048_4ee3:
    ld d, c
    rst $28
    xor $3e
    ld b, h
    ld a, $46
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    rst $28
    xor $40
    ld c, h
    ld c, d
    ld b, d
    ld d, b
    ld h, d
    ld a, $43
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld a, [$eff7]
    xor $04
    rlca
    ld d, c
    ld b, l
    ld h, d
    ld b, e
    ld d, d
    ld c, c
    ld c, c
    ld h, d
    ld c, d
    ld c, h
    ld c, h
    ld c, e
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
    ld d, d
    ld c, e
    ld b, c
    ld c, a
    ld b, d
    ld b, c
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $51
    ld b, l
    ld c, h
    ld d, d
    ld d, b
    ld a, $4b
    ld b, c
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, b
    ld a, [$eff7]
    xor $9f
    and e
    ld b, e
    ld a, $49
    ld c, c
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, b
    ld d, [hl]
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
    ld d, d
    ld c, e
    ld b, c
    ld c, a
    ld b, d
    ld b, c
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $51
    ld b, l
    ld c, h
    ld d, d
    ld d, b
    ld a, $4b
    ld b, c
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, b
    ld a, [$eff7]
    xor $9f
    and e
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $36
    ld d, c
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld c, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    rst $28
    xor $40
    ld c, h
    ld d, d
    ld c, e
    ld d, c
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    ld a, [$eff7]
    xor $50
    ld b, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld h, d
    ld b, c
    ld c, h
    ld d, h
    ld c, e
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    scf
    ld c, h
    ld h, d
    ld b, b
    ld b, d
    ld c, c
    ld b, d
    ccf
    ld c, a
    ld a, $51
    ld b, d
    ld e, [hl]
    rst $28
    xor $3e
    ld h, d
    ld b, h
    ld c, a
    ld b, d
    ld a, $51
    ld a, [$eff7]
    xor $51
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $45
    ld b, d
    ld c, c
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $9f
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
    xor $36
    ld d, c
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    ld a, [$eff7]
    xor $37
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ccf
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    rst $28
    xor $36
    ld d, c
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    ld h, d
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $30
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    or $63
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    cpl
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld a, $44
    ld c, h
    ld e, a
    ld e, a
    rst $28
    xor $3e
    ld c, e
    ld h, d
    ld a, $4b
    ld b, b
    ld b, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, d
    ld c, c
    ld c, h
    ld b, b
    ld c, b
    ld b, d
    ld b, c
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
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ccf
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $37
    ld c, a
    ld a, $53
    ld b, d
    ld c, c
    ld b, d
    ld c, a
    ld d, b
    ld e, h
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld d, b
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld b, b
    ld a, $52
    ld d, b
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, d
    ld c, a
    ld b, d
    rst $28
    xor $45
    ld a, $4f
    ld c, d
    ld b, e
    ld d, d
    ld c, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, l
    ld d, d
    ld c, d
    ld a, $4b
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl-], a
    ld d, d
    ld c, a
    ld h, d
    ld a, $4b
    ld b, b
    ld b, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld d, b
    rst $28
    xor $41
    ld b, d
    ld c, d
    ld a, $4b
    ld b, c
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld b, l
    ld c, h
    ld c, c
    ld b, c
    ld h, d
    ld a, $ef
    xor $51
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld a, [$eff7]
    xor $36
    ld d, c
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr nc, @+$40

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    or $ef
    xor $54
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $51
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $40
    ld a, $50
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld e, a
    rst $28
    xor $2a
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld c, c
    ld d, d
    ld b, b
    ld c, b
    ld h, d
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $51
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl+]
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld c, c
    ld d, d
    ld b, b
    ld c, b
    ld h, d
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $36
    ld d, c
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    ld a, [$eff7]
    xor $37
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld h, e
    rst $28
    xor $3a
    ld b, d
    ld l, c
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $46
    ld d, c
    ld h, h
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ccf
    ld b, d
    ld a, [$eff7]
    xor $3e
    ccf
    ld c, c
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $50
    ld c, h
    ld c, d
    ld b, d
    ld d, h
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $44
    ld c, a
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld h, d
    ld d, c
    ld b, l
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $54
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ccf
    ld d, d
    ld d, b
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec h
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    jr nc, jr_048_5326

    ld b, c
    ld a, $49
    ld h, d
    jr nc, jr_048_5328

    ld c, e
    ld a, [$eff7]
    xor $52
    ld c, l
    ld d, b
    ld d, c
    ld a, $46
    ld c, a
    ld d, b
    ld e, a
    ld h, d
    dec hl
    ld b, d
    ld h, [hl]
    ld c, c
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld c, a
    ld b, [hl]
    ld c, c
    ld c, c
    ld b, d
    ld b, c
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld c, d
    ld a, $4b
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld c, a
    ld b, d
    ld a, $49

jr_048_5326:
    ld c, c
    ld d, [hl]

jr_048_5328:
    ld a, [$eff7]
    xor $4f
    ld b, d
    ld d, b
    ld d, c
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld b, c
    ld a, $56
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    jr nc, jr_048_5382

    ld c, e
    ld d, [hl]
    ld h, d
    ld c, l
    ld b, d
    ld c, h
    ld c, l
    ld c, c
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $45
    ld b, d
    ld a, $41
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld c, e
    ld a, $62
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28

jr_048_5382:
    xor $3f
    ld b, d
    ld h, d
    ld c, l
    ld a, $40
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $51
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, c
    ld d, b
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ld b, l
    ld a, $4d
    ld c, l
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld c, e
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld d, c
    ld h, d
    ld d, b
    ld a, $56
    ld d, b
    ld h, d
    ld d, b
    ld c, h
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ccf
    ld c, a
    ld a, $4f
    ld d, [hl]
    ld e, a
    ld h, d
    inc l
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    rst $28
    xor $54
    ld b, l
    ld a, $51
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld a, $4b
    ld d, b
    ld h, h
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld h, e
    rst $28
    xor $5f
    ld e, a
    ld e, a
    inc l
    ld h, d
    ld b, e
    ld b, d
    ld b, d
    ld c, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    ld h, d
    ld a, $62
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, l
    rst $28
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld d, d
    ld b, d
    ld a, [$eff7]
    xor $46
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec h
    ld d, d
    ld d, c
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ld d, b
    ld a, $51
    ld b, [hl]
    ld d, b
    ld b, e
    ld b, [hl]
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld d, e
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc sp
    ld c, a
    ld c, h
    ld b, b
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $39
    ld a, $52
    ld c, c
    ld d, c
    ld e, a
    ld h, d
    ld a, [hl+]
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld c, c
    ld d, d
    ld b, b
    ld c, b
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl+]
    ld c, h
    ld h, d
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $25
    ld a, $57
    ld a, $3e
    ld c, a
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    or $63
    rst $28
    xor $2c
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $43
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl+]
    ld c, h
    ld h, d
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $25
    ld a, $57
    ld a, $3e
    ld c, a
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    or $63
    rst $28
    xor $2c
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $43
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc h
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $4f
    ld b, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, l
    ld b, d
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    ld e, a
    ld e, a
    ld e, a
    daa
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld e, a
    ld e, a
    ld e, a
    daa
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    ld e, a
    rst $28
    xor $27
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld d, b
    ld a, $56
    ld a, [$eff7]
    xor $46
    ld d, c
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld h, d
    or [hl]
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, e
    rst $28
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    ld b, [hl]
    ld c, d
    ld c, l
    ld c, h
    ld d, b
    ld d, b
    ld b, [hl]
    ccf
    ld c, c
    ld b, d
    ld a, [$eff7]
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $40
    ld c, h
    ld c, d
    ld c, l
    ld b, d
    ld d, c
    ld b, d
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld e, a
    ld e, a
    ld e, a
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    ld h, d
    daa
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld c, a
    ld b, d
    ld b, h
    ld c, a
    ld b, d
    ld d, c
    ld a, [$eff7]
    xor $50
    ld a, $56
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, h
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    jr nc, jr_048_569f

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $30
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    scf
    ld a, $4a
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $41
    ld c, h
    ld d, h
    ld c, e
    ld d, b
    ld d, c
    ld a, $46
    ld c, a
    ld d, b
    ld h, d
    ld d, b
    ld a, $46
    ld b, c
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
    ld b, d
    ld h, d
    ld c, b

jr_048_569f:
    ld c, e
    ld c, h
    ld d, h
    ld d, b
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, c
    ld c, h
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc h
    ld h, d
    ld d, b
    ld d, d
    ld c, a
    ld c, l
    ld c, a
    ld b, [hl]
    ld d, b
    ld b, d
    rst $28
    xor $3e
    ld d, h
    ld a, $46
    ld d, c
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $46
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld b, e
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
    ld c, d
    ld c, d
    ld e, a
    ld e, a
    ld e, a
    ld h, e
    ld h, d
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    rst $28
    xor $50
    ld a, $56
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $36
    ld b, d
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $4c
    ld d, h
    ld c, e
    ld h, d
    ld b, d
    ld d, [hl]
    ld b, d
    ld d, b
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    rst $28
    xor $49
    ld d, d
    ld b, b
    ld c, b
    ld h, e
    ld h, d
    inc h
    ld c, c
    ld c, c
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld d, b
    ld a, [$eff7]
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl+]
    ld c, h
    ld h, d
    ld c, c
    ld b, d
    ld b, e
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $35
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    dec l
    ld c, h
    ld d, [hl]
    ld h, d
    or [hl]
    ld a, [$eff7]
    xor $3a
    ld b, [hl]
    ld d, b
    ld b, c
    ld c, h
    ld c, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld h, $42
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $35
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld [hl], $51
    ld c, a
    ld b, d
    ld c, e
    ld b, h
    ld d, c
    ld b, l
    ld a, [$eff7]
    xor $b6
    ld h, d
    inc h
    ld c, e
    ld b, h
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec [hl]
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $35
    ld c, h
    ld c, h
    ld c, d
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    inc sp
    ld b, d
    ld a, $40
    ld b, d
    ld h, d
    or [hl]
    ld a, [$eff7]
    xor $25
    ld c, a
    ld a, $53
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc h
    ld c, c
    ld c, c
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $4b
    ld c, h
    ld d, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    dec [hl]
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    dec l
    ld c, h
    ld d, [hl]
    rst $28
    xor $b6
    ld h, d
    ld a, [hl-]
    ld b, [hl]
    ld d, b
    ld b, c
    ld c, h
    ld c, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $49
    ld b, d
    ld b, e
    ld d, c
    ld e, a
    ld h, d
    scf
    ld b, l
    ld b, d
    ld h, d
    dec [hl]
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $36
    ld d, c
    ld c, a
    ld b, d
    ld c, e
    ld b, h
    ld d, c
    ld b, l
    ld h, d
    or [hl]
    ld h, d
    inc h
    ld c, e
    ld b, h
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $51
    ld c, h
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
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, $4b
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    dec [hl]
    ld c, h
    ld c, h
    ld c, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
    inc sp
    ld b, d
    ld a, $40
    ld b, d
    ld h, d
    or [hl]
    ld h, d
    dec h
    ld c, a
    ld a, $53
    ld b, d
    ld c, a
    ld d, [hl]
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $43
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $35
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    ld sp, $624c
    ld c, d
    ld a, $51
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    or $62
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    or $62
    ld b, [hl]
    ld d, b
    rst $28
    xor $f6
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, d
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld c, e
    ld b, c
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    ld e, [hl]
    ld a, [$eff7]
    xor $51
    ld c, h
    ld b, h
    ld b, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    sbc h
    ld h, d
    ld b, a
    ld d, d
    ld d, b
    ld d, c
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld d, h
    ld c, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, d
    ld d, b
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, d
    ld c, c
    ld c, c
    ld c, h
    ld e, a
    ld h, d
    daa
    ld c, h
    ld d, h
    ld c, e
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $3f
    ld c, c
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $25
    ld c, c
    ld b, d
    ld a, $51
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr z, jr_048_5a04

    ld b, d
    ld c, a
    ld d, [hl]
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $42
    ld d, l
    ld b, b
    ld b, [hl]
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld a, $52
    ld d, b
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld d, b
    ld c, h
    ld c, h
    ld c, e
    ld e, a
    ld h, d
    dec h
    ld c, c
    ld b, d
    ld a, $51
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446

jr_048_5a04:
    ld b, l
    ld d, c
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld d, b
    ld c, h
    ld c, h
    ld c, e
    ld e, a
    ld h, d
    inc a
    ld b, d
    ld a, $45
    ld h, e
    ld a, [$eff7]
    xor $2b
    ld a, $62
    ld b, l
    ld a, $62
    ld b, l
    ld a, $63
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld l, b
    rst $28
    xor $50
    ld c, h
    ld c, d
    ld b, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld a, [$eff7]
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld b, l
    ld a, $53
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $ef
    xor $44
    ld c, h
    ld c, h
    ld b, c
    ld h, d
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
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc h
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    rst $28
    xor $31
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld c, e
    ld b, d
    ld a, $4f
    ld d, b
    ld e, [hl]
    ld h, d
    inc l
    ld a, [$eff7]
    xor $54
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $28
    xor $2e
    ld d, h
    ld a, $62
    ld l, $54
    ld a, $63
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc h
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    rst $28
    xor $31
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld c, e
    ld b, d
    ld a, $4f
    ld d, b
    ld e, [hl]
    ld h, d
    ld b, [hl]
    ld d, c
    ld a, [$eff7]
    xor $4a
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, e
    ld h, d
    ld c, d
    ld b, d
    rst $28
    xor $54
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, l
    ld c, h
    ld d, h
    ld c, c
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld d, h
    ld c, h
    ld c, h
    ld c, h
    ld c, h
    ld c, h
    ld c, h
    ld c, e
    ld b, d
    ld h, e
    rst $28
    xor $25
    ld d, h
    ld c, h
    ld c, h
    ld c, h
    ld c, e
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $25
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    dec h
    ld c, h
    ld c, e
    ld b, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc sp
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, e
    ld c, c
    ld c, h
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $3e
    ld c, c
    ld c, c
    ld h, d
    ld a, $4f
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld c, d
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld a, $51
    ld b, b
    ld b, l
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld b, c
    ld a, $4b
    ld b, b
    ld b, d
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld a, [$eff7]
    xor $31
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    rst $28
    xor $31
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld c, e
    ld b, d
    ld a, $4f
    ld d, b
    ld e, [hl]
    ld h, d
    ld c, d
    ld d, [hl]
    ld a, [$eff7]
    xor $50
    ld c, b
    ld b, [hl]
    ld c, e
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld d, b
    rst $28
    xor $51
    ld a, $52
    ld d, c
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec a
    ld d, a
    ld d, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $5f
    ld e, a
    ld d, a
    ld d, a
    ld d, a
    ld e, a
    ld h, d
    dec h
    ld d, d
    ld d, b
    ld d, c
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    jr nc, jr_048_5c0d

    ld h, h
    rst $28
    xor $2c
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld a, $49
    ld c, a
    ld b, d
    ld a, $41
    ld d, [hl]
    ld a, [$eff7]
    xor $36
    ld d, c
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    ld h, h
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld b, e
    ld b, d
    ld b, d
    ld c, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, e
    rst $28
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $50
    ld b, l
    ld a, $48
    ld b, [hl]
    ld c, e

jr_048_5c0d:
    ld b, h
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld d, c
    ld h, d
    ld d, b
    ld b, l
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $47
    ld c, h
    ld d, [hl]
    ld h, e
    ld h, d
    scf
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld a, [$eff7]
    xor $31
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, e
    ld b, d
    ld a, $4f
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld b, e
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    rst $28
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $51
    ld c, a
    ld b, [hl]
    ld d, d
    ld c, d
    ld c, l
    ld b, l
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    cpl
    ld c, h
    ld b, h
    ld h, e
    rst $28
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    cpl
    ld c, h
    ld b, h
    ld e, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $40
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld a, $56
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ccf
    ld b, d
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, e
    ld b, d
    rst $28
    xor $27
    ld b, d
    ld a, $41
    scf
    ld c, a
    ld b, d
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld h, d
    ld d, e
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld e, [hl]
    rst $28
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld h, d
    ld b, l
    ld a, $4d
    ld c, l
    ld d, [hl]
    ld e, a
    ld a, [$eff7]
    xor $28
    ld b, d
    ld c, b
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld c, d
    ld a, $41
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, e
    rst $28
    xor $2a
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld b, a
    ld c, h
    ccf
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    add hl, hl
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $45
    ld b, d
    ld a, $4f
    ld d, c
    ld l, b
    ld h, d
    ld b, b
    ld c, h
    ld c, e
    ld d, c
    ld b, d
    ld c, e
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $24
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    ld d, [hl]
    ld h, h
    rst $28
    xor $ff
    ldh a, [$ea]
    sbc a
    and e
    cpl
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    ld d, [hl]
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc h
    ld c, e
    ld c, e
    ld c, h
    ld d, d
    ld c, e
    ld b, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4f
    ld b, d
    ld c, l
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld e, [hl]
    ld a, [$eff7]
    xor $f6
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    rst $28
    xor $31
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    scf
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld a, [$eff7]
    xor $46
    ld d, b
    ld h, d
    ld b, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld a, $4a
    ld c, h
    ld c, e
    ld b, h
    rst $28
    xor $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld a, $4f
    ld d, c
    ld b, [hl]
    ld b, b
    ld b, [hl]
    ld c, l
    ld a, $4b
    ld d, c
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld a, [$eff7]
    xor $25
    ld b, [hl]
    ld b, h
    scf
    ld c, a
    ld d, d
    ld c, e
    ld c, b
    ld e, [hl]
    rst $28
    xor $27
    ld b, d
    ld a, $41
    scf
    ld c, a
    ld b, d
    ld b, d
    ld e, [hl]
    ld a, [$eff7]
    xor $9f
    and e
    ld a, $4b
    ld b, c
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    cpl
    ld c, h
    ld b, h
    ld e, a
    rst $28
    xor $fa
    rst $30
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
    ld d, b
    ld d, d
    ld c, a
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld d, b
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld c, a
    ld b, d
    ld b, d
    ld a, [$eff7]
    xor $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld d, b
    ld e, [hl]
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, e
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld b, d
    ld d, b
    ld b, b
    ld c, a
    ld b, [hl]
    ld c, l
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    jr z, jr_048_5f10

    ld b, d
    ld c, a
    ld d, [hl]
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ccf
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    or $63
    rst $28
    xor $2a
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld c, c
    ld d, d
    ld b, b
    ld c, b
    ld h, e
    ld h, d
    sbc a
    ld c, b
    ld b, [hl]
    ld d, b
    ld d, b
    sbc a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld c, d
    ld a, $41
    ld b, d

jr_048_5f10:
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, e
    rst $28
    xor $40
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld b, b
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    ld e, [hl]
    ld h, d
    or $5f
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl+]
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld c, c
    ld d, d
    ld b, b
    ld c, b
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, e
    ld h, d
    inc l
    ld d, c
    ld d, b
    ld h, d
    ld a, $ef
    xor $2b
    ld c, h
    ld c, a
    ld c, e
    dec h
    ld b, d
    ld b, d
    ld d, c
    ld h, e
    ld h, d
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $4a
    ld a, $44
    ld c, e
    ld b, [hl]
    ld b, e
    ld b, [hl]
    ld b, b
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld b, l
    ld c, h
    ld c, a
    ld c, e
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld b, d
    ld h, e
    rst $28
    xor $2c
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld c, a
    ld b, d
    ld d, h
    ld a, $4f
    ld b, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld d, [hl]
    ld d, e
    ld b, d
    ld c, a
    ld c, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld h, $4c
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld h, e
    ld h, d
    inc sp
    ld c, a
    ld a, $56
    ld h, e
    rst $28
    xor $33
    ld c, a
    ld a, $56
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $50
    ld d, c
    ld a, $51
    ld d, d
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc sp
    ld c, a
    ld a, $56
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld d, c
    ld a, $51
    ld d, d
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, d
    ld a, $4b
    ld b, c
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld h, e
    rst $30
    ldh a, [$f6]
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $3f
    ld c, c
    ld a, $40
    ld c, b
    ccf
    ld c, h
    ld a, $4f
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $a3
    scf
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, b
    ld b, [hl]
    ld c, l
    ld a, $49
    rst $28
    xor $45
    ld b, [hl]
    ld b, c
    ld b, d
    ld d, b
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ccf
    ld a, $49
    ld b, c
    ld a, [$eff7]
    xor $45
    ld b, d
    ld a, $41
    ld h, d
    ld d, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    rst $28
    xor $45
    ld a, $51
    ld e, a
    ld a, [$eff7]
    xor $a3
    dec h
    ld a, $49
    ld b, c
    ld d, [hl]
    ld h, d
    ccf
    ld a, $49
    ld b, c
    ld d, [hl]
    rst $28
    xor $3f
    ld a, $49
    ld b, c
    ld d, [hl]
    ld h, d
    ccf
    ld a, $49
    ld b, c
    ld d, [hl]
    ld e, a
    ld e, a
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $30
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld sp, $5152
    ld e, a
    ld a, [$eff7]
    xor $38
    ld d, b
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, d
    ld c, c
    ld d, [hl]
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    jr nc, jr_048_6127

    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $4d
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld b, h
    ld b, [hl]
    ld c, e
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld b, d
    ld c, a
    ld c, a
    ld b, [hl]
    ccf
    ld c, c
    ld b, d
    rst $28
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l

jr_048_6127:
    ld b, d
    ld a, [$eff7]
    xor $4f
    ld d, d
    ld c, d
    ld c, h
    ld c, a
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    dec l
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld c, a
    ld d, d
    ld c, e
    ld h, d
    ccf
    ld b, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld b, d
    ld a, $51
    ld b, d
    ld c, e
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
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
    ld [hl], $45
    ld c, h
    ld d, [hl]
    ld d, d
    ld h, e
    rst $28
    xor $25
    ld b, d
    ccf
    ld b, d
    ld h, e
    ld h, d
    dec [hl]
    ld b, d
    ld c, l
    ld b, d
    ld a, $51
    ld h, d
    ld a, $43
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $4a
    ld b, d
    ld e, a
    ld h, d
    ld h, $6a
    ld c, h
    ld c, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld b, b
    ld c, b
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld [hl], $45
    ld c, h
    ld d, [hl]
    ld d, d
    ld h, e
    ld a, [$eff7]
    xor $26
    ld a, $4b
    ld h, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, a
    ld d, d
    ld d, b
    ld d, c
    rst $28
    xor $50
    ld a, $56
    ld h, d
    ld d, b
    ld c, h
    ld d, [hl]
    ld h, d
    ld d, b
    ld a, $52
    ld b, b
    ld b, d
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld [hl], $4d
    ld c, c
    ld a, $50
    ld b, l
    ld h, d
    ld [hl], $4d
    ld c, c
    ld a, $50
    ld b, l
    ld h, e
    rst $28
    xor $3a
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld a, [$eff7]
    xor $31
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld c, e
    ld b, d
    ld a, $4f
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, l
    ld b, d
    ld c, c
    ld c, l
    rst $28
    xor $3f
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $62
    ld d, b
    ld c, l
    ld c, c
    ld a, $50
    ld b, l
    ld h, e
    ld a, [$eff7]
    xor $64
    ld h, h
    ld d, b
    ld c, l
    ld c, c
    ld a, $50
    ld b, l
    ld h, h
    ld h, h
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld d, h
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $44
    ld c, h
    ld h, d
    ld b, c
    ld b, d
    ld b, d
    ld c, l
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $40
    ld b, l
    ld a, $4a
    ccf
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $36
    ld b, l
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ccf
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    jr nc, jr_048_62db

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $30
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    scf
    ld a, $4a
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $54
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld c, e
    ld h, a
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    rst $28
    xor $46
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ccf
    ld b, d
    rst $28

jr_048_62db:
    xor $45
    ld b, [hl]
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    rst $30
    ldh a, [$f6]
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld a, $51
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld b, l
    ld b, d
    ld c, c
    ld b, e
    ld e, a
    ld a, [$eff7]
    xor $a3
    ld [hl], $3e
    ld d, [hl]
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $41
    ld a, $56
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $a3
    dec h
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld a, $4a
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
    ld a, [$eff7]
    xor $40
    ld a, $4b
    ld h, d
    ld b, b
    ld c, a
    ld b, d
    ld a, $51
    ld b, d
    ld h, d
    ld a, $ef
    xor $41
    ld b, [hl]
    ld b, e
    ld b, e
    ld b, d
    ld c, a
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    ld a, [$eff7]
    xor $3a
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    ld h, d
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld h, h
    rst $28
    xor $ff
    ldh a, [$a3]
    or $62
    ld a, $49
    ld c, a
    ld b, d
    ld a, $41
    ld d, [hl]
    rst $28
    xor $40
    ld c, h
    ld c, e
    ld c, [hl]
    ld d, d
    ld b, d
    ld c, a
    ld b, d
    ld b, c
    ld h, d
    daa
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $a3
    dec hl
    ld b, d
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, [hl]
    ld d, b
    ld b, l
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    ld l, b
    ld h, d
    ld c, [hl]
    ld d, d
    ld b, d
    ld d, b
    ld d, c
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld a, $4b
    ld d, [hl]
    rst $28
    xor $41
    ld b, [hl]
    ld b, e
    ld b, e
    ld b, [hl]
    ld b, b
    ld d, d
    ld c, c
    ld d, c
    ld d, [hl]
    ld e, a
    ld a, [$eff7]
    xor $a3
    dec hl
    ld b, d
    ld h, d
    ld c, d
    ld a, $41
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld d, b
    rst $28
    xor $4c
    ld b, e
    ld h, d
    dec h
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    dec [hl]
    ld b, d
    ld d, l
    ld a, [$eff7]
    xor $53
    ld a, $4b
    ld b, [hl]
    ld d, b
    ld b, l
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    rst $28
    xor $3e
    ld d, c
    ld d, c
    ld a, $40
    ld c, b
    ld h, e
    ld a, [$eff7]
    xor $a3
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld e, [hl]
    rst $28
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3a
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    ld h, d
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld h, h
    rst $28
    xor $ff
    ldh a, [$a3]
    inc h
    ld d, c
    ld h, d
    ld c, c
    ld a, $50
    ld d, c
    ld h, d
    or $ef
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld c, l
    ld a, $4f
    ld d, c
    ld b, [hl]
    ld b, b
    ld b, [hl]
    ld c, l
    ld a, $51
    ld b, d
    ld a, [$eff7]
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld a, [$eff7]
    xor $46
    ld c, e
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, e
    ld b, h
    ld b, d
    ld c, a
    rst $28
    xor $41
    ld a, $56
    ld d, b
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ccf
    ld b, [hl]
    ld c, e
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld a, $4a
    ld b, d
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld b, b
    ld c, a
    ld b, d
    ld a, $51
    ld b, d
    ld d, b
    ld h, d
    ld a, $ef
    xor $41
    ld b, [hl]
    ld b, e
    ld b, e
    ld b, d
    ld c, a
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    daa
    ld b, [hl]
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld b, d
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, e
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld b, l
    ld a, $4d
    ld c, l
    ld b, d
    ld c, e
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld d, c
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld c, d
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $4a
    ld a, $48
    ld b, d
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, e
    ld b, e
    ld b, d
    ld c, a
    ld b, d
    ld c, e
    ld d, c
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, e
    ld h, d
    ccf
    ld d, [hl]
    rst $28
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $50
    ld a, $4a
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
    rst $28
    xor $43
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld a, $4a
    ld b, d
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    jr nc, jr_048_6616

    ld c, e
    ld d, [hl]
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld d, b
    ld h, d
    ld b, e
    ld a, $49
    ld c, c
    rst $28
    xor $43
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, b
    ld d, [hl]
    ld h, d
    ld c, h
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld h, d
    ld d, h

jr_048_6616:
    ld c, h
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, b
    ld h, d
    ld b, h
    ld c, h
    ld h, h
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    daa
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $41
    ld a, $52
    ld b, h
    ld b, l
    ld d, c
    ld b, d
    ld c, a
    ld h, h
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    ld sp, $634c
    ld h, h
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $48
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld d, b
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld a, $62
    ld b, b
    ld d, d
    ld d, c
    ld b, d
    ld a, [$eff7]
    xor $48
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld b, h
    ld c, a
    ld a, $40
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    rst $28
    xor $44
    ld b, [hl]
    ld c, a
    ld c, c
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl], $45
    ld b, d
    ld l, b
    ld h, d
    ld c, l
    ld c, c
    ld a, $56
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $4c
    ld d, d
    ld d, c
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld e, a
    ld h, d
    ld a, [hl+]
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld a, [$eff7]
    xor $45
    ld b, d
    ld c, a
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, h
    ld d, h
    ld c, e
    rst $28
    xor $42
    ld d, [hl]
    ld b, d
    ld d, b
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld [hl], $45
    ld b, d
    ld l, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld c, h
    ld d, b
    ld d, c
    rst $28
    xor $44
    ld c, a
    ld a, $40
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    ld h, d
    ld b, h
    ld b, [hl]
    ld c, a
    ld c, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld e, a
    rst $28
    xor $2c
    ld d, b
    ld c, e
    ld h, a
    ld h, d
    ld d, b
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld d, d
    ld d, c
    ld b, d
    ld h, h
    rst $38
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    rst $28
    xor $4d
    ld c, a
    ld c, h
    ld c, d
    ld b, [hl]
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    ld a, [$eff7]
    xor $2f
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $50
    ld c, h
    ld c, d
    ld b, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, b
    ld b, [hl]
    ld b, c
    ld a, [$eff7]
    xor $4f
    ld b, d
    ld a, $41
    ld h, d
    ccf
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr z, jr_048_67d2

    ld b, d
    ld c, e
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
    rst $28
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld a, $62
    ld d, h
    ld a, $4f
    ld c, l
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $4d
    ld b, d
    ld c, a
    ld d, b
    ld c, h
    ld c, e
    ld a, $49
    ld b, [hl]
    ld d, c
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ccf
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    rst $28
    xor $40
    ld a, $4b
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld d, c
    ld a, $4a
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld b, h
    ld b, d
    ld c, e
    ld d, c
    ld c, c
    ld b, d
    ld e, a
    rst $28

jr_048_67d2:
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld [hl-], a
    ld b, e
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $41
    ld a, $52
    ld b, h
    ld b, l
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $62
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld a, [$eff7]
    xor $44
    ld b, [hl]
    ld c, a
    ld c, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld c, h
    ld d, d
    ld d, c
    rst $28
    xor $3f
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    jr nc, jr_048_686e

    ld h, d
    ld b, l
    ld d, d
    ccf
    ccf
    ld d, [hl]
    ld h, d
    ld a, $41
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    rst $28
    xor $4c
    ld d, d
    ld c, a
    ld h, d
    ld b, h
    ld b, [hl]
    ld c, a
    ld c, c
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec [hl]
    ld b, d
    ld a, $41
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, a
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    rst $28
    xor $46
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld e, a
    rst $30
    ldh a, [$a3]
    dec l
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    jr nc, jr_048_68bb

    rst $28
    xor $25
    ld a, $3f
    ld d, [hl]
    ld e, [hl]
    ld h, d
    inc sp

jr_048_686e:
    ld a, $4f
    ld d, c
    ld h, d
    inc bc
    ld a, [$eff7]
    xor $a3
    add hl, hl
    ld c, c
    ld a, $51
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $51
    ld c, a
    ld b, d
    ld a, $51
    ld d, b
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld a, [$eff7]
    xor $50
    ld d, c
    ld c, a
    ld b, [hl]
    ld b, b
    ld d, c
    ld h, d
    ld c, h
    ld c, a
    ld b, c
    ld b, d
    ld c, a
    ld d, b
    rst $28
    xor $50
    ld c, h
    ld c, d
    ld b, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    ld h, h
    ld a, [$eff7]
    xor $a3
    ld a, [hl-]

jr_048_68bb:
    ld b, l
    ld a, $51
    ld h, h
    ld h, d
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $4f
    ld a, $46
    ld d, b
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, h
    ld h, d
    inc l
    ld h, d
    ld d, h
    ld a, $50
    rst $28
    xor $4f
    ld b, d
    ld a, $41
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $3f
    ld c, h
    ld c, h
    ld c, b
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3a
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    ld h, d
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld h, h
    rst $28
    xor $ff
    ldh a, [$a3]
    dec l
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    jr nc, jr_048_6982

    rst $28
    xor $25
    ld a, $3f
    ld d, [hl]
    ld e, [hl]
    ld h, d
    inc sp
    ld a, $4f
    ld d, c
    ld h, d
    inc b
    ld a, [$eff7]
    xor $a3
    inc l
    ld h, d
    ld b, h
    ld d, d
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    inc l
    ld l, h
    ld b, d
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld b, h
    ld c, h
    ld d, c
    ld d, c
    ld b, d
    ld c, e
    ld h, d
    ld a, $4b
    ld a, [$eff7]
    xor $46
    ld c, d
    ld c, l
    ld c, h
    ld c, a
    ld d, c
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc l
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld b, h
    ld c, h
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, e
    ld a, $4a

jr_048_6982:
    ld b, d
    rst $28
    xor $4a
    ld d, [hl]
    ld h, d
    ccf
    ld a, $3f
    ld d, [hl]
    ld h, e
    ld a, [$eff7]
    xor $a3
    ld [hl], $45
    ld b, d
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld d, b
    ld c, h
    ld h, d
    ld b, b
    ld d, d
    ld d, c
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    inc l
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, l
    ld c, c
    ld b, d
    ld d, c
    ld b, d
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $43
    ld c, h
    ld c, a
    ld b, h
    ld c, h
    ld d, c
    ld h, d
    ld a, $3f
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    ld h, d
    ld a, $62
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, l
    rst $28
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld d, d
    ld b, d
    ld a, [$eff7]
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
    ld b, [hl]
    ld c, e
    ld h, d
    ld a, $ef
    xor $53
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $51
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    or $5e
    ld h, d
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    rst $28
    xor $54
    ld b, [hl]
    ld c, e
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld c, d
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld c, d
    ld b, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28

ClrB48_6a60:
    xor $4c
    ld d, h
    ld c, e
    ld b, d
    ld c, a
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $39
    ld a, $52
    ld c, c
    ld d, c
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ccf
    ld d, [hl]
    ld h, d
    ld b, l
    ld a, $53
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $40
    ld d, d
    ld c, a
    ld c, a
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld c, h
    ld d, h
    ld c, e
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $4f
    ld b, d
    ld d, c
    ld b, [hl]
    ld c, a
    ld b, d
    ld e, a
    ld e, a
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $51
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld a, $4b
    ld d, [hl]
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld l, d
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    rst $28
    xor $3e
    ld h, d
    ccf
    ld c, h
    ld c, h
    ld c, b
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld e, a
    rst $28
    xor $3a
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ccf
    ld b, d
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld d, c
    ld d, d
    ld b, c
    ld d, [hl]
    rst $28
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    jr nc, jr_048_6ba9

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $30
    ld b, [hl]
    ld c, e
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $24
    ld c, c
    ld c, c
    ld h, d
    ld b, l
    ld a, $46
    ld c, c
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld d, c
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    ld d, b
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld a, [$eff7]
    xor $4a

jr_048_6ba9:
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, c
    ld d, b
    ld h, d
    ld c, h
    ld b, e
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
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld e, a
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld a, $3f
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $35
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    dec l
    ld c, h
    ld d, [hl]
    ld h, d
    or [hl]
    ld a, [$eff7]
    xor $3a
    ld b, [hl]
    ld d, b
    ld b, c
    ld c, h
    ld c, d
    ld h, h
    rst $28
    xor $ff
    ldh a, [$ea]
    sbc a
    and e
    dec h
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
    dec l
    ld c, h
    ld d, [hl]
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld a, [$eff7]
    xor $36
    ld c, e
    ld a, $46
    ld c, c
    ld d, [hl]
    ld d, b
    ld e, [hl]
    ld h, d
    ld [hl], $3e
    ld b, b
    ld b, b
    ld b, d
    ld c, a
    ld d, b
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl+]
    ld d, d
    ld c, c
    ld c, l
    ld c, l
    ld c, c
    ld b, d
    ld d, b
    ld e, [hl]
    rst $28
    xor $28
    ld d, [hl]
    ld b, d
    dec h
    ld a, $49
    ld c, c
    ld d, b
    ld e, [hl]
    ld a, [$eff7]
    xor $30
    ld d, d
    ld c, d
    ld c, d
    ld d, [hl]
    ld d, b
    ld e, [hl]
    ld h, d
    dec h
    ld a, $3f
    ccf
    ld c, c
    ld b, d
    ld d, b
    ld e, a
    ld e, a
    rst $28
    xor $3e
    ld c, e
    ld b, c
    ld a, [$eff7]
    xor $9f
    and e
    jr nc, @+$40

    ld b, c
    inc sp
    ld b, d
    ld b, b
    ld c, b
    ld b, d
    ld c, a
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec h
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld a, [hl-]
    ld b, [hl]
    ld d, b
    ld b, c
    ld c, h
    ld c, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld e, [hl]
    ld a, [$eff7]
    xor $29
    ld a, $40
    ld b, d
    ld c, a
    ld d, b
    ld e, [hl]
    rst $28
    xor $37
    ld c, h
    ld c, e
    ld b, h
    ld d, d
    ld b, d
    ld c, c
    ld c, c
    ld a, $50
    ld e, [hl]
    ld a, [$eff7]
    xor $9f
    and e
    add hl, hl
    ld c, c
    ld c, h
    ld c, a
    ld a, $47
    ld a, $56
    ld d, b
    ld e, [hl]
    rst $28
    xor $24
    ld c, a
    ld c, d
    ld c, h
    ld c, a
    inc sp
    ld b, d
    ld b, c
    ld b, d
    ld d, b
    ld e, [hl]
    ld h, d
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $9f
    and e
    inc sp
    ld d, c
    ld b, d
    ld c, a
    ld a, $4b
    ld c, h
    ld b, c
    ld d, b
    ld e, [hl]
    rst $28
    xor $30
    ld a, $41
    inc sp
    ld c, c
    ld a, $4b
    ld d, c
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld a, $3f
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $35
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    dec hl
    ld a, $4d
    ld c, l
    ld b, [hl]
    ld c, e
    ld b, d
    ld d, b
    ld d, b
    ld a, [$eff7]
    xor $b6
    ld h, d
    scf
    ld b, d
    ld c, d
    ld c, l
    ld d, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, h
    rst $28
    xor $ff
    ldh a, [$ea]
    sbc a
    and e
    dec h
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
    dec hl
    ld a, $4d
    ld c, l
    ld b, [hl]
    ld c, e
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld a, [$eff7]
    xor $32
    ld c, e
    ld b, [hl]
    ld c, h
    ld c, e
    ld c, h
    ld d, b
    ld e, [hl]
    rst $28
    xor $2a
    ld a, $50
    ld b, h
    ld c, h
    ld c, e
    ld d, b
    ld e, [hl]
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl+]
    ld c, h
    ld c, l
    ld b, l
    ld b, d
    ld b, b
    ld a, $41
    ld a, $50
    ld e, [hl]
    rst $28
    xor $33
    ld b, [hl]
    ld d, l
    ld d, [hl]
    ld d, b
    ld e, [hl]
    ld h, d
    ld [hl], $51
    ld d, d
    ccf
    dec h
    ld b, [hl]
    ld c, a
    ld b, c
    ld d, b
    ld e, [hl]
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    daa
    ld b, d
    ld a, $41
    ld sp, $5146
    ld b, d
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec h
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, h
    ld a, $51
    ld b, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
    scf
    ld b, d
    ld c, d
    ld c, l
    ld d, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld a, [$eff7]
    xor $36
    ld c, l
    ld b, [hl]
    ld c, b
    ld d, [hl]
    dec h
    ld c, h
    ld d, [hl]
    ld d, b
    ld e, [hl]
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, $4c
    ccf
    ld c, a
    ld a, $50
    ld e, [hl]
    ld a, [$eff7]
    xor $30
    ld c, h
    ld c, d
    ld c, d
    ld c, h
    ld c, e
    ld b, a
    ld a, $50
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld [hl], $51
    ld a, $44
    dec h
    ld d, d
    ld b, h
    ld d, b
    ld e, [hl]
    rst $28
    xor $36
    ld c, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld sp, $5146
    ld b, d
    ld d, b
    ld e, [hl]
    ld h, d
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $30
    ld b, [hl]
    ld d, b
    ld d, c
    ld d, [hl]
    ld a, [hl-]
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld a, $3f
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $35
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $2f
    ld a, $3f
    ld d, [hl]
    ld c, a
    ld b, [hl]
    ld c, e
    ld d, c
    ld b, l
    rst $28
    xor $b6
    ld h, d
    dec l
    ld d, d
    ld b, c
    ld b, h
    ld c, d
    ld b, d
    ld c, e
    ld d, c
    ld e, a
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    dec h
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
    cpl
    ld a, $3f
    ld d, [hl]
    ld c, a
    ld b, [hl]
    ld c, e
    ld d, c
    ld b, l
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld a, [$eff7]
    xor $26
    ld b, l
    ld a, $4a
    ld b, d
    ld c, c
    ld b, h
    ld c, h
    ld c, e
    ld d, b
    ld e, [hl]
    rst $28
    xor $35
    ld c, h
    ld b, b
    ld c, b
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    ld d, b
    ld e, [hl]
    ld a, [$eff7]
    xor $27
    ld d, d
    ld b, b
    ld c, b
    ld l, $46
    ld d, c
    ld b, d
    ld d, b
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld h, $3e
    ld b, b
    ld d, c
    ld b, [hl]
    dec h
    ld a, $49
    ld c, c
    ld d, b
    ld e, [hl]
    rst $28
    xor $37
    ld a, $46
    ld c, c
    jr z, @+$40

    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld e, [hl]
    ld a, [$eff7]
    xor $24
    ld b, h
    daa
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld d, b
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, $4b
    ld b, c
    ld h, d
    ld a, [hl-]
    ld b, [hl]
    ld c, e
    ld b, c
    jr nc, jr_048_6f94

    ld c, a
    ld b, h
    ld b, d
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec h
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
    dec l
    ld d, d
    ld b, c
    ld b, h
    ld c, d
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld a, [$eff7]
    xor $2b
    ld a, $4a
    ld c, d
    ld b, d
    ld c, a
    jr nc, jr_048_6fce

    ld c, e
    ld e, [hl]
    rst $28
    xor $3a
    ld b, d
    ld b, d
    ld b, c

jr_048_6f94:
    dec h
    ld d, d
    ld b, h
    ld d, b
    ld e, [hl]
    ld a, [$eff7]
    xor $30
    ld a, $41
    ld a, [hl+]
    ld b, d
    ld b, d
    ld d, b
    ld b, d
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    scf
    ld c, a
    ld b, d
    ld b, d
    dec h
    ld c, h
    ld d, [hl]
    ld d, b
    ld e, [hl]
    rst $28
    xor $36
    ld c, l
    ld c, h
    ld d, c
    ld l, $46
    ld c, e
    ld b, h
    ld d, b
    ld e, [hl]
    ld h, d
    daa
    ld c, a
    ld c, h
    ld c, c
    ld c, c
    ld d, b
    ld e, [hl]
    ld a, [$eff7]

jr_048_6fce:
    xor $2f
    ld b, [hl]
    ld d, a
    ld a, $4f
    ld b, c
    add hl, hl
    ld c, c
    ld d, [hl]
    ld d, b
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, $4b
    ld b, c
    ld h, d
    ld a, [hl+]
    ld b, [hl]
    ld a, $4b
    ld d, c
    jr nc, jr_048_7039

    ld d, c
    ld b, l
    ld d, b
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld a, $3f
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    dec [hl]
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e

jr_048_7039:
    ld a, [$eff7]
    xor $35
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, a
    rst $28
    xor $ff
    ldh a, [$ea]
    sbc a
    and e
    dec h
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
    dec [hl]
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld a, [$eff7]
    xor $28
    ld d, e
    ld b, [hl]
    ld c, c
    dec h
    ld b, d
    ld a, $50
    ld d, c
    ld d, b
    ld e, [hl]
    rst $28
    xor $36
    ld b, l
    ld a, $41
    ld c, h
    ld d, h
    ld d, b
    ld e, [hl]
    ld a, [$eff7]
    xor $9f
    and e
    jr z, jr_048_70e6

    ld b, [hl]
    ld c, c
    ld a, [hl-]
    ld a, $4b
    ld b, c
    ld d, b
    ld e, [hl]
    rst $28
    xor $2f
    ld b, [hl]
    ld d, a
    ld a, $4f
    ld b, c
    jr nc, jr_048_70e7

    ld c, e
    ld e, [hl]
    ld a, [$eff7]
    xor $36
    ld c, c
    ld b, [hl]
    ld c, d
    ld b, d
    dec h
    ld c, h
    ld c, a
    ld b, h
    ld d, b
    ld e, [hl]
    rst $28
    xor $29
    ld b, [hl]
    ld c, a
    ld b, d
    ld a, [hl-]
    ld b, d
    ld b, d
    ld b, c
    ld d, b
    ld e, [hl]
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld d, [hl]
    ld d, e
    ld b, d
    ld c, a
    ld c, e
    ld d, b
    ld e, [hl]
    rst $28
    xor $30
    ld a, $41
    dec hl
    ld c, h
    ld c, a
    ld c, e
    ld b, d
    ld d, c
    ld d, b
    ld e, [hl]
    ld a, [$eff7]
    xor $2f
    ld b, [hl]
    ld c, h
    ld c, e
    ld b, d

jr_048_70e6:
    ld d, l

jr_048_70e7:
    ld d, b
    ld e, [hl]
    rst $28
    xor $35
    ld c, h
    ld d, c
    dec [hl]
    ld a, $53
    ld b, d
    ld c, e
    ld d, b
    ld e, [hl]
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl+]
    ld c, a
    ld b, [hl]
    ld d, a
    ld d, a
    ld c, c
    ld d, [hl]
    ld d, b
    ld e, [hl]
    rst $28
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    dec l
    ld b, d
    ld d, h
    ld b, d
    ld c, c
    dec h
    ld a, $44
    ld d, b
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, c
    ld c, h
    rst $28
    xor $3e
    ld c, e
    ld d, [hl]
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld a, $62
    ld b, l
    ld a, $62
    ld b, l
    ld a, $63
    ld h, d
    inc l
    ld h, d
    ld c, d
    ld a, $41
    ld b, d
    rst $28
    xor $2a
    ld b, [hl]
    ld b, h
    ld a, $4b
    ld d, c
    ld b, d
    ld d, b
    ld h, d
    ccf
    ld c, a
    ld a, $53
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld b, e
    ld d, d
    ld c, e
    ld h, e
    rst $28
    xor $2c
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, b
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld b, [hl]
    ld c, a
    ld a, [$eff7]
    xor $4d
    ld b, d
    ld c, a
    ld d, b
    ld c, h
    ld c, e
    ld a, $49
    ld b, [hl]
    ld d, c
    ld b, [hl]
    ld b, d
    ld d, b
    rst $28
    xor $50
    ld c, h
    ld h, d
    ld b, d
    ld a, $50
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, e
    rst $28
    xor $37
    ld b, l
    ld b, d
    ld c, e
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
    ld c, d
    ld h, h
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    rst $28
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $3f
    ld b, d
    ld b, b
    ld a, $52
    ld d, b
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    add hl, hl
    ld c, c
    ld a, $4f
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $2c
    ld h, d
    ld a, $4a
    ld h, d
    jr nc, @+$40

    ld b, c
    ld h, $3e
    ld c, e
    ld b, c
    ld c, c
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    jr nc, jr_048_72a5

    ld h, d
    ld b, e
    ld c, c
    ld a, $4a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $4a
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, c
    ld b, d
    ld c, e
    ld d, b
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld a, $4b
    ld h, d
    ld d, d
    ld d, b
    ld d, d
    ld a, $49
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $46
    ld d, b
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld a, $52
    ld d, b
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $36
    ld d, c
    ld a, $4f

jr_048_72a5:
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $4b
    ld b, d
    ld a, $4f
    ld e, a
    ld e, a
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld c, d
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, e
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld c, a
    ld b, d
    ld c, [hl]
    ld d, d
    ld b, d
    ld d, b
    ld d, c
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, d
    ld b, d
    rst $28
    xor $24
    ld h, d
    dec [hl]
    ld b, d
    ld a, $4d
    ld b, d
    ld c, a
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc h
    ld h, d
    dec [hl]
    ld b, d
    ld a, $4d
    ld b, d
    ld c, a
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld a, $ef
    xor $3f
    ld b, [hl]
    ld b, h
    ld h, d
    ld d, b
    ld b, b
    ld d, [hl]
    ld d, c
    ld b, l
    ld b, d
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld e, [hl]
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $3e
    ld h, d
    dec [hl]
    ld b, d
    ld a, $4d
    ld b, d
    ld c, a
    ld h, e
    ld h, d
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $50
    ld b, l
    ld a, $4f
    ld c, l
    ld h, d
    ld d, b
    ld b, b
    ld d, [hl]
    ld d, c
    ld b, l
    ld b, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld b, d
    ld e, a
    rst $28
    xor $2c
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $4f
    ld b, d
    ld d, h
    ld a, $4f
    ld b, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    or $5e
    ld h, d
    ld c, c
    ld b, d
    ld c, d
    ld c, d
    ld b, d
    rst $28
    xor $51
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    ld h, d
    ld a, $ef
    xor $51
    ld b, d
    ld c, a
    ld c, a
    ld b, [hl]
    ccf
    ld c, c
    ld b, d
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $4d
    ld a, $4f
    ld d, c
    ld b, [hl]
    ld b, b
    ld b, [hl]
    ld c, l
    ld a, $51
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld b, d
    ld h, d
    ld b, b
    ld a, $4f
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    ld h, e
    ld h, d
    scf
    ld b, l
    ld b, d
    ld d, [hl]
    rst $28
    xor $50
    ld a, $56
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $46
    ld d, b
    ld h, d
    ccf
    ld c, a
    ld d, d
    ld d, c
    ld a, $49
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    or $63
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, a
    ld d, b
    ld d, c
    ld h, d
    ld c, l
    ld b, d
    ld c, a
    ld d, b
    ld c, h
    ld c, e
    ld a, [$eff7]
    xor $9f
    and e
    ld d, h
    ld b, l
    ld c, h
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld b, b
    ld a, $4a
    ld b, d
    rst $28
    xor $3f
    ld a, $40
    ld c, b
    ld h, d
    ld d, d
    ld c, e
    ld a, $43
    ld b, e
    ld b, d
    ld b, b
    ld d, c
    ld b, d
    ld b, c
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld a, $51
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    dec [hl]
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $35
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, a
    ld h, d
    scf
    ld b, l
    ld b, d
    rst $28
    xor $2a
    ld a, $51
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    dec [hl]
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld a, [$eff7]
    xor $46
    ld d, b
    ld h, d
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    cpl
    ld a, $41
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    or [hl]
    ld h, d
    ld a, [hl+]
    ld b, d
    ld c, e
    ld d, c
    ld d, b
    ld h, e
    rst $28
    xor $3a
    ld b, d
    ld c, c
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld c, h
    ld c, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4b
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld l, h
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld b, d
    ld c, e
    ld a, [$eff7]
    xor $54
    ld a, $46
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, e
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr nc, jr_048_7556

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    rst $28
    xor $43
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld a, $49
    ld c, c
    ld h, d
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $54
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, c
    ld b, [hl]
    ld d, b
    ld c, l
    ld c, c
    ld a, $56
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld d, c
    ld b, l
    ld b, d
    ld b, [hl]
    ld c, a
    ld h, d
    ld d, c
    ld a, $49
    ld b, d
    ld c, e
    ld d, c
    ld d, b
    rst $28

jr_048_7556:
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld d, d
    ld d, b
    ld h, e
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    rst $28
    xor $41
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    ld d, b
    ld h, d
    ld a, $49
    ld c, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $4c
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld c, h
    ld d, h
    ld c, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld a, $56
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    rst $28
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld d, h
    ld b, d
    ld a, $4f
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $40
    ld c, a
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, e
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    cpl
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ccf
    ld b, d
    ld b, h
    ld b, [hl]
    ld c, e
    ld h, e
    rst $28
    xor $f7
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
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
