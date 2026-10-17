; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $049", ROMX[$4000], BANK[$49]

    db $49 ; Bank number

    ; Cross-bank dispatch table (162 entries)
    ; Called via: ld hl, $49XX / rst $10
    dw LoadB49_4145                  ; Entry 0
    dw $4162                          ; Entry 1
    dw $417F                          ; Entry 2
    dw $4009                          ; Entry 3 — mode 0 -> table $4009 (mode list $4007)
    dw $419C                          ; Entry 4 — [table $4009]; text $0512 "Milayou:Yes, it feels like the fi…"
    dw $4260                          ; Entry 5 — text $0513 "Milayou:Yes, it was truly a fun d…"
    dw $42CB                          ; Entry 6 — text $0514 "Milayou:Good night [HERO]! Sweet …"
    dw $42F7                          ; Entry 7 — text $0515 "Milayou:Good night [HERO]! Go to …"
    dw $4322                          ; Entry 8 — text $0516 "Milayou:...Oh? ...[HERO]!"
    dw $433A                          ; Entry 9 — text $0517 "Milayou:What's in your pocket?"
    dw $435B                          ; Entry 10 — text $0518 "Watabou:Gimme that meat."
    dw $4377                          ; Entry 11 — text $0519 "Watabou:Gimme the meat and I'll b…"
    dw $43AC                          ; Entry 12 — text $051A "[HERO] checked out the bookshelf.…"
    dw $43FA                          ; Entry 13 — text $051B "[SOUND 60][HERO] looked in the dr…"
    dw $4430                          ; Entry 14 — text $051C "*:There are cliffs that we can ju…"
    dw $446E                          ; Entry 15 — text $051D "Watabou:Good job finding the invi…"
    dw $44B1                          ; Entry 16 — text $051E "*:Wow! Yummy meat! Yum!"
    dw $44CC                          ; Entry 17 — text $051F "*:Wow, yummy meat comming this wa…"
    dw $44FE                          ; Entry 18 — text $0520 "*:Wow! I'll do anything for the m…"
    dw $452B                          ; Entry 19 — text $0521 "Watabou:It seems you had a hard t…"
    dw $4572                          ; Entry 20 — text $0522 "[HERO] checked out a treasure che…"
    dw $4603                          ; Entry 21 — text $0523 "[HERO] looked into a jar. There w…"
    dw $4653                          ; Entry 22 — text $0524 "*:......"
    dw $4660                          ; Entry 23 — text $0525 "*:So,yoooou saaaw my face...!!"
    dw $4682                          ; Entry 24 — text $0526 "*:It's yoooou agaaaain!"
    dw $469C                          ; Entry 25 — text $0527 "*:Yoooou win...!!"
    dw $46B2                          ; Entry 26 — text $0528 "Watabou:Good work! So,let's goooo…"
    dw $46E4                          ; Entry 27 — text $0529 "*:Squeak squeak! Strike!"
    dw $4700                          ; Entry 28 — text $052A "*:Good lord, You're good!"
    dw $471C                          ; Entry 29 — text $052B "Watabou:Good work reading SkyDrag…"
    dw $47A5                          ; Entry 30 — text $052C "*:Look at my cool steps!"
    dw $47C1                          ; Entry 31 — text $052D "*:Why don't you dance with me?"
    dw $47E2                          ; Entry 32 — text $052E "*:You came again to dance with me…"
    dw $481D                          ; Entry 33 — text $052F "*:You're a great dancer!"
    dw $4838                          ; Entry 34 — text $0530 "*:Did you enjoy dancing? Well, le…"
    dw $486D                          ; Entry 35 — text $0531 "There is a voice coming from out …"
    dw $48A3                          ; Entry 36 — text $0532 "*:Hello...the traveler over there…"
    dw $4957                          ; Entry 37 — text $0533 "*:Now, wait there."
    dw $496C                          ; Entry 38 — text $0534 "*:Then, would you like me to send…"
    dw $49B2                          ; Entry 39 — text $0535 "*:It was actually a monster that …"
    dw $4A29                          ; Entry 40 — text $0536 "*:Was it this meat that fell in t…"
    dw $4A5D                          ; Entry 41 — text $0537 "*:...you're a liar. *:I'll give y…"
    dw $4AA7                          ; Entry 42 — text $0538 "*:I see. Now, wait a moment for m…"
    dw $4ACE                          ; Entry 43 — text $0539 "*:Now, is this the old guy who fe…"
    dw $4B08                          ; Entry 44 — text $053A "*:...you're a liar. *:I'll give y…"
    dw $4B52                          ; Entry 45 — text $053B "*:I see. Now,wait a minute for me."
    dw $4B78                          ; Entry 46 — text $053C "*:Now is this the [INS 00], the m…"
    dw $4BBA                          ; Entry 47 — text $053D "*:I don't understand you... *:I'l…"
    dw $4C3D                          ; Entry 48 — text $053E "*:You're honest. I'll give you ba…"
    dw $4CEE                          ; Entry 49 — text $053F "*:You did well. Please go back to…"
    dw $4D2B                          ; Entry 50 — text $0540 "*:Oh, it's you again. Would you l…"
    dw $4D75                          ; Entry 51 — text $0541 "*:Take your time."
    dw $4D8B                          ; Entry 52 — text $0542 "*:Now so long..."
    dw $4DA0                          ; Entry 53 — text $0543 "*:Comrade! Now is the time for us…"
    dw $4E49                          ; Entry 54 — text $0544 "*:I'll promise you, comrade! *:A …"
    dw $4EB9                          ; Entry 55 — text $0545 "*:Hm!? I don't know why but I fee…"
    dw $4F36                          ; Entry 56 — text $0546 "*:Sirloin steak is totally yummy!…"
    dw $4FC7                          ; Entry 57 — text $0547 "*:I demand one sirloin steak a da…"
    dw $4FF3                          ; Entry 58 — text $0548 "*:Hee hee hee. I love burning vil…"
    dw $5038                          ; Entry 59 — text $0549 "*:Hee hee hee. Burn'em burn'em al…"
    dw $507D                          ; Entry 60 — text $054A "*:You are so boring! *:You wanna …"
    dw $50B9                          ; Entry 61 — text $054B "*:You again! You really wanna be …"
    dw $50F1                          ; Entry 62 — text $054C "*:Burn me, boil me! Whatever! Ahr…"
    dw $511D                          ; Entry 63 — text $054D "Watabou:Ouch! I'm gonna put out t…"
    dw $518E                          ; Entry 64 — text $054E "[HERO] read the posting. :Once yo…"
    dw $520B                          ; Entry 65 — text $054F "[HERO] read the posting. :Wanted!…"
    dw $5251                          ; Entry 66 — text $0550 "*:Hi! We go sip. Sip here!"
    dw $526F                          ; Entry 67 — text $0551 "*:Boss! You can feel like a king …"
    dw $52AB                          ; Entry 68 — text $0552 "*:Please let the sweet aroma rela…"
    dw $52DB                          ; Entry 69 — text $0553 "*:You're really too much. But the…"
    dw $5313                          ; Entry 70 — text $0554 "*:Boss! You are so strong! But th…"
    dw $534D                          ; Entry 71 — text $0555 "*:I see you have lots of special …"
    dw $5397                          ; Entry 72 — text $0556 "*:Mmm... sip sip! Here I come!"
    dw $53B9                          ; Entry 73 — text $0557 "*:Wow! You really impressed me!"
    dw $53DC                          ; Entry 74 — text $0558 "Watabou:Had a good time!? We've g…"
    dw $5415                          ; Entry 75 — text $0559 "*:Now, sleep tight on my arms...!"
    dw $543A                          ; Entry 76 — text $055A "*:Oh, you were great. Giggle..."
    dw $545D                          ; Entry 77 — text $055B "Watabou:Had a good time!? We got …"
    dw $5494                          ; Entry 78 — text $055C "*:I'll let you sleep with my Slee…"
    dw $54DA                          ; Entry 79 — text $055D "*:You're strong! If this is a dre…"
    dw $5526                          ; Entry 80 — text $055E "Watabou:Had a good time!? We got …"
    dw $555D                          ; Entry 81 — text $055F "Watabou didn't reply."
    dw $5574                          ; Entry 82 — text $0560 "It was a Watabou doll!"
    dw $558D                          ; Entry 83 — text $0561 "[HERO] checked out a treasure che…"
    dw $560A                          ; Entry 84 — text $0562 "Mimic continues to stick his tong…"
    dw $563A                          ; Entry 85 — text $0563 "*:Bleat bleat. I cannot believe t…"
    dw $56CA                          ; Entry 86 — text $0564 "*:Bleat bleat. Welcome to a dead …"
    dw $56FF                          ; Entry 87 — text $0565 "*:Bleat bleat. I never imagined s…"
    dw $5744                          ; Entry 88 — text $0566 "Watabou:You think the doll looks …"
    dw $57BA                          ; Entry 89 — text $0567 "*:You abused monsters cruelly and…"
    dw $584E                          ; Entry 90 — text $0568 "*:If you cannot learn by listenin…"
    dw $58B0                          ; Entry 91 — text $0569 "*:You recognize your sin, right? …"
    dw $59C8                          ; Entry 92 — text $056A "*:If you cannot learn by listenin…"
    dw $5A2A                          ; Entry 93 — text $056B "*:Now we're holding a public exec…"
    dw $5A8B                          ; Entry 94 — text $056C "*:What? You have something to say…"
    dw $5AC5                          ; Entry 95 — text $056D "*:None of your cheek! If you don'…"
    dw $5B3C                          ; Entry 96 — text $056E "*:Then die!"
    dw $5B4C                          ; Entry 97 — text $056F "*:You want to have additional sin…"
    dw $5B73                          ; Entry 98 — text $0570 "Watabou:[HERO]'s monsters trust y…"
    dw $5BD8                          ; Entry 99 — text $0571 "[HERO] touched the blade of the g…"
    dw $5C2A                          ; Entry 100 — text $0572 "[HERO] touched the blade of the g…"
    dw $5CAA                          ; Entry 101 — text $0573 "*:Aaaarrrggh! Gwrrrr... *:Gwrrggg…"
    dw $5CD7                          ; Entry 102 — text $0574 "*:Gwwrrggg..."
    dw $5CE9                          ; Entry 103 — text $0575 "Watabou:[HERO]! Let's go."
    dw $5D00                          ; Entry 104 — text $0576 "*:Aaarrrggh... *:I can't stand it…"
    dw $5D6C                          ; Entry 105 — text $0577 "*:Look... this sword... *:It's th…"
    dw $5EE8                          ; Entry 106 — text $0578 "*:So long! The Orochi won't troub…"
    dw $5F58                          ; Entry 107 — text $0579 "*:What? You want to know why I am…"
    dw $6176                          ; Entry 108 — text $057A "Watabou:Oh, you were saved by som…"
    dw $61C9                          ; Entry 109 — text $057B "*:Welcome [HERO]! *:I'm the King …"
    dw $62FE                          ; Entry 110 — text $057C "DracoLord:Great, you agreed! Now …"
    dw $63E6                          ; Entry 111 — text $057D "DracoLord:What's wrong with it. I…"
    dw $645F                          ; Entry 112 — text $057E "DracoLord:You say you're going to…"
    dw $64C2                          ; Entry 113 — text $057F "DracoLord:You came back? You neve…"
    dw $6568                          ; Entry 114 — text $0580 "DracoLord:You beat me. You're rea…"
    dw $659F                          ; Entry 115 — text $0581 "Watabou:One down! [HERO]! Let's g…"
    dw $65CB                          ; Entry 116 — text $0582 "*:Who is it? *:Disturbing my rest…"
    dw $6649                          ; Entry 117 — text $0583 "Hargon:Then it is unforgivable! H…"
    dw $66A2                          ; Entry 118 — text $0584 "Hargon:Then you should know, Harg…"
    dw $66FB                          ; Entry 119 — text $0585 "Hargon:You again! Hargon:Insolant…"
    dw $677B                          ; Entry 120 — text $0586 "Hargon:To my vex... Hargon:the gr…"
    dw $687E                          ; Entry 121 — text $0587 "Watabou:Hm? I still smell monster…"
    dw $68E2                          ; Entry 122 — text $0588 "*:...I...am... the...god...of... …"
    dw $6961                          ; Entry 123 — text $0589 "Sidoh:...I... destroy...!!"
    dw $697F                          ; Entry 124 — text $058A "Sidoh:............"
    dw $6996                          ; Entry 125 — text $058B "Watabou:There was a monster still…"
    dw $69E2                          ; Entry 126 — text $058C "*:At last you came here, pathetic…"
    dw $6B13                          ; Entry 127 — text $058D "Baramos:Fool! You still disobey m…"
    dw $6C07                          ; Entry 128 — text $058E "Baramos:Arhg... y..you... Baramos…"
    dw $6C40                          ; Entry 129 — text $058F "Watabou: Excellent [HERO]. Leeet'…"
    dw $6C6E                          ; Entry 130 — text $0590 "*:Welcome to my altar of sacrific…"
    dw $6DC6                          ; Entry 131 — text $0591 "Zoma:Hmm, you seem to never learn…"
    dw $6E75                          ; Entry 132 — text $0592 "Zoma:...What is your name... son?…"
    dw $6F7F                          ; Entry 133 — text $0593 "Watabou:There're lots of strong m…"
    dw $6FBD                          ; Entry 134 — text $0594 "*:Gwwrrrr...! Who are you? *:I am…"
    dw $70C7                          ; Entry 135 — text $0595 "Pizzaro:Gwwrrr! Regret showing yo…"
    dw $7110                          ; Entry 136 — text $0596 "Pizzaro:Then, I will tell you! Gw…"
    dw $71AD                          ; Entry 137 — text $0597 "Pizzaro:Gwwrrr...! Pizzaro:You wa…"
    dw $71E1                          ; Entry 138 — text $0598 "Pizzaro:Then, die!"
    dw $71F7                          ; Entry 139 — text $0599 "Pizzaro:Then, what brought you he…"
    dw $723A                          ; Entry 140 — text $059A "Pizzaro:Gwwrr...! My body is burn…"
    dw $72B1                          ; Entry 141 — text $059B "Watabou:Rosalie was Pizzaro's lov…"
    dw $735E                          ; Entry 142 — text $059C "*:Ggggrrr... *:Who is disturb- in…"
    dw $7471                          ; Entry 143 — text $059D "Esterk:Then go away. Esterk:I wil…"
    dw $74B5                          ; Entry 144 — text $059E "Esterk:There is no choice. Esterk…"
    dw $750A                          ; Entry 145 — text $059F "Esterk:Gggrrr... Esterk:You again…"
    dw $7598                          ; Entry 146 — text $05A0 "Esterk:Ggggrrr... What's wrong wi…"
    dw $7640                          ; Entry 147 — text $05A1 "Watabou:Even if we're in a dream,…"
    dw $76C0                          ; Entry 148 — text $05A2 "*:At last, you came here. *:The M…"
    dw $7730                          ; Entry 149 — text $05A3 "*:Ha ha ha!! You have good intent…"
    dw $780F                          ; Entry 150 — text $05A4 "*:You don't know my name? You foo…"
    dw $78E6                          ; Entry 151 — text $05A5 "Mirudraas:Ha ha ha! Mirudraas:Mon…"
    dw $796D                          ; Entry 152 — text $05A6 "Mirudraas:How.. could I be defeat…"
    dw $7A09                          ; Entry 153 — text $05A7 "Watabou:You really became strong.…"
    dw $7A47                          ; Entry 154 — text $05A8 "*:Welcome, you worthless... *:I a…"
    dw $7A8E                          ; Entry 155 — text $05A9 "Mudou:Hm? You already know my nam…"
    dw $7AC2                          ; Entry 156 — text $05AA "Mudou:Fine. Now, Mudou:are you pr…"
    dw $7AF2                          ; Entry 157 — text $05AB "Mudou:Huh? Did you prepare your c…"
    dw $7B39                          ; Entry 158 — text $05AC "Mudou:Fine. Let's begin."
    dw $7B54                          ; Entry 159 — text $05AD "Mudou:Annoying worthless things. …"
    dw $7B91                          ; Entry 160 — text $05AE "Mudou:I was beaten by worthless..…"
    dw $7BEF                          ; Entry 161 — text $05AF "Watabou:Well, shall we go back?"

LoadB49_4145:
    ld a, [$c823]
    cp $9e
    jr c, jr_049_415b

    sub $9e
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $1802
    rst $10
    ret


jr_049_415b:
    ld de, $4007
    call CallTextEngine
    ret


    ld a, [$c823]
    cp $9e
    jr c, jr_049_4178

    sub $9e
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $1803
    rst $10
    ret


jr_049_4178:
    ld de, $4007
    call RunTextHandler
    ret


    ld a, [$c823]
    cp $9e
    jr c, jr_049_4195

    sub $9e
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $1804
    rst $10
    ret


jr_049_4195:
    call LoadB49_4145
    call RequestScreenUpdate
    ret


    db $eb
    jr nc, jr_049_41e5

    ld c, c
    ld a, $56
    ld c, h
    ld d, d

jr_049_41a4:
    and e
    inc a
    ld b, d
    ld d, b
    ld e, [hl]
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $43
    ld b, d
    ld b, d
    ld c, c
    ld d, b
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $43
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld c, a
    ld b, d
    ld a, $49
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    dec h
    ld d, d
    ld d, c
    ld e, [hl]
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28

jr_049_41e5:
    xor $40
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld b, d
    ld c, e
    ld h, d
    ld a, $62
    ld b, c
    ld c, a
    ld b, d
    ld a, $4a
    ld e, a
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld c, d
    ld d, [hl]
    ld a, [$eff7]
    xor $41
    ld c, a
    ld b, d
    ld a, $4a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    ld sp, $544c
    ld h, d
    or $5e
    rst $28
    xor $49
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $50
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld e, a
    rst $28
    xor $36
    ld d, h
    ld b, d
    ld b, d
    ld d, c
    ld h, d
    ld b, c
    ld c, a
    ld b, d
    ld a, $4a
    ld d, b
    ld h, e
    rst $30
    ldh a, [$eb]
    jr nc, jr_049_42a9

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    inc a
    ld b, d
    ld d, b
    ld e, [hl]
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $54
    ld a, $50
    ld h, d
    ld d, c
    ld c, a
    ld d, d
    ld c, c
    ld d, [hl]
    ld h, d
    ld a, $62
    ld b, e
    ld d, d
    ld c, e
    ld a, [$eff7]
    xor $41
    ld c, a
    ld b, d
    ld a, $4a
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    ld sp, $544c
    ld h, d
    or $5e
    rst $28
    xor $2f
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ld b, h
    ld c, h
    ld h, d

jr_049_42a9:
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $50
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld e, a
    rst $28
    xor $36
    ld d, h
    ld b, d
    ld b, d
    ld d, c
    ld h, d
    ld b, c
    ld c, a
    ld b, d
    ld a, $4a
    ld d, b
    ld h, e
    rst $30
    ldh a, [$eb]
    jr nc, jr_049_4314

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    ld a, [hl+]
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld c, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    rst $28
    xor $f6
    ld h, e
    ld a, [$eff7]
    xor $36
    ld d, h
    ld b, d
    ld b, d
    ld d, c
    ld h, d
    ld b, c
    ld c, a
    ld b, d
    ld a, $4a
    ld d, b
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    jr nc, jr_049_4340

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    ld a, [hl+]
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld c, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    rst $28
    xor $f6
    ld h, e
    ld h, d
    ld a, [hl+]
    ld c, h
    ld h, d
    ld d, c
    ld c, h

jr_049_4314:
    ld a, [$eff7]
    xor $50
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    jr nc, @+$48

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    ld e, a
    ld e, a
    ld e, a
    ld [hl-], a
    ld b, l
    ld h, h
    rst $28
    xor $5f
    ld e, a
    ld e, a
    or $63
    rst $30
    ldh a, [$eb]
    jr nc, jr_049_4383

    ld c, c
    ld a, $56

jr_049_4340:
    ld c, h
    ld d, d
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, l
    ld c, h
    ld b, b
    ld c, b
    ld b, d
    ld d, c
    ld h, h
    rst $30
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    ld a, [hl+]
    ld b, [hl]
    ld c, d
    ld c, d
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld c, d
    ld b, d
    ld a, $51
    ld e, a
    rst $30
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    ld a, [hl+]
    ld b, [hl]
    ld c, d

jr_049_4383:
    ld c, d
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld a, $51
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, l
    ld a, $49
    ld h, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$f6]
    ld h, d
    ld b, b
    ld b, l
    ld b, d
    ld b, b
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld c, h
    ld d, d
    ld d, c
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
    jr z, jr_049_441b

    ld b, b
    ld d, [hl]
    ld b, b
    ld c, c
    ld c, h
    ld c, l
    ld b, d
    ld b, c
    ld b, [hl]
    ld a, $62
    ld c, h
    ld b, e
    rst $28
    xor $30
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld a, [$eff7]
    xor $24
    ld d, d
    ld d, c
    ld b, l
    ld c, h
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    or $63
    rst $28
    xor $f7
    ldh a, [$e9]
    ld h, b
    or $62
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld c, a
    ld b, d
    ld d, b
    ld d, b
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $24
    ld c, e

jr_049_441b:
    ld b, c
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    ld c, e
    ld h, a
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
    rst $28
    xor $4a
    ld d, d
    ld b, b
    ld b, l
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld b, b
    ld c, c
    ld b, [hl]
    ld b, e
    ld b, e
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld d, h
    ld b, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, a
    ld d, d
    ld c, d
    ld c, l
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld b, e
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, h
    ld b, d
    ld l, c
    ld b, d
    rst $28
    xor $3f
    ld c, a
    ld a, $53
    ld b, d
    ld h, e
    rst $30
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    ld a, [hl+]
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld b, a
    ld c, h
    ccf
    rst $28
    xor $43
    ld b, [hl]
    ld c, e
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $46
    ld c, e
    ld d, e
    ld b, [hl]
    ld d, b
    ld b, [hl]
    ccf
    ld c, c
    ld b, d
    ld h, d
    ld b, e
    ld c, c
    ld c, h
    ld c, h
    ld c, a
    ld h, e
    rst $28
    xor $2f
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld c, h
    ld d, h
    ld h, e
    ld h, d
    inc a
    ld d, d
    ld c, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $4a
    ld b, d
    ld a, $51
    ld h, e
    ld h, d
    inc a
    ld d, d
    ld c, d
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld c, h
    ld d, h
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld d, d
    ld c, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $4a
    ld b, d
    ld a, $51
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $54
    ld a, $56
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld c, h
    ld d, h
    ld h, e
    ld h, d
    inc l
    ld h, [hl]
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
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld a, $51
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    inc l
    ld d, c
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld c, d
    ld d, b
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $41
    ld h, d
    ld a, $62
    ld b, l
    ld a, $4f
    ld b, c
    ld a, [$eff7]
    xor $51
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, d
    ld e, a
    rst $28
    xor $2f
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, e
    rst $30
    ldh a, [$f6]
    ld h, d
    ld b, b
    ld b, l
    ld b, d
    ld b, b
    ld c, b
    ld b, d
    ld b, c
    rst $28
    xor $4c
    ld d, d
    ld d, c
    ld h, d
    ld a, $62
    ld d, c
    ld c, a
    ld b, d
    ld a, $50
    ld d, d
    ld c, a
    ld b, d
    ld a, [$eff7]
    xor $40
    ld b, l
    ld b, d
    ld d, b
    ld d, c
    ld h, e
    rst $28
    xor $3a
    ld c, h
    ld d, h
    ld h, e
    ld h, d
    scf
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld a, $50
    ld d, d
    ld c, a
    ld b, d
    ld a, [$eff7]
    xor $40
    ld b, l
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld a, $40
    ld d, c
    ld d, d
    ld a, $49
    ld c, c
    ld d, [hl]
    rst $28
    xor $3e
    ld h, d
    jr nc, jr_049_460a

    ld c, d
    ld b, [hl]
    ld b, b
    ld h, e
    ld h, e
    ld a, [$eff7]
    xor $25
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    jr nc, jr_049_461d

    ld c, d
    ld b, [hl]
    ld b, b
    rst $28
    xor $46
    ld d, b
    ld c, e
    ld h, a
    ld h, d
    ld b, c
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld d, [hl]
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ccf
    ld d, d
    ld d, c
    rst $28
    xor $49
    ld a, $52
    ld b, h
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    rst $30
    ldh a, [$f6]
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, d

jr_049_460a:
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    rst $28
    xor $3e
    ld h, d
    ld b, a
    ld a, $4f
    ld e, a
    ld a, [$eff7]
    xor $37

jr_049_461d:
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld a, $ef
    xor $41
    ld a, $4f
    ld c, b
    ld c, e
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld a, [$eff7]
    xor $50
    ld b, d
    ld b, d
    ld c, d
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, c
    ld c, a
    ld a, $54
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld [hl], $4c
    ld e, [hl]
    ld d, [hl]
    ld c, h
    ld c, h
    ld c, h
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld a, $3e
    ld a, $54
    rst $28
    xor $4a
    ld d, [hl]
    ld h, d
    ld b, e
    ld a, $40
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld c, h
    ld c, h
    ld c, h
    ld d, d
    rst $28
    xor $3e
    ld b, h
    ld a, $3e
    ld a, $3e
    ld b, [hl]
    ld c, e
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld c, h
    ld c, h
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld e, a
    ld e, a
    ld e, a
    ld h, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    ld a, [hl+]
    ld c, h
    ld c, h
    ld b, c
    rst $28
    xor $54
    ld c, h
    ld c, a
    ld c, b
    ld h, e
    ld h, d
    ld [hl], $4c
    ld e, [hl]
    ld c, c
    ld b, d
    ld d, c
    ld l, b
    ld a, [$eff7]
    xor $44
    ld c, h
    ld c, h
    ld c, h
    ld c, h
    ld c, h
    ld h, d
    ccf
    ld a, $3e
    ld a, $40
    ld c, b
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld [hl], $4e
    ld d, d
    ld b, d
    ld a, $48
    ld h, d
    ld d, b
    ld c, [hl]
    ld d, d
    ld b, d
    ld a, $48
    ld h, e
    rst $28
    xor $36
    ld d, c
    ld c, a
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl+]
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld c, c
    ld c, h
    ld c, a
    ld b, c
    ld e, [hl]
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld h, e
    rst $30
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    ld a, [hl+]
    ld c, h
    ld c, h
    ld b, c
    rst $28
    xor $54
    ld c, h
    ld c, a
    ld c, b
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $36
    ld c, b
    ld d, [hl]
    daa
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld l, b
    ld h, d
    ld c, d
    ld c, h
    ld d, e
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    inc sp
    ld c, a
    ld b, d
    ld d, c
    ld d, c
    ld d, [hl]
    rst $28
    xor $50
    ld c, d
    ld a, $4f
    ld d, c
    ld h, d
    ld a, $4f
    ld b, d
    ld c, e
    ld h, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    ld a, [$eff7]
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    ld sp, $544c
    ld e, [hl]
    rst $28
    xor $49
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld a, $50
    ld d, c
    ld c, c
    ld b, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    cpl
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld a, $51
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $40
    ld c, h
    ld c, h
    ld c, c
    ld h, d
    ld d, b
    ld d, c
    ld b, d
    ld c, l
    ld d, b
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $41
    ld a, $4b
    ld b, b
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, d
    ld b, d
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
    ld a, $4a
    ld b, d
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld b, c
    ld a, $4b
    ld b, b
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, d
    ld b, d
    ld h, h
    ld a, [$eff7]
    xor $35
    ld b, d
    ld a, $41
    ld d, [hl]
    ld h, h
    ld h, d
    cpl
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ld b, h
    ld c, h
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
    ld a, $62
    ld b, h
    ld c, a
    ld b, d
    ld a, $51
    rst $28
    xor $41
    ld a, $4b
    ld b, b
    ld b, d
    ld c, a
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    daa
    ld b, [hl]
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, d
    ld c, e
    ld b, a
    ld c, h
    ld d, [hl]
    rst $28
    xor $41
    ld a, $4b
    ld b, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, h
    ld h, d
    ld a, [hl-]
    ld b, d
    ld c, c
    ld c, c
    ld e, [hl]
    ld a, [$eff7]
    xor $49
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, e
    rst $28
    xor $f7
    ldh a, [$37]
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $62
    ld d, e
    ld c, h
    ld b, [hl]
    ld b, b
    ld b, d
    rst $28
    xor $40
    ld c, h
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld b, d
    ld c, c
    ld c, c
    ld c, h
    ld e, a
    ld e, a
    ld e, a
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $51
    ld c, a
    ld a, $53
    ld b, d
    ld c, c
    ld b, d
    ld c, a
    ld h, d
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld c, a
    ld b, d
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
    ld l, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, l
    ld b, [hl]
    ld c, a
    ld b, [hl]
    ld d, c
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, b
    ld c, l
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, l
    ld a, $4b
    ld b, [hl]
    ld c, h
    ld c, e
    rst $28
    xor $43
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $50
    ld c, l
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    rst $28
    xor $4a
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, l
    ld b, d
    ld c, c
    ld c, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $40
    ld c, h
    ld c, d
    ld c, l
    ld a, $4b
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    ld sp, $544c
    ld e, [hl]
    ld h, d
    ld d, h
    ld a, $46
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld c, e
    ld e, [hl]
    ld h, d
    ld d, h
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld c, e
    ld b, c
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
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
    rst $28
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
    ld h, h
    rst $38
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld d, c
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld a, $40
    ld d, c
    ld d, d
    ld a, $49
    ld c, c
    ld d, [hl]
    rst $28
    xor $3e
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld a, [$eff7]
    xor $43
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld d, h
    ld a, $50
    ld c, e
    ld h, a
    ld h, d
    ld b, [hl]
    ld d, c
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
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld c, c
    ld c, l
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld sp, $544c
    ld e, [hl]
    ld h, d
    ld d, h
    ld a, $46
    ld d, c
    ld h, d
    ld a, $ef
    xor $4a
    ld c, h
    ld c, d
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld a, $50
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, d
    ld b, d
    ld a, $51
    rst $28
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld b, e
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $50
    ld c, l
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    ld e, a
    ld e, a
    ld e, a
    ld d, [hl]
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld a, $ef
    xor $49
    ld b, [hl]
    ld a, $4f
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
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
    ld c, a
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld e, a
    ld h, d
    ld sp, $544c
    ld a, [$eff7]
    xor $44
    ld c, h
    ld h, d
    ld a, $54
    ld a, $56
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld e, a
    ld h, d
    ld sp, $544c
    ld e, [hl]
    ld h, d
    ld d, h
    ld a, $46
    ld d, c
    rst $28
    xor $3e
    ld h, d
    ld c, d
    ld c, h
    ld c, d
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld sp, $544c
    ld e, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld c, c
    ld b, c
    ld h, d
    ld b, h
    ld d, d
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    ld a, [$eff7]
    xor $43
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld c, l
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, h
    rst $38
    ldh a, [$eb]
    sbc a
    and e
    ld e, a
    ld e, a
    ld e, a
    ld d, [hl]
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld a, $ef
    xor $49
    ld b, [hl]
    ld a, $4f
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
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
    ld c, a
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld e, a
    ld h, d
    ld sp, $544c
    ld a, [$eff7]
    xor $44
    ld c, h
    ld h, d
    ld a, $54
    ld a, $56
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld e, a
    ld h, d
    ld sp, $544c
    ld e, [hl]
    ld d, h
    ld a, $46
    ld d, c
    rst $28
    xor $3e
    ld h, d
    ld c, d
    ld b, [hl]
    ld c, e
    ld d, d
    ld d, c
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld sp, $544c
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $f9
    nop
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
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
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld b, e
    ld b, d
    ld c, c
    ld c, c
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, l
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, h
    rst $38
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $52
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld d, b
    ld d, c
    ld a, $4b
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
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
    rst $28
    xor $3f
    ld a, $40
    ld c, b
    ld h, d
    ld d, c
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
    ld a, [$eff7]
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld b, e
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld c, l
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl+]
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
    rst $28
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
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld b, l
    ld c, h
    ld c, e
    ld b, d
    ld d, b
    ld d, c
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
    ld a, [$eff7]
    xor $3f
    ld a, $40
    ld c, b
    ld h, d
    ld d, c
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
    rst $28
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld b, e
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $50
    ld c, l
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc h
    ld c, e
    ld b, c
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld a, $52
    ld d, b
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $54
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, l
    ld c, h
    ld c, e
    ld b, d
    ld d, b
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
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
    rst $28
    xor $3e
    ld h, d
    daa
    ld b, [hl]
    ld b, h
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $41
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    ld h, d
    ld d, h
    ld b, d
    ld c, c
    ld c, c
    ld e, a
    rst $28
    xor $33
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld b, l
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
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld e, [hl]
    ld h, d
    ld b, [hl]
    ld d, c
    ld l, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $3e
    ld b, h
    ld a, $46
    ld c, e
    ld e, a
    ld h, d
    ld a, [hl-]
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld b, l
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld h, h
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    scf
    ld a, $48
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld sp, $544c
    ld h, d
    ld d, b
    ld c, h
    ld h, d
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld h, $4c
    ld c, d
    ld c, a
    ld a, $41
    ld b, d
    ld h, e
    rst $28
    xor $31
    ld c, h
    ld d, h
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld a, [$eff7]
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld d, d
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, d
    ld c, e
    ld b, [hl]
    ld d, c
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    and h
    ld a, $4b
    ld b, c
    ld h, d
    ld c, h
    ld c, l
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $2a
    ld a, $51
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, e
    ld b, d
    ld d, h
    ld a, [$eff7]
    xor $3e
    ld b, h
    ld b, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc a
    ld b, d
    ld d, b
    ld h, e
    ld h, d
    inc h
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    rst $28
    xor $43
    ld c, h
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
    ld e, [hl]
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld e, [hl]
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ccf
    ld d, [hl]
    rst $28
    xor $4a
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
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld c, l
    ld c, a
    ld c, h
    ld c, d
    ld b, [hl]
    ld d, b
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld e, [hl]
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, a
    ld a, $41
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc h
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    rst $28
    xor $54
    ld b, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, d
    ld a, $51
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, a
    ld c, c
    ld c, h
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $50
    ld d, c
    ld b, d
    ld a, $48
    ld d, b
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld b, c
    ld a, $56
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld c, d
    ld h, e
    ld h, h
    rst $28
    xor $2c
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld d, h
    ld b, l
    ld d, [hl]
    ld a, [$eff7]
    xor $3f
    ld d, d
    ld d, c
    ld h, d
    inc l
    ld h, d
    ld b, e
    ld b, d
    ld b, d
    ld c, c
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
    ccf
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld a, [$eff7]
    xor $4a
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld h, $4c
    ld c, d
    ld c, a
    ld a, $41
    ld b, d
    ld d, b
    ld h, e
    ld h, d
    jr z, jr_049_4f61

    ld b, b
    ld d, d
    ld d, b
    ld b, d
    rst $28
    xor $4a
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld b, e
    ld a, $40
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, d
    ld d, [hl]
    ld a, [$eff7]
    xor $3f
    ld a, $40
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld [hl], $46
    ld c, a
    ld c, c
    ld c, h
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, b
    ld d, c
    ld b, d
    ld a, $48
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld d, c
    ld a, $49
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, [hl]
    ld d, d
    ld c, d
    ld c, d
    ld d, [hl]
    ld h, e
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld c, a

jr_049_4f61:
    ld b, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
    ld c, d
    ld h, e
    ld h, h
    ld h, d
    inc l
    ld h, d
    ld b, e
    ld b, d
    ld b, d
    ld c, c
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
    ccf
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    ld a, [$eff7]
    xor $4a
    ld b, d
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld h, e
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld h, $4c
    ld c, d
    ld c, a
    ld a, $41
    ld b, d
    ld d, b
    ld h, e
    ld h, d
    ld a, [hl+]
    ld b, [hl]
    ld d, e
    ld b, d
    rst $28
    xor $4a
    ld b, d
    ld h, d
    ld a, $62
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld b, c
    ld b, d
    ld c, d
    ld a, $4b
    ld b, c
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    rst $28
    xor $50
    ld b, [hl]
    ld c, a
    ld c, c
    ld c, h
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, b
    ld d, c
    ld b, d
    ld a, $48
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld b, c
    ld a, $56
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, d
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld b, d
    ld e, a
    rst $28
    xor $2c
    ld h, d
    ld c, c
    ld c, h
    ld d, e
    ld b, d
    ld h, d
    ccf
    ld d, d
    ld c, a
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $53
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, $44
    ld b, d
    ld d, b
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld a, $4b
    ld c, e
    ld a, $62
    ld d, c
    ld c, a
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, h
    rst $28
    xor $ff
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, d
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld b, d
    ld e, a
    rst $28
    xor $25
    ld d, d
    ld c, a
    ld c, e
    ld l, [hl]
    ld c, d
    ld h, d
    ccf
    ld d, d
    ld c, a
    ld c, e
    ld e, h
    ld b, d
    ld c, d
    ld a, [$eff7]
    xor $3e
    ld c, c
    ld c, c
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
    ccf
    ld d, d
    ld c, a
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    rst $28
    xor $4e
    ld d, d
    ld b, [hl]
    ld b, b
    ld c, b
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld d, b
    ld c, h
    rst $28
    xor $3f
    ld c, h
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld a, $4b
    ld c, e
    ld a, $62
    ccf
    ld b, d
    rst $28
    xor $3f
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld a, $41
    ld h, e
    ld h, h
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld h, e
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld c, a
    ld b, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, h
    ld a, $4b
    ld c, e
    ld a, $fa
    rst $30
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ccf
    ld d, d
    ld c, a
    ld c, e
    ld d, c
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec h
    ld d, d
    ld c, a
    ld c, e
    ld h, d
    ld c, d
    ld b, d
    ld e, [hl]
    ld h, d
    ccf
    ld c, h
    ld b, [hl]
    ld c, c
    rst $28
    xor $4a
    ld b, d
    ld h, e
    ld h, d
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld h, e
    ld a, [$eff7]
    xor $24
    ld b, l
    ld c, a
    ld b, h
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    ld [hl-], a
    ld d, d
    ld b, b
    ld b, l
    ld h, e
    rst $28
    xor $2c
    ld l, d
    ld h, d
    ld b, h
    ld c, h
    ld c, e
    ld c, e
    ld a, $62
    ld c, l
    ld d, d
    ld d, c
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, a
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    ld sp, $544c
    ld h, e
    rst $28
    xor $2a
    ld c, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $40
    ld a, $50
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld a, $ef
    xor $44
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld d, c
    ld e, a
    rst $30
    ldh a, [$f6]
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4d
    ld c, h
    ld d, b
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld a, [$eff7]
    xor $a3
    ld [hl-], a
    ld c, e
    ld b, b
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ld b, [hl]
    ld c, e
    ld e, [hl]
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld c, e
    ld b, d
    ld d, e
    ld b, d
    ld c, a
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
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld e, a
    rst $28
    xor $30
    ld a, $48
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld b, d
    ld b, b
    ld b, [hl]
    ld d, b
    ld b, [hl]
    ld c, h
    ld c, e
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld c, e
    ld c, h
    rst $28
    xor $4f
    ld b, d
    ld b, h
    ld c, a
    ld b, d
    ld d, c
    ld d, b
    ld e, a
    rst $30
    ldh a, [$f6]
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4d
    ld c, h
    ld d, b
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld a, [$eff7]
    xor $a3
    ld a, [hl-]
    ld a, $4b
    ld d, c
    ld b, d
    ld b, c
    ld h, e
    rst $28
    xor $2b
    ld a, $4d
    ld c, l
    ld d, [hl]
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld a, $49
    ld d, c
    ld b, l
    ld d, [hl]
    ld a, [$eff7]
    xor $3e
    ld c, l
    ld c, l
    ld c, c
    ld b, [hl]
    ld b, b
    ld a, $4b
    ld d, c
    ld d, b
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld b, [hl]
    ld h, e
    ld h, d
    ld a, [hl-]
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, l
    ld e, a
    rst $28
    xor $36
    ld b, [hl]
    ld c, l
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec h
    ld c, h
    ld d, b
    ld d, b
    ld h, e
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $43
    ld b, d
    ld b, d
    ld c, c
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld a, $62
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, a
    ld b, [hl]
    ld b, h
    ld b, h
    ld c, c
    ld b, d
    rst $28
    xor $47
    ld c, h
    ld b, h
    ld b, h
    ld c, c
    ld b, d
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld d, h
    ld b, d
    ld b, d
    ld d, c
    ld h, d
    ld a, $4f
    ld c, h
    ld c, d
    ld a, $62
    ld c, a
    ld b, d
    ld c, c
    ld a, $55
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
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
    ld c, a
    ld b, d
    ld a, $49
    ld c, c
    ld d, [hl]
    rst $28
    xor $51
    ld c, h
    ld c, h
    ld h, d
    ld c, d
    ld d, d
    ld b, b
    ld b, l
    ld e, a
    ld h, d
    dec h
    ld d, d
    ld d, c
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld l, b
    ld h, d
    ld c, e
    ld c, h
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    rst $28
    xor $49
    ld b, d
    ld b, e
    ld d, c
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec h
    ld c, h
    ld d, b
    ld d, b
    ld h, e
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $50
    ld c, h
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld h, e
    ld a, [$eff7]
    xor $25
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld l, b
    ld h, d
    ld c, e
    ld c, h
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    rst $28
    xor $49
    ld b, d
    ld b, e
    ld d, c
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $49
    ld c, h
    ld d, c
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld b, b
    ld b, [hl]
    ld a, $49
    ld a, [$eff7]
    xor $50
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    ld h, e
    ld h, d
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld c, e
    ld c, h
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, d
    ld c, c
    ld b, d
    ld b, e
    ld d, c
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    jr nc, jr_049_53e6

    ld c, d
    ld e, a
    ld e, a
    ld e, a
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, l
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, l
    ld h, e
    rst $28
    xor $2b
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    inc l
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld c, h
    ld d, h
    ld h, e
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld c, a
    ld b, d
    ld a, $49
    ld c, c
    ld d, [hl]
    rst $28
    xor $46
    ld c, d
    ld c, l
    ld c, a
    ld b, d
    ld d, b
    ld d, b
    ld b, d
    ld b, c
    ld h, d
    ld c, d
    ld b, d
    ld h, e
    rst $30
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    dec hl

jr_049_53e6:
    ld a, $41
    ld h, d
    ld a, $ef
    xor $44
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, e
    ld h, h
    ld h, d
    ld a, [hl-]
    ld b, d
    ld l, h
    ld b, d
    ld a, [$eff7]
    xor $44
    ld c, h
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld b, h
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld sp, $544c
    ld e, [hl]
    ld h, d
    ld d, b
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld h, d
    ld d, c
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    rst $28
    xor $4c
    ld c, e
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld a, $4f
    ld c, d
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    ld h, e
    rst $30
    ldh a, [$eb]
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
    ld d, h
    ld b, d
    ld c, a
    ld b, d
    rst $28
    xor $44
    ld c, a
    ld b, d
    ld a, $51
    ld e, a
    ld h, d
    ld a, [hl+]
    ld b, [hl]
    ld b, h
    ld b, h
    ld c, c
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    rst $30
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    dec hl
    ld a, $41
    ld h, d
    ld a, $ef
    xor $44
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, e
    ld h, h
    ld h, d
    ld a, [hl-]
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld d, c
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld b, h
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $50
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    ld a, [$eff7]
    xor $36
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    inc h
    ld b, [hl]
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, e
    rst $28
    xor $2c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [hl+]
    ld b, [hl]
    ld b, h
    ld b, h
    ld c, c
    ld b, d
    ld e, a
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld h, e
    rst $28
    xor $2c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $41
    ld c, a
    ld b, d
    ld a, $4a
    ld e, [hl]
    ld h, d
    ld c, l
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    rst $28
    xor $41
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld a, [$eff7]
    xor $54
    ld a, $48
    ld b, d
    ld h, d
    ld d, d
    ld c, l
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    dec hl
    ld a, $41
    ld h, d
    ld a, $ef
    xor $44
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, e
    ld h, h
    ld h, d
    ld a, [hl-]
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld d, c
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld b, h
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $28
    xor $f7
    ldh a, [$3a]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    ld c, e
    ld h, a
    rst $28
    xor $4f
    ld b, d
    ld c, l
    ld c, c
    ld d, [hl]
    ld e, a
    rst $30
    ldh a, [$2c]
    ld d, c
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld a, $ef
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld c, h
    ld c, c
    ld c, c
    ld h, e
    rst $30
    ldh a, [$f6]
    ld h, d
    ld b, b
    ld b, l
    ld b, d
    ld b, b
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    rst $28
    xor $3e
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld a, $50
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld b, b
    ld b, l
    ld b, d
    ld d, b
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld a, $50
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld b, b
    ld b, l
    ld b, d
    ld d, b
    ld d, c
    rst $28
    xor $54
    ld a, $50
    ld h, d
    ld a, $40
    ld d, c
    ld d, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $30
    ld b, [hl]
    ld c, d
    ld b, [hl]
    ld b, b
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $30
    ld b, [hl]
    ld c, d
    ld b, [hl]
    ld b, b
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $45
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld c, e
    ld b, h
    ld d, d
    ld b, d
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    ld h, e
    rst $30
    ldh a, [$30]
    ld b, [hl]
    ld c, d
    ld b, [hl]
    ld b, b
    ld h, d
    ld b, b
    ld c, h
    ld c, e
    ld d, c
    ld b, [hl]
    ld c, e
    ld d, d
    ld b, d
    ld d, b
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $51
    ld c, h
    ld c, e
    ld b, h
    ld d, d
    ld b, d
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec h
    ld c, c
    ld b, d
    ld a, $51
    ld h, d
    ccf
    ld c, c
    ld b, d
    ld a, $51
    ld e, a
    rst $28
    xor $2c
    ld h, d
    ld b, b
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ccf
    ld b, d
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, e
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, d
    ld a, $41
    ld b, d
    rst $28
    xor $46
    ld d, c
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    rst $28
    xor $4f
    ld b, d
    ld b, b
    ld c, h
    ld b, h
    ld c, e
    ld b, [hl]
    ld d, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $42
    ld b, e
    ld b, e
    ld c, h
    ld c, a
    ld d, c
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
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $ef
    xor $41
    ld b, d
    ld a, $41
    ld h, d
    ld b, d
    ld c, e
    ld b, c
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec h
    ld c, c
    ld b, d
    ld a, $51
    ld h, d
    ccf
    ld c, c
    ld b, d
    ld a, $51
    ld e, a
    rst $28
    xor $3a
    ld b, d
    ld c, c
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $41
    ld b, d
    ld a, $41
    ld h, d
    ld b, d
    ld c, e
    ld b, c
    ld e, [hl]
    ld h, d
    ccf
    ld c, c
    ld b, d
    ld a, $51
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec h
    ld c, c
    ld b, d
    ld a, $51
    ld h, d
    ccf
    ld c, c
    ld b, d
    ld a, $51
    ld e, a
    rst $28
    xor $2c
    ld h, d
    ld c, e
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld c, d
    ld a, $44
    ld b, [hl]
    ld c, e
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $50
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld a, $62
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    rst $28
    xor $4a
    ld a, $50
    ld d, c
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
    ld h, e
    rst $30
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld c, e
    ld c, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld c, h
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $49
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld h, d
    ld b, a
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    rst $28
    xor $4a
    ld b, d
    ld h, h
    ld h, d
    dec hl
    ld b, d
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    or $5e
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, h
    ld a, [$eff7]
    xor $2f
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ccf
    ld a, $40
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
    ld a, $3f
    ld d, d
    ld d, b
    ld b, d
    ld b, c
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
    ld b, b
    ld c, a
    ld d, d
    ld b, d
    ld c, c
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, l
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    rst $28
    xor $4c
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $3e
    ld b, h
    ld a, $46
    ld c, e
    ld e, [hl]
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    ld c, e
    ld h, a
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
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld b, h
    ld c, e
    ld b, [hl]
    ld d, a
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $3e
    ccf
    ld d, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, h
    rst $28
    xor $ff
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $49
    ld b, d
    ld a, $4f
    ld c, e
    ld h, d
    ccf
    ld d, [hl]
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld b, d
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld b, d
    ld a, $40
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $45
    ld a, $4f
    ld b, c
    ld h, d
    ld d, h
    ld a, $56
    ld h, e
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
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld b, h
    ld c, e
    ld b, [hl]
    ld d, a
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld e, [hl]
    ld h, d
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, h
    ld a, [$eff7]
    xor $31
    ld c, h
    ld d, h
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $53
    ld b, d
    ld c, a
    ld b, c
    ld b, [hl]
    ld b, b
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    jr nc, jr_049_5947

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $30
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    or $fa
    rst $30
    rst $28
    xor $4f
    ld b, d
    ld b, b
    ld c, h
    ld b, h
    ld c, e
    ld b, [hl]
    ld d, a
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, e
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld a, $3f
    ld d, d
    ld d, b
    ld b, d
    ld e, [hl]
    ld a, [$eff7]
    xor $9f
    and e
    ld a, $4b
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ccf
    ld d, [hl]
    rst $28
    xor $4d
    ld c, c
    ld b, d
    ld b, c
    ld b, h
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld c, h

jr_049_5947:
    ld h, d
    ld a, $40
    ld b, b
    ld b, d
    ld c, l
    ld d, c
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld d, [hl]
    ld h, d
    ld c, l
    ld d, d
    ld c, e
    ld b, [hl]
    ld d, b
    ld b, l
    ld c, d
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
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    ld e, [hl]
    ld h, d
    or $ef
    xor $46
    ld d, b
    ld h, d
    ld d, b
    ld b, d
    ld c, e
    ld d, c
    ld b, d
    ld c, e
    ld b, b
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld b, c
    ld b, d
    ld a, $51
    ld b, l
    ld h, d
    ld c, l
    ld b, d
    ld c, e
    ld a, $49
    ld d, c
    ld d, [hl]
    ld h, e
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    or $5e
    ld d, c
    ld a, $48
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $4d
    ld d, d
    ld c, e
    ld b, [hl]
    ld d, b
    ld b, l
    ld c, d
    ld b, d
    ld c, e
    ld d, c
    ld h, e
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $49
    ld b, d
    ld a, $4f
    ld c, e
    ld h, d
    ccf
    ld d, [hl]
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
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
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld b, d
    ld a, $40
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $45
    ld a, $4f
    ld b, c
    ld h, d
    ld d, h
    ld a, $56
    ld h, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld sp, $544c
    ld h, d
    ld d, h
    ld b, d
    ld l, c
    ld b, d
    rst $28
    xor $45
    ld c, h
    ld c, c
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $62
    ld c, l
    ld d, d
    ccf
    ld c, c
    ld b, [hl]
    ld b, b
    ld a, [$eff7]
    xor $42
    ld d, l
    ld b, d
    ld b, b
    ld d, d
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $f6
    ld h, d
    ccf
    ld d, [hl]
    ld a, [$eff7]
    xor $44
    ld d, d
    ld b, [hl]
    ld c, c
    ld c, c
    ld c, h
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    daa
    ld b, d
    ld a, $41
    ld h, d
    ld c, d
    ld a, $4b
    ld h, d
    or $ef
    xor $54
    ld a, $49
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, h
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
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
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld a, $56
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, d
    ld h, h
    rst $28
    xor $ff
    ldh a, [$ea]
    sbc a
    and e
    ld sp, $4b4c
    ld b, d
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
    ld b, l
    ld b, d
    ld b, d
    ld c, b
    ld h, e
    ld h, d
    inc l
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $41
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $44
    ld d, d
    ld b, [hl]
    ld c, c
    ld c, c
    ld c, h
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld b, d
    ld c, e
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld b, c
    ld b, d
    ld a, $51
    ld b, l
    ld a, [$eff7]
    xor $3f
    ld d, [hl]
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld b, l
    ld a, $4b
    ld b, c
    ld h, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, d
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
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $3e
    ld b, c
    ld b, c
    ld b, [hl]
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld a, $49
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld d, b
    ld h, h
    rst $30
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    or $68
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
    ld d, c
    ld c, a
    ld d, d
    ld d, b
    ld d, c
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld e, [hl]
    ld h, d
    or $63
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    daa
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $54
    ld c, h
    ld c, a
    ld c, a
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld b, a
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, e
    ld a, [$eff7]
    xor $31
    ld c, h
    ld d, h
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, e
    rst $28
    xor $f7
    ldh a, [$f6]
    ld h, d
    ld d, c
    ld c, h
    ld d, d
    ld b, b
    ld b, l
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $3f
    ld c, c
    ld a, $41
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $44
    ld d, d
    ld b, [hl]
    ld c, c
    ld c, c
    ld c, h
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, d
    ld e, a
    rst $28
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld c, h
    ld c, c
    ld b, c
    ld h, d
    ccf
    ld c, c
    ld a, $41
    ld b, d
    ld a, [$eff7]
    xor $4f
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld d, b
    ld h, d
    or $68
    rst $28
    xor $43
    ld a, $40
    ld b, d
    ld e, a
    rst $30
    ldh a, [$f6]
    ld h, d
    ld d, c
    ld c, h
    ld d, d
    ld b, b
    ld b, l
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $3f
    ld c, c
    ld a, $41
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $44
    ld d, d
    ld b, [hl]
    ld c, c
    ld c, c
    ld c, h
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, d
    ld e, a
    rst $28
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld c, h
    ld c, c
    ld b, c
    ld h, d
    ccf
    ld c, c
    ld a, $41
    ld b, d
    ld a, [$eff7]
    xor $4f
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld d, b
    ld h, d
    or $68
    rst $28
    xor $43
    ld a, $40
    ld b, d
    ld e, [hl]
    ld a, [$eff7]
    xor $3e
    ld d, b
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $44
    ld d, d
    ld b, [hl]
    ld c, c
    ld c, c
    ld c, h
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $54
    ld b, d
    ld c, c
    ld b, b
    ld c, h
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    or $63
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc h
    ld a, $3e
    ld a, $4f
    ld c, a
    ld c, a
    ld b, h
    ld b, h
    ld b, l
    ld h, e
    rst $28
    xor $2a
    ld d, h
    ld c, a
    ld c, a
    ld c, a
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl+]
    ld d, h
    ld c, a
    ld c, a
    ld b, h
    ld b, h
    ld b, h
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl+]
    ld d, h
    ld d, h
    ld c, a
    ld c, a
    ld b, h
    ld b, h
    ld b, h
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    or $63
    rst $28
    xor $2f
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ld b, h
    ld c, h
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc h
    ld a, $3e
    ld c, a
    ld c, a
    ld c, a
    ld b, h
    ld b, h
    ld b, l
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
    ld h, a
    ld h, d
    ld d, b
    ld d, c
    ld a, $4b
    ld b, c
    rst $28
    xor $46
    ld d, c
    ld e, a
    ld h, d
    inc l
    ld h, d
    ld b, a
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    ld a, [$eff7]
    xor $50
    ld d, c
    ld a, $4b
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld e, a
    ld h, d
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    rst $28
    xor $50
    ld d, c
    ld a, $4b
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld e, a
    ld h, d
    inc l
    ld h, d
    ld c, c
    ld c, h
    ld d, b
    ld d, c
    ld h, e
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl+]
    ld d, h
    ld c, a
    ld c, a
    ld c, a
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    cpl
    ld c, h
    ld c, h
    ld c, b
    ld e, a
    ld e, a
    ld e, a
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    rst $28
    xor $50
    ld d, h
    ld c, h
    ld c, a
    ld b, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $2e
    ld d, d
    ld d, b
    ld a, $4b
    ld a, $44
    ld b, [hl]
    ld h, d
    ld d, b
    ld d, h
    ld c, h
    ld c, a
    ld b, c
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld [hl-], a
    ld c, a
    ld c, h
    ld b, b
    ld b, l
    ld b, [hl]
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
    ld l, d
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $49
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
    ld h, d
    ld d, b
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $40
    ld b, l
    ld b, d
    ld a, $4d
    ld h, d
    ld d, b
    ld d, h
    ld c, h
    ld c, a
    ld b, c
    ld h, e
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld e, a
    ld e, a
    ld e, a
    daa
    ld b, [hl]
    ld b, c
    ld h, d
    ld d, h
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld b, d
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
    ld h, h
    ld a, [$eff7]
    xor $9f
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
    xor $51
    ld b, l
    ld a, $4b
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld a, [$eff7]
    xor $45
    ld b, d
    ld c, c
    ld c, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
    ld a, $63
    ld h, d
    ld [hl], $52
    ld b, b
    ld b, l
    ld h, d
    ld a, $62
    ld c, e
    ld a, $46
    ld d, e
    ld b, d
    rst $28
    xor $44
    ld d, d
    ld d, [hl]
    ld e, a
    ld h, d
    daa
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld a, [$eff7]
    xor $54
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    ld b, a
    ld d, d
    ld d, b
    ld d, c
    rst $28
    xor $49
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
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld d, b
    ld d, c
    ld h, d
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld b, e
    ld d, d
    ld c, c
    rst $28
    xor $50
    ld d, h
    ld c, h
    ld c, a
    ld b, c
    ld e, a
    ld h, d
    scf
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    ld a, $49
    ld c, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $4b
    ld c, h
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $50
    ld a, $56
    ld e, [hl]
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, h
    ld c, h
    ld e, a
    rst $28
    xor $ff
    ldh a, [$ea]
    sbc a
    and e
    ld [hl], $4c
    ld h, d
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld h, e
    ld h, d
    scf
    ld b, l
    ld b, d
    rst $28
    xor $32
    ld c, a
    ld c, h
    ld b, b
    ld b, l
    ld b, [hl]
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld h, a
    ld a, [$eff7]
    xor $51
    ld c, a
    ld c, h
    ld d, d
    ccf
    ld c, c
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $3e
    ld c, e
    ld d, [hl]
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc h
    ld d, c
    ld h, d
    ld c, c
    ld b, d
    ld a, $50
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $50
    ld b, l
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld c, l
    ld c, a
    ld a, $40
    ld d, c
    ld b, [hl]
    ld b, b
    ld b, d
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld d, b
    ld d, h
    ld c, h
    ld c, a
    ld b, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, h
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld d, h
    ld b, l
    ld d, [hl]
    ld h, d
    inc l
    ld h, d
    ld a, $4a
    ld a, [$eff7]
    xor $49
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
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ld d, b
    ld d, h
    ld c, h
    ld c, a
    ld b, c
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, e
    ld b, e
    ld b, d
    ld c, a
    ld b, d
    ld c, e
    ld b, b
    ld b, d
    rst $28
    xor $41
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    ld e, a
    ld e, a
    ld e, a
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
    ld a, [$eff7]
    xor $2c
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, c
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    ld h, d
    ld a, $4a
    ld h, d
    inc l
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld b, d
    ld d, b
    ld d, c
    ld a, [$eff7]
    xor $50
    ld d, h
    ld c, h
    ld c, a
    ld b, c
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld d, c
    ld d, b
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld a, $52
    ld d, b
    ld b, d
    ld h, d
    inc l
    rst $28
    xor $54
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld a, [$eff7]
    xor $4d
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld b, e
    ld d, d
    ld c, c
    ld e, a
    ld h, d
    inc l
    ld h, d
    ld b, l
    ld a, $51
    ld b, d
    rst $28
    xor $54
    ld b, d
    ld a, $48
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld b, l
    ld a, $51
    ld b, d
    ld h, d
    ld c, c
    ld c, h
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    rst $28
    xor $36
    ld c, h
    ld e, [hl]
    ld h, d
    inc l
    ld h, d
    ld c, e
    ld b, d
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld b, d
    ld c, a
    ld h, d
    ld d, b
    ld d, h
    ld c, h
    ld c, a
    ld b, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld sp, $3f4c
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    rst $28
    xor $51
    ld c, a
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, l
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld c, a
    ld a, [$eff7]
    xor $2c
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld c, d
    ld a, $50
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld [hl-], a
    ld b, l
    ld e, [hl]
    ld h, d
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    ld d, h
    ld a, $50
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $4a
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl+]
    ld c, h
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    rst $28
    xor $44
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld h, d
    ld [hl-], a
    ld c, a
    ld c, h
    ld b, b
    ld b, l
    ld b, [hl]
    ld h, d
    ld a, [$eff7]
    xor $54
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld a, $4b
    ld d, [hl]
    rst $28
    xor $51
    ld c, a
    ld c, h
    ld d, d
    ccf
    ld c, c
    ld b, d
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc h
    ld d, c
    ld h, d
    ld c, c
    ld b, d
    ld a, $50
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    rst $28
    xor $50
    ld b, l
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld c, l
    ld c, a
    ld a, $40
    ld d, c
    ld b, [hl]
    ld b, b
    ld b, d
    ld h, d
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld d, b
    ld d, h
    ld c, h
    ld c, a
    ld b, c
    ld h, e
    ld h, d
    rst $28
    xor $f7
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    ld [hl-], a
    ld b, l
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $54
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld a, $53
    ld b, d
    ld b, c
    ld h, d
    ccf
    ld d, [hl]
    ld a, [$eff7]
    xor $50
    ld c, h
    ld c, d
    ld b, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld e, a
    ld h, d
    ld [hl-], a
    ld b, l
    ld h, d
    ld d, h
    ld b, d
    ld c, c
    ld c, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3a
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
    sbc a
    and e
    ld a, [hl-]
    ld b, d
    ld c, c
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    or $63
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld l, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld d, b
    ld e, [hl]
    ld a, [$eff7]
    xor $27
    ld c, a
    ld a, $40
    ld c, h
    cpl
    ld c, h
    ld c, a
    ld b, c
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $27
    ld c, a
    ld a, $40
    ld c, h
    cpl
    ld c, h
    ld c, a
    ld b, c
    and e
    inc l
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $3f
    ld b, d
    ld b, d
    ld c, e
    ld h, d
    ld d, h
    ld a, $46
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    and h
    ld a, [$eff7]
    xor $27
    ld c, a
    ld a, $40
    ld c, h
    cpl
    ld c, h
    ld c, a
    ld b, c
    and e
    and h
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld a, $ef
    xor $56
    ld c, h
    ld d, d
    ld d, c
    ld b, l
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $50
    ld b, l
    ld c, h
    ld d, h
    ld h, d
    ld d, d
    ld c, l
    ld e, a
    ld h, d
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $27
    ld c, a
    ld a, $40
    ld c, h
    cpl
    ld c, h
    ld c, a
    ld b, c
    and e
    inc l
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld a, [$eff7]
    xor $4d
    ld a, $49
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $27
    ld c, a
    ld a, $40
    ld c, h
    cpl
    ld c, h
    ld c, a
    ld b, c
    and e
    inc l
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $44
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, [hl]
    ld h, d
    or $fa
    rst $30
    rst $28
    xor $45
    ld a, $49
    ld b, e
    ld h, d
    ld c, h
    ld b, e
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $27
    ld c, a
    ld a, $40
    ld c, h
    cpl
    ld c, h
    ld c, a
    ld b, c
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    rst $28
    xor $41
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld a, $56
    ld h, h
    ld a, [$eff7]
    xor $3a
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $4d
    ld a, $49
    ld h, h
    rst $38
    ldh a, [$ea]
    daa
    ld c, a
    ld a, $40
    ld c, h
    cpl
    ld c, h
    ld c, a
    ld b, c
    and e
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    ld e, [hl]
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld a, $44
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld h, e
    ld a, [$eff7]
    xor $31
    ld c, h
    ld d, h
    ld h, d
    inc l
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $44
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $27
    ld c, a
    ld a, $40
    ld c, h
    cpl
    ld c, h
    ld c, a
    ld b, c
    and e
    ld b, l
    ld a, $49
    ld b, e
    rst $28
    xor $4c
    ld b, e
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
    ld e, [hl]
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $41
    ld a, $4f
    ld c, b
    ld c, e
    ld b, d
    ld d, b
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $27
    ld c, a
    ld a, $40
    ld c, h
    cpl
    ld c, h
    ld c, a
    ld b, c
    and e
    daa
    ld b, [hl]
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $4f
    ld b, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld h, d
    ccf
    ld b, d
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, e
    ld b, d
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld d, h
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld d, b
    ld a, $56
    rst $28
    xor $50
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld a, $62
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, h
    ld a, [$eff7]
    xor $27
    ld c, a
    ld a, $40
    ld c, h
    cpl
    ld c, h
    ld c, a
    ld b, c
    and e
    add hl, hl
    ld c, h
    ld c, h
    ld c, c
    ld h, e
    rst $28
    xor $37
    ld b, l
    ld a, $51
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $51
    ld b, d
    ld a, $40
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    daa
    ld c, a
    ld a, $40
    ld c, h
    cpl
    ld c, h
    ld c, a
    ld b, c
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld l, b
    rst $28
    xor $54
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $2c
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld a, $62
    ccf
    ld a, $41
    rst $28
    xor $4c
    ld b, e
    ld b, e
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $27
    ld c, a
    ld a, $40
    ld c, h
    cpl
    ld c, h
    ld c, a
    ld b, c
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    rst $28
    xor $4f
    ld b, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld a, [$eff7]
    xor $45
    ld a, $49
    ld b, e
    ld h, d
    ld c, h
    ld b, e
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
    ld h, h
    rst $28
    xor $ff
    ldh a, [$ea]
    daa
    ld c, a
    ld a, $40
    ld c, h
    cpl
    ld c, h
    ld c, a
    ld b, c
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld a, $56
    ld h, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld a, $51
    ld h, d
    ld c, d
    ld b, d
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $27
    ld c, a
    ld a, $40
    ld c, h
    cpl
    ld c, h
    ld c, a
    ld b, c
    and e
    add hl, hl
    ld c, h
    ld c, h
    ld c, c
    ld h, e
    rst $28
    xor $37
    ld b, l
    ld a, $51
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld a, [$eff7]
    xor $51
    ld b, d
    ld a, $40
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    daa
    ld c, a
    ld a, $40
    ld c, h
    cpl
    ld c, h
    ld c, a
    ld b, c
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    rst $28
    xor $40
    ld a, $4a
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, h
    ld a, [$eff7]
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld c, e
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld c, c
    ld b, d
    ld a, $4f
    ld c, e
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $27
    ld a, $4f
    ld b, b
    ld c, h
    cpl
    ld c, h
    ld a, $41
    and e
    inc l
    ld l, d
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    rst $28
    xor $46
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld b, d
    ld d, b
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $54
    ld b, d
    ld a, $48
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $27
    ld c, a
    ld a, $40
    ld c, h
    cpl
    ld c, h
    ld c, a
    ld b, c
    and e
    inc a
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    rst $28
    xor $4d
    ld a, $56
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld a, [$eff7]
    xor $4f
    ld d, d
    ld b, c
    ld b, d
    ld c, e
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, e
    ld b, d
    ld h, e
    rst $30
    ldh a, [$ea]
    daa
    ld c, a
    ld a, $40
    ld c, h
    cpl
    ld c, h
    ld c, a
    ld b, c
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld b, d
    ld a, $51
    rst $28
    xor $4a
    ld b, d
    ld e, a
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $50
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
    xor $f7
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    ld [hl-], a
    ld c, e
    ld b, d
    rst $28
    xor $41
    ld c, h
    ld d, h
    ld c, e
    ld h, e
    ld h, d
    or $63
    ld h, d
    ld a, [$eff7]
    xor $2f
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld c, h
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    daa
    ld b, [hl]
    ld d, b
    ld d, c
    ld d, d
    ld c, a
    ccf
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $4a
    ld d, [hl]
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld d, c
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, e
    ld c, h
    ld c, h
    ld c, c
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
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
    ld b, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    rst $28
    xor $48
    ld c, e
    ld c, h
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    inc l
    ld l, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, [$eff7]
    xor $44
    ld c, a
    ld b, d
    ld a, $51
    ld h, d
    ld c, h
    ld c, a
    ld a, $40
    ld c, c
    ld b, d
    ld e, [hl]
    rst $28
    xor $2b
    ld a, $4f
    ld b, h
    ld c, h
    ld c, e
    ld h, e
    ld h, h
    ld h, d
    rst $38
    ldh a, [$ea]
    dec hl
    ld a, $4f
    ld b, h
    ld c, h
    ld c, e
    and e
    scf
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $52
    ld c, e
    ld b, e
    ld c, h
    ld c, a
    ld b, h
    ld b, [hl]
    ld d, e
    ld a, $3f
    ld c, c
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $2b
    ld a, $4f
    ld b, h
    ld c, h
    ld c, e
    and e
    inc l
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $51
    ld b, d
    ld a, $40
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld c, h
    ld d, h
    ld a, [$eff7]
    xor $43
    ld c, h
    ld c, h
    ld c, c
    ld b, [hl]
    ld d, b
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    dec hl
    ld a, $4f
    ld b, h
    ld c, h
    ld c, e
    and e
    scf
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    rst $28
    xor $50
    ld b, l
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld e, [hl]
    ld a, [$eff7]
    xor $2b
    ld a, $4f
    ld b, h
    ld c, h
    ld c, e
    and e
    inc l
    ld l, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $44
    ld c, a
    ld b, d
    ld a, $51
    ld h, d
    ld c, h
    ld c, a
    ld a, $40
    ld c, c
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld b, c
    ld e, [hl]
    ld h, d
    dec hl
    ld a, $4f
    ld b, h
    ld c, h
    ld c, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    dec hl
    ld a, $4f
    ld b, h
    ld c, h
    ld c, e
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2b
    ld a, $4f
    ld b, h
    ld c, h
    ld c, e
    and e
    inc l
    ld c, e
    ld d, b
    ld c, h
    ld c, c
    ld a, $4b
    ld d, c
    rst $28
    xor $43
    ld c, h
    ld c, h
    ld c, c
    ld h, e
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld b, h
    ld b, d
    ld d, c
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld d, b
    ld d, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2b
    ld a, $4f
    ld b, h
    ld c, h
    ld c, e
    and e
    inc l
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    rst $28
    xor $40
    ld c, a
    ld d, d
    ld d, b
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, b
    ld b, d
    ld b, b
    ld d, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    dec hl
    ld a, $4f
    ld b, h
    ld c, h
    ld c, e
    and e
    scf
    ld c, h
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $53
    ld b, d
    ld d, l
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $2b
    ld a, $4f
    ld b, h
    ld c, h
    ld c, e
    and e
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, h
    ld c, a
    ld b, d
    ld a, $51
    rst $28
    xor $2b
    ld a, $4f
    ld b, h
    ld c, h
    ld c, e
    ld h, d
    ld d, h
    ld a, $50
    ld a, [$eff7]
    xor $41
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    ld b, d
    ld b, c
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld d, b
    ld d, d
    ld b, b
    ld b, l
    rst $28
    xor $3e
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld a, [$eff7]
    xor $2b
    ld a, $4f
    ld b, h
    ld c, h
    ld c, e
    and e
    inc l
    ld l, d
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld b, b
    ld c, b
    ld b, d
    ld b, c
    rst $28
    xor $3f
    ld d, d
    ld d, c
    ld h, d
    inc l
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $3e
    ld b, c
    ld c, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $4d
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $2b
    ld a, $4f
    ld b, h
    ld c, h
    ld c, e
    and e
    dec hl
    ld c, h
    ld d, h
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2b
    ld a, $4f
    ld b, h
    ld c, h
    ld c, e
    and e
    dec [hl]
    ld b, d
    ld c, d
    ld b, d
    ld c, d
    ccf
    ld b, d
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2b
    ld a, $4f
    ld b, h
    ld c, h
    ld c, e
    and e
    ld [hl], $4c
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    rst $28
    xor $42
    ld d, l
    ld b, [hl]
    ld d, b
    ld d, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $54
    ld c, h
    ld c, a
    ld c, c

Jump_049_6864:
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $40
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ccf
    ld b, d
    ld a, $51
    ld h, e
    rst $30
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    dec hl
    ld c, d
    ld h, h
    ld h, d
    inc l
    rst $28
    xor $50
    ld d, c
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld d, b
    ld c, d
    ld b, d
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    ld a, [hl-]
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $41
    ld c, h
    ld b, d
    ld d, b
    ld c, e
    ld h, a
    ld h, d
    ld c, d
    ld a, $51
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    ld a, [$eff7]
    xor $2f
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld e, a
    ld e, a
    ld e, a
    inc l
    ld e, a
    ld e, a
    ld e, a
    ld a, $4a
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    ld b, h
    ld c, h
    ld b, c
    ld e, a
    ld e, a
    ld e, a
    ld c, h
    ld b, e
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $41
    ld b, d
    ld d, b
    ld d, c
    ld c, a
    ld d, d
    ld b, b
    ld e, a
    ld e, a
    ld e, a
    ld d, c
    ld b, [hl]
    ld c, h
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
    ld e, a
    ld e, a
    ld e, a
    ld [hl], $46
    ld e, a
    ld e, a
    ld e, a
    ld b, c
    ld c, h
    ld b, l
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
    ld e, a
    ld e, a
    ld e, a
    ld b, c
    ld b, d
    ld d, b
    ld b, [hl]
    ld c, a
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $36
    ld b, [hl]
    ld b, c
    ld c, h
    ld b, l
    and e
    rst $28
    xor $27
    jr z, jr_049_698b

    scf
    dec [hl]
    jr c, @+$28

    scf
    inc l
    ld [hl-], a
    ld sp, $6363
    rst $30
    ldh a, [$ea]
    ld [hl], $46
    ld b, c
    ld c, h
    ld b, l
    and e
    ld e, a
    ld e, a
    ld e, a
    inc l
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $41
    ld b, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld d, [hl]
    ld e, a
    ld e, a
    ld e, a
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
    ld [hl], $46
    ld b, c
    ld c, h
    ld b, l
    and e
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a

jr_049_698b:
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    rst $28
    xor $54
    ld a, $50
    ld h, d
    ld a, $62
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld a, [$eff7]
    xor $50
    ld d, c
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3a
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
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc h
    ld d, c
    ld h, d
    ld c, c
    ld a, $50
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4a
    ld b, d
    rst $28
    xor $45
    ld b, d
    ld c, a
    ld b, d
    ld e, [hl]
    ld h, d
    ld c, l
    ld a, $51
    ld b, l
    ld b, d
    ld d, c
    ld b, [hl]
    ld b, b
    ld h, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld b, c
    ld a, $4f
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld a, [$eff7]
    xor $50
    ld d, c
    ld a, $51
    ld d, d
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
    ld b, c
    ld b, [hl]
    ld d, b
    ld c, h
    ccf
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $44
    ld c, a
    ld b, d
    ld a, $51
    ld h, d
    ld c, c
    ld c, h
    ld c, a
    ld b, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, [$eff7]
    xor $42
    ld d, e
    ld b, [hl]
    ld c, c
    ld e, [hl]
    ld h, d
    dec h
    ld a, $4f
    ld a, $4a
    ld c, h
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $25
    ld a, $4f
    ld a, $4a
    ld c, h
    ld d, b
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $4f
    ld b, d
    ld b, h
    ld c, a
    ld b, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld a, [$eff7]
    xor $40
    ld a, $4a
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $25
    ld a, $4f
    ld a, $4a
    ld c, h
    ld d, b
    and e
    inc l
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    rst $28
    xor $42
    ld a, $51
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld b, h
    ld d, d
    ld d, c
    ld d, b
    and h
    ld a, [$eff7]
    xor $25
    ld a, $4f
    ld a, $4a
    ld c, h
    ld d, b
    and e
    ld d, b
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $40
    ld a, $4b
    ld h, a
    ld h, d
    ccf
    ld b, d
    ld h, d
    ccf
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    ld a, [$eff7]
    xor $3f
    ld a, $40
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, e
    ld b, d
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    rst $28
    xor $3e
    ld b, h
    ld a, $46
    ld c, e
    ld h, e
    rst $30
    ldh a, [$ea]
    dec h
    ld a, $4f
    ld a, $4a
    ld c, h
    ld d, b
    and e
    add hl, hl
    ld c, h
    ld c, h
    ld c, c
    ld h, e
    ld h, d
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $50
    ld d, c
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, c
    ld b, [hl]
    ld d, b
    ld c, h
    ccf
    ld b, d
    ld d, [hl]
    ld h, d
    ld c, d
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $25
    ld a, $4f
    ld a, $4a
    ld c, h
    ld d, b
    and e
    scf
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    rst $28
    xor $44
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld h, d
    ld b, e
    ld a, $4f
    ld e, a
    ld h, d
    ld a, [$eff7]
    xor $2b
    ld c, d
    ld e, [hl]
    ld h, d
    ccf
    ld d, d
    ld d, c
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
    rst $28
    xor $4a
    ld a, $51
    ld d, c
    ld b, d
    ld c, a
    ld e, [hl]
    ld a, [$eff7]
    xor $25
    ld a, $4f
    ld a, $4a
    ld c, h
    ld d, b
    and e
    ld sp, $624c
    ld c, d
    ld a, $51
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $45
    ld c, h
    ld d, h
    ld h, d
    ld c, d
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $40
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld e, [hl]
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $54
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld a, [$eff7]
    xor $41
    ld b, [hl]
    ld b, e
    ld b, e
    ld b, d
    ld c, a
    ld b, d
    ld c, e
    ld b, b
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $25
    ld a, $4f
    ld a, $4a
    ld c, h
    ld d, b
    and e
    inc l
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $51
    ld b, d
    ld a, $40
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld c, h
    ld d, h
    ld a, [$eff7]
    xor $44
    ld c, a
    ld b, d
    ld a, $51
    ld h, d
    inc l
    ld h, d
    ld a, $4a
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    dec h
    ld a, $4f
    ld a, $4a
    ld c, h
    ld d, b
    and e
    inc h
    ld c, a
    ld b, l
    ld b, h
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $56
    ld e, a
    ld e, a
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $25
    ld a, $4f
    ld a, $4a
    ld c, h
    ld d, b
    and e
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld b, c
    ld a, $4f
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld e, a
    ld e, a
    ld e, a
    rst $30
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    rst $28
    xor $28
    ld d, l
    ld b, b
    ld b, d
    ld c, c
    ld c, c
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    or $5f
    ld a, [$eff7]
    xor $2f
    ld b, d
    ld b, d
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, d
    ld c, c
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $3e
    ld c, c
    ld d, c
    ld a, $4f
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, [$eff7]
    xor $50
    ld a, $40
    ld c, a
    ld b, [hl]
    ld b, e
    ld b, [hl]
    ld b, b
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
    ld a, $4a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    dec a
    ld c, h
    ld c, d
    ld a, $ef
    xor $54
    ld b, l
    ld c, h
    ld h, d
    ld a, $4b
    ld c, e
    ld b, [hl]
    ld b, l
    ld b, [hl]
    ld c, c
    ld a, $51
    ld b, d
    ld d, b
    ld h, d
    ld a, [$eff7]
    xor $3e
    ld c, c
    ld c, c
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3d
    ld c, h
    ld c, d
    ld a, $a3
    inc l
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld d, b
    ld a, $40
    ld c, a
    ld b, [hl]
    sbc h
    rst $28
    xor $43
    ld b, [hl]
    ld b, b
    ld b, d
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld c, h
    ld c, e
    ld b, d
    ld e, [hl]
    ld a, [$eff7]
    xor $3d
    ld c, h
    ld c, d
    ld a, $a3
    ld a, $4b
    ld b, c
    ld h, d
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $42
    ld c, e
    ld d, c
    ld b, [hl]
    ld c, a
    ld b, d
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, [$eff7]
    xor $41
    ld b, d
    ld d, b
    ld c, l
    ld a, $46
    ld c, a
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3d
    ld c, h
    ld c, d
    ld a, $a3
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld d, d
    ld b, h
    ld b, h
    ld c, c
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3d
    ld c, h
    ld c, d
    ld a, $a3
    inc h
    ld c, e
    ld c, e
    ld b, [hl]
    ld b, l
    ld b, [hl]
    ld c, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld b, a
    ld c, h
    ld d, [hl]
    ld e, a
    ld h, d
    daa
    ld b, d
    ld a, $51
    ld b, l
    ld a, [$eff7]
    xor $46
    ld d, b
    ld h, d
    ccf
    ld b, d
    ld a, $52
    ld d, c
    ld d, [hl]
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3d
    ld c, h
    ld c, d
    ld a, $a3
    ld sp, $544c
    ld e, [hl]
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld h, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, c
    ld a, $50
    ld d, c
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld a, $51
    ld b, l
    ld a, [$eff7]
    xor $46
    ld c, e
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld a, $4f
    ld c, d
    ld d, b
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    dec a
    ld c, h
    ld c, d
    ld a, $a3
    dec hl
    ld c, d
    ld c, d
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld c, d
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld c, e
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld c, c
    ld b, d
    ld a, $4f
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $3d
    ld c, h
    ld c, d
    ld a, $a3
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld h, d
    ld c, d
    ld a, $51
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $45
    ld c, h
    ld d, h
    ld h, d
    ld b, l
    ld a, $4f
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld c, a
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld a, [$eff7]
    xor $46
    ld d, c
    ld h, [hl]
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld a, $4a
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3d
    ld c, h
    ld c, d
    ld a, $a3
    daa
    ld b, [hl]
    ld b, d
    ld h, d
    ld d, b
    ld c, h
    ld h, d
    ld c, l
    ld b, d
    ld c, h
    ld c, l
    ld c, c
    ld b, d
    rst $28
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld a, [$eff7]
    xor $4a
    ld b, [hl]
    ld d, b
    ld b, d
    ld c, a
    ld a, $3f
    ld c, c
    ld b, d
    ld h, d
    ld b, b
    ld c, h
    ld c, a
    ld c, l
    ld d, b
    ld b, d
    rst $28
    xor $3e
    ld d, c
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld b, e
    ld b, d
    ld b, d
    ld d, c
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
    dec a
    ld c, h
    ld c, d
    ld a, $a3
    ld e, a
    ld e, a
    ld e, a
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    ld h, d
    ld d, b
    ld c, h
    ld c, e
    ld h, h
    ld a, [$eff7]
    xor $3d
    ld c, h
    ld c, d
    ld a, $a3
    inc l
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld e, [hl]
    ld h, d
    rst $28
    xor $f6
    ld e, a
    ld a, [$eff7]
    xor $3d
    ld c, h
    ld c, d
    ld a, $a3
    or $5f
    ld e, a
    ld e, a
    rst $28
    xor $3a
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld a, [$eff7]
    xor $41
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3d
    ld c, h
    ld c, d
    ld a, $a3
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld a, $50
    ld h, d
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    rst $28
    xor $3e
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld e, [hl]
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld a, $4f
    ld c, b
    ld c, e
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    rst $28
    xor $42
    ld d, l
    ld b, [hl]
    ld d, b
    ld d, c
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $3d
    ld c, h
    ld c, d
    ld a, $a3
    inc h
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    rst $28
    xor $50
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld b, d
    ld c, a
    ld e, [hl]
    ld h, d
    ld a, $4b
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, e
    ld h, d
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, a
    ld b, d
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
    rst $28
    xor $3f
    ld b, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, [hl]
    ld a, [$eff7]
    xor $3d
    ld c, h
    ld c, d
    ld a, $a3
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, b
    ld c, h
    ld c, e
    ld b, e
    ld c, a
    ld c, h
    ld c, e
    ld d, c
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld e, a
    ld e, a
    ld e, a
    ld h, e
    rst $30
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld l, c
    ld b, d
    rst $28
    xor $49
    ld c, h
    ld d, c
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, e
    rst $28
    xor $2f
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl+]
    ld d, h
    ld d, h
    ld c, a
    ld c, a
    ld c, a
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    ld h, e
    rst $28
    xor $3a
    ld b, l
    ld c, h
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, h
    ld h, d
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    inc sp
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld c, h
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld b, a
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    rst $28
    xor $54
    ld c, h
    ld c, b
    ld b, d
    ld c, e
    ld h, d
    ld a, $50
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $33
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld c, h
    and e
    inc h
    ld c, a
    ld c, a
    ld c, a
    ld b, h
    ld b, h
    ld b, h
    ld b, l
    ld b, l
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $33
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld c, h
    and e
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $4f
    ld b, d
    ld c, d
    ld b, d
    ld c, d
    ccf
    ld b, d
    ld c, a
    ld h, d
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld d, [hl]
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $33
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld c, h
    and e
    dec h
    ld d, d
    ld d, c
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $33
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld c, h
    and e
    inc l
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    rst $28
    xor $54
    ld b, l
    ld a, $51
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, c
    ld c, h
    ld e, a
    ld a, [$eff7]
    xor $33
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld c, h
    and e
    daa
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $52
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld d, b
    ld d, c
    ld a, $4b
    ld b, c
    ld h, h
    rst $38
    ldh a, [$ea]
    inc sp
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld c, h
    and e
    ld a, [hl+]
    ld d, h
    ld d, h
    ld c, a
    ld c, a
    ld c, a
    ld h, e
    rst $28
    xor $35
    ld b, d
    ld b, h
    ld c, a
    ld b, d
    ld d, c
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    and h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $33
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld c, h
    and e
    and h
    ccf
    ld b, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    rst $28
    xor $4a
    ld b, d
    ld h, e
    rst $30
    ldh a, [$ea]
    inc sp
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld c, h
    and e
    scf
    ld b, l
    ld b, d
    ld c, e
    ld e, [hl]
    ld h, d
    inc l
    rst $28
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld d, c
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    ld a, [$eff7]
    xor $2a
    ld d, h
    ld c, a
    ld c, a
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $33
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld c, h
    and e
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    rst $28
    xor $45
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld c, e
    ld b, [hl]
    ld b, l
    ld b, [hl]
    ld c, c
    ld a, $51
    ld b, d
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $33
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld c, h
    and e
    ld d, e
    ld c, h
    ld d, d
    rst $28
    xor $45
    ld d, d
    ld c, d
    ld a, $4b
    ld d, b
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $41
    ld b, [hl]
    ld c, a
    ld d, c
    ld d, [hl]
    ld h, d
    ld b, c
    ld c, h
    ld b, h
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    rst $28
    xor $43
    ld c, c
    ld a, $51
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    rst $30
    ldh a, [$ea]
    inc sp
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld c, h
    and e
    ld a, [hl+]
    ld d, h
    ld d, h
    ld c, a
    ld c, a
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $33
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld c, h
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, d
    ld h, h
    rst $38
    ldh a, [$ea]
    inc sp
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld c, h
    and e
    scf
    ld b, l
    ld b, d
    ld c, e
    ld e, [hl]
    rst $28
    xor $41
    ld b, [hl]
    ld b, d
    ld h, e
    rst $30
    ldh a, [$ea]
    inc sp
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld c, h
    and e
    scf
    ld b, l
    ld b, d
    ld c, e
    ld e, [hl]
    ld h, d
    ld d, h
    ld b, l
    ld a, $51
    rst $28
    xor $3f
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $33
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld c, h
    and e
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $46
    ld c, d
    ccf
    ld b, d
    ld b, b
    ld b, [hl]
    ld c, c
    ld b, d
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
    inc sp
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld c, h
    and e
    ld a, [hl+]
    ld d, h
    ld d, h
    ld c, a
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    ld h, e
    rst $28
    xor $30
    ld d, [hl]
    ld h, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, [$eff7]
    xor $3f
    ld d, d
    ld c, a
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld e, a
    ld e, a
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $33
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld c, h
    and e
    ld a, [hl-]
    ld a, $50
    ld h, d
    inc l
    ld h, d
    rst $28
    xor $41
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    ld b, d
    ld b, c
    ld h, h
    ld a, [$eff7]
    xor $33
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld c, h
    and e
    dec [hl]
    ld c, h
    ld e, [hl]
    rst $28
    xor $35
    ld c, h
    ld d, b
    ld a, $49
    ld b, [hl]
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    ld h, d
    inc l
    ld e, [hl]
    ld a, [$eff7]
    xor $2c
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    dec [hl]
    ld c, h
    ld d, b
    ld a, $49
    ld b, [hl]
    ld b, d
    rst $28
    xor $54
    ld a, $50
    ld h, d
    inc sp
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld c, h
    ld l, b
    ld a, [$eff7]
    xor $49
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    dec h
    ld d, d
    ld d, c
    rst $28
    xor $4d
    ld c, h
    ld c, h
    ld c, a
    ld h, d
    dec [hl]
    ld c, h
    ld d, b
    ld a, $49
    ld b, [hl]
    ld b, d
    ld h, d
    ld d, h
    ld a, $50
    ld a, [$eff7]
    xor $51
    ld c, h
    ld c, a
    ld c, d
    ld b, d
    ld c, e
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ccf
    ld d, [hl]
    rst $28
    xor $45
    ld d, d
    ld c, d
    ld a, $4b
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, e
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    inc sp
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld c, h
    rst $28
    xor $50
    ld b, l
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld c, l
    ld b, [hl]
    ld d, c
    ld b, [hl]
    ld b, d
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $3a
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
    sbc a
    and e
    ld a, [hl+]
    ld b, h
    ld b, h
    ld b, h
    ld c, a
    ld c, a
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld c, h
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, c
    ld b, [hl]
    ld d, b
    ld d, c
    ld d, d
    ld c, a
    ccf
    sbc h
    rst $28
    xor $46
    ld c, e
    ld b, h
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld d, c
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    jr z, jr_049_73ed

    ld d, c
    ld b, d
    ld c, a
    ld c, b
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $28
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld c, b
    and e
    dec [hl]
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld e, [hl]
    rst $28
    xor $51
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    ld a, $49
    ld c, c
    ld h, d
    inc l
    ld a, [$eff7]
    xor $4f
    ld b, d
    ld c, d
    ld b, d
    ld c, d
    ccf
    ld b, d
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $28
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld c, b
    and e
    inc l
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $42

jr_049_73ed:
    ld d, e
    ld b, d
    ld c, e
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld b, [hl]
    ld b, e
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $28
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld c, b
    and e
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    rst $28
    xor $4c
    ld c, a
    ld h, d
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld e, [hl]
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld e, a
    ld a, [$eff7]
    xor $28
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld c, b
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld b, c
    ld c, h
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld c, d
    ld b, d
    ld h, h
    ld a, [$eff7]
    xor $28
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld c, b
    and e
    daa
    ld b, [hl]
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $40
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, c
    ld b, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld d, [hl]
    ld a, [$eff7]
    xor $4a
    ld b, d
    ld h, h
    rst $28
    xor $ff
    ldh a, [$ea]
    jr z, jr_049_74c4

    ld d, c
    ld b, d
    ld c, a
    ld c, b
    and e
    scf
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld b, h
    ld c, h
    rst $28
    xor $3e
    ld d, h
    ld a, $56
    ld e, a
    ld a, [$eff7]
    xor $28
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld c, b
    and e
    inc l
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    rst $28
    xor $4f
    ld b, d
    ld d, b
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $28
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld c, b
    and e
    dec a
    ld d, a
    ld d, a
    ld d, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    jr z, @+$52

    ld d, c
    ld b, d
    ld c, a
    ld c, b
    and e
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]

jr_049_74c4:
    ld d, b
    rst $28
    xor $4b
    ld c, h
    ld h, d
    ld b, b
    ld b, l
    ld c, h
    ld b, [hl]
    ld b, b
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $28
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld c, b
    and e
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ld b, c
    ld b, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld d, [hl]
    ld b, d
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $28
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld c, b
    and e
    ld h, $4c
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    jr z, jr_049_755d

    ld d, c
    ld b, d
    ld c, a
    ld c, b
    and e
    ld a, [hl+]
    ld b, h
    ld b, h
    ld c, a
    ld c, a
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $28
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld c, b
    and e
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $3e
    ld b, h
    ld a, $46
    ld c, e
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $28
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld c, b
    and e
    ld b, c
    ld b, [hl]
    ld d, b
    ld d, c
    ld d, d
    ld c, a
    ccf
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $4a
    ld d, [hl]
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $28
    ld d, b
    ld d, c
    ld b, d
    ld c, a

jr_049_755d:
    ld c, b
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld a, $62
    rst $28
    xor $4b
    ld d, d
    ld b, [hl]
    ld d, b
    ld a, $4b
    ld b, b
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld a, $4a
    ld h, d
    ld b, h
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld c, [hl]
    ld d, d
    ld b, [hl]
    ld b, d
    ld d, c
    ld h, e
    rst $30
    ldh a, [$ea]
    jr z, jr_049_75eb

    ld d, c
    ld b, d
    ld c, a
    ld c, b
    and e
    ld a, [hl+]
    ld b, h
    ld b, h
    ld b, h
    ld c, a
    ld c, a
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $3a
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    ld d, h
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld a, [$eff7]
    xor $4a
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $28
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld c, b
    and e
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $27
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    ld b, d
    ld b, c
    ld h, h
    ld h, e
    ld h, d
    ld [hl], $4c
    ld c, d
    ld b, d

jr_049_75eb:
    ld b, l
    ld c, h
    ld d, h
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld c, b
    ld c, e
    ld b, d
    ld d, h
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $49
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld b, c
    ld c, a
    ld b, d
    ld a, $4a
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $28
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld c, b
    and e
    ld b, d
    ld d, e
    ld b, d
    ld c, e
    ld d, c
    ld d, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld h, d
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, h
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
    ld e, a
    rst $30
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    jr z, @+$55

    ld b, d
    ld c, e
    ld h, d
    ld b, [hl]
    ld b, e
    rst $28
    xor $54
    ld b, d
    ld l, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld a, $62
    ld b, c
    ld c, a
    ld b, d
    ld a, $4a
    ld e, [hl]
    ld a, [$eff7]
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    ld b, [hl]
    ld d, c
    rst $28
    xor $41
    ld c, h
    ld b, d
    ld d, b
    ld c, e
    ld h, a
    ld h, d
    ld c, d
    ld a, $51
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $3e
    ld d, b
    ld h, d
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld a, $50
    rst $28
    xor $f6
    ld l, b
    ld h, d
    ld d, c
    ld c, a
    ld d, [hl]
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $45
    ld a, $4f
    ld b, c
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    cpl
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ld b, h
    ld c, h
    rst $28
    xor $3f
    ld a, $40
    ld c, b
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc h
    ld d, c
    ld h, d
    ld c, c
    ld a, $50
    ld d, c
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    rst $28
    xor $40
    ld a, $4a
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    jr nc, jr_049_7734

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $30
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    or $62
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $45
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, l
    ld a, $4b
    ld b, [hl]
    ld c, h
    ld c, e
    ld d, b
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
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
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    rst $28
    xor $54
    ld b, l
    ld c, h
    ld h, d
    inc l
    ld h, d
    ld a, $4a
    ld h, h
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    dec hl

jr_049_7734:
    ld a, $62
    ld b, l
    ld a, $62
    ld b, l
    ld a, $63
    ld h, e
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld a, [$eff7]
    xor $46
    ld c, e
    ld d, c
    ld b, d
    ld c, e
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld d, b
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
    ld l, $46
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    rst $28
    xor $51
    ld b, l
    ld b, d
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
    ld d, b
    ld e, [hl]
    ld h, d
    or [hl]
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld d, b
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    jr nc, jr_049_77ed

    ld c, a
    ld d, d
    ld b, c
    ld c, a
    ld a, $3e
    ld d, b
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $30
    ld b, [hl]
    ld c, a
    ld d, d
    ld b, c
    ld c, h
    ld c, a
    ld a, $3e
    ld d, b
    and e
    rst $28
    xor $26
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld h, e
    ld a, [$eff7]
    xor $30
    ld b, [hl]
    ld c, a
    ld d, d
    ld b, c
    ld c, h
    ld c, a
    ld a, $3e
    ld d, b
    and e
    inc l
    ld h, [hl]
    ld c, c
    rst $28
    xor $50
    ld b, l
    ld c, h
    ld d, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, l
    ld d, [hl]
    ld h, d
    inc l
    ld l, d

jr_049_77ed:
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
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
    xor $42
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld c, c
    ld c, h
    ld c, a
    ld b, c
    ld d, b
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
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    rst $28
    xor $4a
    ld d, [hl]
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    ld h, h
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, e
    ld c, h
    ld c, h
    ld c, c
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    rst $28
    xor $51
    ld b, l
    ld b, d
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
    ld d, b
    ld e, [hl]
    ld h, d
    or [hl]
    ld h, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld d, b
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    jr nc, @+$48

    ld c, a
    ld d, d
    ld b, c
    ld c, a
    ld a, $3e
    ld d, b
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $30
    ld b, [hl]
    ld c, a
    ld d, d
    ld b, c
    ld c, a
    ld a, $3e
    ld d, b
    and e
    ld h, $4c
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $30
    ld b, [hl]
    ld c, a
    ld d, d
    ld b, c
    ld c, a
    ld a, $3e
    ld d, b
    and e
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    rst $28
    xor $50
    ld b, l
    ld c, h
    ld d, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, l
    ld d, [hl]
    ld h, d
    inc l
    ld l, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    rst $28
    xor $42
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld c, c
    ld c, h
    ld c, a
    ld b, c
    ld d, b
    ld h, e
    rst $30
    ldh a, [$ea]
    jr nc, jr_049_792f

    ld c, a
    ld d, d
    ld b, c
    ld c, a
    ld a, $3e
    ld d, b
    and e
    dec hl
    ld a, $62
    ld b, l
    ld a, $62
    rst $28
    xor $45
    ld a, $63
    ld a, [$eff7]
    xor $30
    ld b, [hl]
    ld c, a
    ld d, d
    ld b, c
    ld c, a
    ld a, $3e
    ld d, b
    and e
    jr nc, jr_049_7958

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    rst $28
    xor $30
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    or $62
    ld a, [$eff7]
    xor $b6
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, l
    ld a, $4b
    ld d, [hl]
    ld e, [hl]
    rst $28
    xor $fa
    rst $30

jr_049_792f:
    rst $28
    xor $30
    ld b, [hl]
    ld c, a
    ld d, d
    ld b, c
    ld c, a
    ld a, $3e
    ld d, b
    and e
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $41
    ld b, [hl]
    ld d, b
    ld d, c
    ld d, d
    ld c, a
    ccf
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld a, [$eff7]
    xor $50
    ld d, d
    ld b, b
    ld b, l

jr_049_7958:
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, [hl]
    ld h, d
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    ld h, e
    rst $30
    ldh a, [$ea]
    jr nc, jr_049_79b6

    ld c, a
    ld d, d
    ld b, c
    ld c, a
    ld a, $3e
    ld d, b
    and e
    dec hl
    ld c, h
    ld d, h
    ld e, a
    ld e, a
    rst $28
    xor $40
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    inc l
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld a, [$eff7]
    xor $41
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    ld b, d
    ld b, c
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $30
    ld b, [hl]
    ld c, a
    ld d, d
    ld b, c
    ld c, a
    ld a, $3e
    ld d, b
    and e
    inc l
    ld d, c
    rst $28
    xor $40
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ccf
    ld b, d

jr_049_79b6:
    ld e, a
    ld a, [$eff7]
    xor $30
    ld b, [hl]
    ld c, a
    ld d, d
    ld b, c
    ld c, a
    ld a, $3e
    ld d, b
    and e
    inc h
    ld b, l
    ld h, d
    ld b, l
    ld a, $5e
    rst $28
    xor $2c
    ld d, c
    ld h, d
    ld c, d
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld a, $62
    ld a, [$eff7]
    xor $41
    ld c, a
    ld b, d
    ld a, $4a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $30
    ld b, [hl]
    ld c, a
    ld d, d
    ld b, c
    ld c, a
    ld a, $3e
    ld d, b
    and e
    ld sp, $544c
    ld e, [hl]
    rst $28
    xor $2c
    ld h, d
    ld d, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld d, b
    ld d, c
    ld a, $4b
    ld b, c
    ld h, e
    rst $30
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $4f
    ld b, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld a, $4a
    ld b, d
    ld h, d
    ld a, [$eff7]
    xor $50
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld e, a
    ld h, d
    ld sp, $544c
    ld e, [hl]
    ld h, d
    rst $28
    xor $49
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, d
    ld c, c
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $54
    ld c, h
    ld c, a
    ld d, c
    ld b, l
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    jr nc, jr_049_7ac3

    ld b, c
    ld c, h
    ld d, d
    ld e, a
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    rst $28
    xor $4a
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld e, a
    ld h, d
    rst $38
    ldh a, [$ea]
    jr nc, jr_049_7ae3

    ld b, c
    ld c, h
    ld d, d
    and e
    dec hl
    ld c, d
    ld h, h
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    rst $28
    xor $3e
    ld c, c
    ld c, a
    ld b, d
    ld a, $41
    ld d, [hl]
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld c, d
    ld d, [hl]
    ld a, [$eff7]
    xor $4b
    ld a, $4a
    ld b, d
    ld e, [hl]
    ld h, d
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, h
    rst $28
    xor $ff
    ldh a, [$ea]

jr_049_7ac3:
    jr nc, @+$54

    ld b, c
    ld c, h
    ld d, d
    and e
    add hl, hl
    ld b, [hl]
    ld c, e
    ld b, d
    ld e, a
    rst $28
    xor $31
    ld c, h
    ld d, h
    ld e, [hl]
    ld a, [$eff7]
    xor $30
    ld d, d
    ld b, c
    ld c, h
    ld d, d
    and e
    ld a, $4f
    ld b, d
    ld h, d
    ld d, [hl]

jr_049_7ae3:
    ld c, h
    ld d, d
    rst $28
    xor $4d
    ld c, a
    ld b, d
    ld c, l
    ld a, $4f
    ld b, d
    ld b, c
    ld h, h
    rst $38
    ldh a, [$ea]
    jr nc, @+$54

    ld b, c
    ld c, h
    ld d, d
    and e
    dec hl
    ld d, d
    ld b, l
    ld h, h
    ld h, d
    daa
    ld b, [hl]
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $4d
    ld c, a
    ld b, d
    ld c, l
    ld a, $4f
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $40
    ld c, h
    ld b, e
    ld b, e
    ld b, [hl]
    ld c, e
    ld d, b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $42
    ld d, c
    ld b, d
    ld c, a
    ld c, e
    ld a, $49
    ld h, d
    ld d, b
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld h, h
    rst $38
    ldh a, [$ea]
    jr nc, jr_049_7b8e

    ld b, c
    ld c, h
    ld d, d
    and e
    add hl, hl
    ld b, [hl]
    ld c, e
    ld b, d
    ld e, a
    rst $28
    xor $2f
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ccf
    ld b, d
    ld b, h
    ld b, [hl]
    ld c, e
    ld e, a
    rst $30
    ldh a, [$ea]
    jr nc, jr_049_7ba9

    ld b, c
    ld c, h
    ld d, d
    and e
    inc h
    ld c, e
    ld c, e
    ld c, h
    ld d, [hl]
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $54
    ld c, h
    ld c, a
    ld d, c
    ld b, l
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $2c
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, d
    ld d, l
    ld d, c
    ld b, d
    ld c, a
    ld c, d
    ld b, [hl]
    ld c, e
    ld a, $51
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d

jr_049_7b8e:
    ld e, a
    rst $30
    ldh a, [$ea]
    jr nc, jr_049_7be6

    ld b, c
    ld c, h
    ld d, d
    and e
    inc l
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ccf
    ld b, d
    ld a, $51
    ld b, d
    ld c, e
    rst $28
    xor $3f
    ld d, [hl]
    ld h, d

jr_049_7ba9:
    ld d, h
    ld c, h
    ld c, a
    ld d, c
    ld b, l
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $46
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld a, $4b
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $30
    ld d, d
    ld b, c
    ld c, h
    ld d, d
    and e
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld a, $4b
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld d, c
    ld b, l
    ld c, c

jr_049_7be6:
    ld b, d
    ld d, b
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    ld h, h
    rst $30
    ldh a, [$eb]
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    ld a, [hl-]
    ld b, d
    ld c, c
    ld c, c
    ld e, [hl]
    rst $28
    xor $50
    ld b, l
    ld a, $49
    ld c, c
    ld h, d
    ld d, h
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, h
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
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
