; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $01f", ROMX[$4000], BANK[$1f]

    db $1F ; Bank number

    ; Cross-bank dispatch table (120 entries)
    ; Called via: ld hl, $1FXX / rst $10
    dw SetAnim1F_40f1                  ; Entry 0
    dw $40F8                          ; Entry 1
    dw $40FF                          ; Entry 2
    dw $400D                          ; Entry 3 — mode 0 -> table $400D (mode list $4007)
    dw $408D                          ; Entry 4 — mode 1 -> table $408D (mode list $4007)
    dw $40CD                          ; Entry 5 — mode 2 -> table $40CD (mode list $4007)
    dw $4106                          ; Entry 6 — [table $400D]; text $02C0 "*:Who makes such a darn big quake?"
    dw $412C                          ; Entry 7 — text $02C1 "*:Hey watch out! Look where you'r…"
    dw $415D                          ; Entry 8 — text $02C2 "*:Thanks to the quake, you can go…"
    dw $4193                          ; Entry 9 — text $02C3 "*:Welcome to the Bazaar! We have …"
    dw $41C8                          ; Entry 10 — text $02C4 "*:I love festivals! I'm looking f…"
    dw $422E                          ; Entry 11 — text $02C5 "*:Hi, are you a monster master? […"
    dw $4251                          ; Entry 12 — text $02C6 "*:Wow that's great! I wanna be a …"
    dw $428C                          ; Entry 13 — text $02C7 "*:I heard that only people who ha…"
    dw $42EB                          ; Entry 14 — text $02C8 "*:Wow! The quake made the Bazaar …"
    dw $436B                          ; Entry 15 — text $02C9 "*:No? You must be a veteran!"
    dw $438B                          ; Entry 16 — text $02CA "*:A SageStone and WorldDew recove…"
    dw $4579                          ; Entry 17 — text $02CB "*:I did research on what's availa…"
    dw $45C5                          ; Entry 18 — text $02CC "*:Look what the quake did to us! …"
    dw $4628                          ; Entry 19 — text $02CD "*:There is nothing around here. I…"
    dw $466C                          ; Entry 20 — text $02CE "*:It'll be better if stores are b…"
    dw $46A0                          ; Entry 21 — text $02CF "*:Don't say that. It is almost th…"
    dw $46D8                          ; Entry 22 — text $02D0 "*:Hm. It seems there are several …"
    dw $4772                          ; Entry 23 — text $02D1 "*:The room in the center is the R…"
    dw $47E7                          ; Entry 24 — text $02D2 "*:You're at the Chamber of Travel…"
    dw $48BC                          ; Entry 25 — text $02D3 "Splash! Something hit [HERO]."
    dw $48DC                          ; Entry 26 — text $02D4 "*:Where do monsters come from? *:…"
    dw $493B                          ; Entry 27 — text $02D5 "*:Oh look! The cliffs are now con…"
    dw $4997                          ; Entry 28 — text $02D6 "*:Oh Darling! *Kiss* *Kiss*"
    dw $49B6                          ; Entry 29 — text $02D7 "*:Hello. Go down to the stable. B…"
    dw $49E7                          ; Entry 30 — text $02D8 "*:Mostly garbage, but sometimes I…"
    dw $4A23                          ; Entry 31 — text $02D9 "*:Do you want to know the limit o…"
    dw $4A66                          ; Entry 32 — text $02DA "*:Despite my looks I have a high …"
    dw $4B09                          ; Entry 33 — text $02DB "*:My hometown is the Gate of Peac…"
    dw $4B35                          ; Entry 34 — text $02DC "*:Did you see the changes on the …"
    dw $4B64                          ; Entry 35 — text $02DD "*:At last, MadKnight was able to …"
    dw $4BA0                          ; Entry 36 — text $02DE "*:Go quick. You can see the good …"
    dw $4BD0                          ; Entry 37 — text $02DF "*:Goopi loves Paper-Rock- Scissor…"
    dw $4C3D                          ; Entry 38 — text $02E0 "*:Oh, [HERO]! I was waiting for y…"
    dw $4D91                          ; Entry 39 — text $02E1 "*:Well done! You survived C class…"
    dw $4E23                          ; Entry 40 — text $02E2 "*:The classes are S to G, startin…"
    dw $501B                          ; Entry 41 — text $02E3 "*:The last match will be against …"
    dw $5072                          ; Entry 42 — text $02E4 "*:Oh [HERO]! Please listen! *:I'v…"
    dw $5103                          ; Entry 43 — text $02E5 "*:The last fight in C class is go…"
    dw $5141                          ; Entry 44 — text $02E6 "*:[HERO]! We'll have to fight aga…"
    dw $5168                          ; Entry 45 — text $02E7 "*:I wonder how my brothers are do…"
    dw $51B6                          ; Entry 46 — text $02E8 "*:Do ya know! *:A BeastTail has a…"
    dw $5217                          ; Entry 47 — text $02E9 "*:I had a strange dream. This sta…"
    dw $5293                          ; Entry 48 — text $02EA "*:Oh! It's a miracle! The statue …"
    dw $52C6                          ; Entry 49 — text $02EB "*:There are stores behind the Tra…"
    dw $5377                          ; Entry 50 — text $02EC "*:Hi ho! Hi ho!"
    dw $538B                          ; Entry 51 — text $02ED "*:Yo dude! Do ya wanna know who y…"
    dw $53D1                          ; Entry 52 — text $02EE "*:Your opponent for the last matc…"
    dw $54DB                          ; Entry 53 — text $02EF "[HERO] opened the notebook. :Mons…"
    dw $561B                          ; Entry 54 — text $02F0 "*:I took notes on how to change t…"
    dw $566E                          ; Entry 55 — text $02F1 "*:This is miso shiru. Bebe, repea…"
    dw $56AB                          ; Entry 56 — text $02F2 "*:What the heck is miso shiru! Ca…"
    dw $56EA                          ; Entry 57 — text $02F3 "*:We all gather here, seeking vic…"
    dw $57FA                          ; Entry 58 — text $02F4 "[HERO] looked at the bookshelf. :…"
    dw $588F                          ; Entry 59 — text $02F5 ":Monster Diary by the Master Mons…"
    dw $595A                          ; Entry 60 — text $02F6 ":[HERO] has already conquered D c…"
    dw $5A32                          ; Entry 61 — text $02F7 "*:My daughter is the prettiest in…"
    dw $5A79                          ; Entry 62 — text $02F8 "*:You're a promising child! I'll …"
    dw $5B75                          ; Entry 63 — text $02F9 "*:Leave me alone!"
    dw $5B8B                          ; Entry 64 — text $02FA "*:My grandpa is really stubborn."
    dw $5BB0                          ; Entry 65 — text $02FB "[HERO] looked at the bookshelf. :…"
    dw $5C5F                          ; Entry 66 — text $02FC ":Journal of My Baby, Part 2. :My …"
    dw $5CE9                          ; Entry 67 — text $02FD "*:Who? Who are you? How did you g…"
    dw $5D5C                          ; Entry 68 — text $02FE "*:Good excuse. *:You are so funny."
    dw $5D87                          ; Entry 69 — text $02FF "*:Then did you sneak in to steal …"
    dw $5DBB                          ; Entry 70 — [table $408D]; text $04E0 "*:BigTrunk vs. GreatTree! *:Let's…"
    dw $5DEC                          ; Entry 71 — text $04E1 "*:The rep of GreatTree won by *:e…"
    dw $5E62                          ; Entry 72 — text $04E2 "*:DeadTree vs. GreatTree! *:Let's…"
    dw $5E93                          ; Entry 73 — text $04E3 "*:Ladies & Gents, Let's begin the…"
    dw $5FEE                          ; Entry 74 — text $04E4 "*:And now, the feared talk of the…"
    dw $60CA                          ; Entry 75 — text $04E5 "Milayou:Why...I Can't believe.. w…"
    dw $636D                          ; Entry 76 — text $04E6 "Milayou:[HERO], Are you challengi…"
    dw $6416                          ; Entry 77 — text $04E7 "Empty."
    dw $6420                          ; Entry 78 — text $04E8 "Milayou:That's my boy, Terry! You…"
    dw $64A0                          ; Entry 79 — text $04E9 "Milayou:[HERO]! You were strong!"
    dw $64BF                          ; Entry 80 — text $04EA "Warubou:Milayou! You're useless n…"
    dw $64E6                          ; Entry 81 — text $04EB "*:Congratulations! [HERO]! *:From…"
    dw $6523                          ; Entry 82 — text $04EC "May: Congratulations! That's my […"
    dw $6585                          ; Entry 83 — text $04ED "Mick:Hey [HERO]! I came back from…"
    dw $6603                          ; Entry 84 — text $04EE "Mick: Congratulations! Please sta…"
    dw $663B                          ; Entry 85 — text $04EF "King:Oh [HERO]! Well done! You wo…"
    dw $67C5                          ; Entry 86 — text $04F0 "King:Your wish will be granted by…"
    dw $690C                          ; Entry 87 — text $04F1 "King:You don't want to. I underst…"
    dw $6A5F                          ; Entry 88 — text $04F2 "King:Oh!! You will stay in GreatT…"
    dw $6BDF                          ; Entry 89 — text $04F3 "King:[HERO], go to the chamber de…"
    dw $6C85                          ; Entry 90 — text $04F4 "*:[HERO]! I thank you for your vi…"
    dw $6D97                          ; Entry 91 — text $04F5 "*:Tonight is the Starry Night. Th…"
    dw $6E41                          ; Entry 92 — text $04F6 "*:Congratulations! Tonight is the…"
    dw $6ED6                          ; Entry 93 — text $04F7 "*:You did it! [HERO]!! *:I knew y…"
    dw $6F05                          ; Entry 94 — text $04F8 "*:You did it! You won!"
    dw $6F1F                          ; Entry 95 — text $04F9 "*:Hey! Congrats!"
    dw $6F33                          ; Entry 96 — text $04FA "*:Oh my dear [HERO]! Congratulati…"
    dw $6F87                          ; Entry 97 — text $04FB "*:I was a master once. *:I won a …"
    dw $709B                          ; Entry 98 — text $04FC "*:Now let us go! To the Shrine of…"
    dw $70D3                          ; Entry 99 — text $04FD "*:Let me know when you want to go…"
    dw $7112                          ; Entry 100 — text $04FE "*:I was a master once. *:I won a …"
    dw $719B                          ; Entry 101 — text $04FF "*:Okay I'll fish for stars!"
    dw $71B9                          ; Entry 102 — [table $40CD]; text $0500 "*:No running!"
    dw $71CB                          ; Entry 103 — text $0501 "*:Squawk! Squawk!"
    dw $71E1                          ; Entry 104 — text $0502 "[HERO] looked into the jar. The j…"
    dw $7237                          ; Entry 105 — text $0503 "*:Someday I will follow [HERO]...…"
    dw $7280                          ; Entry 106 — text $0504 "Pulio:If you didn't help me... Pu…"
    dw $732E                          ; Entry 107 — text $0505 "*:Yo, I heard you won. *:Isn't it…"
    dw $737D                          ; Entry 108 — text $0506 "*:Oh! [HERO]!! You did it, you di…"
    dw $73DC                          ; Entry 109 — text $0507 "*:You won!! Yeh yeh!"
    dw $73F4                          ; Entry 110 — text $0508 "*:[HERO]! You did great!"
    dw $740B                          ; Entry 111 — text $0509 "*:You did it! Want a reward? [YES…"
    dw $742B                          ; Entry 112 — text $050A "*:... tickle. Tickle, tickle. *:T…"
    dw $7472                          ; Entry 113 — text $050B "*:Giggle.."
    dw $7481                          ; Entry 114 — text $050C "*:I danced too much and I feel di…"
    dw $74AF                          ; Entry 115 — text $050D "*:It's unbelievable to fight agai…"
    dw $754A                          ; Entry 116 — text $050E "*:It is filled with the stars tha…"
    dw $75D0                          ; Entry 117 — text $050F "*:Yes. This is the new spirit of …"
    dw $77D7                          ; Entry 118 — text $0510 "*:Now! Step to the back!"
    dw $77F3                          ; Entry 119 — text $0511 "Milayou:Yawn... I slept well... M…"

SetAnim1F_40f1:
    ld de, $4007
    call CallTextEngine
    ret


    ld de, $4007
    call RunTextHandler
    ret


    call SetAnim1F_40f1
    call RequestScreenUpdate
    ret


    db $eb
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld c, h
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld d, b
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld a, $ef
    xor $41
    ld a, $4f
    ld c, e
    ld h, d
    ccf
    ld b, [hl]
    ld b, h
    ld h, d
    ld c, [hl]
    ld d, d
    ld a, $48
    ld b, d
    ld h, h
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, h
    ld a, $51
    ld b, b
    ld b, l
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, e
    rst $28
    xor $2f
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld a, [$eff7]
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
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld a, $4b
    ld c, b
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4e
    ld d, d
    ld a, $48
    ld b, d
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld a, [$eff7]
    xor $44
    ld c, h
    ld h, d
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
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
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $25
    ld a, $57
    ld a, $3e
    ld c, a
    ld h, e
    ld h, d
    ld a, [hl-]
    ld b, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld a, [$eff7]
    xor $4b
    ld b, d
    ld d, h
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld c, c
    ld c, h
    ld d, e
    ld b, d
    rst $28
    xor $43
    ld b, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld d, e
    ld a, $49
    ld d, b
    ld h, e
    ld h, d
    inc l
    ld l, d
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
    ld d, h
    ld a, $4f
    ld b, c
    ld h, d
    ld d, c
    ld c, h
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
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld d, b
    ld a, $54
    ld h, d
    ld c, e
    ld b, d
    ld d, h
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    rst $28
    xor $4c
    ld c, e
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
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld b, [hl]
    ld e, [hl]
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld a, $ef
    xor $4a
    ld c, h
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
    ld h, h
    rst $38
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld c, h
    ld d, h
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld l, b
    rst $28
    xor $44
    ld c, a
    ld b, d
    ld a, $51
    ld h, e
    ld h, d
    inc l
    ld h, d
    ld d, h
    ld a, $4b
    ld c, e
    ld a, $62
    ccf
    ld b, d
    ld a, [$eff7]
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
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $51
    ld c, h
    ld c, h
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    rst $28
    xor $4c
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld c, l
    ld b, d
    ld c, h
    ld c, l
    ld c, c
    ld b, d
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    ld a, [$eff7]
    xor $45
    ld a, $53
    ld b, d
    ld h, d
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
    rst $28
    xor $3e
    ld d, c
    ld d, c
    ld c, a
    ld a, $40
    ld d, c
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
    ccf
    ld b, d
    ld h, d
    ld a, $62
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld e, a
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
    scf
    ld b, l
    ld b, d
    ld h, d
    ld c, [hl]
    ld d, d
    ld a, $48
    ld b, d
    rst $28
    xor $4a
    ld a, $41
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    dec h
    ld a, $57
    ld a, $3e
    ld c, a
    ld a, [$eff7]
    xor $3f
    ld b, [hl]
    ld b, h
    ld b, h
    ld b, d
    ld c, a
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    ld h, d
    ld a, $62
    ld c, a
    ld b, d
    ld d, b
    ld b, d
    ld a, $4f
    ld b, b
    ld b, l
    rst $28
    xor $4c
    ld c, e
    ld h, d
    ld d, h
    ld b, l
    ld a, $51
    ld l, b
    ld a, [$eff7]
    xor $3e
    ld d, e
    ld a, $46
    ld c, c
    ld a, $3f
    ld c, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $3a
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld h, h
    rst $28
    xor $ff
    ldh a, [$ea]
    sbc a
    and e
    ld sp, $644c
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld c, d
    ld d, d
    ld d, b
    ld d, c
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ld a, $62
    ld d, e
    ld b, d
    ld d, c
    ld b, d
    ld c, a
    ld a, $4b
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc h
    ld h, d
    ld [hl], $3e
    ld b, h
    ld b, d
    ld [hl], $51
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld a, $4b
    ld b, c
    rst $28
    xor $3a
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    daa
    ld b, d
    ld d, h
    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $2b
    inc sp
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec h
    ld c, h
    ld d, c
    ld b, l
    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    dec hl
    inc sp
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld a, $49
    ld c, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld h, d
    ld a, $ef
    xor $36
    ld a, $44
    ld b, d
    ld [hl], $51
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld d, b
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld a, $49
    ld a, [$eff7]
    xor $51
    ld b, [hl]
    ld c, d
    ld b, d
    ld d, b
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, [hl]
    ld c, c
    rst $28
    xor $42
    ld d, e
    ld b, d
    ld c, e
    ld d, c
    ld d, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld a, $48
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    rst $28
    xor $30
    inc sp
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
    inc sp
    ld c, h
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc h
    ld h, d
    ld a, [hl-]
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    cpl
    ld b, d
    ld a, $43
    rst $28
    xor $3f
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld a, [$eff7]
    xor $48
    ld c, e
    ld c, h
    ld b, b
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld c, h
    ld d, d
    ld d, c
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
    ld a, [$eff7]
    xor $9f
    and e
    dec [hl]
    ld b, [hl]
    ccf
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld a, $ef
    xor $3f
    ld b, d
    ld d, c
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld a, $4b
    ld a, [$eff7]
    xor $33
    ld c, h
    ld c, a
    ld c, b
    ld h, $45
    ld c, h
    ld c, l
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc h
    ld h, d
    jr nc, jr_01f_4505

    ld d, b
    ld d, c
    ld [hl], $51
    ld a, $43
    ld b, e
    rst $28
    xor $3f
    ld c, c
    ld c, h
    ld b, b
    ld c, b
    ld d, b
    ld h, d
    ld a, $4b
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, d
    ld d, [hl]
    ld l, b
    ld a, [$eff7]
    xor $4a
    ld a, $44
    ld b, [hl]
    ld b, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $ef
    xor $4a
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
    ld h, d
    ld c, d
    ld b, [hl]
    ld d, b
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc h
    ld h, d
    jr nc, @+$40

    ld c, l

jr_01f_4505:
    dec hl
    ld b, d
    ld c, a
    ccf
    ld h, d
    ld a, $49
    ld c, c
    ld c, h
    ld d, h
    ld d, b
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $4a
    ld a, $4d
    ld h, d
    ld a, $4f
    ld c, h
    ld d, d
    ld c, e
    ld b, c
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
    inc h
    ld h, d
    dec h
    ld c, h
    ld c, h
    ld c, b
    jr nc, jr_01f_4581

    ld c, a
    ld c, b
    rst $28
    xor $3e
    ld c, c
    ld c, c
    ld c, h
    ld d, h
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $4f
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $2d
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c

jr_01f_4581:
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld b, d
    ld a, $4f
    ld b, b
    ld b, l
    rst $28
    xor $4c
    ld c, e
    ld h, d
    ld d, h
    ld b, l
    ld a, $51
    ld l, b
    ld a, [$eff7]
    xor $3e
    ld d, e
    ld a, $46
    ld c, c
    ld a, $3f
    ld c, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $3a
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld h, h
    rst $28
    xor $ff
    ldh a, [$ea]
    sbc a
    and e
    cpl
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld d, h
    ld b, l
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4e
    ld d, d
    ld a, $48
    ld b, d
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, d
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld a, $51
    ld h, d
    ld c, d
    ld b, d
    ld c, a
    ld b, b
    ld b, l
    ld a, $4b
    ld d, c
    rst $28
    xor $54
    ld a, $50
    ld h, d
    ld d, b
    ld b, d
    ld c, l
    ld a, $4f
    ld a, $51
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $43
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld d, c
    ld h, e
    rst $28
    xor $2b
    ld a, $62
    ld b, l
    ld a, $62
    ld b, l
    ld a, $63
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
    rst $28
    xor $3e
    ld c, a
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    ld h, d
    inc l
    ld d, c
    ld a, [$eff7]
    xor $49
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld h, d
    ld b, c
    ld b, d
    ld d, b
    ld b, d
    ld c, a
    ld d, c
    ld b, d
    ld b, c
    rst $28
    xor $41
    ld c, h
    ld b, d
    ld d, b
    ld c, e
    ld h, a
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, h
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld d, c
    ld h, [hl]
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld d, c
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $46
    ld b, e
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    ld a, [$eff7]
    xor $3f
    ld d, d
    ld b, [hl]
    ld c, c
    ld d, c
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    daa
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld d, b
    ld a, $56
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld e, a
    rst $28
    xor $2c
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $49
    ld c, d
    ld c, h
    ld d, b
    ld d, c
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
    ld d, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld c, d
    ld e, a
    ld h, d
    inc l
    ld d, c
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld c, d
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld d, b
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld a, $49
    ld a, [$eff7]
    xor $44
    ld a, $51
    ld b, d
    ld d, b
    ld h, d
    ld b, l
    ld b, [hl]
    ld b, c
    ld b, c
    ld b, d
    ld c, e
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
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
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
    inc l
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
    xor $54
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld a, [$eff7]
    xor $46
    ld d, c
    ld h, d
    ld d, h
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $40
    ld b, d
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    dec [hl]
    ld c, h
    ld c, h
    ld c, d
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld [hl], $51
    ld c, a
    ld b, d
    ld c, e
    ld b, h
    ld d, c
    ld b, l
    rst $28
    xor $b6
    ld h, d
    inc h
    ld c, e
    ld b, h
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $9f
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
    xor $35
    ld c, h
    ld c, h
    ld c, d
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
    ld e, a
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
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld h, $45
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
    add hl, sp
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, $44
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $b6
    ld h, d
    scf
    ld a, $49
    ld b, [hl]
    ld d, b
    ld c, d
    ld a, $4b
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
    ld b, b
    ld b, d
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $46
    ld d, b
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
    ld a, [$eff7]
    xor $25
    ld b, d
    ld b, h
    ld b, [hl]
    ld c, e
    ld c, e
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
    xor $35
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    jr nc, jr_01f_48e3

    ld c, d
    ld c, h
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    dec h
    ld b, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld b, c
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$36]
    ld c, l
    ld c, c
    ld a, $50
    ld b, l
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $36
    ld c, h
    ld c, d
    ld b, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, c
    rst $28
    xor $f6
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, a

jr_01f_48e3:
    ld b, d
    ld h, d
    ld b, c
    ld c, h
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
    ld c, h
    ld c, d
    ld b, d
    ld a, [$eff7]
    xor $43
    ld c, a
    ld c, h
    ld c, d
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld [hl], $4c
    ld c, d
    ld b, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld d, b
    ld h, d
    inc l
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld c, e
    ld c, b
    ld h, d
    ld a, $3f
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    ld h, d
    ld d, b
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld h, e
    ld h, d
    scf
    ld b, l
    ld b, d
    rst $28
    xor $40
    ld c, c
    ld b, [hl]
    ld b, e
    ld b, e
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld a, [$eff7]
    xor $40
    ld c, h
    ld c, e
    ld c, e
    ld b, d
    ld b, b
    ld d, c
    ld b, d
    ld b, c
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    scf
    ld b, l
    ld a, $4b
    ld c, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, [hl]
    rst $28
    xor $50
    ld c, l
    ld b, [hl]
    ld c, a
    ld b, [hl]
    ld d, c
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
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    daa
    ld a, $4f
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $28
    xor $9f
    ld l, $46
    ld d, b
    ld d, b
    sbc a
    ld h, d
    sbc a
    ld l, $46
    ld d, b
    ld d, b
    sbc a
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
    ld a, [hl+]
    ld c, h
    ld h, d
    ld b, c
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
    ld b, d
    ld b, d
    ld a, $51
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    jr nc, jr_01f_4a38

    ld d, b
    ld d, c
    ld c, c
    ld d, [hl]
    ld h, d
    ld b, h
    ld a, $4f
    ccf
    ld a, $44
    ld b, d
    ld e, [hl]
    rst $28
    xor $3f
    ld d, d
    ld d, c
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld d, b
    ld h, d
    inc l
    ld a, [$eff7]
    xor $40
    ld a, $51
    ld b, b
    ld b, l
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld d, b
    ld d, c
    ld d, d
    ld b, e
    ld b, e
    ld h, e
    rst $28
    xor $f7
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
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $48
    ld c, e

jr_01f_4a38:
    ld c, h
    ld d, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $44
    ld c, a
    ld c, h
    ld d, h
    ld d, c
    ld b, l
    ld h, d
    ld c, h
    ld b, e
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
    ld d, b
    ld h, h
    rst $38
    ldh a, [$eb]
    sbc a
    and e
    daa
    ld b, d
    ld d, b
    ld c, l
    ld b, [hl]
    ld d, c
    ld b, d
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    rst $28
    xor $2c
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld a, $62
    ld b, l
    ld b, [hl]
    ld b, h
    ld b, l
    ld a, [$eff7]
    xor $44
    ld c, a
    ld c, h
    ld d, h
    ld d, c
    ld b, l
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, d
    ld b, [hl]
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
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld c, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    rst $28
    xor $3f
    ld b, d
    ld b, b
    ld a, $52
    ld d, b
    ld b, d
    ld h, d
    inc l
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    and d
    dec b
    ld a, [$eff7]
    xor $3f
    ld d, [hl]
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld c, e
    ld a, $4a
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
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld c, e
    ld c, h
    ld h, d
    ld b, [hl]
    ld b, c
    ld b, d
    ld a, $ef
    xor $54
    ld b, l
    ld a, $51
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, a
    ld b, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $4a
    ld b, d
    ld a, $4b
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    jr nc, @+$58

    ld h, d
    ld b, l
    ld c, h
    ld c, d
    ld b, d
    ld d, c
    ld c, h
    ld d, h
    ld c, e
    rst $28
    xor $46
    ld d, b
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
    ld a, [$eff7]
    xor $33
    ld b, d
    ld a, $40
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
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
    ld d, b
    ld b, d
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld h, h
    rst $28
    xor $ff
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
    rst $28
    xor $30
    ld a, $41
    ld l, $4b
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, h
    ld a, $50
    ld a, [$eff7]
    xor $3e
    ccf
    ld c, c
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, a
    ld b, d
    ld d, d
    ld c, e
    ld b, [hl]
    ld d, c
    ld b, d
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    cpl
    ld b, [hl]
    ld c, l
    ld d, b
    ld d, [hl]
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl+]
    ld c, h
    ld h, d
    ld c, [hl]
    ld d, d
    ld b, [hl]
    ld b, b
    ld c, b
    ld e, a
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $44
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld d, b
    ld d, c
    ld d, d
    ld b, e
    ld b, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl+]
    ld c, h
    ld c, h
    ld c, l
    ld b, [hl]
    ld h, d
    ld c, c
    ld c, h
    ld d, e
    ld b, d
    ld d, b
    rst $28
    xor $33
    ld a, $4d
    ld b, d
    ld c, a
    sbc h
    dec [hl]
    ld c, h
    ld b, b
    ld c, b
    sbc h
    ld a, [$eff7]
    xor $36
    ld b, b
    ld b, [hl]
    ld d, b
    ld d, b
    ld c, h
    ld c, a
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld d, c
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld a, $62
    ld b, b
    ld c, h
    ld d, d
    ld c, l
    ld c, c
    ld b, d
    rst $28
    xor $4c
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    ccf
    ld c, a
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld d, b
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    rst $28
    xor $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld e, [hl]
    ld h, d
    or $63
    rst $28
    xor $2c
    ld h, d
    ld d, h
    ld a, $50
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
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld h, d
    ld b, h
    ld a, $53
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld c, l
    ld b, d
    ld c, a
    ld c, d
    ld b, [hl]
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, h
    ld c, e
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, l
    ld b, d
    ld d, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld h, $ef
    xor $40
    ld c, c
    ld a, $50
    ld d, b
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ccf
    ld b, d
    ld d, [hl]
    ld c, h
    ld c, e
    ld b, c
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $50
    ld d, d
    ld c, a
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld [hl], $62
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl-], a
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    rst $28
    xor $50
    ld d, d
    ld c, a
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld [hl], $62
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld a, [$eff7]
    xor $40
    ld a, $4b
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
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
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, l
    rst $28
    xor $41
    ld b, [hl]
    ld c, a
    ld b, d
    ld b, b
    ld d, c
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $36
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
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
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $40
    ld c, h
    ld c, d
    ld c, l
    ld b, d
    ld d, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, h
    rst $28
    xor $f0
    ld [$a39f], a
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
    xor $3c
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
    ld b, c
    ld h, d
    ld h, $fa
    rst $30
    rst $28
    xor $40
    ld c, c
    ld a, $50
    ld d, b
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
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld c, l
    ld b, d
    ld c, e
    ld b, d
    ld b, c
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
    ld h, d
    ld b, e
    ld c, h
    ld c, a
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
    ld [hl], $51
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld b, d
    ld c, a
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
    ld a, $4f
    ld b, d
    ld a, [$eff7]
    xor $54
    ld a, $46
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
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
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld b, d
    ld d, b
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld [hl], $62
    ld d, c
    ld c, h
    ld h, d
    ld a, [hl+]
    ld e, [hl]
    ld a, [$eff7]
    xor $50
    ld d, c
    ld a, $4f
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    rst $28
    xor $51
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
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $51
    ld b, l
    ld c, a
    ld b, d
    ld b, d
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld c, l
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $40
    ld c, c
    ld a, $50
    ld d, b
    ld e, a
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
    ld b, b
    ld a, $4b
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, e
    ld b, d
    ld d, l
    ld d, c
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
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
    ld b, c
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, a
    ld b, c
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
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
    ld d, b
    ld d, d
    ld c, a
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    rst $28
    xor $36
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld b, d
    ld c, c
    ld b, [hl]
    ld b, h
    ld b, [hl]
    ccf
    ld c, c
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $4d
    ld a, $4f
    ld d, c
    ld b, [hl]
    ld b, b
    ld b, [hl]
    ld c, l
    ld a, $51
    ld b, d
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
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    rst $28
    xor $3e
    ld c, e
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, d
    ld a, $4b
    ld b, c
    ld d, b
    ld h, d
    ld d, c
    ld c, h
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
    rst $28
    xor $41
    ld d, d
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld c, e
    ld a, $fa
    rst $30
    rst $28
    xor $3f
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld e, a
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
    ld b, b
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    rst $28
    xor $46
    ld d, c
    ld b, d
    ld c, d
    ld d, b
    ld h, d
    ld b, d
    ld b, [hl]
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl], $42
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    dec [hl]
    jr c, jr_01f_4ff2

    rst $28
    xor $46
    ld d, b
    ld h, d
    ld b, b
    ld c, h
    ld c, e
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld c, a
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $44
    ld b, [hl]
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, d
    ld c, l
    ld e, a
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
    ld b, b
    ld a, $4b
    ld h, d
    ld c, a
    ld b, d
    ld b, h
    ld b, [hl]

jr_01f_4ff2:
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $3e
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld b, d
    ld c, l
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld a, [$eff7]
    xor $4c
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld a, $50
    ld d, c
    ld h, d
    ld c, d
    ld a, $51
    ld b, b
    ld b, l
    rst $28
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld d, b
    ld d, c
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $54
    ld a, $46
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, d
    ld d, c
    ld c, h
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    or $63
    rst $28
    xor $33
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, e
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld l, h
    ld b, d
    ld h, d
    ld a, $41
    ld d, e
    ld a, $4b
    ld b, b
    ld b, d
    ld b, c
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld h, $62
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld h, d
    ld d, h
    ld b, l
    ld b, [hl]
    ld c, c
    ld b, d
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $54
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
    ld h, d
    ld c, c
    ld a, $50
    ld d, c
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld h, $62
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
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
    ccf
    ld b, d
    ld h, d
    ld a, $62
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    rst $28
    xor $4c
    ld c, e
    ld b, d
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld a, $50
    ld d, c
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld h, $62
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
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
    ccf
    ld b, d
    ld h, d
    ld a, $62
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    rst $28
    xor $4c
    ld c, e
    ld b, d
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    or $63
    rst $28
    xor $3a
    ld b, d
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $43
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
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
    inc l
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld b, l
    ld c, h
    ld d, h
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $3f
    ld c, a
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    ld a, [$eff7]
    xor $41
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld h, d
    scf
    ld b, l
    ld b, d
    ld d, [hl]
    ld l, c
    ld b, d
    rst $28
    xor $41
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $53
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, $44
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    daa
    ld c, h
    ld h, d
    ld d, [hl]
    ld a, $62
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc h
    ld h, d
    dec h
    ld b, d
    ld a, $50
    ld d, c
    scf
    ld a, $46
    ld c, c
    ld h, d
    ld b, l
    ld a, $50
    rst $28
    xor $3e
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld b, b
    ld b, [hl]
    ld a, $49
    ld h, d
    ld b, d
    ld b, e
    ld b, e
    ld b, d
    ld b, b
    ld d, c
    ld e, [hl]
    ld a, [$eff7]
    xor $9f
    and e
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld b, c
    rst $28
    xor $41
    ld d, d
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $62
    ccf
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld b, l
    ld a, $41
    ld h, d
    ld a, $62
    ld d, b
    ld d, c
    ld c, a
    ld a, $4b
    ld b, h
    ld b, d
    rst $28
    xor $41
    ld c, a
    ld b, d
    ld a, $4a
    ld e, a
    ld h, d
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, b
    ld d, c
    ld a, $51
    ld d, d
    ld b, d
    ld a, [$eff7]
    xor $50
    ld d, c
    ld a, $4f
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld c, h
    ld d, e
    ld b, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr z, @+$55

    ld b, d
    ld c, e
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld l, b
    ld h, d
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld e, [hl]
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $51
    ld d, d
    ld b, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ld c, d
    ld c, h
    ld d, e
    ld b, d
    ld b, c
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, e
    ld h, d
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $ef
    xor $4a
    ld b, [hl]
    ld c, a
    ld a, $40
    ld c, c
    ld b, d
    ld h, e
    ld h, d
    scf
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $50
    ld d, c
    ld a, $51
    ld d, d
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, d
    ld c, h
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
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
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    rst $28
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
    xor $9f
    and e
    inc l
    ld h, d
    ld c, a
    ld b, d
    ld c, d
    ld b, d
    ld c, d
    ccf
    ld b, d
    ld c, a
    ld h, d
    inc l
    rst $28
    xor $40
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    ld h, d
    ld c, d
    ld d, [hl]
    ld a, [$eff7]
    xor $47
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    rst $28
    xor $51
    ld c, h
    ld c, h
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    jr z, jr_01f_5393

    ld b, b
    ld d, d
    ld d, b
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    rst $28
    xor $2c
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, h
    ld a, $51
    ld b, b
    ld b, l
    ld a, [$eff7]
    xor $4c
    ld d, d
    ld d, c
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld c, c
    ld a, $57
    ld d, [hl]
    rst $28
    xor $25
    ld c, h
    ld c, d
    ccf
    ld h, $4f
    ld a, $44
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, [hl]
    ld h, d
    ld b, l
    ld c, h
    ld h, e
    ld h, d
    dec hl
    ld b, [hl]
    ld h, d
    ld b, l
    ld c, h
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld h, d
    ld b, c
    ld d, d

jr_01f_5393:
    ld b, c
    ld b, d
    ld h, e
    ld h, d
    daa
    ld c, h
    ld h, d
    ld d, [hl]
    ld a, $ef
    xor $54
    ld a, $4b
    ld c, e
    ld a, $62
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, h
    ld c, l
    ld c, l
    ld c, h
    ld c, e
    ld b, d
    ld c, e
    ld d, c
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld h, $62
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld h, h
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, h
    ld c, l
    ld c, l
    ld c, h
    ld c, e
    ld b, d
    ld c, e
    ld d, c
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld a, $50
    ld d, c
    ld h, d
    ld c, d
    ld a, $51
    ld b, b
    ld b, l
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    scf
    ld b, d
    ld d, c
    ld c, h
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
    ld b, d
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld a, $ef
    xor $35
    ld c, h
    ld b, b
    ld c, b
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $02
    ld h, d
    dec h
    ld c, h
    ld d, l
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
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
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld b, h
    ld d, d
    ld d, [hl]
    ld d, b
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $3e
    ld c, e
    ld h, d
    ld b, d
    ld d, l
    ld d, c
    ld c, a
    ld b, d
    ld c, d
    ld b, d
    ld c, c
    ld d, [hl]
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld a, [$eff7]
    xor $41
    ld b, d
    ld b, e
    ld b, d
    ld c, e
    ld d, b
    ld b, d
    ld h, d
    ld a, $4b
    ld b, c
    rst $28
    xor $52
    ld d, b
    ld b, d
    ld h, d
    jr c, @+$4f

    ld c, l
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $51
    ld c, a
    ld c, h
    ld d, d
    ccf
    ld c, c
    ld b, d
    ld h, d
    ld b, [hl]
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
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    rst $28
    xor $3f
    ld b, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, c
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld b, c
    ld b, d
    ld b, e
    ld b, d
    ld c, e
    ld b, c
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld d, b
    ld b, d
    ld c, c
    ld d, e
    ld b, d
    ld d, b
    ld e, a
    rst $30
    ldh a, [$f6]
    ld h, d
    ld c, h
    ld c, l
    ld b, d
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4b
    ld c, h
    ld d, c
    ld b, d
    ccf
    ld c, h
    ld c, h
    ld c, b
    ld e, a
    ld a, [$eff7]
    xor $a3
    jr nc, @+$4e

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $49
    ld b, d
    ld a, $4f
    ld c, e
    ld h, d
    ld a, $49
    ld c, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $50
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld b, [hl]
    ld c, a
    rst $28
    xor $4d
    ld a, $4f
    ld b, d
    ld c, e
    ld d, c
    ld d, b
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $a3
    scf
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld a, $49
    ld d, b
    ld c, h
    rst $28
    xor $49
    ld b, d
    ld a, $4f
    ld c, e
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld b, [hl]
    ld c, a
    ld h, d
    ld b, h
    ld c, a
    ld a, $4b
    ld b, c
    ld c, l
    ld a, $4f
    ld b, d
    ld c, e
    ld d, c
    ld d, b
    rst $28
    xor $45
    ld a, $41
    ld e, a
    ld a, [$eff7]
    xor $a3
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld a, $49
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, h
    ld c, a
    ld a, $4b
    ld b, c
    ld c, l
    ld a, $4f
    ld b, d
    ld c, e
    ld d, c
    ld d, b
    ld e, h
    ld a, [$eff7]
    xor $50
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $49
    ld b, d
    ld a, $4f
    ld c, e
    ld b, d
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $a3
    ld [hl-], a
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld d, h
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld a, $4f
    ld c, e
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $3f
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld a, $4f
    ld b, d
    ld c, e
    ld d, c
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    ld b, b
    ld a, $4b
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld a, $4f
    ld c, e
    ld b, d
    ld b, c
    rst $28
    xor $3f
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, b
    ld b, [hl]
    ld b, c
    ld d, b
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld b, d
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    rst $28
    xor $45
    ld c, h
    ld d, h
    ld h, d
    ld d, c
    ld c, h
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
    ld a, [$eff7]
    xor $44
    ld b, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
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
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld h, h
    rst $28
    xor $ff
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
    ld c, d
    ld b, [hl]
    ld d, b
    ld c, h
    rst $28
    xor $50
    ld b, l
    ld b, [hl]
    ld c, a
    ld d, d
    ld e, a
    ld h, d
    dec h
    ld b, d
    ccf
    ld b, d
    ld e, [hl]
    ld a, [$eff7]
    xor $4f
    ld b, d
    ld c, l
    ld b, d
    ld a, $51
    ld h, d
    ld a, $43
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    rst $28
    xor $26
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld h, e
    rst $30
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
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $4a
    ld b, [hl]
    ld d, b
    ld c, h
    ld h, d
    ld d, b
    ld b, l
    ld b, [hl]
    ld c, a
    ld d, d
    ld h, e
    ld h, d
    ld h, $3e
    ld c, e
    ld h, a
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, a
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld d, b
    ld a, $56
    rst $28
    xor $50
    ld c, h
    ld d, d
    ld c, l
    ld h, e
    ld h, h
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, d
    ld h, d
    ld a, $49
    ld c, c
    ld h, d
    ld b, h
    ld a, $51
    ld b, l
    ld b, d
    ld c, a
    rst $28
    xor $45
    ld b, d
    ld c, a
    ld b, d
    ld e, [hl]
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $53
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr c, jr_01f_576a

    ld b, [hl]
    ld b, b
    ld c, h
    ld c, a
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, b
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
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ld b, c
    ld b, d
    ld b, e
    ld b, d
    ld c, e
    ld d, b
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
    ld d, [hl]
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    rst $28
    xor $3f
    ld b, d
    ld b, l
    ld b, [hl]

jr_01f_576a:
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    ld e, [hl]
    rst $28
    xor $3f
    ld d, d
    ld d, c
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    ld b, [hl]
    ld b, h
    ld c, e
    ld a, [$eff7]
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
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
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $4a
    ld a, $48
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld a, [$eff7]
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    rst $28
    xor $4b
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    add hl, hl
    ld a, $4b
    ld b, h
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    ld e, a
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
    ld h, d
    ld b, c
    ld a, $56
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    ld a, [hl+]
    ld b, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $40
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, l
    ld b, [hl]
    ld c, c
    ld b, d
    ld a, [$eff7]
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
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $3e
    ld c, e
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld e, a
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
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4b
    ld b, d
    ld d, l
    ld d, c
    ld h, d
    ld c, l
    ld a, $44
    ld b, d
    ld h, h
    rst $38
    ldh a, [$a3]
    jr nc, jr_01f_58de

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    daa
    ld b, [hl]
    ld a, $4f
    ld d, [hl]
    rst $28
    xor $3f
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    jr nc, jr_01f_58e6

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    or $62
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $ef
    xor $4d
    ld c, a
    ld c, h
    ld c, d
    ld b, [hl]
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, b
    ld b, [hl]
    ld b, c
    ld e, a
    ld a, [$eff7]

jr_01f_58de:
    xor $a3
    inc l
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f

jr_01f_58e6:
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld a, $53
    ld b, d
    ld b, c
    rst $28
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ccf
    ld b, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $51
    ld b, l
    ld c, a
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld b, a
    ld a, $46
    ld c, c
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld d, d
    ld c, a
    ld b, d
    rst $28
    xor $45
    ld a, $50
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld b, d
    ld d, [hl]
    ld b, d
    ld d, b
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
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4b
    ld b, d
    ld d, l
    ld d, c
    ld h, d
    ld c, l
    ld a, $44
    ld b, d
    ld h, h
    rst $38
    ldh a, [$a3]
    or $62
    ld b, l
    ld a, $50
    ld h, d
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
    inc l
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    rst $28
    xor $40
    ld c, h
    ld c, d
    ld c, l
    ld c, c
    ld b, d
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
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
    rst $28
    xor $42
    ld a, $50
    ld b, [hl]
    ld c, c
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
    xor $4d
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld b, e
    ld d, d
    ld c, c
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld h, e
    ld a, [$eff7]
    xor $a3
    ld a, [hl-]
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
    rst $28
    xor $52
    ld d, b
    ld h, d
    ld a, $62
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
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    jr nc, jr_01f_5a8d

    ld h, d
    ld b, c
    ld a, $52
    ld b, h
    ld b, l
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, c
    ld d, c
    ld b, [hl]
    ld b, d
    ld d, b
    ld d, c
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
    ld h, e
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
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld c, b
    ld h, d
    ld d, b
    ld c, h
    ld h, h
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld a, $ef
    xor $4d
    ld c, a
    ld c, h
    ld c, d
    ld b, [hl]
    ld d, b
    ld b, [hl]
    ld c, e

jr_01f_5a8d:
    ld b, h
    ld h, d
    ld b, b
    ld b, l
    ld b, [hl]
    ld c, c
    ld b, c
    ld h, e
    ld a, [$eff7]
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
    rst $28
    xor $50
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
    ld a, [$eff7]
    xor $9f
    and e
    jr nc, jr_01f_5b07

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    rst $28
    xor $41
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, e
    ld h, d
    ld d, c
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
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $4f
    ld a, $46
    ld d, b
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld a, [$eff7]
    xor $43
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld c, h
    ld c, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f

jr_01f_5b07:
    and e
    dec h
    ld b, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld b, [hl]
    ld b, b
    ld d, c
    rst $28
    xor $4a
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, e
    ld a, [$eff7]
    xor $45
    ld a, $4f
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, b
    ld c, h
    ld c, e
    ld d, c
    ld c, a
    ld c, h
    ld c, c
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
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, d
    ld d, d
    ld d, b
    ld d, c
    rst $28
    xor $41
    ld b, [hl]
    ld d, b
    ld b, b
    ld b, [hl]
    ld c, l
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld a, [$eff7]
    xor $4c
    ld b, b
    ld b, b
    ld a, $50
    ld b, [hl]
    ld c, h
    ld c, e
    ld a, $49
    ld c, c
    ld d, [hl]
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    cpl
    ld b, d
    ld a, $53
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld a, $49
    ld c, h
    ld c, e
    ld b, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    jr nc, jr_01f_5be6

    ld h, d
    ld b, h
    ld c, a
    ld a, $4b
    ld b, c
    ld c, l
    ld a, $62
    ld b, [hl]
    ld d, b
    rst $28
    xor $4f
    ld b, d
    ld a, $49
    ld c, c
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
    ld e, a
    rst $30
    ldh a, [$5f]
    or $62
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
    jr nc, @+$58

    rst $28
    xor $25
    ld a, $3f
    ld d, [hl]
    ld e, [hl]
    ld h, d
    inc sp

jr_01f_5be6:
    ld a, $4f
    ld d, c
    ld h, d
    ld bc, $fa5f
    rst $30
    rst $28
    xor $a3
    jr nc, @+$58

    ld h, d
    ccf
    ld a, $3f
    ld d, [hl]
    ld h, d
    ld b, h
    ld b, [hl]
    ld c, a
    ld c, c
    rst $28
    xor $54
    ld a, $50
    ld h, d
    ccf
    ld c, h
    ld c, a
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $a3
    ld [hl], $45
    ld b, d
    ld l, b
    ld h, d
    ld d, b
    ld c, h
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, c
    ld d, c
    ld d, [hl]
    ld h, e
    rst $28
    xor $2f
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    ld c, l
    ld a, $4f
    ld b, d
    ld c, e
    ld d, c
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $37
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld b, b
    ld c, h
    ld c, e
    ld d, c
    ld b, [hl]
    ld c, e
    ld d, d
    ld b, d
    ld b, c
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
    jr nc, jr_01f_5cc3

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
    ld [bc], a
    ld e, a
    ld a, [$eff7]
    xor $a3
    jr nc, @+$58

    ld h, d
    ccf
    ld a, $3f
    ld d, [hl]
    ld h, d
    ld c, c
    ld b, d
    ld a, $4f
    ld c, e
    ld b, d
    ld b, c
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld a, $48
    ld e, a
    ld h, d
    ld [hl], $45
    ld b, d
    ld l, b
    ld a, [$eff7]
    xor $44
    ld c, a
    ld c, h
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, b
    ld c, h
    ld h, d
    ld b, e
    ld a, $50
    ld d, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc l
    ld h, d
    ld b, l
    ld c, h
    ld c, l
    ld b, d
    ld h, d
    ld d, b

jr_01f_5cc3:
    ld b, l
    ld b, d
    rst $28
    xor $41
    ld c, h
    ld b, d
    ld d, b
    ld c, e
    ld h, a
    ld h, d
    ld b, h
    ld c, a
    ld c, h
    ld d, h
    ld h, d
    ld d, d
    ld c, l
    ld a, [$eff7]
    xor $51
    ld c, h
    ld c, h
    ld h, d
    ld c, [hl]
    ld d, d
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld d, [hl]
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld c, h
    ld h, h
    ld h, d
    ld a, [hl-]
    ld b, l
    ld c, h
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, h
    ld h, d
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $44
    ld b, d
    ld d, c
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld e, a
    ld e, a
    ld e, a
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, d
    ld d, d
    ld d, b
    ld d, c
    ld l, h
    ld b, d
    rst $28
    xor $40
    ld c, a
    ld b, d
    ld c, l
    ld d, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld b, b
    ld a, $52
    ld d, b
    ld b, d
    ld h, d
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    ld d, b
    ld c, h
    rst $28
    xor $3f
    ld b, d
    ld a, $52
    ld d, c
    ld b, [hl]
    ld b, e
    ld d, d
    ld c, c
    ld h, e
    rst $38
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl+]
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld b, d
    ld d, l
    ld b, b
    ld d, d
    ld d, b
    ld b, d
    ld e, a
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
    ld a, $4f
    ld b, d
    ld h, d
    ld d, b
    ld c, h
    rst $28
    xor $43
    ld d, d
    ld c, e
    ld c, e
    ld d, [hl]
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $50
    ld c, e
    ld b, d
    ld a, $48
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld d, c
    ld b, d
    ld a, $49
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
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    dec h
    ld b, [hl]
    ld b, h
    scf
    ld c, a
    ld d, d
    ld c, e
    ld c, b
    ld h, d
    ld d, e
    ld d, b
    ld e, a
    rst $28
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld h, e
    ld a, [$eff7]
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
    ld c, a
    ld b, d
    ld c, l
    ld h, d
    ld c, h
    ld b, e
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
    ld c, h
    ld c, e
    ld h, d
    ccf
    ld d, [hl]
    ld a, [$eff7]
    xor $9f
    and e
    ld b, d
    ld c, e
    ld b, b
    ld b, l
    ld a, $4b
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, d
    ld d, b
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
    ld d, e
    ld a, $4f
    ld b, [hl]
    ld b, d
    ld d, c
    ld d, [hl]
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $44
    ld c, a
    ld a, $40
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    rst $28
    xor $51
    ld b, d
    ld b, b
    ld b, l
    ld c, e
    ld b, [hl]
    ld c, [hl]
    ld d, d
    ld b, d
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    cpl
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ld b, b
    ld c, h
    ld c, e
    ld d, c
    ld b, [hl]
    ld c, e
    ld d, d
    ld b, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    daa
    ld b, d
    ld a, $41
    scf
    ld c, a
    ld b, d
    ld b, d
    ld h, d
    ld d, e
    ld d, b
    ld e, a
    rst $28
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld h, e
    ld a, [$eff7]
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
    ld e, [hl]
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
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld a, $49
    ld h, d
    ld c, d
    ld a, $51
    ld b, b
    ld b, l
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
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld d, c
    ld d, h
    ld c, h
    rst $28
    xor $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld a, [$eff7]
    xor $54
    ld c, h
    ld c, e
    ld h, d
    ld a, $49
    ld c, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld b, [hl]
    ld c, a
    rst $28
    xor $4a
    ld a, $51
    ld b, b
    ld b, l
    ld b, d
    ld d, b
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
    xor $40
    ld b, l
    ld a, $4a
    ld c, l
    ld b, [hl]
    ld c, h
    ld c, e
    ld d, b
    ld b, l
    ld b, [hl]
    ld c, l
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    cpl
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, a
    ld c, h
    ld b, c
    ld d, d
    ld b, b
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld d, h
    ld c, h
    ld h, d
    ld d, b
    ld d, d
    ld c, a
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $4a
    ld a, $50
    ld d, c
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
    add hl, hl
    ld b, [hl]
    ld c, a
    ld d, b
    ld d, c
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, l
    ld c, h
    ld d, b
    ld d, c
    ld a, [$eff7]
    xor $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
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
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    add hl, hl
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $41
    ld c, a
    ld b, d
    ld d, b
    ld d, b
    ld b, d
    ld c, a
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld c, e
    ld b, h
    ld e, [hl]
    ld h, d
    ld c, e
    ld b, d
    ld d, h
    ld h, d
    ld a, $4b
    ld b, c
    rst $28
    xor $51
    ld a, $49
    ld b, d
    ld c, e
    ld d, c
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $9f
    and e
    jr nc, jr_01f_6027

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    jr nc, jr_01f_6021

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $f6
    ld h, e
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc h
    ld c, e
    ld b, c
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $43
    ld b, d
    ld a, $4f
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld a, $49
    ld c, b
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld d, h
    ld c, e
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28

jr_01f_6021:
    xor $9f
    and e
    scf
    ld b, l
    ld b, d

jr_01f_6027:
    ld h, d
    ld b, l
    ld a, $46
    ld c, a
    ld d, [hl]
    ld e, [hl]
    rst $28
    xor $51
    ld b, l
    ld c, a
    ld b, d
    ld b, d
    ld h, d
    ld b, d
    ld d, [hl]
    ld b, d
    ld b, c
    ld e, [hl]
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, d
    ld a, $51
    ld b, d
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
    scf
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld h, d
    ld c, h
    ld b, e
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
    xor $4f
    ld b, d
    ld c, d
    ld c, h
    ld d, e
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    ld c, d
    ld a, $50
    ld c, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl+]
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld a, $62
    ccf
    ld b, [hl]
    ld b, h
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
    ld b, d
    ld c, c
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld a, [$eff7]
    xor $51
    ld c, h
    ld e, a
    ld e, a
    ld e, a
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr nc, jr_01f_6104

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    ld h, e
    ld h, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    jr nc, jr_01f_6113

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    ld e, a
    ld e, a
    ld e, a
    inc l
    rst $28
    xor $26
    ld a, $4b
    ld h, a
    ld h, d
    ccf
    ld b, d
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, e
    ld b, d
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $54
    ld b, l
    ld d, [hl]
    ld h, d
    or $5e
    rst $28
    xor $54
    ld b, l
    ld d, [hl]
    ld h, h
    ld a, [$eff7]
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h

jr_01f_6104:
    ld d, d
    and e
    inc l
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld e, a
    ld h, d
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $54

jr_01f_6113:
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ccf
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld a, [$eff7]
    xor $47
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    ld e, a
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
    inc l
    ld h, d
    ld d, h
    ld a, $50
    rst $28
    xor $3f
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $2a
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
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    inc l
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld c, d
    ld a, $41
    ld b, d
    rst $28
    xor $51
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld a, $62
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ccf
    ld d, [hl]
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
    rst $28
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    cpl
    ld c, h
    ld b, h
    ld e, a
    ld a, [$eff7]
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
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
    xor $44
    ld c, h
    ld h, d
    ld b, l
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, d
    ld c, e
    ld d, c
    ld b, [hl]
    ld c, c
    ld h, d
    inc l
    ld a, [$eff7]
    xor $44
    ld c, h
    ld d, c
    ld h, d
    ld a, $62
    ld d, e
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld e, a
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
    inc l
    ld h, d
    ld b, l
    ld a, $41
    ld h, d
    ld c, e
    ld c, h
    rst $28
    xor $40
    ld b, l
    ld c, h
    ld b, [hl]
    ld b, b
    ld b, d
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $54
    ld c, h
    ld c, a
    ld c, b
    ld h, d
    ld b, l
    ld a, $4f
    ld b, c
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
    scf
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    inc l
    rst $28
    xor $45
    ld b, d
    ld a, $4f
    ld b, c
    ld h, d
    ld a, $62
    ld c, a
    ld d, d
    ld c, d
    ld c, h
    ld c, a
    ld a, [$eff7]
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld a, [hl+]
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
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    scf
    ld b, l
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    rst $28
    xor $54
    ld a, $50
    ld h, d
    ld a, $62
    ld c, l
    ld c, a
    ld c, h
    ld c, d
    ld b, [hl]
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
    ld b, d
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
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
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
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, e
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, h
    ld a, $50
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld e, [hl]
    ld h, d
    or $5f
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
    or $62
    inc l
    ld l, d
    rst $28
    xor $44
    ld c, c
    ld a, $41
    ld h, d
    ld d, c
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
    xor $3e
    ld b, h
    ld a, $46
    ld c, e
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
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld a, $43
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $3e
    ld c, c
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $4b
    ld c, h
    ld h, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld e, a
    ld a, [$eff7]
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    dec [hl]
    ld b, d
    ld a, $41
    ld d, [hl]
    ld h, h
    rst $28
    xor $f6
    ld e, a
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, a
    ld b, d
    ld d, d
    ld c, e
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, e
    rst $30
    ldh a, [$eb]
    jr nc, jr_01f_63b6

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    or $5e
    rst $28
    xor $24
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $40
    ld b, l
    ld a, $49
    ld c, c
    ld b, d
    ld c, e
    ld b, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, d
    ld b, d
    rst $28
    xor $3e
    ld b, h
    ld a, $46
    ld c, e
    ld h, h
    ld a, [$eff7]
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    scf
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $3f
    ld c, a
    ld c, h
    ld d, c
    ld b, l

jr_01f_63b6:
    ld b, d
    ld c, a
    ld e, [hl]
    ld h, d
    or $63
    ld a, [$eff7]
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld b, c
    ld c, h
    ld h, d
    ld b, l
    ld a, $51
    ld b, d
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    dec [hl]
    ld b, d
    ld a, $41
    ld d, [hl]
    ld h, h
    rst $28
    xor $f6
    ld e, a
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, a
    ld b, d
    ld d, d
    ld c, e
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, e
    rst $30
    ldh a, [$28]
    ld c, d
    ld c, l
    ld d, c
    ld d, [hl]
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    jr nc, jr_01f_6469

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    scf
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $3f
    ld c, h
    ld d, [hl]
    ld e, [hl]
    ld h, d
    scf
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, e
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $50
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld b, c
    ld c, h
    ld h, d
    ld b, l
    ld a, $51
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $49
    ld c, h
    ld d, b
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    scf

jr_01f_6469:
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $ef
    xor $49
    ld c, h
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld a, $49
    ld c, b
    ld h, d
    ld a, $3f
    ld c, h
    ld d, d
    ld d, c
    ld a, [$eff7]
    xor $3f
    ld d, d
    ld d, c
    ld e, [hl]
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld h, e
    rst $28
    xor $29
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, e
    rst $30
    ldh a, [$eb]
    jr nc, jr_01f_64e9

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    or $63
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
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld h, e
    rst $30
    ldh a, [$ea]
    ld a, [hl-]
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d
    and e
    jr nc, jr_01f_6510

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    ld h, e
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e

jr_01f_64e9:
    ld h, $4c
    ld c, e
    ld b, h
    ld c, a
    ld a, $51
    ld d, d
    ld c, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld d, b
    ld h, e
    rst $28
    xor $f6
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    add hl, hl
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld c, h
    ld c, e
    ld e, [hl]
    rst $28

jr_01f_6510:
    xor $56
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld a, $62
    ld d, b
    ld d, c
    ld a, $4f
    ld h, e
    rst $30
    ldh a, [$eb]
    jr nc, jr_01f_6564

    ld d, [hl]
    and e
    rst $28
    xor $26
    ld c, h
    ld c, e
    ld b, h
    ld c, a
    ld a, $51
    ld d, d
    ld c, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $37
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    or $63
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $30
    ld a, $56
    and e
    add hl, hl
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld c, h
    ld c, e
    ld e, [hl]
    rst $28
    xor $3c
    ld c, h
    ld d, d

jr_01f_6564:
    ld h, d
    ld a, $4f
    ld b, d
    ld a, [$eff7]
    xor $42
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld l, b
    ld h, d
    ld c, a
    ld c, h
    ld c, c
    ld b, d
    rst $28
    xor $4a
    ld c, h
    ld b, c
    ld b, d
    ld c, c
    ld h, e
    rst $30
    ldh a, [$ea]
    jr nc, jr_01f_65ce

    ld b, b
    ld c, b
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld h, d
    or $63
    rst $28
    xor $2c
    ld h, d
    ld b, b
    ld a, $4a
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld a, [$eff7]
    xor $4a
    ld d, [hl]
    ld h, d
    ld b, a
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld d, [hl]
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $30
    ld b, [hl]
    ld b, b
    ld c, b
    and e
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    ld h, h
    rst $28
    xor $31
    ld c, h
    ld h, d
    ld c, e
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d

jr_01f_65ce:
    ld a, $50
    ld c, b
    ld e, a
    ld a, [$eff7]
    xor $30
    ld b, [hl]
    ld b, b
    ld c, b
    and e
    inc l
    ld h, d
    ld b, b
    ld a, $4a
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld b, b
    ld c, h
    ld c, e
    ld b, h
    ld c, a
    ld a, $51
    ld d, d
    ld c, c
    ld a, $51
    ld b, d
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    jr nc, jr_01f_664c

    ld b, b
    ld c, b
    and e
    rst $28
    xor $26
    ld c, h
    ld c, e
    ld b, h
    ld c, a
    ld a, $51
    ld d, d
    ld c, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $33
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $56
    ld h, d
    ld a, $50
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $43
    ld c, a
    ld b, [hl]
    ld b, d
    ld c, e
    ld b, c
    ld h, e
    rst $30
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
    xor $3a
    ld b, d
    ld c, c
    ld c, c

jr_01f_664c:
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld h, e
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
    jr nc, jr_01f_66c2

    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    rst $28
    xor $43
    ld b, [hl]
    ld c, e
    ld a, $49
    ld c, c
    ld d, [hl]
    ld h, d
    ld c, a
    ld b, d
    ld a, $49
    ld b, [hl]
    ld d, a
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $46
    ld d, c
    ld d, b
    ld h, d
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    rst $28
    xor $41
    ld c, a
    ld b, d
    ld a, $4a
    ld h, e
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $51
    ld c, a
    ld d, d
    ld b, d
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]

jr_01f_66c2:
    xor $37
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
    xor $30
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    jr nc, jr_01f_671d

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld e, a
    ld e, a
    ld e, a
    ld a, [hl-]
    ld b, d
    ld c, c
    ld c, c
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
    ld a, $3f
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
    ld a, [$eff7]
    xor $56
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
    rst $28

jr_01f_671d:
    xor $25
    ld d, d
    ld d, c
    ld h, d
    ld d, d
    ld c, e
    ld b, e
    ld c, h
    ld c, a
    ld d, c
    ld d, d
    ld c, e
    ld a, $51
    ld b, d
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $50
    ld b, l
    ld b, d
    ld l, b
    ld h, d
    ccf
    ld b, d
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld c, e
    rst $28
    xor $3e
    ld d, h
    ld a, $56
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc a
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld h, d
    ccf
    ld b, d
    rst $28
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
    ld b, l
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $3e
    ld b, h
    ld a, $46
    ld c, e
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $4a
    ld a, $48
    ld b, d
    ld h, d
    ld a, $62
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, l
    ld e, a
    ld e, a
    ld e, a
    ld h, e
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld [hl-], a
    ld b, l
    ld h, e
    ld h, d
    inc l
    ld d, c
    rst $28
    xor $50
    ld d, c
    ld a, $4f
    ld d, c
    ld b, d
    ld b, c
    ld h, e
    ld h, d
    cpl
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld a, $51
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, b
    ld d, [hl]
    ld h, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    inc a
    ld c, h
    ld d, d
    ld c, a
    ld h, d
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
    ccf
    ld b, d
    ld h, d
    ld b, h
    ld c, a
    ld a, $4b
    ld d, c
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $3f
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, b
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
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld a, $ef
    xor $4d
    ld c, a
    ld c, h
    ld c, l
    ld c, h
    ld d, b
    ld a, $49
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld a, [$eff7]
    xor $f6
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
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    rst $28
    xor $45
    ld b, d
    ld c, a
    ld b, d
    ld h, h
    ld h, d
    daa
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld b, h
    ld c, h
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
    ld c, l
    ld b, d
    ld c, h
    ld c, l
    ld c, c
    ld b, d
    ld h, d
    ld c, h
    ld b, e
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
    ld a, $4b
    ld b, c
    ld h, d
    inc l
    ld a, [$eff7]
    xor $49
    ld c, h
    ld d, e
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
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
    jr z, jr_01f_68f8

    ld b, d
    ld c, a
    ld d, [hl]
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
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
    ld b, l
    ld a, $4d
    ld c, l
    ld d, [hl]
    ld a, [$eff7]
    xor $46
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $56
    ld b, d
    ld b, c
    ld h, e
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
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld b, c
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld c, e
    ld c, b
    ld h, h
    ld h, d
    ld [hl], $51
    ld a, $56
    ld a, [$eff7]
    xor $45
    ld b, d

jr_01f_68f8:
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld e, a
    rst $28
    xor $ff
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $54
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld e, a
    ld h, d
    inc l
    ld a, [$eff7]
    xor $52
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld d, b
    ld d, c
    ld a, $4b
    ld b, c
    ld e, a
    ld h, d
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld a, [$eff7]
    xor $43
    ld c, h
    ld c, a
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
    ld [hl], $4c
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    rst $28
    xor $3e
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld [hl-], a
    ld b, l
    ld h, e
    ld h, d
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $44
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld b, l
    ld a, $4a
    ccf
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $41
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
    ld h, d
    ld [hl], $45
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    ld h, h
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld [hl-], a
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, e
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, b
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld a, $49
    ld c, c
    ld c, h
    ld d, h
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $44
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
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
    inc h
    ld c, c
    ld d, b
    ld c, h
    ld e, [hl]
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, h
    ld a, $50
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $43
    ld b, [hl]
    ld c, a
    ld d, b
    ld d, c
    ld h, d
    ld a, $4d
    ld c, l
    ld b, d
    ld a, $4f
    ld b, d
    ld b, c
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
    ld h, d
    ld c, d
    ld a, $56
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
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
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    rst $30
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    ld [hl-], a
    ld b, l
    ld h, e
    ld h, e
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
    xor $50
    ld d, c
    ld a, $56
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld e, a
    ld e, a
    dec h
    ld d, d
    ld d, c
    ld h, d
    or $5e
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $42
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld c, d
    ld b, d
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
    inc l
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld e, a
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    rst $28
    xor $56
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
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld [hl-], a
    ld b, l
    ld h, e
    ld h, d
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $44
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld b, l
    ld a, $4a
    ccf
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $41
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
    ld h, d
    ld [hl], $45
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    ld h, h
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld [hl-], a
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $53
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld c, c
    ld c, c
    ld c, h
    ld d, h
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, h
    ld c, h
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc h
    ld c, c
    ld d, b
    ld c, h
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, h
    ld a, $50
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $43
    ld b, [hl]
    ld c, a
    ld d, b
    ld d, c
    ld h, d
    ld a, $4d
    ld c, l
    ld b, d
    ld a, $4f
    ld b, d
    ld b, c
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
    ld h, d
    ld c, d
    ld a, $56
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
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
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    rst $30
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    or $5e
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld b, l
    ld a, $4a
    ccf
    ld b, d
    ld c, a
    ld h, d
    ld b, c
    ld b, d
    ld b, d
    ld c, l
    ld a, [$eff7]
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $45
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, d
    ld h, d
    ld c, h
    ld b, e
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
    ld h, e
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld [hl-], a
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $53
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld c, c
    ld c, c
    ld c, h
    ld d, h
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, h
    ld c, h
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld c, d
    ld a, $56
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
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
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    or $63
    rst $28
    xor $2c
    ld h, d
    ld d, c
    ld b, l
    ld a, $4b
    ld c, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
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
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr nc, jr_01f_6d0c

    ld h, d
    ld b, l
    ld d, d
    ld d, b
    ccf
    ld a, $4b
    ld b, c
    ld e, [hl]
    rst $28
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
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
    ld a, [$eff7]
    xor $46
    ld d, b
    ld h, d
    ld b, h
    ld c, a
    ld b, d
    ld a, $51
    ld c, c
    ld d, [hl]
    rst $28
    xor $4d
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld b, c
    ld e, a
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
    xor $36
    ld d, c
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c

jr_01f_6d0c:
    ld e, a
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld c, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $40
    ld b, d
    ld c, c
    ld b, d
    ccf
    ld c, a
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $4c
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
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr z, jr_01f_6d96

    ld b, a
    ld c, h
    ld d, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d

Jump_01f_6d60:
    ld b, e
    ld d, d
    ld c, c
    ld c, c
    ld b, d
    ld d, b
    ld d, c
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld a, $62
    ld b, l
    ld a, $4d
    ld c, l
    ld d, [hl]
    rst $28
    xor $43
    ld a, $40
    ld b, d
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld b, l
    ld d, d
    ld d, b
    ccf
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $45
    ld a, $50
    ld h, e
    rst $28
    xor $f7

jr_01f_6d96:
    ldh a, [$eb]
    sbc a
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
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld c, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $40
    ld b, d
    ld c, c
    ld b, d
    ccf
    ld c, a
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $4c
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
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr z, jr_01f_6e40

    ld b, a
    ld c, h
    ld d, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld d, d
    ld c, c
    ld c, c
    ld b, d
    ld d, b
    ld d, c
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld a, $62
    ld b, l
    ld a, $4d
    ld c, l
    ld d, [hl]
    rst $28
    xor $43
    ld a, $40
    ld b, d
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld b, l
    ld d, d
    ld d, b
    ccf
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $45
    ld a, $50
    ld h, e
    rst $28
    xor $f7

jr_01f_6e40:
    ldh a, [$eb]
    sbc a
    and e
    ld h, $4c
    ld c, e
    ld b, h
    ld c, a
    ld a, $51
    ld d, d
    ld c, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld d, b
    ld h, e
    rst $28
    xor $37
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
    ld e, a
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
    ld d, b
    ld b, d
    ld b, d
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld d, h
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
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, e
    ld d, c
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ld d, e
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
    ld b, d
    ld c, a
    rst $28
    xor $41
    ld c, h
    ld d, h
    ld c, e
    ld e, a
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
    ld b, [hl]
    ld d, c
    ld h, e
    rst $28
    xor $f6
    ld h, e
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld c, b
    ld c, e
    ld b, d
    ld d, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld l, l
    rst $28
    xor $54
    ld b, [hl]
    ld c, e
    ld e, [hl]
    ld h, d
    or $63
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
    ld b, [hl]
    ld d, c
    ld h, e
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld h, e
    rst $28
    xor $26
    ld c, h
    ld c, e
    ld b, h
    ld c, a
    ld a, $51
    ld d, b
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld b, c
    ld b, d
    ld a, $4f
    rst $28
    xor $f6
    ld h, e
    ld a, [$eff7]
    xor $26
    ld c, h
    ld c, e
    ld b, h
    ld c, a
    ld a, $51
    ld d, d
    ld c, c
    ld a, $51
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
    ld sp, $544c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld l, h
    ld b, d
    rst $28
    xor $3f
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld a, $62
    ld d, c
    ld c, a
    ld d, d
    ld b, d
    ld a, [$eff7]
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld a, $62
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $4c
    ld c, e
    ld b, b
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld h, d
    ld a, $62
    ld d, e
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    rst $28
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
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
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
    rst $28
    xor $45
    ld b, d
    ld c, a
    ld b, d
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
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld [hl-], a
    ld b, l
    ld h, e
    ld h, d
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $50
    ld h, d
    ld b, [hl]
    ld b, e
    rst $28
    xor $54
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld b, l
    ld c, h
    ld c, e
    ld c, h
    ld c, a
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $3f
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld c, e
    ld b, d
    ld d, b
    ld d, b
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld sp, $544c
    ld e, [hl]
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ld d, c
    ld c, h
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
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld c, b
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld d, d
    ld d, c
    ld b, l
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    add hl, hl
    ld c, h
    ld c, c
    ld c, c
    ld c, h
    ld d, h
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $45
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, d
    ld e, a
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    ld sp, $544c
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld h, d
    ld d, d
    ld d, b
    ld h, d
    ld b, h
    ld c, h
    ld h, e
    rst $28
    xor $37
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $45
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, d
    ld h, d
    ld c, h
    ld b, e
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
    xor $f7
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
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, h
    ld c, h
    ld a, [$eff7]
    xor $41
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld b, l
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, d
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld a, $62
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $4c
    ld c, e
    ld b, b
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld h, d
    ld a, $62
    ld d, e
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    rst $28
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
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
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
    rst $28
    xor $45
    ld b, d
    ld c, a
    ld b, d
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
    ld a, [$eff7]
    xor $56
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
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, e
    ld c, h
    ld c, c
    ld c, c
    ld c, h
    ld d, h
    rst $28
    xor $4a
    ld b, d
    ld h, h
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld c, b
    ld a, $56
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, e
    ld b, [hl]
    ld d, b
    ld b, l
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, b
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld sp, $624c
    ld c, a
    ld d, d
    ld c, e
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld [hl], $4e
    ld d, d
    ld a, $54
    ld c, b
    ld h, e
    ld h, d
    ld [hl], $4e
    ld d, d
    ld a, $54
    ld c, b
    ld h, e
    rst $28
    xor $f7
    ldh a, [$f6]
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, a
    ld a, $4f
    ld e, a
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld b, a
    ld a, $4f
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, c
    ld c, c
    ld b, d
    ld b, c
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $3f
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld c, e
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, b
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld [hl], $4c
    ld c, d
    ld b, d
    ld b, c
    ld a, $56
    rst $28
    xor $2c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, e
    ld c, h
    ld c, c
    ld c, c
    ld c, h
    ld d, h
    ld a, [$eff7]
    xor $f6
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld b, h
    ld c, h
    ld b, c
    ld h, e
    rst $28
    xor $3a
    ld b, l
    ld a, $51
    ld h, d
    ld a, $4a
    ld h, d
    inc l
    ld e, a
    ld e, a
    ld e, a
    ccf
    ld c, c
    ld d, d
    ld d, b
    ld b, l
    ld e, a
    rst $30
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc l
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $41
    ld b, [hl]
    ld b, c
    ld c, e
    ld h, a
    ld h, d
    ld b, l
    ld b, d
    ld c, c
    ld c, l
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc l
    ld h, d
    ld d, h
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld c, e
    ld h, a
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld e, a
    ld a, [$eff7]
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    scf
    ld b, l
    ld a, $4b
    ld c, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $f6
    ld e, [hl]
    ld h, d
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $40
    ld c, h
    ld c, e
    ld b, h
    ld c, a
    ld a, $51
    ld d, d
    ld c, c
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld d, b
    rst $28
    xor $4c
    ld c, e
    ld h, d
    ld d, [hl]
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
    ld a, [$eff7]
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $4a
    ld d, [hl]
    ld h, d
    ld b, e
    ld c, a
    ld b, [hl]
    ld b, d
    ld c, e
    ld b, c
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld e, [hl]
    ld h, d
    inc l
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld d, b
    ld c, e
    ld h, a
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, a
    ld d, d
    ld d, b
    ld d, c
    rst $28
    xor $3e
    ld h, d
    ld b, c
    ld c, a
    ld b, d
    ld a, $4a
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $54
    ld c, h
    ld c, e
    ld h, h
    ld h, e
    ld h, d
    dec hl
    ld d, d
    ld b, e
    ld b, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, e
    ld h, d
    or $63
    ld h, e
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $41
    ld b, [hl]
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
    ld b, [hl]
    ld d, b
    ld h, d
    jr nc, jr_01f_73ef

    ld b, a
    ld b, d
    ld d, b
    ld d, c
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $53
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld b, l
    ld a, $4d
    ld c, l
    ld d, [hl]
    ld h, e
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld a, $4a
    ld h, d
    ld c, a
    ld b, d
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, e
    ld b, d
    ld b, c
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
    ld c, h
    ld c, e
    ld h, e
    ld h, e
    rst $28
    xor $3c
    ld b, d
    ld b, l
    ld h, d
    ld d, [hl]

jr_01f_73ef:
    ld b, d
    ld b, l
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    or $63
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    rst $28
    xor $44
    ld c, a
    ld b, d
    ld a, $51
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
    ld b, [hl]
    ld d, c
    ld h, e
    rst $28
    xor $3a
    ld a, $4b
    ld d, c
    ld h, d
    ld a, $62
    ld c, a
    ld b, d
    ld d, h
    ld a, $4f
    ld b, c
    ld h, h
    rst $38
    ldh a, [$eb]
    sbc a
    and e
    ld e, a
    ld e, a
    ld e, a
    ld h, d
    ld d, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    ld e, a
    rst $28
    xor $37
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    ld h, e
    rst $28
    xor $37
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl+]
    ld b, [hl]
    ld b, h
    ld b, h
    ld c, c
    ld b, d
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld b, c
    ld a, $4b
    ld b, b
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    rst $28
    xor $4a
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    inc l
    ld h, d
    ld b, e
    ld b, d
    ld b, d
    ld c, c
    ld a, [$eff7]
    xor $41
    ld b, [hl]
    ld d, a
    ld d, a
    ld d, [hl]
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld d, c
    ld l, b
    rst $28
    xor $52
    ld c, e
    ccf
    ld b, d
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, e
    ld a, $3f
    ld c, c
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $43
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld d, b
    ld d, c
    rst $28
    xor $3e
    ld h, d
    ld d, b
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld c, d
    ld a, $41
    ld b, d
    ld h, d
    ld a, $62
    ld d, b
    ld c, h
    ld c, e
    ld b, h
    rst $28
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $50
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ld c, h
    ld b, l
    ld h, d
    or $62
    ld a, $4b
    ld b, c
    rst $28
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    ld a, [$eff7]
    xor $5f
    ld e, a
    ld e, a
    ld h, d
    cpl
    ld a, $62
    ld c, c
    ld a, $ef
    xor $49
    ld a, $5f
    ld e, a
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld d, c
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
    ld d, c
    ld a, $4f
    ld d, b
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
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, h
    ld c, a
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld d, e
    ld b, [hl]
    ld d, b
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld b, e
    ld c, c
    ld a, $4f
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl], $4c
    ld c, h
    ld c, e
    ld e, a
    ld h, d
    inc l
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $40
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld d, b
    ld b, d
    ld b, b
    ld c, h
    ld c, e
    ld b, c
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld b, d
    ld d, b
    ld e, a
    ld h, d
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
    xor $4b
    ld b, d
    ld d, h
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
    or $5e
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    rst $28
    xor $46
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
    ld a, [$eff7]
    xor $4a
    ld b, d
    ld a, $4b
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
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $3f
    ld c, h
    ld c, a
    ld c, e
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
    xor $51
    ld c, a
    ld d, d
    ld b, d
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld a, $4b
    ld b, c
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
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
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    scf
    ld b, l
    ld a, $51
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4f
    ld b, d
    ld a, $50
    ld c, h
    ld c, e
    ld h, d
    ld d, h
    ld b, l
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld b, b
    ld b, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $41
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld d, d
    ld d, b
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, c
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
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    jr z, jr_01f_774a

    ld b, d
    ld c, e
    ld d, c
    ld d, d
    ld a, $49
    ld c, c
    ld d, [hl]
    rst $28
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld d, b
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ld c, h
    ld c, e
    ld a, [$eff7]
    xor $47
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld d, [hl]
    ld d, b
    ld h, d
    ld a, $4b
    ld b, c
    rst $28
    xor $40
    ld c, a
    ld b, d
    ld a, $51
    ld b, d
    ld h, d
    ld c, e
    ld b, d
    ld d, h
    ld a, [$eff7]
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld sp, $544c
    ld h, d
    or $62
    ld b, h
    ld c, h

jr_01f_774a:
    rst $28
    xor $4c
    ld c, e
    ld e, a
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, h
    ld c, h
    ld a, [$eff7]
    xor $3f
    ld a, $40
    ld c, b
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $51
    ld c, h
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
    rst $28
    xor $56
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
    xor $9f
    and e
    inc a
    ld b, d
    ld d, b
    ld e, [hl]
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
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld a, $50
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $37
    ld c, h
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld sp, $544c
    ld h, e
    ld h, d
    ld [hl], $51
    ld b, d
    ld c, l
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, e
    rst $30
    ldh a, [$eb]
    jr nc, @+$48

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    inc a
    ld a, $54
    ld c, e
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $2c
    ld h, d
    ld d, b
    ld c, c
    ld b, d
    ld c, l
    ld d, c
    ld h, d
    ld d, h
    ld b, d
    ld c, c
    ld c, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    scf
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld e, [hl]
    rst $28
    xor $2b
    ld c, h
    ld d, h
    ld h, d
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld b, d
    ld b, d
    ld c, e
    ld h, d
    ld d, d
    ld c, l
    ld h, h
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
    ld sp, $624c
    ld d, h
    ld a, $56
    ld e, [hl]
    rst $28
    xor $46
    ld d, c
    ld l, b
    ld h, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $4a
    ld b, [hl]
    ld b, c
    ld c, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
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
    inc l
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $50
    ld d, c
    ld a, $56
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld h, d
    ld c, c
    ld a, $51
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
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $40
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld b, b
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $3e
    ld d, h
    ld a, $56
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
    ld a, [hl+]
    ld c, h
    ld h, d
    ld c, h
    ld c, e
    ld e, a
    ld h, d
    ld a, [hl+]
    ld c, h
    rst $28
    xor $3f
    ld a, $40
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld e, a
    ld a, [$eff7]
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a
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
    inc l
    ld d, c
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld d, b
    ld c, h
    rst $28
    xor $40
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    ld h, e
    ld h, d
    inc l
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld a, [$eff7]
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld d, h
    ld c, h
    ld c, e
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
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, h
    rst $28
    xor $32
    ld b, l
    ld e, [hl]
    ld h, d
    ld b, a
    ld d, d
    ld d, b
    ld d, c
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
    scf
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
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
    ld a, [hl-]
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld b, c
    ld c, a
    ld b, d
    ld a, $4a
    ld h, e
    ld a, [$eff7]
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, h
    rst $28
    xor $37
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $41
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $50
    ld a, $4a
    ld b, d
    ld h, d
    ld b, c
    ld c, a
    ld b, d
    ld a, $4a
    ld h, h
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
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld a, $56
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $54
    ld a, $50
    ld c, e
    ld h, a
    ld h, d
    ld a, $62
    ld b, c
    ld c, a
    ld b, d
    ld a, $4a
    ld h, h
    ld a, [$eff7]
    xor $2c
    ld d, c
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld d, c
    ld c, a
    ld d, d
    ld b, d
    ld h, h
    rst $28
    xor $ff
    ldh a, [$4c]
    ld c, l
    ld a, b
    ld a, b
    ld a, e

jr_01f_7a02:
    ld a, e
    ld a, b
    ld a, b
    ld a, e

jr_01f_7a06:
    ld a, e
    ld a, b
    ld a, b
    inc b
    ld a, e
    add c
    dec d
    inc bc
    ld a, b
    add d
    ld a, e
    ld a, e
    inc bc
    ld a, b
    add c
    dec c
    ld a, a
    ld a, b
    add d
    ld a, b
    dec c
    inc bc
    ld a, b
    adc [hl]
    ld a, e
    ld a, b
    ld a, b
    ld a, e
    ld a, b
    ld a, b
    ld c, a
    ld c, a
    ld a, b
    ld a, b
    ld a, e
    ld c, l
    ld c, h
    ld c, h
    inc b
    ld c, l
    add [hl]
    nop
    ld [bc], a
    inc b
    ld a, b
    ld c, a
    ld c, a
    inc bc
    ld a, b
    add c
    dec d
    ld a, a
    ld a, b
    sub b
    ld a, b
    dec c
    ld a, b
    ld a, h
    ld a, b
    ld a, e
    ld c, h
    ld c, h
    ld c, l
    ld c, h
    ld c, h
    ld c, l
    ld c, l
    ld c, h
    ld c, h
    ld c, l
    dec bc
    ld a, b
    add [hl]
    ld a, e
    ld a, e
    ld a, b
    ld [bc], a
    inc b
    nop
    ld a, a
    ld a, b
    adc c
    ld a, b
    dec d
    ld a, b
    db $fd
    ld a, b
    ld c, l
    ld a, b
    jr nc, jr_01f_7a91

    dec bc
    ld a, b
    add c
    jr z, jr_01f_7a6c

    ld a, b
    add d
    ld c, a
    ld c, a
    inc bc
    ld a, b

jr_01f_7a6c:
    add c
    dec b
    ld a, a
    ld a, b
    add [hl]
    ld a, b
    nop
    ld [bc], a
    inc bc
    inc b
    nop
    dec c
    ccf
    add e
    nop
    ld [bc], a
    nop
    dec b
    jr nz, jr_01f_7a02

    ld a, e
    ld a, e
    inc bc
    jr nz, jr_01f_7a06

    dec d
    ld a, a
    ld a, b
    add d
    ld a, b
    dec b
    inc bc
    ld a, b
    add c
    dec b
    dec c
    ld a, c

jr_01f_7a91:
    add h
    dec b
    ld a, b
    nop
    ld [bc], a
    ld [$8203], sp
    inc b
    nop
    ld a, a
    ld a, b
    add d
    ld a, b
    dec c
    inc bc
    ld a, b
    add c
    dec d
    dec c
    ld a, c
    add c
    dec d
    inc c
    ld a, b
    add c
    dec b
    ld a, a
    ld a, b
    add d
    ld a, b
    dec d
    inc bc
    ld a, b
    add d
    nop
    ld [bc], a
    dec bc
    inc bc
    add d
    inc b
    nop
    inc c
    ld a, b
    add c
    dec d
    ld a, a
    ld a, b
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
