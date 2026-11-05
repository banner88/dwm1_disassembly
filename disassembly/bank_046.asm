; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $046", ROMX[$4000], BANK[$46]

    db $46 ; Bank number

    ; Cross-bank dispatch table (148 entries)
    ; Called via: ld hl, $46XX / rst $10
    dw LoadB46_4129                  ; Entry 0
    dw TextRunB46_4146               ; Entry 1
    dw TextShowRefreshB46_4163       ; Entry 2
    dw $4009                          ; Entry 3 — mode 0 -> table $4009 (mode list $4007)
    dw TextStr_46_4180               ; Entry 4 — [table $4009]; text $0300 "*:Hey, little thief, I think it's…"
    dw TextStr_46_41bb               ; Entry 5 — text $0301 "*:You snuck in here because I'm s…"
    dw TextStr_46_41f5               ; Entry 6 — text $0302 "*:Then you must be a master who's…"
    dw TextStr_46_4231               ; Entry 7 — text $0303 "*:You sure don't know how to beha…"
    dw TextStr_46_4292               ; Entry 8 — text $0304 "*:Eeek! I cannot stand you! *:I'm…"
    dw TextStr_46_42d5               ; Entry 9 — text $0305 "*:You again!? I'm really gonna ge…"
    dw TextStr_46_4308               ; Entry 10 — text $0306 "*:You don't seem to be a bad guy …"
    dw TextStr_46_4359               ; Entry 11 — text $0307 "*:It can't be! My Betty is... *:a…"
    dw TextStr_46_43a5               ; Entry 12 — text $0308 "*:Betty was actually a CopyCat! N…"
    dw TextStr_46_43d9               ; Entry 13 — text $0309 "*:The quake of GreatTree must hav…"
    dw TextStr_46_442a               ; Entry 14 — text $030A "*:What? You can't even beat my br…"
    dw TextStr_46_44a4               ; Entry 15 — text $030B "*:Ready! Rock-Paper- Scissors... …"
    dw TextStr_46_44d1               ; Entry 16 — text $030C "*:You...You are one tough kid!! *…"
    dw TextStr_46_456e               ; Entry 17 — text $030D "*:Go to one of my brothers! Somet…"
    dw TextStr_46_45bd               ; Entry 18 — text $030E "*:May I help you [HERO]! I heard …"
    dw TextStr_46_4671               ; Entry 19 — text $030F "*:Foreign masters have many kinds…"
    dw TextStr_46_4760               ; Entry 20 — text $0310 "*:How do you do? My name is May. …"
    dw TextStr_46_47d2               ; Entry 21 — text $0311 "[HERO] pulled the arm of the slot…"
    dw TextStr_46_4835               ; Entry 22 — text $0312 "The slot machine is out of order."
    dw TextStr_46_4859               ; Entry 23 — text $0313 "There are 3 Slimes sleeping insid…"
    dw TextStr_46_487f               ; Entry 24 — text $0314 "[HERO] pulled the slot machine! T…"
    dw TextStr_46_4937               ; Entry 25 — text $0315 "[HERO] pulled the arm of the slot…"
    dw TextStr_46_4988               ; Entry 26 — text $0316 "It's out of order."
    dw TextStr_46_499d               ; Entry 27 — text $0317 "3 Metalys are sweating inside the…"
    dw TextStr_46_49cf               ; Entry 28 — text $0318 "[HERO] pulled the arm of the slot…"
    dw TextStr_46_4b14               ; Entry 29 — text $0319 "The reel is spinning..."
    dw TextStr_46_4b2e               ; Entry 30 — text $031A "[HERO] pulled the slot machine! T…"
    dw TextStr_46_4c3e               ; Entry 31 — text $031B "*:What do you say? Why don't you …"
    dw TextStr_46_4c7b               ; Entry 32 — text $031C "*:I'm trying to pick up all the i…"
    dw TextStr_46_4d47               ; Entry 33 — text $031D "*:You, must comply with my next w…"
    dw TextStr_46_4daa               ; Entry 34 — text $031E "*:Here's the Queen of GreatTree. …"
    dw TextStr_46_4e3d               ; Entry 35 — text $031F "*:I'm Medal Man, just a passer-by…"
    dw TextStr_46_4f14               ; Entry 36 — text $0320 "*:Being a master requires trust!"
    dw TextStr_46_4f38               ; Entry 37 — text $0321 "*:Oh! You believe me! As I promis…"
    dw TextStr_46_4f85               ; Entry 38 — text $0322 "There is a sign on the slot machi…"
    dw TextStr_46_4fcf               ; Entry 39 — text $0323 "There is a sign on the slot machi…"
    dw TextStr_46_500e               ; Entry 40 — text $0324 "*:Welcome to the Casino! Gold her…"
    dw TextStr_46_504e               ; Entry 41 — text $0325 "*:How's your luck?"
    dw TextStr_46_5064               ; Entry 42 — text $0326 "*:I need to get good at it."
    dw TextStr_46_5083               ; Entry 43 — text $0327 "*:That customer has an attitude! …"
    dw TextStr_46_50d1               ; Entry 44 — text $0328 "*:No violence in this store."
    dw TextStr_46_50f1               ; Entry 45 — text $0329 "*:Gwrrrrrrrr.. This machine gave …"
    dw TextStr_46_5126               ; Entry 46 — text $032A "*:Gwrrrrrrrr.. Why are you the on…"
    dw TextStr_46_517c               ; Entry 47 — text $032B "*:It's mine now!!"
    dw TextStr_46_5191               ; Entry 48 — text $032C "*:Because you trusted me, I'll gi…"
    dw TextStr_46_5250               ; Entry 49 — text $032D "*:Metaly is a precious monster. *…"
    dw TextStr_46_530c               ; Entry 50 — text $032E "*:[HERO]! Thanks for saving me. *…"
    dw TextStr_46_53a3               ; Entry 51 — text $032F "*:Thank you very much [HERO]!"
    dw TextStr_46_53bf               ; Entry 52 — text $0330 "*Hello [HERO]! I was expecting yo…"
    dw TextStr_46_5410               ; Entry 53 — text $0331 "*:How are you? I'm ready. *:Let's…"
    dw TextStr_46_5462               ; Entry 54 — text $0332 "*:Do you know of the Gate of Wisd…"
    dw TextStr_46_548f               ; Entry 55 — text $0333 "*:If you want to meet the Dragon,…"
    dw TextStr_46_5531               ; Entry 56 — text $0334 "*:Are you familiar with the Gate …"
    dw TextStr_46_5562               ; Entry 57 — text $0335 "*:A bird spins a round on the sta…"
    dw TextStr_46_55c4               ; Entry 58 — text $0336 "*:A mysterious spring where myste…"
    dw TextStr_46_5667               ; Entry 59 — text $0337 "King:Well done, [HERO]! You defea…"
    dw TextStr_46_5717               ; Entry 60 — text $0338 "*:What's wrong? You look pale!"
    dw TextStr_46_5738               ; Entry 61 — text $0339 "*:That man always looks the same …"
    dw TextStr_46_579d               ; Entry 62 — text $033A "King:Well done, [HERO]! You defea…"
    dw TextStr_46_5802               ; Entry 63 — text $033B "King:Well done, [HERO]! You defea…"
    dw TextStr_46_5888               ; Entry 64 — text $033C "*:What? You won C class? Shoo, sh…"
    dw TextStr_46_58cd               ; Entry 65 — text $033D "*:Well done on surviving C class!…"
    dw TextStr_46_5994               ; Entry 66 — text $033E "*:You gotta have MetalCut to defe…"
    dw TextStr_46_5a12               ; Entry 67 — text $033F "*:There's a technique that can pa…"
    dw TextStr_46_5a9f               ; Entry 68 — text $0340 "*:It's strange. My power of Sleep…"
    dw TextStr_46_5af2               ; Entry 69 — text $0341 "*:Well done!! You survived B clas…"
    dw TextStr_46_5ba3               ; Entry 70 — text $0342 "*:Well done!! You survived B clas…"
    dw TextStr_46_5c74               ; Entry 71 — text $0343 "*:The last match will be against …"
    dw TextStr_46_5cbd               ; Entry 72 — text $0344 "*:[HERO]! You're tough! *:Way to …"
    dw TextStr_46_5d21               ; Entry 73 — text $0345 "*:I'm the King of the world!!"
    dw TextStr_46_5d41               ; Entry 74 — text $0346 "*:No luck today! *:Hey, you don't…"
    dw TextStr_46_5dc6               ; Entry 75 — text $0347 "Watabou:Did you have a good time …"
    dw TextStr_46_5e21               ; Entry 76 — text $0348 "*:Ha ha ha! I made Gigantes smug!"
    dw TextStr_46_5e4b               ; Entry 77 — text $0349 "*:Well. You have to find your own…"
    dw TextStr_46_5e7a               ; Entry 78 — text $034A "*:Oh! It's a CurseLamp! Nasty! *:…"
    dw TextStr_46_5edb               ; Entry 79 — text $034B "This is a DEFseed. Use it wisely."
    dw TextStr_46_5f05               ; Entry 80 — text $034C "*:I'm satisfied. Come back when y…"
    dw TextStr_46_5f3e               ; Entry 81 — text $034D "*:Oh! That's Metaly! How shiny! *…"
    dw TextStr_46_5fa0               ; Entry 82 — text $034E "[HERO] read the blackboard. :The …"
    dw TextStr_46_5ff3               ; Entry 83 — text $034F "*:When two of the same kind of mo…"
    dw TextStr_46_60e5               ; Entry 84 — text $0350 "*:I am the Queen of GreatTree. *:…"
    dw TextStr_46_6188               ; Entry 85 — text $0351 "*:Is this an Orc or Pork? Funny?"
    dw TextStr_46_61b1               ; Entry 86 — text $0352 "*:Hee hee! Yo dude, wanna know wh…"
    dw TextStr_46_61f9               ; Entry 87 — text $0353 "*:The last match will be against …"
    dw TextStr_46_62e7               ; Entry 88 — text $0354 "*:BigBang, Hellblast MultiCut....…"
    dw TextStr_46_632d               ; Entry 89 — text $0355 "*:I see. you've grown to be a res…"
    dw TextStr_46_6365               ; Entry 90 — text $0356 "*:Ho ho ho!! They were names of s…"
    dw TextStr_46_639d               ; Entry 91 — text $0357 "*:Even though we are Horks, we do…"
    dw TextStr_46_63d6               ; Entry 92 — text $0358 "*:..Hm. A girl... named San... so…"
    dw TextStr_46_6432               ; Entry 93 — text $0359 "*:Oh, that's a WingSlime! Cute! *…"
    dw TextStr_46_648d               ; Entry 94 — text $035A "*:...but you don't have any more …"
    dw TextStr_46_64fc               ; Entry 95 — text $035B "*:It is a Sirloin. Use it wisely."
    dw TextStr_46_6521               ; Entry 96 — text $035C "*:You, comply with my next wish. …"
    dw TextStr_46_6597               ; Entry 97 — text $035D "*:You're at the Room of Joy and W…"
    dw TextStr_46_6609               ; Entry 98 — text $035E "*:Oooo! Ahhhh! Where am I? *:What…"
    dw TextStr_46_6677               ; Entry 99 — text $035F "*:Hmm. You again? I hope you got …"
    dw TextStr_46_66a8               ; Entry 100 — text $0360 "*:[HERO], why don't you go to the…"
    dw TextStr_46_6718               ; Entry 101 — text $0361 "Do you know of the Gate of Happin…"
    dw TextStr_46_6746               ; Entry 102 — text $0362 "*:In the kingdom I visited, there…"
    dw TextStr_46_680e               ; Entry 103 — text $0363 "*:Are you familiar with the Gate …"
    dw TextStr_46_6846               ; Entry 104 — text $0364 "*:The legend of the village of Li…"
    dw TextStr_46_6902               ; Entry 105 — text $0365 "*:Choose one of the three Gates! …"
    dw TextStr_46_69c7               ; Entry 106 — text $0366 "King:Oh [HERO]! You beat Jamirus.…"
    dw TextStr_46_6a2f               ; Entry 107 — text $0367 "King:[HERO], At ease. King:It's a…"
    dw TextStr_46_6aad               ; Entry 108 — text $0368 "*:Oh [HERO], It's me. The recepti…"
    dw TextStr_46_6b0b               ; Entry 109 — text $0369 "King:Oh [HERO]! You beat Servant!…"
    dw TextStr_46_6ba1               ; Entry 110 — text $036A "King:Oh, [HERO]! You beat Orochi!…"
    dw TextStr_46_6c63               ; Entry 111 — text $036B "*:There must be some reason that.…"
    dw TextStr_46_6cc8               ; Entry 112 — text $036C "*:Hey, the tournament is coming! …"
    dw TextStr_46_6d33               ; Entry 113 — text $036D "*:One of my relatives is living i…"
    dw TextStr_46_6d7b               ; Entry 114 — text $036E "*:To tell the truth, Watabou hasn…"
    dw TextStr_46_6ded               ; Entry 115 — text $036F "*:Bazaar to the right! A third st…"
    dw TextStr_46_6e26               ; Entry 116 — text $0370 "*:You'll always be a loser! What'…"
    dw TextStr_46_6e9b               ; Entry 117 — text $0371 "*:Hey! Down the stairs is the Shr…"
    dw TextStr_46_6f0b               ; Entry 118 — text $0372 "*:Welcome to the Bazaar! There ar…"
    dw TextStr_46_6f4b               ; Entry 119 — text $0373 "*:I love festivals! I'm looking f…"
    dw TextStr_46_6faf               ; Entry 120 — text $0374 "*:This kingdom is becoming more l…"
    dw TextStr_46_701c               ; Entry 121 — text $0375 "*:I heard that wishes on the Star…"
    dw TextStr_46_7081               ; Entry 122 — text $0376 "*:New stores have opened! *:Want …"
    dw TextStr_46_70e1               ; Entry 123 — text $0377 "*:No?! You must be a heck of a ma…"
    dw TextStr_46_711a               ; Entry 124 — text $0378 "*:Sirloin is the tastiest meat in…"
    dw TextStr_46_728b               ; Entry 125 — text $0379 "[HERO] checked out the treasure c…"
    dw TextStr_46_72c5               ; Entry 126 — text $037A "*:Hm.. It seems there are several…"
    dw TextStr_46_7350               ; Entry 127 — text $037B "*:Go left to the Room of Joy & Wi…"
    dw TextStr_46_7443               ; Entry 128 — text $037C "*:The Room of Happiness & Temptat…"
    dw TextStr_46_747d               ; Entry 129 — text $037D "*:Good work! Have you found stron…"
    dw TextStr_46_74eb               ; Entry 130 — text $037E "SMACK! Something hit [HERO] and b…"
    dw TextStr_46_751f               ; Entry 131 — text $037F "*:We monsters become lively when …"
    dw TextStr_46_758f               ; Entry 132 — text $0380 "*:There are monsters with amazing…"
    dw TextStr_46_75f9               ; Entry 133 — text $0381 "*:I heard there is something that…"
    dw TextStr_46_7659               ; Entry 134 — text $0382 "*:Hello. The stable is below here…"
    dw TextStr_46_7708               ; Entry 135 — text $0383 "*:Having a monster read a QuestBk…"
    dw TextStr_46_7840               ; Entry 136 — text $0384 "*:My parents' ancestors were bred…"
    dw TextStr_46_78ab               ; Entry 137 — text $0385 "*:I'm pretty much a coward. *:I w…"
    dw TextStr_46_78ff               ; Entry 138 — text $0386 "*:Down below, behind the Gtae of …"
    dw TextStr_46_7984               ; Entry 139 — text $0387 "*:Copycopy. I wanna copycopy Dead…"
    dw TextStr_46_79fa               ; Entry 140 — text $0388 "*:Hello! I am Helo. *:My former m…"
    dw TextStr_46_7b1b               ; Entry 141 — text $0389 "*:Go up 3 times, left once! ....z…"
    dw TextStr_46_7bb4               ; Entry 142 — text $038A "*:...zzz..."
    dw TextStr_46_7bc4               ; Entry 143 — text $038B "*:There is a man who collects med…"
    dw TextStr_46_7c70               ; Entry 144 — text $038C "*:I feel the strong presence of a…"
    dw TextStr_46_7ce5               ; Entry 145 — text $038D "*:Go right immediately! *:Then yo…"
    dw TextStr_46_7d26               ; Entry 146 — text $038E "*:My hometown is behind the Gate …"
    dw TextStr_46_7d5e               ; Entry 147 — text $038F "*:Have you met the DarkHorn deep …"

LoadB46_4129:
    ld a, [$c823]
    cp $90
    jr c, jr_046_413f

    sub $90
    ld [$c823], a
    ld a, $02
    ld [$c822], a
    ld hl, $1b00
    rst $10
    ret


jr_046_413f:
    ld de, $4007
    call CallTextEngine
    ret


; [S166] copy a text of this bank (RunTextHandler); ids past the bank's range go to its overflow bank (TEXT_SYSTEM "Text id resolution")
TextRunB46_4146:
    ld a, [$c823]
    cp $90
    jr c, jr_046_415c

    sub $90
    ld [$c823], a
    ld a, $02
    ld [$c822], a
    ld hl, $1b01
    rst $10
    ret


jr_046_415c:
    ld de, $4007
    call RunTextHandler
    ret


; [S166] show a text (entry 0) then RequestScreenUpdate
TextShowRefreshB46_4163:
    ld a, [$c823]
    cp $90
    jr c, jr_046_4179

    sub $90
    ld [$c823], a
    ld a, $02
    ld [$c822], a
    ld hl, $1b02
    rst $10
    ret


jr_046_4179:
    call LoadB46_4129
    call RequestScreenUpdate
    ret


; --- BEGIN re-sectioned text run (bank $46: $4180-$7de1) ---
; DTE-encoded dialogue strings, one label per text id (text_id_map.json).
; Labels/comments only; bytes are byte-identical to the original ROM.
TextStr_46_4180:           ; id $0300
    ; "*:Hey, little thief, I think / it's past your bedtime."
    db $eb, $9f, $a3, $2b, $42, $56, $5e, $62, $49, $46, $51, $51, $49, $42, $ef, $ee
    db $51, $45, $46, $42, $43, $5e, $62, $2c, $62, $51, $45, $46, $4b, $48, $fa, $f7
    db $ef, $ee, $46, $51, $68, $62, $4d, $3e, $50, $51, $62, $56, $4c, $52, $4f, $ef
    db $ee, $3f, $42, $41, $51, $46, $4a, $42, $5f, $f7, $f0
TextStr_46_41bb:           ; id $0301
    ; "*:You snuck in here because / I'm so beautiful right? [YES/NO]"
    db $eb, $9f, $a3, $3c, $4c, $52, $62, $50, $4b, $52, $40, $48, $ef, $ee, $46, $4b
    db $62, $45, $42, $4f, $42, $62, $3f, $42, $40, $3e, $52, $50, $42, $fa, $f7, $ef
    db $ee, $2c, $6a, $62, $50, $4c, $62, $3f, $42, $3e, $52, $51, $46, $43, $52, $49
    db $ef, $ee, $4f, $46, $44, $45, $51, $64, $ff, $f0
TextStr_46_41f5:           ; id $0302
    ; "*:Then you must be a master who's / come to capture me? [YES/NO]"
    db $eb, $9f, $a3, $37, $45, $42, $4b, $62, $56, $4c, $52, $62, $4a, $52, $50, $51
    db $ef, $ee, $3f, $42, $62, $3e, $62, $4a, $3e, $50, $51, $42, $4f, $62, $54, $45
    db $4c, $68, $fa, $f7, $ef, $ee, $40, $4c, $4a, $42, $62, $51, $4c, $62, $40, $3e
    db $4d, $51, $52, $4f, $42, $ef, $ee, $4a, $42, $64, $ff, $f0
TextStr_46_4231:           ; id $0303
    ; "*:You sure don't know how to behave / in front of ladies. / *:I'll teach you some respect!!"
    db $eb, $9f, $a3, $3c, $4c, $52, $62, $50, $52, $4f, $42, $62, $41, $4c, $4b, $67
    db $ef, $ee, $48, $4b, $4c, $54, $62, $45, $4c, $54, $62, $51, $4c, $62, $3f, $42
    db $45, $3e, $53, $42, $fa, $f7, $ef, $ee, $46, $4b, $62, $43, $4f, $4c, $4b, $51
    db $62, $4c, $43, $ef, $ee, $49, $3e, $41, $46, $42, $50, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $2c, $66, $49, $62, $51, $42, $3e, $40, $45, $62, $56, $4c, $52, $ef
    db $ee, $50, $4c, $4a, $42, $62, $4f, $42, $50, $4d, $42, $40, $51, $63, $63, $f7
    db $f0
TextStr_46_4292:           ; id $0304
    ; "*:Eeek! I cannot stand you! / *:I'm gonna teach you a lesson!!"
    db $eb, $9f, $a3, $28, $42, $42, $48, $63, $62, $2c, $62, $40, $3e, $4b, $4b, $4c
    db $51, $ef, $ee, $50, $51, $3e, $4b, $41, $62, $56, $4c, $52, $63, $fa, $f7, $ef
    db $ee, $9f, $a3, $2c, $6a, $62, $44, $4c, $4b, $4b, $3e, $62, $51, $42, $3e, $40
    db $45, $ef, $ee, $56, $4c, $52, $62, $3e, $62, $49, $42, $50, $50, $4c, $4b, $63
    db $63, $f7, $f0
TextStr_46_42d5:           ; id $0305
    ; "*:You again!? I'm really gonna / get you now!"
    db $eb, $9f, $a3, $3c, $4c, $52, $62, $3e, $44, $3e, $46, $4b, $63, $64, $ef, $ee
    db $2c, $6a, $62, $4f, $42, $3e, $49, $49, $56, $62, $44, $4c, $4b, $4b, $3e, $fa
    db $f7, $ef, $ee, $44, $42, $51, $62, $56, $4c, $52, $62, $4b, $4c, $54, $63, $ef
    db $ee, $f7, $f0
TextStr_46_4308:           ; id $0306
    ; "*:You don't seem to be a bad guy / after all. I'm beginning to / like you."
    db $eb, $9f, $a3, $3c, $4c, $52, $62, $41, $4c, $4b, $67, $62, $50, $42, $42, $4a
    db $ef, $ee, $51, $4c, $62, $3f, $42, $62, $3e, $62, $3f, $3e, $41, $62, $44, $52
    db $56, $fa, $f7, $ef, $ee, $3e, $43, $51, $42, $4f, $62, $3e, $49, $49, $5f, $62
    db $2c, $6a, $ef, $ee, $3f, $42, $44, $46, $4b, $4b, $46, $4b, $44, $62, $51, $4c
    db $fa, $f7, $ef, $ee, $49, $46, $48, $42, $62, $56, $4c, $52, $5f, $ef, $ee, $f7
    db $f0
TextStr_46_4359:           ; id $0307
    ; "*:It can't be! My Betty is... / *:actually a CopyCat! / Nooooooooo!!"
    db $ea, $9f, $a3, $2c, $51, $62, $40, $3e, $4b, $67, $62, $3f, $42, $63, $ef, $ee
    db $30, $56, $62, $25, $42, $51, $51, $56, $62, $46, $50, $5f, $5f, $5f, $fa, $f7
    db $ef, $ee, $9f, $a3, $3e, $40, $51, $52, $3e, $49, $49, $56, $ef, $ee, $3e, $62
    db $26, $4c, $4d, $56, $26, $3e, $51, $63, $fa, $f7, $ef, $ee, $31, $4c, $4c, $4c
    db $4c, $4c, $4c, $4c, $4c, $4c, $63, $63, $ef, $ee, $f7, $f0
TextStr_46_43a5:           ; id $0308
    ; "*:Betty was actually / a CopyCat! Nooooooooo!!"
    db $ea, $9f, $a3, $25, $42, $51, $51, $56, $62, $54, $3e, $50, $ef, $ee, $3e, $40
    db $51, $52, $3e, $49, $49, $56, $fa, $f7, $ef, $ee, $3e, $62, $26, $4c, $4d, $56
    db $26, $3e, $51, $63, $ef, $ee, $31, $4c, $4c, $4c, $4c, $4c, $4c, $4c, $4c, $4c
    db $63, $63, $f7, $f0
TextStr_46_43d9:           ; id $0309
    ; "*:The quake of GreatTree must / have some connection with / the Shrine!!"
    db $ea, $9f, $a3, $37, $45, $42, $62, $4e, $52, $3e, $48, $42, $62, $4c, $43, $ef
    db $ee, $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $62, $4a, $52, $50, $51, $fa
    db $f7, $ef, $ee, $45, $3e, $53, $42, $62, $50, $4c, $4a, $42, $ef, $ee, $40, $4c
    db $4b, $4b, $42, $40, $51, $46, $4c, $4b, $62, $54, $46, $51, $45, $fa, $f7, $ef
    db $ee, $51, $45, $42, $62, $36, $45, $4f, $46, $4b, $42, $63, $63, $ef, $ee, $f7
    db $f0
TextStr_46_442a:           ; id $030A
    ; "*:What? You can't even beat my / brothers? / *:I don't need a loser like you! / Come back later when you're ready!"
    db $eb, $9f, $a3, $3a, $45, $3e, $51, $64, $62, $3c, $4c, $52, $62, $40, $3e, $4b
    db $67, $ef, $ee, $42, $53, $42, $4b, $62, $3f, $42, $3e, $51, $62, $4a, $56, $fa
    db $f7, $ef, $ee, $3f, $4f, $4c, $51, $45, $42, $4f, $50, $64, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $2c, $62, $41, $4c, $4b, $67, $62, $4b, $42, $42, $41, $62
    db $3e, $ef, $ee, $49, $4c, $50, $42, $4f, $62, $49, $46, $48, $42, $62, $56, $4c
    db $52, $63, $fa, $f7, $ef, $ee, $26, $4c, $4a, $42, $62, $3f, $3e, $40, $48, $62
    db $49, $3e, $51, $42, $4f, $ef, $ee, $54, $45, $42, $4b, $62, $56, $4c, $52, $69
    db $42, $62, $4f, $42, $3e, $41, $56, $63, $f7, $f0
TextStr_46_44a4:           ; id $030B
    ; "*:Ready! Rock-Paper- / Scissors... Go!"
    db $eb, $9f, $a3, $35, $42, $3e, $41, $56, $63, $ef, $ee, $35, $4c, $40, $48, $9c
    db $33, $3e, $4d, $42, $4f, $9c, $fa, $f7, $ef, $ee, $36, $40, $46, $50, $50, $4c
    db $4f, $50, $5f, $5f, $5f, $62, $2a, $4c, $63, $ef, $ee, $f7, $f0
TextStr_46_44d1:           ; id $030C
    ; "*:You...You are one tough kid!! / *:Okay. I'm gonna give you a prize. / *:Go to one of my brothers! / *:Something good will be waiting / for..."
    db $eb, $9f, $a3, $3c, $4c, $52, $5f, $5f, $5f, $3c, $4c, $52, $62, $3e, $4f, $42
    db $ef, $ee, $4c, $4b, $42, $62, $51, $4c, $52, $44, $45, $62, $48, $46, $41, $63
    db $63, $fa, $f7, $ef, $ee, $9f, $a3, $32, $48, $3e, $56, $5f, $62, $2c, $6a, $62
    db $44, $4c, $4b, $4b, $3e, $ef, $ee, $44, $46, $53, $42, $62, $56, $4c, $52, $62
    db $3e, $62, $4d, $4f, $46, $57, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2a, $4c
    db $62, $51, $4c, $62, $4c, $4b, $42, $62, $4c, $43, $62, $4a, $56, $ef, $ee, $3f
    db $4f, $4c, $51, $45, $42, $4f, $50, $63, $fa, $f7, $ef, $ee, $9f, $a3, $36, $4c
    db $4a, $42, $51, $45, $46, $4b, $44, $62, $44, $4c, $4c, $41, $ef, $ee, $54, $46
    db $49, $49, $62, $3f, $42, $62, $54, $3e, $46, $51, $46, $4b, $44, $fa, $f7, $ef
    db $ee, $43, $4c, $4f, $62, $56, $3e, $63, $63, $ef, $ee, $f7, $f0
TextStr_46_456e:           ; id $030D
    ; "*:Go to one of my brothers! / Something good will be waiting / for ya!"
    db $eb, $9f, $a3, $2a, $4c, $62, $51, $4c, $62, $4c, $4b, $42, $62, $4c, $43, $62
    db $4a, $56, $ef, $ee, $3f, $4f, $4c, $51, $45, $42, $4f, $50, $63, $fa, $f7, $ef
    db $ee, $36, $4c, $4a, $42, $51, $45, $46, $4b, $44, $62, $44, $4c, $4c, $41, $ef
    db $ee, $54, $46, $49, $49, $62, $3f, $42, $62, $54, $3e, $46, $51, $46, $4b, $44
    db $fa, $f7, $ef, $ee, $43, $4c, $4f, $62, $56, $3e, $63, $ef, $ee, $f7, $f0
TextStr_46_45bd:           ; id $030E
    ; "*:May I help you [HERO]! I heard a / rumor... / *:A terrible master appeared in / the country of GreatLog! / *:The master has monsters that ..."
    db $ea, $9f, $a3, $30, $3e, $56, $62, $2c, $62, $45, $42, $49, $4d, $62, $56, $4c
    db $52, $ef, $ee, $f6, $63, $62, $2c, $62, $45, $42, $3e, $4f, $41, $62, $3e, $fa
    db $f7, $ef, $ee, $4f, $52, $4a, $4c, $4f, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $24, $62, $51, $42, $4f, $4f, $46, $3f, $49, $42, $ef, $ee, $4a
    db $3e, $50, $51, $42, $4f, $62, $3e, $4d, $4d, $42, $3e, $4f, $42, $41, $62, $46
    db $4b, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $40, $4c, $52, $4b, $51, $4f, $56
    db $62, $4c, $43, $ef, $ee, $2a, $4f, $42, $3e, $51, $2f, $4c, $44, $63, $fa, $f7
    db $ef, $ee, $9f, $a3, $37, $45, $42, $62, $4a, $3e, $50, $51, $42, $4f, $62, $45
    db $3e, $50, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $51, $45, $3e
    db $51, $62, $4b, $4c, $fa, $f7, $ef, $ee, $4c, $4b, $42, $62, $45, $3e, $50, $62
    db $42, $53, $42, $4f, $62, $50, $42, $42, $4b, $ef, $ee, $3f, $42, $43, $4c, $4f
    db $42, $5f, $f7, $f0
TextStr_46_4671:           ; id $030F
    ; "*:Foreign masters have many kinds / of monsters. / *:such as Blizzardy, / LavaMan, IceMan / *:Phoenix, Digster BombCrag, Orochi / *:BattleRe..."
    db $ea, $9f, $a3, $29, $4c, $4f, $42, $46, $44, $4b, $62, $4a, $3e, $50, $51, $42
    db $4f, $50, $ef, $ee, $45, $3e, $53, $42, $62, $4a, $3e, $4b, $56, $62, $48, $46
    db $4b, $41, $50, $fa, $f7, $ef, $ee, $4c, $43, $62, $4a, $4c, $4b, $50, $51, $42
    db $4f, $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $50, $52, $40, $45, $62
    db $3e, $50, $ef, $ee, $25, $49, $46, $57, $57, $3e, $4f, $41, $56, $5e, $fa, $f7
    db $ef, $ee, $2f, $3e, $53, $3e, $30, $3e, $4b, $5e, $62, $2c, $40, $42, $30, $3e
    db $4b, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $33, $45, $4c, $42, $4b, $46, $55
    db $5e, $62, $27, $46, $44, $50, $51, $42, $4f, $ef, $ee, $25, $4c, $4a, $3f, $26
    db $4f, $3e, $44, $5e, $62, $32, $4f, $4c, $40, $45, $46, $fa, $f7, $ef, $ee, $9f
    db $a3, $25, $3e, $51, $51, $49, $42, $35, $42, $55, $5e, $ef, $ee, $26, $45, $4c
    db $4d, $26, $49, $4c, $54, $4b, $5e, $fa, $f7, $ef, $ee, $2a, $3e, $51, $42, $2a
    db $52, $3e, $4f, $41, $5e, $ef, $ee, $37, $4f, $52, $4a, $4d, $42, $51, $42, $4f
    db $fa, $f7, $ef, $ee, $9f, $a3, $2b, $4c, $4f, $4b, $25, $42, $42, $51, $5e, $ef
    db $ee, $30, $42, $51, $3e, $3f, $3f, $49, $42, $5e, $62, $4c, $4f, $fa, $f7, $ef
    db $ee, $30, $42, $51, $3e, $49, $2e, $46, $4b, $44, $63, $ef, $ee, $f7, $f0
TextStr_46_4760:           ; id $0310
    ; "*:How do you do? My name is May. / It's nice to meet you. / *:Would you like to breed with / my Rayburn?"
    db $eb, $9f, $a3, $2b, $4c, $54, $62, $41, $4c, $62, $56, $4c, $52, $62, $41, $4c
    db $64, $ef, $ee, $30, $56, $62, $4b, $3e, $4a, $42, $62, $46, $50, $62, $30, $3e
    db $56, $5f, $fa, $f7, $ef, $ee, $2c, $51, $68, $62, $4b, $46, $40, $42, $62, $51
    db $4c, $62, $4a, $42, $42, $51, $ef, $ee, $56, $4c, $52, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $3a, $4c, $52, $49, $41, $62, $56, $4c, $52, $62, $49, $46, $48, $42
    db $ef, $ee, $51, $4c, $62, $3f, $4f, $42, $42, $41, $62, $54, $46, $51, $45, $fa
    db $f7, $ef, $ee, $4a, $56, $62, $35, $3e, $56, $3f, $52, $4f, $4b, $64, $ef, $ee
    db $f7, $f0
TextStr_46_47d2:           ; id $0311
    ; "[HERO] pulled the arm of the / slot machine! / It doesn't work! The lever broke / with a snap."
    db $f6, $62, $4d, $52, $49, $49, $42, $41, $62, $51, $45, $42, $ef, $ee, $3e, $4f
    db $4a, $62, $4c, $43, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $50, $49, $4c, $51
    db $62, $4a, $3e, $40, $45, $46, $4b, $42, $63, $ef, $ee, $fa, $f7, $ef, $ee, $2c
    db $51, $62, $41, $4c, $42, $50, $4b, $67, $62, $54, $4c, $4f, $48, $63, $ef, $ee
    db $37, $45, $42, $62, $49, $42, $53, $42, $4f, $62, $3f, $4f, $4c, $48, $42, $fa
    db $f7, $ef, $ee, $54, $46, $51, $45, $62, $3e, $62, $50, $4b, $3e, $4d, $5f, $ef
    db $ee, $f7, $f0
TextStr_46_4835:           ; id $0312
    ; "The slot machine is out of order."
    db $37, $45, $42, $62, $50, $49, $4c, $51, $62, $4a, $3e, $40, $45, $46, $4b, $42
    db $ef, $ee, $46, $50, $62, $4c, $52, $51, $62, $4c, $43, $62, $4c, $4f, $41, $42
    db $4f, $5f, $f7, $f0
TextStr_46_4859:           ; id $0313
    ; "There are 3 Slimes sleeping inside."
    db $37, $45, $42, $4f, $42, $62, $3e, $4f, $42, $62, $03, $62, $36, $49, $46, $4a
    db $42, $50, $ef, $ee, $50, $49, $42, $42, $4d, $46, $4b, $44, $62, $46, $4b, $50
    db $46, $41, $42, $5f, $f7, $f0
TextStr_46_487f:           ; id $0314
    ; "[HERO] pulled the slot machine! / The reels are spinning... / Ka-ching Ka-ching The reels stop. / 3 Metalys are inside sweating! / Jingle! J..."
    db $f6, $62, $4d, $52, $49, $49, $42, $41, $62, $51, $45, $42, $ef, $ee, $50, $49
    db $4c, $51, $62, $4a, $3e, $40, $45, $46, $4b, $42, $63, $fa, $f7, $ef, $ee, $37
    db $45, $42, $62, $4f, $42, $42, $49, $50, $62, $3e, $4f, $42, $ef, $ee, $50, $4d
    db $46, $4b, $4b, $46, $4b, $44, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $2e, $3e, $9c
    db $40, $45, $46, $4b, $44, $62, $2e, $3e, $9c, $40, $45, $46, $4b, $44, $ef, $ee
    db $37, $45, $42, $62, $4f, $42, $42, $49, $50, $62, $50, $51, $4c, $4d, $5f, $fa
    db $f7, $ef, $ee, $03, $62, $30, $42, $51, $3e, $49, $56, $50, $62, $3e, $4f, $42
    db $ef, $ee, $46, $4b, $50, $46, $41, $42, $62, $50, $54, $42, $3e, $51, $46, $4b
    db $44, $63, $fa, $f7, $ef, $ee, $2d, $46, $4b, $44, $49, $42, $63, $62, $2d, $46
    db $4b, $44, $49, $42, $63, $ef, $ee, $fa, $f7, $ef, $ee, $f6, $62, $44, $4c, $51
    db $62, $01, $00, $00, $62, $46, $4b, $ef, $ee, $30, $4c, $4b, $50, $51, $42, $4f
    db $62, $2a, $4c, $49, $41, $63, $f7, $f0
TextStr_46_4937:           ; id $0315
    ; "[HERO] pulled the arm of the / slot machine! / But it doesn't turn. It's rusted!"
    db $f6, $62, $4d, $52, $49, $49, $42, $41, $62, $51, $45, $42, $ef, $ee, $3e, $4f
    db $4a, $62, $4c, $43, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $50, $49, $4c, $51
    db $62, $4a, $3e, $40, $45, $46, $4b, $42, $63, $ef, $ee, $fa, $f7, $ef, $ee, $25
    db $52, $51, $62, $46, $51, $62, $41, $4c, $42, $50, $4b, $67, $ef, $ee, $51, $52
    db $4f, $4b, $5f, $62, $2c, $51, $68, $62, $4f, $52, $50, $51, $42, $41, $63, $f7
    db $f0
TextStr_46_4988:           ; id $0316
    ; "It's out of order."
    db $2c, $51, $68, $62, $4c, $52, $51, $62, $4c, $43, $62, $4c, $4f, $41, $42, $4f
    db $5f, $ef, $ee, $f7, $f0
TextStr_46_499d:           ; id $0317
    ; "3 Metalys are sweating inside / the machine."
    db $03, $62, $30, $42, $51, $3e, $49, $56, $50, $62, $3e, $4f, $42, $ef, $ee, $50
    db $54, $42, $3e, $51, $46, $4b, $44, $62, $46, $4b, $50, $46, $41, $42, $fa, $f7
    db $ef, $ee, $51, $45, $42, $62, $4a, $3e, $40, $45, $46, $4b, $42, $5f, $ef, $ee
    db $f7, $f0
TextStr_46_49cf:           ; id $0318
    ; "[HERO] pulled the arm of the / slot machine! / The reel is spinning like / crazy! / ... ... ... ... K-chunk! K-chunk! / The reel stops. / No..."
    db $f6, $62, $4d, $52, $49, $49, $42, $41, $62, $51, $45, $42, $ef, $ee, $3e, $4f
    db $4a, $62, $4c, $43, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $50, $49, $4c, $51
    db $62, $4a, $3e, $40, $45, $46, $4b, $42, $63, $ef, $ee, $fa, $f7, $ef, $ee, $37
    db $45, $42, $62, $4f, $42, $42, $49, $62, $46, $50, $ef, $ee, $50, $4d, $46, $4b
    db $4b, $46, $4b, $44, $62, $49, $46, $48, $42, $fa, $f7, $ef, $ee, $40, $4f, $3e
    db $57, $56, $63, $ef, $ee, $fa, $f7, $ef, $ee, $5f, $5f, $5f, $62, $5f, $5f, $5f
    db $62, $5f, $5f, $5f, $62, $5f, $5f, $5f, $ef, $ee, $2e, $9c, $40, $45, $52, $4b
    db $48, $63, $62, $2e, $9c, $40, $45, $52, $4b, $48, $63, $fa, $f7, $ef, $ee, $37
    db $45, $42, $62, $4f, $42, $42, $49, $62, $50, $51, $4c, $4d, $50, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $31, $4c, $5e, $46, $51, $68, $62, $50, $4d, $46, $4b, $4b
    db $46, $4b, $44, $ef, $ee, $3e, $44, $3e, $46, $4b, $5f, $fa, $f7, $ef, $ee, $2c
    db $51, $68, $62, $4b, $4c, $51, $62, $50, $51, $4c, $4d, $4d, $46, $4b, $44, $63
    db $ef, $ee, $fa, $f7, $ef, $ee, $2a, $54, $3e, $9c, $26, $45, $52, $4b, $48, $63
    db $63, $ef, $ee, $fa, $f7, $ef, $ee, $f6, $62, $3f, $3e, $4b, $44, $42, $41, $62
    db $51, $45, $42, $ef, $ee, $4a, $3e, $40, $45, $46, $4b, $42, $63, $fa, $f7, $ef
    db $ee, $2e, $9c, $40, $45, $46, $4b, $44, $62, $2e, $9c, $40, $45, $46, $4b, $44
    db $ef, $ee, $fa, $f7, $ef, $ee, $37, $45, $42, $62, $4a, $3e, $40, $45, $46, $4b
    db $42, $62, $50, $4d, $46, $51, $50, $ef, $ee, $4c, $52, $51, $62, $40, $4c, $46
    db $4b, $50, $63, $63, $fa, $f7, $ef, $ee, $f6, $62, $44, $4c, $51, $62, $02, $00
    db $00, $62, $46, $4b, $ef, $ee, $30, $4c, $4b, $50, $51, $42, $4f, $62, $2a, $4c
    db $49, $41, $63, $f7, $f0
TextStr_46_4b14:           ; id $0319
    ; "The reel is spinning..."
    db $37, $45, $42, $62, $4f, $42, $42, $49, $62, $46, $50, $ef, $ee, $50, $4d, $46
    db $4b, $4b, $46, $4b, $44, $5f, $5f, $5f, $f7, $f0
TextStr_46_4b2e:           ; id $031A
    ; "[HERO] pulled the slot machine! / The reels spin quietly. / Spinning.... Spinning.... / [HERO]'s eyes are slowly getting / used to the speed..."
    db $f6, $62, $4d, $52, $49, $49, $42, $41, $62, $51, $45, $42, $ef, $ee, $50, $49
    db $4c, $51, $62, $4a, $3e, $40, $45, $46, $4b, $42, $63, $fa, $f7, $ef, $ee, $37
    db $45, $42, $62, $4f, $42, $42, $49, $50, $ef, $ee, $50, $4d, $46, $4b, $62, $4e
    db $52, $46, $42, $51, $49, $56, $5f, $fa, $f7, $ef, $ee, $36, $4d, $46, $4b, $4b
    db $46, $4b, $44, $5f, $5f, $5f, $5f, $ef, $ee, $36, $4d, $46, $4b, $4b, $46, $4b
    db $44, $5f, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $f6, $68, $62, $42, $56, $42, $50
    db $62, $3e, $4f, $42, $ef, $ee, $50, $49, $4c, $54, $49, $56, $62, $44, $42, $51
    db $51, $46, $4b, $44, $fa, $f7, $ef, $ee, $52, $50, $42, $41, $62, $51, $4c, $62
    db $51, $45, $42, $62, $50, $4d, $42, $42, $41, $ef, $ee, $4c, $43, $62, $51, $45
    db $42, $62, $4a, $3e, $40, $45, $46, $4b, $42, $5f, $fa, $f7, $ef, $ee, $36, $4d
    db $3e, $40, $62, $50, $4d, $4c, $40, $62, $50, $4d, $3e, $40, $63, $63, $ef, $ee
    db $fa, $f7, $ef, $ee, $f6, $62, $45, $46, $51, $62, $51, $45, $42, $ef, $ee, $47
    db $3e, $40, $48, $4d, $4c, $51, $63, $fa, $f7, $ef, $ee, $2d, $46, $4b, $44, $49
    db $42, $62, $2d, $46, $4b, $44, $49, $42, $ef, $ee, $2d, $46, $4b, $44, $49, $42
    db $62, $2d, $46, $4b, $44, $49, $42, $63, $63, $fa, $f7, $ef, $ee, $3a, $4c, $54
    db $63, $62, $f6, $62, $44, $4c, $51, $62, $05, $00, $00, $ef, $ee, $46, $4b, $62
    db $30, $4c, $4b, $50, $51, $42, $4f, $62, $2a, $4c, $49, $41, $63, $63, $f7, $f0
TextStr_46_4c3e:           ; id $031B
    ; "*:What do you say? Why don't you / breed with my Rayburn?"
    db $eb, $9f, $a3, $3a, $45, $3e, $51, $62, $41, $4c, $62, $56, $4c, $52, $62, $50
    db $3e, $56, $64, $ef, $ee, $3a, $45, $56, $62, $41, $4c, $4b, $67, $62, $56, $4c
    db $52, $fa, $f7, $ef, $ee, $3f, $4f, $42, $42, $41, $62, $54, $46, $51, $45, $62
    db $4a, $56, $ef, $ee, $35, $3e, $56, $3f, $52, $4f, $4b, $64, $f0
TextStr_46_4c7b:           ; id $031C
    ; "*:I'm trying to pick up all the / items I can get... / *:And somehow, I keep meeting / the bishops... / *:Does this story help you? / *:I'm ..."
    db $eb, $9f, $a3, $2c, $6a, $62, $51, $4f, $56, $46, $4b, $44, $62, $51, $4c, $ef
    db $ee, $4d, $46, $40, $48, $62, $52, $4d, $62, $3e, $49, $49, $62, $51, $45, $42
    db $fa, $f7, $ef, $ee, $46, $51, $42, $4a, $50, $62, $2c, $62, $40, $3e, $4b, $62
    db $44, $42, $51, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $24, $4b
    db $41, $62, $50, $4c, $4a, $42, $45, $4c, $54, $5e, $ef, $ee, $2c, $62, $48, $42
    db $42, $4d, $62, $4a, $42, $42, $51, $46, $4b, $44, $fa, $f7, $ef, $ee, $51, $45
    db $42, $62, $3f, $46, $50, $45, $4c, $4d, $50, $5f, $5f, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $27, $4c, $42, $50, $62, $51, $45, $46, $50, $62, $50, $51
    db $4c, $4f, $56, $ef, $ee, $45, $42, $49, $4d, $62, $56, $4c, $52, $64, $fa, $f7
    db $ef, $ee, $9f, $a3, $2c, $6a, $62, $49, $4c, $4c, $48, $46, $4b, $44, $ef, $ee
    db $43, $4c, $4f, $54, $3e, $4f, $41, $62, $51, $4c, $fa, $f7, $ef, $ee, $43, $46
    db $44, $45, $51, $46, $4b, $44, $62, $54, $46, $51, $45, $ef, $ee, $56, $4c, $52
    db $62, $50, $4c, $4a, $42, $51, $46, $4a, $42, $63, $f7, $f0
TextStr_46_4d47:           ; id $031D
    ; "*:You, must comply with my next wish. / *I want to see a Metaly! / *:Hard and shiny Metaly!"
    db $eb, $9f, $a3, $3c, $4c, $52, $5e, $62, $4a, $52, $50, $51, $62, $40, $4c, $4a
    db $4d, $49, $56, $ef, $ee, $54, $46, $51, $45, $62, $4a, $56, $62, $4b, $42, $55
    db $51, $62, $54, $46, $50, $45, $5f, $fa, $f7, $ef, $ee, $9f, $2c, $62, $54, $3e
    db $4b, $51, $62, $51, $4c, $62, $50, $42, $42, $ef, $ee, $3e, $62, $30, $42, $51
    db $3e, $49, $56, $63, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $3e, $4f, $41, $62, $3e
    db $4b, $41, $62, $50, $45, $46, $4b, $56, $ef, $ee, $30, $42, $51, $3e, $49, $56
    db $63, $f7, $f0
TextStr_46_4daa:           ; id $031E
    ; "*:Here's the Queen of / GreatTree. / *:And her guest, Medal Man. / *:It seems the Queen invited him / because he looks like the King..."
    db $ea, $9f, $a3, $2b, $42, $4f, $42, $68, $62, $51, $45, $42, $ef, $ee, $34, $52
    db $42, $42, $4b, $62, $4c, $43, $fa, $f7, $ef, $ee, $2a, $4f, $42, $3e, $51, $37
    db $4f, $42, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $24, $4b, $41, $62
    db $45, $42, $4f, $62, $44, $52, $42, $50, $51, $5e, $ef, $ee, $30, $42, $41, $3e
    db $49, $62, $30, $3e, $4b, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $51, $62, $50
    db $42, $42, $4a, $50, $62, $51, $45, $42, $ef, $ee, $34, $52, $42, $42, $4b, $62
    db $46, $4b, $53, $46, $51, $42, $41, $62, $45, $46, $4a, $fa, $f7, $ef, $ee, $3f
    db $42, $40, $3e, $52, $50, $42, $62, $45, $42, $62, $49, $4c, $4c, $48, $50, $ef
    db $ee, $49, $46, $48, $42, $62, $51, $45, $42, $62, $2e, $46, $4b, $44, $5f, $5f
    db $5f, $f7, $f0
TextStr_46_4e3d:           ; id $031F
    ; "*:I'm Medal Man, just a passer-by. / *:I guess I look like the King of / GreatTree. / *:But, I'm not the King! / *:If you believe me, I'll l..."
    db $ea, $9f, $a3, $2c, $6a, $62, $30, $42, $41, $3e, $49, $62, $30, $3e, $4b, $5e
    db $ef, $ee, $47, $52, $50, $51, $62, $3e, $62, $4d, $3e, $50, $50, $42, $4f, $9c
    db $3f, $56, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $44, $52, $42, $50, $50
    db $62, $2c, $62, $49, $4c, $4c, $48, $ef, $ee, $49, $46, $48, $42, $62, $51, $45
    db $42, $62, $2e, $46, $4b, $44, $62, $4c, $43, $fa, $f7, $ef, $ee, $2a, $4f, $42
    db $3e, $51, $37, $4f, $42, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25
    db $52, $51, $5e, $62, $2c, $6a, $62, $4b, $4c, $51, $62, $51, $45, $42, $ef, $ee
    db $2e, $46, $4b, $44, $63, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $43, $62, $56, $4c
    db $52, $62, $3f, $42, $49, $46, $42, $53, $42, $ef, $ee, $4a, $42, $5e, $62, $2c
    db $66, $49, $62, $49, $42, $51, $62, $56, $4c, $52, $fa, $f7, $ef, $ee, $3f, $4f
    db $42, $42, $41, $62, $54, $46, $51, $45, $62, $4c, $4b, $42, $62, $4c, $43, $ef
    db $ee, $4a, $56, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f, $fa, $f7, $ef
    db $ee, $27, $4c, $62, $56, $4c, $52, $62, $3f, $42, $49, $46, $42, $53, $42, $62
    db $4a, $42, $64, $ef, $ee, $ff, $f0
TextStr_46_4f14:           ; id $0320
    ; "*:Being a master requires trust!"
    db $ea, $9f, $a3, $25, $42, $46, $4b, $44, $62, $3e, $62, $4a, $3e, $50, $51, $42
    db $4f, $ef, $ee, $4f, $42, $4e, $52, $46, $4f, $42, $50, $62, $51, $4f, $52, $50
    db $51, $63, $f7, $f0
TextStr_46_4f38:           ; id $0321
    ; "*:Oh! You believe me! As I promised, / you can breed with my FangSlime."
    db $ea, $9f, $a3, $32, $45, $63, $62, $3c, $4c, $52, $62, $3f, $42, $49, $46, $42
    db $53, $42, $ef, $ee, $4a, $42, $63, $62, $24, $50, $62, $2c, $62, $4d, $4f, $4c
    db $4a, $46, $50, $42, $41, $5e, $fa, $f7, $ef, $ee, $56, $4c, $52, $62, $40, $3e
    db $4b, $62, $3f, $4f, $42, $42, $41, $62, $54, $46, $51, $45, $ef, $ee, $4a, $56
    db $62, $29, $3e, $4b, $44, $36, $49, $46, $4a, $42, $5f, $f7, $f0
TextStr_46_4f85:           ; id $0322
    ; "There is a sign on the slot machine. / :No more coins in the machine."
    db $37, $45, $42, $4f, $42, $62, $46, $50, $62, $3e, $62, $50, $46, $44, $4b, $62
    db $4c, $4b, $ef, $ee, $51, $45, $42, $62, $50, $49, $4c, $51, $62, $4a, $3e, $40
    db $45, $46, $4b, $42, $5f, $fa, $f7, $ef, $ee, $a3, $31, $4c, $62, $4a, $4c, $4f
    db $42, $62, $40, $4c, $46, $4b, $50, $62, $46, $4b, $ef, $ee, $51, $45, $42, $62
    db $4a, $3e, $40, $45, $46, $4b, $42, $5f, $f7, $f0
TextStr_46_4fcf:           ; id $0323
    ; "There is a sign on the slot machine. / :No professionals."
    db $37, $45, $42, $4f, $42, $62, $46, $50, $62, $3e, $62, $50, $46, $44, $4b, $62
    db $4c, $4b, $ef, $ee, $51, $45, $42, $62, $50, $49, $4c, $51, $62, $4a, $3e, $40
    db $45, $46, $4b, $42, $5f, $fa, $f7, $ef, $ee, $a3, $31, $4c, $62, $4d, $4f, $4c
    db $43, $42, $50, $50, $46, $4c, $4b, $3e, $49, $50, $5f, $ef, $ee, $f7, $f0
TextStr_46_500e:           ; id $0324
    ; "*:Welcome to the Casino! / Gold here is only for monsters!"
    db $eb, $9f, $a3, $3a, $42, $49, $40, $4c, $4a, $42, $62, $51, $4c, $62, $51, $45
    db $42, $ef, $ee, $26, $3e, $50, $46, $4b, $4c, $63, $fa, $f7, $ef, $ee, $2a, $4c
    db $49, $41, $62, $45, $42, $4f, $42, $62, $46, $50, $62, $4c, $4b, $49, $56, $ef
    db $ee, $43, $4c, $4f, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $63, $f7, $f0
TextStr_46_504e:           ; id $0325
    ; "*:How's your luck?"
    db $eb, $9f, $a3, $2b, $4c, $54, $68, $62, $56, $4c, $52, $4f, $62, $49, $52, $40
    db $48, $64, $ef, $ee, $f7, $f0
TextStr_46_5064:           ; id $0326
    ; "*:I need to get good at it."
    db $eb, $9f, $a3, $2c, $62, $4b, $42, $42, $41, $62, $51, $4c, $62, $44, $42, $51
    db $ef, $ee, $44, $4c, $4c, $41, $62, $3e, $51, $62, $46, $51, $5f, $f7, $f0
TextStr_46_5083:           ; id $0327
    ; "*:That customer has an attitude! / *:Can you do something about / it?"
    db $ea, $9f, $a3, $37, $45, $3e, $51, $62, $40, $52, $50, $51, $4c, $4a, $42, $4f
    db $ef, $ee, $45, $3e, $50, $62, $3e, $4b, $62, $3e, $51, $51, $46, $51, $52, $41
    db $42, $63, $fa, $f7, $ef, $ee, $9f, $a3, $26, $3e, $4b, $62, $56, $4c, $52, $62
    db $41, $4c, $ef, $ee, $50, $4c, $4a, $42, $51, $45, $46, $4b, $44, $62, $3e, $3f
    db $4c, $52, $51, $fa, $f7, $ef, $ee, $46, $51, $64, $ef, $ee, $f7, $f0
TextStr_46_50d1:           ; id $0328
    ; "*:No violence in this store."
    db $ea, $9f, $a3, $31, $4c, $62, $53, $46, $4c, $49, $42, $4b, $40, $42, $62, $46
    db $4b, $ef, $ee, $51, $45, $46, $50, $62, $50, $51, $4c, $4f, $42, $5f, $f7, $f0
TextStr_46_50f1:           ; id $0329
    ; "*:Gwrrrrrrrr.. This machine gave / me nothing!"
    db $ea, $9f, $a3, $2a, $54, $4f, $4f, $4f, $4f, $4f, $4f, $4f, $4f, $5f, $5f, $ef
    db $ee, $37, $45, $46, $50, $62, $4a, $3e, $40, $45, $46, $4b, $42, $62, $44, $3e
    db $53, $42, $fa, $f7, $ef, $ee, $4a, $42, $62, $4b, $4c, $51, $45, $46, $4b, $44
    db $63, $ef, $ee, $f7, $f0
TextStr_46_5126:           ; id $032A
    ; "*:Gwrrrrrrrr.. Why are you the / only lucky one? / *:Gimme that monster gold!"
    db $ea, $9f, $a3, $2a, $54, $4f, $4f, $4f, $4f, $4f, $4f, $4f, $4f, $5f, $5f, $ef
    db $ee, $3a, $45, $56, $62, $3e, $4f, $42, $62, $56, $4c, $52, $62, $51, $45, $42
    db $fa, $f7, $ef, $ee, $4c, $4b, $49, $56, $62, $49, $52, $40, $48, $56, $62, $4c
    db $4b, $42, $64, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2a, $46, $4a, $4a, $42
    db $62, $51, $45, $3e, $51, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $44
    db $4c, $49, $41, $63, $f7, $f0
TextStr_46_517c:           ; id $032B
    ; "*:It's mine now!!"
    db $ea, $9f, $a3, $2c, $51, $68, $62, $4a, $46, $4b, $42, $62, $4b, $4c, $54, $63
    db $63, $ef, $ee, $f7, $f0
TextStr_46_5191:           ; id $032C
    ; "*:Because you trusted me, I'll / give you some advice... / *:Metaly is a precious monster. / *:Go down from the Travelers' Gate at / the bot..."
    db $ea, $9f, $a3, $25, $42, $40, $3e, $52, $50, $42, $62, $56, $4c, $52, $ef, $ee
    db $51, $4f, $52, $50, $51, $42, $41, $62, $4a, $42, $5e, $62, $2c, $66, $49, $fa
    db $f7, $ef, $ee, $44, $46, $53, $42, $62, $56, $4c, $52, $62, $50, $4c, $4a, $42
    db $ef, $ee, $3e, $41, $53, $46, $40, $42, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f
    db $a3, $30, $42, $51, $3e, $49, $56, $62, $46, $50, $62, $3e, $ef, $ee, $4d, $4f
    db $42, $40, $46, $4c, $52, $50, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $5f, $fa
    db $f7, $ef, $ee, $9f, $a3, $2a, $4c, $62, $41, $4c, $54, $4b, $62, $43, $4f, $4c
    db $4a, $62, $51, $45, $42, $ef, $ee, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50
    db $5c, $62, $2a, $3e, $51, $42, $62, $3e, $51, $fa, $f7, $ef, $ee, $51, $45, $42
    db $62, $3f, $4c, $51, $51, $4c, $4a, $62, $4c, $43, $62, $51, $45, $42, $ef, $ee
    db $54, $42, $49, $49, $62, $3e, $4b, $41, $62, $56, $4c, $52, $66, $49, $fa, $f7
    db $ef, $ee, $43, $46, $4b, $41, $62, $4c, $4b, $42, $63, $ef, $ee, $f7, $f0
TextStr_46_5250:           ; id $032D
    ; "*:Metaly is a precious monster. / *:Go down from the Travelers' Gate at / the bottom of the well and you'll / find one! / *:Of course, the p..."
    db $ea, $9f, $a3, $30, $42, $51, $3e, $49, $56, $62, $46, $50, $62, $3e, $ef, $ee
    db $4d, $4f, $42, $40, $46, $4c, $52, $50, $62, $4a, $4c, $4b, $50, $51, $42, $4f
    db $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2a, $4c, $62, $41, $4c, $54, $4b, $62, $43
    db $4f, $4c, $4a, $62, $51, $45, $42, $ef, $ee, $37, $4f, $3e, $53, $42, $49, $42
    db $4f, $50, $5c, $62, $2a, $3e, $51, $42, $62, $3e, $51, $fa, $f7, $ef, $ee, $51
    db $45, $42, $62, $3f, $4c, $51, $51, $4c, $4a, $62, $4c, $43, $62, $51, $45, $42
    db $ef, $ee, $54, $42, $49, $49, $62, $3e, $4b, $41, $62, $56, $4c, $52, $66, $49
    db $fa, $f7, $ef, $ee, $43, $46, $4b, $41, $62, $4c, $4b, $42, $63, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $32, $43, $62, $40, $4c, $52, $4f, $50, $42, $5e, $62
    db $51, $45, $42, $ef, $ee, $4d, $4f, $4c, $3f, $49, $42, $4a, $62, $46, $50, $62
    db $45, $4c, $54, $62, $51, $4c, $fa, $f7, $ef, $ee, $43, $46, $4b, $41, $62, $51
    db $45, $42, $62, $44, $3e, $51, $42, $5f, $ef, $ee, $f7, $f0
TextStr_46_530c:           ; id $032E
    ; "*:[HERO]! Thanks for saving me. / *:You're at the Room of / Strength & Anger. / *:Go right to the Gate of Anger. / Left to the Gate of Stren..."
    db $ea, $9f, $a3, $f6, $63, $62, $37, $45, $3e, $4b, $48, $50, $ef, $ee, $43, $4c
    db $4f, $62, $50, $3e, $53, $46, $4b, $44, $62, $4a, $42, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $3c, $4c, $52, $69, $42, $62, $3e, $51, $ef, $ee, $51, $45, $42, $62
    db $35, $4c, $4c, $4a, $62, $4c, $43, $fa, $f7, $ef, $ee, $36, $51, $4f, $42, $4b
    db $44, $51, $45, $62, $b6, $62, $24, $4b, $44, $42, $4f, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $2a, $4c, $62, $4f, $46, $44, $45, $51, $62, $51, $4c, $62
    db $51, $45, $42, $ef, $ee, $2a, $3e, $51, $42, $62, $4c, $43, $62, $24, $4b, $44
    db $42, $4f, $5f, $fa, $f7, $ef, $ee, $2f, $42, $43, $51, $62, $51, $4c, $62, $51
    db $45, $42, $ef, $ee, $2a, $3e, $51, $42, $62, $4c, $43, $62, $36, $51, $4f, $42
    db $4b, $44, $51, $45, $5f, $f7, $f0
TextStr_46_53a3:           ; id $032F
    ; "*:Thank you very much [HERO]!"
    db $ea, $9f, $a3, $37, $45, $3e, $4b, $48, $62, $56, $4c, $52, $62, $53, $42, $4f
    db $56, $ef, $ee, $4a, $52, $40, $45, $62, $f6, $63, $f7, $f0
TextStr_46_53bf:           ; id $0330
    ; "*Hello [HERO]! I was expecting you. / *:Before I get nervous, / let us begin!"
    db $ea, $9f, $2b, $42, $49, $49, $4c, $62, $f6, $63, $62, $2c, $62, $54, $3e, $50
    db $ef, $ee, $42, $55, $4d, $42, $40, $51, $46, $4b, $44, $62, $56, $4c, $52, $5f
    db $fa, $f7, $ef, $ee, $9f, $a3, $25, $42, $43, $4c, $4f, $42, $62, $2c, $62, $44
    db $42, $51, $ef, $ee, $4b, $42, $4f, $53, $4c, $52, $50, $5e, $fa, $f7, $ef, $ee
    db $49, $42, $51, $62, $52, $50, $62, $3f, $42, $44, $46, $4b, $63, $ef, $ee, $f7
    db $f0
TextStr_46_5410:           ; id $0331
    ; "*:How are you? I'm ready. / *:Let's just begin before I get / butterflies!!"
    db $ea, $9f, $a3, $2b, $4c, $54, $62, $3e, $4f, $42, $62, $56, $4c, $52, $64, $ef
    db $ee, $2c, $6a, $62, $4f, $42, $3e, $41, $56, $5f, $fa, $f7, $ef, $ee, $9f, $a3
    db $2f, $42, $51, $68, $62, $47, $52, $50, $51, $62, $3f, $42, $44, $46, $4b, $ef
    db $ee, $3f, $42, $43, $4c, $4f, $42, $62, $2c, $62, $44, $42, $51, $fa, $f7, $ef
    db $ee, $3f, $52, $51, $51, $42, $4f, $43, $49, $46, $42, $50, $63, $63, $ef, $ee
    db $f7, $f0
TextStr_46_5462:           ; id $0332
    ; "*:Do you know of the Gate of / Wisdom? [YES/NO]"
    db $eb, $9f, $a3, $27, $4c, $62, $56, $4c, $52, $62, $48, $4b, $4c, $54, $62, $4c
    db $43, $ef, $ee, $51, $45, $42, $62, $2a, $3e, $51, $42, $62, $4c, $43, $fa, $f7
    db $ef, $ee, $3a, $46, $50, $41, $4c, $4a, $64, $ef, $ee, $ff, $f0
TextStr_46_548f:           ; id $0333
    ; "*:If you want to meet the Dragon, / you should know its habits. / *:A quote from the Record of the / Journey by the legendary monster / mast..."
    db $eb, $9f, $a3, $2c, $43, $62, $56, $4c, $52, $62, $54, $3e, $4b, $51, $62, $51
    db $4c, $ef, $ee, $4a, $42, $42, $51, $62, $51, $45, $42, $62, $27, $4f, $3e, $44
    db $4c, $4b, $5e, $fa, $f7, $ef, $ee, $56, $4c, $52, $62, $50, $45, $4c, $52, $49
    db $41, $62, $48, $4b, $4c, $54, $ef, $ee, $46, $51, $50, $62, $45, $3e, $3f, $46
    db $51, $50, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $24, $62, $4e, $52, $4c, $51, $42
    db $62, $43, $4f, $4c, $4a, $62, $51, $45, $42, $ef, $ee, $35, $42, $40, $4c, $4f
    db $41, $62, $4c, $43, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $2d, $4c, $52, $4f
    db $4b, $42, $56, $62, $3f, $56, $62, $51, $45, $42, $ef, $ee, $49, $42, $44, $42
    db $4b, $41, $3e, $4f, $56, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $fa, $f7, $ef
    db $ee, $4a, $3e, $50, $51, $42, $4f, $5e, $62, $30, $3e, $4f, $56, $5f, $ef, $ee
    db $f7, $f0
TextStr_46_5531:           ; id $0334
    ; "*:Are you familiar with the Gate of / Joy? [YES/NO]"
    db $eb, $9f, $a3, $24, $4f, $42, $62, $56, $4c, $52, $62, $43, $3e, $4a, $46, $49
    db $46, $3e, $4f, $ef, $ee, $54, $46, $51, $45, $62, $51, $45, $42, $62, $2a, $3e
    db $51, $42, $62, $4c, $43, $fa, $f7, $ef, $ee, $2d, $4c, $56, $64, $ef, $ee, $ff
    db $f0
TextStr_46_5562:           ; id $0335
    ; "*:A bird spins a round on the / stage. / *:It is a poem with a hint of / the exotic..."
    db $eb, $9f, $a3, $24, $62, $3f, $46, $4f, $41, $62, $50, $4d, $46, $4b, $50, $ef
    db $ee, $3e, $62, $4f, $4c, $52, $4b, $41, $62, $4c, $4b, $62, $51, $45, $42, $fa
    db $f7, $ef, $ee, $50, $51, $3e, $44, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $2c, $51, $62, $46, $50, $62, $3e, $62, $4d, $4c, $42, $4a, $ef, $ee, $54
    db $46, $51, $45, $62, $3e, $62, $45, $46, $4b, $51, $62, $4c, $43, $fa, $f7, $ef
    db $ee, $51, $45, $42, $62, $42, $55, $4c, $51, $46, $40, $5f, $5f, $5f, $ef, $ee
    db $f7, $f0
TextStr_46_55c4:           ; id $0336
    ; "*:A mysterious spring where / mysterious spirits live. / *:Sometimes the spirits test the / heart of travelers. / *:A quote from the diary o..."
    db $eb, $9f, $a3, $24, $62, $4a, $56, $50, $51, $42, $4f, $46, $4c, $52, $50, $ef
    db $ee, $50, $4d, $4f, $46, $4b, $44, $62, $54, $45, $42, $4f, $42, $fa, $f7, $ef
    db $ee, $4a, $56, $50, $51, $42, $4f, $46, $4c, $52, $50, $62, $50, $4d, $46, $4f
    db $46, $51, $50, $ef, $ee, $49, $46, $53, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3
    db $36, $4c, $4a, $42, $51, $46, $4a, $42, $50, $62, $51, $45, $42, $ef, $ee, $50
    db $4d, $46, $4f, $46, $51, $50, $62, $51, $42, $50, $51, $62, $51, $45, $42, $fa
    db $f7, $ef, $ee, $45, $42, $3e, $4f, $51, $62, $4c, $43, $ef, $ee, $51, $4f, $3e
    db $53, $42, $49, $42, $4f, $50, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $24, $62, $4e
    db $52, $4c, $51, $42, $62, $43, $4f, $4c, $4a, $62, $51, $45, $42, $ef, $ee, $41
    db $46, $3e, $4f, $56, $62, $4c, $43, $62, $3e, $62, $49, $4c, $44, $44, $42, $4f
    db $5f, $f7, $f0
TextStr_46_5667:           ; id $0337
    ; "King:Well done, [HERO]! / You defeated SkyDragon! / King:I heard that only a clever / master encounters that monster. / King:That's my [HERO..."
    db $ea, $2e, $46, $4b, $44, $a3, $3a, $42, $49, $49, $62, $41, $4c, $4b, $42, $5e
    db $ef, $ee, $f6, $63, $fa, $f7, $ef, $ee, $3c, $4c, $52, $62, $41, $42, $43, $42
    db $3e, $51, $42, $41, $ef, $ee, $36, $48, $56, $27, $4f, $3e, $44, $4c, $4b, $63
    db $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $2c, $62, $45, $42, $3e, $4f, $41
    db $62, $51, $45, $3e, $51, $ef, $ee, $4c, $4b, $49, $56, $62, $3e, $62, $40, $49
    db $42, $53, $42, $4f, $fa, $f7, $ef, $ee, $4a, $3e, $50, $51, $42, $4f, $62, $42
    db $4b, $40, $4c, $52, $4b, $51, $42, $4f, $50, $ef, $ee, $51, $45, $3e, $51, $62
    db $4a, $4c, $4b, $50, $51, $42, $4f, $5f, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44
    db $a3, $37, $45, $3e, $51, $68, $62, $4a, $56, $ef, $ee, $f6, $5f, $62, $3c, $4c
    db $52, $69, $42, $fa, $f7, $ef, $ee, $3e, $50, $62, $50, $4a, $3e, $4f, $51, $62
    db $3e, $50, $ef, $ee, $51, $45, $42, $56, $62, $40, $4c, $4a, $42, $63, $f7, $f0
TextStr_46_5717:           ; id $0338
    ; "*:What's wrong? You look pale!"
    db $ea, $9f, $a3, $3a, $45, $3e, $51, $68, $62, $54, $4f, $4c, $4b, $44, $64, $ef
    db $ee, $3c, $4c, $52, $62, $49, $4c, $4c, $48, $62, $4d, $3e, $49, $42, $63, $f7
    db $f0
TextStr_46_5738:           ; id $0339
    ; "*:That man always looks the same / but... / *:He's actually very restless. / I wonder why?"
    db $eb, $9f, $a3, $37, $45, $3e, $51, $62, $4a, $3e, $4b, $62, $3e, $49, $54, $3e
    db $56, $50, $ef, $ee, $49, $4c, $4c, $48, $50, $62, $51, $45, $42, $62, $50, $3e
    db $4a, $42, $fa, $f7, $ef, $ee, $3f, $52, $51, $5f, $5f, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $2b, $42, $68, $62, $3e, $40, $51, $52, $3e, $49, $49, $56
    db $ef, $ee, $53, $42, $4f, $56, $62, $4f, $42, $50, $51, $49, $42, $50, $50, $5f
    db $fa, $f7, $ef, $ee, $2c, $62, $54, $4c, $4b, $41, $42, $4f, $62, $54, $45, $56
    db $64, $ef, $ee, $f7, $f0
TextStr_46_579d:           ; id $033A
    ; "King:Well done, [HERO]! / You defeated FunkyBird! / King:I will call you Funky [HERO] / from now on!"
    db $ea, $2e, $46, $4b, $44, $a3, $3a, $42, $49, $49, $62, $41, $4c, $4b, $42, $5e
    db $ef, $ee, $f6, $63, $fa, $f7, $ef, $ee, $3c, $4c, $52, $62, $41, $42, $43, $42
    db $3e, $51, $42, $41, $ef, $ee, $29, $52, $4b, $48, $56, $25, $46, $4f, $41, $63
    db $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $2c, $62, $54, $46, $49, $49, $62
    db $40, $3e, $49, $49, $ef, $ee, $56, $4c, $52, $62, $29, $52, $4b, $48, $56, $62
    db $f6, $fa, $f7, $ef, $ee, $43, $4f, $4c, $4a, $62, $4b, $4c, $54, $62, $4c, $4b
    db $63, $ef, $ee, $f7, $f0
TextStr_46_5802:           ; id $033B
    ; "King:Well done, [HERO]! / You defeated Digster! / King:What! You heard a voice? / King:Are you okay? Did you bump your / head?"
    db $ea, $2e, $46, $4b, $44, $a3, $3a, $42, $49, $49, $62, $41, $4c, $4b, $42, $5e
    db $ef, $ee, $f6, $63, $fa, $f7, $ef, $ee, $3c, $4c, $52, $62, $41, $42, $43, $42
    db $3e, $51, $42, $41, $ef, $ee, $27, $46, $44, $50, $51, $42, $4f, $63, $fa, $f7
    db $ef, $ee, $2e, $46, $4b, $44, $a3, $3a, $45, $3e, $51, $63, $62, $3c, $4c, $52
    db $ef, $ee, $45, $42, $3e, $4f, $41, $62, $3e, $62, $53, $4c, $46, $40, $42, $64
    db $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $24, $4f, $42, $62, $56, $4c, $52
    db $62, $4c, $48, $3e, $56, $64, $ef, $ee, $27, $46, $41, $62, $56, $4c, $52, $62
    db $3f, $52, $4a, $4d, $62, $56, $4c, $52, $4f, $fa, $f7, $ef, $ee, $45, $42, $3e
    db $41, $64, $ef, $ee, $f7, $f0
TextStr_46_5888:           ; id $033C
    ; "*:What? You won C class? Shoo, / shoo! It's none of my business."
    db $eb, $9f, $a3, $3a, $45, $3e, $51, $64, $62, $3c, $4c, $52, $62, $54, $4c, $4b
    db $ef, $ee, $26, $62, $40, $49, $3e, $50, $50, $64, $62, $36, $45, $4c, $4c, $5e
    db $fa, $f7, $ef, $ee, $50, $45, $4c, $4c, $63, $62, $2c, $51, $68, $62, $4b, $4c
    db $4b, $42, $ef, $ee, $4c, $43, $62, $4a, $56, $62, $3f, $52, $50, $46, $4b, $42
    db $50, $50, $5f, $f7, $f0
TextStr_46_58cd:           ; id $033D
    ; "*:Well done on surviving C class! / Go left to the Room of / Joy & Wisdom! / *:In the center is the Room of / Strength & Anger. / *:On the r..."
    db $ea, $9f, $a3, $3a, $42, $49, $49, $62, $41, $4c, $4b, $42, $62, $4c, $4b, $ef
    db $ee, $50, $52, $4f, $53, $46, $53, $46, $4b, $44, $62, $26, $62, $40, $49, $3e
    db $50, $50, $63, $fa, $f7, $ef, $ee, $2a, $4c, $62, $49, $42, $43, $51, $62, $51
    db $4c, $62, $51, $45, $42, $ef, $ee, $35, $4c, $4c, $4a, $62, $4c, $43, $fa, $f7
    db $ef, $ee, $2d, $4c, $56, $62, $b6, $62, $3a, $46, $50, $41, $4c, $4a, $63, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $4b, $62, $51, $45, $42, $62, $40, $42
    db $4b, $51, $42, $4f, $ef, $ee, $46, $50, $62, $51, $45, $42, $62, $35, $4c, $4c
    db $4a, $62, $4c, $43, $fa, $f7, $ef, $ee, $36, $51, $4f, $42, $4b, $44, $51, $45
    db $62, $b6, $62, $24, $4b, $44, $42, $4f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $32, $4b, $62, $51, $45, $42, $62, $4f, $46, $44, $45, $51, $62, $46, $50
    db $ef, $ee, $51, $45, $42, $62, $35, $4c, $4c, $4a, $62, $4c, $43, $62, $33, $42
    db $3e, $40, $42, $fa, $f7, $ef, $ee, $3e, $4b, $41, $62, $25, $4f, $3e, $53, $42
    db $4f, $56, $5f, $ef, $ee, $f7, $f0
TextStr_46_5994:           ; id $033E
    ; "*:You gotta have MetalCut to / defeat Metaly. / *:It can be learned by / RougeNite, BattleRex, / *:and Anteater."
    db $eb, $9f, $a3, $3c, $4c, $52, $62, $44, $4c, $51, $51, $3e, $62, $45, $3e, $53
    db $42, $ef, $ee, $30, $42, $51, $3e, $49, $26, $52, $51, $62, $51, $4c, $fa, $f7
    db $ef, $ee, $41, $42, $43, $42, $3e, $51, $62, $30, $42, $51, $3e, $49, $56, $5f
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $51, $62, $40, $3e, $4b, $62, $3f
    db $42, $ef, $ee, $49, $42, $3e, $4f, $4b, $42, $41, $62, $3f, $56, $fa, $f7, $ef
    db $ee, $35, $4c, $52, $44, $42, $31, $46, $51, $42, $5e, $ef, $ee, $25, $3e, $51
    db $51, $49, $42, $35, $42, $55, $5e, $fa, $f7, $ef, $ee, $9f, $a3, $3e, $4b, $41
    db $62, $24, $4b, $51, $42, $3e, $51, $42, $4f, $5f, $ef, $ee, $f7, $f0
TextStr_46_5a12:           ; id $033F
    ; "*:There's a technique that can / paralyze the enemy at the same time / as an attack. / *:Chamelgon, CactiBall & / Mummy have it!"
    db $eb, $9f, $a3, $37, $45, $42, $4f, $42, $68, $62, $3e, $ef, $ee, $51, $42, $40
    db $45, $4b, $46, $4e, $52, $42, $62, $51, $45, $3e, $51, $62, $40, $3e, $4b, $fa
    db $f7, $ef, $ee, $4d, $3e, $4f, $3e, $49, $56, $57, $42, $62, $51, $45, $42, $62
    db $42, $4b, $42, $4a, $56, $ef, $ee, $3e, $51, $62, $51, $45, $42, $62, $50, $3e
    db $4a, $42, $62, $51, $46, $4a, $42, $fa, $f7, $ef, $ee, $3e, $50, $62, $3e, $4b
    db $62, $3e, $51, $51, $3e, $40, $48, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $26, $45, $3e, $4a, $42, $49, $44, $4c, $4b, $5e, $ef, $ee, $26, $3e, $40, $51
    db $46, $25, $3e, $49, $49, $62, $b6, $fa, $f7, $ef, $ee, $30, $52, $4a, $4a, $56
    db $62, $45, $3e, $53, $42, $62, $46, $51, $63, $ef, $ee, $f7, $f0
TextStr_46_5a9f:           ; id $0340
    ; "*:It's strange. My power of / SleepAir is... / *:Maybe I'm getting too old!?"
    db $eb, $9f, $a3, $2c, $51, $68, $62, $50, $51, $4f, $3e, $4b, $44, $42, $5f, $ef
    db $ee, $30, $56, $62, $4d, $4c, $54, $42, $4f, $62, $4c, $43, $fa, $f7, $ef, $ee
    db $36, $49, $42, $42, $4d, $24, $46, $4f, $62, $46, $50, $5f, $5f, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $30, $3e, $56, $3f, $42, $62, $2c, $6a, $ef, $ee
    db $44, $42, $51, $51, $46, $4b, $44, $62, $51, $4c, $4c, $62, $4c, $49, $41, $63
    db $64, $f7, $f0
TextStr_46_5af2:           ; id $0341
    ; "*:Well done!! You survived B class! / *:The King opened the Room of / Happiness & Temptation for / you! / *:A Travelers' Gate with / stronge..."
    db $ea, $9f, $a3, $3a, $42, $49, $49, $62, $41, $4c, $4b, $42, $63, $63, $62, $3c
    db $4c, $52, $ef, $ee, $50, $52, $4f, $53, $46, $53, $42, $41, $62, $25, $62, $40
    db $49, $3e, $50, $50, $63, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $2e
    db $46, $4b, $44, $62, $4c, $4d, $42, $4b, $42, $41, $ef, $ee, $51, $45, $42, $62
    db $35, $4c, $4c, $4a, $62, $4c, $43, $fa, $f7, $ef, $ee, $2b, $3e, $4d, $4d, $46
    db $4b, $42, $50, $50, $62, $b6, $ef, $ee, $37, $42, $4a, $4d, $51, $3e, $51, $46
    db $4c, $4b, $62, $43, $4c, $4f, $fa, $f7, $ef, $ee, $56, $4c, $52, $63, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $24, $62, $37, $4f, $3e, $53, $42, $49, $42, $4f
    db $50, $5c, $ef, $ee, $2a, $3e, $51, $42, $62, $54, $46, $51, $45, $fa, $f7, $ef
    db $ee, $50, $51, $4f, $4c, $4b, $44, $42, $4f, $62, $4a, $4c, $4b, $50, $51, $42
    db $4f, $50, $ef, $ee, $3e, $54, $3e, $46, $51, $50, $62, $56, $4c, $52, $63, $f7
    db $f0
TextStr_46_5ba3:           ; id $0342
    ; "*:Well done!! You survived B class! / *:The King opened the Room of / Happiness & Temptation, and / the Room of Joy & Wisdom / for you! / *:..."
    db $ea, $9f, $a3, $3a, $42, $49, $49, $62, $41, $4c, $4b, $42, $63, $63, $62, $3c
    db $4c, $52, $ef, $ee, $50, $52, $4f, $53, $46, $53, $42, $41, $62, $25, $62, $40
    db $49, $3e, $50, $50, $63, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $2e
    db $46, $4b, $44, $62, $4c, $4d, $42, $4b, $42, $41, $ef, $ee, $51, $45, $42, $62
    db $35, $4c, $4c, $4a, $62, $4c, $43, $fa, $f7, $ef, $ee, $2b, $3e, $4d, $4d, $46
    db $4b, $42, $50, $50, $62, $b6, $ef, $ee, $37, $42, $4a, $4d, $51, $3e, $51, $46
    db $4c, $4b, $5e, $62, $3e, $4b, $41, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $35
    db $4c, $4c, $4a, $62, $4c, $43, $ef, $ee, $2d, $4c, $56, $62, $b6, $62, $3a, $46
    db $50, $41, $4c, $4a, $fa, $f7, $ef, $ee, $43, $4c, $4f, $62, $56, $4c, $52, $63
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $4f, $3e, $53, $42, $49, $42, $4f
    db $50, $5c, $ef, $ee, $2a, $3e, $51, $42, $50, $62, $54, $46, $51, $45, $fa, $f7
    db $ef, $ee, $50, $51, $4f, $4c, $4b, $44, $42, $4f, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $50, $ef, $ee, $3e, $54, $3e, $46, $51, $62, $56, $4c, $52, $63, $f7
    db $f0
TextStr_46_5c74:           ; id $0343
    ; "*:The last match will be against / the tired man in the restaurant."
    db $eb, $9f, $a3, $37, $45, $42, $62, $49, $3e, $50, $51, $62, $4a, $3e, $51, $40
    db $45, $ef, $ee, $54, $46, $49, $49, $62, $3f, $42, $62, $3e, $44, $3e, $46, $4b
    db $50, $51, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $51, $46, $4f, $42, $41, $62
    db $4a, $3e, $4b, $62, $46, $4b, $ef, $ee, $51, $45, $42, $62, $4f, $42, $50, $51
    db $3e, $52, $4f, $3e, $4b, $51, $5f, $f7, $f0
TextStr_46_5cbd:           ; id $0344
    ; "*:[HERO]! You're tough! / *:Way to go. Say, Let's breed. / *:Why don't you breed with my / Eyeder?"
    db $ea, $9f, $a3, $f6, $63, $ef, $ee, $3c, $4c, $52, $69, $42, $62, $51, $4c, $52
    db $44, $45, $63, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $3e, $56, $62, $51, $4c, $62
    db $44, $4c, $5f, $62, $36, $3e, $56, $5e, $ef, $ee, $2f, $42, $51, $68, $62, $3f
    db $4f, $42, $42, $41, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45, $56, $62, $41
    db $4c, $4b, $67, $62, $56, $4c, $52, $ef, $ee, $3f, $4f, $42, $42, $41, $62, $54
    db $46, $51, $45, $62, $4a, $56, $fa, $f7, $ef, $ee, $28, $56, $42, $41, $42, $4f
    db $64, $ef, $ee, $f0
TextStr_46_5d21:           ; id $0345
    ; "*:I'm the King of the world!!"
    db $ea, $9f, $a3, $2c, $6a, $62, $51, $45, $42, $62, $2e, $46, $4b, $44, $62, $4c
    db $43, $ef, $ee, $51, $45, $42, $62, $54, $4c, $4f, $49, $41, $63, $63, $f7, $f0
TextStr_46_5d41:           ; id $0346
    ; "*:No luck today! / *:Hey, you don't have any use for / Monster Gold. It's mine now!! / *:...Hee hee! I am in luck after all!"
    db $ea, $9f, $a3, $31, $4c, $62, $49, $52, $40, $48, $62, $51, $4c, $41, $3e, $56
    db $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $42, $56, $5e, $62, $56, $4c
    db $52, $62, $41, $4c, $4b, $67, $ef, $ee, $45, $3e, $53, $42, $62, $3e, $4b, $56
    db $62, $52, $50, $42, $62, $43, $4c, $4f, $fa, $f7, $ef, $ee, $30, $4c, $4b, $50
    db $51, $42, $4f, $62, $2a, $4c, $49, $41, $5f, $ef, $ee, $2c, $51, $68, $62, $4a
    db $46, $4b, $42, $62, $4b, $4c, $54, $63, $63, $fa, $f7, $ef, $ee, $9f, $a3, $5f
    db $5f, $5f, $2b, $42, $42, $62, $45, $42, $42, $63, $62, $2c, $62, $3e, $4a, $ef
    db $ee, $46, $4b, $62, $49, $52, $40, $48, $62, $3e, $43, $51, $42, $4f, $62, $3e
    db $49, $49, $63, $f7, $f0
TextStr_46_5dc6:           ; id $0347
    ; "Watabou:Did you have a good time / at the casino? Time to go back / to the castle."
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $27, $46, $41, $62, $56, $4c, $52
    db $ef, $ee, $45, $3e, $53, $42, $62, $3e, $62, $44, $4c, $4c, $41, $62, $51, $46
    db $4a, $42, $fa, $f7, $ef, $ee, $3e, $51, $62, $51, $45, $42, $62, $40, $3e, $50
    db $46, $4b, $4c, $64, $ef, $ee, $37, $46, $4a, $42, $62, $51, $4c, $62, $44, $4c
    db $62, $3f, $3e, $40, $48, $fa, $f7, $ef, $ee, $51, $4c, $62, $51, $45, $42, $62
    db $40, $3e, $50, $51, $49, $42, $5f, $ef, $ee, $f7, $f0
TextStr_46_5e21:           ; id $0348
    ; "*:Ha ha ha! I made Gigantes / smug!"
    db $ea, $9f, $a3, $2b, $3e, $62, $45, $3e, $62, $45, $3e, $63, $ef, $ee, $2c, $62
    db $4a, $3e, $41, $42, $62, $2a, $46, $44, $3e, $4b, $51, $42, $50, $fa, $f7, $ef
    db $ee, $50, $4a, $52, $44, $63, $ef, $ee, $f7, $f0
TextStr_46_5e4b:           ; id $0349
    ; "*:Well. You have to find / your own way!"
    db $eb, $9f, $a3, $3a, $42, $49, $49, $5f, $ef, $ee, $3c, $4c, $52, $62, $45, $3e
    db $53, $42, $62, $51, $4c, $62, $43, $46, $4b, $41, $fa, $f7, $ef, $ee, $56, $4c
    db $52, $4f, $62, $4c, $54, $4b, $62, $54, $3e, $56, $63, $ef, $ee, $f7, $f0
TextStr_46_5e7a:           ; id $034A
    ; "*:Oh! It's a CurseLamp! Nasty! / *:Well done for bringing it here. / Here is your reward."
    db $eb, $9f, $a3, $32, $45, $63, $62, $2c, $51, $68, $62, $3e, $ef, $ee, $26, $52
    db $4f, $50, $42, $2f, $3e, $4a, $4d, $63, $62, $31, $3e, $50, $51, $56, $63, $fa
    db $f7, $ef, $ee, $9f, $a3, $3a, $42, $49, $49, $62, $41, $4c, $4b, $42, $62, $43
    db $4c, $4f, $ef, $ee, $3f, $4f, $46, $4b, $44, $46, $4b, $44, $62, $46, $51, $62
    db $45, $42, $4f, $42, $5f, $fa, $f7, $ef, $ee, $2b, $42, $4f, $42, $62, $46, $50
    db $62, $56, $4c, $52, $4f, $ef, $ee, $4f, $42, $54, $3e, $4f, $41, $5f, $fa, $f7
    db $f0
TextStr_46_5edb:           ; id $034B
    ; "This is a DEFseed. / Use it wisely."
    db $eb, $37, $45, $46, $50, $62, $46, $50, $62, $3e, $ef, $ee, $27, $28, $29, $50
    db $42, $42, $41, $5f, $fa, $f7, $ef, $ee, $38, $50, $42, $62, $46, $51, $62, $54
    db $46, $50, $42, $49, $56, $5f, $ef, $ee, $f7, $f0
TextStr_46_5f05:           ; id $034C
    ; "*:I'm satisfied. Come back when you / get stronger."
    db $eb, $9f, $a3, $2c, $6a, $62, $50, $3e, $51, $46, $50, $43, $46, $42, $41, $5f
    db $ef, $ee, $26, $4c, $4a, $42, $62, $3f, $3e, $40, $48, $62, $54, $45, $42, $4b
    db $62, $56, $4c, $52, $fa, $f7, $ef, $ee, $44, $42, $51, $62, $50, $51, $4f, $4c
    db $4b, $44, $42, $4f, $5f, $ef, $ee, $f7, $f0
TextStr_46_5f3e:           ; id $034D
    ; "*:Oh! That's Metaly! How shiny! / *:Well done for bringing it here. / Here is your reward."
    db $eb, $9f, $a3, $32, $45, $63, $62, $37, $45, $3e, $51, $68, $ef, $ee, $30, $42
    db $51, $3e, $49, $56, $63, $62, $2b, $4c, $54, $62, $50, $45, $46, $4b, $56, $63
    db $fa, $f7, $ef, $ee, $9f, $a3, $3a, $42, $49, $49, $62, $41, $4c, $4b, $42, $62
    db $43, $4c, $4f, $ef, $ee, $3f, $4f, $46, $4b, $44, $46, $4b, $44, $62, $46, $51
    db $62, $45, $42, $4f, $42, $5f, $fa, $f7, $ef, $ee, $2b, $42, $4f, $42, $62, $46
    db $50, $62, $56, $4c, $52, $4f, $ef, $ee, $4f, $42, $54, $3e, $4f, $41, $5f, $fa
    db $f7, $f0
TextStr_46_5fa0:           ; id $034E
    ; "[HERO] read the blackboard. / :The principal hides his bald / head under his hat."
    db $f6, $62, $4f, $42, $3e, $41, $62, $51, $45, $42, $ef, $ee, $3f, $49, $3e, $40
    db $48, $3f, $4c, $3e, $4f, $41, $5f, $fa, $f7, $ef, $ee, $a3, $37, $45, $42, $62
    db $4d, $4f, $46, $4b, $40, $46, $4d, $3e, $49, $ef, $ee, $45, $46, $41, $42, $50
    db $62, $45, $46, $50, $62, $3f, $3e, $49, $41, $fa, $f7, $ef, $ee, $45, $42, $3e
    db $41, $62, $52, $4b, $41, $42, $4f, $62, $45, $46, $50, $ef, $ee, $45, $3e, $51
    db $5f, $f7, $f0
TextStr_46_5ff3:           ; id $034F
    ; "*:When two of the same kind of / monsters are bred they create the / same monster, right? / *:But when I bred the same kind of / monsters, a..."
    db $ea, $9f, $a3, $3a, $45, $42, $4b, $62, $51, $54, $4c, $62, $4c, $43, $62, $51
    db $45, $42, $ef, $ee, $50, $3e, $4a, $42, $62, $48, $46, $4b, $41, $62, $4c, $43
    db $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $3e, $4f, $42
    db $62, $3f, $4f, $42, $41, $ef, $ee, $51, $45, $42, $56, $62, $40, $4f, $42, $3e
    db $51, $42, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $50, $3e, $4a, $42, $62, $4a
    db $4c, $4b, $50, $51, $42, $4f, $5e, $ef, $ee, $4f, $46, $44, $45, $51, $64, $fa
    db $f7, $ef, $ee, $9f, $a3, $25, $52, $51, $62, $54, $45, $42, $4b, $62, $2c, $62
    db $3f, $4f, $42, $41, $ef, $ee, $51, $45, $42, $62, $50, $3e, $4a, $42, $62, $48
    db $46, $4b, $41, $62, $4c, $43, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42
    db $4f, $50, $5e, $62, $3e, $ef, $ee, $41, $46, $43, $43, $42, $4f, $42, $4b, $51
    db $62, $48, $46, $4b, $41, $62, $4c, $43, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50
    db $51, $42, $4f, $62, $54, $3e, $50, $62, $3f, $4c, $4f, $4b, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $3a, $42, $46, $4f, $41, $63, $ef, $ee, $2c, $62, $44
    db $52, $42, $50, $50, $62, $51, $45, $42, $4f, $42, $fa, $f7, $ef, $ee, $3e, $4f
    db $42, $62, $42, $55, $40, $42, $4d, $51, $46, $4c, $4b, $50, $64, $63, $ef, $ee
    db $f7, $f0
TextStr_46_60e5:           ; id $0350
    ; "*:I am the Queen of GreatTree. / *:Will you comply with my request? / *:I long to see a monster called / WingSlime. / *:Bring me the Slime w..."
    db $eb, $9f, $a3, $2c, $62, $3e, $4a, $62, $51, $45, $42, $62, $34, $52, $42, $42
    db $4b, $ef, $ee, $4c, $43, $62, $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $5f
    db $fa, $f7, $ef, $ee, $9f, $a3, $3a, $46, $49, $49, $62, $56, $4c, $52, $62, $40
    db $4c, $4a, $4d, $49, $56, $ef, $ee, $54, $46, $51, $45, $62, $4a, $56, $62, $4f
    db $42, $4e, $52, $42, $50, $51, $64, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $49
    db $4c, $4b, $44, $62, $51, $4c, $62, $50, $42, $42, $62, $3e, $ef, $ee, $4a, $4c
    db $4b, $50, $51, $42, $4f, $62, $40, $3e, $49, $49, $42, $41, $fa, $f7, $ef, $ee
    db $3a, $46, $4b, $44, $36, $49, $46, $4a, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $25, $4f, $46, $4b, $44, $62, $4a, $42, $62, $51, $45, $42, $ef, $ee
    db $36, $49, $46, $4a, $42, $62, $54, $46, $51, $45, $62, $54, $46, $4b, $44, $50
    db $63, $f7, $f0
TextStr_46_6188:           ; id $0351
    ; "*:Is this an Orc or Pork? / Funny?"
    db $ea, $9f, $a3, $2c, $50, $62, $51, $45, $46, $50, $62, $3e, $4b, $ef, $ee, $32
    db $4f, $40, $62, $4c, $4f, $62, $33, $4c, $4f, $48, $64, $fa, $f7, $ef, $ee, $29
    db $52, $4b, $4b, $56, $64, $ef, $ee, $f7, $f0
TextStr_46_61b1:           ; id $0352
    ; "*:Hee hee! Yo dude, wanna know / who you're gonna fight in B class? [YES/NO]"
    db $ea, $9f, $a3, $2b, $42, $42, $62, $45, $42, $42, $63, $62, $3c, $4c, $ef, $ee
    db $41, $52, $41, $42, $5e, $62, $54, $3e, $4b, $4b, $3e, $62, $48, $4b, $4c, $54
    db $fa, $f7, $ef, $ee, $54, $45, $4c, $62, $56, $4c, $52, $69, $42, $62, $44, $4c
    db $4b, $4b, $3e, $ef, $ee, $43, $46, $44, $45, $51, $62, $46, $4b, $62, $25, $62
    db $40, $49, $3e, $50, $50, $64, $ff, $f0
TextStr_46_61f9:           ; id $0353
    ; "*:The last match will be against / the man from the restaurant. / *:He has a MadDragon and / two ArmyCrabs. / *:When the MadDragon goes / cr..."
    db $ea, $9f, $a3, $37, $45, $42, $62, $49, $3e, $50, $51, $62, $4a, $3e, $51, $40
    db $45, $ef, $ee, $54, $46, $49, $49, $62, $3f, $42, $62, $3e, $44, $3e, $46, $4b
    db $50, $51, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $4a, $3e, $4b, $62, $43, $4f
    db $4c, $4a, $ef, $ee, $51, $45, $42, $62, $4f, $42, $50, $51, $3e, $52, $4f, $3e
    db $4b, $51, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $42, $62, $45, $3e, $50, $62
    db $3e, $ef, $ee, $30, $3e, $41, $27, $4f, $3e, $44, $4c, $4b, $62, $3e, $4b, $41
    db $fa, $f7, $ef, $ee, $51, $54, $4c, $62, $24, $4f, $4a, $56, $26, $4f, $3e, $3f
    db $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45, $42, $4b, $62, $51
    db $45, $42, $ef, $ee, $30, $3e, $41, $27, $4f, $3e, $44, $4c, $4b, $62, $44, $4c
    db $42, $50, $fa, $f7, $ef, $ee, $40, $4f, $3e, $57, $56, $5e, $62, $56, $4c, $52
    db $66, $49, $62, $51, $3e, $48, $42, $ef, $ee, $3e, $62, $49, $4c, $51, $62, $4c
    db $43, $62, $41, $3e, $4a, $3e, $44, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3a
    db $3e, $51, $40, $45, $62, $56, $4c, $52, $4f, $ef, $ee, $2b, $33, $62, $3e, $4b
    db $41, $62, $51, $3e, $48, $42, $62, $46, $51, $fa, $f7, $ef, $ee, $41, $4c, $54
    db $4b, $62, $4e, $52, $46, $40, $48, $49, $56, $5f, $ef, $ee, $f7, $f0
TextStr_46_62e7:           ; id $0354
    ; "*:BigBang, Hellblast / MultiCut.... / *:You know what I mean? [YES/NO]"
    db $ea, $9f, $a3, $25, $46, $44, $25, $3e, $4b, $44, $5e, $ef, $ee, $2b, $42, $49
    db $49, $3f, $49, $3e, $50, $51, $fa, $f7, $ef, $ee, $30, $52, $49, $51, $46, $26
    db $52, $51, $5f, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c
    db $52, $62, $48, $4b, $4c, $54, $ef, $ee, $54, $45, $3e, $51, $62, $2c, $62, $4a
    db $42, $3e, $4b, $64, $ff, $f0
TextStr_46_632d:           ; id $0355
    ; "*:I see. you've grown to be a / respectable master!"
    db $ea, $9f, $a3, $2c, $62, $50, $42, $42, $5f, $62, $56, $4c, $52, $6c, $42, $ef
    db $ee, $44, $4f, $4c, $54, $4b, $62, $51, $4c, $62, $3f, $42, $62, $3e, $fa, $f7
    db $ef, $ee, $4f, $42, $50, $4d, $42, $40, $51, $3e, $3f, $49, $42, $ef, $ee, $4a
    db $3e, $50, $51, $42, $4f, $63, $f7, $f0
TextStr_46_6365:           ; id $0356
    ; "*:Ho ho ho!! They were names of / special skills!"
    db $ea, $9f, $a3, $2b, $4c, $62, $45, $4c, $62, $45, $4c, $63, $63, $ef, $ee, $37
    db $45, $42, $56, $62, $54, $42, $4f, $42, $62, $4b, $3e, $4a, $42, $50, $62, $4c
    db $43, $fa, $f7, $ef, $ee, $50, $4d, $42, $40, $46, $3e, $49, $62, $50, $48, $46
    db $49, $49, $50, $63, $ef, $ee, $f7, $f0
TextStr_46_639d:           ; id $0357
    ; "*:Even though we are Horks, we / don't like BadMeat."
    db $ea, $9f, $a3, $28, $53, $42, $4b, $62, $51, $45, $4c, $52, $44, $45, $62, $54
    db $42, $ef, $ee, $3e, $4f, $42, $62, $2b, $4c, $4f, $48, $50, $5e, $62, $54, $42
    db $fa, $f7, $ef, $ee, $41, $4c, $4b, $67, $62, $49, $46, $48, $42, $ef, $ee, $25
    db $3e, $41, $30, $42, $3e, $51, $5f, $f7, $f0
TextStr_46_63d6:           ; id $0358
    ; "*:..Hm. A girl... named San... / something is going / *:to open a new gate for you?"
    db $eb, $9f, $a3, $5f, $5f, $2b, $4a, $5f, $62, $24, $62, $44, $46, $4f, $49, $5f
    db $5f, $5f, $ef, $ee, $4b, $3e, $4a, $42, $41, $62, $36, $3e, $4b, $5f, $5f, $5f
    db $fa, $f7, $ef, $ee, $50, $4c, $4a, $42, $51, $45, $46, $4b, $44, $62, $46, $50
    db $62, $44, $4c, $46, $4b, $44, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $51, $4c
    db $62, $4c, $4d, $42, $4b, $62, $3e, $62, $4b, $42, $54, $ef, $ee, $44, $3e, $51
    db $42, $62, $43, $4c, $4f, $62, $56, $4c, $52, $64, $f7, $f0
TextStr_46_6432:           ; id $0359
    ; "*:Oh, that's a WingSlime! Cute! / *:For bringing it here. I'll give / you a reward."
    db $eb, $9f, $a3, $32, $45, $5e, $62, $51, $45, $3e, $51, $68, $62, $3e, $ef, $ee
    db $3a, $46, $4b, $44, $36, $49, $46, $4a, $42, $63, $62, $26, $52, $51, $42, $63
    db $fa, $f7, $ef, $ee, $9f, $a3, $29, $4c, $4f, $62, $3f, $4f, $46, $4b, $44, $46
    db $4b, $44, $62, $46, $51, $ef, $ee, $45, $42, $4f, $42, $5f, $62, $2c, $66, $49
    db $62, $44, $46, $53, $42, $fa, $f7, $ef, $ee, $56, $4c, $52, $62, $3e, $62, $4f
    db $42, $54, $3e, $4f, $41, $5f, $ef, $ee, $fa, $f7, $f0
TextStr_46_648d:           ; id $035A
    ; "*:...but you don't have any more room / to carry it. / *:Get rid of something and come / back later."
    db $eb, $9f, $a3, $5f, $5f, $5f, $3f, $52, $51, $62, $56, $4c, $52, $62, $41, $4c
    db $4b, $67, $ef, $ee, $45, $3e, $53, $42, $62, $3e, $4b, $56, $62, $4a, $4c, $4f
    db $42, $62, $4f, $4c, $4c, $4a, $fa, $f7, $ef, $ee, $51, $4c, $62, $40, $3e, $4f
    db $4f, $56, $62, $46, $51, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2a, $42
    db $51, $62, $4f, $46, $41, $62, $4c, $43, $ef, $ee, $50, $4c, $4a, $42, $51, $45
    db $46, $4b, $44, $62, $3e, $4b, $41, $62, $40, $4c, $4a, $42, $fa, $f7, $ef, $ee
    db $3f, $3e, $40, $48, $62, $49, $3e, $51, $42, $4f, $5f, $ef, $ee, $f7, $f0
TextStr_46_64fc:           ; id $035B
    ; "*:It is a Sirloin. Use it wisely."
    db $eb, $9f, $a3, $2c, $51, $62, $46, $50, $62, $3e, $62, $36, $46, $4f, $49, $4c
    db $46, $4b, $5f, $ef, $ee, $38, $50, $42, $62, $46, $51, $62, $54, $46, $50, $42
    db $49, $56, $5f, $f7, $f0
TextStr_46_6521:           ; id $035C
    ; "*:You, comply with my next wish. / *:I want to see a KingSlime! / *:A KingSlime looks like a / giant Slime!"
    db $eb, $9f, $a3, $3c, $4c, $52, $5e, $62, $40, $4c, $4a, $4d, $49, $56, $62, $54
    db $46, $51, $45, $ef, $ee, $4a, $56, $62, $4b, $42, $55, $51, $62, $54, $46, $50
    db $45, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $54, $3e, $4b, $51, $62, $51
    db $4c, $62, $50, $42, $42, $ef, $ee, $3e, $62, $2e, $46, $4b, $44, $36, $49, $46
    db $4a, $42, $63, $fa, $f7, $ef, $ee, $9f, $a3, $24, $62, $2e, $46, $4b, $44, $36
    db $49, $46, $4a, $42, $ef, $ee, $49, $4c, $4c, $48, $50, $62, $49, $46, $48, $42
    db $62, $3e, $fa, $f7, $ef, $ee, $44, $46, $3e, $4b, $51, $62, $36, $49, $46, $4a
    db $42, $63, $ef, $ee, $f7, $f0
TextStr_46_6597:           ; id $035D
    ; "*:You're at the Room of / Joy and Wisdom. / *:Go right to the Gate of Wisdom. / Left to the Gate of Joy."
    db $ea, $9f, $a3, $3c, $4c, $52, $69, $42, $62, $3e, $51, $ef, $ee, $51, $45, $42
    db $62, $35, $4c, $4c, $4a, $62, $4c, $43, $fa, $f7, $ef, $ee, $2d, $4c, $56, $62
    db $3e, $4b, $41, $62, $3a, $46, $50, $41, $4c, $4a, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $2a, $4c, $62, $4f, $46, $44, $45, $51, $62, $51, $4c, $62, $51
    db $45, $42, $ef, $ee, $2a, $3e, $51, $42, $62, $4c, $43, $62, $3a, $46, $50, $41
    db $4c, $4a, $5f, $fa, $f7, $ef, $ee, $2f, $42, $43, $51, $62, $51, $4c, $62, $51
    db $45, $42, $ef, $ee, $2a, $3e, $51, $42, $62, $4c, $43, $62, $2d, $4c, $56, $5f
    db $f7, $f0
TextStr_46_6609:           ; id $035E
    ; "*:Oooo! Ahhhh! Where am I? / *:What? The arena? Where is my bed? / *:Oh well, I need a change of pace."
    db $ea, $9f, $a3, $32, $4c, $4c, $4c, $63, $62, $24, $45, $45, $45, $45, $63, $ef
    db $ee, $3a, $45, $42, $4f, $42, $62, $3e, $4a, $62, $2c, $64, $fa, $f7, $ef, $ee
    db $9f, $a3, $3a, $45, $3e, $51, $64, $62, $37, $45, $42, $62, $3e, $4f, $42, $4b
    db $3e, $64, $ef, $ee, $3a, $45, $42, $4f, $42, $62, $46, $50, $62, $4a, $56, $62
    db $3f, $42, $41, $64, $fa, $f7, $ef, $ee, $9f, $a3, $32, $45, $62, $54, $42, $49
    db $49, $5e, $62, $2c, $62, $4b, $42, $42, $41, $ef, $ee, $3e, $62, $40, $45, $3e
    db $4b, $44, $42, $62, $4c, $43, $62, $4d, $3e, $40, $42, $5f, $f7, $f0
TextStr_46_6677:           ; id $035F
    ; "*:Hmm. You again? I hope you got / better!"
    db $ea, $9f, $a3, $2b, $4a, $4a, $5f, $62, $3c, $4c, $52, $62, $3e, $44, $3e, $46
    db $4b, $64, $ef, $ee, $2c, $62, $45, $4c, $4d, $42, $62, $56, $4c, $52, $62, $44
    db $4c, $51, $fa, $f7, $ef, $ee, $3f, $42, $51, $51, $42, $4f, $63, $ef, $ee, $f7
    db $f0
TextStr_46_66a8:           ; id $0360
    ; "*:[HERO], why don't you go to / the Bazaar & Stable? / *:It'll be fun because the Starry / Night is coming!"
    db $ea, $9f, $a3, $f6, $5e, $62, $54, $45, $56, $ef, $ee, $41, $4c, $4b, $67, $62
    db $56, $4c, $52, $62, $44, $4c, $62, $51, $4c, $fa, $f7, $ef, $ee, $51, $45, $42
    db $62, $25, $3e, $57, $3e, $3e, $4f, $62, $b6, $62, $ef, $ee, $36, $51, $3e, $3f
    db $49, $42, $64, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $51, $66, $49, $62, $3f, $42
    db $62, $43, $52, $4b, $ef, $ee, $3f, $42, $40, $3e, $52, $50, $42, $62, $51, $45
    db $42, $62, $36, $51, $3e, $4f, $4f, $56, $fa, $f7, $ef, $ee, $31, $46, $44, $45
    db $51, $62, $46, $50, $62, $40, $4c, $4a, $46, $4b, $44, $63, $ef, $ee, $f7, $f0
TextStr_46_6718:           ; id $0361
    ; "Do you know of the Gate of / Happiness? [YES/NO]"
    db $eb, $27, $4c, $62, $56, $4c, $52, $62, $48, $4b, $4c, $54, $62, $4c, $43, $ef
    db $ee, $51, $45, $42, $62, $2a, $3e, $51, $42, $62, $4c, $43, $fa, $f7, $ef, $ee
    db $2b, $3e, $4d, $4d, $46, $4b, $42, $50, $50, $64, $ef, $ee, $ff, $f0
TextStr_46_6746:           ; id $0362
    ; "*:In the kingdom I visited, there / was a monster giving a speech. / *:I was overwhelmed by its / passion and could not talk to it. / *:A qu..."
    db $eb, $9f, $a3, $2c, $4b, $62, $51, $45, $42, $62, $48, $46, $4b, $44, $41, $4c
    db $4a, $ef, $ee, $2c, $62, $53, $46, $50, $46, $51, $42, $41, $5e, $62, $51, $45
    db $42, $4f, $42, $fa, $f7, $ef, $ee, $54, $3e, $50, $62, $3e, $62, $4a, $4c, $4b
    db $50, $51, $42, $4f, $ef, $ee, $44, $46, $53, $46, $4b, $44, $62, $3e, $62, $50
    db $4d, $42, $42, $40, $45, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $54, $3e
    db $50, $ef, $ee, $4c, $53, $42, $4f, $54, $45, $42, $49, $4a, $42, $41, $62, $3f
    db $56, $62, $46, $51, $50, $fa, $f7, $ef, $ee, $4d, $3e, $50, $50, $46, $4c, $4b
    db $62, $3e, $4b, $41, $62, $40, $4c, $52, $49, $41, $ef, $ee, $4b, $4c, $51, $62
    db $51, $3e, $49, $48, $62, $51, $4c, $62, $46, $51, $5f, $fa, $f7, $ef, $ee, $9f
    db $a3, $24, $62, $4e, $52, $4c, $51, $42, $62, $43, $4f, $4c, $4a, $62, $51, $45
    db $42, $ef, $ee, $3e, $4b, $4c, $4b, $56, $4a, $4c, $52, $50, $62, $4f, $42, $40
    db $4c, $4f, $41, $fa, $f7, $ef, $ee, $4c, $43, $62, $3e, $62, $47, $4c, $52, $4f
    db $4b, $42, $56, $5f, $ef, $ee, $f7, $f0
TextStr_46_680e:           ; id $0363
    ; "*:Are you familiar with the Gate / of Temptation? [YES/NO]"
    db $eb, $9f, $a3, $24, $4f, $42, $62, $56, $4c, $52, $62, $43, $3e, $4a, $46, $49
    db $46, $3e, $4f, $ef, $ee, $54, $46, $51, $45, $62, $51, $45, $42, $62, $2a, $3e
    db $51, $42, $fa, $f7, $ef, $ee, $4c, $43, $62, $37, $42, $4a, $4d, $51, $3e, $51
    db $46, $4c, $4b, $64, $ef, $ee, $ff, $f0
TextStr_46_6846:           ; id $0364
    ; "*:The legend of the village / of Lifecod. / *:The evil lord sent Servant from / the bowels of hell... / *:to enslave the burning village. / ..."
    db $eb, $9f, $a3, $37, $45, $42, $62, $49, $42, $44, $42, $4b, $41, $62, $4c, $43
    db $ef, $ee, $51, $45, $42, $62, $53, $46, $49, $49, $3e, $44, $42, $fa, $f7, $ef
    db $ee, $4c, $43, $62, $2f, $46, $43, $42, $40, $4c, $41, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $37, $45, $42, $62, $42, $53, $46, $49, $62, $49, $4c, $4f
    db $41, $ef, $ee, $50, $42, $4b, $51, $62, $36, $42, $4f, $53, $3e, $4b, $51, $62
    db $43, $4f, $4c, $4a, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $3f, $4c, $54, $42
    db $49, $50, $62, $4c, $43, $ef, $ee, $45, $42, $49, $49, $5f, $5f, $5f, $fa, $f7
    db $ef, $ee, $9f, $a3, $51, $4c, $62, $42, $4b, $50, $49, $3e, $53, $42, $62, $51
    db $45, $42, $ef, $ee, $3f, $52, $4f, $4b, $46, $4b, $44, $62, $53, $46, $49, $49
    db $3e, $44, $42, $5f, $fa, $f7, $ef, $ee, $32, $4b, $49, $56, $62, $3e, $62, $4a
    db $46, $44, $45, $51, $56, $62, $45, $42, $4f, $4c, $ef, $ee, $40, $3e, $4b, $62
    db $50, $3e, $53, $42, $62, $51, $45, $42, $4a, $5f, $f7, $f0
TextStr_46_6902:           ; id $0365
    ; "*:Choose one of the three Gates! / One is the Room of the King. / *:The other is the Room of Sweet / Smells, and the last is the Room / of L..."
    db $eb, $9f, $a3, $26, $45, $4c, $4c, $50, $42, $62, $4c, $4b, $42, $62, $4c, $43
    db $ef, $ee, $51, $45, $42, $62, $51, $45, $4f, $42, $42, $62, $2a, $3e, $51, $42
    db $50, $63, $fa, $f7, $ef, $ee, $32, $4b, $42, $62, $46, $50, $62, $51, $45, $42
    db $62, $35, $4c, $4c, $4a, $62, $4c, $43, $ef, $ee, $51, $45, $42, $62, $2e, $46
    db $4b, $44, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $4c, $51, $45
    db $42, $4f, $62, $46, $50, $62, $51, $45, $42, $ef, $ee, $35, $4c, $4c, $4a, $62
    db $4c, $43, $62, $36, $54, $42, $42, $51, $fa, $f7, $ef, $ee, $36, $4a, $42, $49
    db $49, $50, $5e, $62, $3e, $4b, $41, $62, $51, $45, $42, $ef, $ee, $49, $3e, $50
    db $51, $62, $46, $50, $62, $51, $45, $42, $62, $35, $4c, $4c, $4a, $fa, $f7, $ef
    db $ee, $4c, $43, $62, $2f, $46, $4d, $50, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $24, $62, $4e, $52, $4c, $51, $42, $62, $43, $4f, $4c, $4a, $ef
    db $ee, $2b, $42, $49, $4d, $62, $43, $4c, $4f, $62, $51, $45, $42, $62, $2f, $4c
    db $50, $51, $5f, $f7, $f0
TextStr_46_69c7:           ; id $0366
    ; "King:Oh [HERO]! You beat Jamirus. / King:Once you find a monster, feed / them meat to make them tame."
    db $ea, $2e, $46, $4b, $44, $a3, $32, $45, $62, $f6, $63, $ef, $ee, $3c, $4c, $52
    db $62, $3f, $42, $3e, $51, $62, $2d, $3e, $4a, $46, $4f, $52, $50, $5f, $fa, $f7
    db $ef, $ee, $2e, $46, $4b, $44, $a3, $32, $4b, $40, $42, $62, $56, $4c, $52, $62
    db $43, $46, $4b, $41, $ef, $ee, $3e, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $5e
    db $62, $43, $42, $42, $41, $fa, $f7, $ef, $ee, $51, $45, $42, $4a, $62, $4a, $42
    db $3e, $51, $62, $51, $4c, $62, $4a, $3e, $48, $42, $ef, $ee, $51, $45, $42, $4a
    db $62, $51, $3e, $4a, $42, $5f, $f7, $f0
TextStr_46_6a2f:           ; id $0367
    ; "King:[HERO], At ease. / King:It's a good idea to talk to / people! / King:You're dismissed. / King:Busy! Busy! Busy!...."
    db $ea, $2e, $46, $4b, $44, $a3, $f6, $5e, $ef, $ee, $24, $51, $62, $42, $3e, $50
    db $42, $5f, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $2c, $51, $68, $62, $3e
    db $62, $44, $4c, $4c, $41, $ef, $ee, $46, $41, $42, $3e, $62, $51, $4c, $62, $51
    db $3e, $49, $48, $62, $51, $4c, $fa, $f7, $ef, $ee, $4d, $42, $4c, $4d, $49, $42
    db $63, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $3c, $4c, $52, $69
    db $42, $ef, $ee, $41, $46, $50, $4a, $46, $50, $50, $42, $41, $5f, $fa, $f7, $ef
    db $ee, $2e, $46, $4b, $44, $a3, $25, $52, $50, $56, $63, $62, $25, $52, $50, $56
    db $63, $ef, $ee, $25, $52, $50, $56, $63, $5f, $5f, $5f, $5f, $f7, $f0
TextStr_46_6aad:           ; id $0368
    ; "*:Oh [HERO], It's me. / The receptionist! / *:You did great! Here's your / reward. *Kiss*"
    db $ea, $9f, $a3, $32, $45, $62, $f6, $5e, $ef, $ee, $2c, $51, $68, $62, $4a, $42
    db $5f, $fa, $f7, $ef, $ee, $37, $45, $42, $62, $4f, $42, $40, $42, $4d, $51, $46
    db $4c, $4b, $46, $50, $51, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c
    db $52, $62, $41, $46, $41, $62, $44, $4f, $42, $3e, $51, $63, $ef, $ee, $2b, $42
    db $4f, $42, $68, $62, $56, $4c, $52, $4f, $fa, $f7, $ef, $ee, $4f, $42, $54, $3e
    db $4f, $41, $5f, $62, $9f, $2e, $46, $50, $50, $9f, $ef, $ee, $f7, $f0
TextStr_46_6b0b:           ; id $0369
    ; "King:Oh [HERO]! You beat Servant! / King:What? You resisted the / temptation and were victorious? / King:Your heart is as pure as / MegaMagi..."
    db $ea, $2e, $46, $4b, $44, $a3, $32, $45, $62, $f6, $63, $ef, $ee, $3c, $4c, $52
    db $62, $3f, $42, $3e, $51, $62, $36, $42, $4f, $53, $3e, $4b, $51, $63, $fa, $f7
    db $ef, $ee, $2e, $46, $4b, $44, $a3, $3a, $45, $3e, $51, $64, $ef, $ee, $3c, $4c
    db $52, $62, $4f, $42, $50, $46, $50, $51, $42, $41, $62, $51, $45, $42, $fa, $f7
    db $ef, $ee, $51, $42, $4a, $4d, $51, $3e, $51, $46, $4c, $4b, $62, $3e, $4b, $41
    db $ef, $ee, $54, $42, $4f, $42, $62, $53, $46, $40, $51, $4c, $4f, $46, $4c, $52
    db $50, $64, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $3c, $4c, $52, $4f, $62
    db $45, $42, $3e, $4f, $51, $ef, $ee, $46, $50, $62, $3e, $50, $62, $4d, $52, $4f
    db $42, $62, $3e, $50, $fa, $f7, $ef, $ee, $30, $42, $44, $3e, $30, $3e, $44, $46
    db $40, $63, $ef, $ee, $f7, $f0
TextStr_46_6ba1:           ; id $036A
    ; "King:Oh, [HERO]! You beat Orochi! / King:This means... you've already / collected 100 monsters? / King:That's my [HERO]! You're / as good as..."
    db $ea, $2e, $46, $4b, $44, $a3, $32, $45, $5e, $62, $f6, $63, $ef, $ee, $3c, $4c
    db $52, $62, $3f, $42, $3e, $51, $62, $32, $4f, $4c, $40, $45, $46, $63, $fa, $f7
    db $ef, $ee, $2e, $46, $4b, $44, $a3, $37, $45, $46, $50, $62, $4a, $42, $3e, $4b
    db $50, $5f, $5f, $5f, $ef, $ee, $56, $4c, $52, $6c, $42, $62, $3e, $49, $4f, $42
    db $3e, $41, $56, $fa, $f7, $ef, $ee, $40, $4c, $49, $49, $42, $40, $51, $42, $41
    db $62, $01, $00, $00, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $64, $fa
    db $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $37, $45, $3e, $51, $68, $62, $4a, $56
    db $ef, $ee, $f6, $63, $62, $3c, $4c, $52, $69, $42, $fa, $f7, $ef, $ee, $3e, $50
    db $62, $44, $4c, $4c, $41, $62, $3e, $50, $62, $2c, $ef, $ee, $45, $4c, $4d, $42
    db $41, $63, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $26, $4c, $49, $49, $42
    db $40, $51, $ef, $ee, $4a, $4c, $4f, $42, $62, $51, $56, $4d, $42, $50, $fa, $f7
    db $ef, $ee, $4c, $43, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $63, $ef, $ee
    db $f7, $f0
TextStr_46_6c63:           ; id $036B
    ; "*:There must be some reason that.. / *:Watabou's ancestor's wanted / us to hold the tournament."
    db $eb, $9f, $a3, $37, $45, $42, $4f, $42, $62, $4a, $52, $50, $51, $62, $3f, $42
    db $ef, $ee, $50, $4c, $4a, $42, $62, $4f, $42, $3e, $50, $4c, $4b, $62, $51, $45
    db $3e, $51, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $3e, $51, $3e, $3f, $4c
    db $52, $68, $ef, $ee, $3e, $4b, $40, $42, $50, $51, $4c, $4f, $68, $62, $54, $3e
    db $4b, $51, $42, $41, $fa, $f7, $ef, $ee, $52, $50, $62, $51, $4c, $62, $45, $4c
    db $49, $41, $ef, $ee, $51, $45, $42, $62, $51, $4c, $52, $4f, $4b, $3e, $4a, $42
    db $4b, $51, $5f, $f7, $f0
TextStr_46_6cc8:           ; id $036C
    ; "*:Hey, the tournament is / coming! Good Luck! / *:The girl downstairs is also / rooting for you!"
    db $ea, $9f, $a3, $2b, $42, $56, $5e, $62, $51, $45, $42, $ef, $ee, $51, $4c, $52
    db $4f, $4b, $3e, $4a, $42, $4b, $51, $62, $46, $50, $fa, $f7, $ef, $ee, $40, $4c
    db $4a, $46, $4b, $44, $63, $ef, $ee, $2a, $4c, $4c, $41, $62, $2f, $52, $40, $48
    db $63, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $44, $46, $4f, $49, $ef
    db $ee, $41, $4c, $54, $4b, $50, $51, $3e, $46, $4f, $50, $62, $46, $50, $62, $3e
    db $49, $50, $4c, $fa, $f7, $ef, $ee, $4f, $4c, $4c, $51, $46, $4b, $44, $62, $43
    db $4c, $4f, $62, $56, $4c, $52, $63, $ef, $ee, $f7, $f0
TextStr_46_6d33:           ; id $036D
    ; "*:One of my relatives is / living in the kingdom of / BigTrunk."
    db $eb, $9f, $a3, $32, $4b, $42, $62, $4c, $43, $62, $4a, $56, $ef, $ee, $4f, $42
    db $49, $3e, $51, $46, $53, $42, $50, $62, $46, $50, $fa, $f7, $ef, $ee, $49, $46
    db $53, $46, $4b, $44, $62, $46, $4b, $62, $51, $45, $42, $ef, $ee, $48, $46, $4b
    db $44, $41, $4c, $4a, $62, $4c, $43, $fa, $f7, $ef, $ee, $25, $46, $44, $37, $4f
    db $52, $4b, $48, $5f, $ef, $ee, $f7, $f0
TextStr_46_6d7b:           ; id $036E
    ; "*:To tell the truth, Watabou / hasn't brought us a.. / *:A decent master in years but / you're different."
    db $eb, $9f, $a3, $37, $4c, $62, $51, $42, $49, $49, $62, $51, $45, $42, $ef, $ee
    db $51, $4f, $52, $51, $45, $5e, $62, $3a, $3e, $51, $3e, $3f, $4c, $52, $fa, $f7
    db $ef, $ee, $45, $3e, $50, $4b, $67, $62, $3f, $4f, $4c, $52, $44, $45, $51, $ef
    db $ee, $52, $50, $62, $3e, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $24, $62, $41
    db $42, $40, $42, $4b, $51, $62, $4a, $3e, $50, $51, $42, $4f, $ef, $ee, $46, $4b
    db $62, $56, $42, $3e, $4f, $50, $62, $3f, $52, $51, $fa, $f7, $ef, $ee, $56, $4c
    db $52, $69, $42, $62, $41, $46, $43, $43, $42, $4f, $42, $4b, $51, $5f, $ef, $ee
    db $f7, $f0
TextStr_46_6ded:           ; id $036F
    ; "*:Bazaar to the right! A third / store has opened!"
    db $eb, $9f, $a3, $25, $3e, $57, $3e, $3e, $4f, $62, $51, $4c, $62, $51, $45, $42
    db $ef, $ee, $4f, $46, $44, $45, $51, $63, $62, $24, $62, $51, $45, $46, $4f, $41
    db $fa, $f7, $ef, $ee, $50, $51, $4c, $4f, $42, $62, $45, $3e, $50, $62, $4c, $4d
    db $42, $4b, $42, $41, $63, $ef, $ee, $f7, $f0
TextStr_46_6e26:           ; id $0370
    ; "*:You'll always be a loser! / What's wrong with you? / *:Are you using your brain when / you breed monsters!?"
    db $eb, $9f, $a3, $3c, $4c, $52, $66, $49, $62, $3e, $49, $54, $3e, $56, $50, $ef
    db $ee, $3f, $42, $62, $3e, $62, $49, $4c, $50, $42, $4f, $63, $fa, $f7, $ef, $ee
    db $3a, $45, $3e, $51, $68, $62, $54, $4f, $4c, $4b, $44, $ef, $ee, $54, $46, $51
    db $45, $62, $56, $4c, $52, $64, $fa, $f7, $ef, $ee, $9f, $a3, $24, $4f, $42, $62
    db $56, $4c, $52, $62, $52, $50, $46, $4b, $44, $ef, $ee, $56, $4c, $52, $4f, $62
    db $3f, $4f, $3e, $46, $4b, $62, $54, $45, $42, $4b, $fa, $f7, $ef, $ee, $56, $4c
    db $52, $62, $3f, $4f, $42, $42, $41, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f
    db $50, $63, $64, $f7, $f0
TextStr_46_6e9b:           ; id $0371
    ; "*:Hey! Down the stairs is the / Shrine of Starry Night! / *:For the room of Goopi, go to the / right!"
    db $ea, $9f, $a3, $2b, $42, $56, $63, $62, $27, $4c, $54, $4b, $62, $51, $45, $42
    db $ef, $ee, $50, $51, $3e, $46, $4f, $50, $62, $46, $50, $62, $51, $45, $42, $fa
    db $f7, $ef, $ee, $36, $45, $4f, $46, $4b, $42, $62, $4c, $43, $62, $36, $51, $3e
    db $4f, $4f, $56, $ef, $ee, $31, $46, $44, $45, $51, $63, $fa, $f7, $ef, $ee, $9f
    db $a3, $29, $4c, $4f, $62, $51, $45, $42, $62, $4f, $4c, $4c, $4a, $62, $4c, $43
    db $ef, $ee, $2a, $4c, $4c, $4d, $46, $5e, $62, $44, $4c, $62, $51, $4c, $62, $51
    db $45, $42, $fa, $f7, $ef, $ee, $4f, $46, $44, $45, $51, $63, $ef, $ee, $f7, $f0
TextStr_46_6f0b:           ; id $0372
    ; "*:Welcome to the Bazaar! There are / more stores open now!"
    db $eb, $9f, $a3, $3a, $42, $49, $40, $4c, $4a, $42, $62, $51, $4c, $62, $51, $45
    db $42, $ef, $ee, $25, $3e, $57, $3e, $3e, $4f, $63, $62, $37, $45, $42, $4f, $42
    db $62, $3e, $4f, $42, $fa, $f7, $ef, $ee, $4a, $4c, $4f, $42, $62, $50, $51, $4c
    db $4f, $42, $50, $62, $4c, $4d, $42, $4b, $ef, $ee, $4b, $4c, $54, $63, $f7, $f0
TextStr_46_6f4b:           ; id $0373
    ; "*:I love festivals! I'm / looking forward to the tournament! / *:I saw new stores down there!"
    db $eb, $9f, $a3, $2c, $62, $49, $4c, $53, $42, $ef, $ee, $43, $42, $50, $51, $46
    db $53, $3e, $49, $50, $63, $62, $2c, $6a, $fa, $f7, $ef, $ee, $49, $4c, $4c, $48
    db $46, $4b, $44, $62, $43, $4c, $4f, $54, $3e, $4f, $41, $ef, $ee, $51, $4c, $62
    db $51, $45, $42, $62, $51, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $63, $fa
    db $f7, $ef, $ee, $9f, $a3, $2c, $62, $50, $3e, $54, $62, $4b, $42, $54, $62, $50
    db $51, $4c, $4f, $42, $50, $ef, $ee, $41, $4c, $54, $4b, $62, $51, $45, $42, $4f
    db $42, $63, $f7, $f0
TextStr_46_6faf:           ; id $0374
    ; "*:This kingdom is becoming / more lively. / *:I didn't know it'd get this / busy for the tournament."
    db $eb, $9f, $a3, $37, $45, $46, $50, $62, $48, $46, $4b, $44, $41, $4c, $4a, $ef
    db $ee, $46, $50, $62, $3f, $42, $40, $4c, $4a, $46, $4b, $44, $fa, $f7, $ef, $ee
    db $4a, $4c, $4f, $42, $62, $49, $46, $53, $42, $49, $56, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $2c, $62, $41, $46, $41, $4b, $67, $62, $48, $4b, $4c, $54
    db $ef, $ee, $46, $51, $6d, $62, $44, $42, $51, $62, $51, $45, $46, $50, $fa, $f7
    db $ef, $ee, $3f, $52, $50, $56, $62, $43, $4c, $4f, $62, $51, $45, $42, $ef, $ee
    db $51, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $5f, $f7, $f0
TextStr_46_701c:           ; id $0375
    ; "*:I heard that wishes on the / Starry Night come true... / *:But my wish has never come true."
    db $eb, $9f, $a3, $2c, $62, $45, $42, $3e, $4f, $41, $62, $51, $45, $3e, $51, $ef
    db $ee, $54, $46, $50, $45, $42, $50, $62, $4c, $4b, $62, $51, $45, $42, $fa, $f7
    db $ef, $ee, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45, $51, $ef, $ee
    db $40, $4c, $4a, $42, $62, $51, $4f, $52, $42, $5f, $5f, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $25, $52, $51, $62, $4a, $56, $62, $54, $46, $50, $45, $62, $45, $3e
    db $50, $ef, $ee, $4b, $42, $53, $42, $4f, $62, $40, $4c, $4a, $42, $62, $51, $4f
    db $52, $42, $5f, $f7, $f0
TextStr_46_7081:           ; id $0376
    ; "*:New stores have opened! / *:Want to learn about what kind / of goods are in the store? [YES/NO]"
    db $ea, $9f, $a3, $31, $42, $54, $62, $50, $51, $4c, $4f, $42, $50, $62, $45, $3e
    db $53, $42, $ef, $ee, $4c, $4d, $42, $4b, $42, $41, $63, $fa, $f7, $ef, $ee, $9f
    db $a3, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $49, $42, $3e, $4f, $4b, $ef, $ee
    db $3e, $3f, $4c, $52, $51, $62, $54, $45, $3e, $51, $62, $48, $46, $4b, $41, $fa
    db $f7, $ef, $ee, $4c, $43, $62, $44, $4c, $4c, $41, $50, $62, $3e, $4f, $42, $ef
    db $ee, $46, $4b, $62, $51, $45, $42, $62, $50, $51, $4c, $4f, $42, $64, $ff, $f0
TextStr_46_70e1:           ; id $0377
    ; "*:No?! You must be a heck of a master / to say no."
    db $ea, $9f, $a3, $31, $4c, $64, $63, $62, $3c, $4c, $52, $62, $4a, $52, $50, $51
    db $62, $3f, $42, $ef, $ee, $3e, $62, $45, $42, $40, $48, $62, $4c, $43, $62, $3e
    db $62, $4a, $3e, $50, $51, $42, $4f, $fa, $f7, $ef, $ee, $51, $4c, $62, $50, $3e
    db $56, $62, $4b, $4c, $5f, $ef, $ee, $f7, $f0
TextStr_46_711a:           ; id $0378
    ; "*:Sirloin is the tastiest meat / in the world. / *:You can call monsters using / a ShinyHarp. / *:Some items have the same effect as / speci..."
    db $ea, $9f, $a3, $36, $46, $4f, $49, $4c, $46, $4b, $62, $46, $50, $62, $51, $45
    db $42, $ef, $ee, $51, $3e, $50, $51, $46, $42, $50, $51, $62, $4a, $42, $3e, $51
    db $fa, $f7, $ef, $ee, $46, $4b, $62, $51, $45, $42, $62, $54, $4c, $4f, $49, $41
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $62, $40, $3e, $4b
    db $62, $40, $3e, $49, $49, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62
    db $52, $50, $46, $4b, $44, $fa, $f7, $ef, $ee, $3e, $62, $36, $45, $46, $4b, $56
    db $2b, $3e, $4f, $4d, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $36, $4c, $4a
    db $42, $62, $46, $51, $42, $4a, $50, $62, $45, $3e, $53, $42, $ef, $ee, $51, $45
    db $42, $62, $50, $3e, $4a, $42, $62, $42, $43, $43, $42, $40, $51, $62, $3e, $50
    db $fa, $f7, $ef, $ee, $50, $4d, $42, $40, $46, $3e, $49, $62, $50, $48, $46, $49
    db $49, $50, $5f, $ef, $ee, $37, $45, $4c, $50, $42, $62, $3e, $4f, $42, $5e, $fa
    db $f7, $ef, $ee, $9f, $a3, $25, $4c, $49, $51, $36, $51, $3e, $43, $43, $62, $b6
    db $ef, $ee, $25, $4c, $49, $51, $5e, $fa, $f7, $ef, $ee, $3a, $46, $4b, $41, $36
    db $51, $3e, $43, $43, $62, $b6, $ef, $ee, $3a, $45, $46, $4f, $49, $54, $46, $4b
    db $41, $fa, $f7, $ef, $ee, $9f, $a3, $2f, $3e, $53, $3e, $36, $51, $3e, $43, $43
    db $b6, $ef, $ee, $29, $46, $4f, $42, $3f, $3e, $4b, $42, $5e, $fa, $f7, $ef, $ee
    db $36, $4b, $4c, $54, $36, $51, $3e, $43, $43, $62, $b6, $ef, $ee, $2c, $40, $42
    db $36, $51, $4c, $4f, $4a, $5e, $fa, $f7, $ef, $ee, $9f, $a3, $29, $46, $4f, $42
    db $36, $51, $3e, $43, $43, $62, $b6, $ef, $ee, $25, $49, $3e, $57, $42, $4a, $4c
    db $50, $51, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $62, $40, $3e, $4b, $62
    db $52, $50, $42, $62, $3e, $ef, $ee, $50, $51, $3e, $43, $43, $62, $50, $42, $53
    db $42, $4f, $3e, $49, $fa, $f7, $ef, $ee, $51, $46, $4a, $42, $50, $62, $52, $4b
    db $51, $46, $49, $ef, $ee, $46, $51, $62, $3f, $4f, $42, $3e, $48, $50, $5f, $f7
    db $f0
TextStr_46_728b:           ; id $0379
    ; "[HERO] checked out the treasure / chest! / It's locked!"
    db $f6, $62, $40, $45, $42, $40, $48, $42, $41, $ef, $ee, $4c, $52, $51, $62, $51
    db $45, $42, $62, $51, $4f, $42, $3e, $50, $52, $4f, $42, $fa, $f7, $ef, $ee, $40
    db $45, $42, $50, $51, $63, $ef, $ee, $fa, $f7, $ef, $ee, $2c, $51, $68, $62, $49
    db $4c, $40, $48, $42, $41, $63, $ef, $ee, $f7, $f0
TextStr_46_72c5:           ; id $037A
    ; "*:Hm.. It seems there are several / hidden Gates in this kingdom. / *:I don't know where they are. / But I'm sure they'll be useful."
    db $eb, $9f, $a3, $2b, $4a, $5f, $5f, $62, $2c, $51, $62, $50, $42, $42, $4a, $50
    db $ef, $ee, $51, $45, $42, $4f, $42, $62, $3e, $4f, $42, $62, $50, $42, $53, $42
    db $4f, $3e, $49, $fa, $f7, $ef, $ee, $45, $46, $41, $41, $42, $4b, $62, $2a, $3e
    db $51, $42, $50, $62, $46, $4b, $ef, $ee, $51, $45, $46, $50, $62, $48, $46, $4b
    db $44, $41, $4c, $4a, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $41, $4c, $4b
    db $67, $62, $48, $4b, $4c, $54, $ef, $ee, $54, $45, $42, $4f, $42, $62, $51, $45
    db $42, $56, $62, $3e, $4f, $42, $5f, $fa, $f7, $ef, $ee, $25, $52, $51, $62, $2c
    db $6a, $62, $50, $52, $4f, $42, $ef, $ee, $51, $45, $42, $56, $66, $49, $62, $3f
    db $42, $62, $52, $50, $42, $43, $52, $49, $5f, $f7, $f0
TextStr_46_7350:           ; id $037B
    ; "*:Go left to the Room of / Joy & Wisdom. / *:In the center is the Room of / Strength & Anger. / *:Go right to the Room of / Peace & Bravery...."
    db $ea, $9f, $a3, $2a, $4c, $62, $49, $42, $43, $51, $62, $51, $4c, $ef, $ee, $51
    db $45, $42, $62, $35, $4c, $4c, $4a, $62, $4c, $43, $fa, $f7, $ef, $ee, $2d, $4c
    db $56, $62, $b6, $62, $3a, $46, $50, $41, $4c, $4a, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $2c, $4b, $62, $51, $45, $42, $62, $40, $42, $4b, $51, $42, $4f
    db $ef, $ee, $46, $50, $62, $51, $45, $42, $62, $35, $4c, $4c, $4a, $62, $4c, $43
    db $fa, $f7, $ef, $ee, $36, $51, $4f, $42, $4b, $44, $51, $45, $62, $b6, $62, $24
    db $4b, $44, $42, $4f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2a, $4c, $62
    db $4f, $46, $44, $45, $51, $62, $51, $4c, $ef, $ee, $51, $45, $42, $62, $35, $4c
    db $4c, $4a, $62, $4c, $43, $fa, $f7, $ef, $ee, $33, $42, $3e, $40, $42, $62, $b6
    db $62, $25, $4f, $3e, $53, $42, $4f, $56, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $2a, $4c, $46, $4b, $44, $62, $41, $4c, $54, $4b, $62, $51, $45, $42, $ef
    db $ee, $50, $51, $3e, $46, $4f, $50, $62, $49, $42, $3e, $41, $50, $62, $56, $4c
    db $52, $fa, $f7, $ef, $ee, $51, $4c, $62, $51, $45, $42, $62, $35, $4c, $4c, $4a
    db $62, $4c, $43, $ef, $ee, $2b, $3e, $4d, $4d, $46, $4b, $42, $50, $50, $62, $b6
    db $fa, $f7, $ef, $ee, $37, $42, $4a, $4d, $51, $3e, $51, $46, $4c, $4b, $5f, $ef
    db $ee, $f7, $f0
TextStr_46_7443:           ; id $037C
    ; "*:The Room of Happiness & / Temptation are now open!"
    db $ea, $9f, $a3, $37, $45, $42, $62, $35, $4c, $4c, $4a, $62, $4c, $43, $ef, $ee
    db $2b, $3e, $4d, $4d, $46, $4b, $42, $50, $50, $62, $b6, $fa, $f7, $ef, $ee, $37
    db $42, $4a, $4d, $51, $3e, $51, $46, $4c, $4b, $62, $3e, $4f, $42, $ef, $ee, $4b
    db $4c, $54, $62, $4c, $4d, $42, $4b, $63, $f7, $f0
TextStr_46_747d:           ; id $037D
    ; "*:Good work! Have you / found strong monsters? / *:The monsters in the stable can / tell you a lot!"
    db $ea, $9f, $a3, $2a, $4c, $4c, $41, $62, $54, $4c, $4f, $48, $63, $ef, $ee, $2b
    db $3e, $53, $42, $62, $56, $4c, $52, $fa, $f7, $ef, $ee, $43, $4c, $52, $4b, $41
    db $62, $50, $51, $4f, $4c, $4b, $44, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f
    db $50, $64, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $4a, $4c, $4b, $50
    db $51, $42, $4f, $50, $62, $46, $4b, $ef, $ee, $51, $45, $42, $62, $50, $51, $3e
    db $3f, $49, $42, $62, $40, $3e, $4b, $fa, $f7, $ef, $ee, $51, $42, $49, $49, $62
    db $56, $4c, $52, $62, $3e, $62, $49, $4c, $51, $63, $ef, $ee, $f7, $f0
TextStr_46_74eb:           ; id $037E
    ; "SMACK! / Something hit [HERO] and / bounced off."
    db $36, $30, $24, $26, $2e, $63, $ef, $ee, $fa, $f7, $ef, $ee, $36, $4c, $4a, $42
    db $51, $45, $46, $4b, $44, $62, $45, $46, $51, $ef, $ee, $f6, $62, $3e, $4b, $41
    db $fa, $f7, $ef, $ee, $3f, $4c, $52, $4b, $40, $42, $41, $62, $4c, $43, $43, $5f
    db $ef, $ee, $f7, $f0
TextStr_46_751f:           ; id $037F
    ; "*:We monsters become lively when / the Starry Night nears. / *:I wonder if the stars give us / power?"
    db $ea, $9f, $a3, $3a, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $ef, $ee
    db $3f, $42, $40, $4c, $4a, $42, $62, $49, $46, $53, $42, $49, $56, $62, $54, $45
    db $42, $4b, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $36, $51, $3e, $4f, $4f, $56
    db $62, $31, $46, $44, $45, $51, $ef, $ee, $4b, $42, $3e, $4f, $50, $5f, $fa, $f7
    db $ef, $ee, $9f, $a3, $2c, $62, $54, $4c, $4b, $41, $42, $4f, $62, $46, $43, $62
    db $51, $45, $42, $ef, $ee, $50, $51, $3e, $4f, $50, $62, $44, $46, $53, $42, $62
    db $52, $50, $fa, $f7, $ef, $ee, $4d, $4c, $54, $42, $4f, $64, $ef, $ee, $f7, $f0
TextStr_46_758f:           ; id $0380
    ; "*:There are monsters with / amazing skills! / *:You might find out if you ask at / the stable!"
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $62, $3e, $4f, $42, $ef, $ee, $4a, $4c
    db $4b, $50, $51, $42, $4f, $50, $62, $54, $46, $51, $45, $fa, $f7, $ef, $ee, $3e
    db $4a, $3e, $57, $46, $4b, $44, $62, $50, $48, $46, $49, $49, $50, $63, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $62, $4a, $46, $44, $45, $51, $62
    db $43, $46, $4b, $41, $ef, $ee, $4c, $52, $51, $62, $46, $43, $62, $56, $4c, $52
    db $62, $3e, $50, $48, $62, $3e, $51, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $50
    db $51, $3e, $3f, $49, $42, $63, $ef, $ee, $f7, $f0
TextStr_46_75f9:           ; id $0381
    ; "*:I heard there is something that can / change our personalities. / *:It's called a Book."
    db $ea, $9f, $a3, $2c, $62, $45, $42, $3e, $4f, $41, $62, $51, $45, $42, $4f, $42
    db $62, $46, $50, $ef, $ee, $50, $4c, $4a, $42, $51, $45, $46, $4b, $44, $62, $51
    db $45, $3e, $51, $62, $40, $3e, $4b, $fa, $f7, $ef, $ee, $40, $45, $3e, $4b, $44
    db $42, $62, $4c, $52, $4f, $ef, $ee, $4d, $42, $4f, $50, $4c, $4b, $3e, $49, $46
    db $51, $46, $42, $50, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $51, $68, $62, $40
    db $3e, $49, $49, $42, $41, $ef, $ee, $3e, $62, $25, $4c, $4c, $48, $5f, $f7, $f0
TextStr_46_7659:           ; id $0382
    ; "*:Hello. The stable is below / here. Bleat. / *:The Monster Minister is here / at the stable. / *:The Monster Minister knows / where each mo..."
    db $ea, $9f, $a3, $2b, $42, $49, $49, $4c, $5f, $62, $37, $45, $42, $ef, $ee, $50
    db $51, $3e, $3f, $49, $42, $62, $46, $50, $62, $3f, $42, $49, $4c, $54, $fa, $f7
    db $ef, $ee, $45, $42, $4f, $42, $5f, $62, $25, $49, $42, $3e, $51, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $30, $4c, $4b, $50, $51, $42
    db $4f, $ef, $ee, $30, $46, $4b, $46, $50, $51, $42, $4f, $62, $46, $50, $62, $45
    db $42, $4f, $42, $fa, $f7, $ef, $ee, $3e, $51, $62, $51, $45, $42, $62, $50, $51
    db $3e, $3f, $49, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42
    db $62, $30, $4c, $4b, $50, $51, $42, $4f, $ef, $ee, $30, $46, $4b, $46, $50, $51
    db $42, $4f, $62, $48, $4b, $4c, $54, $50, $fa, $f7, $ef, $ee, $54, $45, $42, $4f
    db $42, $62, $42, $3e, $40, $45, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $ef, $ee
    db $49, $46, $53, $42, $50, $5f, $62, $25, $49, $42, $3e, $51, $5f, $f7, $f0
TextStr_46_7708:           ; id $0383
    ; "*:Having a monster read a QuestBk / makes them brave. / *:Having them read HorrorBk makes / them cowardly. / *:BeNiceBk make them gentle. / ..."
    db $ea, $9f, $a3, $2b, $3e, $53, $46, $4b, $44, $62, $3e, $62, $4a, $4c, $4b, $50
    db $51, $42, $4f, $ef, $ee, $4f, $42, $3e, $41, $62, $3e, $62, $34, $52, $42, $50
    db $51, $25, $48, $fa, $f7, $ef, $ee, $4a, $3e, $48, $42, $50, $62, $51, $45, $42
    db $4a, $62, $3f, $4f, $3e, $53, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $2b, $3e, $53, $46, $4b, $44, $62, $51, $45, $42, $4a, $62, $4f, $42, $3e, $41
    db $ef, $ee, $2b, $4c, $4f, $4f, $4c, $4f, $25, $48, $62, $4a, $3e, $48, $42, $50
    db $fa, $f7, $ef, $ee, $51, $45, $42, $4a, $62, $40, $4c, $54, $3e, $4f, $41, $49
    db $56, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25, $42, $31, $46, $40, $42
    db $25, $48, $ef, $ee, $4a, $3e, $48, $42, $62, $51, $45, $42, $4a, $62, $44, $42
    db $4b, $51, $49, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $26, $45, $42, $3e, $51
    db $42, $4f, $25, $48, $62, $4a, $3e, $48, $42, $50, $ef, $ee, $51, $45, $42, $4a
    db $62, $40, $4c, $49, $41, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $36, $4a, $3e, $4f
    db $51, $25, $48, $62, $4a, $3e, $48, $42, $50, $ef, $ee, $51, $45, $42, $4a, $62
    db $51, $45, $46, $4b, $48, $62, $45, $3e, $4f, $41, $5f, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $26, $4c, $4a, $42, $41, $56, $25, $48, $62, $4a, $3e, $48, $42, $50
    db $ef, $ee, $51, $45, $42, $4a, $62, $44, $4c, $4c, $43, $56, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $25, $52, $51, $62, $46, $51, $62, $4a, $46, $44, $45, $51, $62
    db $4b, $4c, $51, $ef, $ee, $54, $4c, $4f, $48, $62, $54, $42, $49, $49, $62, $54
    db $46, $51, $45, $fa, $f7, $ef, $ee, $4c, $4b, $49, $56, $62, $4c, $4b, $42, $62
    db $51, $4f, $56, $63, $ef, $ee, $f7, $f0
TextStr_46_7840:           ; id $0384
    ; "*:My parents' ancestors were / bred a lot. / *:Thanks to them, they say I'll have / a long life!"
    db $eb, $9f, $a3, $30, $56, $62, $4d, $3e, $4f, $42, $4b, $51, $50, $5c, $ef, $ee
    db $3e, $4b, $40, $42, $50, $51, $4c, $4f, $50, $62, $54, $42, $4f, $42, $fa, $f7
    db $ef, $ee, $3f, $4f, $42, $41, $62, $3e, $62, $49, $4c, $51, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $37, $45, $3e, $4b, $48, $50, $62, $51, $4c, $62, $51
    db $45, $42, $4a, $5e, $ef, $ee, $51, $45, $42, $56, $62, $50, $3e, $56, $62, $2c
    db $66, $49, $62, $45, $3e, $53, $42, $fa, $f7, $ef, $ee, $3e, $62, $49, $4c, $4b
    db $44, $62, $49, $46, $43, $42, $63, $ef, $ee, $f7, $f0
TextStr_46_78ab:           ; id $0385
    ; "*:I'm pretty much a coward. / *:I wish there was some way to / become brave!"
    db $ea, $9f, $a3, $2c, $6a, $62, $4d, $4f, $42, $51, $51, $56, $62, $4a, $52, $40
    db $45, $ef, $ee, $3e, $62, $40, $4c, $54, $3e, $4f, $41, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $2c, $62, $54, $46, $50, $45, $62, $51, $45, $42, $4f, $42, $ef, $ee
    db $54, $3e, $50, $62, $50, $4c, $4a, $42, $62, $54, $3e, $56, $62, $51, $4c, $fa
    db $f7, $ef, $ee, $3f, $42, $40, $4c, $4a, $42, $62, $3f, $4f, $3e, $53, $42, $63
    db $ef, $ee, $f7, $f0
TextStr_46_78ff:           ; id $0386
    ; "*:Down below, behind the Gtae of / Temptation, a monster called / DarkEye lives. / *:DarkEye has PalsyAir & / MetalCut!"
    db $eb, $9f, $a3, $27, $4c, $54, $4b, $62, $3f, $42, $49, $4c, $54, $5e, $ef, $ee
    db $3f, $42, $45, $46, $4b, $41, $62, $51, $45, $42, $62, $2a, $51, $3e, $42, $62
    db $4c, $43, $fa, $f7, $ef, $ee, $37, $42, $4a, $4d, $51, $3e, $51, $46, $4c, $4b
    db $5e, $62, $3e, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $40, $3e, $49
    db $49, $42, $41, $fa, $f7, $ef, $ee, $27, $3e, $4f, $48, $28, $56, $42, $62, $49
    db $46, $53, $42, $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $27, $3e, $4f
    db $48, $28, $56, $42, $62, $45, $3e, $50, $ef, $ee, $33, $3e, $49, $50, $56, $24
    db $46, $4f, $62, $b6, $fa, $f7, $ef, $ee, $30, $42, $51, $3e, $49, $26, $52, $51
    db $63, $ef, $ee, $f7, $f0
TextStr_46_7984:           ; id $0387
    ; "*:Copycopy. I wanna copycopy / DeadNite copycopy. / *:Heal, DeChaos & CurseOff. / Recovery is my specialty!"
    db $eb, $9f, $a3, $26, $4c, $4d, $56, $40, $4c, $4d, $56, $5f, $62, $2c, $ef, $ee
    db $54, $3e, $4b, $4b, $3e, $62, $40, $4c, $4d, $56, $40, $4c, $4d, $56, $fa, $f7
    db $ef, $ee, $27, $42, $3e, $41, $31, $46, $51, $42, $62, $40, $4c, $4d, $56, $40
    db $4c, $4d, $56, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $42, $3e, $49
    db $5e, $62, $27, $42, $26, $45, $3e, $4c, $50, $ef, $ee, $b6, $62, $26, $52, $4f
    db $50, $42, $32, $43, $43, $5f, $fa, $f7, $ef, $ee, $35, $42, $40, $4c, $53, $42
    db $4f, $56, $62, $46, $50, $62, $4a, $56, $ef, $ee, $50, $4d, $42, $40, $46, $3e
    db $49, $51, $56, $63, $f7, $f0
TextStr_46_79fa:           ; id $0388
    ; "*:Hello! I am Helo. / *:My former master wanted to increase / his monsters so / *:he intentionally extended the fight / and gave them lots o..."
    db $eb, $9f, $a3, $2b, $42, $49, $49, $4c, $63, $ef, $ee, $2c, $62, $3e, $4a, $62
    db $2b, $42, $49, $4c, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $30, $56, $62, $43, $4c
    db $4f, $4a, $42, $4f, $62, $4a, $3e, $50, $51, $42, $4f, $ef, $ee, $54, $3e, $4b
    db $51, $42, $41, $62, $51, $4c, $62, $46, $4b, $40, $4f, $42, $3e, $50, $42, $fa
    db $f7, $ef, $ee, $45, $46, $50, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62
    db $50, $4c, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $45, $42, $62, $46, $4b, $51
    db $42, $4b, $51, $46, $4c, $4b, $3e, $49, $49, $56, $ef, $ee, $42, $55, $51, $42
    db $4b, $41, $42, $41, $62, $51, $45, $42, $62, $43, $46, $44, $45, $51, $fa, $f7
    db $ef, $ee, $3e, $4b, $41, $62, $44, $3e, $53, $42, $62, $51, $45, $42, $4a, $ef
    db $ee, $49, $4c, $51, $50, $62, $4c, $43, $62, $51, $4f, $42, $3e, $51, $50, $5f
    db $fa, $f7, $ef, $ee, $9f, $a3, $37, $4c, $62, $41, $4c, $62, $51, $45, $3e, $51
    db $5e, $62, $45, $42, $ef, $ee, $51, $4c, $4c, $48, $62, $4c, $4b, $49, $56, $62
    db $54, $42, $3e, $48, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50
    db $62, $54, $46, $51, $45, $62, $45, $46, $4a, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $36, $4c, $4a, $42, $51, $46, $4a, $42, $50, $62, $45, $42, $ef, $ee
    db $51, $4c, $4c, $48, $62, $4c, $4b, $49, $56, $62, $4c, $4b, $42, $fa, $f7, $ef
    db $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $5f, $62, $2b, $42, $62, $51, $4f, $46
    db $42, $41, $ef, $ee, $4a, $3e, $4b, $56, $62, $46, $41, $42, $3e, $50, $5f, $f7
    db $f0
TextStr_46_7b1b:           ; id $0389
    ; "*:Go up 3 times, left once! / ....zzz... / *:Go down twice then left! / ....zzz... / *:Remember my words when you're / lost.... ....zzz..."
    db $ea, $9f, $a3, $2a, $4c, $62, $52, $4d, $62, $03, $62, $51, $46, $4a, $42, $50
    db $5e, $ef, $ee, $49, $42, $43, $51, $62, $4c, $4b, $40, $42, $63, $fa, $f7, $ef
    db $ee, $5f, $5f, $5f, $5f, $57, $57, $57, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $2a, $4c, $62, $41, $4c, $54, $4b, $62, $51, $54, $46, $40, $42
    db $ef, $ee, $51, $45, $42, $4b, $62, $49, $42, $43, $51, $63, $fa, $f7, $ef, $ee
    db $5f, $5f, $5f, $5f, $57, $57, $57, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $35, $42, $4a, $42, $4a, $3f, $42, $4f, $62, $4a, $56, $ef, $ee, $54
    db $4c, $4f, $41, $50, $62, $54, $45, $42, $4b, $62, $56, $4c, $52, $69, $42, $fa
    db $f7, $ef, $ee, $49, $4c, $50, $51, $5f, $5f, $5f, $5f, $ef, $ee, $5f, $5f, $5f
    db $5f, $57, $57, $57, $5f, $5f, $5f, $f7, $f0
TextStr_46_7bb4:           ; id $038A
    ; "*:...zzz..."
    db $ea, $9f, $a3, $5f, $5f, $5f, $57, $57, $57, $5f, $5f, $5f, $ef, $ee, $f7, $f0
TextStr_46_7bc4:           ; id $038B
    ; "*:There is a man who collects / medals in this kingdom. / *:You can leave for a journey near / there. / *:If you give him medals, he'll tell..."
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $62, $46, $50, $62, $3e, $62, $4a, $3e
    db $4b, $ef, $ee, $54, $45, $4c, $62, $40, $4c, $49, $49, $42, $40, $51, $50, $fa
    db $f7, $ef, $ee, $4a, $42, $41, $3e, $49, $50, $62, $46, $4b, $62, $51, $45, $46
    db $50, $ef, $ee, $48, $46, $4b, $44, $41, $4c, $4a, $5f, $fa, $f7, $ef, $ee, $9f
    db $a3, $3c, $4c, $52, $62, $40, $3e, $4b, $62, $49, $42, $3e, $53, $42, $ef, $ee
    db $43, $4c, $4f, $62, $3e, $62, $47, $4c, $52, $4f, $4b, $42, $56, $62, $4b, $42
    db $3e, $4f, $fa, $f7, $ef, $ee, $51, $45, $42, $4f, $42, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $2c, $43, $62, $56, $4c, $52, $62, $44, $46, $53, $42, $62
    db $45, $46, $4a, $ef, $ee, $4a, $42, $41, $3e, $49, $50, $5e, $62, $45, $42, $66
    db $49, $62, $51, $42, $49, $49, $fa, $f7, $ef, $ee, $56, $4c, $52, $62, $50, $4c
    db $4a, $42, $51, $45, $46, $4b, $44, $5f, $ef, $ee, $f7, $f0
TextStr_46_7c70:           ; id $038C
    ; "*:I feel the strong presence of / a powerful monster deep in the / library. / *:Why don't you check it out?"
    db $ea, $9f, $a3, $2c, $62, $43, $42, $42, $49, $62, $51, $45, $42, $ef, $ee, $50
    db $51, $4f, $4c, $4b, $44, $62, $4d, $4f, $42, $50, $42, $4b, $40, $42, $62, $4c
    db $43, $fa, $f7, $ef, $ee, $3e, $62, $4d, $4c, $54, $42, $4f, $43, $52, $49, $62
    db $4a, $4c, $4b, $50, $51, $42, $4f, $ef, $ee, $41, $42, $42, $4d, $62, $46, $4b
    db $62, $51, $45, $42, $fa, $f7, $ef, $ee, $49, $46, $3f, $4f, $3e, $4f, $56, $5f
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45, $56, $62, $41, $4c, $4b, $67
    db $62, $56, $4c, $52, $ef, $ee, $40, $45, $42, $40, $48, $62, $46, $51, $62, $4c
    db $52, $51, $64, $f7, $f0
TextStr_46_7ce5:           ; id $038D
    ; "*:Go right immediately! / *:Then you can meet the DarkHorn!"
    db $eb, $9f, $a3, $2a, $4c, $62, $4f, $46, $44, $45, $51, $ef, $ee, $46, $4a, $4a
    db $42, $41, $46, $3e, $51, $42, $49, $56, $63, $fa, $f7, $ef, $ee, $9f, $a3, $37
    db $45, $42, $4b, $62, $56, $4c, $52, $62, $40, $3e, $4b, $ef, $ee, $4a, $42, $42
    db $51, $62, $51, $45, $42, $62, $27, $3e, $4f, $48, $2b, $4c, $4f, $4b, $63, $f7
    db $f0
TextStr_46_7d26:           ; id $038E
    ; "*:My hometown is behind the Gate of / Temptation."
    db $eb, $9f, $a3, $30, $56, $62, $45, $4c, $4a, $42, $51, $4c, $54, $4b, $62, $46
    db $50, $ef, $ee, $3f, $42, $45, $46, $4b, $41, $62, $51, $45, $42, $62, $2a, $3e
    db $51, $42, $62, $4c, $43, $fa, $f7, $ef, $ee, $37, $42, $4a, $4d, $51, $3e, $51
    db $46, $4c, $4b, $5f, $ef, $ee, $f7, $f0
TextStr_46_7d5e:           ; id $038F
    ; "*:Have you met the DarkHorn deep / inside the mysterious cave? / *:This dragon used to know how to / find the DarkHorn."
    db $ea, $9f, $a3, $2b, $3e, $53, $42, $62, $56, $4c, $52, $62, $4a, $42, $51, $62
    db $51, $45, $42, $ef, $ee, $27, $3e, $4f, $48, $2b, $4c, $4f, $4b, $62, $41, $42
    db $42, $4d, $fa, $f7, $ef, $ee, $46, $4b, $50, $46, $41, $42, $62, $51, $45, $42
    db $ef, $ee, $4a, $56, $50, $51, $42, $4f, $46, $4c, $52, $50, $62, $40, $3e, $53
    db $42, $64, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $46, $50, $62, $41, $4f, $3e
    db $44, $4c, $4b, $62, $52, $50, $42, $41, $ef, $ee, $51, $4c, $62, $48, $4b, $4c
    db $54, $62, $45, $4c, $54, $62, $51, $4c, $fa, $f7, $ef, $ee, $43, $46, $4b, $41
    db $62, $51, $45, $42, $62, $27, $3e, $4f, $48, $2b, $4c, $4f, $4b, $5f, $ef, $ee
    db $f7, $f0, $00
; --- END re-sectioned text run (bank $46) ---
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

