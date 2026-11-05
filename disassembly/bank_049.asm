; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $049", ROMX[$4000], BANK[$49]

    db $49 ; Bank number

    ; Cross-bank dispatch table (162 entries)
    ; Called via: ld hl, $49XX / rst $10
    dw LoadB49_4145                  ; Entry 0
    dw TextRunB49_4162               ; Entry 1
    dw TextShowRefreshB49_417f       ; Entry 2
    dw $4009                          ; Entry 3 — mode 0 -> table $4009 (mode list $4007)
    dw TextStr_49_419c               ; Entry 4 — [table $4009]; text $0512 "Milayou:Yes, it feels like the fi…"
    dw TextStr_49_4260               ; Entry 5 — text $0513 "Milayou:Yes, it was truly a fun d…"
    dw TextStr_49_42cb               ; Entry 6 — text $0514 "Milayou:Good night [HERO]! Sweet …"
    dw TextStr_49_42f7               ; Entry 7 — text $0515 "Milayou:Good night [HERO]! Go to …"
    dw TextStr_49_4322               ; Entry 8 — text $0516 "Milayou:...Oh? ...[HERO]!"
    dw TextStr_49_433a               ; Entry 9 — text $0517 "Milayou:What's in your pocket?"
    dw TextStr_49_435b               ; Entry 10 — text $0518 "Watabou:Gimme that meat."
    dw TextStr_49_4377               ; Entry 11 — text $0519 "Watabou:Gimme the meat and I'll b…"
    dw TextStr_49_43ac               ; Entry 12 — text $051A "[HERO] checked out the bookshelf.…"
    dw TextStr_49_43fa               ; Entry 13 — text $051B "[SOUND 60][HERO] looked in the dr…"
    dw TextStr_49_4430               ; Entry 14 — text $051C "*:There are cliffs that we can ju…"
    dw TextStr_49_446e               ; Entry 15 — text $051D "Watabou:Good job finding the invi…"
    dw TextStr_49_44b1               ; Entry 16 — text $051E "*:Wow! Yummy meat! Yum!"
    dw TextStr_49_44cc               ; Entry 17 — text $051F "*:Wow, yummy meat comming this wa…"
    dw TextStr_49_44fe               ; Entry 18 — text $0520 "*:Wow! I'll do anything for the m…"
    dw TextStr_49_452b               ; Entry 19 — text $0521 "Watabou:It seems you had a hard t…"
    dw TextStr_49_4572               ; Entry 20 — text $0522 "[HERO] checked out a treasure che…"
    dw TextStr_49_4603               ; Entry 21 — text $0523 "[HERO] looked into a jar. There w…"
    dw TextStr_49_4653               ; Entry 22 — text $0524 "*:......"
    dw TextStr_49_4660               ; Entry 23 — text $0525 "*:So,yoooou saaaw my face...!!"
    dw TextStr_49_4682               ; Entry 24 — text $0526 "*:It's yoooou agaaaain!"
    dw TextStr_49_469c               ; Entry 25 — text $0527 "*:Yoooou win...!!"
    dw TextStr_49_46b2               ; Entry 26 — text $0528 "Watabou:Good work! So,let's goooo…"
    dw TextStr_49_46e4               ; Entry 27 — text $0529 "*:Squeak squeak! Strike!"
    dw TextStr_49_4700               ; Entry 28 — text $052A "*:Good lord, You're good!"
    dw TextStr_49_471c               ; Entry 29 — text $052B "Watabou:Good work reading SkyDrag…"
    dw TextStr_49_47a5               ; Entry 30 — text $052C "*:Look at my cool steps!"
    dw TextStr_49_47c1               ; Entry 31 — text $052D "*:Why don't you dance with me?"
    dw TextStr_49_47e2               ; Entry 32 — text $052E "*:You came again to dance with me…"
    dw TextStr_49_481d               ; Entry 33 — text $052F "*:You're a great dancer!"
    dw TextStr_49_4838               ; Entry 34 — text $0530 "*:Did you enjoy dancing? Well, le…"
    dw TextStr_49_486d               ; Entry 35 — text $0531 "There is a voice coming from out …"
    dw TextStr_49_48a3               ; Entry 36 — text $0532 "*:Hello...the traveler over there…"
    dw TextStr_49_4957               ; Entry 37 — text $0533 "*:Now, wait there."
    dw TextStr_49_496c               ; Entry 38 — text $0534 "*:Then, would you like me to send…"
    dw TextStr_49_49b2               ; Entry 39 — text $0535 "*:It was actually a monster that …"
    dw TextStr_49_4a29               ; Entry 40 — text $0536 "*:Was it this meat that fell in t…"
    dw TextStr_49_4a5d               ; Entry 41 — text $0537 "*:...you're a liar. *:I'll give y…"
    dw TextStr_49_4aa7               ; Entry 42 — text $0538 "*:I see. Now, wait a moment for m…"
    dw TextStr_49_4ace               ; Entry 43 — text $0539 "*:Now, is this the old guy who fe…"
    dw TextStr_49_4b08               ; Entry 44 — text $053A "*:...you're a liar. *:I'll give y…"
    dw TextStr_49_4b52               ; Entry 45 — text $053B "*:I see. Now,wait a minute for me."
    dw TextStr_49_4b78               ; Entry 46 — text $053C "*:Now is this the [INS 00], the m…"
    dw TextStr_49_4bba               ; Entry 47 — text $053D "*:I don't understand you... *:I'l…"
    dw TextStr_49_4c3d               ; Entry 48 — text $053E "*:You're honest. I'll give you ba…"
    dw TextStr_49_4cee               ; Entry 49 — text $053F "*:You did well. Please go back to…"
    dw TextStr_49_4d2b               ; Entry 50 — text $0540 "*:Oh, it's you again. Would you l…"
    dw TextStr_49_4d75               ; Entry 51 — text $0541 "*:Take your time."
    dw TextStr_49_4d8b               ; Entry 52 — text $0542 "*:Now so long..."
    dw TextStr_49_4da0               ; Entry 53 — text $0543 "*:Comrade! Now is the time for us…"
    dw TextStr_49_4e49               ; Entry 54 — text $0544 "*:I'll promise you, comrade! *:A …"
    dw TextStr_49_4eb9               ; Entry 55 — text $0545 "*:Hm!? I don't know why but I fee…"
    dw TextStr_49_4f36               ; Entry 56 — text $0546 "*:Sirloin steak is totally yummy!…"
    dw TextStr_49_4fc7               ; Entry 57 — text $0547 "*:I demand one sirloin steak a da…"
    dw TextStr_49_4ff3               ; Entry 58 — text $0548 "*:Hee hee hee. I love burning vil…"
    dw TextStr_49_5038               ; Entry 59 — text $0549 "*:Hee hee hee. Burn'em burn'em al…"
    dw TextStr_49_507d               ; Entry 60 — text $054A "*:You are so boring! *:You wanna …"
    dw TextStr_49_50b9               ; Entry 61 — text $054B "*:You again! You really wanna be …"
    dw TextStr_49_50f1               ; Entry 62 — text $054C "*:Burn me, boil me! Whatever! Ahr…"
    dw TextStr_49_511d               ; Entry 63 — text $054D "Watabou:Ouch! I'm gonna put out t…"
    dw TextStr_49_518e               ; Entry 64 — text $054E "[HERO] read the posting. :Once yo…"
    dw TextStr_49_520b               ; Entry 65 — text $054F "[HERO] read the posting. :Wanted!…"
    dw TextStr_49_5251               ; Entry 66 — text $0550 "*:Hi! We go sip. Sip here!"
    dw TextStr_49_526f               ; Entry 67 — text $0551 "*:Boss! You can feel like a king …"
    dw TextStr_49_52ab               ; Entry 68 — text $0552 "*:Please let the sweet aroma rela…"
    dw TextStr_49_52db               ; Entry 69 — text $0553 "*:You're really too much. But the…"
    dw TextStr_49_5313               ; Entry 70 — text $0554 "*:Boss! You are so strong! But th…"
    dw TextStr_49_534d               ; Entry 71 — text $0555 "*:I see you have lots of special …"
    dw TextStr_49_5397               ; Entry 72 — text $0556 "*:Mmm... sip sip! Here I come!"
    dw TextStr_49_53b9               ; Entry 73 — text $0557 "*:Wow! You really impressed me!"
    dw TextStr_49_53dc               ; Entry 74 — text $0558 "Watabou:Had a good time!? We've g…"
    dw TextStr_49_5415               ; Entry 75 — text $0559 "*:Now, sleep tight on my arms...!"
    dw TextStr_49_543a               ; Entry 76 — text $055A "*:Oh, you were great. Giggle..."
    dw TextStr_49_545d               ; Entry 77 — text $055B "Watabou:Had a good time!? We got …"
    dw TextStr_49_5494               ; Entry 78 — text $055C "*:I'll let you sleep with my Slee…"
    dw TextStr_49_54da               ; Entry 79 — text $055D "*:You're strong! If this is a dre…"
    dw TextStr_49_5526               ; Entry 80 — text $055E "Watabou:Had a good time!? We got …"
    dw TextStr_49_555d               ; Entry 81 — text $055F "Watabou didn't reply."
    dw TextStr_49_5574               ; Entry 82 — text $0560 "It was a Watabou doll!"
    dw TextStr_49_558d               ; Entry 83 — text $0561 "[HERO] checked out a treasure che…"
    dw TextStr_49_560a               ; Entry 84 — text $0562 "Mimic continues to stick his tong…"
    dw TextStr_49_563a               ; Entry 85 — text $0563 "*:Bleat bleat. I cannot believe t…"
    dw TextStr_49_56ca               ; Entry 86 — text $0564 "*:Bleat bleat. Welcome to a dead …"
    dw TextStr_49_56ff               ; Entry 87 — text $0565 "*:Bleat bleat. I never imagined s…"
    dw TextStr_49_5744               ; Entry 88 — text $0566 "Watabou:You think the doll looks …"
    dw TextStr_49_57ba               ; Entry 89 — text $0567 "*:You abused monsters cruelly and…"
    dw TextStr_49_584e               ; Entry 90 — text $0568 "*:If you cannot learn by listenin…"
    dw TextStr_49_58b0               ; Entry 91 — text $0569 "*:You recognize your sin, right? …"
    dw TextStr_49_59c8               ; Entry 92 — text $056A "*:If you cannot learn by listenin…"
    dw TextStr_49_5a2a               ; Entry 93 — text $056B "*:Now we're holding a public exec…"
    dw TextStr_49_5a8b               ; Entry 94 — text $056C "*:What? You have something to say…"
    dw TextStr_49_5ac5               ; Entry 95 — text $056D "*:None of your cheek! If you don'…"
    dw TextStr_49_5b3c               ; Entry 96 — text $056E "*:Then die!"
    dw TextStr_49_5b4c               ; Entry 97 — text $056F "*:You want to have additional sin…"
    dw TextStr_49_5b73               ; Entry 98 — text $0570 "Watabou:[HERO]'s monsters trust y…"
    dw TextStr_49_5bd8               ; Entry 99 — text $0571 "[HERO] touched the blade of the g…"
    dw TextStr_49_5c2a               ; Entry 100 — text $0572 "[HERO] touched the blade of the g…"
    dw TextStr_49_5caa               ; Entry 101 — text $0573 "*:Aaaarrrggh! Gwrrrr... *:Gwrrggg…"
    dw TextStr_49_5cd7               ; Entry 102 — text $0574 "*:Gwwrrggg..."
    dw TextStr_49_5ce9               ; Entry 103 — text $0575 "Watabou:[HERO]! Let's go."
    dw TextStr_49_5d00               ; Entry 104 — text $0576 "*:Aaarrrggh... *:I can't stand it…"
    dw TextStr_49_5d6c               ; Entry 105 — text $0577 "*:Look... this sword... *:It's th…"
    dw TextStr_49_5ee8               ; Entry 106 — text $0578 "*:So long! The Orochi won't troub…"
    dw TextStr_49_5f58               ; Entry 107 — text $0579 "*:What? You want to know why I am…"
    dw TextStr_49_6176               ; Entry 108 — text $057A "Watabou:Oh, you were saved by som…"
    dw TextStr_49_61c9               ; Entry 109 — text $057B "*:Welcome [HERO]! *:I'm the King …"
    dw TextStr_49_62fe               ; Entry 110 — text $057C "DracoLord:Great, you agreed! Now …"
    dw TextStr_49_63e6               ; Entry 111 — text $057D "DracoLord:What's wrong with it. I…"
    dw TextStr_49_645f               ; Entry 112 — text $057E "DracoLord:You say you're going to…"
    dw TextStr_49_64c2               ; Entry 113 — text $057F "DracoLord:You came back? You neve…"
    dw TextStr_49_6568               ; Entry 114 — text $0580 "DracoLord:You beat me. You're rea…"
    dw TextStr_49_659f               ; Entry 115 — text $0581 "Watabou:One down! [HERO]! Let's g…"
    dw TextStr_49_65cb               ; Entry 116 — text $0582 "*:Who is it? *:Disturbing my rest…"
    dw TextStr_49_6649               ; Entry 117 — text $0583 "Hargon:Then it is unforgivable! H…"
    dw TextStr_49_66a2               ; Entry 118 — text $0584 "Hargon:Then you should know, Harg…"
    dw TextStr_49_66fb               ; Entry 119 — text $0585 "Hargon:You again! Hargon:Insolant…"
    dw TextStr_49_677b               ; Entry 120 — text $0586 "Hargon:To my vex... Hargon:the gr…"
    dw TextStr_49_687e               ; Entry 121 — text $0587 "Watabou:Hm? I still smell monster…"
    dw TextStr_49_68e2               ; Entry 122 — text $0588 "*:...I...am... the...god...of... …"
    dw TextStr_49_6961               ; Entry 123 — text $0589 "Sidoh:...I... destroy...!!"
    dw TextStr_49_697f               ; Entry 124 — text $058A "Sidoh:............"
    dw TextStr_49_6996               ; Entry 125 — text $058B "Watabou:There was a monster still…"
    dw TextStr_49_69e2               ; Entry 126 — text $058C "*:At last you came here, pathetic…"
    dw TextStr_49_6b13               ; Entry 127 — text $058D "Baramos:Fool! You still disobey m…"
    dw TextStr_49_6c07               ; Entry 128 — text $058E "Baramos:Arhg... y..you... Baramos…"
    dw TextStr_49_6c40               ; Entry 129 — text $058F "Watabou: Excellent [HERO]. Leeet'…"
    dw TextStr_49_6c6e               ; Entry 130 — text $0590 "*:Welcome to my altar of sacrific…"
    dw TextStr_49_6dc6               ; Entry 131 — text $0591 "Zoma:Hmm, you seem to never learn…"
    dw TextStr_49_6e75               ; Entry 132 — text $0592 "Zoma:...What is your name... son?…"
    dw TextStr_49_6f7f               ; Entry 133 — text $0593 "Watabou:There're lots of strong m…"
    dw TextStr_49_6fbd               ; Entry 134 — text $0594 "*:Gwwrrrr...! Who are you? *:I am…"
    dw TextStr_49_70c7               ; Entry 135 — text $0595 "Pizzaro:Gwwrrr! Regret showing yo…"
    dw TextStr_49_7110               ; Entry 136 — text $0596 "Pizzaro:Then, I will tell you! Gw…"
    dw TextStr_49_71ad               ; Entry 137 — text $0597 "Pizzaro:Gwwrrr...! Pizzaro:You wa…"
    dw TextStr_49_71e1               ; Entry 138 — text $0598 "Pizzaro:Then, die!"
    dw TextStr_49_71f7               ; Entry 139 — text $0599 "Pizzaro:Then, what brought you he…"
    dw TextStr_49_723a               ; Entry 140 — text $059A "Pizzaro:Gwwrr...! My body is burn…"
    dw TextStr_49_72b1               ; Entry 141 — text $059B "Watabou:Rosalie was Pizzaro's lov…"
    dw TextStr_49_735e               ; Entry 142 — text $059C "*:Ggggrrr... *:Who is disturb- in…"
    dw TextStr_49_7471               ; Entry 143 — text $059D "Esterk:Then go away. Esterk:I wil…"
    dw TextStr_49_74b5               ; Entry 144 — text $059E "Esterk:There is no choice. Esterk…"
    dw TextStr_49_750a               ; Entry 145 — text $059F "Esterk:Gggrrr... Esterk:You again…"
    dw TextStr_49_7598               ; Entry 146 — text $05A0 "Esterk:Ggggrrr... What's wrong wi…"
    dw TextStr_49_7640               ; Entry 147 — text $05A1 "Watabou:Even if we're in a dream,…"
    dw TextStr_49_76c0               ; Entry 148 — text $05A2 "*:At last, you came here. *:The M…"
    dw TextStr_49_7730               ; Entry 149 — text $05A3 "*:Ha ha ha!! You have good intent…"
    dw TextStr_49_780f               ; Entry 150 — text $05A4 "*:You don't know my name? You foo…"
    dw TextStr_49_78e6               ; Entry 151 — text $05A5 "Mirudraas:Ha ha ha! Mirudraas:Mon…"
    dw TextStr_49_796d               ; Entry 152 — text $05A6 "Mirudraas:How.. could I be defeat…"
    dw TextStr_49_7a09               ; Entry 153 — text $05A7 "Watabou:You really became strong.…"
    dw TextStr_49_7a47               ; Entry 154 — text $05A8 "*:Welcome, you worthless... *:I a…"
    dw TextStr_49_7a8e               ; Entry 155 — text $05A9 "Mudou:Hm? You already know my nam…"
    dw TextStr_49_7ac2               ; Entry 156 — text $05AA "Mudou:Fine. Now, Mudou:are you pr…"
    dw TextStr_49_7af2               ; Entry 157 — text $05AB "Mudou:Huh? Did you prepare your c…"
    dw TextStr_49_7b39               ; Entry 158 — text $05AC "Mudou:Fine. Let's begin."
    dw TextStr_49_7b54               ; Entry 159 — text $05AD "Mudou:Annoying worthless things. …"
    dw TextStr_49_7b91               ; Entry 160 — text $05AE "Mudou:I was beaten by worthless..…"
    dw TextStr_49_7bef               ; Entry 161 — text $05AF "Watabou:Well, shall we go back?"

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


; [S166] copy a text of this bank (RunTextHandler); ids past the bank's range go to its overflow bank (TEXT_SYSTEM "Text id resolution")
TextRunB49_4162:
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


; [S166] show a text (entry 0) then RequestScreenUpdate
TextShowRefreshB49_417f:
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


; --- BEGIN re-sectioned text run (bank $49: $419c-$7c13) ---
; DTE-encoded dialogue strings, one label per text id (text_id_map.json).
; Labels/comments only; bytes are byte-identical to the original ROM.
TextStr_49_419c:           ; id $0512
    ; "Milayou:Yes, it feels like the / fight was real. / Milayou:But, it could have only / been a dream. You were in my / dream. / Milayou:Now [HE..."
    db $eb, $30, $46, $49, $3e, $56, $4c, $52, $a3, $3c, $42, $50, $5e, $62, $46, $51
    db $ef, $ee, $43, $42, $42, $49, $50, $62, $49, $46, $48, $42, $62, $51, $45, $42
    db $fa, $f7, $ef, $ee, $43, $46, $44, $45, $51, $62, $54, $3e, $50, $62, $4f, $42
    db $3e, $49, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $30, $46, $49, $3e, $56, $4c, $52
    db $a3, $25, $52, $51, $5e, $62, $46, $51, $ef, $ee, $40, $4c, $52, $49, $41, $62
    db $45, $3e, $53, $42, $62, $4c, $4b, $49, $56, $fa, $f7, $ef, $ee, $3f, $42, $42
    db $4b, $62, $3e, $62, $41, $4f, $42, $3e, $4a, $5f, $ef, $ee, $3c, $4c, $52, $62
    db $54, $42, $4f, $42, $62, $46, $4b, $62, $4a, $56, $fa, $f7, $ef, $ee, $41, $4f
    db $42, $3e, $4a, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $30, $46, $49, $3e, $56, $4c
    db $52, $a3, $31, $4c, $54, $62, $f6, $5e, $ef, $ee, $49, $42, $51, $68, $62, $44
    db $4c, $62, $3f, $3e, $40, $48, $62, $51, $4c, $fa, $f7, $ef, $ee, $50, $49, $42
    db $42, $4d, $5f, $ef, $ee, $36, $54, $42, $42, $51, $62, $41, $4f, $42, $3e, $4a
    db $50, $63, $f7, $f0
TextStr_49_4260:           ; id $0513
    ; "Milayou:Yes, it was truly a fun / dream! / Milayou:Now [HERO], Let's go back to / sleep. Sweet dreams!"
    db $eb, $30, $46, $49, $3e, $56, $4c, $52, $a3, $3c, $42, $50, $5e, $62, $46, $51
    db $ef, $ee, $54, $3e, $50, $62, $51, $4f, $52, $49, $56, $62, $3e, $62, $43, $52
    db $4b, $fa, $f7, $ef, $ee, $41, $4f, $42, $3e, $4a, $63, $ef, $ee, $fa, $f7, $ef
    db $ee, $30, $46, $49, $3e, $56, $4c, $52, $a3, $31, $4c, $54, $62, $f6, $5e, $ef
    db $ee, $2f, $42, $51, $68, $62, $44, $4c, $62, $3f, $3e, $40, $48, $62, $51, $4c
    db $fa, $f7, $ef, $ee, $50, $49, $42, $42, $4d, $5f, $ef, $ee, $36, $54, $42, $42
    db $51, $62, $41, $4f, $42, $3e, $4a, $50, $63, $f7, $f0
TextStr_49_42cb:           ; id $0514
    ; "Milayou:Good night [HERO]! / Sweet dreams!"
    db $eb, $30, $46, $49, $3e, $56, $4c, $52, $a3, $2a, $4c, $4c, $41, $62, $4b, $46
    db $44, $45, $51, $ef, $ee, $f6, $63, $fa, $f7, $ef, $ee, $36, $54, $42, $42, $51
    db $62, $41, $4f, $42, $3e, $4a, $50, $63, $ef, $ee, $f7, $f0
TextStr_49_42f7:           ; id $0515
    ; "Milayou:Good night [HERO]! Go to / sleep."
    db $eb, $30, $46, $49, $3e, $56, $4c, $52, $a3, $2a, $4c, $4c, $41, $62, $4b, $46
    db $44, $45, $51, $ef, $ee, $f6, $63, $62, $2a, $4c, $62, $51, $4c, $fa, $f7, $ef
    db $ee, $50, $49, $42, $42, $4d, $5f, $ef, $ee, $f7, $f0
TextStr_49_4322:           ; id $0516
    ; "Milayou:...Oh? ...[HERO]!"
    db $eb, $30, $46, $49, $3e, $56, $4c, $52, $a3, $5f, $5f, $5f, $32, $45, $64, $ef
    db $ee, $5f, $5f, $5f, $f6, $63, $f7, $f0
TextStr_49_433a:           ; id $0517
    ; "Milayou:What's in your pocket?"
    db $eb, $30, $46, $49, $3e, $56, $4c, $52, $a3, $3a, $45, $3e, $51, $68, $62, $46
    db $4b, $ef, $ee, $56, $4c, $52, $4f, $62, $4d, $4c, $40, $48, $42, $51, $64, $f7
    db $f0
TextStr_49_435b:           ; id $0518
    ; "Watabou:Gimme that meat."
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $2a, $46, $4a, $4a, $42, $ef, $ee
    db $51, $45, $3e, $51, $62, $4a, $42, $3e, $51, $5f, $f7, $f0
TextStr_49_4377:           ; id $0519
    ; "Watabou:Gimme the meat and I'll / be your pal!!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $2a, $46, $4a, $4a, $42, $ef, $ee
    db $51, $45, $42, $62, $4a, $42, $3e, $51, $62, $3e, $4b, $41, $62, $2c, $66, $49
    db $fa, $f7, $ef, $ee, $3f, $42, $62, $56, $4c, $52, $4f, $62, $4d, $3e, $49, $63
    db $63, $ef, $ee, $f7, $f0
TextStr_49_43ac:           ; id $051A
    ; "[HERO] checked out the bookshelf. / :Encyclopedia of Monsters / Author...[HERO]!"
    db $f6, $62, $40, $45, $42, $40, $48, $42, $41, $62, $4c, $52, $51, $ef, $ee, $51
    db $45, $42, $62, $3f, $4c, $4c, $48, $50, $45, $42, $49, $43, $5f, $fa, $f7, $ef
    db $ee, $a3, $28, $4b, $40, $56, $40, $49, $4c, $4d, $42, $41, $46, $3e, $62, $4c
    db $43, $ef, $ee, $30, $4c, $4b, $50, $51, $42, $4f, $50, $fa, $f7, $ef, $ee, $24
    db $52, $51, $45, $4c, $4f, $5f, $5f, $5f, $f6, $63, $ef, $ee, $f7, $f0
TextStr_49_43fa:           ; id $051B
    ; "[SOUND 60][HERO] looked in the dresser. / And didn't find much."
    db $e9, $60, $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $46, $4b, $ef, $ee, $51
    db $45, $42, $62, $41, $4f, $42, $50, $50, $42, $4f, $5f, $fa, $f7, $ef, $ee, $24
    db $4b, $41, $62, $41, $46, $41, $4b, $67, $62, $43, $46, $4b, $41, $ef, $ee, $4a
    db $52, $40, $45, $5f, $f7, $f0
TextStr_49_4430:           ; id $051C
    ; "*:There are cliffs that we can jump / off if we're brave!"
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $62, $3e, $4f, $42, $62, $40, $49, $46
    db $43, $43, $50, $ef, $ee, $51, $45, $3e, $51, $62, $54, $42, $62, $40, $3e, $4b
    db $62, $47, $52, $4a, $4d, $fa, $f7, $ef, $ee, $4c, $43, $43, $62, $46, $43, $62
    db $54, $42, $69, $42, $ef, $ee, $3f, $4f, $3e, $53, $42, $63, $f7, $f0
TextStr_49_446e:           ; id $051D
    ; "Watabou:Good job finding the / invisible floor! Let's go back!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $2a, $4c, $4c, $41, $62, $47, $4c
    db $3f, $ef, $ee, $43, $46, $4b, $41, $46, $4b, $44, $62, $51, $45, $42, $fa, $f7
    db $ef, $ee, $46, $4b, $53, $46, $50, $46, $3f, $49, $42, $62, $43, $49, $4c, $4c
    db $4f, $63, $ef, $ee, $2f, $42, $51, $68, $62, $44, $4c, $62, $3f, $3e, $40, $48
    db $63, $f7, $f0
TextStr_49_44b1:           ; id $051E
    ; "*:Wow! Yummy meat! Yum!"
    db $ea, $9f, $a3, $3a, $4c, $54, $63, $62, $3c, $52, $4a, $4a, $56, $ef, $ee, $4a
    db $42, $3e, $51, $63, $62, $3c, $52, $4a, $63, $f7, $f0
TextStr_49_44cc:           ; id $051F
    ; "*:Wow, yummy meat comming this / way again!"
    db $ea, $9f, $a3, $3a, $4c, $54, $5e, $62, $56, $52, $4a, $4a, $56, $ef, $ee, $4a
    db $42, $3e, $51, $62, $40, $4c, $4a, $4a, $46, $4b, $44, $62, $51, $45, $46, $50
    db $fa, $f7, $ef, $ee, $54, $3e, $56, $62, $3e, $44, $3e, $46, $4b, $63, $ef, $ee
    db $f7, $f0
TextStr_49_44fe:           ; id $0520
    ; "*:Wow! I'll do anything for / the meat!"
    db $ea, $9f, $a3, $3a, $4c, $54, $63, $62, $2c, $66, $49, $62, $41, $4c, $ef, $ee
    db $3e, $4b, $56, $51, $45, $46, $4b, $44, $62, $43, $4c, $4f, $fa, $f7, $ef, $ee
    db $51, $45, $42, $62, $4a, $42, $3e, $51, $63, $ef, $ee, $f7, $f0
TextStr_49_452b:           ; id $0521
    ; "Watabou:It seems you had a hard / time in the hole. Let's go back!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $2c, $51, $62, $50, $42, $42, $4a
    db $50, $ef, $ee, $56, $4c, $52, $62, $45, $3e, $41, $62, $3e, $62, $45, $3e, $4f
    db $41, $fa, $f7, $ef, $ee, $51, $46, $4a, $42, $62, $46, $4b, $62, $51, $45, $42
    db $62, $45, $4c, $49, $42, $5f, $ef, $ee, $2f, $42, $51, $68, $62, $44, $4c, $62
    db $3f, $3e, $40, $48, $63, $f7, $f0
TextStr_49_4572:           ; id $0522
    ; "[HERO] checked out a treasure / chest! Wow! The treasure / chest was actually a Mimic!! / But the Mimic isn't doing / anything but laughing."
    db $f6, $62, $40, $45, $42, $40, $48, $42, $41, $ef, $ee, $4c, $52, $51, $62, $3e
    db $62, $51, $4f, $42, $3e, $50, $52, $4f, $42, $fa, $f7, $ef, $ee, $40, $45, $42
    db $50, $51, $63, $ef, $ee, $3a, $4c, $54, $63, $62, $37, $45, $42, $62, $51, $4f
    db $42, $3e, $50, $52, $4f, $42, $fa, $f7, $ef, $ee, $40, $45, $42, $50, $51, $62
    db $54, $3e, $50, $62, $3e, $40, $51, $52, $3e, $49, $49, $56, $ef, $ee, $3e, $62
    db $30, $46, $4a, $46, $40, $63, $63, $fa, $f7, $ef, $ee, $25, $52, $51, $62, $51
    db $45, $42, $62, $30, $46, $4a, $46, $40, $ef, $ee, $46, $50, $4b, $67, $62, $41
    db $4c, $46, $4b, $44, $fa, $f7, $ef, $ee, $3e, $4b, $56, $51, $45, $46, $4b, $44
    db $62, $3f, $52, $51, $ef, $ee, $49, $3e, $52, $44, $45, $46, $4b, $44, $5f, $f7
    db $f0
TextStr_49_4603:           ; id $0523
    ; "[HERO] looked into a jar. / There was a darkness that / seemed to draw you in."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $46, $4b, $51, $4c, $ef, $ee, $3e
    db $62, $47, $3e, $4f, $5f, $fa, $f7, $ef, $ee, $37, $45, $42, $4f, $42, $62, $54
    db $3e, $50, $62, $3e, $ef, $ee, $41, $3e, $4f, $48, $4b, $42, $50, $50, $62, $51
    db $45, $3e, $51, $fa, $f7, $ef, $ee, $50, $42, $42, $4a, $42, $41, $62, $51, $4c
    db $62, $41, $4f, $3e, $54, $ef, $ee, $56, $4c, $52, $62, $46, $4b, $5f, $f7, $f0
TextStr_49_4653:           ; id $0524
    ; "*:......"
    db $ea, $9f, $a3, $5f, $5f, $5f, $5f, $5f, $5f, $ef, $ee, $f7, $f0
TextStr_49_4660:           ; id $0525
    ; "*:So,yoooou saaaw my face...!!"
    db $ea, $9f, $a3, $36, $4c, $5e, $56, $4c, $4c, $4c, $4c, $52, $62, $50, $3e, $3e
    db $3e, $54, $ef, $ee, $4a, $56, $62, $43, $3e, $40, $42, $5f, $5f, $5f, $63, $63
    db $f7, $f0
TextStr_49_4682:           ; id $0526
    ; "*:It's yoooou agaaaain!"
    db $ea, $9f, $a3, $2c, $51, $68, $62, $56, $4c, $4c, $4c, $4c, $52, $ef, $ee, $3e
    db $44, $3e, $3e, $3e, $3e, $46, $4b, $63, $f7, $f0
TextStr_49_469c:           ; id $0527
    ; "*:Yoooou win...!!"
    db $ea, $9f, $a3, $3c, $4c, $4c, $4c, $4c, $52, $62, $54, $46, $4b, $5f, $5f, $5f
    db $63, $63, $ef, $ee, $f7, $f0
TextStr_49_46b2:           ; id $0528
    ; "Watabou:Good work! So,let's / gooooo baaack!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $2a, $4c, $4c, $41, $ef, $ee, $54
    db $4c, $4f, $48, $63, $62, $36, $4c, $5e, $49, $42, $51, $68, $fa, $f7, $ef, $ee
    db $44, $4c, $4c, $4c, $4c, $4c, $62, $3f, $3e, $3e, $3e, $40, $48, $63, $ef, $ee
    db $f7, $f0
TextStr_49_46e4:           ; id $0529
    ; "*:Squeak squeak! Strike!"
    db $ea, $9f, $a3, $36, $4e, $52, $42, $3e, $48, $62, $50, $4e, $52, $42, $3e, $48
    db $63, $ef, $ee, $36, $51, $4f, $46, $48, $42, $63, $f7, $f0
TextStr_49_4700:           ; id $052A
    ; "*:Good lord, You're good!"
    db $ea, $9f, $a3, $2a, $4c, $4c, $41, $62, $49, $4c, $4f, $41, $5e, $ef, $ee, $3c
    db $4c, $52, $69, $42, $62, $44, $4c, $4c, $41, $63, $f7, $f0
TextStr_49_471c:           ; id $052B
    ; "Watabou:Good work reading / SkyDragon's move. / Watabou:Pretty smart aren't you. / Watabou:Now, let's go back to / the castle!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $2a, $4c, $4c, $41, $ef, $ee, $54
    db $4c, $4f, $48, $62, $4f, $42, $3e, $41, $46, $4b, $44, $fa, $f7, $ef, $ee, $36
    db $48, $56, $27, $4f, $3e, $44, $4c, $4b, $68, $62, $4a, $4c, $53, $42, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $33, $4f, $42
    db $51, $51, $56, $ef, $ee, $50, $4a, $3e, $4f, $51, $62, $3e, $4f, $42, $4b, $67
    db $62, $56, $4c, $52, $5f, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52
    db $a3, $31, $4c, $54, $5e, $ef, $ee, $49, $42, $51, $68, $62, $44, $4c, $62, $3f
    db $3e, $40, $48, $62, $51, $4c, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $40, $3e
    db $50, $51, $49, $42, $63, $ef, $ee, $f7, $f0
TextStr_49_47a5:           ; id $052C
    ; "*:Look at my cool steps!"
    db $eb, $9f, $a3, $2f, $4c, $4c, $48, $62, $3e, $51, $62, $4a, $56, $ef, $ee, $40
    db $4c, $4c, $49, $62, $50, $51, $42, $4d, $50, $63, $f7, $f0
TextStr_49_47c1:           ; id $052D
    ; "*:Why don't you dance with me?"
    db $eb, $9f, $a3, $3a, $45, $56, $62, $41, $4c, $4b, $67, $62, $56, $4c, $52, $ef
    db $ee, $41, $3e, $4b, $40, $42, $62, $54, $46, $51, $45, $62, $4a, $42, $64, $f7
    db $f0
TextStr_49_47e2:           ; id $052E
    ; "*:You came again to dance with me? / Ready? Let's go!"
    db $eb, $9f, $a3, $3c, $4c, $52, $62, $40, $3e, $4a, $42, $62, $3e, $44, $3e, $46
    db $4b, $ef, $ee, $51, $4c, $62, $41, $3e, $4b, $40, $42, $62, $54, $46, $51, $45
    db $62, $4a, $42, $64, $fa, $f7, $ef, $ee, $35, $42, $3e, $41, $56, $64, $62, $2f
    db $42, $51, $68, $62, $44, $4c, $63, $ef, $ee, $f7, $f0
TextStr_49_481d:           ; id $052F
    ; "*:You're a great dancer!"
    db $eb, $9f, $a3, $3c, $4c, $52, $69, $42, $62, $3e, $62, $44, $4f, $42, $3e, $51
    db $ef, $ee, $41, $3e, $4b, $40, $42, $4f, $63, $f7, $f0
TextStr_49_4838:           ; id $0530
    ; "*:Did you enjoy dancing? Well, / let's go back!"
    db $eb, $9f, $a3, $27, $46, $41, $62, $56, $4c, $52, $62, $42, $4b, $47, $4c, $56
    db $ef, $ee, $41, $3e, $4b, $40, $46, $4b, $44, $64, $62, $3a, $42, $49, $49, $5e
    db $fa, $f7, $ef, $ee, $49, $42, $51, $68, $62, $44, $4c, $62, $3f, $3e, $40, $48
    db $63, $ef, $ee, $f7, $f0
TextStr_49_486d:           ; id $0531
    ; "There is a voice coming from out / of nowhere..."
    db $37, $45, $42, $4f, $42, $62, $46, $50, $62, $3e, $62, $53, $4c, $46, $40, $42
    db $ef, $ee, $40, $4c, $4a, $46, $4b, $44, $62, $43, $4f, $4c, $4a, $62, $4c, $52
    db $51, $fa, $f7, $ef, $ee, $4c, $43, $62, $4b, $4c, $54, $45, $42, $4f, $42, $5f
    db $5f, $5f, $ef, $ee, $f7, $f0
TextStr_49_48a3:           ; id $0532
    ; "*:Hello...the traveler over / there... / *:I'm the spirit of this spring. / *:Your companion fell in the / spring? / *:Would you like me to ..."
    db $eb, $9f, $a3, $2b, $42, $49, $49, $4c, $5f, $5f, $5f, $51, $45, $42, $ef, $ee
    db $51, $4f, $3e, $53, $42, $49, $42, $4f, $62, $4c, $53, $42, $4f, $fa, $f7, $ef
    db $ee, $51, $45, $42, $4f, $42, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $2c, $6a, $62, $51, $45, $42, $62, $50, $4d, $46, $4f, $46, $51, $ef, $ee
    db $4c, $43, $62, $51, $45, $46, $50, $62, $50, $4d, $4f, $46, $4b, $44, $5f, $fa
    db $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $4f, $62, $40, $4c, $4a, $4d, $3e, $4b
    db $46, $4c, $4b, $ef, $ee, $43, $42, $49, $49, $62, $46, $4b, $62, $51, $45, $42
    db $fa, $f7, $ef, $ee, $50, $4d, $4f, $46, $4b, $44, $64, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $3a, $4c, $52, $49, $41, $62, $56, $4c, $52, $62, $49, $46, $48
    db $42, $ef, $ee, $4a, $42, $62, $51, $4c, $62, $45, $42, $49, $4d, $62, $56, $4c
    db $52, $4f, $fa, $f7, $ef, $ee, $40, $4c, $4a, $4d, $3e, $4b, $46, $4c, $4b, $64
    db $ef, $ee, $ff, $f0
TextStr_49_4957:           ; id $0533
    ; "*:Now, wait there."
    db $eb, $9f, $a3, $31, $4c, $54, $5e, $62, $54, $3e, $46, $51, $62, $51, $45, $42
    db $4f, $42, $5f, $f7, $f0
TextStr_49_496c:           ; id $0534
    ; "*:Then, would you like me to send / you back to your home world? [YES/NO]"
    db $eb, $9f, $a3, $37, $45, $42, $4b, $5e, $62, $54, $4c, $52, $49, $41, $62, $56
    db $4c, $52, $ef, $ee, $49, $46, $48, $42, $62, $4a, $42, $62, $51, $4c, $62, $50
    db $42, $4b, $41, $fa, $f7, $ef, $ee, $56, $4c, $52, $62, $3f, $3e, $40, $48, $62
    db $51, $4c, $62, $56, $4c, $52, $4f, $ef, $ee, $45, $4c, $4a, $42, $62, $54, $4c
    db $4f, $49, $41, $64, $ff, $f0
TextStr_49_49b2:           ; id $0535
    ; "*:It was actually a monster that / fell wasn't it? / *:Let me help it for you. / *:Now, wait a moment for me."
    db $eb, $9f, $a3, $2c, $51, $62, $54, $3e, $50, $62, $3e, $40, $51, $52, $3e, $49
    db $49, $56, $ef, $ee, $3e, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $51, $45
    db $3e, $51, $fa, $f7, $ef, $ee, $43, $42, $49, $49, $62, $54, $3e, $50, $4b, $67
    db $62, $46, $51, $64, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2f, $42, $51, $62
    db $4a, $42, $62, $45, $42, $49, $4d, $62, $46, $51, $ef, $ee, $43, $4c, $4f, $62
    db $56, $4c, $52, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $31, $4c, $54, $5e, $62, $54
    db $3e, $46, $51, $62, $3e, $ef, $ee, $4a, $4c, $4a, $42, $4b, $51, $62, $43, $4c
    db $4f, $62, $4a, $42, $5f, $f7, $f0
TextStr_49_4a29:           ; id $0536
    ; "*:Was it this meat that fell in the / spring? [YES/NO]"
    db $eb, $9f, $a3, $3a, $3e, $50, $62, $46, $51, $62, $51, $45, $46, $50, $62, $4a
    db $42, $3e, $51, $ef, $ee, $51, $45, $3e, $51, $62, $43, $42, $49, $49, $62, $46
    db $4b, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $50, $4d, $4f, $46, $4b, $44, $64
    db $ef, $ee, $ff, $f0
TextStr_49_4a5d:           ; id $0537
    ; "*:...you're a liar. / *:I'll give your monster back. Now / go away!"
    db $eb, $9f, $a3, $5f, $5f, $5f, $56, $4c, $52, $69, $42, $62, $3e, $ef, $ee, $49
    db $46, $3e, $4f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $66, $49, $62, $44, $46
    db $53, $42, $62, $56, $4c, $52, $4f, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f
    db $62, $3f, $3e, $40, $48, $5f, $62, $31, $4c, $54, $fa, $f7, $ef, $ee, $44, $4c
    db $62, $3e, $54, $3e, $56, $63, $ef, $ee, $f7, $f0
TextStr_49_4aa7:           ; id $0538
    ; "*:I see. Now, wait a moment for me."
    db $eb, $9f, $a3, $2c, $62, $50, $42, $42, $5f, $62, $31, $4c, $54, $5e, $62, $54
    db $3e, $46, $51, $ef, $ee, $3e, $62, $4a, $4c, $4a, $42, $4b, $51, $62, $43, $4c
    db $4f, $62, $4a, $42, $5f, $f7, $f0
TextStr_49_4ace:           ; id $0539
    ; "*:Now, is this the old guy who / fell in the spring? [YES/NO]"
    db $eb, $9f, $a3, $31, $4c, $54, $5e, $62, $46, $50, $62, $51, $45, $46, $50, $ef
    db $ee, $51, $45, $42, $62, $4c, $49, $41, $62, $44, $52, $56, $62, $54, $45, $4c
    db $fa, $f7, $ef, $ee, $43, $42, $49, $49, $62, $46, $4b, $62, $51, $45, $42, $ef
    db $ee, $50, $4d, $4f, $46, $4b, $44, $64, $ff, $f0
TextStr_49_4b08:           ; id $053A
    ; "*:...you're a liar. / *:I'll give your monster back. Now / go away!"
    db $eb, $9f, $a3, $5f, $5f, $5f, $56, $4c, $52, $69, $42, $62, $3e, $ef, $ee, $49
    db $46, $3e, $4f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $66, $49, $62, $44, $46
    db $53, $42, $62, $56, $4c, $52, $4f, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f
    db $62, $3f, $3e, $40, $48, $5f, $62, $31, $4c, $54, $fa, $f7, $ef, $ee, $44, $4c
    db $62, $3e, $54, $3e, $56, $63, $ef, $ee, $f7, $f0
TextStr_49_4b52:           ; id $053B
    ; "*:I see. Now,wait a minute for me."
    db $eb, $9f, $a3, $2c, $62, $50, $42, $42, $5f, $62, $31, $4c, $54, $5e, $54, $3e
    db $46, $51, $ef, $ee, $3e, $62, $4a, $46, $4b, $52, $51, $42, $62, $43, $4c, $4f
    db $62, $4a, $42, $5f, $f7, $f0
TextStr_49_4b78:           ; id $053C
    ; "*:Now is this the [INS 00], the / monster that fell in the spring? [YES/NO]"
    db $eb, $9f, $a3, $31, $4c, $54, $62, $46, $50, $62, $51, $45, $46, $50, $62, $51
    db $45, $42, $ef, $ee, $f9, $00, $5e, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $4a
    db $4c, $4b, $50, $51, $42, $4f, $62, $51, $45, $3e, $51, $62, $43, $42, $49, $49
    db $ef, $ee, $46, $4b, $62, $51, $45, $42, $62, $50, $4d, $4f, $46, $4b, $44, $64
    db $ff, $f0
TextStr_49_4bba:           ; id $053D
    ; "*:I don't understand you... / *:I'll give you back the monster / that fell in the spring. / *:Go back to your home world..."
    db $eb, $9f, $a3, $2c, $62, $41, $4c, $4b, $67, $ef, $ee, $52, $4b, $41, $42, $4f
    db $50, $51, $3e, $4b, $41, $62, $56, $4c, $52, $5f, $5f, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $2c, $66, $49, $62, $44, $46, $53, $42, $62, $56, $4c, $52, $ef, $ee
    db $3f, $3e, $40, $48, $62, $51, $45, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f
    db $fa, $f7, $ef, $ee, $51, $45, $3e, $51, $62, $43, $42, $49, $49, $62, $46, $4b
    db $62, $51, $45, $42, $ef, $ee, $50, $4d, $4f, $46, $4b, $44, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $2a, $4c, $62, $3f, $3e, $40, $48, $62, $51, $4c, $62, $56, $4c
    db $52, $4f, $ef, $ee, $45, $4c, $4a, $42, $62, $54, $4c, $4f, $49, $41, $5f, $5f
    db $5f, $f7, $f0
TextStr_49_4c3d:           ; id $053E
    ; "*:You're honest. I'll give you / back the monster that fell in the / spring. / *:And because you were honest... / *:I'll give you a Digster ..."
    db $eb, $9f, $a3, $3c, $4c, $52, $69, $42, $62, $45, $4c, $4b, $42, $50, $51, $5f
    db $ef, $ee, $2c, $66, $49, $62, $44, $46, $53, $42, $62, $56, $4c, $52, $fa, $f7
    db $ef, $ee, $3f, $3e, $40, $48, $62, $51, $45, $42, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $ef, $ee, $51, $45, $3e, $51, $62, $43, $42, $49, $49, $62, $46, $4b
    db $62, $51, $45, $42, $fa, $f7, $ef, $ee, $50, $4d, $4f, $46, $4b, $44, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $24, $4b, $41, $62, $3f, $42, $40, $3e, $52
    db $50, $42, $62, $56, $4c, $52, $ef, $ee, $54, $42, $4f, $42, $62, $45, $4c, $4b
    db $42, $50, $51, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $66, $49, $62
    db $44, $46, $53, $42, $62, $56, $4c, $52, $ef, $ee, $3e, $62, $27, $46, $44, $50
    db $51, $42, $4f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $43, $62, $56, $4c, $52, $62
    db $40, $3e, $4b, $ef, $ee, $41, $42, $43, $42, $3e, $51, $62, $46, $51, $63, $f7
    db $f0
TextStr_49_4cee:           ; id $053F
    ; "*:You did well. Please go back to / your home world..."
    db $eb, $9f, $a3, $3c, $4c, $52, $62, $41, $46, $41, $62, $54, $42, $49, $49, $5f
    db $ef, $ee, $33, $49, $42, $3e, $50, $42, $62, $44, $4c, $62, $3f, $3e, $40, $48
    db $62, $51, $4c, $fa, $f7, $ef, $ee, $56, $4c, $52, $4f, $62, $45, $4c, $4a, $42
    db $62, $54, $4c, $4f, $49, $41, $5f, $5f, $5f, $ef, $ee, $f7, $f0
TextStr_49_4d2b:           ; id $0540
    ; "*:Oh, it's you again. Would you / like to go back to your home world?"
    db $eb, $9f, $a3, $32, $45, $5e, $62, $46, $51, $68, $62, $56, $4c, $52, $ef, $ee
    db $3e, $44, $3e, $46, $4b, $5f, $62, $3a, $4c, $52, $49, $41, $62, $56, $4c, $52
    db $fa, $f7, $ef, $ee, $49, $46, $48, $42, $62, $51, $4c, $62, $44, $4c, $62, $3f
    db $3e, $40, $48, $62, $51, $4c, $ef, $ee, $56, $4c, $52, $4f, $62, $45, $4c, $4a
    db $42, $62, $54, $4c, $4f, $49, $41, $64, $f7, $f0
TextStr_49_4d75:           ; id $0541
    ; "*:Take your time."
    db $eb, $9f, $a3, $37, $3e, $48, $42, $62, $56, $4c, $52, $4f, $62, $51, $46, $4a
    db $42, $5f, $ef, $ee, $f7, $f0
TextStr_49_4d8b:           ; id $0542
    ; "*:Now so long..."
    db $eb, $9f, $a3, $31, $4c, $54, $62, $50, $4c, $62, $49, $4c, $4b, $44, $5f, $5f
    db $5f, $ef, $ee, $f7, $f0
TextStr_49_4da0:           ; id $0543
    ; "*:Comrade! Now is the time / for us to unite... / *:…and open the Gate to the new / age! / *:Yes! A world for monsters, of / monsters, and b..."
    db $ea, $9f, $a3, $26, $4c, $4a, $4f, $3e, $41, $42, $63, $ef, $ee, $31, $4c, $54
    db $62, $46, $50, $62, $51, $45, $42, $62, $51, $46, $4a, $42, $fa, $f7, $ef, $ee
    db $43, $4c, $4f, $62, $52, $50, $62, $51, $4c, $62, $52, $4b, $46, $51, $42, $5f
    db $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $a4, $3e, $4b, $41, $62, $4c
    db $4d, $42, $4b, $62, $51, $45, $42, $ef, $ee, $2a, $3e, $51, $42, $62, $51, $4c
    db $62, $51, $45, $42, $62, $4b, $42, $54, $fa, $f7, $ef, $ee, $3e, $44, $42, $63
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $42, $50, $63, $62, $24, $62, $54
    db $4c, $4f, $49, $41, $ef, $ee, $43, $4c, $4f, $62, $4a, $4c, $4b, $50, $51, $42
    db $4f, $50, $5e, $62, $4c, $43, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42
    db $4f, $50, $5e, $62, $3e, $4b, $41, $62, $3f, $56, $ef, $ee, $4a, $4c, $4b, $50
    db $51, $42, $4f, $50, $5f, $5f, $5f, $f7, $f0
TextStr_49_4e49:           ; id $0544
    ; "*:I'll promise you, comrade! / *:A world where we can eat sirloin / steaks everyday! / *:Therefore..."
    db $ea, $9f, $a3, $2c, $66, $49, $62, $4d, $4f, $4c, $4a, $46, $50, $42, $ef, $ee
    db $56, $4c, $52, $5e, $62, $40, $4c, $4a, $4f, $3e, $41, $42, $63, $fa, $f7, $ef
    db $ee, $9f, $a3, $24, $62, $54, $4c, $4f, $49, $41, $62, $54, $45, $42, $4f, $42
    db $ef, $ee, $54, $42, $62, $40, $3e, $4b, $62, $42, $3e, $51, $62, $50, $46, $4f
    db $49, $4c, $46, $4b, $fa, $f7, $ef, $ee, $50, $51, $42, $3e, $48, $50, $62, $42
    db $53, $42, $4f, $56, $41, $3e, $56, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $37, $45, $42, $4f, $42, $43, $4c, $4f, $42, $5f, $5f, $5f, $ef, $ee, $f7, $f0
TextStr_49_4eb9:           ; id $0545
    ; "*:Hm!? I don't know why / but I feel something behind / me. / *:Comrades! Excuse me for facing my / back to you."
    db $ea, $9f, $a3, $2b, $4a, $63, $64, $ef, $ee, $2c, $62, $41, $4c, $4b, $67, $62
    db $48, $4b, $4c, $54, $62, $54, $45, $56, $fa, $f7, $ef, $ee, $3f, $52, $51, $62
    db $2c, $62, $43, $42, $42, $49, $ef, $ee, $50, $4c, $4a, $42, $51, $45, $46, $4b
    db $44, $62, $3f, $42, $45, $46, $4b, $41, $fa, $f7, $ef, $ee, $4a, $42, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $26, $4c, $4a, $4f, $3e, $41, $42, $50, $63
    db $62, $28, $55, $40, $52, $50, $42, $ef, $ee, $4a, $42, $62, $43, $4c, $4f, $62
    db $43, $3e, $40, $46, $4b, $44, $62, $4a, $56, $fa, $f7, $ef, $ee, $3f, $3e, $40
    db $48, $62, $51, $4c, $62, $56, $4c, $52, $5f, $ef, $ee, $f7, $f0
TextStr_49_4f36:           ; id $0546
    ; "*:Sirloin steak is totally yummy! / Therefore... / *:Hm!? I feel something behind / me again!! / *:Comrades! Give me a little time!"
    db $ea, $9f, $a3, $36, $46, $4f, $49, $4c, $46, $4b, $62, $50, $51, $42, $3e, $48
    db $ef, $ee, $46, $50, $62, $51, $4c, $51, $3e, $49, $49, $56, $62, $56, $52, $4a
    db $4a, $56, $63, $fa, $f7, $ef, $ee, $37, $45, $42, $4f, $42, $43, $4c, $4f, $42
    db $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $4a, $63, $64, $62
    db $2c, $62, $43, $42, $42, $49, $ef, $ee, $50, $4c, $4a, $42, $51, $45, $46, $4b
    db $44, $62, $3f, $42, $45, $46, $4b, $41, $fa, $f7, $ef, $ee, $4a, $42, $62, $3e
    db $44, $3e, $46, $4b, $63, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $26, $4c
    db $4a, $4f, $3e, $41, $42, $50, $63, $62, $2a, $46, $53, $42, $ef, $ee, $4a, $42
    db $62, $3e, $62, $49, $46, $51, $51, $49, $42, $62, $51, $46, $4a, $42, $63, $f7
    db $f0
TextStr_49_4fc7:           ; id $0547
    ; "*:I demand one sirloin steak / a day!"
    db $ea, $9f, $a3, $2c, $62, $41, $42, $4a, $3e, $4b, $41, $62, $4c, $4b, $42, $ef
    db $ee, $50, $46, $4f, $49, $4c, $46, $4b, $62, $50, $51, $42, $3e, $48, $fa, $f7
    db $ef, $ee, $3e, $62, $41, $3e, $56, $63, $ef, $ee, $f7, $f0
TextStr_49_4ff3:           ; id $0548
    ; "*:Hee hee hee. I love burning / villages! / *:Wanna try it? [YES/NO]"
    db $ea, $9f, $a3, $2b, $42, $42, $62, $45, $42, $42, $62, $45, $42, $42, $5f, $ef
    db $ee, $2c, $62, $49, $4c, $53, $42, $62, $3f, $52, $4f, $4b, $46, $4b, $44, $fa
    db $f7, $ef, $ee, $53, $46, $49, $49, $3e, $44, $42, $50, $63, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $3a, $3e, $4b, $4b, $3e, $62, $51, $4f, $56, $62, $46, $51
    db $64, $ef, $ee, $ff, $f0
TextStr_49_5038:           ; id $0549
    ; "*:Hee hee hee. Burn'em burn'em / all! / *:Go burn them quick!"
    db $ea, $9f, $a3, $2b, $42, $42, $62, $45, $42, $42, $62, $45, $42, $42, $5f, $ef
    db $ee, $25, $52, $4f, $4b, $6e, $4a, $62, $3f, $52, $4f, $4b, $5c, $42, $4a, $fa
    db $f7, $ef, $ee, $3e, $49, $49, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2a
    db $4c, $62, $3f, $52, $4f, $4b, $62, $51, $45, $42, $4a, $ef, $ee, $4e, $52, $46
    db $40, $48, $63, $f7, $f0
TextStr_49_507d:           ; id $054A
    ; "*:You are so boring! / *:You wanna be burned instead!?"
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $3e, $4f, $42, $62, $50, $4c, $ef, $ee, $3f
    db $4c, $4f, $46, $4b, $44, $63, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $62
    db $54, $3e, $4b, $4b, $3e, $62, $3f, $42, $ef, $ee, $3f, $52, $4f, $4b, $42, $41
    db $62, $46, $4b, $50, $51, $42, $3e, $41, $63, $64, $f7, $f0
TextStr_49_50b9:           ; id $054B
    ; "*:You again! You really wanna / be burnt don't you!"
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $3e, $44, $3e, $46, $4b, $63, $ef, $ee, $3c
    db $4c, $52, $62, $4f, $42, $3e, $49, $49, $56, $62, $54, $3e, $4b, $4b, $3e, $fa
    db $f7, $ef, $ee, $3f, $42, $62, $3f, $52, $4f, $4b, $51, $62, $41, $4c, $4b, $67
    db $ef, $ee, $56, $4c, $52, $63, $f7, $f0
TextStr_49_50f1:           ; id $054C
    ; "*:Burn me, boil me! Whatever! / Ahrg!"
    db $ea, $9f, $a3, $25, $52, $4f, $4b, $62, $4a, $42, $5e, $62, $3f, $4c, $46, $49
    db $ef, $ee, $4a, $42, $63, $62, $3a, $45, $3e, $51, $42, $53, $42, $4f, $63, $fa
    db $f7, $ef, $ee, $24, $45, $4f, $44, $63, $ef, $ee, $f7, $f0
TextStr_49_511d:           ; id $054D
    ; "Watabou:Ouch! I'm gonna put out / the fire. / Watabou:Now! Go back to the / castle and get a good rest."
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $32, $52, $40, $45, $63, $ef, $ee
    db $2c, $6a, $62, $44, $4c, $4b, $4b, $3e, $62, $4d, $52, $51, $62, $4c, $52, $51
    db $fa, $f7, $ef, $ee, $51, $45, $42, $62, $43, $46, $4f, $42, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $31, $4c, $54, $63, $ef
    db $ee, $2a, $4c, $62, $3f, $3e, $40, $48, $62, $51, $4c, $62, $51, $45, $42, $fa
    db $f7, $ef, $ee, $40, $3e, $50, $51, $49, $42, $62, $3e, $4b, $41, $62, $44, $42
    db $51, $62, $3e, $ef, $ee, $44, $4c, $4c, $41, $62, $4f, $42, $50, $51, $5f, $f7
    db $f0
TextStr_49_518e:           ; id $054E
    ; "[HERO] read the posting. / :Once you go in, you will never be / able to get out. Make the decision / and have no regrets."
    db $f6, $62, $4f, $42, $3e, $41, $62, $51, $45, $42, $ef, $ee, $4d, $4c, $50, $51
    db $46, $4b, $44, $5f, $fa, $f7, $ef, $ee, $a3, $32, $4b, $40, $42, $62, $56, $4c
    db $52, $62, $44, $4c, $62, $46, $4b, $5e, $ef, $ee, $56, $4c, $52, $62, $54, $46
    db $49, $49, $62, $4b, $42, $53, $42, $4f, $62, $3f, $42, $fa, $f7, $ef, $ee, $3e
    db $3f, $49, $42, $62, $51, $4c, $62, $44, $42, $51, $62, $4c, $52, $51, $5f, $ef
    db $ee, $30, $3e, $48, $42, $62, $51, $45, $42, $62, $41, $42, $40, $46, $50, $46
    db $4c, $4b, $fa, $f7, $ef, $ee, $3e, $4b, $41, $62, $45, $3e, $53, $42, $62, $4b
    db $4c, $ef, $ee, $4f, $42, $44, $4f, $42, $51, $50, $5f, $f7, $f0
TextStr_49_520b:           ; id $054F
    ; "[HERO] read the posting. / :Wanted! Happy and healthy / applicants."
    db $f6, $62, $4f, $42, $3e, $41, $62, $51, $45, $42, $ef, $ee, $4d, $4c, $50, $51
    db $46, $4b, $44, $5f, $fa, $f7, $ef, $ee, $a3, $3a, $3e, $4b, $51, $42, $41, $63
    db $ef, $ee, $2b, $3e, $4d, $4d, $56, $62, $3e, $4b, $41, $62, $45, $42, $3e, $49
    db $51, $45, $56, $fa, $f7, $ef, $ee, $3e, $4d, $4d, $49, $46, $40, $3e, $4b, $51
    db $50, $5f, $ef, $ee, $f7, $f0
TextStr_49_5251:           ; id $0550
    ; "*:Hi! We go sip. Sip here!"
    db $eb, $9f, $a3, $2b, $46, $63, $62, $3a, $42, $62, $44, $4c, $62, $50, $46, $4d
    db $5f, $ef, $ee, $36, $46, $4d, $62, $45, $42, $4f, $42, $63, $f7, $f0
TextStr_49_526f:           ; id $0551
    ; "*:Boss! You can feel like a king / with jiggle joggle!"
    db $ea, $9f, $a3, $25, $4c, $50, $50, $63, $62, $3c, $4c, $52, $62, $40, $3e, $4b
    db $ef, $ee, $43, $42, $42, $49, $62, $49, $46, $48, $42, $62, $3e, $62, $48, $46
    db $4b, $44, $fa, $f7, $ef, $ee, $54, $46, $51, $45, $62, $47, $46, $44, $44, $49
    db $42, $ef, $ee, $47, $4c, $44, $44, $49, $42, $63, $f7, $f0
TextStr_49_52ab:           ; id $0552
    ; "*:Please let the sweet aroma relax / you!"
    db $eb, $9f, $a3, $33, $49, $42, $3e, $50, $42, $62, $49, $42, $51, $62, $51, $45
    db $42, $ef, $ee, $50, $54, $42, $42, $51, $62, $3e, $4f, $4c, $4a, $3e, $62, $4f
    db $42, $49, $3e, $55, $fa, $f7, $ef, $ee, $56, $4c, $52, $63, $ef, $ee, $f7, $f0
TextStr_49_52db:           ; id $0553
    ; "*:You're really too much. But / there's nobody left."
    db $ea, $9f, $a3, $3c, $4c, $52, $69, $42, $62, $4f, $42, $3e, $49, $49, $56, $ef
    db $ee, $51, $4c, $4c, $62, $4a, $52, $40, $45, $5f, $62, $25, $52, $51, $fa, $f7
    db $ef, $ee, $51, $45, $42, $4f, $42, $68, $62, $4b, $4c, $3f, $4c, $41, $56, $ef
    db $ee, $49, $42, $43, $51, $5f, $f7, $f0
TextStr_49_5313:           ; id $0554
    ; "*:Boss! You are so strong! / But there's nobody left."
    db $ea, $9f, $a3, $25, $4c, $50, $50, $63, $62, $3c, $4c, $52, $62, $3e, $4f, $42
    db $ef, $ee, $50, $4c, $62, $50, $51, $4f, $4c, $4b, $44, $63, $fa, $f7, $ef, $ee
    db $25, $52, $51, $62, $51, $45, $42, $4f, $42, $68, $62, $4b, $4c, $3f, $4c, $41
    db $56, $ef, $ee, $49, $42, $43, $51, $5f, $f7, $f0
TextStr_49_534d:           ; id $0555
    ; "*:I see you have lots of special / skills! But there is nobody left!"
    db $ea, $9f, $a3, $2c, $62, $50, $42, $42, $62, $56, $4c, $52, $62, $45, $3e, $53
    db $42, $ef, $ee, $49, $4c, $51, $50, $62, $4c, $43, $62, $50, $4d, $42, $40, $46
    db $3e, $49, $fa, $f7, $ef, $ee, $50, $48, $46, $49, $49, $50, $63, $62, $25, $52
    db $51, $62, $51, $45, $42, $4f, $42, $ef, $ee, $46, $50, $62, $4b, $4c, $3f, $4c
    db $41, $56, $62, $49, $42, $43, $51, $63, $f7, $f0
TextStr_49_5397:           ; id $0556
    ; "*:Mmm... sip sip! Here I come!"
    db $eb, $9f, $a3, $30, $4a, $4a, $5f, $5f, $5f, $62, $50, $46, $4d, $62, $50, $46
    db $4d, $63, $ef, $ee, $2b, $42, $4f, $42, $62, $2c, $62, $40, $4c, $4a, $42, $63
    db $f7, $f0
TextStr_49_53b9:           ; id $0557
    ; "*:Wow! You really impressed me!"
    db $eb, $9f, $a3, $3a, $4c, $54, $63, $62, $3c, $4c, $52, $62, $4f, $42, $3e, $49
    db $49, $56, $ef, $ee, $46, $4a, $4d, $4f, $42, $50, $50, $42, $41, $62, $4a, $42
    db $63, $f7, $f0
TextStr_49_53dc:           ; id $0558
    ; "Watabou:Had a good time!? We've / got to get going!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $2b, $3e, $41, $62, $3e, $ef, $ee
    db $44, $4c, $4c, $41, $62, $51, $46, $4a, $42, $63, $64, $62, $3a, $42, $6c, $42
    db $fa, $f7, $ef, $ee, $44, $4c, $51, $62, $51, $4c, $62, $44, $42, $51, $62, $44
    db $4c, $46, $4b, $44, $63, $ef, $ee, $f7, $f0
TextStr_49_5415:           ; id $0559
    ; "*:Now, sleep tight on my arms...!"
    db $eb, $9f, $a3, $31, $4c, $54, $5e, $62, $50, $49, $42, $42, $4d, $62, $51, $46
    db $44, $45, $51, $ef, $ee, $4c, $4b, $62, $4a, $56, $62, $3e, $4f, $4a, $50, $5f
    db $5f, $5f, $63, $f7, $f0
TextStr_49_543a:           ; id $055A
    ; "*:Oh, you were great. Giggle..."
    db $eb, $9f, $a3, $32, $45, $5e, $62, $56, $4c, $52, $62, $54, $42, $4f, $42, $ef
    db $ee, $44, $4f, $42, $3e, $51, $5f, $62, $2a, $46, $44, $44, $49, $42, $5f, $5f
    db $5f, $f7, $f0
TextStr_49_545d:           ; id $055B
    ; "Watabou:Had a good time!? We got / to get going!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $2b, $3e, $41, $62, $3e, $ef, $ee
    db $44, $4c, $4c, $41, $62, $51, $46, $4a, $42, $63, $64, $62, $3a, $42, $62, $44
    db $4c, $51, $fa, $f7, $ef, $ee, $51, $4c, $62, $44, $42, $51, $62, $44, $4c, $46
    db $4b, $44, $63, $ef, $ee, $f7, $f0
TextStr_49_5494:           ; id $055C
    ; "*:I'll let you sleep with my / SleepAir... then I will...Giggle.."
    db $eb, $9f, $a3, $2c, $66, $49, $62, $49, $42, $51, $62, $56, $4c, $52, $ef, $ee
    db $50, $49, $42, $42, $4d, $62, $54, $46, $51, $45, $62, $4a, $56, $fa, $f7, $ef
    db $ee, $36, $49, $42, $42, $4d, $24, $46, $4f, $5f, $5f, $5f, $62, $51, $45, $42
    db $4b, $ef, $ee, $2c, $62, $54, $46, $49, $49, $5f, $5f, $5f, $2a, $46, $44, $44
    db $49, $42, $5f, $5f, $f7, $f0
TextStr_49_54da:           ; id $055D
    ; "*:You're strong! If this is a / dream, please don't let me / wake up!"
    db $eb, $9f, $a3, $3c, $4c, $52, $69, $42, $62, $50, $51, $4f, $4c, $4b, $44, $63
    db $ef, $ee, $2c, $43, $62, $51, $45, $46, $50, $62, $46, $50, $62, $3e, $fa, $f7
    db $ef, $ee, $41, $4f, $42, $3e, $4a, $5e, $62, $4d, $49, $42, $3e, $50, $42, $ef
    db $ee, $41, $4c, $4b, $67, $62, $49, $42, $51, $62, $4a, $42, $fa, $f7, $ef, $ee
    db $54, $3e, $48, $42, $62, $52, $4d, $63, $ef, $ee, $f7, $f0
TextStr_49_5526:           ; id $055E
    ; "Watabou:Had a good time!? We got / to get going!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $2b, $3e, $41, $62, $3e, $ef, $ee
    db $44, $4c, $4c, $41, $62, $51, $46, $4a, $42, $63, $64, $62, $3a, $42, $62, $44
    db $4c, $51, $fa, $f7, $ef, $ee, $51, $4c, $62, $44, $42, $51, $62, $44, $4c, $46
    db $4b, $44, $63, $ef, $ee, $f7, $f0
TextStr_49_555d:           ; id $055F
    ; "Watabou didn't reply."
    db $3a, $3e, $51, $3e, $3f, $4c, $52, $62, $41, $46, $41, $4b, $67, $ef, $ee, $4f
    db $42, $4d, $49, $56, $5f, $f7, $f0
TextStr_49_5574:           ; id $0560
    ; "It was a Watabou doll!"
    db $2c, $51, $62, $54, $3e, $50, $62, $3e, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c
    db $52, $62, $41, $4c, $49, $49, $63, $f7, $f0
TextStr_49_558d:           ; id $0561
    ; "[HERO] checked out a treasure chest. / The treasure chest was actually a / Mimic! / Mimic is sticking his tongue out...!"
    db $f6, $62, $40, $45, $42, $40, $48, $42, $41, $62, $4c, $52, $51, $ef, $ee, $3e
    db $62, $51, $4f, $42, $3e, $50, $52, $4f, $42, $62, $40, $45, $42, $50, $51, $5f
    db $fa, $f7, $ef, $ee, $37, $45, $42, $62, $51, $4f, $42, $3e, $50, $52, $4f, $42
    db $62, $40, $45, $42, $50, $51, $ef, $ee, $54, $3e, $50, $62, $3e, $40, $51, $52
    db $3e, $49, $49, $56, $62, $3e, $fa, $f7, $ef, $ee, $30, $46, $4a, $46, $40, $63
    db $ef, $ee, $fa, $f7, $ef, $ee, $30, $46, $4a, $46, $40, $62, $46, $50, $62, $50
    db $51, $46, $40, $48, $46, $4b, $44, $ef, $ee, $45, $46, $50, $62, $51, $4c, $4b
    db $44, $52, $42, $62, $4c, $52, $51, $5f, $5f, $5f, $63, $f7, $f0
TextStr_49_560a:           ; id $0562
    ; "Mimic continues to stick his / tongue out."
    db $30, $46, $4a, $46, $40, $62, $40, $4c, $4b, $51, $46, $4b, $52, $42, $50, $ef
    db $ee, $51, $4c, $62, $50, $51, $46, $40, $48, $62, $45, $46, $50, $fa, $f7, $ef
    db $ee, $51, $4c, $4b, $44, $52, $42, $62, $4c, $52, $51, $5f, $ef, $ee, $f7, $f0
TextStr_49_563a:           ; id $0563
    ; "*:Bleat bleat. I cannot believe / that you made it here. / *:I should recognize your / effort. / *:But this is a dead end for you!!"
    db $ea, $9f, $a3, $25, $49, $42, $3e, $51, $62, $3f, $49, $42, $3e, $51, $5f, $ef
    db $ee, $2c, $62, $40, $3e, $4b, $4b, $4c, $51, $62, $3f, $42, $49, $46, $42, $53
    db $42, $fa, $f7, $ef, $ee, $51, $45, $3e, $51, $62, $56, $4c, $52, $62, $4a, $3e
    db $41, $42, $ef, $ee, $46, $51, $62, $45, $42, $4f, $42, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $2c, $62, $50, $45, $4c, $52, $49, $41, $ef, $ee, $4f, $42, $40, $4c
    db $44, $4b, $46, $57, $42, $62, $56, $4c, $52, $4f, $fa, $f7, $ef, $ee, $42, $43
    db $43, $4c, $4f, $51, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25, $52, $51
    db $62, $51, $45, $46, $50, $62, $46, $50, $62, $3e, $ef, $ee, $41, $42, $3e, $41
    db $62, $42, $4b, $41, $62, $43, $4c, $4f, $62, $56, $4c, $52, $63, $63, $f7, $f0
TextStr_49_56ca:           ; id $0564
    ; "*:Bleat bleat. Welcome to a / dead end, bleat!"
    db $ea, $9f, $a3, $25, $49, $42, $3e, $51, $62, $3f, $49, $42, $3e, $51, $5f, $ef
    db $ee, $3a, $42, $49, $40, $4c, $4a, $42, $62, $51, $4c, $62, $3e, $fa, $f7, $ef
    db $ee, $41, $42, $3e, $41, $62, $42, $4b, $41, $5e, $62, $3f, $49, $42, $3e, $51
    db $63, $ef, $ee, $f7, $f0
TextStr_49_56ff:           ; id $0565
    ; "*:Bleat bleat. I never imagined / such a strong master existed!"
    db $ea, $9f, $a3, $25, $49, $42, $3e, $51, $62, $3f, $49, $42, $3e, $51, $5f, $ef
    db $ee, $2c, $62, $4b, $42, $53, $42, $4f, $62, $46, $4a, $3e, $44, $46, $4b, $42
    db $41, $fa, $f7, $ef, $ee, $50, $52, $40, $45, $62, $3e, $62, $50, $51, $4f, $4c
    db $4b, $44, $ef, $ee, $4a, $3e, $50, $51, $42, $4f, $62, $42, $55, $46, $50, $51
    db $42, $41, $63, $f7, $f0
TextStr_49_5744:           ; id $0566
    ; "Watabou:You think the doll / looks just like me? Hee hee... / Watabou:[HERO], are you listening? / Let's go back!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $3c, $4c, $52, $ef, $ee, $51, $45
    db $46, $4b, $48, $62, $51, $45, $42, $62, $41, $4c, $49, $49, $fa, $f7, $ef, $ee
    db $49, $4c, $4c, $48, $50, $62, $47, $52, $50, $51, $62, $49, $46, $48, $42, $ef
    db $ee, $4a, $42, $64, $62, $2b, $42, $42, $62, $45, $42, $42, $5f, $5f, $5f, $fa
    db $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $f6, $5e, $ef, $ee, $3e
    db $4f, $42, $62, $56, $4c, $52, $62, $49, $46, $50, $51, $42, $4b, $46, $4b, $44
    db $64, $fa, $f7, $ef, $ee, $2f, $42, $51, $68, $62, $44, $4c, $62, $3f, $3e, $40
    db $48, $63, $ef, $ee, $f7, $f0
TextStr_49_57ba:           ; id $0567
    ; "*:You abused monsters cruelly / and wiped them out over and over / again, didn't you! / *:You recognize your sin of / abusing monsters? [YES..."
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $3e, $3f, $52, $50, $42, $41, $ef, $ee, $4a
    db $4c, $4b, $50, $51, $42, $4f, $50, $62, $40, $4f, $52, $42, $49, $49, $56, $fa
    db $f7, $ef, $ee, $3e, $4b, $41, $62, $54, $46, $4d, $42, $41, $62, $51, $45, $42
    db $4a, $62, $4c, $52, $51, $ef, $ee, $4c, $53, $42, $4f, $62, $3e, $4b, $41, $62
    db $4c, $53, $42, $4f, $fa, $f7, $ef, $ee, $3e, $44, $3e, $46, $4b, $5e, $62, $41
    db $46, $41, $4b, $67, $62, $56, $4c, $52, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $3c, $4c, $52, $62, $4f, $42, $40, $4c, $44, $4b, $46, $57, $42, $ef, $ee
    db $56, $4c, $52, $4f, $62, $50, $46, $4b, $62, $4c, $43, $fa, $f7, $ef, $ee, $3e
    db $3f, $52, $50, $46, $4b, $44, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $64
    db $ef, $ee, $ff, $f0
TextStr_49_584e:           ; id $0568
    ; "*:If you cannot learn by / listening to me, / *:I'll have to teach you the / hard way!!"
    db $ea, $9f, $a3, $2c, $43, $62, $56, $4c, $52, $62, $40, $3e, $4b, $4b, $4c, $51
    db $ef, $ee, $49, $42, $3e, $4f, $4b, $62, $3f, $56, $fa, $f7, $ef, $ee, $49, $46
    db $50, $51, $42, $4b, $46, $4b, $44, $62, $51, $4c, $62, $4a, $42, $5e, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $2c, $66, $49, $62, $45, $3e, $53, $42, $62, $51
    db $4c, $ef, $ee, $51, $42, $3e, $40, $45, $62, $56, $4c, $52, $62, $51, $45, $42
    db $fa, $f7, $ef, $ee, $45, $3e, $4f, $41, $62, $54, $3e, $56, $63, $63, $ef, $ee
    db $f7, $f0
TextStr_49_58b0:           ; id $0569
    ; "*:You recognize your sin, right? / Now here is the verdict. / *:The Monster Master [HERO] / recognizes the sin of abuse, / *:and hereby pled..."
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $4f, $42, $40, $4c, $44, $4b, $46, $57, $42
    db $ef, $ee, $56, $4c, $52, $4f, $62, $50, $46, $4b, $5e, $62, $4f, $46, $44, $45
    db $51, $64, $fa, $f7, $ef, $ee, $31, $4c, $54, $62, $45, $42, $4f, $42, $62, $46
    db $50, $62, $51, $45, $42, $ef, $ee, $53, $42, $4f, $41, $46, $40, $51, $5f, $fa
    db $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $30, $4c, $4b, $50, $51, $42, $4f
    db $ef, $ee, $30, $3e, $50, $51, $42, $4f, $62, $f6, $fa, $f7, $ef, $ee, $4f, $42
    db $40, $4c, $44, $4b, $46, $57, $42, $50, $62, $51, $45, $42, $62, $50, $46, $4b
    db $ef, $ee, $4c, $43, $62, $3e, $3f, $52, $50, $42, $5e, $fa, $f7, $ef, $ee, $9f
    db $a3, $3e, $4b, $41, $62, $45, $42, $4f, $42, $3f, $56, $ef, $ee, $4d, $49, $42
    db $41, $44, $42, $50, $62, $51, $4c, $62, $3e, $40, $40, $42, $4d, $51, $fa, $f7
    db $ef, $ee, $3e, $4b, $56, $62, $4d, $52, $4b, $46, $50, $45, $4a, $42, $4b, $51
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $4f, $42, $43, $4c
    db $4f, $42, $5e, $62, $f6, $ef, $ee, $46, $50, $62, $50, $42, $4b, $51, $42, $4b
    db $40, $42, $41, $fa, $f7, $ef, $ee, $51, $4c, $62, $51, $45, $42, $5f, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $41, $42, $3e, $51, $45, $62, $4d, $42, $4b
    db $3e, $49, $51, $56, $63, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $f6, $5e
    db $51, $3e, $48, $42, $62, $56, $4c, $52, $4f, $ef, $ee, $4d, $52, $4b, $46, $50
    db $45, $4a, $42, $4b, $51, $63, $ff, $f0
TextStr_49_59c8:           ; id $056A
    ; "*:If you cannot learn by / listening to me! / *:I'll have to teach you the / hard way!!"
    db $ea, $9f, $a3, $2c, $43, $62, $56, $4c, $52, $62, $40, $3e, $4b, $4b, $4c, $51
    db $ef, $ee, $49, $42, $3e, $4f, $4b, $62, $3f, $56, $fa, $f7, $ef, $ee, $49, $46
    db $50, $51, $42, $4b, $46, $4b, $44, $62, $51, $4c, $62, $4a, $42, $63, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $2c, $66, $49, $62, $45, $3e, $53, $42, $62, $51
    db $4c, $ef, $ee, $51, $42, $3e, $40, $45, $62, $56, $4c, $52, $62, $51, $45, $42
    db $fa, $f7, $ef, $ee, $45, $3e, $4f, $41, $62, $54, $3e, $56, $63, $63, $ef, $ee
    db $f7, $f0
TextStr_49_5a2a:           ; id $056B
    ; "*:Now we're holding a public / execution of [HERO] by / guillotine! / *:Dead man [HERO] walking!!"
    db $ea, $9f, $a3, $31, $4c, $54, $62, $54, $42, $69, $42, $ef, $ee, $45, $4c, $49
    db $41, $46, $4b, $44, $62, $3e, $62, $4d, $52, $3f, $49, $46, $40, $fa, $f7, $ef
    db $ee, $42, $55, $42, $40, $52, $51, $46, $4c, $4b, $62, $4c, $43, $ef, $ee, $f6
    db $62, $3f, $56, $fa, $f7, $ef, $ee, $44, $52, $46, $49, $49, $4c, $51, $46, $4b
    db $42, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $27, $42, $3e, $41, $62, $4a
    db $3e, $4b, $62, $f6, $ef, $ee, $54, $3e, $49, $48, $46, $4b, $44, $63, $63, $f7
    db $f0
TextStr_49_5a8b:           ; id $056C
    ; "*:What? You have something to say / before you die? [YES/NO]"
    db $ea, $9f, $a3, $3a, $45, $3e, $51, $64, $62, $3c, $4c, $52, $62, $45, $3e, $53
    db $42, $ef, $ee, $50, $4c, $4a, $42, $51, $45, $46, $4b, $44, $62, $51, $4c, $62
    db $50, $3e, $56, $fa, $f7, $ef, $ee, $3f, $42, $43, $4c, $4f, $42, $62, $56, $4c
    db $52, $62, $41, $46, $42, $64, $ef, $ee, $ff, $f0
TextStr_49_5ac5:           ; id $056D
    ; "*:None of your cheek! If you / don't like the guillotine... / *:I'll send you to your death / by my own hand!!"
    db $ea, $9f, $a3, $31, $4c, $4b, $42, $62, $4c, $43, $62, $56, $4c, $52, $4f, $ef
    db $ee, $40, $45, $42, $42, $48, $63, $62, $2c, $43, $62, $56, $4c, $52, $fa, $f7
    db $ef, $ee, $41, $4c, $4b, $67, $62, $49, $46, $48, $42, $62, $51, $45, $42, $ef
    db $ee, $44, $52, $46, $49, $49, $4c, $51, $46, $4b, $42, $5f, $5f, $5f, $fa, $f7
    db $ef, $ee, $9f, $a3, $2c, $66, $49, $62, $50, $42, $4b, $41, $62, $56, $4c, $52
    db $ef, $ee, $51, $4c, $62, $56, $4c, $52, $4f, $62, $41, $42, $3e, $51, $45, $fa
    db $f7, $ef, $ee, $3f, $56, $62, $4a, $56, $62, $4c, $54, $4b, $62, $45, $3e, $4b
    db $41, $63, $63, $ef, $ee, $f7, $f0
TextStr_49_5b3c:           ; id $056E
    ; "*:Then die!"
    db $ea, $9f, $a3, $37, $45, $42, $4b, $62, $41, $46, $42, $63, $ef, $ee, $f7, $f0
TextStr_49_5b4c:           ; id $056F
    ; "*:You want to have additional sins?"
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $54, $3e, $4b, $51, $62, $51, $4c, $62, $45
    db $3e, $53, $42, $ef, $ee, $3e, $41, $41, $46, $51, $46, $4c, $4b, $3e, $49, $62
    db $50, $46, $4b, $50, $64, $f7, $f0
TextStr_49_5b73:           ; id $0570
    ; "Watabou:[HERO]'s monsters trust / you, [HERO]! / Watabou:Don't worry, just fight! / Now let's go back!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $f6, $68, $ef, $ee, $4a, $4c, $4b
    db $50, $51, $42, $4f, $50, $62, $51, $4f, $52, $50, $51, $fa, $f7, $ef, $ee, $56
    db $4c, $52, $5e, $62, $f6, $63, $ef, $ee, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e
    db $3f, $4c, $52, $a3, $27, $4c, $4b, $67, $ef, $ee, $54, $4c, $4f, $4f, $56, $5e
    db $62, $47, $52, $50, $51, $62, $43, $46, $44, $45, $51, $63, $fa, $f7, $ef, $ee
    db $31, $4c, $54, $62, $49, $42, $51, $68, $62, $44, $4c, $62, $3f, $3e, $40, $48
    db $63, $ef, $ee, $f7, $f0
TextStr_49_5bd8:           ; id $0571
    ; "[HERO] touched the blade of the / guillotine. The cold blade / reflects [HERO]'s face."
    db $f6, $62, $51, $4c, $52, $40, $45, $42, $41, $62, $51, $45, $42, $ef, $ee, $3f
    db $49, $3e, $41, $42, $62, $4c, $43, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $44
    db $52, $46, $49, $49, $4c, $51, $46, $4b, $42, $5f, $ef, $ee, $37, $45, $42, $62
    db $40, $4c, $49, $41, $62, $3f, $49, $3e, $41, $42, $fa, $f7, $ef, $ee, $4f, $42
    db $43, $49, $42, $40, $51, $50, $62, $f6, $68, $ef, $ee, $43, $3e, $40, $42, $5f
    db $f7, $f0
TextStr_49_5c2a:           ; id $0572
    ; "[HERO] touched the blade of the / guillotine. The cold blade / reflects [HERO]'s face, / as if the guillotine is / welcoming [HERO]!"
    db $f6, $62, $51, $4c, $52, $40, $45, $42, $41, $62, $51, $45, $42, $ef, $ee, $3f
    db $49, $3e, $41, $42, $62, $4c, $43, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $44
    db $52, $46, $49, $49, $4c, $51, $46, $4b, $42, $5f, $ef, $ee, $37, $45, $42, $62
    db $40, $4c, $49, $41, $62, $3f, $49, $3e, $41, $42, $fa, $f7, $ef, $ee, $4f, $42
    db $43, $49, $42, $40, $51, $50, $62, $f6, $68, $ef, $ee, $43, $3e, $40, $42, $5e
    db $fa, $f7, $ef, $ee, $3e, $50, $62, $46, $43, $62, $51, $45, $42, $ef, $ee, $44
    db $52, $46, $49, $49, $4c, $51, $46, $4b, $42, $62, $46, $50, $fa, $f7, $ef, $ee
    db $54, $42, $49, $40, $4c, $4a, $46, $4b, $44, $62, $f6, $63, $ef, $ee, $f7, $f0
TextStr_49_5caa:           ; id $0573
    ; "*:Aaaarrrggh! Gwrrrr... / *:Gwrrggg..."
    db $ea, $9f, $a3, $24, $3e, $3e, $3e, $4f, $4f, $4f, $44, $44, $45, $63, $ef, $ee
    db $2a, $54, $4f, $4f, $4f, $4f, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2a
    db $54, $4f, $4f, $44, $44, $44, $5f, $5f, $5f, $ef, $ee, $f7, $f0
TextStr_49_5cd7:           ; id $0574
    ; "*:Gwwrrggg..."
    db $ea, $9f, $a3, $2a, $54, $54, $4f, $4f, $44, $44, $44, $5f, $5f, $5f, $ef, $ee
    db $f7, $f0
TextStr_49_5ce9:           ; id $0575
    ; "Watabou:[HERO]! Let's go."
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $f6, $63, $ef, $ee, $2f, $42, $51
    db $68, $62, $44, $4c, $5f, $f7, $f0
TextStr_49_5d00:           ; id $0576
    ; "*:Aaarrrggh... / *:I can't stand it. I just can't / stand it. I can't stand it. I lost!! / *:Gwrrr!"
    db $ea, $9f, $a3, $24, $3e, $3e, $4f, $4f, $4f, $44, $44, $45, $5f, $5f, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $40, $3e, $4b, $67, $62, $50, $51
    db $3e, $4b, $41, $ef, $ee, $46, $51, $5f, $62, $2c, $62, $47, $52, $50, $51, $62
    db $40, $3e, $4b, $67, $fa, $f7, $ef, $ee, $50, $51, $3e, $4b, $41, $62, $46, $51
    db $5f, $62, $2c, $62, $40, $3e, $4b, $67, $ef, $ee, $50, $51, $3e, $4b, $41, $62
    db $46, $51, $5f, $62, $2c, $62, $49, $4c, $50, $51, $63, $63, $fa, $f7, $ef, $ee
    db $9f, $a3, $2a, $54, $4f, $4f, $4f, $63, $ef, $ee, $f7, $f0
TextStr_49_5d6c:           ; id $0577
    ; "*:Look... this sword... / *:It's the Kusanagi sword / of Orochi. / *:But I'm not looking for such a / cheap sword!! / *:...Did we meet somew..."
    db $ea, $9f, $a3, $2f, $4c, $4c, $48, $5f, $5f, $5f, $62, $51, $45, $46, $50, $ef
    db $ee, $50, $54, $4c, $4f, $41, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c
    db $51, $68, $62, $51, $45, $42, $ef, $ee, $2e, $52, $50, $3e, $4b, $3e, $44, $46
    db $62, $50, $54, $4c, $4f, $41, $fa, $f7, $ef, $ee, $4c, $43, $62, $32, $4f, $4c
    db $40, $45, $46, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25, $52, $51, $62
    db $2c, $6a, $62, $4b, $4c, $51, $ef, $ee, $49, $4c, $4c, $48, $46, $4b, $44, $62
    db $43, $4c, $4f, $62, $50, $52, $40, $45, $62, $3e, $fa, $f7, $ef, $ee, $40, $45
    db $42, $3e, $4d, $62, $50, $54, $4c, $4f, $41, $63, $63, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $5f, $5f, $5f, $27, $46, $41, $62, $54, $42, $62, $4a, $42, $42
    db $51, $ef, $ee, $50, $4c, $4a, $42, $54, $45, $42, $4f, $42, $64, $fa, $f7, $ef
    db $ee, $9f, $a3, $3a, $45, $3e, $51, $64, $62, $3c, $4c, $52, $ef, $ee, $51, $45
    db $3e, $4b, $48, $42, $41, $62, $4a, $42, $62, $43, $4c, $4f, $fa, $f7, $ef, $ee
    db $45, $42, $49, $4d, $46, $4b, $44, $62, $56, $4c, $52, $64, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $2b, $3e, $63, $62, $36, $52, $40, $45, $62, $3e, $62, $4b
    db $3e, $46, $53, $42, $ef, $ee, $44, $52, $56, $5f, $62, $27, $4c, $4b, $67, $62
    db $44, $42, $51, $62, $4a, $42, $fa, $f7, $ef, $ee, $54, $4f, $4c, $4b, $44, $5f
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $3e, $4a, $62, $47, $52, $50
    db $51, $ef, $ee, $49, $4c, $4c, $48, $46, $4b, $44, $62, $43, $4c, $4f, $62, $51
    db $45, $42, $fa, $f7, $ef, $ee, $4a, $4c, $50, $51, $62, $4d, $4c, $54, $42, $4f
    db $43, $52, $49, $ef, $ee, $50, $54, $4c, $4f, $41, $5f, $62, $37, $45, $3e, $51
    db $68, $62, $3e, $49, $49, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $43, $62, $56
    db $4c, $52, $62, $45, $3e, $53, $42, $ef, $ee, $4b, $4c, $51, $45, $46, $4b, $44
    db $62, $4a, $4c, $4f, $42, $62, $51, $4c, $fa, $f7, $ef, $ee, $50, $3e, $56, $5e
    db $62, $2c, $66, $49, $62, $44, $4c, $5f, $ef, $ee, $ff, $f0
TextStr_49_5ee8:           ; id $0578
    ; "*:So long! The Orochi won't / trouble you anymore. / *:At least you should practice / with your sword!"
    db $ea, $9f, $a3, $36, $4c, $62, $49, $4c, $4b, $44, $63, $62, $37, $45, $42, $ef
    db $ee, $32, $4f, $4c, $40, $45, $46, $62, $54, $4c, $4b, $67, $fa, $f7, $ef, $ee
    db $51, $4f, $4c, $52, $3f, $49, $42, $62, $56, $4c, $52, $ef, $ee, $3e, $4b, $56
    db $4a, $4c, $4f, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $24, $51, $62, $49, $42
    db $3e, $50, $51, $62, $56, $4c, $52, $ef, $ee, $50, $45, $4c, $52, $49, $41, $62
    db $4d, $4f, $3e, $40, $51, $46, $40, $42, $fa, $f7, $ef, $ee, $54, $46, $51, $45
    db $62, $56, $4c, $52, $4f, $62, $50, $54, $4c, $4f, $41, $63, $ef, $ee, $f7, $f0
TextStr_49_5f58:           ; id $0579
    ; "*:What? You want to know why I am / looking for the strongest sword? / *:What difference does it make? / *:...doesn't matter. / I'll tell yo..."
    db $ea, $9f, $a3, $3a, $45, $3e, $51, $64, $62, $3c, $4c, $52, $62, $54, $3e, $4b
    db $51, $ef, $ee, $51, $4c, $62, $48, $4b, $4c, $54, $62, $54, $45, $56, $62, $2c
    db $62, $3e, $4a, $fa, $f7, $ef, $ee, $49, $4c, $4c, $48, $46, $4b, $44, $62, $43
    db $4c, $4f, $62, $51, $45, $42, $ef, $ee, $50, $51, $4f, $4c, $4b, $44, $42, $50
    db $51, $62, $50, $54, $4c, $4f, $41, $64, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45
    db $3e, $51, $62, $41, $46, $43, $43, $42, $4f, $42, $4b, $40, $42, $ef, $ee, $41
    db $4c, $42, $50, $62, $46, $51, $62, $4a, $3e, $48, $42, $64, $fa, $f7, $ef, $ee
    db $9f, $a3, $5f, $5f, $5f, $41, $4c, $42, $50, $4b, $67, $ef, $ee, $4a, $3e, $51
    db $51, $42, $4f, $5f, $fa, $f7, $ef, $ee, $2c, $66, $49, $62, $51, $42, $49, $49
    db $62, $56, $4c, $52, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45, $56
    db $62, $3e, $4a, $62, $2c, $62, $49, $4c, $4c, $48, $46, $4b, $44, $ef, $ee, $43
    db $4c, $4f, $62, $51, $45, $42, $62, $50, $51, $4f, $4c, $4b, $44, $42, $50, $51
    db $fa, $f7, $ef, $ee, $50, $54, $4c, $4f, $41, $64, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $2c, $51, $50, $62, $3f, $42, $40, $3e, $52, $50, $42, $62, $2c, $ef
    db $ee, $54, $3e, $4b, $51, $62, $51, $4c, $62, $3f, $42, $fa, $f7, $ef, $ee, $4d
    db $4c, $54, $42, $4f, $43, $52, $49, $5f, $62, $2c, $62, $45, $3e, $51, $42, $ef
    db $ee, $54, $42, $3e, $48, $49, $46, $4b, $44, $50, $63, $fa, $f7, $ef, $ee, $9f
    db $a3, $2c, $62, $45, $3e, $51, $42, $62, $49, $4c, $50, $46, $4b, $44, $5f, $ef
    db $ee, $36, $4c, $5e, $62, $2c, $62, $4b, $42, $42, $41, $fa, $f7, $ef, $ee, $3e
    db $62, $50, $51, $4f, $4c, $4b, $44, $42, $4f, $62, $50, $54, $4c, $4f, $41, $5f
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $31, $4c, $3f, $4c, $41, $56, $62, $50
    db $45, $4c, $52, $49, $41, $62, $ef, $ee, $51, $4f, $56, $62, $51, $4c, $62, $50
    db $51, $4c, $4d, $62, $4a, $42, $62, $4c, $4f, $fa, $f7, $ef, $ee, $2c, $66, $49
    db $62, $50, $4a, $3e, $50, $45, $62, $51, $45, $42, $4a, $63, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $32, $45, $5e, $62, $2c, $62, $3e, $4a, $62, $54, $3e, $50
    db $51, $46, $4b, $44, $ef, $ee, $4a, $56, $62, $51, $46, $4a, $42, $5f, $fa, $f7
    db $ef, $ee, $9f, $a3, $2a, $4c, $51, $62, $51, $4c, $62, $44, $42, $51, $62, $ef
    db $ee, $44, $4c, $46, $4b, $44, $5f, $62, $32, $4f, $4c, $40, $45, $46, $62, $fa
    db $f7, $ef, $ee, $54, $4c, $4b, $67, $62, $3f, $42, $62, $3e, $4b, $56, $ef, $ee
    db $51, $4f, $4c, $52, $3f, $49, $42, $62, $3e, $4b, $56, $4a, $4c, $4f, $42, $5f
    db $fa, $f7, $ef, $ee, $9f, $a3, $24, $51, $62, $49, $42, $3e, $50, $51, $62, $56
    db $4c, $52, $62, $ef, $ee, $50, $45, $4c, $52, $49, $41, $62, $4d, $4f, $3e, $40
    db $51, $46, $40, $42, $62, $fa, $f7, $ef, $ee, $54, $46, $51, $45, $62, $56, $4c
    db $52, $4f, $62, $50, $54, $4c, $4f, $41, $63, $62, $ef, $ee, $f7, $f0
TextStr_49_6176:           ; id $057A
    ; "Watabou:Oh, you were saved by / somebody. Oh well. / Watabou:Let's go back!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $32, $45, $5e, $62, $56, $4c, $52
    db $ef, $ee, $54, $42, $4f, $42, $62, $50, $3e, $53, $42, $41, $62, $3f, $56, $fa
    db $f7, $ef, $ee, $50, $4c, $4a, $42, $3f, $4c, $41, $56, $5f, $62, $32, $45, $62
    db $54, $42, $49, $49, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f
    db $4c, $52, $a3, $2f, $42, $51, $68, $ef, $ee, $44, $4c, $62, $3f, $3e, $40, $48
    db $63, $f7, $f0
TextStr_49_61c9:           ; id $057B
    ; "*:Welcome [HERO]! / *:I'm the King of Kings, / DracoLord! / DracoLord:I have been waiting… / DracoLord:…for a youth like you to / show up. /..."
    db $ea, $9f, $a3, $3a, $42, $49, $40, $4c, $4a, $42, $62, $f6, $63, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $2c, $6a, $62, $51, $45, $42, $62, $2e, $46, $4b, $44
    db $ef, $ee, $4c, $43, $62, $2e, $46, $4b, $44, $50, $5e, $fa, $f7, $ef, $ee, $27
    db $4f, $3e, $40, $4c, $2f, $4c, $4f, $41, $63, $ef, $ee, $fa, $f7, $ef, $ee, $27
    db $4f, $3e, $40, $4c, $2f, $4c, $4f, $41, $a3, $2c, $62, $45, $3e, $53, $42, $ef
    db $ee, $3f, $42, $42, $4b, $62, $54, $3e, $46, $51, $46, $4b, $44, $a4, $fa, $f7
    db $ef, $ee, $27, $4f, $3e, $40, $4c, $2f, $4c, $4f, $41, $a3, $a4, $43, $4c, $4f
    db $62, $3e, $ef, $ee, $56, $4c, $52, $51, $45, $62, $49, $46, $48, $42, $62, $56
    db $4c, $52, $62, $51, $4c, $fa, $f7, $ef, $ee, $50, $45, $4c, $54, $62, $52, $4d
    db $5f, $62, $ef, $ee, $fa, $f7, $ef, $ee, $27, $4f, $3e, $40, $4c, $2f, $4c, $4f
    db $41, $a3, $2c, $43, $62, $56, $4c, $52, $ef, $ee, $54, $46, $49, $49, $62, $3f
    db $42, $40, $4c, $4a, $42, $62, $4a, $56, $62, $fa, $f7, $ef, $ee, $4d, $3e, $49
    db $5e, $ef, $ee, $fa, $f7, $ef, $ee, $27, $4f, $3e, $40, $4c, $2f, $4c, $4f, $41
    db $a3, $2c, $62, $54, $46, $49, $49, $ef, $ee, $44, $46, $53, $42, $62, $56, $4c
    db $52, $5e, $62, $f6, $fa, $f7, $ef, $ee, $45, $3e, $49, $43, $62, $4c, $43, $62
    db $51, $45, $42, $62, $54, $4c, $4f, $49, $41, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $27, $4f, $3e, $40, $4c, $2f, $4c, $4f, $41, $a3, $3a, $45, $3e, $51, $ef, $ee
    db $41, $4c, $62, $56, $4c, $52, $62, $50, $3e, $56, $64, $fa, $f7, $ef, $ee, $3a
    db $46, $49, $49, $62, $56, $4c, $52, $62, $3f, $42, $62, $4a, $56, $ef, $ee, $4d
    db $3e, $49, $64, $ff, $f0
TextStr_49_62fe:           ; id $057C
    ; "DracoLord:Great, you agreed! / Now I will give you... / DracoLord:half of the world, / the world of darkness! / DracoLord:Did you really bel..."
    db $ea, $27, $4f, $3e, $40, $4c, $2f, $4c, $4f, $41, $a3, $2a, $4f, $42, $3e, $51
    db $5e, $ef, $ee, $56, $4c, $52, $62, $3e, $44, $4f, $42, $42, $41, $63, $fa, $f7
    db $ef, $ee, $31, $4c, $54, $62, $2c, $62, $54, $46, $49, $49, $ef, $ee, $44, $46
    db $53, $42, $62, $56, $4c, $52, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $27, $4f, $3e
    db $40, $4c, $2f, $4c, $4f, $41, $a3, $45, $3e, $49, $43, $ef, $ee, $4c, $43, $62
    db $51, $45, $42, $62, $54, $4c, $4f, $49, $41, $5e, $fa, $f7, $ef, $ee, $51, $45
    db $42, $62, $54, $4c, $4f, $49, $41, $62, $4c, $43, $ef, $ee, $41, $3e, $4f, $48
    db $4b, $42, $50, $50, $63, $fa, $f7, $ef, $ee, $27, $4f, $3e, $40, $4c, $2f, $4c
    db $4f, $41, $a3, $27, $46, $41, $62, $56, $4c, $52, $ef, $ee, $4f, $42, $3e, $49
    db $49, $56, $62, $3f, $42, $49, $46, $42, $53, $42, $fa, $f7, $ef, $ee, $2c, $62
    db $54, $4c, $52, $49, $41, $62, $50, $3e, $56, $ef, $ee, $50, $52, $40, $45, $62
    db $3e, $62, $51, $45, $46, $4b, $44, $64, $fa, $f7, $ef, $ee, $27, $4f, $3e, $40
    db $4c, $2f, $4c, $4f, $41, $a3, $29, $4c, $4c, $49, $63, $ef, $ee, $37, $45, $3e
    db $51, $62, $54, $46, $49, $49, $fa, $f7, $ef, $ee, $51, $42, $3e, $40, $45, $62
    db $56, $4c, $52, $63, $ef, $ee, $f7, $f0
TextStr_49_63e6:           ; id $057D
    ; "DracoLord:What's wrong with it. / It is not a bad offer. / DracoLord:You really don't want / half of the world? [YES/NO]"
    db $ea, $27, $4f, $3e, $40, $4c, $2f, $4c, $4f, $41, $a3, $3a, $45, $3e, $51, $68
    db $ef, $ee, $54, $4f, $4c, $4b, $44, $62, $54, $46, $51, $45, $62, $46, $51, $5f
    db $fa, $f7, $ef, $ee, $2c, $51, $62, $46, $50, $62, $4b, $4c, $51, $62, $3e, $62
    db $3f, $3e, $41, $ef, $ee, $4c, $43, $43, $42, $4f, $5f, $fa, $f7, $ef, $ee, $27
    db $4f, $3e, $40, $4c, $2f, $4c, $4f, $41, $a3, $3c, $4c, $52, $62, $ef, $ee, $4f
    db $42, $3e, $49, $49, $56, $62, $41, $4c, $4b, $67, $62, $54, $3e, $4b, $51, $fa
    db $f7, $ef, $ee, $45, $3e, $49, $43, $62, $4c, $43, $62, $51, $45, $42, $62, $54
    db $4c, $4f, $49, $41, $64, $ef, $ee, $ff, $f0
TextStr_49_645f:           ; id $057E
    ; "DracoLord:You say you're going to / beat me? / DracoLord:Fool! That will / teach you!"
    db $ea, $27, $4f, $3e, $40, $4c, $2f, $4c, $4f, $41, $a3, $3c, $4c, $52, $62, $50
    db $3e, $56, $62, $ef, $ee, $56, $4c, $52, $69, $42, $62, $44, $4c, $46, $4b, $44
    db $62, $51, $4c, $62, $fa, $f7, $ef, $ee, $3f, $42, $3e, $51, $62, $4a, $42, $64
    db $ef, $ee, $fa, $f7, $ef, $ee, $27, $4f, $3e, $40, $4c, $2f, $4c, $4f, $41, $a3
    db $29, $4c, $4c, $49, $63, $ef, $ee, $37, $45, $3e, $51, $62, $54, $46, $49, $49
    db $62, $fa, $f7, $ef, $ee, $51, $42, $3e, $40, $45, $62, $56, $4c, $52, $63, $ef
    db $ee, $f7, $f0
TextStr_49_64c2:           ; id $057F
    ; "DracoLord:You came back? / You never learn! / DarcoLoad:I'm not interested in / weaklings! / DracoLord:You'll pay for your / rudeness with y..."
    db $ea, $27, $4f, $3e, $40, $4c, $2f, $4c, $4f, $41, $a3, $3c, $4c, $52, $62, $ef
    db $ee, $40, $3e, $4a, $42, $62, $3f, $3e, $40, $48, $64, $fa, $f7, $ef, $ee, $3c
    db $4c, $52, $62, $4b, $42, $53, $42, $4f, $62, $49, $42, $3e, $4f, $4b, $63, $ef
    db $ee, $fa, $f7, $ef, $ee, $27, $3e, $4f, $40, $4c, $2f, $4c, $3e, $41, $a3, $2c
    db $6a, $62, $4b, $4c, $51, $62, $ef, $ee, $46, $4b, $51, $42, $4f, $42, $50, $51
    db $42, $41, $62, $46, $4b, $fa, $f7, $ef, $ee, $54, $42, $3e, $48, $49, $46, $4b
    db $44, $50, $63, $ef, $ee, $fa, $f7, $ef, $ee, $27, $4f, $3e, $40, $4c, $2f, $4c
    db $4f, $41, $a3, $3c, $4c, $52, $66, $49, $ef, $ee, $4d, $3e, $56, $62, $43, $4c
    db $4f, $62, $56, $4c, $52, $4f, $62, $fa, $f7, $ef, $ee, $4f, $52, $41, $42, $4b
    db $42, $50, $50, $62, $54, $46, $51, $45, $ef, $ee, $56, $4c, $52, $4f, $62, $49
    db $46, $43, $42, $63, $f7, $f0
TextStr_49_6568:           ; id $0580
    ; "DracoLord:You beat me. You're really / something!"
    db $ea, $27, $4f, $3e, $40, $4c, $2f, $4c, $4f, $41, $a3, $3c, $4c, $52, $62, $3f
    db $42, $3e, $51, $ef, $ee, $4a, $42, $5f, $62, $3c, $4c, $52, $69, $42, $62, $4f
    db $42, $3e, $49, $49, $56, $fa, $f7, $ef, $ee, $50, $4c, $4a, $42, $51, $45, $46
    db $4b, $44, $63, $ef, $ee, $f7, $f0
TextStr_49_659f:           ; id $0581
    ; "Watabou:One down! [HERO]! / Let's go back!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $32, $4b, $42, $ef, $ee, $41, $4c
    db $54, $4b, $63, $62, $f6, $63, $62, $fa, $f7, $ef, $ee, $2f, $42, $51, $68, $62
    db $44, $4c, $62, $3f, $3e, $40, $48, $63, $ef, $ee, $f7, $f0
TextStr_49_65cb:           ; id $0582
    ; "*:Who is it? / *:Disturbing my rest? / *:You fool! / *:Did you do that knowing I'm the / great oracle, Hargon!? [YES/NO]"
    db $ea, $9f, $a3, $3a, $45, $4c, $62, $46, $50, $62, $46, $51, $64, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $27, $46, $50, $51, $52, $4f, $3f, $46, $4b, $44, $ef
    db $ee, $4a, $56, $62, $4f, $42, $50, $51, $64, $fa, $f7, $ef, $ee, $9f, $a3, $3c
    db $4c, $52, $62, $43, $4c, $4c, $49, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $27, $46, $41, $62, $56, $4c, $52, $62, $41, $4c, $62, $51, $45, $3e, $51, $ef
    db $ee, $48, $4b, $4c, $54, $46, $4b, $44, $62, $2c, $6a, $62, $51, $45, $42, $62
    db $fa, $f7, $ef, $ee, $44, $4f, $42, $3e, $51, $62, $4c, $4f, $3e, $40, $49, $42
    db $5e, $ef, $ee, $2b, $3e, $4f, $44, $4c, $4b, $63, $64, $62, $ff, $f0
TextStr_49_6649:           ; id $0583
    ; "Hargon:Then it is unforgivable! / Hargon:I will teach you how / foolish you are!"
    db $ea, $2b, $3e, $4f, $44, $4c, $4b, $a3, $37, $45, $42, $4b, $62, $46, $51, $62
    db $46, $50, $ef, $ee, $52, $4b, $43, $4c, $4f, $44, $46, $53, $3e, $3f, $49, $42
    db $63, $fa, $f7, $ef, $ee, $2b, $3e, $4f, $44, $4c, $4b, $a3, $2c, $62, $54, $46
    db $49, $49, $ef, $ee, $51, $42, $3e, $40, $45, $62, $56, $4c, $52, $62, $45, $4c
    db $54, $fa, $f7, $ef, $ee, $43, $4c, $4c, $49, $46, $50, $45, $62, $56, $4c, $52
    db $62, $3e, $4f, $42, $63, $ef, $ee, $f7, $f0
TextStr_49_66a2:           ; id $0584
    ; "Hargon:Then you should know, / Hargon:I'm the great oracle of / the god, Hargon!"
    db $ea, $2b, $3e, $4f, $44, $4c, $4b, $a3, $37, $45, $42, $4b, $62, $56, $4c, $52
    db $62, $ef, $ee, $50, $45, $4c, $52, $49, $41, $62, $48, $4b, $4c, $54, $5e, $fa
    db $f7, $ef, $ee, $2b, $3e, $4f, $44, $4c, $4b, $a3, $2c, $6a, $62, $51, $45, $42
    db $ef, $ee, $44, $4f, $42, $3e, $51, $62, $4c, $4f, $3e, $40, $49, $42, $62, $4c
    db $43, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $44, $4c, $41, $5e, $62, $2b, $3e
    db $4f, $44, $4c, $4b, $63, $ef, $ee, $f7, $f0
TextStr_49_66fb:           ; id $0585
    ; "Hargon:You again! / Hargon:Insolant fool! You forget / your station! / Hargon:I will crush you like / an insect!"
    db $ea, $2b, $3e, $4f, $44, $4c, $4b, $a3, $3c, $4c, $52, $62, $3e, $44, $3e, $46
    db $4b, $63, $ef, $ee, $fa, $f7, $ef, $ee, $2b, $3e, $4f, $44, $4c, $4b, $a3, $2c
    db $4b, $50, $4c, $49, $3e, $4b, $51, $ef, $ee, $43, $4c, $4c, $49, $63, $62, $3c
    db $4c, $52, $62, $43, $4c, $4f, $44, $42, $51, $fa, $f7, $ef, $ee, $56, $4c, $52
    db $4f, $62, $50, $51, $3e, $51, $46, $4c, $4b, $63, $ef, $ee, $fa, $f7, $ef, $ee
    db $2b, $3e, $4f, $44, $4c, $4b, $a3, $2c, $62, $54, $46, $49, $49, $62, $ef, $ee
    db $40, $4f, $52, $50, $45, $62, $56, $4c, $52, $62, $49, $46, $48, $42, $fa, $f7
    db $ef, $ee, $3e, $4b, $62, $46, $4b, $50, $42, $40, $51, $63, $ef, $ee, $f7, $f0
TextStr_49_677b:           ; id $0586
    ; "Hargon:To my vex... / Hargon:the great Hargon was / defeated by such a thing. / Hargon:I'm shocked but I have to / admit your power... / Har..."
    db $ea, $2b, $3e, $4f, $44, $4c, $4b, $a3, $37, $4c, $62, $4a, $56, $ef, $ee, $53
    db $42, $55, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $2b, $3e, $4f, $44, $4c, $4b, $a3
    db $51, $45, $42, $62, $44, $4f, $42, $3e, $51, $ef, $ee, $2b, $3e, $4f, $44, $4c
    db $4b, $62, $54, $3e, $50, $fa, $f7, $ef, $ee, $41, $42, $43, $42, $3e, $51, $42
    db $41, $62, $3f, $56, $62, $50, $52, $40, $45, $ef, $ee, $3e, $62, $51, $45, $46
    db $4b, $44, $5f, $fa, $f7, $ef, $ee, $2b, $3e, $4f, $44, $4c, $4b, $a3, $2c, $6a
    db $62, $50, $45, $4c, $40, $48, $42, $41, $ef, $ee, $3f, $52, $51, $62, $2c, $62
    db $45, $3e, $53, $42, $62, $51, $4c, $fa, $f7, $ef, $ee, $3e, $41, $4a, $46, $51
    db $62, $56, $4c, $52, $4f, $ef, $ee, $4d, $4c, $54, $42, $4f, $5f, $5f, $5f, $fa
    db $f7, $ef, $ee, $2b, $3e, $4f, $44, $4c, $4b, $a3, $2b, $4c, $54, $42, $53, $42
    db $4f, $63, $ef, $ee, $fa, $f7, $ef, $ee, $2b, $3e, $4f, $44, $4c, $4b, $a3, $35
    db $42, $4a, $42, $4a, $3f, $42, $4f, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $2b, $3e, $4f, $44, $4c, $4b, $a3, $36, $4c, $4a, $42, $62, $51, $45, $46, $4b
    db $44, $50, $ef, $ee, $42, $55, $46, $50, $51, $62, $46, $4b, $62, $51, $45, $46
    db $50, $fa, $f7, $ef, $ee, $54, $4c, $4f, $49, $41, $62, $51, $45, $3e, $51, $62
    db $56, $4c, $52, $ef, $ee, $40, $3e, $4b, $4b, $4c, $51, $62, $3f, $42, $3e, $51
    db $63, $f7, $f0
TextStr_49_687e:           ; id $0587
    ; "Watabou:Hm? I still smell / monster... / Watabou:Well it doesn't matter! / Let's go back!!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $2b, $4a, $64, $62, $2c, $ef, $ee
    db $50, $51, $46, $49, $49, $62, $50, $4a, $42, $49, $49, $fa, $f7, $ef, $ee, $4a
    db $4c, $4b, $50, $51, $42, $4f, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $3a
    db $3e, $51, $3e, $3f, $4c, $52, $a3, $3a, $42, $49, $49, $62, $46, $51, $ef, $ee
    db $41, $4c, $42, $50, $4b, $67, $62, $4a, $3e, $51, $51, $42, $4f, $63, $fa, $f7
    db $ef, $ee, $2f, $42, $51, $68, $62, $44, $4c, $62, $3f, $3e, $40, $48, $63, $63
    db $ef, $ee, $f7, $f0
TextStr_49_68e2:           ; id $0588
    ; "*:...I...am... the...god...of... / destruc...tion... / *:...Si...doh... / *:I...desire... / Sidoh: DESTRUCTION!!"
    db $ea, $9f, $a3, $5f, $5f, $5f, $2c, $5f, $5f, $5f, $3e, $4a, $5f, $5f, $5f, $ef
    db $ee, $51, $45, $42, $5f, $5f, $5f, $44, $4c, $41, $5f, $5f, $5f, $4c, $43, $5f
    db $5f, $5f, $fa, $f7, $ef, $ee, $41, $42, $50, $51, $4f, $52, $40, $5f, $5f, $5f
    db $51, $46, $4c, $4b, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $5f
    db $5f, $5f, $36, $46, $5f, $5f, $5f, $41, $4c, $45, $5f, $5f, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $2c, $5f, $5f, $5f, $41, $42, $50, $46, $4f, $42, $5f
    db $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $36, $46, $41, $4c, $45, $a3, $ef, $ee
    db $27, $28, $36, $37, $35, $38, $26, $37, $2c, $32, $31, $63, $63, $f7, $f0
TextStr_49_6961:           ; id $0589
    ; "Sidoh:...I... destroy...!!"
    db $ea, $36, $46, $41, $4c, $45, $a3, $5f, $5f, $5f, $2c, $5f, $5f, $5f, $ef, $ee
    db $41, $42, $50, $51, $4f, $4c, $56, $5f, $5f, $5f, $63, $63, $f7, $f0
TextStr_49_697f:           ; id $058A
    ; "Sidoh:............"
    db $ea, $36, $46, $41, $4c, $45, $a3, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f
    db $5f, $5f, $5f, $ef, $ee, $f7, $f0
TextStr_49_6996:           ; id $058B
    ; "Watabou:There was a monster / still here. / Watabou:Let's go back!!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $37, $45, $42, $4f, $42, $ef, $ee
    db $54, $3e, $50, $62, $3e, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $fa, $f7
    db $ef, $ee, $50, $51, $46, $49, $49, $62, $45, $42, $4f, $42, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $2f, $42, $51, $68, $ef
    db $ee, $44, $4c, $62, $3f, $3e, $40, $48, $63, $63, $f7, $f0
TextStr_49_69e2:           ; id $058C
    ; "*:At last you came here, pathetic / thing! / *:How dare you forget your / status, / *:and disobey the great lord of / evil, Baramos. / Baram..."
    db $ea, $9f, $a3, $24, $51, $62, $49, $3e, $50, $51, $62, $56, $4c, $52, $62, $40
    db $3e, $4a, $42, $ef, $ee, $45, $42, $4f, $42, $5e, $62, $4d, $3e, $51, $45, $42
    db $51, $46, $40, $62, $fa, $f7, $ef, $ee, $51, $45, $46, $4b, $44, $63, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $2b, $4c, $54, $62, $41, $3e, $4f, $42, $62, $56
    db $4c, $52, $ef, $ee, $43, $4c, $4f, $44, $42, $51, $62, $56, $4c, $52, $4f, $62
    db $fa, $f7, $ef, $ee, $50, $51, $3e, $51, $52, $50, $5e, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $3e, $4b, $41, $62, $41, $46, $50, $4c, $3f, $42, $56, $62, $51
    db $45, $42, $ef, $ee, $44, $4f, $42, $3e, $51, $62, $49, $4c, $4f, $41, $62, $4c
    db $43, $62, $fa, $f7, $ef, $ee, $42, $53, $46, $49, $5e, $62, $25, $3e, $4f, $3e
    db $4a, $4c, $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $25, $3e, $4f, $3e, $4a, $4c
    db $50, $a3, $3c, $4c, $52, $62, $54, $46, $49, $49, $ef, $ee, $4f, $42, $44, $4f
    db $42, $51, $62, $51, $45, $3e, $51, $62, $56, $4c, $52, $62, $fa, $f7, $ef, $ee
    db $40, $3e, $4a, $42, $62, $45, $42, $4f, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $25, $3e, $4f, $3e, $4a, $4c, $50, $a3, $2c, $62, $54, $46, $49, $49, $62, $ef
    db $ee, $42, $3e, $51, $62, $56, $4c, $52, $4f, $62, $44, $52, $51, $50, $a4, $fa
    db $f7, $ef, $ee, $25, $3e, $4f, $3e, $4a, $4c, $50, $a3, $50, $4c, $62, $56, $4c
    db $52, $ef, $ee, $40, $3e, $4b, $67, $62, $3f, $42, $62, $3f, $4f, $4c, $52, $44
    db $45, $51, $fa, $f7, $ef, $ee, $3f, $3e, $40, $48, $62, $51, $4c, $62, $49, $46
    db $43, $42, $62, $42, $53, $42, $4f, $ef, $ee, $3e, $44, $3e, $46, $4b, $63, $f7
    db $f0
TextStr_49_6b13:           ; id $058D
    ; "Baramos:Fool! You still disobey me! / Baramos:That's going too far. / Hm, but it doesn't matter, / Baramos:No matter how many times you / co..."
    db $ea, $25, $3e, $4f, $3e, $4a, $4c, $50, $a3, $29, $4c, $4c, $49, $63, $62, $3c
    db $4c, $52, $ef, $ee, $50, $51, $46, $49, $49, $62, $41, $46, $50, $4c, $3f, $42
    db $56, $62, $4a, $42, $63, $fa, $f7, $ef, $ee, $25, $3e, $4f, $3e, $4a, $4c, $50
    db $a3, $37, $45, $3e, $51, $68, $62, $ef, $ee, $44, $4c, $46, $4b, $44, $62, $51
    db $4c, $4c, $62, $43, $3e, $4f, $5f, $62, $fa, $f7, $ef, $ee, $2b, $4a, $5e, $62
    db $3f, $52, $51, $62, $46, $51, $62, $41, $4c, $42, $50, $4b, $67, $ef, $ee, $4a
    db $3e, $51, $51, $42, $4f, $5e, $fa, $f7, $ef, $ee, $25, $3e, $4f, $3e, $4a, $4c
    db $50, $a3, $31, $4c, $62, $4a, $3e, $51, $51, $42, $4f, $ef, $ee, $45, $4c, $54
    db $62, $4a, $3e, $4b, $56, $62, $51, $46, $4a, $42, $50, $62, $56, $4c, $52, $fa
    db $f7, $ef, $ee, $40, $4c, $4a, $42, $62, $3f, $3e, $40, $48, $5e, $62, $46, $51
    db $ef, $ee, $54, $4c, $4b, $67, $62, $4a, $3e, $48, $42, $62, $3e, $4b, $56, $fa
    db $f7, $ef, $ee, $41, $46, $43, $43, $42, $4f, $42, $4b, $40, $42, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $25, $3e, $4f, $3e, $4a, $4c, $50, $a3, $2c, $62, $54, $46
    db $49, $49, $ef, $ee, $51, $42, $3e, $40, $45, $62, $56, $4c, $52, $62, $45, $4c
    db $54, $fa, $f7, $ef, $ee, $44, $4f, $42, $3e, $51, $62, $2c, $62, $3e, $4a, $63
    db $ef, $ee, $f7, $f0
TextStr_49_6c07:           ; id $058E
    ; "Baramos:Arhg... y..you... / Baramos:How dare you..."
    db $ea, $25, $3e, $4f, $3e, $4a, $4c, $50, $a3, $24, $4f, $45, $44, $5f, $5f, $5f
    db $ef, $ee, $56, $5f, $5f, $56, $4c, $52, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $25
    db $3e, $4f, $3e, $4a, $4c, $50, $a3, $2b, $4c, $54, $62, $41, $3e, $4f, $42, $ef
    db $ee, $56, $4c, $52, $5f, $5f, $5f, $f7, $f0
TextStr_49_6c40:           ; id $058F
    ; "Watabou: Excellent [HERO]. / Leeet's go back!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $ef, $ee, $28, $55, $40, $42, $49
    db $49, $42, $4b, $51, $62, $f6, $5f, $fa, $f7, $ef, $ee, $2f, $42, $42, $42, $51
    db $68, $62, $44, $4c, $62, $3f, $3e, $40, $48, $63, $ef, $ee, $f7, $f0
TextStr_49_6c6e:           ; id $0590
    ; "*:Welcome to my altar of / sacrifice! / *:I am the Zoma who annihilates / all! / Zoma:I will sacri- fice everyone, / Zoma:and cover the enti..."
    db $ea, $9f, $a3, $3a, $42, $49, $40, $4c, $4a, $42, $62, $51, $4c, $62, $4a, $56
    db $ef, $ee, $3e, $49, $51, $3e, $4f, $62, $4c, $43, $62, $fa, $f7, $ef, $ee, $50
    db $3e, $40, $4f, $46, $43, $46, $40, $42, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $2c, $62, $3e, $4a, $62, $51, $45, $42, $62, $3d, $4c, $4a, $3e, $ef, $ee
    db $54, $45, $4c, $62, $3e, $4b, $4b, $46, $45, $46, $49, $3e, $51, $42, $50, $62
    db $fa, $f7, $ef, $ee, $3e, $49, $49, $63, $ef, $ee, $fa, $f7, $ef, $ee, $3d, $4c
    db $4a, $3e, $a3, $2c, $62, $54, $46, $49, $49, $62, $50, $3e, $40, $4f, $46, $9c
    db $ef, $ee, $43, $46, $40, $42, $62, $42, $53, $42, $4f, $56, $4c, $4b, $42, $5e
    db $fa, $f7, $ef, $ee, $3d, $4c, $4a, $3e, $a3, $3e, $4b, $41, $62, $40, $4c, $53
    db $42, $4f, $62, $51, $45, $42, $ef, $ee, $42, $4b, $51, $46, $4f, $42, $62, $54
    db $4c, $4f, $49, $41, $62, $54, $46, $51, $45, $62, $fa, $f7, $ef, $ee, $41, $42
    db $50, $4d, $3e, $46, $4f, $63, $ef, $ee, $fa, $f7, $ef, $ee, $3d, $4c, $4a, $3e
    db $a3, $3a, $45, $56, $62, $50, $45, $4c, $52, $49, $41, $62, $ef, $ee, $56, $4c
    db $52, $62, $50, $51, $4f, $52, $44, $44, $49, $42, $62, $51, $4c, $62, $fa, $f7
    db $ef, $ee, $49, $46, $53, $42, $64, $ef, $ee, $fa, $f7, $ef, $ee, $3d, $4c, $4a
    db $3e, $a3, $24, $4b, $4b, $46, $45, $46, $49, $3e, $51, $46, $4c, $4b, $ef, $ee
    db $46, $50, $62, $4a, $56, $62, $47, $4c, $56, $5f, $62, $27, $42, $3e, $51, $45
    db $fa, $f7, $ef, $ee, $46, $50, $62, $3f, $42, $3e, $52, $51, $56, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $3d, $4c, $4a, $3e, $a3, $31, $4c, $54, $5e, $62, $51, $3e
    db $48, $42, $62, $ef, $ee, $56, $4c, $52, $4f, $62, $49, $3e, $50, $51, $62, $3f
    db $4f, $42, $3e, $51, $45, $fa, $f7, $ef, $ee, $46, $4b, $62, $4a, $56, $62, $3e
    db $4f, $4a, $50, $63, $ef, $ee, $f7, $f0
TextStr_49_6dc6:           ; id $0591
    ; "Zoma:Hmm, you seem to never learn. / Zoma:But no matter how hard you try, / it'll be the same. / Zoma:Die so people will see your / miserabl..."
    db $ea, $3d, $4c, $4a, $3e, $a3, $2b, $4a, $4a, $5e, $62, $56, $4c, $52, $62, $50
    db $42, $42, $4a, $ef, $ee, $51, $4c, $62, $4b, $42, $53, $42, $4f, $62, $49, $42
    db $3e, $4f, $4b, $5f, $fa, $f7, $ef, $ee, $3d, $4c, $4a, $3e, $a3, $25, $52, $51
    db $62, $4b, $4c, $62, $4a, $3e, $51, $51, $42, $4f, $ef, $ee, $45, $4c, $54, $62
    db $45, $3e, $4f, $41, $62, $56, $4c, $52, $62, $51, $4f, $56, $5e, $62, $fa, $f7
    db $ef, $ee, $46, $51, $66, $49, $62, $3f, $42, $62, $51, $45, $42, $62, $50, $3e
    db $4a, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $3d, $4c, $4a, $3e, $a3, $27, $46
    db $42, $62, $50, $4c, $62, $4d, $42, $4c, $4d, $49, $42, $ef, $ee, $54, $46, $49
    db $49, $62, $50, $42, $42, $62, $56, $4c, $52, $4f, $62, $fa, $f7, $ef, $ee, $4a
    db $46, $50, $42, $4f, $3e, $3f, $49, $42, $62, $40, $4c, $4f, $4d, $50, $42, $ef
    db $ee, $3e, $51, $62, $4a, $56, $62, $43, $42, $42, $51, $63, $63, $f7, $f0
TextStr_49_6e75:           ; id $0592
    ; "Zoma:...What is your name... son? / Zoma:I see, [HERO]. / Zoma:[HERO]... Well done / defeating me. / Zoma:But as long as there is light, / t..."
    db $ea, $3d, $4c, $4a, $3e, $a3, $5f, $5f, $5f, $3a, $45, $3e, $51, $62, $46, $50
    db $ef, $ee, $56, $4c, $52, $4f, $62, $4b, $3e, $4a, $42, $5f, $5f, $5f, $62, $50
    db $4c, $4b, $64, $fa, $f7, $ef, $ee, $3d, $4c, $4a, $3e, $a3, $2c, $62, $50, $42
    db $42, $5e, $62, $ef, $ee, $f6, $5f, $fa, $f7, $ef, $ee, $3d, $4c, $4a, $3e, $a3
    db $f6, $5f, $5f, $5f, $ef, $ee, $3a, $42, $49, $49, $62, $41, $4c, $4b, $42, $62
    db $fa, $f7, $ef, $ee, $41, $42, $43, $42, $3e, $51, $46, $4b, $44, $62, $4a, $42
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $3d, $4c, $4a, $3e, $a3, $25, $52, $51, $62
    db $3e, $50, $62, $49, $4c, $4b, $44, $ef, $ee, $3e, $50, $62, $51, $45, $42, $4f
    db $42, $62, $46, $50, $62, $49, $46, $44, $45, $51, $5e, $fa, $f7, $ef, $ee, $51
    db $45, $42, $62, $41, $3e, $4f, $48, $4b, $42, $50, $50, $62, $ef, $ee, $42, $55
    db $46, $50, $51, $50, $5f, $fa, $f7, $ef, $ee, $3d, $4c, $4a, $3e, $a3, $24, $50
    db $62, $56, $4c, $52, $62, $3f, $42, $40, $4c, $4a, $42, $ef, $ee, $50, $51, $4f
    db $4c, $4b, $44, $42, $4f, $5e, $62, $3e, $4b, $62, $42, $53, $42, $4b, $62, $fa
    db $f7, $ef, $ee, $4a, $4c, $4f, $42, $62, $4d, $4c, $54, $42, $4f, $43, $52, $49
    db $62, $ef, $ee, $3f, $42, $46, $4b, $44, $5e, $fa, $f7, $ef, $ee, $3d, $4c, $4a
    db $3e, $a3, $54, $46, $49, $49, $62, $40, $4c, $4b, $43, $4f, $4c, $4b, $51, $ef
    db $ee, $56, $4c, $52, $5f, $5f, $5f, $63, $f7, $f0
TextStr_49_6f7f:           ; id $0593
    ; "Watabou:There're lots of strong / monsters! Let's go back!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $37, $45, $42, $4f, $42, $69, $42
    db $ef, $ee, $49, $4c, $51, $50, $62, $4c, $43, $62, $50, $51, $4f, $4c, $4b, $44
    db $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $63, $ef, $ee, $2f
    db $42, $51, $68, $62, $44, $4c, $62, $3f, $3e, $40, $48, $63, $f7, $f0
TextStr_49_6fbd:           ; id $0594
    ; "*:Gwwrrrr...! Who are you? / *:I am Pizzaro. / *:I have just woken as the King / of the evil lords. / Pizzaro:Arrrggghh! / Pizzaro:I cannot ..."
    db $ea, $9f, $a3, $2a, $54, $54, $4f, $4f, $4f, $4f, $5f, $5f, $5f, $63, $ef, $ee
    db $3a, $45, $4c, $62, $3e, $4f, $42, $62, $56, $4c, $52, $64, $62, $fa, $f7, $ef
    db $ee, $9f, $a3, $2c, $62, $3e, $4a, $62, $33, $46, $57, $57, $3e, $4f, $4c, $5f
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $45, $3e, $53, $42, $62, $47
    db $52, $50, $51, $62, $ef, $ee, $54, $4c, $48, $42, $4b, $62, $3e, $50, $62, $51
    db $45, $42, $62, $2e, $46, $4b, $44, $fa, $f7, $ef, $ee, $4c, $43, $62, $51, $45
    db $42, $62, $42, $53, $46, $49, $62, $49, $4c, $4f, $41, $50, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $33, $46, $57, $57, $3e, $4f, $4c, $a3, $24, $4f, $4f, $4f, $44
    db $44, $44, $45, $45, $63, $ef, $ee, $fa, $f7, $ef, $ee, $33, $46, $57, $57, $3e
    db $4f, $4c, $a3, $2c, $62, $40, $3e, $4b, $4b, $4c, $51, $ef, $ee, $4f, $42, $4a
    db $42, $4a, $3f, $42, $4f, $62, $fa, $f7, $ef, $ee, $3e, $4b, $56, $51, $45, $46
    db $4b, $44, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $33, $46, $57, $57, $3e
    db $4f, $4c, $a3, $25, $52, $51, $63, $ef, $ee, $fa, $f7, $ef, $ee, $33, $46, $57
    db $57, $3e, $4f, $4c, $a3, $2c, $62, $48, $4b, $4c, $54, $62, $ef, $ee, $54, $45
    db $3e, $51, $62, $51, $4c, $62, $41, $4c, $5f, $fa, $f7, $ef, $ee, $33, $46, $57
    db $57, $3e, $4f, $4c, $a3, $27, $4c, $62, $56, $4c, $52, $ef, $ee, $52, $4b, $41
    db $42, $4f, $50, $51, $3e, $4b, $41, $64, $ff, $f0
TextStr_49_70c7:           ; id $0595
    ; "Pizzaro:Gwwrrr! Regret showing / yourself… / Pizzaro:…before me!"
    db $ea, $33, $46, $57, $57, $3e, $4f, $4c, $a3, $2a, $54, $54, $4f, $4f, $4f, $63
    db $ef, $ee, $35, $42, $44, $4f, $42, $51, $62, $50, $45, $4c, $54, $46, $4b, $44
    db $fa, $f7, $ef, $ee, $56, $4c, $52, $4f, $50, $42, $49, $43, $a4, $ef, $ee, $fa
    db $f7, $ef, $ee, $33, $46, $57, $57, $3e, $4f, $4c, $a3, $a4, $3f, $42, $43, $4c
    db $4f, $42, $ef, $ee, $4a, $42, $63, $f7, $f0
TextStr_49_7110:           ; id $0596
    ; "Pizzaro:Then, I will tell you! / Gwrrr...! / Pizzaro:I am here to / annihilate, / Pizzaro:vou humans and the / dirty dogs that flatter you!"
    db $ea, $33, $46, $57, $57, $3e, $4f, $4c, $a3, $37, $45, $42, $4b, $5e, $62, $2c
    db $ef, $ee, $54, $46, $49, $49, $62, $51, $42, $49, $49, $62, $56, $4c, $52, $63
    db $fa, $f7, $ef, $ee, $2a, $54, $4f, $4f, $4f, $5f, $5f, $5f, $63, $ef, $ee, $fa
    db $f7, $ef, $ee, $33, $46, $57, $57, $3e, $4f, $4c, $a3, $2c, $62, $3e, $4a, $62
    db $ef, $ee, $45, $42, $4f, $42, $62, $51, $4c, $62, $fa, $f7, $ef, $ee, $3e, $4b
    db $4b, $46, $45, $46, $49, $3e, $51, $42, $5e, $ef, $ee, $fa, $f7, $ef, $ee, $33
    db $46, $57, $57, $3e, $4f, $4c, $a3, $53, $4c, $52, $ef, $ee, $45, $52, $4a, $3e
    db $4b, $50, $62, $3e, $4b, $41, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $41, $46
    db $4f, $51, $56, $62, $41, $4c, $44, $50, $62, $51, $45, $3e, $51, $ef, $ee, $43
    db $49, $3e, $51, $51, $42, $4f, $62, $56, $4c, $52, $63, $f7, $f0
TextStr_49_71ad:           ; id $0597
    ; "Pizzaro:Gwwrrr...! / Pizzaro:You want to die? [YES/NO]"
    db $ea, $33, $46, $57, $57, $3e, $4f, $4c, $a3, $2a, $54, $54, $4f, $4f, $4f, $5f
    db $5f, $5f, $63, $ef, $ee, $fa, $f7, $ef, $ee, $33, $46, $57, $57, $3e, $4f, $4c
    db $a3, $3c, $4c, $52, $62, $54, $3e, $4b, $51, $ef, $ee, $51, $4c, $62, $41, $46
    db $42, $64, $ff, $f0
TextStr_49_71e1:           ; id $0598
    ; "Pizzaro:Then, die!"
    db $ea, $33, $46, $57, $57, $3e, $4f, $4c, $a3, $37, $45, $42, $4b, $5e, $ef, $ee
    db $41, $46, $42, $63, $f7, $f0
TextStr_49_71f7:           ; id $0599
    ; "Pizzaro:Then, what brought you here! / Pizzaro:You imbecile!!"
    db $ea, $33, $46, $57, $57, $3e, $4f, $4c, $a3, $37, $45, $42, $4b, $5e, $62, $54
    db $45, $3e, $51, $ef, $ee, $3f, $4f, $4c, $52, $44, $45, $51, $62, $56, $4c, $52
    db $62, $45, $42, $4f, $42, $63, $fa, $f7, $ef, $ee, $33, $46, $57, $57, $3e, $4f
    db $4c, $a3, $3c, $4c, $52, $ef, $ee, $46, $4a, $3f, $42, $40, $46, $49, $42, $63
    db $63, $f7, $f0
TextStr_49_723a:           ; id $059A
    ; "Pizzaro:Gwwrr...! My body is / burning...! / Pizzaro:Was I defeated? / Pizzaro:Ro, Rosalie... I, / I..."
    db $ea, $33, $46, $57, $57, $3e, $4f, $4c, $a3, $2a, $54, $54, $4f, $4f, $5f, $5f
    db $5f, $63, $ef, $ee, $30, $56, $62, $3f, $4c, $41, $56, $62, $46, $50, $62, $fa
    db $f7, $ef, $ee, $3f, $52, $4f, $4b, $46, $4b, $44, $5f, $5f, $5f, $63, $ef, $ee
    db $fa, $f7, $ef, $ee, $33, $46, $57, $57, $3e, $4f, $4c, $a3, $3a, $3e, $50, $62
    db $2c, $62, $ef, $ee, $41, $42, $43, $42, $3e, $51, $42, $41, $64, $fa, $f7, $ef
    db $ee, $33, $46, $57, $57, $3e, $4f, $4c, $a3, $35, $4c, $5e, $ef, $ee, $35, $4c
    db $50, $3e, $49, $46, $42, $5f, $5f, $5f, $62, $2c, $5e, $fa, $f7, $ef, $ee, $2c
    db $5f, $5f, $5f, $ef, $ee, $f7, $f0
TextStr_49_72b1:           ; id $059B
    ; "Watabou:Rosalie was Pizzaro's / lover. / Watabou:But poor Rosalie was / tormented by humans then... / Watabou:Pizzaro should be pitied. / Wa..."
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $35, $4c, $50, $3e, $49, $46, $42
    db $ef, $ee, $54, $3e, $50, $62, $33, $46, $57, $57, $3e, $4f, $4c, $68, $fa, $f7
    db $ef, $ee, $49, $4c, $53, $42, $4f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $3a, $3e
    db $51, $3e, $3f, $4c, $52, $a3, $25, $52, $51, $ef, $ee, $4d, $4c, $4c, $4f, $62
    db $35, $4c, $50, $3e, $49, $46, $42, $62, $54, $3e, $50, $fa, $f7, $ef, $ee, $51
    db $4c, $4f, $4a, $42, $4b, $51, $42, $41, $62, $3f, $56, $ef, $ee, $45, $52, $4a
    db $3e, $4b, $50, $62, $51, $45, $42, $4b, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $3a
    db $3e, $51, $3e, $3f, $4c, $52, $a3, $33, $46, $57, $57, $3e, $4f, $4c, $ef, $ee
    db $50, $45, $4c, $52, $49, $41, $62, $3f, $42, $62, $4d, $46, $51, $46, $42, $41
    db $5f, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $2f, $42, $51
    db $68, $ef, $ee, $44, $4c, $62, $3f, $3e, $40, $48, $63, $f7, $f0
TextStr_49_735e:           ; id $059C
    ; "*:Ggggrrr... / *:Who is disturb- ing my rest? / *:I am Esterk... / Esterk:Right now, that's all I / remember... / Esterk:I don't even know i..."
    db $ea, $9f, $a3, $2a, $44, $44, $44, $4f, $4f, $4f, $5f, $5f, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $3a, $45, $4c, $62, $46, $50, $62, $41, $46, $50, $51
    db $52, $4f, $3f, $9c, $ef, $ee, $46, $4b, $44, $62, $4a, $56, $62, $4f, $42, $50
    db $51, $64, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $3e, $4a, $62, $28, $50, $51
    db $42, $4f, $48, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $28, $50, $51, $42
    db $4f, $48, $a3, $35, $46, $44, $45, $51, $62, $4b, $4c, $54, $5e, $ef, $ee, $51
    db $45, $3e, $51, $68, $62, $3e, $49, $49, $62, $2c, $fa, $f7, $ef, $ee, $4f, $42
    db $4a, $42, $4a, $3f, $42, $4f, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $28
    db $50, $51, $42, $4f, $48, $a3, $2c, $62, $41, $4c, $4b, $67, $ef, $ee, $42, $53
    db $42, $4b, $62, $48, $4b, $4c, $54, $62, $46, $43, $5f, $5f, $5f, $fa, $f7, $ef
    db $ee, $28, $50, $51, $42, $4f, $48, $a3, $2c, $62, $3e, $4a, $62, $44, $4c, $4c
    db $41, $ef, $ee, $4c, $4f, $62, $42, $53, $46, $49, $5e, $62, $4b, $4c, $54, $5f
    db $fa, $f7, $ef, $ee, $28, $50, $51, $42, $4f, $48, $a3, $3a, $45, $3e, $51, $62
    db $41, $4c, $ef, $ee, $56, $4c, $52, $62, $54, $3e, $4b, $51, $62, $43, $4f, $4c
    db $4a, $62, $4a, $42, $64, $fa, $f7, $ef, $ee, $28, $50, $51, $42, $4f, $48, $a3
    db $27, $46, $41, $62, $56, $4c, $52, $ef, $ee, $40, $4c, $4a, $42, $62, $51, $4c
    db $62, $41, $42, $50, $51, $4f, $4c, $56, $fa, $f7, $ef, $ee, $4a, $42, $64, $ef
    db $ee, $ff, $f0
TextStr_49_7471:           ; id $059D
    ; "Esterk:Then go away. / Esterk:I will rest. / Esterk:Zzzz.."
    db $ea, $28, $50, $51, $42, $4f, $48, $a3, $37, $45, $42, $4b, $62, $44, $4c, $ef
    db $ee, $3e, $54, $3e, $56, $5f, $fa, $f7, $ef, $ee, $28, $50, $51, $42, $4f, $48
    db $a3, $2c, $62, $54, $46, $49, $49, $62, $ef, $ee, $4f, $42, $50, $51, $5f, $fa
    db $f7, $ef, $ee, $28, $50, $51, $42, $4f, $48, $a3, $3d, $57, $57, $57, $5f, $5f
    db $ef, $ee, $f7, $f0
TextStr_49_74b5:           ; id $059E
    ; "Esterk:There is no choice. / Esterk:I cannot be destroyed. / Esterk:Come on!"
    db $ea, $28, $50, $51, $42, $4f, $48, $a3, $37, $45, $42, $4f, $42, $62, $46, $50
    db $ef, $ee, $4b, $4c, $62, $40, $45, $4c, $46, $40, $42, $5f, $fa, $f7, $ef, $ee
    db $28, $50, $51, $42, $4f, $48, $a3, $2c, $62, $40, $3e, $4b, $4b, $4c, $51, $ef
    db $ee, $3f, $42, $62, $41, $42, $50, $51, $4f, $4c, $56, $42, $41, $5f, $fa, $f7
    db $ef, $ee, $28, $50, $51, $42, $4f, $48, $a3, $26, $4c, $4a, $42, $62, $4c, $4b
    db $63, $ef, $ee, $f7, $f0
TextStr_49_750a:           ; id $059F
    ; "Esterk:Gggrrr... / Esterk:You again... / Esterk:disturbing my rest. / Esterk:What a nuisance. / I am going to make you be quiet!"
    db $ea, $28, $50, $51, $42, $4f, $48, $a3, $2a, $44, $44, $4f, $4f, $4f, $5f, $5f
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $28, $50, $51, $42, $4f, $48, $a3, $3c, $4c
    db $52, $ef, $ee, $3e, $44, $3e, $46, $4b, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $28
    db $50, $51, $42, $4f, $48, $a3, $41, $46, $50, $51, $52, $4f, $3f, $46, $4b, $44
    db $ef, $ee, $4a, $56, $62, $4f, $42, $50, $51, $5f, $fa, $f7, $ef, $ee, $28, $50
    db $51, $42, $4f, $48, $a3, $3a, $45, $3e, $51, $62, $3e, $62, $ef, $ee, $4b, $52
    db $46, $50, $3e, $4b, $40, $42, $5f, $fa, $f7, $ef, $ee, $2c, $62, $3e, $4a, $62
    db $44, $4c, $46, $4b, $44, $62, $51, $4c, $62, $4a, $3e, $48, $42, $ef, $ee, $56
    db $4c, $52, $62, $3f, $42, $62, $4e, $52, $46, $42, $51, $63, $f7, $f0
TextStr_49_7598:           ; id $05A0
    ; "Esterk:Ggggrrr... What's wrong with / me... / Esterk:I can be Defeated?! Somehow / I knew from my long dream that... / Esterk:eventually thi..."
    db $ea, $28, $50, $51, $42, $4f, $48, $a3, $2a, $44, $44, $44, $4f, $4f, $4f, $5f
    db $5f, $5f, $ef, $ee, $3a, $45, $3e, $51, $68, $62, $54, $4f, $4c, $4b, $44, $62
    db $54, $46, $51, $45, $fa, $f7, $ef, $ee, $4a, $42, $5f, $5f, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $28, $50, $51, $42, $4f, $48, $a3, $2c, $62, $40, $3e, $4b, $62
    db $3f, $42, $ef, $ee, $27, $42, $43, $42, $3e, $51, $42, $41, $64, $63, $62, $36
    db $4c, $4a, $42, $45, $4c, $54, $fa, $f7, $ef, $ee, $2c, $62, $48, $4b, $42, $54
    db $62, $43, $4f, $4c, $4a, $62, $4a, $56, $ef, $ee, $49, $4c, $4b, $44, $62, $41
    db $4f, $42, $3e, $4a, $62, $51, $45, $3e, $51, $5f, $5f, $5f, $fa, $f7, $ef, $ee
    db $28, $50, $51, $42, $4f, $48, $a3, $42, $53, $42, $4b, $51, $52, $3e, $49, $49
    db $56, $62, $ef, $ee, $51, $45, $46, $50, $62, $54, $4c, $52, $49, $41, $62, $45
    db $3e, $4d, $4d, $42, $4b, $5f, $f7, $f0
TextStr_49_7640:           ; id $05A1
    ; "Watabou:Even if we're in a dream, / Watabou:it doesn't matter / as long as [HERO]'s trying / hard! / Watabou:Let's go back!!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $28, $53, $42, $4b, $62, $46, $43
    db $ef, $ee, $54, $42, $69, $42, $62, $46, $4b, $62, $3e, $62, $41, $4f, $42, $3e
    db $4a, $5e, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $46, $51
    db $ef, $ee, $41, $4c, $42, $50, $4b, $67, $62, $4a, $3e, $51, $51, $42, $4f, $fa
    db $f7, $ef, $ee, $3e, $50, $62, $49, $4c, $4b, $44, $62, $3e, $50, $ef, $ee, $f6
    db $68, $62, $51, $4f, $56, $46, $4b, $44, $fa, $f7, $ef, $ee, $45, $3e, $4f, $41
    db $63, $ef, $ee, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $2f
    db $42, $51, $68, $62, $44, $4c, $ef, $ee, $3f, $3e, $40, $48, $63, $63, $f7, $f0
TextStr_49_76c0:           ; id $05A2
    ; "*:At last, you came here. / *:The Monster Master [HERO] and / his companions! / *:You must know who I am? [YES/NO]"
    db $ea, $9f, $a3, $24, $51, $62, $49, $3e, $50, $51, $5e, $62, $56, $4c, $52, $62
    db $ef, $ee, $40, $3e, $4a, $42, $62, $45, $42, $4f, $42, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $37, $45, $42, $62, $30, $4c, $4b, $50, $51, $42, $4f, $ef, $ee, $30
    db $3e, $50, $51, $42, $4f, $62, $f6, $62, $3e, $4b, $41, $fa, $f7, $ef, $ee, $45
    db $46, $50, $62, $40, $4c, $4a, $4d, $3e, $4b, $46, $4c, $4b, $50, $63, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $62, $4a, $52, $50, $51, $62, $48
    db $4b, $4c, $54, $ef, $ee, $54, $45, $4c, $62, $2c, $62, $3e, $4a, $64, $ff, $f0
TextStr_49_7730:           ; id $05A3
    ; "*:Ha ha ha!! You have good / intentions. / *:The King of the evil lords, & / the King of Kings, / *:I am Mirudraas! / Mirudoraas: Come on! /..."
    db $ea, $9f, $a3, $2b, $3e, $62, $45, $3e, $62, $45, $3e, $63, $63, $ef, $ee, $3c
    db $4c, $52, $62, $45, $3e, $53, $42, $62, $44, $4c, $4c, $41, $fa, $f7, $ef, $ee
    db $46, $4b, $51, $42, $4b, $51, $46, $4c, $4b, $50, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $37, $45, $42, $62, $2e, $46, $4b, $44, $62, $4c, $43, $62, $ef
    db $ee, $51, $45, $42, $62, $42, $53, $46, $49, $62, $49, $4c, $4f, $41, $50, $5e
    db $62, $b6, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $2e, $46, $4b, $44, $62, $4c
    db $43, $62, $2e, $46, $4b, $44, $50, $5e, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $2c, $62, $3e, $4a, $62, $30, $46, $4f, $52, $41, $4f, $3e, $3e, $50, $63, $ef
    db $ee, $fa, $f7, $ef, $ee, $30, $46, $4f, $52, $41, $4c, $4f, $3e, $3e, $50, $a3
    db $ef, $ee, $26, $4c, $4a, $42, $62, $4c, $4b, $63, $fa, $f7, $ef, $ee, $30, $46
    db $4f, $52, $41, $4c, $4f, $3e, $3e, $50, $a3, $2c, $66, $49, $ef, $ee, $50, $45
    db $4c, $54, $62, $56, $4c, $52, $62, $54, $45, $56, $62, $2c, $6a, $fa, $f7, $ef
    db $ee, $51, $45, $42, $62, $2e, $46, $4b, $44, $62, $4c, $43, $62, $51, $45, $42
    db $ef, $ee, $42, $53, $46, $49, $62, $49, $4c, $4f, $41, $50, $63, $f7, $f0
TextStr_49_780f:           ; id $05A4
    ; "*:You don't know my name? You fool! / *:The King of the evil lords, & / the King of Kings, / *:I am Mirudraas! / Mirudraas:Come on! / Mirudr..."
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $41, $4c, $4b, $67, $62, $48, $4b, $4c, $54
    db $ef, $ee, $4a, $56, $62, $4b, $3e, $4a, $42, $64, $62, $3c, $4c, $52, $62, $43
    db $4c, $4c, $49, $63, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $2e, $46
    db $4b, $44, $62, $4c, $43, $62, $ef, $ee, $51, $45, $42, $62, $42, $53, $46, $49
    db $62, $49, $4c, $4f, $41, $50, $5e, $62, $b6, $62, $fa, $f7, $ef, $ee, $51, $45
    db $42, $62, $2e, $46, $4b, $44, $62, $4c, $43, $62, $2e, $46, $4b, $44, $50, $5e
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $3e, $4a, $62, $30, $46, $4f
    db $52, $41, $4f, $3e, $3e, $50, $63, $ef, $ee, $fa, $f7, $ef, $ee, $30, $46, $4f
    db $52, $41, $4f, $3e, $3e, $50, $a3, $26, $4c, $4a, $42, $62, $4c, $4b, $63, $ef
    db $ee, $fa, $f7, $ef, $ee, $30, $46, $4f, $52, $41, $4f, $3e, $3e, $50, $a3, $2c
    db $66, $49, $62, $ef, $ee, $50, $45, $4c, $54, $62, $56, $4c, $52, $62, $54, $45
    db $56, $62, $2c, $6a, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $2e, $46, $4b, $44
    db $62, $4c, $43, $62, $51, $45, $42, $62, $ef, $ee, $42, $53, $46, $49, $62, $49
    db $4c, $4f, $41, $50, $63, $f7, $f0
TextStr_49_78e6:           ; id $05A5
    ; "Mirudraas:Ha ha ha! / Mirudraas:Monster Master [HERO] / & company, / Mirudraas:don't disturb me with / such silly things...!"
    db $ea, $30, $46, $4f, $52, $41, $4f, $3e, $3e, $50, $a3, $2b, $3e, $62, $45, $3e
    db $62, $ef, $ee, $45, $3e, $63, $fa, $f7, $ef, $ee, $30, $46, $4f, $52, $41, $4f
    db $3e, $3e, $50, $a3, $30, $4c, $4b, $50, $51, $42, $4f, $62, $ef, $ee, $30, $3e
    db $50, $51, $42, $4f, $62, $f6, $62, $fa, $f7, $ef, $ee, $b6, $62, $40, $4c, $4a
    db $4d, $3e, $4b, $56, $5e, $ef, $ee, $fa, $f7, $ef, $ee, $30, $46, $4f, $52, $41
    db $4f, $3e, $3e, $50, $a3, $41, $4c, $4b, $67, $ef, $ee, $41, $46, $50, $51, $52
    db $4f, $3f, $62, $4a, $42, $62, $54, $46, $51, $45, $fa, $f7, $ef, $ee, $50, $52
    db $40, $45, $62, $50, $46, $49, $49, $56, $62, $ef, $ee, $51, $45, $46, $4b, $44
    db $50, $5f, $5f, $5f, $63, $f7, $f0
TextStr_49_796d:           ; id $05A6
    ; "Mirudraas:How.. could I be / defeated... / Mirudraas:It cannot be. / Mirudraas:Ah ha, It must be a / dream. / Mirudraas:Now, I understand!"
    db $ea, $30, $46, $4f, $52, $41, $4f, $3e, $3e, $50, $a3, $2b, $4c, $54, $5f, $5f
    db $ef, $ee, $40, $4c, $52, $49, $41, $62, $2c, $62, $3f, $42, $62, $fa, $f7, $ef
    db $ee, $41, $42, $43, $42, $3e, $51, $42, $41, $5f, $5f, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $30, $46, $4f, $52, $41, $4f, $3e, $3e, $50, $a3, $2c, $51, $ef, $ee
    db $40, $3e, $4b, $4b, $4c, $51, $62, $3f, $42, $5f, $fa, $f7, $ef, $ee, $30, $46
    db $4f, $52, $41, $4f, $3e, $3e, $50, $a3, $24, $45, $62, $45, $3e, $5e, $ef, $ee
    db $2c, $51, $62, $4a, $52, $50, $51, $62, $3f, $42, $62, $3e, $62, $fa, $f7, $ef
    db $ee, $41, $4f, $42, $3e, $4a, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $30, $46, $4f
    db $52, $41, $4f, $3e, $3e, $50, $a3, $31, $4c, $54, $5e, $ef, $ee, $2c, $62, $52
    db $4b, $41, $42, $4f, $50, $51, $3e, $4b, $41, $63, $f7, $f0
TextStr_49_7a09:           ; id $05A7
    ; "Watabou:You really became / strong. Now, let's go back!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $3c, $4c, $52, $ef, $ee, $4f, $42
    db $3e, $49, $49, $56, $62, $3f, $42, $40, $3e, $4a, $42, $62, $fa, $f7, $ef, $ee
    db $50, $51, $4f, $4c, $4b, $44, $5f, $62, $31, $4c, $54, $5e, $62, $ef, $ee, $49
    db $42, $51, $68, $62, $44, $4c, $62, $3f, $3e, $40, $48, $63, $f7, $f0
TextStr_49_7a47:           ; id $05A8
    ; "*:Welcome, you worthless... / *:I am Mudou. You must know that. [YES/NO]"
    db $ea, $9f, $a3, $3a, $42, $49, $40, $4c, $4a, $42, $5e, $62, $56, $4c, $52, $ef
    db $ee, $54, $4c, $4f, $51, $45, $49, $42, $50, $50, $5f, $5f, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $2c, $62, $3e, $4a, $62, $30, $52, $41, $4c, $52, $5f, $62, $3c
    db $4c, $52, $62, $ef, $ee, $4a, $52, $50, $51, $62, $48, $4b, $4c, $54, $62, $51
    db $45, $3e, $51, $5f, $62, $ff, $f0
TextStr_49_7a8e:           ; id $05A9
    ; "Mudou:Hm? You already know my / name, right? [YES/NO]"
    db $ea, $30, $52, $41, $4c, $52, $a3, $2b, $4a, $64, $62, $3c, $4c, $52, $62, $ef
    db $ee, $3e, $49, $4f, $42, $3e, $41, $56, $62, $48, $4b, $4c, $54, $62, $4a, $56
    db $fa, $f7, $ef, $ee, $4b, $3e, $4a, $42, $5e, $62, $4f, $46, $44, $45, $51, $64
    db $ef, $ee, $ff, $f0
TextStr_49_7ac2:           ; id $05AA
    ; "Mudou:Fine. Now, / Mudou:are you prepared? [YES/NO]"
    db $ea, $30, $52, $41, $4c, $52, $a3, $29, $46, $4b, $42, $5f, $ef, $ee, $31, $4c
    db $54, $5e, $fa, $f7, $ef, $ee, $30, $52, $41, $4c, $52, $a3, $3e, $4f, $42, $62
    db $56, $4c, $52, $ef, $ee, $4d, $4f, $42, $4d, $3e, $4f, $42, $41, $64, $ff, $f0
TextStr_49_7af2:           ; id $05AB
    ; "Mudou:Huh? Did you prepare your / coffins for your eternal sleep? [YES/NO]"
    db $ea, $30, $52, $41, $4c, $52, $a3, $2b, $52, $45, $64, $62, $27, $46, $41, $62
    db $56, $4c, $52, $ef, $ee, $4d, $4f, $42, $4d, $3e, $4f, $42, $62, $56, $4c, $52
    db $4f, $fa, $f7, $ef, $ee, $40, $4c, $43, $43, $46, $4b, $50, $62, $43, $4c, $4f
    db $62, $56, $4c, $52, $4f, $ef, $ee, $42, $51, $42, $4f, $4b, $3e, $49, $62, $50
    db $49, $42, $42, $4d, $64, $ff, $f0
TextStr_49_7b39:           ; id $05AC
    ; "Mudou:Fine. Let's begin."
    db $ea, $30, $52, $41, $4c, $52, $a3, $29, $46, $4b, $42, $5f, $ef, $ee, $2f, $42
    db $51, $68, $62, $3f, $42, $44, $46, $4b, $5f, $f7, $f0
TextStr_49_7b54:           ; id $05AD
    ; "Mudou:Annoying worthless things. / I'll exterminate you."
    db $ea, $30, $52, $41, $4c, $52, $a3, $24, $4b, $4b, $4c, $56, $46, $4b, $44, $ef
    db $ee, $54, $4c, $4f, $51, $45, $49, $42, $50, $50, $62, $51, $45, $46, $4b, $44
    db $50, $5f, $fa, $f7, $ef, $ee, $2c, $66, $49, $62, $42, $55, $51, $42, $4f, $4a
    db $46, $4b, $3e, $51, $42, $ef, $ee, $56, $4c, $52, $5f, $f7, $f0
TextStr_49_7b91:           ; id $05AE
    ; "Mudou:I was beaten by worthless... / it means... / Mudou:I am less than worthless...?"
    db $ea, $30, $52, $41, $4c, $52, $a3, $2c, $62, $54, $3e, $50, $62, $3f, $42, $3e
    db $51, $42, $4b, $ef, $ee, $3f, $56, $62, $54, $4c, $4f, $51, $45, $49, $42, $50
    db $50, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $46, $51, $62, $4a, $42, $3e, $4b, $50
    db $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $30, $52, $41, $4c, $52, $a3, $2c
    db $62, $3e, $4a, $62, $49, $42, $50, $50, $ef, $ee, $51, $45, $3e, $4b, $62, $54
    db $4c, $4f, $51, $45, $49, $42, $50, $50, $5f, $5f, $5f, $64, $f7, $f0
TextStr_49_7bef:           ; id $05AF
    ; "Watabou:Well, shall we go back?"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $3a, $42, $49, $49, $5e, $ef, $ee
    db $50, $45, $3e, $49, $49, $62, $54, $42, $62, $44, $4c, $62, $3f, $3e, $40, $48
    db $64, $f7, $f0, $00
; --- END re-sectioned text run (bank $49) ---
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

