; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $021", ROMX[$4000], BANK[$21]

    db $21 ; Bank number

    ; Cross-bank dispatch table (120 entries)
    ; Called via: ld hl, $21XX / rst $10
    dw SetAnim21_40f1                  ; Entry 0
    dw $40F8                          ; Entry 1
    dw $40FF                          ; Entry 2
    dw $4009                          ; Entry 3 — mode 0 -> table $4009 (mode list $4007)
    dw $4106                          ; Entry 4 — [table $4009]; text $0400 "*:I heard a rumor that a terrible…"
    dw $420F                          ; Entry 5 — text $0401 "*:I think I'm gonna quit staying …"
    dw $4248                          ; Entry 6 — text $0402 "*:You defeated me. I didn't even …"
    dw $42E8                          ; Entry 7 — text $0403 "*:I'll send my StoneMan to the fa…"
    dw $4349                          ; Entry 8 — text $0404 "*:Well, I thought to... but... yo…"
    dw $43D8                          ; Entry 9 — text $0405 "*:...fine. If you change your min…"
    dw $4411                          ; Entry 10 — text $0406 "*:My StoneMan can use Ahhh! *:Boy…"
    dw $44A2                          ; Entry 11 — text $0407 "*:It's a LifeAcorn. Use it wisely."
    dw $44CC                          ; Entry 12 — text $0408 "*:You're at the Room of the Labyr…"
    dw $4553                          ; Entry 13 — text $0409 "*:Winning is not about luck but a…"
    dw $462C                          ; Entry 14 — text $040A "*:Perfect your ability and luck w…"
    dw $46FF                          ; Entry 15 — text $040B "*:Congratulations on your partici…"
    dw $47D9                          ; Entry 16 — text $040C "*:Oh my! Monster Master [HERO]! I…"
    dw $480E                          ; Entry 17 — text $040D "*:Even I can be of help? I'm touc…"
    dw $483B                          ; Entry 18 — text $040E "*:Breeding two child-like devils …"
    dw $489E                          ; Entry 19 — text $040F "*:We clowns hustle on the Starry …"
    dw $48FE                          ; Entry 20 — text $0410 "King:[HERO]! At last you're in th…"
    dw $49C1                          ; Entry 21 — text $0411 "King of GreatLog: How are you, Ki…"
    dw $4A4F                          ; Entry 22 — text $0412 "King:Don't be silly! You're sarca…"
    dw $4AB3                          ; Entry 23 — text $0413 "King of GreatLog: Oh! I didn't no…"
    dw $4C01                          ; Entry 24 — text $0414 "King of GreatLog: Ha ha ha ha ha!…"
    dw $4C7C                          ; Entry 25 — text $0415 "King:Huff! Whatever! He doesn't k…"
    dw $4E38                          ; Entry 26 — text $0416 "*:Oh Monster Master [HERO]! Great…"
    dw $4E88                          ; Entry 27 — text $0417 "*:I assume GreatTree is encouragi…"
    dw $4F4F                          ; Entry 28 — text $0418 "*:The King fears for your future,…"
    dw $4FF7                          ; Entry 29 — text $0419 "*:Do you want me to tell you the …"
    dw $5046                          ; Entry 30 — text $041A "*:Be careful behind the Gate of R…"
    dw $507A                          ; Entry 31 — text $041B "*:Far beyond the Gate, lives your…"
    dw $5154                          ; Entry 32 — text $041C "*:So you became the master of Gre…"
    dw $51C0                          ; Entry 33 — text $041D "*:The Starry Night is coming. The…"
    dw $5205                          ; Entry 34 — text $041E "*:Hey, I heard you became the rep…"
    dw $529E                          ; Entry 35 — text $041F "*:Just competing in the Starry Ni…"
    dw $5307                          ; Entry 36 — text $0420 "*:Many people are heading to Grea…"
    dw $5379                          ; Entry 37 — text $0421 "*:You'll win! I can feel it! *:I …"
    dw $5407                          ; Entry 38 — text $0422 "*:Go right to the Bazaar! More st…"
    dw $5441                          ; Entry 39 — text $0423 "*:Rep? A kid like you? Liar! *:He…"
    dw $5495                          ; Entry 40 — text $0424 "*:Master [HERO]! Welcome to the B…"
    dw $54C0                          ; Entry 41 — text $0425 "*:The Starry Night is almost here…"
    dw $5554                          ; Entry 42 — text $0426 "*:For victory! I will sing for yo…"
    dw $55B9                          ; Entry 43 — text $0427 "*:Everybody is partying because i…"
    dw $5622                          ; Entry 44 — text $0428 "*:Eek eek eek! *:Mister! I wanna …"
    dw $565C                          ; Entry 45 — text $0429 "*:Festivals are fun! *:Want to le…"
    dw $56D6                          ; Entry 46 — text $042A "*:Oh, of course. You're the rep!"
    dw $56F9                          ; Entry 47 — text $042B "*:Hi little master! *:What a gloo…"
    dw $5753                          ; Entry 48 — text $042C "*:Okay. Good luck!"
    dw $5769                          ; Entry 49 — text $042D "*:...tickle,tickle ... tickle,tic…"
    dw $57DD                          ; Entry 50 — text $042E "*:Oh joy! Starry Night! *:It seem…"
    dw $5873                          ; Entry 51 — text $042F "*:I've been alone for a long time…"
    dw $5931                          ; Entry 52 — text $0430 "*:Congratulations on becoming the…"
    dw $59A6                          ; Entry 53 — text $0431 "*:You said no... That's the rep o…"
    dw $59DB                          ; Entry 54 — text $0432 "*:Lemme tell you a scary story. T…"
    dw $5A81                          ; Entry 55 — text $0433 "*:Ohh!! You'll really go to see y…"
    dw $5B31                          ; Entry 56 — text $0434 "*:I'm betting on which kingdom wi…"
    dw $5B77                          ; Entry 57 — text $0435 "*:Whaat? 100 thousand in gold for…"
    dw $5C3A                          ; Entry 58 — text $0436 "*:My god, up close, I see you're …"
    dw $5C97                          ; Entry 59 — text $0437 "*:I bet on [HERO]! Do your best!!"
    dw $5CBC                          ; Entry 60 — text $0438 "*:GWWRRR! It's GreatLog! Of cours…"
    dw $5CFD                          ; Entry 61 — text $0439 "*:Good work on surviving S class.…"
    dw $5DF4                          ; Entry 62 — text $043A "*:It's unfortunate but you have w…"
    dw $5E89                          ; Entry 63 — text $043B "*:Go left to the Room of Villager…"
    dw $5F0F                          ; Entry 64 — text $043C "*:At last you became the Master o…"
    dw $5FDC                          ; Entry 65 — text $043D "*:Oh, the rep of GreatTree, Maste…"
    dw $60A1                          ; Entry 66 — text $043E "*:They say people see the future …"
    dw $612D                          ; Entry 67 — text $043F "Slio:Will you do me a favor? Slio…"
    dw $61A1                          ; Entry 68 — text $0440 "Slio:I guess I'm useless to you n…"
    dw $6203                          ; Entry 69 — text $0441 "Slio:[HERO], you have too many mo…"
    dw $6274                          ; Entry 70 — text $0442 "Slio:Thank you [HERO]! I'll wait …"
    dw $62AC                          ; Entry 71 — text $0443 "Slio:[HERO]! You're going to take…"
    dw $62DD                          ; Entry 72 — text $0444 "*:How are you? I'm Slim! I'm the …"
    dw $6343                          ; Entry 73 — text $0445 "*:As might be expected [HERO]! Yo…"
    dw $6379                          ; Entry 74 — text $0446 "*:You can drop off up to 19 monst…"
    dw $64C7                          ; Entry 75 — text $0447 "*:Do you want to know about the f…"
    dw $64F5                          ; Entry 76 — text $0448 "*:I heard the monster called Durr…"
    dw $652F                          ; Entry 77 — text $0449 "*:Copycopy. I wanna copycopy Balz…"
    dw $658C                          ; Entry 78 — text $044A "*:Hello! I'm Helo *:My former mas…"
    dw $66A6                          ; Entry 79 — text $044B "*:H..H..Hello! M..my name is T..T…"
    dw $6713                          ; Entry 80 — text $044C "*:Do ya know GigaSlash? It's grea…"
    dw $6744                          ; Entry 81 — text $044D "*:The arena is currently being pr…"
    dw $67B0                          ; Entry 82 — text $044E "*:I heard his Majesty commanded y…"
    dw $688B                          ; Entry 83 — text $044F "*:They say you see the future beh…"
    dw $690E                          ; Entry 84 — text $0450 "*:Hi [HERO], Congratulations. *:I…"
    dw $6988                          ; Entry 85 — text $0451 "*:Starry Night Tournament... What…"
    dw $69E3                          ; Entry 86 — text $0452 "*:You, obey my command. *:I want …"
    dw $6A46                          ; Entry 87 — text $0453 "*:Gigantes goes on gigantic prote…"
    dw $6A6F                          ; Entry 88 — text $0454 "*:The guy at the entrance to the …"
    dw $6AEB                          ; Entry 89 — text $0455 "*:My rival must be watching me...…"
    dw $6B91                          ; Entry 90 — text $0456 "*:I've been training a BombCrag t…"
    dw $6C55                          ; Entry 91 — text $0457 "*:Scurry away Scurry away! *:It's…"
    dw $6C97                          ; Entry 92 — text $0458 "*:Hee hee! Yo dude. Wanna know wh…"
    dw $6CED                          ; Entry 93 — text $0459 "*:Hee hee! I dunno either."
    dw $6D0B                          ; Entry 94 — text $045A "*:I'm your mother. C'mon Bebe, re…"
    dw $6D41                          ; Entry 95 — text $045B "*:Why do you have to be MY mother…"
    dw $6D68                          ; Entry 96 — text $045C "*:We all gather here seeking vict…"
    dw $6E5F                          ; Entry 97 — text $045D "*:What should I do? That looks ni…"
    dw $6EA2                          ; Entry 98 — text $045E "*:Ha ha ha! I made Gigantes an un…"
    dw $6EDB                          ; Entry 99 — text $045F "[HERO] looked in front. The fire …"
    dw $6F2F                          ; Entry 100 — text $0460 "*:Oh! It's a WildApe! The monkey …"
    dw $6FAC                          ; Entry 101 — text $0461 "*:I heard a rumor about an awful …"
    dw $704B                          ; Entry 102 — text $0462 "*:I think I'll go to bed. But yet…"
    dw $7084                          ; Entry 103 — text $0463 "*:[HERO]. Let me tell you. *:When…"
    dw $717C                          ; Entry 104 — text $0464 "*:This is a ATKseed. Use it wisel…"
    dw $71A8                          ; Entry 105 — text $0465 "*:Obey my command. *:Bring me Hor…"
    dw $721E                          ; Entry 106 — text $0466 "*:You're amazing! I didn't know y…"
    dw $7305                          ; Entry 107 — text $0467 "*:You came back again. I wonder i…"
    dw $7346                          ; Entry 108 — text $0468 "*:For your victory, let me tell y…"
    dw $744D                          ; Entry 109 — text $0469 "*:I can't say it loud but... *:Wh…"
    dw $7520                          ; Entry 110 — text $046A "*:You're at the Room of Reflectio…"
    dw $75B6                          ; Entry 111 — text $046B "*:Actually, nobody has survived t…"
    dw $76D3                          ; Entry 112 — text $046C "*:I...I agree with you. I'm sorry…"
    dw $7709                          ; Entry 113 — text $046D "*:How do you do? I am the guardia…"
    dw $7849                          ; Entry 114 — text $046E "Durran:Here, fight to your heart'…"
    dw $787C                          ; Entry 115 — text $046F "Durran:Hmm. You came back again. …"
    dw $78E1                          ; Entry 116 — text $0470 "Durran:Here, fight to your heart'…"
    dw $7914                          ; Entry 117 — text $0471 "Durran:Ha ha ha! You defeated the…"
    dw $7A4E                          ; Entry 118 — text $0472 "Durran:Let me introduce him to yo…"
    dw $7B4D                          ; Entry 119 — text $0473 "Durran:Ha ha ha! You came again!!…"

SetAnim21_40f1:
    ld de, $4007
    call CallTextEngine
    ret


    ld de, $4007
    call RunTextHandler
    ret


    call SetAnim21_40f1
    call RequestScreenUpdate
    ret


    ld [$a39f], a
    inc l
    ld h, d
    ld b, l
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
    rst $28
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld a, $62
    ld d, c
    ld b, d
    ld c, a
    ld c, a
    ld b, [hl]
    ccf
    ld c, c
    ld b, d
    ld a, [$eff7]
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld a, $4d
    ld c, l
    ld b, d
    ld a, $4f
    ld b, d
    ld b, c
    rst $28
    xor $43
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld b, e

jr_021_4154:
    ld c, h
    ld c, a
    ld b, d
    ld b, [hl]
    ld b, h
    ld c, e
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
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $40
    ld c, h
    ld c, d
    ld c, d
    ld a, $4b
    ld b, c
    ld d, b
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
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld c, e
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    rst $28
    xor $3f
    ld b, d
    ld b, d
    ld c, e
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld c, e
    ld h, d
    ccf
    ld b, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    ld e, [hl]
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ccf
    ld b, d
    ld a, $51
    ld d, b
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, d
    ld b, [hl]
    ld b, d
    ld d, b
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
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
    rst $28
    xor $50
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    ld h, d
    ld a, $4b
    ld b, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld b, d
    ld a, $51
    ld d, b
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, d
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
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld c, b
    ld h, d
    inc l
    ld l, d
    rst $28
    xor $44
    ld c, h
    ld c, e
    ld c, e
    ld a, $62
    ld c, [hl]
    ld d, d
    ld b, [hl]
    ld d, c
    ld a, [$eff7]
    xor $50
    ld d, c
    ld a, $56
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld a, $49
    ld c, c
    rst $28
    xor $4b
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    dec a
    ld d, a
    ld d, a
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
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    ld b, d
    ld b, c
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    rst $28
    xor $2c
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    ld c, e
    ld h, a
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, e
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld b, b
    ld b, l
    ld a, $4b
    ld b, b
    ld b, d
    ld h, e
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $4d
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, h
    ld c, a
    ld b, d
    ld a, $51
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    cpl
    ld b, d
    ld c, d
    ld c, d
    ld b, d
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
    xor $4a
    ld d, [hl]
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
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld b, b
    ld a, $49
    ld c, c
    ld b, d
    ld b, c
    ld h, d
    ld a, $ef
    xor $36
    ld d, c
    ld c, h
    ld c, e
    ld b, d
    jr nc, @+$40

    ld c, e
    ld e, a
    ld h, d
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld b, b
    ld b, b
    ld b, d
    ld c, l
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld e, a
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
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
    ld c, d
    ld d, [hl]
    rst $28
    xor $36
    ld d, c
    ld c, h
    ld c, e
    ld b, d
    jr nc, @+$40

    ld c, e
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $43
    ld a, $4f
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, e
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
    ld d, c
    ld a, $48
    ld b, d
    rst $28
    xor $44
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld b, b
    ld a, $4f
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, d
    ld d, [hl]
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld b, d
    ld c, c
    ld c, c
    ld e, [hl]
    ld h, d
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
    xor $51
    ld c, h
    ld e, a
    ld e, a
    ld e, a
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    rst $28
    xor $4a
    ld a, $4b
    ld d, [hl]
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
    ld a, [$eff7]
    xor $9f
    and e
    ld h, $3e
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, e
    ld b, [hl]
    ld d, b
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    rst $28
    xor $3e
    ld b, h
    ld a, $46
    ld c, e
    ld h, d
    ld a, $43
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $44
    ld b, d
    ld d, c
    ld h, d
    ld c, a
    ld b, [hl]
    ld b, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, b
    ld c, h
    ld c, d
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
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, h
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld e, a
    ld e, a
    ld e, a
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, d
    ld e, a
    rst $28
    xor $2c
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $4a
    ld b, [hl]
    ld c, e
    ld b, c
    ld e, [hl]
    ld h, d
    ld c, c
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
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    jr nc, jr_021_446c

    ld h, d
    ld [hl], $51
    ld c, h
    ld c, e
    ld b, d
    jr nc, jr_021_445c

    ld c, e
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $52
    ld d, b
    ld b, d
    ld h, d
    inc h
    ld b, l
    ld b, l
    ld b, l
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld c, h
    ld d, [hl]
    ld h, d
    ld c, d
    ld c, h
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
    xor $52
    ld d, b
    ld b, d
    ld h, d
    inc h
    ld b, l
    ld b, l
    ld b, l
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld e, a
    ld a, [$eff7]
    xor $36
    ld d, c
    ld c, a
    ld a, $4b

jr_021_445c:
    ld b, h
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
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

jr_021_446c:
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld d, [hl]
    ld l, c
    ld b, d
    ld h, d
    ld a, $49
    ld c, c
    rst $28
    xor $45
    ld a, $4f
    ld b, c
    ld b, b
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld [hl], $fa
    rst $30
    rst $28
    xor $40
    ld c, c
    ld a, $50
    ld d, b
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
    rst $28
    xor $f6
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $ef
    xor $2f
    ld b, [hl]
    ld b, e
    ld b, d
    inc h
    ld b, b
    ld c, h
    ld c, a
    ld c, e
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
    dec [hl]
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $2f
    ld a, $3f
    ld d, [hl]
    ld c, a
    ld b, [hl]
    ld c, e
    ld d, c
    ld b, l
    ld h, d
    or [hl]
    rst $28
    xor $2d
    ld d, d
    ld b, c
    ld b, h
    ld c, d
    ld b, d
    ld c, e
    ld d, c
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
    xor $2a
    ld a, $51
    ld b, d
    ld h, d
    ld c, h
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
    ld e, a
    ld a, [$eff7]
    xor $2f
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
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    cpl
    ld a, $3f
    ld d, [hl]
    ld c, a
    ld b, [hl]
    ld c, e
    ld d, c
    ld b, l
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, [hl]
    ld c, e
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld c, c
    ld d, d
    ld b, b
    ld c, b
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld a, [$eff7]
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld l, b
    rst $28
    xor $3e
    ccf
    ld b, [hl]
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, [hl]
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    jr z, jr_021_45e7

    ld b, d
    ld c, e
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld c, h
    rst $28
    xor $45
    ld a, $4d
    ld c, l
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $42
    ld c, e
    ld b, b
    ld c, h
    ld d, d
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    jr nc, jr_021_45fd

    ld d, c
    ld a, $49
    ld d, [hl]
    ld d, b
    rst $28
    xor $4e
    ld d, d
    ld b, [hl]
    ld d, c
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld d, c
    ld b, d
    ld c, e
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28

jr_021_45e7:
    xor $51
    ld c, h
    ld h, d
    ld b, c
    ld c, h
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld c, e
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h

jr_021_45fd:
    ld e, a
    ld h, d
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
    xor $2c
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
    ld a, $fa
    rst $30
    rst $28
    xor $3f
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, d
    ld c, e
    ld d, e
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc sp
    ld b, d
    ld c, a
    ld b, e
    ld b, d
    ld b, b
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $3e
    ccf
    ld b, [hl]
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, [hl]
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld c, c
    ld d, d
    ld b, b
    ld c, b
    ld a, [$eff7]
    xor $54
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
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr z, jr_021_46ba

    ld b, d
    ld c, e
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld c, h
    rst $28
    xor $45
    ld a, $4d
    ld c, l
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $42
    ld c, e
    ld b, b
    ld c, h
    ld d, d
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    jr nc, jr_021_46d0

    ld d, c
    ld a, $49
    ld d, [hl]
    ld d, b
    rst $28
    xor $4e
    ld d, d
    ld b, [hl]
    ld d, c
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld d, c
    ld b, d
    ld c, e
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28

jr_021_46ba:
    xor $51
    ld c, h
    ld h, d
    ld b, c
    ld c, h
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld c, e
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h

jr_021_46d0:
    ld e, a
    ld [hl-], a
    ld b, e
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld e, [hl]
    rst $28
    xor $2c
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
    ld a, $fa
    rst $30
    rst $28
    xor $3f
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, d
    ld c, e
    ld d, e
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
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
    rst $28
    xor $4c
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
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
    ld c, h
    ld c, e
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
    dec hl
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $62
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    rst $28
    xor $46
    ld c, e
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld c, a
    ld l, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld b, e
    ld c, h
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    rst $28
    xor $51
    ld d, h
    ld c, h
    ld h, d
    ld b, b
    ld b, l
    ld b, [hl]
    ld c, c
    ld b, c
    sbc h
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld a, [$eff7]
    xor $41
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld d, b
    ld e, [hl]
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
    ld a, [$eff7]
    xor $46
    ld d, b
    ld h, d
    ccf
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
    daa
    ld b, [hl]
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, b
    ld b, d
    ld b, b
    ld c, a
    ld b, d
    ld d, c
    ld h, h
    rst $38
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, e
    ld h, d
    jr nc, jr_021_4831

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
    or $63
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld a, $4a
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, e
    ld b, [hl]
    ld d, c
    ld b, d
    ld b, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    jr z, jr_021_4866

    ld b, d
    ld c, e
    ld h, d
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld b, l
    ld b, d
    ld c, c
    ld c, l
    ld h, h
    ld h, d
    inc l
    ld l, d
    ld a, [$eff7]
    xor $51
    ld c, h

jr_021_4831:
    ld d, d
    ld b, b
    ld b, l
    ld b, d
    ld b, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
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
    ld d, h
    ld c, h
    rst $28
    xor $40
    ld b, l
    ld b, [hl]
    ld c, c
    ld b, c
    sbc h
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld b, c
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld d, b
    ld a, [$eff7]
    xor $40
    ld c, a
    ld b, d
    ld a, $51

jr_021_4866:
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
    ld h, e
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
    ld b, l
    ld b, d
    ld c, c
    ld c, l
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld b, d
    ld h, d
    ld b, b
    ld c, c
    ld c, h
    ld d, h
    ld c, e
    ld d, b
    ld h, d
    ld b, l
    ld d, d
    ld d, b
    ld d, c
    ld c, c
    ld b, d
    rst $28
    xor $4c
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
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld b, d
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, [hl]
    ld h, d
    ld b, c
    ld a, $4b
    ld b, b
    ld b, d
    rst $28
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld b, d
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld d, c
    ld a, $46
    ld c, e
    ld a, [$eff7]
    xor $4d
    ld b, d
    ld c, h
    ld c, l
    ld c, c
    ld b, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    or $63
    ld h, d
    inc h
    ld d, c
    rst $28
    xor $49
    ld a, $50
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
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
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc l
    ld l, h
    ld b, d
    ld h, d
    ld d, h
    ld a, $46
    ld d, c
    ld b, d
    ld b, c
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, c
    ld a, $56
    ld h, e
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
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
    xor $56
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
    ld a, $49
    ld c, c
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
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
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    ld l, $46
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
    cpl
    ld c, h
    ld b, h
    and e
    rst $28
    xor $2b
    ld c, h
    ld d, h
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, [hl]
    ld a, [$eff7]
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
    ld h, h
    rst $28
    xor $fa
    rst $30
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
    cpl
    ld c, h
    ld b, h
    and e
    rst $28
    xor $2c
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld a, [$eff7]
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    ld h, d
    ld d, h
    ld a, $50
    rst $28
    xor $3e
    ccf
    ld c, c
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld d, d
    ld c, a
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    ld a, [$eff7]
    xor $36
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld h, h
    rst $28
    xor $f7
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    daa
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $50
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, [hl]
    ld h, e
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld a, [$eff7]
    xor $50
    ld a, $4f
    ld b, b
    ld a, $50
    ld d, c
    ld b, [hl]
    ld b, b
    ld h, d
    ld a, $50
    rst $28
    xor $3e
    ld c, c
    ld d, h
    ld a, $56
    ld d, b
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
    rst $28
    xor $50
    ld d, c
    ld a, $4b
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, e
    ld b, d
    ld d, l
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $4c
    ld d, d
    ld c, a
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    ld l, $46
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
    cpl
    ld c, h
    ld b, h
    and e
    rst $28
    xor $32
    ld b, l
    ld h, e
    ld h, d
    inc l
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    ld c, e
    ld h, a
    ld a, [$eff7]
    xor $4b
    ld c, h
    ld d, c
    ld b, [hl]
    ld b, b
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
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    cpl
    ld c, h
    ld b, h
    and e
    rst $28
    xor $2c
    ld h, d
    ld d, c
    ld b, l
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld a, $50
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, a
    ld a, $4b
    ld b, [hl]
    ld d, c
    ld c, h
    ld c, a
    ld e, a
    rst $28
    xor $fa
    rst $30
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
    cpl
    ld c, h
    ld b, h
    and e
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld a, $49
    ld c, a
    ld b, d
    ld a, $41
    ld d, [hl]
    ld a, [$eff7]
    xor $45
    ld b, d
    ld a, $4f
    ld b, c
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
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $4a
    ld d, [hl]
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
    cpl
    ld c, h
    ld b, h
    and e
    rst $28
    xor $35
    ld d, d
    ld c, d
    ld c, h
    ld c, a
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld a, [$eff7]
    xor $4c
    ld d, d
    ld c, a
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld h, d
    ld b, [hl]
    ld d, b
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
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    ld a, [$eff7]
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
    cpl
    ld c, h
    ld b, h
    and e
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld h, d
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $2a
    ld b, d
    ld d, c
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, [hl]
    ld b, c
    ld b, d
    ld a, $5f
    rst $30
    ldh a, [$ea]
    ld l, $46
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
    cpl
    ld c, h
    ld b, h
    and e
    rst $28
    xor $2b
    ld a, $62
    ld b, l
    ld a, $62
    ld b, l
    ld a, $62
    ld b, l
    ld a, $62
    ld b, l
    ld a, $63
    ld a, [$eff7]
    xor $2c
    ld l, d
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
    ld d, h
    ld a, $4f
    ld b, c
    ld h, d
    ld d, c
    ld c, h
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
    xor $fa
    rst $30
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
    cpl
    ld c, h
    ld b, h
    and e
    rst $28
    xor $2b
    ld a, $62
    ld b, l
    ld a, $62
    ld b, l
    ld a, $62
    ld b, l
    ld a, $62
    ld b, l
    ld a, $63
    ld h, e
    rst $30
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    dec hl
    ld d, d
    ld b, e
    ld b, e
    ld h, e
    rst $28
    xor $3a
    ld b, l
    ld a, $51
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld h, e
    ld h, d
    dec hl
    ld b, d
    ld a, [$eff7]
    xor $41
    ld c, h
    ld b, d
    ld d, b
    ld c, e
    ld h, a
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld b, l
    ld c, h
    ld d, h
    rst $28
    xor $50
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    dec h
    ld d, d
    ld d, c
    ld h, d
    or $5e
    rst $28
    xor $4d
    ld b, d
    ld c, h
    ld c, l
    ld c, c
    ld b, d
    ld h, d
    ld a, $49
    ld d, h
    ld a, $56
    ld d, b
    ld a, [$eff7]
    xor $54
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $43
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld a, [hl-]
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $51
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
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
    ld b, h
    ld c, h
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
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
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
    ld h, h
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
    ld b, d
    ld a, $4f
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $40
    ld a, $4b
    ld h, d
    ld c, d
    ld b, d
    ld b, d
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $43
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld b, d
    ld c, c
    ld b, e
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
    ld [hl], $42
    ld b, d
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $40
    ld a, $4b
    ld h, d
    ld a, $40
    ld d, c
    ld d, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld h, d
    ld c, d
    ld b, d
    ld b, d
    ld d, c
    ld a, [$eff7]
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
    ld h, d
    ld d, b
    ld b, d
    ld c, c
    ld b, e
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
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld h, d
    ld b, [hl]
    ld b, e
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
    ld h, d
    ld c, h
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
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld a, $56
    rst $28
    xor $4b
    ld c, h
    ld h, d
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $25
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
    ld [hl-], a
    ld b, l
    ld h, d
    jr nc, jr_021_4e8c

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
    or $63
    ld a, [$eff7]
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
    rst $28
    xor $50
    ld b, l
    ld a, $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld c, [hl]
    ld d, d
    ld a, $48
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $50
    ld d, c
    ld a, $4f
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l

jr_021_4e8c:
    ld h, d
    ld a, $50
    ld d, b
    ld d, d
    ld c, d
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
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $42
    ld c, e
    ld b, b
    ld c, h
    ld d, d
    ld c, a
    ld a, $44
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $51
    ld c, h
    ld c, h
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld h, $4c
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    jr nc, jr_021_4f08

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $f6
    ld h, e
    ld h, d
    ld a, [hl+]
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
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
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l

jr_021_4f08:
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
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $49
    ld c, h
    ld b, b
    ld a, $51
    ld b, d
    ld b, c
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
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld h, d
    ld b, e
    ld b, d
    ld a, $4f
    ld d, b
    rst $28
    xor $43
    ld c, h
    ld c, a
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
    ld e, [hl]
    ld a, [$eff7]
    xor $30
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    or $5f
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
    ld b, d
    ld a, $50
    ld b, d
    rst $28
    xor $45
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl+]
    ld c, h
    ld h, d
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
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $43
    ld d, d
    ld d, c
    ld d, d
    ld c, a
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
    ld c, a
    ld a, [$eff7]
    xor $4c
    ld d, h
    ld c, e
    ld h, d
    ld b, d
    ld d, [hl]
    ld b, d
    ld d, b
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
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
    ld c, d
    ld b, d
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $49
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
    rst $28
    xor $2a
    ld a, $51
    ld b, d
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
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
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
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld a, [$eff7]
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
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    add hl, hl
    ld a, $4f
    ld h, d
    ccf
    ld b, d
    ld d, [hl]
    ld c, h
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $2a
    ld a, $51
    ld b, d
    ld e, [hl]
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $43
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    daa
    ld c, h
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $51
    ld c, a
    ld d, d
    ld b, d
    ld h, d
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    ld e, [hl]
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, e
    ld h, d
    ld b, [hl]
    ld b, e
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld c, d
    ld b, d
    ld b, d
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $43
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc h
    ld h, d
    ld c, [hl]
    ld d, d
    ld c, h
    ld d, c
    ld b, d
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $47
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $47
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld d, [hl]
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld a, $ef
    xor $49
    ld b, d
    ld b, h
    ld b, d
    ld c, e
    ld b, c
    ld a, $4f
    ld d, [hl]
    ld h, d
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
    ld e, [hl]
    ld h, d
    jr nc, jr_021_518b

    ld c, a
    ld d, [hl]
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld [hl], $4c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld a, $4a
    ld b, d
    rst $28
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
    inc l
    ld l, d

jr_021_518b:
    ld h, d
    ld a, $4a
    ld a, $57
    ld b, d
    ld b, c
    ld e, a
    ld h, d
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $54
    ld c, h
    ld c, a
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld b, l
    ld a, $4f
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
    ld c, l
    ld d, d
    ld c, e
    ld d, [hl]
    ld h, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
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
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld h, d
    scf
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
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $50
    ld d, c
    ld a, $4f
    ld d, c
    ld h, d
    ld d, b
    ld c, h
    ld c, h
    ld c, e
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld e, [hl]
    ld h, d
    inc l
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $3f
    ld b, d
    ld b, b
    ld a, $4a
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld h, e
    ld a, [$eff7]
    xor $3c
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld a, $4a
    ld a, $57
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
    dec l
    ld d, d
    ld d, b
    ld d, c
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
    ld a, [$eff7]
    xor $46
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec h
    ld b, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld d, b
    ld d, c
    ld a, $4b
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec l
    ld d, d
    ld d, b
    ld d, c
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
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld d, b
    ld b, [hl]
    ld b, h
    ld c, e
    ld b, [hl]
    ld b, e
    ld b, [hl]
    ld b, b
    ld a, $4b
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld b, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld b, e
    ld a, $4b
    ld d, c
    ld a, $50
    ld d, c
    ld b, [hl]
    ld b, b
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    jr nc, jr_021_534a

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
    inc l
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, d

FuncAnim21_5344:
    ld b, l
    ld c, h
    ld d, h
    rst $28
    xor $4a

jr_021_534a:
    ld a, $4b
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
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $40
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
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld h, e
    rst $28
    xor $2c
    ld h, d
    ld b, b
    ld a, $4b
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
    ld d, c
    ld b, l
    ld a, $51
    rst $28
    xor $56
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
    ld a, [$eff7]
    xor $40
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld d, d
    ld b, d
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $54
    ld b, [hl]
    ld c, e
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
    or $68
    rst $28
    xor $53
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
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
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    dec h
    ld a, $57
    ld a, $3e
    ld c, a
    ld h, e
    ld a, [$eff7]
    xor $30
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld d, b
    rst $28
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld c, h
    ld c, l
    ld b, d
    ld c, e
    ld b, d
    ld b, c
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    dec [hl]
    ld b, d
    ld c, l
    ld h, h
    ld h, d
    inc h
    ld h, d
    ld c, b
    ld b, [hl]
    ld b, c
    rst $28
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, h
    ld h, d
    cpl
    ld b, [hl]
    ld a, $4f
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
    ld b, d
    ld c, c
    ld c, c
    ld c, h
    ld c, h
    ld c, h
    ld c, h
    ld h, e
    ld h, d
    ld a, [hl-]
    ld a, $48
    ld b, d
    ld d, [hl]
    ld e, [hl]
    rst $28
    xor $54
    ld a, $48
    ld b, d
    ld b, d
    ld b, d
    ld d, [hl]
    ld h, e
    ld a, [$eff7]
    xor $36
    ld d, c
    ld c, h
    ld c, l
    ld h, d
    ld b, c
    ld c, a
    ld b, d
    ld a, $4a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    jr nc, jr_021_54d8

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    or $63
    rst $28
    xor $fa
    rst $30
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
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $25
    ld a, $57
    ld a, $3e
    ld c, a
    ld h, e
    rst $30
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
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    rst $28
    xor $46
    ld d, b
    ld h, d

jr_021_54d8:
    ld a, $49
    ld c, d
    ld c, h
    ld d, b
    ld d, c
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld a, $4a
    ld h, d
    ld d, b
    ld c, h
    ld c, h
    ld c, h
    ld h, d
    ld b, d
    ld d, l
    ld b, b
    ld b, [hl]
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
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4a
    ld b, d
    ld c, a
    ld b, b
    ld b, l
    ld a, $4b
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $4b
    ld a, [$eff7]
    xor $3e
    ld d, c
    ld d, c
    ld b, [hl]
    ld d, c
    ld d, d
    ld b, c
    ld b, d
    ld h, d
    ld b, l
    ld a, $50
    rst $28
    xor $51
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld a, $62
    ld c, e
    ld b, d
    ld d, h
    ld a, [$eff7]
    xor $49
    ld b, d
    ld a, $43
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    add hl, hl
    ld c, h
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
    xor $2c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld d, b
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
    cpl
    ld a, $62
    ld c, c
    ld a, $62
    ld c, c
    ld a, $62
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
    ld e, a
    ld e, a
    ld e, a
    ld h, d
    or $68
    ld a, [$eff7]
    xor $53
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    jr z, jr_021_5611

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
    xor $4d
    ld a, $4f
    ld d, c
    ld d, [hl]
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld a, $52
    ld d, b
    ld b, d
    ld a, [$eff7]
    xor $46
    ld d, c
    ld l, b
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
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    jr nc, jr_021_565d

    ld e, a
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $2b
    ld d, d
    ld c, a

jr_021_5611:
    ld c, a
    ld a, $56
    ld h, e
    ld h, d
    dec hl
    ld d, d
    ld c, a
    ld c, a
    ld a, $56
    rst $28
    xor $f6
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    jr z, jr_021_5669

    ld c, b
    ld h, d
    ld b, d
    ld b, d
    ld c, b
    ld h, d
    ld b, d
    ld b, d
    ld c, b
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr nc, jr_021_5681

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    ld h, d
    inc l
    ld h, d
    ld d, h
    ld a, $4b
    ld c, e
    ld a, $ef
    xor $3f
    ld b, d
    ld h, d
    ld a, $62
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld h, e
    rst $30
    ldh a, [$ea]

jr_021_565d:
    sbc a
    and e
    add hl, hl
    ld b, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld d, e
    ld a, $49
    ld d, b
    ld h, d

jr_021_5669:
    ld a, $4f
    ld b, d
    rst $28
    xor $43
    ld d, d
    ld c, e
    ld h, e
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
    ld c, c

jr_021_5681:
    ld b, d
    ld a, $4f
    ld c, e
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
    ld b, [hl]
    ld d, c
    ld b, d
    ld c, d
    ld d, b
    ld a, [$eff7]
    xor $50
    ld c, h
    ld c, c
    ld b, c
    ld h, d
    ld a, $51
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
    ld d, b
    ld h, h
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld b, d
    ld a, $4f
    ld b, b
    ld b, l
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    rst $28
    xor $3e
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]
    ccf
    ld c, a
    ld a, $4f
    ld d, [hl]
    ld e, a
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld e, [hl]
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld e, a
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld b, [hl]
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    rst $28
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld a, $62
    ld b, h
    ld c, c
    ld c, h
    ld c, h
    ld c, d
    ld d, [hl]
    rst $28
    xor $43
    ld a, $40
    ld b, d
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
    ld c, d
    ld b, d
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
    ld d, b
    ld c, d
    ld b, [hl]
    ld c, c
    ld b, d
    ld h, h
    rst $38
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld c, b
    ld a, $56
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
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld e, a
    ld e, a
    ld e, a
    ld d, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    ld e, [hl]
    ld d, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    rst $28
    xor $5f
    ld e, a
    ld e, a
    ld h, d
    ld d, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    ld e, [hl]
    ld d, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    ld a, [$eff7]
    xor $9f
    and e
    ld d, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    ld e, [hl]
    ld d, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    rst $28
    xor $51
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    ld e, [hl]
    ld d, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld sp, $544c
    ld e, [hl]
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
    ld d, b
    ld h, d
    ld a, $62
    ld d, b
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ld b, a
    ld c, h
    ld d, [hl]
    ld h, e
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
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4a
    ld b, d
    ld c, a
    ld b, b
    ld b, l
    ld a, $4b
    ld d, c
    ld h, d
    ld b, l
    ld a, $50
    ld a, [$eff7]
    xor $51
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld a, $62
    ld c, e
    ld b, d
    ld d, h
    rst $28
    xor $49
    ld b, d
    ld a, $43
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
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
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
    ccf
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, h
    ld d, d
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $50
    ld b, d
    ld c, c
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, h
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld l, h
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld b, d
    ld c, e
    ld h, d
    ld a, $49
    ld c, h
    ld c, e
    ld b, d
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld a, $62
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld l, d
    ld h, d
    ld c, c
    ld c, h
    ld c, e
    ld b, d
    ld c, c
    ld d, [hl]
    ld e, a
    rst $28
    xor $2c
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    ld h, d
    ld d, b
    ld d, c
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $49
    ld c, h
    ld c, e
    ld b, d
    rst $28
    xor $3e
    ld c, e
    ld d, [hl]
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld c, l
    ld b, [hl]
    ld b, b
    ld c, b
    ld d, [hl]
    rst $28
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld b, b
    ld d, d
    ld d, b
    ld d, c
    ld c, h
    ld c, d
    ld b, d
    ld c, a
    ld d, b
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld d, [hl]
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld h, e
    ld h, d
    inc l
    ld l, h
    ld b, d
    rst $28
    xor $40
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld b, c
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, d
    ld c, c
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, e
    ld h, d
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld c, d
    ld a, $56
    rst $28
    xor $2c
    ld h, d
    ld b, l
    ld b, d
    ld c, c
    ld c, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, h
    ldh a, [$ea]
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
    rst $28
    xor $4c
    ld c, e
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
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
    ld h, e
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
    ld a, $51
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld h, h
    rst $28
    xor $ff
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld a, $46
    ld b, c
    ld h, d
    ld c, e
    ld c, h
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $37
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
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
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    cpl
    ld b, d
    ld c, d
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
    xor $3e
    ld h, d
    ld d, b
    ld b, b
    ld a, $4f
    ld d, [hl]
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld e, a
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld l, b
    ld h, d
    ld a, $62
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    ld b, [hl]
    ld b, h
    ld c, e
    rst $28
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, d
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld b, l
    ld b, d
    ld a, $41
    ld d, b
    rst $28
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld a, $4b
    ld h, d
    ld [hl-], a
    ld c, a
    ld c, h
    ld b, b
    ld b, l
    ld b, [hl]
    ld e, [hl]
    ld a, [$eff7]
    xor $9f
    and e
    ld b, l
    ld a, $46
    ld c, a
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    rst $28
    xor $30
    ld b, d
    ld b, c
    ld d, d
    ld d, b
    ld a, $28
    ld d, [hl]
    ld b, d
    ld l, b
    ld a, [$eff7]
    xor $9f
    and e
    ld a, $4b
    ld b, c
    ld h, d
    ld a, $62
    ld c, d
    ld c, h
    ld d, d
    ld d, c
    ld b, l
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    rst $28
    xor $26
    ld c, h
    ld b, [hl]
    ld c, c
    dec h
    ld b, [hl]
    ld c, a
    ld b, c
    ld l, b
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld b, l
    ld h, e
    ld h, e
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    rst $28
    xor $4f
    ld b, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld a, [$eff7]
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
    ld h, d
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    ld h, h
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
    ld b, l
    ld c, h
    ld c, a
    ld c, a
    ld b, [hl]
    ccf
    ld c, c
    ld b, d
    ld e, a
    rst $28
    xor $3a
    ld b, d
    ld c, c
    ld c, c
    ld e, [hl]
    ld h, d
    inc l
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld h, a
    ld a, [$eff7]
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
    ld b, e
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $4b
    ld c, h
    ld d, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld c, c
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld a, [$eff7]
    xor $54
    ld b, l
    ld c, h
    ld h, d
    ld b, h
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $43
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld l, d
    ld h, d
    ccf
    ld b, d
    ld d, c
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld c, e
    rst $28
    xor $54
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
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld e, a
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
    ccf
    ld b, d
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld h, h
    rst $28
    xor $ff
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld a, $3e
    ld d, c
    ld h, h
    rst $28
    xor $01
    nop
    nop
    ld h, d
    ld d, c
    ld b, l
    ld c, h
    ld d, d
    ld d, b
    ld a, $4b
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $44
    ld c, h
    ld c, c
    ld b, c
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    or $64
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc h
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, b
    ld a, $4b
    ld b, d
    ld h, e
    ld h, h
    rst $28
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    ld a, $62
    ccf
    ld b, [hl]
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld e, a
    ld e, a
    ld h, e
    ld h, d
    ld a, [hl-]
    ld a, $46
    ld d, c
    ld h, d
    ld a, $ef
    xor $4a
    ld b, [hl]
    ld c, e
    ld d, d
    ld d, c
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $24
    ld c, a
    ld b, d
    ld c, e
    ld h, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $f6
    ld h, e
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    inc sp
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
    xor $40
    ld a, $4b
    ld h, a
    ld h, d
    ccf
    ld b, d
    ld d, c
    ld e, a
    ld h, d
    ld [hl], $4c
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    ld d, h
    ld b, l
    ld d, [hl]
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
    ccf
    ld c, c
    ld d, d
    ld b, e
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    jr nc, @+$58

    ld h, d
    ld b, h
    ld c, h
    ld b, c
    ld e, [hl]
    ld h, d
    ld d, d
    ld c, l
    rst $28
    xor $40
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    ld e, [hl]
    ld h, d
    inc l
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    or $63
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc sp
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
    xor $40
    ld a, $4b
    ld h, a
    ld h, d
    ccf
    ld b, d
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    jr z, jr_021_5cdd

    ld b, b
    ld d, d
    ld d, d
    ld d, d
    ld d, d
    ld d, b
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ccf
    ld b, d
    ld d, c
    ld h, d
    ld c, h
    ld c, e
    rst $28
    xor $f6
    ld h, e
    ld a, [$eff7]
    xor $27
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ccf
    ld b, d
    ld d, b
    ld d, c
    ld h, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl+]
    ld a, [hl-]
    ld a, [hl-]
    dec [hl]
    dec [hl]
    dec [hl]
    ld h, e
    ld h, d
    inc l
    ld d, c
    ld l, b
    rst $28
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    cpl
    ld c, h
    ld b, h
    ld h, e
    ld h, d
    ld [hl-], a
    ld b, e
    ld a, [$eff7]
    xor $40

jr_021_5cdd:
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    cpl
    ld c, h
    ld b, h
    ld h, e
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
    ld d, h
    ld c, h
    ld c, a
    ld c, b
    ld h, d
    ld c, h
    ld c, e
    rst $28
    xor $50
    ld d, d
    ld c, a
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld [hl], $62
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $24
    ld c, c
    ld c, c
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld h, e
    ld h, e
    ld a, [$eff7]
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
    ld a, [$eff7]
    xor $2d
    ld c, h
    ld d, [hl]
    ld h, d
    or [hl]
    ld h, d
    ld a, [hl-]
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
    ld a, [$eff7]
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
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $33
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
    ld e, a
    rst $28
    xor $37
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
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $3f
    ld b, d
    ld c, c
    ld c, h
    ld d, h
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld d, c
    ld l, b
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
    rst $28
    xor $3f
    ld d, d
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, h
    ld b, d
    ld a, $48
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, e
    ld d, b
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
    inc h
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
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
    ld a, [$eff7]
    xor $9f
    and e
    dec [hl]
    ld a, $46
    ld d, b
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
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
    ld c, h
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $4c
    ld d, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    rst $28
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
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
    ld h, d
    or [hl]
    ld a, [$eff7]
    xor $37
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
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    jr nc, jr_021_5f1d

    ld c, d
    ld c, h
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    ld a, [$eff7]
    xor $b6
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
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec h
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    jr nc, jr_021_5f42

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $f6
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

jr_021_5f1d:
    rst $28
    xor $3f
    ld b, d
    ld b, b
    ld a, $4a
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    jr nc, jr_021_5f6a

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $4c
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
    ld h, e
    ld h, e

jr_021_5f42:
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
    cpl
    ld a, $3f
    ld d, [hl]
    ld c, a
    ld b, [hl]
    ld c, e
    ld d, c

jr_021_5f6a:
    ld b, l
    ld a, [$eff7]
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
    ld h, d
    ld h, $42
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
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld e, [hl]
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
    ld e, [hl]
    ld a, [$eff7]
    xor $30
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    or $63
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
    cpl
    ld a, $3f
    ld d, [hl]
    ld c, a
    ld b, [hl]
    ld c, e
    ld d, c
    ld b, l
    ld a, [$eff7]
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
    rst $28
    xor $26
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
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, b
    ld a, $56
    ld h, d
    ld c, l
    ld b, d
    ld c, h
    ld c, l
    ld c, c
    ld b, d
    rst $28
    xor $50
    ld b, d
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld d, d
    ld d, c
    ld d, d
    ld c, a
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
    ld e, a
    ld e, a
    ld e, a
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
    ldh a, [$eb]
    ld [hl], $49
    ld b, [hl]
    ld c, h
    and e
    ld a, [hl-]
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $41
    ld c, h
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld a, $62
    ld b, e
    ld a, $53
    ld c, h
    ld c, a
    ld h, h
    ld a, [$eff7]
    xor $36
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc l
    ld h, d
    ld d, h
    ld a, $4b
    ld c, e
    ld a, $62
    ld b, h
    ld c, h
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    or $5f
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $36
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    scf
    ld a, $48
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, e
    ld h, d
    inc sp
    ld c, c
    ld b, d
    ld b, d
    ld b, d
    ld a, $50
    ld b, d
    ld h, e
    rst $38
    ldh a, [$eb]
    ld [hl], $49
    ld b, [hl]
    ld c, h
    and e
    inc l
    ld h, d
    ld b, h
    ld d, d
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    inc l
    ld l, d
    rst $28
    xor $52
    ld d, b
    ld b, d
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $4b
    ld c, h
    ld d, h
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $36
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
    ld h, d
    ld b, b
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, c
    ld e, [hl]
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld a, [$eff7]
    xor $48
    ld c, e
    ld c, h
    ld d, h
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    ld [hl], $49
    ld b, [hl]
    ld c, h
    and e
    or $5e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld h, d
    ld c, d
    ld a, $4b
    ld d, [hl]
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
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $36
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    scf
    ld a, $49
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld b, d
    rst $28
    xor $3e
    ld b, e
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld c, a
    ld b, [hl]
    ld b, c
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    ld [hl], $49
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
    ld h, e
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld a, [$eff7]
    xor $54
    ld a, $46
    ld d, c
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld a, $51
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld h, e
    ld h, e
    rst $30
    ldh a, [$eb]
    ld [hl], $49
    ld b, [hl]
    ld c, h
    and e
    or $63
    rst $28
    xor $3c
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
    ld a, [$eff7]
    xor $51
    ld a, $48
    ld b, d
    ld h, d
    ld c, d
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
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, h
    rst $28
    xor $2c
    ld l, d
    ld h, d
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld h, e
    ld h, d
    inc l
    ld l, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $50
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld [hl], $49
    ld b, [hl]
    ld c, h
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
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
    ld a, [$eff7]
    xor $43
    ld a, $4f
    ld c, d
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    inc h
    ld d, b
    ld h, d
    ld c, d
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $42
    ld d, l
    ld c, l
    ld b, d
    ld b, b
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    or $63
    ld a, [$eff7]
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $40
    ld c, h
    ld c, e
    ld b, e
    ld b, [hl]
    ld b, c
    ld b, d
    ld c, e
    ld b, b
    ld b, d
    ld h, e
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
    ld b, c
    ld c, a
    ld c, h
    ld c, l
    rst $28
    xor $4c
    ld b, e
    ld b, e
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld bc, $fa09
    rst $30
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
    ld a, $4b
    ld b, c
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld d, b
    rst $28
    xor $45
    ld b, d
    ld c, a
    ld b, d
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
    ld e, [hl]
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld d, b
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, e
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld c, h
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
    ld d, b
    ld d, c
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $44
    ld b, d
    ld d, c
    ld h, d
    ld a, $62
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ccf
    ld b, [hl]
    ld d, c
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld b, d
    ld d, l
    ld c, l
    ld b, d
    ld c, a
    ld b, [hl]
    ld b, d
    ld c, e
    ld b, b
    ld b, d
    rst $28
    xor $42
    ld d, e
    ld b, d
    ld c, e
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, c
    ld b, d
    ld a, $53
    ld b, d
    ld a, [$eff7]
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
    rst $28
    xor $45
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, c
    ld b, d
    ld a, $53
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $49
    ld c, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, [hl]
    ld c, d
    ld b, d
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $4c
    ccf
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec [hl]
    ld b, d
    ld c, d
    ld b, d
    ld c, d
    ccf
    ld b, d
    ld c, a
    ld e, [hl]
    rst $28
    xor $50
    ld c, c
    ld b, d
    ld b, d
    ld c, l
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
    ld a, [$eff7]
    xor $9f
    and e
    ld e, a
    ld e, a
    ld e, a
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld a, $4b
    ld d, [hl]
    rst $28
    xor $42
    ld d, l
    ld c, l
    ld b, d
    ld c, a
    ld b, [hl]
    ld b, d
    ld c, e
    ld b, b
    ld b, d
    ld e, a
    rst $30
    ldh a, [$eb]
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
    ld a, [$eff7]
    xor $43
    ld a, $4f
    ld c, d
    ld h, h
    rst $28
    xor $ff
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
    ld b, b
    ld a, $49
    ld c, c
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld d, b
    rst $28
    xor $25
    ld b, [hl]
    ld c, a
    ld b, c
    dec h
    ld c, c
    ld c, h
    ld d, h
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld h, $4c
    ld c, l
    ld d, [hl]
    ld b, b
    ld c, h
    ld c, l
    ld d, [hl]
    ld e, a
    ld h, d
    inc l
    rst $28
    xor $54
    ld a, $4b
    ld c, e
    ld a, $62
    ld b, b
    ld c, h
    ld c, l
    ld d, [hl]
    ld b, b
    ld c, h
    ld c, l
    ld d, [hl]
    ld a, [$eff7]
    xor $25
    ld a, $49
    ld d, a
    ld a, $48
    ld h, d
    ld d, c
    ld c, h
    ld b, c
    ld a, $56
    ld e, a
    rst $28
    xor $26
    ld c, h
    ld c, l
    ld d, [hl]
    ld b, b
    ld c, h
    ld c, l
    ld d, [hl]
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    jr z, jr_021_65c7

    ld c, l
    ld c, c
    ld c, h
    ld b, c
    ld b, d
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $3d
    ld a, $4d
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld h, h
    ld h, h
    ld h, h
    ld e, a
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld b, d
    ld c, c
    ld c, c
    ld c, h
    ld h, e
    rst $28
    xor $2c
    ld l, d
    ld h, d
    dec hl
    ld b, d
    ld c, c
    ld c, h
    ld a, [$eff7]
    xor $9f
    and e
    jr nc, jr_021_65fc

    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld c, d
    ld b, d
    ld c, a
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $54
    ld a, $4b
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld a, [$eff7]
    xor $4a
    ld c, h

jr_021_65c7:
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld d, b
    ld c, h
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld b, l
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, c
    ld b, d
    ld c, e
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld a, $49
    ld c, c
    ld d, [hl]
    rst $28
    xor $42
    ld d, l
    ld d, c
    ld b, d
    ld c, e
    ld b, c
    ld b, d
    ld b, c
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld d, b

jr_021_65fc:
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $44
    ld b, [hl]
    ld d, e
    ld b, d
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
    ld d, b
    rst $28
    xor $49
    ld c, h
    ld d, c
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld a, $51
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld c, h
    ld h, d
    ld a, $40
    ld b, b
    ld c, h
    ld c, d
    ld c, l
    ld c, c
    ld b, [hl]
    ld d, b
    ld b, l
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld e, [hl]
    ld h, d
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld c, b
    ld a, [$eff7]
    xor $54
    ld b, d
    ld a, $48
    ld h, d
    ld c, d
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
    rst $28
    xor $45
    ld b, [hl]
    ld c, d
    ld e, a
    ld a, [$eff7]
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
    ld b, l
    ld b, d
    rst $28
    xor $4c
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $2b
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld b, [hl]
    ld b, d
    ld b, c
    ld h, d
    ld c, d
    ld a, $4b
    ld d, [hl]
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld e, a
    ld e, a
    dec hl
    ld e, a
    ld e, a
    dec hl
    ld b, d
    ld c, c
    ld c, c
    ld c, h
    ld h, e
    rst $28
    xor $30
    ld e, a
    ld e, a
    ld c, d
    ld d, [hl]
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $37
    ld e, a
    ld e, a
    scf
    ld e, a
    ld e, a
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
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, h
    ld h, d
    daa
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $54
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld b, l
    ld c, h
    ld d, h
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
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
    rst $28
    xor $2a
    ld b, [hl]
    ld b, h
    ld a, $36
    ld c, c
    ld a, $50
    ld b, l
    ld h, h
    ld a, [$eff7]
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    ld b, h
    ld c, a
    ld b, d
    ld a, $51
    ld e, a
    rst $28
    xor $28
    jr z, jr_021_6767

    jr z, @+$4a

    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld c, e
    ld a, $62
    ld b, [hl]
    ld d, b
    rst $28
    xor $40
    ld d, d
    ld c, a
    ld c, a
    ld b, d
    ld c, e
    ld d, c
    ld c, c
    ld d, [hl]
    ld h, d
    ccf
    ld b, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]

jr_021_6767:
    xor $4d
    ld c, a
    ld b, d
    ld c, l
    ld a, $4f
    ld b, d
    ld b, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr c, jr_021_67c6

    ld d, c
    ld b, [hl]
    ld c, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $4f
    ld b, d
    ld a, $41
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld d, c
    ld c, a
    ld a, $46
    ld c, e
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
    ld d, b
    ld h, d
    ld d, h
    ld b, d
    ld c, c
    ld c, c
    ld h, e
    rst $28
    xor $f7
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
    ld b, l
    ld b, [hl]
    ld d, b
    rst $28
    xor $30
    ld a, $47
    ld b, d
    ld d, b
    ld d, c

jr_021_67c6:
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, d
    ld a, $4b
    ld b, c
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, c
    rst $28
    xor $51
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
    ld d, [hl]
    ld h, d
    ld d, b
    ld a, $56
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
    ld b, e
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
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
    ld e, a
    ld a, [$eff7]
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
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    rst $28
    xor $54
    ld b, l
    ld c, h
    ld h, d
    ld c, e
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld c, a
    ld b, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $25
    ld b, d
    ld h, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld b, b
    ld a, $4f
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, b
    ld a, $56
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
    ld b, e
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
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
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $35
    ld b, d
    ld b, e
    ld b, d
    ld c, c
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, a
    ld a, [$eff7]
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
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    rst $28
    xor $54
    ld b, l
    ld c, h
    ld h, d
    ld c, e
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld c, a
    ld b, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $25
    ld b, d
    ld h, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld b, b
    ld a, $4f
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, [hl]
    ld h, d
    or $5e
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
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, l
    ld b, d
    ld c, c
    ld c, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, h
    ld b, l
    ld a, $51
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, c
    ld c, h
    ld h, e
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
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld a, [$eff7]
    xor $4a
    ld d, [hl]
    ld h, d
    inc a
    ld b, d
    ld d, c
    ld b, [hl]
    ld h, h
    rst $28
    xor $f0
    ld [$a39f], a
    ld [hl], $51
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld sp, $4446
    ld b, l
    ld d, c
    rst $28
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
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $3a
    ld b, l
    ld a, $51
    ld h, d
    ld a, $62
    ld b, h
    ld c, a
    ld b, d
    ld a, $51
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
    ld a, $4a
    ld h, d
    ld c, l
    ld c, a
    ld a, $56
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    rst $28
    xor $f6
    ld l, b
    ld h, d
    ld d, e
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld e, [hl]
    ld h, d
    ld c, h
    ccf
    ld b, d
    ld d, [hl]
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $40
    ld c, h
    ld c, d
    ld c, d
    ld a, $4b
    ld b, c
    ld e, a
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
    ld b, d
    ld b, d
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
    ld b, b
    ld a, $49
    ld c, c
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $3a
    ld b, [hl]
    ld c, c
    ld b, c
    inc h
    ld c, l
    ld b, d
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $25
    ld b, d
    ld a, $50
    ld d, c
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl+]
    ld b, [hl]
    ld b, h
    ld a, $4b
    ld d, c
    ld b, d
    ld d, b
    ld h, d
    ld b, h
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    rst $28
    xor $44
    ld b, [hl]
    ld b, h
    ld a, $4b
    ld d, c
    ld b, [hl]
    ld b, b
    ld h, d
    ld c, l
    ld c, a
    ld c, h
    ld d, c
    ld b, d
    ld d, b
    ld d, c
    ld d, b
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld b, h
    ld d, d
    ld d, [hl]
    ld h, d
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $42
    ld c, e
    ld d, c
    ld c, a
    ld a, $4b
    ld b, b
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $4f
    ld b, d
    ld d, b
    ld d, c
    ld a, $52
    ld c, a
    ld a, $4b
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $4f
    ld b, [hl]
    ld d, e
    ld a, $49
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    ld h, h
    ld h, d
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld c, a
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
    ld h, d
    ld a, $3f
    ld c, h
    ld d, d
    ld d, c
    ld a, [$eff7]
    xor $4f
    ld a, $46
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    ld d, b
    ld h, e
    ld h, h
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    jr nc, jr_021_6b46

    ld h, d
    ld c, a
    ld b, [hl]
    ld d, e
    ld a, $49
    ld h, d
    ld c, d
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $54
    ld a, $51
    ld b, b
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
    ld b, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld d, d
    ld c, a
    ld b, d
    rst $28
    xor $4c
    ld d, d
    ld d, c
    ld h, d
    ld d, h
    ld b, l
    ld d, [hl]
    ld h, d
    inc l
    ld l, d
    ld a, [$eff7]
    xor $4f
    ld a, $46
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
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

jr_021_6b46:
    xor $9f
    and e
    jr z, @+$55

    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld a, $62
    ld c, d
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld c, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld e, [hl]
    ld a, [$eff7]
    xor $54
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    inc l
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld b, d
    ld a, $51
    rst $28
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld e, a
    ld e, a
    ld b, l
    ld a, $62
    ld b, l
    ld a, $5f
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld l, h
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld b, d
    ld c, e
    rst $28
    xor $51
    ld c, a
    ld a, $46
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $25
    ld c, h
    ld c, d
    ccf
    ld h, $4f
    ld a, $44
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, a
    ld d, d
    ld c, e
    rst $28
    xor $3e
    ld d, h
    ld a, $56
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld l, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld c, a
    ld c, h
    ld d, d
    ccf
    ld c, c
    ld b, d
    ld e, a
    rst $28
    xor $35
    ld b, d
    ld b, b
    ld b, d
    ld c, e
    ld d, c
    ld c, c
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld b, l
    ld b, d
    ld l, b
    ld a, [$eff7]
    xor $49
    ld c, h
    ld d, b
    ld d, c
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    rst $28
    xor $4a
    ld c, h
    ld d, c
    ld b, [hl]
    ld d, e
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld b, h
    ld d, d
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld l, b
    rst $28
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
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, l
    ld b, d
    ld l, b
    ld h, d
    ccf
    ld b, d
    ld b, d
    ld c, e
    rst $28
    xor $41
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld c, a
    ld d, d
    ld c, e
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $3e
    ld d, h
    ld a, $56
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld [hl], $40
    ld d, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    ld a, $54
    ld a, $56
    rst $28
    xor $36
    ld b, b
    ld d, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    ld a, $54
    ld a, $56
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld b, d
    ld a, $50
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $4f
    ld d, d
    ld c, e
    ld h, e
    ld h, d
    dec hl
    ld b, d
    ld d, [hl]
    ld h, d
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, e
    rst $30
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
    ld h, e
    ld h, d
    inc a
    ld c, h
    rst $28
    xor $41
    ld d, d
    ld b, c
    ld b, d
    ld e, a
    ld h, d
    ld a, [hl-]
    ld a, $4b
    ld c, e
    ld a, $62
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld a, [$eff7]
    xor $54
    ld b, l
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    rst $28
    xor $43
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, [hl]
    ld c, e
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
    ld h, e
    ld h, d
    inc l
    ld h, d
    ld b, c
    ld d, d
    ld c, e
    ld c, e
    ld c, h
    rst $28
    xor $42
    ld b, [hl]
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld l, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, d
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $26
    ld l, d
    ld c, h
    ld c, e
    ld h, d
    dec h
    ld b, d
    ccf
    ld b, d
    ld e, [hl]
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld b, d
    ld a, $51
    ld a, [$eff7]
    xor $3e
    ld b, e
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld c, d
    ld b, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    ld h, d
    ld b, c
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $51
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld h, d
    jr nc, jr_021_6d99

    ld h, d
    ld c, d
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld h, e
    ld h, e
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

jr_021_6d99:
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
    rst $28
    xor $3f
    ld b, d
    ld b, b
    ld a, $4a
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld e, a
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
    ld l, h
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    rst $28
    xor $3f
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
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
    xor $fa
    rst $30
    rst $28
    xor $9f
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
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld b, d
    ld c, e
    ld b, h
    ld d, c
    ld b, l
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $43
    ld c, h
    ld c, a
    ld b, d
    ld b, [hl]
    ld b, h
    ld c, e
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
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
    inc a
    ld c, h
    ld d, d
    ld l, l
    ld h, d
    ccf
    ld b, d
    ld d, c
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $50
    ld d, c
    ld a, $56
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld d, c
    ld c, h
    ld b, d
    ld d, b
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    inc l
    rst $28
    xor $41
    ld c, h
    ld h, h
    ld h, d
    scf
    ld b, l
    ld a, $51
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld a, [$eff7]
    xor $4b
    ld b, [hl]
    ld b, b
    ld b, d
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    rst $28
    xor $44
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld e, a
    ld e, a
    ld e, a
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
    rst $28
    xor $4a
    ld a, $41
    ld b, d
    ld h, d
    ld a, [hl+]
    ld b, [hl]
    ld b, h
    ld a, $4b
    ld d, c
    ld b, d
    ld d, b
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld h, d
    ld d, d
    ld c, e
    ld b, b
    ld b, d
    ld c, a
    ld d, c
    ld a, $46
    ld c, e
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
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
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, e
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $3f
    ld d, d
    ld c, a
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ccf
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld a, $51
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $50
    ld b, [hl]
    ld d, a
    ld d, a
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    rst $30
    ldh a, [$eb]
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
    xor $3a
    ld b, [hl]
    ld c, c
    ld b, c
    inc h
    ld c, l
    ld b, d
    ld h, e
    ld h, d
    scf
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, e
    ld c, b
    ld b, d
    ld d, [hl]
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld h, d
    ld d, b
    ld c, h
    ld c, h
    ld c, h
    rst $28
    xor $50
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld h, e
    ld a, [$eff7]
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
    ld h, d
    add hl, hl
    ld c, h
    ld c, a
    rst $28
    xor $3f
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, [hl]
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
    ld h, d
    ld a, $ef
    xor $4f
    ld b, d
    ld d, h
    ld a, $4f
    ld b, c
    ld e, a
    ld a, [$f0f7]
    ld [$a39f], a
    inc l
    ld h, d
    ld b, l
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
    rst $28
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld a, $4b
    ld h, d
    ld a, $54
    ld b, e
    ld d, d
    ld c, c
    ld a, [$eff7]
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    rst $28
    xor $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
    ld b, d
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld d, c
    ld b, l
    ld c, a
    ld b, d
    ld b, d
    rst $28
    xor $42
    ld d, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $45
    ld a, $46
    ld c, a
    ld d, [hl]
    ld h, d
    ld b, e
    ld a, $40
    ld b, d
    ld h, e
    ld h, e
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
    ccf
    ld b, d
    rst $28
    xor $40
    ld a, $4f
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    ld h, e
    ld a, [$eff7]
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
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld c, b
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    rst $28
    xor $44
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $25
    ld d, d
    ld d, c
    ld h, d
    ld d, [hl]
    ld b, d
    ld d, c
    ld e, a
    ld e, a
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $56
    ld b, d
    ld d, c
    ld h, e
    ld h, d
    dec hl
    ld b, [hl]
    ld b, b
    ld e, a
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    or $5f
    rst $28
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
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, l
    ld d, d
    ld d, c
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
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $41
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
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
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
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $3f
    ld b, [hl]
    ld b, h
    ld h, d
    ld b, l
    ld a, $4a
    ld c, d
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
    or $63
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, d
    ld c, a
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
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
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
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
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
    xor $2c
    ld l, d
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $43
    ld c, h
    ld c, a
    ld d, h
    ld a, $4f
    ld b, c
    ld h, d
    ld d, c
    ld c, h
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
    ld h, e
    rst $30
    ldh a, [$eb]
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
    ld a, $ef
    xor $24
    scf
    ld l, $50
    ld b, d
    ld b, d
    ld b, c
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
    ld [hl-], a
    ccf
    ld b, d
    ld d, [hl]
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, d
    ld a, $4b
    ld b, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
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
    xor $2b
    ld c, h
    ld c, a
    ld c, e
    dec h
    ld b, d
    ld b, d
    ld d, c
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
    xor $25
    ld d, d
    ld b, h
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
    ld c, h
    ld c, a
    ld c, e
    dec h
    ld b, d
    ld b, d
    ld d, c
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $3f
    ld b, d
    ld b, d
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $45
    ld c, h
    ld c, a
    ld c, e
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
    ld a, $4a
    ld a, $57
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $28
    xor $2c
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    ld c, e
    ld h, a
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $54
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld a, $62
    ld b, h
    ld c, a
    ld b, d
    ld a, $51
    rst $28
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, [hl]
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
    ld h, d
    ld b, [hl]
    ld d, b
    ld c, e
    ld h, a
    rst $28
    xor $47
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld a, $62
    ld b, c
    ld c, a
    ld b, d
    ld a, $4a
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, a
    ld a, $46
    ld d, b
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
    xor $51
    ld c, h
    ld c, h
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld [hl], $3e
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld d, h
    ld b, l
    ld d, [hl]
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    ld a, [$eff7]
    xor $30
    ld b, d
    ld d, c
    ld a, $49
    ld d, [hl]
    ld h, h
    rst $28
    xor $f0
    ld [$a39f], a
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4a
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
    rst $28
    xor $3e
    ld b, h
    ld a, $46
    ld c, e
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
    ld a, [$eff7]
    xor $46
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld d, d
    ld b, d
    rst $28
    xor $40
    ld c, h
    ld d, d
    ld c, a
    ld a, $44
    ld b, d
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    add hl, hl
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $53
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    rst $28
    xor $46
    ld c, e
    ld b, e
    ld c, h
    ld c, a
    ld c, d
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
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
    ld d, b
    ld a, $56
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $49
    ld c, h
    ld d, d
    ld b, c
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
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
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $36
    ld c, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld a, $ef
    xor $30
    ld b, d
    ld d, c
    ld a, $49
    daa
    ld c, a
    ld a, $5f
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc h
    ld h, d
    jr nc, jr_021_743b

    ld d, c
    ld a, $49
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $3f
    ld c, h
    ld c, a
    ld c, e
    ld h, e
    ld a, [$eff7]
    xor $24
    ld c, d
    ld a, $57
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, l
    ld d, d
    ld b, l
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
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
    xor $40
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld c, e
    ld h, a
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld a, [$eff7]
    xor $40

jr_021_743b:
    ld c, c
    ld b, d
    ld a, $4f
    ld c, c
    ld d, [hl]
    ld h, h
    ld h, d
    ld [hl], $4c
    ld c, a
    ld c, a
    ld d, [hl]
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    ld h, d
    ld d, b
    ld a, $56
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $49
    ld c, h
    ld d, d
    ld b, c
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
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
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $36
    ld c, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld a, $ef
    xor $30
    ld b, d
    ld d, c
    ld a, $49
    daa
    ld c, a
    ld a, $5f
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc h
    ld h, d
    jr nc, @+$44

    ld d, c
    ld a, $49
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $40
    ld c, a
    ld b, d
    ld a, $51
    ld b, d
    ld b, c
    ld h, e
    ld a, [$eff7]
    xor $24
    ld c, d
    ld a, $57
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, l
    ld d, d
    ld b, l
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
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
    xor $40
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld c, e
    ld h, a
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld a, [$eff7]
    xor $40
    ld c, c
    ld b, d
    ld a, $4f
    ld c, c
    ld d, [hl]
    ld h, h
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
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, c
    ld c, h
    ld d, d
    ld b, c
    ld e, a
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
    rst $28
    xor $33
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld b, b
    ld a, $4f
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    ld e, a
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
    ld d, c
    ld b, d
    ld c, c
    ld c, c
    ld e, a
    ld e, a
    ld e, a
    ld c, e
    ld c, h
    rst $28
    xor $2c
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
    ld h, d
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld a, [$eff7]
    xor $50
    ld b, l
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    inc l
    ld h, d
    ld b, c
    ld c, h
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
    ld e, a
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
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, h
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    inc h
    ld b, b
    ld d, c
    ld d, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld e, [hl]
    rst $28
    xor $4b
    ld c, h
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, d
    ld b, l
    ld a, $50
    ld a, [$eff7]
    xor $50
    ld d, d
    ld c, a
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    ld b, c
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
    ld d, h
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    rst $28
    xor $54
    ld b, l
    ld c, h
    ld h, d
    ld a, $49
    ld c, d
    ld c, h
    ld d, b
    ld d, c
    ld h, d
    ld c, d
    ld a, $41
    ld b, d
    ld a, [$eff7]
    xor $46
    ld d, c
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
    ld a, $49
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    rst $28
    xor $54
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, c
    ld b, d
    ld d, e
    ld a, $50
    ld d, c
    ld a, $51
    ld b, d
    ld b, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld d, c
    ld d, h
    ld c, h
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
    ld a, $62
    ld d, d
    ld d, b
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld a, [$eff7]
    xor $44
    ld c, a
    ld b, d
    ld a, $51
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    rst $28
    xor $3f
    ld d, d
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
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
    ld d, b
    ld c, h
    ld h, d
    ld d, c
    ld b, d
    ld c, a
    ld c, a
    ld b, [hl]
    ccf
    ld c, c
    ld b, d
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $43
    ld d, d
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld e, a
    ld e, a
    ld e, a
    inc l
    ld h, d
    ld a, $44
    ld c, a
    ld b, d
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld e, a
    ld h, d
    inc l
    ld l, d
    ld h, d
    ld d, b
    ld c, h
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $48
    ld b, d
    ld b, d
    ld c, l
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
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld b, c
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $41
    ld c, h
    ld h, h
    ld h, d
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $44
    ld d, d
    ld a, $4f
    ld b, c
    ld b, [hl]
    ld a, $4b
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    rst $28
    xor $30
    ld d, [hl]
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    daa
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    ld e, a
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    dec hl
    ld c, d
    ld c, d
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
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld b, d
    ld d, [hl]
    ld b, d
    ld d, b
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
    ld l, c
    ld b, d
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, c
    ld d, c
    ld d, [hl]
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
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
    xor $fa
    rst $30
    rst $28
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    inc l
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld a, $62
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, e
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
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
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld b, d
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld c, d
    ld b, d
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
    cpl
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    rst $28
    xor $45
    ld c, h
    ld d, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $27
    ld d, d
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
    xor $4c
    ld d, d
    ld d, c
    ld h, e
    ld h, d
    jr nc, jr_021_7893

    ld h, d
    ld d, b
    ld b, d
    ld c, a
    ld d, e
    ld a, $4b
    ld d, c
    ld d, b
    ld h, e
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
    ld e, [hl]
    rst $28
    xor $43
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
    ld a, [$eff7]
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
    ld c, d
    ld c, d
    ld e, a
    ld h, d
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $40
    ld a, $4a
    ld b, d
    ld h, d

jr_021_7893:
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $29
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $50
    ld b, d
    ld c, a
    ld d, e
    ld a, $4b
    ld d, c
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $27
    ld d, d
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
    xor $4c
    ld d, d
    ld d, c
    ld h, e
    ld h, d
    jr nc, jr_021_792b

    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, c
    ld d, c
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, e
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
    ld e, [hl]
    rst $28
    xor $43
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
    ld a, [$eff7]
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
    xor $3c
    ld c, h
    ld d, d
    ld h, d

jr_021_792b:
    ld b, c
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld b, d
    ld a, $50
    ld b, [hl]
    ld c, c
    ld d, [hl]
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
    add hl, hl
    ld c, h
    ld c, a
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    rst $28
    xor $4a
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld b, l
    ld a, $53
    ld b, [hl]
    ld c, e
    ld b, h
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
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $54
    ld b, d
    ld a, $48
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld c, e
    ld b, d
    ld d, l
    ld d, c
    rst $28
    xor $4c
    ld c, e
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $62
    ld c, l
    ld c, a
    ld b, d
    ld d, c
    ld d, c
    ld d, [hl]
    ld a, [$eff7]
    xor $51
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    ld c, h
    ld c, e
    ld b, d
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
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $ef
    xor $50
    ld d, h
    ld c, h
    ld c, a
    ld b, c
    ld c, d
    ld a, $4b
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    ld a, [$eff7]
    xor $54
    ld a, $4b
    ld b, c
    ld b, d
    ld c, a
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, b
    ld b, d
    ld a, $4f
    ld b, b
    ld b, l
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ld d, b
    ld d, h
    ld c, h
    ld c, a
    ld b, c
    ld a, [$eff7]
    xor $46
    ld c, e
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
    ld h, d
    ld a, $4b
    ld b, c
    ld e, a
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
    ld a, $51
    ld h, d
    ld c, c
    ld a, $50
    ld d, c
    rst $28
    xor $40
    ld a, $4a
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    ld h, $4c
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld d, d
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
    cpl
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    rst $28
    xor $46
    ld c, e
    ld d, c
    ld c, a
    ld c, h
    ld b, c
    ld d, d
    ld b, b
    ld b, d
    ld h, d
    ld b, l
    ld b, [hl]
    ld c, d
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld e, a
    ld h, d
    dec hl
    ld b, d
    ld l, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    rst $28
    xor $54
    ld b, l
    ld c, h
    ld h, d
    ld b, c
    ld b, d
    ld b, c
    ld b, [hl]
    ld b, b
    ld a, $51
    ld b, d
    ld b, c
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $50
    ld c, h
    ld d, d
    ld c, c
    ld h, d
    ld d, c
    ld c, h
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
    xor $27
    ld d, d
    ld c, a
    ld c, a
    ld a, $4b
    and e
    ld a, $4b
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld l, b
    ld h, d
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
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $3e
    ld c, c
    ld c, c
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
    rst $28
    xor $f6
    ld h, e
    ld h, e
    ld a, [$eff7]
    xor $27
    ld d, d
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
    ld h, e
    rst $28
    xor $f6
    ld h, e
    ld e, [hl]
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
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
    ld h, e
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
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
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
    xor $3c
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
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $43
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, e
    ld h, h
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld a, $62
    ld c, a
    ld b, d
    ld a, $49
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
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
    ld h, $4c
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, e
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    ld h, d
    ld b, c
    ld b, d
    ld b, c
    ld b, [hl]
    ld b, b
    ld a, $51
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $45
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, b
    ld c, h
    ld d, d
    ld c, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld b, d
    ld e, [hl]
    rst $28
    xor $26
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, e
    ld h, d
    or $63
    rst $30
    ldh a, [$f0]
    ld h, $60
    ldh [$f8], a
    inc h
    ld h, b
    ldh [rP1], a
    ld [hl+], a
    ld h, b
    ldh [$08], a
    jr nz, @+$62

    ldh [rNR10], a
    ld e, $60
    ldh a, [$e8]
    inc e
    ld h, b
    ldh a, [$f0]
    ld a, [de]
    ld h, b
    ldh a, [$f8]
    jr jr_021_7c78

    ldh a, [rP1]
    ld d, $60
    ldh a, [$08]
    inc d
    ld h, b
    ldh a, [rNR10]
    ld [de], a
    ld h, b
    add b
    db $e4
    ld [$005a], sp
    db $e3
    add sp, $4c
    nop
    ldh a, [rP1]
    ld e, b
    nop
    ldh a, [$f8]
    ld d, [hl]
    nop
    ldh a, [$f0]
    ld d, h
    nop
    ldh [rP1], a
    ld d, d
    nop
    ldh [$f8], a
    ld d, b
    nop
    ldh [$f0], a
    ld c, [hl]
    nop
    add b
    db $ed
    ld [$604c], sp
    db $ec
    add sp, $5a
    ld h, b
    ldh [$f0], a
    ld e, b
    ld h, b
    ldh [$f8], a
    ld d, [hl]
    ld h, b
    ldh [rP1], a
    ld d, h
    ld h, b
    ldh a, [$f0]
    ld d, d
    ld h, b
    ldh a, [$f8]
    ld d, b
    ld h, b
    ldh a, [rP1]
    ld c, [hl]
    ld h, b
    add b
    ldh a, [rNR23]
    ld b, b
    nop
    ldh a, [rNR10]
    ld a, $00
    ldh [$08], a
    ld b, b
    nop
    ldh [rP1], a
    ld a, $00
    ret nc

jr_021_7c78:
    ld hl, sp+$40
    nop
    ret nc

    ldh a, [$3e]
    nop
    ret nc

    add sp, $3c
    nop
    ret nc

    ldh [$3a], a
    nop
    add b
    ldh [$e8], a
    ld b, h
    nop
    ldh [$e0], a
    ld b, d
    nop
    ldh a, [$f8]
    ld b, h
    nop
    ldh a, [$f0]
    ld b, d
    nop
    nop
    jr jr_021_7ce3

    nop
    nop
    db $10
    ld b, [hl]
    nop
    nop
    ld [$0044], sp
    nop
    nop
    ld b, d
    nop
    add b
    ldh a, [rNR41]
    ld [hl], d
    nop
    ldh a, [$d8]
    ld h, b
    nop
    ldh a, [rNR23]
    ld [hl], b
    nop
    ldh a, [rNR10]
    ld l, [hl]
    nop
    ldh a, [$08]
    ld l, h
    nop
    ldh a, [rP1]
    ld l, d
    nop
    ldh a, [$f8]
    ld l, b
    nop
    ldh a, [$f0]
    ld h, [hl]
    nop
    ldh a, [$e8]
    ld h, h
    nop
    ldh a, [$e0]
    ld h, d
    nop
    add b
    add hl, bc
    ld b, b
    ld [$da40], sp
    ld a, h
    rst $28
    ld a, h
    ldh a, [$f0]
    ld a, [bc]
    nop
    ldh a, [$e8]
    ld [$f000], sp

jr_021_7ce3:
    ldh [rTMA], a
    nop
    ldh a, [rNR23]
    ld c, $00
    ldh a, [rNR10]
    inc c
    nop
    add b
    ldh a, [rNR23]
    ld [de], a
    nop
    ldh a, [rNR10]
    stop
    ldh a, [$f0]
    inc b
    nop
    ldh a, [$e8]
    ld [bc], a
    nop
    ldh a, [$e0]
    nop
    nop
    add b
    ld bc, $0040
    ld b, b
    ld a, $01
    ldh [rVBK], a
    ld hl, $7a45
    ld bc, $9c00
    ld a, $21
    ld [$c6a1], a
    call BitComplementAndBranch
    xor a
    ldh [rVBK], a
    ld hl, $78f7
    ld bc, $9c00
    call BitComplementAndBranch
    ld hl, $59d6
    ld a, $22
    ld [$c6a1], a
    call WriteRotatedBytesDown
    ld hl, $5a16
    call $2df1
    ret


    ld hl, $4000
    ld bc, $9c00
    ld a, $3f
    ld [$c6a1], a
    call BitComplementAndBranch
    ldh a, [$fe]
    and a
    ret z

    ld a, $01
    ldh [rVBK], a
    ld hl, $4179
    ld bc, $9c00
    call BitComplementAndBranch
    xor a
    ldh [rVBK], a
    ld a, $02
    ld [$c6a1], a
    ld hl, $4000
    call WriteRotatedBytesDown
    ld hl, $4040
    call $2df1
    ret


    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
